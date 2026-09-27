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
