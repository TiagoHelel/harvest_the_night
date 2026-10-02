class_name EnemyMotion
extends RefCounted

## Observation only: authored ordinary-enemy poses follow actual core deltas.
## No movement on a render frame, no invented damage, and no saved fields.
const FAMILIES: Array[StringName] = [&"walker", &"runner", &"tank", &"breaker"]
var _before: Dictionary = {}
var _actors: Dictionary = {}


func clear() -> void:
	_before.clear()
	_actors.clear()


func before_tick(state: Dictionary) -> void:
	_before.clear()
	for id in Entities.ids(state):
		var one := Entities.get_one(state, int(id))
		if not FAMILIES.has(one["kind"]):
			continue
		_before[int(id)] = {"pos": Vector2i(int(one["pos"][0]), int(one["pos"][1])),
			"wait": int(one.get("chew_wait", 0)), "tick": int(state["tick"])}


func after_tick(state: Dictionary) -> void:
	var alive: Dictionary = {}
	var tick := int(state["tick"])
	for id in Entities.ids(state):
		var one := Entities.get_one(state, int(id))
		if not FAMILIES.has(one["kind"]):
			continue
		var key := int(id)
		alive[key] = true
		var memo: Dictionary = _actors.get(key, {"travel": 0, "right": false, "strike": -1000, "moving": false})
		var pos := Vector2i(int(one["pos"][0]), int(one["pos"][1]))
		var previous: Dictionary = _before.get(key, {})
		if not previous.is_empty() and tick <= int(previous["tick"]):
			continue
		memo["moving"] = false
		memo["tick"] = tick
		memo["pos"] = pos
		if not previous.is_empty() and tick == int(previous["tick"]) + 1:
			var delta: Vector2i = pos - previous["pos"]
			memo["moving"] = delta != Vector2i.ZERO
			if delta != Vector2i.ZERO:
				memo["strike"] = -1000
				memo["travel"] = int(memo["travel"]) + absi(delta.x) + absi(delta.y)
				if delta.x != 0:
					memo["right"] = delta.x > 0
			elif int(one.get("chew_wait", 0)) > int(previous["wait"]) and int(one.get("chewing", -1)) >= 0:
				# The core has just dealt a real structure hit and set its wait.
				# Even a destroyed target gets the observed contact/recovery pose.
				memo["strike"] = tick
				memo["target"] = int(one["chewing"])
				memo["grid_version"] = int(state["grid_version"])
				var target := Grid.cell(int(one["chewing"]))
				var here := Vector2i(pos.x / Player.SUBTILE, pos.y / Player.SUBTILE)
				if target.x != here.x:
					memo["right"] = target.x > here.x
		_actors[key] = memo
	for key in _actors.keys():
		if not alive.has(key):
			_actors.erase(key)
	_before.clear()


func pose(one: Dictionary, state: Dictionary) -> StringName:
	var family: StringName = one["kind"]
	var memo: Dictionary = _actors.get(int(one["id"]), {})
	var tick := int(state["tick"])
	if memo.is_empty() or tick != int(memo["tick"]):
		return family
	if memo["pos"] != Vector2i(int(one["pos"][0]), int(one["pos"][1])):
		return family
	if bool(memo["moving"]):
		var frame := (int(memo["travel"]) / (Player.SUBTILE / 4)) % 4
		return StringName("%s_walk_%d" % [family, frame])
	var age := tick - int(memo["strike"])
	if age >= 0 and age < 5:
		return StringName("%s_attack_%d" % [family, 1 if age < 2 else 2])
	var wait := int(one.get("chew_wait", 0))
	var target := int(one.get("chewing", -1))
	if wait > 0 and wait <= 3 and target >= 0 and target == int(memo.get("target", -1)) and int(memo["strike"]) >= 0 and int(state["grid_version"]) == int(memo.get("grid_version", -1)):
		var cell := Grid.cell(target)
		var here := Vector2i(int(one["pos"][0]) / Player.SUBTILE, int(one["pos"][1]) / Player.SUBTILE)
		var on := Farm.occupant(state, cell)
		if absi(cell.x - here.x) + absi(cell.y - here.y) == 1 and not on.is_empty() and int(on.get("hp", 0)) > 0:
			# Anticipation uses the final three ticks of an existing core wait.
			return StringName("%s_attack_0" % family)
	return family


func faces_right(one: Dictionary) -> bool:
	return bool((_actors.get(int(one["id"]), {}) as Dictionary).get("right", false))
