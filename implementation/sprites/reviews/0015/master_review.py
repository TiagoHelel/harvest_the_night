"""Native palette/alpha conversion preview only; accepted sources remain untouched."""
from pathlib import Path
import json
import sys
from PIL import Image, ImageDraw
ROOT = Path(__file__).resolve().parents[4]
HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT/'tools'))
import import_art

def main():
    page = Image.new('RGBA', (200,100), (218,213,183,255))
    draw = ImageDraw.Draw(page)
    for i, family in enumerate(('walker','runner','tank','breaker')):
        call = json.loads((ROOT/f'implementation/sprites/generation/0015-{family}-master-call.json').read_text())
        m = call['measurements'][0]
        scale = 29/m['crop_xywh'][3]
        w,h = [round(n*scale) for n in m['crop_xywh'][2:]]
        entry = dict(source=call['source'], crop_xywh=m['crop_xywh'], content_scale=scale, content_anchor_xy=[w//2,h], canvas_wh=[32,40], pivot_xy=[16,36], alpha_threshold=128)
        image = import_art.render_source(entry)
        image.save(HERE/f'{family}-master-native.png')
        image.resize((96,120),Image.Resampling.NEAREST).save(HERE/f'{family}-master-3x.png')
        page.alpha_composite(image,(i*50+8,12))
        black = Image.new('RGBA',image.size,(0,0,0,255)); black.putalpha(image.getchannel('A'))
        page.alpha_composite(black,(i*50+8,58))
        draw.text((i*50+4,0), family, fill=(25,24,30,255))
    page.save(HERE/'masters-native.png')
    page.resize((600,300),Image.Resampling.NEAREST).save(HERE/'masters-3x.png')

if __name__ == '__main__': main()
