# A003 - The porch guardian

- **Status:** todo
- **For game task:** 0145
- **Dressed by game tasks:** 0131
- **Spec after game task:** 0131
- **Family:** guardian
- **Mode:** A - raw ImageGen sources, Claude reduces them to the 42-colour palette
- **Size of the job:** 1 character, 4 states, 12 frames (1 still, strips of 4, 4 and 3)

## What it is for

At night the farmer sleeps and the player becomes the guardian: the old scarecrow
that stands by the farmhouse porch. By day it is an ordinary, slightly slumped farm
scarecrow; at the reality switch it wakes, straightens and its eyes light; all night
it stands awake with two small warm eyes; and it points each time the player places
something. It stands on the house footprint beside the door, next to the 2x
farmhouse, and must read at 1080p as a friendly guardian a little taller than the
32px farmer - by day, and after the night relight with only its eyes glowing. It is
unique on the farm: the straw decoy defence (A037) and the Scarecrow King boss
(A053) must never look like it.

## Deliverables

**Settled by game task 0131** (2026-10-08) from the stand-in it draws (`PlaceholderArt.ART`, `src/ui/guardian_view.gd`): the table below is final. The guardian stands on the house's own footprint, on its front-left corner cell (`House.porch` + (-3,-1), clear of the door and most of the lit windows). Its pivot is on that cell's bottom middle, drawn at 1.0 in the world, lit by the night ramp like the house and y-sorted one pixel in front of it. The states play as the table says: `day` by day; `wake` once when the night begins, then `night`; `point` once when game task 0133 asks for it, then `night`. On every lit frame the stand-in's eyes are native (13,12) and (18,12), the points `lighting.gd` puts its glow and one-pixel cores on today. The delivered frames carry their own measured points, which replace these. Start only when `python implementation/backlog/assets.py next` offers this pack.

| Runtime name | Native canvas | Pivot | Frames / seconds / loop | Notes |
|---|---|---|---|---|
| `guardian_day_0` | 32x48 | (16,44) | 1 / 1.0 / static | Day pose: head bowed 1-2 px, arms resting along the crossbar, eyes closed (dark stitches). No light points. |
| `guardian_wake_0..3` | 32x48 | (16,44) | 4 / 0.12 / one-shot | 01 the day pose with the straw tufts lifting, eyes still dark; 02 head lifts, eyes open and lit; 03 shoulders square, arms rise to horizontal; 04 the settled night stance (the same pose as night 01). Light points on 02-04. |
| `guardian_night_0..3` | 32x48 | (16,44) | 4 / 0.25 / loop | 01 rest, eyes lit; 02 shirt tails and straw tufts blow 1-2 px west, head tilts 1 px; 03 rest with head and arm cuffs 1 px lower; 04 tails and tufts blow 1-2 px east. 04 leads back to 01. Light points on every frame. |
| `guardian_point_0..2` | 32x48 | (16,44) | 3 / 0.1 / one-shot | 01 anticipation: the viewer-left arm drops and draws in; 02 that arm swings up and out to the upper left (about 45 degrees), straw cuff open; 03 hold, arm 1 px lower, leading back to night 01. Light points on every frame. |

- **Direction:** `none`, `mirror: "none"`. Nothing is mirrored by the delivery.
- **Size:** standing visible body about 24 wide x 38 tall (+-2): hat top near row 6,
  arm line (crossbar) about rows 15-17, the post's foot on row 43 (`pivot_y - 1`),
  the post centred on x=16 (+-1). Every frame, the point arm included, stays inside
  columns 2..29. Hat-top-to-post-foot height is the same in all 12 frames (+-1 px).
  The post's foot never moves.
- **Eyes:** by day two closed eyes, each a 2x1 horizontal `ink` stitch (asleep; never
  an X - the decoy A037 has X eyes). When lit, each eye is a 1x1 or 2x1
  cluster of `flame_hot` (one `flame` pixel allowed), never a halo; nothing else on
  the scarecrow is a light colour. The glow is code.
- **Metadata:** on every lit frame (wake 02-04, all night, all point) `light_xy` =
  the viewer-left eye and `lights_xy` = `[viewer-left eye, viewer-right eye]` (two
  distinct points, the first equal to `light_xy`), each on an opaque eye pixel, in
  native coordinates, measured per frame and stored per frame in contract.json.
  `lighting.gd` puts one small warm glow on each (game task 0145). Day and wake 01
  have no points.
- **Colours (guide for the prompt, reduced by the recipe):** hat `gold`/`gold_light`
  with a `wood_dark` band; burlap head `bone_dark`/`soil_light`; shirt the `cloth`
  ramp with one `roof` patch; straw tufts `gold`/`gold_dark`; crossbar and post
  `wood`/`wood_dark`; outline `ink`. `palette_keys` default `null`; if reduction
  turns the eyes or shirt into a wrong ramp, use for all 12 frames: `ink, ink_soft,
  gold_dark, gold, gold_light, wood_dark, wood, wood_light, soil_dark, soil,
  soil_light, bone_dark, bone, cloth_dark, cloth, cloth_light, roof_dark, roof,
  flame, flame_hot`.
- Runtime files go to `sprites/props/guardian_<anim>_<i>.png`, the folder 0131
  registered.

## Match these

- `implementation/fhd-player/pilots/2026-10-06/walk-final-mirrored/native-40/walk/down/01.png`
  (40x40, pivot (20,36), visible 16x32): the guardian is about 6 px taller and reads
  as an object, not a second farmer. Its hat echoes his straw hat and brown band.
- `assets/art_source/masters/farmer.png`: material reference for the straw hat and
  the blue cloth only, not the body.
- `sprites/buildings/house.png` (64x64, drawn at 2.0, so 128x128 logical on screen)
  and `assets/art_source/masters/house.png`: the timber and terracotta it stands by.
- `sprites/buildings/gun_tower.png` (32x48, pivot (16,44), visible 19x25): the same
  canvas and pivot convention; the guardian is taller and narrower.
- `sprites/enemies/walker_walk_0.png`: rot green belongs to the enemies; keep it off
  the guardian.
- `implementation/backlog/packs/A037-decoy.md` (hatless straw dummy, X eyes, red-brown
  shirt) and `A053-scarecrow-king.md` (dark, crowned, no hat, no pole): the two other
  scarecrows. The guardian is the only one with the straw hat, the blue shirt and
  the post.
- `docs/reference-sheet.png`, `assets/art_source/masters/style-day.png` and
  `style-night.png`: outline, light from the upper left, the night mood.

## How to make it

1. Assemble every prompt per contract section 8: BASE from
   `implementation/sprites/generation/PROMPTS.md` (canvas 32x48, contact pivot
   16,44), STRIP for strips, CORRECTION for revisions. PROMPTS.md has no guardian
   section; add these lines to every call:
   "A friendly old farm scarecrow that guards the farmhouse porch: burlap-sack head
   with a stitched mouth and two stitched eyes, an old wide straw hat with a brown
   band, a faded blue work shirt with one terracotta patch, straw tufts at the neck
   and cuffs, arms along a wooden crossbar, standing on one wooden post. Whimsical
   and protective, not creepy: no rot, blood, crown, claws or pumpkin head. About 38
   native pixels from hat top to the foot of the post. No ground, grass, base,
   shadow or glow."
2. **Identity master:** one call, the day pose alone, `transparent_background=true`.
   Inputs: Image 1 `docs/reference-sheet.png` (style reference); Image 2 the farmer
   walk frame above, enlarged by nearest (scale reference); Image 3
   `assets/art_source/masters/farmer.png` (hat and cloth material reference only).
   Check it through the recipe preview at 32x48 before anything else.
3. **Day + wake strip:** one call, 5 equal cells (STRIP, N=5): the day pose, then
   wake 01-04 as in the table. Input: the accepted master (identity master).
   `guardian_day_0` is cell 1, wake is cells 2-5, one `content_scale` for all five.
4. **Night idle strip** (4 cells) and **point strip** (3 cells): one call each, with
   the master and the accepted wake raw attached (identity and scale reference).
   Night 01 matches wake 04; point 03 leads back to night 01.
5. **Export:** crop each frame from its measured cell with the crop's bottom edge on
   the post's lowest opaque raw row and the crop centred on the post, so the default
   anchor `(scaled_w // 2, scaled_h)` puts the foot on row 43 and the post on x=16.
   One `content_scale` per strip; pick each strip's scale so the hat-to-foot height
   equals the day frame's (+-1 px) and record it.
6. If reduction loses the lit eyes, the stitched mouth or the hat brim, regenerate
   the source (section 3). Never patch output pixels.
7. Measure `light_xy` / `lights_xy` on the exported native frames.

## Review with the owner

The page (contract 9.5) shows every state at 1x and 4x: the day still, wake, night
and point playing at their seconds and as still strips; the night preview with the
eye points marked on an overlay plus a small warm dot at each, labelled "code glow,
approximation"; beside the farmer walk frame on one ground line; beside
`sprites/buildings/house.png` drawn at 2x nearest, as the game draws it, with the
guardian by the door; over light, dark, checker and tiled grass, with a 16 px grid.

Questions for the owner:

1. "O espantalho parece o guardião amigável da fazenda, e não um inimigo ou o espantalho-isca? O tamanho ao lado do fazendeiro e da casa está certo?"
2. "À noite só os olhos acendem. Na prévia noturna eles aparecem o bastante, ou você quer olhos maiores (2 pixels)?"
3. "O gesto de apontar (o braço para cima, à esquerda) funciona quando você coloca uma defesa, ou prefere outro gesto?"

## Acceptance

- [ ] 12 frames: day 1, wake 4, night 4, point 3; every one 32x48 with pivot (16,44).
- [ ] Lowest opaque row 43 in every frame; post centred on x=16 (+-1); the foot never moves; hat-to-foot height equal (+-1) across all frames.
- [ ] Everything inside columns 2..29; nothing clipped.
- [ ] Binary alpha with a true transparent background; no shadow, ground, grass, glow, halo, night tint or text.
- [ ] Only the 42 colours through `render_source`; one `content_scale` per strip; `importer_recipe_matches` true.
- [ ] Day and wake 01 have dark eyes and no points; every lit frame has two warm eye clusters, `light_xy` and `lights_xy` on opaque eye pixels.
- [ ] Wake 04 and night 01 are the same pose; the night loop closes; point ends ready for night 01.
- [ ] Reads at 1x by day and in the night preview; does not read as an enemy, the decoy or a second farmer.
- [ ] `build.py` twice gives identical bytes, `--check` passes, checks.json all `true`.

## Delivery

`implementation/backlog/deliveries/A003-guardian/` with the files of contract 9.1:
`raw/` (each return with `.prompt.txt` and `.call.json`), `native/guardian_day/none/01.png`,
`native/guardian_wake/none/01..04.png`, `native/guardian_night/none/01..04.png`,
`native/guardian_point/none/01..03.png` (no `runtime/`: draw scale 1.0), `preview/`,
`rejected/`, `contract.json` (`palette_mode` "A", the points per frame),
`checks.json`, `build.py`, `index.html`, `review-log.txt`. After the owner approves
in words: `APPROVAL.json`, `CLAUDE-A003-PROMPT.txt` (mapping e.g.
`native/guardian_wake/none/01..04.png -> sprites/props/guardian_wake_0..3.png  32x48 pivot (16,44) draw 1.0  0.12 s one-shot`,
replacing 0131's placeholder for game task 0145), then
`python implementation/backlog/assets.py set A003 approved`.
