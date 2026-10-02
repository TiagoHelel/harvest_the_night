"""Compose QA playback from unmodified native Godot captures."""
from pathlib import Path
import json
from PIL import Image, ImageChops, ImageDraw

HERE = Path(__file__).resolve().parent
CAPTURES = HERE / 'captures'
for prefix, duration in [('camera', [20,10,20]*30), ('ambient-day', [70,60,70]*30), ('ambient-night', [70,60,70]*30)]:
    frames = [Image.open(p).convert('RGB') for p in sorted(CAPTURES.glob(prefix+'-*.png'))]
    assert len(frames) == 90
    frames[0].save(HERE / (prefix+'.gif'), save_all=True, append_images=frames[1:],
                   duration=duration, loop=0, optimize=False, disposal=2)

# Native closeups, with an exact nearest enlargement beside each phase.
page = Image.new('RGB',(900,1440),(218,213,183))
for i, frame in enumerate([0,8,16,24,48,49,50,52]):
    source = Image.open(CAPTURES / ('ambient-day-%03d.png' % frame)).convert('RGB')
    crop = source.crop((164,70,304,154))
    x,y = (i%2)*450,(i//2)*360
    page.paste(crop,(x,y+15))
    ImageDraw.Draw(page).text((x+2,y+2),'frame '+str(frame),fill=(24,24,24))
    page.paste(crop.resize((420,252),Image.Resampling.NEAREST),(x,y+104))
page.save(HERE / 'ambient-contact.png')

# Verify actual raster movement separately for each fixed creature/canopy area.
samples = [Image.open(p).convert('RGB') for p in sorted(CAPTURES.glob('ambient-day-*.png'))]
regions = {'tree':(170,75,220,132), 'cow':(249,105,274,132), 'chicken':(275,103,304,135)}
changes = {name:len({frame.crop(box).tobytes() for frame in samples}) for name,box in regions.items()}
assert all(n > 1 for n in changes.values()), changes
(HERE / 'visible-motion.json').write_text(json.dumps(changes,indent=2)+'\n')
print(changes)

for source in (HERE.parents[1]/'shots'/'world-visibility').glob('*.png'):
    Image.open(source).resize((1440,810),Image.Resampling.NEAREST).save(
        HERE/('main-'+source.stem+'-3x.png'))
