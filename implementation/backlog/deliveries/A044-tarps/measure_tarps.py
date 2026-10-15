"""Register ImageGen cloth states to the measured covered cell ground point."""
from pathlib import Path
import sys,json
from PIL import Image
sys.dont_write_bytecode=True
D=Path(__file__).resolve().parent;ROOT=D.parents[3];sys.path.insert(0,str(ROOT/'implementation/backlog/deliveries/A028-dog'));from source_tools import measure_strip,write
sys.path.insert(0,str(ROOT/'tools'));from import_art import render_source
stem=sys.argv[1];kind=sys.argv[2];height=float(sys.argv[3]);canvas,pivot={'tower':([32,48],[16,44]),'tall':([16,32],[8,28]),'short':([16,24],[8,20])}[kind];cells=measure_strip(D,stem,4);scale=height/cells[0]['crop_xywh'][3];covered=cells[0];x,y,w,h=covered['crop_xywh'];local_ground_x=x+w/2-covered['sheet_cell_xywh'][0];ground_y=y+h;data=[];out=Image.new('RGBA',((canvas[0]+4)*4,canvas[1]))
for i,c in enumerate(cells):
 x,y,w,h=c['crop_xywh'];anchor=[round((local_ground_x+c['sheet_cell_xywh'][0]-x)*scale),round((ground_y-y)*scale)] if i>=2 else [round(w*scale)//2,round(h*scale)];r={'id':stem+'-'+str(i),'source':str((D/f'raw/{stem}.png').resolve()),**c,'content_scale':scale,'content_anchor_xy':anchor,'canvas_wh':canvas,'pivot_xy':pivot,'alpha_threshold':128,'palette':'tools/palette.py:COLOURS'};im=render_source(r);data.append({'recipe':r,'native_bounds':im.getbbox(),'measured_covered_local_ground':[local_ground_x,ground_y]});out.alpha_composite(im,(i*(canvas[0]+4),0))
write(D/f'raw/{stem}.recipes.json',data);out.resize((out.width*6,out.height*6),Image.Resampling.NEAREST).save(D/f'preview/{stem}-registered-6x.png');print(json.dumps(data))
