"""Pack accepted diagonal motion references and archive current review poses."""
from pathlib import Path
import hashlib
import json
import shutil
from PIL import Image

ROOT=Path(__file__).resolve().parent
SOURCE=ROOT.parents[3]/'assets/art_source/player-fhd/pilots/2026-10-04'
assert not (ROOT/'diagonal-arm-reference-baseline.json').exists(),'Preserve the baseline.'
baseline={str(p.relative_to(ROOT)).replace('\\','/'):hashlib.sha256(p.read_bytes()).hexdigest()
          for p in ROOT.glob('walk-*/frames/*.png')}
(ROOT/'diagonal-arm-reference-baseline.json').write_text(json.dumps(baseline,indent=2)+'\n')
approved=Image.new('RGBA',(320,160))
reference_inputs=[]
for i in range(8):
    # Original R5 was approved, then pose4 was reopened for a doubled sleeve.
    # Exclude that pose from the approved motion source rather than implying
    # approval of the separate recent repair.
    if i==3: continue
    path=ROOT/f'walk-down-right/before-arms-2026-10-05/frames/walk-down-right-{i+1:02}.png'
    im=Image.open(path).convert('RGBA')
    approved.alpha_composite(im,((i%4)*80,(i//4)*80))
    reference_inputs.append({'frame':i+1,'path':str(path.relative_to(ROOT)).replace('\\','/'),
                             'sha256':hashlib.sha256(path.read_bytes()).hexdigest()})
approved.resize((1920,960),Image.Resampling.NEAREST).save(SOURCE/'approved-diagonal-arm-motion-reference.png')
for direction in ['up-right','up-left']:
    folder=ROOT/f'walk-{direction}'; archive=folder/'before-diagonal-arm-reference'
    archive.mkdir(); shutil.copytree(folder/'frames',archive/'frames')
    for name in ['generation.json','validation.json','index.html','contact-sheet.png']:
        shutil.copy2(folder/name,archive/name)
    native=Image.new('RGBA',(320,160))
    for i in range(8):
        native.alpha_composite(Image.open(folder/f'frames/walk-{direction}-{i+1:02}.png').convert('RGBA'),
                               ((i%4)*80,(i//4)*80))
    native.resize((1920,960),Image.Resampling.NEAREST).save(SOURCE/f'walk-{direction}/diagonal-arm-target-reference.png')
(ROOT/'diagonal-arm-reference-inputs.json').write_text(json.dumps({
    'gait_source':'Approved DOWN-RIGHT R5 cycle, excluding reopened pose4.',
    'accepted_motion_frames':reference_inputs,'omitted_reference_frames':[4],
    'frame4_rule':'Interpolate target arm poses3-to5; do not copy the doubled sleeve or assume approval of R7repair.',
    'operations':['Unmodified RGBA frame packing','Integer6x nearest scaling'],
    'source_alpha_preserved':True},indent=2)+'\n')
print('Packed seven approved diagonal poses; omitted reopened pose4.')
