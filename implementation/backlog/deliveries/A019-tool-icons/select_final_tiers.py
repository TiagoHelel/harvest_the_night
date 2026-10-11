"""Register inspected tier sources with one common reduction scale per tool."""
from pathlib import Path
import json
HERE=Path(__file__).resolve().parent
groups={'hoe':['basic','iron','gold'],'can':['basic','iron','gold'],'axe':['basic','iron','gold'],'pickaxe':['basic','iron','gold'],'rod':['bamboo','fibre','iron']}
recipes=[]
for tool,tiers in groups.items():
    pairs=[]
    for tier in tiers:
        stem=tool+'_'+tier+('-r2' if tool=='can' and tier in ['basic','gold'] else '-r1')
        pairs.append(json.loads((HERE/f'preview/{stem}-recipes.json').read_text()))
    largest=max(max(pair[0]['importer']['crop_xywh'][2:]) for pair in pairs)
    for pair in pairs:
        for r in pair:
            e=r['importer'];size=e['canvas_wh'][0];s=(14 if size==16 else 8)/largest;w,h=e['crop_xywh'][2:];e.update(content_scale=s,content_anchor_xy=[round(w*s)//2,round(h*s)//2]);recipes.append(r)
        stem=pair[0]['stem'];p=HERE/f'raw/{stem}.call.json';c=json.loads(p.read_text());c.update(decision='accepted',inspection='Both native cuts and common scale tier grid inspected. Owner final approval pending.');p.write_text(json.dumps(c,indent=2)+'\n');(HERE/f'preview/{stem}-recipes.json').write_text(json.dumps(pair,indent=2)+'\n')
(HERE/'recipes.json').write_text(json.dumps(recipes,indent=2)+'\n')
print(json.dumps({'frames':len(recipes)}))
