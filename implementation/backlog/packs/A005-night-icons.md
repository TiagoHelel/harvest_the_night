# A005 - Night hotbar and HUD icons

- **Status:** todo
- **For game task:** 0147
- **Dressed by game tasks:** 0133, 0139
- **Family:** ui
- **Mode:** A - raw ImageGen sources, Claude reduces them to the 42-colour palette
- **Size of the job:** 12 icons, each cut twice (24 files)

## What it is for

The night's shop window and controls. The hotbar along the bottom of the night
screen shows one 16x16 icon per defence with its price (game task 0133), and the
night HUD shows 10x10 icons beside the flare's charge, START, the speed control and
the time-to-dawn countdown (0139). Today these are text rows; a 32x48 tower shrunk
to 16 px does not read. Each icon must say "this defence" or "this control" at 1x on
the dark navy HUD, beside the existing resource icons. This pack sets the style of
every later hotbar icon (A045 matches it).

## Deliverables

Every item: one raw source cut into `icon_<id>` 16x16 pivot (8,8) (visible at most
14x14) and `hud_<id>` 10x10 pivot (5,5) (visible at most 8x8), 1 frame, 1.0 s,
static, direction `none`, `mirror: "none"`, runtime files `sprites/ui/icon_<id>.png`
and `sprites/ui/hud_<id>.png`. No `_hurt`, level or greyed variants: levels and
greying are code.

| Runtime name | Native canvas | Pivot | Frames / seconds / loop | Notes |
|---|---|---|---|---|
| `icon_gun_tower`, `hud_gun_tower` | 16x16, 10x10 | (8,8), (5,5) | 1 / 1.0 / static | The dark iron gun barrel on its timber turret head and a stub of the trestle, barrel to the upper right, as on the gun tower master |
| `icon_auto_crossbow`, `hud_auto_crossbow` | 16x16, 10x10 | (8,8), (5,5) | 1 / 1.0 / static | The crossbow seen from the front-left: wide wooden limbs, string and a bolt pointing upper right |
| `icon_flame_tower`, `hud_flame_tower` | 16x16, 10x10 | (8,8), (5,5) | 1 / 1.0 / static | The red fuel tank with its brass nozzle pipe, one small flame tongue at the nozzle tip (a shape, not a glow) |
| `icon_mortar`, `hud_mortar` | 16x16, 10x10 | (8,8), (5,5) | 1 / 1.0 / static | The squat black iron tube on its wooden carriage, mouth tilted upper right |
| `icon_mine`, `hud_mine` | 16x16, 10x10 | (8,8), (5,5) | 1 / 1.0 / static | The round grey metal disc with its red pressure button, seen from above at three-quarter |
| `icon_fence`, `hud_fence` | 16x16, 10x10 | (8,8), (5,5) | 1 / 1.0 / static | Two timber posts with iron bands joined by two rails |
| `icon_wall`, `hud_wall` | 16x16, 10x10 | (8,8), (5,5) | 1 / 1.0 / static | A short grey stone block wall, three courses, light top edge |
| `icon_barricade`, `hud_barricade` | 16x16, 10x10 | (8,8), (5,5) | 1 / 1.0 / static | Crossed timber logs braced by a plank, as on the barricade master |
| `icon_flare`, `hud_flare` | 16x16, 10x10 | (8,8), (5,5) | 1 / 1.0 / static | A hand-held signal flare: a red (`roof`) tube with a burning `flame_hot`/`flame` head and two or three spark pixels, tilted 45 degrees |
| `icon_start`, `hud_start` | 16x16, 10x10 | (8,8), (5,5) | 1 / 1.0 / static | START: a curved bone signal horn with a gold band, bell to the upper right |
| `icon_speed`, `hud_speed` | 16x16, 10x10 | (8,8), (5,5) | 1 / 1.0 / static | Speed: two solid right-pointing chevrons (fast-forward) in `gold_light` with an `ink` outline. The "1x/2x/4x" is code text. Points east; not mirrored |
| `icon_dawn_moon`, `hud_dawn_moon` | 16x16, 10x10 | (8,8), (5,5) | 1 / 1.0 / static | Time to dawn: a pale moon (`moon`/`bone`) half sunk behind a straight 1 px dark horizon line - a setting moon, not a crescent (A010's calm night uses the crescent) |

## Match these

- `sprites/ui/icon_wood.png`, `icon_iron.png`, `icon_incendiary.png`, `icon_money.png`
  and their `hud_*` cuts: the approved icon look (ink outline, 2-3 material planes,
  visible 14 / 8 px, 1 px clear padding). Raw style master
  `assets/art_source/ui/wood.png` (1254x1254) and its recipe in
  `assets/art_source/manifest.json` (`ui/icon_wood`: crop 630x571,
  `content_scale` 0.0222 for 16 and 0.0127 for 10).
- Identity of each defence: `assets/art_source/defences/<id>/master.png` and
  `sprites/buildings/<id>.png` for gun_tower, auto_crossbow, flame_tower, mortar,
  mine, barricade; `assets/art_source/defences/fence/whole.png`,
  `assets/art_source/defences/wall/whole.png` and
  `sprites/buildings/{fence,wall}_join_10.png`. Same materials and colours.
- `sprites/effects/flare_1.png` (24x24): the flare's colours.
- `sprites/ui/panel.png` (centre `night` #1a1830) and `button_normal.png` (centre
  `night_light` #2e2a4e): the HUD the icons sit on.
- `implementation/sprites/generation/0018-wood.prompt.txt`: the prompt that made the
  approved icons; reuse its "Native contract" paragraph with visible 14 and 8.

## How to make it

1. One call per icon, `transparent_background=true`, one candidate per call. Prompt
   = BASE (canvas 16x16, pivot 8,8) + the ICON section of `PROMPTS.md` + the item's
   line from the table + the 0018 "Native contract" paragraph, with "maximum
   visible dimension 8" for the compact cut (the contract's number, not the 0018
   prompt's 9).
2. Inputs: Image 1 `assets/art_source/ui/wood.png` (icon style master); Image 2 the
   defence master (identity reference); Image 3 `docs/reference-sheet.png` (style
   reference). For START, speed and dawn moon only Images 1 and 3.
3. Make the gun tower first and check it before the rest: it fixes how much of a
   tower an icon shows. Then the other three towers, then the rest.
4. **Export:** `crop_xywh` = the object's measured bounds in the raw (plus a few raw
   px); `content_scale` 16 = 14 / max(crop w, h); `content_scale` 10 = 8 / max(crop
   w, h); `content_anchor_xy` = `(scaled_w // 2, scaled_h // 2)`, which centres the
   object on the pivot as `ui/icon_wood` does. The same crop for both cuts.
5. If the 10x10 cut loses what the thing is (the crossbow limbs, the mine's button,
   the horn's curve), regenerate the raw with a bolder, simpler shape. Never patch
   pixels, and never draw the 10x10 separately.

## Review with the owner

The page shows each icon at 1x and 4x, both cuts, over `night` #1a1830, over
`night_light` #2e2a4e, over tiled `sprites/ui/panel.png`, over checker and light
grey; the eight defences as a mock hotbar row of 16x16 slots, each beside its tower
sprite; the four HUD icons in a mock night HUD strip; and a row with today's
`icon_wood`, `icon_iron` and `icon_money` for style. The HUD is not relit at night
(Relight is layer 1, UI layer 3), so the contract's night preview is shown but
labelled "world relight, for reference only".

Questions for the owner:

1. "Os ícones mostram a cabeça da arma em vez da torre inteira. Você reconhece cada defesa na barra, no tamanho real?"
2. "Para o COMEÇAR usei uma corneta, e para o tempo até o amanhecer uma lua se pondo atrás do horizonte. Funcionam, ou prefere outros símbolos?"
3. "No tamanho pequeno (10x10) algum ícone ficou ilegível?"

## Acceptance

- [ ] 24 files: 12 `icon_` at 16x16 pivot (8,8) and 12 `hud_` at 10x10 pivot (5,5), each pair from one raw with one crop.
- [ ] `icon_bounds_ok`: visible at most 14x14 and 8x8, centred on the pivot (+-1), at least 1 px clear padding.
- [ ] Binary alpha; no text, numbers, panel, frame, shadow or glow.
- [ ] Only the 42 colours through `render_source`; `importer_recipe_matches` true.
- [ ] Each defence keeps its master's materials; the four towers have four different silhouettes at 10x10.
- [ ] The dawn moon reads as a setting moon, distinct from a crescent and from a full disc.
- [ ] Sits beside the approved resource icons without looking larger, busier or differently outlined.
- [ ] `build.py` twice gives identical bytes, `--check` passes, checks.json all `true`.

## Delivery

`implementation/backlog/deliveries/A005-night-icons/` with the files of contract 9.1:
`raw/` (each return with `.prompt.txt` and `.call.json`),
`native/icon_<id>/none/01.png` and `native/hud_<id>/none/01.png` for the 12 ids,
`preview/`, `rejected/`, `contract.json` (`palette_mode` "A"), `checks.json`,
`build.py`, `index.html`, `review-log.txt`. After the owner approves in words:
`APPROVAL.json`, `CLAUDE-A005-PROMPT.txt` (mapping e.g.
`native/icon_mortar/none/01.png -> sprites/ui/icon_mortar.png  16x16 pivot (8,8) draw 1.0  static`;
the hotbar (0133) takes the 16x16 cuts and the night HUD (0139) the 10x10 ones, for
game task 0147), then `python implementation/backlog/assets.py set A005 approved`.
