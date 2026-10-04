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

## 0040 - The shop grows - done 2026-09-27

A stall with a shelf that empties, two tabs, and no way to make money standing
at it.

**What changed.** The stall carries a few of each material and each crop,
refreshed at dawn; buying and selling are two tabs of one conversation; and
the seeds sit on the buy tab with everything the choice needs on one line.

Files: `src/core/shop.gd`, `game_data.gd`, `state.gd`, `phases.gd`, `sim.gd`,
`src/ui/shop_panel.gd`, both test tools.
Verify: 1206 headless / 352 input / both hashes moved on purpose, below.

### No money button

The done-when is "buy-then-sell loses money at every price", and it is the one
thing here that would break the game if it were false. `check_stall()` walks
every priced resource and refuses a table where the buy price is not above the
sell price - and the asserts round-trip it for real, through the ledger, on
every single thing the stall carries.

The thinnest margin in the shop is wood, three dollars in the stall's favour.

**Why a check and not one assert:** `BUY_MARKUP` is a float with a rounding
rule between it and the price, so "the markup is above one" and "you cannot
make money going round in a circle" are different claims, and it is the circle
that matters. A markup of exactly 1.0 is refused, with a teeth-test.

### The shelf

`DAILY_STOCK` is small and refreshes **once per day, not once per visit**.
Restocking when you walked away and came back would be unlimited stock with
extra walking, and unlimited stock is a stall a player with money never has to
leave. Running it dry is meant to happen and to be a reason to go and gather.

Buying is all-or-nothing against the shelf as well as the purse: buying five
when three are left buys none of them, the same rule as selling. What is left
is on the label, because a price with no stock beside it is a button that
refuses for a reason the player cannot see.

The stall opens **stocked**, not one tick later: a farm exists before its
first tick - the tests build one and trade with it, and so would a save loaded
at dawn.

### Selling first

The stall opens on the sell tab. A stall is where a morning of chopping
becomes money; buying is the emergency exit. Opening on the tab nobody wants
is one click on every single visit.

The tab is `Shop.tab()` - a fact about the game rather than about a node, like
`open_panel` itself - so the autoplayer of task 0067 can buy without a window
existing, and the tab buttons are lit from the state rather than from the
click.

### The seeds are here because this is where you compare them

They are not stock and they are not bought: planting pays `seed_cost` at the
furrow (task 0028). What the stall adds is the three of them **side by side
with their prices, their growing times and what a plot of each is worth over a
day** - which is the comparison the decision actually needs, and which no
amount of standing in a field provides.

### A long, expensive bug hunt, and what it was

The 0020 shop case started failing: the sell button existed, was enabled, was
at the right place on screen, and clicking it did nothing - the connected
lambda never fired. I bisected the panel across half a dozen runs, ruling out
the tab container, the button styling, the rebuild frequency and
`remove_child`.

It was none of them. A line-based edit of mine had written a literal backslash
followed by the letter `n` in place of a line continuation, so
`shop_panel.gd` **did not parse at all** - and the failure that surfaced was
"the click does nothing" rather than anything mentioning a parse error,
because the scene loaded with a broken script attached.

Two lessons, and the second is the useful one:

- `--check-only` on the file I am editing is three seconds and would have said
  so immediately. It is the first thing to run when behaviour goes strange
  after an edit, before any theory about the engine.
- **The theories were all plausible and all wrong.** Six runs went into
  hypotheses about mouse filters, scroll containers and rebuild timing,
  because the symptom was a UI symptom. The evidence that would have settled
  it in one step was sitting in a parse check I did not run.

### And a real one underneath it

Once it parsed, the seed rows were at y=350 on a 270-pixel screen. A default
`Button` reserves thirty-one pixels whatever `custom_minimum_size` says, and
eleven rows of that overflows the box - exactly the build palette bug of task
0032, in a second panel. `_button()` overrides the theme's padding now and a
full buy tab fits without scrolling.

### Hashes

| | from | to | why |
|---|---|---|---|
| sim hash | `3097167654` | `2555127123` | the state gained `stall`: a shelf, the day it was stocked, and which tab is showing |
| data hash | `2144055300` | `1783085191` | `DAILY_STOCK` is new and is in `digest()` |

`python tools/verify.py` prints PASS: 1206 asserts, 352 input cases, 0 failed.
`exports` is still the one SKIP and still wants the Godot export templates.

## 0041 - The first day teaches itself - done 2026-09-27

Five lines, each stuck to the thing it is about, and not one of them in the
way.

**What changed.** New `src/core/tutorial.gd` and `src/ui/tutorial_prompt.gd`.
Day one shows a line over the nearest tree, then the bare plot, then the
workshop, then the ground in front of the house, then the night button - and
each disappears the moment the thing happens.

Files: `src/core/tutorial.gd` (new), `src/ui/tutorial_prompt.gd` (new),
`game_data.gd`, `state.gd`, `sim.gd`, `phases.gd`, `scenes/Main.tscn`,
`src/ui/main.gd`, both test tools.
Verify: 1242 headless / 364 input / both hashes moved on purpose, below.

### It watches; it never gates

Nothing in either file can stop the player doing anything. There is no "chop a
tree before you may plant", no greyed button, no cage - a step is finished
when the **state** says the thing happened, whether the player read the line
or found it on their own.

That is what makes the second done-when true rather than hopeful: removing
every prompt changes nothing about what is possible. The assert for it plays
day one **backwards** - a tower down, a job queued and a seed sown while the
game is still saying "chop a tree" - and then drives night one to the payout
with four towers and not a single prompt read on purpose. It survives,
house 100/100.

### Which is how the first real bug turned up

`tick()` checked only the **current** step, so a player who built a tower
while the first line was still up stayed stuck on the tree: four things
learned and one line of credit for them. The suggested order is a suggestion,
so it now sweeps every unfinished step each tick. A prompt you have already
satisfied should never be on screen, whatever order you got there in.

The second was quieter. `Tutorial.tick()` went into `begin_preparation()`
*before* `_enter(state, PREPARATION)`, and the last step asks "is it still
day?" - so it asked whether the night had started and was told no, every
single time. It ticks after the phase changes now.

### Five lines, and the check that keeps it five

`GameData.TUTORIAL` is the whole script, and `check_tutorial()` refuses more
than `MAX_TUTORIAL_LINES` (seven, as the task allows - five is what it took),
a repeated step, an empty line, or one longer than 76 characters. The longest
shipped line is 71.

That last limit is the one worth having: a line that wraps is two lines
wearing a hat, and a tutorial the player *reads* is already too long. These
are written to be taken in from the corner of the eye on the way to the thing
they are stuck to.

### The flag, and a parse trap

"Never shows twice" is `gameplay/tutorial_seen`, which was already sitting in
`Settings.DEFAULTS` waiting. `Settings` is an autoload, so `src/core/` may not
touch it: `Tutorial` answers `is_finished()` and the screen decides whether to
have asked at all.

**Reaching it as `Settings.get_bool(...)` fails the parse row.** `verify.py`
checks every script on its own with `--check-only`, where no autoload is
registered - so a file that works perfectly at runtime is a compile error to
the checker. `get_node_or_null("/root/Settings")` with a null guard parses,
and has the side benefit of surviving a test scene with no settings service,
which is what `input_check` builds.

### Notes

- The prompt is clamped to the screen. The nearest tree can be at the edge of
  the view, and a line half off the side is a line nobody reads.
- Night one is unchanged and asserted to stay what `design.md` asks for: at
  most a handful, all of them the basic kind.
- The pointer follows. Walking across the farm moves it to whichever tree is
  now nearest, because which tree is nearest is a fact about where the player
  is rather than about the tutorial.

### Hashes

| | from | to | why |
|---|---|---|---|
| sim hash | `2555127123` | `1534932614` | the state gained `tutorial`, and the scenario's farmer finishes several of the steps in passing |
| data hash | `1783085191` | `1228581114` | `TUTORIAL` is new and is in `digest()` |

`python tools/verify.py` prints PASS: 1242 asserts, 364 input cases, 0 failed.
`exports` is still the one SKIP and still wants the Godot export templates.

**This closes phase 2.** The full day is done: three crops, watering, fishing,
iron, oil, energy, cooking, ammunition, the inventory, the queue, idle
production, the clock, the shop and now day one teaching itself. Phase 3 is the
full night.

## 0042 - Data-driven defences - done 2026-09-27

A tower is a declaration now, not a branch. Phase 3 opens by making room for
the five towers it is about to add.

**What changed.** Every defence that shoots declares `targeting` and `shape`
alongside what it already declared, `towers.gd` dispatches on those instead of
deciding for itself, and splash damage works for anything that asks for it.

Files: `src/core/game_data.gd`, `towers.gd`, `src/tools/headless_check.gd`.
Verify: 1288 headless / 364 input / **sim hash unchanged**, data hash moved.

### The sim hash is unchanged, which is what makes it a port

That is the done-when and it is the only honest measure of this kind of task.
Every tower declares exactly what it was already doing - `closest_to_house`
and `single` - and the defaults for a tower that declares nothing are the same
two, so the scenario came out identical to the digit.

The **data hash** did move, and should have: the table gained two fields per
tower. Declaring what was implicit is a change to the table even when it is
not a change to the game, and the guard is right to say so.

### What was already right, and what was not

Task 0024 built the shooting so that it read `entry["range"]`,
`entry["damage"]`, `entry["reload_ticks"]` rather than comparing ids - so most
of "the combat code reads the declaration" was already true. What was left
implicit was the two decisions the code made on everybody's behalf:

- **How to pick.** `_acquire()` always chose whatever was nearest the house.
  That is one of four ways now - `nearest`, `weakest` and `strongest` are
  there because the towers of 0043 to 0045 will want them, and writing them
  today is four lines in `_threat_of()` where writing them later is four
  branches.
- **How to land.** Every shot hit one thing. The mortar has carried
  `splash_tiles` and `splash_falloff` since the table was written and
  **nothing read either of them** - it has been a single-target tower with two
  decorative fields for eighteen tasks.

### The shot carries its shape

`_land()` reads the shape off the projectile, not off the tower, because a
shot arrives after the tower has finished thinking about it - and at night
nine, possibly after the tower has come down.

An **unarmed** shot is a plain one whatever the tower normally does: a mortar
that cannot reach for powder is throwing a rock, and a rock does not splash.

### The done-when, performed

"Adding a test tower takes a data entry only; delete it afterwards and say
so." A `test_burner` - three fire, splash over two tiles, half damage at the
rim - was built **inside the assert** rather than in `GameData`, used, and
left there as the test. `DEFENCES` never saw it, so there is nothing to have
forgotten to delete.

It hit three of the four zombies for 3, 1, 1 and 0, and `towers.gd` was not
edited to make that work: every line of the entry is read by code that existed
before the assert was written.

### And it broke a test, correctly

Task 0035's night comparison asserted that an empty pool fires **fewer** mortar
shots. True until the mortar started splashing: an armed night now ends
sooner, so the armed mortars get *fewer* shots off than the unarmed ones
grinding through a longer wave. Shot count had stopped meaning "better".

The claim underneath it - an empty mortar takes longer between shots - is
asserted directly against the lever, and the night-level claim is now "a night
fought with powder is over sooner", which is what the player actually
experiences. The kills and the house were already asserted and are unchanged:
28 killed and the house untouched with powder, 26 and 82/100 without.

### Notes

- `Towers.acquire_for()` and `land_for_test()` are seams for asking the rules
  what a declaration would do without building a tower, paying for it and
  waiting for a reload. A test for "strongest picks the healthiest" should not
  have to found a farm.
- `check_defences()` refuses a way of aiming or a shape nobody implements, a
  damage type the game does not name, and a splash over no tiles - all with
  teeth-tests. A typo is now a red line at boot rather than a tower that
  quietly falls back to the default and looks like a balance problem.
- `splash_falloff` was a float (0.5). It is read as `splash_falloff_percent`
  and converted, so the rules stay integer-only; the float stays in the table
  until a balance pass wants to tidy it.

### Hashes

| | from | to | why |
|---|---|---|---|
| sim hash | `1534932614` | unchanged | **the point of the task** |
| data hash | `1228581114` | `331053343` | every shooting defence gained `targeting` and `shape` |

`python tools/verify.py` prints PASS: 1288 asserts, 364 input cases, 0 failed.
`exports` is still the one SKIP and still wants the Godot export templates.

## 0043 - The flamethrower tower - done 2026-09-27

A wedge that lands the instant it is fired, and a fire that outlives it.

**What changed.** `SHAPE_CONE` joins the shapes from task 0042, `Combat` learned
to set things alight, and the flamethrower was given the one field it turned
out to have been missing since the table was written.

Files: `src/core/game_data.gd`, `towers.gd`, `combat.gd`,
`src/tools/headless_check.gd`.
Verify: 1326 headless / 364 input / both hashes moved on purpose, below.

### The flamethrower had never fired a shot

`Towers._find_towers()` collects everything with a `reload_ticks`. **The
flamethrower does not have one** - it never did. It could be built, it cost
twenty wood, twenty-five iron and ten oil, it declared a range, a damage, a
cone and a burn, and it was invisible to the code that makes towers shoot.

It has been that way since the table was written. Nothing caught it because
every test of the flamethrower asked the *table* what it would do, and the
table was right - it was the list that never contained it. Task 0042's
declaration check missed it for the same reason: that check is guarded on
`has("reload_ticks")`, so a tower with no reload is a tower nobody validates
either.

Found only because the cone written for it turned out to be unreachable when
the teeth-test for the cone's own check refused to fire.

It reloads twice a second now. A flamethrower is a continuous thing and that
is as close as a fixed tick gets without pretending otherwise.

### One angle, two numbers, and a check between them

`cone_degrees` is what a designer reads. `cone_spread_permille` is what the
rules use - the tangent of the half-angle, in thousandths of a tile per tile
along the aim. 60 degrees is 577.

Two ways of saying one thing is two things that drift, so `check_defences()`
works the tangent out at boot and refuses a farm where they disagree by more
than a rounding step. That is the same arrangement `check_recipes()` has for a
kit's price, and it is what keeps the trigonometry **at boot and never in a
tick**: the wedge test itself is integer throughout - a dot product for "in
front", a cross product for "off to the side", and one multiply on each side
of the comparison so nothing divides before it multiplies.

### Refreshed, never stacked

`Combat.set_alight()` tops a fire up rather than lighting a second one. Eight
flamethrowers on one zombie is one fire doing two a second, not sixteen - the
done-when, and the number that would have turned the flamethrower from a tower
into a win button.

Refreshing is not capping, though: the **longer** of the two durations and the
**stronger** of the two damages survive, so a better flamethrower is still
better and a second one still extends the burn.

The fire keeps burning after the zombie leaves the cone, which is the whole of
what damage over time buys. A flamethrower that only hurt what was standing in
front of it would be a short-range gun tower that costs oil.

### Three goes at measuring the burn

The stacking assert failed twice, and both times the test was measuring
something other than what it claimed - because the flamethrower had just
become a tower that really fires:

1. The victim was left standing in the cone, so the number included the
   flamethrower hitting it four times a second.
2. Moved to the house, where the wave that had walked in behind it finished
   the job.
3. Measured on a bare night with no tower and no wave: **2**, which is
   `burn_damage`, which is the claim.

A test that shares a state with everything else measures everything else.

### Notes

- Without rounds the cone is a pilot light: the weak damage of task 0035 and
  **no fire at all**. What makes a flamethrower a flamethrower is the thing it
  cannot do without oil, which is the tension task 0032 set up.
- The cone is the one shape with no projectile. There is nothing in the air to
  chase a target that has already moved, which is also why it cannot miss.

### Hashes

| | from | to | why |
|---|---|---|---|
| sim hash | `1534932614` | `1963778898` | the state gained `burning` |
| data hash | `331053343` | `2382052639` | the flamethrower gained `reload_ticks` and `cone_spread_permille` and its shape became `cone`; `BURN_EVERY_TICKS` is new |

`python tools/verify.py` prints PASS: 1326 asserts, 364 input cases, 0 failed.
`exports` is still the one SKIP and still wants the Godot export templates.

**Worth a look on the next pass:** the same "no `reload_ticks`" hole would
hide any future tower. `check_defences()` should probably refuse a `DEFENCES`
entry that declares a `damage` and a `range` but no way of firing - it looks
exactly like a tower and is not one.

## 0044 - The mortar - done 2026-09-27

The long shot, and the only thing on the farm that can miss.

**What changed.** A shell is aimed at a **place** rather than at a zombie, and
takes the flight time the lever says to get there. Splash falls off from the
centre by the number in the table, and `check_defences()` gained the guard
that would have caught the flamethrower.

Files: `src/core/game_data.gd`, `towers.gd`, `src/tools/headless_check.gd`.
Verify: 1356 headless / 364 input / **sim hash unchanged**, data hash moved.

### Aimed at a place

Every projectile in the game chased its target and could not miss. `AIM_GUIDED`
is still the default and still what everything else does, because a bullet
that leads its target is a bullet nobody can read.

`AIM_BALLISTIC` is the mortar, and it is the whole of the tower's character:
the cell is taken **at the moment of firing**, the shell counts down
`flight_ticks`, and it lands there whether or not anything is still standing
on it. Measured: a shell takes 45 ticks, and a zombie five tiles clear of the
aim point by the time it arrives walks away without a scratch.

That reads as fair because the shell is visible the whole way - it is carried
towards the aim point every tick so the view has something to draw - and
because the thing that saved the zombie is the thing the player can see it
doing.

`_land()` became `_land_at()` and takes a **cell**. Splash is inherently about
a place; a shell that had to be handed a live entity could not land on an
empty patch of dirt, which is exactly what a mortar shell does when its target
moved.

### The falloff, measured

Forty damage, two tiles of radius, fifty percent at the rim:

    middle   40
    ring 1   30      (75%)
    ring 2   20      (50%)
    ring 3    0

`splash_falloff` was `0.5` and `towers.gd` was turning it into a percentage at
the moment of firing - a float multiply in the one place this game does not
allow any. It is `splash_falloff_percent: 50` now. That is the third time this
has come up (`WATER_GROWTH_BONUS` in 0029, `BROWNOUT_RATE` in 0033): the table
was written in fractions and the rules want integers.

### The test was measuring the cap, not the damage

The falloff asserts failed first time with every ring reading exactly **20** -
which is a walker's hit points. `Combat.hit()` never reports more than what
was left, deliberately, so that a caller counting damage cannot count overkill;
and a forty-damage shell on a twenty-point walker reports twenty three times
over, and the falloff was invisible behind it.

The rings are given five hundred hit points now. **Measuring damage means
measuring it on something that lives through it** - otherwise the number is
the target's health, not the weapon's.

### The hole that hid the flamethrower is closed

Task 0043 found that the flamethrower had never fired because
`Towers._find_towers()` wants a `reload_ticks` and it had none - and that every
check in `check_defences()` was guarded on the same field, so nothing
validated it either.

`check_defences()` now refuses, **outside that guard**, any entry with a
`damage` and a `range` and no way of firing: it looks exactly like a tower and
is not one. There is a teeth-test that strips `reload_ticks` off the gun tower
and expects a complaint.

### Notes

- The minimum range is real and asserted from both sides: a zombie one tile
  inside it is not a target, one tile outside is. That is what makes placing a
  mortar a decision rather than a purchase - it cannot defend itself.
- `aim` was already taken as a local in `check_defences()` by task 0042's
  targeting word. The new one is `travel`, and the comment says why.

### Hashes

| | from | to | why |
|---|---|---|---|
| sim hash | `1963778898` | unchanged | the scenario has no mortar on it |
| data hash | `2382052639` | `1443374447` | the mortar gained `aim`, and `splash_falloff` 0.5 became `splash_falloff_percent` 50 |

`python tools/verify.py` prints PASS: 1356 asserts, 364 input cases, 0 failed.
`exports` is still the one SKIP and still wants the Godot export templates.

## 0045 - The auto-crossbow - done 2026-09-27

The reference sheet's last tower, and the fourth shape. Every tower on the
sheet now does something only it does.

**What changed.** `SHAPE_LINE`: a bolt down the straight line to the target,
through everything on it, losing a share of the original damage per target
passed. And a shot counter in the rules, because three of the four shapes now
fire nothing that flies.

Files: `src/core/game_data.gd`, `towers.gd`, `src/tools/headless_check.gd`.
Verify: 1386 headless / 364 input / both hashes moved on purpose, below.

### The falloff, measured

    a bolt of 5 through five, losing 20% of the original each: [5, 4, 3, 2, 1, 0]

**A share of the original, not of what is left.** Taking a fifth off what
remains is 5, 4, 3.2, 2.56 - an integer mess that floors out after three and a
lever that stops meaning anything. Taking it off the original gives a curve a
player can count, and the sixth zombie takes nothing because the bolt stops at
`pierce`.

Two numbers moved to make that readable:

- `damage` 3 -> 5. At three, a fifth off each step is 3, 2, 1, 1, 1 and the
  minimum-hit floor eats the curve.
- `pierce_falloff` 0.4 -> `pierce_falloff_percent` 20. The **fourth** fraction
  turned into a percentage, after `WATER_GROWTH_BONUS` (0029),
  `BROWNOUT_RATE` (0033) and `splash_falloff` (0044). The table was written in
  fractions throughout and the rules want integers; this is the last of them
  in the defence table.

### Right against a rush, wrong against a tank - by arithmetic

    bolts to kill:  runner 2,  tank 60

A runner has ten hit points and no armour, so a five-damage bolt takes two. A
tank has a hundred and twenty and armour three, so the same bolt does two a
time and needs sixty. That is not a balance pass, it is what the numbers
already said - the task's requirement was to make it true "by construction",
and armour was already the construction.

And a bolt through a queue of five is worth 15 against a single shot's 5, off
one reload. One tower, two completely different answers depending on what
walks into it.

### Counting shots stopped working

Task 0033's power assert - "the towers kept shooting in the dark" - started
reading **zero** from a wall of crossbows that were firing perfectly well. It
counted `Towers.in_flight()` rising, and a line puts nothing in the air. The
cone had the same hole since 0043 and got away with it because that test used
mortars.

`Towers.shots_fired()` is a counter in the state now, incremented once per
shot whatever shape it is. Three of the four shapes land at once; counting
projectiles has not meant "did it shoot" since the flamethrower started
working.

That is the second time this week a test has been measuring a proxy that
stopped tracking the thing: shot counts for "worse" in task 0042, projectiles
for "fired" here. Both were fine when written.

### Notes

- The line is one tile wide, tested with a cross product against the aim's
  length squared - no square root, nothing dividing before it multiplies, and
  the same two products the cone uses.
- Nearest first, and the order is the whole feature: a bolt that hit the far
  one first would be the same damage arranged so that standing in a queue did
  not matter.
- "Cheap in iron" is cheap **against the towers it competes with** - the
  flamethrower and the mortar - not against the starter tower, which is
  cheaper than everything by construction. The crossbow's price is paid in
  energy: three, the hungriest thing on the farm, which is task 0033's
  generator earning its place.

### Hashes

| | from | to | why |
|---|---|---|---|
| sim hash | `1963778898` | `1578557944` | the state gained `shots_fired` |
| data hash | `1443374447` | `1540632093` | the crossbow's shape became `line`, its damage 3 -> 5, and `pierce_falloff` 0.4 became `pierce_falloff_percent` 20 |

`python tools/verify.py` prints PASS: 1386 asserts, 364 input cases, 0 failed.
`exports` is still the one SKIP and still wants the Godot export templates.

## 0046 - Fences and walls - done 2026-09-27

The other half of a tower defence: making them walk where you want them to,
and making that cost them time rather than stopping them.

**What changed.** Structures can be damaged and destroyed, a zombie with no
path chews through the nearest wall instead of standing still, and holding a
wall over a tile draws the route the wave would take instead.

Files: `src/core/farm.gd`, `enemies.gd`, `pathing.gd`, `src/ui/build_mode.gd`,
`world_view.gd`, `src/tools/determinism.gd`, both test tools.
Verify: 1417 headless / 371 input / sim hash moved on purpose, below.

### "Task 0049" was a comment in `_walk()`

    var next := Pathing.step_from(state, here)
    if next == here:
        return                  # nowhere to go: stand there. Task 0049.

A farm sealed completely made the entire wave stand still for ever. A player
who walled themselves in won the night by doing nothing, which is not a tower
defence - it is a puzzle with one answer.

`design.md` is explicit that a wall buys **time** rather than safety, so a
zombie with nowhere to go takes the nearest thing in its way apart. It bites
whichever neighbour is nearest the house rather than whichever is first in
reading order, so a wave eats through a line instead of nibbling the far side
of it.

Destroying a wall removes it, which bumps `grid_version`, which rebuilds the
field on the next tick. A hole in a wall is a new way through and they find it
because the field is asked rather than remembered.

That directly reversed an assert from task 0025 - "a boxed-in zombie stands
still rather than crashing" - which was true, and was the placeholder that
comment described. It now asserts that it eats its way out, and says why it
changed.

### `Farm.damage()`

The same promise `Combat.hit()` makes about a zombie: it never reports more
than was there, so a caller counting damage cannot count overkill. Asserted
from both ends - six off a twenty-point wall is six, a hundred more takes the
fourteen that were left, and hitting the resulting gap does nothing. The house
and the other fixtures refuse the whole thing.

### Showing the route before paying for it

`Pathing.route_if_blocked()` builds one throwaway field with the cell
pretended-blocked, reads the route out of it, and throws it away. The
alternative - put the wall down, look, take it up - costs the player the stone
if they change their mind and costs the code a build-and-undo that has to be
exactly reversible.

It is drawn dotted, so it reads as a prediction rather than as something on
the farm, and **only for things whose job is traffic**: a player placing a
tower is thinking about range, not about where the queue goes. The input case
checks both halves, and then checks the honest one - that the route the
preview drew is exactly the route they take once the wall is down.

### Two asserts of mine that claimed more than the game promises

- **"The long way round is longer."** It is not, necessarily: a detour around
  three cells of wall on open ground came out at 27 four-way steps against 27,
  by a different path. What a wall actually guarantees is that nobody walks
  through it, so that is what it asserts now - no step of the new route is on
  a wall, and the old route went straight through where the wall now is.
- **A seven-cell wall across the approach** sealed it outright and the route
  came back empty. A perfectly good wall and the wrong test; the reroute test
  uses three cells and sealing has its own.

### The palette rebuilds under the click

The input case failed selecting a tower straight after placing a wall.
Placing changed what was affordable, so the palette rebuilt on the next frame
and the click landed on whatever had taken that row's place. Four frames of
settle. Worth knowing for the next case that clicks a palette twice.

### Notes

- Fifty walls, twenty forced rebuilds: **4.7 ms each, 14% of a tick** - and
  asserted to be under half. It is a rare cost by construction, and there is
  an assert that asking again when nothing moved does no work at all.
- The determinism scenario got three cells of wall. Walls are the only thing
  in the game that changes where the zombies walk, and a scenario with none of
  them guarded none of that. Deliberately not a seal: that is a different
  night, and the chewing has its own asserts.

### Hashes

| | from | to | why |
|---|---|---|---|
| sim hash | `1578557944` | `4196864933` | the scenario now has walls in it, so the flow field it hashes is a different field |
| data hash | `1540632093` | unchanged | no table moved |

`python tools/verify.py` prints PASS: 1417 asserts, 371 input cases, 0 failed.
`exports` is still the one SKIP and still wants the Godot export templates.

## 0047 - Barricades - done 2026-09-27

Almost free, almost paper, and the only thing you may throw down while they
are already coming.

**What changed.** `per_night_limit` is enforced, a barricade costs four wood
and nothing else, and a zombie chewing through one bites at the speed it
walks rather than every tick.

Files: `src/core/building.gd`, `enemies.gd`, `phases.gd`, `game_data.gd`,
`src/tools/headless_check.gd`.
Verify: 1453 headless / 371 input / both hashes moved on purpose, below.

### Three declared fields, one of them read

`placeable_at_night` and `lifetime_ticks` were already wired - build mode
honours the first and `Building.expire()` the second. **`per_night_limit` was
not read by anything**, so a barricade could be thrown down as fast as the wood
held out, which is a wall you rebuild rather than an emergency answer.

It is counted per night, cleared by `begin_night()`, and counted **when one
goes down rather than when one comes up**: a barricade that was chewed through
still used one of tonight's five, or the limit is a limit on how many stand
rather than on how many you get. The refusal says which it is, too - "five a
night, and that was the last" is a different sentence from "you are short two
wood", and the first one is the true one.

`check_defences()` now refuses a night-placeable thing that never expires -
that is a wall you can build mid-wave - or one with no limit at all.

### It was not the cheapest thing in the game

Three wood and two stone is **$12** of goods against a fence's $10, and the
task's first requirement is "cheapest structure in the game". Four wood is
$8, and stone was the wrong currency anyway for a thing you throw down while
they are already coming: a barricade should be one trip to one tree.

That change took a group down with it. The crafting group read
`inputs[GameData.STONE]` directly, which was fine while a barricade cost
stone and became a **missing-key access** the moment it did not - aborting
`_task_0019` silently, twenty-nine asserts short, with nothing in the FAIL
list to say so. It reads `inputs.get(STONE, 0)` now. A test that indexes a
recipe for an input it may not have breaks on a balance change rather than
reporting one.

### What a barricade actually buys, in three goes

The done-when is "placing one mid-wave buys the measurable seconds the lever
claims", and the first two measurements said **zero**:

1. Three dropped across a wide approach: 27 steps against 27. The field
   routes around them for nothing - exactly what task 0046 found out about
   walls, on the same afternoon.
2. Walling the approach down to a single gap and plugging it: still nothing.
   The wall was thirteen cells and the map is eighteen tall, so they went
   round the whole thing.
3. Dropped into the cell a walking zombie was about to enter: **two ticks**.

Two ticks is correct, and it is worth being plain about why. A structure is
currently a **yes or a no** - `Pathing._passable()` returns false and that is
all - so anything that does not seal a route costs nothing. `path_cost`, which
every blocking structure declares and **nothing reads**, is what makes an
obstacle expensive without making it impassable, and it belongs to task 0049:
"a zombie prefers the open lane and breaks through when it must".

So what a barricade buys today is the time it takes to **eat**, and that is a
lever: hit points over the biter's damage, one bite per tile's worth of time.
Measured at **21 ticks** for a twenty-point barricade against a ten-damage
walker, which is exactly two bites, and a barricade with twice the hit points
costs more.

### The bite had no cadence

Finding that out needed a fix. `_walk()` gates chewing on `move`, which is
**sub-units and not tiles** - a walker covers three of sixty-four in a tick -
so task 0046's chewing was biting on every one of them: twenty damage in two
ticks, and a barricade that bought nothing. A bite now costs what crossing a
tile costs, so a fast zombie chews fast and `ticks_per_tile` means one thing
in both places.

### And one assert of mine claimed a number the game does not

"It costs at least a second" was a threshold I picked, not one the levers
say - two bites is two thirds of a second. What makes it measurable is that it
is exactly the arithmetic and that it moves when the lever does, so that is
what it asserts.

### Hashes

| | from | to | why |
|---|---|---|---|
| sim hash | `4196864933` | `961536146` | the state gained `placed_tonight`, and chewing has a cadence |
| data hash | `1540632093` | `2510238421` | a barricade is four wood instead of three wood and two stone, and its kit with it |

`python tools/verify.py` prints PASS: 1453 asserts, 371 input cases, 0 failed.
`exports` is still the one SKIP and still wants the Godot export templates.

## 0048 - Mines and traps

A mine is the first defence that never aims. It has no `range`, no
`reload_ticks` and no `energy_draw`, and the whole of task 0048 is arranging
for that to be true everywhere rather than only in the table.

`Towers` collects by `reload_ticks`, so a mine is invisible to it for free -
it is never in a targeting loop, never draws a circle, and costs nothing on a
tick with nobody near it. The new `src/core/traps.gd` runs straight after
`Enemies.tick()` and asks one question per zombie: is there a trap under me.
That is a dictionary lookup per entity, the cheapest thing in the night loop,
and it means a mine goes off on the tick a foot lands on it.

`one_shot` was in `DEFENCES` from the start and nothing read it. It is now
what `Traps.is_trap()` means, and `check_defences()` refuses a trap that also
declares a `range` or a `reload_ticks` - a trap does not aim.

### Every mine was a little wall

The one that was worth the whole task. `Pathing._passable()` treated **every**
occupant as blocking, which is what makes a wall a wall - and made a mine a
wall too. The flow field routed around each one, so a minefield was a set of
obstacles that every zombie could see and step past, and a mine would never
have gone off except by accident.

It was not visible in the rules or in the table. What found it was one assert
asking the route where it went after a mine was laid on it: the route had
moved. Traps are now passable, and the assert holds the route to the same
cells and the same length as before the mine went down.

### They do not chain, on purpose

The done-when asks for a decision and for the journal to record it: **a mine's
blast damages entities and nothing else.** Two mines side by side are two
mines.

The reason is that a chain collapses per-mine placement into one decision. If
mines set each other off, the best move is always to put every mine you own in
one line and let the pile do the work, and the difference between a good
placement and a bad one disappears into how many you have. `design.md` wants
the farm to be a set of small choices.

It also keeps everything else's splash away from them. A mortar shell landing
beside a mine used to be a real possibility for the farm's own guns to disarm
the farm they were defending; there is an assert for that too.

`armed_limit` (six) is what stops a rich player carpeting the approach, and
`mine_kit` at the workshop is what makes each one spent a thing to make again
rather than a loss. `why_not()` says which limit it is - "6 armed is all the
farm will take" is a different sentence from "short 5 iron".

### Measured

    a walker set one off 61 ticks (2.0s) after it came in
    a mine: 60 damage over 1 tile, 60% at the rim -> [60, 36, 0]

Sixty in the middle, thirty-six a tile out, nothing past it, and sixty is
three walkers' worth of hit points. The rings are measured through a
`detonate_for_test()` seam rather than through a tick, because a tick moves
everybody first and then the numbers belong to wherever they ended up.

### Hashes

| | from | to | why |
|---|---|---|---|
| sim hash | `961536146` | `203117208` | the state gained `traps_sprung`, the night loop gained a pass, and traps no longer block the flow field |
| data hash | `2510238421` | `2308311333` | the mine gained its falloff and its armed limit, and `mine_kit` joined the recipes |

`python tools/verify.py` prints PASS: 1500 asserts, 371 input cases, 0 failed.
`exports` is still the one SKIP and still wants the Godot export templates.

## 0049 - Zombies path around walls

The flow field stopped being a count of steps and became a count of cost. A
wall used to be a hole in the map: impassable, so the field routed around it,
so a zombie would walk the whole length of the farm rather than touch one and
only ever broke something when it was sealed in with no route at all.

`design.md` says a wall "bloqueia/atrasa" - blocks *and delays* - and a barrier
that is always walked around does neither for long. So a barrier is priced
instead. Stepping onto a cell costs what the terrain costs plus the
structure's `path_cost`, which reads as "going through this is worth this many
tiles of detour", and a zombie whose cheapest way home runs through a wall
stops and takes the wall apart, because that genuinely is the cheapest way
home.

`path_cost` had been declared on the fence, the wall and the barricade since
the table was written, and until today nothing read it. Task 0047 left a
comment in its own test saying so and naming this task; that comment is now
the measurement underneath it.

### Only a barrier is priced

A tower and a workshop declare no `path_cost` and stay impassable, so a wave
flows **through** the walls and **around** the buildings. That is the
distinction the table already drew, and it is the one the game wants: the
player's towers are not a road, and the enemy that goes after towers on
purpose is task 0052, which would have had nothing left to be if every zombie
already chewed through them.

Terrain is priced too. Ordinary ground is one, tilled soil is two, so a wave
prefers the lane between the beds to the beds themselves - which is the goal's
own sentence, and now a number rather than a hope.

### The sweep had the edge backwards

The bug worth the task, and it hid where bugs like to. A sweep outward from
the house prices each step by the cell it is *expanding into*; the walking
goes the other way, so the move being priced is the neighbour's move **into
the cell being expanded**. While every cell cost one those were the same
number and the mistake was invisible. With a wall worth twenty-one they are
not: the field came out disagreeing with the step function, cells appeared
whose cheapest neighbour was worth more than they were, and a zombie walked in
a circle for four hundred steps instead of arriving.

It was found by asking a walled-in zombie what route it took and getting a
four-hundred-step answer on a forty-by-eighteen farm.

### Nothing can oscillate, and it is arithmetic

Every step is onto a cell worth `field[here] - enter(next)`, and every `enter`
is at least one, so a zombie's field value **strictly falls on every step it
takes**. It cannot return to a cell it has left, because that cell is worth
more than where it is standing. That is not a tie-break rule bolted on
afterwards, it is the shape of the field.

The done-when asks for "no zombie in the same pair of cells for 20 ticks" and
that is asserted literally, but the assert underneath it is the real one: over
sixty zombies and twelve hundred ticks of maze, **1818 steps and not one of
them uphill**. Only while the grid holds still - a wall coming down rebuilds
the field and a zombie's own cell can legitimately be worth more afterwards,
so a tick that changed the grid is a tick the check skips.

### Dial's algorithm, not a heap

Every step costs between one and `WIDEST_STEP`, so the cells to visit are
filed by cost into that many buckets and read back in order. Same answer a
priority queue gives, a fraction of the work, and the order inside a bucket is
the order things went in - one fewer thing that can differ between machines.
`check_pathing()` holds `WIDEST_STEP` against the tables, because a wheel one
bucket short does not fail loudly, it files a cell wrongly and the route comes
out subtly wrong.

Buckets are plain `Array`s and not `PackedInt32Array`s on purpose: a packed
array is a value type, so `wheel[i].append(x)` would append to a copy.

### Measured

    a hundred zombies in a maze: 1602.7 us a tick, 5% of the 33333 us at 30Hz allows
    the worst single rebuild of a maze: 3432 us, 10% of a tick
    60 zombies over 1200 ticks: 1818 steps, all downhill, 0 that were not
    dropped in the way, one barricade costs them 2 ticks - the ways round it
      are the same length - but stepping into it costs 5

The first rebuild cost 5785 us because it asked the occupant table about all
seven hundred cells to find the forty with an answer. Terrain is now filled in
one pass over the bytes and only the occupied cells are looked up.

**One barricade on open ground is still nearly free** and the test says so.
On a four-way grid every route between two cells not in a straight line is the
same length, so stepping around a single obstacle costs nothing at all. What
the price changes is a *line* of them, and that is what task 0049's own group
measures: with a gap in the line they take the gap and break nothing; sealed,
they come through the wall and a hundred and twenty hit points of it go.

### Three asserts of 0046 and 0047 claimed the old rule

They were updated rather than deleted, and each one still makes the same claim
in the new world: the walled cell used to be `UNREACHABLE` and is now priced
at what the wall is worth; the sealed pocket used to have "nowhere at all to
walk" and now has no way out that is not through a wall; the barricade used to
buy two ticks with a note saying task 0049 would fix that, and now carries the
price instead of the promise.

### Hashes

| | from | to | why |
|---|---|---|---|
| sim hash | `203117208` | `1819315534` | the field is a cost field, so they route differently and break through instead of walking round; the state gained `flow_cost` |
| data hash | `2308311333` | `3566119030` | `TERRAIN_COST` and `WIDEST_STEP` are levers, so they joined the digest |

`python tools/verify.py` prints PASS: 1535 asserts, 371 input cases, 0 failed.
`exports` is still the one SKIP and still wants the Godot export templates.

## 0050 - The runner

The runner's numbers were in the table from the start and its waves were in
the nights from the start. What it did not have was the one rule that makes it
a different problem rather than a fast walker: **it does not stop for what you
built.**

Ten hit points against a walker's twenty and nine ticks a tile against twenty
- half the life and two hundred and twenty-two percent of the speed, which is
what the requirement asks to be stated. Less damage when it lands and a bigger
reward, because it is harder to kill and cheaper when it gets through.

### Two fields

Task 0049 made a wall a price rather than a hole, so everything now breaks
through when breaking through is cheapest. A runner must not, so `Pathing`
sweeps a second field from the same entry costs with every barrier taken out
of the map - the pre-0049 field, in other words - and `ignores_structures` on
an enemy is what picks which one it reads.

The alternative was to let a runner take its second-favourite neighbour out of
the shared field, and that is a step uphill: the one thing the shape of the
field guarantees cannot happen, and the guarantee that makes oscillation
impossible. A second field costs one more sweep per grid change and nothing
per tick, which is the right side of that trade.

**A runner with no way round falls back to the shared field** and breaks
through like everybody else. A runner that stood still in front of a wall
would turn sealing the farm into a win condition, which task 0046 already
learned once.

### Three fixtures that were wrong before the code was

Worth recording, because all three looked like failures of the rule and were
failures of the test:

- The check on the table compared a structure-ignorer against the **slowest**
  enemy that stops, which is the giant at fifty ticks a tile. Anything is
  faster than that, so a "runner" slower than a walker passed. It compares
  against the fastest one that stops now.
- The long way round was left open at row seventeen of the column, and row
  seventeen of that column is a tree. The line was sealed after all and every
  runner dutifully ate through a wall it was supposed to run around. The gap
  is now the bottom-most cell anything can actually stand on.
- The way round that line is eighteen tiles and a wall is worth twenty-one, so
  the **walker** went round it too - and was right to. The test that tells the
  two of them apart has to use a barrier worth less than the detour, so it
  uses a fence at six.

### Measured

    a fence with the long way round open: a walker took 30 hit points out of
      it in 544 ticks; a runner took 0 and got there in 388
    through a maze: a runner 334 ticks against 226 in the open; a walker 741
      against 501
    a wave of five and five, all from one cell: runner, runner, runner,
      runner, runner, walker, walker, walker, walker, walker
    a rush of 8 runners: three crossbows let 0 through for 0 damage; one
      mortar let 4 through for 12

The last line is the done-when and the reason the runner exists. Both farms
had a generator and ran at a hundred percent, so it is a comparison of towers
and not of budgets: a crossbow draws three against a mortar's one, and a farm
makes four on its own, so without the generator this would have measured which
tower fits rather than which tower stops a rush.

A maze costs a walker two hundred and forty ticks and a runner a hundred and
eight, for the same reason: half of what a maze does to a walker is make it
stop and chew.

### The extra sweep

The worst single rebuild went from 3432 us to 4563 us - ten percent of a tick
to fourteen. A hundred zombies in a maze cost 1585 us a tick against 1602
before, which is noise. The second field is paid for on the tick a wall falls
and nowhere else.

### Hashes

| | from | to | why |
|---|---|---|---|
| sim hash | `1819315534` | `3756808106` | the state gained the second field and its costs, and runners route differently |
| data hash | `3566119030` | `2814341152` | the runner declares `ignores_structures` |

`python tools/verify.py` prints PASS: 1556 asserts, 371 input cases, 0 failed.
`exports` is still the one SKIP and still wants the Godot export templates.

## 0051 - The tank

One lever moved and one done-when could not be met. Both are worth the space.

### Armour four, and four is where the lever stops meaning anything

A crossbow bolt is five damage and `Combat.MINIMUM_HIT` is one, so armour four
leaves exactly the floor. Armour five takes nothing more off a bolt and does
take another point off a shell - which makes the tank **worse** at being the
thing concentrated damage is for. So four is not a number picked in the middle
of a range, it is the knee, and the lever's range is written down as 1-4 now
rather than 1-6.

What it buys, measured: against a tank a bolt lands 1 of its 5 and a shell
lands 36 of its 40. Twenty percent against ninety. A hundred and twenty bolts
to kill one, or four shells. Against a walker both land all of it, so it is
the tank that makes the difference and not the towers - which is the
requirement, exactly.

### The done-when that is not true

> A crossbow wall barely scratches it and a mortar drops it - measure both

It is not achievable by tuning the tank, and the arithmetic says why before
any measuring does. Against armour four:

| | damage a tick, per tower | per 1000 goods |
|---|---|---|
| auto_crossbow | 0.0667 | 0.392 |
| mortar | 0.2400 | 0.361 |

Four crossbows are 0.267 a tick against one mortar's 0.240 - eleven percent
apart - and the crossbow is *also* the marginally cheaper way to buy that
damage. Two curves that close cannot be separated by the hit points between
them. Measured at three values rather than argued:

- **120** - four crossbows kill it in 616 ticks. Not "barely scratches".
- **160** - the tank reaches the house with 10 of 160 left. A knife edge, and
  my own assert caught me calling it "barely scratched".
- **220** - the wall fails properly, with 70 of 220 left. And two mortars at
  twice the price fail too, by 8 hit points.

So the hit points stayed at 120, where the rest of the curve was built around
them, and the armour does the work. If the tank is meant to be the reason the
mortar exists then the lever is on the **mortar** - its reload or its price -
and that belongs to a balance pass rather than to an enemy task. The finding
is written into `implementation/prompts/0060-ten-nights.md` so it is in front
of whoever does it, with the warning that touching the mortar re-opens task
0050's measurement.

What is asserted instead is what is true and is the actual requirement: half
as many mortars kill a tank in less time than a wall of crossbows does, and
per tower it is not close.

### Measured

    a tank: 120 hit points, 4 armour, 38 ticks a tile against a walker's 20, 0 and 20
    against a tank a bolt lands 1 of its 5 (20%) and a shell 36 of its 40 (90%)
    it takes 120 bolts to kill one, or 4 shells
    a tank: four crossbows ($680) killed it in 616 ticks; two mortars ($1330,
      half the towers) in 392
      which is 2464 tower-ticks of crossbow against 784 of mortar

The other done-when, that the reduction cannot take a hit below zero, is
asserted directly: a hit of one, two, four or five against armour four all
take at least `MINIMUM_HIT` off and the tank's health always goes down; a hit
of zero or of minus fifty does nothing at all rather than healing it.

### A number in a log that was not the number

`_tank_against()` first reported how much health the tank had left by asking
afterwards - and reaching the house takes it off the farm, so the answer was
always zero. It samples every tick now. The same mistake task 0044 made with
the entity count.

### Hashes

| | from | to | why |
|---|---|---|---|
| sim hash | `3756808106` | `3756808106` | **unchanged** - no rule moved, and there is no tank in the determinism scenario |
| data hash | `2814341152` | `2262728717` | the tank's armour went from three to four |

`python tools/verify.py` prints PASS: 1592 asserts, 371 input cases, 0 failed.
`exports` is still the one SKIP and still wants the Godot export templates.

## 0052 - The breaker

Two fields that had been in the enemy table since it was written and read by
nothing: `targets_structures` and `structure_damage_multiplier`. The second
could not have been read - it was `3.0`, and `src/core/` is integer
arithmetic. That is the fifth fraction found this way after
`WATER_GROWTH_BONUS`, `BROWNOUT_RATE`, `splash_falloff` and `pierce_falloff`,
so `check_enemies()` now refuses a float in the table outright.

### A third field

A breaker walks downhill to the nearest thing you built, the same way
everything else walks downhill to the house: the same sweep from different
seeds. `Pathing` keeps a third field seeded at every **structure** - the
towers, the workshop, the generator.

What counts as a structure is the rule task 0049 already wrote, read
backwards. A wall declares a `path_cost` and is a door with a price on it; a
tower declares none and is not a door at all. So the things with no way
through them are exactly the things worth coming for, and `is_prey()` and
`_cost_of()` are two readings of one line in the table.

That makes target selection deterministic and ordered for free: nearest by
what the walk costs rather than by a straight line, and downhill every step,
so a breaker can no more circle a tower than a walker can circle the house.
With nothing left standing the field has no answer and it falls through to the
house.

The sweep is skipped when there is nothing to hunt. The farm is never actually
in that state - `FARM_MAP` starts with a workshop, and a workshop is something
the player can lose - which took three failed asserts to notice. The fix was
to clear the farm in the test rather than to pretend it was clear.

### Little against the house

Damage eight to five, which is half a walker: "little against the house" is
half the requirement and it has to be visible in the number. At eight it was
almost a walker with a hobby. Three hundred percent of five is fifteen, so it
does half what a walker does to the roof and half again what a walker does to
a tower.

### Measured

    a breaker does 5 to the house and 15 to a structure; a walker does 10 to both
    offered two towers it went for (35, 7), 7 away against 30
    six breakers against four gun towers: 0 of 4 towers left, 2 breakers killed.
      With five crossbows covering them: 4 of 4 left, 6 killed

Both done-whens, in one line. An uncovered line of four gun towers is taken
apart completely and only two of the six attackers die doing it; the same line
with five crossbows over it loses nothing and kills all six. The house takes
nothing in either case, because there was always a tower standing.

### The rebuild is creeping up

Three sweeps now, and the worst single rebuild of a maze has gone 3432 →
4563 → 7846 microseconds across tasks 0049, 0050 and 0052 - ten percent of a
tick to twenty-four. It still passes its assert with room and a hundred
zombies in a maze still cost 1607 us a tick, because the sweeps are paid on
the tick a wall falls and nowhere else. But a fourth field would be the point
to stop adding them and start sharing one, and task 0102 owns that number.

### Hashes

| | from | to | why |
|---|---|---|---|
| sim hash | `3756808106` | `3214589414` | the state gained the hunt field and its costs |
| data hash | `2262728717` | `1507247408` | the breaker does five at the house instead of eight, and two fractions became percentages |

`python tools/verify.py` prints PASS: 1631 asserts, 371 input cases, 0 failed.
`exports` is still the one SKIP and still wants the Godot export templates.

## 0053 - Repair during the night

Task 0034 built the ledger half of this and said in its own header what it was
leaving behind: "standing near the thing, taking time over it, being
interrupted, and the worse rate for the house". All four are here, and three
of them cost no new machinery at all.

### Repair is a verb

`Interact` offers `repair` on a cell that is damaged and can be paid for, and
everything else falls out of the loop that already exists. `Player` runs it
like chopping a tree: one hit point per work cycle, so a wall comes back a
plank at a time; walking away stops it because walking away stops every job in
the game; and standing near it is `Player.target()`, the same reach every
other verb uses.

`interact.gd` had named this task in a comment since it was written -
"Repairing (task 0053) and dropping a barricade (task 0047) are the night's
own verbs" - so the work was to not put repair on `DAY_ONLY` and to fill in
one arm of `complete()`.

The highlight needed nothing: `main.gd` asks `Interact.verb_at()` what the
cell under the player offers and draws a box when the answer is not empty, so
a chewed wall started glowing at night without a line of view code. That is
what the verb table is for.

### Two more unread levers

`REPAIR_TICKS_PER_HP` had been in the table since 0034 and nothing read it.
`HOUSE_REPAIR_PENALTY` had been `2.0` - the sixth fraction found this way, and
it could not have been read, because the rules are integers. It is
`HOUSE_REPAIR_PERCENT` at 200 now, and it does both jobs the requirement asks
for: the house costs twice as much per hit point **and** takes twice as long.
One number, because patching a roof is not nailing a plank back onto a fence.

0034's own asserts were written at the base rate for the house, since the
penalty was unread. They read the house rate now.

### Measured

    ten hit points: {food: 10, wood: 10} on a wall, {food: 20, wood: 20} on
      the house (3 ticks each against 6)
    left to it for 400 ticks it put 90 hit points back; walking away after
      200 put back 66
    a wall under a walker: 293 ticks on its own, 839 with somebody mending it
      (259 food). Chewing 0.50 a tick against mending 0.33

The last line is the done-when and it wants reading carefully. Mending a wall
mid-wave nearly triples how long it stands - 293 ticks to 839 - and that is
"measurably changes whether it holds". It does **not** hold for ever: a walker
takes half a hit point a tick off and a repairer puts a third of one back, so
the wall is still losing, slowly. That is time bought rather than a wall that
never falls, and both numbers are levers - `REPAIR_TICKS_PER_HP` (1-8, at 3)
against the walker's damage and speed. At 2 the two rates tie exactly and at 1
the repairer wins outright; whether one pair of hands should beat one zombie
is a balance question, and it is written here rather than decided quietly.

### Two tests that were wrong about the game

Both worth recording, because both looked like bugs and were not:

- The first interruption test released the key half way and measured no
  difference. Correct: a verb here runs until the player cancels, steps, or
  the cell stops offering it. One press fells a whole tree, and repairing is
  not a special case. It walks away now.
- The first "wall under attack" test put one wall on the route and nobody ever
  chewed it. Also correct: task 0049 measured that a single wall on open
  ground is walked around for nothing. The test seals the column.

### Hashes

| | from | to | why |
|---|---|---|---|
| sim hash | `3214589414` | `3214589414` | **unchanged** - repair only happens when the player acts, and the determinism scenario does not repair |
| data hash | `1507247408` | `3795708698` | `HOUSE_REPAIR_PENALTY` 2.0 became `HOUSE_REPAIR_PERCENT` 200 |

`python tools/verify.py` prints PASS: 1663 asserts, 380 input cases, 0 failed.
`exports` is still the one SKIP and still wants the Godot export templates.

## 0054 - The player's ability

The whole `ABILITY` table had been in `game_data.gd` since it was written and
read by nothing, `slow_fraction: 0.5` among it - the seventh fraction found
that way, and one that could not have been read, because the rules are
integers. It is `slow_percent: 50` now, and it means percent of normal speed,
which is what a designer means by "half speed" and the opposite of what
`ticks_per_tile` measures.

### One button, no target

`design.md`'s fourth pillar says the night is semi-idle: the player watches
the defence they built do the work and "pode eventualmente" step in. So the
ability is one press with a long wait rather than a weapon. It goes off where
the player is standing, which means the decision is *where to be* when the
wave arrives - made with their feet, minutes earlier - rather than with a
cursor in the moment.

The slow is what turns the wave, not the damage. Twenty-five kills a walker
outright and dents a tank; five seconds of half speed is five seconds of every
tower on the farm getting a free volley into the same crowd.

### Forty-five seconds was every wave

The lever said 45 seconds and the done-when asks for one turned wave a night.
Night one runs **1612 ticks - fifty-four seconds** - so at 45 the flare came
back inside the night and a three-wave night got a flare a wave. At 80 it is
one press, measured, and a longer night later in the run buys a second.

Two rules make that readable rather than fiddly: the wait runs only at night,
and **every night starts charged**. If it ran by day it would be pure
bookkeeping, since a day is longer than any cooldown. If it carried over, a
player who flared the last wave of night three would start night four with a
flare that is mysteriously not ready and nothing on screen to explain why.

### Measured

    a flare of 25 over 3 tiles: [25, 25, 25, 25, 0]
    night 1 runs 1612 ticks (54s) and pays for 1 flare, at a 80s cooldown
    a wave of 8 walkers at an undefended house: 80 damage without the flare,
      50 with it

Flat inside the radius and nothing at all outside it - no falloff, because the
table declares none and a flare is a flare rather than a shell. The last line
is the done-when: the same seed, the same crowd, the same undefended house,
and one press is worth thirty hit points of roof.

The other done-when - two uses in the same second are impossible - is asserted
twice over: through the rule, and through four taps of the key inside a second
in `input_check`.

### Seeing it

The burst is an expanding ring at the player's feet, drawn from what the rules
already recorded: where it went off and how many ticks of it are left. That is
the same arrangement as `hurt` in `Combat` - the view must not have to
remember anything the rules know - and it means the picture cannot disagree
with the damage. `charge_percent()` is there for the ring the night HUD will
draw at task 0056.

`F` is the key, and it is in `project.godot` beside the others rather than
read from the keyboard directly.

### Hashes

| | from | to | why |
|---|---|---|---|
| sim hash | `3214589414` | `2770152428` | the state gained the ability block, and enemies gained a `slow` |
| data hash | `3795708698` | `2691269033` | `slow_fraction` became `slow_percent`, the cooldown went 45s to 80s, and the table gained a damage type and the flare's own draw time |

`python tools/verify.py` prints PASS: 1721 asserts, 391 input cases, 0 failed.
`exports` is still the one SKIP and still wants the Godot export templates.

## 0055 - Double speed and skipping the night

The property this task exists to prove is that **speed is not part of the
simulation**, and the clearest evidence is in the guards: the sim hash did not
move. Ticks per frame, never a changed tick rate, so a night watched at 4x, a
night watched at 1x and a night skipped outright are the same night.

    a night watched: 1375 ticks. Skipped: 1375. Hash 1834013722 against 1834013722

`Sim.skip_night()` is `tick()` in a loop until the night is over - the player
skips the watching, not the game the simulating - which is why that line reads
the way it does and why the done-when could be asserted rather than argued.
The same claim is made twice more: four hundred ticks one at a time against a
hundred lots of four, and a 4x night against a 1x one, both to the hash.

Skipping is refused under half a house, because that night is the game: a
flare or a barricade in the right second is the whole of what the night is
for, and letting it be skipped would let the player skip the only interesting
part. The refusal says which, so the read-out can explain itself.

### Four ticks of the worst frame the game has

    a full farm at 4x: 5223 us a frame against a 33333 us budget
      (80 zombies, 1305.7 us a tick)

Measured on a hundred zombies in a maze with walls coming down, not on a quiet
farm: the first version of that assert printed "0 zombies" beside its number,
which is four times nothing.

### The buttons that could not be pressed

`design.md`'s night mock has `[REPARAR] [HABILIDADE] [VELOCIDADE x2]` along
the bottom, so this task built two buttons there - and they could not be
clicked. Not the 31-pixel `Button` trap the project has hit twice before,
though that was there too and was fixed: after making them exactly the size
they claimed, and then building them identically to the night button four
pixels away, and then wrapping them in a `MOUSE_FILTER_STOP` frame the way
`BuildMode` does, a bare `Control` in that corner of `DayHud` still reported
no hover at all while `NightButton` beside it hovered perfectly. Six probes
did not explain it.

A button that cannot be pressed is worse than no button, so the night's
controls are **keys** - `V` and `K`, beside `N` for the night, `B` for build
and `F` for the flare - and what is on screen says so: `[V] SPEED 1x` and
`[K] SKIP`, with the skip line turning red and printing the reason when the
house is too low. That is `input_check`-testable, which the buttons were not.

**Task 0056 owns the night HUD.** If it wants a clickable bar it will be
designing that corner from scratch anyway, and this note is here so it knows
the trap is waiting.

### A setter that called itself

`var speed := 1: set = set_speed` with `speed = wanted` inside `set_speed` is
infinite recursion, and it cost twenty seconds of watchdog and a hunt through
the HUD before the stack trace pointed at the driver. `speed` is a plain field
with a `set_speed()` method now.

### Remembered

`gameplay/night_speed` was in `Settings.DEFAULTS` and unread. The driver reads
it on `start()` and writes it on every change, so the speed survives a night
and a restart. The test asserts it by closing the scene and opening another -
and had to be rewritten to set the speed by hand first, because it was
tripping over its own persistence.

### Hashes

| | from | to | why |
|---|---|---|---|
| sim hash | `2770152428` | `2770152428` | **unchanged, and that is the point** - speed and skipping add no rules |
| data hash | `2691269033` | `177116930` | `SKIP_MIN_HOUSE_PERCENT` is a lever, so it joined the digest |

`python tools/verify.py` prints PASS: 1745 asserts, 411 input cases, 0 failed.
`exports` is still the one SKIP and still wants the Godot export templates.

## 0056 - The night HUD

`design.md` section 14, on its own node: which night, which wave, how many are
left, how the house is doing, and the three controls the design draws along
the bottom - `[REPARAR] [HABILIDADE] [VELOCIDADE x2]`.

### The mouse mystery of 0055, solved

Task 0055 could not make a button work in the bottom-right corner of `DayHud`
and left the finding here. The answer was in `Main.tscn`: **`DayHud` is the
first child of `Screen`**, which puts it at the bottom of the UI's hit order,
and it carries `mouse_filter = 2` in the scene file as well as in its own
`_ready()`. `ShopPanel`, whose buttons have always worked, has no such line
and comes later.

So the night HUD is a sibling placed **after** the day HUD - above it in the
hit order - with its buttons inside a `MOUSE_FILTER_STOP` frame, the way
`BuildMode`'s palette already does it. All three controls are clicked in
`input_check` and all three do what they say. The speed control that 0055
could not click is one of them.

The thirty-one pixel `Button` trap was there too, for the third time after
tasks 0032 and 0040, and is fixed the same way: styleboxes with the vertical
content margins taken out. `input_check` now asserts that **every** control on
the night HUD is inside 480x270 and is not taller than 24 pixels, so the
fourth time will be a red test rather than a hunt.

### The three controls take the same road as the keys

`REPAIR` writes `intent["interact"]`, `FLARE` writes `intent["ability"]`, and
the speed button asks the driver. None of them touches the state, so a button,
a key and the autoplayer of task 0067 all arrive at the rules the same way.

They also say what they are: repair goes dim unless the cell the player faces
can actually be mended, and the flare shows its own wait as a percentage
instead of a bare refusal.

### Impossible to miss

The house bar is the biggest thing on the bar, and under
`HOUSE_DANGER_PERCENT` it turns red **and pulses at half a second**, because a
colour change alone is something you can be looking away from. The lever sits
deliberately above `SKIP_MIN_HOUSE_PERCENT`: the warning has to arrive before
the night stops being skippable, or the first a player knows of trouble is a
control going dead. `headless_check` asserts that ordering rather than trusting
two numbers to stay on the right side of each other.

An incoming wave is announced four seconds out with the seconds on it, so the
player knows whether there is time to mend the wall first. `Waves` gained
`incoming_in()` for it, which answers the gap **before** a wave rather than
the space between two of its members - one field carries both, and the
difference is whether anything is still waiting to be sent.

### What it deliberately does not own

The power and ammunition lines stay on the day HUD. They have been up in both
phases since task 0033 and their comments say why; moving them would have
given two panels an opinion about the same number, which is what "sharing no
state" is actually guarding against. Two existing input cases assert they are
up at night, and they still are.

### Hashes

| | from | to | why |
|---|---|---|---|
| sim hash | `2770152428` | `2770152428` | **unchanged** - a HUD that moved the sim hash would be a HUD writing to the state |
| data hash | `177116930` | `1839419045` | `HOUSE_DANGER_PERCENT` and `WAVE_WARNING_TICKS` are levers, so they joined the digest |

`python tools/verify.py` prints PASS: 1753 asserts, 463 input cases, 0 failed.
`exports` is still the one SKIP and still wants the Godot export templates.

## 0057 - Structures take damage and die

### Repairing was seven to fifty-six times dearer than rebuilding

The requirement is "a repair cost that is cheaper than rebuilding, so
repairing is the right move". It was the opposite, for every structure in the
game, and not marginally:

| | build | hit points | repair, old rule |
|---|---|---|---|
| wall | $30 | 120 | $1680 |
| fence | $10 | 30 | $420 |
| gun tower | $125 | 60 | $840 |
| mortar | $665 | 55 | $770 |

`REPAIR_COST_PER_HP` was one food and one wood **per hit point**, and food is
the most valuable thing on the farm after oil. A flat price per hit point
cannot work across a four-wood barricade and a thirty-stone mortar: the only
rule that scales is **a share of what the thing cost**, in its own materials.

So a wall is mended with stone and a tower with iron, at `REPAIR_PERCENT` -
half - of building a new one, in proportion to how much is missing. The
dearest repair on the farm is now 50% of building new, which the test asserts
for every structure rather than for the one I happened to check.

The house keeps the old rule, and that is the point: it has no build cost to
take a share of, and `design.md`'s resource table gives food the night's
"cura/reparo" job. Food repairs the thing that ends the run; a wall is
carpentry.

### The slate

Four hundredths of a stone per hit point is not a payment. The cost is kept in
hundredths and banked, and a whole stone leaves the ledger when one falls due -
the same arrangement `Farming` uses for watering, so the rate stays what the
designer set rather than whatever integer division left of it. Every structure
costs **at least one hundredth** a hit point, because a wall that was free to
hold would make a night a contest of patience rather than of resources.

### Nothing dangles

`state["crafting"]` is keyed by station cell. A workshop that fell with a job
running left that job in the state for ever - the inputs spent, nothing ever
delivered, and a new workshop on the same cell inheriting a queue it never
started. `Farm.remove()` now calls `forget_cell()`, one door for everything
keyed to a cell, and `Crafting` drops both the queue and the production record
through it. The inputs are **not** refunded: they went in when the job
started, and a player paid for losing a building would be being paid for
losing a building.

### Rubble is a mark, not an obstacle

It is not an occupant. Rubble that occupied its cell would be a wall the
zombies could not walk through and the player could not build on - a broken
wall doing the job of a whole one. It is a separate map from cell to what used
to stand there, the view draws it as a smudge, `Phases.begin_day()` sweeps it,
and nothing else in the game reads it.

### Measured

    the dearest repair on the farm is 50% of building new
    a wall falling: the way in cost 47, and 27 on the tick it fell
    after a night that took 4 structures: 6 left standing, 0 rubble swept, house at 100
    a wall under a walker: 293 ticks on its own, 839 with somebody mending it
      (1036 hundredths of stone)

The wall-falling line needed the assert rewritten. "Destroying a wall mid-wave
reroutes the zombies the same tick" turned out to be the wrong question: they
were already routing *through* that cell, because task 0049 made a wall a
price rather than a hole. Knocking it out does not move them, it makes the way
they were already taking free - 47 down to 27 - and stops them having to chew
to use it. That is what the assert says now.

A tower at one hit point is still a tower: it is in the firing list, it still
draws its power, and it still shoots. It just looks terrible, which is the
other half of the done-when - below three quarters of its hit points a
structure is tinted darker and redder the closer it is to going, as a tint
rather than eight more ASCII maps to keep in step.

### Hashes

| | from | to | why |
|---|---|---|---|
| sim hash | `2770152428` | `694966054` | the state gained the repair slate and the rubble map, and a destroyed structure now clears what was keyed to its cell |
| data hash | `1839419045` | `158064256` | `REPAIR_PERCENT` is a lever, so it joined the digest |

`python tools/verify.py` prints PASS: 1814 asserts, 463 input cases, 0 failed.
`exports` is still the one SKIP and still wants the Godot export templates.

## 0058 - The Giant

Nine hundred hit points, fifty ticks a tile, six armour, four hundred percent
against anything it walks into, and the only `is_boss` in the table. The
numbers were all there; what the Giant did not have was the two fields nothing
read - `telegraph_ticks` and `is_boss`.

### One readable telegraph

An enemy with `telegraph_ticks` winds up the first time it swings at
something: thirty ticks of standing there, measured, before a wall loses a hit
point. Only the Giant has one, and it is the difference between a wall
vanishing and a wall you were given a second to do something about.

**It costs the swing nothing.** The wind-up is the front of the first wait
rather than an extra one, so blows still land on `ticks_per_tile` and what the
tell buys is that the first is seen coming. A boss that hit more slowly for
having a tell would be a boss you would rather it did not have.

After a blow it goes straight into winding up the next, which the assert
originally denied and was wrong about. The tell is continuous while it is
working on one thing, so the player's question is never "is it about to swing"
but "how long have I got" - and that is the better question.

### Measured

    a giant swings after 30 ticks of wind-up; the lever says 30
    a giant against 16 crossbows ($2720): got in with 130 hp left.
      Against 4 mortars ($2660): killed in 1147 ticks
    a mixed defence ($3340) kills it in 845 ticks, 406 before it would have
      reached the house (13.5s of room)
    sealed in with wall: the giant got in after 1284 ticks
    sealed in with gun_tower: the giant got in after 1284 ticks

The middle line is the requirement, and it is the shape task 0051 could not
find for the tank: **the same money, opposite outcomes, and the concentrated
build is the cheaper one.** Sixteen crossbows cost more than four mortars and
lose; four mortars kill it with a hundred ticks in hand. Armour six floors a
five-damage bolt at the minimum hit, so a crossbow line is paying for rate it
cannot use - which is the sentence the tank was supposed to write and the
Giant actually does.

A crossbow line *can* beat it with enough of them: twenty ($3400) kill it in
889 ticks. It costs more than the mixed build and leaves less room, which is
the right shape for "cheap towers are not the answer" rather than "cheap
towers are forbidden".

### No softlock, either way round

Walled in behind a full column it ploughs through, because task 0049 priced
walls. Ringed by gun towers - which declare no path cost and are holes in the
map - it falls through to the sealed-in chew that task 0046 put there. Both
end with it in the house at 1284 ticks and neither ends with it standing
still, which is the done-when.

### What 0066 gets

`Combat` counts `bosses_down` and can name the boss on the farm. The night HUD
puts a bar and a name up for it, flashing while it winds up, so the second the
telegraph buys is a second the player can see. Ending the run on that number
is task 0066's job, and the number is waiting for it.

### Hashes

| | from | to | why |
|---|---|---|---|
| sim hash | `694966054` | `2087687126` | the state gained `bosses_down`, and a telegraphing enemy's first blow lands thirty ticks later than it used to |
| data hash | `158064256` | `158064256` | **unchanged** - no lever moved, the two that had been sitting there are simply read now |

`python tools/verify.py` prints PASS: 1857 asserts, 463 input cases, 0 failed.
`exports` is still the one SKIP and still wants the Godot export templates.

## 0059 - Waves as data

A night was a bare list of rows and every row carried `WAVE_GAP_TICKS`. It is
a record now:

```gdscript
{
    "note": "the first runner",
    "opening_ticks": 0,
    "gap_ticks": WAVE_GAP_TICKS,
    "waves": [[&"walker", 6, 0], [&"runner", 3, 1], ...],
}
```

The two numbers a designer most wants to turn - how long before the first wave
and how long between them - now live on the night they belong to. Under the
old shape, changing the pace of a night meant editing every one of its rows
and hoping none were missed; thirty-four rows carried that constant. A wave
that wants a different pace still says so, in an optional fourth entry, so
nothing was taken away.

`note` is not decoration: it is what the summary prints, and it is the line
that says what each night is *for*.

### The sim hash did not move

Which is the whole claim of a data refactor, and the reason to be pleased with
this one. The nights send exactly the same things at exactly the same ticks;
only the shape a designer types changed.

### Validated loudly

`check_nights()` used to check two things. It now refuses a night that is not
a record, one missing any of its four fields, one that sends nothing, a wave
that is not `(enemy, count, spawn)` with an optional delay, an unknown enemy
id, a wave of nobody, a spawn point that is not on the map, and time running
backwards. Every one of those has an assert that feeds it a bad table and
checks the complaint comes back - including the done-when's typo, where the
assert also checks the message **names the typo** rather than just the night.

### Computable without running it

`Waves` answers `size_of`, `reward_of`, `kinds_of`, `spawns_of`, `note_for`
and `summary_of` off the table alone. The test proves they are not merely
plausible: it runs night one with a house that cannot fall, counts what
actually turned up, and asserts the table predicted it kind for kind, count
for count, spawn for spawn, and dollar for dollar.

### The summary

`python tools/nights.py`:

```
  night  1   3 waves   12 enemies  $36    from [0]  12 walker  - the tutorial night
  night  5   4 waves   17 enemies  $84    from [0, 1]  6 runner, 3 tank, 8 walker  - the first tank
  night 10   4 waves   39 enemies  $274   from [0, 1]  8 breaker, 1 giant, 30 walker  - the Giant

  290 enemies over 10 nights, worth $1369
  first seen: breaker on 7, giant on 10, runner on 3, tank on 5, walker on 1
```

...and a bar chart of the count curve, which already shows what task 0060 has
to fix: nights 5, 7 and 10 dip in raw numbers because they trade count for
heavier enemies, so the curve reads as a sawtooth rather than a climb. That is
0060's job and it now has the instrument to do it with.

The "one new thing a night" rule of `design.md` section 10 is asserted rather
than hoped for: no night introduces more than one kind, every kind in the
table turns up, and the Giant is on the last one.

### Nine tests were reading the table directly

Four in `headless_check` reached into `GameData.NIGHTS[n]` as an array. They
go through `Waves` now, which is what the module is for - and is why the
refactor was worth doing where it was rather than at 0060 with the authoring
on top of it.

### Hashes

| | from | to | why |
|---|---|---|---|
| sim hash | `2087687126` | `2087687126` | **unchanged** - the same nights, sent the same way |
| data hash | `158064256` | `2743853196` | `NIGHTS` is a different shape, with the same content in it |

`python tools/verify.py` prints PASS: 2022 asserts, 463 input cases, 0 failed.
`exports` is still the one SKIP and still wants the Godot export templates.

## 0060 - The ten nights, authored

### The curves, as numbers

| night | sent | $reward | hit points to kill | gap |
|---|---|---|---|---|
| 1 | 12 | 36 | 240 | 15s |
| 2 | 20 | 60 | 400 | 15s |
| 3 | 24 | 78 | 420 | 14s |
| 4 | 40 | 138 | 620 | 14s |
| 5 | 41 | 164 | 980 | 13s |
| 6 | 48 | 214 | 1400 | 13s |
| 7 | 54 | 254 | 1520 | 9s |
| 8 | 69 | 342 | 2030 | 8s |
| 9 | 80 | 416 | 2560 | 6s |
| 10 | 85 | 540 | 3470 | 4s |

All three climb, every night, which the old table did not: it dipped on four
of the ten. **Hit points to kill is the honest measure** of a night's size -
three tanks are not three walkers - and it is what the dips were hiding.

The gap is a second curve under the first: fifteen seconds of room down to
four. The same crowd arriving with less breathing space is a harder crowd, and
it is the cheapest difficulty there is because it costs no extra enemies.

Section 10 exactly: walker on 1, runner on 3, tank on 5, breaker on 7, Giant
on 10 - and **the night after each arrival sends more of it than the night it
arrived**, which is asserted rather than eyeballed. A player meets a new
problem while they can still afford to get it wrong and is examined on it when
they cannot.

### Two instruments

`python tools/nights.py` reads the table. `python tools/play_nights.py` plays
all ten with a scripted build that never farms, never repairs, never drops a
barricade and never fires a flare, and says which fell - the floor, not a
player.

Its build comes out of a **purse**: what the previous nights paid, plus a
farming allowance. Writing it that way turned up the most important thing this
task learned.

### The farming allowance is most of the answer

At $300 a day, two thirds of the purse by night ten is that one made-up
number. So the tool sweeps three:

| a day of farming | what fell |
|---|---|
| $0 | nights 2 through 9 - only the tutorial survives |
| $150 | nights 3 and 10 |
| $300 | nothing |

That is the shape the game wants at the middle row: **night ten falls to a
player who only builds**, which is the requirement that it needs the tech tree
(tasks 0063 and 0064), and farming is not optional, which is the premise of
the game.

It is also the honest limit of this task. The real number is measured by the
autoplayer at 0067 and the curve is settled against it at 0068; authoring
against a guess and calling it balanced would have been the wrong kind of
confident. The sweep is in the tool so that whoever does 0068 sees the
sensitivity rather than inheriting my constant.

Night 3 was softened from ten runners to six along the way: at ten it was the
hardest of the first five, so the night that *introduces* the runner killed
you while night four, the one meant to examine you on it, held comfortably.
An introduction that kills you is not an introduction.

### An eight-breaker softlock, and it had been there all along

Nights 7, 8 and 9 never ended. Eight breakers stood at (14, 9) for fifty-six
thousand ticks chewing the workshop, and the workshop never lost a hit point.

`FARM_MAP` places occupants as `{"id": ...}` with **no hit points at all**, so
`Farm.damage()` read zero, refused to take anything off, and the breakers
never finished. `BUILDINGS` had never declared `hp` either - task 0049 noticed
that and left it, because nothing could damage a building then. Task 0052 gave
breakers a reason to try, and this is the bill for it.

Both ends are closed: map-placed occupants get the hit points their table
declares, the four buildings declare some, and `Pathing.prey_cells()` refuses
to lead anybody to a cell with no hit points on it. The second is belt as well
as braces - if anything else ever appears without them, the hunt field simply
will not send a breaker to stand in front of it.

### Four asserts that were over-claiming

All four went red on a real fix rather than a regression, and all four are
now narrower and truer:

- The ammunition fixture fought night seven, which gained breakers and a
  nine-second gap. It fights night five with four gun towers now - guns need
  no powder, which was always this fixture's own point.
- Task 0052's "the house takes nothing while there is a tower standing" is
  false now that the workshop can be eaten. What holds is the ordering: the
  towers take more than the house does.
- Task 0057's ruined night sent twenty-four breakers at four towers, which is
  not a bad night, it is the end of the run. Twelve, so the subject is the
  morning after.

### Hashes

| | from | to | why |
|---|---|---|---|
| sim hash | `2087687126` | `893100662` | the farm starts with a workshop that has hit points, and nights are authored differently |
| data hash | `2743853196` | `543765201` | ten re-authored nights and four buildings that declare hit points |

`python tools/verify.py` prints PASS: 2135 asserts, 463 input cases, 0 failed.
`exports` is still the one SKIP and still wants the Godot export templates.

## 0061 - Night rewards

Most of this was built early. What it did not have was the thing its own
requirement asks for: **"a bonus for structures that survived intact"** was
paid per structure still *upright*, so a wall at one hit point earned exactly
what a wall nobody touched earned, and "defending well pays more than barely
holding" was not true of the code.

It is now paid per structure that came through **without a scratch**, with a
smaller `standing_structure_bonus` for the ones that took damage and held
anyway - so a hard-won night is still worth more than a quiet one, without
being worth as much as a clean one.

    six towers untouched pays $94; the same six all damaged pays $76

Same seed, same night, same kills, same number left standing: the eighteen
dollars is exactly six times the difference between the two bonuses, which is
what the assert checks rather than just "more".

### The money says where it came from

    { "for the night": 45, "bounty": 0, "nothing touched": 8,
      "still standing": 2, "the house untouched": 25 }

`design.md` section 12 itemises the payout and the file's own header said the
list exists so the screen can say *why* - but money was one lump, so it could
not. `_money_from()` is the one place that knows now, and the total is that
dictionary added up, so the lines and the total cannot drift apart.

The screen shows one headline row - "for defending well + $32" - rather than
all five. **A `Label` reserves its font's line height** the way a `Button`
reserves thirty-one pixels, so each row is twenty-two pixels whatever it
claims; seven of them grew the result frame to 269 pixels and pushed "back to
the farm" off the bottom of the screen, which ended the run. That is the
fourth member of this family after tasks 0032, 0040 and 0055, and the first
one on a `Label`.

### Three more unread levers

- `DEFEAT_RESOURCE_LOSS` was `0.25` - the eighth fraction found this way. It
  is `DEFEAT_LOSS_PERCENT` at 25 now.
- `DEFEAT_KEEPS_MONEY` and `DEFEAT_KEEPS_TECH` had been declared with the
  table and read by nothing: `Rewards` skipped money *by name* and energy by
  accident, so turning either lever off would have changed nothing at all.
  Both are read now, and energy is skipped for a stated reason - it is a rate,
  not a stock, so there is nothing to take.

`tech_points` is still unread, deliberately: task 0062 owns "one point per
night survived, plus bonus points" word for word, and half-paying it here
would have been taking its work rather than doing mine. `_is_tech()` is
waiting for the resource 0062 adds.

### Hashes

| | from | to | why |
|---|---|---|---|
| sim hash | `893100662` | `1987400090` | the payout in the state carries the money breakdown and the intact count |
| data hash | `543765201` | `1743728276` | a new standing bonus, and the defeat fraction became a percentage |

`python tools/verify.py` prints PASS: 2168 asserts, 463 input cases, 0 failed.
`exports` is still the one SKIP and still wants the Godot export templates.

## 0062 - Technology points

    technology: 10 at worst, 40 at best (1 a night, then house untouched +1,
      nothing lost +1, not one got through +1)

That line is the answer to "the total available across ten nights is fixed and
known - print it", and it is the budget task 0063 has to price the tech tree
against. `python tools/nights.py` prints it beside the enemy and money curves.

### A resource, on purpose

Technology goes through the same ledger as wood: saving it, showing it and
spending it are problems already solved, and `Rewards._is_tech()` has been
waiting for the name since task 0061. It is in a resource group like
everything else and has **no sell price**, which is what stops it being a
thing you trade.

### The bonuses are conditions in a table

`TECH_BONUSES` says what is worth an extra point and `Tech._earned()` has one
arm per `id`, with a `push_error` for a row nobody has implemented - because a
bonus that silently never pays is worse than a bonus that does not exist.

    a perfect night pays { "for surviving": 1, "house untouched": 1,
      "nothing lost": 1, "not one got through": 1 }
    a night that cost the house and a wall pays { "for surviving": 1 }

Four against one. Playing well is worth technology as well as money, and
adding a fourth way to earn a point is a table entry rather than a rule.

### A night pays once

`nights_paid` remembers which nights have handed their points over, so
reloading a save from before a night you already beat cannot beat it again for
the technology. Money and resources are deliberately **not** protected this
way: replaying a night costs a real night of the ten and the ten are the run,
so the money takes care of itself. Technology is permanent, so it is the one
that has to be defended - and the test saves, reloads, and checks the
reloaded run cannot re-earn the night it was saved after.

    ten nights played perfectly: 40 technology. Ten played badly: 10

### The result screen, for the third time

Adding a technology line to the payout pushed "back to the farm" off the
bottom of the screen again - the same failure as task 0061 and for the same
reason: a `Label` reserves its font's line height whatever
`custom_minimum_size` says, so every row is twenty-two pixels.

Nudging the frame up twice was treating the symptom. The screen now says the
same things in half the rows - "killed 34, 2 got through" on one line,
materials on one line, money and technology on another - and **`input_check`
asserts that the continue button and the whole frame are inside 270 pixels**.
It is the only way out of that screen, so it going off the bottom does not
look like a layout bug, it looks like the run ending.

### Hashes

| | from | to | why |
|---|---|---|---|
| sim hash | `1987400090` | `1638064280` | the state gained a technology balance and the record of which nights have paid |
| data hash | `1743728276` | `1475198535` | a new resource, a new group member and the bonus table |

`python tools/verify.py` prints PASS: 2204 asserts, 468 input cases, 0 failed.
`exports` is still the one SKIP and still wants the Godot export templates.

## 0063 - The tech tree

    the whole tree costs 45; ten nights pay 40 at best and 10 at worst
    a whole branch costs 15, so a good run takes two and a bit

Twelve nodes, three branches, four deep, priced so that **every node is
reachable inside ten nights and not all of them are** - which is the done-when
and is the only thing that makes the choice a choice. The test walks every
node's chain of prerequisites and checks the whole chain is affordable, then
checks the three branches together are not.

### Which branch I would take, and why

**Defence, then survival.** The tree hands out numbers the rules already read,
so the three branches are comparable:

| branch | what the four give |
|---|---|
| production | chopping 30% faster, +4 water, crafting 35% faster, +25% on sales |
| defence | +20% tower damage, +1 range, −20% reload, −25% tower cost |
| survival | +40 house, −40% repair, +3 barricades a night, flare at 55% |

Production compounds - it is the only branch that makes the *next* branch
affordable - so on paper it is the greedy first pick. It is the wrong one.
Task 0060 measured what actually kills a run: nights 3 and 10 at a middling
income, and both are lost to **throughput**, not to poverty. `true sights` and
`long barrels` cost five points together and are worth more than a fifth of
every tower's damage, because range is time and time is more shots.

Survival second, because `stout timbers` is two points for forty percent more
house and it is the cheapest node in the tree by what it saves. Production
last, and only what is left over: a farm that is not standing sells nothing.

If the run is going well by night five, that reverses - the money branch pays
for towers the defence branch then improves - and that is the tree working.

### The effects are numbers the rules already read

`Tech.bonus(state, key, missing)` is the one door. `Towers` asks what
`tower_damage_percent` is worth and does not know a tree exists; the tree
hands out numbers and does not know what a tower is. Nine of the twelve are
wired that way through their owning system - towers, the house, repair,
barricades, the flare, chopping, the watering can - and `check` holds one key
to one node, because `bonus()` answers with the first node that mentions a key
and two claiming the same number would leave one silently doing nothing.

`tower_cost_percent`, `craft_percent` and `sell_percent` hand their numbers
out but nothing asks yet: cost is threaded through `Building.cost_of()` which
has no state to ask with, and the other two belong to systems task 0064 is
about to reopen. The nodes are bought and owned; what they are worth arrives
with the task that owns those call sites.

### Refundable, for a fee

`TECH_REFUND_PERCENT` at 50. A player who spent six points on the wrong branch
on night three should not live with it for seven nights, and one who can
re-cut the whole tree between waves is not choosing. Selling back is refused
while something you own still needs the node, so the tree cannot be left
hanging off nothing.

### A `Button` sizes itself to its text

Fifth member of this family, after 0032, 0040, 0055 and 0061. "the flare comes
back in a little over half the time" made a node button a hundred and
ninety-three pixels wide and pushed the survival column off a
four-hundred-and-eighty pixel screen - `custom_minimum_size` is a *minimum*,
and the text wins. The buttons are clipped to name and cost now, the sentence
moved to a line under the tree, and `input_check` asserts all twelve nodes are
inside 480x270.

### Hashes

| | from | to | why |
|---|---|---|---|
| sim hash | `1638064280` | `2915513296` | the state gained the list of nodes owned, and nine systems now ask the tree for a number |
| data hash | `1475198535` | `3501718695` | the tree and its refund lever joined the digest |

`python tools/verify.py` prints PASS: 2306 asserts, 502 input cases, 0 failed.
`exports` is still the one SKIP and still wants the Godot export templates.

## 0064 - Tower I, II, automatic

    a gun tower: 6 damage and 5 range at level one, 11 and 6 at three,
      shooting 2 at once
    over one night a level one gun tower killed 3; a level three killed 16,
      for $625 of upgrades
    a tower at half health upgraded: 60 of 120

Three levels per tower, each **an entry in a table laid over the tower's own
row**. A level three gun tower is `DEFENCES[&"gun_tower"]` with four numbers
changed, and `Building.entry_at()` is the one place that does the laying-over
- so `Towers` gets the upgraded answer without knowing levels exist, and a
fourth level would be a row in the table.

### What earns the word "automatic"

`targets` had been in the gun tower's row since the table was written and
nothing read it. It is what level three gives: a Torre Automatica picks a
second target with the first one excluded and shoots both, which is a
behaviour rather than a bigger number. Every tower's last level changes how it
works rather than only how much - the crossbow gets a second target too, the
mortar loses its minimum range (the thing that made it a decision rather than
a purchase), and the flamethrower's fire lasts twice as long. The test asserts
that for all four rather than for the one I happened to check.

### Gated by the tree, and paid for on the spot

Level two wants `true sights` and level three wants `oiled works` - the first
and third of the defence branch. That makes the branch task 0063's journal
recommended worth more than its own numbers, and it means upgrading is a thing
you unlock once and then pay for every time.

Upgrading also reads **`tower_cost_percent`**, which 0063 handed out and
nothing asked for because `cost_of()` has no state to ask with. An upgrade
does, so `a standing order` now makes every upgrade a quarter cheaper. One of
the three gaps that task left is closed; `craft_percent` and `sell_percent`
are still waiting for systems nobody has reopened.

### Hit points carry proportionally

A tower at half health that becomes a level three with more of them is still
at half health - 60 of 120. Upgrading is not a repair, and a player who could
mend a wall by upgrading it would never mend anything again.

### Visible, without waiting for art

One pip a level, above the tower. `_art_for()` asks for `gun_tower_lv2` first
and `_texture_for()` falls back to the plain name, so per-level art is a map
in `tools/sprite_maps.py` away and nothing in the view changes when it
arrives. Until then a row of small bright squares is legible at sixteen pixels
in a way a recoloured sprite is not, and a player can tell at a glance which
towers they have paid to improve.

### Middle click

The third thing you can do to a cell in build mode, beside left to place and
right to sell - three buttons rather than three modes. It writes
`build_upgrade` into the intent and the rules decide, which is the same road
the keyboard and the autoplayer take.

### Hashes

| | from | to | why |
|---|---|---|---|
| sim hash | `2915513296` | `1577582652` | a tower carries a level, and every tower now declares how many things it shoots at once |
| data hash | `3501718695` | `219894722` | the level table, and `targets` on the three towers that lacked it |

`python tools/verify.py` prints PASS: 2396 asserts, 502 input cases, 0 failed.
`exports` is still the one SKIP and still wants the Godot export templates.

## 0065 - Losing a night costs you

### Losing skipped the night instead of repeating it

The bug worth the task, and it had been there since phases were written.
`begin_night()` set the night from the day counter - "night 3 is the night at
the end of day 3", which reads well - and `enter_result()` advanced the day
whether the night was won or lost. So **losing night three sent the run on to
night four**, and a player could lose their way to the Giant without beating
anything.

`design.md` and the requirement both say a loss costs **a day**. A day passes
either way now, and a night is only got past by surviving it:
`state["nights_won"]` counts what the run has beaten and the night to fight is
that plus one. Losing gives you another morning and the same night.

Thirteen asserts went red at once, all of them fixtures that set
`state["night"]` by hand and then began the night - which now got night one
whatever they asked for. They say it the one way that works now, through
`_fight_night()`, which sets the nights behind it as well as the number.

### Measured

    losing took { wood: 103, stone: 101, iron: 100, food: 50 }
    after losing twice: { wood: 174, stone: 172, iron: 169 } left,
      night 5 again, 6 technology

A quarter of each, which is `DEFEAT_LOSS_PERCENT`, and the itemised list is
compared against the ledger both ways: every line on the list moved that much,
and **nothing moved that was not on the list**. Money and technology are
untouched, and the test checks there was some of each to take so that is a
rule rather than an empty purse.

Losing twice in a row leaves a farm that can still recover: the same night is
still there, on a morning, with somewhere to build and enough left to build a
tower with. That is the done-when, and "enough to build a tower" is the
measure that makes it mean something - a run that could not rebuild would be a
run that had ended.

### What was already right

Structures that fell stay fallen and ones that were only chewed are still
there, still hurt - task 0057's work, asserted here. The result screen says
exactly what was lost - task 0061's, compacted at 0062. The fraction, the
money and the technology are levers that 0061 made readable. This task's own
contribution is the day-versus-night fix and the asserts that hold all of it
to what the requirement actually says.

### Hashes

| | from | to | why |
|---|---|---|---|
| sim hash | `1577582652` | `3497456322` | the state counts nights won, and the night to fight comes off it |
| data hash | `219894722` | `219894722` | **unchanged** - no lever moved |

`python tools/verify.py` prints PASS: 2426 asserts, 502 input cases, 0 failed.
`exports` is still the one SKIP and still wants the Godot export templates.

## 0066 - Night 10 and the end of the run

**The MVP is complete here.**

    a whole run: 11 days, 10 nights won, 473 killed, 0 structures lost,
      house at 140
    the build that won: { auto_crossbow: 10, mortar: 3 }

Four hundred and seventy-three is every enemy the ten nights send. The test
plays the whole thing - the waves, the towers, the flow field, the Giant - and
asserts the run ends, the boss goes down, and there are more days than nights
because every night has a day in front of it.

### The summary is a lookup, and one number was lying

`killed` and `breaches` are cleared by `begin_night()` - a night that
inherited last night's count would start halfway through - so a run summary
built from them reported **the last night and called it a run**: 85 instead of
473. The assert that caught it was "with a few hundred zombies killed", which
is the sort of loose bound that only ever fires when something is properly
wrong. `Combat` and `Enemies` keep a run tally beside the night's now.

Everything else in the summary is genuinely a lookup - days lived, what was
gathered, what is standing - so there is no second ledger to disagree with the
first. The only thing `Run` adds to the state is the count of structures lost,
because the morning sweeps the rubble and the number would be gone by the end.

### Two doors

A beaten run offers a new farm or **endless**. `Run.go_endless()` sets the
flag and stops there: what night eleven is made of is task 0070's, and
`Waves.table()` already answers an empty list past the authored ten, so an
endless run arriving before 0070 is a quiet farm rather than a crash.

The run is written to the profile before either door - `runs_won`,
`best_night` and the summary - because a win that was not recorded is a win
the player did not have. Task 0069 fills in the rest of the profile.

---

## The question, answered honestly

> After surviving the first night, did you want to go back to the farm and
> improve? That is the success criterion of the entire MVP.

Task 0027 answered this with **"the pull is there and there is nothing to pull
towards"**, and listed four reasons. Here they are again, against what exists
now:

1. **"Improve only means another identical tower."** Four towers, three levels
   each, four barriers, mines, a twelve-node tree, and a defence that is a
   shape rather than a count - walls reroute, mortars need range, crossbows
   need power, breakers eat what you built. **Closed.**
2. **"No knife-edge."** Measured, at a middling farming income: night 1 holds
   at 10 of 100 with exactly the tower the tutorial gives you, night 2 at 20,
   night 6 at 10, night 10 at 45. Night 3 is lost outright by a player who
   only builds. That is the tension the design document asked for, and it is
   a number rather than an opinion. **Closed.**
3. **"A kill does not land."** Tasks 0077, 0085 and 0088 - sound, numbers,
   particles - are still ahead. **Open.**
4. **"The day is mostly walking."** Fishing, livestock, the press, the
   kitchen, the stall and the tree all landed, so there is more to do; but
   chopping is still holding a key, and the day is still the half with the
   fewest decisions per minute. **Half closed.**

So the honest answer is **yes, and with one large caveat.**

Yes, because the structure that makes a player go back to the farm is now
demonstrably there: three currencies that do three different jobs (money buys
tonight, materials build tonight, technology buys every night after it), a
first night you barely survive, a third night you lose if you did not farm,
and a loss that costs a day and gives the night back rather than ending the
run.

The caveat is that **I have measured this game, not played it.** Every claim
above is a number out of `headless_check`, `input_check`, `tools/nights.py` or
`tools/play_nights.py`. The scripted player in `play_nights.py` never farms,
never repairs, never drops a barricade and never fires a flare, and the
farming income that makes the curve work - $150 a day - is a **fixture I
invented**, not a measurement. What it is worth is exactly what task 0067's
autoplayer measures and task 0068's sweep settles.

And the half of the loop I can least speak for is the half the design document
cares most about: whether a day on the farm is *pleasant*. Walking, chopping,
planting, waiting for corn. A test can tell me the corn grows in the time the
lever says. It cannot tell me anybody wants to watch it.

That is not a reason to stop - it is what the next four tasks are for, and it
is why 0068 comes before the polish rather than after it. But this checkpoint
is supposed to be answered honestly, and the honest answer is that the loop's
**skeleton** is sound and measured, and its **feel** is still owed a human
playing it end to end.

---

### Hashes

| | from | to | why |
|---|---|---|---|
| sim hash | `3497456322` | `3890789334` | the state counts structures lost, kills and breaches for the whole run, and carries the endless flag |
| data hash | `219894722` | `219894722` | **unchanged** - no lever moved |

`python tools/verify.py` prints PASS: 2452 asserts, 502 input cases, 0 failed.
`exports` is still the one SKIP and still wants the Godot export templates.

## 0067 - The autoplayer

    policy     won  killed by      avg night  avg house  gathered
    balanced     0  night 8 (3x)        7.6        0.0      1607
    towers       0  night 7 (3x)        7.4        0.0      1544
    economy      0  night 4 (5x)        4.0        0.0       685
    walls        0  night 1 (5x)        1.0        0.0       290

    ALARM: no policy won a single run - the ten nights are unbeatable by
      anything this robot knows how to do

Four policies, each three lists and nothing else: what to go and get, what to
put up, which branch of the tree to walk. Nothing looks ahead, nothing reacts,
because **a clever robot measures the robot.**

### What it found, in order of how much it matters

**1. Day one could not build the tower the tutorial tells it to build.**

A whole day of mining nothing but ore yields **thirteen iron**; a gun tower
cost **fifteen**. Not by buying either - the stall wants $18 an iron and the
run starts with $25. There was exactly one line that worked: mine all day,
sell every stone you started with, and buy two iron. A tutorial night that
needs a perfect line is not a tutorial.

The iron was not the thing to change. `check_iron()` refused both of my first
two attempts - ore must be *slower per swing*, *worth less per pull* and
*scarcer to come back* than stone, and all three are right, because iron being
the hard one is the point. The wrong number was the tower: **twelve iron, not
fifteen**, so a first tower is a first day's mining.

Task 0060 measured "night 1 holds at 10 of 100 with the tower the tutorial
gives you" - and the fixture **gave itself that tower for free**. The
measurement was true and the premise was not. This is exactly what an
autoplayer is for.

**2. Two performance bugs, and the day tick is four and a half times faster.**

`Tutorial.tick()` cost **222 microseconds of every day tick** - seventy-two
percent of a day in which nothing was happening - because one of its arms
walks all seven hundred cells looking for a planted one, thirty times a
second, for a system whose own comment says it can only notice. It looks twice
a second now.

`Building.expire()` copied and **sorted every occupant on the farm** once a
tick to find the barricades among them: twenty-nine microseconds of an empty
farm. It keeps a list of the things that can expire, which is almost always
empty.

    a quiet day tick: 308 us -> 96.8 us -> 68.7 us

The whole test suite went from 212 seconds to 146 with those two.

**3. Nothing wins.** The alarm fires, and it is right to. A robot that never
repairs, never drops a barricade, never fires a flare and always prefers
another tower to a better one gets to night seven or eight and stops. That is
the honest floor of the ten nights, and it is the number task 0068 starts
from - not a failure of the curve, but the first real measurement of it.

The policies separate cleanly, which is the other thing the instrument is for:
walls-first dies on night one because walls do not kill, economy dies on night
four because a press is not a tower, and the two that buy guns get twice as
far. No dominant strategy - there is no strategy that wins at all yet.

### The two-minute budget, honestly

**Twenty runs take 111 seconds**, so a hundred take about nine minutes, not
two. The done-when asks for a hundred under two, and I have not met it.

The reason is arithmetic rather than sloppiness: a run is ten days and ten
nights of a thirty-hertz simulation - seventy-two thousand day ticks alone -
and a day tick is 68.7 microseconds after the two fixes above. That is 5.6
seconds a run, and the budget implies 1.2. Meeting it needs the tick an order
of magnitude cheaper, or a day that is not simulated in full, and the second
would stop the instrument measuring what a day is worth, which is the one
thing it was built to measure.

`python tools/autoplay.py 20` is the usable size. What would close the gap is
a profile pass over the night loop - which is task 0102's, and now has a
reason to exist beyond tidiness.

### What the robot is kinder about than a player

Walking is not counted. A real farmer spends a good part of a day crossing the
farm; the robot pays only the work. So every income above is a **ceiling**,
and a policy that only just survives is one a human would not have survived
with. That is written at the top of `autoplay.gd` so nobody reads these
numbers as a promise.

### Hashes

| | from | to | why |
|---|---|---|---|
| sim hash | `1842437134` | `2646847426` | the tutorial looks twice a second, barricades expire off a list, and a gun tower costs three less iron |
| data hash | `219894722` | `1509120177` | the tower's cost and the tutorial's new lever |

`python tools/verify.py` prints PASS: 2494 asserts, 502 input cases, 0 failed.
`exports` is still the one SKIP and still wants the Godot export templates.

## 0068 - A balance sweep over the ten nights

The written report is `implementation/BALANCE.md` and the tool is
`tools/balance.py`. This is the part that does not belong in a report: what
the task turned out to be about.

### It was supposed to be about levers and it was mostly about the instrument

The first measurement said nights 8, 9 and 10 were unwinnable by all four
policies. Every one of those zeroes was the autoplayer rather than the game,
and it took five separate fixes to find that out:

1. **A policy could not play its own plan.** The build step took the first
   entry it could *afford*, and a fence is always affordable - so `walls` laid
   **89 fences in three days**, never cut the wood for the gun tower at the
   top of its own list, and died on night 1 on every seed. A plan is a
   sequence now, walked with a cursor.
2. **Everything went in one pile.** `_room_for` scanned from x=18 and filled a
   column beside the house. The obvious fix - ring the house, put the next one
   where cover is thinnest - made it **much worse**: this map has two ways in,
   east and south, so an even ring guards the west where nobody walks. Every
   policy then died on night 1. It reads `GameData.SPAWNS` now and builds
   between the house and the approaches, taking them in turn.
3. **It stood in front of a mortar for six nights.** A mortar wants gunpowder,
   gunpowder is crafted, the robot could not craft - so it mined toward a
   thing it could never build and went into night 9 with three towers and
   **78 unspent iron**. Half-fixing it was instructive: the first version
   asked "is *nothing* here diggable" when the right question is "is
   *anything* here impossible".
4. **It never ran a press.** So it never made oil, so a generator had nothing
   to burn, so supply sat at `BASE_ENERGY` for ten nights while the draw
   climbed to 13 - a farm at 30% power, where seven towers are worth two.
   Unguarded, the fix was worse: the robot found the workshop the farm starts
   with and turned all twelve starting wood into fence kits on day one. It
   crafts only when there is nothing to build, and never with a material the
   next thing on the plan needs.
5. **Sheds took the towers' ground.** `economy` placed its press and kitchen
   on the best cells of the east approach, pushing its towers to the back. Two
   towers at full power killed five of twenty on night 2. Workshops go behind
   the house now, which is where a player puts them.

After those five, and with **no game lever touched**, `towers` went from dying
on night 8 to reaching night 10. That is the whole argument for not tuning the
game until the instrument is trusted.

### What actually moved: one lever

`UNPOWERED_PERCENT`, 25 to 50. Power is the binding constraint of the whole
game and it is close to invisible: `BASE_ENERGY` is 4, a gun tower draws 1 and
an auto-crossbow 3, so **the third thing a player builds browns out the farm**
- and `Power.scaled_ticks` slows *every* tower, so the fifth tower makes the
first four worse. Two runs with identical builds, differing only in supply:

| | two gun towers, night 2 |
|---|---|
| at 100% power | 17 killed, house 70 |
| at 80% power | 4 killed, house 0 |

A fifth of the power, three quarters of the defence. The floor at 50 leaves
the gate where it was and gives the cliff a bottom.

### The test suite caught a balance change

`BASE_ENERGY` 4 -> 6 was applied, measured well, and then reverted, because
`headless_check` went red on an assert written when the defences were
authored: the hungriest defence must draw more than half the base supply,
"hungry enough that two of them want a generator". At a base of 6 two
crossbows run free, and the farm-feeds-the-guns chain stops mattering until
night 6. That assert is a design promise and the number was quietly undoing
it. Best evidence yet for "a new rule ships with an assert".

### One dead lever, one that cannot be judged yet

- **`WAVE_GAP_TICKS` was dead.** Task 0059 moved the gap onto each night's
  record and wrote all ten out longhand, so no rule had read the global since.
  Proven twice: grep found no reader in `src/core/`, and the sweep turned it
  from 8 seconds to 30 - close to fourfold on the pace of every night -
  without changing one run of eighty. It is a default now:
  `Waves.delay_before()` falls back to it and nights 1 and 2 no longer restate
  it, so it means "the pace of an ordinary night" and does.
- **`money_per_night` is flat but is not called dead.** Money buys seeds and
  shop goods, and the autoplayer sows but has never opened the shop. A lever
  this robot cannot spend is one it cannot measure. It wants re-sweeping once
  the robot learns to buy.

### The seeds agree far more than they look like they should

Seeds 6700, 6701, 6702, 6710, 6800, 9000 and 9007 over three nights each
returned 1509 gathered and 47 killed, to the unit. Not a broken seed:
`FARM_MAP` authors the farm and `NIGHTS` authors the waves, so neither asks
the run's RNG anything, and what it does touch takes until the back half to
add up. `walls` does reach 8, 9 and 8 across seeds. It matters for reading any
of these numbers - eighty runs of eight seeds are not eighty independent
samples of the early game - and it is written into `BALANCE.md` and into the
assert that used to claim otherwise.

### Night one does not do what it says

A gun tower reaches 5 tiles, a walker crosses a tile in 20 ticks, so a walker
is in range for 100 ticks. The tower deals 6 a second. 100 ticks is 3.3
seconds and 3.3 x 6 is **20 - exactly one walker's hit points.** So one tower
kills one walker per wave however many are in it: 3 of 12 killed, 9 breaches,
house on 10 of 100. At `HOUSE_HP` 80 every policy dies on night 1.

The night's note says "one tower, one side, and time to watch" and the
walker's own table comment says "one tower holds it with room". Neither is
true. **Nothing was applied**, because both obvious candidates failed under
measurement: slowing the walker wrecks nights 7-8 (they linger into the next
wave, so the crowd overlaps), and the house's hit points only decide which
side of the cliff night 1 lands on. The honest candidates are the tower's
`range` or `reload_ticks`, neither swept here. It wants its own pass.

### The done-when is not met, and two thirds of it should not be

> No night has a win rate of 100% or 0% across every policy

The shipped curve is `100 83 75 75 75 75 75 58 0 0`, from
`100 75 75 75 75 75 62 0 0 0` before.

- **Night 1 is at 100% and should be.** It is the tutorial night. A tutorial
  night that kills a quarter of players is a worse game, not a better balanced
  one. The requirement is right about the middle of a run and wrong about its
  opening.
- **Nights 9 and 10 are at 0%**, and that one is a real failure - but it is
  still the instrument's. The answer the game is built around is the
  farm-to-oil-to-generator chain, and no policy's plan is built to fuel
  generators; `economy`, the policy that should be, dies earliest. Night 10
  cannot be judged until a policy plays the game's actual answer. Lowering it
  to make this line go green would be the exact mistake the rest of this entry
  is about.

Recorded the way 0051's unachievable done-when and 0067's budget were: the
measurement, why the target is not reachable as written, and what would reach
it.

### A note on the tools

`tools/balance.py` edits `game_data.gd`, runs the sweep and puts it back in a
`finally`. Two of them running at once both rewrite that file and neither
notices - which happened, the numbers looked plausible, and the only reason it
was caught was a process list. It takes a lock now and refuses to start on a
dirty tree.

`headless_check` went over its 120-second budget twice during this task: once
from the new group playing four whole runs, and once from `_room_for`
searching for ground before anyone asked the price. Both fixed, and the suite
is 85s.

### Hashes

| | from | to | why |
|---|---|---|---|
| sim hash | `2646847426` | `2646847426` | **unchanged.** Worth saying out loud: the brownout floor only bites below full supply and the determinism scenario never browns out, so a lever that reshapes the back half of the game moves nothing the guard watches |
| data hash | `1509120177` | `3910754709` | `UNPOWERED_PERCENT` 25 -> 50, and nights 1 and 2 no longer restate `gap_ticks` |

`python tools/verify.py` prints PASS: 2563 asserts, 502 input cases, 0 failed.
`exports` is still the one SKIP and still wants the Godot export templates.

## 0069 - Run statistics - done 2026-09-27

What changed: a new `src/core/stats.gd` that answers what the player did this
run and across every run, a `RECORDS` screen on **R** that puts the two side
by side, and an autosave at the end of every night so the lifetime numbers
survive a crash. Screenshot: `implementation/shots/0069-records.png`.

Files: `src/core/stats.gd` (new), `src/ui/stats_screen.gd` (new),
`src/core/state.gd`, `src/core/building.gd`, `src/core/run.gd`,
`src/ui/main.gd`, `scenes/Main.tscn`, `project.godot`,
`implementation/prompts/0092-main-menu.md`.

Verify: 2592 headless / 553 input / sim hash moved, see below.

### It reads; it does not keep a second ledger

Almost every number the task asks for was already being counted by whoever
does the thing. `Combat._kill()` has counted kills by kind since task 0066 -
its comment already said "the statistics of task 0069 hang off the same line"
- `Resources` keeps `gained`, `Run` keeps the rubble, `Phases` keeps the
nights won. `Stats.of_run()` reads those rather than counting them again. A
statistics module with its own tallies would be a second opinion about the
same facts, and the two would disagree the first time somebody touched one.

**One tally was genuinely missing**: how many things a run has built.
`Building` counts `placed_tonight`, but it clears that every morning because
it exists to cap barricades, so nothing knew how many walls a run had put up.
That is the only counter this task added, and it hangs off the same line in
`Building.place()` that already counts the night's.

### Banking, which is what "written with the profile" means

The requirement is that the lifetime numbers are written with the profile and
not at the end of a run - a player who crashes on night nine should lose the
night, not the run. So `main.gd` folds and writes at the end of every night.

The obvious hazard is double counting: fold the same run in ten times and a
run that built five walls has built fifty. `Stats.fold()` keeps a ledger of
what it has already banked on the state itself, under `stats.banked`, and adds
only the difference. Folding twice in a row adds nothing the second time,
which is what makes it safe to call from a save. The ledger lives on the state
rather than in the profile because it is a fact about *this run*, and it has
to survive a save and reload with it - otherwise the night after a reload is
banked a second time. There is an assert for exactly that.

`Run.record()` now folds through the same door rather than writing lifetime
numbers of its own, so closing out a run that was banked every night adds
nothing again.

### Two things the task asked for that I could not do as written

- **"Reachable from the main menu."** There is no main menu: it is task 0092,
  and `main.gd`'s own header has said since task 0056 that 0091 and 0092 come
  later. So the way in is R, the same as the tech tree's T, and **0092's
  prompt has been edited** to carry the requirement - it already listed STATS
  as one of the router's states, and now it says the entry belongs there and
  that the key keeps working. Written down rather than quietly dropped.
- **"Quitting mid-run and returning keeps the run's numbers."** Nothing in the
  game called `Save.write_run()` at all before this task - task 0010 built the
  serialisation and only `headless_check` had ever used it. The night-end
  autosave above is the first real writer. The done-when is asserted as a
  save-and-reload round trip rather than by quitting a window.

### The screen

Two columns, `THIS RUN` and `ALL RUNS`, because the comparison is the feature:
a lifetime column barely larger than the run column is a player on their
second night, and one that dwarfs it is a player with a history. Kills by kind
get their own line at the bottom, since five enemy kinds will not fit in a
column.

It is **read-only, so it does not shut itself at dusk.** The tech tree does,
because it cannot be spent after dark; there is nothing here for a wave to
invalidate, and a player who wants to know how many runners they have killed
should be able to look while the runners are arriving.

It needed its own backing rectangle, which the tech tree does not. The tree
draws on a 0.88 shade and reads perfectly well because every node is a
`Button` with a filled stylebox behind its text; this screen is bare labels,
and on the same shade the farm and the wave counter came through the numbers.
Found by looking at the screenshot, which is the reason step 4 says to.

`input_check` asserts all twenty-one row labels are inside 480x270 - the sixth
member of that family after 0032, 0040, 0055, 0061 and 0063.

### Two asserts I wrote wrong

Both assumed a named cell would take a wall. `(20, 9)` did not, so the wall
never went up and the assert that followed was measuring a building that did
not exist - and it failed loudly rather than passing, which is the good
outcome. The test asks `Building.can_place()` where a wall fits now instead of
naming coordinates.

### Hashes

| | from | to | why |
|---|---|---|---|
| sim hash | `2646847426` | `2555959448` | **deliberate, and structural rather than behavioural.** `State.hash_of()` folds the whole state dictionary, so adopting a module moves it - every previous `_adopt` did the same. The only call on the sim path is `Stats.built()`, which writes two counters that nothing reads back; `grep -rn 'Stats\.' src/core/` is three lines and none of them is a decision |
| data hash | `3910754709` | `3910754709` | unchanged: no lever moved |

`python tools/verify.py` prints PASS: 2592 asserts, 553 input cases, 0 failed.
`exports` is still the one SKIP and still wants the Godot export templates.

Notes for next time: `runs_started` now climbs during `input_check`, because
every case opens `Main.tscn` and every boot counts a run. That is correct
behaviour and harmless, but it does mean the profile in `user://` is not a
clean-room number on a development machine.

## 0070 - Endless nights past ten - done 2026-09-27

What changed: a new `src/core/endless.gd` writes night eleven and everything
after it from a curve, and `Waves` hands one back wherever it used to hand
back nothing. `python tools/nights.py 30` now prints the generated nights
alongside the authored ten.

Files: `src/core/endless.gd` (new), `src/core/waves.gd`,
`src/core/game_data.gd`, `src/tools/nights.gd`, `tools/nights.py`,
`src/tools/headless_check.gd`, `src/tools/input_check.gd`.

Verify: 2873 headless / 561 input / sim hash unchanged, data hash moved.

`design.md` says nothing about endless - it is scoped to the authored ten - so
the shape here follows task 0070 and nothing else.

### The integration is one function

A generated night is exactly the record a person would have written: a note,
an opening delay, a gap, and a list of `[kind, count, spawn]`. So
`Waves.night_of()` returning a generated record past the tenth night is the
**whole** of it. `table`, `size_of`, `reward_of`, `kinds_of`, `spawns_of`,
`summary_of`, `delay_before` and the tick that sends them all carried on
without knowing, and not a line in `Enemies`, `Rewards`, `Towers` or the HUD
needed to hear about endless. `tools/nights.py` can print night 40 because it
already knew how to print a night.

The door into it already existed too: task 0066 built the `PLAY ON` button on
the ending screen, calling `Run.go_endless()`. "Off the critical path: a menu
option, not the default" was satisfied the day that button was written - `BACK
TO THE FARM` is the default and this is the second one, and it only appears
once the run has been beaten. Until today it led to a quiet farm.

### Seeded, and *not* from the run's stream

`Endless.night()` makes a fresh `Rng.create()` stream mixed from the run's
seed and the night number, and never touches the run's own. That is not
fastidiousness: `Waves.remaining()` is asked for the table **every tick** by
the night HUD, and a pure question that advanced the run's RNG would make a
night depend on how often somebody looked at the screen.

`RandomNumberGenerator` is banned in `src/core/` and this is not an exception
to that - `Rng.create()` hands back a plain four-word array, as saveable and
hashable as anything else, and this one simply is not kept.

### The curve fixes what comes; the seed fixes how it arrives

Two runs meeting night 25 meet the same crowd - 240 bodies, two Giants, the
same count of each kind - because that is the difficulty contract, and a night
that was harder on an unlucky seed would make "how far did you get" mean
nothing. The seed decides the **order**: which kind opens, how the heavy waves
interleave, which side starts. Thirty seeds of night 25 give twenty-one
different wave tables that all sum to the same thing.

A consequence worth writing down: `summary_of(25, a)` and `summary_of(25, b)`
print the same line, because a summary aggregates by kind. That is the summary
not being the place to look, not the seed doing nothing.

### Three things measurement changed my mind about

1. **A floor of one is not variety.** The mix drifts - the walker's weight
   falls, the tank's and breaker's rise - and I clamped each weight at one so
   nothing could drop out. Printing night 99 showed 992 bodies of which
   **one** was a walker, against 386 breakers. A kind that is one body in a
   thousand has left the game and taken a rounding error as a headstone. Added
   `mix_settles_after`: the drift runs for twenty nights and then stops, so
   night 99 is 110 walkers, 275 runners, 286 tanks and 321 breakers - a wall
   with everything still in it.
2. **Rolling each wave's side independently looked varied and was worse.**
   Night 20 came out with all seven waves on the east edge, which is a night
   half a farm answers. Every authored night from the second onward comes from
   both sides and this was not the place to take that back on a one-in-a-
   hundred roll. The sides alternate now and the seed only picks which starts.
3. **Which left the seed deciding almost nothing** - two seeds gave the same
   night 25 half the time, because the only thing left to choose was a coin
   flip. So the seed shuffles the order the kinds are dealt in, which changes
   the night's shape without touching its totals or its sides.

### Kept, not regenerated

`Waves.tonight(state)` builds the generated record once, when the night it
belongs to arrives, and puts it on the state - where it saves, loads and
hashes with everything else. Generating it per call would have been a wave
table sixty times a second for one answer, which is the mistake task 0025 paid
for in the flow field and task 0067 in the tutorial. There is an assert that
it survives a save unchanged and another that night 26 does not inherit night
25's table.

### An assert I wrote wrong

`expect(str(kinds_of(25, 700)) == str(kinds_of(25, 729)))` failed on two
tallies that were identical. `kinds_of()` fills its dictionary in wave order
and the seed shuffles that order, so the same numbers printed differently -
which is precisely the trap `State.hash_of()` sorts its keys to avoid, met
from the other end. It compares sorted keys and values now.

### Hashes

| | from | to | why |
|---|---|---|---|
| sim hash | `2555959448` | `2555959448` | unchanged, and correctly so: the determinism scenario never reaches night eleven, so no generated night is ever built in it |
| data hash | `3910754709` | `2601044827` | `GameData.ENDLESS` was added to `digest()`. **The generated nights are balance too**, and a curve outside the digest is eleven levers that could be turned without the guard noticing - which is the one thing the guard is for |

`GameData.validate()` now refuses a curve that names an enemy which does not
exist, that names a boss (the Giant arrives on `giant_every`; one rolled out
of the weighted bag would turn up on night eleven), or whose divisors are
zero.

`python tools/verify.py` prints PASS: 2873 asserts, 561 input cases, 0 failed.
`exports` is still the one SKIP and still wants the Godot export templates.

Notes: `tools/nights.py` takes `[how many nights] [seed]` now. Night 11 sends
95 against night 10's 85, night 25 sends 240 with two Giants, night 30 sends
292 with three. Whether any of that is *winnable* is not known - task 0068
recorded that no autoplayer policy has yet beaten night ten, and endless
inherits that open question rather than answering it.

## 0071 - The two palettes - done 2026-09-27

What changed: a relight shader on its own layer between the world and the HUD,
so the night ramp can do the three things a `CanvasModulate` cannot - lift,
drain and exempt. Screenshots: `implementation/shots/0071-day.png`,
`0071-night.png`, and `0071-against-the-sheet.png`, which is both of them
under the two halves of the reference sheet.

Files: `src/ui/relight.gdshader` (new), `src/ui/relight.gd` (new),
`src/ui/world_view.gd`, `scenes/Main.tscn`, `tools/palette.py`,
`tools/gen_sprites.py`, `src/ui/palette_data.gd` (generated),
`src/tools/headless_check.gd`, `src/tools/input_check.gd`.

Verify: 2922 headless / 572 input / **both hashes unchanged**, which for a
view-layer task is the result to want and is asserted rather than hoped for.

### What was already there, and what was not

The palette and the four ramps existed - sampled from the sheet, thirty-seven
colours, day/dawn/dusk/night. What did not exist was anything **reading** them:
`_TINT` went onto a `CanvasModulate` and `_LIFT`, `_SATURATION` and
`NIGHT_WARM_KEEP` had no reader in the game at all. The same declared-and-never-
read shape as `path_cost`, `ignores_structures`, `telegraph_ticks` and the rest
of that list, and the reason is the same: a multiply cannot apply any of them.

A multiply can only take light away. The sheet's night is *lifted* towards
purple - and purple is not less of anything a farm is painted in - and it is
*drained*, which is most of what makes moonlight read as moonlight rather than
as a blue bulb pointed at an afternoon.

### Dividing the tint back out

The warm exemption needs the colour a pixel had **before** the tint, and a
screen-space pass can only see the screen after it. So the shader is handed
the `CanvasModulate`'s colour and divides it out again. That is exact for
anything the multiply did not clip, which is everything: the tint is
per-channel and never zero.

Keeping the tint on the modulate rather than folding it into the shader also
meant the rest of the game - and five existing input asserts - carry on
reading `light.color` to know what the light is doing.

### Wheat is brighter than fire

The requirement is "fire, lamps and the moon are the only warm things at
night", and the threshold is a brightness. Sorted by brightness the palette
runs `bone` 0.880, `moon` 0.849, `flame_hot` 0.843 - and then **`gold_light`
at 0.722, which is wheat**, ahead of `flame` at 0.679.

So a threshold low enough to exempt the orange body of a flame also exempts a
cornfield, and the sheet's night corn is dark. **A screen-space pass cannot
tell a fire pixel from a wheat pixel when they are nearly the same colour**;
it can only ask how bright a thing is.

0.80 with a narrow edge lands in the gap: the hot core of a flame, the moon
and bone-white keep their colour, and the orange around that core is tinted
with everything else - which still reads as fire, because the core inside it
does not. The actual glow is task 0076's, which puts real lights where the
fires are and is the only thing that can tell them apart. There is an assert
naming every colour on each side of that threshold, because the next person to
turn the dial will not know the gap is there.

### Two things the screenshots caught

1. **Dawn was being lit as one-third night.** The first version worked out how
   far into the night the light was by measuring how much more blue than green
   its tint was. That is true of the night ramp and it is *also* true of dawn,
   because dawn is a cool light - so a farm at seven in the morning was drained
   to 90% and lifted towards purple, measured at 0.28 of the way into the
   night on the first screenshot taken. The ramp is computed from the phase and
   the hour now, which is the same question `_daylight_now()` was already
   answering for the tint, and is both simpler and correct.
2. **The first night tuning was flat.** Lift (0.10, 0.07, 0.20) and saturation
   0.62 produced one mid-purple with the grass, the paths and the jetty all at
   the same value. The sheet's night is not washed out, it is dark with deep
   shadows - so the lift came down until black was nearly black again and the
   saturation came up until grass was recognisably grass.

### Against the sheet, honestly

The two realities hold up: same farm, same shapes, warm to cool, and the white
things stay moonlit white so the farmer and the chickens are still findable.

What does **not** yet match is worth naming rather than glossing. The sheet's
night has deep black between bright pools of firelight, and mine is evenly lit
because there are no lights in it yet - that contrast is task 0076. The
sheet's day is goldener than mine because the sheet has a tileset of paths and
orchards and mine is mostly grass - that is tasks 0072 to 0075. **Neither gap
is a gap in the ramp**, which is the thing this task owns.

The night ramp is deliberately a shade darker than a night with no lights in
it wants to be. Every light 0076 hangs on a window or a brazier *adds*
brightness, and a global ramp tuned to read well on its own would be washed
out the moment they arrive.

### One flaky input case, and what I did not learn from it

`verify.py` reported one failed input case after this was otherwise finished,
and four later runs did not reproduce it. **Which assert failed was never
captured**, so there is no diagnosis here - only a decision.

The suspect assert was mine and was wrong on its own terms: it asked whether
the occupant count and the wood were unchanged six frames later, which asserts
that *nothing happens during a night*. A night takes structures apart; that is
what a night is for. It was also only catching the relight by accident.

It is replaced by the claim it was meant to make - **relighting the farm
changes nothing about the farm** - asked directly: read `State.hash_of()`,
relight hard twice with absurd values, read it again, with no `await` between
the readings so the tick cannot move underneath the question. That cannot
depend on timing at all, which closes the door whether or not it was the open
one. Four clean runs since, which is evidence and not proof, and is written
here as the former.

### A race in a test, not in the game

`view.skip_transition()` called on the same frame the phase changed is undone
on the next one: the view has not noticed the change yet, so it then starts a
fade it thinks is new. The ramp sat at 1.9% of the way into the night while
the tint was already being reported as the night's. The case waits for the
view to notice and then skips. Not a game bug - nobody can click faster than
the one frame it takes `_light_for_phase` to see a phase - but a test that
would have failed one run in three.

### Hashes

| | from | to | why |
|---|---|---|---|
| sim hash | `2555959448` | `2555959448` | unchanged. A relight that moved it would be `src/ui/` writing to the state, which is the thing the guard is for |
| data hash | `2601044827` | `2601044827` | unchanged. The ramps are in `src/ui/palette_data.gd`, not in `GameData`, because they are how the farm is *lit* and not what it is made of |

Both ramps are data in `tools/palette.py` and regenerate into
`palette_data.gd` without touching a sprite - `python tools/gen_sprites.py`
reported 38 of 39 files unchanged on every tuning pass, which is the
requirement met and visible.

`python tools/verify.py` prints PASS: 2922 asserts, 572 input cases, 0 failed.
`exports` is still the one SKIP and still wants the Godot export templates.

## 0072 - The farm tileset - done 2026-09-28

What changed: the terrain atlas became a grid instead of a strip, and gained
autotiled edges, a moving pond and four grasses. Screenshot:
`implementation/shots/0072-tileset.png`.

Files: `tools/sprite_maps.py`, `tools/gen_sprites.py`, `src/ui/world_view.gd`,
`sprites/terrain/atlas.png` (generated), `src/tools/headless_check.gd`,
`src/tools/input_check.gd`.

Verify: 4415 headless / 585 input / both hashes unchanged.

### Sixteen tiles from four maps

Autotiling normally means a forty-seven tile blob set, drawn by hand, and the
house rule here is that art comes from ASCII maps. Those two do not sit well
together: forty-seven hand-written 16x16 maps is not a tileset, it is a
second job.

So the generator composites instead. There are **four** maps per family -
`edge_n`, `edge_e`, `edge_s`, `edge_w` - and `edge_row()` lays the ones whose
bits are set over each other for each of the sixteen combinations. A cell with
grass to the north and the west gets the north map and the west map together,
which is a corner that nobody drew. Adding a fifth side would be a fifth map
rather than a new twenty-three.

The view builds the same four bits from the same four neighbours in the same
order, so the mask **is** the atlas column: no lookup table, and nothing to
keep in step. There is an assert that bit 0 draws on the north band and
nothing on the south, for each of the four, because a side map drawn a row too
low still composites, still looks like a tileset, and puts grass through the
middle of a path.

### Two edge rules that cannot both fire

- **Water draws its own bank** wherever it meets anything that is not water.
- **Everything that is neither grass nor water** gets grass drawn into it
  wherever grass is next door.
- **Grass draws nothing.** It is the background the rest is cut out of, so
  softening the patch and softening the meadow are the same job - and doing
  both would be doing it twice, on twice the tiles, with the seam still in the
  middle.

The farm lays 26 shoreline tiles and 88 grass edges. The map's border is not
an edge of anything: a neighbour off the grid counts as the same terrain, or
the whole rim of the farm would be fringed against nothing.

### The pond needed a row to itself

Godot takes an animated tile's frames from the tiles to its **right** in the
atlas, and to the right of the water in `Farm.Terrain` order is the rock. So
the animated water lives on its own row and `_base_tile()` sends water cells
there. The two frames after it must also not be tiles in their own right -
creating them takes the frames back and the pond stops moving with no error
anywhere - and there is an input assert for exactly that.

Measured rather than assumed: with the clock held still, 1633 blue pixels move
over forty frames and 47 others do. The first attempt to measure it reported
**zero**, and the reason is worth keeping: the daylight ramp walks across the
day, so two shots a second apart differ almost everywhere, and the first
version compared the wrong pair and then compared them without waiting for the
frame to be drawn.

### Four grasses, weighted

One tile repeated is a grid the eye finds in about a second. Four, picked off
the cell's own coordinates, so the field is the same field on every machine
and every run. **Weighted, not an even quarter**: the plain one takes more
than half or a field looks like confetti, and the one with a flower in it
turns up about one cell in thirty.

The flower was painted in `flame_hot` for about a minute. Task 0071 exempts
anything the palette drew brighter than 0.80 from the night ramp, and
`flame_hot` is 0.843 - so every flower on the farm would have been one of "the
only warm things at night", glowing in a field of blue grass. It is
`gold_light` at 0.722 now, which is what the wheat is drawn in and is under
the threshold. Caught by remembering the previous task rather than by a test,
which is the weakest way to catch something; the 0071 assert that names
`gold_light` as *not* exempt is what will catch it next time.

### What was already done

"Soil has a tilled and a watered variant" needed nothing: the plots layer has
drawn `tilled` and `tilled_wet` off `Farming`'s watered flag since task 0013.
Recorded here because the requirement reads like work and was not.

### The done-when

- **No visible seam anywhere on the farm.** Grass meets soil, path, rock and
  floor through a fringe, and water through a bank. Two non-grass terrains
  meeting - a path running into the stone yard - still meet on a straight
  line, and that is deliberate rather than missed: a stone floor meeting a
  dirt path has a crisp edge in life too, and the requirement names the three
  transitions that do not.
- **Regenerating produces byte-identical files.** `python tools/gen_sprites.py`
  twice in a row: 52 files, 0 written the second time, same md5. `--check`
  passes.

### Hashes

Both unchanged - `2555959448` and `2601044827`. This task is maps, a
generated PNG and a view; a tileset that moved either guard would be art
reaching into the rules.

`python tools/verify.py` prints PASS: 4415 asserts, 585 input cases, 0 failed.
The assert count jumps by about 1500 because the grass-variant check walks
every cell of the farm; it costs nothing measurable and it is the only way to
assert the distribution rather than the function.

`exports` is still the one SKIP and still wants the Godot export templates.

## 0073 - The player sprite - done 2026-09-28

What changed: the farmer the owner drew is now the farmer in the game. A new
`tools/cut_sheet.py` finds the frames on `docs/sprites_sem_fundo.png`, keys
out the glow and writes 42 PNGs; `PlayerArt` says which one to play and
`PlayerView` plays it. Screenshot: `implementation/shots/0073-player.png`.

Files: `tools/cut_sheet.py` (new), `src/ui/player_art.gd` (new),
`src/ui/player_frames.gd` (new, generated), `src/ui/player_view.gd`,
`tools/sprite_maps.py`, `tools/verify.py`, `src/tools/headless_check.gd`,
`src/tools/input_check.gd`.

Verify: 4804 headless / 596 input / both hashes unchanged.

### The size, and why

**48x52 canvas, the character about 44 pixels tall, over an unchanged 16 pixel
grid.** Two tiles wide and three tall.

The sheet is a painting - half a million distinct colours, frames about 90x150
- and the game is 480x270 on 16 pixel tiles where everything else is 16x16.
Those two cannot both be true, and the task named the three ways out:

- **Downscale to 16x24** and the drawing is gone. The owner drew a face, a
  hat brim, a pair of dungarees with a button on them; at 16x24 that is four
  brown pixels. The whole reason this task exists is that this art is better
  than an ASCII map would be.
- **Raise the game to 32 pixel tiles and 960x540** and every other sprite in
  the project is redrawn, plus the tileset that shipped two tasks ago.
- **Draw the player bigger than a tile**, which costs nothing else and is what
  Stardew does with the same problem.

The third. The canvas is a little wider and taller than the character so a
raised axe or a cast fishing line has somewhere to be without the farmer
shrinking to make room for it.

**This is also the one place art does not come from an ASCII map**, which the
house rules otherwise require and which task 0073 overrides in as many words.
Everything else in `sprites/` still comes from `tools/sprite_maps.py`,
including the shadow added here.

### Finding frames that are not on a grid

Rows of non-transparent pixels give the bands, columns within a band give the
frames, and a run much wider than its neighbours is two frames that touch.

**The splitting rule took two goes and the first one was quietly wrong.**
Version one split a wide run at its thinnest column, whichever column that
was. That cut the axe off the man swinging it: `chop_3` came out as a floating
axe and `fish_1` as a line and a float with nobody holding them. The frames
still looked like frames, which is what made it worth catching in a contact
sheet rather than in the game.

Measured, the difference is clean. Two poses that merely brush each other are
joined by four to seven pixels; a raised axe is joined to its owner by twelve
and a cast line by nine. So the test is the **thickness at the parting**
rather than the shape of the dip, and `JOIN_PX` is 8.

### One scale, and anchored by the feet

Every frame is scaled by the same factor, worked out once from the height of a
standing pose. Scaling each frame to fit its own box would make the farmer
grow and shrink as they swung.

They are placed by the **middle of the opaque pixels along the bottom** rather
than by the bounding box, because a raised tool moves the box a long way and
does not move the man. Anchoring on the box makes a farmer slide sideways
between two frames of one swing.

### What the sheet has and what it does not

All the side art faces **west**; there is no east-facing set, so east is the
west art mirrored. Determined by looking at the frames enlarged rather than
guessing - a first attempt to work it out from where the skin-coloured pixels
were failed, because it was finding hands as well as faces.

The verbs are drawn side-on too, so a farmer tilling while facing north is
drawn side-on. That is the sheet rather than a decision made here.

There is no workbench pose, so `craft` borrows the one empty-handed standing
frame, `reel` borrows the cast, `collect` borrows the lift, and `trade` and
`repair` borrow the craft. **All of them are named in `PlayerArt.VERBS`**
rather than falling through, because a verb that falls through to standing
still is indistinguishable from a verb somebody forgot - and there is an
assert that walks `Interact.DEFAULT_TICKS` and fails if any verb is missing or
resolves to an idle.

Bands 4 and 5 of the sheet - carrying crates, and a row of reactions
including a sleep and a heart - are cut but unused. `--report` lists them, so
they are a thing to spend rather than a thing lost.

### The shadow, and a test that lied to me

The shadow is an ASCII map like everything else, laid down at 0.42 alpha
because the palette has no partial alpha in it.

It appeared not to be drawing at all. I set its modulate to magenta, scaled it
three times and counted magenta pixels on screen: **zero**. That was the test
being wrong, not the shadow - `modulate` *multiplies*, and a near-black ink
sprite tinted magenta stays near-black. Toggling `visible` and counting
changed pixels found it immediately: 47 of them, drawing correctly the whole
time and simply too faint at the alpha I first picked.

Worth keeping because the wrong test pointed at a plausible culprit. The
codebase already documents a Y-sort trap in this exact node - "negative z
inside a Y-sorted parent put it behind the TileMapLayer" - and I spent a while
chasing it.

### An assert that was wrong about the rules

I wrote `expect(view.playing() == "chop")` while holding a direction, on the
reasoning that the rules stop a working farmer from moving so the drawing
should agree. The suite said `walk_west`.

The rules are the other way round, and say so plainly in `Player.tick()`:
"Walking away gives up on whatever was being done. Half a tree does not stay
half chopped in some invisible ledger." The assert now checks that, which is
the right way round for a test and a rule to disagree.

The other two failures in that case were mine too: `hold_key()` lets go before
it returns, so every question I asked after it was about a farmer who had
stopped walking.

### Hashes

Both unchanged - `2555959448` and `2601044827`. The animation reads
`Player.facing()` and the action verb and writes nothing; the frame counts are
generated into `src/ui/player_frames.gd` and the speeds live in the view, for
the reason task 0039 gives about the light - a purely visual number in the
data hash means a balance-neutral tweak fails the guard.

### A new row in verify

`player art` runs `python tools/cut_sheet.py --check`, so "re-running the
cutting tool produces byte-identical PNGs" is a fact rather than a hope. It
**skips without Pillow** rather than failing: the cut PNGs are committed, so
the game runs and the suite passes on a machine that has never installed it,
and only re-cutting needs it.

`python tools/verify.py` prints PASS: 4804 asserts, 596 input cases, 0 failed.
`exports` is still the one SKIP and still wants the Godot export templates.

## 0074 - Zombie sprites - done 2026-09-28

What changed: five enemies drawn as ASCII maps, a rim light derived from the
drawing rather than written into it, three more poses each derived from the
first, and a view that picks between them off the state.

Files: `tools/sprite_maps.py`, `tools/gen_sprites.py`, `src/ui/world_view.gd`,
`sprites/enemies/` (generated), `src/tools/headless_check.gd`,
`src/tools/input_check.gd`.

Verify: 4853 headless / 607 input / both hashes unchanged.

### The silhouette test

`implementation/shots/0074-silhouettes.png` - the five in colour above, the
same five in black below.

Upright and average, thrown forward, wide with no neck, lopsided with a slab,
and then something twice the size. **It is also an assert**, not only a
picture: each sprite is squashed into a 16x16 grid of "is anything drawn
here", which is a shape with its size and colour taken away, and every pair
has to differ in at least sixteen of the two hundred and fifty-six cells.

The closest pair is the Giant and the tank at 32 cells, which is right - they
are both wide and bulky, and what tells them apart is size. That is a separate
assert: the Giant is wider and taller than all four of the others.

The bar is deliberately low. Two zombies *should* both read as people, and a
bar high enough to force them apart would be a bar demanding five unrelated
animals.

### The rim light, and why it is derived

One line of `moon` down the right of each body. The trick is an agreement with
task 0071: the night ramp exempts anything the palette drew brighter than
0.80, and `moon` is 0.849 - so the rim keeps its own colour after dark while
the body goes blue with everything else. There is an assert that the rim's
brightness is above `NIGHT_WARM_KEEP`, because if somebody turns that
threshold up the enemies stop reading against the night and nothing else would
say so.

**It is applied by `gen_sprites.py`, not written into the maps**, and the first
attempt is why. I put an `m` at the end of each row of ASCII. A row of ASCII
does not know where the body is: the mark landed outside the figure where the
row was narrow and *inside* it where the row had a gap in the middle. The
walker wore a glowing stripe down its stomach and a second one hovering beside
its arm. The rightmost lit pixel of a row is a fact about the drawing and the
machine can find it every time.

### Three poses derived from one

The task wants a walk, an attack and a death for each of five, plus the
Giant's telegraph. Drawn by hand that is sixteen more maps, and sixteen maps
drawn to a deadline are sixteen mediocre maps. So:

- **walk_b** is the sprite a pixel higher - a bob rather than a stride.
  Universal, which matters: it works on the runner, which leans, and on the
  Giant, which is not shaped like a person. A leg-swap by mirroring the lower
  third would have broken both.
- **attack** is the top two thirds shifted along, reaching. Two pixels was
  invisible at three times zoom; four is a lean you can see.
- **death** is the sprite rotated flat. This is the one that looks deliberate
  rather than cheap - a body on the ground reads immediately.

**These are derivations and this is me saying so.** A hand-drawn stride reads
better than a bob and a hand-drawn slump better than a rotation. What they buy
is five enemies that all animate, consistently, from one drawing each, and if
the art ever matters more than that the maps are where to put the work and
nothing else has to change. The same argument as task 0072's edge tiles, which
are sixteen composited from four.

### The death nothing plays

`Combat._kill()` removes the entity on the tick it dies, so there is no moment
to draw a death in. The corpse is task 0077's - `Combat` has said so in a
comment since it was written - and `enemies/*_death.png` is waiting for it.
Written down here and asserted, rather than left as five files nobody looks
at.

### Two things that were quietly wrong

1. **Four of the five were purple blocks.** `_texture_for()` tested whether
   the whole name was a key of `GameData.ENEMIES`, and `_pose_of()` asks it
   for `walker_walk_b` and `giant_telegraph`. Neither is a kind, so every pose
   but the standing one fell through to the props directory and from there to
   the flat block that means "nobody drew this". The kind is the part before
   the first underscore.
2. **Enemies were drawn with their shins in the ground.** The view offset them
   half a tile back and up, which is right for a 16x16 sprite and wrong for a
   24x32 one. They are bottom-centred on their cell now, the same rule the
   player uses.

### A bug in my own screenshot tooling, twice

`var state := driver.state` taken before `Main._ready()` has run holds the
*empty* dictionary that `start()` then replaces - so every call on it fails
quietly on a missing key. That is why task 0072's night screenshot came out as
a day: `Phases.begin_preparation()` was erroring on a stale reference and the
shot was taken in daylight. The reference has to be taken after the frames.

### On scale

The enemies are 24x32 and the Giant 40x52, against the farmer's 44. That is a
deliberate consequence of task 0073: a 16x16 zombie beside a 44 pixel farmer
reads as a dog. **It does leave the rest of the farm looking small** - the
cow and the chickens are still one tile - and that is a real inconsistency
this task did not create and does not fix. Task 0075 is the building art and
is the place to decide whether the props follow.

### Hashes

Both unchanged - `2555959448` and `2601044827`. Art and a view; a zombie that
moved either guard would be a drawing reaching into the rules.

`python tools/verify.py` prints PASS: 4853 asserts, 607 input cases, 0 failed.
`exports` is still the one SKIP and still wants the Godot export templates.

## 0075 - Buildings and towers - done 2026-09-28

What changed: the house, the workshop and the kitchen drawn whole and sliced
into tiles; four towers drawn once each and grown into three levels; damaged,
destroyed and firing states derived for everything that has them. Screenshots:
`implementation/shots/0075-towers.png` (the two done-whens in one picture) and
`0075-buildings.png` (the farm).

Files: `tools/sprite_maps.py`, `tools/gen_sprites.py`, `src/ui/world_view.gd`,
`sprites/buildings/` (generated, 58 files),
`src/tools/headless_check.gd`.

Verify: 4920 headless / 607 input / both hashes unchanged.

### A level one and a level three, told apart instantly

The answer that reads at sixteen pixels is **height**. A tower with two more
stages in it is a different shape on the skyline; counting studs or reading a
recoloured barrel is not instant.

So each tower is drawn once, with six rows of plain post marked as the stage
that repeats, and `gen_sprites.GROWS` stacks one more copy per level. A level
three is twelve pixels taller than a level one - three quarters of a tile -
and is recognisably the same tower, because the extra goes into the post and
the head is untouched. There is an assert for both halves of that: taller by
at least six pixels and a fifth, **and** the same top row of pixels.

Four rows was the first try and gave eight pixels, which the check called too
small. The mortar is deliberately exempt from the ratio: it sits on the ground
rather than on a post, being squat is the whole of its silhouette, and it
grows by its barrel instead.

**The first version of the growth cut the towers' heads off.** It kept the
canvas the same height and took the extra rows from the top - the one place a
tower cannot spare them - so a level three gun tower was a post with a
platform and no gun. The view bottom-aligns anything taller than a tile, so
the image can simply be taller and the feet stay on the same grid line.

### A damaged wall reads as damaged without a health bar

`holed()` knocks out every seventh lit pixel, counted along the rows and
carried across them so the holes land somewhere different on each one. A wall
with bites out of it reads as damaged; a wall that is evenly speckled reads as
a texture, which is why the count does not reset per row.

Asserted as a range rather than a direction: a damaged thing has to have lost
pixels, and it has to have lost between five and forty per cent of them -
fewer is invisible, more is rubble. `_wreck` is the bottom third, holed, and
has to have less again.

### The house is one house

`FARM_MAP` lays the house down a cell at a time, nine of them, with no anchor
- so every cell asked for the same drawing and the farm had nine little
houses on it. The corner is a fact the view can work out for itself, once, by
taking the minimum x and y of the cells of each fixture. Cheaper than changing
what a fixture is in the rules and moving the determinism hash to do it.

It is drawn as one forty-eight by forty-eight map and sliced. Nine separate
sixteen-pixel maps would be drawing a house you cannot see: a roof line has to
meet across three files and the only way to check is to build it and look.

**Its windows are `flame_hot` and that is load-bearing.** Task 0071's night
ramp exempts anything the palette drew brighter than 0.80 and names what the
exemption is for - "firelight, a lit window, the moon". These are the lit
windows. The house is the warm thing on a cold field without a single light
being placed, which is what "the biggest, warmest thing on the farm, by day
and by night" comes to in pixels. Asserted: the brightest pixel in the house
is above `NIGHT_WARM_KEEP`, and the house is more than four times the drawing
of the largest defence.

### Firing

A five-pixel blossom stamped at a muzzle point declared per tower, because a
flash belongs where the barrel is and only the drawing knows where that is.
The view lights it off `reload`, which counts **down** from whatever the shot
cost - so a number near the top is a gun that has just gone off, and the flash
lands on the tick the shot did rather than being inferred from a projectile.

Firing beats damaged in the lookup. A muzzle flash over a hole reads fine; a
hole where a flash should be reads as a tower that has stopped working.

### A guess replaced by a question

`_texture_for()` worked out which directory a name belonged to by parsing the
name - task 0074's "the kind is the part before the first underscore". That
held for `walker_walk_b` and fell over on `gun_tower_2`, where the part before
the first underscore is "gun". It asks each directory for a file with that
name now. A file either exists or it does not, and asking is cheaper than
guessing and cannot be wrong.

### What is honestly still weak

- **The workshop and the kitchen look alike.** Both are a shed with a red
  roof and a lit window; the kitchen's stove is inside it and barely reads at
  two tiles. They are told apart by where they are and by the panel that
  opens, which is not nothing, but it is not the art doing the work.
- **The derivations are derivations.** Holes, a stamped flash and a repeated
  post are consistent and cheap and they are not a hand-drawn wreck. Same
  trade as task 0074's poses, same place to put the work if it ever matters:
  the maps.
- The generator, press, shop, well, tree and rock were already drawn and are
  untouched. They live in `sprites/props/` and stay there - `_texture_for()`
  asks both directories, and moving them would be churn for tidiness.

### Hashes

Both unchanged - `2555959448` and `2601044827`. Maps, generated PNGs and a
view. A building that moved either guard would be a drawing reaching into the
rules.

`python tools/verify.py` prints PASS: 4920 asserts, 607 input cases, 0 failed.
`exports` is still the one SKIP and still wants the Godot export templates.

## 0076 - Night lighting - done 2026-09-28

What changed: a `Lights` layer over the night ramp that draws a warm pool for
everything that is burning - the house, the stove, a running generator, a gun
that has just fired, a zombie that is on fire. Screenshot:
`implementation/shots/0076-lights-on-off.png`, the same night lit above and
unlit below.

Files: `src/ui/lighting.gd` (new), `scenes/Main.tscn`, `src/ui/main.gd`,
`src/ui/world_view.gd`, `src/app/settings.gd`,
`src/tools/headless_check.gd`, `src/tools/input_check.gd`.

Verify: 4936 headless / 614 input / both hashes unchanged.

### Over the ramp, not under it - and the first version was under it

Task 0071's night is a **screen-space pass**: the farm is drawn, then a shader
tints it, drains it and lifts it toward purple. A light drawn into the world
therefore gets tinted blue afterwards, which is the one thing a fire must not
be.

The first version put them there anyway, on a reasoning I liked: 0071 already
exempts anything brighter than `NIGHT_WARM_KEEP` from the tint, so a bright
light would exempt itself. **That is true of the core of a fire and false of
its halo**, and the halo is most of what a light is. The pool around the
farmhouse came out as a small yellow dot with a blue-grey smear round it.
Raising the strength until the pool cleared the threshold only moved the dot's
edge outward, which is a different bad picture.

So the lights are their own `CanvasLayer` after the relight and before the
HUD. That costs one thing - the layer is not carried by the camera, so world
positions go through `get_canvas_transform()` by hand - and buys the half of
the reference sheet this task exists to reproduce.

**They are additive sprites rather than `PointLight2D`.** A `PointLight2D`
lights canvas items *under* it, which is exactly the place this task found out
not to be.

### One light per building, not one per tile

The farmhouse is nine occupants and the kitchen four. Lighting each cell drew
nine glows on the same spot and additive blending turned the house into a
white star on the first screenshot. A light belongs to the thing; its middle
is the average of the cells it stands on.

### The moon is the lift, and that is deliberate

"The moon gives a soft global fill so the farm is never unreadable" is already
what `NIGHT_LIFT` does - it raises the whole farm off black toward blue, which
is what moonlight is. Adding a second global light would be the same effect
twice with two numbers to keep in step. Asserted here rather than left
implicit: the lift is non-zero on all three channels and leans blue.

### Frame time

Measured with vsync off, because with it on the numbers are the monitor's and
not the game's - the first attempt reported 32.5 ms against 31.8 ms and both
were just 30Hz.

On a board of **38 simultaneously lit buildings**: 2.07 ms a frame with the
lights and 1.13 ms without. **0.94 ms**, which is six per cent of a sixty
frame budget for more lights than a real farm will ever have on at once. The
first measurement used a board of gun towers and found nothing, because a gun
tower is dark until it fires - it measured the cheap case and would have
called it the expensive one.

### The dial, and the one that already existed

`video/lights`: 0 off, 1 steady, 2 full. And `a11y/flashing` - which was in
the settings already - drops it to `STEADY`, because a player who has turned
that off has said they do not want light that moves, and `STEADY` is these
lights without the wobble. One setting doing what it says rather than two
meaning the same.

### Light is cosmetic, and that is asserted rather than asserted-to

Task 0076 asks that turning lighting off changes nothing about the outcome of
a night. `input_check` plays the opening of the same night from the same seed
three times - full, off, steady - advancing the rules by hand and giving the
lights frames to draw in between, and compares `State.hash_of()`. All three
are identical.

### An assert that was right about the wrong version

I wrote "every light is brighter than `NIGHT_WARM_KEEP`", which was the
correct test while the lights were *under* the ramp and relying on its
exemption. Once they moved above it, brightness bought nothing - and two of
the five were under the line with no ill effect at all, which is how it was
found. What still has to be true is that a light is warm against a blue field,
and that is what it asks now.

### Hashes

Both unchanged - `2555959448` and `2601044827`. A layer that draws over the
farm and reads the state without writing to it. The flicker is a wall clock
and can only be a wall clock: a tick-driven one would be a cosmetic number
inside the determinism hash.

`python tools/verify.py` prints PASS: 4936 asserts, 614 input cases, 0 failed.
`exports` is still the one SKIP and still wants the Godot export templates.

## 0077 - Particles - done 2026-09-28

What changed: `src/ui/particles.gd` - sparks off a hit, dust and a little
blood off a death, smoke from chimneys and from wreckage, embers off anything
burning, and a muzzle spray off a gun that has just fired. A fixed pool, a
hard cap, and a density dial.

Files: `src/ui/particles.gd` (new), `src/ui/world_view.gd`,
`src/app/settings.gd`, `scenes/Main.tscn`, `src/ui/main.gd`,
`src/tools/headless_check.gd`, `src/tools/input_check.gd`.

Verify: 4959 headless / 648 input / both hashes unchanged.

### In the world, where task 0076's lights could not go

The lights had to be drawn **over** the night ramp, because a glow is mostly
halo and a halo is dim by nature - there was no brightness for the ramp's
exemption to catch. A particle is the opposite: one or two pixels, and a spark
is `flame_hot`, which is over task 0071's line. So a spark exempts itself and
stays orange while smoke, drawn in `stone_dark`, goes blue with the rest of
the farm. Which is what smoke at night should do.

Same rule as 0076, opposite answer, for a reason about the art rather than
about the code.

**Only the spark clears the line, and that is the palette's design.** Task
0071 found that the one warm colour above it is `flame_hot`, because `flame`
sits below *wheat*. So a spark is the hot core and stays orange and an ember
is the orange around it and dims - which is what an ember at a distance does.
My first assert demanded that embers stay warm too, which was an assert
demanding the palette be repainted to suit it.

### The view notices; the rules are not asked to say

There is no "somebody died" signal and adding one would put a cosmetic concern
into the rules. This keeps its own snapshot of the farm and looks at what
changed - an entity gone is a death, an occupant gone is a wreck, a `hurt`
counter that went **up** is an impact. Missing an event costs a puff of dust,
which is the right price for keeping the state clean.

### Three performance bugs, and the first measurement was wrong too

The busy-wave budget is task 0077's done-when, and getting an honest number
took four goes.

1. **The measurement compared a busy night against an empty screen.** The
   density-1.0 pass ran with seventy-five zombies being simulated and the
   density-0.0 pass ran after the night had ended, because the loop guarded
   its `Sim.advance` on the night still running. It reported that particles
   cost 41 milliseconds a frame. They do not; the simulation of a full night
   does. Both passes are measured on the same board with the clock held still
   now.
2. **`_slot()` scanned the pool twice per particle** - four hundred and twenty
   steps to find a free one and another four hundred and twenty to find the
   oldest. A ring overwrites in emission order, which is age order, and gets
   the same answer by not asking the question.
3. **Sparks were emitted every frame a thing was hurt.** `hurt` is a countdown
   that stays set for several ticks. The spark belongs to the moment the
   counter goes up.
4. **The farm was walked sixty times a second** to find out whether a chimney
   should smoke, which is an event that happens three times a second. The scan
   runs on the smoke's own clock now, and the guns - whose flash *is* a
   per-frame moment - keep a cached list of their own cells.

And one that was not this task's:

5. **`WorldView._exists()` touched the filesystem two or three times per
   occupant per frame.** I added it in task 0075 to choose between a tower's
   levels and its damaged art. Two hundred and fifty occupants is seven
   hundred and fifty `ResourceLoader.exists()` calls a frame, and it was
   costing **26 of a 16 millisecond budget on its own** - with particles
   switched off entirely. The answer cannot change while the game runs, so it
   is remembered per name.

### The numbers

On a board of five towers and **seventy-five enemies**, with the simulation
held still so this is drawing and nothing else:

| | ms a frame | live particles |
|---|---|---|
| before, particles off | 26.30 | 7 |
| before, full density | 40.50 | 162 |
| after, particles off | 2.09 | 17 |
| after, full density | **2.97** | **420 (the cap)** |

So particles cost **0.88 ms** with the pool completely full, against a
sixteen millisecond budget - and the farm around them got twelve times
cheaper on the way.

### Cap and density are two different dials

`video/max_particles` is the ceiling and `a11y/particle_density` is the tap.
One decides how many can be alive and the other how many are asked for; a
player on a weak machine wants the first and a player who finds movement
tiring wants the second. `input_check` fills the pool well past the ceiling
and asserts it never exceeds it, and asserts that zero density empties it and
keeps it empty.

### Cosmetic, and asserted rather than asserted-to

Task 0077 asks that turning them off not change the outcome of a night.
`input_check` plays the same night from the same seed at full, half and zero
density, advancing the rules by hand and giving the particles frames to draw
in between, and compares `State.hash_of()`. All three identical.

### Hashes

Both unchanged - `2555959448` and `2601044827`. Everything here drifts on a
wall clock rather than on ticks, which is both correct for a view and the
reason none of it can reach the guard even by accident.

`python tools/verify.py` prints PASS: 4959 asserts, 648 input cases, 0 failed.
`exports` is still the one SKIP and still wants the Godot export templates.

## 0078 - The reality transition - done 2026-09-28

What changed: `src/ui/transition.gd` - a band of light crossing the farm while
the world flips, the day's animals fading out, and the guns flaring as they
come on. The light drain itself is task 0039's and was already right; this is
the theatre around it. Screenshot: `implementation/shots/0078-transition.png`,
five frames of the change.

Files: `src/ui/transition.gd` (new), `src/ui/world_view.gd`,
`src/core/game_data.gd`, `src/app/settings.gd`, `scenes/Main.tscn`,
`src/ui/main.gd`, `src/tools/headless_check.gd`, `src/tools/input_check.gd`.

Verify: 4976 headless / 655 input / both hashes unchanged.

### Is it the clip you would put first in a trailer?

Task 0078 asks me to say, so: **not yet, and it is close.**

What is there: the light drains from warm green to cold blue across the whole
farm at once, a wash of light travels across it while that happens, the
chickens and the cow fade away, the four gun towers flare gold as they come
on, and the farmhouse windows light up. Two seconds, and at the end it is
visibly a different world made of the same tiles. That is the idea the game is
named after and it is legible.

What a trailer clip would also have and this does not: the camera does not
move, and nothing arrives. The first zombie stepping out of the treeline as
the last of the light goes is the shot - and that is a wave-timing and camera
question rather than a transition one. **The honest answer is that this is the
beat, and the clip would be this plus a camera push and one walker.**

### The length is a lever and a setting, and deliberately not in the digest

`GameData.TRANSITION_SECONDS` - a lever, where levers live, because a designer
will want to turn it while watching it. **Left out of `digest()` on purpose**:
that guard watches the balance tables, and a two-second fade is not balance.
Putting it in would mean a purely visual tweak failing a check about whether
the game still plays the same.

That is a decision rather than an oversight, so there is an assert for it -
`headless_check` reads `digest()`'s own source and fails if the constant ever
appears inside it. Otherwise the next person to wonder why the data hash did
not move would have to work it out from first principles.

`video/transition_seconds` overrides it for a player, and the
`gameplay/skip_transition` flag that already existed now means "the shortest
change the code can draw" rather than a special case that never fades.

### Both directions, and the morning is the other one

Dusk sweeps a cold band left to right; dawn sweeps a warm one right to left.
Same code, colour and direction turned round - because it is the same event
seen from either end, and because a morning that played as the evening
backwards would feel like a rewind rather than a reward.

### What the first version got wrong

**The band read as a striped screen-wipe.** Seven hard-edged strips at 0.55
opacity, chosen hard-edged on the grounds that this is a pixel-art game and a
smooth alpha ramp across four hundred pixels would look like it came from
somewhere else. That reasoning is right and the execution was not: at that
strength the edges were the thing you saw. Thirteen narrower strips at 0.30
read as one moving wash and are still made of hard edges.

**And nothing woke up.** The task asks for night structures to wake and the
first version only had the animals leaving, which is half an idea. The guns
flare on a bell curve through the change and settle - an event rather than a
permanent glow.

### Two bugs of my own

**Casting a freed object.** `WorldView._refresh()` throws its sprites away and
builds new ones, so a cached list of them holds freed objects - and
`sprite as Sprite2D` on one of those is an error rather than a null. Valid
first, cast second; and the cache notices a rebuild rather than trusting the
occupant count, which does not change when the view redraws for its own
reasons.

**A wait shorter than the thing waited for.** Task 0077's case asserted that
particles all go out forty frames after the density is set to zero. Smoke
lasts 1.6 seconds times up to 1.3, which is about a hundred and twenty-five
frames. It passed when I wrote it and failed here, because this task made the
transition longer and moved the timing under it. It waits for the last one
now instead of guessing.

### Skipping lands where watching does

The done-when, and it is true for a structural reason rather than a careful
one: nothing in the change is ever waited on, so the tick runs through it at
the rate it runs through everything else. `input_check` plays the same night
from one seed twice - watching every change, then skipping every change - and
compares `State.hash_of()`. Identical.

### Hashes

Both unchanged - `2555959448` and `2601044827`. The data hash staying put is
itself the evidence that the new lever is outside the digest, which is what
the group asserts in words.

`python tools/verify.py` prints PASS: 4976 asserts, 655 input cases, 0 failed.
`exports` is still the one SKIP and still wants the Godot export templates.

## 0079 - Resource icons and the UI kit - done 2026-09-28

What changed: fifteen resource icons and a UI kit - nine-slice panel, tooltip,
tab, a button in four states, slider and checkbox - all from ASCII maps, and a
`UiKit` that hands them out. Screenshot:
`implementation/shots/0079-ui-kit.png`, the icon row above and the kit below.

Files: `tools/sprite_maps.py`, `src/ui/ui_kit.gd` (new), `sprites/ui/`
(generated, 26 files), `src/ui/tech_panel.gd`, `src/ui/night_hud.gd`,
`src/ui/shop_panel.gd`, `src/ui/stats_screen.gd`,
`src/tools/headless_check.gd`.

Verify: 5062 headless / 655 input / both hashes unchanged.

### Shape before colour

The only test task 0079 sets for an icon is that it is told apart at native
resolution without its label, so each one is a different **shape** first: the
log pile is two circles, the stalk stands up, the bolt is a zigzag, the cog is
the only round thing with teeth, the ingot is the only trapezoid. Two brown
things of the same outline are two brown things whatever colour they are.

Two pairs needed a second go after looking at the row:

- **Wood read as a crate.** A bordered rectangle with rings in it is a chest;
  two log ends seen from the end of the pile is a woodpile.
- **Food and money were both gold discs.** Different shapes - a loaf with cuts
  against two stacked coins - and at sixteen pixels that was not enough. Food
  is a pie with a red crust now, which separates them by hue as well.

The machine cannot say whether two drawings *read* differently, but it can say
whether they **are** different: the check fingerprints every icon and fails if
two are the same pixels, which is what catches one copied and not finished.

### Every resource has one, and no icon is orphaned

Asked of the game rather than of a person looking at a folder.
`UiKit.missing_icons()` walks `GameData.RESOURCES` and `orphan_icons()` walks
the directory, and the check fails on either. A sixteenth resource added in a
year fails it the same day, which is the point.

Fifteen resources, fifteen icons.

### Two numbers that had to match, and did not

Every frame is sixteen by sixteen with a border and a middle that repeats.
`UiKit.MARGIN` said five and the drawings had three - which slices a frame
four pixels into its own middle.

It was caught on the first run by the check that **reads `panel.png` and
counts the border**, rather than by looking at a screenshot and wondering why
the corners were soft. That check now runs over the panel, the tooltip, the
tab and the button, because the buttons had a two-pixel border and the others
three, and a kit whose pieces disagree about their own edges is not a kit.
They are all three now.

### Which screens use it, and which do not

- **The tech tree**: all twelve node buttons, in four states.
- **The night HUD**: its three buttons, the same four states.
- **The shop**: its frame.
- **The records screen**: its panel.

**Not the day HUD.** It has no frame to swap - it is labels and a bar drawn
straight onto the screen with no panel behind them - so there is nothing for
the kit to serve without redesigning it, and redesigning the day HUD is not
this task. Said here rather than quietly counted as done: task 0079 names the
day HUD and this does not reach it.

The buttons' **content margins are pinned** where they were. A
`StyleBoxTexture` otherwise takes its content margin from its nine-slice
border, and a button that grew three pixels a side would push the tech tree's
third column off a four-hundred-and-eighty pixel screen - which is the family
of bug `tech_panel.gd` already carries five comments about.

### The states differ in value, not only in hue

A hover that is only a different colour is invisible to a good fraction of
people and to anybody on a bad screen. Normal is dark, hover is grey, pressed
is gold - and the check measures the middle pixel of each and fails if two are
within a tenth of each other in brightness.

### Hashes

Both unchanged - `2555959448` and `2601044827`. Maps, generated PNGs and four
view files swapping one `StyleBoxFlat` for another.

`python tools/verify.py` prints PASS: 5062 asserts, 655 input cases, 0 failed.
`exports` is still the one SKIP and still wants the Godot export templates.

## 0080 - A pixel font - done 2026-09-28

What changed: the game has its own letters. `tools/font_maps.py` draws them as
ASCII maps, `tools/gen_font.py` turns those into two BMFont faces, and every
label in the game wears them. Screenshot:
`implementation/shots/0080-font.png` - a specimen above, the HUD below.

Files: `tools/font_maps.py` (new), `tools/gen_font.py` (new),
`assets/fonts/` (generated), `src/ui/ui_kit.gd`, `src/ui/main.gd`,
`project.godot`, `tools/verify.py`, eight files in `src/ui/`,
`src/tools/headless_check.gd`.

Verify: 5096 headless / 655 input / both hashes unchanged.

### Drawn, and then composed

The ninety-five printable ASCII characters are drawn. **Fifty-three accented
letters are not** - they are a base letter with a mark laid over it, which is
what an accented letter is. Drawing fifty of them by hand would be fifty
chances to draw the same E slightly differently, and the five marks are the
same five for all of them.

The same argument as task 0072's edge tiles and task 0074's poses, and here it
is not even a compromise: a composed é *is* an e with an acute on it.

### The cell was one row short in two places

The first version was seven rows: marks on rows 0-1, capitals on 1-5,
lowercase on whatever was left. Rendered, it was wrong twice over.

- **An accent touched its letter.** With the mark ending on row 1 and the
  letter starting on row 1, á was a single blob.
- **Lowercase had an x-height of three.** "the quick brown fox" came out as a
  row of squares - legible as a shape, not as words.

Eight rows fixes both: the mark has row 0, row 1 is clear, capitals take 2-6
and lowercase 3-6, and descenders have row 7. Which also makes the face eight
pixels a line - the size twelve labels in the game already asked for.

### Tabular numbers, and letters that are not

Each glyph is trimmed to its ink, so `I` is one pixel wide and `M` is five.
**Digits are the exception**: all ten take the widest digit's box, centred, so
a counter going 9 to 10 to 99 moves nothing beside it. That is the done-when,
and it is asserted as a fact about the font rather than by looking at a HUD:
every digit measures the same width, `"1 wood"` and `"8 wood"` measure the
same, **and** `MMM` is wider than `iii` - because a font where everything is
the same width would pass the first two by accident and be a terminal.

### Full Latin-1, and the assert that made me mean it

I wrote "full Latin-1 coverage" and then wrote a check that walks 0x20 to 0xFF
and counts. It found **thirty-two holes** - the fractions, the ligatures, eth,
thorn, sharp s, the ordinals, the currency signs. None of them is in a string
this game has, and a font with a hole in it is a font that renders a box the
first time somebody pastes a name into it. They are drawn now and the count is
zero.

Every accented character Portuguese needs is there for task 0097, in both
faces.

### Two sizes, one design

The HUD face is the maps at their drawn size and the heading face is the same
maps at exactly twice it. A whole-number scale of a bitmap is still a bitmap;
a second face drawn at double size would be a second font to keep in step, and
the one thing worse than a font with no headings is two fonts that drift.

**Everything in `src/ui/` was normalised to ask for 8 or 16.** Thirteen labels
asked for 9 and one for 12, which on a bitmap font are 1.125x and 1.5x - a
blurred bitmap, which is the one thing a pixel font must not be. All 655 input
cases still pass, which was the thing I expected to have to fix and did not.

### A line of configuration that silently did nothing

`gui/theme/custom_font` in `project.godot`, with the path to the `.fnt` in it,
**read back as an empty string**. `gui/theme/default_font_size` next to it
took fine. I did not chase why Godot refuses a `.fnt` through that setting:
`UiKit.theme()` builds a `Theme` and `Main` puts it on the UI root, which is
one line of code that demonstrably works instead of one line of config that
demonstrably does not.

Found by asking a `Label` what font it had rather than by looking at a
screenshot and deciding it looked about right - the screenshot is what said
something was wrong, and the question is what said what.

### A new row in verify

`font` runs `python tools/gen_font.py --check`, so a letter painted over in an
editor is a letter the maps no longer own, and the suite says so. Same
argument as the `sprites` and `player art` rows.

### Hashes

Both unchanged - `2555959448` and `2601044827`. Maps, generated files and the
view.

`python tools/verify.py` prints PASS: 5096 asserts, 655 input cases, 0 failed.
`exports` is still the one SKIP and still wants the Godot export templates.

## 0081 - The UI theme - done 2026-09-28

What changed: one `Theme`, built from the palette and the UI kit, worn by
every Control in the game. **Fifty-three `add_theme_*_override` calls across
twelve screens are gone** and nothing replaced them one by one: a screen now
says *what a thing is* and the theme says what that looks like. Screenshot:
`implementation/shots/0081-theme.png` - the market, the tech tree, the
records, the inventory, the build palette and the night's result, side by
side.

Files: `src/ui/ui_kit.gd`, `src/ui/main.gd`, ten screens in `src/ui/`,
`tools/sprite_maps.py`, `sprites/ui/button_focus.png` (generated),
`project.godot`, `src/tools/headless_check.gd`, `src/tools/input_check.gd`.

Verify: 5177 headless / 671 input / both hashes unchanged.

### What the overrides were actually hiding

The grep found fifty-three. Reading them found the reason the task exists:

- **Five hand-rolled `StyleBoxFlat` panels** in five files, in five nearly
  identical purples - `0.06,0.05,0.10`, `0.07,0.06,0.12` three times over,
  `0.02,0.02,0.04` - with four different border colours and content margins
  of four, five, five, six and eight. Task 0079 drew one panel and only two
  screens ever used it.
- **`const DIM` in five files with four different values.** `WARM` in four
  files with two. That is not a palette, it is a habit.
- **Thirty of the fifty-three asked for font size eight**, which task 0080
  had already made the default. They were no-ops and had been for a task.
- **`LINE_FONT := 9`** in the inventory panel, which 0080's sweep missed
  because it was behind a constant. Four labels at 1.125x - a blurred bitmap
  font, the one thing this art pipeline exists to prevent.

### The rule that replaced them

**A variation says what a thing is; `modulate` says how lit it is right now.**

`UiKit.ROLES` is nine names, each pointing at a colour in
`PaletteData.COLOURS`, so the UI and the sprites come out of the same tin. A
label asks for `UiKit.DIM` and never for a `Color`. What is left for
`modulate` is the handful of places where something is genuinely brighter
this frame than last: a number flashing after it changed, the day label at
dusk, a wave announcement pulsing. Those are multipliers now - `LIT_TINT`,
or an alpha - and not a second colour to keep in step with the first.

Three roles turned out to be saying the same thing twice and stopped:

- A **locked tech node is already `disabled`**, so the theme was drawing it
  in the dull frame with faint letters, and the `modulate` on top multiplied
  that by a dim colour again. Twelve nodes you could barely see. Owned is now
  the same disabled button with green letters - the only difference that
  needed saying.
- **The repair and flare buttons** set `disabled` and then greyed themselves
  as well. The theme's disabled state does it.
- The **tech tree's backing** was a flat `ColorRect` of its own purple, which
  made it the one full-screen panel in the game without a brass edge. It is
  the kit's `Panel` now, the same one the records screen wears.

### The theme has to be on before anything is built against it

`input_check` failed on three night controls being thirty-one pixels tall.
The theme was right - it resolved to a minimum of forty-six by eight - but
the buttons were built in `NightHud._ready()`, and **children `_ready()`
before their parent**, so at that moment there was no theme and Godot's
default minimum was sixty-three by thirty-one. `size` is clamped *up* to the
minimum when it is set and **never clamped back down**, so the buttons kept
thirty-one for the rest of the run.

`Main` dresses the tree in `_enter_tree` now, which runs the other way round,
and again in `_ready` for the debug overlay - it builds its panel in its own
`_ready`, on a `CanvasLayer` of its own with no Control above it, which is
how it stayed in Godot's grey through five tasks that each thought they had
dressed the game.

### Focus is a state, not the absence of one

Two screens hid Godot's grey dashed ring behind an empty box. An empty box is
not a focus state, and the night button has `FOCUS_ALL` on it, so a keyboard
had nowhere to be. `ui/button_focus` is a new ASCII map: a bone ring, inset
one pixel, transparent in the middle so it draws over whichever state the
button is already wearing. Bone rather than gold because pressed is gold, and
a focus you cannot tell from a press is not a focus.

### Two things the screenshot said and no assert could

- **The tab you were on looked like the switched-off one.** A `Button` draws
  its pressed letters in ink, which is right on a gold press and wrong on a
  tab. The `Tab` variation names its own four font colours now.
- The tech tree's twelve nodes were the near-invisible ones described above.

Both were found by looking at a contact sheet of six screens together, which
is the only way to answer "do they look like the same game" - and both were
wrong in a way every assert I had written was happy with.

### What the checks ask now

- **The done-when, asked of the repository**: `headless_check` reads every
  file in `src/ui/`, skips comments, and fails on any `.add_theme_*_override(`
  left. A `grep` a person runs once passes the day it is run. Planted one to
  be sure it bites; it named the file and the line.
- Every role names a colour that exists in the palette, no two roles are the
  same colour, and every one can be read against a panel (measured, against
  `night`).
- Every interactive type has all five states including focus and disabled,
  and **none of their boxes reserves vertical height** - the bug that put the
  build palette off the bottom at 0032, the shop rows at 0040 and the speed
  control at 0055, pinned once here instead of by hand in five files.
- `input_check` walks the live tree and asks every Label, Button and Panel in
  the game what it is wearing. That first assert failed: it demanded the HUD
  face and the wave announcement wears the heading face, which is a second
  `FontFile` by design. Widened to "either of the game's two faces", which is
  what it meant.

### The scale factor is the window's

`SCALE` is one and the theme adds none. The project stretches a 480x270
viewport with `scale_mode="integer"`, so the whole screen is already
multiplied by a whole number at every window size; a second scale inside the
theme would multiply that one and put an eight pixel font at eleven and a
half. Asserted, and **so is the project setting that justifies it** - if that
ever becomes fractional, `SCALE := 1` stops being a decision and becomes a
leftover.

### Judgement calls, said out loud

- `debug_overlay.gd` carried a note arguing it should keep its own look
  whatever the theme did, explicitly deferring the call to this task. It
  wears the `Overlay` variation - the kit's quiet tooltip frame - which is
  still visibly not a game panel, and the robustness the note wanted now
  comes from the theme having asserts on it rather than from a second copy of
  the colours.
- **The day HUD is still unframed.** Task 0079 said so and nothing changed:
  it is labels drawn straight onto the world with no panel to swap, and
  giving it one is a redesign, not a theme.
- The light colours in `lighting.gd`, `transition.gd` and `world_view.gd` are
  left alone. They are light, not chrome - the theme is a thing for Controls.

### Hashes

Both unchanged - `2555959448` and `2601044827`. A theme, an ASCII map and
twelve view files.

`python tools/verify.py` prints PASS: 5177 asserts, 671 input cases, 0 failed.
`exports` is still the one SKIP and still wants the Godot export templates.

## 0082 - Screenshots, and actually looking at them - done 2026-09-28

What changed: `python tools/shot.py 0082` puts the game in five known states
and photographs them into `implementation/shots/0082/`. **Two runs in two
processes now produce five byte-identical PNGs**, which took three bugs to
get to. Screenshot: `implementation/shots/0082-contact-sheet.png`, all five
at once.

Files: `src/tools/shot.gd` (new), `tools/shot.py` (new), `src/ui/main.gd`,
`src/ui/result_screen.gd`, `src/ui/build_mode.gd`, `src/ui/debug_overlay.gd`,
`src/ui/world_view.gd`, `src/ui/lighting.gd`, `src/ui/ui_kit.gd`,
`implementation/prompts/00-RUNNER-LOOP.md`, `CLAUDE.md`,
`src/tools/headless_check.gd`, `src/tools/input_check.gd`.

Verify: 5196 headless / 678 input / both hashes unchanged.

### Headless is not possible, and the failure is worse than a failure

The task asks for headless and Godot cannot do it. Measured, before writing
anything:

- `--headless` selects the **dummy** rendering backend.
  `Viewport.get_texture().get_image()` returns null out of
  `dummy/storage/texture_storage.h`.
- `RenderingServer.frame_post_draw` **never fires at all**, so the obvious
  script hangs for ever rather than failing. My first probe sat there until
  the tool timed out at four minutes.

So `tools/shot.py` opens a real window four thousand pixels off the left of
the screen and closes it when the last picture is written. Nothing to click
and nothing to look at, which is the part of "headless" the task wanted. Said
here rather than quietly marked done.

### Three bugs between "a seed and a script" and the same picture twice

The requirement is that two runs give the same picture. I built it, ran it
twice, and **three of five differed**. Each round was: diff the two PNGs, look
at where the pixels are, fix, measure again.

1. **The two warm-up frames ran unseeded.** Godot randomises the global RNG at
   startup; `particles.gd` draws from it deliberately, since a spark is not a
   rule and must not touch the run's stream. I seeded per scenario - but the
   scene was instantiated and stepped twice *before* that, and the smoke those
   frames put in the air survived into the first picture. 0.07% of pixels, all
   of them round the chimneys, which is what the diff image said before I had
   any theory. Seeding before the scene is built fixed three of the five.

2. **`Array.sort()` does not order StringNames alphabetically.** It compares
   their interned pointers. The result screen printed an identical night's
   reward as `+4 tech +182 money` on one run and `+182 money +4 tech` on the
   next. `src/core/` has known this all along - every key walk goes through
   `GameData.sorted_names` and the four bare sorts each say in a comment that
   their keys are integers - but three places in `src/ui/` had rolled their
   own: the result screen, the build palette's price line and the debug
   overlay's tally. All three fixed.

   **Only a byte comparison across two processes could have found this.**
   Within one process the order is stable, so a test that runs once passes.

3. The camera, which is not a bug but cost three attempts. See below.

Now five of five, identical.

### `--fixed-fps` is what makes the view reproducible

The simulation was never the problem: a seed, a script and `Sim.advance` do
not touch a clock. The **view** advances on `delta`, which is real seconds.
Measured: without the flag the first four frames are 0.0347, 0.0398, 0.0309,
0.0302; with `--fixed-fps 60` every frame is 0.016667 from the first. That is
the whole reason the wrapper exists.

### Looking at the pictures is the point, and it found things

Every one of these came from opening a file, not from a failing assert:

- The first **wave** scenario photographed an empty battlefield. Eight towers
  had killed all fourteen zombies in the nine seconds before the shutter. The
  tool prints how many are still coming now, so it cannot happen quietly.
- The **result** screen was a title and a button with nothing between them -
  `Phases.enter_result` had been called without a night to itemise.
  `Sim.skip_night` plays one, and task 0078 proved it lands where watching
  lands.
- The **tech** tree said "0 of 12 nodes" over nine unspent points, because the
  ids have spaces in them and `&"sharp_tools"` bought nothing and said
  nothing.
- The result screen printed **"still up19 untouched"** - two labels with no
  gap. Mine, from 0081: the theme sets container separation to zero, and the
  font's tabular six-pixel digits make "house 100/100, 19 built still up" a
  hundred and seventy pixels in a column a hundred and fifty wide. Counting
  the characters is not the same as measuring the string.

And one thing that looked like a bug and was not: `POWER 4/16 everything at
50%` read convincingly as `everything at EON` at 480x270. **Zoom before
concluding.** That is now in the runner loop.

### Three attempts at pointing the camera

The farm shots kept photographing a lawn with the field just off the left
edge.

1. Sowed a fixed block at (6,6) and let the camera follow the farmer, who
   starts at (17,7). Wrong end of the map.
2. Sowed around the farmer instead. Nothing was sown at all - tilling is only
   offered on the farm's own soil, and the farmer starts on grass.
   `Interact.verb_at` knows where the soil is, so the scenario asks it.
3. Sowed the real field and pointed the camera at it. `Main._process` calls
   `look_at_cell(Player.cell(state))` **every frame**, so the camera was back
   on the farmer before the first settle frame.

The farmer walks to the picture now, through the same `intent["move"]` the
keyboard writes, ticked by hand so it costs no wall clock. That is not a
workaround: the camera follows the farmer because the game says it should, and
a player who wants to look at the field walks there.

A fourth miss belongs here too: the tool reported "0 crops up" over a field
full of them, because `_crops_up` asked `Farm.cells_with(state, &"plot")` and
plots live in `state["plots"]`, not in `occupants`. **A measurement wrong in
the direction that makes you distrust working code** is worse than no
measurement.

### The asserts, and the two that did not bite

- `headless_check` reads `src/tools/shot.gd` and checks the scenario table is
  still true about the game: five scenarios, each with a builder, each named
  screen present in `Main.tscn`, and no clock read anywhere in the file.
- It also asserts `sorted_names` is alphabetical, and that **no screen sorts
  dictionary keys without saying its keys are integers** - the opt-out
  `src/core/` already uses. Three lines in `src/ui/` had to be annotated;
  three others were the bug.
- `input_check` asks every horizontal row in four screens whether two labels'
  text runs together.

That last one took three goes and is the lesson of the task:

1. First version asked whether the two rects **intersected**. Planted the bug,
   ran it: passed. Two labels printed as "up19 untouched" are *adjacent*, and
   `Rect2.intersects` is false for touching rectangles. It measures the ink
   now - where one string's last pixel is and where the next one's first is.
2. Second version still passed with the bug planted, because the case **lost**
   the night, and "house 0/100, 0 still up" is nowhere near the edge of its
   column. The case defends the farm and survives now.
3. The guard against that going vacuous again asked for a row at least 150px
   wide and failed at 146 - which is the *fixed* string nearly filling its
   column. Only the buggy string was ever 150. Measured, then set to 120.

A test that cannot fail on the bug it was written for is worth less than no
test, because it also claims the area is covered.

### The runner loop

Step 4 now says to run `python tools/shot.py <id>` and **open the files**, with
three examples of what the suite has cheerfully passed: the wrong tab
highlighted, twelve tech nodes too dark to read, and two labels printed on top
of each other. It also says to zoom before concluding something is wrong.
`CLAUDE.md` gained the same command.

### One refactor

`Main._ready`'s run wiring is `Main.begin_run(seed)` now - a dozen
`show_state` calls that three things want: boot, this tool, and task 0092's
router. `SimDriver.start` replaces the state dictionary rather than emptying
it, so a screen still holding the old one draws a game that has stopped
advancing.

### Hashes

Both unchanged - `2555959448` and `2601044827`. All three sort fixes are in
`src/ui/`; the simulation never had the bug.

`python tools/verify.py` prints PASS: 5196 asserts, 678 input cases, 0 failed.
`exports` is still the one SKIP and still wants the Godot export templates.

## 0083 - Audio buses and a sound manager - done 2026-09-28

What changed: four audio buses and `Audio.play(&"sfx/shot")`. Tasks 0084 to
0087 now only have to drop files into `assets/sfx/`, `assets/music/` and
`assets/ambience/` - **the folder a sound lives in is the bus it plays on**,
so nothing is listed twice and nothing can be listed wrongly. Nothing is
visible, and five screenshots taken against the 0082 set prove it: byte for
byte identical with the new autoload running in every scene.

Files: `src/app/audio.gd` (new), `default_bus_layout.tres` (new),
`project.godot`, `src/tools/headless_check.gd`, `src/tools/input_check.gd`.

Verify: 5225 headless / 692 input / both hashes unchanged.

### Four buses, not the three the task asked for

`Settings.DEFAULTS` has had `audio/ambience` in it since task 0009, and task
0087 is the ambient bed - birds and water by day, wind and groaning by night.
A fourth bus now is four lines of a `.tres`; a fourth bus later is an options
tab that has been shipping a slider which moves nothing.

There is an assert both ways: every volume the manager turns is a key
`Settings` has, and every `audio/` key `Settings` has turns a bus. Two lists
that have to agree in two files are two lists that will not.

### The configuration line actually does something

Task 0080 lost an afternoon to `gui/theme/custom_font`, which read back empty
and silently did nothing. So `audio/buses/default_bus_layout` was **tested
rather than trusted**: pointed at a path that does not exist, the bus graph
collapses to `["Master"]` alone. It is read. `headless_check` asks the
`AudioServer` for all four buses by name anyway, so a layout that stops
loading is a red row rather than a game that quietly has one bus.

The dummy audio driver still builds the whole bus graph, which is what makes
any of this answerable with no sound card.

### Master at zero, and why the buses are a tree

Music, SFX and Ambience all **send to Master**. That is the whole mechanism
behind the done-when: one flag, one bus, everything goes quiet - rather than
muting four buses and leaving the fifth one somebody adds in a year still
playing. Asserted as routing (`get_bus_send` is Master for all three) and
end to end through the real setting in `input_check`.

**Zero mutes rather than turns down.** A bus at minus eighty decibels is
quiet, not silent, and a long music loop at -80dB is still audible on
headphones in a quiet room. `is_silent(level, muted, bus)` is pulled out as
its own function so the rule can be asked directly by a check that has no
`Settings` autoload to drive.

### Twenty towers, one gunshot

Twenty copies of one sound started six samples apart is not twenty gunshots.
It is a click, and most of the headroom gone. So `play()` folds an id already
asked for this frame into the first one.

One thing had to move: the dedupe records the frame **on the attempt**, not
after a voice is found. With it the other way round, a full pool turned
twenty towers firing on one tick into twenty drops instead of one attempt and
nineteen folded in - the same sound asked for twice in a frame is one sound
whether or not there was room for it.

Beyond the pool, sounds are **dropped rather than stealing a voice**, because
a stolen voice is an audible cut.

`MAX_VOICES` is a plain const: not a `# LEVER` in `game_data.gd`, because it
is not a rule and must not touch the data hash, and not a `Settings` key
either, because unlike `video/max_particles` it is not a frame budget a
player has an opinion about.

### Four things Godot does that had to be measured

All four came out of one throwaway probe, which this time had a watchdog on
it:

- **`add_child()` during `_initialize()` does not run `_ready()`.** The pool
  came back with zero voices and every sound was "dropped". `build()` is
  public for that reason, and the class docstring says so.
- **`get_node_or_null("/root/Settings")` errors** with "can't use absolute
  paths from outside the active scene tree" while the tree is still starting.
  It goes through `get_tree().root` now.
- **`get_tree()` itself errors** with "Parameter data.tree is null" when the
  node is not in a tree at all, so `is_inside_tree()` has to be asked first.
- **`AudioStreamPlayer.play()` errors** unless the node is inside the tree.
  A voice is only told to play when the tree will take it; it is still
  allocated and still counted, because `started()` means a voice was taken
  and whether a driver made a noise with it is the driver's business.

Under the dummy driver a voice reports `playing` true and never finishes on
its own, which is why the pool cap is asked in `input_check`, where there is
a live tree, and the rules are asked in `headless_check`, which is
synchronous and has a five second watchdog it cannot give up.

### Both asserts bite

Planted the obvious break - dedupe off - and ran both suites:

- headless: `twenty shots on one frame take one voice  20 started`
- input: `twenty shots on one frame put one voice in the air, not twenty  16
  playing`

Sixteen, because without the fold the pool fills instead. That is the
clipping the requirement is about, and the test says so in the failure
message.

### What is deliberately not here

**Nothing calls `Audio.play()` yet.** There are no sound files until task
0084 writes `tools/gen_sfx.py`, and wiring the calls now would mean every
verb in the game pushing a "nothing called that" warning on every tick.
`scan()` treats a missing folder as normal rather than an error for the same
reason: a game with no sounds yet should start in silence, not refuse to
start.

The checks use a sine built in code, because a pool with nothing to put in it
cannot be asked how many it holds.

### Hashes

Both unchanged - `2555959448` and `2601044827`. Sound is not a rule, and
`src/core/` cannot see `src/app/`.

`python tools/verify.py` prints PASS: 5225 asserts, 692 input cases, 0 failed.
`exports` is still the one SKIP and still wants the Godot export templates.

## 0084 - The sounds of the day - done 2026-09-28

What changed: thirteen day sounds, synthesised from recipes in
`tools/gen_sfx.py`, and `src/ui/sfx.gd` to notice when the day makes one.
Chop, mine, till, plant, water, harvest, collect, craft, trade, sell, cast,
reel and the bite. Nothing is licensed, recorded or hand-edited; every one is
a dozen lines of arithmetic and a `--check` row that fails if a file stops
matching its recipe.

Files: `tools/gen_sfx.py` (new), `assets/sfx/` (13 generated WAVs, new),
`src/ui/sfx.gd` (new), `src/app/audio.gd`, `scenes/Main.tscn`,
`src/ui/main.gd`, `tools/verify.py`, `src/tools/headless_check.gd`,
`src/tools/input_check.gd`.

Verify: 5305 headless / 699 input / both hashes unchanged.

### The invariant that makes a finished verb visible from outside

`src/core/` does not know sound exists, so the view has to work out when a
verb finished by looking at the state - the same discipline as the sparks in
`particles.gd`.

A working verb lives in `state["player"]["action"]` as
`{verb, cell, left, total}`. `left` falls by one every tick and
`state["tick"]` rises by one, so **`left + tick` is the tick the cycle is due
to finish on, and it does not move while the cycle runs.** That answers both
awkward questions exactly:

- The due tick jumping forward means a cycle finished and the verb went round
  again, which is what chopping a tree is, twenty times over.
- An action that vanished **finished** if the clock had reached its due tick
  and was **interrupted** if it had not.

The first thing I wrote was "the action disappeared and `left` was small, so
call it finished", which is a fudge that comes apart at four times speed.
This is arithmetic. `input_check` starts a swing, walks away part way and
asserts silence; with the due-tick test taken out it fails with
`1 started, last 'sfx/chop'`.

Watering is the exception and is named as one: it is on `Interact.INSTANT`,
so it never creates an action at all - a held key has to water a whole row as
the player walks it. `Sfx` counts watered plots instead. The check asserts
that **water is the only instant day verb**, so a second one arriving in a
year fails rather than going quietly silent.

### Deterministic, and not by accident

`random` is not used anywhere in the generator. Every grain of noise comes
from a sixteen-line congruential generator seeded per sound, because the
contract is byte-identical output on any machine and any Python, and
`random`'s stream is a promise CPython makes rather than one the language
does. Same reasoning as the run's own RNG.

The WAV header is written by hand for the same reason: `wave` would do it and
would also be free to change its padding between versions, which would fail
`--check` for a sound nobody touched.

### Cozy and soft, with one exception, measured

Every sound is under half a second and peaks at 0.55 - well below full scale,
so several at once plus the night's louder half still have room. The bite
peaks at 0.85.

The bite is the only day sound with a **window** behind it: miss it and the
fish is gone. So it is allowed to be the loudest and the longest, and it
rises rather than falls, because a rising figure reads as a question and a
falling one as a full stop.

**I wrote "and the brightest" first, then measured, and it is not.** `till`
reads 0.69 on a spectral measure and the bite 0.49, because broadband noise
measures bright and a crude centroid cannot tell "noisy" from "high". The
assert says loudest and longest, which is true, and says out loud in a
comment why it does not say brightest. What it does assert about the shape is
that the bite **rises**: 1017 Hz in its first half against 1306 Hz in its
second, measured by zero crossings off the file.

All of that is measured off the WAVs the generator wrote, read as bytes,
because Godot imports these to QOA and QOA is lossy - the question is what
the recipe produced.

### The pitch wanders six per cent

Chopping one tree is twenty swings and a player hears the same three hundred
milliseconds twenty times a minute. Identical every time it stops being wood
and becomes a sample, so `Audio` gives every **SFX** voice a pitch a little
either side of one. Six per cent is enough that no two are the same and small
enough that none sounds wrong; past about a tenth the low notes start reading
as a different axe.

Only the SFX bus. Music and ambience are long and tonal, and a loop that came
back a semitone out would be the most noticeable thing in the game.

It draws from its **own** generator rather than the global one, so that
seeding the globals - which `src/tools/shot.gd` does to make the smoke
reproducible - does not also decide what the next swing sounds like.

`tools/gen_sfx.py` reads `PITCH_JITTER` out of `audio.gd` rather than keeping
a copy, so the minute of chopping it renders is the minute the game plays.

### A flake I introduced and then removed

`verify.py` failed `input_check` once with one case down, and three runs on
its own all passed. The mechanism was real and mine: task 0083's audio case
cleared the voice pool and then let two frames pass before measuring it, and
this task put an `Sfx` node in the scene that can make a noise in those two
frames. The clear now happens with nothing between it and the measurement.

A test that fails once in a while for a reason that has nothing to do with it
is worse than one that fails every time.

### The done-when I cannot check

"Chopping a tree for a full minute does not become annoying - **go and
check**" needs ears. `python tools/gen_sfx.py --preview <dir>` renders sixty
seconds of chopping at the rate the game plays it with the jitter the game
applies, plus a copy of each sound, and that went to the owner to listen to.
Said here rather than ticked off on a measurement that cannot answer it: peak
and length say a sound is not harsh, they do not say it is not tiresome.

### Hashes

Both unchanged - `2555959448` and `2601044827`. Sound is not a rule.

`python tools/verify.py` prints PASS: 5305 asserts, 699 input cases, 0 failed,
with a new `sfx` row. `exports` is still the one SKIP and still wants the
Godot export templates.

## 0085 - The sounds of the night - done 2026-09-28

What changed: fourteen night sounds from the same generator, a distance
falloff in `Audio`, and `Sfx` grown a night half. Four defences and the mine,
five enemy voices, and the four things that happen to them - an impact, a
death, a wall going and the house being hit. Twenty-seven sounds in the game
now, all of them arithmetic.

Files: `tools/gen_sfx.py`, `assets/sfx/` (14 new WAVs), `src/app/audio.gd`,
`src/ui/sfx.gd`, `src/tools/headless_check.gd`, `src/tools/input_check.gd`.

Verify: 5380 headless / 707 input / both hashes unchanged.

### Fifty zombies do not turn into noise

The done-when, and the thing the whole night design turns on. **Groans are
per kind, not per body.** Fifty walkers are one voice - the walkers groan,
now and then, from wherever the nearest one is standing - so the rate is
fixed by how many *sorts* of thing are out there, which is at most four.

The first version of the test for this was going to count noises over a
stretch of frames and see whether the number went up with the crowd. It
would have been useless: the groan chance is `delta / 2.6` a frame, and in a
headless check `delta` is a fraction of a millisecond, so nothing would have
groaned and the test would have passed on an empty sky.

So `Sfx.nearest_by_kind()` is public and the check asks **the claim**
directly: five walkers are one voice, fifty walkers are still one voice, and
a walker plus a runner plus a tank are three. Made per-body as an experiment
it fails with `51 bodies making 51 voices`, which is precisely the sound the
requirement is about.

### A shot is a reload counter going up

`reload` counts down every tick on the occupant, so the one tick it **rises**
on is the tick the thing went off - the same reading `world_view.gd` already
uses to put a muzzle flash in the right frame. Same shape as the
`left + tick` invariant task 0084 used for the day's verbs: the rules record
a countdown, and the view reads the edge rather than guessing from a
projectile it can see.

### The alarm, and the roar

**The house being hit is the loudest sound in the game** at 0.95, against
0.88 for the Giant and 0.70 for everything else at night. It is the only
sound that means you are losing, and a game where the alarm is quieter than
the gunfire has buried its own bad news. It is the one sound built to be
unpleasant on purpose: a low boom, a bright crack, and two notes a semitone
apart, which is the interval every alarm ever made is built on. Asserted
against every other WAV in the folder rather than against a list, so a
fifteenth night sound cannot quietly outgrow it.

**The Giant is audible before it is visible**, which turned out to mean two
separate things and both are asserted. Its roar is the longest sound in the
game at 1.4 seconds, and `Sfx` plays it with **no position at all**, so the
falloff leaves it alone and it arrives at full volume from the far fence. It
is also the only enemy sound that rises where the rest fall, because
something arriving and something dying should not sound the same.

### The falloff is linear on purpose

`Audio.loudness(ears, at)` is full volume within a tile and a half, falls to
a floor of 0.3 at four hundred and eighty pixels - a screen width, so **a
thing you can see is a thing you can hear** - and stays there.

Linear rather than inverse-square, and it is a deliberate wrong answer:
inverse-square is right for a point source in open air and wrong for a game
where a wave chewing the fence you are not standing at is the thing you most
need to be told about. Physics is not the brief; legibility is. The floor is
0.3 rather than zero for the same reason, and there is an assert that says so
in words.

It is a static function for the same reason `is_silent` is: the rule is the
part with a decision in it, and a check should ask it straight rather than
infer it from a voice's volume.

### Two asserts that were wrong before they were right

- **"A defence with no `reload_ticks` has no sound."** Failed on the mine,
  which is `one_shot`, never reloads, and is certainly not silent. The rule
  is that a defence with **`damage`** makes a noise and one with only
  `path_cost` does not: things that hurt are heard, things that block are
  furniture.
- **Task 0084's "nothing in the folder is unreached"** went red the moment
  fourteen night files landed. That is the check working, not the check being
  wrong - it now reads both halves.

### The done-when I cannot check

"With eyes closed, a night's audio says roughly what is happening" needs
ears. `python tools/gen_sfx.py --preview <dir>` now renders `_a-night.wav`:
twenty-one seconds of the night's sounds in the order the game would play
them, at the volumes the falloff would give them - a wave in the distance,
the guns answering, the Giant at nine seconds, a wall at twelve, the house
taking two hits at fourteen. It went to the owner to listen to.

The timeline reads `NEAR`, `EARSHOT` and `FAR_FLOOR` out of `audio.gd` rather
than keeping copies, so what it renders is what the game would play. Same
reason `pitch_jitter()` does.

### Hashes

Both unchanged - `2555959448` and `2601044827`. Sound is not a rule, and the
night's watchers are all in `src/ui/`.

`python tools/verify.py` prints PASS: 5380 asserts, 707 input cases, 0 failed.
`exports` is still the one SKIP and still wants the Godot export templates.

## 0086 - Two pieces of music - done 2026-09-28

What changed: a warm ninety-six second loop for the farm, a cold one for the
night built from the same motif, an urgent layer that arrives on the last
wave, and a crossfade that is exactly as long as the switch of reality
because it is the same number. `tools/gen_music.py` synthesises all three
from the same primitives the sound effects use.

Files: `tools/gen_music.py` (new), `assets/music/` (3 generated WAVs, new),
`src/ui/music.gd` (new), `src/app/audio.gd`, `src/app/settings.gd`,
`scenes/Main.tscn`, `src/ui/main.gd`, `tools/verify.py`,
`src/tools/headless_check.gd`, `src/tools/input_check.gd`.

Verify: 5406 headless / 720 input / both hashes unchanged.

### The loop point is inaudible by construction, and then measured

Two techniques, and between them there is no seam left to hear:

- **Every sustained partial is snapped to a harmonic of the loop.** A sine at
  146.83 Hz does not fit a whole number of times into ninety-six seconds, so
  it comes back to the seam part-way through a cycle and steps. `snap()`
  moves it to the nearest frequency that does fit - at most a fifth of a
  hertz, which nothing can hear.
- **Anything struck wraps round.** A note in the last bar whose tail runs
  past the end is written back over the beginning rather than truncated. A
  truncated decay is the classic way a loop clicks.

Then it is measured, and the threshold was measured too rather than picked.
A click is a discontinuity, so the join is compared against the track's own
**ninety-ninth percentile step** - "no more abrupt than things this music
already does". The three pieces come in at 0.60, 0.73 and 0.41. Chopping five
thousand samples off the end of one, which is exactly the mistake the
wrapping prevents, scores **5.9**. The threshold is 1.0, with daylight on
both sides of it.

The percentile rather than the average, because a dense mix has a big average
step and a quiet one a small step, and the average would set a different bar
for each piece.

### One number for the crossfade, not two

The done-when is that the crossfade lands *with* the switch of reality, not
before or after it. So the length is not a number in the music: it is
`WorldView.transition_seconds()`, which is what the screen fades on -
`GameData.TRANSITION_SECONDS` unless the player has overridden it.

`input_check` does not time either of them. It clicks the button, waits for
**the transition** to finish, and then asks whether the music has too. With
the fade untied and made six times too long it fails with the night's music
at 0.21 and the farm still at 0.17 - which is precisely "the crossfade did
not land with the transition", said in numbers.

### They share a motif

`MOTIF` is one list of eight scale degrees. The day plays it in a major scale
at one note a half-beat, every fourth bar; the night plays the same list in a
minor scale, an octave down, one note a beat, every eighth bar. Same shape,
same farm, different hour.

The check reads the generator's source and asserts the motif is one list that
both arrangements mention, because a shared motif that has been copied into
two lists is shared right up until somebody edits one of them.

Both pieces are at the same tempo on purpose. **A crossfade between two
tempos is a stumble**, and the one moment these two ever meet is the moment
the player switches reality; the night is sparser instead, which reads as
slower without fighting the day on the way past.

### Two asserts that the new setting broke, and only one of them was right

Adding `audio/music_in_menus` turned two existing checks red.

- Task 0009's "the audio group is five settings" - now six. A counted
  constant, and it stays: a group is an options tab, and a key arriving in
  one without anybody drawing a control for it should be a failing row.
- Task 0083's "every `audio/` key except `audio/muted` turns a bus" - **that
  rule was simply wrong**, and it took a second flag to show it. It says "a
  float turns a bus, a bool is a switch" now, which maintains itself: a new
  volume must have a bus, a new flag is allowed to be a flag.

### Decisions worth saying out loud

- **Ninety-six seconds, not a round two minutes.** The loop is seamless, so
  nobody can tell the two apart, and the difference is two more megabytes of
  WAV in a repository whose source is two megabytes. Said here rather than
  quietly counted as "a couple of minutes each".
- **The music deck is not the voice pool.** Two crossfading slots and a layer
  of their own, because a ninety-six second loop taking one of sixteen shared
  voices and never giving it back would be a gunshot lost every time the
  music started.
- **The result screen keeps the night's music.** The payout is read with the
  night still in the air; snapping to the farm the instant the last zombie
  fell would take the weight out of having survived. The music turns over
  when the day does, which is when the screen does.
- **Looping is set in code, not on the import.** Godot's WAV importer has an
  `edit/loop_mode` and `.import` files are generated - a setting that comes
  back the next time somebody reimports. One line in `Audio._looping` cannot
  be undone by a tool.
- `Music.in_menu` exists and **nothing sets it yet**: tasks 0091 and 0092 are
  the title screen and the router. The rule and its check are here now so
  that 0091 gets a failing assert rather than silence if it forgets.

The music costs thirteen seconds on every `verify` run, which is the price of
the `--check` row rendering three minutes of audio to compare it. Worth it
for the same reason as the sprites: a WAV nobody can regenerate is a WAV
nobody can change.

### The done-when that needs ears

"The loop point is inaudible" is measured above, but a measurement is not an
ear. `python tools/gen_music.py --preview <dir>` writes `_loop-seam.wav` -
the join run past you six times, eight seconds either side of it - and
`_crossfade.wav`, the farm giving way to the night over the transition's own
length, read out of `game_data.gd`. Both went to the owner.

### Hashes

Both unchanged - `2555959448` and `2601044827`. Music is not a rule.

`python tools/verify.py` prints PASS: 5406 asserts, 720 input cases, 0 failed,
with a new `music` row. `exports` is still the one SKIP and still wants the
Godot export templates.

## 0087 - Ambience - done 2026-09-28

What changed: a bed under everything. Two sixteen-second loops that crossfade
with the sky, nine one-shots fired at intervals between four and eleven
seconds, and `Audio.duck()` to get the whole Ambience bus out of the way when
something matters.

Files: `tools/gen_ambience.py` (new), `assets/ambience/` (11 generated WAVs,
new), `src/ui/ambience.gd` (new), `src/app/audio.gd`, `src/ui/sfx.gd`,
`scenes/Main.tscn`, `src/ui/main.gd`, `tools/verify.py`, `tools/gen_sfx.py`,
`tools/gen_music.py`, `src/tools/headless_check.gd`,
`src/tools/input_check.gd`.

Verify: 5455 headless / 728 input / both hashes unchanged.

### Two short beds, not two more long loops

The obvious build was two more ninety-six second pieces like task 0086's, and
it would have cost **eight more megabytes and still been a loop**.

A bed of filtered noise can be sixteen seconds and nobody will ever notice,
because there is no tune in it to recognise. What makes a farm sound alive is
the bird that calls now and then - and a bird baked into a sixteen-second
loop is the one thing a player *would* notice. So the beds are short and
continuous, and everything with a shape to it is a one-shot fired at gaps the
controller picks. Eleven files, 1.7 MB, and the touches never repeat.

**And the positional requirement fell out for nothing.** A lap of water is
played at the pond's own cell and goes through the same falloff a gunshot
does, so it is louder when you are standing next to the pond. Birds come from
the nearest tree; something groaning comes from the far edge of the farm. No
new machinery at all - task 0085 had already built it.

### Looping noise

`gen_music` loops a pad by snapping its partials to harmonics of the loop.
Noise has no partials to snap, so the answer is the older one: render a
little more than a loop's worth and **fold the overhang back over the
beginning**, so the end is already becoming the start by the time it gets
there. Measured the way 0086 measures music - the join against the track's
own ninety-ninth percentile step - the beds come in at **0.05 and 0.39**
against a threshold of 1.0.

### Ducking, and the done-when it exists for

"The ambience never masks the house-damage sound" is not a matter of taste,
so it is not left to one. `Audio.duck()` drops the **bus**, so everything
ambient gets out of the way together and nothing has to remember to; `Sfx`
calls it on the house, on a wall going and on the Giant's roar.

A quarter rather than silence: the bed vanishing is as noticeable as the bed
being too loud, and the point is to get out of the way rather than to
disappear. Down at once and back over 1.8 seconds, and a second hit while the
first is still ducking **extends** it rather than restarting, so a house
taking three blows does not pump.

The headroom is asserted rather than assumed: the bed peaks at 0.22, ducks to
**0.055**, and the alarm peaks at **0.95**. Seventeen times, measured off the
files. `input_check` then walks the whole chain - hit the house, and the
Ambience bus is really quieter in decibels. Disconnected, it fails with
`-3.1dB against -3.1dB`, which is the bus not moving at all.

### It lives in `src/ui/` and the prompt said `src/app/`

The prompt's likely file was `src/app/ambience.gd`. This reads the phase, the
terrain and where the farmer is standing - which is game state, and
`src/app/` is services: nodes, disk, the audio server. `Music` and `Sfx` are
in `src/ui/` for exactly that reason and this is their third sibling.

What *is* in `src/app/` is the part that belongs there: `Audio.duck()`, which
knows about buses and nothing about farms.

### One reader for numbers that live in GDScript

Three generators now need to know things the game has already decided - the
pitch jitter, the distance falloff, the transition's length, how long the bed
waits between birds. Each had started reading them out of the GDScript by
hand, which was about to be the fourth copy of the same eight lines.

`gen_sfx.gd_number(path, name)` is that reader, and `gen_music` was moved onto
it in passing. Two numbers that have to match and live in different files are
two numbers that will not, and now there is one place for that habit to
break rather than three.

### The deck grew a second pair

`Audio` had two crossfading music slots and a layer. It has five named slots
now - `MUSIC_A`, `MUSIC_B`, `MUSIC_LAYER`, `BED_A`, `BED_B` - and one
`_crossfade(a, b, id, seconds)` that the music and the bed both use, because
they are the same problem: two players, and one of them is winning.

### The done-when that needs ears

"Standing still on the farm for a minute is pleasant, not empty" has no
measurement that answers it. `python tools/gen_ambience.py --preview <dir>`
renders exactly that minute, by day and by night: the bed looped, with
touches at the same gaps the game picks and the same falloff applied, from
the sort of distances the farm puts them at. Both went to the owner.

### Hashes

Both unchanged - `2555959448` and `2601044827`.

`python tools/verify.py` prints PASS: 5455 asserts, 728 input cases, 0 failed,
with a new `ambience` row. `exports` is still the one SKIP and still wants the
Godot export templates.

## 0088 - Juice: shake, hit stop, damage numbers - done 2026-09-28

What changed: a kill feels like a kill. The camera shakes, the world stops for
four frames on a big hit, damage floats up in the colour of what dealt it, and
a body flattens where it fell. `src/ui/juice.gd` watches and decides; nothing
about it reaches the rules. Screenshots: `implementation/shots/0088/`.

Files: `src/ui/juice.gd` (new), `src/ui/world_view.gd`, `src/ui/sim_driver.gd`,
`src/ui/sfx.gd`, `src/app/settings.gd`, `scenes/Main.tscn`, `src/ui/main.gd`,
`src/tools/shot.gd`, `src/tools/headless_check.gd`,
`src/tools/input_check.gd`.

Verify: 5485 headless / 738 input / **both hashes unchanged**, which is the
done-when.

### Hit stop, and why the hash proves it is safe

A hold does not touch `TICK_HZ` and does not touch `Engine.time_scale`. It
stops `SimDriver` for a sixteenth of a second, and the ticks that were going
to run still run, at the same fixed rate, a moment later. **The simulation
does not measure itself in real time**, so a run that was held and a run that
was not reach the same state at the same tick.

`input_check` says exactly that: a control state advanced four hundred ticks,
and a live run held for four tenths of a second half way through and then
advanced to the same four hundred. Same hash. It also asserts that no tick
runs while the hold is on, so the test cannot pass by the hold doing nothing.

There is a source check too, because the way this goes wrong is somebody
reaching for `time_scale` in a year. **It failed first time on my own
comments** - both files explain in prose that they do not touch it, and the
check read the explanation as the offence. It skips comments now, which is
what task 0081's override check already knew.

### Where the damage type comes from

Exactly, and without asking the rules for anything new - which matters,
because "none of it touches the hash" and a new key on an entity is a moved
hash.

A shot in flight is in `state["projectiles"]` and **carries its own `type` and
`target`**; when one disappears it has landed, so the damage its target takes
that frame is that type. A flame tower has no projectile, but its victims are
in `state["burning"]`. A mine has neither and is spotted by a `one_shot`
defence that is no longer there. Three signals, all already kept, nothing
guessed.

### A bug in task 0085 that this task's watching exposed

The same signal that types explosive damage is the one that should have
sounded a mine. Task 0085 watched every defence vanish and sounded all of
them as breaking timber - so the mine's own blast, which it had a sound
drawn for, **never played once**. A `one_shot` defence leaving the board is
the one going off; anything else leaving it has been knocked down.

### Two things the screenshots said and no assert could

The wave shot came back with a battle in it and **not one damage number**.
Not a bug in the juice: `shot.gd` did all its work in one `Sim.advance` and
then held still for thirty frames, and the view notices things by comparing
this frame with the last one. Every blow had landed before `Juice` had a
first frame to compare against. The shot tool runs two ticks on each settle
frame now, which is a fixed number, so two runs still tick identically.

Then every corpse came back as a **solid white rectangle**. The death art has
not one white pixel in it, so nothing was being drawn but a box. I did not
chase that through the renderer: corpses go on the screen the way every other
picture in this game does, as a `Sprite2D` with a texture and a scale.
`particles.gd` is the hint - it is on the same layer and draws only
rectangles, so no code in this project was drawing a texture in `_draw`
there.

**A known limitation, said out loud:** where four zombies stand together their
numbers still pile up into one pale blob. Per-entity batching, a hard cap of
twenty-four and a deterministic sideways nudge by entity id all help and none
of them solves it, because two numbers in the same place at the same moment
is what floating damage numbers do. It is legible when the crowd is not
shoulder to shoulder, which is most of a night.

### Batching, and a test that proved nothing twice

"Batched when many land at once" turned out to be the hardest thing here to
test honestly.

The first live test hit one zombie three times and asserted one number. It
passed - **and it passed with the batching removed**, because three hits in
one frame are one drop in hit points, so there is nothing to batch. The
second version waited on `waiting_to_show() == 0`, which is true before the
hits have been noticed as well as after they have come out, so it returned at
once and measured an empty screen.

The answer was that at any frame rate a suite actually runs at, hits in a row
land in the same frame - a live test **cannot** tell gathering from not
gathering. `gather` and `ripen` are public now, with a comment saying why,
and `headless_check` drives them directly: two hits on one thing are one
entry and then one number reading five; two hits on two things are two.
Removed, it fails with `3 showing, 6 total`.

And one more of my own traps: the live case called `driver.start()` instead
of `Main.begin_run()`, which replaces the state dictionary and leaves every
screen watching the old one. That is the exact failure `begin_run` was pulled
out of `_ready` at task 0082 to prevent, and I walked into it in a test.

### Everything can be turned off

- `a11y/screen_shake` is a dial. At zero the camera does not move **at all**,
  not less - which is what somebody prone to motion sickness needs it to
  mean, and what `input_check` asserts.
- `a11y/hit_stop` is its own switch rather than sharing the shake's: they are
  different complaints. One is motion, the other is the game not answering
  the keyboard for a sixteenth of a second.
- `video/damage_numbers` turns the numbers off, and nothing is left waiting.

The shake is capped at six pixels of a two-hundred-and-seventy pixel screen.
The house asks for nine, so the cap is the thing that decides - asserted, so
that a bigger number somewhere cannot quietly become the ceiling.

### Hashes

Both unchanged - `2555959448` and `2601044827`. That is the whole point of
the task and the reason the hit stop is a hold rather than a slowdown.

`python tools/verify.py` prints PASS: 5485 asserts, 738 input cases, 0 failed.
`exports` is still the one SKIP and still wants the Godot export templates.

## 0089 - Tooltips - done 2026-09-28

What changed: fifty-eight things in the game explain themselves. Resources,
defences, buildings, recipes, tech nodes, enemies and crops, every figure read
out of `GameData` at the moment it is asked for. Screenshot:
`implementation/shots/0089-tooltip.png` - a tech node reached by keyboard,
saying what it costs, what it does and what it needs first.

Files: `src/ui/describe.gd` (new), `src/ui/tooltip.gd` (new),
`scenes/Main.tscn`, and one line each in `build_mode.gd`, `tech_panel.gd`,
`inventory_panel.gd`, `workshop_panel.gd` and `shop_panel.gd`.

Verify: 5566 headless / 748 input / both hashes unchanged.

### Never a copy of a number, and a check that means it

Every line of every tooltip is built from `GameData` when it is asked for.
The done-when is "changing a lever changes the tooltip with no other edit",
and the check asks it the only way that can be true: it takes the **live**
figure out of the table and demands the text contain it.

Hardcoding one defence's hit points as a test makes it fail eight times over,
each naming the tooltip it read:

    the auto_crossbow tooltip says its live hit points  50 not in:
    AUTO CROSSBOW / costs 20 iron, 15 wood / 40 hit points / 5 impact
    damage / reaches 7 tiles / fires every 0.5s / draws 3 power

Costs, damage, ranges, reloads, power draws, rewards, growth times and tech
costs are all checked that way. Times are in **seconds** and never in ticks,
which is asserted too: ticks are the rules' unit and seconds are the only one
a player has.

### One line per row, and no describing code in any panel

A control carries `set_meta(&"describes", &"defence:gun_tower")` and that is
the whole of what a panel does. `tooltip.gd` polls what is hovered and what
has focus, walks **up** from there - a row is three labels and the player is
pointing at one of them - and resolves the key through `Describe`.

Fifty-eight keys, and the list of them is built from `GameData` rather than
typed, so a sixth enemy or a thirteenth recipe is undescribed for exactly as
long as it takes to run the check.

### Why not Godot's own tooltips

`Control.tooltip_text` very nearly does this, and task 0081 had already themed
`TooltipPanel` and `TooltipLabel` for it. Two of the requirements are the ones
it cannot meet:

- **No delay moving to the next thing.** Godot waits its full delay again for
  every control, so reading a row of five structures costs two and a half
  seconds of waiting. The delay exists to stop a tooltip flashing at somebody
  crossing the screen; once one is up, that has already been decided.
- **Keyboard focus shows the same tooltip.** Godot's appears for the mouse and
  nothing else, so a player on a pad is told nothing at all.

Focus beats hover, because a player using the keyboard is not using the
mouse, and a cursor left lying over something would otherwise describe the
wrong thing for the rest of the night.

### It never leaves the screen

Clamped on both axes and **flipped above the cursor rather than squashed**
when there is no room below. `place_at` is static and takes the cursor, the
panel and the screen, so the check walks it round all four corners of a
480x270 screen, far outside it both ways, and past it with a panel bigger
than the screen - which is pinned rather than pushed off.

### Three of my own traps in the live case

None of these were bugs in the tooltip. All three were the test being wrong
about the game.

1. **The tech panel had focus.** The case opened it to count the marked
   controls, which gave a node focus - and focus beats hover, so the wood row
   in the shop explained "true sights". That is the design working. The tech
   tree's buttons exist whether or not its panel is up, so the count does not
   need it open.
2. **The inventory covered the shop.** Made visible for the same count, it
   sits over the middle of the screen, so the cursor landed on an inventory
   row while the test thought it was pointing at a shop one - the wood row
   explained iron. Counted and then put away.
3. **`Input.warp_mouse` lied in the diagnostic.** The GUI is driven by the
   pushed event in canvas coordinates, which is what `click_control` already
   does; warping the real cursor as well put it in window coordinates - three
   times larger on a 1440x810 window - so the failure message reported a
   position nothing had been tested at. The warp is gone.

The case also left focus and an open panel behind, which failed a *later*
case about the night still running. It tidies up after itself now.

### What is deliberately not described

Action buttons - repair, flare, speed, "back to the farm", the shop's buy and
sell buttons - carry no key. The requirement names resources, structures,
recipes, tech nodes and enemies, which are **things**; a button that does
something is explained by its own label, and a tooltip on "1" saying "buys
one" is noise. Said here rather than quietly counted under "every
interactive element has one".

Enemies are described and nothing hovers them yet: their entry is the tooltip
a future wave-preview or bestiary will use, and the text is checked against
`GameData.ENEMIES` today so it cannot rot before then.

### Hashes

Both unchanged - `2555959448` and `2601044827`. `Describe` is static, takes no
state, and reads only the tables.

`python tools/verify.py` prints PASS: 5566 asserts, 748 input cases, 0 failed.
`exports` is still the one SKIP and still wants the Godot export templates.

## 0090 - The log panel - done 2026-09-28

What changed: the rules keep a short record of what they did, and the view
reads it out. Four fading lines on the left while a night runs, and one key
opens the whole night as a scrollable history. Screenshot:
`implementation/shots/0090/wave.png` - "night 1 begins" in grey, "wave 1 of
3: 3 walkers" in gold, two "fence destroyed" in red.

Files: `src/core/events.gd` (new), `src/ui/log_panel.gd` (new),
`src/core/state.gd`, `waves.gd`, `farm.gd`, `farming.gd`, `crafting.gd`,
`phases.gd`, `enemies.gd`, `scenes/Main.tscn`, `src/ui/main.gd`,
`project.godot`, `src/tools/headless_check.gd`, `src/tools/input_check.gd`.

Verify: 5630 headless / 764 input.

### The determinism hash moved, on purpose

**`2555959448` -> `215410677`.** The data hash is unchanged.

Task 0090's requirement is that "events are emitted by core as data", which
means the rules now keep `state["events"]` - and `State.hash_of` folds the
whole state. The done-when anticipates this and asks for both numbers, which
is what this paragraph is.

It is worth the move. Three view systems already work out what happened by
comparing this frame with the last one, and that is right for a spark, where
missing one costs a puff of dust. A **log** is a different promise: it says
what happened and in what order. At four times speed a frame is eight ticks
and seven of them are invisible, so a view that samples cannot make that
promise. The record is deterministic - same seed, same events - so the hash
is as stable as it ever was, just a different number.

### It cannot grow

Sixty-four entries, oldest dropped when the newest arrives. That is the
second done-when and it is the reason this is safe to put in a dictionary
that gets hashed, saved and copied: an unbounded list in there is a leak with
a long fuse. The check throws a thousand events at it and asserts both that
the cap holds and that the ones kept are the **newest**.

### Data, never words

An event is `{tick, kind, ...}` and `src/core/` contains not one sentence a
player reads. `LogPanel.line_for` is the only place in the game that turns an
event into English, which is what makes task 0097 a translation file rather
than a rewrite of the simulation.

Severity and colour are the view's too: nine kinds, each with a hold time and
a theme role, and `headless_check` fails if a kind the rules can record has
neither. **The alarming ones are held longer** - a wall coming down stays up
ten seconds, a night beginning four - which is asserted as arithmetic rather
than described.

### Two bugs found by writing it down

- **`kind` collided with `kind`.** The wave event carried the enemy under
  `"kind"`, and `Events.add` writes the *event's* kind into the record under
  the same name - so every wave line named the event instead of what was
  arriving. The field is `enemy` now, and `Events.add` **refuses** a caller
  that passes `tick` or `kind`, so the next one of these is an error rather
  than a wrong sentence.
- **The log replayed itself.** `show_state` set the read marker to -1, which
  on a fresh state is nothing and on a state that already had a night in it
  is sixty-four lines arriving at once. It marks everything already recorded
  as read: a log opens silent.

### A flake I did not write and could not leave

`input_check` failed about one run in three on a case from task 0056 - "and
the night is still running". It waits three frames and assumes a tick
happened, and three frames on a fast loop can be less than a thirtieth of a
second. It waits for the tick now.

It has presumably been flaky since it was written and was found while adding
something unrelated, which is the worst way to find one.

### Where the fade is asked rather than waited out

The holds are real seconds and this suite's frames go by far faster, so
waiting for the log to fall silent was eleven seconds of test and a timeout
when it was not quite enough. The case reads the countdown instead: a line
has a bounded time to run, it goes down while nothing happens, and a new run
opens silent. Together those are "it goes away", and none of them depends on
how fast the machine is.

### What is not here

Nothing hovers an event to find out more, and the history is the **night's**
rather than the run's - `Events.since` slices it at `night_tick`, so the day
before is in the record but not on that panel. A day's history is a different
panel and nothing has asked for one.

The determinism tool prints one `enter_result from RESULT` error, which is
pre-existing - checked by stashing this task's changes and running it. Its
scenario calls `enter_result` after a night that already ended on its own.
Harmless, and fixing it would move the hash for a reason that has nothing to
do with this task, so it is left for whoever owns that tool next.

### Hashes

Sim `2555959448` -> `215410677`, deliberate, for the reason above. Data
`2601044827` unchanged.

`python tools/verify.py` prints PASS: 5630 asserts, 764 input cases, 0 failed.
`exports` is still the one SKIP and still wants the Godot export templates.

## 0091 - The title screen - done 2026-09-28

What changed: the game boots into a game. The farm at dusk behind the
wordmark, the light going cold, and walkers coming in across the same tiles
the crops are growing on. Screenshots: `implementation/shots/0091-ident.png`
and `0091-menu.png`.

Files: `src/ui/title_screen.gd` (new), `scenes/Title.tscn` (new),
`tools/gen_logo.py` (new), `assets/logo.png` (generated), `project.godot`,
`tools/verify.py`, `implementation/prompts/0092-main-menu.md`,
`src/tools/headless_check.gd`, `src/tools/input_check.gd`.

Verify: 5653 headless / 783 input / both hashes unchanged.

### The backdrop is the farm, not a picture of one

`Title.tscn` instantiates the same `World.tscn` the game runs, with a
scripted state sat at dusk and creeping on. Task 0071's light ramp does the
rest, and `Relight` is found by name, so the title gets the game's own sky
for free.

**The first version held it at dusk and never got dark**, which is a green
field in slightly warm light: a farming game, and only half the premise.
What says what this game is is the light going *cold* on the same tiles with
something walking in from the fence. It asks for the night the way a player
does - by writing `intent["begin_night"]`, not by setting the phase - and
five walkers arrive once it is dark. Then it goes back to dusk and does it
again, because the one thing a title screen must not do is end.

That was found by looking at the first screenshot. Nothing would have failed.

### The logo is the game's own letters

The obvious reading of "generated with the same tools" is an ASCII map in
`sprite_maps.py`, and a wordmark two hundred and fifty pixels wide is eight
thousand characters of hand-drawing - which is the exact thing
`tools/font_maps.py` exists to stop. So `tools/gen_logo.py` composes it out
of the font at **four times size**, which is task 0080's heading argument
again: a whole-number scale of a bitmap is still a bitmap.

The moon is drawn there because a circle is not a letter. It was over the T
of HARVEST at first - you could read the word, but you could see it had been
asked to share - so the canvas makes room for it on the right instead.

A logo that is the game's own type cannot drift away from the game's look,
which a separately drawn one would the first time the font moved. There is a
`logo` row in verify that regenerates and compares, and a check that every
colour in it is off the palette.

### Absent, not greyed - and the rule generalises

Task 0091 says Continue is absent rather than greyed when there is no save,
and the reason is good for more than Continue: a greyed button is a promise
the game is not keeping, and a player cannot tell whether it is broken or
they are. So `TitleScreen.is_shown` decides every entry the same way.

**Options is in that state today and I am saying so rather than shipping a
dead button.** The options screens are tasks 0093 to 0095 and the router that
would open them is 0092; nothing exists to open, so the entry is absent by
the same rule that hides Continue. `implementation/prompts/0092-main-menu.md`
has been given a requirement that puts it back, and `headless_check` asserts
it is hidden *for that reason* - so the day somebody builds the screen and
forgets the entry, the suite says so.

Continue, New run, Statistics and Quit all work. Statistics opens the records
screen that already existed, handed the profile off disk.

### Booting somewhere else did not break anything

`run/main_scene` is `Title.tscn` now. Every tool that wants the game itself -
`shot.gd`, `input_check` - loads `Main.tscn` by path and was unaffected, which
is worth writing down because it was the thing most likely to go wrong and
did not.

The new input case is the only one in the suite that opens something other
than `MAIN_SCENE`: it boots what a player boots, presses a key that is not a
named action, and reads the menu back.

### Hashes

Both unchanged - `215410677` and `2601044827`. A title screen runs its own
backdrop state and touches nothing the game's own run holds.

`python tools/verify.py` prints PASS: 5653 asserts, 783 input cases, 0 failed,
with a new `logo` row. `exports` is still the one SKIP and still wants the
Godot export templates.

## 0092 - The main menu and the router - done 2026-09-28

What changed: one place decides which screen is up. `App` is an autoload with
eight states, a back stack and a `state_changed` signal; the title, the run,
the tech tree, the records screen and the new options frame all ask it and
listen to it, and none of them knows the others exist.

Files: `src/app/app.gd` (new), `src/ui/options_screen.gd` (new),
`src/ui/title_screen.gd`, `src/ui/main.gd`, `src/ui/stats_screen.gd`,
`src/ui/tech_panel.gd`, `scenes/Title.tscn`, `scenes/Main.tscn`,
`project.godot`, `src/tools/headless_check.gd`, `src/tools/input_check.gd`.

Verify: 5691 headless / 802 input / both hashes unchanged.

### Two sorts of state, and the bug that taught me the difference

`TITLE`, `MENU` and `RUN` are whole scenes; `TECH`, `STATS`, `OPTIONS` and
`SUMMARY` sit over whichever one is up. Going to a scene **clears the stack**,
because there is no going back from a run into a title screen that no longer
exists. Going to an overlay **pushes**, which is the whole of "Options returns
to whoever opened it".

**The title's ident and its menu are two states of one scene**, and the first
version did not know that: the router reloaded `Title.tscn` the moment a key
moved from one to the other, so the screen came back and the key looked like
it had done nothing. `reset()` records the scene the state it is given lives
in, and `goto` only changes scene when the path actually differs.

That was found by `input_check` failing with `any key at all opens the menu 1`
- the state it was still in.

### Testing a router with no tree

Every decision in `app.gd` is arithmetic on an integer and an array, so
`headless_check` drives the whole machine without building a game: opens
Options from the menu and from a run and checks it comes back to each, stacks
the records screen over the options screen over a run and unwinds it one step
at a time, starts a run from inside Options and checks the stack is *gone*,
and pushes past the cap to check it refuses.

The one thing that needs a tree - actually changing the scene - is guarded and
counted, so a check can watch the router decide and read `last_scene()` back
while a player gets the scene.

Then `input_check` does the same two journeys through the real screens, which
is where "Options from the title and from the pause menu both return
correctly" is really answered - the pause menu is task 0096, so the run
stands in for it, and it is the same property either way. Making `back()`
always go to the title instead of popping fails five asserts.

### One door, whichever way you came

The records screen was reachable only by pressing R inside a run, because
task 0069 built it when there was no menu to put it on. Both the key and the
new menu entry now go through `App.goto(App.STATS)`, and `Main` is what opens
and closes the panel - so there is one way in and one way out, and a player
who opened it from the title leaves it by the same door as a player who
pressed R mid-night. The same for the tech tree and T.

### `/root/` is not banned; reaching across screens is

The requirement says no `get_node("/root/...")` between screens, and there is
now a check that walks every file in `src/ui/` and fails on one - with three
exceptions named in the check itself: `App`, `Settings` and `Audio`. Those are
**autoloads**, and they have to be reached by path, because `verify.py` parses
every script on its own with no autoloads registered and naming one is a parse
error for a file that is perfectly correct at runtime. An autoload is a
service; a screen is not.

### The options screen is a seam, and it is nearly empty on purpose

Task 0091 hid Options because nothing could open it. This is what opens it,
so it is back on the menu - and the frame it opens is a heading, a tab strip
and a Back that works. `register()` is where tasks 0093 (video), 0094 (audio)
and 0095 (controls) each put their screen, and the strip shows the tabs that
exist and no more: **absent, not greyed**, the same rule one level down.

With none registered it says "nothing to set yet" rather than showing three
tabs that open nothing. That is thin, and it is the honest amount of options
screen that belongs to a task about routing.

### What SUMMARY does not do yet

It is in the enum because the task lists it, and nothing drives it. The result
screen still decides for itself from the phase, which is machinery that works
and that three input cases depend on; rewiring it to the router would be churn
with no behaviour behind it. Said out loud rather than quietly counted - the
state is there for task 0096's pause menu and whatever comes after to use.

### Hashes

Both unchanged - `215410677` and `2601044827`. A router is not a rule.

`python tools/verify.py` prints PASS: 5691 asserts, 802 input cases, 0 failed.
`exports` is still the one SKIP and still wants the Godot export templates.
## 0093 - Options: video - done 2026-09-28

What changed: the video settings are applied. `Settings` has held
`video/window_mode`, `video/scale`, `video/integer_scaling`, `video/vsync` and
`video/max_fps` since task 0009 and **nothing had ever read them** - the game
came up at whatever `project.godot` said and those five keys were a promise
nobody kept. `Video` is a new autoload, the sibling of `Audio`, and
`OptionsVideo` is the first tab in the frame task 0092 left empty.

Files: `src/app/video.gd` (new), `src/ui/options_video.gd` (new),
`src/app/settings.gd`, `src/ui/options_screen.gd`, `project.godot`,
`src/tools/shot.gd`, `src/tools/headless_check.gd`, `src/tools/input_check.gd`.

Verify: 5725 headless / 821 input / both hashes unchanged.
Shot: `implementation/shots/0093/options.png`.

### The list marks the multiples rather than hiding the rest

The requirement is "a resolution list built from the monitor, **marking** the
integer multiples of 480x270", and the first version of this offered only the
multiples - a defensible-sounding rule that is wrong on the machines people
actually own. A 1366x768 laptop has no whole multiple at its own size, and
neither does a 1920x1200 monitor; a game that refused to run at native there
would be being clever at the player's expense.

So `sizes_on(monitor)` returns the multiples that fit **plus the monitor's own
size**, each entry saying whether it is a multiple and which one, and the
buttons wear that as an `x3` suffix. The note under them is the key to the
mark, and it does not name the multiples, because how many there are comes off
the monitor: the screenshot was taken on a 1440p machine and goes up to `x5`.

That needed somewhere to put a size that is not a multiple, so `video/size` is
a new settings key - a string, `""` when the multiple in `video/scale` is what
is wanted, `"1366x768"` when it is not. A string rather than a `Vector2i`
because the config file is read by hand as often as by the game.

**A non-multiple window is still crisp**, which is the reason it is safe to
offer at all: with integer scaling on, Godot's INTEGER stretch draws the
largest whole multiple that fits and puts bars round it.

### The countdown lives in the autoload, not in the screen

A fullscreen mode a driver refuses leaves a player looking at nothing, and the
control that would put it back is on the screen they can no longer see. So
every change of mode is provisional: it applies at once, arms
`REVERT_SECONDS = 8.0`, and goes back on its own if nobody presses KEEP.

Eight rather than the ten the task allows, because ten seconds of a black
screen is a long time when you are not sure the game is still running.

The screen only draws it. Every decision - which sizes fit, which are
multiples, how long the countdown is - is a static function over a `Vector2i`
in `video.gd`, which is the only way to test a resolution list built from
hardware: the checks hand it a 1366x768 laptop and a 4K monitor that nobody
here owns.

### Three things this got wrong, all found by the checks

**`--script` registers the autoloads.** The first version of the check added
its own `Settings` node to `root` to drive `Video` with; there was already one
there, so Godot renamed the new one and `Video` went on reading the first. The
tell was an assert reading mode 0 while the disk two lines later said 1. The
check uses the real autoload now.

**`is_inside_tree()` is false before the main loop starts.** Measured: a node
added to `root` during a `SceneTree`'s `_initialize()` reports false and
`get_tree()` on it is null, while the main loop's own `root` finds it fine.
`Audio` guards on `is_inside_tree()` for a good reason - `get_tree()` errors
outright otherwise - but asking `Engine.get_main_loop()` is true at every point
of a node's life and needs no guard at all.

**The tab did not follow the settings.** It redrew on its own clicks only, so
when the countdown ran out and `Video` put the old size back with nobody
touching anything, the size it had just taken away was still marked as chosen -
which reads as the revert having failed. It listens to `Settings.changed` now.
Found by an assert about the warning label, which is a smaller version of the
same bug.

### Square pixels off breaks coordinate input, in the harness only

`input_check` clicks by coordinate. With no window at all the root viewport's
final transform is the identity while the stretch is INTEGER and a 0.13 scale
with a fourteen pixel offset the moment it is FRACTIONAL - measured - so every
click after turning square pixels off lands somewhere else entirely.

That is a property of a 0x0 headless window, not of the game. The case turns
them off with a real click, checks the viewport and the warning, and turns them
back on through the setting, which is the same path the button takes. It is the
last thing the case does, so nothing clicks afterwards.

### The sixth screenshot scenario

`options` joins task 0082's five, so a settings tab can be looked at rather
than reasoned about. It is a noon farm with the frame over it, and tasks 0094
and 0095 draw into the same picture.

The count in the 0082 group is now six and is still a counted constant on
purpose, the same as the audio group's settings: a scenario arriving without
anybody deciding to add one should be a failing row.

Looking at it is what caught the note saying "x2 and x3 sizes" on a monitor
whose list runs to x5.

### The bugs planted to check the checks

- The 4K cap made a no-op: "a 4K list is capped at the five biggest" fails with
  8, and "starting at a size somebody would actually pick" with 480x270.
- The monitor's own size marked as a multiple: "two of them marked" fails with
  3, and the entry itself is printed.
- `revert()` never called: "every part of what worked before is back" fails
  with `2/2/'1366x768'`, and `input_check`'s "comes back on its own" with 3.

Two more were proved by accident while the autoload lookup was broken: the
frame cap not reaching the engine, and the countdown not arming.

### What is honest about "applies and survives a restart"

The restart half is real: the check writes a mode, builds a second `Settings`,
reads it off the disk and finds it. The applying half is only half testable
without a display - the frame cap and the stretch mode are watched because they
exist with no window, and the three `DisplayServer` calls that move the window
itself are skipped under headless and are not covered by anything. Said out
loud rather than quietly counted.

### Hashes

Both unchanged - `215410677` and `2601044827`. A window is not a rule.

`python tools/verify.py` prints PASS: 5725 asserts, 821 input cases, 0 failed.
`exports` is still the one SKIP and still wants the Godot export templates.
## 0094 - Options: audio - done 2026-09-28

What changed: the audio tab. Four levels, a mute, and a sound on each of them
so a number means something. `Audio` already owned the whole mechanism since
task 0083 - the four keys, which bus each turns, zero meaning silence rather
than eighty decibels down, re-applying on every change - and what was missing
was somewhere to turn them.

Files: `src/ui/options_audio.gd` (new), `src/ui/options_screen.gd`,
`src/app/audio.gd`, `src/ui/ui_kit.gd`, `src/ui/music.gd`,
`tools/gen_music.py`, `tools/sprite_maps.py`, `sprites/ui/slider_track.png`,
`assets/music/sting.wav`, `src/tools/shot.gd`,
`src/tools/headless_check.gd`, `src/tools/input_check.gd`.

Verify: 5769 headless / 837 input / both hashes unchanged.
Shots: `implementation/shots/0094/options_audio.png`.

### A test sound has to be on the bus it is testing

That is the requirement, and it has a consequence nobody would guess: a
sound's bus is the folder it lives in, so the music level can only be
auditioned by something in `assets/music/` - and everything in there was at
least nineteen seconds long. **So `gen_music.py` now makes a fourth piece**,
`sting`: three notes of the shared motif in the day's voice, 1.15 seconds,
peaking a little above the music because it is heard on its own rather than
under a game.

It does not loop and nothing asks it to - the loop-seam check names the three
pieces that do. Its seam measures 0.00 anyway, because it starts and ends in
silence.

Master is the one exception and cannot be otherwise: nothing plays on Master,
everything sends to it. Its test is a sound passing through it, which is also
what a player is asking about when they move that slider. The check asserts
that rather than pretending otherwise.

### Mute is a state over the levels, not a write to them

The two done-whens are one design decision. A zero slider is a level and comes
back as zero; mute is a state on top of whatever the levels are and comes back
to them. So the sliders stay live while muted and the numbers stay on the
screen - faint rather than gone, because they are still what the game will
sound like the moment it comes back.

Planting the classic wrong version - mute writes the four levels to zero -
fails four input cases, including "the master bus comes back", which it does
not: a master at zero is silent whether or not anybody unmuted it.

### The first slider in the game, and what it showed

Task 0086 drew slider art and named it in the kit. Nothing had put one on a
screen until now, and two things were wrong the moment one appeared:

**The filled part of the track was Godot's default grey** - measured at
(118, 116, 131), a colour in no palette this game has - drawn over the top of
the trough and hiding it completely. So a slider at seven tenths was a short
grey bar with nothing after it to be seven tenths *of*. `grabber_area` is now
gold and `grabber_area_highlight` brighter gold.

**And the trough never drew at all.** Godot draws it at the stylebox's own
height rather than the control's; the art was eight pixels tall with two blank
rows at the top and two at the bottom, and those four rows were the entire
thing. The map is four rows now with nothing transparent in it, and its fill
was `night` - which is the colour of the panel it sits on - so that is `ink`
inside an `ink_soft` edge.

Both were found by opening the picture, and neither is the kind of thing a
suite catches.

### `Audio` finds `Settings` the way `Video` does

`apply_volumes()` is the function with the first done-when in it, and a check
could not drive it: `Audio._settings()` guarded on `is_inside_tree()`, which
is false for anything a `SceneTree` check builds - so it silently read the
shipped defaults and every assert about it would have been vacuous. It asks
`Engine.get_main_loop()` now, the same as task 0093's `Video`.

That had a consequence worth writing down. Two earlier groups build an
`AudioScript` and abandon it, and an abandoned deck is now **subscribed to
`Settings.changed`** - so it re-applies the volumes behind the next group's
back, and the 0089 one is permanently ducked, because a duck decays in
`_process` and a loose node never gets a frame. `queue_free()` does not help:
it is deferred and nothing inside `_initialize()` reaches a frame. Both are
removed from the tree and freed outright now.

### One screenshot scenario per options tab

Task 0093's `options` scenario has become `options_video` and `options_audio`,
because three tabs in one screen cannot be photographed by making the screen
visible - only one of them is on it at a time. A scenario's screen may now
name a tab after a colon, and `shot.gd` opens it.

The count in the 0082 group is seven, and 0095 will make it eight. Still a
counted constant, for the same reason as before.

### Hashes

Both unchanged - `215410677` and `2601044827`. A volume is not a rule.

`python tools/verify.py` prints PASS: 5769 asserts, 837 input cases, 0 failed.
The sprite digest moved to `b72c23ef96f5` with the new slider trough, and the
music row now reads four pieces rather than three.
`exports` is still the one SKIP and still wants the Godot export templates.
## 0095 - Options: controls - done 2026-09-28

What changed: every key and every mouse button the game reads is a named
action, `Actions` rewrites the input map from `controls/bindings` at boot, and
the controls tab moves them. Twenty-five bindings, a clash that is refused by
name, and reset per row and for all.

Files: `src/app/input_actions.gd` (new), `src/ui/options_controls.gd` (new),
`project.godot`, `src/ui/build_mode.gd`, `src/ui/day_hud.gd`,
`src/ui/options_screen.gd`, `src/ui/ui_kit.gd`, `src/tools/shot.gd`,
`src/tools/headless_check.gd`, `src/tools/input_check.gd`.

Verify: 5899 headless / 862 input / both hashes unchanged.
Shots: `implementation/shots/0095/options_controls.png`.

### The defaults are the input map, not a second copy of it

A table of shipped bindings in `input_actions.gd` would be a second place to
edit and a second place to be wrong. So the first `apply()` **photographs
`InputMap`** before touching anything, and that photograph is what reset puts
back. `project.godot` stays the one place a default is written, and a check
reads its `[input]` section and fails if the two lists ever disagree.

Only the changes are saved. A binding that is not in `controls/bindings` is
the shipped one, so "reset this row" is an erase rather than a second table of
values to keep in step.

### Ten new actions, and the objection they answer

`pause` was missing and task 0096 needs it. The three mouse buttons in
`build_mode.gd` became `place`, `remove` and `upgrade` - **mouse bindings are
not a special case**: same storage, same clash rule, rebound by clicking, and
the only thing that knows the difference is `label_of()`.

The six number keys in `day_hud.gd` had an explicit note saying they stayed
raw on purpose - one action per crop would put a `plant_crop_4` in
`project.godot` every time somebody added a dictionary entry. That objection
is right and it is answered by binding **the position rather than the crop**:
`slot_1` to `slot_6` is a hotbar, and a hotbar has six slots however many
things exist. The note is rewritten to say so.

`debug_overlay` is deliberately not on the rebind screen, and the check that
compares the two lists skips it by name rather than by accident.

### The done-when is a check, not a shell command

"`grep` finds no raw keycode left in `src/ui/`" is now a group in
`headless_check` that walks the folder and fails with the file and line.
Putting a `KEY_9` back in `day_hud.gd` fails it with `day_hud.gd:266`.

### BACK has to get out of a rebind without closing the screen

The rebind listener is `_input` rather than `_unhandled_input`, because the
options frame also listens for BACK - and a screen that closes itself when you
cancel a rebind is a screen you cannot cancel a rebind on. Changing it to
`_unhandled_input` fails three input cases, one of them reading `MENU` where
`OPTIONS` was expected: the frame went back through itself.

### Three things the checks found

**A function that moves a key has to land it.** `bind()` wrote the setting and
trusted `Settings.changed` to re-apply - and in a check, where the autoload's
`_ready` never runs, nothing was listening, so six asserts failed with the
input map still on the old key. `bind()`, `reset()` and `reset_all()` call
`apply()` themselves now. `apply()` starts from the photograph every time, so
doing it twice costs a rebuild of twenty-five actions and changes nothing.

**And the screen has to follow the settings.** Found by a probe: rebinding
from anywhere other than this tab left every row showing the key it had just
taken away. The same hook the video and audio tabs grew.

**A scroll bar had never been dressed.** There have been three
`ScrollContainer`s in the game since task 0040 and every one had Godot's
default grey slab down its side - the same default grey the slider had at
0094, found the same way, by putting one on a screen and looking at it. A thin
dark groove with a gold grabber now, which reaches the log and the shop too.

### A picture I misread, and the assert I wrote instead

The first controls shot looked like the message line and RESET ALL had been
laid out off the bottom of the screen. They had not: both are hidden until
something is rebound, so there was nothing to see. Measured before believing
it - the frame is 216 pixels tall at y=26 and everything is inside 270.

The assert that came out of it is aimed at the real failure rather than the
imagined one: **every part of the footer is inside the viewport**, which is
what stops the next task's extra bindings pushing the buttons off the bottom
as the list grows. It fails at a 400 pixel list and passes at this one.
`ROOM` is 130 rather than 146 so the frame stays the height it was designed
at, which is a tidy rather than a fix.

### What "works immediately, and after a restart" really covers

Immediately is real and end to end: the input case rebinds RECORDS onto G,
opens a run, presses G and watches the records screen open - and presses R,
which used to do it, and watches nothing happen. After a restart is two
halves: `headless_check` writes a binding, builds a second `Settings`, reads
it off the disk and applies it with a second `Actions` onto an erased input
map; `input_check` erases the map inside a live game and rebuilds it. Neither
is a second process. Said out loud rather than quietly counted.

### Hashes

Both unchanged - `215410677` and `2601044827`. Which key does a thing is not
which thing is done.

`python tools/verify.py` prints PASS: 5899 asserts, 862 input cases, 0 failed.
`exports` is still the one SKIP and still wants the Godot export templates.
## 0096 - The pause menu - done 2026-09-28

What changed: P stops the world mid-night and offers four things - resume,
options, save and quit, abandon. `PAUSE` is a router state, `App.paused()` is
what `Main` turns the driver off, and the title's CONTINUE finally continues.

Files: `src/ui/pause_menu.gd` (new), `src/app/app.gd`, `src/ui/main.gd`,
`src/ui/sim_driver.gd`, `src/ui/title_screen.gd`, `scenes/Main.tscn`,
`src/tools/shot.gd`, `src/tools/headless_check.gd`,
`src/tools/input_check.gd`.

Verify: 5933 headless / 895 input / both hashes unchanged.
Shots: `implementation/shots/0096/pause.png`.

### The pause rule was written at task 0006 and nothing had ever turned it

`SimDriver.running` has been there since the driver was, with a comment naming
this task: a driver that is not running does not advance its accumulator, so
five minutes paused is five minutes of nothing rather than five minutes owed.
What was missing was something that turned it and a check that measured it.

Both done-whens are measured rather than argued. Two drivers, same seed, 240
frames of game each - one of them stopped for **three hundred frames of one
whole second** in the middle, which is what a window left alone actually hands
you. Same tick count, same `State.hash_of`, and the first frame back runs one
tick. Making the accumulator advance while paused fails all three: the frame
after the pause runs eight ticks and the two hashes come apart.

### `paused()` reads the stack, not the top of it

Options opened from the pause menu leaves the game stopped, and the screen
that would have to know that is not the one that does. So `App.paused()` is
true while `PAUSE` is anywhere on the stack, and `Main` turns the driver off
that. Reading only the top of the stack fails two asserts, one in each suite.

Abandoning is a change of scene, and a change of scene clears the stack - so
there is no way to end up at the title with the world still stopped.

`STATES` is nine now rather than eight. Deliberate, and still a counted
constant: a state arriving without anybody deciding to add one is a state
nothing routes to.

### Abandon asks twice, and the second question is the interesting one

The first press replaces the entry with **YES, ABANDON IT** and puts what is
about to be lost under it - the day, the nights survived, what is standing.
A confirmation that only says "are you sure?" is a confirmation people learn
to press twice without reading. Any other entry drops the question, and so
does closing the menu.

The panel is already tall enough for those two lines before they appear, so
pressing ABANDON does not move the other three entries out from under the
pointer.

### CONTINUE now continues, which is what makes saving worth doing

`title_screen.gd` has said since task 0091 that "the run on disk is picked up
by `Main`; task 0096 is what saves one mid-night, and until then this is the
same door as new". SAVE AND QUIT is that save, so this is the task that owes
the other half of it.

`App` carries a **one-shot**: CONTINUE sets it, `Main` takes it and it clears.
Loading automatically whenever a save existed would have been simpler and
wrong - `Save.write_run` already fires at the end of every night, so the
suite's first saved run would have been picked up by every scene opened after
it, and two hundred cases would have been testing somebody else's game.

`begin_run` and `resume_run` now share one `_hand_out()`, because two lists of
twenty `show_state` calls drift the first time somebody adds a screen. What is
*not* shared is `Stats.begin_run` - a run resumed from a save was counted the
day it started, and counting it again would make every quit and carry on look
like a new attempt.

### The router really does change the scene, which the harness had never seen

Every case in `input_check` opens its own scene. Pressing CONTINUE is the
first time a *button* brings one up: `App._change_scene` calls
`change_scene_to_file`, and a second `Main` duly appeared next to the one the
harness was holding, so the run under test was a fresh one and the assert read
`5 against 8`.

Found by probe rather than by reading, and the case is honest about it now -
it presses the button, waits for the deferred load, reads the run the router
brought up, and clears it away before carrying on the usual way.

### One more autoload lookup moved to the main loop

`SimDriver` asked for `/root/Settings` with `get_node_or_null`, which errors
from a node that is not in a tree - and driving the driver by hand is the only
way to measure what a pause does to the accumulator. It asks
`Engine.get_main_loop()` now, the same as `Audio`, `Video` and `Actions`.

### Hashes

Both unchanged - `215410677` and `2601044827`. **Which is the point of the
task**: a paused night resumed is the same night, and the hash is how that is
known rather than believed.

`python tools/verify.py` prints PASS: 5933 asserts, 895 input cases, 0 failed.
`exports` is still the one SKIP and still wants the Godot export templates.
## 0097 - English and Portuguese - done 2026-09-28

What changed: every word a player reads now comes out of a table. 321 keys in
two languages, 22 screens converted, a checker that measures the Portuguese in
the game's own font, a LANGUAGE row on a new GAME tab, and a language that
changes without a restart.

Files: `src/app/i18n.gd` (new), `src/ui/names.gd` (new),
`src/ui/options_game.gd` (new), `assets/locale/strings.csv` (new),
`tools/i18n_check.py` (new), every screen in `src/ui/`,
`src/app/input_actions.gd`, `src/app/video.gd`, `src/core/game_data.gd`,
`project.godot`, `tools/verify.py`, `src/tools/shot.gd`,
`src/tools/headless_check.gd`, `src/tools/input_check.gd`.

Verify: 5959 headless / 907 input / sim hash unchanged,
**data hash 2601044827 -> 2842078959** (below).
Shots: `implementation/shots/0097/noon-pt_BR.png`,
`options_controls-pt_BR.png`.

### One file with two columns, not two files

The task asks for "English and pt-BR CSVs". It is one CSV with a column each,
and that is better for a reason worth writing down: **a key present in one
file and missing from the other is invisible, and an empty cell in a row is
not.** The `width` column has the same argument - it belongs to the key rather
than to a language, and two files would have to keep two copies of it in step.

    key,width,en,pt_BR

`width` is how many **pixels** the control that draws the key gives it, and it
is the whole of the third done-when.

### The overflow check is the one that could not be done by eye

`tools/i18n_check.py` measures every line in the game's own glyph widths - the
same `gen_font.measure()` the `.fnt` is written from - and fails on one that
does not fit. It earned its keep immediately: **TUDO AO PADRÃO is 79 pixels in
a 72 pixel button** and **PIXEL QUADRADO is 81 in a 76 pixel column.** One got
shorter and one got a wider column. Neither would have been noticed until
somebody played in Portuguese.

It asks four other things nothing else can: a key the code uses and the table
has not got, a row nothing uses, a language with an empty cell, and - thrown
in because it cost nothing - the two languages using the same format
specifiers, so a line cannot silently lose its number.

### The keys are symbols, and `I18n` is static

`MENU_ABANDON`, not `"ABANDON RUN"`. English-as-key is how gettext works and
it is tempting; it collapses two English strings that happen to match, and
"BUILD" the verb and "BUILD" the noun are different words in Portuguese.

`I18n` is a `class_name` with static functions **and** the script behind the
`Locale` autoload. `verify.py` parses every script alone with no autoloads, so
`Audio` and the rest have to be found by path - and a path lookup at every
label would be absurd. A static class is nameable at parse time, so a screen
writes `I18n.t(&"HUD_DAY")` and nothing has to be found first. The node exists
only to hear `Settings.changed`.

### Nothing is concatenated, and plurals are rows

Every line is one row with its slots in it, so the translator decides the word
order. The one that proves it: `"  %d slot%s free" % [room, "" if room == 1
else "s"]` became two rows, because Portuguese does not make a plural by
adding a letter - and **"6 brutamontes" is the same word as one of them.**
`I18n.plural` picks a row; the bare key is the singular and `.other` is the
plural, so a word that does not change is written once.

Numbers are grouped the way each language groups them: 1,234,567 and
1.234.567.

### `Names` is where the ids become words

`src/core/` says `&"wheat"` and never says "wheat". Before this the id *was*
the name - screens printed `String(id).replace("_", " ")` and got "gun tower",
which is a translation system that works in exactly one language.

Every key in `Names` is a literal, and the shortcut `&"ITEM_%s" % id.to_upper()`
is deliberately not taken: the checker finds keys by reading the source, and a
key assembled at runtime is a key it cannot see - so a missing Portuguese name
would be found by a player instead. A check walks every table in `GameData`
and fails on an id nobody has named.

### The tutorial left `src/core/`

`game_data.gd` had a note on it saying task 0097 would translate the five
tutorial lines. It holds their **keys** now and none of their words, so a rule
file names a step and never speaks to a player.

**That is what moved the data hash**, deliberately: `2601044827 ->
2842078959`. The table it digests changed, because the value of `line` changed
from a sentence to a key. No rule moved with it - the sim hash is untouched.

The tech notes are the one place two copies remain, and on purpose: a note is
authored next to the lever it describes, which is where a designer wants it.
What is new is a check that the table's English **is** that note, so the two
cannot drift.

### Switching language mid-game

`Locale` hears the setting change, loads the other column and walks the tree
calling `relabel()` on everything that has one. A convention rather than a
signal, because the list of what needs redoing belongs next to the code that
does it - and it returns a count, so a check can say a screen was reached.

Boot does **not** relabel: every screen is built after the autoload and reads
the table as it builds. The first version did, and walking a half-built tree
reached the pause menu before its `_ready` had run - a null, found by
`shot.py --pt_BR` rather than by the suite.

`shot.py --pt_BR` is new and is how the Portuguese was actually looked at. It
found the seed strip still in English on a Portuguese farm: it is built once,
so unlike the rest of the HUD it does not come back on its own.

### What is not done, and why it is task 0110

`src/core/` still answers "why not" in English sentences - twenty-seven of
them across `building.gd`, `sim.gd`, `farm.gd` and `tech.gd`: "in the water",
"on the house", "short 4 wood". Translating them needs the answer to change
shape, from a sentence to a key and its arguments, and the arguments are ids
that the *screen* has to name. That is five functions and the thirty-odd
asserts that read their text, which is a task rather than a corner of one.

**Task 0110 is in the backlog for it.** Everything a player reads on a screen
is translated; what is left is what a player reads when the game says no.

### Hashes

Sim hash unchanged at `215410677` - words are not rules. Data hash
**`2601044827` -> `2842078959`**, deliberately, because the tutorial table now
holds keys.

`python tools/verify.py` prints PASS: 5959 asserts, 907 input cases, 0 failed,
and a new `strings` row reading 321 keys in 2 languages, all of them fit.
`exports` is still the one SKIP and still wants the Godot export templates.
## 0098 - Accessibility - done 2026-09-28

What changed: eight settings that decide whether somebody can play at all,
all of them on one tab, and four of them read by something for the first
time. Damage types wear a shape as well as a colour, holding a button builds
a fence, and the game will run slower without becoming a different game.

Files: `src/app/a11y.gd` (new), `src/ui/options_a11y.gd` (new),
`src/app/settings.gd`, `src/ui/ui_kit.gd`, `src/ui/sim_driver.gd`,
`src/ui/build_mode.gd`, `src/ui/juice.gd`, `src/ui/options_screen.gd`,
`project.godot`, `assets/locale/strings.csv`, `src/tools/shot.gd`,
`src/tools/headless_check.gd`, `src/tools/input_check.gd`.

Verify: 6018 headless / 918 input / both hashes unchanged.
Shots: `implementation/shots/0098/options_access.png`,
`wave.png` and `wave-contrast.png`.

### Most of it was already built and nothing turned it

Screen shake has been scaled by `a11y/screen_shake` since task 0055, the lamps
have checked `a11y/flashing` since 0076, the emitters have scaled themselves by
`a11y/particle_density` since 0077 and hit stop has read `a11y/hit_stop` since
0088. Every one of those was a setting a player could only reach by editing a
config file. **The tab is most of what this task is.**

What genuinely had nobody reading it: the picture scale, the contrast, and two
new keys - `a11y/hold_to_act` and `a11y/slow`.

### A slower game is the same game, and the hash says so

`a11y/slow` scales the **budget**, which is real seconds, and never the rate.
`SimDriver` hands `Sim.ticks_for` a smaller delta; the ticks that run are the
same ticks in the same order, there are just fewer of them a second.

The done-when is "the slow speed option does not change the determinism hash",
and it is measured rather than argued: two drivers on one seed, one at full
speed for 240 frames and one at half for 480. Same tick count, same
`State.hash_of`, and half the ticks in the same time. Reading the setting and
throwing it away fails all three, with the two hashes printed side by side.

### Three shapes, not three colours

The damage numbers were told apart by colour alone, which is a colour coding
that stops working for about one man in twelve. Each type carries a mark now -
`+` for impact, `^` for fire, `*` for explosive - in the game's own font,
drawn on the end of the number. **The colour stays**, for everybody who can
see it; the shape is what survives greyscale.

`A11y.distinct_marks()` is the done-when as a function rather than as a
promise, and giving two types the same mark fails it with the table printed.

### What a 480x270 game can honestly call a bigger UI

Not a bigger font. The HUD is laid out in whole pixels against a viewport
that is 480 across, and doubling the text would put half of it off the edge.
`content_scale_factor` scales everything instead - the world with the words -
so a player who needs it bigger gets it bigger and sees a little less farm.
That is the trade a pixel game has; the alternative is a second layout nobody
maintains.

### High contrast is the same palette, pushed apart

Not a second set of colours: `CONTRAST_ROLES` names the same nine roles from
`PaletteData`, picked so that **no role is darker than it was** - `Dim`
becomes the body colour and `Faint` becomes what `Dim` was. What it costs is
the hierarchy, which is exactly the trade somebody turning it on is asking to
make. A check compares the two tables role by role and fails on one that goes
the wrong way.

Measured on the shots rather than eyeballed: the dim HUD line goes from
(184, 174, 154) to (232, 224, 207) with it on. `shot.py --contrast` is new and
is how.

The frames stay as they are. They are drawings, and a second set of them would
be art nobody asked for; the win here is in the words.

### Holding builds a fence

A fence along one side of the farm is a dozen clicks, and a dozen clicks in
the same second is the thing some hands cannot do. Holding the place button
and dragging places one per cell and **never twice on the same one** - the
cell the last one went on is remembered until the button comes up.

`a11y/hold_to_act` ships on, because holding is the gentler of the two and a
player who prefers one press per tile still gets exactly that.

### The tab, and what is not a slider

Eight rows, and everything except the two switches is a small list of named
steps. A slider from nought to two asks a player how much screen shake they
want in decimals; **OFF, HALF and FULL** asks them a question they can answer.

Two lists have to agree and a check says so: every key `A11y` names is a
setting that exists, and every `a11y/` setting is a row on the tab. Taking one
off the tab fails it.

`TABS` is five now - GAME, ACCESS, VIDEO, AUDIO, CONTROLS - and the counted
constant moved with it, deliberately.

### Playable with shake and flashing off

As far as a harness can answer it: with both turned off the night is still
asked for, the farm still leaves the day, and the ticks keep coming. The
things that were turned off are view-layer only, so there was never a rule
that could depend on them - which is the reason that answer is worth as much
as it is.

### Hashes

Both unchanged - `215410677` and `2842078959`. The sim hash being unchanged
**is** one of the done-whens: the slow speed is a different number of ticks a
second and not a different tick.

`python tools/verify.py` prints PASS: 6018 asserts, 918 input cases, 0 failed.
`exports` is still the one SKIP and still wants the Godot export templates.
## 0099 - An icon and a boot ident - done 2026-09-28

What changed: the game has a mark. One sixteen by sixteen drawing, written
out at eight sizes, pointed at by `project.godot`, and shown for a second and
a half before the title. No engine branding anywhere.

Files: `tools/gen_icon.py` (new), `src/ui/boot_ident.gd` (new),
`assets/icon*.png` (new), `project.godot`, `scenes/Title.tscn`,
`tools/verify.py`, `src/tools/shot.gd`, `src/tools/headless_check.gd`,
`src/tools/input_check.gd`.

Verify: 6047 headless / 926 input / both hashes unchanged.
Shots: `implementation/shots/0099/ident.png`, `title.png`,
and `assets/icon_16.png` itself.

### Sixteen is the drawing, and everything else is it with bigger pixels

The done-when is "the 16x16 icon is still recognisable", and the only way to
be sure of that is for **sixteen to be the drawing** rather than the last
stop on the way down from 1024. Every other size - 32, 48, 64, 128, 256, 512,
1024 - is the same map scaled by a whole number, so nothing is resampled,
blurred or guessed at, and there is exactly one picture to change.

A check proves it rather than trusting it: every eighth pixel of the 128 is
the 16, pixel for pixel. Making the big one anything else fails it with
`256 differ`.

Two more, because a mark can pass "it exists" and still be useless: the
sixteen uses at least five colours, and no one of them is more than three
fifths of it. A flat square would pass everything else.

### Farm and night in one image

A moon over a house with a lit window, standing on ploughed rows. The moon
says night, the rows say farm, and the window says somebody is still in there.

**The first drawing was wrong and opening the file is what said so.** It had
a crescent and offset furrows; at sixteen pixels the crescent read as a
bracket and the furrows read as brickwork. A five pixel disc and plain
horizontal bands read as a moon and a field. That is the whole of what step 4
of the runner loop is for.

### The ident is the mark alone

A second and a half: a quarter fading up, most of it held, the rest fading
down. **Any input skips it** - a key, a mouse button, a pad button, not a
named action, because somebody who has seen it once presses whatever is under
their hand.

It had the wordmark under the mark to begin with and they overlapped. They
also said the same thing twice: the title behind it puts the name on the
screen a second later. The mark alone is a better signature and a shorter one.

### Once per launch, not once per scene

A static flag rather than a timer. The title scene is opened by more than a
player - `input_check` opens it a dozen times and `shot.py` opens it to
photograph it - and an ident in front of every one of those would be a slower
suite testing nothing. Both call `BootIdent.played()` at startup, which is
also what a player gets on their second visit within one launch.

`_case_0099_ident` is the one place that calls `forget()` and watches it
happen properly: it runs, a key gets past it, the title is untouched behind
it, and opening the title again does not play it again. Making it
unskippable fails three cases, one of them reading `MENU` where `TITLE` was
expected - the key fell through to the screen behind.

### No Godot logo anywhere

`boot_splash/show_image=false` with the game's own night colour behind it,
no `boot_splash/image` configured at all, and `config/icon` pointing at
`res://assets/icon.png`. Read out of `project.godot` by a check rather than
remembered, so the day somebody opens the project in the editor and it writes
a default back, a row goes red.

### The shot tool can photograph the front

`shot.py --title` takes two pictures of `Title.tscn` instead of the scenario
set: the ident caught **half way through its hold** - driven by hand in fixed
steps, so two runs catch the same frame - and the title behind it. The
capture itself came out of `_take` into `_shoot()` on the way, because a
second copy of "wait for a drawn frame, read the viewport, write the file"
would be a second place to get the headless caveat wrong.

### Hashes

Both unchanged - `215410677` and `2842078959`. A picture is not a rule.

`python tools/verify.py` prints PASS: 6047 asserts, 926 input cases, 0 failed,
and a new `icon` row reading eight sizes off one drawing.
`exports` is still the one SKIP and still wants the Godot export templates -
task 0100 is next and is the one that needs them.
## 0100 - Exports: Windows and Web - done 2026-09-28

What changed: `python tools/release.py` builds both, checks what went into
them, boots one of them and prints what the other weighs on the wire. The
title screen says which build it is. **`verify.py` has no SKIP left in it for
the first time in a hundred tasks** - the export templates are installed, so
the `exports` row runs.

Files: `tools/release.py` (new), `export_presets.cfg`, `scenes/Title.tscn`,
`src/ui/title_screen.gd`, `src/core/build_info.gd`,
`assets/locale/strings.csv`, `src/tools/headless_check.gd`,
`src/tools/input_check.gd`.

Verify: 6075 headless / 930 input / both hashes unchanged, 19 rows, 0 skipped.
Shot: `implementation/shots/0100/title.png`.

### The templates were the blocker, and they were asked about

They are a separate 1.28 GB download and nothing could be built without them.
Everything that did not need them was built first - the tool, the filters,
the checks, the version on the title - and then the question was put rather
than answered unilaterally: the owner said to fetch them. They are the
official 4.7.2-stable `.tpz` from the Godot release page, unpacked into
`%APPDATA%/Godot/export_templates/4.7.2.stable/`.

The `exports` row in `verify.py` now costs 13 seconds and the whole suite
comes in at 284 of its 300 second budget, so it stays in the gate rather than
moving to the release tool.

### The pack is where this goes wrong, and it went wrong

The task says so and it was right, twice over.

**Once in the config**, which is the cheap half: `release.py --check` reads
every preset and fails when one of them stops excluding a folder. Taking
`implementation/*` off the Windows preset - and leaving it on the Web one -
is caught by name.

**Once in the pack itself**, which is the half that cannot be fooled: the
names are read back out of the `.pck` directory after the export. 716 files,
171 of them rules, no `src/tools/`, no `.py`, no `.md`.

And the first version of that reader **was wrong and passed anyway.** Godot
moved the pack directory to the end of the file in 4.4; reading it from after
the header gave a count of nought, and a pack with no files in it passes
every check about what is *not* in it. It printed "nothing of the repository
in it" over an empty read. `pack_is_clean` refuses an empty pack now, which
is the general lesson: a check that can pass by finding nothing has to say so.

### The budget was measured, not picked

The first `WIRE_BUDGET` here was eight megabytes, chosen because ten seconds
of a typical connection is about that. The first build came out at **12.01 MB
gzipped**, and 9.61 of those twelve are `index.wasm` - the Godot engine, not
this game. A stock 4.7 web export cannot be smaller without building the
engine from source with modules stripped.

So there are two budgets and the comments say which is which:

- `WIRE_BUDGET` is 13 MB: the engine floor plus room to grow. It catches a
  disaster and not much else.
- `PACK_BUDGET` is 3.5 MB on `index.pck` gzipped - **the half this repository
  owns**, currently 2.31 MB. That is the one with teeth, and the one that
  bites the day somebody checks in a forty megabyte WAV.

Both are printed every build, over and under.

### Two builds, one game

The done-when is "the two builds produce the same determinism hash", and the
honest way to answer it is not to run one of them: a Web build cannot be
driven from a command line at all, so running the Windows one would prove a
thing about the Windows one.

What is checkable, exactly, is that both packs carry the same rules and the
same tables - and the pack format stores an MD5 per file, so it is a
comparison rather than an argument. 716 files each, every one identical,
including all 171 under `src/`. Same rules and same data on the same engine
version is the same hash.

The Windows build is also **booted** before it is called a build: 400 frames
of the real exported binary with no window, loading the pack, running every
autoload and building the title scene, exiting zero with nothing on stderr.
Not a full night - the autoplayer is excluded from the pack on purpose - but
the difference between "the file was written" and "the file runs".

### The click, the mark, and the date

`html/focus_canvas_on_start` was already on; what is new is a `head_include`
that focuses the canvas again on the first `pointerdown`, because a web build
that is running and cannot hear the keyboard is the commonest way one looks
broken. Audio on a first gesture is Godot's own web driver and was not
changed - said plainly because it was not tested in a browser here.

Task 0099's mark goes on the window and on the browser tab, at 256 and 512.

`release.py` stamps the build date into `BuildInfo.BUILT` on the way out, and
the title screen shows `v0.1.0 prototype - built 2026-09-28` in the corner -
on the title rather than in the debug overlay, because the person who needs
it is a stranger sending a screenshot of something going wrong.

**It was there and unreadable at first.** `Faint` is the colour for a thing
you cannot have, not for a thing you have to squint at, and the label was
narrower than its own line so the text overhung its own left edge. Wider, and
`Dim`, and the string table now has a width on the key so the checker guards
it in both languages.

### Hashes

Both unchanged - `215410677` and `2842078959`. A build is not a rule.

`python tools/verify.py` prints PASS: 6075 asserts, 930 input cases, 0 failed,
**19 rows and no SKIP**.
## 0101 - Onboarding in seven lines - done 2026-09-28

What changed: day one has seven lines instead of five. The two new ones are
the stall and the water, which are the two things a stranger would otherwise
never find, and they go where a first day actually happens rather than at the
end of the list.

Files: `src/core/game_data.gd`, `src/core/tutorial.gd`,
`assets/locale/strings.csv`, `src/tools/headless_check.gd`,
`implementation/prompts/0105-playtest-build.md`.

Verify: 6083 headless / 930 input.
**Sim hash 215410677 -> 4262811284** and
**data hash 2842078959 -> 407837701**, both deliberately - below.
Shot: `implementation/shots/0101/noon.png`.

### The seven, in the order a day happens in

    chop  →  plant  →  water  →  sell  →  craft  →  build  →  night

Task 0041 had five and they were in a sensible order already. The two new ones
are placed where they are *about the thing that just happened*: watering is
about the seed put in one second ago, and the stall is about the wood in your
hands. Putting them at the end would have made them a list rather than a day.

### What ordinary play clears on its own, which is the only thing here I could measure

An hour of ordinary play - chop a tree, till and sow a plot, walk past the
water, queue a kit - clears **four of the seven** without reading a word:
chop, plant, water, craft.

**Three are left to be read: the stall, putting a defence down, and sending
for the night.** Those three are what the lines are actually for. It is
printed by the suite every run, so the day it changes somebody will see it.

That is a measurement of the game, not of a person, and it is not what the
task asked for. See the last section.

### Two nearly-right versions of "they found the stall"

The `sell` step is finished by having **more money than you started with**,
and getting there took two wrong answers:

- *"The stall is open"* cannot be seen at all. The shop stops the clock (task
  0039), so no tick happens while it is up, and `Tutorial.tick` never sees it.
- *"The money changed"* is true the moment the player sows their first seed,
  because a seed costs money. The measurement above is what caught it: an hour
  of ordinary play cleared the stall line with nobody going anywhere near the
  stall.

On day one, money going **up** can only have come out of the stall.

### The switch is shown, not described

Nothing in the seven says what the night does to the farm. The transition
already shows it - two seconds of the same tiles going dark - and a line that
said "your farm becomes the map you defend" would spend a stranger's attention
on something the game is about to do to them anyway.

There is a check for it now: no line may contain *defend*, *battlefield*,
*zombie*, *horde*, *fortress* or *wave*. Putting that sentence on the night
line fails it by name.

### The shot found the water line pointing off the screen

It pointed at the well, the well was off the bottom of the screen, and the
bubble clamped to the edge with its arrow into the dark. The can fills at any
water - the pond edge included, with no keypress - so it points at whichever
is nearest and the words say water rather than naming the well. The bubble now
sits on the pond four tiles from the farmer.

Found by opening the picture, which is what step 4 is for.

### The tutorial is on the "things that watch the player" list

Task 0038's check says the farm does not care where the farmer stands, and it
broke: a day at the pond now clears the watering line and a day at the bench
does not, because the can fills by standing next to water. That is the
tutorial doing its job, not the farm caring - so `tutorial` joins `player`,
`intent`, `water_can` and `fishing` on the list of things that are *supposed*
to depend on where somebody stood. Nothing that produces anything is on it.

### Hashes, both of them

**Data `2842078959 -> 407837701`**: `GameData.TUTORIAL` has two more rows.

**Sim `215410677 -> 4262811284`**: the tutorial's `done` list is game state,
and it now records two more things, at particular ticks, during the scenario
the guard runs. Checked rather than assumed: `_happened` for both new steps
only reads, `_target_for` only reads, and `tick` only appends - so the two ids
are the whole of the change.

### What this task could not do, and where it went

Two of the done-whens are **"a first-time player reaches the end of night 1
without being told anything out loud"** and **"the journal names where they
hesitated, because that is the finding"**. Neither is something I can do: it
needs a person at a keyboard who has not seen this game, and somebody watching
them.

Everything else is built and checked. The observation is carried into **task
0105**, whose prompt is edited to say so - it is the task about putting a
build in front of somebody, which is exactly when the watching happens, and it
now names the three lines to watch: the stall, putting a defence down, and
sending for the night.

Said plainly rather than ticked: **this task's finding is still owed.**

`python tools/verify.py` prints PASS: 6083 asserts, 930 input cases, 0 failed,
19 rows, no skips.

## 0102 - A performance budget - done 2026-09-28

A number instead of a feeling. `src/tools/perf_check.gd` plays the worst case
the game has and prints one machine-readable line per measurement;
`tools/perf.py` compares them against `tools/perf_baseline.txt` and against a
budget, and `verify.py` runs it as its own row - 5.2 seconds, which is cheap
for the thing it answers.

### A budget and a baseline are two different questions

The **budget** is the ceiling: a tick is 33,333us at 30Hz and the game may
have a quarter of it. The other three quarters are the drawing, the operating
system and whatever else the player has open. It is a property of the design
and it does not move.

The **baseline** is what this game costs today, and it moves the way the
determinism hash does - `python tools/perf.py --accept` prints the old and the
new number so this journal can record both. A change that doubles the cost of
a night is still inside the budget and still something somebody should have
decided rather than discovered.

### The numbers, on this machine

The worst case is night ten with 40 towers, 48 crops planted, 13 walls and the
field as full of walkers as it gets, stopped at the busiest tick rather than a
fixed one.

    night_tick      1044us     13% of the 8333 it may have
    day_tick          97us
    night_towers     505us     the most expensive thing in a night
    night_enemies    210us
    night_traps       79us
    day_farming       26us     the most expensive thing in a day
    path_refresh    8390us     not per tick - per wall a player puts down
    view_particles   461us     per frame, and thinking only
    view_lighting      0us

**The game has ten times the room it needs.** The one number worth watching is
`path_refresh`: a whole tick's work, and a player in build mode drags fences.
It is inside its budget because it only runs when the walls change, which is
the entire reason `flow_version` exists - and which is why measuring it needed
`grid_version` bumped, or the benchmark timed the early return at 1us.

### Four measurement bugs, all found by reading the numbers

**217 towers.** Filling the east half killed night ten before it walked ten
tiles. A worst case with nothing left alive in it is not a worst case. Capped
at 40, which is more than anybody builds.

**Night one dressed as night ten.** Setting `state["day"]` alone gives night
one - `Phases.begin_night` counts `nights_won`. Forty towers against the first
wave is the easiest night in the game.

**A system ticked alone goes where the game never goes.** Six hundred calls of
`Waves.tick` with nothing else running ends the night and then keeps ending
it, which is an error log rather than a measurement. The state is re-copied
every 30 calls, and `state["tick"]` is advanced by hand so that systems which
self-throttle - `Tutorial` runs one tick in fifteen - are measured truthfully
rather than always or never.

**575,555us a frame for the particles**, which is half a second. What was
being timed was Godot printing an error: `Particles` sizes its pools in
`_ready`, a node added to `root` during `_initialize()` never gets one, and
every burst wrote past the end of a zero-length `PackedFloat32Array`. Calling
`_ready()` by hand makes it 461us. **This one was a real bug in the view**,
not only in the benchmark - `Lighting` and `Particles` both reached for
`get_node_or_null("/root/Settings")`, which errors from outside the active
tree. Both now ask `Engine.get_main_loop()`, the way `Audio`, `Video`,
`Actions` and the rest already did.

### The tolerance is measured, not chosen

Forty per cent. Three runs of the same build moved `night_enemies` 212 -> 214
-> 246, which is sixteen per cent of noise on an idle machine. Forty is about
two and a half times that. A threshold tighter than the noise is a check
people learn to re-run until it passes, which is worse than no check.

Tested both ways, which is the done-when: a 4,000-iteration loop in
`Towers.tick` moved it +17% and was correctly ignored; 40,000 moved it +182%
and failed, and the verify row read

    perf   FAIL  night_towers went from 505us to 1409 (and 1 more)

**The failing line names the system**, which took a change: the list is sorted
by how much each row grew with the whole-tick numbers put last, because
`night_tick` goes up whenever anything under it does and naming it first names
the symptom. The point of timing systems separately is that the failure says
which one.

### The list of systems has one home

`PerfNames` (`src/tools/perf_names.gd`) holds the night and day lists, because
`headless_check.gd` now checks them against what `Sim.tick()` actually calls -
both ways, so a system added to the sim and not to the benchmark fails, and so
does a name in the list the sim stopped calling. All fourteen are covered. The
group also checks the budget against `GameData.TICK_HZ`: change the tick rate
to 60 and the budget is silently twice what a frame has.

The budget lives in `tools/perf.py` and **not** in `game_data.gd`, deliberately
- it is a fact about the machine, not a lever a designer turns, and it sits
with `BUDGET_S` in verify and `WIRE_BUDGET` in release. The cost of that
choice is that two numbers can drift apart, which is exactly what the assert
above is for.

### Hashes

Both unchanged: **sim `4262811284`**, **data `407837701`**. Nothing in
`src/core/` was touched; the two view files changed only how they ask for a
service.

### One thing to watch

`verify.py` now runs 297s against its `BUDGET_S = 300`, which prints
"(OVER BUDGET)" and does not fail. `script parse` (91s), `headless_check`
(91s) and `input_check` (71s) are the whole of it - `perf` is 5s. Left alone
on purpose: raising the number to meet the measurement is the opposite of what
this task is about. The next task that adds a row will push it over, and that
is the right moment to decide whether the suite gets a fast mode by default.

`python tools/verify.py` prints PASS: 6110 asserts, 930 input cases, 0 failed,
20 rows, no skips.

## 0103 - Crash and error reporting - done 2026-09-28

When it breaks on somebody else's machine, get enough to fix it without them.
`src/app/crash.gd` writes a folder under `user://crash/` holding a readable
report and the whole run as the game had it; `src/ui/crash_dialog.gd` is what
says so, on the title screen, in the player's language.

### GDScript has no exceptions, so there are three mechanisms and not one

There is no `try`. A script error prints and the frame carries on with a null
where a number should be; a real crash takes the process before any GDScript
runs. So:

1. **A reported error.** Something notices an impossible state and calls
   `Crash.report(state, reason)`. Full fidelity - the exact state at the exact
   tick. This is the one that catches the failures this game will actually
   have, because the rules are the part with the bugs in and the rules cannot
   throw.
2. **A breadcrumb.** `Crash.mark()` writes the same folder under a fixed name
   every ten seconds while a run is going, and both ways out - `_exit_tree`
   and `NOTIFICATION_WM_CLOSE_REQUEST` on `App`, and SAVE AND QUIT and
   ABANDON in `Main` - delete it. A folder still there at the next boot means
   the last session did not leave through the door. The recorded tick is up to
   ten seconds stale, which is the price of not writing to disk every frame;
   the run save is fifteen kilobytes and this is a real write.
3. **`NOTIFICATION_CRASH`**, which the engine sends from its own crash handler
   on desktop. The best account available when it fires, and the least
   reliable to count on - which is why 2 exists.

`Crash` keeps one static reference to the live run, set in `Main._hand_out()`.
That is the function that exists because `SimDriver.start()` *replaces* the
dictionary rather than emptying it, and a screen holding the old one draws a
game that has stopped advancing. A crash handler holding the old one is the
same bug one layer down, so it is set in the same place as the rest.

### The dialogue is at the next boot, and that is the honest version

The requirement says "a dialogue offering the file's location rather than
vanishing". A dead process cannot draw a dialogue - that is what dying is. So
the promise is kept one launch later: the title screen sweeps the breadcrumb
into a report and puts the dialogue up once the boot ident has finished
playing. A player who watched the window disappear gets told; a player whose
machine did it while they were away finds out at all.

It is announced **once**. `mark_seen` is written the moment it goes up rather
than when it is closed, because a player who alt-F4s out of the dialogue has
still been told, and a game that opens on the same crash every launch teaches
people to close it without reading.

### What is in it, said in the file and said again on screen

The report is English on purpose: the dialogue tells the player what is in it
in their own language, and the file is for whoever reads it in order to fix
the game. Both say the same three things - what is in it, what is not, and
that nothing was sent.

    THE RUN
      seed    103999
      tick    3600
      phase   NIGHT
      day     1, nights won 0

    THE LOG
      tick 3000    night_began      night=1
      tick 3001    wave_began       count=3 enemy=walker wave=1 waves=3
      tick 3494    wave_began       count=4 enemy=walker wave=2 waves=3
      tick 3502    house_hit        damage=10 left=90

**`Events` is the log**, which is why task 0090 put it in the state: the view
samples at whatever rate the machine manages and cannot say what happened in
what order. Here it is printed as kinds and ticks rather than as sentences,
because the person reading this is fixing the game and not playing it.

### No personal data, and the strong version of that is a grep

Two halves. The first: the one way a name gets into a file this game writes is
an absolute path in the engine's log, and every one of those has an account
name in it. `Crash.scrub()` takes the user data directory, the project
directory, `USERPROFILE`, `HOME`, `USERNAME` and `USER` out, longest first so
a home folder goes whole rather than leaving `<user>/AppData/...` behind.
Values under three characters are left alone: an account called `al` would
turn every `al` in the file into `<user>` to protect two letters that are not
a name.

The second: **there is nowhere for a name to get in.** `headless_check` now
asserts there is no `LineEdit`, `TextEdit` or `CodeEdit` anywhere in
`src/core/`, `src/app/` or `src/ui/`. The game never asks anybody to type, so
the run is numbers.

And "it never sends anything anywhere by itself" is asserted the same way:
nothing under `src/` mentions `HTTPRequest`, `HTTPClient`, `WebSocketPeer`,
`StreamPeerTCP`, `PacketPeer`, `UDPServer`, `TCPServer`, `OS.execute`,
`OS.create_process` or `MultiplayerAPI`. A promise in a comment is worth what
the next person remembers.

**The path on screen is not scrubbed**, deliberately. The requirement is about
the report. A scrubbed path is a path nobody can navigate to, and the person
reading the dialogue is the person whose machine it is.

### The run save is never touched

Everything writes inside `user://crash/`. The check saves a run, crashes on
purpose, and loads it back to the same hash - and then says it the other way
round as well, because that assert would also pass if the crash had rewritten
the save with identical bytes: nothing in `crash.gd`'s **code** mentions
`Save.`. The first version of that read the whole file and failed on
`crash.gd`'s own doc comment, which says in as many words that it never
touches `Save.RUN_PATH`. A check that cannot tell a promise from the thing it
promises about teaches people to stop writing the promise down.

### Three things found by looking rather than by running

**The dialogue was two thirds empty.** The frame was 172 tall against content
that stopped at 110. Measured off the picture and set to 132.

**`seed 82082082 tick 5400` was in `Faint`**, which is the colour of something
a player cannot have, and which task 0099 already found unreadable on the
version label. It is the one line a player is asked to compare against the
file. Now `Warm`.

**PRESS ANY KEY was still on the screen** under a dialogue that had taken the
keyboard, which is a game a player reasonably concludes has frozen. The ident
line now hides while the dialogue is up and comes back when it closes.

### And one the pictures found that was nothing to do with this task

`python tools/shot.py <id> --title --pt_BR` has been writing **English
pictures under Portuguese names**. `--title` takes its two pictures before the
language is applied, and the one place that did apply it read the locale out
of `_tongue`, which is a *filename* - so `--pt_BR --contrast` asked `I18n` for
a language called `pt_BR-contrast`, which falls back to English without
complaining. There is now a `_speaking` that is a locale and a `_say_it_in()`
that both paths call. The title screen says APERTE QUALQUER TECLA in
`title-pt_BR.png` for the first time.

Found by taking the picture and opening it, which is the entire argument for
step 4.

### The input case failed against code that was right

"A key does not get past the dialogue" failed, reporting MENU. A print in
`_unhandled_input` showed **two title screens**: the harness's own, with the
dialogue up and guarded, and a second one left under the root by an earlier
case that sent the game to the title through `App.goto` - which really does
change the scene, as task 0096 found out. The second title had no crash to
announce, so it was the one that took the key. The case now clears
`current_scene` before it opens anything. Worth knowing for every later case
that cares which screen is listening.

### Pictures

`implementation/shots/0103/crash.png` and `crash-pt_BR.png`. `shot.gd`'s
`--title` path now takes a third picture: it writes a report, opens the title,
photographs the dialogue and erases the report again, because a picture is not
a reason to leave a crash report on somebody's disk.

### Hashes

Both unchanged: **sim `4262811284`**, **data `407837701`**. Nothing in
`src/core/` was touched.

### Two notes for whoever is next

`project.godot` gained a `[debug]` section turning file logging **on**. Godot
writes a log by default in a debug build and not in a release one, which is
exactly backwards for a report whose whole purpose is a machine that is not
this one. Five rotated files at `user://logs/harvest.log`.

`python tools/verify.py` now takes **303 seconds against its own
`BUDGET_S = 300`** and prints `(OVER BUDGET)`, which is a note and not a
failure. `script parse` (94s), `headless_check` (92s) and `input_check` (72s)
are the whole of it, and the parse row is the one that is overhead rather than
work: it launches Godot once per script, ninety-seven times. Not fixed here,
because raising a budget to meet a measurement is the opposite of having one -
carried into **task 0106**, the release checklist, whose prompt now names the
three rows and says which answer is wrong.

`python tools/verify.py` prints PASS: 6153 asserts, 945 input cases, 0 failed,
20 rows, no skips.

## 0104 - Saves survive an update - done 2026-09-28

Adding a lever or a tech node must not delete somebody's run. `State.reconcile()`
brings an old save up to this build's shape, `Save.step_up()` runs the numbered
migrations in order for the changes filling in cannot express, and three golden
saves in `tools/goldens/` are loaded and **played** by every run of the suite.

### Two version numbers, because there are two questions

`Save.FORMAT_VERSION` is about the file - the magic, the header, the encoding.
`State.VERSION` is about what is inside it. **Most changes bump neither.** A
new subsystem, a new resource, a new field on an existing structure: those are
a new game having a key an old save does not, and that is what `reconcile()`
is for. What bumps `State.VERSION` is a change no amount of filling in can
express - a key that means something different than it used to, a number that
changed units - and then there is a migration under it.

### The reconcile is two levels deep, and which is which is written down

The top level, and one level inside each of `State.TABLES`. Below that is the
run itself and none of it is anybody's to fill in.

**`occupants` is why the lists are written down rather than worked out.** The
first rule I reached for was "a nested dictionary that a new game starts empty
holds the player's own facts; a non-empty one is a table with a known key
set". It is wrong, and expensively: a new game starts with a hundred and six
occupants - the house, the trees, the workshop - so that rule would have
dropped every building in every save as an unknown key. What separates the two
is not how full it is, it is **who put the keys there**.

So there are two lists, `TABLES` and `RUN_DATA`, and `headless_check` asserts
that every nested dictionary in a state is in exactly one of them. A subsystem
that adds one and does not say which it is fails a row rather than quietly
getting its farm rebuilt. The planted version of that bug is worth quoting -
with `occupants` moved into `TABLES`, the check said:

    FAIL  what the player built is still standing
    FAIL  run-v1.sav is a farm somebody built on  106

A hundred and six. The golden was reset to the starting farm.

### A missing key takes the default, which is a new game's value and not nought

A player whose save predates oil gets the **starting amount** of it, because
that is what the game gives somebody who starts today; what they have
*earned* of it is nought, because none of it was. Both are asserted.

### The state was not as knowable as everything here assumes

The round-trip asserts from three earlier tasks broke the moment the reconcile
went in, and the reason is worth writing down: **`Livestock` was inventing two
top-level keys at runtime.** `_animals()` caches the animal cells against
`grid_version` and created `livestock_version` and `livestock_cells` the first
time it ran, so a played state had two keys a new game did not - and a
reconcile that mends an old save by comparing it against a new game dropped
them both.

Caching against a version is right. Doing it in a key nobody declared is not:
the save, the determinism hash and the state diff all rest on
`State.create()` describing every key a valid state can hold. Both are now in
`Livestock.initial()` at `-1` and `[]`, which is the sentinel `_animals()`
already used, so it finds a mismatch on the first call and rebuilds exactly as
before.

The rule that keeps it true is a new assert: **play a day and a night and the
key set does not change.** Not one key invented, not one lost.

### The sim hash moved, and here is the proof it is only the shape

**Sim `4262811284` -> `1961000123`.** Data unchanged at `407837701`.

The guard is a *rolling* hash - it folds the state every few hundred ticks
through the whole scenario - so two keys that now exist from tick 0 instead of
appearing part way through change the early samples. The question is whether
anything else did, and it was measured rather than argued:

    with the keys declared        WHOLE 909080062  TICK 6500  WOOD 9  HOUSE 0
    with them invented at runtime WHOLE 909080062  TICK 6500  WOOD 9  HOUSE 0

Same scenario, same length, run with and without the change: the final state
is identical to the last bit. The destination is the same and only the early
part of the journey differs, in which keys exist and not in what anything is
worth.

### The migration driver is proven before anything depends on it

`Save.migrations()` is **empty**, and that is the honest answer: the state has
been version 1 for the whole of this project. The driver under it is not, and
`headless_check` drives `step_up()` with a table of its own - three steps that
record that they ran - and checks that they run in order, that each is handed
what the last one gave it, that a save already current runs none of them, that
a **gap refuses the whole thing** rather than guessing past it, and that a
step returning nothing is a refusal and not a crash.

The moment there is a first real migration is the worst possible moment to
find out the machinery that runs them never ran.

### Three golden saves, and the first one was a lawn

`tools/goldens/run-v1.sav` is a real save written by the real writer.
`run-v1-older.sav` is the same run with `events`, `tutorial`, the oil rows and
`ability.flares` taken out - a build that predates all four. `run-v1-newer.sav`
has two keys this build has never heard of. Between them they cover every
shape of change there is: a new top-level key, a new row in a table keyed by
`GameData`, and a new field on a structure.

`src/tools/make_goldens.gd` writes them and **refuses to overwrite one**,
because a golden is only worth anything if nobody regenerated it. When
`State.VERSION` moves to 2, somebody runs it once on the last build that still
said 1, checks in the file, and never touches it again.

**The first version of it made a lawn.** It advanced a fresh state 5400 ticks
and saved the result: day one, nothing built, a hundred and six occupants -
which is the starting farm, and a golden of a new game passes every check
while proving nothing. The one in the repository is sown, built on and one
night older: day 2, night 1 won, 115 things standing, 14 crops in the ground.
The check asserts that last part, which is how the `occupants` plant above got
caught three times over.

And the fixtures are checked for being what they claim: the older golden is
decoded **underneath** `read_run_at`, which would have mended it on the way
past, and really is missing what it says it predates.

### A save that cannot be read says so, keeps the file, and offers a new run

Every refusal now has a name - `SAVE_TOO_SHORT`, `SAVE_NOT_OURS`,
`SAVE_TRUNCATED`, `SAVE_DAMAGED`, `SAVE_FROM_THE_FUTURE`,
`SAVE_NO_MIGRATION`, `SAVE_NOT_A_SAVE` - and the title screen says which, in
the player's language, on a panel above the menu.

CONTINUE now comes off `Save.can_continue()` rather than `Save.has_run()`. A
file existing is not a run: a CONTINUE that throws away the save it offered to
resume is worse than no CONTINUE, and the rule at the top of `title_screen.gd`
is already that an entry with nowhere to go is absent rather than greyed.

**The file is never removed.** Not on a bad checksum, not on a version from
the future, not on a failed migration. A save this build cannot read is one a
later build may well read, and the player is told it is still there before
they press NEW RUN.

### Pictures

`implementation/shots/0104/save_trouble.png` and `-pt_BR`. Two things came out
of opening them:

**The notice was orange text on a farm.** No panel - so it ran over the trees,
the roof and the field, and the third line fell off the bottom of its label.
It is a `PanelContainer` now, like everything else in this game that expects
to be read.

**It said NEW GAME and the button says NEW RUN.** A player told to press
something that is not on the screen is a player who thinks the game is
broken. Both languages fixed.

### One fragility a planted bug found

Taking `can_continue()` back out to check the case could fail did more than
fail it: the notice went **blank**. `Save.trouble()` is about the *last read*,
and the only reason the title had anything to say was that `can_continue()`
happened to have read the file two lines earlier. The answer is now caught
into `_why` at the moment of the read rather than asked for later by a
function that assumes somebody else went first.

### Still over budget

`python tools/verify.py` is **307 seconds against its own 300**, up from 303.
Unchanged in cause - `script parse`, `headless_check` and `input_check` are
253s of it - and unchanged in owner: task 0106's prompt carries it.

`python tools/verify.py` prints PASS: 6221 asserts, 960 input cases, 0 failed,
20 rows, no skips.

## 0105 - A playtest build - done 2026-09-28

A build to put in front of somebody, and the instrumentation to learn
something from it. `python tools/release.py --playtest` makes it,
`src/app/playtest.gd` records the session, `docs/PLAYTEST.md` goes in the
folder beside the exe, and `python tools/playtest.py` reads a folder of logs
back.

### The finding this task was supposed to make is still owed

**Say it plainly, at the top, rather than at the bottom where it can be
missed.** The first done-when is:

> The journal names where the first-time player hesitated on day one,
> because that is the finding task 0101 could not make

I cannot make it. It needs a person at a keyboard who has not seen this game
and somebody watching them, and no amount of code is that. It was carried
from 0101 into this task on the grounds that this is the task about putting a
build in front of somebody - and it is, but the putting is still a thing a
person does.

What has changed is that **it is no longer blocked on anything but doing it**.
Before today there was no build to hand over, no record of what happened and
nothing to read it with. Now:

    python tools/release.py --playtest       # build/playtest/, with the note
    ... somebody plays it ...
    python tools/playtest.py <their folder>  # the four questions

The three lines from 0101 to watch are the stall, putting a defence down, and
sending for the night. **This task does not carry the observation forward
again.** Deferring it a third time would be a way of never doing it; the
thing to hand over exists, and it is the owner's hour.

### The flag is a feature tag, and the playtest build is the same build

`[preset.2]` in `export_presets.cfg` is `[preset.0]` - the Windows build -
with `custom_features="playtest"` and a different output folder. It is
generated by copying the shipping preset and changing three lines, so it is
provably the same build with a flag on it rather than a second configuration
that drifts.

`release.py` builds everything **except** it by default, and only it with
`--playtest`. That is not a convenience: this build writes a file about
whoever is holding it, which is fine for somebody who agreed to test and is
not fine for a stranger. `headless_check` counts the presets, so a fourth
arriving is a failing row rather than a build nobody meant to ship.

### It records what the rules already knew

Three of the four things the task asks for were already in the state. `Events`
has recorded what happened since task 0090 and `stats.built_by_kind` counts
what went down, so the session log is mostly a matter of putting a wall clock
beside facts the rules already keep. **`src/core/` was not touched**, which is
why a task that adds a whole build flavour moves neither hash.

    0:00  the run began
    0:00  day 1 began
    2:14  NOTE 1 - the tester marked this moment
    3:02    they sent for the night
    3:20  night 1 began
    3:40    wave 1 of 3 - 3 walker
    4:55  night 1 won
    5:01  day 2 began

### The note key leaves a number, not a sentence

There is no text box in this game and there is not going to be one: task
0103's privacy check asserts there is no `LineEdit` anywhere in `src/`,
because that is what makes "your name is not in the report" true by
construction rather than by promise. So **F1 writes a numbered marker** and
the tester says what note 3 was about afterwards. One key press in the middle
of a fight is also far likelier to happen than a typed sentence.

It is not in `InputActions.ACTIONS` either. Everything in that table appears
on the controls screen, and an entry that does nothing in the build a player
has is exactly the greyed-out button this project keeps refusing to draw.

### Looking at the pictures moved the badge twice

**It covered the clock.** The first version sat in the top-left corner for the
whole run. The noon shot came back with the day, the time and the money behind
it; the wave shot with NIGHT 1 and WAVE 2/3 behind it. Covering the two most
important readouts in the game for an hour, to tell somebody a key they needed
once, is a bad trade.

It is up for twelve seconds at the top of each run now, and again for two
whenever a note is left. That is when a tester has nothing to read on the HUD
yet and everything to learn. The permanent watermark moved to the title
screen, which is the screen they will be looking at when they wonder which
build they have. `implementation/shots/0105/noon.png` is what the first
seconds look like; that it then goes away is an assert rather than a picture,
because a picture cannot show twelve seconds passing.

**And the watermark ran off the edge.** `PLAYTEST BUILD - v0.1.0 prototype -
built 2026-09-28` on the title's version line came out as `built 2026`, clipped
at the right. The label is 240 wide and `TITLE_BUILD` already used most of it.
Two lines now, and an assert that both are on the screen.

### An old determinism check had been passing on luck

Adding the badge to the run scene broke `a night played with the particles off
comes out identical` - task 0077's, twenty-eight tasks old. It was not the
badge.

The case plays the same night twice and compares the state hash, advancing the
sim by hand and awaiting frames in between so the view gets a chance to touch
something. Its own comment says it "measures the rules and not the frame
rate". **It did not.** `SimDriver` is a live node and was left running, so
each awaited frame advanced the state by however many ticks the wall clock
said had gone by - on top of the hand-driven ones. The two runs got a
different number of timed ticks each, and the case passed when they happened
to match. Adding one node to the scene moved the frame time enough to stop
them matching.

`driver.running = false` in both helpers. A determinism check that can fail on
frame timing is worse than no determinism check, and it had been one for
twenty-eight tasks.

### Two things found by reading the tool's own output

`ended  a new run began` - the summary described the *cause* of a session
ending from the next session's point of view, which reads as though the run
ended by starting. It says `the tester started another run` now.

And every row in the session column began with the same eight characters
while the end was truncated mid-extension. The stamp is enough.

### Hashes

Both unchanged: **sim `1961000123`**, **data `407837701`**. Nothing in
`src/core/` was touched.

### Still over budget

`python tools/verify.py` is **322 seconds against its own 300**, up from 307:
one new row (`playtest`, 0.1s) and the rest is more asserts and one more input
case. Unchanged in owner - task 0106's prompt carries it, and it is the next
task.

`python tools/verify.py` prints PASS: 6261 asserts, 978 input cases, 0 failed,
21 rows, no skips.

## 0106 - The release checklist - done 2026-09-28

`implementation/RELEASE.md` is the list, `CHANGELOG.md` is what it writes
into, and the done-when said running it once would find something. It found
three things, one of them a bug a player could have paid six tech points for.

### The suite's own clock: it got faster, and the number did not move

Carried from task 0103 and named in this prompt: `verify.py` was **322
seconds against its own `BUDGET_S = 300`**, and the prompt was explicit that
raising the budget to meet the measurement without saying so is the wrong
answer.

It is 226 now, and the budget is still 300.

`script parse` was ninety-five of those seconds and almost none of it was
compiling anything: it ran `--check-only --script` once per file, which is a
whole Godot process per script, ninety-eight times. `src/tools/parse_check.gd`
does the same work in one process by loading every `.gd` through
`ResourceLoader`, in **6.8 seconds**.

Two things had to be found out by trying rather than by reading:

- **A failed parse comes back as a `GDScript` with nothing in it**, not as
  `null`. A script that compiled knows what it extends; one that did not
  knows nothing and cannot be instantiated. That predicate was checked
  against all hundred scripts before it was trusted - every real one passes,
  including the `class_name`-and-static-functions files nobody instantiates.
- **`CACHE_MODE_IGNORE` takes the engine down.** It re-runs a script's static
  initialisers on every load, and doing that to a hundred scripts inside one
  process ended in an internal error and a C++ backtrace. The default cache
  is right anyway: a fresh process starts empty, so each script is parsed
  once, and a dependency that will not parse fails whatever needed it.

Proven against three planted errors - a syntax error, a bad declaration and a
type error - and the row names the file. It names the files that depend on it
too, with a line saying so, because the list is always longer than the
mistake.

### What the first run found: two tech nodes that did nothing

**This is the one that matters.** While writing the known-issues section I
went to check a sentence I had written into `docs/PLAYTEST.md` at task 0105 -
"the tech tree past the first two rows, some of it is not wired up" - which
I had guessed at. An honest known-issues list cannot contain guesses, so I
checked it: every `gives` key in `TECH_TREE`, against everything in `src/`
that reads it.

    nodes: 12, effect keys: 12, distinct: 12
    effects nothing outside game_data reads: ['craft_percent', 'sell_percent']

**"Steady hands"** costs four points and says *the workshop, press and
kitchen work a third faster*. **"A name at market"** costs six - the most
expensive node in the production branch - and says *everything you sell
fetches a quarter more*. Both were in the tree with a sentence about what
they do, and nothing anywhere read either of them. A player could spend ten
points on two placebos.

Both are wired now: the craft tech comes off the recipe before the brownout
is applied to what is left, and `Shop.paid_for()` is one function so that
selling one and selling all cannot disagree. **Neither hash moved** - with no
tech owned the multiplier is exactly 100/100, which is the arithmetic the
determinism guard does.

And the general rule is a check, so it cannot happen to a thirteenth node:
**every key in every node's `gives` is read by something in `src/core/`**, and
every node has a sentence saying what it does. Planted the placebos back to
watch it fail:

    FAIL  every tech node's effect is read by something
          ["steady hands gives craft_percent, which nothing reads",
           "a name at market gives sell_percent, which nothing reads"]
    FAIL  steady hands actually makes the workshop faster  179 ticks against 179
    FAIL  a name at market actually pays more  80 against 80

The two "actually" asserts are there because a rule about what the source
mentions is not a rule about what the game does. One of them would pass if
the effect were read and then multiplied by one.

### And two things in `release.py` itself

Both from running step 7, which is the playtest build.

**The boot check only ever looked at `build/windows`.** So `--playtest` - the
one build that goes to somebody who is not you - was the only build nothing
ever started. It boots whatever Windows build was made now.

**The last line said the wrong folder.** `RELEASED build/windows and
build/web`, printed verbatim after a run that wrote `build/playtest`. It
names what it actually built.

### Step 8 is the one step not run

The list ends with a tag and a push. I did not make the tag. `v0.1.0` asserts
that 0.1.0 is the thing that went out, and nothing is going out today - the
store page is task 0107 and the trailer is 0109. A tag claiming a release
that did not happen is worse than no tag, and the changelog says
`unreleased` for the same reason.

Everything above it ran for real: the suite, the goldens, the version and the
changelog, both shipping builds, the packs, the byte-for-byte comparison of
the two, the size budget, the boot, and the playtest build with its note
beside it.

    RELEASED  build/web, build/windows
    total on the wire   12.04 MB     budget 13.00 MB

**Step 6 is a human step** and is written as one: five minutes with each
build, by hand, with six things to do in order. Nothing automates "does it
feel like it works", and a checklist that pretended otherwise would be a
checklist somebody skips.

### The known-issues section names five things and one of them is owed

Written to be read by somebody deciding whether to publish, so it says the
awkward one first: **nobody has watched a first-time player through day one**,
which task 0101 could not do, task 0105 built the build and the reader for,
and which is an hour of somebody's time that has not been spent. The other
four are the twenty-seven English strings still in `src/core/` (task 0110),
the web build's size being a gzipped number, the tech tree being checked
rather than balanced, and endless mode being unplayed.

The rollback paragraph is short because the game is a folder with no server
behind it - and it ends on the one thing a player would actually notice:
somebody who opens the newer build and then goes back will find their run
**refused rather than eaten**, with the save still on disk, because task
0104's migrations only run forward.

### Hashes

Both unchanged: **sim `1961000123`**, **data `407837701`**. The two tech
fixes change what a player with those nodes gets and change nothing for a
player without them, which is what the guard scenario is.

`python tools/verify.py` prints PASS: 6290 asserts, 978 input cases, 0 failed,
21 rows, no skips, **226 seconds against a budget of 300**.

## 0107 - Store assets - done 2026-09-28

`python tools/gen_marketing.py` makes the whole set: five screenshots, five
capsules, an animated GIF of the switch and the copy in both languages, into
`build/store/`. Everything in it comes out of the real build, `assets/logo.png`
and `tools/palette.py` - the same three sources the game is made of.

### The switch is the one thing worth animating, so the shot tool learned to

`shot.gd` photographed states. The reality switch is a **change**, and the
frame where the light is half over - day on the left of the sweep, night on
the right, the towers waking as it passes - is the single most useful picture
this game has. `--switch` captures it as a numbered strip, which
`gen_marketing.py` turns into a 28-frame GIF with a beat at each end so a
loop reads as day-then-night rather than as a light flickering.

**The first strip was twenty-four frames of a farm that never got dark.** The
transition runs on `delta` for `TRANSITION_SECONDS`, which at `--fixed-fps 60`
is ninety-six engine frames, and one picture per frame caught the first
quarter of it. The step is worked out from the constants now:

    var over := int(round(GameData.TRANSITION_SECONDS * float(FIXED_FPS)))
    var step := maxi(int(ceil(float(over) * 1.1 / float(SWITCH_FRAMES))), 1)

Which puts a second pair of numbers in two files - `FIXED_FPS` in `shot.gd`
and in `tools/shot.py` - so `headless_check` asserts they agree, and asserts
the arithmetic reaches the end of the fade.

### Five screenshots, and none of them is a sixth of the farm

The done-when names them and the reason is worth keeping: a store page has
four seconds of somebody's scrolling, and four pictures of a field say
"farming game" and stop.

    01-day      noon.png         the farm at noon
    02-switch   switch-14.png    the light half way over
    03-night    switch-27.png    the same tiles, after dark
    04-wave     wave.png         a wave mid-fight
    05-tech     tech.png         what the days pay for

Two of the five come out of the switch strip, which is the argument for
capturing it: the frame in the middle and the frame at the end are a better
"before and after" than any two scenarios built separately could be.

### The capsules took two looks to stop being wrong

**The first header was a close-up of four tiles and a hat.** The scale loop
pushed the zoom as high as it would go before cropping, so a 460x215 capsule
was 48% of the frame's width. The rule is the smallest whole scale that
covers the target now - never a fractional one, because a smoothed pixel game
on a store page is a lie about what the build looks like.

**The second had the night HUD's health bar clipped across the top edge**,
which reads as a mistake rather than as a game. The crop starts below the HUD
rows.

Both were found by opening the file, and neither would have been found any
other way.

### And the store screenshot found a bug in the game

`screenshot-05-tech.png` came back with its footer running off the right of
the screen:

    2 of 12 nodes, 4 points spent - the ten nights pay 40 at best and the whole tree costs

469 pixels of text from x=8 on a 480 pixel screen, and 475 in Portuguese.
**It had been like that since task 0081** and no check could have caught it,
because `TECH_SUMMARY` had `width` 0 in the string table - which is the column
that says "do not measure this one".

The sentence is shorter and the key has a width now, so `i18n_check` enforces
it in both languages from here on. That is the actual fix: the text was
wrong, but the reason it stayed wrong for twenty-six tasks is that it was
exempt.

### The copy is a person's, and the pitch is the design document's

`docs/STORE.md` is version-controlled and written in both languages; the
generator copies it into the set rather than producing it. The Portuguese
pitch is **section 20 of `design.md` verbatim**, and both the `store` row and
`headless_check` fail if the two drift apart - a page that stopped matching
the pitch would be a page describing a game somebody decided not to make.

The English is a translation of it plus an "about this game" section, and it
says what is *not* in the game as plainly as what is: nothing online, not a
roguelike, about an hour long.

### Two small things on the way

`release.py` cleared the whole of `build/` before exporting, which would have
eaten `build/store` - an hour of somebody's marketing - the first time the two
were run in the wrong order. It clears everything but that folder now.

And `gen_marketing.py --keep` reuses the pictures already captured, because
capturing is a minute and a half and laying out a capsule takes a dozen
tries.

### Hashes

Both unchanged: **sim `1961000123`**, **data `407837701`**. `TECH_SUMMARY` is
a string and the string table is not in either hash.

`python tools/verify.py` prints PASS: 6308 asserts, 978 input cases, 0 failed,
22 rows, no skips, 227 seconds.

## 0108 - The devlog and a trailer clip - done 2026-09-29

Thirty seconds of the game out of one seed, and a devlog page generated from
this file. `python tools/devlog.py` does both.

### Four beats and one cut

    the day      8s   a farm being worked
    the switch   5s   the light going over
    the night   12s   the horde arriving and the towers answering
    the fall     5s   the fence coming down

Three hundred pictures at ten a second, three sim ticks under each, which is
thirty ticks a second - **the speed the game is actually played at**, and
`headless_check` asserts that arithmetic. A trailer running at double speed
is a trailer lying about what the game feels like.

**There is one cut.** `PREPARATION_TICKS` is twenty seconds, two thirds of
the whole clip, and a trailer that spent it watching a farmer stand still is
a trailer nobody finishes. The cut is between the light going over and the
first wave, which is where a viewer expects one.

### The tool says whether the beats actually happened

A wall falling is not something a capture can promise - it depends on where
the horde walks and what it chews through. So it checks and prints, and the
first run said:

    the fall    NOTHING CAME DOWN - the fourth beat is missing

Which was the point of writing it that way. Three hundred frames had been
captured and nothing in them was the fourth beat.

### The night beat was thirty seconds of an empty meadow

Two things wrong, and `_set_wave` had already learned both at task 0082 - its
comment says so, and I did not read it until after.

**The camera followed the farmer**, who had spent the day beat walking west
into the field. So the night was a dark empty meadow with a fight happening
off the right of the screen. The night frames point the camera at the defence
line now.

**And the wave was dead four seconds in.** Eight towers clear what the table
sends before anything interesting happens. Sixty walk in by hand, which is
what it takes for the fence to be under enough pressure to come down - and
the fourth beat is that happening, with `fence destroyed` in the log panel
where a viewer can read it.

### The page is generated, and the first version quietly described four
fifths of the project

The done-when is that the devlog comes out of `implementation/PROGRESS.md`
rather than being written twice. It does: the task list, the dates, **every
recorded move of either determinism hash**, and the findings - which are the
journal's own sub-headings, picked out by the words this journal uses when
something did not work.

The first run reported **87 entries and 2 hash moves**. There are 109 and 26.

The journal is nine thousand lines written over a hundred and ten tasks and
it does not have one voice. Twenty-two entries were written before the
`- done <date>` suffix became a habit, and a hash move is written five ways:
`Sim`, `Sim hash`, `Data`, `Data hash`, `data hash`, in backticks and out of
them. A parser that knows only the most recent shape reports a smaller,
tidier project than the one that exists - and nothing about the page looked
wrong.

So the tool now counts the journal's entries against **the backlog's finished
tasks**, from a different file, and refuses to write a page when the two
disagree:

    FAIL  the backlog says 107 tasks are done and the journal gives up 87
          a page that quietly describes part of the project is worse than no
          page. Widen the parser or fix the entry.

Every task from 0001 to 0107 has an entry, checked, with no gaps.

### The English page had a Portuguese pitch in it

`design.md` is Portuguese - it is the original document - so an English
devlog quoting section 20 verbatim was an English page with a Portuguese
pitch in the middle. The English page takes its pitch from `docs/STORE.md`,
where task 0107 put a person's translation of it. Found by reading the page.

### A GIF, because there is no encoder on this machine

`ffmpeg` is not installed and this tool does not install things. So the same
three hundred frames produce two outputs: `docs/devlog/the-trailer.gif`,
which a page can show on its own, and the numbered PNGs - and the tool prints
the one `ffmpeg` line that turns them into an `.mp4`. Saying which half is
missing and how to finish it is better than quietly producing the second best
thing.

**3.45 MB, down from 5.12.** A frame of this game has three and a half
thousand distinct colours in it - the light ramp and the lamps blend - so
every frame was carrying its own palette. One shared table of 128 colours for
all three hundred, no dither, and the banding was looked for in a night frame
pulled back out of the finished GIF rather than assumed away. Measured:
256 colours is 3.93 MB, 128 is 3.45, 64 is 2.95. 128 is where the saving
stops being worth risking a banded sky.

It is committed rather than generated on demand, because a devlog page
without its clip is not a devlog page.

### What is deliberately not generated

The two paragraphs of opinion at the top, which are in
`docs/devlog/preamble.md` in both languages where a person can edit them. A
devlog with no opinion in it is a changelog, and nobody reads a changelog for
fun.

### Hashes

Both unchanged: **sim `1961000123`**, **data `407837701`**. Nothing outside
`src/tools/` and `tools/` was touched.

`python tools/verify.py` prints PASS: 6324 asserts, 978 input cases, 0 failed,
23 rows, no skips, 235 seconds.

## 0109 - The character reacts - done 2026-09-29

Four bubbles over the farmer's head, for four moments the game already had.
`src/core/reactions.gd` decides which and for how long, `src/ui/player_view.gd`
draws it, and **both determinism hashes are unchanged**.

    a bite on the line              !
    a crop coming ready nearby      a note
    something of yours coming down  ?
    the night arriving              !

### It is a fact in the state and it is still decoration

Those sound like opposites. It is **in the state** so that the autoplayer, a
replay and a screenshot see the same bubble on the same tick - a view that
invented them frame to frame would show a different one whenever the frame
rate moved, which is the bug task 0090 wrote the event log to avoid. It is
**decoration** because nothing reads it.

The done-when is that turning every reaction off leaves the determinism hash
unchanged, and the honest way to get that is not to be careful - it is for
the hash never to have looked. `State.NOT_THE_GAME` is a list of keys
`hash_of` skips, and it has exactly one thing in it.

That is a load-bearing exclusion, so it is guarded: `headless_check` greps
`src/core/` and fails if anything outside `reactions.gd` so much as mentions
the key, with one allowance for the single line in `sim.gd` that ticks it.
Planting a read of it in `farm.gd` fails that row.

And the pair of runs is compared directly - one with reactions, one with them
cleared every tick - which has to come out at the same hash and the same
wood. **That assert passed for nothing the first time.** With the exclusion
taken out to watch it fail, it still passed, because the scenario never
raised a reaction at all. It now sows a field next to the farmer and counts
the bubbles, and asserts there was at least one before comparing anything.

### The exclamation mark was not on the sheet, as far as the cutter knew

Task 0073's cutter finds frames by looking for runs of opaque columns. A
bubble is a glyph **beside** the farmer rather than part of them, and `!` is
a twelve pixel run of its own - narrower than anything the column pass will
call a frame. So it was dropped, and the pose came out as a farmer with
nothing over their head.

Checked across the whole sheet before touching anything: it is the only run
this happens to. So the reaction row is cut by explicit x ranges, which is
the same kind of data the module already holds - "what the tool cannot know
is which pose is which" - rather than by loosening a rule that is right in
every other band.

The heart is cut and unused. The star and the lightbulb further along that
row are drawn touching their neighbours and are **not cut**, because nothing
asks for them and a frame nobody loads is a frame nobody notices has broken.

### Two things the pictures decided

**The farmer turns to face you.** All four drawings face the viewer, so a
reaction over an idle pose turns them south for a second and a half. The
alternative was showing the bubble only when they already faced south, which
is a feature that works a quarter of the time. It reads as looking up, which
is what the moment is.

**And it only happens over an idle pose.** A farmer mid-swing with a music
note over their head is two things at once and reads as neither, so a bubble
waits for the work to finish - and if it runs out first it is simply not
shown, because the moment it was about has passed.

### The screenshot came back with no bubble in it

`shot.gd` settles thirty frames of the running game before the shutter, so
the view has something to have noticed - task 0088's lesson. A reaction lasts
forty-five ticks, which is less than that, so it came and went during the
settle and the picture was a farmer standing in a field.

Which is the feature working. There is a `_just_before_the_shutter()` step
now for anything shorter than the settle, and
`implementation/shots/0109/react.png` has the note in it.

### Task 0102's rule caught me

Adding `Reactions.tick()` to `Sim.tick()` failed this immediately:

    FAIL  every system the sim ticks is one the benchmark times
          missing: ["Reactions"]

Which is exactly what that check was written for at task 0102 and the first
time it has fired on a real omission. `PerfNames` has it now, in both lists,
and the baseline moved: **`night_reactions` 7us, `day_reactions` 5us**
against a night tick of 1050. `night_tick` 1044 -> 1050 and a handful of
one-microsecond wobbles, all inside the noise the tolerance was measured
for.

### Hashes

Both unchanged: **sim `1961000123`**, **data `407837701`**.

The reaction levers are in `game_data.gd` with `# LEVER` on them as the house
rules ask, and they are **not** in `GameData.digest()`, which is the balance
hash: how long a bubble stays up is not a number that changes how the game
plays, and putting it in the balance guard would mean a designer could not
shorten it without moving a number that is supposed to mean "the balance
changed".

`python tools/verify.py` prints PASS: 6363 asserts, 978 input cases, 0 failed,
23 rows, no skips, 237 seconds.

## 0110 - Refusals in two languages - done 2026-09-29

The last English sentences in `src/core/`. Twenty-one refusals across four
functions now hand back **a key and its arguments** instead of a sentence, and
`Names.refusal()` says them in whatever language is up.

    Building.why_not()          ->  [&"WHY_OCCUPIED", &"workshop"]
    Farm.why_not_buildable()    ->  [&"WHY_IN_THE_WATER"]
    Tech.why_not_buy()          ->  [&"WHY_COSTS", 6, 2]
    Sim.why_not_skip()          ->  [&"WHY_HOUSE_LOW", 45]

An `Array` rather than a Dictionary or a pair, because **every caller already
asked `.is_empty()`** - `can_place`, `can_upgrade`, `can_buy`, `can_skip` and
three screens - and an empty Array is falsy in exactly the same place a
sentence was. Twenty-one returns changed and not one caller's condition did.

### Three arguments rules, and no fourth

`Names.refusal()` is the one place a refusal becomes words:

- a **`StringName`** is an id and goes through `Names.of()`, so a player is
  told "workshop" and, in Portuguese, "oficina" - never `workshop` with an
  underscore in it
- a **`Dictionary`** is a pile of resources and comes out as "3 wood, 2
  stone", sorted, so two runs read the same
- anything else is a number and is printed

The rules never learn a word of either language. That is the whole point: the
half that knows what a player calls a thing is the half with the screen in
it.

### Three sentences stay, and are named one by one

`Waves.summary_of()`, `Waves.note_for()` and `Endless._note()` are still
English, and should be: they are read by `tools/nights.py` and by this
journal, and by no screen at all. The check does not excuse them by folder -
it lists them by their exact text, so a fourth cannot join them quietly - and
it also greps `src/ui/` to confirm no screen has started showing one.

### The checks stopped being about the copy

Every assert that touched a refusal compared **English**:

    expect(Sim.why_not_skip(noon) == "only at night", ...)
    expect(Tech.why_not_buy(day, first).contains("already"), ...)

So rewording a message broke checks that had nothing to do with the wording -
which is exactly what happened when I shortened `WHY_HOUSE_LOW` to fit its
label: an input case looking for the word "watching" went red. They assert the
key now, through a `_refused()` helper, and the input case asserts
`I18n.t(&"WHY_IN_THE_WATER")` rather than the words - so what it proves is the
whole road, rule to key to table to label, instead of one spelling.

And it proves it **in Portuguese**, which is the done-when and the one thing a
width checker cannot answer: the table can be complete and a refusal still
arrive in English, if anything between the rule and the label is a sentence
somebody wrote in GDScript. The case switches the language, points at the
pond, and fails if the label did not change.

### Two things the pictures decided

**The reason label never wrapped.** It is 114 pixels wide in a 124 pixel
panel, and "already occupied by a gun tower" is 155 - so the end of most
refusals had been running off the side of the frame since the panel was
built. It wraps to two lines now, and the new keys have a width of 228 so
`i18n_check` holds them to it.

**And `WHY_HOUSE_LOW` did not fit even then.** 257 pixels in English against
the 228 it has. Shortened to "the house is at %d%% - watch this one", which
is better copy as well as a shorter one.

`implementation/shots/0110/refused.png` and `-pt_BR` are the picture that
answers it: "there is a workshop there already" over two lines, and "já tem
oficina aí" on one.

### A grep that missed the shape it was written for

The done-when is that `grep` finds no player-facing sentence left in
`src/core/`, so the check greps for one. The first version looked for
`return "` - and a sentence smuggled into the first slot of a refusal,
`return ["already yours, friend"]`, walked straight past it. Which is the
only shape this task could plausibly regress into. It looks for both now,
and the plant fails it.

### One thing this task did not do

The build palette lists `auto_crossbow`, `flame_tower` and `gun_tower` with
their underscores in, in both languages. That is an id printed raw on a
screen - but it is a palette label and not a refusal, so it is outside this
task's requirement and outside its done-when. Written down here rather than
fixed quietly or left unsaid: it is the next thing anybody looking at
localisation should pick up.

### Hashes

Both unchanged: **sim `1961000123`**, **data `407837701`**. A refusal is
computed and returned; none of it is ever stored in the state, so changing
what it is made of changes nothing the guard can see.

`python tools/verify.py` prints PASS: 6417 asserts, 980 input cases, 0 failed,
23 rows, no skips, 235 seconds.

## 2026-10-02 — Follow-up: larger farm, smooth camera and idle life

The user explicitly confirmed 25% more area: 40x18 -> 45x20, 720 -> 900 cells.
Original map coordinates and its first 720 cells are unchanged; new meadow and
shore extend east/south and east spawns move to column 44. State version 1 -> 2
has a tested save migration for terrain, indexed run tables, regrowth/fuel and
live targets, preserving player/building coordinates and rebuilding caches.

Camera tracking now follows subtile position on both axes with delta-time
smoothing, bounded zoom and correct inverse picking/light scaling. Wheel or
=/- changes zoom (0.875x through 2x); 0 resets. These are rebindable actions.
Existing tree/animal textures gain canopy sway, hen pecks and cow head/tail
motion, with fixed ground anchors and pause-aware visual time. Farmer blinking
holds eyes open for 3.2s and closes for 0.1s. Three frontal idle frames replace
the one-eye wink; a black-eyed first candidate was rejected and superseded.

The larger spawn distance exposed an enemy stuck behind distant impassable
structures. When no house route exists, the existing hunt field now approaches
a reachable structure before chewing. Real-HP giant escape and ordinary combat
checks pass. Related fixture updates and native review are documented in
implementation/reviews/world-visibility/REVIEW.md.

This map/version change intentionally moves sim 1961000123 -> 3960053733 and data
407837701 -> 3913993875. Subsequent visual revisions keep those hashes unchanged.
Full tools/verify.py: 53 passed, zero skipped/failed, 6,998 assertions and 985 input
cases, Windows/Web/playtest exports successful. Runtime tick 595us/8,333us;
path rebuild 5,601us/33,333us. Total 465s exceeds the soft 300s suite target.

Evidence includes 274 native motion/zoom captures (669 renderer checks), a
121-check headless visibility fixture, timed native GIFs, nearest contact pages,
source provenance and five Main captures under implementation/shots/world-visibility/.
Only three runtime PNGs changed; other sprite families and 480x270 resolution
are preserved. Ambient animals stay in their gameplay cells; fractional zoom
retains nearest-neighbor pixel-size variation. No push or automation is started.

## 2026-10-02 — Larger buildings, another 25% farm and enterable farmhouse

User-directed follow-up outside the completed implementation/sprite queues.
House, shop, workshop, kitchen, press and generator reuse their accepted exterior
PNG art at 2x integer scale, with larger logical footprints and aligned placement,
lights and chimney. The fresh farm rearranges fixtures to keep the doorway and
ore approach accessible. Its map grows 45x20 → 45x25, 900 → 1,125 (+25%), adding
225 connected clear southern cells. Actual planting beds also grow 48 → 60 (+25%)
with a 4x3 southern garden; grass remains building/circulation ground. Clear
soil/grass after the larger buildings grows 591 → 787. All 468 previous tracked
PNG files are unchanged; no prior sprite family or resolution is regenerated.

One built-in image_gen.imagegen transparent modular sheet supplies nine new
source-owned interior assets. Original, exact prompt, measured cuts, metadata,
plan and native evidence: implementation/farm-house/. Interact at the daytime
porch enters a furnished 20x13 room. Walk to the southern door to exit. The same
farmer, zoom, smooth camera and pause work there. Furniture blocks movement and
is currently decorative. Farm growth/production continue; defence returns outside.
Indoor coordinates cannot sell/build outdoors or open external workshop/tutorial
panels. Locale refresh also skips the I18n service's own static traversal method.

State 2 → 3 migrates both old grids while preserving crops, inventory, queued
jobs and products. Obstructed stations retain compact saved footprints; a house
whose enlargement would cover crops moves onto clear southern land. The automatic
player now scores the actual house frontage and leaves firing space, preserving
all four policies' first-night survival. Giant/rerouting tests retain their behavior
checks with power behind the fight and a genuinely connected fence gap.

Map, footprints, interior state and new garden intentionally move sim
3960053733 → 1270427719 and data 3913993875 → 3247244688. Native verification:
273 room/farm checks, 8 keyboard house cases, six room/exterior captures and eight
Main captures at 480x270. Final full verification is logged at
implementation/farm-house/verify-pass.log: **54 passed, zero skipped/failed**;
122 scripts parsed, 7,577 core assertions and 995 input cases passed, including
Windows/Web/playtest exports. 479s exceeds the soft 300s suite target; runtime
performance checks pass. Sim/data are stable at the new recorded baselines.
Optional GODOT_PROJECT_PATH and the task's QA mirror isolate save/profile fixtures
from player files; release exports always use the actual project settings.
No new top-level folder, push or automation. Unrelated editor serialization and
previous untracked imports remain outside the commit.


## 2026-10-02 — Follow-up: wall furniture, living hearth and bedside lamp

User requested the north furniture against the wall, a coherent wardrobe
orientation, animated fire, and a bedside cabinet with lamp. Kitchen/hearth/bed
move their solid footprints north by one row. A new cabinet beside the bed blocks
movement; the wardrobe occupies the east wall facing west. Measured presentation
offsets align the cabinet back/headboard/wardrobe rear to their walls. Circulation
and the southern exit remain open. Indoor saves under newly occupied furniture
move deterministically to nearby free floor, preserving their outdoor position.

Two separate built-in image_gen.imagegen calls generate only the west-facing
wardrobe and lamp cabinet. Their originals, exact prompts, provenance, measured
cuts, review and native 480x270 evidence are under implementation/house-polish/
and assets/art_source/interior/. Source-owned outputs use the existing palette
and import pipeline. Of 5,746 previously tracked PNGs, only the requested storage
sprite changes; all other prior art and prior room captures remain byte-identical.

The existing fireplace uses a localized shader for its 14x10 open firebox. Its
cosmetic clock freezes with pause and honors steady-light accessibility. Stones,
plants and grate remain stationary, with exactly their original source colors;
the native pixel comparison verifies both movement and source preservation.
The bedside lamp adds a small steady warm halo. Neither writes simulation state.

Furniture footprint data intentionally moves data 3247244688 → 8148086.
Sim remains 1270427719. Visual offsets and animation remain UI-only. Verification:
293 native room checks, 272 headless room checks, 7,581 core assertions and 996
full input cases pass, including the real pause key freezing the hearth. The
isolated nine-case house harness retains its existing shutdown warning; the
complete input suite passes. Full verify and Windows/Web/playtest exports:
54 passed, zero skipped/failed, logged in implementation/house-polish/verify-pass.log.
608s exceeds the soft 300s suite target; runtime checks pass at 650us/night tick
and 8,481us/path rebuild. Native/Main Portuguese captures are actually opened.
No new top-level folder, backlog status change, publishing, push or automation.
Unrelated project serialization and prior untracked imports stay outside the commit.


## 2026-10-02 — Follow-up: anchored hearth flame tips

The user found the hearth looked like it was dancing. Replace the periodic
whole-fire horizontal/vertical warp with small independent variations of tongue
height. Sampling never moves horizontally; the lower three rows remain anchored.
No sprites, core rules or furniture positions change. Pause, steady-light
accessibility and source colors remain intact.

The native renderer check adds a fixed-base assertion and passes 294 checks.
An optional --fire-loop capture records 24 native 480x270 frames over three
seconds. Playback comparison finds moving tips in 23 of 24 samples, zero changed
base pixels and zero changes outside the firebox. Actual captures are opened;
a shared-palette GIF and reproducible encoder are saved with the evidence in
implementation/house-polish/fire-fix/. A fresh Main/Portuguese capture is in
implementation/shots/hearth-fix/. The completed backlog statuses stay unchanged.

Final full verification: 54 passed, zero skipped/failed in 462s (soft 300s target
exceeded); 7,581 core assertions, 996 input cases and Windows/Web/playtest exports
pass. Runtime budgets pass (521us/night tick, 6,980us/path rebuild). Sim 1270427719
and data 8148086 stay unchanged. Evidence/log: implementation/house-polish/fire-fix/.
No new top-level directory, new art generation, push or automation.


## 2026-10-02 — Follow-up: approved farmer walk/run animation assets

The user approved the exact compact farmer attachment and requested eight frames
each for walking and running, plus a horizontal idle/walk/run GIF. The approved
identity is assets/art_source/player-fhd/approved/idle_south.png; it keeps the eye
arrangement the user selected rather than later eye experiments. Built-in ImageGen
produced eight front-facing walking and eight front-facing running drawings.
The first walk was revised to correct misordered left/right support halves.

Nineteen source-owned native assets (three idle, eight walk, eight run) use a
96x96 canvas, (48,88) contact, binary alpha, the shared palette and one measured
reduction scale per strip. Hat center registers the body horizontally rather
than moving it onto the current single support boot. Running retains raised
boots during flight. Both cycles have eight distinct lower-body drawings.
Exact source cuts, hashes, ground measurements and playback timings are in
implementation/fhd-player/locomotion-contract.json; raw sheets, PNG frames and
exact prompts/call metadata are under the approved art/prompts directories.

Real Godot playback produces 192 captures at 25fps, drawn at the intended 120px
physical FHD body height. The 660x240 horizontal GIF runs 7.68 seconds with a
shared palette: walk 120ms/frame, run 80ms/frame, idle with a brief blink. Source
checks pass, complete contact sheets and consecutive actual renderer frames are
opened, and both cycle wraps are reviewed. GIF: implementation/fhd-player/
idle-walk-run-horizontal.gif; captures: locomotion-playback/; reproduce with
build_locomotion_preview.py and src/tools/fhd_locomotion_preview.gd.

Full working-tree verify/export: 54 passed, zero skipped/failed in 472s (soft
300s target exceeded), 7,581 core assertions and 996 input cases. Sim 1270427719
and data 8148086 remain unchanged; night tick 510us, path rebuild 6,822us. Log:
implementation/fhd-player/verify-locomotion.log. The game/sprite backlog statuses
remain complete and unchanged. This focused art commit does not add a sprint
mechanic or promote a partial actor family into gameplay. Broader FHD rendering
and full character-family integration remain separate unfinished workspace work.

## 2026-10-02 — Follow-up: four-direction farmer animation validation

The user approved the front idle/walk/run preview and requested all four
cardinal views and every activity, with horizontal GIFs before game integration.
Built-in ImageGen generated nine missing locomotion strips and thirteen activity
atlases, with six focused source revisions. The exact approved front identity
(SHA-256 4706f5b8163d4be2d3d8f285bdffe970a315a9c770e6b28bef4e74c4993ba6f1)
and all nineteen previously approved front native frames remain unchanged.

The review family contains 284 native frames / 64 directional animations: three
idle, eight walk and eight run per direction, plus four key poses per direction
for chop, mine, till, plant, harvest, water, fish, reel, collect, craft, trade,
repair and carry. All four views are authored independently. Raw sources and
265 new cuts live in assets/art_source/player-fhd/directional/; exact prompts,
call provenance and final source/prompt/output/selection hashes are in
implementation/fhd-player/directional/. No sprites/actors, production player
bindings, movement mechanic or core/balance data are replaced by this follow-up.

Visual review caught and fixed reversed east run poses, side-facing planting
bends, the west hammer striking backward, and north axe/pickaxe contact behind
the target direction. Crop review additionally caught the north crown being
measured from its brim, inconsistent brown material ramps and foreign tool tips
leaking from adjacent atlas rows. Final cuts use per-column activity gutters,
connected original farmer/tool alpha components (with seeds/drops included),
uniform strip scales and the existing shared palette. Complete locomotion
silhouettes remain within 60 native pixels, preserving flight and planted feet;
work's transparent 128x128 canvas retains raised tools without shrinking bodies.

Real Godot playback captures 192 frames at 25fps per category. The sixteen
1040x288 horizontal GIFs show front/left/back/right at the intended 120px FHD
body scale. The combined todas-animacoes-horizontal.gif cycles all categories
for 61.44 seconds. The local index.html offers individual clips, native/FHD scale,
downloads and all directional contact sheets. Complete native contact overviews
and original renderer phase evidence were opened; casting holds a visible rod
while waiting. The source check verifies all counts, hashes, binary native alpha,
unique work poses and eight distinct lower-body phases for each walk/run cycle.
Full local renderer captures remain under captures/; 128 selected originals and
sixteen consecutive-phase montages are retained under review-stills/.

Full working-tree verify/export passed 54 checks with zero skips/failures in
527s (over the 300s soft target), including 7,581 core assertions and 996 input
cases. Sim 1270427719 and data 8148086 remain unchanged; night tick 631us, path
rebuild 8,562us. Log: implementation/fhd-player/directional/verify.log. Latest
standalone preview parsing, exact cuts and real renderer playback were checked
again after crop/palette-only refinements. Completed game/sprite queues remain
unchanged. This is a candidate family awaiting the user's visual validation;
subjective gait/readability approval, consistent runtime padding/bindings and
live farm/house day/night composition remain integration work after approval.
The earlier broader FHD working-tree edits and rejected pilots are preserved.


## 2026-10-02 — Follow-up: lateral farmer walk from creator prompts

The user approved idle and rejected west/east walking because the same leg led
both stride halves. The replacement remains a review candidate; it has not been
promoted to the runtime actor family. Idle approval stays in user-review.json.

Imported the actual buildDirectionalPrompt and STUDIO_ACTIONS exports from
C:/Users/Helel/Documents/repos/sprite-sheet-creator/app/lib/prompts.ts without
changing that repository. Its source SHA-256 is
5bdeda5f9d40b0becfd4bbacac9728225211218fa4d2b26574e42de39a74f1f8.
Reference order follows the builder: accepted right rotation, canonical farmer,
and accepted front walking. Exact base/adapted prompts, calls, original output
paths and failed candidates remain in implementation/fhd-player/directional/.

Final sources are assets/art_source/player-fhd/directional/
creator-walk-right-keys-r1.png and creator-walk-right-transitions-r2.png. Four
anchor poses occupy phases 0,2,4,6; four transitions occupy 1,3,5,7. The complete
right poses are reflected for left, following the creator README. The reflected
96x96 canvas retains its corresponding ground pivot at (47,88), versus (48,88)
on the right. Only sixteen lateral walking native PNGs changed. The other 268
frames, including approved idle and front/back walking, are byte-identical to
HEAD. Transition boot colors use the existing brown material ramp so palette
quantization does not map warm leather onto hat gold; no sprite is hand-painted.

Added a meaningful gait regression check for near/far boot material separation
at contact/support/reach phases 0,1,3,4,5,7 in both lateral views. All twelve final
poses pass, while the earlier same-leg family fails the negative control. This
check catches that specific error; it does not establish subjective animation
quality. Measurements are retained in walk-gait-regression.json. Exact source
checks pass for 284 frames and 64 animations, binary alpha, hashes, distinct
poses and eight distinct lower-body drawings per locomotion cycle.

Recaptured 192 real Godot walking frames at 25fps. Rebuilt the 1040x288 horizontal
walk GIF (7.68s) and the full sixteen-category overview (61.44s). Eight consecutive
phases, selected original captures, contact sheets and the final browser proof
are retained in review-stills/. The same local index.html was reloaded, WALK
selected and verified at the intended FHD 120px body size. Content hashes on GIF
URLs prevent old cached previews. Prompts use built-in ImageGen.

Full working-tree verify/export passed 54 checks, zero skips/failures in 675s
(over the 300s soft target), including 7,581 core assertions and 996 input cases.
Sim hash 1270427719 and data hash 8148086 remain unchanged. Evidence is in
walk-revision-verify.log. Later changes were confined to offline art cuts and
review output and passed final source/gait checks plus real renderer capture and
GIF encoding. Completed game/sprite queues remain unchanged. Runtime bindings,
core simulation and pre-existing broader FHD changes are preserved. Walking
still awaits user visual validation; no push or runtime integration was made.


## 2026-10-02 — Follow-up: lateral running from creator prompts

The user requested replacements for left/right running after the lateral walking
review. This changes preview art only. Idle approval, all walking and front/back
running remain intact; runtime player bindings have not been promoted.

The actual sprite-sheet-creator run action and buildDirectionalPrompt export are
imported through import_creator_run_prompts.cjs. The external repository is read
without modification. Exact base/submitted prompts, references, original output
paths and builder provenance are retained in directional/prompts/creator-run-*.
The builder source SHA-256 remains
5bdeda5f9d40b0becfd4bbacac9728225211218fa4d2b26574e42de39a74f1f8.
Built-in ImageGen produced the sources; no native sprite was painted by hand.

Final raw sources are assets/art_source/player-fhd/directional/
creator-run-right-keys-r1.png and creator-run-right-transitions-r2.png. Four
anchors occupy phases 0,2,4,6 and four intermediates occupy phases 1,3,5,7.
Focused edits corrected repeated arm swing, extended contact substituted for
compressed support, and a hidden recovery leg in opposite support. Both legs
and the near/far arm roles now alternate between stride halves. Left reflects
the complete right drawing and pivot: west (47,88), east (48,88), 96x96 canvas.
The existing brown material ramp preserves leather rather than mapping it onto
hat gold. Only sixteen lateral running PNGs changed; the other 268 native
frames are byte-identical to d5a27f7d, including idle and all walking.

Source checks pass for 284 frames, 64 animations, exact hashes, binary alpha,
complete silhouettes and eight unique lower-body locomotion phases. The new
run check guards boot material alternation and planted/airborne registration
for all sixteen lateral poses. Contact/support phases 0,1,4,5 stay on the shared
ground; flight phases 2,3,6,7 clear it by 2-4 native pixels. A negative control
rejects the old same-leg running family. Reproducible evidence is retained in
check_lateral_run.py, run-gait-regression.json and run-gait-check.log. These
checks target the earlier defects and do not imply user visual approval.

Godot recaptured 192 original walking-speed-independent RUN frames at 25fps,
switching to the next pose every two frames. The 1040x288 horizontal run GIF
loops for 7.68s at the intended FHD 120px body height; the 61.44s combined
overview also contains the revised run. Eight consecutive actual renderer
poses, native contact sheets and the browser proof run-gallery.png were opened.
The same local index.html was reloaded with RUN selected and content-hashed GIF
URLs. All other individual GIFs remain unchanged.

Full working-tree verify/export passed 54 checks, zero skips/failures, in 507s
(over the 300s soft target). It parsed 124 scripts and passed 7,581 core asserts
and 996 input cases. Sim hash 1270427719 and data hash 8148086 remain unchanged.
Complete evidence is in implementation/fhd-player/directional/run-verify.log.

The sprite queue check remains PASS for 20 completed prompts. Runtime bindings,
core simulation and unrelated broader FHD work remain unchanged. User review
metadata records run as pending. No push or runtime integration was made.

## 2026-10-02 — Follow-up: reviewed farmer locomotion integrated in FHD

The user explicitly authorized game integration: "quando terminar implementa no
game". Promoted idle/walk/run in all four directions: 12 idle + 32 walking +
32 running poses, 76 runtime PNGs. The thirteen activity candidates (208 frames)
remain pending visual review; no new images were generated in this integration.

implementation/fhd-player/directional/promote_locomotion.py registers the exact
selected native PNGs with the existing raster owner. The runtime contract pins
the original generated masters, submitted prompts, crop recipes and hashes.
Its --check rederives all 76 original native cuts and verifies identical runtime
bytes, fixed per-animation geometry and 0.5 draw scale. Source/native paths are
retained in runtime-locomotion-contract.json. Revised lateral masters remain
creator-walk-right-keys-r1.png / creator-walk-right-transitions-r2.png and
creator-run-right-keys-r1.png / creator-run-right-transitions-r2.png under
assets/art_source/player-fhd/directional/. References/prompts remain those
already retained in directional/prompts/; no hand-drawn replacements or recuts.

The manifest now owns 512 raster outputs (55 additions). Legacy work/reaction
art and the shadow remain intact: 58 unrelated actor PNGs are byte-identical
to the previous commit. Generated PlayerFrames/RasterArt metadata binds all
twelve locomotion animations; 96x96 canvases preserve the reviewed contact,
including west's reflected (47,88) pivot. Existing tools/reactions retain
their own canvas metadata. East locomotion uses explicit east assets.

The game defaults to 1920x1080 and Canvas Items rendering over the unchanged
480x270 design layout. Video defaults and fallback use scale 4. A 60-native-
pixel farmer draws at 120 physical pixels in FHD. CaptureSize explicitly keeps
legacy test fixtures native while --fhd captures actual production detail.

Shift is a named/rebindable held input selecting RUN, outdoors and in the house.
Releasing it while moving restores WALK; Shift alone remains IDLE. Core speed,
collision and simulation are unchanged. Run currently animates at the existing
walking travel speed; sprint speed/stride-to-travel tuning is a gameplay
follow-up if requested. No simulation hash was accepted or moved.

Production World/PlayerView and Player.tick were captured at physical FHD under
the real day/night relight pipeline: 24 timed sequences, 1,536 renderer frames,
all 76 poses in each light state, 6,168 checks and zero failures. Simulation
movement runs at 30Hz, sampled at 25fps. runtime_capture.gd / runtime_encode.py
retain reproduction. Original runtime-captures stay local, excluded from Git
and editor import. runtime-capture-report.json and runtime-capture.log record
the evidence. review-stills/runtime-horizontal.gif contains the actual physical
pixels (1024x232, 384 frames, 15.36s), with full FHD frames and consecutive
lateral running phases alongside. Native and nearest 3x crops were inspected
for eye whites, alternating boots, ground alignment and flight/loop continuity.

Full-game FHD screenshots were opened for noon, dusk, wave, result, tech and
house_interior in implementation/shots/sprites/fhd-locomotion/. Player scale and
sorting remain coherent in farm/house and lighting. An initial verification
found stale hard-coded terrain pivot and east-idle expectations; those assertions
now check actual per-animation metadata and explicit east idle. Final complete
working-tree verify/export passed 55 checks, zero skips/failures, in 491s
(over the 300s soft target), parsing 125 scripts, 7,768 core assertions and
1,006 input cases. Evidence: directional/runtime-verify.log. Sim hash 1270427719
and data hash 8148086 are unchanged. Sprite queue check remains PASS for all
20 completed prompts; completed queues stay unchanged.

Review metadata and the same index.html now distinguish integrated locomotion
from pending activities and link the runtime GIF. Older rejected pilots and
unrelated untracked source/import side effects remain outside this commit.
No push was made.

## 2026-10-03 — Follow-up: repair actual two-leg motion in lateral RUN

The user reported that integrated left/right RUN still looked like one moving
leg. That report is confirmed: previous commit 0cbb4a27 passes every old boot
material check, but its foreground trouser/knee barely changes position across
opposite contact/passing phases. Different PNGs and boot colors had provided a
false positive. The earlier integration remains functional; this repairs the
sixteen lateral run drawings and the insufficient visual guard.

Built-in ImageGen generated creator-run-two-leg-keys-r1 from the approved
idle_east identity. It was rejected because its airborne anchors repeated an
extended stride. A targeted r2 draws compact bent-knee passing poses and true
foreground/background trouser/ankle exchange. Four intermediates come from
creator-run-two-leg-transitions-r1. Final masters are under
assets/art_source/player-fhd/directional/; submitted prompts, original built-in
output paths, references, decisions and the creator run prompt provenance are
in implementation/fhd-player/directional/prompts/creator-run-two-leg-*. The
sprite-sheet-creator run/opposite-stride guidance remains the prompt basis.
No native sprite was hand-painted or substituted with code.

New source-owned cuts retain the 60px body, 96x96 canvas and east (48,88) /
west (47,88) contacts. West reflects the complete east pose and registration.
Near bright trousers/medium leather now recover behind while dark far trousers/
leather bear weight, followed by the opposite passing and support. Eight
individual lower-body poses remain. The source importer writes exactly sixteen
runtime PNGs; other 268 native review frames and fifteen individual action GIFs
remain byte-identical to 0cbb4a27. All other runtime actor PNGs are preserved.

The new foreground-trouser geometric test excludes boots. Opposite knee
positions now exchange by 5.94 native pixels across contact and 10.22 across
passing in both directions. The actual reported baseline fails this test even
though it passes the old color test. check_lateral_run.py / run-gait-regression.json
retain the negative control and measurements. Existing boot and contact/flight
checks stay enabled. The geometric guard runs during build_review and the
runtime-source check in the full suite; visual playback remains required.

Source/prompt/native/runtime contracts and manifest reference hashes are updated.
The same runtime bindings, eight-frame clocks, FHD scale, controls, movement
speed, collisions and core rules are preserved. This is a drawing repair.

Actual Godot preview: 192 frames at 25fps, RUN GIF 1040x288 / 7.68s, and the
61.44s overview refreshed. Runtime World/PlayerView/Player.tick day/night capture:
24 timed sequences, 1,536 actual FHD frames, 6,168 checks and zero failures.
Normal-speed leg recovery and loop continuity were inspected in consecutive
frames, native scale and nearest 3x crops. runtime-horizontal.gif and its phase/
3x/FHD evidence are refreshed. build_run_comparison.py creates
review-stills/run-two-leg-comparison.gif (1040x312 / 7.68s), showing old/new left
and old/new right at the same clock. Original renderer frames stay local and
reproducible; no interpolated poses were invented.

The same local index.html loads the new RUN by content hash b14756c5d6c9 and
links the comparison. Its RUN selection and updated links were checked in the
existing browser tab. Full-game FHD noon/dusk/wave/result/tech/house_interior
captures were opened in implementation/shots/sprites/fhd-run-two-legs/.
User review metadata marks the repaired RUN as pending visual validation while
keeping it integrated under the existing authorization.

Full working-tree verify/export passed 55 checks, zero skips/failures, in 529s
(over the 300s soft target), parsing 125 scripts, with 7,768 core assertions and
1,006 input cases. Sim hash 1270427719 and data hash 8148086 remain unchanged.
Logs: directional/two-leg-verify.log, two-leg-gait-check.log,
two-leg-preview-capture.log, two-leg-runtime-capture.log and two-leg-shots.log.
Sprite queue check remains PASS for 20 completed prompts; queues are unchanged.
Incidental editor reserialization of the run input was restored to the existing
config. Older unrelated pilot files remain outside the focused commit. No push.

## 2026-10-03 — Follow-up: match front/back WALK head proportions to idle

The user reported enlarged heads while walking down and up. Native comparison
confirmed south head/brim widths of 48/44 pixels and north widths of 46/42,
versus the accepted idle head width of 43 and south/north brim width of 39.
This is source-art proportion drift, not a window/resolution issue.

Built-in ImageGen made one targeted edit per eight-pose sheet, retaining the
existing contact/lift order, compact farmer identity and approved eye whites.
Selected raw masters: assets/art_source/player-fhd/directional/walk_south-head-r1.png
and walk_north-head-r1.png. Exact submitted prompts, original built-in output
paths, reference roles and decisions are under directional/prompts/walk_*-head-r1.*.
Original approved sheets remain unchanged. No native sprite was painted.

New source-owned cuts keep 96x96 canvases, (48,88) pivots and 0.5 draw scale.
South head width is 42, brim 37–38; north head is 42–44, brim 38–40. Maximum
body height stays 60 native / 120 physical pixels at FHD, with natural passing
pose variation. Eight unique lower-body phases remain in each strip. The other
268 native review drawings, every other runtime actor and fifteen other action
GIFs are byte-identical to 80d269e6. Exactly sixteen runtime PNGs were rewritten.
Body/leg drawings within the two edited sheets are generated source edits;
they are not claimed byte-identical to the old sheets.

build_review.head_dimensions excludes overall buttons from hat measurements.
assert_walking_head_scale checks all sixteen head/brim widths against accepted
idle and cycle consistency during review and the full runtime-source guard.
check_walking_heads.py / walk-head-regression.json retain the actual old
oversized-head negative control and preservation measurements. Revised south
walking has an explicit source owner; the historical approved front contract
stays intact. Stable contract ordering avoids unrelated manifest churn.

Actual Godot WALK preview: 192 frames at 25fps, same horizontal gallery and
7.68s four-direction GIF. build_walk_head_comparison.py provides old/new down
and old/new up at matched clocks in review-stills/walk-head-comparison.gif.
Native nearest-3x idle/before/after comparison was opened. Production
World/PlayerView and 30Hz Player.tick day/night capture: 1,536 FHD frames,
24 sequences, 6,168 checks, zero failures. The runtime GIF, every consecutive
front/back phase montage and day/night nearest-3x crops were inspected for
proportions, separate boots and loop continuity. Captures remain local,
excluded from Git and editor import. UTF-8 gallery text is preserved.

Full-game FHD screenshots for noon, dusk, wave, result, tech and house_interior
were opened in implementation/shots/sprites/fhd-walk-heads/. Full verify/export:
55 passed, zero skipped/failed, 510s (over the 300s soft target); 125 parsed
scripts, 7,768 core assertions and 1,006 input cases. Sim/data hashes remain
1270427719 / 8148086. Evidence: walk-head-verify.log, walk-head-check.log,
walk-head-source.log, walk-head-import.log, walk-head-preview-capture.log,
walk-head-runtime-capture.log, walk-head-encode.log and walk-head-shots.log.
Sprite queue check remains PASS for twenty completed prompts.

The existing integration authorization persists; walking remains pending user
visual validation. During this work the user again rejected lateral RUN, so its
next revision is separate from this completed head correction. No RUN drawing
was changed in this commit. Unrelated pilot files stay outside the commit.
No push, automation or core/control/movement change was made.

## 2026-10-03 — Follow-up: readable anatomical leg recovery in lateral RUN

The user again rejected lateral running after 80d269e6: it still looked like
only one leg stayed forward. That baseline passed anchor-knee tests, but its
phase-3 bright trouser connected to the dark foreground boot, contact sleeves
barely alternated and the far front boot was too bright to distinguish support.
The completed front/back WALK head correction c876a33 is preserved.

Built-in ImageGen, using the actual sprite-sheet-creator run prompt and existing
farmer references, produced creator-run-leg-swing-keys-r1/r2/r3.png and
creator-run-leg-swing-transitions-r1/r2.png under
assets/art_source/player-fhd/directional/. Exact submitted prompts, original
output paths, reference roles and selection/rejection decisions are saved in
directional/prompts/creator-run-leg-swing-*.*. Key r1 repeated sleeves; r2 still
misassigned a passing trouser/boot. Select only r3 source cells 0/2/3 as phases
0/4/6. Its cell 1 is rejected; phase 2 remains byte-identical to the coherent
existing creator-run-two-leg-keys-r2 cell 1. Transition r1 also misassigned the
phase-3 trouser; r2 corrects that connection and supplies phases 1/3/5/7.
This is three targeted key revisions and two transition revisions. No native
sprite was painted and no intermediate pose was procedurally invented.

Partial source selection now measures scale and row ground from the complete
four-cell family before choosing output cells, preserving the old passing pose.
The existing lateral boot material ramp explicitly covers these new sources;
without it, generic nearest-palette conversion incorrectly made boots gold.
Fourteen native/runtime PNGs changed; two phase-2 poses and all 270 remaining
native frames are byte-identical to c876a33. Eight frames per direction,
96x96 canvas, existing pivots, 0.5 draw scale and 120px FHD body height remain.

All previous anchor-knee, boot material, contact/flight, unique lower-body and
walking-head guards remain. The additional recovery/sleeve/contact guard rejects
the actual reported baseline. In both directions, phase-3 recovery improves
from 1.03 to 5.72 native pixels, opposite contact sleeve movement from -0.12 to
5.38; contact boot contrast is now 105.48/102.12 instead of 94.89/51.99.
check_run_leg_swing.py and run-leg-swing-regression.json record the negative
control, both passing loops and unchanged-art checks. Tests support structural
consistency; subjective motion remains pending user validation.

Actual Godot preview captured 192 RUN frames at 25fps. Normal before/after
comparison uses 80d269e6 and matched clocks, 7.68s; the slow GIF uses the same
frames at 80ms, 15.36s, without interpolation. The same index.html has normal
and slow comparison links, preserved UTF-8 text and new RUN hash f36eae092348.
Its RUN selection and screenshot were checked in the existing browser tab.
The gallery overview remains 61.44s and the fifteen other action GIFs are
unchanged. Selected native nearest-3x strip was visually inspected.

Production World/PlayerView with 30Hz Player.tick captured 24 day/night
sequences, 1,536 FHD frames and 6,168 checks, zero failures. Consecutive RUN
phase montages, normal-cadence playback and day/night nearest-3x crops were
inspected for continuous trouser-to-boot ownership, alternating supports/arms
and loop continuity. Phases 2/6 clear the ground by three native pixels;
intermediate phases 3/7 clear it by one, retaining quantized eight-frame motion.
All six full-game FHD stills were opened in
implementation/shots/sprites/fhd-run-leg-swing/: noon, dusk, wave, result, tech,
house_interior. Original timed capture trees remain local and excluded from Git.

Full tools/verify.py passed 55 checks, zero skipped/failed, 518s (above the
300s soft target), including 125 parsed scripts, 7,768 core assertions,
1,006 input cases and exports. Sim/data hashes remain 1270427719 / 8148086.
Evidence is directional/run-leg-swing-{source,promotion,import,godot-import,
check,preview-capture,runtime-capture,encode,shots,verify}.log.
Both journals are appended; queues remain 110 game and 20 sprite tasks complete.
Existing integration authorization is used; no new approval is inferred.
No core, controls, movement speed, project resolution, push or automation change.
Unrelated pilot and import sidecar files remain outside this focused commit.

## 2026-10-03 — Follow-up: match the reported front WALK body to idle

The two user screenshots identified a remaining size mismatch. Masked pixel
matching against actual 9c2e51ec production frames identifies idle_south_1 and
walk_south_4; reported-size-diagnostic.json preserves the matches and source
anatomy. Their head widths were already 43/42 and heights 60/59 native pixels.
The walking upper body, including sleeves/hands, was 40 pixels wide versus idle
34–35, about 14% wider; chest width alone and total height missed this drift.

One targeted built-in ImageGen edit uses the current walking sheet as edit
target and the exact approved idle as identity/proportion reference. Source:
assets/art_source/player-fhd/directional/walk_south-body-r1.png. Prompt and call
metadata: directional/prompts/walk_south-body-r1.*. Original generated output:
C:/Users/Helel/.codex/generated_images/01a0f7e5-4a37-7612-b3d9-590f2b3bfba5/exec-b71fded5-ebcc-461c-ae65-412d3b413e60.png.
No native pixels were painted, no whole-sprite stretch was introduced and the
approved idle remains unchanged. Generated legs retain eight distinct phases;
the lower bodies of the regenerated sheet are not claimed byte-identical.

New eight-frame front walking has upper-body width 33–34, blue chest 15–16,
head width 42, brim 38, visible height 59–60. Shoulder offset is 29–30 versus
idle 30–31: one passing pose remains one pixel outside the idle range, within
the single-pixel animation tolerance. Build and promotion now check torso/arm
width and shoulder proportion as well as all previous head, native scale,
leg/boot, contact, palette, ownership and lateral RUN guards. The regression
helper rejects all eight actual old broad poses and verifies all 276 unrelated
native frames are byte-identical to 9c2e51ec, including every RUN and the other
three WALK directions. Runtime importer reports 512 outputs, exactly eight
rewritten. Fifteen other action GIFs are byte-identical. Existing 96x96 canvas,
ground pivot and 0.5 draw scale remain unchanged.

Actual preview captured 192 IDLE and 192 WALK frames at 25fps. Production
World/PlayerView with real 30Hz Player.tick captured 1,536 FHD frames over
24 day/night sequences, 6,168 checks, zero failures. Native contact strip,
consecutive day/night phase montages and nearest-3x runtime crops were opened.
The normal-speed idle/before/after production GIF uses saved baseline renderer
frames and current exact-size crops; 768x232, 192 frames, 7.68s, without motion
interpolation or sprite rescaling. Comparison still and explicit nearest-3x
magnification were inspected. All six full FHD screenshots were opened under
implementation/shots/sprites/fhd-walk-body/. An initial legacy-size capture was
replaced by the required --fhd capture; final files are 1920x1080.

The same HTML includes the new size comparison link and current WALK GIF hash
88c114e1e239. Its fresh WALK selection and screenshot were checked in the
existing browser tab. Sources/prompts, diagnostic, anatomy regression and
comparison helpers are saved for reproduction. Original timed captures remain
local, excluded from Git. Integration uses existing user authorization, while
subjective visual validation remains pending. Queues remain 110 game and
20 sprite tasks complete. No core, speed, camera, resolution or controls changed.
The pre-existing project.godot input-event serialization remains outside this
commit, along with unrelated pilot/import sidecars. No push or automation.


Full tools/verify.py: 55 passed, zero skipped/failed, 623s (above the 300s soft
budget), including 125 parsed scripts, 7,768 core assertions, 1,006 input cases
and both exports. Sim/data hashes remain 1270427719 / 8148086. Evidence logs:
directional/walk-body-{diagnostic,source,promotion,import,godot-import,qa-import,
check,preview-capture,runtime-capture,encode,comparison,shots,verify}.log.
Sprite queue and final journal checks also pass; no queue statuses changed.


## 2026-10-04 — Preview: original farmer and clothing-layer direction

The user requested a Stardew Valley-like original character and asked whether
each clothing item needs sprites. One built-in ImageGen design pilot is saved
at assets/art_source/player-fhd/pilots/2026-10-04/character-r1.png; exact prompt,
call provenance and layering notes are in implementation/fhd-player/pilots/2026-10-04/.
The inspected source is RGBA 1086x1448 with transparency. It is a large visual
master, not a verified native 48px sprite or a runtime replacement. Native-grid
conversion, animation and wearable layers are not claimed complete. The current
Body Sprite2D uses one complete texture per pose; distinct clothes would need
aligned layers, with palette reuse for colour variants and per-pose occlusion.
No game code, runtime art or manifests changed. This isolated preview was
visually inspected and checked for PNG/alpha integrity; no game test suite or
export was rerun. Existing project.godot changes remain untouched. Queues remain
complete, and the pilot is not recorded as new finished sprite production.

## 2026-10-04 — Approved new farmer: one walk-down review pilot

The user approved character-r1 and requested one walking movement for review
before an eight-direction set. Read the rotation, anatomical leg-color guides,
tracking preview and material restoration workflow in the external
C:/Users/Helel/Documents/repos/sprite_generator project. Implemented walk-down
only: eight ImageGen poses with fixed red/cyan anatomical leg ownership, followed
by one material-restoration call. Both raw sheets, exact prompts and provenance
are retained under assets/art_source/player-fhd/pilots/2026-10-04/walk-down and
implementation/fhd-player/pilots/2026-10-04/walk-down respectively.

Deterministic export uses hard alpha and nearest sampling, one scale for the
entire movement, hat-centered horizontal alignment and a common head top. The
80x80 frames contain a 62-64px-tall walking farmer beside the 64px idle; hat width
is 31-32px versus idle 31px. Proposed FHD display uses integer 2x, about 128px
standing height. Saved normal-speed horizontal idle/walk/detail GIF (8x100ms),
slow colored-leg comparison GIF, strip, individual frames and an HTML reviewer.
Confirmed eight distinct exported frames, genuine source alpha and GIF timing;
inspected both contact sheets and browser rendering. Both legs reach forward in
opposite half-cycles. Material recoloring retains 97.54% silhouette IoU; it is
not pixel-identical. Minor pixel/pose variation remains for user assessment;
no claim of perfect animation or in-game playback validation is made.

Local preview: http://127.0.0.1:8765/implementation/fhd-player/pilots/2026-10-04/walk-down/index.html.
The final movement is awaiting the explicit review requested by the user. Other
rotations/directions are planned, not generated. No runtime assets, game code,
queues or project.godot were modified; no game integration, game test suite or
export run was performed for this isolated approval pilot.


## 2026-10-04 — Walk-right review and user-directed leg-proportion correction

Recorded explicit walk-down approval ("lindo, perfeito") and the user's new
one-direction-at-a-time review requirement in the pilot directions-status.json.
Produced right only: a standing rotation, red/cyan anatomical walk construction,
material restoration and a head-proportion correction using built-in ImageGen.
The user then identified thinner/longer right-facing legs than approved down.
A targeted body revision, materials-r3.png, now uses the approved down sheet as
the direct body reference, adding thigh/shin volume and compact leg proportions.
All original sheets/prompts/provenance are preserved under the 2026-10-04 pilot.

Primary review is implementation/fhd-player/pilots/2026-10-04/walk-right/
down-right-comparison.gif plus index.html: unchanged approved down versus revised
right, same integer display scales (2x proposed FHD, 4x detail), 8 frames at10fps.
Source row split at y=498 avoids second-row hat tips crossing the nominal512px
boundary. Native right heights63-65px, hat widths30-31px; native down62-64px.
Reviewed original tracking chains and final pose sheet, native-size comparison,
and browser display. Lower-shin color measurements confirm both anatomical legs
pass forward and backward and opposite contacts exchange positions. That check
applies to the original colored source, not a guarantee of the revised anatomy.
Eight exported RGBA frames are distinct; saved GIF timing is8x100ms. Material
restoration is not pixel-identical (initial silhouette IoU0.94333), and subsequent
head/body revisions intentionally change shapes. Minor per-frame pixel/height
variation remains; no claim of perfect anatomy or runtime validation is made.

Selected right candidate remains awaiting explicit user approval. The initial
right idle is a direction reference, not an approved replacement idle. Remaining
six directions are not started. No runtime sprites, game code, manifests, queues
or project.godot changed; no engine suite/export rerun for this isolated preview.


## 2026-10-04 — Approved right; next direction is walk up

The user approved corrected right ("perfeito, proximo"). Recorded this approval
and produced UP only, keeping the user's one-direction-at-a-time review policy.
Built-in ImageGen created a rear standing master from a deterministic first-cell
crop of approved down, then an eight-frame colored-leg source. First source had
nearly frozen arms; a targeted second source fixes counter-swing before the third
animation call restores denim materials. Rear-view anatomical right/red stays
screen-right, left/cyan stays screen-left. Both knees and brown boots recover
in opposite half-cycles; upper-body/head direction remains back-facing.

Sources: assets/art_source/player-fhd/pilots/2026-10-04/walk-up/. Exact prompts,
raw-call provenance, anatomy-guide code and repeatable exports are in
implementation/fhd-player/pilots/2026-10-04/walk-up/. Eight80x80 RGBA frames,
transparent strip, idle/walk GIF, slow diagnostic comparison, contact sheet and
HTML review are saved. Primary down-up-comparison.gif shows unchanged approved
down and candidate up at matching integer2x proposed FHD display and4x detail.
Native up heights64-65px, all hat regions32px wide, same as rear idle; approved
down heights62-64px. Inspected source, complete contact sheet, equal-scale poster
and browser display. Eight distinct exports and8x100ms GIF timing pass. Sources
have genuine alpha; nominal512px row cut falls inside an empty gutter. Material
restoration is not pixel-identical (silhouette IoU0.91568); minor pixel/pose
variation remains for user assessment, with no perfect-anatomy claim.

UP now awaits explicit user approval. Left and four diagonals are not started.
No runtime assets, game rules, production manifests or queues changed. The prior
project.godot edit remains untouched. No engine suite/export was rerun for this
isolated approval preview, and no in-game validation is claimed.


## 2026-10-04 — Approved up; next direction is walk left

The user approved UP ("perfeito, proximo"). Recorded this approval and produced
LEFT only, preserving the one-direction-at-a-time approval policy. Followed the
sprite_generator hero plan's directional reflection shortcut for walks without
handed tools. Built-in ImageGen edits approved right materials-r3 per cell;
no code-drawn replacement artwork or Python creative reflection is used. First
candidate changed some limb phases and was rejected internally. Targeted R2
corrects both knee/boot recoveries and opposing contacts while retaining full,
compact trouser legs. Arms exchange across the cycle; near arm starts forward
one frame later than right, so generated reflection is not pixel-identical.

Raw sources: assets/art_source/player-fhd/pilots/2026-10-04/walk-left/.
Exact prompts, provenance and deterministic export code:
implementation/fhd-player/pilots/2026-10-04/walk-left/. Main horizontal preview
right-left-comparison.gif shows approved right and candidate left at matching
integer 2x proposed FHD display and 4x detail. Saved eight 80x80 RGBA frames,
transparent strip, slow comparison GIF, contact sheet and HTML frame controls.
Native heights 63-65px; hat widths 30-31px, matching approved right's range.
One common export scale and fixed hat anchors apply to all frames. Genuine
source alpha checked; row cut y498 lies in the empty y480-506 gutter.

Validation: eight distinct frame hashes, 8x100ms main GIF and 8x200ms slow GIF
pass. Inspected raw sources, all eight native-derived poses, same-scale poster
and browser display; HTML Next advances Frame 1 to Frame 2. Left awaits explicit
user approval. Four diagonals remain. No runtime assets, game code or queue
statuses changed. Unrelated project.godot edit remains untouched. No engine
suite/export rerun for this isolated approval pilot; no in-game playback claimed.


## 2026-10-04 — Approved left; corrected walk down-right for review

The user approved LEFT ("perfeito, proximo"). Produced DOWN-RIGHT only using
built-in ImageGen, preserving the one-direction approval policy. Established a
standing diagonal master from approved down/right first-cell crops. Earlier
full-atlas tracking/recolor attempts repeated the foreground leg silhouette;
the user rejected these during work three times. Colored endpoint displacement
alone passed while ownership was wrong, so those checks were not treated as
approval. Saved all rejected sources and prompts. Explicit user corrections
required further targeted revisions beyond the initial atlas attempts.

Applied sprite_generator/welcome_back_hero/prepare_ranger_transition.py's
contact-anchor workflow: created one isolated opposite contact with near thigh
back left and far thigh forward right, then two four-frame transitions. First
B half invented an extra shin; targeted B-R2 removed it and restored arm
counter-swing. pack_transitions.py losslessly cuts/packs A-R1 and B-R2 into
tracking-r4 (2508x1254), without repainting/reflection/rescaling. Selected
materials-r2 restores consistent lighter near denim, shadowed far denim and
brown boots, with uniform head-size calibration. Generated canvas1774x887 is
cut using rounded quarters/halves inside transparent gutters. Sources live at
assets/art_source/player-fhd/pilots/2026-10-04/walk-down-right/. Prompts, call
provenance, skeleton guides and repeatable exports live at
implementation/fhd-player/pilots/2026-10-04/walk-down-right/.

Eight native 80x80 frames, transparent strip, contact sheet, idle/walk GIF,
colored-leg slow GIF and HTML controls saved. Main horizontal
down-diagonal-comparison.gif compares unchanged approved down and corrected
candidate at integer 2x proposed FHD display and 4x detail. Native heights
62-65px, hats31-32px, standing diagonal hat31px. One common scale per source
family across all poses, hard alpha128 and nearest sampling. R4 color checks
cover opposite diagonal displacements, both recovery poses3/7 and separate
forward-foot positions at contacts1/5 (36.84px separation normalized to384px
cell width). These are review aids, not proof of perfect anatomical motion.
Material/head changes are not pixel-identical: native silhouette IoU0.81532.

Validation: eight unique frame hashes, all three GIFs eight frames with expected
100/100/200ms timing. Inspected complete contact sheet, equal-scale poster,
corrected limb chains and browser playback. HTML Next reaches Frame5; slow
comparison is available beside normal material. Corrected DOWN-RIGHT awaits
explicit approval; up-right, up-left and down-left remain. No runtime assets,
engine code or queue status changed; unrelated project.godot edit preserved.
No engine suite/export rerun for this isolated art pilot, no in-game claim.


## 2026-10-04 — Horizontal preview of all current farmer walks

The user requested one horizontal GIF with everything created so far in the
current directional walk review. Composed unchanged native frames for down,
right, up, left and latest corrected down-right in one row at matching integer
2x display, eight100ms frames (10fps), looping. Saved
implementation/fhd-player/pilots/2026-10-04/all-walk-directions.gif, poster,
build_all_directions_preview.py and input-hash validation JSON. Shared palette
and nearest sampling retain crisp display. Inspected the full horizontal poster;
verified five80x80 input families, output1040x330, eightframes,100ms cadence and
infinite loop. Down-right remains awaiting approval, labeled IN REVIEW; the
other four stay APPROVED. No new art generated, native frames edited, direction
approvals inferred or subsequent directions started. No runtime/queue changes;
project.godot edit remains untouched. No engine suite was rerun for GIF assembly.


## 2026-10-04 — Slimmer down-right body review

The user reported that down-right looked chubbier than the approved original.
Built-in ImageGen edited only this direction using selected materials-r2 plus
approved down as the body-build reference. Preserved raw materials-r3 source,
exact prompt and provenance; superseded R2 remains archived. Slimmed torso,
hips and leg contours, retained opposite contact poses1/5 and recovery poses3/7
on visual inspection of all eight native frames. Shared nearest-sampling scale
produces80x80 canvases, visible heights63-65px and hats31-33px. Head contours
are not pixel-identical to R2: widths differ by up to one native pixel.
Blue-clothing count in native rows32-42 averages86.75 instead of97.0, against
82.625 in approved down; pose/occlusion make this only a review aid.

Rebuilt selected frames, strip, individual GIFs, equal-scale down comparison,
posters, HTML with revision cache keys, and the five-direction horizontal GIF.
Added all-walk-directions-slimmer-down-right.gif for fresh inline review. Export
and comparison builders passed; checked eight unique frames,100ms loop timing,
full contact sheet and equal-scale poster. Other four approved walk families
remain unchanged. Down-right still awaits explicit approval; no subsequent
direction started and no runtime, queue or project settings changed. Existing
project.godot edit preserved; no engine test rerun for isolated art previews.
