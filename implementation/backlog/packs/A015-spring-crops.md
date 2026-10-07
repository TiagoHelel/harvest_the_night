# A015 - Spring crops

- **Status:** todo
- **For game task:** 0198
- **Dressed by game tasks:** 0168
- **Spec after game task:** 0168
- **Family:** crops
- **Mode:** A - raw ImageGen sources, Claude reduces them to the 42-colour palette
- **Size of the job:** 13 crop frames in 3 strips; 7 icon sources cut to 14 icons (3 produce, 4 seed packets)

## What it is for

Spring (days 1-14) grows carrot, potato, garlic and strawberry. This pack draws
the three new ones through their four growth stages, the strawberry's regrowing
stage after picking (0172), their produce icons, and the seed packets the stall
sells for the four spring crops (0170). The player sees the crops on tilled
plots all spring day and under the night relight, at 1 art px = 4x4 screen px:
a ripe crop is at most 12 px (48 screen px) tall, a quarter of the 128 px
farmer, so each species and each stage must read by silhouette and colour at
1x, and ripe must look ready to pick. The packet drawn here is the model for
all twelve packets (A016 and A017 copy it). Until it arrives, 0168, 0170 and
0172 draw tinted stand-ins.

## Deliverables

The table is provisional: game task 0168 settles the final canvas/footprint/states and updates it; start only when `python implementation/backlog/assets.py next` offers this pack.

| Runtime name | Native canvas | Pivot | Frames / seconds / loop | Notes |
|---|---|---|---|---|
| `crops/potato_0..3` | 16x16 | (8,14) | 4 stages (planted, sprout, growing, ripe), static 0.55, no loop | One strip, one scale. |
| `crops/garlic_0..3` | 16x16 | (8,14) | 4 stages, static 0.55, no loop | One strip, one scale. |
| `crops/strawberry_0..3` | 16x16 | (8,14) | 4 stages, static 0.55, no loop | One 5-cell strip with the regrow stage, one scale. |
| `crops/strawberry_regrow` | 16x16 | (8,14) | 1, static 0.55, no loop | The plant after picking, waiting to fruit again (0172 draws `<crop>_regrow`). Cell 5 of the strawberry strip. |
| `ui/icon_potato` + `ui/hud_potato` | 16x16 / 10x10 | (8,8) / (5,5) | 1, static 1.0, no loop | One source: two brown potatoes. |
| `ui/icon_garlic` + `ui/hud_garlic` | 16x16 / 10x10 | (8,8) / (5,5) | 1, static | One source: a white garlic bulb with a short stalk. |
| `ui/icon_strawberry` + `ui/hud_strawberry` | 16x16 / 10x10 | (8,8) / (5,5) | 1, static | One source: one red strawberry with its green crown. |
| `ui/icon_carrot_seed` + `ui/hud_carrot_seed` | 16x16 / 10x10 | (8,8) / (5,5) | 1, static | One source. **Packet master** for all twelve packets. |
| `ui/icon_potato_seed` + `ui/hud_potato_seed`, `ui/icon_garlic_seed` + `ui/hud_garlic_seed`, `ui/icon_strawberry_seed` + `ui/hud_strawberry_seed` | 16x16 / 10x10 | (8,8) / (5,5) | 1 each, static | One source each, an edit of the master. |

Crop ids are 0168's plain names; packet ids are 0170's `<crop>_seed` resources.

**Stage targets** (visible height in px; heights rise strictly from stage 0 to
3; lowest opaque row 13; bounding box inside x 1-14 and y >= 1; centred on x=8
±1; at most 150 opaque px per frame, so at least 80 wet-soil px stay visible,
`check_crop_art.py`):

| Crop | 0 planted | 1 sprout | 2 growing | 3 ripe | regrow |
|---|---|---|---|---|---|
| potato | cut seed potato half in the soil, 2-3, at most 5 wide | 2-3 round leaves, 4-5 | bushy leafy plant, 7-8 | full bush with a few small white flowers, two brown tubers showing at the soil line, 10-12 | - |
| garlic | one pale clove, 2-3, at most 4 wide | 2-3 thin shoots, 4-6 | upright strap leaves, 7-9 | taller leaves with yellowing tips, white bulb shoulder at the soil line, 10-12 | - |
| strawberry | small rooted runner, 2-3 | three-lobed leaves, 4-5 | low leafy clump, 1-2 small white flowers, 6-7 | the clump with 3-4 red berries at its edges, 8-10 | the ripe clump's leaves with white flowers and 1-2 small green berries, no red; height from stage 2's to stage 3's, distinct from both |

**Recipe values (mode A).** Crops: no `palette_keys` (full palette, like
today's crops); one `content_scale` per strip, chosen so the ripe stage meets its
height; each stage's `crop_xywh` = its measured box in its cell, bottom on the
lowest opaque raw row, centred on the stem; default content anchor. Produce
icons: one crop per source and two `content_scale` values; visible at most 14
(inside x/y 1-14) and at most 8 (inside 1-8); `content_anchor_xy` = (w//2,
h//2) of each scaled size, as `icon_carrot` [6,7] / `hud_carrot` [3,4].
Packets: visible box exactly x 2-13, y 1-14 at 16x16 (12x14) and x 2-8, y 1-8
at 10x10 (7x8); crop aspect 12:14; anchors (6,7) and (3,4).

**Packet design** (shared by all twelve): an upright paper seed packet in cream
paper (`bone`, `bone_dark` shading, dark coloured outline), a folded top band in
the season colour (spring `grass_light`/`grass`, summer `gold_light`/`gold`,
autumn `roof_light`/`roof`), and on its front a clear picture of the crop's
produce filling about half the packet. No text, numbers, logo or shadow.

## Match these

- `sprites/crops/carrot_0..3.png` (heights 2/4/6/9), `wheat_0..3.png` (2/4/8/12), `corn_0..3.png` (16x24) and raws `assets/art_source/crops/carrot.png` (2172x724, one 4-stage strip), `wheat.png`, `corn.png`: stage sizes, `night`/`ink` outline, light from the upper left, strip layout.
- `sprites/crops/tilled.png`, `tilled_wet.png`: the plots they grow on.
- `sprites/ui/icon_carrot.png` (visible 13x14), `hud_carrot.png` (7x8), `icon_wheat.png`, `icon_corn.png` and raw `assets/art_source/ui/carrot.png` (1254x1254): icon size, padding, outline.
- `docs/reference-sheet.png`: the crop field and the icon row.
- The farmer `implementation/fhd-player/pilots/2026-10-06/walk-final-mirrored/native-40/walk/down/01.png`: scale.

## How to make it

1. Safety first (CODEX-RUNNER step 1): `python tools/task.py list done` must
   list 0168. Re-read this table: 0168 may have changed it.
2. Crops: PROMPTS.md BASE + CROP + STRIP + CORRECTION for revisions, braces
   filled with 16x16, pivot (8,14) and the stage list of the table (CROP's
   `{wheat/corn/carrot}` line replaced by the species line).
   `transparent_background=true`. One species per call: potato and garlic are
   4-cell strips, strawberry a 5-cell strip ordered planted, sprout, growing,
   ripe, regrow. Attach `assets/art_source/crops/carrot.png` as "approved crop
   strip: layout, scale and style reference" and `docs/reference-sheet.png` as
   style.
3. Produce icons: BASE + ICON, one item per call, `transparent_background=true`,
   `assets/art_source/ui/carrot.png` attached as "approved icon: style and size
   reference".
4. Packets: `carrot_seed` first, alone, from BASE + ICON with the packet design
   above (a carrot on the front, spring band). Check it at 16x16 and 10x10
   before the others. Then each other packet as an edit of the accepted master
   raw: "change only the picture on the front to {produce}; keep the paper,
   band, outline, size and position". All four then share one crop size and the
   same two scales.
5. One candidate per call; at most 3 targeted revisions per asset.

## Review with the owner

`index.html` shows, at 1x and 4x (nearest): each species' stages in a row on
`tilled.png` and on `tilled_wet.png` plots; a 4x3 field of each ripe crop; the
ripe crops beside today's `carrot_3`, `wheat_3` and `corn_3` and the farmer,
feet on the same ground line; `strawberry_regrow` between `strawberry_2` and
`strawberry_3`; the icons on light and dark backgrounds beside `icon_carrot` /
`hud_carrot`; all packets in a row (with any from A016/A017 already
delivered). Day and night preview (contract 9.5), a 16px grid toggle. Static
art, nothing plays.

Ask the owner (pt-BR):

1. "Batata, alho e morango se distinguem entre si e da cenoura em todos os estágios, a 1x? O estágio maduro parece pronto para colher?"
2. "O pacote de sementes (papel creme, faixa verde da primavera, a cultura desenhada na frente) pode ser o modelo dos 12 pacotes?"
3. "O morango rebrotando (só flores e frutinhas verdes) se distingue bem do maduro?"

## Acceptance

- [ ] 27 files: 12 stage frames + 1 regrow at 16x16 / (8,14); 7 icons at 16x16 / (8,8) and 7 at 10x10 / (5,5); 1 static frame each.
- [ ] Binary alpha, true transparent background; no baked soil, shadow, glow, night version or text.
- [ ] Mode A: `render_source` with each recorded recipe reproduces `native/`; one `content_scale` per crop strip.
- [ ] Every stage meets the stage targets (grounded on row 13, centred, heights rising, at most 150 px); four distinct stages per species; the regrow differs from stages 2 and 3.
- [ ] Icons: inside the canvas with a clear 1 px margin, more than 24 (16x16) / 7 (10x10) opaque px, at least 2 colours, no two identical.
- [ ] All packets have exactly the visible box above and differ only by their picture; each packet differs from its produce icon at both sizes.
- [ ] At 1x, by day and in the night preview, every species and stage reads; ripe crops do not look lit.

## Delivery

- Folder `implementation/backlog/deliveries/A015-spring-crops/`, with the files of contract 9.1: `raw/` (+ `.prompt.txt`, `.call.json`), `native/<anim>/none/01..NN.png` (`native/potato/none/01..04.png`, `native/strawberry_regrow/none/01.png`, `native/icon_potato/none/01.png`, `native/hud_potato/none/01.png`), `preview/`, `rejected/`, `contract.json`, `checks.json` (with `wet_cue_exposed`, `stages_rise`, `icon_bounds_ok`, `packets_same_box`), `build.py`, `index.html`, `review-log.txt`.
- `CLAUDE-A015-PROMPT.txt` maps each file, e.g. `native/potato/none/01..04.png -> sprites/crops/potato_0..3.png  16x16 pivot (8,14) draw 1.0 static (0.55, no loop)`, `native/strawberry_regrow/none/01.png -> sprites/crops/strawberry_regrow.png`, `native/icon_potato/none/01.png -> sprites/ui/icon_potato.png  16x16 pivot (8,8) static (1.0)`, `native/hud_carrot_seed/none/01.png -> sprites/ui/hud_carrot_seed.png  10x10 pivot (5,5)`; and names the stand-ins replaced (0168, 0170, 0172).
- Last step, only after the owner approves in words recorded in `APPROVAL.json`: `python implementation/backlog/assets.py set A015 approved`.
