# Art contract for Codex art packs

Every pack in `implementation/backlog/packs/` must follow this contract. Codex makes
the art with its built-in ImageGen tool, the owner approves it, and Claude
integrates it. If a delivery follows this contract, Claude can integrate it
without guessing.

- **Must / never** are hard rules. **Default** means "use this unless the pack
  file says otherwise".
- The pack file's Deliverables table wins over a family default, but only for the
  item it names, and only if it says so explicitly. Nothing overrides section 1.
- If a number Claude needs is in neither this contract nor the pack, ask the
  owner. Do not guess, and do not "pick something reasonable".
- Facts here were checked against `project.godot`, `src/core/game_data.gd`,
  `tools/import_art.py`, `src/ui/raster_art.gd`, `src/ui/art_placement.gd`,
  `implementation/sprites/{ART_DIRECTION,PIPELINE}.md`,
  `implementation/sprites/generation/PROMPTS.md` and the approved farmer walk
  handoff `implementation/fhd-player/pilots/2026-10-06/walk-final-mirrored/`.

## 1. Scale

| Fact | Value |
|---|---|
| Logical viewport | 480x270, integer-scaled (`canvas_items`, `integer`) to a 1920x1080 window |
| Tile | 16x16 logical px (`TILE_SIZE := 16`). The screen shows 30x17 tiles. There is no zoom. |
| Density | **1 art px = 1 logical px = 4x4 physical px at 1080p** |
| Farmer detail ("32px") | The body is about 32 art px tall, about 128 physical px: two tiles, like Stardew's 16x32 farmer at 4x |

1. Author every new asset at that density, at draw scale 1.0. A native canvas of
   WxH is WxH logical pixels on screen.
2. "32px" means the farmer's detail density. It is not a 32x32 cell and not a new
   resolution.
3. **Farmer-style packs** (section 2.2) are the only 2x exception:
   - native 40x40, pivot (20,36);
   - also delivered as a runtime pack: 80x80, pivot (40,72), every art pixel a
     2x2 block, drawn at `draw_scale` 0.5.
   
   On screen this is the same density as everything else.
4. **Never author a new building at half density.** The six legacy fixtures
   (house, shop, workshop, kitchen, press, generator) are drawn at 2.0 by
   `ArtPlacement.visual_scale`, which gives 8x8 physical px per art pixel. They are
   a legacy exception, not a template: "48x48 like the stations" is wrong for new
   art. A new building with a footprint of W tiles is about W*16 art px wide.
5. Never:
   - raise the resolution;
   - resize a frame to fit its own bounds;
   - change scale within an animation, or within one level of a family.
   
   A transparent canvas is not the object's size. Measure visible bounds.

**Body targets** (visible native px; these are the reference points for "how big"):

| Thing | Visible size | Physical at 1080p |
|---|---|---|
| Farmer, standing | 16 wide x 32 tall | ~128 tall |
| NPC (adult) | 30-32 tall | ~124 |
| Ordinary enemy, standing | ~18 x 29 | ~116 |
| Giant, standing | ~46 x 41 | ~170 |
| New boss | at least the Giant | - |
| Tree | 36 x 42 | 144 x 168 |
| Tower | at most 32 x 44 (today 19 x 25 at L1) | - |
| Crop, ripe | at most 12 tall on 16x16, at most 20 on 16x24 | - |
| Inventory / HUD icon | at most 14 / 8 | 56 / 32 |

## 2. Families

### 2.1 Rules for every family

- **The pivot is the ground contact point**, in native canvas pixels, with the
  origin at the top left.
  - On a grounded pose, the lowest opaque row is `pivot_y - 1`: the feet stand on
    the pivot row. Every approved sprite measures this way.
  - The body is centred on `pivot_x`.
- **Placement.** Claude places the pivot at the bottom centre of the object's
  logical footprint (`cell*16 + (fw*8, fh*16)`). Sorting is by ground contact.
- **One canvas and one pivot** for every frame of an animation, and for every level
  and state of a family.
- **One source scale** per animation strip, and per tower level across its states.
  Never one per frame.
- **Frame files** are numbered `01..NN`, and **`01.png` is frame 0**.
- **Loops** close: the last frame leads back to the first.
- **One-shots** (deaths, work, wake-up) end. A death ends low on the ground.
- **Side view** is authored **facing west (left)**. The runtime mirrors it to face
  east, so never deliver an east copy.
- **Direction names** in a delivery are the runtime names: `south`, `north`,
  `west`, `east`, `south_west`, `south_east`, `north_west`, `north_east`.
  - Art with no facing uses `none`.
  - The 2026-10-06 walk pack used screen words. Their mapping is: down=south,
    right=east, up=north, left=west, down-right=south_east, up-right=north_east,
    up-left=north_west, down-left=south_west.

### 2.2 Per-family table (defaults for new packs)

`draw` is the runtime draw scale. Timings are in seconds per frame.

| Family | Canvas / pivot (native) | draw | Frames and timing | Directions and mirrors | Runtime names |
|---|---|---|---|---|---|
| **Farmer: locomotion and plain poses** (walk, run, idle, sleep, bed, pass out) | 40x40 / (20,36); runtime 80x80 / (40,72) | 0.5 | walk 8 at 0.1, loop. Run 8 at 0.07, loop. Idle 3 at 0.55, loop: one grounded pose, never a lifted walk frame. Others as the pack says. | 8 directions. Author `south`, `north`, `east`, `south_west` and `north_east`. Bake `west`=flip(`east`), `south_east`=flip(`south_west`) and `north_west`=flip(`north_east`) as exact whole-canvas flips. Claude binds them directly and never flips again. | `<anim>_<dir>_<i>`, e.g. `run_north_east_3` |
| **Farmer: work, tools, fishing, tend, reactions** | 48x48 / (24,44); runtime 96x96 / (48,88). Same body scale as the walk; the extra room is for tools and glyphs. | 0.5 | Work: 4 frames (anticipation, contact, follow-through, recovery) at 0.09, one-shot. Reactions: 1 frame at 0.2, south only, with `bubble_xywh`. | `south`, `north`, `west`. East is a runtime mirror of west and is not delivered. | `<verb>_<dir>_<i>`; `react_<kind>_0` |
| **NPC** (peddler and any other person) | 40x40 / (20,36) | 1.0 | Idle 2-4 at 0.4, loop. Talk 2-4 at 0.15, loop. Walk 4-8 at 0.1, loop. | Idle and talk face `south`. Walk is side view facing `west`, mirrored at runtime. | `<npc>_<anim>_<i>` |
| **Guardian** (porch scarecrow) | 32x48 / (16,44), one cell (settled by its spec task) | 1.0 | Day 1 frame. Wake 3-4 at 0.12, one-shot. Night idle 2-4 at 0.25, loop. Point 3 at 0.1, one-shot. | `none` | `guardian_<anim>_<i>` |
| **Animals, large** (cow, sheep, pig, dog) | 40x32 / (20,30) | 1.0 | Idle 2 at 0.5, loop. Walk 4 at 0.15, loop. Eat 2-3 at 0.2, loop. Sleep 1-2 at 0.6, loop. Bark, bite or dig 3 at 0.1, one-shot. | Side view facing `west`, mirrored at runtime. No up/down cycles unless the pack asks. | `<animal>_<anim>_<i>` |
| **Animals, small** (chicken) | 24x24 / (12,22) | 1.0 | As large animals | As large animals | As large animals |
| **Crops** | 16x16 / (8,14). Tall: 16x24 / (8,22). Very tall (sunflower, trellis): 16x32 / (8,30). | 1.0 | 4 stages (planted, sprout, growing, ripe) as frames 0..3, static (`loop` false, 0.55). One scale per species. Extra stages (regrow, trampled, withered) are named by the pack. | `none` | `<crop>_<stage>` |
| **Soil overlays** (tilled, wet, fertilised) | 16x16 / (8,16), opaque | 1.0 | 1 frame. Wet is at least 20 RGB brightness darker than dry. | `none` | `tilled`, `tilled_wet`, `<name>` |
| **Props and resources** | Small nodes 16x16 / (8,14). Tree 40x48 / (20,44). 2x2 props 32x32 / (16,30). Bin-sized 24x24 / (12,22). | 1.0 | 1 frame, or the strip the pack names (e.g. a lid opening 2-3 at 0.1, one-shot) | `none` | `<id>`. A `_b` variant shares canvas, pivot, scale and palette with its master. |
| **Snow caps and other overlays** | Same canvas and pivot as the host sprite | 1.0 | 1 frame | `none` | `<host>_<overlay>` |
| **Buildings** (coop, barn, machines, house tiers) | Full density. Width = footprint_w*16 + up to 8 px of overhang per side. Height = footprint_h*16 + walls and roof + 4 rows below. Pivot = (W/2, H-4). Example: a 4x3 machine is about 64 wide. | 1.0 | 1 frame per state | `none` | `<id>`, `<id>_active`, `<id>_hurt`, `<id>_wreck` (only if the pack lists it) |
| **Towers and tower-like defences** (gun, flame, mortar, crossbow, catapult, beehive, searchlight) | 32x48 / (16,44), one cell | 1.0 | 1 frame per level x state | `none` | `<family>`, `<family>_2`, `<family>_3`, each x `""`, `_hurt`, `_fire`, `_wreck` |
| **Small defences** | Decoy 16x32 / (8,28). Braid 16x24 / (8,20). Bait or mine 16x16 / (8,14). | 1.0 | States per pack. A hit sway is 2-3 at 0.1, one-shot. | `none` | `<id>`, `<id>_hurt`, `<id>_wreck`; mine: `mine`, `mine_triggered`, `mine_spent` |
| **Barrier modules** (wall, fence, electric fence, hardwood wall, sandbags) | 16x32 / (8,28); barricade-type 16x24 / (8,20) | 1.0 | Modules per state, see 2.3 | `none` | `<f>` (mask 0), `<f>_join_<1..15>`, `<f>_hurt`, `<f>_join_<m>_hurt`, `<f>_wreck` |
| **Ordinary enemies** | 64x48 / (32,44). Body about 29 tall. | 1.0 | Walk 4 at 0.125, loop. Attack 3 at 0.1, one-shot. Death 4 at 0.1, one-shot. Extra moves (burrow, emerge, spit) as the pack lists, at 0.1. | Side view facing `west`, mirrored at runtime. Never up/down or diagonal cycles. A flyer (crow) is still side view; its shadow is code. | `<kind>_<anim>_<i>`. Claude makes the aliases (`<kind>`, `_walk_b`, `_attack`, `_death`). |
| **Bosses** | 80x64 / (40,60) like the Giant. Up to 112x80 / (56,76) only if the pack justifies it. | 1.0 | Walk 4 at 0.14, loop. Windup 3 at 0.1. Attack, slam or charge 3-4 at 0.1. Cast 4 at 0.1. Death 5 at 0.12, one-shot. Master: 1 standing pose. | Side view facing `west`, mirrored at runtime | `<boss>_<anim>_<i>` |
| **Projectiles** | 8x8 / (4,4) | 1.0 | 2-3 at 0.1, loop | Facing `west` if directional | `<id>_<i>` |
| **Effects** | Burst 12x12 / (6,6). Rising (flame, smoke) 16x20 / (8,18). Dust 16x12 / (8,10). Splash 20x16 / (10,14). Flare 24x24 / (12,12). | 1.0 | 3-4 frames at 0.065-0.14, one-shot. Peak visible height 8-18 px. | `none` | `<effect>_<i>` |
| **Icons** | Inventory 16x16 / (8,8) and HUD 10x10 / (5,5), both cut from **one** raw source | 1.0 | 1 frame (1.0, static). Visible at most 14 and 8 px, centred, with clear padding. | `none` | `icon_<id>` and `hud_<id>` |
| **Forecast heads and marks** | 16x16 / (8,8) | 1.0 | 1 frame | `none` | `head_<kind>` |
| **UI pieces** (cursor, bobber, minigame bar, book) | Per pack: cursor 16x16 / (8,8), bobber 8x8 / (4,4) | 1.0 | Cursor pulse 2 at 0.4, loop. Others per pack. | `none` | Per pack |
| **Terrain** | 16x16 / (8,16), **fully opaque, seamless** | 1.0 | 1 frame. Water: 3 phases at 0.55, loop, with a 2 px calm margin. | `none` | `<material>`, `<material>_b..d`, `edge_<n,e,s,w>`, `edge_corner_<ne,nw,se,sw>`, `shore_*`, `water`, `water_b`, `water_c` |

The contract.json `runtime_name` of each file (section 9.2) is authoritative. The
patterns above are the defaults it starts from.

### 2.3 Family notes

**Farmer and NPC**

- Palette mode B (section 3).
- Keep the blue 32px identity: straw hat with a brown band, dark hair, warm skin,
  blue work clothes, brown boots.
- Body and feet never move between frames of a pose. Tools stay inside the canvas.
- Reaction glyphs must be separate from the body: at least 1 transparent pixel
  away, diagonals included. `bubble_xywh` covers every glyph pixel and no body
  pixel (`validate_bubble` checks this).
- No crop, tree, rock or impact particle is baked into a work strip.

**Towers**

- Levels change the construction (footing, armour, mechanism, barrels).
- Never stack copies vertically or add level pips or coloured bands.
- `_hurt` shows deliberate damage. `_wreck` collapses onto the same base.
- `_fire` adds only a small, local muzzle form at the real weapon tip. A whole tower
  never has a permanent flame.
- Each level needs `muzzle_xy` and `muzzles_xy` (one or two points) on whole, hurt
  and fire, plus `muzzle_region_xywh`. Wrecks have no muzzle.
- A searchlight gives `light_xy` instead (the beam is code).

**Buildings**

- Keep window panes as separate shapes so the runtime can light them. Never bake
  the glow.
- Active art moves only the mechanism or a local furnace. It never adds a baked
  smoke scene.
- An idle building never looks active.
- If a pack asks for a new state of one of the six legacy 2x fixtures and does not
  say which density to use, ask the owner.

**Barrier joins**

- The runtime picks one of 16 masks from the occupied same-group neighbours:
  **N = 1, E = 2, S = 4, W = 8**.
- Deliver for each state (`whole`, `hurt`) three modules, all on 16x32 / (8,28):
  - `<f>_post`;
  - `<f>_horizontal` (full-width span);
  - `<f>_vertical` (narrow north-south projection).
- Also deliver one `<f>_wreck` (a low pile on the cell).
- One scale per material across every module and state.
- Match the geometry of `sprites/buildings/modules/wall_*.png` and `fence_*.png`
  (open them):
  - the post and the horizontal span stand on row 20, the cell's centre line, 8
    rows above the pivot;
  - the vertical slice runs rows 8-27.
- `build.py` must also compose all 32 masks (16 whole, 16 hurt) with today's exact
  recipe, so the owner reviews real joins. Parts are pasted in this order: N, W, E,
  S, then the post on top.

| Bit | Part | slice (x,y,w,h) | paste (x,y) |
|---|---|---|---|
| N = 1 | `<f>_vertical` | (0,8,16,20) | (0,0) |
| W = 8 | `<f>_horizontal` | (0,0,8,32) | (0,0) |
| E = 2 | `<f>_horizontal` | (8,0,8,32) | (8,0) |
| S = 4 | `<f>_vertical` | (0,8,16,20) | (0,8) |
| always | `<f>_post` | (0,0,16,32) | (0,0) |

The broken span must stay visible: the post must not cover the whole break.

**Icons**

- One raw source per item, in palette mode A.
- The 16x16 and the 10x10 use the same crop with two `content_scale` values.
- No text, numbers, panels or shadows.
- The nine-patch UI kit (`panel`, `button_*`, `tab_*`, `checkbox_*`, `slider_*`)
  is code-owned. Never redraw it unless a pack asks.

**Terrain**

- `transparent_background=false`. The tile is opaque edge to edge.
- Opposite borders match. Variants share boundary colours and texture density.
- Edges and shores are 16x16 overlays that are transparent outside their band
  (`transparent_background=true`).
- Terrain is the quietest contrast in the game: grouped texture, no centrepiece.
- `sprites/terrain/atlas.png` is built by Claude. Deliver tiles only.

## 3. Colour: palette modes

Every pack declares one mode in contract.json. The default is mode A, except for
farmer and NPC packs, which use mode B.

| | **Mode A: palette-reduced** | **Mode B: exact-source** |
|---|---|---|
| Use for | World art: terrain, props, crops, buildings, defences, barriers, enemies, bosses, effects, icons, UI pieces | The blue 32px farmer and NPCs drawn beside him, or any pack whose file says B |
| What the source is | The raw ImageGen PNG in `raw/` | The finished native frame in `native/` |
| Claude's import | `palette: "tools/palette.py:COLOURS"`, optional `palette_keys` subset. Crop, `content_scale`, `content_anchor_xy` and `alpha_threshold` 128 come from contract.json. | `palette: "exact-source"`, `content_scale` 1.0, the crop is the whole canvas. Colours are kept exactly. For 2x packs the runtime frames are imported with `detail_wh` = native size. |
| What Codex's `native/` holds | A preview made by **the importer's own recipe** (below), so the owner approves exactly what the game will show | The final pixels |
| Colours allowed | Only the 42 project colours (table below) | Every colour already present in the approved walk frames, plus the 42 project colours. The farmer garment stays inside the 12-colour blue ramp (`blue_palette` in `implementation/fhd-player/pilots/2026-10-06/walk-up-right-low-step/contract.json`). contract.json `colour_ramp` lists every RGB used, each with a role. |
| Pixel edits beyond the recipe | Never | Only with the owner's explicit permission, quoted in `authorization.json`, and done as a deterministic step in `build.py`. Never a hand-edited PNG without a recipe, and never a frame drawn from scratch by code. |

**Mode A recipe.** This is `render_source` in `tools/import_art.py`. Import it read-only
(`sys.path.insert(0, "tools")`) and never re-implement it. Never edit that file.

1. Crop `crop_xywh` from the raw image, as RGBA.
2. Resize with NEAREST to `max(1, round(w*s)) x max(1, round(h*s))`.
3. If alpha is below `alpha_threshold`, the pixel becomes transparent. Otherwise its
   RGB becomes the nearest palette colour (squared RGB distance) and alpha becomes
   255.
4. Paste onto an empty canvas at `pivot - content_anchor`. The default anchor is
   `(scaled_w // 2, scaled_h)`. The content must not clip.

Rules for the recipe values:

- All frames of an animation share one `content_scale`.
- `_b` variants share canvas, pivot, scale and `palette_keys` with their master.
- Use `palette_keys` to stop small shapes from borrowing colours from unrelated
  ramps (e.g. grass taking cloth blue).
- If reduction erases a face, crop stage, barrel or silhouette, regenerate the
  source. Never patch the output.

**The 42 project colours** (the authority is `tools/palette.py:COLOURS`):

| Ramp | Dark | Mid | Light |
|---|---|---|---|
| ink | `ink` #241f2e | `ink_soft` #3a3345 | |
| grass | `grass_dark` #4e7a35 | `grass` #6a9646 | `grass_light` #8ab659 |
| soil | `soil_dark` #5c422a | `soil` #7a5838 | `soil_light` #96704a |
| water | `water_dark` #2b5480 | `water` #3a6ea5 | `water_light` #5a8cc0 |
| stone | `stone_dark` #52505c | `stone` #6e6c78 | `stone_light` #8c8a96 |
| wood | `wood_dark` #6b4a2c | `wood` #8c6239 | `wood_light` #a87c4e |
| leaf | `leaf_dark` #1d4024 | `leaf` #2e5e34 | `leaf_light` #46804a |
| roof | `roof_dark` #8a2f2a | `roof` #b0423a | `roof_light` #c9635a |
| gold | `gold_dark` #a8742c | `gold` #c49646 | `gold_light` #d6ba60 |
| flame | | `flame` #f2a03c | `flame_hot` #f6d97a |
| bone | `bone_dark` #b8ae9a | | `bone` #e8e0cf |
| skin | `skin_dark` #b56b4b | `skin` #e49b68 | `skin_light` #f3c58d |
| cloth | `cloth_dark` #203859 | `cloth` #315a8c | `cloth_light` #4e7fb1 |
| night | `night` #1a1830 | `night_light` #2e2a4e | `moon` #cfd6ff |
| rot | `rot_dark` #355038 | `rot` #557652 | |
| blood | `blood` #8e2b33 | | |

## 4. Alpha, and what is never baked

- **Alpha is binary.** Every pixel of a delivered native or runtime frame has alpha
  0 or 255. There are no empty frames.
- **Ask for transparency with the tool argument** `transparent_background=true`
  for every isolated sprite, and `false` for opaque terrain tiles and scene
  studies. Asking for transparency only in the prompt prose is not enough.
- **A painted checkerboard or a flat key colour is not transparency.**
  - Inspect the raw alpha before accepting a return.
  - If the background is not truly transparent, regenerate it or have ImageGen
    edit it.
  - Never key a background out with code.
- **Never baked into a sprite:**
  - ground shadows (one shared `sprites/actors/shadow.png`, 20x8, is used for
    everyone);
  - ground patches, soil or grass bases;
  - night or dusk versions (night is relit at runtime);
  - glows, halos or bloom;
  - text, labels, numbers, watermarks or UI;
  - other objects (a tree in a chop strip, a target in an attack strip).
- **Light comes only from metadata points** (section 5) and from the flame and
  flare effect families.
  - Bright source pixels do not emit.
  - White cloth and ripe crops must not look emissive at night.
- Wraiths and other "transparent" creatures are still drawn opaque with binary
  alpha. Their translucency is a shader.

## 5. Metadata points

All points are native canvas pixels with the origin at the top left. For 2x packs,
also give the runtime value (x2). Each point must sit **on an opaque pixel** of the
frame it belongs to, and checks.json proves it.

| Key | Used by | Rule |
|---|---|---|
| `light_xy` | Stations, buildings, the guardian's eyes (one per eye), the searchlight | On the lamp, furnace or eye pixel, in every state where it shines |
| `smoke_xy` | Chimneys, exhausts | On the top opaque pixel of the chimney or exhaust |
| `windows_xy` + `window_rects_xywh` | Buildings with glass | 1-8 panes, the same count in both lists. Each point lies inside its rect, and the rect covers glass only. |
| `muzzle_xy`, `muzzles_xy`, `muzzle_region_xywh` | Towers, catapult | `muzzles_xy` holds 1-2 distinct points and its first equals `muzzle_xy`. The point is at the weapon tip of the fire pose and inside the region. Set per level. |
| `bubble_xywh` | Farmer reactions | Covers every glyph pixel and no body pixel |
| Anything new (e.g. `spray_xy`, `bite_xy`) | As the pack names it | Same rules. Name it and say what code uses it for. |

## 6. The look

- **Camera:** one orthographic three-quarter top-down view showing roofs and front
  faces. **No diamond isometric grid.**
- **Light** comes from the upper left: highlights are clustered top-left, and
  undersides and contact areas are darker.
- **Hand-crafted pixel art:**
  - deliberate pixel clusters;
  - **coloured outlines**, darker on the underside;
  - readable material planes with restrained texture.
- **Avoid:**
  - smooth gradients, blur and anti-aliased halos;
  - vector, 3D or painterly looks;
  - random single-pixel speckle;
  - uniform thick black outlines;
  - tiny details that vanish at native size.
- **Contrast ladder:**
  1. ground is the lowest contrast;
  2. props are next;
  3. actors and interactive objects are the highest.
  
  The house is the landmark.
- **Materials:** warm timber, terracotta roofs, full foliage and cool water.
- **Enemies:** rot greens and muted worn clothes, menacing but compatible with a
  cozy farm, with restrained gore.
- **Readability:** everything must read at 480x270 at 1x, by day and after the night
  relight. A sprite says what it is without text or a health bar.

## 7. Approved art to match

Open these images before generating; do not work only from their names. Attach
the relevant ones to ImageGen as references, and state each one's role ("style
reference", "identity master", "edit target").

| For | Path |
|---|---|
| Look, materials, composition | `docs/reference-sheet.png` |
| Farmer's original identity | `docs/sprites_sem_fundo.png` |
| Identity masters and day/night studies | `assets/art_source/masters/` (`farmer.png`, `house.png`, `tree.png`, `walker.png`, `style-day.png`, `style-night.png`, `master-contract.json`). The studies show materials and lighting, not authoritative sizes. |
| Blue 32px farmer, approved walk (scale and identity reference for every pack) | `implementation/fhd-player/pilots/2026-10-06/walk-final-mirrored/native-40/walk/<down,up,right,left,...>/01..08.png` (runtime: `runtime-80/`) |
| Farmer grounded idle | `assets/art_source/player-fhd/idle-blue-grounded/frames/*.png` (80x80, 2x), `sprites/actors/idle_south_0.png` |
| Ordinary enemies | `sprites/enemies/<walker,runner,tank,breaker>_<walk,attack,death>_<i>.png`; masters `assets/art_source/enemies/<kind>/master.png` |
| Giant | `sprites/enemies/giant_<walk,windup,slam,death>_<i>.png`; `assets/art_source/enemies/giant/master.png` |
| Towers | `sprites/buildings/<gun_tower,flame_tower,mortar,auto_crossbow>[_2,_3][_hurt,_fire,_wreck].png`; masters `assets/art_source/defences/<family>/master.png` |
| Barriers and mine | `sprites/buildings/{wall,fence,barricade,mine}*.png`, modules `sprites/buildings/modules/` |
| Buildings (legacy 2x) | `sprites/buildings/{house,workshop,kitchen}*.png`, `sprites/props/{shop,well,press,generator}*.png`, raw `assets/art_source/buildings/` |
| Props and animals | `sprites/props/{tree,tree_b,stump,rock,rock_b,ore,ore_b,seam,seam_b,cow,chicken}.png` |
| Crops and soil | `sprites/crops/{wheat,corn,carrot}_<0..3>.png`, `tilled.png`, `tilled_wet.png` |
| Terrain | `sprites/terrain/*.png` (grass a-d, soil, path, floor, rock, water a-c, edges, shores) |
| Effects | `sprites/effects/<muzzle,impact,flame,smoke,dust,splash,flare>_<i>.png` |
| Icons | `sprites/ui/icon_*.png`, `sprites/ui/hud_*.png`; raw `assets/art_source/ui/` |
| Interior (bed and others) | `sprites/interior/*.png` (bed 48x64, pivot at bottom centre) |

## 8. Prompts and generation

- Build every prompt from `implementation/sprites/generation/PROMPTS.md`: **BASE**,
  plus the family section, plus **STRIP** for an animation, plus **CORRECTION** for
  a revision.
  - Replace every `{brace}` with this contract's numbers: the native canvas and
    pivot, frame count and ordered poses.
  - Say which input image is a reference and which is an edit target.
- **Keep calls small.** Generate one identity master first, then one animation in
  one direction per call (at most 8 frames). Never put a whole pack on one
  enormous sheet.
- **Strip layout:**
  - equal cells with generous transparent gutters;
  - feet on one baseline, centred at the same x in every cell;
  - the same body height throughout;
  - no labels or separators.
  
  Cut strips with measured boxes, never with guessed row cuts.
- **Tool arguments:**
  - set `transparent_background` as described in section 4;
  - do not add model, size or path fields that the built-in tool does not expose;
  - do not invent a destination path. Copy the file from the location the tool
    actually returned.
- **Revisions:** at most **3 targeted revisions per asset** (`r1`-`r3`). Each one
  fixes one concrete failure and names the evidence. After the third, ask the
  owner whether to continue, change the brief, or stop.

## 9. Delivery contract (every pack)

### 9.1 Folder

Put everything in `implementation/backlog/deliveries/<Axxx-slug>/`, where
`<Axxx-slug>` is the pack file's name without `.md`.

- `implementation/backlog/` has a `.gdignore`, so Godot never imports these files.
- Codex writes nothing outside this folder, except the pack's Status line, which
  it changes through `assets.py`.

```
A030-coop-barn/
  raw/                         ImageGen returns, byte-for-byte copies
    coop-whole-r0.png
    coop-whole-r0.prompt.txt   the exact assembled prompt text
    coop-whole-r0.call.json    the exact tool call (see below)
  native/<anim>/<dir>/01..NN.png
  runtime/<anim>/<dir>/01..NN.png      only for 2x farmer-style packs: exact 2x NEAREST of native
  preview/                     images built by build.py for index.html
  rejected/                    rejected candidates + <name>.reason.txt
  contract.json
  checks.json
  build.py
  index.html
  review-log.txt               every review round: date, the owner's words verbatim, what changed
  authorization.json           only if the owner allowed pixel edits (mode B)
  APPROVAL.json                only after the owner approves
  CLAUDE-A030-PROMPT.txt       only after the owner approves
```

**`<anim>`** is the runtime animation stem, without the direction or frame index:

- `run`, `chop`, `spitter_walk`, `catapult_2_fire`, `potato`, `coop_hurt`,
  `icon_copper`, `grass_snow_b`;
- barrier modules: `electric_fence_post_hurt`;
- composed masks: `electric_fence_join_5`.

**`<dir>`** is a direction from 2.1, or `none`.

**Each `*.call.json`** records:

- the tool name;
- every argument exactly as sent (the prompt text and `transparent_background`);
- each input image's path, sha256 and role;
- the returned file path;
- the copied `raw/` path and its sha256;
- the date and the revision number;
- the decision: accepted, or rejected with its reason.

`implementation/sprites/generation/0005-chop-call.json` is a good example.

### 9.2 contract.json

`build.py` writes contract.json. Claude reads it to write manifest entries.
Required keys:

| Key | Content |
|---|---|
| `pack`, `slug`, `title`, `date` | `date` is a constant in build.py, never read from the clock |
| `status` | `"review"`, or `"approved for integration"` once APPROVAL.json exists |
| `runtime_integrated` | always `false` (Claude's integration task records integration) |
| `palette_mode` | `"A"` or `"B"` |
| `palette`, `palette_keys`, `colour_ramp` | Mode A: `"tools/palette.py:COLOURS"` (+ keys). Mode B: `"exact-source"` + every RGB with its role. |
| `alpha_threshold` | 128 |
| `tool` | `"built-in ImageGen"` |
| `references` | `[{path, sha256, role}]`: every reference image used |
| `animations` | One entry per `<anim>/<dir>`:<br>- `anim`, `dir`, `frames`, `poses` (the ordered pose names), `frame_seconds`, `loop`;<br>- `canvas_wh`, `pivot_xy`, `draw_scale`;<br>- for 2x packs: `runtime_canvas_wh`, `runtime_pivot_xy`, `detail_wh`;<br>- `mirror`: `"none"`, `"runtime"` (east is flipped by the game) or `"baked:<dir>"` (an exact flip of that direction);<br>- `points` (section 5). |
| `mirror_pairs` | e.g. `{"west": "east", "south_east": "south_west", "north_west": "north_east"}` |
| `files` | One entry per exported PNG:<br>- `output`, `sha256`, `runtime_name`, `anim`, `dir`, `frame`;<br>- `source` + `source_sha256` (the raw file), `prompt` + `prompt_sha256`, `call`;<br>- `recipe`: `crop_xywh`, `sheet_cell_xywh` if cut from a strip, `content_scale`, `content_anchor_xy`, `alpha_threshold`, `palette_keys`, `mirrored_from`;<br>- `runtime: {output, sha256}` for 2x packs;<br>- `points` for that frame. |
| `joins` | Barrier packs only: the mask recipe from 2.3, exactly as used |
| `deviations` | Every place the pack departs from this contract, with the owner's words that allowed it. Empty if none. |
| `supersedes` | Older delivery folders this pack replaces, if any |

Example `files` entry (mode A, one enemy frame):

```json
{"output": "native/spitter_walk/west/01.png", "sha256": "<64 hex>",
 "runtime_name": "spitter_walk_0", "anim": "spitter_walk", "dir": "west", "frame": 0,
 "source": "raw/spitter-walk-r1.png", "source_sha256": "<64 hex>",
 "prompt": "raw/spitter-walk-r1.prompt.txt", "prompt_sha256": "<64 hex>",
 "call": "raw/spitter-walk-r1.call.json",
 "recipe": {"crop_xywh": [73, 121, 411, 638], "sheet_cell_xywh": [0, 0, 516, 836],
            "content_scale": 0.045, "content_anchor_xy": [9, 29],
            "alpha_threshold": 128, "palette_keys": null, "mirrored_from": null},
 "points": {}}
```

### 9.3 checks.json

`build.py` computes it. Every boolean must be `true` before review. If one cannot
be, explain why in `review-log.txt` and to the owner.

| Key | Meaning |
|---|---|
| `frames_expected`, `frames_found` | Equal. Counted from the pack's Deliverables table. |
| `canvas_and_pivot_consistent` | One canvas and one pivot per animation and family |
| `one_scale_per_animation` | Mode A `content_scale` is shared, and per tower level |
| `binary_alpha`, `no_empty_frame` | Every pixel has alpha 0 or 255; no frame is empty |
| `colours_allowed` | Mode A: only the 42 colours. Mode B: only `colour_ramp`. |
| `grounded_on_pivot` | On grounded poses the lowest opaque row is `pivot_y - 1`, centred on `pivot_x` (±1) |
| `mirror_pairs_exact` | Every baked mirror is a pixel-exact horizontal flip |
| `runtime_exact_2x` | 2x packs: runtime is exactly native x2 NEAREST |
| `points_on_opaque` | Every metadata point sits on an opaque pixel and inside its rect or region |
| `importer_recipe_matches` | Mode A: `render_source` with the recorded recipe reproduces `native/` pixel for pixel |
| `rebuild_identical` | A second run of build.py gave byte-identical files |
| Family checks | Terrain `opaque_and_seamless`. Icons `icon_bounds_ok` (≤14 / ≤8). Barriers `all_32_masks_composed`. Reactions `bubble_ok`. Crops `wet_darker_by_20`. |

### 9.4 build.py

- Uses Python 3 and Pillow only. Run it from the repo root with
  `python implementation/backlog/deliveries/<Axxx-slug>/build.py`.
- **Reads** `raw/` (and, read-only, `tools/palette.py`, `tools/import_art.py` and the
  reference sprites). **Writes** only inside its own folder.
- No network and no ImageGen calls. Generation happens before build.py; build.py
  only converts.
- Does the deterministic steps:
  - measured crops, one scale per strip, the mode A recipe or the mode B
    quantisation;
  - alpha threshold, placement by pivot, exact flips, the 2x runtime and barrier
    composition;
  - then contract.json, checks.json, `preview/` and index.html.
- Is deterministic: sorted iteration, no clock, no randomness. **A second run gives
  byte-identical files.**
- `--check` rebuilds in memory, compares everything with contract.json, and exits
  non-zero on any difference.

### 9.5 index.html (the owner's review page)

- Static and self-contained: relative paths only, no CDN and no network.
- Every image uses `image-rendering: pixelated`. Browsers block canvas pixel reads
  on `file://`, so build.py pre-computes every derived image into `preview/`.
- Shows each animation or state:
  - at **1x and 4x** (nearest);
  - playing at its real `frame_seconds`, by swapping the `src` in JavaScript, and
    as a still strip;
  - **by day**, and in a **night preview** computed with the game's relight. For
    each pixel: `lit = rgb * (0.36, 0.40, 0.82)`,
    `grey = 0.299*lit.r + 0.587*lit.g + 0.114*lit.b`,
    `out = clamp(grey + 0.76*(lit - grey) + (0.040, 0.035, 0.105))`;
  - **beside the 32px farmer**, feet on the same ground line, at 1x and 4x. Use the
    farmer frame `implementation/fhd-player/pilots/2026-10-06/walk-final-mirrored/native-40/walk/down/01.png`
    (40x40, pivot (20,36); that pack names directions in screen words), copied into
    `preview/`. Also show the
    closest existing family sprite (walker for enemies, gun_tower for towers, tree
    for props);
  - over light, dark, checker and tiled `sprites/terrain/grass.png` backgrounds;
  - with metadata points marked on a separate overlay;
  - for barriers, all 32 composed masks laid out as real runs and corners.
- Links to contract.json, checks.json and review-log.txt.
- Has a collapsed "Rejected" section with each candidate's reason.

### 9.6 Rejected candidates and revisions

- A rejected return moves to `rejected/`, keeping its `.prompt.txt` and
  `.call.json`, plus `<name>.reason.txt`: one line with the concrete failure
  (e.g. "feet drift 3 px between frames 2 and 3").
- Nothing in `rejected/` is ever referenced by contract.json.
- Never call a whole sheet accepted if some of its frames were rejected. Record
  which cells were used.

### 9.7 APPROVAL.json (only after the owner's explicit approval)

```json
{"pack": "A030", "date": "2026-10-09", "status": "approved for integration",
 "owner_words": "<the owner's words, verbatim, untranslated>",
 "approved_folder": "implementation/backlog/deliveries/A030-coop-barn",
 "approved_sha256": {"native/coop/none/01.png": "<64 hex>"},
 "frames": 8, "runtime_integrated": false}
```

`approved_sha256` lists every file in `native/` and `runtime/`.

### 9.8 CLAUDE-Axxx-PROMPT.txt (Claude's handoff)

Plain English text. Claude reads it from the integration task. It must state:

1. **The pack and approval:** the pack id and title, the approval date, and the
   owner's words.
2. **The authoritative folder:** this delivery folder only. Name every older folder
   it supersedes, and say that rejected/ and preview/ are not sources.
3. **The palette mode:**
   - Mode A: raw sources plus the per-file recipe in contract.json; reduce with
     `tools/palette.py:COLOURS` (+ keys).
   - Mode B: exact-source with `colour_ramp`. For 2x packs, use `runtime/` with
     `detail_wh` = native size and `draw_scale` 0.5.
4. **The mapping table:** one line per animation, e.g.
   `native/spitter_walk/west/01..04.png -> sprites/enemies/spitter_walk_0..3.png  64x48 pivot (32,44) draw 1.0  0.125 s loop`.
   It includes the aliases to create and the game task(s) whose placeholder this
   replaces.
5. **Frame order:** `01.png` is frame 0.
6. **Mirrors:** which are baked ("bind directly, do not flip again at runtime") and
   which are runtime ("east is not delivered; the game flips west").
7. **Metadata points** per state or level, in native coordinates (and runtime
   coordinates for 2x).
8. **Deviations** from this contract, with the owner's words.
9. **What not to do:**
   - never regenerate, repaint, recolour, resample or retime;
   - never cut sprites from GIFs, preview images or screenshots;
   - never use files that are not listed in contract.json;
   - never add a runtime flip to a baked mirror.
10. **The steps:**
    1. verify every file's sha256 against contract.json before promoting;
    2. promote through the raster pipeline (versioned sources under
       `assets/art_source/<family>/`, manifest entries with prompt, reference and
       approval provenance, `ownership.json`, `python tools/import_art.py`);
    3. extend the hard-coded family lists the art checks use;
    4. run `python tools/verify.py`;
    5. look at FHD captures by day and by night;
    6. run `python implementation/backlog/assets.py set Axxx integrated`.

## 10. Checklist before showing the owner

- [ ] Every deliverable in the pack's table exists, with the canvas, pivot, frame count and timing from section 2 or the pack.
- [ ] Feet stay planted and the body size never changes inside a strip. Loops close and one-shots end.
- [ ] Side-view art faces west. Baked mirrors are exact. Nothing is mirrored twice.
- [ ] Binary alpha with a true transparent background (terrain fully opaque). No baked shadow, ground, glow, night or text.
- [ ] The colours fit the declared mode. Mode A previews come from the importer's own recipe.
- [ ] Metadata points sit on opaque pixels.
- [ ] Next to the 32px farmer the size reads right, and it stays readable at 1x and in the night preview.
- [ ] `build.py` twice gives identical bytes, and `build.py --check` passes. checks.json is all `true`.
- [ ] Every raw return has its `.prompt.txt` and `.call.json`. Rejected candidates are in `rejected/` with reasons.
