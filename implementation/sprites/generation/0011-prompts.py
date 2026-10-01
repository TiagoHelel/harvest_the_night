"""Save BASE + HOUSE requests before built-in generation."""
from pathlib import Path
import json
import re

ROOT=Path(__file__).resolve().parents[3]
HERE=Path(__file__).resolve().parent
briefs=(HERE/'PROMPTS.md').read_text(encoding='utf-8')
def brief(name):return re.search(r'## '+name+r'\n\n```text\n(.*?)\n```',briefs,re.S).group(1)

def main():
    plans=[]
    for state in ('whole','hurt'):
        ident='house' if state=='whole' else 'house_hurt'
        target='assets/art_source/masters/house.png' if state=='whole' else 'assets/art_source/buildings/house/whole.png'
        base=brief('BASE').replace('{specific object or animation, asset ID, required states}','refine the accepted farmhouse, buildings/'+ident+', one '+state+' state').replace('{Image 1: approved style reference; Image 2: identity/shape master;\nImage 3 if applicable: edit target. Specify each role explicitly.}','Image 1: accepted farmhouse, EDIT TARGET and architecture/camera/scale identity. '+('Image 2: repository reference sheet, material/style reference only.' if state=='whole' else 'Preserve exactly the whole master framing, dimensions, ground baseline, chimney and five window/door-pane positions.')).replace('{width}','64').replace('{height}','64').replace('{x}','32').replace('{y}','60').replace('{true transparent background for isolated sprites, or fully\nopaque edge-to-edge material for terrain}','genuinely transparent background outside this single complete house')
        spec=('Preserve this exact compact farmhouse design and silhouette: one front gable, terracotta roof, right gray chimney, timber facade, central door, two front windows, one gable window, one right-wall window and the small glazed door pane. Keep the same source canvas dimensions, object framing, outer margins and stair ground baseline; this is an edit, not another larger house. Refine the roof into calmer broad joined red tile clusters and clear three-plane shading that survive a 56x55 native body, simplifying tiny speckles and redundant one-pixel tile seams. Retain the facade beams, large simple window frames and short entrance steps. Warm pale gold panes without baked bloom; window glass remains visibly separated by dark timber mullions. No new windows, balcony, decorations, smoke, ground patch or shadows. Neutral upper-left daylight, matching existing cozy pixel art, crisp simple colored edges.' if state=='whole' else 'Change only structural damage. Same house silhouette, framing, source pixel scale, roof ridge, chimney position and untouched five glass centers as the edit target. Clearly damaged but standing: a single localized missing terracotta tile cluster on the left lower roof exposes dark rafters, one cracked/slightly splintered facade beam near the left front corner, a few adjacent chipped foundation stones and one small cracked front glass pane that keeps its warm center. Damage must read at 64x64 without random scattered holes, uniform black polka dots, red damage overlay, floating rubble, extra smoke/flames or a second unrelated house. Do not collapse, move or shrink the house, change the doorway/steps/roof perimeter, dim all windows or alter camera/lighting. Preserve true transparency and complete margins. Use broad connected damage cues, about 8x6 native pixels for the roof opening and 5x7 for facade wear; no many tiny cracks that vanish at reduction.')
        prompt=base+'\n\nHOUSE brief:\n'+brief('HOUSE').replace('{whole/hurt}',state)+'\n\nExact state/edit contract:\n'+spec
        references=[target]+(['docs/reference-sheet.png'] if state=='whole' else [])
        plans.append(dict(id=ident,state=state,prompt=prompt,references=references,transparent=True))
        (HERE/('0011-'+ident+'.prompt.txt')).write_text(prompt+'\n',encoding='utf-8',newline='\n')
    (HERE/'0011-plan.json').write_text(json.dumps(plans,indent=2)+'\n',encoding='utf-8',newline='\n')
    print('Saved two exact BASE + HOUSE edit prompts')

if __name__=='__main__':main()
