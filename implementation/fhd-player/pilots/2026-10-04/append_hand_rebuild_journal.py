"""Append the hand-correction review evidence to both repository journals."""
from pathlib import Path
ROOT=Path(__file__).resolve().parents[4]
entry='''

## 2026-10-05 - Rebuild upper diagonal hands and wrists

User rejected the current hand shapes and authorized another targeted rebuild.
Archived R13 native frames, metadata and contact sheets in before-hand-rebuild;
hand-rebuild-baseline.json records56native PNG hashes. References are unchanged
nearest-enlarged eight-pose sheets plus approved DOWN hand proportions.

Built-in ImageGen edits: hands-r14 in each direction reduced hand size but kept
raised/flat palm silhouettes. hands-r15 uses relaxed-wrist joint schematics:
small rounded palms, wrists below elbows, diagonal forearms, consistent hand
volume. UP-RIGHT hands-r16 tried to increase far-arm travel, but reintroduced
a bulky sharply bent fist1 and altered the near arm; rejected after viewing.
Selected hands-r15 in both directions. Three evaluated UP-RIGHT generations,
two UP-LEFT generations; no fourth or unevaluated generation.

Sources:assets/art_source/player-fhd/pilots/2026-10-04/walk-up-right and
walk-up-left. Exact prompts:hand-rebuild-prompts.json, hand-neutral-wrist-
prompts.json, hand-far-arm-prompt.json. Original ImageGen paths, dimensions,
SHA256 and decisions:hand-rebuild-calls.json and each generation.json.
neutral-wrist-guides.json/PNGs are abstract joint diagrams, not code-painted
farmer art. Python performs cuts, binary alpha, common hat-width calibration,
nearest scaling, packing and GIF composition only; no hand repaint or warp.

Preview validation PASS for scope/format:16changed upper-diagonal native poses,
40other PNGs byte-identical,8unique80x80binary-alpha frames per direction;
normal8x100ms and slow8x200ms infinite GIFs. UP-RIGHT heights60-63px, UP-LEFT
60-64px, hats31-32px. Source edits preserve design rather than byte-exact
unrelated pixels within edited poses. Body details can change in those16poses.
The earlier full arm-smoothing gate remains pending: UP-RIGHT far-left arm
travel is still subtle in R15. Hand silhouettes and overall gait await visual
approval; no numeric checks or manual inspection are labeled user approval.

Same direction HTMLs refreshed and UP-LEFT page remains open at?v=hands-r15.
Normal playback and manual1/4/7/8 inspected in browser. Capture evidence:
hand-rebuild-browser.png and hand-rebuild-frame{1,4,7,8}-browser.png.
Horizontal GIF:up-diagonal-hands-r15.gif; slow comparison:
up-diagonal-hands-before-after-r15.gif; aggregate:
all-walk-directions-hands-r15.gif. Generic aliases also refreshed.

Sprite queue check PASS:20prompts, valid dependencies/statuses/index.
git diff --check PASS. Full engine suite not rerun for isolated approval
previews outside runtime. No runtime integration, gameplay/collision/input/
simulation/resolution changes, next direction, queue mutations or push.
Both upper diagonals remain in review;40other native frames untouched.
Existing project.godot edits and unrelated untracked files preserved.
'''
for relative in ['implementation/PROGRESS.md','implementation/sprites/PROGRESS.md']:
    with (ROOT/relative).open('a',encoding='utf-8',newline='\n') as handle: handle.write(entry)
