"""Review-only native/nearest-threefold views; never edit source art."""
from pathlib import Path
import json
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[4]
HERE = Path(__file__).resolve().parent
FOLDER = ROOT / 'implementation/shots/sprites/0019'
index = HERE / 'capture-index.json'
if index.exists():
    changes = []
    for entry in json.loads(index.read_text(encoding='utf-8')):
        before = Image.open(ROOT / entry['review']).convert('RGBA').crop((0,0,480,270))
        after = Image.open(ROOT / entry['capture']).convert('RGBA')
        changes.append(dict(capture=entry['capture'], pixel_identical=before.tobytes()==after.tobytes()))
    (HERE / 'observer-refresh-diff.json').write_text(json.dumps(changes,indent=2)+'\n',encoding='utf-8',newline='\n')
captures = []
for i, path in enumerate(sorted(FOLDER.rglob('*.png'))):
    if 'before' in path.relative_to(FOLDER).parts:
        continue
    art = Image.open(path).convert('RGBA')
    assert art.size == (480, 270), path
    page = Image.new('RGBA', (1440, 1080), (24, 22, 30, 255))
    page.alpha_composite(art, (0, 0))
    ImageDraw.Draw(page).text((500, 20), path.relative_to(FOLDER).as_posix() + ' / native above, nearest 3x below', fill=(239, 232, 205, 255))
    page.alpha_composite(art.resize((1440, 810), Image.Resampling.NEAREST), (0, 270))
    out = f'captures-{i:02}.png'
    page.save(HERE / out)
    captures.append(dict(capture=path.relative_to(ROOT).as_posix(), review=f'implementation/sprites/reviews/0019/{out}'))
index.write_text(json.dumps(captures, indent=2) + '\n', encoding='utf-8', newline='\n')
print(f'{len(captures)} native/3x capture pages prepared')
