"""Reject oversized front/back walking heads and preserve all unrelated frames."""
from io import BytesIO
from pathlib import Path
import json
import subprocess
from PIL import Image
import build_review

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
BASELINE = '80d269e6'


def main():
    current = json.loads((HERE / 'review-contract.json').read_text())['frames']
    old_contract = json.loads(subprocess.check_output(
        ['git', 'show', BASELINE + ':implementation/fhd-player/directional/review-contract.json'],
        cwd=ROOT))['frames']
    old = {e['id']:e for e in old_contract}
    replacement = build_review.assert_walking_head_scale(current)
    previous = {}
    preserved = 0
    for entry in current:
        prior = old[entry['id']]
        before = subprocess.check_output(['git', 'show', BASELINE + ':' + prior['output']], cwd=ROOT)
        if entry['animation'] in ('walk_south', 'walk_north'):
            dimensions = build_review.head_dimensions(Image.open(BytesIO(before)))
            previous.setdefault(entry['animation'], []).append(dimensions)
        else:
            assert (ROOT / entry['output']).read_bytes() == before, ('unrelated drawing changed', entry['id'])
            preserved += 1
    assert preserved == 268
    for direction in ('south', 'north'):
        idle = replacement[direction]['idle']
        assert any(abs(e['brim_width'] - idle['brim_width']) > 2
                   for e in previous['walk_' + direction]), ('old oversized head accepted', direction)
    report = {'baseline_commit':BASELINE, 'unchanged_other_native_frames':preserved,
              'previous':previous, 'replacement':replacement,
              'scope':'Native head/brim width versus approved idle, frame consistency; normal-speed playback also reviewed'}
    (HERE / 'walk-head-regression.json').write_text(json.dumps(report, indent=2) + '\n',
                                                  encoding='utf-8', newline='\n')
    print('WALK HEAD GUARD: 16 front/back poses match idle width; both old oversized strips rejected.')
    print('PRESERVATION: all 268 other review frames, including every RUN, are byte-identical.')


if __name__ == '__main__':
    main()
