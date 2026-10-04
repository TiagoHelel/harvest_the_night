"""Draw diagonal leg ownership/phase schematic; not character artwork."""
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent
im = Image.new('RGB', (1536,1024), '#faf9f4')
d = ImageDraw.Draw(im)
# Near anatomical right hip = left/down screen; far left hip = right/up.
# Forward motion projects right AND down. Each whole chain owns one fixed hip.
phases = [((194,365),(208,450)),((195,370),(205,447)),
          ((187,368),(178,443)),((172,358),(156,420)),
          ((164,345),(145,405)),((158,349),(142,413)),
          ((188,343),(180,413)),((201,355),(207,442))]
labels = ['Near right contact','Near support / far toe-off','Far knee passes',
          'Far reaches forward','Far left contact','Far support / near toe-off',
          'Near knee passes','Near reaches forward']
for i in range(8):
    ox,oy = i%4*384,i//4*512
    d.text((ox+10,oy+10),f'{i+1}: {labels[i]}',fill='#222222')
    d.ellipse((ox+155,oy+55,ox+239,oy+135),fill='#cccccc')
    d.polygon([(ox+150,oy+150),(ox+231,oy+141),(ox+237,oy+292),(ox+160,oy+305)],fill='#dddddd')
    for offset,p,color,hip in [(40,phases[(i+4)%8],'#009eb7',(218,292)),
                               (0,phases[i],'#e73438',(178,300))]:
        (kx,ky),(ax,ay) = p
        kx,ax = kx+offset,ax+offset
        ky,ay = ky-(8 if offset else 0),ay-(8 if offset else 0)
        d.ellipse((ox+hip[0]-12,oy+hip[1]-12,ox+hip[0]+12,oy+hip[1]+12),fill=color)
        d.line([(ox+hip[0],oy+hip[1]),(ox+kx,oy+ky),(ox+ax,oy+ay)],fill=color,width=18)
        d.ellipse((ox+kx-10,oy+ky-10,ox+kx+10,oy+ky+10),fill=color)
        d.polygon([(ox+ax-12,oy+ay-4),(ox+ax+10,oy+ay-4),
                   (ox+ax+25,oy+ay+16),(ox+ax+1,oy+ay+20)],fill=color)
    d.text((ox+115,oy+315),'R hip',fill='#e73438')
    d.text((ox+225,oy+295),'L hip',fill='#009eb7')
    d.line((ox+285,oy+220,ox+330,oy+265),fill='#555555',width=4)
    d.polygon([(ox+330,oy+265),(ox+315,oy+260),(ox+327,oy+248)],fill='#555555')
    d.text((ox+260,oy+280),'Forward: down-right',fill='#555555')
im.save(ROOT/'leg-ownership-guide.png')
