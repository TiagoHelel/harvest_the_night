"""Export coarser enemy sprites and build a source-preserving review page."""
from pathlib import Path
import hashlib
import json
import sys
from PIL import Image, ImageDraw, ImageFont

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[4]
KINDS=['walker','runner','tank','breaker','giant']
DIRECTIONS=['down','right','up','left','down-right','up-right','up-left','down-left']
PLAYER_REVIEW=ROOT/'implementation/fhd-player/pilots/2026-10-04/idle-grounded-review'
sys.path.insert(0,str(PLAYER_REVIEW))
from build_preview import gif

def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()

def export():
    entries=[]
    farmer_source=ROOT/'assets/art_source/player-fhd/idle-blue-grounded/frames/left.png'
    farmer=Image.open(farmer_source).convert('RGBA')
    native32=farmer.resize((40,40),Image.Resampling.NEAREST)
    runtime32=native32.resize((80,80),Image.Resampling.NEAREST)
    assert set(runtime32.get_flattened_data())<=set(farmer.get_flattened_data())
    farmer_folder=HERE/'farmer32';farmer_folder.mkdir(exist_ok=True)
    native32.save(farmer_folder/'native-40-idle-left.png')
    runtime32.save(farmer_folder/'idle-left.png')
    farmer_entries=[]
    for direction in DIRECTIONS:
        sources=[(f'walk/{direction}/{i:02}.png',ROOT/f'assets/art_source/player-fhd/walk-blue/frames/{direction}/{i:02}.png') for i in range(1,9)]
        sources.append((f'idle/{direction}.png',ROOT/f'assets/art_source/player-fhd/idle-blue-grounded/frames/{direction}.png'))
        for name,source in sources:
            original=Image.open(source).convert('RGBA')
            assert original.size==(80,80)
            native=original.resize((40,40),Image.Resampling.NEAREST)
            runtime=native.resize((80,80),Image.Resampling.NEAREST)
            assert set(runtime.get_flattened_data())<=set(original.get_flattened_data())
            assert set(runtime.getchannel('A').get_flattened_data())<={0,255}
            outputs={}
            for folder,image in [('native-40',native),('runtime-80',runtime)]:
                path=farmer_folder/folder/name;path.parent.mkdir(parents=True,exist_ok=True);image.save(path)
                outputs[folder]={'path':path.relative_to(ROOT).as_posix(),'sha256':sha(path)}
            farmer_entries.append({'source':source.relative_to(ROOT).as_posix(),'source_sha256':sha(source),'name':name,'outputs':outputs})
    for source in sorted((ROOT/'sprites/enemies').glob('*.png')):
        original=Image.open(source).convert('RGBA')
        small=original.resize((original.width//2,original.height//2),Image.Resampling.NEAREST)
        coarse=small.resize(original.size,Image.Resampling.NEAREST)
        assert set(small.getchannel('A').get_flattened_data())<={0,255}
        assert set(small.get_flattened_data())<=set(original.get_flattened_data())
        outputs={}
        for folder,image in [('native-half',small),('runtime-size',coarse)]:
            path=HERE/f'{folder}/{source.name}';path.parent.mkdir(parents=True,exist_ok=True);image.save(path)
            outputs[folder]={'path':path.relative_to(ROOT).as_posix(),'sha256':sha(path)}
        entries.append({'source':source.relative_to(ROOT).as_posix(),'source_sha256':sha(source),
                        'canvas_wh':original.size,'source_content_xyxy':original.getbbox(),
                        'native_content_xyxy':small.getbbox(),'outputs':outputs})
    contract={'date':'2026-10-05','status':'review only','runtime_integrated':False,
              'method':'NEAREST half-size then integer2x NEAREST restore; no redraw or recoloring',
              'FHD_physical_pixels_per_detail_pixel':8,
              'common_enemy_art_height_px':'approximately15–16','giant_art_height_px':'approximately21',
              'original_frame_order_and_ground_pivots':True,'entries':entries}
    contract['farmer32']={'source':farmer_source.relative_to(ROOT).as_posix(),'source_sha256':sha(farmer_source),
                         'output_sha256':sha(farmer_folder/'idle-left.png'),'method':'80->40->80 NEAREST, same idle left pose',
                         'body_height_px':32,'FHD_detail_pixel_size':4,'runtime_integrated':False}
    contract['farmer32']['assets']=farmer_entries
    contract['farmer32']['native_canvas_wh']=[40,40]
    contract['farmer32']['native_pivot_xy']=[20,36]
    contract['farmer32']['runtime_pivot_xy']=[40,72]
    contract['farmer32']['runtime_draw_scale']=0.5
    contract['farmer32']['walk_frame_seconds']=0.1
    farmer16=PLAYER_REVIEW/'resolution-review/16px-assets/runtime-80/idle/left.png'
    contract['farmer16']={'source':farmer16.relative_to(ROOT).as_posix(),'source_sha256':sha(farmer16),'body_height_px':16,'FHD_detail_pixel_size':8}
    (HERE/'contract.json').write_text(json.dumps(contract,indent=2)+'\n')
    frame_list=[]
    for motion,count in [('idle',1),('walk',4),('attack',3),('death',5),('windup',3),('slam',3)]:
        for i in range(count):
            paths=[]
            for kind in KINDS:
                verb=motion;index=i
                if motion=='idle' or (motion in ['windup','slam'] and kind!='giant'):name=kind
                else:
                    if kind=='giant' and motion=='attack':verb='slam'
                    if kind!='giant' and motion=='death':index=min(i,3)
                    name=f'{kind}_{verb}_{index}'
                paths.append(name)
            frame_list.append({'label':f'{motion}_{i}','names':paths})
    (HERE/'frame-list.json').write_text(json.dumps(frame_list,indent=2)+'\n')
    print(f'Exported{len(entries)} enemies; original colors/alpha and production files preserved.')

def frames():
    font=ImageFont.truetype('C:/Windows/Fonts/consola.ttf',18)
    records=json.loads((HERE/'frame-list.json').read_text())
    groups={}
    for record in records:
        label=record['label'];motion=label.rsplit('_',1)[0]
        sheet=Image.new('RGB',(1680,1200),'#20292c');d=ImageDraw.Draw(sheet)
        for row,(light,variant) in enumerate([('day','original'),('day','coarse'),('night','original'),('night','coarse')]):
            top=row*300
            d.text((10,top+7),f'{motion.upper()} / {light.upper()} / '+('CURRENT: ~29px / GIANT ~42px' if variant=='original' else '16PX STYLE: ~15px / GIANT ~21px'),font=font,fill='#e9e3cf')
            for column,kind in enumerate(KINDS+['farmer16px','farmer32px']):
                d.text((column*240+65,top+32),kind.upper(),font=font,fill='#a6cbc6')
            im=Image.open(HERE/f'captures/{light}_{variant}_{label}.png').convert('RGB')
            sheet.paste(im,(0,top+60))
        (HERE/'frames').mkdir(exist_ok=True);sheet.save(HERE/f'frames/{label}.png')
        groups.setdefault(motion,[]).append(sheet)
    for motion,images in groups.items():
        if motion=='walk':durations=[120,130,120,130]
        elif motion=='death':durations=[120]*len(images)
        elif motion=='windup':durations=[200]*len(images)
        else:durations=[100]*len(images)
        if motion!='walk':
            images=images+[groups['idle'][0]];durations=durations+[600]
        gif(images,HERE/f'{motion}-day-night.gif',durations)
    groups['walk'][0].save(HERE/'poster.png')
    farmer_sheets=[]
    for i in range(1,9):
        sheet=Image.new('RGB',(1920,600),'#20292c');d=ImageDraw.Draw(sheet)
        for row,light in enumerate(['day','night']):
            top=row*300
            d.text((10,top+7),f'FARMER32PX / WALK / {light.upper()} / FRAME {i:02}/08 / 10 FPS / ACTUAL FHD SIZE',font=font,fill='#e9e3cf')
            for column,direction in enumerate(DIRECTIONS):
                d.text((column*240+60,top+32),direction.upper(),font=font,fill='#a6cbc6')
                sheet.paste(Image.open(HERE/f'captures/{light}_farmer32_walk_{direction}_{i:02}.png').convert('RGB'),(column*240,top+60))
        farmer_sheets.append(sheet)
    gif(farmer_sheets,HERE/'farmer32-all-eight.gif',[100]*8)
    farmer_sheets[0].save(HERE/'farmer32-all-eight-poster.png')
    html='''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Zombies —16px style review</title>
<style>body{margin:24px;background:#182426;color:#e9e3cf;font:17px Consolas,monospace}h1{font-size:25px}h2{font-size:21px}p{max-width:1000px;line-height:1.5}img{image-rendering:pixelated}.overflow{overflow:auto;margin:18px 0}button,select{padding:10px;font:inherit;color:#e9e3cf;background:#344b48;border:1px solid #75958d}a{color:#98dcd6}details{margin:24px 0}.two{display:flex;gap:28px;flex-wrap:wrap}</style>
<h1>Zombies —16px pixel-density review</h1><p>Walker, Runner, Tank, Breaker and Giant. Each animation compares the current sprites with coarser pixels at the SAME screen size, using actual Godot FHD rendering in day and night.</p>
<p>Current ordinary zombies have about29 artwork pixels of height; the coarser version has about15–16. The Giant changes from about42 to21. The last two columns show the blue FARMER in16px and32px detail, standing in the SAME pose and at the SAME FHD screen size. Each coarse detail pixel spans8 screen pixels at1920×1080. Existing poses and colors are preserved. Review only.</p>
<button id="scale">Show actual FHD screen size</button>
<h2>Walking — zombies beside the 16px and32px farmers</h2><div class="overflow"><img class="wide" src="walk-day-night.gif?v=z16-r6" width="840" height="600"></div>
<details><summary>Attack — ordinary enemies / Giant slam</summary><div class="overflow"><img class="wide" src="attack-day-night.gif?v=z16-r6" width="840" height="600"></div></details>
<details><summary>Death — all five types</summary><div class="overflow"><img class="wide" src="death-day-night.gif?v=z16-r6" width="840" height="600"></div></details>
<details><summary>Giant windup and slam</summary><div class="overflow"><img class="wide" src="windup-day-night.gif?v=z16-r6" width="840" height="600"><img class="wide" src="slam-day-night.gif?v=z16-r6" width="840" height="600"></div></details>
<h2 id="farmer32-walk">Farmer32px — all eight walking directions</h2><p>All approved walking movements:8 frames per direction at10 FPS. The32px detail samples preserve their original frame order, palette, ground pivot and screen size.</p><div class="overflow"><img class="farmerwide" src="farmer32-all-eight.gif?v=z16-r6" width="960" height="300"></div>
<h2>Transparent sprites — frame inspector</h2><p>The existing enemy art has one side-view walking cycle, mirrored for the other side in the game. No additional enemy directions were invented.</p>
<select id="kind"><option>walker</option><option>runner</option><option>tank</option><option>breaker</option><option>giant</option></select>
<select id="motion"><option>walk</option><option>attack</option><option>death</option><option>idle</option><option>windup</option><option>slam</option></select>
<button id="previous">Previous</button> <button id="next">Next</button> <button id="flip">Mirror direction</button> <span id="phase"></span>
<div class="two"><div><p>Current</p><canvas id="current" width="320" height="256"></canvas></div><div><p>16px style</p><canvas id="coarse" width="320" height="256"></canvas></div></div>
<p><a href="contract.json">Source, geometry and output hashes</a> · <a href="renderer-report.json">Actual renderer evidence</a> · <a href="../../../../fhd-player/pilots/2026-10-04/idle-grounded-review/index.html#resolution-review">Farmer pixel-density review</a></p>
<script>
let index=0,mirror=false,small=true,renderToken=0;const kind=document.getElementById('kind'),motion=document.getElementById('motion');
function inspect(){const token=++renderToken;const k=kind.value,m=motion.value;let count=m==='walk'?4:m==='death'?(k==='giant'?5:4):m==='idle'?1:3;if(k!=='giant'&&(m==='windup'||m==='slam'))count=1;index=(index+count)%count;let name=k;if(m!=='idle'&&(!(m==='windup'||m==='slam')||k==='giant'))name+='_'+(m==='attack'&&k==='giant'?'slam':m)+'_'+index;document.getElementById('phase').textContent=`Frame ${index+1}/${count}`;
for(const [id,root] of [['current','/sprites/enemies/'],['coarse','runtime-size/']]){const im=new Image();im.onload=()=>{if(token!==renderToken)return;const canvas=document.getElementById(id),ctx=canvas.getContext('2d');ctx.imageSmoothingEnabled=false;ctx.fillStyle='#303a3e';ctx.fillRect(0,0,320,256);ctx.save();if(mirror){ctx.translate(320,0);ctx.scale(-1,1)}ctx.drawImage(im,160-im.width*2,240-im.height*4,im.width*4,im.height*4);ctx.restore()};im.src=root+name+'.png'}}
kind.onchange=motion.onchange=()=>{index=0;inspect()};document.getElementById('next').onclick=()=>{index++;inspect()};document.getElementById('previous').onclick=()=>{index--;inspect()};document.getElementById('flip').onclick=()=>{mirror=!mirror;inspect()};
document.getElementById('scale').onclick=function(){small=!small;document.querySelectorAll('.wide').forEach(im=>{im.width=small?840:1680;im.height=small?600:1200});document.querySelectorAll('.farmerwide').forEach(im=>{im.width=small?960:1920;im.height=small?300:600});this.textContent=small?'Show actual FHD screen size':'Show at half screen size'};inspect();
</script></html>'''
    (HERE/'index.html').write_text(html,encoding='utf-8')
    print('Review page/GIFs saved:actual renderer day/night, current/coarse, source frame inspector.')

if __name__=='__main__':
    frames() if '--rendered' in sys.argv else export()
