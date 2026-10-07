# 0234 - The arsenal grows with the seasons

- **Phase:** 13 - Weapons of the night
- **Status:** todo
- **Depends on:** 0224, 0225, 0226, 0227, 0228, 0229, 0230, 0231, 0149, 0220, 0223
- **Likely files:** src/core/game_data.gd, src/core/building.gd, src/ui/hotbar.gd, src/ui/build_mode.gd, src/ui/night_hud.gd, src/ui/world_view.gd, src/ui/transition.gd, assets/locale/strings.csv, implementation/BALANCE.md, src/tools/headless_check.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd

## Goal

The arsenal arrives with the calendar - spring's six, then summer's, autumn's and winter's - and every defence costs money as well as materials, so the day's purse is what the night is built with (plan sections 2, 5 and 7).

## Art

What this task puts on screen will be dressed by Codex art pack(s) A045
(`implementation/backlog/packs/`). Draw it through the placeholder road of
task 0120 until each pack is integrated - or with the pack's art if
`python implementation/backlog/assets.py status <pack>` already says
`integrated`. Never wait for art and never draw or generate PNGs here.

## Requirements

- The `season` field 0193 put on `DEFENCES` (default spring; 0224-0231 set their own) becomes a rule, per the plan's table: spring the gun tower, crossbow, mine, fence, barricade and wall; summer the flamethrower, decoy, beehive and bait; autumn the mortar, catapult and garlic braid; winter the searchlight and electric fence. Confirm the hardwood wall level and the sandbags and say why. Gated through 0220's `Calendar.season_reached` (Year 2 keeps all), refused in `Building.why_not` with 0220's season key, shown greyed in the hotbar with its season; `validate()` refuses a `season` outside 0-3
- Moving the flamethrower and the mortar out of spring is a rule change: every test, tool and showcase that builds them on day 1 (perf_check's worst case, `_task_0043`, `_task_0044`, the tower groups, `tower_showcase`, the autoplayer) gets a test helper that sets the calendar - never a switch in core
- Money in the cost (plan sections 1 and 7): each `cost` gains a money share (LEVERs). A kit pays the materials in advance and placing it still charges the money: `check_recipes` compares the kit's inputs with the cost less its money, `Building.affordable` and `why_not` ask for the money even when a kit is held (today a kit alone says yes), `Building.place` takes the money either way, and refunds follow `refund_for_cost`
- The hotbar of 0133 already pages or scrolls: give it a fixed order, by season then by cost, and group or page it by season if that reads better - decide; keyboard, mouse and pad still reach every slot
- 0223's tarp list and `transition.gd`'s `WAKES` take the new families; every new defence has its hotbar icon through the placeholder road until A045 is integrated by 0244
- Prices argued against 0194's money per day: at the start of a season a good day buys about one new defence (plan section 5) - a table in `implementation/BALANCE.md`
- SIM and DATA move on purpose: record both

## Done when

- [ ] `_task_0234_arsenal` in `src/tools/headless_v1.gd` asserts each defence is refused before its season with the season reason and placeable after, Year 2's spring keeps winter's defences, a placed kit still charges its money, and `GameData.validate()` refuses a kit whose inputs drift from the materials
- [ ] `_case_0234_hotbar_pages` in `src/tools/input_v1.gd` pages the hotbar and places an autumn defence in autumn
- [ ] The Deliverables tables of `implementation/backlog/packs/A044-tarps.md` and `implementation/backlog/packs/A045-power-weapon-icons.md` state the final geometry this task settled (the tarp families and footprints, the icon list)
- [ ] `python tools/shot.py 0234` captures of the hotbar in spring and in winter, opened and looked at
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
