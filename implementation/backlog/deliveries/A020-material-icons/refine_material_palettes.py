"""Prevent unrelated colour ramps from entering the recorded mode-A material recipes."""
from pathlib import Path
import json
HERE=Path(__file__).resolve().parent
outline=['ink','ink_soft','night','night_light']
pools={'copper':['roof_dark','skin_dark','skin','skin_light'],'gold':['gold_dark','gold','gold_light','flame_hot'],'coal':['stone_dark','stone','stone_light'],'hardwood':['wood_dark','soil_dark','roof_dark','wood'],'hay':['gold_dark','gold','gold_light','grass_light','wood_dark'],'straw':['bone_dark','gold_light','bone','wood_dark']}
for asset,keys in pools.items():
    path=HERE/f'preview/{asset}-r1-recipes.json'
    if not path.exists():continue
    recipes=json.loads(path.read_text())
    for r in recipes:r['importer']['palette_keys']=outline+keys
    path.write_text(json.dumps(recipes,indent=2)+'\n')
    with (HERE/'review-log.txt').open('a') as log:log.write('2026-10-07 | '+asset+': constrain mode-A palette to the specified material planes and dark outlines, excluding unrelated orange flame, cloth or skin borrowing. Crop, scale, anchor and movement unchanged. Keys: '+','.join(outline+keys)+'\n')
