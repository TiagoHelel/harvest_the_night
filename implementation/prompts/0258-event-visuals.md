# 0258 - Fog, rain and a red moon on screen

- **Phase:** 14 - Enemies and bosses
- **Status:** todo
- **Depends on:** 0256, 0257
- **Likely files:** src/ui/lighting.gd, src/ui/particles.gd, src/ui/fog.gdshader (new), src/ui/world_view.gd, tools/palette.py, src/ui/palette_data.gd (generated), src/tools/perf_check.gd, tools/perf_baseline.txt, src/tools/shot.gd, src/tools/input_v1.gd

## Goal

Fog that looks like fog, rain you can see, a red moon that makes the farm look wrong - and none of it touches a rule.

## Requirements

- View only, both hashes unchanged: everything reads `Weather.event` (0256, 0257) and `Light.is_lit` (0229), and nothing writes the state
- Fog: a code noise shader over the world (no new PNG), thinner on lit cells so the searchlight visibly cuts it
- Rain: particles in `particles.gd` bounded by the accessibility particle density setting (`a11y/particle_density`), a darker night ramp, and a mud tint on walkable ground
- Blood Moon: a red night ramp. Ramps go the road 0152 used for the Full Moon: `rain` and `blood_moon` entries in `tools/palette.py` `RAMPS`, written into `PaletteData` by `python tools/gen_sprites.py` (never edit `palette_data.gd`), picked by `WorldView._night_ramp()`. Check that the Full Moon still reads brighter than an ordinary night and that the ramps (ordinary, Full Moon, fog, rain, Blood Moon) are told apart at a glance
- Cost: `perf_check.gd`'s view timing (`_view`, today's `view_lighting`/`view_particles`) gains a rain night at 4x as its own `PERF` line (e.g. `view_rain`), inside `tools/perf.py`'s tolerance and accepted with the reason in the journal
- Shot scenarios `fog`, `rain`, `blood_moon` and `full_moon` in `src/tools/shot.gd`, each finding a (seed, date) through `Weather.event` or `Calendar.is_full_moon` rather than an override

## Done when

- [ ] `_case_0258_event_visuals` in `src/tools/input_v1.gd`: each event turns its layer on with the night and off at dawn, the rain particle count follows the density setting, and a night with the layers on and one with them off end on the same SIM hash
- [ ] `python tools/shot.py 0258 fog rain blood_moon full_moon --fhd` opened and looked at beside `docs/reference-sheet.png`: the farm stays readable in every one
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
