# A040 - The garlic braid

- **Status:** todo
- **For game task:** 0239
- **Dressed by game tasks:** 0228
- **Spec after game task:** 0228
- **Family:** defences
- **Mode:** A - raw ImageGen sources, Claude reduces them to the 42-colour palette
- **Size of the job:** 3 still sprites

## What it is for

The garlic braid (`garlic_braid`, never `garlic`, which is the crop) is a braid
of garlic bulbs hung on a short post: zombies walk round the ground near it, and
the ones that come through are slowed (the area is code). It wears out over the
nights - fresh the first night, wilted the second, spent after - and the player
must see that wear at a glance, at 1x, by day and after the night relight.
Zombies walk over its cell (it is not a wall), so it is small and low: about the
barricade's height, half the farmer's.

## Deliverables

The table is provisional: game task 0228 settles the final canvas/footprint/states and updates it; start only when `python implementation/backlog/assets.py next` offers this pack.

| Runtime name | Native canvas | Pivot | Frames / seconds / loop | Notes |
|---|---|---|---|---|
| `buildings/garlic_braid` | 16x24 | (8,20) | 1 / static (0.55, loop false) | Fresh. A short wooden stake with a small crosspiece; a braid of 5-7 plump bone-white bulbs with faint violet streaks, dried gold stems plaited, hanging from the crosspiece. Visible about 10-12 wide x 17-19 tall, x 2..13, lowest opaque row 19, stake centred on x 8. |
| `buildings/garlic_braid_wilted` | 16x24 | (8,20) | 1 / static | The same stake. 4-5 bulbs, shrunken and dulled toward brown-grey, braid sagging lower, a stem or two hanging loose. Its alpha shape differs from fresh. |
| `buildings/garlic_braid_spent` | 16x24 | (8,20) | 1 / static | The same stake. A bare braid of dry brown stems with at most 2 shrivelled bulbs; clearly "used up", not "broken". |

- Every row: dir `none`, `mirror: "none"`, draw scale 1.0, no metadata points
  (the repelling area and any scent wisps are code).
- No `_hurt` or `_wreck`: the braid is walkable and nothing bites it. If 0228
  decides that a spent braid disappears, `garlic_braid_spent` is still delivered
  (it is what the player sees on the last night).
- The three states share one `content_scale` (one raw sheet) and the same stake:
  same x (±0), same top row (±1), lowest row 19.
- Delivery paths: `native/garlic_braid/none/01.png`,
  `native/garlic_braid_wilted/none/01.png`, `native/garlic_braid_spent/none/01.png`
  (3 files).

## Match these

- `sprites/buildings/barricade.png`, `barricade_hurt.png`, `barricade_wreck.png`
  (16x24, pivot (8,20), lowest row 19, visible 14x9) and raw
  `assets/art_source/defences/barricade/states.png` - the same canvas and pivot,
  and the "three states in one row from one raw" layout. Open them at 4x.
- `sprites/buildings/fence.png` (16x32) - the timber of the stake.
- The garlic crop of pack A015 if it is approved by then (match its bulb
  colours); otherwise `bone`/`bone_dark` bulbs with `stone_light` or
  `roof_light` streaks and `gold`/`gold_light` stems.
- The 32 px farmer frame `implementation/fhd-player/pilots/2026-10-06/walk-final-mirrored/native-40/walk/down/01.png`.
- `docs/reference-sheet.png` - warm timber, crops and the night panel.

## How to make it

1. Prompt = BASE + WALL_TRAP (from `implementation/sprites/generation/PROMPTS.md`)
   with "garlic braid on a short stake" in place of the barrier list and the
   states fresh/wilted/spent in place of whole/hurt/wreck.
   `transparent_background=true` on every call. Attach `docs/reference-sheet.png`
   (style) and `sprites/buildings/barricade.png` (canvas, scale and family) and
   say each role.
2. **Master** (1 call, at most 2 fresh candidates): the fresh braid, one object.
   Bulbs large and few rather than many and tiny: each bulb must survive as a
   2-3 px pale cluster at native size.
3. **State sheet** (1 call, master attached as identity master and edit target):
   three cells in one row with wide transparent gutters - FRESH, WILTED, SPENT -
   the stake identical and on one baseline in every cell. Model the layout on
   `implementation/sprites/generation/0014-barricade-states.prompt.txt`.
4. Export with the mode A recipe (contract section 3, `render_source` imported
   read-only): one `content_scale` for the three, `content_anchor_xy` = (stake
   centre in scaled px, scaled height) so the lowest opaque row is 19 and the
   stake sits on x 8; `alpha_threshold` 128; `palette_keys` null. If the bulbs
   lose their pale clusters or turn blue, regenerate rather than patch.

## Review with the owner

The page (contract 9.5) shows the three states side by side at 1x and 4x, day
and night preview, over grass, light, dark and checker; beside
`sprites/buildings/barricade.png`, a walker (`sprites/enemies/walker_walk_0.png`)
and the farmer frame on one ground line over a 16 px grid; and a row of three
braids on tiled grass as the player meets them on nights 1, 2 and 3.

Ask the owner:

1. "Dá para ver a diferença entre fresca, murcha e gasta a 1x, também na prévia noturna?"
2. "A réstia de alho no poste está do tamanho certo ao lado do fazendeiro e da barricada?"

## Acceptance

- [ ] 3 files, 16x24, pivot (8,20); `01.png` is the only frame of each.
- [ ] Lowest opaque row 19; stake centred on x 8 (±1) and identical in place in
      all three; bbox inside the canvas with 1 px clear.
- [ ] One raw, one `content_scale`; the three states differ in alpha shape, not
      only in tint.
- [ ] Bulbs read as garlic (pale clusters) at 1x; wilted and spent are clearly
      fewer and duller; spent does not read as a wreck.
- [ ] Binary alpha, true transparent raw, only the 42 colours, recipe matches,
      build twice identical; no shadow, ground, glow, aura, night version or text.

## Delivery

Folder `implementation/backlog/deliveries/A040-garlic-braid/` with `raw/` (each
return plus `.prompt.txt` and `.call.json`), `native/`, `preview/`, `rejected/`,
`contract.json`, `checks.json`, `build.py`, `index.html` and `review-log.txt`
(contract section 9); after approval `APPROVAL.json` and
`CLAUDE-A040-PROMPT.txt` (mapping each `native/<anim>/none/01.png` to
`sprites/<runtime name>.png`). Last step, only after the owner approves in
words recorded verbatim in `APPROVAL.json`:
`python implementation/backlog/assets.py set A040 approved`.
