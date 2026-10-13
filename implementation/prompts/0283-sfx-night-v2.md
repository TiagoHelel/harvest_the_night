# 0283 - The guardian's sounds

- **Phase:** 16 - Sound, collections and polish
- **Status:** done
- **Depends on:** 0233, 0234
- **Likely files:** tools/gen_sfx.py, assets/sfx/, src/ui/sfx.gd, src/ui/main.gd, src/app/audio.gd, src/tools/headless_check.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd

## Goal

The night is played through the cursor now, so the cursor's work, the START horn, the four powers and the new defences get sounds - heard from where the guardian is looking, not from the farmer asleep in bed. View only: neither hash moves, and no state key is added to be heard.

## Requirements

- The ears: at night `Sfx` calls `listen_at` with the centre of 0130's night camera (`main.gd` owns the `WorldView`; hand it over the way `Music.show_state` gets it), not `_where_the_player_is()` (the sleeping farmer), and `nearest_by_kind` measures from the same point. `Audio` has no getter for its ears today: add one if the checks need it. If 0130 already did this, say so and move on
- The cursor's hand, quieter than the weapons (at most `SOFT_PEAK`) and played at its cell: place (a defence that appears), upgrade (its `level` rising), repair (hp or `house_hp` rising in PREPARATION/NIGHT, not the fill `begin_night` does) and sell. A defence that vanishes leaving rubble (`Farm.rubble_at`) broke and one that leaves none was sold - `_watch_structures` sounds every vanished non-mine as `wall_break` today, and a sale must not; put the decision in a static helper the checks can ask
- The START horn on 0136's PREPARATION -> NIGHT edge: once a night, with no position (`AudioScript.NOWHERE`), on the `DUCKS` list, below `NIGHT_PEAK`
- The powers of 0232/0233 - flare, farm bell, the dog and emergency repair - each heard when its cooldown rises (the reading `_watch_towers` uses for `reload`), at the aimed cell; the bell, which stops every zombie, with no position. The dog's bark and bite are written here (moved from 0281; 0286 leaves the dog out of its animal calls)
- The defences of 0224-0231: a straw rustle when the decoy is hit, the beehive's buzz, the catapult's thunk (and a splat where the pumpkin lands, if the shell is already in the state), the searchlight's hum and the electric fence's zap when it stuns. Buzz and hum are per kind and not per structure - from the nearest stinging hive or lit searchlight, the way groans are - so ten hives are not ten loops
- Replace every borrowed entry 0224-0231 put in `Sfx.TOWER_SOUNDS` to keep `_task_0085_night_sounds` green. That group's rule still holds: `TOWER_SOUNDS` lists exactly the defences with `damage` (their shot), so the rustle, the hum and the zap of defences without it - and the buzz, if it is not the hive's shot - go in a table of their own (e.g. `DEFENCE_SOUNDS`). The house being hit stays the loudest file in `assets/sfx/`, and every new night file stays shorter than the Giant's roar, which that group still asserts is the longest night sound until 0284 rewrites it
- Extend `_night_sound_ids()` in `headless_check.gd` with every new list, because `_task_0084_day_sounds` builds its 'nothing in the folder is unreached' set from it

## Done when

- [ ] `_task_0283_guardian_sounds` in `src/tools/headless_v1.gd`: every new id is a file under `NIGHT_PEAK`, no two damaging defences share a file, every defence without `damage` is out of `TOWER_SOUNDS`, and the sold/broken/spent helper answers right for a crafted sale, a wreck with rubble and a spent mine
- [ ] `_case_0283_guardian_sounds` in `src/tools/input_v1.gd`: in the build step the cursor places, upgrades and sells a defence and `Audio.last_played()` is place, upgrade, sell (never `sfx/wall_break`); START plays the horn; an aimed flare plays the flare; panning the camera away from a firing tower makes it quieter (`Audio.loudness`)
- [ ] `_task_0084_day_sounds` and `_task_0085_night_sounds` pass; `python tools/gen_sfx.py --report` for the new sounds is in the journal
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
