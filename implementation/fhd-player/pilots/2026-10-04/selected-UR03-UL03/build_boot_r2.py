"""Replace the complete lifted boot in UR03 frame7; freeze approved UL03."""
from pathlib import Path
import hashlib
import json
import shutil
from PIL import Image, ImageDraw
from export_review import sample_source, caption, save_gif

HERE = Path(__file__).resolve().parent
PILOT = HERE.parent
REPO = PILOT.parents[3]
SOURCE = REPO / 'assets/art_source/player-fhd/pilots/2026-10-04/selected-UR03-UL03'
OUT = HERE / 'UR03/revisions/boot-r2/frames'
OUT.mkdir(parents=True, exist_ok=True)

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

approval = json.loads((HERE / 'UL03-approval.json').read_text())
assert all(sha(HERE / 'UL03/frames' / p) == h for p, h in approval['frame_sha256'].items())
sampled, sampling = sample_source('UR03-boot-r2.png', 1)
sampled[0].save(HERE / 'UR03-boot-r2-sampled.png')
old = [Image.open(HERE / 'UR03/original' / f'{i:02}.png').convert('RGBA') for i in range(1, 9)]
new = [im.copy() for im in old]
# This cut includes the entire lifted boot silhouette, including heel and toe;
# it does not stop inside the boot as the rejected r1 cut did.
region = (41, 52, 55, 61)
new[6].paste(sampled[0].crop(region), region[:2])
checks = []
for i, im in enumerate(new, 1):
    path = OUT / f'{i:02}.png'
    if i != 7:
        shutil.copy2(HERE / 'UR03/original' / f'{i:02}.png', path)
        assert path.read_bytes() == (HERE / 'UR03/original' / f'{i:02}.png').read_bytes()
    else:
        im.save(path)
        assert im.tobytes() != old[6].tobytes()
        for y in range(80):
            for x in range(80):
                if not(region[0] <= x < region[2] and region[1] <= y < region[3]):
                    assert im.getpixel((x, y)) == old[6].getpixel((x, y))
    assert im.size == (80, 80) and set(im.getchannel('A').tobytes()) <= {0, 255}
    checks.append({'frame': i, 'sha256': sha(path), 'changed': i == 7})
ul = [Image.open(HERE / 'UL03/frames' / f'{i:02}.png').convert('RGBA') for i in range(1, 9)]
normal, slow = [], []
for i in range(8):
    a = Image.new('RGBA', (720, 350), '#20292c')
    b = Image.new('RGBA', (960, 380), '#303a3e')
    caption(ImageDraw.Draw(a), (20, 16), 'UR03 BOOT CORRECTION / UL03 APPROVED / 10 FPS', 17)
    for j, (label, data) in enumerate([('UR03 ORIGINAL', old), ('UR03 BOOT R2', new), ('UL03 APPROVED', ul)]):
        caption(ImageDraw.Draw(a), (j * 240 + 20, 70), label, 15)
        a.alpha_composite(data[i].resize((160, 160), Image.Resampling.NEAREST), (j * 240 + 40, 95))
        caption(ImageDraw.Draw(b), (j * 320 + 10, 10), f'{label} / {i+1}', 14)
        b.alpha_composite(data[i].resize((320, 320), Image.Resampling.NEAREST), (j * 320, 35))
    caption(ImageDraw.Draw(a), (20, 285), 'Only UR03 frame7 revised. Approved UL03 unchanged.', 14)
    caption(ImageDraw.Draw(a), (20, 322), f'Frame {i+1:02}/08 | Boot revision awaiting review', 14)
    normal.append(a.convert('RGB')); slow.append(b.convert('RGB'))
save_gif(normal, HERE / 'selected-corrections-boot-r2.gif', 100)
save_gif(slow, HERE / 'selected-corrections-boot-slow-r2.gif', 200)
strip = Image.new('RGBA', (1280, 360), '#303a3e')
for row, data in enumerate([old, new]):
    for i, im in enumerate(data):
        caption(ImageDraw.Draw(strip), (i*160+4, row*180), f'UR03 {i+1} ' + ('original' if row == 0 else 'boot R2'), 11)
        strip.alpha_composite(im.resize((160, 160), Image.Resampling.NEAREST), (i*160, row*180+20))
strip.convert('RGB').save(HERE / 'UR03-boot-r2-before-after.png')
detail = Image.new('RGBA', (960, 355), '#303a3e')
for j, (label, frame) in enumerate([('FRAME7 ORIGINAL', old[6]), ('FRAME7 REJECTED R1', Image.open(HERE / 'UR03/frames/07.png')), ('FRAME7 BOOT R2', new[6])]):
    caption(ImageDraw.Draw(detail), (j*320+10, 8), label, 14)
    detail.alpha_composite(frame.convert('RGBA').resize((320, 320), Image.Resampling.NEAREST), (j*320, 30))
detail.convert('RGB').save(HERE / 'UR03-frame7-boot-r2-detail.png')
aggregate = []
directions = ['down', 'right', 'up', 'left', 'down-right', 'up-right', 'up-left']
for i in range(8):
    canvas = Image.new('RGBA', (1440, 330), '#20292c')
    draw = ImageDraw.Draw(canvas)
    caption(draw, (24, 16), 'FARMER WALK / UR03 BOOT R2 / UL03 APPROVED / 10 FPS', 19)
    for j, d in enumerate(directions):
        frame = new[i] if d == 'up-right' else ul[i] if d == 'up-left' else Image.open(PILOT / f'walk-{d}/frames/walk-{d}-{i+1:02}.png').convert('RGBA')
        x = 40 + j*200
        caption(draw, (x, 75), d.upper(), 17)
        canvas.alpha_composite(frame.resize((160, 160), Image.Resampling.NEAREST), (x, 100))
        caption(draw, (x, 274), 'CHECK BOOT7' if d == 'up-right' else 'UL03 APPROVED' if d == 'up-left' else 'UNCHANGED', 13)
    caption(draw, (24, 308), f'Frame {i+1:02}/08 | Preview only', 13)
    aggregate.append(canvas.convert('RGB'))
save_gif(aggregate, HERE / 'all-walk-directions-boot-r2.gif', 100)
baseline = json.loads((HERE / 'baseline.json').read_text())
assert all(sha(PILOT / p) == h for p, h in baseline.items())
gifs = []
for name, duration in [('selected-corrections-boot-r2.gif', 100), ('selected-corrections-boot-slow-r2.gif', 200), ('all-walk-directions-boot-r2.gif', 100)]:
    gif = Image.open(HERE / name)
    assert gif.n_frames == 8 and gif.info['loop'] == 0
    for i in range(8):
        gif.seek(i); assert gif.info['duration'] == duration
    gifs.append({'file': name, 'size': list(gif.size), 'frames': 8, 'duration_ms': duration, 'sha256': sha(HERE / name)})
prompt = json.loads((HERE / 'UR03-boot-r2.prompt.json').read_text())
raw = Path('C:/Users/Helel/.codex/generated_images/01a0f7e5-4a37-7612-b3d9-590f2b3bfba5/exec-8469c265-669a-46d3-8280-10a4e793eac2.png')
assert raw.read_bytes() == (SOURCE / 'UR03-boot-r2.png').read_bytes()
report = {'date': '2026-10-05', 'tool': 'built-in ImageGen edit', 'arguments': prompt,
          'raw_original': str(raw), 'saved_source': str(SOURCE / 'UR03-boot-r2.png'),
          'source_sha256': sha(raw), 'input_sha256': {p: sha(Path(p)) for p in prompt['referenced_image_paths']},
          'sampling': sampling, 'region': list(region), 'frames': checks, 'gifs': gifs,
          'UL03_status': 'approved; all8frames unchanged', 'current_native_unchanged': len(baseline),
          'status': 'awaiting UR03 frame7 visual review; no runtime integration',
          'previous_r1': 'Rejected by user: foot remained malformed; cut did not include full heel.'}
(HERE / 'UR03-boot-r2.call.json').write_text(json.dumps(report, indent=2) + '\n')
status_path = PILOT / 'directions-status.json'
status = json.loads(status_path.read_text())
ur = status['walk_up_right']
ur.update(candidate='selected-UR03-UL03/UR03/revisions/boot-r2/frames',
          preview='selected-UR03-UL03/index.html', status='awaiting_approval',
          feedback_addressed='Whole lifted boot silhouette rebuilt in7; other7selected poses exact.')
ur['selected_archive_review'].update(candidate=ur['candidate'], status='awaiting_approval',
                                      revision='boot-r2', requested_frames=[7])
status_path.write_text(json.dumps(status, indent=2) + '\n')
html = (HERE / 'index.html').read_text()
html = html.replace('The other 13 selected frames are identical. UL03 legs and boots are preserved in every frame.', 'UR03: only the lifted boot in frame 7 is revised. UL03 is approved and all eight approved frames are unchanged.')
html = html.replace('UR03: frame 7. UL03: frames 5 and 6. ', '')
html = html.replace('width="960" height="350" src="selected-corrections-r1.gif?v=local-r1"', 'width="720" height="350" src="selected-corrections-boot-r2.gif?v=boot-r2"')
html = html.replace('width="1280" height="380" src="selected-corrections-slow-r1.gif?v=local-r1"', 'width="960" height="380" src="selected-corrections-boot-slow-r2.gif?v=boot-r2"')
html = html.replace('UR03-before-after.png', 'UR03-boot-r2-before-after.png').replace('all-walk-directions-selected-r1.gif', 'all-walk-directions-boot-r2.gif')
html = html.replace('Selected bases: UR03 and UL03. Three revised frames awaiting review.', 'UL03 approved. Only UR03 frame 7 boot revision awaits review.')
html = html.replace("'ur-new':['UR03','frames']", "'ur-new':['UR03','revisions/boot-r2/frames']").replace('v=local-r1', 'v=boot-r2')
html = html.replace('UL03 revised', 'UL03 approved').replace('[4,5,6].includes(index)', 'index===6')
html = html.replace('let index=0;', 'let index=6;')
html = html.replace('<p><a href="UR03-boot-r2-before-after.png">', '<p><a href="UR03-frame7-boot-r2-detail.png">Frame7 original / rejected / new</a> &middot; <a href="UR03-boot-r2-before-after.png">')
(HERE / 'index.html').write_text(html)
print('PASS: whole boot cut,7unchanged UR03 poses,8frozen approved UL03 poses,56active frames unchanged,3eight-frame GIFs.')
