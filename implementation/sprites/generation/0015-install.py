"""Install measured authored enemies and explicit legacy-name aliases."""
from pathlib import Path
import json
import sys
from PIL import Image
ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
sys.path.insert(0,str(ROOT/'tools'))
import import_art

FAMILIES = ('walker','runner','tank','breaker')
SELECTED = {('runner','death'):'death-r1', ('tank','death'):'death-r1',
            ('breaker','walk'):'walk-r2', ('breaker','attack'):'attack-r1'}
# Allow the farmer's ground baseline with a roomy horizontal envelope. Bodies stay 29px;
# asymmetric lunges and the hammer need clearance, not a smaller character.
CANVAS, PIVOT = [64,48], [32,44]

def entries():
    out = []
    for family in FAMILIES:
        for motion in ('master','walk','attack','death'):
            chosen = SELECTED.get((family,motion),motion)
            c = json.loads((HERE/f'0015-{family}-{chosen}-call.json').read_text())
            heights = [m['crop_xywh'][3] for m in c['measurements']]
            # Raw tool resolutions vary between calls. Calibrate a sequence
            # once from its standing recovery or first buckling pose, then
            # preserve that exact scale for every frame, including collapse.
            reference_height = heights[-1] if motion=='attack' else max(heights)
            scale = (27 if motion=='death' else 29)/reference_height
            for frame,m in enumerate(c['measurements']):
                name = family if motion=='master' else f'{family}_{motion}_{frame}'
                ident = 'enemies/'+name
                w,h = [max(1,round(n*scale)) for n in m['crop_xywh'][2:]]
                # Measure the two lowest native rows. Arms and raised tools
                # cannot bias the ground anchor toward a reaching hand.
                raw = Image.open(ROOT/c['source']).convert('RGBA')
                x,y,cw,ch = m['crop_xywh']
                mask = raw.crop((x,y,x+cw,y+ch)).getchannel('A').resize((w,h),Image.Resampling.NEAREST).point(lambda a:255 if a>=128 else 0)
                foot_box = mask.crop((0,max(0,h-2),w,h)).getbbox()
                anchor_x = w//2 if motion=='death' else (foot_box[0]+foot_box[2])//2
                e = dict(id=ident, owner='raster', source=c['source'], source_sha256=c['source_sha256'],
                         crop_xywh=m['crop_xywh'], sheet_cell_xywh=m['sheet_cell_xywh'], gutter_xy=[0,0],
                         canvas_wh=CANVAS, pivot_xy=PIVOT, content_scale=scale, content_anchor_xy=[anchor_x,h],
                         alpha_threshold=128, palette='tools/palette.py:COLOURS',
                         animation='enemies/'+family+'_'+motion, frame=frame, seconds=0.125 if motion=='walk' else 0.1,
                         loop=motion in ('master','walk'), output='sprites/'+ident+'.png',
                         prompt=c['prompt'],prompt_sha256=c['prompt_sha256'],
                         references=[dict(path=p,sha256=c['reference_hashes'][p],role='As indexed in exact submitted prompt') for p in c['references']],
                         tool='built-in ImageGen', generation_task='0015', revision=c['revision'],
                         enemy_family=family, enemy_motion=motion, enemy_master_id='enemies/'+family,
                         scale_reference=dict(role='recovery standing pose' if motion=='attack' else 'first buckling pose' if motion=='death' else 'tallest standing pose',raw_height=reference_height,native_height=27 if motion=='death' else 29),
                         ground_measurement='lowest two native alpha rows' if motion!='death' else 'collapse bounds midpoint',
                         cell_offset_xy=[8-PIVOT[0],16-PIVOT[1]])
                if frame>0:e['variant_of']='enemies/'+family+'_'+motion+'_0'
                image = import_art.render_source(e)
                e['output_sha256']=import_art.sha(import_art.png(image))
                out.append(e)
        for suffix, target in (('walk_b','walk_2'),('attack','attack_1'),('death','death_3')):
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
    replace = {f'enemies/{family}'+suffix for family in FAMILIES for suffix in ('','_walk_b','_attack','_death')}
    data['assets']=[e for e in data['assets'] if e['id'] not in replace and e.get('generation_task')!='0015']+fresh
    path.write_text(json.dumps(data,indent=2)+'\n',encoding='utf-8',newline='\n')
    ownership = ROOT/'assets/art_source/ownership.json'
    owners = json.loads(ownership.read_text())
    by_output = {e['output']:e for e in owners['outputs']}
    for e in fresh:by_output[e['output']] = dict(output=e['output'], owner='raster')
    owners['outputs'] = [by_output[p] for p in sorted(by_output)]
    ownership.write_text(json.dumps(owners,indent=2)+'\n',encoding='utf-8',newline='\n')
    print(f'Installed {len(fresh)} enemy frames/aliases; {len(data["assets"])} raster entries')

if __name__=='__main__':main()
