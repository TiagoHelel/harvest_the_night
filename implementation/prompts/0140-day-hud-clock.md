# 0140 - The day HUD: the hour and bedtime

- **Phase:** 10 - Sleep is the night
- **Status:** done
- **Depends on:** 0126, 0127, 0128
- **Likely files:** src/ui/day_hud.gd, src/core/game_data.gd, assets/locale/strings.csv, src/tools/shot.gd, src/tools/input_v1.gd

## Goal

The day HUD tells the time and says when it is time for bed: an HH:MM clock, a GO TO BED button that looks like the way into the night, a reminder from 22:00 and a warning before the 02:00 pass-out.

## Requirements

- The HH:MM clock (0126's format) gets its final place and look, tinted from dusk; it reads the `Phases` clock helpers and nothing else
- The GO TO BED button (`NightButton`) is dressed with the UI kit and lights up from the reminder hour
- `BEDTIME_REMINDER_MINUTE := 22 * 60` and `PASS_OUT_WARNING_MINUTE := 25 * 60 + 30` (01:30) as `# LEVER`s with ranges; `validate()`: dusk <= reminder < warning < `DAY_END_MINUTE`. They are view thresholds, not balance, so they stay out of `digest()` and neither hash moves (0112's coverage assert reads only Dictionary and Array tables)
- From 22:00 a quiet 'time for bed' line naming the GO TO BED key (the `night` action through `InputActions.label_of`, so a pad player reads 0121's glyph); from 01:30 a warning in the warn colour with the minutes left before he passes out (`DHUD_BEDTIME`, `DHUD_PASS_OUT_SOON`, both languages, inside `tools/i18n_check.py`'s widths)
- A `bedtime` scenario in `shot.gd` (the farm at 22:30) beside `noon` and `dusk`

## Done when

- [ ] `_case_0140_bedtime` in `input_v1.gd`: no reminder at 21:59, the reminder at 22:00, the warning at 01:30; clicking GO TO BED at 23:00 starts the night
- [ ] `python tools/shot.py 0140 noon dusk bedtime` opened, also with `--pt_BR`
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
