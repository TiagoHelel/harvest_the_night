# 0281 - The new day's sounds

- **Phase:** 16 - Sound, collections and polish
- **Status:** done
- **Depends on:** 0196
- **Likely files:** tools/gen_sfx.py, assets/sfx/, src/ui/sfx.gd, src/tools/headless_check.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd

## Goal

Going to bed, waking up, the shipping bin, the peddler, the machines and the new ores each make their own noise, so the longer day of 1.0 sounds as varied as it plays. View only: neither hash moves. (The animal calls are 0286's and the dog's bark 0283's - moved there so this fits one invocation.)

## Requirements

- New recipes in `tools/gen_sfx.py`, built from the same `Noise` and primitives (no `random`): bed (under the blanket), wake (a stretch at 06:00), pass-out (a thud at 02:00), the morning payout coins, the peddler's stall bell, and the tool upgrade (an anvil ring when it is ordered, a bright ting when it is delivered next morning)
- And the farm's: one working sound per artisan machine (0187's keg and jar, 0188's dairy, loom and mill) and copper, coal and gold variants of `mine` for 0176's nodes. No animal voices here: 0286 writes the calls heard near the coop and the barn and 0283 the dog's bark for its power
- Furniture and moments: everything played per action keeps the rule `_task_0084_day_sounds` enforces (a peak of at most 0.6 - rendered at `SOFT_PEAK` - under 0.6 s, and quieter and shorter than the bite, so the bite stays the loudest and longest day sound). Bed, wake, pass-out, the morning coins, the stall bell and a delivered tool happen once or twice a day: give them their own list and peak in `gen_sfx.py` (e.g. `MOMENT_SOUNDS`, below `ALARM_PEAK`, joined into `SOUNDS`) and teach that group the named exception rather than loosening its rule
- `Sfx` hears them from the state and `src/core/` never calls `Audio` nor gains a key for a sound: bed and pass-out on the phase leaving DAY with 0127's `House.asleep` and 0128's `house_visit.passed_out`, wake on 0138's morning, the payout as ONE coins sound when 0189's bin is paid at `begin_day` (never one per coin, never the night's reward; `_watch_money` resets outside DAY and swallows that rise, so read the bin emptying), the stall bell when 0190's `STALL_OPENS` and `STALL_CLOSES` pass, at the stall's cell, the anvil when 0173's pending upgrade appears and the ting when it is handed over
- A per-target table in `src/ui/sfx.gd` (e.g. `TARGET_SOUNDS`, occupant id -> sound) consulted before `VERB_SOUNDS` with the cell the action already carries: copper, coal and gold nodes sound like their ore and each machine like itself when a job goes in; a target absent from it falls back to the verb's sound
- Walk `Interact.DAY_ONLY` against `Sfx.VERB_SOUNDS`: every verb 0165-0195 added (0189's `ship` - the bin's lid and drop -, 0185's truffle dig, whatever else the list holds now) was mapped to a borrowed file to keep `_task_0084_day_sounds` green; each gets its own recipe, and two verbs share a file only where the journal says why
- Every new file is reached by the checks: the per-target table goes into the `wanted` list of `_task_0084_day_sounds` (so the furniture rule measures it), the moment list into the `heard` set its 'nothing in the folder is unreached' assert builds but not into the furniture loop - that assert fails on a WAV nothing asks for
- The numbers live in `gen_sfx.py` and `sfx.gd`, not in `game_data.gd` - the `Sfx.GROAN_EVERY_SECONDS` reasoning: a noise changes no rule and must not move the data hash

## Done when

- [ ] `_task_0281_day_sounds` in `src/tools/headless_v1.gd`: every new id is a file, per-action sounds keep the furniture rule, the moment list is named and stays under the alarm, and ore and machine targets resolve to their own sound while an unknown target falls back to the verb's
- [ ] `_case_0281_day_moments` in `src/tools/input_v1.gd`, reading `Audio.last_played()` and `Audio.plays_of()`: going to bed plays the bed sound once, mining a copper node plays the copper variant and not `sfx/mine`, and a morning with items in the bin plays the coins exactly once
- [ ] `_task_0084_day_sounds` and `_task_0085_night_sounds` pass; `python tools/gen_sfx.py --report` lengths and peaks of every new sound are in the journal
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
