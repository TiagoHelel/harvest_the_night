# 0151 - The night is the calendar day

- **Phase:** 11 - Calendar and seasons
- **Status:** todo
- **Depends on:** 0150
- **Likely files:** src/core/phases.gd, src/core/run.gd, src/core/state.gd, src/core/tech.gd, src/core/endless.gd, src/app/save.gd, src/core/game_data.gd, src/app/playtest.gd, src/tools/nights.gd, tools/nights.py, tools/verify.py, src/tools/headless_check.gd, src/tools/input_check.gd, src/tools/headless_v1.gd, src/tools/autoplay.gd, src/tools/play_nights.gd, src/tools/perf_check.gd, tools/goldens/

## Goal

The meaning change. The night fought at the end of a day is that day's night in the calendar, so difficulty follows the calendar, a lost night is never fought again, and the year has fifty-six of them.

## Requirements

- `Phases.begin_night` sets `night = Calendar.date(state)` instead of `nights_won + 1`; `enter_result` still moves `day` every time and `nights_won` only on a win - a count now, not an index. Fix every reader that means 'the next night is nights_won + 1': `src/app/playtest.gd` (~l.221), the `perf_check.gd` and `play_nights.gd` fixtures, and test fixtures that set `nights_won` to pick a night (`_a_run_at_night`, `_task_0070_endless`'s 'night 25 is playable'), which now set `day`
- `Run.final_night()` becomes `Calendar.year_days()` (update `_task_0150_lookup`'s line that pins it to `Waves.authored_count()`). `Run.is_over` is 'the year's last night has been won', read from a stable fact (`Tech.already_paid(state, Run.final_night())` or equivalent), never from a count of wins, and `go_endless` opens on that same fact (0160 reworks the door). `Tech.total_available()` now counts a year (56 x 4 = 224 at best) and the whole tree costs 45, so `_task_0063_tech_tree`'s 'the tree costs more than the best run earns' fails: give `total_available`/`least_available` an optional night count and keep that assert on the first `Waves.authored_count()` nights, commented that 0220 re-prices the tree against the year
- `State.VERSION` 5 with `Save.migrations()[4]`: `day` is kept and becomes the date (no v4 save ever held a day back); a night in progress keeps its `night` until it ends and the calendar takes over at the next `begin_night`; `nights_paid` keeps its entries unchanged (an old night number is below the date, a date the calendar has left behind, so none can pay twice) and gains nothing - padding it with lost dates would make `already_paid(56)` lie to `Run.is_over`; `endless` becomes false (the year carries the run on; 0160 offers it again) except on an endless save already past `year_days()`, which stays endless so it is not 'over' on load (0291 settles those shapes). Saves can be written in any phase (the pause menu's save and quit): handle all four
- Test the step on a real v4 save: if `tools/goldens/run-v4.sav` does not exist, make it from the MVP commit `bea89a88` in a `git worktree` outside the repository (`--import`, `src/tools/make_goldens.gd` with `GODOT` set, copy back only the v4 goldens, remove the worktree); after the bump write `run-v5*.sav` from this build. Never name a key `moon_phase` (the newer golden's dropped key)
- Delete `MVP_NIGHTS` everywhere (code, tools, tests, `digest()`): after 0150 it is left in `_task_0066`, input_check's `_case_0070_endless`, `autoplay.gd`, `nights.gd`, `play_nights.gd` and `perf_check.gd`. The autoplayer's and `play_nights`' night counts become explicit arguments (default: the first ten calendar nights, so `implementation/BALANCE.md` keeps its meaning)
- Rewrite `_task_0065` (a lost night is not fought again: losing day 3's night leads to night 4 on day 4, and `nights_won` holds), `_task_0066` (not over mid-year, not ended by a loss, over once the year's last night is won - by a fixture on that date, not by playing 56 nights - then carrying on and the profile) and `_case_0070_endless` (the ending offers PLAY ON after a fixture wins date 56, and the next night is 57). The in-suite played run is at most three nights
- The whole-year assertion moves to a tool: `python tools/nights.py --check` resolves every date 1..`year_days()` for seeds 0 and 424242 and exits 1 on an empty record or any `check_nights` error; `tools/verify.py` runs it as a gate (through `check_script()` on `src/tools/nights.gd` with `verify.GODOT` - `tools/nights.py` has its own hard-coded `GODOT` default). If a generated night breaks 0137's night-length rule, fix the generator's pacing (an `ENDLESS` lever, DATA moving on purpose), not the check
- Hashes: SIM moves (the version is in the state) and DATA moves (`MVP_NIGHTS` leaves the digest), both on purpose - both numbers in the journal. The night HUD keeps printing `NIGHT %d`, now the date's number; naming the date there (`SPRING 3`) moved to 0158, whose captures show it

## Done when

- [ ] `_task_0065`, `_task_0066`, `_task_0063_tech_tree` and `_case_0070_endless` rewritten as above and passing; `grep -rn MVP_NIGHTS src` and `grep -n MVP_NIGHTS tools/*.py` find nothing (the prompts in `tools/backlog/` may still name it)
- [ ] `python tools/nights.py --check` passes and prints 56 nights; a deliberately broken record makes it exit 1 (tried, reverted, said so in the journal)
- [ ] `_task_0151_migration` in `src/tools/headless_v1.gd` steps a v4 state in DAY, PREPARATION, NIGHT and RESULT up to v5, brings each to its next night through 0118's road and the sleep intent (never by playing a day out) and asserts the night number, the paid list and that no date pays twice; an endless v4 state past day 56 stays endless and a non-endless one there is not over either; every golden (v1, v4, v5) loads and plays
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
