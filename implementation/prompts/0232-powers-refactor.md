# 0232 - Powers as a list

- **Phase:** 13 - Weapons of the night
- **Status:** todo
- **Depends on:** 0196, 0135
- **Likely files:** src/core/ability.gd, src/ui/night_hud.gd, src/ui/main.gd, src/ui/world_view.gd, src/ui/pixel_effects.gd, src/tools/effect_showcase.gd, src/tools/perf_check.gd, src/tools/headless_check.gd, src/tools/input_check.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd

## Goal

Nothing changes for the player. The one flare becomes the first entry of a list of powers, each with its own cooldown and aim cell, so 0233 can add three without a second copy of the cooldown and aiming code.

## Requirements

- `Ability` takes a power id: `ready(state, id)`, `cooldown_left(state, id)`, `charge_percent(state, id)` and `use(state, id, cell)` with the aim cell from 0135's `ability_cell` intent. The flare is the only power and behaves exactly as it does now
- Hashes unchanged is the bar. `state["ability"]` is in `State.TABLES` and folded into SIM, so the flare keeps its keys (`cooldown`, `flare`, `flare_ticks`, `flares`) and no new state key appears until 0233 adds a power; `intent.ability` stays the flare's edge for the same reason; `GameData.ABILITY` stays byte-identical so DATA does not move
- If a key truly has to move, prove play identical (a scripted night with two aimed flares, before and after) and record both numbers in `implementation/PROGRESS.md`
- `Ability.recharge` and `Ability.put_out` work over every power; the `flare_percent` tree bonus stays the flare's
- Every caller moves to the new signatures - today `main.gd`, `night_hud.gd`, `world_view.gd`, `pixel_effects.gd`, `effect_showcase.gd`, `perf_check.gd`, `_task_0054` as 0135 left it and the input cases (grep `Ability.` for whatever 0135-0142 added: the shot scenarios, the autoplayer) - and no flare-only path is left

## Done when

- [ ] `_task_0232_powers_list` in `src/tools/headless_v1.gd` asserts the flare's cooldown, aim and damage through the new API match the numbers before the refactor, and an unknown power id is refused without touching the state
- [ ] `_case_0135_flare_aim` in `src/tools/input_v1.gd` passes with nothing changed but its calls moved to the new API
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
