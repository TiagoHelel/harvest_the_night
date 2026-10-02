extends SceneTree

var _checks := 0
var _failed := 0
var _capture := false
var _state: Dictionary
var _world: WorldView
var _house: HouseView
const OUT := "res://implementation/farm-house/captures/"
var _out := OUT


func _initialize() -> void:
	call_deferred("_run")


func expect(ok: bool, message: String) -> void:
	_checks += 1
	if not ok:
		_failed += 1
		push_error(message)


func _stand(state: Dictionary, cell: Vector2i) -> void:
	state["player"]["pos"] = [cell.x * Player.SUBTILE + Player.SUBTILE / 2,
		cell.y * Player.SUBTILE + Player.SUBTILE / 2]
	state["intent"]["move"] = [0, 0]


func _legacy() -> Dictionary:
	var state := State.create(30303)
	state["version"] = 2
	state.erase("house_visit")
	var rows: Array = JSON.parse_string(FileAccess.get_file_as_string("res://implementation/farm-house/farm-v2.json"))
	var terrain := PackedByteArray()
	terrain.resize(900)
	state["occupants"] = {}
	for y in rows.size():
		for x in 45:
			var entry: Array = GameData.MAP_LEGEND[rows[y][x]]
			var idx := y * 45 + x
			terrain[idx] = entry[0]
			if entry[1] != &"":
				state["occupants"][idx] = {"id": entry[1]}
	state["terrain"] = terrain
	state["house_cell"] = [16, 4]
	_stand(state, Vector2i(17, 7))
	return state


func _run() -> void:
	_capture = not OS.get_cmdline_user_args().has("--check")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = "res://" + arg.trim_prefix("--out=").trim_suffix("/") + "/"
	_state = State.create(30303)
	expect(GameData.validate().is_empty(), "Expanded farm data validates: %s" % str(GameData.validate()))
	expect(Grid.CELLS == 1125 and Grid.CELLS * 100 == 900 * 125, "Farm has exactly 25% more total area")
	var available := 0
	for idx in Grid.CELLS:
		if Farm.is_empty(_state, Grid.cell(idx)) and _state["terrain"][idx] in [Farm.Terrain.GRASS, Farm.Terrain.SOIL]:
			available += 1
	expect(available == 787 and available * 100 >= 591 * 125, "Enlarged buildings leave at least 25% more clear usable land")
	for y in range(20, 25):
		for x in Grid.WIDTH:
			expect(Farm.walkable(_state, Vector2i(x, y)) and Farm.terrain_at(_state, Vector2i(x, y)) in [Farm.Terrain.GRASS, Farm.Terrain.SOIL],
				"Every new southern cell is clear ground")
	expect(Farm.cells_of(_state, Farm.Terrain.SOIL).size() * 100 == 48 * 125,
		"The real planting beds also increase by exactly 25%")
	var reachable := {Grid.index(House.porch(_state)): true}
	var pending := [House.porch(_state)]
	while not pending.is_empty():
		var cell: Vector2i = pending.pop_back()
		for step in Grid.STEPS:
			var neighbour: Vector2i = cell + step
			var idx := Grid.index(neighbour)
			if Farm.walkable(_state, neighbour) and not reachable.has(idx):
				reachable[idx] = true
				pending.append(neighbour)
	var connected := 0
	for y in range(20, 25):
		for x in Grid.WIDTH:
			connected += int(reachable.has(Grid.index(Vector2i(x, y))))
	expect(connected == 225, "All new southern land is reachable from the farmhouse without clearing trees")
	expect(Farm.house_bounds(_state).size == GameData.HOUSE_SIZE, "House collision covers the enlarged footprint")
	expect(not Farm.buildable(_state, House.porch(_state)) and Farm.walkable(_state, House.porch(_state)),
		"The front door stays accessible and cannot be walled in")
	var legacy := _legacy()
	legacy["plots"][Grid.index(Vector2i(14, 7))] = {"crop": &"carrot", "growth": 123, "watered": true}
	legacy["plots"][Grid.index(Vector2i(14, 8))] = {"crop": &"wheat", "growth": 77, "watered": true}
	legacy["crafting"][Grid.index(Vector2i(12, 8))] = {"queue": [&"gunpowder"], "left": 25, "total": 30}
	legacy["produced"][Grid.index(Vector2i(13, 8))] = {"at": 40, "yield": {&"wood": 2}}
	var crops: Dictionary = legacy["plots"].duplicate(true)
	var jobs: Dictionary = legacy["crafting"].duplicate(true)
	var products: Dictionary = legacy["produced"].duplicate(true)
	var inventory: Dictionary = legacy["held"].duplicate(true)
	var migrated := Save.step_up(legacy, 2, State.VERSION, Save.migrations())
	expect(not migrated.is_empty() and int(migrated["version"]) == 3 and migrated["terrain"].size() == Grid.CELLS,
		"Version 2 save expands successfully")
	expect(migrated["plots"] == crops and migrated["crafting"] == jobs and migrated["produced"] == products
		and migrated["held"] == inventory, "Migration preserves saved crops, queued work, deliveries and inventory")
	expect(Farm.house_bounds(migrated).size == GameData.HOUSE_SIZE and Farm.walkable(migrated, House.porch(migrated)),
		"A house whose expansion conflicts with crops relocates safely onto the new clear land")
	expect(Building.parts_at(migrated, Vector2i(12, 8)).size() == 4,
		"A dense legacy workshop keeps its existing cells rather than covering a saved crop")
	State.reconcile(migrated)
	expect(State.reconcile(migrated).is_empty(), "Migrated save reconciles once and remains stable")
	var clean_legacy := Save.step_up(_legacy(), 2, State.VERSION, Save.migrations())
	expect(Farm.house_bounds(clean_legacy).size == GameData.HOUSE_SIZE
		and Building.parts_at(clean_legacy, Vector2i(12, 8)).size() == 12, "Unobstructed legacy buildings receive larger footprints")
	# Finish a real planting/harvest loop on newly added ground.
	var field := Vector2i(31, 22)
	_stand(_state, field - Vector2i(1, 0))
	_state["player"]["facing"] = Player.EAST
	var crop := Farming.selected_seed(_state)
	var before_crop := Resources.amount(_state, crop)
	_state["intent"]["interact"] = true
	for _i in Interact.ticks_for(_state, field, &"till"):
		Player.tick(_state)
	_state["intent"]["interact"] = true
	for _i in Interact.ticks_for(_state, field, &"plant"):
		Player.tick(_state)
	expect(not _state["plots"].get(Grid.index(field), {}).is_empty(), "New land supports the real planting action")
	var plot: Dictionary = _state["plots"][Grid.index(field)]
	plot["growth"] = int(GameData.CROPS[plot["crop"]]["growth_ticks"])
	_state["intent"]["interact"] = true
	for _i in Interact.ticks_for(_state, field, &"harvest"):
		Player.tick(_state)
	expect(Resources.amount(_state, crop) > before_crop, "New land pays the normal harvest reward")
	_stand(_state, House.porch(_state))
	var outside := Player.position(_state)
	_state["intent"]["interact"] = true
	Sim.tick(_state)
	expect(House.inside(_state) and Player.cell(_state) == House.SPAWN, "The existing interact input enters at the porch")
	var saved: Dictionary = bytes_to_var(var_to_bytes(_state))
	expect(State.hash_of(saved) == State.hash_of(_state) and State.reconcile(saved).is_empty(), "Indoor position survives a plain-data save round trip")
	var day_tick := int(_state["day_tick"])
	Sim.advance(_state, 30)
	expect(int(_state["day_tick"]) == day_tick + 30, "Farm time keeps advancing during a house visit")
	expect(not Building.can_place(_state, &"workshop", Vector2i(35, 22)), "Indoor input cannot build onto outdoor coordinates")
	for piece in House.FURNITURE:
		var cell: Vector2i = piece["cell"]
		var size: Vector2i = piece["size"]
		_stand(_state, cell + Vector2i(size.x / 2, size.y))
		_state["intent"]["move"] = [0, -1]
		for _i in 30:
			Player.tick(_state)
		expect(Player.cell(_state).y >= cell.y + size.y, "%s has solid furniture collision" % piece["id"])
	_stand(_state, House.SPAWN)
	_state["intent"]["move"] = [0, 1]
	for _i in 10:
		if House.inside(_state):
			Player.tick(_state)
	expect(not House.inside(_state) and Player.position(_state) == outside, "Walking to the interior door returns to the exact farm position")
	_state["intent"]["move"] = [0, 0]
	House.enter(_state)
	_state["intent"]["begin_night"] = true
	Sim.tick(_state)
	expect(not House.inside(_state) and int(_state["phase"]) == Phases.PREPARATION,
		"Starting defence returns outside before the phase changes")
	expect(not House.enter(_state), "The night phase cannot be bypassed with a house visit")
	# Render both spaces with the actual source assets and common farmer canvas.
	_state = State.create(30303)
	_world = load("res://scenes/World.tscn").instantiate()
	root.add_child(_world)
	_house = HouseView.new()
	root.add_child(_house)
	await process_frame
	_world.show_state(_state)
	_world.get_node("Occupants/PlayerView").show_state(_state)
	_world.look_at_cell(Player.cell(_state))
	_house.show_state(_state)
	await _shoot("exterior", false)
	var house_sprite: Sprite2D = _world.get_node("Occupants").get_children().filter(
		func(node): return node is Sprite2D and node.texture != null and node.texture.resource_path.ends_with("/house.png"))[0]
	expect(house_sprite.scale == Vector2(2, 2), "Exterior house reuses the source drawing at twice the native scale")
	var corner := Farm.house_bounds(_state).position
	var metadata: Dictionary = RasterArt.FRAMES[house_sprite.texture.resource_path]
	expect(ArtPlacement.emission(&"house", Vector2(corner) * 16, &"smoke", Vector2.ZERO, GameData.HOUSE_SIZE)
		== house_sprite.position + (Vector2(metadata["smoke"]) - Vector2(metadata["pivot"])) * 2,
		"Scaled chimney particles remain aligned to the actual sprite")
	House.enter(_state)
	await _shoot("interior_entry", true)
	await _check_furniture_art()
	_stand(_state, Vector2i(9, 8))
	await _shoot("interior_dining", true)
	_stand(_state, Vector2i(14, 7))
	await _shoot("interior_bedroom", true)
	_house.change_zoom(1)
	_house._process(1.0)
	await _shoot("interior_zoom", true)
	_house.reset_zoom()
	House.leave(_state)
	await _shoot("exterior_return", false)
	_world.queue_free()
	_house.queue_free()
	await process_frame
	print("FARM HOUSE: %d checks, %d failed" % [_checks, _failed])
	quit(1 if _failed > 0 else 0)


func _shoot(name: String, indoors: bool) -> void:
	_world.visible = not indoors
	var before := var_to_bytes(_state)
	for _i in 24:
		await process_frame
	expect(var_to_bytes(_state) == before, "Rendering the room or farm cannot alter saved state")
	if not _capture:
		return
	await RenderingServer.frame_post_draw
	var picture := root.get_texture().get_image()
	expect(picture.get_size() == Vector2i(480, 270), "Inspection uses the real native viewport")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out))
	expect(picture.save_png(_out + name + ".png") == OK, "Native capture saved")


func _check_furniture_art() -> void:
	var pieces: Dictionary = {}
	for piece in House.FURNITURE:
		pieces[piece["id"]] = piece
	for id in [&"kitchen", &"fireplace", &"bed", &"nightstand"]:
		expect(pieces[id]["cell"].y == 3, "%s backs onto the north wall" % id)
	expect(pieces[&"nightstand"]["cell"].x + pieces[&"nightstand"]["size"].x == pieces[&"bed"]["cell"].x,
		"The lamp cabinet sits beside the head of the bed")
	expect(pieces[&"storage"]["cell"].x + pieces[&"storage"]["size"].x == House.ROOM.x - 1,
		"The west-facing wardrobe backs onto the east wall")
	var before := var_to_bytes(_state)
	_house.ambient_running = false
	var stopped := _house._ambient_time
	_house._refresh_ambient(0.5)
	expect(_house._ambient_time == stopped, "Pause freezes hearth animation")
	_house.ambient_running = true
	var settings := root.get_node("Settings")
	var previous: bool = settings.get_bool(&"a11y/flashing")
	settings.set_value(&"a11y/flashing", false)
	_house._refresh_ambient(0.5)
	expect(float(_house._flame.get_shader_parameter("flame_time")) == 0.0,
		"Steady light accessibility keeps the hearth stationary")
	settings.set_value(&"a11y/flashing", true)
	_house._refresh_ambient(0.5)
	expect(_house._ambient_time > stopped, "The hearth animates when running")
	if _capture:
		_house.ambient_running = false
		_house._flame.set_shader_parameter("flame_time", 0.0)
		await _shoot("fire_a", true)
		var first := root.get_texture().get_image()
		_house._flame.set_shader_parameter("flame_time", 0.27)
		await _shoot("fire_b", true)
		var second := root.get_texture().get_image()
		# The default camera is native 1:1: room origin is (80,38), hearth
		# sprite origin (240,54). Inspect the actual shader-rendered pixels.
		var changed := 0
		var masonry_changed := 0
		var source_changed := 0
		var original: Image = load("res://sprites/interior/fireplace.png").get_image()
		for y in 64:
			for x in 48:
				if first.get_pixel(240 + x, 54 + y) != second.get_pixel(240 + x, 54 + y):
					changed += 1
					if not Rect2i(17, 43, 14, 10).has_point(Vector2i(x, y)):
						masonry_changed += 1
				if original.get_pixel(x, y).a == 1.0 and not Rect2i(17, 43, 14, 10).has_point(Vector2i(x, y)):
					if first.get_pixel(240 + x, 54 + y) != original.get_pixel(x, y):
						source_changed += 1
		expect(changed >= 8, "Fire changes visibly inside the rendered firebox")
		expect(masonry_changed == 0, "Masonry, plants and grate stay perfectly still")
		expect(source_changed == 0, "Static hearth pixels keep the exact original source colors")
	_house.ambient_running = true
	settings.set_value(&"a11y/flashing", previous)
	expect(var_to_bytes(_state) == before, "Hearth and lamp never write simulation state")
