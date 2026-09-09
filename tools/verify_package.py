"""Validate public/private archive boundaries, required files and checksums."""
import hashlib
import io
import json
from pathlib import Path
import xml.etree.ElementTree as ET
import zipfile
from build import SHA256

ROOT = Path(__file__).resolve().parents[1]

def main():
    for filename,private,muos in [('ashworld-byo-data.zip',False,False),
                                  ('ashworld-private-portmaster.zip',True,False),
                                  ('ashworld-private-muos.zip',True,True)]:
        with zipfile.ZipFile(ROOT/'dist'/filename) as z:
            assert z.testzip() is None
            prefix = 'ports/' if muos else ''
            script = 'roms/PORTS/Ashworld.sh' if muos else 'Ashworld.sh'
            assert script in z.namelist()
            for member in (script,prefix+'ashworld/display.sh'):
                assert b'\r' not in z.read(member)
                assert z.getinfo(member).external_attr >> 16 & 0o111
            for member in ('ashworld.gptk','README.txt','licenses/PORT-LICENSE.txt','port.json','gameinfo.xml'):
                assert prefix+'ashworld/'+member in z.namelist()
            json.loads(z.read(prefix+'ashworld/port.json'))
            ET.fromstring(z.read(prefix+'ashworld/gameinfo.xml'))
            for n in z.namelist():
                assert n == script or n.startswith(prefix+'ashworld/')
                assert not any(p in ('saves','cache','build') for p in Path(n).parts)
                assert not n.endswith(('.exe','.dll','.apk','log.txt'))
            game = prefix+'ashworld/ashworld.dat'
            if private: assert hashlib.sha256(z.read(game)).hexdigest() == SHA256
            else: assert game not in z.namelist()
            with zipfile.ZipFile(io.BytesIO(z.read(prefix+'ashworld/runtime/ashworld-host.jar'))) as host:
                assert 'org/portmaster/ashworld/Main.class' in host.namelist()
                assert all(n.startswith('org/portmaster/ashworld/') and 'Smoke' not in n for n in host.namelist())
    with zipfile.ZipFile(ROOT/'dist/ashworld-port-source.zip') as z:
        assert z.testzip() is None
        assert 'ashworld-port/src/org/portmaster/ashworld/Main.java' in z.namelist()
        assert not any(n.endswith(('.jar','.dat','.exe','.apk','.class')) or '/build/' in n or '/decompiled/' in n for n in z.namelist())
    for line in (ROOT/'dist/SHA256SUMS.txt').read_text().splitlines():
        expected,name = line.split('  ')
        assert hashlib.sha256((ROOT/'dist'/name).read_bytes()).hexdigest()==expected
    print('PACKAGE_OK: three install ZIPs, public/source exclusions, exact private JAR, checksums')

if __name__ == '__main__': main()
