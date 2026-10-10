# 0191 - The house in three tiers

- **Phase:** 12 - The day that pays
- **Status:** done
- **Depends on:** 0148, 0114
- **Likely files:** src/core/phases.gd, src/core/house.gd, src/core/repair.gd, src/core/interact.gd, src/core/game_data.gd, src/ui/house_view.gd, src/ui/world_view.gd, src/ui/sfx.gd, src/ui/placeholder_art.gd, assets/locale/strings.csv, src/tools/shot.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd

## Goal

Money buys a stronger house - tiers I, II and III, each more hit points and cheaper repairs - because the house is what keeps the sleeping farmer safe (plan section 3.8).

## Art

What this task puts on screen will be dressed by Codex art pack(s) A035
(`implementation/backlog/packs/`). Draw it through the placeholder road of
task 0120 until each pack is integrated - or with the pack's art if
`python implementation/backlog/assets.py status <pack>` already says
`integrated`. Never wait for art and never draw or generate PNGs here.

## Requirements

- `HOUSE_TIERS` (`# LEVER`s): a price in money (and materials if wanted), an `hp_bonus` and a repair discount per tier, bought by day; tier I is the house a new game has. `validate()` checks it (bonuses never fall from one tier to the next, the discount within 0-100) and it goes into `digest()`
- The tier is a top-level `house_tier` int: reconcile fills it for old saves (no version bump), but the state hash folds it. `Phases.house_full` adds the tier's HP, so every reader 0114 routed through it follows; the house repair in `Repair` applies the discount and composes with what 0113 decided for 'a full larder' on the house
- **There is no storage limit today** and section 3.8's 'more room to keep things' is not invented here; say so in the journal
- Pick one input path for buying (the house's door, the stall, or a tab in the workshop panel) and test it; the new tier holds from the next night. A new verb goes in `DAY_ONLY` and `all_verbs` with an `Sfx.VERB_SOUNDS` entry (borrow `sfx/trade` until 0281), or `_task_0084_day_sounds` fails. The tier names and the buying row are `strings.csv` rows in both languages, through literal keys
- Same 6x4 footprint and pivot; tiers II and III draw as today's house with a code-drawn mark through the placeholder road until A035 is integrated by 0217
- DATA moves; SIM moves on purpose (the `house_tier` key) - record both

## Done when

- [ ] `_task_0191_house` in `src/tools/headless_v1.gd`: tier II raises `house_full` by its bonus with and without 'stout timbers'; a house repair costs the discounted price; the untouched-house bonus (0114) reads the new full
- [ ] `_case_0191_house` in `src/tools/input_v1.gd`: buy tier II by day
- [ ] A new `house_tiers` scenario: `python tools/shot.py 0191 house_tiers --fhd` shows tiers I to III; opened and looked at
- [ ] the Deliverables table of `implementation/backlog/packs/A035-house-tiers.md` states the final geometry this task settled
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
