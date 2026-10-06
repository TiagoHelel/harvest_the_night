"""Cut generated diagonal repairs for review; never overwrite accepted walks."""
from pathlib import Path
import colorsys
import json
import sys
from PIL import Image,ImageDraw

HERE=Path(__file__).resolve().parent
sys.path.insert(0,str(HERE))
from prepare import DIRS,digest
from build_preview import gif,label
ROOT=HERE.parents[4]
DEST=HERE/'diagonal-candidate'
CHOICES={'up-left':('up-left-motion-r3.raw.png','up-left-motion-r3.prompt.txt','north_west'),
         'up-right':('up-right-hips-r1.raw.png','up-right-hips-r1.prompt.txt','north_east')}
SCALE=.18

def build():
    DEST.mkdir(exist_ok=True)
    palette=[tuple(e['rgb']) for e in json.loads((HERE.parent/'palette-variants/validation.json').read_text())['variants']['blue']]
    report={};rendered={}
    for direction,(filename,prompt,suffix) in CHOICES.items():
        path=HERE/filename;raw=Image.open(path).convert('RGBA');frames=[];stats=[]
        folder=DEST/f'frames/{direction}';folder.mkdir(parents=True,exist_ok=True)
        for i in range(8):
            # Frame7 has its own targeted passing-foot repair. Other poses
            # remain on the selected R3 source, at the same common scale.
            selected=HERE/'up-left-frame7-r1.raw.png' if direction=='up-left' and i==6 else path
            selected_prompt=HERE/'up-left-frame7-r1.prompt.txt' if direction=='up-left' and i==6 else HERE/prompt
            image=Image.open(selected).convert('RGBA')
            box=(int(i%4*image.width/4),int(i//4*image.height/2),int((i%4+1)*image.width/4),int((i//4+1)*image.height/2))
            cell=image.crop(box);cell.putalpha(cell.getchannel('A').point(lambda a:255 if a>=128 else 0))
            bounds=cell.getbbox();crop=cell.crop(bounds)
            # Hat-centered x registration avoids a bounding-box shift caused
            # by a swinging boot or hand. Ground registration is independent.
            hat=[]
            for y in range(bounds[1],bounds[1]+120):
                for x in range(cell.width):
                    r,g,b,a=cell.getpixel((x,y))
                    if a and r>g and g>90 and g>b*1.4:hat.append(x)
            hat_center=(min(hat)+max(hat))/2
            size=tuple(round(n*SCALE) for n in crop.size)
            crop=crop.resize(size,Image.Resampling.NEAREST)
            offset=(40-round((hat_center-bounds[0])*SCALE),72-size[1])
            assert offset[0]>=0 and offset[1]>=0 and offset[0]+size[0]<=80
            native=Image.new('RGBA',(80,80));native.alpha_composite(crop,offset)
            before=native.copy();mask=Image.new('L',(80,80))
            for y in range(80):
                for x in range(80):
                    r,g,b,a=native.getpixel((x,y));h,s,v=colorsys.rgb_to_hsv(r/255,g/255,b/255)
                    if a and y>=28 and 185<=h*360<=270 and s>=.3 and b>=6:
                        mask.putpixel((x,y),255)
                        rgb=min(palette,key=lambda c:sum((c[k]-(r,g,b)[k])**2 for k in range(3)))
                        native.putpixel((x,y),(*rgb,a))
                    else:assert native.getpixel((x,y))==before.getpixel((x,y))
            assert native.getchannel('A').tobytes()==before.getchannel('A').tobytes()
            output=folder/f'{i+1:02}.png';native.save(output)
            frames.append(native)
            (DEST/f'masks/{direction}').mkdir(parents=True,exist_ok=True);mask.save(DEST/f'masks/{direction}/{i+1:02}.png')
            stats.append({'frame':i+1,'raw_cell_xyxy':box,'raw_content_xyxy':bounds,'offset_xy':offset,
                          'raw_path':selected.relative_to(ROOT).as_posix(),'raw_sha256':digest(selected),
                          'prompt_path':selected_prompt.relative_to(ROOT).as_posix(),'prompt_sha256':digest(selected_prompt),
                          'native_bounds_xyxy':native.getbbox(),'height':native.getbbox()[3]-native.getbbox()[1],
                          'native_path':output.relative_to(ROOT).as_posix(),'sha256':digest(output)})
        report[direction]={'raw_path':path.relative_to(ROOT).as_posix(),'raw_sha256':digest(path),
                           'prompt_path':(HERE/prompt).relative_to(ROOT).as_posix(),'prompt_sha256':digest(HERE/prompt),
                           'suffix':suffix,'common_scale':SCALE,'frames':stats}
        rendered[direction]=frames
    images=[]
    for i in range(8):
        sheet=Image.new('RGBA',(960,300),'#20292c');d=ImageDraw.Draw(sheet)
        label(d,(18,12),f'DIAGONAL WALK REPAIR / FRAME {i+1}/8 / 10 FPS',20)
        for j,(direction,data) in enumerate(report.items()):
            old=Image.open(ROOT/f'sprites/actors/walk_{data["suffix"]}_{i}.png').convert('RGBA')
            for col,im,name in [(0,old,'CURRENT'),(1,rendered[direction][i],'CANDIDATE')]:
                x=j*480+col*240
                label(d,(x+10,53),direction.upper()+' '+name,15)
                sheet.alpha_composite(im.resize((160,160),Image.Resampling.NEAREST),(x+35,83))
                label(d,(x+10,260),'128px FHD artwork',14)
        images.append(sheet.convert('RGB'))
    gif(images,DEST/'before-after.gif',100);images[0].save(DEST/'poster.png')
    contact=Image.new('RGBA',(1280,410),'#303a3e');d=ImageDraw.Draw(contact)
    for row,(direction,frames) in enumerate(rendered.items()):
        for i,im in enumerate(frames):
            contact.alpha_composite(im.resize((160,160),Image.Resampling.NEAREST),(i*160,row*205+30))
            label(d,(i*160+8,row*205+5),direction.upper()+f' {i+1}',13)
    contact.save(DEST/'contact-sheet.png')
    document={'date':'2026-10-05','status':'awaiting_user_motion_review','runtime_integrated':False,
              'changes':'UL: reaching poses 4/8, consistent supporting calf reach, raised passing foot7; UR: stable pelvis/back-pocket contour',
              'revisions':{'up-left-r1':'Rejected: reaching poses still duplicate wide contact',
                           'up-left-r2':'Rejected: supporting calves shortened, inconsistent height',
                           'up-left-r3':'Selected for frames1..6/8; frame7 passing dip rejected',
                           'up-left-frame7-r1':'Targeted frame7 passing-foot repair, second targeted revision for this asset',
                           'up-right-r1':'Selected for user hip review'},
              'targeted_revisions_per_up_left_frame':{'1':2,'2':2,'3':2,'4':3,'5':2,'6':2,'7':2,'8':3},
              'canvas_wh':[80,80],'pivot_xy':[40,72],'draw_scale':.5,'seconds':.1,
              'palette_rgb':palette,'frames':report}
    (DEST/'validation.json').write_text(json.dumps(document,indent=2)+'\n')
    print('Diagonal candidates cut; runtime blue walks untouched. Heights:',{d:[s['height'] for s in r['frames']] for d,r in report.items()})

if __name__=='__main__':build()
