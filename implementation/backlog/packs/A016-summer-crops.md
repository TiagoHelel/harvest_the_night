# A016 - Summer crops

- **Status:** todo
- **For game task:** 0199
- **Dressed by game tasks:** 0168
- **Spec after game task:** 0168
- **Family:** crops
- **Mode:** A - raw ImageGen sources, Claude reduces them to the 42-colour palette
- **Size of the job:** 14 crop frames in 4 strips (one of them tall); 7 icon sources cut to 14 icons (3 produce, 4 seed packets)

## What it is for

Summer (days 15-28) grows corn, pepper, sunflower and melon (a watermelon:
"melancia"). This pack draws the three new ones through their four growth
stages, the regrowing stage of pepper and of today's corn after picking (0172),
their produce icons, and the seed packets the stall sells for the four summer
crops (0170). The player sees them on tilled plots all summer day and under the
night relight, at 1 art px = 4x4 screen px beside the 128 px farmer. The
sunflower is the tall one: ripe, it stands almost as high as the farmer and is
the beehive's flower, so its yellow head must read from across the farm. Each
species and stage must read by silhouette and colour at 1x. Until it arrives,
0168, 0170 and 0172 draw tinted stand-ins.

## Deliverables

The table is provisional: game task 0168 settles the final canvas/footprint/states and updates it; start only when `python implementation/backlog/assets.py next` offers this pack.

| Runtime name | Native canvas | Pivot | Frames / seconds / loop | Notes |
|---|---|---|---|---|
| `crops/pepper_0..3` | 16x16 | (8,14) | 4 stages (planted, sprout, growing, ripe), static 0.55, no loop | One 5-cell strip with the regrow stage, one scale. |
| `crops/pepper_regrow` | 16x16 | (8,14) | 1, static 0.55, no loop | Cell 5 of the pepper strip. |
| `crops/sunflower_0..3` | 16x32 | (8,30) | 4 stages, static 0.55, no loop | Tall crop. One strip, one scale. |
| `crops/melon_0..3` | 16x16 | (8,14) | 4 stages, static 0.55, no loop | One strip, one scale. |
| `crops/corn_regrow` | 16x24 | (8,22) | 1, static 0.55, no loop | Today's corn after picking. Must match `corn_3`'s pixel scale (see Recipe). |
| `ui/icon_pepper` + `ui/hud_pepper` | 16x16 / 10x10 | (8,8) / (5,5) | 1, static 1.0, no loop | One source: one red chili with a green stem, on a diagonal. |
| `ui/icon_sunflower` + `ui/hud_sunflower` | 16x16 / 10x10 | (8,8) / (5,5) | 1, static | One source: a sunflower head (yellow petals, brown seed disc) on a short stem. |
| `ui/icon_melon` + `ui/hud_melon` | 16x16 / 10x10 | (8,8) / (5,5) | 1, static | One source: a whole striped watermelon with a wedge cut out showing red flesh. |
| `ui/icon_corn_seed` + `ui/hud_corn_seed`, `ui/icon_pepper_seed` + `ui/hud_pepper_seed`, `ui/icon_sunflower_seed` + `ui/hud_sunflower_seed`, `ui/icon_melon_seed` + `ui/hud_melon_seed` | 16x16 / 10x10 | (8,8) / (5,5) | 1 each, static | One source each: an edit of A015's approved packet master with the summer band. |

Crop ids are 0168's plain names; packet ids are 0170's `<crop>_seed` resources;
`<crop>_regrow` is the stage 0172 draws.

**Stage targets** (visible height in px; heights rise strictly from stage 0 to
3; lowest opaque row is pivot_y - 1; bounding box inside x 1-14 and y >= 1;
centred on x=8 ±1; at most 150 opaque px over the plot cell, i.e. in rows 0-13
of a 16x16 frame, rows 6-21 of 16x24, rows 14-29 of 16x32, so at least 80
wet-soil px stay visible, `check_crop_art.py`):

| Crop | 0 planted | 1 sprout | 2 growing | 3 ripe | regrow |
|---|---|---|---|---|---|
| pepper | seed mound, 2-3 | two leaves, 4-5 | small bushy plant, 7-8 | bush with 2-3 hanging red chilies, 10-12 | the bush with white flowers and small green pods, no red; height from stage 2's to stage 3's, distinct from both |
| sunflower (16x32) | seed mound, 2-3 | two leaves, 5-7 | stalk with broad leaves and a closed green bud, 14-18 | stalk 2 px wide, leaves, a big yellow head 9-12 wide with a brown seed disc, slightly tilted to the viewer, 24-28 | - |
| melon | seed mound, 2-3 | two broad leaves, 4-5 | spreading vine with leaves and a yellow flower, 6-7 | one striped green watermelon 10-13 wide lying on the vine, 8-11 | - |
| corn (16x24) | - | - | - | - | `corn_3`'s stalk and leaves with the cobs picked (short husk stubs allowed), 17-19 tall (`corn_3` is 20), at most 12 wide |

**Recipe values (mode A).** Crops: no `palette_keys` (full palette, like
today's crops); one `content_scale` per strip, chosen so the ripe stage meets
its height; each stage's `crop_xywh` = its measured box in its cell, bottom on
the lowest opaque raw row, centred on the stem; default content anchor.
`corn_regrow` comes from a 2-cell strip: cell 1 a calibration copy of the ripe
corn, cell 2 the regrowing stalk; its `content_scale` is the one that reduces
cell 1 to exactly 20 px tall (`corn_3`); only cell 2 is delivered, and the call
record says which cell was used. Icons and packets: exactly as A015 (produce
visible at most 14 / 8 with anchors (w//2, h//2); packets visible box x 2-13, y
1-14 at 16x16 and x 2-8, y 1-8 at 10x10, anchors (6,7) and (3,4)).

## Match these

- `sprites/crops/corn_0..3.png` (16x24, heights 2/4/11/20) and raw `assets/art_source/crops/corn.png` (1983x793): the tall-crop scale, and the stalk `corn_regrow` must continue.
- `sprites/crops/carrot_0..3.png`, `wheat_0..3.png` and raw `assets/art_source/crops/carrot.png`: 16x16 stage sizes, `night`/`ink` outline, light, strip layout.
- A015's approved delivery `implementation/backlog/deliveries/A015-spring-crops/`: its crops (scale, style) and its packet master (the raw its `contract.json` lists as the source of `icon_carrot_seed`, and `native/icon_carrot_seed/none/01.png`, `native/hud_carrot_seed/none/01.png`). If A015 is not approved, ask the owner; without an answer run `python implementation/backlog/assets.py set A016 blocked "waiting for A015 approval"` and stop.
- `sprites/crops/tilled.png`, `tilled_wet.png`; `sprites/ui/icon_corn.png`, `hud_corn.png`, raw `assets/art_source/ui/corn.png`.
- `docs/reference-sheet.png` (its field of sunflowers, top left); the farmer `implementation/fhd-player/pilots/2026-10-06/walk-final-mirrored/native-40/walk/down/01.png`.

## How to make it

1. Safety first (CODEX-RUNNER step 1): `python tools/task.py list done` must
   list 0168. Re-read this table: 0168 may have changed it.
2. Crops: PROMPTS.md BASE + CROP + STRIP + CORRECTION for revisions, braces
   filled with the canvas, pivot and stage list of the table (CROP's
   `{wheat/corn/carrot}` line replaced by the species line).
   `transparent_background=true`. One species per call: pepper 5 cells
   (planted, sprout, growing, ripe, regrow), sunflower and melon 4 cells. Attach
   `assets/art_source/crops/carrot.png` (16x16 crops) or
   `assets/art_source/crops/corn.png` (sunflower) as "approved crop strip:
   layout, scale and style reference", and `docs/reference-sheet.png` as style.
3. `corn_regrow`: one 2-cell call, ordered "ripe corn (calibration copy of the
   attached ripe stage), the same corn plant after its cobs were picked", with
   `assets/art_source/crops/corn.png` attached as "identity master: the corn
   plant to keep".
4. Produce icons: BASE + ICON, one item per call, `transparent_background=true`,
   `assets/art_source/ui/corn.png` attached as "approved icon: style and size
   reference".
5. Packets: each one an edit of A015's accepted packet-master raw (role "edit
   target: packet master"): "change only the picture on the front to {produce}
   and the top band to the summer gold; keep the paper, outline, size and
   position". All four share the master's crop size and two scales.
6. One candidate per call; at most 3 targeted revisions per asset.

## Review with the owner

`index.html` shows, at 1x and 4x (nearest): each species' stages in a row on
`tilled.png` and on `tilled_wet.png` plots; a 4x3 field of each ripe crop; the
sunflower stages beside `corn_0..3` and the farmer, feet on the same ground
line; `pepper_regrow` between `pepper_2` and `pepper_3`, `corn_regrow` between
`corn_2` and `corn_3`; the icons on light and dark backgrounds beside
`icon_corn` / `hud_corn`; all packets delivered so far (A015 and this pack, and
A017 if delivered) in one row. Day and night preview (contract 9.5), a 16px grid
toggle. Static art, nothing plays.

Ask the owner (pt-BR):

1. "O girassol maduro ficou na altura certa ao lado do fazendeiro e do milho, e a flor amarela se vê de longe?"
2. "A pimenta e a melancia se distinguem bem do morango e entre si, a 1x, de dia e à noite?"
3. "O milho e a pimenta rebrotando (sem frutos maduros) se distinguem bem do estágio maduro?"

## Acceptance

- [ ] 28 files: 8 + 1 frames at 16x16 / (8,14), 4 at 16x32 / (8,30), 1 at 16x24 / (8,22); 7 icons at 16x16 / (8,8) and 7 at 10x10 / (5,5); 1 static frame each.
- [ ] Binary alpha, true transparent background; no baked soil, shadow, glow, night version or text.
- [ ] Mode A: `render_source` with each recorded recipe reproduces `native/`; one `content_scale` per crop strip; `corn_regrow`'s calibration cell reduces to 20 px.
- [ ] Every stage meets the stage targets (grounded on pivot_y - 1, centred, heights rising, at most 150 px over the plot cell); four distinct stages per species; each regrow differs from stages 2 and 3 of its crop.
- [ ] Icons: inside the canvas with a clear 1 px margin, more than 24 (16x16) / 7 (10x10) opaque px, at least 2 colours, no two identical.
- [ ] The packets have exactly A015's packet box and paper, differ only by picture and band, and each differs from its produce icon at both sizes.
- [ ] At 1x, by day and in the night preview, every species and stage reads; the ripe sunflower and the melon do not look lit.

## Delivery

- Folder `implementation/backlog/deliveries/A016-summer-crops/`, with the files of contract 9.1: `raw/` (+ `.prompt.txt`, `.call.json`), `native/<anim>/none/01..NN.png` (`native/sunflower/none/01..04.png`, `native/corn_regrow/none/01.png`, `native/icon_melon/none/01.png`, `native/hud_melon/none/01.png`), `preview/`, `rejected/`, `contract.json` (its `references` include A015's packet master with its sha256), `checks.json` (with `wet_cue_exposed`, `stages_rise`, `icon_bounds_ok`, `packets_same_box`), `build.py`, `index.html`, `review-log.txt`.
- `CLAUDE-A016-PROMPT.txt` maps each file, e.g. `native/sunflower/none/01..04.png -> sprites/crops/sunflower_0..3.png  16x32 pivot (8,30) draw 1.0 static (0.55, no loop)`, `native/corn_regrow/none/01.png -> sprites/crops/corn_regrow.png  16x24 pivot (8,22)`, `native/icon_pepper_seed/none/01.png -> sprites/ui/icon_pepper_seed.png  16x16 pivot (8,8) static (1.0)`; and names the stand-ins replaced (0168, 0170, 0172).
- Last step, only after the owner approves in words recorded in `APPROVAL.json`: `python implementation/backlog/assets.py set A016 approved`.
