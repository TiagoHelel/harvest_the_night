# A044 - Day tarps over the defences

- **Status:** integrated
- **For game task:** 0243
- **Dressed by game tasks:** 0223
- **Spec after game task:** 0234
- **Family:** defences
- **Mode:** A - raw ImageGen sources, Claude reduces them to the 42-colour palette
- **Size of the job:** 6 still sprites, 3 animations of 2 frames

## What it is for

By day the defences sleep under tarps, so the farm looks like a farm; at dusk
the covers come off in the wake the transition already plays, and at dawn they
go back on. One tarp per footprint covers every defence of that size: a lumpy
canvas cover roped and pegged over something, generic enough to hide a gun
tower, a mortar or a beehive alike. The player sees them all day across the
farm, so they are calm props (below the farmer and the house in contrast) that
still say "a defence sleeps here", including when it was damaged last night.

## Deliverables

Final geometry settled by game task 0234: the three footprints and the
rows below stand as written, and every defence of the year is now placed on
one of them or on none. Start only when `python implementation/backlog/assets.py next` offers this pack.

Families - **chosen by game task 0223** (2026-10-10), **settled by 0234**
(2026-10-11):

- **The game's one list is `Transition.TARPS`** (`src/ui/transition.gd`).
- **`tarp_tower`** covers the towers at every level: `gun_tower`,
  `auto_crossbow`, `flame_tower` and `mortar`, and since 0234 `beehive`,
  `catapult` and `searchlight` - the three new families that also flare at
  the wake (`Transition.WAKES`).
- **`tarp_tall`** covers the `decoy`, **`tarp_short`** the `garlic_braid`.
- **No tarp for barriers, mines or the bait:** a covered wall is still a
  wall, and a covered mine is a lie - so not the fence, the wall at either
  level, the barricade, the sandbags or the electric fence, the mine or
  the zombie bait. The generator still wakes at dusk, bare.
- **A hurt defence wears the `_hurt` cover by day**, past the tower's own
  hurt threshold, so the morning never hides the night's damage.
- **A defence that came down is rubble,** swept at dawn, so by day there is
  no `_wreck` to cover.
- **Every file below is drawn by code until 0243** (`TarpArt`,
  `src/ui/tarp_art.gd`), at these canvases and pivots: a khaki mound roped
  and pegged, a torn one, a yank and a flying bundle.
- **The game shows a covered state *instead of* the defence**, as a child
  of its sprite at the same pivot, so it sorts the way the defence does.
  The unveil frames are drawn over it.
- **The unveil plays at the wake:** the middle of the switch into the
  night, where the towers flare, 0.12 s a frame. At dawn it plays
  backwards, and the cover goes back on.

| Runtime name | Native canvas | Pivot | Frames / seconds / loop | Notes |
|---|---|---|---|---|
| `buildings/tarp_tower` | 32x48 | (16,44) | 1 / static (0.55, loop false) | Covered: drawn **instead of** the tower. A weathered khaki canvas draped over a lumpy shape, roped round the middle and pegged at the base. Visible about 22-24 wide x 22-26 tall, centred on x 16, lowest opaque row 43, bbox x 1..30. |
| `buildings/tarp_tower_hurt` | 32x48 | (16,44) | 1 / static | The same cover torn: a ripped flap hanging, a dark hole showing shadow beneath (not the tower's art), one rope snapped. Its alpha shape differs from the whole cover. Shown for a hurt defence by day. |
| `buildings/tarp_tower_unveil_0..1` | 32x48 | (16,44) | 2 at 0.12 s, one-shot | Drawn **over** the uncovered defence. Poses `yank` (the canvas whipped up and toward the west, the lower half gone, bunched above the defence's top) and `away` (a small crumpled bundle flying off at the upper left, inside the canvas). At dawn the view plays the two frames in reverse; no extra frames. |
| `buildings/tarp_tall`, `tarp_tall_hurt` | 16x32 | (8,28) | 1 each / static | The same cover and canvas over a tall narrow shape (the decoy). Visible about 11-13 wide x 22-25 tall, x 1..14, lowest row 27. |
| `buildings/tarp_tall_unveil_0..1` | 16x32 | (8,28) | 2 at 0.12 s, one-shot | As the tower's, scaled to this canvas; the bundle stays inside x 0..15. |
| `buildings/tarp_short`, `tarp_short_hurt` | 16x24 | (8,20) | 1 each / static | The same cover over a short post (the garlic braid). Visible about 10-12 wide x 14-17 tall, x 2..13, lowest row 19. |
| `buildings/tarp_short_unveil_0..1` | 16x24 | (8,20) | 2 at 0.12 s, one-shot | As above, inside this canvas. |

- Every row: dir `none`, `mirror: "none"`, draw scale 1.0, no metadata points.
- The unveil frames are not grounded (the cover is in the air); every covered
  state is (lowest opaque row = `pivot_y - 1`).
- All three footprints share one canvas material and colours: default a
  weathered khaki canvas (`bone_dark`, `wood_light`, `soil_light`, `soil_dark`
  shading) with `gold_dark` rope and `wood_dark` pegs - not green (it would sink
  into the grass) and not the farmer's blue.
- One `content_scale` per footprint across its four files (one raw sheet each).
- Delivery paths: `native/tarp_tower/none/01.png`, `native/tarp_tower_hurt/none/01.png`,
  `native/tarp_tower_unveil/none/01..02.png`, and the same for `tarp_tall` and
  `tarp_short` (12 files).

## Match these

- `sprites/buildings/gun_tower.png`, `gun_tower_3.png`, `mortar_3.png`,
  `auto_crossbow.png`, `flame_tower.png` - the shapes `tarp_tower` hides and the
  base line (row 43) it shares. The cover must look like it could hide any of
  them, without their outline showing through.
- `sprites/buildings/barricade.png` (16x24, pivot (8,20)) and the 16x32 barrier
  canvases in `sprites/buildings/modules/` - the small canvases' scale.
- `sprites/props/shop.png` and `sprites/buildings/house.png` - the cloth, rope
  and timber of today's farm props; the tarp sits below them in contrast.
- `sprites/terrain/grass.png` - the ground it must stand out from by day.
- The 32 px farmer frame `implementation/fhd-player/pilots/2026-10-06/walk-final-mirrored/native-40/walk/down/01.png`.
- `docs/reference-sheet.png` - the day farm the covers belong to.

## How to make it

1. Prompt = BASE (from `implementation/sprites/generation/PROMPTS.md`) with this
   pack's lines as the family section, plus STRIP for the unveil, and the
   "LAYOUT CLEARANCE" paragraph of `0013-mortar-level-2.prompt.txt` for the
   sheets. `transparent_background=true` on every call. Attach
   `docs/reference-sheet.png` (style) and `sprites/buildings/gun_tower.png`
   (scale) and say each role.
2. **Master** (1 call, at most 2 fresh candidates): the tower cover, one object:
   "a weathered khaki canvas tarp draped over a squat machine, folds clustered,
   a rope tied round the middle, two wooden pegs at the base; the shape beneath
   unreadable".
3. **One sheet per footprint** (3 calls, master attached as identity master):
   four cells in one row with wide transparent gutters - COVERED, TORN, YANK,
   AWAY - the covered and torn cells on one baseline; the unveil cells keep the
   same cell size and centre so they can be cut at the same anchor.
4. Export with the mode A recipe (contract section 3, `render_source` imported
   read-only): one `content_scale` per footprint; `content_anchor_xy` so covered
   and torn states end on `pivot_y - 1` and centre on the pivot x. For an unveil
   frame, measure the COVERED cover's ground point (base centre, bottom) relative
   to its cell, take the same point in the unveil's own cell, and set
   `content_anchor_xy` = (point - crop origin) x scale, rounded, so the cloth
   lifts from where it lay. `alpha_threshold` 128; `palette_keys` null.

## Review with the owner

The page (contract 9.5) shows the 12 files at 1x and 4x by day and in the night
preview (the unveil plays at dusk); each cover on tiled grass beside the farmer
frame on one ground line over a 16 px grid; a dusk sequence per footprint -
covered, `yank` over the uncovered defence (`gun_tower.png`, a 16x32 and a 16x24
stand-in from `sprites/buildings/`), `away`, then the defence alone - playing at
0.12 s and as a still strip; a day row of covered towers beside the house.

Ask the owner:

1. "Cor da lona: cáqui (padrão) ou prefere outra, como verde-oliva?"
2. "A lona rasgada deixa claro, de dia, que a defesa foi danificada na noite?"
3. "O destapar em 2 quadros (0,12 s cada) ficou rápido ou lento demais?"

## Acceptance

- [ ] 12 files; canvases and pivots exactly as the table.
- [ ] Covered and torn states: lowest opaque row = `pivot_y - 1`, centred on the
      pivot x (±1), bbox inside the canvas with 1 px clear; torn differs from
      covered in alpha shape.
- [ ] Unveil frames: 2 distinct frames per footprint, inside the canvas, the
      `away` frame smaller in area than `yank`; nothing of a defence drawn in them.
- [ ] One raw and one `content_scale` per footprint; the three footprints share
      the cloth colours and fold style.
- [ ] No tower, decoy or braid shape readable under the cover.
- [ ] Binary alpha, true transparent raws, only the 42 colours, recipe matches,
      build twice identical; no shadow, ground patch, glow, night version or text.
- [ ] Calm by day (below the farmer and the house in contrast) yet readable as
      "a covered defence" at 1x.

## Delivery

Folder `implementation/backlog/deliveries/A044-tarps/` with `raw/` (each return
plus `.prompt.txt` and `.call.json`), `native/`, `preview/`, `rejected/`,
`contract.json`, `checks.json`, `build.py`, `index.html` and `review-log.txt`
(contract section 9); after approval `APPROVAL.json` and `CLAUDE-A044-PROMPT.txt`
(mapping each `native/<anim>/none/NN.png` to `sprites/<runtime name>.png`, with
the family list per footprint and the rule: covered replaces the defence, unveil
draws over it). Last step, only after the owner approves in words recorded
verbatim in `APPROVAL.json`:
`python implementation/backlog/assets.py set A044 approved`.
