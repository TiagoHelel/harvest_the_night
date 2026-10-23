# A008 - The farmer chopping, mining, collecting, carrying

- **Status:** blocked - Owner deferred all farmer sprites until later, one at a time. Await an explicit request; no generation or integration now.
- **For game task:** 0124
- **Family:** farmer
- **Mode:** B - finished native pixel art (`exact-source`), the approved blue 32px farmer's colours
- **Size of the job:** 4 verbs x 3 directions x 4 frames = 48 native frames, plus the same 48 as exact 2x runtime copies

## What it is for

Chopping and mining are what a first day is made of, and they still play the older,
stockier 48x48 farmer next to the blue 32px walk. These strips are the same blue
farmer swinging an axe at a tree, a pickaxe at a rock or ore, picking something up
from the ground, and lifting a crate when a nearby station finishes - facing south,
north and west (east is the game's mirror of west). At 1080p the body is the walk's
body (~128 physical px), the swing reads at 1x, and on the contact frame the axe meets
the trunk and the pick meets the rock on the faced cell, by day and at night.

## Deliverables

| Runtime name | Native canvas | Pivot | Frames / seconds / loop | Notes |
|---|---|---|---|---|
| `chop_<dir>_0..3` | 48x48 | (24,44) | 4 / 0.09 / one-shot | Axe. 0 axe raised over the shoulder, weight back (held); 1 axe edge at the trunk (`contact_xy`); 2 recoil, axe pulled out a little; 3 axe lowered at the side, close to idle. |
| `mine_<dir>_0..3` | 48x48 | (24,44) | 4 / 0.09 / one-shot | Pickaxe. 0 pick raised high (held); 1 pick point at the rock, low (`contact_xy`); 2 rebound, pick lifted 3-4 px; 3 pick lowered, close to idle. |
| `collect_<dir>_0..3` | 48x48 | (24,44) | 4 / 0.09 / one-shot | Hands only - a generic pick-up from the ground (bones, stones, a dig spot). 0 crouch, hand reaching to the faced cell (held); 1 hand closes at the ground; 2 rising, closed fist at the chest; 3 standing, close to idle. No item drawn. |
| `carry_<dir>_0..3` | 48x48 | (24,44) | 4 / 0.09 / plays 0,1,2,3 | A small closed wooden crate (about 8x6 px, `wood` ramp, no contents shown). 0 crouch, hands on the crate at the boots; 1 lifting; 2 crate held at the chest; 3 the same hold, 1 px bounce. |

`<dir>` is `south`, `north` and `west` (12 animations). The runtime pack of every
row is 96x96 / pivot (48,88), `draw_scale` 0.5, every native pixel a 2x2 block.

Rules for every row:

- **Directions and files.** South, north and west are authored. East is the runtime
  mirror of west and is never delivered: `mirror: "runtime"`, `mirror_pairs: {}`.
  Files `native/<verb>/<dir>/01..04.png` and `runtime/<verb>/<dir>/01..04.png`,
  `01.png` = frame 0. Claude writes `sprites/actors/<verb>_<dir>_<i>.png`.
- **How the game plays a strip** (`src/ui/player_work.gd`): for chop, mine and
  collect, frame 0 is held for the whole swing timer (a tree takes several swings
  while the key is held, each one 0 held -> 1, 2, 3 at 0.09 s); then idle. `carry` is
  a view cue (`PlayerArt.COSMETIC`) played once 0, 1, 2, 3 when a station delivers.
  So frame 0 of chop/mine/collect is a stable wind-up, and frame 3 sits within 2 px
  of the idle silhouette (carry's frame 3 holds the crate).
- **The same body as the walk.** Same identity, scale and camera as
  `walk-final-mirrored` and the grounded idle: straw hat with the brown band, dark
  red-brown hair, white shirt, blue overalls, brown boots, ~16 px wide and 32 rows
  tall standing. Upright frames: hat top on row 12, boots on row 43 (+-1). Head+hat
  block within +-1 px of `idle_<dir>`.
- **Grounded.** Boots on row 43 in every frame, never sliding (each boot's x span
  equal +-1 across the strip). Outside `tool_rects_xywh` the lowest opaque row is 43
  and the body is centred on x=24 (+-1). Only a south tool head may reach rows 44-47.
  The raised axe and pick stay inside the canvas (rows >= 0, columns 0..47).
- **Contact targets** (frame 1; the farmer's own cell is x 16..31, rows 28..43; the
  faced tree or rock stands on the neighbouring cell with its base on that cell's
  bottom edge): west - axe edge on the trunk at x 8..14, rows 30..38; pick point on
  the rock at x 4..14, rows 34..42; collect hand at x 4..14, rows 38..43. South - in
  front of the boots, x 16..31, rows 40..47. North - striking away from the viewer,
  the head above or beside the hat at x 16..31, rows 4..27, partly hidden by the hat
  and back (never below the boots). `contact_xy` (chop, mine) = the opaque edge/point
  pixel of the head on frame 1; code may place its existing impact effect there.
- **Tool head ramp** (decision: tools are tinted per tier by code, never redrawn).
  The axe head and the pickaxe head use exactly three reserved colours: `stone_dark`
  #52505c (underside), `stone` #6e6c78 (body), `stone_light` #8c8a96 (top plane). No
  other pixel in the pack uses them (the walk and idle use none of the 42 project
  colours, measured). build.py may assign them only inside each frame's
  `tool_rects_xywh` (1-3 rectangles holding tool-head pixels and no body pixel,
  recorded in that file's recipe) and removes them from the palette everywhere else.
  Draw the heads as plain untinted steel; game task 0173 tints them to A019's
  basic/iron/gold. Handles and the crate are the `wood` ramp, untinted. Collect and
  carry have no reserved pixels.
- **Never baked:** the tree, rock, ore, chips, sparks, dust, the picked-up item,
  shadow, glow, night tint, text (contract sections 2.3 and 4).

## Match these

- `implementation/fhd-player/pilots/2026-10-06/walk-final-mirrored/native-40/walk/<down,up,left>/01..08.png`
  (40x40, pivot (20,36), visible ~16x32): identity, scale, outline, garment.
  down=south, up=north, left=west.
- `sprites/actors/idle_<south,north,west>_0.png` (80x80 exact 2x blocks; NEAREST to
  40x40 = native idle); full detail for ImageGen:
  `assets/art_source/player-fhd/idle-blue-grounded/frames/<down,up,left>.png`.
- `implementation/fhd-player/pilots/2026-10-04/palette-variants/validation.json`
  (`variants.blue`): the 12 garment colours.
- `sprites/actors/{chop,mine,collect,carry}_0..3.png` (legacy 48x48): the meaning of
  each frame. Copy the gesture, never the drawing.
- `assets/art_source/player-fhd/directional/frames/<verb>_<south,north,west>_0..3.png`
  (128x128, 60 px body, older identity): pose reference only. The north revisions
  `chop_north-r1.png` and `mine_north-r1.png` in `.../directional/` show the accepted
  idea for north: strike away from the viewer, partly hidden by the hat.
- Preview targets (never drawn into a strip): `sprites/props/tree.png` (40x48, pivot
  (20,44)), `rock.png`, `ore.png`, `seam.png` (16x16, pivot (8,14)).
- A007's delivery (`implementation/backlog/deliveries/A007-farmer-field-work/`), if it
  is `approved`: the strips to match for style, tool steel and frame rhythm.

## How to make it

1. **Candidates first (no generation).** Build `preview/candidates.png`: each FHD
   candidate strip NEAREST-scaled by 32/60 beside the approved walk and idle of the
   same direction. They are an older identity (bigger head and hat, brown hair, navy
   `cloth` overalls that fail the 12-colour garment rule). Ask owner question 1.
   Default (and the answer if none comes): regenerate every strip in the blue
   identity with the candidates as pose references. A kept candidate is exported
   from its raw sheet (`assets/art_source/player-fhd/directional/<verb>.png`, record
   in `implementation/fhd-player/directional/prompts/`, copied into `raw/`) with the
   same recipe.
2. **Prompt:** contract section 8 - BASE + PLAYER_WORK (+ STRIP, + CORRECTION),
   canvas 48x48, contact pivot (24,44), the row's ordered poses, and: "The approved
   blue 32px farmer, exactly the attached identity: same body size, hat, hair, face,
   white shirt, blue overalls, brown boots. Boots planted on one ground line in every
   cell. The axe or pick head is plain flat grey steel with a light top edge; the
   handle is warm wood. No tree, rock, chips, sparks or shadow." For carry: "a small
   closed plain wooden crate, nothing inside it visible".
3. **Inputs** (`transparent_background=true`, one subject per call): Image 1 the 8
   walk frames of that direction enlarged x6 NEAREST (identity master); Image 2 the
   full-detail idle of that direction (identity); Image 3 the legacy strip (pose
   reference, older identity); after the first accepted strip, that strip (style and
   scale reference); if A007 is approved, its `till` strip of the same direction
   (tool-steel reference).
4. **Order:** `chop/west` first; reduce and check it beside the walk and a tree on
   the neighbouring cell before anything else. Then mine, collect, carry west; then
   south; then north. One 4-cell STRIP call per verb and direction.
5. **Export (mode B):** measured cell boxes; one `content_scale` per strip, chosen so
   the upright frame is 32 rows tall and the hat brim matches the idle; anchor = the
   boots' bottom centre on (24,44). Alpha >= 128 -> 255, else 0. Garment pixels
   (`b > 1.15*r and b > 1.10*g and b >= 6`, as in
   `implementation/fhd-player/pilots/2026-10-06/walk-up-right-low-step/export_individual.py`)
   -> nearest of the 12 blue colours; the reserved ramp only inside
   `tool_rects_xywh`; every other opaque pixel -> nearest of (all RGB in the 64
   approved walk native frames + the 42 `COLOURS`) minus the reserved ramp. Runtime =
   native x2 NEAREST.
6. **Single-frame fixes:** the guide method that finished the approved walk - the
   native frame enlarged x10 NEAREST to 480x480 as the edit target, one CORRECTION,
   the whole return NEAREST-resized to 48x48, the same colour step. At most 3
   revisions per strip.
7. If reduction loses the face, the axe edge or the pick's points, regenerate. Never
   patch native pixels.

## Review with the owner

The page (contract 9.5) shows, for each of the 12 strips: 1x and 4x; played as the
game does (frame 0 held 0.4 s, then 1-3 at 0.09 s, twice in a row for chop and mine,
then the idle frame; carry 0-3 once) and as a still strip; east as a flip of west,
labelled "runtime mirror, preview only"; beside the walk and idle on one ground line;
an onion skin over the idle; frame 1 over a 16 px grid on tiled grass with
`tree.png` (chop), `rock.png` and `ore.png` (mine) on the faced cell, preview only;
the reserved tool pixels in magenta and `contact_xy` on an overlay; the night preview;
and `preview/candidates.png`.

Ask the owner:

1. (before generating) "Os candidatos antigos (machado, picareta, coletar, carregar) são o fazendeiro de cabeça grande e macacão azul-marinho. Posso usá-los só como referência de pose e gerar tudo de novo no corpo azul de 32px?"
2. "No quadro de contato o machado acerta o tronco e a picareta acerta a pedra, nas três direções?"
3. "Coletar sem desenhar o item (só a mão fechando) e carregar com um caixote simples - está bom assim?"

## Acceptance

- [ ] 48 native frames (4 verbs x south/north/west x 4), each 48x48 pivot (24,44); 48 runtime frames, each exactly native x2 NEAREST (96x96, pivot (48,88)); no east files.
- [ ] Boots on row 43 and not sliding; lowest body row 43 and body centred on x=24 (+-1) outside the tool rects; upright frames 32 rows; head+hat within +-1 px of the idle.
- [ ] Frame 0 of chop/mine/collect is a stable wind-up; frame 3 within 2 px of the idle (carry holds the crate).
- [ ] `contact_xy` on an opaque head pixel of frame 1 of every chop and mine strip, inside its direction's zone; the preview shows the axe on the trunk and the pick on the rock.
- [ ] `tool_ramp_reserved`: the three stone colours only inside `tool_rects_xywh`, on the axe and pick heads, at least 4 pixels per frame where a head shows; none in collect or carry.
- [ ] Binary alpha, true transparency; no tree, rock, item, chips, sparks, shadow, glow, night or text.
- [ ] `colours_allowed`: garment only in the 12 blue colours; every RGB in `colour_ramp` with a role.
- [ ] Reads at 1x by day and at night; the same person as the walk.
- [ ] `build.py` twice gives identical bytes, `--check` passes, checks.json all `true`.

## Delivery

`implementation/backlog/deliveries/A008-farmer-gather-work/` with the files of contract
9.1: `raw/` (+ `.prompt.txt`, `.call.json`), `native/<verb>/<dir>/01..04.png`,
`runtime/<verb>/<dir>/01..04.png`, `preview/`, `rejected/`, `contract.json`
(`palette_mode` "B", `palette` "exact-source", `colour_ramp`, `tool_ramp`
`["#52505c","#6e6c78","#8c8a96"]`, per file `tool_rects_xywh` in the recipe and
`contact_xy` in `points`, native and runtime x2), `checks.json` (plus
`tool_ramp_reserved`), `build.py`, `index.html`, `review-log.txt`. After the owner
approves in words: `APPROVAL.json`, `CLAUDE-A008-PROMPT.txt` (mapping e.g.
`runtime/chop/west/01..04.png -> sprites/actors/chop_west_0..3.png  96x96 pivot (48,88) draw 0.5 detail_wh [48,48]  0.09 s one-shot`;
it replaces the legacy `chop_*`, `mine_*`, `collect_*`, `carry_*` 48x48 strips and
0120's placeholder entries for game task 0124, and names the tool ramp for 0173),
then `python implementation/backlog/assets.py set A008 approved`.
