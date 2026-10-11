"""Correct an over-wide bust that clips the prescribed native canvas."""
from pathlib import Path
import json
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3];stem='tank-r2'
prompt='''Use case: precise-object-edit. Image1 is the tank bust EDIT TARGET. Correct ONLY the over-wide silhouette: make its complete head-and-shoulders bust a SQUARE visible13wide by13tall at native scale. Current wide shoulders make the source clip the16x16import. Narrow both shoulders and increase visible head/neck height within the square silhouette; keep bald heavy green head sunk on thick neck, broad shoulders relative to the other enemies and mustard vest over dark shirt. One flat cut bottom edge. Three-quarter turn to viewer LEFT, same rotten face, pale eyes, upper-left light and simple coloured dark outline. Do not change species, vest material, camera or facing; no full body, arms reaching out or weapon. Bold recognizable planes, no decoration. ONE bust with real transparent alpha, generous margins on all sides, nothing clipped. No border, UI panel, ground, shadow, glow, blood splashes, labels, blur or gradients. Image2 existing tank runtime sprite is IDENTITY AND MATERIAL ONLY; never draw the complete body.\n'''
args={'prompt':prompt,'referenced_image_paths':[str(HERE/'raw/tank-r1.png'),str(ROOT/'sprites/enemies/tank_walk_0.png')],'transparent_background':True}
for suffix,data in [('.request.json',json.dumps(args,indent=2)+'\n'),('.prompt.txt',prompt)]:
    path=HERE/f'raw/{stem}{suffix}';assert not path.exists();path.write_text(data,encoding='utf-8')
(HERE/'tank-fix-job.json').write_text(json.dumps({'stem':stem,'revision':2,'folder':HERE.name,'args':args},indent=2)+'\n')
