"""Anatomical joint instructions only; never production sprite artwork.

Applies sprite_generator/fight/create_walk_guides.py's fixed limb ownership.
"""
from pathlib import Path
import json
from PIL import Image,ImageDraw,ImageFont
HERE=Path(__file__).resolve().parent

# Hip anchors never swap. Native coordinates, continuous clockwise phases.
PHASES=[
 {'phase':'near contact','near':[(36,46),(30,57),(25,68)],'far':[(44,46),(48,59),(51,72)]},
 {'phase':'near recoil','near':[(36,46),(31,59),(30,71)],'far':[(44,46),(44,56),(49,66)]},
 {'phase':'far passing','near':[(36,46),(37,60),(37,72)],'far':[(44,46),(38,54),(43,62)]},
 {'phase':'far reaching','near':[(36,46),(40,58),(43,71)],'far':[(44,46),(34,55),(30,64)]},
 {'phase':'far contact','near':[(36,46),(48,59),(51,72)],'far':[(44,46),(30,57),(25,68)]},
 {'phase':'far recoil','near':[(36,46),(44,56),(49,66)],'far':[(44,46),(31,59),(30,71)]},
 {'phase':'near passing','near':[(36,46),(38,54),(43,62)],'far':[(44,46),(37,60),(37,72)]},
 {'phase':'near reaching','near':[(36,46),(34,55),(30,64)],'far':[(44,46),(40,58),(43,71)]},
]

def main():
    im=Image.new('RGB',(1920,960),'#20292c');d=ImageDraw.Draw(im)
    f=ImageFont.truetype('C:/Windows/Fonts/consola.ttf',20)
    for i,p in enumerate(PHASES):
        ox,oy=i%4*480,i//4*480
        d.text((ox+15,oy+12),f'{i+1}: {p["phase"]}',font=f,fill='white')
        d.line([(ox+240,oy+150),(ox+240,oy+276)],fill='#999999',width=8)
        d.line([(ox+216,oy+276),(ox+264,oy+276)],fill='#bbbbbb',width=8)
        d.line([(ox+100,oy+432),(ox+380,oy+432)],fill='#556566',width=2)
        for key,color in [('far','#ff61c3'),('near','#40e5ed')]:
            points=[(ox+x*6,oy+y*6) for x,y in p[key]]
            d.line(points,fill=color,width=10,joint='curve')
            for x,y in points:d.ellipse((x-7,y-7,x+7,y+7),fill=color)
    im.save(HERE/'up-left-leg-ownership-guide.png')
    (HERE/'up-left-joint-contract.json').write_text(json.dumps(PHASES,indent=2)+'\n')
    print('Eight anatomical phase instructions; cyan near LEFT / pink far RIGHT throughout. Not runtime artwork.')

if __name__=='__main__':main()
