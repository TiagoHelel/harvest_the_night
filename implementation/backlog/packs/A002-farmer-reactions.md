# A002 - The farmer's reactions and Zzz

- **Status:** todo
- **For game task:** 0144
- **Dressed by game tasks:** 0129
- **Family:** farmer
- **Mode:** B - finished native pixel art (`exact-source`): the approved idle body copied as it is, plus ImageGen glyphs reduced to project colours
- **Size of the job:** 5 glyph sources, 7 native frames (4 reactions x 1 frame + the Zzz x 3 frames), plus the same 7 as exact 2x runtime copies

## What it is for

The little symbols over the farmer's head: `!` (bang) at a bite on the line and when
the night begins, `?` (question) when something of his is destroyed, a music note
when a crop comes ready nearby, and a heart when he pets the dog (0185). Today they
are 48x48 frames of the older 30px farmer; the view draws only the glyph, lifted 2 px
(`PlayerView.BUBBLE_LIFT`). This pack redraws the four glyphs beside the blue 32px
farmer's real head, a little larger and each in its own colour so it reads at 1x, and
adds a Zzz: a view cue (not a `Reactions.KINDS` kind) that rises from the farmhouse
at night while he sleeps and over his pillow in bed (0129). Each art pixel is 4x4
physical px at 1080p; every glyph must read by day and after the night relight, and
the Zzz is seen mostly at night.

## Deliverables

| Runtime name | Native canvas | Pivot | Frames / seconds / loop | Notes |
|---|---|---|---|---|
| `react_bang_0` | 48x48 | (24,44) | 1 / 0.2 / one-shot | A bold `!`: an upright bar 2-3 px wide and a separate square dot. `flame_hot` fill, `flame` underside, `night` outline. At most 4x9, at least 8 rows. |
| `react_question_0` | 48x48 | (24,44) | 1 / 0.2 / one-shot | A `?`: a round hook and a separate dot. `bone` fill, `bone_dark` underside, `night` outline. At most 6x9, at least 8 rows. |
| `react_note_0` | 48x48 | (24,44) | 1 / 0.2 / one-shot | One eighth note: an oval head bottom-left, a stem, a flag to the right. `gold_light` fill, `gold` underside, `night` outline. At most 7x9, at least 8 rows. |
| `react_heart_0` | 48x48 | (24,44) | 1 / 0.2 / one-shot | A heart: `roof_light` highlight top-left, `roof` body, `roof_dark` underside, `night` outline. At most 7x7, at least 6x6. |
| `react_zzz_0..2` | 48x48 | (24,44) | 3 / 0.4 / loop | The Zzz rising up-right: 0 a small `z` (about 4x4 with its outline); 1 the same plus a medium `z` (about 5x5) up and to the right; 2 the same plus a big `Z` (about 6x6) highest. `moon` fill, `water_light` underside, `night` outline. Letters already shown never move. |

The runtime pack of every row is 96x96 / pivot (48,88), `draw_scale` 0.5, every
native pixel a 2x2 block (Claude imports with `detail_wh` [48,48]).

Rules for every row:

- **Direction and names.** Reactions face `south` only (contract 2.2), `mirror:
  "none"`; the game draws the same glyph whatever way he faces. Files
  `native/react_<kind>/south/01.png` and `native/react_zzz/south/01..03.png` (and
  `runtime/` alike), `01.png` = frame 0. Claude writes `sprites/actors/react_<kind>_0.png`
  and `react_zzz_0..2.png`: the four keep today's names and retire the legacy frames;
  `react_zzz` is the name 0129 registers its stand-in under.
- **The body is the approved idle, copied.** Every frame's body is
  `sprites/actors/idle_south_0.png` NEAREST-resized to 40x40 and pasted at (4,8): hat
  top row 12, boots row 43, x 16..32. It is never redrawn. The game never draws it
  (`PlayerArt.reaction_pose`: only the glyph crop is drawn, beside whatever pose he
  holds); it places the glyph against the real 32px head and is the "body" that
  `validate_bubble` separates the glyph from. Owner question 1 confirms this before
  generating. If the owner refuses, the body comes from an ImageGen strip of the
  farmer standing south instead, under A007's body rules.
- **Where the glyph goes.** Up and to the right of the hat crown, as today's glyphs
  are, now beside the 32-row head. The four reactions sit inside x 33..40, rows 6..14,
  bottom-left aligned: lowest glyph row 14, leftmost glyph column 33. The Zzz sits
  inside x 33..46, rows 1..14, its small `z` touching (33,14). At least 1 transparent
  pixel between any glyph pixel and any body pixel, diagonals included (the hat
  crown reaches x 28 on rows 12-15 and the brim x 31 on rows 16-18). Because the glyph
  is already beside the 32-row head, 0144 sets the view's lift to zero for these
  frames.
- **`bubble_xywh`** on every frame: the measured bounding box of all glyph pixels
  (every 8-connected part that is not the body). It covers every glyph pixel and no
  body pixel (`validate_bubble` in `tools/import_art.py`). Give it native and runtime
  (x2): e.g. a 4x9 bang at (33,6) is native (33,6,4,9), runtime (66,12,8,18). The Zzz
  box grows frame by frame.
- **Glyph drawing.** A 1 px `night` outline all round (`ink` allowed on the
  underside), a flat fill with a lighter top-left edge, strokes at least 2 px thick
  where the size allows, no anti-aliasing, no balloon or panel behind it. A glyph may
  be several parts (the dots, the three letters), each at least 1 px from the next.
- **The Zzz is three nested crops of one source.** Frame k shows letters 1..k+1; the
  crops share the source's left edge, bottom edge and `content_scale`, so earlier
  letters keep their pixels exactly. Code drifts or fades the crop over the farmhouse
  and over the pillow; the frames never move the letters.
- **Never baked:** speech balloon, panel, glow, halo, text other than the glyph shapes
  themselves, shadow, night tint.

## Match these

- `sprites/actors/react_{bang,question,note,heart}_0.png` (48x48, pivot (24,44), older
  30px farmer, `bubble` (33,11,3,8), (32,11,5,7), (34,11,6,8), (31,11,6,6) in
  `src/ui/raster_art.gd`): today's meaning, place and the `night` outline language.
  They are too small to read at 1x: the new ones are larger. Raw sources
  `assets/art_source/player/react_*.png` and the old prompts
  `implementation/sprites/generation/0006-react_*.prompt.txt` show how they were made.
- `sprites/actors/idle_south_0.png` (80x80, exact 2x blocks): the body every frame
  copies. `implementation/fhd-player/pilots/2026-10-06/walk-final-mirrored/native-40/walk/down/01..08.png`:
  the walking head the glyph also floats beside.
- `src/ui/player_view.gd` (`_show_bubble`, `BUBBLE_LIFT`) and `src/ui/player_art.gd`
  (`reaction_pose`): how the glyph crop is drawn.
- `sprites/buildings/house.png` (64x64, drawn at 2x by `ArtPlacement.visual_scale`,
  `smoke_xy` (51,12)) and `sprites/interior/bed.png` (48x64): where the Zzz is drawn.
- `docs/reference-sheet.png`: the look by day and by night.

## How to make it

1. **Prompt:** contract section 8 - BASE + PLAYER_REACTION, replacing its "farmer and
   pose" lines with: "Only the symbol, alone, centred, nothing else: {exclamation mark
   / question mark / one eighth music note / heart / three letters z z Z rising
   diagonally up-right, small to big}. Chunky pixel art on a hard pixel grid, every
   art pixel a flat square block, about {9 / 9 / 9 / 7 / 14} art pixels tall, a dark
   violet-black outline, {the fill colour words of its row}, a lighter top-left edge.
   No balloon, no glow, no shadow, no text." Canvas: the symbol's own target size.
2. **Inputs:** Image 1 `docs/reference-sheet.png` (style reference); Image 2 the
   legacy reaction frame of the same kind enlarged x8 NEAREST (meaning and outline
   reference; the new glyph is larger); for the Zzz, the bang's accepted raw (style
   reference). One glyph per call, one candidate per call,
   `transparent_background=true`. Inspect the raw alpha. At most 3 revisions per raw.
3. **Order:** the bang first; show it composited beside the head at 1x and 4x with
   question 2 before the others. Then the question, note, heart and the Zzz.
4. **Export:** render each glyph through `import_art.render_source` (imported
   read-only, never re-implemented): crop = the measured glyph box in the raw (for
   the Zzz, the three nested crops), one `content_scale` per source chosen so the
   glyph lands on its target height (ideally 1/N, N the raw block size measured on the
   return), `alpha_threshold` 128, `palette` `tools/palette.py:COLOURS` with
   `palette_keys`: bang `night, ink, flame_hot, flame`; question `night, ink, bone,
   bone_dark`; note `night, ink, gold_light, gold`; heart `night, ink, roof_light,
   roof, roof_dark`; zzz `night, ink, moon, water_light`. Render onto an empty 48x48
   canvas with pivot (33,15) and `content_anchor_xy` (0, scaled_h), so the glyph's
   bottom-left pixel lands on (33,14). Then paste the copied idle body under it. There
   is no garment step: the body is copied and the glyph has its own keys. Runtime =
   native x2 NEAREST.
5. If the reduction breaks a glyph (a broken stroke, a lost hole in the `?`, a heart
   with no notch), regenerate it with a blockier source. Never patch pixels.

## Review with the owner

The page (contract 9.5) shows each frame at 1x and 4x; the glyph crop drawn the way
the game draws it (cut at `bubble_xywh`, placed relative to the pivot, no lift) over
`idle_south`, over the walk south 01..08 and over `idle_north` and `idle_west`, next to
the legacy glyph on the legacy farmer (with its 2 px lift); the Zzz playing at 0.4 s
over bed.png's pillow and over `house.png` drawn at 2x beside its chimney (`smoke_xy`);
everything by day and in the night preview, over light, dark, checker and tiled
grass; and the bubble boxes outlined on a separate overlay.

Ask the owner:

1. (before generating) "O jogo só desenha o símbolo; o corpo do quadro serve apenas para posicionar o símbolo ao lado da cabeça. Posso usar o idle sul aprovado, copiado pixel a pixel, como corpo e gerar só os símbolos?"
2. "Cada símbolo (exclamação, interrogação, nota, coração) se lê a 1x ao lado da cabeça, de dia e na prévia noturna? As cores diferentes ajudam a distinguir?"
3. "O Zzz subindo do telhado à noite e sobre o travesseiro lê como 'ele está dormindo'?"

## Acceptance

- [ ] 7 native frames (`react_bang_0`, `react_question_0`, `react_note_0`, `react_heart_0`, `react_zzz_0..2`), each 48x48 pivot (24,44), `south`; 7 runtime frames, each exactly native x2 NEAREST (96x96, pivot (48,88)).
- [ ] `body_is_idle`: the body part of every frame equals `idle_south_0` NEAREST to 40x40 pasted at (4,8), pixel for pixel.
- [ ] `bubble_ok`: `validate_bubble` passes on native and runtime with the recorded boxes; reactions inside x 33..40, rows 6..14 with the lowest glyph row 14; the Zzz inside x 33..46, rows 1..14.
- [ ] Glyph sizes within each row's limits; `zzz_nested`: frame 1 contains frame 0's glyph pixels unchanged, frame 2 contains frame 1's.
- [ ] Glyph colours only from that glyph's `palette_keys`; body colours exactly the idle's; `importer_recipe_matches` true for every glyph.
- [ ] Binary alpha, true transparency; no balloon, glow, shadow, night or text.
- [ ] Every glyph readable at 1x by day and in the night preview; the Zzz the lightest thing over the dark house.
- [ ] `build.py` twice gives identical bytes, `--check` passes, checks.json all `true`.

## Delivery

`implementation/backlog/deliveries/A002-farmer-reactions/` with the files of contract
9.1: `raw/` (+ `.prompt.txt`, `.call.json`), `native/react_<kind>/south/01.png`,
`native/react_zzz/south/01..03.png`, the same under `runtime/`, `preview/`,
`rejected/`, `contract.json` (`palette_mode` "B", `palette` "exact-source",
`colour_ramp` with the idle's RGB as "body (copied idle)" and each glyph colour with
its role, `runtime_canvas_wh` [96,96], `runtime_pivot_xy` [48,88], `detail_wh`
[48,48], per file a recipe with `body_source` (path, sha256, `paste_xy` [4,8]) and the
glyph's `source`, `crop_xywh`, `content_scale`, `content_anchor_xy`, `glyph_pivot_xy`
[33,15], `alpha_threshold`, `palette_keys`, and `bubble_xywh` in `points`, native and
runtime), `checks.json` (plus `bubble_ok`, `body_is_idle`, `zzz_nested`), `build.py`,
`index.html`, `review-log.txt`. After the owner approves in words: `APPROVAL.json`,
`CLAUDE-A002-PROMPT.txt` (mapping e.g.
`runtime/react_bang/south/01.png -> sprites/actors/react_bang_0.png  96x96 pivot (48,88) draw 0.5 detail_wh [48,48]  0.2 s  bubble_xywh (66,12,8,18)`
and `runtime/react_zzz/south/01..03.png -> sprites/actors/react_zzz_0..2.png  0.4 s loop`;
the glyphs are authored beside the 32-row head, so the view's lift is zero for them;
`react_zzz` is a view cue, not a `Reactions.KINDS` kind; it replaces the legacy
reaction frames and 0129's Zzz stand-in for game task 0144), then
`python implementation/backlog/assets.py set A002 approved`.
