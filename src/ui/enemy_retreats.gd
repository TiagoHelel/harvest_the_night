class_name EnemyRetreats
extends RefCounted

## Dawn, seen from the yard: whoever the night left standing turns its back on
## the house and walks off the farm.
##
## **Cosmetic, like `EnemyDeaths`.** The rules take the survivors of a lost
## night off the farm on the tick the day begins (`Enemies.withdraw()`); this
## keeps a picture of each one walking away from the house - quicker than it
## came, fading as the light comes up - so the morning is them leaving rather
## than them vanishing. Nothing here is saved, hashed or waited on.

const CAP := 48
## How long the walk off lasts, in seconds. About the length of the dawn
## change itself, so they are gone when the light has settled.
const SECONDS := 2.4
## The share of the walk that is walking before it starts to fade.
const FADE_FROM := 0.35
## How much quicker than their night pace: a shamble with somewhere to be.
const HURRY := 1.5

var _before: Dictionary = {}
var _phase := -1
var _tick := -1
var _cues: Array[Dictionary] = []


func clear() -> void:
	_before.clear()
	_cues.clear()
	_phase = -1
	_tick = -1


## Only a result screen with somebody still in the yard is worth a look: the
## day begins from RESULT and from nowhere else.
func before_tick(state: Dictionary, motion: EnemyMotion) -> void:
	_before.clear()
	_tick = int(state["tick"])
	_phase = int(state["phase"])
	if _phase != Phases.RESULT or Entities.count(state) == 0:
		return
	for id in Entities.ids(state):
		var one := Entities.get_one(state, int(id))
		_before[int(id)] = {"kind": StringName(one["kind"]),
			"pos": Vector2(float(one["pos"][0]), float(one["pos"][1])),
			"right": motion.faces_right(one)}


func after_tick(state: Dictionary) -> void:
	if _phase == Phases.RESULT and int(state["phase"]) == Phases.DAY \
			and int(state["tick"]) == _tick + 1:
		var house := Farm.house_centre(state)
		var home := Vector2(house) * float(Player.SUBTILE) \
			+ Vector2.ONE * float(Player.SUBTILE / 2)
		var ids: Array = _before.keys()
		ids.sort()
		for id in ids:
			if Entities.alive(state, int(id)):
				continue
			var before: Dictionary = _before[id]
			var from: Vector2 = before["pos"]
			# **Away from the house**, the one direction that cannot walk
			# them through it. One standing on its centre leaves the way it
			# was facing.
			var away := from - home
			if away.length() < 1.0:
				away = Vector2.RIGHT if bool(before["right"]) else Vector2.LEFT
			var data: Dictionary = GameData.ENEMIES.get(before["kind"], {})
			var per_tile := maxi(int(data.get("ticks_per_tile", 20)), 1)
			if _cues.size() == CAP:
				_cues.pop_front()
			_cues.append({"kind": before["kind"], "from": from,
				"way": away.normalized(),
				"speed": float(Player.SUBTILE) * float(GameData.TICK_HZ)
					/ float(per_tile) * HURRY,
				"right": away.x > 0.0 if absf(away.x) > 0.01
					else bool(before["right"]),
				"age": 0.0})
	_before.clear()
	_tick = -1


func advance(delta: float) -> void:
	for i in range(_cues.size() - 1, -1, -1):
		var cue: Dictionary = _cues[i]
		cue["age"] = float(cue["age"]) + maxf(delta, 0.0)
		if float(cue["age"]) >= SECONDS:
			_cues.remove_at(i)


## How far it has walked, in the rules' subtile units.
static func travelled(cue: Dictionary) -> float:
	return float(cue["speed"]) * float(cue["age"])


## Where its feet are, in subtile units, for `ArtPlacement.contact()`.
static func position(cue: Dictionary) -> Array:
	var at: Vector2 = cue["from"] + cue["way"] * travelled(cue)
	return [at.x, at.y]


## The walk the night used, stepped by distance the same way: a frame every
## quarter tile.
static func pose(cue: Dictionary) -> StringName:
	var frame := int(travelled(cue) / float(Player.SUBTILE / 4)) % 4
	return StringName("%s_walk_%d" % [cue["kind"], frame])


## 1 while it is walking, down to 0 as the light takes it.
static func alpha(cue: Dictionary) -> float:
	var through := float(cue["age"]) / SECONDS
	return 1.0 - clampf((through - FADE_FROM) / (1.0 - FADE_FROM), 0.0, 1.0)
