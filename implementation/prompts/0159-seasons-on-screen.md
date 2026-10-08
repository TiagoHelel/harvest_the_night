# 0159 - Seasons on screen

- **Phase:** 11 - Calendar and seasons
- **Status:** done
- **Depends on:** 0149
- **Likely files:** src/ui/season_view.gd (new), src/ui/season_remap.gdshader (new), src/ui/ambient_motion.gdshader, tools/palette.py, tools/gen_sprites.py, src/ui/palette_data.gd (generated), src/ui/world_view.gd, src/ui/particles.gd, src/ui/placeholder_art.gd, src/tools/shot.gd, src/tools/input_v1.gd, src/tools/headless_v1.gd

## Goal

The same farm through the year: today's green in spring, warmer in summer, ochre and rust in autumn, snow in winter - all of it in the view, with not one rule touched.

## Art

What this task puts on screen will be dressed by Codex art pack(s) A012, A013
(`implementation/backlog/packs/`). Draw it through the placeholder road of
task 0120 until each pack is integrated - or with the pack's art if
`python implementation/backlog/assets.py status <pack>` already says
`integrated`. Never wait for art and never draw or generate PNGs here.

## Requirements

- A palette remap shader (`src/ui/season_remap.gdshader`) on the terrain, edge and prop layers: each season maps the grass and foliage palette entries onto other palette entries (spring is today's art, summer warmer, autumn ochre and rust). The tables live in `tools/palette.py` and reach `PaletteData` through `python tools/gen_sprites.py` (its `palette_gd()` writes only `COLOURS` and `RAMPS` today: extend it); a uniform switches the season, and the terrain - drawn once - is never redrawn for it. A CanvasItem has one material and the trees already carry `ambient_motion.gdshader` for the wind: put the remap inside that shader (or a shared include) for them
- Winter stand-in until A012 and A013 are integrated by 0163 and 0164: the remap turns grass and foliage to the palette's pale colours (`bone`, `bone_dark`, `moon`, `stone_light`). No new `COLOURS` entry: the raster importer maps sources onto that palette, so a new colour could change imported art. Register the winter paths the seasonal lookup asks for (`terrain/<name>_winter`, `props/tree_<season>`, the caps) in 0120's registry under A012 and A013, resolving to the base frame, so `python tools/placeholders.py` lists both packs until 0163 and 0164 delete the entries
- Hooks so those leaves only add frames: a seasonal lookup (e.g. `SeasonView.frame_for(name, season)`) returns `<name>_<season>` when the art lookup of 0120 has it and the base name otherwise; a seasonal terrain atlas, when one exists, is swapped onto the terrain `TileMapLayer`'s tile set; the remap leaves alone a raster frame that already carries its season, and still remaps a registered stand-in
- Snowfall in winter in `src/ui/particles.gd`, honouring `a11y/particle_density` and the `video/max_particles` cap
- Snow on roofs by a code mask: in winter the top rows of the house's, the stations' and the stall's opaque roof pixels draw in `bone`/`moon` (the occupant sprites in `world_view.gd`; `house_view.gd` is the interior and has no roof). No new art: if the shots fail, say so in the journal and propose a pack rather than drawing one
- The season comes from `Calendar.season_of(Calendar.date(state))` and changes on the morning of a season's first day, behind 0138's wake-up, never mid-frame
- New shot scenarios `season_summer`, `season_autumn`, `season_winter` and `season_winter_night`: a date in each season, framed like `noon`
- View only: nothing in `src/core/` changes, and SIM and DATA must not move

## Done when

- [ ] `_case_0159_seasons` in `src/tools/input_v1.gd`: the remap's season and the snowfall follow the date (off in spring, on in winter), and the terrain layer is not redrawn when the season changes
- [ ] `python tools/gen_sprites.py --check` (or a `_task_0159_palette` group in `src/tools/headless_v1.gd`) checks that every grass or foliage colour used by `terrain/` and the trees has a mapping in every season: it passes, and a scratch table missing one mapping makes it fail (tried, reverted, said so in the journal)
- [ ] `python tools/shot.py 0159 noon season_summer season_autumn season_winter season_winter_night --fhd`, opened against `docs/reference-sheet.png`: each season reads at a glance and the night ramp still works over it
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
