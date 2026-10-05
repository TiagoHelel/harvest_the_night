"""Replace only requested regions in the user's exact selected native cycles."""
from pathlib import Path
import hashlib
import json
import shutil
import statistics
import sys
from PIL import Image,ImageDraw,ImageFont

HERE=Path(__file__).resolve().parent
ROOT=HERE.parent
SOURCE=ROOT.parents[3]/'assets/art_source/player-fhd/pilots/2026-10-04/selected-UR03-UL03'
sys.path.insert(0,str(ROOT))
from build_hand_rebuild_review import caption,save_gif

def sample_source(name,count):
    im=Image.open(SOURCE/name).convert('RGBA')
    im.putalpha(im.getchannel('A').point(lambda a:255 if a>=128 else 0))
    cols=[round(i*im.width/count) for i in range(count+1)]
    cells=[im.crop((cols[i],0,cols[i+1],im.height)) for i in range(count)]
    widths=[];centers=[]
    for cell in cells:
        b=cell.getbbox();assert b
        hat=cell.crop((0,b[1],cell.width,b[1]+round((b[3]-b[1])*.22))).getbbox()
        widths.append(hat[2]-hat[0]);centers.append((hat[0]+hat[2])/2)
    scale=32/statistics.median(widths)
    frames=[]
    for cell,center in zip(cells,centers):
        small=cell.resize((round(cell.width*scale),round(cell.height*scale)),Image.Resampling.NEAREST)
        frame=Image.new('RGBA',(80,80));frame.alpha_composite(small,(round(40-center*scale),8-small.getbbox()[1]))
        b=frame.getbbox();assert b[0]>1 and b[2]<79 and b[3]<78,b
        frames.append(frame)
    return frames,{'source':name,'source_size':list(im.size),'col_cuts':cols,'common_scale':scale,
                   'native_canvas':[80,80],'hat_target':32,'resample':'nearest','alpha_threshold':128}

def build(revision):
    selection=json.loads((HERE/'sources.json').read_text())
    old={};new={};report={}
    for code,count,indices in [('UR03',1,[7]),('UL03',2,[5,6])]:
        original=HERE/code/'original';output=HERE/code/'frames';output.mkdir(exist_ok=True)
        frames,state=sample_source(selection[code],count)
        raw=HERE/code/f'candidate-{revision}';raw.mkdir(exist_ok=True)
        for index,frame in zip(indices,frames):frame.save(raw/f'{index:02}.png')
        old[code]=[Image.open(original/f'{i:02}.png').convert('RGBA') for i in range(1,9)]
        new[code]=[im.copy() for im in old[code]]
        regions=[]
        for index,frame in zip(indices,frames):
            # Generated artwork supplies the replacement pixels. These fixed
            # cuts preserve the selected head/torso or lower body verbatim.
            region=(44,48,62,68) if code=='UR03' else (22,30,46,50)
            new[code][index-1].paste(frame.crop(region),region[:2])
            regions.append({'frame':index,'generated_region':list(region)})
        unchanged=[]
        for i,im in enumerate(new[code],1):
            path=output/f'{i:02}.png'
            if i not in indices:
                shutil.copy2(original/f'{i:02}.png',path)
                assert path.read_bytes()==(original/f'{i:02}.png').read_bytes();unchanged.append(i)
            else:
                im.save(path);assert im.tobytes()!=old[code][i-1].tobytes()
                before=old[code][i-1];region=regions[indices.index(i)]['generated_region']
                for y in range(80):
                    for x in range(80):
                        if not(region[0]<=x<region[2] and region[1]<=y<region[3]):
                            assert im.getpixel((x,y))==before.getpixel((x,y))
            assert im.size==(80,80) and set(im.getchannel('A').tobytes())<={0,255}
        state.update(changed_frames=indices,byte_identical_unedited_frames=unchanged,regions=regions,
                     retained_regions='UR03 head, torso, arms, planted leg/boot; UL03 head, legs, boots and far arm retained outside fixed source cuts.')
        report[code]=state
        strips=[]
        for label,data in [('original',old[code]),('revised',new[code])]:
            strip=Image.new('RGBA',(1280,180),'#303a3e')
            for i,im in enumerate(data):
                strip.alpha_composite(im.resize((160,160),Image.Resampling.NEAREST),(i*160,20))
                caption(ImageDraw.Draw(strip),(i*160+4,0),f'{code} {i+1} {label}',11)
            strip.convert('RGB').save(HERE/f'{code}-{label}-strip.png')
            strips.append(strip)
        contact=Image.new('RGBA',(1280,360));contact.alpha_composite(strips[0]);contact.alpha_composite(strips[1],(0,180))
        contact.convert('RGB').save(HERE/f'{code}-before-after.png')
    regular=[];slow=[]
    for i in range(8):
        canvas=Image.new('RGBA',(960,350),'#20292c');draw=ImageDraw.Draw(canvas)
        caption(draw,(20,16),'SELECTED CYCLES / LOCAL FRAME CORRECTIONS / 10 FPS',19)
        enlarged=Image.new('RGBA',(1280,380),'#303a3e');ed=ImageDraw.Draw(enlarged)
        for j,(code,label,data) in enumerate([('UR03','SELECTED',old['UR03']),('UR03','REVISED',new['UR03']),('UL03','SELECTED',old['UL03']),('UL03','REVISED',new['UL03'])]):
            x=j*240
            caption(draw,(x+30,70),f'{code} | {label}',15)
            canvas.alpha_composite(data[i].resize((160,160),Image.Resampling.NEAREST),(x+40,95))
            caption(ed,(j*320+10,10),f'{code} {label} / {i+1}',14)
            enlarged.alpha_composite(data[i].resize((320,320),Image.Resampling.NEAREST),(j*320,35))
        caption(draw,(25,285),'UR03: frame7 / UL03: frames5,6 / other13selected poses unchanged',14)
        caption(draw,(25,322),f'Frame {i+1:02} / 08 | Preview only - awaiting review',14)
        regular.append(canvas.convert('RGB'));slow.append(enlarged.convert('RGB'))
    save_gif(regular,HERE/f'selected-corrections-{revision}.gif',100)
    save_gif(slow,HERE/f'selected-corrections-slow-{revision}.gif',200)
    regular[0].save(HERE/'poster.png')
    directions=['down','right','up','left','down-right','up-right','up-left']
    aggregate=[]
    for i in range(8):
        sheet=Image.new('RGBA',(1440,330),'#20292c');draw=ImageDraw.Draw(sheet)
        caption(draw,(24,16),'FARMER WALK / SELECTED UP DIAGONALS / 8 FRAMES / 10 FPS',20)
        for j,d in enumerate(directions):
            im=(new['UR03'] if d=='up-right' else new['UL03'])[i] if d in ['up-right','up-left'] else Image.open(ROOT/f'walk-{d}/frames/walk-{d}-{i+1:02}.png').convert('RGBA')
            x=40+j*200
            caption(draw,(x,75),d.upper(),17)
            sheet.alpha_composite(im.resize((160,160),Image.Resampling.NEAREST),(x,100))
            caption(draw,(x,274),'UR03 / CHECK7' if d=='up-right' else 'UL03 / CHECK5,6' if d=='up-left' else 'UNCHANGED',13)
        caption(draw,(24,308),f'Frame {i+1:02}/08 | Preview only',13)
        aggregate.append(sheet.convert('RGB'))
    save_gif(aggregate,HERE/f'all-walk-directions-selected-{revision}.gif',100)
    baseline=json.loads((HERE/'baseline.json').read_text())
    assert all(hashlib.sha256((ROOT/p).read_bytes()).hexdigest()==h for p,h in baseline.items())
    report.update(status='awaiting user visual review; preview only',unchanged_current_native_count=len(baseline),
                  edited_selected_frame_count=3,unchanged_selected_frame_count=13,revision=revision)
    (HERE/f'validation-{revision}.json').write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps(report))

if __name__=='__main__':build(sys.argv[1])
