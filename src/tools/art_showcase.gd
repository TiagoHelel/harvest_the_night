extends SceneTree

## Deterministic isolated fixtures, never writing player saves.
## Locomotion mode drives unchanged Player.tick; rendering cannot mutate state.
## tools/show_art.py supplies the real renderer and fixed FPS for PNG capture.
var _world: WorldView
var _state: Dictionary
var _checks := 0
var _failed := 0
var _capture := false
var _folder := "res://implementation/shots/sprites/0003/showcase/"
var _caption: Label


func _initialize() -> void:
	call_deferred("_run")


func expect(ok: bool, message: String) -> void:
	_checks += 1
	if not ok:
		_failed += 1
		push_error(message)


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	_capture = not args.has("--check")
	for arg in args:
		if arg.begins_with("--out="):
			_folder = "res://" + arg.substr(6).trim_suffix("/") + "/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_folder))
	_world = load("res://scenes/World.tscn").instantiate()
	root.add_child(_world)
	await process_frame
	var overlay := CanvasLayer.new()
	root.add_child(overlay)
	_caption = Label.new()
	_caption.position = Vector2(8, 8)
	_caption.add_theme_font_override("font", load("res://assets/fonts/harvest_hud.fnt"))
	_caption.add_theme_font_size_override("font_size", 8)
	overlay.add_child(_caption)
	_state = State.create(3003)
	var terrain: PackedByteArray = _state["terrain"]
	terrain.fill(Farm.Terrain.GRASS)
	_state["terrain"] = terrain
	(_state["occupants"] as Dictionary).clear()
	(_state["plots"] as Dictionary).clear()
	_state["tick"] = GameData.DUSK_AT_TICK / 2
	_state["house_cell"] = [21, 7]
	_add_house(Vector2i(20, 6))
	(_state["occupants"] as Dictionary)[Grid.index(Vector2i(12, 9))] = {"id": &"tree"}
	var enemy := Entities.spawn(_state, &"walker", Vector2i(21, 8))
	var player: Dictionary = _state["player"]
	player["facing"] = Player.SOUTH
	player["action"] = {}
	var actor := Entities.get_one(_state, enemy)
	if args.has("--locomotion"):
		await _locomotion()
		print("PLAYER SHOWCASE: %d checks, %d failed" % [_checks, _failed])
		quit(1 if _failed > 0 else 0)
		return
	# Traverse the overlap in both directions, swapping farmer/enemy subjects.
	for subject in 2:
		for step in 9:
			var dy := -24 + step * 6
			_set_contact(player, Vector2i(200 if subject == 0 else 344, (160 if subject == 0 else 144) + dy))
			_set_contact(actor, Vector2i(344 if subject == 0 else 200, (144 if subject == 0 else 160) + dy))
			await _settle()
			_check_placement()
			await _shoot("occlusion_%d_%02d" % [subject, step], "Farmer / walker behind -> in front; %d" % dy)
	# House ghost and its full logical footprint, plus tall tower preview.
	_world.show_ghost(Vector2i(14, 10), &"house", true)
	await _settle()
	var ghost: Sprite2D = _world.find_child("Ghost", true, false)
	expect(ghost.position == Vector2(248, 208), "House ghost sorts at the 3x3 ground contact")
	expect(ghost.offset == Vector2(-32, -60), "House ghost uses source-owned pivot")
	expect(_world.ghost_footprint() == Vector2i(3, 3), "House preview frame covers its nine cells")
	await _shoot("ghost_house", "House preview: unchanged 3x3 footprint / roof overhang")
	_world.show_ghost(Vector2i(14, 10), &"gun_tower", true)
	await _settle()
	expect(ghost.position == Vector2(232, 176), "Tower ghost stands on the selected cell")
	expect(ghost.offset.y == -ghost.texture.get_height(), "Legacy tower preview bottom agrees with placed tower")
	expect(_world.ghost_footprint() == Vector2i.ONE, "Changing family in the same cell updates the preview frame")
	await _shoot("ghost_tower", "Tower preview: base stays on the selected cell")
	_world.hide_ghost()
	# Real map/camera limits: both horizontal sides and top/bottom roof clips.
	for corner in [Vector2i(0, 0), Vector2i(37, 0), Vector2i(0, 15), Vector2i(37, 15)]:
		(_state["occupants"] as Dictionary).clear()
		_add_house(corner)
		_state["house_cell"] = [corner.x + 1, corner.y + 1]
		_set_contact(player, Vector2i((corner.x + 1) * 16 + 8, mini(corner.y + 4, 17) * 16))
		await _settle()
		_world.look_at_cell(corner)
		await process_frame
		await _shoot("bounds_%d_%d" % [corner.x, corner.y], "Map/camera boundary: one house, 3x3 logical base")
	# Living crop states and all existing tower upgrade/damage/fire states.
	(_state["occupants"] as Dictionary).clear()
	(_state["entities"] as Dictionary).clear()
	var row := 5
	for crop in Farming.seeds():
		var needed := int(GameData.CROPS[crop]["growth_ticks"])
		for stage in 4:
			(_state["plots"] as Dictionary)[Grid.index(Vector2i(9 + stage * 3, row))] = {
				"crop": crop, "growth": stage * needed / 3, "watered": stage % 2 == 0, "soak": 0}
		row += 3
	var column := 21
	for kind in [&"gun_tower", &"flame_tower", &"mortar", &"auto_crossbow"]:
		for level in 3:
			var cell := Vector2i(column, 5 + level * 4)
			(_state["occupants"] as Dictionary)[Grid.index(cell)] = {"id": kind, "level": level + 1,
				"hp": int(GameData.DEFENCES[kind]["hp"]), "reload": 0}
		column += 4
	await _settle()
	_world.look_at_cell(Vector2i(20, 9))
	await _shoot("crop_tower_whole", "Three crop families / stages 0-3; four tower families / levels 1-3")
	for idx in _state["occupants"]:
		(_state["occupants"][idx] as Dictionary)["hp"] = 1
	await _settle()
	await _shoot("crop_tower_hurt", "Same crop stages and tower levels: damaged")
	for idx in _state["occupants"]:
		var on: Dictionary = _state["occupants"][idx]
		on["reload"] = int(GameData.DEFENCES[on["id"]].get("reload_ticks", 10))
	await _settle()
	await _shoot("crop_tower_fire", "Same tower levels: firing / native ground anchors")
	await _contacts()
	print("ART SHOWCASE: %d checks, %d failed" % [_checks, _failed])
	quit(1 if _failed > 0 else 0)


func _add_house(corner: Vector2i) -> void:
	for y in 3:
		for x in 3:
			(_state["occupants"] as Dictionary)[Grid.index(corner + Vector2i(x, y))] = {"id": &"house"}


## The actual PlayerView clock/flip/frame binding, plus core-resolved diagonal facing.
func _locomotion() -> void:
	(_state["entities"] as Dictionary).clear()
	var view: PlayerView = _world.get_node("Occupants/PlayerView")
	view.set_process(false)
	var body: Sprite2D = view.get_node("Body")
	var player: Dictionary = _state["player"]
	for facing in [Player.SOUTH, Player.WEST, Player.NORTH, Player.EAST]:
		for moving in [false, true]:
			_set_contact(player, Vector2i(248, 208))
			var step: Vector2i = Player.FACING_STEPS[facing]
			_state["intent"]["move"] = [step.x, step.y]
			Player.tick(_state)
			expect(Player.facing(_state) == facing, "Core movement resolves the cardinal facing")
			if not moving:
				_state["intent"]["move"] = [0, 0]
			var pose := PlayerArt.pose(facing, moving, &"")
			var count := int(pose["frames"])
			var each := float(pose["seconds"])
			var expected_name: StringName = StringName("%s_%s" % [
				"walk" if moving else "idle", PlayerArt.FACINGS[facing][0]])
			expect(pose["name"] == expected_name and count == (4 if moving else 3),
				"Each facing selects its complete authored idle/walk family")
			expect(PlayerFrames.SECONDS.has(expected_name), "Timing comes from the accepted strip")
			await _settle()
			var fixed_contact := ArtPlacement.contact(player["pos"])
			for phase in count * 2:
				if moving and phase > 0:
					Player.tick(_state)
				var before := State.hash_of(_state)
				view._process(0.0 if phase == 0 else each)
				expect(State.hash_of(_state) == before, "Drawing the player never changes core state")
				expect(view.playing() == expected_name, "No locomotion family silently falls back to idle")
				expect(view.flipped() == (facing == Player.EAST), "Only east mirrors the accepted west")
				expect(body.texture != null and body.texture.resource_path ==
					PlayerArt.texture_path(expected_name, phase % count),
					"Actual view clock selects each authored frame, including loop wrap")
				expect(body.offset == Vector2(-24, -44), "A turn or mirror cannot move the foot pivot")
				expect(view.position == ArtPlacement.contact(player["pos"]),
					"Visible ground origin agrees with unchanged core position")
				if not moving:
					expect(view.position == fixed_contact, "Idle feet stay planted across both loops")
				var metadata: Dictionary = RasterArt.FRAMES.get(body.texture.resource_path, {})
				expect(metadata.get("canvas") == Vector2i(48, 48)
					and metadata.get("pivot") == Vector2i(24, 44), "Every frame uses accepted source geometry")
				if phase < count:
					await _shoot("%s_facing%d_%02d" % ["walk" if moving else "idle", facing, phase],
						"%s / facing %d / authored frame %d" % [expected_name, facing, phase])
	# Vertical wins a diagonal tie in core; release retains the resulting facing.
	for move in [Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)]:
		_set_contact(player, Vector2i(248, 208))
		_state["intent"]["move"] = [move.x, move.y]
		var previous := Player.position(_state)
		Player.tick(_state)
		var expected := Player.NORTH if move.y < 0 else Player.SOUTH
		var after := Player.position(_state)
		expect(signi(after.x - previous.x) == move.x and signi(after.y - previous.y) == move.y,
			"Diagonal movement advances both axes using actual core rules")
		view._process(0.13)
		expect(Player.facing(_state) == expected and view.playing() ==
			StringName("walk_%s" % PlayerArt.FACINGS[expected][0]), "Diagonal direction binds to core-facing art")
		await _shoot("diagonal_%d_%d" % [move.x, move.y], "Diagonal %s: core facing, shared feet" % str(move))
		_state["intent"]["move"] = [0, 0]
		view._process(0.0)
		expect(view.playing() == StringName("idle_%s" % PlayerArt.FACINGS[expected][0]),
			"Releasing diagonal input retains facing and enters authored idle")
	# Direction changes without recreating the view, including east -> west.
	for facing in [Player.EAST, Player.WEST, Player.NORTH, Player.SOUTH]:
		var step: Vector2i = Player.FACING_STEPS[facing]
		_state["intent"]["move"] = [step.x, step.y]
		Player.tick(_state)
		view._process(0.13)
		expect(view.playing() == StringName("walk_%s" % PlayerArt.FACINGS[facing][0])
			and view.flipped() == (facing == Player.EAST), "Immediate direction changes show the correct art")
		expect(view.position == ArtPlacement.contact(player["pos"]) and body.offset == Vector2(-24, -44),
			"Turning never adds an artificial canvas-width displacement")
		await _shoot("turn_%d" % facing, "Direction change / facing %d / no contact jump" % facing)


func _set_contact(who: Dictionary, pixels: Vector2i) -> void:
	var scale := Player.SUBTILE / GameData.TILE_SIZE
	who["pos"] = [pixels.x * scale, (pixels.y - GameData.TILE_SIZE / 2) * scale]


func _settle() -> void:
	var before := State.hash_of(_state)
	_world.show_state(_state)
	_world.get_node("Occupants/PlayerView").show_state(_state)
	for _i in 3:
		await process_frame
	expect(State.hash_of(_state) == before, "Drawing/showcase frame cannot change isolated simulation")


func _check_placement() -> void:
	var drawn := {}
	var house_count := 0
	for node in _world.get_node("Occupants").get_children():
		if node is Sprite2D and node.has_meta("logical_cells"):
			for idx in node.get_meta("logical_cells"):
				expect(not drawn.has(idx), "No duplicated logical cell in grouped sprites")
				drawn[idx] = true
			if node.texture.resource_path.ends_with("/house.png"):
				house_count += 1
				expect(node.position == Vector2(344, 144), "House node sorts at facade ground contact")
				expect(node.offset == Vector2(-32, -60), "House roof overhang retains its accepted source pivot")
			if node.texture.resource_path.ends_with("/tree.png"):
				expect(node.position == Vector2(200, 160), "Tree sorts by trunk contact, not canopy top")
				expect(node.offset == Vector2(-20, -44), "Tree uses source-owned pivot")
	expect(drawn.size() == (_state["occupants"] as Dictionary).size() and house_count == 1,
		"Exactly one house drawing covers all nine logical cells")
	var actors := _world.get_node("Occupants/Actors")
	expect(actors.y_sort_enabled, "Nested actors participate in their parent's y-sort")
	var enemy := Entities.get_one(_state, Entities.ids(_state)[0])
	expect(actors.get_child(0).position == ArtPlacement.contact(enemy["pos"]), "Enemy sort origin is its ground contact")
	var player := _world.get_node("Occupants/PlayerView")
	expect(player.position == ArtPlacement.contact(_state["player"]["pos"]), "Player and enemies share contact coordinates")
	var body: Sprite2D = player.get_node("Body")
	expect(body.offset == Vector2(-24, -44), "Pilot farmer is the accepted 30px source at its ground pivot")
	var light := ArtPlacement.emission(&"house", Vector2(320, 96), &"light", Vector2.ZERO)
	var smoke := ArtPlacement.emission(&"house", Vector2(320, 96), &"smoke", Vector2.ZERO)
	expect(light == Vector2(344, 127) and smoke == Vector2(361, 98), "Lamp/chimney anchor follows the same full house drawing")


func _shoot(name: String, caption: String) -> void:
	_caption.text = caption
	if not _capture:
		return
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	expect(image != null and image.get_size() == Vector2i(480, 270), "Capture is the native viewport")
	if image != null:
		expect(image.save_png(_folder + name + ".png") == OK, "Capture saved: " + name)


## Real texture frames on native canvases, grouped into review pages.
func _contacts() -> void:
	_world.visible = false
	var layer := Node2D.new()
	root.add_child(layer)
	_world.get_node("Camera").enabled = false
	root.canvas_transform = Transform2D.IDENTITY
	var paths: Array[String] = []
	for name in GameData.sorted_names(PlayerFrames.COUNT.keys()):
		for frame in int(PlayerFrames.COUNT[name]):
			paths.append(PlayerArt.texture_path(name, frame))
	for name in ["walker", "walker_walk_b", "walker_attack", "walker_death"]:
		paths.append(WorldView.ENEMY_DIR + name + ".png")
	paths.append(WorldView.BUILDING_DIR + "house.png")
	paths.append(WorldView.PROP_DIR + "tree.png")
	for page in ceili(float(paths.size()) / 28.0):
		for child in layer.get_children():
			child.queue_free()
		await process_frame
		for i in mini(28, paths.size() - page * 28):
			var path := paths[page * 28 + i]
			var sprite := Sprite2D.new()
			sprite.texture = load(path)
			sprite.centered = false
			var metadata: Dictionary = RasterArt.FRAMES.get(path, {})
			var pivot: Vector2 = Vector2(metadata.get("pivot", PlayerFrames.FEET))
			sprite.offset = -pivot
			sprite.position = Vector2(32 + i % 7 * 64, 80 + i / 7 * 58)
			layer.add_child(sprite)
			expect(sprite.texture != null, "Every contact frame has an actual texture")
		await _shoot("animation_frames_%02d" % page, "Committed player / walker frames at native scale; page %d" % page)
		for sprite in layer.get_children():
			sprite.modulate = Color.BLACK
		await _shoot("silhouettes_%02d" % page, "Native alpha silhouettes: committed actors and pilot landmarks")
	layer.queue_free()
