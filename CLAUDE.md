# HARVEST THE NIGHT - working notes

A Godot 4.7 game built by a backlog loop. Before doing anything here, read
`implementation/prompts/00-RUNNER-LOOP.md` - it is the procedure for doing one
task, and `implementation/README.md` is the plan.

## The one command

```bash
python tools/verify.py
```

Nothing is done until that prints PASS. Run it rather than the Godot scripts by
hand: it does `--import` first, which refreshes the global `class_name` cache. A
brand new `class_name` is invisible to `--script` runs until that happens, and
the error you get instead is a misleading "Identifier not declared in the
current scope".

## The architecture, in four rules

1. **`src/core/` is node-free and deterministic.** It advances only through
   `Sim.tick(state)` at a fixed 30Hz. No nodes, no `randf()` outside the run's
   seeded RNG, no `Time.*`, no iterating an unordered Dictionary without sorting
   the keys first.
2. **`src/ui/` draws and reads input and owns no rules.** Shake, particles,
   lighting and damage numbers must be invisible to the determinism hash. A
   view-layer task that moves the hash is a bug, not a new baseline.
3. **Every tunable number is in `src/core/game_data.gd`** with `# LEVER` on it.
4. **Tests ship with the change.** A new rule gets an assert in
   `src/tools/headless_check.gd`; a new input path gets a case in
   `src/tools/input_check.gd`. Same pass, not later.

## Conventions

- Everything is in **English**: identifiers, comments, commit messages and
  player-facing strings. Portuguese is a translation file at task 0097 - never a
  hardcoded string before it.
- Tabs, `snake_case`, `##` doc comments on public functions.
- Art comes from ASCII maps in `tools/gen_sprites.py`, sound from
  `tools/gen_sfx.py`. Do not hand-author PNGs or WAVs.
- Changed something visible? `python tools/shot.py <task-id>` puts the game in
  five known states and photographs them into `implementation/shots/<id>/`.
  **Open the files.** The suite has passed with the wrong tab highlighted and
  with two labels printed on top of each other.
- Do not create a new top-level directory without saying why in the journal.

## Backlog commands

```bash
python tools/task.py next            # what to work on now
python tools/task.py doing 0042
python tools/task.py done 0042
python tools/task.py blocked 0042 "one line of why"
python tools/task.py stats
```

Never tick a checkbox in `implementation/BACKLOG.md` by hand - it is generated
from the `Status:` line in each prompt and will be overwritten.

To change the backlog itself, edit `tools/backlog/part*.py` and run
`python tools/gen_backlog.py`. Existing prompts are not overwritten.

## Sources of truth

- `design.md` - intent, scope, and what is deliberately **not** in the MVP.
- `docs/reference-sheet.png` - the look. Open it on any task that draws
  something.
- `implementation/PROGRESS.md` - what was done, what broke, and every time the
  determinism hash moved and why.
