class_name Entities
extends RefCounted

## Everything alive on the farm that is not the player.
##
## Zombies, today and mostly. A flat table keyed by an integer id, because
## **the id is how anything refers to anything else across a tick**: a
## projectile in flight names the thing it is chasing, and a reference to a
## dictionary would either dangle when the thing died or keep it alive after
## it should be gone.
##
## Ids are handed out in order and never reused. Two runs of the same seed give
## the same thing the same id, which is what lets "break a tie by id" mean
## something - and it is the only tie-break in the game that cannot depend on
## how a Dictionary felt like iterating.
##
## Positions are in `Player.SUBTILE` units, the same integers the player moves
## in, for the same reason: smooth movement with no floating point anywhere
## near the rules.

static func initial() -> Dictionary:
	return {
		"entities": {},
		# Never reset, never reused. An id that came back would make a stale
		# projectile hit whatever inherited it.
		"next_entity_id": 1,
	}


## Put something on the farm. Returns its id.
##
## **On a Blood Moon it comes as an elite** (task 0257): tonight's weather
## (`Weather.tonight`) raises its hit points to `Weather.elite_hp` and writes
## them down as `max_hp` - on the elite only, so an ordinary night's bodies
## are what they always were. Never a boss: an elite boss is another balance
## problem.
##
## **A boss of a later year** (task 0279) comes by the same road: its hit
## points grown a year (`Almanac.boss_hp`), written down as `max_hp`, so
## `Combat.full_hp` and the boss bar read them.
static func spawn(state: Dictionary, kind: StringName, cell: Vector2i) -> int:
	var data: Variant = GameData.ENEMIES.get(kind, null)
	if data == null:
		push_error("Entities.spawn: nothing called '%s'" % kind)
		return 0
	var id := int(state["next_entity_id"])
	state["next_entity_id"] = id + 1
	var one := {
		"id": id,
		"kind": kind,
		"pos": [cell.x * Player.SUBTILE + Player.SUBTILE / 2,
				cell.y * Player.SUBTILE + Player.SUBTILE / 2],
		"hp": int((data as Dictionary)["hp"]),
		# Ticks of movement owed, so a speed measured in ticks-per-tile does
		# not need a float anywhere. Task 0025 uses it.
		"step": 0,
	}
	var boss := bool((data as Dictionary).get("is_boss", false))
	if not boss and Weather.tonight(state) == Weather.BLOOD_MOON:
		one["hp"] = Weather.elite_hp(int(one["hp"]))
		one["max_hp"] = int(one["hp"])
	elif boss and Calendar.year_of(Calendar.date(state)) > 1:
		one["hp"] = Almanac.boss_hp(int(one["hp"]), Calendar.date(state))
		one["max_hp"] = int(one["hp"])
	(state["entities"] as Dictionary)[id] = one
	return id


## **Whether a body is a Blood Moon's elite** (task 0257): it carries
## `max_hp` and is no boss - a later year's boss carries one too (task 0279).
static func is_elite(state: Dictionary, id: int) -> bool:
	var one := get_one(state, id)
	return one.has("max_hp") and not bool((GameData.ENEMIES.get(one.get("kind", &""), {}) as Dictionary).get("is_boss", false))


static func get_one(state: Dictionary, id: int) -> Dictionary:
	return (state["entities"] as Dictionary).get(id, {})


static func alive(state: Dictionary, id: int) -> bool:
	return (state["entities"] as Dictionary).has(id)


## Every live id, lowest first: every loop over entities is a loop that could
## resolve a tie, and iteration order is not a rule.
##
## **In order without sorting** (task 0218). Ids are handed out ascending by
## `next_entity_id` and never reused, and a Dictionary keeps its keys in the
## order they went in, so the table is lowest first already - and stays so
## when one is taken out. Sorting it again on every call was most of what a
## tower's look round cost. `headless_v1` holds the table to that order after
## spawns, kills, a withdrawal and a save round trip, and `State.reconcile()`
## puts a save that came in otherwise back in order (`put_in_order()`).
static func ids(state: Dictionary) -> Array:
	return (state["entities"] as Dictionary).keys()


## Whether the table is lowest id first, as `ids()` takes it to be.
static func in_order(state: Dictionary) -> bool:
	var last := 0
	# **The one loop that reads the table's own order**, because the order is
	# what it is asking about.
	for id in (state["entities"] as Dictionary):
		if int(id) <= last:
			return false
		last = int(id)
	return true


## Put the table back in id order, if a save brought it in otherwise. True
## when it had to.
static func put_in_order(state: Dictionary) -> bool:
	if in_order(state):
		return false
	var table: Dictionary = state["entities"]
	var keys: Array = table.keys()
	keys.sort()
	var ordered := {}
	for id in keys:
		ordered[id] = table[id]
	state["entities"] = ordered
	return true


static func count(state: Dictionary) -> int:
	return (state["entities"] as Dictionary).size()


static func position(state: Dictionary, id: int) -> Vector2i:
	var one := get_one(state, id)
	if one.is_empty():
		return Vector2i(-1, -1)
	return Vector2i(int(one["pos"][0]), int(one["pos"][1]))


static func cell_of(state: Dictionary, id: int) -> Vector2i:
	var pos := position(state, id)
	if pos.x < 0:
		return Vector2i(-1, -1)
	return Vector2i(pos.x / Player.SUBTILE, pos.y / Player.SUBTILE)


## **Damage does not live here.** `Combat.hit()` is the one place armour, the
## minimum hit and the kill are decided, and a second way in would be a second
## set of rules that agreed with the first until somebody changed one of them.
##
## This is the raw write `Combat` uses, and nothing else should call it.
static func set_hp(state: Dictionary, id: int, hp: int) -> void:
	var one := get_one(state, id)
	if not one.is_empty():
		one["hp"] = hp


static func remove(state: Dictionary, id: int) -> void:
	(state["entities"] as Dictionary).erase(id)


## How many of each kind are out there, for the debug overlay and the night HUD.
static func census(state: Dictionary) -> Dictionary:
	var counts := {}
	for id in ids(state):
		var kind: StringName = (get_one(state, id))["kind"]
		counts[kind] = int(counts.get(kind, 0)) + 1
	return counts
