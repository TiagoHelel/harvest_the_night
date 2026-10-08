class_name House
extends RefCounted

## A separate walkable room, stored as plain data and driven by the same tick.
## Farm time continues; local coordinates never perform jobs on outdoor cells.
const ROOM := GameData.HOUSE_ROOM
const DOOR := GameData.HOUSE_DOOR
const SPAWN := GameData.HOUSE_SPAWN
const FURNITURE := GameData.HOUSE_FURNITURE


static func initial() -> Dictionary:
	return {"house_visit": {"inside": false, "outside_pos": [],
		"outside_facing": Player.SOUTH,
		# Gone to bed (task 0127): set by `Phases.begin_preparation`, so every
		# road into the build step leaves him asleep; cleared at dawn.
		"asleep": false,
		# Fell asleep where he stood at 02:00 (task 0128): the build step is
		# the short one. Cleared by a bedtime and by the morning.
		"passed_out": false}}


static func inside(state: Dictionary) -> bool:
	return bool((state.get("house_visit", {}) as Dictionary).get("inside", false))


## Whether the farmer is asleep: from going to bed until the morning. **Not
## the same as `inside()`** - the room is left behind when he sleeps, so the
## farm, its building and its view carry on outdoors through the night.
static func asleep(state: Dictionary) -> bool:
	return bool((state.get("house_visit", {}) as Dictionary).get("asleep", false))


## Whether tonight's sleep began with him collapsing at 02:00 (task 0128)
## rather than in his bed - which is where the view draws him.
static func passed_out(state: Dictionary) -> bool:
	return bool((state.get("house_visit", {}) as Dictionary).get("passed_out", false))


## The bed, as the rectangle `HOUSE_FURNITURE` gives it.
static func bed() -> Rect2i:
	for piece in FURNITURE:
		if StringName(piece["id"]) == &"bed":
			return Rect2i(piece["cell"], piece["size"])
	return Rect2i()


## Whether a floor cell is beside the bed - one step from it, side by side
## rather than corner to corner - which is where going to bed is offered.
static func bedside(cell: Vector2i) -> bool:
	var rect := bed()
	if rect.size == Vector2i.ZERO or not walkable(cell):
		return false
	for step in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		if rect.has_point(cell + step):
			return true
	return false


## Whether the farmer could go to bed right now: indoors, by day, beside it.
static func can_sleep(state: Dictionary) -> bool:
	return inside(state) and int(state["phase"]) == Phases.DAY \
		and bedside(Player.cell(state))


static func porch(state: Dictionary) -> Vector2i:
	var bounds := Farm.house_bounds(state)
	return Vector2i(-1, -1) if bounds.size == Vector2i.ZERO else bounds.position \
		+ Vector2i(bounds.size.x / 2, bounds.size.y)


static func can_enter(state: Dictionary) -> bool:
	return not inside(state) and int(state["phase"]) == Phases.DAY \
		and StringName(state["open_panel"]) == &"" and not Building.is_active(state) \
		and not Player.is_busy(state) and Player.cell(state) == porch(state)


static func enter(state: Dictionary) -> bool:
	if not can_enter(state):
		return false
	var visit: Dictionary = state["house_visit"]
	visit["outside_pos"] = (state["player"]["pos"] as Array).duplicate()
	visit["outside_facing"] = Player.facing(state)
	visit["inside"] = true
	state["player"]["pos"] = [SPAWN.x * Player.SUBTILE + Player.SUBTILE / 2,
		SPAWN.y * Player.SUBTILE + Player.SUBTILE / 2]
	state["player"]["facing"] = Player.NORTH
	state["player"]["action"] = {}
	Fishing.give_up(state)
	state["intent"]["interact"] = false
	return true


static func leave(state: Dictionary) -> void:
	if not inside(state):
		return
	var visit: Dictionary = state["house_visit"]
	var back: Array = visit["outside_pos"]
	var here := Vector2i(int(back[0]) / Player.SUBTILE, int(back[1]) / Player.SUBTILE)
	if not Farm.walkable(state, here):
		for candidate in Grid.within(porch(state), 5):
			if Farm.walkable(state, candidate):
				back = [candidate.x * Player.SUBTILE + Player.SUBTILE / 2,
					candidate.y * Player.SUBTILE + Player.SUBTILE / 2]
				break
	state["player"]["pos"] = back.duplicate()
	state["player"]["facing"] = Player.SOUTH
	state["player"]["action"] = {}
	visit["inside"] = false
	visit["outside_pos"] = []
	state["intent"]["interact"] = false
	state["intent"]["cancel"] = false


static func walkable(cell: Vector2i) -> bool:
	if cell == DOOR:
		return true
	if cell.x < 1 or cell.x >= ROOM.x - 1 or cell.y < 3 or cell.y >= ROOM.y - 1:
		return false
	for piece in FURNITURE:
		if Rect2i(piece["cell"], piece["size"]).has_point(cell):
			return false
	return true


## Rehome an indoor save if a furniture revision occupies its old standing cell.
static func repair_position(state: Dictionary) -> bool:
	if not inside(state) or walkable(Player.cell(state)):
		return false
	var original := Player.cell(state)
	var nearest := SPAWN
	var distance := ROOM.x + ROOM.y
	for y in range(3, ROOM.y - 1):
		for x in range(1, ROOM.x - 1):
			var cell := Vector2i(x, y)
			var next := absi(cell.x - original.x) + absi(cell.y - original.y)
			if walkable(cell) and next < distance:
				nearest = cell
				distance = next
	state["player"]["pos"] = [nearest.x * Player.SUBTILE + Player.SUBTILE / 2,
		nearest.y * Player.SUBTILE + Player.SUBTILE / 2]
	return true


static func tick(state: Dictionary) -> void:
	var intent: Dictionary = state["intent"]
	var move: Array = intent["move"]
	var dx := signi(int(move[0]))
	var dy := signi(int(move[1]))
	var speed := GameData.PLAYER_SPEED
	if dx != 0 and dy != 0:
		speed = speed * Player.DIAGONAL_NUMERATOR / Player.DIAGONAL_DENOMINATOR
	state["player"]["facing"] = Player._facing_for(dx, dy, Player.facing(state))
	for delta in [Vector2i(dx * speed, 0), Vector2i(0, dy * speed)]:
		var pos: Vector2i = Player.position(state) + delta
		if walkable(Vector2i(pos.x / Player.SUBTILE, pos.y / Player.SUBTILE)):
			state["player"]["pos"] = [pos.x, pos.y]
	var here := Player.cell(state)
	if here == DOOR or (here == SPAWN and bool(intent["interact"])):
		leave(state)
	elif bool(intent["interact"]) and can_sleep(state):
		# **The bed's verb** (task 0127): the same `sleep` intent the GO TO
		# BED button writes, decided by the next tick like every intent.
		intent["sleep"] = true
	intent["interact"] = false
	intent["cancel"] = false
