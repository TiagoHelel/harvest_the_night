# 0282 - The sounds of the fishing minigame

- **Phase:** 16 - Sound, collections and polish
- **Status:** done
- **Depends on:** 0180, 0182, 0196
- **Likely files:** tools/gen_sfx.py, tools/gen_music.py, assets/sfx/, assets/music/, src/ui/sfx.gd, src/tools/headless_check.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd

## Goal

The minigame of 0180 can be played by ear as well as by eye: a tick from the bar, a hit, a miss, the catch, and a fanfare when one of 0182's legendaries comes out of the water. View only: neither hash moves, and no state key is added to be heard.

## Requirements

- Recipes in `tools/gen_sfx.py` for tick, hit, miss and catch. All four are furniture (at most `SOFT_PEAK`, shorter than the bite), so `_task_0084_day_sounds` still finds the bite the loudest and longest day sound: the bite opens the window, these only follow it
- The tick marks the marker turning at an end of the bar or entering the zone (pick one and say why), never every frame
- `Sfx` reads hit, miss and catch off 0180's minigame state the way `_watch_fishing` reads `Fishing.is_biting`: a hit or a miss is the edge the press intent left in the state, the catch is the cast ending with a species landed. An assisted hit (0180's option) sounds like any other hit
- The legendary fanfare is music, not furniture: a short cue in `tools/gen_music.py` beside `sting` (Music bus, at most `STING_PEAK`, a `PIECES` entry so `--check` knows it) built on `MOTIF`, so the year's tune answers the catch. `Sfx` asks `Audio.play` for it when the species landed is one of 0182's legendaries, and the ordinary catch is skipped then
- Decide what becomes of `sfx/reel` (the MVP's one-press reel): kept as the line coming in under the minigame, or retired with its recipe and its `VERB_SOUNDS` entry - never left as a file nothing plays. `reel` is in `Interact.DAY_ONLY` today and `_task_0084_day_sounds` wants a sound for every verb there, so retire it only if 0180 took the verb out of that list
- Extend what `_task_0084_day_sounds` collects so every new file in `assets/sfx/` is reached; `python tools/gen_sfx.py --check` and `python tools/gen_music.py --check` are clean

## Done when

- [ ] `_task_0282_fishing_sounds` in `src/tools/headless_v1.gd`: the four files exist and keep the furniture rule against the bite; the fanfare is in `assets/music/`, under five seconds and at most `STING_PEAK`, and its recipe reads `MOTIF`
- [ ] `_case_0282_fishing_sounds` in `src/tools/input_v1.gd`: a minigame driven through intents plays the hit for a press in the zone, the miss for one outside it and the catch on landing; a crafted legendary bite landed plays the fanfare and not the catch (`Audio.last_played()`)
- [ ] `gen_sfx.py --report` and `gen_music.py --report` numbers for the new sounds are in the journal
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
