# 0286 - Fog, rain and winter wind

- **Phase:** 16 - Sound, collections and polish
- **Status:** done
- **Depends on:** 0186, 0256, 0257, 0285
- **Likely files:** tools/gen_ambience.py, assets/ambience/, tools/gen_music.py, assets/music/, src/ui/ambience.gd, src/ui/music.gd, src/tools/headless_check.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd

## Goal

The bed under everything follows the weather and the season: fog and rain on the nights that have them, wind through the winter, the animals heard near their coop and barn, and a short stinger when an event night reaches its build step. View only: neither hash moves. (The animal calls came from 0281 and the stingers from 0284, so those fit one invocation.)

## Requirements

- `tools/gen_ambience.py` writes a fog bed and a rain bed for the night, and a winter bed (wind, no birds, no crickets) for winter's day and night, looped with its `seamless()` and under `BED_PEAK` - the bed stays the quietest thing in the game
- `Ambience.bed_for` stays static and gains the season and tonight's event: an event night's bed beats the season's, and winter's beats the ordinary day and night beds. The event is 0256's `Weather` answer for `(seed, day)` (0257 added the Blood Moon to it) - the function the forecast panel calls, never a second draw and never the view's own `RandomNumberGenerator`
- Touches by season: winter gets its own short lists (no crickets, no songbirds), and no touch is in both a day list and a night list
- Animals near barns, written here (moved from 0281): cluck, moo, baa and oink in `gen_ambience.py` from `gen_sfx`'s primitives (it already imports `gen_sfx`), at most `TOUCH_PEAK`, played at the coop's and the barn's cells through the existing falloff - by day while the building stands with animals of that kind in it (0183's residents), and as a sleepy murmur at night, when they sleep inside (0186). The dog is not here: its bark is 0283's power sound. Decide whether a wrecked-but-standing barn still murmurs
- The beds change on the cue they use today (`Audio.play_bed` with the transition's length); nothing changes the bed in the middle of a night
- Event stingers (moved from 0284): fog, rain, the Blood Moon (0257) and the Full Moon (0152) as short cues in `tools/gen_music.py` beside `sting` - `PIECES` entries, at most `STING_PEAK`, named in 0285's not-loop list - played once through `Audio.play` (the Music bus, because the file is in `assets/music/`) when a night with that event reaches its build step. The event is the same `Weather` answer the bed reads (the Full Moon is 0152's `Calendar.is_full_moon`), never decided in the view
- Rewrite `_task_0087_ambience` in `headless_check.gd` for the new `bed_for`: every file is still asked for, every bed loops (`_loop_seam` at most 1.0) and peaks under 0.3, and the house being hit still stands far above the ducked bed

## Done when

- [ ] `_task_0286_weather_ambience` in `src/tools/headless_v1.gd`: `bed_for` answers for every season, phase and event; each new bed loops and stays under the old peak; no touch is in both a day and a night list, and winter's hold no cricket and no songbird; animal calls are offered only where a coop or barn with animals stands; each stinger is in `assets/music/`, at most `STING_PEAK` and on 0285's not-loop list
- [ ] `_case_0286_weather_ambience` in `src/tools/input_v1.gd`: a foggy night's build step plays the fog bed (`Audio.bed_playing()`) and the fog stinger once (`Audio.plays_of()`), and a winter morning the winter bed
- [ ] `python tools/gen_ambience.py --report` for the new beds (length, peak, seam) and `gen_music.py --report` for the stingers are in the journal
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
