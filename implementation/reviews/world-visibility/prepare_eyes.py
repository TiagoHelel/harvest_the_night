"""Cut the eye-corrected authored strip with one shared scale; no pixel painting."""
from pathlib import Path
import json
import sys
from PIL import Image,ImageDraw

ROOT=Path(__file__).resolve().parents[3]
sys.path.insert(0,str(ROOT/'tools'))
import import_art

HERE=Path(__file__).resolve().parent
source='assets/art_source/player/idle_south-eyes-v3.png'
prompt='implementation/sprites/generation/visibility-idle-eyes-v3.prompt.txt'
data=json.loads(import_art.MANIFEST.read_text())
original=json.loads((HERE/'eyes-original-recipes.json').read_text())
raw=Image.open(ROOT/source).convert('RGBA')
alpha=raw.getchannel('A').point(lambda a:255 if a>=128 else 0)
runs=[];start=None
for x in range(raw.width+1):
    on=x<raw.width and alpha.crop((x,0,x+1,raw.height)).getbbox() is not None
    if on and start is None:start=x
    if not on and start is not None:runs.append((start,x));start=None
assert len(runs)==3,runs
cuts=[0]+[(runs[i-1][1]+runs[i][0])//2 for i in range(1,3)]+[raw.width]
boxes=[]
for a,b in zip(cuts,cuts[1:]):
    box=alpha.crop((a,0,b,raw.height)).getbbox()
    boxes.append((a+box[0],box[1],a+box[2],box[3]))
scale=30/max(b[3]-b[1] for b in boxes)
entries=[];page=Image.new('RGBA',(192,128),(218,213,183))
d=ImageDraw.Draw(page)
d.text((0,0),'Before',fill=(20,20,20));d.text((0,64),'After',fill=(20,20,20))
for i,b in enumerate(boxes):
    e=next(e for e in data['assets'] if e['id']=='actors/idle_south_'+str(i))
    page.alpha_composite(import_art.render_source(original[i]),(i*64,16))
    e.update(source=source,source_sha256=import_art.sha((ROOT/source).read_bytes()),
             crop_xywh=[b[0],b[1],b[2]-b[0],b[3]-b[1]],
             sheet_cell_xywh=[cuts[i],0,cuts[i+1]-cuts[i],raw.height],gutter_xy=[0,0],
             content_scale=scale,revision=1,prompt=prompt,prompt_sha256=import_art.sha((ROOT/prompt).read_bytes()),
             references=[{'path':'assets/art_source/player/idle_south.png','role':'Original idle strip edit target',
                          'sha256':import_art.sha((ROOT/'assets/art_source/player/idle_south.png').read_bytes())}])
    image=import_art.render_source(e)
    page.alpha_composite(image,(i*64,80))
    e['output_sha256']=import_art.sha(import_art.png(image));entries.append(e)
page.save(HERE/'eyes-comparison-native.png')
page.resize((768,512),Image.Resampling.NEAREST).save(HERE/'eyes-comparison-4x.png')
(HERE/'eyes-recipes.json').write_text(json.dumps(entries,indent=2)+'\n')
print('Shared scale',scale,'boxes',boxes)
if '--install' in sys.argv:
    import_art.MANIFEST.write_text(json.dumps(data,indent=2)+'\n',encoding='utf-8',newline='\n')
    print('Installed only three frontal idle recipes')
