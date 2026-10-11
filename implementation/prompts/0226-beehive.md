# 0226 - The beehive

- **Phase:** 13 - Weapons of the night
- **Status:** done
- **Depends on:** 0218, 0132, 0168
- **Likely files:** src/core/game_data.gd, src/core/towers.gd, src/core/combat.gd, src/core/phases.gd, src/core/building.gd, src/core/state.gd, src/ui/names.gd, src/ui/describe.gd, src/ui/sfx.gd, assets/locale/strings.csv, src/tools/headless_v1.gd

## Goal

Bees sting what comes near and keep stinging, and the hive is as strong as the sunflowers around it - a defence that asks for a field to be planted beside it (plan section 5).

## Art

What this task puts on screen will be dressed by Codex art pack(s) A038
(`implementation/backlog/packs/`). Draw it through the placeholder road of
task 0120 until each pack is integrated - or with the pack's art if
`python implementation/backlog/assets.py status <pack>` already says
`integrated`. Never wait for art and never draw or generate PNGs here.

## Requirements

- Id `beehive`: a `DEFENCES` row with `reload_ticks` (so `Towers` collects it), a short `range`, a cost in wood and sunflowers, `season` summer (0193's field), and a sting - damage over time refreshed, never stacked, the way `Combat.set_alight` works. Either generalise `burning` to carry a damage type (fire must stay fire for 0256's rain; an entry saved without a type reads as fire, so no version bump) or add a sibling RUN_DATA table ticked in sorted id order in `Combat.tick`; decide and say which
- The row has a `damage` (the sting's per-hit number), so `_task_0085_night_sounds` wants a `Sfx.TOWER_SOUNDS` entry: map `beehive` to the nearest generated sound (e.g. `sfx/flame`) until 0283 gives it a buzz
- Strength from sunflowers, worked out once at `Phases.begin_night` and written on the occupant (no `Farm.touch`): growing sunflower plots within N tiles (`Farming.crop_on`, LEVER 2-4) raise the sting; when too few grow - autumn and winter - the hive takes sunflowers from the stock instead (LEVER per hive per night). Decide the curve and write it in the journal; a hive with neither still stings, weakly
- `TOWER_LEVELS` 1-2 for `beehive`. `Building.why_not_upgrade` only checks `TOP_TOWER_LEVEL`, so a family with fewer rows can be upgraded past its last one: refuse that, for every family
- `check_defences` accepts a sting (damage and ticks above zero) and refuses a sting with either at zero; the sunflower radius and per-night stock LEVERs are checked above zero too
- `Names.KEYS` `DEF_BEEHIVE`, a `Describe.defence` line (the sting, the sunflowers), strings in both languages; drawn through the placeholder road (a tinted 32x48 tower per level and state, an 8x8 bee swarm) until A038 is integrated by 0237
- SIM and DATA move on purpose: record both

## Done when

- [ ] `_task_0226_beehive` in `src/tools/headless_v1.gd` asserts the sting refreshes rather than stacks, a hive among growing sunflowers outdoes one without, a hive with stocked sunflowers takes them at `begin_night`, and a two-level family refuses a third upgrade
- [ ] The Deliverables table of `implementation/backlog/packs/A038-beehive.md` states the final geometry this task settled (levels 1-2, the states, the swarm)
- [ ] `python tools/shot.py 0226` captures of a hive at work beside a sunflower bed at night, opened and looked at
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
