"""CI and release guards. Uses only Python's standard library; never prints secrets."""

import argparse
import base64
import hashlib
import json
import os
from pathlib import Path
import platform
import re
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
CONFIG = json.loads((Path(__file__).with_name("toolchain.json")).read_text())
ABIS = ("armeabi-v7a", "arm64-v8a", "x86_64")
RELEASE_ABIS = ("armeabi-v7a", "arm64-v8a")
VERSION = re.compile(
    r"(?m)^version:\s*['\"]?(?P<name>(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)\."
    r"(?:0|[1-9]\d*)(?:-[0-9A-Za-z]+(?:[.-][0-9A-Za-z]+)*)?)"
    r"\+(?P<code>[1-9]\d*)['\"]?\s*(?:#.*)?$"
)


def run(*args):
    executable = shutil.which(args[0]) or args[0]
    return subprocess.run(
        (executable, *args[1:]), cwd=ROOT, check=True, capture_output=True, text=True, encoding="utf-8"
    ).stdout.strip()


def version(text):
    match = VERSION.search(text)
    if not match:
        raise ValueError("pubspec.yaml needs version: major.minor.patch[-prerelease]+positiveBuildNumber")
    return match["name"], int(match["code"])


def validate_tag(tag, name):
    if tag != f"v{name}":
        raise ValueError("Release tag must exactly match v + pubspec version name")
    if not re.fullmatch(r"v[0-9A-Za-z.-]+", tag):
        raise ValueError("Invalid release tag")


def output(values):
    destination = os.environ.get("GITHUB_OUTPUT")
    if destination:
        with open(destination, "a", encoding="utf-8") as stream:
            for key, value in values.items():
                if "\n" in str(value) or "\r" in str(value):
                    raise ValueError("Multiline workflow output is not allowed")
                stream.write(f"{key}={value}\n")


def toolchain():
    output(CONFIG)
    print(f"Flutter {CONFIG['flutter']}; Dart {CONFIG['dart']}; Java {CONFIG['java']}")


def verify_toolchain():
    actual = json.loads(run("flutter", "--version", "--machine"))
    for expected, key in (
        ("flutter", "frameworkVersion"),
        ("framework_revision", "frameworkRevision"),
        ("dart", "dartSdkVersion"),
    ):
        if actual[key] != CONFIG[expected]:
            raise ValueError(f"SDK {key} does not match tool/ci/toolchain.json")
    print("Flutter version, framework revision and Dart SDK verified")


def check_generated():
    patterns = ("*.g.dart", "*.freezed.dart")
    subprocess.run(
        ("git", "diff", "--exit-code", "--", *patterns), cwd=ROOT, check=True
    )
    if run("git", "ls-files", "--others", "--exclude-standard", "--", *patterns):
        raise ValueError("Generated sources are untracked; commit them before pushing")


def release_preflight():
    tag = os.environ.get("RELEASE_TAG", "")
    if not re.fullmatch(r"v\d+\.\d+\.\d+(?:-[0-9A-Za-z]+(?:[.-][0-9A-Za-z]+)*)?", tag):
        raise ValueError("Expected an existing vMAJOR.MINOR.PATCH[-prerelease] tag")
    sha = run("git", "rev-parse", "--verify", f"refs/tags/{tag}^{{commit}}")
    if not re.fullmatch(r"[0-9a-f]{40}", sha):
        raise ValueError("Tag did not resolve to a commit")
    run("git", "merge-base", "--is-ancestor", sha, "origin/master")
    name, _ = version(run("git", "show", f"{sha}:pubspec.yaml"))
    validate_tag(tag, name)
    output({"sha": sha, "tag": tag, "prerelease": str("-" in name).lower()})
    print(f"Validated existing tag {tag} on master history: {sha}")


def keystore_path():
    temporary = Path(os.environ["RUNNER_TEMP"]).resolve()
    return temporary / "mambatv-release.jks"


def restore_signing():
    required = (
        "ANDROID_KEYSTORE_BASE64", "MAMBA_KEYSTORE_PASSWORD", "MAMBA_KEY_ALIAS", "MAMBA_KEY_PASSWORD"
    )
    missing = [key for key in required if not os.environ.get(key)]
    if missing:
        raise ValueError("Missing signing secrets: " + ", ".join(missing))
    encoded = "".join(os.environ["ANDROID_KEYSTORE_BASE64"].split())
    try:
        decoded = base64.b64decode(encoded, validate=True)
    except ValueError:
        raise ValueError("ANDROID_KEYSTORE_BASE64 is invalid") from None
    if not 32 <= len(decoded) <= 10 * 1024 * 1024:
        raise ValueError("Decoded keystore has an invalid size")
    path = keystore_path()
    # Exclusive create prevents accidentally replacing an existing signing key.
    with path.open("xb") as stream:
        path.chmod(0o600)
        stream.write(decoded)
    output({"keystore": str(path)})
    print("Signing material restored to runner temporary storage")


def cleanup_signing():
    path = keystore_path()
    if path.is_symlink():
        raise ValueError("Refusing a symlink at the temporary keystore path")
    path.unlink(missing_ok=True)
    print("Temporary signing material removed")


def certificate(text, mode="debug"):
    if mode == "release" and re.search(r"certificate DN:.*CN=Android Debug", text, re.IGNORECASE):
        raise ValueError("Release APK uses an Android Debug certificate")
    values = re.findall(r"Signer #\d+ certificate SHA-256 digest:\s*([0-9a-fA-F:]+)", text)
    if len(values) != 1:
        raise ValueError("APK must have exactly one signing certificate")
    digest = values[0].replace(":", "").lower()
    if not re.fullmatch(r"[0-9a-f]{64}", digest):
        raise ValueError("Invalid APK certificate fingerprint")
    return digest


def java_version():
    home = os.environ.get("JAVA_HOME")
    java = str(Path(home) / "bin" / ("java.exe" if os.name == "nt" else "java")) if home else "java"
    process = subprocess.run((java, "-version"), check=True, capture_output=True, text=True)
    match = re.search(r'version "([^"]+)"', process.stdout + process.stderr)
    if not match:
        raise ValueError("Cannot identify the Java runtime")
    return match[1]


def apk_identity(text, name, abi, mode, build_number=None):
    match = re.search(r"package: name='([^']+)' versionCode='(\d+)' versionName='([^']+)'", text)
    if not match or match[1] != "app.mamba.mambatv" or match[3] != name or int(match[2]) <= 0:
        raise ValueError("APK package or version does not match the product")
    native = re.search(r"(?m)^native-code:\s*(.+)$", text)
    if not native or re.findall(r"'([^']+)'", native[1]) != [abi]:
        raise ValueError("Split APK ABI does not match its filename")
    if ("application-debuggable" in text) != (mode == "debug"):
        raise ValueError("APK debuggable flag does not match the requested build mode")
    if "leanback-launchable-activity:" not in text:
        raise ValueError("APK has no Android TV launcher activity")
    if build_number is not None:
        expected = {"armeabi-v7a": 1, "arm64-v8a": 2, "x86_64": 4}[abi] * 1000 + build_number
        if int(match[2]) != expected:
            raise ValueError("APK versionCode does not match the locked build number and ABI")
    return int(match[2])


def package(mode, destination):
    name, code = version((ROOT / "pubspec.yaml").read_text(encoding="utf-8"))
    if mode == "release":
        validate_tag(os.environ.get("RELEASE_TAG", ""), name)
    sdk = Path(os.environ.get("ANDROID_HOME") or os.environ["ANDROID_SDK_ROOT"])
    tools = sdk / "build-tools" / CONFIG["android_build_tools"]
    aapt = tools / ("aapt.exe" if os.name == "nt" else "aapt")
    signer = tools / ("apksigner.bat" if os.name == "nt" else "apksigner")
    target = Path(destination).resolve()
    if target.exists() and any(target.iterdir()):
        raise ValueError("Artifact directory must be empty; refusing mixed/stale assets")
    target.mkdir(parents=True, exist_ok=True)
    artifacts = []
    fingerprints = set()
    for abi in RELEASE_ABIS if mode == "release" else ABIS:
        source = ROOT / "build/app/outputs/flutter-apk" / f"app-{abi}-{mode}.apk"
        badging = run(str(aapt), "dump", "badging", str(source))
        version_code = apk_identity(badging, name, abi, mode, code)
        digest = certificate(run(str(signer), "verify", "--verbose", "--print-certs", str(source)), mode)
        fingerprints.add(digest)
        filename = f"mambatv-{name}+{code}-{abi}-{mode}.apk"
        shutil.copyfile(source, target / filename)
        artifacts.append({"file": filename, "abi": abi, "versionCode": version_code, "certificateSha256": digest})
    if len(fingerprints) != 1:
        raise ValueError("All ABI artifacts must use the same signing certificate")
    dirty = bool(run("git", "status", "--porcelain", "--untracked-files=normal"))
    if os.environ.get("GITHUB_ACTIONS") == "true" and dirty:
        raise ValueError("CI build changed source files; refusing artifacts that differ from the checked-out commit")
    metadata = {
        "applicationId": "app.mamba.mambatv", "versionName": name, "buildNumber": code,
        "mode": mode, "commit": run("git", "rev-parse", "HEAD"),
        "workingTreeDirty": dirty,
        "pubspecLockSha256": hashlib.sha256((ROOT / "pubspec.lock").read_bytes()).hexdigest(),
        "tag": os.environ.get("RELEASE_TAG") if mode == "release" else None,
        "toolchainManifest": CONFIG,
        "buildHost": {"os": platform.system(), "java": java_version()},
        "artifacts": artifacts,
        "deviceAcceptance": "CI packaging does not prove physical TV, ARM, decoder or lip-sync acceptance",
    }
    (target / "build-metadata.json").write_text(json.dumps(metadata, indent=2) + "\n", encoding="utf-8")
    notes = (
        f"MambaTV {name} ({code})\n\n"
        "Release downloads: arm64-v8a for 64-bit Android systems; armeabi-v7a for 32-bit ARM systems.\n"
        "Check the device ABI list; a 64-bit CPU may run a 32-bit Android system.\n"
        "x86_64 is available in CI debug artifacts for emulator validation.\n\n"
        "Verify SHA256SUMS before installing. Build and signing checks do not replace physical-device acceptance.\n"
        f"Signing certificate SHA-256: {next(iter(fingerprints))}\n"
    )
    changelog = ROOT / "docs/release/changelog.md"
    if not changelog.is_file():
        raise ValueError("Missing release changelog")
    notes += "\n" + changelog.read_text(encoding="utf-8-sig")
    (target / "release-notes.md").write_text(notes, encoding="utf-8")
    for name in ("dependencies.json", "THIRD_PARTY_NOTICES.txt", "NATIVE_NOTICES.txt", "installation.md", "known-limitations.md", "sources.md"):
        source = ROOT / "docs/release" / name
        if not source.is_file():
            raise ValueError("Missing release documentation: " + name)
        shutil.copyfile(source, target / name)
    checksums = []
    for file in sorted(target.iterdir()):
        with file.open("rb") as stream:
            digest = hashlib.file_digest(stream, "sha256").hexdigest()
        checksums.append(f"{digest}  {file.name}\n")
    (target / "SHA256SUMS").write_text("".join(checksums), encoding="utf-8")
    print(f"Verified and packaged {len(artifacts)} {mode} APKs with metadata and SHA256SUMS")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    for name in ("toolchain", "verify-toolchain", "check-generated", "release-preflight", "restore-signing", "cleanup-signing"):
        commands.add_parser(name)
    pack = commands.add_parser("package")
    pack.add_argument("--mode", choices=("debug", "release"), required=True)
    pack.add_argument("--out", required=True)
    args = parser.parse_args()
    if args.command == "package":
        package(args.mode, args.out)
    else:
        globals()[args.command.replace("-", "_")]()


if __name__ == "__main__":
    try:
        main()
    except (ValueError, OSError, subprocess.CalledProcessError) as error:
        # Native command output can contain paths/credentials: do not echo it.
        if isinstance(error, subprocess.CalledProcessError):
            print(f"CI guard failed: subprocess exited {error.returncode}", file=sys.stderr)
        else:
            print(f"CI guard failed: {error}", file=sys.stderr)
        sys.exit(1)
