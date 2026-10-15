# A023 - Fishing gear and the minigame

- **Status:** integrated
- **For game task:** 0206
- **Dressed by game tasks:** 0180, 0181, 0182
- **Spec after game task:** 0180
- **Family:** ui
- **Mode:** A - raw ImageGen sources, Claude reduces them to the 42-colour palette
- **Size of the job:** 20 PNGs from 9 raw sources: a bobber (2 + 3 frames), 3 icons (2 cuts each), 3 bar pieces, 2 bar flashes of 3 frames

## What it is for

Fishing gets a float on the water and a timing bar (0180), bait (0181) and a fish
book (0182). The bobber sits on the pond in the world, bobs while the farmer waits
and dips under at the bite; it is relit at night and must stay visible on dark
water. When a fish bites, a horizontal bar opens on the HUD: a marker sweeps along
a dark track and the player presses while it crosses the green sweet zone; a short
flash answers a hit or a miss. Worms and fish bait have inventory icons, and the
fish book has a tab icon that pack A056 later matches for the collection tabs.
Everything except the bobber is HUD art, not relit.

## Deliverables

Final bar geometry settled by game task 0180. The rows stand as written. The bar sits centred under the farmer on the 480x270 screen, at (240,184). The code maps its 100 bar steps onto the `fishbar_frame` track, measured on the stand-in as `track_xywh` (5,5,90,6). `fishbar_zone` is stretched over the green's steps (its 3-patch caps 2 px each), and `fishbar_marker`'s centre column sits on the marker's step. `fishbar_hit` and `fishbar_miss` flash at the marker's x on the press that lands, 3 frames of 0.065 s. The hits a species needs (1-3) show as 4x4 pips under the bar, drawn by code. The bobber and the three icons are for 0181 and 0182 to use; their rows stand. Game task 0181 shows `icon_worm` and `icon_bait` in the ledger's BAIT tab and `icon_bait` on the workshop's make-bait row, through 0120's stand-ins until this pack lands; the `hud_` cuts are registered for a compact place to come. Game task 0182 puts `hud_book_fish` on the ledger's FISH BOOK tab, beside its label, through the `hud_fish` stand-in until this pack lands. Start only when `python implementation/backlog/assets.py next` offers this pack.

Direction `none` and `mirror: "none"` for every file; draw 1.0.

| Runtime name | Native canvas | Pivot | Frames / seconds / loop | Notes |
|---|---|---|---|---|
| `effects/bobber_float_0..1` | 8x8 | (4,6) | 2 / 0.4 / loop | The waiting float. Row 6 is the waterline; the lowest opaque row is 5 in every frame. 0 = resting, visible 5 rows (rows 1-5): a 1 px `ink` antenna at x=4, a round `roof` cap (`roof_light` highlight) 2 rows, a `bone`/`bone_dark` band 2 rows, 5 wide (x 2..6). 1 = the same float 1 px lower: its top 4 rows (rows 2-5) |
| `effects/bobber_bite_0..2` | 8x8 | (4,6) | 3 / 0.1 / one-shot | The bite dip: the same float sinking, top 3 rows (rows 3-5), top 2 rows (rows 4-5), then only the antenna tip (row 5). The view holds frame 2 until the bar opens |
| `ui/icon_worm`, `ui/hud_worm` | 16x16, 10x10 | (8,8), (5,5) | 1 / 1.0 / static | One fat earthworm in an S-curve, `skin`/`skin_dark` with a `roof_light` band and `skin_light` highlights |
| `ui/icon_bait`, `ui/hud_bait` | 16x16, 10x10 | (8,8), (5,5) | 1 / 1.0 / static | Fish bait: a small open round tin (`stone`, `stone_light` rim) heaped with pink fish chunks (`roof_light`, `skin`). Not a whole fish (zombie bait, A037, is a rotten whole fish) |
| `ui/icon_book_fish`, `ui/hud_book_fish` | 16x16, 10x10 | (8,8), (5,5) | 1 / 1.0 / static | The fish book's tab icon: a small closed book at a slight three-quarter angle, water-blue cloth cover (`water_dark`, `water`, `water_light` top edge), a `bone` fish emblem facing west on the cover, `gold_dark` corner caps, `bone` page edges showing on the right. No title text. Pack A056 copies this book for its other tabs |
| `ui/fishbar_frame` | 100x16 | (50,8) | 1 / 1.0 / static | The bar: a warm timber frame (`wood_dark`, `wood`, `wood_light`) with small brass end caps (`gold_dark`, `gold`) around a recessed dark channel, the track (`water_dark`, a 1 px `water` top line). Visible at most 98x14, centred. Point `track_xywh` |
| `ui/fishbar_zone` | 8x6 | (4,3) | 1 / 1.0 / static | The sweet zone as a horizontal 3-patch: 2-column caps at each end, columns 2..5 the stretchable centre. `grass` body, `grass_light` top row, `grass_dark` bottom row, `ink` at the cap ends. Opaque edge to edge |
| `ui/fishbar_marker` | 5x12 | (2,6) | 1 / 1.0 / static | The sweeping marker: an upright needle, a 5-wide downward triangle head (rows 0-2, `bone` with `ink` outline) over a 1 px `bone` stem with `ink` sides; centre column x=2 |
| `ui/fishbar_hit_0..2` | 12x12 | (6,6) | 3 / 0.065 / one-shot | A hit: (0) a small 4-point star (`flame_hot` core, `gold_light`), (1) the widest, a ring of 6-8 short rays (`gold_light`, `grass_light`), at most 10 px, (2) four fading specks. Origin at the centre |
| `ui/fishbar_miss_0..2` | 12x12 | (6,6) | 3 / 0.065 / one-shot | A miss: (0) a small burst of grey-blue droplets (`water_light`, `stone_light`), (1) the widest, droplets flung outward, at most 10 px, (2) a few droplets falling. No cross, no letters |

- **The bobber is one float.** All five frames are cut from one raw float (an upright
  float: antenna, red cap, white band, and below the band the lower body that is
  under water in play). Pick `content_scale` = 1/N with N a whole number of raw
  pixels per art pixel, so the float is 5 art px wide; every frame uses the same
  `crop_x`, `crop_w` (5N, centred on the antenna) and `crop_y` (the antenna's top
  raw row), and crop height k*N with k = 5, 4 (float) and 3, 2, 1 (bite).
  `content_anchor_xy` is the default `(scaled_w // 2, scaled_h)`, so the crop's
  bottom edge lands on the waterline row 6. These are crops of one source, not new
  drawings.
- **Explicit overrides of contract 2.2 for the bobber only:** pivot (4,6) instead of
  the UI-piece default (4,4), because the pivot is the contact point (contract 2.1)
  and the float's contact is the waterline; and the float loop at 0.4 s instead of
  the effect family's 0.065-0.14 one-shot, because it is a resting bob, not a burst.
- **`line_xy`** on every bobber frame: the antenna's top opaque pixel, (4,1),
  (4,2), (4,3), (4,4), (4,5). The fishing line (code) ends there.
- **`track_xywh`** on `fishbar_frame`: the measured rectangle of the dark channel,
  covering channel pixels only. It must be exactly 6 rows tall (the zone's height)
  and at least 80 wide, centred on x=50 (±1). The code draws the zone and moves
  the marker inside it. Choose the frame's `content_scale` so the channel measures
  6 rows (the width only has to fit in 98).
- **`patch_margins_lrtb`** on `fishbar_zone`: (2, 2, 0, 0). In each row, columns 2..5
  are one colour, so stretching or tiling the centre looks the same.
- **Recipe for the icons:** one crop for both cuts; 16x16 = 14 / max(crop w, h),
  10x10 = 8 / max(crop w, h); `content_anchor_xy` `(scaled_w // 2, scaled_h // 2)`,
  as in `ui/icon_fish`. The bar pieces and flashes use the centre anchor too, each
  fitted inside its canvas with 1 px clear (the zone fills its canvas). Every recipe:
  `alpha_threshold` 128, `palette` `tools/palette.py:COLOURS`, `palette_keys` null
  unless a piece takes a colour from a ramp it does not have (then record the keys
  and why in review-log.txt).
- **Delivery paths:** `native/bobber_float/none/01..02.png`,
  `native/bobber_bite/none/01..03.png`, `native/icon_<id>/none/01.png`,
  `native/hud_<id>/none/01.png`, `native/fishbar_frame/none/01.png`,
  `native/fishbar_zone/none/01.png`, `native/fishbar_marker/none/01.png`,
  `native/fishbar_hit/none/01..03.png`, `native/fishbar_miss/none/01..03.png`.

## Match these

- `sprites/terrain/water.png`, `water_b.png`, `water_c.png` (16x16, `water_dark` to
  `water_light`): the pond the bobber floats on. The red cap and white band must
  stand out on them by day and in the night preview.
- `sprites/effects/splash_0..3.png` (20x16, pivot (10,14)): the bite splash the game
  plays over the bobber; the bobber is smaller than its first frame.
- `sprites/actors/fish_1.png` and `reel_1.png` (48x48): the rod and line today. If
  `python implementation/backlog/assets.py status A019` says `approved` or
  `integrated`, also its `native/icon_rod_*` cuts: the gear must look like the same
  fishing set.
- `sprites/ui/icon_fish.png`, `icon_wood.png` and raws `assets/art_source/ui/fish.png`,
  `wood.png`: the icon family (outline, 2-3 planes, 1 px clear padding).
- `sprites/effects/impact_0..2.png` (12x12, pivot (6,6), visible 6-9 px): the size of
  a small burst, for the hit and miss flashes.
- `sprites/ui/panel.png`, `button_normal.png`, `tab.png` and `tab_selected.png`
  (`night` #1a1830, `night_light` #2e2a4e, `gold_dark`/`gold` borders): the HUD
  around the bar and under the tab icon.
- `docs/reference-sheet.png` (style; the PESCAR panel and the jetty) and the farmer
  frame `implementation/fhd-player/pilots/2026-10-06/walk-final-mirrored/native-40/walk/down/01.png`.

## How to make it

1. **Prompts** from `implementation/sprites/generation/PROMPTS.md`, with the canvas
   and pivot of the row: the bobber BASE + "Create one fishing float (bobber),
   upright, seen from the game's three-quarter camera, a short dark antenna, a round
   red cap, a white band, and the lower body that is under water. Simple enough to
   be 5 pixels wide." The icons BASE + ICON + the "Native contract" paragraph of
   `implementation/sprites/generation/0018-fish.prompt.txt` with visible 14 and 8.
   The bar frame, zone and marker BASE + UI_SURFACE (with "no nine-patch; one fixed
   piece" for the frame and the marker). The flashes BASE + FX + STRIP (3 frames,
   the poses in the table).
2. **Inputs:** `docs/reference-sheet.png` (style) on every call;
   `assets/art_source/ui/wood.png` (icon style master) for the icons and the bar
   pieces; `sprites/terrain/water.png` (background colour reference, not to draw)
   for the bobber; `assets/art_source/effects/impact.png` (layout and size
   reference) for the flashes.
3. **Order:** the bobber, then the bar frame and zone together on one review, then
   the marker, the flashes, the worm, the bait and the book. One subject per call,
   one candidate per call, `transparent_background=true` (the zone too: it is a
   piece, not terrain). Inspect the raw alpha. At most 3 revisions per raw.
4. **Export:** build.py cuts and renders through `import_art.render_source` with the
   recipes above. If the zone's centre columns are not uniform, or the channel is not
   6 rows, regenerate with a flatter, cleaner source. Never patch pixels.

## Review with the owner

`index.html` follows contract 9.5. It shows:

- the bobber at 1x and 4x on tiled `water.png`, `water_b.png` and `water_c.png`, by
  day and in the night preview, float looping at 0.4 s and the bite playing at 0.1 s
  then holding, with `line_xy` marked and a 1 px line drawn from it to a mock rod
  tip; the farmer frame on a jetty-height row beside it;
- the bar assembled as the game will draw it, at 1x and 4x on the panel: the frame,
  the zone stretched to 12, 24 and 40 px inside `track_xywh`, the marker animated
  sweeping the track, and the hit and miss flashes playing on the marker;
- the three icons at 1x and 4x, both cuts, on flat `night`, flat `night_light`,
  tiled `panel.png`, light grey and checker; the book icon on `tab.png` and
  `tab_selected.png`;
- the night preview for the HUD pieces, labelled "world relight, for reference only:
  the HUD is not relit".

Questions for the owner:

1. "A boia afundando na mordida fica clara sobre a água, de dia e na prévia noturna?"
2. "Na barra do minijogo, a faixa verde e o marcador se leem bem no tamanho real, e os brilhos de acerto e de erro ficam claros sem texto?"
3. "Aprova para integração ou quer mudanças?"

## Acceptance

- [ ] Exactly 20 PNGs with the table's names, canvases and pivots.
- [ ] Bobber: one raw, one `content_scale` = 1/N, the same crop x, width and top; heights 5, 4, 3, 2, 1 art rows; lowest opaque row 5 in every frame; `line_xy` on the antenna pixel of each frame.
- [ ] `track_xywh` covers channel pixels only, is 6 rows tall and at least 80 wide, centred on x=50 (±1).
- [ ] `fishbar_zone` is opaque edge to edge, 8x6, and its columns 2..5 are uniform in every row (`zone_centre_uniform`).
- [ ] The flashes expand from frame 0 to frame 1 and shrink in frame 2, at most 10 px visible, 1 px clear border.
- [ ] Icons: one raw crop per pair, visible at most 14 and 8, centred (±1), 1 px clear padding, more than 24 / 7 opaque pixels, at least 2 colours, no two PNGs of one size byte-identical.
- [ ] Binary alpha, only the 42 colours, `importer_recipe_matches` true; no text, numbers, water, ripples, shadow or glow.
- [ ] Every other item of contract section 10 holds, and `build.py` twice gives identical bytes.

## Delivery

- **Folder:** `implementation/backlog/deliveries/A023-fishing-gear/` with the standard
  files of contract 9.1. No `runtime/` folder: this is not a 2x pack.
- **checks.json** adds `icon_bounds_ok`, `bobber_one_source`, `bobber_waterline`,
  `track_ok`, `zone_centre_uniform` and `flash_expands_then_fades`.
- **The mapping lines** in `CLAUDE-A023-PROMPT.txt`:
  - `native/bobber_float/none/01..02.png -> sprites/effects/bobber_float_0..1.png  8x8 pivot (4,6) draw 1.0  0.4 s loop  line_xy per frame`;
  - `native/bobber_bite/none/01..03.png -> sprites/effects/bobber_bite_0..2.png  8x8 pivot (4,6)  0.1 s one-shot  line_xy per frame`;
  - `native/icon_<id>/none/01.png -> sprites/ui/icon_<id>.png  16x16 pivot (8,8)` and `native/hud_<id>/none/01.png -> sprites/ui/hud_<id>.png  10x10 pivot (5,5)` for `worm`, `bait`, `book_fish`;
  - `native/fishbar_frame/none/01.png -> sprites/ui/fishbar_frame.png  100x16 pivot (50,8)  track_xywh`;
  - `native/fishbar_zone/none/01.png -> sprites/ui/fishbar_zone.png  8x6 pivot (4,3)  patch margins (2,2,0,0)`;
  - `native/fishbar_marker/none/01.png -> sprites/ui/fishbar_marker.png  5x12 pivot (2,6)`;
  - `native/fishbar_hit/none/01..03.png -> sprites/ui/fishbar_hit_0..2.png  12x12 pivot (6,6)  0.065 s one-shot`, and the same for `fishbar_miss`.

  They replace the stand-ins of 0180, 0181 and 0182 for game task 0206.
- **Last step:** `python implementation/backlog/assets.py set A023 approved`, run only
  after the owner approves in words recorded in `APPROVAL.json`.
