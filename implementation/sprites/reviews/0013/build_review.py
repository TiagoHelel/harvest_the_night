"""Compose source/native QA only, without creating or repairing sprite art."""
from pathlib import Path
import json
import sys
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[4]
HERE = Path(__file__).resolve().parent
GEN = ROOT / 'implementation/sprites/generation'
sys.path.insert(0, str(ROOT / 'tools'))
import import_art

SELECTED = {
    'gun_tower': ['level-1-r2', 'level-2-r2', 'level-3'],
    'flame_tower': ['level-1-r1', 'level-2', 'level-3'],
    'mortar': ['level-1', 'level-2', 'level-3'],
    'auto_crossbow': ['level-1-r1', 'level-2', 'level-3'],
}
STATES = ['whole', 'hurt', 'fire', 'wreck']


def calls():
    return [json.loads((GEN / f'0013-{ident}-{kind}-call.json').read_text())
            for ident, kinds in SELECTED.items() for kind in kinds]


def checker(size):
    image = Image.new('RGBA', size, '#e8e0cf')
    draw = ImageDraw.Draw(image)
    for y in range(0, size[1], 8):
        for x in range(0, size[0], 8):
            if (x // 8 + y // 8) % 2:
                draw.rectangle((x, y, x + 7, y + 7), fill='#b3ab9d')
    return image


def pair(image, name):
    image.save(HERE / (name + '.png'))
    image.resize(tuple(n * 3 for n in image.size), Image.Resampling.NEAREST).save(HERE / (name + '-3x.png'))


def main():
    selected = calls()
    for ident in SELECTED:
        family = [c for c in selected if c['id'] == ident]
        for mode, color in [('light', '#e8e0cf'), ('dark', '#241f2e'), ('checker', None)]:
            image = Image.new('RGBA', (320, 218), color) if color else checker((320, 218))
            draw = ImageDraw.Draw(image)
            text = '#241f2e' if color == '#e8e0cf' else '#e8e0cf'
            draw.text((4, 2), ident + ' 32x48 / (16,44)', fill=text)
            for col, state in enumerate(STATES):
                draw.text((60 + col * 64, 22), state, fill=text)
            for row, call in enumerate(family):
                draw.text((4, 42 + row * 56), 'L' + str(row + 1), fill=text)
                for col, recipe in enumerate(call['measured_recipes']):
                    sprite = import_art.render_source(recipe)
                    image.alpha_composite(sprite, (64 + col * 64, 34 + row * 56))
            pair(image, ident + '-' + mode)
    # Coordinate grids support authored native weapon-tip metadata.
    for ident in SELECTED:
        image = Image.new('RGBA', (576, 442), '#e8e0cf')
        draw = ImageDraw.Draw(image)
        draw.text((3, 2), ident + ' whole / fire native coordinates (4x nearest QA)', fill='#241f2e')
        family = [c for c in selected if c['id'] == ident]
        for col, call in enumerate(family):
            for row, state_index in enumerate([0, 2]):
                x, y = col * 192 + 24, row * 208 + 34
                sprite = import_art.render_source(call['measured_recipes'][state_index])
                # Downstream native coordinates, no refitting between states.
                sprite = sprite.resize((128, 192), Image.Resampling.NEAREST)
                for n in range(0, 33, 4):
                    draw.line((x + n * 4, y, x + n * 4, y + 192), fill='#b3ab9d')
                    draw.text((x + n * 4 - 3, y - 16), str(n), fill='#241f2e')
                for n in range(0, 49, 4):
                    draw.line((x, y + n * 4, x + 128, y + n * 4), fill='#b3ab9d')
                    draw.text((x - 20, y + n * 4 - 4), str(n), fill='#241f2e')
                image.alpha_composite(sprite, (x, y))
        image.save(HERE / (ident + '-coordinates.png'))
    silhouettes = Image.new('RGBA', (320, 242), '#e8e0cf')
    draw = ImageDraw.Draw(silhouettes)
    for row, ident in enumerate(SELECTED):
        draw.text((3, row * 58 + 3), ident, fill='#241f2e')
        for col, call in enumerate(c for c in selected if c['id'] == ident):
            sprite = import_art.render_source(call['measured_recipes'][0])
            black = Image.new('RGBA', sprite.size, '#241f2e')
            black.putalpha(sprite.getchannel('A'))
            silhouettes.alpha_composite(black, (132 + col * 56, row * 58 + 8))
    pair(silhouettes, 'silhouettes')
    raw_paths = [ROOT / c['source'] for c in selected]
    raw_paths += [ROOT / 'assets/art_source/defences' / ident / 'master.png' for ident in SELECTED]
    for page in range(0, len(raw_paths), 2):
        image = Image.new('RGBA', (960, 420), '#241f2e')
        draw = ImageDraw.Draw(image)
        for row, path in enumerate(raw_paths[page:page + 2]):
            raw = Image.open(path).convert('RGBA')
            draw.text((3, row * 210 + 2), path.parent.name + '/' + path.name + ' alpha ' + str(raw.getchannel('A').getextrema()), fill='#e8e0cf')
            for col, color in enumerate(['#e8e0cf', '#241f2e', None]):
                background = Image.new('RGBA', (312, 188), color) if color else checker((312, 188))
                thumb = raw.copy()
                thumb.thumbnail((304, 180), Image.Resampling.NEAREST)
                background.alpha_composite(thumb, ((312 - thumb.width) // 2, (188 - thumb.height) // 2))
                image.paste(background, (col * 320, row * 210 + 20))
        image.save(HERE / ('source-alpha-%02d.png' % (page // 2)))
    (HERE / 'selection.json').write_text(json.dumps(SELECTED, indent=2) + '\n', encoding='utf-8')
    captures = sorted((ROOT / 'implementation/shots/sprites/0013').rglob('*.png'))
    for page in range(0, len(captures), 2):
        image = Image.new('RGBA', (480, 572), '#241f2e')
        draw = ImageDraw.Draw(image)
        for row, path in enumerate(captures[page:page + 2]):
            draw.text((4, row * 286 + 2), path.parent.name + '/' + path.stem, fill='#e8e0cf')
            capture = Image.open(path).convert('RGBA')
            assert capture.size == (480, 270), (path, capture.size)
            image.paste(capture, (0, row * 286 + 16))
        pair(image, 'captures-%02d' % (page // 2))
    (HERE / 'capture-index.json').write_text(json.dumps([str(p.relative_to(ROOT)).replace('\\', '/') for p in captures], indent=2) + '\n', encoding='utf-8')
    print('Saved all 48 native states on light/dark/checker, silhouettes, coordinate grids and 16 source alpha reviews')


if __name__ == '__main__':
    main()
