"""Compose actual 30-Hz renderer captures without modifying any sprite pixels."""
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[4]
HERE = Path(__file__).resolve().parent
SHOTS = ROOT / 'implementation/shots/sprites/walker-walk-fix'

for phase in ('day', 'night'):
    frames = []
    # Compare the same viewport area at native size, with no enlargement.
    # The panel follows no actor; its source crop is fixed throughout the clip.
    sheet = Image.new('RGB', (960, 720), (218,213,183))
    for t in range(60):
        pair = Image.new('RGB', (240,176), (218,213,183))
        d = ImageDraw.Draw(pair)
        for row, version in enumerate(('before', 'after')):
            source = Image.open(SHOTS / version / ('loop_%s_%03d.png' % (phase,t))).convert('RGB')
            crop = source.crop((145,100,385,172))
            pair.paste(crop, (0,row*88+16))
            d.text((3,row*88+2), 'Before' if row == 0 else 'After', fill=(26,24,32))
        frames.append(pair)
        # Every consecutive sample remains inspectable, including foot contact.
        source = Image.open(SHOTS / 'after' / ('loop_%s_%03d.png' % (phase,t))).convert('RGB')
        sheet.paste(source.crop((145,112,265,160)), ((t%8)*120,(t//8)*90+16))
        ImageDraw.Draw(sheet).text(((t%8)*120+2,(t//8)*90+2), str(t), fill=(26,24,32))
    frames[0].save(HERE / ('walk-'+phase+'-native.gif'), save_all=True,
                   append_images=frames[1:], duration=[30,30,40]*20, loop=0, disposal=2, optimize=False)
    sheet.save(HERE / ('walk-'+phase+'-all-ticks.png'))

print('Saved native before/after day and night clips, 60 real ticks each')
