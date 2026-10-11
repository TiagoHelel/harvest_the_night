# 0233 - Three new powers

- **Phase:** 13 - Weapons of the night
- **Status:** done
- **Depends on:** 0232, 0185, 0220, 0230
- **Likely files:** src/core/ability.gd, src/core/game_data.gd, src/core/enemies.gd, src/core/repair.gd, src/ui/night_hud.gd, src/ui/names.gd, src/app/input_actions.gd, project.godot, assets/locale/strings.csv, src/tools/headless_v1.gd, src/tools/input_v1.gd

## Goal

Three more buttons for a night going wrong: the farm bell stops every zombie for two seconds, the dog runs out and bites one, and an emergency repair puts a structure back on its feet - each aimed with the cursor, each with its wait (plan section 4.4).

## Art

What this task puts on screen will be dressed by Codex art pack(s) A045
(`implementation/backlog/packs/`). Draw it through the placeholder road of
task 0120 until each pack is integrated - or with the pack's art if
`python implementation/backlog/assets.py status <pack>` already says
`integrated`. Never wait for art and never draw or generate PNGs here.

## Requirements

- Power ids `farm_bell`, `call_dog` and `emergency_repair` (not `dog`, the animal of 0185), every number a LEVER in a `GameData` table beside `ABILITY`, listed in `GameData.digest()` (0112's coverage assert) and checked by `validate()` (a cooldown above zero, a node that gives each power). Their state goes inside `state["ability"]` (`State.TABLES`, so reconcile fills old saves)
- The bell stops every zombie on the farm for 2 s (1-4) through 0230's entity stun counter; decide whether bosses stop, for less or not at all
- The dog bites the enemy nearest the aimed cell within a radius, for a LEVER damage, after a delay worked out from its distance to the house - no RNG; its run and bite are view only
- The repair restores 30% (LEVER 15-50) of the aimed structure's levelled maximum (0113), free, through one `Repair` function that `apply` also uses for the cap; decide whether the house counts. A destroyed structure is rubble and cannot be aimed at
- Own cooldowns (LEVERs), recharged at `begin_night` like the flare. Unlocked by the tree, one per season from summer: three survival rows in `TECH_TREE` with 0220's `season` gate (summer the bell, autumn the dog, winter the repair), each giving its power, priced with 0220's arithmetic (redo it in the journal with the three added); a locked power shows greyed with its node, never hidden
- Aimed with the cursor through 0232's API; an input action per power in `InputActions.ACTIONS` and `project.godot` with pad bindings (0121's sync check) and `ACT_*` strings in both languages, rebindable
- The night dog is 0185's stand-in through the placeholder road until A028 is integrated by 0245; the power icons are placeholders until A045 is integrated by 0244
- `Names.KEYS`/`NOTES` for the new nodes, `POWER_*` names and notes, strings in both languages; the night HUD shows each power's charge or lock
- SIM and DATA move on purpose: record both

## Done when

- [ ] `_task_0233_powers` in `src/tools/headless_v1.gd` asserts the bell holds every walker for exactly its ticks, the dog's bite lands on the enemy nearest the aimed cell after the computed delay, the repair restores the LEVER share of a levelled tower, and each power is refused before its node is bought
- [ ] `_case_0233_powers` in `src/tools/input_v1.gd` aims and fires each power with the mouse and with the pad
- [ ] The Deliverables table of `implementation/backlog/packs/A028-dog.md` states the final geometry this task settled (the night run and bite, the scale against the farmer)
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
