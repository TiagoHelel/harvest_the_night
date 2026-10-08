# 0150 - Nights looked up by the calendar

- **Phase:** 11 - Calendar and seasons
- **Status:** done
- **Depends on:** 0149
- **Likely files:** src/core/waves.gd, src/core/endless.gd, src/core/run.gd, src/core/tech.gd, src/core/rewards.gd, src/core/game_data.gd, src/tools/headless_check.gd, src/tools/headless_v1.gd

## Goal

Before the night number changes meaning, every question about which night is which goes through one lookup, and nothing in the rules asks `MVP_NIGHTS` any more. A port: the same ten nights, the same Endless past them, the same hashes.

## Requirements

- Split the lookup in two in `src/core/waves.gd`: `Waves.plain_night(night, seed)` is the record as written - the authored row for days `1..Waves.authored_count()` (today's ten, `NIGHTS.size()`), `Endless.night(seed, day)` after them, defined for every day of every year - and `Waves.night_of(night, seed)` is the record the night actually fights: `plain_night` plus the calendar's rules. There are none yet; 0152-0154 add theirs there and nowhere else. With no rule, `night_of` hands back the authored row itself, not a copy
- Every pure question keeps going through `night_of` (`table`, `size_of`, `kinds_of`, `spawns_of`, `reward_of`, `summary_of`, `delay_before`, `tonight`); tests of the authored curve and of the endless curve (`_task_0059`, `_task_0060`, and `_task_0070`'s 'it grows', 'deals out every body it promised' and 'both sides') read `plain_night`, so the Full Moon, boss and calm rules of 0152-0154 do not fight them. No new record format: 0270 owns that
- Core readers of `MVP_NIGHTS` ask a named question instead: `Endless.is_generated`, `step_of` and `_size` use `Waves.authored_count()`, and `_size`'s base is the last authored night's plain size (through `plain_night`, not `Waves.size_of`), so a calendar rule on that date never moves the whole curve; `Run.is_over`, `is_final_night` and `go_endless` use a new `Run.final_night()` (the last authored night in this task; 0151 makes it the year's last day, 0160 the winter boss); `Tech.total_available()` and `least_available()` count `Run.final_night()` nights
- `Rewards._lines` and `_money_from` scale with `state["night"]`, which becomes the calendar day in 0151: read it through one helper (e.g. `Rewards.night_step(state)`) so 0219 and 0278 retune a 56-night year in one place; nights 1-10 pay exactly what they pay today
- `check_nights`' `nights.size() != MVP_NIGHTS` rule becomes: at least one authored night and no more than `Calendar.year_days()`
- The other test reads of `MVP_NIGHTS` that only mean 'the authored nights' become `Waves.authored_count()` as a plain rename: `_task_0003_game_data` ('ten nights'), `_a_full_farm` (for `_task_0038_idle`), `_task_0058_giant` and `_task_0068_balance`. `MVP_NIGHTS` then survives only for `_task_0066_run_end` and input_check's `_case_0070_endless` (both about the run's end, which 0151 changes), the tools (`autoplay.gd`, `nights.gd`, `play_nights.gd`, `perf_check.gd`) and its line in `digest()`; its comment says 0151 deletes it
- Rewrite `_task_0059`, `_task_0060`, `_task_0061`, `_task_0062` and `_task_0070` in `src/tools/headless_check.gd` over the lookup and the named questions: `_ten_of` becomes one copy per authored night, 'the Giant on night ten' becomes 'on the last authored night', the endless asserts compare `plain_night` with `Endless.night` and read 'past the authored nights'. Keep what each asserted and its run time
- Hashes: SIM and DATA both stay where they are. If either moves, find out why before going on

## Done when

- [ ] `grep -rn MVP_NIGHTS src/core` finds only its declaration and the `digest()` line
- [ ] The five rewritten groups pass, and the journal has one line per group on what changed in it
- [ ] `python tools/nights.py 20` prints the same twenty lines as before the change (diff the two outputs; the result goes in the journal)
- [ ] `_task_0150_lookup` in `src/tools/headless_v1.gd`: every day 1-112 resolves to a non-empty record for seeds 0 and 424242; `night_of(1)` is the same object as `GameData.NIGHTS[0]` (`is_same`); `Tech.least_available()` is `tech_points` x `Run.final_night()`, and `Run.final_night()` equals `Waves.authored_count()` - the one line 0151 changes to `Calendar.year_days()`
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
