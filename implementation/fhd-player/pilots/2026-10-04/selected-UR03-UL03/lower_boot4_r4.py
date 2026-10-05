"""Lower the existing frame4 boot one pixel without a new generation."""
from pathlib import Path
import hashlib
import json
import re
import shutil
from PIL import Image, ImageDraw
from export_review import sample_source, caption, save_gif

HERE = Path(__file__).resolve().parent
PILOT = HERE.parent
REPO = PILOT.parents[3]
SOURCE = REPO / 'assets/art_source/player-fhd/pilots/2026-10-04/selected-UR03-UL03'
BASE = HERE / 'UR03/revisions/boot4-r3/frames'
OUT = HERE / 'UR03/revisions/boot4-r4/frames'
OUT.mkdir(parents=True, exist_ok=True)

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

approval = json.loads((HERE / 'UL03-approval.json').read_text())
assert all(sha(HERE / 'UL03/frames' / p) == h for p, h in approval['frame_sha256'].items())
old = [Image.open(BASE / f'{i:02}.png').convert('RGBA') for i in range(1, 9)]
new = [im.copy() for im in old]
sampled, sampling = sample_source('UR03-boot4-r3.png', 1)
sampled[0].save(HERE / 'UR03-boot4-r4-sampled.png')
# Lossless source cut aligned to the original ankle. The generated full-body
# source retained: place the same boot one pixel below the previous review.
source_cut = (42, 52, 54, 62)
target_region = (42, 51, 54, 61)
new[3].paste(sampled[0].crop(source_cut), target_region[:2])
# Preserve original blue trouser pixels within the cut, using their existing
# material ownership. No boot pixels are painted or recolored by this mask.
original_cut = old[3].crop(target_region)
mask = Image.new('L', original_cut.size)
mask.putdata([255 if a > 0 and b > r * 1.1 else 0 for r, g, b, a in original_cut.get_flattened_data()])
new[3].paste(original_cut, target_region[:2], mask)
checks = []
for i, im in enumerate(new, 1):
    path = OUT / f'{i:02}.png'
    if i != 4:
        shutil.copy2(BASE / f'{i:02}.png', path)
        assert path.read_bytes() == (BASE / f'{i:02}.png').read_bytes()
    else:
        im.save(path)
        assert im.tobytes() != old[3].tobytes()
        for y in range(80):
            for x in range(80):
                p = old[3].getpixel((x, y))
                protected = p[3] > 0 and p[2] > p[0] * 1.1
                outside = not(target_region[0] <= x < target_region[2] and target_region[1] <= y < target_region[3])
                if protected or outside:
                    assert im.getpixel((x, y)) == p
    assert im.size == (80, 80) and set(im.getchannel('A').tobytes()) <= {0, 255}
    checks.append({'frame': i, 'baseline_sha256': sha(BASE / f'{i:02}.png'), 'sha256': sha(path), 'changed': i == 4})
ul = [Image.open(HERE / 'UL03/frames' / f'{i:02}.png').convert('RGBA') for i in range(1, 9)]
normal, slow, aggregate = [], [], []
directions = ['down', 'right', 'up', 'left', 'down-right', 'up-right', 'up-left']
for i in range(8):
    a = Image.new('RGBA', (720, 350), '#20292c')
    b = Image.new('RGBA', (960, 380), '#303a3e')
    caption(ImageDraw.Draw(a), (20, 16), 'UR03 FRAME4 BOOT / UL03 APPROVED / 10 FPS', 17)
    for j, (label, data) in enumerate([('UR03 PREVIOUS', old), ('UR03 BOOT4 R4', new), ('UL03 APPROVED', ul)]):
        caption(ImageDraw.Draw(a), (j*240+20, 70), label, 15)
        a.alpha_composite(data[i].resize((160, 160), Image.Resampling.NEAREST), (j*240+40, 95))
        caption(ImageDraw.Draw(b), (j*320+10, 10), f'{label} / {i+1}', 14)
        b.alpha_composite(data[i].resize((320, 320), Image.Resampling.NEAREST), (j*320, 35))
    caption(ImageDraw.Draw(a), (20, 285), 'Boot4 lowered1px. Frame7 and approved UL03 retained.', 13)
    caption(ImageDraw.Draw(a), (20, 322), f'Frame {i+1:02}/08 | UR03 cycle awaiting review', 14)
    normal.append(a.convert('RGB')); slow.append(b.convert('RGB'))
    canvas = Image.new('RGBA', (1440, 330), '#20292c'); draw = ImageDraw.Draw(canvas)
    caption(draw, (24, 16), 'FARMER WALK / UR03 BOOT4 R4 / UL03 APPROVED / 10 FPS', 18)
    for j, d in enumerate(directions):
        frame = new[i] if d == 'up-right' else ul[i] if d == 'up-left' else Image.open(PILOT / f'walk-{d}/frames/walk-{d}-{i+1:02}.png').convert('RGBA')
        x = 40+j*200
        caption(draw, (x, 75), d.upper(), 17)
        canvas.alpha_composite(frame.resize((160, 160), Image.Resampling.NEAREST), (x, 100))
        caption(draw, (x, 274), 'CHECK BOOT4' if d == 'up-right' else 'UL03 APPROVED' if d == 'up-left' else 'UNCHANGED', 13)
    caption(draw, (24, 308), f'Frame {i+1:02}/08 | Preview only', 13)
    aggregate.append(canvas.convert('RGB'))
gifs = []
for name, sequence, duration in [('selected-corrections-boot4-r4.gif', normal, 100), ('selected-corrections-boot4-slow-r4.gif', slow, 200), ('all-walk-directions-boot4-r4.gif', aggregate, 100)]:
    save_gif(sequence, HERE / name, duration)
    gif = Image.open(HERE / name)
    assert gif.n_frames == 8 and gif.info['loop'] == 0
    for i in range(8):
        gif.seek(i); assert gif.info['duration'] == duration
    gifs.append({'file': name, 'size': list(gif.size), 'frames': 8, 'duration_ms': duration, 'sha256': sha(HERE / name)})
strip = Image.new('RGBA', (1280, 360), '#303a3e')
for row, data in enumerate([old, new]):
    for i, frame in enumerate(data):
        caption(ImageDraw.Draw(strip), (i*160+4, row*180), f'UR03 {i+1} ' + ('previous' if row == 0 else 'boot4 R4'), 11)
        strip.alpha_composite(frame.resize((160, 160), Image.Resampling.NEAREST), (i*160, row*180+20))
strip.convert('RGB').save(HERE / 'UR03-boot4-r4-before-after.png')
detail = Image.new('RGBA', (640, 355), '#303a3e')
for j, (label, frame) in enumerate([('FRAME4 HIGHER', old[3]), ('FRAME4 LOWERED1PX', new[3])]):
    caption(ImageDraw.Draw(detail), (j*320+10, 8), label, 14)
    detail.alpha_composite(frame.resize((320, 320), Image.Resampling.NEAREST), (j*320, 30))
detail.convert('RGB').save(HERE / 'UR03-frame4-boot-r4-detail.png')
baseline = json.loads((HERE / 'baseline.json').read_text())
assert all(sha(PILOT / p) == h for p, h in baseline.items())
args = json.loads((HERE / 'UR03-boot4-r3.prompt.json').read_text())
raw = Path('C:/Users/Helel/.codex/generated_images/01a0f7e5-4a37-7612-b3d9-590f2b3bfba5/exec-28f969ac-7fef-4e03-8c28-1467f7039825.png')
assert raw.read_bytes() == (SOURCE / 'UR03-boot4-r3.png').read_bytes()
report = {'date': '2026-10-05', 'tool': 'deterministic source placement', 'imagegen_calls': 0, 'source_generation_arguments': args,
    'raw_original': str(raw), 'saved_source': str(SOURCE / 'UR03-boot4-r3.png'), 'source_sha256': sha(raw),
    'input_sha256': {p: sha(Path(p)) for p in args['referenced_image_paths']},
    'sampling': sampling, 'source_cut': list(source_cut), 'target_region': list(target_region),
    'alignment': 'Same generated boot source placed1nativepixel lower than boot4-r3; existing ankle cap retained.',
    'protected_material': 'All original blue trouser pixels retained exactly by material mask.',
    'frames': checks, 'gifs': gifs, 'UL03': 'approved; eight frozen PNGs unchanged',
    'current_native_unchanged': len(baseline), 'scope': 'Only frame4 boot lowered1nativepixel relative to boot4-r3; frame7 byte-identical.',
    'status': 'awaiting user visual review; no runtime integration'}
(HERE / 'UR03-boot4-r4.call.json').write_text(json.dumps(report, indent=2) + '\n')
status_path = PILOT / 'directions-status.json'
status = json.loads(status_path.read_text()); ur = status['walk_up_right']
ur.update(candidate='selected-UR03-UL03/UR03/revisions/boot4-r4/frames',
    preview='selected-UR03-UL03/index.html', diagnostic='selected-UR03-UL03/UR03-boot4-r4-before-after.png',
    user_feedback='Boot shape good; lower frame4 foot slightly for walking motion.',
    feedback_addressed='Existing frame4 boot source lowered1nativepixel; no new generation. Blue trousers, frame7 and UL03 retained.',
    review_limit='Selected UR03 cycle visual approval pending; no runtime integration.')
ur['selected_archive_review'].update(candidate=ur['candidate'], revision='boot4-r4',
    requested_frames=[4], retained_previous_revision='boot-r2 frame7', status='awaiting_approval')
status_path.write_text(json.dumps(status, indent=2) + '\n')
html = (HERE / 'index.html').read_text()
html = html.replace('UR03: only the lifted boot in frame 7 is revised.', 'UR03: only the lifted boot in frame 4 changed in this revision. Frame 7 is retained.')
html = html.replace('selected-corrections-boot-r2.gif', 'selected-corrections-boot4-r4.gif').replace('selected-corrections-boot-slow-r2.gif', 'selected-corrections-boot4-slow-r4.gif')
html = html.replace('UR03-boot-r2-before-after.png', 'UR03-boot4-r4-before-after.png').replace('all-walk-directions-boot-r2.gif', 'all-walk-directions-boot4-r4.gif')
html = html.replace('UL03 approved. Only UR03 frame 7 boot revision awaits review.', 'UL03 approved and preserved. UR03 frame 4 boot revised; frame 7 retained. UR03 cycle awaits review.')
html = html.replace("'ur-old':['UR03','original']", "'ur-old':['UR03','revisions/boot-r2/frames']").replace("'ur-new':['UR03','revisions/boot-r2/frames']", "'ur-new':['UR03','revisions/boot4-r4/frames']")
html = html.replace('UR03 original', 'UR03 previous').replace('v=boot-r2', 'v=boot4-r4').replace('let index=6;', 'let index=3;').replace('index===6', 'index===3')
if 'UR03-frame4-boot-r4-detail.png' not in html:
    html = html.replace('<p><a href="UR03-frame7', '<p><a href="UR03-frame4-boot-r4-detail.png">Frame4 previous / new</a> &middot; <a href="UR03-frame7', 1)
html = html.replace('boot4-r3', 'boot4-r4').replace('boot-r2/frames', 'boot4-r3/frames')
html = re.sub(r"'ur-old':\['UR03','[^']+'\]", "'ur-old':['UR03','revisions/boot4-r3/frames']", html)
html = html.replace('only the lifted boot in frame 4 changed in this revision.', 'the frame 4 foot is now 1 native pixel lower, with its existing boot design retained.')
html = html.replace('UR03 frame 4 boot revised;', 'UR03 frame 4 boot lowered 1 pixel;')
html = html.replace('now1nativepixel', 'now 1 native pixel').replace('lowered1pixel', 'lowered 1 pixel')
html = html.replace('selected-corrections-boot4-slow-r3.gif', 'selected-corrections-boot4-slow-r4.gif')
(HERE / 'index.html').write_text(html)
print('PASS: only boot4 changed; protected blue trousers,7other UR03 poses, approved UL03 and56active native poses retained.')
