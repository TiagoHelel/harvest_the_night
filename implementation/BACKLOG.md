# Backlog - HARVEST THE NIGHT

`#######################.`  **104 / 110 done**

0 doing / 6 todo / 0 blocked across 9 phases.

Run one task - `/next-task`, which reads
`implementation/prompts/00-RUNNER-LOOP.md` and does exactly one:

```
/next-task
```

Keep going until it is all ticked:

```
/loop /next-task
```

First up: **0105 - A playtest build**. The whole of what is left is
spelled out under *What is open* below, ready ones first.

The boxes below are **generated** from the `Status:` line inside each
prompt file. Do not tick them by hand: use `python tools/task.py done 0042`,
which rewrites this file for you.

## What is open

6 task(s) left, the ready ones first, then what they
unlock. Generated from `tools/backlog/part*.py` together
with the prompt files, so the two cannot disagree.

### 0105 - A playtest build

Ready to pick up.  Likely files: `tools/playtest.py`.

A build to put in front of someone, with the instrumentation to learn something from it.

- A build flag that turns on local session logging: nights reached, time per day, what was built, where the run ended
- The log is a local file the player can read and send, never an upload
- A one-page note for the tester: what to try, what to ignore, what to report
- An in-game feedback key that timestamps a note into the log
- It is obvious it is a playtest build

  - done when: A session produces a readable log
  - done when: `tools/playtest.py` summarises a folder of logs into the questions that matter

### 0107 - Store assets

Ready to pick up.  Likely files: `tools/gen_marketing.py, build/store/`.

The page it goes on: capsule images, screenshots, the pitch, generated from the game rather than mocked up.

- Capsules at the usual sizes, from the real game and the real palette
- Five screenshots from `shot.gd`, picked to show the loop, not five of the farm
- The elevator pitch from section 20 of the design document, edited to fit a store page
- An animated GIF of the reality switch
- English and Portuguese copy

  - done when: One command regenerates the whole set
  - done when: The screenshots show a day, a night, the switch, a busy wave and the tech tree

### 0109 - The character reacts

Ready to pick up.  Likely files: `src/core/player.gd, src/ui/player_view.gd`.

The little bubbles on the owner's sheet - !, ?, a heart, a note, an idea, a star - used for the two or three moments the game already has and nothing more.

- The sheet's reaction row is cut with the rest of task 0073 and is available as named frames
- A reaction is a fact in the state with a lifetime, not a thing the view invents, so the autoplayer and a replay see the same ones
- Used only where the game already has a moment: a bite on the line, a crop coming ready nearby, a structure destroyed, the night arriving. Four at most
- Never during a wave except for damage - a farmer with a music note over their head while the house burns is the wrong game
- It is decoration: removing every reaction changes nothing about what is possible, and there is an assert for that

  - done when: A reaction appears on the tick the thing happens and clears itself
  - done when: Turning them all off leaves the determinism hash unchanged

### 0110 - Refusals in two languages

Ready to pick up.  Likely files: `src/core/building.gd, src/core/sim.gd, src/core/tech.gd`.

The last English sentences in `src/core/`: the lines that say why a thing cannot be built, bought or skipped.

- `why_not_*` returns a key and its arguments rather than a sentence
- The words live in `assets/locale/strings.csv` like every other line
- The ids in a refusal - what is short, what is needed - are named by `Names.of` rather than printed raw
- `tools/i18n_check.py` covers them, widths and all

  - done when: `grep` finds no player-facing sentence left in `src/core/`
  - done when: Every refusal reads in Portuguese, and the checker proves it fits

### 0106 - The release checklist

Waits on 0105.  Likely files: `implementation/RELEASE.md`.

The list you run before publishing, written once, so nothing is remembered at the wrong moment.

- Every check with its command: verify, exports, save compatibility, the i18n checker, the perf budget, both builds smoke-tested
- Version bump, changelog, and a tag
- A known-issues section that is honest
- A rollback plan in one paragraph
- Run it once, end to end, and fix what it finds

  - done when: Running the list top to bottom produces a publishable build
  - done when: The journal records what the first run of it found, because it will find something

### 0108 - The devlog and a trailer clip

Waits on 0107.  Likely files: `tools/devlog.py, docs/devlog/`.

The thing that gets people to look: thirty seconds that show the farm, the switch and the horde.

- A scripted capture: a day of farming, the transition, a night holding, a wall falling
- It is captured from a seeded run, so it can be captured again
- A devlog page from the journal: what the loop was meant to be and what it turned out to be
- Honest about what is not in the MVP
- Both in English and Portuguese

  - done when: The clip is thirty seconds and needs no explanation
  - done when: The devlog is generated from `implementation/PROGRESS.md` rather than written twice

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

## 5 - Art and visual direction  (12/13)

- [x] **0071** [The two palettes](prompts/0071-palettes.md)
- [x] **0072** [The farm tileset](prompts/0072-tileset.md)
- [x] **0073** [The player sprite](prompts/0073-player-art.md)
- [ ] **0109** [The character reacts](prompts/0109-player-emotes.md)
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

## 7 - Shell and product  (10/11)

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
- [ ] **0110** [Refusals in two languages](prompts/0110-refusals.md)

## 8 - Ship the MVP  (4/8)

- [x] **0101** [Onboarding in seven lines](prompts/0101-onboarding.md)
- [x] **0102** [A performance budget](prompts/0102-perf-budget.md)
- [x] **0103** [Crash and error reporting](prompts/0103-error-report.md)
- [x] **0104** [Saves survive an update](prompts/0104-save-compat.md)
- [ ] **0105** [A playtest build](prompts/0105-playtest-build.md)
- [ ] **0106** [The release checklist](prompts/0106-release-checklist.md) - needs 0105
- [ ] **0107** [Store assets](prompts/0107-store-assets.md)
- [ ] **0108** [The devlog and a trailer clip](prompts/0108-devlog.md) - needs 0107
