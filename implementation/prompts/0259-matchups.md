# 0259 - Every weapon has its night

- **Phase:** 14 - Enemies and bosses
- **Status:** todo
- **Depends on:** 0234, 0247, 0248, 0249, 0250, 0251, 0252, 0253, 0254, 0255, 0256, 0257
- **Likely files:** src/tools/matchups.gd, tools/matchups.py, implementation/MATCHUPS.md

## Goal

The plan's test for phases 4 and 5 turned into numbers: every weapon is the best buy somewhere, and every enemy needs a different answer. The report is what the night authors of 0270-0274 build the year from.

## Requirements

- A headless tool, not a suite group: `src/tools/matchups.gd` run by `tools/matchups.py`, seeded and deterministic, printing its run time, with `--only=<enemy>` for quick reruns; it stays out of `verify.py` (the 120 s per-suite timeout). Keep a full run to about ten minutes by shortening the lane's fight, not by dropping rows of the grid
- The arena: one fixed lane on the real farm map with a fixed base defence; for every `GameData.DEFENCES` entry (the plan's fourteen plus 0225's bait and 0231's sandbags - print the count), the same budget (0234's money plus materials, materials at `SELL_PRICE`) spent on it at the level its season allows, placed by a fixed rule; a fixed group of one enemy kind, and each boss with its season's escort
- Per pair: house damage, kills, ticks to clear and structures lost; the score is house damage prevented per unit of cost against the base alone
- The same grid under fog, rain and the Blood Moon, so the searchlight, fire and the mines get their nights
- Prove: every defence is the top buy against at least one enemy, boss or event (a barrier or a support piece - decoy, garlic, searchlight - may be scored as the best addition to the base line rather than alone; say how); no defence is top against every enemy; every new enemy's top answer differs from the walker's. Where a claim fails, a lever may move here (at most a few, DATA recorded) or the failure goes to 0277 with its numbers
- `implementation/MATCHUPS.md`: the table, each enemy's top three answers, each defence's best night, and a line per enemy for the night authors (e.g. 'rats: mines, flamethrower')

## Done when

- [ ] `python tools/matchups.py` exits 0 and names, for every `DEFENCES` entry, the enemy or event where it is the best buy, or marks it UNPROVEN with its numbers; every UNPROVEN line is in the journal as handed to 0277
- [ ] Two runs write the same `implementation/MATCHUPS.md` byte for byte
- [ ] The journal answers in one paragraph, with the numbers, whether each enemy asks for a different answer, and lists any lever moved
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
