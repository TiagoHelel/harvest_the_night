# 0194 - The day's economy

- **Phase:** 12 - The day that pays
- **Status:** done
- **Depends on:** 0193, 0189, 0171, 0172, 0174, 0177, 0178, 0180, 0182, 0186, 0191
- **Likely files:** src/core/game_data.gd, tools/balance.py, src/tools/autoplay.gd, implementation/BALANCE.md, src/tools/headless_v1.gd

## Goal

The day's money is tuned on purpose: a price for every item, and targets per season so that a good day buys about one new defence (plan section 5's rule of thumb).

## Requirements

- One reviewed price table for every item: `SELL_PRICE`, seed and animal prices, upgrade and building costs; `check_stall` and `check_chain` pass
- Money-per-day targets by season, as `# LEVER`s or a table the check reads: a well-worked day at the start of each season buys about one new defence
- `tools/balance.py` gains sweeps of day strategies - crops, fishing, mining, animals, artisan goods - over a spring and a summer day, headless and outside the suite; it still refuses a dirty tree and restores `game_data.gd`
- A BALANCE.md section with money per strategy per season against the target, and every lever moved
- No single strategy wins every season: the day has several ways to earn, which is what 0196 asks
- DATA moves on purpose (the target table goes into `digest()`); SIM moves if a price or a stock the determinism scenario meets changes - record both

## Done when

- [ ] `_task_0194_economy` in `src/tools/headless_v1.gd`: a computed (not simulated) day of each strategy lands inside its season's target band
- [ ] A `tools/balance.py` run writes the BALANCE.md section, and the journal quotes its numbers
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
