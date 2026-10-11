# A039 - The pumpkin catapult

- **Status:** todo
- **For game task:** 0238
- **Dressed by game tasks:** 0227
- **Spec after game task:** 0227
- **Family:** defences
- **Mode:** A - raw ImageGen sources, Claude reduces them to the 42-colour palette
- **Size of the job:** 12 tower frames (3 levels x 4 states), 1 projectile of 3 frames, 1 effect of 4 frames

## What it is for

The catapult (`catapult`, never `pumpkin`, which is the crop) is a one-cell
tower that lobs pumpkins in an arc and splashes a small area where they land -
the autumn harvest turned into a weapon. It stands in the tower line at night
beside the mortar, which it must not copy: timber arm, rope, a bucket with a
pumpkin, no metal tube. The pumpkin shot flies where the view draws a mortar
shell today, and the splat bursts where it lands. All of it must read at 1x
after the night relight, and the splat must read as pumpkin, not blood.

## Deliverables

Final geometry settled by game task 0227. The rows stand as written: the catapult 32x48 standing on (16,44) at three levels in four states each, the pumpkin shot 8x8 round (4,4) in three looping frames, and the splat 20x16 on (10,14) in four one-shot frames. **How the game plays them:** a catapult is one cell, a tower that throws a pumpkin from the store every four seconds at the nearest thing in its reach - level three, the family's last, two at a time: a volley. A pumpkin is lobbed at the cell its target stood on and lands there a second later, whoever has walked off, splashing two tiles round (three at level three). The tower wears `_fire` for the first fifth of its reload after each throw, `_hurt` below three quarters of its hit points (firing first, as the towers do), and `_wreck` once it falls, as rubble the morning sweeps, at the level it stood at. The shot tumbles on a 14-pixel arc the view draws over its straight line, and the splat bursts once on the cell it lands on, over the ground and under the night's relight. With no pumpkins a catapult throws a stone - the plain dot every shot is, and no splat. Until 0238 the catapult is the auto crossbow burnt to pumpkin orange and drawn smaller (0.7, 0.8 and 0.9) so the levels grow, the shot is drawn in code by `CatapultArt`, and the splat is the splash in pumpkin, through 0120's road; the shot leaves from the cell's middle until the real fire frames' `muzzle_xy` land, and from there after. Start only when `python implementation/backlog/assets.py next` offers this pack.

| Runtime name | Native canvas | Pivot | Frames / seconds / loop | Notes |
|---|---|---|---|---|
| `buildings/catapult` | 32x48 | (16,44) | 1 / static (0.55, loop false) | L1 whole: arm cocked back (bucket low at the west end) with one pumpkin loaded. Visible about 20-22 wide x 17-19 tall, low and broad; base centred on x 16, lowest opaque row 43. Points at the loaded bucket. |
| `buildings/catapult_hurt` | 32x48 | (16,44) | 1 / static | L1 cracked arm, frayed torsion rope, a split runner; pumpkin still loaded. |
| `buildings/catapult_fire` | 32x48 | (16,44) | 1 / static | L1 release: same base and frame pixels, arm thrown up against its stop bar toward the upper right (east), bucket empty with a tiny 2-3 px fleck of orange pulp at its lip - the "muzzle form". No pumpkin in flight, no motion streaks. Points at the bucket. |
| `buildings/catapult_wreck` | 32x48 | (16,44) | 1 / static | L1 snapped arm across the broken base, low, inside the whole's width; no pumpkin, no points. |
| `buildings/catapult_2` + `_hurt`, `_fire`, `_wreck` | 32x48 | (16,44) | 1 each / static | L2, same state rules. Visible about 23-25 wide x 20-22 tall. |
| `buildings/catapult_3` + `_hurt`, `_fire`, `_wreck` | 32x48 | (16,44) | 1 each / static | L3, same state rules. Visible about 26-28 wide x 24-27 tall. |
| `effects/pumpkin_shot_0..2` | 8x8 | (4,4) | 3 at 0.1 s, loop | A small round pumpkin, 5-6 px, with a 1 px dark stem, tumbling: stem at 12, 4 and 8 o'clock. Visible inside x 1..6, y 1..6. Frame 2 leads back to frame 0. |
| `effects/pumpkin_splat_0..3` | 20x16 | (10,14) | 4 at 0.1 s, one-shot | Ground burst of orange pulp chunks and pale seeds. Poses `squash` (small, low), `burst` (largest area, peak 8-13 px tall), `fall` (chunks lower and spreading), `bits` (a few small bits, smallest area). Inside the canvas with 1 px clear; no stain or puddle left behind. |

- Every row: dir `none`, `mirror: "none"`, draw scale 1.0. The catapult throws
  toward the upper right like every existing tower; never deliver a mirrored copy.
- **The stand-in until 0238** (task 0227): `PlaceholderArt` registers the
  twelve tower names with `buildings/auto_crossbow` and its states and levels
  as stand-ins, tinted orange and scaled down; `CatapultArt`
  (`src/ui/catapult_art.gd`) draws the shot's three frames at this canvas and
  pivot - a six-pixel pumpkin, `flame` with `gold_dark` ribs, its `wood_dark`
  stem at 12, 4 and 8 o'clock - and the splat stands in as
  `effects/splash_0..3` tinted. The pack has no icon: the hotbar shows
  `catapult` scaled into its 16x16 box.
- **Points** (contract section 5), per level, on whole, hurt and fire:
  `muzzle_xy` on an opaque pixel of the bucket (the pumpkin in whole and hurt,
  the bucket lip in fire), `muzzles_xy` = `[muzzle_xy]` (one bucket per level),
  `muzzle_region_xywh` = `[x-2, y-2, 5, 5]`. The fire point is where the view
  launches the pumpkin shot (expected near x 22-27, y 20-30, rising with the
  level - measure the real art). Wrecks have none.
- **Base fixed, arm moves.** Whole, hurt and fire of one level share the base
  and frame pixels; only the arm, bucket and load change between whole and fire.
- **Levels change the construction.** L1: a small timber torsion catapult on a
  sled base, rope-twisted bundle, wooden bucket. L2: on four small wheels, an
  iron-banded arm and a rope winch. L3: a heavier frame on a stone footing with
  a stone counterweight box and an iron-shod bucket. Never stacked copies, pips
  or bands. L1 and L3 whole differ in at least 80 native pixels.
- Delivery paths: `native/catapult/none/01.png` ... `native/catapult_3_wreck/none/01.png`,
  `native/pumpkin_shot/none/01..03.png`, `native/pumpkin_splat/none/01..04.png` (19 files).

## Match these

- `sprites/buildings/mortar.png`, `mortar_fire.png`, `mortar_2.png`,
  `mortar_3.png`, `mortar_3_wreck.png` - the low, broad tower on this canvas:
  base line (row 43), level growth and how small the fire cue stays. Open at 4x.
- `assets/art_source/defences/mortar/level-2.png` and
  `implementation/sprites/generation/0013-mortar-level-2.prompt.txt` - the raw
  2x2 four-state sheet and the prompt that produced it.
- `sprites/buildings/gun_tower.png` - the family outline and contrast.
- `sprites/effects/splash_0..3.png` (20x16, pivot (10,14), 0.1 s) - the splat's
  geometry, expansion and dissipation; `impact_0..2.png` for cluster style.
- The pumpkin crop of pack A017 if it is approved by then (match its rind and
  stem colours); otherwise the palette's `flame`/`gold_dark`/`roof_light` ramp
  for the rind and `wood_dark` for the stem.
- The 32 px farmer frame `implementation/fhd-player/pilots/2026-10-06/walk-final-mirrored/native-40/walk/down/01.png`.

## How to make it

1. Prompt = BASE + TOWER with "pumpkin catapult: timber throwing arm, twisted
   rope torsion bundle, a bucket holding one pumpkin, throwing toward the upper
   right" in place of the weapon list, plus the "Four-state sheet contract" and
   "LAYOUT CLEARANCE" paragraphs of `0013-mortar-level-2.prompt.txt`, with FIRE
   redefined as "the arm thrown forward against its stop bar, bucket empty, a
   tiny fleck of pumpkin pulp at its lip". `transparent_background=true` on
   every call. Attach `docs/reference-sheet.png` (style) and
   `sprites/buildings/mortar.png` (scale and family) and say each role.
2. **Master** (1 call, at most 2 fresh candidates): L1 whole, one object.
3. **One 2x2 four-state sheet per level** (3 calls), whole top-left, hurt
   top-right, fire bottom-left, wreck bottom-right; master (and the accepted
   previous level) attached as identity master. All four states of a level are
   cut from that one raw; the cut boxes share no opaque pixel.
4. **Shot strip** (1 call, STRIP N=3) and **splat strip** (1 call, FX section,
   STRIP N=4, poses as in the table).
5. Export with the mode A recipe (`render_source` imported read-only): one
   `content_scale` per level across its four states, one per effect strip;
   `content_anchor_xy` puts the base centre on x 16 and the lowest opaque row on
   43 (effects: the origin on their pivot); `alpha_threshold` 128;
   `palette_keys` null. If the splat reduces to `blood` red, regenerate.

## Review with the owner

The page (contract 9.5) shows three levels x four states as a grid at 1x and 4x,
day and night preview, beside the matching `mortar` level and the farmer frame
on one ground line over a 16 px grid and tiled grass; whole and fire flipping at
0.2 s so the arm swing reads; points on an overlay; the shot looping at 0.1 s
and the splat playing once at 0.1 s, both over grass at 1x and 4x.

Ask the owner:

1. "A catapulta se lê como catapulta de abóbora nos três níveis, ao lado do morteiro?"
2. "No estado parado a concha mostra uma abóbora carregada. Mantém assim ou prefere a concha vazia?"
3. "O respingo da abóbora tem o tamanho certo e não parece sangue na prévia noturna?"

## Acceptance

- [ ] 19 files; tower frames 32x48 / (16,44); shot 8x8 / (4,4); splat 20x16 / (10,14).
- [ ] Tower frames: bbox left >= 1, top >= 1, right <= 30, lowest opaque row 43,
      base centred on x 16 (±1); all 12 frames distinct.
- [ ] One raw and one `content_scale` per level; cut boxes share no opaque pixel;
      whole/hurt/fire share the base; L1 and L3 whole differ by >= 80 pixels.
- [ ] Points on opaque pixels inside their region, one per level and state; none
      on wrecks; the fire point sits on the released bucket.
- [ ] Shot: 3 distinct frames, one raw, one scale, unclipped, loop closes.
- [ ] Splat: 4 distinct frames, one raw, one scale, unclipped; frame 1 has the
      largest area, frame 3 less than frame 1; no puddle.
- [ ] Binary alpha, true transparent raws, only the 42 colours, recipe matches,
      build twice identical; no shadow, ground, glow, night version or text.
- [ ] Readable at 1x by day and in the night preview; distinct from the mortar.

## Delivery

Folder `implementation/backlog/deliveries/A039-catapult/` with `raw/` (each
return plus `.prompt.txt` and `.call.json`), `native/`, `preview/`, `rejected/`,
`contract.json`, `checks.json`, `build.py`, `index.html` and `review-log.txt`
(contract section 9); after approval `APPROVAL.json` and `CLAUDE-A039-PROMPT.txt`
(mapping each `native/<anim>/none/NN.png` to `sprites/<runtime name>.png`, with
the per-level points). Last step, only after the owner approves in words
recorded verbatim in `APPROVAL.json`:
`python implementation/backlog/assets.py set A039 approved`.
