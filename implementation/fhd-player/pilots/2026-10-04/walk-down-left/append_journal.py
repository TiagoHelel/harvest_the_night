"""Append acceptance and preview evidence without duplicating the entry."""
from pathlib import Path
import json

HERE = Path(__file__).resolve().parent
PILOT = HERE.parent
REPO = PILOT.parents[3]
validation = json.loads((HERE / 'validation.json').read_text())
source = json.loads((HERE / 'materials-r1.call.json').read_text())
heading = '## FHD walking review — UR03 approved, DOWN-LEFT candidate — 2026-10-05'
entry = f'''

{heading}

The user approved the exact UR03 boot4-r4 eight-frame cycle. Its PNG hashes are
frozen in selected-UR03-UL03/UR03-approval.json; UL03 remains approved. The paired
review footer and directions-status.json now record that approval. No native
pose from the existing seven directions, UR03 or UL03 was replaced: all 72
baseline file hashes match.

Prepared the last direction, DOWN-LEFT, for individual visual review. Sources
are assets/art_source/player-fhd/pilots/2026-10-04/walk-down-left/; exact six
built-in ImageGen calls/prompts, raw original paths, input/output hashes and
evaluations are in implementation/fhd-player/pilots/2026-10-04/walk-down-left/.
Read sprite_generator's prepare_ranger_transition.py and prepare_walk_v2.py:
rotate first, opposite contacts, fixed cyan/magenta hip ownership, two halves.
Contacts R1 were oversized; R2 improved proportions. Four-phase transition A
R1/R2 failed smooth far-leg passage/ownership. Full colored cycle R3 also failed
ownership. Rejected candidates retained, not treated as approved animation.

Selected materials-r1.png is a separate built-in direction-only edit of the
existing opposite-diagonal eight-pose timeline; it does not restore or consume
the rejected colored poses. Original leg/arm timing provides the reference;
the generated result is not a pixel-exact mirror. No code-drawn farmer, limb
warp or programmatic reflection. Source SHA256: {source['sha256']}.
One global nearest sampling scale per sheet, hat-center/top8 anchor and alpha128
cleanup. Native 80x80, eight unique frames at 10 FPS; heights
{[m['height'] for m in validation['frames_metrics']]}, hat widths
{[m['hat_region_width'] for m in validation['frames_metrics']]}.

Preview folder: implementation/fhd-player/pilots/2026-10-04/walk-down-left/.
Normal 880x450 GIF at integer 2x and 100ms, slow 900x395 opposite-diagonal comparison
at integer 4x and 200ms, all-eight-walk-directions.gif horizontal overview,
contact-sheet.png and manual Previous/Next controls. Every GIF has 8 frames and
infinite looping. aggregate-selection.json records all 64 selected file hashes,
including exact approved UR03 boot4-r4 and UL03 rather than rejected active
archives. DOWN-RIGHT's later arm repair and DOWN-LEFT remain IN REVIEW.

Opened source masters, native contact strip and actual browser review at normal
cadence; inspected manual passing 3/7 and opposite contact 5 plus slow comparison.
Evidence: browser.png, frame3-browser.png, frame5-browser.png, frame7-browser.png,
slow-browser.png. Two legs/arms, compact boots and contained silhouettes visible.
Similar contact 1/2 and 4/5/6 drawings reflect source timing; small generated boot
and contour differences remain. The rejected tracking sequence is explicitly
not proof of final leg identity. User approval and full in-game day/night
renderer validation remain outstanding; no runtime promotion is claimed.

Required engine suite PASS: 55 passed, 0 skipped, 0 failed in 502s (OVER BUDGET relative
to 300s suite target), 7768 headless asserts, 1006 input cases, both exports PASS.
Sim 1270427719 and data 8148086 unchanged. Full engine-check.log retained. Sprite
queue and diff checks PASS; completed queues unchanged. Preview-only follow-up;
no new backlog claim, simulation edits, project.godot staging, push or automation.
'''
for path in [REPO / 'implementation/PROGRESS.md', REPO / 'implementation/sprites/PROGRESS.md']:
    text = path.read_text(encoding='utf-8')
    if heading not in text:
        with path.open('a', encoding='utf-8', newline='\n') as output:
            output.write(entry)
print('Both journals contain the UR03 approval and DOWN-LEFT review evidence.')
