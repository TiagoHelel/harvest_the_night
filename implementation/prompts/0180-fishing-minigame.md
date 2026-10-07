# 0180 - The fishing minigame

- **Phase:** 12 - The day that pays
- **Status:** todo
- **Depends on:** 0179, 0121, 0173
- **Likely files:** src/core/fishing.gd, src/core/game_data.gd, src/ui/fishing_bar.gd (new), src/ui/main.gd, src/app/input_actions.gd, src/app/settings.gd, project.godot, src/ui/player_work.gd, src/ui/sfx.gd, src/tools/shot.gd, src/tools/headless_check.gd, src/tools/input_check.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd

## Goal

A bite opens a simple timing bar: a marker runs, and you press as it crosses the green - simpler than Stardew's bar and as good on a pad as on a mouse.

## Art

What this task puts on screen will be dressed by Codex art pack(s) A023, A024
(`implementation/backlog/packs/`). Draw it through the placeholder road of
task 0120 until each pack is integrated - or with the pack's art if
`python implementation/backlog/assets.py status <pack>` already says
`integrated`. Never wait for art and never draw or generate PNGs here.

## Requirements

- In core, after the bite the line enters a bar stage: the marker is a pure function of the ticks since the bite (a triangle sweep, speed per species); the zone's place comes from the cast's draw and its width from the species and the rod tier (`# LEVER`s in `FISH_SPECIES` and `TOOLS`, which `check_fishing` bounds). No RNG after the cast
- Presses are intents (the `interact` edge or a dedicated one), judged against the marker on the tick they are consumed; 1-3 hits by species land the fish; misses allowed and how long the bar runs are `# LEVER`s, and running out loses the fish and nothing else
- If the bar adds or retires a verb, `_task_0084_day_sounds` still passes: every `Interact.DAY_ONLY` verb keeps an `Sfx.VERB_SOUNDS` entry (borrow `sfx/reel` until 0282 gives the bar its sounds) and `water` stays the only instant verb. A new `X.tick(state)` call in `sim.gd` joins `PerfNames.DAY` and `perf_check.gd`
- Keyboard, mouse and pad write the same intent: a new action in `InputActions.ACTIONS` and `project.godot` with a pad binding, kept in sync by the existing check
- An assist (wider zone, slower marker) is a rule, so it lives in the state: a run flag written through an intent from a Settings key, never read by core from `Settings`. The Options row is 0292's
- The view draws the bar, marker, zone and hit/miss flash through the placeholder road until A023 is integrated by 0206, and the farmer on today's `fish`/`reel` strips until A024 is integrated by 0207
- Settle the art: the bar's piece sizes into A023, and the farmer's poses and timings (cast, wait, strike, reel loop, show the catch) into A024
- SIM moves on purpose; rewrite what is left of `_task_0030_fishing`/`_case_0030_fishing` that reels in one press

## Done when

- [ ] `_task_0180_minigame` in `src/tools/headless_v1.gd`: a press on a tick inside the zone counts and one tick outside does not; a three-hit species needs three; the assist widens the zone; a replay with the same presses lands the same fish
- [ ] `_case_0180_minigame` in `src/tools/input_v1.gd`: land a fish with the keyboard, with the mouse and with a synthetic pad button
- [ ] A new `fishing_bar` scenario: `python tools/shot.py 0180 fishing_bar --fhd` shows the bar mid-catch; opened and looked at
- [ ] the Deliverables tables of `implementation/backlog/packs/A023-fishing-gear.md` and `A024-farmer-fishing.md` state the final geometry and poses this task settled
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
