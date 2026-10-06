extends "res://src/tools/shot.gd"

## Real FHD scenes of the 320 non-character assets around the 32px farmer.
##
## The game itself - Main.tscn, its SimDriver, WorldView, HouseView, Relight,
## Lighting and HUD - at 1920x1080 over the 480x270 viewport, scripted the
## way `tools/shot.py` scripts it and through the same helpers: a fresh seeded
## run per picture, the farmer walked to the subject, thirty frames of the
## running game before the shutter. Day and night (dusk indoors: the house
## is a day visit and nightfall sends the farmer out, `Phases`).
##
##     godot --path . --fixed-fps 60 --position -4000,-4000 --script \
##         res://implementation/fhd-assets/pilots/2026-10-06/32px-integration/scenes.gd
##
## Writes implementation/shots/assets32-1080/: one still per scene and, for
## the scenes whose point is motion, twelve frames 0.1 s apart from the
## running game (the GIFs are put together by scenes_playback.py).

const ID := "assets32-1080"
const SCENES: Array = [
	["farmstead_noon", "the farmstead: house, stall, workshop, well, animals, trees"],
	["farmstead_night", "the farmstead at night: lit windows, lamps"],
	["fields_noon", "beds sown in three batches: growth stages, wet soil"],
	["fields_night", "the same beds at night"],
	["stations_noon", "press, kitchen and generator placed and running"],
	["stations_night", "the same stations at night"],
	["defences_noon", "four tower families at levels one to three, joined walls and fences, wear"],
	["defences_wave", "a wave against the towers: muzzles, shots, hits"],
	["pond_noon", "the old pond: water, shore, jetty, path, stones, trees"],
	["pond_night", "the pond at night"],
	["interior_noon", "the furnished farmhouse"],
	["interior_dusk", "the farmhouse at dusk: fire and lamp"],
]
## Twelve frames of the running game, for the scenes that are about motion.
const MOTION: Array = ["farmstead_noon", "interior_dusk", "defences_wave"]

var _report: Array = []


func _initialize() -> void:
	CaptureSize.configure(root, true)
	BootIdent.played()
	seed(SPARK_SEED)
	var main: Node = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var folder := OUT + ID + "/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	for entry in SCENES:
		await _scene(main, entry, folder)
	var file := FileAccess.open(folder + "scenes-report.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(_report, "  ") + "\n")
	file.close()
	print("ASSET SCENES: %d written, %d failed, into %s" % [_written, _failed, folder])
	quit(1 if _failed > 0 else 0)


func _scene(main: Node, entry: Array, folder: String) -> void:
	var name: String = entry[0]
	seed(SPARK_SEED)
	main.begin_run(SEED)
	var state: Dictionary = main.get_node("%SimDriver").state
	var porch: Vector2i = GameData.PLAYER_START
	_standing_at = porch
	match name.get_slice("_", 0):
		"fields":
			_staggered_field(state)
		"stations":
			_stations(state)
		"defences":
			if name.ends_with("wave"):
				_set_wave(state)
			else:
				_defences(state)
		"pond":
			# Twenty-four tiles of farmstead lie between the porch and the
			# pond, and walking gets stuck on the well: start the day there.
			_standing_at = Vector2i(16, 13)
			state["player"]["pos"] = [_standing_at.x * Player.SUBTILE + Player.SUBTILE / 2,
				_standing_at.y * Player.SUBTILE + Player.SUBTILE / 2]
		"interior":
			if name.ends_with("dusk"):
				Sim.advance(state, maxi(GameData.DUSK_AT_TICK + 4 * GameData.SECONDS - int(state["tick"]), 1))
			_set_house_interior(state)
	if name.ends_with("_night"):
		_walk_to(state, _standing_at)
		Phases.begin_preparation(state)
		Sim.advance(state, GameData.PREPARATION_TICKS + 1)
	elif name.ends_with("_noon"):
		Sim.advance(state, maxi(GameData.DAY_TICKS / 2 - int(state["tick"]), 1))
	_walk_to(state, _standing_at)
	var view := main.get_node("%WorldView") as WorldView
	view.look_at_cell(Player.cell(state))
	_only_showing(main, "")
	for i in SETTLE:
		Sim.advance(state, STIR_TICKS)
		await process_frame
	view.skip_transition()
	view._light_for_phase(0.0)
	await process_frame
	await RenderingServer.frame_post_draw
	_save(folder + name + ".png", name)
	if name in MOTION:
		for frame in 12:
			for _i in 6:
				await process_frame
			await RenderingServer.frame_post_draw
			_save(folder + "%s_motion_%02d.png" % [name, frame], "")
	var farmer := _farmer_texture(main)
	_report.append({"scene": name, "line": entry[1], "tick": int(state["tick"]),
		"phase": Phases.name_of(int(state["phase"])), "inside": House.inside(state),
		"farmer_cell": [Player.cell(state).x, Player.cell(state).y], "farmer_texture": farmer,
		"farmer_draw_scale": float(RasterArt.FRAMES.get(farmer, {}).get("draw_scale", 1.0)),
		"nearest_filter": int(ProjectSettings.get_setting("rendering/textures/canvas_textures/default_texture_filter")) == 0,
		"integer_stretch": str(ProjectSettings.get_setting("display/window/stretch/scale_mode")) == "integer"})
	print("  %-16s tick %5d  %-11s farmer %s" % [name, int(state["tick"]),
		Phases.name_of(int(state["phase"])), farmer.get_file()])


func _save(path: String, name: String) -> void:
	var image := root.get_texture().get_image()
	if image == null or image.get_size() != Vector2i(1920, 1080):
		print("  %s: no 1920x1080 image" % path)
		_failed += 1
		return
	if image.save_png(ProjectSettings.globalize_path(path)) != OK:
		_failed += 1
		return
	if name != "":
		_written += 1


func _farmer_texture(main: Node) -> String:
	for view in main.find_children("*", "PlayerView", true, false):
		var body: Sprite2D = view.get_node_or_null("Body")
		if body != null and body.texture != null and (view as CanvasItem).is_visible_in_tree():
			return body.texture.resource_path
	return ""


## Beds sown in three batches a minute apart, so one picture holds seedlings,
## half-grown and ready crops - the way a worked farm looks.
func _staggered_field(state: Dictionary) -> void:
	Resources.gain(state, {GameData.MONEY: 400})
	var seeds := Farming.seeds()
	var beds: Array = []
	for y in GameData.GRID_HEIGHT:
		for x in GameData.GRID_WIDTH:
			if Interact.verb_at(state, Vector2i(x, y)) == &"till":
				beds.append(Vector2i(x, y))
	var batch := ceili(beds.size() / 3.0)
	for i in beds.size():
		var cell: Vector2i = beds[i]
		Farming.select_seed(state, StringName(seeds[i % seeds.size()]))
		Interact.complete(state, cell, &"till")
		Interact.complete(state, cell, &"plant")
		Interact.complete(state, cell, &"water")
		if (i + 1) % batch == 0:
			Sim.advance(state, 50 * GameData.SECONDS)
	_standing_at = GameData.PLAYER_START + Vector2i(1, 4)


## The three larger stations east of the stall, fuelled and set to work.
func _stations(state: Dictionary) -> void:
	Resources.gain(state, {GameData.WOOD: 999, GameData.STONE: 999, GameData.IRON: 999,
		GameData.OIL: 200, GameData.FOOD: 200})
	var placed: Array = []
	for pair in [[&"press", Vector2i(49, 22)], [&"kitchen", Vector2i(52, 21)], [&"generator", Vector2i(55, 22)]]:
		var at := _room_near(state, pair[0], pair[1])
		if at != Vector2i(-1, -1) and Building.place(state, pair[0], at):
			placed.append(at)
	for at in placed:
		Crafting.start_at(state, at)
	Sim.advance(state, 2 * GameData.SECONDS)
	_standing_at = Vector2i(52, 25)


## Every tower family at levels one, two and three, a joined wall and fence
## with some wear, and a mine - the states a defended farm shows by day.
func _defences(state: Dictionary) -> void:
	Resources.gain(state, {GameData.WOOD: 3000, GameData.IRON: 3000, GameData.STONE: 3000,
		GameData.OIL: 400, GameData.GUNPOWDER: 400, GameData.INCENDIARY: 200, GameData.MONEY: 3000})
	# Levels two and three are tree nodes: buy the tree, cheapest first.
	Resources.gain(state, {GameData.TECH: 200})
	for _pass in 2:
		for row in Tech.tree():
			Tech.buy(state, StringName((row as Dictionary)["id"]))
	var families := [&"gun_tower", &"auto_crossbow", &"mortar", &"flame_tower"]
	for row in families.size():
		for level in 3:
			var at := _room_near(state, families[row], Vector2i(52 + level * 3, 29 + row * 2))
			if at == Vector2i(-1, -1) or not Building.place(state, families[row], at):
				continue
			for _up in level:
				Building.upgrade(state, at)
	for x in range(50, 62):
		Building.place(state, &"wall", Vector2i(x, 38))
		Building.place(state, &"fence", Vector2i(x, 40))
	for x in [52, 55, 58]:
		for y in [38, 40]:
			var on := Farm.occupant(state, Vector2i(x, y))
			if not on.is_empty() and on.has("hp"):
				on["hp"] = maxi(1, int(on["hp"]) / 3)
	Building.place(state, &"mine", Vector2i(56, 36))
	_standing_at = Vector2i(55, 35)
