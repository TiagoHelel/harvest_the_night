# A046 - The spitter

- **Status:** integrated
- **For game task:** 0260
- **Dressed by game tasks:** 0247
- **Spec after game task:** 0247
- **Family:** enemies
- **Mode:** A - raw ImageGen sources, Claude reduces them to the 42-colour palette
- **Size of the job:** 18 PNGs: 1 master, 3 animations (11 frames), a 2-frame projectile, a 3-frame effect, 1 forecast head

## What it is for

The spitter is summer's ranged zombie. When a tower is 3-5 tiles away, it stops and spits a glob at it every few seconds. When no tower is in range, it walks and bites like a walker. The player sees it at night among the walkers, standing still at the edge of a tower line, and sees its head in the dusk forecast. At 1x, beside the 32px farmer and the walker, its silhouette alone must say "a different zombie": a swollen throat sac and a hunched spitting stance. The spit must stay visible in flight over night grass, and it must not look like a tower shot or fire.

## Deliverables

Final geometry settled by game task 0247. The rows stand as written: the spitter is an ordinary family's 64x48 standing on (32,44), the glob 8x8 round (4,4) and the splat 12x12 round (6,6). **How the game plays them:** with a tower within four tiles (Chebyshev) the spitter stands still and spits at the nearest, every two seconds; with none it walks and bites like a walker. The game shows `spitter_attack_1` (the release) for the three ticks from the moment a glob leaves, `spitter_attack_2` (the recovery) for the five after that, and `spitter_attack_0` (the rear) for the six before the next one; between spits it stands in the master pose, and it walks on the four `walk` frames, 0.125 s each. It faces the tower it spits at, so it is mirrored to face east as often as west. The glob flies at six tiles a second (a four-tile spit is about three quarters of a second), from 22 px over the spitter's feet - until `spit_xy` replaces that - to 14 px up the tower on a 6 px arc, and **the splat plays once where it lands, 14 px up the tower's cell**, over the tower's body. Both are drawn above the night's relight, on the cues' layer the bees and the zaps use, so give them a mid-green body rather than the brightest colours: they must stay readable at night without glowing. Until 0260 the spitter stands in as the walker tinted yellow-green and the glob and the splat are drawn in code (`SpitterArt`) through 0120's road; the forecast head is the walker's head box, tinted the same. Start only when `python implementation/backlog/assets.py next` offers this pack.

| Runtime name | Native canvas | Pivot | Frames / seconds / loop | Notes |
|---|---|---|---|---|
| `enemies/spitter` | 64x48 | (32,44) | 1 / 0.1 / static (like the walker master) | Identity master: standing, facing `west`. Visible 18-24 wide x 28-30 tall. |
| `enemies/spitter_walk_0..3` | 64x48 | (32,44) | 4 / 0.125 / loop | Facing `west`; the game mirrors it to face east. Poses: left contact, passing, right contact, passing. The sac sways. |
| `enemies/spitter_attack_0..2` | 64x48 | (32,44) | 3 / 0.1 / one-shot | The spit, facing `west`. Poses: (0) rears back with the sac swelling; (1) head snaps forward with the mouth wide open (release); (2) settles back to standing (recovery). No glob in any frame: the projectile is a separate sprite. |
| `enemies/spitter_death_0..3` | 64x48 | (32,44) | 4 / 0.1 / one-shot | Facing `west`. Poses: buckles, the sac bursts flat, falls, lies on the ground (at most 16 tall). |
| `effects/spit_0..1` | 8x8 | (4,4) | 2 / 0.1 / loop | The glob in flight. Direction `none`: it is round and non-directional, and the game never rotates it. Visible 4-6 px, centred on (4,4). Frame 1 is a slight squash of frame 0, not a copy. |
| `effects/spit_splat_0..2` | 12x12 | (6,6) | 3 / 0.08 / one-shot | Direction `none`. The glob hits a tower: (0) a small blob, (1) the widest splash with droplets (at most 10 px), (2) shrinking drips. Origin at the centre. |
| `ui/head_spitter` | 16x16 | (8,8) | 1 / 1.0 / static | Forecast head, direction `none`. A bust following A011's head rules (below). |

- **Metadata point:** `spit_xy` on `spitter_attack_1` only. It is the front opaque pixel of the open mouth, in native west-facing coordinates. 0247/0260 start the projectile there, and the game mirrors it with the sprite when the spitter faces east.
- **Every enemy frame:**
  - the lowest opaque row is 43 (the feet stand on the pivot row 44);
  - the feet are centred on x=32 (±1);
  - a 1 px clear border: only columns 1-62 and rows 1-43 hold pixels;
  - one `content_scale` per strip;
  - the standing height is 28-30 px in the master, the walk and attack frame 2.
- **Death:** the visible height never grows from one frame to the next, and the last frame is at most 16 tall.
- **Effects:** a 1 px clear border on every side.
- **Splat area:** the visible area grows from frame 0 to frame 1, and frame 2 is smaller than frame 1.
- **The head** follows the head rules of A011 (`implementation/backlog/packs/A011-forecast-heads.md`), so it sits in one row with the other heads:
  - a bust in three-quarter view turned to the left, cut flat at the bottom;
  - the lowest opaque row is 14 (row 15 empty), centred on x=8 (±1), with 1 px clear at left, right and top;
  - 12-13 tall and at most 13 wide;
  - `palette_keys` are the palette names used by this pack's own `spitter` frames, which build.py computes read-only from its `native/`;
  - the eyes are `bone` or `bone_dark`, never a colour that looks emissive;
  - `content_anchor_xy` = `(scaled_w // 2, scaled_h - 7)`;
  - there is no 10x10 cut.
- **Aliases:** Claude creates `spitter_walk_b` (= walk_2), `spitter_attack` (= attack_1) and `spitter_death` (= death_3). Do not deliver them.
- **Delivery paths:**
  - `native/spitter/west/01.png`;
  - `native/spitter_walk/west/01..04.png`, `native/spitter_attack/west/01..03.png` and `native/spitter_death/west/01..04.png`;
  - `native/spit/none/01..02.png` and `native/spit_splat/none/01..03.png`;
  - `native/head_spitter/none/01.png`.

## Match these

- `docs/reference-sheet.png`: the style reference. Match the camera, the coloured outlines and the night-half zombies.
- `implementation/fhd-player/pilots/2026-10-06/walk-final-mirrored/native-40/walk/down/01.png`: the 32px farmer (40x40, pivot (20,36), visible 16x32). A standing enemy is a little shorter than he is.
- `sprites/enemies/walker.png`, `walker_walk_0..3.png`, `walker_attack_0..2.png` and `walker_death_0..3.png`:
  - 64x48, pivot (32,44);
  - standing visible 15-19 x 28-29, with the feet on row 43;
  - the death ends 26x10.
  
  Match the body scale, the outline weight, the rot-green skin, the muted worn clothes and the contrast.
- `sprites/enemies/runner.png`, `tank.png` and `breaker.png`: the silhouettes the spitter must not resemble.
- `assets/art_source/enemies/walker/master.png` (1086x1448) and `assets/art_source/enemies/walker/walk-v2.png` (1880x836, 4 cells): what an accepted raw master and strip look like. They have a true transparent background, wide gutters and one baseline. The walk-v2 recipe used `content_scale` 0.045 for a 645 px raw standing height, giving 29 native px.
- `sprites/buildings/gun_tower.png` (32x48, visible 19x25): what it spits at. The splat must stay readable on it.
- `sprites/effects/impact_0..2.png` (12x12, pivot (6,6), visible 6-9 px) and `assets/art_source/effects/impact.png` (2172x724 raw strip): the size and density of a small burst.

## How to make it

1. **Master.**
   - Prompt: BASE + WALKER from `implementation/sprites/generation/PROMPTS.md`, with WALKER's old target numbers replaced by: 64x48 canvas, contact pivot (32,44), standing body 29 px.
   - Add: "The spitter: a gaunt, hunched zombie with a huge swollen throat sac and puffed cheeks. The sac is sickly yellow-green with darker veins. Thin arms, a torn work shirt in muted cloth, rot-green skin. Side view facing west (left) in the game's three-quarter camera. The sac is the identity and must read at 29 px tall."
   - Attach:
     - `docs/reference-sheet.png` (style reference);
     - `assets/art_source/enemies/walker/master.png` (a same-world enemy: camera, materials and rot palette, not a character to copy);
     - the farmer frame (scale reference).
   - Make two candidates in two calls. Keep the one whose reduced 1x silhouette is the most distinct.
2. **Strips.**
   - Prompt: BASE + ENEMY_STRIP + STRIP, one call per strip (walk 4, attack 3, death 4), with the poses in the table order.
   - Attach the accepted master raw as the identity master, and `walk-v2.png` as the layout reference.
3. **Spit and splat.**
   - Prompt: BASE + FX + STRIP, one call each.
   - The spit: "a round glob of sickly green spit with a yellow-green highlight and a dark outline, 2 frames, wobbling".
   - The splat: "the same green spit splashing on a surface, 3 frames".
4. **Head.** One call, made the way A011's "How to make it" says: its prompt lines, one candidate, `transparent_background=true`.
   - Subject: "head, puffed cheeks and the swollen throat sac".
   - Image 1: this pack's accepted master raw (identity master).
   - Image 2: `native/spitter_walk/west/01.png` from this delivery, enlarged by nearest (colour and in-game identity reference).
   - Image 3: `assets/art_source/ui/wood.png` (icon style reference).
   - If `python implementation/backlog/assets.py status A011` says `approved`, also attach `native/head_walker/none/01.png` from `implementation/backlog/deliveries/A011-forecast-heads/` (framing reference).
5. **Tool argument:** `transparent_background=true` on every call. Use only the arguments the tool exposes.
6. **Export.**
   - Cut every cell by its measured alpha box.
   - Give each strip one `content_scale`, chosen so its standing (or recovery) pose is 29 native px. Record the raw and native heights in review-log.txt.
   - Set `content_anchor_xy` per frame so that the centre of the feet lands on (32,44) and the lowest opaque row is 43.
   - Render through `import_art.render_source`.
   - Omit `palette_keys` for the body and the master. The head follows A011's rule (above).
   - Spit and splat use `palette_keys` `["ink","rot_dark","rot","leaf_dark","leaf","leaf_light","grass_dark","grass","grass_light","gold_light"]`.

## Review with the owner

`index.html` follows contract 9.5. It shows:

- every animation at 1x and 4x, playing and as a still strip, by day and in the night preview, next to the farmer frame and `sprites/enemies/walker.png` with the feet on one line;
- a scene on tiled `sprites/terrain/grass.png`, by day and at night: the spitter four tiles west of `sprites/buildings/gun_tower.png`, the spit at three points along its flight, and the splat on the tower;
- `spit_xy` marked on an overlay.

The forecast head is shown at 1x and 4x over `night` #1a1830 and tiled `sprites/ui/panel.png`, beside this pack's master, and in one row with A011's five heads when A011 is approved. The HUD is not relit, so the head's night preview is labelled "world relight, for reference only".

Questions (in Portuguese):

1. "O cuspidor se distingue do andarilho só pela silhueta, a 1x e na prévia noturna?"
2. "A cuspida em voo e o respingo na torre ficam visíveis à noite sem parecer tiro de torre ou fogo?"
3. "Aprova para integração ou quer mudanças?"

## Acceptance

- [ ] Exactly 18 PNGs, with the canvases, pivots, frame counts and names of the table. Nothing is facing east.
- [ ] Every enemy frame: lowest opaque row 43, feet on x=32 (±1), the 1 px clear border, no two frames identical.
- [ ] No walk frame is another walk frame shifted vertically by 2 px or less.
- [ ] The standing height is 28-30 in the master, the walk and attack frame 2, and each strip has one `content_scale`.
- [ ] The death never grows taller and ends at most 16 tall, lying on the ground.
- [ ] `checks.json` has `silhouette_distances`: the master's 16x16 occupancy (the `silhouette()` of `tools/check_enemy_art.py`) against `sprites/enemies/{walker,runner,tank,breaker}.png`. Each distance is at least 16.
- [ ] Effects keep the 1 px border. The splat expands and then fades. The spit's visible size is 4-6 px.
- [ ] The head meets A011's rules: lowest opaque row 14, centred on x=8 (±1), 1 px clear at left, right and top, 12-13 tall and at most 13 wide, and only its body's palette names.
- [ ] `spit_xy` sits on an opaque pixel of `spitter_attack_1`.
- [ ] Every other item in contract section 10 holds: binary alpha, no baked shadow, ground, glow, night or text, Mode A previews from the importer's own recipe, and identical rebuilds.

## Delivery

- **Folder:** `implementation/backlog/deliveries/A046-spitter/` with the standard files of contract 9.1. There is no `runtime/` folder, because this is not a 2x pack.
- **checks.json** adds `silhouette_distances`, `silhouette_distinct`, `death_settles`, `effect_expands_then_fades` and `icon_bounds_ok`.
- **The mapping lines** in `CLAUDE-A046-PROMPT.txt`:
  - `native/spitter/west/01.png -> sprites/enemies/spitter.png`;
  - `native/spitter_walk/west/01..04.png -> sprites/enemies/spitter_walk_0..3.png  64x48 pivot (32,44) draw 1.0  0.125 s loop`;
  - `native/spitter_attack/west/01..03.png -> sprites/enemies/spitter_attack_0..2.png  0.1 s one-shot  spit_xy on frame 1`;
  - `native/spitter_death/west/01..04.png -> sprites/enemies/spitter_death_0..3.png  0.1 s one-shot`;
  - `native/spit/none/01..02.png -> sprites/effects/spit_0..1.png  8x8 pivot (4,4)  0.1 s loop`;
  - `native/spit_splat/none/01..03.png -> sprites/effects/spit_splat_0..2.png  12x12 pivot (6,6)  0.08 s one-shot`;
  - `native/head_spitter/none/01.png -> sprites/ui/head_spitter.png  16x16 pivot (8,8)`.
  
  The handoff also lists the three aliases, and that the game mirrors west to east at runtime.
- **Last step:** `python implementation/backlog/assets.py set A046 approved`, run only after the owner approves in words recorded in `APPROVAL.json`.
