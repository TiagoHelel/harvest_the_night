"""Record the one-pixel placement adjustment and required verification."""
from pathlib import Path
import hashlib
import json
import re

HERE = Path(__file__).resolve().parent
REPO = HERE.parent.parents[3]
log_path = HERE / 'boot4-r4-engine-check.log'
log = log_path.read_text(encoding='utf-8')
assert re.search(r'^PASS\s*$', log, re.MULTILINE), 'Required engine verification has not completed with PASS.'
assert not re.search(r'^FAIL\b', log, re.MULTILINE)
path = HERE / 'UR03-boot4-r4.call.json'
report = json.loads(path.read_text())
report.update(user_feedback='Boot shape is good; lower frame4 foot slightly for walking motion.',
    change='Existing boot source placement moved down1nativepixel (2screenpixels at preview scale); no generation.',
    visual_review={'result': 'Lowered foot and ankle connection inspected at2x/4x; cycle approval pending.',
                   'evidence': ['boot4-r4-browser.png', 'boot4-r4-frame4-browser.png', 'UR03-frame4-boot-r4-detail.png']},
    engine_verification={'result': 'PASS', 'log': log_path.name, 'sha256': hashlib.sha256(log_path.read_bytes()).hexdigest()})
path.write_text(json.dumps(report, indent=2) + '\n')
entry = '''
## UR03 frame4 foot placement lowered one pixel - 2026-10-05

User liked the rebuilt boot shape and requested that frame4's foot sit a little
lower during walking. Adjusted the editable deterministic source placement:
same boot cut(42,52,54,62), target now(42,51,54,61), one native pixel belowr3.
Existing ankle cap and every blue trouser pixel retained. No new ImageGen call,
new boot artwork, recoloring, scaling or warp. Reused the unchanged raw/source
UR03-boot4-r3.png; provenance and previous generation arguments recorded in
UR03-boot4-r4.call.json. New isolated cycle:UR03/revisions/boot4-r4/frames.

Scope/format PASS: only frame4 placement changed relative tor3; other7UR03
poses including7byte-identical,8approved UL03 poses exact,56active native
frames unchanged. Previous artifacts retained. Normal720x350integer2xGIF,
slow960x380integer4xGIF,all-seven-directionsGIF,contactstrip and manual4x
comparison updated in the same index.html. Eight poses at100/200ms infinite
loops. Browser normal playback and frame4 ankle/foot placement inspected;
boot4-r4-browser.png / boot4-r4-frame4-browser.png saved. User review pending.

Required engine verification PASS:
'''
entry += '\n```text\n' + '\n'.join(log.splitlines()[-10:]) + '\n```\n'
entry += '''
Sprite queue and git diff --check PASS. No runtime promotion, new direction,
queue mutation, hash acceptance, push or project.godot change.
'''
for p in [REPO / 'implementation/PROGRESS.md', REPO / 'implementation/sprites/PROGRESS.md']:
    text = p.read_text(encoding='utf-8')
    if '## UR03 frame4 foot placement lowered one pixel' not in text:
        p.write_text(text.rstrip() + '\n' + entry, encoding='utf-8')
print('Recorded one-pixel placement adjustment, preserved approval scope and engine PASS.')
