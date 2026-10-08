# 0135 - The flare goes where you aim it

- **Phase:** 10 - Sleep is the night
- **Status:** done
- **Depends on:** 0131
- **Likely files:** src/core/ability.gd, src/core/player.gd, src/ui/main.gd, src/ui/guardian_cursor.gd, src/ui/world_view.gd, src/ui/night_hud.gd, src/tools/headless_check.gd, src/tools/input_check.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd

## Goal

The flare goes off where the player aims it, not where somebody is standing. It is the night's one power today and the first of the plan's aimed powers.

## Requirements

- A level intent `ability_cell` (`[-1, -1]` is nowhere), written every frame from the cursor like `build_cell`; a new field of `intent`, filled in old saves by reconcile
- `Ability.use` centres on `ability_cell`. Nowhere or off the farm is refused and spends nothing - no cooldown, no `flares` count. 0129's interim house centre goes
- Aiming: while the flare is ready, holding the ability key or arming the FLARE button shows the radius around the cursor (`ABILITY.radius_tiles`, a Chebyshev square, the way `Ability.use` measures it) and the cursor's aim state. The key fires on press at the cursor; the armed button fires on the next confirm; `cancel` disarms. The pad uses the same actions through 0121's bindings
- Final `_task_0054_ability` and `_case_0054_ability`: the flare lands on the aimed cell; rewrite the flare half of 0129's `_task_0129_asleep` (it asserted the interim house centre)
- **Give back what 0129 weakened.** A flare at the house centre reaches little more than the walls, so 0129 relaxed `headless_check`'s `_task_0054_ability` 'and one press measurably changes that' (`turned < lost`) to 'and one press never makes it worse' (`<=`), and `_flare_a_wave` fires when the first walker is within reach + 2 of the house (`_crowd_near(state, house, 2) >= 1`). Aim `_flare_a_wave`'s flare at the crowd (its `ability_cell`), put the strict `<` back, and drop the interim comment. `input_check`'s `_case_0054_ability` victim stands at the rim of the reach south of the house; move it next to the aimed cell
- SIM moves on purpose: `intent` gains `ability_cell`, and every state key is hashed (more if the determinism scenario fires a flare - say which). Record both numbers. DATA does not move

## Done when

- [ ] `_task_0135_aimed_flare` in `headless_v1.gd`: with one zombie by the aimed cell and one by the house, only the first is hit and slowed; a flare at nowhere is refused and keeps its charge
- [ ] `_case_0135_flare_aim` in `input_v1.gd`: moving the cursor and pressing the ability key flares that cell; arming the button and clicking flares the clicked cell
- [ ] A capture of the aiming preview, opened: the square matches what the flare hits
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
