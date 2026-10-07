class_name State
extends RefCounted

## The whole game, as plain data.
##
## `Dictionary` and `Array` of primitives, and nothing else. That is what lets
## it be deep-copied, hashed, written to a save file and diffed between two
## runs - and it is the reason `src/core/` may not hold a node. Put an object in
## here and the save, the hash guard and the autoplayer all stop working on the
## same afternoon.
##
## Keys are Strings. Access is `state["tick"]`, spelled out rather than
## `state.tick`, so a typo is a missing key at the call site instead of a silent
## new one.

## Bumped whenever the shape changes in a way `reconcile()` cannot mend.
##
## **Two version numbers, because there are two questions.**
## `Save.FORMAT_VERSION` is about the file - the magic, the header, how the
## bytes are encoded - and `VERSION` is about what is inside it. A new
## subsystem, a new resource or a new field on an existing one does not bump
## this: `reconcile()` fills those in from a new game, which is what the
## whole of `initial()` is for. What bumps it is a change no amount of
## filling in can express - a key that means something different than it used
## to, a number that changed units, two keys that became one. Then there is a
## migration under it, and `Save` runs them in order.
const VERSION := 4

## The nested dictionaries whose keys come from the code.
##
## `held` and `gained` are keyed by `GameData.RESOURCES`; the rest are
## structures with a fixed set of fields. Every key in one of these is a key
## this build decided on, so a save that is missing one is a save written
## before it existed and a save that has a spare one is a save written after
## it was taken away. Both are mended by looking at a new game.
const TABLES: Array = [
	"ability", "build", "gained", "held", "intent", "player", "power",
	"reaction", "selected_recipe", "stall", "stats", "tutorial", "wave", "house_visit",
]

## And the ones whose keys come from playing.
##
## **`occupants` is why this list is written down rather than worked out.**
## A new game starts with a hundred and six of them - the house, the trees,
## the workshop - so "it starts empty, therefore it is the player's" is a
## rule that would have thrown away every building in every save. What
## separates these is not how full they are, it is who put the keys there.
## Nothing in here is ever added to or taken from by `reconcile()`.
const RUN_DATA: Array = [
	"burning", "crafting", "entities", "fishing", "killed_by_kind",
	"killed_by_kind_all_run", "kits", "last_result", "livestock",
	"occupants", "payout", "plots", "produced", "repair_debt", "rubble",
]

const _FNV_OFFSET := 2166136261
const _FNV_PRIME := 16777619
const _MASK := 0xFFFFFFFF


## A new game.
##
## Each subsystem contributes the keys it owns through its own `initial()`, so
## that adding one is an edit in that file plus a line here, rather than a
## growing literal nobody can find their way around.
static func create(seed_value: int) -> Dictionary:
	var state := {
		"version": VERSION,
		"seed": seed_value,
		"tick": 0,
		"rng": Rng.create(seed_value),
	}
	_adopt(state, Phases.initial(), "Phases")
	_adopt(state, Resources.initial(), "Resources")
	_adopt(state, Farm.initial(), "Farm")
	_adopt(state, Player.initial(), "Player")
	_adopt(state, House.initial(), "House")
	_adopt(state, Gathering.initial(), "Gathering")
	_adopt(state, Farming.initial(), "Farming")
	_adopt(state, Crafting.initial(), "Crafting")
	_adopt(state, Building.initial(), "Building")
	_adopt(state, Entities.initial(), "Entities")
	_adopt(state, Towers.initial(), "Towers")
	_adopt(state, Pathing.initial(), "Pathing")
	_adopt(state, Enemies.initial(), "Enemies")
	_adopt(state, Combat.initial(), "Combat")
	_adopt(state, Traps.initial(), "Traps")
	_adopt(state, Tutorial.initial(), "Tutorial")
	_adopt(state, Shop.initial(), "Shop")
	_adopt(state, Livestock.initial(), "Livestock")
	_adopt(state, Power.initial(), "Power")
	_adopt(state, Fishing.initial(), "Fishing")
	_adopt(state, Waves.initial(), "Waves")
	_adopt(state, Rewards.initial(), "Rewards")
	_adopt(state, Ability.initial(), "Ability")
	_adopt(state, Repair.initial(), "Repair")
	_adopt(state, Tech.initial(), "Tech")
	_adopt(state, Run.initial(), "Run")
	_adopt(state, Stats.initial(), "Stats")
	_adopt(state, Events.initial(), "Events")
	_adopt(state, Reactions.initial(), "Reactions")
	return state


## Merge one subsystem's keys in, and **refuse a name that is already taken**.
##
## The state is one flat namespace shared by every subsystem, which is what
## makes it hashable, savable and diffable in one piece. The cost is that two
## subsystems can pick the same key - and `Dictionary.merge()` silently keeps
## one of them. Farming called its chosen crop `"seed"`, which was already the
## run's RNG seed; planting did nothing at all and the only symptom was a type
## error three files away.
static func _adopt(state: Dictionary, keys: Dictionary, owner: String) -> void:
	for key in keys:
		if state.has(key):
			push_error("State: %s wants the key '%s' and something already "
				% [owner, key] + "owns it. Pick another name.")
			continue
		state[key] = keys[key]


## A deep copy, safe to simulate forward without touching the original.
##
## What the "what if I placed it here" preview will run on, and what the
## headless tests compare against.
static func copy(state: Dictionary) -> Dictionary:
	return state.duplicate(true)


## One integer that stands for the entire state.
##
## The determinism guard is this number: two runs of the same seed that end with
## the same hash did the same thing, and a task that moves it changed a rule -
## deliberately, and recorded in the journal, or by accident, which is a bug.
## Bring a state from an older build up to this one's shape, in place.
##
## Returns a line per repair, oldest concern first, for the journal and for a
## check to read. An empty Array means it was already this shape - which is
## what a state written by this build always is, and which
## `headless_check` asserts, because a reconcile that quietly rewrites
## today's save would move the determinism hash on a machine and not on the
## one next to it.
##
## ## Two levels, and only two
##
## The top level, and one level inside each of `TABLES`. That is as deep as
## the shape is decided by the code: below it is the run - what is standing
## on which tile, which plot has what growing on it - and none of it is
## anybody's to fill in.
##
## ## A missing key takes the default, which is what a new game has
##
## Not zero. A player whose save predates oil gets the starting amount of it,
## because that is what the game gives somebody who starts today, and a run
## that never had the chance to gather a thing should not be punished for it.
static func reconcile(state: Dictionary) -> Array:
	var notes: Array = []
	if state.is_empty():
		return notes
	var fresh := create(int(state.get("seed", 0)))

	# **Sorted, both ways round.** Two builds reading the same old save have
	# to make the same repairs in the same order, or the first thing anybody
	# notices is the determinism guard moving on one machine only.
	for key in _sorted(fresh):
		if not state.has(key):
			state[key] = fresh[key]
			notes.append("filled in '%s', which this save predates" % key)
	for key in _sorted(state):
		if not fresh.has(key):
			state.erase(key)
			notes.append("dropped '%s', which this build no longer has" % key)

	for named in TABLES:
		if not state.has(named) or not (state[named] is Dictionary):
			continue
		var mine: Dictionary = state[named]
		var theirs: Dictionary = fresh[named]
		for key in _sorted(theirs):
			if not mine.has(key):
				mine[key] = theirs[key]
				notes.append("filled in '%s' in %s" % [str(key), named])
		for key in _sorted(mine):
			if not theirs.has(key):
				mine.erase(key)
				notes.append("dropped '%s' from %s" % [str(key), named])
	if House.repair_position(state):
		notes.append("moved indoor player off revised furniture")
	# A zombie on a sunny afternoon: a lost night used to leave its winners
	# in the yard until the same night came back.
	var withdrawn := Enemies.withdraw_in_daylight(state)
	if withdrawn > 0:
		notes.append("sent home %d zombies a lost night left in daylight"
			% withdrawn)
	return notes


## Every nested Dictionary in a state, named. The union of `TABLES` and
## `RUN_DATA` has to be exactly this, which `headless_check` asserts - a
## subsystem that adds one and says which it is gets reconciled or left
## alone on purpose, and one that says neither is a failing row.
static func nested_in(state: Dictionary) -> Array:
	var found: Array = []
	for key in state:
		if state[key] is Dictionary:
			found.append(str(key))
	found.sort()
	return found


## A Dictionary's keys, sorted, as Strings sort.
static func _sorted(from: Dictionary) -> Array:
	var keys: Array = []
	for key in from:
		keys.append(key)
	keys.sort()
	return keys


## The keys the hash does not look at.
##
## **One, and it is task 0109's bubble.** A reaction is a fact in the state so
## that the autoplayer and a replay see the same one at the same tick, and it
## is decoration: nothing reads it, nothing branches on it, and turning every
## one of them off has to leave this number where it was. The honest way to
## get that is not to be careful about it - it is for the hash never to have
## looked.
##
## Adding to this list is how a view-layer fact gets to live in the state
## without being part of the game, and it is not a thing to do lightly:
## `headless_check` asserts that nothing in `src/core/` outside
## `reactions.gd` so much as mentions the key.
const NOT_THE_GAME: Array = ["reaction"]


static func hash_of(state: Dictionary) -> int:
	var mine: Dictionary = state
	for key in NOT_THE_GAME:
		if state.has(key):
			# Copied only when there is something to leave out, because this
			# runs every few hundred ticks inside the determinism guard.
			mine = state.duplicate(false)
			break
	for key in NOT_THE_GAME:
		mine.erase(key)
	return _fold(_FNV_OFFSET, mine)


static func _fold(h: int, value: Variant) -> int:
	match typeof(value):
		TYPE_DICTIONARY:
			# **Sorted keys.** Dictionary iteration follows insertion order, so
			# two states that are equal in every value can still be built in
			# different orders. Sorting is what makes this a hash of the state
			# rather than a hash of how the state was assembled.
			#
			# **Sorted by their text**, because the keys here are a mix of ints
			# and StringNames and `Array.sort()` orders a StringName by its
			# internal pointer - that is, by the order the strings happened to
			# be interned in, which moves when somebody reorders two `const`
			# lines. A hash that depended on that would be a hash of the source
			# file's layout. Text order is not the prettiest total order - "10"
			# sorts before "2" - but it is the same one on every build, which
			# is the only property this needs.
			var d: Dictionary = value
			var keys: Array = []
			for k in d:
				keys.append([str(k), k])
			keys.sort()
			for pair in keys:
				var k: Variant = (pair as Array)[1]
				h = _fold(h, k)
				h = _fold(h, d[k])
		TYPE_ARRAY:
			# Arrays keep their order: in an array, order is data.
			for item in (value as Array):
				h = _fold(h, item)
		_:
			h = _bytes(h, str(value))
	return h


static func _bytes(h: int, s: String) -> int:
	for b in s.to_utf8_buffer():
		h = (h ^ b) & _MASK
		h = (h * _FNV_PRIME) & _MASK
	return h
