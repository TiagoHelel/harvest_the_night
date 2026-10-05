## Arm smoothing follow-up - 2026-10-05

Current arm candidate: arms-r9.png plus arm-05-06-r10.png overrides5/6 only. Near arm now hangs naturally by the left hip instead of crossing the central back. The other six native poses are byte-identical. Current main GIF: up-diagonals-arms-r10.gif. Both directions before/after: ../up-diagonal-arms-before-after.gif. Exact prompts/provenance: generation.json. Preview only and awaiting user review.

## Arm correction - 2026-10-05

Current candidate: arms-r9.png. Both arms counter-swing; far right arm is partly occluded in phases4/5. Native hats32px in every pose; heights62-65px. Export calibrates the generated sheet against the prior R7 hat width with one common scale. The generated edit preserves the design and gait poses, not byte-exact pixels inside those edited poses. Current GIF: up-diagonals-arms-r9.gif. Before/after: ../up-left-arms-before-after.gif. Exact prompts and provenance: generation.json. Still preview-only and awaiting review.

# Walk up-left: full rebuild R7 review

The user rejected R3 because frames1/2 exchange leg ownership and4 is bugged,
and requested all eight poses rebuilt. This candidate uses all new drawings;
no R3 native frame is retained. The previous candidate and exporter are preserved
under rejected-r3. Six other walking directions remain approved and unchanged.

Built-in ImageGen constructs a new colored gait using the rotated identity and
fixed hip-knee-ankle schematic. Near LEFT is cyan, far RIGHT is pink; each root
stays below its own rear pocket. R4 and R5 still swap roots5/6, detected both
visually and by check_rebuild_colors.py. A third isolated diagnostic generation
constructs crossed opposite contacts5/6 from the fixed waist of1. The assembled
R6 diagnostic passes all8root-order checks and opposite contacts1/5. These
centroids do not prove full anatomical connectedness or smooth motion.

pack_rebuild_tracking.py performs source cuts, binary alpha, uniform source/head
reference calibration, nearest sampling and packing only. No Python art repaint,
reflection, bone warping or leg reshaping. Source row cut478 follows an actual
empty gutter, preventing the next row's hat from entering a previous cell.
ImageGen restores denim/leather in R6, then R7 corrects the undersized hat and
short5/6calves. Material silhouettes differ from diagnostic pixels: this is
recorded in review-check.json, not described as a pixel-exact geometry match.

Selected raw art: assets/art_source/player-fhd/pilots/2026-10-04/walk-up-left/
rebuild-materials-r7.png. Exact prompts, references, original paths, dimensions,
SHA256 and rejection history are recorded in generation.json. Diagnostic masters
R4/R5, isolated pairR6, packed native/reference atlas and raw materialR6/R7 remain
preserved. Three diagnostic attempts and two material attempts were evaluated.

Run export_preview.py for80x80native frames, one common scale and fixed hat-top
anchor. Visible heights62-66px and hat widths31-32px, matching the approved head
width. Normal GIFs8x100ms, slow/color comparisons8x200ms, shared palette, no blur.
All8previous UP-LEFT frames replaced; all48approved frame PNGs unchanged by SHA256.

Review files:
- up-diagonals-rebuilt-r7.gif: approved UP-RIGHT beside full UP-LEFT rebuild.
- tracking-materials-rebuild-r7.gif: cyanLEFT/pinkRIGHT source beside materials.
- idle-walk-up-left.gif, gait-comparison-slow.gif, transparent strip/contact sheet.
- index.html: same review URL, visible diagnostic comparison and manual controls.
- rebuild-tracking-r6-reference-color-check.json: fixed upper roots and contacts.
- browser-frame4-r7.png and browser-review-r7.png: actual browser evidence.
- ../all-walk-directions-rebuilt-up-left-r7.gif: updated seven-direction overview.

Inspected raw colored chains, native material contact sheet, normal browser
playback and manual2/4. User motion approval remains pending. Existing game is
unchanged; no integration, resolution/collision/simulation/balance/queue changes.
No engine suite rerun for isolated review assets. Earlier full engine PASS remains
in ../walk-up-right/verify-result.json and does not approve the gait. Preserve
unrelated project.godot edits. Await UP-LEFT approval before starting DOWN-LEFT.

## Earlier rejected R3 candidate

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
