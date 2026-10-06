"""Source-owned neutral idle; never derive a stopped farmer from a walk phase."""
from pathlib import Path
import json
import sys
import colorsys
from PIL import Image

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[4]
sys.path.insert(0,str(ROOT/'tools'))
import import_art
sys.path.insert(0,str(HERE))
from prepare import DIRS, digest

CONTRACT=HERE/'runtime-idle-contract.json'

def runtime_entries():
    contract=json.loads(CONTRACT.read_text())
    prompt=contract['prompt'];refs=[contract['raw'],*contract['references'],
        {'path':CONTRACT.relative_to(ROOT).as_posix(),'sha256':digest(CONTRACT),
         'role':'Dedicated grounded idle geometry and approved walking pixel invariance'}]
    entries=[]
    for frame in contract['frames']:
        suffix=frame['suffix'];source=frame['source']
        for index in range(contract['idle_slots']):
            entry={'id':f'actors/idle_{suffix}_{index}','owner':'raster',
                   'source':source['path'],'source_sha256':source['sha256'],
                   'crop_xywh':[0,0,80,80],'canvas_wh':[80,80],'pivot_xy':[40,72],
                   'content_anchor_xy':[40,72],'content_scale':1.0,'draw_scale':.5,
                   'alpha_threshold':128,'palette':import_art.EXACT_SOURCE,
                   'animation':f'idle_{suffix}','frame':index,'seconds':.55,'loop':True,
                   'output':f'sprites/actors/idle_{suffix}_{index}.png',
                   'prompt':prompt['path'],'prompt_sha256':prompt['sha256'],
                   'references':refs,'tool':'built-in ImageGen','generation_task':'fhd-idle-grounded',
                   'approval':'User-requested raised-foot idle fix; 2026-10-05'}
            entry['output_sha256']=import_art.sha(import_art.png(import_art.render_source(entry)))
            entries.append(entry)
    return entries

def check():
    baseline=json.loads((HERE/'walk-baseline.json').read_text())
    assert len(baseline)==192
    for path,expected in baseline.items():
        assert digest(ROOT/path)==expected, ('Approved walk changed',path)
    contract=json.loads(CONTRACT.read_text())
    palette={tuple(rgb) for rgb in contract['palette_rgb']}
    manifest=json.loads(import_art.MANIFEST.read_text())
    actual={e['id']:e for e in manifest['assets']}
    for entry in runtime_entries():
        assert actual[entry['id']]==entry, ('Idle recipe drift',entry['id'])
        assert 'input' not in entry and 'alias_of' not in entry
        source=Image.open(ROOT/entry['source']).convert('RGBA')
        runtime=Image.open(ROOT/entry['output']).convert('RGBA')
        assert runtime.tobytes()==source.tobytes()
        assert source.size==(80,80) and set(source.getchannel('A').get_flattened_data())<={0,255}
        bounds=source.getbbox();assert 63<=bounds[3]-bounds[1]<=65 and bounds[3]==72
        boot_pixels=[]
        for y in range(80):
            for x in range(80):
                r,g,b,a=source.getpixel((x,y));h,s,v=colorsys.rgb_to_hsv(r/255,g/255,b/255)
                if a and y>=28 and 185<=h*360<=270 and s>=.3 and b>=6:
                    assert (r,g,b) in palette, ('Garment palette drift',entry['id'])
                if a and y>=52 and r>g+8 and g>b+5 and r>40:
                    boot_pixels.append((x,y))
        assert boot_pixels and min(y for x,y in boot_pixels)>=60, ('Suspended boot',entry['id'])
        suffix=entry['animation'][5:]
        for i in range(8):
            walk=Image.open(ROOT/f'sprites/actors/walk_{suffix}_{i}.png').convert('RGBA')
            assert runtime.tobytes()!=walk.tobytes(), ('Idle still holds a walk phase',entry['id'],i)
    print('GROUNDED IDLE: 8 dedicated poses / 24 slots, low resting boots, common height/pivot/palette; 192 approved walk hashes unchanged.')

if __name__=='__main__':check()
