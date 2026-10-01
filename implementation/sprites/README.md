# Sprite production loop

This is a new art backlog for HARVEST THE NIGHT. The original 110 game tasks are
complete; this queue has its own prompts, statuses, index and journal. Planning
does not mean the new sprites have been produced. All 20 production tasks start
as `todo`.

Read `AUDIT.md`, `ART_DIRECTION.md`, `PIPELINE.md` and then
`prompts/00-RUNNER-LOOP.md`. `generation/PROMPTS.md` contains the image prompts.

## Run one task

From the repository root, ask the agent:

```text
Read and execute implementation/sprites/prompts/00-RUNNER-LOOP.md.
```

The preferred production environment is an agent with the built-in ImageGen
tool and filesystem/Godot access. Image generation is a tool capability, not a
Python dependency. A text-only CLI cannot create those images just by reading
the prompts. It must stop with an explicit capability blocker for that task;
it must not substitute ASCII sketches for the requested raster art.

```powershell
python implementation/sprites/task.py next
python implementation/sprites/task.py stats
python implementation/sprites/task.py check
```

## Repeat the original CLI model

`loop.ps1` follows the project's Claude CLI driver, with completion checks,
the local Godot path, dry-run support and a separate log directory:

```powershell
.\implementation\sprites\loop.ps1 -Tasks 20 -DryRun
.\implementation\sprites\loop.ps1 -Tasks 20
```

It does not install tools, start itself, schedule future work, or assume that
Claude CLI has an image-generation tool. Use it only with a configured agent
that actually exposes the required generation capability. An interrupted,
failed or blocked task stops the driver. Resume through the runner after fixing
the cause; change `blocked` to `todo` explicitly when the cause is resolved.

## Production order

1. Establish the look with a small style board and a playable pilot.
2. Build the reproducible raster import path and repair visual anchors.
3. Replace the player, terrain, vegetation, crops and farm buildings.
4. Replace defences, enemies, boss and combat effects.
5. Unify icons and day/night lighting, then inspect the full game.

The grid stays 16 px and the viewport stays 480x270. Sprite canvas size is
separate from collision footprint. The proposed scale is tested in the pilot
before the remaining families are produced.

## Files

| File | Purpose |
|---|---|
| `AUDIT.md` | Findings from source and actual Godot captures |
| `ART_DIRECTION.md` | Proposed visual rules, scale and review criteria |
| `PIPELINE.md` | Source ownership, cuts, alpha, manifests and integration |
| `inventory.json` | Current PNG dimensions, owners and SHA-256 snapshot |
| `baseline-check.json` | Read-only PNG byte versus decoded-pixel comparisons |
| `snapshot.py` | Explicit baseline inventory/comparison writer; never edits runtime art |
| `plan.py` | Task definitions; generates missing prompts without overwriting work |
| `task.py` | Separate queue with dependency checks and generated index |
| `BACKLOG.md` | Generated from prompt status lines |
| `PROGRESS.md` | Append-only production journal |
| `generation/PROMPTS.md` | Base prompt, family briefs and correction prompts |
| `prompts/00-RUNNER-LOOP.md` | One complete, reviewed production task per invocation |
| `loop.ps1` | Optional Claude CLI driver, following the original model |

```powershell
# Recreate missing task prompts, preserving existing status/content:
python implementation/sprites/plan.py
python implementation/sprites/task.py index

# Godot path for this checkout:
$env:GODOT = 'C:\Users\Helel\Documents\godot\Godot_v4.7.1-stable_win64_console.exe'
python tools/verify.py
python tools/shot.py sprites/0003 noon dusk wave
```

Current visual baseline: `implementation/shots/sprites/baseline/`.
Production screenshots use `implementation/shots/sprites/<task-id>/` so the
existing screenshot tool can be reused. Do not overwrite the baseline.
