# A041 - The searchlight

- **Status:** integrated
- **For game task:** 0240
- **Dressed by game tasks:** 0229
- **Spec after game task:** 0229
- **Family:** defences
- **Mode:** A - raw ImageGen sources, Claude reduces them to the 42-colour palette
- **Size of the job:** 8 tower frames (2 levels x 4 states)

## What it is for

The searchlight (`searchlight`) is a powered winter lamp on a mast: it lights
the ground round it, lets towers in its light see a tile further, cancels fog
and reveals wraiths. It does not shoot. It stands in the tower line at night,
and its lamp is where the code's beam and light pool start (`light_xy`), so the
lens must be an obvious, opaque target. The light itself is never in the
sprite: no beam, no halo, no glow. It must read as a lamp, not a gun, at 1x by
day and after the night relight.

## Deliverables

Final geometry settled by game task 0229. The rows stand as written: the searchlight 32x48 standing on (16,44) at two levels in four states each. **How the game plays them:** a searchlight is one cell, a tower that never shoots and lights the ground round it - a square four tiles out, six at level two, its only upgrade and the family's last - and every tower standing in light reaches a tile further. **`_fire` is kept, and means the lamp at full**: the view shows it from the sun going down to the morning on a farm with all the power it wants; by day, and on a farm short of power - whose lamp lights a tile less, never none - it shows the whole state, the lens dark, which is the cue that it is not at full. It is `_hurt` below three quarters of its hit points (lit first, as the towers' firing is) and `_wreck` once it falls, as rubble the morning sweeps, at the level it stood at. The pool of light over the lit square, the beam from the lens down to it and the lens's own glow are code, and they start at `light_xy`. Until 0240 the searchlight is the gun tower in a cold lamp white at each level and state, through 0120's road. Start only when `python implementation/backlog/assets.py next` offers this pack.

| Runtime name | Native canvas | Pivot | Frames / seconds / loop | Notes |
|---|---|---|---|---|
| `buildings/searchlight` | 32x48 | (16,44) | 1 / static (0.55, loop false) | L1 whole. Visible about 16-18 wide x 26-28 tall, base centred on x 16, lowest opaque row 43. Lens glass unlit: dark glass with one small top-left highlight. `light_xy` on the lens. |
| `buildings/searchlight_hurt` | 32x48 | (16,44) | 1 / static | L1 dented hood, an ink crack across the lens, a bent brace, a loose cable; lens still in place. `light_xy` on the lens. |
| `buildings/searchlight_fire` | 32x48 | (16,44) | 1 / static | L1 "lamp at full": same pixels as whole except the lens face, which is filled flat with pale lit glass inside its rim (no rays, nothing outside the housing). `light_xy` on the lens. |
| `buildings/searchlight_wreck` | 32x48 | (16,44) | 1 / static | L1 mast collapsed, lamp drum on its side on the base, lens shattered; low, inside the whole's width. No points. |
| `buildings/searchlight_2` + `_hurt`, `_fire`, `_wreck` | 32x48 | (16,44) | 1 each / static | L2, same state rules. Visible about 20-22 wide x 30-34 tall. |

- Every row: dir `none`, `mirror: "none"`, draw scale 1.0.
- **The stand-in until 0240** (task 0229): `PlaceholderArt` registers the
  eight names with `buildings/gun_tower` and its states and level as
  stand-ins, tinted a cold white, each with a `light_xy` on the stand-in's
  turret - (16,23) at level one and (15,22) at level two - and none on the
  wrecks; `Lighting` draws the pool, the beam and the lens from there. The
  pack has no icon: the hotbar shows `searchlight` scaled into its 16x16 box.
- **Points** (contract section 5): per level, on whole, hurt and fire, one
  `light_xy` on an opaque pixel at the centre of the lens (expected near x 16-20,
  y 18-24 for L1 and y 12-18 for L2 - measure the real art). No muzzle points:
  the searchlight never fires. Wrecks have no point.
- **Lens.** A round lens facing the viewer, turned slightly to the right (east)
  like every tower aims, 6-7 px across on L1 and 8-9 px on L2 at native size,
  with a 1 px rim, so the beam can leave toward the camera side.
- **Levels change the construction.** L1: a round lamp drum with a reflector
  hood on a yoke, on a braced timber post with a crank handle; a cable runs down
  the post into the base. L2: a larger drum with a brass rim and cooling fins on
  a braced iron-and-timber lattice mast with a short ladder, on a stone footing.
  Never stacked copies, pips or bands. L1 and L2 whole differ in at least 80
  native pixels.
- `_fire` is kept for the tower pattern the game already reads; the searchlight
  has no `reload_ticks`, so 0229 decides when the view shows it (this pack's
  default: the lamp at full power) or removes the two `_fire` rows before the
  pack starts.
- Delivery paths: `native/searchlight/none/01.png` ...
  `native/searchlight_2_wreck/none/01.png` (8 files).

## Match these

- `sprites/buildings/gun_tower.png`, `gun_tower_hurt.png`, `gun_tower_wreck.png`,
  `gun_tower_2.png`, `gun_tower_3.png` - the tower family's canvas, base line
  (row 43), outline, and how hurt and wreck differ. Open them at 4x.
- `assets/art_source/defences/gun_tower/level-3.png` - the raw 2x2 four-state
  sheet layout every tower level is cut from (one raw, one scale per level).
- `sprites/buildings/house.png` and its `windows_xy` in `src/ui/raster_art.gd` -
  how a light point sits on a pane the runtime lights; the lens works the same way.
- `sprites/props/generator.png` - the powered machinery the lamp belongs with.
- The 32 px farmer frame `implementation/fhd-player/pilots/2026-10-06/walk-final-mirrored/native-40/walk/down/01.png`.
- `docs/reference-sheet.png` and `assets/art_source/masters/style-night.png` -
  the night mood the lamp must survive (the study shows lighting, not sizes).

## How to make it

1. Prompt = BASE + TOWER with "searchlight: a round lamp drum on a mast, lens
   facing the viewer, a cable down to the base; it does not shoot" in place of
   the weapon list, plus the "Four-state sheet contract" and "LAYOUT CLEARANCE"
   paragraphs of `implementation/sprites/generation/0013-mortar-level-2.prompt.txt`,
   with FIRE redefined as "the same lamp with its lens face lit flat and pale,
   no beam, no rays, no glow outside the housing". `transparent_background=true`
   on every call. Attach `docs/reference-sheet.png` (style) and
   `sprites/buildings/gun_tower.png` (scale and family) and say each role.
2. **Master** (1 call, at most 2 fresh candidates): L1 whole, one object.
3. **One 2x2 four-state sheet per level** (2 calls): whole top-left, hurt
   top-right, fire bottom-left, wreck bottom-right, with the master (and for L2
   the accepted L1 sheet) attached as identity master. All four states of a
   level are cut from that one raw; the cut boxes share no opaque pixel.
4. Export with the mode A recipe (contract section 3, `render_source` imported
   read-only): one `content_scale` per level, `content_anchor_xy` putting the
   base centre on x 16 and the lowest opaque row on 43, `alpha_threshold` 128,
   `palette_keys` null. If a beam or halo survives in the raw, regenerate - never
   erase it in code.

## Review with the owner

The page (contract 9.5) shows the two levels x four states as a grid at 1x and
4x, day and night preview, beside `sprites/buildings/gun_tower.png` and the
farmer frame on one ground line over a 16 px grid and tiled grass; `light_xy` on
an overlay; and, on the night preview only, a plain disc marking where the code
light starts (drawn by build.py into `preview/`, never into `native/`).

Ask the owner:

1. "O estado `_fire` mostra a lente acesa (clara) e os outros a lente apagada. Faz sentido, ou a lente deve ficar sempre igual e só a luz do jogo mostra que está ligado?"
2. "O nível 2 parece um holofote mais forte, sem virar uma torre de tiro?"

## Acceptance

- [ ] 8 files, 32x48, pivot (16,44).
- [ ] Bbox left >= 1, top >= 1, right <= 30, lowest opaque row 43, base centred
      on x 16 (±1); all 8 frames distinct; `_fire` differs from whole only at the
      lens.
- [ ] One raw and one `content_scale` per level; cut boxes share no opaque
      pixel; L1 and L2 whole differ by >= 80 pixels.
- [ ] `light_xy` on an opaque lens pixel in whole, hurt and fire of each level;
      no point on wrecks; no muzzle keys anywhere.
- [ ] No beam, ray, halo or bloom in any frame; the lit lens stays inside its rim.
- [ ] Binary alpha, true transparent raws, only the 42 colours, recipe matches,
      build twice identical; no shadow, ground, night version or text.
- [ ] Reads as a lamp, not a gun, at 1x by day and in the night preview.

## Delivery

Folder `implementation/backlog/deliveries/A041-searchlight/` with `raw/` (each
return plus `.prompt.txt` and `.call.json`), `native/`, `preview/`, `rejected/`,
`contract.json`, `checks.json`, `build.py`, `index.html` and `review-log.txt`
(contract section 9); after approval `APPROVAL.json` and
`CLAUDE-A041-PROMPT.txt` (mapping each `native/<anim>/none/01.png` to
`sprites/<runtime name>.png`, with `light_xy` per level and state). Last step,
only after the owner approves in words recorded verbatim in `APPROVAL.json`:
`python implementation/backlog/assets.py set A041 approved`.
