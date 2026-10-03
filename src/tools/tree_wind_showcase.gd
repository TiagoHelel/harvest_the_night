extends SceneTree

## Real renderer proof: all exposed wood stays identical to the static source.
const OUT := "res://implementation/reviews/tree-wind/captures/"
var checks := 0
var failed := 0


func _initialize() -> void:
	call_deferred("_run")


func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failed += 1
		push_error(message)


func _read() -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()


func _run() -> void:
	CaptureSize.configure(root)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var world: WorldView = load("res://scenes/World.tscn").instantiate()
	root.add_child(world)
	await process_frame
	world.set_process(false)
	world.get_node("Occupants/PlayerView").set_process(false)
	world.get_node("Occupants/PlayerView").hide()
	var state := State.create(251020)
	state["terrain"].fill(Farm.Terrain.GRASS)
	state["occupants"].clear()
	for cell in [Vector2i(18,9), Vector2i(23,9), Vector2i(28,9)]:
		state["occupants"][Grid.index(cell)] = {"id": &"tree"}
	world.show_state(state)
	world.look_at_cell(Vector2i(23,10))
	world._process(0.0)
	var immutable := var_to_bytes(state)
	var materials: Array[ShaderMaterial] = []
	var tops: Array[Vector2i] = []
	var parameters: Array = []
	for sprite in world._sprites:
		materials.append(sprite.material)
		tops.append(Vector2i(sprite.get_global_transform_with_canvas() * sprite.offset))
		var speed := float(sprite.material.get_shader_parameter("wind_speed"))
		var strength := float(sprite.material.get_shader_parameter("wind_strength"))
		expect(speed >= 0.55 and speed <= 0.95, "Wind speeds stay gentle")
		expect(strength >= 0.65 and strength <= 0.95, "Leaf displacement stays below one native pixel")
		parameters.append({"texture": sprite.texture.resource_path, "top": [tops[-1].x,tops[-1].y],
			"speed": speed, "strength": strength,
			"phase": sprite.material.get_shader_parameter("phase")})
	expect(parameters[0]["speed"] != parameters[1]["speed"]
		and parameters[1]["speed"] != parameters[2]["speed"], "Neighboring trees have independent rhythms")
	for night in [false,true]:
		state["phase"] = Phases.NIGHT if night else Phases.DAY
		world._light_for_phase(5.0)
		for sprite in world._sprites:
			sprite.material = null
		var reference := await _read()
		var prefix := "night" if night else "day"
		expect(reference.save_png(OUT + prefix + "-static.png") == OK, "Static reference saves")
		for i in world._sprites.size():
			world._sprites[i].material = materials[i]
		var seen: Array[Dictionary] = [{},{},{}]
		for frame in 360:
			world._refresh_ambient(1.0 / 30.0)
			var capture := await _read()
			for i in tops.size():
				var wood := Rect2i(tops[i] + Vector2i(0,22), Vector2i(40,26))
				expect(capture.get_region(wood).get_data() == reference.get_region(wood).get_data(),
					"Trunk, branches and roots remain pixel-identical to static art")
				seen[i][hash(capture.get_region(Rect2i(tops[i], Vector2i(40,22))).get_data())] = true
			expect(capture.get_size() == Vector2i(480,270), "Capture uses native game size")
			expect(capture.save_png(OUT + "%s-%03d.png" % [prefix,frame]) == OK, "Native frame saves")
		for versions in seen:
			expect(versions.size() > 100, "Subpixel foliage evolves smoothly rather than switching between a few poses")
	state["phase"] = Phases.DAY
	expect(var_to_bytes(state) == immutable, "Wind cannot change simulation or its RNG")
	var clock := world._ambient_time
	world.ambient_running = false
	world._refresh_ambient(1.0)
	expect(world._ambient_time == clock, "Pause freezes wind")
	var file := FileAccess.open(OUT + "../parameters.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(parameters, "\t") + "\n")
	print("TREE WIND: %d checks, %d failed" % [checks,failed])
	quit(1 if failed else 0)
