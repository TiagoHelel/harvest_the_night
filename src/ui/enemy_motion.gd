class_name EnemyMotion
extends RefCounted

## Observation only: authored ordinary-enemy poses follow actual core deltas.
## No movement on a render frame, no invented damage, and no saved fields.
##
## **A boss moves in the Giant's pose names** (task 0246) - `<kind>_walk_0..3`,
## `<kind>_windup_0..2`, `<kind>_slam_0..2` and five `<kind>_death_N` - once
## its art has them (`posed_boss`). A boss with none drawn yet falls back to
## the ordinary path, as any family this does not track; the Giant draws
## exactly as before.
## The rat since task 0261 (A047): its scurry by the distance it runs, its
## bite off the rules' own hit, its death played on.
## The digger since task 0263 (A049): its burrow on the tick the rules put it
## under, its mound while it stays there, its emergence when it comes up.
## The frost zombie since task 0264 (A050), as the four walk and bite.
## The wraith since task 0265 (A051), its float as the walk.
const FAMILIES: Array[StringName] = [&"walker", &"runner", &"tank", &"breaker", &"rat", &"digger", &"frost_zombie",
	&"wraith"]
## The ticks a boss's slam shows, its three frames.
const SLAM_TICKS := 9
var _before: Dictionary = {}
var _actors: Dictionary = {}
## Whether each boss kind has the Giant's poses drawn, asked once.
static var _posed: Dictionary = {}


## **Whether this follows a kind's authored poses**: the four ordinary
## families, and a boss drawn in the Giant's pose names.
static func tracks(kind: StringName) -> bool:
	return FAMILIES.has(kind) or posed_boss(kind)


## Every kind this follows, the ordinary four first and then the posed
## bosses by name - the Giant today.
static func tracked() -> Array[StringName]:
	var out: Array[StringName] = FAMILIES.duplicate()
	for kind in GameData.sorted_names(GameData.ENEMIES.keys()):
		if posed_boss(StringName(kind)):
			out.append(StringName(kind))
	return out


## **`tracked()` under its old name**, which was a constant until task 0246:
## the FHD pilots' captures in `implementation/fhd-player/` still spawn their
## lineup off it. Read on use, so it names no boss of its own.
static var TRACKED: Array[StringName]:
	get:
		return tracked()


## **A boss drawn in the Giant's pose names** (task 0246): `is_boss`, and its
## first wind-up frame on disk.
static func posed_boss(kind: StringName) -> bool:
	if not _posed.has(kind):
		_posed[kind] = Combat.is_boss(kind) \
			and ResourceLoader.exists(WorldView.ENEMY_DIR + "%s_windup_0.png" % kind)
	return bool(_posed[kind])


func clear() -> void:
	_before.clear()
	_actors.clear()


func before_tick(state: Dictionary) -> void:
	_before.clear()
	for id in Entities.ids(state):
		var one := Entities.get_one(state, int(id))
		if not tracks(one["kind"]):
			continue
		_before[int(id)] = {"pos": Vector2i(int(one["pos"][0]), int(one["pos"][1])),
			"wait": int(one.get("chew_wait", 0)), "winding": int(one.get("winding_at", -1)), "tick": int(state["tick"])}


func after_tick(state: Dictionary) -> void:
	var alive: Dictionary = {}
	var tick := int(state["tick"])
	for id in Entities.ids(state):
		var one := Entities.get_one(state, int(id))
		if not tracks(one["kind"]):
			continue
		var posed := posed_boss(one["kind"])
		var key := int(id)
		alive[key] = true
		var memo: Dictionary = _actors.get(key, {"travel": 0, "right": false, "strike": -1000, "moving": false,
			"under": false, "turned": -1000})
		# **Going under or coming up** (task 0263): the tick it turned.
		var under := Enemies.underground(state, key)
		if bool(memo.get("under", false)) != under:
			memo["turned"] = tick
		memo["under"] = under
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
				if not posed or tick - int(memo["strike"]) >= SLAM_TICKS:
					memo["strike"] = -1000
				memo["travel"] = int(memo["travel"]) + absi(delta.x) + absi(delta.y)
				if delta.x != 0:
					memo["right"] = delta.x > 0
			elif int(one.get("chew_wait", 0)) > int(previous["wait"]) and int(one.get("chewing", -1)) >= 0 and (not posed or int(previous["winding"]) == int(one.get("winding_at", -1)) and int(one["chewing"]) == int(one.get("winding_at", -1))):
				# The core has just dealt a real structure hit and set its wait.
				# Even a destroyed target gets the observed contact/recovery pose.
				memo["strike"] = tick
				memo["target"] = int(one["chewing"])
				memo["grid_version"] = int(state["grid_version"])
				var target := Grid.cell(int(one["chewing"]))
				var here := Vector2i(pos.x / Player.SUBTILE, pos.y / Player.SUBTILE)
				if target.x != here.x:
					memo["right"] = target.x > here.x
		if posed and not bool(memo["moving"]):
			var aimed := Enemies.winding_at(state, key)
			var here := Vector2i(pos.x / Player.SUBTILE, pos.y / Player.SUBTILE)
			if aimed.x >= 0 and aimed.x != here.x:
				memo["right"] = aimed.x > here.x
		_actors[key] = memo
	for key in _actors.keys():
		if not alive.has(key):
			_actors.erase(key)
	_before.clear()


func pose(one: Dictionary, state: Dictionary) -> StringName:
	var family: StringName = one["kind"]
	var memo: Dictionary = _actors.get(int(one["id"]), {})
	var tick := int(state["tick"])
	if posed_boss(family):
		return _boss_pose(one, state, memo)
	var burrowing := _burrow_pose(one, state, memo)
	if burrowing != &"":
		return burrowing
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


## **A burrower's turn** (task 0263, A049's digger): under ground, its burrow
## for the four frames after it went under and then its mound, round and
## round on its frame's seconds; just up, its emergence; `&""` otherwise, or
## for a kind with no burrow drawn.
func _burrow_pose(one: Dictionary, state: Dictionary, memo: Dictionary) -> StringName:
	var kind: StringName = one["kind"]
	if not PlaceholderArt.has_frame(WorldView.ENEMY_DIR + "%s_burrow_0.png" % kind):
		return &""
	var tick := int(state["tick"])
	var age := tick - int(memo.get("turned", -1000))
	var each := maxi(roundi(float(PlaceholderArt.frame(WorldView.ENEMY_DIR + "%s_burrow_0.png" % kind)
		.get("seconds", 0.1)) * float(GameData.TICK_HZ)), 1)
	if Enemies.underground(state, int(one["id"])):
		if age >= 0 and age < each * 4:
			return StringName("%s_burrow_%d" % [kind, age / each])
		var mound := maxi(roundi(float(PlaceholderArt.frame(WorldView.ENEMY_DIR + "%s_mound_0.png" % kind)
			.get("seconds", 0.125)) * float(GameData.TICK_HZ)), 1)
		return StringName("%s_mound_%d" % [kind, (tick / mound + int(one["id"])) % 3])
	if age >= 0 and age < each * 4 and not memo.is_empty() and not bool(memo.get("under", false)):
		return StringName("%s_emerge_%d" % [kind, age / each])
	return &""


## A boss in the Giant's pose names (task 0246): its slam for `SLAM_TICKS`
## from a real hit, its walk by real distance, its wind-up through its own
## `telegraph_ticks` at an adjacent target - and its standing body otherwise.
func _boss_pose(one: Dictionary, state: Dictionary, memo: Dictionary) -> StringName:
	var kind: StringName = one["kind"]
	var current: bool = not memo.is_empty() and int(memo["tick"]) == int(state["tick"]) and memo["pos"] == Vector2i(int(one["pos"][0]), int(one["pos"][1]))
	var age := int(state["tick"]) - int(memo.get("strike", -1000))
	if current and age >= 0 and age < SLAM_TICKS:
		return StringName("%s_slam_%d" % [kind, age / 3])
	if current and bool(memo["moving"]):
		return StringName("%s_walk_%d" % [kind, (int(memo["travel"]) / (Player.SUBTILE / 4)) % 4])
	var target := Enemies.winding_at(state, int(one["id"]))
	if target.x >= 0:
		var here := Vector2i(int(one["pos"][0]) / Player.SUBTILE, int(one["pos"][1]) / Player.SUBTILE)
		var on := Farm.occupant(state, target)
		if Grid.manhattan(here, target) <= 1 and not on.is_empty() and (on.get("id", &"") == &"house" or int(on.get("hp", 0)) > 0):
			var full := maxi(int((GameData.ENEMIES[kind] as Dictionary).get("telegraph_ticks", 0)), 1)
			var elapsed := maxi(full - int(one.get("chew_wait", 0)), 0)
			return StringName("%s_windup_%d" % [kind, mini(elapsed * 3 / full, 2)])
	return kind


## Whether a body's pose is a boss's wind-up - the moment the ring under its
## target shows (task 0246: any posed boss's, not the Giant's by name).
static func is_windup(pose: StringName) -> bool:
	return String(pose).contains("_windup_")


func faces_right(one: Dictionary) -> bool:
	var memo: Dictionary = _actors.get(int(one["id"]), {})
	if memo.is_empty() and posed_boss(one["kind"]) and int(one.get("chew_wait", 0)) > 0 and int(one.get("winding_at", -1)) >= 0:
		var target := Grid.cell(int(one["winding_at"]))
		var here := Vector2i(int(one["pos"][0]) / Player.SUBTILE, int(one["pos"][1]) / Player.SUBTILE)
		if Grid.manhattan(here, target) <= 1 and target.x != here.x:
			return target.x > here.x
	return bool(memo.get("right", false))
