"""Freeze exact single-icon requests and native/compact targets before calls."""
from pathlib import Path
import json
import re

ROOT=Path(__file__).resolve().parents[3]
HERE=Path(__file__).resolve().parent
briefs={
 'wood':'two short stacked timber logs with warm bark and one large pale cut end; horizontal silhouette',
 'stone':'two chunky grey fieldstones with broad angular faces; low irregular silhouette',
 'iron':'one silver-grey iron ingot, elongated trapezoid with a bright broad top and dark side; no rocks',
 'food':'one shallow wooden bowl holding a simple cream cooked meal with one green garnish; round open bowl silhouette, not a corn cob or raw meat',
 'fish':'one blue fish facing left with a distinct forked tail and pale belly; horizontal oval silhouette',
 'oil':'one squat upright wooden oil barrel with two dark metal hoops and closed lid; warm brown cylindrical silhouette',
 'wheat':'one slim golden wheat head leaning diagonally with short stem and joined grain lobes; no corn cob',
 'corn':'one broad golden corn cob with a simple dark-green peeled husk; wide tapering grain mass, no long stalk',
 'carrot':'one orange carrot with two short joined green leaves; long tapered root silhouette',
 'meat':'one red raw steak with a cream fat rim and one central bone spot; compact irregular red oval',
 'gunpowder':'one low triangular mound of charcoal-grey gunpowder with two broad light planes; no barrel or metallic ingot',
 'incendiary':'one squat red metal fuel can with a short spout and one small orange flame emblem made of pixels, no letters; red rectangular silhouette distinct from the brown oil barrel',
 'money':'three overlapping golden coins, two stacked and one showing a plain broad face; no embossed letters or numbers',
 'energy':'one bold gold lightning bolt leaning right; a compact five-turn zigzag, no enclosing battery or glow',
 'tech':'one pale steel six-tooth gear with a dark circular hole and one warm brass accent; bold mechanism silhouette, no letter or number',
}
doc=(ROOT/'implementation/sprites/generation/PROMPTS.md').read_text(encoding='utf-8')
base=re.search(r'## BASE\s+```text\n(.*?)\n```',doc,re.S)[1]
plan=[]
for ident,subject in briefs.items():
    refs=['docs/reference-sheet.png']+([] if ident=='wood' else ['assets/art_source/ui/wood.png'])
    roles='Image 1: approved world materials and resource vocabulary, style reference only; do not reproduce its panels, lettering or scene.'
    if ident!='wood':roles+=' Image 2: accepted wood icon family master, reference only for outline thickness, clustered detail and neutral upper-left light, not an edit target or the requested object.'
    values=dict(specific_object='',width=16,height=16,x=8,y=8)
    text=base.replace('{specific object or animation, asset ID, required states}',f'ONE isolated inventory icon ui/icon_{ident}, one neutral static state: {subject}.')
    text=text.replace('{Image 1: approved style reference; Image 2: identity/shape master;\nImage 3 if applicable: edit target. Specify each role explicitly.}',roles)
    for key,value in values.items():text=text.replace('{'+key+'}',str(value))
    text=text.replace('{true transparent background for isolated sprites, or fully\nopaque edge-to-edge material for terrain}','true transparent background outside the icon; no enclosing frame or ground')
    text+='\n\n'+re.search(r'## ICON\s+```text\n(.*?)\n```',doc,re.S)[1].replace('{exact resource ID}',ident).replace('{logs/stone/iron ingot/meal/fish/oil barrel/wheat head/corn cob/carrot/\nmeat/gunpowder/incendiary fuel/coins/energy/tech mechanism}',subject)
    text+='\n\nNative contract: one centered complete object with generous transparent outer space. The import targets are 16x16 (maximum visible dimension 14) and a separate 10x10 compact HUD canvas (maximum visible dimension 9). The same source will be reduced for both: use a bold simple silhouette, a few joined color clusters and only 2-3 material planes. Think of a real tiny inventory sprite, not a miniature detailed illustration. Compact internal features must survive at nine visible pixels. No tiny line hatching, scattered crumbs, distant decorative fragments, floor, cast shadow, glow, labels, lettering, numbers, backdrop or extra objects. Maintain approximately square source framing with the object centered; do not clip its silhouette.\n'
    assert not re.search(r'\{.*?\}',text),ident
    (HERE/f'0018-{ident}.prompt.txt').write_text(text,encoding='utf-8',newline='\n')
    plan.append(dict(id=ident,subject=subject,references=refs,canvas=[16,16],compact_canvas=[10,10],visible=14,compact_visible=9))
(HERE/'0018-plan.json').write_text(json.dumps(plan,indent=2)+'\n',newline='\n')
print('Prepared 15 exact single-icon prompts; native 16px and compact 10px, no prior art replacements')
