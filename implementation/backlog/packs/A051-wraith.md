# A051 - The wraith

- **Status:** todo
- **For game task:** 0265
- **Dressed by game tasks:** 0252
- **Spec after game task:** 0252
- **Family:** enemies
- **Mode:** A - raw ImageGen sources, Claude reduces them to the 42-colour palette
- **Size of the job:** 13 PNGs: 1 master, 3 animations (11 frames), 1 forecast head

## What it is for

The wraith is winter's answer to a defence that only shoots: in the dark, no tower can aim at it. Light makes it a target: the searchlight, a flare, fire and the porch. The player sees it at night drifting towards the house, faint outside light and solid inside it. That fading is a view-only alpha shader (0252, `src/ui/wraith_fade.gdshader`). **The art itself is fully opaque with binary alpha.** Never paint translucency, soft edges or a glow. At 1x it must read as a hooded floating shade, distinct from every walking zombie. Its pale form must hold up in the night preview, and it must still read when the shader shows it faint.

## Deliverables

Final geometry settled by game task 0252. The rows stand as written: 64x48 standing on (32,44), the frames and seconds of the table. **How the game plays them:**
- **The float:** 18 ticks a tile, a little over one and a half tiles a second, on the four `walk` frames at 0.125 s each, facing the way it moves. It bites the house and gnaws a wall as a walker does; until 0265 it does that on its walk frames, and `attack` waits for it.
- **The fade is the shader's** (`src/ui/wraith_fade.gdshader`), never the art's. Where its cell is lit it is drawn solid. Outside light it is drawn at 35%, and its rows waver a little, each on its own clock. Between the two it eases over a quarter of a second, and its shadow fades with it. The lit cells are the ones the towers ask about: a searchlight's square, two tiles round the porch, a flare's burst while it shows, a fire under it.
- **Death:** until 0265 the body left behind is `wraith_death_3`, squashed, and solid; the fade is for the living.
- **Night colours:** at 35% what carries it on night snow is its dark outline over the pale body. A faint stand-in with its rim reads as a shade, and without it the body would melt into the snow. Keep a dark rim round the pale form on every frame.

Until 0265 every frame stands in as the walker gone pale (`PlaceholderArt`), and the forecast head is the box over the walker's head, tinted the same, all through 0120's road. Start only when `python implementation/backlog/assets.py next` offers this pack.

| Runtime name | Native canvas | Pivot | Frames / seconds / loop | Notes |
|---|---|---|---|---|
| `enemies/wraith` | 64x48 | (32,44) | 1 / 0.1 / static | Identity master, facing `west`. A hooded, legless shade. The body hovers 3-4 px above the ground, and a tattered hem tapers to wisps that touch the ground row. Visible 18-24 wide x 30-32 tall. |
| `enemies/wraith_walk_0..3` | 64x48 | (32,44) | 4 / 0.125 / loop | **The float.** Facing `west`, mirrored at runtime. The hood and torso bob by at most 1 px, the arms drift and the hem ripples. The wisp tip stays on the ground row. |
| `enemies/wraith_attack_0..2` | 64x48 | (32,44) | 3 / 0.1 / one-shot | Facing `west`: (0) rears back with the arms drawn in, (1) lunges with long claws reaching west, (2) drifts back to the float pose. |
| `enemies/wraith_death_0..3` | 64x48 | (32,44) | 4 / 0.1 / one-shot | **The dissipate.** Facing `west`: (0) the hood tears, (1) the form unravels into strands, (2) the strands sink, (3) a low knot of wisps on the ground, at most 6 tall. |
| `ui/head_wraith` | 16x16 | (8,8) | 1 / 1.0 / static | Forecast head, direction `none`. A bust following A011's head rules (below). |

- **Every frame:**
  - the lowest opaque row is 43: the hem wisp or the death knot touches it;
  - the body is centred on x=32 (±1);
  - a 1 px clear border: only columns 1-62 and rows 1-43 hold pixels;
  - one `content_scale` per strip;
  - the float height is 30-32 in the master, the walk and attack frame 2;
  - no two frames are identical.
- **Every pixel is alpha 0 or 255.** The checker refuses partial alpha.
- **Death:** the visible height never grows from one frame to the next.
- **Eyes:** two eye pixels are allowed in `bone` or `bone_dark`. They are not a light source: there is no metadata point and no glow.
- **Runtime names:** the float is `wraith_walk_*` and the dissipate is `wraith_death_*`, because the game's motion code plays `walk` and `death`.
- **The head** follows the head rules of A011 (`implementation/backlog/packs/A011-forecast-heads.md`), so it sits in one row with the other heads:
  - a bust in three-quarter view turned to the left, cut flat at the bottom;
  - the lowest opaque row is 14 (row 15 empty), centred on x=8 (±1), with 1 px clear at left, right and top;
  - 12-13 tall and at most 13 wide;
  - `palette_keys` are the palette names used by this pack's own `wraith` frames, which build.py computes read-only from its `native/`;
  - the eyes are `bone` or `bone_dark`, never a colour that looks emissive;
  - `content_anchor_xy` = `(scaled_w // 2, scaled_h - 7)`;
  - there is no 10x10 cut.
- **Aliases:** Claude creates `wraith_walk_b` (= walk_2), `wraith_attack` (= attack_1) and `wraith_death` (= death_3). Do not deliver them.
- **Delivery paths:**
  - `native/wraith/west/01.png`;
  - `native/wraith_walk/west/01..04.png`, `native/wraith_attack/west/01..03.png` and `native/wraith_death/west/01..04.png`;
  - `native/head_wraith/none/01.png`.

## Match these

- `sprites/enemies/walker.png`, `walker_walk_0..3.png` and `walker_death_0..3.png`:
  - 64x48, pivot (32,44);
  - standing visible 15-19 x 28-29.
  
  The wraith is a little taller because it hovers. Match the outline and contrast.
- `sprites/enemies/runner.png`, `tank.png` and `breaker.png`: the silhouettes it must not resemble. The hood and the legless tapering hem carry the difference.
- `implementation/fhd-player/pilots/2026-10-06/walk-final-mirrored/native-40/walk/down/01.png`: the 32px farmer (visible 16x32). The wraith is about his height.
- `sprites/effects/flare_0..3.png` (24x24) and `sprites/buildings/gun_tower.png` (32x48): the light it is revealed by, and the tower that cannot see it in the dark.
- `assets/art_source/masters/style-night.png` (1672x941 study): how pale cool colours sit in the night palette. It is a study, not a size reference.
- `assets/art_source/enemies/walker/master.png` and `walk-v2.png`: accepted raw sources. `docs/reference-sheet.png`: the style reference.

## How to make it

1. **Master.**
   - Prompt: BASE + WALKER, with WALKER's old targets replaced by: 64x48 canvas, contact pivot (32,44), floating body 31 px with the hem wisp touching the ground at the pivot.
   - Add: "The wraith: a hooded, legless shade in a long tattered shroud. Pale grey-violet cloth with cool white edge highlights, a deep dark hood opening with two small pale eyes, long thin arms with claw fingers, and a hem that frays into wisps tapering to the ground. Side view facing west (left). Solid, fully opaque pixel art with crisp edges. No transparency, no soft fade, no glow, no mist cloud."
   - Attach `docs/reference-sheet.png` (style reference), `assets/art_source/enemies/walker/master.png` (same-world enemy) and the farmer frame (scale reference).
   - Make two candidates. Keep the one that reads as floating at 1x.
2. **Strips.**
   - Prompt: BASE + ENEMY_STRIP + STRIP, one call per strip: float 4 (written in the prompt as "walk"), attack 3, dissipate 4 (written as "death", "unravels and sinks into a low knot of wisps, ending on the ground").
   - Attach the accepted master raw as the identity master.
3. **Head.** One call, made the way A011's "How to make it" says: its prompt lines, one candidate, `transparent_background=true`.
   - Subject: "the hood with its dark opening and two pale eyes, and the shroud's shoulders".
   - Image 1: this pack's accepted master raw (identity master).
   - Image 2: `native/wraith_walk/west/01.png` from this delivery, enlarged by nearest (colour and in-game identity reference).
   - Image 3: `assets/art_source/ui/wood.png` (icon style reference).
   - If `python implementation/backlog/assets.py status A011` says `approved`, also attach `native/head_walker/none/01.png` from `implementation/backlog/deliveries/A011-forecast-heads/` (framing reference).
4. **Tool argument:** `transparent_background=true` on every call.
5. **Check the raw alpha.** ImageGen tends to return a ghost with soft partial alpha.
   - Inspect the raw.
   - If the body's alpha is partial in large areas, so that threshold 128 eats the shape, regenerate with the CORRECTION prompt asking for solid opaque pixels.
   - Never repair it in code.
6. **Export.**
   - One `content_scale` per strip (float pose = 31 px).
   - Set the anchors so the wisp tip is on row 43 and the body is centred on x=32.
   - Render through `import_art.render_source`.
   - All the wraith strips use `palette_keys` `["ink","ink_soft","night","night_light","moon","stone_dark","stone","stone_light","cloth_dark","cloth","water_dark","bone","bone_dark"]`, so the shade never picks up rot green or skin. The head follows A011's rule (above), which gives a subset of these.

## Review with the owner

`index.html` follows contract 9.5. It shows:

- every animation at 1x and 4x, playing and still, by day and in the night preview, next to the farmer and the walker;
- each night-preview view twice:
  - solid;
  - at CSS `opacity: 0.35`, as a stand-in for the shader's faint state. This is only on the review page: the delivered PNGs stay binary.
- a scene on tiled `sprites/terrain/grass.png` at night: one wraith inside a flare's area (`flare_2.png` behind it), drawn solid, and one outside it, drawn at 0.35.

The forecast head is shown at 1x and 4x over `night` #1a1830 and tiled `sprites/ui/panel.png`, beside this pack's master, and in one row with A011's five heads when A011 is approved. The HUD is not relit, so the head's night preview is labelled "world relight, for reference only".

Questions (in Portuguese):

1. "A assombração se lê como um vulto flutuando, diferente de todos os zumbis, a 1x?"
2. "Na versão fraca (fora da luz) ela ainda é percebida pelo jogador, sem sumir de vez?"
3. "Aprova para integração ou quer mudanças?"

## Acceptance

- [ ] Exactly 13 PNGs, with the canvases, pivots, counts and names of the table. Nothing is facing east.
- [ ] Every frame: binary alpha, lowest opaque row 43, centred on x=32 (±1), the 1 px border.
- [ ] The wraith strips use only the listed `palette_keys` colours.
- [ ] No float frame is another shifted by 2 px or less. The float loop closes.
- [ ] The dissipate never grows taller and ends at most 6 tall.
- [ ] `checks.json` `silhouette_distances` (master against `sprites/enemies/{walker,runner,tank,breaker}.png`, the `silhouette()` of `tools/check_enemy_art.py`) are each at least 16.
- [ ] No soft edge, mist halo or glow anywhere.
- [ ] The head meets A011's rules: lowest opaque row 14, centred on x=8 (±1), 1 px clear at left, right and top, 12-13 tall and at most 13 wide, and only its body's palette names.
- [ ] Every other item in contract section 10 holds.

## Delivery

- **Folder:** `implementation/backlog/deliveries/A051-wraith/` with the standard files of contract 9.1. There is no `runtime/` folder.
- **checks.json** adds `silhouette_distances`, `silhouette_distinct`, `death_settles` and `icon_bounds_ok`.
- **The mapping lines** in `CLAUDE-A051-PROMPT.txt`:
  - `native/wraith/west/01.png -> sprites/enemies/wraith.png  64x48 pivot (32,44) draw 1.0`;
  - `native/wraith_walk/west/01..04.png -> sprites/enemies/wraith_walk_0..3.png  0.125 s loop (the float)`;
  - `native/wraith_attack/west/01..03.png -> sprites/enemies/wraith_attack_0..2.png  0.1 s one-shot`;
  - `native/wraith_death/west/01..04.png -> sprites/enemies/wraith_death_0..3.png  0.1 s one-shot (the dissipate)`;
  - `native/head_wraith/none/01.png -> sprites/ui/head_wraith.png  16x16 pivot (8,8)`.
  
  The handoff also says the art is opaque and the fade is 0252's shader.
- **Last step:** `python implementation/backlog/assets.py set A051 approved`, run only after the owner approves in words recorded in `APPROVAL.json`.
