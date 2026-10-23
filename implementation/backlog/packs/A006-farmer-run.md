# A006 - The farmer's run, eight directions

- **Status:** blocked - Cancelled by owner: remove all eight run directions; reuse existing walk; see delivery/RUN-REMOVAL.txt
- **For game task:** 0122
- **Family:** farmer
- **Mode:** B - finished native pixel art (`exact-source`), the approved blue 32px farmer's colours
- **Size of the job:** 5 authored directions x 8 frames = 40 drawn frames, plus 24 baked mirrors = 64 native frames, plus the same 64 as exact 2x runtime copies

## What it is for

Holding the run key (Shift, or the pad binding) today replays the walk at 0.07 s per
frame, so the farmer looks like he is walking fast, not running. This pack is the
real run in all eight directions, in the approved blue 32px body. The player sees it
whenever he crosses the farm in a hurry, by day and at dusk. At 1080p it is the walk's
body (~128 physical px) with a longer stride, a forward lean, pumping arms and two
legs that clearly alternate. The owner rejected the lateral run twice (2026-10-02/03,
PROGRESS) because it "looked like one moving leg": that is the failure this pack must
not repeat.

## Deliverables

| Runtime name | Native canvas | Pivot | Frames / seconds / loop | Notes |
|---|---|---|---|---|
| `run_south_0..7` | 40x40 | (20,36) | 8 / 0.07 / loop | Authored, facing the viewer. |
| `run_north_0..7` | 40x40 | (20,36) | 8 / 0.07 / loop | Authored, back to the viewer. |
| `run_east_0..7` | 40x40 | (20,36) | 8 / 0.07 / loop | Authored side view, running right. |
| `run_south_west_0..7` | 40x40 | (20,36) | 8 / 0.07 / loop | Authored, down-left. |
| `run_north_east_0..7` | 40x40 | (20,36) | 8 / 0.07 / loop | Authored, up-right. |
| `run_west_0..7` | 40x40 | (20,36) | 8 / 0.07 / loop | Baked: exact whole-canvas flip of `run_east`, frame for frame. |
| `run_south_east_0..7` | 40x40 | (20,36) | 8 / 0.07 / loop | Baked: exact flip of `run_south_west`. |
| `run_north_west_0..7` | 40x40 | (20,36) | 8 / 0.07 / loop | Baked: exact flip of `run_north_east`. |

The runtime pack of every row is 80x80 / pivot (40,72), `draw_scale` 0.5, every
native pixel a 2x2 block (Claude imports with `detail_wh` [40,40]).

Rules for every row:

- **The eight phases**, in order (A and B are the two legs; in side and diagonal
  views A is the near leg): 0 contact A (A's heel lands ahead), 1 down A (weight on
  A, knee bent, body lowest), 2 push-off A (A drives back, B swings through bent),
  3 flight (both boots off the ground, B reaching ahead), 4 contact B, 5 down B,
  6 push-off B, 7 flight (A reaching ahead) - 7 leads back to 0. Arms swing opposite
  to the legs. Frames 4-7 mirror the leg roles of 0-3; they are never copies.
- **Two legs, always readable.** In side and diagonal views the near leg's trouser
  and boot are lighter than the far leg's (the blue ramp's upper vs lower steps, boot
  `soil_light`-like vs `soil_dark`-like values from the walk's own boot colours), and
  the near knee moves at least 4 px between frames 1 and 5 and between 3 and 7. In
  south and north the two legs exchange which one is lifted.
- **The same body as the walk.** Identity, scale, camera and garment of
  `walk-final-mirrored`: straw hat with the brown band, dark red-brown hair, white
  shirt, blue overalls, brown boots. Hat top on row 4 in phases 0, 2, 3, 4, 6, 7 and
  on row 5 in the down phases 1 and 5 (a 1 px bob, never more). Head+hat block within
  +-1 px of the walk frame of the same direction. Body height 31-32 rows; visible
  width at most 26 px; the torso (not the reaching foot) centred on x 19-21. A 1-2 px
  lean into the direction of travel.
- **Grounded.** Phases 0, 1, 2, 4, 5, 6 have the lowest opaque row 35 (`pivot_y - 1`).
  Flight phases 3 and 7 have both boots 1-3 px off the ground (lowest row 32-34). The
  supporting boot does not slide between 0 and 1 or between 4 and 5.
- **Mirrors.** `west`, `south_east` and `north_west` are exact whole-canvas horizontal
  flips of `east`, `south_west` and `north_east`, made by build.py, for native and
  runtime; `mirror: "baked:<dir>"`, `mirror_pairs` `{"west": "east", "south_east":
  "south_west", "north_west": "north_east"}`. Claude binds all eight directly and
  never flips at runtime. The pivot is centred, so a flip keeps (20,36).
- **Files:** `native/run/<dir>/01..08.png` and `runtime/run/<dir>/01..08.png` for all
  eight directions; `01.png` = frame 0. Claude writes `sprites/actors/run_<dir>_<i>.png`.
- **Never baked:** dust, speed lines, motion blur, shadow, glow, night tint, text.

## Match these

- `implementation/fhd-player/pilots/2026-10-06/walk-final-mirrored/native-40/walk/<dir>/01..08.png`
  and `runtime-80/`: the approved walk, the identity and scale master. Screen words:
  down=south, up=north, right=east, left=west, down-left=south_west,
  down-right=south_east, up-right=north_east, up-left=north_west. Measured: visible
  top row 4 in every frame, lowest row 33-35, width 15-20, ~200 colours a frame.
- `implementation/fhd-player/pilots/2026-10-06/walk-up-right-low-step/`
  (`frame-inputs/`, `individual-frame-prompts.json`, `export_individual.py`): the
  single-frame edit method that finished the approved walk, and its colour step.
- `sprites/actors/idle_<dir>_0.png` and
  `assets/art_source/player-fhd/idle-blue-grounded/frames/<screen dir>.png` (full
  detail): identity at rest.
- `implementation/fhd-player/pilots/2026-10-04/palette-variants/validation.json`
  (`variants.blue`): the 12 garment colours.
- Older run candidates, pose reference only (older chibi identity, 60 px body, navy
  `cloth` overalls): `assets/art_source/player-fhd/approved/run_south_8.png` (raw
  1774x887 sheet), `assets/art_source/player-fhd/directional/frames/run_{east,north,west}_0..7.png`
  (96x96, pivot (48,88)), and the rejected lateral sources
  `assets/art_source/player-fhd/directional/creator-run-*.png`. The rejection
  history is in `implementation/fhd-player/directional/README.md` ("Lateral run")
  and `implementation/PROGRESS.md` (2026-10-03, "readable anatomical leg recovery").

## How to make it

1. **Candidates first (no generation).** Build `preview/candidates.png` and a GIF
   row: the old run candidates NEAREST-scaled by 32/60 beside the approved walk of
   the same direction, at 0.07 s. Ask owner question 1. Default (and the answer if
   none comes): generate all five authored directions fresh from the blue walk; the
   candidates are pose references only. They cannot be delivered as they are: their
   overalls are outside the 12-colour ramp and their head and hat are larger.
2. **Prompt:** contract section 8 - BASE + PLAYER_STRIP (direction, action "run";
   its "Walk: 4 frames" line is replaced by this pack's eight phases) + STRIP (N=8)
   + CORRECTION for revisions; canvas 40x40, contact pivot (20,36). Add: "The
   approved blue 32px farmer, exactly the attached walk: same hat, hair, face, white
   shirt, blue overalls, brown boots, same body height. A light jog-run, not a
   sprint: longer stride than the walk, knees bending, a slight forward lean, arms
   pumping opposite to the legs. Two separate legs that clearly take turns: the near
   leg lighter, the far leg darker. No dust or speed lines."
3. **Inputs** (`transparent_background=true`, one direction per call): Image 1 the 8
   walk frames of that direction, enlarged x6 NEAREST (identity master and scale);
   Image 2 the full-detail idle of that direction (identity); Image 3 an old
   candidate run of the nearest direction (pose reference only, older identity: copy
   the timing of the legs, not the drawing).
4. **Order:** `east` first - it is the twice-rejected one. Reduce it, show the owner
   the lateral run alone (question 2) before anything else. Then `south`, `north`,
   `south_west`, `north_east`. One 8-cell STRIP per direction.
5. **Export (mode B):** measured cell boxes; one `content_scale` per direction,
   chosen so the hat brim matches the walk of that direction; anchor = the
   supporting boot's bottom centre in contact phase 0, the same cell-relative anchor
   for all eight cells, landing on (20,36). Alpha >= 128 -> 255, else 0. Garment
   pixels (`b > 1.15*r and b > 1.10*g and b >= 6`) -> nearest of the 12 blue colours;
   every other opaque pixel -> nearest of (all RGB in the 64 approved walk native
   frames + the 42 `COLOURS`). Then the three baked flips, then runtime = native x2.
6. **Single-frame fixes** (the expected way to repair a leg): the guide method of
   `walk-up-right-low-step` - the native frame enlarged x12 NEAREST to 480x480 as the
   edit target, CORRECTION text naming the one fix ("only the far leg: ..."), the
   whole return NEAREST-resized to 40x40, the same colour step. At most 3 revisions
   per frame; after that ask the owner.
7. Never patch, swap or re-time frames by code; never reuse a walk frame as a run
   frame.

## Review with the owner

The page (contract 9.5) shows all eight directions: 1x and 4x, playing at 0.07 s and
again slowed to 0.2 s, beside the walk of the same direction at 0.1 s on one ground
line; each direction as a still strip of 8 frames at 8x with only the lower body
(rows 22-35) enlarged, so the leg exchange is visible; an onion skin of phases 0 and
4; the three baked pairs side by side; the night preview; over light, dark, checker
and tiled grass; and `preview/candidates.png`.

Ask the owner:

1. (before generating) "Os candidatos antigos de corrida são o fazendeiro de cabeça grande e macacão azul-marinho, e a corrida lateral já foi recusada duas vezes. Posso gerar a corrida toda de novo a partir da caminhada azul aprovada, usando os antigos só como referência de pose?"
2. (after `east`) "Agora a corrida para a direita mostra as duas pernas se alternando? Veja na velocidade real e na câmera lenta."
3. "As oito direções parecem o mesmo fazendeiro da caminhada, só correndo?"

## Acceptance

- [ ] 64 native frames (8 directions x 8), each 40x40 pivot (20,36); 64 runtime frames, each exactly native x2 NEAREST (80x80, pivot (40,72)).
- [ ] The three baked directions are pixel-exact flips of their sources, native and runtime (`mirror_pairs_exact`).
- [ ] Phases 0, 1, 2, 4, 5, 6 have lowest row 35; flights 3 and 7 lowest row 32-34; hat top row 4 (row 5 on 1 and 5); torso centred on x 19-21; width at most 26.
- [ ] The two legs differ in value in side and diagonal views, and the near knee moves at least 4 px between 1 and 5 and between 3 and 7 (record the measurement in checks.json as `legs_alternate`).
- [ ] Frame 7 leads back to frame 0; frames 4-7 are not copies of 0-3.
- [ ] Binary alpha, true transparency; no dust, speed lines, shadow, glow, night or text.
- [ ] `colours_allowed`: garment only in the 12 blue colours; every RGB in `colour_ramp` with a role.
- [ ] Next to the walk it is the same person, by day and in the night preview.
- [ ] `build.py` twice gives identical bytes, `--check` passes, checks.json all `true`.

## Delivery

`implementation/backlog/deliveries/A006-farmer-run/` with the files of contract 9.1:
`raw/` (+ `.prompt.txt`, `.call.json`), `native/run/<dir>/01..08.png` and
`runtime/run/<dir>/01..08.png` for all eight directions, `preview/`, `rejected/`,
`contract.json` (`palette_mode` "B", `palette` "exact-source", `colour_ramp`, the
`mirror` of every direction and `mirror_pairs`, `runtime_canvas_wh` [80,80],
`runtime_pivot_xy` [40,72], `detail_wh` [40,40]), `checks.json` (plus
`legs_alternate`), `build.py`, `index.html`, `review-log.txt`. After the owner
approves in words: `APPROVAL.json`, `CLAUDE-A006-PROMPT.txt` (mapping e.g.
`runtime/run/north_east/01..08.png -> sprites/actors/run_north_east_0..7.png  80x80 pivot (40,72) draw 0.5 detail_wh [40,40]  0.07 s loop`;
"west, south_east and north_west are baked mirrors: bind directly, never flip"; it
replaces 0120's run stand-in (the walk at `RUN_FRAME_SECONDS`) for game task 0122),
then `python implementation/backlog/assets.py set A006 approved`.
