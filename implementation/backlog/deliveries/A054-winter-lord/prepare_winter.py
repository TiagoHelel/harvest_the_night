"""Build recorded-source diagnostic candidates; never writes production sprites."""
from pathlib import Path
import json, shutil
D=Path(__file__).resolve().parent; RAW=D/'raw'; ROOT=D.parents[3]
import sys
sys.path.insert(0,str(ROOT/'tools'))
from import_art import render_source
from palette import COLOURS
def read(p): return json.loads(p.read_text(encoding='utf-8'))
def write(p,v): p.write_text(json.dumps(v,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
spec=[('winter_lord','west','winter-master-r1',1,.1,False,False,'recipe'),('winter_lord_attack','west','winter-attack-r2',3,.1,False,False,'recipes'),('winter_lord_death','west','winter-death-r2',5,.12,False,False,'recipes'),('ice_shards','none','winter-shards-r1',4,.1,False,False,'recipes'),('head_winter_lord','none','winter-head-r3',1,1.,False,True,'single')]
files=[]; rgb=set(); decisions={}; recipe_cache={}
for anim,direction,stem,count,seconds,loop,icon,kind in spec:
    p=RAW/(stem+('.recipe.json' if kind=='recipe' else '.recipes.json' if kind=='recipes' else '.unused.json'))
    if kind=='recipe': items=[{'recipe':read(p)}]
    elif kind=='recipes': items=read(p)
    else:
        from PIL import Image
        im=Image.open(RAW/(stem+'.png')).convert('RGBA'); box=im.getchannel('A').point(lambda a:255 if a>=128 else 0).getbbox(); x,y,r,b=box; w,h=r-x,b-y; s=14/h
        recipe={'id':stem,'source':str((RAW/(stem+'.png')).resolve()),'crop_xywh':[x,y,w,h],'sheet_cell_xywh':[0,0,*im.size],'content_scale':s,'content_anchor_xy':[round(w*s/2),round(h*s)-7],'canvas_wh':[16,16],'pivot_xy':[8,8],'alpha_threshold':128,'palette':'tools/palette.py:COLOURS'}
        items=[{'recipe':recipe}]
    decisions[stem]={'decision':'selected diagnostic source; not approved'}
    call=read(RAW/(stem+'.call.json')); call['decision']='selected diagnostic source; not approved'; write(RAW/(stem+'.call.json'),call)
    recipe_cache[stem]=items
    for i,item in enumerate(items):
        recipe=item['recipe']
        if anim!='head_winter_lord': rgb.update(px[:3] for px in render_source(recipe).get_flattened_data() if px[3])
body_keys=[k for k,c in COLOURS.items() if c in rgb]
for anim,direction,stem,count,seconds,loop,icon,kind in spec:
    items=recipe_cache[stem]
    for i,item in enumerate(items):
        recipe=item['recipe']
        if anim=='head_winter_lord': recipe['palette_keys']=body_keys
        canvas=[24,20] if anim=='ice_shards' else [16,16] if icon else [80,64]
        pivot=[12,18] if anim=='ice_shards' else [8,8] if icon else [40,60]
        files.append({'anim':anim,'dir':direction,'frame':i,'pose':f'{anim}_{i}','output':f'native/{anim}/{direction}/{i+1:02d}.png','source':f'raw/{stem}.png','prompt':f'raw/{stem}.prompt.txt','call':f'raw/{stem}.call.json','recipe':recipe,'canvas_wh':canvas,'pivot_xy':pivot,'draw_scale':1,'seconds':seconds,'loop':loop,'mirror':'none' if icon or direction=='none' else 'runtime','grounded':anim.startswith('winter_lord') and not icon,'palette_keys':body_keys if icon else None})
expected=22
plan={'title':'The Winter Lord','date':'2026-10-14','status':'blocked','palette_mode':'A','expected_files':expected,'files':files,'comparison':[{'path':'sprites/enemies/giant.png','pivot_xy':[40,60],'draw_scale':1.0}],'deviations':['The walk strip could not be separated into four unambiguous frames after three attempts.','The cast exceeds the 58px silhouette ceiling at the master body scale after three attempts.','Death grows from 46px to 51px in frame 1, violating the monotonic fall; three attempts used.','The forecast icon remains diagnostic; the three generated portraits are oversized and the required walk-frame colour reference could not be extracted.'],'supersedes':[]}
write(RAW/'export-plan.json',plan)
write(RAW/'selection.json',{'status':'blocked','issues':plan['deviations'],'files':{f"{f['anim']}/{f['dir']}/{f['frame']}":{'stem':f['source'][4:-4],'index':f['frame']} for f in files},'rejected':{'winter-walk-r1':'No three transparent gutters; figures touch.','winter-walk-r2':'Gait is largely hidden by robe; no three transparent gutters.','winter-walk-r3':'No three transparent gutters after final attempt.','winter-cast-r1':'Frame heights exceed 58px at master scale.','winter-cast-r2':'Frames overlap and heights exceed 58px at master scale.','winter-cast-r3':'Frame heights exceed 58px at master scale.','winter-death-r1':'Poses touch; no four measurable gutters.','winter-death-r2':'Pose 1 height 51px exceeds pose 0 height 46px.','winter-head-r1':'Oversized portrait, not a 16px icon.','winter-head-r2':'Oversized portrait repeated; no compact icon.','winter-head-r3':'Still an oversized portrait; maximum three attempts reached.'},'decisions':decisions,'body_palette_keys':body_keys})
write(D/'review-log.json',{'date':'2026-10-14','status':'blocked','selected_candidate_files':len(files),'expected_files':expected,'approved':False,'issues':plan['deviations']})
(D/'review-log.txt').write_text('2026-10-14: Diagnostic candidates were assembled from recorded ImageGen sources. Walk, cast, death, and forecast-mark constraints remain unmet as listed in raw/selection.json. Package blocked; no production export and no approval inferred.\n',encoding='utf-8')
shutil.copyfile(ROOT/'implementation/backlog/deliveries/A052-harvester/build.py',D/'build.py')
print(f"Prepared {len(files)} diagnostic candidates; expected {expected}; body palette keys={body_keys}")
