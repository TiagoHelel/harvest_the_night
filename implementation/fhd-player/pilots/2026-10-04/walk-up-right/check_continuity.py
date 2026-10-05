"""Track colored boot positions through time; an aid, never an anatomy approval."""
from pathlib import Path
import colorsys, json, math, statistics
from PIL import Image, ImageDraw, ImageFont

ROOT=Path(__file__).resolve().parent
SOURCE=ROOT.parents[4]/'assets/art_source/player-fhd/pilots/2026-10-04/walk-up-right/tracking-r3.png'
im=Image.open(SOURCE).convert('RGBA')
im.putalpha(im.getchannel('A').point(lambda a:255 if a>=128 else 0))
xs=[round(i*im.width/4) for i in range(5)]
ys=[0,round(im.height/2),im.height]
cells=[im.crop((xs[c],ys[r],xs[c+1],ys[r+1])) for r in range(2) for c in range(4)]
scale=64/statistics.median(c.getbbox()[3]-c.getbbox()[1] for c in cells)
measure=[]
for i,cell in enumerate(cells):
    b=cell.getbbox()
    hb=cell.crop((0,b[1],cell.width,b[1]+100)).getbbox()
    center=(hb[0]+hb[2])/2
    colors={'right_red':[], 'left_cyan':[]}
    for y in range(b[1]+round((b[3]-b[1])*.57),b[3]):
        for x in range(b[0],b[2]):
            r,g,blue,a=cell.getpixel((x,y))
            h,s,v=colorsys.rgb_to_hsv(r/255,g/255,blue/255)
            if not a or s<.6 or v<.28:continue
            if (h<.035 or h>.96) and r>g*3 and r>blue*3:
                colors['right_red'].append((x,y))
            if .46<h<.58 and blue>r*1.8 and g>r*1.8:
                colors['left_cyan'].append((x,y))
    record={'frame':i+1}
    for name,points in colors.items():
        assert len(points)>150,(i+1,name,'Missing diagnostic leg color')
        bottom=max(y for x,y in points)
        # Lowest7% of visible body height isolates each boot rather than its cuff.
        band=[(x,y) for x,y in points if y>=bottom-(b[3]-b[1])*.07]
        record[name]=[round((statistics.mean(x for x,y in band)-center)*scale,3),
                      round((statistics.mean(y for x,y in band)-b[1])*scale,3)]
    measure.append(record)
checks={}
for name,stance in [('right_red',[0,1,2,3,4]),('left_cyan',[4,5,6,7,0])]:
    points=[m[name] for m in measure]
    steps=[round(math.dist(points[i],points[(i+1)%8]),3) for i in range(8)]
    support_dx=[round(points[b][0]-points[a][0],3) for a,b in zip(stance,stance[1:])]
    checks[name]={'cycle_displacements_native_px':steps,'largest_step_native_px':max(steps),
                  'support_x_changes':support_dx,
                  'support_moves_backward_with_1px_tolerance':all(dx<=1 for dx in support_dx)}
separation=[round(abs(m['right_red'][0]-m['left_cyan'][0]),3) for m in measure]
checks['horizontal_boot_separation_by_frame']=separation
checks['passing3_narrower_than_contacts']=separation[2]<min(separation[0],separation[4])
checks['passing7_narrower_than_contacts']=separation[6]<min(separation[0],separation[4])
report={'source':SOURCE.name,'status':'rejected construction study; not a selected motion proof','common_scale':scale,'measurements':measure,'checks':checks,
        'limitations':['Colored boot centroids estimate trajectories; occlusion and perspective can bias them.',
                      'These numbers cannot prove hip attachment or anatomical correctness.',
                      'Inspect actual 10fps and slow playback, then obtain user approval.']}
(ROOT/'continuity-check-rejected-r3.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
plot=Image.new('RGB',(760,340),'#20292c');d=ImageDraw.Draw(plot)
f=ImageFont.truetype('C:/Windows/Fonts/consola.ttf',16)
d.text((15,12),'CONSTRUCTION BOOT PATHS / NATIVE PX / 1 -> 8 -> 1',font=f,fill='#e9e3cf')
for name,color,ox in [('right_red','#f03946',180),('left_cyan','#00b9d6',550)]:
    p=[(ox+m[name][0]*7,55+(m[name][1]-40)*10) for m in measure]
    d.line(p+[p[0]],fill=color,width=2)
    for i,(x,y) in enumerate(p):
        d.ellipse((x-4,y-4,x+4,y+4),fill=color)
        d.text((x+6,y-12),str(i+1),font=f,fill='#e9e3cf')
    d.text((ox-80,310),name,font=f,fill=color)
plot.save(ROOT/'continuity-paths-rejected-r3.png')
print(json.dumps(checks,indent=2))
