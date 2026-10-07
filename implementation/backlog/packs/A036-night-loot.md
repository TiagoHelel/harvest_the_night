# A036 - Bones, moon stones and essence

- **Status:** todo
- **For game task:** 0235
- **Dressed by game tasks:** 0219, 0221, 0222
- **Spec after game task:** 0222
- **Family:** props
- **Mode:** A - raw ImageGen sources, Claude reduces them to the 42-colour palette
- **Size of the job:** 13 PNGs from 9 raw sources: 2 ground pickups (one with a 2-frame shimmer), 2 soil tiles, 4 icons (each cut at 16x16 and 10x10)

## What it is for

The night now leaves something for the morning.

- **Bones.** Zombies leave a bone pile on the cell where they fall (0221). The piles appear at night, during the fight, and the farmer collects them on his morning round by stepping on the cell.
- **Moon stones.** After a Full Moon, moon stones lie along the horde's road (0221).
- **Bone meal.** Bones are ground into bone meal, which marks a tilled plot as fertilised until the next morning's growth (0222).
- **Essence.** Essence, the tech currency (id `tech`, 0219), gets its own icon in place of today's gear.

At 1080p, next to the 32px farmer, the pickups must read as small loot lying on grass or path, by day and in the night preview. They sit on the contrast ladder above ground and below actors, and must never look like a rock, an ore node or a crop. A fertilised plot must be told apart from a plain tilled plot, dry and wet, even with a crop on it.

## Deliverables

The table is provisional: game task 0222 settles the final canvas/footprint/states and updates it; start only when `python implementation/backlog/assets.py next` offers this pack.

| Runtime name | Native canvas | Pivot | Frames / seconds / loop | Notes |
|---|---|---|---|---|
| `bone_pile` | 16x16 | (8,14) | 1 / 0.55 / static | A low heap of 3-4 pale bones (long bones, a rib), no skull. Visible 11-13 wide x 6-8 tall. Goes to `sprites/props/`. |
| `moon_stone_0..1` | 16x16 | (8,14) | 2 / 0.4 / loop | A smooth, rounded pale stone with a cool blue-white crescent sheen. Not a faceted gem and not a crystal cluster. Visible 9-11 wide x 7-9 tall. Goes to `sprites/props/`. See the shimmer rule below. |
| `tilled_fertilised` | 16x16 | (8,16) | 1 / 0.55 / static | Opaque. Today's dry tilled soil with bone-meal clusters. Goes to `sprites/crops/`. |
| `tilled_fertilised_wet` | 16x16 | (8,16) | 1 / 0.55 / static | Opaque. The same plot, damp. Goes to `sprites/crops/`. |
| `icon_bones` / `hud_bones` | 16x16 / 10x10 | (8,8) / (5,5) | 1 / 1.0 / static | Two pale bones side by side on a diagonal, with knobbed ends. Cream, so it never reads as the grey iron ingot. |
| `icon_bone_meal` / `hud_bone_meal` | 16x16 / 10x10 | (8,8) / (5,5) | 1 / 1.0 / static | A small open burlap sack of pale powder, with the knobbed end of one bone sticking out. The bone is what tells it apart from a flour sack. |
| `icon_moon_stone` / `hud_moon_stone` | 16x16 / 10x10 | (8,8) / (5,5) | 1 / 1.0 / static | The world moon stone, larger, with its crescent sheen. It must not read as the grey `icon_stone`. |
| `icon_tech` / `hud_tech` | 16x16 / 10x10 | (8,8) / (5,5) | 1 / 1.0 / static | Essence: a small corked glass vial holding a swirl of pale moon-blue light. No halo. It replaces today's gear (task 0018), and the id stays `tech`. |

Rules for every row:

- **Direction and naming.**
  - `dir` is `none` and there are no mirrors.
  - Files are `native/<runtime name without index>/none/01..NN.png`, e.g. `native/moon_stone/none/02.png` and `native/hud_bone_meal/none/01.png`.
  - Draw scale is 1.0.
- **Pickups.** The lowest opaque row is 13, and the visible bounds are centred on x=8 (±1). They are no taller than `sprites/props/rock.png` (visible 14x10).
- **Moon stone shimmer.**
  - Both frames have an identical alpha mask.
  - 3-8 interior pixels differ: the bright `moon` glint slides along the crescent.
  - `light_xy` is the same point in both frames, on an opaque pixel of the sheen. The view's code glow (0221) is centred there.
  - The stone itself never looks lit.
- **Soil.**
  - Both tiles are fully opaque.
  - The dark furrow rows stay on rows 2-3, 6-7, 10-11 and 14-15, as in `sprites/crops/tilled.png` and `tilled_wet.png`, so a fertilised plot sits seamlessly beside a plain one.
  - Bone meal is 5-8 pale clusters of 2-4 px each, 14-32 px in all, with at least one in each 8x8 quadrant so a crop on the plot never hides them all. None touch the outer 1 px ring. No single-pixel speckle.
  - The dry clusters are `bone_dark`, with at most one `bone` pixel each.
  - On the wet tile the clusters keep their places and turn a damp grey (`stone`, `stone_light`), still lighter than the soil.
  - The wet tile's mean brightness is at least 20 below the dry one's (`check_crop_art.py`'s metric: the mean of (r+g+b)/3 over all 256 pixels).
- **Icons.**
  - One raw source per item gives both cuts with the same `crop_xywh` and two `content_scale` values.
  - `content_anchor_xy` is `(scaled_w // 2, scaled_h // 2)`.
  - The visible size is at most 14 (16x16) and at most 8 (10x10), with at least 1 clear pixel on every side.
  - There are more than 24 (16x16) or 7 (10x10) opaque pixels, in 2 or more colours.
  - The silhouette is unlike the 15 icons in `sprites/ui/`.
  - Each icon's file entry carries `resource_id` (`bones`, `bone_meal`, `moon_stone`, `tech`) and `display_role` (`inventory` or `compact_hud`), as today's manifest does.
- **`palette_keys`.**
  - `bone_pile`: `ink, ink_soft, stone_dark, stone_light, bone_dark, bone`.
  - `moon_stone`: `ink, ink_soft, night_light, stone_dark, stone, stone_light, water_light, moon`.
  - Both soil tiles: `soil_dark, soil, soil_light, ink_soft, ink, stone, stone_light, bone_dark, bone`.
  - Icons: none (all 42).

## Match these

- **Soil.** `sprites/crops/tilled.png` and `tilled_wet.png` (16x16, pivot (8,16), opaque; mean brightness 81 and 53) set the furrows, ramp and the dry-to-wet step. Their raw sources are `assets/art_source/crops/tilled.png` and `tilled_wet.png` (1254x1254, opaque). The wet one was made as an ImageGen edit of the dry one: see `implementation/sprites/generation/0010-tilled_wet.prompt.txt` and `-call.json`.
- **Pickups.** `sprites/props/rock.png`, `seam.png` and `stump.png` (16x16, pivot (8,14)) set the outline and how a small node sits. The pickups must be lower and smaller than these.
- **Icons.**
  - `sprites/ui/icon_*.png` and `hud_*.png`: all 15, with `assets/art_source/ui/wood.png` as the icon family master. Avoid look-alikes of `icon_iron` (pale ingot), `icon_stone` (grey rocks) and `icon_oil` and `icon_energy`.
  - `sprites/ui/icon_tech.png` is the gear being replaced. Show it beside the new one.
- **Scale.** The farmer is `implementation/fhd-player/pilots/2026-10-06/walk-final-mirrored/native-40/walk/down/01.png` (visible 16x32).
- **Look.** `docs/reference-sheet.png` and `assets/art_source/masters/style-night.png`.

## How to make it

1. **Prompt.** Build it as contract section 8 says.
   - Pickups: BASE + RESOURCE_PROP. Replace its braces with the pickup and "16x16, contact pivot (8,14)", and keep its "no gem fantasy crystal" line.
   - Soil: BASE + the CROP soil sentence, written the way `0010-tilled_wet.prompt.txt` was.
   - Icons: BASE + ICON.
   - Revisions: + CORRECTION.
2. **Tool.** Built-in ImageGen, one subject per call. Use `transparent_background=true` for the pickups and icons, and `false` for the two soil tiles. Attach `docs/reference-sheet.png` (role: style reference) to every call.
3. **Order.**
   1. **`bone_pile`.**
   2. **`icon_bones`**, with the pile's raw attached as its identity reference.
   3. **`moon_stone` frame 0.**
   4. **Moon stone frame 1**, an edit of frame 0 (EDIT TARGET): "change only the bright glint: slide it along the crescent; keep silhouette, size and framing".
   5. **`icon_moon_stone`**, with frame 0's raw attached as its identity reference.
   6. **`tilled_fertilised`**, an edit of `assets/art_source/crops/tilled.png` (EDIT TARGET): "keep the four furrows, ramp and framing exactly; add a few small pale bone-meal clusters on ridges and furrow edges in every quadrant; no seeds, plants, stones or sparkle".
   7. **`tilled_fertilised_wet`**, an edit of the accepted dry tile (EDIT TARGET), with `assets/art_source/crops/tilled_wet.png` attached as its moisture reference: "darken to damp soil like the reference; keep furrows and every bone-meal cluster in place, damp grey".
   8. **`icon_bone_meal`.**
   9. **`icon_tech`.**
   
   Run at most 3 CORRECTION revisions per asset.
4. **Reduce** with the mode A recipe (`render_source` in `tools/import_art.py`, imported read-only).
   - **Pickups.** `crop_xywh` is the measured visible box. Pick `content_scale` for the visible target. The default anchor gives row 13.
   - **Moon stone frame 1.** Use frame 0's `crop_xywh` and `content_scale` exactly. If the reduced alpha masks differ, or fewer than 3 pixels change, revise the edit.
   - **Soil.**
     - The crop is the whole square raw, with `content_scale` = 16 / side.
     - The default anchor (8,16) fills the tile.
     - If the furrow rows land elsewhere, regenerate. Never shift or patch pixels.
   - **Icons.** One crop gives two scales, with the anchor as above.

## Review with the owner

The page follows contract 9.5 and shows:

- **The pickups** at 1x and 4x on tiled `sprites/terrain/grass.png` and `path.png`, beside the farmer and `sprites/props/rock.png`, by day and in the night preview. The night preview is shown without the code glow and says so.
- **The moon stone** playing at 0.4 s, with `light_xy` on a separate overlay.
- **The soil** as a 3x3 field that mixes the new tiles with plain `tilled` and `tilled_wet`, with `sprites/crops/carrot_3.png` on one fertilised plot, by day and at night.
- **The icons** at 1x and 4x, both cuts, on a dark panel colour beside all 15 current icons, with the old and new `icon_tech` side by side.

Ask the owner:

1. "A pilha de ossos e a pedra da lua leem como restos para recolher no chão (não como pedra ou cristal), de dia e na prévia noturna?"
2. "O ícone de essência (um frasco com luz da lua) funciona no lugar da engrenagem de tecnologia, ou prefere outra forma?"
3. "Dá para ver a diferença entre o solo adubado e o arado comum, seco e molhado, mesmo com uma planta em cima?"

## Acceptance

- [ ] There are 13 PNGs. Canvases and pivots are exactly as in the table, and every `dir` is `none`.
- [ ] Both pickups have their lowest opaque row on 13 and are centred on x=8 (±1).
- [ ] The two moon stone frames have identical alpha and 3-8 changed pixels. `light_xy` is opaque and the same in both frames (`points_on_opaque`).
- [ ] The soil is fully opaque, with the furrow rows unchanged and the cluster rule met. Wet is at least 20 darker (`wet_darker_by_20`).
- [ ] The icons meet the size and margin rules, with one crop per item (`icon_bounds_ok`). They have no text, number, panel, shadow or glow, and no duplicate of an existing icon.
- [ ] Alpha is binary everywhere except the opaque soil. There is no baked glow, shadow, grass or ground under the pickups, and the bones and the moon stone do not look lit in the night preview.
- [ ] Only the 42 colours are used, within the `palette_keys` above, and `importer_recipe_matches` holds.
- [ ] `build.py` twice gives identical bytes, `--check` passes, and checks.json is all `true`.

## Delivery

Deliver to `implementation/backlog/deliveries/A036-night-loot/` with `raw/`, `native/`, `preview/`, `rejected/`, contract.json, checks.json, build.py, index.html and review-log.txt (contract 9.1-9.6). This pack has no `runtime/`.

contract.json has:

- `palette_mode: "A"`;
- `points: {"light_xy": [x, y]}` on `moon_stone` and on both of its file entries.

After the owner approves, write APPROVAL.json (9.7) and CLAUDE-A036-PROMPT.txt (9.8). The prompt maps every file, for example:

- `native/moon_stone/none/01..02.png -> sprites/props/moon_stone_0..1.png  16x16 pivot (8,14) draw 1.0  0.4 s loop`;
- `native/icon_tech/none/01.png -> sprites/ui/icon_tech.png` (it replaces the 0018 gear; the resource id stays `tech`).

The prompt also names the stand-ins of 0219, 0221 and 0222 that these replace.

The last step is `python implementation/backlog/assets.py set A036 approved`, and only after the owner approves in words recorded in APPROVAL.json.
