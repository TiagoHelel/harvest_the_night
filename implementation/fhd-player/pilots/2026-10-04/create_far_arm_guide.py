"""Abstract arm trajectory diagram; not farmer artwork or sprite repaint."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
ROOT=Path(__file__).resolve().parent
SOURCE=ROOT.parents[3]/'assets/art_source/player-fhd/pilots/2026-10-04/walk-up-right'
points=[((31,39),(34,41)),((31,39),(32,43)),((32,40),(30,45)),((31,41),(28,47)),
        ((31,42),(27,49)),((31,41),(28,47)),((32,40),(30,45)),((31,39),(32,43))]
sheet=Image.new('RGB',(1920,960),'#20292c')
d=ImageDraw.Draw(sheet)
f=ImageFont.truetype('C:/Windows/Fonts/consola.ttf',19)
for i,(elbow,hand) in enumerate(points):
    x,y=(i%4)*480,(i//4)*480
    def p(point): return (x+point[0]*6,y+point[1]*6)
    d.ellipse((x+28*6,y+8*6,x+56*6,y+29*6),fill='#61676c')
    d.rectangle((x+34*6,y+30*6,x+48*6,y+49*6),fill='#61676c')
    d.line([p((34,32)),p(elbow),p(hand)],fill='#51e2db',width=16)
    for point in [(34,32),elbow,hand]:
        px,py=p(point); d.ellipse((px-9,py-9,px+9,py+9),fill='#faf6de')
    d.text((x+28,y+405),f'{i+1}: FIXED SHOULDER / ELBOW / HAND',font=f,fill='#e9e3cf')
    d.text((x+28,y+432),f'Hand {hand}; keep hand outside torso',font=f,fill='#51e2db')
sheet.save(SOURCE/'far-arm-trajectory-guide.png')
