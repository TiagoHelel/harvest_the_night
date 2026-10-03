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
BASELINE = 'd5a27f7d'
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
    return {'direction':direction, 'phase':phase,
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
    assert not all(e['opposite_leg_material_pass'] for e in previous), 'Old same-leg control incorrectly accepted'
    report = {'baseline_commit':BASELINE, 'unchanged_other_native_frames':preserved,
              'scope':'Boot materials and contact/flight; subjective motion still needs user review',
              'previous_same_leg_control':previous, 'replacement':replacement}
    (HERE / 'run-gait-regression.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    print('RUN GAIT GUARD: sixteen contact/flight and opposite-leg phases pass; previous same-leg control fails.')
    print('PRESERVATION GUARD: other 268 native frames byte-identical to ' + BASELINE + '.')


if __name__ == '__main__':
    main()
