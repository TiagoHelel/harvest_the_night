# Backlog - HARVEST THE NIGHT

`###############.........`  **179 / 296 done**

0 doing / 117 todo / 0 blocked across 18 phases.

Run one task - `/next-task`, which reads
`implementation/prompts/00-RUNNER-LOOP.md` and does exactly one:

```
/next-task
```

Keep going until it is all ticked:

```
/loop /next-task
```

First up: **0123 - Art: the farmer tilling, planting, watering and harvesting**. The whole of what is left is
spelled out under *What is open* below, ready ones first.

The boxes below are **generated** from the `Status:` line inside each
prompt file. Do not tick them by hand: use `python tools/task.py done 0042`,
which rewrites this file for you.

## What is open

117 task(s) left, the ready ones first, then what they
unlock. Generated from `tools/backlog/part*.py` together
with the prompt files, so the two cannot disagree.

### 0123 - Art: the farmer tilling, planting, watering and harvesting

Waits for Codex art A007.  Likely files: `assets/art_source/player-fhd/, assets/art_source/manifest.json, assets/art_source/ownership.json, src/ui/player_art.gd, src/ui/placeholder_art.gd, src/tools/art_showcase.gd, src/tools/headless_check.gd, src/tools/shot.gd`.

The field verbs still play the older, stockier 48x48 farmer next to the 32px walk. Put in A007's till, plant, water and harvest, drawn facing south, north and west, so the farmer is one person whatever he is doing.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A007` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A007-PROMPT.txt` handoff (under `implementation/backlog/deliveries/`); check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/player-fhd/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend `art_showcase.gd --work` (and the FHD player sources check if the pack is exact-source) for the new strips
- Runtime names `<verb>_<dir>_0..3` for till, plant, water and harvest x south, north, west - anticipation, contact, follow-through, recovery - at the canvas, pivot and draw scale the pack's contract states; east is west mirrored at runtime
- `PlayerArt.pose` picks a verb's strip by facing (today `VERBS` maps a verb to one west strip, drawn for every facing), `flip` only for `Player.EAST`; one code path for every verb, with verbs not yet converted keeping their one legacy strip, which 0124 and 0125 reuse if this lands first. The contact frame still meets the rules' completion (`player_work.gd`)
- The tool in hand is not tiered by art: keep the pack's fixed head ramp as delivered and record which colours it is (manifest metadata or a constant beside `PlayerArt`) so 0173 can tint it per tier; this task draws it untinted
- Retire the legacy `till_*`, `plant_*`, `water_*`, `harvest_*` 48x48 outputs from the manifest and `ownership.json`, and their `PlayerArt.SECONDS` rows; rewrite `_task_0073_player_art` (its verb loops, ~l.13253-13276, and 'a verb is drawn even while a direction is held') and `art_showcase.gd`'s `--work` checks (`_work_frame` and `_work_cycles`, ~l.1491-1530, which pin `PlayerFrames.FEET`/`CANVAS` 48x48 and `pose(...)["name"] == verb` for north and south); delete A007's registry entry
- Set the pack to integrated: `python implementation/backlog/assets.py set A007 integrated`.

  - done when: `python tools/show_art.py --work --check` passes with the four verbs in three directions; `python tools/import_art.py --check` passes
  - done when: `python tools/placeholders.py` no longer lists A007
  - done when: FHD captures (`python tools/shot.py 0123 --fhd`; add a scenario that holds the farmer mid-verb if none does) of each verb facing south, north, west and east, by day and in the dark, in `implementation/shots/0123/`, opened: feet planted, the same body height as the walk
  - done when: The sim and data hashes are unchanged (art never moves them)

### 0124 - Art: the farmer chopping, mining, collecting and carrying

Waits for Codex art A008.  Likely files: `assets/art_source/player-fhd/, assets/art_source/manifest.json, assets/art_source/ownership.json, src/ui/player_art.gd, src/ui/placeholder_art.gd, src/tools/art_showcase.gd, src/tools/headless_check.gd, src/tools/shot.gd`.

Chopping and mining are what a first day is made of, and they still play the old 48x48 farmer. Put in A008's chop, mine, collect and carry in the 32px body.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A008` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A008-PROMPT.txt` handoff (under `implementation/backlog/deliveries/`); check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/player-fhd/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend `art_showcase.gd --work` for the new strips
- Runtime names `<verb>_<dir>_0..3` for chop, mine, collect and carry x south, north, west, east mirrored at runtime, at the pack's canvas, pivot and draw scale. `carry` is a view cue (`PlayerArt.COSMETIC`), not a core verb, and maps the same way
- If 0123 has not yet made `PlayerArt.pose` choose a strip by facing, do it here as the one path for every verb. The axe and pickaxe heads keep the pack's fixed ramp, recorded for 0173's tint, drawn untinted
- Retire the legacy `chop_*`, `mine_*`, `collect_*`, `carry_*` 48x48 outputs and their `SECONDS` rows; update `_task_0073_player_art` and the `--work` checks for the new names; delete A008's registry entry
- Set the pack to integrated: `python implementation/backlog/assets.py set A008 integrated`.

  - done when: `python tools/show_art.py --work --check` and `python tools/import_art.py --check` pass
  - done when: `python tools/placeholders.py` no longer lists A008
  - done when: FHD captures (`python tools/shot.py 0124 --fhd`, with an earlier leaf's mid-verb scenario or a new one) of each verb in four facings, by day and in the dark, in `implementation/shots/0124/`, opened: the axe meets the tree and the pick meets the rock on the contact frame
  - done when: The sim and data hashes are unchanged (art never moves them)

### 0125 - Art: the farmer crafting, trading and repairing

Waits for Codex art A009.  Likely files: `assets/art_source/player-fhd/, assets/art_source/manifest.json, assets/art_source/ownership.json, src/ui/player_art.gd, src/ui/placeholder_art.gd, src/tools/art_showcase.gd, src/tools/headless_check.gd, src/tools/shot.gd`.

The last three legacy strips: A009's craft, trade and repair in the 32px body. Repair becomes a day job in 1.0 - the house, the barns and the stations, mended by the farmer while defences are mended by cursor at night.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A009` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A009-PROMPT.txt` handoff (under `implementation/backlog/deliveries/`); check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/player-fhd/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend `art_showcase.gd --work` for the new strips
- Runtime names `<verb>_<dir>_0..3` for craft, trade and repair x south, north, west, east mirrored at runtime, at the pack's canvas, pivot and draw scale; if no earlier leaf has made `PlayerArt.pose` choose a strip by facing, do it here
- The `repair` verb plays this strip wherever the rules still offer it (by day today, and at night until 0129/0134 move night repair to the cursor); the hammer head keeps the pack's fixed ramp for 0173
- Retire the legacy `craft_*`, `trade_*`, `repair_*` 48x48 outputs and their `SECONDS` rows; update `_task_0073_player_art` and the `--work` checks; delete A009's registry entry. After this no 48x48 work strip is left except fish/reel (A024)
- Set the pack to integrated: `python implementation/backlog/assets.py set A009 integrated`.

  - done when: `python tools/show_art.py --work --check` and `python tools/import_art.py --check` pass
  - done when: `python tools/placeholders.py` no longer lists A009
  - done when: FHD captures (`python tools/shot.py 0125 --fhd`, with an earlier leaf's mid-verb scenario or a new one) of craft at the workshop, trade at the stall and repair on the house, by day and in the dark, in `implementation/shots/0125/`, opened
  - done when: The sim and data hashes are unchanged (art never moves them)

### 0143 - Art: going to bed and sleeping

Waits for Codex art A001.  Likely files: `assets/art_source/player-fhd/, assets/art_source/manifest.json, assets/art_source/ownership.json, src/ui/player_frames.gd, src/ui/raster_art.gd, src/ui/placeholder_art.gd, src/ui/house_view.gd, tools/verify.py`.

The farmer's night in his own art - getting into bed and the sleep loop - from Codex pack A001, replacing 0129's stand-ins. The owner retired A001's waking and pass-out on 2026-10-08 (`deliveries/A001-farmer-bed/WAKE-SIMPLIFICATION.txt`, `BLACKOUT-SIMPLIFICATION.txt`): he wakes on his feet beside the bed (0138) and a pass-out is a black screen, so neither is art any more.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A001` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A001-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/player-fhd/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`. The farmer has no `check_*_art.py`: its gates are a hash-checking promoter with a `--check` mode wired into `tools/verify.py` (like `implementation/fhd-player/pilots/2026-10-04/palette-variants/promote_blue_walk.py`) and the `show_art.py` showcases
- Runtime: the canvas, pivot and `draw_scale` the pack's contract states, one per animation; the get-in and sleep strips play in `house_view.gd` sitting exactly on the bed (`FURNITURE_OFFSETS` for the bed); the get-in stays a one-shot and the sleep loop loops. The retired `bed_wake` and `pass_out_*` frames are never imported or played
- Delete A001's entries from 0120's placeholder registry: the raster outputs land under the names 0129 registered, so no view code changes (`python tools/placeholders.py --check` fails on an entry left for an integrated pack). Extend the `--house-visit` showcase with both animations
- Set the pack to integrated: `python implementation/backlog/assets.py set A001 integrated`.

  - done when: `python tools/show_art.py --house-visit --check` and the farmer's promoter check pass; `python tools/import_art.py --check` passes; `python tools/placeholders.py` no longer lists A001
  - done when: FHD (1920x1080) captures of the art in the real game - going to bed and asleep - opened and looked at, in `implementation/shots/0143/`
  - done when: The sim and data hashes are unchanged (art never moves them)

### 0144 - Art: the farmer's reactions and Zzz

Waits for Codex art A002.  Likely files: `assets/art_source/player-fhd/, assets/art_source/manifest.json, assets/art_source/ownership.json, src/ui/raster_art.gd, src/ui/placeholder_art.gd, src/ui/player_view.gd, src/ui/world_view.gd, src/ui/house_view.gd`.

The farmer's reactions at the 32px detail of his new body, and the Zzz that rises from the farmhouse at night, from Codex pack A002.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A002` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A002-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/player-fhd/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; the gates are the `--reactions` showcase and the importer's bubble checks
- Runtime: `react_bang`, `react_question`, `react_note` and `react_heart` keep their names (the legacy 48x48 frames are retired) and the Zzz takes the name 0129 registered; every frame carries a `bubble_xywh` covering every glyph pixel and no body pixel (`validate_bubble` in `import_art.py`)
- The Zzz replaces 0129's stand-in over the farmhouse at night and over him in bed indoors by deleting A002's entry from 0120's placeholder registry; `Reactions.KINDS` is untouched, because the Zzz is a view cue
- Set the pack to integrated: `python implementation/backlog/assets.py set A002 integrated`.

  - done when: `python tools/show_art.py --reactions --check` passes and shows the Zzz; `python tools/import_art.py --check` passes; `python tools/placeholders.py` no longer lists A002
  - done when: FHD (1920x1080) captures by day and by night of the art in the real game - a reaction by day, the Zzz at night - opened and looked at, in `implementation/shots/0144/`
  - done when: The sim and data hashes are unchanged (art never moves them)

### 0145 - Art: the porch guardian

Waits for Codex art A003.  Likely files: `assets/art_source/guardian/, assets/art_source/manifest.json, assets/art_source/ownership.json, src/ui/raster_art.gd, src/ui/placeholder_art.gd, src/ui/guardian_view.gd, src/ui/lighting.gd, tools/check_prop_art.py, tools/show_art.py, tools/verify.py`.

The porch scarecrow that becomes the guardian at night, from Codex pack A003, replacing 0131's placeholder.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A003` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A003-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/guardian/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`. It is a new family: extend `tools/check_prop_art.py`'s `NAMES` or add a `tools/check_guardian_art.py` wired into `tools/verify.py`, with a showcase
- Runtime: the day, wake, night and point states with the canvas, pivot and timings 0131 wrote into the pack's Deliverables table, at draw scale 1.0 (`ArtPlacement`'s 2x list is not extended); the eyes' light points become emission metadata, like `light_xy`, that `lighting.gd` reads - nothing else on the scarecrow emits
- Replace 0131's placeholder by deleting A003's entries from 0120's placeholder registry (runtime names `guardian_<anim>_<i>`, as 0131 registered them); the wake still plays at the reality switch and the point (0133) when something is placed
- Set the pack to integrated: `python implementation/backlog/assets.py set A003 integrated`.

  - done when: The guardian's checker and showcase pass; `python tools/import_art.py --check` passes; `python tools/placeholders.py` no longer lists A003
  - done when: FHD (1920x1080) captures by day and by night of the art in the real game - still by day, awake with its eyes lit at night, pointing at a placement - opened and looked at, in `implementation/shots/0145/`
  - done when: The sim and data hashes are unchanged (art never moves them)

### 0146 - Art: the guardian's cursor

Waits for Codex art A004.  Likely files: `assets/art_source/ui/, assets/art_source/manifest.json, assets/art_source/ownership.json, src/ui/raster_art.gd, src/ui/placeholder_art.gd, src/ui/guardian_cursor.gd, tools/check_ui_art.py, tools/show_art.py`.

The cursor's seven states in drawn pixels, from Codex pack A004, replacing 0131's code-drawn outline.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A004` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A004-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/ui/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded lists of `tools/check_ui_art.py` and the `--ui` showcase
- Runtime: neutral, can place, blocked, upgrade, sell, repair and aim as one-cell 16x16 frames with a 2-frame pulse each, under the names 0131 registered; no text; readable over the night ramp on grass, soil and a wall
- Replace 0131's placeholder by deleting A004's entries from 0120's placeholder registry, so the states 0132, 0134 and 0135 switched on all show the new art
- Set the pack to integrated: `python implementation/backlog/assets.py set A004 integrated`.

  - done when: `python tools/check_ui_art.py` and `python tools/show_art.py --ui --check` pass; `python tools/import_art.py --check` passes; `python tools/placeholders.py` no longer lists A004
  - done when: FHD (1920x1080) captures by day and by night of the art in the real game - the cursor in each state over dark ground - opened and looked at, in `implementation/shots/0146/`
  - done when: The sim and data hashes are unchanged (art never moves them)

### 0147 - Art: the night hotbar and HUD icons

Waits for Codex art A005.  Likely files: `assets/art_source/ui/, assets/art_source/manifest.json, assets/art_source/ownership.json, src/ui/raster_art.gd, src/ui/placeholder_art.gd, src/ui/hotbar.gd, src/ui/night_hud.gd, tools/check_ui_art.py, tools/show_art.py`.

The icons of the night - the eight defences, the flare, START, speed and the moon of the dawn countdown - from Codex pack A005, replacing the hotbar's and the night HUD's placeholders.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A005` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A005-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/ui/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded lists of `tools/check_ui_art.py` and the `--ui` showcase
- Runtime: one raw source each, cut into a 16x16 `icon_<id>` and a 10x10 `hud_<id>` (visible at most 14 and 8 px) for `gun_tower`, `auto_crossbow`, `flame_tower`, `mortar`, `mine`, `fence`, `wall`, `barricade`, the flare, START, speed and the dawn moon
- The hotbar (0133) takes the 16x16 cuts and the night HUD (0139) the 10x10 ones, replacing their placeholders by deleting A005's entries from 0120's placeholder registry
- Set the pack to integrated: `python implementation/backlog/assets.py set A005 integrated`.

  - done when: `python tools/check_ui_art.py` and `python tools/show_art.py --ui --check` pass; `python tools/import_art.py --check` passes; `python tools/placeholders.py` no longer lists A005
  - done when: FHD (1920x1080) captures by day and by night of the art in the real game - the hotbar and the night HUD in the build step and mid-wave - opened and looked at, in `implementation/shots/0147/`
  - done when: The sim and data hashes are unchanged (art never moves them)

### 0161 - Art: seasons and moons

Waits for Codex art A010.  Likely files: `assets/art_source/ui/, assets/art_source/manifest.json, assets/art_source/ownership.json, tools/check_ui_art.py, src/ui/raster_art.gd (generated), src/ui/placeholder_art.gd, src/ui/forecast_panel.gd`.

The approved season, moon, boss-night and calm-night icons take the place of the forecast's code-drawn marks.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A010` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A010-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/ui/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`tools/check_ui_art.py`, `ArtPlacement` if needed).
- Runtime names: `ui/icon_<id>` 16x16 pivot (8,8) and `ui/hud_<id>` 10x10 pivot (5,5) for `spring`, `summer`, `autumn`, `winter`, `full_moon`, `boss_night` and `calm_night`, both cut from one source crop like the resource icons, binary alpha, no text. `tools/check_ui_art.py` is hard-coded to the fifteen resource icons of task 0018: give it a calendar family with the same clipping and size rules
- Replace 0158's code-drawn marks in the forecast panel by deleting their entries from `src/ui/placeholder_art.gd`; `python tools/placeholders.py` no longer lists A010
- Set the pack to integrated: `python implementation/backlog/assets.py set A010 integrated`.

  - done when: `python tools/check_ui_art.py` and `python tools/show_art.py --ui --check` pass, and `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures by day and by night of the icons in the real game - `python tools/shot.py 0161 forecast_dusk forecast_build --fhd` - in `implementation/shots/0161/`, opened and looked at
  - done when: The sim and data hashes are unchanged (art never moves them)

### 0162 - Art: forecast heads

Waits for Codex art A011.  Likely files: `assets/art_source/ui/, assets/art_source/manifest.json, assets/art_source/ownership.json, tools/check_ui_art.py, src/ui/raster_art.gd (generated), src/ui/placeholder_art.gd, src/ui/forecast_panel.gd`.

The forecast names what is coming with the enemies' own faces: the approved heads of the walker, runner, tank, breaker and Giant replace the cropped walk frames.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A011` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A011-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/ui/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`tools/check_ui_art.py`, `ArtPlacement` if needed).
- Runtime names: `ui/head_<kind>` 16x16, pivot (8,8), for `walker`, `runner`, `tank`, `breaker` and `giant`, binary alpha, matching each enemy's sprite. `tools/check_ui_art.py` gains a heads family that requires a head for each of these five; later enemies bring theirs in their own packs and add themselves to the list
- Replace 0158's cropped walk-frame heads by deleting their entries from `src/ui/placeholder_art.gd`; the panel asks for `ui/head_<kind>` and nothing else changes; `python tools/placeholders.py` no longer lists A011
- Set the pack to integrated: `python implementation/backlog/assets.py set A011 integrated`.

  - done when: `python tools/check_ui_art.py` and `python tools/show_art.py --ui --check` pass, and `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures by day and by night of the heads in the real game - `python tools/shot.py 0162 forecast_dusk forecast_build --fhd`, with the scenarios moved to a date whose forecast lists all five kinds (Spring 14 does while it is Endless-generated with the Giant's row; check it on the day) - in `implementation/shots/0162/`, opened and looked at
  - done when: The sim and data hashes are unchanged (art never moves them)

### 0163 - Art: winter ground

Waits for Codex art A012.  Likely files: `assets/art_source/terrain/, assets/art_source/crops/, assets/art_source/manifest.json, assets/art_source/ownership.json, tools/check_terrain_art.py, tools/check_crop_art.py, tools/gen_sprites.py, src/ui/world_view.gd, src/ui/season_view.gd, src/ui/placeholder_art.gd`.

Winter gets real snow on the ground: the approved snowy grass, path, soil, tilled ground, edges and shores replace the remapped stand-in of 0159.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A012` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A012-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/terrain/` (and `crops/` for the tilled tiles), manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`tools/check_terrain_art.py`, `tools/check_crop_art.py`, `ArtPlacement` if needed).
- Runtime names: `terrain/<name>_winter` for `grass`, `grass_b`-`grass_d`, `path` and `soil`, the winter `edge_*`/`shore_*` sides and corners, and `crops/tilled_winter` / `tilled_wet_winter` - 16x16, opaque, seamless, the same set as today's (the wet tile still at least 20 RGB darker, `check_crop_art.py`). The 256x80 atlas is ASCII-owned and built by `tools/gen_sprites.py` from the raster recipes (and asserted against it): build the winter atlas there the way the handoff says (new rows or a second atlas) and let 0159's hook swap it in
- Winter's ground stops going through 0159's remap (the remap stays for anything this pack does not cover); delete the stand-in entries from `src/ui/placeholder_art.gd`, so `python tools/placeholders.py` no longer lists A012
- Set the pack to integrated: `python implementation/backlog/assets.py set A012 integrated`.

  - done when: `python tools/check_terrain_art.py`, `python tools/check_crop_art.py` and `python tools/show_art.py --check` pass, and `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures by day and by night in the real game - `python tools/shot.py 0163 season_winter season_winter_night --fhd` - in `implementation/shots/0163/`, opened and looked at: no seam, edge or shore breaks the snow
  - done when: The sim and data hashes are unchanged (art never moves them)

### 0164 - Art: trees through the seasons

Waits for Codex art A013.  Likely files: `assets/art_source/props/, assets/art_source/manifest.json, assets/art_source/ownership.json, tools/check_prop_art.py, src/ui/world_view.gd, src/ui/season_view.gd, src/ui/placeholder_art.gd`.

Blossom in spring, colour in autumn, bare branches under snow in winter: the approved seasonal trees and snow caps replace the remapped stand-ins of 0159.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A013` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A013-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/props/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`tools/check_prop_art.py`, `ArtPlacement` if needed).
- Runtime names: `props/tree_spring`, `tree_autumn` and `tree_winter`, and the same for `tree_b` - 40x48, pivot (20,44), sharing canvas, pivot, scale and palette with the base tree (`variant_of` rules); summer is today's tree. The tree wind motion (`tree_wind_showcase.gd`) still applies
- Generic 16x16 snow caps drawn over each stump, rock, seam and ore node in winter, and over 0156's new nodes and stumps (one per 2x2 cell); the caps are an overlay in the view, never a change to the occupant. 0159's lookup finds the seasonal frames, and the remap leaves them alone
- Delete the stand-in entries from `src/ui/placeholder_art.gd`; `python tools/placeholders.py` no longer lists A013
- Set the pack to integrated: `python implementation/backlog/assets.py set A013 integrated`.

  - done when: `python tools/check_prop_art.py` and `python tools/show_art.py --check` pass, and `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures by day and by night in the real game - `python tools/shot.py 0164 noon season_autumn season_winter season_winter_night --fhd` - in `implementation/shots/0164/`, opened and looked at: the trees change with the season and every cap sits on its node
  - done when: The sim and data hashes are unchanged (art never moves them)

### 0193 - Every season can make what it needs

Ready to pick up.  Likely files: `src/core/game_data.gd, src/core/shop.gd, src/ui/names.gd, assets/locale/strings.csv, src/tools/headless_v1.gd`.

No defence, round, repair meal or feed may depend on a crop whose season has not come yet: every season can make what it needs.

- `check_seasonal_supply(...)` in `GameData.validate()`, taking its tables as arguments like `check_chain(recipes, prices)` so a test can hand it a broken one: for each season S, everything unlocked in S - defence kits, ammunition, repair food, animal feed - is makeable from the crops of seasons up to S plus fish, ore, wood, stone and what the stall sells in S (0190's seasonal stock table); it walks the recipe graph
- What 'unlocked in S' means: a `season` field on `DEFENCES` entries, default spring. Plan section 5 puts the flamethrower in summer and the mortar in autumn, but moving them is 0234's (with the new defences), so today's eight stay spring here
- Fix the known breaks: gunpowder in spring (a recipe from coal and oil pressed from fish by `press_fish_oil`, since corn is summer), a meal in spring (0192's, checked here), straw and hay sold by the peddler before autumn (rows in 0190's seasonal stock)
- Pepper and sunflower get their plan roles: pepper makes incendiary rounds at a better yield than wood (a recipe, not a new ammunition rule), and sunflower is pressed into oil
- Every new recipe passes `check_chain` and `check_ammo` and has a `Names.KEYS` entry and a `REC_*` row in both languages
- DATA moves; SIM moves if the stall's stock or a station's default recipe (both in the state) changes - say which

  - done when: `_task_0193_supply` in `src/tools/headless_v1.gd`: the real tables pass for all four seasons; taking out the coal gunpowder recipe makes spring fail by name
  - done when: The journal lists, season by season, the route to each kit, round, meal and feed

### 0197 - Art: trampled crops and tilled ground

Waits for Codex art A014.  Likely files: `assets/art_source/crops/, assets/art_source/manifest.json, tools/check_crop_art.py, src/ui/world_view.gd`.

The trampled crop of 0155, the withered crop of 0171 and the tilled-grass edges of 0167 get their approved art in place of their stand-ins.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A014` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A014-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/crops/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`tools/check_crop_art.py`, which checks `tilled`/`tilled_wet` today).
- Runtime names: the trampled and withered crops (16x16, pivot (8,14)) and the edge pieces under the mask names 0167 wrote into the pack's table; ground pieces keep the soil conventions (pivot (8,16), wet at least 20 RGB darker)
- Replace the stand-ins in `world_view.gd`'s plot drawing left by 0155, 0167 and 0171, and flip A014's placeholder-registry entries to raster so 0120's check stops listing it
- Set the pack to integrated: `python implementation/backlog/assets.py set A014 integrated`.

  - done when: `python tools/check_crop_art.py` and `python tools/show_art.py --crops --check` pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures by day and by night of the art in the real game, opened and looked at, in `implementation/shots/0197/`
  - done when: the sim and data hashes are unchanged (art never moves them)

### 0198 - Art: spring crops

Waits for Codex art A015.  Likely files: `assets/art_source/crops/, assets/art_source/ui/, assets/art_source/manifest.json, tools/check_crop_art.py, tools/check_ui_art.py`.

Potato, garlic and strawberry, and the spring seed packets, get their approved art in place of 0168's tinted stand-ins.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A015` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A015-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/crops` and `assets/art_source/ui/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`check_crop_art.KINDS`; `tools/check_ui_art.py`, which counts only task 0018's icons today - give it the new family rather than breaking that count).
- Runtime names: `<crop>_0..3` for potato, garlic and strawberry (16x16, pivot (8,14)), strawberry's regrowing stage under the name 0172 draws, and `ui/icon_<id>` (16x16) with `ui/hud_<id>` (10x10) cut from one source for the produce and the carrot, potato, garlic and strawberry seed packets (ids from 0170)
- Replace the stand-ins of 0168, 0170 and 0172 and flip A015's placeholder-registry entries to raster
- Set the pack to integrated: `python implementation/backlog/assets.py set A015 integrated`.

  - done when: `python tools/check_crop_art.py`, `python tools/check_ui_art.py`, `python tools/show_art.py --crops --check` and `--ui --check` pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures by day and by night of the art in the real game, opened and looked at, in `implementation/shots/0198/`
  - done when: the sim and data hashes are unchanged (art never moves them)

### 0199 - Art: summer crops

Waits for Codex art A016.  Likely files: `assets/art_source/crops/, assets/art_source/ui/, assets/art_source/manifest.json, tools/check_crop_art.py, tools/check_ui_art.py`.

Pepper, sunflower and melon, corn's regrowing stage and the summer seed packets get their approved art.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A016` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A016-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/crops` and `assets/art_source/ui/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`check_crop_art.KINDS`, `tools/check_ui_art.py`).
- Runtime names: `<crop>_0..3` for pepper and melon (16x16, pivot (8,14)) and the tall sunflower at the canvas and pivot 0168 settled, pepper's and corn's regrowing stages, icons (16x16 + 10x10 from one source) for the produce and the corn, pepper, sunflower and melon seed packets
- Replace the stand-ins of 0168, 0170 and 0172 and flip A016's placeholder-registry entries to raster
- Set the pack to integrated: `python implementation/backlog/assets.py set A016 integrated`.

  - done when: `python tools/check_crop_art.py`, `python tools/check_ui_art.py`, `python tools/show_art.py --crops --check` and `--ui --check` pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures by day and by night of the art in the real game, opened and looked at, in `implementation/shots/0199/`
  - done when: the sim and data hashes are unchanged (art never moves them)

### 0200 - Art: autumn crops

Waits for Codex art A017.  Likely files: `assets/art_source/crops/, assets/art_source/ui/, assets/art_source/manifest.json, tools/check_crop_art.py, tools/check_ui_art.py`.

Pumpkin, the grape on its trellis and beet, and the autumn seed packets, get their approved art.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A017` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A017-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/crops` and `assets/art_source/ui/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`check_crop_art.KINDS`, `tools/check_ui_art.py`).
- Runtime names: `<crop>_0..3` for pumpkin and beet (16x16, pivot (8,14)) and the tall grape trellis at the canvas and pivot 0168 settled with its regrowing stage, icons (16x16 + 10x10 from one source) for the produce and the wheat, pumpkin, grape and beet seed packets
- Replace the stand-ins of 0168, 0170 and 0172 and flip A017's placeholder-registry entries to raster
- Set the pack to integrated: `python implementation/backlog/assets.py set A017 integrated`.

  - done when: `python tools/check_crop_art.py`, `python tools/check_ui_art.py`, `python tools/show_art.py --crops --check` and `--ui --check` pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures by day and by night of the art in the real game, opened and looked at, in `implementation/shots/0200/`
  - done when: the sim and data hashes are unchanged (art never moves them)

### 0201 - Art: sprinklers

Waits for Codex art A018.  Likely files: `assets/art_source/props/, assets/art_source/ui/, assets/art_source/manifest.json, tools/check_prop_art.py, tools/check_ui_art.py`.

The copper, iron and gold sprinklers of 0178 get their approved bodies and icons; the spray stays code particles.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A018` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A018-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/props` and `assets/art_source/ui/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`check_prop_art.NAMES`, `tools/check_ui_art.py`).
- Runtime names for each tier's idle and spray-body frames at the 16x16 canvas and pivot 0178 settled, and an icon (16x16 + 10x10) per tier for the build list
- Replace 0178's stand-ins and flip A018's placeholder-registry entries to raster; the particle spray is unchanged
- Set the pack to integrated: `python implementation/backlog/assets.py set A018 integrated`.

  - done when: `python tools/check_prop_art.py`, `python tools/check_ui_art.py`, `python tools/show_art.py --props --check` and `--ui --check` pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures by day and by night of the art in the real game, opened and looked at, in `implementation/shots/0201/`
  - done when: the sim and data hashes are unchanged (art never moves them)

### 0202 - Art: tool icons

Waits for Codex art A019.  Likely files: `assets/art_source/ui/, assets/art_source/manifest.json, tools/check_ui_art.py, src/ui/workshop_panel.gd`.

Fifteen tool icons - four tools in three tiers and the three rods - replace 0173's stand-ins wherever a tool is shown.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A019` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A019-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/ui/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`tools/check_ui_art.py`, which counts only task 0018's icons today - give it the new family).
- Runtime names `ui/icon_<tool>_<tier>` (16x16, pivot (8,8)) and `ui/hud_<tool>_<tier>` (10x10, pivot (5,5)) cut from one source, for hoe, can, axe and pickaxe at basic/iron/gold and the rod at bamboo/fibre/iron, as 0173 named the tiers
- Replace the stand-ins in the workshop panel, the inventory and the stall (0190) and flip A019's placeholder-registry entries to raster. The tool in the farmer's hand stays code-tinted
- Set the pack to integrated: `python implementation/backlog/assets.py set A019 integrated`.

  - done when: `python tools/check_ui_art.py` and `python tools/show_art.py --ui --check` pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures by day and by night of the art in the real game, opened and looked at, in `implementation/shots/0202/`
  - done when: the sim and data hashes are unchanged (art never moves them)

### 0203 - Art: material icons

Waits for Codex art A020.  Likely files: `assets/art_source/ui/, assets/art_source/manifest.json, tools/check_ui_art.py`.

Copper, coal, gold, hardwood, hay and straw get their approved icons in the inventory, the HUD and the panels.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A020` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A020-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/ui/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`tools/check_ui_art.py`).
- Runtime names `ui/icon_<id>` (16x16) and `ui/hud_<id>` (10x10) cut from one source, for the ids 0176, 0177 and 0184 gave copper, coal, gold, hardwood, hay and straw
- Replace their stand-ins and flip A020's placeholder-registry entries to raster
- Set the pack to integrated: `python implementation/backlog/assets.py set A020 integrated`.

  - done when: `python tools/check_ui_art.py` and `python tools/show_art.py --ui --check` pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures by day and by night of the art in the real game, opened and looked at, in `implementation/shots/0203/`
  - done when: the sim and data hashes are unchanged (art never moves them)

### 0204 - Art: copper, coal, gold and hardwood

Waits for Codex art A021.  Likely files: `assets/art_source/props/, assets/art_source/manifest.json, tools/check_prop_art.py, src/ui/world_view.gd, src/ui/art_placement.gd`.

The new quarry nodes and the big hardwood stumps get their approved art in the world.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A021` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A021-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/props/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`check_prop_art.NAMES`; `ArtPlacement` if the 2x2 stump needs it).
- Runtime names: copper, coal and gold nodes at 16x16, pivot (8,14), each with a `_b` variant through `WorldView.PROP_VARIANTS`/`_prop_variant` like `ore`/`ore_b`; the 2x2 stump whole and chipped at the 32x32 canvas and pivot 0177 settled, placed at the bottom centre of its footprint
- Replace the stand-ins of 0176 and 0177 and flip A021's placeholder-registry entries to raster
- Set the pack to integrated: `python implementation/backlog/assets.py set A021 integrated`.

  - done when: `python tools/check_prop_art.py` and `python tools/show_art.py --props --check` pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures by day and by night of the art in the real game, opened and looked at, in `implementation/shots/0204/`
  - done when: the sim and data hashes are unchanged (art never moves them)

### 0205 - Art: fish

Waits for Codex art A022.  Likely files: `assets/art_source/ui/, assets/art_source/manifest.json, tools/check_ui_art.py, src/ui/fish_book.gd`.

Every species and the four legendaries get their icons and fish-book portraits.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A022` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A022-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/ui/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`tools/check_ui_art.py`, plus the 32x32 portraits as a family of their own).
- Runtime names: `ui/icon_<species>` (16x16) and `ui/hud_<species>` (10x10) from one source per species, for the list 0179 and 0182 settled, and a 32x32 book portrait each
- Replace the stand-ins in the inventory, the catch line and the fish book, and flip A022's placeholder-registry entries to raster
- Set the pack to integrated: `python implementation/backlog/assets.py set A022 integrated`.

  - done when: `python tools/check_ui_art.py` and `python tools/show_art.py --ui --check` pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures by day and by night of the art in the real game, opened and looked at, in `implementation/shots/0205/`
  - done when: the sim and data hashes are unchanged (art never moves them)

### 0206 - Art: fishing gear and the minigame

Waits for Codex art A023.  Likely files: `assets/art_source/ui/, assets/art_source/effects/, assets/art_source/manifest.json, tools/check_ui_art.py, src/ui/fishing_bar.gd`.

The bobber, the bait icons, the pieces of the fishing bar and the fish-book tab get their approved art.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A023` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A023-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/ui` and `assets/art_source/effects/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`tools/check_ui_art.py`; `tools/check_effect_art.py` if the bobber goes in as an effect).
- Runtime names: the 8x8 bobber (float and the 2-3 frame bite dip) replacing the float the view draws today; worm and bait icons (16x16 + 10x10); the bar's frame, marker, sweet zone and hit/miss flash at the sizes 0180 settled; the book tab icon (0182)
- Replace the stand-ins of 0180, 0181 and 0182 and flip A023's placeholder-registry entries to raster
- Set the pack to integrated: `python implementation/backlog/assets.py set A023 integrated`.

  - done when: `python tools/check_ui_art.py` and `python tools/show_art.py --ui --check` pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures by day and by night of the art in the real game, opened and looked at, in `implementation/shots/0206/`
  - done when: the sim and data hashes are unchanged (art never moves them)

### 0207 - Art: the farmer fishing

Waits for Codex art A024.  Likely files: `assets/art_source/player-fhd/, assets/art_source/manifest.json, src/ui/player_work.gd, src/ui/player_frames.gd`.

The farmer casts, waits, strikes, reels and shows the catch at the 32px detail, replacing the legacy fish and reel strips (0180's poses).

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A024` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A024-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/player-fhd/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (the work-verb list `player_work.gd` and the showcase read).
- Runtime names and timings: cast, wait, strike, reel (loop) and show the catch (2) for S, N and W, with E mirrored at runtime (not baked), on the art contract's work canvas (48x48, pivot (24,44), draw scale 0.5); if a farmer work leaf (0123-0125) has landed, reuse its `PlayerArt.pose` work-strip path; the poses follow 0180's bar stages
- Retire the legacy 48x48 `fish`/`reel` strips from the manifest and `ownership.json` once nothing reads them, and flip A024's placeholder-registry entries to raster
- Set the pack to integrated: `python implementation/backlog/assets.py set A024 integrated`.

  - done when: `python tools/show_art.py --work --check` pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures by day and by night of the art in the real game, opened and looked at, in `implementation/shots/0207/`
  - done when: the sim and data hashes are unchanged (art never moves them)

### 0208 - Art: the farmer tending animals

Waits for Codex art A025.  Likely files: `assets/art_source/player-fhd/, assets/art_source/manifest.json, src/ui/player_work.gd`.

The farmer milks, shears and feeds with a proper pose, and pets the dog, at the 32px detail.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A025` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A025-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/player-fhd/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (the work-verb list `player_work.gd` and the showcase read).
- Runtime names: a tend-animal pose (4 frames) for S, N and W with E mirrored at runtime, played for `collect` at a coop or barn and the truffle dig of 0185; pet the dog (2-4 frames) for 0185's view-only gesture; canvas, pivot and `draw_scale` as 0185 wrote into the pack
- Replace the stand-in poses and flip A025's placeholder-registry entries to raster
- Set the pack to integrated: `python implementation/backlog/assets.py set A025 integrated`.

  - done when: `python tools/show_art.py --work --check` pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures by day and by night of the art in the real game, opened and looked at, in `implementation/shots/0208/`
  - done when: the sim and data hashes are unchanged (art never moves them)

### 0209 - Art: sheep and pigs

Waits for Codex art A026.  Likely files: `assets/art_source/props/, assets/art_source/manifest.json, tools/check_prop_art.py, src/ui/animal_view.gd`.

Sheep and pigs get their approved art and the view states 0185 gave them.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A026` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A026-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/props/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`check_prop_art.NAMES`, where the cow and the chicken live today, or a new animals checker wired into `tools/verify.py` if the pack says so).
- Runtime names: idle (2), walk side-on (4, mirrored at runtime), eat (2-3) and sleep (1-2) for both, and the pig's dig (3), at the scale 0185 settled against the 32px farmer; 0185's wander/eat/sleep view states play them
- Replace the tinted stand-ins and flip A026's placeholder-registry entries to raster
- Set the pack to integrated: `python implementation/backlog/assets.py set A026 integrated`.

  - done when: `python tools/check_prop_art.py` and `python tools/show_art.py --props --check` pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures by day and by night of the art in the real game, opened and looked at, in `implementation/shots/0209/`
  - done when: the sim and data hashes are unchanged (art never moves them)

### 0210 - Art: the cow and the chicken redrawn

Waits for Codex art A027.  Likely files: `assets/art_source/props/, assets/art_source/manifest.json, tools/check_prop_art.py, src/ui/world_view.gd, src/ui/animal_view.gd`.

Today's 24x24 cow and chicken are redrawn at the farmer's scale with idle, walk, eat and sleep.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A027` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A027-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/props/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`check_prop_art.NAMES`, which names `cow` and `chicken` today).
- Runtime names: idle, walk (side-on, mirrored at runtime), eat and sleep for the cow and the chicken at the canvas and pivot 0185 settled; drop the cow and chicken from the `AMBIENT_MOTION` shader's `species` parameter in `world_view.gd` if the frames replace that sway, and keep `transition.gd`'s `DAY_ONLY` finding them
- Retire the old 24x24 `props/cow` and `props/chicken` once nothing reads them, and flip A027's placeholder-registry entries to raster
- Set the pack to integrated: `python implementation/backlog/assets.py set A027 integrated`.

  - done when: `python tools/check_prop_art.py` and `python tools/show_art.py --props --check` pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures by day and by night of the art in the real game, opened and looked at, in `implementation/shots/0210/`
  - done when: the sim and data hashes are unchanged (art never moves them)

### 0211 - Art: animal goods

Waits for Codex art A029.  Likely files: `assets/art_source/ui/, assets/art_source/props/, assets/art_source/manifest.json, tools/check_ui_art.py, tools/check_prop_art.py`.

Egg, milk, wool and truffle get their icons, and the pig's dig spot its look in the world.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A029` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A029-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/ui` and `assets/art_source/props/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`tools/check_ui_art.py`, `check_prop_art.NAMES`).
- Runtime names: `ui/icon_<id>` (16x16) and `ui/hud_<id>` (10x10) from one source for the ids 0184 and 0185 gave egg, milk, wool and truffle, and the 16x16 dig spot drawn where 0185 marks one
- Replace their stand-ins and flip A029's placeholder-registry entries to raster
- Set the pack to integrated: `python implementation/backlog/assets.py set A029 integrated`.

  - done when: `python tools/check_ui_art.py`, `python tools/check_prop_art.py` and `python tools/show_art.py --ui --check` pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures by day and by night of the art in the real game, opened and looked at, in `implementation/shots/0211/`
  - done when: the sim and data hashes are unchanged (art never moves them)

### 0212 - Art: the coop and the barn

Waits for Codex art A030.  Likely files: `assets/art_source/buildings/, assets/art_source/manifest.json, tools/check_station_art.py, src/ui/art_placement.gd`.

The coop and the barn get their approved art - whole, hurt and wrecked-but-standing - in place of 0183's stand-ins.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A030` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A030-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/buildings/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`check_station_art.FAMILY` or a buildings checker wired into `tools/verify.py`).
- Runtime names: `<id>`, `<id>_hurt` and the wrecked state 0186 added, at the footprints 0183 settled, with door/window light points on opaque pixels; full density - they do **not** join `ArtPlacement.visual_scale`'s 2.0 list
- Replace the stand-ins of 0183 and 0186 and flip A030's placeholder-registry entries to raster
- Set the pack to integrated: `python implementation/backlog/assets.py set A030 integrated`.

  - done when: `python tools/check_station_art.py` and `python tools/show_art.py --stations --check` pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures by day and by night of the art in the real game, opened and looked at, in `implementation/shots/0212/`
  - done when: the sim and data hashes are unchanged (art never moves them)

### 0213 - Art: the artisan machines

Waits for Codex art A031.  Likely files: `assets/art_source/buildings/, assets/art_source/props/, assets/art_source/manifest.json, tools/check_station_art.py`.

The keg, the preserves jar, the dairy, the loom and the mill get their approved art, idle and working.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A031` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A031-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/buildings/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`check_station_art.FAMILY`).
- Runtime names: `<id>`, `<id>_active` and `<id>_hurt` (and the wreck if 0187 chose it) for the five, at the sizes 0188 settled, with `light_xy`/`smoke_xy` on opaque active pixels; full density, not in `ArtPlacement.visual_scale`'s 2.0 list
- Replace the stand-ins of 0187 and 0188 and flip A031's placeholder-registry entries to raster
- Set the pack to integrated: `python implementation/backlog/assets.py set A031 integrated`.

  - done when: `python tools/check_station_art.py` and `python tools/show_art.py --stations --check` pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures by day and by night of the art in the real game, opened and looked at, in `implementation/shots/0213/`
  - done when: the sim and data hashes are unchanged (art never moves them)

### 0214 - Art: artisan goods

Waits for Codex art A032.  Likely files: `assets/art_source/ui/, assets/art_source/manifest.json, tools/check_ui_art.py`.

Wine, juice, jelly, pickles, cheese, butter, cloth, sandbags, flour, bread and sugar get their approved icons.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A032` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A032-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/ui/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`tools/check_ui_art.py`).
- Runtime names: `ui/icon_<id>` (16x16) and `ui/hud_<id>` (10x10) from one source for the eleven ids 0187, 0188 and 0192 gave them
- Replace their stand-ins and flip A032's placeholder-registry entries to raster
- Set the pack to integrated: `python implementation/backlog/assets.py set A032 integrated`.

  - done when: `python tools/check_ui_art.py` and `python tools/show_art.py --ui --check` pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures by day and by night of the art in the real game, opened and looked at, in `implementation/shots/0214/`
  - done when: the sim and data hashes are unchanged (art never moves them)

### 0215 - Art: the shipping bin

Waits for Codex art A033.  Likely files: `assets/art_source/props/, assets/art_source/manifest.json, tools/check_prop_art.py`.

The shipping bin of 0189 gets its approved art, lid and all.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A033` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A033-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/props/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`check_prop_art.NAMES`).
- Runtime names: the closed bin and its lid-opening strip (2-3 frames, one-shot) at the canvas and pivot 0189 settled; the view plays the lid when the bin's panel opens (view only)
- Replace 0189's stand-in and flip A033's placeholder-registry entries to raster
- Set the pack to integrated: `python implementation/backlog/assets.py set A033 integrated`.

  - done when: `python tools/check_prop_art.py` and `python tools/show_art.py --props --check` pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures by day and by night of the art in the real game, opened and looked at, in `implementation/shots/0215/`
  - done when: the sim and data hashes are unchanged (art never moves them)

### 0216 - Art: the peddler

Waits for Codex art A034.  Likely files: `assets/art_source/npc/, assets/art_source/props/, assets/art_source/manifest.json, tools/check_station_art.py, tools/check_npc_art.py (new), tools/verify.py`.

The peddler at the stall and the stall's closed state get their approved art.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A034` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A034-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/npc` and `assets/art_source/props/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`check_station_art.FAMILY` for the closed stall; a new `tools/check_npc_art.py` wired into `tools/verify.py` for the peddler, saying why in the journal).
- Runtime names: idle (2-4), talk/wave (2-4) and the walk in/out side cycle (4-8, mirrored at runtime) at the farmer's scale and the pivot 0190 settled; the closed stall matches today's `shop` (32x40, pivot (16,36))
- Replace 0190's stand-ins and flip A034's placeholder-registry entries to raster
- Set the pack to integrated: `python implementation/backlog/assets.py set A034 integrated`.

  - done when: `python tools/check_station_art.py`, `python tools/check_npc_art.py` and `python tools/show_art.py --stations --check` pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures by day and by night of the art in the real game, opened and looked at, in `implementation/shots/0216/`
  - done when: the sim and data hashes are unchanged (art never moves them)

### 0217 - Art: the house in three tiers

Waits for Codex art A035.  Likely files: `assets/art_source/buildings/, assets/art_source/manifest.json, tools/check_house_art.py, src/ui/art_placement.gd, src/ui/house_view.gd`.

House tiers I, II and III get their approved exteriors, whole and hurt; tier III reads as a small fortified farmhouse.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A035` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A035-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/buildings/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`tools/check_house_art.py`, which hard-codes `house`/`house_hurt` and their window points today - extend it per tier).
- Runtime names: `house`, `house_hurt`, `house_2`, `house_2_hurt`, `house_3`, `house_3_hurt` with their slices (`house_<c>_<r>`, `house_2_<c>_<r>`...), `windows_xy`, `window_rects_xywh`, `light_xy` and `smoke_xy` on the same 6x4 footprint as today's house. The pack draws them at full density (128x128, pivot (64,120): today's 64x64 at 2.0), so take `house` out of `ArtPlacement.visual_scale`'s 2.0 list - it matches every file whose name starts `house_`, the tiers too - unless 0191 wrote a different density into the pack
- Replace 0191's code-marked stand-ins and flip A035's placeholder-registry entries to raster
- Set the pack to integrated: `python implementation/backlog/assets.py set A035 integrated`.

  - done when: `python tools/check_house_art.py` and `python tools/show_art.py --house --check` pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures by day and by night of the art in the real game, opened and looked at, in `implementation/shots/0217/`
  - done when: the sim and data hashes are unchanged (art never moves them)

### 0289 - Art: the morning report

Waits for Codex art A057.  Likely files: `assets/art_source/, assets/art_source/manifest.json, assets/art_source/ownership.json, tools/check_ui_art.py, src/tools/ui_art_showcase.gd, src/ui/placeholder_art.gd, src/ui/result_screen.gd`.

A small sunrise over the farmhouse heads 0138's morning report. Optional: if the owner declines the pack, the header 0138 drew becomes the shipped look and this task closes with a note.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A057` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- The one exception, because A057 is optional: if its status is `blocked` with the owner's decline in the note, do not wait. Delete A057's entries from 0120's placeholder registry (`src/ui/placeholder_art.gd`) and draw 0138's code-drawn band directly in `result_screen.gd`, so it is the final look and no longer a stand-in (or drop the header if it only made sense as art), quote the decline in the journal and close with `python tools/task.py done 0289`. `task.py next` never offers a task whose pack is not approved, so this path is run by hand or by 0290
- Use only the folder named in the pack's `CLAUDE-A057-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/<family>/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`tools/check_<family>_art.py`, `ArtPlacement` if needed).
- Family `ui`: one header at the canvas and pivot 0138 settled in A057's Deliverables table, drawn by `result_screen.gd` above the report through the lookup it already uses, replacing 0138's stand-in (delete A057's registry entries in `src/ui/placeholder_art.gd` once the raster lands at the same path); no text in it (the report's words stay strings), checked in its own section of `tools/check_ui_art.py` and shown in `ui_art_showcase.gd`
- Set the pack to integrated: `python implementation/backlog/assets.py set A057 integrated`.

  - done when: `python tools/check_ui_art.py` and `python tools/show_art.py --ui --check` pass with the header counted
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures of the morning report after a won and after a lost night, and of the farm around it by day and by night, opened and looked at, in `implementation/shots/0289/`
  - done when: The sim and data hashes are unchanged (art never moves them)
  - done when: On the decline path instead: `python tools/placeholders.py` no longer lists A057, a capture of the morning report shows the band drawn directly, and the journal quotes the owner's words

### 0292 - Options for the new controls

Ready to pick up.  Likely files: `src/app/settings.gd, src/app/input_actions.gd, src/ui/options_controls.gd, src/ui/options_game.gd, src/ui/guardian_cursor.gd, src/ui/main.gd, src/ui/world_view.gd, src/ui/forecast_panel.gd, src/ui/day_hud.gd, assets/locale/strings.csv, src/tools/input_v1.gd, src/tools/headless_v1.gd`.

The guardian's cursor, the night camera and the fishing bar each get the knob a player reaches for: how fast the cursor moves, whether the screen edge pans, how far a stick must tilt, a kinder fishing bar, and a forecast that stays up all day.

- Five keys in `Settings.DEFAULTS` (`src/app/settings.gd`), each in its page's `resets` and with a row: `controls/cursor_speed` (percent of the repeat rate 0131 shipped, steps 50/75/100/150/200), `controls/edge_pan` (on), `controls/pad_deadzone` (0.10-0.50 in 0.05 steps, default what 0121 shipped - `project.godot` has 0.2 on the move actions today), `gameplay/fishing_assist` and `gameplay/forecast_all_day` (both off). A key 0130, 0131 or 0180 already made is reused, never doubled
- Cursor speed, edge pan and deadzone are input preferences, not rules: 0131's hold-repeat in `guardian_cursor.gd` scales its rate by cursor speed, 0130's edge-band pan in `main.gd`/`world_view.gd` runs only with edge pan on, and `InputActions` applies the deadzone with `InputMap.action_set_deadzone` to the move, pan and cursor actions (0121, 0130, 0131). Their step lists sit with their rows on the options pages, the way `OptionsA11y.ROWS` and `Video.FPS_CAPS` keep theirs - preferences, not balance, so not in `game_data.gd`, and neither hash moves for them
- Fishing assist: 0180 shipped it as a rule - a run flag written through an intent from its Settings key, the zone wider and the marker slower, never read by core from `Settings` - and left only the row. Reuse 0180's key (rename nothing) and its levers. If 0180 left a gap (core reading `Settings`, a strength with no `# LEVER` in `GameData.FISHING`, a view-side widening that changes catches), fix it here and say so: a new lever moves DATA and a rule fix moves SIM, on purpose, both numbers in the journal; otherwise neither hash moves
- Forecast all day is view only: 0158's panel (`src/ui/forecast_panel.gd`, shown by `day_hud.gd`) shows from 06:00 instead of 18:00 and still hides once START is pressed. The forecast is a pure function of (seed, date), so seeing it at breakfast can never change the night
- Rows where a player looks for them: cursor speed, edge pan and deadzone under a heading on the controls page (`OptionsControls`), fishing assist and the forecast on the game page (`OptionsGame`). Both pages still work by keyboard, mouse and pad, and RESET puts the new keys back
- Applied live and kept: a change made with a night up behind the options moves the cursor and the camera at once, the way `SimDriver` hears `gameplay/night_speed` through `Settings.changed`, and every value survives a restart through `settings.cfg`. New keys alone need no `Settings.VERSION` bump
- Strings in `assets/locale/strings.csv` with real widths, under each page's prefix (`CTL_CURSOR_SPEED`, `CTL_EDGE_PAN`, `CTL_DEADZONE`, a `CTL_*` heading, `GAME_FISHING_ASSIST`, `GAME_FORECAST_ALL_DAY`), toggles reusing `OPT_ON`/`OPT_OFF`: e.g. CURSOR SPEED / VELOCIDADE DO CURSOR, EDGE PAN / ROLAR PELA BORDA, STICK DEADZONE / ZONA MORTA DO ANALÓGICO, FISHING ASSIST / PESCA ASSISTIDA, FORECAST ALL DAY / PREVISÃO O DIA TODO

  - done when: `_case_0292_options` in `src/tools/input_v1.gd` steps each new row by keyboard and by pad, finds the value in `Settings` and in a reloaded `settings.cfg`, and RESET puts it back
  - done when: the same case at night: with edge pan on, a pointer held in 0130's edge band for a second moves the camera, and with it off it does not (a synthetic mouse motion into the band, or the edge-pan helper 0130's pan reads if the headless window cannot hold focus); a stick tilt under the deadzone moves no cursor and one over it does; a held d-pad at 200 crosses about twice the cells it crosses at 100
  - done when: the same case by day: with forecast all day on, the panel is up at 08:00, and with it off it is hidden at noon as `_case_0158_panel` expects; with fishing assist on, the next cast carries 0180's assist flag, and with it off it does not
  - done when: `_task_0292_options` in `src/tools/headless_v1.gd`: no file in `src/core/` names `Settings`; `Forecast.tonight` gives the same record at 08:00 as at 18:00
  - done when: the controls and game pages captured at 1920x1080 in both languages (`$GODOT --path . --position -4000,-4000 --script res://src/tools/capture_menus.gd -- --out=res://implementation/shots/0292/`, then again with `--pt_BR`) and opened: no label runs off its row and no two rows overlap

### 0194 - The day's economy

Waits on 0193.  Likely files: `src/core/game_data.gd, tools/balance.py, src/tools/autoplay.gd, implementation/BALANCE.md, src/tools/headless_v1.gd`.

The day's money is tuned on purpose: a price for every item, and targets per season so that a good day buys about one new defence (plan section 5's rule of thumb).

- One reviewed price table for every item: `SELL_PRICE`, seed and animal prices, upgrade and building costs; `check_stall` and `check_chain` pass
- Money-per-day targets by season, as `# LEVER`s or a table the check reads: a well-worked day at the start of each season buys about one new defence
- `tools/balance.py` gains sweeps of day strategies - crops, fishing, mining, animals, artisan goods - over a spring and a summer day, headless and outside the suite; it still refuses a dirty tree and restores `game_data.gd`
- A BALANCE.md section with money per strategy per season against the target, and every lever moved
- No single strategy wins every season: the day has several ways to earn, which is what 0196 asks
- DATA moves on purpose (the target table goes into `digest()`); SIM moves if a price or a stock the determinism scenario meets changes - record both

  - done when: `_task_0194_economy` in `src/tools/headless_v1.gd`: a computed (not simulated) day of each strategy lands inside its season's target band
  - done when: A `tools/balance.py` run writes the BALANCE.md section, and the journal quotes its numbers

### 0195 - Teaching the new day

Waits on 0194.  Likely files: `src/core/game_data.gd, src/ui/tips.gd (new, e.g.), src/ui/tutorial_prompt.gd, src/ui/main.gd, src/app/save.gd, assets/locale/strings.csv, src/tools/shot.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd`.

The new day explains itself once: tilling grass, the seasons, the shipping bin, the fishing bar and the animals each get one tip, at the moment they first matter.

- Tips, not day-one lines: `MAX_TUTORIAL_LINES` still caps the first day. A tip fires from the state (the first stand on open grass with the hoe, the first morning of a new season, the first stand by the bin, the first bite, the first animal bought) and is remembered in the profile so it never shows twice
- Tips live in the view: `src/ui/` reads the state for the trigger and the profile (`Save.read_profile`/`write_profile`) for what was shown, through a pure `due(state, profile)` the headless group can call. No rule in `src/core/` reads them (their table may sit in `game_data.gd` beside `TUTORIAL`, as data), so SIM must not move; they never gate or pause anything. The day-one lines remember themselves in the `gameplay/tutorial_seen` Settings key (`tutorial_prompt.gd`): say why the tips use the profile instead, or use Settings too
- `check_tutorial` (or a new check) covers the tip table in `game_data.gd`: unique, short, naming a string key that exists. List it in `digest()` (DATA moves) or exempt it in `_task_0112_digest` as view text - say which
- Strings in both languages, each fitting its control (`tools/i18n_check.py`); a tip sits on the thing it describes (`tutorial_prompt.gd`)
- The guided Spring 1-7 is 0293's, not here

  - done when: `_task_0195_tips` in `src/tools/headless_v1.gd`: each tip fires once on its trigger and never again with the profile flag set
  - done when: `_case_0195_tips` in `src/tools/input_v1.gd`: a tip appears on the first bite and is dismissed
  - done when: A new `tips` scenario: `python tools/shot.py 0195 tips --fhd` shows two tips in place; opened and looked at

### 0196 - Checkpoint: is the day good on its own?

Waits on 0194, 0195.  Likely files: `implementation/PROGRESS.md, implementation/shots/0196/, src/tools/autoplay.gd, implementation/prompts/`.

**The plan's Phase 3 checkpoint.** A spring day and a summer day earn money in different ways, and the day is fun even without thinking about the night. Phase 13 and everything after it waits on this answer.

- Play a spring day and a summer day in the real game, and run the autoplayer through the same days; compare where the money came from
- FHD captures of both days at morning, noon and dusk in `implementation/shots/0196/`, opened and looked at
- Answer honestly in the journal: is the day fun even without thinking about the night? What drags, what is busywork, what is missing
- If the answer changes the plan, edit the later prompts (0197 on) before they run, and say which
- If the answer is no, mark this task blocked with the reason, so phase 13 does not start on a day that does not work
- Change no rule here, so neither hash moves: fixes go into later prompts or new tasks

  - done when: The journal says, with numbers, how a spring day and a summer day each made their money - and that they differ
  - done when: The journal answers the question in one paragraph a reader could disagree with
  - done when: The captures are in `implementation/shots/0196/` and the journal says what each one shows

### 0293 - The first week, taught

Waits on 0195.  Likely files: `src/core/game_data.gd, src/core/tutorial.gd, src/ui/tutorial_prompt.gd, src/app/settings.gd, tools/goldens/, assets/locale/strings.csv, src/tools/shot.gd, src/tools/headless_check.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd`.

A stranger learns 1.0 the way they learned the MVP's first day - one short line, on the thing it is about, gone when it is done - but spread over Spring 1 to 7, so the first morning is not a lecture and the forecast, the bin and the rod arrive when they first matter.

- Start from what 0141 and 0195 left in `GameData.TUTORIAL` and write the week down as data: each step gains the Spring date it may first show (e.g. `from_day`, read against `Calendar.date`), in the order a week happens - day 1 chop, plant, water, the bed, the cursor, START and dawn; the bin and the stall once there is something to sell; the forecast at 18:00 of the first night with something new in it; the rod and the minigame mid-week; the season and the Full Moon by day 7. Where a 0195 tip already teaches a lesson (the bin, the first bite, a new season), the week takes it over or leaves it to the tip - one line per lesson, never both. The schedule is the task's to justify in the journal
- It still watches and never gates (the `Tutorial` header): `Tutorial.tick` keeps checking every step, a step done early by a player who found it alone is done, and `current()` and `points_at()` only offer steps whose day has come. Keep 0141's assert that ignoring the prompts reaches the same night with the same state apart from `tutorial` - one day and night in the suite, never Spring 1-7
- Every step finishes on something the state shows: the forecast step is done when the night it forecast begins, not when a panel was looked at - the rules cannot see the screen
- Short, per day: `check_tutorial` counts the week's lines per day against a new `# LEVER` `MAX_TUTORIAL_LINES_PER_DAY` (3-7, start at 5) and the week against `MAX_TUTORIAL_LINES`, whose comment and range are raised only as far as the week needs, with the reason in the journal (0195's tips keep their own check and do not count per day). `MAX_TUTORIAL_LINE_LENGTH` is unchanged, and no line describes the switch of reality - the bed and the fade show it
- Never twice, but the new lessons still reach a returning player: `gameplay/tutorial_seen` is one bool, so whoever finished the 0.1 day one would never see the bed or the cursor. Unless 0141 or 0195 already changed it, make it the list of step ids seen, with a `Settings.VERSION` bump whose `Settings._migrate` turns `true` into the 0.1 steps. The bump gets its golden: a 0.1 `settings.cfg` fixture in `tools/goldens/` (e.g. `settings-v1.cfg`, in the format `git show bea89a88:src/app/settings.gd` saves, with a non-default language, volumes, a rebind and `tutorial_seen` true) - the fixture goes in even if 0141 or 0195 already changed the key
- Each line sits on its thing through `tutorial_prompt.gd`: the bed, the cursor's cell, the START button, the forecast panel, the bin, the pond. At night the line follows the camera, not the sleeping farmer
- Rewrite in place what assumed every step shows on day one: `_task_0041_tutorial` in `headless_check.gd`, 0141's `_task_0141_tutorial`/`_case_0141_tutorial` and 0195's tip groups in `headless_v1.gd`/`input_v1.gd`
- Every line is a `TUT_*` row in both languages with a real width. `TUTORIAL` is in `GameData.digest()`, so DATA moves on purpose; SIM moves only if the done list in the determinism scenario changes - say which, both numbers in the journal
- What the loop cannot know - whether a stranger reads them - becomes a question in 0295's tester note, not a guess here

  - done when: `check_tutorial` passes, and the journal has the week as a table: day, steps, lines
  - done when: `_task_0293_first_week` in `src/tools/headless_v1.gd`: a scripted player that only does what `Tutorial.current()` and `points_at()` ask gets from Spring 1 at 06:00 to Spring 2's morning with the house standing and every day-1 step done (going to bed early, so the group stays a few seconds); no step is offered before its day
  - done when: the same group: the 0.1 `settings.cfg` fixture loads with its language, volumes and rebind kept, every key it lacks at its `Settings.DEFAULTS` value, and its `tutorial_seen` of `true` migrated to the 0.1 step ids, so only the new steps are offered
  - done when: 1920x1080 captures of the bed line, the cursor line at night and the forecast line at dusk, in both languages (new scenarios such as `tut_bed`, `tut_cursor`, `tut_forecast`: `python tools/shot.py 0293 tut_bed tut_cursor tut_forecast --fhd` and again with `--pt_BR`), opened: each line is on its thing and nothing on screen covers it

### 0218 - Room for more fields and more bodies

Waits on 0196.  Likely files: `src/core/pathing.gd, src/core/entities.gd, src/core/towers.gd, src/tools/perf_check.gd, tools/perf.py, tools/perf_baseline.txt, src/tools/headless_v1.gd`.

Nothing changes for the player. The decoy, the bait, the digger and the rat swarm are coming, and today every wall placed re-sweeps every path field and every tower scans every zombie; make room before adding to either, with the game playing exactly as it does now.

- A named-field registry in `Pathing`, in code (a const table and one accessor such as `Pathing.field(state, name)`): a field is registered with its seeds, its cost rule and the state keys it is stored under, and is built on first request for the current `grid_version`, never on a rebuild nobody asked for. Today's three (`flow`, `flow_open`, `flow_hunt` and their `*_cost` arrays, under `flow_version`) keep being built eagerly in `refresh` exactly as now, because those keys are folded into SIM. The registry is for 0224's lure field and 0250's digger field, which add their own storage keys (and move SIM) then
- `Entities.ids` stops sorting on every call, on the strength of an asserted invariant: ids are handed out ascending and never reused (`next_entity_id`), so the table's own order is already ascending - assert it after spawns, kills, `Enemies.withdraw` and a save round trip (if a loaded table does not keep the order, sort it once where the save is read, e.g. `State.reconcile`). No static cache shared between states
- A spatial bucket for `Towers._acquire`, built once per `Towers.tick` as a local (never stored in the state) from the entity cells, so a tower looks only at the buckets its reach touches. It must pick exactly what the full scan picks for every `TARGETING` mode, ties to the lowest id included; `acquire_for` keeps working for the tests
- Both hashes unchanged is the bar. `State.hash_of` folds every state key, caches included, so nothing here may add a key to a new game's state. If that proves impossible, prove play identical (kills, house HP and every entity cell at fixed ticks of one seeded night, before and after) and record both numbers in `implementation/PROGRESS.md`
- A swarm scenario in `src/tools/perf_check.gd`: a few hundred walkers (the rat swarm's stand-in until 0248) against the worst case's towers, with its own `PERF` lines (e.g. `swarm_tick`, `swarm_towers`, `swarm_enemies`) and a `COUNT` of bodies. `PerfNames` is unchanged: no system is added
- The swarm must sit inside `TICK_BUDGET_US` (8333 us), and `tools/perf.py` holds only `night_tick`, `day_tick` and `path_refresh` to a budget today: add `swarm_tick` to that list so the bar is enforced. If it does not fit, write down what it would take rather than shrinking the swarm
- Accept the new baseline with `python tools/perf.py --accept` and say in the journal why each number moved

  - done when: `_task_0218_perf_ground` in `src/tools/headless_v1.gd` asserts the bucketed acquire equals the full scan over a seeded crowd for all four targeting modes, `Entities.ids` is ascending after spawns, kills and a save round trip, and a registered field is not built until it is asked for
  - done when: `python tools/perf.py --report` shows `night_towers` below its baseline at the start of this task (1028 us when this was written) on the old worst case, and `python tools/perf.py` passes with `swarm_tick` inside the tick budget
  - done when: The journal has the perf table before and after

### 0219 - Essence

Waits on 0196.  Likely files: `src/core/rewards.gd, src/core/tech.gd, src/core/game_data.gd, src/ui/night_hud.gd, src/ui/result_screen.gd, src/ui/tech_panel.gd, assets/locale/strings.csv, implementation/BALANCE.md, src/tools/headless_check.gd, src/tools/headless_v1.gd`.

The night stops paying like a day. It hands over essence - today's technology points under a new name - for holding the farm, and a smaller purse, so money is what the day earns and the night spends (plan section 4.6).

- Keep the id `tech` (`GameData.TECH`, `Rewards._is_tech`, the saves): only the words change, so no `State.VERSION` bump. `ITEM_TECH` becomes essence / essência and every line that names the currency follows (`DESC_TECH_COST`, `TECH_HELD`'s 'points', any result or HUD line); the tree itself may stay the technology tree (`TECH_TITLE`)
- Earn rules as LEVERs in `GameData.REWARDS` and `TECH_BONUSES`: a night won pays `tech_points`; the three bonuses stay (house untouched measured against `Phases.house_full`, as 0114 left it); a Full Moon night (`Calendar.is_full_moon`, 0152) multiplies the night's essence by a percent LEVER (100-300), its own line in `Tech.would_pay`; `GameData.validate()` refuses a percent under 100. `nights_paid` still stops a night paying twice
- The night's money shrinks: `base_money`, `money_per_night` and the material handout (`resources`, `resources_per_night`), read through 0150's `Rewards.night_step`, come down to numbers argued against 0194's money-per-day targets in `implementation/BALANCE.md`; the journal says what a spring night paid before and after
- The bounty is paid for kills only. `Rewards._money_from` already reads `killed_by_kind`; assert that survivors who walk off at dawn (0137, `Enemies.withdraw`) pay nothing and are not counted as killed
- Essence on screen: the night HUD shows what is held (plan section 9) and the morning report of 0138 has a '+N essence' line itemised from the lines `Tech.would_pay` gave inside `Rewards.settle`, kept in `payout` for the screen - after `Tech.award` the night is paid and `would_pay` answers empty. The icon is the existing tech icon through the placeholder road until A036 is integrated by 0235
- Asserts that pin night money or technology (`_task_0061`, `_task_0062`, `_task_0068` and whatever 0150 left of them) are rewritten in place in `src/tools/headless_check.gd` to read the LEVERs rather than literals; `tools/i18n_check.py` is clean in both languages
- SIM and DATA both move on purpose (the payout and the REWARDS table): record the old and the new numbers in `implementation/PROGRESS.md`

  - done when: `_task_0219_essence` in `src/tools/headless_v1.gd` asserts a won night pays `tech_points` plus each bonus earned, a Full Moon night pays the multiplied amount, a replayed night pays no essence, and a dawn win with survivors pays bounty for the kills only
  - done when: `python tools/shot.py 0219` captures of the night HUD and the morning report say essence, opened and looked at
  - done when: The BALANCE.md section sets a spring night's money and essence beside a spring day's money

### 0223 - Defences sleep under tarps

Waits on 0196.  Likely files: `src/ui/world_view.gd, src/ui/transition.gd, src/ui/placeholder_art.gd, src/tools/shot.gd, src/tools/headless_v1.gd, implementation/backlog/packs/A044-tarps.md`.

By day the defences sleep under tarps and the farm looks like a farm; when the night comes the covers come off with the wake the transition already plays (plan section 5).

- View only: no rule reads a tarp, and both hashes stay where they are
- In the DAY phase every defence of a tarp family is drawn covered; during the switch into the night the tarps come off with the wake pass in `transition.gd` (`WAKES` kept - the generator still wakes, without a tarp) and go back on when the day begins
- Decide which families get tarps and why: probably the towers and the other standing one-cell defences, not barriers, mines or traps (a covered wall is still a wall, a covered mine is a lie). Drive the unveil from one list in the view so a later defence joins by being listed; 0234 lists the families of 0224-0231, which leave the list alone
- A hurt or wrecked defence shows its state by day - through the tarp or instead of it, decide - so the morning never hides damage
- Drawn through the placeholder road of 0120: a code-drawn or tinted cover per footprint (32x48 towers, 16x32, 16x24) with two unveil frames, until A044 is integrated by 0243
- Write the chosen families and footprints into the Deliverables table of `implementation/backlog/packs/A044-tarps.md`; 0234 settles the final list

  - done when: `_task_0223_tarps` in `src/tools/headless_v1.gd` asserts every id in the view's tarp list is a `DEFENCES` id and nothing in `src/core/` mentions a tarp
  - done when: `python tools/shot.py 0223` captures of the same towers by day (covered), at dusk and at night (uncovered), opened and looked at

### 0227 - The pumpkin catapult

Waits on 0196.  Likely files: `src/core/game_data.gd, src/core/towers.gd, src/core/ammo.gd, src/ui/names.gd, src/ui/describe.gd, src/ui/sfx.gd, assets/locale/strings.csv, src/tools/shot.gd, src/tools/headless_v1.gd`.

A lobbed splash that burns pumpkins instead of gunpowder, so an autumn harvest becomes an autumn defence (plan section 5).

- Id `catapult` (never `pumpkin`, which is the crop): `shape` splash, `aim` ballistic with `flight_ticks`, `ammo` {pumpkin: 1}, a cost in wood and pumpkins, `season` autumn (0193's field - pumpkins are autumn's, so `check_seasonal_supply` fails it as spring). Not a cheaper mortar: shorter reach, no gunpowder, a reason of its own - the journal says when it is the better buy
- It has `damage`, so `_task_0085_night_sounds` wants a `Sfx.TOWER_SOUNDS` entry: borrow `sfx/mortar` until 0283 gives it a thunk
- `check_ammo` refuses ammunition no recipe makes. Allow what a crop yields (the `CROPS` table) as well as recipe outputs, or add a recipe - decide, and keep the rule's intent: a tower must be able to fire a proper shot
- An empty pumpkin pool gives the weak shot every tower has (`Ammo.weak_damage`, `Ammo.weak_reload`), never a silent catapult
- `TOWER_LEVELS` 1-3 for `catapult`, gated on the same tree nodes as the other towers (`true sights`, `oiled works`)
- `Names.KEYS` `DEF_CATAPULT`, a `Describe.defence` line, strings in both languages; drawn through the placeholder road (a tinted 32x48 tower per level and state, an 8x8 pumpkin shot, a 4-frame splat) until A039 is integrated by 0238
- DATA moves (a row, its levels, the ammunition rule); SIM moves only if a state key appears or the scenario builds one - record both numbers

  - done when: `_task_0227_catapult` in `src/tools/headless_v1.gd` asserts a pumpkin lands where it was aimed with the splash falloff the LEVER claims, an empty pool still fires weakly, and levels 1-3 read through `Building.entry_at`
  - done when: The Deliverables table of `implementation/backlog/packs/A039-catapult.md` states the final geometry this task settled (levels, states, muzzle points, the shot, the splat)
  - done when: `python tools/shot.py 0227` captures of a volley landing, opened and looked at

### 0230 - The electric fence

Waits on 0196.  Likely files: `src/core/game_data.gd, src/core/enemies.gd, src/ui/world_view.gd, src/ui/placeholder_art.gd, src/ui/names.gd, src/ui/describe.gd, assets/locale/strings.csv, src/tools/headless_v1.gd`.

A barrier like the wooden fence, except whatever bites it is thrown back stunned for a moment - a winter answer that needs the generator running (plan section 5).

- Id `electric_fence`: a barrier (`path_cost` and `hp` LEVERs, within `WIDEST_STEP` by `check_pathing`) with an `energy_draw`, a cost in copper (0176), with wood if it needs a frame, and `season` winter (0193's field). The shock is a stun, not `damage`, so no `Sfx.TOWER_SOUNDS` entry (`_task_0085_night_sounds` wants one exactly when a defence has `damage`; 0283 adds the zap)
- Stun in `Enemies._gnaw`: an enemy biting an electric fence is stunned for a LEVER of ticks (1-3 s) - a generic entity counter (any source may set it) read at the top of `Enemies._walk`, so a stunned enemy neither moves nor bites; 0233's farm bell writes the same counter. The bite still lands; decide whether bosses get a shorter stun or none. `check_defences` refuses a stun of zero ticks
- Needs power, degraded never dead: on a short farm the stun is scaled down by `Power.percent`, never to zero
- Joins like the fence: `WorldView.barrier_mask` joins only `wall` and `fence` today - add the electric fence (decide whether it meets a wooden one) and the placeholder road's `connected` flag, so the joins draw before the art arrives
- `Names.KEYS` `DEF_ELECTRIC_FENCE`, a `Describe.defence` line, strings in both languages; drawn through the placeholder road (fence-style modules for the 16 masks, whole/hurt, a wreck, a 3-frame zap) until A042 is integrated by 0241
- DATA moves (a new row); SIM moves only if the scenario meets one or a state key appears - record both numbers

  - done when: `_task_0230_electric_fence` in `src/tools/headless_v1.gd` asserts a walker that bites it stands still for the stun and then bites again, a short farm shortens the stun without removing it, and the field prices it like a barrier
  - done when: The Deliverables table of `implementation/backlog/packs/A042-electric-fence.md` states the final geometry this task settled
  - done when: `python tools/shot.py 0230` captures of a joined run of electric fence, opened and looked at

### 0232 - Powers as a list

Waits on 0196.  Likely files: `src/core/ability.gd, src/ui/night_hud.gd, src/ui/main.gd, src/ui/world_view.gd, src/ui/pixel_effects.gd, src/tools/effect_showcase.gd, src/tools/perf_check.gd, src/tools/headless_check.gd, src/tools/input_check.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd`.

Nothing changes for the player. The one flare becomes the first entry of a list of powers, each with its own cooldown and aim cell, so 0233 can add three without a second copy of the cooldown and aiming code.

- `Ability` takes a power id: `ready(state, id)`, `cooldown_left(state, id)`, `charge_percent(state, id)` and `use(state, id, cell)` with the aim cell from 0135's `ability_cell` intent. The flare is the only power and behaves exactly as it does now
- Hashes unchanged is the bar. `state["ability"]` is in `State.TABLES` and folded into SIM, so the flare keeps its keys (`cooldown`, `flare`, `flare_ticks`, `flares`) and no new state key appears until 0233 adds a power; `intent.ability` stays the flare's edge for the same reason; `GameData.ABILITY` stays byte-identical so DATA does not move
- If a key truly has to move, prove play identical (a scripted night with two aimed flares, before and after) and record both numbers in `implementation/PROGRESS.md`
- `Ability.recharge` and `Ability.put_out` work over every power; the `flare_percent` tree bonus stays the flare's
- Every caller moves to the new signatures - today `main.gd`, `night_hud.gd`, `world_view.gd`, `pixel_effects.gd`, `effect_showcase.gd`, `perf_check.gd`, `_task_0054` as 0135 left it and the input cases (grep `Ability.` for whatever 0135-0142 added: the shot scenarios, the autoplayer) - and no flare-only path is left

  - done when: `_task_0232_powers_list` in `src/tools/headless_v1.gd` asserts the flare's cooldown, aim and damage through the new API match the numbers before the refactor, and an unknown power id is refused without touching the state
  - done when: `_case_0135_flare_aim` in `src/tools/input_v1.gd` passes with nothing changed but its calls moved to the new API

### 0246 - Bosses in general

Waits on 0196.  Likely files: `src/core/combat.gd, src/ui/night_hud.gd, src/ui/log_panel.gd, src/ui/enemy_motion.gd, src/ui/enemy_deaths.gd, src/ui/pixel_effects.gd, src/ui/world_view.gd, src/ui/sfx.gd, assets/locale/strings.csv, tools/check_giant_art.py, tools/show_art.py, src/tools/giant_showcase.gd, src/tools/shot.gd, src/tools/headless_check.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd`.

Three more bosses are coming, and everything that knows about a boss today knows about the Giant by name. Make the bar, the counters, the arrival line, the sounds and the art checks work for anything with `is_boss`, so 0253-0255 are a data entry and a behaviour each.

- `Combat.boss_here` stays the lowest-id boss on the farm; add `Combat.bosses_here(state)` (sorted ids) and `Combat.full_hp(state, id)` (the table's `hp` today), so the boss bar (`NightHud._refresh_boss` reads `ENEMIES[kind]["hp"]` today) reads a body's full health from the one place 0257's elites will change; `Describe.enemy` describes a kind and keeps the table's number
- Per-boss counters without a new State key: `Combat.bosses_down_of(state, kind)` reads `killed_by_kind_all_run` (RUN_DATA) for `is_boss` kinds; `bosses_down` stays the run total `Run` reports. Raising `boss_arrived` for any `is_boss` is 0153's, not this task's
- The night HUD's boss bar (`NightHud._refresh_boss`, or wherever 0139 moved it) names whichever boss is up, adds `x2` when more than one is alive (Endless already sends two Giants) and keeps the wind-up flash for any boss with `telegraph_ticks`
- A boss intro line: `LOG_BOSS` ('the giant is coming') becomes one literal key per boss in a const map in the view (`BOSS_INTRO_GIANT` first; key,width,en,pt_BR rows in `assets/locale/strings.csv`), shown as a banner on `boss_arrived` and as the log line; delete the `LOG_BOSS` row, since `tools/i18n_check.py` fails on unused keys
- View hard-codes on the Giant's id become boss-generic where the art follows the Giant's pose names (`EnemyMotion.TRACKED` and `_giant_pose`, the five death frames in `EnemyDeaths`, the impact offset in `PixelEffects`, the `giant_windup_` test in `WorldView`): a boss with no authored poses falls back to the ordinary path, and the Giant draws exactly as before. `Sfx` too: `_watch_bodies` announces any `is_boss` on arrival with no position, `nearest_by_kind` leaves every boss out and `_ducks` ducks for any boss voice - so 0253-0255 borrow `sfx/roar_giant` in `ENEMY_SOUNDS` until 0284 voices them
- `tools/check_giant_art.py` becomes table-driven (family -> motion counts, canvas, pivot, generation task; only the Giant today) and its exact `migrated_enemies() == {five}` becomes a subset check, so a new enemy family cannot fail it; `giant_showcase.gd` takes the family and `tools/show_art.py` routes a new `--boss=<family>` to it (`--giant` unchanged) for the leaves 0266-0268
- Rewrite `_task_0058_giant`'s 'the only boss in the table' and 'outlasts every other enemy' asserts as every boss against every non-boss (hp, armour, walking `ticks_per_tile`), because 0247-0255 add both kinds
- Hashes unchanged: helpers, view and tests only

  - done when: `_task_0246_bosses` in `src/tools/headless_v1.gd`: two Giants on the farm give `bosses_here` both ids in order; killing one moves `bosses_down_of(state, &"giant")` and `bosses_down` by one each; every `is_boss` entry has an intro key in the map and in the strings table
  - done when: `_case_0246_boss_bar` in `src/tools/input_v1.gd`: a spawned Giant raises the bar and the banner, `Sfx.nearest_by_kind()` has no entry for it, and the bar goes when it dies
  - done when: `python tools/check_giant_art.py` and `python tools/show_art.py --giant --check` pass and report the Giant as before
  - done when: `python tools/shot.py 0246 boss` (a new scenario: a Giant winding up) opened and looked at: bar, name and banner overlap neither the hotbar nor the time to dawn

### 0281 - The new day's sounds

Waits on 0196.  Likely files: `tools/gen_sfx.py, assets/sfx/, src/ui/sfx.gd, src/tools/headless_check.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd`.

Going to bed, waking up, the shipping bin, the peddler, the machines and the new ores each make their own noise, so the longer day of 1.0 sounds as varied as it plays. View only: neither hash moves. (The animal calls are 0286's and the dog's bark 0283's - moved there so this fits one invocation.)

- New recipes in `tools/gen_sfx.py`, built from the same `Noise` and primitives (no `random`): bed (under the blanket), wake (a stretch at 06:00), pass-out (a thud at 02:00), the morning payout coins, the peddler's stall bell, and the tool upgrade (an anvil ring when it is ordered, a bright ting when it is delivered next morning)
- And the farm's: one working sound per artisan machine (0187's keg and jar, 0188's dairy, loom and mill) and copper, coal and gold variants of `mine` for 0176's nodes. No animal voices here: 0286 writes the calls heard near the coop and the barn and 0283 the dog's bark for its power
- Furniture and moments: everything played per action keeps the rule `_task_0084_day_sounds` enforces (a peak of at most 0.6 - rendered at `SOFT_PEAK` - under 0.6 s, and quieter and shorter than the bite, so the bite stays the loudest and longest day sound). Bed, wake, pass-out, the morning coins, the stall bell and a delivered tool happen once or twice a day: give them their own list and peak in `gen_sfx.py` (e.g. `MOMENT_SOUNDS`, below `ALARM_PEAK`, joined into `SOUNDS`) and teach that group the named exception rather than loosening its rule
- `Sfx` hears them from the state and `src/core/` never calls `Audio` nor gains a key for a sound: bed and pass-out on the phase leaving DAY with 0127's `House.asleep` and 0128's `house_visit.passed_out`, wake on 0138's morning, the payout as ONE coins sound when 0189's bin is paid at `begin_day` (never one per coin, never the night's reward; `_watch_money` resets outside DAY and swallows that rise, so read the bin emptying), the stall bell when 0190's `STALL_OPENS` and `STALL_CLOSES` pass, at the stall's cell, the anvil when 0173's pending upgrade appears and the ting when it is handed over
- A per-target table in `src/ui/sfx.gd` (e.g. `TARGET_SOUNDS`, occupant id -> sound) consulted before `VERB_SOUNDS` with the cell the action already carries: copper, coal and gold nodes sound like their ore and each machine like itself when a job goes in; a target absent from it falls back to the verb's sound
- Walk `Interact.DAY_ONLY` against `Sfx.VERB_SOUNDS`: every verb 0165-0195 added (0189's `ship` - the bin's lid and drop -, 0185's truffle dig, whatever else the list holds now) was mapped to a borrowed file to keep `_task_0084_day_sounds` green; each gets its own recipe, and two verbs share a file only where the journal says why
- Every new file is reached by the checks: the per-target table goes into the `wanted` list of `_task_0084_day_sounds` (so the furniture rule measures it), the moment list into the `heard` set its 'nothing in the folder is unreached' assert builds but not into the furniture loop - that assert fails on a WAV nothing asks for
- The numbers live in `gen_sfx.py` and `sfx.gd`, not in `game_data.gd` - the `Sfx.GROAN_EVERY_SECONDS` reasoning: a noise changes no rule and must not move the data hash

  - done when: `_task_0281_day_sounds` in `src/tools/headless_v1.gd`: every new id is a file, per-action sounds keep the furniture rule, the moment list is named and stays under the alarm, and ore and machine targets resolve to their own sound while an unknown target falls back to the verb's
  - done when: `_case_0281_day_moments` in `src/tools/input_v1.gd`, reading `Audio.last_played()` and `Audio.plays_of()`: going to bed plays the bed sound once, mining a copper node plays the copper variant and not `sfx/mine`, and a morning with items in the bin plays the coins exactly once
  - done when: `_task_0084_day_sounds` and `_task_0085_night_sounds` pass; `python tools/gen_sfx.py --report` lengths and peaks of every new sound are in the journal

### 0282 - The sounds of the fishing minigame

Waits on 0196.  Likely files: `tools/gen_sfx.py, tools/gen_music.py, assets/sfx/, assets/music/, src/ui/sfx.gd, src/tools/headless_check.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd`.

The minigame of 0180 can be played by ear as well as by eye: a tick from the bar, a hit, a miss, the catch, and a fanfare when one of 0182's legendaries comes out of the water. View only: neither hash moves, and no state key is added to be heard.

- Recipes in `tools/gen_sfx.py` for tick, hit, miss and catch. All four are furniture (at most `SOFT_PEAK`, shorter than the bite), so `_task_0084_day_sounds` still finds the bite the loudest and longest day sound: the bite opens the window, these only follow it
- The tick marks the marker turning at an end of the bar or entering the zone (pick one and say why), never every frame
- `Sfx` reads hit, miss and catch off 0180's minigame state the way `_watch_fishing` reads `Fishing.is_biting`: a hit or a miss is the edge the press intent left in the state, the catch is the cast ending with a species landed. An assisted hit (0180's option) sounds like any other hit
- The legendary fanfare is music, not furniture: a short cue in `tools/gen_music.py` beside `sting` (Music bus, at most `STING_PEAK`, a `PIECES` entry so `--check` knows it) built on `MOTIF`, so the year's tune answers the catch. `Sfx` asks `Audio.play` for it when the species landed is one of 0182's legendaries, and the ordinary catch is skipped then
- Decide what becomes of `sfx/reel` (the MVP's one-press reel): kept as the line coming in under the minigame, or retired with its recipe and its `VERB_SOUNDS` entry - never left as a file nothing plays. `reel` is in `Interact.DAY_ONLY` today and `_task_0084_day_sounds` wants a sound for every verb there, so retire it only if 0180 took the verb out of that list
- Extend what `_task_0084_day_sounds` collects so every new file in `assets/sfx/` is reached; `python tools/gen_sfx.py --check` and `python tools/gen_music.py --check` are clean

  - done when: `_task_0282_fishing_sounds` in `src/tools/headless_v1.gd`: the four files exist and keep the furniture rule against the bite; the fanfare is in `assets/music/`, under five seconds and at most `STING_PEAK`, and its recipe reads `MOTIF`
  - done when: `_case_0282_fishing_sounds` in `src/tools/input_v1.gd`: a minigame driven through intents plays the hit for a press in the zone, the miss for one outside it and the catch on landing; a crafted legendary bite landed plays the fanfare and not the catch (`Audio.last_played()`)
  - done when: `gen_sfx.py --report` and `gen_music.py --report` numbers for the new sounds are in the journal

### 0220 - The technology tree by season

Waits on 0219.  Likely files: `src/core/game_data.gd, src/core/tech.gd, src/core/calendar.gd, src/ui/tech_panel.gd, src/ui/names.gd, assets/locale/strings.csv, src/tools/headless_v1.gd, src/tools/input_v1.gd`.

Each season opens a new floor of the tree, so summer's essence buys something spring could not and the tree grows with the year instead of being finished in the first fortnight (plan section 7).

- `TECH_TREE` rows gain a `season` (0 spring to 3 winter, the calendar of 0149). Today's twelve nodes are spring's floor; summer, autumn and winter each add one node per branch (production, defence, survival) - nine new nodes with notes
- The gate is the seasons the run has reached, not the season it is in: a winter node stays available in Year 2's spring. Put that question in one pure helper beside 0149's, e.g. `Calendar.season_reached(state, season)` (every season from Year 2 on) - 0233 and 0234 reuse it. `Tech.why_not_buy` refuses an unreached season with a new key (e.g. `WHY_NOT_YET_SEASON` and the season name, a `strings.csv` row in both languages), checked before the price
- Every new node gives a number a system already reads, or a new `Tech.bonus` key read by the one system that owns it. `Tech.bonus` returns the first owned node that gives a key, so a later tier improving an existing key needs a rule (best value wins, or a key of its own): decide, write it in `tech.gd` and assert it
- Price it the way task 0063 did: every node reachable in a year, not all of them, against `Tech.total_available()` over the calendar (0150); the arithmetic goes in the journal
- Leave the powers to 0233, which adds one survival node per season from summer; nothing here gives a power
- `tech_panel.gd` pages the tree by season (keyboard, mouse and pad), greys an unreached season with its reason and still fits 480x270. `Names.KEYS`, `Names.NOTES` and `TECH_*`/`TECHNOTE_*` rows in `assets/locale/strings.csv` for every new node, in both languages
- A `GameData.validate()` rule: every `season` is 0-3, `needs` never points at a later season, and each branch has a node in every season. DATA moves on purpose (the tree is in `GameData.digest()`): record it. SIM must not move - no state key is added and the determinism scenario buys nothing

  - done when: `_task_0220_tree_seasons` in `src/tools/headless_v1.gd` asserts a summer node is refused in spring with the season reason, is buyable once summer is reached and still in Year 2's spring, and the stacking rule for a repeated bonus key holds
  - done when: `_case_0220_tree_pages` in `src/tools/input_v1.gd` pages to summer and buys a node with the keyboard and with the pad
  - done when: `python tools/shot.py 0220` captures of the tree in spring and in autumn, opened and looked at: no node cut off, no two labels on top of each other

### 0221 - What the night leaves behind

Waits on 0219.  Likely files: `src/core/combat.gd, src/core/loot.gd (new), src/core/phases.gd, src/core/player.gd, src/core/state.gd, src/core/game_data.gd, src/core/tech.gd, src/ui/names.gd, src/ui/world_view.gd, src/ui/result_screen.gd, assets/locale/strings.csv, src/tools/headless_v1.gd, src/tools/input_v1.gd`.

The night leaves something for the morning: bones where zombies fell and, after a Full Moon, moon stones along the road the horde came by - picked up on the morning round and worth money, essence or fertiliser (plan sections 3.3 and 4.6).

- Loot is a RUN_DATA dictionary (cell index -> {item: count}) listed in `State.RUN_DATA` and adopted through an `initial()` (a small `src/core/loot.gd`). It is not an occupant - nothing walks round it or builds on it - and it survives `Farm.clear_rubble` at `begin_day`. Never name a key `moon_phase`
- Bones drop in `Combat._kill` on the cell the enemy died on: a per-kind count in `ENEMIES` (`bones`, LEVER 0-6, the Giant more; a row without `bones` drops none, so the enemies of phase 14 opt in), piled per cell up to a cap LEVER, no RNG. Survivors that walk off at dawn drop nothing. A pile on a cell the farmer cannot stand on (a wall, water) goes to the nearest walkable cell by a fixed rule - decide and assert
- Moon stones: the morning after a Full Moon night (0152), a LEVER number (2-8) lies on cells of the horde's route - e.g. every Kth cell of the flow field from tonight's spawn regions toward the house - chosen deterministically or from a fresh `(seed, day)` stream like `Endless._stream_for`, never the run stream
- Picked up by day only, when the farmer steps onto the cell in `Player.tick` (no verb, no tool); the pile goes into the ledger and the cell is cleared. Uncollected loot stays, or fades after a LEVER of days - decide and say so
- `bones` and `moon_stone` are resources: `RESOURCES`, `SELL_PRICE`, a leftovers group in `RESOURCE_GROUPS`, `Names.KEYS` (`ITEM_BONES`, `ITEM_MOON_STONE`) and both languages. Moon stones sell at the stall or trade for essence by day at a LEVER rate through one core function (e.g. `Tech.trade_moon_stones`), offered where an input path already exists - a button in the tech panel, or a station recipe through the workshop panel if `check_chain` can value essence (a recipe needs its `REC_*` key). Every new constant goes into `GameData.digest()` (0112's coverage assert) and `validate()` refuses a cap, a stone count or a rate of zero
- The morning report's leftovers line (0138) says what is lying on the farm: N bones, M moon stones to collect
- Drawn through the placeholder road until A036 is integrated by 0235: a code-drawn bone pile and a moon stone with a 2-frame shimmer (the glow is code, view only)
- SIM moves on purpose (drops in `_kill`, a new state key) and DATA moves (new resources and prices): record both

  - done when: `_task_0221_night_loot` in `src/tools/headless_v1.gd` asserts a killed walker leaves its bones on its cell, the pile survives `begin_day`, stepping on it by day collects it and at night does not, a Full Moon morning lays its stones on the same cells for the same seed, and a traded stone pays the essence LEVER
  - done when: `_case_0221_collect` in `src/tools/input_v1.gd` walks the farmer over a bone pile and sees the count rise, then trades a moon stone for essence through the panel that offers it
  - done when: `python tools/shot.py 0221` morning captures show the piles on the road, opened and looked at

### 0224 - The scarecrow decoy

Waits on 0218.  Likely files: `src/core/game_data.gd, src/core/pathing.gd, src/core/enemies.gd, src/ui/names.gd, src/ui/describe.gd, assets/locale/strings.csv, src/tools/perf_check.gd, src/tools/shot.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd`.

A straw figure that pulls nearby zombies off their road and takes their blows while the towers work - the first defence that changes where the horde goes without walling it in.

- Id `decoy` (not `scarecrow`, which is the porch guardian, and no crop id). A `DEFENCES` row: a cost in straw (the resource 0184 and 0193 brought in) and wood, a high `hp` LEVER (100-250), a `lure_tiles` LEVER (3-8), no `reload_ticks` (it is not a tower) and no `path_cost`, so breakers already hunt it as prey. Its `season` (0193's field on `DEFENCES`) is summer, per the plan's table, so `check_seasonal_supply` judges it right; 0234 does the gating. No `damage` either, so no `Sfx.TOWER_SOUNDS` entry: `_task_0085_night_sounds` wants a sound exactly when a defence has `damage`
- The lure rule: a lure field registered in 0218's `Pathing` registry, swept from decoy cells and built only while a decoy stands. An enemy whose `ENEMIES` row says it can be lured (a new flag: walker and runner yes, bosses never; decide the tank and the breaker) and is within `lure_tiles` of a decoy by the lure field walks down that field instead of its own, and bites the decoy through `Enemies._gnaw` when it is the next cell
- When the decoy falls the lured go back to their own field the same tick. Two decoys: the nearer by the field wins, ties by `Grid.STEPS`
- `GameData.validate()`: a lure has `lure_tiles` > 0 and hit points (`check_defences`); no boss is lurable (`check_enemies`)
- Perf: a farm without decoys pays nothing for the lure field; with four decoys the rebuild stays inside `PATH_BUDGET_US`. Add decoys to perf_check's swarm scenario
- `Names.KEYS` `DEF_DECOY`, a `Describe.defence` line for the lure (a `DESC_*` key), strings in both languages; placed by cursor at night like every defence (0132)
- Drawn through the placeholder road (a code-drawn straw figure at 16x32, whole/hurt/wreck) until A037 is integrated by 0236; the hit sway is view only
- DATA moves (a new row and the lurable flags). SIM moves on purpose too if the lure field's storage keys are in a new game's state, because `State.hash_of` folds every key, cached fields included: record both numbers and why

  - done when: `_task_0224_decoy` in `src/tools/headless_v1.gd` asserts a walker within `lure_tiles` walks to the decoy and bites it while one beyond walks on to the house, a runner is lured, the Giant is not, and the lured return to the road the tick the decoy falls
  - done when: `_case_0224_decoy` in `src/tools/input_v1.gd` places a decoy with the cursor at night
  - done when: `python tools/perf.py` passes with decoys in the swarm, and a `shot.gd` scenario of a lured crowd, captured with `python tools/shot.py 0224`, is opened and looked at

### 0226 - The beehive

Waits on 0218.  Likely files: `src/core/game_data.gd, src/core/towers.gd, src/core/combat.gd, src/core/phases.gd, src/core/building.gd, src/core/state.gd, src/ui/names.gd, src/ui/describe.gd, src/ui/sfx.gd, assets/locale/strings.csv, src/tools/headless_v1.gd`.

Bees sting what comes near and keep stinging, and the hive is as strong as the sunflowers around it - a defence that asks for a field to be planted beside it (plan section 5).

- Id `beehive`: a `DEFENCES` row with `reload_ticks` (so `Towers` collects it), a short `range`, a cost in wood and sunflowers, `season` summer (0193's field), and a sting - damage over time refreshed, never stacked, the way `Combat.set_alight` works. Either generalise `burning` to carry a damage type (fire must stay fire for 0256's rain; an entry saved without a type reads as fire, so no version bump) or add a sibling RUN_DATA table ticked in sorted id order in `Combat.tick`; decide and say which
- The row has a `damage` (the sting's per-hit number), so `_task_0085_night_sounds` wants a `Sfx.TOWER_SOUNDS` entry: map `beehive` to the nearest generated sound (e.g. `sfx/flame`) until 0283 gives it a buzz
- Strength from sunflowers, worked out once at `Phases.begin_night` and written on the occupant (no `Farm.touch`): growing sunflower plots within N tiles (`Farming.crop_on`, LEVER 2-4) raise the sting; when too few grow - autumn and winter - the hive takes sunflowers from the stock instead (LEVER per hive per night). Decide the curve and write it in the journal; a hive with neither still stings, weakly
- `TOWER_LEVELS` 1-2 for `beehive`. `Building.why_not_upgrade` only checks `TOP_TOWER_LEVEL`, so a family with fewer rows can be upgraded past its last one: refuse that, for every family
- `check_defences` accepts a sting (damage and ticks above zero) and refuses a sting with either at zero; the sunflower radius and per-night stock LEVERs are checked above zero too
- `Names.KEYS` `DEF_BEEHIVE`, a `Describe.defence` line (the sting, the sunflowers), strings in both languages; drawn through the placeholder road (a tinted 32x48 tower per level and state, an 8x8 bee swarm) until A038 is integrated by 0237
- SIM and DATA move on purpose: record both

  - done when: `_task_0226_beehive` in `src/tools/headless_v1.gd` asserts the sting refreshes rather than stacks, a hive among growing sunflowers outdoes one without, a hive with stocked sunflowers takes them at `begin_night`, and a two-level family refuses a third upgrade
  - done when: The Deliverables table of `implementation/backlog/packs/A038-beehive.md` states the final geometry this task settled (levels 1-2, the states, the swarm)
  - done when: `python tools/shot.py 0226` captures of a hive at work beside a sunflower bed at night, opened and looked at

### 0228 - The garlic braid

Waits on 0218.  Likely files: `src/core/game_data.gd, src/core/pathing.gd, src/core/enemies.gd, src/core/phases.gd, src/ui/names.gd, src/ui/describe.gd, assets/locale/strings.csv, src/tools/perf_check.gd, src/tools/headless_v1.gd`.

Hung on a post, it makes the ground around it somewhere zombies would rather walk round, and slows the ones that come through anyway (plan sections 3.1 and 5).

- Id `garlic_braid` (never `garlic`, the crop), paid in garlic and a little wood, `season` autumn (0193's field, per the plan's table). Walkable like a trap through the `walkable` flag 0225 puts on `DEFENCES` (add it here if 0225 has not landed): `Pathing._through` gives it the ground's cost and `Pathing.is_prey` leaves it out (today a defence with no `path_cost` is prey); it is not `one_shot`, so `Traps` never sees it. No `damage`, so no `Sfx.TOWER_SOUNDS` entry
- Repelling is a cost: cells within N tiles (LEVER 1-3) cost a LEVER more in `Pathing._entry_costs`, in the shared and the open field, never more than one braid's worth however many overlap. Every step stays within `WIDEST_STEP` (32): extend `check_pathing` to add the garlic extra to the worst terrain and the worst `path_cost`
- Slowing: inside the area an enemy walks at a percent of its speed (LEVER) in `Enemies._walk`, worked out like `Ability.slowed_ticks`; with a flare too, the stronger of the two applies, not both. Build the area as a per-cell array with the field (the pass over the occupants is already there) so `_walk` reads one entry, never a search per zombie per tick
- It wears out: full strength the first night, wilted (a LEVER share) the second, spent after - kept on the occupant, moved on at `Phases.begin_night`. The strength is part of the path costs, so a night that changes any braid bumps the grid once (`Farm.touch`) and the fields rebuild; the no-touch rule is for per-tick status. A spent braid does nothing and stays until sold, or goes (decide). The states match A040: fresh, wilted, spent
- Perf: the area cost is part of `_entry_costs`, so measure `path_refresh` with ten braids; it stays inside `PATH_BUDGET_US`
- `Names.KEYS` `DEF_GARLIC_BRAID`, a `Describe.defence` line, strings in both languages; drawn through the placeholder road (16x24, fresh/wilted/spent) until A040 is integrated by 0239
- SIM and DATA: record both

  - done when: `_task_0228_garlic` in `src/tools/headless_v1.gd` asserts a route with a cheap way round avoids the braid, a crowd forced through walks at the LEVER's speed, the braid wilts and is spent on the nights it says (driven through `Phases.begin_night`, not whole played nights), and `GameData.validate()` refuses a garlic extra that would pass `WIDEST_STEP`
  - done when: The Deliverables table of `implementation/backlog/packs/A040-garlic-braid.md` states the final geometry this task settled
  - done when: `python tools/shot.py 0228` captures of the route bending round a braid (0130's camera hook), opened and looked at

### 0238 - Art: the pumpkin catapult

Waits on 0227.  Likely files: `assets/art_source/defences/, assets/art_source/effects/, assets/art_source/manifest.json, tools/check_tower_art.py, tools/check_effect_art.py, tools/import_art.py`.

The approved catapult, its pumpkin and its splat replace the stand-ins 0227 left.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A039` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A039-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/defences/` and `assets/art_source/effects/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`tools/check_tower_art.py` `FAMILIES`, `check_effect_art.py`, `ArtPlacement` if needed).
- `buildings/catapult`, `catapult_2` and `catapult_3` x the four states at 32x48 with `muzzle_xy`/`muzzles_xy` on opaque pixels; the `tower` metadata in `import_art.py` for this pack; the per-family checks 0237 made in `check_tower_art.py` (if 0237 has not landed, make them here), with `gen_sprites.migrated_towers()` still the four legacy families
- The pumpkin shot (8x8) drawn where the view draws a mortar shell, and the splat (4 frames, one-shot) as an effect family in `check_effect_art.py` - its own checked block, leaving task 0017's count of 25 frames alone
- Retire 0227's stand-ins from 0120's placeholder registry
- Set the pack to integrated: `python implementation/backlog/assets.py set A039 integrated`.

  - done when: The family checks (`check_tower_art.py`, `check_effect_art.py`) and the showcase (`python tools/show_art.py --towers --check` and `python tools/show_art.py --effects --check`) pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures by day and by night of each level firing and a pumpkin landing in the real game, opened and looked at, in `implementation/shots/0238/`
  - done when: The sim and data hashes are unchanged (art never moves them)

### 0241 - Art: the electric fence

Waits on 0230.  Likely files: `assets/art_source/defences/, assets/art_source/effects/, assets/art_source/manifest.json, tools/check_barrier_art.py, tools/check_effect_art.py`.

The approved electric fence, joined on all sixteen masks, and its zap replace the stand-ins 0230 left.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A042` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A042-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/defences/` and `assets/art_source/effects/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`tools/check_barrier_art.py`, `check_effect_art.py`, `ArtPlacement` if needed).
- Source modules `buildings/modules/electric_fence_{post,horizontal,vertical}` (and `_hurt`) composed into `electric_fence_join_<mask>` for the 16 N1/E2/S4/W8 masks and `_hurt`, plus `_wreck`, at 16x32 / (8,28) like the fence. `check_barrier_art.py` checks `('wall', 'fence')` and 84 entries of task 0014: add the family and its count
- `WorldView.connected_barrier` reads the `connected` flag the importer writes from `join_mask`, so the joined art replaces 0230's placeholder joins with no view change - check it. The zap (3 frames, one-shot) is an effect family played when the stun lands, its own checked block in `check_effect_art.py` beside task 0017's 25 frames
- Retire 0230's stand-ins from 0120's placeholder registry
- Set the pack to integrated: `python implementation/backlog/assets.py set A042 integrated`.

  - done when: The family checks (`check_barrier_art.py`, `check_effect_art.py`) and the showcase (`python tools/show_art.py --barriers --check` and `python tools/show_art.py --effects --check`) pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures by day and by night of a joined run of electric fence zapping a biter in the real game, opened and looked at, in `implementation/shots/0241/`
  - done when: The sim and data hashes are unchanged (art never moves them)

### 0247 - The spitter

Waits on 0218.  Likely files: `src/core/enemies.gd, src/core/game_data.gd, src/ui/world_view.gd, src/ui/describe.gd, src/ui/names.gd, src/ui/sfx.gd, assets/locale/strings.csv, src/tools/shot.gd, src/tools/headless_check.gd, src/tools/input_check.gd, src/tools/headless_v1.gd`.

The first enemy that hurts what you built without touching it: it stops at range and spits at a tower. A tower line in the open becomes something to cover, not only something to build.

- `ENEMIES.spitter` with `# LEVER`s: hp, `ticks_per_tile`, damage to the house, reward, `spit_range` (tiles, 3-5), `spit_damage` (to a structure), `spit_every_ticks`, `spit_tiles_per_second`; `check_enemies` refuses a spit range of zero or one that reaches as far as the gun tower's base `range` (5), so a tower can always answer it. Keep it inside `_task_0051_tank`'s non-boss bounds (less hp and armour than the tank, faster than it) and `_task_0058_giant`'s
- In `Enemies._walk`: with a tower (a DEFENCES entry with `reload_ticks`) within `spit_range` - Chebyshev, nearest first, ties by the lower cell index - it stands and spits; with none it walks the flow field and bites like a walker
- Enemy projectiles are new and kept apart from the towers' `projectiles`, which `Combat.incoming` and `worth_shooting` read: a top-level `enemy_shots` Array (only Dictionaries need a TABLES/RUN_DATA line), integer positions, aimed at a cell when fired, landing through `Farm.damage` after its flight
- Advance them inside `Enemies.tick` so `PerfNames.NIGHT` stays true; if a new `X.tick` goes into `Sim._tick_night` instead, add it to `src/tools/perf_names.gd` and `perf_check.gd` in this task
- `Enemies.withdraw` clears `enemy_shots` at dawn; a spit landing on an empty cell does nothing; a tower it destroys leaves rubble and a `structure_lost` event like a bite
- Names.KEYS `spitter`, rows `ENEMY_SPITTER` and `ENEMY_SPITTER.other` (spitter/spitters, cuspidor/cuspidores) and a `Describe.enemy` line `DESC_SPITS` ('spits at towers from %d tiles' / 'cospe nas torres a %d ladrilhos'); `Sfx.ENEMY_SOUNDS.spitter` borrows the nearest generated voice (`sfx/groan_walker`) so `_task_0085_night_sounds` passes, until 0284 gives it its own
- On screen through 0120's placeholder road: the spitter at 64x48 pivot (32,44), the spit in flight (8x8) and a code-drawn splat, plus its forecast head - placeholders until A046 is integrated by 0260
- The first kind past the MVP's five breaks the art groups that count `ENEMIES`: rewrite in place `_task_0074_zombie_art` (`kinds.size() == 5`, a file per pose, the silhouette and biggest-Giant tests) and `_task_0088_juice` (a death body per kind) to check the kinds with raster art, leaving stand-ins to 0120's `_task_0120_placeholders`; `_case_0074_zombie_art` in `input_check.gd` counts a stand-in through 0120's lookup as drawn. If `_task_0059_wave_data` still wants every `ENEMIES` kind in the authored nights, exempt the kinds no night sends yet in one named list (0270-0274 put them in the year). Later enemy tasks only add to what this leaves
- Hashes: DATA moves (a new ENEMIES entry); SIM moves once, because the state gains `enemy_shots` - nothing else in the determinism scenario may change, and the journal says so

  - done when: `_task_0247_spitter` in `src/tools/headless_v1.gd`: with a gun tower inside `spit_range` it stops and lands `spit_damage` every `spit_every_ticks` (measured); with none it walks to the house; two runs of one seed land the same spits on the same ticks; nothing is left in `enemy_shots` after dawn
  - done when: The same group: a tower whose reach covers it kills it before losing the tower, and a tower that cannot reach it is worn down - print both numbers
  - done when: `python tools/shot.py 0247 spitter` (a new scenario: a spitter working on a tower line) opened and looked at; the rewritten `_task_0074_zombie_art`, `_task_0088_juice` and `_case_0074_zombie_art` pass with the spitter on its stand-in
  - done when: the Deliverables table of `implementation/backlog/packs/A046-spitter.md` states the final geometry this task settled

### 0248 - The rat swarm

Waits on 0218.  Likely files: `src/core/game_data.gd, src/core/waves.gd, src/core/enemies.gd, src/tools/perf_check.gd, tools/perf_baseline.txt, src/ui/names.gd, src/ui/describe.gd, src/ui/sfx.gd, assets/locale/strings.csv, src/tools/shot.gd, src/tools/headless_v1.gd`.

A crowd of small fast bodies that a single-target tower wastes shots on and a mine or a flame cone eats. It is also the perf case the groundwork of 0218 was built for.

- `ENEMIES.rat` with `# LEVER`s: hp 2-6, `ticks_per_tile` 10-14, damage 1-2, reward 1, armour 0, `cluster` (rats per spawn, 4-10; `check_enemies` refuses a `cluster` below 1); a swarm must not out-earn a day - check the night's bounty against 0219's levers
- `check_enemies` wants every `ignores_structures` kind faster than the fastest kind that stops for walls (the runner, 9 ticks a tile): a rat that stops for walls at 9 or less would fail the runner, so keep it at 10-14 or make it go round like one - decide, and never weaken the check to pass
- Clusters: a wave record still counts bodies, so the forecast and `Waves.size_of` stay true; `Waves.tick` releases up to `cluster` per `SPAWN_INTERVAL_TICKS`, the first on a cell from the run RNG as today (`Enemies.spawn`) and the rest through `Entities.spawn` on that cell's walkable, reachable neighbours in `Enemies.NEIGHBOURS` order (four of them), then back round onto the same cells - bodies may share a cell, as they already can - with no extra draws
- Mines and fire are the answer by construction: a gun tower overkills a rat, a mine's splash and the flamethrower cone take many. Put the cost per rat killed for the gun tower, the crossbow, the mine and the flamethrower in the journal
- Perf through 0218's caches: 0218's swarm scenario in `src/tools/perf_check.gd` swaps its walker stand-ins for rats (a few hundred alive); its `swarm_tick`, `swarm_towers` and `swarm_enemies` lines stay inside `TICK_BUDGET_US` (8333 us); a moved baseline is accepted (`python tools/perf.py --accept`) only with the journal saying why
- Names.KEYS `rat`, `ENEMY_RAT`/`ENEMY_RAT.other` (rat/rats, rato/ratos), and `DESC_SWARMS` ('comes %d at a time' / 'chega %d de cada vez') in `Describe.enemy`; `Sfx.ENEMY_SOUNDS.rat` borrows `sfx/groan_runner` until 0284
- Drawn through 0120's placeholder road at the pack's small canvas (~24x16), forecast head included - placeholders until A047 is integrated by 0261
- Hashes: DATA moves; SIM should not (no rats in the determinism night) - if it does, find out why before accepting

  - done when: `_task_0248_rats` in `src/tools/headless_v1.gd`: one wave member releases `cluster` rats on adjacent cells on one tick, the bodies sent match `Waves.size_of`, and a mine under the cluster kills more rats per unit of cost than a gun tower in the same lane
  - done when: `python tools/perf.py --report` prints the swarm lines with rats inside `TICK_BUDGET_US` and every other line inside its tolerance
  - done when: `python tools/shot.py 0248 rats` (a new scenario) opened and looked at: a cluster reads as a crowd, not a smear
  - done when: the Deliverables table of `implementation/backlog/packs/A047-rats.md` states the final geometry this task settled

### 0251 - The frost zombie

Waits on 0218.  Likely files: `src/core/combat.gd, src/core/towers.gd, src/core/enemies.gd, src/core/game_data.gd, src/ui/world_view.gd, src/ui/names.gd, src/ui/describe.gd, src/ui/sfx.gd, assets/locale/strings.csv, src/tools/shot.gd, src/tools/headless_v1.gd`.

An enemy whose death is the attack: it bursts into ice and the towers near it reload slowly for a while. Killing it right under the line now costs something.

- `ENEMIES.frost_zombie` with `# LEVER`s (hp, `ticks_per_tile`, damage, reward, armour; inside `_task_0051_tank`'s non-boss bounds) plus `chill_tiles` (radius, 1-3), `chill_ticks` and `chill_reload_percent` (reload speed while chilled, 25-75: fifty is twice as slow); `check_enemies` refuses a chill field of zero or a percent outside 1-99
- The hook is `Combat._kill`: every tower within `chill_tiles` (Chebyshev, from `Towers`' cached tower cells, sorted) gets a countdown on its occupant dictionary (`tower["chill"]`) - never through `Farm.touch`, so `grid_version` and every field stay put
- Refreshed, never stacked (the `Combat.set_alight` rule); `Towers.tick` and `_cool_down` count it down; while it lasts the reload set after a shot is scaled by `chill_reload_percent` in integers
- No chill outlives the night: cleared in `Enemies.withdraw`, which `Phases.begin_day` already calls; a save made mid-night keeps it, since occupants are RUN_DATA
- `Towers.chill_left(state, cell)` for the view and for the Winter Lord, whose freeze (0255) sits beside this chill
- Names.KEYS `frost_zombie`, `ENEMY_FROST_ZOMBIE`/`.other` (frost zombie/frost zombies, zumbi de gelo/zumbis de gelo); `DESC_CHILLS` ('slows towers when it dies' / 'deixa as torres lentas ao morrer'); `Sfx.ENEMY_SOUNDS.frost_zombie` borrows `sfx/groan_tank` until 0284
- On screen through 0120's placeholder road: the zombie, a code-drawn ice burst on death, a frost tint on chilled towers (view only) and its forecast head, until A050 is integrated by 0264
- Hashes: DATA moves; SIM should not

  - done when: `_task_0251_frost` in `src/tools/headless_v1.gd`: one killed beside two towers makes their next reload `chill_reload_percent` slower for exactly `chill_ticks`, a tower outside `chill_tiles` is untouched, `grid_version` does not move, and the chill is gone the next morning
  - done when: Two deaths beside one tower refresh rather than stack - asserted on the reload number
  - done when: `python tools/shot.py 0251 frost` (a new scenario) opened and looked at: a chilled tower is visibly different
  - done when: the Deliverables table of `implementation/backlog/packs/A050-frost-zombie.md` states the final geometry this task settled

### 0285 - Music for four seasons

Waits on 0282.  Likely files: `tools/gen_music.py, assets/music/, src/ui/music.gd, src/app/audio.gd, src/ui/main.gd, src/tools/headless_check.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd`.

The two MVP pieces become a year: a day piece per season on the shared motif, a winter night, a boss track and the credits, each crossfading on the moment it belongs to. View only: neither hash moves.

- `tools/gen_music.py` adds day pieces for summer, autumn and winter beside today's `farm`, which becomes spring (keep its id or rename it and every reader in the same pass), a winter night beside `night`, a boss track and the credits. All read `MOTIF` at the one `BPM = 75` - a crossfade between two tempos is a stumble, as the module says - and each season gets its own scale, register and density
- Every looping piece gets the seam the module already builds (`snap()`, `wrapped()` tails) and runs longer than 15 s. The credits play once, as long as 0160's roll; they and the cues (`sting` and 0282's fanfare; 0286 adds its event stingers to the same list later) are named as not-loops rather than excused from the seam check in bulk. `Audio.play_music` loops whatever it plays (`_looping` sets the shared stream's loop mode), so the credits need a play-once road in `src/app/audio.gd`
- `Music.piece_for` stays static and askable and gains what it now needs: the season (0149's calendar) and whether tonight is a boss night (0153). Day plays that season's piece; the build step, the night and the morning report play the night piece (the winter one in winter); a boss night plays the boss track; a menu keeps the spring piece behind `audio/music_in_menus`
- Crossfades use the one length there is (`fade_seconds()`, the transition's): the season turns on the first morning of the new season, the boss track arrives with a boss night's build step and leaves at dawn, the credits take over on 0160's ending screen. Decide whether `layer_for`'s urgent layer plays over the boss track, and say why
- Size: a 96 s piece is about 4.2 MB of WAV in the repository and about 0.85 MB of QOA in the pack, and `tools/release.py` holds the Web pack to `PACK_BUDGET` (3.5 MB gzipped, 2.31 MB at task 0100). Measure before and after, prefer shorter loops for the new pieces, and if the budget must move, move it on purpose with both numbers in the journal. Time matters too: `tools/verify.py` runs `gen_music.py --check`, which renders every piece (about 13 s for today's four) - put its time before and after in the journal
- Rewrite `_task_0086_music` in `headless_check.gd` for the new `piece_for` and the new list: its seam, motif and one-tempo checks cover every looping piece

  - done when: `_task_0285_season_music` in `src/tools/headless_v1.gd`: `piece_for` answers right for each season and phase, a boss night, and a menu with the setting off and on; every looping piece's `_loop_seam` ratio is at most 1.0 and its length over 15 s; every arrangement reads `MOTIF`
  - done when: `_case_0285_season_music` in `src/tools/input_v1.gd`: a real run moved to a summer morning is playing the summer piece once the fade is over (`Audio.music_playing()`), and a boss night's build step the boss track
  - done when: The Web pack size before and after (`python tools/release.py`, or why it could not be measured) and `python tools/gen_music.py --report` lengths and seams are in the journal

### 0222 - Bone meal

Waits on 0221.  Likely files: `src/core/game_data.gd, src/core/farming.gd, src/core/interact.gd, src/ui/day_hud.gd, src/ui/sfx.gd, src/ui/names.gd, src/ui/world_view.gd, assets/locale/strings.csv, src/tools/headless_v1.gd, src/tools/input_v1.gd`.

Bones go back into the ground: ground into bone meal, they give a plot one day of growth for free, once - the night paying for the day.

- A recipe (e.g. `grind_bone_meal`, at the workshop or 0188's mill) turns bones into `bone_meal`, a new resource with a price, a group, `Names.KEYS` (`ITEM_BONE_MEAL`, its `REC_*`) and both languages; `check_chain` holds (bone meal is worth more than its bones)
- Fertilising: with bone meal selected in the day HUD's strip beside the seeds (keyboard, mouse and pad), interact on a tilled plot spends one and marks the plot `fertilised` - a new field on the plot in `state["plots"]` (RUN_DATA), read with a default so old saves' plots need no migration and no `State.VERSION` bump. If it is a new verb (e.g. `fertilise` in `Farming.verb_at`), it goes in `Interact.DAY_ONLY` and `DEFAULT_TICKS`, and `Sfx.VERB_SOUNDS` maps it to the nearest generated sound (`sfx/plant`) so `_task_0084_day_sounds` stays green until 0281 gives it its own
- The rule: at the next morning's growth credit (0165) a fertilised plot grows one extra day, once, and the mark clears. Decide and assert whether it must also have been watered; it never gets round a regrowth (0172) or winter (0171) rule
- A fertilised plot not yet planted keeps the mark until it is; harvesting clears it
- The soil marker is drawn through the placeholder road (a tinted tilled tile, dry and wet) until A036 is integrated by 0235
- SIM and DATA move on purpose: record both

  - done when: `_task_0222_bone_meal` in `src/tools/headless_v1.gd` asserts two plots of one crop planted together, one of them fertilised, finish exactly one day apart, and a second morning grants nothing extra - driving 0165's morning credit directly rather than simulating whole days, which the 120 s suite budget cannot afford
  - done when: `_case_0222_fertilise` in `src/tools/input_v1.gd` selects bone meal and fertilises a plot with the keyboard
  - done when: The Deliverables table of `implementation/backlog/packs/A036-night-loot.md` states the final geometry this task settled (the pickups, the fertilised soil, the four icons)
  - done when: `python tools/shot.py 0222` captures of a fertilised plot dry and wet, opened and looked at

### 0225 - Zombie bait

Waits on 0224.  Likely files: `src/core/game_data.gd, src/core/pathing.gd, src/core/enemies.gd, src/core/building.gd, src/ui/names.gd, src/ui/describe.gd, assets/locale/strings.csv, src/tools/headless_v1.gd, src/tools/input_v1.gd`.

Rotten fish made by day and thrown down at night: for a few seconds the whole crowd around it turns toward it - the pond paying into the night (plan section 3.2).

- Id `zombie_bait`: a recipe at the kitchen (or the press) turns fish into a bait kit, through 0179's rule that a recipe taking `fish` accepts any species; the kit's inputs equal the `DEFENCES` cost, as `check_recipes` demands. 0179's fish group is understood by `Crafting`, not by `Resources.pay`: either the bait goes down from a kit only (the ledger road refused with a reason) or its `cost` names a real resource - decide. Its `season` (0193's field) is summer, as 0234's table says
- It reuses 0224's lure rule and lurable flags, with a wider `lure_tiles` LEVER (6-14). Decide how one lure field honours two reaches (each source seeded with its own head start, or the bait as a second registered field) and keep 'the nearer by the field wins'
- Walkable like a mine: a `walkable` flag on the `DEFENCES` row that `Pathing._through` (the ground's cost) and `Pathing.is_prey` (left out) both read, so nothing breaks through it and breakers do not hunt it. 0228's garlic braid uses the same flag - if 0228 landed first, reuse it. `check_defences` refuses a walkable row with a `path_cost`
- Consumed: it lasts `lifetime_ticks` (LEVER, 5-20 s) and goes when that runs out or when a LEVER number of zombies have reached it, whichever is first; it leaves no rubble
- A per-night limit LEVER like the barricade's, read through `Building.left_tonight` - which today adds the tree's `barricade_bonus` to every `per_night_limit`: make that the barricade's alone, or decide the bait shares it, and assert which
- `Names.KEYS` (`DEF_ZOMBIE_BAIT`, its `REC_*`), a `Describe.defence` line, strings in both languages; no `damage`, so no `Sfx.TOWER_SOUNDS` entry; drawn through the placeholder road (a 16x16 fish on the ground and its icon) until A037 is integrated by 0236
- DATA moves (a row and a recipe); SIM moves only if a state key is added or the determinism scenario meets a bait - record which

  - done when: `_task_0225_bait` in `src/tools/headless_v1.gd` asserts a crowd beyond any decoy's reach turns toward the bait, the bait goes at its lifetime or its arrival count, and the crowd is back on its road the same tick
  - done when: `_case_0225_bait` in `src/tools/input_v1.gd` makes a bait by day and places it with the cursor at night
  - done when: The Deliverables table of `implementation/backlog/packs/A037-decoy.md` states the final geometry this task settled (decoy states and sway frames, the bait on the ground, its icon)

### 0229 - The searchlight

Waits on 0196, 0226.  Likely files: `src/core/light.gd (new), src/core/game_data.gd, src/core/towers.gd, src/core/ability.gd, src/core/combat.gd, src/ui/lighting.gd, src/ui/names.gd, src/ui/describe.gd, assets/locale/strings.csv, src/tools/headless_check.gd, src/tools/headless_v1.gd`.

A powered lamp that lights the ground around it and lets the towers in its light see a tile further - and the moment light becomes a rule that the wraith and the fog will read (plan section 5).

- Id `searchlight`: a `DEFENCES` row with no `reload_ticks` (it does not shoot) and no `damage` (so no `Sfx.TOWER_SOUNDS` entry), an `energy_draw`, a `light_tiles` LEVER (3-6), a cost in iron and copper (0176) and `season` winter (0193's field). Breakers hunt it like anything built. `check_defences` refuses a light with `light_tiles` of zero; a new constant (the porch radius, the reach bonus) goes into `GameData.digest()`
- Light is a core rule in one place (e.g. `src/core/light.gd`): `Light.is_lit(state, cell)` is true on searchlight cells, in the flare's area while it burns (`Ability.flare_at`), on the cells of burning enemies (`Combat.is_burning`) and on the porch (a LEVER radius round the house door). 0252 and 0256 read it; `lighting.gd` may draw from it, never the other way round
- Searchlight cells are cached against `grid_version`, like `Towers._towers` (new state keys: SIM moves; a Dictionary cache goes in `State.TABLES` or `RUN_DATA`); the flare and the fires are asked fresh. `Light` is asked, never ticked - if it grows a `tick`, it goes in `PerfNames` and `perf_check`
- A tower standing in light reaches +1 (LEVER): `Towers.reach_of` learns the tower's cell (or `_acquire` passes it) - move every caller: `_acquire` (0218's bucketed version), `acquire_for`, the old asserts that call `reach_of` in `headless_check.gd`, and any range drawing the view gained (0131's cursor)
- Needs power, degraded never dead like the rest of `Power`: on a short farm the light shrinks (e.g. by a tile) instead of going out; decide and assert
- `TOWER_LEVELS` 1-2 for `searchlight` (a wider light), refused past its last row by 0226's fix to `Building.why_not_upgrade`
- `Names.KEYS` `DEF_SEARCHLIGHT`, a `Describe.defence` line, strings in both languages; drawn through the placeholder road (32x48 per level and state, a `light_xy` point) with the beam in code, until A041 is integrated by 0240
- SIM and DATA: record both

  - done when: `_task_0229_light` in `src/tools/headless_v1.gd` asserts the lit cells of each source (a searchlight, the flare, a burning zombie, the porch), a gun tower in light acquiring one tile further than one in the dark, a short farm shrinking the light, and the cache rebuilding when a searchlight goes up or comes down
  - done when: The Deliverables table of `implementation/backlog/packs/A041-searchlight.md` states the final geometry this task settled
  - done when: `python tools/shot.py 0229` captures of a lit and an unlit tower line at night, opened and looked at

### 0231 - Hardwood walls and sandbags

Waits on 0196, 0226.  Likely files: `src/core/game_data.gd, src/core/building.gd, src/core/pathing.gd, src/core/repair.gd, src/ui/world_view.gd, src/ui/names.gd, src/ui/describe.gd, assets/locale/strings.csv, src/tools/headless_v1.gd`.

Two more ways to hold a line: the stone wall upgraded with hardwood into something a breaker has to work at, and sandbags from the loom as a cheap barrier that soaks more than a fence (plan sections 3.3 and 3.5).

- A `TOWER_LEVELS` row for `wall`: level 2 paid in hardwood (0177), more `hp` and `path_cost`, upgraded by cursor like a tower (0226's fix refuses a third level). `Building.entry_at` already lays a level over any id, but the field does not read it: `Pathing._through` prices an occupant from `Building.entry_of` (the base row), so `_entry_costs` must price a levelled occupant from its levelled entry, and `check_pathing` must read `TOWER_LEVELS`' `path_cost` too, so the level stays within `WIDEST_STEP`
- Sandbags: 0188 planned `SANDBAG` as a material (read what it actually made). A material means the barrier gets its own id (e.g. `sandbag_wall`) paid in sandbags, because `Names.KEYS` is keyed by id; if 0188 made a kit instead, it becomes the `DEFENCES` row that kit places. Its `hp` and `path_cost` LEVERs sit between the fence and the wall, and its `season` (0193's field) is decided here and confirmed by 0234. Neither has `damage`, so no `Sfx.TOWER_SOUNDS` entry
- A level-2 wall mends to its levelled HP (0113) and costs what that level is made of - assert it
- Joins: `WorldView.barrier_mask` decides who meets whom - a hardwood wall joins stone walls, sandbags join sandbags (decide whether they meet walls) - and `_barrier_name` learns the wall's level
- `Names.KEYS` and strings in both languages for the new id and the upgrade; drawn through the placeholder road (level-2 wall modules for the 16 masks, whole/hurt/wreck; the sandbag pieces) until A043 is integrated by 0242
- DATA moves (a level row, a new barrier). SIM must not move for the determinism scenario's level-1 walls; if pricing levelled occupants moves it, say why - record both numbers

  - done when: `_task_0231_strong_walls` in `src/tools/headless_v1.gd` asserts a level-2 wall takes the LEVER's longer to chew through and costs the field its levelled `path_cost`, a third upgrade is refused, sandbags sit between fence and wall on hit points and path cost, and repair restores the level-2 maximum
  - done when: The Deliverables table of `implementation/backlog/packs/A043-strong-walls.md` states the final geometry this task settled (and whether sandbags are modules or one piece)
  - done when: `python tools/shot.py 0231` captures of a mixed line - stone, hardwood, sandbags - opened and looked at

### 0233 - Three new powers

Waits on 0232, 0220, 0230.  Likely files: `src/core/ability.gd, src/core/game_data.gd, src/core/enemies.gd, src/core/repair.gd, src/ui/night_hud.gd, src/ui/names.gd, src/app/input_actions.gd, project.godot, assets/locale/strings.csv, src/tools/headless_v1.gd, src/tools/input_v1.gd`.

Three more buttons for a night going wrong: the farm bell stops every zombie for two seconds, the dog runs out and bites one, and an emergency repair puts a structure back on its feet - each aimed with the cursor, each with its wait (plan section 4.4).

- Power ids `farm_bell`, `call_dog` and `emergency_repair` (not `dog`, the animal of 0185), every number a LEVER in a `GameData` table beside `ABILITY`, listed in `GameData.digest()` (0112's coverage assert) and checked by `validate()` (a cooldown above zero, a node that gives each power). Their state goes inside `state["ability"]` (`State.TABLES`, so reconcile fills old saves)
- The bell stops every zombie on the farm for 2 s (1-4) through 0230's entity stun counter; decide whether bosses stop, for less or not at all
- The dog bites the enemy nearest the aimed cell within a radius, for a LEVER damage, after a delay worked out from its distance to the house - no RNG; its run and bite are view only
- The repair restores 30% (LEVER 15-50) of the aimed structure's levelled maximum (0113), free, through one `Repair` function that `apply` also uses for the cap; decide whether the house counts. A destroyed structure is rubble and cannot be aimed at
- Own cooldowns (LEVERs), recharged at `begin_night` like the flare. Unlocked by the tree, one per season from summer: three survival rows in `TECH_TREE` with 0220's `season` gate (summer the bell, autumn the dog, winter the repair), each giving its power, priced with 0220's arithmetic (redo it in the journal with the three added); a locked power shows greyed with its node, never hidden
- Aimed with the cursor through 0232's API; an input action per power in `InputActions.ACTIONS` and `project.godot` with pad bindings (0121's sync check) and `ACT_*` strings in both languages, rebindable
- The night dog is 0185's stand-in through the placeholder road until A028 is integrated by 0245; the power icons are placeholders until A045 is integrated by 0244
- `Names.KEYS`/`NOTES` for the new nodes, `POWER_*` names and notes, strings in both languages; the night HUD shows each power's charge or lock
- SIM and DATA move on purpose: record both

  - done when: `_task_0233_powers` in `src/tools/headless_v1.gd` asserts the bell holds every walker for exactly its ticks, the dog's bite lands on the enemy nearest the aimed cell after the computed delay, the repair restores the LEVER share of a levelled tower, and each power is refused before its node is bought
  - done when: `_case_0233_powers` in `src/tools/input_v1.gd` aims and fires each power with the mouse and with the pad
  - done when: The Deliverables table of `implementation/backlog/packs/A028-dog.md` states the final geometry this task settled (the night run and bite, the scale against the farmer)

### 0237 - Art: the beehive

Waits on 0226.  Likely files: `assets/art_source/defences/, assets/art_source/effects/, assets/art_source/manifest.json, tools/check_tower_art.py, tools/check_effect_art.py, tools/import_art.py`.

The approved beehive and its bees replace the stand-ins 0226 left.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A038` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A038-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/defences/` and `assets/art_source/effects/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`tools/check_tower_art.py` `FAMILIES`, `check_effect_art.py`, `ArtPlacement` if needed).
- `buildings/beehive` and `beehive_2` x {'', `_hurt`, `_fire`, `_wreck`} at 32x48, pivot (16,44), one scale per level. `check_tower_art.py` loops levels 1-3 for every family, accepts only `generation_task` 0013 and demands a `muzzle_xy` on every non-wreck state: make the level count and the metadata point per family (the hive's own point, where the swarm leaves, or none - as the pack's contract says) and accept the pack. Keep `gen_sprites.migrated_towers()` to the four legacy families (the checker compares it with `FAMILIES`). `import_art.py` writes `"tower": true` only for 0013 - extend it
- The bee swarm (8x8, 3 frames) loops while a hive stings: a looping effect, which `check_effect_art.py` (one-shots only) has to be taught deliberately
- Retire 0226's stand-ins from 0120's placeholder registry
- Set the pack to integrated: `python implementation/backlog/assets.py set A038 integrated`.

  - done when: The family checks (`check_tower_art.py`, `check_effect_art.py`) and the showcase (`python tools/show_art.py --towers --check` and `python tools/show_art.py --effects --check`) pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures by day and by night of a hive at each level stinging a crowd in the real game, opened and looked at, in `implementation/shots/0237/`
  - done when: The sim and data hashes are unchanged (art never moves them)

### 0239 - Art: the garlic braid

Waits on 0228.  Likely files: `assets/art_source/defences/, assets/art_source/manifest.json, tools/check_barrier_art.py, tools/verify.py`.

The approved garlic braid, fresh, wilted and spent, replaces the stand-in 0228 left.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A040` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A040-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/defences/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`tools/check_barrier_art.py`, `ArtPlacement` if needed).
- `buildings/garlic_braid`, `_wilted` and `_spent` at 16x24 on the barricade's ground pivot; the wear state 0228 keeps on the occupant picks the frame
- Extend `check_barrier_art.py`'s single-piece checks (or a family checker wired into `tools/verify.py`) for the three states
- Retire 0228's stand-in from 0120's placeholder registry
- Set the pack to integrated: `python implementation/backlog/assets.py set A040 integrated`.

  - done when: The family checks (`check_barrier_art.py`) and the showcase (`python tools/show_art.py --barriers --check`) pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures by day and by night of braids fresh, wilted and spent beside a route in the real game, opened and looked at, in `implementation/shots/0239/`
  - done when: The sim and data hashes are unchanged (art never moves them)

### 0260 - Art: the spitter

Waits on 0247, 0246.  Likely files: `assets/art_source/enemies/spitter/, assets/art_source/effects/, assets/art_source/manifest.json, assets/art_source/ownership.json, tools/check_enemy_art.py, tools/gen_sprites.py, tools/check_effect_art.py, src/ui/enemy_motion.gd`.

The spitter as Codex drew it, in place of 0247's stand-in: its walk, the spit, the splat and its forecast head.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A046` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A046-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/enemies/spitter/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`gen_sprites.migrated_enemies()`, `check_enemy_art.FAMILIES` and its pinned generation task `'0015'`, the effect checker's pinned 0017 set, `EnemyMotion.FAMILIES`/`TRACKED`) with a block for this pack rather than loosening the old counts.
- Runtime names as the ordinary enemies at 64x48 pivot (32,44): `enemies/spitter`, `spitter_walk_0..3` (0.125 s, loop), `spitter_attack_0..2` (the spit), `spitter_death_0..3`, with the `_walk_b`/`_attack`/`_death` aliases; the spit (8x8, 2 frames) and the splat (3) in the effects family; the 16x16 forecast head where 0158 put the others
- Replace 0247's placeholders in 0120's registry (the leaf flips ownership to raster) and drive the attack pose from the real spit, not a bite.
- Set the pack to integrated: `python implementation/backlog/assets.py set A046 integrated`.

  - done when: `python tools/check_enemy_art.py`, `python tools/check_effect_art.py` and `python tools/show_art.py --enemies --check` pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures in the real game by day (its head in the dusk forecast) and by night (spitting at a tower), opened and looked at, in `implementation/shots/0260/`
  - done when: the sim and data hashes are unchanged (art never moves them)

### 0261 - Art: the rat swarm

Waits on 0248, 0246.  Likely files: `assets/art_source/enemies/rat/, assets/art_source/manifest.json, assets/art_source/ownership.json, tools/check_enemy_art.py, tools/gen_sprites.py, src/ui/enemy_motion.gd, src/ui/enemy_deaths.gd`.

The rats as Codex drew them, in place of 0248's stand-in: small enough to read as a swarm and still read as rats.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A047` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A047-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/enemies/rat/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`gen_sprites.migrated_enemies()`, `check_enemy_art.FAMILIES`, `EnemyMotion.FAMILIES`/`TRACKED`).
- The rat is not 64x48: `check_enemy_art.py` takes canvas, pivot, contact row and motion counts per family (rat: walk 4, attack 3 from the pack's bite, death 3, at the canvas 0248 settled, ~24x16) instead of asserting `[64,48]` for everyone, and `EnemyDeaths` plays three death frames for it
- Runtime names `enemies/rat`, `rat_walk_0..3`, `rat_attack_0..2`, `rat_death_0..2` with the usual aliases, and the forecast head; replace 0248's placeholders in 0120's registry
- Set the pack to integrated: `python implementation/backlog/assets.py set A047 integrated`.

  - done when: `python tools/check_enemy_art.py` and `python tools/show_art.py --enemies --check` pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures in the real game by day (the head in the dusk forecast) and by night (a cluster crossing a mine), opened and looked at, in `implementation/shots/0261/`
  - done when: the sim and data hashes are unchanged (art never moves them)

### 0264 - Art: the frost zombie

Waits on 0251, 0246.  Likely files: `assets/art_source/enemies/frost_zombie/, assets/art_source/effects/, assets/art_source/manifest.json, assets/art_source/ownership.json, tools/check_enemy_art.py, tools/gen_sprites.py, tools/check_effect_art.py, src/ui/enemy_motion.gd`.

The frost zombie as Codex drew it, in place of 0251's stand-in, with the ice shattering when it dies.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A050` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A050-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/enemies/frost_zombie/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`gen_sprites.migrated_enemies()`, `check_enemy_art.FAMILIES`, the effect checker's pinned set, `EnemyMotion.FAMILIES`/`TRACKED`).
- At 64x48 pivot (32,44): `frost_zombie_walk_0..3`, `_attack_0..2`, `_death_0..3` with the usual aliases; the ice-shatter burst (4 frames, one-shot) in the effects family, played where 0251's code burst was; the forecast head
- Replace 0251's placeholders in 0120's registry; the frost tint on chilled towers stays code
- Set the pack to integrated: `python implementation/backlog/assets.py set A050 integrated`.

  - done when: `python tools/check_enemy_art.py`, `python tools/check_effect_art.py` and `python tools/show_art.py --enemies --check` pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures in the real game by day (the head in the dusk forecast) and by night (a shatter beside a tower), opened and looked at, in `implementation/shots/0264/`
  - done when: the sim and data hashes are unchanged (art never moves them)

### 0234 - The arsenal grows with the seasons

Waits on 0224, 0225, 0226, 0227, 0228, 0229, 0230, 0231, 0220, 0223.  Likely files: `src/core/game_data.gd, src/core/building.gd, src/ui/hotbar.gd, src/ui/build_mode.gd, src/ui/night_hud.gd, src/ui/world_view.gd, src/ui/transition.gd, assets/locale/strings.csv, implementation/BALANCE.md, src/tools/headless_check.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd`.

The arsenal arrives with the calendar - spring's six, then summer's, autumn's and winter's - and every defence costs money as well as materials, so the day's purse is what the night is built with (plan sections 2, 5 and 7).

- The `season` field 0193 put on `DEFENCES` (default spring; 0224-0231 set their own) becomes a rule, per the plan's table: spring the gun tower, crossbow, mine, fence, barricade and wall; summer the flamethrower, decoy, beehive and bait; autumn the mortar, catapult and garlic braid; winter the searchlight and electric fence. Confirm the hardwood wall level and the sandbags and say why. Gated through 0220's `Calendar.season_reached` (Year 2 keeps all), refused in `Building.why_not` with 0220's season key, shown greyed in the hotbar with its season; `validate()` refuses a `season` outside 0-3
- Moving the flamethrower and the mortar out of spring is a rule change: every test, tool and showcase that builds them on day 1 (perf_check's worst case, `_task_0043`, `_task_0044`, the tower groups, `tower_showcase`, the autoplayer) gets a test helper that sets the calendar - never a switch in core
- Money in the cost (plan sections 1 and 7): each `cost` gains a money share (LEVERs). A kit pays the materials in advance and placing it still charges the money: `check_recipes` compares the kit's inputs with the cost less its money, `Building.affordable` and `why_not` ask for the money even when a kit is held (today a kit alone says yes), `Building.place` takes the money either way, and refunds follow `refund_for_cost`
- The hotbar of 0133 already pages or scrolls: give it a fixed order, by season then by cost, and group or page it by season if that reads better - decide; keyboard, mouse and pad still reach every slot
- 0223's tarp list and `transition.gd`'s `WAKES` take the new families; every new defence has its hotbar icon through the placeholder road until A045 is integrated by 0244
- Prices argued against 0194's money per day: at the start of a season a good day buys about one new defence (plan section 5) - a table in `implementation/BALANCE.md`
- SIM and DATA move on purpose: record both

  - done when: `_task_0234_arsenal` in `src/tools/headless_v1.gd` asserts each defence is refused before its season with the season reason and placeable after, Year 2's spring keeps winter's defences, a placed kit still charges its money, and `GameData.validate()` refuses a kit whose inputs drift from the materials
  - done when: `_case_0234_hotbar_pages` in `src/tools/input_v1.gd` pages the hotbar and places an autumn defence in autumn
  - done when: The Deliverables tables of `implementation/backlog/packs/A044-tarps.md` and `implementation/backlog/packs/A045-power-weapon-icons.md` state the final geometry this task settled (the tarp families and footprints, the icon list)
  - done when: `python tools/shot.py 0234` captures of the hotbar in spring and in winter, opened and looked at

### 0235 - Art: bones, moon stones and essence

Waits on 0221, 0222, 0219.  Likely files: `assets/art_source/props/, assets/art_source/crops/, assets/art_source/ui/, assets/art_source/manifest.json, tools/check_prop_art.py, tools/check_crop_art.py, tools/check_ui_art.py`.

The approved bones, moon stones, fertilised soil and night-loot icons go into the game in place of the stand-ins 0219, 0221 and 0222 left - essence's icon included.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A036` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A036-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/props/`, `assets/art_source/crops/` and `assets/art_source/ui/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`tools/check_prop_art.py` `NAMES`, `check_crop_art.py`'s soil names, `check_ui_art.py`, `ArtPlacement` if needed).
- Runtime names: the bone pile and the moon stone as 16x16 props on a ground pivot (the stone's 2-frame shimmer an animation, its glow left in code); the fertilised ground dry and wet beside `tilled`/`tilled_wet` (the wet one at least 20 RGB darker, as `check_crop_art.py` holds soil to); `icon_`/`hud_` for `bones`, `bone_meal` and `moon_stone`, and the essence art as `ui/icon_tech` and `ui/hud_tech`, since the id stays `tech`
- `check_ui_art.py` counts the resource icons by `generation_task` (15 plans, 30 entries today, `tech` among them): extend it to the pack's entries rather than loosening the count, and move `tech` out of task 0018's set on purpose (the plan list and the count, with the reason) since the essence icon replaces it
- Retire the stand-ins of 0219, 0221 and 0222 from 0120's placeholder registry, so its check no longer lists A036
- Set the pack to integrated: `python implementation/backlog/assets.py set A036 integrated`.

  - done when: The family checks (`check_prop_art.py`, `check_crop_art.py`, `check_ui_art.py`) and the showcase (`python tools/show_art.py --props --check`, `python tools/show_art.py --crops --check` and `python tools/show_art.py --ui --check`) pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures by day and by night of bone piles, a moon stone, a fertilised plot and the essence counter in the real game, opened and looked at, in `implementation/shots/0235/`
  - done when: The sim and data hashes are unchanged (art never moves them)

### 0236 - Art: the scarecrow decoy and zombie bait

Waits on 0224, 0225.  Likely files: `assets/art_source/defences/, assets/art_source/ui/, assets/art_source/manifest.json, tools/check_barrier_art.py, tools/check_ui_art.py, tools/verify.py`.

The approved straw decoy and rotten-fish bait replace the stand-ins 0224 and 0225 left.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A037` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A037-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/defences/` and `assets/art_source/ui/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`tools/check_barrier_art.py`, `check_ui_art.py`, `ArtPlacement` if needed).
- Runtime names follow the one-cell pieces: `buildings/decoy`, `_hurt` and `_wreck` at 16x32 on the ground pivot, the hit sway (2-3 frames) as a short one-shot the view plays when it is struck; the bait on the ground at 16x16 like the mine; `icon_`/`hud_` for the bait kit
- `check_barrier_art.py` counts task 0014's 84 entries and checks the mine's single pieces: extend it for the pack's entries, or add a `check_decoy_art.py` wired into `tools/verify.py` if the shape does not fit
- Retire the stand-ins of 0224 and 0225 from 0120's placeholder registry; if 0223/0234 gave the decoy a tarp, check it still unveils
- Set the pack to integrated: `python implementation/backlog/assets.py set A037 integrated`.

  - done when: The family checks (`check_barrier_art.py`, `check_ui_art.py`) and the showcase (`python tools/show_art.py --barriers --check` and `python tools/show_art.py --ui --check`) pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures by day and by night of a decoy whole, hurt and struck, and a bait on the ground in the real game, opened and looked at, in `implementation/shots/0236/`
  - done when: The sim and data hashes are unchanged (art never moves them)

### 0240 - Art: the searchlight

Waits on 0229.  Likely files: `assets/art_source/defences/, assets/art_source/manifest.json, tools/check_tower_art.py, tools/import_art.py`.

The approved searchlight replaces the stand-in 0229 left, and its beam starts from the lamp the art draws.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A041` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A041-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/defences/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`tools/check_tower_art.py` `FAMILIES`, `ArtPlacement` if needed).
- `buildings/searchlight` and `searchlight_2` x the four states at 32x48 with a `light_xy` point on an opaque pixel in place of the muzzle `check_tower_art.py` demands of a gun; the per-family level count, metadata point and `tower` metadata as 0237 left them (make them here if it has not landed), `gen_sprites.migrated_towers()` still the four legacy families
- The beam stays code and starts from `light_xy`; what is lit is still `Light.is_lit` (0229), never the sprite
- Retire 0229's stand-in from 0120's placeholder registry
- Set the pack to integrated: `python implementation/backlog/assets.py set A041 integrated`.

  - done when: The family checks (`check_tower_art.py`) and the showcase (`python tools/show_art.py --towers --check`) pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures by day and by night of searchlights at both levels lighting a tower line in the real game, opened and looked at, in `implementation/shots/0240/`
  - done when: The sim and data hashes are unchanged (art never moves them)

### 0242 - Art: hardwood walls and sandbags

Waits on 0231.  Likely files: `assets/art_source/defences/, assets/art_source/manifest.json, tools/check_barrier_art.py`.

The approved hardwood wall and sandbags replace the stand-ins 0231 left.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A043` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A043-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/defences/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`tools/check_barrier_art.py`, `ArtPlacement` if needed).
- The level-2 wall's modules composed into its join names (the naming 0231 gave `_barrier_name`) for the 16 masks, whole/hurt, plus a wreck; the sandbags as modules or one piece, as 0231 settled, whole/hurt/wreck
- Extend `check_barrier_art.py` with both families and their counts rather than loosening the 84
- Retire 0231's stand-ins from 0120's placeholder registry
- Set the pack to integrated: `python implementation/backlog/assets.py set A043 integrated`.

  - done when: The family checks (`check_barrier_art.py`) and the showcase (`python tools/show_art.py --barriers --check`) pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures by day and by night of a mixed line of stone, hardwood and sandbags in the real game, opened and looked at, in `implementation/shots/0242/`
  - done when: The sim and data hashes are unchanged (art never moves them)

### 0245 - Art: the dog

Waits on 0233.  Likely files: `assets/art_source/props/, assets/art_source/manifest.json, tools/check_prop_art.py, src/ui/art_placement.gd`.

The approved farm dog replaces the stand-ins of 0185 by day and of 0233's call-the-dog power at night.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A028` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A028-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/props/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`tools/check_prop_art.py` `NAMES` and its animal canvas rule, `ArtPlacement` if needed).
- The dog as an animal like the cow and the chicken (24x24 / (12,22) unless the pack's contract says otherwise - read it): day sit, wag, follow-walk (4) and bark (2-3); night run (4) and bite (3); side view mirrored at runtime like the enemies unless the contract bakes directions
- The pet's states of 0185 and the power's run and bite of 0233 pick their frames; retire both stand-ins from 0120's placeholder registry
- Set the pack to integrated: `python implementation/backlog/assets.py set A028 integrated`.

  - done when: The family checks (`check_prop_art.py`) and the showcase (`python tools/show_art.py --props --check`) pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures by day and by night of the dog following the farmer and the dog called at night in the real game, opened and looked at, in `implementation/shots/0245/`
  - done when: The sim and data hashes are unchanged (art never moves them)

### 0252 - The wraith

Waits on 0229, 0218.  Likely files: `src/core/towers.gd, src/core/combat.gd, src/core/game_data.gd, src/ui/world_view.gd, src/ui/wraith_fade.gdshader (new), src/ui/names.gd, src/ui/describe.gd, src/ui/sfx.gd, assets/locale/strings.csv, src/tools/shot.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd`.

Winter's answer to a defence that only shoots: in the dark it cannot be aimed at. Light - the searchlight, the flare, fire, the porch - becomes a weapon of its own.

- `ENEMIES.wraith` with `# LEVER`s (hp, `ticks_per_tile`, damage, reward, armour; inside `_task_0051_tank`'s non-boss bounds) and a `needs_light` flag
- Light comes only from 0229's core rule - `Light.is_lit(state, cell)` in `src/core/light.gd`, or whatever name 0229's journal gives it (searchlight cells, the flare area, burning cells, the porch) - never from `lighting.gd`; if that rule cannot be asked about one cell, add the query there rather than a second definition here
- `Towers._acquire` (0218's bucketed version) and `Combat.worth_shooting` skip a `needs_light` enemy on an unlit cell; it is a target from the tick it steps into light, and a shot already in the air still lands
- Decide and document what is not aiming - splash landings, mines, the cone, the flare. Recommendation: area damage still hurts it, so the dark has answers that are not light
- Names.KEYS `wraith`, `ENEMY_WRAITH`/`ENEMY_WRAITH.other` (wraith/wraiths, assombração/assombrações); `DESC_NEEDS_LIGHT` ('can only be aimed at in light' / 'só dá para mirar nela na luz'); `Sfx.ENEMY_SOUNDS.wraith` borrows `sfx/groan_walker` until 0284
- On screen: a view-only alpha shader in `src/ui/` reading the same core rule - faint outside light, solid in it, never fully invisible to the player - over 0120's placeholder road with its forecast head until A051 is integrated by 0265 (the pack's art is opaque with binary alpha; transparency is the shader's)
- Hashes: DATA moves; SIM should not; the shader moves neither

  - done when: `_task_0252_wraith` in `src/tools/headless_v1.gd`: a gun tower ignores a wraith walking past it in the dark and shoots it on the first tick it stands in a searchlight cell, a flare's area or a burning cell
  - done when: `_case_0252_wraith_fade` in `src/tools/input_v1.gd`: the wraith's sprite is faint outside light and solid in it
  - done when: `python tools/shot.py 0252 wraith` (a new scenario: one in the beam, one outside it) opened and looked at
  - done when: the Deliverables table of `implementation/backlog/packs/A051-wraith.md` states the final geometry this task settled

### 0253 - The Harvester

Waits on 0246, 0231.  Likely files: `src/core/enemies.gd, src/core/game_data.gd, src/ui/enemy_motion.gd, src/ui/world_view.gd, src/ui/night_hud.gd, src/ui/names.gd, src/ui/describe.gd, src/ui/sfx.gd, assets/locale/strings.csv, src/tools/shot.gd, src/tools/headless_v1.gd`.

Summer's boss: a possessed machine that winds up and charges in a straight line, flattening the walls in its row. It tests defence in depth - one thick wall is a speed bump, layers are a defence.

- `ENEMIES.harvester` with `is_boss` and `# LEVER`s: hp, armour, walking `ticks_per_tile`, damage, reward, `telegraph_ticks`, `charge_every_ticks`, `charge_tiles`, `charge_ticks_per_tile`, `crush_damage`; `check_enemies` refuses a charger missing any of them or with a zero; it passes 0246's 'every boss outlasts every non-boss' asserts
- The charge, in `Enemies` (inside `Enemies.tick`, `PerfNames` unchanged): every `charge_every_ticks` it stops and winds up with the line fixed when the wind-up starts - the row or column towards the house centre along the dominant axis, ties to the row - then moves along it at `charge_ticks_per_tile`, ignoring the flow field. `telegraph_ticks` already times the wind-up before every gnaw and at the house (`_gnaw`, `_swung_at_the_house`): reuse it for the charge or add `charge_windup_ticks`, and say which
- Every structure entered takes `crush_damage` through `Farm.damage`; it carries on through what it destroys and stops at the first that survives, at impassable terrain, at `charge_tiles` or at the house (a bite), then walks and gnaws as usual. Set the numbers so a stone wall falls and the wall's hardwood level (0231's `TOWER_LEVELS` row, read through `Building.entry_at`) holds a charge, and state them
- `Enemies.charge_line(state, id)` returns the telegraphed cells for the view and the tests; the wind-up goes through `is_winding`/`winding_at` so the 0246 bar flashes
- Destroyed walls rebuild the fields at most once a tick (they are rebuilt lazily by `Pathing.refresh`; assert one rebuild after a charge crushes three walls in one tick)
- Summer's day-14 boss: `GameData.SEASON_BOSSES[1]` (0153's table) becomes `&"harvester"`, and any 0153-0160 group or shot scenario that put a Giant on Summer 14 is rewritten in place; its 0246 intro `BOSS_INTRO_HARVESTER`; Names.KEYS `harvester`, `ENEMY_HARVESTER`/`.other` (harvester/harvesters, colheitadeira/colheitadeiras) and `DESC_CHARGES` ('charges in a straight line' / 'investe em linha reta'); `Sfx.ENEMY_SOUNDS.harvester` borrows `sfx/roar_giant` (0246 made `Sfx` boss-generic) until 0284
- On screen: a strip on the telegraphed cells during the wind-up (view only) and the boss through 0120's placeholder road at the Giant's 80x64 pivot (40,60), with its forecast mark, until A052 is integrated by 0266
- Hashes: DATA moves (ENEMIES, SEASON_BOSSES); SIM should not - the determinism night is Spring 1

  - done when: `_task_0253_harvester` in `src/tools/headless_v1.gd`: the line is fixed when the wind-up starts and the wind-up lasts exactly the levers' ticks; three stone layers lose what the levers say and a structure with more hp than `crush_damage` stops the charge; it never leaves the map or crosses water
  - done when: The same group: sealed in, it still reaches the house, and killing it moves `bosses_down_of(state, &"harvester")`
  - done when: `python tools/shot.py 0253 harvester` (wind-up with its strip, and the line after the charge) opened and looked at
  - done when: the Deliverables table of `implementation/backlog/packs/A052-harvester.md` states the final geometry this task settled (80x64, or up to 112x80 if justified)

### 0256 - Fog and rain

Waits on 0229.  Likely files: `src/core/weather.gd (new), src/core/forecast.gd, src/core/game_data.gd, src/core/towers.gd, src/core/combat.gd, src/core/enemies.gd, src/ui/forecast_panel.gd, assets/locale/strings.csv, src/tools/shot.gd, src/tools/headless_v1.gd`.

Nights that are not all alike: some are foggy, some rain. Both are known at dusk, so they change what you build rather than punish you for not guessing.

- `Weather.event(seed, date)` in a new `src/core/weather.gd` (class name `Weather` - `Events` is already the log), keyed on the calendar date (`Calendar.date`, which 0153's hold keeps on 14), not on `day`: a fresh stream mixed like `Endless._stream_for` but salted so it is not the wave table's stream, never `state["rng"]`; at most one event a night; it returns none on date 1 and on `Calendar.is_calm(date)`; no State key, and none may be named `moon_phase`. The one function every reader calls (0270 will let a night record pin or forbid an event through it)
- `GameData.NIGHT_EVENTS` with per-season weights (percent, `# LEVER`) for `fog` and `rain` and their levers, listed in `GameData.digest()` and checked by a new `check_night_events` in `validate()`: weights 0-100, a season's weights summing to at most 100, each lever in range
- Fog: `Towers.reach_of` (which 0229 taught the tower's cell) loses `fog_reach_penalty` (1) down to a floor of 1, except for a tower on a lit cell (`Light.is_lit`, 0229) - the searchlight cancels it; every shape that reads reach gets the same answer
- Rain: `DAMAGE_FIRE` hits and burn ticks deal `rain_fire_percent` (bees are not fire, even if 0226 reused `burning`), and mud slows walkers by `rain_mud_percent` in `Enemies._walk`, composed with the flare's (`Ability.slowed_ticks`) and the garlic's slows by one written rule; flyers (0249's `flies`) are not slowed
- Ask `Weather` once per system tick (`Towers.tick`, `Enemies.tick`, `Combat.tick`), not once per body, so a swarm does not pay for it; `python tools/perf.py --report` stays inside its tolerance
- The `event` slot 0158 left in `Forecast.of(seed, date)` is filled from `Weather.event`; `src/ui/forecast_panel.gd` shows its icon (placeholder until A055 is integrated by 0269) and `FCAST_FOG`/`FCAST_RAIN` (FOG / NEBLINA, RAIN / CHUVA, widths measured), beside 0158's `FCAST_*` rows
- Rules only: fog and rain on screen are 0258's
- Hashes: DATA moves (a new table); SIM should not, since the determinism night is Spring 1 - if it does, the journal says why

  - done when: `_task_0256_fog_rain` in `src/tools/headless_v1.gd`: the event for a (seed, date) is the same however often it is asked and whatever the run RNG did; over seeds 0-49 and dates 1-56 (pure calls, no simulation) each season's share of fog and rain is within 5 points of its weight (printed); date 1 and a calm date have none; `Forecast.of` names the same event
  - done when: The same group: in fog a gun tower reaches one tile less unless its cell is lit; in rain a burn deals `rain_fire_percent` and a walker takes the slower count per tile
  - done when: `python tools/shot.py 0256 forecast_fog --fhd` (a new scenario in `src/tools/shot.gd` that finds a foggy (seed, date) through `Weather.event`, never an override) shows the event in the forecast, opened and looked at

### 0243 - Art: the day tarps

Waits on 0223, 0234.  Likely files: `assets/art_source/defences/, assets/art_source/manifest.json, src/ui/world_view.gd, tools/verify.py`.

The approved tarps cover the defences by day and unveil at nightfall, in place of the code-drawn covers 0223 left.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A044` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A044-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/defences/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (a tarp checker such as `tools/check_tarp_art.py` wired into `tools/verify.py`, or the tower and barrier checkers, `ArtPlacement` if needed).
- One cover per footprint 0234 settled (32x48 towers, 16x32, 16x24) plus its 2 unveil frames; the family list comes from the pack's Deliverables table, and the unveil plays in the transition's wake pass
- A hurt or wrecked defence still reads by day the way 0223 decided
- Retire 0223's code-drawn covers from 0120's placeholder registry
- Set the pack to integrated: `python implementation/backlog/assets.py set A044 integrated`.

  - done when: The family checks (the tarp checks - the new checker, or the tower and barrier checkers that took them) and the showcase (`python tools/show_art.py --towers --check` and `python tools/show_art.py --barriers --check`) pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures by day and by night of covered defences of every footprint and their unveil at nightfall in the real game, opened and looked at, in `implementation/shots/0243/`
  - done when: The sim and data hashes are unchanged (art never moves them)

### 0244 - Art: power and new weapon icons

Waits on 0233, 0234.  Likely files: `assets/art_source/ui/, assets/art_source/manifest.json, tools/check_ui_art.py`.

The approved icons of the three powers and the nine new defences replace the hotbar and HUD stand-ins 0233 and 0234 left.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A045` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A045-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/ui/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`tools/check_ui_art.py`, `ArtPlacement` if needed).
- `ui/icon_*` (16x16) and `ui/hud_*` (10x10) cut from one source each, as the resource icons are, for `farm_bell`, `call_dog`, `emergency_repair` and the decoy, zombie bait, beehive, catapult, garlic braid, searchlight, electric fence, hardwood wall and sandbags (the ids 0231 and 0233 chose)
- The hotbar and the night HUD read them by id; extend `check_ui_art.py`'s counts for the pack
- Retire the icon stand-ins of 0233 and 0234 from 0120's placeholder registry
- Set the pack to integrated: `python implementation/backlog/assets.py set A045 integrated`.

  - done when: The family checks (`check_ui_art.py`) and the showcase (`python tools/show_art.py --ui --check`) pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures by day and by night of the hotbar and the power bar in the real game, opened and looked at, in `implementation/shots/0244/`
  - done when: The sim and data hashes are unchanged (art never moves them)

### 0249 - The crow

Waits on 0218, 0233, 0234.  Likely files: `src/core/enemies.gd, src/core/traps.gd, src/core/towers.gd, src/core/farming.gd, src/core/events.gd, src/core/game_data.gd, src/ui/world_view.gd, src/ui/log_panel.gd, src/ui/names.gd, src/ui/describe.gd, src/ui/sfx.gd, assets/locale/strings.csv, src/tools/shot.gd, src/tools/headless_v1.gd`.

The first thing that does not walk: it flies over walls and mines and lands to eat the field. Defending the farm stops being only about the house and starts being about the harvest.

- `ENEMIES.crow` with `# LEVER`s (hp, `ticks_per_tile` in flight, damage, reward, `peck_ticks` to eat one crop) and a `flies` flag; `check_enemies`: a flyer declares neither `ignores_structures` nor `targets_structures` and is left out of the 'fastest kind that stops' comparison (a fast crow counted there would fail the runner). Inside `_task_0051_tank`'s non-boss bounds
- Straight flight, no sweep: it heads for the nearest plot with a crop in `state["plots"]` (Manhattan, ties by the lower cell index) one unit at a time along the dominant axis, like `_walk`'s inner loop, ignoring walls and occupants; with no crop on the farm it flies at the house and bites
- Landed, it waits `peck_ticks`, then the crop is eaten through a `Farming` helper (the plot stays tilled and loses crop and growth - reuse 0155's trampling path if it fits) and it takes off for the next one; a new `Events.KINDS` entry `crop_eaten` with a `LogPanel.SEVERITY` entry and a `line_for` branch (`LOG_CROP_EATEN`, 'a crow ate the %s' / 'um corvo comeu %s')
- Barriers and mines never see it: `Traps.tick` skips flyers, and it never reaches `_gnaw` or the fields; it moves inside `Enemies.tick`, so `PerfNames` is unchanged
- Which defences hit it is data: a `hits_flying` flag on every DEFENCES entry with `reload_ticks` (0224-0231's included), refused by `check_defences` when missing so any later defence must choose; `Towers._acquire`, `_burn_cone`, `_pierce_line` and splash landings (`_land_at`) skip flyers otherwise. Decide the powers too (the flare and 0233's bell and dog) and whether a landed crow counts as on the ground; the table and the reasons go in the journal
- Names.KEYS `crow`, `ENEMY_CROW`/`ENEMY_CROW.other` (crow/crows, corvo/corvos); `DESC_FLIES` in `Describe.enemy`; `Sfx.ENEMY_SOUNDS.crow` borrows `sfx/groan_runner` until 0284
- On screen: drawn above its cell with a code-drawn shadow on the ground (the pack's flying exception), through 0120's placeholder road with its forecast head until A048 is integrated by 0262
- Hashes: DATA moves (ENEMIES and the DEFENCES flags); SIM should not

  - done when: `_task_0249_crow` in `src/tools/headless_v1.gd`: a crow spawned behind a wall line reaches a planted plot in the straight-line tick count, eats it after `peck_ticks`, crosses a mine without setting it off, and is acquired only by `hits_flying` towers
  - done when: With nothing planted it reaches the house and bites, so an empty field never softlocks a night
  - done when: `python tools/shot.py 0249 crow` (a new scenario) opened and looked at: in flight it reads as above the wall, landed as on the field
  - done when: the Deliverables table of `implementation/backlog/packs/A048-crow.md` states the final geometry this task settled

### 0250 - The digger

Waits on 0218, 0234.  Likely files: `src/core/pathing.gd, src/core/enemies.gd, src/core/towers.gd, src/core/game_data.gd, src/ui/world_view.gd, src/ui/names.gd, src/ui/describe.gd, src/ui/sfx.gd, assets/locale/strings.csv, src/tools/perf_check.gd, tools/perf_baseline.txt, src/tools/shot.gd, src/tools/headless_v1.gd`.

The enemy that makes a fence a different thing from a wall: it tunnels under fences and barricades and comes up on the other side. Only a real wall stops it.

- `ENEMIES.digger` with `# LEVER`s (hp, `ticks_per_tile` slower than the runner's 9 so `check_enemies` holds, damage, reward, armour) and a `burrows` flag; inside `_task_0051_tank`'s non-boss bounds
- A burrow field through 0218's named-field registry, built on first request by a digger, so a night without one never builds it: a barrier flagged `burrowable` costs only the ground under it (`Pathing._through` and `_entry_costs`), everything else as in the flow field
- `check_defences` makes every barrier (`path_cost` > 0) declare `burrowable`: fence and barricade yes, wall no (0231's hardwood wall is the wall's `TOWER_LEVELS` row and inherits it); 0231's sandbag barrier, 0230's electric fence and anything else with a `path_cost` decided and written in the journal
- On a `burrowable` barrier's cell it is underground: in `Enemies._walk` it passes instead of `_gnaw`ing, `Towers._acquire` (0218's bucketed version) cannot target it and the barrier loses nothing; on open ground it surfaces, and walls and the house are gnawed and bitten as a walker does (`_gnaw`, `_bite`)
- The tie-breaks of `Grid.STEPS` and 0049's rule hold: a digger never alternates between two cells for 20 ticks
- A digger case in `src/tools/perf_check.gd` (its own `PERF` line, fifty walls and fences, the burrow field built): its path rebuild stays inside `PATH_BUDGET_US` (33333 us) in `python tools/perf.py --report`, the baseline accepted with the reason in the journal
- Names.KEYS `digger`, `ENEMY_DIGGER`/`ENEMY_DIGGER.other` (digger/diggers, escavador/escavadores); `DESC_BURROWS` ('digs under fences' / 'cava por baixo das cercas'); `Sfx.ENEMY_SOUNDS.digger` borrows `sfx/groan_breaker` until 0284
- On screen through 0120's placeholder road: a tinted stand-in, a code-drawn mound while underground and its forecast head, until A049 is integrated by 0263
- Hashes: DATA moves; SIM should not (no digger in the determinism night, so no field is built)

  - done when: `_task_0250_digger` in `src/tools/headless_v1.gd`: a digger reaches the house through a ring of fences without a fence losing a hit point, a ring of walls makes it gnaw, and a tower cannot target it while it is under a fence
  - done when: The same group asserts the burrow field is never built on a night without a digger
  - done when: `python tools/shot.py 0250 digger` (a new scenario) opened and looked at: the mound reads as under the fence
  - done when: the Deliverables table of `implementation/backlog/packs/A049-digger.md` states the final geometry this task settled

### 0257 - The Blood Moon

Waits on 0256, 0219, 0246.  Likely files: `src/core/weather.gd, src/core/entities.gd, src/core/combat.gd, src/core/game_data.gd, src/core/rewards.gd, src/core/tech.gd, src/ui/forecast_panel.gd, src/ui/result_screen.gd, assets/locale/strings.csv, src/tools/shot.gd, src/tools/headless_v1.gd`.

A rare red night from autumn on: the horde comes back stronger and pays in essence. Rare enough to be an occasion, forecast so it is never an ambush.

- `blood_moon` joins `GameData.NIGHT_EVENTS`: weight 0 in spring and summer (refused otherwise by `check_night_events`), a small `# LEVER` weight in autumn and winter; `Weather.event` never returns it when `Calendar.is_boss_night(date)` (an elite boss is another balance problem); decide whether it may fall on `Calendar.is_full_moon(date)` and say why
- Elites: on a Blood Moon night `Entities.spawn` (reading `Weather.event` for `Calendar.date(state)`) scales hp by `blood_moon_hp_percent` (120-200, integers) and writes `max_hp` on the elite only, so ordinary nights are untouched and 0246's `Combat.full_hp` (and any health bar that reads it) uses it
- Extra essence through 0219's earn rules: a `blood_moon_essence` `# LEVER` in `GameData.REWARDS`, its own itemised line in `Tech.would_pay` on a won night, shown in the morning report as a `RES_*` row in both languages; `nights_paid` still stops it paying twice
- In the forecast slot (`Forecast.of`'s `event`, `forecast_panel.gd`): `FCAST_BLOOD_MOON` (BLOOD MOON / LUA DE SANGUE) and the icon placeholder until A055 is integrated by 0269
- `Waves.size_of` and the forecast count do not change: elites are tougher, not more
- Hashes: DATA moves; SIM should not (`max_hp` exists only on elites)

  - done when: `_task_0257_blood_moon` in `src/tools/headless_v1.gd`: over seeds 0-49 and dates 1-56 (pure calls) no Blood Moon falls in spring, summer or on a boss night, and the autumn and winter counts are printed; on one, a walker spawns with the scaled hp and `full_hp` reads it; winning pays the extra essence, once
  - done when: `python tools/shot.py 0257 forecast_blood_moon --fhd` (a new scenario that finds a Blood Moon (seed, date) through `Weather.event`) shows it in the forecast, opened and looked at
  - done when: the Deliverables table of `implementation/backlog/packs/A055-event-icons.md` states the final geometry this task settled (fog, rain and Blood Moon at 16x16 and 10x10)

### 0265 - Art: the wraith

Waits on 0252, 0246.  Likely files: `assets/art_source/enemies/wraith/, assets/art_source/manifest.json, assets/art_source/ownership.json, tools/check_enemy_art.py, tools/gen_sprites.py, src/ui/enemy_motion.gd, src/ui/wraith_fade.gdshader`.

The wraith as Codex drew it, in place of 0252's stand-in, fading in and out of the light through 0252's shader.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A051` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A051-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/enemies/wraith/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`gen_sprites.migrated_enemies()`, `check_enemy_art.FAMILIES`, `EnemyMotion.FAMILIES`/`TRACKED`).
- At 64x48 pivot (32,44): the float loop as `wraith_walk_0..3`, `wraith_attack_0..2`, the dissipate as `wraith_death_0..3`, with the usual aliases and the forecast head; the art is opaque with binary alpha (the checker refuses any partial alpha), transparency is 0252's shader
- Replace 0252's placeholders in 0120's registry and check the shader on the real art: faint in the dark, solid in light
- Set the pack to integrated: `python implementation/backlog/assets.py set A051 integrated`.

  - done when: `python tools/check_enemy_art.py` and `python tools/show_art.py --enemies --check` pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures in the real game by day (the head in the dusk forecast) and by night (one in the searchlight beam, one outside it), opened and looked at, in `implementation/shots/0265/`
  - done when: the sim and data hashes are unchanged (art never moves them)

### 0266 - Art: the Harvester

Waits on 0253.  Likely files: `assets/art_source/enemies/harvester/, assets/art_source/manifest.json, assets/art_source/ownership.json, tools/check_giant_art.py, tools/gen_sprites.py, src/tools/headless_check.gd, src/tools/giant_showcase.gd, src/ui/enemy_motion.gd`.

The Harvester as Codex drew it, in place of 0253's stand-in: the wind-up you learn to fear and the charge that follows it.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A052` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A052-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/enemies/harvester/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`gen_sprites.migrated_enemies()`, 0246's boss table in `check_giant_art.py`, `ArtPlacement` if the canvas is larger than 80x64).
- At the canvas 0253 settled (80x64 pivot (40,60), or up to 112x80): `harvester` master, `harvester_walk_0..3` (move), `harvester_windup_0..2`, the charge/crush frames, `harvester_death_0..4`, the wreck debris and the forecast mark; 0246's boss path picks the windup on the telegraph and the charge frames while 0253's charge runs
- Replace 0253's placeholders in 0120's registry; the telegraph strip on the ground stays code. The first boss leaf to land (0266-0268, any order) rewrites `_task_0074_zombie_art`'s 'the Giant is the biggest thing on the field' as 'every boss outsizes every non-boss'
- Set the pack to integrated: `python implementation/backlog/assets.py set A052 integrated`.

  - done when: `python tools/check_giant_art.py` and `python tools/show_art.py --boss=harvester --check` pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures in the real game by day (the mark in the dusk forecast) and by night (wind-up with the strip, and mid-charge), opened and looked at, in `implementation/shots/0266/`
  - done when: the sim and data hashes are unchanged (art never moves them)

### 0283 - The guardian's sounds

Waits on 0233, 0234.  Likely files: `tools/gen_sfx.py, assets/sfx/, src/ui/sfx.gd, src/ui/main.gd, src/app/audio.gd, src/tools/headless_check.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd`.

The night is played through the cursor now, so the cursor's work, the START horn, the four powers and the new defences get sounds - heard from where the guardian is looking, not from the farmer asleep in bed. View only: neither hash moves, and no state key is added to be heard.

- The ears: at night `Sfx` calls `listen_at` with the centre of 0130's night camera (`main.gd` owns the `WorldView`; hand it over the way `Music.show_state` gets it), not `_where_the_player_is()` (the sleeping farmer), and `nearest_by_kind` measures from the same point. `Audio` has no getter for its ears today: add one if the checks need it. If 0130 already did this, say so and move on
- The cursor's hand, quieter than the weapons (at most `SOFT_PEAK`) and played at its cell: place (a defence that appears), upgrade (its `level` rising), repair (hp or `house_hp` rising in PREPARATION/NIGHT, not the fill `begin_night` does) and sell. A defence that vanishes leaving rubble (`Farm.rubble_at`) broke and one that leaves none was sold - `_watch_structures` sounds every vanished non-mine as `wall_break` today, and a sale must not; put the decision in a static helper the checks can ask
- The START horn on 0136's PREPARATION -> NIGHT edge: once a night, with no position (`AudioScript.NOWHERE`), on the `DUCKS` list, below `NIGHT_PEAK`
- The powers of 0232/0233 - flare, farm bell, the dog and emergency repair - each heard when its cooldown rises (the reading `_watch_towers` uses for `reload`), at the aimed cell; the bell, which stops every zombie, with no position. The dog's bark and bite are written here (moved from 0281; 0286 leaves the dog out of its animal calls)
- The defences of 0224-0231: a straw rustle when the decoy is hit, the beehive's buzz, the catapult's thunk (and a splat where the pumpkin lands, if the shell is already in the state), the searchlight's hum and the electric fence's zap when it stuns. Buzz and hum are per kind and not per structure - from the nearest stinging hive or lit searchlight, the way groans are - so ten hives are not ten loops
- Replace every borrowed entry 0224-0231 put in `Sfx.TOWER_SOUNDS` to keep `_task_0085_night_sounds` green. That group's rule still holds: `TOWER_SOUNDS` lists exactly the defences with `damage` (their shot), so the rustle, the hum and the zap of defences without it - and the buzz, if it is not the hive's shot - go in a table of their own (e.g. `DEFENCE_SOUNDS`). The house being hit stays the loudest file in `assets/sfx/`, and every new night file stays shorter than the Giant's roar, which that group still asserts is the longest night sound until 0284 rewrites it
- Extend `_night_sound_ids()` in `headless_check.gd` with every new list, because `_task_0084_day_sounds` builds its 'nothing in the folder is unreached' set from it

  - done when: `_task_0283_guardian_sounds` in `src/tools/headless_v1.gd`: every new id is a file under `NIGHT_PEAK`, no two damaging defences share a file, every defence without `damage` is out of `TOWER_SOUNDS`, and the sold/broken/spent helper answers right for a crafted sale, a wreck with rubble and a spent mine
  - done when: `_case_0283_guardian_sounds` in `src/tools/input_v1.gd`: in the build step the cursor places, upgrades and sells a defence and `Audio.last_played()` is place, upgrade, sell (never `sfx/wall_break`); START plays the horn; an aimed flare plays the flare; panning the camera away from a firing tower makes it quieter (`Audio.loudness`)
  - done when: `_task_0084_day_sounds` and `_task_0085_night_sounds` pass; `python tools/gen_sfx.py --report` for the new sounds is in the journal

### 0254 - The Scarecrow King

Waits on 0246, 0249.  Likely files: `src/core/enemies.gd, src/core/game_data.gd, src/ui/enemy_motion.gd, src/ui/world_view.gd, src/ui/names.gd, src/ui/describe.gd, src/ui/sfx.gd, assets/locale/strings.csv, src/tools/shot.gd, src/tools/headless_v1.gd`.

Autumn's boss calls the sky down: it stops, casts, and a flock of crows rises around it. It asks what the crow asked - cover in the air and care for the field - under pressure.

- `ENEMIES.scarecrow_king` with `is_boss` and `# LEVER`s: hp, armour, `ticks_per_tile`, damage, reward, `telegraph_ticks` (the cast), `summon_every_ticks`, `flock_size`, `summon_cap` (crows it may raise in one night, so a long fight cannot flood the farm); it passes 0246's boss-against-non-boss asserts
- Summons on deterministic cells: a fixed list of offsets around its cell (a table in `game_data.gd`, listed in `digest()`), clipped to the map, taken in list order - no RNG draw. They are 0249's `crow` through `Entities.spawn`, flying from there to the field; `check_enemies` refuses a `flock_size` above the offsets, a `summon_cap` below `flock_size`, or a summoned kind that does not fly
- Summoned crows are not wave members: `Waves` counts and the forecast are unchanged, and the night still ends at dawn (0137) or when everything is dead; decide whether they pay bounty (a farmable King is an exploit) and say why
- The cast is the telegraph: it stands for `telegraph_ticks` and is `is_winding` (reusing `winding_at`/`chew_wait`, as `_gnaw` does), so the 0246 bar flashes; otherwise it walks the flow field and bites like a walker, inside `Enemies.tick`
- Autumn's day-14 boss: `GameData.SEASON_BOSSES[2]` becomes `&"scarecrow_king"` (any group that put a Giant on Autumn 14 is rewritten in place); `BOSS_INTRO_SCARECROW_KING`; Names.KEYS `scarecrow_king`, `ENEMY_SCARECROW_KING`/`.other` (scarecrow king/scarecrow kings, rei espantalho/reis espantalhos) and `DESC_SUMMONS` ('calls down crows' / 'chama os corvos'); `Sfx.ENEMY_SOUNDS.scarecrow_king` borrows `sfx/roar_giant` until 0284
- On screen through 0120's placeholder road: a cast pose, the flock rising and its forecast mark at the boss canvas, until A053 is integrated by 0267
- Hashes: DATA moves (ENEMIES, the offsets, SEASON_BOSSES); SIM should not - the determinism night is Spring 1

  - done when: `_task_0254_scarecrow_king` in `src/tools/headless_v1.gd`: each cast raises `flock_size` crows on the listed cells after exactly `telegraph_ticks`, two runs agree cell for cell, and no night raises more than `summon_cap`
  - done when: The same group: a King with a planted field and no `hits_flying` cover costs crops, one with cover over the field costs few - print both counts
  - done when: `python tools/shot.py 0254 scarecrow_king` (mid-cast) opened and looked at
  - done when: the Deliverables table of `implementation/backlog/packs/A053-scarecrow-king.md` states the final geometry this task settled

### 0258 - Fog, rain and a red moon on screen

Waits on 0256, 0257.  Likely files: `src/ui/lighting.gd, src/ui/particles.gd, src/ui/fog.gdshader (new), src/ui/world_view.gd, tools/palette.py, src/ui/palette_data.gd (generated), src/tools/perf_check.gd, tools/perf_baseline.txt, src/tools/shot.gd, src/tools/input_v1.gd`.

Fog that looks like fog, rain you can see, a red moon that makes the farm look wrong - and none of it touches a rule.

- View only, both hashes unchanged: everything reads `Weather.event` (0256, 0257) and `Light.is_lit` (0229), and nothing writes the state
- Fog: a code noise shader over the world (no new PNG), thinner on lit cells so the searchlight visibly cuts it
- Rain: particles in `particles.gd` bounded by the accessibility particle density setting (`a11y/particle_density`), a darker night ramp, and a mud tint on walkable ground
- Blood Moon: a red night ramp. Ramps go the road 0152 used for the Full Moon: `rain` and `blood_moon` entries in `tools/palette.py` `RAMPS`, written into `PaletteData` by `python tools/gen_sprites.py` (never edit `palette_data.gd`), picked by `WorldView._night_ramp()`. Check that the Full Moon still reads brighter than an ordinary night and that the ramps (ordinary, Full Moon, fog, rain, Blood Moon) are told apart at a glance
- Cost: `perf_check.gd`'s view timing (`_view`, today's `view_lighting`/`view_particles`) gains a rain night at 4x as its own `PERF` line (e.g. `view_rain`), inside `tools/perf.py`'s tolerance and accepted with the reason in the journal
- Shot scenarios `fog`, `rain`, `blood_moon` and `full_moon` in `src/tools/shot.gd`, each finding a (seed, date) through `Weather.event` or `Calendar.is_full_moon` rather than an override

  - done when: `_case_0258_event_visuals` in `src/tools/input_v1.gd`: each event turns its layer on with the night and off at dawn, the rain particle count follows the density setting, and a night with the layers on and one with them off end on the same SIM hash
  - done when: `python tools/shot.py 0258 fog rain blood_moon full_moon --fhd` opened and looked at beside `docs/reference-sheet.png`: the farm stays readable in every one

### 0262 - Art: the crow

Waits on 0249, 0246.  Likely files: `assets/art_source/enemies/crow/, assets/art_source/manifest.json, assets/art_source/ownership.json, tools/check_enemy_art.py, tools/gen_sprites.py, src/ui/enemy_motion.gd, src/ui/world_view.gd`.

The crow as Codex drew it, in place of 0249's stand-in: in the air, landing, pecking and falling.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A048` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A048-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/enemies/crow/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`gen_sprites.migrated_enemies()`, `check_enemy_art.FAMILIES`, `EnemyMotion.FAMILIES`/`TRACKED`).
- The flying exception: `crow_fly_0..3` (loop), `crow_land_0`, `crow_peck_0..2`, `crow_death_0..3` (the fall), side view mirrored at runtime; the checker takes this family's motions from its own row (not the fixed walk/attack/death `COUNTS`), exempts flying frames from the ground-contact row and asserts no baked shadow - the shadow stays 0249's code shadow. Keep `crow`, `_walk_b`, `_attack`, `_death` aliases (or teach `_task_0074_zombie_art` the exception) so the suite's art groups still pass
- `EnemyMotion` maps 0249's states (in flight, landed, pecking, falling) to these names and keeps 0249's height offset; replace 0249's placeholders and the forecast head in 0120's registry
- Set the pack to integrated: `python implementation/backlog/assets.py set A048 integrated`.

  - done when: `python tools/check_enemy_art.py` and `python tools/show_art.py --enemies --check` pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures in the real game by day (the head in the dusk forecast) and by night (one over a wall, one pecking a crop), opened and looked at, in `implementation/shots/0262/`
  - done when: the sim and data hashes are unchanged (art never moves them)

### 0263 - Art: the digger

Waits on 0250, 0246.  Likely files: `assets/art_source/enemies/digger/, assets/art_source/manifest.json, assets/art_source/ownership.json, tools/check_enemy_art.py, tools/gen_sprites.py, src/ui/enemy_motion.gd`.

The digger as Codex drew it, in place of 0250's stand-in: going down, the mound moving under the fence, coming up.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A049` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A049-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/enemies/digger/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`gen_sprites.migrated_enemies()`, `check_enemy_art.FAMILIES` with its extra motions, `EnemyMotion.FAMILIES`/`TRACKED`).
- At 64x48 pivot (32,44): `digger_walk_0..3`, `digger_burrow_0..3` (one-shot), `digger_mound_0..N` (loop, 2-3 frames), `digger_emerge_0..3`, `digger_attack_0..2`, `digger_death_0..3` with the usual aliases, and the forecast head
- `EnemyMotion` plays burrow on the tick 0250 puts it underground, the mound while it stays there and emerge when it surfaces; replace 0250's placeholders in 0120's registry
- Set the pack to integrated: `python implementation/backlog/assets.py set A049 integrated`.

  - done when: `python tools/check_enemy_art.py` and `python tools/show_art.py --enemies --check` pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures in the real game by day (the head in the dusk forecast) and by night (a mound under a fence line), opened and looked at, in `implementation/shots/0263/`
  - done when: the sim and data hashes are unchanged (art never moves them)

### 0269 - Art: fog, rain and the Blood Moon icons

Waits on 0256, 0257.  Likely files: `assets/art_source/ui/, assets/art_source/manifest.json, assets/art_source/ownership.json, tools/check_ui_art.py, src/ui/forecast_panel.gd`.

The three night events as Codex drew them, in the forecast slot where 0256 and 0257 left placeholders.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A055` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A055-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/ui/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`check_ui_art.py` pins the 0018 resource set - add this pack as its own checked block).
- `ui/icon_fog`, `ui/icon_rain`, `ui/icon_blood_moon` at 16x16 pivot (8,8) and the matching `ui/hud_*` at 10x10 pivot (5,5), each pair cut from the same raw source at different nearest scales (visible size at most 14 and 8 px)
- Replace 0256's and 0257's placeholders in the forecast slot (`src/ui/forecast_panel.gd`, 0158) through 0120's registry
- Set the pack to integrated: `python implementation/backlog/assets.py set A055 integrated`.

  - done when: `python tools/check_ui_art.py` and `python tools/show_art.py --ui --check` pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures in the real game by day (each event in the dusk forecast) and by night (the build step's forecast), opened and looked at, in `implementation/shots/0269/`
  - done when: the sim and data hashes are unchanged (art never moves them)

### 0270 - Fifty-six nights as data

Waits on 0256, 0257, 0234.  Likely files: `src/core/game_data.gd, src/core/waves.gd, src/core/endless.gd, src/core/almanac.gd (new), src/core/weather.gd, src/tools/nights.gd, tools/nights.py, src/tools/headless_check.gd, src/tools/headless_v1.gd`.

The year stops being ten written nights plus a curve and becomes tables a designer can read: a template per season, hand-written key nights (every introduction, every Full Moon) and a seeded generator for the nights in between. Nothing downstream of `Waves.night_of` can tell which is which, so the season tasks after this one edit data (0271 also gives `play_nights` a day range).

- A night is still `{note, opening_ticks, gap_ticks, waves}` with waves `[kind, count, spawn, delay?]`, so `Waves`, `Enemies`, `Rewards`, the forecast (0158) and the HUD need no new case. Two new tables in `src/core/game_data.gd`: `SEASON_NIGHTS` (per season: the sides it deals from - indices open for that season in 0157's `SIDES_BY_SEASON`, never a second copy of that table - each with the day it joins, so a season brings a new side in gently; the kinds of its mix with a weight and the day each joins; a size in hit points - the honest measure 0060 used, `play_nights.gd`'s `_hit_points_of` - at the season's second and thirteenth day; waves and gap from/to; every number a `# LEVER` with a range) and `KEY_NIGHTS` (day of the year 1-56 -> a record)
- Key nights are each kind's introduction and the Full Moons on days 7 and 14 of every season. No record names a boss: 0153's rule in `Waves.night_of` adds the `SEASON_BOSSES` row on day 14 (0253-0255 put theirs there), so a day-14 key night writes only the boss's company. Draft content so all 56 resolve: today's nights 1-9 as spring's days 1-9 and today's 10, without its Giant row, as day 14, their south-east rows moved to the east; delete 0157's commented allowance for today's ten, which nothing needs now (0271 has nothing left to remove). Day 1 stays byte-identical. Summer to winter get drafts that send spring's kinds only; 0271-0274 author them for real
- Days 15, 29 and 43 are 0154's calm dates (`Calendar.is_calm`): `night_of` already returns the calm record for them, so they carry no key night and the generator never makes one
- A node-free generator - `src/core/almanac.gd` with `Almanac.night(seed, day)`, or the home 0150/0158 already gave the calendar lookup (extend it, never a second one) - fills every other day from its season's template with a fresh stream from `(seed, day)` (the `Endless._stream_for` pattern), never `state["rng"]`. The seed orders the waves and picks among the open sides; it never changes the totals per kind (the `Endless` contract)
- `Waves.plain_night(day, seed)` (0150) is where the year comes from - the key night first, else the generator - and `night_of` keeps 0152-0154's rules on top of it, unchanged. `Waves.tonight` keeps caching generated records on `state.wave.tonight`, so no new State key and `remaining()` stays free per frame. `GameData.NIGHTS` retires here (its rows are spring's draft) and `Waves.authored_count()` with it: grep `src/` and `tools/` for both and move every reader. Past day 56 the lookup keeps serving `Endless.night` until 0279 (if its base or step must read something new, the journal says what day 57 sends before and after); `perf_check.gd`'s worst case stays on Spring 14 (0153) until 0275
- Decide in one place whether 0152's Full Moon percent scales an authored Full Moon record or is already written into it - one, never both, and the forecast's count equals what is sent. A key night may pin or forbid an event with an optional `event` field, read by 0256's `Weather` chooser for that `(seed, day)`; a pin still obeys `check_night_events` (no Blood Moon before autumn or on a boss night, nothing on Spring 1 or a calm date)
- `GameData.check_nights(templates, key_nights)` takes its tables as arguments, as it takes `nights` today, so a test can hand it a broken copy. It refuses: a boss in any template or key night (the boss row is 0153's); an unknown kind in a template; a side not open in that season (0157); a size that falls or a gap that grows across a season (0060's curve rules); a key-night day outside 1-56 or on a calm date; a Full Moon day without a key night; a schedule that outlasts the night (0137); an unknown `event`. The per-record rules are one function: `validate()` runs it on seed 0's year only, so loading stays cheap, and 0151's `python tools/nights.py --check` gate runs it on every date for its two seeds
- `GameData.digest()` lists `SEASON_NIGHTS` and `KEY_NIGHTS` and drops `NIGHTS` (0112's coverage assert passes). DATA moves on purpose; SIM should not, day 1 being identical - if it moves, the journal says why. What 0150-0153 left of `_task_0058_giant`, `_task_0059_wave_data`, `_task_0060_ten_nights` and `_task_0070_endless` in `src/tools/headless_check.gd` that reads `GameData.NIGHTS` rows reads the year through `Waves.plain_night` instead, keeping what each asserted
- `python tools/nights.py` prints the year by default: a block per season, each day's kinds, sides, count, hit points, reward and event, with key, Full Moon, boss and calm days marked, then first-seen per kind and the size bars. Its positional arguments change from today's `[count] [seed]` to `[from] [to] [seed]` (`python tools/nights.py 15 28 3` prints a range); `--check` stays; the docstrings of `nights.gd` and `nights.py` say so

  - done when: `_task_0270_year_records` in `src/tools/headless_v1.gd`: for seeds 0-4 every day 1-56 is a key night, a generated record or a calm date; generated records pass the per-record rules an authored one does; two seeds send the same totals per kind on every day; generating day 30 leaves `state["rng"]` untouched; no kind is sent before the day its key night or template introduces it; day 1's record equals the old night 1
  - done when: The same group hands `check_nights` doctored copies - a boss in a key night, an unknown kind in a template's mix, a spring night from the south-east, a key night on day 15 - and each is refused
  - done when: For days 1-56 and two seeds, 0158's forecast counts equal `Waves.size_of`/`kinds_of` for the same day
  - done when: The year from `python tools/nights.py` is in the journal: count, hit points and reward per day, by season

### 0286 - Fog, rain and winter wind

Waits on 0256, 0257, 0285.  Likely files: `tools/gen_ambience.py, assets/ambience/, tools/gen_music.py, assets/music/, src/ui/ambience.gd, src/ui/music.gd, src/tools/headless_check.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd`.

The bed under everything follows the weather and the season: fog and rain on the nights that have them, wind through the winter, the animals heard near their coop and barn, and a short stinger when an event night reaches its build step. View only: neither hash moves. (The animal calls came from 0281 and the stingers from 0284, so those fit one invocation.)

- `tools/gen_ambience.py` writes a fog bed and a rain bed for the night, and a winter bed (wind, no birds, no crickets) for winter's day and night, looped with its `seamless()` and under `BED_PEAK` - the bed stays the quietest thing in the game
- `Ambience.bed_for` stays static and gains the season and tonight's event: an event night's bed beats the season's, and winter's beats the ordinary day and night beds. The event is 0256's `Weather` answer for `(seed, day)` (0257 added the Blood Moon to it) - the function the forecast panel calls, never a second draw and never the view's own `RandomNumberGenerator`
- Touches by season: winter gets its own short lists (no crickets, no songbirds), and no touch is in both a day list and a night list
- Animals near barns, written here (moved from 0281): cluck, moo, baa and oink in `gen_ambience.py` from `gen_sfx`'s primitives (it already imports `gen_sfx`), at most `TOUCH_PEAK`, played at the coop's and the barn's cells through the existing falloff - by day while the building stands with animals of that kind in it (0183's residents), and as a sleepy murmur at night, when they sleep inside (0186). The dog is not here: its bark is 0283's power sound. Decide whether a wrecked-but-standing barn still murmurs
- The beds change on the cue they use today (`Audio.play_bed` with the transition's length); nothing changes the bed in the middle of a night
- Event stingers (moved from 0284): fog, rain, the Blood Moon (0257) and the Full Moon (0152) as short cues in `tools/gen_music.py` beside `sting` - `PIECES` entries, at most `STING_PEAK`, named in 0285's not-loop list - played once through `Audio.play` (the Music bus, because the file is in `assets/music/`) when a night with that event reaches its build step. The event is the same `Weather` answer the bed reads (the Full Moon is 0152's `Calendar.is_full_moon`), never decided in the view
- Rewrite `_task_0087_ambience` in `headless_check.gd` for the new `bed_for`: every file is still asked for, every bed loops (`_loop_seam` at most 1.0) and peaks under 0.3, and the house being hit still stands far above the ducked bed

  - done when: `_task_0286_weather_ambience` in `src/tools/headless_v1.gd`: `bed_for` answers for every season, phase and event; each new bed loops and stays under the old peak; no touch is in both a day and a night list, and winter's hold no cricket and no songbird; animal calls are offered only where a coop or barn with animals stands; each stinger is in `assets/music/`, at most `STING_PEAK` and on 0285's not-loop list
  - done when: `_case_0286_weather_ambience` in `src/tools/input_v1.gd`: a foggy night's build step plays the fog bed (`Audio.bed_playing()`) and the fog stinger once (`Audio.plays_of()`), and a winter morning the winter bed
  - done when: `python tools/gen_ambience.py --report` for the new beds (length, peak, seam) and `gen_music.py --report` for the stingers are in the journal

### 0255 - The Winter Lord

Waits on 0246, 0251, 0253, 0254.  Likely files: `src/core/enemies.gd, src/core/towers.gd, src/core/game_data.gd, src/ui/world_view.gd, src/ui/names.gd, src/ui/describe.gd, src/ui/sfx.gd, assets/locale/strings.csv, src/tools/shot.gd, src/tools/headless_v1.gd`.

The last night of the year: a lord of ice whose cast freezes every tower around it. It tests the whole build - spread, depth, light and the powers - and its fall is the ending.

- `ENEMIES.winter_lord` with `is_boss` and `# LEVER`s: hp, armour, `ticks_per_tile`, damage, reward, `telegraph_ticks` (the cast), `freeze_every_ticks`, `aura_tiles`, `freeze_ticks` (`check_enemies` refuses a zero); the strongest boss in the table (more hp than the Harvester and the King - asserted)
- The freeze sits beside 0251's chill on the occupant, never through `Farm.touch`: towers within `aura_tiles` when the cast lands stop counting their reload for `freeze_ticks` (a `frozen` countdown in `Towers.tick`/`_cool_down`); refreshed, never stacked, cleared in `Enemies.withdraw` at dawn
- The cast is telegraphed (`is_winding` for `telegraph_ticks`, so the 0246 bar flashes) and the aura's cells are a core query for the view
- Winter's day-14 boss: `GameData.SEASON_BOSSES[3]` becomes `&"winter_lord"`, and 0160's ending fires on it falling: rewrite `_task_0160_year_end` and `_case_0160_ending` to kill a Winter Lord on Winter 14 and see the ending; a Giant on that night no longer ends the year
- `BOSS_INTRO_WINTER_LORD`; Names.KEYS `winter_lord`, `ENEMY_WINTER_LORD`/`.other` (winter lord/winter lords, senhor do inverno/senhores do inverno) and `DESC_FREEZES` ('freezes the towers around it' / 'congela as torres em volta'); `Sfx.ENEMY_SOUNDS.winter_lord` borrows `sfx/roar_giant` until 0284
- On screen through 0120's placeholder road: a cast pose, the aura's reach on the ground during the wind-up, ice on frozen towers (view only) and its forecast mark, until A054 is integrated by 0268
- Hashes: DATA moves; SIM should not

  - done when: `_task_0255_winter_lord` in `src/tools/headless_v1.gd`: a cast freezes exactly the towers inside `aura_tiles` for `freeze_ticks`, `grid_version` does not move, and every tower fires again afterwards
  - done when: Killing it on Winter 14 brings up the year's ending through 0160's path and `bosses_down_of(state, &"winter_lord")` is one
  - done when: `python tools/shot.py 0255 winter_lord` (the aura during a cast) opened and looked at
  - done when: the Deliverables table of `implementation/backlog/packs/A054-winter-lord.md` states the final geometry this task settled

### 0267 - Art: the Scarecrow King

Waits on 0254.  Likely files: `assets/art_source/enemies/scarecrow_king/, assets/art_source/manifest.json, assets/art_source/ownership.json, tools/check_giant_art.py, tools/gen_sprites.py, src/tools/headless_check.gd, src/tools/giant_showcase.gd, src/ui/enemy_motion.gd`.

The Scarecrow King as Codex drew it, in place of 0254's stand-in, raising its arms as the flock comes up.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A053` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A053-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/enemies/scarecrow_king/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`gen_sprites.migrated_enemies()`, 0246's boss table in `check_giant_art.py`, `ArtPlacement` if needed).
- At the canvas 0254 settled: master, `scarecrow_king_walk_0..3`, the summon cast (4 frames) played for 0254's `telegraph_ticks`, `_attack_0..2`, `_death_0..4`, and the forecast mark
- Replace 0254's placeholders in 0120's registry; if no boss leaf has yet, rewrite `_task_0074_zombie_art`'s 'the Giant is the biggest thing on the field' as 'every boss outsizes every non-boss' (see 0266)
- Set the pack to integrated: `python implementation/backlog/assets.py set A053 integrated`.

  - done when: `python tools/check_giant_art.py` and `python tools/show_art.py --boss=scarecrow_king --check` pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures in the real game by day (the mark in the dusk forecast) and by night (mid-cast with the flock rising), opened and looked at, in `implementation/shots/0267/`
  - done when: the sim and data hashes are unchanged (art never moves them)

### 0271 - Spring's fourteen nights

Waits on 0270.  Likely files: `src/core/game_data.gd (`KEY_NIGHTS`, spring's `SEASON_NIGHTS`), src/tools/play_nights.gd, tools/play_nights.py, src/tools/headless_v1.gd`.

Spring is the season that teaches: the walker, the runner, the tank and the breaker one at a time, all from the east, a Full Moon on day 7 and the Giant on day 14. Today's ten nights are the raw material, but they were balanced for two sides and a ten-night run, so they are rewritten rather than pasted.

- First the instrument, moved here from 0270: `tools/play_nights.py` forwards its arguments (today it passes none) and `python tools/play_nights.py <from> <to>` plays that range of dates with the scripted build, buying only what each date's season has unlocked (0234's `unlock_season`, money and materials) from a purse that starts where a run would be (what the earlier dates paid plus the income). 0272-0274 author with it
- Every spring night comes from the east only (0157's east region; 0270 already deleted the allowance today's ten had). Today's night 2, 'the same again from two sides', becomes a lesson one side can teach
- The plan's rhythm: days 1-6 grow gently, day 7 is a Full Moon of the kinds already met, days 8-13 grow again with the season's novelty - the breaker, 'Primavera (fim)' - and day 14 is the Full Moon with the Giant (0153's row) in company. A starting map: today's 1-6 to days 1-6, today's 7 (breakers) to day 8, today's 8-9 spread over 9-13, today's 10 to day 14 - change it if the numbers say so
- One new thing a night at most, and the night after an introduction is where it bites (0060's rule): the walker on 1, the runner and the tank in days 2-6, the breaker in 8-13. The introductions, day 7 and day 14 are `KEY_NIGHTS`; the other days come from spring's template
- Day 1 stays the tutorial night: a normal night 1 (the calm night only follows a fallen boss), winnable with what the tutorial (0141) gives; the tutorial asserts of 0041/0141 stay green
- Every night fits the night length (0137) with room for the last wave to be fought before dawn, **and fills it** (moved here by 0148): its last wave is sent no earlier than `NIGHT_TICKS - DAWN_MARGIN_TICKS - NIGHT_FILL_TICKS`, a new `# LEVER` in `src/core/game_data.gd` (60 s, 30-120) in `digest()`'s `time` row, and `tools/nights.py` prints each night's last send against that line. 0148 measured today's ten sending everything by 36-84 s of a 240 s night: every night it played was over, everything dead, about a minute in, and none of a thousand autoplayed nights reached dawn, so the plan's 'holding on until sunrise is worth as much as killing everything' (4.5) and its three to five minutes of waves never happen. Spread the waves - a later last wave, gaps that leave quiet stretches between them - rather than shortening `NIGHT_TICKS` below the plan's three minutes; day 1 too, still winnable with the tutorial's tower
- Notes in the voice of the authored ten, English, one line each - they are what `tools/nights.py` prints
- Author against `python tools/nights.py 1 14` (count, hit points and reward climb, peaking on 7 and 14) and `python tools/play_nights.py 1 14` at its three incomes
- DATA moves on purpose; SIM moves if day 1 changed, because the determinism scenario fights it - both numbers in `implementation/PROGRESS.md`

  - done when: `_task_0271_spring_nights` in `src/tools/headless_v1.gd`: days 1-14 send only the walker, runner, tank, breaker and the Giant, only from the east; each kind is first sent on its authored introduction day; day 7 is the largest of days 1-7 and day 14 the largest of spring in hit points; the Giant is on day 14 and nowhere else; every day 1-14 sends its last wave after the fill line (`NIGHT_FILL_TICKS`) and before the dawn margin
  - done when: `python tools/play_nights.py 1 14` output is in the journal: night 1 holds at the lowest income, and every night that falls is named with what the curve does there; `python tools/play_nights.py 15 20` runs on 0270's summer draft and buys nothing summer has not unlocked
  - done when: Spring's table from `python tools/nights.py 1 14` is in the journal beside the old ten nights' numbers

### 0259 - Every weapon has its night

Waits on 0234, 0247, 0248, 0249, 0250, 0251, 0252, 0253, 0254, 0255, 0256, 0257.  Likely files: `src/tools/matchups.gd, tools/matchups.py, implementation/MATCHUPS.md`.

The plan's test for phases 4 and 5 turned into numbers: every weapon is the best buy somewhere, and every enemy needs a different answer. The report is what the night authors of 0270-0274 build the year from.

- A headless tool, not a suite group: `src/tools/matchups.gd` run by `tools/matchups.py`, seeded and deterministic, printing its run time, with `--only=<enemy>` for quick reruns; it stays out of `verify.py` (the 120 s per-suite timeout). Keep a full run to about ten minutes by shortening the lane's fight, not by dropping rows of the grid
- The arena: one fixed lane on the real farm map with a fixed base defence; for every `GameData.DEFENCES` entry (the plan's fourteen plus 0225's bait and 0231's sandbags - print the count), the same budget (0234's money plus materials, materials at `SELL_PRICE`) spent on it at the level its season allows, placed by a fixed rule; a fixed group of one enemy kind, and each boss with its season's escort
- Per pair: house damage, kills, ticks to clear and structures lost; the score is house damage prevented per unit of cost against the base alone
- The same grid under fog, rain and the Blood Moon, so the searchlight, fire and the mines get their nights
- Prove: every defence is the top buy against at least one enemy, boss or event (a barrier or a support piece - decoy, garlic, searchlight - may be scored as the best addition to the base line rather than alone; say how); no defence is top against every enemy; every new enemy's top answer differs from the walker's. Where a claim fails, a lever may move here (at most a few, DATA recorded) or the failure goes to 0277 with its numbers
- `implementation/MATCHUPS.md`: the table, each enemy's top three answers, each defence's best night, and a line per enemy for the night authors (e.g. 'rats: mines, flamethrower')

  - done when: `python tools/matchups.py` exits 0 and names, for every `DEFENCES` entry, the enemy or event where it is the best buy, or marks it UNPROVEN with its numbers; every UNPROVEN line is in the journal as handed to 0277
  - done when: Two runs write the same `implementation/MATCHUPS.md` byte for byte
  - done when: The journal answers in one paragraph, with the numbers, whether each enemy asks for a different answer, and lists any lever moved

### 0268 - Art: the Winter Lord

Waits on 0255.  Likely files: `assets/art_source/enemies/winter_lord/, assets/art_source/effects/, assets/art_source/manifest.json, assets/art_source/ownership.json, tools/check_giant_art.py, tools/gen_sprites.py, src/tools/headless_check.gd, tools/check_effect_art.py, src/tools/giant_showcase.gd, src/ui/enemy_motion.gd`.

The Winter Lord as Codex drew it, in place of 0255's stand-in: the last thing the year sends, and the cast that freezes the line.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A054` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A054-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/enemies/winter_lord/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`gen_sprites.migrated_enemies()`, 0246's boss table in `check_giant_art.py`, the effect checker for the shards, `ArtPlacement` if needed).
- At the canvas 0255 settled: master, `winter_lord_walk_0..3`, the freeze cast (4) for 0255's `telegraph_ticks`, `_attack_0..2`, `_death_0..4`, the ice aura shards (4) in the effects family, and the forecast mark
- Replace 0255's placeholders in 0120's registry; the aura's reach on the ground and the ice on frozen towers stay code. If no boss leaf has yet, rewrite `_task_0074_zombie_art`'s 'the Giant is the biggest thing on the field' as 'every boss outsizes every non-boss' (see 0266)
- Set the pack to integrated: `python implementation/backlog/assets.py set A054 integrated`.

  - done when: `python tools/check_giant_art.py`, `python tools/check_effect_art.py` and `python tools/show_art.py --boss=winter_lord --check` pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures in the real game by day (the mark in the dusk forecast) and by night (mid-cast, towers freezing), opened and looked at, in `implementation/shots/0268/`
  - done when: the sim and data hashes are unchanged (art never moves them)

### 0284 - The new enemies and bosses, heard

Waits on 0247, 0248, 0250, 0252, 0253, 0254, 0255, 0257.  Likely files: `tools/gen_sfx.py, assets/sfx/, src/ui/sfx.gd, src/tools/headless_check.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd`.

Six new enemies and three new bosses each get a voice of their own, so a night heard with your eyes shut still says what is coming. View only: neither hash moves, and no state key is added to be heard. (The night events' stingers moved to 0286, beside the event beds, so this fits one invocation.)

- Recipes for the spitter (the spit, and a splat on the tower 0247's projectile hits), the rat swarm (a squeak), the crow (a caw over wingbeats), the digger (a burrowing rumble and a burst when it surfaces), the frost zombie (a shatter as it dies and a crackle on the towers it chills) and the wraith (a whisper)
- Voices stay per kind and not per body: `nearest_by_kind` keeps a swarm of fifty rats to one voice (0085's promise). Deaths that differ by kind go through a small per-kind table that falls back to `DEATH_SOUND` and keeps `DEATH_GAP`
- The wraith cannot be shot outside light (0252): decide whether its whisper plays with no position (you know they are out, not where) or only from wraiths in light, and write why in the journal
- Three boss voices - the Harvester's engine, the Scarecrow King's call, the Winter Lord's ice - and their specials: the Harvester's charge telegraph and the crunch of the walls it crushes, the King summoning crows, the Winter Lord's freezing aura; each special heard on the edge its telegraph or effect already sets in the state (`is_winding`, 0253's `charge_line`, 0251's `Towers.chill_left`, 0255's `frozen` countdown), read like `reload`
- Every boss is announced like the Giant: on arrival, with no position, ducking the ambience. Wherever `sfx.gd` still tests `kind == &"giant"` (`_watch_bodies`, `nearest_by_kind`, `_ducks`), read `is_boss` instead, unless 0246 already did
- Rewrite `_task_0085_night_sounds`: 'the Giant's roar is the longest sound at night' becomes 'every boss voice is longer than every ordinary night sound'; the house being hit stays the loudest file (bosses at `GIANT_PEAK` or below); replace each borrowed `ENEMY_SOUNDS` entry 0247-0255 left
- Extend `_night_sound_ids()` so every new file in `assets/sfx/` is reached. The event stingers (fog, rain, the Blood Moon, the Full Moon) are not this task's: 0286 writes and plays them

  - done when: `_task_0284_enemy_sounds` in `src/tools/headless_v1.gd`: every enemy in `GameData.ENEMIES` has a voice file of its own, every boss voice is longer than any ordinary night sound and quieter than the alarm, and fifty rats are one entry in `nearest_by_kind`
  - done when: `_case_0284_boss_voices` in `src/tools/input_v1.gd`: a boss spawned in a real scene plays its voice once with no position and ducks the bed (`Audio.duck_gain()`)
  - done when: `_task_0085_night_sounds` (rewritten) passes; `python tools/gen_sfx.py --report` for every new sound is in the journal

### 0287 - Collections and achievements

Waits on 0253, 0254, 0255.  Likely files: `src/core/collections.gd, src/core/stats.gd, src/core/farming.gd, src/core/phases.gd, src/core/run.gd, src/core/game_data.gd, src/app/save.gd, src/app/app.gd, src/app/input_actions.gd, project.godot, src/ui/collections_screen.gd, src/ui/title_screen.gd, src/ui/main.gd, scenes/Title.tscn, scenes/Main.tscn, assets/locale/strings.csv, src/tools/headless_check.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd, src/tools/shot.gd, implementation/backlog/packs/A056-collections.md`.

The plan's reason to start Year 2: four collections - fish, crops, the bosses' trophies and a year without losing the house - and a short list of achievements, kept in the profile across runs and shown on one screen.

- A node-free `src/core/collections.gd` in the shape of `Stats`: it reads facts other modules already count and keeps no second ledger - fish from 0182's book, trophies from 0246's `Combat.bosses_down_of` (`killed_by_kind_all_run`) for every `is_boss` kind, crops from a harvest tally - and folds them into the profile with the banking of `Stats.fold` (`stats.banked`), so folding twice adds nothing. Call it from inside `Stats.fold`, so every fold site (`main.gd`'s autosaves, `Run.record`) gets it without a second call
- Crops count harvests, not `gained`: everything `Resources.add` brings in (a purchase through `Shop.buy`, a gift, loot) lands in `gained` too. Add `stats.harvested_by_crop` to `Stats.initial()` (inside the `stats` TABLE, so reconcile fills old saves and no version bump is needed), counted in `Farming._harvest` the way `Stats.built` is counted in `Building.place`. SIM moves on purpose (the state gains keys): both numbers in the journal
- 'A year without losing the house' is a run that saw Winter 14's boss fall (0160's `Run.is_over`) with no night on which the house fell; a boss that walks off at dawn (0153's escaped outcome) is not a lost house. Nothing counts lost nights today: add `stats.nights_lost` beside the crop tally, counted in `Phases.enter_result` when the house fell (read how 0153 marks an escape in `last_result` and leave that out)
- About a dozen achievements, decided here, repeating none of the collections - e.g. first night survived, a Full Moon held (0152's `Calendar.is_full_moon`), a legendary landed, every defence in `DEFENCES` built once, a night with nothing destroyed, Year 2 reached - each a pure test of the lifetime stats, the collections and this run's record. A table in `game_data.gd` (thresholds `# LEVER`, a `check_achievements` in `GameData.validate()` that every id it names exists, listed in `GameData.digest()` so DATA moves on purpose) whose entries carry literal `&"ACH_*"` keys for a name and a one-line description: a key built at runtime is invisible to `tools/i18n_check.py`
- The profile: `Save.default_profile()` gains `collections` and `achievements`; `read_profile` already merges the defaults, so an older profile loads with no format bump. No toast for a newly earned badge in this task: the skeleton asks for the screen, and the task has to fit one invocation
- `src/ui/collections_screen.gd`, a sibling of `StatsScreen` (a node in `scenes/Title.tscn` and `scenes/Main.tscn`, as it is): tabs for fish (0182's book view embedded - reuse its pages, do not rebuild them; 0182's own way in keeps working), crops, bosses, the year and achievements, each with a count. Locked trophies and badges are the earned art dimmed by code, so A056 needs no locked state
- Ways in: the title menu (`ENTRIES` gains `collections`, `TITLE_COLLECTIONS`), a `COLLECTIONS` router state in `App.STATES` and `App.NAMES` (update the state count `_task_0092_router` asserts in `headless_check.gd`) and, in a run, a new `collections` action in `InputActions.ACTIONS` (`ACT_COLLECTIONS`, `ACT_GROUP_SCREENS`) with key and pad bindings in `project.godot` (0121's sync and clash checks), opened and closed the way the `stats` key opens `StatsScreen`. Strings in both languages, e.g. `TITLE_COLLECTIONS` (COLLECTIONS / COLEÇÕES), the tabs, every `ACH_*`
- Placeholders until 0288 integrates A056, through 0120's road: the existing crop and fish icons on the tabs, each boss's first frame as its trophy, code-drawn shapes for the badges, the cover and the ornament - never a hand-drawn PNG

  - done when: `_task_0287_collections` in `src/tools/headless_v1.gd`, on crafted states rather than a 56-night run (the 120 s limit): a harvested crop ticks its page and the same crop added through `Resources.add` does not; a boss killed adds its trophy; a run that lost a night never earns the year, one whose boss only escaped still can, and one that lost none and beat Winter 14 does; folding twice adds nothing; a profile without the new keys reads with defaults; `GameData.validate()` refuses an achievement naming an unknown id
  - done when: `_case_0287_collections` in `src/tools/input_v1.gd`: the title menu opens the screen, the tabs move by keyboard and by pad, cancel goes back to the title; in a run the `collections` key opens and closes it
  - done when: FHD captures of every tab with an empty and a full profile in English, and with the full profile in Portuguese (`src/tools/capture_menus.gd` or a new `shot.gd` scenario), opened and looked at, in `implementation/shots/0287/`
  - done when: The Deliverables table of `implementation/backlog/packs/A056-collections.md` states the final geometry this task settled: canvases, pivots and runtime names for the cover, the tab icons, a trophy per boss, one badge per achievement id and the ornament

### 0272 - Summer's fourteen nights

Waits on 0270, 0247, 0248, 0253, 0259, 0271.  Likely files: `src/core/game_data.gd (`KEY_NIGHTS`, summer's `SEASON_NIGHTS`), src/tools/headless_v1.gd`.

Summer opens the second side and brings the first enemies that change what a spring defence is worth: the spitter shoots towers from range, the rats come in numbers that mines and fire love, and on day 28 the Harvester charges straight through the walls.

- Days 16-28 fight; day 15 is 0154's calm night after the Giant. The east and the south-east are open (0157), and the first south-east night is a small one, so the new side is learned before it is tested
- Summer's first fight starts below spring's Full Moons and above spring's day 6, so the year still climbs; spring's four kinds stay in the mix at summer's share
- The spitter and the rat swarm are introduced on different nights - one in days 16-20, the other in days 22-27 - never together; the Full Moon on day 21 sends what is already known; the night after each introduction bites
- Day 28 is the Full Moon with the Harvester in company, so it cannot be focused alone: the Harvester is the row 0153's rule adds from `SEASON_BOSSES` (0253 put it there), and this task writes its company
- Read 0259's `implementation/MATCHUPS.md` first: every night's mix has an answer in what summer's arsenal (0234) has unlocked by that day - the flamethrower, the decoy, the beehive and the bait arrive this season - and the journal says which weapon each new enemy is meant to teach
- Rats are many bodies: print the peak entity count of the largest rat night and compare it with what the swarm scenario of 0218/0248 in `perf_check.gd` measured; the year's worst case is 0275's
- Author against `python tools/nights.py 15 28` and `python tools/play_nights.py 15 28` (0271's range), starting from spring's final numbers; notes in the authored voice; every night fits and fills the night (0137, 0271's `NIGHT_FILL_TICKS`); DATA moves on purpose, SIM only if a day the determinism scenario fights changed

  - done when: `_task_0272_summer_nights` in `src/tools/headless_v1.gd`: days 16-28 send only kinds introduced by that day, only from the east and the south-east; the spitter and the rats are first sent on their introduction days, on different nights; the Harvester is on day 28 and nowhere else; days 21 and 28 are the largest of their halves in hit points
  - done when: `python tools/nights.py 15 28` and `python tools/play_nights.py 15 28` output in the journal, with the matchup line for each new enemy and the peak rat count

### 0288 - Art: the collection book, trophies and badges

Waits on 0287.  Likely files: `assets/art_source/, assets/art_source/manifest.json, assets/art_source/ownership.json, tools/check_ui_art.py, src/tools/ui_art_showcase.gd, src/ui/placeholder_art.gd, src/ui/collections_screen.gd`.

The book cover, the four boss trophies and the achievement badges Codex drew replace 0287's stand-ins, so the screen a player opens before Year 2 looks like the rest of the game.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A056` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A056-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/<family>/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`tools/check_<family>_art.py`, `ArtPlacement` if needed).
- Family `ui`, no text in any of it: names, canvases and pivots exactly as A056's Deliverables table (settled by 0287) - the cover, the tab icons, a trophy per `is_boss` enemy, a badge per achievement id, the ornament. `tools/check_ui_art.py` hard-codes the 0018 resource icons (`len(plans)==15`): give the A056 set its own section and counts rather than loosening that one, and show it in `ui_art_showcase.gd`
- Delete A056's entries from 0120's placeholder registry (`src/ui/placeholder_art.gd`) once the raster outputs land at the same paths, so `collections_screen.gd` draws the real art through the lookup it already uses and `python tools/placeholders.py` no longer lists A056; locked trophies and badges stay the same art dimmed by code
- Set the pack to integrated: `python implementation/backlog/assets.py set A056 integrated`.

  - done when: `python tools/check_ui_art.py` and `python tools/show_art.py --ui --check` pass with the A056 set counted
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures of the collections screen, every tab with a full profile, opened in a run by day and by night, opened and looked at, in `implementation/shots/0288/`
  - done when: The sim and data hashes are unchanged (art never moves them)

### 0273 - Autumn's fourteen nights

Waits on 0270, 0249, 0250, 0254, 0259, 0272.  Likely files: `src/core/game_data.gd (`KEY_NIGHTS`, autumn's `SEASON_NIGHTS`), src/tools/headless_v1.gd`.

Autumn opens the north and brings the two enemies that ignore the shape of a maze: the crow flies over it to eat the crops, the digger goes under the fences and barricades. The Scarecrow King calls his flocks on day 42, and the Blood Moon can rise from now on.

- Days 30-42 fight; day 29 is 0154's calm night after the Harvester. The east, the south-east and the north are open (0157); the first north night is a small one
- The crow and the digger are introduced on different nights - one in days 30-34, the other in days 36-41 - never together; the Full Moon on day 35 sends what is already known; the night after each introduction bites
- Crows eat what is in the ground, and autumn's fields are full (wheat, pumpkin, grape, beet): crow nights are the ones where the farm's layout matters, so their first one is gentle
- Day 42 is the Full Moon with the Scarecrow King in company - 0153's row from `SEASON_BOSSES`, which 0254 set; this task writes the company. The crows he summons come from his rule, not from rows, so the forecast's count leaves them out by design (0254): day 42's note says he calls crows, and the journal gives the peak count of crows alive on day 42 in `play_nights`
- The Blood Moon (0257) may roll from autumn: list which autumn days roll it for seeds 0-4 in `tools/nights.py`, and pin `event` off on an introduction night it would drown (0270's field)
- Read 0259's `implementation/MATCHUPS.md`: every night has an answer in what autumn's arsenal (0234) has unlocked by that day - the mortar, the pumpkin catapult and the garlic braid - and the journal says which weapon each new enemy is meant to teach
- The template keeps climbing from summer's final numbers (`python tools/play_nights.py 29 42`); notes in the authored voice; every night fits and fills the night (0137, 0271's `NIGHT_FILL_TICKS`); DATA moves on purpose, SIM only if a day the determinism scenario fights changed

  - done when: `_task_0273_autumn_nights` in `src/tools/headless_v1.gd`: days 30-42 send only kinds introduced by that day, only from the east, south-east and north; the crow and the digger are first sent on their introduction days, on different nights; the Scarecrow King is on day 42 and nowhere else; days 35 and 42 are the largest of their halves in hit points
  - done when: `python tools/nights.py 29 42` and `python tools/play_nights.py 29 42` output in the journal, with the Blood Moon days for seeds 0-4 and the matchup line for each new enemy

### 0290 - The 1.0 visual gate

Waits on 0123, 0124, 0125, 0143, 0144, 0145, 0146, 0147, 0161, 0162, 0163, 0164, 0197, 0198, 0199, 0200, 0201, 0202, 0203, 0204, 0205, 0206, 0207, 0208, 0209, 0210, 0211, 0212, 0213, 0214, 0215, 0216, 0217, 0235, 0236, 0237, 0238, 0239, 0240, 0241, 0242, 0243, 0244, 0245, 0258, 0260, 0261, 0262, 0263, 0264, 0265, 0266, 0267, 0268, 0269, 0288.  Likely files: `src/tools/shot.gd, src/tools/capture_menus.gd, implementation/shots/0290/, implementation/backlog/CATALOGUE.md, implementation/backlog/packs/, tools/backlog/, implementation/prompts/, implementation/PROGRESS.md`.

Before 1.0 ships, look at the whole game in its real frame - every screen, season, family and state at 1920x1080, by day and by night - and prove nothing is still drawn on a stand-in. Like sprite task 0020: no claim of done from one nice farm shot.

- Capture at 1920x1080 by day and by night with `python tools/shot.py 0290 <scenarios> --fhd`, the showcases behind `python tools/show_art.py` and `src/tools/capture_menus.gd`; add the `shot.gd` scenarios that are missing (a night scenario uses 0130's camera hook)
- The world, at least: the four seasons' ground and trees, snow included; the farmer walking, running, every work verb and facing, in bed, passed out, fishing and reacting; the guardian and the cursor; every crop stage, tilled and trampled ground; the animals and their buildings, wrecked-but-standing included; machines, the bin, the peddler, the house tiers; every defence at every level with hurt, fire, wreck and its tarp; every enemy walking, attacking and dying; the four bosses and their telegraphs; effects; fog, rain, the Full and the Blood Moon
- Every screen: title, pause, options, the day HUD with clock and calendar, the forecast, the night HUD with hotbar and powers, the morning report, inventory, stall, workshop and machines, the tech tree by season, the fishing minigame, the fish book and collections, statistics, the year's end and the credits - in English and Portuguese where there are words
- Open every file. Judge scale against Stardew Valley at 1080p and the look against `docs/reference-sheet.png`: one art pixel is 4x4 physical pixels, the farmer about 128 px tall, and no new family drawn at the six legacy fixtures' 2x unless the journal says why
- 0120's placeholder check (`python tools/placeholders.py` and `_task_0120_placeholders` in `headless_v1.gd`) reports nothing on a stand-in, and `python implementation/backlog/assets.py list` shows every pack `integrated`, A057 excepted only if declined. 0289 is not a dependency because A057 is optional: if it is still todo, read the pack's status - declined (`blocked` with the owner's words) means run 0289's decline path here and close it; approved means block this gate until 0289 is done; anything else (todo, generating, review) means block it `waiting for asset A057 (Codex)` - a later decline then needs `python tools/task.py todo 0290` by hand
- Fix here what needs no new art and is small (placement, pivots, scale, sorting, the wrong state shown); a view fix bigger than that, and anything that needs new art (a correction pack in `implementation/backlog/packs/`), becomes a follow-up task in `tools/backlog/` with the next free id. Add each follow-up id to 0297's deps (in `tools/backlog/part13.py` and on the `Depends on:` line of its prompt, which `gen_backlog.py` does not overwrite) so 1.0 cannot ship ahead of it. This task never draws or generates art, and its fixes are view only: neither hash moves
- A 1.0 delivery catalogue, `implementation/backlog/CATALOGUE.md`, modelled on `implementation/sprites/DELIVERY.md`: per family the pack id, canvases, pivots, animation and state coverage, the capture that shows it, and its known limits

  - done when: Every capture in `implementation/shots/0290/` was opened; the journal lists what was looked at per family and per screen, what was wrong and what was done about it
  - done when: 0120's placeholder check prints zero packs pending (A057 excepted only when declined and 0289 closed), quoted in the journal
  - done when: The catalogue names a capture for every family and state in the lists above
  - done when: Every follow-up is filed as a task (and a pack when it needs art) with ids, each one in 0297's deps, none left as prose

### 0274 - Winter's fourteen nights

Waits on 0270, 0251, 0252, 0255, 0259, 0273.  Likely files: `src/core/game_data.gd (`KEY_NIGHTS`, winter's `SEASON_NIGHTS`), src/tools/headless_v1.gd`.

Winter is the exam: every side open, the frost zombie that slows the towers it dies beside, the wraith that cannot be shot outside the light, and the Winter Lord on day 56. Nothing grows, so these nights are fought with what autumn put away.

- Days 44-56 fight; day 43 is 0154's calm night after the Scarecrow King. Every side is open (0157), but the sides new to winter join over several nights through the side join days of winter's template (0270) and key nights - never on an introduction night
- The frost zombie and the wraith are introduced on different nights, never together; the Full Moon on day 49 sends what is already known; the night after each introduction bites
- The first wraith night is small and answerable with the light a farm has without a searchlight - the porch, the flare, burning cells (0229's light rule) - because it is the night that teaches the searchlight
- Day 56 is the Full Moon with the Winter Lord in company - 0153's row from `SEASON_BOSSES`, which 0255 set; this task writes the company - and the largest night of Year 1; 0160's ending hook fires when he falls
- Nothing grows outdoors in winter (the plan; the rule is 0171), so the money for these nights was made in autumn: prefer a climb in variety - sides, kinds, events - over a climb in bodies
- Read 0259's `implementation/MATCHUPS.md`: every night has an answer in what winter's arsenal (0234) has unlocked by that day (`python tools/play_nights.py 43 56`) - the searchlight and the electric fence - and the journal says which weapon each new enemy is meant to teach
- Notes in the authored voice; every night fits and fills the night (0137, 0271's `NIGHT_FILL_TICKS`); DATA moves on purpose, SIM only if a day the determinism scenario fights changed
- With all four seasons authored, `GameData.check_nights` refuses a night whose last wave is sent before 0271's fill line (`NIGHT_FILL_TICKS`), for every date `python tools/nights.py --check` resolves: 0148 found a night that is over in a minute leaves dawn nothing to do

  - done when: `_task_0274_winter_nights` in `src/tools/headless_v1.gd`: days 44-56 send only kinds introduced by that day; the frost zombie and the wraith are first sent on their introduction days, on different nights; the Winter Lord is on day 56 and nowhere else; day 56 is the largest night of days 1-56 in hit points; a copy of a night with its last wave moved before 0271's fill line is refused by `check_nights`
  - done when: `python tools/nights.py 43 56` and `python tools/play_nights.py 43 56` output in the journal, with the matchup line for each new enemy and the night each side first opens
  - done when: `python tools/nights.py` for the whole year, after all four seasons, is in the journal: the year's curve in one table

### 0275 - The worst night of the year, within budget

Waits on 0274, 0234, 0248, 0233.  Likely files: `src/tools/perf_check.gd, src/tools/perf_names.gd, tools/perf.py, tools/perf_baseline.txt, src/tools/headless_v1.gd`.

The benchmark's worst case is still Spring 14, where 0153 moved the MVP's night ten. Move it to the heaviest night 1.0 can produce - Winter 14 with the Winter Lord, a rat swarm and every defence on the farm - and settle the cost profile before 0277 simulates thousands of nights on it.

- `_the_worst_case()` in `src/tools/perf_check.gd` sets the run to Winter 14 (day 56) the way the calendar reads it (0151), not through `nights_won`, and still stops at the busiest moment
- At least one of every `GameData.DEFENCES` entry - the plan's fourteen and whatever 0231 added - at the top `TOWER_LEVELS` level, powered and with ammunition, placed where the fight is through the build-step road of 0119; 0218's swarm scenario is folded in or kept as its own rows - say which
- Every lazily built path field in 0218's registry is built tonight, adding the kinds that force one if day 56 lacks them, so `path_refresh` is timed with all of them; the heaviest event day 56 can roll is on - fog or rain, since 0257 keeps the Blood Moon off boss nights - by picking a seed `Weather` gives it, never an override in core
- `COUNT` lines for each defence family, each enemy kind, the boss and the fields built, so a reader can see the case is the case
- `PerfNames.NIGHT`/`DAY` already have to match `Sim.tick` (`_task_0102_budget`); every one of those names gets its branch in `perf_check._tick_one` (today an unmapped name only `push_error`s and still prints a row), and `_a_busy_day` becomes the 1.0 day: tilled grass, season crops, sprinklers, animals, every machine queued
- The budgets do not move: `TICK_BUDGET_US` 8333 and `PATH_BUDGET_US` 33333 in `tools/perf.py`. If the winter case breaks one, optimise here, hash-neutral, or block with the measured numbers - never raise a budget
- Print the wall time of one winter night simulated end to end as a `COUNT` (not budgeted), because 0277 multiplies it by thousands
- `python tools/perf.py --accept` moves the baseline; every row's old and new number goes in the journal, with why it grew. A benchmark and hash-neutral optimisations only: neither hash moves

  - done when: `python tools/perf.py` passes on the new baseline, with `night_tick` and `path_refresh` under their budgets on the winter case - both numbers, and the old ones, in the journal
  - done when: The `COUNT` lines show one of every `DEFENCES` entry, the Winter Lord, a rat swarm and every named path field built
  - done when: `_task_0275_perf_year` in `src/tools/headless_v1.gd` reads `perf_check.gd` and asserts every name in `PerfNames.NIGHT` and `DAY` has a branch in `_tick_one`, the way `_task_0102_budget` reads `sim.gd`

### 0276 - The autoplayer plays a whole year

Waits on 0194, 0233, 0234, 0275, 0221.  Likely files: `src/tools/autoplay.gd, src/tools/autoplay_run.gd, tools/autoplay.py, src/tools/play_nights.gd, src/tools/headless_check.gd, src/tools/headless_v1.gd`.

0142 taught the robot to sleep; this teaches it the rest of 1.0, so balance can be measured over a whole year: crops by days and season, the fishing minigame, animals and machines, the bin and the peddler, cursor building and repairs, the powers, and carrying on through losses and boss repeats.

- Each policy in `Autoplay.POLICIES` gains a day plan (its earners in order: season crops, fishing, animals, machines, mining, chopping), a night plan (what to place, upgrade and repair by cursor in the build step and during the waves, when each power fires) and a bedtime. `towers`, `walls`, `economy` and `balanced` keep their character; `balanced` is declared the average player 0277 balances against
- Everything goes through the intent road a player uses: tilling and watering through the verbs, fish landed through the minigame's press intents (0180), products collected, goods into the shipping bin, seeds and animals from the peddler in his hours, tool and house tiers bought (0173, 0191), night loot picked up (0221); `build_cell`, `build_place`, `build_upgrade` and `ability_cell` (0135) with 0232's power API at night. Nothing is granted by writing `state`
- Walking is counted from here on (path length at `PLAYER_SPEED`), or the journal measures why not: on an 80x65 farm with an 8-10 minute day (0166), 'walking is free' is no longer close to a player
- `Autoplay.play(seed, policy, days)` follows the calendar, not a night count: calm nights, Full Moons, winter with nothing growing (0171), boss nights repeated until the boss falls - with a cap so a tool run always ends, reported when hit - and losses that move the calendar on. Per night: held or lost, house left, essence and money; per season: losses and boss repeats
- `autoplay_run.gd` prints one machine-readable `RUN` line per run (policy, seed, losses per season, boss repeats, money and essence at each season's start) beside today's lines, so `tools/balance.py` keeps working until 0277 moves its parser onto `RUN` (moved there from here); `python tools/autoplay.py --year [runs]` prints the per-policy table and the dominant-strategy alarm per season
- `play_nights.gd` plays the whole year by default with its scripted floor, following the boss repeat rule
- A year is long: print the wall time per run; if 8 seeds of 4 policies are impractical in one process, split the runs across processes (the data does not change inside a run set) and say how long it took
- `_task_0067_autoplay` and `_task_0068_balance` in `src/tools/headless_check.gd` follow the new policy fields and stay one day and one night; nothing in the suites plays a season. Tools only: neither hash moves

  - done when: `_task_0276_year_autoplay` in `src/tools/headless_v1.gd`, its time measured, printed and under 15 s (over it, the slice's day plan shrinks - bed as soon as it is done - and the cap does not move): from a prepared mid-summer state the `balanced` policy plays one day and one night twice on one seed with the same result; that day landed a fish through the minigame, shipped goods through the bin and collected an animal product; that night placed a defence by cursor in the build step and fired a power
  - done when: `python tools/autoplay.py --year 8` completes for all four policies; its table and wall time are in the journal
  - done when: `python tools/balance.py` with a short sweep still finishes on today's lines and leaves the git tree clean (its move onto `RUN` is 0277's)

### 0277 - Balancing the year

Waits on 0271, 0272, 0273, 0274, 0276, 0259.  Likely files: `tools/balance.py, tools/autoplay.py, src/core/game_data.gd, implementation/BALANCE.md, implementation/PROGRESS.md, src/tools/headless_v1.gd`.

The phase's own target: an average player reaches winter having lost two to four nights, and every boss falls. Measured with the year autoplayer, moved with levers, written down - the way 0068 did it for ten nights.

- The target as numbers: the `balanced` policy loses 2-4 nights before Winter 1 (day 43), averaged over at least 8 seeds, and every boss falls for it on every seed. A boss that walks off at dawn is a repeat, not a loss (0153), and is counted apart
- `tools/balance.py` moves onto 0276's `RUN` lines (its parser, moved here from 0276) and sweeps the year: `NIGHTS = 10` and the win-rate-per-night arithmetic become survival per day and losses per season; `LEVERS` is re-chosen for 1.0 (season sizes, the Full Moon percent, boss hit points, house tiers, the night length, essence and night money), each regex matching exactly one line
- Size the sweep before running it: a year run takes minutes (0276 printed it, 0275 the winter night), so levers x values x 8 seeds x 4 policies is days of wall time. Sweep with the `balanced` policy on 4 seeds, run seeds as parallel processes, and keep the full `--year 8` for all four policies for the before and after tables; each sweep's wall time goes in BALANCE.md
- It keeps its safety: it refuses a dirty `game_data.gd`, holds the lock file and restores the file in a `finally`
- Start with the instrument, as 0068 found: before moving a lever, ask a losing run what it was doing; a fault in the autoplayer is fixed there and named in BALANCE.md, not tuned around
- No policy wins every night of the year by a wide margin (the dominant alarm, per season); no day sits at 0% survival across every policy; a lever that moves nothing across its range is reported as dead weight
- Re-run 0259's matchup tool after the levers move: every weapon is still the best buy somewhere and every enemy still needs a different answer
- Levers move in `src/core/game_data.gd` with their `# LEVER` ranges kept true and `GameData.validate()` passing. DATA moves on purpose; SIM moves too where the determinism scenario reads a moved lever - old and new numbers of both in PROGRESS.md
- A new top section of `implementation/BALANCE.md`, 'The year': losses by season and policy, boss repeats, the sweep tables, every applied change with its old and new value, and what is still off

  - done when: `python tools/autoplay.py --year 8` after the changes: `balanced` loses between 2 and 4 nights before day 43 on average and every boss falls on every seed - the table is in BALANCE.md
  - done when: The sweep's own output in BALANCE.md shows no day at 0% survival across every policy and the dominant alarm silent in every season
  - done when: The season groups of 0271-0274 still pass with the moved levers, or the journal says which asserted relation the data proved wrong and how it was rewritten
  - done when: `python tools/balance.py` reads only `RUN` lines, and a short sweep leaves `game_data.gd` restored, the git tree clean and no `.balance-lock` behind

### 0278 - The economy across a year

Waits on 0277.  Likely files: `src/core/game_data.gd, src/core/shop.gd, src/tools/autoplay.gd, src/tools/autoplay_run.gd, tools/autoplay.py, implementation/BALANCE.md, src/tools/headless_v1.gd`.

The plan's rule of thumb, checked in every season and not only the first: a good day buys about one new defence, a boss costs five to seven focused days, and winter - when nothing grows - lives off what autumn put away.

- Measure first, with the year autoplayer: per season, what a focused day earns by earner (crops, fish, animals, machines, mining), the price of each of that season's new defences (0234's money and materials, at stall prices), and what was standing on the night each boss fell - `python tools/autoplay.py --economy` or an equivalent report
- Rule of thumb: one well-worked day at the start of each season buys about one of that season's new defences - the ratio per season in BALANCE.md, each within 0.7-1.5 or the journal says why
- A boss costs 5-7 focused days: the value of the build that beat it, less what stood at the season's start, divided by that season's focused-day income
- Winter: nothing grows (0171), so the `balanced` policy enters day 43 with autumn's stock, and its winter income (fish, mining, machines, animals) plus that stock pays for winter's defences and repairs to day 56 without running out of food or ammunition - reported per run
- Costs before prices: prefer moving defence costs, machine times and yields, starting from 0234's day-to-defence table in BALANCE.md; if prices must differ by season, one `# LEVER` table (a percent per resource group per season) read through `Shop.sell_price` (it takes only an id today: it gains the season, and every caller follows) and so by the bin, listed in `digest()`
- `GameData.check_stall` and `check_chain` already take the prices as an argument: `validate()` runs them at every season's prices, so markups stay above prices and every recipe still adds value in every season
- DATA moves on purpose, SIM too if the determinism scenario's shop visit reads a moved price - both in PROGRESS.md; re-check 0277's target after the changes

  - done when: BALANCE.md 'The economy across a year': per season the focused-day income by earner, the day-to-defence ratio, the days each boss cost, and winter's stock from day 43 to day 56, all measured
  - done when: `_task_0278_season_economy` in `src/tools/headless_v1.gd`: the stall and chain checks pass at every season's prices, and a doctored price that breaks the chain in one season only is refused
  - done when: 0277's target still holds: the `--year 8` table after the changes is in the journal

### 0279 - Year 2

Waits on 0277.  Likely files: `src/core/game_data.gd, src/core/almanac.gd, src/core/endless.gd, src/core/waves.gd, src/core/run.gd, src/ui/result_screen.gd, assets/locale/strings.csv, src/tools/nights.gd, tools/nights.py, src/tools/perf_check.gd, tools/perf.py, src/tools/shot.gd, src/tools/headless_check.gd, src/tools/headless_v1.gd`.

After the Winter Lord the farm carries on, and today that means the MVP's endless curve. Replace it with the calendar: Year 2 and every year after replay the four seasons from 0270's templates, heavier each year, with the bosses back on every day 14.

- Days past 56 resolve through 0270's generator (wherever it lives): the year and the season from 0149's `Calendar` helpers, the season's template scaled by a per-year growth `# LEVER` that is added, not compounded (the `ENDLESS.growth_percent` lesson), with the mix allowed to lean heavier each year. The plan wants Year 2 heavier 'a cada estação': the journal compares Year 2's spring with Year 1's winter, and a drop between them stands only with its reason written down
- Every season's day 14 sends its boss again (0153's row), with hit points scaled per year by a `# LEVER` through the `max_hp` road 0257's elites use, read by `Combat.full_hp` (0246); the boss-repeat rule (0153) and the calm night after a fallen boss (0154) hold every year, so Spring 1 of Year 2 is calm
- Later years have no introductions; the Full Moons on 7 and 14 stay - Year 1's records scaled, or generated with the Full Moon percent: decide one and assert it
- Sides and events keep to their season as in Year 1, so each season keeps its character; the Blood Moon comes earlier only if a lever says so
- Retire the MVP curve: `Endless` and the `ENDLESS` table, `giant_every` levers included (0153 left them to this task), leave `plain_night`, `check_nights` and `digest()` (a reader of `Endless._stream_for`, such as 0256's `Weather`, keeps the helper in its new home); `_task_0070_endless` in `src/tools/headless_check.gd` is rewritten over the later years or removed with the reason in the journal; 0160's carry-on lands in Year 2 of the calendar, and `Run`'s `endless` flag means 'past Year 1' or goes. A saved key that changes meaning gets a `State.VERSION` bump, a migration and a golden (never a key named `moon_phase`); otherwise no bump. `validate()` checks the new levers' ranges
- 0160's ending screen shows once, after Year 1; a later Winter Lord ends his year with a line in the morning report (`result_screen.gd`): a new `RES_YEAR_SURVIVED` row (key,width,en,pt_BR: YEAR %d SURVIVED / ANO %d SOBREVIVIDO, width measured). The HUD's year is already 0149's: `SPRING 3` beside the clock and `YEAR 2` on the line under it until dusk (`DHUD_YEAR`); add a `year_two` scenario (a Year 2 day) to `src/tools/shot.gd` to see it
- `python tools/nights.py --years 3` prints Years 1-3 by season with sizes, bosses and events; generation stays a fresh `(seed, day)` stream
- The curve stays sane to Year 3: `perf_check.gd` takes a date (e.g. `--date=<n>`, forwarded by `tools/perf.py`, which compares and accepts nothing on such a run) and times 0275's case on Year 3's heaviest night; the `balanced` policy plays into Year 2 on one seed with `Autoplay.play(seed, policy, days)`
- Hashes: DATA moves (the new levers; `ENDLESS` leaves the digest). SIM should not - the determinism night is day 1 - unless a state key goes (e.g. `endless`), which moves it on purpose; both numbers in `implementation/PROGRESS.md`

  - done when: `_task_0279_year_two` in `src/tools/headless_v1.gd`: day 57 is Spring 1 of Year 2 and calm; a Giant spawned on day 70 has more `Combat.full_hp` than one spawned on day 14; on every day of the year but Spring 1 (Year 1's is the tutorial night), Year 2 sends at least Year 1's hit points on the same day and Year 3 at least Year 2's; days 57-168 resolve for seeds 0-2 without touching `state["rng"]`
  - done when: Year 3's heaviest night is inside `TICK_BUDGET_US` and `PATH_BUDGET_US` (`python tools/perf.py --date=<it>`) - the numbers in the journal
  - done when: The `python tools/nights.py --years 3` summary and where the `balanced` policy fell in Year 2 are in the journal
  - done when: `python tools/shot.py 0279 year_two --fhd` opened: the year label fits, in English and in Portuguese

### 0280 - Checkpoint: do fifty-six nights tire?

Waits on 0277, 0278, 0279, 0258.  Likely files: `implementation/PROGRESS.md, implementation/shots/0280/, src/tools/shot.gd, src/tools/nights.gd, implementation/prompts/ (later prompts, if the answer needs it), tools/backlog/ (new tasks, if any)`.

The plan's Phase 6 question, answered honestly: 'as 56 noites cansam?' A checkpoint like 0027, 0066 and 0148, not a feature - a 'yes' found here is worth more than every polish task after it.

- Play, not only measure: the year autoplayer for all four policies, `python tools/nights.py` for the year, and at least one night of each season and each boss night driven through the real game with the cursor, by mouse and by pad (a real pad if one is attached; say honestly if it was synthetic), and looked at
- Captures at 1920x1080 (`python tools/shot.py 0280 <scenarios> --fhd`): each season by day and at night mid-wave, a Full Moon, a fog or rain night, a Blood Moon, and the four bosses mid-fight. Reuse what exists - 0159's `season_*`, 0258's `fog`, `rain`, `blood_moon` and `full_moon`, 0246's `boss` and the boss scenarios of 0253-0255 - and add to `src/tools/shot.gd` only what is missing (a tool change, hashes untouched)
- Look for sameness with numbers, computed by a tool rather than by eye (a `--sameness` report in `src/tools/nights.gd`): per season, how many nights share a mix of kinds and sides; the longest run of nights that bring nothing new (no new enemy, side, weapon, event or boss); how often the forecast says the same thing two nights running
- Answer in the journal: do the fifty-six nights tire, where and why, with the stretches named by day - then what would fix it (more events, fewer generated nights, new key nights, shorter seasons) and what each fix costs
- Fixes that fit go into the later prompts (P16-P17), or into new tasks in `tools/backlog/part*.py` run through `python tools/gen_backlog.py` - each with a free id and added to 0295's deps, so the playtest waits for it; anything that changes an owner decision (14 days a season, Normal only) is a recommendation to the owner in the journal, not an edit made here
- If the honest answer is that the year tires and the cure is bigger than prompt edits, mark this task blocked with the reason (`python tools/task.py blocked 0280 "<why>"`), so 0295 (the playtest of the year) waits for the owner
- No rule changes here: nothing in `src/core/` moves, and neither hash moves

  - done when: `implementation/shots/0280/` holds the FHD captures listed above, every one opened and looked at; the journal names what is wrong in any of them
  - done when: The journal has the year's autoplayer table, the sameness numbers and the longest stretch with nothing new, by day
  - done when: The journal answers 'do the fifty-six nights tire?' in plain words and lists every prompt edited and every task added because of it

### 0291 - Saves into 1.0

Waits on 0279, 0287.  Likely files: `src/app/save.gd, src/tools/make_goldens.gd, src/tools/play_goldens.gd (new), tools/verify.py, tools/goldens/, src/ui/title_screen.gd, src/tools/shot.gd, src/tools/headless_v1.gd, src/tools/headless_check.gd, assets/locale/strings.csv`.

Somebody who played the 0.1 prototype opens 1.0 and finds their farm in the calendar, or is told plainly where it went - never a crash and never an empty title. This is the last look at every save shape before a stranger's save depends on it.

- An inventory first, in the journal: every `State.VERSION` from 1 to now, the task that bumped it, its step in `Save.migrations()` and its golden in `tools/goldens/`. A version with no step is fixed here. Only the 0.1 shape (State 4) was ever in a player's hands, so the versions in between need their step, not a golden each
- The real 0.1 golden is 0151's `run-v4.sav` (made from the MVP commit `bea89a88`: State 4, BuildInfo 0.1.0). If it is missing, make it the same way: check that commit out in a `git worktree` outside the repository, `--import` it, run `make_goldens.gd` there with `GODOT` set, copy back only the v4 goldens and remove the worktree. A golden that exists is never regenerated
- Two declared shapes beside it, made by `make_goldens.gd` from `run-v4.sav`'s raw payload (no migration, no reconcile - read underneath `Save.read_run_at` the way `headless_check`'s `_payload_of` does), each consistent with itself the way the MVP moved its counters (`day`, `night`, `nights_won`, `nights_paid`, the bosses down), and declared as shapes in the script's header like `run-v1-newer.sav`: `run-v4-endless.sav`, a run carried on past night 10 (`endless` true, `nights_won` 11, in DAY), and `run-v4-finished.sav`, a won MVP run (`nights_won` 10, `endless` false, in RESULT with `last_result.run_over` true)
- A written rule, per shape, migrate or archive, decided by one pure function in `Save` (e.g. `Save.verdict(state)`, asked of the migrated state): a run inside nights 1-10 migrates to its calendar day through 0151's step; the endless and finished shapes migrate only if they land on a day whose night resolves and whose boss bookkeeping (0153's hold at day 14) is consistent, and are archived otherwise. The rule and why go in the journal and in `Save`'s doc comment
- Archiving never deletes, and only the player's run moves: `Save.read_run()` (`RUN_PATH`) moves an archived run to `user://archive/run-v<N>-<k>.sav` (never over a file already there) and reports a new `Save.ARCHIVED` trouble; `read_run_at` gives the same verdict and moves nothing, so a golden in `res://` is never touched. CONTINUE is absent and the title says so once, the `SAVE_ARCHIVED` line on its own rather than under `SAVE_UNREADABLE`/`SAVE_KEPT` (nothing was unreadable), a row with a real width - e.g. 'Your 0.1 run is kept in the archive folder. 1.0 starts a new year.' / 'Sua partida da 0.1 ficou guardada no arquivo. A 1.0 começa um ano novo.'
- The profile is kept: a 0.1 profile (`runs_started`, `runs_won`, `best_night`, `stats`) loads through `Save.read_profile` with its numbers, and every 1.0 key (the fish book of 0182, the collections and achievements of 0287) at its default. 0160 left `best_night` to this task: decide and record whether it still means 'most nights won in one run'. A key whose meaning moved gets a named step in a profile version of its own (e.g. `Save.PROFILE_VERSION` and a `profile_migrations()` table run through `Save.step_up` in `read_profile`; `FORMAT_VERSION` is the file header's, not the profile's), never a silent reread. A `profile-v1.sav` shape goes in `tools/goldens/` (add `Save.read_profile_at`/`write_profile_at` if the pair is missing). The 0.1 `settings.cfg` is 0293's, beside its `Settings.VERSION` bump
- Fix `_task_0104_saves` in `headless_check.gd`: `_goldens()` lists only `run-v*.sav` (the profile golden and any settings fixture are not runs); a shape the rule archives is asserted refused with `Save.ARCHIVED`, not 'loads'; and 'a farm somebody built on' compares against the occupant count of `State.create(seed)` in this build, not the MVP's 106 - since 0156 a fresh farm can pass that number on its own
- A day and a night for every golden is a tool, not the suite (a dozen goldens times a night to dawn is minutes of ticks): `src/tools/play_goldens.gd` loads every run golden the rule migrates, plays 600 day ticks, goes to bed and through 0118's road (START, the night runner to dawn, `confirm_result`), and checks it wakes on the next calendar date in DAY with no enemy left on the farm; `tools/verify.py` runs it as a `goldens` row through `check_script`. The suite keeps load + 600 ticks per golden
- Saves never touch the determinism scenario: SIM and DATA stay where they are

  - done when: `_task_0291_saves` in `src/tools/headless_v1.gd`: each 0.1 shape (`run-v4.sav`, `-endless`, `-finished`) gets the rule's verdict; a migrated one lands on the date the rule says and plays 600 ticks; an archived one, copied to `Save.RUN_PATH` and read through `Save.read_run()`, ends byte for byte under `user://archive/`, `Save.can_continue()` is false and the title's `trouble_says()` holds the `SAVE_ARCHIVED` line (the group removes the files it made)
  - done when: the same group: the 0.1 profile golden loads through `Save.read_profile_at` with its numbers (and `best_night` as the journal decided) and every 1.0 key at its default
  - done when: verify prints the `goldens` row passing: every migrated golden woke on its next date in DAY with no enemy on the farm - the dates and the row's time in the journal
  - done when: the title with the archive line captured at 1920x1080 in both languages (`python tools/shot.py 0291 --title --fhd` and `--title --fhd --pt_BR`, staging an archived run in `shot.gd` the way the crash dialogue is staged, and putting back any real `user://run.sav` afterwards) and opened: the line fits and sits clear of the menu

### 0294 - Every new word in Portuguese

Waits on 0287, 0293, 0291, 0292.  Likely files: `assets/locale/strings.csv, tools/i18n_check.py, src/ui/names.gd, src/tools/headless_v1.gd`.

Portuguese is the owner's language and most of the audience's. Every line 1.0 added gets read again as a whole: one name for each thing, sentences that agree in gender and number, and nothing running off its button.

- Read every row added since 0112 (`git log -p -- assets/locale/strings.csv` from 0112's commit on) in both languages, then on screen. The journal lists every pt_BR change with the before and the after
- One name per thing, and the plan's: its names become a glossary in `tools/i18n_check.py` (key to expected pt_BR, compared without case) that fails a row which drifts - the seasons, Lua Cheia, Lua de Sangue, neblina, chuva, essência, caixa de envio, mascate, banca, guardião, COMEÇAR, the crops of §3.1, the fish of §3.2, the machines of §3.5, the defences of §5, the enemies and bosses of §6, ossos, farinha de osso, pedras da lua
- Three MVP names disagree with the plan today: `DEF_FLAME_TOWER` 'torre de fogo' (plan: lança-chamas), `ENEMY_BREAKER` 'quebrador' (destruidor) and `ENEMY_TANK` 'brutamontes' (tanque). The plan wins unless the journal records the owner choosing otherwise; the plurals and every sentence that uses them move with them
- Counted names have plurals: every enemy, fish, crop and item a line counts (the forecast's '34 andarilhos', the morning report, the fish book) has its `.other` row in both languages - the bare key is the singular, and a `.one` row exists only where the counted singular differs from the name, as `I18n.plural` documents
- Agreement: a pt_BR line that puts a name into a sentence agrees with it ('a Colheitadeira caiu', 'o Gigante caiu'). Where one template cannot agree with every name, rewrite it so the name stands alone ('Caiu: %s') rather than adding gender data to the rules
- Widths: every row added since 0112 that is drawn in a fixed control (HUD label, button, hotbar tooltip, option row) and still has `width` 0 - which means unchecked - is measured and given its real width. `python tools/i18n_check.py --report` names the widest lines, and the widest pt_BR ones are looked at on screen. `i18n_check` already refuses a glyph the font lacks; look at the accented ones in use (ã, õ, ç, ê, á, and capitals on buttons such as COMEÇAR) at 1920x1080 too
- `Names.KEYS` covers every id 1.0 added and `Names.NOTES` every tech node (already asserted); `ITEM_TECH` reads essence / essência (0219's rename, the id stays `tech`) and the glossary holds it there. Text only: neither hash moves

  - done when: `python tools/i18n_check.py` passes with the glossary enforced, and fails when one glossary row is changed by hand (tried once, reverted, said in the journal)
  - done when: `_task_0294_names` in `src/tools/headless_v1.gd`: every id in `CROPS`, `RESOURCES`, `DEFENCES`, `ENEMIES`, `BUILDINGS`, `RECIPES`, `TECH_TREE` and the fish species of 0179 has a `Names.KEYS` key whose row is non-empty in `en` and in `pt_BR` read straight from the table (no English fallback, no key printed as itself), and its pt_BR text differs from its English one unless the glossary marks the word as the same in both
  - done when: pt_BR captures at 1920x1080 of both HUDs, the forecast, the hotbar, the morning report, the fish book, the collections and every options page (`python tools/shot.py 0294 --fhd --pt_BR` and `capture_menus.gd -- --out=res://implementation/shots/0294/ --pt_BR`), opened one by one: no clipped, overlapping or English word

### 0295 - A playtest build of the year

Waits on 0280, 0291, 0292, 0293, 0294.  Likely files: `src/app/playtest.gd, src/ui/main.gd, tools/playtest.py, docs/PLAYTEST.md, src/tools/headless_v1.gd, src/tools/headless_check.gd`.

Put the year in front of somebody and learn from it: a build that says it is a playtest, a log of what 1.0 is about - bedtimes, the build step, dawn, seasons, lost nights - and a reader that answers 1.0's questions instead of the MVP's. It goes out with the art that has arrived, placeholders and all.

- The log learns the calendar: `Playtest.watch` writes the season and day when a day begins ('Spring 3 began'), the hour he went to bed or that he passed out at 02:00, how long the build step ran before START, how the night ended (dawn, all killed, the house fell) and when a boss night repeats - all in the `  m:ss  what` shape the reader parses
- A lost night no longer ends the session: today `watch` calls `run_ended` on `night_lost` ('the house fell on night N'), which in 1.0 is a setback inside a run. A session ends at the end of the year (0160's ending), at Abandon (`main.gd`) or when the window closes. `run_ended`'s 'reached night' reads the calendar date - 0151 named `playtest.gd` among the `nights_won + 1` readers; finish it here if it did not
- `tools/playtest.py` asks 1.0's questions: did they reach the first night; how long was Spring 1 in real minutes (the plan wants 8-10 for the day and 3-5 for the night); bed or pass-out, night by night; how long the build step ran; how far into the year they got and how many nights they lost per season (the plan's target is 2-4 lost before winter); where the notes cluster. `--self-check` gets a 1.0 sample log and fails when any answer comes back empty
- `docs/PLAYTEST.md` rewritten for 1.0 (it still says ten nights and a night you send for; 0117 only corrected what happens after night ten): what the game is now; the most useful stretch to play (Spring 1 to the Giant on day 14); what to try (bed early and late, the cursor by mouse and by pad, START, the bin, the rod); what to ignore, including the placeholders still on screen as `python tools/placeholders.py` (0120) lists them; the same F1 and local-log promises
- `_task_0105_playtest` in `headless_check.gd` stays true: if a line it reads has moved, rewrite it in the same change
- The build: `python tools/release.py --playtest` writes `build/playtest/` with `READ ME FIRST.md` beside it, and the badge says playtest. It builds only the Windows playtest preset, so no web budget is weighed here - `PACK_BUDGET` and `WIRE_BUDGET` are 0297's
- Nothing is sent: the build is made and checked and the journal says where it is. Handing it to a tester is the owner's call. Playtest code is `src/app/` and only reads the state: neither hash moves
- Questions the loop cannot answer - whether a stranger reads the week's lines (0293), whether a night is long enough - go into PLAYTEST.md's 'what to report', not into a guess in the journal

  - done when: `_task_0295_playtest_log` in `src/tools/headless_v1.gd`: a short scripted run through bed, START, dawn, a lost night and the next morning writes, in order, the lines the reader parses, and the session is still open after the lost night - the lost night parked through 0118's road with the house set to fall, so the group takes seconds, not two whole nights
  - done when: `python tools/playtest.py --self-check` passes with the 1.0 sample, and `python tools/playtest.py <folder>` on the log that group wrote answers every question
  - done when: `python tools/release.py --playtest` succeeds, including its 400-frame boot of the playtest build; `python tools/shot.py 0295 --title --playtest --fhd` shows the badge on the first screen - opened
  - done when: no 'ten nights' or 'night ten' is left in `docs/PLAYTEST.md`, in any case

### 0296 - The store page and trailer for 1.0

Waits on 0290, 0294.  Likely files: `docs/STORE.md, tools/gen_marketing.py, src/tools/shot.gd, tools/devlog.py, docs/devlog/the-trailer.gif, implementation/shots/trailer/, src/tools/headless_v1.gd, src/tools/headless_check.gd`.

The store page still sells the prototype: ten nights, about an hour, sixteen crops and a night you send for. Make it describe the year - seasons, going to bed, the guardian on the porch, dawn - in pictures from the real game and words the data can check.

- `docs/STORE.md` rewritten in both languages: a year of four fourteen-day seasons, the night that starts when he goes to bed (or passes out at 02:00), the guardian's cursor, dawn at 06:00, four bosses, what the days pay for; 'What is in it' with real counts; 'What is not' honest (nothing online, one farm, no stamina, no greenhouse, one difficulty); a length worked out from the day and night levers times 56, not hoped for. The pitch stays `design.md` §20 verbatim, which `gen_marketing.py --check` and `_task_0107_store` enforce
- Words the data can check: each count is a digit before a fixed noun in both sections ('12 crops' / '12 culturas'), and `_task_0296_store_copy` in `src/tools/headless_v1.gd` reads `docs/STORE.md` (the way `_task_0106_release` reads `CHANGELOG.md`) and fails when a count it states - crops, defences, enemies, bosses (`is_boss`), days in a season - disagrees with `GameData`
- Screenshots at 1920x1080 through `gen_marketing.py`'s `SCREENSHOTS`, its `capture()` passing `--fhd`: a spring day, the same farm in winter, going to bed, the guardian's build step with cursor and route, a wave holding, dawn with the survivors walking off, and the tech tree or the collections. Reuse the scenarios earlier tasks added (`python tools/shot.py --list`), add only the missing ones. Capsules keep `capsule()`'s rule - a whole-number `NEAREST` scale or a crop, never a smoothed resample - with `HUD_ROWS` scaled to the capture; if the header capsule comes out a close-up, pick a wider source shot and say so
- Rewrite `_task_0107_store` in `headless_check.gd` in place: the five picture names it looks for in `gen_marketing.py` become the new list; its pitch, `NEAREST`, `SWITCH_FRAMES` and no-`HTTPRequest` asserts stay
- The switch GIF and its stills come from `shot.gd --switch`, which 0129 opened with the bed beat: check it is 1.0's switch - he lies down and the farm goes dark - and fix the strip if it still sends for the night
- The trailer's four beats in `shot.gd` (`BEAT_DAY`, `BEAT_SWITCH`, `BEAT_NIGHT`, `BEAT_FALL` - names kept, `_task_0108_devlog` reads them) tell the 1.0 story: a day's work, going to bed, the guardian placing a defence and pressing START, a wave held until dawn. They still sum to `TRAILER_SECONDS * TRAILER_FPS`, and `devlog.py`'s `clip_caption` (EN and PT) says the new story
- The trailer goes through the devlog tool, and never bare (the bare command deletes the tracked frames before capturing): capture with `python tools/shot.py trailer --trailer`, look at the frames, assemble with `python tools/devlog.py --keep`. If a capture fails, `git checkout HEAD -- implementation/shots/trailer` puts the frames back. `python tools/devlog.py --check` (verify's devlog row) passes at the end. The devlog's 'what is not in it' list is 0297's, beside the Known issues it sits with
- `python tools/gen_marketing.py` makes the set in `build/store/`; nothing is uploaded. Captures and copy only: neither hash moves

  - done when: `python tools/gen_marketing.py` builds the set and `--check` passes; every screenshot and capsule is opened at full size and named in the journal
  - done when: `_task_0296_store_copy` passes, and fails when one count in the copy is changed (tried once, reverted, said in the journal); the rewritten `_task_0107_store` passes
  - done when: `docs/devlog/the-trailer.gif` is remade (its size in the journal) and watched start to finish: the bed, the cursor, START and dawn are all in it
  - done when: `python tools/devlog.py --check` passes and `git status` shows the trailer frames replaced, not missing

### 0297 - Releasing 1.0

Waits on 0290, 0291, 0292, 0293, 0294, 0295, 0296.  Likely files: `src/core/build_info.gd, CHANGELOG.md, implementation/RELEASE.md, export_presets.cfg, tools/release.py, tools/devlog.py, docs/devlog/, tools/goldens/, src/tools/headless_v1.gd`.

Run the checklist 0106 wrote, for 1.0: one version everywhere, a changelog a player would recognise, both builds made and proven, the known issues told honestly - and then stop, because publishing is the owner's.

- Every task below 0297 is done (`python tools/task.py stats`). One that is not - an optional art leaf such as 0289 the owner declined, or a blocked task - is closed by the owner's word or listed under Known issues with why. No release over a todo nobody explained
- One version: `BuildInfo.VERSION` becomes `1.0.0` and `STAGE` stops saying prototype; `CHANGELOG.md` gets a 1.0.0 section on top (`_task_0106_release` requires one); both Windows presets in `export_presets.cfg` (Windows Desktop and Windows Playtest) get `application/file_version` and `application/product_version` (four numbers, `1.0.0.0`). `_task_0297_release` in `src/tools/headless_v1.gd` fails when any of them disagrees with `BuildInfo.VERSION`
- The changelog in sentences a player would recognise: a year of seasons, going to bed, the guardian, dawn, the new crops, fishing, animals, machines, defences, enemies and bosses, collections, the new options - and what happens to a 0.1 save (0291's rule)
- The save the next version must read: if `tools/goldens/run-v<State.VERSION>.sav` is missing, `make_goldens.gd` writes it from this build, and nobody regenerates it after
- `implementation/RELEASE.md` brought to 1.0 and run top to bottom: the tag says `v1.0.0`; step 3 names 0291's 0.1 goldens; Known issues rewritten from the journal (0280's answer, 0295's playtest, anything still on a placeholder, 0290's follow-ups, the perf and wire numbers); Rollback says a 0.1 run is migrated or archived, never eaten. Keep the commands and headings `_task_0106_release` looks for
- The devlog describes 1.0 (moved here from 0296): `devlog.py`'s 'What is not in it' stops reading `design.md` §15 and lists what is not in 1.0 from the plan (the greenhouse of §3.1, stamina in §3.9, the Nightmare mode of §11, the one-farm pillar of §3.3 and §12) on both pages, keeping the heading `_task_0108_devlog` reads; its 'still wrong' list is the Known issues above. `docs/devlog/preamble.md` is the owner's opinion and is left alone - the journal asks for a 1.0 paragraph
- `python tools/release.py` - verify, stamp, both exports, the pack check, the budgets, the 400-frame boot - passes. If `PACK_BUDGET` or `WIRE_BUDGET` fails, find what grew from the pack listing and move it once, deliberately, with the old and new number and the biggest files in the journal - the way a hash moves. Version, words and builds only: neither hash moves
- Step 6's smoke test by hand is the owner's wherever the loop cannot do it (the Web build in a browser, a pad in the hand): the journal says what the tools checked and what is left for a person, and never claims a hand test that did not happen
- Nothing leaves the machine: no `git push`, no `git push --tags`, no upload. Commit the release (the runner loop's step 6) and only then, `release.py` having passed, make the annotated tag `v1.0.0` on that commit, so it holds the stamped `BuildInfo.BUILT`; the journal ends with the push and upload commands for the owner

  - done when: `python tools/release.py` passes and prints both builds against their budgets; the numbers are in the journal
  - done when: the title screen shows the 1.0.0 `BuildInfo.short()` - captured with `python tools/shot.py 0297 --title --fhd` and opened
  - done when: `_task_0297_release` fails on a preset whose version disagrees (tried once, reverted) and passes on the real ones; `python tools/devlog.py --check` passes with the 1.0 list
  - done when: `git tag -l v1.0.0` lists the local annotated tag on the commit holding this task's changes, `git status` shows nothing of this task uncommitted, and nothing was pushed

## 0 - Foundation  (12/12)

- [x] **0001** [Godot project scaffold](prompts/0001-project-scaffold.md)
- [x] **0002** [Fixed-timestep deterministic simulation](prompts/0002-sim-tick.md)
- [x] **0003** [game_data.gd, the one file of levers](prompts/0003-game-data.md)
- [x] **0004** [Harden the headless check harness](prompts/0004-headless-check.md)
- [x] **0005** [verify.py and the determinism guard](prompts/0005-verify-and-hash.md)
- [x] **0006** [The phase machine: day, preparation, night, result](prompts/0006-phase-machine.md)
- [x] **0007** [The resource ledger](prompts/0007-resource-ledger.md)
- [x] **0008** [The farm grid](prompts/0008-farm-grid.md)
- [x] **0009** [Settings singleton](prompts/0009-settings.md)
- [x] **0010** [Save the profile and the run](prompts/0010-save.md)
- [x] **0011** [input_check harness](prompts/0011-input-check.md)
- [x] **0012** [Debug overlay](prompts/0012-debug-overlay.md)

## 1 - The first playable build  (15/15)

- [x] **0013** [The world renders](prompts/0013-world-render.md)
- [x] **0014** [Sprites generated from ASCII maps](prompts/0014-sprite-pipeline.md)
- [x] **0015** [The player walks and interacts](prompts/0015-player.md)
- [x] **0016** [Trees and wood](prompts/0016-wood.md)
- [x] **0017** [Rocks and stone](prompts/0017-stone.md)
- [x] **0018** [Wheat: till, plant, grow, harvest](prompts/0018-wheat.md)
- [x] **0019** [The workshop and its first recipe](prompts/0019-workshop.md)
- [x] **0020** [The shop: sell and buy](prompts/0020-shop.md)
- [x] **0021** [The day HUD](prompts/0021-day-hud.md)
- [x] **0022** [Switching reality](prompts/0022-reality-switch.md)
- [x] **0023** [Build mode](prompts/0023-build-mode.md)
- [x] **0024** [The shooting tower](prompts/0024-tower-gun.md)
- [x] **0025** [Zombies walk to the house](prompts/0025-zombies-walk.md)
- [x] **0026** [The tower kills the zombie](prompts/0026-combat.md)
- [x] **0027** [Three waves, a result screen, and back to the farm](prompts/0027-first-loop.md)

## 2 - The full day  (14/14)

- [x] **0028** [Corn and carrot](prompts/0028-three-crops.md)
- [x] **0029** [Growth stages and watering](prompts/0029-growth-stages.md)
- [x] **0030** [Fishing](prompts/0030-fishing.md)
- [x] **0031** [Iron from the rock face](prompts/0031-iron.md)
- [x] **0032** [Oil](prompts/0032-oil.md)
- [x] **0033** [The generator and energy](prompts/0033-generator.md)
- [x] **0034** [Cooking: food and meat](prompts/0034-cooking.md)
- [x] **0035** [Gunpowder and ammunition](prompts/0035-ammunition.md)
- [x] **0036** [The inventory](prompts/0036-inventory.md)
- [x] **0037** [The workshop queue](prompts/0037-craft-queue.md)
- [x] **0038** [Production runs while you are elsewhere](prompts/0038-idle-production.md)
- [x] **0039** [The day clock and dusk](prompts/0039-day-clock.md)
- [x] **0040** [The shop grows](prompts/0040-shop-full.md)
- [x] **0041** [The first day teaches itself](prompts/0041-tutorial-day.md)

## 3 - The full night  (17/17)

- [x] **0042** [Data-driven defences](prompts/0042-defence-data.md)
- [x] **0043** [The flamethrower tower](prompts/0043-tower-flame.md)
- [x] **0044** [The mortar](prompts/0044-tower-mortar.md)
- [x] **0045** [The auto-crossbow](prompts/0045-tower-crossbow.md)
- [x] **0046** [Fences and walls](prompts/0046-walls.md)
- [x] **0047** [Barricades](prompts/0047-barricades.md)
- [x] **0048** [Mines and traps](prompts/0048-traps.md)
- [x] **0049** [Zombies path around walls](prompts/0049-pathing-walls.md)
- [x] **0050** [The runner](prompts/0050-enemy-runner.md)
- [x] **0051** [The tank](prompts/0051-enemy-tank.md)
- [x] **0052** [The breaker](prompts/0052-enemy-breaker.md)
- [x] **0053** [Repair during the night](prompts/0053-repair.md)
- [x] **0054** [The player's ability](prompts/0054-ability.md)
- [x] **0055** [Double speed and skipping the night](prompts/0055-speed-controls.md)
- [x] **0056** [The night HUD](prompts/0056-night-hud.md)
- [x] **0057** [Structures take damage and die](prompts/0057-structure-damage.md)
- [x] **0058** [The Giant](prompts/0058-boss-giant.md)

## 4 - Ten nights and progression  (12/12)

- [x] **0059** [Waves as data](prompts/0059-wave-data.md)
- [x] **0060** [The ten nights, authored](prompts/0060-ten-nights.md)
- [x] **0061** [Night rewards](prompts/0061-rewards.md)
- [x] **0062** [Technology points](prompts/0062-tech-points.md)
- [x] **0063** [The tech tree](prompts/0063-tech-tree.md)
- [x] **0064** [Tower I, II, automatic](prompts/0064-tower-upgrades.md)
- [x] **0065** [Losing a night costs you](prompts/0065-defeat.md)
- [x] **0066** [Night 10 and the end of the run](prompts/0066-run-end.md)
- [x] **0067** [The autoplayer](prompts/0067-autoplayer.md)
- [x] **0068** [A balance sweep over the ten nights](prompts/0068-balance-sweep.md)
- [x] **0069** [Run statistics](prompts/0069-stats.md)
- [x] **0070** [Endless nights past ten](prompts/0070-endless.md)

## 5 - Art and visual direction  (13/13)

- [x] **0071** [The two palettes](prompts/0071-palettes.md)
- [x] **0072** [The farm tileset](prompts/0072-tileset.md)
- [x] **0073** [The player sprite](prompts/0073-player-art.md)
- [x] **0109** [The character reacts](prompts/0109-player-emotes.md)
- [x] **0074** [Zombie sprites](prompts/0074-zombie-art.md)
- [x] **0075** [Buildings and towers](prompts/0075-building-art.md)
- [x] **0076** [Night lighting](prompts/0076-lighting.md)
- [x] **0077** [Particles](prompts/0077-particles.md)
- [x] **0078** [The reality transition](prompts/0078-transition.md)
- [x] **0079** [Resource icons and the UI kit](prompts/0079-ui-kit.md)
- [x] **0080** [A pixel font](prompts/0080-font.md)
- [x] **0081** [The UI theme](prompts/0081-theme.md)
- [x] **0082** [Screenshots, and actually looking at them](prompts/0082-screenshots.md)

## 6 - Sound and juice  (8/8)

- [x] **0083** [Audio buses and a sound manager](prompts/0083-audio-buses.md)
- [x] **0084** [The sounds of the day](prompts/0084-sfx-day.md)
- [x] **0085** [The sounds of the night](prompts/0085-sfx-night.md)
- [x] **0086** [Two pieces of music](prompts/0086-music.md)
- [x] **0087** [Ambience](prompts/0087-ambience.md)
- [x] **0088** [Juice: shake, hit stop, damage numbers](prompts/0088-juice.md)
- [x] **0089** [Tooltips](prompts/0089-tooltips.md)
- [x] **0090** [The log panel](prompts/0090-log-panel.md)

## 7 - Shell and product  (11/11)

- [x] **0091** [The title screen](prompts/0091-title-screen.md)
- [x] **0092** [The main menu and the router](prompts/0092-main-menu.md)
- [x] **0093** [Options: video](prompts/0093-options-video.md)
- [x] **0094** [Options: audio](prompts/0094-options-audio.md)
- [x] **0095** [Options: controls](prompts/0095-options-controls.md)
- [x] **0096** [The pause menu](prompts/0096-pause-menu.md)
- [x] **0097** [English and Portuguese](prompts/0097-i18n.md)
- [x] **0098** [Accessibility](prompts/0098-accessibility.md)
- [x] **0099** [An icon and a boot ident](prompts/0099-icon-ident.md)
- [x] **0100** [Exports: Windows and Web](prompts/0100-exports.md)
- [x] **0110** [Refusals in two languages](prompts/0110-refusals.md)

## 8 - Ship the MVP  (8/8)

- [x] **0101** [Onboarding in seven lines](prompts/0101-onboarding.md)
- [x] **0102** [A performance budget](prompts/0102-perf-budget.md)
- [x] **0103** [Crash and error reporting](prompts/0103-error-report.md)
- [x] **0104** [Saves survive an update](prompts/0104-save-compat.md)
- [x] **0105** [A playtest build](prompts/0105-playtest-build.md)
- [x] **0106** [The release checklist](prompts/0106-release-checklist.md)
- [x] **0107** [Store assets](prompts/0107-store-assets.md)
- [x] **0108** [The devlog and a trailer clip](prompts/0108-devlog.md)

## 9 - v1.0 groundwork  (11/14)

- [x] **0112** [Room in the test suites](prompts/0112-suite-headroom.md)
- [x] **0113** [Repairs mend to the real maximum](prompts/0113-repairs-full-max.md)
- [x] **0114** [Untouched means the house the night started with](prompts/0114-untouched-house.md)
- [x] **0115** [Spawn ground that cannot be built shut](prompts/0115-spawn-room.md)
- [x] **0116** [The mortar and the flamethrower, empty and upgraded](prompts/0116-mortar-flame-ammo.md)
- [x] **0117** [Three stale documents](prompts/0117-stale-docs.md)
- [x] **0118** [One road into the waves](prompts/0118-one-road-into-night.md)
- [x] **0119** [Tests and tools build in the build step](prompts/0119-build-in-preparation.md)
- [x] **0120** [One road for art that has not arrived](prompts/0120-placeholder-road.md)
- [x] **0121** [A controller for every action](prompts/0121-gamepad-bindings.md)
- [x] **0122** [Art: the farmer's run](prompts/0122-art-farmer-run.md)
- [ ] **0123** [Art: the farmer tilling, planting, watering and harvesting](prompts/0123-art-farmer-field-work.md) - waits for art A007
- [ ] **0124** [Art: the farmer chopping, mining, collecting and carrying](prompts/0124-art-farmer-gather-work.md) - waits for art A008
- [ ] **0125** [Art: the farmer crafting, trading and repairing](prompts/0125-art-farmer-make-work.md) - waits for art A009

## 10 - Sleep is the night  (18/23)

- [x] **0126** [The clock: 06:00 to 02:00](prompts/0126-clock.md)
- [x] **0127** [Going to bed starts the night](prompts/0127-bed.md)
- [x] **0128** [Passing out at 02:00](prompts/0128-pass-out.md)
- [x] **0129** [He stays in bed all night](prompts/0129-asleep-all-night.md)
- [x] **0130** [The night camera](prompts/0130-night-camera.md)
- [x] **0131** [The guardian's cursor](prompts/0131-guardian-cursor.md)
- [x] **0132** [Defences go down only at night](prompts/0132-defences-at-night.md)
- [x] **0133** [The hotbar of defences](prompts/0133-hotbar.md)
- [x] **0134** [Repairing by cursor](prompts/0134-repair-by-cursor.md)
- [x] **0135** [The flare goes where you aim it](prompts/0135-aimed-flare.md)
- [x] **0136** [The build step waits for START](prompts/0136-start-button.md)
- [x] **0137** [The night ends at 06:00](prompts/0137-dawn-ends-night.md)
- [x] **0138** [Waking up: the morning report](prompts/0138-morning-report.md)
- [x] **0139** [The night HUD for the guardian](prompts/0139-night-hud-guardian.md)
- [x] **0140** [The day HUD: the hour and bedtime](prompts/0140-day-hud-clock.md)
- [x] **0141** [Teaching the new night](prompts/0141-tutorial-sleep.md)
- [x] **0142** [The autoplayer sleeps too](prompts/0142-autoplay-sleep.md)
- [ ] **0143** [Art: going to bed and sleeping](prompts/0143-art-farmer-bed.md) - waits for art A001
- [ ] **0144** [Art: the farmer's reactions and Zzz](prompts/0144-art-reactions.md) - waits for art A002
- [ ] **0145** [Art: the porch guardian](prompts/0145-art-guardian.md) - waits for art A003
- [ ] **0146** [Art: the guardian's cursor](prompts/0146-art-cursor.md) - waits for art A004
- [ ] **0147** [Art: the night hotbar and HUD icons](prompts/0147-art-night-icons.md) - waits for art A005
- [x] **0148** [Checkpoint: is the night better with him asleep?](prompts/0148-checkpoint-sleep.md)

## 11 - Calendar and seasons  (12/16)

- [x] **0149** [The calendar: four seasons of fourteen days](prompts/0149-calendar.md)
- [x] **0150** [Nights looked up by the calendar](prompts/0150-calendar-lookup.md)
- [x] **0151** [The night is the calendar day](prompts/0151-night-is-calendar.md)
- [x] **0152** [Full Moon nights](prompts/0152-full-moon.md)
- [x] **0153** [Boss nights repeat until the boss falls](prompts/0153-boss-nights.md)
- [x] **0154** [The calm night after a boss](prompts/0154-calm-night.md)
- [x] **0155** [Losing a night when the calendar moves on](prompts/0155-losing-calendar.md)
- [x] **0156** [The 1.0 farm map](prompts/0156-farm-map-v1.md)
- [x] **0157** [A new side every season](prompts/0157-attack-sides.md)
- [x] **0158** [The forecast](prompts/0158-forecast.md)
- [x] **0159** [Seasons on screen](prompts/0159-seasons-on-screen.md)
- [x] **0160** [The end of the year](prompts/0160-year-end.md)
- [ ] **0161** [Art: seasons and moons](prompts/0161-art-calendar-icons.md) - waits for art A010
- [ ] **0162** [Art: forecast heads](prompts/0162-art-forecast-heads.md) - waits for art A011
- [ ] **0163** [Art: winter ground](prompts/0163-art-winter-ground.md) - waits for art A012
- [ ] **0164** [Art: trees through the seasons](prompts/0164-art-seasonal-trees.md) - waits for art A013

## 12 - The day that pays  (28/53)

- [x] **0165** [Crops grow by days](prompts/0165-crops-by-days.md)
- [x] **0166** [A day of eight to ten minutes](prompts/0166-longer-day.md)
- [x] **0167** [Any grass can be tilled](prompts/0167-till-grass.md)
- [x] **0168** [Nine new crops](prompts/0168-crop-data.md)
- [x] **0169** [An inventory for many things](prompts/0169-inventory.md)
- [x] **0170** [Crops keep to their seasons](prompts/0170-crop-seasons.md)
- [x] **0171** [Winter: nothing grows outside](prompts/0171-winter-rules.md)
- [x] **0172** [Crops that grow back](prompts/0172-regrowing-crops.md)
- [x] **0173** [Five tools, three tiers](prompts/0173-tool-tiers.md)
- [x] **0174** [The can and the hoe by tier](prompts/0174-can-and-hoe.md)
- [x] **0175** [The axe and the pickaxe by tier](prompts/0175-axe-pickaxe.md)
- [x] **0176** [Copper, coal and gold](prompts/0176-copper-coal-gold.md)
- [x] **0177** [Hardwood](prompts/0177-hardwood.md)
- [x] **0178** [Sprinklers](prompts/0178-sprinklers.md)
- [x] **0179** [Fish by pond, season and hour](prompts/0179-fish-species.md)
- [x] **0180** [The fishing minigame](prompts/0180-fishing-minigame.md)
- [x] **0181** [Rods and bait](prompts/0181-rods-bait.md)
- [x] **0182** [Legendary fish and the fish book](prompts/0182-legendary-book.md)
- [x] **0183** [The coop and the barn](prompts/0183-coop-barn.md)
- [x] **0184** [Feeding, eggs and milk](prompts/0184-feeding-products.md)
- [x] **0185** [Sheep, pigs and the dog](prompts/0185-sheep-pigs-dog.md)
- [x] **0186** [Barns at night](prompts/0186-barns-at-night.md)
- [x] **0187** [Days in a barrel: the keg and the preserves jar](prompts/0187-keg-and-jar.md)
- [x] **0188** [The dairy, the loom and the mill](prompts/0188-dairy-loom-mill.md)
- [x] **0189** [The shipping bin](prompts/0189-shipping-bin.md)
- [x] **0190** [The peddler and his hours](prompts/0190-peddler.md)
- [x] **0191** [The house in three tiers](prompts/0191-house-tiers.md)
- [x] **0192** [Cooking with the new harvest](prompts/0192-cooking-v2.md)
- [ ] **0193** [Every season can make what it needs](prompts/0193-seasonal-supply.md)
- [ ] **0194** [The day's economy](prompts/0194-day-economy.md) - needs 0193
- [ ] **0195** [Teaching the new day](prompts/0195-day-tutorial.md) - needs 0194
- [ ] **0196** [Checkpoint: is the day good on its own?](prompts/0196-checkpoint-day.md) - needs 0194, 0195
- [ ] **0197** [Art: trampled crops and tilled ground](prompts/0197-art-crop-ground.md) - waits for art A014
- [ ] **0198** [Art: spring crops](prompts/0198-art-spring-crops.md) - waits for art A015
- [ ] **0199** [Art: summer crops](prompts/0199-art-summer-crops.md) - waits for art A016
- [ ] **0200** [Art: autumn crops](prompts/0200-art-autumn-crops.md) - waits for art A017
- [ ] **0201** [Art: sprinklers](prompts/0201-art-sprinklers.md) - waits for art A018
- [ ] **0202** [Art: tool icons](prompts/0202-art-tool-icons.md) - waits for art A019
- [ ] **0203** [Art: material icons](prompts/0203-art-material-icons.md) - waits for art A020
- [ ] **0204** [Art: copper, coal, gold and hardwood](prompts/0204-art-ore-hardwood.md) - waits for art A021
- [ ] **0205** [Art: fish](prompts/0205-art-fish-icons.md) - waits for art A022
- [ ] **0206** [Art: fishing gear and the minigame](prompts/0206-art-fishing-gear.md) - waits for art A023
- [ ] **0207** [Art: the farmer fishing](prompts/0207-art-farmer-fishing.md) - waits for art A024
- [ ] **0208** [Art: the farmer tending animals](prompts/0208-art-farmer-care.md) - waits for art A025
- [ ] **0209** [Art: sheep and pigs](prompts/0209-art-farm-animals.md) - waits for art A026
- [ ] **0210** [Art: the cow and the chicken redrawn](prompts/0210-art-cow-chicken.md) - waits for art A027
- [ ] **0211** [Art: animal goods](prompts/0211-art-animal-goods.md) - waits for art A029
- [ ] **0212** [Art: the coop and the barn](prompts/0212-art-coop-barn.md) - waits for art A030
- [ ] **0213** [Art: the artisan machines](prompts/0213-art-machines.md) - waits for art A031
- [ ] **0214** [Art: artisan goods](prompts/0214-art-artisan-goods.md) - waits for art A032
- [ ] **0215** [Art: the shipping bin](prompts/0215-art-shipping-bin.md) - waits for art A033
- [ ] **0216** [Art: the peddler](prompts/0216-art-peddler.md) - waits for art A034
- [ ] **0217** [Art: the house in three tiers](prompts/0217-art-house-tiers.md) - waits for art A035

## 13 - Weapons of the night  (0/28)

- [ ] **0218** [Room for more fields and more bodies](prompts/0218-perf-groundwork.md) - needs 0196
- [ ] **0219** [Essence](prompts/0219-essence.md) - needs 0196
- [ ] **0220** [The technology tree by season](prompts/0220-tech-by-season.md) - needs 0219
- [ ] **0221** [What the night leaves behind](prompts/0221-night-loot.md) - needs 0219
- [ ] **0222** [Bone meal](prompts/0222-bone-meal.md) - needs 0221
- [ ] **0223** [Defences sleep under tarps](prompts/0223-defence-tarps.md) - needs 0196
- [ ] **0224** [The scarecrow decoy](prompts/0224-decoy.md) - needs 0218
- [ ] **0225** [Zombie bait](prompts/0225-zombie-bait.md) - needs 0224
- [ ] **0226** [The beehive](prompts/0226-beehive.md) - needs 0218
- [ ] **0227** [The pumpkin catapult](prompts/0227-catapult.md) - needs 0196
- [ ] **0228** [The garlic braid](prompts/0228-garlic-braid.md) - needs 0218
- [ ] **0229** [The searchlight](prompts/0229-searchlight.md) - needs 0196, 0226
- [ ] **0230** [The electric fence](prompts/0230-electric-fence.md) - needs 0196
- [ ] **0231** [Hardwood walls and sandbags](prompts/0231-strong-walls.md) - needs 0196, 0226
- [ ] **0232** [Powers as a list](prompts/0232-powers-refactor.md) - needs 0196
- [ ] **0233** [Three new powers](prompts/0233-new-powers.md) - needs 0232, 0220, 0230
- [ ] **0234** [The arsenal grows with the seasons](prompts/0234-arsenal-by-season.md) - needs 0224, 0225, 0226, 0227, 0228, 0229, 0230, 0231, 0220, 0223
- [ ] **0235** [Art: bones, moon stones and essence](prompts/0235-art-night-loot.md) - needs 0221, 0222, 0219 - waits for art A036
- [ ] **0236** [Art: the scarecrow decoy and zombie bait](prompts/0236-art-decoy.md) - needs 0224, 0225 - waits for art A037
- [ ] **0237** [Art: the beehive](prompts/0237-art-beehive.md) - needs 0226 - waits for art A038
- [ ] **0238** [Art: the pumpkin catapult](prompts/0238-art-catapult.md) - needs 0227 - waits for art A039
- [ ] **0239** [Art: the garlic braid](prompts/0239-art-garlic.md) - needs 0228 - waits for art A040
- [ ] **0240** [Art: the searchlight](prompts/0240-art-searchlight.md) - needs 0229 - waits for art A041
- [ ] **0241** [Art: the electric fence](prompts/0241-art-electric-fence.md) - needs 0230 - waits for art A042
- [ ] **0242** [Art: hardwood walls and sandbags](prompts/0242-art-strong-walls.md) - needs 0231 - waits for art A043
- [ ] **0243** [Art: the day tarps](prompts/0243-art-tarps.md) - needs 0223, 0234 - waits for art A044
- [ ] **0244** [Art: power and new weapon icons](prompts/0244-art-power-icons.md) - needs 0233, 0234 - waits for art A045
- [ ] **0245** [Art: the dog](prompts/0245-art-dog.md) - needs 0233 - waits for art A028

## 14 - Enemies and bosses  (0/24)

- [ ] **0246** [Bosses in general](prompts/0246-bosses-general.md) - needs 0196
- [ ] **0247** [The spitter](prompts/0247-spitter.md) - needs 0218
- [ ] **0248** [The rat swarm](prompts/0248-rat-swarm.md) - needs 0218
- [ ] **0249** [The crow](prompts/0249-crow.md) - needs 0218, 0233, 0234
- [ ] **0250** [The digger](prompts/0250-digger.md) - needs 0218, 0234
- [ ] **0251** [The frost zombie](prompts/0251-frost-zombie.md) - needs 0218
- [ ] **0252** [The wraith](prompts/0252-wraith.md) - needs 0229, 0218
- [ ] **0253** [The Harvester](prompts/0253-harvester.md) - needs 0246, 0231
- [ ] **0254** [The Scarecrow King](prompts/0254-scarecrow-king.md) - needs 0246, 0249
- [ ] **0255** [The Winter Lord](prompts/0255-winter-lord.md) - needs 0246, 0251, 0253, 0254
- [ ] **0256** [Fog and rain](prompts/0256-fog-and-rain.md) - needs 0229
- [ ] **0257** [The Blood Moon](prompts/0257-blood-moon.md) - needs 0256, 0219, 0246
- [ ] **0258** [Fog, rain and a red moon on screen](prompts/0258-event-visuals.md) - needs 0256, 0257
- [ ] **0259** [Every weapon has its night](prompts/0259-matchups.md) - needs 0234, 0247, 0248, 0249, 0250, 0251, 0252, 0253, 0254, 0255, 0256, 0257
- [ ] **0260** [Art: the spitter](prompts/0260-art-spitter.md) - needs 0247, 0246 - waits for art A046
- [ ] **0261** [Art: the rat swarm](prompts/0261-art-rats.md) - needs 0248, 0246 - waits for art A047
- [ ] **0262** [Art: the crow](prompts/0262-art-crow.md) - needs 0249, 0246 - waits for art A048
- [ ] **0263** [Art: the digger](prompts/0263-art-digger.md) - needs 0250, 0246 - waits for art A049
- [ ] **0264** [Art: the frost zombie](prompts/0264-art-frost-zombie.md) - needs 0251, 0246 - waits for art A050
- [ ] **0265** [Art: the wraith](prompts/0265-art-wraith.md) - needs 0252, 0246 - waits for art A051
- [ ] **0266** [Art: the Harvester](prompts/0266-art-harvester.md) - needs 0253 - waits for art A052
- [ ] **0267** [Art: the Scarecrow King](prompts/0267-art-scarecrow-king.md) - needs 0254 - waits for art A053
- [ ] **0268** [Art: the Winter Lord](prompts/0268-art-winter-lord.md) - needs 0255 - waits for art A054
- [ ] **0269** [Art: fog, rain and the Blood Moon icons](prompts/0269-art-event-icons.md) - needs 0256, 0257 - waits for art A055

## 15 - Fifty-six nights and balance  (0/11)

- [ ] **0270** [Fifty-six nights as data](prompts/0270-night-records-v2.md) - needs 0256, 0257, 0234
- [ ] **0271** [Spring's fourteen nights](prompts/0271-spring-nights.md) - needs 0270
- [ ] **0272** [Summer's fourteen nights](prompts/0272-summer-nights.md) - needs 0270, 0247, 0248, 0253, 0259, 0271
- [ ] **0273** [Autumn's fourteen nights](prompts/0273-autumn-nights.md) - needs 0270, 0249, 0250, 0254, 0259, 0272
- [ ] **0274** [Winter's fourteen nights](prompts/0274-winter-nights.md) - needs 0270, 0251, 0252, 0255, 0259, 0273
- [ ] **0275** [The worst night of the year, within budget](prompts/0275-perf-year.md) - needs 0274, 0234, 0248, 0233
- [ ] **0276** [The autoplayer plays a whole year](prompts/0276-autoplay-year.md) - needs 0194, 0233, 0234, 0275, 0221
- [ ] **0277** [Balancing the year](prompts/0277-balance-year.md) - needs 0271, 0272, 0273, 0274, 0276, 0259
- [ ] **0278** [The economy across a year](prompts/0278-economy-seasons.md) - needs 0277
- [ ] **0279** [Year 2](prompts/0279-year-two.md) - needs 0277
- [ ] **0280** [Checkpoint: do fifty-six nights tire?](prompts/0280-checkpoint-year.md) - needs 0277, 0278, 0279, 0258

## 16 - Sound, collections and polish  (0/10)

- [ ] **0281** [The new day's sounds](prompts/0281-sfx-day-v2.md) - needs 0196
- [ ] **0282** [The sounds of the fishing minigame](prompts/0282-sfx-fishing.md) - needs 0196
- [ ] **0283** [The guardian's sounds](prompts/0283-sfx-night-v2.md) - needs 0233, 0234
- [ ] **0284** [The new enemies and bosses, heard](prompts/0284-sfx-enemies-v2.md) - needs 0247, 0248, 0250, 0252, 0253, 0254, 0255, 0257
- [ ] **0285** [Music for four seasons](prompts/0285-music-seasons.md) - needs 0282
- [ ] **0286** [Fog, rain and winter wind](prompts/0286-ambience-v2.md) - needs 0256, 0257, 0285
- [ ] **0287** [Collections and achievements](prompts/0287-collections.md) - needs 0253, 0254, 0255
- [ ] **0288** [Art: the collection book, trophies and badges](prompts/0288-art-collections.md) - needs 0287 - waits for art A056
- [ ] **0289** [Art: the morning report](prompts/0289-art-morning.md) - waits for art A057
- [ ] **0290** [The 1.0 visual gate](prompts/0290-visual-gate-v1.md) - needs 0123, 0124, 0125, 0143, 0144, 0145, 0146, 0147, 0161, 0162, 0163, 0164, 0197, 0198, 0199, 0200, 0201, 0202, 0203, 0204, 0205, 0206, 0207, 0208, 0209, 0210, 0211, 0212, 0213, 0214, 0215, 0216, 0217, 0235, 0236, 0237, 0238, 0239, 0240, 0241, 0242, 0243, 0244, 0245, 0258, 0260, 0261, 0262, 0263, 0264, 0265, 0266, 0267, 0268, 0269, 0288

## 17 - Ship 1.0  (0/7)

- [ ] **0291** [Saves into 1.0](prompts/0291-saves-v1.md) - needs 0279, 0287
- [ ] **0292** [Options for the new controls](prompts/0292-options-v1.md)
- [ ] **0293** [The first week, taught](prompts/0293-onboarding-v1.md) - needs 0195
- [ ] **0294** [Every new word in Portuguese](prompts/0294-translation-v1.md) - needs 0287, 0293, 0291, 0292
- [ ] **0295** [A playtest build of the year](prompts/0295-playtest-v1.md) - needs 0280, 0291, 0292, 0293, 0294
- [ ] **0296** [The store page and trailer for 1.0](prompts/0296-store-v1.md) - needs 0290, 0294
- [ ] **0297** [Releasing 1.0](prompts/0297-release-v1.md) - needs 0290, 0291, 0292, 0293, 0294, 0295, 0296
