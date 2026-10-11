"""Render the final common-scale tier recipes for internal pixel-size inspection."""
from pathlib import Path
import json,sys
from PIL import Image,ImageDraw
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3];sys.path.insert(0,str(ROOT/'tools'))
from import_art import render_source
tools={'hoe':['basic','iron','gold'],'can':['basic','iron','gold'],'axe':['basic','iron','gold'],'pickaxe':['basic','iron','gold'],'rod':['bamboo','fibre','iron']}
sheet=Image.new('RGBA',(720,5*132),(26,24,48,255));d=ImageDraw.Draw(sheet)
for row,(tool,tiers)in enumerate(tools.items()):
    for col,tier in enumerate(tiers):
        name=tool+'_'+tier;rs=[r for r in json.loads((HERE/'recipes.json').read_text()) if r['asset']==name];x=col*240;y=row*132;d.text((x+6,y+4),name,fill=(232,224,207))
        for i,r in enumerate(rs):
            f=render_source(r['importer']);xx=x+6+i*112;sheet.alpha_composite(f,(xx,y+24));sheet.alpha_composite(f.resize((f.width*4,f.height*4),Image.Resampling.NEAREST),(xx,y+48));d.text((xx,y+116),str(f.getbbox()),fill=(184,174,154))
sheet.save(HERE/'preview/common-scale-tier-inspection.png')
