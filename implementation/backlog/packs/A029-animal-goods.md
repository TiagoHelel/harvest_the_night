# A029 - Animal goods

- **Status:** todo
- **For game task:** 0211
- **Dressed by game tasks:** 0184
- **Family:** ui
- **Mode:** A - raw ImageGen sources, Claude reduces them to the 42-colour palette
- **Size of the job:** 4 icons (2 cuts each) and 1 world prop: 9 PNGs from 5 raw sources

## What it is for

The coop and the barn start to pay: chickens lay eggs and cows give milk (0184),
sheep give wool and pigs dig up truffles (0185). The four goods get inventory,
stall and panel icons (16x16) and compact HUD icons (10x10), on the dark navy panel,
by day and by night (the HUD is not relit). The truffle also exists in the world:
where a pig has dug, a small truffle spot waits on the grass for the farmer to pick
up. It is a 16x16 prop, relit at night, read at 1x beside the 32px farmer as "dug
earth with something in it", not as a rock, a stump or tilled soil.

## Deliverables

Direction `none`, `mirror: "none"`, draw 1.0, 1 frame, 1.0 s for the icons and
0.55 s for the prop, static (`loop` false). The ids are the resource ids 0184 and
0185 add.

| Runtime name | Native canvas | Pivot | Frames / seconds / loop | Notes |
|---|---|---|---|---|
| `ui/icon_egg`, `ui/hud_egg` | 16x16, 10x10 | (8,8), (5,5) | 1 / 1.0 / static | Two eggs overlapping, one cream-white (`bone`, `bone_dark` shade), one pale brown (`wood_light`, `skin_light`), smooth ovals, highlight upper left |
| `ui/icon_milk`, `ui/hud_milk` | 16x16, 10x10 | (8,8), (5,5) | 1 / 1.0 / static | A short, round glass milk bottle full of white milk (`bone`, `bone_dark`), `stone_light` glass edge, a `roof` cap. Short and fat: not a wine or juice bottle (A032) |
| `ui/icon_wool`, `ui/hud_wool` | 16x16, 10x10 | (8,8), (5,5) | 1 / 1.0 / static | A ball of cream wool yarn (`bone`, `bone_dark`, a `gold_light` warm highlight) with visible wrap bands and one loose strand curling out |
| `ui/icon_truffle`, `ui/hud_truffle` | 16x16, 10x10 | (8,8), (5,5) | 1 / 1.0 / static | Two truffles: one whole, knobby, dark brown (`soil_dark`, `wood_dark`, `soil_light` knob highlights); one halved, its cut face pale with dark marbled veins (`bone_dark`, `soil`). The cut face is what tells it from a rock |
| `props/truffle_spot` | 16x16 | (8,14) | 1 / 0.55 / static | A small raised heap of freshly turned soil clods (`soil_dark`, `soil`, `soil_light` tops) with the knobby dark top of a truffle poking out. Visible 11-13 wide x 7-9 tall, centred on x=8 (±1), lowest opaque row 13. No grass, no flat dirt disc, no shadow, no hole drawn into the ground |

**Recipe** (contract section 3, mode A):

- **Icons**, as the 0018 resource icons: one crop (the object's measured alpha
  bounds) for both cuts; 16x16 `content_scale` = 14 / max(crop w, h), 10x10 =
  8 / max(crop w, h); `content_anchor_xy` `(scaled_w // 2, scaled_h // 2)`, the
  centre, as in `ui/icon_meat`.
- **Truffle spot**, as the 16x16 props (`sprites/props/rock.png`, `stump.png`):
  `crop_xywh` the measured alpha bounds; `content_scale` chosen so the heap is 12
  wide (±1); `content_anchor_xy` the default `(scaled_w // 2, scaled_h)`, so the
  lowest opaque row is 13 and the heap is centred on x=8.
- Every recipe: `alpha_threshold` 128, `palette` `tools/palette.py:COLOURS`,
  `palette_keys` null unless a cut takes a colour from a ramp the item does not have
  (then record the keys and why in review-log.txt).
- **Delivery paths:** `native/icon_<id>/none/01.png`, `native/hud_<id>/none/01.png`,
  `native/truffle_spot/none/01.png`.

## Match these

- `sprites/ui/icon_meat.png`, `icon_food.png`, `icon_wood.png` and their `hud_`
  cuts; raw `assets/art_source/ui/meat.png` and the style master
  `assets/art_source/ui/wood.png` (1254x1254): the icon family (outline, 2-3 planes,
  visible 14 / 8, 1 px clear padding). Meat is the animal product that already
  exists.
- `sprites/ui/icon_stone.png` and `icon_gunpowder.png`: the dark lumps the truffle
  icon must not look like.
- `sprites/ui/panel.png` (centre `night` #1a1830) and `button_normal.png` (centre
  `night_light` #2e2a4e): the icons' background.
- `sprites/props/rock.png` (visible 14x10, rows 4-13), `stump.png` (14x8, rows 6-13)
  and `sprites/buildings/mine.png` (12x8): 16x16 props on pivot (8,14); match their
  outline and contrast, and make the spot clearly smaller and softer than the rock.
- `sprites/crops/tilled.png` (16x16, opaque): the soil colours, and the flat tile the
  spot must not look like.
- `sprites/terrain/grass.png`, `grass_b.png`: what the spot sits on.
- `sprites/props/cow.png` and `chicken.png`: today's animals, for material only.
- `docs/reference-sheet.png` (style) and the farmer frame
  `implementation/fhd-player/pilots/2026-10-06/walk-final-mirrored/native-40/walk/down/01.png`
  (40x40, pivot (20,36), visible 16x32).

## How to make it

1. **Icons:** BASE (canvas 16x16, pivot 8,8) + ICON from
   `implementation/sprites/generation/PROMPTS.md`, ICON's `{exact resource ID}` set
   to the id and "Represent ..." set to the Notes above, plus the last paragraph of
   `implementation/sprites/generation/0018-meat.prompt.txt` ("Native contract: ...")
   with "maximum visible dimension 8" for the compact cut. Inputs: Image 1
   `assets/art_source/ui/wood.png` (icon style master; not the object), Image 2
   `docs/reference-sheet.png` (style).
2. **Truffle spot:** BASE (canvas 16x16, pivot 8,14) + RESOURCE_PROP, its first line
   replaced by "Create a truffle dig spot: a small raised heap of freshly turned soil
   clods with the knobby top of a dark truffle poking out, target 16x16, about 12 px
   wide, stable ground contact." Inputs: Image 1 `docs/reference-sheet.png` (style),
   Image 2 `assets/art_source/props/rock.png` (a same-world 16x16 prop: camera,
   outline, light; not the object), Image 3 the accepted truffle icon raw (what the
   truffle looks like).
3. **Order:** egg first (it fixes the set), then milk, wool, truffle, then the spot.
   One call each, one candidate per call, `transparent_background=true`. Inspect the
   raw alpha. At most 3 revisions per raw (CORRECTION).
4. **Export:** build.py cuts and renders through `import_art.render_source` with the
   recipes above. If a 10x10 cut loses the item (the bottle's cap, the yarn's bands,
   the truffle's cut face), regenerate the raw with a bolder, simpler shape. Never
   patch pixels.

## Review with the owner

`index.html` follows contract 9.5. It shows:

- the four icons at 1x and 4x, both cuts, over flat `night` #1a1830, flat
  `night_light` #2e2a4e, tiled `sprites/ui/panel.png`, light grey and checker, beside
  today's `icon_meat`, `icon_food`, `icon_stone` and `icon_gunpowder`; a mock
  inventory column of the 16x16 cuts and a mock HUD row of the 10x10 cuts; their
  night preview labelled "world relight, for reference only: the HUD is not relit";
- the truffle spot at 1x and 4x on tiled `grass.png` and `grass_b.png`, by day and
  in the night preview, over a 16 px tile grid, beside `sprites/props/rock.png`,
  `stump.png` and a `tilled.png` tile, with the farmer frame's feet on the same
  ground line.

Questions for the owner:

1. "Ovo, leite, lã e trufa se reconhecem no 10x10 do painel escuro?"
2. "O montinho da trufa se destaca na grama, de dia e à noite, sem parecer pedra, toco ou terra arada?"
3. "Aprova para integração ou quer mudanças?"

## Acceptance

- [ ] Exactly 9 PNGs: 4 `icon_` 16x16 pivot (8,8), 4 `hud_` 10x10 pivot (5,5), and `truffle_spot` 16x16 pivot (8,14).
- [ ] Each icon pair from one raw with one crop; visible at most 14 and 8, centred (±1), at least 1 transparent row and column on every side.
- [ ] More than 24 opaque pixels at 16x16 and more than 7 at 10x10, at least 2 colours each, no two PNGs of one size byte-identical and none identical to an existing `sprites/ui` icon.
- [ ] `truffle_spot`: lowest opaque row 13, centred on x=8 (±1), visible 11-13 wide and 7-9 tall, 1 px clear on the left, right and top, no ground or grass pixels around the heap.
- [ ] Binary alpha, only the 42 colours, `importer_recipe_matches` true; no text, numbers, panel, frame, shadow or glow.
- [ ] Every other item of contract section 10 holds, and `build.py` twice gives identical bytes.

## Delivery

- **Folder:** `implementation/backlog/deliveries/A029-animal-goods/` with the standard
  files of contract 9.1. No `runtime/` folder: this is not a 2x pack.
- **checks.json** adds `icon_bounds_ok`, `icon_margin_ok`, `same_crop_per_pair` and
  `grounded_on_pivot` (for the spot).
- **The mapping lines** in `CLAUDE-A029-PROMPT.txt`:
  - `native/icon_<id>/none/01.png -> sprites/ui/icon_<id>.png  16x16 pivot (8,8) draw 1.0  static` and `native/hud_<id>/none/01.png -> sprites/ui/hud_<id>.png  10x10 pivot (5,5)` for `egg`, `milk`, `wool`, `truffle` (manifest `display_role` `inventory` and `compact_hud`);
  - `native/truffle_spot/none/01.png -> sprites/props/truffle_spot.png  16x16 pivot (8,14) draw 1.0  static`, added to `check_prop_art.NAMES`.

  They replace the stand-ins of 0184 and 0185 for game task 0211.
- **Last step:** `python implementation/backlog/assets.py set A029 approved`, run only
  after the owner approves in words recorded in `APPROVAL.json`.
