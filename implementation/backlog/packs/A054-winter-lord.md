# A054 - The Winter Lord

- **Status:** integrated
- **For game task:** 0268
- **Dressed by game tasks:** 0255
- **Spec after game task:** 0255
- **Family:** bosses
- **Mode:** A - raw ImageGen sources, Claude reduces them to the 42-colour palette
- **Size of the job:** 22 PNGs: 1 master, 4 animations (16 frames), a 4-frame effect, 1 forecast mark

## What it is for

The Winter Lord is the final boss: the last night of Year 1 (Winter 14). It is a lord of ice whose telegraphed cast freezes every tower within its aura: they stop reloading for a while. Its fall is the year's ending and the credits. The player sees it at night as the most imposing thing the year sends. Through the cast, the aura's reach on the ground and the ice on frozen towers are code (0255). This pack gives the body, the cast pose and the ice shards that burst on each tower the freeze lands on. At 1x it must read as the strongest boss, beside the Giant and the 32px farmer. Its ice must stay matte, not emissive, in the night preview, and it must belong with the frost zombie (A050).

## Deliverables

Final geometry settled by game task 0255: **the Giant's 80x64 standing on (40,60)**. The rows stand as written, with the frames and seconds of the table. **How the game plays them:**
- **The walk:** 48 ticks a tile, a little over half a tile a second, on the four `walk` frames at 0.14 s each, facing the way it moves. It bites the house and gnaws a wall as a walker does. Until 0268 it does that on its walk frames, and `attack` waits for it.
- **The cast:** every twelve seconds of walking it stops for `telegraph_ticks`, two seconds. `cast_0..3` play at 0.1 s each, and frame 3 holds for the rest of the two seconds. Meanwhile the square of ground within three tiles of it is laid in ice by code and edged, and the boss bar flashes. The tick the cast ends, every tower inside that square freezes for four seconds: its reload stops and it does not fire. A frozen tower is drawn whiter than a frost zombie's chill, also by code.
- **`ice_shards`** play nowhere until 0268 emits them at the base of every tower the freeze lands on.
- **Death:** its fall on Winter 14 is the year's ending (0160's path). Until 0268 the body left behind is `winter_lord_death_4`, squashed.
- **Night colours:** winter's night is the bluest of the four, and the icy stand-in reads on the snow by its lighter body and dark outline. Keep the Lord's ice pale and its outline dark, matte and never lit, so it stands off the snow and belongs with A050's frost zombie.

Until 0268 every frame stands in as the Giant gone to ice (`PlaceholderArt`): its cast is the Giant's three-frame wind-up with the last frame held for the fourth, and its forecast mark is the Giant's head, tinted the same, all through 0120's road. Start only when `python implementation/backlog/assets.py next` offers this pack.

| Runtime name | Native canvas | Pivot | Frames / seconds / loop | Notes |
|---|---|---|---|---|
| `enemies/winter_lord` | 80x64 | (40,60) | 1 / 0.1 / static | Identity master, side view facing `west`. Visible 34-46 wide x 46-52 tall: the tallest boss. The staff is held low, so the cast still fits (see the cast row). |
| `enemies/winter_lord_walk_0..3` | 80x64 | (40,60) | 4 / 0.14 / loop | Facing `west`, mirrored at runtime. A slow, heavy, gliding stride: the robe hem and the free arm swing, and the staff marks the step. |
| `enemies/winter_lord_cast_0..3` | 80x64 | (40,60) | 4 / 0.1 / one-shot | The freeze and its telegraph. (0) the staff lifts, (1) the staff overhead with ice crystals growing on its head, (2) both arms high with the crystals at their largest, (3) the held pose at its peak. The view holds frame 3 for the rest of 0255's `telegraph_ticks`, then the freeze lands. No frame is taller than 58. The crystals are matte sprite pixels, with no glow, flash or aura ring. |
| `enemies/winter_lord_attack_0..2` | 80x64 | (40,60) | 3 / 0.1 / one-shot | A staff strike to the west: anticipation, contact, recovery. |
| `enemies/winter_lord_death_0..4` | 80x64 | (40,60) | 5 / 0.12 / one-shot | (0) cracks spread, (1) the crown shatters, (2) the body breaks into ice blocks, (3) it collapses, (4) a low heap of ice and an empty robe, at most 20 tall. |
| `effects/ice_shards_0..3` | 24x20 | (12,18) | 4 / 0.1 / one-shot | Direction `none`. When the freeze lands, the game emits it at the ground contact point (bottom centre of the cell) of every tower the cast freezes. Ice spikes jut from the ground around a tower base: (0) small spikes, (1) the tallest and widest (at most 22 wide x 17 tall: rows 1-17, base on row 17), (2) they crack, (3) a few crumbling stubs. **24x20 is chosen here over the 16x20 rising default, because the shards ring a tower base 19-24 px wide.** |
| `ui/head_winter_lord` | 16x16 | (8,8) | 1 / 1.0 / static | Forecast mark, direction `none`: the face under the icicle crown, turned three-quarter to the left. Fills the box like A011's `head_giant` (rules below). |

- **Every boss frame:**
  - the lowest opaque row is 59;
  - the feet or robe hem are centred on x=40 (±1);
  - a 1 px clear border: only columns 1-78 and rows 1-59 hold pixels;
  - one `content_scale` per strip and the same body height across strips (±1 px);
  - no two frames are identical.
- **Cast:** the staff head is above the crown in frames 1-3.
- **Death:** the visible height never grows from one frame to the next, and the last frame is at most 20 tall.
- **The shards:**
  - a 1 px clear border;
  - the visible area grows from frame 0 to frame 1, and frame 3 is smaller than frame 1;
  - no frame repeats.
- **No metadata points.** The aura is a core query drawn by code.
- **The mark** follows the head rules of A011 (`implementation/backlog/packs/A011-forecast-heads.md`), so it sits in one row with the other heads:
  - a bust in three-quarter view turned to the left, cut flat at the bottom;
  - the lowest opaque row is 14 (row 15 empty), centred on x=8 (±1), with 1 px clear at left, right and top;
  - 14 wide or 14 tall, nothing over 14: it fills the box like `head_giant`;
  - `palette_keys` are the palette names used by this pack's own `winter_lord` frames, which build.py computes read-only from its `native/`;
  - the eyes are `bone` or `bone_dark`, never a colour that looks emissive;
  - `content_anchor_xy` = `(scaled_w // 2, scaled_h - 7)`;
  - there is no 10x10 cut.
- **Aliases:** Claude creates `winter_lord_walk_b` (= walk_2), `winter_lord_telegraph` (= cast_3), `winter_lord_attack` (= attack_1) and `winter_lord_death` (= death_4). Do not deliver them.
- **Delivery paths:**
  - `native/winter_lord/west/01.png`;
  - `native/winter_lord_<walk,cast,attack,death>/west/01..NN.png`;
  - `native/ice_shards/none/01..04.png`;
  - `native/head_winter_lord/none/01.png`.

## Match these

- `sprites/enemies/giant.png`, `giant_walk_0..3.png`, `giant_windup_0..2.png` and `giant_death_0..4.png`:
  - 80x64, pivot (40,60);
  - the master is visible 43x42, windup_2 48x55, and death_4 45x16.
  
  These are the boss scale, outline and telegraph readability to match.
- `assets/art_source/enemies/giant/master.png` (1217x1293): an accepted raw boss source.
- `implementation/backlog/deliveries/A050-frost-zombie/` (once approved): the frost zombie's ice ramp and `ice_shatter`. The Lord's ice and the shards use the same blues and `moon` highlights.
- `sprites/buildings/gun_tower.png` (32x48, pivot (16,44), visible 19x25) and `gun_tower_3.png` (visible 24x28): the towers the shards ring. The shards must not hide a tower.
- `sprites/effects/splash_0..3.png` (20x16) and `flame_0..3.png` (16x20, rising origin (8,18)): the existing water-blue ramp, and how a rising effect sits on its base point.
- `implementation/fhd-player/pilots/2026-10-06/walk-final-mirrored/native-40/walk/down/01.png`: the 32px farmer (visible 16x32).
- `assets/art_source/masters/style-night.png`: how cool colours sit after the night relight. `docs/reference-sheet.png`: the style reference.

## How to make it

1. **Master.**
   - Prompt: BASE + GIANT, with GIANT's subject and old 64x64 target replaced by: "the Winter Lord, final boss, canvas 80x64, contact pivot (40,60), visible body about 40x50 with the staff held low".
   - Add: "A tall, gaunt undead lord of ice. A crown of jagged icicles, a pale blue-grey frozen face with frost in the beard and brows, and a heavy layered robe in deep winter blue with a frost-white fur collar and hem. Ice plates grow on the shoulders. It carries a long staff topped with an ice crystal. Side view facing west (left) in the game's three-quarter camera. Regal and terrible, the year's last enemy, in the same world as the rotting zombies (hints of rot green at the cuffs). Matte ice: no glow, no aura, no snow particles, no ground."
   - Attach:
     - `docs/reference-sheet.png` (style reference);
     - `assets/art_source/enemies/giant/master.png` (boss scale and palette reference, not the shape);
     - the farmer frame (scale reference);
     - the approved A050 master raw if it exists (ice material reference).
   - Make two candidates. Keep the one with the clearest crown and staff silhouette at 1x.
2. **Strips.**
   - Prompt: BASE + GIANT (the motion lines) + ENEMY_STRIP + STRIP, one call per strip: walk 4, cast 4, attack 3, death 5.
   - Attach the accepted master raw as the identity master.
3. **Shards.** Prompt: BASE + FX + STRIP: "matte pale-blue ice spikes jutting up from the ground in a ring around a point, then cracking and crumbling, 4 frames, base origin at the bottom centre. No glow, no white flash."
4. **Mark.** One call, made the way A011's "How to make it" says: its prompt lines, one candidate, `transparent_background=true`.
   - Subject: "the face under the icicle crown, and the fur collar".
   - Image 1: this pack's accepted master raw (identity master).
   - Image 2: `native/winter_lord_walk/west/01.png` from this delivery, enlarged by nearest (colour and in-game identity reference).
   - Image 3: `assets/art_source/ui/wood.png` (icon style reference).
   - If `python implementation/backlog/assets.py status A011` says `approved`, also attach `native/head_giant/none/01.png` from `implementation/backlog/deliveries/A011-forecast-heads/` (framing reference).
5. **Tool argument:** `transparent_background=true` on every call.
6. **Export.**
   - One `content_scale` per strip, set so the standing height matches the master (±1 px).
   - Set the anchors so the feet or hem sit on row 59, centred on x=40. The shards' base sits on row 17, centred on x=12.
   - Render through `import_art.render_source`.
   - The boss strips use no `palette_keys`. The mark follows A011's rule (above).
   - `ice_shards` uses `["ink","ink_soft","water_dark","water","water_light","moon","bone","stone_light","night_light"]`, the same set as A050's `ice_shatter`.

## Review with the owner

`index.html` follows contract 9.5. It shows:

- every animation at 1x and 4x, playing and still, by day and in the night preview;
- the Lord next to the farmer, `sprites/enemies/giant.png` and `walker.png`, feet on one line;
- the A050 frost zombie beside it, if A050 is approved;
- a scene on tiled `sprites/terrain/grass.png`, by day and at night:
  1. the cast with frame 3 held for 1 s;
  2. then `ice_shards` playing at the base of three `gun_tower.png` placed 1-3 cells from it.

The forecast mark is shown at 1x and 4x over `night` #1a1830 and tiled `sprites/ui/panel.png`, beside this pack's master, and in one row with A011's five heads when A011 is approved. The HUD is not relit, so the mark's night preview is labelled "world relight, for reference only".

Questions (in Portuguese):

1. "O Senhor do Inverno parece o chefe mais forte do ano, ao lado do Gigante e do fazendeiro?"
2. "O gelo dele e os estilhaços nas torres continuam foscos, sem parecer luz, na prévia noturna?"
3. "Aprova para integração ou quer mudanças?"

## Acceptance

- [ ] Exactly 22 PNGs, with the canvases, pivots, counts and names of the table. Nothing is facing east.
- [ ] Every boss frame: lowest opaque row 59, feet or hem on x=40 (±1), the 1 px border.
- [ ] The master is 46-52 tall and 34-46 wide: taller than the Giant's 42, and wider than every ordinary master (25). No frame is taller than 58.
- [ ] `checks.json` has `silhouette_distances` (the `silhouette()` of `tools/check_enemy_art.py`, master against `sprites/enemies/giant.png` and the four ordinary masters). Each is at least 16.
- [ ] No walk frame is another shifted by 2 px or less. The walk loop closes.
- [ ] The staff head is above the crown in cast frames 1-3. The death never grows taller and ends at most 20 tall.
- [ ] The shards keep a 1 px border, expand then fade, peak at most 22x17, and use only the listed keys.
- [ ] No glow, aura ring or snowfall is baked in.
- [ ] The mark meets A011's rules: lowest opaque row 14, centred on x=8 (±1), 1 px clear at left, right and top, 14 wide or 14 tall, nothing over 14, and only its body's palette names.
- [ ] Every other item in contract section 10 holds.

## Delivery

- **Folder:** `implementation/backlog/deliveries/A054-winter-lord/` with the standard files of contract 9.1. There is no `runtime/` folder.
- **checks.json** adds:
  - `silhouette_distances`;
  - `silhouette_distinct`;
  - `dominates_ordinary_enemies`;
  - `death_settles`;
  - `effect_expands_then_fades`;
  - `icon_bounds_ok`.
- **The mapping lines** in `CLAUDE-A054-PROMPT.txt`:
  - `native/winter_lord/west/01.png -> sprites/enemies/winter_lord.png  80x64 pivot (40,60) draw 1.0`;
  - `native/winter_lord_walk/west/01..04.png -> sprites/enemies/winter_lord_walk_0..3.png  0.14 s loop`;
  - `native/winter_lord_cast/west/01..04.png -> sprites/enemies/winter_lord_cast_0..3.png  0.1 s one-shot, hold frame 3 for the telegraph`;
  - `native/winter_lord_attack/west/01..03.png -> sprites/enemies/winter_lord_attack_0..2.png  0.1 s one-shot`;
  - `native/winter_lord_death/west/01..05.png -> sprites/enemies/winter_lord_death_0..4.png  0.12 s one-shot`;
  - `native/ice_shards/none/01..04.png -> sprites/effects/ice_shards_0..3.png  24x20 pivot (12,18)  0.1 s one-shot, at each frozen tower's ground point`;
  - `native/head_winter_lord/none/01.png -> sprites/ui/head_winter_lord.png  16x16 pivot (8,8)`.
  
  The handoff also says the aura on the ground and the ice on frozen towers stay 0255's code.
- **Last step:** `python implementation/backlog/assets.py set A054 approved`, run only after the owner approves in words recorded in `APPROVAL.json`.
