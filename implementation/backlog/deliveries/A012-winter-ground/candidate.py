"""Whole-square source reduction through the unchanged project importer."""
from pathlib import Path
import json,sys
from PIL import Image
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3];sys.path.insert(0,str(ROOT/'tools'))
from import_art import render_source
stem=sys.argv[1];source=HERE/f'raw/{stem}.png';im=Image.open(source).convert('RGBA');assert im.width==im.height
name=stem.rsplit('-r',1)[0]
groups={'grass':['bone','moon','bone_dark','grass_dark','grass'],'path':['bone','bone_dark','soil_light','soil','stone_light'],'soil':['soil_dark','soil','soil_light','bone','bone_dark'],'tilled':['soil_dark','soil','soil_light','ink_soft','ink','bone','bone_dark'],'edge':['bone','moon','bone_dark'],'shore':['bone','moon','bone_dark','wood_light','wood','soil_light','water_dark']}
group=next(g for g in groups if name.startswith(g))
entry={'id':'A012/'+name,'source':source.relative_to(ROOT).as_posix(),'crop_xywh':[0,0,im.width,im.height],'content_scale':16/im.width,'content_anchor_xy':[8,16],'alpha_threshold':128,'palette':'tools/palette.py:COLOURS','palette_keys':groups[group],'canvas_wh':[16,16],'pivot_xy':[8,16]}
native=render_source(entry);native.save(HERE/f'preview/{stem}-native.png');native.resize((160,160),Image.Resampling.NEAREST).save(HERE/f'preview/{stem}-10x.png')
repeat=Image.new('RGBA',(96,64))
for y in range(4):
    for x in range(6):repeat.alpha_composite(native,(16*x,16*y))
repeat.resize((384,256),Image.Resampling.NEAREST).save(HERE/f'preview/{stem}-repeat-4x.png')
(HERE/f'preview/{stem}-recipe.json').write_text(json.dumps({'anim':name,'stem':stem,'importer':entry},indent=2)+'\n')
print(json.dumps({'stem':stem,'source_size':im.size,'opaque':sum(p[3]>0 for p in native.getdata()),'colours':sorted(native.getcolors() or [],reverse=True),'seamless':all(native.getpixel((x,0))==native.getpixel((x,15)) for x in range(16)) and all(native.getpixel((0,y))==native.getpixel((15,y)) for y in range(16))}))
