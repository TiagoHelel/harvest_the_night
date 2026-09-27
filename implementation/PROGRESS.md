# Progress journal - HARVEST THE NIGHT

Append-only, newest last. One entry per backlog task, written by the runner loop
in `prompts/00-RUNNER-LOOP.md` as step 5.

The format:

```markdown
## 0042 - The shooting tower - done 2026-09-27

What changed: two or three sentences, in plain language.
Files: src/core/towers.gd, src/core/game_data.gd
Verify: 96 headless / 21 input / hash 1873912198 unchanged
Notes: anything the next session needs to know. Follow-ups worth a new task.
```

A task that could not be finished gets the same entry with `- blocked`, what was
tried, and exactly what decision or asset it is waiting on.

**Write down the hash whenever it moves**, with the old number and the new one,
and why the rule changed. That line is the only record of a deliberate balance
change, and `tools/determinism_hash.txt` on its own cannot tell you which of
forty commits moved it.

---

## 0000 - The backlog itself - done 2026-09-27

What changed: turned `design.md` and `docs/reference-sheet.png` into a 108-task
backlog with the same harness as the welcome_back_hero repository - generated
prompts, a Status line per task, a generated checkbox index, a bootstrap
`verify.py` that skips what the backlog has not built yet, and a loop driver.

Files: tools/backlog/part1-4.py, tools/gen_backlog.py, tools/task.py,
tools/verify.py, implementation/, .claude/commands/next-task.md

Verify: PASS - 2 passed, 5 skipped (everything Godot waits on task 0001).

Notes: the repository has no Godot project yet; task 0001 creates it. Decisions
baked into the backlog and worth knowing before changing them:

- **480x270 at 16px tiles**, integer scaling only. The farm is 40x18 tiles,
  which is the design document's "1.2 to 1.5 screens wide, one tall".
- **One fixed 30Hz tick** advances day growth, night combat, the headless
  tests, the 2x button and skipping a night. That single decision is what makes
  the determinism guard, the autoplayer and the skip-the-night feature possible
  at all; task 0055 is its acceptance test.
- **A flow field from the house**, not A* per zombie. Cheap, deterministic, and
  it holds a hundred of them with walls being built and destroyed underneath.
- **The reference sheet is wider than the design document.** The sheet shows a
  mortar, an auto-crossbow, mines, gunpowder, meat and energy, and nights up to
  20. The backlog follows the sheet for content and the document for scope: ten
  authored nights, with endless as an off-path extra at 0070.
- **Everything in English.** pt-BR is a translation file at task 0097, not a
  hardcoded string anywhere before it.

## 0001 - Godot project scaffold - done 2026-09-27

What changed: the repository is a Godot 4.7 project. `project.godot` at
480x270 with integer scaling and `gl_compatibility`, `scenes/Main.tscn` booting
to a screen that names the build, the six source directories each with a README
saying what belongs in it, and export presets for Windows and Web.

Files: project.godot, scenes/Main.tscn, src/ui/main.gd, src/core/build_info.gd,
export_presets.cfg, src/{core,ui,tools}/README.md, scenes/README.md,
sprites/README.md, assets/README.md, tools/verify.py

Verify: PASS - 3 passed, 4 skipped. `--import` exits 0, booting for 90 frames
prints the build line with no error or warning, and the boot screen renders
correctly at 480x270 (looked at it, not just asserted it).

Notes:

- **The exports could not be run: this machine has no Godot export templates.**
  `%APPDATA%/Godot/export_templates/` exists and is empty, so every export fails
  with the same unhelpful error. The presets themselves are written and correct.
  `verify.py` now detects this and prints SKIP naming the fix - Editor > Manage
  Export Templates > Download - rather than failing a build that is not broken.
  That is a deviation from this task's "both exports produce a file in build/",
  and it is an environment fix rather than a code one. It has to be resolved
  before **0100 - Exports**, which is where it actually matters.
- `build_info.gd` is a `RefCounted` with constants rather than an autoload, so
  `src/core/` stays node-free from the first file in it. Read it as
  `BuildInfo.VERSION`.
- Two small fixes to the bootstrap `verify.py` while it was in front of me: the
  export check now takes each preset's own `export_path` from the cfg instead of
  inventing one, and `godot import` no longer prints the importer's chatter on a
  pass.
- `.gitignore`, `.gitattributes` and the first commits already existed from the
  backlog session, so the "git init" requirement was already satisfied.

## 0002 - Fixed-timestep deterministic simulation - done 2026-09-27

What changed: the one clock the whole game runs on. `Sim.tick(state)` advances
the world exactly once at 30Hz; `Sim.ticks_for()` turns a frame's `delta` into a
whole number of ticks with the remainder carried over and a cap on catching up;
`Rng` is a seeded xorshift128 the state carries; `State` is plain Dictionary and
Array with a deep copy and an order-independent hash. `SimDriver` is the only
thing in the game that touches `delta`, and the boot screen now shows the clock
running so the tick is visible rather than merely asserted.

Files: src/core/sim.gd, src/core/rng.gd, src/core/state.gd,
src/core/game_data.gd, src/ui/sim_driver.gd, src/ui/main.gd, scenes/Main.tscn,
src/tools/headless_check.gd, tools/verify.py, tools/backlog/part1.py

Verify: PASS - 4 passed, 3 skipped. **13 asserts, 0 failed.** No hash baseline
yet (task 0005 records it), but the number the guard will lock in is here:
**10000 ticks at seed 1234 hashes to 440001231.**

Notes:

- **`randi_range` and `randf` are taken.** GDScript has both as globals, so a
  static method of the same name loses to the built-in at the call site *inside
  the same file* - `Rng.chance()` was silently calling the engine's
  `randi_range(from, to)` and the parser only complained about the argument
  count. Renamed to `Rng.int_between()` and `Rng.unit_float()`. That is better
  than the prompt asked for: `grep -rE 'randi|randf|Time\.' src/core/` now finds
  **no calls at all**, only the doc comments explaining the ban, instead of "only
  rng.gd".
- **A Godot tool script that errors never exits.** `extends SceneTree` with a
  parse error in `_initialize()` leaves the tree running forever, so the check
  hangs instead of failing - it cost two 120-second timeouts to find. `verify.py`
  now bounds every script run at 120s and reports a timeout as "hung - it never
  reached quit()". **Task 0004 was rescoped** from "build the harness" to "harden
  it": the harness shipped here with 0002's asserts, because the house rule is
  that a rule ships with its test, and the hang is the real work left. Its prompt
  is rewritten and its deps now include 0003.
- The RNG is xorshift128 over four 32-bit words with every intermediate masked
  back into 32 bits. That masking is not decoration: GDScript's `>>` is an
  arithmetic shift, so an unmasked port goes wrong the first time a value crosses
  the sign bit, and it goes wrong differently on different builds.
- The state hash sorts Dictionary keys before folding. Iteration is insertion
  order, so two equal states built in different orders would otherwise hash
  differently - it has to be a hash of the state, not of how it was assembled.
- `MAX_CATCH_UP_TICKS = 8` drops a long stall rather than paying it. Confirmed
  on screen: 150 frames from a cold start reached tick 138, not tick 900.

## 0003 - game_data.gd, the one file of levers - done 2026-09-27

What changed: the file everything else reads its numbers from. Thirteen
resources, three crops, gathering and fishing, eight recipes, four production
buildings, eight defences, five enemies, the ten nights of `design.md` section
10, and the reward and defeat tables. `# LEVER` on every balance dial with its
unit and a sane range. `validate()` cross-checks every id one table points at
against the table that defines it.

Files: src/core/game_data.gd, src/tools/headless_check.gd

Verify: PASS - 4 passed, 3 skipped. **57 asserts, 0 failed** (13 before this
task). Hash unchanged at 440001231, correctly: this task added data and no rule
reads any of it yet.

Notes:

- **The validator is tested failing, not only passing.** Each check takes its
  table rather than reading the constant, so `headless_check` hands
  `check_recipes()` a recipe wanting `unobtainium` and asserts the error names
  it, and hands `check_nights()` a wave of `vampire` and asserts the same. A
  validator nobody has seen fail is one nobody should trust.
- **The economy, as arithmetic.** Crops, net of seed, per second of growth:
  wheat (2 x $4 - $3) / 90s = **$0.056/s**, corn (3 x $5 - $6) / 180s =
  **$0.050/s**, carrot (2 x $3 - $4) / 60s = **$0.033/s**. Wheat wins on money
  and is meant to - carrot's value is food, which is what repairs a wall at
  three in the morning, and corn's is oil and gunpowder. That is how task 0028's
  "no crop strictly dominates" is supposed to hold, and task 0068 is where it
  gets measured instead of reasoned about.
- **One number was wrong and the arithmetic found it.** Ore respawn was 240s,
  the whole length of a day, which means each node yields one iron per day and a
  15-iron gun tower costs three days of nothing but mining. Task 0031 asks that
  a day's mining buy roughly one tower. Dropped to 60s: six nodes re-minable
  four times is ~24 iron a day at 6s a hit, which is 144s of a 240s day spent
  at the rock face - a real cost, and one tower.
- The wheat growth lever was turned from 90s to 45s and back as a check: it
  appears in exactly one place, no assert moved and the hash did not move. The
  behavioural half of "changes growth and nothing else" is not observable until
  task 0018 plants something, and 0018's prompt already asks for that assert.
- Speeds are **ticks per tile**, not tiles per second, so they stay integers and
  two machines cannot disagree about where a zombie is.
- Carrot is in, though the reference sheet shows only wheat and corn:
  `design.md` section 5 names three crops and the document is the scope
  authority.

## 0004 - Harden the headless check harness - done 2026-09-27

What changed: the harness can no longer report success for work it did not do,
and can no longer hang instead of failing. Three mechanisms, cheapest first: a
group counter, a watchdog, and a new parse gate in `verify.py`.

Files: src/tools/headless_check.gd, tools/verify.py

Verify: PASS - 5 passed, 3 skipped. 57 asserts, 0 failed. Hash still 440001231
(nothing here touches a rule). Whole run 7s warm, 8s from a deleted `.godot/`;
`headless_check` itself 0.3s against its 10s budget.

Notes:

- **GDScript has no exceptions, and that is the whole problem.** A runtime
  error prints, abandons the function it happened in, and returns to the
  caller. A check that died half way would otherwise sail on to the end of the
  file and print `0 failed` for asserts it never reached. Each `_task_NNNN_*`
  group now increments `_completed` **as its last statement**, so an abandoned
  group cannot count itself, and `_finish()` fails when fewer groups finished
  than `GROUPS` says exist. Adding a group means bumping that constant.
- **`--import` does not parse scripts.** Measured, not assumed: a script with
  `not_a_real_function_anywhere()` in it imports clean and exits 0.
  `--check-only --script` does compile, and exits 1 when it cannot. `verify.py`
  gained a **script parse** row that runs it over every `.gd` - 8 scripts, 2.5s
  - so a parse error is caught before any tool script gets the chance to
  half-run.
- **All three failure paths were tested, not assumed**, as the prompt insisted:
  - a runtime error half way through a group: **exit 1 in 506ms**, reporting
    `a check group did not finish - 1 of 2 completed`
  - a parse error in `sim.gd`, a dependency: **exit 1 in 507ms**, and
    `verify.py` also fails at the parse gate naming the file and the line
  - `_initialize()` never returning at all: the watchdog ends the main loop at
    **5.4s** with `0 of 2 completed`, instead of idling for ever
- The watchdog is `_process()` returning `true`. `SceneTree` inherits
  `MainLoop._process(delta) -> bool` and returning true ends the loop - checked
  with a throwaway probe before relying on it. It is reached only when
  `_initialize()` never returns, which is why the group counter is the fast
  path and the watchdog is the backstop.
- `verify.py`'s 120s timeout stays as the outermost belt. It is now the third
  line of defence rather than the only one.

## 0005 - verify.py and the determinism guard - done 2026-09-27

What changed: `src/tools/determinism.gd` runs a fixed scenario and prints two
numbers, and `verify.py` guards both against baseline files. **Two guards, not
one**, because they answer two different questions.

Files: src/tools/determinism.gd, src/core/game_data.gd, tools/verify.py,
tools/determinism_sim_hash.txt, tools/determinism_data_hash.txt,
src/tools/headless_check.gd, implementation/README.md,
implementation/prompts/00-RUNNER-LOOP.md

Verify: PASS - 7 passed, 2 skipped, 8s. 60 asserts, 0 failed.

**First baselines recorded: sim 2393142509, data 3714036227.**

Notes:

- **Why two.** The prompt's done-when says "changing a lever makes the hash move
  and the run FAILs until --accept". It would not have. No rule reads a lever
  yet - the systems that will are 0018 onward - so a hash of the simulated state
  is blind to a balance change today, and a balance change is precisely the
  thing that must never happen by accident. So:
  - **sim hash**: `State.create(424242)` advanced 20000 ticks, hashed. Moves
    when the rules do. Every system the backlog adds ticks inside `Sim.tick()`,
    so each starts being covered the moment it lands without this file changing.
  - **data hash**: `GameData.digest()`, a fold over every balance table. Moves
    when the design does.
  A port that changes no behaviour must move neither, which makes "port with
  zero behaviour change" a checkable claim rather than a hopeful one - task 0042
  depends on exactly that.
- **Both directions were tested, not assumed:**
  - lever `HOUSE_HP` 100 -> 110: data hash 3714036227 -> 1895612796, **FAIL**;
    sim hash unchanged. `--accept` records it and prints `3714036227 ->
    1895612796` with a reminder to journal it. Putting the lever back is caught
    too - a revert is a change like any other.
  - a rule change, `Sim.tick()` made to consume randomness: sim hash 2393142509
    -> 2870855444, **FAIL**; data hash unchanged.
  - no baseline at all: **FAIL** with "no baseline yet", not a silent pass.
- `GameData.digest()` lists its tables by hand. Reflecting over the class would
  have been shorter and would silently stop covering whatever was added last;
  **a new table means a new line there**, and that is on purpose.
- `determinism.gd` carries the same watchdog and the same reached-the-end flag
  as `headless_check` - a scenario that dies half way must not print a number
  anybody trusts.
- `implementation/README.md` and the runner loop both talked about "the
  determinism hash" in the singular. Updated.

## 0006 - The phase machine: day, preparation, night, result - done 2026-09-27

What changed: `Phases` owns DAY -> PREPARATION -> NIGHT -> RESULT -> DAY as four
functions on the state, and `Sim.tick()` now dispatches on the phase rather than
running one undifferentiated list. The boot screen shows the phase and the day
so the machine is visible rather than only asserted.

Files: src/core/phases.gd, src/core/sim.gd, src/core/state.gd,
src/tools/determinism.gd, src/tools/headless_check.gd, src/ui/main.gd

Verify: PASS - 7 passed, 2 skipped, 8s. **86 asserts, 0 failed** (60 before).

**Sim hash moved deliberately: 2393142509 -> 2127612543.** Two reasons, both
this task's job: the state gained the six keys `Phases.initial()` owns, and the
scenario in `determinism.gd` now walks a whole cycle instead of sitting in the
day. Data hash unchanged at 3714036227, correctly - no lever was touched.

Notes:

- **The phase decides which systems tick, and nothing else does.** That is what
  makes "crops do not grow at night" and "no zombie spawns in the afternoon"
  structural facts rather than conditions somebody has to remember to write in
  fifteen places. Neither crops nor zombies exist yet, so the assert is on
  `day_tick` and `night_tick`: 600 ticks of day move one and not the other, 400
  ticks of night move the other and not the one. When the real systems land they
  hang off `_tick_day` and `_tick_night` and inherit the property.
- **A transition refuses rather than half-applies.** `begin_night()` from DAY
  returns false, pushes an error and changes nothing - checked, including that
  the day counter did not move. A corrupted phase would otherwise surface three
  thousand ticks later as a zombie on a sunny afternoon. The check prints four
  deliberate ERROR lines and says so on the line above them, so nobody learns to
  scroll past ERROR in this log.
- **PREPARATION ends itself** after `GameData.PREPARATION_TICKS`, and the player
  can end it early. That makes it the first lever any rule actually reads.
- **Dusk asks, it never presses.** `is_dusk()` is true past the lever and the
  phase stays DAY - `design.md` promises the player switches reality when they
  want to, and an auto-advancing day would quietly take that away.
- RESULT freezes the world: 300 ticks inside it leave the state hash unchanged
  apart from `tick` and `phase_tick`. Asserted, because "nothing moves while the
  payout is up" is easy to believe and easy to get wrong.
- `State.create()` now merges each subsystem's own `initial()` instead of
  growing one literal nobody can navigate. `Phases.initial()` is the first.
- The payout itself is task 0061. What RESULT records now is the outcome it will
  be computed from - night number, survived, how long it took - so the result
  screen reads one dictionary rather than interrogating the world afterwards.

## 0007 - The resource ledger - done 2026-09-27

What changed: `Resources` owns what the player has and is the only way it
changes. `add`/`gain` to give, `spend`/`pay` to take, `can_afford` and
`missing` to ask. `GameData.STARTING_RESOURCES` says what day 1 begins with.

Files: src/core/resources.gd, src/core/game_data.gd, src/core/state.gd,
src/tools/headless_check.gd

Verify: PASS - 7 passed, 2 skipped, 9s. **123 asserts, 0 failed** (86 before).

**Both guards moved deliberately.** Sim 2127612543 -> 673656594: the state
gained `held` and `gained`. Data 3714036227 -> 1015548053: the tables gained
`STARTING_RESOURCES`.

Notes:

- **Paying is all or nothing, and that is the whole point of the file.** The
  obvious implementation - a loop of `spend()` over the cost - takes the wood,
  fails on the iron, and leaves the player four wood poorer with nothing to show
  for it. `pay()` checks `can_afford()` across every line first. Asserted by
  hashing the state before a failed payment and after it: not even the
  affordable line moves.
- **Deviation from the prompt, on purpose.** It asked for a negative balance to
  be "a hard error in debug and a clamped no-op in release". Implemented as
  clamp-always plus `push_error`-always instead. Godot's `assert()` would give
  literally what was asked, but a rule that resolves differently in two builds
  breaks both the determinism guard and the browser-matches-desktop promise -
  and it would make the clamp untestable, because the assert would halt the
  headless check. The error is diagnostics; the clamp is the rule, in every
  build.
- **No starting iron**, deliberately. The first gun tower costs 15 iron and
  there is no way to get it but the rock face, which is the lesson day 1 is
  meant to teach. Starting stock is 25 money, 12 wood, 6 stone: enough to buy
  seeds and put up a fence without standing around, not enough to skip the day.
- `gained` only ever goes up, including for things later spent - that is what
  the statistics screen of task 0069 reports and what a balance sweep reads to
  find out where a run's wood actually came from.
- Every Dictionary walk sorts its keys first. Nothing in this file draws from
  the RNG today, so nothing depends on the order yet; the day something does,
  the hash would otherwise start depending on the order a cost literal happened
  to be typed in.
- An unknown resource id is refused and does not quietly create itself.

## 0008 - The farm grid - done 2026-09-27

What changed: the farm exists. `GameData.FARM_MAP` is one 40x18 ASCII picture
of the whole world; `Grid` is the cell arithmetic and `Farm` is what is made of
what and what is standing on it. `buildable()` and `occupant()` are the only
way anything asks.

Files: src/core/farm.gd, src/core/grid.gd, src/core/game_data.gd,
src/core/state.gd, src/tools/headless_check.gd

Verify: PASS - 7 passed, 2 skipped, 9s. **160 asserts, 0 failed** (123 before).

**Both guards moved deliberately.** Sim 673656594 -> 3413240837: the state
gained `terrain` and `occupants`. Data 1015548053 -> 2522481920: the tables
gained `FARM_MAP` and its legend.

Notes:

- **One grid, both realities**, which is `design.md` pillars 1 and 2 made
  structural. There is one terrain array and one occupant table; the day screen
  and the night screen will be two views of them. Asserted end to end: a wall
  placed by day is in the same cell after `begin_preparation` and a night
  falling. A second copy for the night would be a second thing to keep in step
  and it would have drifted inside a week.
- **Regions are the map, not coordinates written down twice.** `cells_with()`
  and `cells_of()` derive the field, the pond, the wood, the rock face and the
  house from the characters. Moving the pond means editing the pond.
- **Place-then-remove leaves the farm byte-identical**, the done-when of this
  task, checked by hashing before and after. The build-then-sell loop of task
  0023 depends on it, and so does anything that previews a placement.
- `place()` deep-copies what it is handed, so a caller holding on to the
  dictionary it passed cannot reach back into the state afterwards. Asserted.
- The house is a fixture: not buildable on, not removable, and
  `why_not_buildable()` says which of the reasons applies so the red ghost of
  task 0023 can explain itself.
- **I rendered the map and looked at it**, which found something the asserts
  could not: the trees were a decorative border rather than the "area de
  arvores" `design.md` asks for, so there was nowhere to go for wood. Added a
  grove on the open right-hand side - 60 trees became 76.
- `Grid.STEPS` is a written-down order, not an incidental one. A flow field
  breaks ties between equally short paths by whichever neighbour it saw first,
  so that order decides which way a zombie walks around a wall and has to be
  the same on every machine. Task 0025 depends on it.
- Terrain is a `PackedByteArray`: 720 bytes, deep-copied by `State.copy()` and
  folded by the hash as one string rather than 720.

## 0009 - Settings singleton - done 2026-09-27

What changed: `Settings` owns every presentation and comfort option and writes
them to `user://settings.cfg`. One defaults dictionary, namespaced keys, typed
getters, `changed(key)`, an atomic save and a migration hook.

**A new directory, `src/app/`**, and nine backlog prompts moved into it.

Files: src/app/settings.gd, src/app/README.md, project.godot, tools/verify.py,
src/tools/headless_check.gd, tools/backlog/part1.py, tools/backlog/part4.py

Verify: PASS - 8 passed, 2 skipped, 10s. **182 asserts, 0 failed** (160 before).
Both hashes unchanged, correctly: nothing here is a rule or a lever.

Notes:

- **`src/app/` exists because the house rule would otherwise have been broken
  nine times.** The prompt put `settings.gd` in `src/core/`, and eight later
  prompts did the same for save, audio, ambience, the router, input actions,
  i18n, a11y and crash reporting. Every one of those is a node that touches the
  disk. `src/core/` earns its guarantee - headless, deterministic, replayable -
  by being narrow, and a settings file reading `user://` is exactly what it must
  not contain. All nine prompts now say `src/app/`; they were all still `todo`,
  so regenerating them lost nothing.
- **The rule is now checked rather than remembered.** `verify.py` has a **core
  is pure** row: no `extends Node`, no `randi`/`randf`/`randi_range`/
  `randf_range`, no `Time.`, no `OS.`, no `RandomNumberGenerator` anywhere in
  `src/core/`, doc comments excepted. It would have caught this drift on task
  0010 instead of task 0009.
- **The test found a real hole, which is what tests are for.**
  `ConfigFile.load()` returning OK does not mean the file was ours: Godot's
  parser is lenient enough to read `[[[ this is not a config file ]]` as a
  section and report success. A genuinely corrupt file was therefore reaching
  the happy path, coming up on defaults, and never telling anybody. Every file
  this class writes carries `[meta] version`; one that does not is now treated
  as corrupt, warned about, and left on disk rather than overwritten.
- **The crash window is closed, not ignored.** Windows will not rename onto an
  existing file, so an atomic save has to remove the old one first - leaving a
  moment where neither file exists. `_recover_path()` reads the temporary file
  when the real one is missing, so a crash in that window costs nothing.
  Asserted.
- Settings works on a plain `Settings.new()` outside the tree. An autoload is
  only added to the root when a scene runs, so a `--script` check would never
  see one; `_ready()` does nothing but call `load_from_disk()`.
- A key not in `DEFAULTS` does not exist: it cannot be read, cannot be written,
  and is dropped from a file that has it. A value of the wrong type falls back
  to its default rather than poisoning a panel.

## 0010 - Save the profile and the run - done 2026-09-27

What changed: two files, `user://run.sav` and `user://profile.sav`. The run save
is the core state and nothing else; the profile is what outlives a run. Both
written atomically, both checked before they are trusted.

Files: src/app/save.gd, src/tools/headless_check.gd

Verify: PASS - 8 passed, 2 skipped, 10s. **205 asserts, 0 failed** (182 before).
Both hashes unchanged: saving reads the state and never writes to it.

Notes:

- **The save is the state, not a second description of it.** Because
  `src/core/` has been plain data since task 0002, saving is serialisation
  rather than a parallel account of the world that could quietly disagree with
  the real one. The whole file is `{"state": state}`.
- **`var_to_bytes`, not JSON.** Measured with a probe before committing to it:
  it round-trips `StringName`, `PackedByteArray`, integer dictionary keys and
  the int-versus-float distinction exactly, and JSON loses every one of those.
  **Never `var_to_bytes_with_objects`** - that would let a save file instantiate
  a script, and a save file is data somebody else can hand you.
- **Mid-night saves finish the night identically.** Asserted directly: save at
  night tick 500, advance the original and the reloaded copy 3000 ticks each,
  hashes match. That only holds because the RNG stream position is part of the
  state, which is what task 0002 bought.
- **The checksum earns its place.** The same probe showed `bytes_to_var` on a
  truncated buffer returns null after printing two engine errors about Variant
  decoding - true but useless to a player. Header, length and FNV-1a checksum
  are all checked first, so a damaged save is refused with a message about the
  save. Six ways of being wrong are covered: truncated, a single flipped bit,
  not ours, empty, too short, and from a format this build does not know.
- **The previous save becomes the backup**, and only then does the new one take
  its place. A crash at any point leaves either the old file, or the old file as
  `.bak` plus a complete `.tmp` - never a half-written save.
- A profile from an older build gains the keys this build added rather than
  being rejected; one from a newer build keeps what this build understands.
  Losing somebody's statistics because they opened an older copy of the game
  would be unforgivable, and it is the kind of thing that happens by default.
- `Save` is static functions on a `RefCounted`, not an autoload: nothing here
  needs to be in the tree, and the headless check calls it directly.

## 0011 - input_check harness - done 2026-09-27

What changed: real clicks and real keys, through the real scenes, with nobody
in the room. `input_check.gd` opens a scene, finds controls by name, clicks
them, clicks farm cells, presses keys, and tears the scene down for the next
case. Wired into `verify.py`, which now has only one SKIP left.

Files: src/tools/input_check.gd

Verify: PASS - 9 passed, 1 skipped, 11s. 205 asserts, **15 cases, 0 failed**.
Both hashes unchanged: nothing here is a rule.

Notes:

- **Headless really is enough**, measured with a probe before the file was
  written: with `--headless` the viewport is the project's own 480x270,
  `root.push_input()` reaches Controls and fires their signals, and
  `Input.parse_input_event()` sets `Input.is_key_pressed()`. So there is no
  window and - more importantly - no separate "test mode" path through the UI.
  A test mode is a thing that can be right while the real path is wrong.
- **The harness is proved to fail loudly, not assumed to.** `require_control()`
  on a name that is not there records a failure; the case asks for a control
  that does not exist, checks the failure landed, and takes it back off the
  tally. That is the only place in the file that does so and it says so on the
  line above. Separately verified from outside: renaming `Clock` to `ClockTypo`
  produces two failures and exit 1.
- `locate_control()` is the quiet counterpart, for asking whether something is
  there at all.
- **There is nothing in the game to click yet**, so the case checks the
  machinery that will click it: that the scene is live (the clock moves between
  frames), that a synthesised click reaches a control's handler and a click
  elsewhere does not, that a held key stays held and a tapped one lets go.
  Real interactions get their own `_case_NNNN_*` as the backlog adds them.
- `cell_to_screen()` asks the world view for the mapping when there is one, so
  the camera of task 0013 is accounted for automatically. Until then the
  viewport is the farm's own resolution and the mapping is the obvious one.
- Cases are counted the way `headless_check` counts groups: the counter is the
  last line of each case, so one that dies half way cannot report success.
- Noticed in passing: autoloads **do** run under `--script`, so `Settings` was
  alive during the check. `headless_check` instantiating its own copy is
  belt-and-braces rather than a necessity, and it stays that way - a test that
  depends on autoload ordering is a test that breaks for reasons unrelated to
  what it checks.

## 0012 - Debug overlay - done 2026-09-27

What changed: F3 puts up what you actually want while tuning - phase, day,
night, every tick counter, the seed and the live RNG words, fps, speed, ticks
per frame, what the last batch cost in microseconds per tick, what the player
holds, and what is standing on the farm by kind. **Phase 0 is finished.**

Files: src/ui/debug_overlay.gd, src/ui/sim_driver.gd, src/ui/main.gd,
scenes/Main.tscn, project.godot, src/tools/input_check.gd

Verify: PASS - 9 passed, 1 skipped, 12s. 205 asserts, **28 cases, 0 failed**.
Both hashes unchanged, which is one of this task's done-whens.

Notes:

- **It reads and never writes**, so "toggling it does not move the hash" is
  true by construction. Checked anyway, with the driver frozen first so that
  the ordinary tick is not the thing doing the moving - "by construction" is
  exactly how view layers start writing to state.
- **It is not in a release build at all.** `_ready()` frees the node when
  `OS.is_debug_build()` is false, so there is no key combination to find and no
  per-frame cost in a shipped game.
- `SimDriver` now measures what a frame's ticks cost, because it is the only
  thing that knows how many ran. A real clock read, which is fine: it is not a
  rule. `input_check` asserts the number is a measurement and not a decorative
  zero - it reads about 8 microseconds a tick on a farm of 100 occupants.
- **Half a done-when is deferred, and it is worth saying so plainly.** "It
  shows the tick cost climbing when a hundred zombies are alive" cannot be
  checked until task 0025 provides a hundred zombies. The counter is live and
  asserted; task 0102 is where the number becomes a gate.
- **Two things came from looking at it rather than from the asserts.** Nodes
  added in code without a `name` get an internal `@PanelContainer@2` that
  nothing can find, which broke the input case until they were named - and
  naming them is the whole reason `require_control` can be loud. And Godot's
  default panel is nearly transparent, so the readout was sitting unreadable on
  top of the title; it has its own opaque style now rather than the game theme,
  because a debug overlay should look the same whatever the theme is doing.
- `debug_overlay` is the first named input action (F3). Task 0095 makes the set
  rebindable; the point today is that no keycode is written at a call site.
- The overlay is handed its driver by the screen that owns it rather than going
  looking for one, so two simulations on screen would each be described by
  their own.

## 0013 - The world renders - done 2026-09-27

What changed: the farm is on screen. `WorldView` draws the terrain on a
`TileMapLayer` and the occupants on a y-sorted layer above it, with a camera
fenced in at the farm's edges. `Main.tscn` stopped being a boot screen and
became the game screen.

Files: src/ui/world_view.gd, scenes/World.tscn, scenes/Main.tscn,
src/ui/main.gd, src/tools/input_check.gd

Verify: PASS - 9 passed, 1 skipped, 13s. 205 asserts, **41 cases, 0 failed**
(28 before). Both hashes unchanged, which is one of this task's done-whens.

Notes:

- **The camera is locked vertically and the map was drawn for it.** The farm is
  640x288 and the viewport 480x270, so there are 160 pixels of horizontal pan
  and only 18 of vertical. Locking Y to the middle crops nine pixels off the top
  and the bottom - and rows 0 and 17 are the tree line and the far water, a
  decorative border rather than anywhere the player goes. A camera drifting over
  eighteen pixels would be motion sickness in exchange for nothing.
- **Godot's camera limits do the clamping**, so no arithmetic here can produce
  the gap or the repeated column the done-when warns about. Checked at both
  edges, by eye and by assert.
- **`cell_to_screen()` is why click cases will keep working.** `input_check`
  asks the view for it by name, so a click on a cell goes wherever the camera
  has put it. Two of the older case-0011 asserts went stale the moment this
  landed - the naive identity mapping was no longer the answer - and were
  rewritten to check the round trip instead of today's coordinates.
- The other stale assert was "the clock moved": the label reads in whole
  seconds now, so twenty frames of it say nothing. It checks the tick counter
  instead, which is what it was really asking about.
- Redraw is a signature check on the occupant dictionary, not a rebuild per
  frame. Godot's `Dictionary.hash()` is cheap and notices a placement or a
  removal; the determinism hash is a different thing for a different job and is
  not used for this.
- **Looking at it found what the asserts could not.** The first render had trees
  at a green close to the grass in value, inset two pixels - they vanished into
  the lawn. Placeholder art has exactly one job, which is to be legible, so the
  trees went darker and every occupant got a darker rim so a block reads as an
  object rather than as a stain.
- Terrain is built once and never touched again: nothing in the game turns grass
  into water, and the day and the night are the same tiles by design.
- The placeholder tileset and textures are generated in this file. Tasks 0014
  and 0072 replace two functions and nothing else in the view will know.

## 0014 - Sprites generated from ASCII maps - done 2026-09-27

What changed: the game has art, and a script owns it. `tools/palette.py` is the
one colour table, `tools/sprite_maps.py` is every sprite as a picture you can
read in a text editor, and `tools/gen_sprites.py` turns the second through the
first into `sprites/**.png`. The world view loads them instead of inventing
flat colours.

Files: tools/palette.py, tools/sprite_maps.py, tools/gen_sprites.py,
sprites/ (12 PNGs + README), src/ui/world_view.gd, project.godot,
tools/verify.py, src/tools/input_check.gd

Verify: PASS - 10 passed, 1 skipped, 13s. 205 asserts, **43 cases, 0 failed**.
Both hashes unchanged: art is not a rule.

Notes:

- **The PNG writer is hand-rolled, and that is the point.** Pillow is not a
  dependency of the game and writes a timestamp chunk by default, which would
  make every regeneration a diff - a build output that changes every time it is
  built is one nobody can check. Four chunks, fixed compression level, and the
  bytes are a function of the pixels and of nothing else. Measured: two runs,
  byte-identical, `5e3544f4c0ce` both times.
- **One character is one pixel**, measured rather than asserted: changing a
  single `g` to another colour in one row of `terrain/grass` and re-rendering
  changed **exactly 1 pixel**.
- **`verify.py` has a `sprites` row now.** The PNGs are committed so a clone
  runs with no build step - which also means somebody can open one in an editor
  and paint over it, after which the palette no longer owns that sprite and
  nobody finds out until a colour change leaves one thing the old green.
  `--check` catches it.
- **Import settings are project-wide, not per file.** `[importer_defaults]` in
  `project.godot` turns off mipmaps, compression and 3D detection for every
  texture, so a sprite added later cannot arrive with the wrong settings
  because somebody forgot. Verified in the generated `.import`.
- The world view loads `sprites/` and keeps the flat colour blocks only as a
  fallback for occupants nothing has drawn yet - the farmhouse, until task
  0075. It is deliberately visible: "nobody has drawn the house" should look
  like a placeholder, not like a design choice. `input_check` asserts the
  tileset is the generated atlas and not the emergency flat one, so a forgotten
  generator step is a red line rather than a slightly duller farm.
- The palette names a day ramp and a night ramp. Task 0071 applies them as a
  shader - the same pixels, relit - which is how `design.md` section 18 gets
  two realities out of one set of sprites.

## 0015 - The player walks and interacts - done 2026-09-27

What changed: somebody is on the farm. `Player` owns position, facing and
whatever they are in the middle of doing; `Interact` owns what a cell offers.
The camera follows, the faced cell is framed, and the UI moved onto its own
canvas layer.

Files: src/core/player.gd, src/core/interact.gd, src/core/game_data.gd,
src/core/sim.gd, src/core/state.gd, src/ui/player_view.gd, src/ui/world_view.gd,
src/ui/main.gd, scenes/Main.tscn, scenes/World.tscn, project.godot,
src/tools/input_check.gd

Verify: PASS - 10 passed, 1 skipped, 19s. 205 asserts, **59 cases, 0 failed**
(43 before). **Sim hash 3413240837 -> 4066923035** (the state gained the player
and the intent, and the player ticks). **Data hash 2522481920 -> 3593855788**
(`PLAYER_SPEED`).

Notes:

- **Position is sub-tile and integer.** 64 units to a tile, `PLAYER_SPEED` of 6
  a tick: 2.8 tiles a second, smooth at 30Hz, and no floating point anywhere
  near it. Walking has to feel continuous or the farm is a board game, but a
  float position accumulates differently on different machines and the hash
  guard would start failing for reasons nobody could find.
- **The UI does not move the player.** It writes what is being asked for into
  `state["intent"]` and the tick decides what it means - which is what lets the
  autoplayer of task 0067 drive the game by writing the same field. Asserted:
  the same key script from the same seed ends on the same cell, twice.
- **`Interact` is why `player.gd` does not know what a tree is.** Two tables and
  three functions: what a cell offers, how long it takes, and what happens when
  the time is up. Every arm of `complete()` is deliberately empty until the task
  that owns it lands, so the wiring is testable end to end before any payload
  exists. 0016 fills chop, 0018 farm, 0030 fish, 0020 trade.
- Movement resolves one axis at a time, so walking into a wall at an angle
  slides along it. Diagonals are scaled by 181/256 or a player holding two keys
  crosses the farm 41% faster, which is the oldest bug in top-down movement.
- **Three real problems, all found by running it rather than by reasoning:**
  - **A `Camera2D` drags the whole default canvas, Controls included.** The
    clock was sliding around and a button was being picked somewhere other than
    where it was drawn. The UI is on its own `CanvasLayer` now. The HUD of task
    0021 would have hit this on its first day.
  - **`Input.is_action_just_pressed()` is only true during the frame the event
    arrived in.** A press landing after this node's `_process` had already run
    that frame was lost outright - a rare dropped keypress with a keyboard, and
    a test that failed one run in three with synthesised input. Main compares
    `is_action_pressed()` with last frame instead, which cannot race. Four
    consecutive clean runs after.
  - **A negative `z_index` inside a Y-sorted parent put the target frame behind
    the TileMapLayer**, so the highlight was being drawn under the grass and
    nothing appeared at all. It is its own node between the terrain and the
    actors now.
- The player view sits at the feet and offsets the sprite upwards, rather than
  sitting at the sprite's corner: Y-sorting uses the node's own y, and sorting a
  character by the top of their head draws them behind things they are standing
  in front of.

## 0016 - Trees and wood - done 2026-09-27

What changed: the first resource comes out of the world. `Gathering` owns
everything you hit with a tool - swings, yield, what is left behind, and the
farm putting it back - and `Interact.complete()` has its first filled-in arm.

Files: src/core/gathering.gd, src/core/game_data.gd, src/core/interact.gd,
src/core/sim.gd, src/core/state.gd, tools/sprite_maps.py, sprites/props/stump.png,
src/ui/world_view.gd, src/tools/headless_check.gd

Verify: PASS - 10 passed, 1 skipped, 21s. **230 asserts, 0 failed** (205
before). **Sim hash 4066923035 -> 2123598417** (the state gained `regrowing`,
and gathering ticks). **Data hash 3593855788 -> 3968728927** (`hits` and
`leaves`, and the retimed swings).

Notes:

- **Written for all three gatherables, not just trees.** A tree, a boulder and
  an ore seam differ only in their row of `GameData.GATHERING`. Task 0017 adds
  stone and 0031 iron; if either has to touch `gathering.gd`, this task was not
  general enough and 0017's journal should say so.
- **A node has hit points measured in swings**, and the yield arrives when the
  last one lands rather than a little at a time. Dribbling it out would make
  "a day's mining buys one tower" depend on where the player happened to stop,
  and those totals are what the economy of task 0003 was balanced on.
  Per-swing feedback belongs to the particles of task 0077.
- Swings retimed so felling something is not a chore: a tree is 3 swings of 1
  second rather than one swing of 3; ore is 3 swings of 2 seconds, which keeps
  the 24-iron day the 0003 journal worked out.
- **Nothing can be stripped for good.** Asserted at full scale: chop all 76
  trees, wait the regrowth delay, and all 76 are back with no stumps left. A
  farm you can strip-mine into uselessness is a farm you stop playing on.
- The pending list is flat and sorted by cell, because it has to survive a save
  and because two runs of the same seed must bring the same tree back on the
  same tick.
- **The night does not heal the wood.** Regrowth ticks in the day only:
  asserted across a whole night, which moved nothing along. A farm quietly
  regrowing behind a firefight would be the one thing on the night map that was
  not about the night.
- A structure built where a tree was keeps the cell - the farm gives up on that
  one rather than knocking a tower over to put a tree back.
- **One tree is exactly `hits` x `work_ticks`**, driven through the real player
  action machinery rather than by calling `strike()` directly, so the assert
  covers the wiring as well as the arithmetic.

## 0017 - Rocks and stone - done 2026-09-27

What changed: stone, from two sources that behave differently on purpose. Five
seams cut into the rock face, which come back; seven boulders on the lawn,
which do not. And a bug that had been silently live since task 0016.

Files: src/core/game_data.gd, src/core/gathering.gd, src/core/farm.gd,
src/core/interact.gd, tools/sprite_maps.py, sprites/props/seam.png,
src/ui/world_view.gd, src/tools/headless_check.gd

Verify: PASS - 10 passed, 1 skipped, 21s. **259 asserts, 0 failed** (230
before). **Sim hash 2123598417 -> 3337239467**, **data hash 3968728927 ->
3627249258** - the map gained five seams and the gathering table two rows.

Notes:

- **Was task 0016 general enough? Almost.** Adding the loose boulder and the
  seam took two data rows and **three lines of code** - a `regrow > 0` guard,
  which bought a behaviour rather than a special case. Task 0031's iron should
  need none at all. The class doc of `gathering.gd` has been corrected to say
  so rather than to keep claiming zero.
- **The rock face needed stone in it, and that came out of the requirement.**
  "Loose rocks do not respawn" would have made stone finite at 14 for the whole
  game, against 10 for a single wall. `design.md` section 5 says the mining area
  gives stone *and* iron, so five seams were cut into the cliff: 3 stone each,
  back every 90 seconds, about 39 stone across a day of nothing but mining.
  Clearing a boulder is now a reward - the cell becomes build space for good -
  rather than a way to run the farm dry.
- **A bug that survived task 0016, found by this task's first failing assert.**
  Regrowth went through `Farm.place()`, which asks whether the *player* may
  build on a cell - and the rock face is not buildable. So **ore had never been
  coming back** since the day it was written, and nothing noticed because the
  only regrowth tested was a tree, and trees stand on grass. `Farm.restore()`
  now exists for things the farm owns putting themselves back, and ore regrowth
  has its own assert.
  The lesson is the cheap one: a test that only covers the easy instance of a
  general mechanism is a test that certifies the easy instance.

## 0018 - Wheat: till, plant, grow, harvest - done 2026-09-27

What changed: the crop cycle, which is the semi-idle heart of the day. Four
verbs on a soil tile, growth in stages that only advances by daylight, and a
field that survives the night untouched.

Files: src/core/farming.gd, src/core/interact.gd, src/core/sim.gd,
src/core/state.gd, src/ui/world_view.gd, tools/sprite_maps.py, sprites/crops/,
src/tools/headless_check.gd

Verify: PASS - 10 passed, 1 skipped, 22s. **286 asserts, 0 failed** (259
before). **Sim hash 3337239467 -> 2213922541** (the state gained `plots` and
`selected_seed`, and farming ticks). Data hash unchanged: the crop table was
already there from task 0003.

Notes:

- **A plot is not an occupant**, and the second reason is the real one. You can
  walk across your own field, which an occupant would prevent - but more
  importantly, **at night the field is ground to defend**. Zombies walk over
  the wheat. Making a crop an occupant would have turned every planted tile
  into a wall, and the player would have discovered on night 3 that they had
  accidentally built a maze out of carrots.
- **One verb with four meanings, resolved by the cell.** `Interact` asks
  `Farming` what a soil tile offers and gets `till`, `plant`, `harvest` or
  nothing, so the highlight can say what the key will actually do. "Farm" would
  have been one word for four different keypresses.
- **Seeds are money, not an inventory item.** Buying a packet and then planting
  from it is two steps and a number to manage, for a decision the player already
  made by walking to the field. Task 0040 may revisit it; `_plant()` is the one
  function that would change.
- **The night does nothing at all**, asserted directly: 300 ticks of growth
  before dusk, a whole night of preparation and 2000 night ticks, and the number
  has not moved; then 100 ticks of the next morning and it is exactly 400. That
  falls out of not being ticked rather than having to be arranged, which is what
  plain data in the state buys.
- **A name collision in the flat state, and a guard so it cannot recur.**
  Farming called its chosen crop `"seed"` - already the run's RNG seed.
  `Dictionary.merge()` silently kept one of them, planting did nothing at all,
  and the only symptom was a type error three files away. `State.create()` now
  adopts each subsystem's keys one at a time and **refuses a name that is
  already taken**, naming the subsystem that asked. The flat namespace is what
  makes the state hashable and savable in one piece; this is the price, and it
  is now paid once rather than every time.
- Stage arithmetic is integer throughout. A stage boundary landing differently
  on two machines would be a visible desync in something nobody would think to
  look at.

## 0019 - The workshop and its first recipe - done 2026-09-27

What changed: the bridge the whole game rests on. Wood and stone stop being
things you sell and become a barricade. The farm comes with a workshop,
crafting runs whether anybody is watching, and cancelling costs you the
materials.

Files: src/core/crafting.gd, src/core/game_data.gd, src/core/interact.gd,
src/core/sim.gd, src/core/state.gd, src/ui/world_view.gd,
src/tools/headless_check.gd, src/tools/input_check.gd

Verify: PASS - 10 passed, 1 skipped, 23s. **316 asserts, 0 failed** (286
before). **Sim hash 2213922541 -> 865751178** (a workshop on the map, plus
`crafting`, `kits` and `selected_recipe`). **Data hash 3627249258 ->
1084797554** (the map and the legend).

Notes:

- **Inputs are taken when the job starts**, not when it finishes. That is the
  whole reason cancelling is a decision rather than a free undo, and it means
  two stations can never be counting on the same wood. Asserted from both ends:
  the wood is gone the tick the job begins, and cancelling halfway gives none of
  it back and does not let the job quietly finish later either.
- **A job belongs to a station, not to the game.** `state["crafting"]` is keyed
  by the cell the workshop stands on, so the press of task 0032 and the kitchen
  of 0034 need no new machinery, and neither would a second workshop. Task 0037
  puts a queue behind the same interface.
- **A kit is not a resource.** A barricade goes to `state["kits"]`, which build
  mode will draw from, rather than to the ledger - a structure in the resource
  table would turn up in the shop's sell list and on the HUD, and it is neither
  of those things. What decides is the output id, not the recipe, so the press
  making oil goes to the ledger without anybody writing a rule for it.
- **A recipe you cannot afford is refused and still listed.** A menu that grows
  as you get richer teaches nothing about what to go and get. `missing()` names
  the shortfall so the tooltip of task 0089 can explain a greyed line.
- The workshop is on the map rather than built, because task 0023 is where
  building arrives and `design.md` section 19 asks for one workshop in the first
  playable build. It draws as colour blocks like the farmhouse; task 0075 draws
  the buildings and can give multi-tile occupants a single anchored sprite.
- **Four tests were naming cells that the workshop then landed on.** They now
  search for a free cell instead of writing one down. A named cell is a test
  that breaks whenever the map gains a building, and a failure that teaches
  nothing about the thing being tested is worse than no test - it is a test that
  gets edited without being read.

## 0020 - The shop: sell and buy - done 2026-09-27

What changed: money, and the first reason to care which resource you went and
got. A stall that takes anything sellable, sells raw materials back at a markup,
and a panel that opens on interact and closes on escape without pausing a thing.

Files: src/core/shop.gd, src/ui/shop_panel.gd, src/core/interact.gd,
src/core/player.gd, scenes/Main.tscn, src/ui/main.gd,
src/tools/headless_check.gd, src/tools/input_check.gd

Verify: PASS - 10 passed, 1 skipped, 25s. **352 asserts, 0 failed** (316
before), **70 cases, 0 failed** (59 before). **Sim hash 865751178 -> 684454707**
(the state gained `open_panel`). Data hash unchanged: prices were already there.

Notes:

- **A panel is a state, not a screen.** `state["open_panel"]` is owned by core:
  the interact verb sets it, the cancel intent clears it, and `src/ui/` only
  draws whatever it says. That makes "the player is shopping" a fact about the
  game rather than about a node, which is what will let the autoplayer of task
  0067 sell a day's wood with no window open.
- **Nothing pauses.** Asserted: sixty ticks of haggling grew the wheat by sixty.
  `design.md` section 13 is about a farm that runs itself, and a shop that
  stopped the world would be the one place it did not.
- **Selling is all or nothing.** Selling ten wood when you have four sells none
  of them - checked by hashing the state before and after. A shop that quietly
  sold what it could would empty your bag when you fumbled a number.
- Buying is always a worse deal than going and getting it, at **every** price -
  asserted for each sellable thing rather than for one. A shop that could
  replace an afternoon at the rock face would quietly replace playing the game.
- **Deviation:** the prompt asked for "buy wheat seed". Task 0018 made seeds
  money rather than an inventory item, so there is nothing to buy - the buy side
  stocks raw materials instead, which is the emergency exit for being three
  stone short at dusk. Task 0040 gives it stock and a daily limit.
- **A real bug, and input_check found it.** The player repeats an action while
  the cell still offers the same verb - which is right for chopping a tree and
  wrong for opening a stall. Escape closed the panel and the very next tick
  reopened it, because the stall still offered `trade`. Verbs are now either
  work, which repeats, or one-shot, which does not; `trade` and `craft` are
  one-shot. The second one mattered too: a finished crafting job would have
  silently started another and drained the stock.
  The assert that keeps it honest is not "escape closes it" but **"and stays
  closed a second later"**.

## 0021 - The day HUD - done 2026-09-27

What changed: the bar across the top of the reference sheet. Which day it is,
what time it is, what is in the purse, six totals that matter, and the button
that starts the night.

Files: src/ui/day_hud.gd, src/core/player.gd, src/core/sim.gd, project.godot,
scenes/Main.tscn, src/ui/main.gd, src/tools/headless_check.gd,
src/tools/input_check.gd

Verify: PASS - 10 passed, 1 skipped, 26s. **358 asserts, 0 failed**, **83 cases,
0 failed** (82 before). **Sim hash 684454707 -> 1543735352** (the intent gained
`begin_night`). Data hash unchanged.

Notes:

- **The HUD does not change the phase.** Pressing the button writes
  `intent["begin_night"]` and the tick decides, so the mouse, the `N` key and
  the autoplayer of task 0067 all take the same road into the night. Asserted
  both through the button and through the key.
- **The same tick, not the next frame.** Every number is a lookup rather than a
  copy, so the HUD and the ledger cannot drift apart. `input_check` adds wood
  and checks the label two frames later.
- A changed total lights up and fades back over four tenths of a second. A farm
  is a place where you are looking somewhere else, and a number quietly
  incrementing is a number nobody sees.
- **Past dusk the button changes what it says** and brightens; it still never
  presses itself. `design.md` promises the player switches reality when they
  want to, and a day that ended on its own would quietly take that away.
- **Three things came from looking at it rather than from the asserts.** The
  old clock label was sitting on top of the new resource grid, so it was folded
  into the day label and the node deleted. The button's text ran off the right
  edge. And pale text on a sunlit farm is text nobody can read, so the bar got a
  dark strip behind it.
- **"WOO", "STO", "IRO".** The first version abbreviated to three letters, which
  is not shorthand, it is a puzzle. At font size 9 the longest of these words is
  forty pixels and the bar is four hundred and eighty - so they are spelled out
  until task 0079 draws the icons.
- `main.gd` no longer listens for the tick signal. Every panel reads the state
  each frame and draws what it finds; a signal per tick would have meant a
  redraw per tick, which at 4x speed is four times the work for one picture.

## 0022 - Switching reality - done 2026-09-27

What changed: the moment the game is named after. The same farm, relit. The
light fades between two tints from the palette, the daylight verbs are put away
at dusk, and the player walks their defences after dark.

Files: src/ui/world_view.gd, src/ui/palette_data.gd (generated),
tools/palette.py, tools/gen_sprites.py, src/core/interact.gd, src/core/sim.gd,
src/core/phases.gd, src/tools/headless_check.gd, src/tools/input_check.gd

Verify: PASS - 10 passed, 1 skipped, 27s. **375 asserts, 0 failed**, **94 cases,
0 failed**. Both hashes unchanged: the player ticking at night changes nothing
while nobody is pressing anything, and the scenario presses nothing.

Notes:

- **Nothing moves but the light.** Asserted rather than eyeballed: the terrain,
  the occupants and the plots are hashed before the switch and after it, and
  they are the same number. A tower built by day is in the same cell by night
  because it is the same dictionary.
- **The palette is generated into GDScript** by `gen_sprites.py`, so the night
  ramp the view applies and the colours the sprites were drawn against are the
  same numbers by construction. A hand-kept second copy would have drifted the
  first time somebody tuned a colour, and the drift would have been invisible
  because both copies would look plausible.
- **The farm is asleep after dark.** `Interact` puts the daylight verbs away in
  any phase but DAY - chopping a tree while a wave comes in would be the one
  thing on the night map that was not about the night, and the systems behind
  those verbs do not tick then anyway, so a verb that still worked would be a
  verb that lied. The player still walks: `design.md` section 8 has them out
  there repairing and aiming.
- **The night is teal, not purple, and that is as far as a multiply goes.**
  `CanvasModulate` can only multiply, and a farm is mostly grass: multiplying
  green by blue leaves green. The tint pulls green down hardest, which gets it
  to a cold blue-teal that reads as another world. The reference sheet's purple
  needs a *lift* as well as a tint, and nothing that multiplies can add light -
  task 0076 has the shader.
- **The fade was an exponential approach pretending to be a fade.** Lerping the
  current colour towards the target every frame arrives quickly and never quite
  finishes, so `is_transitioning()` stayed true long after it looked over. It
  lerps from where it started now.
- **Frame counts are not time, and that was three flaky asserts.** A tick is
  owed every thirtieth of a second and a headless frame can be a thousandth, so
  "wait four frames for the phase to change" is a bet on how busy the machine
  is - it passed alone and failed one run in four under load. `input_check` has
  an `until(condition)` helper now and every wait that meant "until something
  happened" uses it. Six parallel runs, all clean.
- **The hash guard flagged a move I could not explain, and it was right to.**
  Investigated rather than accepted: the scenario is stable at 1543735352 with
  and without this task's core changes, and the odd number came from six Godot
  processes running at once against one `.godot/` cache. **Do not run Godot in
  parallel against the same project** - they fight over the import cache and
  the loser reports nonsense.

## 0023 - Build mode - done 2026-09-27

What changed: things go on the farm. A palette of everything the phase allows,
a ghost that is green where it fits and red where it does not with the reason
underneath, a left click to place and a right click to sell back.

Files: src/core/building.gd, src/ui/build_mode.gd, src/core/game_data.gd,
src/core/player.gd, src/core/sim.gd, src/core/state.gd, src/ui/world_view.gd,
src/ui/main.gd, scenes/Main.tscn, project.godot, src/tools/headless_check.gd,
src/tools/input_check.gd

Verify: PASS - 10 passed, 1 skipped, 34s. **424 asserts, 0 failed** (375
before), **122 cases, 0 failed** (94 before). **Sim hash 1543735352 ->
3694981960**, **data hash 1084797554 -> 2501830300**.

Notes:

- **One price, in one place, checked.** A structure's cost was written twice -
  in `DEFENCES[id]["cost"]` and again as a workshop recipe's inputs - and the
  two had **already drifted**: 4 wood against 3 for the barricade, before
  anything used either. `GameData.validate()` now refuses a build where a kit
  recipe's inputs are not exactly the cost of the thing it makes. A kit is that
  cost paid in advance, which is how a player puts a wall up at night when
  there is nothing to gather.
- **Place and sell can never be a money printer.** The refund is a fraction of
  the cost rounded **down**, and the assert checks it for every structure in
  the catalogue rather than for one - rounding up on something cheap is the
  sort of thing nobody finds until somebody does.
- **Night takes only what says it may**, which is the barricade and nothing
  else. That is what makes it `design.md` section 8's emergency answer rather
  than a cheaper wall, and it expires on a timer so it cannot quietly become
  one either.
- **The palette shows what it cannot afford.** Greyed, priced, with the
  shortfall on the reason line - a menu that grew as you got richer would teach
  nothing about what to go and get.
- Nothing of the farm's is the player's to sell: a tree, the house and the
  workshop all refuse, asserted.
- **`get_viewport().get_mouse_position()` does not follow a synthesised event.**
  It asks the display server, so under `input_check` the ghost sat wherever the
  real cursor happened to be and every placement went to the wrong cell. The
  pointer is taken from the events themselves now, which is both testable and
  closer to what the player actually did. Motion is watched in `_input` rather
  than `_unhandled_input` because the palette panel eats it first.
- **A screenshot of this is harder than a test of it.** A windowed run has a
  real cursor whose motion events overwrite a synthesised one, so the ghost in
  a capture goes wherever the mouse physically is. The render was confirmed by
  driving `show_ghost()` directly; the input path is `input_check`'s job, and
  the verdict is now exposed as `ghost_is_ok()` so a test can ask about it - a
  colour drawn into a canvas is not something a test can read.

## 0024 - The shooting tower - done 2026-09-27

What changed: the first thing that fights for you. A tower reloads, picks a
target and puts something in the air. `Entities` is the table everything alive
lives in, and the world draws both it and the shots.

Files: src/core/towers.gd, src/core/entities.gd, src/core/sim.gd,
src/core/state.gd, src/ui/world_view.gd, src/tools/headless_check.gd

Verify: PASS - 10 passed, 1 skipped, 38s. **436 asserts, 0 failed** (424
before). **Sim hash 3694981960 -> 4008937129** (the state gained `entities`
and `projectiles`). Data hash unchanged: the tower was already in the table.

Notes:

- **`Entities` was built here rather than in task 0025**, because a tower with
  nothing to shoot at cannot be tested. It is the same call as `Gathering` in
  0016: write the shared thing once, and let the task that needs it most build
  it. 0025 adds walking and spawning from waves; the table, the ids and the
  damage are here.
- **An id, not a reference.** A projectile in flight names the thing it is
  chasing. A reference to a dictionary would either dangle when the target died
  or keep it alive after it should be gone, and ids are also the only ordering
  in the game that cannot depend on how a Dictionary felt like iterating.
- **Nearest the house, not nearest the tower.** The thing about to reach the
  farmhouse is the thing worth shooting; a tower that fired at whatever
  wandered closest to itself would let the leader through while it plinked at
  the back of the queue. Asserted with two targets at deliberately different
  distances.
- **Ties go to the lower id**, asserted with two walkers equidistant from the
  house on either side of the tower.
- **Two runs of the same seed shoot the same script.** The check records which
  target was hit on which tick across 400 ticks and compares the whole log,
  rather than comparing a final number that could match by luck.
- **Halving the rate of fire halves the shots**, measured over 600 ticks
  against an immortal target so the count is about the reload and nothing else.
- **A quiet tick costs nothing.** With no entities alive the tower loop does
  not walk the grid looking for targets; it only counts reloads down. A farm
  covered in towers on a quiet tick should not pay for the wave that is not
  there.
- The order inside `_tick_night` is now written down as a rule: enemies move
  *before* towers fire, so something that stepped into range this tick can be
  shot this tick - which is what makes a range circle mean what it looks like.
- Actor sprites are pooled rather than freed and rebuilt each frame. A wave is
  a hundred things moving every frame and that is the one place this view could
  plausibly cost something.

## 0025 - Zombies walk to the house - done 2026-09-27

What changed: the night has something in it. Zombies spawn at two edges,
follow one flow field to the farmhouse, and take a bite out of it when they
arrive. The house can fall, and when it does the night ends.

Files: src/core/pathing.gd, src/core/enemies.gd, src/core/farm.gd,
src/core/towers.gd, src/core/game_data.gd, src/core/sim.gd, src/core/state.gd,
src/core/building.gd, src/tools/headless_check.gd

Verify: PASS - 10 passed, 1 skipped, 40s. **470 asserts, 0 failed** (436
before). **Sim hash 4008937129 -> 1177574569**, **data hash 2501830300 ->
3315067798** (the spawn table, the grid version and the house's hit points).

Notes:

- **One field, not one search each.** A breadth-first sweep out from the house
  fills every cell with its distance; a zombie reads four neighbours and steps
  to the smallest. It is also the right answer rather than only the fast one:
  every zombie agrees what the shortest way is, so a wall reroutes the whole
  wave at once and the player can watch their plan work.
- **A version, not a hash.** `Farm` bumps `grid_version` on every placement and
  removal and the field rebuilds when it is behind. Hashing the occupants every
  tick to find out nothing moved is the cost the field exists to avoid.
- **Two spawn edges, not four.** A farm attacked from every side at once cannot
  be defended with the towers a first night affords, and the reason to choose
  where a wall goes disappears with it.
- **Fifty zombies went from 2316 microseconds a tick to 566**, against a budget
  of a thousand. Three things, in order of what they were worth:
  - the flow field was read **once per sub-unit of movement** rather than once
    per tick, which is three lookups where one would do;
  - `Farm.house_centre()` scanned and sorted every occupant on the farm, once
    per tower per tick - the house is a fixture and never moves, so it is
    worked out once now;
  - `Towers.tick` walked all hundred and ten occupants each tick to find the
    four towers; it keeps a list keyed by `grid_version`.
- **A bug the test was too helpful to catch.** `Enemies.spawn()` asks whether a
  cell can reach the house, and the field is only built when something needs
  it - so **the first wave of every night spawned nothing at all**. The check
  had called `Pathing.refresh()` by hand first, which is a precondition the
  game does not arrange. It now spawns onto a night nobody prepared, and the
  refresh lives where the question is asked.
- **A zombie standing on the house never bit it**, because the field says
  "stay where you are" at distance zero. Standing on it counts now.
- The farm-identity assert from task 0008 was asking about the whole state,
  which now carries a counter of how many times the farm changed. It asks about
  the ground and what is standing on it instead - which is what it meant.

## 0026 - The tower kills the zombie - done 2026-09-27

What changed: damage happens in one place. `Combat` owns armour, the minimum
hit, the kill and the hurt flash, and towers stop committing shots to something
that is already dead.

Files: src/core/combat.gd, src/core/entities.gd, src/core/towers.gd,
src/core/game_data.gd, src/core/sim.gd, src/core/state.gd, src/core/enemies.gd,
src/ui/world_view.gd, src/tools/headless_check.gd

Verify: PASS - 10 passed, 1 skipped, 42s. **492 asserts, 0 failed** (470
before). **Sim hash 1177574569 -> 3224086426**, **data hash 3315067798 ->
4216175348**.

Notes:

- **Armour never takes all of a hit.** Flat reduction is what makes many small
  hits worse than a few big ones, which is what `design.md` section 9 asks the
  tank for - but reduction that could reach zero makes a tank **immune** to the
  auto-crossbow rather than bad against it, and an immune enemy in a tower
  defence is not a hard fight, it is a night nobody can end. `MINIMUM_HIT` is 1.
- **Nothing commits to a corpse.** A target with enough already in the air to
  kill it stops being a target. Without it, a line of towers all fires at the
  leader, most of those shots land on a body and the wave behind walks past
  untouched - which looks exactly like the towers being too weak. Asserted with
  three towers and a leader one shot from dying.
- `Entities.damage()` is gone; `Combat.hit()` is the only way in, and it writes
  through the one `set_hp`. A second way in would be a second set of rules that
  agreed with the first until somebody changed one of them.
- **A test that measured the weather.** "Fifty zombies cost under a millisecond
  a tick" passed on its own and failed under `verify.py`, because `verify`
  leaves the machine busier. It now asserts the **invariant** - two hundred
  ticks of fifty zombies rebuild the flow field no times at all - which is true
  on any machine and catches the algorithmic regression that the microseconds
  were standing in for. The number is still printed, for information. Task 0102
  owns the wall-clock budget, and it should: a correctness suite that fails when
  the machine is busy is a suite people learn to re-run.
- **A balance finding worth having before task 0060 writes ten nights:** one
  gun tower against seven walkers kills five and lets two through. The check
  prints it and asserts only that all seven are accounted for - a lane of
  walking zombies is a test of the balance, not of the arithmetic, so the
  shots-per-kill count is measured against a penned group instead.

## 0027 - Three waves, a result screen, and back to the farm - done 2026-09-27

## THE FIRST PLAYABLE BUILD. Phase 1 is complete.

What changed: the loop closes. Three waves arrive from the table, the night
ends by itself, the payout is itemised on screen, and confirming it returns to
a day that is better than the one before.

Files: src/core/waves.gd, src/core/rewards.gd, src/ui/result_screen.gd,
src/core/phases.gd, src/core/sim.gd, src/core/state.gd, src/core/player.gd,
src/core/enemies.gd, src/core/game_data.gd, scenes/Main.tscn, src/ui/main.gd,
src/tools/headless_check.gd, src/tools/input_check.gd

Verify: PASS - 10 passed, 1 skipped, 53s. **524 asserts, 0 failed** (492
before), **136 cases, 0 failed** (122 before). **Sim hash 3224086426 ->
721873783**, **data hash 4216175348 -> 1636540132**.

### Measured

- A whole night is **2050 ticks, 68 seconds** - preparation, three waves, and
  the last walker dying.
- Four gun towers hold night one: **12 killed, 0 through, house untouched**,
  paying **$122 + 10 wood + 8 stone + 4 iron**.
- One gun tower against seven walkers kills five and lets two through.
- Day one, mining flat out: 6 ore nodes at 6 seconds each is 6 iron in 36
  seconds, then 60 seconds of regrowth. Fifteen iron - one gun tower - takes
  about **190 seconds of a 240 second day**, of which 84 seconds is waiting
  that can be spent chopping, planting or fishing. So day one is a real day and
  the tower at the end of it is a real purchase.

### A balance change the checkpoint forced

**Night one was unloseable.** Twelve walkers at five damage is 60 against a
house of 100, so a farm with nothing built on it survived the tutorial night
with forty hit points to spare - the one night whose job is to teach that you
have to build was teaching the opposite. Walker damage is **10** now: twelve of
them is 120 against 100, undefended loses, one tower holds it with room. The
rest of the enemy table is left for task 0068 to sweep against the autoplayer.

### Was it fun? Honestly: not yet, and the reasons are specific

The **structure** is right. The cycle closes, the numbers go up, the night is
watchable - projectiles travel, the horde walks out of the dark two at a time,
the house bar is the thing you are actually watching. The decision "do I spend
today mining or farming" is real, because iron gates towers and iron is slow.

But the answer to `design.md` section 17 - *after surviving the first night, do
you want to go back and improve?* - is **"the pull is there and there is
nothing to pull towards"**. Four things, in the order they matter:

1. **"Improve" only means "another identical tower."** One tower, one enemy.
   There is no *build* to make and so no decision with a shape. This is exactly
   what phase 3 exists for (tasks 0042-0058: five towers, four enemies, walls
   that reroute), and it is the single biggest gap.
2. **No knife-edge.** With four towers night one is a foregone conclusion; with
   none it is a loss. Nothing in between, because there is only one dial. The
   tension the design document is after needs the other towers to exist before
   it can exist.
3. **A kill does not land.** A three-frame flash and nothing else - no sound, no
   number, no particle. Tasks 0077, 0085 and 0088.
4. **The day is mostly walking.** Gathering is holding a key; fishing (0030) is
   the first thing in the day with a decision inside it.

None of that is a reason to stop - it is a reason phases 2 and 3 are next, and
every one of those four is already a task. What the checkpoint was for was
finding out whether the *loop* works before building forty things on top of it,
and it does: the three minutes exist, they end somewhere better than they
started, and the reason to go again is legible even though what you would go
and do is not yet varied enough to be interesting.

**Recommendation for the next phase:** the backlog runs 0028-0041 (the full
day) before 0042-0058 (the full night). On this evidence the night is the
hungrier half - a second tower and a second enemy would do more for the loop
right now than a third crop would. Not reordering it, because the day's
resources are what the night's towers cost and 0031-0035 feed 0043-0048
directly, but if the next playtest says the same thing, that is the swap to
make.

## 0028 - Corn and carrot

Three crops that are a real choice, and a determinism bug found by checking
whether a fourth one needs any code.

### The arithmetic

The task asks for seed cost and sale price set so that no crop strictly
dominates, and for the sums to be here. Sale prices are `design.md` section 6
and were left alone; the **seed costs** carry the balance.

Where it started, per plot across a 240 second day:

| crop | grow | seed | sells | net a harvest | harvests | **a day** |
|---|---|---|---|---|---|---|
| wheat | 90s | $3 | 2 x $4 | 5 | 2 | **10** |
| corn | 180s | $6 | 3 x $5 | 9 | 1 | **9** |
| carrot | 60s | $4 | 2 x $3 | 2 | 4 | **8** |

Carrot was strictly worse than wheat: less money, twice the walking, and a
dearer seed. That is not a choice, it is a trap, and it is what the done-when
"no crop is the right answer at every money level" is pointing at.

First attempt was to flatten them - seeds 2/3/3, every crop worth 12 a day,
differing only in how often you come back. It reads well and it is still
wrong: wheat at 12 a day, 2 visits and a $2 seed beats carrot at 12 a day,
4 visits and a $3 seed on every axis at once. Equal money is not
non-domination when the other two axes still line up the same way.

What shipped, seeds **1 / 2 / 4**:

| crop | grow | seed | sells | net a harvest | harvests | **a day** |
|---|---|---|---|---|---|---|
| carrot | 60s | $1 | 2 x $3 | 5 | 4 | **20** |
| wheat | 90s | $2 | 2 x $4 | 6 | 2 | **12** |
| corn | 180s | $4 | 3 x $5 | 11 | 1 | **11** |

Three axes, and nobody wins all three:

- **carrot** - most money, cheapest to start, and wants you standing in the
  field all day.
- **corn** - least money, one visit, four dollars up front. What you plant
  before going down the mine. Also the only crop that becomes gunpowder.
- **wheat** - beats corn on money and carrot on walking, and is the one crop
  nothing downstream competes for, so every wheat is sellable.

And the money-level question the task asks directly: **with a dollar in your
pocket only carrot goes in the ground.** There is an assert for that.

The domination test is `x.value >= y.value and x.visits <= y.visits and
x.seed <= y.seed`. Rather than assert it once, `GameData.check_crops()` now
computes it over every pair at boot, so a later balance pass cannot quietly
flatten the choice - and the fourth crop somebody adds is checked on the way
in, by name, with both sets of numbers in the message.

### A fourth crop is one dictionary entry - checked, not claimed

Done-when says to check it and say so, so it was checked rather than reasoned
about: a `pumpkin` was added to `RESOURCES`, `SELL_PRICE` and `CROPS` - three
data entries, no code - and the suite run against it.

**No game code needed changing.** The seed strip grew a fourth row with the
right grow time and per-day value, key 4 selected it, it tilled, planted,
grew, harvested and paid, and the balance guard checked it against the other
three. 602 asserts and 168 input cases ran, up from 582 and 163, because the
per-crop loops are loops over the table.

Three asserts failed, all of them tests naming the three-crop world rather
than code: the resource count, the expected sorted list, and "carrot pays the
most over a day". That is the right kind of failure - a test that says what
the game is today.

Then pumpkin was removed. The only trace left is one line of comment in
`sorted_names()`, which is where it earned its place:

### Sorting StringNames does not sort them

The first fourth-crop run printed the seed list as
`[pumpkin, carrot, corn, wheat]` - out of a `.sort()`.

**GDScript compares a `StringName` by its internal pointer**, not by its text.
That is the point of the type and it is why it is fast. It also means every
`keys.sort()` in `src/core/` over id-keyed Dictionaries - twelve of them - was
ordering by the order the strings happened to be interned in, which is source
file order.

Stable within a build, and that is the worst kind of stable. Move two `const`
lines in `game_data.gd` and the rules iterate in a different order and the
determinism hash moves, for a diff that changed no behaviour. The house rule
says sort the keys; the code called `sort()` and satisfied the letter of it
while delivering none of the intent.

`state.gd:hash_of()` was doing it too, which means **the determinism guard was
hashing the layout of the source file** along with the state.

Fixed with `GameData.sorted_names()`, which sorts by `String(v)`, and every
StringName site routed through it. `hash_of()` sorts by `str(k)` instead,
because its keys are a mix of ints and names and it only needs a total order
that is the same on every build - "10" before "2" is fine, pointer order is
not.

One thing this broke on the way: `state["crafting"]` is keyed by **cell index**,
an int, and `sorted_names()` turned `42` into `&"42"` so the station lookup
missed and five crafting asserts failed. Plain `sort()` is correct there and
has a comment now saying which kind of key it is sorting. The lesson is the
familiar one in a new shape - a helper named for the common case gets applied
to the uncommon one.

There is an assert that `sorted_names` puts `apple` before `apple pie` before
`mango` before `zebra`, so nobody optimises it back into `.sort()`.

### Other notes

- **A new farm starts on carrot**, not wheat: `Farming.initial()` takes
  `seeds()[0]` rather than naming a crop, and carrot is both alphabetically
  first and the right default - it is the cheapest seed and the fastest
  feedback. This is the whole of the first sim hash move below; confirmed by
  putting wheat back temporarily and watching the hash return to the old
  number exactly.
- The 0018 group is about wheat, so it now **asks for wheat by name** instead
  of leaning on whatever the default happens to be.
- `Farming.select_seed()` is called straight from the HUD rather than going
  through `state["intent"]`, matching `Building.select()`. A selection has no
  rule to decide and no tick to wait for - it is a mode, not an action. The
  autoplayer of task 0067 calls the same function.
- The number keys are read as **keycodes, not named actions**. An action per
  crop would mean editing `project.godot` every time somebody adds a
  dictionary entry, which is the opposite of what this task is for. Task 0095
  rebinds the named actions; a hotbar stays positional.
- The strip shows **value per day**, not sale price, because sale price is the
  wrong pair of numbers to compare: corn sells for more than carrot and carrot
  is worth nearly three times as much per plot per day.

### Hashes

Two deliberate moves, in two steps.

| | from | to | why |
|---|---|---|---|
| sim hash | `721873783` | `431908473` | a new farm starts on carrot, not wheat |
| data hash | `1636540132` | `3327150656` | seed costs 3/6/4 -> 2/4/1 |
| sim hash | `431908473` | `670145679` | id-keyed Dictionaries now fold in text order |
| data hash | `3327150656` | `553378396` | same, for `GameData.digest()` |

`python tools/verify.py` prints PASS: 582 asserts, 163 input cases, 0 failed.
`exports` is still the one SKIP and still wants the Godot export templates.

## 0029 - Growth stages and watering - done 2026-09-27

A field you can read from across the farm, and one chore worth walking for.

**What changed.** All three crops have four drawn stages now, not just wheat.
Watering is a new verb on a growing plot: it wants water in hand, the can fills
by standing next to the pond or the new well, and a watered tile grows 35%
faster until the night dries it out. Holding the key and walking down a row
waters each tile once.

Files: `src/core/farming.gd`, `game_data.gd`, `interact.gd`, `player.gd`,
`phases.gd`, `farm.gd`, `sim.gd`, `src/ui/world_view.gd`, `day_hud.gd`,
`main.gd`, `tools/sprite_maps.py`, both test tools.
Verify: 640 headless / 177 input / both hashes moved on purpose, below.

### The levers were already there, as floats

`WATER_GROWTH_BONUS := 0.35` and `WATER_LASTS_UNTIL_NIGHT := true` had been
sitting in `game_data.gd` since the table was laid out, read by nothing, and
`digest()` already had a `"water"` key - which is how I found them: my own
duplicate lever collided with it and the parser said so.

The float had to go. `src/core/` is integer-only on purpose, and a growth rate
multiplied by 0.35 is the exact shape of a desync that shows up on one
machine. So the lever kept its name and became `35`, a percentage.

Applying a percentage per tick with integers is the only interesting part:
0.35 of a tick is not a number a plot can hold, and rounding it every tick
gives either a 100% bonus or none. Each watered plot banks
`WATER_GROWTH_BONUS` hundredths per tick and spends a whole tick whenever it
has one. Exact, integer throughout, and any percentage works - which is what
makes it a lever rather than a choice between two numbers. Measured: wheat
ripens at 1999 ticks watered against 2699 dry, and 2700/1.35 = 2000.

### Where the water comes from

The pond is eight rows south of the north field, so a range from open water
would never have reached the crops. The task asks for "the pond and the well"
and there was no well anywhere in the game, so one went into the farm map at
(10, 7), between the two fields, as a fixture that cannot be sold - a player
who sold their own well would have sold the only water north of the pond.

**The can fills by standing next to a source, with nothing pressed.** Two
reasons, and the second decided it:

- Filling a bucket is not a decision. Walking to the water is, and the carry
  limit is what makes you do it.
- A water tile already offers `fish` (task 0030). A tile that offered two
  verbs would make the player guess which key does which.

`WATER_CAN_CAPACITY` is 8, so the whole 48-plot field is six trips.

### An instant verb, and the thing that made it necessary

Every verb in the game stops the moment the player steps - right for a tree,
where half-chopped should not persist in some invisible ledger, and wrong for
a watering can. So `water` went on a new `Interact.INSTANT` list: it finishes
on the tick it starts, owns no action state, and `Player` completes it where
it stands whether or not the farmer is moving. A tile that has been watered
stops offering the verb, which is what makes a held key water each tile once
instead of emptying the can into the first one.

That was not enough on its own, and the input case is what caught it: **the
first attempt watered nothing at all.** `main.gd` writes `intent["interact"]`
on the *edge* of the key, because a job that has started repeats itself from
then on without the key being read again. An instant verb has no job to
repeat, so the edge fires once and the whole walk does nothing.

So the intent now carries both: `interact` is the edge that starts work, and
`interact_held` is the level, written every frame like `move` and never
consumed. Two fields because they genuinely mean two different things, and the
autoplayer of task 0067 will want the same two.

### The watchdog was a deadline, not a watchdog

Adding an eleventh input case made `input_check` fail with "a case never
finished" - on a suite where nothing was wrong. `WATCHDOG_SECONDS` was being
measured across the **whole run**, so every case ever added ate into it and the
eleventh one ran out of budget.

That is a false alarm that gets more likely with every task, and it would have
been blamed on whatever case happened to be last. `expect()` now puts the
timer back to zero, so it measures what it was always for - how long the run
has gone without a single assert landing - and does that as well with two
hundred cases as with eleven.

### Notes

- **Wet earth is drawn under the crop, not instead of it.** The first version
  swapped the tile art and a watered row vanished the moment it sprouted,
  which is a chore with no feedback - the player would be back to remembering
  which tiles they had done.
- Looked at the sprites as a contact sheet rather than trusting the maps.
  Caught corn's ready-stage cob running off the right edge of the tile; both
  cobs are inboard now. Carrot going green-to-orange at stage 3 is the clearest
  read of the three.
- `Farming` deliberately does **not** call `Player`. `Player` asks `Interact`,
  `Interact` asks `Farming`, and closing that ring is a cyclic reference; the
  four neighbour steps are spelled out locally and `Sim._tick_day()` is what
  passes the player's cell in for the refill.
- `WATER_LASTS_UNTIL_NIGHT` is honoured rather than assumed - `dry_out()`
  returns early if it is ever turned off.

### Hashes

Both moved on purpose.

| | from | to | why |
|---|---|---|---|
| sim hash | `670145679` | `569302775` | the state gained `water_can`, every plot gained `soak`, the intent gained `interact_held`, and the farm gained a well |
| data hash | `553378396` | `2916488539` | the farm map, `WATER_GROWTH_BONUS` 0.35 -> 35, and the can and the lifetime joining `digest()` |

`python tools/verify.py` prints PASS: 640 asserts, 177 input cases, 0 failed.
`exports` is still the one SKIP and still wants the Godot export templates.

**Follow-up worth a task:** the well is a fixture on the map. A *buildable*
well would make "where is my water" a placement decision on a bigger farm, and
`BUILDINGS` already has the shape for it. Not in the MVP unless the fields
move.

## 0030 - Fishing - done 2026-09-27

The pond earns its place: nothing to spend, everything to pay attention to.

**What changed.** New `src/core/fishing.gd`. Standing on the bank facing water
and pressing interact casts a line; a seeded wait later the float goes under
and there are 45 ticks to react; reeling inside that window lands a common or
a rare fish. Missing it costs the time and nothing else.

Files: `src/core/fishing.gd` (new), `interact.gd`, `state.gd`, `sim.gd`,
`game_data.gd`, `src/ui/day_hud.gd`, both test tools.
Verify: 686 headless / 192 input / sim hash moved on purpose, data hash
unchanged.

### One rod, and the draw happens at the cast

`state["fishing"]` is one cast or nothing - not a list. A farmer has one rod,
and the moment there are two lines in the water the player is doing something
else while they wait, which is exactly the attention the pond is charging for.
Other water offers nothing while a line is out, and there is an assert for it.

Both random decisions - **how long the wait is** and **whether it is the rare
one** - are drawn in `begin()`, at the cast. Drawing the fish at the reel
instead would mean a fast hand changed what was on the hook, and `rare_in`
would stop being a lever and start being a reflex prize. Thirty casts on one
seed produce an identical log to thirty casts on the same seed and a different
one to another, which is the done-when.

### Reeling is a press, watering is a hold

Task 0029 put `water` on `Interact.INSTANT`, firing off `interact_held` - the
level - so one held key waters a row while you walk. Reeling deliberately does
**not** go there. A player holding the key down while they wait would land
every fish without ever reacting to one, and reacting is the entire mechanic.
So `reel` takes the `interact` edge through the ordinary action path, and it
is on `ONE_SHOT`.

That the two verbs needed opposite treatment is the argument for having split
the edge from the level last task rather than overloading one field.

### Water asks, the way soil asks

`TERRAIN_VERBS` had `WATER: &"fish"` as a flat entry. It could not stay: what
the pond offers depends on whether there is a line in it and whether that line
is biting. So water now asks `Fishing.verb_at()` exactly as soil asks
`Farming.verb_at()`, `TERRAIN_VERBS` is empty, and the highlight says "reel"
at the one moment reeling does anything rather than "fish" at a pond that
already has a line in it.

`all_verbs()` was reading the two verb tables and therefore quietly listed
none of the farming verbs. It now includes the ones the two subsystems
produce, so task 0089's tooltip can find them.

### A bite you cannot see is not a reaction test

Task 0078 draws the float going under, and it is not written yet - which would
have left this task shipping a mechanic that is literally unplayable: a window
of a second and a half, opening with no signal at all.

So the day HUD says "waiting for a bite" quietly and "A BITE - PRESS SPACE"
loudly, in the middle of the screen under the farmer rather than in a corner,
because the player is looking at the water. It is deliberately plain and 0078
replaces it.

### Notes

- `check_fishing()` joins the other table checks: a window of zero ticks is a
  pond nobody can fish, a bite that comes sooner than it can is nonsense, and a
  rare fish worth no more than the common one is not a rare fish. All three
  have a teeth-test that builds the broken table and expects a complaint.
- **Walking away gives the cast up**, the same rule as every other job on the
  farm. Without it a player could cast, go mining, and come back to a fish that
  had waited all day. `Sim._tick_day()` passes the player's cell in, the same
  way it does for the watering can, because `Fishing` calling `Player` would
  close the `Player -> Interact -> Fishing` ring.
- The rare rate is asserted over 400 casts and allowed to land within half the
  expected count. Thirty casts gave 3 where 5 was expected, which is noise, not
  a bug - a tight assert on a small sample is a test that fails on Tuesdays.
- Ran `input_check` three times over: 192 cases, 0 failed, every time. The bite
  delay is deterministic from `BOOT_SEED`, so the reaction case is not a race.

### Hashes

| | from | to | why |
|---|---|---|---|
| sim hash | `569302775` | `3926216903` | the state gained `fishing` and `last_catch` |

The **data hash did not move**, which is right: this task added a `check_` for
the fishing table and turned no lever in it. The numbers were all set when the
table was laid out.

`python tools/verify.py` prints PASS: 686 asserts, 192 input cases, 0 failed.
`exports` is still the one SKIP and still wants the Godot export templates.

## 0031 - Iron from the rock face - done 2026-09-27

The resource that gates every tower, and the discovery that five of the map's
thirteen mining nodes had never been reachable.

**What changed.** Ore is now worse than stone on all three dials, the rock face
was redrawn so every node sits on a surface somebody can stand at, and there
are eight ore nodes instead of six. A day at the cliff is 16 iron; a gun tower
is 15.

Files: `src/core/game_data.gd`, `src/tools/headless_check.gd`.
Verify: 727 headless / 192 input / both hashes moved on purpose, below.

### The arithmetic

The task asks for a day's mining to buy roughly one tower and for the sums to
be here.

Where it started, ore and stone were the same swing and ore came back
**faster** than stone, which is backwards for the scarce resource:

|  | swing | swings | yield | back in |
|---|---|---|---|---|
| seam | 2s | 3 | 3 stone | 90s |
| ore | 2s | 3 | 1 iron | 60s |

What shipped:

|  | swing | swings | yield | back in |
|---|---|---|---|---|
| seam | 2s | 3 | 3 stone | 90s |
| ore | **3s** | 3 | 1 iron | **120s** |

Slower per swing, less per node, slower to return - all three, so the cliff is
a choice about what you came for rather than a place you leave with
everything.

Eight nodes, nine seconds of swinging each, a hundred and twenty to come back.
A node gives twice in a 240 second day - take it at 0, again at 129 - so the
cliff is worth **16 iron**. A gun tower is 15 iron and 10 wood. That is the
whole design of the resource: a day at the rock face is a tower.

**And the cliff is regrowth-bound, not swing-bound**, which I did not expect
and which is the more useful fact. Measured, by mining a whole day three ways:

    tight route (no walking)      16 iron
    strolling (1.5s a node)       16 iron
    a deliberately bad route      12 iron

Sixteen harvests take 144 seconds of swinging out of 240, so the other 96 are
spent waiting for nodes to come back - and any walk shorter than about three
seconds a node disappears into that waiting. The consequence: `regrow_ticks`
is the real dial on iron, and the 96 idle seconds are exactly the window the
farm is meant to fill. Mine the cliff, farm while it regrows. That is the loop
the game wants and it fell out of the numbers rather than being arranged.

Both the strolling and the bad route are asserted, so the boundary is
documented rather than folklore.

### Five seams that were never in the game

Redrawing the cliff, I checked that a farmer could stand next to each node -
and **the five stone seams could not be reached, and never could**. They were
drawn inside the `#` block, walled in on all four sides by unwalkable rock,
from the day the map was written in task 0003 until now.

Thirty tasks of asserts never caught it. They all did the same thing:

    Farm.cells_with(state, &"seam")[0]   ->  "a seam offers mining"

which is perfectly true, and perfectly useless, from a cell no player can get
to. The test fetched the node by id and asked what it offered; nobody asked
whether anybody could get there. Same shape as the ore-regrowth bug of task
0017 - a test that certifies the easy instance certifies the easy instance.

So the walk is a check now. `check_reachable()` runs over every occupant in
`GATHERING` and refuses any that has no walkable orthogonal neighbour, with a
teeth-test that buries an ore node in cliff and expects a complaint.

The cliff was redrawn as a solid block with the nodes on its faces: stone down
the west side, iron down the east side and along the bottom. It reads better
than the scattered version too - you mine the exposed rock.

    20        27
     S######o
     S######o
     S######o
     S######o
     S######o
     #####ooo

Three ore nodes that were sitting on their own in open ground - (30,6), (26,7)
and (29,9) - were removed. "Iron comes only from the rock face region" is a
requirement, and a lone ore tile in the middle of the lawn is iron with no walk
attached.

**Seven border trees** were walled in by other trees as well. Rather than
exempt them and weaken the rule, a single-cell gap was opened beside each. One
scare on the way: the first fixup script was scoped to every occupant and
punched a hole in the farmhouse, whose interior cells legitimately have no
walkable neighbour. Restored, and the check is scoped to `GATHERING` - which it
already was; only the throwaway script was too greedy.

### Notes

- Two map-count asserts were restated as counts off the map rather than
  literals: the border wood and the loose boulders are scenery and move when
  the map does. The **ore count stayed a literal 8 with a comment saying why**
  - it is load-bearing, because the day's iron is computed from it, so a node
  added or removed is a balance change and should fail a test.
- Clearing the cliff into the rock face cost two loose boulders, 7 down to 5.
  Loose rock does not regrow, so it is a small nerf to day-one stone; seams
  give stone for ever and 5 boulders is still more than a wall.
- "Iron is not sellable at a profit against what a tower costs" is asserted
  directly: a tower's worth of iron sells for $105 and costs $270 to buy back
  at the stall's markup. Mining stays the way you get iron.
- `Array.sort()` on an untyped array literal makes its loop variable a Variant
  and `cell + step` stops being a `Vector2i` - the parse error that cost two
  runs here. There is a typed `GameData.NEIGHBOUR_STEPS` now.

### Hashes

| | from | to | why |
|---|---|---|---|
| sim hash | `3926216903` | `485801538` | the farm map: the cliff redrawn, 8 ore instead of 6, three strays and two boulders gone, eight gaps in the border wood |
| data hash | `2916488539` | `135663565` | the same map, plus ore's swing 2s -> 3s and regrowth 60s -> 120s |

`python tools/verify.py` prints PASS: 727 asserts, 192 input cases, 0 failed.
`exports` is still the one SKIP and still wants the Godot export templates.

## 0032 - Oil - done 2026-09-27

The first resource that costs a building, which meant first making it possible
to build one.

**What changed.** Build mode can place the production buildings, not only the
defences, and honours their footprints. The press is 2x2, costs 25 wood and 5
iron, and turns corn or fish into oil. Oil is now the dearest thing in the
ledger, and a flamethrower's ten drops of it are $260 if you sell them instead.

Files: `src/core/building.gd`, `crafting.gd`, `interact.gd`, `game_data.gd`,
`src/ui/world_view.gd`, `build_mode.gd`, `tools/sprite_maps.py`, both test
tools.
Verify: 797 headless / 222 input / both hashes moved on purpose, below.

### The press could be built and then stood next to uselessly

Three things were missing and none of them was the recipe - `press_oil` has
been in the table since task 0003.

1. **`Building` was hardwired to `DEFENCES`** in ten places, so a press could
   never go on the farm at all. It now reads either table through `entry_of()`,
   and `BUILDINGS` falls out of the night rule for free: nothing in there
   carries `placeable_at_night`, so a press is a day job without that being
   spelled out anywhere.
2. **Footprints.** A press is 2x2. Placing writes the occupant to all four
   cells with an `anchor` on each, `why_not()` checks every cell so a press
   cannot hang off the edge, and a failed placement takes back whatever went
   down and refunds - half a press is worse than none. This is not a new idea
   in this codebase: the farmhouse has been nine cells of `{"id": "house"}`
   since the map was drawn. It is only a placeable one now.
3. **`OCCUPANT_VERBS` named the workshop.** So the press and the kitchen
   offered nothing when you stood at them. Any station with a recipe now
   offers `craft`, which also unblocks task 0034's kitchen.

`selected_recipe` was a single id, which worked while the workshop was the
only station you could reach. It is a Dictionary keyed by station now, built
from the recipe table so a new station arrives already selected, and
`start_at()` resolves the **anchor** - four corners of one press are one press,
not four, and there is an assert that the other three corners take no more
corn.

### The arithmetic

Four corn is $20 of crop. Pressing it was twenty seconds of work for one oil
worth **$10** - the press destroyed half the value of everything put into it.

That is not the tension the task asks for. "Sell it or keep it" is only a
decision if selling is a real option; at $10 you kept the oil because selling
it was strictly worse, which is not a choice, it is an absence of one.

So oil went to **$26** and gunpowder, which is made from it, to **$22**:

| recipe | in | out |
|---|---|---|
| press_oil | 4 corn, $20 | 1 oil, $26 |
| press_fish_oil | 3 fish, $24 | 1 oil, $26 |
| make_gunpowder | 2 corn + 1 oil, $36 | 2 gunpowder, $44 |
| cook_fish | 1 fish + 1 carrot, $11 | 3 food, $36 |

Oil is now the dearest single thing on the farm, which the task asks for
directly, and a flamethrower's ten oil is **$260** on the stall - against a
night's base reward of $20. That is the temptation, and it is asserted.

The fish route is deliberately the worse deal: three fish is $24 against corn's
$20, and a fish is worth more cooked than pressed. It is the day you have a
good pond and a bad field, not the route.

`check_chain()` now refuses any recipe whose output sells for less than its
inputs. **Its first version had a bug the teeth-test caught**: `_worth()` read
`SELL_PRICE` directly instead of the price list it was handed, so the check
looked at the real table while the test handed it a rigged one, and passed by
agreeing with itself. The price list is a parameter now.

### The build palette did not fit on the screen

Making four buildings placeable took the palette from eight rows to twelve, and
`input_check` said "clicking press selects auto_crossbow".

It was not the click. The palette was **327 pixels tall on a 270 pixel
screen** - the press row sat at y=294, below the bottom edge, and could not be
clicked by anybody. A default `Button` reserves about twenty pixels whatever
`ROW_HEIGHT` says, and `VBoxContainer` adds four more between each. Rows now
carry their own compact styleboxes, the separation is zero, and the panel is
255 -> 187 tall.

There is an assert that every row of the palette is on the screen, so the next
task that adds a defence is told rather than finding out.

A second, quieter bug was found on the way: `_build_palette()` called
`queue_free()` on the old rows without removing them from the tree first.
`queue_free` is deferred, so for one frame the container laid out both sets and
every row sat somewhere it was not drawn. Harmless at eight rows. Fixed.

### Notes

- The press is drawn as one 32x32 picture split into four quarters by the
  generator, rather than four sprites authored separately - much easier to get
  a beam and a screw to line up across a tile boundary. `world_view` asks for
  `press_0_0` and falls back to `press` and then to a flat block, so a building
  whose quarters nobody has drawn is visible before it is pretty.
- Looked at the assembled press rather than trusting the ASCII. The first one
  read as an archway: two feet with a gap between them. Redrawn with a solid
  stone basin, a timber beam and an oil spout.
- The test case's first spot for the press was underneath the build panel,
  where the click never reaches the farm. It places east of the panel now, and
  says why.

### Hashes

| | from | to | why |
|---|---|---|---|
| sim hash | `485801538` | `680464820` | `selected_recipe` went from one id to one per station |
| data hash | `135663565` | `3582057941` | oil $10 -> $26, gunpowder $14 -> $22, and the `press_fish_oil` recipe |

`python tools/verify.py` prints PASS: 797 asserts, 222 input cases, 0 failed.
`exports` is still the one SKIP and still wants the Godot export templates.

**Follow-up:** task 0033's generator and 0034's kitchen are both `BUILDINGS`
entries, so both are now placeable and workable without further plumbing. The
`energy_draw` on the press is still data only - 0033 owns it.

## 0033 - The generator and energy - done 2026-09-27

Energy, and the farm that slows down rather than switching off.

**What changed.** New `src/core/power.gd`. Everything placed on the farm draws
energy while it runs; the farm supplies a trickle of its own and a generator
burns oil for more. Draw more than you make and **everything slows together**,
in proportion, with a floor - a tower reloads more slowly, the press takes
longer, and nothing ever stops.

Files: `src/core/power.gd` (new), `game_data.gd`, `state.gd`, `sim.gd`,
`towers.gd`, `crafting.gd`, `src/ui/day_hud.gd`, `tools/sprite_maps.py`, both
test tools.
Verify: 839 headless / 237 input / both hashes moved on purpose, below.

### A rate, not a stockpile

There is no energy in the ledger and there never will be. `Power.tick()`
recomputes supply and draw and turns them into a **percentage**, and the whole
of the rest of the game touches it through one function:

    Power.scaled_ticks(state, ticks)  ->  ticks * 100 / percent

At full power that hands back exactly what it was given, which is why nothing
measured before this file existed moved by a tick. A tower asks it how long to
reload and the press asks it how long a batch takes; neither knows what a
generator is.

Two call sites, and the difference between them is deliberate:

- **A tower asks after every shot**, so a generator running dry half way
  through a night slows the guns from the next shot rather than the next night.
- **The press asks when a batch starts.** A brown-out does not lengthen work
  already committed - the corn is in the hopper.

### `BROWNOUT_RATE` was already there, and was a float

`const BROWNOUT_RATE := 0.5` had been in `game_data.gd` since the table was
written, read by nothing, with `digest()` already carrying a `"power"` key -
which is how I found it, the same way as `WATER_GROWTH_BONUS` in task 0029:
my own duplicate lever collided with it and the parser said so.

It became `UNPOWERED_PERCENT := 25`, an integer, because a float in `src/core/`
is a desync waiting for a machine that rounds differently. Twenty-five rather
than fifty because of the other new lever:

### The farm has a trickle of its own

`BASE_ENERGY := 4`. Without it, the first press on day one would draw two
against a supply of nothing and grind at the floor until the player built a
generator - which burns oil, which comes out of the press. Not a deadlock, but
an hour of wondering what is wrong.

Four is the press and a tower or two. Past that the farm has grown beyond its
own means, which is exactly when a generator should be the answer. Measured:

    4 gun towers on 4 supply   100%   reload 30 ticks
    5 gun towers on 4 supply    80%   reload 37 ticks
    12 auto-crossbows           25%   reload 120 ticks - the floor, not a stop

`fuel_every_ticks` went from 30 seconds to 60: a full day and night of running
is five or six oil against the twelve a press can make in a day. Expensive
enough to be a decision, cheap enough that the answer is sometimes yes.

A generator **burns nothing when nothing is drawing**. There is no tank for the
energy to go into, so a generator idling on an empty farm would be the player
paying oil for nothing. It also burns nothing during the build phase, where the
clock does not run.

### It tripled the test suite, and the fix was the flow field's

`Power.tick()` runs at 30Hz through every day and every night, and the first
version scanned and sorted the whole occupant table twice per tick - once for
the draw and once to find the generators. `headless_check` went from 18 seconds
to **51**.

The farm's draw only changes when something goes up or comes down, which is
exactly what `grid_version` counts. Both lists are cached against it now and
the suite is back to 18 seconds. Same fix and same reason as the flow field in
task 0025: ask what changed, not what is. Worth writing down that the
performance regression showed up in the wall clock of the test run rather than
in any assert - task 0102 owns the budget, but a 3x slowdown compounds, and
the cheapest time to fix it is the hour it appears.

### The power line outlives the day

The HUD requirement is "supply against draw", and the day HUD hides itself when
the day ends - which is precisely backwards for this number, because towers
draw at night and a generator running dry mid-wave is the one moment a player
most needs to be told.

So `DayHud` stays up and hides its **contents** instead. The power line is the
one child left showing after dark. Three existing asserts were asking
`hud.visible` and meaning "is the day's chrome up", so they got
`DayHud.shows_day()`, which is the question they were actually asking.

### The done-whens

- **Building one too many visibly slows everything rather than stopping it** -
  five gun towers on four supply is 80%, and a 30-tick reload becomes 37.
  Twelve auto-crossbows is the 25% floor and still fires.
- **Running out of fuel mid-night degrades the defence and the night still
  resolves** - driven end to end on one drop of oil: dark at tick 1799 (a
  minute, exactly what the lever says), 203 shots fired after that, night
  survived and settled to a payout. Night one had to be swapped for night
  eight: night one is over in forty seconds and a drop of oil lasts a minute,
  so the generator outlived the wave and there was no brown-out to watch.

### Notes

- The generator is drawn as one 32x32 split into quarters, like the press: a
  stone housing with a lit burner in the middle, a stack and a cable. Looked at
  it assembled rather than trusting the ASCII.
- `_total_draw` skips the generator itself and counts a multi-tile building
  once, by anchor - four cells of one press are one press.

### Hashes

| | from | to | why |
|---|---|---|---|
| sim hash | `680464820` | `3918087068` | the state gained `power`: supply, draw, percent, the burn timers and the two caches |
| data hash | `3582057941` | `1017850053` | `BASE_ENERGY` is new, `BROWNOUT_RATE` 0.5 became `UNPOWERED_PERCENT` 25, and the generator burns a drop a minute instead of every thirty seconds |

`python tools/verify.py` prints PASS: 839 asserts, 237 input cases, 0 failed.
`exports` is still the one SKIP and still wants the Godot export templates.

## 0034 - Cooking: food and meat - done 2026-09-27

The kitchen, the animals meat has to come from, and somewhere for food to go
other than the stall.

**What changed.** Two new core files: `livestock.gd` and `repair.gd`. A cow and
two chickens stand on the grass and slowly have something worth collecting; the
kitchen turns crops, fish and meat into food; and food can now be spent putting
hit points back, through the ledger.

Files: `src/core/livestock.gd` (new), `repair.gd` (new), `game_data.gd`,
`interact.gd`, `state.gd`, `sim.gd`, `tools/sprite_maps.py`, both test tools.
Verify: 893 headless / 247 input / both hashes moved on purpose, below.

### Nothing in the world made any meat

`MEAT` has been in the resource table with a price of $9 since task 0003, and
`cook_roast` has wanted one since the same day. **Nothing produced a single
unit of it for thirty-three tasks.** The recipe was unreachable and no check
said so, because every table checked its own contents and none of them asked
whether a resource anybody wanted could actually be got.

`check_livestock()` asks that now - it refuses a farm where nothing produces
meat, and a recipe that wants a resource nothing makes.

The answer was on the reference sheet the whole time: a chicken and a cow,
loose on the grass, not penned. So that is what went on the map, south-west of
the house where the sheet has them.

### A trickle, and what "passive" was taken to mean

The task says to keep it to a passive trickle and not an animal husbandry
system. Passive was read as **nothing to manage**: no feed, no water, no
breeding, no happiness, no shelter. An animal stands there and accumulates.

What it was *not* read as is "arrives in the ledger without you". The player
walks over and collects, because that is the same bargain as every other thing
on this farm - it happens while you are elsewhere and comes to nothing if you
never come back - and because an animal that paid out automatically would be
wallpaper with a number attached.

`holds` is what keeps it a trickle rather than idle income: a full animal
**stops**. A cow nobody visits does not bank a fortnight of beef.

    cow       1 meat every 80s, holds 2
    chicken   1 meat every 50s, holds 1

Both are asleep at night, like the rest of the farm.

`_animals()` is cached against `grid_version` from the start rather than after
a profiling scare - task 0033 paid that tuition already.

### The margins

The done-when asks for a dish to sell for more than its inputs, with the
margin stated. Measured, printed by the suite:

| dish | inputs | food out | margin |
|---|---|---|---|
| cook_meal | 2 carrot + 1 wheat, $10 | 2 food, $24 | **+$14 (240%)** |
| cook_fish | 1 fish + 1 carrot, $11 | 3 food, $36 | **+$25 (327%)** |
| cook_roast | 1 meat + 1 corn, $14 | 4 food, $48 | **+$34 (342%)** |

These were already true - `check_chain()` from task 0032 has been enforcing
"a recipe gains value" across the whole table since it was written, and the
kitchen passes it the same way the press does. What 0034 adds is that the
kitchen can now be built and stood at, which task 0032's generic station verb
made possible, and that meat exists.

### What food is for

Until this task, food was a thing you cooked and then sold, which made the
kitchen a money press with a thematic hat on. `design.md`'s resource table
calls it the night's repair and heal currency, and `REPAIR_COST_PER_HP` has
been sitting in `game_data.gd` - `{food: 1, wood: 1}` - read by nothing.

`repair.gd` is the **ledger path** and deliberately nothing more: what a hit
point costs, how many the larder can cover, and taking them. It knows nothing
about where the player is standing.

**Task 0053 owns the night interaction** - being near the thing, taking time
over it, being interrupted, the worse rate for the house - and there is a
`REPAIR_TICKS_PER_HP` lever already in the table waiting for it. Splitting it
this way is what lets 0034's done-when ("food spent on repair during a night is
taken through the ledger") be true and tested now without 0034 quietly doing
0053's job.

All or nothing per hit point: `max_affordable()` works out what the ledger can
cover before anything is spent, so there is no way to end up with half a hit
point paid for. Asserted: an empty larder buys no repair and takes nothing for
trying; a whole house cannot be repaired; a house is never mended past whole.

### Notes

- **Looked at the reference sheet properly**, which I should have been doing
  on the art tasks before this one. It settled the animals (loose, not penned),
  confirmed the well from task 0029, and showed meat as a red steak.
- The cow's first draft was a white box on legs - the patches were
  `bone_dark`, a shade away from `bone`. Redrawn with `ink_soft` patches, dark
  ears and a red eye, and it reads as a cow next to the chicken now.
- One input assert was wrong about the engine rather than the game:
  `Player.target()` returns the cell ahead whatever is on it, so "an empty
  chicken is not a target" was never going to be true. The assert that matters
  is that it offers no verb and a held key takes nothing, which is what it says
  now.
- `digest()` already had a `"repair"` key, so my duplicate collided. Third
  time this session - `WATER_GROWTH_BONUS` in 0029, `BROWNOUT_RATE` in 0033,
  and now this. The table was laid out with the whole game in it and the
  backlog keeps catching up to it.

### Hashes

| | from | to | why |
|---|---|---|---|
| sim hash | `3918087068` | `2650491902` | the state gained `livestock`, and the farm gained a cow and two chickens |
| data hash | `1017850053` | `3799311961` | the `LIVESTOCK` table is new and it is in `digest()`, and so are the three animals on the map |

`python tools/verify.py` prints PASS: 893 asserts, 247 input cases, 0 failed.
`exports` is still the one SKIP and still wants the Godot export templates.

## 0035 - Gunpowder and ammunition - done 2026-09-27

Towers that consume something, and a farm where what you made today decides
what tonight can do.

**What changed.** New `src/core/ammo.gd`. Incendiary rounds are a resource and
a recipe; the flamethrower burns them instead of raw oil; mortars draw
gunpowder from a shared pool in the ledger; and a tower with an empty pool
keeps shooting, slower and weaker.

Files: `src/core/ammo.gd` (new), `game_data.gd`, `towers.gd`,
`src/ui/day_hud.gd`, both test tools.
Verify: 947 headless / 256 input / both hashes moved on purpose, below.

### The flamethrower was burning money

`design.md` section 5 names the recipe exactly - "Oleo + Madeira -> Municao
incendiaria" - and the flamethrower's data declared `ammo: {OIL: 1}` every two
seconds. Oil is $26 since task 0032, so forty-five ticks of flame across one
night is **eleven hundred dollars of fuel**, burning the single most valuable
thing on the farm straight out of the tank.

So `INCENDIARY` is a resource now, `make_incendiary` turns 1 oil and 2 wood
into 4 rounds, and the flamethrower burns those. The same burst costs **$30 of
goods instead of $104 of raw oil**, and the margin on the recipe is thin on
purpose: rounds are for burning, not for selling.

### One pool, in the ledger

There is no magazine per tower and there will not be one. Ammunition is a
resource held in `state["resources"]`, which buys three things the task asks
for without a line of code each:

- **What is left carries into the next night**, because nothing clears it.
- **Towers compete for it.** Six mortars drain the pool six times as fast, so
  how many you build is a question about supply and not only about money.
- It shows up in the inventory, the shop and on the HUD for free, because
  those already know what a resource is.

### Out of ammunition is a worse tower, never a dead one

A silent tower is a tower the player stops looking at. An empty mortar still
lobs something: `EMPTY_RELOAD_PERCENT` (300) longer between shots,
`EMPTY_DAMAGE_PERCENT` (30) of the damage, plain impact, and none of what made
it a mortar - no splash. A tower that cannot reach for powder is throwing a
rock.

### The done-whens, measured

The same seed, the same six towers, the same night seven, the same generator
with oil so that energy is not the variable. The only difference is the pool:

| | killed | house | mortar shots |
|---|---|---|---|
| 60 rounds | 28 | **100 / 100** | 22 |
| no rounds | 26 | **82 / 100** | 17 |

Survivable, and clearly worse. And the drain is exactly what the table claims:
**22 rounds for 22 mortar shots**, with the 63 gun-tower shots in the same
night costing nothing at all.

### Three goes at a test that could tell the two cases apart

Worth writing down, because each failure was the test being wrong about the
game rather than the game being wrong:

1. **Zero shots for fifteen rounds spent.** I was counting
   `Towers.in_flight()` rising between ticks, which misses a shot created and
   resolved inside one tick - at a mortar's range, most of them. Counted off
   `next_projectile_id`, which only ever goes up.
2. **Seventy-two shots and zero rounds.** A mortar *costs* fifteen gunpowder
   to build. The helper granted wood, iron, stone and oil, placed no mortars
   at all, and reported what three gun towers look like. There is an assert now
   that the scripted night has the towers it thinks it has.
3. **With powder and without came out identical.** Night three, and the gun
   towers held it alone without the house being touched. A comparison that
   cannot distinguish the two cases is not a test of anything. Night seven, two
   guns and four mortars.

Along the way, "one round per shot" turned out to be the wrong invariant
entirely: a gun tower fires for free, so rounds spent equals *mortar* shots,
not shots. Counted per kind now.

### Notes

- `check_ammo()` refuses a tower that fires something no recipe makes. Exactly
  the meat bug of task 0034 one table along - a tower may declare it fires
  anything, and a tower whose ammunition cannot be made would be permanently
  on its weak shot with nothing in the game to say why.
- The `thirteen resources` assert became a **named** list instead of a count.
  A count fails when the game grows and tells you nothing: this one reported
  "14". The twelve things on the reference sheet's panel have to exist; carrot
  and incendiary are not on that panel and are not listed. The sheet is a
  floor, not a ceiling.
- The ammunition line sits under the power line and stays up after dark for
  the same reason: a mortar running dry mid-wave is something the player has
  to be able to watch happen.
- One self-inflicted scare: a botched edit left `projectile_tiles_per_second`
  in the crossbow twice, which is a parse error in GDScript. Caught by the
  parse row before anything else ran.

### Hashes

| | from | to | why |
|---|---|---|---|
| sim hash | `2650491902` | `3087806628` | projectiles carry whether they were armed, and the towers now spend from the pool |
| data hash | `3799311961` | `4237661147` | `INCENDIARY` and its price, the `make_incendiary` recipe, the flamethrower's ammunition, and the two empty-pool levers |

`python tools/verify.py` prints PASS: 947 asserts, 256 input cases, 0 failed.
`exports` is still the one SKIP and still wants the Godot export templates.

## 0036 - The inventory - done 2026-09-27

Somewhere to see all fourteen resources, which a 480 pixel top bar cannot do.

**What changed.** New `src/core/inventory.gd` and `src/ui/inventory_panel.gd`,
and a `RESOURCE_GROUPS` table read off the reference sheet. `I` opens a panel
listing every resource with its amount and its price, grouped, and the day
carries on behind it.

Files: `src/core/inventory.gd` (new), `src/ui/inventory_panel.gd` (new),
`game_data.gd`, `scenes/Main.tscn`, `project.godot`, `src/ui/main.gd`, both
test tools.
Verify: 1033 headless / 293 input / **sim hash unchanged**, data hash moved.

### It holds nothing

There is no inventory in the state and there is not going to be one. Every
function in `inventory.gd` is a question about `state["resources"]` answered on
the spot. A panel with its own totals is a panel that can disagree with the
ledger, and the number the player believes is the one on screen.

There is an assert that `state` has no `"inventory"` key at all, which is the
bluntest way to say it.

**Why it is in `src/core/` when it draws nothing:** what is shown and in what
order is a rule, not a decoration. It has to be the same on every machine and
derived from `GameData` rather than typed into a panel - which is also what
makes the second done-when true rather than hopeful.

### Grouped off the sheet

`docs/reference-sheet.png` lays its resource panel out in two rows of six -
wood, stone, iron, food, fish, oil, then wheat, corn, meat, gunpowder, money,
energy. Not alphabetical and not arbitrary: what you gather, then what you grow
and what you make of it. Named:

    materials   wood, stone, iron
    larder      food, fish, meat
    crops       wheat, corn, carrot
    workshop    oil, gunpowder, incendiary
    the farm    money, energy

Carrot and incendiary are not on the sheet's panel and sit with their own kind.

### Adding a resource makes it appear - checked, not claimed

Done-when says so, so it was done rather than reasoned about. An `amber` was
added to `RESOURCES` and `SELL_PRICE` and **deliberately to no group**, and
nothing else was touched:

    before   14 rows in 5 groups
    after    15 rows in 6 groups: ... and "other"

No UI edit, no grouping edit. `Inventory.groups()` sweeps whatever is in no
group into `GROUP_OTHER` rather than dropping it, so forgetting the grouping
table is a cosmetic mistake and never an invisible resource.

One assert failed during the experiment - "everything the game ships with has
a group" - which is the assert doing its job rather than a bug. Amber was then
removed.

### Notes

- **The day does not stop.** `design.md` calls the farm the cozy half, and a
  panel that paused the clock would make checking your stores a free action and
  reading the HUD a chore you do instead. It also does not set
  `state["open_panel"]` the way the stall does, so the farmer can walk with it
  open - there is nothing in it to click, so there is nothing to steal.
- **Blank, not `$0`**, for money and energy. Money does not sell for money and
  energy is a rate rather than a thing in a sack; "$0" reads as worthless,
  which is a different claim from "not for sale".
- A resource you have none of still gets a row. A thing you have none of is a
  thing you can go and get, and a list that grew as you got richer would teach
  nothing about where to go.
- `_build()` takes rows out of the tree before freeing them, which is the bug
  task 0032 found in the build palette. Written that way from the start here.
- `check_groups()` refuses a resource in two groups or a group naming
  something that is not a resource, both with teeth-tests.

### Hashes

| | from | to | why |
|---|---|---|---|
| sim hash | `3087806628` | unchanged | **as it should be.** This task added a view; a view-layer task that moved the sim hash would mean something in `src/ui/` was writing to the state |
| data hash | `4237661147` | `2144055300` | `RESOURCE_GROUPS` is new and is in `digest()` |

The grouping is presentation rather than balance, so it is worth saying why it
is in the digest at all: it is data in `game_data.gd` that `src/core/` reads
and that the asserts depend on the order of, and `digest()` already covers the
farm map and the resource list for the same reason.

`python tools/verify.py` prints PASS: 1033 asserts, 293 input cases, 0 failed.
`exports` is still the one SKIP and still wants the Godot export templates.

## 0037 - The workshop queue - done 2026-09-27

Semi-idle in one feature - and, on the way, the discovery that the sim hash
was guarding almost nothing.

**What changed.** `state["crafting"]` holds a list per station instead of one
job. Queuing is free, the inputs go in when an item reaches the front, and a
new `WorkshopPanel` appears when the farmer stands at a bench and counts down
what it is making.

Files: `src/core/crafting.gd`, `src/ui/workshop_panel.gd` (new),
`src/tools/determinism.gd`, `scenes/Main.tscn`, `src/ui/main.gd`, both test
tools.
Verify: 1080 headless / 308 input / sim hash moved on purpose, below.

### Queuing is free; starting is not

The two requirements read like a contradiction - "inputs are taken when an
item starts, not when it is queued" and "cancelling a queued item that has not
started refunds it in full" - and are not. An item that has not started has
had nothing spent on it, so removing it gives back everything it cost, which
is nothing. The item at the **front** has the wood in it already, and that
wood does not come back. That is what keeps stopping a decision rather than a
free undo.

The arrangement buys one more thing that was not asked for and matters: **a
queue that cannot be paid for waits.** Line up five barricades with an empty
larder and the front one retries every tick, so a player can queue and then go
and fetch the wood. Throwing the item away for being early would make the
queue a thing you only dare use after gathering, which is the opposite of
semi-idle.

That did change an assert from task 0019, which said a job you could not
afford must be refused. It now says the new rule, and checks the whole of it:
queuing is allowed, nothing is taken, the front item stalls, and the wood
arriving starts it.

### The sim hash was guarding almost nothing

Rewriting crafting from one job per station into a queue moved the sim hash by
**zero digits**. That is not reassurance.

Two separate holes, and both are worth writing down because the guard is what
every other task leans on:

**1. The scenario never had the player do anything.** `determinism.gd` created
a state and advanced it through the phases. That covers everything that ticks
on its own - waves, animals, power, regrowth - and covers none of the systems
that need somebody to press a key. Crafting, planting, building and fishing
were all outside it. The file's own documentation invited the fix ("when a
system needs setting up to be exercised, the setup goes here"), so the farmer
now plants nine tiles of three crops, waters four of them, queues three items
at the workshop, puts up two gun towers and casts a line before the clock
starts.

**2. The hash was taken at the end.** With the setup added, I deliberately
broke crafting - made the queue advance twice as fast - and the hash *still*
did not move: twenty thousand ticks is long enough for the queue to finish
either way, and three kits are three kits whether they took ten seconds or
twenty. **A guard on the final state cannot see a change in timing**, which is
most of what the rules are.

SIM is a rolling fold now, sampling the whole state every 250 ticks. Re-tested
the same deliberate break: `1766805932` correct against `1503858902` broken,
with DATA correctly unchanged because nothing in the tables moved. The guard
has teeth.

Everything from here on is measured against a scenario that plays the game
rather than watching it, so more tasks will move this number - which is the
point. A guard that never fires is not guarding.

### The panel

There is no key for it. Standing at a workshop, a press or a kitchen is what
opens it, because a key would be one more thing to remember for information
the player has already walked over to get. The front item gets a name and a
countdown, everything behind it gets a line, clicking a recipe queues it and
clicking a queued item takes it off.

The countdown updates every frame while the rows only rebuild when the queue
changes - a timer that only moved when the queue moved would be a timer that
stood still.

### Notes

- `start()` kept its name and now queues, because it is what `Interact` calls
  and what every test since task 0019 says. `cancel()` still cancels what is
  running; `cancel_at()` and `cancel_all()` are the new ones.
- One assert of mine was wrong in the ordinary way: it compared wood against
  `200` after gaining 200 on top of the starting stock. Measures the delta now.

### Hashes

| | from | to | why |
|---|---|---|---|
| sim hash | `3087806628` | `1766805932` | the scenario now plants, queues, builds and fishes, and the number is a rolling fold over the run rather than the state at the end |
| data hash | `2144055300` | unchanged | no table moved: the queue is a rules change and `QUEUE_LENGTH` was already there |

`python tools/verify.py` prints PASS: 1080 asserts, 308 input cases, 0 failed.
`exports` is still the one SKIP and still wants the Godot export templates.

## 0038 - Production runs while you are elsewhere - done 2026-09-27

Mostly an audit, and the audit is the deliverable: the farm does not care
where you are standing, and now there is a test that says so rather than a
reading of the code that hopes so.

**What changed.** `Crafting` keeps a record of what each station has ever
delivered, the workshop panel reports the difference when you walk back up to
a bench, and there are two measurements: a day run twice with the farmer
parked in two places, and the tick cost of a farm with 237 towers on it.

Files: `src/core/crafting.gd`, `src/ui/workshop_panel.gd`, both test tools.
Verify: 1099 headless / 314 input / sim hash moved on purpose, below.

### Measured, not read

"No system may depend on being on screen - find and remove any that does" is
the sort of requirement that is easy to satisfy by reading the code and
declaring it fine. So instead: **the same scripted day, run twice**, with the
farmer parked at the pond and parked at the bench, doing nothing at all in
either case. Nine tiles sown, three items queued at the workshop, a press
running, the animals standing there.

Every number came out identical - 3 kits, 3 oil, 29700 ticks of crop growth,
4 meat waiting - and so did **a hash of the entire state**, with four keys
excluded:

    player      the farmer themselves
    intent      what they are pressing
    water_can   fills by standing next to water (task 0029)
    fishing     a line, given up by walking away (task 0030)

That list is the complete set of things in this game that care where the
player is, and each one is deliberate. **Nothing that produces anything is on
it.** Hashing the farm rather than comparing half a dozen counters is what
makes this a real answer: it says every byte came out the same, including
things nobody thought to count.

The first version of the assert compared the *whole* state hash and failed,
correctly - a farmer at the pond is not a farmer at the bench. That failure
was the test being imprecise about its own claim, and fixing it is what
produced the list above.

### The tick budget

A farm with **237 gun towers**, every soil tile planted, a generator, and
night ten's waves walking in: **189 microseconds a tick**, which is one
percent of the 33 milliseconds that 30Hz allows.

Task 0102 owns tuning this. What is asserted here is a wide margin - under
half the budget - and the real number is printed either way, so a regression
shows up in the log before it is a failure. That is the lesson of task 0026:
a wall-clock assert with a tight bound fails on a busy machine and teaches
nothing.

One correction on the way: the first version printed the zombie count *before*
advancing, which is always zero because the waves have not started. A number
in a log that is not the number being measured is worse than no number.

### Coming back to something better

`design.md` section 13 promises the semi-idle loop, and a bench that silently
went from three queued to three kits in the pile would be the same event with
none of the telling. `state["produced"]` is a running tally per station,
deliberately kept apart from `state["crafting"]` because that entry is erased
the moment a queue empties - and "what happened while you were away" is
exactly the question you ask when the queue has finished.

The panel remembers what it last showed for each bench and reports the
difference: *while you were away: 2 barricade_kit*. **That memory is the
panel's, not the game's** - the running total is state, but what this
particular screen has already told this particular player is a fact about the
screen.

The first version never showed the line at all. It decided "have I been here
before" by asking whether the remembered tally was empty, which is also what a
first visit to a bench that has made nothing looks like - so every visit was
a first visit. It asks whether the bench has an entry at all now.

### Hashes

| | from | to | why |
|---|---|---|---|
| sim hash | `1766805932` | `3866599667` | the state gained `produced`, and the widened scenario of task 0037 queues at the workshop, so deliveries are recorded in it |
| data hash | `2144055300` | unchanged | no table moved |

Worth noting that the guard caught this immediately, which it would not have
done a task ago: `produced` only appears because the scenario now has the
player queue something. The widening in 0037 is already paying for itself.

`python tools/verify.py` prints PASS: 1099 asserts, 314 input cases, 0 failed.
`exports` is still the one SKIP and still wants the Godot export templates.

## 0039 - The day clock and dusk - done 2026-09-27

Time passing, without taking away the promise that the player switches reality
when they want to.

**What changed.** The clock counts today rather than the session, the daylight
travels from a cool dawn through noon to a warm dusk, and a modal panel stops
the day. Dusk says so and presses nothing.

Files: `src/core/sim.gd`, `phases.gd`, `src/ui/day_hud.gd`, `world_view.gd`,
`tools/palette.py`, `src/tools/determinism.gd`, both test tools.
Verify: 1130 headless / 330 input / sim hash moved on purpose, below.

### Two tasks disagreed, and the later one was right

Task 0020 asserted, in as many words, **"the wheat kept growing while the
player haggled"** - reading `design.md` section 13 (a farm that runs itself)
as meaning the shop must not stop the world. Task 0039 asks for the reverse:
"time does not pass in menus", with a done-when naming the shop panel.

0039 wins, and on reflection it is the better reading of the same section.
Section 13 is about the farm running **while you are doing something else on
the farm** - which is exactly what task 0038 measured a task ago, and which
this does not touch. Standing at a stall talking to a shopkeeper is not
somewhere else on the farm, it is a conversation. A player who opened the shop
to think and came back to a dead field would learn to think somewhere else,
which is the opposite of cozy.

The inventory of task 0036 is the other half of the distinction and did not
need changing: it deliberately does not set `open_panel`, so a glance at your
own pockets stops nothing. Modal panel stops the clock, view does not.

0020's assert now says the new rule and carries the whole of that reasoning,
so the next person to read it finds the argument rather than an unexplained
reversal.

### The clock was counting the wrong thing

`day_hud` read `state["tick"]`, the global counter, which never resets. On day
three it said 12:00 and kept climbing - a clock measuring how long the session
had been running rather than how much of today is left, which is the one thing
it is for. It reads `day_tick` now, and says DUSK when it is.

### The light goes somewhere

`docs/reference-sheet.png` has one daylight and the light system had one
colour to match. `design.md` asks for light that warms and then cools across
a day, so `tools/palette.py` grew `dawn` and `dusk` ramps either side of the
existing `day`, and the `CanvasModulate` lerps dawn to noon over the first
half and noon to dusk over the second - continuing past dusk, so a day that
runs over looks like one.

It costs nothing per sprite: one node, one colour, as it was before.

`light_target()` - the function tests are supposed to ask, because waiting for
a fade to finish depends on how busy the machine is - was still returning the
noon constant. A function that reports where the light *used* to go is worse
than no function, and the input case caught it.

### The guard, again

The shop pause is a rules change and both hashes came back unchanged, because
the scenario never opened the shop. One task after widening it, the same
lesson: **a rule nothing in the scenario exercises is a rule the guard cannot
see.** The farmer now visits the stall mid-morning and leaves again.

Proved it with the same method as 0037: with the pause `3097167654`, with the
pause switched off `3547075508`.

### The done-whens

- **A player who ignores the clock is not punished for it.** Three whole days'
  worth of ticks past dusk without pressing the button: 300% through the day,
  1100% overtime, house 100/100, nothing taken, nothing spoiled, and the crop
  that was planted is simply ready. Then the button still works. It also works
  at dawn - the choice is the player's at any hour, which is `design.md`'s
  promise stated as an assert.
- **The clock stops in the shop panel and resumes on close.** Ten seconds of
  haggling is not ten seconds of the day, the crop does not grow through it,
  and closing it picks up exactly where it left off. Cancel still gets you out
  of a stopped world, which is the one thing that has to keep working.

### Notes

- `Phases.day_percent()` and `overtime_percent()` are in `src/core/` rather
  than the HUD so the light, the tests and the autoplayer of task 0067 all ask
  the sun the same question.
- Night and the payout keep their own clocks. Stopping for a menu is a daytime
  rule; a wave does not wait for anybody.

### Hashes

| | from | to | why |
|---|---|---|---|
| sim hash | `3866599667` | `3097167654` | the scenario now visits the stall, and the stall stops the clock |
| data hash | `2144055300` | unchanged | the dawn and dusk ramps are in `tools/palette.py`, which is art, not balance - `digest()` has never covered it |

`python tools/verify.py` prints PASS: 1130 asserts, 330 input cases, 0 failed.
`exports` is still the one SKIP and still wants the Godot export templates.
