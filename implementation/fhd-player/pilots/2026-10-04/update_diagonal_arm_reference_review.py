"""Publish preview-only reference edits with source ownership and pending review."""
from pathlib import Path
import hashlib
import json
import shutil
from PIL import Image

ROOT=Path(__file__).resolve().parent
SOURCE=ROOT.parents[3]/'assets/art_source/player-fhd/pilots/2026-10-04'

def publish(revision):
    selection=json.loads((ROOT/'diagonal-arm-reference-selection.json').read_text())
    calls=json.loads((ROOT/'diagonal-arm-reference-calls.json').read_text())
    status=json.loads((ROOT/'directions-status.json').read_text())
    for d,selected in selection.items():
        folder=ROOT/f'walk-{d}'
        generation=json.loads((folder/'generation.json').read_text())
        for call in calls[d]:
            source=SOURCE/f'walk-{d}'/call['source']
            call.update(source_sha256=hashlib.sha256(source.read_bytes()).hexdigest(),
                        source_dimensions=list(Image.open(source).size),date='2026-10-05',
                        tool='built-in ImageGen')
            if not any(c.get('source')==call['source'] for c in generation['calls']):
                generation['calls'].append(call)
        generation['diagonal_arm_reference']={'date':'2026-10-05','baseline':'before-diagonal-arm-reference',
            'feedback':'Arms are still poor; use another approved diagonal walk as reference.',
            'reference':'Seven approved original DOWN-RIGHT R5 poses; reopened pose4 excluded.',
            'scope':'Both upper-diagonal arms and hands; preview only. No runtime integration.',
            'result':'Three evaluated revisions per direction; none met the visual gate. Current native sources retained.',
            'comparison_source':selected,'comparison_preview':f'up-diagonal-reference-arms-{revision}.gif',
            'limitations':'Generated target edits preserve design, not byte-exact body pixels; comparison candidates are rejected.'}
        (folder/'generation.json').write_text(json.dumps(generation,indent=2)+'\n')
        entry=status[f'walk_{d.replace("-","_")}']
        entry['diagonal_reference_attempt']={'date':'2026-10-05','status':'visual_gate_failed',
                     'comparison_source':selected,'preview':f'up-diagonal-reference-arms-{revision}.gif',
                     'user_feedback':'Use another approved diagonal walk as arm reference.',
                     'result':'All three revisions rejected; native frames and active candidate retained.'}
    (ROOT/'directions-status.json').write_text(json.dumps(status,indent=2)+'\n')
    (ROOT/'diagonal-arm-reference-calls.json').write_text(json.dumps(calls,indent=2)+'\n')
    html='''<!doctype html>
<html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Farmer - diagonal reference arm review</title>
<style>body{margin:24px;background:#172225;color:#e9e3cf;font:16px system-ui}main{max-width:1280px;margin:auto}h1{font-size:26px}p{color:#b7ccc7}img{image-rendering:pixelated;max-width:none;height:auto}.clip{overflow-x:auto}button,a{color:#e9e3cf}button{background:#344b48;border:1px solid #66847c;padding:10px 18px;cursor:pointer;margin:8px}canvas{image-rendering:pixelated;width:320px;height:320px;background:#303a3e}details{margin-top:24px}summary{cursor:pointer}small{color:#b7ccc7}.poses{display:flex;gap:20px;flex-wrap:wrap}</style>
<main><h1>Farmer &middot; Diagonal arm reference</h1>
<p>DOWN-RIGHT motion reference beside the new rear-diagonal attempts. These candidates were not accepted: arm continuity is still unresolved. Current sprites are preserved. Normal playback: 10 fps.</p>
<div class="clip"><img src="../up-diagonal-reference-arms-REV.gif?v=diagonal-reference-REV" width="960" height="360" alt="Down-right reference beside up-right and up-left revised walking arms"></div>
<details><summary>Slow before and after</summary><div class="clip"><img src="../up-diagonal-reference-before-after-REV.gif?v=diagonal-reference-REV" width="1280" height="380" alt="Previous and revised rear diagonals at half speed"></div></details>
<details><summary>Inspect individual frames</summary>
<p><button id="back">Previous</button><button id="next">Next</button><span id="count">Frame 1 / 8</span></p>
<div class="poses"><div><p>DOWN-RIGHT REFERENCE</p><canvas width="80" height="80" id="reference"></canvas></div><div><p>UP-RIGHT</p><canvas width="80" height="80" id="right"></canvas></div><div><p>UP-LEFT</p><canvas width="80" height="80" id="left"></canvas></div></div></details>
<p><a href="../all-walk-directions-hands-r15.gif?v=hands-r15">All seven current walk directions (preserved)</a></p>
<p><small>Comparison only &middot; Not accepted. Reference pose 4 displays the separate repair still in review; the other seven reference poses are approved.</small></p></main>
<script>
const paths={reference:'down-right',right:'up-right',left:'up-left'};
const series=Object.fromEntries(Object.entries(paths).map(([key,d])=>[key,Array.from({length:8},(_,i)=>{let im=new Image();const folder=key==='reference'?'frames':'reference-arm-candidate';im.src=`../walk-${d}/${folder}/walk-${d}-${String(i+1).padStart(2,'0')}.png?v=diagonal-reference-REV`;return im})]));let index=0;
function show(){for(const d of Object.keys(paths)){const ctx=document.getElementById(d).getContext('2d');ctx.imageSmoothingEnabled=false;ctx.clearRect(0,0,80,80);if(series[d][index].complete)ctx.drawImage(series[d][index],0,0)}document.getElementById('count').textContent=`Frame ${index+1} / 8`}
for(const images of Object.values(series))for(const im of images)im.onload=show;
document.getElementById('next').onclick=()=>{index=(index+1)%8;show()};document.getElementById('back').onclick=()=>{index=(index+7)%8;show()};
</script></html>
'''.replace('REV',revision)
    for d in selection: (ROOT/f'walk-{d}/index.html').write_text(html,encoding='utf-8')
    (ROOT/'up-diagonal-arms.html').write_text(html.replace('../',''),encoding='utf-8')

if __name__=='__main__':
    import sys
    publish(sys.argv[1])
