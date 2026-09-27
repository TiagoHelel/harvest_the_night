class_name Combat
extends RefCounted

## Where damage happens, and the only place it happens.
##
## Five towers and five enemies are coming. Every one of them resolves through
## the two functions below, so armour, the minimum hit, the kill and the hurt
## flash are written once - and a new tower is a data entry rather than a fifth
## copy of the same arithmetic with one number different.
##
## ## Armour takes a slice off every hit, never all of it
##
## `design.md` section 9 wants the tank to make many small hits worse than a few
## big ones, which flat reduction does exactly. But reduction that could reach
## zero would make a tank **immune** to the auto-crossbow rather than bad
## against it, and an immune enemy in a tower defence is not a hard fight, it is
## a stuck night nobody can end.
##
## So a hit that lands always takes at least `MINIMUM_HIT`. The crossbow still
## loses to a tank - one damage against a hundred and twenty, slowly - which is
## what task 0045 asks for, without a softlock hiding in it.
##
## ## Nothing shoots what is already dead
##
## A dead target stops being a target the moment it dies, and a target with
## enough already in the air to kill it stops being one too. Without that, ten
## towers all fire at the leader, nine of those shots land on a corpse, and the
## wave behind it walks past untouched - which looks exactly like the towers
## being too weak and is not.

## What lands however good the armour is.
const MINIMUM_HIT := 1


## Hit something. Returns what was actually taken off, which is never more than
## it had left - so a caller counting damage dealt cannot count overkill.
static func hit(state: Dictionary, id: int, amount: int,
		_type: StringName = GameData.DAMAGE_IMPACT) -> int:
	var one := Entities.get_one(state, id)
	if one.is_empty() or amount <= 0:
		return 0

	var data: Dictionary = GameData.ENEMIES[one["kind"]]
	var after_armour := maxi(amount - int(data.get("armour", 0)), MINIMUM_HIT)
	var dealt := mini(after_armour, int(one["hp"]))

	Entities.set_hp(state, id, int(one["hp"]) - dealt)
	# A few ticks of "that hurt", for the view to flash. It is in the state
	# because the view must not have to remember anything the rules know.
	one["hurt"] = GameData.HURT_TICKS

	if int(one["hp"]) <= 0:
		_kill(state, id)
	return dealt


## How much damage is already on its way to this id.
##
## What stops a line of towers all committing to the same target. Counting the
## projectiles is exact and costs a walk of a list that is rarely longer than
## the number of towers.
static func incoming(state: Dictionary, id: int) -> int:
	var total := 0
	for shot in (state["projectiles"] as Array):
		if int(shot["target"]) == id:
			total += int(shot["damage"])
	return total


## Whether it is worth shooting at all: alive, and not already accounted for.
##
## The arithmetic uses the same armour the hit will, so a tank is not written
## off as dead because four crossbow bolts add up to its hit points on paper.
static func worth_shooting(state: Dictionary, id: int) -> bool:
	var one := Entities.get_one(state, id)
	if one.is_empty():
		return false
	var data: Dictionary = GameData.ENEMIES[one["kind"]]
	var armour := int(data.get("armour", 0))

	var committed := 0
	for shot in (state["projectiles"] as Array):
		if int(shot["target"]) == id:
			committed += maxi(int(shot["damage"]) - armour, MINIMUM_HIT)
	return committed < int(one["hp"])


## One tick of the hurt flash counting down. Called from `Sim._tick_night()`.
static func tick(state: Dictionary) -> void:
	if Entities.count(state) == 0:
		return
	for id in Entities.ids(state):
		var one := Entities.get_one(state, id)
		var left := int(one.get("hurt", 0))
		if left > 0:
			one["hurt"] = left - 1


## Something died. One place, so that the reward of task 0061, the corpse of
## task 0077 and the statistics of task 0069 all hang off the same line.
static func _kill(state: Dictionary, id: int) -> void:
	var one := Entities.get_one(state, id)
	if one.is_empty():
		return
	state["killed"] = int(state.get("killed", 0)) + 1
	var by_kind: Dictionary = state["killed_by_kind"]
	var kind: StringName = one["kind"]
	by_kind[kind] = int(by_kind.get(kind, 0)) + 1

	Entities.remove(state, id)
	# **Nothing is left pointing at it.** A projectile chasing a dead id is
	# dropped by `Towers` on the next tick; this is the other half of that
	# promise, and `headless_check` asserts there is no dangling reference.


static func initial() -> Dictionary:
	return {
		"killed": 0,
		"killed_by_kind": {},
	}
