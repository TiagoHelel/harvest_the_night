"""Record final review evidence after the required engine suite completes."""
from pathlib import Path
import hashlib
import json
import re

HERE = Path(__file__).resolve().parent
PILOT = HERE.parent
REPO = PILOT.parents[3]
log = (HERE / 'boot-r2-engine-check.log').read_text(encoding='utf-8')
assert re.search(r'^PASS\b', log, re.MULTILINE), 'Required engine verification has not completed with PASS.'
assert not re.search(r'^FAIL\b', log, re.MULTILINE), 'Engine verification failed.'
approval = json.loads((HERE / 'UL03-approval.json').read_text())
assert all(hashlib.sha256((HERE / 'UL03/frames' / p).read_bytes()).hexdigest() == h
           for p, h in approval['frame_sha256'].items())
report_path = HERE / 'UR03-boot-r2.call.json'
report = json.loads(report_path.read_text())
report.update(visual_review={
    'result': 'Complete raised boot now has a compact toe and continuous sole/heel; reviewed at integer2x/4x. User approval pending.',
    'evidence': ['UR03-frame7-boot-r2-detail.png', 'boot-r2-browser.png', 'boot-r2-frame7-browser.png'],
    'remaining_scope': 'Only UR03 frame7; do not modify the explicitly approved UL03 cycle.'},
    engine_verification={'result': 'PASS', 'log': 'boot-r2-engine-check.log',
                         'log_sha256': hashlib.sha256((HERE / 'boot-r2-engine-check.log').read_bytes()).hexdigest()})
report_path.write_text(json.dumps(report, indent=2) + '\n')
prior_path = HERE / 'validation-r1.json'
prior = json.loads(prior_path.read_text())
prior['user_review_2026_10_05'] = {'UR03': 'frame7 rejected: foot malformed',
                                'UL03': 'approved', 'next_review': 'index.html boot-r2'}
prior_path.write_text(json.dumps(prior, indent=2) + '\n')
calls_path = HERE / 'calls.json'
calls = json.loads(calls_path.read_text())
calls['UR03'][0]['status'] = 'rejected by user: frame7 foot malformed'
calls['UL03'][0]['status'] = 'approved by user on2026-10-05; exact final cycle frozen in UL03-approval.json'
calls_path.write_text(json.dumps(calls, indent=2) + '\n')
status_path = PILOT / 'directions-status.json'
status = json.loads(status_path.read_text())
status['walk_up_right']['review_limit'] = 'Only UR03 frame7 rebuilt boot awaits user review; no runtime integration.'
status['walk_up_right']['diagnostic'] = 'selected-UR03-UL03/UR03-boot-r2-before-after.png'
status['walk_up_left']['diagnostic'] = 'selected-UR03-UL03/UL03-before-after.png'
status['walk_up_left']['feedback_addressed'] = 'Selected UL03 cycle with corrected near-arm poses5/6; original legs and boots retained.'
status_path.write_text(json.dumps(status, indent=2) + '\n')
summary = '\n'.join(log.splitlines()[-10:])
entry = '''
## UR03 frame7 boot rebuild / UL03 approved - 2026-10-05

User rejected UR03 frame7's malformed foot and explicitly approved UL03.
UL03-approval.json freezes all8approved frame SHA256 values. Direction status
records the exact approved selected cycle; all8UL03 files remain byte-identical.
No next direction or runtime promotion performed during this correction.

One built-in ImageGen edit call:UR03-boot-r2.prompt.json, exact arguments and
source/input hashes in UR03-boot-r2.call.json. Original1254x1254RGBA preserved
under CODEX_HOME and copied unchanged to assets/art_source/player-fhd/pilots/
2026-10-04/selected-UR03-UL03/UR03-boot-r2.png. Rebuilt lifted boot has a narrow
ankle, rounded toe and dark sole. The rejectedr1 cut missed part of the original
heel, leaving an incoherent composite. New fixed generated cut(41,52,55,61)
covers the whole raised boot below the retained cuff. All outside pixels exact;
other7UR03 selected poses copied unchanged. No limb painting, flipping or warp.

New selected review cycle:UR03/revisions/boot-r2/frames. Previousr1frames and
sources retained. Existing index.html now shows original UR03 / revised UR03 /
approved UL03,720x350,integer2x,8x100ms; slow960x380,integer4x,8x200ms.
All-seven-direction horizontal GIF updated; other five directions unchanged.
Format/scope PASS: only boot7changed,7unchanged UR03 poses,8frozen UL03 poses,
56active native assets unchanged,binary alpha,3eight-frame infinite GIFs.
Manual frame7 and normal playback inspected; boot-r2-browser.png and
boot-r2-frame7-browser.png saved. User approval remains pending for UR03.

Required full engine verification PASS (boot-r2-engine-check.log):
'''
entry += '\n```text\n' + summary + '\n```\n'
entry += '''
Sprite queue and git diff --check PASS. No sim/data acceptance, queue mutation,
runtime integration, push or project.godot edits. Unrelated files preserved.
'''
for p in [REPO / 'implementation/PROGRESS.md', REPO / 'implementation/sprites/PROGRESS.md']:
    text = p.read_text(encoding='utf-8')
    if '## UR03 frame7 boot rebuild / UL03 approved' not in text:
        p.write_text(text.rstrip() + '\n' + entry, encoding='utf-8')
print('Recorded boot-r2 review, explicit UL03 approval, full engine PASS and both journals.')
