# A018 - Sprinklers

- **Status:** integrated
- **For game task:** 0201
- **Dressed by game tasks:** 0178
- **Spec after game task:** 0178
- **Family:** props
- **Mode:** A - raw ImageGen sources, Claude reduces them to the 42-colour palette
- **Size of the job:** 3 sprinklers x (1 idle + 4 spray frames) = 15 world frames, 3 icons (6 cuts); 3 masters + 3 five-cell sheets

## What it is for

Copper, iron and gold sprinklers water the plots around them every morning
(game task 0178). The player builds them by day on a single cell among the
tilled plots, and sees them all day; at dawn they pop up and spin while the game
draws the water spray as code particles. At 1080p each is a small metal head
on a base plate, clearly lower and quieter than the crops and the 32px farmer,
and the three tiers must differ by **construction** (not just colour), because
the night relight flattens copper and gold into the same dull ramp. Enemies walk
over them at night, so they stay low and never read as a wall.

## Deliverables

Final geometry settled by game task 0178. There are three ids, one per tier (`copper_sprinkler`, `iron_sprinkler`, `gold_sprinkler`), not one id with levels, so the rows below keep their names. Each body is one cell: 16x16 at pivot (8,14), draw scale 1.0. It is idle all day and runs its four-frame spray loop through the first hour of the morning (06:00-07:00), while the game throws the water from `spray_xy` out over the cells it waters: the four beside it for copper, the 3x3 for iron and the 5x5 for gold. Zombies walk over all three at night. Start only when `python implementation/backlog/assets.py next` offers this pack.

| Runtime name | Native canvas | Pivot | Frames / seconds / loop | Notes |
|---|---|---|---|---|
| `copper_sprinkler` | 16x16 | (8,14) | 1 / 0.55 / static | Idle, head lowered onto its riser. Visible at most 8 wide x 8 tall. Single round nozzle cap on a short riser on a small square base plate. |
| `copper_sprinkler_spray_0..3` | 16x16 | (8,14) | 4 / 0.1 / loop | Head raised 2 px above idle; the nozzle points `west`, `south`, `east`, `north` in that frame order (north = nozzle hidden behind the cap), so frame 3 leads back to frame 0. Visible at most 8 x 10. `spray_xy` on all 4 frames. |
| `iron_sprinkler` | 16x16 | (8,14) | 1 / 0.55 / static | Idle. Visible at most 10 x 9. Squat iron head with four short nozzle stubs on a cross-shaped footed base. |
| `iron_sprinkler_spray_0..3` | 16x16 | (8,14) | 4 / 0.1 / loop | As copper: raised 2 px, nozzle stubs turned through the same 4 steps. Visible at most 10 x 11. `spray_xy`. |
| `gold_sprinkler` | 16x16 | (8,14) | 1 / 0.55 / static | Idle. Visible at most 12 x 10. Domed gold head with a ring of nozzle holes and a collar, on a round stepped base. |
| `gold_sprinkler_spray_0..3` | 16x16 | (8,14) | 4 / 0.1 / loop | As copper: raised 2 px, the ring turned through 4 steps (a highlight cluster moves round the dome). Visible at most 12 x 12. `spray_xy`. |
| `icon_copper_sprinkler`, `hud_copper_sprinkler` | 16x16 / 10x10 | (8,8) / (5,5) | 1 / 1.0 / static | Cut from the copper master raw (one source, two `content_scale` values). Visible at most 14 / 8, centred, clear padding. |
| `icon_iron_sprinkler`, `hud_iron_sprinkler` | 16x16 / 10x10 | (8,8) / (5,5) | 1 / 1.0 / static | Cut from the iron master raw. |
| `icon_gold_sprinkler`, `hud_gold_sprinkler` | 16x16 / 10x10 | (8,8) / (5,5) | 1 / 1.0 / static | Cut from the gold master raw. |

- Directions: `none` for every row. No mirrors (the spin covers both sides).
- Every world frame: lowest opaque row 13 (`pivot_y - 1`); the base plate is
  centred on x 8 and sits on the **same pixels** in the idle frame and all four
  spray frames of a tier (only the head moves).
- `spray_xy` (new metadata key, contract section 5): one point per tier, the
  top-centre opaque pixel of the raised head, the same coordinate in all four
  spray frames and opaque in each. Code emits the water particles from it.
  Idle frames have no points.
- `palette_keys` per tier (record the list used in contract.json; change it only
  with a line in review-log.txt): copper `ink, ink_soft, stone_dark, stone,
  roof_dark, skin_dark, roof_light, skin, gold_dark, leaf_light` (leaf_light is
  the verdigris); iron `ink, ink_soft, stone_dark, stone, stone_light,
  bone_dark, water_dark`; gold `ink, ink_soft, stone_dark, gold_dark, gold,
  gold_light, flame_hot, bone`. Icons use the same keys as their tier.
- Never baked: water, droplets, mist, a puddle, wet soil, a grass tuft or a soil
  disc under the base. If 0178 makes the tiers one id with levels, it renames
  the rows `sprinkler`, `sprinkler_2`, `sprinkler_3` (+ `_spray_<i>`, icons)
  before this pack starts.

## Match these

- `implementation/fhd-player/pilots/2026-10-06/walk-final-mirrored/native-40/walk/down/01.png`
  (40x40, pivot (20,36), body 16x32): scale. A copper sprinkler is about a
  quarter of the farmer's height.
- `sprites/props/ore.png` (16x16, pivot (8,14), visible 14x11): the small-node
  canvas, how the object stands on row 13, outline weight.
- `sprites/buildings/mine.png` (16x16, visible 12x8): the nearest existing small
  metal device on one cell - low, readable at 1x, metal ramp.
- `sprites/crops/tilled_wet.png`, `sprites/crops/carrot_3.png`,
  `sprites/crops/wheat_3.png`, `sprites/crops/corn_3.png` (16x24): the plots it
  sits among. The sprinkler stays below the ripe crops in height and contrast.
- `sprites/ui/icon_iron.png` (visible 14x11), `sprites/ui/hud_iron.png` (8x7)
  and raw `assets/art_source/ui/iron.png`: icon density, padding and outline.
- `docs/reference-sheet.png`: look and materials (contract section 6).

## How to make it

1. Prompt = `implementation/sprites/generation/PROMPTS.md` BASE (braces: canvas
   16x16, pivot 8,14) + these lines in place of a family section, + STRIP for
   the sheets, + CORRECTION for revisions:
   `Primary request: {copper|iron|gold}_sprinkler, a small garden irrigation
   head on a base plate set flush into farm ground, three-quarter top-down.
   Construction: {the tier's construction from the table}. Final visible size
   about {W}x{H} native px of a 16x16 cell; chunky readable metal planes with a
   coloured outline. No water spray, droplets, puddle, wet soil, grass or soil
   base: the game draws the spray.`
2. Masters, `transparent_background=true`, one subject per call: copper first
   (2 candidates; keep the one whose 16x16 reduction still shows riser, cap and
   plate). Then iron and gold, each with the accepted copper raw attached as
   "family style and camera reference" (not an edit target), so all three share
   camera, plate height and outline.
3. Per tier, one STRIP call of exactly 5 cells, ordered
   `idle (head down), spray west, spray south, spray east, spray north`, with the
   tier master attached as "identity master". Gutters at least a quarter of a
   cell. Same plate size and position in every cell.
4. Export with the mode A recipe (`render_source` from `tools/import_art.py`,
   imported read-only). One `content_scale` for the whole 5-cell sheet of a
   tier; measured `sheet_cell_xywh` and crops; `content_anchor_xy` = the base
   plate's bottom-centre in the scaled crop (not the bbox centre, which the
   nozzle shifts), so the plate lands on the same pixels in all five frames.
5. Icons: from the tier master raw, one crop, two `content_scale` values so the
   visible size is at most 14 (16x16, pivot (8,8)) and at most 8 (10x10, pivot
   (5,5)), content centred.

## Review with the owner

`index.html` shows, per tier: idle and the spray loop at 1x and 4x nearest,
playing at 0.1 s and as a still strip, by day and in the night preview; beside
the farmer frame and `sprites/buildings/mine.png`, feet on one ground line; in
the centre of a 3x3 block of `sprites/crops/tilled_wet.png` with `carrot_3` on
the eight neighbours; over `sprites/terrain/grass.png` tiles; with `spray_xy`
on an overlay. The six icons at 1x and 4x beside `icon_iron` / `hud_iron`.

Ask the owner:
- "Os três aspersores se distinguem pelo formato, e não só pela cor, também na prévia noturna?"
- "O tamanho está bom no meio dos canteiros e ao lado do fazendeiro, sem esconder as plantas vizinhas?"
- "A cabeça subindo e girando (4 quadros a 0,1 s) parece um aspersor ligado? As gotas o jogo desenha por cima."

## Acceptance

- [ ] 15 world frames and 6 icon cuts exist with the canvas, pivot, frame count and timing above.
- [ ] Lowest opaque row 13 on every world frame; plate centred on x 8 (±1); plate bbox identical across the 5 frames of a tier.
- [ ] Visible bounds within the per-row limits; copper < iron < gold in size.
- [ ] The tiers differ in silhouette at 1x and in the night preview, not only in hue.
- [ ] `spray_xy` sits on an opaque pixel, at the same coordinate, in all 4 spray frames of its tier.
- [ ] Binary alpha, true transparency; no water, ground, shadow, glow or text.
- [ ] Mode A: only the 42 colours, within the recorded `palette_keys`; `native/` reproduced by `render_source` (`importer_recipe_matches`).
- [ ] One `content_scale` per tier sheet (`one_scale_per_animation`); `icon_bounds_ok` (at most 14 / 8).
- [ ] `build.py` twice is byte-identical and `--check` passes; checks.json all `true`.

## Delivery

Folder `implementation/backlog/deliveries/A018-sprinklers/` with `raw/`,
`native/<anim>/none/01..NN.png` (e.g. `native/iron_sprinkler_spray/none/01..04.png`,
`native/icon_iron_sprinkler/none/01.png`), `preview/`, `rejected/`,
`contract.json`, `checks.json`, `build.py`, `index.html`, `review-log.txt`
(contract 9.1-9.6). No `runtime/` folder.

`CLAUDE-A018-PROMPT.txt` maps, for each tier `<t>`:
`native/<t>_sprinkler/none/01.png -> sprites/props/<t>_sprinkler.png 16x16 pivot (8,14) draw 1.0 static`;
`native/<t>_sprinkler_spray/none/01..04.png -> sprites/props/<t>_sprinkler_spray_0..3.png 16x16 pivot (8,14) draw 1.0 0.1 s loop, spray_xy (x,y)`;
`native/icon_<t>_sprinkler/none/01.png -> sprites/ui/icon_<t>_sprinkler.png 16x16 (8,8)` and the `hud_` cut at 10x10 (5,5).
They replace 0178's stand-ins in game task 0201.

Last step, only after the owner approves in words recorded verbatim in
`APPROVAL.json`: `python implementation/backlog/assets.py set A018 approved`.
