# A013 - Trees through the seasons

- **Status:** todo
- **For game task:** 0164
- **Dressed by game tasks:** 0159
- **Family:** props
- **Mode:** A - raw ImageGen sources, Claude reduces them to the 42-colour palette
- **Size of the job:** 15 sprites: 6 seasonal trees, 9 snow caps; no animation

## What it is for

The farm's two trees (`tree`, `tree_b`) change with the year: blossom in spring
(days 1-14), today's green in summer, ochre and rust in autumn, bare branches
under snow in winter. In winter, small snow caps also settle on every stump,
rock, stone seam and ore node, drawn by the view as an overlay over the
unchanged node. The player sees trees all over the map by day and at night under
the relight; at 1080p a tree is 144x168 screen px beside the 128 px farmer, so a
season must read at a glance from its silhouette and colour, never as fire and
never as a different species. Game task 0159 fakes all this with a palette
remap; this pack replaces that stand-in.

## Deliverables

| Runtime name | Native canvas | Pivot | Frames / seconds / loop | Notes |
|---|---|---|---|---|
| `props/tree_spring` | 40x48 | (20,44) | 1, static | `tree` in blossom. Manifest `variant_of: props/tree`. |
| `props/tree_autumn` | 40x48 | (20,44) | 1, static | `tree` in autumn colours. `variant_of: props/tree`. |
| `props/tree_winter` | 40x48 | (20,44) | 1, static | `tree` bare, snow on the upper surfaces of its branches. `variant_of: props/tree`. |
| `props/tree_b_spring`, `props/tree_b_autumn`, `props/tree_b_winter` | 40x48 | (20,44) | 1 each, static | The same three seasons of `tree_b`. Also `variant_of: props/tree` (variants cannot chain). |
| `props/stump_snow` | 16x16 | (8,14) | 1, static | Overlay drawn over `stump` (cut top at rows 6-8). |
| `props/rock_snow`, `props/rock_b_snow` | 16x16 | (8,14) | 1 each, static | Over `rock` / `rock_b` (tops at row 4). |
| `props/ore_snow`, `props/ore_b_snow` | 16x16 | (8,14) | 1 each, static | Over `ore` (top row 3) / `ore_b` (top row 4). The ore's gold clusters stay visible. |
| `props/seam_snow`, `props/seam_b_snow` | 16x16 | (8,14) | 1 each, static | Over `seam` / `seam_b` (tops at row 7). |
| `props/snow_cap` | 16x16 | (8,14) | 1, static | Generic cap for 1-cell nodes with no cap of their own (0156's copper, coal and gold nodes). Must fit both `ore` and `rock`. |
| `props/snow_cap_2x2` | 32x32 | (16,30) | 1, static | Generic cap, one per 2x2 hardwood stump (0156). Must fit the stand-in 0156 draws: `stump` scaled 2x NEAREST, lowest opaque row 29, centred on x=16. |

**Trees.** All six: `content_scale` exactly 0.03700440528634361 and no
`palette_keys`, because the importer's `variant_of` rule demands the master's
scale and keys. `crop_xywh` is measured in the return: bottom edge on the
trunk's lowest opaque raw row, centred on the trunk, sized like the master's
crop (`tree` [35,220,962,1135] in `assets/art_source/masters/tree.png`;
`tree_b` [26,202,980,1153] in `assets/art_source/props/tree_b.png`), larger only
if the crown needs it, never a different scale; default content anchor. Targets:

- Lowest opaque row 43, trunk centred on x=20 ±1, bounding box inside x 1-38 and y >= 1, one 8-connected silhouette (`tools/check_prop_art.py` rejects detached petals, leaves or flakes). Trunk and roots below row 33 keep the base tree's shape (±1 px). Visible height 38-43.
- The wind shader sways rows above 13, fades between 13 and 22 and never moves rows below 22: keep the base tree's crown/trunk split.
- Spring: the base crown outline (±2 px), leaves kept, blossom clusters of 3 px or more (`bone`, `bone_dark`, `roof_light`, `skin_light`) on 20-40% of the crown's pixels. The palette has no pink; strong pink reduces to roof red and reads as fruit.
- Autumn: the base crown outline (±2 px) in `gold_dark`/`gold`/`gold_light`/`roof_dark`/`roof` with the wood ramp; at most 10% grass- or leaf-ramp pixels; no `flame_hot`, and `flame` on at most 8% of the crown, so it never reads as a burning tree at night.
- Winter: no leaves (at most 3 grass/leaf pixels); bare branches in the wood ramp with the base tree's dark outline; snow (`bone`, `moon`, `bone_dark` underside) lying on top of the branches; the bare crown still spans at least 26 px so it reads as the same tree.

**Caps.** `palette_keys` `["bone","moon","bone_dark","stone_light","night"]`
for all nine (`night` is the hosts' outline colour). `crop_xywh` = the cap's
measured box; `content_scale` per cap, chosen for its width; an explicit
`content_anchor_xy` that seats it on its host; both recorded. Caps are not
grounded: `grounded_on_pivot` does not apply; the fit rule does (check
`caps_fit_hosts`), with cap and host composited at the same canvas origin:

1. every cap pixel lies in a column where the host is opaque, at most 2 rows above the host's top pixel in that column and at most 5 rows below it;
2. at least 60% of cap pixels overlap opaque host pixels;
3. the cap covers at most 35% of the host's opaque pixels;
4. one 8-connected piece, 2-6 rows tall, 55-80% of the host's visible width, centred over the host's highest part.

The generic caps meet 1-3 against every host listed in their row.

## Match these

- `sprites/props/tree.png`, `tree_b.png` (visible 36x42 / 36x43) and their raws above: identity, trunk, outline (`night`), light from the upper left; edit targets.
- `sprites/props/stump.png`, `rock.png`, `rock_b.png`, `ore.png`, `ore_b.png`, `seam.png`, `seam_b.png` (16x16, pivot (8,14)) and raws `assets/art_source/props/<host>.png`: the silhouettes each cap must rest on.
- `docs/reference-sheet.png`, `assets/art_source/masters/style-day.png`, `style-night.png`: foliage clusters, materials, night.
- If delivered: `implementation/backlog/deliveries/A012-winter-ground/native/grass_winter/none/01.png` (the snow ground the winter trees stand on).
- The farmer `implementation/fhd-player/pilots/2026-10-06/walk-final-mirrored/native-40/walk/down/01.png`: scale.

## How to make it

1. Trees: PROMPTS.md BASE + TREE + CORRECTION for revisions, braces filled
   with 40x48 and pivot (20,44). `transparent_background=true`. Edit target =
   the base raw (`assets/art_source/masters/tree.png` for `tree_*`,
   `assets/art_source/props/tree_b.png` for `tree_b_*`); style reference
   `docs/reference-sheet.png`. Add: "Change only the season. Keep the trunk,
   roots, crown outline, camera, light and size of the edit target exactly, in
   the same place on the canvas." Then one season line: spring "apple-blossom
   clusters, cream white with a few soft salmon-pink accents, among the green
   leaves"; autumn "ochre, gold and rust leaves, a few gaps in the crown, no
   bright orange glow"; winter "bare branches, a light layer of snow resting on
   their upper surfaces, no leaves, no falling flakes".
2. One season per call: `tree_autumn`, `tree_spring`, `tree_winter`, then the
   three `tree_b_*` with the accepted `tree_<season>` raw attached as "season
   style reference". Reject a return whose trunk moved or resized: reduced at
   the fixed scale, its trunk base must land on (20,44) ±1.
3. Caps: BASE + RESOURCE_PROP + CORRECTION, `transparent_background=true`, one
   cap per call. Attach the host's raw as "fit reference: the object this snow
   rests on; do not draw it" and `docs/reference-sheet.png` as style. Add: "Only
   a soft cap of settled snow shaped to rest on the top of the attached
   {host}, same three-quarter view, lit from the upper left, a slightly darker
   underside where it meets the {host}; nothing else." `rock_snow` first as
   the cap master; the others attach it as "style reference". `snow_cap_2x2`
   uses `assets/art_source/props/stump.png` as its fit reference.
4. One candidate per call; at most 3 targeted revisions per sprite.

## Review with the owner

`index.html` shows, at 1x and 4x (nearest): each tree beside its three seasons,
`tree_b` beside `tree`, the farmer standing next to them with feet on the same
line, over tiled `sprites/terrain/grass.png` and (winter) over A012's
`grass_winter` if delivered, else over a flat `bone` field; then each host
alone, the host with its cap, and the fit overlay (any cap pixel over a
transparent host pixel marked red); the generic caps over `ore`, `rock` and the
2x stump stand-in. Day and night preview (contract 9.5) for everything, a 16px
grid toggle. Static art: the game sways the crown in code.

Ask the owner (pt-BR):

1. "As flores da primavera ficaram creme com toques rosados, porque a paleta não tem rosa de verdade. Está bom, ou prefere flores brancas?"
2. "A árvore de outono parece folhagem de outono, e não fogo, também na prévia noturna?"
3. "Os montinhos de neve assentam nos tocos, pedras e minérios sem parecer que flutuam?"

## Acceptance

- [ ] 15 files: 6 trees at 40x48 / (20,44), 8 caps at 16x16 / (8,14), 1 cap at 32x32 / (16,30); 1 static frame each.
- [ ] Binary alpha, true transparent background, no baked shadow, grass patch, glow, falling flakes, night version or text.
- [ ] Mode A: `render_source` with each recorded recipe reproduces `native/`; trees at scale 0.03700440528634361 with no `palette_keys`; caps only use their 5 keys.
- [ ] Every tree meets the targets above (grounded on row 43, trunk at x=20 ±1, one 8-connected piece, trunk below row 33 unchanged, season colour limits).
- [ ] `caps_fit_hosts` is true for every cap and every host it serves.
- [ ] At 1x, by day and in the night preview, each season reads at a glance, the autumn tree never reads as burning, and every host still reads as stump, rock, seam or ore under its cap.

## Delivery

- Folder `implementation/backlog/deliveries/A013-seasonal-trees/`, with the files of contract 9.1: `raw/` (+ `.prompt.txt`, `.call.json`), `native/<name>/none/01.png` (e.g. `native/tree_b_winter/none/01.png`, `native/ore_b_snow/none/01.png`), `preview/`, `rejected/`, `contract.json`, `checks.json` (with `caps_fit_hosts`), `build.py`, `index.html`, `review-log.txt`.
- `CLAUDE-A013-PROMPT.txt` maps each file, e.g. `native/tree_spring/none/01.png -> sprites/props/tree_spring.png  40x48 pivot (20,44) draw 1.0 static, variant_of props/tree` and `native/rock_snow/none/01.png -> sprites/props/rock_snow.png  16x16 pivot (8,14) draw 1.0, winter overlay drawn over rock at the same placement`; lists the cap each host uses (`stump`, `rock`, `rock_b`, `ore`, `ore_b`, `seam`, `seam_b` -> `<host>_snow`; 0156's 1-cell nodes -> `snow_cap`; `hardwood_stump` -> `snow_cap_2x2`); and says the seasonal frames replace 0159's remap for the trees, summer stays today's tree.
- Last step, only after the owner approves in words recorded in `APPROVAL.json`: `python implementation/backlog/assets.py set A013 approved`.
