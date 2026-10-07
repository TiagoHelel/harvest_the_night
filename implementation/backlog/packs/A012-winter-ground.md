# A012 - Winter ground

- **Status:** todo
- **For game task:** 0163
- **Dressed by game tasks:** 0159
- **Family:** terrain
- **Mode:** A - raw ImageGen sources, Claude reduces them to the 42-colour palette
- **Size of the job:** 11 tiles (8 opaque ground tiles, 3 transparent edge/shore overlays), no animation

## What it is for

Winter (days 43-56) puts the farm under snow. Game task 0159 fakes it with a
palette remap; this pack replaces that stand-in with real winter ground: the
four grasses, the path, the bed soil and the tilled plots under snow, plus the
snow fringe that today's grass edges and pond banks draw. The player walks on it
all winter day and watches it all winter night under the relight, beneath every
actor, so it must stay the quietest thing on screen: a calm snow field the blue
32px farmer, the zombies and the towers read clearly against at 1080p (1 art px
= 4x4 screen px). Paths and beds must still read as paths and beds through the
snow. Water does not freeze (winter fishing goes on); `rock`, `floor` and the
three water tiles keep today's art and are not in this pack.

## Deliverables

| Runtime name | Native canvas | Pivot | Frames / seconds / loop | Notes |
|---|---|---|---|---|
| `terrain/grass_winter` | 16x16 | (8,16) | 1, static (0.55, no loop) | Master snow tile, drawn on 56% of grass cells. Fully opaque, seamless. |
| `terrain/grass_b_winter` | 16x16 | (8,16) | 1, static | 22% of cells. Same borders, `content_scale` and `palette_keys` as the master; one different soft drift cluster. |
| `terrain/grass_c_winter` | 16x16 | (8,16) | 1, static | 19% of cells. As b, plus one small dark grass tuft poking through (at most 10 px). |
| `terrain/grass_d_winter` | 16x16 | (8,16) | 1, static | 3% of cells (the rare one). As b, plus a few dry stalks (at most 10 px). |
| `terrain/path_winter` | 16x16 | (8,16) | 1, static | Trodden, packed snow (base `bone_dark`) with a few slushy dirt clusters. Seamless. |
| `terrain/soil_winter` | 16x16 | (8,16) | 1, static | The bed soil (base `soil`) under a light dusting: snow clusters on at most 40 px. Seamless. |
| `crops/tilled_winter` | 16x16 | (8,16) | 1, static | Opaque plot. Keeps `tilled.png`'s furrows: ridges on rows 0-1, 4-5, 8-9, 12-13 hold snow; grooves on rows 2-3, 6-7, 10-11, 14-15 stay dark soil. |
| `crops/tilled_wet_winter` | 16x16 | (8,16) | 1, static | Same furrows, watered: wetter grooves, less snow. Mean brightness at least 20 below `tilled_winter`. |
| `terrain/edge_n_winter` | 16x16 | (8,16) | 1, static | Overlay: snow creeping into a path/soil/floor/rock cell from its north. Row 0 full width; soft scallops down to row 2 at most; columns 0 and 15 opaque on row 0 only (like today's `edge_n`). |
| `terrain/shore_n_winter` | 16x16 | (8,16) | 1, static | Overlay on the water cell: a snowy bank lip. Row 0 snow, row 1 the bank's earth edge with snow clumps, at most one `water_dark` contact cluster on row 2; 3 rows deep at most. |
| `terrain/shore_corner_nw_winter` | 16x16 | (8,16) | 1, static | Overlay: inner-corner cap of the bank, at most 3x3 from (0,0). |

**Recipe values (mode A).** Opaque tiles and overlays: `crop_xywh` = the whole
square return `[0,0,W,W]`, `content_scale` = 16/W, `content_anchor_xy` (8,16),
`alpha_threshold` 128 (today's grass: W=1254, scale 0.012759170653907496). The
corner may use a measured square crop, as today's `shore_corner_nw` does
(`[14,14,720,720]`). `palette_keys`, shared within each group:

- `grass_winter`, `grass_b..d_winter`: `["bone","moon","bone_dark","grass_dark","grass"]`
- `path_winter`: `["bone","bone_dark","soil_light","soil","stone_light"]`
- `soil_winter`: `["soil_dark","soil","soil_light","bone","bone_dark"]`
- `tilled_winter`, `tilled_wet_winter`: `["soil_dark","soil","soil_light","ink_soft","ink","bone","bone_dark"]`
- `edge_n_winter`: `["bone","moon","bone_dark"]`
- `shore_n_winter`, `shore_corner_nw_winter`: `["bone","moon","bone_dark","wood_light","wood","soil_light","water_dark"]`

Snow body is `bone`, cool variation `moon`, shadow clusters `bone_dark`. The 42
colours have no pure white; do not ask for a new one.

**Overlay geometry** (the rules `tools/check_terrain_art.py` applies to today's
pieces): a side piece's bounding box starts at (0,0), spans the full width and
ends by row 3; row 0 is fully opaque; column 0 equals column 15 pixel for pixel;
row 15 is empty; all pixels form one 4-connected piece containing (0,0). The
corner's column 0 and its row 0 both equal `shore_n_winter`'s column 0, read
top to bottom.

**Derived by Claude at integration, not delivered:** `edge_e/s/w_winter` and
`shore_e/s/w_winter` (clockwise quarter-turns 1/2/3 of the north piece, the
importer's `rotate`), `edge_corner_nw_winter` (`slice_canvas` (0,0,1,1) of
`edge_n_winter`, as today), and the ne/se/sw corners (rotations of the nw cap).

## Match these

- `sprites/terrain/grass.png`, `grass_b.png`, `grass_c.png`, `grass_d.png`, `path.png`, `soil.png` and their raws `assets/art_source/terrain/{grass,grass_b,grass_c,grass_d,path,soil}.png` (1254x1254): how quiet ground is here (grass is 240 of 256 px one colour, path 254) and the edit targets.
- `sprites/crops/tilled.png`, `tilled_wet.png` and raws `assets/art_source/crops/tilled.png`, `tilled_wet.png`: the furrow rows to keep.
- `sprites/terrain/edge_n.png`, `shore_n.png`, `shore_corner_nw.png` and raws `assets/art_source/terrain/edge-n.png`, `shore-n.png`, `shore-corner-nw.png`: the footprint of each overlay (today: a 1-row grass fringe with a 2 px dip; a 2-row bank).
- `sprites/terrain/atlas.png` (256x80): how the 16 edge and shore masks composite.
- `docs/reference-sheet.png`, `assets/art_source/masters/style-day.png`, `style-night.png`: look, day and night.
- The farmer `implementation/fhd-player/pilots/2026-10-06/walk-final-mirrored/native-40/walk/down/01.png` (40x40, visible 16x32, pivot (20,36)): scale on the ground.

## How to make it

1. Prompt: `implementation/sprites/generation/PROMPTS.md` BASE + TERRAIN (the
   shore pieces use WATER's bank lines) + CORRECTION for revisions, braces
   filled with 16x16 and pivot (8,16). Add: "Winter version of the attached
   tile: {subject}. Keep the attached tile's texture density, cluster size and
   seamless borders. Snow is soft warm white with a few cool pale-blue shadow
   clusters; no glare, no sparkle pixels, no footprints, no ice, no
   centrepiece, no objects."
2. One tile per call. `transparent_background=false` for the 8 opaque tiles,
   `true` for the 3 overlays. Edit target: today's raw of the same tile (role
   "edit target: the same tile, now in winter"); style reference
   `docs/reference-sheet.png`.
3. Order: `grass_winter` first; check it at native size in a 6x4 repeat before
   anything else. Then `grass_b..d_winter` as edits of the accepted
   `grass_winter` raw ("change only the interior cluster, keep every border"),
   so all four share its resolution and scale. Then `path_winter`,
   `soil_winter`, `tilled_winter`, then `tilled_wet_winter` as an edit of the
   accepted `tilled_winter` raw ("same furrows, wetter and darker, less snow").
   Then `edge_n_winter`, `shore_n_winter`, `shore_corner_nw_winter`.
4. One candidate per call; at most 3 targeted revisions per tile. Reject a
   return that is not square, or a b-d variant whose resolution differs from
   the master. If a native border pair differs or a lone speckle appears,
   revise the source; never fix pixels in code.

## Review with the owner

`index.html` shows every tile at 1x and 4x (nearest), each opaque tile repeated
6x4, and a winter test field of about 24x14 cells that `build.py` composes from
the delivered tiles: grass cells pick their variant with the game's own rule
(`h = (x*73856093) ^ (y*19349663)`, `abs(h) % 32`: 31 -> d, 25-30 -> c, 18-24
-> b, else the master), a path crossing it, a soil bed with `tilled_winter` and
`tilled_wet_winter` plots, a rock patch and a floor strip with snow edges, and a
pond of today's `water.png` with winter shores. Edges are composited exactly as
`tools/gen_sprites.py` `edge_row()` does (side pieces by mask N=1, E=2, S=4,
W=8, laid in that order) plus corner caps where `world_view._corner_mask` puts
them. The farmer stands on it, feet on a cell, at 1x and 4x. The same field in
today's spring tiles sits beside it. Day and night preview (contract 9.5), and a
16px grid toggle. Static art, nothing plays.

Ask the owner (pt-BR):

1. "A neve está creme quente com sombras levemente azuladas. Está bom, ou prefere uma neve mais fria e azulada?" (If cooler: drop `bone` from the snow `palette_keys` so the body reduces to `moon`, rebuild; no new generation.)
2. "O caminho e os canteiros continuam fáceis de ler no meio da neve, de dia e na prévia noturna?"
3. "As bordas (neve invadindo o caminho e a terra) e a margem do lago com neve ficaram naturais, sem emendas aparentes?"

## Acceptance

- [ ] 11 files, all 16x16 with pivot (8,16), 1 static frame each; names and paths as the table.
- [ ] Binary alpha. The 8 tiles are fully opaque; the 3 overlays are transparent outside their band.
- [ ] Mode A: `render_source` with each recorded recipe reproduces `native/` pixel for pixel; only the listed `palette_keys` occur.
- [ ] Seamless: in each opaque tile row 0 equals row 15 and column 0 equals column 15; `grass_b..d_winter` have exactly `grass_winter`'s four borders; the 8 opaque tiles are pairwise distinct.
- [ ] Quiet: each grass tile has its base colour on at least 232 of 256 px, `path_winter` on at least 220, `soil_winter` on at least 200; non-base pixels sit in clusters of 2 px or more.
- [ ] Readable: mean brightness (mean of (r+g+b)/3) of `grass_winter` is at least 25 above `path_winter` and above `soil_winter`; `tilled_winter` is at least 20 above `tilled_wet_winter` (the `check_crop_art.py` formula).
- [ ] `tilled_winter` and `tilled_wet_winter` keep `tilled.png`'s groove rows (2-3, 6-7, 10-11, 14-15, each ±1).
- [ ] Overlays pass the geometry rules above; `edge_n_winter`'s columns 0 and 15 are opaque on row 0 only.
- [ ] In the test field no seam, edge or shore breaks the snow, by day and in the night preview; the farmer reads clearly on it.
- [ ] No baked shadow, footprints, objects, glow, night version or text.

## Delivery

- Folder `implementation/backlog/deliveries/A012-winter-ground/`, with the files of contract 9.1: `raw/` (+ `.prompt.txt`, `.call.json`), `native/<name>/none/01.png` (e.g. `native/grass_b_winter/none/01.png`), `preview/`, `rejected/`, `contract.json`, `checks.json` (`opaque_and_seamless`, plus `overlay_geometry` and `wet_darker_by_20`), `build.py`, `index.html`, `review-log.txt`.
- `CLAUDE-A012-PROMPT.txt` maps each file, e.g. `native/grass_winter/none/01.png -> sprites/terrain/grass_winter.png  16x16 pivot (8,16) draw 1.0 static` and `native/tilled_winter/none/01.png -> sprites/crops/tilled_winter.png`; lists the derived pieces of the Deliverables note for Claude to make with manifest `rotate`/`slice_canvas` entries; recommends a second atlas `sprites/terrain/atlas_winter.png` in `atlas.png`'s exact 256x80 layout (row 0 with `soil_winter`/`path_winter` and today's water, rock and floor; the winter grasses in row 2; winter edges and shores in rows 3-4 and the corner slots) for 0159's hook to swap in; and says it replaces 0159's winter remap for the ground.
- Last step, only after the owner approves in words recorded in `APPROVAL.json`: `python implementation/backlog/assets.py set A012 approved`.
