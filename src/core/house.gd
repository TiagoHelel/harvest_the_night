class_name House
extends RefCounted

## A separate walkable room, stored as plain data and driven by the same tick.
## Farm time continues; local coordinates never perform jobs on outdoor cells.
const ROOM := GameData.HOUSE_ROOM
const DOOR := GameData.HOUSE_DOOR
const SPAWN := GameData.HOUSE_SPAWN
const FURNITURE := GameData.HOUSE_FURNITURE


static func initial() -> Dictionary:
	return {"house_visit": {"inside": false, "outside_pos": [], "outside_facing": Player.SOUTH}}


static func inside(state: Dictionary) -> bool:
	return bool((state.get("house_visit", {}) as Dictionary).get("inside", false))


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
	intent["interact"] = false
	intent["cancel"] = false
