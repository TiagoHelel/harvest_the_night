"""Publish a selected hand candidate in existing approval pages and provenance."""
from pathlib import Path
import hashlib
import json
import re
from PIL import Image

ROOT=Path(__file__).resolve().parent
REPO=ROOT.parents[3]
SOURCE=REPO/'assets/art_source/player-fhd/pilots/2026-10-04'
selection=json.loads((ROOT/'hand-rebuild-selection.json').read_text())
calls=json.loads((ROOT/'hand-rebuild-calls.json').read_text())
status=json.loads((ROOT/'directions-status.json').read_text())
for direction,selected in selection.items():
    folder=ROOT/f'walk-{direction}'; key=direction.replace('-','_')
    generation=json.loads((folder/'generation.json').read_text())
    for call in calls[direction]:
        source=SOURCE/f'walk-{direction}'/call['source']
        call.update(source_sha256=hashlib.sha256(source.read_bytes()).hexdigest(),
                    source_dimensions=list(Image.open(source).size),date='2026-10-05',
                    transparent_background=True,tool='built-in ImageGen')
        if not any(c.get('source')==call['source'] for c in generation['calls']):
            generation['calls'].append(call)
    generation.update(status='awaiting user visual review: hand and wrist rebuild',selected_source=selected,
                      selected_preview='up-diagonal-hands-r15.gif')
    generation['hand_rebuild']={'date':'2026-10-05','baseline':'before-hand-rebuild',
        'feedback':'Hands still look strange in both upper diagonals.',
        'edit_scope':'Hand/wrist silhouettes and connected forearm trajectories; no runtime integration.',
        'workflow':'Native reference, approved DOWN hand proportions, relaxed-wrist shoulder/elbow guide.',
        'limitations':'Generated edits are not byte-exact outside hands within the edited poses; scope checks are not anatomy proof.'}
    (folder/'generation.json').write_text(json.dumps(generation,indent=2)+'\n')
    entry=status[f'walk_{key}']
    candidate=f'walk-{direction}/{selected.removesuffix(".png")}'
    if entry['candidate']!=candidate: entry['rejected_candidate']=entry['candidate']
    entry.update(status='awaiting_approval',candidate=candidate,
                 preview='up-diagonal-hands-r15.gif',diagnostic='up-diagonal-hands-before-after-r15.gif',
                 user_feedback='Hands still look strange; rebuild them.',
                 feedback_addressed='Compact palms, narrower wrists and relaxed downward forearm/hand angles.',
                 review_limit=('Far left arm travel remains subtle; hand and gait approval pending.' if direction=='up-right'
                               else 'Awaiting user visual approval at actual preview size.'),date='2026-10-05')
    html=(folder/'index.html').read_text(encoding='utf-8')
    html=html.replace('full-arms-r13','hands-r15')
    html=html.replace('up-diagonal-full-arms-r13.gif','up-diagonal-hands-r15.gif')
    html=html.replace('up-diagonal-full-arms-before-after-r13.gif','up-diagonal-hands-before-after-r15.gif')
    html=html.replace('all-walk-directions-full-arms-r13.gif','all-walk-directions-hands-r15.gif')
    html=re.sub(r'<details><summary>Track both arm identities</summary>.*?</details>\n','',html,flags=re.S)
    html=html.replace('Farmer - upper diagonal arm review','Farmer - hand and wrist review')
    html=html.replace('Upper diagonal arms','Upper diagonal hands')
    html=html.replace('Both arms revised across all eight poses.','Hands and wrists rebuilt across all eight poses.')
    html=html.replace(' &middot; UP-LEFT near arm7-to8 still rises briskly.','')
    (folder/'index.html').write_text(html,encoding='utf-8')
(ROOT/'directions-status.json').write_text(json.dumps(status,indent=2)+'\n')
(ROOT/'hand-rebuild-calls.json').write_text(json.dumps(calls,indent=2)+'\n')
focused=html.replace('../up-diagonal','up-diagonal').replace('../all-walk','all-walk').replace('../walk-up-','walk-up-')
(ROOT/'up-diagonal-arms.html').write_text(focused,encoding='utf-8')
