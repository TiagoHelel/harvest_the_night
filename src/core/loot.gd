class_name Loot
extends RefCounted

## **What the night leaves behind** (task 0221; plan sections 3.3 and 4.6):
## the bones of whatever fell, on the cell it fell on, and the morning after a
## Full Moon a few moon stones along the road the horde came by. The farmer
## picks them up on the morning round by walking over them - no verb, no
## tool - and they go into the ledger like anything gathered.
##
## ## Lying about, never standing
##
## A pile is not an occupant. Nothing walks round it, nothing is refused a
## build on it, and the pathing never hears of it: it is a fact about a cell
## that the farmer's boots and the view read, and nothing else. It lives in
## `loot` (cell index -> {item: count}), beside the yard's `rubble`, and the
## morning's sweep (`Farm.clear_rubble`) does not touch it.
##
## ## Whose bones
##
## One body of a kind in `BONES_EVERY` leaves its bones - tonight's first
## walker, its ninth, its seventeenth - counted on the night's own tally
## (`killed_by_kind`), so a rare kind's first body always does. A boss
## always leaves its heap. Every body would have been eighty bones a spring
## night and six hundred a winter one.
##
## ## Where a pile goes
##
## Where it fell, when the farmer can stand there. A zombie that dies on a
## spike trap, against a wall or at the pond's edge leaves its bones on the
## nearest cell he can stand on: the nearest by distance, then the first in
## reading order - the top row first, the left first - within `LOOT_REACH`
## tiles. None that near and they are lost. One cell holds `LOOT_PILE_CAP` of
## a thing, and what falls on a full pile is trodden into the mud.
##
## ## How long it lies
##
## `LOOT_FADE_DAYS` mornings, then it is gone. A pile is as old as the night
## it was last added to, and the end of a night (`Phases.enter_result`) takes
## whatever has lain that long - at the end of the night rather than at dawn,
## so that the morning report counts what the morning has.


## The keys this subsystem owns. `State.create()` merges them in.
static func initial() -> Dictionary:
	return {
		# cell index -> {item: count}: what is lying on the farm.
		"loot": {},
		# cell index -> the day of the night the pile was last added to.
		"loot_laid": {},
	}


# ------------------------------------------------------------------ asking

## The pile on a cell, {item: count}; empty for none. The state's own
## Dictionary: read it, never write it.
static func at(state: Dictionary, cell: Vector2i) -> Dictionary:
	var idx := Grid.index(cell)
	if idx < 0:
		return {}
	return (state["loot"] as Dictionary).get(idx, {})


## Every cell with something lying on it, in index order.
static func cells(state: Dictionary) -> Array:
	var keys: Array = (state["loot"] as Dictionary).keys()
	keys.sort()
	var out: Array = []
	for idx in keys:
		out.append(Grid.cell(int(idx)))
	return out


## The cells with `item` on them, in index order.
static func cells_with(state: Dictionary, item: StringName) -> Array:
	var out: Array = []
	for cell in cells(state):
		if int(at(state, cell).get(item, 0)) > 0:
			out.append(cell)
	return out


## How much of each thing is lying on the farm, {item: count}: the morning
## report's leftovers line.
static func lying(state: Dictionary) -> Dictionary:
	var out := {}
	var loot: Dictionary = state["loot"]
	var keys: Array = loot.keys()
	keys.sort()
	for idx in keys:
		var pile: Dictionary = loot[idx]
		for item in GameData.sorted_names(pile.keys()):
			out[item] = int(out.get(item, 0)) + int(pile[item])
	return out


# ------------------------------------------------------------------ falling

## Leave `n` of `item` on `cell`, or where it comes to rest (`landing`).
## Returns how many landed: fewer when the pile there is near
## `LOOT_PILE_CAP`, none when there is nowhere near to stand.
static func drop(state: Dictionary, cell: Vector2i, item: StringName, n: int) -> int:
	if n <= 0:
		return 0
	var rest := landing(state, cell)
	if rest.x < 0:
		return 0
	var idx := Grid.index(rest)
	var loot: Dictionary = state["loot"]
	var pile: Dictionary = loot.get(idx, {})
	var landed := mini(n, GameData.LOOT_PILE_CAP - int(pile.get(item, 0)))
	if landed <= 0:
		return 0
	pile[item] = int(pile.get(item, 0)) + landed
	loot[idx] = pile
	(state["loot_laid"] as Dictionary)[idx] = int(state["day"])
	return landed


## **A body's bones, where it fell** (`Combat._kill`, after the night's
## tally has counted it): its `ENEMIES` row's `bones` when it is one of the
## bodies that leave them (`leaves_bones`), and none for a row without
## them - so a new enemy opts in.
static func drop_bones(state: Dictionary, kind: StringName, cell: Vector2i) -> int:
	var row: Dictionary = GameData.ENEMIES.get(kind, {})
	var nth := int((state["killed_by_kind"] as Dictionary).get(kind, 0))
	if not leaves_bones(kind, nth):
		return 0
	return drop(state, cell, GameData.BONES, int(row.get("bones", 0)))


## Whether tonight's `nth` body of a kind leaves its bones: the first, then
## one in `BONES_EVERY` - and every boss.
static func leaves_bones(kind: StringName, nth: int) -> bool:
	var row: Dictionary = GameData.ENEMIES.get(kind, {})
	if int(row.get("bones", 0)) <= 0 or nth <= 0:
		return false
	return bool(row.get("is_boss", false)) or (nth - 1) % GameData.BONES_EVERY == 0


## Where something dropped on `cell` comes to rest: the cell itself when the
## farmer can stand on it, else the nearest that he can (see the header), or
## `(-1, -1)` when there is none within `LOOT_REACH`.
static func landing(state: Dictionary, cell: Vector2i) -> Vector2i:
	if not Grid.in_bounds(cell):
		return Vector2i(-1, -1)
	if Farm.walkable(state, cell):
		return cell
	for step in nearest_steps():
		var near: Vector2i = cell + (step as Vector2i)
		if Grid.in_bounds(near) and Farm.walkable(state, near):
			return near
	return Vector2i(-1, -1)


## The steps within `LOOT_REACH`, nearest first, then in reading order: the
## order `landing` tries them in.
static func nearest_steps() -> Array:
	var reach := GameData.LOOT_REACH
	var out: Array = []
	for dy in range(-reach, reach + 1):
		for dx in range(-reach, reach + 1):
			if dx != 0 or dy != 0:
				out.append(Vector2i(dx, dy))
	# A total order - no two steps tie on all three - so the answer does not
	# hang on how the sort breaks ties.
	out.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var near_a := a.x * a.x + a.y * a.y
		var near_b := b.x * b.x + b.y * b.y
		if near_a != near_b:
			return near_a < near_b
		if a.y != b.y:
			return a.y < b.y
		return a.x < b.x)
	return out


# ------------------------------------------------------------ the night ends

## **As a night ends** (`Phases.enter_result`, before the day turns over):
## the piles that have lain `LOOT_FADE_DAYS` mornings go, and a Full Moon
## lays its stones.
static func night_ends(state: Dictionary) -> void:
	fade(state)
	lay_moon_stones(state)


## Take the piles that have lain `LOOT_FADE_DAYS` mornings. Returns how many
## went.
static func fade(state: Dictionary) -> int:
	var today := int(state["day"])
	var loot: Dictionary = state["loot"]
	var laid: Dictionary = state["loot_laid"]
	var keys: Array = loot.keys()
	keys.sort()
	var gone := 0
	for idx in keys:
		# A pile laid tonight is 0 mornings old, and goes after its last one.
		if today - int(laid.get(idx, today)) >= GameData.LOOT_FADE_DAYS:
			loot.erase(idx)
			laid.erase(idx)
			gone += 1
	return gone


## **The morning after a Full Moon** (task 0152's nights): `MOON_STONES` moon
## stones on the road the horde came by, one a cell. However the night ended -
## the moon does not ask who held. Returns the cells they went on.
static func lay_moon_stones(state: Dictionary) -> Array:
	if not Calendar.is_full_moon(int(state["night"])):
		return []
	var laid: Array = []
	for cell in moon_cells(state):
		if drop(state, cell, GameData.MOON_STONE, 1) > 0:
			laid.append(cell)
	return laid


## Where tonight's moon stones go: `MOON_STONES` cells spread evenly along
## `road(state)`, every Kth cell from an offset drawn from a stream of the
## night's own - mixed from the run's seed and the night as `Almanac` mixes
## its waves', and never the run's own dice. The same seed and the same farm,
## the same cells.
static func moon_cells(state: Dictionary) -> Array:
	var along := road(state)
	var wanted := mini(GameData.MOON_STONES, along.size())
	if wanted <= 0:
		return []
	var gap := along.size() / wanted
	var rng := Rng.create(_stream_for(int(state["seed"]), int(state["night"])))
	var start := Rng.int_between(rng, 0, gap - 1)
	var out: Array = []
	for i in wanted:
		out.append(along[start + i * gap])
	return out


## **The road the horde came by tonight**: from the middle spawn cell of each
## of tonight's spawn regions (`Waves.spawns_in`), the flow field's steps to
## the house, in walking order and each cell once - the ones the farmer can
## stand on.
static func road(state: Dictionary) -> Array:
	var out: Array = []
	var seen := {}
	for where in Waves.spawns_in(Waves.tonight(state)):
		var starts := Enemies.spawn_cells(state, int(where))
		if starts.is_empty():
			continue
		var cell: Vector2i = starts[starts.size() / 2]
		# A field value strictly falls on every step, so this ends; the bound
		# is only a guard against a field that is not built.
		for _step in Grid.CELLS:
			var idx := Grid.index(cell)
			if not seen.has(idx):
				seen[idx] = true
				if Farm.walkable(state, cell):
					out.append(cell)
			var next := Pathing.step_from(state, cell)
			if next == cell:
				break
			cell = next
	return out


## A stream for the stones, mixed from the run's seed and the night the way
## `Almanac` mixes one for its waves, with a salt of its own so that the two
## never draw the same numbers.
static func _stream_for(seed_value: int, night: int) -> int:
	var h := (seed_value ^ STONE_SALT) & 0xFFFFFFFF
	h = (h * 16777619) & 0xFFFFFFFF
	h = (h ^ (night * 2654435761)) & 0xFFFFFFFF
	h = (h * 16777619) & 0xFFFFFFFF
	return h


## "moon", as four bytes.
const STONE_SALT := 0x6D6F6F6E


# ---------------------------------------------------------------- picking up

## **Picked up by walking over it**, by day (`Player.tick`, after a step):
## the pile on the cell goes into the ledger and the cell is cleared.
## Returns what was picked up, {item: count}: empty after dark and on a bare
## cell.
static func collect_at(state: Dictionary, cell: Vector2i) -> Dictionary:
	if int(state["phase"]) != Phases.DAY:
		return {}
	var idx := Grid.index(cell)
	var loot: Dictionary = state["loot"]
	if idx < 0 or not loot.has(idx):
		return {}
	var pile: Dictionary = loot[idx]
	loot.erase(idx)
	(state["loot_laid"] as Dictionary).erase(idx)
	for item in GameData.sorted_names(pile.keys()):
		Resources.add(state, StringName(item), int(pile[item]))
	return pile
