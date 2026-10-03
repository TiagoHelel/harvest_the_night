"""Reject the previous same-leg run and verify real contact/flight poses."""
from io import BytesIO
from pathlib import Path
import json
import subprocess
import sys

import numpy as np
from PIL import Image

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
BASELINE = '0cbb4a27'
sys.path.insert(0, str(ROOT / 'tools'))
from palette import COLOURS


def measure(image, direction, phase):
    pixels = np.array(image.convert('RGBA'))
    yy, xx = np.indices(pixels.shape[:2])
    leather = np.zeros(pixels.shape[:2], dtype=bool)
    for material in ('soil_dark', 'wood_dark', 'wood', 'wood_light'):
        leather |= (pixels[:, :, :3] == COLOURS[material]).all(2)
    foot = leather & (yy >= 72) & (pixels[:, :, 3] > 0)
    left, right = foot & (xx < 48), foot & (xx >= 48)
    luminance = pixels[:, :, :3].astype(np.int32).sum(2)
    delta = float(luminance[right].mean() - luminance[left].mean())
    expected = (1 if direction == 'east' else -1) * (1 if phase in (0,1,6,7) else -1)
    bottom = image.getbbox()[3]
    flying = phase in (2,3,6,7)
    near = ((pixels[:,:,:3] == COLOURS['cloth']).all(2)
            | (pixels[:,:,:3] == COLOURS['cloth_light']).all(2))
    near &= (yy >= 70) & (yy <= 80) & (pixels[:,:,3] > 0)
    return {'direction':direction, 'phase':phase,
            'foreground_knee_x':float(xx[near].mean()),
            'boot_brightness_right_minus_left':delta,
            'opposite_leg_material_pass':bool(delta * expected > 0),
            'ground_clearance_native_px':88 - bottom,
            'contact_or_flight_pass':bottom < 88 if flying else bottom == 88}


def main():
    frames = json.loads((HERE / 'review-contract.json').read_text())['frames']
    previous, replacement = [], []
    preserved = 0
    for entry in frames:
        content = (ROOT / entry['output']).read_bytes()
        old = subprocess.check_output(['git', 'show', BASELINE + ':' + entry['output']], cwd=ROOT)
        if entry['animation'] in ('run_east','run_west'):
            direction = entry['animation'].split('_')[1]
            previous.append(measure(Image.open(BytesIO(old)), direction, entry['frame']))
            replacement.append(measure(Image.open(BytesIO(content)), direction, entry['frame']))
        else:
            assert content == old, ('unrelated frame changed', entry['id'])
            preserved += 1
    assert preserved == 268
    assert all(e['opposite_leg_material_pass'] and e['contact_or_flight_pass'] for e in replacement)
    def knee_motion(samples):
        result = {}
        for direction in ('east','west'):
            x = {e['phase']:e['foreground_knee_x'] for e in samples if e['direction']==direction}
            sign = 1 if direction=='east' else -1
            contact, passing = sign*(x[0]-x[4]), sign*(x[6]-x[2])
            result[direction] = {'contact_exchange_px':contact, 'passing_exchange_px':passing,
                                 'pass':contact>=4 and passing>=5}
        return result
    old_knees, new_knees = knee_motion(previous), knee_motion(replacement)
    assert all(e['pass'] for e in new_knees.values()), new_knees
    assert not all(e['pass'] for e in old_knees.values()), 'Reported bad run incorrectly accepted'
    # The actual reported baseline PASSED the old boot-color guard. It must now
    # fail a geometric foreground-trouser test that no boot recoloring can fix.
    assert all(e['opposite_leg_material_pass'] for e in previous)
    report = {'baseline_commit':BASELINE, 'unchanged_other_native_frames':preserved,
              'scope':'Foreground trouser/knee exchange, boot material and contact/flight; visual playback still reviewed',
              'previous_color_guard_false_positive':True,
              'previous_knee_motion':old_knees,'replacement_knee_motion':new_knees,
              'previous_same_leg_control':previous, 'replacement':replacement}
    (HERE / 'run-gait-regression.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    print('RUN GAIT GUARD: sixteen contact/flight/material phases pass; both foreground knee paths exchange.')
    print('NEGATIVE CONTROL: actual reported baseline passes old color guard but fails the new knee-motion test.')
    print('PRESERVATION GUARD: other 268 native frames byte-identical to ' + BASELINE + '.')


if __name__ == '__main__':
    main()
