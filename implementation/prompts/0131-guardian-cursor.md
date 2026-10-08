# 0131 - The guardian's cursor

- **Phase:** 10 - Sleep is the night
- **Status:** done
- **Depends on:** 0130, 0121, 0120
- **Likely files:** src/ui/guardian_cursor.gd (new), src/ui/guardian_view.gd (new), src/ui/main.gd, src/ui/world_view.gd, src/ui/build_mode.gd, src/ui/tooltip.gd, src/ui/describe.gd, src/ui/lighting.gd, src/ui/placeholder_art.gd, src/app/input_actions.gd, project.godot, assets/locale/strings.csv, src/tools/headless_v1.gd, src/tools/input_v1.gd, implementation/backlog/packs/

## Goal

The player's hand at night: a cell cursor that the mouse or the pad drives, that says what is under it, and that every night action points at - held by the porch scarecrow, who wakes up to be the guardian.

## Art

What this task puts on screen will be dressed by Codex art pack(s) A003, A004
(`implementation/backlog/packs/`). Draw it through the placeholder road of
task 0120 until each pack is integrated - or with the pack's art if
`python implementation/backlog/assets.py status <pack>` already says
`integrated`. Never wait for art and never draw or generate PNGs here.

## Requirements

- A cell cursor in PREPARATION and NIGHT only. With the mouse it is the cell under the pointer (`WorldView.screen_to_cell`); with a pad the dpad and the left stick step it one cell per press with a hold-repeat (delay and rate are view levers) and the camera follows it near the edge. The last device used decides, as 0121's glyphs do, so the keyboard keeps panning (0130) while a pad steps
- It writes the levels the rules read - `build_cell` now, `ability_cell` from 0135 - and BuildMode's ghost and its `Pathing.route_if_blocked` preview follow the cursor instead of the raw pointer
- A tooltip of what is under it through `tooltip.gd` and `Describe`: a structure (name, HP against its levelled maximum, level), an enemy (kind, HP) or empty ground, with strings in both languages
- Seven highlight states, all registered now in 0120's placeholder registry so later tasks only switch them on: neutral, can place, blocked, upgrade, sell, repair, aim - a code-drawn outline with a 2-frame pulse until A004 is integrated by 0146. This task uses neutral, can place and blocked
- Any new pad action (a confirm or back for the cursor, if 0121 left `place` and `remove` without a pad button) goes into `project.godot` and `InputActions.ACTIONS` with `ACT_*` strings and is rebindable on the controls page; the clash check passes
- The porch guardian: a view-only prop at a fixed offset from `House.porch`, on a cell nothing can ever be built on (the house's own footprint beside the door is one) - not an occupant and not in the state, so the hash cannot see it. States: day (still), wake (plays at the reality switch), night (idle, the eyes lit as emission points `lighting.gd` reads) and point; placeholder until A003 is integrated by 0145. This task registers all four and plays the first three; 0133 makes it point when a defence goes down
- Settle A003's and A004's geometry from what this task drew: canvas, pivot, frames per state, seconds per frame, emission points
- View only: neither hash moves

## Done when

- [ ] `_case_0131_cursor` in `input_v1.gd`: a synthetic mouse move puts the cursor on that cell; synthetic dpad presses step it one cell each and repeat when held; a placement at the cursor in PREPARATION lands on that cell; there is no cursor by day
- [ ] `_task_0131_guardian` in `headless_v1.gd`: the guardian's cell is never buildable (`Farm.buildable` false) on a new farm
- [ ] The Deliverables tables of `implementation/backlog/packs/A003-guardian.md` and `implementation/backlog/packs/A004-cursor.md` state the final geometry this task settled
- [ ] `python tools/shot.py 0131 dusk wave` and `--fhd` captures opened: the cursor reads over dark ground, the tooltip does not cover the HUD, the guardian stands by the porch with its eyes lit at night
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
