"""Draw an anatomy diagram for ImageGen, never replacement sprite artwork."""
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent
im = Image.new('RGB', (1536, 1024), '#faf9f4')
d = ImageDraw.Draw(im)
# Each anatomical leg retains its own hip. Forward is toward screen bottom.
# (knee y, ankle y, sole y); second half exchanges gait, never identity.
a = [(370, 450, 469), (377, 446, 466), (374, 437, 455), (362, 415, 431),
     (350, 400, 418), (346, 405, 424), (354, 416, 435), (363, 438, 457)]
labels = ['A contact', 'A weight / B toe off', 'B passing', 'B reaches',
          'B contact', 'B weight / A toe off', 'A passing', 'A reaches']
for i in range(8):
    ox, oy = i % 4 * 384, i // 4 * 512
    d.text((ox + 15, oy + 15), f'{i + 1}: {labels[i]}', fill='#202020')
    d.ellipse((ox+150, oy+55, ox+234, oy+135), fill='#cccccc')
    d.rectangle((ox+151, oy+145, ox+233, oy+305), fill='#dddddd')
    for hip, pose, color in [(172, a[i], '#e73438'), (213, a[(i+4)%8], '#009eb7')]:
        ky, ay, sy = pose
        d.line([(ox+hip, oy+305), (ox+hip, oy+ky), (ox+hip, oy+ay)], fill=color, width=18)
        d.ellipse((ox+hip-10, oy+ky-10, ox+hip+10, oy+ky+10), fill=color)
        d.rounded_rectangle((ox+hip-15, oy+ay-6, ox+hip+15, oy+sy), radius=4, fill=color)
    d.line((ox+145,oy+479,ox+240,oy+479), fill='#999999', width=1)
im.save(ROOT / 'leg-ownership-guide.png')
