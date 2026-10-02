"""Assemble immutable submitted ImageGen prompts for connected barrier modules."""
from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
briefs = (HERE / 'PROMPTS.md').read_text(encoding='utf-8')
base = briefs.split('## BASE')[1].split('```text')[1].split('```')[0].strip()
family = briefs.split('## WALL_TRAP')[1].split('```text')[1].split('```')[0].strip()
plans = []
for ident in ('wall', 'fence'):
    material = ('solid low gray stone masonry with a broad capped stone pier, three readable courses and darker violet joints'
                if ident == 'wall' else 'warm timber fence with square capped posts and two substantial horizontal rails, iron fastenings and open gaps')
    for kind in ('whole', 'hurt'):
        refs = ['assets/art_source/defences/gun_tower/master.png', 'docs/reference-sheet.png'] if kind == 'whole' else [f'assets/art_source/defences/{ident}/whole.png', 'docs/reference-sheet.png']
        text = base.replace('{specific object or animation, asset ID, required states}', f'{ident}/{kind}: a four-module construction source sheet')
        text = text.replace('{Image 1: approved style reference; Image 2: identity/shape master;\nImage 3 if applicable: edit target. Specify each role explicitly.}',
                            'Image 1: material/camera style reference' if kind == 'whole' else 'Image 1: exact approved construction master; preserve its physical dimensions')
        text = text.replace('{width}x{height}', '16x32').replace('{x},{y}', '8,28')
        text = text.replace('{true transparent background for isolated sprites, or fully\nopaque edge-to-edge material for terrain}', 'true transparent background for every module')
        text += '\n\n' + family.replace('{timber fence/stone wall/barricade/mine}', material).replace('{whole/hurt/wreck/armed/triggered}', kind).replace('{horizontal/vertical/end/corner/junction}', 'modular horizontal/vertical/post/ruin pieces').replace('{16x24 or 16x32; mine 16x16}', '16x32')
        text += '''

Generate exactly FOUR separate modules in a clearly separated 2x2 source sheet.
No labels, no tile outlines, no ground, no baked cast shadow. Leave wide transparent gutters.
TOP LEFT: a SINGLE isolated capped central pier/post, no rails or connecting arms.
TOP RIGHT: one horizontal east-west span viewed straight along the rectangular screen X axis, with exposed vertical front face and shallow top, no perspective diagonal. Rails/masonry reach the two cut ends; no tall endpoint posts. Its native physical width is 16 units and construction height 12 units.
BOTTOM LEFT: one north-south span viewed along the rectangular screen Y axis, a narrow straight corridor with a continuous visible top and side. No perspective diagonal and no tall endpoint posts. Its native ground length is 16 units, construction height 12 units, overall projected silhouette about 28 units tall and 5-6 units wide.
BOTTOM RIGHT: the same material collapsed into a low heap of broken construction, about 14 units wide and 4 units high, completely lying down.
Same physical scale in all four modules: the single post is 5-6 units wide and 12 units tall; the horizontal span is 16 units wide; the vertical span is taller only because its ground length extends away from camera. Do not enlarge the post or heap to fill their sheet cells.
These are authored components of 16x16 logical cells. Downstream deterministic cuts and composition will join the approved post and the cardinal halves of the approved spans into isolated/end/corner/T/cross shapes. Keep clean broad edges and continuous bridge surfaces. All artwork must survive reduction to these tiny sizes.
'''
        if kind == 'hurt':
            text += ('\nKeep the master camera, physical dimensions, span cut ends and contacts. Author structural wear rather than random holes: '
                     + ('a visibly missing central masonry chunk, a cracked cap and a broken side course; ends still connect to neighbors.' if ident == 'wall' else 'a clearly split post cap, snapped lower rail and a bent/splintered upper rail; ends still connect to neighbors.')
                     + ' The heap remains collapsed rubble. Keep missing parts visible as broad gaps without redesigning the construction.\n')
        path = HERE / f'0014-{ident}-{kind}.prompt.txt'
        if not path.exists():
            path.write_text(text.strip(), encoding='utf-8', newline='\n')
        plans.append(dict(id=ident, kind=kind, prompt=path.relative_to(ROOT).as_posix(), references=refs,
                          canvas_wh=[16,32], pivot_xy=[8,28], modules=['post','horizontal','vertical','wreck']))
for ident in ('barricade', 'mine'):
    refs = ['assets/art_source/defences/gun_tower/master.png', 'docs/reference-sheet.png']
    request = ('a piled timber barricade, low crossed heavy logs and salvaged planks, with a joined silhouette and readable diagonal bracing'
               if ident == 'barricade' else 'a low round mechanical pressure mine, dull steel casing, a restrained red copper central pressure plate and short mechanical tabs; no glowing beacon')
    states = ('whole intact stack; structurally hurt with a snapped brace and shifted log; collapsed low wreck'
              if ident == 'barricade' else 'armed intact disc; triggered with pressure plate depressed, casing sprung open and a tiny localized warm burst; spent collapsed casing without fire')
    text = base.replace('{specific object or animation, asset ID, required states}', request + ', asset ' + ident)
    text = text.replace('{Image 1: approved style reference; Image 2: identity/shape master;\nImage 3 if applicable: edit target. Specify each role explicitly.}', 'Image 1: approved material/camera reference; Image 2: approved farm style reference')
    text = text.replace('{width}x{height}', '16x24' if ident == 'barricade' else '16x16').replace('{x},{y}', '8,20' if ident == 'barricade' else '8,14')
    text = text.replace('{true transparent background for isolated sprites, or fully\nopaque edge-to-edge material for terrain}', 'true transparent background')
    text += '\n\nGenerate a SINGLE isolated identity master of ' + request + '. Native visible dimensions about ' + ('14x12' if ident == 'barricade' else '12x7') + '. Low and contained inside one existing logical cell. No ground or shadow. No labels or extra objects.'
    path = HERE / f'0014-{ident}-master.prompt.txt'
    if not path.exists(): path.write_text(text.strip(), encoding='utf-8', newline='\n')
    plans.append(dict(id=ident, kind='master', prompt=path.relative_to(ROOT).as_posix(),references=refs,canvas_wh=[16,24] if ident=='barricade' else [16,16],pivot_xy=[8,20] if ident=='barricade' else [8,14],modules=['master']))
    refs = [f'assets/art_source/defences/{ident}/master.png', 'docs/reference-sheet.png']
    text = text.replace('Image 1: approved material/camera reference; Image 2: approved farm style reference', 'Image 1: exact identity master; Image 2: farm camera/material style reference')
    text = text.split('\n\nGenerate a SINGLE')[0] + '\n\nGenerate exactly THREE states of the SAME approved master in one clearly separated horizontal strip, ordered left to right: ' + states + '. Wide transparent gutters, same construction size and ground contact baseline. Do not fit each state to its cell. No labels, ground or shadows. Keep every tiny burst inside the common native canvas; no huge explosion. Preserve the master silhouette and identity.'
    path = HERE / f'0014-{ident}-states.prompt.txt'
    if not path.exists(): path.write_text(text.strip(), encoding='utf-8', newline='\n')
    plans.append(dict(id=ident,kind='states',prompt=path.relative_to(ROOT).as_posix(),references=refs,canvas_wh=[16,24] if ident=='barricade' else [16,16],pivot_xy=[8,20] if ident=='barricade' else [8,14],modules=['whole','hurt','wreck'] if ident=='barricade' else ['armed','triggered','spent']))
plan_path = HERE / '0014-plan.json'
if not plan_path.exists():
    plan_path.write_text(json.dumps(plans,indent=2)+'\n',encoding='utf-8',newline='\n')
print('Prepared eight immutable source prompts: two modular barrier families and two trap/obstacle families')
