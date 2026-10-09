# 0171 - Winter: nothing grows outside

- **Phase:** 12 - The day that pays
- **Status:** done
- **Depends on:** 0170, 0159
- **Likely files:** src/core/farming.gd, src/core/interact.gd, src/core/game_data.gd, src/ui/day_hud.gd, src/ui/main.gd, src/ui/world_view.gd, src/ui/placeholder_art.gd, assets/locale/strings.csv, src/tools/shot.gd, src/tools/headless_v1.gd

## Goal

When a season ends its crops wither, and in winter nothing grows outside - yet the day still matters: the pond, the quarry, the workshop and the barn carry it while the farm lives on autumn's stock.

## Requirements

- The change of season, moved here from 0170 so one task owns what a season boundary does to the field: on the first morning of a season `Farming.morning` withers every planted crop whose `seasons` does not list the new one (regrowing plants too, once 0172 has them). The plot loses its crop and growth and keeps a `withered` marker naming the crop for the view, like 0155's `trampled`: `Farming` treats it as empty tilled ground and planting clears the marker (no new verb, so no new sound). No crop lists winter, so Winter 1 withers what autumn left in the ground: write that in the journal
- A withered crop draws through the placeholder road (the crop's stage-2 frame, greyed in code) until A014's withered crop is integrated by 0197
- `Farming.morning` credits no growth outdoors in a season named by `NO_GROWTH_SEASONS` (`# LEVER`, winter; in `digest()`; `validate()` refuses a name not in `GameData.SEASONS`), so a crop that is in the ground in winter anyway (a test, an old save) never grows
- Planting in winter is refused with a reason the highlight can show (a `WHY_*` key in both languages), never a silent nothing; tilling still works. Interact has no refusal road today: give it a reason array of the shape `Building.why_not` returns, which `Names.refusal` already turns into words (0175 reuses it for tool tiers)
- The seed strip says that nothing grows in winter instead of showing an empty list (a `DHUD_*` string in both languages)
- Assert the rest of a winter day still runs - a check, not a new rule: fishing (winter species once 0179 has them), mining and regrowth, crafting queues and animals all produce
- No greenhouse: plan section 3.1 puts it after 1.0
- Winter's look is 0159's; this task adds only the withered stand-in and the HUD line. DATA moves; SIM does not unless the determinism scenario crosses a season - say which

## Done when

- [x] `_task_0171_winter` in `src/tools/headless_v1.gd`: a corn plot withers on the first morning of autumn and a wheat plot sown that morning does not; every planted crop withers on Winter 1; a watered plot gains no day on a winter morning; a seam, a press queue and a cow still produce on a winter day (direct calls or a short run)
- [x] New `withered` (the first morning of autumn by a summer field) and `winter_day` scenarios: `python tools/shot.py 0171 withered winter_day --fhd` shows the withered stand-ins and the HUD line; opened and looked at
- [x] `python tools/verify.py` prints PASS
- [x] the determinism hash is unchanged, or the change is deliberate and both
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
