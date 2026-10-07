# A032 - Artisan goods

- **Status:** todo
- **For game task:** 0214
- **Dressed by game tasks:** 0187, 0188
- **Spec after game task:** 0188
- **Family:** ui
- **Mode:** A - raw ImageGen sources, Claude reduces them to the 42-colour palette
- **Size of the job:** 11 icons from 11 raw sources, each cut twice (22 PNGs)

## What it is for

The artisan machines turn the farm's produce into goods worth much more: the keg
and the preserves jar (0187) make wine, juice, jelly and pickles; the dairy, the
loom and the mill (0188) make cheese, butter, cloth, sandbags, flour and sugar; the
kitchen bakes bread from flour (0192). Each good gets an inventory, stall and
machine-panel icon (16x16) and a compact HUD icon (10x10), on the dark navy panel,
by day and by night (the HUD is not relit). At 1x the eleven must be told apart
from each other and from today's icons, above all the bottles, the jars and the
sacks.

## Deliverables

The table is provisional: game task 0188 settles the final canvas/footprint/states and updates it; start only when `python implementation/backlog/assets.py next` offers this pack.

Every file: 1 frame, 1.0 s, static (`loop` false), direction `none`, `mirror:
"none"`, draw 1.0, runtime file `sprites/ui/<name>.png`. The ids are the resource
ids 0187, 0188 and 0192 give the goods; 0188 writes the final list here.

| Runtime name | Native canvas | Pivot | Frames / seconds / loop | Notes |
|---|---|---|---|---|
| `ui/icon_wine`, `ui/hud_wine` | 16x16, 10x10 | (8,8), (5,5) | 1 / 1.0 / static | A tall wine bottle of deep red glass (`blood`, `roof_dark`, a `roof_light` glint), long neck, `wood_light` cork, a blank `bone_dark` label band (no text) |
| `ui/icon_juice`, `ui/hud_juice` | 16x16, 10x10 | (8,8), (5,5) | 1 / 1.0 / static | A round glass jug with a side handle, full of orange juice (`flame`, `flame_hot`), `stone_light` glass rim, `wood_light` stopper |
| `ui/icon_jelly`, `ui/hud_jelly` | 16x16, 10x10 | (8,8), (5,5) | 1 / 1.0 / static | A squat jar of dark red jelly (`roof_dark`, `roof`), a `bone` cloth cover tied over the lid with string |
| `ui/icon_pickles`, `ui/hud_pickles` | 16x16, 10x10 | (8,8), (5,5) | 1 / 1.0 / static | A taller straight-sided jar of green pickles (`grass`, `grass_dark`) in pale brine, a `stone` metal lid. Taller and greener than the jelly |
| `ui/icon_cheese`, `ui/hud_cheese` | 16x16, 10x10 | (8,8), (5,5) | 1 / 1.0 / static | A wedge cut from a wheel, pale yellow (`gold_light`, `flame_hot`) with a `gold_dark` rind and two round holes |
| `ui/icon_butter`, `ui/hud_butter` | 16x16, 10x10 | (8,8), (5,5) | 1 / 1.0 / static | A rectangular butter block half wrapped in folded paper (`bone`, `bone_dark`), the yellow top exposed (`flame_hot`). A block, no holes: not the cheese |
| `ui/icon_cloth`, `ui/hud_cloth` | 16x16, 10x10 | (8,8), (5,5) | 1 / 1.0 / static | A folded stack of woven wool cloth, two or three layers, cream (`bone`, `bone_dark`) with one `cloth` blue stripe along the folds |
| `ui/icon_sandbag`, `ui/hud_sandbag` | 16x16, 10x10 | (8,8), (5,5) | 1 / 1.0 / static | One squat burlap sack lying on its side, tied at one end, rough tan weave (`soil_light`, `bone_dark`, `soil` underside), a stitched seam. One sack: the night barrier of sandbags (A043, A045) is a stack |
| `ui/icon_flour`, `ui/hud_flour` | 16x16, 10x10 | (8,8), (5,5) | 1 / 1.0 / static | An upright white cotton sack (`bone`, `bone_dark`), its top folded open on white flour, a `gold` wheat-ear emblem on the front (a shape, not text). Not burlap (that is A036's bone meal and the sandbag) |
| `ui/icon_bread`, `ui/hud_bread` | 16x16, 10x10 | (8,8), (5,5) | 1 / 1.0 / static | A round crusty loaf (`wood_light`, `gold`, `gold_dark` crust) with three diagonal score marks |
| `ui/icon_sugar`, `ui/hud_sugar` | 16x16, 10x10 | (8,8), (5,5) | 1 / 1.0 / static | A small stack of three white sugar cubes in three-quarter view (`bone`, `bone_dark`, `stone_light` shaded sides) |

**Recipe** (contract section 3, mode A; the same as the 0018 resource icons):

- `crop_xywh`: the object's measured alpha bounds in its raw; one crop for both cuts.
- `content_scale`: 16x16 cut = 14 / max(crop w, h); 10x10 cut = 8 / max(crop w, h).
- `content_anchor_xy`: `(scaled_w // 2, scaled_h // 2)`, the centre, as in
  `ui/icon_oil` and `ui/icon_food`.
- `alpha_threshold` 128, `palette` `tools/palette.py:COLOURS`, `palette_keys` null.
  Set a subset for an icon (both cuts) only when a cut takes a colour from a ramp
  the item does not have (e.g. `cloth` blue in the bread), and record the keys and
  the reason in review-log.txt.
- **Delivery paths:** `native/icon_<id>/none/01.png` and `native/hud_<id>/none/01.png`.

## Match these

- `sprites/ui/icon_oil.png` (a barrel, visible 10x14), `icon_food.png` (a bowl),
  `icon_meat.png`, `icon_wheat.png`, `icon_corn.png` and their `hud_` cuts; raws
  `assets/art_source/ui/oil.png`, `food.png` and the style master
  `assets/art_source/ui/wood.png` (1254x1254): the icon family to match (outline,
  2-3 planes, visible 14 / 8, 1 px clear padding), and the produced goods that
  already exist.
- If `python implementation/backlog/assets.py status A029` says `approved` or
  `integrated`: its `icon_milk` (the milk bottle the wine and juice must differ
  from) and `icon_wool` (the wool the cloth is made of), from
  `implementation/backlog/deliveries/A029-animal-goods/native/`. If
  `A036` is approved: its `icon_bone_meal` (the burlap sack the flour must differ
  from), from `implementation/backlog/deliveries/A036-night-loot/native/`.
- `sprites/ui/panel.png` (centre `night` #1a1830) and `button_normal.png` (centre
  `night_light` #2e2a4e): the background.
- `implementation/sprites/generation/0018-oil.prompt.txt` and `0018-oil-call.json`:
  an accepted container-icon prompt and call record.
- `docs/reference-sheet.png` (style; the PRODUZIR panel) and the farmer frame
  `implementation/fhd-player/pilots/2026-10-06/walk-final-mirrored/native-40/walk/down/01.png`.

## How to make it

1. **Prompt:** BASE (canvas 16x16, pivot 8,8) + ICON from
   `implementation/sprites/generation/PROMPTS.md`, ICON's `{exact resource ID}` set
   to the id and "Represent ..." set to the Notes above, plus the last paragraph of
   `0018-oil.prompt.txt` ("Native contract: ...") with "maximum visible dimension 8"
   for the compact cut.
2. **Inputs:** Image 1 `assets/art_source/ui/wood.png` (icon style master; not the
   object); Image 2 `docs/reference-sheet.png` (style); for the bottles and jars
   also Image 3 `assets/art_source/ui/oil.png` ("a same-family container icon:
   outline and planes; not the object").
3. **Order:** the four vessels first (wine, juice, jelly, pickles), reviewed together
   at 10x10 before going on: they are the likeliest to blur together. Then cheese,
   butter, cloth, sandbag, flour, bread, sugar. One call per icon, one candidate per
   call, `transparent_background=true`. Inspect the raw alpha. At most 3 revisions
   per raw (CORRECTION).
4. **Export:** build.py cuts and renders through `import_art.render_source` with the
   recipe above. If two 10x10 cuts read the same, regenerate the weaker raw with its
   telling feature larger (the jug's handle, the cloth cover, the cheese holes, the
   flour's open top). Never patch pixels and never draw a cut separately.

## Review with the owner

`index.html` follows contract 9.5. It shows:

- the eleven icons at 1x and 4x, both cuts, over flat `night` #1a1830, flat
  `night_light` #2e2a4e, tiled `sprites/ui/panel.png`, light grey and checker;
- confusion groups side by side at 1x and 4x, both cuts: wine / juice / today's
  `icon_oil` (and A029's milk if approved); jelly / pickles; cheese / butter; flour /
  sandbag / sugar (and A036's bone meal if approved); bread / today's `icon_food`;
- a mock machine panel row (input icon, arrow, output icon) on the panel, and a mock
  HUD row of the eleven 10x10 cuts;
- the farmer frame with his feet on a 16 px grid line, at 1x and 4x;
- the night preview, labelled "world relight, for reference only: the HUD is not
  relit".

Questions for the owner:

1. "Os 11 produtos se distinguem no 10x10, principalmente vinho e suco, geleia e picles, e farinha, saco de areia e açúcar?"
2. "Eles combinam com os ícones de recursos de hoje (óleo, comida, carne), no mesmo tamanho e estilo?"
3. "Aprova para integração ou quer mudanças?"

## Acceptance

- [ ] Exactly 22 PNGs for the 11 ids of the final table: `icon_` 16x16 pivot (8,8) and `hud_` 10x10 pivot (5,5).
- [ ] Each pair from one raw with one crop, at 14 / max and 8 / max.
- [ ] `icon_bounds_ok`: visible at most 14x14 and 8x8, centred on the pivot (±1), at least 1 transparent row and column on every side.
- [ ] More than 24 opaque pixels at 16x16 and more than 7 at 10x10, at least 2 colours each; no two PNGs of one size byte-identical and none identical to an existing `sprites/ui` icon.
- [ ] Labels and emblems are blank shapes: no letters, numbers or brand marks anywhere.
- [ ] Binary alpha, only the 42 colours, `importer_recipe_matches` true; no panel, frame, table, shadow or glow.
- [ ] Every other item of contract section 10 holds, and `build.py` twice gives identical bytes.

## Delivery

- **Folder:** `implementation/backlog/deliveries/A032-artisan-goods/` with the
  standard files of contract 9.1. No `runtime/` folder: this is not a 2x pack.
- **checks.json** adds `icon_bounds_ok`, `icon_margin_ok` and `same_crop_per_pair`.
- **The mapping lines** in `CLAUDE-A032-PROMPT.txt`, one per file (22), e.g.
  `native/icon_cheese/none/01.png -> sprites/ui/icon_cheese.png  16x16 pivot (8,8) draw 1.0  static`
  and `native/hud_cheese/none/01.png -> sprites/ui/hud_cheese.png  10x10 pivot (5,5) draw 1.0  static`;
  manifest `display_role` `inventory` for `icon_` and `compact_hud` for `hud_`. They
  replace the stand-ins of 0187, 0188 and 0192 for game task 0214.
- **Last step:** `python implementation/backlog/assets.py set A032 approved`, run only
  after the owner approves in words recorded in `APPROVAL.json`.
