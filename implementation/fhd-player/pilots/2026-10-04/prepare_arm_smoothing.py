"""Archive review poses and prepare lossless ImageGen edit references."""
from pathlib import Path
import json
import hashlib
import shutil
from PIL import Image

ROOT=Path(__file__).resolve().parent
SOURCE=ROOT.parents[3]/'assets/art_source/player-fhd/pilots/2026-10-04'
assert not (ROOT/'arm-smoothing-baseline.json').exists(), 'Existing review baseline must be preserved.'
baseline={str(p.relative_to(ROOT)).replace('\\','/'):hashlib.sha256(p.read_bytes()).hexdigest()
          for p in ROOT.glob('walk-*/frames/*.png')}
(ROOT/'arm-smoothing-baseline.json').write_text(json.dumps(baseline,indent=2)+'\n')
for direction in ['walk-up-right','walk-up-left']:
    archive=ROOT/direction/'before-arm-smoothing'
    archive.mkdir(exist_ok=True)
    shutil.copytree(ROOT/direction/'frames',archive/'frames',dirs_exist_ok=True)
    for name in ['export_preview.py','validation.json','generation.json','contact-sheet.png']:
        shutil.copy2(ROOT/direction/name,archive/name)
sheet=Image.new('RGBA',(320,160))
for i in range(8):
    frame=Image.open(ROOT/f'walk-up-right/frames/walk-up-right-{i+1:02}.png').convert('RGBA')
    sheet.alpha_composite(frame,((i%4)*80,(i//4)*80))
sheet.resize((1920,960),Image.Resampling.NEAREST).save(SOURCE/'walk-up-right/arm-smoothing-original.png')
left=Image.open(SOURCE/'walk-up-left/arms-r9.png')
validation=json.loads((ROOT/'walk-up-left/validation.json').read_text())
left.crop((0,validation['source_row_cuts'][1],validation['source_col_cuts'][2],left.height)).save(
    SOURCE/'walk-up-left/arm-05-06-original.png')
print('Archived56frame hashes; prepared UP-RIGHT8poses and UP-LEFT5/6 crops.')
