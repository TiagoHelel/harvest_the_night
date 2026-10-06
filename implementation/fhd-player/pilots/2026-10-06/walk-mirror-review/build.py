"""Exact horizontal mirroring of selected32px walk sources; isolated comparison."""
from pathlib import Path
import hashlib
import json
import sys
from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[4]
BASE = ROOT/'implementation/fhd-enemies/pilots/2026-10-05/16px-review'
DIRECTIONS = ['down','right','up','left','down-right','up-right','up-left','down-left']
MIRRORS = {'left':'right','down-right':'down-left','up-left':'up-right'}
sys.path.insert(0,str(ROOT/'implementation/fhd-player/pilots/2026-10-04/idle-grounded-review'))
from build_preview import gif


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def export():
    approved=json.loads((BASE/'contract.json').read_text())['farmer32']['assets']
    expected={e['name']:e['outputs']['runtime-80']['sha256'] for e in approved}
    entries=[]
    for direction in DIRECTIONS:
        for frame in range(1,9):
            source_direction=MIRRORS.get(direction,direction)
            name=f'walk/{source_direction}/{frame:02}.png'
            source=BASE/'farmer32/runtime-80'/name
            assert sha(source)==expected[name], f'Approved source changed:{name}'
            original=Image.open(source).convert('RGBA')
            native=Image.open(BASE/'farmer32/native-40'/name).convert('RGBA')
            assert original.size==(80,80) and native.size==(40,40)
            assert native.resize((80,80),Image.Resampling.NEAREST).tobytes()==original.tobytes()
            after=original.transpose(Image.Transpose.FLIP_LEFT_RIGHT) if direction in MIRRORS else original.copy()
            small=native.transpose(Image.Transpose.FLIP_LEFT_RIGHT) if direction in MIRRORS else native.copy()
            assert after.tobytes()==small.resize((80,80),Image.Resampling.NEAREST).tobytes()
            assert set(after.get_flattened_data())==set(original.get_flattened_data())
            assert set(after.getchannel('A').get_flattened_data())<={0,255}
            outputs={}
            for folder,image in [('runtime-80',after),('native-40',small)]:
                path=HERE/folder/'walk'/direction/f'{frame:02}.png'
                path.parent.mkdir(parents=True,exist_ok=True);image.save(path)
                outputs[folder]={'path':path.relative_to(ROOT).as_posix(),'sha256':sha(path)}
            before=BASE/f'farmer32/runtime-80/walk/{direction}/{frame:02}.png'
            assert sha(before)==expected[f'walk/{direction}/{frame:02}.png']
            entries.append({'direction':direction,'frame':frame,'before':before.relative_to(ROOT).as_posix(),
                            'before_sha256':sha(before),'source':source.relative_to(ROOT).as_posix(),
                            'source_sha256':sha(source),'mirrored':direction in MIRRORS,'outputs':outputs})
    contract={'date':'2026-10-06','status':'review only','runtime_integrated':False,
              'method':'Exact horizontal FLIP_LEFT_RIGHT of whole transparent canvas; no generation, recoloring or retiming',
              'mirrors':MIRRORS,'directions':DIRECTIONS,'frame_seconds':0.1,'frames_per_direction':8,
              'runtime_canvas_wh':[80,80],'runtime_pivot_xy':[40,72],'runtime_draw_scale':0.5,
              'native_canvas_wh':[40,40],'native_pivot_xy':[20,36],
              'idle_changed':False,'work_changed':False,'assets':entries}
    (HERE/'contract.json').write_text(json.dumps(contract,indent=2)+'\n',encoding='utf-8')
    print('Exported64 walk frames in native40/runtime80:24 mirrored,40 unchanged. Originals preserved.')


def rendered():
    font=ImageFont.truetype('C:/Windows/Fonts/consola.ttf',18)
    for light in ['day','night']:
        full=[];changed=[]
        for frame in range(1,9):
            sheet=Image.new('RGB',(1920,600),'#20292c');draw=ImageDraw.Draw(sheet)
            detail=Image.new('RGB',(960,600),'#20292c');dd=ImageDraw.Draw(detail)
            for row,variant in enumerate(['before','after']):
                top=row*300
                draw.text((10,top+7),f'{variant.upper()} / WALK32PX / {light.upper()} / FRAME {frame:02}/08 / 10 FPS',font=font,fill='#e9e3cf')
                dd.text((10,top+7),f'{variant.upper()} / {light.upper()} / CHANGED DIRECTIONS / FRAME {frame:02}/08',font=font,fill='#e9e3cf')
                for column,direction in enumerate(DIRECTIONS):
                    path=HERE/f'captures/{light}_{variant}_{direction}_{frame:02}.png'
                    # Unchanged columns reuse the identical before capture.
                    if variant=='after' and direction not in MIRRORS:
                        path=HERE/f'captures/{light}_before_{direction}_{frame:02}.png'
                    image=Image.open(path).convert('RGB')
                    draw.text((column*240+50,top+32),direction.upper()+(' *' if direction in MIRRORS and variant=='after' else ''),font=font,fill='#a6cbc6')
                    sheet.paste(image,(column*240,top+60))
                    if direction in MIRRORS:
                        col=list(MIRRORS).index(direction)
                        text=direction.upper() if variant=='before' else MIRRORS[direction].upper()+' -> '+direction.upper()
                        dd.text((col*320+5,top+32),text,font=font,fill='#a6cbc6')
                        detail.paste(image,(col*320+40,top+60))
            full.append(sheet);changed.append(detail)
            out=HERE/'frames'/light;out.mkdir(parents=True,exist_ok=True)
            sheet.save(out/f'{frame:02}.png')
        gif(full,HERE/f'all-eight-{light}.gif',[100]*8)
        gif(changed,HERE/f'changed-three-{light}.gif',[100]*8)
        full[0].save(HERE/f'poster-{light}.png')
    page='''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>32px walk —mirror before/after</title><style>
body{margin:24px;background:#182426;color:#e9e3cf;font:17px Consolas,monospace}h1{font-size:26px}h2{font-size:21px}p{max-width:1050px;line-height:1.5}img,canvas{image-rendering:pixelated}.overflow{overflow:auto;margin:18px 0}button,select{padding:10px;font:inherit;color:#e9e3cf;background:#344b48;border:1px solid #75958d}a{color:#98dcd6}summary{cursor:pointer}details{margin:28px 0}.controls{display:flex;gap:12px;align-items:center;flex-wrap:wrap}
</style></head><body><h1>32px walk —before / after exact mirroring</h1>
<p>Right → Left · Down-left → Down-right · Up-right → Up-left. Top row: BEFORE. Bottom row: AFTER. The other five directions are identical. All8 frames retain their order and100ms timing. Exact source pixels and the full transparent canvas are mirrored, preserving color, scale and foot pivot.</p>
<p>Walking review only. Idle and tool activities are unchanged. These are actual Godot FHD captures with the same ground and camera; only the character sprite changes. Original approved sources and production sprites are preserved.</p>
<button id="scale">Show actual FHD screen size</button><h2>All eight directions —day</h2><div class="overflow"><img class="full" src="all-eight-day.gif?v=mirror-r1" width="960" height="300" alt="Eight walking directions before and after mirroring"></div>
<h2>Changed directions —day, larger comparison</h2><div class="overflow"><img src="changed-three-day.gif?v=mirror-r1" width="960" height="600" alt="Left, down-right and up-left before and after"></div>
<details><summary>Day/night comparison</summary><h2>All eight —night</h2><div class="overflow"><img class="full" src="all-eight-night.gif?v=mirror-r1" width="960" height="300"></div><div class="overflow"><img src="changed-three-night.gif?v=mirror-r1" width="960" height="600"></div></details>
<h2>Pause and inspect a frame</h2><div class="controls"><select id="light" aria-label="Lighting"><option value="day">Day</option><option value="night">Night</option></select><button id="play">Play</button><button id="previous">Previous</button><button id="next">Next</button><span id="phase">Frame1/8</span></div>
<div class="overflow"><canvas id="inspector" width="1920" height="600" style="width:960px;height:300px"></canvas></div>
<p><a href="contract.json">Mirroring map and exact PNG hashes</a> · <a href="renderer-report.json">Actual renderer evidence</a> · <a href="../../../../fhd-enemies/pilots/2026-10-05/16px-review/index.html?v=z16-r6#farmer32-walk">Original32px review</a></p>
<script>
let frame=0,playing=false,half=true,token=0;const canvas=document.getElementById('inspector'),ctx=canvas.getContext('2d'),light=document.getElementById('light'),play=document.getElementById('play');function draw(){const t=++token;const im=new Image();im.onload=()=>{if(t!==token)return;ctx.imageSmoothingEnabled=false;ctx.drawImage(im,0,0)};im.src='frames/'+light.value+'/'+String(frame+1).padStart(2,'0')+'.png';document.getElementById('phase').textContent='Frame '+(frame+1)+'/8'}function stop(){playing=false;play.textContent='Play'}play.onclick=()=>{playing=!playing;play.textContent=playing?'Pause':'Play'};document.getElementById('previous').onclick=()=>{stop();frame=(frame+7)%8;draw()};document.getElementById('next').onclick=()=>{stop();frame=(frame+1)%8;draw()};light.onchange=draw;setInterval(()=>{if(playing){frame=(frame+1)%8;draw()}},100);document.getElementById('scale').onclick=function(){half=!half;document.querySelectorAll('.full').forEach(im=>{im.width=half?960:1920;im.height=half?300:600});canvas.style.width=(half?960:1920)+'px';canvas.style.height=(half?300:600)+'px';this.textContent=half?'Show actual FHD screen size':'Show at half screen size'};draw();
</script></body></html>'''
    (HERE/'index.html').write_text(page,encoding='utf-8')
    print('Saved horizontal before/after GIFs and frame inspector.')


if __name__=='__main__':
    rendered() if '--rendered' in sys.argv else export()
