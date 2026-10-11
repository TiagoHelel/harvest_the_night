# A045 - Power icons and the new weapons' icons

- **Status:** todo
- **For game task:** 0244
- **Dressed by game tasks:** 0233, 0234
- **Spec after game task:** 0234
- **Family:** ui
- **Mode:** A - raw ImageGen sources, Claude reduces them to the 42-colour palette
- **Size of the job:** 11 icons from 11 raw sources, each cut twice (22 PNGs)

## What it is for

The night arsenal grows with the seasons (0234) and the guardian gains three powers
(0233): the farm bell stops every zombie for two seconds, the dog runs out and bites
one, and an emergency repair puts a structure back on its feet. The hotbar shows
one 16x16 icon per defence, and the night HUD shows the powers with their charge at
10x10 (and 16x16 where the power bar has room). The icons sit on the dark navy HUD
(not relit) beside pack A005's hotbar icons, and must look like the same set: each
says "this defence" or "this power" at 1x, from the defence's approved world art,
with no text.

## Deliverables

Final geometry settled by game task 0234: the eleven rows below are the
final list, each one source cut twice at the canvases written. Start only when `python implementation/backlog/assets.py next` offers this pack.

**Who reads them** (task 0234):
- **The three powers:** the night HUD's power row and its hint (0233).
- **Seven of the weapons:** the hotbar at 16x16 and the night hint at 10x10 -
  the decoy, the beehive, the catapult, the garlic braid, the searchlight, the
  electric fence and the sandbags.
- **The hardwood wall** (`wall_2`): nothing reads it yet - the hotbar has one
  wall slot, whatever its level. It is in the list for the level's upgrade
  line once one shows a picture.
- **Until 0244 they are stand-ins**, registered under A045 in 0120's road:
  - the decoy, the braid, the wire and the sandbags drawn in code (their
    drawings on the farm), with no 10x10;
  - the hive, the catapult and the searchlight as the icon of the tower they
    stand in for on the farm (the mortar's, the crossbow's and the gun
    tower's), tinted as there.

Every item: one raw source cut into `icon_<id>` 16x16 pivot (8,8) (visible at most
14x14) and `hud_<id>` 10x10 pivot (5,5) (visible at most 8x8); 1 frame, 1.0 s,
static (`loop` false), direction `none`, `mirror: "none"`, draw 1.0, runtime files
`sprites/ui/icon_<id>.png` and `sprites/ui/hud_<id>.png`. No levels, `_hurt`,
cooldown or greyed variants: those are code - the hotbar greys a defence its
season has not opened (0234) as it greys one it cannot pay for. The ids are
0233's and 0231's, and the list below is 0234's final one.

| Runtime name | Native canvas | Pivot | Frames / seconds / loop | Notes |
|---|---|---|---|---|
| `ui/icon_farm_bell`, `ui/hud_farm_bell` | 16x16, 10x10 | (8,8), (5,5) | 1 / 1.0 / static | Power. A brass farm bell (`gold_dark`, `gold`, `gold_light`) hanging from a short wooden yoke (`wood`), clapper showing, tilted mid-swing. No sound lines |
| `ui/icon_call_dog`, `ui/hud_call_dog` | 16x16, 10x10 | (8,8), (5,5) | 1 / 1.0 / static | Power. The farm dog's head (A028's dog: its coat colours, ears and muzzle) turned three-quarter to the left, ears up, mouth open in a bark |
| `ui/icon_emergency_repair`, `ui/hud_emergency_repair` | 16x16, 10x10 | (8,8), (5,5) | 1 / 1.0 / static | Power. A claw hammer crossed over a wrench (steel heads `stone`/`stone_light`, `wood` handles), with one small `flame_hot`/`gold_light` four-point spark at the crossing. No medical cross |
| `ui/icon_decoy`, `ui/hud_decoy` | 16x16, 10x10 | (8,8), (5,5) | 1 / 1.0 / static | A037's straw dummy, head and arms on the crossbar with the stake's top, filling the box. Sack head, no hat, no lit eyes: not the porch guardian |
| `ui/icon_beehive`, `ui/hud_beehive` | 16x16, 10x10 | (8,8), (5,5) | 1 / 1.0 / static | A038's level-1 hive box (roof and entrance) without its stand, two or three 1-2 px bees at the entrance |
| `ui/icon_catapult`, `ui/hud_catapult` | 16x16, 10x10 | (8,8), (5,5) | 1 / 1.0 / static | A039's catapult arm and bucket, cocked, with the orange pumpkin loaded, and a stub of the frame |
| `ui/icon_garlic_braid`, `ui/hud_garlic_braid` | 16x16, 10x10 | (8,8), (5,5) | 1 / 1.0 / static | A040's fresh braid: 4-5 plump bone-white bulbs plaited on gold stems, hanging from the stake's crosspiece |
| `ui/icon_searchlight`, `ui/hud_searchlight` | 16x16, 10x10 | (8,8), (5,5) | 1 / 1.0 / static | A041's lamp drum on its yoke, tilted to the upper right, lens dark glass with one small highlight (unlit, as A041's whole). No beam, no rays |
| `ui/icon_electric_fence`, `ui/hud_electric_fence` | 16x16, 10x10 | (8,8), (5,5) | 1 / 1.0 / static | A042's two dark iron posts with white insulators joined by two or three taut copper wires, one small `flame_hot` zigzag spark on a wire (not a lightning bolt: that is `icon_energy`) |
| `ui/icon_wall_2`, `ui/hud_wall_2` | 16x16, 10x10 | (8,8), (5,5) | 1 / 1.0 / static | The hardwood wall (A043's `wall_2`, level 2 of the stone wall): a short wall section faced with dark hardwood beams, iron straps and bolts. Same framing as A005's `icon_wall`, darker and heavier |
| `ui/icon_sandbag_wall`, `ui/hud_sandbag_wall` | 16x16, 10x10 | (8,8), (5,5) | 1 / 1.0 / static | A043's sandbag barrier: a low stack of burlap sacks, three below and two on top. A stack, not A032's single `icon_sandbag` |

- **Not in this pack:** `zombie_bait`. Its `icon_zombie_bait`/`hud_zombie_bait` is
  pack A037's ("the only one"; game task 0236 integrates it) and the hotbar reads
  it by id. The flare, START, speed and the eight older defences are A005's.
- **Recipe** (the same as A005 and the 0018 icons): `crop_xywh` = the object's
  measured alpha bounds in its raw, one crop for both cuts; 16x16 `content_scale` =
  14 / max(crop w, h), 10x10 = 8 / max(crop w, h); `content_anchor_xy` =
  `(scaled_w // 2, scaled_h // 2)`; `alpha_threshold` 128, `palette`
  `tools/palette.py:COLOURS`, `palette_keys` null unless a cut takes a colour from a
  ramp the item does not have (then record the keys and why in review-log.txt).
- **Delivery paths:** `native/icon_<id>/none/01.png` and `native/hud_<id>/none/01.png`.

## Match these

- **Pack A005's approved icons**, the style master of every hotbar icon:
  `implementation/backlog/deliveries/A005-night-icons/native/icon_<id>/none/01.png`
  and `hud_<id>` (or `sprites/ui/icon_<id>.png` once game task 0147 has integrated
  them). Match how much of a structure an icon shows, the angle, the outline and
  the fill of the box; `icon_flare` is the model for the three powers, `icon_wall`
  and `icon_fence` for the hardwood wall, the sandbags and the electric fence.
- **The approved world art of each subject** (the delivery folder's `native/`, or
  the runtime sprite once integrated): A037 `decoy`, A038 `beehive`, A039
  `catapult`, A040 `garlic_braid`, A041 `searchlight`, A042
  `electric_fence_post`/`_horizontal`, A043 `wall_2_horizontal` and
  `sandbag_wall_horizontal`, A028 `dog_sit` frame 0. Same materials and colours.
- `sprites/ui/icon_energy.png` (a lightning bolt), `icon_tech.png` and A032's
  `icon_sandbag` if approved: icons these must not be mistaken for.
- `sprites/ui/panel.png` (centre `night` #1a1830) and `button_normal.png` (centre
  `night_light` #2e2a4e): the HUD the icons sit on.
- `assets/art_source/ui/wood.png` (icon style master) and
  `implementation/sprites/generation/0018-wood.prompt.txt` (its "Native contract"
  paragraph).
- `docs/reference-sheet.png` (style; its CONSTRUA SUA DEFESA panel) and the farmer
  frame `implementation/fhd-player/pilots/2026-10-06/walk-final-mirrored/native-40/walk/down/01.png`.

## How to make it

1. **Check the inputs first.** Run `python implementation/backlog/assets.py status`
   for A005, A028, A037, A038, A039, A040, A041, A042 and A043. Each must say
   `approved` or `integrated`: their art is what these icons depict. If one does
   not, ask the owner; without an answer,
   `python implementation/backlog/assets.py set A045 blocked "waiting for Axxx approval"`
   and stop (CODEX-RUNNER, "When something goes wrong").
2. **Prompt:** BASE (canvas 16x16, pivot 8,8) + ICON from
   `implementation/sprites/generation/PROMPTS.md`, ICON's first line replaced by
   "Create ONE night hotbar icon for {id}." (or "night power icon"), "Represent ..."
   set to the Notes above, plus the 0018 "Native contract" paragraph with
   "maximum visible dimension 8" for the compact cut.
3. **Inputs:** Image 1 A005's accepted `icon_gun_tower` raw (hotbar icon style
   master: framing, outline, fill of the box; not the object); Image 2 the subject's
   approved world sprite or master raw (identity reference); Image 3
   `docs/reference-sheet.png` (style). For the bell and the repair, Image 2 is A005's
   `icon_flare` raw (the power family), not an identity.
4. **Order:** the decoy first and check it at 10x10 against A005's row before the
   rest; then the other defences; then the three powers. One call per icon, one
   candidate per call, `transparent_background=true`. Inspect the raw alpha. At most
   3 revisions per raw (CORRECTION).
5. **Export:** build.py cuts and renders through `import_art.render_source` with the
   recipe above. If a 10x10 cut loses what the thing is (the bulbs, the wires, the
   dog's ears), regenerate the raw with a bolder, simpler shape. Never patch pixels
   and never draw a cut separately.

## Review with the owner

`index.html` follows contract 9.5. It shows:

- each icon at 1x and 4x, both cuts, over flat `night` #1a1830, flat `night_light`
  #2e2a4e, tiled `sprites/ui/panel.png`, light grey and checker;
- a mock hotbar row of 16x16 slots holding A005's eight defences, A037's
  `icon_zombie_bait` and these eight, each beside its world sprite; a mock power bar
  of the flare and the three powers at 10x10 and 16x16;
- confusion pairs at 1x: `icon_electric_fence` / `icon_energy`; `icon_sandbag_wall`
  / A032's `icon_sandbag`; `icon_wall_2` / A005's `icon_wall`; `icon_decoy` / the
  porch guardian (A003) if approved;
- the farmer frame with his feet on a 16 px grid line, at 1x and 4x;
- the night preview, labelled "world relight, for reference only: the HUD is not
  relit".

Questions for the owner:

1. "Na barra de armas, cada defesa nova se reconhece ao lado das que já existem, no tamanho real?"
2. "Os três poderes (sino, cachorro, conserto) ficam claros sem texto, no 10x10?"
3. "Aprova para integração ou quer mudanças?"

## Acceptance

- [ ] Exactly 22 PNGs for the 11 ids of the final table: `icon_` 16x16 pivot (8,8) and `hud_` 10x10 pivot (5,5); no `zombie_bait` file.
- [ ] Each pair from one raw with one crop, at 14 / max and 8 / max.
- [ ] `icon_bounds_ok`: visible at most 14x14 and 8x8, centred on the pivot (±1), at least 1 transparent row and column on every side.
- [ ] More than 24 opaque pixels at 16x16 and more than 7 at 10x10, at least 2 colours each; no two PNGs of one size byte-identical and none identical to an existing `sprites/ui` icon or an A005 icon.
- [ ] Each defence keeps its approved world art's materials and colours; no beam, halo, glow, sound lines, text or numbers.
- [ ] Binary alpha, only the 42 colours, `importer_recipe_matches` true.
- [ ] Sits in a row with A005's icons without looking larger, busier or differently outlined.
- [ ] Every other item of contract section 10 holds, and `build.py` twice gives identical bytes.

## Delivery

- **Folder:** `implementation/backlog/deliveries/A045-power-weapon-icons/` with the
  standard files of contract 9.1. No `runtime/` folder: this is not a 2x pack.
- **checks.json** adds `icon_bounds_ok`, `icon_margin_ok` and `same_crop_per_pair`.
- **contract.json** `references` lists every A005, A028 and A037-A043 file used, with
  its sha256.
- **The mapping lines** in `CLAUDE-A045-PROMPT.txt`, one per file (22), e.g.
  `native/icon_farm_bell/none/01.png -> sprites/ui/icon_farm_bell.png  16x16 pivot (8,8) draw 1.0  static`
  and `native/hud_farm_bell/none/01.png -> sprites/ui/hud_farm_bell.png  10x10 pivot (5,5) draw 1.0  static`.
  The hotbar takes the 16x16 cuts and the night HUD the 10x10 ones; the handoff
  says `zombie_bait` comes from A037. They replace the stand-ins of 0233 and 0234
  for game task 0244.
- **Last step:** `python implementation/backlog/assets.py set A045 approved`, run only
  after the owner approves in words recorded in `APPROVAL.json`.
