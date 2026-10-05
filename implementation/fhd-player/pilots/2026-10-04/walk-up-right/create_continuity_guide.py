"""Diagnostic joint paths only. This does not paint or deform character artwork."""
from pathlib import Path
import json
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent
# A planted foot moves steadily backward relative to the stationary body.
# During recovery it lifts, passes below its own hip, then reaches forward.
ankles = [(260, 440), (240, 446), (220, 452), (200, 458),
          (180, 464), (190, 438), (220, 422), (250, 427)]
knees = [(240, 370), (230, 378), (220, 382), (210, 386),
         (200, 390), (205, 371), (238, 365), (245, 368)]
labels = ['R contact / L toe-off', 'R support / L lift',
          'R under hip / L passing', 'R trailing / L reach',
          'L contact / R toe-off', 'L support / R lift',
          'L under hip / R passing', 'L trailing / R reach']
im = Image.new('RGB', (1536, 1024), '#faf9f4')
d = ImageDraw.Draw(im)
records = []
for i in range(8):
    ox, oy = i % 4 * 384, i // 4 * 512
    d.text((ox+12, oy+12), f'{i+1}: {labels[i]}', fill='#202020')
    d.ellipse((ox+133, oy+60, ox+267, oy+145), fill='#cccccc')
    d.polygon([(ox+162, oy+155), (ox+240, oy+157),
               (ox+242, oy+311), (ox+166, oy+300)], fill='#dddddd')
    chains = []
    for name, phase, offset, hip, color in [
        ('far_left', (i+4)%8, (-30,-8), (190,299), '#00b9d6'),
        ('near_right', i, (0,0), (220,307), '#f03946')]:
        knee = tuple(knees[phase][j]+offset[j] for j in (0,1))
        ankle = tuple(ankles[phase][j]+offset[j] for j in (0,1))
        points = [(ox+x, oy+y) for x,y in [hip,knee,ankle]]
        d.line(points, fill=color, width=19)
        for x,y in points:
            d.ellipse((x-8,y-8,x+8,y+8), fill=color)
        ax, ay = points[-1]
        d.polygon([(ax-9,ay-6),(ax+7,ay-8),(ax+24,ay-1),
                   (ax+20,ay+9),(ax-10,ay+9)], fill=color)
        chains.append(dict(leg=name, hip=hip, knee=knee, ankle=ankle))
    # Crosshairs are diagnostic references, never production sprite pixels.
    for x,y,color in [(190,299,'#007e91'),(220,307,'#b4222b')]:
        d.line((ox+x-10,oy+y,ox+x+10,oy+y),fill=color,width=2)
        d.line((ox+x,oy+y-10,ox+x,oy+y+10),fill=color,width=2)
    records.append(dict(frame=i+1, phase=labels[i], chains=chains))
im.save(ROOT/'continuity-guide-r2.png')
(ROOT/'continuity-guide-r2.json').write_text(json.dumps(records, indent=2), encoding='utf-8')
