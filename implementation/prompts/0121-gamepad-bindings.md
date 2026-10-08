# 0121 - A controller for every action

- **Phase:** 9 - v1.0 groundwork
- **Status:** done
- **Depends on:** 0112
- **Likely files:** project.godot, src/app/input_actions.gd, src/ui/main.gd, src/ui/options_controls.gd, src/ui/pause_menu.gd, src/ui/title_screen.gd, src/ui/studio_intro.gd, assets/locale/strings.csv, src/tools/input_v1.gd, src/tools/headless_v1.gd

## Goal

The plan promises a night played on a controller, and `project.godot` has not one joypad binding: only the pause menu, the title and the ident read raw pad buttons. Bind every action now, before phase 10's cursor and hotbar are built on top of them.

## Requirements

- A pad event for every action in `InputActions.ACTIONS`, in `project.godot`: `move_*` on the left stick and the d-pad; face, shoulder, trigger and Start/Back buttons for run, interact, cancel, build, place/remove/upgrade, inventory, night (0127's GO TO BED), ability, speed, skip_night, pause, tech, stats, log. Where there are more actions than buttons (the six seed slots), decide, write the layout in the journal and name any action left without a pad event on purpose in the assert below, with its reason
- Analog walking: `main.gd` writes `intent.move` as `int(Input.get_axis(...))`, which truncates a half-tilted stick to 0. Turn the stick into -1/0/1 through the action's deadzone, so a stick walks exactly like a key
- `InputActions.label_of` names pad buttons and axes from the strings table: new `ACT_PAD_*` rows (A, B, X, Y, LB, RB, LT, RT, Start, Back, d-pad and stick directions) in en and pt_BR. Hints and the controls screen show the pad's name when the last input came from a pad - a view-only flag in `InputActions`
- Rebinding keeps the devices apart: today `apply()` replaces all of an action's events with the one saved, so a rebound key would drop the pad button. Save one binding per device kind (`as_text`/`from_text` learn `joy:<button>` and `axis:<axis>:<sign>`, `is_bindable` accepts pad events), read old single `key:`/`mouse:` values as keyboard ones, and apply the clash rule within a device kind
- `pause_menu.gd`, `title_screen.gd` and `studio_intro.gd` read actions rather than raw `JOY_BUTTON_*`; menus and panels move focus on the d-pad/stick and accept/cancel on the face buttons through the `ui_*` actions
- Keep `_task_0095_controls`' sync check (project.godot `[input]` against `ACTIONS`) passing. Tutorial lines that name a key in their text (`TUT_CHOP`, `TUT_BUILD`, `TUT_NIGHT`) are 0141's and 0195's; a deadzone option is 0292's
- Cases go in `input_v1` with synthetic events (`Input.parse_input_event` with `InputEventJoypadButton` and `InputEventJoypadMotion`). Input and view only: neither hash moves (a stick walks exactly like a key, so the intents a keyboard writes are unchanged)

## Done when

- [ ] `_case_0121_pad` in `input_v1`: synthetic pad events walk the farmer on the stick and on the d-pad, chop a tree, open and leave build mode, press the night button and open and close the pause menu - each asserted through the state or the scene
- [ ] Rebinding interact to another key keeps its pad button, and rebinding its pad button keeps the key - asserted, then reset
- [ ] `_task_0121_pad` in `headless_v1`: every action in `ACTIONS` has a joypad event in `project.godot` except the ones the assert names with a reason, every `ACT_PAD_*` key `label_of` can return is in the strings table, and no code line in `src/ui/` names a `JOY_` constant
- [ ] `python tools/i18n_check.py` passes; `python tools/shot.py 0121 options_controls` opened: the pad labels fit
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
