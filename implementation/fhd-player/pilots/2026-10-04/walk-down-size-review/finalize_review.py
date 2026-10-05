"""Freeze review selection and verify format plus unchanged accepted inputs."""
from pathlib import Path
import hashlib
import json
from PIL import Image

HERE=Path(__file__).resolve().parent
PILOT=HERE.parent
def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()
def save(path,data):
    path.write_text(json.dumps(data,indent=2)+'\n',encoding='utf-8')

report=json.loads((HERE/'validation.json').read_text())
assert report['source']=='down-r3.png'
baseline=json.loads((HERE/'baseline.json').read_text())
assert len(baseline)==64 and all(digest(PILOT/p)==h for p,h in baseline.items())
for m in report['frames_metrics']:
    im=Image.open(HERE/report['candidate_frames']/f"walk-down-{m['frame']:02}.png")
    assert im.size==(80,80) and im.mode=='RGBA'
    assert set(im.getchannel('A').getdata())=={0,255}
gifs={}
for name, dimensions, cadence in [('walk-down-size-review.gif',(990,440),100),
        ('walk-down-size-slow.gif',(1040,390),200),('all-eight-with-new-down.gif',(1440,280),100)]:
    im=Image.open(HERE/name)
    assert im.size==dimensions and im.n_frames==8 and im.info['loop']==0
    durations=[]
    for i in range(8):
        im.seek(i); durations.append(im.info['duration'])
    assert durations==[cadence]*8
    gifs[name]={'dimensions':dimensions,'frames':8,'duration_ms':cadence,'loop':0,'sha256':digest(HERE/name)}
report.update({'gif_checks':gifs,'visual_review':{
    'body_volume':'Fuller frontal bib, sleeves and limbs compared at identical integer2x scale.',
    'height_range':[min(m['height'] for m in report['frames_metrics']),max(m['height'] for m in report['frames_metrics'])],
    'hat_width':33,'right_reference_hat_width':'30-31 native pixels; front view is wider.',
    'gait':'R3 keeps the original pose progression; support changes between halves. R1/R2 rejected for repeated/early switching support.',
    'limits':'Front arms remain subtle. No perfect-motion claim; user size and animation approval is pending.',
    'actual_preview':'index.html?v=down-r3, normal10FPS plus manual controls; browser.png',
    'game_capture':'Not integrated; browser review only.'},
    'engine_verification':{'passed':55,'skipped':0,'failed':0,'duration_s':500,'suite_budget':'OVER BUDGET',
        'headless_asserts':7768,'input_cases':1006,'exports':'PASS','sim_hash':1270427719,'data_hash':8148086,
        'log':'engine-check.log'}})
save(HERE/'validation.json',report)
save(HERE/'down-r3/validation.json',report)
for stem,status,note in [('down-r1','rejected','Repeated screen-right extended leg in most frames.'),
        ('down-r2','rejected','Guide did not produce continuous support progression; premature leg swaps.'),
        ('down-r3','awaiting_approval','Selected size review candidate; original front gait retained as reference.')]:
    path=HERE/f'{stem}.call.json'; data=json.loads(path.read_text())
    data.update({'status':status,'visual_result':note});save(path,data)
request=json.loads((HERE/'request.json').read_text())
request.update({'status':'awaiting_approval','selected_source':report['source'],
    'candidate':report['candidate_frames'],'preview':'index.html?v=down-r3',
    'candidate_frame_sha256':{f"walk-down-{m['frame']:02}.png":m['sha256'] for m in report['frames_metrics']}})
save(HERE/'request.json',request)
status_path=PILOT/'directions-status.json'; status=json.loads(status_path.read_text())
status['walk_down']['size_refinement_review']={'date':'2026-10-05','status':'awaiting_approval',
    'user_feedback':'Down looks smaller than the other directions; regenerate it first, then repaint trousers.',
    'candidate':'walk-down-size-review/down-r3/frames','preview':'walk-down-size-review/index.html?v=down-r3',
    'native_height_range':[63,65],'original_approved_frames_retained':True,
    'palette_harmonization':'deferred until after down approval','runtime_integrated':False}
if 'down-size-refinement' not in status['pending_reviews']:
    status['pending_reviews'].append('down-size-refinement')
save(status_path,status)
print('PASS: eight native frames, three timed GIFs, 64 original selected frame hashes unchanged; awaiting approval.')
