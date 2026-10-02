"""Save exact LF prompts before calling built-in ImageGen; no pixels generated here."""
from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
BASE = '''Use case: stylized-concept
Asset type: production raster sprite source for HARVEST THE NIGHT, a cozy farm that becomes a fortress against zombies at night.
Style: deliberate chunky hand-crafted pixel art, colored dark outlines, large readable clusters, restrained texture. Orthographic three-quarter top-down rectangular-grid camera matching Image 1. Neutral daytime upper-left light; runtime supplies night lighting. Muted rot greens, worn cloth, violet undersides, cold small highlights. No ground shadow, scenery, text, watermark, checkerboard, blur, gradients, smooth painting, new gameplay objects or excessive gore. Complete unclipped body, true transparent background. The final downstream native canvas is 32x40 with ground pivot (16,36), visible standing body 29 pixels high. Keep forms simple enough to survive reduction. This is a zombie, not a farmer costume. All heads, hands, legs and clothes must remain recognizable as black silhouettes.'''
DESIGNS = {
    'walker': 'Slouched uneven shoulders, shaggy brown hair, torn muted plum shirt, brown trousers, long dangling thin green arms. Uneven weary stance. Preserve the pilot identity in Image 1.',
    'runner': 'Very thin wiry body, conspicuous forward lean, swept-back sparse dark hair, ragged faded teal sleeveless shirt, charcoal knee-length trousers, long bent legs and tucked angular running arms. A fast hungry sprinter; clearly different from the slouched walker.',
    'tank': 'Broad heavy stocky body, thick short neck and wide shoulders, bald head, large barrel torso, faded ochre work vest over dark purple shirt, heavy charcoal trousers and broad boots. Huge forearms but no weapon. Roughly the same standing height as the walker, with substantially greater width.',
    'breaker': 'Conspicuous very long muscular arms and a demolition stance, small bent knees, cropped dark hair, ragged muted rust-red work shirt, desaturated brown trousers. One oversized dark iron demolition hammer held low outward in the left-side leading hand; functional silhouette distinct from the tank. No hard hat, shield or extra equipment.',
}
ORDERS = {
    'walk': ('4', 'left leading heel planted with right trailing toe; left leg passing under hips and right foot lifted; right leading heel planted with left trailing toe; right leg passing under hips and left foot lifted', 'a seamless weight-transfer loop'),
    'attack': ('3', 'anticipation with torso recoiled and leading arms drawn back; contact with weight forward and hands or hammer reaching toward screen-left; recovery returning to the master stance', 'one attack and recovery'),
    'death': ('4', 'knees first buckle and arms lose support; torso pitches sideways while one knee contacts ground; shoulder and hip contact ground with legs folding; fully collapsed low side-lying body with head and arms resting', 'a single irreversible collapse, ending low and still'),
}

def main():
    plan = []
    for family, design in DESIGNS.items():
        for kind in ('master', 'walk', 'attack', 'death'):
            if kind == 'master':
                refs = ['assets/art_source/masters/walker.png', 'docs/reference-sheet.png']
                body = f'''Primary request: ONE identity master for enemies/{family}, full body in neutral standing pose, looking three-quarter toward screen-left and the viewer. Image 1 is the approved pilot walker camera/material/body-scale reference; Image 2 is the world style reference, not an edit target. Create only this new master. Identity: {design}'''
            else:
                refs = [f'assets/art_source/enemies/{family}/master.png', 'assets/art_source/masters/walker.png']
                count, order, end = ORDERS[kind]
                body = f'''Primary request: enemies/{family}/{kind}, exactly {count} sequential frames in ONE horizontal strip. Image 1 is the accepted {family} identity master: retain exactly its head, clothing, body mass, camera and colors. Image 2 is only the pixel-cluster style reference. Identity: {design}
Order from left to right: {order}. The sequence forms {end}. Facing is three-quarter screen-left and toward the viewer throughout. Use equally sized generous cells separated by completely empty transparent gutters. Same ground/contact baseline at 90 percent of cell height and contact center at each cell's horizontal midpoint. Keep common drawing scale across the entire strip; never enlarge a collapsed or crouched pose. No limbs cross another cell. Actual joints, weight transfer and changing leg/arm shapes: never translate the whole drawing as an animation. No impact victim, dust, blood pool, weapon trails, ground shadow, labels or panels.'''
            prompt = BASE + '\n\n' + body + '\n'
            dest = HERE / f'0015-{family}-{kind}.prompt.txt'
            if dest.exists():
                assert dest.read_text(encoding='utf-8') == prompt, 'Retain submitted prompt'
            else:
                dest.write_text(prompt, encoding='utf-8', newline='\n')
            plan.append(dict(id=family, kind=kind, modules=[kind] if kind=='master' else [f'{kind}_{i}' for i in range(int(ORDERS[kind][0]))], references=refs, layout='row'))
    path = HERE / '0015-plan.json'
    if not path.exists():
        path.write_text(json.dumps(plan, indent=2)+'\n', encoding='utf-8', newline='\n')

if __name__ == '__main__':
    main()
