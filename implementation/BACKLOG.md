# Backlog - HARVEST THE NIGHT

`###################.....`  **232 / 296 done**

0 doing / 64 todo / 0 blocked across 18 phases.

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

64 task(s) left, the ready ones first, then what they
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

### 0235 - Art: bones, moon stones and essence

Waits for Codex art A036.  Likely files: `assets/art_source/props/, assets/art_source/crops/, assets/art_source/ui/, assets/art_source/manifest.json, tools/check_prop_art.py, tools/check_crop_art.py, tools/check_ui_art.py`.

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

Waits for Codex art A037.  Likely files: `assets/art_source/defences/, assets/art_source/ui/, assets/art_source/manifest.json, tools/check_barrier_art.py, tools/check_ui_art.py, tools/verify.py`.

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

### 0237 - Art: the beehive

Waits for Codex art A038.  Likely files: `assets/art_source/defences/, assets/art_source/effects/, assets/art_source/manifest.json, tools/check_tower_art.py, tools/check_effect_art.py, tools/import_art.py`.

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

### 0238 - Art: the pumpkin catapult

Waits for Codex art A039.  Likely files: `assets/art_source/defences/, assets/art_source/effects/, assets/art_source/manifest.json, tools/check_tower_art.py, tools/check_effect_art.py, tools/import_art.py`.

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

### 0239 - Art: the garlic braid

Waits for Codex art A040.  Likely files: `assets/art_source/defences/, assets/art_source/manifest.json, tools/check_barrier_art.py, tools/verify.py`.

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

### 0240 - Art: the searchlight

Waits for Codex art A041.  Likely files: `assets/art_source/defences/, assets/art_source/manifest.json, tools/check_tower_art.py, tools/import_art.py`.

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

### 0241 - Art: the electric fence

Waits for Codex art A042.  Likely files: `assets/art_source/defences/, assets/art_source/effects/, assets/art_source/manifest.json, tools/check_barrier_art.py, tools/check_effect_art.py`.

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

### 0242 - Art: hardwood walls and sandbags

Waits for Codex art A043.  Likely files: `assets/art_source/defences/, assets/art_source/manifest.json, tools/check_barrier_art.py`.

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

### 0243 - Art: the day tarps

Waits for Codex art A044.  Likely files: `assets/art_source/defences/, assets/art_source/manifest.json, src/ui/world_view.gd, tools/verify.py`.

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

Waits for Codex art A045.  Likely files: `assets/art_source/ui/, assets/art_source/manifest.json, tools/check_ui_art.py`.

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

### 0245 - Art: the dog

Waits for Codex art A028.  Likely files: `assets/art_source/props/, assets/art_source/manifest.json, tools/check_prop_art.py, src/ui/art_placement.gd`.

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

### 0260 - Art: the spitter

Waits for Codex art A046.  Likely files: `assets/art_source/enemies/spitter/, assets/art_source/effects/, assets/art_source/manifest.json, assets/art_source/ownership.json, tools/check_enemy_art.py, tools/gen_sprites.py, tools/check_effect_art.py, src/ui/enemy_motion.gd`.

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

Waits for Codex art A047.  Likely files: `assets/art_source/enemies/rat/, assets/art_source/manifest.json, assets/art_source/ownership.json, tools/check_enemy_art.py, tools/gen_sprites.py, src/ui/enemy_motion.gd, src/ui/enemy_deaths.gd`.

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

### 0262 - Art: the crow

Waits for Codex art A048.  Likely files: `assets/art_source/enemies/crow/, assets/art_source/manifest.json, assets/art_source/ownership.json, tools/check_enemy_art.py, tools/gen_sprites.py, src/ui/enemy_motion.gd, src/ui/world_view.gd`.

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

Waits for Codex art A049.  Likely files: `assets/art_source/enemies/digger/, assets/art_source/manifest.json, assets/art_source/ownership.json, tools/check_enemy_art.py, tools/gen_sprites.py, src/ui/enemy_motion.gd`.

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

### 0264 - Art: the frost zombie

Waits for Codex art A050.  Likely files: `assets/art_source/enemies/frost_zombie/, assets/art_source/effects/, assets/art_source/manifest.json, assets/art_source/ownership.json, tools/check_enemy_art.py, tools/gen_sprites.py, tools/check_effect_art.py, src/ui/enemy_motion.gd`.

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

### 0265 - Art: the wraith

Waits for Codex art A051.  Likely files: `assets/art_source/enemies/wraith/, assets/art_source/manifest.json, assets/art_source/ownership.json, tools/check_enemy_art.py, tools/gen_sprites.py, src/ui/enemy_motion.gd, src/ui/wraith_fade.gdshader`.

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

Waits for Codex art A052.  Likely files: `assets/art_source/enemies/harvester/, assets/art_source/manifest.json, assets/art_source/ownership.json, tools/check_giant_art.py, tools/gen_sprites.py, src/tools/headless_check.gd, src/tools/giant_showcase.gd, src/ui/enemy_motion.gd`.

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

### 0267 - Art: the Scarecrow King

Waits for Codex art A053.  Likely files: `assets/art_source/enemies/scarecrow_king/, assets/art_source/manifest.json, assets/art_source/ownership.json, tools/check_giant_art.py, tools/gen_sprites.py, src/tools/headless_check.gd, src/tools/giant_showcase.gd, src/ui/enemy_motion.gd`.

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

### 0268 - Art: the Winter Lord

Waits for Codex art A054.  Likely files: `assets/art_source/enemies/winter_lord/, assets/art_source/effects/, assets/art_source/manifest.json, assets/art_source/ownership.json, tools/check_giant_art.py, tools/gen_sprites.py, src/tools/headless_check.gd, tools/check_effect_art.py, src/tools/giant_showcase.gd, src/ui/enemy_motion.gd`.

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

### 0269 - Art: fog, rain and the Blood Moon icons

Waits for Codex art A055.  Likely files: `assets/art_source/ui/, assets/art_source/manifest.json, assets/art_source/ownership.json, tools/check_ui_art.py, src/ui/forecast_panel.gd`.

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

### 0273 - Autumn's fourteen nights

Ready to pick up.  Likely files: `src/core/game_data.gd (`KEY_NIGHTS`, autumn's `SEASON_NIGHTS`), src/tools/headless_v1.gd`.

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

### 0281 - The new day's sounds

Ready to pick up.  Likely files: `tools/gen_sfx.py, assets/sfx/, src/ui/sfx.gd, src/tools/headless_check.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd`.

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

Ready to pick up.  Likely files: `tools/gen_sfx.py, tools/gen_music.py, assets/sfx/, assets/music/, src/ui/sfx.gd, src/tools/headless_check.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd`.

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

### 0283 - The guardian's sounds

Ready to pick up.  Likely files: `tools/gen_sfx.py, assets/sfx/, src/ui/sfx.gd, src/ui/main.gd, src/app/audio.gd, src/tools/headless_check.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd`.

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

### 0284 - The new enemies and bosses, heard

Ready to pick up.  Likely files: `tools/gen_sfx.py, assets/sfx/, src/ui/sfx.gd, src/tools/headless_check.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd`.

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

Ready to pick up.  Likely files: `src/core/collections.gd, src/core/stats.gd, src/core/farming.gd, src/core/phases.gd, src/core/run.gd, src/core/game_data.gd, src/app/save.gd, src/app/app.gd, src/app/input_actions.gd, project.godot, src/ui/collections_screen.gd, src/ui/title_screen.gd, src/ui/main.gd, scenes/Title.tscn, scenes/Main.tscn, assets/locale/strings.csv, src/tools/headless_check.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd, src/tools/shot.gd, implementation/backlog/packs/A056-collections.md`.

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

### 0293 - The first week, taught

Ready to pick up.  Likely files: `src/core/game_data.gd, src/core/tutorial.gd, src/ui/tutorial_prompt.gd, src/app/settings.gd, tools/goldens/, assets/locale/strings.csv, src/tools/shot.gd, src/tools/headless_check.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd`.

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

### 0274 - Winter's fourteen nights

Waits on 0273.  Likely files: `src/core/game_data.gd (`KEY_NIGHTS`, winter's `SEASON_NIGHTS`), src/tools/headless_v1.gd`.

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

### 0275 - The worst night of the year, within budget

Waits on 0274.  Likely files: `src/tools/perf_check.gd, src/tools/perf_names.gd, tools/perf.py, tools/perf_baseline.txt, src/tools/headless_v1.gd`.

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

### 0286 - Fog, rain and winter wind

Waits on 0285.  Likely files: `tools/gen_ambience.py, assets/ambience/, tools/gen_music.py, assets/music/, src/ui/ambience.gd, src/ui/music.gd, src/tools/headless_check.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd`.

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

### 0290 - The 1.0 visual gate

Waits on 0123, 0124, 0125, 0143, 0144, 0145, 0146, 0200, 0201, 0206, 0207, 0208, 0209, 0210, 0212, 0215, 0216, 0217, 0235, 0236, 0237, 0238, 0239, 0240, 0241, 0242, 0243, 0244, 0245, 0260, 0261, 0262, 0263, 0264, 0265, 0266, 0267, 0268, 0269, 0288.  Likely files: `src/tools/shot.gd, src/tools/capture_menus.gd, implementation/shots/0290/, implementation/backlog/CATALOGUE.md, implementation/backlog/packs/, tools/backlog/, implementation/prompts/, implementation/PROGRESS.md`.

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

### 0276 - The autoplayer plays a whole year

Waits on 0275.  Likely files: `src/tools/autoplay.gd, src/tools/autoplay_run.gd, tools/autoplay.py, src/tools/play_nights.gd, src/tools/headless_check.gd, src/tools/headless_v1.gd`.

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

Waits on 0273, 0274, 0276.  Likely files: `tools/balance.py, tools/autoplay.py, src/core/game_data.gd, implementation/BALANCE.md, implementation/PROGRESS.md, src/tools/headless_v1.gd`.

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
- A real day is the field and then a second earner (0196): the tour's field took two to two and a half game hours, and the rest of the day went to the pond and the cliff. Measure each season against that mixed day - the field, then the best earner for the hours left - beside the focused ones, and say in BALANCE.md which of the two the rule of thumb is held to
- The hens' clock (0196): a hen holds one egg and its clock waits until it is collected, 4h10m a lay, so the tour's second round, four hours after its first, found nothing. Report eggs a day at one, two and three visits, and keep `holds` at 1 only if the journal says why that is the pressure the plan wants and not a chore
- The night's purse by season (0219): a night held well pays about a quarter of a well-worked day in spring, but its bounty grows with the horde, to about seven tenths of a winter day (`src/tools/night_pay.gd` prints it). Measure it beside each season's day, and hold every season near spring's share - a `bounty_percent` that falls by season, or a bounty that grows slower than the horde - or the journal says why not. Count what the night leaves lying about with it (0221): bones at $1 and a Full Moon's four moon stones at $20 are $23 a spring night and $93 a winter one at the stall (`night_pay.gd`'s last columns)
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

Waits on 0277, 0278, 0279.  Likely files: `implementation/PROGRESS.md, implementation/shots/0280/, src/tools/shot.gd, src/tools/nights.gd, implementation/prompts/ (later prompts, if the answer needs it), tools/backlog/ (new tasks, if any)`.

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
- Questions the loop cannot answer - whether a stranger reads the week's lines (0293), whether a night is long enough, and 0196's: after the morning's field, are the pond, the cliff and the animals worth doing for themselves or only for the night - go into PLAYTEST.md's 'what to report', not into a guess in the journal

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

## 10 - Sleep is the night  (19/23)

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
- [x] **0147** [Art: the night hotbar and HUD icons](prompts/0147-art-night-icons.md)
- [x] **0148** [Checkpoint: is the night better with him asleep?](prompts/0148-checkpoint-sleep.md)

## 11 - Calendar and seasons  (16/16)

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
- [x] **0161** [Art: seasons and moons](prompts/0161-art-calendar-icons.md)
- [x] **0162** [Art: forecast heads](prompts/0162-art-forecast-heads.md)
- [x] **0163** [Art: winter ground](prompts/0163-art-winter-ground.md)
- [x] **0164** [Art: trees through the seasons](prompts/0164-art-seasonal-trees.md)

## 12 - The day that pays  (42/53)

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
- [x] **0193** [Every season can make what it needs](prompts/0193-seasonal-supply.md)
- [x] **0194** [The day's economy](prompts/0194-day-economy.md)
- [x] **0195** [Teaching the new day](prompts/0195-day-tutorial.md)
- [x] **0196** [Checkpoint: is the day good on its own?](prompts/0196-checkpoint-day.md)
- [x] **0197** [Art: trampled crops and tilled ground](prompts/0197-art-crop-ground.md)
- [x] **0198** [Art: spring crops](prompts/0198-art-spring-crops.md)
- [x] **0199** [Art: summer crops](prompts/0199-art-summer-crops.md)
- [ ] **0200** [Art: autumn crops](prompts/0200-art-autumn-crops.md) - waits for art A017
- [ ] **0201** [Art: sprinklers](prompts/0201-art-sprinklers.md) - waits for art A018
- [x] **0202** [Art: tool icons](prompts/0202-art-tool-icons.md)
- [x] **0203** [Art: material icons](prompts/0203-art-material-icons.md)
- [x] **0204** [Art: copper, coal, gold and hardwood](prompts/0204-art-ore-hardwood.md)
- [x] **0205** [Art: fish](prompts/0205-art-fish-icons.md)
- [ ] **0206** [Art: fishing gear and the minigame](prompts/0206-art-fishing-gear.md) - waits for art A023
- [ ] **0207** [Art: the farmer fishing](prompts/0207-art-farmer-fishing.md) - waits for art A024
- [ ] **0208** [Art: the farmer tending animals](prompts/0208-art-farmer-care.md) - waits for art A025
- [ ] **0209** [Art: sheep and pigs](prompts/0209-art-farm-animals.md) - waits for art A026
- [ ] **0210** [Art: the cow and the chicken redrawn](prompts/0210-art-cow-chicken.md) - waits for art A027
- [x] **0211** [Art: animal goods](prompts/0211-art-animal-goods.md)
- [ ] **0212** [Art: the coop and the barn](prompts/0212-art-coop-barn.md) - waits for art A030
- [x] **0213** [Art: the artisan machines](prompts/0213-art-machines.md)
- [x] **0214** [Art: artisan goods](prompts/0214-art-artisan-goods.md)
- [ ] **0215** [Art: the shipping bin](prompts/0215-art-shipping-bin.md) - waits for art A033
- [ ] **0216** [Art: the peddler](prompts/0216-art-peddler.md) - waits for art A034
- [ ] **0217** [Art: the house in three tiers](prompts/0217-art-house-tiers.md) - waits for art A035

## 13 - Weapons of the night  (17/28)

- [x] **0218** [Room for more fields and more bodies](prompts/0218-perf-groundwork.md)
- [x] **0219** [Essence](prompts/0219-essence.md)
- [x] **0220** [The technology tree by season](prompts/0220-tech-by-season.md)
- [x] **0221** [What the night leaves behind](prompts/0221-night-loot.md)
- [x] **0222** [Bone meal](prompts/0222-bone-meal.md)
- [x] **0223** [Defences sleep under tarps](prompts/0223-defence-tarps.md)
- [x] **0224** [The scarecrow decoy](prompts/0224-decoy.md)
- [x] **0225** [Zombie bait](prompts/0225-zombie-bait.md)
- [x] **0226** [The beehive](prompts/0226-beehive.md)
- [x] **0227** [The pumpkin catapult](prompts/0227-catapult.md)
- [x] **0228** [The garlic braid](prompts/0228-garlic-braid.md)
- [x] **0229** [The searchlight](prompts/0229-searchlight.md)
- [x] **0230** [The electric fence](prompts/0230-electric-fence.md)
- [x] **0231** [Hardwood walls and sandbags](prompts/0231-strong-walls.md)
- [x] **0232** [Powers as a list](prompts/0232-powers-refactor.md)
- [x] **0233** [Three new powers](prompts/0233-new-powers.md)
- [x] **0234** [The arsenal grows with the seasons](prompts/0234-arsenal-by-season.md)
- [ ] **0235** [Art: bones, moon stones and essence](prompts/0235-art-night-loot.md) - waits for art A036
- [ ] **0236** [Art: the scarecrow decoy and zombie bait](prompts/0236-art-decoy.md) - waits for art A037
- [ ] **0237** [Art: the beehive](prompts/0237-art-beehive.md) - waits for art A038
- [ ] **0238** [Art: the pumpkin catapult](prompts/0238-art-catapult.md) - waits for art A039
- [ ] **0239** [Art: the garlic braid](prompts/0239-art-garlic.md) - waits for art A040
- [ ] **0240** [Art: the searchlight](prompts/0240-art-searchlight.md) - waits for art A041
- [ ] **0241** [Art: the electric fence](prompts/0241-art-electric-fence.md) - waits for art A042
- [ ] **0242** [Art: hardwood walls and sandbags](prompts/0242-art-strong-walls.md) - waits for art A043
- [ ] **0243** [Art: the day tarps](prompts/0243-art-tarps.md) - waits for art A044
- [ ] **0244** [Art: power and new weapon icons](prompts/0244-art-power-icons.md) - waits for art A045
- [ ] **0245** [Art: the dog](prompts/0245-art-dog.md) - waits for art A028

## 14 - Enemies and bosses  (14/24)

- [x] **0246** [Bosses in general](prompts/0246-bosses-general.md)
- [x] **0247** [The spitter](prompts/0247-spitter.md)
- [x] **0248** [The rat swarm](prompts/0248-rat-swarm.md)
- [x] **0249** [The crow](prompts/0249-crow.md)
- [x] **0250** [The digger](prompts/0250-digger.md)
- [x] **0251** [The frost zombie](prompts/0251-frost-zombie.md)
- [x] **0252** [The wraith](prompts/0252-wraith.md)
- [x] **0253** [The Harvester](prompts/0253-harvester.md)
- [x] **0254** [The Scarecrow King](prompts/0254-scarecrow-king.md)
- [x] **0255** [The Winter Lord](prompts/0255-winter-lord.md)
- [x] **0256** [Fog and rain](prompts/0256-fog-and-rain.md)
- [x] **0257** [The Blood Moon](prompts/0257-blood-moon.md)
- [x] **0258** [Fog, rain and a red moon on screen](prompts/0258-event-visuals.md)
- [x] **0259** [Every weapon has its night](prompts/0259-matchups.md)
- [ ] **0260** [Art: the spitter](prompts/0260-art-spitter.md) - waits for art A046
- [ ] **0261** [Art: the rat swarm](prompts/0261-art-rats.md) - waits for art A047
- [ ] **0262** [Art: the crow](prompts/0262-art-crow.md) - waits for art A048
- [ ] **0263** [Art: the digger](prompts/0263-art-digger.md) - waits for art A049
- [ ] **0264** [Art: the frost zombie](prompts/0264-art-frost-zombie.md) - waits for art A050
- [ ] **0265** [Art: the wraith](prompts/0265-art-wraith.md) - waits for art A051
- [ ] **0266** [Art: the Harvester](prompts/0266-art-harvester.md) - waits for art A052
- [ ] **0267** [Art: the Scarecrow King](prompts/0267-art-scarecrow-king.md) - waits for art A053
- [ ] **0268** [Art: the Winter Lord](prompts/0268-art-winter-lord.md) - waits for art A054
- [ ] **0269** [Art: fog, rain and the Blood Moon icons](prompts/0269-art-event-icons.md) - waits for art A055

## 15 - Fifty-six nights and balance  (3/11)

- [x] **0270** [Fifty-six nights as data](prompts/0270-night-records-v2.md)
- [x] **0271** [Spring's fourteen nights](prompts/0271-spring-nights.md)
- [x] **0272** [Summer's fourteen nights](prompts/0272-summer-nights.md)
- [ ] **0273** [Autumn's fourteen nights](prompts/0273-autumn-nights.md)
- [ ] **0274** [Winter's fourteen nights](prompts/0274-winter-nights.md) - needs 0273
- [ ] **0275** [The worst night of the year, within budget](prompts/0275-perf-year.md) - needs 0274
- [ ] **0276** [The autoplayer plays a whole year](prompts/0276-autoplay-year.md) - needs 0275
- [ ] **0277** [Balancing the year](prompts/0277-balance-year.md) - needs 0273, 0274, 0276
- [ ] **0278** [The economy across a year](prompts/0278-economy-seasons.md) - needs 0277
- [ ] **0279** [Year 2](prompts/0279-year-two.md) - needs 0277
- [ ] **0280** [Checkpoint: do fifty-six nights tire?](prompts/0280-checkpoint-year.md) - needs 0277, 0278, 0279

## 16 - Sound, collections and polish  (0/10)

- [ ] **0281** [The new day's sounds](prompts/0281-sfx-day-v2.md)
- [ ] **0282** [The sounds of the fishing minigame](prompts/0282-sfx-fishing.md)
- [ ] **0283** [The guardian's sounds](prompts/0283-sfx-night-v2.md)
- [ ] **0284** [The new enemies and bosses, heard](prompts/0284-sfx-enemies-v2.md)
- [ ] **0285** [Music for four seasons](prompts/0285-music-seasons.md) - needs 0282
- [ ] **0286** [Fog, rain and winter wind](prompts/0286-ambience-v2.md) - needs 0285
- [ ] **0287** [Collections and achievements](prompts/0287-collections.md)
- [ ] **0288** [Art: the collection book, trophies and badges](prompts/0288-art-collections.md) - needs 0287 - waits for art A056
- [ ] **0289** [Art: the morning report](prompts/0289-art-morning.md) - waits for art A057
- [ ] **0290** [The 1.0 visual gate](prompts/0290-visual-gate-v1.md) - needs 0123, 0124, 0125, 0143, 0144, 0145, 0146, 0200, 0201, 0206, 0207, 0208, 0209, 0210, 0212, 0215, 0216, 0217, 0235, 0236, 0237, 0238, 0239, 0240, 0241, 0242, 0243, 0244, 0245, 0260, 0261, 0262, 0263, 0264, 0265, 0266, 0267, 0268, 0269, 0288

## 17 - Ship 1.0  (0/7)

- [ ] **0291** [Saves into 1.0](prompts/0291-saves-v1.md) - needs 0279, 0287
- [ ] **0292** [Options for the new controls](prompts/0292-options-v1.md)
- [ ] **0293** [The first week, taught](prompts/0293-onboarding-v1.md)
- [ ] **0294** [Every new word in Portuguese](prompts/0294-translation-v1.md) - needs 0287, 0293, 0291, 0292
- [ ] **0295** [A playtest build of the year](prompts/0295-playtest-v1.md) - needs 0280, 0291, 0292, 0293, 0294
- [ ] **0296** [The store page and trailer for 1.0](prompts/0296-store-v1.md) - needs 0290, 0294
- [ ] **0297** [Releasing 1.0](prompts/0297-release-v1.md) - needs 0290, 0291, 0292, 0293, 0294, 0295, 0296
