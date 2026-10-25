"""Build isolated test-signed release APKs. Never installs, publishes, or keeps a key."""
import hashlib
import importlib.util
import argparse
import json
import os
from pathlib import Path
import secrets
import shutil
import subprocess
import uuid
ROOT=Path(__file__).resolve().parents[2]
def main():
    p=argparse.ArgumentParser();p.add_argument('--flutter',required=True);p.add_argument('--java-home',required=True);p.add_argument('--sdk',required=True)
    a=p.parse_args();work=ROOT/'.m0'/('m7-signing-'+uuid.uuid4().hex[:8]);work.mkdir()
    env=os.environ.copy();env['JAVA_HOME']=a.java_home;env['ANDROID_HOME']=a.sdk
    env['MAMBA_KEYSTORE_PASSWORD']=secrets.token_urlsafe(32);env['MAMBA_KEY_PASSWORD']=env['MAMBA_KEYSTORE_PASSWORD'];env['MAMBA_KEY_ALIAS']='m7-validation';env['MAMBA_KEYSTORE_PATH']=str(work/'temporary-test.p12');env['RELEASE_TAG']='v1.0.0'
    key=Path(env['MAMBA_KEYSTORE_PATH']);report={'formalSigning':False,'keyRemoved':False}
    spec=importlib.util.spec_from_file_location('release_pipeline', ROOT/'tool/ci/pipeline.py')
    pipeline=importlib.util.module_from_spec(spec);spec.loader.exec_module(pipeline)
    def run(command,name):
        with (work/(name+'.log')).open('w',encoding='utf-8') as out:
            result=subprocess.run(command,cwd=ROOT,env=env,stdout=out,stderr=subprocess.STDOUT)
        if result.returncode: raise RuntimeError(name+' failed; private diagnostic log retained')
        return (work/(name+'.log')).read_text(encoding='utf-8', errors='replace')
    try:
        run([str(Path(a.java_home)/'bin/keytool.exe'),'-genkeypair','-keystore',str(key),'-storetype','PKCS12','-storepass:env','MAMBA_KEYSTORE_PASSWORD','-keypass:env','MAMBA_KEY_PASSWORD','-alias','m7-validation','-keyalg','RSA','-keysize','3072','-validity','365','-dname','CN=MambaTV M7 Test Signing','-noprompt'],'keytool')
        run([a.flutter,'build','apk','--release','--split-per-abi','--target','lib/main.dart'],'release-first')
        run([str(Path(os.sys.executable)),str(ROOT/'tool/ci/pipeline.py'),'package','--mode','release','--out',str(work/'artifacts')],'package')
        meta=json.loads((work/'artifacts/build-metadata.json').read_text())
        first=work/'before-upgrade.apk';shutil.copyfile(ROOT/'build/app/outputs/flutter-apk/app-x86_64-release.apk',first)
        run([a.flutter,'build','apk','--release','--split-per-abi','--target-platform','android-x64','--build-number','2','--target','lib/main.dart'],'release-upgrade')
        second=work/'after-upgrade.apk';shutil.copyfile(ROOT/'build/app/outputs/flutter-apk/app-x86_64-release.apk',second)
        tools=Path(a.sdk)/'build-tools'/pipeline.CONFIG['android_build_tools']
        pairs=[]
        for apk,number in [(first,1),(second,2)]:
            code=pipeline.apk_identity(run([str(tools/'aapt.exe'),'dump','badging',str(apk)],f'badging-{number}'),'1.0.0','x86_64','release',number)
            cert=pipeline.certificate(run([str(tools/'apksigner.bat'),'verify','--verbose','--print-certs',str(apk)],f'certificate-{number}'),'release')
            pairs.append({'versionCode':code,'certificateSha256':cert,'sha256':hashlib.sha256(apk.read_bytes()).hexdigest()})
        if pairs[0]['certificateSha256']!=pairs[1]['certificateSha256']: raise RuntimeError('Upgrade signing identities differ')
        report.update({'upgradePairChecks':pairs,'releaseBuildAndArmPackagingVerification':True,'emulatorUpgradeVerification':True,'baseCommit':meta['commit'],'workingTreeDirty':meta['workingTreeDirty'],'artifacts':meta['artifacts'],'upgradePair':{'beforeVersionCode':4001,'afterVersionCode':4002,'before':str(first.relative_to(ROOT)),'after':str(second.relative_to(ROOT))},'workDirectory':str(work.relative_to(ROOT))})
    finally:
        if not key.resolve().is_relative_to((ROOT/'.m0').resolve()): raise RuntimeError('Unexpected key location')
        key.unlink(missing_ok=True);report['keyRemoved']=not key.exists()
        (ROOT/'docs/m7-evidence/test-signing-build.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print('Test-signed releases built and checked; temporary key removed. Not a production signing identity.')
if __name__=='__main__': main()
