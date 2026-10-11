# A020 - Material icons

- **Status:** integrated
- **For game task:** 0203
- **Dressed by game tasks:** 0176, 0177
- **Family:** ui
- **Mode:** A - raw ImageGen sources, Claude reduces them to the 42-colour palette
- **Size of the job:** 6 icons from 6 raw sources, each cut twice (12 PNGs)

## What it is for

New materials the day brings in: copper, coal and gold from the quarry (0176),
hardwood from the big stumps (0177), and hay and straw from the wheat (0184). Their
icons show in the inventory, the stall, the workshop's costs (16x16) and the HUD's
compact rows (10x10), on the dark navy panel, by day and by night (the HUD is not
relit). Each must read at 1x as its material and never as an icon that already
exists: gold is not money, coal is not gunpowder, hardwood is not wood, and hay and
straw are not wheat.

## Deliverables

Every file: 1 frame, 1.0 s, static (`loop` false), direction `none`, `mirror:
"none"`, draw 1.0, runtime file `sprites/ui/<name>.png`. The ids are the resource
ids 0176, 0177 and 0184 add.

| Runtime name | Native canvas | Pivot | Frames / seconds / loop | Notes |
|---|---|---|---|---|
| `ui/icon_copper`, `ui/hud_copper` | 16x16, 10x10 | (8,8), (5,5) | 1 / 1.0 / static | One copper ingot with the same trapezoid shape, three-quarter view and proportions as `icon_iron` (visible about 14x11 at 16). Copper ramp: `roof_dark` underside, `skin_dark` body, `skin` top plane, one `skin_light` glint |
| `ui/icon_coal`, `ui/hud_coal` | 16x16, 10x10 | (8,8), (5,5) | 1 / 1.0 / static | Three chunky angular coal lumps touching, flat broken faces, `ink`/`ink_soft` bodies with `stone` and `stone_light` facets on their upper-left planes so they read on the dark panel. Not a low powder heap like `icon_gunpowder` |
| `ui/icon_gold`, `ui/hud_gold` | 16x16, 10x10 | (8,8), (5,5) | 1 / 1.0 / static | One gold ingot, the same shape as the copper and iron ingots: `gold_dark` underside, `gold` body, `gold_light` top plane, one `flame_hot` glint. No round coins and no `flame` orange (that is `icon_money`) |
| `ui/icon_hardwood`, `ui/hud_hardwood` | 16x16, 10x10 | (8,8), (5,5) | 1 / 1.0 / static | One short, thick log lying on the diagonal, dark bark (`wood_dark`, `soil_dark`), its cut end toward the viewer showing tight rings in a dark reddish heartwood (`roof_dark`, `wood`). Darker and heavier than `icon_wood`'s two pale-ended orange logs |
| `ui/icon_hay`, `ui/hud_hay` | 16x16, 10x10 | (8,8), (5,5) | 1 / 1.0 / static | A compact rectangular hay bale in three-quarter view, two `wood_dark` twine bands, dried-grass texture in `gold`/`gold_light` with a few `grass_light` strands |
| `ui/icon_straw`, `ui/hud_straw` | 16x16, 10x10 | (8,8), (5,5) | 1 / 1.0 / static | A loose sheaf of long pale stalks lying horizontally, tied at the waist with twine, flared ends, no grain heads (`bone_dark`, `gold_light`, `bone`). Not the diagonal grain stalk of `icon_wheat`, not the block of the hay bale |

**Recipe** (contract section 3, mode A; the same as the 0018 resource icons):

- `crop_xywh`: the object's measured alpha bounds in its raw; one crop for both cuts.
- `content_scale`: 16x16 cut = 14 / max(crop w, h); 10x10 cut = 8 / max(crop w, h).
  The three ingots (copper, gold, and today's iron) keep the same visible size:
  copper and gold each measure 14 wide at 16x16, like `icon_iron`.
- `content_anchor_xy`: `(scaled_w // 2, scaled_h // 2)`, the centre, as in
  `ui/icon_iron` (crop 696x571, scale 14/696, anchor (7,5)).
- `alpha_threshold` 128, `palette` `tools/palette.py:COLOURS`, `palette_keys` null,
  like the 0018 icons. Set a subset for an icon (both cuts) only when a cut takes a
  colour from a ramp the item does not have (e.g. `cloth` blue in the coal), and
  record the keys and the reason in review-log.txt.
- **Delivery paths:** `native/icon_<id>/none/01.png` and `native/hud_<id>/none/01.png`.

## Match these

- `sprites/ui/icon_iron.png` (visible 14x11) and raw `assets/art_source/ui/iron.png`
  (1254x1254): the ingot that copper and gold repeat, in shape, angle and size.
- `sprites/ui/icon_wood.png` and raw `assets/art_source/ui/wood.png`: the icon style
  master (outline, 2-3 planes, upper-left light, 1 px clear padding), and the wood
  that hardwood must not look like.
- The icons these must not be mistaken for: `sprites/ui/icon_money.png` (orange
  coins), `icon_gunpowder.png` (a dark low heap), `icon_stone.png` (grey stones),
  `icon_wheat.png` (a diagonal grain stalk), and their `hud_` cuts.
- `sprites/ui/panel.png` (centre `night` #1a1830, `night_light` #2e2a4e rims) and
  `button_normal.png`: the background. Coal is the risk on it.
- `sprites/props/ore.png`, `ore_b.png`, `seam.png` (16x16) and `stump.png`: the
  quarry and stump look today. Pack A021 later draws the copper, coal and gold
  nodes and the hardwood stump to match these icons.
- `implementation/sprites/generation/0018-iron.prompt.txt` and `0018-iron-call.json`:
  an accepted icon prompt and call record to follow.
- `docs/reference-sheet.png` (style; its RECURSOS panel) and the farmer frame
  `implementation/fhd-player/pilots/2026-10-06/walk-final-mirrored/native-40/walk/down/01.png`.

## How to make it

1. **Prompt:** BASE (canvas 16x16, pivot 8,8) + ICON from
   `implementation/sprites/generation/PROMPTS.md`, with ICON's `{exact resource ID}`
   set to the id and its "Represent ..." line set to the item's Notes above, plus the
   last paragraph of `0018-iron.prompt.txt` ("Native contract: ...") with "maximum
   visible dimension 8" for the compact cut.
2. **Inputs:** Image 1 `assets/art_source/ui/wood.png` (icon style master; not the
   object); Image 2 `docs/reference-sheet.png` (style). For copper and gold also
   Image 3 `assets/art_source/ui/iron.png`, role "shape reference: match this
   ingot's silhouette, proportions and camera exactly; change only the metal".
   For hardwood, Image 3 is `wood.png` again with the role "the wood icon this must
   differ from".
3. **Order:** copper first (it proves the ingot family), then gold, coal, hardwood,
   hay, straw. One call per icon, one candidate per call,
   `transparent_background=true`. Inspect the raw alpha before accepting. At most 3
   revisions per raw (CORRECTION).
4. **Export:** build.py cuts and renders through `import_art.render_source` with the
   recipe above. If a 10x10 cut loses the material (coal's facets, the bale's
   bands, the straw's tie), regenerate the raw with a bolder, simpler shape. Never
   patch pixels and never draw a cut separately.

## Review with the owner

`index.html` follows contract 9.5. It shows:

- each icon at 1x and 4x, both cuts, over flat `night` #1a1830, flat `night_light`
  #2e2a4e, tiled `sprites/ui/panel.png`, light grey, checker and tiled
  `sprites/terrain/grass.png`;
- confusion pairs side by side at 1x and 4x, both cuts: copper / gold /
  `icon_iron`; gold / `icon_money`; coal / `icon_gunpowder` / `icon_stone`;
  hardwood / `icon_wood`; hay / straw / `icon_wheat`;
- a mock inventory column of all six 16x16 cuts with blank text bars, and a mock HUD
  row of the six 10x10 cuts, on the panel;
- the farmer frame with his feet on a 16 px grid line, at 1x and 4x;
- the night preview, labelled "world relight, for reference only: the HUD is not
  relit".

Questions for the owner:

1. "Cobre e ouro como lingotes iguais ao ferro de hoje (só muda o metal) estão bons, ou prefere pepitas brutas?"
2. "No painel escuro em 10x10, dá para separar carvão de pólvora, ouro do dinheiro, madeira de lei da madeira, e feno, palha e trigo?"
3. "Aprova para integração ou quer mudanças?"

## Acceptance

- [ ] Exactly 12 PNGs: 6 `icon_` at 16x16 pivot (8,8) and 6 `hud_` at 10x10 pivot (5,5), with the table's names.
- [ ] Each pair is cut from one raw with one crop, at 14 / max and 8 / max.
- [ ] `icon_bounds_ok`: visible at most 14x14 and 8x8, centred on the pivot (±1), at least 1 transparent row and column on every side.
- [ ] More than 24 opaque pixels at 16x16 and more than 7 at 10x10, at least 2 colours each, no two PNGs of one size byte-identical, and none byte-identical to an existing `sprites/ui/icon_*` or `hud_*` (the `tools/check_ui_art.py` rules).
- [ ] The copper and gold 16x16 cuts have the same width as `icon_iron` (14) and the same height ±1.
- [ ] Gold uses no `flame` and has no round coin shape; coal has at least 3 `stone`/`stone_light` pixels at 16x16 and at least 1 at 10x10, so it shows on the panel.
- [ ] Binary alpha, only the 42 colours, `importer_recipe_matches` true; no text, numbers, panel, frame, ground, shadow or glow.
- [ ] Every other item of contract section 10 holds, and `build.py` twice gives identical bytes.

## Delivery

- **Folder:** `implementation/backlog/deliveries/A020-material-icons/` with the
  standard files of contract 9.1. No `runtime/` folder: this is not a 2x pack.
- **checks.json** adds `icon_bounds_ok`, `icon_margin_ok`, `same_crop_per_pair`,
  `ingots_match_iron` and `coal_reads_on_panel`.
- **The mapping lines** in `CLAUDE-A020-PROMPT.txt`, one per file (12), e.g.
  `native/icon_coal/none/01.png -> sprites/ui/icon_coal.png  16x16 pivot (8,8) draw 1.0  static`
  and `native/hud_coal/none/01.png -> sprites/ui/hud_coal.png  10x10 pivot (5,5) draw 1.0  static`;
  manifest `display_role` `inventory` for `icon_` and `compact_hud` for `hud_`, as
  in the 0018 entries. They replace the stand-ins of 0176, 0177 and 0184 for game
  task 0203.
- **Last step:** `python implementation/backlog/assets.py set A020 approved`, run only
  after the owner approves in words recorded in `APPROVAL.json`.
