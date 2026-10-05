# DOWN-LEFT preview — 2026-10-05

The user approved UR03 `boot4-r4`. Its exact eight PNG hashes are frozen in
`../selected-UR03-UL03/UR03-approval.json`. This folder contains the next and
last walking direction for individual review. DOWN-LEFT remains awaiting user
approval. No runtime files were replaced.

## Production and selection

All new farmer drawings use built-in `image_gen`. Exact arguments are in the
six `*.prompt.json` files; `*.call.json` retain original output paths, workspace
copies, input hashes, output hashes, dimensions and per-attempt evaluation.
Source PNGs are under
`assets/art_source/player-fhd/pilots/2026-10-04/walk-down-left/`.

The `sprite_generator` concepts were tried: rotate first, opposite contact
masters, cyan/magenta anatomical leg ownership, fixed hip roots and four-phase
transition guides. Contacts R1 had oversized head/boots; R2 corrected the style
but did not establish reliable motion. Both transition-A attempts repeated the
far foot position and exchanged the apparent leg ownership. The full colored
cycle R3 also failed ownership and opposite contacts. These sources are retained
as rejected attempts and were **not** used for the final pose source.

The selected `materials-r1.png` is a separate built-in direction edit of the
existing DOWN-RIGHT eight-frame timeline, reflecting each sprite's direction
while preserving frame order. This provided the approved diagonal movement and
body proportions as the direct reference. It is not a programmatic mirror and
the generated output is not a pixel-exact reflection of the input. There was
one direction-only material edit, without additional targeted revisions.

`prepare_down_left.py` is a **one-time bootstrap**, not a safe review-export
command: rerunning it would reset status and the pre-production baseline.
`build_review.py` can regenerate the review from the saved sources. It uses one
common nearest sampling scale per sheet, fixed hat-center/top anchors, binary
alpha cleanup and deterministic cuts. Python never draws, warps or mirrors the
farmer. Native frames are 80x80, artwork 60–63px tall, hat region 31–33px wide.

## Review

- `index.html`: normal integer 2x display with approved DOWN beside it.
- `walk-down-left.gif`: eight drawings at 100ms per frame, infinite loop.
- `walk-down-left-slow.gif`: 200ms comparison against DOWN-RIGHT at integer 4x.
- `contact-sheet.png`: all eight poses; manual Previous/Next controls in HTML.
- `all-eight-walk-directions.gif`: horizontal overview. Approved UR03 boot4-r4
  and approved UL03 are selected explicitly, not their rejected active archives.
  DOWN-RIGHT's later arm repair and the new DOWN-LEFT still carry IN REVIEW.
- `browser.png`, `frame3-browser.png`, `frame5-browser.png`, `frame7-browser.png`,
  `slow-browser.png`: actual browser review evidence.

Visual inspection covers normal cadence, the two passing poses 3/7, the opposite
contact 5 and all eight silhouettes. Two limbs remain readable, with compact
boots and no clipping. Contact phases 1/2 and 4/5/6 have similar poses, reflecting
the reference timing; generated small contour/boot differences remain. This is
a review candidate, not a claim of perfect anatomy or automatic visual approval.
The rejected colored sheet does not prove the final animation's leg identity.

## Checks

`validation.json` records eight unique native drawings, timings, canvas/alpha,
sampling and file hashes. All 72 pre-existing native frame hashes match the
baseline. Format/scope checks do not prove animation quality.

Required engine suite: **55 passed, 0 skipped, 0 failed**, 502s (over the suite's
300s target). Headless: 7768 asserts; input: 1006 cases; both exports passed.
Sim 1270427719 and data 8148086 unchanged. Sprite queue and diff checks pass.
`engine-check.log` contains the full output. Engine scenes were not changed;
browser GIFs are the changed preview surface. No game capture is claimed as
validation of these unintegrated sprites.
