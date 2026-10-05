"""Draw diagnostic hip-to-boot paths; this is never used as farmer artwork."""
from pathlib import Path
import json
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent
NEAR = '#00cddd'
FAR = '#eb3062'
HIP_NEAR = (180, 296)
HIP_FAR = (210, 289)
# Knees/ankles are explicit, with the same hip origin in every phase.
near = [((163,355),(138,420)), ((172,368),(153,432)),
        ((178,378),(176,449)), ((193,375),(213,453)),
        ((208,374),(234,455)), ((211,350),(235,418)),
        ((169,341),(192,394)), ((153,349),(140,410))]
far = [((226,373),(252,450)), ((228,360),(252,416)),
       ((195,350),(220,398)), ((185,354),(165,408)),
       ((184,354),(150,417)), ((190,369),(166,435)),
       ((204,379),(204,451)), ((218,379),(238,455))]
hands_near = [(212,331),(205,324),(177,296),(147,273),
              (138,264),(153,280),(186,311),(207,324)]
hands_far = [(193,252),(194,260),(211,294),(224,317),
             (232,332),(222,320),(207,296),(195,271)]
labels = ['Near left contact; far right trails', 'Near left supports; far right toe-off',
          'Far right bends through; near left supports', 'Far right reaches; near left recedes',
          'Far right contact; near left trails', 'Far right supports; near left toe-off',
          'Near left bends through; far right supports', 'Near left reaches; far right recedes']
atlas = Image.new('RGB', (1536,1024), '#faf9f4')
records = []
for i in range(8):
    cell = Image.new('RGB', (384,512), '#faf9f4')
    d = ImageDraw.Draw(cell)
    d.text((8,8), f'{i+1}: {labels[i]}', fill='#222222')
    d.ellipse((146,50,238,140),fill='#cccccc')
    d.polygon([(154,148),(225,154),(226,288),(159,301)],fill='#dddddd')
    d.polygon([(154,92),(141,99),(154,108)],fill='#999999')
    for shoulder, hand in [((160,180),hands_near[i]),((220,178),hands_far[i])]:
        elbow=((shoulder[0]+hand[0])//2,(shoulder[1]+hand[1])//2+8)
        d.line([shoulder,elbow,hand],fill='#777777',width=10)
        d.ellipse((hand[0]-6,hand[1]-6,hand[0]+6,hand[1]+6),fill='#edb387')
    for hip, (knee,ankle), color in [(HIP_FAR,far[i],FAR),(HIP_NEAR,near[i],NEAR)]:
        d.line([hip,knee,ankle],fill=color,width=17)
        for x,y in (hip,knee): d.ellipse((x-9,y-9,x+9,y+9),fill=color)
        x,y=ankle
        d.polygon([(x+8,y-10),(x-6,y-15),(x-25,y-10),(x-22,y+2),(x+8,y+9)],fill=color)
    d.text((80,307),'LEFT hip: cyan',fill=NEAR)
    d.text((224,299),'RIGHT hip: pink',fill=FAR)
    d.line((316,250,275,209),fill='#555555',width=4)
    d.text((253,271),'UP-LEFT',fill='#555555')
    atlas.paste(cell,((i%4)*384,(i//4)*512))
    records.append({'phase':i+1,'near_left':{'hip':HIP_NEAR,'knee':near[i][0],'ankle':near[i][1]},
                    'far_right':{'hip':HIP_FAR,'knee':far[i][0],'ankle':far[i][1]},'meaning':labels[i]})
atlas.save(ROOT/'rebuild-leg-guide.png')
(ROOT/'rebuild-leg-guide.json').write_text(json.dumps({'direction':'up-left','phases':records,
    'purpose':'diagnostic pose paths only; never sprite artwork'},indent=2)+'\n',encoding='utf-8')
print(ROOT/'rebuild-leg-guide.png')
