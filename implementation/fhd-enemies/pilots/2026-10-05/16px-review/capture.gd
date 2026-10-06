extends SceneTree

## Isolated authored-pose review through the real WorldView/Relight renderer.
## It does not run combat or modify production textures, simulation or saves.
const HERE := "res://implementation/fhd-enemies/pilots/2026-10-05/16px-review/"
const FARMER := "res://implementation/fhd-player/pilots/2026-10-04/idle-grounded-review/resolution-review/16px-assets/runtime-80/idle/left.png"
const FARMER32 := HERE + "farmer32/idle-left.png"
var checks := 0
var failures := 0

func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	CaptureSize.configure(root, true)
	var relight := Relight.new()
	relight.layer = 1
	root.add_child(relight)
	var world: WorldView = load("res://scenes/World.tscn").instantiate()
	root.add_child(world)
	await process_frame
	world.set_process(false)
	var farmer: PlayerView = world.get_node("Occupants/PlayerView")
	farmer.set_process(false)
	farmer.visible = true
	var farmer32 := PlayerView.new()
	world.get_node("Occupants").add_child(farmer32)
	farmer32.set_process(false)
	var records: Array = JSON.parse_string(FileAccess.get_file_as_string(HERE + "frame-list.json"))
	var kinds := [&"walker", &"runner", &"tank", &"breaker", &"giant"]
	var folder := ProjectSettings.globalize_path(HERE + "captures/")
	DirAccess.make_dir_recursive_absolute(folder)
	var report: Array = []
	var farmer_report: Array = []
	for night in [false, true]:
		var state := State.create(20261005)
		for key in ["occupants", "plots", "entities", "livestock", "crafting", "produced"]:
			(state[key] as Dictionary).clear()
		state["terrain"].fill(Farm.Terrain.GRASS)
		state["phase"] = Phases.NIGHT if night else Phases.DAY
		state["day_tick"] = GameData.DAY_TICKS / 2
		state["player"]["pos"] = [32 * Player.SUBTILE + Player.SUBTILE / 2, 10 * Player.SUBTILE + Player.SUBTILE / 2]
		for i in kinds.size():
			Entities.spawn(state, kinds[i], Vector2i(12 + i * 4, 10))
		world.show_state(state)
		world.look_at_cell(Vector2i(24, 10))
		world._process(5.0)
		farmer.show_state(state)
		farmer._heading = Vector2i(-1, 0)
		farmer._process(0.0)
		var body: Sprite2D = farmer.get_node("Body")
		var farmer_image := Image.load_from_file(ProjectSettings.globalize_path(FARMER))
		body.texture = ImageTexture.create_from_image(farmer_image)
		expect(farmer_image.get_size() == Vector2i(80, 80), "Existing 16px farmer runtime canvas")
		expect(body.offset == Vector2(-40, -72) and body.scale == Vector2(0.5, 0.5), "Production farmer pivot and draw scale")
		var state32 := state.duplicate(true)
		state32["player"]["pos"][0] = 36 * Player.SUBTILE + Player.SUBTILE / 2
		farmer32.show_state(state32)
		farmer32._heading = Vector2i(-1, 0)
		farmer32._process(0.0)
		var body32: Sprite2D = farmer32.get_node("Body")
		var image32 := Image.load_from_file(ProjectSettings.globalize_path(FARMER32))
		body32.texture = ImageTexture.create_from_image(image32)
		expect(image32.get_size() == Vector2i(80, 80) and body32.offset == body.offset and body32.scale == body.scale, "32px farmer preserves production canvas, pivot and draw scale")
		await process_frame
		for coarse in [false, true]:
			for record in records:
				var before := var_to_bytes(state)
				var before32 := var_to_bytes(state32)
				for i in kinds.size():
					var name: String = record["names"][i]
					var source := "res://sprites/enemies/" + name + ".png"
					var path := HERE + "runtime-size/" + name + ".png" if coarse else source
					var image := Image.load_from_file(ProjectSettings.globalize_path(path))
					var sprite: Sprite2D = world._actor_sprites[i]
					sprite.texture = ImageTexture.create_from_image(image)
					sprite.flip_h = false
					sprite.offset = -Vector2(RasterArt.FRAMES[source]["pivot"])
					expect(image.get_size() == Vector2i(RasterArt.FRAMES[source]["canvas"]), "Canvas retained")
				for _tick in 3:
					await process_frame
					await RenderingServer.frame_post_draw
				expect(var_to_bytes(state) == before, "Authored pose preview leaves simulation untouched")
				expect(var_to_bytes(state32) == before32, "32px farmer preview state unchanged")
				var rendered := root.get_texture().get_image()
				expect(rendered.get_size() == Vector2i(1920, 1080), "Real FHD renderer")
				var strip := Image.create(1680, 240, false, Image.FORMAT_RGBA8)
				for j in kinds.size():
					var sprite: Sprite2D = world._actor_sprites[j]
					var contact: Vector2 = root.get_stretch_transform() * (sprite.get_global_transform_with_canvas() * Vector2.ZERO)
					var region := Rect2i(Vector2i(contact) - Vector2i(120, 205), Vector2i(240, 240))
					expect(Rect2i(Vector2i.ZERO, rendered.get_size()).encloses(region), "Full unscaled actor crop")
					strip.blit_rect(rendered, region, Vector2i(j * 240, 0))
				var farmer_contact: Vector2 = root.get_stretch_transform() * (farmer.get_global_transform_with_canvas() * Vector2.ZERO)
				var farmer_region := Rect2i(Vector2i(farmer_contact) - Vector2i(120, 205), Vector2i(240, 240))
				expect(Rect2i(Vector2i.ZERO, rendered.get_size()).encloses(farmer_region), "Full unscaled 16px farmer crop")
				strip.blit_rect(rendered, farmer_region, Vector2i(1200, 0))
				var contact32: Vector2 = root.get_stretch_transform() * (farmer32.get_global_transform_with_canvas() * Vector2.ZERO)
				var region32 := Rect2i(Vector2i(contact32) - Vector2i(120, 205), Vector2i(240, 240))
				expect(Rect2i(Vector2i.ZERO, rendered.get_size()).encloses(region32), "Full unscaled 32px farmer crop")
				strip.blit_rect(rendered, region32, Vector2i(1440, 0))
				var label := "%s_%s_%s" % ["night" if night else "day", "coarse" if coarse else "original", record["label"]]
				strip.save_png(folder + label + ".png")
				if record["label"] == "walk_0":
					rendered.save_png(folder + label + "_FHD.png")
				report.append({"label":label, "names":record["names"], "farmer":FARMER, "farmer32":FARMER32, "farmer_pose":"idle left", "source": "isolated authored pose review", "view_hz":30})
		for direction in ["down", "right", "up", "left", "down-right", "up-right", "up-left", "down-left"]:
			for frame in range(1, 9):
				var path := HERE + "farmer32/runtime-80/walk/%s/%02d.png" % [direction, frame]
				var image := Image.load_from_file(ProjectSettings.globalize_path(path))
				var before := var_to_bytes(state32)
				body32.texture = ImageTexture.create_from_image(image)
				expect(image.get_size() == Vector2i(80, 80), "32px walk runtime canvas preserved")
				await process_frame
				await RenderingServer.frame_post_draw
				expect(var_to_bytes(state32) == before, "32px walk preview does not advance game state")
				var rendered := root.get_texture().get_image()
				var contact: Vector2 = root.get_stretch_transform() * (farmer32.get_global_transform_with_canvas() * Vector2.ZERO)
				var region := Rect2i(Vector2i(contact) - Vector2i(120, 205), Vector2i(240, 240))
				expect(Rect2i(Vector2i.ZERO, rendered.get_size()).encloses(region), "Unscaled walking farmer crop")
				var label := "%s_farmer32_walk_%s_%02d" % ["night" if night else "day", direction, frame]
				rendered.get_region(region).save_png(folder + label + ".png")
				farmer_report.append({"label":label,"source":path,"frame":frame,"seconds":0.1})
	var file := FileAccess.open(HERE + "renderer-report.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":report,"farmer_walk_captures":farmer_report}, "  ") + "\n")
	print("ZOMBIE16 REVIEW: %d checks, %d failed" % [checks, failures])
	quit(1 if failures else 0)
