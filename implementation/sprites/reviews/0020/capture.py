"""Capture every production family with the final code, one renderer at a time."""
from pathlib import Path
import json, subprocess, sys

ROOT = Path(__file__).resolve().parents[4]
HERE = Path(__file__).resolve().parent
commands = [('placement', ['tools/show_art.py', '--out=implementation/shots/sprites/0020/placement'])]
for mode in ['locomotion','work','reactions','terrain','water','props','crops','house','stations','towers','barriers','enemies','giant','effects','ui','atmosphere']:
    commands.append((mode, ['tools/show_art.py', '--'+mode, '--out=implementation/shots/sprites/0020/'+mode]))
scenes = ['noon','dusk','wave','result','tech','pause','options_access','options_video','options_audio','options_controls','react','refused']
for locale, flags in [('en',[]),('pt',['--pt_BR']),('en-contrast',['--contrast']),('pt-contrast',['--pt_BR','--contrast'])]:
    commands.append(('standard-'+locale,['tools/shot.py','sprites/0020',*scenes,*flags]))
    commands.append(('title-'+locale,['tools/shot.py','sprites/0020','--title',*flags]))
start = next((arg.split('=',1)[1] for arg in sys.argv[1:] if arg.startswith('--start=')), None)
results = []
if start:
    names = [name for name, _ in commands]
    assert start in names
    commands = commands[names.index(start):]
    if (HERE/'capture-runs.json').exists():
        results = [r for r in json.loads((HERE/'capture-runs.json').read_text(encoding='utf-8')) if r['name'] in names[:names.index(start)]]
for name, args in commands:
    print('START',name,flush=True)
    result = subprocess.run([sys.executable,'-u',*args],cwd=ROOT,capture_output=True,text=True,encoding='utf-8',errors='replace')
    output = result.stdout+result.stderr
    (HERE/(name+'.log')).write_text(output.rstrip()+'\n',encoding='utf-8',newline='\n')
    results.append(dict(name=name,command=args,exit_code=result.returncode))
    (HERE/'capture-runs.json').write_text(json.dumps(results,indent=2)+'\n',encoding='utf-8',newline='\n')
    print('END',name,result.returncode,output.strip().splitlines()[-1:] if output.strip() else '',flush=True)
    if result.returncode:
        print(output,flush=True)
        sys.exit(result.returncode)
print('PASS: all final renderer scenarios captured',flush=True)
