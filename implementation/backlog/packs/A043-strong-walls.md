# A043 - Hardwood walls and sandbags

- **Status:** todo
- **For game task:** 0242
- **Dressed by game tasks:** 0231
- **Spec after game task:** 0231
- **Family:** defences
- **Mode:** A - raw ImageGen sources, Claude reduces them to the 42-colour palette
- **Size of the job:** 12 barrier modules + 2 wrecks (64 joins composed from them)

## What it is for

Two stronger ways to hold a line at night. The **hardwood wall** is level 2 of
today's stone wall (`wall`): the same masonry rebuilt with heavy hardwood beams
and iron straps, something a breaker has to work at - it joins stone walls in
one run, so it keeps their silhouette and changes the material. The **sandbag
wall** is a cheap, low barrier of burlap sacks from the loom that soaks more than
a fence. Both join their neighbours on all 16 masks like the wall and the fence,
and both must read at 1x after the night relight, beside each other and beside
stone.

## Deliverables

The table is provisional: game task 0231 settles the final canvas/footprint/states and updates it; start only when `python implementation/backlog/assets.py next` offers this pack.

| Runtime name | Native canvas | Pivot | Frames / seconds / loop | Notes |
|---|---|---|---|---|
| `buildings/modules/wall_2_post` | 16x32 | (8,28) | 1 / static (0.55) | Hardwood. Stone pier wrapped by dark hardwood planks with an iron strap and a hardwood cap. Envelope of `wall_post`: x 5-10 (±1), rows 5-19, lowest opaque row 19 (stands on row 20). |
| `buildings/modules/wall_2_horizontal` | 16x32 | (8,28) | 1 / static | East-west span, no end piers: stone courses faced with two horizontal hardwood beams and bolts. Rows 12-19 exactly, opaque at x 0 and x 15, so it meets `wall_horizontal` on at least 2 rows. |
| `buildings/modules/wall_2_vertical` | 16x32 | (8,28) | 1 / static | North-south span seen from above along the screen Y axis (not an upright pillar): x 6-10, content inside rows 8-27 and reaching both ends, like `wall_vertical` rows 9-27. |
| `buildings/modules/wall_2_{post,horizontal,vertical}_hurt` | 16x32 | (8,28) | 1 each / static | Same scale and placement: split planks, a sprung strap, a missing stone; every hurt module's alpha shape differs from its whole one. |
| `buildings/wall_2_wreck` | 16x32 | (8,28) | 1 / static | Low heap of stone and broken hardwood beams: height at most 8, width at most 14, lowest row 27 (like `wall_wreck` rows 23-27). |
| `buildings/wall_2`, `wall_2_join_<1..15>`, `wall_2_hurt`, `wall_2_join_<1..15>_hurt` | 16x32 | (8,28) | 1 each / static | **Composed by build.py** from the six modules (32 masks), with the contract's recipe (section 2.3). |
| `buildings/modules/sandbag_wall_post` | 16x32 | (8,28) | 1 / static | A small stack of 3 sacks (2 below, 1 on top). Visible about 8-10 wide x 7-9 tall, centred on x 8, lowest opaque row 19. |
| `buildings/modules/sandbag_wall_horizontal` | 16x32 | (8,28) | 1 / static | Two staggered courses of plump sacks, 3 per course, spanning x 0-15; rows 12-19, the same span rows as the wall and the fence. |
| `buildings/modules/sandbag_wall_vertical` | 16x32 | (8,28) | 1 / static | A line of sacks seen from above along the screen Y axis: x 5-11, content inside rows 8-27 and reaching both ends. |
| `buildings/modules/sandbag_wall_{post,horizontal,vertical}_hurt` | 16x32 | (8,28) | 1 each / static | Split sacks slumped, a gap in a course, a little sand spilled within the pile (no ground patch); alpha shape differs from whole. |
| `buildings/sandbag_wall_wreck` | 16x32 | (8,28) | 1 / static | Flattened, burst sacks: height at most 6, width at most 14, lowest row 27. |
| `buildings/sandbag_wall`, `sandbag_wall_join_<1..15>`, `sandbag_wall_hurt`, `sandbag_wall_join_<1..15>_hurt` | 16x32 | (8,28) | 1 each / static | **Composed by build.py** from the six sandbag modules (32 masks). |

- Every row: dir `none`, `mirror: "none"`, draw scale 1.0, no metadata points.
- One `content_scale` per family across its six modules and its wreck.
- **Names are provisional**: `wall_2_*` follows the tower level naming
  (`<id>_<level>`) and `sandbag_wall` is the id 0231 suggests for a barrier paid
  in the loom's `sandbag` material. 0231 writes the final names and whether the
  sandbags are modules (this default) or one 16x24 piece, and rewrites this table.
- `contract.json` carries `joins` for both families; native paths are
  `native/<runtime name without folder>/none/01.png` (78 files).

## Match these

- `sprites/buildings/modules/wall_post.png`, `wall_horizontal.png`,
  `wall_vertical.png` and their `_hurt` versions - the hardwood wall's exact
  envelope and its stone. Open them at 4x.
- `sprites/buildings/wall.png`, `wall_join_1..15.png`, `wall_join_*_hurt.png`,
  `wall_wreck.png` - what a joined run looks like; the hardwood joins must sit
  in the same run without a step.
- `assets/art_source/defences/wall/whole-r2.png` and `whole-r3.png` - the raw
  module rows the stone wall was cut from (identity master for level 2).
- `sprites/buildings/modules/fence_*.png` and `sprites/buildings/barricade.png`
  - lighter barriers the sandbags sit between, in height and weight.
- `implementation/sprites/generation/0014-wall-whole-r2.prompt.txt` and
  `0014-fence-whole-r2.prompt.txt` - the module-row prompts, including the fix
  that made the north-south module a long run lying along the screen Y axis.
- The sandbag icon of pack A032 if it is approved by then (match its burlap).
- The 32 px farmer frame `implementation/fhd-player/pilots/2026-10-06/walk-final-mirrored/native-40/walk/down/01.png`.

## How to make it

1. Prompt = BASE + WALL_TRAP (from `implementation/sprites/generation/PROMPTS.md`)
   plus the four-module paragraph of `0014-fence-whole-r2.prompt.txt`, with the
   material lines below. `transparent_background=true` on every call. Attach
   `docs/reference-sheet.png` (style) and the stone wall raw (identity master for
   the hardwood, module layout and scale for the sandbags) and say each role.
2. **Hardwood whole row** (1 call, `assets/art_source/defences/wall/whole-r3.png`
   attached as edit target): "the same stone wall modules upgraded with heavy
   dark hardwood beams, iron straps and bolts; same proportions" - POST,
   HORIZONTAL, VERTICAL, WRECK. **Hardwood hurt row** (1 call): POST,
   HORIZONTAL, VERTICAL damaged.
3. **Sandbag whole row** (1 call): "burlap sandbags tied with twine, plump,
   stacked like bricks" - POST, HORIZONTAL, VERTICAL, WRECK. **Sandbag hurt row**
   (1 call). Sandbags are low: the post about half the stone pier's height.
4. In every row the vertical is at least 1.7 times as long as the horizontal
   span is wide, and lies along the ground, not upright.
5. Export with the mode A recipe (contract section 3, `render_source` imported
   read-only): one `content_scale` per family, `content_anchor_xy` so posts and
   spans stand on row 20 and wrecks end on row 27, `alpha_threshold` 128,
   `palette_keys` null; then build.py composes 2 x 32 masks with the section 2.3
   table exactly.

## Review with the owner

The page (contract 9.5) shows every module and wreck at 1x and 4x, day and night
preview; all 64 composed masks laid out as real runs (straight, L corner, T,
cross, whole and hurt) over tiled grass; a **mixed line** stone - hardwood -
stone - sandbags - fence on one row to judge seams and heights; the farmer frame
and a walker on the same ground line.

Ask the owner:

1. "O muro de madeira de lei parece um muro de pedra reforçado (nível 2) e emenda bem com o muro de pedra comum?"
2. "Os sacos de areia se leem como sacos (e não pedras) a 1x, também na prévia noturna?"

## Acceptance

- [ ] 78 files: per family 6 modules + 1 wreck + 32 composed masks, all 16x32 / (8,28).
- [ ] Posts and spans stand on row 20 (lowest opaque row 19); spans opaque at
      x 0 and x 15 on rows within 12-19; verticals inside rows 8-27.
- [ ] One `content_scale` per family; hardwood wreck at most 8 rows, sandbag
      wreck at most 6, both ending on row 27.
- [ ] `all_32_masks_composed` true for both; arms match the mask bits; every hurt
      mask's alpha differs from its whole mask by at least 3 pixels.
- [ ] East-west seams hardwood-to-stone (`wall_join_8`, whole and hurt) share at
      least 2 opaque rows; the hardwood post is not taller than the stone post.
- [ ] Hardwood whole modules differ visibly from the stone ones at 1x.
- [ ] Binary alpha, true transparent raws, only the 42 colours, recipe matches,
      build twice identical; no shadow, ground, glow, night version or text.

## Delivery

Folder `implementation/backlog/deliveries/A043-strong-walls/` with `raw/` (each
return plus `.prompt.txt` and `.call.json`), `native/`, `preview/`, `rejected/`,
`contract.json` (with `joins`), `checks.json`, `build.py`, `index.html` and
`review-log.txt` (contract section 9); after approval `APPROVAL.json` and
`CLAUDE-A043-PROMPT.txt` (mapping modules to `sprites/buildings/modules/`, joins
and wrecks to `sprites/buildings/`, stating that Claude composes the joins with
the importer's `compose` recipe). Last step, only after the owner approves in
words recorded verbatim in `APPROVAL.json`:
`python implementation/backlog/assets.py set A043 approved`.
