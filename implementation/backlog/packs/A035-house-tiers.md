# A035 - The house in three tiers

- **Status:** todo
- **For game task:** 0217
- **Dressed by game tasks:** 0191
- **Spec after game task:** 0191
- **Family:** buildings
- **Mode:** A - raw ImageGen sources, Claude reduces them to the 42-colour palette
- **Size of the job:** 3 tiers x 2 states (whole, hurt) = 6 frames; 6 ImageGen edits in a chain from today's house raw

## What it is for

Money buys a stronger house (game task 0191): tiers I, II and III, each with
more hit points and cheaper repairs, because the house is what keeps the
sleeping farmer safe at night. The house is the farm's landmark, seen all day
and defended all night, so each tier must look clearly sturdier than the last
on the same 6x4 footprint, and tier III must read as a small fortified
farmhouse - still a cozy home, never a castle. All three tiers are drawn at
**full density** (1 art px = 1 logical px), so on screen they are exactly as
big as today's house (which is 64x64 drawn at 2.0) but with the farmer's level
of detail; tier I is today's house redrawn at that density and replaces it.

## Deliverables

Final geometry and states settled by game task 0191. The rows stand as written: all six frames are 128x128 at (64,120), drawn at 1.0, on the house's same 6x4 footprint, so on screen each tier is exactly as big as today's 64x64 house drawn at 2.0. **The states the game plays** (`WorldView`, view only):
- **The tier** is `House.tier(state)`, 1 to 3: `house` for tier I, `house_2` for II, `house_3` for III. A new game's house is tier I. A tier is bought by day at the workshop's UPGRADES tab and is the house from that moment, so the night after it was bought is the new tier's first.
- **Whole or hurt** by the rule today's house uses: `_hurt` below 75% of the whole house (`WorldView.WOUNDED_AT`), whole from there up. Since 0191 the whole house is `Phases.house_full`, which adds the tier's `hp_bonus` (40 for II, 100 for III, levers in `GameData.HOUSE_TIERS`), so a sturdier house takes more hits before it looks hurt.
- **No wreck**, and nothing between the tiers: a bought tier is drawn at once, with no build animation.

Until 0217 the game draws tiers II and III through 0120's road: today's `house` / `house_hurt` drawing, with a small code-drawn plaque of two or three gold studs on the beam over the door. The plaque goes as each tier's own drawing lands; it is never part of the art. Start only when `python implementation/backlog/assets.py next` offers this pack.

| Runtime name | Native canvas | Pivot | Frames / seconds / loop | Notes |
|---|---|---|---|---|
| `house` | 128x128 | (64,120) | 1 / 0.55 / static | Tier I. Today's design (timber farmhouse, terracotta gabled roof, gable window, chimney on the right, stone footing, central door and stoop) at full density. Visible about 112 x 110 (x 8-119, rows 10-119). Points below. |
| `house_hurt` | 128x128 | (64,120) | 1 / 0.55 / static | Tier I hurt: today's damage language (one roof hole with dark rafters, one split beam, chipped footing stones, one cracked pane that stays a pane). Same silhouette and points as `house`. |
| `house_2` | 128x128 | (64,120) | 1 / 0.55 / static | Tier II: the same house, sturdier - a taller dressed-stone footing, a small shingled porch roof over the door on two posts, plank shutters beside the windows, a roof dormer with a window, iron strap hinges. Visible at most 112 wide, rows at least 4-119. |
| `house_2_hurt` | 128x128 | (64,120) | 1 / 0.55 / static | Tier II hurt, same damage language. Same points as `house_2`. |
| `house_3` | 128x128 | (64,120) | 1 / 0.55 / static | Tier III, a small fortified farmhouse: ground storey faced in fieldstone, an iron-banded door, heavy shutters with iron bars, timber corner braces, a small roofed bell-and-lookout gable on the ridge. No battlements, towers, spikes, weapons or flags. Visible at most 112 wide, rows at least 0-119. |
| `house_3_hurt` | 128x128 | (64,120) | 1 / 0.55 / static | Tier III hurt, same damage language. Same points as `house_3`. |

- **This table explicitly overrides the buildings default** (width
  footprint_w*16 + up to 16, pivot (W/2, H-4)) for the house only:
  128x128 / (64,120) is today's 64x64 / (32,60) at `visual_scale` 2.0, so the
  on-screen size, the placement on the 6x4 footprint and the 3x3 slice grid
  (columns 48/32/48, rows 56/32/40) stay exactly as today. Claude removes
  `house` from `ArtPlacement.visual_scale`'s 2.0 list and cuts the slices
  (`house_<c>_<r>`, `house_2_<c>_<r>`...) from these frames in 0217; Codex
  delivers whole images only.
- **Fixed in all six frames:** the door and stoop (today's doorstep bottom row
  59, x 24-35 becomes row 119, x 48-71), the chimney (so `smoke_xy` is the
  same pixel) and the ground-floor left window (so `light_xy` is the same
  pixel). The farmer's entrance and the guardian's porch (A003) never move.
  The door is farmer-sized: 14-16 wide x 28-34 tall.
- **Points** per tier, identical in whole and hurt, on opaque pixels:
  `windows_xy` + `window_rects_xywh` (3-8 panes, the same count in both lists,
  each rect covering glass only); `light_xy` on the left ground-floor pane;
  `smoke_xy` on the chimney's top opaque pixel. Today's points x2 are the
  guide: windows (64,66), (38,90), (82,90), (60,90), (104,92); light (38,90);
  smoke (102,24). Measure the real ones on the exported frames.
- **Glass is unlit:** dark glass (`night_light`, `water_dark`, `ink_soft`) with
  a pale glint of at least 2 px per pane (`bone` or `moon`, which also keeps
  `check_house_art.py`'s "pane survives at native size" rule); never `flame`,
  `flame_hot` or `gold_light` fill. Today's house bakes warm panes; the tiers
  do not - the runtime lights them at night.
- Directions: `none`. No mirrors. No `_wreck`: a fallen house loses the night.
- Never baked: a fence, yard, path, ground, garden, the guardian, smoke, glow,
  a shadow, text or a tier number, pips or coloured bands.

## Match these

- `sprites/buildings/house.png`, `house_hurt.png` (64x64, pivot (32,60), drawn at
  2.0; visible 56x55) and raws `assets/art_source/buildings/house/whole.png`,
  `hurt.png` (1254x1254, shared `crop_xywh` [114,134,1082,1053], `content_scale`
  0.0518): the identity, the damage language and the shared-crop practice. They
  are the **edit targets** of the chain below.
- `implementation/sprites/generation/0011-house_hurt.prompt.txt`: the wording
  that kept framing, door and panes while adding damage.
- `assets/art_source/masters/house.png`, `style-day.png`, `style-night.png`:
  landmark look and night mood.
- Farmer `implementation/fhd-player/pilots/2026-10-06/walk-final-mirrored/native-40/walk/down/01.png`
  (body 16x32): door height and detail density to match.
- `sprites/buildings/workshop.png` (48x48 at 2.0): the half-density stations
  the house will now out-detail; the materials stay the same.
- `docs/reference-sheet.png`: the farmhouse by day and by night.

## How to make it

1. Prompt = PROMPTS.md BASE (braces: canvas 128x128, pivot 64,120) + HOUSE
   (replace "Target 64x64 over an existing 48x48 logical footprint" with
   "Target 128x128 over the 6x4-cell (96x64 px) footprint, full density: about
   112 art pixels across the house body"; replace "Keep window planes available
   for separate runtime amber glow" with "Window glass unlit: dark glass with a
   small pale glint") + CORRECTION for revisions. Every call:
   `transparent_background=true`, "preserve framing, dimensions, ground
   baseline, door, stoop, chimney and window positions".
2. The chain, one ImageGen edit per call, each accepted raw the edit target of
   the next:
   - `house`: edit of `assets/art_source/buildings/house/whole.png` - finer
     pixel clusters for full density and unlit glass; nothing else changes.
   - `house_hurt`: edit of the accepted `house` raw, adding the damage of
     `house/hurt.png` (attached as "damage reference").
   - `house_2`: edit of the accepted `house` raw, adding the tier II
     construction; `house_2_hurt`: edit of the accepted `house_2` raw.
   - `house_3`: edit of the accepted `house_2` raw, adding the tier III
     construction; `house_3_hurt`: edit of the accepted `house_3` raw.
   Leave headroom above the roof in tier I's framing so tier III's gable fits.
3. Export with the mode A recipe: **one** crop box (the union of the six
   opaque bboxes), **one** `content_scale` and **one** `content_anchor_xy` for
   all six frames, so walls, door and chimney land on the same pixels in every
   tier and state. Pick the scale so tier I's body is about 112 px wide and its
   lowest opaque row is 119. If the reduction shows 2x2 blocks (half density),
   regenerate tier I with finer clusters; never upscale.

## Review with the owner

`index.html` shows the six frames at 1x and 4x, by day and in the night
preview, plus a second night preview with each window rect filled with `flame`
(preview only, never in `native/`); today's `house.png` drawn at 2x beside tier
I (same on-screen size); tiers I, II, III side by side; whole/hurt blink per
tier; the farmer frame at the door, feet on the stoop row; over tiled
`sprites/terrain/grass.png` with the 6x4 footprint outlined; points on an
overlay.

Ask the owner:
- "A Casa I redesenhada com o detalhe do fazendeiro ainda é a nossa casa? Ela substitui a de hoje."
- "As Casas II e III mostram melhoria clara, e a III parece uma casa de fazenda fortificada sem virar castelo?"
- "As janelas sem brilho pintado (o jogo acende à noite) ficam boas de dia e na prévia noturna?"

## Acceptance

- [ ] 6 frames, all 128x128 / (64,120); one crop, scale and anchor for all six.
- [ ] Lowest opaque row 119; body centred on x 64 (±1); visible width at most 112 in every tier.
- [ ] Full density: no 2x2 pixel blocks; detail comparable to the farmer.
- [ ] Door, stoop, chimney and the left ground-floor window on the same pixels (±1) in all six frames.
- [ ] Per tier, `windows_xy`, `window_rects_xywh`, `light_xy`, `smoke_xy` identical in whole and hurt, on opaque pixels, inside their rects.
- [ ] Every pane has at least 2 `bone` or `moon` glint px and no `flame`, `flame_hot` or `gold_light`.
- [ ] Each tier is visibly sturdier through construction, not colour bands or pips; tier III has no castle features.
- [ ] Mode A only 42 colours; `importer_recipe_matches`; binary alpha; no ground, fence, shadow, smoke, glow or text.
- [ ] `build.py` twice is byte-identical and `--check` passes; checks.json all `true`.

## Delivery

Folder `implementation/backlog/deliveries/A035-house-tiers/` with `raw/`,
`native/<id>/none/01.png` (`house`, `house_hurt`, `house_2`, `house_2_hurt`,
`house_3`, `house_3_hurt`), `preview/`, `rejected/`, `contract.json`,
`checks.json`, `build.py`, `index.html`, `review-log.txt`. `supersedes` stays
empty (today's house art is not a delivery folder); the handoff says instead
that tier I replaces the `house` / `house_hurt` manifest entries sourced from
`assets/art_source/buildings/house/`.

`CLAUDE-A035-PROMPT.txt` maps
`native/<id>/none/01.png -> sprites/buildings/<id>.png 128x128 pivot (64,120) draw 1.0 static`
for the six ids, lists every tier's points, and says: remove `house` from
`ArtPlacement.visual_scale`'s 2.0 list; cut the slices from these frames;
update `tools/check_house_art.py`, which hard-codes 64x64, the five window
points and `smoke_xy` (51,12) today. They replace 0191's code-marked stand-ins
in game task 0217.

Last step, only after the owner approves in words recorded verbatim in
`APPROVAL.json`: `python implementation/backlog/assets.py set A035 approved`.
