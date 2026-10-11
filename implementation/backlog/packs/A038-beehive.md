# A038 - The beehive

- **Status:** todo
- **For game task:** 0237
- **Dressed by game tasks:** 0226
- **Spec after game task:** 0226
- **Family:** defences
- **Mode:** A - raw ImageGen sources, Claude reduces them to the 42-colour palette
- **Size of the job:** 8 tower frames (2 levels x 4 states), 1 animation of 3 frames

## What it is for

The beehive (`beehive`) is a one-cell tower that stings what comes near and
keeps stinging; it is stronger with sunflowers planted round it. It stands in
the tower line at night beside gun towers and mortars, and it must read as a
farm hive, not a gun: warm timber, a terracotta roof, a dark entrance slot. The
bee swarm (`bee_swarm`) is a tiny looping cloud the view draws on an enemy
while the sting lasts. Both must read at 1x after the night relight.

## Deliverables

Final geometry settled by game task 0226. The rows stand as written: the hive 32x48 standing on (16,44) at two levels in four states each, and the bee swarm 8x8 round (4,4) in three looping frames. **How the game plays them:** a hive is one cell, a tower that stings the nearest thing in its reach once a second - one not yet stung while there is one - and level two, its only upgrade and the family's last (`Building.why_not_upgrade` refuses a third), stings two at a time. It wears `_fire` for the first fifth of its reload after each sting, `_hurt` below three quarters of its hit points (firing first, as the towers do), and `_wreck` once it falls, as rubble the morning sweeps, at the level it stood at. The swarm loops on every stung enemy, round its head, for as long as the sting lasts - four seconds, topped up by another sting and never doubled. Until 0237 the hive is the mortar tinted honey at each level and state and the swarm is drawn in code by `HiveArt`, through 0120's road. Start only when `python implementation/backlog/assets.py next` offers this pack.

| Runtime name | Native canvas | Pivot | Frames / seconds / loop | Notes |
|---|---|---|---|---|
| `buildings/beehive` | 32x48 | (16,44) | 1 / static (0.55, loop false) | Level 1 whole. Visible about 16-18 wide x 20-22 tall, base centred on x 16, lowest opaque row 43. Points: `muzzle_xy`, `muzzles_xy` (1 point), `muzzle_region_xywh`. |
| `buildings/beehive_hurt` | 32x48 | (16,44) | 1 / static | L1 cracked boards, a missing roof shingle, a leaning leg; entrance intact. Same points rule. |
| `buildings/beehive_fire` | 32x48 | (16,44) | 1 / static | L1 whole plus a tiny cluster of 3-5 bees (1-2 px specks) just leaving the entrance - the "muzzle form". Same body pixels as whole. Points at the entrance. |
| `buildings/beehive_wreck` | 32x48 | (16,44) | 1 / static | L1 box toppled off its stand, roof slid off, broken boards; low on the same base, inside the whole's width. No bees, no honey puddle, no points. |
| `buildings/beehive_2`, `_2_hurt`, `_2_fire`, `_2_wreck` | 32x48 | (16,44) | 1 each / static | Level 2, same four state rules. Visible about 20-22 wide x 25-28 tall. |
| `effects/bee_swarm_0..2` | 8x8 | (4,4) | 3 at 0.1 s, loop | 4-6 bees, each 1-2 px (gold body, ink stripe), in a loose cloud centred on (4,4) ±1; visible inside x 1..6, y 1..6. Poses `cloud_a`, `cloud_b`, `cloud_c`: the bees shuffle, the cloud does not grow or shrink by more than a quarter. Frame 2 leads back to frame 0. |

- Every row: dir `none`, `mirror: "none"`, draw scale 1.0.
- **The stand-in until 0237** (task 0226): `PlaceholderArt` registers the
  eight tower names with `buildings/mortar`, `mortar_hurt`, `mortar_fire`,
  `mortar_wreck` and their `_2` frames as stand-ins, tinted honey, and
  `HiveArt` (`src/ui/hive_art.gd`) draws the swarm's three frames at this
  canvas and pivot - five bees of two pixels, gold with an ink stripe. The
  pack has no icon: the hotbar shows `beehive` scaled into its 16x16 box.
- **Points** (contract section 5), per level, on whole, hurt and fire:
  `muzzle_xy` on an opaque pixel of the entrance slot (expected near x 15-19,
  y 33-37 for L1 and y 28-34 for L2 - measure the real art), `muzzles_xy` =
  `[muzzle_xy]`, `muzzle_region_xywh` = the 5x5 box `[x-2, y-2, 5, 5]` round it.
  The view starts its sting cue there. Wrecks have none.
- **Levels change the construction.** L1: a single timber hive box with a
  pitched terracotta-shingle roof on a low four-leg stand, a dark entrance slot
  with a small landing board at the front. L2: rebuilt broader and sturdier - a
  deeper box with iron corner straps, a wider overhanging roof with a small
  vent, a stone-and-timber footing, a wider entrance with an iron guard. Never
  two L1 boxes stacked, never level pips or bands. L1 and L2 whole differ in at
  least 80 native pixels.
- Delivery paths: `native/beehive/none/01.png`, `native/beehive_hurt/none/01.png`
  ... `native/beehive_2_wreck/none/01.png`, `native/bee_swarm/none/01..03.png`
  (11 files).

## Match these

- `sprites/buildings/gun_tower.png`, `gun_tower_hurt.png`, `gun_tower_fire.png`,
  `gun_tower_wreck.png`, `gun_tower_2*.png` - the tower family's canvas, base
  line (row 43), outline and how hurt, fire and wreck differ. Open them at 4x.
- `assets/art_source/defences/gun_tower/level-3.png` - the raw 2x2 four-state
  sheet layout every tower level is cut from (one raw, one scale per level).
- `sprites/buildings/mortar.png` - a low tower on the same canvas, for height.
- `sprites/effects/muzzle_0..2.png`, `impact_0..2.png` (12x12) - effect scale
  and cluster style; the swarm is smaller still.
- The 32 px farmer frame `implementation/fhd-player/pilots/2026-10-06/walk-final-mirrored/native-40/walk/down/01.png`.
- `docs/reference-sheet.png` - timber, terracotta and the "CONSTRUA SUA DEFESA" panel.

## How to make it

1. Prompt = BASE + TOWER (from `implementation/sprites/generation/PROMPTS.md`)
   with "beehive" in place of the weapon list, plus the "Four-state sheet
   contract" and "LAYOUT CLEARANCE" paragraphs of
   `implementation/sprites/generation/0013-mortar-level-2.prompt.txt`, with the
   fire cue redefined as "a tiny cluster of bees leaving the entrance".
   `transparent_background=true` on every call. Attach `docs/reference-sheet.png`
   (style reference) and `sprites/buildings/gun_tower.png` (scale and family
   reference) and say each role.
2. **Master** (1 call, at most 2 fresh candidates): the L1 hive whole, one object.
3. **One 2x2 four-state sheet per level** (2 calls): whole top-left, hurt
   top-right, fire bottom-left, wreck bottom-right, with the master (and for L2
   the accepted L1 sheet) attached as identity master. Every state of a level is
   cut from that one raw; the four cut boxes share no opaque pixel.
4. **Swarm strip** (1 call): STRIP with N=3, "a loose cloud of five cartoon
   honeybees", equal cells, the cloud centred in each cell.
5. Export with the mode A recipe (contract section 3, `render_source` imported
   read-only): one `content_scale` per level across its four states and one for
   the swarm strip; `content_anchor_xy` puts the base centre on x 16 and the
   lowest opaque row on 43; `alpha_threshold` 128; `palette_keys` null. If bees
   reduce to blue or grey, regenerate rather than patch.

## Review with the owner

The page (contract 9.5) shows the two levels x four states as a grid at 1x and
4x, day and night preview, beside `sprites/buildings/gun_tower.png` and the
farmer frame on one ground line over a 16 px grid and tiled grass; the points on
an overlay; the swarm looping at 0.1 s at 1x and 4x, over grass and over a
walker frame (`sprites/enemies/walker_walk_0.png`) as it will be drawn.

Ask the owner:

1. "A colmeia do nível 2 parece uma melhoria clara do nível 1, sem parecer duas colmeias empilhadas?"
2. "O enxame (8x8) se lê como abelhas na prévia noturna, em cima do zumbi, ou vira um borrão?"

## Acceptance

- [ ] 11 files; every tower frame 32x48, pivot (16,44); swarm 8x8, pivot (4,4).
- [ ] Tower frames: bbox left >= 1, top >= 1, right <= 30, lowest opaque row 43,
      base centred on x 16 (±1); all 8 frames distinct.
- [ ] One raw and one `content_scale` per level across whole/hurt/fire/wreck;
      cut boxes share no opaque pixel; L1 and L2 whole differ by >= 80 pixels.
- [ ] Fire keeps the whole's body; the bee cue is small and inside the canvas;
      no permanent bees on whole.
- [ ] Points on opaque pixels, inside their region; none on wrecks.
- [ ] Swarm: 3 distinct frames from one raw at one scale, unclipped, loop closes.
- [ ] Binary alpha, true transparent raws, only the 42 colours, recipe matches,
      build twice identical; no shadow, ground, glow, night version or text.
- [ ] Reads as a hive (not a gun) at 1x by day and in the night preview.

## Delivery

Folder `implementation/backlog/deliveries/A038-beehive/` with `raw/` (each return
plus `.prompt.txt` and `.call.json`), `native/`, `preview/`, `rejected/`,
`contract.json`, `checks.json`, `build.py`, `index.html` and `review-log.txt`
(contract section 9); after approval `APPROVAL.json` and `CLAUDE-A038-PROMPT.txt`
(mapping each `native/<anim>/none/NN.png` to `sprites/<runtime name>.png`, with
the per-level points). Last step, only after the owner approves in words
recorded verbatim in `APPROVAL.json`:
`python implementation/backlog/assets.py set A038 approved`.
