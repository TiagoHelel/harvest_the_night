# 0285 - Music for four seasons

- **Phase:** 16 - Sound, collections and polish
- **Status:** todo
- **Depends on:** 0160, 0282
- **Likely files:** tools/gen_music.py, assets/music/, src/ui/music.gd, src/app/audio.gd, src/ui/main.gd, src/tools/headless_check.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd

## Goal

The two MVP pieces become a year: a day piece per season on the shared motif, a winter night, a boss track and the credits, each crossfading on the moment it belongs to. View only: neither hash moves.

## Requirements

- `tools/gen_music.py` adds day pieces for summer, autumn and winter beside today's `farm`, which becomes spring (keep its id or rename it and every reader in the same pass), a winter night beside `night`, a boss track and the credits. All read `MOTIF` at the one `BPM = 75` - a crossfade between two tempos is a stumble, as the module says - and each season gets its own scale, register and density
- Every looping piece gets the seam the module already builds (`snap()`, `wrapped()` tails) and runs longer than 15 s. The credits play once, as long as 0160's roll; they and the cues (`sting` and 0282's fanfare; 0286 adds its event stingers to the same list later) are named as not-loops rather than excused from the seam check in bulk. `Audio.play_music` loops whatever it plays (`_looping` sets the shared stream's loop mode), so the credits need a play-once road in `src/app/audio.gd`
- `Music.piece_for` stays static and askable and gains what it now needs: the season (0149's calendar) and whether tonight is a boss night (0153). Day plays that season's piece; the build step, the night and the morning report play the night piece (the winter one in winter); a boss night plays the boss track; a menu keeps the spring piece behind `audio/music_in_menus`
- Crossfades use the one length there is (`fade_seconds()`, the transition's): the season turns on the first morning of the new season, the boss track arrives with a boss night's build step and leaves at dawn, the credits take over on 0160's ending screen. Decide whether `layer_for`'s urgent layer plays over the boss track, and say why
- Size: a 96 s piece is about 4.2 MB of WAV in the repository and about 0.85 MB of QOA in the pack, and `tools/release.py` holds the Web pack to `PACK_BUDGET` (3.5 MB gzipped, 2.31 MB at task 0100). Measure before and after, prefer shorter loops for the new pieces, and if the budget must move, move it on purpose with both numbers in the journal. Time matters too: `tools/verify.py` runs `gen_music.py --check`, which renders every piece (about 13 s for today's four) - put its time before and after in the journal
- Rewrite `_task_0086_music` in `headless_check.gd` for the new `piece_for` and the new list: its seam, motif and one-tempo checks cover every looping piece

## Done when

- [ ] `_task_0285_season_music` in `src/tools/headless_v1.gd`: `piece_for` answers right for each season and phase, a boss night, and a menu with the setting off and on; every looping piece's `_loop_seam` ratio is at most 1.0 and its length over 15 s; every arrangement reads `MOTIF`
- [ ] `_case_0285_season_music` in `src/tools/input_v1.gd`: a real run moved to a summer morning is playing the summer piece once the fade is over (`Audio.music_playing()`), and a boss night's build step the boss track
- [ ] The Web pack size before and after (`python tools/release.py`, or why it could not be measured) and `python tools/gen_music.py --report` lengths and seams are in the journal
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
