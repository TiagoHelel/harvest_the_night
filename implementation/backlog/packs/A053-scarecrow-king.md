# A053 - The Scarecrow King

- **Status:** integrated
- **For game task:** 0267
- **Dressed by game tasks:** 0254
- **Spec after game task:** 0254
- **Family:** bosses
- **Mode:** A - raw ImageGen sources, Claude reduces them to the 42-colour palette
- **Size of the job:** 18 PNGs: 1 master, 4 animations (16 frames), 1 forecast mark

## What it is for

The Scarecrow King is autumn's boss (Autumn 14). It walks the flow field like a walker. Every so often it stops, raises its arms and casts, and a flock of crows (A048's crows, separate entities) rises around it. It tests cover in the air and care for the field. The player sees it at night towering over the zombies, and the cast is its telegraph: a pose that must read at 1x by day and in the night preview. Two other scarecrows exist in the game: the friendly porch guardian (A003) and the straw decoy defence (A037). The King must never be confused with either. It is dark, crowned and hostile. The trophy is A056's.

## Deliverables

Final geometry settled by game task 0254: **the Giant's 80x64 standing on (40,60)**. The rows stand as written, with the frames and seconds of the table. **How the game plays them:**
- **The walk:** 42 ticks a tile, a little under three quarters of a tile a second, on the four `walk` frames at 0.14 s each, facing the way it moves. It bites the house and gnaws a wall as a walker does. Until 0267 it does that on its walk frames, and `attack` waits for it.
- **The cast:** every ten seconds of walking it stops for `telegraph_ticks`, two seconds. `cast_0..3` play at 0.1 s each, and frame 3 holds for the rest of the two seconds. Meanwhile a ring drawn in code closes on each of the six cells the flock will rise on, and the boss bar flashes. The tick the cast ends, six crows - A048's, separate bodies - rise on those cells: two tiles out round the cell it cast on (west, east, north, south, then the corners), clipped to the map. They fly for the field. No more than eighteen rise in a night; after that it only walks.
- **Death:** until 0267 the body left behind is `scarecrow_king_death_4`, squashed.
- **Night colours:** autumn's night is a brown dusk. The straw-dark stand-in reads on it as yellow-green over the ground, and the crows' blue-black reads against both. Keep the King's straw and coat darker than A003's porch guardian and A037's decoy, so the crowned one never reads as either.

Until 0267 every frame stands in as the Giant gone to dark straw (`PlaceholderArt`): its cast is the Giant's three-frame wind-up with the last frame held for the fourth, and its forecast mark is the Giant's head, tinted the same, all through 0120's road. Start only when `python implementation/backlog/assets.py next` offers this pack.

| Runtime name | Native canvas | Pivot | Frames / seconds / loop | Notes |
|---|---|---|---|---|
| `enemies/scarecrow_king` | 80x64 | (40,60) | 1 / 0.1 / static | Identity master, side view facing `west`. Visible 30-44 wide x 44-50 tall: taller than the Giant (42), thinner and spikier. Leave room above the head: the raised arms of the cast reach at most 58 tall. |
| `enemies/scarecrow_king_walk_0..3` | 80x64 | (40,60) | 4 / 0.14 / loop | Facing `west`, mirrored at runtime. A lurching stilt-legged stride, with the coat tails and straw swaying. |
| `enemies/scarecrow_king_cast_0..3` | 80x64 | (40,60) | 4 / 0.1 / one-shot | The summon and its telegraph. (0) the arms sweep out, (1) the arms rise and the coat flares, (2) the arms high and the head thrown back with straw bursting from the cuffs, (3) the held summoning pose. The view holds frame 3 for the rest of 0254's `telegraph_ticks`. No crows, feathers in the air or magic are baked in. |
| `enemies/scarecrow_king_attack_0..2` | 80x64 | (40,60) | 3 / 0.1 / one-shot | A raking sweep of its long twig-clawed hand to the west: anticipation, contact, recovery. |
| `enemies/scarecrow_king_death_0..4` | 80x64 | (40,60) | 5 / 0.12 / one-shot | (0) staggers with straw spilling, (1) the crown falls, (2) the frame buckles, (3) it collapses, (4) a low pile of straw, coat and sticks, at most 20 tall. |
| `ui/head_scarecrow_king` | 16x16 | (8,8) | 1 / 1.0 / static | Forecast mark, direction `none`: the sack head with its stitched grin and the twig crown, turned three-quarter to the left. Fills the box like A011's `head_giant` (rules below). |

- **Every boss frame:**
  - the lowest opaque row is 59;
  - the feet are centred on x=40 (±1);
  - a 1 px clear border: only columns 1-78 and rows 1-59 hold pixels;
  - one `content_scale` per strip and the same body height across strips (±1 px);
  - no two frames are identical.
- **Cast:** the arms end above the head in frames 2 and 3, and no cast frame is taller than 58.
- **Death:** the visible height never grows from one frame to the next, and the last frame is at most 20 tall.
- **No metadata points.** The crows spawn on 0254's listed cells, not from the sprite.
- **The mark** follows the head rules of A011 (`implementation/backlog/packs/A011-forecast-heads.md`), so it sits in one row with the other heads:
  - a bust in three-quarter view turned to the left, cut flat at the bottom;
  - the lowest opaque row is 14 (row 15 empty), centred on x=8 (±1), with 1 px clear at left, right and top;
  - 14 wide or 14 tall, nothing over 14: it fills the box like `head_giant`;
  - `palette_keys` are the palette names used by this pack's own `scarecrow_king` frames, which build.py computes read-only from its `native/`;
  - the eyes are `bone` or `bone_dark`, never a colour that looks emissive;
  - `content_anchor_xy` = `(scaled_w // 2, scaled_h - 7)`;
  - there is no 10x10 cut.
- **Aliases:** Claude creates `scarecrow_king_walk_b` (= walk_2), `scarecrow_king_telegraph` (= cast_3), `scarecrow_king_attack` (= attack_1) and `scarecrow_king_death` (= death_4). Do not deliver them.
- **Delivery paths:**
  - `native/scarecrow_king/west/01.png`;
  - `native/scarecrow_king_<walk,cast,attack,death>/west/01..NN.png`;
  - `native/head_scarecrow_king/none/01.png`.

## Match these

- `sprites/enemies/giant.png`, `giant_walk_0..3.png`, `giant_windup_0..2.png` and `giant_death_0..4.png`:
  - 80x64, pivot (40,60);
  - the master is visible 43x42, windup_2 48x55, and death_4 45x16.
  
  These are the boss scale, outline and readability to match.
- `assets/art_source/enemies/giant/master.png` (1217x1293): an accepted raw boss source.
- **The other scarecrows to stay distinct from.** Open the latest of these that exists:
  - `implementation/backlog/packs/A003-guardian.md` and `implementation/backlog/deliveries/A003-guardian/` (the porch guardian: friendly, straw hat);
  - `implementation/backlog/packs/A037-decoy.md` and `implementation/backlog/deliveries/A037-decoy/` (the straw decoy).
  
  If neither delivery exists yet, follow the identity lines below, which avoid the straw hat and the plain cross-post.
- `implementation/backlog/deliveries/A048-crow/` (once approved): the crows it raises. Match their blue-black feather ramp in the King's feather trim.
- `sprites/crops/wheat_3.png` and `corn_3.png`: the straw and husk colours (gold ramp).
- `implementation/fhd-player/pilots/2026-10-06/walk-final-mirrored/native-40/walk/down/01.png`: the 32px farmer (visible 16x32).
- `docs/reference-sheet.png`: the style reference.

## How to make it

1. **Master.**
   - Prompt: BASE + GIANT, with GIANT's subject and old 64x64 target replaced by: "the Scarecrow King boss, canvas 80x64, contact pivot (40,60), visible body about 38x48, arms down".
   - Add: "A towering, hostile scarecrow lord. A burlap sack head with a stitched jagged grin and two dark hollow eyes, under a crown of twisted dry branches and corn husks. A long tattered dark coat in violet-black and dark red, with crow-feather trim on the shoulders. Straw bursts from the cuffs, collar and hem. Long thin stick limbs with twig claws, walking on two stilt-like legs. Side view facing west (left) in the game's three-quarter camera. Menacing autumn harvest horror for a cozy farm. No straw hat, no pole, no birds, no glow."
   - Attach:
     - `docs/reference-sheet.png` (style reference);
     - `assets/art_source/enemies/giant/master.png` (boss scale and palette reference, not the shape);
     - the farmer frame (scale reference);
     - the approved A003 master if it exists (marked "a friendly scarecrow this boss must NOT resemble").
   - Make two candidates. Keep the one with the clearest crown and sack-head silhouette at 1x.
2. **Strips.**
   - Prompt: BASE + GIANT (the motion lines) + ENEMY_STRIP + STRIP, one call per strip: walk 4, cast 4, attack 3, death 5.
   - Attach the accepted master raw as the identity master.
3. **Mark.** One call, made the way A011's "How to make it" says: its prompt lines, one candidate, `transparent_background=true`.
   - Subject: "the sack head with its stitched grin, the twig crown and the feather collar".
   - Image 1: this pack's accepted master raw (identity master).
   - Image 2: `native/scarecrow_king_walk/west/01.png` from this delivery, enlarged by nearest (colour and in-game identity reference).
   - Image 3: `assets/art_source/ui/wood.png` (icon style reference).
   - If `python implementation/backlog/assets.py status A011` says `approved`, also attach `native/head_giant/none/01.png` from `implementation/backlog/deliveries/A011-forecast-heads/` (framing reference).
4. **Tool argument:** `transparent_background=true` on every call.
5. **Export.**
   - One `content_scale` per strip, set so the standing height matches the master (±1 px).
   - Set the anchors so the feet sit on row 59, centred on x=40.
   - Render through `import_art.render_source`.
   - The boss strips use no `palette_keys`. The mark follows A011's rule (above).

## Review with the owner

`index.html` follows contract 9.5. It shows:

- every animation at 1x and 4x, playing and still, by day and in the night preview;
- the King next to the farmer, `sprites/enemies/giant.png` and `walker.png`, feet on one line;
- the A003 guardian and the A037 decoy beside it, when their deliveries exist;
- a scene on tiled `sprites/terrain/grass.png`, by day and at night: the cast with frame 3 held for 1 s. If A048 is approved, also show its `crow_fly` frames at three cells around the King.

The forecast mark is shown at 1x and 4x over `night` #1a1830 and tiled `sprites/ui/panel.png`, beside this pack's master, and in one row with A011's five heads when A011 is approved. The HUD is not relit, so the mark's night preview is labelled "world relight, for reference only".

Questions (in Portuguese):

1. "O Rei Espantalho é inconfundível com o espantalho da varanda e com o espantalho-isca, a 1x?"
2. "O gesto de invocar (braços erguidos) avisa claramente que os corvos vão subir, de dia e de noite?"
3. "Aprova para integração ou quer mudanças?"

## Acceptance

- [ ] Exactly 18 PNGs, with the canvases, pivots, counts and names of the table. Nothing is facing east.
- [ ] Every boss frame: lowest opaque row 59, feet on x=40 (±1), the 1 px border.
- [ ] The master is 44-50 tall and 30-44 wide: taller than the Giant's 42, and wider than every ordinary enemy master (25). No frame is taller than 58.
- [ ] `checks.json` has `silhouette_distances` (the `silhouette()` of `tools/check_enemy_art.py`, master against `sprites/enemies/giant.png` and the four ordinary masters). Each is at least 16.
- [ ] No walk frame is another shifted by 2 px or less. The walk loop closes.
- [ ] The cast arms are above the head in frames 2-3. The death never grows taller and ends at most 20 tall.
- [ ] No crows, magic, glow or ground is baked in.
- [ ] The mark meets A011's rules: lowest opaque row 14, centred on x=8 (±1), 1 px clear at left, right and top, 14 wide or 14 tall, nothing over 14, and only its body's palette names.
- [ ] Every other item in contract section 10 holds.

## Delivery

- **Folder:** `implementation/backlog/deliveries/A053-scarecrow-king/` with the standard files of contract 9.1. There is no `runtime/` folder.
- **checks.json** adds:
  - `silhouette_distances`;
  - `silhouette_distinct`;
  - `dominates_ordinary_enemies`;
  - `death_settles`;
  - `icon_bounds_ok`.
- **The mapping lines** in `CLAUDE-A053-PROMPT.txt`:
  - `native/scarecrow_king/west/01.png -> sprites/enemies/scarecrow_king.png  80x64 pivot (40,60) draw 1.0`;
  - `native/scarecrow_king_walk/west/01..04.png -> sprites/enemies/scarecrow_king_walk_0..3.png  0.14 s loop`;
  - `native/scarecrow_king_cast/west/01..04.png -> sprites/enemies/scarecrow_king_cast_0..3.png  0.1 s one-shot, hold frame 3 for the telegraph`;
  - `native/scarecrow_king_attack/west/01..03.png -> sprites/enemies/scarecrow_king_attack_0..2.png  0.1 s one-shot`;
  - `native/scarecrow_king_death/west/01..05.png -> sprites/enemies/scarecrow_king_death_0..4.png  0.12 s one-shot`;
  - `native/head_scarecrow_king/none/01.png -> sprites/ui/head_scarecrow_king.png  16x16 pivot (8,8)`.
- **Last step:** `python implementation/backlog/assets.py set A053 approved`, run only after the owner approves in words recorded in `APPROVAL.json`.
