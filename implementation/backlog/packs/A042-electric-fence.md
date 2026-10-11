# A042 - The electric fence

- **Status:** todo
- **For game task:** 0241
- **Dressed by game tasks:** 0230
- **Spec after game task:** 0230
- **Family:** defences
- **Mode:** A - raw ImageGen sources, Claude reduces them to the 42-colour palette
- **Size of the job:** 6 barrier modules + 1 wreck (32 joins composed from them), 1 effect of 3 frames

## What it is for

The electric fence (`electric_fence`) is a winter barrier built like the wooden
fence - posts and spans that join their neighbours on all 16 masks - except that
whatever bites it is thrown back stunned. It needs the generator, so it reads as
iron and copper: dark metal posts, white ceramic insulators, taut copper wires.
The zap (`zap`) is a short spark burst the view plays where the stun lands.
Both are seen only at night, so they must read at 1x after the relight, and a
run of electric fence must be told apart from a wooden fence at a glance.

## Deliverables

Final geometry settled by game task 0230. The rows stand as written, with the module geometry below measured on the stand-in the game draws today. **How the game plays them:** an electric fence is one cell, a barrier the zombies' field prices like the wooden fence, and it joins on all 16 masks to its own kind, to the wooden fence and to the wall - a run of wire can carry on a wooden fence or end on a wall, so the mixed seam is a real case, not a curiosity. Whatever bites it stands stunned for two seconds (a boss for a quarter of that; less on a farm short of power, never none); the bite lands all the same. It is `_hurt` below three quarters of its hit points and `_wreck` once it falls, as rubble the morning sweeps. **The zap** plays once, the moment a stun lands, half way from the biter's feet to the cell it bit and 13 px over the ground - the wires' height - on the night cues' layer, above the relight; the stunned one is tinted a cold blue by the view for as long as it stands (no art). Until 0241 the whole family is drawn in code by `ElectricFenceArt` through 0120's road, the 32 masks composed with the recipe below from its three modules exactly as `build.py` will. Start only when `python implementation/backlog/assets.py next` offers this pack.

| Runtime name | Native canvas | Pivot | Frames / seconds / loop | Notes |
|---|---|---|---|---|
| `buildings/modules/electric_fence_post` | 16x32 | (8,28) | 1 / static (0.55) | Dark iron post with a cap and white ceramic insulators, x 6-9, rows 7-19: ink sides, the cap on row 7, the foot on row 19 (it stands on row 20, the cell's centre line, like `fence_post`). **The insulators sit inside the post's ink**, on the wire rows 13 and 17: a white pixel against the winter snow is the snow after the relight, so one on the post's edge vanishes at night. |
| `buildings/modules/electric_fence_horizontal` | 16x32 | (8,28) | 1 / static | East-west span, no end posts: two taut 1 px copper wires on rows 13 and 17, each with an ink row under it (14 and 18), opaque at x 0 and x 15. Those rows are opaque in `fence_horizontal` too, so a mixed run meets the wooden fence on four. Dark wires read against snow; keep them darker than the snow. |
| `buildings/modules/electric_fence_vertical` | 16x32 | (8,28) | 1 / static | North-south run seen from above, the two wires receding along the screen Y axis (not upright poles): x 7 and 9 with ink between, rows 11-27, as `fence_vertical` (x 7-9, rows 11-27). |
| `buildings/modules/electric_fence_{post,horizontal,vertical}_hurt` | 16x32 | (8,28) | 1 each / static | Same scale and placement: a bent post and a cracked insulator; one wire snapped and hanging in each span. Every hurt module's alpha shape differs from its whole one, and the post never covers the whole break. |
| `buildings/electric_fence_wreck` | 16x32 | (8,28) | 1 / static | A low tangle of a fallen post and coiled wire on the cell: visible height at most 8, width at most 14, lowest row 27 (like `fence_wreck` rows 21-27; the stand-in's is x 2-13, rows 21-27). |
| `buildings/electric_fence`, `electric_fence_join_<1..15>` | 16x32 | (8,28) | 1 each / static | **Composed by build.py, not generated**: the 16 whole masks (mask 0 is the post alone), with the contract's recipe (section 2.3: N=1, E=2, S=4, W=8; slices and pastes from the table; order N, W, E, S, post on top). |
| `buildings/electric_fence_hurt`, `electric_fence_join_<1..15>_hurt` | 16x32 | (8,28) | 1 each / static | The same 16 masks from the hurt modules. |
| `effects/zap_0..2` | 12x12 | (6,6) | 3 at 0.065 s, one-shot | A small electric arc burst: jagged 1 px pale-blue/white arcs with 2-3 warm spark specks. Poses `spark` (small), `arc` (largest area), `fade` (a few specks, less than `arc`). Inside the canvas with 1 px clear; no full-frame bloom. Drawn over the relight, so its own colours are what the player sees. |

- Every row: dir `none`, `mirror: "none"`, draw scale 1.0, no metadata points.
- **The stand-in until 0241** (task 0230): `PlaceholderArt` registers the 32
  masks (`connected`, so they join before the art arrives), the wreck and the
  zap as drawn by code (`ElectricFenceArt`). The pack has no icon: the hotbar
  shows the straight run, mask 10, scaled into its 16x16 box.
- One `content_scale` across all six modules and the wreck (contract 2.3).
- No glow, spark or arc is ever baked into a module: the fence is dark metal
  until the zap plays.
- `contract.json` carries `joins` with the exact recipe used; native paths:
  `native/electric_fence_post/none/01.png` ... `native/electric_fence_wreck/none/01.png`,
  `native/electric_fence/none/01.png`, `native/electric_fence_join_<m>/none/01.png`,
  `native/electric_fence_hurt/none/01.png`, `native/electric_fence_join_<m>_hurt/none/01.png`,
  `native/zap/none/01..03.png` (42 files).

## Match these

- `sprites/buildings/modules/fence_post.png`, `fence_horizontal.png`,
  `fence_vertical.png` and their `_hurt` versions - the exact geometry to copy
  (post x 6-9 rows 7-19; span x 0-15 rows 12-19; vertical x 7-9 rows 11-27).
  Open them at 4x.
- `sprites/buildings/fence.png`, `fence_join_1..15.png`, `fence_join_*_hurt.png`,
  `fence_wreck.png` - what the composed joins and the wreck must look like.
- `assets/art_source/defences/fence/whole-r2.png` - the raw module row (post,
  span, vertical, heap) the wooden fence was cut from.
- `implementation/sprites/generation/0014-fence-whole-r2.prompt.txt` - the
  correction that finally made the north-south module a long beam lying along
  the screen Y axis instead of two upright posts. Reuse its wording.
- `sprites/effects/impact_0..2.png`, `muzzle_0..2.png` (12x12) - burst scale.
- `sprites/props/generator.png` - the metal it is powered by.
- The 32 px farmer frame `implementation/fhd-player/pilots/2026-10-06/walk-final-mirrored/native-40/walk/down/01.png`.

## How to make it

1. Prompt = BASE + WALL_TRAP (from `implementation/sprites/generation/PROMPTS.md`)
   with "electric fence: dark iron posts, white ceramic insulators, taut copper
   wires" in place of the barrier list, plus the module paragraph of
   `0014-fence-whole-r2.prompt.txt` (four modules in one row, shared scale,
   proportions: span 16 wide x 8 high, post 5 x 13, north-south run 4 wide x 24
   long, heap 14 x 4). `transparent_background=true` on every call. Attach
   `docs/reference-sheet.png` (style) and `assets/art_source/defences/fence/whole-r2.png`
   (module layout and scale) and say each role.
2. **Whole row** (1 call): POST, HORIZONTAL, VERTICAL, WRECK. The vertical must
   be at least 1.7 times as long as the horizontal span is wide.
3. **Hurt row** (1 call, the accepted whole row attached as edit target): POST,
   HORIZONTAL, VERTICAL with the damage above, same scale.
4. **Zap strip** (1 call, FX section + STRIP N=3).
5. Export with the mode A recipe (contract section 3, `render_source` imported
   read-only): measured crops, one `content_scale` for every module and the
   wreck, `content_anchor_xy` so the post and span stand on row 20 and the
   wreck's lowest row is 27; `alpha_threshold` 128; `palette_keys` null. Then
   build.py composes the 32 masks with the section 2.3 table exactly.

## Review with the owner

The page (contract 9.5) shows the modules and the wreck at 1x and 4x, day and
night preview; all 32 composed masks laid out as real runs - a straight
east-west run, a north-south run, an L corner, a T and a cross, whole and hurt -
over tiled grass; a mixed run with the wooden `fence_join_*` sprites to judge
the seam; the farmer frame and a walker on the same ground line; the zap playing
once at 0.065 s at 1x and 4x over a walker frame.

Ask the owner:

1. "A cerca elétrica se distingue da cerca de madeira a 1x, também na prévia noturna?"
2. "As emendas (cantos, cruzamentos, e lado a lado com a cerca de madeira) ficaram boas?"
3. "O choque está forte demais ou fraco demais?"

## Acceptance

- [ ] 42 files: 6 modules + wreck + 32 composed masks (16x32 / (8,28)) + 3 zap
      frames (12x12 / (6,6)).
- [ ] Post and span stand on row 20 (lowest opaque row 19); span opaque at x 0
      and x 15 on rows within 12-19; vertical content inside rows 8-27.
- [ ] One `content_scale` for all modules and the wreck; wreck at most 8 rows
      tall, lowest row 27.
- [ ] `all_32_masks_composed` true; each mask's arms match its bits (west
      column, east column, above the post top, below row 20); every hurt mask's
      alpha differs from its whole mask by at least 3 pixels; the break stays
      visible under the post.
- [ ] Mixed east-west seams with `fence` share at least 2 opaque rows.
- [ ] Zap: 3 distinct frames, one raw, one scale, unclipped; frame 1 has the
      largest area, frame 2 less than frame 1.
- [ ] Binary alpha, true transparent raws, only the 42 colours, recipe matches,
      build twice identical; no glow, shadow, ground, night version or text.

## Delivery

Folder `implementation/backlog/deliveries/A042-electric-fence/` with `raw/` (each
return plus `.prompt.txt` and `.call.json`), `native/`, `preview/`, `rejected/`,
`contract.json` (with `joins`), `checks.json`, `build.py`, `index.html` and
`review-log.txt` (contract section 9); after approval `APPROVAL.json` and
`CLAUDE-A042-PROMPT.txt` (mapping the modules to `sprites/buildings/modules/`,
the joins and wreck to `sprites/buildings/`, the zap to `sprites/effects/`, and
stating that Claude composes the joins with the importer's `compose` recipe from
the promoted modules). Last step, only after the owner approves in words
recorded verbatim in `APPROVAL.json`:
`python implementation/backlog/assets.py set A042 approved`.
