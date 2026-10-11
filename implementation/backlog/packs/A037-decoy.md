# A037 - The scarecrow decoy and zombie bait

- **Status:** todo
- **For game task:** 0236
- **Dressed by game tasks:** 0224, 0225
- **Spec after game task:** 0225
- **Family:** defences
- **Mode:** A - raw ImageGen sources, Claude reduces them to the 42-colour palette
- **Size of the job:** 4 still sprites, 2 animations of 3 frames, 1 icon (2 cuts)

## What it is for

The decoy (`decoy`) is a crude straw dummy on a stake that the player places at
night to pull nearby zombies off their road; they crowd round it and bite it
while the towers work. The zombie bait (`zombie_bait`) is a rotten fish thrown
on the ground at night: for a few seconds the whole crowd turns toward it, then
it is gone. Both are seen at night among walkers (~29 px tall) and towers, so
they must read at 1x after the night relight. The decoy is **not** the porch
guardian (pack A003): no hat, no lit eyes, no glow - a cheap target, a little
shorter than the 32 px farmer.

## Deliverables

Final geometry settled by game task 0225. The rows stand as written: the decoy 16x32 standing on (8,28) in its three states and two three-frame sway strips, the bait 16x16 lying on (8,14), and the bait's icon at 16x16 and 10x10. **How the game plays them:** a decoy is one cell, bitten from its four sides by a crowd that does not collide, so the biters stand on the cells round it; it is `decoy_hurt` below three quarters of its hit points and `decoy_wreck` once it falls, as rubble the morning sweeps; each bite plays the sway strip of the state it is in, west first, whoever bit it (0224). A bait is one cell that the crowd walks onto and stands on to eat - several of them on that one cell at once, drawn under their feet - until it is gone, at its lifetime or once enough have eaten, with no wreck; its icon is the hotbar slot's (`icon_zombie_bait`) and the compact rows' (`hud_zombie_bait`). Until 0236 the decoy and the bait are drawn in code by `DecoyArt` and the icons are the fish's own, rotted green, through 0120's road. Start only when `python implementation/backlog/assets.py next` offers this pack.

| Runtime name | Native canvas | Pivot | Frames / seconds / loop | Notes |
|---|---|---|---|---|
| `buildings/decoy` | 16x32 | (8,28) | 1 / static (0.55, loop false) | Whole. Straw dummy on a wooden T-stake. Visible 11-12 wide (arms spread on the crossbar) x 25-27 tall, x 2..13, lowest opaque row 27, stake centred on x 8. Dir `none`. |
| `buildings/decoy_hurt` | 16x32 | (8,28) | 1 / static | Same dummy and stake: torn shirt, straw spilling, head slumped, one arm hanging. Its alpha shape differs from whole. |
| `buildings/decoy_wreck` | 16x32 | (8,28) | 1 / static | Collapsed: snapped stake, sack head and straw heap on the cell. Visible height at most 8, width at most 14, lowest row 27. |
| `buildings/decoy_sway_0..2` | 16x32 | (8,28) | 3 at 0.1 s, one-shot | Whole decoy struck. Poses: `lean_west_2` (top 2 px west), `rebound_east_1` (top 1 px east), `settle_west_1` (top 1 px west). After frame 2 the view shows `decoy` again. The stake's lowest 4 rows keep the same x (±1) and row 27 in every frame. |
| `buildings/decoy_hurt_sway_0..2` | 16x32 | (8,28) | 3 at 0.1 s, one-shot | The same motion on the hurt decoy; after it the view shows `decoy_hurt`. |
| `buildings/zombie_bait` | 16x16 | (8,14) | 1 / static | A rotting fish lying on the ground, like the mine's footprint. Visible about 12 wide x 5-7 tall, x 2..13, lowest row 13. No puddle, flies or stink lines (the stink and the lure are code). |
| `ui/icon_zombie_bait` | 16x16 | (8,8) | 1 / static (1.0) | Inventory and hotbar icon of the bait kit, visible at most 14, centred, clear padding. |
| `ui/hud_zombie_bait` | 10x10 | (5,5) | 1 / static (1.0) | Same raw crop as the icon, a second `content_scale`; visible at most 8. |

- Every row: dir `none`, `mirror: "none"`, draw scale 1.0, no metadata points.
- The authored sway leans **west first**, and the view plays it as is for any
  biter: 0224 decided not to mirror the strip. Never deliver an east copy.
- **The stand-in until 0236** (task 0224): `DecoyArt` (`src/ui/decoy_art.gd`)
  draws `decoy`, `decoy_hurt` and `decoy_wreck` in code at this canvas and
  pivot, registered as drawn in `PlaceholderArt`, and the view leans the whole
  drawing through the same three poses (`DecoyArt.SWAY_TOPS`). The hotbar shows
  `decoy` scaled into its 16x16 box: this pack has no decoy icon.
- **The bait's stand-in** (task 0225): `DecoyArt` draws `zombie_bait` in code,
  a rot-green fish belly-up on the pivot's row, 12x6 with its outline; the
  icons are `ui/icon_fish` and `ui/hud_fish` tinted green.
- `decoy`, `decoy_hurt` and `decoy_wreck` share one `content_scale` (one raw
  sheet). Each sway strip has its own single `content_scale`, chosen so its
  stake and body height equal `decoy`'s.
- This is the only `icon_zombie_bait`/`hud_zombie_bait`. The kit recipe outputs
  the defence id itself (as `mine_kit` outputs `mine`), so the stock item and
  the hotbar slot are the same id and A045 reuses this icon.
- Delivery paths follow the contract: `native/decoy/none/01.png`,
  `native/decoy_sway/none/01..03.png`, `native/decoy_hurt_sway/none/01..03.png`,
  `native/zombie_bait/none/01.png`, `native/icon_zombie_bait/none/01.png`,
  `native/hud_zombie_bait/none/01.png` (12 files).

## Match these

- `implementation/fhd-player/pilots/2026-10-06/walk-final-mirrored/native-40/walk/down/01.png`
  - the 32 px farmer (16x32 visible): the decoy stays visibly shorter and must
  never be mistaken for him or wear his blue.
- `sprites/buildings/barricade.png`, `barricade_hurt.png`, `barricade_wreck.png`
  (16x24, pivot (8,20)) and raw `assets/art_source/defences/barricade/states.png`
  - the small-defence look, outline weight and the "three states in one row from
  one raw" layout.
- `sprites/buildings/mine.png` (16x16, pivot (8,14), visible 12x8) - the ground
  footprint and contrast of `zombie_bait`.
- `sprites/enemies/walker_walk_0.png` and `assets/art_source/masters/walker.png`
  - the rot greens the bait shares, and the crowd the decoy stands among.
- `sprites/ui/icon_fish.png`, `hud_fish.png`, raw `assets/art_source/ui/fish.png`
  - icon framing and scale; the bait icon must not read as this healthy blue fish.
- `docs/reference-sheet.png` - straw, warm timber and the night panel's mood.

## How to make it

1. Prompt = contract section 8: BASE from `implementation/sprites/generation/PROMPTS.md`
   with this pack's lines as the family section (there is no decoy section),
   STRIP for the sway, ICON for the icon. Every call `transparent_background=true`.
   Attach `docs/reference-sheet.png` (style reference) and the farmer frame
   above (scale reference) and say each role.
2. **Master** (1 call, at most 2 fresh candidates): "an old straw dummy lashed
   to a wooden T-stake planted in the ground: a burlap sack head with stitched
   cross eyes and a stitched mouth, no hat, a ragged faded red-brown shirt
   stuffed with straw, straw tufts at the collar, cuffs and waist, arms spread
   along the crossbar; crude, cheap, slightly comic, not frightening; one object."
3. **State sheet** (1 call, master attached as identity master): three cells in
   one row with wide transparent gutters - WHOLE, HURT, WRECK - same base centre
   and baseline in each cell. Model the layout on
   `implementation/sprites/generation/0014-barricade-states.prompt.txt`.
4. **Sway strips** (2 calls, the accepted sheet attached as identity master):
   STRIP with N=3, poses as in the table, the stake planted at the same x and
   baseline in every cell; only the body above the ground leans.
5. **Bait** (1 call): "one small rotting fish lying belly-up on the ground,
   grey-green rotten skin, ribs showing through a torn side, a bitten tail;
   restrained, no gore, no puddle". **Icon** (1 call): the same rotten fish tied
   with twine to a short stick, as a clear icon silhouette.
6. Export with the mode A recipe (contract section 3), importing `render_source`
   from `tools/import_art.py` read-only: measured `crop_xywh` per object,
   `content_anchor_xy` = (stake centre in scaled px, scaled height) so the lowest
   opaque row lands on `pivot_y - 1`, `alpha_threshold` 128, `palette_keys` null
   (the full 42 colours, as every existing defence). If a reduction pulls an
   unrelated ramp (blue on the straw), regenerate or record the subset you used.

## Review with the owner

The page (contract 9.5) shows every row at 1x and 4x, day and night preview,
over grass, light, dark and checker; the sway strips playing at 0.1 s then
holding the rest frame; the decoy beside the farmer frame, a walker
(`sprites/enemies/walker_walk_0.png`) and `sprites/buildings/barricade.png` on
one ground line over a 16 px tile grid; the bait beside `sprites/buildings/mine.png`;
the icon at 16 and 10 next to `sprites/ui/icon_fish.png`.

Ask the owner:

1. "O espantalho-isca tem uns 26 px de altura, menor que o fazendeiro (32 px). Está bom assim ou deve ficar da altura dele?"
2. "Dá para distinguir esse espantalho do guardião da varanda (sem chapéu, sem olhos acesos), de dia e à noite?"
3. "O peixe podre no chão e o ícone se leem como isca de zumbi a 1x, também na prévia noturna?"

## Acceptance

- [ ] 12 files; canvases and pivots exactly as the table; `01.png` is frame 0.
- [ ] Decoy states and sway frames: lowest opaque row 27, stake centred on x 8
      (±1), nothing clipped (bbox inside the canvas with 1 px clear on every side
      at rest).
- [ ] `decoy`, `decoy_hurt`, `decoy_wreck` share one `content_scale`; all three
      differ; the wreck is at most 8 rows tall.
- [ ] Sway: three distinct frames per strip, stake base fixed, body height equal
      to the rest frame (±1 at the top), never resized to fit.
- [ ] `zombie_bait` lowest row 13, visible at most 13x8; reads as a fish at 1x.
- [ ] Icon and HUD from one raw crop, two scales; visible at most 14 and 8;
      more than 24 / 7 opaque pixels and at least 2 colours; no panel or text.
- [ ] Binary alpha; true transparent raw (no painted checkerboard); no baked
      shadow, ground patch, glow, night version or text.
- [ ] Only the 42 colours; `importer_recipe_matches` true; build twice identical.
- [ ] Readable at 1x by day and in the night preview; not mistakable for the
      farmer or the porch guardian.

## Delivery

Folder `implementation/backlog/deliveries/A037-decoy/` with `raw/` (each return
plus its `.prompt.txt` and `.call.json`), `native/`, `preview/`, `rejected/`,
`contract.json`, `checks.json`, `build.py`, `index.html` and `review-log.txt`, as
contract section 9 says; after approval `APPROVAL.json` and
`CLAUDE-A037-PROMPT.txt` (mapping `native/<anim>/none/NN.png` to the
`sprites/<runtime name>.png` paths above). Last step, only after the owner
approves in words recorded verbatim in `APPROVAL.json`:
`python implementation/backlog/assets.py set A037 approved`.
