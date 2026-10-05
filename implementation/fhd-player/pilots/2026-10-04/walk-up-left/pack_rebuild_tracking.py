"""Pack newly generated diagnostic poses without repainting or reflecting art."""
from pathlib import Path
import json
import statistics
from PIL import Image

ROOT = Path(__file__).resolve().parent
SOURCE = ROOT.parents[4] / 'assets/art_source/player-fhd/pilots/2026-10-04/walk-up-left'


def clean(im):
    im = im.convert('RGBA')
    im.putalpha(im.getchannel('A').point(lambda a:255 if a >= 128 else 0))
    return im


source = clean(Image.open(SOURCE/'rebuild-tracking-r5.png'))
cols = [round(i*source.width/4) for i in range(5)]
blank = [y for y in range(round(source.height*.4),round(source.height*.6))
         if source.getchannel('A').crop((0,y,source.width,y+1)).getbbox() is None]
assert blank, 'No empty source row gutter; inspect before cutting.'
row = round(statistics.median(blank))
rows = [0,row,source.height]
cells = [source.crop((cols[c],rows[r],cols[c+1],rows[r+1])) for r in range(2) for c in range(4)]
scale = 64 / statistics.median(c.getbbox()[3]-c.getbbox()[1] for c in cells)
pair = clean(Image.open(SOURCE/'rebuild-contacts-r6.png'))
mid = round(pair.width/2)
pair_cells = [pair.crop((0,0,mid,pair.height)),pair.crop((mid,0,pair.width,pair.height))]


def head_width(cell):
    b = cell.getbbox()
    h = cell.crop((0,b[1],cell.width,b[1]+round((b[3]-b[1])*.22))).getbbox()
    return h[2]-h[0]


calibration = statistics.median(head_width(c) for c in cells[:4]) / statistics.median(head_width(c) for c in pair_cells)
cells[4:6] = pair_cells
scales = [scale]*4 + [scale*calibration]*2 + [scale]*2
atlas = Image.new('RGBA',(320,160))
metrics = []
for i,(cell,sampling) in enumerate(zip(cells,scales)):
    b = cell.getbbox()
    head = cell.crop((0,b[1],cell.width,b[1]+round((b[3]-b[1])*.22))).getbbox()
    center = (head[0]+head[2])/2
    small = cell.resize((round(cell.width*sampling),round(cell.height*sampling)),Image.Resampling.NEAREST)
    frame = Image.new('RGBA',(80,80))
    frame.alpha_composite(small,(round(40-center*sampling),8-small.getbbox()[1]))
    fb = frame.getbbox()
    assert fb[0]>0 and fb[2]<80 and fb[3]<78, (i,fb)
    atlas.alpha_composite(frame,((i%4)*80,(i//4)*80))
    metrics.append({'phase':i+1,'bbox':fb,'height':fb[3]-fb[1]})
atlas.save(SOURCE/'rebuild-tracking-r6-packed.png')
atlas.resize((1920,960),Image.Resampling.NEAREST).save(SOURCE/'rebuild-tracking-r6-reference.png')
(ROOT/'rebuild-tracking-packing.json').write_text(json.dumps({'source_row_cut':row,'common_scale':scale,
    'pair_reference_calibration':calibration,'pose_sources':['rebuild-tracking-r5.png']*4 +
    ['rebuild-contacts-r6.png']*2 + ['rebuild-tracking-r5.png']*2,
    'canvas':[80,80],'metrics':metrics,'operations':'alpha threshold, uniform whole-source nearest sampling, packing only'},
    indent=2)+'\n',encoding='utf-8')
print(json.dumps(metrics,indent=2))
