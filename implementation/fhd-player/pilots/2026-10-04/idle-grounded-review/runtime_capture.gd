extends SceneTree

## Actual production World/PlayerView, normal 30Hz movement, FHD day/night.
const HERE := "res://implementation/fhd-player/pilots/2026-10-04/idle-grounded-review/"
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
	relight.name = "Relight"
	relight.layer = 1
	root.add_child(relight)
	var world: WorldView = load("res://scenes/World.tscn").instantiate()
	root.add_child(world)
	await process_frame
	world.set_process(false)
	var view: PlayerView = world.get_node("Occupants/PlayerView")
	view.set_process(false)
	var folder := HERE + "runtime-captures/"
	var candidate := OS.get_cmdline_user_args().has("--diagonal-candidate")
	if candidate:
		folder = HERE + "diagonal-candidate/runtime-captures/"
		# Review-only source injection into the actual production view. It
		# retains the normal clock/placement and never changes runtime files.
		for suffix in ["north_east", "north_west"]:
			var direction := "up-right" if suffix == "north_east" else "up-left"
			for index in 8:
				var path := PlayerArt.texture_path(StringName("walk_" + suffix), index)
				var image := Image.load_from_file(ProjectSettings.globalize_path(HERE + "diagonal-candidate/frames/%s/%02d.png" % [direction,index+1]))
				var texture := ImageTexture.create_from_image(image)
				texture.resource_name = path.get_file()
				view._textures[path] = texture
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var report: Array = []
	for night in [false, true]:
		for heading in PlayerArt.HEADINGS:
			var state := State.create(20261005)
			for key in ["occupants", "plots", "entities", "livestock", "crafting", "produced"]:
				(state[key] as Dictionary).clear()
			state["terrain"].fill(Farm.Terrain.GRASS)
			state["phase"] = Phases.NIGHT if night else Phases.DAY
			state["day_tick"] = GameData.DAY_TICKS / 2
			state["player"]["pos"] = [20 * Player.SUBTILE, 10 * Player.SUBTILE]
			state["player"]["facing"] = Player.facing_for(heading.x, heading.y, Player.SOUTH)
			state["intent"]["move"] = [0, 0]
			world.show_state(state)
			view.show_state(state)
			view._heading = heading
			world.look_at_cell(Vector2i(20, 10))
			world._process(5.0)
			await process_frame
			await process_frame
			var suffix: StringName = PlayerArt.HEADINGS[heading]
			var label := "%s_%s" % ["night" if night else "day", suffix]
			var trace: Array = []
			var moving_poses := {}
			for frame in 72:
				var moving := frame >= 12 and frame < 60
				state["intent"]["move"] = [heading.x, heading.y] if moving else [0, 0]
				Player.tick(state)
				var before := var_to_bytes(state)
				view._process(1.0 / 30.0)
				expect(var_to_bytes(state) == before, "View cannot mutate simulation/save state")
				var body: Sprite2D = view.get_node("Body")
				var family := StringName(("walk_" if moving else "idle_") + String(suffix))
				expect(view.playing() == family, "Normal idle-walk-idle direction selection")
				if moving:
					moving_poses[body.texture.get_instance_id()] = true
				else:
					expect(body.texture.resource_path == PlayerArt.texture_path(family, 0), "Stopped farmer uses independent grounded pose")
				trace.append(body.texture.resource_path.get_file() if not body.texture.resource_path.is_empty() else body.texture.resource_name)
				await process_frame
				await RenderingServer.frame_post_draw
				if frame % 3 == 0:
					var rendered := root.get_texture().get_image()
					expect(rendered.get_size() == Vector2i(1920, 1080), "Physical FHD capture")
					var contact: Vector2 = root.get_stretch_transform() * (view.get_global_transform_with_canvas() * Vector2.ZERO)
					var region := Rect2i(Vector2i(contact) - Vector2i(128, 176), Vector2i(256, 208))
					expect(Rect2i(Vector2i.ZERO, rendered.get_size()).encloses(region), "Native actor crop remains on screen")
					rendered.get_region(region).save_png(folder + "%s_%02d.png" % [label, frame / 3])
					if frame in [0, 12, 60]:
						rendered.save_png(folder + "%s_fhd_%02d.png" % [label, frame])
			expect(moving_poses.size() == 8, "Two normal-speed loops visit all eight preserved walk frames")
			report.append({"sequence":label,"walk_poses":moving_poses.size(),"render_fps":30,"capture_fps":10,
				"size":[1920,1080],"trace":trace,"durations_seconds":{"idle_before":.4,"walk":1.6,"idle_after":.4}})
	var file := FileAccess.open(HERE + ("diagonal-candidate/runtime-capture-report.json" if candidate else "runtime-capture-report.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"sequences":report}, "  ") + "\n")
	print("GROUNDED IDLE PLAYBACK: %d checks, %d failed" % [checks, failures])
	quit(1 if failures else 0)
