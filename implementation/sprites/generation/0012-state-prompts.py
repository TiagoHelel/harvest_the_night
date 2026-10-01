"""Derive small authored state-strip briefs from the accepted identity masters."""
from pathlib import Path
import json
import re

ROOT=Path(__file__).resolve().parents[3]
HERE=Path(__file__).resolve().parent
CHANGES={
    'workshop': ('light only the stone furnace opening with a small amber fire, move the tabletop hammer slightly into its working pose; do not move the bench or hanging tools', 'a few broken tiles on one roof corner and a split bench-facing board, while both support posts and the furnace remain standing'),
    'kitchen': ('light only the stone oven opening with amber fire and lift the pot lid slightly; do not add steam to this source', 'a few broken tiles on one roof corner, chipped oven masonry and a torn small counter cloth; keep the chimney, cookware and supporting posts'),
    'press': ('rotate the long lever a small angle and lower the screw pressing plate slightly; a short oil stream into the same receiving barrel is allowed only in this active frame', 'a split side brace, a chipped lever end and a bent basket hoop; keep both main uprights, the complete screw and the same planted base'),
    'generator': ('rotate only the flywheel spokes to a distinct second position and add a tiny pale blue indicator on the engine casing; no sparks, smoke plume or external glow', 'a dented casing panel, one exposed small coil section and a split base-facing board; preserve the exhaust, overall engine mass and ground base'),
}
for plan in json.loads((HERE/'0012-plan.json').read_text()):
    ident=plan['id']
    if ident not in CHANGES:continue
    source=(ROOT/plan['prompt']).read_text(encoding='utf-8').split('\nFamily contract:')[0]
    source=re.sub(r'Primary request: .*?\nInput images:', 'Primary request: Exactly three authored states of the accepted '+ident+' in one horizontal strip.\nInput images:', source)
    source=re.sub(r'Input images: .*?\nStyle/medium:', 'Input images: Image 1 is the accepted '+ident+' identity master and precise geometry reference. Image 2 is the accepted farmhouse material/camera style reference.\nStyle/medium:', source)
    active,hurt=CHANGES[ident]
    prompt=source+'\nFamily: '+ident+', production building over an unchanged 32x32 logical footprint.\n'
    prompt+='Exactly THREE complete objects of the SAME master in equal-size cells in one horizontal strip, left to right: IDLE, ACTIVE, HURT. Wide transparent image, large empty gutters (at least 8 percent of a cell width) and outer margin. Same camera, visible dimensions, base geometry, ground-contact baseline, and center within every cell. No labels, borders, separators, shadows, smoke or extra objects. Preserve identity rather than redesigning the master.\n'
    prompt+='Frame 1 IDLE: faithfully repeat the accepted master with dark inactive furnace/oven/indicator; no oil pouring, no motion marks. Frame 2 ACTIVE: '+active+'. Frame 3 HURT: '+hurt+'. This is localized structural wear, not a collapsed wreck, different building, uniformly peppered holes or a different scale. Hurt opening/indicator remains inactive.\n'
    prompt+='Critical invariants: all fixed structural edges and the planted base match between IDLE and ACTIVE; only the listed working parts change. HURT retains the same base and structural identity. Generate fresh authored state art referenced from the master, never multiple different stations in a strip. Simple broad clusters suitable for the same native canvas/contact contract.\n'
    (HERE/('0012-'+ident+'-states.prompt.txt')).write_text(prompt,encoding='utf-8',newline='\n')
print('Saved four exact three-state strip prompts using accepted masters')
