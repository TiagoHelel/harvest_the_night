"""Measure construction thigh/cuff displacement; assists visual review only."""
from pathlib import Path
import json,colorsys
from PIL import Image
ROOT=Path(__file__).resolve().parent
def largest_component(points):
 remaining=set(points);largest=[]
 while remaining:
  seed=remaining.pop();queue=[seed];component=[]
  while queue:
   x,y=queue.pop();component.append((x,y))
   for dx,dy in [(-1,-1),(0,-1),(1,-1),(-1,0),(1,0),(-1,1),(0,1),(1,1)]:
    neighbor=(x+dx,y+dy)
    if neighbor in remaining:remaining.remove(neighbor);queue.append(neighbor)
  if len(component)>len(largest):largest=component
 return largest
im=Image.open(ROOT.parents[4]/'assets/art_source/player-fhd/pilots/2026-10-04/walk-up-right/tracking-r1.png').convert('RGBA');im.putalpha(im.getchannel('A').point(lambda a:255 if a>=128 else 0));w,h=im.width//4,im.height//2;measure=[]
for i in range(8):
 cell=im.crop((i%4*w,i//4*h,(i%4+1)*w,(i//4+1)*h));b=cell.getbbox();hat=cell.crop((0,b[1],w,b[1]+round((b[3]-b[1])*.22))).getbbox();anchor=(hat[0]+hat[2])/2;colors={'near_red':[],'far_cyan':[]}
 for y in range(b[1]+round((b[3]-b[1])*.52),b[3]):
  for x in range(b[0],b[2]):
   r,g,blue,a=cell.getpixel((x,y));hu,s,v=colorsys.rgb_to_hsv(r/255,g/255,blue/255)
   if not a or s<.65 or v<.25:continue
   if (hu<.025 or hu>.97) and r>g*2.4 and r>blue*1.8:colors['near_red'].append((x,y))
   if .46<hu<.58:colors['far_cyan'].append((x,y))
 out={'frame':i+1}
 for name,pts in colors.items():
  pts=largest_component(pts)
  assert len(pts)>100,(i+1,name,len(pts))
  low,high=min(y for x,y in pts),max(y for x,y in pts);bottom=[(x,y) for x,y in pts if y>=low+(high-low)*.8]
  out[name]=[round(sum(x for x,y in bottom)/len(bottom)-anchor,2),round(sum(y for x,y in bottom)/len(bottom)-b[1],2)]
 measure.append(out)
checks={}
for name,first,second in [('near_red',0,4),('far_cyan',4,0)]:
 delta=[round(measure[first][name][j]-measure[second][name][j],2) for j in range(2)]
 checks[name]={'forward_minus_rear_contact_xy':delta,'rightward_forward_contact':delta[0]>10,'upward_forward_contact':delta[1]<-10}
report={'check':'same construction chain at opposite contacts','contact_checks':checks,'measurements':measure,'limitations':['Largest 8-connected construction-color component excludes isolated reddish boot-edge pixels that corrupted the initial bounding-extents estimate. Colored cuff displacement cannot prove hip attachment, sole contact or anatomy. Both boots may have brown leather, so this measures trouser cuffs rather than soles.','Anatomy, passing knees, arm counter-swing and material preservation require visual comparison.']}
(ROOT/'leg-tracking-check.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8');print(json.dumps(checks))
