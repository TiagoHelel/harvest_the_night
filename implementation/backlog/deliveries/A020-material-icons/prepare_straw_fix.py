"""Correct the sheaf's orientation after comparing it with the wheat icon."""
from pathlib import Path
import json
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3];stem='straw-r2'
prompt='''Use case: precise-object-edit. Image1 is the straw sheaf edit target. Change ONLY the pose and silhouette: lay this loose tied sheaf HORIZONTALLY left to right, not on the45degree wheat/log diagonal. Long pale stalks with flared ends at both LEFT and RIGHT, one narrow dark timber twine tie at the centre. Overall native14wide6-8high, compact8wide4-5high. No grain heads or leaves, not a rectangular hay bale. Keep the same pale bone/bone_dark/gold_light material, coloured dark outline, simple2-3flatplanes, neutral upper-left light. ONE complete unclipped isolated sheaf centred on true transparent alpha. Image2 wood icon is STYLE ONLY. No background, ground, shadow, halo, labels, blur, gradients or additional objects.\n'''
args={'prompt':prompt,'referenced_image_paths':[str(HERE/'raw/straw-r1.png'),str(ROOT/'assets/art_source/ui/wood.png')],'transparent_background':True}
for suffix,data in [('.request.json',json.dumps(args,indent=2)+'\n'),('.prompt.txt',prompt)]:
    path=HERE/f'raw/{stem}{suffix}';assert not path.exists();path.write_text(data)
(HERE/'straw-fix-job.json').write_text(json.dumps({'stem':stem,'revision':2,'folder':HERE.name,'args':args},indent=2)+'\n')
