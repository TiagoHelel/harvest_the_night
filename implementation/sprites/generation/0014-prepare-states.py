"""Prepare not-yet-submitted state prompts from the measured master candidates."""
from pathlib import Path
import json
HERE=Path(__file__).resolve().parent
plan=json.loads((HERE/'0014-plan.json').read_text())
for family,master in [('wall','whole-r2'),('fence','whole-r2')]:
    p=HERE/f'0014-{family}-hurt.prompt.txt'
    assert not (HERE/f'0014-{family}-hurt-call.json').exists(),'Do not overwrite submitted prompts'
    whole=(HERE/f'0014-{family}-{master}.prompt.txt').read_text() if (HERE/f'0014-{family}-{master}.prompt.txt').exists() else (HERE/f'0014-{family}-whole-r1.prompt.txt').read_text()
    text=whole.split('Generate exactly FOUR')[0]
    text=text.replace(f'{family}/whole',f'{family}/hurt').replace('Image 1: material/camera style reference','Image 1: exact accepted construction master; preserve physical proportions')
    text+='\nGenerate exactly FOUR modules in ONE horizontal row, matching Image 1 layout, camera and shared physical scale: isolated post; horizontal span; long narrow north-south span; collapsed rubble. Keep the master proportions, especially the long north-south span. No labels, ground or shadows. Author structural wear: '
    text+=('a cracked cap with a corner snapped off the post; a BROAD missing central masonry chunk in both spans exposing a jagged uneven course, while retaining the outer cut ends; same low collapsed stones.' if family=='wall' else 'a split post cap and visibly splintered shaft; lower horizontal rail snapped through its middle and upper rail bent; lengthwise beam broken through its middle; same collapsed timber. Keep outer beam cut ends intact.')
    text+=' Whole versus hurt must be recognizable at 16 native pixels without colored tint or health bars. No random pinholes, fire, extra posts, independent per-module enlargement or new construction design. Same complete source canvas dimensions and planted lower contact baseline as master. The vertical span must retain its long length; do not shorten it because a rail is broken.'
    p.write_text(text.strip(),encoding='utf-8',newline='\n')
    for x in plan:
        if x['id']==family and x['kind']=='hurt':x.update(layout='row',references=[f'assets/art_source/defences/{family}/{master}.png','docs/reference-sheet.png'])
(HERE/'0014-plan.json').write_text(json.dumps(plan,indent=2)+'\n',encoding='utf-8',newline='\n')

p=HERE/'0014-fence-whole-r2.prompt.txt'
if not p.exists():
    t=(HERE/'0014-fence-whole-r1.prompt.txt').read_text()
    t+='\nCRITICAL: the long north-south module is a beam lying along the ground Y direction, NOT a tall pole. Make it EXTREMELY LONG: its total length is at least 1.7 times the entire WIDTH of the horizontal span. A 500-pixel-wide east-west span requires a 850-pixel-long narrow north-south beam. Use a taller source canvas to leave it unclipped; arrange all four modules in a horizontal row on one ground baseline. Leave the horizontal span and post unchanged. Keep wood gaps and cut ends clean. No upright pair of posts in the third module.\n'
    p.write_text(t.strip(),encoding='utf-8',newline='\n')
for family,kind,reason in [('fence','whole','North-south piece depicts a pair of upright posts instead of longitudinal rails and is too short at the common horizontal span scale.'),('fence','whole-r1','Longitudinal beam is still too short to cover an occupied-cell connection at the common scale. Request only length/camera correction.')]:
    p=HERE/f'0014-{family}-{kind}-call.json'
    d=json.loads(p.read_text());d['decision']='Rejected: '+reason;p.write_text(json.dumps(d,indent=2)+'\n',encoding='utf-8',newline='\n')
print('Prepared wall/fence hurt prompts against selected whole candidates; targeted fence length revision')
