"""CI-only installer for the pinned official engine, verified against its SHA512 manifest."""
import hashlib, os, pathlib, urllib.request, zipfile
folder=pathlib.Path(os.environ['RUNNER_TEMP'])/'lighting15-godot'
folder.mkdir(exist_ok=True)
platform='win64.exe' if os.name=='nt' else 'linux.x86_64'
name='Godot_v4.4.1-stable_'+platform+'.zip'
base='https://github.com/godotengine/godot-builds/releases/download/4.4.1-stable/'
archive=folder/name
with urllib.request.urlopen(base+name,timeout=120) as response:archive.write_bytes(response.read())
with urllib.request.urlopen(base+'SHA512-SUMS.txt',timeout=30) as response:lines=response.read().decode().splitlines()
expected=[line.split()[0] for line in lines if line.rstrip().endswith(name)]
assert len(expected)==1 and hashlib.sha512(archive.read_bytes()).hexdigest()==expected[0].lower(), 'Official engine checksum mismatch'
with zipfile.ZipFile(archive) as z:z.extractall(folder)
exe=next(folder.glob('*_console.exe' if os.name=='nt' else '*.x86_64'))
if os.name!='nt':exe.chmod(0o755)
with open(os.environ['GITHUB_ENV'],'a',encoding='utf-8') as f:f.write('GODOT_BIN='+str(exe)+'\nGODOT_SILENCE_ROOT_WARNING=1\n')
