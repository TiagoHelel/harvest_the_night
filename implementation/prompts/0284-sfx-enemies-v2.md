# 0284 - The new enemies and bosses, heard

- **Phase:** 16 - Sound, collections and polish
- **Status:** todo
- **Depends on:** 0247, 0248, 0250, 0252, 0253, 0254, 0255, 0257
- **Likely files:** tools/gen_sfx.py, assets/sfx/, src/ui/sfx.gd, src/tools/headless_check.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd

## Goal

Six new enemies and three new bosses each get a voice of their own, so a night heard with your eyes shut still says what is coming. View only: neither hash moves, and no state key is added to be heard. (The night events' stingers moved to 0286, beside the event beds, so this fits one invocation.)

## Requirements

- Recipes for the spitter (the spit, and a splat on the tower 0247's projectile hits), the rat swarm (a squeak), the crow (a caw over wingbeats), the digger (a burrowing rumble and a burst when it surfaces), the frost zombie (a shatter as it dies and a crackle on the towers it chills) and the wraith (a whisper)
- Voices stay per kind and not per body: `nearest_by_kind` keeps a swarm of fifty rats to one voice (0085's promise). Deaths that differ by kind go through a small per-kind table that falls back to `DEATH_SOUND` and keeps `DEATH_GAP`
- The wraith cannot be shot outside light (0252): decide whether its whisper plays with no position (you know they are out, not where) or only from wraiths in light, and write why in the journal
- Three boss voices - the Harvester's engine, the Scarecrow King's call, the Winter Lord's ice - and their specials: the Harvester's charge telegraph and the crunch of the walls it crushes, the King summoning crows, the Winter Lord's freezing aura; each special heard on the edge its telegraph or effect already sets in the state (`is_winding`, 0253's `charge_line`, 0251's `Towers.chill_left`, 0255's `frozen` countdown), read like `reload`
- Every boss is announced like the Giant: on arrival, with no position, ducking the ambience. Wherever `sfx.gd` still tests `kind == &"giant"` (`_watch_bodies`, `nearest_by_kind`, `_ducks`), read `is_boss` instead, unless 0246 already did
- Rewrite `_task_0085_night_sounds`: 'the Giant's roar is the longest sound at night' becomes 'every boss voice is longer than every ordinary night sound'; the house being hit stays the loudest file (bosses at `GIANT_PEAK` or below); replace each borrowed `ENEMY_SOUNDS` entry 0247-0255 left
- Extend `_night_sound_ids()` so every new file in `assets/sfx/` is reached. The event stingers (fog, rain, the Blood Moon, the Full Moon) are not this task's: 0286 writes and plays them

## Done when

- [ ] `_task_0284_enemy_sounds` in `src/tools/headless_v1.gd`: every enemy in `GameData.ENEMIES` has a voice file of its own, every boss voice is longer than any ordinary night sound and quieter than the alarm, and fifty rats are one entry in `nearest_by_kind`
- [ ] `_case_0284_boss_voices` in `src/tools/input_v1.gd`: a boss spawned in a real scene plays its voice once with no position and ducks the bed (`Audio.duck_gain()`)
- [ ] `_task_0085_night_sounds` (rewritten) passes; `python tools/gen_sfx.py --report` for every new sound is in the journal
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
