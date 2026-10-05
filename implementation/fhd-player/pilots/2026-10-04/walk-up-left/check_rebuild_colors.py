"""Check diagnostic root ordering and opposite contacts before denim restoration."""
from pathlib import Path
import json
import sys
from PIL import Image

ROOT = Path(__file__).resolve().parent
SOURCE = ROOT.parents[4] / 'assets/art_source/player-fhd/pilots/2026-10-04/walk-up-left'
name = sys.argv[1] if len(sys.argv) > 1 else 'rebuild-tracking-r5.png'
im = Image.open(SOURCE/name).convert('RGBA')
cols = [round(i*im.width/4) for i in range(5)]
rows = [0, round(im.height/2), im.height]
phases = []
for i in range(8):
    c, r = i%4, i//4
    cell = im.crop((cols[c],rows[r],cols[c+1],rows[r+1]))
    colors = {'near_cyan':[], 'far_pink':[]}
    for y in range(cell.height):
        for x in range(cell.width):
            red,green,blue,alpha = cell.getpixel((x,y))
            if alpha < 128: continue
            if green > 65 and blue > 65 and red < green*.45 and green > blue*.80:
                colors['near_cyan'].append((x,y))
            elif red > 100 and red > green*1.5 and blue > red*.35 and green < blue*.80:
                colors['far_pink'].append((x,y))
    metrics = {}
    for key,points in colors.items():
        if not points:
            metrics[key] = None
            continue
        top, bottom = min(y for x,y in points), max(y for x,y in points)
        upper = [(x,y) for x,y in points if y < top + max(6,round((bottom-top)*.09))]
        boot = [(x,y) for x,y in points if y > bottom - max(6,round((bottom-top)*.13))]
        metrics[key] = {'root_x':sum(x for x,y in upper)/len(upper),
                        'root_y':sum(y for x,y in upper)/len(upper),
                        'boot_x':sum(x for x,y in boot)/len(boot),
                        'boot_y':sum(y for x,y in boot)/len(boot),
                        'colored_pixels':len(points)}
    present = all(metrics.values())
    phases.append({'phase':i+1, 'color_metrics':metrics,
        'cyan_root_left_of_pink': bool(present and metrics['near_cyan']['root_x'] < metrics['far_pink']['root_x'])})
roots_ok = all(p['cyan_root_left_of_pink'] for p in phases)
contacts_ok = False
if all(p['color_metrics']['near_cyan'] and p['color_metrics']['far_pink'] for p in phases):
    first, opposite = [phases[i]['color_metrics'] for i in (0,4)]
    contacts_ok = (first['near_cyan']['boot_x'] < first['far_pink']['boot_x']
                   and opposite['near_cyan']['boot_x'] > opposite['far_pink']['boot_x'])
report = {'source':name, 'result':'PASS' if roots_ok and contacts_ok else 'FAIL',
          'all_eight_roots_consistent':roots_ok, 'opposite_boot_contacts_1_5':contacts_ok,
          'phases':phases,
          'limitations':['Color centroids check roots/contacts, not full anatomical connectedness.',
                         'Occluded leg chains and frame3/4 knee unfolding require visual inspection.']}
out = ROOT/f'{Path(name).stem}-color-check.json'
out.write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'result':report['result'], 'root_order':[p['cyan_root_left_of_pink'] for p in phases],
                  'opposite_contacts':contacts_ok},indent=2))
sys.exit(0 if report['result']=='PASS' else 1)
