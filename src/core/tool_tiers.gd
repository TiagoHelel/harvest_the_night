class_name ToolTiers
extends RefCounted

## Permanent ladders, outside the loss/sale ledger. Finished upgrades wait for dawn.
static func initial() -> Dictionary:
	var held := {"pending": {}}
	for tool in GameData.sorted_names(GameData.TOOLS.keys()):
		held[String(tool)] = 0
	return {"tools": held}


static func tier(state: Dictionary, tool: StringName) -> int:
	return int(state["tools"].get(String(tool), 0))


## The current tier's effects, for the systems that consume them.
static func effects(state: Dictionary, tool: StringName) -> Dictionary:
	return GameData.TOOLS[tool][tier(state, tool)]


static func item(tool: StringName, level: int) -> StringName:
	return StringName("%s_%s" % [tool, GameData.TOOLS[tool][level]["name"]])


## An upgrade being made anywhere blocks another order for the same tool.
static func queued(state: Dictionary, tool: StringName) -> bool:
	var crafting: Dictionary = state["crafting"]
	var cells: Array = crafting.keys()
	cells.sort()
	for cell in cells:
		for recipe_id in crafting[cell]["queue"]:
			var recipe: Dictionary = GameData.RECIPES[recipe_id]
			for out in GameData.sorted_names(recipe["output"].keys()):
				if GameData.tool_output(out).get("tool", &"") == tool:
					return true
	return false


## A Building-shaped refusal, shared by the workshop and its input path.
static func why_not(state: Dictionary, recipe_id: StringName) -> Array:
	var recipe: Dictionary = GameData.RECIPES[recipe_id]
	if recipe["output"].size() != 1:
		return []
	var target := GameData.tool_output(StringName(recipe["output"].keys()[0]))
	if target.is_empty():
		return []
	var tool: StringName = target["tool"]
	var level: int = target["tier"]
	if int(state["phase"]) != Phases.DAY:
		return [&"WHY_AFTER_DARK"]
	if not bool(GameData.TOOLS[tool][level]["enabled"]):
		return [&"WHY_TOOL_GOLD_LOCKED"]
	if tier(state, tool) >= level:
		return [&"WHY_TOOL_OWNED"]
	if tier(state, tool) + 1 != level:
		return [&"WHY_TOOL_PREVIOUS"]
	if state["tools"]["pending"].has(String(tool)) or queued(state, tool):
		return [&"WHY_TOOL_PENDING"]
	if not Resources.can_afford(state, recipe["inputs"]):
		return [&"WHY_SHORT", Resources.missing(state, recipe["inputs"])]
	return []


## Called only when the workshop completes the recipe; the old tool remains usable.
static func deliver(state: Dictionary, output: StringName) -> void:
	var target := GameData.tool_output(output)
	state["tools"]["pending"][String(target["tool"])] = {
		"tier": int(target["tier"]), "ready_day": int(state["day"]) + 1}


## Hand over completed upgrades once, including after a lost night.
static func morning(state: Dictionary) -> void:
	var pending: Dictionary = state["tools"]["pending"]
	for tool in GameData.sorted_names(GameData.TOOLS.keys()):
		var key := String(tool)
		if pending.has(key) and int(pending[key]["ready_day"]) <= int(state["day"]):
			state["tools"][key] = maxi(tier(state, tool), int(pending[key]["tier"]))
			pending.erase(key)
