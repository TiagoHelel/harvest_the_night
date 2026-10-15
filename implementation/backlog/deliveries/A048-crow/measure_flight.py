"""Register source bird to measured body core, not moving wing bounds."""
from pathlib import Path
import sys,json
from PIL import Image
sys.dont_write_bytecode=True
D=Path(__file__).resolve().parent;ROOT=D.parents[3];sys.path.insert(0,str(ROOT/'implementation/backlog/deliveries/A028-dog'));from source_tools import measure_strip,write
sys.path.insert(0,str(ROOT/'tools'));from import_art import render_source
stem=sys.argv[1];cells=measure_strip(D,stem,4);spec=json.loads((D/f'raw/{stem}.body-measurements.json').read_text());scale=spec['body_length_native']/spec['body_length_raw'];data=[];out=Image.new('RGBA',(144,24))
for i,c in enumerate(cells):
 x,y,w,h=c['crop_xywh'];bx,by=spec['body_points_raw_xy'][i];r={'id':stem+'-'+str(i),'source':str((D/f'raw/{stem}.png').resolve()),**c,'content_scale':scale,'content_anchor_xy':[round((bx-x)*scale),round((by-y)*scale)+22-spec['torso_bottom_native']],'canvas_wh':[32,24],'pivot_xy':[16,22],'alpha_threshold':128,'palette':'tools/palette.py:COLOURS'};im=render_source(r);data.append({'recipe':r,'native_bounds':im.getbbox(),'measured_body_point':[bx,by]});out.alpha_composite(im,(i*36,0))
write(D/f'raw/{stem}.recipes.json',data);out.resize((864,144),Image.Resampling.NEAREST).save(D/f'preview/{stem}-registered-6x.png');print(json.dumps(data))
