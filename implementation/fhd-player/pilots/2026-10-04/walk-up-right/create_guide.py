"""Schematic fixed hips and northeast gait phases; never paints farmer art."""
from pathlib import Path
from PIL import Image,ImageDraw
ROOT=Path(__file__).resolve().parent
im=Image.new('RGB',(1536,1024),'#faf9f4');d=ImageDraw.Draw(im)
poses=[((225,374),(236,435)),((224,382),(232,442)),((217,388),(219,456)),((203,390),(198,474)),((197,392),(184,482)),((201,383),(191,465)),((219,360),(211,413)),((226,368),(231,421))]
labels=['Near RIGHT contact','Far toe-off','Far LEFT recovery','Far reaches forward','Far LEFT contact','Near toe-off','Near RIGHT recovery','Near reaches forward']
for i in range(8):
 ox,oy=i%4*384,i//4*512
 d.text((ox+10,oy+10),f'{i+1}: {labels[i]}',fill='#222222')
 d.ellipse((ox+145,oy+55,ox+239,oy+135),fill='#cccccc')
 d.polygon([(ox+150,oy+142),(ox+231,oy+152),(ox+228,oy+314),(ox+158,oy+300)],fill='#dddddd')
 near_hands=[(224,333),(231,323),(247,302),(268,260),(285,227),(274,252),(247,302),(232,319)]
 nx,ny=near_hands[i];fx,fy=near_hands[(i+4)%8];fx-=73;fy-=8
 for sx,sy,hx,hy in [(154,177,fx,fy),(238,184,nx,ny)]:
  d.line([(ox+sx,oy+sy),(ox+(sx+hx)//2,oy+(sy+hy)//2+14),(ox+hx,oy+hy)],fill='#888888',width=14)
  d.ellipse((ox+hx-8,oy+hy-8,ox+hx+8,oy+hy+8),fill='#eaa36b')
 for phase,offset,hip,color in [((i+4)%8,(-34,-8),(178,298),'#009eb7'),(i,(0,0),(212,306),'#e73438')]:
  knee,ankle=poses[phase];kx,ky=knee[0]+offset[0],knee[1]+offset[1];ax,ay=ankle[0]+offset[0],ankle[1]+offset[1]
  d.line([(ox+hip[0],oy+hip[1]),(ox+kx,oy+ky),(ox+ax,oy+ay)],fill=color,width=15)
  d.ellipse((ox+hip[0]-10,oy+hip[1]-10,ox+hip[0]+10,oy+hip[1]+10),fill=color)
  d.ellipse((ox+kx-7,oy+ky-7,ox+kx+7,oy+ky+7),fill=color)
  d.polygon([(ox+ax-10,oy+ay),(ox+ax+6,oy+ay+6),(ox+ax+23,oy+ay-12),(ox+ax+7,oy+ay-19)],fill=color)
 d.text((ox+121,oy+319),'L hip',fill='#009eb7');d.text((ox+222,oy+330),'R hip',fill='#e73438')
 d.line((ox+288,oy+258,ox+331,oy+215),fill='#555555',width=4);d.text((ox+262,oy+277),'Forward: up-right',fill='#555555')
im.save(ROOT/'leg-ownership-guide.png')
for name,seq in [('transition-a-guide.png',[1,2,3,4]),('transition-b-guide.png',[5,6,7,8])]:
 out=Image.new('RGB',(768,1024),'#faf9f4')
 for j,i in enumerate(seq):
  x,y=(i-1)%4*384,(i-1)//4*512;out.paste(im.crop((x,y,x+384,y+512)),(j%2*384,j//2*512))
 out.save(ROOT/name)
contacts=Image.new('RGB',(768,512),'#faf9f4')
for j,i in enumerate([0,4]):
 x,y=i%4*384,i//4*512;contacts.paste(im.crop((x,y,x+384,y+512)),(j*384,0))
contacts.save(ROOT/'contact-guide.png')
