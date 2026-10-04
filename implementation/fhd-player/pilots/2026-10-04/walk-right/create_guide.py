"""Right-facing walk anatomy only; ImageGen supplies all character artwork."""
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent
canvas = Image.new('RGB', (1536,1024), '#faf9f4')
d = ImageDraw.Draw(canvas)
# Fixed hip ownership. Red is the near/anatomical right leg; cyan is far/left.
# Tuples are knee x/y, ankle x/y, sole y. X increases toward travel direction.
near = [(224,374,252,453,470), (214,380,229,453,470),
        (196,383,194,453,470), (177,375,156,453,470),
        (163,367,133,445,462), (151,360,132,416,433),
        (218,355,177,416,433), (235,373,240,435,452)]
labels = ['Near contact', 'Near support / far toe-off', 'Far passing', 'Far reaching',
          'Far contact', 'Far support / near toe-off', 'Near passing', 'Near reaching']
for i in range(8):
    x,y = i%4*384,i//4*512
    d.text((x+12,y+12),f'{i+1}: {labels[i]}',fill='#222222')
    d.ellipse((x+157,y+65,x+233,y+140),fill='#cccccc')
    d.polygon([(x+231,y+100),(x+248,y+110),(x+231,y+122)],fill='#999999')
    d.rectangle((x+157,y+151,x+226,y+300),fill='#dddddd')
    def leg(p, hip, color):
        kx,ky,ax,ay,sy=p
        d.line([(x+hip,y+300),(x+kx,y+ky),(x+ax,y+ay)],fill=color,width=16)
        d.ellipse((x+kx-8,y+ky-8,x+kx+8,y+ky+8),fill=color)
        d.polygon([(x+ax-8,y+ay-4),(x+ax+11,y+ay-4),(x+ax+26,y+sy),(x+ax-8,y+sy)],fill=color)
    leg(near[(i+4)%8],184,'#009eb7')
    leg(near[i],202,'#e73438')
    d.line((x+94,y+474,x+296,y+474),fill='#aaaaaa')
canvas.save(ROOT/'leg-ownership-guide.png')
