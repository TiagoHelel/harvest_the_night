class_name House
extends RefCounted

## A separate walkable room, stored as plain data and driven by the same tick.
## Farm time continues; local coordinates never perform jobs on outdoor cells.
const ROOM := GameData.HOUSE_ROOM
const DOOR := GameData.HOUSE_DOOR
const SPAWN := GameData.HOUSE_SPAWN
const FURNITURE := GameData.HOUSE_FURNITURE


static func initial() -> Dictionary:
	return {
		# **Which of `HOUSE_TIERS` the house is** (task 0191), from 1. An old
		# save gets tier I from the reconcile, which is the house it had.
		"house_tier": 1,
		"house_visit": {"inside": false, "outside_pos": [],
		"outside_facing": Player.SOUTH,
		# Gone to bed (task 0127): set by `Phases.begin_preparation`, so every
		# road into the build step leaves him asleep; cleared at dawn.
		"asleep": false,
		# Fell asleep where he stood at 02:00 (task 0128): the build step is
		# the short one. Cleared by a bedtime and by the morning.
		"passed_out": false}}


## **The house's tier** (task 0191), 1 to `HOUSE_TIERS.size()`.
static func tier(state: Dictionary) -> int:
	return clampi(int(state.get("house_tier", 1)), 1, GameData.HOUSE_TIERS.size())


## What this tier adds to the house's hit points.
static func tier_bonus(state: Dictionary) -> int:
	return int((GameData.HOUSE_TIERS[tier(state) - 1] as Dictionary)["hp_bonus"])


## The percentage this tier takes off a house repair.
static func tier_discount(state: Dictionary) -> int:
	return int((GameData.HOUSE_TIERS[tier(state) - 1] as Dictionary)["repair_discount"])


## What the next tier costs, or empty at the top.
static func next_cost(state: Dictionary) -> Dictionary:
	if tier(state) >= GameData.HOUSE_TIERS.size():
		return {}
	return ((GameData.HOUSE_TIERS[tier(state)] as Dictionary)["cost"] as Dictionary).duplicate()


## Why the next tier cannot be bought now: by day only, not past the top,
## and paid for in full. Empty when it can.
static func why_not_tier(state: Dictionary) -> Array:
	if int(state["phase"]) != Phases.DAY:
		return [&"WHY_AFTER_DARK"]
	if tier(state) >= GameData.HOUSE_TIERS.size():
		return [&"WHY_HOUSE_TOP"]
	var cost := next_cost(state)
	if not Resources.can_afford(state, cost):
		return [&"WHY_SHORT", Resources.missing(state, cost)]
	return []


## **Buy the next tier** (task 0191), at the workshop by day. It is the house
## from now on - `Phases.house_full` reads it, so tonight's house is the new
## one - and the new rooms come whole: the hit points it adds are added to
## what the house has, so a whole house stays whole.
static func buy_tier(state: Dictionary) -> bool:
	if not why_not_tier(state).is_empty():
		return false
	if not Resources.pay(state, next_cost(state)):
		return false
	var before := tier_bonus(state)
	state["house_tier"] = tier(state) + 1
	state["house_hp"] = int(state["house_hp"]) + tier_bonus(state) - before
	Events.add(state, &"house_tier", {"tier": tier(state)})
	return true


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


## **The morning** (task 0138): up at 06:00 in his own bed, whether he went to
## it or fell asleep in a field - inside, on the floor beside the bed, awake,
## with the porch as the way out, so the day starts by walking out of the
## door. `Phases.begin_day` is the one caller.
static func wake(state: Dictionary) -> void:
	var visit: Dictionary = state["house_visit"]
	var door := porch(state)
	visit["outside_pos"] = [door.x * Player.SUBTILE + Player.SUBTILE / 2,
		door.y * Player.SUBTILE + Player.SUBTILE / 2] if door.x >= 0 \
		else (state["player"]["pos"] as Array).duplicate()
	visit["outside_facing"] = Player.SOUTH
	visit["inside"] = true
	visit["asleep"] = false
	visit["passed_out"] = false
	var cell := wake_cell()
	state["player"]["pos"] = [cell.x * Player.SUBTILE + Player.SUBTILE / 2,
		cell.y * Player.SUBTILE + Player.SUBTILE / 2]
	state["player"]["facing"] = Player.SOUTH
	state["player"]["action"] = {}
	Fishing.give_up(state)
	state["intent"]["interact"] = false
	state["intent"]["cancel"] = false


## Where he gets out of bed: the floor cell at its foot, or the first bedside
## cell when a furniture revision has put something there.
static func wake_cell() -> Vector2i:
	var rect := bed()
	var foot := Vector2i(rect.position.x + rect.size.x / 2, rect.end.y)
	if bedside(foot):
		return foot
	for y in range(3, ROOM.y - 1):
		for x in range(1, ROOM.x - 1):
			if bedside(Vector2i(x, y)):
				return Vector2i(x, y)
	return SPAWN


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
