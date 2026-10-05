"""Export generated DOWN-LEFT art and an isolated eight-direction review."""
from pathlib import Path
import hashlib
import json
import sys
from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parent
PILOT = HERE.parent
sys.path.insert(0, str(PILOT))
from full_arm_cycle_export import sample
from build_hand_rebuild_review import caption, save_gif

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def build():
    frames, sampling = sample('down-left', 'materials-r1.png', 'frames')
    colored, tracking = sample('down-left', 'tracking-eight.png', 'tracking-frames')
    original = Image.open(PILOT / 'walk-down/frames/walk-down-01.png').convert('RGBA')
    normal, slow = [], []
    for i, frame in enumerate(frames):
        opposite = Image.open(PILOT / f'walk-down-right/frames/walk-down-right-{i+1:02}.png').convert('RGBA')
        canvas = Image.new('RGBA', (880, 450), '#20292c')
        draw = ImageDraw.Draw(canvas)
        caption(draw, (22, 18), 'WALK DOWN-LEFT / 8 FRAMES / 10 FPS', 21)
        for x, image, size, label in [(25, original, 160, 'APPROVED DOWN | 1x'),
                                      (230, frame, 160, 'DOWN-LEFT | 1x'),
                                      (490, frame, 320, 'DETAIL | 2x')]:
            caption(draw, (x, 70), label, 16)
            canvas.alpha_composite(image.resize((size, size), Image.Resampling.NEAREST),
                                   (x, 108 if size == 160 else 92))
        caption(draw, (25, 315), '80px canvas / artwork ~64px / integer 2x', 14)
        caption(draw, (25, 347), 'Preview only - awaiting visual approval', 14)
        caption(draw, (25, 388), f'Frame {i+1:02} / 08', 17)
        normal.append(canvas.convert('RGB'))
        detail = Image.new('RGBA', (900, 395), '#20292c')
        dd = ImageDraw.Draw(detail)
        for x, im, label in [(20, opposite, 'DOWN-RIGHT REFERENCE'), (450, frame, 'DOWN-LEFT DIRECTION EDIT')]:
            caption(dd, (x, 15), label, 17)
            detail.alpha_composite(im.resize((320, 320), Image.Resampling.NEAREST), (x, 45))
        caption(dd, (20, 370), f'Frame {i+1} / 8 / slow comparison / awaiting review', 15)
        slow.append(detail.convert('RGB'))
    save_gif(normal, HERE / 'walk-down-left.gif', 100)
    save_gif(slow, HERE / 'walk-down-left-slow.gif', 200)
    normal[0].save(HERE / 'poster.png')
    strip = Image.new('RGBA', (1280, 205), '#303a3e')
    for i, frame in enumerate(frames):
        strip.alpha_composite(frame.resize((160, 160), Image.Resampling.NEAREST), (i*160, 30))
        caption(ImageDraw.Draw(strip), (i*160+12, 8), f'FRAME {i+1}', 15)
    strip.convert('RGB').save(HERE / 'contact-sheet.png')
    directions = ['down', 'right', 'up', 'left', 'down-right', 'up-right', 'up-left', 'down-left']
    all_frames = {}
    selections = {}
    for direction in directions:
        folder = PILOT / f'walk-{direction}/frames'
        if direction == 'up-right':
            folder = PILOT / 'selected-UR03-UL03/UR03/revisions/boot4-r4/frames'
        if direction == 'up-left':
            folder = PILOT / 'selected-UR03-UL03/UL03/frames'
        paths = sorted(folder.glob('*.png'))
        assert len(paths) == 8, (direction, len(paths))
        selections[direction] = [{'path': str(p.relative_to(PILOT)).replace('\\', '/'),
                                  'sha256': sha(p)} for p in paths]
        all_frames[direction] = [Image.open(p).convert('RGBA') for p in paths]
    (HERE / 'aggregate-selection.json').write_text(json.dumps(selections, indent=2) + '\n')
    combined = []
    for i in range(8):
        canvas = Image.new('RGBA', (1440, 280), '#20292c')
        draw = ImageDraw.Draw(canvas)
        caption(draw, (20, 12), 'EIGHT WALK DIRECTIONS / 8 FRAMES / 10 FPS', 21)
        for j, direction in enumerate(directions):
            x = j*180
            caption(draw, (x+12, 55), direction.upper(), 16)
            canvas.alpha_composite(all_frames[direction][i].resize((160, 160), Image.Resampling.NEAREST), (x, 82))
            caption(draw, (x+12, 245), 'IN REVIEW' if direction in ['down-right', 'down-left'] else 'APPROVED', 13)
        combined.append(canvas.convert('RGB'))
    save_gif(combined, HERE / 'all-eight-walk-directions.gif', 100)
    combined[0].save(HERE / 'all-eight-poster.png')
    baseline = json.loads((HERE / 'baseline.json').read_text())
    assert len(baseline) == 72
    assert all(sha(PILOT / name) == value for name, value in baseline.items())
    sampling.update(status='awaiting user visual approval', date='2026-10-05',
        frames=8, fps=10, fhd_display_scale=2, gif_duration_ms=100,
        slow_duration_ms=200, existing_native_frames_unchanged=72,
        rejected_tracking_sampling=tracking, runtime_integrated=False,
        limits='Format, scope and unique drawings do not prove anatomy, smoothness or user approval.')
    sampling['frame_file_sha256'] = {p.name: sha(p) for p in sorted((HERE / 'frames').glob('*.png'))}
    (HERE / 'validation.json').write_text(json.dumps(sampling, indent=2) + '\n')
    status_path = PILOT / 'directions-status.json'
    status = json.loads(status_path.read_text())
    status['walk_down_left'].update(status='awaiting_approval', frames=8, fps=10,
        review='walk-down-left/index.html', selected_source='materials-r1.png',
        workflow='Rotate/contact probes; reject colored transitions and full colored cycle; built-in per-pose direction edit of existing opposite-diagonal eight-phase animation.',
        tracking_gate='FAILED: diagnostic attempt rejected; final source does not use its poses.')
    status_path.write_text(json.dumps(status, indent=2) + '\n')
    html = '''<!doctype html><html lang="en"><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>DOWN-LEFT walk review</title><style>
body{background:#182426;color:#e9e3cf;font:17px Consolas,monospace;margin:20px}
h1{font-size:23px}a{color:#98dcd6}img{image-rendering:pixelated}
.overflow{overflow-x:auto;margin:20px 0}.preview{width:880px;height:450px}
.frames{display:flex;gap:20px}.frames img{width:320px;height:320px;background:#303a3e}
button{background:#344b48;color:#e9e3cf;border:1px solid #75958d;padding:12px;font:inherit;margin:16px 8px 16px 0}
details{margin:28px 0}summary{cursor:pointer}p{line-height:1.5}
</style><h1>DOWN-LEFT — eighth direction</h1>
<p>Eight frames at 10 FPS. Original DOWN shown at the same integer 2x scale.</p>
<div class="overflow"><img class="preview" src="walk-down-left.gif?v=dl-r1" alt="Down-left walk beside approved down proportions"></div>
<details><summary>Inspect individual frames</summary>
<button id="previous">Previous</button><button id="next">Next</button><span id="number">Frame 1 / 8</span>
<div class="overflow frames"><div>DOWN-LEFT<br><img id="final" src="frames/walk-down-left-01.png"></div></div></details>
<details><summary>Slow playback against down-right reference</summary><div class="overflow">
<img src="walk-down-left-slow.gif" width="900" height="395" alt="Slow down-right reference and down-left comparison"></div></details>
<details><summary>Rejected leg-color diagnostic</summary><p>This attempt failed limb ownership and was not used as the final pose source.</p>
<div class="overflow"><img src="tracking-frames-native.png" width="960" height="480" alt="Rejected eight-pose diagnostic, not final art"></div></details>
<details><summary>All eight walking directions</summary><p>UR03 boot4-r4 and approved UL03 selected. DOWN-RIGHT arm repair and DOWN-LEFT await review.</p>
<div class="overflow"><img src="all-eight-walk-directions.gif" width="1440" height="280" alt="All eight directions horizontally"></div></details>
<details><summary>Eight-frame contact sheet</summary><div class="overflow"><img src="contact-sheet.png" width="1280" height="205"></div></details>
<p>Preview only — awaiting your approval.</p>
<p><a href="../selected-UR03-UL03/index.html?v=approved-r4">Approved UR03 / UL03 review</a> ·
<a href="validation.json">Validation and source sampling</a></p>
<script>
let current=0;
function show(delta){current=(current+delta+8)%8;const n=String(current+1).padStart(2,'0');
document.getElementById('number').textContent=`Frame ${current+1} / 8`;
document.getElementById('final').src=`frames/walk-down-left-${n}.png`;
}
document.getElementById('previous').onclick=()=>show(-1);
document.getElementById('next').onclick=()=>show(1);
</script></html>'''
    (HERE / 'index.html').write_text(html, encoding='utf-8')
    print(json.dumps({'heights': [m['height'] for m in sampling['frames_metrics']],
        'hat_widths': [m['hat_region_width'] for m in sampling['frames_metrics']],
        'unchanged_existing_frames': 72, 'status': 'awaiting approval'}))

if __name__ == '__main__':
    build()
