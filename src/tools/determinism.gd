extends SceneTree

## The scripted scenario behind the hash guards.
##
## Prints two integers and nothing else that looks like one:
##
##     SIM <n>     the state after a fixed scenario of a fixed length
##     DATA <n>    every balance table in GameData, folded
##
## `tools/verify.py` compares each against its baseline file and fails when one
## moved. Moving one on purpose is `python tools/verify.py --accept`, which
## prints the old and the new number so the journal can record both.
##
## **Two numbers because they answer two questions.** SIM asks whether the
## rules still do the same thing from the same seed; DATA asks whether the
## design is still the design.
##
## **SIM is the whole journey, not the destination.** It folds the state every
## `SAMPLE_EVERY` ticks rather than hashing it once at the end, because a
## scenario run to a standstill hashes a standstill: task 0037 made the
## workshop queue advance twice as fast, deliberately, and the end-of-run hash
## did not move by a digit - three kits are three kits whether they took ten
## seconds or twenty. Anything that changes *when* things happen now moves this
## number, which is most of what the rules are. A task that ports code without changing
## behaviour must move neither. A balance pass moves DATA and says so. A new
## system that consumes randomness moves SIM and says so.
##
## The scenario is deliberately boring: create a state from one seed and
## advance it. Every system the backlog adds ticks inside `Sim.tick()`, so each
## one starts being covered the moment it lands, without this file changing.
## When a system needs setting up to be exercised - a farm with crops in it, a
## night with zombies walking - the setup goes here, above the advance.

const SCENARIO_SEED := 424242
const SCENARIO_TICKS := 20000

## How often the state is folded into the running hash. Small enough to catch
## a change of a few ticks in when something happens, large enough that the
## guard costs a fraction of a second.
const SAMPLE_EVERY := 250

## Bounded like `headless_check` is, and for the same reason: a tool script
## that errors leaves the SceneTree running rather than exiting.
const WATCHDOG_SECONDS := 10.0

var _finished := false
var _reached_end := false
var _elapsed := 0.0


func _initialize() -> void:
	_run()
	_finish()


func _process(delta: float) -> bool:
	_elapsed += delta
	if _elapsed < WATCHDOG_SECONDS:
		return false
	push_error("determinism: watchdog fired after %.0fs" % _elapsed)
	_finish()
	return true


func _run() -> void:
	var state := State.create(SCENARIO_SEED)
	_set_the_farm_going(state)

	# **Walk the whole loop**, so that the guard covers the phase machine and
	# everything the backlog later hangs off each phase, rather than only the
	# bare tick. The numbers below are part of the scenario: changing one moves
	# the sim hash, which is fine as long as the journal says why.
	var rolling := _sample(0, state)
	rolling = _advance_sampling(state, 1500, rolling)   # a morning on the farm

	# **A visit to the stall**, because the shop stops the clock (task 0039)
	# and a rule nothing in the scenario exercises is a rule the guard cannot
	# see. This is the same reason the farmer plants and queues above.
	Shop.open(state)
	rolling = _advance_sampling(state, 500, rolling)
	Shop.close(state)

	rolling = _advance_sampling(state, 1500, rolling)   # and the afternoon
	NightRoad.into_build(state)
	_arm_the_farm(state)        # the defences go up in the build step
	# START (task 0136): the build step waits for it, one tick instead of 600.
	NightRoad.press_start(state)
	rolling = _advance_sampling(state, NightRoad.build_ticks_left(state),
		rolling)
	# **A night fought until it ends itself** (task 0137): everything killed,
	# or dawn, or the house - never `enter_result` by hand.
	var fought := 0
	while int(state["phase"]) == Phases.NIGHT and fought < Sim.MOST_TICKS_IN_A_NIGHT:
		rolling = _advance_sampling(state, SAMPLE_EVERY, rolling)
		fought += SAMPLE_EVERY
	rolling = _advance_sampling(state, 200, rolling)    # the payout on screen
	Phases.begin_day(state)
	# Up beside his bed (task 0138) and out of the door into the second day.
	House.leave(state)

	var spent: int = int(state["tick"])
	rolling = _advance_sampling(state, SCENARIO_TICKS - spent, rolling)

	print("SIM ", rolling)
	print("DATA ", GameData.digest())
	_reached_end = true          # last line: an abandoned run never gets here


## Advance `ticks`, folding the state in every `SAMPLE_EVERY` of them.
static func _advance_sampling(state: Dictionary, ticks: int,
		rolling: int) -> int:
	var left := ticks
	while left > 0:
		var step := mini(left, SAMPLE_EVERY)
		Sim.advance(state, step)
		left -= step
		rolling = _sample(rolling, state)
	return rolling


## Fold one state into the running number. FNV-1a over the two, the same shape
## as `State.hash_of` itself.
static func _sample(rolling: int, state: Dictionary) -> int:
	var h := rolling ^ State.hash_of(state)
	h = (h * 16777619) & 0xFFFFFFFF
	return h


## Put the farm to work before the clock starts.
##
## **A scenario where the player does nothing guards almost nothing.** Until
## task 0037 this file created a state and advanced it, which covered the phase
## machine, the waves, the animals and the power - everything that ticks on its
## own - and covered none of the systems that need somebody to press a key.
## Crafting was rewritten from one job per station into a queue and the sim
## hash did not move by a digit, which is not reassurance, it is a gap.
##
## So the farmer plants, queues, builds and casts, once, here. Everything below
## is part of the scenario: changing any of it moves the sim hash, which is
## fine as long as the journal says why.
func _set_the_farm_going(state: Dictionary) -> void:
	# Enough of everything to pay for what follows, so that the scenario is
	# about the rules rather than about the starting purse.
	Resources.gain(state, {
		GameData.WOOD: 300, GameData.STONE: 300, GameData.IRON: 300,
		GameData.MONEY: 300, GameData.OIL: 60, GameData.CORN: 60,
		GameData.GUNPOWDER: 60, GameData.INCENDIARY: 60,
	})

	# **A field with three different crops in it**, so growth, stages and the
	# watering of task 0029 all have something to work on.
	var seeds := Farming.seeds()
	var sown := 0
	for found in Farm.cells_of(state, Farm.Terrain.SOIL):
		var cell: Vector2i = found
		if sown >= 9:
			break
		Farming.select_seed(state, StringName(seeds[sown % seeds.size()]))
		Farming.act(state, cell)            # till
		Farming.act(state, cell)            # plant
		sown += 1
	# Half of them watered, so the soak arithmetic is in the hash too.
	state["water_can"] = GameData.WATER_CAN_CAPACITY
	var watered := 0
	for found in Farm.cells_of(state, Farm.Terrain.SOIL):
		var cell: Vector2i = found
		if watered >= 4:
			break
		if Farming.verb_at(state, cell) == &"water":
			Farming.act(state, cell)
			watered += 1

	# **A workshop with a queue on it**, which is what task 0037 added and what
	# nothing in here was watching.
	var benches := Farm.cells_with(state, &"workshop")
	if not benches.is_empty():
		var bench: Vector2i = Building.anchor_of(state, benches[0])
		for recipe in [&"barricade_kit", &"fence_kit", &"barricade_kit"]:
			Crafting.enqueue(state, bench, recipe)

	# **A line in the water**, so the fishing RNG is drawn from inside the
	# scenario rather than never at all.
	for found in Farm.cells_of(state, Farm.Terrain.WATER):
		var wet: Vector2i = found
		if Fishing.begin(state, wet):
			var who: Dictionary = state["player"]
			who["pos"] = [wet.x * Player.SUBTILE + Player.SUBTILE / 2,
				(wet.y - 1) * Player.SUBTILE + Player.SUBTILE / 2]
			break


## The towers and the wall, **in the build step** (task 0119): 0132 forbids
## defences by day, so the scenario puts them up where a player will.
func _arm_the_farm(state: Dictionary) -> void:
	# **Two towers**, so that the night is fought rather than merely survived,
	# and one of them draws ammunition from the pool.
	var guns := 0
	for y in [7, 9]:
		for x in range(22, 30):
			if guns >= 2:
				break
			if Building.place(state, &"gun_tower", Vector2i(x, y)):
				guns += 1
		if guns >= 2:
			break

	# **A short line of wall**, so the flow field is something other than open
	# ground. Walls are the only thing in the game that changes where the
	# zombies walk, and a scenario with none of them guards none of that.
	# Deliberately not a seal: a sealed farm is a different night, and the
	# chewing that answers it has its own asserts.
	var walled := 0
	for y in [6, 7, 8]:
		if walled >= 3:
			break
		if Building.place(state, &"wall", Vector2i(28, y)):
			walled += 1


func _finish() -> void:
	if _finished:
		return
	_finished = true
	if not _reached_end:
		print("the scenario did not finish - no number above is trustworthy")
		quit(1)
		return
	quit(0)
