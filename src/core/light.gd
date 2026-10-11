class_name Light
extends RefCounted

## **What is lit at night** (task 0229; the plan's section 5): the one place
## light is a rule. The searchlight's whole job, and what the wraith (0252)
## and the fog (0256) will read; `lighting.gd` may draw from it, never the
## other way round.
##
## A cell is lit when it is:
## - within a standing **searchlight**'s `light_tiles`, a square as a tower's
##   reach is - a tile less on a farm short of power, never out;
## - within `PORCH_LIGHT_TILES` of the house's **porch**;
## - in the **flare**'s area while it burns (`Ability.aimed_at`);
## - under an enemy that is **burning** (`Combat.is_burning`).
##
## ## Cached where it stands still, asked fresh where it moves
##
## The searchlights and the porch only change when the farm does, or when the
## farm's power runs short or comes back - so their cells are kept in the
## state (`light_cells`), stamped with the `grid_version` and the short flag
## they were worked out for (`light_for`), and rebuilt when either moves, as
## `Towers._towers` keeps its list. The flare and the fires are asked fresh.
##
## **Asked, never ticked**: nothing advances it. And only the rules ask the
## cached way (`is_lit`), because asking refreshes the cache in the state: the
## view asks `lamp_tiles` and `lit_cells`, which write nothing.

static func initial() -> Dictionary:
	return {
		# {cell index: true} for every cell a searchlight or the porch lights.
		"light_cells": {},
		# The `grid_version` and the short flag `light_cells` was built for.
		"light_for": [-1, false],
	}


## Whether this cell is lit. The rules' question - the towers' reach asks it.
static func is_lit(state: Dictionary, cell: Vector2i) -> bool:
	var idx := Grid.index(cell)
	if idx < 0:
		return false
	if _steady(state).has(idx):
		return true
	return _flared(state, cell) or _burning_on(state, cell)


## **How far a lamp standing here lights tonight**, in tiles: its levelled
## `light_tiles`, `LIGHT_SHORT_SHRINK` fewer while the farm is short of power
## and never fewer than one - degraded, never dead. Zero for anything that is
## not a lamp. Writes nothing, so the view may ask it.
static func lamp_tiles(state: Dictionary, cell: Vector2i) -> int:
	var entry := Building.entry_at(state, cell)
	var tiles := int(entry.get("light_tiles", 0))
	if tiles <= 0:
		return 0
	if Power.is_short(state):
		tiles = maxi(tiles - GameData.LIGHT_SHORT_SHRINK, 1)
	return tiles


## Every lit cell, in index order - the steady ones worked out afresh rather
## than read from the cache. For the tests and the view; writes nothing.
static func lit_cells(state: Dictionary) -> Array:
	var lit: Dictionary = _steady_cells(state)
	var flare := Ability.aimed_at(state, Ability.FLARE)
	if not flare.is_empty():
		var radius := int(GameData.ABILITY["radius_tiles"])
		_stamp(lit, Vector2i(int(flare[0]), int(flare[1])), radius)
	var burning: Array = (state["burning"] as Dictionary).keys()
	burning.sort()
	for id in burning:
		var at := Entities.cell_of(state, int(id))
		if at.x >= 0:
			lit[Grid.index(at)] = true
	var keys: Array = lit.keys()
	keys.sort()
	var out: Array = []
	for idx in keys:
		out.append(Grid.cell(int(idx)))
	return out


## The cache, refreshed when the farm or its power has moved since.
static func _steady(state: Dictionary) -> Dictionary:
	var stamp := [int(state["grid_version"]), Power.is_short(state)]
	if state["light_for"] != stamp:
		state["light_cells"] = _steady_cells(state)
		state["light_for"] = stamp
	return state["light_cells"]


## The cells every searchlight and the porch light, worked out from the farm.
static func _steady_cells(state: Dictionary) -> Dictionary:
	var lit := {}
	var occupants: Dictionary = state["occupants"]
	var keys: Array = occupants.keys()
	keys.sort()
	for key in keys:
		var id := StringName((occupants[key] as Dictionary)["id"])
		if not GameData.DEFENCES.has(id) or not (GameData.DEFENCES[id] as Dictionary).has("light_tiles"):
			continue
		var cell := Grid.cell(int(key))
		_stamp(lit, cell, lamp_tiles(state, cell))
	var porch := House.porch(state)
	if Grid.in_bounds(porch):
		_stamp(lit, porch, GameData.PORCH_LIGHT_TILES)
	return lit


## Every cell within `radius` of `centre`, a square, marked lit.
static func _stamp(lit: Dictionary, centre: Vector2i, radius: int) -> void:
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			var at := centre + Vector2i(dx, dy)
			if Grid.in_bounds(at):
				lit[at.y * Grid.WIDTH + at.x] = true


static func _flared(state: Dictionary, cell: Vector2i) -> bool:
	var flare := Ability.aimed_at(state, Ability.FLARE)
	return not flare.is_empty() and Grid.chebyshev(Vector2i(int(flare[0]), int(flare[1])), cell) \
		<= int(GameData.ABILITY["radius_tiles"])


## Whether something burning stands on this cell. Sorted, as every walk of a
## Dictionary in the rules is, though an "any" no order could change.
static func _burning_on(state: Dictionary, cell: Vector2i) -> bool:
	var burning: Dictionary = state["burning"]
	if burning.is_empty():
		return false
	var ids: Array = burning.keys()
	ids.sort()
	for id in ids:
		if Entities.cell_of(state, int(id)) == cell:
			return true
	return false
