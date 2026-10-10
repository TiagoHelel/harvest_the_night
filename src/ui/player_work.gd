class_name PlayerWork
extends RefCounted

## Presentation only. Anticipation follows the existing work timer; contact
## starts on the completion tick, then follow-through/recovery expire in the
## view. Instant verbs start at contact and finish with the ready pose. No
## event, timer, inventory or extra action is written into simulation/save data.
var _verb: StringName = &""
var _left := 0
var _total := 0
var _offered: StringName = &""
var _cell := Vector2i.ZERO
var _facing := Player.SOUTH
var _cancelled := false
var _watered := false
var _station := -1
var _produced_at := -1
var _cue: StringName = &""
var _cue_facing := Player.SOUTH
var _elapsed := 0.0
var _cue_seconds := 0.09
var _fresh := false
var _order: Array[int] = []


func reset() -> void:
	_cue = &""
	_order.clear()
	_elapsed = 0.0
	_fresh = false
	_verb = &""
	_left = 0
	_station = -1


func before_tick(state: Dictionary) -> void:
	var intent: Dictionary = state["intent"]
	var move: Array = intent["move"]
	_cancelled = bool(intent.get("cancel", false)) or int(move[0]) != 0 \
		or int(move[1]) != 0 or bool(intent.get("sleep", false))
	if _cancelled:
		reset()
	var action: Dictionary = state["player"]["action"]
	_verb = StringName(action.get("verb", &""))
	_left = int(action.get("left", 0))
	_total = int(action.get("total", 0))
	_cell = Player.target(state) if action.is_empty() else Vector2i(
		int(action["cell"][0]), int(action["cell"][1]))
	_offered = Interact.verb_at(state, _cell)
	_facing = Player.facing(state)
	if _verb == &"" and StringName(state["open_panel"]) == &"":
		if bool(intent.get("interact", false)) or \
				(bool(intent.get("interact_held", false)) and _offered == &"water"):
			_verb = _offered
			_left = Interact.ticks_for(state, _cell, _verb) if _verb != &"" else 0
			_total = _left
	_watered = bool((state["plots"] as Dictionary).get(Grid.index(_cell), {}).get("watered", false))
	_station = -1
	if not _cancelled and action.is_empty() and int(state["phase"]) == Phases.DAY:
		var on := Farm.occupant(state, _cell)
		if Crafting.is_station(StringName(on.get("id", &""))):
			_station = Grid.index(Building.anchor_of(state, _cell))
	_produced_at = int((state["produced"] as Dictionary).get(_station, {}).get("at", -1))


func after_tick(state: Dictionary) -> void:
	if _cancelled:
		return
	if _verb == &"water":
		var watered := bool((state["plots"] as Dictionary).get(Grid.index(_cell), {}).get("watered", false))
		if watered and not _watered:
			contact(&"water", _facing, true)
	elif _verb != &"" and _left == 1 and _offered == _verb:
		# The same transition observed by the core action loop, including a
		# repeat resetting its timer in this tick. Refused/invalid one-tick
		# fishing/shop requests do not manufacture a presentation cue.
		if _verb == &"trade" and StringName(state["open_panel"]) != &"shop":
			return
		if _verb == &"ship" and not Shipping.is_open(state):
			return
		if _verb == &"reel" and not (state["fishing"] as Dictionary).is_empty():
			return
		contact(_verb, _facing, _verb in [&"reel", &"trade", &"ship"])
	elif _station >= 0 and not Player.is_busy(state):
		var delivered := int((state["produced"] as Dictionary).get(_station, {}).get("at", -1))
		if delivered > _produced_at:
			# A nearby real station delivered an item. Carry illustrates that
			# existing result; it creates no physical crate or carrying rule.
			_cue = &"carry"
			_cue_facing = _facing
			_order.assign([0, 1, 2, 3])
			_elapsed = 0.0
			_cue_seconds = float(PlayerFrames.SECONDS[&"carry"])
			_fresh = true


func contact(verb: StringName, facing: int, instant: bool) -> void:
	_cue = verb
	_cue_facing = facing
	_order.assign([1, 2, 3, 0] if instant else [1, 2, 3])
	# A repair may repeat every three ticks. Its return must fit inside that
	# existing cycle, otherwise every new hit would erase follow-through.
	# The strip the verb plays (`PlayerArt.VERBS`): its own, or since task
	# 0185 a borrowed one - digging a truffle plays the collect strip.
	_cue_seconds = float(PlayerFrames.SECONDS[PlayerArt.VERBS.get(verb, verb)])
	if not instant:
		_cue_seconds = minf(_cue_seconds, float(maxi(_total, 1)) / GameData.TICK_HZ / 4.0)
	_elapsed = 0.0
	_fresh = true


func pose(state: Dictionary, delta: float) -> Dictionary:
	var move: Array = state["intent"]["move"]
	if int(move[0]) != 0 or int(move[1]) != 0:
		reset()
		return {}
	var action: Dictionary = state["player"]["action"]
	var active: StringName = StringName(action.get("verb", &""))
	if _cue != &"" and ((active != &"" and active != _cue) or \
			(Interact.DAY_ONLY.has(_cue) and int(state["phase"]) != Phases.DAY)):
		_cue = &""
	if _cue != &"":
		var cue_pose := PlayerArt.pose(_cue_facing, false, _cue)
		cue_pose["seconds"] = _cue_seconds
		if not _fresh:
			_elapsed += maxf(delta, 0.0)
		_fresh = false
		var phase := int(floorf((_elapsed + 0.000001) / float(cue_pose["seconds"])))
		if phase < _order.size():
			cue_pose["frame"] = _order[phase]
			return cue_pose
		_cue = &""
	if active != &"":
		var active_pose := PlayerArt.pose(Player.facing(state), false, active)
		active_pose["frame"] = 0
		return active_pose
	# Casting finishes the player's action, but the line remains in the water.
	# Keep the existing rod-ready drawing until a catch, miss or cancellation.
	if int(state["phase"]) == Phases.DAY and Fishing.is_casting(state):
		var waiting := PlayerArt.pose(Player.facing(state), false, &"reel")
		waiting["frame"] = 0
		return waiting
	return {}


## A019's head ramps: the view maps fixed steel pixels without editing art/state.
const TOOL_VERBS := {&"till": &"hoe", &"water": &"can", &"chop": &"axe",
	&"mine": &"pickaxe", &"fish": &"rod", &"reel": &"rod"}
const HEAD_RAMPS := {
	&"basic": [Color("3a3345"), Color("52505c"), Color("6e6c78")],
	&"iron": [Color("52505c"), Color("6e6c78"), Color("8c8a96")],
	&"gold": [Color("a8742c"), Color("c49646"), Color("d6ba60")],
	&"bamboo": [Color("a8742c"), Color("b8ae9a"), Color("d6ba60")],
	&"fibre": [Color("8a2f2a"), Color("b0423a"), Color("c9635a")],
}
var _head_materials: Dictionary = {}


func head_material(state: Dictionary, verb: StringName) -> ShaderMaterial:
	if not TOOL_VERBS.has(verb):
		return null
	var tool: StringName = TOOL_VERBS[verb]
	var name: StringName = ToolTiers.effects(state, tool)["name"]
	if not _head_materials.has(name):
		var material := ShaderMaterial.new()
		material.shader = load("res://src/ui/tool_head.gdshader")
		material.set_shader_parameter("head_dark", HEAD_RAMPS[name][0])
		material.set_shader_parameter("head_mid", HEAD_RAMPS[name][1])
		material.set_shader_parameter("head_light", HEAD_RAMPS[name][2])
		_head_materials[name] = material
	return _head_materials[name]
