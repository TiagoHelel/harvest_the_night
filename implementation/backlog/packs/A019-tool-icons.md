# A019 - Tool icons

- **Status:** todo
- **For game task:** 0202
- **Dressed by game tasks:** 0173
- **Family:** ui
- **Mode:** A - raw ImageGen sources, Claude reduces them to the 42-colour palette
- **Size of the job:** 15 icons from 15 raw sources, each cut twice (30 PNGs)

## What it is for

Game task 0173 gives the farmer five tools - hoe, watering can, axe, pickaxe and
fishing rod - in three tiers each, bought at the workshop. These icons say which
tool and which tier: 16x16 in the workshop's upgrade list, the inventory and the
stall, 10x10 in compact HUD rows. They sit on the dark navy panel by day and by
night (the HUD is not relit). At 1x the tool must read from its silhouette and the
tier from the head's material, with no label. The tool in the farmer's hand is not
drawn per tier (decision): code tints its head, so the tier colours chosen here are
the tint targets.

## Deliverables

Every file: 1 frame, 1.0 s, static (`loop` false), direction `none`, `mirror:
"none"`, draw 1.0, runtime file `sprites/ui/<name>.png`. Ids are 0173's: tools
`hoe`, `can`, `axe`, `pickaxe`, `rod`; tiers `basic`, `iron`, `gold` (the rod:
`bamboo`, `fibre`, `iron`), tiers 0/1/2 of one ladder.

| Runtime name | Native canvas | Pivot | Frames / seconds / loop | Notes |
|---|---|---|---|---|
| `ui/icon_hoe_basic`, `ui/icon_hoe_iron`, `ui/icon_hoe_gold` | 16x16 | (8,8) | 1 / 1.0 / static | Hoe: handle on the 45-degree diagonal, grip at the lower left; a flat blade at the upper-right end, set at a right angle to the handle, edge facing down |
| `ui/hud_hoe_basic`, `ui/hud_hoe_iron`, `ui/hud_hoe_gold` | 10x10 | (5,5) | 1 / 1.0 / static | Same raw and crop as the 16x16 of the same tier |
| `ui/icon_can_basic`, `ui/icon_can_iron`, `ui/icon_can_gold` | 16x16 | (8,8) | 1 / 1.0 / static | Watering can in side view: round body left of centre, an arched handle over the top, the spout rising to the upper right and ending in a rose |
| `ui/hud_can_basic`, `ui/hud_can_iron`, `ui/hud_can_gold` | 10x10 | (5,5) | 1 / 1.0 / static | Same raw and crop |
| `ui/icon_axe_basic`, `ui/icon_axe_iron`, `ui/icon_axe_gold` | 16x16 | (8,8) | 1 / 1.0 / static | Axe: the same diagonal handle; a wedge head at the upper-right end, cutting edge facing right |
| `ui/hud_axe_basic`, `ui/hud_axe_iron`, `ui/hud_axe_gold` | 10x10 | (5,5) | 1 / 1.0 / static | Same raw and crop |
| `ui/icon_pickaxe_basic`, `ui/icon_pickaxe_iron`, `ui/icon_pickaxe_gold` | 16x16 | (8,8) | 1 / 1.0 / static | Pickaxe: the same diagonal handle; a curved two-pointed head crossing the upper-right end |
| `ui/hud_pickaxe_basic`, `ui/hud_pickaxe_iron`, `ui/hud_pickaxe_gold` | 10x10 | (5,5) | 1 / 1.0 / static | Same raw and crop |
| `ui/icon_rod_bamboo`, `ui/icon_rod_fibre`, `ui/icon_rod_iron` | 16x16 | (8,8) | 1 / 1.0 / static | Rod: grip at the lower left, tip at the upper right, the longest diagonal of the set; a 1 px line hangs from the tip in a short curve to a small hook |
| `ui/hud_rod_bamboo`, `ui/hud_rod_fibre`, `ui/hud_rod_iron` | 10x10 | (5,5) | 1 / 1.0 / static | Same raw and crop. The line may vanish at 10x10; the rod must not |

**The tiers.** One tool keeps one silhouette across its tiers; only the parts named
here change.

| Tier | Head (blade, pick, can body) | Joint | Handle |
|---|---|---|---|
| `basic` (0) | Worn dull iron: `ink_soft` underside, `stone_dark` body, `stone` top plane, two or three `soil`/`soil_light` rust patches, no bright glint | Rope binding (`bone_dark`, `soil_light`) | Plain `wood`, `wood_dark` underside |
| `iron` (1) | Clean steel: `stone_dark` underside, `stone` body, `stone_light` top plane, one `bone` glint on the edge | Riveted steel collar (`stone_dark`) | `wood` with a `wood_light` top line |
| `gold` (2) | The iron tier's exact shape in gold: `gold_dark` underside, `gold` body, `gold_light` top plane, one `flame_hot` glint. No coin shapes | The collar in `gold_dark` | `wood_dark` |
| rod `bamboo` (0) | Pale segmented cane (`gold_light`, `bone_dark`) with `wood_dark` node rings, thicker at the grip; no reel; the line tied to the tip | - | The cane itself |
| rod `fibre` (1) | Slimmer dark red-brown rod (`roof_dark`, `roof` top line); a small `stone` reel above the grip | - | `wood_light` cork grip |
| rod `iron` (2) | Grey steel rod (`stone`, `stone_light` top line); a larger `stone_dark`/`stone_light` reel; one guide ring near the tip | - | `wood_dark` grip |

**Recipe** (contract section 3, mode A; the same as the 0018 resource icons):

- `crop_xywh`: the object's measured alpha bounds in its raw. Both cuts of one icon
  use the same crop.
- `content_scale`: one value per tool and cut size, shared by its three tiers. L =
  the largest side of the three tier crops of that tool; 16x16 cut = 14 / L, 10x10
  cut = 8 / L.
- `content_anchor_xy`: `(scaled_w // 2, scaled_h // 2)`, the centre, as in
  `ui/icon_iron` (crop 696x571, scale 14/696 = 0.0201149, anchor (7,5)).
- `alpha_threshold` 128, `palette` `tools/palette.py:COLOURS`, `palette_keys` null
  (all 42), like the 0018 icons. Set a subset for an icon (both cuts) only when a
  cut takes a colour from a ramp the item does not have (e.g. `cloth` blue on a
  handle), and record the keys and the reason in review-log.txt.
- **Delivery paths:** `native/icon_<tool>_<tier>/none/01.png` and
  `native/hud_<tool>_<tier>/none/01.png`.

## Match these

- `sprites/ui/icon_wood.png`, `icon_iron.png`, `icon_stone.png` (16x16, visible
  14x13, 14x11, 14x11) and their `hud_` cuts; raws `assets/art_source/ui/wood.png`
  and `iron.png` (1254x1254): the icon family. Match the coloured outline, 2-3
  material planes, upper-left light, 1 px clear padding. The iron tier's steel
  matches `icon_iron`'s greys.
- `sprites/ui/icon_money.png`: coins in `flame`/`flame_hot` orange. The gold tier
  must not read as coins.
- `sprites/ui/panel.png` (centre `night` #1a1830, `night_light` #2e2a4e and `ink`
  rims, `gold_dark` border) and `button_normal.png`: the panel the icons sit on.
- The tools the farmer swings, for the kind of tool (not the tier): if
  `python implementation/backlog/assets.py status A007` and `A008` both say
  `approved` or `integrated`, the `till` and `water` strips in
  `implementation/backlog/deliveries/A007-farmer-field-work/native/` and the `chop`
  and `mine` strips in `A008-farmer-gather-work/native/`; otherwise the legacy
  48x48 frames `sprites/actors/till_1.png` (hoe), `water_1.png` (can),
  `chop_1.png` (axe), `mine_1.png` (pickaxe). For the rod: `sprites/actors/fish_1.png`.
  Record which set you used in `references`.
- `implementation/sprites/generation/0018-iron.prompt.txt` and `0018-iron-call.json`:
  an accepted icon prompt and call record to follow.
- `docs/reference-sheet.png` (style) and the farmer frame
  `implementation/fhd-player/pilots/2026-10-06/walk-final-mirrored/native-40/walk/down/01.png`
  (40x40, pivot (20,36), visible 16x32).

## How to make it

1. **Prompt:** BASE (canvas 16x16, pivot 8,8) + ICON from
   `implementation/sprites/generation/PROMPTS.md`, ICON's first line replaced by
   "Create ONE tool icon: the {tool} at the {tier} tier.", the tool's and tier's
   lines from the tables above, and the last paragraph of `0018-iron.prompt.txt`
   ("Native contract: ...") with "maximum visible dimension 8" for the compact cut.
   Add to every call: "This icon belongs to a set of five tools. Every handled tool
   lies on the same 45-degree diagonal, grip at the lower left, working end at the
   upper right; the watering can is in side view with its spout to the upper right.
   Same handle thickness and outline weight in every icon. The tier is told by the
   head's material."
2. **Inputs:** Image 1 `assets/art_source/ui/wood.png` (icon style master: outline,
   clusters, light; not the object); Image 2 `assets/art_source/ui/iron.png` (steel
   material reference; not the object); Image 3 the tool's in-hand reference from
   Match these (kind of tool only); Image 4 `docs/reference-sheet.png` (style).
3. **Order:** per tool, the middle tier first (`iron`; the rod `fibre`) as the
   tool master. Make the first one (`hoe_iron`) in two calls and keep the candidate
   whose 10x10 cut reads best: it fixes the set's angle and weight. Attach the
   accepted `hoe_iron` raw as a style reference to every later tool master.
4. **Other tiers:** an ImageGen edit of the accepted tool master raw (edit target):
   "Change only the head, the joint and the handle colour to the {tier} tier: ...
   Keep the pose, the size, the position and the outline." For the rod the edit
   also adds or removes the reel and segments as the table says.
5. `transparent_background=true` on every call, one subject per call, one candidate
   per call. Inspect the raw alpha; a painted checkerboard is a rejection. At most
   3 revisions per raw (CORRECTION).
6. **Export:** build.py cuts and renders through `import_art.render_source` with the
   recipe above. If a 10x10 cut loses the tool (the can's spout, the pick's second
   point), regenerate the raw with a bolder, simpler shape. Never patch pixels and
   never draw a cut separately.

## Review with the owner

`index.html` follows contract 9.5. It shows:

- a grid, one row per tool and one column per tier, each icon at 1x and 4x, both
  cuts;
- every cut over flat `night` #1a1830, flat `night_light` #2e2a4e, tiled
  `sprites/ui/panel.png`, light grey, checker and tiled `sprites/terrain/grass.png`;
- a mock workshop row (the 16x16 icon left of a blank bar on the panel) and a mock
  HUD row of the five 10x10 cuts of one tier, for each tier;
- a row with today's `icon_wood`, `icon_iron`, `icon_money` and `icon_fish`, and the
  farmer frame with his feet on a 16 px grid line, at 1x and 4x;
- the night preview, labelled "world relight, for reference only: the HUD is not
  relit".

Questions for the owner:

1. "No tamanho 10x10, dá para saber o nível de cada ferramenta (básico, ferro, ouro; na vara: bambu, fibra, ferro) só pela cor e pelo detalhe?"
2. "As cinco ferramentas parecem um conjunto (mesmo ângulo, tamanho e contorno) e combinam com os ícones de recursos de hoje?"
3. "Aprova para integração ou quer mudanças?"

## Acceptance

- [ ] Exactly 30 PNGs: 15 `icon_` at 16x16 pivot (8,8) and 15 `hud_` at 10x10 pivot (5,5), with the table's names.
- [ ] Each `icon_`/`hud_` pair is cut from one raw with one crop; the three tiers of a tool share both `content_scale` values.
- [ ] `icon_bounds_ok`: visible at most 14x14 and 8x8, centred on the pivot (±1), at least 1 transparent row and column on every side.
- [ ] More than 24 opaque pixels at 16x16 and more than 7 at 10x10, at least 2 colours each, no two PNGs of one size byte-identical (the `tools/check_ui_art.py` rules).
- [ ] `tiers_distinct`: within each tool the three 10x10 cuts differ pairwise in at least 6 pixels.
- [ ] Head colours follow the tier table; the gold tier has no coin shapes; the handled tools share the diagonal and the can's spout points to the upper right.
- [ ] Binary alpha, only the 42 colours, `importer_recipe_matches` true; no text, numbers, panel, frame, ground, shadow or glow.
- [ ] Every other item of contract section 10 holds, and `build.py` twice gives identical bytes.

## Delivery

- **Folder:** `implementation/backlog/deliveries/A019-tool-icons/` with the standard
  files of contract 9.1. No `runtime/` folder: this is not a 2x pack.
- **checks.json** adds `icon_bounds_ok`, `icon_margin_ok`, `same_crop_per_pair`,
  `one_scale_per_tool` and `tiers_distinct`.
- **contract.json** adds `tier_ramps`, the head ramp of each tier as three palette
  names, dark to light: `basic` [`ink_soft`, `stone_dark`, `stone`], `iron`
  [`stone_dark`, `stone`, `stone_light`], `gold` [`gold_dark`, `gold`,
  `gold_light`], `bamboo` [`gold_dark`, `bone_dark`, `gold_light`], `fibre`
  [`roof_dark`, `roof`, `roof_light`] (the iron rod uses `iron`). A007 draws the
  in-hand head in exactly `stone_dark`/`stone`/`stone_light`, and game task 0173's
  `player_work.gd` maps those three colours onto these ramps. If the approved icons
  end up using a different ramp, the review-log says so and `tier_ramps` records
  what was used.
- **The mapping lines** in `CLAUDE-A019-PROMPT.txt`, one per file (30), e.g.
  `native/icon_axe_iron/none/01.png -> sprites/ui/icon_axe_iron.png  16x16 pivot (8,8) draw 1.0  static`
  and `native/hud_axe_iron/none/01.png -> sprites/ui/hud_axe_iron.png  10x10 pivot (5,5) draw 1.0  static`;
  manifest `display_role` `inventory` for `icon_` and `compact_hud` for `hud_`, as
  in the 0018 entries. They replace 0173's stand-ins for game task 0202.
- **Last step:** `python implementation/backlog/assets.py set A019 approved`, run only
  after the owner approves in words recorded in `APPROVAL.json`.
