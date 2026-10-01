"""Assemble exact built-in ImageGen briefs before generating station masters."""
from pathlib import Path
import json
import re

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
TEXT = (HERE / 'PROMPTS.md').read_text(encoding='utf-8')
def brief(name):
    return re.search(r'## ' + name + r'\s+```text\n(.*?)```', TEXT, re.S).group(1).strip()

HOUSE = 'assets/art_source/buildings/house/whole.png'
REF = 'docs/reference-sheet.png'
SPECS = [
    ('workshop', 'buildings', [48,48], [24,44], [40,38], 'compact open-front timber workshop under a low terracotta shelter roof, a broad workbench, clearly silhouetted hammer and tongs, and a small stone furnace with a dark idle opening; keep the bench and tools visible below the modest roof'),
    ('kitchen', 'buildings', [48,48], [24,44], [40,38], 'compact open-front farm kitchen with a squat stone oven and chimney, one large black cooking pot and hanging pan, a timber preparation counter and modest terracotta shelter; oven opening dark while idle, cookware plainly visible'),
    ('press', 'props', [48,48], [24,44], [36,40], 'freestanding timber screw oil press with two heavy upright beams, a conspicuous central vertical metal screw, horizontal lever, round slatted pressing basket, and a small attached receiving barrel; open silhouette, no shelter roof'),
    ('generator', 'props', [48,48], [24,44], [42,30], 'low broad farm generator on a stable small timber/stone base: one chunky blue-gray metal engine, large visible copper coil, flywheel, small exhaust pipe and fuel reservoir; clearly mechanical, no roof or building facade'),
    ('shop', 'props', [32,40], [16,36], [28,32], 'modest wooden shop counter with a blue-and-cream striped cloth awning, two timber posts, a few large basket/jar shapes on the counter; no shopkeeper, no painted text or currency icons, no extra stalls'),
    ('well', 'props', [24,32], [12,30], [20,26], 'small circular gray stone well rim with a dark visible opening, two simple timber supports and crossbar, and a conspicuous hanging wooden bucket; no roof, no ground tile, no rope filigree'),
]
plans = []
for ident, folder, canvas, pivot, body, subject in SPECS:
    specific = ('Production station identity master, idle state. ' if ident not in ('shop','well') else 'Static fixture identity master. ') + subject
    base = brief('BASE').replace('{specific object or animation, asset ID, required states}', specific + '. Asset ID: ' + folder + '/' + ident)
    base = base.replace('{Image 1: approved style reference; Image 2: identity/shape master;\nImage 3 if applicable: edit target. Specify each role explicitly.}', 'Image 1: accepted farmhouse material/camera style reference only. Image 2: original farm reference sheet for function and setting only, ignore its labels, characters, scenery and lighting effects.')
    for key, value in [('width',canvas[0]),('height',canvas[1]),('x',pivot[0]),('y',pivot[1])]:
        base = base.replace('{'+key+'}', str(value))
    base = base.replace('{true transparent background for isolated sprites, or fully\nopaque edge-to-edge material for terrain}', 'true transparent background')
    family = brief('SHOP_WELL' if ident in ('shop','well') else 'PRODUCTION_BUILDING')
    prompt = base + '\n\nFamily contract:\n' + family + '\n\nExact requested object: ' + subject + '.\nOnly draw this ONE object in the IDLE state, centered and fully isolated. Read placeholders in the family brief as this exact requested object, not a request for multiple objects or multiple states. No roof copied from the house where it would hide the function. Ground/contact is the bottom center of the object. Final visible body maximum ' + str(body[0]) + ' by ' + str(body[1]) + ' native pixels; prioritize large recognizable functional shapes that survive this reduction. No baked cast shadow, grass, smoke, sparks, glow outside the object, ground pedestal tile, floating extra parts, NPC or text.\n'
    path = HERE / ('0012-' + ident + '-master.prompt.txt')
    path.write_text(prompt, encoding='utf-8', newline='\n')
    plans.append(dict(id=ident, folder=folder, canvas_wh=canvas, pivot_xy=pivot, body_wh=body, prompt=path.relative_to(ROOT).as_posix(), references=[HOUSE,REF]))
(HERE/'0012-plan.json').write_text(json.dumps(plans,indent=2)+'\n',encoding='utf-8',newline='\n')
print('Saved six exact master prompts and their downstream contracts')
