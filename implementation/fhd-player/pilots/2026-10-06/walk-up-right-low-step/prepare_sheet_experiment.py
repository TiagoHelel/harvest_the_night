"""Measure generated frames, restore approved blue, and export isolated review assets."""
from pathlib import Path
from collections import Counter
from bisect import bisect_left
import colorsys, hashlib, json, shutil, sys
import numpy as np
from PIL import Image, ImageDraw, ImageFont

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[4]
BEFORE=HERE.parent/'walk-mirror-review'
DIRS=['down','right','up','left','down-right','up-right','up-left','down-left']
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def lum(c): return .2126*c[0]+.7152*c[1]+.0722*c[2]
def bands(values):
    active=np.flatnonzero(values>3)
    groups=np.split(active,np.flatnonzero(np.diff(active)>8)+1)
    return [(int(a[0]),int(a[-1])+1) for a in groups if len(a)>15]

def main(source, tracking=False):
    raw=Image.open(HERE/source).convert('RGBA')
    solid=np.asarray(raw.getchannel('A'))>=128
    rows=bands(solid.sum(axis=1)); assert len(rows)==2,rows
    boxes=[]; pieces=[]
    for y0,y1 in rows:
        cols=bands(solid[y0:y1].sum(axis=0)); assert len(cols)==4,cols
        for x0,x1 in cols:
            ys,xs=np.where(solid[y0:y1,x0:x1])
            box=(int(x0+xs.min()),int(y0+ys.min()),int(x0+xs.max()+1),int(y0+ys.max()+1))
            boxes.append(box); pieces.append(raw.crop(box))
    scale=32/max(im.height for im in pieces)
    guide=[]
    for im in pieces:
        small=im.resize((round(im.width*scale),round(im.height*scale)),Image.Resampling.NEAREST)
        a=np.array(small); a[:,:,3]=np.where(a[:,:,3]>=128,255,0); a[a[:,:,3]==0]=0
        small=Image.fromarray(a)
        # Register by the hat bounds rather than animated hands/legs.
        hat=small.getchannel('A').crop((0,0,small.width,max(1,round(small.height*.30)))).getbbox()
        center=(hat[0]+hat[2])/2
        canvas=Image.new('RGBA',(40,40)); canvas.alpha_composite(small,(round(20-center),4))
        guide.append(canvas)
    doc=json.loads((ROOT/'implementation/fhd-player/pilots/2026-10-04/palette-variants/validation.json').read_text())
    blue=[tuple(e['rgb']) for e in doc['variants']['blue']]
    ref=Counter()
    for i in range(1,9):
        im=Image.open(BEFORE/f'native-40/walk/right/{i:02}.png').convert('RGBA')
        ref.update(p[:3] for p in im.get_flattened_data() if p[3] and p[:3] in blue)
    total=sum(ref.values()); acc=0; cdf=[]
    for c in blue: acc+=ref[c]; cdf.append(acc/total)
    masks=[]; colors={'cyan':Counter(),'red':Counter()}
    for im in guide:
        mask={}
        for y in range(40):
            for x in range(40):
                r,g,b,a=im.getpixel((x,y))
                if not a: continue
                kind=None
                if tracking and y>=21 and b>r*1.2 and g>r*1.5 and g>=b*.68: kind='cyan'
                elif tracking and y>=21 and r>g*2 and b>=g*.55 and b>40: kind='red'
                if kind: mask[x,y]=kind;colors[kind][r,g,b]+=1
        masks.append(mask)
    maps={}
    for kind,counts in colors.items():
        if not counts: continue
        tones=Counter()
        for c,n in counts.items(): tones[lum(c)]+=n
        acc=0;count=sum(tones.values()); ranks={}
        for tone,n in sorted(tones.items()): ranks[tone]=(acc+n/2)/count;acc+=n
        maps[kind]={c:blue[min(11,bisect_left(cdf,ranks[lum(c)]))] for c in counts}
    candidates=[]; changes=[]
    for im,mask in zip(guide,masks):
        out=im.copy(); n=0
        for y in range(40):
            for x in range(40):
                r,g,b,a=im.getpixel((x,y))
                if not a: continue
                c=(r,g,b);new=c
                if (x,y) in mask: new=maps[mask[x,y]][c]
                elif b>r*1.15 and b>g*1.10 and b>=6:
                    new=min(blue,key=lambda t:sum((t[k]-c[k])**2 for k in range(3)))
                if new!=c:out.putpixel((x,y),(*new,a));n+=1
        assert out.getchannel('A').tobytes()==im.getchannel('A').tobytes()
        candidates.append(out);changes.append(n)
    entries=[]
    for d in DIRS:
        for i in range(1,9):
            changed=d=='up-right'
            original=BEFORE/f'native-40/walk/{d}/{i:02}.png'
            im=candidates[i-1] if changed else Image.open(original).convert('RGBA')
            outputs={}
            for folder,size in [('native-40',40),('runtime-80',80)]:
                p=HERE/folder/'walk'/d/f'{i:02}.png';p.parent.mkdir(parents=True,exist_ok=True)
                if changed: im.resize((size,size),Image.Resampling.NEAREST).save(p)
                else: shutil.copy2(BEFORE/folder/'walk'/d/f'{i:02}.png',p)
                outputs[folder]={'path':p.relative_to(ROOT).as_posix(),'sha256':sha(p)}
                if not changed: assert sha(p)==sha(BEFORE/folder/'walk'/d/f'{i:02}.png')
            entries.append({'direction':d,'frame':i,'changed':changed,'before_sha256':sha(original),'outputs':outputs})
    strip=Image.new('RGB',(8*160,220),'#20292c'); draw=ImageDraw.Draw(strip)
    font=ImageFont.truetype('C:/Windows/Fonts/consola.ttf',16)
    for i,im in enumerate(candidates):
        strip.paste(im.resize((160,160),Image.Resampling.NEAREST),(i*160,40),im.resize((160,160),Image.Resampling.NEAREST))
        draw.text((i*160+20,12),f'FRAME {i+1}',font=font,fill='#e9e3cf')
        p=HERE/f'tracking-native/{i+1:02}.png';p.parent.mkdir(exist_ok=True);guide[i].save(p)
    strip.save(HERE/'up-right-frames.png')
    contract={'date':'2026-10-06','status':'awaiting motion review','runtime_integrated':False,
      'generation':'built-in image_gen; measured transparent bounding boxes, shared nearest-neighbor scale; approved RIGHT blue palette mapping',
      'tracking_colors_used_in_final':tracking,
      'generated_source':source,'generated_sha256':sha(HERE/source),'measured_boxes':boxes,'uniform_scale':scale,
      'changed_directions':['up-right'],'unchanged_approved_directions':[d for d in DIRS if d!='up-right'],
      'up_left_preserved':True,'native_canvas_wh':[40,40],'native_pivot_xy':[20,36],
      'runtime_canvas_wh':[80,80],'runtime_pivot_xy':[40,72],'runtime_draw_scale':.5,
      'frames_per_direction':8,'frame_seconds':.1,'palette':blue,'recolored_pixels':changes,'assets':entries}
    (HERE/'contract.json').write_text(json.dumps(contract,indent=2)+'\n')
    print('Measured 8 generated components:',boxes)
    print('Exported 8 new up-right frames plus 56 byte-identical approved frames, each in 40/80px formats.')

if __name__=='__main__':main(sys.argv[1], '--tracking' in sys.argv)
