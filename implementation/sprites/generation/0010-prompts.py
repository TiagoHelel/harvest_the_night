"""Persist exact production prompts before built-in ImageGen calls."""
from pathlib import Path
import json
import re

ROOT=Path(__file__).resolve().parents[3]
HERE=Path(__file__).resolve().parent
briefs=(HERE/'PROMPTS.md').read_text(encoding='utf-8')
def brief(name):
    return re.search(r'## '+name+r'\n\n```text\n(.*?)\n```',briefs,re.S).group(1)

def main():
    plans=[]
    stages={
        'wheat': ('16','14','12', 'Stage 0: three small warm tan planted kernels on the baseline, no leaves, about 5x2 native pixels. Stage 1: two short thin green shoots, about 5x4. Stage 2: three taller green blades with tiny immature green heads, about 8x8. Stage 3: three slender stalks bearing distinct ripe golden wheat ears, about 10x12, green lower leaves and clearly warm golden upper grain clusters. The ripe ears are narrow pointed grain heads, not corn cobs.'),
        'corn': ('24','22','20', 'Stage 0: two small pale gold planted kernels on the baseline, no leaves, about 4x2 native pixels. Stage 1: one short shoot with TWO broad folded leaves, about 6x5. Stage 2: upright green stalk with four broad alternating lance leaves, about 10x12, no yellow cobs yet. Stage 3: one taller upright stalk, six broad leaves, two readable yellow cobs attached to the central stem and a small ochre tassel, about 12x20. Keep clear spaces between leaves, not a bush or sunflower. Both cobs must survive reduction.'),
        'carrot': ('16','14','10', 'Stage 0: three tiny orange-brown planted seeds on the baseline, no leaves, about 4x2 native pixels. Stage 1: two low delicate divided green leaves, about 5x4. Stage 2: a fuller compact feathery green top with several divided branches, about 8x7, no visible orange shoulder yet. Stage 3: a low fan of feathery green tops with TWO small ripe orange carrot shoulders visible just above the ground baseline, about 10x10. No complete uprooted carrot, dirt mound or round tomato fruit; roots remain underground.'),
    }
    for kind,(height,pivot,body,spec) in stages.items():
        base=brief('BASE').replace('{specific object or animation, asset ID, required states}',kind+' growth source, crops/'+kind+'_0 through '+kind+'_3, exactly four stages').replace('{Image 1: approved style reference; Image 2: identity/shape master;\nImage 3 if applicable: edit target. Specify each role explicitly.}','Image 1: approved neutral-day farm, material/camera reference only; Image 2: repository reference sheet, species/material reference only. Neither is an edit target.').replace('{width}','16').replace('{height}',height).replace('{x}','8').replace('{y}',pivot).replace('{true transparent background for isolated sprites, or fully\nopaque edge-to-edge material for terrain}','genuinely transparent background outside the four plant silhouettes')
        crop=brief('CROP').replace('{wheat/corn/carrot}',kind)
        exact=('Exact asset and strip contract:\nOne horizontal row of EXACTLY FOUR non-overlapping equal-width source cells, ordered stage 0,1,2,3 from LEFT to RIGHT. Each cell has the same bottom-center ground contact and the same source pixel scale; early plants are naturally much smaller, never enlarged to fill a cell. Generous transparent gutters and margins; no labels, lines, boxes, soil, ground shadow, grass or background. One coherent '+kind+' species under neutral upper-left daylight. Final crop canvases are 16x'+height+' with pivot (8,'+pivot+'); mature visible height about '+body+' pixels, keep native side margins so adjacent 16px cells remain readable. '+spec+' All four contacts lie on ONE shared horizontal baseline. Keep the complete plants unclipped and centered independently in equal source cells. This is growth progression, not four identical mature plants or a walk animation.')
        plans.append(dict(id=kind,prompt=base+'\n\nCROP brief:\n'+crop+'\n\n'+exact,transparent=True,references=['assets/art_source/masters/style-day.png','docs/reference-sheet.png']))
    for wet in (False,True):
        ident='tilled_wet' if wet else 'tilled'
        base=brief('BASE').replace('{specific object or animation, asset ID, required states}','crops/'+ident+', one opaque seamless tilled-earth tile').replace('{Image 1: approved style reference; Image 2: identity/shape master;\nImage 3 if applicable: edit target. Specify each role explicitly.}','Image 1: '+('approved dry tilled soil, EDIT TARGET; change only soil moisture value/color, preserve exactly the furrow geometry, spacing and camera.' if wet else 'accepted plain soil tile, material/color reference only; make a new tilled version.')).replace('{width}','16').replace('{height}','16').replace('{x}','8').replace('{y}','16').replace('{true transparent background for isolated sprites, or fully\nopaque edge-to-edge material for terrain}','fully opaque tilled earth filling every image pixel edge to edge')
        exact=('Exact soil contract:\nA SINGLE fully opaque seamless orthographic top-down material swatch, not a perspective block or patch floating on a background. Four quiet horizontal joined furrows cross the whole image at equal intervals, repeating top-to-bottom and left-to-right at tile boundaries. Subdued broad pixel clusters, two or three brown planes, no high contrast black border or random noise. Final 16x16 tile under foliage must remain recognizable as '+('dark cool damp earth; visibly darker than the accepted dry master, preserving all four original furrows, without blue water puddles or sparkles.' if wet else 'dry medium warm brown earth with darker furrow channels, slightly lighter ridge tops. It must contrast with accepted plain soil while staying below crop silhouettes in visual priority.')+' No plant, seed, roots, pebbles, grass, farm object, label, border, bevel or transparency. Do not draw a checkerboard. Crop family contract: dry/wet tilled soil are separate opaque assets; the plants will be composited over this material at runtime.')
        plans.append(dict(id=ident,prompt=base+'\n\nCROP supporting-soil brief:\nDry/wet tilled soil are separate opaque assets.\n\n'+exact,transparent=False,references=['assets/art_source/crops/tilled.png' if wet else 'assets/art_source/terrain/soil.png']))
    for plan in plans:
        (HERE/('0010-'+plan['id']+'.prompt.txt')).write_text(plan['prompt']+'\n',encoding='utf-8',newline='\n')
    (HERE/'0010-plan.json').write_text(json.dumps(plans,indent=2)+'\n',encoding='utf-8',newline='\n')
    print('Saved three growth-strip and two soil prompts')

if __name__=='__main__':
    main()
