"""Check real Release upgrade on a fresh, explicitly named synthetic AVD only."""
import argparse,json,re,sqlite3,subprocess,time
import xml.etree.ElementTree as ET
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
PACKAGE='app.mamba.mambatv'
AVD='Mamba_TV_M7_Signing_API36'
def main():
    p=argparse.ArgumentParser();p.add_argument('--adb',required=True);p.add_argument('--device',required=True);p.add_argument('--reset-synthetic',action='store_true');a=p.parse_args()
    def adb(*args,check=True):
        r=subprocess.run([a.adb,'-s',a.device,*args],capture_output=True,text=True,encoding='utf-8',errors='replace',timeout=45)
        if check and r.returncode: raise RuntimeError('Isolated ADB step failed: '+args[0])
        return r
    if adb('shell','getprop','ro.boot.qemu.avd_name').stdout.strip()!=AVD: raise RuntimeError('Refusing any other AVD or physical device')
    if PACKAGE in adb('shell','pm','list','packages',PACKAGE).stdout:
        if not a.reset_synthetic: raise RuntimeError('Dedicated AVD must be unused; refusing an existing installation')
        adb('uninstall',PACKAGE)
    report=json.loads((ROOT/'docs/m7-evidence/test-signing-build.json').read_text())
    before=ROOT/report['upgradePair']['before'];after=ROOT/report['upgradePair']['after']
    work=ROOT/'.m0/m7-upgrade-data';work.mkdir(exist_ok=True)
    adb('install','-r',str(before))
    if adb('shell','getprop','ro.debuggable').stdout.strip() != '1':
        def dump():
            adb('shell','uiautomator','dump','/sdcard/m7-upgrade-window.xml')
            return adb('shell','cat','/sdcard/m7-upgrade-window.xml').stdout
        def key(code):
            adb('shell','input','keyevent',str(code));time.sleep(.3)
        def settings():
            adb('shell','am','force-stop',PACKAGE)
            adb('shell','am','start','-n',PACKAGE+'/app.mamba.mambatv.MainActivity','--es','route','/settings')
            time.sleep(5)
            xml=dump()
            if '减少动态效果' not in xml:
                for _ in range(3): key(20)
                key(23);time.sleep(1)
            for _ in range(5):
                xml=dump()
                if '减少动态效果' in xml: break
                time.sleep(1)
            if '减少动态效果' not in xml: raise RuntimeError('Settings did not become visible on the isolated AVD')
            key(22)
        def motion():
            nodes=ET.fromstring(dump()).iter('node')
            candidates=[]
            for n in nodes:
                value=n.get('content-desc') or n.get('text')
                if value and '减少动态效果' in value:
                    value='已开启' if '已开启' in value else '已关闭' if '已关闭' in value else None
                    if value is None: continue
                    y=int(re.findall(r'\d+',n.get('bounds'))[1]);candidates.append((y,value))
            if not candidates: raise RuntimeError('Native accessibility did not expose preference controls')
            return sorted(candidates)[0][1]
        settings();original=motion()
        if original!='已关闭': raise RuntimeError('Fresh test installation had unexpected preferences')
        key(23);time.sleep(1);changed=motion()
        if changed!='已开启': raise RuntimeError('Synthetic preference change was not visible')
        adb('shell','am','force-stop',PACKAGE);adb('install','-r',str(after))
        installed=adb('shell','dumpsys','package',PACKAGE).stdout
        if not re.search(r'versionCode=4002\b',installed): raise RuntimeError('Upgraded versionCode did not match')
        settings();restored=motion()
        if restored!=changed: raise RuntimeError('Preference was lost across the signed upgrade')
        result={'device':a.device,'avd':AVD,'releaseApks':True,'testSigningOnly':True,'applicationId':PACKAGE,'installReplacePassed':True,'fromVersionCode':4001,'toVersionCode':4002,'mode':'native UI preference preservation','preference':'reducedMotion','originalValue':False,'committedValue':True,'restoredAfterUpgrade':True,'nativeV1FixtureInjected':False,'nativeV1FixtureUnavailableReason':'This SDK TV image disables root; no private-data bypass was attempted. SQLite v1 migration remains covered by repository tests.','realAccountUsed':False,'personalDeviceModified':False,'keyAlreadyRemoved':report['keyRemoved']}
        (ROOT/'docs/m7-evidence/native-signed-upgrade.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
        adb('shell','am','force-stop',PACKAGE)
        print('Isolated Release replacement preserved a preference changed through the actual TV UI')
        return
    adb('root');adb('wait-for-device')
    uid=re.search(r'uid:(\d+)',adb('shell','pm','list','packages','-U',PACKAGE).stdout).group(1)
    directory=f'/data/user/0/{PACKAGE}/app_flutter';remote=directory+'/mambatv.sqlite'
    seed=work/'seed.sqlite'
    if seed.exists(): seed.unlink()
    c=sqlite3.connect(seed)
    c.executescript("CREATE TABLE watch_progress_rows(owner_key TEXT NOT NULL,video_id TEXT NOT NULL,part_id TEXT NOT NULL,position_ms INTEGER NOT NULL DEFAULT 0,duration_ms INTEGER NOT NULL DEFAULT 0,updated_at INTEGER NOT NULL,PRIMARY KEY(owner_key,video_id,part_id)); CREATE TABLE search_entries(owner_key TEXT NOT NULL,query TEXT NOT NULL,updated_at INTEGER NOT NULL,PRIMARY KEY(owner_key,query)); PRAGMA user_version=1;")
    c.execute("INSERT INTO watch_progress_rows VALUES('guest','BVsyntheticUpgrade','11',25000,120000,1700000000)")
    c.execute("INSERT INTO search_entries VALUES('guest','synthetic-upgrade-search',1700000000)");c.commit();c.close()
    adb('shell','mkdir','-p',directory);adb('push',str(seed),'/data/local/tmp/m7-seed.sqlite')
    adb('shell','cp','/data/local/tmp/m7-seed.sqlite',remote);adb('shell','chown',uid+':'+uid,directory,remote);adb('shell','restorecon','-RF',directory)
    def boot_and_read(stage):
        adb('shell','am','start','-n',PACKAGE+'/app.mamba.mambatv.MainActivity')
        time.sleep(8)
        adb('shell','am','force-stop',PACKAGE)
        target=work/stage;target.mkdir(exist_ok=True)
        adb('pull',remote,str(target/'mambatv.sqlite'))
        adb('pull',remote+'-wal',str(target/'mambatv.sqlite-wal'),check=False)
        db=sqlite3.connect(target/'mambatv.sqlite')
        version=db.execute('PRAGMA user_version').fetchone()[0]
        progress=db.execute("SELECT position_ms FROM watch_progress_rows WHERE video_id='BVsyntheticUpgrade'").fetchone()
        search=db.execute("SELECT query FROM search_entries").fetchone()
        metadata=db.execute("SELECT count(*) FROM sqlite_master WHERE name='history_videos'").fetchone()[0]
        db.close()
        if version!=2 or progress!=(25000,) or search!=('synthetic-upgrade-search',) or metadata!=1: raise RuntimeError('Migration or upgrade changed synthetic records')
        return {'schemaVersion':version,'syntheticProgressMs':progress[0],'syntheticSearchPreserved':True,'metadataTablePresent':True}
    migration=boot_and_read('before')
    adb('install','-r',str(after))
    installed=adb('shell','dumpsys','package',PACKAGE).stdout
    if not re.search(r'versionCode=4002\b',installed): raise RuntimeError('Upgraded versionCode did not match')
    upgraded=boot_and_read('after')
    result={'device':a.device,'avd':AVD,'releaseApks':True,'testSigningOnly':True,'applicationId':PACKAGE,'installReplacePassed':True,'fromVersionCode':4001,'toVersionCode':4002,'v1Migration':migration,'afterUpgrade':upgraded,'realAccountUsed':False,'personalDeviceModified':False,'keyAlreadyRemoved':report['keyRemoved']}
    (ROOT/'docs/m7-evidence/native-signed-upgrade.json').write_text(json.dumps(result,indent=2)+'\n')
    print('Isolated Release upgrade and native v1 migration preserved synthetic data')
if __name__=='__main__':main()
