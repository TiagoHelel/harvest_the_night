# A025 - The farmer tending animals

- **Status:** todo
- **For game task:** 0208
- **Dressed by game tasks:** 0185
- **Spec after game task:** 0185
- **Family:** farmer
- **Mode:** B - finished native pixel art (`exact-source`), the approved blue 32px farmer's colours
- **Size of the job:** 2 animations x 3 directions x 4 frames = 24 native frames, plus the same 24 as exact 2x runtime copies

## What it is for

The coop and the barn fill out in 1.0 (0183-0185): hens lay eggs, cows give milk,
sheep give wool, pigs find truffles, and a dog follows the farmer by day. Collecting
at the coop or barn and digging a truffle play one generic tending gesture (down on
one knee, hands working at an animal's flank or at the ground, up again), and petting
the dog is a view-only gesture with A002's heart over his head afterwards. Today the
farmer has no pose for either (0185 draws stand-ins). The player sees them several
times a day beside the 40x32 animals of A026-A028, by day and at dusk: the body must
be the walk's 32px body and the hands must meet the neighbouring cell at an animal's
height, readable at 1x and after the night relight.

## Deliverables

The table is provisional: game task 0185 settles the final canvas/footprint/states and updates it; start only when `python implementation/backlog/assets.py next` offers this pack.

| Runtime name | Native canvas | Pivot | Frames / seconds / loop | Notes |
|---|---|---|---|---|
| `tend_<dir>_0..3` | 48x48 | (24,44) | 4 / 0.09 / one-shot | Hands only; one gesture for milking, shearing, feeding, collecting at the coop or barn and digging a truffle. 0 down on one knee, both hands reaching into the faced cell at an animal's flank height (held); 1 hands working: closed and 1-2 px lower (a squeeze, a pull, a scoop); 2 hands drawn back toward the chest, still kneeling; 3 rising, close to idle. |
| `pet_dog_<dir>_0..3` | 48x48 | (24,44) | 4 / 0.15 / played 0,1,2,1,2,3 | Bending at the waist, the other hand on the knee. 0 bending, one hand reaching; 1 the hand on a dog's head at the farmer's hip height in the faced cell (pat up); 2 the same hand 1-2 px lower (pat down); 3 straightening, close to idle. |

`<dir>` is `south`, `north` and `west` (6 animations). The runtime pack of every row
is 96x96 / pivot (48,88), `draw_scale` 0.5, every native pixel a 2x2 block (Claude
imports with `detail_wh` [48,48]).

Rules for every row:

- **Directions and files.** South, north and west are authored. East is the runtime
  mirror of west and is never delivered: `mirror: "runtime"`, `mirror_pairs: {}`.
  Files `native/<anim>/<dir>/01..04.png` and `runtime/<anim>/<dir>/01..04.png`,
  `01.png` = frame 0. Claude writes `sprites/actors/<anim>_<dir>_<i>.png`.
- **How the game plays them** (0185 and 0208 confirm): `tend` plays like the work
  verbs in `src/ui/player_work.gd` - frame 0 held for the collect or dig work timer,
  then 1, 2, 3 at 0.09 s on completion, then idle. `pet_dog` is a view cue with no
  core verb (like `carry`): 0, 1, 2, 1, 2, 3 at 0.15 s while the dog plays A028's
  `dog_wag`, then idle with A002's heart. So frame 0 of `tend` is a stable hold that
  reads as "about to", and frame 3 of both sits within 2 px of the idle silhouette.
- **The same body as the walk.** Same identity, scale and camera as
  `walk-final-mirrored` and the grounded idle: straw hat with the brown band, dark
  red-brown hair, white shirt, blue overalls, brown boots, ~16 px wide and 32 rows
  tall standing. Upright frames: hat top on row 12, boots on row 43 (+-1); head+hat
  block within +-1 px of `idle_<dir>`. Kneeling and bending lower the head 5-9 rows;
  they never shrink or enlarge it.
- **Grounded.** The lowest opaque row is 43 in every frame (boots, or the kneeling
  knee and the planted boot). The planted boot never slides (its x span equal +-1
  across the strip). The torso is centred on x=24 (+-1). Only south hands may reach
  rows 44-47. Everything stays inside the canvas.
- **Hand targets** on the contact frames (`tend_1`, `pet_dog_1` and `_2`; the farmer's
  own cell is x 16..31, rows 28..43; the animal stands on the neighbouring cell: a
  cow, sheep or pig 15-24 rows tall, a hen about 12, the dog 15-17 with its ears at
  the farmer's hip). West - tend hands at x 4..14, rows 32..42 (an udder, a fleece, a
  hen, a trough or a dig spot); pet hand at x 6..15, rows 27..33 (a dog's head).
  South - in front of the boots, x 16..31: tend rows 40..47, pet rows 38..46. North -
  reaching away from the viewer, x 16..31: tend rows 20..30, pet rows 14..24, partly
  hidden by the back and the hat (never below the boots).
- **No metadata points and no reserved colours:** hands only, nothing held.
- **Never baked:** the animal, the dog, eggs, milk, wool, truffles, a bucket, shears,
  a scoop, feed or hay, the heart, dust, shadow, glow, night tint, text (contract
  sections 2.3 and 4).

## Match these

- `implementation/fhd-player/pilots/2026-10-06/walk-final-mirrored/native-40/walk/<down,up,left>/01..08.png`
  (40x40, pivot (20,36), visible ~16x32): identity, scale, outline and the blue
  garment. Screen words: down=south, up=north, left=west.
- `sprites/actors/idle_<south,north,west>_0.png` (80x80, exact 2x blocks; NEAREST to
  40x40 gives the native idle) and the full-detail
  `assets/art_source/player-fhd/idle-blue-grounded/frames/<down,up,left>.png`: the
  stance every frame 3 returns to.
- `implementation/fhd-player/pilots/2026-10-04/palette-variants/validation.json`
  (`variants.blue`, 12 RGB): the only colours a garment pixel may take.
- `sprites/actors/collect_0..3.png` (legacy 48x48) and
  `assets/art_source/player-fhd/directional/frames/collect_<south,north,west>_0..3.png`
  (128x128, pivot (64,108), older FHD candidates): the crouch-and-reach, pose
  reference only. If approved, A007's `plant` and A008's `collect` deliveries
  (`implementation/backlog/deliveries/A007-farmer-field-work/native/plant/<dir>/`,
  `.../A008-farmer-gather-work/native/collect/<dir>/`): the kneel in the blue body.
- The animals, preview only: if approved, `implementation/backlog/deliveries/A027-cow-chicken/native/cow_idle/west/01.png`,
  `.../A026-farm-animals/native/sheep_idle/west/01.png` and
  `.../A028-dog/native/dog_wag/west/01.png` (40x32, pivot (20,30)); otherwise
  `sprites/props/cow.png` and `chicken.png` (24x24, too small - height reference only)
  and A028's size table (a standing dog 20-22 wide, 15-17 tall).
- `docs/reference-sheet.png`, `assets/art_source/masters/farmer.png`: look and identity.

## How to make it

1. **No candidates exist** for tend or pet (the inventory lists them as missing).
   Ask owner question 1 before generating.
2. **Prompt:** contract section 8 - BASE + PLAYER_WORK (+ STRIP, + CORRECTION), canvas
   48x48, contact pivot (24,44), the row's ordered poses, tool "bare hands". Add: "The
   approved blue 32px farmer, exactly the attached identity: same body size, hat,
   hair, face, white shirt, blue overalls, brown boots. Hands only: nothing in the
   hands, no animal, no bucket, shears or feed. Boots, and the kneeling knee, on one
   ground line in every cell. Nothing on the ground, no shadow." For `tend`: "Down on
   one knee, working with both hands at the flank of an animal standing in the next
   cell." For `pet_dog`: "Bending at the waist, patting the head of a medium dog
   whose ears reach his hip, in the next cell."
3. **Inputs** (one strip per call, `transparent_background=true`): Image 1 the 8 walk
   frames of that direction enlarged x6 NEAREST (identity master); Image 2 the
   full-detail idle of that direction (identity); Image 3 an animal of the right height
   enlarged at the same factor (A027's cow or A028's dog if approved, else `cow.png`;
   role: height reference only, never drawn); after the first accepted strip, that
   strip (style and scale reference).
4. **Order:** `tend/west` first; reduce it and check it beside the walk and an animal
   on the neighbouring cell before anything else. Then `pet_dog/west`, then south,
   then north.
5. **Export (mode B):** measured cell boxes; one `content_scale` per strip, chosen so
   the upright frame measures 32 rows and the hat brim matches the idle's width;
   anchor = the planted boot's bottom centre in frame 3, landing on (24,44), the same
   cell-relative anchor for all four cells. Alpha >= 128 -> 255, else 0. Garment
   pixels (`b > 1.15*r and b > 1.10*g and b >= 6`, as in
   `implementation/fhd-player/pilots/2026-10-06/walk-up-right-low-step/export_individual.py`)
   -> nearest of the 12 blue colours; every other opaque pixel -> nearest of (all RGB
   in the 64 approved walk native frames + the 42 `COLOURS`). Runtime = native x2
   NEAREST.
6. **Single-frame fixes** use the guide method that finished the approved walk: the
   native frame enlarged x10 NEAREST to 480x480 as the edit target, CORRECTION text
   naming the one fix, the whole return NEAREST-resized to 48x48, the same colour step.
   At most 3 revisions per strip.
7. If the reduction loses the face or merges the hands into the body, regenerate.
   Never patch native pixels.

## Review with the owner

The page (contract 9.5) shows, for each of the 6 strips: 1x and 4x; played the way
the game plays it (`tend`: frame 0 held 0.5 s, then 1-3 at 0.09 s, then the idle
frame; `pet_dog`: 0, 1, 2, 1, 2, 3 at 0.15 s, then the idle frame with today's
`react_heart_0` glyph, or A002's if approved, at its `bubble`) and as a still strip;
the east version as a flip of west, labelled "runtime mirror, preview only"; beside the
walk and idle of that direction on one ground line; an onion skin over the idle;
frame 1 over a 16 px grid with tiled grass and, on the faced cell, the animal
references (cow, sheep and hen for `tend`, the dog for `pet_dog`; a 20x16 box when the
dog is not approved), preview only; the night preview.

Ask the owner:

1. (before generating) "Um único gesto de cuidar (ajoelhar, mãos trabalhando, levantar) serve para ordenhar, tosquiar, alimentar, coletar no galinheiro e no celeiro e cavar trufa. Pode ser assim, ou quer um gesto próprio para algum deles?"
2. "No carinho no cachorro a mão chega à cabeça dele na altura certa nas três direções, e o corpo continua o mesmo da caminhada?"
3. "Na prévia noturna os dois gestos continuam legíveis a 1x?"

## Acceptance

- [ ] 24 native frames (`tend` and `pet_dog` x south/north/west x 4), each 48x48 pivot (24,44); 24 runtime frames, each exactly native x2 NEAREST (96x96, pivot (48,88)); no east files.
- [ ] Lowest opaque row 43 in every frame; the planted boot not sliding; torso centred on x=24 (+-1); upright frames 32 rows tall; head+hat within +-1 px of the idle.
- [ ] Hands inside their direction's target zone on `tend_1`, `pet_dog_1` and `pet_dog_2`; `pet_dog_1` and `_2` differ only in the patting hand.
- [ ] Frame 0 of `tend` is a stable hold; frame 3 of both is within 2 px of the idle silhouette.
- [ ] Binary alpha, true transparency; no animal, product, tool, heart, shadow, glow, night or text.
- [ ] `colours_allowed`: garment only in the 12 blue colours; every RGB listed in `colour_ramp` with a role.
- [ ] Reads at 1x by day and at night; the same person as the walk.
- [ ] `build.py` twice gives identical bytes, `--check` passes, checks.json all `true`.

## Delivery

`implementation/backlog/deliveries/A025-farmer-care/` with the files of contract 9.1:
`raw/` (+ `.prompt.txt`, `.call.json`), `native/<anim>/<dir>/01..04.png`,
`runtime/<anim>/<dir>/01..04.png`, `preview/`, `rejected/`, `contract.json`
(`palette_mode` "B", `palette` "exact-source", `colour_ramp`, `runtime_canvas_wh`
[96,96], `runtime_pivot_xy` [48,88], `detail_wh` [48,48], `mirror` "runtime" for every
animation, `points` empty), `checks.json`, `build.py`, `index.html`, `review-log.txt`.
After the owner approves in words: `APPROVAL.json`, `CLAUDE-A025-PROMPT.txt` (mapping
e.g. `runtime/tend/west/01..04.png -> sprites/actors/tend_west_0..3.png  96x96 pivot (48,88) draw 0.5 detail_wh [48,48]  0.09 s one-shot`
and `runtime/pet_dog/west/01..04.png -> sprites/actors/pet_dog_west_0..3.png  0.15 s, played 0,1,2,1,2,3`;
"east is not delivered: the game flips west"; it replaces 0185's stand-in poses for
game task 0208), then `python implementation/backlog/assets.py set A025 approved`.
