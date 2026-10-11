# A047 - The rat swarm

- **Status:** todo
- **For game task:** 0261
- **Dressed by game tasks:** 0248
- **Spec after game task:** 0248
- **Family:** enemies
- **Mode:** A - raw ImageGen sources, Claude reduces them to the 42-colour palette
- **Size of the job:** 12 PNGs: 1 master, 3 animations (10 frames), 1 forecast head

## What it is for

Summer brings swarms of undead rats. Each wave member releases 4-10 rats on adjacent cells at once. They are small and fast, and a mine or a flame cone eats a whole cluster. The player sees them at night as a crowd pouring across the grass, and sees their head in the dusk forecast. One rat is far smaller than any zombie: about a quarter of the farmer's height. It must still read at 1x as a rat (snout, ears, tail), by day and after the night relight, and six of them side by side must read as a crowd of rats, not a smear.

## Deliverables

Final geometry settled by game task 0248. The rows stand as written: 24x16 standing on (12,14), the frames and seconds of the table. **How the game plays them:**
- **Clusters:** a summer wave releases six rats at once, the first on a spawn cell and five on its four neighbours. The swarm walks the same road to the house, so each cluster ends up on one cell. The view spreads each rat by its id, up to 8 px across and 5 px up or down of its point, so six on a cell read as a crowd round it: the master and the walk must still read when they overlap by half.
- **Movement:** a rat walks a tile in 12 ticks (2.5 tiles a second) on the four `walk` frames, 0.1 s each, facing the way it last moved.
- **Walls and the house:** it stops for walls and chews through them as a walker does. Until 0261 a chewing rat scurries in place: the game plays the bite and the three-frame death once that leaf tracks the rat. Until then the corpse is `rat_death_2` squashed and faded.
- **Night colours:** the rat is seen almost only at night. **After the relight a grey rat turns the blue of the field's stones**, and a cluster reads as a heap of rocks, so keep the fur grey-brown (the soils, not the stones).

Until 0261 every frame and the forecast head are drawn in code (`RatArt`) through 0120's road. Start only when `python implementation/backlog/assets.py next` offers this pack.

| Runtime name | Native canvas | Pivot | Frames / seconds / loop | Notes |
|---|---|---|---|---|
| `enemies/rat` | 24x16 | (12,14) | 1 / 0.1 / static | Identity master: standing on four legs, side view facing `west`. Visible 15-18 long (the tail included, at most 20) x 7-9 tall. |
| `enemies/rat_walk_0..3` | 24x16 | (12,14) | 4 / 0.1 / loop | Facing `west`; the game mirrors it to face east. A scurry: (0) front legs reach, (1) gather, (2) back legs push, (3) gather. The tail swings. **0.1 s overrides the family's 0.125: a rat scurries.** |
| `enemies/rat_attack_0..2` | 24x16 | (12,14) | 3 / 0.1 / one-shot | The bite, facing `west`: (0) crouches back, (1) lunges with the jaws open, the snout at most 3 px further west, (2) recovers to standing. |
| `enemies/rat_death_0..2` | 24x16 | (12,14) | 3 / 0.1 / one-shot | Facing `west`: (0) jolts, (1) rolls onto its side, (2) lies on its back with its legs up, at most 6 tall. |
| `ui/head_rat` | 16x16 | (8,8) | 1 / 1.0 / static | Forecast head, direction `none`. A bust following A011's head rules (below). |

- **This is not the 64x48 enemy canvas:** 0261 teaches `tools/check_enemy_art.py` per-family canvases. Every rat frame shares 24x16, pivot (12,14) and the rules below.
- **Every rat frame:**
  - the lowest opaque row is 13 (the feet stand on the pivot row 14);
  - the body is centred on x=12 (±1), with the tail excluded from the centre;
  - a 1 px clear border: only columns 1-22 and rows 1-13 hold pixels;
  - no two frames are identical;
  - one `content_scale` per strip;
  - the standing height is 7-9 in the master, the walk and attack frame 2.
- **Death:** the visible height never grows from one frame to the next.
- **The head** follows the head rules of A011 (`implementation/backlog/packs/A011-forecast-heads.md`), so it sits in one row with the other heads:
  - a bust in three-quarter view turned to the left, cut flat at the bottom;
  - the lowest opaque row is 14 (row 15 empty), centred on x=8 (±1), with 1 px clear at left, right and top;
  - 12-13 tall and at most 13 wide;
  - `palette_keys` are the palette names used by this pack's own `rat` frames, which build.py computes read-only from its `native/`;
  - the eyes are `bone` or `bone_dark`, never a colour that looks emissive;
  - `content_anchor_xy` = `(scaled_w // 2, scaled_h - 7)`;
  - there is no 10x10 cut.
- **Aliases:** Claude creates `rat_walk_b` (= walk_2), `rat_attack` (= attack_1) and `rat_death` (= death_2). Do not deliver them.
- **Delivery paths:**
  - `native/rat/west/01.png`;
  - `native/rat_walk/west/01..04.png`, `native/rat_attack/west/01..03.png` and `native/rat_death/west/01..03.png`;
  - `native/head_rat/none/01.png`.

## Match these

- `implementation/fhd-player/pilots/2026-10-06/walk-final-mirrored/native-40/walk/down/01.png`: the 32px farmer (40x40, pivot (20,36), visible 16x32). The rat is about a quarter of his height.
- `sprites/enemies/walker.png` and `walker_walk_0..3.png` (64x48, pivot (32,44), visible 15-19 x 28-29): match the zombie palette and outline. The rat is the same undead world: rot-green patches on grey-brown fur.
- `sprites/props/chicken.png` (24x24, pivot (12,22), visible 11x12): the only small creature in the game today. Match the density of a small body at 1x. The rat is lower and longer than the chicken.
- `sprites/buildings/mine.png` (16x16, visible 12x8): the rat is about as long as a mine, and the review shows a cluster crossing one.
- `assets/art_source/enemies/walker/walk-v2.png` (1880x836, 4 cells): what an accepted raw strip looks like (transparent background, gutters, one baseline).
- `docs/reference-sheet.png`: the style reference.

## How to make it

1. **Master.**
   - Prompt: BASE + WALKER, with WALKER's target replaced by: "one undead rat, canvas 24x16, contact pivot (12,14), body 16 px long and 8 px tall".
   - Add: "A zombie rat: grey-brown matted fur, bald rot-green patches, exposed ribs on one flank, a pink-grey bare tail and ears, one pale cloudy eye. Side view facing west (left) in the game's three-quarter camera. Big readable head and ears, a clear tail. A small, nasty pest, not a cute pet."
   - Attach `docs/reference-sheet.png` (style reference) and `assets/art_source/enemies/walker/master.png` (a same-world enemy: palette and outline, not a shape to copy).
   - Make two candidates in two calls. Keep the one that still has a snout, ears and a tail after the reduction to 16 px long.
2. **Strips.** Prompt: BASE + ENEMY_STRIP + STRIP, one call per strip (walk 4, attack 3, death 3), with the poses in the table order. Attach the accepted master raw as the identity master.
3. **Head.** One call, made the way A011's "How to make it" says: its prompt lines, one candidate, `transparent_background=true`.
   - Subject: "head, ears, snout and front paws".
   - Image 1: this pack's accepted master raw (identity master).
   - Image 2: `native/rat_walk/west/01.png` from this delivery, enlarged by nearest (colour and in-game identity reference).
   - Image 3: `assets/art_source/ui/wood.png` (icon style reference).
   - If `python implementation/backlog/assets.py status A011` says `approved`, also attach `native/head_walker/none/01.png` from `implementation/backlog/deliveries/A011-forecast-heads/` (framing reference).
4. **Tool argument:** `transparent_background=true` on every call.
5. **Export.**
   - One `content_scale` per strip, chosen so the standing pose is 8 native px tall. The scale is tiny, so check that the eye and ears survive.
   - Set the anchors so the centre of the feet lands on (12,14) and the lowest opaque row is 13.
   - Render through `import_art.render_source`.
   - The default is no `palette_keys`. If the fur borrows cloth blue or grass green, use `["ink","ink_soft","stone_dark","stone","stone_light","soil_dark","soil","soil_light","rot_dark","rot","skin_dark","bone","bone_dark","blood"]` for every rat strip. The head follows A011's rule (above).

## Review with the owner

`index.html` follows contract 9.5. It shows:

- every animation at 1x and 4x, playing and still, by day and in the night preview, next to the farmer and the walker with the feet on one line;
- a swarm scene on tiled `sprites/terrain/grass.png`: six rats on adjacent cells (a 3x2 block of 16 px cells) crossing `sprites/buildings/mine.png`, each rat on a different walk frame, by day and at night.

The forecast head is shown at 1x and 4x over `night` #1a1830 and tiled `sprites/ui/panel.png`, beside this pack's master, and in one row with A011's five heads when A011 is approved. The HUD is not relit, so the head's night preview is labelled "world relight, for reference only".

Questions (in Portuguese):

1. "Seis ratos lado a lado se leem como um enxame de ratos a 1x, de dia e de noite, e não como uma mancha?"
2. "O tamanho do rato ao lado do fazendeiro está bom, ou quer ele um pouco maior?"
3. "Aprova para integração ou quer mudanças?"

## Acceptance

- [ ] Exactly 12 PNGs, with the canvases, pivots, counts and names of the table. Nothing is facing east.
- [ ] Every rat frame: lowest opaque row 13, centred on x=12 (±1), the 1 px clear border.
- [ ] No walk frame is another shifted vertically by 2 px or less. The walk loop closes.
- [ ] The master and the walk are 7-9 tall and at most 20 long. The death never grows taller and ends at most 6 tall.
- [ ] At 1x the snout, an ear and the tail are each visible in the master and in every walk frame.
- [ ] The head meets A011's rules: lowest opaque row 14, centred on x=8 (±1), 1 px clear at left, right and top, 12-13 tall and at most 13 wide, and only its body's palette names.
- [ ] Every other item in contract section 10 holds.

## Delivery

- **Folder:** `implementation/backlog/deliveries/A047-rats/` with the standard files of contract 9.1. There is no `runtime/` folder.
- **checks.json** adds `death_settles` and `icon_bounds_ok`.
- **The mapping lines** in `CLAUDE-A047-PROMPT.txt`:
  - `native/rat/west/01.png -> sprites/enemies/rat.png  24x16 pivot (12,14) draw 1.0`;
  - `native/rat_walk/west/01..04.png -> sprites/enemies/rat_walk_0..3.png  0.1 s loop`;
  - `native/rat_attack/west/01..03.png -> sprites/enemies/rat_attack_0..2.png  0.1 s one-shot`;
  - `native/rat_death/west/01..03.png -> sprites/enemies/rat_death_0..2.png  0.1 s one-shot (3 frames)`;
  - `native/head_rat/none/01.png -> sprites/ui/head_rat.png  16x16 pivot (8,8)`.
  
  The handoff also lists the aliases, and that the game mirrors west to east at runtime.
- **Last step:** `python implementation/backlog/assets.py set A047 approved`, run only after the owner approves in words recorded in `APPROVAL.json`.
