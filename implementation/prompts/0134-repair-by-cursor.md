# 0134 - Repairing by cursor

- **Phase:** 10 - Sleep is the night
- **Status:** todo
- **Depends on:** 0131, 0113, 0133
- **Likely files:** src/core/interact.gd, src/core/building.gd, src/core/repair.gd, src/ui/guardian_cursor.gd, src/ui/night_hud.gd, src/ui/build_mode.gd, assets/locale/strings.csv, src/tools/headless_check.gd, src/tools/input_check.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd

## Goal

Repairs at night are made by pointing, not by walking. A damaged defence or the house is mended by selecting it with the cursor, paid as today, and defences are mended no other way.

## Requirements

- At night, confirming the cursor on a damaged structure or the house (an occupied cell, or nothing selected in the hotbar) writes 0129's `repair_cell` at the cursor; any part of a multi-cell structure mends its anchor (`Building.anchor_of`). Mending is `Repair.apply_all`: as far as the ledger covers, at today's price (`Repair.cost_at`, the house at `HOUSE_REPAIR_PERCENT`), up to 0113's real maximum
- The cursor shows its repair state over anything `Repair.can_mend` allows, and the tooltip adds what a full repair costs and how much can be afforded (`Repair.max_affordable`)
- Defences lose the farmer's repair verb: `Interact._offered` offers `repair` only for the house, production buildings and stations, by day. A damaged defence by day offers nothing and waits for the night. Gate it in `_offered`, not by adding `repair` to `Interact.DAY_ONLY`: every verb there needs a `Sfx.VERB_SOUNDS` entry (`_task_0084_day_sounds`) and there is no repair sound; if it must go there, map it to the nearest existing sound until 0281
- **Already moved by 0129:** `_task_0053_repair` / `_case_0053_repair` mend a wall by day with the farmer's verb, and `headless_check`'s `_wall_under_attack` mends at night by writing `repair_cell` every tick - its assert accepts `fell_at == 0` ('it held'), because nothing slows a mend any more
- There is no farmer, so there is no per-HP work time any more: write in the journal what that does to a siege (a scripted wall under attack, mended every second, against today's held key) and whether a lever will be needed
- The interim REPAIR button of 0129 leaves the night HUD (0139 lays out what is there instead), and with it its string: delete the `NHUD_REPAIR` row, or `tools/i18n_check.py` fails on an unused key. Update what names `RepairButton`: `_case_0056_night_hud` (~3355, ~3407), `_case_0081_theme`'s size loop (~4403) and the RepairButton half of 0129's `_case_0129_asleep`, which now mends through the cursor
- Rewrite `_task_0053_repair` and `_case_0053_repair` where they mend a defence with the farmer's verb by day; the house by day keeps the verb
- A rule change: SIM moves if the determinism scenario repairs a defence by day - say which

## Done when

- [ ] `_task_0134_cursor_repair` in `headless_v1.gd`: a damaged gun tower mended through `repair_cell` at night costs exactly `Repair.cost_at`; it is refused, changing nothing, when the ledger cannot pay; a damaged wall by day offers the farmer no verb; the house by day still does
- [ ] `_case_0134_repair` in `input_v1.gd`: confirming the cursor on a damaged wall at night mends it, with the mouse and with a synthetic pad press; no `RepairButton` exists any more and `python tools/i18n_check.py` passes
- [ ] A capture of the repair cursor and its tooltip, opened
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
