extends SceneTree

## Native evidence and regression guards for the fixed camera, tracking and idle life.
var _world: WorldView
var _player: PlayerView
var _state: Dictionary
var _capture := false
var _folder := "res://implementation/reviews/world-visibility/captures/"
var _checks := 0
var _failed := 0


func _initialize() -> void:
	call_deferred("_run")


func expect(ok: bool, message: String) -> void:
	_checks += 1
	if not ok:
		_failed += 1
		push_error(message)


func _run() -> void:
	CaptureSize.configure(root)
	_capture = not OS.get_cmdline_user_args().has("--check")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_folder))
	_world = load("res://scenes/World.tscn").instantiate()
	root.add_child(_world)
	await process_frame
	_world.set_process(false)
	_player = _world.get_node("Occupants/PlayerView")
	_player.set_process(false)
	_state = State.create(251020)
	_world.show_state(_state)
	_player.show_state(_state)
	_world.look_at_cell(Vector2i(24, 10))
	_world._process(0.0)
	_player._process(0.0)
	await _shoot("farm-default")
	var unchanged := var_to_bytes(_state)
	var sub := Vector2i(24 * Player.SUBTILE + 32, 10 * Player.SUBTILE + 32)
	var start := _world._camera.position
	_world.follow_player(sub + Vector2i(2, 0), 1.0 / 60.0)
	expect(_world._camera.position.x > start.x and _world._camera.position.x - start.x < 0.5,
		"Camera responds smoothly to movement within one cell")
	# **No zoom, as in Stardew Valley**: one tile is always 16 native pixels,
	# 64 screen pixels at 1920x1080, and the farmer two tiles tall.
	expect(not _world.has_method("change_zoom") and not _world.has_method("reset_zoom"),
		"The farm camera exposes no zoom")
	for frame in 90:
		_world.follow_player(sub, 1.0 / 60.0)
	expect(_world._camera.zoom == Vector2.ONE, "The camera stays at the fixed Stardew-like scale")
	var far_corner := Vector2i(Grid.WIDTH - 1, Grid.HEIGHT - 1)
	for cell in [Vector2i.ZERO, far_corner, Vector2i(23,10), Vector2i(Grid.WIDTH - 1, 0), Vector2i(0, Grid.HEIGHT - 1)]:
		_world.look_at_cell(cell)
		var half := Vector2(480,270) * 0.5
		var centre := _world._camera.position
		expect(centre.x >= half.x and centre.y >= half.y and centre.x + half.x <= WorldView.WORLD_SIZE.x
			and centre.y + half.y <= WorldView.WORLD_SIZE.y, "Panning keeps all viewport corners inside the farm")
		expect(_world.screen_to_cell(_world.cell_to_screen(cell)) == cell, "The fixed camera preserves cell picking")
		await _shoot("pan-%d-%d" % [cell.x, cell.y])
	expect(var_to_bytes(_state) == unchanged, "Camera controls never alter the saved simulation")
	for frame in 90:
		_world.follow_player(sub, 1.0 / 60.0)
	_world.look_at_cell(Vector2i(24,10))
	for frame in 90:
		var last := _world._camera.position
		_world.follow_player(sub + Vector2i(frame * 3, 0), 1.0 / 60.0)
		expect(_world._camera.position.distance_to(last) < 2.0, "Normal follow has no tile-size jump")
		await _shoot("camera-%03d" % frame)
	await _ambient()
	print("VISIBILITY SHOWCASE: %d checks, %d failed" % [_checks, _failed])
	quit(1 if _failed else 0)


func _ambient() -> void:
	# Keep the ordinary art in a quiet, reproducible section of real-sized ground.
	_state["terrain"].fill(Farm.Terrain.GRASS)
	_state["occupants"].clear()
	for entry in [[&"tree",Vector2i(20,9)],[&"cow",Vector2i(24,9)],[&"chicken",Vector2i(26,9)]]:
		_state["occupants"][Grid.index(entry[1])] = {"id":entry[0]}
	_state["player"]["pos"] = [23*64+32, 10*64+32]
	_state["player"]["facing"] = Player.SOUTH
	_world.show_state(_state)
	_world._camera.zoom = Vector2.ONE
	_world.look_at_cell(Vector2i(23,10))
	var original := var_to_bytes(_state)
	var positions: Array = []
	for sprite in _world._sprites:
		positions.append(sprite.position)
	for night in [false, true]:
		_state["phase"] = Phases.NIGHT if night else Phases.DAY
		_world._light_for_phase(5.0)
		for frame in 90:
			_world._process(1.0/15.0)
			_player._process(1.0/15.0)
			await _shoot("ambient-%s-%03d" % ["night" if night else "day",frame])
		for i in _world._sprites.size():
			expect(_world._sprites[i].position == positions[i], "Ambient movement retains every ground anchor")
	_state["phase"] = Phases.DAY
	expect(var_to_bytes(_state) == original, "Ambient animation and blinking never change simulation")
	var clock_before := _world._ambient_time
	_world.ambient_running = false
	_world._process(1.0)
	expect(_world._ambient_time == clock_before, "Pausing freezes all ambient movement")


func _shoot(name: String) -> void:
	if not _capture:
		return
	await process_frame
	await RenderingServer.frame_post_draw
	var frame := root.get_texture().get_image()
	expect(frame.get_size() == Vector2i(480,270), "Evidence uses the actual native viewport")
	expect(frame.save_png(_folder + name + ".png") == OK, "Native capture saves")
