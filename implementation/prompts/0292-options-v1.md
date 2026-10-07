# 0292 - Options for the new controls

- **Phase:** 17 - Ship 1.0
- **Status:** todo
- **Depends on:** 0131, 0180, 0158
- **Likely files:** src/app/settings.gd, src/app/input_actions.gd, src/ui/options_controls.gd, src/ui/options_game.gd, src/ui/guardian_cursor.gd, src/ui/main.gd, src/ui/world_view.gd, src/ui/forecast_panel.gd, src/ui/day_hud.gd, assets/locale/strings.csv, src/tools/input_v1.gd, src/tools/headless_v1.gd

## Goal

The guardian's cursor, the night camera and the fishing bar each get the knob a player reaches for: how fast the cursor moves, whether the screen edge pans, how far a stick must tilt, a kinder fishing bar, and a forecast that stays up all day.

## Requirements

- Five keys in `Settings.DEFAULTS` (`src/app/settings.gd`), each in its page's `resets` and with a row: `controls/cursor_speed` (percent of the repeat rate 0131 shipped, steps 50/75/100/150/200), `controls/edge_pan` (on), `controls/pad_deadzone` (0.10-0.50 in 0.05 steps, default what 0121 shipped - `project.godot` has 0.2 on the move actions today), `gameplay/fishing_assist` and `gameplay/forecast_all_day` (both off). A key 0130, 0131 or 0180 already made is reused, never doubled
- Cursor speed, edge pan and deadzone are input preferences, not rules: 0131's hold-repeat in `guardian_cursor.gd` scales its rate by cursor speed, 0130's edge-band pan in `main.gd`/`world_view.gd` runs only with edge pan on, and `InputActions` applies the deadzone with `InputMap.action_set_deadzone` to the move, pan and cursor actions (0121, 0130, 0131). Their step lists sit with their rows on the options pages, the way `OptionsA11y.ROWS` and `Video.FPS_CAPS` keep theirs - preferences, not balance, so not in `game_data.gd`, and neither hash moves for them
- Fishing assist: 0180 shipped it as a rule - a run flag written through an intent from its Settings key, the zone wider and the marker slower, never read by core from `Settings` - and left only the row. Reuse 0180's key (rename nothing) and its levers. If 0180 left a gap (core reading `Settings`, a strength with no `# LEVER` in `GameData.FISHING`, a view-side widening that changes catches), fix it here and say so: a new lever moves DATA and a rule fix moves SIM, on purpose, both numbers in the journal; otherwise neither hash moves
- Forecast all day is view only: 0158's panel (`src/ui/forecast_panel.gd`, shown by `day_hud.gd`) shows from 06:00 instead of 18:00 and still hides once START is pressed. The forecast is a pure function of (seed, date), so seeing it at breakfast can never change the night
- Rows where a player looks for them: cursor speed, edge pan and deadzone under a heading on the controls page (`OptionsControls`), fishing assist and the forecast on the game page (`OptionsGame`). Both pages still work by keyboard, mouse and pad, and RESET puts the new keys back
- Applied live and kept: a change made with a night up behind the options moves the cursor and the camera at once, the way `SimDriver` hears `gameplay/night_speed` through `Settings.changed`, and every value survives a restart through `settings.cfg`. New keys alone need no `Settings.VERSION` bump
- Strings in `assets/locale/strings.csv` with real widths, under each page's prefix (`CTL_CURSOR_SPEED`, `CTL_EDGE_PAN`, `CTL_DEADZONE`, a `CTL_*` heading, `GAME_FISHING_ASSIST`, `GAME_FORECAST_ALL_DAY`), toggles reusing `OPT_ON`/`OPT_OFF`: e.g. CURSOR SPEED / VELOCIDADE DO CURSOR, EDGE PAN / ROLAR PELA BORDA, STICK DEADZONE / ZONA MORTA DO ANALÓGICO, FISHING ASSIST / PESCA ASSISTIDA, FORECAST ALL DAY / PREVISÃO O DIA TODO

## Done when

- [ ] `_case_0292_options` in `src/tools/input_v1.gd` steps each new row by keyboard and by pad, finds the value in `Settings` and in a reloaded `settings.cfg`, and RESET puts it back
- [ ] the same case at night: with edge pan on, a pointer held in 0130's edge band for a second moves the camera, and with it off it does not (a synthetic mouse motion into the band, or the edge-pan helper 0130's pan reads if the headless window cannot hold focus); a stick tilt under the deadzone moves no cursor and one over it does; a held d-pad at 200 crosses about twice the cells it crosses at 100
- [ ] the same case by day: with forecast all day on, the panel is up at 08:00, and with it off it is hidden at noon as `_case_0158_panel` expects; with fishing assist on, the next cast carries 0180's assist flag, and with it off it does not
- [ ] `_task_0292_options` in `src/tools/headless_v1.gd`: no file in `src/core/` names `Settings`; `Forecast.tonight` gives the same record at 08:00 as at 18:00
- [ ] the controls and game pages captured at 1920x1080 in both languages (`$GODOT --path . --position -4000,-4000 --script res://src/tools/capture_menus.gd -- --out=res://implementation/shots/0292/`, then again with `--pt_BR`) and opened: no label runs off its row and no two rows overlap
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
