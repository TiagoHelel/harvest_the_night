"""Tool-family provenance, tier comparison and review compositions only."""
from PIL import Image,ImageDraw
from static_checks import enrich

def inspect(here,root,frames,recipes,outputs,contract,checks,add,night):
    html=enrich(here,root,frames,recipes,outputs,contract,checks,add,night)
    tools={'hoe':['basic','iron','gold'],'can':['basic','iron','gold'],'axe':['basic','iron','gold'],'pickaxe':['basic','iron','gold'],'rod':['bamboo','fibre','iron']}
    scales=True;distinct=True;parts=[]
    grid=Image.new('RGBA',(3*110+92,5*88+30),(26,24,48,255));d=ImageDraw.Draw(grid)
    d.text((4,4),'Native16 and10 / basic-middle-best',fill=(232,224,207))
    for row,(tool,tiers) in enumerate(tools.items()):
        d.text((4,32+row*88),tool,fill=(232,224,207))
        for prefix in ['icon','hud']:
            group=[r for r in recipes if r['anim'] in [prefix+'_'+tool+'_'+t for t in tiers]]
            scales &= len(group)==3 and len({r['importer']['content_scale'] for r in group})==1
        small=[frames.get('hud_'+tool+'_'+t) for t in tiers]
        distinct &= all(f is not None for f in small)
        if all(f is not None for f in small):
            for a in range(3):
                for b in range(a+1,3):distinct &= sum(x!=y for x,y in zip(small[a].getdata(),small[b].getdata()))>=6
        for col,tier in enumerate(tiers):
            x=92+col*110;y=30+row*88;d.text((x,y),tier,fill=(232,224,207))
            for prefix,dy in [('icon',18),('hud',52)]:
                f=frames.get(prefix+'_'+tool+'_'+tier)
                if f:
                    grid.alpha_composite(f,(x,y+dy));grid.alpha_composite(f.resize((f.width*2,f.height*2),Image.Resampling.NEAREST),(x+28,y+dy))
    add('preview/tool-tier-grid.png',grid)
    checks.update(one_scale_per_tool=bool(scales),tiers_distinct=bool(distinct))
    contract['tier_ramps']={'basic':['ink_soft','stone_dark','stone'],'iron':['stone_dark','stone','stone_light'],'gold':['gold_dark','gold','gold_light'],'bamboo':['gold_dark','bone_dark','gold_light'],'fibre':['roof_dark','roof','roof_light']}
    html+='<section><h2>Five tools / three tiers / both cuts</h2><img src="preview/tool-tier-grid.png"><br><img src="preview/tool-tier-grid.png" width="844"></section>'
    for tier_index in range(3):
        hud=Image.new('RGBA',(5*28+12,30),(26,24,48,255));workshop=Image.new('RGBA',(220,5*28+8),(26,24,48,255));wd=ImageDraw.Draw(workshop)
        for i,(tool,tiers) in enumerate(tools.items()):
            name=tool+'_'+tiers[tier_index];f=frames.get('hud_'+name);large=frames.get('icon_'+name)
            if f:hud.alpha_composite(f,(6+i*28,10))
            if large:workshop.alpha_composite(large,(8,8+i*28))
            wd.rectangle((36,12+i*28,206,20+i*28),fill=(46,42,78,255))
        add(f'preview/tier-{tier_index}-hud.png',hud);add(f'preview/tier-{tier_index}-workshop.png',workshop)
        html+=f'<section><h2>Tier{tier_index}: HUD and workshop</h2><img src="preview/tier-{tier_index}-hud.png"><br><img src="preview/tier-{tier_index}-hud.png" width="608"><br><img src="preview/tier-{tier_index}-workshop.png"></section>'
    resources=Image.new('RGBA',(240,64),(26,24,48,255));rd=ImageDraw.Draw(resources)
    for i,name in enumerate(['wood','iron','money','fish']):
        icon=Image.open(root/f'sprites/ui/icon_{name}.png').convert('RGBA');resources.alpha_composite(icon,(4+i*32,16));rd.text((4+i*32,36),name,fill=(232,224,207))
    farmer=Image.open(here/'preview/farmer.png').convert('RGBA');resources.alpha_composite(farmer,(176,12));rd.line((160,48,232,48),fill=(105,136,120,255))
    add('preview/resource-and-farmer-scale.png',resources);add('preview/tool-tier-grid-world-night.png',night(grid))
    html+='<section><h2>Current resources and farmer / feet on16px grid</h2><img src="preview/resource-and-farmer-scale.png"><br><img src="preview/resource-and-farmer-scale.png" width="960"><h2>World relight, for reference only: HUD is not relit</h2><img src="preview/tool-tier-grid-world-night.png" width="844"></section>'
    return html
