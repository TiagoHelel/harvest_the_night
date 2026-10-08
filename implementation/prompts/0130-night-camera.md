# 0130 - The night camera

- **Phase:** 10 - Sleep is the night
- **Status:** done
- **Depends on:** 0129, 0121
- **Likely files:** src/ui/main.gd, src/ui/world_view.gd, src/core/game_data.gd, project.godot, src/app/input_actions.gd, assets/locale/strings.csv, src/tools/shot.gd, src/tools/input_v1.gd

## Goal

At night the camera belongs to the player, not to the farmer: it pans over the whole farm with the keys, the screen edge or the right stick, so the guardian can look wherever the horde is.

## Requirements

- From PREPARATION until the day begins, `main.gd` stops calling `follow_player` and the world camera pans: with the move axes (WASD, the arrows, and the left stick 0121 bound to them), with the mouse inside an edge band of the window (only while the window has focus and the pointer is in it), and with the right stick
- The right stick gets actions of its own: `pan_left`, `pan_right`, `pan_up`, `pan_down` in `project.godot` and `InputActions.ACTIONS` (`ACT_GROUP_NIGHT`, `ACT_PAN_*` strings in both languages), rebindable, with the sync and clash checks passing
- Pan speed and edge width are `# LEVER`s in `game_data.gd` - view feel, not balance, so they stay out of `digest()`. Speed is in real seconds whatever 1x/2x/4x is set, and nothing pans while the pause menu is up
- Clamped by `WorldView._camera_bounds`, no zoom. The night opens with the camera on the house; RESULT leaves it where it is; when the day begins it goes back to the farmer
- `shot.gd` gains a camera hook that a night scenario can set (rewrite the comment that says the camera cannot be set); `dusk`, `wave` and `result` use it
- View only: neither hash moves

## Done when

- [ ] `_case_0130_night_camera` in `input_v1.gd`: holding D at night moves the camera right by about speed x time and leaves the farmer where he is; panning past the farm edge stops at the bound; a synthetic right-stick motion pans; after the morning the camera is back on the farmer
- [ ] `python tools/shot.py 0130 wave` opened: the camera is where the scenario put it, not on the porch
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
