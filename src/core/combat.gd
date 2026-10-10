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

## Whether anything with `is_boss` is on the farm right now. The night HUD
## puts a name and a health bar up for it.
static func boss_here(state: Dictionary) -> int:
	for id in Entities.ids(state):
		var kind: StringName = Entities.get_one(state, id).get("kind", &"")
		if kind == &"":
			continue
		if bool((GameData.ENEMIES[kind] as Dictionary).get("is_boss", false)):
			return id
	return 0


## How many bosses have been put down this run.
static func bosses_down(state: Dictionary) -> int:
	return int(state.get("bosses_down", 0))


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
	# **Before the early return.** A thing can be on fire on a tick when
	# nothing else is happening, and the fire going out is the last thing that
	# happens on some nights.
	_tick_burning(state)
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

	# **The run's own tally, beside the night's.** `killed` is cleared every
	# `begin_night()` - a night that inherited last night's count would be a
	# night that started halfway through - so the run summary of task 0066
	# would have read the last night and called it ten.
	state["killed_all_run"] = int(state.get("killed_all_run", 0)) + 1
	var ever: Dictionary = state["killed_by_kind_all_run"]
	ever[kind] = int(ever.get(kind, 0)) + 1
	# **A boss going down is a fact about the run**, not about the night.
	# `is_boss` had been in the table since it was written and nothing read
	# it; task 0066 ends the run on this.
	if bool((GameData.ENEMIES[kind] as Dictionary).get("is_boss", false)):
		state["bosses_down"] = int(state.get("bosses_down", 0)) + 1
	# **Its bones stay where it fell** (task 0221): on its cell, or the
	# nearest one the farmer can stand on. Only a kill leaves them - one that
	# bites the house or walks off at dawn is removed elsewhere, whole.
	Loot.drop_bones(state, kind, Entities.cell_of(state, id))

	Entities.remove(state, id)
	# **Nothing is left pointing at it.** A projectile chasing a dead id is
	# dropped by `Towers` on the next tick; this is the other half of that
	# promise, and `headless_check` asserts there is no dangling reference.


static func initial() -> Dictionary:
	return {
		"killed": 0,
		"killed_by_kind": {},
		# The same two for the whole run, which the night reset does not
		# touch. See `_kill()`.
		"killed_all_run": 0,
		"killed_by_kind_all_run": {},
		# How many bosses this run has put down. The MVP has one, and task
		# 0066 ends the run when it falls.
		"bosses_down": 0,
		# {entity id: {"left": ticks, "damage": per second, "next": ticks}}
		"burning": {},
	}


# ------------------------------------------------------------------- burning

## Set something alight, or top it up if it already is.
##
## **Refreshed, never stacked.** Two flamethrowers on one zombie is one fire
## burning for the full duration, not two fires burning at once - otherwise six
## towers would be six times the damage and the flamethrower would stop being a
## tower and start being a win button. The stronger of the two damages wins,
## which is what makes upgrading one matter without making a second one
## pointless.
static func set_alight(state: Dictionary, id: int, damage: int,
		ticks: int) -> void:
	if damage <= 0 or ticks <= 0 or not Entities.alive(state, id):
		return
	var burning: Dictionary = state["burning"]
	if burning.has(id):
		var already: Dictionary = burning[id]
		already["left"] = maxi(int(already["left"]), ticks)
		already["damage"] = maxi(int(already["damage"]), damage)
		return
	burning[id] = {
		"left": ticks,
		"damage": damage,
		"next": GameData.BURN_EVERY_TICKS,
	}


static func is_burning(state: Dictionary, id: int) -> bool:
	return (state["burning"] as Dictionary).has(id)


## How long this one has left to burn, in ticks. Zero when it is not.
static func burn_left(state: Dictionary, id: int) -> int:
	var burning: Dictionary = state["burning"]
	return 0 if not burning.has(id) else int((burning[id] as Dictionary)["left"])


## One tick of everything on fire.
##
## **It keeps burning after it leaves the cone**, which is the whole of what
## damage over time buys: a flamethrower that only hurt what was standing in
## front of it would be a short-range gun tower that cost oil.
static func _tick_burning(state: Dictionary) -> void:
	var burning: Dictionary = state["burning"]
	if burning.is_empty():
		return
	# Sorted, because two things burning out on the same tick have to die in
	# the same order on every machine.
	var ids: Array = burning.keys()
	ids.sort()
	var out: Array = []
	for id in ids:
		if not Entities.alive(state, int(id)):
			out.append(id)
			continue
		var fire: Dictionary = burning[id]
		fire["left"] = int(fire["left"]) - 1
		fire["next"] = int(fire["next"]) - 1
		if int(fire["next"]) <= 0:
			fire["next"] = GameData.BURN_EVERY_TICKS
			hit(state, int(id), int(fire["damage"]), GameData.DAMAGE_FIRE)
		if int(fire["left"]) <= 0 or not Entities.alive(state, int(id)):
			out.append(id)
	for id in out:
		burning.erase(id)
