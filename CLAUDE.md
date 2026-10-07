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
4. **Tests ship with the change.** A new rule gets an assert and a new input
   path gets a case, same pass, not later: in `src/tools/headless_check.gd` /
   `input_check.gd` up to task 0111, and from 0112 on in
   `src/tools/headless_v1.gd` / `input_v1.gd` (made by task 0112).

## Conventions

- Everything in the repository is in **English**: identifiers, comments,
  commit messages and player-facing strings, whose Portuguese lives in
  `assets/locale/strings.csv` (never hardcoded). The owner writes in Brazilian
  Portuguese: answer them in pt-BR.
- Tabs, `snake_case`, `##` doc comments on public functions.
- New art comes from **Codex packs** in `implementation/backlog/` (requests,
  contract, deliveries) promoted through the raster pipeline
  (`assets/art_source/`, `tools/import_art.py`); until a pack is integrated a
  game task draws through the placeholder road (task 0120). Sound comes from
  `tools/gen_sfx.py`, `gen_music.py`, `gen_ambience.py`. Do not hand-author
  PNGs or WAVs.
- Before any Godot run or verify: `export GODOT="C:/Users/Helel/Documents/godot/Godot_v4.7.1-stable_win64_console.exe"`.
  Never run `tools/devlog.py` without `--check`.
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

- `docs/PLANO-DO-JOGO.md` - the approved 1.0 plan (Portuguese): day earns the
  money, the farmer sleeps and the player defends by cursor, 4 seasons x 14
  days. It overrides `design.md` where its section 12 says so.
- `design.md` - the MVP's intent, scope, and what was deliberately **not** in
  the MVP.
- `implementation/backlog/` - the art requests for Codex (`INDEX.md`,
  `ART-CONTRACT.md`, `packs/`) and their deliveries.
- `docs/reference-sheet.png` - the look. Open it on any task that draws
  something.
- `implementation/PROGRESS.md` - what was done, what broke, and every time the
  determinism hash moved and why.
