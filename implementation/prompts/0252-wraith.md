# 0252 - The wraith

- **Phase:** 14 - Enemies and bosses
- **Status:** done
- **Depends on:** 0229, 0218
- **Likely files:** src/core/towers.gd, src/core/combat.gd, src/core/game_data.gd, src/ui/world_view.gd, src/ui/wraith_fade.gdshader (new), src/ui/names.gd, src/ui/describe.gd, src/ui/sfx.gd, assets/locale/strings.csv, src/tools/shot.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd

## Goal

Winter's answer to a defence that only shoots: in the dark it cannot be aimed at. Light - the searchlight, the flare, fire, the porch - becomes a weapon of its own.

## Art

What this task puts on screen will be dressed by Codex art pack(s) A051
(`implementation/backlog/packs/`). Draw it through the placeholder road of
task 0120 until each pack is integrated - or with the pack's art if
`python implementation/backlog/assets.py status <pack>` already says
`integrated`. Never wait for art and never draw or generate PNGs here.

## Requirements

- `ENEMIES.wraith` with `# LEVER`s (hp, `ticks_per_tile`, damage, reward, armour; inside `_task_0051_tank`'s non-boss bounds) and a `needs_light` flag
- Light comes only from 0229's core rule - `Light.is_lit(state, cell)` in `src/core/light.gd`, or whatever name 0229's journal gives it (searchlight cells, the flare area, burning cells, the porch) - never from `lighting.gd`; if that rule cannot be asked about one cell, add the query there rather than a second definition here
- `Towers._acquire` (0218's bucketed version) and `Combat.worth_shooting` skip a `needs_light` enemy on an unlit cell; it is a target from the tick it steps into light, and a shot already in the air still lands
- Decide and document what is not aiming - splash landings, mines, the cone, the flare. Recommendation: area damage still hurts it, so the dark has answers that are not light
- Names.KEYS `wraith`, `ENEMY_WRAITH`/`ENEMY_WRAITH.other` (wraith/wraiths, assombração/assombrações); `DESC_NEEDS_LIGHT` ('can only be aimed at in light' / 'só dá para mirar nela na luz'); `Sfx.ENEMY_SOUNDS.wraith` borrows `sfx/groan_walker` until 0284
- On screen: a view-only alpha shader in `src/ui/` reading the same core rule - faint outside light, solid in it, never fully invisible to the player - over 0120's placeholder road with its forecast head until A051 is integrated by 0265 (the pack's art is opaque with binary alpha; transparency is the shader's)
- Hashes: DATA moves; SIM should not; the shader moves neither

## Done when

- [ ] `_task_0252_wraith` in `src/tools/headless_v1.gd`: a gun tower ignores a wraith walking past it in the dark and shoots it on the first tick it stands in a searchlight cell, a flare's area or a burning cell
- [ ] `_case_0252_wraith_fade` in `src/tools/input_v1.gd`: the wraith's sprite is faint outside light and solid in it
- [ ] `python tools/shot.py 0252 wraith` (a new scenario: one in the beam, one outside it) opened and looked at
- [ ] the Deliverables table of `implementation/backlog/packs/A051-wraith.md` states the final geometry this task settled
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
