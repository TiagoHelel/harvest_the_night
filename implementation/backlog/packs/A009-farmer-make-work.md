# A009 - The farmer crafting, trading, repairing

- **Status:** blocked - Owner deferred all farmer sprites until later, one at a time. Await an explicit request; no generation or integration now.
- **For game task:** 0125
- **Family:** farmer
- **Mode:** B - finished native pixel art (`exact-source`), the approved blue 32px farmer's colours
- **Size of the job:** 3 verbs x 3 directions x 4 frames = 36 native frames, plus the same 36 as exact 2x runtime copies

## What it is for

The last three legacy work strips: the farmer working at a station (workshop,
kitchen, press, generator and later the artisan machines), opening the stall to
trade, and mending with a hammer. In 1.0 repair is a day job - the house, the barns
and the stations, mended by the farmer while defences are mended by the cursor at
night. The player sees these beside buildings, facing south, north and west (east is
the game's mirror of west). At 1080p the body is the walk's body (~128 physical px),
the gesture reads at 1x against a building, and the hammer meets the faced wall on
the contact frame, by day and after the night relight.

## Deliverables

| Runtime name | Native canvas | Pivot | Frames / seconds / loop | Notes |
|---|---|---|---|---|
| `craft_<dir>_0..3` | 48x48 | (24,44) | 4 / 0.09 / one-shot | Hands only, working at bench height in front of him. 0 both hands forward at waist height, fingers on the work (held); 1 a firm press or twist, shoulders down 1 px; 2 hands pull back with a small lift; 3 hands lowering, close to idle. No bench, tool, food or product drawn. |
| `trade_<dir>_0..3` | 48x48 | (24,44) | 4 / 0.09 / plays 1,2,3,0 | Hands only, at a counter. 0 standing ready, near hand raised to the chest (also the final pose); 1 leans in 1 px, near hand reaching forward at chest height, palm up; 2 small open-hand gesture; 3 hand coming back. No coin, bag or goods. |
| `repair_<dir>_0..3` | 48x48 | (24,44) | 4 / 0.09 / one-shot | Hammer. 0 hammer raised beside the head (held); 1 hammer head on the faced wall at chest height (`contact_xy`); 2 rebound, hammer lifted 3-4 px; 3 hammer lowered at the side, close to idle. No nails, planks, sparks or dust. |

`<dir>` is `south`, `north` and `west` (9 animations). The runtime pack of every row
is 96x96 / pivot (48,88), `draw_scale` 0.5, every native pixel a 2x2 block.

Rules for every row:

- **Directions and files.** South, north and west are authored. East is the runtime
  mirror of west and is never delivered: `mirror: "runtime"`, `mirror_pairs: {}`.
  Files `native/<verb>/<dir>/01..04.png` and `runtime/<verb>/<dir>/01..04.png`,
  `01.png` = frame 0. Claude writes `sprites/actors/<verb>_<dir>_<i>.png`.
- **How the game plays a strip** (`src/ui/player_work.gd`): craft and repair hold
  frame 0 for the work timer, then play 1, 2, 3 at 0.09 s. Repair repeats while the
  key is held and may restart every few ticks, so frames 1-3 must read even when cut
  short. Trade is instant and plays 1, 2, 3, 0 as the stall panel opens. So frame 0
  is a stable hold, and frame 3 sits within 2 px of the idle silhouette.
- **The same body as the walk.** Same identity, scale and camera as
  `walk-final-mirrored` and the grounded idle: straw hat with the brown band, dark
  red-brown hair, white shirt, blue overalls, brown boots, ~16 px wide, 32 rows tall.
  Upright frames: hat top on row 12, boots on row 43 (+-1). Head+hat block within
  +-1 px of `idle_<dir>`.
- **Grounded.** Boots on row 43 in every frame, never sliding (each boot's x span
  equal +-1). Outside `tool_rects_xywh` the lowest opaque row is 43 and the body is
  centred on x=24 (+-1). Everything inside the canvas.
- **Contact targets** (frame 1; the farmer's own cell is x 16..31, rows 28..43; the
  faced building's wall rises from the neighbouring cell): west - hammer head at
  x 6..15, rows 22..34; south - in front at chest-to-waist height, x 16..31,
  rows 30..42; north - up and away against the wall behind the hat, x 16..31,
  rows 4..18. Craft and trade hands reach the same zones at waist height (west
  x 8..15, rows 26..34). `contact_xy` (repair only) = an opaque pixel of the hammer
  face on frame 1; code may place its existing impact effect there.
- **Tool head ramp.** The hammer head uses exactly three reserved colours:
  `stone_dark` #52505c, `stone` #6e6c78, `stone_light` #8c8a96 - the same ramp as the
  hoe, can, axe and pickaxe of A007/A008, so 0173's tint code treats every farmer tool
  alike (the hammer has no tiers today and is drawn untinted). No other pixel in the
  pack uses these colours; build.py assigns them only inside each frame's
  `tool_rects_xywh` (1-3 rectangles holding head pixels and no body pixel, recorded in
  the recipe) and removes them everywhere else. The handle is the `wood` ramp.
  Craft and trade have no reserved pixels.
- **Never baked:** the station, stall, counter, wall, items, coins, sparks, dust,
  shadow, glow, night tint, text.

## Match these

- `implementation/fhd-player/pilots/2026-10-06/walk-final-mirrored/native-40/walk/<down,up,left>/01..08.png`
  (40x40, pivot (20,36), visible ~16x32): identity, scale, outline, garment.
  down=south, up=north, left=west.
- `sprites/actors/idle_<south,north,west>_0.png` (80x80, exact 2x blocks; NEAREST to
  40x40 = native idle); full detail:
  `assets/art_source/player-fhd/idle-blue-grounded/frames/<down,up,left>.png`.
- `implementation/fhd-player/pilots/2026-10-04/palette-variants/validation.json`
  (`variants.blue`): the 12 garment colours.
- `sprites/actors/{craft,trade,repair}_0..3.png` (legacy 48x48): the meaning of each
  frame. Copy the gesture, never the drawing.
- `assets/art_source/player-fhd/directional/frames/<verb>_<south,north,west>_0..3.png`
  (128x128, 60 px body, older identity): pose reference only;
  `assets/art_source/player-fhd/directional/repair_west-r1.png` shows the accepted
  idea of the hammer striking ahead to the left.
- Preview targets (never drawn into a strip): `sprites/buildings/workshop.png`
  (48x48, pivot (24,44), drawn at 2.0 by the game), `sprites/props/shop.png` (32x40,
  pivot (16,36), drawn at 2.0), `sprites/buildings/house.png` (64x64, pivot (32,60),
  drawn at 2.0).
- A007 and A008 deliveries under `implementation/backlog/deliveries/`, if
  `approved`: the strips to match for style, steel and frame rhythm.

## How to make it

1. **Candidates first (no generation).** Build `preview/candidates.png`: each FHD
   candidate strip NEAREST-scaled by 32/60 beside the approved walk and idle of the
   same direction (older identity: bigger head and hat, brown hair, navy `cloth`
   overalls outside the 12-colour ramp). Ask owner question 1. Default (and the
   answer if none comes): regenerate every strip in the blue identity with the
   candidates as pose references. A kept candidate is exported from its raw sheet
   (`assets/art_source/player-fhd/directional/<verb>.png`, record in
   `implementation/fhd-player/directional/prompts/`, copied into `raw/`) with the same
   recipe.
2. **Prompt:** contract section 8 - BASE + PLAYER_WORK (+ STRIP, + CORRECTION),
   canvas 48x48, contact pivot (24,44), the row's ordered poses, and: "The approved
   blue 32px farmer, exactly the attached identity: same body size, hat, hair, face,
   white shirt, blue overalls, brown boots. Boots planted on one ground line in every
   cell. Nothing in front of him: no bench, counter, wall, item, coin or shadow."
   For repair: "a small claw hammer, plain flat grey steel head, wood handle".
3. **Inputs** (`transparent_background=true`, one subject per call): Image 1 the 8
   walk frames of that direction enlarged x6 NEAREST (identity master); Image 2 the
   full-detail idle of that direction (identity); Image 3 the legacy strip (pose
   reference, older identity); after the first accepted strip, that strip (style and
   scale reference); if A008 is approved, its `chop` strip of the same direction
   (tool-steel reference).
4. **Order:** `repair/west` first; reduce and check it beside the walk before
   anything else. Then craft and trade west; then south; then north. One 4-cell
   STRIP call per verb and direction.
5. **Export (mode B):** measured cell boxes; one `content_scale` per strip, chosen so
   the upright frame is 32 rows tall and the hat brim matches the idle; anchor = the
   boots' bottom centre on (24,44). Alpha >= 128 -> 255, else 0. Garment pixels
   (`b > 1.15*r and b > 1.10*g and b >= 6`, as in
   `implementation/fhd-player/pilots/2026-10-06/walk-up-right-low-step/export_individual.py`)
   -> nearest of the 12 blue colours; the reserved ramp only inside
   `tool_rects_xywh`; every other opaque pixel -> nearest of (all RGB in the 64
   approved walk native frames + the 42 `COLOURS`) minus the reserved ramp. Runtime =
   native x2 NEAREST.
6. **Single-frame fixes:** the guide method - the native frame enlarged x10 NEAREST
   to 480x480 as the edit target, one CORRECTION, the whole return NEAREST-resized to
   48x48, the same colour step. At most 3 revisions per strip.
7. If reduction loses the face, the hands or the hammer head, regenerate. Never patch
   native pixels.

## Review with the owner

The page (contract 9.5) shows, for each of the 9 strips: 1x and 4x; played as the game
does (craft and repair: frame 0 held 0.33 s, then 1-3 at 0.09 s, repair three times
in a row; trade 1, 2, 3, 0) and as a still strip; east as a flip of west, labelled
"runtime mirror, preview only"; beside the walk and idle on one ground line; an onion
skin over the idle; frame 1 over a 16 px grid with the workshop (craft), the stall
(trade) and the house wall (repair) on the faced cell at the game's 2.0 draw scale,
preview only; the hammer's reserved pixels in magenta and `contact_xy` on an overlay;
the night preview; and `preview/candidates.png`.

Ask the owner:

1. (before generating) "Os candidatos antigos de produzir, negociar e consertar são o fazendeiro de cabeça grande. Posso usá-los só como referência de pose e gerar tudo de novo no corpo azul de 32px?"
2. "Produzir e negociar só com gestos de mão (sem bancada, moeda ou mercadoria) - lê bem ao lado da oficina e da banca?"
3. "O martelo acerta a parede da casa no quadro de contato, inclusive de costas (norte)?"

## Acceptance

- [ ] 36 native frames (3 verbs x south/north/west x 4), each 48x48 pivot (24,44); 36 runtime frames, each exactly native x2 NEAREST (96x96, pivot (48,88)); no east files.
- [ ] Boots on row 43 and not sliding; lowest body row 43 and body centred on x=24 (+-1) outside the tool rects; upright frames 32 rows; head+hat within +-1 px of the idle.
- [ ] Frame 0 of craft/repair is a stable hold; trade's frame 0 works as the final pose; frame 3 within 2 px of the idle.
- [ ] `contact_xy` on an opaque hammer-face pixel of frame 1 of every repair strip, inside its direction's zone.
- [ ] `tool_ramp_reserved`: the three stone colours only inside `tool_rects_xywh`, on the hammer head, at least 4 pixels per repair frame where the head shows; none in craft or trade.
- [ ] Binary alpha, true transparency; no station, counter, wall, item, coin, sparks, shadow, glow, night or text.
- [ ] `colours_allowed`: garment only in the 12 blue colours; every RGB in `colour_ramp` with a role.
- [ ] Reads at 1x by day and at night; the same person as the walk.
- [ ] `build.py` twice gives identical bytes, `--check` passes, checks.json all `true`.

## Delivery

`implementation/backlog/deliveries/A009-farmer-make-work/` with the files of contract
9.1: `raw/` (+ `.prompt.txt`, `.call.json`), `native/<verb>/<dir>/01..04.png`,
`runtime/<verb>/<dir>/01..04.png`, `preview/`, `rejected/`, `contract.json`
(`palette_mode` "B", `palette` "exact-source", `colour_ramp`, `tool_ramp`
`["#52505c","#6e6c78","#8c8a96"]`, per file `tool_rects_xywh` in the recipe and
`contact_xy` in `points`, native and runtime x2), `checks.json` (plus
`tool_ramp_reserved`), `build.py`, `index.html`, `review-log.txt`. After the owner
approves in words: `APPROVAL.json`, `CLAUDE-A009-PROMPT.txt` (mapping e.g.
`runtime/repair/west/01..04.png -> sprites/actors/repair_west_0..3.png  96x96 pivot (48,88) draw 0.5 detail_wh [48,48]  0.09 s one-shot`;
it replaces the legacy `craft_*`, `trade_*`, `repair_*` 48x48 strips and 0120's
placeholder entries for game task 0125), then
`python implementation/backlog/assets.py set A009 approved`.
