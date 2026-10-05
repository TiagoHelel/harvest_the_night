"""Record provenance and verify the isolated selected-cycle review."""
from pathlib import Path
import hashlib
import json
from PIL import Image

HERE = Path(__file__).resolve().parent
PILOT = HERE.parent
REPO = PILOT.parents[3]
SOURCE = REPO / 'assets/art_source/player-fhd/pilots/2026-10-04/selected-UR03-UL03'

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def write_json(path, data):
    path.write_text(json.dumps(data, indent=2) + '\n', encoding='utf-8')

report = json.loads((HERE / 'validation-r1.json').read_text())
calls = json.loads((HERE / 'calls.json').read_text())
selection = json.loads((HERE / 'selection.json').read_text())
for code, indices in [('UR03', [7]), ('UL03', [5, 6])]:
    call = calls[code][0]
    source = SOURCE / call['source']
    original = Path(call['original'])
    assert source.read_bytes() == original.read_bytes()
    call.update(tool='image_gen.imagegen', date='2026-10-05', mode='built-in edit',
                source_sha256=sha(source), original_sha256=sha(original),
                dimensions=list(Image.open(source).size),
                input_sha256={p: sha(Path(p)) for p in call['referenced_image_paths']},
                selected_base=selection['selected'][code]['name'],
                assembly='Fixed rectangular cut from generated artwork; original pixels retained outside cut.',
                status='awaiting user visual review; preview only')
    frame_checks = []
    base = REPO / selection['selected'][code]['aliases'][0]['path']
    direction = selection['selected'][code]['direction']
    for i in range(1, 9):
        before_path = HERE / code / 'original' / f'{i:02}.png'
        after_path = HERE / code / 'frames' / f'{i:02}.png'
        assert before_path.read_bytes() == (base / f'walk-{direction}-{i:02}.png').read_bytes()
        before = Image.open(before_path).convert('RGBA')
        after = Image.open(after_path).convert('RGBA')
        assert before.size == after.size == (80, 80)
        assert set(after.getchannel('A').tobytes()) <= {0, 255}
        if i not in indices:
            assert before_path.read_bytes() == after_path.read_bytes()
        else:
            region = next(r['generated_region'] for r in report[code]['regions'] if r['frame'] == i)
            assert before.tobytes() != after.tobytes()
            for y in range(80):
                for x in range(80):
                    if not(region[0] <= x < region[2] and region[1] <= y < region[3]):
                        assert before.getpixel((x, y)) == after.getpixel((x, y))
        if code == 'UL03':
            assert before.crop((0, 50, 80, 80)).tobytes() == after.crop((0, 50, 80, 80)).tobytes()
        frame_checks.append({'frame': i, 'original_sha256': sha(before_path),
                             'revised_sha256': sha(after_path), 'changed': i in indices})
    report[code]['frame_checks'] = frame_checks

baseline = json.loads((HERE / 'baseline.json').read_text())
assert len(baseline) == 56
assert all(sha(PILOT / p) == h for p, h in baseline.items())
gif_checks = []
for name, size, duration in [('selected-corrections-r1.gif', (960, 350), 100),
                              ('selected-corrections-slow-r1.gif', (1280, 380), 200),
                              ('all-walk-directions-selected-r1.gif', (1440, 330), 100)]:
    path = HERE / name
    gif = Image.open(path)
    assert gif.size == size and gif.n_frames == 8 and gif.info['loop'] == 0
    hashes = []
    for i in range(8):
        gif.seek(i)
        assert gif.info['duration'] == duration
        hashes.append(hashlib.sha256(gif.convert('RGB').tobytes()).hexdigest())
    assert len(set(hashes)) == 8
    gif_checks.append({'file': name, 'size': list(size), 'frames': 8,
                       'duration_ms': duration, 'loop': 0, 'sha256': sha(path)})

report.update(gif_checks=gif_checks, format_and_scope='PASS',
              selected_archive_ownership='PASS: exact UR03 and UL03 archive hashes',
              visual_review={'inspected': ['normal 10fps comparison', 'frame5', 'frame6', 'frame7'],
                             'screenshots': ['browser.png', 'frame5-browser.png', 'frame6-browser.png', 'frame7-browser.png'],
                             'finding': 'UL03 cross-back arm removed in5/6; UR03 lifted boot lowered in7. Protected regions retained. User review pending.'},
              engine_validation='Not rerun for isolated preview assets; previous full engine run passed55checks. No runtime asset changes.')
write_json(HERE / 'calls.json', calls)
write_json(HERE / 'validation-r1.json', report)

status_path = PILOT / 'directions-status.json'
status = json.loads(status_path.read_text())
for key, code, frames in [('walk_up_right', 'UR03', [7]), ('walk_up_left', 'UL03', [5, 6])]:
    status[key]['selected_archive_review'] = {
        'date': '2026-10-05', 'selected_code': code,
        'selected_base': selection['selected'][code]['name'],
        'requested_frames': frames, 'status': 'awaiting_approval',
        'candidate': f'selected-UR03-UL03/{code}/frames',
        'preview': 'selected-UR03-UL03/index.html',
        'runtime_integrated': False,
        'user_feedback': 'UR03: redo only7. UL03: redo5and6. Use selected gallery versions.'}
write_json(status_path, status)

link = '<p><a href="../selected-UR03-UL03/index.html?v=local-r1">Selected UR03 + UL03: corrections to frames7 / 5,6</a></p>\n'
for folder in ['walk-revision-gallery', 'walk-up-right', 'walk-up-left']:
    path = PILOT / folder / 'index.html'
    text = path.read_text(encoding='utf-8')
    if '../selected-UR03-UL03/index.html' not in text:
        text = text.replace('<main>', '<main>' + link, 1)
        path.write_text(text, encoding='utf-8')

entry = '''
## Selected UR03 / UL03 local corrections - review ready 2026-10-05

User selected UR03 (before-07-08-r5/frames) and UL03
(before-arm-smoothing/frames), requesting only UR03 frame7 and UL03 frames5/6.
Frozen gallery IDs and original archive pixels preserved. New review lives in
implementation/fhd-player/pilots/2026-10-04/selected-UR03-UL03/index.html.
The gallery and both existing upper-diagonal pages link to this local review.

Two built-in ImageGen edit calls, one single recovery pose and one arm pair;
English prompts and exact arguments in prompts-r1.json/calls.json. Originals
copied unchanged into assets/art_source/player-fhd/pilots/2026-10-04/
selected-UR03-UL03/, with dimensions and source/input SHA256 recorded.
Native export uses a shared32px hat calibration per source and nearest sampling.
Fixed generated cuts:UR03 frame7(44,48,62,68), UL03 frames5/6(22,30,46,50).
All other pixels of those frames retained; no hand painting or limb warping.
UR03 planted leg/boot, head, torso and arms retained. UL03 legs/boots in all8
poses, heads and far arms retained. Other13selected poses byte-identical.

Horizontal before/after:selected-corrections-r1.gif,960x350,8x100ms,
integer2x. Slow detail:1280x380,8x200ms,integer4x. Seven-direction review:
all-walk-directions-selected-r1.gif,1440x330,8x100ms; other five directions
unchanged. Manual comparison controls inspect all8poses without interpolation.

Format/scope PASS: exact selected archives,16binary-alpha80x80frames,
only3changed poses, protected regions identical,8unique poses per infinite
GIF, correct cadence,56current native assets unchanged. Browser inspected
normal comparison and corrected phases5/6/7; screenshots saved beside review.
UR03 recovery boot now lower in7; UL03 near arm no longer crosses the back.
Visual approval remains pending. No active native/runtime assets replaced.
Full engine suite not rerun for isolated preview art; preceding run passed55
checks with unchanged sim/data hashes. Sprite queue and git diff --check PASS.
No next direction, queue mutation, push or project.godot change.
'''
for path in [REPO / 'implementation/PROGRESS.md', REPO / 'implementation/sprites/PROGRESS.md']:
    text = path.read_text(encoding='utf-8')
    if '## Selected UR03 / UL03 local corrections' not in text:
        path.write_text(text.rstrip() + '\n' + entry, encoding='utf-8')
print('PASS: 3 local edits, 13 identical selected poses, protected regions, 56 unchanged active poses, 3 GIFs and provenance.')
