"""Preview idle/walk/idle without modifying any approved walking frame."""
from pathlib import Path
import sys
from PIL import Image,ImageDraw,ImageFont

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[4]
sys.path.insert(0,str(HERE))
from prepare import DIRS

def label(draw,xy,text,size=15):
    draw.text(xy,text,font=ImageFont.truetype('C:/Windows/Fonts/consola.ttf',size),fill='#e9e3cf')

def gif(images,path,durations):
    montage=Image.new('RGB',(images[0].width,images[0].height*len(images)))
    for i,im in enumerate(images):montage.paste(im,(0,i*im.height))
    palette=montage.quantize(colors=256)
    quantized=[im.quantize(palette=palette,dither=Image.Dither.NONE) for im in images]
    quantized[0].save(path,save_all=True,append_images=quantized[1:],loop=0,duration=durations,disposal=2,optimize=False)

def preview():
    images=[]
    for phase in range(18):
        sheet=Image.new('RGBA',(1440,265),'#20292c');draw=ImageDraw.Draw(sheet)
        mode='IDLE — BOTH FEET RESTING' if phase in [0,17] else f'WALK — APPROVED FRAME {(phase-1)%8+1}/8'
        label(draw,(18,12),mode,20)
        for j,(direction,suffix) in enumerate(DIRS.items()):
            path=ROOT/f'sprites/actors/idle_{suffix}_0.png' if phase in [0,17] else ROOT/f'sprites/actors/walk_{suffix}_{(phase-1)%8}.png'
            im=Image.open(path).convert('RGBA')
            label(draw,(j*180+10,48),direction.upper())
            sheet.alpha_composite(im.resize((160,160),Image.Resampling.NEAREST),(j*180,80))
        images.append(sheet.convert('RGB'))
    gif(images,HERE/'idle-walk-idle-all-eight.gif',[400]+[100]*16+[400])
    html='''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Grounded idle — eight directions</title><style>body{margin:20px;background:#182426;color:#e9e3cf;font:17px Consolas,monospace}h1{font-size:24px}h2{font-size:20px}img{image-rendering:pixelated}a{color:#98dcd6}.overflow{overflow:auto;margin:22px 0}button{background:#344b48;color:#e9e3cf;border:1px solid #75958d;padding:12px;font:inherit}details{margin:20px 0}</style>
<h1>Grounded idle — all eight directions</h1><p>Stopped poses now have resting boots. The 64 approved walking frames, their order and their blue palette are preserved.</p>
<p>80px native cells, ground pivot (40,72), 64px artwork / 128px screen height at 1920×1080.</p><button id="scale">Show all eight at native 1x</button>
<section id="diagonal-review"><h2>Up-left legs / up-right hips — revised walk preview</h2><p>Current and candidate side by side, eight frames at 10 FPS, shown at the actual FHD artwork size. Awaiting your motion review.</p>
<img src="diagonal-candidate/before-after.gif?v=diagonal-r4" width="960" height="300">
<details><summary>Inspect diagonal walking frames</summary><button id="previous">Previous</button> <button id="next">Next</button> <span id="number">Frame 1 / 8</span><div id="inspection" style="display:flex;gap:25px;margin:20px 0;overflow:auto"></div></details>
<details><summary>Revised walk in the actual Godot renderer — day and night</summary><div class="overflow"><img class="wide" src="diagonal-candidate/runtime-idle-walk-idle.gif?v=diagonal-r4" width="1440" height="510"></div></details></section>
<h2>Standing still — integrated fix</h2><div class="overflow"><img class="wide" src="idle-all-eight.png?v=grounded-r1" width="1440" height="240"></div>
<h2>Idle → walk → idle / 10 FPS</h2><div class="overflow"><img class="wide" src="idle-walk-idle-all-eight.gif?v=grounded-r1" width="1440" height="265"></div>
<details><summary>Before: a lifted walking foot held as idle</summary><img src="before-idle.png" width="960" height="600"></details>
<h2>Production renderer / day and night</h2><p>30Hz core movement and view clock; a capture every 100ms. Two preserved walk loops between grounded stops.</p>
<div class="overflow"><img class="wide" src="runtime-idle-walk-idle.gif?v=grounded-r1" width="1440" height="510"></div>
<p><a href="runtime-idle-contract.json">Source and geometry contract</a> · <a href="runtime-capture-report.json">Actual renderer report</a> · <a href="../palette-variants/index.html">Approved garment palettes</a></p>
<script>let small=false;document.getElementById('scale').onclick=function(){small=!small;document.querySelectorAll('.wide').forEach(im=>{const ratio=small?.5:2;im.width=Math.round(im.width*ratio);im.height=Math.round(im.height*ratio)});this.textContent=small?'Show FHD display size (2x native)':'Show all eight at native 1x'};
let frame=0;const root='/sprites/actors/';function inspect(d){frame=(frame+d+8)%8;document.getElementById('number').textContent=`Frame ${frame+1} / 8`;const n=String(frame+1).padStart(2,'0');document.getElementById('inspection').innerHTML=[['up-left','north_west'],['up-right','north_east']].map(([dir,suffix])=>`<div>${dir} CURRENT<br><img src="${root}walk_${suffix}_${frame}.png" width="240" height="240"></div><div>${dir} CANDIDATE<br><img src="diagonal-candidate/frames/${dir}/${n}.png?v=diagonal-r4" width="240" height="240"></div>`).join('')};document.getElementById('previous').onclick=()=>inspect(-1);document.getElementById('next').onclick=()=>inspect(1);inspect(0);
</script></html>'''
    (HERE/'index.html').write_text(html,encoding='utf-8')
    print('Preview saved: same blue walk with dedicated grounded idle before and after.')

def renderer(target=HERE):
    images=[]
    for i in range(24):
        sheet=Image.new('RGB',(1440,510),'#20292c');draw=ImageDraw.Draw(sheet)
        for row,light in enumerate(['day','night']):
            label(draw,(12,row*255+10),f'GODOT {light.upper()} / '+('IDLE' if i<4 or i>=20 else 'WALK'),18)
            for j,(direction,suffix) in enumerate(DIRS.items()):
                im=Image.open(target/f'runtime-captures/{light}_{suffix}_{i:02}.png').convert('RGB')
                sheet.paste(im.crop((38,0,218,208)),(j*180,row*255+42))
                label(draw,(j*180+8,row*255+29),direction.upper(),12)
        images.append(sheet)
    gif(images,target/'runtime-idle-walk-idle.gif',100)
    images[0].save(target/'runtime-idle-poster.png')
    print('Renderer playback saved: 16 sequences, 24 physical FHD crops each, 100ms per capture.')

if __name__=='__main__':
    renderer(HERE/'diagonal-candidate' if '--candidate' in sys.argv else HERE) if '--renderer' in sys.argv else preview()
