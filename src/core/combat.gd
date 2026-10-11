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

## Whether anything with `is_boss` is on the farm right now - the lowest id
## of them, or 0. The night HUD puts a name and a health bar up for it.
static func boss_here(state: Dictionary) -> int:
	var bosses := bosses_here(state)
	return int(bosses[0]) if not bosses.is_empty() else 0


## **Every boss on the farm** (task 0246), lowest id first: Endless sends
## two Giants, and 0253-0255 add bosses of their own.
static func bosses_here(state: Dictionary) -> Array:
	var out: Array = []
	for id in Entities.ids(state):
		if is_boss(StringName(Entities.get_one(state, id).get("kind", &""))):
			out.append(int(id))
	out.sort()
	return out


## **Whether a kind's death chills the towers round it** (task 0251): its
## row has a burst, `chill_tiles`.
static func chills(kind: StringName) -> bool:
	return int((GameData.ENEMIES.get(kind, {}) as Dictionary).get("chill_tiles", 0)) > 0


## Whether a kind is a boss: its `is_boss`.
static func is_boss(kind: StringName) -> bool:
	return kind != &"" and bool((GameData.ENEMIES.get(kind, {}) as Dictionary).get("is_boss", false))


## **A body's full health** (task 0246): its kind's `hp` in the table, or a
## Blood Moon elite's own `max_hp` (task 0257) - which the boss bar and the
## checks read rather than the table. 0 for nobody.
static func full_hp(state: Dictionary, id: int) -> int:
	var one := Entities.get_one(state, id)
	if one.is_empty():
		return 0
	if one.has("max_hp"):
		return int(one["max_hp"])
	return int((GameData.ENEMIES[StringName(one["kind"])] as Dictionary).get("hp", 0))


## How many bosses have been put down this run.
static func bosses_down(state: Dictionary) -> int:
	return int(state.get("bosses_down", 0))


## **How many of one boss have been put down this run** (task 0246), off the
## run's tally by kind - no counter of its own. 0 for a kind that is no boss.
static func bosses_down_of(state: Dictionary, kind: StringName) -> int:
	if not is_boss(kind):
		return 0
	return int((state.get("killed_by_kind_all_run", {}) as Dictionary).get(kind, 0))


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


## Whether it is worth shooting at all: alive, seen (task 0252), and not
## already accounted for.
##
## The arithmetic uses the same armour the hit will, so a tank is not written
## off as dead because four crossbow bolts add up to its hit points on paper.
static func worth_shooting(state: Dictionary, id: int) -> bool:
	var one := Entities.get_one(state, id)
	if one.is_empty():
		return false
	var data: Dictionary = GameData.ENEMIES[one["kind"]]
	# **Not what cannot be seen** (task 0252): a wraith in the dark is no
	# target for any tower, until the tick it stands in light.
	if bool(data.get("needs_light", false)) and not Enemies.in_sight(state, id):
		return false
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
	# The stings after the fire (task 0226), in the same sorted order.
	_tick_stung(state)
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
	# **A King's flock is not the night's** (task 0254): a summoned body is a
	# kill, here and in the run's tallies, but not in the night's tally by
	# kind - which pays the bounty and drops the bones. A King left casting
	# would be a farm of crows.
	var summoned := bool(one.get("summoned", false))
	if not summoned:
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
	if not summoned:
		Loot.drop_bones(state, kind, Entities.cell_of(state, id))
	# **Its death is the attack** (task 0251): a kind that `chills` bursts
	# into ice where it fell, and every tower round it reloads slowly for a
	# while. Only a kill: one that bites the house or walks off at dawn goes
	# whole, with nothing to burst.
	if chills(kind):
		var row: Dictionary = GameData.ENEMIES[kind]
		Towers.chill_around(state, Entities.cell_of(state, id), int(row["chill_tiles"]),
			int(row["chill_ticks"]), int(row["chill_reload_percent"]))

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
		# The same, for a hive's stings (task 0226): `sting()`.
		"stung": {},
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
##
## **Damped in the rain** (task 0256): each tick of it deals
## `rain_fire_percent` of itself (`Weather.damped`), never under one.
static func _tick_burning(state: Dictionary) -> void:
	var burning: Dictionary = state["burning"]
	if burning.is_empty():
		return
	# **Tonight's weather, asked once a tick** - and only while something
	# burns, which is when it matters.
	var weather := Weather.tonight(state)
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
			hit(state, int(id), Weather.damped(int(fire["damage"]), GameData.DAMAGE_FIRE, weather),
				GameData.DAMAGE_FIRE)
		if int(fire["left"]) <= 0 or not Entities.alive(state, int(id)):
			out.append(id)
	for id in out:
		burning.erase(id)


# ------------------------------------------------------------------ stinging

## Sting something, or top the sting up if it already has one (task 0226).
##
## **A table beside `burning`, not a second kind of fire.** A thing can burn
## and be stung at once - a flamethrower and a hive on the same crowd - and
## each is topped up by its own kind; the rain of task 0256 damps `burning`
## and never touches a sting. **Refreshed, never stacked**, as a fire is: two
## hives on one zombie are one sting, for the longer time at the stronger
## damage.
##
## **The first lands at once** (`next` 1, and `tick()` runs after the
## towers'): a sting is felt when it is given. A top-up keeps the running
## count, so stinging again never puts a hit off.
static func sting(state: Dictionary, id: int, damage: int, ticks: int) -> void:
	if damage <= 0 or ticks <= 0 or not Entities.alive(state, id):
		return
	var stung: Dictionary = state["stung"]
	if stung.has(id):
		var already: Dictionary = stung[id]
		already["left"] = maxi(int(already["left"]), ticks)
		already["damage"] = maxi(int(already["damage"]), damage)
		return
	stung[id] = {
		"left": ticks,
		"damage": damage,
		"next": 1,
	}


static func is_stung(state: Dictionary, id: int) -> bool:
	return (state["stung"] as Dictionary).has(id)


## How long this one has left stung, in ticks. Zero when it is not.
static func sting_left(state: Dictionary, id: int) -> int:
	var stung: Dictionary = state["stung"]
	return 0 if not stung.has(id) else int((stung[id] as Dictionary)["left"])


## One tick of everything stung: `_tick_burning`'s rule - sorted ids, a hit
## every `STING_EVERY_TICKS` - with the sting's own damage type.
static func _tick_stung(state: Dictionary) -> void:
	var stung: Dictionary = state["stung"]
	if stung.is_empty():
		return
	var ids: Array = stung.keys()
	ids.sort()
	var out: Array = []
	for id in ids:
		if not Entities.alive(state, int(id)):
			out.append(id)
			continue
		var bees: Dictionary = stung[id]
		bees["left"] = int(bees["left"]) - 1
		bees["next"] = int(bees["next"]) - 1
		if int(bees["next"]) <= 0:
			bees["next"] = GameData.STING_EVERY_TICKS
			hit(state, int(id), int(bees["damage"]), GameData.DAMAGE_STING)
		if int(bees["left"]) <= 0 or not Entities.alive(state, int(id)):
			out.append(id)
	for id in out:
		stung.erase(id)
