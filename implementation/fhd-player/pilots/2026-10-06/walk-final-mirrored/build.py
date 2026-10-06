"""Final approved 32px walk pack: exact new up-right -> up-left mirroring."""
from pathlib import Path
import hashlib, json, shutil, sys
from PIL import Image,ImageDraw,ImageFont

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[4]
SOURCE=HERE.parent/'walk-up-right-low-step'
DIRS=['down','right','up','left','down-right','up-right','up-left','down-left']
PAIRS={'left':'right','down-right':'down-left','up-left':'up-right'}
sys.path.insert(0,str(ROOT/'implementation/fhd-player/pilots/2026-10-04/idle-grounded-review'))
from build_preview import gif
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()

def export():
    original=json.loads((SOURCE/'contract.json').read_text(encoding='utf-8'))
    lookup={(e['direction'],e['frame']):e for e in original['assets']}
    entries=[]
    for d in DIRS:
        for i in range(1,9):
            source_d='up-right' if d=='up-left' else d
            outputs={}
            for folder in ['native-40','runtime-80']:
                source=SOURCE/folder/'walk'/source_d/f'{i:02}.png'
                assert sha(source)==lookup[source_d,i]['outputs'][folder]['sha256']
                target=HERE/folder/'walk'/d/f'{i:02}.png'
                target.parent.mkdir(parents=True,exist_ok=True)
                if d=='up-left':Image.open(source).transpose(Image.Transpose.FLIP_LEFT_RIGHT).save(target)
                else:shutil.copy2(source,target);assert sha(source)==sha(target)
                outputs[folder]={'path':target.relative_to(ROOT).as_posix(),'sha256':sha(target)}
            entries.append({'direction':d,'frame':i,'source_direction':source_d,
              'mirrored':d=='up-left','source':(SOURCE/'runtime-80/walk'/source_d/f'{i:02}.png').relative_to(ROOT).as_posix(),
              'source_sha256':sha(SOURCE/'runtime-80/walk'/source_d/f'{i:02}.png'),'outputs':outputs})
    check_geometry()
    doc={'status':'approved source pack; exact up-left mirroring requested by user','runtime_integrated':False,
      'date':'2026-10-06','approval':'New low-step up-right approved; user instructed Codex to mirror it and let Claude fetch the ready pack.',
      'method':'Exact full-canvas FLIP_LEFT_RIGHT only for up-left; other seven directions byte-identical to approved source pack',
      'mirror_pairs':PAIRS,'directions':DIRS,'frames_per_direction':8,'frame_seconds':.1,
      'native_canvas_wh':[40,40],'native_pivot_xy':[20,36],
      'runtime_canvas_wh':[80,80],'runtime_pivot_xy':[40,72],'runtime_draw_scale':.5,'assets':entries}
    (HERE/'contract.json').write_text(json.dumps(doc,indent=2)+'\n',encoding='utf-8')
    print('Exported64 poses in native40/runtime80:8 up-left mirrors,56 byte-identical approved poses.')

def check_geometry():
    for i in range(1,9):
        for d in DIRS:
            small=Image.open(HERE/f'native-40/walk/{d}/{i:02}.png').convert('RGBA')
            large=Image.open(HERE/f'runtime-80/walk/{d}/{i:02}.png').convert('RGBA')
            assert small.size==(40,40) and large.size==(80,80)
            assert small.resize((80,80),Image.Resampling.NEAREST).tobytes()==large.tobytes()
            assert set(small.getchannel('A').get_flattened_data())<={0,255}
        for d,master in PAIRS.items():
            for folder in ['native-40','runtime-80']:
                left=Image.open(HERE/f'{folder}/walk/{d}/{i:02}.png').convert('RGBA')
                right=Image.open(HERE/f'{folder}/walk/{master}/{i:02}.png').convert('RGBA')
                assert left.tobytes()==right.transpose(Image.Transpose.FLIP_LEFT_RIGHT).tobytes(),(d,master,i)

def rendered():
    font=ImageFont.truetype('C:/Windows/Fonts/consola.ttf',18)
    for light in ['day','night']:
        all_eight=[];pair=[]
        for i in range(1,9):
            sheet=Image.new('RGB',(1920,300),'#20292c');draw=ImageDraw.Draw(sheet)
            detail=Image.new('RGB',(640,300),'#20292c');dd=ImageDraw.Draw(detail)
            draw.text((10,8),f'FINAL 32PX / {light.upper()} / FRAME {i}/8 / 10 FPS',font=font,fill='#e9e3cf')
            for j,d in enumerate(DIRS):
                variant='after' if d=='up-left' else 'before'
                im=Image.open(HERE/f'captures/{light}_{variant}_{d}_{i:02}.png').convert('RGB')
                draw.text((j*240+35,34),d.upper(),font=font,fill='#a6cbc6');sheet.paste(im,(j*240,60))
                if d in ['up-right','up-left']:
                    col=['up-right','up-left'].index(d)
                    dd.text((col*320+10,8),f'{d.upper()} / FRAME {i}/8',font=font,fill='#e9e3cf')
                    dd.text((col*320+10,34),'APPROVED MASTER' if col==0 else 'EXACT MIRROR',font=font,fill='#a6cbc6')
                    detail.paste(im,(col*320+40,60))
            all_eight.append(sheet);pair.append(detail)
            path=HERE/'frames'/light;path.mkdir(parents=True,exist_ok=True);detail.save(path/f'{i:02}.png')
        gif(all_eight,HERE/f'all-eight-{light}.gif',[100]*8)
        gif(pair,HERE/f'up-right-up-left-{light}.gif',[100]*8)
        pair[0].save(HERE/f'poster-{light}.png')
    page='''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Final32px walking mirrors</title><style>body{background:#182426;color:#e9e3cf;font:17px Consolas,monospace;margin:24px}h1{font-size:25px}h2{font-size:20px}p{max-width:960px;line-height:1.5}img,canvas{image-rendering:pixelated}.overflow{overflow:auto;margin:20px 0}a{color:#98dcd6}button{padding:10px;font:inherit;background:#344b48;color:#e9e3cf;border:1px solid #75958d}details{margin:24px 0}</style><h1>Final32px walk - exact mirrored up-left</h1><p>Up-left is now the exact horizontal mirror of the newly approved low-step up-right. The other seven directions retain their approved pixels. Eight phases,10 FPS; no regeneration, recoloring or retiming.</p><h2>UP-RIGHT / UP-LEFT - actual FHD renderer</h2><div class="overflow"><img src="up-right-up-left-day.gif" width="640" height="300" alt="Approved up-right and exact mirrored up-left"></div><h2>All eight directions - final pack</h2><div class="overflow"><img src="all-eight-day.gif" width="960" height="150" alt="All eight approved final walking directions"></div><details><summary>Night preview</summary><div class="overflow"><img src="up-right-up-left-night.gif" width="640" height="300"></div><div class="overflow"><img src="all-eight-night.gif" width="960" height="150"></div></details><h2>Inspect the mirrored pair</h2><button id="prev">Previous</button> <button id="next">Next</button> <span id="number">Frame1/8</span><div class="overflow"><canvas id="inspect" width="640" height="300"></canvas></div><p><a href="CLAUDE-APPROVED-WALK-PROMPT.txt">Claude integration prompt</a> / <a href="contract.json">Final asset contract</a> / <a href="checks.json">Export checks</a></p><script>let frame=0,serial=0;const ctx=document.getElementById('inspect').getContext('2d');function draw(){const n=++serial,im=new Image();im.onload=()=>{if(n===serial){ctx.imageSmoothingEnabled=false;ctx.drawImage(im,0,0)}};im.src='frames/day/'+String(frame+1).padStart(2,'0')+'.png';document.getElementById('number').textContent='Frame '+(frame+1)+'/8'};document.getElementById('prev').onclick=()=>{frame=(frame+7)%8;draw()};document.getElementById('next').onclick=()=>{frame=(frame+1)%8;draw()};draw();</script></html>'''
    (HERE/'index.html').write_text(page,encoding='utf-8')
    check_geometry()
    renderer=json.loads((HERE/'renderer-report.json').read_text(encoding='utf-8'))
    assert renderer['failures']==0 and len(renderer['captures'])==144
    assert len({tuple(c['contact']) for c in renderer['captures']})==1
    for path in HERE.glob('*.gif'):
        im=Image.open(path);assert im.n_frames==8
        for i in range(8):im.seek(i);assert im.info['duration']==100
    report={'poses':64,'native_and_runtime_pngs':128,'new_mirrored_up_left_frames':8,
      'other_approved_frames_byte_identical':56,'all_three_mirror_pairs_exact':True,
      'integer_scaling_exact':True,'binary_alpha':True,'gif_frames':8,'gif_frame_ms':100,
      'godot_checks':renderer['checks'],'godot_failures':renderer['failures'],'captures':144,'runtime_integrated':False}
    (HERE/'checks.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print('Verified3 exact mirror pairs,128 PNGs,144 FHD crops and four8-frame GIFs.')

if __name__=='__main__':rendered() if '--rendered' in sys.argv else export()
