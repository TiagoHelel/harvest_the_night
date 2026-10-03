extends SceneTree

## Production World/PlayerView, true FHD rendering, real core movement at 30Hz.
## Captures are isolated from player saves. View clocks run at 25fps for GIFs.
const HERE := "res://implementation/fhd-player/directional/"
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
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var report: Array = []
	for night in [false, true]:
		for motion in ["idle", "walk", "run"]:
			for facing in 4:
				var state := State.create(20261002)
				for key in ["occupants", "plots", "entities", "livestock", "crafting", "produced"]:
					(state[key] as Dictionary).clear()
				state["terrain"].fill(Farm.Terrain.GRASS)
				state["phase"] = Phases.NIGHT if night else Phases.DAY
				state["day_tick"] = GameData.DAY_TICKS / 2
				state["player"]["pos"] = [20 * Player.SUBTILE, 10 * Player.SUBTILE]
				state["player"]["facing"] = facing
				var step: Vector2i = Player.FACING_STEPS[facing] if motion != "idle" else Vector2i.ZERO
				state["intent"]["move"] = [step.x, step.y]
				world.show_state(state)
				view.show_state(state)
				view.set_running(motion == "run")
				world.look_at_cell(Vector2i(20, 10))
				world._process(5.0)
				await process_frame
				await process_frame
				var clock := 0.0
				var seen := {}
				var label := "%s_%s_%s" % ["night" if night else "day", motion, PlayerArt.FACINGS[facing][0]]
				for frame in (96 if motion == "idle" else 48):
					clock += 30.0 / 25.0
					while clock >= 1.0:
						Player.tick(state)
						clock -= 1.0
					var before := var_to_bytes(state)
					view._process(1.0 / 25.0)
					expect(var_to_bytes(state) == before, "Rendering cannot mutate movement or save state")
					expect(view.playing() == StringName(motion + "_" + String(PlayerArt.FACINGS[facing][0])), "Actual runtime animation/facing")
					var body: Sprite2D = view.get_node("Body")
					seen[body.texture.resource_path] = true
					await process_frame
					await RenderingServer.frame_post_draw
					var rendered := root.get_texture().get_image()
					expect(rendered.get_size() == Vector2i(1920, 1080), "Physical FHD render")
					var contact: Vector2 = root.get_stretch_transform() * (view.get_global_transform_with_canvas() * Vector2.ZERO)
					var region := Rect2i(Vector2i(contact) - Vector2i(128, 176), Vector2i(256, 208))
					expect(Rect2i(Vector2i.ZERO, rendered.get_size()).encloses(region), "Actor crop is fully on screen")
					rendered.get_region(region).save_png(folder + "%s_%03d.png" % [label, frame])
					if frame == 8 and facing == Player.EAST and motion != "idle":
						rendered.save_png(folder + label + "_fhd.png")
					if frame == 0:
						print("CONTACT %s: %s" % [label, contact])
				expect(seen.size() == (3 if motion == "idle" else 8), "Every runtime pose appears over time")
				report.append({"sequence":label,"poses":seen.size(),"size":[1920,1080],"fps":25})
	var file := FileAccess.open(HERE + "runtime-capture-report.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"sequences":report}, "  ") + "\n")
	print("FHD RUNTIME CAPTURE: %d checks, %d failed" % [checks, failures])
	quit(1 if failures else 0)
