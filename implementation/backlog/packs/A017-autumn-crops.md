# A017 - Autumn crops

- **Status:** integrated
- **For game task:** 0200
- **Dressed by game tasks:** 0168
- **Spec after game task:** 0168
- **Family:** crops
- **Mode:** A - raw ImageGen sources, Claude reduces them to the 42-colour palette
- **Size of the job:** 13 crop frames in 3 strips (one of them tall); 7 icon sources cut to 14 icons (3 produce, 4 seed packets)

## What it is for

Autumn (days 29-42) grows wheat, pumpkin, grape and beet. This pack draws the
three new ones through their four growth stages, the grape's regrowing stage
after picking (0172), their produce icons, and the seed packets the stall sells
for the four autumn crops (0170). The player sees them on tilled plots all
autumn day and under the night relight, at 1 art px = 4x4 screen px beside the
128 px farmer. The grape grows on a wooden trellis and is the tall one; the
pumpkin is also the catapult's ammunition, so its icon is seen at night too.
Each species and stage must read by silhouette and colour at 1x. Until it
arrives, 0168, 0170 and 0172 draw tinted stand-ins.

## Deliverables

Final geometry settled by game task 0168: four static stages at draw scale 1.0; 16x16 at (8,14), except sunflower and grape at 16x32, (8,30). Existing corn remains 16x24 at (8,22). Regrow frames and seed packets are reserved for 0172 and 0170. Start only when `python implementation/backlog/assets.py next` offers this pack.

| Runtime name | Native canvas | Pivot | Frames / seconds / loop | Notes |
|---|---|---|---|---|
| `crops/pumpkin_0..3` | 16x16 | (8,14) | 4 stages (planted, sprout, growing, ripe), static 0.55, no loop | One strip, one scale. |
| `crops/grape_0..3` | 16x32 | (8,30) | 4 stages, static 0.55, no loop | Tall crop on a trellis. One 5-cell strip with the regrow stage, one scale. |
| `crops/grape_regrow` | 16x32 | (8,30) | 1, static 0.55, no loop | Cell 5 of the grape strip. |
| `crops/beet_0..3` | 16x16 | (8,14) | 4 stages, static 0.55, no loop | One strip, one scale. |
| `ui/icon_pumpkin` + `ui/hud_pumpkin` | 16x16 / 10x10 | (8,8) / (5,5) | 1, static 1.0, no loop | One source: one ribbed orange pumpkin with its stem. |
| `ui/icon_grape` + `ui/hud_grape` | 16x16 / 10x10 | (8,8) / (5,5) | 1, static | One source: a bunch of dark grapes with one leaf. |
| `ui/icon_beet` + `ui/hud_beet` | 16x16 / 10x10 | (8,8) / (5,5) | 1, static | One source: one dark-red beet root with its leaves. |
| `ui/icon_wheat_seed` + `ui/hud_wheat_seed`, `ui/icon_pumpkin_seed` + `ui/hud_pumpkin_seed`, `ui/icon_grape_seed` + `ui/hud_grape_seed`, `ui/icon_beet_seed` + `ui/hud_beet_seed` | 16x16 / 10x10 | (8,8) / (5,5) | 1 each, static | One source each: an edit of A015's approved packet master with the autumn band. |

Crop ids are 0168's plain names; packet ids are 0170's `<crop>_seed` resources;
`<crop>_regrow` is the stage 0172 draws.

**Stage targets** (visible height in px; heights rise strictly from stage 0 to
3; lowest opaque row is pivot_y - 1; bounding box inside x 1-14 and y >= 1;
centred on x=8 ±1; at most 150 opaque px over the plot cell, i.e. in rows 0-13
of a 16x16 frame and rows 14-29 of 16x32, so at least 80 wet-soil px stay
visible, `check_crop_art.py`):

| Crop | 0 planted | 1 sprout | 2 growing | 3 ripe | regrow |
|---|---|---|---|---|---|
| pumpkin | seed mound, 2-3 | two leaves, 4-5 | vine with leaves and a small green pumpkin, 6-7 | one big ribbed orange pumpkin 10-13 wide, green stem, a leaf, 9-11 | - |
| grape (16x32) | planted cutting in a mound, 2-3 | young vine tied to a short stake, 8-12 | the trellis (two wooden posts and a crossbar) with the vine climbing it, leaves, no fruit, 22-25 | the full vine over the trellis, leaves arching 1-3 px over the crossbar, 3-4 dark grape bunches, 25-28 | the ripe stage's trellis and foliage with small green clusters instead of ripe bunches; height from stage 2's to stage 3's, distinct from both |
| beet | seed mound, 2-3 | two leaves, 4-5 | leafy rosette with red stems, 7-8 | taller leaves with red veins, a round dark-red root shoulder at the soil line, 10-12 | - |

The trellis first appears at stage 2, because `check_crop_art.py` needs every
stage taller than the last. Stages 2, 3 and regrow show the same trellis: same
posts, same crossbar row, same width (±1 px). Grapes default to dark
blue-violet (they reduce to `cloth_dark`/`cloth`/`night_light` with a
`cloth_light` highlight); every bunch keeps at least 2 colours after reduction,
never one dark blob.

**Recipe values (mode A).** Crops: no `palette_keys` (full palette, like
today's crops); one `content_scale` per strip, chosen so the ripe stage meets
its height; each stage's `crop_xywh` = its measured box in its cell, bottom on
the lowest opaque raw row, centred on the stem (for the grape, on the
trellis); default content anchor. Icons and packets: exactly as A015 (produce
visible at most 14 / 8 with anchors (w//2, h//2); packets visible box x 2-13, y
1-14 at 16x16 and x 2-8, y 1-8 at 10x10, anchors (6,7) and (3,4)).

## Match these

- `sprites/crops/wheat_0..3.png` (heights 2/4/8/12), `carrot_0..3.png` and raws `assets/art_source/crops/{wheat,carrot}.png`: 16x16 stage sizes, `night`/`ink` outline, light, strip layout.
- `sprites/crops/corn_0..3.png` (16x24) and raw `assets/art_source/crops/corn.png`: tall-crop scale for the grape.
- A015's approved delivery `implementation/backlog/deliveries/A015-spring-crops/`: crop scale and style, and its packet master (the raw its `contract.json` lists as the source of `icon_carrot_seed`, and `native/icon_carrot_seed/none/01.png`, `native/hud_carrot_seed/none/01.png`). If A015 is not approved, ask the owner; without an answer run `python implementation/backlog/assets.py set A017 blocked "waiting for A015 approval"` and stop.
- `sprites/props/stump.png`, `tree.png`: the warm wood the trellis is built from.
- `sprites/crops/tilled.png`, `tilled_wet.png`; `sprites/ui/icon_wheat.png`, `hud_wheat.png`, raw `assets/art_source/ui/wheat.png`.
- `docs/reference-sheet.png`; the farmer `implementation/fhd-player/pilots/2026-10-06/walk-final-mirrored/native-40/walk/down/01.png`.

## How to make it

1. Safety first (CODEX-RUNNER step 1): `python tools/task.py list done` must
   list 0168. Re-read this table: 0168 may have changed it.
2. Crops: PROMPTS.md BASE + CROP + STRIP + CORRECTION for revisions, braces
   filled with the canvas, pivot and stage list of the table (CROP's
   `{wheat/corn/carrot}` line replaced by the species line).
   `transparent_background=true`. One species per call: grape 5 cells
   (planted, sprout, growing, ripe, regrow), pumpkin and beet 4 cells. Attach
   `assets/art_source/crops/wheat.png` (16x16 crops) or
   `assets/art_source/crops/corn.png` (grape) as "approved crop strip: layout,
   scale and style reference", and `docs/reference-sheet.png` as style. For the
   grape add: "the same trellis in the growing, ripe and regrow cells".
3. Produce icons: BASE + ICON, one item per call, `transparent_background=true`,
   `assets/art_source/ui/wheat.png` attached as "approved icon: style and size
   reference".
4. Packets: each one an edit of A015's accepted packet-master raw (role "edit
   target: packet master"): "change only the picture on the front to {produce}
   and the top band to the autumn red; keep the paper, outline, size and
   position". All four share the master's crop size and two scales.
5. One candidate per call; at most 3 targeted revisions per asset.

## Review with the owner

`index.html` shows, at 1x and 4x (nearest): each species' stages in a row on
`tilled.png` and on `tilled_wet.png` plots; a 4x3 field of each ripe crop; the
grape stages beside `corn_0..3` and the farmer, feet on the same ground line;
`grape_regrow` between `grape_2` and `grape_3`; the icons on light and dark
backgrounds beside `icon_wheat` / `hud_wheat`; all packets delivered so far
(A015, A016 if delivered, and this pack) in one row. Day and night preview
(contract 9.5), a 16px grid toggle. Static art, nothing plays.

Ask the owner (pt-BR):

1. "Na uva, a treliça aparece a partir do estágio 'crescendo', porque a checagem do jogo exige que cada estágio seja mais alto que o anterior. Está bom, ou prefere a treliça desde o plantio, como no Stardew (aí a tarefa 0200 precisa mudar essa checagem)?"
2. "A uva azul-violeta escura lê bem a 1x e na prévia noturna, ou prefere uva verde?"
3. "A abóbora e a beterraba maduras leem bem e não se confundem com a cenoura?"

## Acceptance

- [ ] 27 files: 8 frames at 16x16 / (8,14), 4 + 1 at 16x32 / (8,30); 7 icons at 16x16 / (8,8) and 7 at 10x10 / (5,5); 1 static frame each.
- [ ] Binary alpha, true transparent background; no baked soil, shadow, glow, night version or text.
- [ ] Mode A: `render_source` with each recorded recipe reproduces `native/`; one `content_scale` per crop strip.
- [ ] Every stage meets the stage targets (grounded on pivot_y - 1, centred, heights rising, at most 150 px over the plot cell); four distinct stages per species; `grape_regrow` differs from stages 2 and 3; the trellis matches across stages 2, 3 and regrow (±1 px).
- [ ] Icons: inside the canvas with a clear 1 px margin, more than 24 (16x16) / 7 (10x10) opaque px, at least 2 colours, no two identical.
- [ ] The packets have exactly A015's packet box and paper, differ only by picture and band, and each differs from its produce icon at both sizes.
- [ ] At 1x, by day and in the night preview, every species and stage reads; grape bunches stay visible at night; the pumpkin does not look lit.

## Delivery

- Folder `implementation/backlog/deliveries/A017-autumn-crops/`, with the files of contract 9.1: `raw/` (+ `.prompt.txt`, `.call.json`), `native/<anim>/none/01..NN.png` (`native/grape/none/01..04.png`, `native/grape_regrow/none/01.png`, `native/icon_beet/none/01.png`, `native/hud_beet/none/01.png`), `preview/`, `rejected/`, `contract.json` (its `references` include A015's packet master with its sha256), `checks.json` (with `wet_cue_exposed`, `stages_rise`, `icon_bounds_ok`, `packets_same_box`), `build.py`, `index.html`, `review-log.txt`.
- `CLAUDE-A017-PROMPT.txt` maps each file, e.g. `native/grape/none/01..04.png -> sprites/crops/grape_0..3.png  16x32 pivot (8,30) draw 1.0 static (0.55, no loop)`, `native/grape_regrow/none/01.png -> sprites/crops/grape_regrow.png`, `native/icon_wheat_seed/none/01.png -> sprites/ui/icon_wheat_seed.png  16x16 pivot (8,8) static (1.0)`; and names the stand-ins replaced (0168, 0170, 0172).
- Last step, only after the owner approves in words recorded in `APPROVAL.json`: `python implementation/backlog/assets.py set A017 approved`.
