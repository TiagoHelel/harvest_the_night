# 0256 - Fog and rain

- **Phase:** 14 - Enemies and bosses
- **Status:** todo
- **Depends on:** 0158, 0229
- **Likely files:** src/core/weather.gd (new), src/core/forecast.gd, src/core/game_data.gd, src/core/towers.gd, src/core/combat.gd, src/core/enemies.gd, src/ui/forecast_panel.gd, assets/locale/strings.csv, src/tools/shot.gd, src/tools/headless_v1.gd

## Goal

Nights that are not all alike: some are foggy, some rain. Both are known at dusk, so they change what you build rather than punish you for not guessing.

## Art

What this task puts on screen will be dressed by Codex art pack(s) A055
(`implementation/backlog/packs/`). Draw it through the placeholder road of
task 0120 until each pack is integrated - or with the pack's art if
`python implementation/backlog/assets.py status <pack>` already says
`integrated`. Never wait for art and never draw or generate PNGs here.

## Requirements

- `Weather.event(seed, date)` in a new `src/core/weather.gd` (class name `Weather` - `Events` is already the log), keyed on the calendar date (`Calendar.date`, which 0153's hold keeps on 14), not on `day`: a fresh stream mixed like `Endless._stream_for` but salted so it is not the wave table's stream, never `state["rng"]`; at most one event a night; it returns none on date 1 and on `Calendar.is_calm(date)`; no State key, and none may be named `moon_phase`. The one function every reader calls (0270 will let a night record pin or forbid an event through it)
- `GameData.NIGHT_EVENTS` with per-season weights (percent, `# LEVER`) for `fog` and `rain` and their levers, listed in `GameData.digest()` and checked by a new `check_night_events` in `validate()`: weights 0-100, a season's weights summing to at most 100, each lever in range
- Fog: `Towers.reach_of` (which 0229 taught the tower's cell) loses `fog_reach_penalty` (1) down to a floor of 1, except for a tower on a lit cell (`Light.is_lit`, 0229) - the searchlight cancels it; every shape that reads reach gets the same answer
- Rain: `DAMAGE_FIRE` hits and burn ticks deal `rain_fire_percent` (bees are not fire, even if 0226 reused `burning`), and mud slows walkers by `rain_mud_percent` in `Enemies._walk`, composed with the flare's (`Ability.slowed_ticks`) and the garlic's slows by one written rule; flyers (0249's `flies`) are not slowed
- Ask `Weather` once per system tick (`Towers.tick`, `Enemies.tick`, `Combat.tick`), not once per body, so a swarm does not pay for it; `python tools/perf.py --report` stays inside its tolerance
- The `event` slot 0158 left in `Forecast.of(seed, date)` is filled from `Weather.event`; `src/ui/forecast_panel.gd` shows its icon (placeholder until A055 is integrated by 0269) and `FCAST_FOG`/`FCAST_RAIN` (FOG / NEBLINA, RAIN / CHUVA, widths measured), beside 0158's `FCAST_*` rows
- Rules only: fog and rain on screen are 0258's
- Hashes: DATA moves (a new table); SIM should not, since the determinism night is Spring 1 - if it does, the journal says why

## Done when

- [ ] `_task_0256_fog_rain` in `src/tools/headless_v1.gd`: the event for a (seed, date) is the same however often it is asked and whatever the run RNG did; over seeds 0-49 and dates 1-56 (pure calls, no simulation) each season's share of fog and rain is within 5 points of its weight (printed); date 1 and a calm date have none; `Forecast.of` names the same event
- [ ] The same group: in fog a gun tower reaches one tile less unless its cell is lit; in rain a burn deals `rain_fire_percent` and a walker takes the slower count per tile
- [ ] `python tools/shot.py 0256 forecast_fog --fhd` (a new scenario in `src/tools/shot.gd` that finds a foggy (seed, date) through `Weather.event`, never an override) shows the event in the forecast, opened and looked at
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
