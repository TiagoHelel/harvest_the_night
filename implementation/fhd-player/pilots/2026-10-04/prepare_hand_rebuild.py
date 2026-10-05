"""Archive the rejected hand cycle and pack untouched references for ImageGen."""
from pathlib import Path
import hashlib
import json
import shutil
from PIL import Image

ROOT=Path(__file__).resolve().parent
SOURCE=ROOT.parents[3]/'assets/art_source/player-fhd/pilots/2026-10-04'
assert not (ROOT/'hand-rebuild-baseline.json').exists(),'Preserve existing baseline.'
baseline={str(p.relative_to(ROOT)).replace('\\','/'):hashlib.sha256(p.read_bytes()).hexdigest()
          for p in ROOT.glob('walk-*/frames/*.png')}
(ROOT/'hand-rebuild-baseline.json').write_text(json.dumps(baseline,indent=2)+'\n')
for direction in ['up-right','up-left']:
    folder=ROOT/f'walk-{direction}'
    archive=folder/'before-hand-rebuild'
    archive.mkdir()
    shutil.copytree(folder/'frames',archive/'frames')
    for name in ['generation.json','validation.json','index.html','contact-sheet.png']:
        shutil.copy2(folder/name,archive/name)
    native=Image.new('RGBA',(320,160))
    for i in range(8):
        im=Image.open(folder/f'frames/walk-{direction}-{i+1:02}.png').convert('RGBA')
        native.alpha_composite(im,((i%4)*80,(i//4)*80))
    native.resize((1920,960),Image.Resampling.NEAREST).save(SOURCE/f'walk-{direction}/hand-rebuild-reference.png')
down=Image.open(ROOT/'walk-down/frames/walk-down-01.png').convert('RGBA')
down.resize((800,800),Image.Resampling.NEAREST).save(SOURCE/'approved-hand-proportions-reference.png')
print('Archived R13 native poses and packed references without editing artwork.')
