"""Keep milk and wool in their specified cream material ramps after mode-A reduction."""
from pathlib import Path
import json
HERE=Path(__file__).resolve().parent
pools={'milk':['ink','ink_soft','night','bone','bone_dark','stone_light','roof','roof_dark'],'wool':['ink','ink_soft','night','bone','bone_dark','gold_light']}
for asset,keys in pools.items():
    path=HERE/f'preview/{asset}-r1-recipes.json'
    if not path.exists():continue
    recipes=json.loads(path.read_text())
    for r in recipes:r['importer']['palette_keys']=keys
    path.write_text(json.dumps(recipes,indent=2)+'\n')
    with (HERE/'review-log.txt').open('a') as log:log.write('2026-10-07 | '+asset+': palette subset avoids unrelated orange skin/flame borrowing in cream material; keep geometry and alpha unchanged. Keys: '+','.join(keys)+'\n')
