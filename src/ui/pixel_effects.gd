class_name PixelEffects
extends RefCounted

## Small source-owned one-shots. Records contain view values only, never a
## retained entity/occupant dictionary. The shared particle budget reserves at
## most 24 forms; newer contacts replace older ones during a crowded wave.
const MAX_FORMS := 24
const COUNTS := {&"muzzle":3, &"impact":3, &"flame":4, &"smoke":4,
	&"dust":3, &"splash":4, &"flare":4}
const OPACITY := {&"muzzle":1.0, &"impact":0.85, &"flame":1.0,
	&"smoke":0.6, &"dust":0.8, &"splash":1.0, &"flare":1.0}
const WARM_FAMILIES := [&"muzzle", &"flame", &"flare"]

var limit := MAX_FORMS
var density := 1.0
var motion := true
var records: Array[Dictionary] = []
var sprites: Array[Sprite2D] = []
var ground_parent: Node2D
var warm_parent: Node2D
var _textures: Dictionary = {}
var _credit := 0.0
var _tick := -1
var _entities: Dictionary = {}
var _guns: Dictionary = {}
var _flares := 0
var _work := PlayerWork.new()


func reset() -> void:
	records.clear()
	_entities.clear()
	_guns.clear()
	_work.reset()
	_tick = -1
	_credit = 0.0
	for sprite in sprites:
		if is_instance_valid(sprite):
			sprite.hide()


func release() -> void:
	reset()
	for sprite in sprites:
		if is_instance_valid(sprite):
			sprite.queue_free()
	sprites.clear()
	ground_parent = null
	warm_parent = null


func set_density(value: float) -> void:
	density = clampf(value, 0.0, 1.0)
	_credit = 0.0
	if density == 0.0:
		records.clear()
		for sprite in sprites:
			sprite.hide()


func emit(family: StringName, at: Vector2, velocity := Vector2.ZERO) -> bool:
	if limit <= 0 or density <= 0.0 or not COUNTS.has(family):
		return false
	_credit += density
	if _credit < 1.0:
		return false
	_credit -= 1.0
	if records.size() >= limit:
		records.pop_front()
	records.append({"family":family, "at":at, "velocity":velocity, "age":0.0})
	return true


static func path_for(family: StringName, frame: int) -> String:
	return "res://sprites/effects/%s_%d.png" % [family, frame]


static func seconds(family: StringName) -> float:
	return float(PlaceholderArt.frame(path_for(family, 0))["seconds"])


func advance(delta: float, parent: Node2D) -> void:
	# Main's child Particles enters the tree before WorldView creates its
	# ground layer in _ready. Bind on first playback, when that layer exists.
	if not is_instance_valid(ground_parent):
		var world := parent.get_parent() as WorldView
		if world != null:
			ground_parent = world._ground_traps
	for i in range(records.size()-1, -1, -1):
		var record := records[i]
		record["age"] = float(record["age"]) + maxf(delta, 0.0)
		if float(record["age"]) + 0.000001 >= seconds(record["family"]) * int(COUNTS[record["family"]]):
			records.remove_at(i)
		elif motion:
			record["at"] = (record["at"] as Vector2) + (record["velocity"] as Vector2) * delta
	while sprites.size() < records.size():
		var sprite := Sprite2D.new()
		sprite.centered = false
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		parent.add_child(sprite)
		sprites.append(sprite)
	for i in sprites.size():
		var sprite := sprites[i]
		sprite.visible = i < records.size()
		if not sprite.visible:
			continue
		var record := records[i]
		var family: StringName = record["family"]
		var ground := ground_parent if is_instance_valid(ground_parent) else null
		var warm := warm_parent if is_instance_valid(warm_parent) else null
		var target := warm if warm!=null and family in WARM_FAMILIES else ground if ground!=null and family in [&"dust",&"splash"] else parent
		if warm!=null:
			warm.transform = parent.get_global_transform()
		if sprite.get_parent()!=target:
			sprite.reparent(target,false)
		var phase := int(floorf((float(record["age"]) + 0.000001) / seconds(family))) if motion else 0
		var path := path_for(family, mini(phase, int(COUNTS[family])-1))
		if not _textures.has(path):
			_textures[path] = load(path)
		sprite.texture = _textures[path]
		sprite.offset = -Vector2(PlaceholderArt.frame(path)["pivot"])
		sprite.position = (record["at"] as Vector2).round()
		# Steady accessibility mode holds the first silhouette with a gentle
		# fade, instead of enlarging/flashing it or moving fragments.
		var fade := 1.0 if motion else 1.0-float(record["age"])/(seconds(family)*int(COUNTS[family]))
		sprite.modulate = Color(1, 1, 1, float(OPACITY[family])*fade)


func before_tick(state: Dictionary, gun_cells: Array) -> void:
	_tick = int(state["tick"])
	_entities.clear()
	_guns.clear()
	for id in Entities.ids(state):
		var one := Entities.get_one(state, int(id))
		# Borrow only the coordinate array until after this core tick. A death
		# following movement then emits at its final contact, not the old cell.
		_entities[int(id)] = [one["pos"],
			int(one.get("hurt",0)), Combat.is_burning(state,int(id)), StringName(one["kind"])]
	for idx in gun_cells:
		_guns[int(idx)] = int(state["occupants"][int(idx)].get("reload",0))
	_flares = Ability.flares_used(state)
	_work.before_tick(state)


func after_tick(state: Dictionary) -> void:
	if _tick < 0 or int(state["tick"]) != _tick+1:
		_entities.clear()
		_guns.clear()
		_tick = -1
		_work.reset()
		return
	var per := float(GameData.TILE_SIZE) / Player.SUBTILE
	for id in _entities:
		var was: Array = _entities[id]
		var one := Entities.get_one(state, int(id))
		if one.is_empty():
			var coordinates: Array = was[0]
			emit(&"dust", Vector2(coordinates[0],coordinates[1])*per)
			continue
		var at := Vector2(one["pos"][0],one["pos"][1])*per
		if int(one.get("hurt",0)) > int(was[1]):
			emit(&"impact", at-Vector2(0,20 if was[3]==&"giant" else 12))
		if Combat.is_burning(state,int(id)) and not bool(was[2]):
			emit(&"flame", at-Vector2(0,4))
	for idx in _guns:
		var on: Dictionary = state["occupants"].get(idx,{})
		# Reload rises on the actual firing tick, including powered towers.
		# Render rate cannot repeat the same shot or miss a fast reload.
		if not on.is_empty() and int(on.get("reload",0)) > int(_guns[idx]):
			for muzzle in WorldView.tower_muzzles(on,Grid.cell(int(idx))):
				emit(&"flame" if on["id"]==&"flame_tower" else &"muzzle",muzzle)
	if Ability.flares_used(state) > _flares:
		var at := Ability.flare_at(state)
		if at.size()==2:
			emit(&"flare",(Vector2(at[0],at[1])+Vector2(0.5,0.5))*GameData.TILE_SIZE)
	_work.after_tick(state)
	if _work._fresh:
		var at := (Vector2(_work._cell)+Vector2(0.5,0.7))*GameData.TILE_SIZE
		if _work._cue in [&"water",&"fish",&"reel"]:
			emit(&"splash",at)
		elif _work._cue in [&"harvest",&"chop",&"mine",&"till",&"plant",&"repair"]:
			emit(&"dust",at)
		_work._fresh = false
	_entities.clear()
	_guns.clear()
	_tick = -1
