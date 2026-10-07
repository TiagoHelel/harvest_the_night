# 0129 - He stays in bed all night

- **Phase:** 10 - Sleep is the night
- **Status:** todo
- **Depends on:** 0127, 0120, 0128
- **Likely files:** src/core/player.gd, src/core/ability.gd, src/core/building.gd, src/ui/main.gd, src/ui/night_hud.gd, src/ui/player_view.gd, src/ui/house_view.gd, src/ui/world_view.gd, src/ui/placeholder_art.gd, src/tools/headless_check.gd, src/tools/input_check.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd

## Goal

Nobody walks at night. The farmer is in bed from the moment he sleeps until the morning, and the two things the night used him for - the flare and the repair - keep working without him until the cursor takes them over.

## Art

What this task puts on screen will be dressed by Codex art pack(s) A001, A002
(`implementation/backlog/packs/`). Draw it through the placeholder road of
task 0120 until each pack is integrated - or with the pack's art if
`python implementation/backlog/assets.py status <pack>` already says
`integrated`. Never wait for art and never draw or generate PNGs here.

## Requirements

- `Player.tick` returns at once while `House.asleep` (consuming the `interact` and `cancel` edges): no movement, no verbs, no turn in PREPARATION or NIGHT. `main.gd` writes `intent.move = [0, 0]` and no highlight outside DAY, which frees the move axes for 0130's camera
- Interim flare until 0135: `Ability.use` centres on `Farm.house_centre(state)` instead of `Player.cell`; `_task_0054_ability`'s and `_case_0054_ability`'s (~3140, 'recorded where the player is standing') 'goes off at the player' becomes the house, for now
- Interim repair until 0134: a new edge intent `repair_cell` (`[-1, -1]` when idle; a new field of `intent`, which is in TABLES, so reconcile fills it) is consumed in `Building.tick` in PREPARATION and NIGHT and calls `Repair.apply_all` on that cell; the night HUD's REPAIR button writes the house's cell and is enabled while `Repair.can_mend` allows it. No new `X.tick` in `sim.gd`, so `PerfNames` is untouched
- Rewrite `_task_0022_reality`'s 'the player walks his defences at night' as 'he stays in bed all night' (600 ticks of move and interact change nothing about him)
- Every test that has the farmer walk or use a verb in PREPARATION or NIGHT now fails - a scratch run of both suites lists them. Known ones: `_task_0053_repair` and `_case_0053_repair` mend a wall at night with the held key (move those night mends onto `repair_cell`; 0134 then takes the defences' day verb away), and `_case_0056_night_hud`'s REPAIR block (~3395-3420, 'facing a broken wall') now mends a damaged house
- View: at night the farm shows nobody on the porch; the farmhouse windows stay lit (`lighting.gd` lights them already) and a Zzz drifts up from the house - a view cue, not a `Reactions` kind, so the hash never sees it
- Register the four A001 animations in 0120's placeholder registry under the names the pack will deliver - get into bed, the sleep loop, wake and stretch, pass out on the farm - with stand-ins (the idle frame turned or tinted is enough), and the Zzz for A002. The switch opens with a short interior beat of him getting into bed and asleep (view only: the rules are already in PREPARATION), the pass-out plays where he fell, and 0138 plays the wake
- SIM moves on purpose: `intent` gains `repair_cell`, and every state key is hashed (and more if the determinism scenario walks or flares at night - say which). Record both numbers. DATA does not move

## Done when

- [ ] `_task_0129_asleep` in `headless_v1.gd`: in PREPARATION and in NIGHT, 600 ticks of move and interact leave his position, facing and action unchanged; a flare lands on the house centre; `repair_cell` on a damaged house mends it, charges what `Repair.cost_at` says, and changes nothing when the ledger cannot pay
- [ ] `_case_0129_asleep` in `input_v1.gd`: holding D at night does not move `Player.position`; clicking `RepairButton` mends a damaged house
- [ ] `python tools/shot.py 0129 dusk wave` and `python tools/shot.py 0129 --switch` opened: the bed beat, nobody on the porch at night, the windows lit, the Zzz visible
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
