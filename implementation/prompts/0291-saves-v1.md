# 0291 - Saves into 1.0

- **Phase:** 17 - Ship 1.0
- **Status:** todo
- **Depends on:** 0151, 0156, 0165, 0279, 0287
- **Likely files:** src/app/save.gd, src/tools/make_goldens.gd, src/tools/play_goldens.gd (new), tools/verify.py, tools/goldens/, src/ui/title_screen.gd, src/tools/shot.gd, src/tools/headless_v1.gd, src/tools/headless_check.gd, assets/locale/strings.csv

## Goal

Somebody who played the 0.1 prototype opens 1.0 and finds their farm in the calendar, or is told plainly where it went - never a crash and never an empty title. This is the last look at every save shape before a stranger's save depends on it.

## Requirements

- An inventory first, in the journal: every `State.VERSION` from 1 to now, the task that bumped it, its step in `Save.migrations()` and its golden in `tools/goldens/`. A version with no step is fixed here. Only the 0.1 shape (State 4) was ever in a player's hands, so the versions in between need their step, not a golden each
- The real 0.1 golden is 0151's `run-v4.sav` (made from the MVP commit `bea89a88`: State 4, BuildInfo 0.1.0). If it is missing, make it the same way: check that commit out in a `git worktree` outside the repository, `--import` it, run `make_goldens.gd` there with `GODOT` set, copy back only the v4 goldens and remove the worktree. A golden that exists is never regenerated
- Two declared shapes beside it, made by `make_goldens.gd` from `run-v4.sav`'s raw payload (no migration, no reconcile - read underneath `Save.read_run_at` the way `headless_check`'s `_payload_of` does), each consistent with itself the way the MVP moved its counters (`day`, `night`, `nights_won`, `nights_paid`, the bosses down), and declared as shapes in the script's header like `run-v1-newer.sav`: `run-v4-endless.sav`, a run carried on past night 10 (`endless` true, `nights_won` 11, in DAY), and `run-v4-finished.sav`, a won MVP run (`nights_won` 10, `endless` false, in RESULT with `last_result.run_over` true)
- A written rule, per shape, migrate or archive, decided by one pure function in `Save` (e.g. `Save.verdict(state)`, asked of the migrated state): a run inside nights 1-10 migrates to its calendar day through 0151's step; the endless and finished shapes migrate only if they land on a day whose night resolves and whose boss bookkeeping (0153's hold at day 14) is consistent, and are archived otherwise. The rule and why go in the journal and in `Save`'s doc comment
- Archiving never deletes, and only the player's run moves: `Save.read_run()` (`RUN_PATH`) moves an archived run to `user://archive/run-v<N>-<k>.sav` (never over a file already there) and reports a new `Save.ARCHIVED` trouble; `read_run_at` gives the same verdict and moves nothing, so a golden in `res://` is never touched. CONTINUE is absent and the title says so once, the `SAVE_ARCHIVED` line on its own rather than under `SAVE_UNREADABLE`/`SAVE_KEPT` (nothing was unreadable), a row with a real width - e.g. 'Your 0.1 run is kept in the archive folder. 1.0 starts a new year.' / 'Sua partida da 0.1 ficou guardada no arquivo. A 1.0 começa um ano novo.'
- The profile is kept: a 0.1 profile (`runs_started`, `runs_won`, `best_night`, `stats`) loads through `Save.read_profile` with its numbers, and every 1.0 key (the fish book of 0182, the collections and achievements of 0287) at its default. 0160 left `best_night` to this task: decide and record whether it still means 'most nights won in one run'. A key whose meaning moved gets a named step in a profile version of its own (e.g. `Save.PROFILE_VERSION` and a `profile_migrations()` table run through `Save.step_up` in `read_profile`; `FORMAT_VERSION` is the file header's, not the profile's), never a silent reread. A `profile-v1.sav` shape goes in `tools/goldens/` (add `Save.read_profile_at`/`write_profile_at` if the pair is missing). The 0.1 `settings.cfg` is 0293's, beside its `Settings.VERSION` bump
- Fix `_task_0104_saves` in `headless_check.gd`: `_goldens()` lists only `run-v*.sav` (the profile golden and any settings fixture are not runs); a shape the rule archives is asserted refused with `Save.ARCHIVED`, not 'loads'; and 'a farm somebody built on' compares against the occupant count of `State.create(seed)` in this build, not the MVP's 106 - since 0156 a fresh farm can pass that number on its own
- A day and a night for every golden is a tool, not the suite (a dozen goldens times a night to dawn is minutes of ticks): `src/tools/play_goldens.gd` loads every run golden the rule migrates, plays 600 day ticks, goes to bed and through 0118's road (START, the night runner to dawn, `confirm_result`), and checks it wakes on the next calendar date in DAY with no enemy left on the farm; `tools/verify.py` runs it as a `goldens` row through `check_script`. The suite keeps load + 600 ticks per golden
- Saves never touch the determinism scenario: SIM and DATA stay where they are

## Done when

- [ ] `_task_0291_saves` in `src/tools/headless_v1.gd`: each 0.1 shape (`run-v4.sav`, `-endless`, `-finished`) gets the rule's verdict; a migrated one lands on the date the rule says and plays 600 ticks; an archived one, copied to `Save.RUN_PATH` and read through `Save.read_run()`, ends byte for byte under `user://archive/`, `Save.can_continue()` is false and the title's `trouble_says()` holds the `SAVE_ARCHIVED` line (the group removes the files it made)
- [ ] the same group: the 0.1 profile golden loads through `Save.read_profile_at` with its numbers (and `best_night` as the journal decided) and every 1.0 key at its default
- [ ] verify prints the `goldens` row passing: every migrated golden woke on its next date in DAY with no enemy on the farm - the dates and the row's time in the journal
- [ ] the title with the archive line captured at 1920x1080 in both languages (`python tools/shot.py 0291 --title --fhd` and `--title --fhd --pt_BR`, staging an archived run in `shot.gd` the way the crash dialogue is staged, and putting back any real `user://run.sav` afterwards) and opened: the line fits and sits clear of the menu
- [ ] `python tools/verify.py` prints PASS
- [ ] the determinism hash is unchanged, or the change is deliberate and both
      the old and the new number are in the journal

## House rules

`src/core/` holds the game rules: node-free, deterministic, advanced only by
`Sim.tick()` at a fixed rate. No nodes, no unseeded randomness, no clock reads,
no iterating an unordered Dictionary without sorting the keys first. `src/ui/`
draws and reads input and owns no rules.

Every number a designer might want to turn lives in `src/core/game_data.gd`
with `# LEVER` on it. A new rule ships with an assert and a new input path with
a case, in the same pass - from task 0112 on in `src/tools/headless_v1.gd` and
`src/tools/input_v1.gd` once 0112 has made them (the older suites are full).

Code, identifiers, comments and player-facing strings are in English; every
new string is a row in `assets/locale/strings.csv` with its pt_BR text. Art
comes only from the Codex packs in `implementation/backlog/` through the raster
pipeline (`assets/art_source/`, `tools/import_art.py`): never hand-paint or
generate PNGs in a game task.

`docs/PLANO-DO-JOGO.md` is the source of truth for intent in 1.0 (its section
12 says what it changes in `design.md`); `docs/reference-sheet.png` and the
approved 32px farmer are the look. If this task contradicts either, follow the
task and say so in the journal.
