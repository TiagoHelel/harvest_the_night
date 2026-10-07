# A055 - Fog, rain and the Blood Moon icons

- **Status:** todo
- **For game task:** 0269
- **Dressed by game tasks:** 0256, 0257
- **Spec after game task:** 0257
- **Family:** ui
- **Mode:** A - raw ImageGen sources, Claude reduces them to the 42-colour palette
- **Size of the job:** 3 icons, each cut twice (6 files)

## What it is for

Some nights carry an event, and the forecast says so at dusk so it changes what the
player builds: fog (towers reach one tile less unless lit), rain (fire is weaker,
mud slows the walkers) and, from autumn on, the rare Blood Moon (elite zombies,
extra essence). Each event gets one mark in the forecast panel's event slot (game
tasks 0256 and 0257), on the day HUD from 18:00 and in the night's build step. At 1x
on the dark navy HUD each mark must say its event without text, and the Blood Moon
must never be mistaken for A010's Full Moon, even by a colour-blind player.

## Deliverables

The table is provisional: game task 0257 settles the final canvas/footprint/states and updates it; start only when `python implementation/backlog/assets.py next` offers this pack.

Every item: one raw source cut into `icon_<id>` 16x16 pivot (8,8) (visible at most
14x14) and `hud_<id>` 10x10 pivot (5,5) (visible at most 8x8), 1 frame, 1.0 s,
static, direction `none`, `mirror: "none"`, runtime files `sprites/ui/icon_<id>.png`
and `sprites/ui/hud_<id>.png`.

| Runtime name | Native canvas | Pivot | Frames / seconds / loop | Notes |
|---|---|---|---|---|
| `icon_fog`, `hud_fog` | 16x16, 10x10 | (8,8), (5,5) | 1 / 1.0 / static | Three soft horizontal wavy bands of mist, staggered left and right, `stone_light`/`bone_dark` with an `ink_soft` underside; solid clusters, no transparency gradient |
| `icon_rain`, `hud_rain` | 16x16, 10x10 | (8,8), (5,5) | 1 / 1.0 / static | A grey rain cloud (`stone`/`stone_light`, `stone_dark` underside) with three slanted `water_light` drops falling to the lower left |
| `icon_blood_moon`, `hud_blood_moon` | 16x16, 10x10 | (8,8), (5,5) | 1 / 1.0 / static | The same round disc as A010's `icon_full_moon`, recoloured to the `roof`/`roof_dark`/`blood` ramp with a `roof_light` upper-left highlight, plus one short drip hanging from its lower edge: the drip is the shape cue that tells it from the Full Moon. No halo, no splatter |

## Match these

- A010's approved delivery `implementation/backlog/deliveries/A010-calendar-icons/`:
  `icon_full_moon` (the disc the Blood Moon recolours), `icon_winter` and
  `icon_calm_night` (the weather and night family these join). Its accepted
  `full_moon` raw is the edit target for the Blood Moon.
- `sprites/ui/icon_wood.png`, `icon_stone.png`, `icon_fish.png` and their `hud_*`
  cuts: the approved icon look (ink outline, 2-3 material planes, visible 14 / 8 px,
  1 px clear padding). Raw style master `assets/art_source/ui/wood.png` and its
  recipe in `assets/art_source/manifest.json` (`ui/icon_wood`).
- `sprites/terrain/water.png`: the water blue of the raindrops.
- `sprites/ui/panel.png` (centre `night` #1a1830): the HUD they sit on.
- `implementation/sprites/generation/0018-wood.prompt.txt`: the prompt that made the
  approved icons; reuse its "Native contract" paragraph with visible 14 and 8.

## How to make it

1. One call per icon, `transparent_background=true`, one candidate per call. Prompt
   = BASE (canvas 16x16, pivot 8,8) + the ICON section of `PROMPTS.md` + the item's
   line from the table + the 0018 "Native contract" paragraph with "maximum visible
   dimension 8" for the compact cut. Add: "a forecast weather mark, a simple emblem,
   not a scene; no sky, no ground, no frame".
2. Fog and rain: inputs Image 1 `assets/art_source/ui/wood.png` (icon style master),
   Image 2 A010's accepted `icon_winter` raw (family reference), Image 3
   `docs/reference-sheet.png` (style reference).
3. Blood Moon: an edit call with A010's accepted `full_moon` raw as the edit target:
   change only the colour to the red ramp and add the drip; keep the disc's size,
   position and craters. If A010 is not approved yet, ask the owner before
   generating (CODEX-RUNNER: "needs art from another pack").
4. **Export:** `crop_xywh` = the object's measured bounds in the raw (plus a few raw
   px); `content_scale` 16 = 14 / max(crop w, h); `content_scale` 10 = 8 / max(crop
   w, h); `content_anchor_xy` = `(scaled_w // 2, scaled_h // 2)` (as `ui/icon_wood`).
   The same crop for both cuts. The Blood Moon's disc must come out the same size as
   A010's full moon disc (+-1 px) in both cuts.
5. If the 10x10 cut loses the shape (the fog's three bands, the drops, the drip),
   regenerate a bolder raw. Never patch pixels.

## Review with the owner

The page shows each icon at 1x and 4x, both cuts, over `night` #1a1830, tiled
`sprites/ui/panel.png`, checker and light grey; the Blood Moon beside A010's
`icon_full_moon` in colour and in a greyscale copy (the drip must tell them apart
without colour); a mock forecast line (season mark, moon mark, event mark) without
text. The HUD is not relit at night (Relight is layer 1, UI layer 3), so the
contract's night preview is shown but labelled "world relight, for reference only".

Questions for the owner:

1. "A neblina, a chuva e a Lua de Sangue se entendem sem texto, no tamanho real?"
2. "A gota pendurada na Lua de Sangue serve para diferenciá-la da Lua Cheia, ou é sangue demais para o tom do jogo?"

## Acceptance

- [ ] 6 files: 3 `icon_` at 16x16 pivot (8,8) and 3 `hud_` at 10x10 pivot (5,5), each pair from one raw with one crop.
- [ ] `icon_bounds_ok`: visible at most 14x14 and 8x8, centred on the pivot (+-1), at least 1 px clear padding.
- [ ] Binary alpha; no text, numbers, frame, panel, shadow, glow or halo.
- [ ] Only the 42 colours through `render_source`; `importer_recipe_matches` true.
- [ ] The Blood Moon and the Full Moon differ in the greyscale copy; the discs match in size.
- [ ] Sits beside A010's icons and the resource icons without looking larger, busier or differently outlined.
- [ ] `build.py` twice gives identical bytes, `--check` passes, checks.json all `true`.

## Delivery

`implementation/backlog/deliveries/A055-event-icons/` with the files of contract 9.1:
`raw/` (each return with `.prompt.txt` and `.call.json`),
`native/icon_<id>/none/01.png` and `native/hud_<id>/none/01.png` for `fog`, `rain`
and `blood_moon`, `preview/`, `rejected/`, `contract.json` (`palette_mode` "A"; the
A010 raw used as edit target listed in `references`), `checks.json`, `build.py`,
`index.html`, `review-log.txt`. After the owner approves in words: `APPROVAL.json`,
`CLAUDE-A055-PROMPT.txt` (mapping e.g.
`native/icon_fog/none/01.png -> sprites/ui/icon_fog.png  16x16 pivot (8,8) draw 1.0  static`,
replacing 0256's and 0257's placeholders for game task 0269), then
`python implementation/backlog/assets.py set A055 approved`.
