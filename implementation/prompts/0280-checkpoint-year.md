# 0280 - Checkpoint: do fifty-six nights tire?

- **Phase:** 15 - Fifty-six nights and balance
- **Status:** done
- **Depends on:** 0277, 0278, 0279, 0159, 0258
- **Likely files:** implementation/PROGRESS.md, implementation/shots/0280/, src/tools/shot.gd, src/tools/nights.gd, implementation/prompts/ (later prompts, if the answer needs it), tools/backlog/ (new tasks, if any)

## Goal

The plan's Phase 6 question, answered honestly: 'as 56 noites cansam?' A checkpoint like 0027, 0066 and 0148, not a feature - a 'yes' found here is worth more than every polish task after it.

## Requirements

- Play, not only measure: the year autoplayer for all four policies, `python tools/nights.py` for the year, and at least one night of each season and each boss night driven through the real game with the cursor, by mouse and by pad (a real pad if one is attached; say honestly if it was synthetic), and looked at
- Captures at 1920x1080 (`python tools/shot.py 0280 <scenarios> --fhd`): each season by day and at night mid-wave, a Full Moon, a fog or rain night, a Blood Moon, and the four bosses mid-fight. Reuse what exists - 0159's `season_*`, 0258's `fog`, `rain`, `blood_moon` and `full_moon`, 0246's `boss` and the boss scenarios of 0253-0255 - and add to `src/tools/shot.gd` only what is missing (a tool change, hashes untouched)
- Look for sameness with numbers, computed by a tool rather than by eye (a `--sameness` report in `src/tools/nights.gd`): per season, how many nights share a mix of kinds and sides; the longest run of nights that bring nothing new (no new enemy, side, weapon, event or boss); how often the forecast says the same thing two nights running
- Answer in the journal: do the fifty-six nights tire, where and why, with the stretches named by day - then what would fix it (more events, fewer generated nights, new key nights, shorter seasons) and what each fix costs
- Fixes that fit go into the later prompts (P16-P17), or into new tasks in `tools/backlog/part*.py` run through `python tools/gen_backlog.py` - each with a free id and added to 0295's deps, so the playtest waits for it; anything that changes an owner decision (14 days a season, Normal only) is a recommendation to the owner in the journal, not an edit made here
- If the honest answer is that the year tires and the cure is bigger than prompt edits, mark this task blocked with the reason (`python tools/task.py blocked 0280 "<why>"`), so 0295 (the playtest of the year) waits for the owner
- No rule changes here: nothing in `src/core/` moves, and neither hash moves

## Done when

- [ ] `implementation/shots/0280/` holds the FHD captures listed above, every one opened and looked at; the journal names what is wrong in any of them
- [ ] The journal has the year's autoplayer table, the sameness numbers and the longest stretch with nothing new, by day
- [ ] The journal answers 'do the fifty-six nights tire?' in plain words and lists every prompt edited and every task added because of it
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
