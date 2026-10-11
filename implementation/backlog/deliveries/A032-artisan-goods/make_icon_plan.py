from pathlib import Path
import json,sys,shutil
from PIL import Image
D=Path(__file__).resolve().parent;ROOT=D.parents[3];sys.path.insert(0,str(ROOT/'tools'))
from import_art import render_source
source_map=json.loads((D/'raw/icon-source-map.json').read_text());files=[];isfish=D.name.startswith('A022');sizes=[('portrait',32,30),('icon',16,14),('hud',10,8)] if isfish else [('icon',16,14),('hud',10,8)]
for id,source in source_map.items():
 p=D/source;im=Image.open(p).convert('RGBA');a,b,c,d=im.getchannel('A').point(lambda a:255 if a>=128 else 0).getbbox();crop=[a,b,c-a,d-b]
 for kind,size,maxv in sizes:
  scale=maxv/max(crop[2:]);anchor=[round(crop[2]*scale)//2,round(crop[3]*scale)//2];name=kind+'_'+id;recipe={'crop_xywh':crop,'content_scale':scale,'content_anchor_xy':anchor};f={'anim':name,'dir':'none','frame':0,'output':f'native/{name}/none/01.png','runtime_name':f'sprites/ui/{name}.png','canvas_wh':[size,size],'pivot_xy':[size//2]*2,'draw_scale':1.0,'seconds':1.0,'loop':False,'mirror':'none','pose':id+' icon','source':source,'prompt':source.replace('.png','.prompt.txt'),'call':source.replace('.png','.call.json'),'recipe':recipe,'grounded':False,'points':{},'resource_id':id,'display_role':{'portrait':'book_portrait','icon':'inventory','hud':'compact_hud'}[kind]};files.append(f);n=render_source({'id':name,'source':str(p),'canvas_wh':[size,size],'pivot_xy':[size//2]*2,'palette':'tools/palette.py:COLOURS','alpha_threshold':128,**recipe});n.resize((size*8,size*8),Image.Resampling.NEAREST).save(D/f'preview/{name}-inspect.png')
plan={'expected_files':48 if isfish else 22,'status':'generating','palette_mode':'A','colour_ramp':[],'files':files,'comparison':[{'path':'sprites/ui/icon_fish.png' if isfish else 'sprites/ui/icon_oil.png','pivot_xy':[8,8],'draw_scale':1}],'deviations':[],'supersedes':[]};(D/'raw/export-plan.json').write_text(json.dumps(plan,indent=2));shutil.copyfile(ROOT/'implementation/backlog/deliveries/A030-coop-barn/export_core.py',D/'build.py');print('Planned',len(files),'icon cuts')
