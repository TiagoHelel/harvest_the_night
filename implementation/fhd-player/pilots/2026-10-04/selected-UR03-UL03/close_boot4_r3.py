"""Append provenance, browser evidence and required engine results."""
from pathlib import Path
import hashlib
import json
import re

HERE = Path(__file__).resolve().parent
REPO = HERE.parent.parents[3]
log_path = HERE / 'boot4-r3-engine-check.log'
log = log_path.read_text(encoding='utf-8')
assert re.search(r'^PASS\s*$', log, re.MULTILINE), 'Full verification has not completed with PASS.'
assert not re.search(r'^FAIL\b', log, re.MULTILINE)
call_path = HERE / 'UR03-boot4-r3.call.json'
call = json.loads(call_path.read_text())
call.update(visual_review={
    'inspected': ['normal10fps integer2x playback', 'frame4 at integer4x', 'neighboring3/5 poses'],
    'evidence': ['boot4-r3-browser.png', 'boot4-r3-frame4-browser.png', 'UR03-frame4-boot-r3-detail.png'],
    'finding': 'Raised boot4 has a compact toe, heel and dark sole; retained cuff and blue trousers exact. User visual review pending.'},
    engine_verification={'result': 'PASS', 'log': log_path.name,
                         'sha256': hashlib.sha256(log_path.read_bytes()).hexdigest()})
call_path.write_text(json.dumps(call, indent=2) + '\n')
summary = '\n'.join(log.splitlines()[-10:])
entry = '''
## UR03 frame4 raised boot correction - review ready 2026-10-05

User identified a malformed lifted boot in UR03 frame4. One built-in ImageGen
edit using the exact frame4 target, neighboring3/5 poses and rebuilt boot7 as
design reference. Exact prompt: selected-UR03-UL03/UR03-boot4-r3.prompt.json;
arguments, source/input SHA256 and output ownership: UR03-boot4-r3.call.json.
Original1254x1254RGBA preserved and copied unchanged into assets/art_source/
player-fhd/pilots/2026-10-04/selected-UR03-UL03/UR03-boot4-r3.png.

Native source uses common32pxhat calibration, nearest sampling and binary
alpha. Lossless boot cut(42,52,54,62) placed at original cuff(42,50), correcting
the generated source's2pxlower ankle. Original blue trouser pixels inside
the patch retained by material mask; all outside pixels exact. No painted boot
pixels, limb warp, recoloring or per-limb scaling. Source boot silhouette now
has a narrow ankle, heel, rounded rightward toe and continuous dark sole.

New isolated cycle:UR03/revisions/boot4-r3/frames. Exactly one frame changed
relative to boot-r2; other7poses including revised7byte-identical. All8approved
UL03 frame hashes retained;56active native assets remain unchanged. Previous
sources/cycles retained. Same index.html now opens manual review at frame4.
Updated horizontal720x350normalGIF(integer2x,8x100ms),960x380slow(integer4x,
8x200ms),all7directions1440x330,contactstrip and before/after frame4 detail.
Other five directions unchanged. Browser screenshots:boot4-r3-browser.png,
boot4-r3-frame4-browser.png. Integer2xpreview playback and4xboot shape inspected;
format/scope PASS. UR03 visual approval remains pending; UL03 stays approved.

Full required engine verification PASS, no sim/data hash acceptance:
'''
entry += '\n```text\n' + summary + '\n```\n'
entry += '''
Sprite queue and git diff --check PASS. No runtime promotion, queue mutation,
next direction, push or project.godot edit. Unrelated work preserved.
'''
for path in [REPO / 'implementation/PROGRESS.md', REPO / 'implementation/sprites/PROGRESS.md']:
    text = path.read_text(encoding='utf-8')
    if '## UR03 frame4 raised boot correction' not in text:
        path.write_text(text.rstrip() + '\n' + entry, encoding='utf-8')
print('Recorded isolated boot4 correction, frozen approval scope and engine PASS.')
