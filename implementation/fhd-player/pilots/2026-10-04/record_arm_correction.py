"""Record exact generation prompts and select user-requested arm edits."""
from pathlib import Path
import hashlib
import json
from PIL import Image

ROOT=Path(__file__).resolve().parent
REPO=ROOT.parents[3]
SOURCE=REPO/'assets/art_source/player-fhd/pilots/2026-10-04'
RAW='C:/Users/Helel/.codex/generated_images/01a0f7e5-4a37-7612-b3d9-590f2b3bfba5/'
INITIAL=json.loads((ROOT/'arm-correction-prompts.json').read_text())
REFINE=json.loads((ROOT/'arm-refinement-prompts.json').read_text())
OUTPUTS={
 'walk-up-left': [('arms-r8.png','exec-7b557f8a-e0c3-451a-9727-85c0c38c101c.png',INITIAL['up_left'],
                  'Far right arm moves, but near arm4/5/6 still fails opposite swing; refined.'),
                 ('arms-r9.png','exec-819b4c57-ff57-4e82-93a2-f26f13faba6a.png',REFINE['up_left'],
                  'Selected: both arms counter-swing with far arm occlusion in4/5. User review pending.')],
 'walk-down-right': [('arm-frame04-r6.png','exec-9185141a-5082-4b3e-ae9a-b9f11d5931bf.png',INITIAL['down_right'],
                     'Still shows doubled sleeve at near shoulder; refined.'),
                    ('arm-frame04-r7.png','exec-96536204-fd0c-4186-854f-5b4ba4a464a2.png',REFINE['down_right'],
                     'Selected: one near white sleeve, far forearm emerges behind torso. Only frame4 replaced; pending review.')]
}
for direction,calls in OUTPUTS.items():
    path=ROOT/direction/'generation.json'
    data=json.loads(path.read_text())
    existing={c.get('source') for c in data['calls']}
    for name,raw,args,review in calls:
        file=SOURCE/direction/name
        if name not in existing:
            data['calls'].append({'source':name,'raw_original':RAW+raw,
               'prompt':args['prompt'],'references':args['references'],
               'dimensions':list(Image.open(file).size),'sha256':hashlib.sha256(file.read_bytes()).hexdigest(),
               'date':'2026-10-05','review':review})
    data['date']='2026-10-05'
    data['status']='awaiting user review: arm animation/sleeve correction'
    data['selected_source']='arms-r9.png' if direction=='walk-up-left' else 'materials-r5.png + arm-frame04-r7.png override4'
    data['arm_correction_request']='Right arm does not move; one down-right pose appears to have three arms.'
    if direction=='walk-down-right':
        data['arm_original_crop']={'source':'materials-r5.png','bounds':[1330,0,1774,444],
                                  'output':'arm-frame04-original.png','operation':'lossless crop'}
    data['limitations']=['Preview only, no runtime integration.',
                        'ImageGen edits preserve design, not byte-exact unchanged regions within edited poses.',
                        'Frame-count and scope checks do not prove gait quality; user review remains pending.']
    path.write_text(json.dumps(data,indent=2)+'\n',encoding='utf-8')

status_path=ROOT/'directions-status.json'
status=json.loads(status_path.read_text())
status['walk_up_left'].update({'status':'awaiting_approval','date':'2026-10-05',
    'candidate':'walk-up-left/arms-r9','preview':'walk-up-left/up-diagonals-arms-r9.gif',
    'diagnostic':'up-left-arms-before-after.gif',
    'feedback_addressed':'Far right arm swings across8phases; near left arm4/5/6 corrected for opposing swing.',
    'user_feedback':'Right arm does not move.'})
status['walk_down_right'].update({'status':'awaiting_approval','date':'2026-10-05',
    'candidate':'walk-down-right/materials-r5 + arm-frame04-r7 override4',
    'user_feedback':'One down-right frame appears to have three arms.',
    'previous_approval_date':'2026-10-04',
    'feedback_addressed':'Doubled sleeve in4 replaced by one near sleeve and far forearm behind torso; seven accepted poses byte-identical.'})
status_path.write_text(json.dumps(status,indent=2)+'\n',encoding='utf-8')

left_path=ROOT/'walk-up-left/index.html'
left=left_path.read_text()
left=left.replace('up-diagonals-rebuilt-r7.gif','up-diagonals-arms-r9.gif').replace('tracking-materials-rebuild-r7.gif','tracking-materials-arms-r9.gif')
left=left.replace('up-left-rebuilt-r7','arms-r9').replace('seven-rebuilt-r7','arms-r9')
left=left.replace('All eight up-left poses rebuilt.','Both arms now counter-swing through the up-left cycle.')
left=left.replace('<details open><summary>Track','<details><summary>Track')
if 'Arm correction before and after' not in left:
    left=left.replace('<details><summary>Direction master',
      '<details open><summary>Arm correction before and after, half speed</summary><img src="../up-left-arms-before-after.gif?v=arms-r9" width="640" height="370" alt="Previous static right arm beside corrected swing"></details>\n<details><summary>Direction master')
left_path.write_text(left,encoding='utf-8')
down_path=ROOT/'walk-down-right/index.html'
down=down_path.read_text().replace('diagonal-r5','arms-r7')
down=down.replace('Lower-body revision: narrower trouser legs and compact work boots matching the approved original. Compared with unchanged approved down at the same display scale. Approved by user; next direction is up-right.',
 'Frame4 arm cleanup: one visible near sleeve; far forearm partially hidden behind the torso. Frames1-3 and5-8 keep their approved pixels. This repair awaits review.')
down=down.replace('Preview only &middot; Approved','Preview only &middot; Arm correction awaiting review')
down_path.write_text(down,encoding='utf-8')
print('Generation provenance and review pages updated.')
