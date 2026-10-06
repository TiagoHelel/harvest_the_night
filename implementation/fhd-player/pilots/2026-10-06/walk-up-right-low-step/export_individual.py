"""Export targeted ImageGen foot edits; approved phases 2/6 and other directions copied."""
from pathlib import Path
import hashlib, json, shutil
import numpy as np
from PIL import Image, ImageDraw, ImageFont

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[4]
BASE=HERE.parent/'walk-mirror-review'
DIRS=['down','right','up','left','down-right','up-right','up-left','down-left']
EDITED=[1,3,4,5,7,8]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()

def main():
    palette=json.loads((ROOT/'implementation/fhd-player/pilots/2026-10-04/palette-variants/validation.json').read_text())['variants']['blue']
    blue=[tuple(c['rgb']) for c in palette]
    source_boxes=[]; frames=[]
    for i in range(1,9):
        original=Image.open(BASE/f'native-40/walk/up-right/{i:02}.png').convert('RGBA')
        if i not in EDITED:
            frames.append(original);continue
        p=HERE/f'individual-generated/{i:02}.png'
        raw=Image.open(p).convert('RGBA')
        a=np.array(raw.getchannel('A')); ys,xs=np.where(a>=128)
        box=(int(xs.min()),int(ys.min()),int(xs.max()+1),int(ys.max()+1))
        source_boxes.append({'frame':i,'source_size':raw.size,'solid_bbox':box,'raw_sha256':sha(p)})
        # Normalize the same full transparent cell, preserving the authored phase position.
        im=raw.resize((40,40),Image.Resampling.NEAREST)
        rgba=np.array(im);rgba[:,:,3]=np.where(rgba[:,:,3]>=128,255,0);rgba[rgba[:,:,3]==0]=0
        im=Image.fromarray(rgba)
        mask=im.getchannel('A').tobytes()
        for y in range(40):
            for x in range(40):
                r,g,b,a=im.getpixel((x,y))
                if a and b>r*1.15 and b>g*1.10 and b>=6:
                    c=min(blue,key=lambda t:sum((t[k]-[r,g,b][k])**2 for k in range(3)))
                    im.putpixel((x,y),(*c,a))
        assert mask==im.getchannel('A').tobytes()
        assert im.getbbox() is not None
        frames.append(im)
    entries=[]
    for d in DIRS:
        for i in range(1,9):
            changed=d=='up-right' and i in EDITED
            outputs={}
            for folder,size in [('native-40',40),('runtime-80',80)]:
                p=HERE/folder/'walk'/d/f'{i:02}.png';p.parent.mkdir(parents=True,exist_ok=True)
                original=BASE/folder/'walk'/d/f'{i:02}.png'
                if changed:frames[i-1].resize((size,size),Image.Resampling.NEAREST).save(p)
                else:shutil.copy2(original,p)
                outputs[folder]={'path':p.relative_to(ROOT).as_posix(),'sha256':sha(p)}
                if not changed:assert sha(p)==sha(original)
            small=Image.open(HERE/f'native-40/walk/{d}/{i:02}.png').convert('RGBA')
            large=Image.open(HERE/f'runtime-80/walk/{d}/{i:02}.png').convert('RGBA')
            assert small.resize((80,80),Image.Resampling.NEAREST).tobytes()==large.tobytes()
            assert set(small.getchannel('A').get_flattened_data())<={0,255}
            entries.append({'direction':d,'frame':i,'edited':changed,'before_sha256':sha(BASE/f'native-40/walk/{d}/{i:02}.png'),'outputs':outputs})
    strip=Image.new('RGB',(1280,220),'#20292c'); draw=ImageDraw.Draw(strip)
    font=ImageFont.truetype('C:/Windows/Fonts/consola.ttf',16)
    for i,im in enumerate(frames):
        im=im.resize((160,160),Image.Resampling.NEAREST);strip.paste(im,(i*160,40),im)
        draw.text((i*160+20,12),f'FRAME {i+1}',font=font,fill='#e9e3cf')
    strip.save(HERE/'up-right-frames.png')
    contract={'status':'awaiting visual review','runtime_integrated':False,'tool':'built-in image_gen',
      'method':'Targeted single-frame edits of raised boots; native nearest export and approved RIGHT blue palette mapping',
      'rejected_sheet_attempts':['r1','r2-tracking','r3-low-tracking','r4-approved-gait'],
      'changed_directions':['up-right'],'preserved_approved_directions':[d for d in DIRS if d!='up-right'],
      'edited_up_right_frames':EDITED,'preserved_up_right_frames':[2,6],
      'native_canvas_wh':[40,40],'native_pivot_xy':[20,36],'runtime_canvas_wh':[80,80],
      'runtime_pivot_xy':[40,72],'runtime_draw_scale':.5,'frame_seconds':.1,'frames_per_direction':8,
      'raw_sources':source_boxes,'blue_palette':blue,'assets':entries}
    (HERE/'contract.json').write_text(json.dumps(contract,indent=2)+'\n')
    print('Exported six targeted edits; 58 remaining walk frames byte-identical, native40/runtime80 consistent.')

if __name__=='__main__':main()
