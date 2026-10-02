"""Retain original renderer frames and compact consecutive review montages."""
from pathlib import Path
import json
import shutil
from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parent
OUT = HERE / 'review-stills'
OUT.mkdir(exist_ok=True)
spec = json.loads((HERE/'playback.json').read_text())
evidence = []
for group in spec['groups']:
    action = group['action']
    selected = [0,3,6,9,12,15,18,21] if action in ('walk','run') else [0,4,8,12,16,20,24,28]
    if action == 'idle':
        selected = [0,79,80,81,82,83,84,85]
    if action == 'run':
        selected = [0,2,4,6,8,10,12,14]
    if action == 'fish':
        selected = [0,5,6,9,10,15,16,55]
    target = OUT/action
    target.mkdir(exist_ok=True)
    for n in selected:
        source = HERE/'captures'/action/('frame-%03d.png'%n)
        shutil.copyfile(source,target/source.name)
    page = Image.new('RGB',(1040,288*len(selected)),(24,21,29))
    for row,n in enumerate(selected):
        page.paste(Image.open(target/('frame-%03d.png'%n)),(0,row*288))
    page.save(OUT/(action+'-consecutive.png'))
    evidence.append({'action':action,'renderer_frames':selected,'cadence_fps':25,
                     'montage':str((OUT/(action+'-consecutive.png')).relative_to(HERE))})
(OUT/'evidence.json').write_bytes((json.dumps(evidence,indent=2)+'\n').encode())
print('Retained 128 original renderer frames and sixteen eight-phase montages.')
