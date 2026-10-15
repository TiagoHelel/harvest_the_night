"""Archive ImageGen receipts and measure sources. Never draw or patch sprite art."""
from pathlib import Path
import sys,json,hashlib,shutil
from PIL import Image
sys.dont_write_bytecode=True
D=Path(__file__).resolve().parent;ROOT=D.parents[3]
RECEIPT_DATE='2026-10-14'
sys.path.insert(0,str(ROOT/'tools'))
from import_art import render_source

def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def write(p,v):p.parent.mkdir(parents=True,exist_ok=True);p.write_text(json.dumps(v,indent=2)+'\n',encoding='utf-8')

def record(folder,stem,returned):
 folder=Path(folder).resolve();assert folder.parent==D.parent and folder.name[:4] in ['A028']+[f'A{i:03d}' for i in range(37,57)]
 args=json.loads((folder/f'raw/{stem}.request.json').read_text(encoding='utf-8'));src=Path(returned);target=folder/f'raw/{stem}.png'
 (folder/f'raw/{stem}.prompt.txt').write_text(args['prompt'],encoding='utf-8')
 if target.exists():assert sha(target)==sha(src)
 else:shutil.copyfile(src,target)
 roles_path=folder/f'raw/{stem}.roles.json';roles=json.loads(roles_path.read_text(encoding='utf-8')) if roles_path.exists() else {}
 refs=[{'path':p,'sha256':sha(Path(p)),'role':roles.get(p,'reference image; exact role specified in the recorded prompt')} for p in args.get('referenced_image_paths',[])]
 receipt={'tool':'built-in ImageGen','date':RECEIPT_DATE,'arguments':args,'input_images':refs,'returned_file':str(src),'raw_path':str(target.relative_to(ROOT)),'sha256':sha(target),'revision':int(stem.rsplit('-r',1)[1]),'decision':'pending native-size inspection'}
 write(folder/f'raw/{stem}.call.json',receipt)
 im=Image.open(target).convert('RGBA');box=im.getchannel('A').point(lambda a:255 if a>=128 else 0).getbbox()
 print(json.dumps({'source':str(target),'size':im.size,'alpha':im.getchannel('A').getextrema(),'bounds':box,'sha256':sha(target)}))

def preview_master(folder,stem,height,canvas,pivot,keys):
 folder=Path(folder);source=folder/f'raw/{stem}.png';im=Image.open(source).convert('RGBA');box=im.getchannel('A').point(lambda a:255 if a>=128 else 0).getbbox();x,y,r,b=box;crop=[x,y,r-x,b-y];scale=height/crop[3]
 recipe={'source':str(source.resolve()),'crop_xywh':crop,'content_scale':scale,'canvas_wh':canvas,'pivot_xy':pivot,'palette':'tools/palette.py:COLOURS','alpha_threshold':128,'palette_keys':keys}
 if keys is None:recipe.pop('palette_keys')
 native=render_source(recipe);out=folder/f'preview/{stem}-native.png';out.parent.mkdir(parents=True,exist_ok=True);native.save(out);native.resize((canvas[0]*8,canvas[1]*8),Image.Resampling.NEAREST).save(folder/f'preview/{stem}-8x.png');write(folder/f'raw/{stem}.recipe.json',recipe)
 print(json.dumps({'recipe':recipe,'native_bounds':native.getbbox(),'colours':len(set(native.get_flattened_data())),'preview':str(out)}))

def measure_strip(folder,stem,count):
 folder=Path(folder);source=folder/f'raw/{stem}.png';im=Image.open(source).convert('RGBA');mask=im.getchannel('A').point(lambda a:255 if a>=128 else 0)
 xs=[x for x in range(im.width) if mask.crop((x,0,x+1,im.height)).getbbox()]
 gaps=sorted(sorted([(b-a-1,a,b) for a,b in zip(xs,xs[1:]) if b-a>1],reverse=True)[:count-1],key=lambda g:g[1]);assert len(gaps)==count-1
 cuts=[0]+[(a+b)//2 for _,a,b in gaps]+[im.width];cells=[]
 for x0,x1 in zip(cuts,cuts[1:]):
  a,b,c,d=mask.crop((x0,0,x1,im.height)).getbbox();cells.append({'sheet_cell_xywh':[x0,0,x1-x0,im.height],'crop_xywh':[x0+a,b,c-a,d-b]})
 write(folder/f'raw/{stem}.cells.json',cells);print(json.dumps({'gaps':gaps,'cells':cells}))
 return cells

def preview_decoy_states(folder,stem):
 folder=Path(folder);cells=measure_strip(folder,stem,3);scale=26/cells[0]['crop_xywh'][3];ims=[];data=[]
 preview_w=max(16,max(round(c['crop_xywh'][2]*scale)+2 for c in cells));preview_w+=preview_w%2
 for index,c in enumerate(cells):
  recipe={'id':stem+f'-{index}','source':str((folder/f'raw/{stem}.png').resolve()),**c,'content_scale':scale,'canvas_wh':[16,32],'pivot_xy':[8,28],'palette':'tools/palette.py:COLOURS','alpha_threshold':128}
  im=render_source({**recipe,'canvas_wh':[preview_w,32],'pivot_xy':[preview_w//2,28]});ims.append(im);data.append({'recipe':recipe,'diagnostic_bounds':im.getbbox(),'diagnostic_canvas_wh':[preview_w,32],'unclipped_scaled_wh':[round(c['crop_xywh'][2]*scale),round(c['crop_xywh'][3]*scale)],'fits_target_canvas':round(c['crop_xywh'][2]*scale)<=16})
 strip=Image.new('RGBA',((preview_w+4)*3,32))
 for i,im in enumerate(ims):strip.alpha_composite(im,(i*(preview_w+4),0))
 (folder/'preview').mkdir(exist_ok=True);strip.resize((strip.width*8,256),Image.Resampling.NEAREST).save(folder/f'preview/{stem}-8x.png');write(folder/f'raw/{stem}.recipes.json',data);print(json.dumps(data))

def preview_decoy_sway(folder,stem,height):
 folder=Path(folder);cells=measure_strip(folder,stem,3);source=folder/f'raw/{stem}.png';raw=Image.open(source).convert('RGBA');mask=raw.getchannel('A').point(lambda a:255 if a>=128 else 0);scale=height/(sum(c['crop_xywh'][3] for c in cells)/3);ims=[];data=[]
 for index,c in enumerate(cells):
  x,y,w,h=c['crop_xywh'];bottom=[xx for xx in range(x,x+w) if mask.getpixel((xx,y+h-1))];ground_x=sum(bottom)/len(bottom);anchor=[round((ground_x-x)*scale),round(h*scale)];recipe={'id':stem+f'-{index}','source':str(source.resolve()),**c,'content_scale':scale,'content_anchor_xy':anchor,'canvas_wh':[16,32],'pivot_xy':[8,28],'palette':'tools/palette.py:COLOURS','alpha_threshold':128}
  im=render_source(recipe);ims.append(im);box=im.getbbox();head=[xx for yy in range(box[1],min(box[1]+7,32)) for xx in range(16) if im.getpixel((xx,yy))[3]];base=[xx for yy in range(24,28) for xx in range(16) if im.getpixel((xx,yy))[3]];data.append({'recipe':recipe,'native_bounds':box,'head_centre_x':sum(head)/len(head),'base_x_range':[min(base),max(base)],'raw_ground_x':ground_x})
 strip=Image.new('RGBA',(60,32))
 for i,im in enumerate(ims):strip.alpha_composite(im,(i*20,0))
 (folder/'preview').mkdir(exist_ok=True);strip.resize((480,256),Image.Resampling.NEAREST).save(folder/f'preview/{stem}-8x.png');write(folder/f'raw/{stem}.recipes.json',data);print(json.dumps(data))

def measure_grid(folder,stem):
 folder=Path(folder);source=folder/f'raw/{stem}.png';raw=Image.open(source).convert('RGBA');mask=raw.getchannel('A').point(lambda a:255 if a>=128 else 0)
 xs=[x for x in range(raw.width) if mask.crop((x,0,x+1,raw.height)).getbbox()];ys=[y for y in range(raw.height) if mask.crop((0,y,raw.width,y+1)).getbbox()]
 xgap=max((b-a-1,a,b) for a,b in zip(xs,xs[1:]) if b-a>1);ygap=max((b-a-1,a,b) for a,b in zip(ys,ys[1:]) if b-a>1);xc=(xgap[1]+xgap[2])//2;yc=(ygap[1]+ygap[2])//2;cells=[]
 for y0,y1 in [(0,yc),(yc,raw.height)]:
  for x0,x1 in [(0,xc),(xc,raw.width)]:
   a,b,c,d=mask.crop((x0,y0,x1,y1)).getbbox();cells.append({'sheet_cell_xywh':[x0,y0,x1-x0,y1-y0],'crop_xywh':[x0+a,y0+b,c-a,d-b]})
 write(folder/f'raw/{stem}.cells.json',cells);print(json.dumps({'cross_gaps':[xgap,ygap],'cells':cells}));return cells

def preview_hive_states(folder,stem,height):
 folder=Path(folder);cells=measure_grid(folder,stem);scale=height/cells[0]['crop_xywh'][3];ims=[];data=[]
 for i,c in enumerate(cells):
  e={'id':stem+f'-{i}','source':str((folder/f'raw/{stem}.png').resolve()),**c,'content_scale':scale,'canvas_wh':[32,48],'pivot_xy':[16,44],'palette':'tools/palette.py:COLOURS','alpha_threshold':128};im=render_source(e);ims.append(im);b=im.getbbox();data.append({'recipe':e,'native_bounds':b,'visible_wh':[b[2]-b[0],b[3]-b[1]]})
 out=Image.new('RGBA',(72,104))
 for i,im in enumerate(ims):out.alpha_composite(im,((i%2)*36,(i//2)*52))
 (folder/'preview').mkdir(exist_ok=True);out.resize((432,624),Image.Resampling.NEAREST).save(folder/f'preview/{stem}-6x.png');write(folder/f'raw/{stem}.recipes.json',data);print(json.dumps(data))

def preview_bee_swarm(folder,stem):
 folder=Path(folder);cells=measure_strip(folder,stem,3);scale=6/max(max(c['crop_xywh'][2:]) for c in cells);ims=[];data=[]
 for i,c in enumerate(cells):
  w,h=[round(v*scale) for v in c['crop_xywh'][2:]];e={'id':stem+f'-{i}','source':str((folder/f'raw/{stem}.png').resolve()),**c,'content_scale':scale,'content_anchor_xy':[w//2,h//2],'canvas_wh':[8,8],'pivot_xy':[4,4],'palette':'tools/palette.py:COLOURS','palette_keys':['ink','gold'],'alpha_threshold':128};im=render_source(e);ims.append(im);pending={(x,y) for y in range(8) for x in range(8) if im.getpixel((x,y))[3]};groups=[]
  while pending:
   q=[pending.pop()];group=set(q)
   while q:
    x,y=q.pop()
    for v in [(x-1,y),(x+1,y),(x,y-1),(x,y+1)]:
     if v in pending:pending.remove(v);group.add(v);q.append(v)
   groups.append(len(group))
  data.append({'recipe':e,'native_bounds':im.getbbox(),'opaque_pixels':sum(im.getpixel((x,y))[3]>0 for y in range(8) for x in range(8)),'component_sizes_4':sorted(groups),'opaque_colours':sorted({p[:3] for p in im.get_flattened_data() if p[3]})})
 out=Image.new('RGBA',(36,8))
 for i,im in enumerate(ims):out.alpha_composite(im,(i*12,0))
 (folder/'preview').mkdir(exist_ok=True);out.resize((576,128),Image.Resampling.NEAREST).save(folder/f'preview/{stem}-16x.png');write(folder/f'raw/{stem}.recipes.json',data);print(json.dumps(data))

if __name__=='__main__':
 if sys.argv[1]=='record':record(*sys.argv[2:5])
 elif sys.argv[1]=='dog-master':preview_master(sys.argv[2],sys.argv[3],16,[40,32],[20,30],['ink','ink_soft','wood_dark','wood','wood_light','soil_dark','bone_dark','bone','roof_light'])
 elif sys.argv[1]=='dog-sit':preview_master(sys.argv[2],sys.argv[3],17,[40,32],[20,30],['ink','ink_soft','wood_dark','wood','wood_light','soil_dark','bone_dark','bone','roof_light'])
 elif sys.argv[1]=='decoy-master':preview_master(sys.argv[2],sys.argv[3],26,[16,32],[8,28],None)
 elif sys.argv[1]=='decoy-states':preview_decoy_states(sys.argv[2],sys.argv[3])
 elif sys.argv[1]=='measure':measure_strip(sys.argv[2],sys.argv[3],int(sys.argv[4]))
 elif sys.argv[1]=='decoy-sway':preview_decoy_sway(sys.argv[2],sys.argv[3],float(sys.argv[4]))
 elif sys.argv[1]=='hive-master':preview_master(sys.argv[2],sys.argv[3],21,[32,48],[16,44],None)
 elif sys.argv[1]=='grid':measure_grid(sys.argv[2],sys.argv[3])
 elif sys.argv[1]=='hive-states':preview_hive_states(sys.argv[2],sys.argv[3],float(sys.argv[4]))
 elif sys.argv[1]=='bee-swarm':preview_bee_swarm(sys.argv[2],sys.argv[3])
