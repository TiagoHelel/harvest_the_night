# A010 - Seasons and moons

- **Status:** todo
- **For game task:** 0161
- **Dressed by game tasks:** 0158
- **Family:** ui
- **Mode:** A - raw ImageGen sources, Claude reduces them to the 42-colour palette
- **Size of the job:** 7 icons, each cut twice (14 files)

## What it is for

The calendar's marks in the night forecast (game task 0158): from 18:00 on the day
HUD and in the night's build step, the panel shows the date with its season, and
marks a Full Moon (days 7 and 14), a boss night (day 14, together with the Full
Moon) and a calm night (the first night after a boss falls). Each mark must say its
meaning at 1x without text, on the dark navy HUD, next to the resource icons and
A005's night icons. The four seasons must be told apart by shape, not only by
colour, and the three night marks must never be confused with each other or with
A005's setting moon or A055's Blood Moon.

## Deliverables

Every item: one raw source cut into `icon_<id>` 16x16 pivot (8,8) (visible at most
14x14) and `hud_<id>` 10x10 pivot (5,5) (visible at most 8x8), 1 frame, 1.0 s,
static, direction `none`, `mirror: "none"`, runtime files `sprites/ui/icon_<id>.png`
and `sprites/ui/hud_<id>.png`.

| Runtime name | Native canvas | Pivot | Frames / seconds / loop | Notes |
|---|---|---|---|---|
| `icon_spring`, `hud_spring` | 16x16, 10x10 | (8,8), (5,5) | 1 / 1.0 / static | A young sprout: two round `grass_light`/`grass` leaves on a short stem with one small `bone` bud |
| `icon_summer`, `hud_summer` | 16x16, 10x10 | (8,8), (5,5) | 1 / 1.0 / static | A sun: a round `gold_light`/`flame_hot` disc with 8 short chunky rays, `gold_dark` on the lower right; rays are shapes, no halo |
| `icon_autumn`, `hud_autumn` | 16x16, 10x10 | (8,8), (5,5) | 1 / 1.0 / static | One maple-like leaf in `roof`/`flame` with a `wood` stem, tilted |
| `icon_winter`, `hud_winter` | 16x16, 10x10 | (8,8), (5,5) | 1 / 1.0 / static | A chunky six-armed snowflake in `bone`/`moon` with `water_light` shading |
| `icon_full_moon`, `hud_full_moon` | 16x16, 10x10 | (8,8), (5,5) | 1 / 1.0 / static | A whole round pale disc (`moon`/`bone`) with two or three `stone_light` craters, highlight upper left; no halo |
| `icon_boss_night`, `hud_boss_night` | 16x16, 10x10 | (8,8), (5,5) | 1 / 1.0 / static | A horned skull: `bone`/`bone_dark` with `ink` outline, dark eye sockets, two short curved horns. No blood, no crown (the Scarecrow King has one) |
| `icon_calm_night`, `hud_calm_night` | 16x16, 10x10 | (8,8), (5,5) | 1 / 1.0 / static | A thin crescent moon (`moon`/`bone`) opening to the right with one small four-point star beside it |

## Match these

- `sprites/ui/icon_wood.png`, `icon_tech.png`, `icon_energy.png` and their `hud_*`
  cuts: the approved icon look (ink outline, 2-3 material planes, visible 14 / 8 px,
  1 px clear padding). Raw style master `assets/art_source/ui/wood.png` and its
  recipe in `assets/art_source/manifest.json` (`ui/icon_wood`).
- A005's delivery `implementation/backlog/deliveries/A005-night-icons/` if it is
  approved: `icon_dawn_moon` is a setting moon behind a horizon line; the full moon
  and the calm crescent here must not look like it. Use its accepted dawn-moon raw
  (the `source` of `icon_dawn_moon` in its contract.json) as a style reference for
  the moon material.
- `sprites/ui/icon_carrot.png` and `icon_wheat.png`: the greens and golds of the
  farm's plants for spring and autumn.
- `sprites/ui/panel.png` (centre `night` #1a1830): the HUD they sit on.
- `implementation/sprites/generation/0018-wood.prompt.txt`: the prompt that made the
  approved icons; reuse its "Native contract" paragraph with visible 14 and 8.

## How to make it

1. One call per icon, `transparent_background=true`, one candidate per call. Prompt
   = BASE (canvas 16x16, pivot 8,8) + the ICON section of `PROMPTS.md` + the item's
   line from the table + the 0018 "Native contract" paragraph with "maximum visible
   dimension 8" for the compact cut. Add: "a calendar mark, a simple emblem, not a
   scene; no sky, no ground, no frame".
2. Inputs: Image 1 `assets/art_source/ui/wood.png` (icon style master); Image 2
   `docs/reference-sheet.png` (style reference); for the moons, also A005's accepted
   dawn-moon raw if A005 is approved (material reference).
3. Make `full_moon` first, then `calm_night` and `boss_night`, then the seasons. A055
   will later recolour the accepted `full_moon` raw into the Blood Moon, so keep it a
   clean single disc.
4. **Export:** `crop_xywh` = the object's measured bounds in the raw (plus a few raw
   px); `content_scale` 16 = 14 / max(crop w, h); `content_scale` 10 = 8 / max(crop
   w, h); `content_anchor_xy` = `(scaled_w // 2, scaled_h // 2)` (as `ui/icon_wood`).
   The same crop for both cuts.
5. If the 10x10 cut loses the shape (the snowflake's arms, the skull's horns, the
   star beside the crescent), regenerate a bolder raw. Never patch pixels.

## Review with the owner

The page shows each icon at 1x and 4x, both cuts, over `night` #1a1830, tiled
`sprites/ui/panel.png`, checker and light grey; the four seasons in a row; the three
night marks in a row beside A005's `icon_dawn_moon` (if delivered) so the moons can
be compared; a mock forecast line (season mark, Full Moon mark, boss mark) without
text; and a row with today's `icon_wood` and `icon_tech`. The HUD is not relit at
night (Relight is layer 1, UI layer 3), so the contract's night preview is shown but
labelled "world relight, for reference only".

Questions for the owner:

1. "Você reconhece as quatro estações só pelo desenho (broto, sol, folha, floco de neve)?"
2. "A caveira com chifres serve como marca de noite de chefe, ou prefere outro símbolo?"
3. "A lua cheia, a lua crescente com estrela (noite calma) e a lua se pondo da barra da noite estão bem diferentes entre si?"

## Acceptance

- [ ] 14 files: 7 `icon_` at 16x16 pivot (8,8) and 7 `hud_` at 10x10 pivot (5,5), each pair from one raw with one crop.
- [ ] `icon_bounds_ok`: visible at most 14x14 and 8x8, centred on the pivot (+-1), at least 1 px clear padding.
- [ ] Binary alpha; no text, numbers, frame, panel, shadow, glow or halo.
- [ ] Only the 42 colours through `render_source`; `importer_recipe_matches` true.
- [ ] The seasons differ by silhouette at 10x10; full moon, calm crescent and A005's setting moon differ by silhouette.
- [ ] Sits beside the approved resource icons without looking larger, busier or differently outlined.
- [ ] `build.py` twice gives identical bytes, `--check` passes, checks.json all `true`.

## Delivery

`implementation/backlog/deliveries/A010-calendar-icons/` with the files of contract
9.1: `raw/` (each return with `.prompt.txt` and `.call.json`),
`native/icon_<id>/none/01.png` and `native/hud_<id>/none/01.png` for the 7 ids,
`preview/`, `rejected/`, `contract.json` (`palette_mode` "A"), `checks.json`,
`build.py`, `index.html`, `review-log.txt`. After the owner approves in words:
`APPROVAL.json`, `CLAUDE-A010-PROMPT.txt` (mapping e.g.
`native/icon_full_moon/none/01.png -> sprites/ui/icon_full_moon.png  16x16 pivot (8,8) draw 1.0  static`,
replacing 0158's code-drawn marks for game task 0161), then
`python implementation/backlog/assets.py set A010 approved`.
