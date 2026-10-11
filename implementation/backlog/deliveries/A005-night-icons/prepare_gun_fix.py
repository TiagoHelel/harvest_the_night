"""Remove the unwanted tall support from the gun-head icon source."""
from pathlib import Path
import json
HERE=Path(__file__).resolve().parent
stem='gun_tower-r2';prompt='''Precise-object-edit for one tiny inventory icon. Image1 is the EDIT TARGET. Remove the whole timber trestle, four support legs and stone foot blocks from the candidate. Keep ONLY the dark iron gun barrel, compact timber rotating turret HEAD directly underneath it, and a tiny central timber mounting stub no longer than one-third the head height. The native10x10 preview of this candidate showed a whole tower and lost the gun silhouette; the new icon must be a wide horizontal gun head whose barrel is its dominant readable form. Keep the same upper-right barrel orientation, same upper-left light, colours and icon style. Wide silhouette about14wide x8-10high when imported to16canvas, or8wide x5-6high in10canvas. Dark iron barrel long and bold with a pale top plane and visible muzzle. Simple wood head beneath, NO legs, no tower framework, no ground or masonry, no extra ammo/weapons. ONE complete isolated object centred on true alpha, generous margins, coloured1pixel outline, only2or3 large material planes; no fine texture, blur, gradient, shadow, panel, labels or text. Image2 wood icon is outline/colour STYLE only, not the subject.\n'''
args={'prompt':prompt,'referenced_image_paths':[str(HERE/'raw/gun_tower-r1.png'),str(HERE.parents[3]/'assets/art_source/ui/wood.png')],'transparent_background':True}
for suffix,data in [('.prompt.txt',prompt),('.request.json',json.dumps(args,indent=2)+'\n')]:
    p=HERE/f'raw/{stem}{suffix}';assert not p.exists();p.write_text(data)
(HERE/'gun-fix-job.json').write_text(json.dumps({'stem':stem,'revision':2,'args':args},indent=2)+'\n')
