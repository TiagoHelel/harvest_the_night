extends SceneTree

## The rules, asserted with no window.
##
## Run by `python tools/verify.py`. The last line it prints is
## `N asserts, M failed`, and it exits non-zero when M is not zero.
##
## Every rule the backlog adds gets its asserts here in the same pass that adds
## the rule, grouped by the task that introduced them - so a failure says which
## piece of design just moved.
##
## **A script error before the final `quit()` leaves the SceneTree running
## forever** rather than failing: a headless check that hangs the loop instead
## of breaking it. `verify.py` bounds every Godot script with a timeout for
## exactly that reason, and task 0004 makes this file fail fast on its own.

var passed := 0
var failed := 0


func _initialize() -> void:
	_task_0002_tick_and_rng()

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
