"""Compose native renderer playback and assert stable wood / gradual leaf motion."""
from pathlib import Path
import json
from PIL import Image, ImageChops, ImageDraw

HERE = Path(__file__).resolve().parent
specs = json.loads((HERE / 'parameters.json').read_text())
metrics = {}
for phase in ['day', 'night']:
    files = sorted((HERE / 'captures').glob(phase + '-???.png'))
    frames = [Image.open(p).convert('RGB') for p in files]
    assert len(frames) == 360
    frames[0].save(HERE / (phase + '.gif'), save_all=True,
                   append_images=frames[1:], duration=[30, 30, 40] * 120,
                   loop=0, optimize=False, disposal=2)
    metrics[phase] = []
    reference = Image.open(HERE / 'captures' / (phase + '-static.png')).convert('RGB')
    for spec in specs:
        x, y = spec['top']
        leaves = [im.crop((x, y, x + 40, y + 22)) for im in frames]
        wood = (x, y + 22, x + 40, y + 48)
        assert all(ImageChops.difference(im.crop(wood), reference.crop(wood)).getbbox()
                   is None for im in frames)
        delta = max(max(hi for lo, hi in ImageChops.difference(a, b).getextrema())
                    for a, b in zip(leaves, leaves[1:]))
        unique = len({im.tobytes() for im in leaves})
        assert delta <= 5, (phase, delta)
        assert unique > 100, (phase, unique)
        metrics[phase].append({
            'texture': spec['texture'], 'max_adjacent_frame_channel_change': delta,
            'unique_canopy_crops': unique,
            'all_360_trunk_frames_equal_to_static': True})

page = Image.new('RGB', (900, 1440), (218, 213, 183))
for i, frame in enumerate([0, 45, 90, 135, 180, 225, 270, 315]):
    im = Image.open(HERE / 'captures' / ('day-%03d.png' % frame)).convert('RGB')
    crop = im.crop((134, 78, 346, 134))
    y = i * 180
    ImageDraw.Draw(page).text((0, y), '%.1f s' % (frame / 30), fill=(20, 20, 20))
    page.paste(crop, (0, y + 18))
    page.paste(crop.resize((636, 168), Image.Resampling.NEAREST), (248, y + 8))
page.save(HERE / 'contact.png')
(HERE / 'pixel-motion.json').write_text(json.dumps(metrics, indent=2) + '\n')
print(json.dumps(metrics, indent=2))
