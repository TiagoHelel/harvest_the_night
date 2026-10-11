"""Targeted simplification after inspecting the actual 16px and10px icon cuts."""
from pathlib import Path
import json
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3];jobs=[]
descriptions={
'auto_crossbow':'Keep ONLY the wooden crossbow bow, string, thick bolt pointing upper right, and its short central mounting stub. REMOVE the complete timber trestle, every support leg and every stone foot block. Wide bow silhouette dominates: about14wide9high native,8wide5high compact. Bold two wooden limbs and clear string triangle, large arrow tip. No full tower or tall framework.',
'flame_tower':'Keep ONLY the squat RED fuel tank and short BRASS nozzle pipe with ONE SMALL flame tongue at its upper-right tip. REMOVE the timber trestle, all support legs, all stone feet and framework. The tank must dominate the silhouette and be roof-red, not wood orange. Brass pipe has ochre-gold large planes. Wide compact silhouette about14wide10high native,8wide6high compact. No full tower or tall framework.'}
for asset,description in descriptions.items():
    stem=asset+'-r2'
    prompt='Use case: precise-object-edit. Image1 is the exact edit target. '+description+' Keep the same camera, light from upper left, material identity and coloured dark outlines. Simplify all decoration into two or three readable flat planes so the object remains recognizable on a10x10 canvas. ONE isolated object, true transparent alpha, generous empty margins. No ground, shadow, halo, glow, particles, labels or background. Crisp square pixels, no gradients or blurred edges. Image2 approved wood icon is STYLE ONLY, not the subject.\n'
    args={'prompt':prompt,'referenced_image_paths':[str(HERE/f'raw/{asset}-r1.png'),str(ROOT/'assets/art_source/ui/wood.png')],'transparent_background':True}
    for suffix,data in [('.prompt.txt',prompt),('.request.json',json.dumps(args,indent=2)+'\n')]:
        path=HERE/f'raw/{stem}{suffix}';assert not path.exists();path.write_text(data)
    jobs.append({'stem':stem,'revision':2,'args':args,'folder':HERE.name})
(HERE/'head-fix-jobs.json').write_text(json.dumps(jobs,indent=2)+'\n')
