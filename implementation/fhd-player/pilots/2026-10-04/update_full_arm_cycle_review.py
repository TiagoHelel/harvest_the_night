"""Refresh existing approval pages and keep rejected candidates in provenance."""
from pathlib import Path
import hashlib
import json
from PIL import Image

ROOT=Path(__file__).resolve().parent
REPO=ROOT.parents[3]
SOURCE=REPO/'assets/art_source/player-fhd/pilots/2026-10-04'
GENERATED=Path('C:/Users/Helel/.codex/generated_images/01a0f7e5-4a37-7612-b3d9-590f2b3bfba5')
originals={
    'up-right':['exec-59ec64c4-a3b4-4172-ae28-cbadd5caa4ce.png',
                'exec-4aa08ac9-39fd-4f90-bf6b-ace6986fbc44.png',
                'exec-afb6dddc-e86d-4bc8-b51d-08b72c0a9f00.png'],
    'up-left':['exec-88c0ecbe-4dff-4065-86a6-53cc564b4a5b.png',
               'exec-b8e78d61-cf90-44b7-94c3-bcf80f9dd0da.png',
               'exec-1f492339-57be-4aea-8e8e-1ae7cbac12df.png']}
prompt_files=['full-arm-cycle-prompts.json','full-arm-cycle-refinement-prompts.json',
              'full-arm-cycle-material-prompts.json']
source_files=['full-arm-tracking-r11.png','full-arm-tracking-r12.png','full-arm-materials-r13.png']
reviews={
    'up-right':['Not selected: far left diagnostic lower-extent travel4px; near right8px.',
                'Diagnostic only: far left5px fails6px planned motion gate; near right7px.',
                'Final review candidate: larger left arm arc, restored peach skin. Visual approval pending.'],
    'up-left':['Not selected: near left8px, far right5px fails6px planned motion gate.',
               'Diagnostic: near left9px, far right7px, no adjacent identical masks. Numeric checks are not visual approval.',
               'Final review candidate: both arms change poses; near-arm7-to8 rises more abruptly than requested. Visual approval pending.']}
status=json.loads((ROOT/'directions-status.json').read_text())
for direction in ['up-right','up-left']:
    folder=ROOT/f'walk-{direction}'
    key=direction.replace('-','_')
    entry=status[f'walk_{key}']
    old=entry['candidate']
    entry.update(status='awaiting_approval',rejected_candidate=old,
                 candidate=f'walk-{direction}/full-arm-materials-r13',
                 preview='up-diagonal-full-arms-r13.gif',
                 diagnostic='up-diagonal-full-arms-before-after-r13.gif',
                 user_feedback='UP-RIGHT left arm barely moves; UP-LEFT arm stays static in most poses.',
                 feedback_addressed='Rebuilt all eight shoulder/elbow/hand chains using fixed cyan-left/pink-right arm identities.',
                 review_limit='Motion quality awaits user review; UP-LEFT near-arm7-to8 remains brisk.',date='2026-10-05')
    path=folder/'generation.json'
    generation=json.loads(path.read_text())
    generation['status']='awaiting visual review: full arm cycle'
    generation['selected_source']='full-arm-materials-r13.png'
    generation['selected_preview']='up-diagonal-full-arms-r13.gif'
    generation['full_arm_cycle']={'date':'2026-10-05','rejected_previous_candidate':old,
        'attempts_per_direction':3,'baseline_archive':'before-full-arm-cycle',
        'scope':'All eight native poses in both upper diagonals; other40 native poses byte-identical.',
        'diagnostic_colors':'CYAN anatomical left arm; PINK anatomical right arm',
        'limits':'Color tracking evaluates a diagnostic source; material restoration is not pixel-identical and does not prove final motion quality.'}
    for index,(filename,prompt_file,original) in enumerate(zip(source_files,prompt_files,originals[direction])):
        if any(c.get('source')==filename for c in generation['calls']): continue
        p=json.loads((ROOT/prompt_file).read_text())[key]
        raw=SOURCE/f'walk-{direction}'/filename
        generation['calls'].append({'tool':'built-in ImageGen','date':'2026-10-05',
            'source':filename,'raw_original':str(GENERATED/original).replace('\\','/'),
            'prompt_file':str((ROOT/prompt_file).relative_to(REPO)).replace('\\','/'),
            'prompt_key':key,'exact_prompt':p['prompt'],'references':p['references'],
            'source_dimensions':list(Image.open(raw).size),
            'source_sha256':hashlib.sha256(raw.read_bytes()).hexdigest(),
            'transparent_background':True,'review':reviews[direction][index]})
    path.write_text(json.dumps(generation,indent=2)+'\n')
    html='''<!doctype html>
<html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Farmer - upper diagonal arm review</title>
<style>body{margin:32px;background:#172225;color:#e9e3cf;font:16px system-ui}main{max-width:1100px;margin:auto}h1{font-size:26px}p{color:#b7ccc7}img{image-rendering:pixelated;max-width:100%;height:auto}button,a{color:#e9e3cf}button{background:#344b48;border:1px solid #66847c;padding:10px 18px;cursor:pointer;margin:8px}canvas{image-rendering:pixelated;width:320px;height:320px;background:#303a3e}details{margin-top:24px}summary{cursor:pointer}small{color:#b7ccc7}.poses{display:flex;gap:20px;flex-wrap:wrap}</style>
<main><h1>Farmer &middot; Upper diagonal arms</h1>
<p>Both arms revised across all eight poses. Normal playback: 10 fps. Compare the two directions at the same display scale.</p>
<img src="../up-diagonal-full-arms-r13.gif?v=full-arms-r13" width="1040" height="420" alt="Up-right and up-left revised arm cycles at FHD size and enlarged">
<details><summary>Slow before and after</summary><img src="../up-diagonal-full-arms-before-after-r13.gif?v=full-arms-r13" width="1280" height="380" alt="Previous and revised arm cycles, both directions, half speed"></details>
<details><summary>Track both arm identities</summary><p>Cyan: anatomical left arm. Pink: anatomical right arm. Colored drafts alongside final skin materials.</p><img src="../up-diagonal-full-arms-tracking-r13.gif?v=full-arms-r13" width="1280" height="380" alt="Left and right arm identity tracking in both diagonals"></details>
<details><summary>Inspect individual frames</summary>
<p><button id="back">Previous</button><button id="next">Next</button><span id="count">Frame 1 / 8</span></p>
<div class="poses"><div><p>UP-RIGHT</p><canvas width="80" height="80" id="right"></canvas></div><div><p>UP-LEFT</p><canvas width="80" height="80" id="left"></canvas></div></div></details>
<p><a href="../all-walk-directions-full-arms-r13.gif?v=full-arms-r13">All seven current walk directions</a></p>
<p><small>Preview only &middot; Awaiting visual approval &middot; UP-LEFT near arm7-to8 still rises briskly.</small></p></main>
<script>
const series=Object.fromEntries(['right','left'].map(d=>[d,Array.from({length:8},(_,i)=>{let im=new Image();im.src=`../walk-up-${d}/frames/walk-up-${d}-${String(i+1).padStart(2,'0')}.png?v=full-arms-r13`;return im})]));let index=0;
function show(){for(const d of ['right','left']){const ctx=document.getElementById(d).getContext('2d');ctx.imageSmoothingEnabled=false;ctx.clearRect(0,0,80,80);if(series[d][index].complete)ctx.drawImage(series[d][index],0,0)}document.getElementById('count').textContent=`Frame ${index+1} / 8`}
for(const images of Object.values(series))for(const im of images)im.onload=show;
document.getElementById('next').onclick=()=>{index=(index+1)%8;show()};document.getElementById('back').onclick=()=>{index=(index+7)%8;show()};
</script></html>
'''
    (folder/'index.html').write_text(html,encoding='utf-8')
(ROOT/'directions-status.json').write_text(json.dumps(status,indent=2)+'\n')
focused=html.replace('../up-diagonal','up-diagonal').replace('../all-walk','all-walk').replace('../walk-up-','walk-up-')
(ROOT/'up-diagonal-arms.html').write_text(focused,encoding='utf-8')
