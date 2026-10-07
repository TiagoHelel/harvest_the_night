# A011 - Forecast heads of the first enemies

- **Status:** todo
- **For game task:** 0162
- **Dressed by game tasks:** 0158
- **Family:** ui
- **Mode:** A - raw ImageGen sources, Claude reduces them to the 42-colour palette
- **Size of the job:** 5 heads (5 files)

## What it is for

At dusk the forecast panel (game task 0158) says what is coming tonight: one head
and a count per enemy kind, on the day HUD from 18:00 and in the night's build step.
The heads replace 0158's stand-in (each enemy's first walk frame cropped into a
16x16 box). A player who has met a walker must recognise "walkers" from the head
alone, at 1x on the dark navy HUD, so each head carries its enemy's identity cues
and colours. The Giant's head reads as the biggest and heaviest. Later enemies and
bosses bring their own heads in their packs (A046-A054) and follow this one.

## Deliverables

Every head: one raw source, 16x16, pivot (8,8), 1 frame, 1.0 s, static, direction
`none`, `mirror: "none"`, runtime file `sprites/ui/head_<kind>.png`. No 10x10 cut
(game task 0162 uses only 16x16).

A head-and-shoulders bust in three-quarter view turned to the viewer's left, the way
the enemy sprites face. The bust is cut flat at the bottom: lowest opaque row 14
(row 15 empty) for all five, so a row of heads shares one baseline; centred on x=8
(+-1); at least 1 px clear on the left, right and top.

| Runtime name | Native canvas | Pivot | Frames / seconds / loop | Notes |
|---|---|---|---|---|
| `head_walker` | 16x16 | (8,8) | 1 / 1.0 / static | Visible 12-13 tall, at most 13 wide. Shaggy rust-brown hair, green rotten face, pale eyes, torn red-brown shirt collar, slouched shoulders |
| `head_runner` | 16x16 | (8,8) | 1 / 1.0 / static | Visible 12-13 tall, at most 13 wide. Dark spiky hair, gaunt face, open mouth, thin neck, torn dark teal vest |
| `head_tank` | 16x16 | (8,8) | 1 / 1.0 / static | Visible 12-13 tall, 13 wide. Bald heavy green head sunk on a thick neck, wide shoulders, mustard vest over a dark shirt |
| `head_breaker` | 16x16 | (8,8) | 1 / 1.0 / static | Visible 12-13 tall, at most 13 wide. Messy dark hair, torn red shirt, the iron head of its sledgehammer resting on its shoulder |
| `head_giant` | 16x16 | (8,8) | 1 / 1.0 / static | Visible 14x14. Huge bald head, small pale eyes, blood streaks, grey stone plates on its shoulder; fills the box |

**Colours:** each head reduces with `palette_keys` = the palette names used by that
enemy's runtime frames (`sprites/enemies/<kind>_{walk,attack,death}_<i>.png`; for
the Giant `giant_{walk,windup,slam,death}_<i>.png`), computed by build.py read-only,
so a head can only use its body's colours.
Eyes stay pale (`bone_dark`/`bone`), never a light colour that would look emissive.

## Match these

- `sprites/enemies/walker_walk_0.png`, `runner_walk_0.png`, `tank_walk_0.png`,
  `breaker_walk_0.png` (64x48, pivot (32,44), visible about 18-24 x 29) and
  `giant_walk_0.png` (80x64, pivot (40,60), visible 46x41): the colours and the
  cues players see in the game. The head must match these sprites, not only the
  master.
- `assets/art_source/enemies/<kind>/master.png` for the five kinds: identity masters
  (the hair, faces, clothes, the breaker's hammer, the Giant's stone plates).
- `sprites/ui/icon_meat.png` and `icon_tech.png`: the approved icon outline and
  padding.
- `sprites/ui/panel.png` (centre `night` #1a1830): the HUD they sit on.

## How to make it

1. One call per head, `transparent_background=true`, one candidate per call. Prompt
   = BASE (canvas 16x16, pivot 8,8) + the WALKER section of `PROMPTS.md` for the
   identity lines + these lines: "A forecast portrait icon: head and shoulders only,
   three-quarter view turned to the left, cut flat at the chest, bold simple shapes
   that survive reduction to 16x16 with 12-14 visible pixels; the same character as
   the attached master. No body below the chest, no background, no frame, no text."
2. Inputs: Image 1 `assets/art_source/enemies/<kind>/master.png` (identity master);
   Image 2 `sprites/enemies/<kind>_walk_0.png` enlarged by nearest (colour and
   in-game identity reference); Image 3 `assets/art_source/ui/wood.png` (icon style
   reference).
3. Make the walker first and check it at 16x16 before the rest; then runner, tank,
   breaker, Giant.
4. **Export:** `crop_xywh` = the bust's measured bounds in the raw, bottom edge on its
   lowest opaque raw row; `content_scale` = target height / crop height (12 or 13
   for the four kinds, 14 for the Giant), also keeping the width within its limit;
   `content_anchor_xy` = `(scaled_w // 2, scaled_h - 7)`, which puts the lowest row
   on 14 and the bust centred on x=8.
5. If reduction loses the face, the eyes or the kind's cue (hair, vest, hammer,
   stone plates), regenerate a bolder raw. Never patch pixels.

## Review with the owner

The page shows each head at 1x and 4x over `night` #1a1830, tiled
`sprites/ui/panel.png`, checker and light grey; each head beside its enemy's
`walk_0` sprite at 1x and 4x (the farmer walk frame beside them for scale); the five
in a mock forecast row (head plus a blank where code writes the count); and 0158's
stand-in (the walk frame cropped to 16x16) beside each for comparison. The HUD is
not relit at night (Relight is layer 1, UI layer 3), so the contract's night preview
is shown but labelled "world relight, for reference only".

Questions for the owner:

1. "Olhando só a cabeça, você sabe qual zumbi é (andarilho, corredor, tanque, destruidor, Gigante)?"
2. "O Gigante ocupa o quadro inteiro e os outros são um pouco menores. Está bom assim?"

## Acceptance

- [ ] 5 files, each 16x16 with pivot (8,8).
- [ ] Lowest opaque row 14 in all five; centred on x=8 (+-1); 1 px clear at left, right and top; the four kinds 12-13 tall, the Giant 14x14.
- [ ] Binary alpha; no text, frame, background, shadow or glow.
- [ ] Each head uses only its enemy's own palette colours, through `render_source`; `importer_recipe_matches` true.
- [ ] Each kind tells apart from the others at 1x; matches its walk sprite's hair, skin and clothes.
- [ ] `build.py` twice gives identical bytes, `--check` passes, checks.json all `true`.

## Delivery

`implementation/backlog/deliveries/A011-forecast-heads/` with the files of contract
9.1: `raw/` (each return with `.prompt.txt` and `.call.json`),
`native/head_<kind>/none/01.png` for the five kinds, `preview/`, `rejected/`,
`contract.json` (`palette_mode` "A", `palette_keys` per head), `checks.json`,
`build.py`, `index.html`, `review-log.txt`. After the owner approves in words:
`APPROVAL.json`, `CLAUDE-A011-PROMPT.txt` (mapping e.g.
`native/head_tank/none/01.png -> sprites/ui/head_tank.png  16x16 pivot (8,8) draw 1.0  static`,
replacing 0158's cropped walk-frame heads for game task 0162), then
`python implementation/backlog/assets.py set A011 approved`.
