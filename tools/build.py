"""Build the Ashworld PortMaster host and ZIPs from the owner's Windows JAR."""
import argparse
import hashlib
import os
from pathlib import Path
import shutil
import subprocess
import zipfile

ROOT = Path(__file__).resolve().parents[1]
SHA256 = '672f2ba91677d2279c1a630255eece0d09fbc9f0061b6323514689b23217446f'

def add(out, source, target):
    entry = zipfile.ZipInfo(target, (2026, 9, 10, 0, 0, 0))
    entry.create_system = 3
    entry.external_attr = (0o100755 if target.endswith('.sh') else 0o100644) << 16
    entry.compress_type = zipfile.ZIP_DEFLATED
    out.writestr(entry, source.read_bytes())

def package():
    dist = ROOT/'dist'; dist.mkdir(exist_ok=True)
    for name, private, muos in [('ashworld-byo-data.zip',False,False),
                                ('ashworld-private-portmaster.zip',True,False),
                                ('ashworld-private-muos.zip',True,True)]:
        with zipfile.ZipFile(dist/name,'w') as out:
            for path in sorted((ROOT/'package').rglob('*')):
                if not path.is_file(): continue
                rel = path.relative_to(ROOT/'package').as_posix()
                if any(part in ('saves','cache') for part in path.relative_to(ROOT/'package').parts): continue
                if path.name in ('log.txt','resolution.txt') or path.suffix.lower() in ('.apk','.exe','.dll'): continue
                if not private and path.name == 'ashworld.dat': continue
                if '/' not in rel and rel != 'Ashworld.sh': rel = 'ashworld/'+rel
                if muos: rel = ('roms/PORTS/' if rel == 'Ashworld.sh' else 'ports/') + rel
                add(out,path,rel)
        print('Built',name)
    with zipfile.ZipFile(dist/'ashworld-port-source.zip','w') as out:
        for path in sorted(ROOT.rglob('*')):
            if not path.is_file(): continue
            parts = path.relative_to(ROOT).parts
            if parts[0] not in ('src','tools','tests','docs','package','README.md','VALIDATION.md','LICENSE','.gitignore','.gitattributes'): continue
            if any(p in ('build','dist','__pycache__','saves','cache','runtime') for p in parts): continue
            if path.suffix.lower() in ('.jar','.dat','.class','.apk','.exe','.dll','.pyc','.log'): continue
            if path.name in ('log.txt','resolution.txt'): continue
            add(out,path,'ashworld-port/'+'/'.join(parts))
    (dist/'SHA256SUMS.txt').write_text(''.join(hashlib.sha256(p.read_bytes()).hexdigest()+'  '+p.name+'\n'
                                            for p in sorted(dist.glob('*.zip'))),encoding='utf-8')
    print('Built ashworld-port-source.zip and checksums')

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--game-jar',type=Path)
    parser.add_argument('--jdk',type=Path)
    parser.add_argument('--package-only',action='store_true')
    args = parser.parse_args()
    if args.package_only:
        if not (ROOT/'package/ashworld/runtime/ashworld-host.jar').is_file():
            parser.error('Run a full build before --package-only')
        package(); return
    if not args.game_jar or not args.jdk: parser.error('--game-jar and --jdk are required')
    game = args.game_jar.resolve(); jdk = args.jdk.resolve()
    if hashlib.sha256(game.read_bytes()).hexdigest() != SHA256: parser.error('Unsupported game JAR fingerprint')
    suffix = '.exe' if os.name == 'nt' else ''
    javac = jdk/'bin'/('javac'+suffix)
    classes = ROOT/'build/classes'; classes.mkdir(parents=True,exist_ok=True)
    # Require JDK 17+ for --release and emit Java 8-compatible host bytecode.
    compile_cp = ROOT/'build/compile-classpath'
    compile_cp.mkdir(parents=True,exist_ok=True)
    with zipfile.ZipFile(game) as archive:
        for entry in archive.infolist():
            if entry.filename.endswith('.class'):
                target = (compile_cp/entry.filename).resolve()
                target.relative_to(compile_cp.resolve())
                target.parent.mkdir(parents=True,exist_ok=True)
                target.write_bytes(archive.read(entry))
    subprocess.run([str(javac),'--release','8','-Xlint:-options','-encoding','UTF-8','-cp',str(compile_cp),
                    '-d',str(classes),*[str(p) for p in sorted((ROOT/'src').rglob('*.java'))]],check=True)
    runtime = ROOT/'package/ashworld/runtime'; runtime.mkdir(parents=True,exist_ok=True)
    with zipfile.ZipFile(runtime/'ashworld-host.jar','w') as out:
        for path in sorted(classes.rglob('*.class')): add(out,path,path.relative_to(classes).as_posix())
    target = ROOT/'package/ashworld/ashworld.dat'
    if game != target: shutil.copy2(game,target)
    package()

if __name__ == '__main__': main()
