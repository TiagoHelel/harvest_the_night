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
	var lines: Array = [String(id).to_upper()]
	if GameData.SELL_PRICE.has(id):
		lines.append("sells for $%d" % int(GameData.SELL_PRICE[id]))
	else:
		# **Said rather than left blank.** "Not for sale" is a different
		# thing from "worth nothing", and a player who cannot tell which
		# will try to sell it.
		lines.append("not for sale")
	if Ammo.kinds().has(id):
		lines.append("loaded into towers")
	return "\n".join(lines)


static func defence(id: StringName) -> String:
	var entry: Variant = GameData.DEFENCES.get(id, null)
	if entry == null:
		return ""
	var one: Dictionary = entry
	var lines: Array = [String(id).to_upper().replace("_", " ")]
	lines.append(_costs(one.get("cost", {}) as Dictionary))
	lines.append("%d hit points" % int(one.get("hp", 0)))
	if one.has("damage"):
		lines.append("%d %s damage" % [int(one["damage"]),
			String(one.get("damage_type", GameData.DAMAGE_IMPACT))])
	if one.has("range"):
		lines.append("reaches %d tiles" % int(one["range"]))
	if int(one.get("reload_ticks", 0)) > 0:
		lines.append("fires every %s" % _seconds(int(one["reload_ticks"])))
	if int(one.get("energy_draw", 0)) > 0:
		lines.append("draws %d power" % int(one["energy_draw"]))
	if int(one.get("path_cost", 0)) > 0:
		lines.append("things walk round it if they can")
	if bool(one.get("one_shot", false)):
		lines.append("goes off once")
	return "\n".join(lines)


static func building(id: StringName) -> String:
	var entry: Variant = GameData.BUILDINGS.get(id, null)
	if entry == null:
		return ""
	var one: Dictionary = entry
	var lines: Array = [String(id).to_upper().replace("_", " ")]
	lines.append(_costs(one.get("cost", {}) as Dictionary))
	lines.append("%d hit points" % int(one.get("hp", 0)))
	if int(one.get("energy_supply", 0)) > 0:
		lines.append("supplies %d power" % int(one["energy_supply"]))
	if int(one.get("energy_draw", 0)) > 0:
		lines.append("draws %d power" % int(one["energy_draw"]))
	var makes := _recipes_at(id)
	if not makes.is_empty():
		lines.append("makes %s" % ", ".join(makes))
	return "\n".join(lines)


static func recipe(id: StringName) -> String:
	var entry: Variant = GameData.RECIPES.get(id, null)
	if entry == null:
		return ""
	var one: Dictionary = entry
	var lines: Array = [String(id).to_upper().replace("_", " ")]
	lines.append("from %s" % _costs(one.get("inputs", {}) as Dictionary))
	lines.append("makes %s" % _amounts(one.get("output", {}) as Dictionary))
	lines.append("takes %s" % _seconds(int(one.get("ticks", 0))))
	lines.append("at the %s" % String(one.get("station", &"")).replace(
		"_", " "))
	return "\n".join(lines)


static func tech(id: StringName) -> String:
	var one := Tech.node(id)
	if one.is_empty():
		return ""
	var lines: Array = [String(id).to_upper()]
	lines.append("costs %d tech" % int(one.get("cost", 0)))
	lines.append(String(one.get("note", "")))
	var needs: Array = one.get("needs", []) as Array
	if not needs.is_empty():
		lines.append("after %s" % ", ".join(needs))
	return "\n".join(lines)


static func enemy(id: StringName) -> String:
	var entry: Variant = GameData.ENEMIES.get(id, null)
	if entry == null:
		return ""
	var one: Dictionary = entry
	var lines: Array = [String(id).to_upper()]
	lines.append("%d hit points" % int(one.get("hp", 0)))
	lines.append("hits for %d" % int(one.get("damage", 0)))
	lines.append("a tile every %s" % _seconds(int(one.get(
		"ticks_per_tile", 0))))
	if int(one.get("armour", 0)) > 0:
		lines.append("shrugs off %d a hit" % int(one["armour"]))
	if bool(one.get("targets_structures", false)):
		lines.append("chews through walls")
	if bool(one.get("ignores_structures", false)):
		lines.append("runs straight past walls")
	if bool(one.get("is_boss", false)):
		lines.append("winds up before it swings")
	lines.append("worth $%d" % int(one.get("reward", 0)))
	return "\n".join(lines)


static func crop(id: StringName) -> String:
	var entry: Variant = GameData.CROPS.get(id, null)
	if entry == null:
		return ""
	var one: Dictionary = entry
	var lines: Array = [String(id).to_upper()]
	lines.append("seed costs $%d" % int(one.get("seed_cost", 0)))
	lines.append("grows in %s" % _seconds(int(one.get("growth_ticks", 0))))
	lines.append("sells for $%d" % int(GameData.SELL_PRICE.get(id, 0)))
	return "\n".join(lines)


# ------------------------------------------------------------------ the parts

## A cost, as "4 wood, 2 iron". Sorted, so it reads the same every time.
static func _costs(cost: Dictionary) -> String:
	if cost.is_empty():
		return "free"
	return "costs %s" % _amounts(cost)


static func _amounts(amounts: Dictionary) -> String:
	var parts: Array = []
	for id in GameData.sorted_names(amounts.keys()):
		parts.append("%d %s" % [int(amounts[id]), id])
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
			out.append(String(id).replace("_", " "))
	return out
