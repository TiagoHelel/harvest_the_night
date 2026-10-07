# A031 - Artisan machines

- **Status:** todo
- **For game task:** 0213
- **Dressed by game tasks:** 0187, 0188
- **Spec after game task:** 0188
- **Family:** buildings
- **Mode:** A - raw ImageGen sources, Claude reduces them to the 42-colour palette
- **Size of the job:** 5 machines x 3 states (idle, active, hurt) = 15 frames; 5 masters + 5 three-cell state sheets

## What it is for

Artisan machines multiply what the farm earns (game tasks 0187 and 0188): the
keg turns fruit into wine and juice, the preserves jar makes jelly and pickles,
the dairy makes cheese and butter, the loom weaves wool into cloth, and the mill
grinds wheat into flour and beet into sugar. The player builds them by day,
sees them idle or working all day, and must recognise each without text. At
1080p they sit beside today's workshop, kitchen, press and generator, but at
**full density** (1 art px = 1 logical px), smaller than the coop and far
smaller than the house. Working is shown only by the mechanism (and the jar's
small fire); the runtime adds smoke and light from the points.

## Deliverables

The table is provisional: game task 0188 settles the final canvas/footprint/states and updates it; start only when `python implementation/backlog/assets.py next` offers this pack.

| Runtime name | Native canvas | Pivot | Frames / seconds / loop | Notes |
|---|---|---|---|---|
| `keg`, `keg_active`, `keg_hurt` | 48x56 | (24,52) | 1 per state / 0.55 / static | Footprint 2x2. A big oak cask with iron hoops lying on a timber trestle, a wooden spigot. Visible 28-36 wide x 30-38 tall. Active: a small glass airlock on the bung shows bubbles (2-3 `bone` px) and the spigot handle turned. Hurt: a sprung hoop and a split stave. No points. |
| `preserves_jar`, `preserves_jar_active`, `preserves_jar_hurt` | 48x56 | (24,52) | 1 per state / 0.55 / static | Footprint 2x2. A large glazed crock with a wired lid on a small brick stove with a short stovepipe. Visible 26-34 wide x 34-44 tall. Active: a small fire in the firebox mouth (`flame`, `flame_hot`) and the lid lifted 1 px. Idle and hurt: firebox dark. Hurt: a chipped crock rim and loose bricks. Points: `light_xy`, `smoke_xy`. |
| `dairy`, `dairy_active`, `dairy_hurt` | 64x64 | (32,60) | 1 per state / 0.55 / static | Footprint 3x2. An open-fronted timber lean-to sheltering a tall butter churn and a small screw cheese press. Visible 48-56 wide x 40-52 tall. Active: churn plunger raised high, press screw turned down onto a cheese mould. Hurt: a broken roof board and a cracked churn band. No points. |
| `loom`, `loom_active`, `loom_hurt` | 64x64 | (32,60) | 1 per state / 0.55 / static | Footprint 3x2. A wooden floor loom under a small shingled awning, warp threads and a cloth roll. Visible 48-56 wide x 40-52 tall. Active: the shuttle mid-warp in the open shed and the beater pulled forward. Idle: shuttle parked at the side. Hurt: a snapped crossbeam end and slack threads. No points. |
| `mill`, `mill_active`, `mill_hurt` | 64x96 | (32,92) | 1 per state / 0.55 / static | Footprint 3x3. A small timber post windmill on a stone base with four lattice sails. Visible 52-64 wide (the sails may use the full 8 px overhang) x 72-88 tall; its top stays below the house's. Idle: sails bare lattice, cloth furled along the spars. Active: sails spread with cloth (`bone`, `bone_dark`). Hurt: one sail broken, a loose board. No points. |

- Directions: `none`. No mirrors. One canvas and one pivot per machine across
  its states. Not in `ArtPlacement.visual_scale`'s 2.0 list: drawn at 1.0.
- **States.** Idle never looks active. Active changes only the mechanism listed
  (and the jar's firebox); the frame, base and silhouette stay on the same
  pixels as idle. Hurt keeps the same base and identity; it is never on fire
  and never collapsed.
- **Wreck: none by default.** If 0187 gave the machines 0186's
  wrecked-but-standing state, 0188 adds one `<id>_wreck` row per machine to
  this table before the pack starts; Codex makes exactly the rows listed.
- **Points** (only the jar): `light_xy` on the firebox mouth and `smoke_xy` on
  the top opaque pixel of the stovepipe, the **same coordinates in idle, active
  and hurt** and opaque in each, as today's stations carry them. The runtime
  lights and smokes them only while the jar works. The active `light_xy`
  pixel is warmer (higher red) than the idle one, as `check_station_art.py`
  requires of a lit station.
- Never baked: products, fruit, bottles, sacks or cloth bolts lying beside the
  machine, smoke, steam, flour dust, glow, a ground patch, a shadow, text or
  signs. The "ready" marker is code.

## Match these

- `sprites/buildings/workshop.png`, `workshop_active.png`, `workshop_hurt.png`,
  `sprites/buildings/kitchen*.png`, `sprites/props/press*.png`,
  `sprites/props/generator*.png` (48x48, pivot (24,44), drawn at 2.0): the
  idle/active/hurt language, materials and a lit firebox. Match their look,
  **not** their half density.
- Raw `assets/art_source/buildings/workshop/states.png` (2172x724, three cells)
  and `implementation/sprites/generation/0012-workshop-states.prompt.txt`: how a
  three-state sheet was asked for and cut at one scale.
- Raw `assets/art_source/buildings/house/whole.png`: timber, terracotta, stone.
- Farmer `implementation/fhd-player/pilots/2026-10-06/walk-final-mirrored/native-40/walk/down/01.png`
  (body 16x32): the keg is about the farmer's height, the mill about 2.5 times.
- `docs/reference-sheet.png` ("PRODUZIR E COZINHAR" panel): production props.

## How to make it

1. Prompt = PROMPTS.md BASE (braces: canvas and pivot from the table) +
   PRODUCTION_BUILDING with `{keg | preserves jar | dairy | loom | mill}` and
   the function cues of its row, + STRIP for the state sheet, + CORRECTION for
   revisions. Add: "Full-density pixel art for a {2x2 | 3x2 | 3x3}-cell
   footprint, about {W} art pixels wide; no products, ground, shadow or text."
2. Per machine a master (idle), `transparent_background=true`, 2 candidates,
   with `assets/art_source/buildings/workshop/master.png` attached as "material
   and camera style reference". Pick by the native reduction.
3. Then one sheet call per machine with exactly 3 cells, left to right
   `IDLE, ACTIVE, HURT`, the accepted master attached as "identity master and
   precise geometry reference", worded like
   `0012-workshop-states.prompt.txt` (fixed edges identical between idle and
   active; only the listed working parts change).
4. Export with the mode A recipe: one `content_scale` per machine sheet,
   measured `sheet_cell_xywh` (cells must not overlap), a crop per cell and a
   `content_anchor_xy` at the base's bottom-centre, so the base lands on the
   same pixels in all three states. Lowest opaque row `pivot_y - 1`.

## Review with the owner

`index.html` shows each machine's three states at 1x and 4x, by day and in the
night preview, plus a jar preview with a `flame` 3x3 at `light_xy` (preview
only); beside the farmer frame and `sprites/buildings/workshop.png` drawn at 2x
(its real on-screen size), feet on one ground line; over tiled
`sprites/terrain/grass.png` with the footprint outlined; an idle/active blink
compare per machine; points on an overlay.

Ask the owner:
- "Cada máquina é reconhecível sem texto: barril, conserva, laticínios, tear e moinho?"
- "A diferença entre parada e trabalhando aparece bem a 1x?"
- "O tamanho delas ao lado do fazendeiro, da oficina e da casa está bom?"

## Acceptance

- [ ] 15 frames, one canvas and pivot per machine as the table.
- [ ] Lowest opaque row `pivot_y - 1`, centred (±1); visible sizes inside the ranges.
- [ ] Full density: no 2x2 pixel blocks.
- [ ] Idle vs active differ only in the mechanism (and the jar's fire); the base bbox is identical across states.
- [ ] Jar `light_xy` / `smoke_xy` on opaque pixels at the same coordinates in all three states; active light pixel warmer than idle.
- [ ] One `content_scale` per machine; mode A only 42 colours; `importer_recipe_matches`.
- [ ] Binary alpha; no products, smoke, glow, ground, shadow or text.
- [ ] `build.py` twice is byte-identical and `--check` passes; checks.json all `true`.

## Delivery

Folder `implementation/backlog/deliveries/A031-machines/` with `raw/`,
`native/<id>[_active|_hurt]/none/01.png`, `preview/`, `rejected/`,
`contract.json`, `checks.json`, `build.py`, `index.html`, `review-log.txt`.

`CLAUDE-A031-PROMPT.txt` maps, per machine,
`native/<id>[_active|_hurt]/none/01.png -> sprites/buildings/<id>[_active|_hurt].png <canvas> pivot <pivot> draw 1.0 static`
with the canvases above, `active` and `hurt` as `variant_of` the idle entry,
the jar's `light_xy` / `smoke_xy` on all three states, and says the ids stay
out of `ArtPlacement.visual_scale`. They replace the stand-ins of 0187 and 0188
in game task 0213.

Last step, only after the owner approves in words recorded verbatim in
`APPROVAL.json`: `python implementation/backlog/assets.py set A031 approved`.
