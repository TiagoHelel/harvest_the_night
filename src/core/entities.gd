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
static func spawn(state: Dictionary, kind: StringName, cell: Vector2i) -> int:
	var data: Variant = GameData.ENEMIES.get(kind, null)
	if data == null:
		push_error("Entities.spawn: nothing called '%s'" % kind)
		return 0
	var id := int(state["next_entity_id"])
	state["next_entity_id"] = id + 1
	(state["entities"] as Dictionary)[id] = {
		"id": id,
		"kind": kind,
		"pos": [cell.x * Player.SUBTILE + Player.SUBTILE / 2,
				cell.y * Player.SUBTILE + Player.SUBTILE / 2],
		"hp": int((data as Dictionary)["hp"]),
		# Ticks of movement owed, so a speed measured in ticks-per-tile does
		# not need a float anywhere. Task 0025 uses it.
		"step": 0,
	}
	return id


static func get_one(state: Dictionary, id: int) -> Dictionary:
	return (state["entities"] as Dictionary).get(id, {})


static func alive(state: Dictionary, id: int) -> bool:
	return (state["entities"] as Dictionary).has(id)


## Every live id, lowest first. **Sorted, always**: every loop over entities is
## a loop that could resolve a tie, and iteration order is not a rule.
static func ids(state: Dictionary) -> Array:
	var out: Array = (state["entities"] as Dictionary).keys()
	out.sort()
	return out


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


## Take hit points off. Returns what was actually dealt, which is never more
## than the thing had left - task 0026 needs that to stop wasting overkill.
static func damage(state: Dictionary, id: int, amount: int) -> int:
	var one := get_one(state, id)
	if one.is_empty() or amount <= 0:
		return 0
	var dealt := mini(amount, int(one["hp"]))
	one["hp"] = int(one["hp"]) - dealt
	if int(one["hp"]) <= 0:
		remove(state, id)
	return dealt


static func remove(state: Dictionary, id: int) -> void:
	(state["entities"] as Dictionary).erase(id)


## How many of each kind are out there, for the debug overlay and the night HUD.
static func census(state: Dictionary) -> Dictionary:
	var counts := {}
	for id in ids(state):
		var kind: StringName = (get_one(state, id))["kind"]
		counts[kind] = int(counts.get(kind, 0)) + 1
	return counts
