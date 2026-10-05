"""Append the preview correction evidence without marking a visual gate done."""
from pathlib import Path
ROOT=Path(__file__).resolve().parents[4]
entry='''

## 2026-10-05 - Full eight-pose upper diagonal arm review

User rejected the previous UP-RIGHT far-left arm amplitude and UP-LEFT mostly
static arm. Archived both current native cycles, exporters, approval pages and
metadata in before-full-arm-cycle; full-arm-cycle-baseline.json records all56
native preview PNG hashes. No queue task was claimed or marked done.

Built-in ImageGen produced three evaluated revisions for each direction:
full-arm-tracking-r11.png, full-arm-tracking-r12.png, full-arm-materials-r13.png.
The first two use fixed cyan anatomical LEFT and pink anatomical RIGHT arm
identities, white sleeves unchanged in color, diagrams for shoulder/elbow/hand
arcs. The second asks for sleeve/upper-arm rotation rather than hand jitter.
The third restores slim peach skin and further increases UP-RIGHT far-arm arc.
All sources are preserved under assets/art_source/player-fhd/pilots/2026-10-04.
Exact English prompts and references: full-arm-cycle-prompts.json,
full-arm-cycle-refinement-prompts.json, full-arm-cycle-material-prompts.json;
each direction generation.json records originals, dimensions and SHA256.

No code painting, limb deformation, mirroring or generated in-between pixels.
Python performs alpha thresholding, source cuts, one common32pxhat-width scale
per generated sheet, nearest resampling, packing and shared-palette GIF export.
Guide PNGs are abstract joint schematics, not code-drawn farmer art.

Measured R11 diagnostic lower-extent ranges: UP-RIGHT left4/right8px; UP-LEFT
left8/right5px. Both rejected internally for small far-arm travel. R12:
UP-RIGHT left5/right7px (left FAIL against planned6px gate), UP-LEFT left9/
right7px (PASS). No consecutive identical colored masks. Cyan detector was
corrected to exclude blue denim before recording these results. These metrics
are diagnostic color extents, not wrist landmarks or final-material proof.

Native/export scope checks PASS:16changed upper-diagonal poses,40other poses
byte-identical; binary80x80 alpha,8unique poses per direction, infinite8-frame
GIFs at100ms normal and200ms slow. UP-RIGHT material heights59-61px, UP-LEFT
62-65px, all final hat regions32px. Generated edits are not byte-identical
inside the16affected poses and can change lower-body details/proportions.

Visual gate NOT MET: UP-LEFT near arm7-to8 still rises more abruptly than
requested. Larger swing is observable, but this remains a review candidate,
not a completed smooth animation. The runner limits each asset to three
targeted visual revisions per task; that limit was reached for both directions.
No fourth generation, automatic approval or next direction was started.

Current GIF:up-diagonal-full-arms-r13.gif; slow prior/current:
up-diagonal-full-arms-before-after-r13.gif; colored/final:
up-diagonal-full-arms-tracking-r13.gif; aggregate:
all-walk-directions-full-arms-r13.gif. Generic aggregate/arm aliases and both
existing direction HTMLs refreshed. UP-LEFT current page remains open.
Normal browser playback and manual1/5/7/8 inspected; captures:
full-arms-frame1-browser.png, full-arms-frame5-browser.png,
full-arms-frame7-browser.png, full-arms-frame8-browser.png,
full-arms-review-browser.png. Full-page browser screenshot unsupported in this
view; viewport capture and scrolling produced usable evidence.

Sprite queue check PASS:20prompts with valid statuses/dependencies/index.
git diff --check PASS. Full engine suite not rerun: approval preview only,
outside runtime; no simulation, collision, input, gameplay or resolution edits.
Both upper diagonals remain awaiting review, DOWN-RIGHT unchanged awaiting
prior repair review, DOWN/RIGHT/UP/LEFT still approved, DOWN-LEFT not started.
Existing project.godot edits and unrelated untracked files preserved. No push,
automation, new thread or runtime integration.
'''
for relative in ['implementation/PROGRESS.md','implementation/sprites/PROGRESS.md']:
    with (ROOT/relative).open('a',encoding='utf-8',newline='\n') as handle:
        handle.write(entry)
