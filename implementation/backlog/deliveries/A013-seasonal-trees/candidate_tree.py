"""Measure seasonal tree bounds and trunk anchor; retain the mandatory master scale."""
from pathlib import Path
import json,sys,math
from PIL import Image
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3];sys.path.insert(0,str(ROOT/'tools'))
from import_art import render_source
import palette
stem=sys.argv[1];source=HERE/f'raw/{stem}.png';im=Image.open(source).convert('RGBA');alpha=im.getchannel('A').point(lambda a:255 if a>=128 else 0);lo,hi=im.getchannel('A').getextrema();assert lo==0 and hi>=128, 'Real transparent margins and visible object alpha required'
x,y,xe,ye=alpha.getbbox()
# The roots are intentionally asymmetric. Centre the accepted crop on the
# complete crown bounding box, not on the farthest pair of spreading roots.
# The full measured box fits the source and preserves the accepted master anchor.
left=x;width=xe-x;height=ye-y;scale=.03700440528634361;centre=(x+xe)/2
name=stem.rsplit('-r',1)[0];entry={'id':'A013/'+name,'source':source.relative_to(ROOT).as_posix(),'crop_xywh':[left,y,width,height],'content_scale':scale,'content_anchor_xy':[round(width*scale)//2,round(height*scale)],'alpha_threshold':128,'palette':'tools/palette.py:COLOURS','canvas_wh':[40,48],'pivot_xy':[20,44]}
native=render_source(entry);native.save(HERE/f'preview/{stem}-native.png');native.resize((240,288),Image.Resampling.NEAREST).save(HERE/f'preview/{stem}-6x.png')
cut=alpha.crop((left,y,left+width,ye)).resize((round(width*scale),round(height*scale)),Image.Resampling.NEAREST);b=cut.getbbox();ax,ay=entry['content_anchor_xy'];placed=[b[0]+20-ax,b[1]+44-ay,b[2]+20-ax,b[3]+44-ay]
(HERE/f'preview/{stem}-recipe.json').write_text(json.dumps({'anim':name,'stem':stem,'importer':entry,'unclipped_bounds':placed},indent=2)+'\n')
print(json.dumps({'stem':stem,'source_size':im.size,'bounds':native.getbbox(),'unclipped_bounds':placed,'crop':entry['crop_xywh'],'trunk_source_centre':centre}))
