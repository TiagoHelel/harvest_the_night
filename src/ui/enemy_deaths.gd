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
			# A tracked kind's, and since task 0262 a flyer's fall (A048's
			# crow), which has its own poses in the air.
			if not EnemyMotion.tracks(before["kind"]) and not Enemies.flies(before["kind"]):
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
		# Five for a boss in the Giant's poses (task 0246), and otherwise as
		# many as its art draws - four, the rat's three (task 0261).
		var frames := 5 if EnemyMotion.posed_boss(cue["kind"]) else death_frames(cue["kind"])
		if float(cue["age"]) >= frames * FRAME_SECONDS:
			_cues.remove_at(i)


## How many death frames a kind's art draws (task 0261): counted off the
## art, four when it says nothing.
static func death_frames(kind: StringName) -> int:
	var count := 0
	while not PlaceholderArt.frame(WorldView.ENEMY_DIR + "%s_death_%d.png" % [kind, count]).is_empty():
		count += 1
	return count if count > 0 else 4


static func pose(cue: Dictionary) -> StringName:
	return StringName("%s_death_%d" % [cue["kind"], int(float(cue["age"]) / FRAME_SECONDS)])
