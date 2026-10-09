class_name Describe
extends RefCounted

## What everything in the game is, in words, built from `game_data` every time.
##
## **Never a copy of a number.** Every figure in every line below is read out
## of `GameData` at the moment the tooltip is asked for, so changing a
## `# LEVER` changes what the player is told and nothing else has to be
## edited. That is task 0089's second requirement and its second done-when,
## and `headless_check` holds it to it: for every describable thing it takes
## the live number and asserts the text says it.
##
## ## The key is `kind:id`
##
## A control that wants explaining carries `set_meta(&"describes", key)` and
## `tooltip.gd` resolves it here. One string, so a button has nothing to
## remember and a panel has no describing code in it at all.
##
## ## It owns no rules and reads no state
##
## Everything here is static and takes no `state`: a tooltip describes what a
## thing *is*, not how much of it you have. That keeps it out of the way of
## the determinism hash entirely and makes every line of it testable without
## building a game.
##
## **One exception, read-only: `under_cursor`** (task 0131). The guardian's
## cursor says how this wall is doing tonight - its hit points against its
## levelled maximum - and that is the live state's to say. It reads, never
## writes, so the hash still cannot tell it was asked.

## The kinds a key can name, and what each one looks up.
const KINDS: Array = [
	&"resource", &"defence", &"building", &"recipe", &"tech", &"enemy",
	&"crop",
]


## The text for a key like `&"defence:gun_tower"`, or empty when there is
## nothing to say.
static func of(key: StringName) -> String:
	var parts := String(key).split(":", true, 1)
	if parts.size() != 2:
		return ""
	var kind := StringName(parts[0])
	var id := StringName(parts[1])
	match kind:
		&"resource": return resource(id)
		&"defence": return defence(id)
		&"building": return building(id)
		&"recipe": return recipe(id)
		&"tech": return tech(id)
		&"enemy": return enemy(id)
		&"crop": return crop(id)
		# **Words already said** (task 0139): a control whose explanation
		# changes with the state - the night HUD's SKIP and its refusal -
		# carries them whole, and they are shown as they are.
		&"text": return String(parts[1])
	return ""


## Every key the game can describe, for the check that nothing is missing.
static func every_key() -> Array:
	var out: Array = []
	for id in GameData.RESOURCES:
		out.append(StringName("resource:%s" % id))
	for id in GameData.sorted_names(GameData.DEFENCES.keys()):
		out.append(StringName("defence:%s" % id))
	for id in GameData.sorted_names(GameData.BUILDINGS.keys()):
		out.append(StringName("building:%s" % id))
	for id in GameData.sorted_names(GameData.RECIPES.keys()):
		out.append(StringName("recipe:%s" % id))
	for row in GameData.TECH_TREE:
		out.append(StringName("tech:%s" % (row as Dictionary)["id"]))
	for id in GameData.sorted_names(GameData.ENEMIES.keys()):
		out.append(StringName("enemy:%s" % id))
	for id in GameData.sorted_names(GameData.CROPS.keys()):
		out.append(StringName("crop:%s" % id))
	return out


# ------------------------------------------------------------------- the text

static func resource(id: StringName) -> String:
	if not GameData.RESOURCES.has(id):
		return ""
	var lines: Array = [Names.of(id).to_upper()]
	if GameData.SELL_PRICE.has(id):
		lines.append(I18n.f(&"DESC_SELLS_FOR",
			[int(GameData.SELL_PRICE[id])]))
	else:
		# **Said rather than left blank.** "Not for sale" is a different
		# thing from "worth nothing", and a player who cannot tell which
		# will try to sell it.
		lines.append(I18n.t(&"DESC_NOT_FOR_SALE"))
	if Ammo.kinds().has(id):
		lines.append(I18n.t(&"DESC_AMMO"))
	return "\n".join(lines)


static func defence(id: StringName) -> String:
	var entry: Variant = GameData.DEFENCES.get(id, null)
	if entry == null:
		return ""
	var one: Dictionary = entry
	var lines: Array = [Names.of(id).to_upper()]
	lines.append(_costs(one.get("cost", {}) as Dictionary))
	lines.append(I18n.f(&"DESC_HP", [int(one.get("hp", 0))]))
	if one.has("damage"):
		lines.append(I18n.f(&"DESC_DAMAGE", [int(one["damage"]),
			Names.of(StringName(one.get("damage_type",
				GameData.DAMAGE_IMPACT)))]))
	if one.has("range"):
		lines.append(I18n.f(&"DESC_RANGE", [int(one["range"])]))
	if int(one.get("reload_ticks", 0)) > 0:
		lines.append(I18n.f(&"DESC_RELOAD",
			[_seconds(int(one["reload_ticks"]))]))
	if int(one.get("energy_draw", 0)) > 0:
		lines.append(I18n.f(&"DESC_DRAWS", [int(one["energy_draw"])]))
	if int(one.get("path_cost", 0)) > 0:
		lines.append(I18n.t(&"DESC_BLOCKS"))
	if bool(one.get("one_shot", false)):
		lines.append(I18n.t(&"DESC_ONE_SHOT"))
	return "\n".join(lines)


static func building(id: StringName) -> String:
	var entry: Variant = GameData.BUILDINGS.get(id, null)
	if entry == null:
		return ""
	var one: Dictionary = entry
	var lines: Array = [Names.of(id).to_upper()]
	lines.append(_costs(one.get("cost", {}) as Dictionary))
	lines.append(I18n.f(&"DESC_HP", [int(one.get("hp", 0))]))
	if int(one.get("energy_supply", 0)) > 0:
		lines.append(I18n.f(&"DESC_SUPPLIES",
			[int(one["energy_supply"])]))
	if int(one.get("energy_draw", 0)) > 0:
		lines.append(I18n.f(&"DESC_DRAWS", [int(one["energy_draw"])]))
	var makes := _recipes_at(id)
	if not makes.is_empty():
		lines.append(I18n.f(&"DESC_MAKES", [", ".join(makes)]))
	return "\n".join(lines)


static func recipe(id: StringName) -> String:
	var entry: Variant = GameData.RECIPES.get(id, null)
	if entry == null:
		return ""
	var one: Dictionary = entry
	var lines: Array = [Names.of(id).to_upper()]
	lines.append(I18n.f(&"DESC_FROM",
		[_costs(one.get("inputs", {}) as Dictionary)]))
	lines.append(I18n.f(&"DESC_MAKES",
		[_amounts(one.get("output", {}) as Dictionary)]))
	lines.append(I18n.f(&"DESC_TAKES",
		[_seconds(int(one.get("ticks", 0)))]))
	lines.append(I18n.f(&"DESC_AT_THE",
		[Names.of(StringName(one.get("station", &"")))]))
	return "\n".join(lines)


static func tech(id: StringName) -> String:
	var one := Tech.node(id)
	if one.is_empty():
		return ""
	var lines: Array = [Names.of(id).to_upper()]
	lines.append(I18n.f(&"DESC_TECH_COST", [int(one.get("cost", 0))]))
	lines.append(Names.note_of(id))
	var needs: Array = one.get("needs", []) as Array
	if not needs.is_empty():
		lines.append(I18n.f(&"DESC_AFTER", [_named(needs)]))
	return "\n".join(lines)


static func enemy(id: StringName) -> String:
	var entry: Variant = GameData.ENEMIES.get(id, null)
	if entry == null:
		return ""
	var one: Dictionary = entry
	var lines: Array = [Names.of(id).to_upper()]
	lines.append(I18n.f(&"DESC_HP", [int(one.get("hp", 0))]))
	lines.append(I18n.f(&"DESC_HITS_FOR",
		[int(one.get("damage", 0))]))
	lines.append(I18n.f(&"DESC_TILE_EVERY", [_seconds(int(one.get(
		"ticks_per_tile", 0)))]))
	if int(one.get("armour", 0)) > 0:
		lines.append(I18n.f(&"DESC_ARMOUR", [int(one["armour"])]))
	if bool(one.get("targets_structures", false)):
		lines.append(I18n.t(&"DESC_EATS_WALLS"))
	if bool(one.get("ignores_structures", false)):
		lines.append(I18n.t(&"DESC_PASSES_WALLS"))
	if bool(one.get("is_boss", false)):
		lines.append(I18n.t(&"DESC_WINDS_UP"))
	lines.append(I18n.f(&"DESC_WORTH", [int(one.get("reward", 0))]))
	return "\n".join(lines)


## What is under the guardian's cursor (task 0131): an enemy first - it is
## what matters at night - then a structure with its hit points against its
## levelled maximum and its level, or open ground. Empty for what has no name
## to give (a tree, a rock).
static func under_cursor(state: Dictionary, cell: Vector2i) -> String:
	if state.is_empty() or not Grid.in_bounds(cell):
		return ""
	for id in Entities.ids(state):
		if Entities.cell_of(state, id) == cell:
			var one := Entities.get_one(state, id)
			return I18n.f(&"CURSOR_ENEMY", [Names.of(StringName(one["kind"])).to_upper(),
				int(one["hp"])])
	var anchor := Building.anchor_of(state, cell)
	var on := Farm.occupant(state, anchor)
	if on.is_empty():
		return I18n.t(&"CURSOR_GROUND")
	var id := StringName(on["id"])
	if id == Repair.HOUSE:
		return I18n.f(&"CURSOR_STRUCTURE", [I18n.t(&"CURSOR_HOUSE"),
			int(state["house_hp"]), Phases.house_full(state), Building.level_at(state, anchor)])
	if Building.entry_of(id) == null:
		return ""
	var full := Repair.full_hp_at(state, anchor)
	return I18n.f(&"CURSOR_STRUCTURE", [Names.of(id).to_upper(),
		int(on.get("hp", full)), full, Building.level_at(state, anchor)])


## **What mending this costs** (task 0134), for the cursor's tooltip: the
## whole repair at today's price (`Repair.cost_at`, the house at its own
## percent) and how many of its missing hit points the ledger covers now
## (`Repair.max_affordable`). Read-only, like `under_cursor`.
static func repair_line(state: Dictionary, cell: Vector2i) -> String:
	var missing := Repair.damage_at(state, cell)
	return I18n.f(&"CURSOR_REPAIR", [_amounts(Repair.cost_at(state, cell, missing)),
		Repair.max_affordable(state, cell), missing])


static func crop(id: StringName) -> String:
	var entry: Variant = GameData.CROPS.get(id, null)
	if entry == null:
		return ""
	var one: Dictionary = entry
	var lines: Array = [Names.of(id).to_upper()]
	lines.append(I18n.f(&"DESC_SEED_COST",
		[int(one.get("seed_cost", 0))]))
	lines.append(I18n.f(&"DESC_GROWS_IN",
		[int(one.get("growth_days", 0))]))
	lines.append(I18n.f(&"DESC_SELLS_FOR",
		[int(GameData.SELL_PRICE.get(id, 0))]))
	return "\n".join(lines)


# ------------------------------------------------------------------ the parts

## A cost, as "4 wood, 2 iron". Sorted, so it reads the same every time.
## A list of ids as a list of names, so "after sharp tools" reads as
## "depois de ferramentas afiadas" rather than as an id.
static func _named(ids: Array) -> String:
	var parts: Array = []
	for id in ids:
		parts.append(Names.of(StringName(id)))
	return ", ".join(parts)


static func _costs(cost: Dictionary) -> String:
	if cost.is_empty():
		return I18n.t(&"DESC_FREE")
	return I18n.f(&"DESC_COSTS", [_amounts(cost)])


static func _amounts(amounts: Dictionary) -> String:
	var parts: Array = []
	for id in GameData.sorted_names(amounts.keys()):
		parts.append(I18n.f(&"DESC_AMOUNT",
			[int(amounts[id]), Names.of(id)]))
	return ", ".join(parts)


## Ticks as seconds, which is the only unit a player has. One decimal place,
## because "1s" and "1.5s" are a real difference to somebody deciding whether
## to run.
static func _seconds(ticks: int) -> String:
	return "%.1fs" % (float(ticks) / float(GameData.TICK_HZ))


static func _recipes_at(station: StringName) -> Array:
	var out: Array = []
	for id in GameData.sorted_names(GameData.RECIPES.keys()):
		if (GameData.RECIPES[id] as Dictionary).get("station", &"") == station:
			out.append(Names.of(id))
	return out
