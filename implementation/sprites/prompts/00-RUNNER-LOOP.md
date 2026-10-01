# 00 — SPRITE RUNNER LOOP

Read and execute this procedure for exactly one sprite task, then stop.
This queue is independent of the completed game implementation backlog.

## 1. Select and claim

From the repository root:

```powershell
python implementation/sprites/task.py check
python implementation/sprites/task.py next
python implementation/sprites/task.py doing <id>
```

Resume `doing` first, otherwise pick the lowest actionable `todo`. If the queue
is empty or blocked, report the blockers and stop. Do not invoke `tools/task.py`
to change statuses for this art queue.

## 2. Read

Read the selected prompt, its dependencies, `implementation/sprites/AUDIT.md`,
`ART_DIRECTION.md`, `PIPELINE.md`, `generation/PROMPTS.md`, `PROGRESS.md` and
the actual affected code. Open `docs/reference-sheet.png`, the owner's player
sheet when relevant and current baseline/last accepted captures. Read local
repository instructions. Use the original runner's architecture and testing
rules; this art runner's explicit raster-source contract replaces the old
ASCII-only rule for migrated assets.

## 3. Produce a complete family

Keep grid, collision, simulation and balance unchanged. Code, comments, prompts
and repository notes remain in English; player text stays in the i18n tables.
Use the imagegen skill and built-in raster tool for generated art. Check actual
tool availability before claiming success. If the agent cannot generate images,
record a precise blocker; do not silently use an API/CLI fallback, install tools,
or replace the requested assets with code-drawn placeholders.

Combine BASE plus the family brief and exact asset/frame contract. Preserve
masters and use them as references for subsequent poses. Save accepted raw
sources and prompt/revision metadata in the project. Implement source ownership
and deterministic cuts before replacing runtime PNGs. Limit each asset to three
targeted visual revisions per task; keep completed candidates and record why a
task cannot meet its gate. Do not multiply generations without evaluating them.

Each task must produce its stated deliverable and required view integration.
If interrupted, keep `doing` so it can resume. If genuinely blocked, mark it
`blocked` with a concrete cause and append the journal. Do not call a partial
family done. No auto-approval pause is required for routine reversible art work.

## 4. Verify and actually look

```powershell
$env:GODOT = 'C:\Users\Helel\Documents\godot\Godot_v4.7.1-stable_win64_console.exe'
python implementation/sprites/task.py check
python tools/verify.py
python tools/shot.py sprites/<id> noon dusk wave result tech
```

Respect an explicitly provided alternative `GODOT` path. Run the raster/source
check introduced by 0002; never disable old checks or accept changed sim/data
hashes for art. Open every relevant capture at native size and 3x nearest;
inspect source alpha, silhouettes, animation contact sheets and all family
states. Use extra showcase scenarios from 0003 where the base captures do not
cover a required state. Fix failed visual criteria even when verification passes.

## 5. Close, journal and commit

Mark `done` only when every selected task criterion and verification pass.
`task.py done` checks dependencies; the agent remains responsible for evidence.

```powershell
python implementation/sprites/task.py done <id>
python implementation/sprites/task.py check
```

Append `implementation/sprites/PROGRESS.md` with date, changes, source/master
paths, prompts/revisions, hashes, verification counts, capture paths, visual
criteria results and known follow-ups. Use client/user date, not an arbitrary
host timezone. Preserve old entries. Do not mark planning as sprite production.

If repository policy calls for a commit, stage only this task's actual files
and create one focused commit. Do not stage unrelated user changes or invent
co-author identities. Do not push, publish, merge, start an unattended driver
or create a recurring automation as part of one task.

## 6. Report and stop

Report task ID, finished family, verification result, source/capture paths and
queue status. On a blocker report exactly what was saved and what is missing.
Stop after this task; a subsequent invocation handles the next one.
