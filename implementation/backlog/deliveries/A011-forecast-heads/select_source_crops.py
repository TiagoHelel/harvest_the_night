"""Record explicit crop authorization and snapshot current enemy sprites unchanged."""
from pathlib import Path
import json, shutil, hashlib
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3]
words='ficou bem incoerente, faz um recorte da cabeca dos sprites atuais que dai nao tem erro'
regions={'walker':[24,15,12,13],'runner':[26,15,13,13],'tank':[27,15,11,13],'breaker':[28,15,11,13],'giant':[28,19,14,14]}
retired=HERE/'retired/generated-heads';retired.mkdir(parents=True,exist_ok=True)
if not (HERE/'head-crops.json').exists():
    for name in ('contract.json','recipes.json','build.py','checks.json','index.html','final-rebuild-proof.json'):
        path=HERE/name
        if path.exists():shutil.copy2(path,retired/('original-'+name))
    for path in (HERE/'native').rglob('*.png'):
        target=retired/path.relative_to(HERE)
        assert target.resolve().is_relative_to(retired.resolve())
        target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(path,target)
entries=[]
for kind,crop in regions.items():
    source=ROOT/f'sprites/enemies/{kind}_walk_0.png'
    snapshot=HERE/f'raw/current-{kind}-walk-0.png'
    if snapshot.exists(): assert snapshot.read_bytes()==source.read_bytes()
    else: shutil.copy2(source,snapshot)
    entries.append({'kind':kind,'source':snapshot.relative_to(HERE).as_posix(),
        'original_source':source.relative_to(ROOT).as_posix(),
        'source_sha256':hashlib.sha256(snapshot.read_bytes()).hexdigest(),'crop_xywh':crop,
        'trim_transparent_border':True,'scale':1,'recolor':False})
(HERE/'head-crops.json').write_text(json.dumps({'date':'2026-10-08','owner_words':words,
    'method':'exact crop of current runtime sprites; transparent padding only',
    'canvas_wh':[16,16],'pivot_xy':[8,8],'entries':entries},indent=2)+'\n',encoding='utf-8')
with (HERE/'review-log.txt').open('a',encoding='utf-8') as log:
    log.write('2026-10-08 | Owner words verbatim: '+words+'\n')
    log.write('2026-10-08 | Replaced generated heads with exact crops of the current five enemy walk frame 0 sprites. No ImageGen, resizing, recoloring, pixel painting or game edits. Original heads retained under retired/generated-heads.\n')
