# A007 - The farmer tilling, planting, watering, harvesting

- **Status:** todo
- **For game task:** 0123
- **Family:** farmer
- **Mode:** B - finished native pixel art (`exact-source`), the approved blue 32px farmer's colours
- **Size of the job:** 4 verbs x 3 directions x 4 frames = 48 native frames, plus the same 48 as exact 2x runtime copies

## What it is for

The field verbs still play the older, stockier 48x48 farmer (about 30 px tall, big
head, orange hat) next to the approved blue 32px walk, so the farmer changes
identity every time he touches the soil. These strips are the same blue farmer
tilling with a hoe, planting by hand, watering with a can and pulling a crop, facing
south, north and west (east is the game's mirror of west). The player sees them all
day, every day, on the 16 px field grid; at 1080p the body must be exactly the walk's
body (~128 physical px tall), the gesture must read at 1x, and the tool must land on
the neighbouring cell on the contact frame - by day and after the night relight.

## Deliverables

| Runtime name | Native canvas | Pivot | Frames / seconds / loop | Notes |
|---|---|---|---|---|
| `till_<dir>_0..3` | 48x48 | (24,44) | 4 / 0.09 / one-shot | Hoe. 0 hoe raised over the shoulder (held); 1 blade bites the soil of the faced cell (`contact_xy`); 2 blade drags back toward him; 3 hoe lowered to rest, close to idle. |
| `plant_<dir>_0..3` | 48x48 | (24,44) | 4 / 0.09 / one-shot | Hands only. 0 crouch, one hand at a small seed pouch on the belt (held); 1 hand presses into the faced cell's soil; 2 pats the soil, knees still bent; 3 rising, close to idle. No seeds or particles drawn. |
| `water_<dir>_0..3` | 48x48 | (24,44) | 4 / 0.09 / plays 1,2,3,0 | Watering can. 0 can held level at the hip (ready, and the last frame shown); 1 can tipped, an attached water stream of at most 6 px from the spout (`contact_xy` = spout tip); 2 tipped further, stream shorter; 3 can levelling. No detached drops, no splash, no wet soil. |
| `harvest_<dir>_0..3` | 48x48 | (24,44) | 4 / 0.09 / one-shot | Hands only. 0 crouch, both hands reaching to the faced cell (held); 1 grip at the plant's base, leaning back; 2 rising, closed fists at the chest; 3 standing, close to idle. No crop, bundle or leaves drawn. |

`<dir>` is `south`, `north` and `west` (12 animations). The runtime pack of every
row is 96x96 / pivot (48,88), `draw_scale` 0.5, every native pixel a 2x2 block.

Rules for every row:

- **Directions and files.** South, north and west are authored. East is the runtime
  mirror of west and is never delivered: `mirror: "runtime"`, `mirror_pairs: {}`.
  Files `native/<verb>/<dir>/01..04.png` and `runtime/<verb>/<dir>/01..04.png`,
  `01.png` = frame 0. Claude writes `sprites/actors/<verb>_<dir>_<i>.png`.
- **How the game plays a strip** (`src/ui/player_work.gd`): frame 0 is held for the
  whole work timer (about 0.33 s for plant and harvest, longer while a held key
  repeats); on the completion tick it plays 1, 2, 3 at 0.09 s and returns to idle.
  Water is instant and plays 1, 2, 3, 0. So frame 0 is a stable hold that reads as
  "about to", and frame 3 sits within 2 px of the idle silhouette.
- **The same body as the walk.** Same identity, scale and camera as
  `walk-final-mirrored` and the grounded idle: straw hat with the brown band, dark
  red-brown hair, white shirt, blue overalls, brown boots, ~16 px wide and 32 rows
  tall standing. Upright frames: hat top on row 12, boots on row 43 (+-1). Head+hat
  block within +-1 px of `idle_<dir>` in width and height. Crouches lower the head;
  they never shrink or enlarge it.
- **Grounded.** The boots stand on row 43 in every frame and never slide (each boot's
  x span equal +-1 across the strip). Measured outside `tool_rects_xywh`, the lowest
  opaque row is 43 and the body is centred on x=24 (+-1). Only a south tool head may
  reach rows 44-47. Everything stays inside the canvas.
- **Contact targets** (frame 1, faced cell; the farmer's own cell is x 16..31,
  rows 28..43): west - hoe blade, hand or spout tip inside x 2..14, rows 34..43
  (spout tip rows 28..36, stream ending above row 42); south - in front of the boots,
  x 16..31, rows 40..47; north - reaching away from the viewer above or beside the
  hat, x 16..31, rows 4..27, partly hidden by the hat and back (never below the
  boots). `contact_xy` (till, water only) = an opaque tool-head pixel at the strike or
  the spout tip, on frame 1; code may place its existing dust or splash effect there.
- **Tool head ramp** (decision: the tool is tinted per tier by code, never redrawn).
  The hoe blade and the whole watering can use exactly three reserved colours:
  `stone_dark` #52505c (underside), `stone` #6e6c78 (body), `stone_light` #8c8a96
  (top plane). No other pixel in the pack uses them (the approved walk and idle use
  none of the 42 project colours, measured). build.py may assign them only inside
  each frame's `tool_rects_xywh` (1-3 rectangles chosen to hold tool-head pixels and
  no body pixel, recorded in that file's recipe) and removes them from the palette
  everywhere else. Draw the head as plain untinted steel; game task 0173 tints these
  three RGB values to A019's basic/iron/gold. Handles are the `wood` ramp, untinted.
  Plant and harvest have no reserved pixels.
- **Never baked:** soil, crops, seeds, drops, splash, dust, shadow, glow, night tint,
  text. Contract section 4.

## Match these

- `implementation/fhd-player/pilots/2026-10-06/walk-final-mirrored/native-40/walk/<down,up,left>/01..08.png`
  (40x40, pivot (20,36), visible ~16x32, hat top row 4, boots row 35): identity,
  scale, outline and the blue garment. Screen words: down=south, up=north, left=west.
- `sprites/actors/idle_<south,north,west>_0.png` (80x80, exact 2x blocks; NEAREST to
  40x40 gives the native idle): the grounded stance every frame 3 returns to. Full
  detail for ImageGen: `assets/art_source/player-fhd/idle-blue-grounded/frames/<down,up,left>.png`.
- `implementation/fhd-player/pilots/2026-10-04/palette-variants/validation.json`
  (`variants.blue`, 12 RGB): the only colours a garment pixel may take.
- `sprites/actors/{till,plant,water,harvest}_0..3.png` (legacy 48x48, 30 px tall
  older farmer): what each frame means. Copy the gesture, never the drawing.
- `assets/art_source/player-fhd/directional/frames/<verb>_<south,north,west>_0..3.png`
  (128x128, pivot (64,108), 60 px body): older FHD candidates. Pose reference only
  (see step 1); `plant-r1` keeps the crouch facing the reach.
- Preview targets (never drawn into a strip): `sprites/crops/tilled.png`,
  `tilled_wet.png`, `wheat_3.png`, `corn_3.png` (16x24), `sprites/terrain/grass.png`.
- `docs/reference-sheet.png`, `assets/art_source/masters/farmer.png`: look and identity.

## How to make it

1. **Candidates first (no generation).** Build `preview/candidates.png`: each FHD
   candidate strip NEAREST-scaled by 32/60 beside the approved walk and idle of the
   same direction. They are an older identity - bigger head and hat, brown hair,
   navy overalls from the project `cloth` ramp, which fails the 12-colour garment
   rule. Ask owner question 1. Default (and the answer if none comes): regenerate
   every strip in the blue identity, using the candidates as pose references. If the
   owner keeps a candidate strip, copy its raw sheet
   (`assets/art_source/player-fhd/directional/<verb>.png`) and its record from
   `implementation/fhd-player/directional/prompts/` into `raw/` and export it with
   the same recipe as everything else.
2. **Prompt:** contract section 8 - BASE + PLAYER_WORK (+ STRIP, + CORRECTION) from
   `implementation/sprites/generation/PROMPTS.md`, canvas 48x48, contact pivot
   (24,44), the row's ordered poses, and: "The approved blue 32px farmer, exactly the
   attached identity: same body size, hat, hair, face, white shirt, blue overalls,
   brown boots. Boots planted on one ground line in every cell. The tool's metal head
   is plain flat grey steel with a light top edge; the handle is warm wood. Nothing
   on the ground: no soil, crop, seed, water drop or shadow." Replace PLAYER_WORK's
   "harvest bundle" and "seed hand" with this pack's hands-only poses.
3. **Inputs** (one subject per call, `transparent_background=true`): Image 1 the 8
   walk frames of that direction enlarged x6 NEAREST (identity master); Image 2 the
   full-detail idle of that direction (identity); Image 3 the legacy strip of the
   verb (pose reference, older identity: copy the gesture, not the drawing); after
   the first accepted strip, that strip (style and scale reference).
4. **Order:** `till/west` first; reduce it and check it beside the walk before
   anything else. Then the other west strips, then south, then north. One call per
   verb and direction: a 4-cell STRIP, ordered as the table.
5. **Export (mode B):** cut each cell with a measured box; one `content_scale` per
   strip, chosen so the upright frame measures 32 rows and the hat brim matches the
   idle's width; anchor = the boots' bottom centre, landing on (24,44). Alpha >= 128
   -> 255, else 0. Garment pixels (`b > 1.15*r and b > 1.10*g and b >= 6`, as in
   `implementation/fhd-player/pilots/2026-10-06/walk-up-right-low-step/export_individual.py`)
   -> nearest of the 12 blue colours; the reserved ramp only inside `tool_rects_xywh`;
   every other opaque pixel -> nearest of (all RGB in the 64 approved walk native
   frames + the 42 `COLOURS`) minus the reserved ramp. Runtime = native x2 NEAREST.
6. **Single-frame fixes** use the guide method that finished the approved walk: the
   native frame enlarged x10 NEAREST to 480x480 as the edit target, CORRECTION text
   naming the one fix, then the whole returned image NEAREST-resized to 48x48 and
   the same colour step. At most 3 revisions per strip.
7. If the reduction loses the face, the hoe blade or the can's spout, regenerate.
   Never patch native pixels (contract section 3).

## Review with the owner

The page (contract 9.5) shows, for each of the 12 strips: 1x and 4x; played the way
the game plays it (frame 0 held 0.33 s, then 1-3 at 0.09 s, then the idle frame;
water 1,2,3,0) and as a still strip; the east version as a flip of west, labelled
"runtime mirror, preview only"; beside the walk and idle of that direction on one
ground line; an onion skin over the idle; frame 1 over a 16 px grid with tiled
grass, `tilled.png` on the faced cell (and `wheat_3.png` for harvest), preview only;
the reserved tool pixels in magenta on an overlay, with `contact_xy` marked; the
night preview; and `preview/candidates.png`.

Ask the owner:

1. (before generating) "Os candidatos antigos de trabalho são o fazendeiro de cabeça grande e macacão azul-marinho, não o azul de 32px aprovado. Posso usá-los só como referência de pose e gerar tudo de novo no corpo aprovado?"
2. "Em todos os golpes o corpo, o chapéu e as botas são os mesmos da caminhada aprovada, e a ferramenta acerta o canteiro do lado no quadro de contato?"
3. "Na prévia noturna, enxada, regador e gestos de plantar e colher continuam legíveis a 1x?"

## Acceptance

- [ ] 48 native frames (4 verbs x south/north/west x 4), each 48x48 pivot (24,44); 48 runtime frames, each exactly native x2 NEAREST (96x96, pivot (48,88)); no east files.
- [ ] Boots on row 43 and not sliding; lowest body row 43 and body centred on x=24 (+-1) outside the tool rects; upright frames 32 rows tall; head+hat within +-1 px of the idle.
- [ ] Frame 0 is a stable hold, frame 3 is within 2 px of the idle silhouette; water's frame 0 works as the final pose.
- [ ] `contact_xy` on an opaque tool pixel of frame 1 of every till and water strip, inside its direction's zone.
- [ ] `tool_ramp_reserved`: the three stone colours appear only inside `tool_rects_xywh`, on the hoe blade and the can, at least 4 pixels per tool frame where the head shows; none in plant or harvest.
- [ ] Binary alpha, true transparency; no soil, crop, seed, drop, splash, shadow, glow, night or text.
- [ ] `colours_allowed`: garment only in the 12 blue colours; every RGB listed in `colour_ramp` with a role.
- [ ] Reads at 1x by day and at night; the same person as the walk.
- [ ] `build.py` twice gives identical bytes, `--check` passes, checks.json all `true`.

## Delivery

`implementation/backlog/deliveries/A007-farmer-field-work/` with the files of contract
9.1: `raw/` (+ `.prompt.txt`, `.call.json`), `native/<verb>/<dir>/01..04.png`,
`runtime/<verb>/<dir>/01..04.png`, `preview/`, `rejected/`, `contract.json`
(`palette_mode` "B", `palette` "exact-source", `colour_ramp`, `tool_ramp`:
`["#52505c","#6e6c78","#8c8a96"]`, per file `tool_rects_xywh` in the recipe and
`contact_xy` in `points`, native and runtime x2), `checks.json` (plus
`tool_ramp_reserved`), `build.py`, `index.html`, `review-log.txt`. After the owner
approves in words: `APPROVAL.json`, `CLAUDE-A007-PROMPT.txt` (mapping e.g.
`runtime/till/west/01..04.png -> sprites/actors/till_west_0..3.png  96x96 pivot (48,88) draw 0.5 detail_wh [48,48]  0.09 s one-shot`;
it replaces the legacy `till_*`, `plant_*`, `water_*`, `harvest_*` 48x48 strips and
0120's placeholder entries for game task 0123, and names the tool ramp for 0173),
then `python implementation/backlog/assets.py set A007 approved`.
