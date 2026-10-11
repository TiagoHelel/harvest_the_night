# A014 - Trampled crops and tilled ground

- **Status:** integrated
- **For game task:** 0197
- **Dressed by game tasks:** 0155, 0167
- **Spec after game task:** 0167
- **Family:** crops
- **Mode:** A - raw ImageGen sources, Claude reduces them to the 42-colour palette
- **Size of the job:** 4 sprites: 2 crop states, 2 tilled-edge pieces (provisional, 0167 may change the edge set); no animation

## What it is for

Three pieces of farm ground the 1.0 rules add. When a night is lost, the horde
tramples every crop on its routes (game task 0155): the plot stays tilled and
shows a flattened, broken plant until something is planted there. On the first
morning of a season, crops of the old season wither (0170) and stay as dead
plants until harvested or hoed. And any grass can now be tilled (0167), so a
tilled patch in open grass needs a turf border where it meets untilled grass.
The player sees these in the morning light right after a loss or a season
change, and at night on the field, at 1 art px = 4x4 screen px beside the 128
px farmer: trampled must read as damage, withered as dead, and the border as
the edge of a hoed patch, all quieter than a growing crop.

## Deliverables

The table is provisional: game task 0167 settles the final canvas/footprint/states and updates it; start only when `python implementation/backlog/assets.py next` offers this pack.

| Runtime name | Native canvas | Pivot | Frames / seconds / loop | Notes |
|---|---|---|---|---|
| `crops/trampled` | 16x16 | (8,14) | 1, static (0.55, no loop) | Generic for every crop, drawn over the tilled plot (dry or wet). Flattened, broken green-and-brown stalks and torn leaves pressed into the soil, with one clear zombie footprint. 2-5 rows tall, 8-12 wide, at most 50 opaque px, at most 2 pieces. |
| `crops/withered` | 16x16 | (8,14) | 1, static | Generic dead crop. A dry, drooping brown-and-straw plant still standing. 6-9 rows tall, at most 12 wide, at most 60 opaque px, one 8-connected piece. |
| `crops/tilled_edge_n` | 16x16 | (8,16) | 1, static | Overlay drawn on a tilled-grass plot whose north neighbour is untilled grass: torn turf curling over the plot's edge, with a thin `soil_dark` cut line under it. Row 0 full width; tufts reach row 2 at most; columns 0 and 15 identical; one 4-connected piece containing (0,0). |
| `crops/tilled_edge_corner_nw` | 16x16 | (8,16) | 1, static | Corner cap for an exposed diagonal: at most 3x3 from (0,0); its column 0 and its row 0 both equal `tilled_edge_n`'s column 0. |

**Default edge scheme** (until 0167 rewrites it): like the terrain edges. The
plot's mask counts its untilled-grass neighbours, N=1, E=2, S=4, W=8. Claude
derives `tilled_edge_e/s/w` (clockwise quarter-turns 1/2/3 of the north piece,
the importer's `rotate`) and `tilled_edge_corner_ne/se/sw` at integration;
composites lay the sides in N, E, S, W order as `tools/gen_sprites.py`
`edge_row()` does, and corner caps go where `world_view._corner_mask` would put
them. They are not delivered.

**Recipe values (mode A).** `trampled`, `withered`: no `palette_keys` (full
palette, like today's crops), crop = the measured box, default anchor (bottom
centre), so the lowest opaque row is 13 and the piece is centred on x=8 ±1.
Edge pieces: `palette_keys` `["grass_dark","grass","grass_light","soil_dark"]`,
`crop_xywh` the whole square return `[0,0,W,W]` (or a measured square for the
corner), `content_scale` 16/W, `content_anchor_xy` (8,16). Grass-ramp turf only
lets 0159's season remap recolour it with the grass, and one set serves dry and
wet plots.

## Match these

- `sprites/crops/carrot_0..3.png`, `wheat_0..3.png`, `corn_0..3.png` and raws `assets/art_source/crops/{carrot,wheat,corn}.png`: crop scale, `night`/`ink` outline, light from the upper left. What trampled and withered replace.
- `sprites/crops/tilled.png`, `tilled_wet.png`: the ground they sit on (furrow ridges on rows 0-1, 4-5, 8-9, 12-13).
- `sprites/terrain/edge_n.png`, `edge_corner_nw.png` and raw `assets/art_source/terrain/edge-n.png`: today's grass-encroaching edge, the model for the turf border.
- `sprites/terrain/grass.png`: the grass around a tilled patch.
- `sprites/enemies/walker_walk_0.png` (64x48): whose foot made the print.
- `docs/reference-sheet.png`; the farmer `implementation/fhd-player/pilots/2026-10-06/walk-final-mirrored/native-40/walk/down/01.png`.

## How to make it

1. Safety first (CODEX-RUNNER step 1): `python tools/task.py list done` must
   list 0167. Re-read this table: 0167 may have changed it.
2. `trampled`, `withered`: PROMPTS.md BASE + CROP + CORRECTION for revisions,
   braces filled with 16x16 and pivot (8,14); one subject per call,
   `transparent_background=true`. Replace CROP's growth-strip lines with:
   trampled "one crop plant crushed flat into the soil by a zombie's foot,
   broken stalks and torn leaves lying flat, one footprint, no soil patch"; or
   withered "one crop plant dead from frost, dry straw and brown leaves drooping,
   still standing, no soil patch". Attach `assets/art_source/crops/carrot.png`
   as "approved crop strip: scale and style reference". Choose each
   `content_scale` for the target size in the table.
3. Edge pieces: BASE + TERRAIN + CORRECTION, `transparent_background=true`,
   edit target `assets/art_source/terrain/edge-n.png` ("same footprint and
   width; torn turf lip over hoed soil instead of grass over path").
   `tilled_edge_corner_nw` after the side is accepted, with it attached as
   "style reference".
4. One candidate per call; at most 3 targeted revisions per sprite.

## Review with the owner

`index.html` shows each sprite at 1x and 4x (nearest), then a test patch: a
6x4 block of tilled grass cut into tiled `sprites/terrain/grass.png`, with
`tilled` and `tilled_wet` plots, edges composited for every mask and corner,
some plots carrying today's crops at each stage, some `trampled`, some
`withered`; `sprites/enemies/walker_walk_0.png` and the farmer standing beside
it, feet on the same line. Day and night preview (contract 9.5), a 16px grid
toggle. Static art, nothing plays.

Ask the owner (pt-BR):

1. "A planta pisoteada parece estrago feito pela horda (com a pegada) e não uma planta nova?"
2. "A planta murcha de fim de estação se distingue bem da pisoteada, de dia e à noite?"
3. "A borda de grama em volta do canteiro arado na grama ficou natural, sem emendas?"

## Acceptance

- [ ] 4 files with the canvases and pivots of the table (or of 0167's final table); 1 static frame each.
- [ ] Binary alpha, true transparent background; no baked soil patch, shadow, glow, night version or text.
- [ ] Mode A: `render_source` with each recorded recipe reproduces `native/`; the edge pieces only use their 4 keys.
- [ ] `trampled` and `withered`: bounding box inside x 1-14 and y >= 1, lowest opaque row 13, centred on x=8 ±1, sizes and pixel counts as the table; over `tilled_wet.png` at least 80 wet-soil px stay visible (`check_crop_art.py`'s rule); their silhouettes differ from each other and from every crop stage.
- [ ] Edge pieces pass the geometry in the table (the same rules `tools/check_terrain_art.py` applies to `edge_n` and its corner).
- [ ] In the test patch all 16 masks and the corners join without gaps or doubled turf, by day and in the night preview.

## Delivery

- Folder `implementation/backlog/deliveries/A014-crop-ground/`, with the files of contract 9.1: `raw/` (+ `.prompt.txt`, `.call.json`), `native/<name>/none/01.png` (e.g. `native/tilled_edge_n/none/01.png`), `preview/`, `rejected/`, `contract.json`, `checks.json` (with `edge_geometry` and `wet_cue_exposed`), `build.py`, `index.html`, `review-log.txt`.
- `CLAUDE-A014-PROMPT.txt` maps each file, e.g. `native/trampled/none/01.png -> sprites/crops/trampled.png  16x16 pivot (8,14) draw 1.0 static` and `native/tilled_edge_n/none/01.png -> sprites/crops/tilled_edge_n.png  16x16 pivot (8,16)`; lists the rotations Claude derives; and names the stand-ins it replaces (0155's trampled plot, 0170's withered crop, 0167's tilled-grass border).
- Last step, only after the owner approves in words recorded in `APPROVAL.json`: `python implementation/backlog/assets.py set A014 approved`.
