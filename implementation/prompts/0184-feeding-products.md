# 0184 - Feeding, eggs and milk

- **Phase:** 12 - The day that pays
- **Status:** done
- **Depends on:** 0183, 0168
- **Likely files:** src/core/livestock.gd, src/core/farming.gd, src/core/phases.gd, src/core/game_data.gd, src/ui/names.gd, src/ui/placeholder_art.gd, assets/locale/strings.csv, src/tools/headless_check.gd, src/tools/input_check.gd, src/tools/headless_v1.gd

## Goal

Animals are fed and give what they are kept for: chickens lay eggs, cows give milk, and both eat hay made from the wheat's straw - one more use for wheat.

## Art

What this task puts on screen will be dressed by Codex art pack(s) A029
(`implementation/backlog/packs/`). Draw it through the placeholder road of
task 0120 until each pack is integrated - or with the pack's art if
`python implementation/backlog/assets.py status <pack>` already says
`integrated`. Never wait for art and never draw or generate PNGs here.

## Requirements

- Harvesting wheat also gives `STRAW` (`# LEVER` per harvest); a recipe at a station you choose turns straw into `HAY`, the feed (both exist: the plan makes hay from straw, and straw is also 0224's decoy material). The peddler's hay outside autumn is 0193's
- A daily feed debit at `Phases.begin_day`: each housed animal eats `feed_per_day` hay (`# LEVER`); one not fed gives nothing that day, and never dies or sickens. Decide and assert what day 1 (no `begin_day` before it) and the map's loose animals (no coop or barn yet) count as - 'unfed' would silence `_task_0034_cooking`, `_case_0034_livestock`, `_task_0038_idle` ('the animals produced', `_a_busy_day`) and the determinism scenario's animals; rewrite in place what the decision and the new products break
- Products: chickens give `EGG`, cows give `MILK` (`LIVESTOCK.produces`, the rate and `holds` as `# LEVER`s)
- Decide what happens to `MEAT` and write it in the journal: keep the resource and `cook_roast`, and say how meat is still had (the stall stocks it, an animal gives it now and then...). `check_livestock`'s 'nothing produces meat' rule follows the decision. A saved animal's waiting produce is a count and comes out as the new product: say so (no version bump)
- `STRAW`, `HAY`, `EGG` and `MILK` with prices, groups, names and strings in both languages, and a `Names.KEYS` entry with a `REC_*` row for each new recipe; recipes that took meat adjusted so `check_chain` passes
- Icons through the placeholder road until A029 (0211) and, for hay and straw, A020 (0203) are integrated
- SIM moves (four new resources in `held`/`gained`, and the scenario's animals produce differently); DATA moves

## Done when

- [ ] `_task_0184_feed` in `src/tools/headless_v1.gd` (mornings by `Phases.begin_day`, produce by advancing `every_ticks`, never a whole day of ticks): a fed coop gives eggs the next day, an unfed one gives none and every chicken is still there; a wheat harvest gives the straw the lever says
- [ ] The journal states the meat decision and `check_livestock` enforces it (a rigged table without a meat source fails)
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
