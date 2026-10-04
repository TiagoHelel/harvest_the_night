"""Lossless cutting and atlas packing of two ImageGen four-frame transitions."""
from pathlib import Path
from PIL import Image
import json

ROOT=Path(__file__).resolve().parent
SOURCE=ROOT.parents[4]/'assets/art_source/player-fhd/pilots/2026-10-04/walk-down-right'
masters=[Image.open(SOURCE/name).convert('RGBA') for name in ('transition-a-r1.png','transition-b-r2.png')]
assert masters[0].size==masters[1].size, [im.size for im in masters]
cell_width,cell_height=masters[0].width//2,masters[0].height//2
out=Image.new('RGBA',(cell_width*4,cell_height*2))
report=[]
for half,im in enumerate(masters):
    name='a' if half==0 else 'b'
    for j in range(4):
        cell=im.crop((j%2*cell_width,j//2*cell_height,(j%2+1)*cell_width,(j//2+1)*cell_height))
        mask=cell.getchannel('A').point(lambda a:255 if a>=128 else 0)
        box=mask.getbbox()
        assert box is not None
        i=half*4+j
        out.paste(cell,(i%4*cell_width,i//4*cell_height))
        report.append({'frame':i+1,'half':name,'cell':j+1,'bbox':box})
out.save(SOURCE/'tracking-r4.png')
(ROOT/'transition-packing.json').write_text(json.dumps({'operation':'lossless crop and pack; no painting, reflection or rescaling','cells':report},indent=2),encoding='utf-8')
print(SOURCE/'tracking-r4.png')
