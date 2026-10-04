# Walk left: one-direction approval candidate

The user approved UP with "perfeito, proximo". This task produces LEFT only.
Down, corrected right and up remain the approved direction references.

The sprite_generator hero-generation-plan.md allows reflecting a right walk
for the left direction when handedness does not matter. This farmer has no
held tools or asymmetric hand props in the walk. Built-in ImageGen receives
the approved right materials-r3 as the limb/proportion authority and requests
per-cell reflection, preserving eight-frame order. No Python artwork reflection
or newly designed anatomy is used. The approved right standing reference is
not used because its earlier leg proportions were not approved.

R1 preserves identity and size but changes the arm phases and far-leg passing
pose. It is rejected internally. R2 explicitly maps near/far hip ownership,
opposite contacts, bent-knee recovery and arm counter-swing back to approved
right. Both trouser chains recover in opposite halves of R2. The near arm changes
forward a frame later than approved right, so R2 is a generated directional
counterpart, not an exact reflected pixel copy. User review remains required.
Exact prompts and call provenance are saved; both raw masters are retained.

Run export_preview.py to cut selected materials-r2, threshold alpha at 128,
apply one common scale to all eight frames, and anchor by hat center/top.
Native frames are 80x80, targeting 64px visible height. Main horizontal GIF
compares unchanged approved right with candidate left at integer 2x proposed
FHD display and 4x detail. Includes a 200ms slow GIF, contact sheet, transparent
strip and HTML individual-frame controls. No colored anatomy masks are claimed
for this directional reuse of an already reviewed gait.

Validated eight unique RGBA frames, loop timing 8x100ms, transparent background,
source gutter and same-scale visual comparison. The native strip/contact sheet
and browser view were inspected; HTML Next advances the frame indicator.
Preview scale is proposed only: no engine rendering or runtime integration is
included, and the game verification suite was not rerun for this isolated pilot.

Await explicit approval of LEFT before generating down-right or other diagonals.
