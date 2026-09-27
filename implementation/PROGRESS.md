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
