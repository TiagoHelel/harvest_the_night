"""Install measured authored enemies and explicit legacy-name aliases."""
from pathlib import Path
import json
import sys
from PIL import Image
ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
sys.path.insert(0,str(ROOT/'tools'))
import import_art

FAMILIES = ('giant',)
SELECTED = {}
# The leftward ground slam needs fist clearance while the feet stay planted.
# Add transparent width; the standing body still measures 42 pixels high.
CANVAS, PIVOT = [80,64], [40,60]

def entries():
    out = []
    for family in FAMILIES:
        for motion in ('master','walk','windup','slam','death'):
            chosen = SELECTED.get((family,motion),motion)
            c = json.loads((HERE/f'0016-{family}-{chosen}-call.json').read_text())
            heights = [m['crop_xywh'][3] for m in c['measurements']]
            # Raw tool resolutions vary between calls. Calibrate a sequence
            # once from its standing recovery or first buckling pose, then
            # preserve that exact scale for every frame, including collapse.
            reference_height = heights[-1] if motion=='slam' else heights[0] if motion in ('windup','death') else max(heights)
            native_height = 39 if motion in ('windup','death') else 42
            scale = native_height/reference_height
            for frame,m in enumerate(c['measurements']):
                name = family if motion=='master' else f'{family}_{motion}_{frame}'
                ident = 'enemies/'+name
                w,h = [max(1,round(n*scale)) for n in m['crop_xywh'][2:]]
                # Measure the eight lowest native rows. Arms and raised tools
                # share a measured lower support band with the spread feet.
                raw = Image.open(ROOT/c['source']).convert('RGBA')
                x,y,cw,ch = m['crop_xywh']
                mask = raw.crop((x,y,x+cw,y+ch)).getchannel('A').resize((w,h),Image.Resampling.NEAREST).point(lambda a:255 if a>=128 else 0)
                support_x = round(w*0.42) if motion=='slam' and frame<2 else 0
                foot_box = mask.crop((support_x,max(0,h-8),w,h)).getbbox()
                anchor_x = w//2 if motion=='death' else support_x+(foot_box[0]+foot_box[2])//2
                e = dict(id=ident, owner='raster', source=c['source'], source_sha256=c['source_sha256'],
                         crop_xywh=m['crop_xywh'], sheet_cell_xywh=m['sheet_cell_xywh'], gutter_xy=[0,0],
                         canvas_wh=CANVAS, pivot_xy=PIVOT, content_scale=scale, content_anchor_xy=[anchor_x,h],
                         alpha_threshold=128, palette='tools/palette.py:COLOURS',
                         animation='enemies/'+family+'_'+motion, frame=frame, seconds=0.12 if motion=='death' else 0.14 if motion=='walk' else 0.1,
                         loop=motion in ('master','walk'), output='sprites/'+ident+'.png',
                         prompt=c['prompt'],prompt_sha256=c['prompt_sha256'],
                         references=[dict(path=p,sha256=c['reference_hashes'][p],role='As indexed in exact submitted prompt') for p in c['references']],
                         tool='built-in ImageGen', generation_task='0016', revision=c['revision'],
                         enemy_family=family, enemy_motion=motion, enemy_master_id='enemies/'+family,
                         scale_reference=dict(role='standing recovery' if motion=='slam' else 'first crouch' if motion in ('windup','death') else 'tallest standing pose',raw_height=reference_height,native_height=native_height),
                         ground_measurement='lower eight-row support band, excluding left contact fist for slam 0/1' if motion!='death' else 'collapse bounds midpoint',
                         cell_offset_xy=[8-PIVOT[0],16-PIVOT[1]])
                if frame>0:e['variant_of']='enemies/'+family+'_'+motion+'_0'
                image = import_art.render_source(e)
                e['output_sha256']=import_art.sha(import_art.png(image))
                out.append(e)
        for suffix, target in (('walk_b','walk_2'),('attack','slam_0'),('death','death_4'),('telegraph','windup_2')):
            original = next(e for e in out if e['id']=='enemies/'+family+'_'+target)
            e = {k:v for k,v in original.items() if k not in ('source','source_sha256','crop_xywh','sheet_cell_xywh','gutter_xy','content_scale','content_anchor_xy','alpha_threshold','variant_of','scale_reference','ground_measurement')}
            e.update(id='enemies/'+family+'_'+suffix,output='sprites/enemies/'+family+'_'+suffix+'.png',
                     input=original['id'],operation='copy',animation='enemies/'+family+'_compat_'+suffix,frame=0,
                     alias_of=original['id'],loop=False)
            out.append(e)
    return out

def main():
    fresh = entries()
    path = ROOT/'assets/art_source/manifest.json'
    data = json.loads(path.read_text())
    replace = {f'enemies/{family}'+suffix for family in FAMILIES for suffix in ('','_walk_b','_attack','_death','_telegraph')}
    data['assets']=[e for e in data['assets'] if e['id'] not in replace and e.get('generation_task')!='0016']+fresh
    path.write_text(json.dumps(data,indent=2)+'\n',encoding='utf-8',newline='\n')
    ownership = ROOT/'assets/art_source/ownership.json'
    owners = json.loads(ownership.read_text())
    by_output = {e['output']:e for e in owners['outputs']}
    for e in fresh:by_output[e['output']] = dict(output=e['output'], owner='raster')
    owners['outputs'] = [by_output[p] for p in sorted(by_output)]
    ownership.write_text(json.dumps(owners,indent=2)+'\n',encoding='utf-8',newline='\n')
    print(f'Installed {len(fresh)} enemy frames/aliases; {len(data["assets"])} raster entries')

if __name__=='__main__':main()
