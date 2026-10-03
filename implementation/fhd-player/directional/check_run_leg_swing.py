"""Reject the reported ambiguous run, including intermediate trouser ownership."""
from io import BytesIO
from pathlib import Path
import json
import subprocess
from PIL import Image
import build_review
import check_lateral_run

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
BASELINE = 'c876a33'


def main():
    frames = json.loads((HERE / 'review-contract.json').read_text(encoding='utf-8'))['frames']
    prior = json.loads(subprocess.check_output([
        'git', 'show', BASELINE + ':implementation/fhd-player/directional/review-contract.json'],
        cwd=ROOT))['frames']
    old_entries = {e['id']:e for e in prior}
    before, after = {'east':{}, 'west':{}}, {'east':{}, 'west':{}}
    preserved, changed = 0, []
    for entry in frames:
        content = (ROOT / entry['output']).read_bytes()
        old = subprocess.check_output(['git', 'show', BASELINE + ':' + old_entries[entry['id']]['output']],
                                      cwd=ROOT)
        if entry['animation'] in ('run_east', 'run_west'):
            direction = entry['animation'].split('_')[1]
            before[direction][entry['frame']] = Image.open(BytesIO(old)).convert('RGBA')
            after[direction][entry['frame']] = Image.open(BytesIO(content)).convert('RGBA')
            measure = check_lateral_run.measure(after[direction][entry['frame']], direction, entry['frame'])
            assert measure['opposite_leg_material_pass'] and measure['contact_or_flight_pass'], measure
            if entry['frame'] == 2:
                assert content == old, ('retained correct passing pose changed', entry['id'])
        else:
            assert content == old, ('unrelated art changed', entry['id'])
        if content == old:
            preserved += 1
        else:
            changed.append(entry['id'])
    previous = {d:build_review.lateral_run_readability(images, d) for d, images in before.items()}
    replacement = build_review.assert_lateral_run_readability(frames)
    assert all(not e['pass'] for e in previous.values()), 'Actual reported run incorrectly passes readability guard'
    assert preserved == 270 and len(changed) == 14
    build_review.assert_lateral_knee_exchange(frames)
    build_review.assert_walking_head_scale(frames)
    report = {'baseline_commit':BASELINE, 'preserved_native_frames':preserved, 'changed_native_frames':changed,
              'retained_phases':['run_east_2', 'run_west_2'],
              'previous':previous, 'replacement':replacement,
              'scope':'Foreground recovery, opposite sleeve swing and distinct contact boot material; actual normal-speed renderer review also required'}
    (HERE / 'run-leg-swing-regression.json').write_text(json.dumps(report, indent=2) + '\n',
                                                       encoding='utf-8', newline='\n')
    print('RUN LEG SWING: both actual reported loops rejected; 14 corrected poses and 2 retained passing poses pass.')
    print('PRESERVED: 270 native frames, including all corrected walking heads and all other directions/activities.')


if __name__ == '__main__':
    main()
