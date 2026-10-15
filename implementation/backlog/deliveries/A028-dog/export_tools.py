"""Measure and convert recorded ImageGen sources, without authoring art."""
from pathlib import Path
import sys,json
from PIL import Image
sys.dont_write_bytecode=True
sys.path.insert(0,str(Path(__file__).resolve().parent))
from source_tools import measure_strip,measure_grid,write,ROOT
sys.path.insert(0,str(ROOT/'tools'))
from import_art import render_source

def group(folder,stem,layout,canvas,pivot,height,index=0,centre=False):
 folder=Path(folder);src=folder/f'raw/{stem}.png'
 if layout=='single':
  im=Image.open(src).convert('RGBA');b=im.getchannel('A').point(lambda a:255 if a>=128 else 0).getbbox();cells=[{'crop_xywh':[b[0],b[1],b[2]-b[0],b[3]-b[1]],'sheet_cell_xywh':[0,0,*im.size]}]
 elif layout=='grid':
  try:cells=measure_grid(folder,stem)
  except ValueError:
   # Each column can have a different measured row gap. Never guess a half-sheet cut.
   raw=Image.open(src).convert('RGBA');mask=raw.getchannel('A').point(lambda a:255 if a>=128 else 0);xs=[x for x in range(raw.width) if mask.crop((x,0,x+1,raw.height)).getbbox()];gap=max((b-a-1,a,b) for a,b in zip(xs,xs[1:]) if b-a>1);xc=(gap[1]+gap[2])//2;columns=[]
   for x0,x1 in [(0,xc),(xc,raw.width)]:
    ys=[y for y in range(raw.height) if mask.crop((x0,y,x1,y+1)).getbbox()];gap=max((b-a-1,a,b) for a,b in zip(ys,ys[1:]) if b-a>1);yc=(gap[1]+gap[2])//2;col=[]
    for y0,y1 in [(0,yc),(yc,raw.height)]:
     a,b,c,d=mask.crop((x0,y0,x1,y1)).getbbox();col.append({'sheet_cell_xywh':[x0,y0,x1-x0,y1-y0],'crop_xywh':[x0+a,y0+b,c-a,d-b]})
    columns.append(col)
   cells=[columns[0][0],columns[1][0],columns[0][1],columns[1][1]];write(folder/f'raw/{stem}.cells.json',cells)
 else:cells=measure_strip(folder,stem,int(layout))
 if centre:scale=height/max(max(c['crop_xywh'][2:]) for c in cells)
 else:scale=height/cells[index]['crop_xywh'][3]
 data=[];strip=Image.new('RGBA',((canvas[0]+4)*len(cells),canvas[1]))
 for i,c in enumerate(cells):
  w,h=[round(v*scale) for v in c['crop_xywh'][2:]]
  r={'id':stem+'-'+str(i),'source':str(src.resolve()),**c,'content_scale':scale,'canvas_wh':canvas,'pivot_xy':pivot,'alpha_threshold':128,'palette':'tools/palette.py:COLOURS'}
  if centre:r['content_anchor_xy']=[w//2,h//2]
  im=render_source(r);data.append({'recipe':r,'native_bounds':im.getbbox(),'unclipped_scaled_wh':[w,h]});strip.alpha_composite(im,(i*(canvas[0]+4),0))
 (folder/'preview').mkdir(exist_ok=True);strip.resize((strip.width*6,strip.height*6),Image.Resampling.NEAREST).save(folder/f'preview/{stem}-group-6x.png');write(folder/f'raw/{stem}.recipes.json',data);print(json.dumps(data))

def register_feet(folder,stem,band=5):
 folder=Path(folder);p=folder/f'raw/{stem}.recipes.json';data=json.loads(p.read_text(encoding='utf-8'));raw=Image.open(folder/f'raw/{stem}.png').convert('RGBA');mask=raw.getchannel('A').point(lambda a:255 if a>=128 else 0);ims=[]
 for e in data:
  r=e['recipe'];x,y,w,h=r['crop_xywh'];scale=r['content_scale'];box=mask.crop((x,y+h-max(1,round(band/scale)),x+w,y+h)).getbbox();contact=(box[0]+box[2])/2;r['content_anchor_xy']=[round(contact*scale),round(h*scale)];im=render_source(r)
  dy=im.getbbox()[3]-r['pivot_xy'][1];r['content_anchor_xy'][1]+=dy;im=render_source(r)
  native_band=im.getchannel('A').crop((0,r['pivot_xy'][1]-band,im.width,r['pivot_xy'][1])).getbbox();native_centre=(native_band[0]+native_band[2])/2;delta=round(native_centre-r['pivot_xy'][0]);r['content_anchor_xy'][0]+=delta;im=render_source(r);e['native_bounds']=im.getbbox();e['measured_contact_band_raw_xywh']=[x,y+h-max(1,round(band/scale)),w,max(1,round(band/scale))];e['contact_centre_raw_x']=x+contact;e['native_grid_registration_dx']=delta;e['native_grid_registration_dy']=dy;ims.append(im)
 out=Image.new('RGBA',((ims[0].width+4)*len(ims),ims[0].height))
 for i,im in enumerate(ims):out.alpha_composite(im,(i*(im.width+4),0))
 write(p,data);out.resize((out.width*6,out.height*6),Image.Resampling.NEAREST).save(folder/f'preview/{stem}-feet-6x.png');print(json.dumps([{'bounds':e['native_bounds'],'anchor':e['recipe']['content_anchor_xy']} for e in data]))

if __name__=='__main__':
 folder,stem,layout=sys.argv[1:4];canvas=[int(v) for v in sys.argv[4].split(',')];pivot=[int(v) for v in sys.argv[5].split(',')];group(folder,stem,layout,canvas,pivot,float(sys.argv[6]),int(sys.argv[7]) if len(sys.argv)>7 else 0,'centre' in sys.argv)
