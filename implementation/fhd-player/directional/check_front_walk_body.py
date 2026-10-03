"""Regression for the actual screenshot-reported idle/walking bulk mismatch."""
from io import BytesIO
from pathlib import Path
import json
import subprocess
from PIL import Image
import build_review

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
BASELINE = '9c2e51ec'


def main():
    current = json.loads((HERE/'review-contract.json').read_text())['frames']
    old = json.loads(subprocess.check_output(['git','show',
        BASELINE+':implementation/fhd-player/directional/review-contract.json'], cwd=ROOT))['frames']
    by_id = {e['id']:e for e in old}
    before, preserved = [], 0
    for entry in current:
        prior = subprocess.check_output(['git','show',BASELINE+':'+by_id[entry['id']]['output']], cwd=ROOT)
        if entry['animation'] == 'walk_south':
            before.append(build_review.upper_body_dimensions(Image.open(BytesIO(prior))))
        else:
            assert (ROOT/entry['output']).read_bytes() == prior, ('unrelated sprite changed',entry['id'])
            preserved += 1
    replacement = build_review.assert_front_walk_body_scale(current)
    limit = max(e['upper_body_width'] for e in replacement['idle'])+1
    assert all(e['upper_body_width'] > limit for e in before), 'Actual reported broad walking body incorrectly accepted'
    assert preserved == 276
    build_review.assert_walking_head_scale(current)
    build_review.assert_lateral_run_readability(current)
    report = {'baseline_commit':BASELINE,'unchanged_other_native_frames':preserved,
              'previous':before,'replacement':replacement,
              'scope':'Screenshot pose walk_south_4; chest/arm/shoulder proportions versus all three idle poses'}
    (HERE/'walk-body-regression.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print('FRONT WALK BODY: all 8 reported broad poses rejected; revised anatomy matches idle.')
    print('PRESERVED: all 276 other native frames, including approved idle, every RUN and three other WALK directions.')


if __name__ == '__main__':
    main()
