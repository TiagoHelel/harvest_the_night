# A004 - The guardian's cursor

- **Status:** integrated
- **For game task:** 0146
- **Dressed by game tasks:** 0131
- **Spec after game task:** 0131
- **Family:** ui
- **Mode:** A - raw ImageGen sources, Claude reduces them to the 42-colour palette
- **Size of the job:** 7 cursor states x a 2-frame pulse = 14 frames

## What it is for

At night the player's hand is a cell cursor, driven by the mouse or stepped by the
pad, in the build step and during the waves. It frames one 16x16 ground cell, pulses
slowly, and says by colour and by a small corner glyph what confirming will do:
nothing to do (neutral), place the selected defence, refused (blocked), upgrade,
sell, repair, or aim the flare. It sits over the night farm - relit grass, soil,
path, snow, walls and towers - and must read there at 1x without covering what
stands in the cell. 0131's code-drawn outline is the stand-in. The footprint
highlight, the range ring, the predicted path and the flare's radius square stay
code.

## Deliverables

**Settled by game task 0131** (2026-10-08) from its code-drawn stand-in (`PlaceholderArt.ART`, `src/ui/guardian_cursor.gd`): the geometry below is final. The cursor is drawn **above the night ramp**: it is unlit, on `WorldView`'s `NightCues` layer, so review it unlit. It is centred on the cell (pivot (8,8) on the cell's middle) at 1.0, and it is up in the build step and the night only. The seven looks keep the table's names: 0131 switches on neutral, place and blocked, and game tasks 0133-0135 the rest. Start only when `python implementation/backlog/assets.py next` offers this pack.

Every state: canvas 16x16, pivot (8,8), 2 frames at 0.4 s, loop, direction `none`,
`mirror: "none"`, runtime file `sprites/ui/<runtime name>.png`.

| Runtime name | Native canvas | Pivot | Frames / seconds / loop | Notes |
|---|---|---|---|---|
| `cursor_neutral_0..1` | 16x16 | (8,8) | 2 / 0.4 / loop | `bone` brackets, no glyph. `palette_keys`: `ink, bone, bone_dark` |
| `cursor_place_0..1` | 16x16 | (8,8) | 2 / 0.4 / loop | `grass_light` brackets, plus glyph. Keys: `ink, grass_light, grass` |
| `cursor_blocked_0..1` | 16x16 | (8,8) | 2 / 0.4 / loop | `roof_light` brackets, X glyph. Keys: `ink, roof_light, roof` |
| `cursor_upgrade_0..1` | 16x16 | (8,8) | 2 / 0.4 / loop | `water_light` brackets, up-arrow glyph. Keys: `ink, water_light, water` |
| `cursor_sell_0..1` | 16x16 | (8,8) | 2 / 0.4 / loop | `gold_light` brackets, coin glyph. Keys: `ink, gold_light, gold, gold_dark` |
| `cursor_repair_0..1` | 16x16 | (8,8) | 2 / 0.4 / loop | `flame` brackets, hammer glyph (`stone_light` head, `wood_light` handle). Keys: `ink, flame, stone_light, wood_light` |
| `cursor_aim_0..1` | 16x16 | (8,8) | 2 / 0.4 / loop | `moon` brackets, no corner glyph, a 3x3 plus in the centre (pixels (7..9,8) and (8,7..9)). Keys: `ink, moon, stone_light` |

**Geometry, the same in every state:**

- **Frame 0 (out):** four L-shaped corner brackets on the cell edge. Each arm is 5 px
  long and 2 px thick: the outer line (on the canvas edge) in the state colour, the
  inner line `ink`. The four corners are exact mirror images of each other.
- **Frame 1 (in):** the same brackets moved 1 px diagonally inward. Nothing else
  changes.
- **Glyph:** a symbol in the state colour with an `ink` outline, at most 6x6 px
  outline included, inside the top-right corner region x 10..15, y 0..5, replacing
  the top-right bracket. It does not move between the two frames.
- **Centre:** x 3..12, y 3..12 stays transparent, except the aim plus. The ghost or
  the structure in the cell must stay visible.
- No text, numbers, fill, glow or shadow.

## Match these

- `sprites/terrain/grass.png`, `soil.png`, `path.png` (16x16): the ground it sits on;
  the bracket ends sit exactly on the cell edge.
- `sprites/buildings/wall_join_10.png` and `sprites/buildings/gun_tower.png` (32x48,
  pivot (16,44)): structures that stand in the cell; the glyph must not hide them.
- `sprites/ui/icon_money.png`: the coin shape the sell glyph echoes.
- `sprites/ui/button_focus.png` and `sprites/ui/panel.png`: today's UI chrome (ink
  outline, gold trim); the cursor belongs to that family, not to the world art.
- `docs/reference-sheet.png`: the night half, the ground it must read over.

## How to make it

1. BASE from `implementation/sprites/generation/PROMPTS.md` (canvas 16x16, pivot 8,8)
   plus STRIP (N=2, ordered "brackets out", "brackets 1 px in") and these lines:
   "A crisp pixel-art map-cell selection cursor drawn on an exact 16x16 pixel grid,
   enlarged so that every art pixel is one flat square block of equal size. Four
   L-shaped corner brackets, each arm 5 pixels long and 2 pixels thick, a coloured
   outer line and a dark ink inner line. Empty centre. Flat colours, no anti-aliasing,
   no gradient, no glow, no text."
2. **Neutral first:** one call, `transparent_background=true`, two equal cells with
   a wide gutter. Inputs: `docs/reference-sheet.png` (style reference),
   `sprites/terrain/grass.png` enlarged by nearest (scale reference: one cell). Accept
   it only when the block grid is regular and the four corners are symmetric.
3. **Other states:** one call each, with the accepted neutral raw as the edit target.
   Change only the bracket colour and add the state's glyph; keep the image size,
   cell positions and bracket shapes.
4. **Export:** for each cell, crop exactly the 16x16-block grid (measure the raw's
   block size and align the crop to block edges); `content_scale` = 16 / crop width;
   `content_anchor_xy` = (8,8), so the content lands at (0,0). The default anchor
   would clip it. One `content_scale` per state's two frames. Use each state's
   `palette_keys` from the table.
5. If a bracket is lopsided, a corner comes out a different length, or the glyph
   bleeds into the centre after reduction, revise the raw. Never fix pixels.

## Review with the owner

The page shows every state at 1x and 4x, pulsing at 0.4 s and as still pairs, on a
16 px grid over tiled `grass.png`, `soil.png` and `path.png`, over a bright stand-in
for snow (`bone`), with `gun_tower.png` and `wall_join_10.png` standing in the cell.
It shows each state twice: unlit (if 0131 draws the cursor above the night ramp) and
in the night preview (if it is drawn in the world).

Questions for the owner:

1. "Cada estado se distingue pela cor e pelo símbolo no canto. Dá para saber o que o clique vai fazer só de olhar, à noite?"
2. "A pulsação (os cantos entram 1 pixel) está calma o bastante, ou incomoda?"
3. "As cores estão boas (branco neutro, verde colocar, vermelho bloqueado, azul melhorar, dourado vender, laranja consertar, lilás mirar), ou quer trocar alguma?"

## Acceptance

- [ ] 14 frames: 7 states x 2; every one 16x16 with pivot (8,8).
- [ ] Frame 0 brackets touch the canvas edge; frame 1 is the same set 1 px in; the four corners are mirror images; arms 5 px, 2 px thick.
- [ ] Glyph (outline included) inside x 10..15, y 0..5, identical in both frames; neutral and aim keep all four brackets; centre x 3..12, y 3..12 empty except the aim plus.
- [ ] Binary alpha; no fill, glow, shadow, text or numbers.
- [ ] Only each state's `palette_keys` colours, through `render_source`; `importer_recipe_matches` true.
- [ ] Each state tells apart from the others by glyph as well as colour; readable at 1x over grass, soil, path, snow and in the night preview; the tower in the cell stays readable.
- [ ] `build.py` twice gives identical bytes, `--check` passes, checks.json all `true`.

## Delivery

`implementation/backlog/deliveries/A004-cursor/` with the files of contract 9.1:
`raw/` (each return with `.prompt.txt` and `.call.json`),
`native/cursor_<state>/none/01..02.png` for the seven states, `preview/`,
`rejected/`, `contract.json` (`palette_mode` "A", `palette_keys` per state),
`checks.json`, `build.py`, `index.html`, `review-log.txt`. After the owner approves
in words: `APPROVAL.json`, `CLAUDE-A004-PROMPT.txt` (mapping e.g.
`native/cursor_blocked/none/01..02.png -> sprites/ui/cursor_blocked_0..1.png  16x16 pivot (8,8) draw 1.0  0.4 s loop`,
replacing 0131's code-drawn outline for game task 0146), then
`python implementation/backlog/assets.py set A004 approved`.
