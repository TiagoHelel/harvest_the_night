"""Keep exact edit prompts, source ownership and current review references."""
from pathlib import Path
import hashlib
import json
import shutil
import re
from PIL import Image

ROOT=Path(__file__).resolve().parent
SOURCE=ROOT.parents[3]/'assets/art_source/player-fhd/pilots/2026-10-04'
RAW='C:/Users/Helel/.codex/generated_images/01a0f7e5-4a37-7612-b3d9-590f2b3bfba5/'
INITIAL=json.loads((ROOT/'arm-smoothing-prompts.json').read_text())
REFINE=json.loads((ROOT/'far-arm-refinement-prompt.json').read_text())
FINAL=json.loads((ROOT/'far-arm-final-prompt.json').read_text())
calls={
 'walk-up-right': [('arm-smoothing-r7.png','exec-8f35893b-cc34-433c-85e7-fa569578ddcc.png',INITIAL['up_right'],
      'Rejected: far left hand now visible in1 but still nearly static across8poses.'),
                  ('arm-smoothing-r8.png','exec-5381c709-0d1b-4cf4-b58d-431fdb4acf03.png',REFINE,
      'Rejected: slightly changes far arm but accidentally reverses near arm1/5/8.'),
                  ('arm-smoothing-r9.png','exec-f0fc7e52-2543-4a90-abf2-bafee3ebbfad.png',FINAL,
      'Selected candidate: bent/extended far-arm cycle with near-arm correction. User review pending.')],
 'walk-up-left': [('arm-05-06-r10.png','exec-0228a514-04c1-4a32-8355-0df1bc63081b.png',INITIAL['up_left'],
      'Selected: near left arm stays relaxed by left hip in5/6, no forearm across central back. Only5/6 overridden.')]
}
for direction,items in calls.items():
    path=ROOT/direction/'generation.json'; data=json.loads(path.read_text())
    existing={c.get('source') for c in data['calls']}
    for name,raw,args,review in items:
        file=SOURCE/direction/name
        if name not in existing:
            data['calls'].append({'source':name,'raw_original':RAW+raw,'prompt':args['prompt'],
                'references':args['references'],'dimensions':list(Image.open(file).size),
                'sha256':hashlib.sha256(file.read_bytes()).hexdigest(),'date':'2026-10-05','review':review})
    data['selected_source']='arm-smoothing-r9.png' if direction=='walk-up-right' else 'arms-r9.png + arm-05-06-r10.png override5/6'
    data['status']='awaiting user review: smoother walking arm movement'
    data['arm_smoothing_request']='Up-right left arm pops in/out; up-left arm5/6 extends unnaturally across back.'
    data['limitations']=['Preview only; no runtime integration.',
         'Generated edits preserve design, not byte-exact unchanged regions inside edited poses.',
         'Numeric scope checks do not establish motion quality.']
    if direction=='walk-up-right':
        data['arm_edit_reference']={'source':'before-arm-smoothing/frames/*.png',
            'operation':'lossless320x160packing, nearest6x to1920x960; includes approved recovery7/8'}
    else:
        data['arm_edit_reference']={'source':'arms-r9.png','crop':[0,438,887,887],
            'operation':'lossless two-cell crop of5/6; common native hat-width calibration'}
    path.write_text(json.dumps(data,indent=2)+'\n',encoding='utf-8')

path=ROOT/'directions-status.json'; data=json.loads(path.read_text())
data['walk_up_right'].update({'status':'awaiting_approval','candidate':'walk-up-right/arm-smoothing-r9',
 'preview':'walk-up-right/up-diagonal-arms-r9.gif','diagnostic':'up-diagonal-arms-before-after.gif',
 'user_feedback':'Left arm disappears and appears without fluid motion.',
 'feedback_addressed':'Continuous far left shoulder/elbow/hand cycle with modest arc.',
 'date':'2026-10-05'})
data['walk_up_left'].update({'status':'awaiting_approval','candidate':'walk-up-left/arms-r9 + arm-05-06-r10 override5/6',
 'preview':'walk-up-left/up-diagonals-arms-r10.gif','diagnostic':'up-diagonal-arms-before-after.gif',
 'user_feedback':'Arm goes too far backward in5/6.',
 'feedback_addressed':'Relaxed near arm beside hip in5/6, reduced bend; six other native poses unchanged.',
 'date':'2026-10-05'})
path.write_text(json.dumps(data,indent=2)+'\n',encoding='utf-8')

for name in ['up-right','up-left']:
    path=ROOT/f'walk-{name}/index.html'; html=path.read_text()
    if name=='up-right':
        html=html.replace('up-diagonal-recovery-r6.gif','up-diagonal-arms-r9.gif').replace('up-right-r6','arm-smoothing-r9')
        html=html.replace('Only frames7 and8 revised: the raised foot reaches and lowers into frame1. Frames1 to6 are unchanged.',
          'Far left arm now follows a gradual visible elbow/hand arc through all8poses. Recovery gait7/8 remains the design reference.')
        html=html.replace('Approved2026-10-05','Arm correction awaiting review')
    else:
        html=html.replace('up-diagonals-arms-r9.gif','up-diagonals-arms-r10.gif').replace('tracking-materials-arms-r9.gif','tracking-materials-arms-r10.gif')
        html=html.replace('arms-r9','arm-smoothing-r9')
        html=re.sub(r'<details open><summary>Arm correction before and after, half speed</summary>.*?</details>','',html)
        html=html.replace('Both arms now counter-swing through the up-left cycle. Approved up-right at the same display scale.',
          'Near arm5/6 now swings mildly beside the hip. Six other up-left poses are unchanged. Current up-right at the same display scale.')
        html=html.replace('Approved up-right beside proposed up-left','Current up-right beside proposed up-left')
        html=html.replace('Top row: approved up-right. Bottom row: new up-left.','Top row: current up-right. Bottom row: corrected up-left.')
    html=html.replace('seven-r1','arm-smoothing-r9')
    marker='<details open><summary>Current arm correction comparison</summary><img src="../up-diagonal-arms-before-after.gif?v=arm-smoothing-r9" width="1280" height="380" alt="Both up diagonal arm cycles before and after"></details>\n'
    if 'Current arm correction comparison' not in html:
        html=html.replace('<details><summary>Direction master',marker+'<details><summary>Direction master')
    path.write_text(html,encoding='utf-8')
shutil.copy2(ROOT/'walk-up-right/up-diagonal-comparison.gif',ROOT/'walk-up-right/up-diagonal-arms-r9.gif')
print('Arm smoothing provenance and current HTML references updated.')
