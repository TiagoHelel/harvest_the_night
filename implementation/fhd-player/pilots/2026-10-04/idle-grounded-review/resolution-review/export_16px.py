"""Export the chosen coarse pixel density without changing game assets."""
from pathlib import Path
import hashlib
import json
from PIL import Image

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[5]
DEST = HERE / '16px-assets'
DIRECTIONS = ['down', 'right', 'up', 'left', 'down-right', 'up-right', 'up-left', 'down-left']

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def export():
    sources = []
    for direction in DIRECTIONS:
        for index in range(1, 9):
            sources.append((f'walk/{direction}/{index:02}.png', ROOT / f'assets/art_source/player-fhd/walk-blue/frames/{direction}/{index:02}.png'))
        sources.append((f'idle/{direction}.png', ROOT / f'assets/art_source/player-fhd/idle-blue-grounded/frames/{direction}.png'))
    entries = []
    for name, source in sources:
        original = Image.open(source).convert('RGBA')
        assert original.size == (80, 80)
        native = original.resize((20, 20), Image.Resampling.NEAREST)
        runtime = native.resize((80, 80), Image.Resampling.NEAREST)
        assert set(native.getchannel('A').get_flattened_data()) <= {0, 255}
        assert set(native.get_flattened_data()) <= set(original.get_flattened_data())
        outputs = {}
        for folder, image in [('native-20', native), ('runtime-80', runtime)]:
            output = DEST / folder / name
            output.parent.mkdir(parents=True, exist_ok=True)
            image.save(output)
            assert Image.open(output).convert('RGBA').tobytes() == image.tobytes()
            outputs[folder] = {'path': output.relative_to(ROOT).as_posix(), 'sha256': sha(output)}
        entries.append({'source': source.relative_to(ROOT).as_posix(), 'source_sha256': sha(source),
                        'name': name, 'native_content_bounds': native.getbbox(), 'outputs': outputs})
    baseline = json.loads((HERE.parent / 'walk-baseline.json').read_text())
    assert all(sha(ROOT / name) == expected for name, expected in baseline.items())
    metadata = {'date': '2026-10-05', 'selection': 'User chose the approximately16px character detail test',
                'method': 'NEAREST80x80 to20x20, then integer4x NEAREST to80x80',
                'source_body_height_px': 64, 'chosen_body_height_px': 16,
                'physical_body_height_at_FHD_px': 128,
                'native_canvas_wh': [20, 20], 'native_pivot_xy': [10, 18],
                'runtime_canvas_wh': [80, 80], 'runtime_pivot_xy': [40, 72], 'runtime_draw_scale': .5,
                'walk_frame_count_per_direction': 8, 'walk_seconds': .1,
                'idle_policy': 'Independent neutral idle; never hold a walking frame as idle',
                'palette_policy': 'Exact existing source colors; no recoloring or dithering',
                'runtime_integrated': False, 'walking_geometry_changed': False,
                'rejected_diagonal_candidates_used': False, 'assets': entries}
    DEST.mkdir(exist_ok=True)
    (DEST / 'contract.json').write_text(json.dumps(metadata, indent=2) + '\n')
    print('16px handoff exported:64 walk +8 grounded idle; native20/runtime80; production sprites unchanged.')

if __name__ == '__main__':
    export()
