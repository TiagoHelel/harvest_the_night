"""Display existing rear-diagonal revisions without modifying sprite sources."""
from pathlib import Path
import hashlib
import html
import json
import re
import statistics
from PIL import Image, ImageDraw
from build_hand_rebuild_review import caption, save_gif

ROOT=Path(__file__).resolve().parent
SOURCE=ROOT.parents[3]/'assets/art_source/player-fhd/pilots/2026-10-04'
OUT=ROOT/'walk-revision-gallery'
OUT.mkdir(exist_ok=True)
PARTIAL={
    'up-right':{'rotation-r1.png','contacts-r1.png','contacts-r2.png','contact-05-r1.png',
                'transition-a-r1.png','transition-a-r2.png','transition-b-r1.png','transition-b-r2.png',
                'phase-06-r1.png','reach-04-08-r1.png','passing-03-07-r1.png','recovery-07-08-r1.png'},
    'up-left':{'rotation-r1.png','recovery-r3.png','rebuild-contacts-r6.png','arm-05-06-r10.png'}}
EXTRA={'up-right':['materials-r4.png','tracking-r1.png'],
       'up-left':['rebuild-tracking-r6-packed.png']}

def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
baseline={str(p.relative_to(ROOT)).replace('\\','/'):sha(p) for p in ROOT.glob('walk-*/frames/*.png')}

def sample_sheet(path):
    im=Image.open(path).convert('RGBA')
    im.putalpha(im.getchannel('A').point(lambda a:255 if a>=128 else 0))
    blank=[y for y in range(round(im.height*.4),round(im.height*.6))
           if im.getchannel('A').crop((0,y,im.width,y+1)).getbbox() is None]
    assert blank,f'No transparent separator in {path.name}'
    rows=[0,round(statistics.median(blank)),im.height]
    cols=[round(i*im.width/4) for i in range(5)]
    cells=[im.crop((cols[c],rows[r],cols[c+1],rows[r+1])) for r in range(2) for c in range(4)]
    widths=[];centers=[]
    for cell in cells:
        b=cell.getbbox();assert b
        hat=cell.crop((0,b[1],cell.width,b[1]+round((b[3]-b[1])*.22))).getbbox()
        widths.append(hat[2]-hat[0]);centers.append((hat[0]+hat[2])/2)
    hat_scale=32/statistics.median(widths)
    # Preserve unusually tall rejected studies without clipping their boots.
    height_limit=70/max(c.getbbox()[3]-c.getbbox()[1] for c in cells)
    scale=min(hat_scale,height_limit)
    frames=[]
    for cell,center in zip(cells,centers):
        small=cell.resize((round(cell.width*scale),round(cell.height*scale)),Image.Resampling.NEAREST)
        frame=Image.new('RGBA',(80,80))
        frame.alpha_composite(small,(round(40-center*scale),8-small.getbbox()[1]))
        b=frame.getbbox();assert b[0]>0 and b[2]<80 and b[3]<80,(path.name,b)
        frames.append(frame)
    return frames,{'method':'Common 32px hat scale, limited to 70px height when needed; nearest sampling, alpha128.',
                   'scale':scale,'rows':rows,'cols':cols,'source':str(path.relative_to(ROOT.parents[3])).replace('\\','/')}

def identity(frames):
    data=[]
    for f in frames:
        plain=Image.new('RGBA',f.size);plain.alpha_composite(f)
        data.append(plain.tobytes())
    return hashlib.sha256(b''.join(data)).hexdigest()

items=[];partials=[];seen={};coverage={};counts={'up-right':0,'up-left':0}

def add_cycle(direction,frames,name,path,meta):
    key=(direction,identity(frames))
    alias={'name':name,'path':str(path.relative_to(ROOT.parents[3])).replace('\\','/'),
           'source_sha256':sha(path) if path.is_file() else None}
    if key in seen:
        seen[key]['aliases'].append(alias)
        return seen[key]['id']
    counts[direction]+=1
    code=('UR' if direction=='up-right' else 'UL')+f'{counts[direction]:02}'
    item={'id':code,'direction':direction,'name':name,'aliases':[alias],
          'sampling':meta,'gif':f'{code}.gif','strip':f'{code}-strip.png',
          'frames':8,'duration_ms':100,'display_scale':2}
    outputs=[];strip=Image.new('RGBA',(1280,180),'#303a3e')
    for i,f in enumerate(frames):
        canvas=Image.new('RGBA',(240,215),'#20292c')
        canvas.alpha_composite(f.resize((160,160),Image.Resampling.NEAREST),(40,25))
        caption(ImageDraw.Draw(canvas),(12,190),f'{code} | {i+1}/8 | 10 FPS',13)
        outputs.append(canvas.convert('RGB'))
        strip.alpha_composite(f.resize((160,160),Image.Resampling.NEAREST),(i*160,20))
        caption(ImageDraw.Draw(strip),(i*160+6,0),f'{code} frame {i+1}',12)
    save_gif(outputs,OUT/item['gif'],100)
    strip.convert('RGB').save(OUT/item['strip'])
    for i,f in enumerate(frames):f.save(OUT/f'{code}-frame-{i+1:02}.png')
    item['export_sha256']={str(p.name):sha(p) for p in OUT.glob(f'{code}-*')}
    item['export_sha256'][item['gif']]=sha(OUT/item['gif'])
    items.append(item);seen[key]=item
    return code

for d in counts:
    folder=ROOT/f'walk-{d}'
    # Current plus historical native exports first, retaining original gait pixels.
    candidates=[folder/'frames']+sorted(p for p in folder.rglob('*') if p.is_dir() and p!=folder/'frames')
    for p in candidates:
        frames=sorted(p.glob(f'walk-{d}-[0-9][0-9].png'))
        if len(frames)!=8:continue
        if any(Image.open(f).size!=(80,80) for f in frames):continue
        ims=[Image.open(f).convert('RGBA') for f in frames]
        name='CURRENT | hands-r15' if p==folder/'frames' else str(p.relative_to(folder)).replace('\\','/')
        add_cycle(d,ims,name,p,{'method':'Exact existing native PNGs; no resampling.',
                              'input_sha256':{f.name:sha(f) for f in frames}})
    generation=json.loads((folder/'generation.json').read_text())
    coverage[d]={}
    names=[c['source'] for c in generation['calls']]+EXTRA[d]
    for name in dict.fromkeys(names):
        path=SOURCE/f'walk-{d}'/name
        if name in PARTIAL[d]:
            im=Image.open(path).convert('RGBA');im.thumbnail((960,480),Image.Resampling.NEAREST)
            preview=f'partial-{d}-{path.stem}.png';im.save(OUT/preview)
            partials.append({'direction':d,'name':name,'preview':preview,
                             'source':str(path.relative_to(ROOT.parents[3])).replace('\\','/'),'sha256':sha(path)})
            coverage[d][name]={'type':'static/partial','preview':preview}
        else:
            frames,meta=sample_sheet(path)
            code=add_cycle(d,frames,name,path,meta)
            coverage[d][name]={'type':'complete eight-frame cycle','id':code}

assert all(sha(ROOT/p)==h for p,h in baseline.items())
manifest={'date':'2026-10-05','items':items,'partials':partials,'coverage':coverage,
          'unique_cycles':counts,'unchanged_native_frames':len(baseline),
          'source_changes':False,'new_generation_calls':0,'selection_applies_to_game':False}
(OUT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')

cards=[]
for d in counts:
    cards.append(f'<section id="{d}"><h2>{d.upper()} ({counts[d]} versions)</h2><div class="grid">')
    for item in [i for i in items if i['direction']==d]:
        code=item['id'];name=html.escape(item['name'])
        cards.append(f'''<article id="{code}"><h3>{code}</h3><p class="name">{name}</p>
<img src="{item['gif']}" width="240" height="215" alt="{code} {d} walking animation">
<button data-id="{code}" data-direction="{d}">Choose {code}</button>
<details><summary>Frames and source</summary><a href="{item['strip']}">All 8 frames horizontally</a>
<ul>''')
        for alias in item['aliases']:
            path=alias['path'];href='../../../../../'+path
            cards.append(f'<li><a href="{html.escape(href)}">{html.escape(alias["name"])}</a></li>')
        cards.append('</ul></details></article>')
    cards.append('</div></section>')
    cards.append(f'<details class="extras"><summary>{d.upper()} | original sheets, contacts and partial transitions</summary><div class="raw">')
    for p in [p for p in partials if p['direction']==d]:
        cards.append(f'<article><h3>{html.escape(p["name"])}</h3><p>Static source / partial cycle</p><a href="../../../../../{html.escape(p["source"])}"><img loading="lazy" src="{p["preview"]}" alt="{html.escape(p["name"])} original source"></a></article>')
    cards.append('</div></details>')
document='''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Farmer - all upper diagonal walk revisions</title>
<style>body{margin:24px;background:#172225;color:#e9e3cf;font:16px system-ui}main{max-width:1500px;margin:auto}h1{font-size:26px}h2{margin-top:32px}p{color:#b7ccc7}.name{font:13px monospace;min-height:32px;overflow-wrap:anywhere}.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(256px,1fr));gap:16px}article{background:#20292c;border:2px solid #405754;border-radius:5px;padding:12px;min-width:0}article.chosen{border-color:#f6c65b}article h3{margin:0;color:#f6c65b}article img{display:block;image-rendering:pixelated;margin:auto;max-width:100%;height:auto}button,a{color:#e9e3cf}button{background:#344b48;border:1px solid #78968d;padding:9px 16px;cursor:pointer}button:hover{background:#52685f}nav a{margin-right:22px}.selection{position:sticky;top:0;z-index:2;background:#172225f5;border:1px solid #779688;padding:12px;margin:18px 0}.comparison{display:flex;gap:16px;flex-wrap:wrap}.comparison figure{margin:0}.comparison img{image-rendering:pixelated;width:240px;height:215px}.empty{padding:25px}.extras{margin:24px 0}.raw{display:grid;grid-template-columns:repeat(auto-fill,minmax(360px,1fr));gap:16px;margin-top:16px}.raw img{max-height:480px}summary{cursor:pointer;padding:8px 0}li{overflow-wrap:anywhere}ul{padding-left:20px}
</style><main><h1>All UP-RIGHT and UP-LEFT walk revisions</h1>
<p>All existing complete cycles, including older versions and color studies. Every GIF plays 8 frames at 10 fps and integer 2x scale. Archived exports retain their original pixels; raw sheets use one shared hat scale per sheet.</p>
<nav><a href="#up-right">UP-RIGHT</a><a href="#up-left">UP-LEFT</a><a href="manifest.json">Source inventory</a></nav>
<div class="selection"><strong id="choice">Choose one version for each direction.</strong><p>Selections are for review only. Reply with the two codes to confirm your choices.</p><details><summary>Compare chosen versions</summary><div class="comparison" id="comparison"></div></details></div>
CARDS
</main><script>
const choices={};
for(const button of document.querySelectorAll('button[data-id]'))button.onclick=()=>{
 const d=button.dataset.direction,id=button.dataset.id;choices[d]=id;
 for(const b of document.querySelectorAll(`button[data-direction="${d}"]`)){b.closest('article').classList.toggle('chosen',b.dataset.id===id);b.textContent=(b.dataset.id===id?'Chosen ':'Choose ')+b.dataset.id;}
 document.getElementById('choice').textContent=`UP-RIGHT: ${choices['up-right']||'---'} | UP-LEFT: ${choices['up-left']||'---'}`;
 const area=document.getElementById('comparison');area.replaceChildren();
 for(const key of ['up-right','up-left'])if(choices[key]){const figure=document.createElement('figure');const label=document.createElement('figcaption');label.textContent=key.toUpperCase()+' '+choices[key];const image=document.createElement('img');image.src=choices[key]+'.gif';image.alt=label.textContent;figure.append(label,image);area.append(figure);}
};
</script></html>'''.replace('CARDS','\n'.join(cards))
(OUT/'index.html').write_text(document,encoding='utf-8')
print(json.dumps({'unique_cycles':counts,'partial_sources':len(partials),'unchanged_native_frames':len(baseline),'generated_calls':0}))
