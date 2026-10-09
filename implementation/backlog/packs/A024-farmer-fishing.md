# A024 - The farmer fishing

- **Status:** todo
- **For game task:** 0207
- **Dressed by game tasks:** 0180
- **Spec after game task:** 0180
- **Family:** farmer
- **Mode:** B - finished native pixel art (`exact-source`), the approved blue 32px farmer's colours
- **Size of the job:** 4 animations x 3 directions (13 frames each) + a 2-frame catch facing south = 41 native frames, plus the same 41 as exact 2x runtime copies

## What it is for

Fishing becomes a sequence in 1.0 (0179-0182): cast into a pond, wait while the
bobber (A023) floats, strike when it bites, reel while the timing bar runs (0180), and
hold the fish up when it lands. Today the farmer plays two legacy strips of the older
30px farmer (`fish_0..3` the cast, `reel_0..3`, 48x48, west only, mirrored and reused
for north and south, `reel_0` held while waiting). This pack is the whole sequence in
the blue 32px body facing south, north and west (east mirrored), with a rod whose
shaft code tints per tier (bamboo, fibre, iron) and a rod-tip point the code's fishing
line starts from. The player watches it for seconds at a time on a bank or the jetty,
by day and into the evening: the body must stay the walk's (~128 physical px) and the
rod tip must hang over the faced water cell.

## Deliverables

The table is provisional: game task 0180 settles the final canvas/footprint/states and updates it; start only when `python implementation/backlog/assets.py next` offers this pack.

| Runtime name | Native canvas | Pivot | Frames / seconds / loop | Notes |
|---|---|---|---|---|
| `fish_cast_<dir>_0..3` | 48x48 | (24,44) | 4 / 0.09 / one-shot | 0 rod drawn back over the shoulder, weight back (held); 1 rod whipping forward overhead; 2 release: arms extended, rod pointing out over the faced cell (the line leaves here); 3 settling into the wait hold = `fish_wait_0` within 1 px. |
| `fish_wait_<dir>_0..1` | 48x48 | (24,44) | 2 / 0.6 / loop | Rod held out over the water in both hands, relaxed. 1 = the same with the rod tip and the hands 1 px lower; nothing else moves. |
| `fish_strike_<dir>_0..2` | 48x48 | (24,44) | 3 / 0.08 / one-shot | The bite: 0 a sharp pull, rod snapped up and back, both hands high; 1 rod bent hard toward the water, leaning back; 2 settling into the reel hold = `fish_reel_0` within 1 px. |
| `fish_reel_<dir>_0..3` | 48x48 | (24,44) | 4 / 0.1 / loop | While the bar runs: rod raised and bent toward the water, front hand on the grip, the other cranking the reel through four positions (top, front, bottom, back); rod tip +-1 px. Body and boots still. |
| `fish_catch_south_0..1` | 48x48 | (24,44) | 2 / 0.3 / one-shot, frame 1 held | Showing the catch, facing the viewer whatever his facing (as Stardew's farmer does): 0 both hands coming up to the chest; 1 both fists together above the hat, holding up the fish the code draws (`catch_xy`). No rod (put away), no fish drawn. |

`<dir>` is `south`, `north` and `west` (12 animations, plus `fish_catch` south only).
The runtime pack of every row is 96x96 / pivot (48,88), `draw_scale` 0.5, every
native pixel a 2x2 block (Claude imports with `detail_wh` [48,48]).

Rules for every row:

- **Directions and files.** East is the runtime mirror of west and is never
  delivered: `mirror: "runtime"`, `mirror_pairs: {}`; `fish_catch` is `mirror:
  "none"`. Files `native/<anim>/<dir>/01..NN.png` and `runtime/<anim>/<dir>/01..NN.png`,
  `01.png` = frame 0. Claude writes `sprites/actors/<anim>_<dir>_<i>.png`.
- **How the game plays it** (confirmed by 0180: a 1 s cast, a wait of 4.7-23 s, a bar of up
  to 10 s, then the catch shown or straight back to idle): the cast plays with the `fish` verb -
  frame 0 held through the work timer, then 1, 2, 3 at 0.09 s; `fish_wait` loops
  while the line is in the water; `fish_strike` plays once at the bite, as the bar
  opens; `fish_reel` loops while the bar runs; a landed fish plays `fish_catch` 0, 1
  and holds 1 while the catch shows (about 1 s), then idle; a lost fish goes straight
  back to idle.
- **The same body as the walk.** Same identity, scale and camera as
  `walk-final-mirrored` and the grounded idle: straw hat with the brown band, dark
  red-brown hair, white shirt, blue overalls, brown boots, ~16 px wide and 32 rows
  tall. Upright frames: hat top on row 12, boots on row 43 (+-1); head+hat block
  within +-1 px of `idle_<dir>`. Leaning back never shrinks or enlarges the head.
- **Grounded.** Boots on row 43 in every frame, never sliding (each boot's x span
  equal +-1 across the sequence). Outside `tool_rects_xywh` the lowest opaque row is
  43 and the body is centred on x=24 (+-1). Only a south rod may reach rows 44-47.
  Everything stays inside the canvas.
- **Rod tip targets** (cast 2-3, wait, strike 1-2, reel; the farmer's own cell is
  x 16..31, rows 28..43): west - the rod rises forward-left over the water, tip at
  x 0..10, rows 10..28; south - held out toward the viewer on the screen-right side,
  foreshortened, tip at x 30..47, rows 34..47; north - pointing away, tip above or
  beside the hat at x 16..36, rows 0..10. Cast 0-1 and strike 0 may point elsewhere,
  inside the canvas.
- **`rod_tip_xy`** (new point, contract section 5): on every frame that shows the rod
  (cast, wait, strike, reel), the outermost opaque pixel of the shaft. Code draws the
  fishing line from it to the bobber's `line_xy` (A023). **`catch_xy`** on both
  `fish_catch` frames: the top-centre opaque pixel of the joined fists (frame 1: fists
  centred on x 24 +-1, above the hat, top row 2..6); code centres the species icon
  (16x16, A022, today `icon_fish`) on it. Both points native and runtime (x2).
- **Rod ramp** (decision: the tool is tinted per tier by code, never redrawn). The
  shaft, from just above the grip to the tip, uses exactly A007's and A008's three
  reserved colours, so 0173's one tint covers every tool: `stone_dark` #52505c
  (underside, only where the shaft is 2 px thick), `stone` #6e6c78 (body), `stone_light`
  #8c8a96 (the lit upper-left pixels). No other pixel in the pack uses them. build.py
  may assign them only inside each frame's `tool_rects_xywh` (1-4 rectangles holding
  shaft pixels and no body pixel - a diagonal rod needs more than a hoe - recorded in
  that file's recipe). The shaft stays 8-connected from grip to tip. The grip is the
  `wood` ramp and the reel `ink_soft` with a `bone_dark` crank knob, both untinted.
  Draw the shaft plain untinted grey; 0173 tints it to bamboo, fibre and iron.
  `fish_catch` has no reserved pixels.
- **Never baked:** the line, bobber, water, ripples, splash, the fish, bait, shadow,
  glow, night tint, text (contract section 4).

## Match these

- `implementation/fhd-player/pilots/2026-10-06/walk-final-mirrored/native-40/walk/<down,up,left>/01..08.png`
  (40x40, pivot (20,36), visible ~16x32): identity, scale, outline and the blue
  garment. Screen words: down=south, up=north, left=west.
- `sprites/actors/idle_<south,north,west>_0.png` (80x80, exact 2x blocks) and the
  full-detail `assets/art_source/player-fhd/idle-blue-grounded/frames/<down,up,left>.png`.
- `implementation/fhd-player/pilots/2026-10-04/palette-variants/validation.json`
  (`variants.blue`, 12 RGB): the only colours a garment pixel may take.
- `sprites/actors/fish_0..3.png` and `reel_0..3.png` (legacy 48x48, west, older 30px
  farmer; the rod reaches about 20 px from the hands): what the cast and the reel
  mean. Copy the gesture, never the drawing.
- `assets/art_source/player-fhd/directional/frames/{fish,reel}_<south,north,west>_0..3.png`
  (128x128, pivot (64,108), 60 px body; raw sheets `directional/fish.png`,
  `reel.png`): older FHD candidates, pose reference only - they already show the
  south and north rod angles.
- A023's bobber (`line_xy` at the antenna top) and, if approved,
  `implementation/backlog/deliveries/A023-fishing-gear/native/bobber_float/none/01.png`;
  if A019 is approved, its rod icons (`native/icon_rod_*`): the same fishing set.
- The work body, if approved: `implementation/backlog/deliveries/A007-farmer-field-work/native/water/<dir>/`.
- Preview targets (never drawn into a strip): `sprites/terrain/water.png`,
  `sprites/terrain/floor.png` (the jetty), `sprites/terrain/grass.png`,
  `sprites/effects/splash_0..3.png`, `sprites/ui/icon_fish.png`.
- `docs/reference-sheet.png` (the PESCAR panel: the farmer on the jetty facing the
  viewer, rod out to the side, line to the water), `assets/art_source/masters/farmer.png`.

## How to make it

1. **Candidates first (no generation).** Build `preview/candidates.png`: the FHD fish
   and reel candidates NEAREST-scaled by 32/60 beside the approved walk and idle of
   the same direction, and the legacy strips at 1x and 4x. They are an older identity
   (bigger head and hat, navy overalls outside the 12-colour ramp). Ask owner question
   1. Default (and the answer if none comes): generate everything fresh in the blue
   identity, using the candidates as pose references.
2. **Prompt:** contract section 8 - BASE + PLAYER_WORK (+ STRIP, + CORRECTION), canvas
   48x48, contact pivot (24,44), the row's ordered poses; replace PLAYER_WORK's "For
   fishing separate cast and reel" with this pack's animations. Add: "The approved
   blue 32px farmer, exactly the attached identity: same body size, hat, hair, face,
   white shirt, blue overalls, brown boots. Boots planted on one ground line in every
   cell. The rod is a long thin plain grey pole with a small dark reel and a warm wood
   grip. No fishing line, no bobber, no water, no fish, no shadow." For `fish_catch`:
   "Facing the viewer, both fists raised together above the hat as if holding up a
   fish; no fish and no rod drawn."
3. **Inputs** (one strip per call, `transparent_background=true`): Image 1 the 8 walk
   frames of that direction enlarged x6 NEAREST (identity master); Image 2 the
   full-detail idle of that direction (identity); Image 3 the FHD candidate of the
   nearest verb and direction (pose reference, older identity: copy the rod angle,
   not the drawing); after the first accepted strip, that strip (style and scale).
4. **Order:** `fish_wait/west` first - reduce it and check the rod angle, the tip zone
   and the shaft ramp beside the walk before anything else. Then cast, strike and
   reel west; then south; then north; `fish_catch` last.
5. **Export (mode B):** measured cell boxes; one `content_scale` per strip, chosen so
   the upright frame measures 32 rows and the hat brim matches the idle's width;
   anchor = the boots' bottom centre, landing on (24,44). Alpha >= 128 -> 255, else 0.
   Garment pixels (`b > 1.15*r and b > 1.10*g and b >= 6`, as in
   `implementation/fhd-player/pilots/2026-10-06/walk-up-right-low-step/export_individual.py`)
   -> nearest of the 12 blue colours; the reserved ramp only inside `tool_rects_xywh`;
   every other opaque pixel -> nearest of (all RGB in the 64 approved walk native
   frames + the 42 `COLOURS`) minus the reserved ramp. Runtime = native x2 NEAREST.
6. **Single-frame fixes** use the guide method that finished the approved walk: the
   native frame enlarged x10 NEAREST to 480x480 as the edit target, CORRECTION text
   naming the one fix, the whole return NEAREST-resized to 48x48, the same colour step.
   At most 3 revisions per strip.
7. If the reduction breaks the shaft into dots or loses the reel, regenerate. Never
   patch native pixels.

## Review with the owner

The page (contract 9.5) shows each strip at 1x and 4x and as a still strip; the whole
sequence per direction played the way the game plays it (cast 0 held 0.5 s, 1-3; wait
looping 2 s; strike; reel looping 2 s; `fish_catch` 0, 1 held 1 s; idle); the east
version as a flip of west labelled "runtime mirror, preview only"; each beside the
walk and idle of that direction on one ground line; a preview scene with the farmer on
`floor.png` (the jetty) and on grass, the faced cell tiled with `water.png`, a 1 px
line drawn from `rod_tip_xy` to a bobber (A023's if approved, else a 5-px red and
white mock) on the faced cell's centre, and on `fish_catch_1` `icon_fish.png` centred
on `catch_xy`; the reserved shaft pixels in magenta on an overlay with `rod_tip_xy`
marked; one row with the shaft recoloured to the `gold` ramp (a preview of a tier
tint only); the night preview; and `preview/candidates.png`.

Ask the owner:

1. (before generating) "Os candidatos antigos de pesca são o fazendeiro de cabeça grande e macacão azul-marinho. Posso usá-los só como referência de pose e gerar a pesca toda no corpo azul de 32px aprovado?"
2. "Em cada direção a ponta da vara fica sobre a água e a linha (desenhada pelo jogo) sai de um ponto que faz sentido?"
3. "Para mostrar o peixe ele sempre se vira para a câmera, como no Stardew. Fica bom assim, ou prefere que ele mostre na direção em que está pescando?"

## Acceptance

- [ ] 41 native frames (`fish_cast` 4, `fish_wait` 2, `fish_strike` 3, `fish_reel` 4 x south/north/west, plus `fish_catch_south` 2), each 48x48 pivot (24,44); 41 runtime frames, each exactly native x2 NEAREST (96x96, pivot (48,88)); no east files.
- [ ] Boots on row 43 and not sliding; lowest body row 43 and body centred on x=24 (+-1) outside the tool rects; upright frames 32 rows tall; head+hat within +-1 px of the idle.
- [ ] `fish_cast_3` matches `fish_wait_0` and `fish_strike_2` matches `fish_reel_0` within 1 px; `fish_wait_0` and `_1` differ only in the rod and hands; the reel loop closes (3 leads to 0).
- [ ] `rod_tip_xy` on an opaque reserved-ramp pixel of every rod frame, inside its direction's zone where the table says; `catch_xy` on an opaque fist pixel above the hat on both catch frames.
- [ ] `tool_ramp_reserved`: the three stone colours only inside `tool_rects_xywh`, on the shaft, at least 6 pixels per rod frame; none in `fish_catch`. `rod_connected`: the shaft is 8-connected from grip to tip.
- [ ] Binary alpha, true transparency; no line, bobber, water, splash, fish, shadow, glow, night or text.
- [ ] `colours_allowed`: garment only in the 12 blue colours; every RGB listed in `colour_ramp` with a role.
- [ ] Reads at 1x by day and at night; the same person as the walk.
- [ ] `build.py` twice gives identical bytes, `--check` passes, checks.json all `true`.

## Delivery

`implementation/backlog/deliveries/A024-farmer-fishing/` with the files of contract
9.1: `raw/` (+ `.prompt.txt`, `.call.json`), `native/<anim>/<dir>/01..NN.png`,
`runtime/<anim>/<dir>/01..NN.png`, `preview/`, `rejected/`, `contract.json`
(`palette_mode` "B", `palette` "exact-source", `colour_ramp`, `tool_ramp`:
`["#52505c","#6e6c78","#8c8a96"]`, `runtime_canvas_wh` [96,96], `runtime_pivot_xy`
[48,88], `detail_wh` [48,48], per file `tool_rects_xywh` in the recipe and `rod_tip_xy`
or `catch_xy` in `points`, native and runtime x2), `checks.json` (plus
`tool_ramp_reserved`, `rod_connected`), `build.py`, `index.html`, `review-log.txt`.
After the owner approves in words: `APPROVAL.json`, `CLAUDE-A024-PROMPT.txt` (mapping
e.g. `runtime/fish_reel/west/01..04.png -> sprites/actors/fish_reel_west_0..3.png  96x96 pivot (48,88) draw 0.5 detail_wh [48,48]  0.1 s loop`;
"east is not delivered: the game flips west"; `fish_catch_south` plays for every
facing; it replaces the legacy `fish_0..3` and `reel_0..3` 48x48 strips for game task
0207 and names the shaft ramp for 0173), then
`python implementation/backlog/assets.py set A024 approved`.
