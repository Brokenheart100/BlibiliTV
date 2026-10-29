"""Release guard regression tests; no credentials, network, SDK or device needed."""

import base64
import hashlib
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
import xml.etree.ElementTree as ET
from unittest.mock import patch

import pipeline


class ReleaseGuardsTest(unittest.TestCase):
    def test_dash_loopback_network_policy_is_explicit_and_scoped(self):
        resources = pipeline.ROOT / "android/app/src/main"
        config = ET.parse(resources / "res/xml/network_security_config.xml").getroot()
        self.assertEqual(config.find("base-config").get("cleartextTrafficPermitted"), "false")
        domains = config.findall("domain-config")
        self.assertEqual(len(domains), 1)
        self.assertEqual(domains[0].get("cleartextTrafficPermitted"), "true")
        hosts = domains[0].findall("domain")
        self.assertEqual(len(hosts), 1)
        self.assertEqual(hosts[0].text, "127.0.0.1")
        self.assertEqual(hosts[0].get("includeSubdomains"), "false")
        app = ET.parse(resources / "AndroidManifest.xml").getroot().find("application")
        self.assertEqual(app.get("{http://schemas.android.com/apk/res/android}networkSecurityConfig"), "@xml/network_security_config")

    def test_version_and_exact_tag(self):
        self.assertEqual(pipeline.version("version: 1.0.0+1\n"), ("1.0.0", 1))
        self.assertEqual(pipeline.version('version: "1.2.3-rc.1+42" # candidate\n'), ("1.2.3-rc.1", 42))
        pipeline.validate_tag("v1.2.3-rc.1", "1.2.3-rc.1")
        for tag in ("v1.2.3", "1.2.3-rc.1", "v1.2.3-rc.1;echo bad", ""):
            with self.subTest(tag=tag), self.assertRaises(ValueError):
                pipeline.validate_tag(tag, "1.2.3-rc.1")

    def test_invalid_pubspec_version(self):
        for value in ("1.0.0", "01.0.0+1", "1.0.0+0", "1.0+2", "1.0.0+oops"):
            with self.subTest(version=value), self.assertRaises(ValueError):
                pipeline.version(f"version: {value}\n")

    def test_missing_signing_material_creates_nothing(self):
        with tempfile.TemporaryDirectory() as temporary, patch.dict(os.environ, {"RUNNER_TEMP": temporary}, clear=True):
            with self.assertRaisesRegex(ValueError, "Missing signing secrets"):
                pipeline.restore_signing()
            self.assertEqual(list(Path(temporary).iterdir()), [])

    def test_invalid_base64_creates_nothing(self):
        with tempfile.TemporaryDirectory() as temporary, patch.dict(os.environ, self.signing_env(temporary, "**invalid**"), clear=True):
            with self.assertRaisesRegex(ValueError, "BASE64 is invalid"):
                pipeline.restore_signing()
            self.assertEqual(list(Path(temporary).iterdir()), [])

    def test_restore_is_exclusive_and_cleanup_is_scoped(self):
        payload = b"Synthetic keystore fixture, not real signing material" * 2
        with tempfile.TemporaryDirectory() as temporary, patch.dict(os.environ, self.signing_env(temporary, base64.b64encode(payload).decode()), clear=True):
            sibling = Path(temporary) / "keep.txt"
            sibling.write_text("unrelated data")
            pipeline.restore_signing()
            self.assertEqual(pipeline.keystore_path().read_bytes(), payload)
            with self.assertRaises(FileExistsError):
                pipeline.restore_signing()
            pipeline.cleanup_signing()
            pipeline.cleanup_signing()
            self.assertEqual(sibling.read_text(), "unrelated data")

    def test_apk_identity_and_mode(self):
        text = self.badging()
        self.assertEqual(pipeline.apk_identity(text, "1.0.0", "arm64-v8a", "release", 1), 2001)
        with self.assertRaisesRegex(ValueError, "versionCode"):
            pipeline.apk_identity(text, "1.0.0", "arm64-v8a", "release", 2)
        self.assertEqual(pipeline.apk_identity(text, "1.0.0", "arm64-v8a", "release"), 2001)
        for changed in (
            text.replace("app.mamba.mambatv", "app.mamba.mambatv.validation"),
            text.replace("versionName='1.0.0'", "versionName='0.9.0'"),
            text.replace("'arm64-v8a'", "'x86_64'"),
            text.replace("leanback-launchable-activity:", "launchable-activity:"),
            text + "\napplication-debuggable\n",
        ):
            with self.subTest(badging=changed), self.assertRaises(ValueError):
                pipeline.apk_identity(changed, "1.0.0", "arm64-v8a", "release")

    def test_certificate_rejects_debug_and_multiple_signers(self):
        digest = "ab" * 32
        signature = f"Signer #1 certificate SHA-256 digest: {digest}"
        self.assertEqual(pipeline.certificate(signature, "release"), digest)
        for bad in (signature + "\nSigner #1 certificate DN: CN=Android Debug, O=Android, C=US", signature + "\n" + signature, "not verified"):
            with self.subTest(signature=bad), self.assertRaises(ValueError):
                pipeline.certificate(bad, "release")

    def test_preflight_uses_tag_pubspec_and_rejects_non_master_history(self):
        sha = "a" * 40
        with patch.dict(os.environ, {"RELEASE_TAG": "v1.0.0"}), patch.object(pipeline, "run", side_effect=[sha, "", "version: 1.0.0+1\n"]) as call, patch.object(pipeline, "output") as output:
            pipeline.release_preflight()
            self.assertEqual(call.call_args.args, ("git", "show", f"{sha}:pubspec.yaml"))
            self.assertEqual(output.call_args.args[0]["sha"], sha)
        with patch.dict(os.environ, {"RELEASE_TAG": "v1.0.0"}), patch.object(pipeline, "run", side_effect=[sha, subprocess.CalledProcessError(1, "git")]):
            with self.assertRaises(subprocess.CalledProcessError):
                pipeline.release_preflight()

    def test_packaging_checksums_cover_every_uploaded_file(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = self.package_fixture(temporary)
            destination = root / "artifacts"
            with patch.object(pipeline, "ROOT", root), patch.dict(os.environ, {"ANDROID_HOME": temporary, "RELEASE_TAG": "v1.0.0"}), patch.object(pipeline, "run", side_effect=self.package_command), patch.object(pipeline, "java_version", return_value="21-test"):
                pipeline.package("release", destination)
            entries = (destination / "SHA256SUMS").read_text().splitlines()
            self.assertEqual(len(entries), 10)
            for entry in entries:
                digest, filename = entry.split("  ", 1)
                self.assertEqual(digest, hashlib.sha256((destination / filename).read_bytes()).hexdigest())
            metadata = json.loads((destination / "build-metadata.json").read_text())
            self.assertEqual({item["abi"] for item in metadata["artifacts"]}, {"armeabi-v7a", "arm64-v8a"})
            self.assertFalse(any("x86" in file.name for file in destination.iterdir()))
            self.assertFalse(metadata["workingTreeDirty"])

    def test_debug_packaging_keeps_emulator_abi(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = self.package_fixture(temporary)
            destination = root / "artifacts"
            with patch.object(pipeline, "ROOT", root), patch.dict(os.environ, {"ANDROID_HOME": temporary}), patch.object(pipeline, "run", side_effect=self.package_command), patch.object(pipeline, "java_version", return_value="21-test"):
                pipeline.package("debug", destination)
            metadata = json.loads((destination / "build-metadata.json").read_text())
            self.assertEqual({item["abi"] for item in metadata["artifacts"]}, set(pipeline.ABIS))
            self.assertEqual(len((destination / "SHA256SUMS").read_text().splitlines()), 11)

    def test_packaging_rejects_mixed_signing_keys(self):
        def mixed(*args):
            response = self.package_command(*args)
            if "verify" in args and "arm64-v8a" in args[-1]:
                response = response.replace("ab" * 32, "cd" * 32)
            return response

        with tempfile.TemporaryDirectory() as temporary:
            root = self.package_fixture(temporary)
            with patch.object(pipeline, "ROOT", root), patch.dict(os.environ, {"ANDROID_HOME": temporary, "RELEASE_TAG": "v1.0.0"}), patch.object(pipeline, "run", side_effect=mixed):
                with self.assertRaisesRegex(ValueError, "same signing certificate"):
                    pipeline.package("release", root / "artifacts")

    def test_packaging_rejects_dirty_ci_checkout(self):
        def modified(*args):
            if args[:2] == ("git", "status"):
                return " M lib/main.dart"
            return self.package_command(*args)

        with tempfile.TemporaryDirectory() as temporary:
            root = self.package_fixture(temporary)
            with patch.object(pipeline, "ROOT", root), patch.dict(os.environ, {"ANDROID_HOME": temporary, "RELEASE_TAG": "v1.0.0", "GITHUB_ACTIONS": "true"}), patch.object(pipeline, "run", side_effect=modified):
                with self.assertRaisesRegex(ValueError, "CI build changed source files"):
                    pipeline.package("release", root / "artifacts")

    def test_generated_guard_detects_modified_and_untracked_sources(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            with patch.object(pipeline, "ROOT", root):
                pipeline.run("git", "init", "--quiet")
                generated = root / "sample.g.dart"
                generated.write_text("// checked in\n")
                pipeline.run("git", "add", "sample.g.dart")
                pipeline.check_generated()
                untracked = root / "other.freezed.dart"
                untracked.write_text("// needs commit\n")
                with self.assertRaisesRegex(ValueError, "untracked"):
                    pipeline.check_generated()
                untracked.unlink()
                generated.write_text("// regenerated\n")
                with self.assertRaises(subprocess.CalledProcessError):
                    pipeline.check_generated()

    @staticmethod
    def package_fixture(temporary):
        root = Path(temporary)
        (root / "pubspec.yaml").write_text("version: 1.0.0+1\n")
        (root / "pubspec.lock").write_text("# synthetic lockfile\n")
        docs = root / "docs/release"
        docs.mkdir(parents=True)
        for name in ("dependencies.json", "THIRD_PARTY_NOTICES.txt", "NATIVE_NOTICES.txt", "installation.md", "known-limitations.md", "sources.md", "changelog.md"):
            (docs / name).write_text("Synthetic release documentation\n")
        output = root / "build/app/outputs/flutter-apk"
        output.mkdir(parents=True)
        for abi in pipeline.ABIS:
            (output / f"app-{abi}-release.apk").write_bytes(f"synthetic {abi} APK".encode())
            (output / f"app-{abi}-debug.apk").write_bytes(f"synthetic debug {abi} APK".encode())
        return root

    @classmethod
    def package_command(cls, *args):
        if "badging" in args:
            for abi in pipeline.ABIS:
                if f"app-{abi}-" in args[-1]:
                    code = {"armeabi-v7a": 1001, "arm64-v8a": 2001, "x86_64": 4001}[abi]
                    result = cls.badging().replace("arm64-v8a", abi).replace("versionCode='2001'", f"versionCode='{code}'")
                    return result + ("application-debuggable\n" if "-debug.apk" in args[-1] else "")
        if "verify" in args:
            return "Signer #1 certificate SHA-256 digest: " + "ab" * 32
        if args[:3] == ("git", "rev-parse", "HEAD"):
            return "a" * 40
        if args[:2] == ("git", "status"):
            return ""
        raise AssertionError("Unexpected native command in fixture")

    @staticmethod
    def signing_env(temporary, encoded):
        return {
            "RUNNER_TEMP": temporary, "ANDROID_KEYSTORE_BASE64": encoded,
            "MAMBA_KEYSTORE_PASSWORD": "synthetic", "MAMBA_KEY_ALIAS": "synthetic",
            "MAMBA_KEY_PASSWORD": "synthetic",
        }

    @staticmethod
    def badging():
        return (
            "package: name='app.mamba.mambatv' versionCode='2001' versionName='1.0.0'\n"
            "native-code: 'arm64-v8a'\nleanback-launchable-activity: name='app.mamba.mambatv.MainActivity'\n"
        )


if __name__ == "__main__":
    unittest.main()
