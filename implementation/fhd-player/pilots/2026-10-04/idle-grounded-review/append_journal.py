"""Append the grounded idle integration and pending diagonal review evidence."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[5]
ENTRY = '''

## 2026-10-05 — grounded blue idle; diagonal walking review candidates

Ad hoc visual repair requested by the user, not a sprite queue advancement.
Claude's aece33f8 integration selected walking phases for idle; several boots
were suspended on stopping. Built-in ImageGen generated eight independent
neutral standing poses from the accepted identity and preserved edit targets.
Source: assets/art_source/player-fhd/idle-blue-grounded/idle-r1.raw.png,
SHA256 44bf86d816ac64b492291701e77697790f31e4bf61e3a556c219909f20ed4895.
Prompt, references and extraction evidence are under
implementation/fhd-player/pilots/2026-10-04/idle-grounded-review/.

Integrated eight source-owned idle poses into 24 existing runtime slots, with
exact-source manifest entries and a separate sealed runtime-idle-contract.json
(89ff7e6197d616815a0172b1c650c10f67c0f10f4bd204e2a8f0edb5837a348c).
One common 0.18 nearest source conversion retains 80x80 cells, pivot(40,72),
63–65px body height and existing 0.5 drawing scale (about128px at FHD).
All three idle slots intentionally share the same neutral pose; no blink is
authored. Garment-only mapping uses the approved RIGHT twelve-color blue ramp
under the user's explicit code-paint authorization. Alpha/non-garment pixels
remain invariant. Code does not draw or repair limbs. The blue promoter now
loads this idle contract, preventing regeneration of walking-frame aliases.
192 accepted review/source/runtime walking SHA256 hashes remain unchanged.

Stopping at every direction/phase is covered by locomotion regression; art
showcase passed2533 checks. Actual Godot renderer playback runs Player.tick
and PlayerView at normal30Hz, capturing at100ms for all eight directions,
day/night:3472 checks,0 failures. The original384 crops and48 full FHD frames
are in idle-grounded-review/runtime-captures/. Neutral boots were inspected
at native size and nearest3x, including physical FHD day/night scenes.

Full tools/verify.py initially returned54 passed,0 skipped,1 failed in632s
(OVER BUDGET), with both exports passing. The sole failure was the unchanged
timing-sensitive move-away/repair input fixture, HP88. An identical targeted
verify.check_script retry passed all1017 input cases in86.9s; no core, fixture,
clock or timing defaults changed. Logs retain the initial failure and retry.
Headless16137 assertions passed; sim3096784529/data3219365985 are unchanged.
Source promotion check, raster import, sprite queue check and diff check pass.
Rebuilding and importing integrated idle again produced0 changed outputs.

The user subsequently reported shaking UP-LEFT legs and UP-RIGHT hips during
walking, explicitly clarifying this occurs mid-cycle. These walking repairs
remain REVIEW CANDIDATES; production's accepted64 walking frames are untouched.
Fixed anatomical limb ownership and colored diagnostic joints apply concepts
from sprite_generator/fight/create_walk_guides.py and its ranger guide, with
sprite-sheet-creator walking phase prompts. Guides are instructions, not art.
UP-LEFT R1 retained duplicated reaching contacts; R2 shortened supporting
calves. Selected R3 poses1–6/8 share64px height. A separate ImageGen master
repairs only frame7's dipping passing boot, leaving the other15 candidate
PNGs byte-identical. Each individual pose has at most3 targeted revisions;
frame7 has2. UP-RIGHT R1 redraws a consistent pelvis/back-pocket silhouette.
All raw masters, prompts and per-frame source hashes are preserved alongside
diagonal-candidate/validation.json. Common scale and garment-only color mapping
preserve generated geometry and approved blue. No procedural limb painting.

Candidate playback is injected only into the isolated production-renderer
review fixture: final3472 checks,0 failures, normal30Hz day/night. Native and
nearest3x consecutive captures, 8x100ms before-after.gif and physical renderer
clips are preserved in diagonal-candidate/. Browser review confirms frame7
loads diagonal-r4, with screenshot diagonal-review-browser.png. Geometry,
alpha, palette, source immutability and clip timing pass; these checks cannot
prove fluid limb motion. Contact-pose anatomical identity remains subtle in
uniform blue; visual motion approval is pending with the user at
idle-grounded-review/index.html?v=grounded-r2#diagonal-review.

No queue mutation, unrelated project.godot staging, push or automation.
Idle is integrated; diagonal walking replacement awaits user visual review.
'''

if __name__ == '__main__':
    for rel in ['implementation/PROGRESS.md', 'implementation/sprites/PROGRESS.md']:
        path = ROOT / rel
        with path.open('a', encoding='utf-8') as journal:
            journal.write(ENTRY)
        print('Appended', rel)
