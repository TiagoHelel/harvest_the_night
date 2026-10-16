# Backlog - HARVEST THE NIGHT

`#######################.`  **284 / 297 done**

0 doing / 13 todo / 0 blocked across 18 phases.

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

13 task(s) left, the ready ones first, then what they
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

### 0294 - Every new word in Portuguese

Ready to pick up.  Likely files: `assets/locale/strings.csv, tools/i18n_check.py, src/ui/names.gd, src/tools/headless_v1.gd`.

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

### 0298 - The seasons' second weeks

Ready to pick up.  Likely files: `src/core/game_data.gd, src/core/almanac.gd, src/tools/nights.gd, src/tools/headless_v1.gd, implementation/BALANCE.md`.

0280 found where the year tires: each season's days 9-13 send the same kinds from the same sides five nights running, only bigger - twenty of the year's 56 nights - and the forecast says the same thing two nights running about twenty times a year, most of them there. Give every second week something to meet without breaking the rhythm the plan wants (days 8-13 grow again with the season's novelty) or the year 0277 balanced.

- Measure first: `python tools/nights.py --sameness` for seeds 0-3, before and after, in the journal
- One written key night in each season's second week (day 11 is free of every other rule: no Full Moon, no boss, no introduction): a pinch rather than a bigger copy - the season's heaviest kinds from one side, or its newest kind leading - at the made night's hit points for that day, so `check_nights`' rules (a size never falls, a gap never grows) hold as written
- The made nights of days 9-13 no longer share a mix: a template's `mix` may name a day a kind's weight changes (`[weight, the day it joins]` gains an optional third, `[weight, day, weight from day 9]`), read by `Almanac.mix_on`, checked by `check_nights`; Year 2's `_later` follows it
- Targets, asserted in `_task_0298_second_weeks` in `src/tools/headless_v1.gd`: no two nights of a season's days 9-13 share their mix of kinds and sides; the longest run of nights that bring nothing new is three at most; the forecast says the same thing two nights running at most once a season
- The year still holds: `python tools/autoplay.py --year 8` after the change keeps 0277's target (`towers` two to four nights lost before Winter 1) or the journal says why and the owner calls it; the table in the journal
- DATA moves on purpose (the key nights and the templates), SIM should not - the determinism night is day 1 - both in `implementation/PROGRESS.md`

  - done when: `_task_0298_second_weeks` in `src/tools/headless_v1.gd` holds the three sameness targets for seeds 0-3
  - done when: `python tools/nights.py --sameness` before and after, and the `--year 8` table after, are in the journal
  - done when: `python tools/verify.py` prints PASS
  - done when: the determinism hash is unchanged, or the change is deliberate and both the old and the new number are in the journal

### 0290 - The 1.0 visual gate

Waits on 0123, 0124, 0125, 0143, 0144, 0207, 0208.  Likely files: `src/tools/shot.gd, src/tools/capture_menus.gd, implementation/shots/0290/, implementation/backlog/CATALOGUE.md, implementation/backlog/packs/, tools/backlog/, implementation/prompts/, implementation/PROGRESS.md`.

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

### 0295 - A playtest build of the year

Waits on 0294, 0298.  Likely files: `src/app/playtest.gd, src/ui/main.gd, tools/playtest.py, docs/PLAYTEST.md, src/tools/headless_v1.gd, src/tools/headless_check.gd`.

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

Waits on 0290, 0294, 0295, 0296.  Likely files: `src/core/build_info.gd, CHANGELOG.md, implementation/RELEASE.md, export_presets.cfg, tools/release.py, tools/devlog.py, docs/devlog/, tools/goldens/, src/tools/headless_v1.gd`.

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

## 10 - Sleep is the night  (21/23)

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
- [x] **0145** [Art: the porch guardian](prompts/0145-art-guardian.md)
- [x] **0146** [Art: the guardian's cursor](prompts/0146-art-cursor.md)
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

## 12 - The day that pays  (51/53)

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
- [x] **0200** [Art: autumn crops](prompts/0200-art-autumn-crops.md)
- [x] **0201** [Art: sprinklers](prompts/0201-art-sprinklers.md)
- [x] **0202** [Art: tool icons](prompts/0202-art-tool-icons.md)
- [x] **0203** [Art: material icons](prompts/0203-art-material-icons.md)
- [x] **0204** [Art: copper, coal, gold and hardwood](prompts/0204-art-ore-hardwood.md)
- [x] **0205** [Art: fish](prompts/0205-art-fish-icons.md)
- [x] **0206** [Art: fishing gear and the minigame](prompts/0206-art-fishing-gear.md)
- [ ] **0207** [Art: the farmer fishing](prompts/0207-art-farmer-fishing.md) - waits for art A024
- [ ] **0208** [Art: the farmer tending animals](prompts/0208-art-farmer-care.md) - waits for art A025
- [x] **0209** [Art: sheep and pigs](prompts/0209-art-farm-animals.md)
- [x] **0210** [Art: the cow and the chicken redrawn](prompts/0210-art-cow-chicken.md)
- [x] **0211** [Art: animal goods](prompts/0211-art-animal-goods.md)
- [x] **0212** [Art: the coop and the barn](prompts/0212-art-coop-barn.md)
- [x] **0213** [Art: the artisan machines](prompts/0213-art-machines.md)
- [x] **0214** [Art: artisan goods](prompts/0214-art-artisan-goods.md)
- [x] **0215** [Art: the shipping bin](prompts/0215-art-shipping-bin.md)
- [x] **0216** [Art: the peddler](prompts/0216-art-peddler.md)
- [x] **0217** [Art: the house in three tiers](prompts/0217-art-house-tiers.md)

## 13 - Weapons of the night  (28/28)

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
- [x] **0235** [Art: bones, moon stones and essence](prompts/0235-art-night-loot.md)
- [x] **0236** [Art: the scarecrow decoy and zombie bait](prompts/0236-art-decoy.md)
- [x] **0237** [Art: the beehive](prompts/0237-art-beehive.md)
- [x] **0238** [Art: the pumpkin catapult](prompts/0238-art-catapult.md)
- [x] **0239** [Art: the garlic braid](prompts/0239-art-garlic.md)
- [x] **0240** [Art: the searchlight](prompts/0240-art-searchlight.md)
- [x] **0241** [Art: the electric fence](prompts/0241-art-electric-fence.md)
- [x] **0242** [Art: hardwood walls and sandbags](prompts/0242-art-strong-walls.md)
- [x] **0243** [Art: the day tarps](prompts/0243-art-tarps.md)
- [x] **0244** [Art: power and new weapon icons](prompts/0244-art-power-icons.md)
- [x] **0245** [Art: the dog](prompts/0245-art-dog.md)

## 14 - Enemies and bosses  (24/24)

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
- [x] **0260** [Art: the spitter](prompts/0260-art-spitter.md)
- [x] **0261** [Art: the rat swarm](prompts/0261-art-rats.md)
- [x] **0262** [Art: the crow](prompts/0262-art-crow.md)
- [x] **0263** [Art: the digger](prompts/0263-art-digger.md)
- [x] **0264** [Art: the frost zombie](prompts/0264-art-frost-zombie.md)
- [x] **0265** [Art: the wraith](prompts/0265-art-wraith.md)
- [x] **0266** [Art: the Harvester](prompts/0266-art-harvester.md)
- [x] **0267** [Art: the Scarecrow King](prompts/0267-art-scarecrow-king.md)
- [x] **0268** [Art: the Winter Lord](prompts/0268-art-winter-lord.md)
- [x] **0269** [Art: fog, rain and the Blood Moon icons](prompts/0269-art-event-icons.md)

## 15 - Fifty-six nights and balance  (11/12)

- [x] **0270** [Fifty-six nights as data](prompts/0270-night-records-v2.md)
- [x] **0271** [Spring's fourteen nights](prompts/0271-spring-nights.md)
- [x] **0272** [Summer's fourteen nights](prompts/0272-summer-nights.md)
- [x] **0273** [Autumn's fourteen nights](prompts/0273-autumn-nights.md)
- [x] **0274** [Winter's fourteen nights](prompts/0274-winter-nights.md)
- [x] **0275** [The worst night of the year, within budget](prompts/0275-perf-year.md)
- [x] **0276** [The autoplayer plays a whole year](prompts/0276-autoplay-year.md)
- [x] **0277** [Balancing the year](prompts/0277-balance-year.md)
- [x] **0278** [The economy across a year](prompts/0278-economy-seasons.md)
- [x] **0279** [Year 2](prompts/0279-year-two.md)
- [x] **0280** [Checkpoint: do fifty-six nights tire?](prompts/0280-checkpoint-year.md)
- [ ] **0298** [The seasons' second weeks](prompts/0298-second-weeks.md)

## 16 - Sound, collections and polish  (9/10)

- [x] **0281** [The new day's sounds](prompts/0281-sfx-day-v2.md)
- [x] **0282** [The sounds of the fishing minigame](prompts/0282-sfx-fishing.md)
- [x] **0283** [The guardian's sounds](prompts/0283-sfx-night-v2.md)
- [x] **0284** [The new enemies and bosses, heard](prompts/0284-sfx-enemies-v2.md)
- [x] **0285** [Music for four seasons](prompts/0285-music-seasons.md)
- [x] **0286** [Fog, rain and winter wind](prompts/0286-ambience-v2.md)
- [x] **0287** [Collections and achievements](prompts/0287-collections.md)
- [x] **0288** [Art: the collection book, trophies and badges](prompts/0288-art-collections.md)
- [x] **0289** [Art: the morning report](prompts/0289-art-morning.md)
- [ ] **0290** [The 1.0 visual gate](prompts/0290-visual-gate-v1.md) - needs 0123, 0124, 0125, 0143, 0144, 0207, 0208

## 17 - Ship 1.0  (3/7)

- [x] **0291** [Saves into 1.0](prompts/0291-saves-v1.md)
- [x] **0292** [Options for the new controls](prompts/0292-options-v1.md)
- [x] **0293** [The first week, taught](prompts/0293-onboarding-v1.md)
- [ ] **0294** [Every new word in Portuguese](prompts/0294-translation-v1.md)
- [ ] **0295** [A playtest build of the year](prompts/0295-playtest-v1.md) - needs 0294, 0298
- [ ] **0296** [The store page and trailer for 1.0](prompts/0296-store-v1.md) - needs 0290, 0294
- [ ] **0297** [Releasing 1.0](prompts/0297-release-v1.md) - needs 0290, 0294, 0295, 0296
