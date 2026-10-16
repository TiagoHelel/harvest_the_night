# A052 - The Harvester

- **Status:** integrated
- **For game task:** 0266
- **Dressed by game tasks:** 0253
- **Spec after game task:** 0253
- **Family:** bosses
- **Mode:** A - raw ImageGen sources, Claude reduces them to the 42-colour palette
- **Size of the job:** 25 PNGs: 1 master, 5 animations (19 frames), a 4-frame effect, 1 forecast mark

## What it is for

The Harvester is summer's boss (Summer 14): an old harvesting machine possessed by the rot. It rolls in slowly. Every so often it stops and winds up, with its charge line telegraphed on the ground by code. Then it charges in a straight line, crushing every wall in its row until one holds. One thick wall is a speed bump; layers are a defence. The player sees it at night as the biggest thing on the farm after the house. The wind-up must be the pose they learn to fear, readable at 1x by day and in the night preview. It must read as a machine, not a giant zombie, beside the Giant and the 32px farmer. The trophy is A056's, not this pack's.

## Deliverables

Final geometry settled by game task 0253: **the Giant's 80x64 standing on (40,60), kept.** Nothing in the rules or the view asks for more room, so 0253 writes no case for 112x80. The rows stand as written, with the frames and seconds of the table. **How the game plays them:**
- **The roll:** 44 ticks a tile, about two thirds of a tile a second, on the four `walk` frames at 0.14 s each, facing the way it moves.
- **The wind-up:** `telegraph_ticks`, a second and a half - the same rear before a charge, before a gnaw and at the house. `windup_0..2` play at 0.1 s each, and frame 2 holds for the rest of it. Before a charge, a strip drawn in code covers every cell the charge will enter, edged in the warning's red. It ends where something will hold, or at the house. The boss bar flashes through every wind-up.
- **The charge:** `charge_0..3` loop at 0.1 s while it runs its line at 3 ticks a tile (ten tiles a second), six tiles at most, along a row or a column - so it faces west, or east mirrored, or moves straight up or down the screen in the west-facing frames.
- **The crush:** until 0266 its gnaws and bites show the wind-up and then the roll, and `crush` waits for 0266 to play on each contact. Every structure the charge brings down leaves its own wreck; `wreck_debris` plays nowhere until 0266 emits it at each one.
- **Death:** until 0266 the body left behind is `harvester_death_4`, squashed.
- **Night colours:** summer's night is the teal one, and the rust stand-in reads on it by its warm body against the cool ground. Keep the machine warm-toned, rust and old paint, so it never reads as part of the night.

Until 0266 every frame stands in as the Giant gone to rust (`PlaceholderArt`), and the forecast mark is the Giant's head, tinted the same, all through 0120's road. Start only when `python implementation/backlog/assets.py next` offers this pack.

| Runtime name | Native canvas | Pivot | Frames / seconds / loop | Notes |
|---|---|---|---|---|
| `enemies/harvester` | 80x64 | (40,60) | 1 / 0.1 / static | Identity master, side view facing `west`: the cutting reel and blades at the front (west), the cab, the hopper and an exhaust stack at the back. Visible 58-66 wide x 40-46 tall. The wheels stand on row 59. |
| `enemies/harvester_walk_0..3` | 80x64 | (40,60) | 4 / 0.14 / loop | The slow roll, facing `west`, mirrored at runtime. The reel and wheels turn through 4 positions, and the chassis bobs by at most 1 px. |
| `enemies/harvester_windup_0..2` | 80x64 | (40,60) | 3 / 0.1 / one-shot | The telegraph. (0) brakes, and the reel spins up with the front lifting 2 px. (1) rears back, the front up 6 px. (2) fully rearing: the header and blades high, the body leaning east, at least 50 tall. The view holds frame 2 for the rest of `telegraph_ticks`. |
| `enemies/harvester_charge_0..3` | 80x64 | (40,60) | 4 / 0.1 / loop | Plays while 0253's charge runs. Lunging low, with the header down and the reel blades in 4 rotation positions. No dust or speed lines baked in. |
| `enemies/harvester_crush_0..2` | 80x64 | (40,60) | 3 / 0.1 / one-shot | Its attack: gnawing a wall, biting the house, and stopping at a structure that holds. (0) the header raised, (1) slammed down to the west (contact), (2) recovery. |
| `enemies/harvester_death_0..4` | 80x64 | (40,60) | 5 / 0.12 / one-shot | (0) jolts with a panel bursting, (1) the reel breaks off and drops, (2) sags on a broken wheel, (3) collapses, (4) a low wreck heap, at most 20 tall. |
| `effects/wreck_debris_0..3` | 24x20 | (12,18) | 4 / 0.08 / one-shot | Direction `none`. Splinters, stone chips and dirt thrown up from a crushed structure. The game emits it at the ground contact point (bottom centre of the cell) of every structure the charge destroys. (0) a low burst, (1) the widest and highest (at most 22 wide x 17 tall: rows 1-17, base on row 17), (2) pieces falling, (3) a few chips. **24x20 is chosen here over the 16x20 rising default, because a crushed cell sprays wider than a flame.** |
| `ui/head_harvester` | 16x16 | (8,8) | 1 / 1.0 / static | Forecast mark, direction `none`: the front of the machine (reel, blades and cab) turned three-quarter to the left. Fills the box like A011's `head_giant` (rules below). |

- **Every boss frame:**
  - the lowest opaque row is 59 (the wheels or wreck stand on the pivot row 60);
  - the machine is centred on x=40 (±1), between its wheels;
  - a 1 px clear border: only columns 1-78 and rows 1-59 hold pixels;
  - one `content_scale` per strip and the same machine size across strips (±1 px);
  - no two frames are identical.
- **Windup:** the visible height strictly increases from frame 0 to frame 2.
- **Death:** the visible height never grows from one frame to the next, and the last frame is at most 20 tall.
- **`smoke_xy`:**
  - on the top opaque pixel of the exhaust stack in the master and in every walk, windup, charge and crush frame (none on death);
  - 0266 may puff the existing `smoke` effect from it during the wind-up and the charge;
  - it is in native west-facing coordinates, and the game mirrors it with the sprite.
- **No light point:** the lamps, if drawn, are matte pixels.
- **The debris** keeps a 1 px clear border, expands from frame 0 to frame 1, and frame 3 is smaller than frame 1.
- **The mark** follows the head rules of A011 (`implementation/backlog/packs/A011-forecast-heads.md`), so it sits in one row with the other heads:
  - a bust in three-quarter view turned to the left, cut flat at the bottom;
  - the lowest opaque row is 14 (row 15 empty), centred on x=8 (±1), with 1 px clear at left, right and top;
  - 14 wide or 14 tall, nothing over 14: it fills the box like `head_giant`;
  - `palette_keys` are the palette names used by this pack's own `harvester` frames, which build.py computes read-only from its `native/`;
  - the eyes are `bone` or `bone_dark`, never a colour that looks emissive;
  - `content_anchor_xy` = `(scaled_w // 2, scaled_h - 7)`;
  - there is no 10x10 cut.
- **Aliases:** Claude creates `harvester_walk_b` (= walk_2), `harvester_telegraph` (= windup_2), `harvester_attack` (= crush_1) and `harvester_death` (= death_4). Do not deliver them.
- **Delivery paths:**
  - `native/harvester/west/01.png`;
  - `native/harvester_<walk,windup,charge,crush,death>/west/01..NN.png`;
  - `native/wreck_debris/none/01..04.png`;
  - `native/head_harvester/none/01.png`.

## Match these

- `sprites/enemies/giant.png`, `giant_walk_0..3.png`, `giant_windup_0..2.png`, `giant_slam_0..2.png` and `giant_death_0..4.png`:
  - 80x64, pivot (40,60);
  - the master is visible 43x42, walk 44-46 x 40-42, windup_2 48x55, and death_4 45x16.
  
  These are the boss scale, outline, rot palette and wind-up readability to match. The Harvester is at least as big as the Giant, but a machine.
- `assets/art_source/enemies/giant/master.png` (1217x1293) and `assets/art_source/enemies/giant/windup.png` (2103x748, 3 cells): accepted raw boss sources.
- `sprites/props/generator.png` (48x48, visible 42x30) and `sprites/buildings/mortar.png` (32x48, visible 21x20): the game's metal, rivets and timber.
  - Match their materials only.
  - The generator is a legacy half-density fixture, drawn at 2x. Do not copy its pixel size.
- `sprites/buildings/wall.png`, `wall_join_10.png` (16x32, pivot (8,28)) and `sprites/buildings/fence_join_10.png`: what it crushes. The debris uses their stone and wood.
- `sprites/effects/dust_0..2.png` (16x12) and `smoke_0..3.png` (16x20): the existing effects that may play with it. The debris must differ from dust: it has hard chips and splinters.
- `implementation/fhd-player/pilots/2026-10-06/walk-final-mirrored/native-40/walk/down/01.png`: the 32px farmer (visible 16x32).
- `docs/reference-sheet.png`: the style reference, with its "BOSS" panel.

## How to make it

1. **Master.**
   - Prompt: BASE + GIANT from `implementation/sprites/generation/PROMPTS.md`, with GIANT's subject and old 64x64 target replaced by: "the Harvester boss, canvas 80x64, contact pivot (40,60), visible machine about 62x44".
   - Add: "An old harvesting machine possessed by the rot. A rusted red-and-timber body with dented iron panels and rivets. At the front (west) a wide cutting reel with scythe blades, then a small cab, a hopper and a tall exhaust stack at the back. Rot-green vines and fungus grow through the seams, and two dead headlamps look like eyes. Big iron wheels. Side view facing west (left) in the game's three-quarter camera. Menacing but in the cozy farm's world. No driver, no glow, no smoke, no ground."
   - Attach:
     - `docs/reference-sheet.png` (style reference);
     - `assets/art_source/enemies/giant/master.png` (boss scale and palette reference, not the shape);
     - the farmer frame (scale reference).
   - Make two candidates. Keep the one that reads as a machine at 1x.
2. **Strips.**
   - Prompt: BASE + GIANT (the motion lines) + ENEMY_STRIP + STRIP, one call per strip: walk 4, windup 3, charge 4, crush 3, death 5.
   - Attach the accepted master raw as the identity master.
   - The windup prompt states that the front rears up higher in each frame.
3. **Debris.** Prompt: BASE + FX + STRIP: "debris thrown up from a crushed wooden-and-stone wall: splinters, stone chips and clods, 4 frames, burst then fall. No smoke cloud, no glow."
4. **Mark.** One call, made the way A011's "How to make it" says: its prompt lines, one candidate, `transparent_background=true`.
   - Subject: "the front of the machine: the reel, the blades, the dead headlamps and the cab".
   - Image 1: this pack's accepted master raw (identity master).
   - Image 2: `native/harvester_walk/west/01.png` from this delivery, enlarged by nearest (colour and in-game identity reference).
   - Image 3: `assets/art_source/ui/wood.png` (icon style reference).
   - If `python implementation/backlog/assets.py status A011` says `approved`, also attach `native/head_giant/none/01.png` from `implementation/backlog/deliveries/A011-forecast-heads/` (framing reference).
5. **Tool argument:** `transparent_background=true` on every call.
6. **Export.**
   - One `content_scale` per strip, set so the machine body (wheel to cab roof) matches the master (±1 px).
   - Set the anchors so the wheels sit on row 59 and the machine is centred on x=40. The debris base sits on row 17, centred on x=12.
   - Render through `import_art.render_source`.
   - The boss strips use no `palette_keys`. The mark follows A011's rule (above).
   - `wreck_debris` uses `["ink","ink_soft","wood_dark","wood","wood_light","stone_dark","stone","stone_light","soil_dark","soil","soil_light"]`.

## Review with the owner

`index.html` follows contract 9.5. It shows:

- every animation at 1x and 4x, playing and still, by day and in the night preview;
- the machine next to the farmer, `sprites/enemies/giant.png` and `walker.png`, feet and wheels on one line;
- a scene on tiled `sprites/terrain/grass.png`, by day and at night:
  1. the wind-up, with frame 2 held for 1 s;
  2. the charge loop crossing a three-cell east-west stone wall run (`wall_join_2.png`, `wall_join_10.png`, `wall_join_8.png`);
  3. `wreck_debris` on each wall cell;
  4. the crush at the end;
- `smoke_xy` marked on an overlay.

The forecast mark is shown at 1x and 4x over `night` #1a1830 and tiled `sprites/ui/panel.png`, beside this pack's master, and in one row with A011's five heads when A011 is approved. The HUD is not relit, so the mark's night preview is labelled "world relight, for reference only".

Questions (in Portuguese):

1. "A Colheitadeira se lê como uma máquina possuída, e não como um zumbi gigante, ao lado do Gigante e do fazendeiro?"
2. "A preparação (a máquina empinando) avisa claramente que ela vai investir, a 1x e de noite?"
3. "Aprova para integração ou quer mudanças?"

## Acceptance

- [ ] Exactly 25 PNGs, with the canvases, pivots, counts and names of the table. Nothing is facing east.
- [ ] Every boss frame: lowest opaque row 59, centred on x=40 (±1), the 1 px border.
- [ ] The master is 58-66 wide and 40-46 tall: wider than every ordinary enemy master and at least 38 tall.
- [ ] No walk or charge frame is another shifted vertically by 2 px or less. The loops close.
- [ ] The windup heights strictly increase, and windup_2 is at least 50 tall.
- [ ] The death never grows taller and ends at most 20 tall.
- [ ] `smoke_xy` sits on an opaque exhaust pixel in each of the 15 frames that carry it.
- [ ] The debris keeps a 1 px border, expands then fades, peaks at most 22x17, and uses only the listed keys.
- [ ]
- [ ] The mark meets A011's rules: lowest opaque row 14, centred on x=8 (±1), 1 px clear at left, right and top, 14 wide or 14 tall, nothing over 14, and only its body's palette names.
- [ ] Every other item in contract section 10 holds.

## Delivery

- **Folder:** `implementation/backlog/deliveries/A052-harvester/` with the standard files of contract 9.1. There is no `runtime/` folder.
- **checks.json** adds:
  - `windup_rises`;
  - `death_settles`;
  - `dominates_ordinary_enemies`;
  - `effect_expands_then_fades`;
  - `icon_bounds_ok`.
- **The mapping lines** in `CLAUDE-A052-PROMPT.txt`:
  - `native/harvester/west/01.png -> sprites/enemies/harvester.png  80x64 pivot (40,60) draw 1.0`;
  - `native/harvester_walk/west/01..04.png -> sprites/enemies/harvester_walk_0..3.png  0.14 s loop`;
  - `native/harvester_windup/west/01..03.png -> sprites/enemies/harvester_windup_0..2.png  0.1 s one-shot, hold frame 2 for the telegraph`;
  - `native/harvester_charge/west/01..04.png -> sprites/enemies/harvester_charge_0..3.png  0.1 s loop while charging`;
  - `native/harvester_crush/west/01..03.png -> sprites/enemies/harvester_crush_0..2.png  0.1 s one-shot`;
  - `native/harvester_death/west/01..05.png -> sprites/enemies/harvester_death_0..4.png  0.12 s one-shot`;
  - `native/wreck_debris/none/01..04.png -> sprites/effects/wreck_debris_0..3.png  24x20 pivot (12,18)  0.08 s one-shot`;
  - `native/head_harvester/none/01.png -> sprites/ui/head_harvester.png  16x16 pivot (8,8)`.
  
  The handoff also gives `smoke_xy` per frame, and says the telegraph strip on the ground is 0253's code.
- **Last step:** `python implementation/backlog/assets.py set A052 approved`, run only after the owner approves in words recorded in `APPROVAL.json`.
