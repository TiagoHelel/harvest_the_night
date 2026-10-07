# A050 - The frost zombie

- **Status:** todo
- **For game task:** 0264
- **Dressed by game tasks:** 0251
- **Spec after game task:** 0251
- **Family:** enemies
- **Mode:** A - raw ImageGen sources, Claude reduces them to the 42-colour palette
- **Size of the job:** 17 PNGs: 1 master, 3 animations (11 frames), a 4-frame effect, 1 forecast head

## What it is for

The frost zombie is winter's first new enemy. Its death is the attack: it bursts into ice, and every tower within 1-3 tiles reloads slowly for a while. The player sees it at night shambling in the winter crowd, and sees an ice burst wherever one dies. Killing one right under the tower line now costs something. The frost tint on chilled towers is code (0251), not art. At 1x it must read as a zombie crusted in ice, clearly colder than the walker, and the ice must not look emissive after the night relight.

## Deliverables

The table is provisional: game task 0251 settles the final canvas/footprint/states and updates it; start only when `python implementation/backlog/assets.py next` offers this pack.

| Runtime name | Native canvas | Pivot | Frames / seconds / loop | Notes |
|---|---|---|---|---|
| `enemies/frost_zombie` | 64x48 | (32,44) | 1 / 0.1 / static | Identity master, standing, facing `west`. Visible 18-24 wide x 28-30 tall, with ice spikes on the shoulders and back. |
| `enemies/frost_zombie_walk_0..3` | 64x48 | (32,44) | 4 / 0.125 / loop | Facing `west`, mirrored at runtime. A stiff, frozen-jointed shamble. |
| `enemies/frost_zombie_attack_0..2` | 64x48 | (32,44) | 3 / 0.1 / one-shot | An icy claw swipe to the west: anticipation, contact, recovery. |
| `enemies/frost_zombie_death_0..3` | 64x48 | (32,44) | 4 / 0.1 / one-shot | (0) freezes stiff with cracks, (1) cracks open, (2) breaks apart and falls, (3) a low heap of ice chunks and rags (at most 16 tall). |
| `effects/ice_shatter_0..3` | 24x24 | (12,12) | 4 / 0.08 / one-shot | Direction `none`. The burst played on its death. Origin at the centre. The game emits it at the zombie's ground point minus 12 px (body centre), as `impact` is emitted today. (0) a cracked core, (1) an outward burst of ice shards at its widest (at most 22 wide and 18 tall), (2) shards flying apart and thinning, (3) a few small shards. **The canvas is the flare size, explicitly chosen here over the 12x12 burst default, because the burst covers a whole body.** |
| `ui/head_frost_zombie` | 16x16 | (8,8) | 1 / 1.0 / static | Forecast head, direction `none`. A bust following A011's head rules (below). |

- **Every enemy frame:**
  - the lowest opaque row is 43;
  - the feet are centred on x=32 (±1);
  - a 1 px clear border: only columns 1-62 and rows 1-43 hold pixels;
  - one `content_scale` per strip;
  - the standing height is 28-30 in the master, the walk and attack frame 2;
  - no two frames are identical.
- **Death:** the visible height never grows from one frame to the next, and the last frame is at most 16 tall.
- **The shatter:**
  - a 1 px clear border on every side;
  - its visible area grows from frame 0 to frame 1, and frame 3 is smaller than frame 1;
  - no frame repeats.
- **The head** follows the head rules of A011 (`implementation/backlog/packs/A011-forecast-heads.md`), so it sits in one row with the other heads:
  - a bust in three-quarter view turned to the left, cut flat at the bottom;
  - the lowest opaque row is 14 (row 15 empty), centred on x=8 (±1), with 1 px clear at left, right and top;
  - 12-13 tall and at most 13 wide;
  - `palette_keys` are the palette names used by this pack's own `frost_zombie` frames, which build.py computes read-only from its `native/`;
  - the eyes are `bone` or `bone_dark`, never a colour that looks emissive;
  - `content_anchor_xy` = `(scaled_w // 2, scaled_h - 7)`;
  - there is no 10x10 cut.
- **Aliases:** Claude creates `frost_zombie_walk_b` (= walk_2), `frost_zombie_attack` (= attack_1) and `frost_zombie_death` (= death_3). Do not deliver them.
- **Delivery paths:**
  - `native/frost_zombie/west/01.png`;
  - `native/frost_zombie_walk/west/01..04.png`, `native/frost_zombie_attack/west/01..03.png` and `native/frost_zombie_death/west/01..04.png`;
  - `native/ice_shatter/none/01..04.png`;
  - `native/head_frost_zombie/none/01.png`.

## Match these

- `sprites/enemies/walker.png` and `walker_walk_0..3.png`, `walker_attack_0..2.png` and `walker_death_0..3.png`:
  - 64x48, pivot (32,44);
  - standing visible 15-19 x 28-29, feet on row 43;
  - the death ends 26x10.
  
  Match the scale, the outline and the contrast. The frost zombie is the same rotting body, gone cold.
- `sprites/enemies/runner.png`, `tank.png` and `breaker.png`: the silhouettes it must not resemble. The shoulder and back spikes carry the difference.
- `sprites/effects/flare_0..3.png` (24x24, pivot (12,12), visible 10-22 px): the size of a large burst. `sprites/effects/impact_0..2.png` (12x12): the small burst it outgrows.
- `sprites/buildings/gun_tower.png` (32x48, visible 19x25): the shatter will play beside towers. It must stay readable against a tower and must not hide one.
- `sprites/effects/splash_0..3.png` (20x16): the water-blue ramp already in use. Ice uses the same blues with `moon` highlights.
- `implementation/fhd-player/pilots/2026-10-06/walk-final-mirrored/native-40/walk/down/01.png`: the 32px farmer (visible 16x32).
- `assets/art_source/enemies/walker/master.png`, `walk-v2.png` and `assets/art_source/effects/flare.png` (2172x724): accepted raw sources. `docs/reference-sheet.png`: the style reference.

## How to make it

1. **Master.**
   - Prompt: BASE + WALKER, with WALKER's old targets replaced by: 64x48 canvas, contact pivot (32,44), standing body 29 px.
   - Add: "The frost zombie: a shambling zombie in torn winter rags, crusted with ice. There are jagged ice spikes on the shoulders and back, frost-white hair, and icicles hanging from the arms. Its skin is pale blue-grey with rot-green showing through. Side view facing west (left). The ice is matte and pale blue with white edge highlights. It does not glow."
   - Attach `docs/reference-sheet.png` (style reference), `assets/art_source/enemies/walker/master.png` (same-world enemy) and the farmer frame (scale reference).
   - Make two candidates. Keep the one whose 1x silhouette shows the spikes.
2. **Strips.**
   - Prompt: BASE + ENEMY_STRIP + STRIP, one call per strip (walk 4, attack 3, death 4).
   - Attach the accepted master raw as the identity master.
   - The death strip ends in a heap of ice chunks, not a puddle.
3. **Shatter.** Prompt: BASE + FX + STRIP: "an ice shatter burst, 4 frames, pale blue and white matte ice shards bursting outward from a cracked centre and scattering. No glow, no white flash, no bloom."
4. **Head.** One call, made the way A011's "How to make it" says: its prompt lines, one candidate, `transparent_background=true`.
   - Subject: "the face, the frosted hair and a shoulder spike".
   - Image 1: this pack's accepted master raw (identity master).
   - Image 2: `native/frost_zombie_walk/west/01.png` from this delivery, enlarged by nearest (colour and in-game identity reference).
   - Image 3: `assets/art_source/ui/wood.png` (icon style reference).
   - If `python implementation/backlog/assets.py status A011` says `approved`, also attach `native/head_walker/none/01.png` from `implementation/backlog/deliveries/A011-forecast-heads/` (framing reference).
5. **Tool argument:** `transparent_background=true` on every call.
6. **Export.**
   - One `content_scale` per strip (standing pose = 29 px, shatter frame 1 = at most 22 wide).
   - Set the anchors for (32,44) with the lowest row 43, and centre the shatter on (12,12).
   - Render through `import_art.render_source`.
   - The body strips use no `palette_keys`. The head follows A011's rule (above).
   - `ice_shatter` uses `["ink","ink_soft","water_dark","water","water_light","moon","bone","stone_light","night_light"]`.

## Review with the owner

`index.html` follows contract 9.5. It shows:

- every animation at 1x and 4x, playing and still, by day and in the night preview, next to the farmer and the walker;
- a scene on tiled `sprites/terrain/grass.png`, by day and at night: the frost zombie dying one tile west of `gun_tower.png`, with the death strip and the shatter playing together, the shatter centred 12 px above the zombie's pivot.

The forecast head is shown at 1x and 4x over `night` #1a1830 and tiled `sprites/ui/panel.png`, beside this pack's master, and in one row with A011's five heads when A011 is approved. The HUD is not relit, so the head's night preview is labelled "world relight, for reference only".

Questions (in Portuguese):

1. "O zumbi de gelo parece claramente mais frio que o andarilho, e o gelo não parece brilhar na prévia noturna?"
2. "A explosão de gelo ao lado da torre chama atenção sem esconder a torre?"
3. "Aprova para integração ou quer mudanças?"

## Acceptance

- [ ] Exactly 17 PNGs, with the canvases, pivots, counts and names of the table. Nothing is facing east.
- [ ] Every enemy frame: lowest opaque row 43, feet on x=32 (±1), the 1 px border, standing height 28-30.
- [ ] No walk frame is another shifted by 2 px or less. The walk loop closes.
- [ ] The death never grows taller and ends at most 16 tall.
- [ ] `checks.json` `silhouette_distances` (master against `sprites/enemies/{walker,runner,tank,breaker}.png`, the `silhouette()` of `tools/check_enemy_art.py`) are each at least 16.
- [ ] The shatter keeps a 1 px border, expands then fades, peaks at most 22x18, and uses only the listed keys.
- [ ] The head meets A011's rules: lowest opaque row 14, centred on x=8 (±1), 1 px clear at left, right and top, 12-13 tall and at most 13 wide, and only its body's palette names.
- [ ] Every other item in contract section 10 holds.

## Delivery

- **Folder:** `implementation/backlog/deliveries/A050-frost-zombie/` with the standard files of contract 9.1. There is no `runtime/` folder.
- **checks.json** adds:
  - `silhouette_distances`;
  - `silhouette_distinct`;
  - `death_settles`;
  - `effect_expands_then_fades`;
  - `icon_bounds_ok`.
- **The mapping lines** in `CLAUDE-A050-PROMPT.txt`:
  - `native/frost_zombie/west/01.png -> sprites/enemies/frost_zombie.png  64x48 pivot (32,44) draw 1.0`;
  - `native/frost_zombie_walk/west/01..04.png -> sprites/enemies/frost_zombie_walk_0..3.png  0.125 s loop`;
  - `native/frost_zombie_attack/west/01..03.png -> sprites/enemies/frost_zombie_attack_0..2.png  0.1 s one-shot`;
  - `native/frost_zombie_death/west/01..04.png -> sprites/enemies/frost_zombie_death_0..3.png  0.1 s one-shot`;
  - `native/ice_shatter/none/01..04.png -> sprites/effects/ice_shatter_0..3.png  24x24 pivot (12,12)  0.08 s one-shot, emitted at the death point minus 12 px`;
  - `native/head_frost_zombie/none/01.png -> sprites/ui/head_frost_zombie.png  16x16 pivot (8,8)`.
- **Last step:** `python implementation/backlog/assets.py set A050 approved`, run only after the owner approves in words recorded in `APPROVAL.json`.
