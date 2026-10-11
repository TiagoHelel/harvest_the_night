class_name Traps
extends RefCounted

## Things that go off when somebody stands on them.
##
## The reference sheet's mine: no targeting, no upkeep, no range circle, and
## then it is gone. **It is not a tower** and the code is careful about that -
## `Towers` collects everything with a `reload_ticks` and a mine has none, so
## it never appears in a targeting loop, never draws a line to anything, and
## costs nothing on a tick when nobody is near it.
##
## ## It triggers on arrival, not on a timer
##
## `Enemies.tick()` moves everybody; this runs straight afterwards and asks
## one question per entity - "is there a trap under me". That is a dictionary
## lookup per zombie, which is the cheapest thing in the night loop, and it
## means a mine goes off on the tick a foot lands on it rather than up to a
## tick later.
##
## ## They do not chain
##
## The done-when asks for a decision and for it to be written down, so: **a
## mine's blast damages entities and nothing else.** Two mines side by side
## are two mines, not a hundred and twenty damage in one bang.
##
## The reason is placement. A chain would mean the right move is always to put
## every mine you own in one line and detonate the lot, which is one decision
## made once rather than a decision per mine - and it makes the difference
## between a good mine placement and a bad one disappear into the size of the
## pile. `design.md` wants the farm to be a set of small choices; a cascade is
## the opposite of that.
##
## It also keeps a mine from being destroyed by anything else's splash, which
## would make the mortar and the flamethrower quietly disarm the farm they are
## defending.


static func initial() -> Dictionary:
	return {
		# How many have gone off, for the statistics of task 0069.
		"traps_sprung": 0,
	}


# ------------------------------------------------------------------- asking

## Whether this is a thing that goes off once and is then gone.
static func is_trap(id: StringName) -> bool:
	var entry: Variant = GameData.DEFENCES.get(id, null)
	return entry != null and bool((entry as Dictionary).get("one_shot", false))


## The trap on this cell, or an empty Dictionary.
static func at(state: Dictionary, cell: Vector2i) -> Dictionary:
	var on := Farm.occupant(state, cell)
	if on.is_empty() or not is_trap(StringName(on["id"])):
		return {}
	return on


## How many of a given trap are armed on the farm right now.
static func armed(state: Dictionary, id: StringName) -> int:
	return Farm.cells_with(state, id).size()


## How many more of this may be armed. A big number for anything with no
## limit declared, so callers need not know which is which.
static func room_for(state: Dictionary, id: StringName) -> int:
	var entry: Variant = GameData.DEFENCES.get(id, null)
	if entry == null:
		return 0
	var limit := int((entry as Dictionary).get("armed_limit", 0))
	if limit <= 0:
		return 1 << 30
	return maxi(limit - armed(state, id), 0)


static func sprung(state: Dictionary) -> int:
	return int(state.get("traps_sprung", 0))


# ------------------------------------------------------------------ the tick

## One tick of looking down. Called from `Sim._tick_night()`, straight after
## everything has moved.
static func tick(state: Dictionary) -> void:
	if Entities.count(state) == 0:
		return
	# Sorted, so that two zombies stepping onto the same mine on the same tick
	# always set it off in the same order - and the one that does is always
	# the same one.
	for id in Entities.ids(state):
		if not Entities.alive(state, id):
			continue
		var cell := Entities.cell_of(state, id)
		if cell.x < 0:
			continue
		var trap := at(state, cell)
		if trap.is_empty():
			continue
		# **What flies over it never sets it off** (task 0249).
		if Enemies.airborne(state, id):
			continue
		_detonate(state, cell, StringName(trap["id"]))


## Set one off by hand. **For the tests only**, the same door
## `Towers.land_at_for_test()` opens: measuring a blast through a tick means
## measuring it after everybody has taken a step, and then the numbers belong
## to wherever they ended up rather than to the rings they started on.
static func detonate_for_test(state: Dictionary, cell: Vector2i) -> void:
	var trap := at(state, cell)
	if trap.is_empty():
		return
	_detonate(state, cell, StringName(trap["id"]))


## Off it goes, and then it is not there any more.
##
## **Removed before the damage lands.** A mine that was still on the cell
## while its own blast resolved could be triggered again by the next entity in
## the same loop, which is one mine doing its damage twice for no reason a
## player could see.
static func _detonate(state: Dictionary, cell: Vector2i,
		id: StringName) -> void:
	var entry: Dictionary = GameData.DEFENCES[id]
	Farm.remove(state, cell)
	state["traps_sprung"] = int(state.get("traps_sprung", 0)) + 1

	var damage := int(entry.get("damage", 0))
	var radius := maxi(int(entry.get("splash_tiles", 1)), 1)
	var edge := int(entry.get("splash_falloff_percent", 100))
	var kind := StringName(entry.get("damage_type", GameData.DAMAGE_EXPLOSIVE))

	# Entities only. See the note at the top of this file: no chains.
	for other in Entities.ids(state):
		var at_cell := Entities.cell_of(state, other)
		if at_cell.x < 0:
			continue
		var apart := Grid.chebyshev(cell, at_cell)
		if apart > radius:
			continue
		# Nor does its blast reach the air (task 0249), or under a fence (0250).
		if not Enemies.in_reach(state, other, false):
			continue
		var share := 100 - (100 - edge) * apart / radius
		Combat.hit(state, other, maxi(damage * share / 100, 1), kind)
