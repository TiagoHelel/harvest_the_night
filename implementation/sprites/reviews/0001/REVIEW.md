# Task 0001 visual review

Date: 2026-10-01. Six built-in ImageGen calls, one accepted source each, no
regeneration revisions. `generation/0001-record.json` records exact prompts,
input roles/source hashes and output source hashes. Original owner art preserved.

## Accepted scale

| Master | Native canvas | Visible content | Ground pivot |
|---|---|---|---|
| Farmer | 48x48 | 20x30 | 24,44 |
| House | 64x64 | 56x55 | 32,60 |
| Tree | 40x48 | 36x42 | 20,44 |
| Walker | 32x40 | 16x29 | 16,36 |

All crop boxes were measured from the generated source alpha at threshold 128.
Native review uses common aspect-preserving scaling per static master, nearest
sampling, binary alpha and the same 42-color palette. Tree width was adjusted
from the proposal so its natural canopy did not need clipping or stretching.

## Criteria and evidence

| Criterion | Result and evidence |
|---|---|
| Farmer identity | PASS: straw hat, dark hair, white sleeves, blue overalls and boots match owner identity; empty-handed south-facing neutral pose |
| Shared language | PASS: farmer/house/tree/walker use stepped contours, clustered shading, upper-left daylight and colored dark outline; reviewed raw sources and native alpha contact sheet |
| Material/function | PASS: terracotta roof and timber facade, clear tree trunk/canopy, rot skin and slouched walker; house and tree no longer smaller than the worker |
| Scale consistency | PASS for source review: `scale-grid.png` and `scale-grid-3x.png` show every master against 16 px cells; farmer 30 px body versus existing approximately 44 px body |
| Transparency | PASS after specified native conversion: `alpha-contact.png`/`-3x.png` show white, dark, checker and grass backgrounds; binary alpha, no opaque rectangles or low-alpha glow retained |
| Bounds and pivots | PASS: native boxes fit their fixed canvases, full hat/roof/chimney/canopy/boots visible; ground pivot recorded; future animation will preserve those pivots |
| Silhouettes | PASS: `silhouettes.png` differentiates canopy, house, hat-wearing farmer and thin slouched walker |
| Day/night recognition | PASS for lighting reference: `style-day.png`/`style-night.png` retain one house/tree/farmer/walker, path, tilled patch and water bank; night is blue/violet with localized amber windows, pale clothes subdued |
| Native display | PASS for references: inspected `style-day-480.png`/`style-night-480.png`, native and 3x master views; prototypes remain recognizable at native resolution |
| Runtime integration | Deferred by task scope to 0002/0003; this task does not claim new art is already shown by gameplay |
| Other directions/actions | Deferred by task scope to 0004–0006/0015; these sources are one-pose identity masters, not animation sheets |

The scene-study object sizes are illustrative; use the measured native master
contract as the authoritative scale source. Future ground art needs quieter
texture than the concept scene. Ground shadows, lamp origins and depth sorting
require the task 0003 playable pilot; no new collision footprint was introduced.

The generated tree source has soft alpha on many pixels. Thresholding is part
of the declared conversion and its cleaned native silhouette was reviewed over
all four backgrounds. It is not safe to drop the raw large source directly into
the renderer and assume its alpha/pixel density already matches the other assets.
