extends SceneTree

## The rules, asserted with no window.
##
## Run by `python tools/verify.py`. The last line it prints is
## `N asserts, M failed`, and it exits non-zero when M is not zero.
##
## Every rule the backlog adds gets its asserts here in the same pass that adds
## the rule, grouped by the task that introduced them - so a failure says which
## piece of design just moved. **Adding a group means bumping `GROUPS`.**
##
## ## Failing rather than hanging
##
## GDScript has no exceptions. A runtime error does not stop the program: it
## prints, abandons the function it happened in, and returns to the caller. A
## check that dies half way would therefore reach the end of this file with a
## clean `0 failed` and report success for work it never did.
##
## Three things stop that, cheapest first:
##
## 1. Each group increments `_completed` **as its last statement**, so a group
##    that was abandoned mid-way never counts. `_finish()` fails when fewer
##    groups finished than `GROUPS` says exist.
## 2. `_process()` is a watchdog. It only runs when `_initialize()` never
##    returned at all - a parse error in something this file depends on - and it
##    ends the main loop rather than letting the SceneTree idle for ever.
## 3. `verify.py` bounds the whole run with a timeout, as the belt to these
##    braces, and runs `--check-only` over every script before this one starts.

## How long to wait before deciding `_initialize()` is never coming back.
## The whole check takes about a third of a second, so this is ample.
const WATCHDOG_SECONDS := 5.0

## How many `_task_NNNN_*` groups `_run()` is expected to finish.
const GROUPS := 2

var passed := 0
var failed := 0

var _completed := 0
var _finished := false
var _elapsed := 0.0


func _initialize() -> void:
	_run()
	_finish()


## Reached only when `_initialize()` did not return - which in practice means a
## parse error in a script this one depends on, so `_run()` never started.
func _process(delta: float) -> bool:
	_elapsed += delta
	if _elapsed < WATCHDOG_SECONDS:
		return false
	push_error("headless_check: watchdog fired after %.0fs" % _elapsed)
	print("WATCHDOG: _initialize() never returned. Something it depends on ",
		"failed to parse - run: godot --headless --path . --check-only ",
		"--script res://src/tools/headless_check.gd")
	_finish()
	return true


func _run() -> void:
	_task_0002_tick_and_rng()
	_task_0003_game_data()


func _finish() -> void:
	if _finished:
		return
	_finished = true
	if _completed < GROUPS:
		failed += 1
		print("  FAIL  a check group did not finish   %d of %d completed"
			% [_completed, GROUPS])
	print("%d asserts, %d failed" % [passed + failed, failed])
	quit(1 if failed > 0 else 0)


## One assertion. A failure prints the values, because "false" on its own has
## never once been enough to fix anything.
func expect(ok: bool, what: String, detail: String = "") -> void:
	if ok:
		passed += 1
	else:
		failed += 1
		print("  FAIL  ", what, "  ", detail)


## 0002 - the fixed timestep, the seeded stream and the state hash.
func _task_0002_tick_and_rng() -> void:
	# The same seed, ten thousand ticks, twice.
	var a := State.create(1234)
	var b := State.create(1234)
	Sim.advance(a, 10000)
	Sim.advance(b, 10000)
	var ha := State.hash_of(a)
	var hb := State.hash_of(b)
	expect(ha == hb, "10000 ticks from one seed replay identically",
		"%d vs %d" % [ha, hb])
	expect(int(a["tick"]) == 10000, "the tick count is the ticks asked for",
		str(a["tick"]))
	print("  hash of 10000 ticks @ seed 1234: ", ha)

	# A different seed must not land on the same state.
	var c := State.create(1235)
	Sim.advance(c, 10000)
	expect(State.hash_of(c) != ha, "a different seed diverges")

	# A draw advances the stream the state carries.
	var d := State.create(7)
	var first: Array = []
	for _i in 50:
		first.append(Rng.int_between(d["rng"], 1, 100))
	var e := State.create(7)
	var second: Array = []
	for _i in 50:
		second.append(Rng.int_between(e["rng"], 1, 100))
	expect(first == second, "the RNG stream replays from a seed")

	var lo := 101
	var hi := 0
	for v in first:
		lo = mini(lo, v)
		hi = maxi(hi, v)
	expect(lo >= 1 and hi <= 100, "int_between stays inside its bounds",
		"%d..%d" % [lo, hi])
	expect(lo <= 10 and hi >= 90, "int_between reaches both ends",
		"%d..%d" % [lo, hi])

	# Saving and restoring the stream resumes it exactly: this is the property
	# that lets a save reload mid-night and finish the night the same way.
	var f := State.create(99)
	Sim.advance(f, 100)
	for _i in 10:
		Rng.next_u32(f["rng"])
	var snapshot := State.copy(f)
	var after_a: Array = []
	for _i in 20:
		after_a.append(Rng.next_u32(f["rng"]))
	var after_b: Array = []
	for _i in 20:
		after_b.append(Rng.next_u32(snapshot["rng"]))
	expect(after_a == after_b, "a restored state resumes the same stream")

	# A deep copy cannot be moved by simulating the original - what the "what
	# if I put the tower here" preview will depend on.
	var g := State.create(5)
	var frozen := State.copy(g)
	var frozen_hash := State.hash_of(frozen)
	Sim.advance(g, 500)
	expect(State.hash_of(frozen) == frozen_hash, "a copy is independent")

	# The frame accumulator never produces a partial tick and never spirals.
	var acc := 0.0
	var total := 0
	for _i in 600:                      # ten seconds of 60fps frames
		var owed: Array = Sim.ticks_for(acc, 1.0 / 60.0)
		total += int(owed[0])
		acc = owed[1]
	expect(total == 300, "60fps for 10s owes exactly 300 ticks", str(total))

	var fast := 0
	acc = 0.0
	for _i in 1440:                     # the same ten seconds at 144fps
		var owed: Array = Sim.ticks_for(acc, 1.0 / 144.0)
		fast += int(owed[0])
		acc = owed[1]
	expect(absi(fast - 300) <= 1, "144fps owes the same ticks as 60fps",
		str(fast))

	var stall: Array = Sim.ticks_for(0.0, 30.0)     # a thirty second freeze
	expect(int(stall[0]) == GameData.MAX_CATCH_UP_TICKS,
		"a long stall is capped, not paid", str(stall[0]))
	expect(float(stall[1]) == 0.0, "the dropped backlog is not banked",
		str(stall[1]))

	var tiny: Array = Sim.ticks_for(0.0, 0.001)
	expect(int(tiny[0]) == 0 and float(tiny[1]) > 0.0,
		"a short frame owes no tick and carries the remainder")

	_completed += 1     # last line: an abandoned group never gets here


## 0003 - the lever file: every cross-reference resolves, and the validator
## that says so is itself shown to fail when it should.
func _task_0003_game_data() -> void:
	var errors: Array = GameData.validate()
	expect(errors.is_empty(), "GameData.validate() is clean",
		"; ".join(PackedStringArray(errors)))

	# **The validator has to be seen failing.** One that has never caught
	# anything is one nobody should trust, so it is handed a recipe pointing at
	# a resource that does not exist and asked to name it.
	var broken: Dictionary = {
		&"bad_recipe": {
			"station": &"workshop",
			"inputs": {&"unobtainium": 1},
			"output": {GameData.WOOD: 1},
			"ticks": 30,
		},
	}
	var caught: Array = GameData.check_recipes(broken)
	expect(caught.size() == 1, "a bad recipe input is caught", str(caught))
	expect(caught.size() > 0 and str(caught[0]).contains("unobtainium"),
		"the error names the offending id", str(caught))

	var bad_station: Array = GameData.check_recipes({
		&"homeless": {
			"station": &"nowhere",
			"inputs": {GameData.WOOD: 1},
			"output": {GameData.FOOD: 1},
			"ticks": 30,
		},
	})
	expect(bad_station.size() == 1 and str(bad_station[0]).contains("nowhere"),
		"a recipe at an unknown station is caught", str(bad_station))

	var bad_night: Array = GameData.check_nights([[[&"vampire", 3, 0, 0]]])
	expect(bad_night.size() >= 1 and str(bad_night[0]).contains("vampire"),
		"an unknown enemy in a wave is caught", str(bad_night))

	# Every resource the reference sheet shows is here, and every sellable one
	# has a price.
	expect(GameData.RESOURCES.size() == 13, "thirteen resources",
		str(GameData.RESOURCES.size()))
	for res in GameData.SELL_PRICE:
		expect(GameData.RESOURCES.has(res), "a priced thing is a resource",
			str(res))

	# Ten nights, per design.md, and each one has at least one wave.
	expect(GameData.NIGHTS.size() == GameData.MVP_NIGHTS, "ten nights",
		str(GameData.NIGHTS.size()))
	for n in GameData.NIGHTS.size():
		expect((GameData.NIGHTS[n] as Array).size() > 0,
			"night %d has waves" % (n + 1))

	# The Giant only shows up on the last one: it is the test of the build, not
	# a thing that wanders in on night 4.
	var giant_nights: Array = []
	for n in GameData.NIGHTS.size():
		for wave in (GameData.NIGHTS[n] as Array):
			if wave[0] == &"giant" and not giant_nights.has(n + 1):
				giant_nights.append(n + 1)
	expect(giant_nights == [10], "the Giant is night 10 and nowhere else",
		str(giant_nights))

	# Buying a material is always worse than going and getting it, at every
	# price, or money quietly replaces playing the game.
	for res in GameData.SELL_PRICE:
		var sell: int = GameData.SELL_PRICE[res]
		var buy: float = float(sell) * GameData.BUY_MARKUP
		expect(buy > float(sell), "buying %s costs more than selling it" % res,
			"%d sell, %.1f buy" % [sell, buy])

	# A crop must be worth more harvested than its seed cost, or nobody plants
	# it twice.
	for crop_id in GameData.CROPS:
		var crop: Dictionary = GameData.CROPS[crop_id]
		var revenue: int = int(crop["yield"]) * int(GameData.SELL_PRICE[crop_id])
		expect(revenue > int(crop["seed_cost"]),
			"%s pays for its own seed" % crop_id,
			"%d seed, %d harvest" % [crop["seed_cost"], revenue])

	# Dusk falls inside the day.
	expect(GameData.DUSK_AT_TICK < GameData.DAY_TICKS, "dusk is before night")

	_completed += 1     # last line: an abandoned group never gets here
