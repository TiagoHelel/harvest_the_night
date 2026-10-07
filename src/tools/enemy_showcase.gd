extends SceneTree

## Actual core movement/structure attacks, immutable view observations and native captures.
var _world: WorldView
var _view: PlayerView
var _lighting: Lighting
var _state: Dictionary
var _checks := 0
var _failed := 0
var _capture := false
var _folder := "res://implementation/shots/sprites/0015/enemies/"
var _caption: Label


func _initialize() -> void:
	call_deferred("_run")


func expect(ok: bool, message: String) -> void:
	_checks += 1
	if not ok:
		_failed += 1
		push_error(message)


func _run() -> void:
	CaptureSize.configure(root)
	await _setup()
	if OS.get_cmdline_user_args().has("--walk-loop"):
		await _walk_loop()
		print("ENEMY WALK LOOP: %d checks, %d failed" % [_checks, _failed])
		quit(1 if _failed > 0 else 0)
		return
	await _identities()
	await _walks(false)
	await _walks(true)
	await _attacks()
	await _guards()
	await _mixed()
	await _dawn()
	await _death_sources()
	print("ENEMY SHOWCASE: %d checks, %d failed" % [_checks, _failed])
	quit(1 if _failed > 0 else 0)


## Consecutive real core ticks, suitable for a 30 Hz native playback review.
## Sparse stills can prove pose coverage while missing an unconvincing gait.
func _walk_loop() -> void:
	for night in [false, true]:
		_state = _blank(night)
		var id := Entities.spawn(_state, &"walker", Vector2i(11, 9))
		await _settle()
		for t in 60:
			_step()
			await _settle()
			var one := Entities.get_one(_state, id)
			expect(str(_world._pose_of(one)).begins_with("walker_walk_"), "Walking retains a walk pose every observed tick")
			await _shoot("loop_%s_%03d" % ["night" if night else "day", t], "Walker / actual movement / 30 simulation ticks per second")


func _setup() -> void:
	var args := OS.get_cmdline_user_args()
	_capture = not args.has("--check")
	for arg in args:
		if arg.begins_with("--out="):
			_folder = "res://" + arg.substr(6).trim_suffix("/") + "/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_folder))
	var relight := Relight.new()
	relight.name = "Relight"
	relight.layer = 1
	root.add_child(relight)
	_world = load("res://scenes/World.tscn").instantiate()
	root.add_child(_world)
	_world.set_process(false)
	await process_frame
	_view = _world.get_node("Occupants/PlayerView")
	_view.set_process(false)
	var lamps := CanvasLayer.new()
	lamps.layer = 2
	root.add_child(lamps)
	_lighting = Lighting.new()
	lamps.add_child(_lighting)
	_lighting.set_process(false)
	_lighting.set_quality(Lighting.STEADY)
	var overlay := CanvasLayer.new()
	overlay.layer = 3
	root.add_child(overlay)
	_caption = Label.new()
	_caption.position = Vector2(8, 2)
	_caption.add_theme_font_override("font", load("res://assets/fonts/harvest_hud.fnt"))
	_caption.add_theme_font_size_override("font_size", 8)
	overlay.add_child(_caption)


func _blank(night: bool = false) -> Dictionary:
	var state := State.create(3015)
	var terrain: PackedByteArray = state["terrain"]
	terrain.fill(Farm.Terrain.GRASS)
	state["terrain"] = terrain
	(state["occupants"] as Dictionary).clear()
	(state["plots"] as Dictionary).clear()
	(state["entities"] as Dictionary).clear()
	state["grid_version"] = int(state["grid_version"]) + 1
	state["tick"] = 1000
	state["day_tick"] = GameData.DAY_TICKS / 2
	state["phase"] = Phases.NIGHT if night else Phases.DAY
	state["house_cell"] = [26, 8]
	for y in 3:
		for x in 3:
			state["occupants"][Grid.index(Vector2i(25+x,7+y))] = {"id":&"house"}
	for resource in GameData.RESOURCES:
		(state["held"] as Dictionary)[resource] = 10000
	state["player"]["pos"] = [26 * Player.SUBTILE, 16 * Player.SUBTILE]
	state["player"]["action"] = {}
	return state


func _house(center: Vector2i) -> void:
	for key in (_state["occupants"] as Dictionary).keys():
		if _state["occupants"][key]["id"] == &"house":
			_state["occupants"].erase(key)
	for y in 3:
		for x in 3:
			_state["occupants"][Grid.index(center+Vector2i(x-1,y-1))] = {"id":&"house"}
	_state["house_cell"] = [center.x,center.y]
	_state["grid_version"] = int(_state["grid_version"]) + 1


func _settle() -> void:
	var before := var_to_bytes(_state)
	_world.show_state(_state)
	_view.show_state(_state)
	_lighting.show_state(_state)
	_lighting.queue_redraw()
	_world.skip_transition()
	_world._process(0.0)
	_world._light_for_phase(5.0)
	_world.look_at_cell(Vector2i(15, 8))
	await process_frame
	await process_frame
	_view._process(0.0)
	expect(var_to_bytes(_state) == before, "Rendering never changes a core/save byte")
	var ids := Entities.ids(_state)
	expect(_world._actor_sprites.size() == ids.size(), "Pool contains exactly the live core entities")
	for i in ids.size():
		var one := Entities.get_one(_state, int(ids[i]))
		var sprite: Sprite2D = _world._actor_sprites[i]
		expect(sprite.position == ArtPlacement.contact(one["pos"]), "Ground contact uses unchanged core subtile position")
		if EnemyMotion.FAMILIES.has(one["kind"]):
			expect(sprite.offset == Vector2(-32, -44), "Common authored pose pivot, including lunges")
			expect(sprite.texture != null and RasterArt.FRAMES.has(sprite.texture.resource_path), "Actual source-owned pose is rendered")
			expect(sprite.get_parent().y_sort_enabled, "Actor depth uses feet, including mirrored poses")


func _step() -> void:
	var control := _state.duplicate(true)
	var before := var_to_bytes(_state)
	_world.before_tick(_state)
	expect(var_to_bytes(_state) == before, "Before-tick snapshots only read core state")
	_state["tick"] = int(_state["tick"]) + 1
	control["tick"] = int(control["tick"]) + 1
	Enemies.tick(_state)
	Enemies.tick(control)
	var after := var_to_bytes(_state)
	_world.after_tick(_state)
	expect(var_to_bytes(_state) == after and var_to_bytes(control) == after, "Observed real Enemies.tick equals an unobserved control byte for byte")
	expect(_world._enemy_motion._before.is_empty(), "Tick snapshot is released")
	expect(_world._enemy_motion._actors.size() <= Entities.ids(_state).size(), "No retained dead core identity")


func _shoot(name: String, caption: String) -> void:
	_caption.text = caption
	if not _capture:
		return
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	expect(image != null and image.get_size() == Vector2i(480, 270), "Actual 480x270 renderer")
	if image != null:
		expect(image.save_png(_folder + name + ".png") == OK, "Saved native viewport: " + name)


func _identities() -> void:
	for night in [false, true]:
		_state = _blank(night)
		for i in EnemyMotion.FAMILIES.size():
			Entities.spawn(_state, EnemyMotion.FAMILIES[i], Vector2i(7+i*5, 9))
		await _settle()
		await _shoot("identities_"+str(int(night)), "Walker / runner / tank / breaker - 29px bodies, unchanged farm scale")
		if not night:
			for sprite in _world._actor_sprites:
				sprite.modulate = Color.BLACK
			await _shoot("silhouettes", "Black silhouettes - slouch / forward lean / broad mass / demolition hammer")


func _walks(left: bool) -> void:
	_state = _blank()
	_house(Vector2i(2,8) if left else Vector2i(26,8))
	var ids: Array[int] = []
	var seen: Dictionary = {}
	for i in EnemyMotion.FAMILIES.size():
		ids.append(Entities.spawn(_state, EnemyMotion.FAMILIES[i], Vector2i(21 if left else 5, 3+i*4)))
		seen[ids[i]] = {}
	await _settle()
	for t in 96:
		_step()
		_world._refresh_actors()
		for id in ids:
			var one := Entities.get_one(_state, id)
			if one.is_empty():
				continue
			var name := _world._pose_of(one)
			if str(name).contains("_walk_"):
				seen[id][name] = true
		if t in [7, 23, 39, 55, 71, 87]:
			await _settle()
			await _shoot("walk_%d_%02d" % [int(left), t], "Actual core movement / left=%s / tick=%d" % [str(left), t])
	for id in ids:
		expect(seen[id].size() == 4, "Every ordinary identity uses four articulated walk frames")
		var one := Entities.get_one(_state, id)
		if not one.is_empty() and int(one["pos"][0]) != (21 if left else 5) * Player.SUBTILE + Player.SUBTILE / 2:
			expect(_world._enemy_motion.faces_right(one) != left, "Horizontal facing follows actual position deltas")
	var snapshot := _world._enemy_motion._actors.duplicate(true)
	for repeat in 12:
		_world._process(0.016)
	expect(_world._enemy_motion._actors == snapshot, "Render-only/paused frames never advance animation")


func _attacks() -> void:
	_state = _blank()
	_house(Vector2i(2,8))
	var ids: Array[int] = []
	var seen: Dictionary = {}
	for i in EnemyMotion.FAMILIES.size():
		var cell := Vector2i(17,3+i*4)
		var terrain: PackedByteArray = _state["terrain"]
		for step in [Vector2i.UP,Vector2i.DOWN,Vector2i.RIGHT]:
			terrain[Grid.index(cell+step)] = Farm.Terrain.WATER
		_state["terrain"] = terrain
		expect(Building.place(_state, &"wall", cell+Vector2i.LEFT), "Actual paid barrier blocks the only route")
		ids.append(Entities.spawn(_state, EnemyMotion.FAMILIES[i],cell))
		seen[ids[i]] = {}
	await _settle()
	for t in 110:
		_step()
		_world._refresh_actors()
		for id in ids:
			var one := Entities.get_one(_state,id)
			if not one.is_empty():
				var pose := _world._pose_of(one)
				if str(pose).contains("_attack_"):
					seen[id][pose] = true
		if t in [0,2,13,29,30,32,47,61,77,93]:
			await _settle()
			await _shoot("attack_%03d" % t, "Real barrier damage / contact and recovery / existing core wait")
	for id in ids:
		expect(seen[id].size() == 3, "All three attack poses are driven by actual contact and existing waits")


func _guards() -> void:
	_state = _blank()
	var id := Entities.spawn(_state,&"walker",Vector2i(12,9))
	var one := Entities.get_one(_state,id)
	one["chewing"] = Grid.index(Vector2i(11,9))
	one["chew_wait"] = 2
	await _settle()
	expect(_world._pose_of(one) == &"walker", "A saved stale chewing field cannot invent a first attack")
	var before := var_to_bytes(_state)
	_world.before_tick(_state)
	_world.after_tick(_state)
	expect(var_to_bytes(_state) == before and _world._pose_of(one) == &"walker", "A duplicate/paused tick does not create a strike")
	Combat.hit(_state,id,1)
	await _settle()
	expect(_world._actor_sprites[0].modulate == Color(1.25,1.12,1.12), "Hurt reads without bleaching family colors into white")
	await _shoot("hurt_walker", "Real core hurt cue / restrained flash / readable material planes")
	_state["phase"] = Phases.NIGHT
	for batch in 6:
		for step in 4:
			_world.before_tick(_state)
			Sim.tick(_state)
			var actual := var_to_bytes(_state)
			_world.after_tick(_state)
			expect(var_to_bytes(_state)==actual, "4x core batches stay observational")
		_world._refresh_actors()
	Entities.remove(_state,id)
	_step()
	expect(_world._enemy_motion._actors.is_empty(), "Actual removal releases live motion memory")
	await _settle()
	var clone := _state.duplicate(true)
	_world.show_state(clone)
	expect(_world._enemy_motion._actors.is_empty(), "Loading a new state cannot replay old attacks")


func _mixed() -> void:
	_state = _blank(true)
	_house(Vector2i(13,9))
	var phase := int(_state["phase"])
	_state["phase"] = Phases.DAY
	expect(Farm.cells_with(_state,&"house").size()==9, "Existing three-by-three house fixture establishes shared character scale")
	for cell in [Vector2i(10,9),Vector2i(16,9)]:
		expect(Building.place(_state,&"gun_tower",cell), "Mixed-wave defence uses unchanged rules")
	_state["phase"] = phase
	(_state["occupants"] as Dictionary)[Grid.index(Vector2i(7,7))] = {"id":&"tree"}
	for i in 16:
		Entities.spawn(_state,EnemyMotion.FAMILIES[i%4],Vector2i(19+(i%4)*2,4+(i/4)*3))
	await _settle()
	await _shoot("mixed_wave_night", "Dark mixed wave / distinct functions / coherent farmhouse and forest scale")
	for t in 20:
		_step()
	await _settle()
	await _shoot("mixed_wave_moving", "Actual mixed-wave movement / stable foot depth / authored frames")


## A lost night's winners at dawn: the rules take them off the farm on the
## tick the day begins, and the view walks each one away from the house and
## out of the light rather than letting it vanish.
func _dawn() -> void:
	_state = _blank(true)
	var home := Vector2(Farm.house_centre(_state)) * float(Player.SUBTILE) \
		+ Vector2.ONE * float(Player.SUBTILE / 2)
	var cells: Array[Vector2i] = [Vector2i(22, 8), Vector2i(30, 9),
		Vector2i(26, 12), Vector2i(25, 4), Vector2i(29, 11)]
	for i in cells.size():
		Entities.spawn(_state, EnemyMotion.TRACKED[i], cells[i])
	_state["phase"] = Phases.RESULT
	await _settle()
	_world.look_at_cell(Vector2i(26, 8))
	await _shoot("dawn_0_result", "Lost night / the winners still in the yard while the result is read")
	var starts: Array[Vector2] = []
	for id in Entities.ids(_state):
		var one := Entities.get_one(_state, int(id))
		starts.append(Vector2(float(one["pos"][0]), float(one["pos"][1])))

	(_state["intent"] as Dictionary)["confirm_result"] = true
	_world.before_tick(_state)
	Sim.tick(_state)
	var after := var_to_bytes(_state)
	_world.after_tick(_state)
	expect(var_to_bytes(_state) == after, "Watching the dawn tick changes no core byte")
	expect(int(_state["phase"]) == Phases.DAY, "Confirming the result is dawn")
	expect(Entities.count(_state) == 0, "The rules take every survivor off the farm at dawn")
	var cues := _world._enemy_retreats._cues
	expect(cues.size() == cells.size(), "And the view keeps one walking picture of each")
	expect(_world._enemy_retreats._before.is_empty(), "The dawn snapshot is released")
	for i in mini(cues.size(), starts.size()):
		var cue: Dictionary = cues[i]
		var from: Vector2 = cue["from"]
		var way: Vector2 = cue["way"]
		expect(from == starts[i], "Each walks off from exactly where the rules last had it")
		expect((from + way * 64.0).distance_to(home) > from.distance_to(home),
			"Away from the house, never through it")

	await _settle()
	_world.look_at_cell(Vector2i(26, 8))
	expect(_world._actor_sprites.is_empty(), "No live enemy sprite is left in daylight")
	var shown := 0
	for sprite in _world._retreat_sprites:
		shown += 1 if sprite.visible else 0
	expect(shown == cells.size(), "Every one of them is drawn walking off")
	var steps := [0.5, 0.6, 0.6]
	for s in steps.size():
		var before := var_to_bytes(_state)
		_world._refresh_retreats(steps[s])
		expect(var_to_bytes(_state) == before, "Walking them off never touches the state")
		for i in cues.size():
			var sprite: Sprite2D = _world._retreat_sprites[i]
			var at: Array = EnemyRetreats.position(cues[i])
			expect(sprite.position == ArtPlacement.contact(at), "Drawn where the walk has got to")
			expect(Vector2(at[0], at[1]).distance_to(home) > starts[i].distance_to(home), "Further from the house as dawn goes on")
			expect(sprite.texture.resource_path.contains("_walk_"), "Walking, in the night's own frames")
			expect(sprite.modulate.a <= 1.0 and sprite.modulate.a > 0.0, "Still there to be seen leaving")
		await process_frame
		await _shoot("dawn_%d_leaving" % (s + 1), "Dawn / the survivors turn their backs on the house and walk off")
	expect(not cues.is_empty() and EnemyRetreats.alpha(cues[0]) < 1.0
		and float(cues[0]["age"]) < EnemyRetreats.SECONDS, "Fading before they are gone")
	_world._refresh_retreats(EnemyRetreats.SECONDS)
	expect(_world._enemy_retreats._cues.is_empty(), "And gone once the walk is over")
	var still := 0
	for sprite in _world._retreat_sprites:
		still += 1 if sprite.visible else 0
	expect(still == 0, "Leaving nothing drawn behind")

	# A won night leaves nobody, so its morning has nobody to walk off.
	_state = _blank(true)
	_state["phase"] = Phases.RESULT
	await _settle()
	(_state["intent"] as Dictionary)["confirm_result"] = true
	_world.before_tick(_state)
	Sim.tick(_state)
	_world.after_tick(_state)
	expect(int(_state["phase"]) == Phases.DAY and _world._enemy_retreats._cues.is_empty(), "A clean night has a clean dawn")


func _death_sources() -> void:
	_state = _blank()
	await _settle()
	var layer := Node2D.new()
	root.add_child(layer)
	for i in EnemyMotion.FAMILIES.size():
		for frame in 4:
			var sprite := Sprite2D.new()
			sprite.centered = false
			sprite.texture = load(WorldView.ENEMY_DIR+str(EnemyMotion.FAMILIES[i])+"_death_%d.png" % frame)
			sprite.offset = Vector2(-32,-44)
			sprite.position = Vector2(110+frame*80,65+i*58)
			layer.add_child(sprite)
	await _shoot("death_sources", "Prepared one-shot collapse sources / playback follows in task 0016")
	layer.queue_free()
