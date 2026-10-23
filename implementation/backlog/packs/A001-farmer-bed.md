# A001 - Going to bed, sleeping, waking, passing out

- **Status:** blocked - Owner deferred all farmer sprites until later, one at a time. Await an explicit request; no generation or integration now.
- **For game task:** 0143
- **Dressed by game tasks:** 0129
- **Family:** farmer
- **Mode:** B - finished native pixel art (`exact-source`), the approved blue 32px farmer's colours, plus the bed's own colours for the covers
- **Size of the job:** 3 bed strips (10 frames) + pass-out in 3 authored directions x 4 = 22 drawn frames, plus 4 baked mirrors = 26 native frames, plus the same 26 as exact 2x runtime copies

## What it is for

Going to bed is the reality switch (0127), and a farmer still up at 02:00 collapses
where he stands (0128). 0129 shows both with stand-ins (the idle turned or tinted).
This pack is the farmer's night in the approved blue 32px body: getting into the
farmhouse bed (a short interior beat when the switch starts), asleep under the covers
(with A002's Zzz over him), waking and stretching at 06:00 before he steps out into
the day (0138), and the collapse on the farm at 02:00 that ends lying on the ground.
The bed strips are drawn over the existing `sprites/interior/bed.png` and must sit on
it pixel-exactly; the pass-out is seen mostly after the night relight, at 1x, beside
the walk's body (~128 physical px standing). It must read as exhaustion, not death.

## Deliverables

| Runtime name | Native canvas | Pivot | Frames / seconds / loop | Notes |
|---|---|---|---|---|
| `bed_in_0..3` | 40x40 | (20,36) | 4 / 0.2 / one-shot | On the bed (mapping below). 0 sitting up, covers at the waist, facing the viewer, both hands at the hat brim; 1 the hat lifted off and held out to the screen left (toward the nightstand); 2 lying back, hat gone, head dropping to the pillow, one hand pulling the sheet up; 3 lying under the covers, eyes closed = the `bed_sleep_0` pose. |
| `bed_sleep_0..1` | 40x40 | (20,36) | 2 / 0.8 / loop | On his back, face up, head on the pillow, eyes closed, no hat, covers up to the chest. 0 exhale; 1 inhale: only the chest part of the covers 1 row higher. Head and hair pixels identical in both. |
| `bed_wake_0..3` | 40x40 | (20,36) | 4 / 0.25 / one-shot | 0 `bed_sleep_0` with the eyes open; 1 sitting up, covers fallen to the waist, hair ruffled; 2 the stretch: both arms raised in a V, eyes shut, mouth open in a yawn; 3 sitting up, hat back on (as in `bed_in_0`), hands down, ready to step out. |
| `pass_out_<dir>_0..3` | 40x40 | (20,36) | 4 / 0.18 / one-shot | `south`, `north`, `west` authored, `east` baked. 0 swaying where he stands, eyelids heavy, knees soft; 1 knees buckle: kneeling, torso slumped, head drooping; 2 toppling onto his side, one hand reaching for the ground; 3 lying on his side on the ground, eyes closed, hat still on (tipped). The view holds frame 3 until the night's fade. |

The runtime pack of every row is 80x80 / pivot (40,72), `draw_scale` 0.5, every
native pixel a 2x2 block (Claude imports with `detail_wh` [40,40]).

Rules for every row:

- **The bed mapping (exact).** The bed strips have direction `none` and `mirror:
  "none"`. Native pixel (x,y) of every bed frame lies over pixel (x+4, y+3) of
  `sprites/interior/bed.png` (48x64, pivot (24,64)). So the frame's pivot (20,36) sits
  on bed pixel (24,39): **the bed sprite's pivot moved by (0,-25)**. In the room today
  (`GameData.HOUSE_FURNITURE` bed cell (16,3), size (3,3); `HouseView.FURNITURE_OFFSETS`
  bed (0,-4)) the bed's pivot is at room (280,92), so the farmer's pivot is at
  (280,67). The runtime frame at `draw_scale` 0.5 lands on the same logical point.
  The game draws these frames above the bed (y-sorting by this pivot alone would put
  him under it) and hides the contact shadow while he is in bed.
- **The bed in native coordinates** (measured on bed.png, minus (4,3)): headboard
  rows 1..9; pillow x 9..30, rows 10..20; turned-down white sheet x 3..35, rows
  21..26; brown quilt x 2..37 from row 27 to the canvas bottom; side rails x 0..3 and
  36..39. The footboard is below the canvas.
- **Lying frames** (`bed_in_2`, `bed_in_3`, both `bed_sleep`, `bed_wake_0`): every
  opaque pixel inside x 4..35, rows 10..39 (on the mattress, between the rails, below
  the headboard). Hair top on row 11 (+-1), the bare head 10-12 px wide and centred on
  x 19-21 (the pillow's centre); the body under the covers is a soft mound 12-16 px
  wide down the middle of the bed, the feet a 1-2 px bump ending on rows 35..39.
- **Sitting frames** (`bed_in_0`, `bed_in_1`, `bed_wake_1..3`): hips and the folded
  covers on rows 21..27 (over the turned-down sheet), torso upright, hat top on row 3
  (+-1) when the hat is on; nothing above row 0 (the stretch may touch row 0). The
  head+hat block within +-1 px of `idle_south`'s in width and height.
- **The covers are drawn in the frame**, shaped by his body: the turned-down sheet
  over the chest and the quilt over the body and legs. Those pixels sit inside the
  frame's `cover_rects_xywh` (1-3 rectangles holding cover pixels only, recorded in
  its recipe), where build.py maps every pixel to the nearest of the 18 RGB measured
  in bed.png (all 18 are project colours: `bone`, `bone_dark`, `skin_light` sheet;
  `soil`, `soil_dark`, `wood_dark`, `wood` quilt; `ink`, `night` outlines; and the
  rest). Never draw the pillow, headboard, rails, mattress or footboard: they are
  bed.png's and stay underneath.
- **The hat** is off in the lying frames and in `bed_wake_1..2` (it is on the
  nightstand and never drawn), on in `bed_in_0`, `bed_wake_3` and every pass-out frame.
- **Pass-out: the same body as the walk.** Frame 0 is the walk's identity and scale:
  hat top row 4 (+-1), 32 rows tall, head+hat within +-1 px of `idle_<dir>`. Every
  frame touches the ground on row 35 (`pivot_y - 1`: boots, knee, hand or body).
  Frames 0, 1 and 3 are centred on x 20 (+-1); frame 2 may lean up to 6 px. Frame 3
  lies horizontally, 26-31 px long and 7-11 rows tall, head to the left: in `south`
  face toward the viewer, in `north` back toward the viewer, in `west` fallen forward.
- **Mirrors and directions.** `pass_out_east` is an exact whole-canvas flip of
  `pass_out_west`, made by build.py for native and runtime (`mirror: "baked:west"`,
  `mirror_pairs` `{"east": "west"}`); Claude binds it directly and never flips. There
  are no diagonal pass-outs: the rules hold four facings (`PlayerArt.FACINGS`).
- **Files:** `native/<anim>/<dir>/01..NN.png` and `runtime/<anim>/<dir>/01..NN.png`,
  `<dir>` = `none` for the bed strips; `01.png` = frame 0. Claude writes
  `sprites/actors/bed_in_0..3.png`, `bed_sleep_0..1`, `bed_wake_0..3` and
  `pass_out_<dir>_0..3` - the names 0129 registers its stand-ins under.
- **Never baked:** the bed or any part of it, the nightstand, a hat lying anywhere,
  the Zzz (A002), dust, shadow, glow, night tint, text (contract section 4).

## Match these

- `implementation/fhd-player/pilots/2026-10-06/walk-final-mirrored/native-40/walk/<down,up,left>/01..08.png`
  (40x40, pivot (20,36), visible ~16x32, hat top row 4, lowest row 35): identity,
  scale, outline and the blue garment. Screen words: down=south, up=north, left=west.
- `sprites/actors/idle_<south,north,west>_0.png` (80x80, exact 2x blocks; NEAREST to
  40x40 gives the native idle) and the full-detail
  `assets/art_source/player-fhd/idle-blue-grounded/frames/<down,up,left>.png`: the
  standing body of `pass_out_0` and the head of every bed frame.
- `implementation/fhd-player/pilots/2026-10-04/palette-variants/validation.json`
  (`variants.blue`, 12 RGB): the only colours a garment pixel may take.
- `sprites/interior/bed.png` (48x64, pivot (24,64), visible 42x60 from (3,4)): the bed
  every bed frame lies on - open it at 8x. With `sprites/interior/nightstand.png`
  (32x48, pivot (16,48)), `floor.png`, `wall.png`, `src/core/game_data.gd`
  `HOUSE_FURNITURE` and `src/ui/house_view.gd` (`_build_room`, `FURNITURE_OFFSETS`):
  the room the preview composes.
- `sprites/enemies/walker_death_3.png` (64x48, visible 26x10 on rows 34..43): how long
  and low a body lying on the ground reads at native size. Copy the height, not the
  zombie.
- `sprites/actors/shadow.png` (20x8, pivot (10,4)): drawn by the view under the
  pass-out at the pivot; preview only.
- `docs/reference-sheet.png`, `assets/art_source/masters/farmer.png`: look and identity.

## How to make it

1. **No candidates exist** (sleep, bed and pass-out art are missing). Before
   generating, `build.py --guide` writes only `preview/bed-guide.png`: bed.png at 8x
   NEAREST with the 40x40 frame area, the pillow, sheet and quilt zones and the lying
   limits outlined. Ask owner question 1.
2. **Prompt:** contract section 8 - BASE + PLAYER_STRIP (direction, action = the
   animation; its idle/walk lines replaced by this row's ordered poses) + STRIP (N) +
   CORRECTION; canvas 40x40, pivot (20,36). Add: "The approved blue 32px farmer,
   exactly the attached identity: same hat, dark red-brown hair, face, white shirt,
   blue overalls, brown boots, same body size." For the bed strips add: "Lying in the
   attached bed, seen from the game's three-quarter top-down camera, head at the top
   on the pillow and feet toward the viewer. Do not draw the bed: only the farmer and
   the covers over his body, in the bed's own brown quilt and white sheet colours. No
   hat while lying." For the pass-out add: "Exhausted at 2 a.m., he collapses where
   he stands and ends lying on his side on the ground, hat on. Not dead: relaxed
   limbs, a sleeping face. No dust, no Zzz."
3. **Inputs** (`transparent_background=true`, one strip per call): Image 1 the 8 walk
   frames of that direction enlarged x6 NEAREST (identity master and scale); Image 2
   the full-detail idle (identity); for bed strips Image 3 `preview/bed-guide.png`
   (placement reference, never drawn), for the pass-out Image 3 `walker_death_3.png`
   x6 (how low a body lies, never the identity); after the first accepted strip, that
   strip (style and scale reference).
4. **Order:** `bed_sleep` first - composite it on bed.png and ask owner question 2
   before anything else. Then `bed_in` and `bed_wake`, then `pass_out` west, south,
   north.
5. **Export (mode B):** measured cell boxes; one `content_scale` per strip, chosen so
   the head matches `idle_south` (bare face 10-12 px wide, hat brim 16 px). Bed
   strips: anchor = the hair-top centre of the strip's lying frame, landing on
   (20,11), the same cell-relative anchor for every cell. Pass-out: anchor = the boots'
   bottom centre in frame 0, landing on (20,36). Alpha >= 128 -> 255, else 0. Garment
   pixels (`b > 1.15*r and b > 1.10*g and b >= 6`, as in
   `implementation/fhd-player/pilots/2026-10-06/walk-up-right-low-step/export_individual.py`)
   -> nearest of the 12 blue colours; inside `cover_rects_xywh` -> nearest of bed.png's
   18 RGB; every other opaque pixel -> nearest of (all RGB in the 64 approved walk
   native frames + the 42 `COLOURS`). Then the east flip, then runtime = native x2.
6. **Single-frame fixes** use the guide method that finished the approved walk: the
   native frame enlarged x10 NEAREST to 400x400 as the edit target, CORRECTION text
   naming the one fix, the whole return NEAREST-resized to 40x40, the same colour step.
   At most 3 revisions per strip.
7. Never nudge, crop or patch a frame by code to make it fit the bed. A lying frame
   outside the limits is regenerated or corrected.

## Review with the owner

The page (contract 9.5) shows every bed strip composited on bed.png inside the room
crop (room x 208..319, y 0..127: wall, floor, the nightstand to the left, laid out as
`house_view.gd` does), at 1x and 4x, played as the game plays it (`bed_in` then
`bed_sleep` looping; `bed_sleep` then `bed_wake`, then a cut to `idle_south` standing
on the floor cell below the bed), as still strips, and alone over checker with the
lying limits outlined; the pass-out per direction over tiled grass with `shadow.png`
under the pivot, playing then holding frame 3, beside the walk of that direction on
one ground line; the baked east pair side by side; the night preview of all of it;
and `preview/bed-guide.png`.

Ask the owner:

1. (before generating) "Na cama ele fica sem o chapéu (tira ao deitar, põe de volta ao acordar) e coberto até o peito pela colcha da própria cama. Pode ser assim?"
2. (after `bed_sleep`) "Ele parece deitado dentro da cama, com a cabeça no travesseiro e o corpo debaixo da colcha, e não flutuando por cima dela?"
3. "O desmaio lê como cansaço, não como morte, a 1x de dia e na prévia noturna?"

## Acceptance

- [ ] 26 native frames (`bed_in` 4, `bed_sleep` 2, `bed_wake` 4 as `none`; `pass_out` 4 x south/north/west/east), each 40x40 pivot (20,36); 26 runtime frames, each exactly native x2 NEAREST (80x80, pivot (40,72)).
- [ ] `bed_fit`: lying frames inside x 4..35, rows 10..39, hair top row 11 (+-1), head centred on x 19-21; sitting frames with hips on rows 21..27 and hat top row 3 (+-1); no pixel above row 0.
- [ ] `bed_continuity`: `bed_in_3` and `bed_wake_0` match `bed_sleep_0` within 1 px of silhouette; `bed_sleep_0` and `_1` differ only on the chest rows; `bed_wake_3` and `bed_in_0` share the sitting body within 1 px.
- [ ] `cover_colours`: every pixel inside `cover_rects_xywh` is one of bed.png's 18 RGB, and no bed part is redrawn.
- [ ] Pass-out: every frame touches row 35; frames 0, 1, 3 centred on x 20 (+-1); frame 0 hat top row 4 (+-1); frame 3 lying 26-31 wide, 7-11 tall; `east` a pixel-exact flip of `west` (`mirror_pairs_exact`).
- [ ] Binary alpha, true transparency; no bed, shadow, Zzz, dust, glow, night or text.
- [ ] `colours_allowed`: garment only in the 12 blue colours; every RGB listed in `colour_ramp` with a role.
- [ ] The same person as the walk, readable at 1x by day and in the night preview.
- [ ] `build.py` twice gives identical bytes, `--check` passes, checks.json all `true`.

## Delivery

`implementation/backlog/deliveries/A001-farmer-bed/` with the files of contract 9.1:
`raw/` (+ `.prompt.txt`, `.call.json`), `native/<anim>/<dir>/01..NN.png`,
`runtime/<anim>/<dir>/01..NN.png`, `preview/`, `rejected/`, `contract.json`
(`palette_mode` "B", `palette` "exact-source", `colour_ramp`, `runtime_canvas_wh`
[80,80], `runtime_pivot_xy` [40,72], `detail_wh` [40,40], the `mirror` of every
animation, `mirror_pairs` `{"east": "west"}`, `grounded` false for the bed strips, a
`bed_anchor` entry `{"bed": "sprites/interior/bed.png", "frame_origin_on_bed_xy":
[4,3], "pivot_on_bed_xy": [24,39], "offset_from_bed_pivot": [0,-25]}`, and
`cover_rects_xywh` in each bed file's recipe), `checks.json` (plus `bed_fit`,
`bed_continuity`, `cover_colours`), `build.py`, `index.html`, `review-log.txt`. After
the owner approves in words: `APPROVAL.json`, `CLAUDE-A001-PROMPT.txt` (mapping e.g.
`runtime/bed_sleep/none/01..02.png -> sprites/actors/bed_sleep_0..1.png  80x80 pivot (40,72) draw 0.5 detail_wh [40,40]  0.8 s loop`
and `runtime/pass_out/east/01..04.png -> sprites/actors/pass_out_east_0..3.png  0.18 s one-shot`;
"pass_out_east is a baked mirror: bind directly, never flip"; the bed anchor for
`house_view.gd` - the frame's pivot is the bed sprite's pivot + (0,-25), drawn above
the bed, no shadow; it replaces 0129's stand-ins for game task 0143), then
`python implementation/backlog/assets.py set A001 approved`.
