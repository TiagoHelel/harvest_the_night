# The Aseprite art contract

Every sprite of the remake follows this contract. If a delivery follows it,
Claude (the game's chat) can integrate it without guessing.

## What decides what

- **This contract** is the law for the Aseprite remake.
- **`inventory/Bxx-*.md` and `inventory/inventory.json`** give, for every file:
  - its name;
  - its native canvas and pivot;
  - its frame count and timing;
  - its facing and its mirrors.
  
  These are the game's real numbers. Code and tests depend on them, so never
  change one on your own.
- **A brief** is the pack file (`implementation/backlog/packs/Axxx-*.md`) or
  the old generation prompt that a row links to. It says:
  - what the thing is for and what it must read as;
  - its poses, frame by frame;
  - its states and its metadata points.
  
  **Ignore the Codex mechanics in a brief.** That means ImageGen calls,
  `raw/`, `build.py`, palette modes A/B, `content_scale`, `palette_keys`,
  `tool_rects_xywh` and `tool_ramp_reserved`. Where a brief and this contract
  disagree, this contract wins.
- **`implementation/backlog/ART-CONTRACT.md`** is the older Codex contract.
  Some of its sections still apply, and this file names them where they do.
- **If a number is in neither this contract nor the inventory,** ask the
  owner. Do not guess.
- **If the owner wants a number changed** (more frames, another timing, a
  bigger canvas), record it as a deviation (section 9) with the owner's
  words. Claude decides at integration whether the game can take it.

## 1. Scale and density

| Fact | Value |
|---|---|
| Logical screen | 480x270, integer-scaled to 1920x1080 (4x) |
| Tile | 16x16 logical px; the screen shows 30x17 tiles; no zoom |
| Density | **1 art px = 1 logical px = 4x4 screen px**, for every sprite |

- **Draw every sprite at its native size,** the canvas the inventory gives,
  one art pixel per pixel.
  - Never draw big and scale down.
  - Never draw small and scale up.
  - Never resample a frame to fit.
- **Two families have a 2x runtime:**
  - the farmer's walk, idle and bed are 40x40 native, 80x80 at runtime;
  - his work, fishing, care and reactions are 48x48 native, 96x96 at runtime.
  
  Deliver **native only**. Claude makes the exact 2x NEAREST runtime copy, and
  the game draws it at 0.5, so on screen it has the same density as
  everything else.
- **Five old fixtures are redrawn at full density:** workshop, kitchen,
  press, generator and the shop (with `shop_closed`).
  - The game used to double them. Their inventory canvas is twice today's
    (`was 48x48 at 2x`).
  - They stay the same size on screen, with twice the detail.

**Body targets** (visible native px):

| Thing | Visible size |
|---|---|
| Farmer, standing | 16 wide x 32 tall |
| Peddler (adult NPC) | 30-32 tall |
| Ordinary enemy, standing | about 18 x 29 |
| Giant, standing | about 46 x 41; every boss at least this |
| Tree | about 36 x 42 |
| Tower | at most 32 x 44 (today about 19 x 25 at level 1) |
| Ripe crop | at most 12 tall on 16x16, 20 on 16x24, 28 on 16x32 |
| Inventory / HUD icon | at most 14x14 / 8x8 |

Each row's `Today` column gives today's visible size. A new sprite may differ
by a pixel or two. The check warns when the height moves by more than 15%.

## 2. Geometry

- **The pivot is the ground contact point,** in canvas pixels with the origin
  at the top left. The game places the pivot on the ground and sorts by it.
- **Grounded rule.** When the inventory says `lowest row N`, the lowest opaque
  row of every frame is exactly N (the pivot row minus 1). The feet stand on
  the pivot.
  - Centre the body on the pivot's x.
  - A death ends lying on that same ground row.
- **One canvas, one pivot and one body scale** for every frame of an
  animation. Use the same for every level and state of a family: a tower's
  `_hurt`, `_fire` and `_wreck` stand exactly where its whole version stands.
- **Frame files** are `<anim>_<i>.png` from `_0`, exactly as the inventory
  lists them. Single-frame sprites have no index unless the inventory gives
  one.
- **Loops close:** the last frame leads back into the first. **One-shots
  end:** a death ends low on the ground, and a work stroke ends close to the
  idle.
- **Side view faces west (left).** The game mirrors west to face east, so
  never deliver an east copy of a side-view sprite.
- **The farmer's baked mirrors.** In B01 `west`, `south_east` and
  `north_west` are delivered as exact whole-canvas horizontal flips of `east`,
  `south_west` and `north_east`. The check compares them byte for byte.
- **Nothing touches the canvas edge** unless it is a terrain tile. Keep a
  1 px clear border on effects and icons.

## 3. Alpha, and what is never baked

`ART-CONTRACT.md` section 4 applies. In short:

- **Alpha is binary,** 0 or 255. There are no soft edges, no anti-aliasing
  against transparency and no empty frames.
- **Terrain tiles are fully opaque** and seamless. Edges and shores are
  overlays, transparent outside their band.
- **Never baked into a sprite:**
  - ground shadows (the game has one shared `actors/shadow.png`);
  - grass or soil patches under an object;
  - night or dusk versions (the game relights at night);
  - glows, halos or bloom;
  - text, numbers or labels;
  - other objects (a tree in a chop strip, a target in an attack strip).
- **Light comes from metadata points** (section 6) and from the flame and
  flare effects. A bright pixel does not emit, so white cloth and ripe crops
  must not look lit at night.
- **"Transparent" creatures** (the wraith) are drawn opaque with binary alpha.
  Their translucency is a shader.

## 4. The palette

- **One palette for the whole game,** made in B00 and approved by the owner:
  - `deliveries/B00-palette-and-pilot/palette/harvest.gpl`, to load in
    Aseprite;
  - `harvest.json`, as `{"colours": [{"name", "hex", "role"}]}`.
- **It contains the game's 42 project colours unchanged:** the same names
  and hex values as `tools/palette.py:COLOURS` (also tabled in
  `ART-CONTRACT.md` section 3). The code, the font, the UI kit and the night
  relight are tuned on them. The check fails a palette that drops or changes
  one.
- **You may add tones** so each material gets the 4-5-tone ramp the toolkit
  shades with:
  - a highlight above `grass_light`;
  - a mid tone between `wood_dark` and `wood`;
  - purples for grapes and beets;
  - and so on.
  
  Aim for 64 colours or fewer. Going above 64 needs the owner's yes,
  recorded in B00's review log.
- **Hue shifting** (shadows towards violet, highlights towards yellow) is
  built into the palette's ramps once. **Every pixel of every PNG is a
  palette colour,** and the check fails any other.
  - If the toolkit makes colours at build time (`C.hueShift`, selout,
    `E.ramp`), turn that off for this game or snap the final frame to the
    palette.
  - The snap is the nearest palette colour by squared RGB distance, done as a
    deterministic export step.
  - Then look at the result: a snap that erases a face or a silhouette means
    the drawing must change, not the snap.

## 5. The look

`ART-CONTRACT.md` section 6 applies, and `docs/reference-sheet.png` is the
look. Open it.

- **The camera:** one orthographic three-quarter top-down view showing roofs
  and front faces. There is no diamond isometric grid.
- **Light comes from the upper left:** highlights clustered top-left,
  undersides and contact areas darker.
- **Hand-crafted pixel art:**
  - deliberate pixel clusters;
  - **coloured outlines, darker on the underside** (the toolkit's selective
    outline does this);
  - readable material planes with restrained texture.
- **Avoid:**
  - gradients and dithering noise;
  - uniform thick black outlines;
  - random single-pixel speckle;
  - details that vanish at 1x.
- **The contrast ladder:**
  1. ground is the quietest;
  2. props are next;
  3. actors and interactive objects are the loudest;
  4. the house is the landmark.
- **Materials:** warm timber, terracotta roofs, full foliage and cool water.
  **Enemies:** rot greens and muted worn clothes, menacing but at home on a
  cozy farm, with restrained gore.
- **Readability:** everything reads at 480x270 at 1x, by day and after the
  night relight (section 8). A sprite says what it is without text or a
  health bar.
- **Today's art is a guide, not a template.** Use it for what each thing is,
  its size, its silhouette, its poses and its states. Never copy its pixels.

## 6. Metadata points

All points are in **native** canvas pixels, with the origin at the top left.

- **On an opaque pixel.** Each `_xy` point sits on an opaque pixel of the
  frame it belongs to. The exception is `catch_xy`, which marks where code
  draws the fish.
- **Inside the canvas.** Each `_xywh` rectangle stays inside the canvas.
- **Your own values.** The inventory's Points column shows today's values for
  reference. Give your art's own values in contract.json.

| Key | On | Rule |
|---|---|---|
| `light_xy`, `lights_xy` | buildings, the guardian's eyes, the searchlight | On the lamp, furnace or eye pixel, in every state where it shines |
| `smoke_xy` | chimneys, exhausts | The top opaque pixel of the chimney |
| `windows_xy` + `window_rects_xywh` | buildings with glass | 1-8 panes, the same count in both lists. Each point is inside its rect, and the rect covers glass only. Panes stay separate shapes. |
| `muzzle_xy`, `muzzles_xy`, `muzzle_region_xywh` | towers, catapult | Per level, on whole, hurt and fire. `muzzles_xy` has 1-2 points and its first is `muzzle_xy`. |
| `spray_xy`, `bite_xy`, `spit_xy`, `line_xy` | sprinklers, dog, spitter, bobber | Where the code's effect starts |
| `contact_xy` | farmer work, frame 1 | The tool head pixel at the strike |
| `rod_tip_xy`, `catch_xy` | farmer fishing | As the A024 pack says |
| `bubble_xywh` | farmer reactions and Zzz | Covers every glyph pixel and no body pixel |
| `track_xywh`, `patch_margins_lrtb` | fishing bar | The inner track; the nine-patch margins |

## 7. What not to draw

`inventory/DERIVED.md` lists every file the game loads that you do **not**
deliver:

- composed pieces;
- barrier join masks (composed from your modules);
- aliases;
- the terrain's rotated edges;
- compatibility slices;
- the code-owned UI kit and atlas;
- the studio ident, the font, the logo and the app icon.

## 8. The review page and the night preview

Each batch's review (`review/index.html`, local, opened from disk) shows:

- **every animation at 1x and 4x** (nearest), playing at its real timing and
  as a still strip;
- **by day and in the night preview.** The night preview is the game's
  relight, computed for each pixel:
  - `lit = rgb * (0.36, 0.40, 0.82)`
  - `grey = 0.299*lit.r + 0.587*lit.g + 0.114*lit.b`
  - `out = clamp(grey + 0.76*(lit - grey) + (0.040, 0.035, 0.105))`
- **beside the farmer,** with the feet on one ground line. Use B01's approved
  farmer once it exists, and today's `sprites/actors/idle_south_0.png`
  (80x80, halve it) before that.
- **before and after:** today's version beside the new one (`current` in
  `inventory.json`; `inventory.py sheet` makes a contact sheet of it);
- **a small scene on tiled grass** where the batch's things live: a tower
  line with enemies, a field of crops, the farm buildings in a row;
- **metadata points** marked on a separate overlay.

Precompute every derived image (4x, night) into `review/`, because a
browser blocks canvas reads from `file://`. Use relative paths only, with no
CDN and no network.

## 9. The delivery

Everything for a batch goes in
`implementation/aseprite/deliveries/<Bxx-slug>/` (the slug is the inventory
file's name). Nothing else in the repository is written.

```
B15-enemies/
  png/<folder>/<file>.png    the native frames, named exactly as inventory files
                             (png/enemies/walker_walk_0.png, png/ui/head_walker.png)
  source/                    copies of what made them: the Lua generators, the
                             .aseprite files, and any engine file you changed
  review/                    the review page and its precomputed images
  contract.json
  checks.json                written by `inventory.py check Bxx --write`
  review-log.txt             every review round: date, the owner's words verbatim, what changed
  APPROVAL.json              only after the owner approves
  HANDOFF.md                 only after the owner approves
```

B00 has `palette/` and `review/pilot-board.png` instead of `png/`.

### contract.json

```json
{
 "batch": "B15", "slug": "B15-enemies", "title": "Enemies and their forecast heads",
 "date": "2026-10-23",
 "tool": "Aseprite 1.3.18, toolkit C:/Users/Helel/Documents/aseprite (game_assets/harvest_the_night)",
 "palette": "deliveries/B00-palette-and-pilot/palette/harvest.json",
 "sources": [{"path": "source/enemies.lua", "sha256": "<64 hex>"},
             {"path": "source/walker.aseprite", "sha256": "<64 hex>"}],
 "files": [
  {"png": "png/enemies/walker_walk_0.png", "sha256": "<64 hex>",
   "anim": "enemies/walker_walk", "frame": 0, "seconds": 0.125, "loop": true,
   "source": "source/enemies.lua", "mirror_of": null, "points": {}}
 ],
 "deviations": [{"anim": "enemies/walker_walk", "what": "6 frames instead of 4",
                 "owner_words": "<verbatim>"}]
}
```

- `files` lists every PNG in `png/`, with its points.
- `seconds` and `loop` must equal the inventory, unless a deviation names that
  `anim`.
- `sources` lists everything in `source/`.
- `date` is written by hand, never read from the clock.

### checks.json

```
python implementation/aseprite/inventory.py check Bxx --write
```

It checks:
- every inventory file is present and nothing else is;
- the canvas sizes and RGBA mode;
- binary alpha and no empty frames;
- the grounded and opaque rules;
- the exact mirrors;
- palette colours only;
- contract.json's hashes, timings and points;
- the sources listed and present.

It warns on identical frames and on a height far from today's. **It must
print PASS before the owner reviews.** If a rule cannot hold, explain why in
`review-log.txt` and to the owner.

### APPROVAL.json (only after the owner's explicit approval)

```json
{"batch": "B15", "date": "2026-10-23", "status": "approved for integration",
 "owner_words": "<the owner's words, verbatim, untranslated>",
 "approved_sha256": {"png/enemies/walker_walk_0.png": "<64 hex>"},
 "frames": 141, "runtime_integrated": false}
```

### HANDOFF.md (for Claude, the game's chat)

Plain English. It states:

1. **The batch,** its approval date and the owner's words.
2. **What is in it:** frame count, and anything left out with the reason.
3. **Deviations** from the inventory or this contract, with the owner's
   words.
4. **The points** that changed meaning or were added.
5. **Anything the owner asked of the game**, for Claude to decide: a timing,
   a new frame, a colour the night relight crushes.
6. **What not to do:**
   - never regenerate, repaint, recolour, resample or retime;
   - never use `review/` images as sources;
   - only `png/` files listed in contract.json are art.

## 10. Before showing the owner

- [ ] Every inventory row of the batch exists, with its canvas, pivot, frame count and timing.
- [ ] The feet stay planted and the body size never changes inside a strip. Loops close and one-shots end.
- [ ] Side view faces west. B01's baked flips are exact. Nothing faces east that the game mirrors.
- [ ] Binary alpha, a true transparent background (terrain opaque), and no baked shadow, ground, glow, night or text.
- [ ] Palette colours only. The 1x and night previews still read.
- [ ] Metadata points sit where section 6 says.
- [ ] `inventory.py check Bxx --write` prints PASS.
- [ ] `source/` holds everything needed to rebuild the batch, and a rebuild gives the same bytes.
