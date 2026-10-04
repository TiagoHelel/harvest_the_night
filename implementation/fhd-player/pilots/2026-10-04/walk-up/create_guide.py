"""Draw a rear-view anatomy guide only; ImageGen authors the character poses."""
from pathlib import Path
from PIL import Image, ImageDraw

ROOT=Path(__file__).resolve().parent
im=Image.new('RGB',(1536,1024),'#faf9f4')
d=ImageDraw.Draw(im)
# Up-screen is forward. Right leg stays at screen-right hip in back view.
a=[(350,403,418),(352,416,431),(366,440,455),(374,452,469),
   (374,450,468),(376,435,452),(366,415,431),(351,400,415)]
labels=['Right contact ahead','Right support / left toe-off','Left passing',
        'Left reaches ahead','Left contact ahead','Left support / right toe-off',
        'Right passing','Right reaches ahead']
for i in range(8):
    x,y=i%4*384,i//4*512
    d.text((x+12,y+12),f'{i+1}: {labels[i]}',fill='#222222')
    d.ellipse((x+150,y+60,x+234,y+140),fill='#cccccc')
    d.rectangle((x+151,y+150,x+233,y+305),fill='#dddddd')
    for hip,p,color in [(213,a[i],'#e73438'),(172,a[(i+4)%8],'#009eb7')]:
        ky,ay,sy=p
        d.line([(x+hip,y+305),(x+hip,y+ky),(x+hip,y+ay)],fill=color,width=18)
        d.ellipse((x+hip-10,y+ky-10,x+hip+10,y+ky+10),fill=color)
        d.rounded_rectangle((x+hip-15,y+ay-6,x+hip+15,y+sy),radius=4,fill=color)
    d.line((x+142,y+478,x+242,y+478),fill='#aaaaaa')
im.save(ROOT/'leg-ownership-guide.png')
