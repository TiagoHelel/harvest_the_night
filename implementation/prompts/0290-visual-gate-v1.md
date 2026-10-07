# 0290 - The 1.0 visual gate

- **Phase:** 16 - Sound, collections and polish
- **Status:** todo
- **Depends on:** 0122, 0123, 0124, 0125, 0143, 0144, 0145, 0146, 0147, 0161, 0162, 0163, 0164, 0197, 0198, 0199, 0200, 0201, 0202, 0203, 0204, 0205, 0206, 0207, 0208, 0209, 0210, 0211, 0212, 0213, 0214, 0215, 0216, 0217, 0235, 0236, 0237, 0238, 0239, 0240, 0241, 0242, 0243, 0244, 0245, 0258, 0260, 0261, 0262, 0263, 0264, 0265, 0266, 0267, 0268, 0269, 0288
- **Likely files:** src/tools/shot.gd, src/tools/capture_menus.gd, implementation/shots/0290/, implementation/backlog/CATALOGUE.md, implementation/backlog/packs/, tools/backlog/, implementation/prompts/, implementation/PROGRESS.md

## Goal

Before 1.0 ships, look at the whole game in its real frame - every screen, season, family and state at 1920x1080, by day and by night - and prove nothing is still drawn on a stand-in. Like sprite task 0020: no claim of done from one nice farm shot.

## Requirements

- Capture at 1920x1080 by day and by night with `python tools/shot.py 0290 <scenarios> --fhd`, the showcases behind `python tools/show_art.py` and `src/tools/capture_menus.gd`; add the `shot.gd` scenarios that are missing (a night scenario uses 0130's camera hook)
- The world, at least: the four seasons' ground and trees, snow included; the farmer walking, running, every work verb and facing, in bed, passed out, fishing and reacting; the guardian and the cursor; every crop stage, tilled and trampled ground; the animals and their buildings, wrecked-but-standing included; machines, the bin, the peddler, the house tiers; every defence at every level with hurt, fire, wreck and its tarp; every enemy walking, attacking and dying; the four bosses and their telegraphs; effects; fog, rain, the Full and the Blood Moon
- Every screen: title, pause, options, the day HUD with clock and calendar, the forecast, the night HUD with hotbar and powers, the morning report, inventory, stall, workshop and machines, the tech tree by season, the fishing minigame, the fish book and collections, statistics, the year's end and the credits - in English and Portuguese where there are words
- Open every file. Judge scale against Stardew Valley at 1080p and the look against `docs/reference-sheet.png`: one art pixel is 4x4 physical pixels, the farmer about 128 px tall, and no new family drawn at the six legacy fixtures' 2x unless the journal says why
- 0120's placeholder check (`python tools/placeholders.py` and `_task_0120_placeholders` in `headless_v1.gd`) reports nothing on a stand-in, and `python implementation/backlog/assets.py list` shows every pack `integrated`, A057 excepted only if declined. 0289 is not a dependency because A057 is optional: if it is still todo, read the pack's status - declined (`blocked` with the owner's words) means run 0289's decline path here and close it; approved means block this gate until 0289 is done; anything else (todo, generating, review) means block it `waiting for asset A057 (Codex)` - a later decline then needs `python tools/task.py todo 0290` by hand
- Fix here what needs no new art and is small (placement, pivots, scale, sorting, the wrong state shown); a view fix bigger than that, and anything that needs new art (a correction pack in `implementation/backlog/packs/`), becomes a follow-up task in `tools/backlog/` with the next free id. Add each follow-up id to 0297's deps (in `tools/backlog/part13.py` and on the `Depends on:` line of its prompt, which `gen_backlog.py` does not overwrite) so 1.0 cannot ship ahead of it. This task never draws or generates art, and its fixes are view only: neither hash moves
- A 1.0 delivery catalogue, `implementation/backlog/CATALOGUE.md`, modelled on `implementation/sprites/DELIVERY.md`: per family the pack id, canvases, pivots, animation and state coverage, the capture that shows it, and its known limits

## Done when

- [ ] Every capture in `implementation/shots/0290/` was opened; the journal lists what was looked at per family and per screen, what was wrong and what was done about it
- [ ] 0120's placeholder check prints zero packs pending (A057 excepted only when declined and 0289 closed), quoted in the journal
- [ ] The catalogue names a capture for every family and state in the lists above
- [ ] Every follow-up is filed as a task (and a pack when it needs art) with ids, each one in 0297's deps, none left as prose
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
