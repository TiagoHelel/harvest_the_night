"""Track lower-leg displacement in diagonal construction colors, not anatomy proof."""
from pathlib import Path
import colorsys
import json
from PIL import Image

ROOT=Path(__file__).resolve().parent
SOURCE=ROOT.parents[4]/'assets/art_source/player-fhd/pilots/2026-10-04/walk-down-right/tracking-r4.png'
im=Image.open(SOURCE).convert('RGBA')
width,height=im.width//4,im.height//2
measurements=[]
for i in range(8):
    cell=im.crop((i%4*width,i//4*height,(i%4+1)*width,(i//4+1)*height))
    cell.putalpha(cell.getchannel('A').point(lambda a:255 if a>=128 else 0))
    b=cell.getbbox()
    hb=cell.crop((0,b[1],width,b[1]+round(height*.195))).getbbox()
    anchor=(hb[0]+hb[2])/2
    points={'near_red':[],'far_cyan':[]}
    for y in range(b[1]+round((b[3]-b[1])*.53),b[3]):
        for x in range(b[0],b[2]):
            r,g,blue,a=cell.getpixel((x,y))
            if not a:continue
            h,s,v=colorsys.rgb_to_hsv(r/255,g/255,blue/255)
            if s<.65 or v<.25:continue
            if (h<.025 or h>.97) and r>g*2.4 and r>blue*1.8:points['near_red'].append((x,y))
            if .46<h<.58:points['far_cyan'].append((x,y))
    result={'frame':i+1}
    for name,pts in points.items():
        assert pts,(i,name)
        miny,maxy=min(y for x,y in pts),max(y for x,y in pts)
        lower=[(x,y) for x,y in pts if y>=miny+(maxy-miny)*.8]
        result[name]=[round(sum(x for x,y in lower)/len(lower)-anchor,2),
                      round(sum(y for x,y in lower)/len(lower)-b[1],2)]
    measurements.append(result)
checks={}
for name,sign in [('near_red',1),('far_cyan',-1)]:
    a,b=measurements[0][name],measurements[4][name]
    delta=[round(sign*(a[j]-b[j]),2) for j in range(2)]
    checks[name]={'contact_displacement_forward_xy':delta,
                  'moves_right_and_down':delta[0]>10 and delta[1]>10}
passing={'far_boot_lifted_on_frame3':measurements[2]['far_cyan'][1]<measurements[2]['near_red'][1]-25,
         'near_boot_lifted_on_frame7':measurements[6]['near_red'][1]<measurements[6]['far_cyan'][1]-25}
contact_separation=(measurements[4]['far_cyan'][0]-measurements[0]['near_red'][0])*384/width
passing['opposite_forward_boot_uses_other_side']=contact_separation>25
report={'opposite_forward_boot_x_separation_at_384_cell_scale':round(contact_separation,2),'check':'opposite diagonal contacts and both recovery phases',
        'result':'PASS' if all(c['moves_right_and_down'] for c in checks.values()) and all(passing.values()) else 'REVIEW',
        'checks':checks,'passing_checks':passing,'measurements':measurements,
        'limitation':'Lower-leg color displacement assists visual review; does not prove joint anatomy, planted-foot timing or restored-material fidelity.'}
(ROOT/'leg-tracking-check.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print(json.dumps(report,indent=2))
