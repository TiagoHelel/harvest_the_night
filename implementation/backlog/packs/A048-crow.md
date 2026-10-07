# A048 - The crow

- **Status:** todo
- **For game task:** 0262
- **Dressed by game tasks:** 0249
- **Spec after game task:** 0249
- **Family:** enemies
- **Mode:** A - raw ImageGen sources, Claude reduces them to the 42-colour palette
- **Size of the job:** 14 PNGs: 1 master, 4 animations (12 frames), 1 forecast head

## What it is for

The crow is autumn's flyer. It is the first enemy that does not walk: it flies straight over walls and mines to the nearest planted plot, lands, pecks the crop away, and takes off for the next one. The Scarecrow King (A053) also raises flocks of these same crows. The player sees crows at night crossing the defences in the air, with a code-drawn shadow on the ground under them, then landed on the field. It is the **flying exception** to the enemy rules:

- it is still side view facing west, mirrored at runtime;
- its flight height and its shadow are code (0249), so nothing in the art is lifted or shadowed.

At 1x it must read as "in the air" in flight and as "on the field" when landed, and its black feathers must not vanish in the night preview.

## Deliverables

The table is provisional: game task 0249 settles the final canvas/footprint/states and updates it; start only when `python implementation/backlog/assets.py next` offers this pack.

| Runtime name | Native canvas | Pivot | Frames / seconds / loop | Notes |
|---|---|---|---|---|
| `enemies/crow` | 32x24 | (16,22) | 1 / 0.1 / static | Identity master: standing on the ground with its wings folded, facing `west`. Visible 13-16 long x 10-12 tall. Grounded. |
| `enemies/crow_fly_0..3` | 32x24 | (16,22) | 4 / 0.1 / loop | Facing `west`. (0) wings up, (1) wings level on the downstroke, (2) wings fully down, (3) wings level on the upstroke. The feet are tucked. Not grounded (see the flight rule). |
| `enemies/crow_land_0` | 32x24 | (16,22) | 1 / 0.1 / static | Touchdown and take-off, facing `west`: the wings are raised and spread, and the legs reach down with the feet touching. Grounded. |
| `enemies/crow_peck_0..2` | 32x24 | (16,22) | 3 / 0.12 / loop | Pecking a crop, facing `west`: (0) head up, (1) the beak down at ground level, (2) the head tugging back up. The feet never move. Grounded. No crop is drawn. |
| `enemies/crow_death_0..3` | 32x24 | (16,22) | 4 / 0.1 / one-shot | The fall, facing `west`: (0) hit, feathers ruffled, wings crumpled, (1) tumbling, (2) tumbling lower, (3) lying on its side on the ground, at most 8 tall. Only frame 3 is grounded. |
| `ui/head_crow` | 16x16 | (8,8) | 1 / 1.0 / static | Forecast head, direction `none`. A bust following A011's head rules (below). |

- **Grounded frames** (the master, `land_0`, `peck_0..2` and `death_3`):
  - the lowest opaque row is 21 (the feet stand on the pivot row 22);
  - the feet are centred on x=16 (±1).
- **Flight rule** (`fly_0..3` and `death_0..2`):
  - nothing on or below row 22;
  - in the fly frames, the torso and head occupy the same rows (±1) and are centred on x=16 (±1);
  - only the wings move;
  - draw the bird at ground level as if standing. 0249's height offset lifts the whole sprite, and `sprites/actors/shadow.png` is drawn by code at the pivot.
- **Every frame:**
  - a 1 px clear border: only columns 1-30 and rows 1-21 hold pixels;
  - no two frames are identical;
  - one `content_scale` per strip, with the body (head to tail) 13-16 px long in every strip.
- **Death:** the visible height never grows from one frame to the next.
- **The head** follows the head rules of A011 (`implementation/backlog/packs/A011-forecast-heads.md`), so it sits in one row with the other heads:
  - a bust in three-quarter view turned to the left, cut flat at the bottom;
  - the lowest opaque row is 14 (row 15 empty), centred on x=8 (±1), with 1 px clear at left, right and top;
  - 12-13 tall and at most 13 wide;
  - `palette_keys` are the palette names used by this pack's own `crow` frames, which build.py computes read-only from its `native/`;
  - the eyes are `bone` or `bone_dark`, never a colour that looks emissive;
  - `content_anchor_xy` = `(scaled_w // 2, scaled_h - 7)`;
  - there is no 10x10 cut.
- **Aliases:** Claude creates `crow_walk_b` (= fly_2), `crow_attack` (= peck_1, used when it bites the house) and `crow_death` (= death_3). Do not deliver them.
- **Delivery paths:**
  - `native/crow/west/01.png`;
  - `native/crow_fly/west/01..04.png`;
  - `native/crow_land/west/01.png`;
  - `native/crow_peck/west/01..03.png`;
  - `native/crow_death/west/01..04.png`;
  - `native/head_crow/none/01.png`.

## Match these

- `implementation/fhd-player/pilots/2026-10-06/walk-final-mirrored/native-40/walk/down/01.png`: the 32px farmer (visible 16x32). A standing crow comes to about a third of his height.
- `sprites/enemies/walker.png` (64x48, visible 15x29): match the undead palette, outline weight and contrast. The crow is the same world.
- `sprites/actors/shadow.png` (20x8, visible 18x3): the code shadow drawn under a flying crow. The wingspan in `fly_2` must not be much wider than it (at most 26 px).
- `sprites/crops/wheat_3.png` (16x16, visible 9x12), `sprites/crops/corn_3.png` (16x24, visible 12x20) and `carrot_3.png`: the ripe crops it lands on. The review shows it pecking them.
- `sprites/buildings/wall.png` (16x32, pivot (8,28), visible 6x15) and `sprites/buildings/wall_join_10.png`: the wall line it flies over in the review.
- `sprites/props/chicken.png` (24x24, visible 11x12): the only bird in the game today. The crow must never be mistaken for it: it is black, lean and sharp-beaked.
- `docs/reference-sheet.png`: the style reference.

## How to make it

1. **Master.**
   - Prompt: BASE + WALKER, with WALKER's target replaced by: "one undead crow, canvas 32x24, contact pivot (16,22), standing body 14 px long and 11 px tall".
   - Add: "A zombie crow: ragged blue-black feathers with violet-grey highlights, a few missing feathers that show pale bone on one wing, a sharp grey beak and a pale cloudy eye. Side view facing west (left) in the game's three-quarter camera. Lean, sharp and menacing, never cute. The dark feathers need lighter cool edge highlights, so the bird reads on dark grass at night."
   - Attach `docs/reference-sheet.png` (style reference) and `assets/art_source/enemies/walker/master.png` (same-world undead palette).
   - Make two candidates. Keep the one whose 1x reduction still shows the beak and the eye.
2. **Strips.**
   - Prompt: BASE + ENEMY_STRIP + STRIP, one call each: fly 4, peck 3, death 4, and land 1 as its own single-frame call. Attach the accepted master raw as the identity master.
   - For the fly strip add: "the body and head stay in exactly the same place in every cell; only the wings move".
3. **Head.** One call, made the way A011's "How to make it" says: its prompt lines, one candidate, `transparent_background=true`.
   - Subject: "head, beak and ragged neck ruff".
   - Image 1: this pack's accepted master raw (identity master).
   - Image 2: `native/crow/west/01.png` from this delivery, enlarged by nearest (colour and in-game identity reference).
   - Image 3: `assets/art_source/ui/wood.png` (icon style reference).
   - If `python implementation/backlog/assets.py status A011` says `approved`, also attach `native/head_walker/none/01.png` from `implementation/backlog/deliveries/A011-forecast-heads/` (framing reference).
4. **Tool argument:** `transparent_background=true` on every call.
5. **Export.**
   - One `content_scale` per strip, set from the body length (head to tail, 14 px).
   - For the grounded frames, set the anchors so the centre of the feet lands on (16,22) with the lowest row 21.
   - For the fly frames, set the anchor so the torso's bottom sits at row 18 (±1) and the torso is centred on x=16.
   - Render through `import_art.render_source`.
   - The default is no `palette_keys`. If the feathers turn brown or green, use `["ink","ink_soft","night","night_light","moon","stone_dark","stone","stone_light","cloth_dark","bone","bone_dark","gold_dark"]` for every crow strip. The head follows A011's rule (above).

## Review with the owner

`index.html` follows contract 9.5. It shows every animation at 1x and 4x, playing and still, by day and in the night preview, next to the farmer and the walker. It also shows two scenes on tiled `sprites/terrain/grass.png`, by day and at night:

- **Over the wall:** the crow flying at a 10 px lift over an east-west run of three wall cells (`sprites/buildings/wall_join_2.png`, `wall_join_10.png` and `wall_join_8.png`), with `shadow.png` at its pivot.
- **On the field:** the crow landed and pecking beside `wheat_3.png`, and the death ending on the grass.

The forecast head is shown at 1x and 4x over `night` #1a1830 and tiled `sprites/ui/panel.png`, beside this pack's master, and in one row with A011's five heads when A011 is approved. The HUD is not relit, so the head's night preview is labelled "world relight, for reference only".

Questions (in Portuguese):

1. "Em voo o corvo parece estar no ar, acima do muro, e pousado parece estar na plantação?"
2. "As penas pretas continuam legíveis na prévia noturna?"
3. "Aprova para integração ou quer mudanças?"

## Acceptance

- [ ] Exactly 14 PNGs, with the canvases, pivots, counts and names of the table. Nothing is facing east.
- [ ] Grounded frames have the lowest opaque row 21, centred on x=16 (±1).
- [ ] Flight frames have no pixel on row 22 or below. The fly torso is fixed (±1).
- [ ] The 1 px clear border holds on every frame.
- [ ] The fly loop closes. No fly frame is another shifted by 2 px or less.
- [ ] The wingspan of `fly_2` is at most 26 px.
- [ ] The death never grows taller and ends on the ground at most 8 tall.
- [ ] No baked shadow, crop, wall or motion lines.
- [ ] At 1x the beak and the eye read in the master, the peck and the head.
- [ ] The head meets A011's rules: lowest opaque row 14, centred on x=8 (±1), 1 px clear at left, right and top, 12-13 tall and at most 13 wide, and only its body's palette names.
- [ ] Every other item in contract section 10 holds.

## Delivery

- **Folder:** `implementation/backlog/deliveries/A048-crow/` with the standard files of contract 9.1. There is no `runtime/` folder.
- **checks.json** adds:
  - `flight_frames_clear_of_ground`;
  - `fly_torso_fixed`;
  - `death_settles`;
  - `icon_bounds_ok`.
  
  The contract's `grounded_on_pivot` is computed on the grounded frames only, and the file says so.
- **The mapping lines** in `CLAUDE-A048-PROMPT.txt`:
  - `native/crow/west/01.png -> sprites/enemies/crow.png  32x24 pivot (16,22) draw 1.0`;
  - `native/crow_fly/west/01..04.png -> sprites/enemies/crow_fly_0..3.png  0.1 s loop (airborne)`;
  - `native/crow_land/west/01.png -> sprites/enemies/crow_land_0.png`;
  - `native/crow_peck/west/01..03.png -> sprites/enemies/crow_peck_0..2.png  0.12 s loop`;
  - `native/crow_death/west/01..04.png -> sprites/enemies/crow_death_0..3.png  0.1 s one-shot`;
  - `native/head_crow/none/01.png -> sprites/ui/head_crow.png  16x16 pivot (8,8)`.
  
  The handoff also lists the aliases, and says the height offset and the shadow stay 0249's code.
- **Last step:** `python implementation/backlog/assets.py set A048 approved`, run only after the owner approves in words recorded in `APPROVAL.json`.
