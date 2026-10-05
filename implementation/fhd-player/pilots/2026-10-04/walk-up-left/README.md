# Walk up-left: one-direction approval candidate

The user approved UP-RIGHT R6 with "aprovado" on 2026-10-05. This task
produces UP-LEFT only; DOWN-LEFT still awaits the next approval.

The requested sprite_generator hero-generation-plan.md permits directional
reflection when handedness does not matter. This walk has no held props. Built-in
ImageGen first establishes a rear-left neutral master, then receives the eight
approved UP-RIGHT R6 poses as the gait authority. The reference atlas is a
lossless packing with integer nearest enlargement, not Python-generated art.
No Python artwork reflection or limb deformation is used.

R1 incorrectly leaves the bottom row facing up-right and is rejected. R2
corrects that orientation, but its passing7 repeats the support leg of3 and its
reaching8 does not complete the opposite recovery. R3 is a targeted two-pose
ImageGen edit of approved UP-RIGHT7/8 into UP-LEFT. In the selected result the
near left leg recovers while the far right leg supports;8 extends/lowers into1.
R2 poses1-6 remain byte-identical after this correction. Historical validation,
contact sheets and comparison GIFs are retained under rejected-r1 and
before-recovery-r2. Raw sources, exact prompts and provenance remain available.

Selected art: materials-r2.png for1-6, recovery-r3.png for7-8 under
assets/art_source/player-fhd/pilots/2026-10-04/walk-up-left. Run
export_preview.py for deterministic alpha threshold128, cuts, nearest sampling
and fixed hat-center/top anchoring. One common whole-source scale is used for
R2; the two-pose recovery is uniformly calibrated to the approved32px hat.
Native frames are80x80; visible heights62-64px, hats31-33px. Proposed FHD display
uses integer2x, about128px body height. The pair is not a pixel-exact mirror;
small contour, boot-angle and arm-phase differences remain. No colored anatomy
proof is claimed for this reuse of an already approved gait.

Review artifacts:
- up-diagonals-comparison-r3.gif: approved UP-RIGHT beside UP-LEFT at2x and4x.
- gait-comparison-slow.gif: the same pair at200ms per frame.
- idle-walk-up-left.gif: standing master, walk and detail.
- contact-sheet.png: approved direction above candidate, all eight phases.
- walk-up-left-strip.png and frames/: transparent native assets.
- index.html: animations and manual previous/next controls.
- browser-review-r3.png: browser evidence after inspecting7/8 and wrap to1.
- ../all-walk-directions-seven-r1.gif: seven-direction horizontal overview.

Exporter, GIF loop/duration checks and unchanged approved-frame hashes pass.
All48 approved source frame files are unchanged. HTML playback and the manual
7,8,1 sequence were inspected in the in-app browser. The main HTML image can
shrink responsively in a narrow browser; exported PNG/GIF artifacts retain
the stated integer sampling. Preview only, not integrated or rendered inside
the game. No engine suite rerun for this isolated preview; the previous full
PASS is recorded in ../walk-up-right/verify-result.json and does not prove gait
quality. Existing project.godot edits are preserved.

Await explicit approval of UP-LEFT before generating DOWN-LEFT.
