"""Record review invariants without claiming visual gait approval."""
from pathlib import Path
import hashlib
import json
from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[4]
DEST = HERE / 'diagonal-candidate'

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def main():
    baseline = json.loads((HERE / 'walk-baseline.json').read_text())
    assert len(baseline) == 192
    assert all(digest(ROOT / path) == expected for path, expected in baseline.items())
    before = json.loads((DEST / 'before-frame7-hashes.json').read_text())
    changed = [path for path, expected in before.items() if digest(DEST / path) != expected]
    assert changed == ['frames/up-left/07.png'], changed
    contract = json.loads((DEST / 'validation.json').read_text())
    palette = {tuple(color) for color in contract['palette_rgb']}
    outputs = {}
    for direction in ['up-left', 'up-right']:
        unique = set()
        for i in range(1, 9):
            rel = f'frames/{direction}/{i:02}.png'
            im = Image.open(DEST / rel).convert('RGBA')
            mask = Image.open(DEST / f'masks/{direction}/{i:02}.png').convert('L')
            assert im.size == (80, 80)
            assert set(im.getchannel('A').getdata()) == {0, 255}
            bounds = im.getbbox()
            assert bounds[3] == 72 and 63 <= bounds[3] - bounds[1] <= 65
            assert all(pixel[:3] in palette for pixel, mark in zip(im.getdata(), mask.getdata()) if mark)
            outputs[rel] = digest(DEST / rel)
            unique.add(im.tobytes())
        assert len(unique) == 8
    renderer = json.loads((DEST / 'runtime-capture-report.json').read_text())
    assert renderer['failures'] == 0 and len(renderer['sequences']) == 16
    assert all(s['walk_poses'] == 8 and s['render_fps'] == 30 for s in renderer['sequences'])
    clip = Image.open(DEST / 'before-after.gif')
    assert clip.n_frames == 8
    durations = []
    for i in range(8):
        clip.seek(i)
        durations.append(clip.info['duration'])
    assert durations == [100] * 8
    report = {'accepted_walk_hashes_unchanged': 192,
              'last_targeted_repair_changed_only': changed,
              'candidate_png_sha256': outputs,
              'renderer_checks': renderer['checks'], 'renderer_failures': 0,
              'gif_frame_durations_ms': durations,
              'runtime_integrated': False, 'motion_approval': 'pending user review'}
    (DEST / 'checks.json').write_text(json.dumps(report, indent=2) + '\n')
    # Consecutive production-renderer crops, at physical FHD size and 3x
    # nearest magnification. Source frames are captured 100ms apart.
    for scale in [1, 3]:
        sheet = Image.new('RGB', (180 * 8 * scale, 210 * 4 * scale), '#20292c')
        for row, (light, suffix) in enumerate([('day', 'north_west'), ('day', 'north_east'),
                                              ('night', 'north_west'), ('night', 'north_east')]):
            for phase in range(8):
                image = Image.open(DEST / f'runtime-captures/{light}_{suffix}_{phase+4:02}.png').convert('RGB')
                image = image.crop((38, 0, 218, 208)).resize((180 * scale, 208 * scale), Image.Resampling.NEAREST)
                sheet.paste(image, (phase * 180 * scale, row * 210 * scale))
        sheet.save(DEST / f'consecutive-renderer-{scale}x.png')
    print('Candidate source checks PASS; 192 accepted walking hashes unchanged; motion approval pending.')

if __name__ == '__main__':
    main()
