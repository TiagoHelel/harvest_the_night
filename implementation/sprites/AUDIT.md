# Visual audit — 2026-10-01

## What was inspected

`design.md` section 18, `docs/reference-sheet.png`, the original runner and art
prompts, `tools/gen_sprites.py`, `tools/sprite_maps.py`, `tools/cut_sheet.py`,
`tools/palette.py`, `tools/verify.py`, `tools/shot.py`, `src/tools/shot.gd`,
`src/ui/world_view.gd`, `src/ui/player_view.gd`, `src/ui/player_art.gd`,
`src/ui/player_frames.gd`, `src/ui/particles.gd` and `scenes/World.tscn`.

The original queue reports **110/110 done**. Some root README text still calls
the project an empty scaffold; the code and captures show a playable game.

Godot was found at
`C:/Users/Helel/Documents/godot/Godot_v4.7.1-stable_win64_console.exe`.
The old tooling defaults to another user's 4.7.2 path, so this loop explicitly
sets `GODOT` without changing the project's engine/version declarations.

Fresh baseline captures were rendered and opened individually:

- `../shots/sprites/baseline/noon.png`
- `../shots/sprites/baseline/dusk.png`
- `../shots/sprites/baseline/wave.png`

They are 480x270, produced by the existing fixed-state screenshot tool using
the actual rendering backend. Historical 0082 captures and the reference sheet
were also inspected. See `PROGRESS.md` for verification results.

## Findings and their implications

| Finding | Evidence | Production response |
|---|---|---|
| Scale and rendering style clash | Farmer has a 48x52 canvas and roughly 44 px body; tree and shop are 16x16 | Test a smaller pixel-art farmer and larger vegetation/shop art as a coherent group |
| Repeating ground overwhelms forms | Tiny grass speckles cover large areas; rock terrain repeats rectangular brick shapes | Use quieter pixel clusters, controlled variants and natural rock masses |
| Farm lacks recognizable landmarks | House is 48x48, workshop 32x32, shop a tiny prop; baseline loses the reference's material richness | Redesign coherent roofs, facades, tools, counters and ground contact |
| Animation substitutes exist | `craft`, `fish`, `harvest` are single cut frames; verbs borrow poses | Produce deliberate work cycles and preserve verb coverage |
| Generated enemy animation is limited | `_pose_of()` alternates base and `_walk_b`; death PNGs exist but are not selected there | Create authored motion and view-owned death playback with bounded lifetime |
| Upgrades rely on repeating pixels | `GROWS` duplicates a tower band; damage uses scattered holes | Author level changes and recognizable broken states |
| Night looks like dim daytime | Fresh wave capture remains largely green, with very strong warm bloom | Tune the shared ramp and localized lamps after materials are coherent |
| Larger sprites require view changes | Props use texture top-left as node position; nested Actors container is not explicitly y-sorted | Audit bottom anchors and nested sorting; test walking in front/behind |
| Multi-cell art is sliced | `_art_for()` builds cell-specific names, house/workshop/kitchen have generated quarters | Define a full-building visual anchor or validated slice strategy before increasing roof height |
| Runtime missing-art fallbacks can hide mistakes | `_texture_for()`, `_crop_texture()` and `PlayerArt.pose()` can fall back | Make offline ownership/reference checks fail on missing required assets |

## Source constraints

Most sprites are generated from ASCII maps. The generator emits **171 PNG
outputs**, including terrain atlas, fixture slices, derived levels and states.
Player frames are a separate deterministic cut of `docs/sprites_sem_fundo.png`.
There are **217 current sprite PNGs**: 171 from the ASCII generator and 46
player frames from the cutter; generated palette metadata is an additional file.
`inventory.json` records every committed/current PNG under `sprites/`, its
actual dimensions, SHA-256 and which of those two paths owns it.

Simply overwriting a PNG will fail `gen_sprites.py --check` or
`cut_sheet.py --check`; the old generators can also overwrite the replacement.
The new raster source path must be added with explicit ownership and the old
checks must remain effective for assets that have not migrated.

## Baseline verification finding

The full existing verifier was run with the local Godot before runtime art was
changed. Result: **18 passed, 0 skipped, 5 failed** in 173 seconds. Rules passed
6417 assertions, input passed 980 cases, both exports passed, and hashes stayed
sim `1961000123` / data `407837701`.

The five failing checks are sprites, player art, font, logo and icon. A read-only
decoded RGBA comparison confirmed zero pixel differences in each group, despite
PNG byte differences: respectively 48, 46, 2, 1 and 2 PNGs. See
`baseline-check.json`. The historical cause of the encoding discrepancy has not
been proven; different PNG bytes do not establish that someone painted over art.

Task 0001 must normalize/reproduce this baseline deliberately before completing
the first production gate. Preserve the snapshot, compare decoded pixels first,
then regenerate existing outputs only from their unchanged sources and review
the diff. Investigate portability/version differences if byte divergence recurs.
Keep strict source validation and hash baselines; do not disable five checks or
accept a new simulation baseline to get a green result. This planning change
leaves existing runtime art intact.

The owner's character sheet is a reference for identity and actions. Preserve
the original file. The reference sheet establishes warmth, readable silhouettes,
three-quarter top-down perspective and a recognizable farm under night light;
it is a composed illustration, not a ready-to-cut production atlas.

## Scope

This backlog improves raster art and the view code required to show it. It
does not add biomes, NPC systems, crops, towers, enemy rules or progression.
`src/core/`, save formats, map occupancy, balance tables and determinism
baselines must not change for an art task.
