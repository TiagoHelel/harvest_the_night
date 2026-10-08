# 0139 - The night HUD for the guardian

- **Phase:** 10 - Sleep is the night
- **Status:** done
- **Depends on:** 0133, 0134, 0135, 0136, 0137
- **Likely files:** src/ui/night_hud.gd, src/ui/day_hud.gd, src/ui/hotbar.gd, src/ui/ui_kit.gd, src/ui/placeholder_art.gd, assets/locale/strings.csv, src/tools/headless_check.gd, src/tools/input_check.gd, src/tools/input_v1.gd

## Goal

One night HUD built for the guardian rather than for a farmer in the yard: the time to dawn, the house, the wave, START, speed, skip, the flare and the hotbar, all reachable by mouse and by pad.

## Art

What this task puts on screen will be dressed by Codex art pack(s) A005
(`implementation/backlog/packs/`). Draw it through the placeholder road of
task 0120 until each pack is integrated - or with the pack's art if
`python implementation/backlog/assets.py status <pack>` already says
`integrated`. Never wait for art and never draw or generate PNGs here.

## Requirements

- Top strip: the night, wave x/y, the dawn countdown (0137) and the house bar against `Phases.house_full` (the boss bar stays where it is). Bottom: the hotbar (0133). Bottom right: START in the build step; speed, skip and the flare with its charge during the waves
- A mode hint line says what a confirm does now - place, upgrade, sell, repair or aim - with the key or the pad glyph from 0121, following the cursor's state
- Skip becomes a button whose tooltip is its refusal (`Sim.why_not_skip`), and the day HUD's `SkipLine` read-out goes. The farmer-centric REPAIR button is gone (0134). The day HUD's `NightButton` belongs to 0127 and 0140 and is not touched here
- Every control writes an intent or asks the driver, as today; on a pad each one is reachable by focus or by its own action
- Icons through the placeholder road until A005 is integrated by 0147
- Rewrite `_case_0056_night_hud` (and `_task_0056_night_hud` where it reads the old layout) and the `SkipLine` read in `_case_0055_speed` (~3178); remove strings nothing reads any more (`DHUD_SKIP` and `DHUD_SKIP_NO`; 0134 already took `NHUD_REPAIR`) so `tools/i18n_check.py` stays clean
- View only: neither hash moves

## Done when

- [ ] `_case_0139_night_hud` in `input_v1.gd`: START is up in the build step and starts the waves; speed cycles 1/2/4; skip is refused under `SKIP_MIN_HOUSE_PERCENT` with its reason and allowed above it; the flare shows its charge; no `RepairButton` exists; the hint changes with what is under the cursor
- [ ] `python tools/shot.py 0139 dusk wave` and `--fhd` captures opened, also with `--pt_BR`: no two labels on top of each other and nothing over the hotbar
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
