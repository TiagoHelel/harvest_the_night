class_name EnemyDeaths
extends RefCounted

## Cosmetic snapshots only. No entity dictionaries survive a tick observation.
const CAP := 24
const FRAME_SECONDS := 0.12
var _before: Dictionary = {}
var _tick := -1
var _night := -1
var _cues: Array[Dictionary] = []


func clear() -> void:
	_before.clear()
	_cues.clear()
	_tick = -1
	_night = -1


func before_tick(state: Dictionary, motion: EnemyMotion) -> void:
	_before.clear()
	_tick = int(state["tick"])
	_night = int(state["phase"])
	if _night != Phases.NIGHT:
		return
	for id in Entities.ids(state):
		var one := Entities.get_one(state, int(id))
		# Only this tiny coordinate Array is borrowed during the core tick.
		# Enemies updates it in place before traps/projectiles can remove its id.
		# This captures the final moved position, without retaining an entity.
		_before[int(id)] = {"kind": StringName(one["kind"]), "coordinates": one["pos"],
			"right": motion.faces_right(one)}


func after_tick(state: Dictionary) -> void:
	if _night == Phases.NIGHT and int(state["tick"]) == _tick + 1 and int(state["phase"]) != Phases.DAY:
		for id in _before:
			if Entities.alive(state, int(id)):
				continue
			var before: Dictionary = _before[id]
			if not EnemyMotion.TRACKED.has(before["kind"]):
				continue
			var at: Array = before["coordinates"]
			if _cues.size() == CAP:
				_cues.pop_front()
			_cues.append({"kind": before["kind"], "pos": Vector2i(int(at[0]), int(at[1])),
				"right": bool(before["right"]), "age": 0.0})
	_before.clear()
	_tick = -1


func advance(delta: float) -> void:
	for i in range(_cues.size() - 1, -1, -1):
		var cue: Dictionary = _cues[i]
		cue["age"] = float(cue["age"]) + maxf(delta, 0.0)
		var frames := 5 if cue["kind"] == &"giant" else 4
		if float(cue["age"]) >= frames * FRAME_SECONDS:
			_cues.remove_at(i)


static func pose(cue: Dictionary) -> StringName:
	return StringName("%s_death_%d" % [cue["kind"], int(float(cue["age"]) / FRAME_SECONDS)])
