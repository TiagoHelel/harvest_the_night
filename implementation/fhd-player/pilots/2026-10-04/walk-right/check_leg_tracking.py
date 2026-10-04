"""Measure colored lower-shin travel; an aid to, not a substitute for, review."""
from pathlib import Path
import colorsys
import json
from PIL import Image

ROOT=Path(__file__).resolve().parent
SOURCE=ROOT.parents[4]/'assets/art_source/player-fhd/pilots/2026-10-04/walk-right/tracking-r1.png'
im=Image.open(SOURCE).convert('RGBA')
rows=[]
for i in range(8):
    col,row=i%4,i//4
    cell=im.crop((col*384,row*512,(col+1)*384,(row+1)*512))
    cell.putalpha(cell.getchannel('A').point(lambda a:255 if a>=128 else 0))
    b=cell.getbbox()
    hb=cell.crop((0,b[1],384,b[1]+100)).getbbox()
    anchor=(hb[0]+hb[2])/2
    points={'near_red':[],'far_cyan':[]}
    for y in range(b[1]+round((b[3]-b[1])*.53),b[3]):
        for x in range(b[0],b[2]):
            r,g,blue,a=cell.getpixel((x,y))
            if not a:continue
            h,s,v=colorsys.rgb_to_hsv(r/255,g/255,blue/255)
            if s<.65 or v<.35:continue
            if (h<.025 or h>.97) and r>g*2.4 and r>blue*1.8:points['near_red'].append((x,y))
            if .46<h<.58:points['far_cyan'].append((x,y))
    result={'frame':i+1}
    for name,pts in points.items():
        assert pts, (i,name)
        miny,maxy=min(y for x,y in pts),max(y for x,y in pts)
        lower=[x for x,y in pts if y>=miny+(maxy-miny)*.8]
        result[name+'_lower_shin_x_from_hat_center']=round(sum(lower)/len(lower)-anchor,2)
    rows.append(result)
key='near_red_lower_shin_x_from_hat_center'
other='far_cyan_lower_shin_x_from_hat_center'
# Frame 1 versus opposite contact 5 must reverse leg positions.
assert rows[0][key]>rows[0][other]+25
assert rows[4][key]<rows[4][other]-25
for name in (key,other):
    assert min(row[name] for row in rows)<-20
    assert max(row[name] for row in rows)>20
report={'check':'opposite contacts and both shins travel before/behind torso',
        'result':'PASS','measurements':rows,
        'limitation':'Color segmentation measures lower-shin motion, not boot material or complete anatomical correctness. Boots are not consistently tracking-colored in the generated source.'}
(ROOT/'leg-tracking-check.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print(json.dumps(report,indent=2))
