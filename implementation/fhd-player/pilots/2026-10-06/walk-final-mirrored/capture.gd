extends SceneTree

## Isolated same-camera before/after captures; no gameplay tick or promotion.
const HERE := "res://implementation/fhd-player/pilots/2026-10-06/walk-final-mirrored/"
const BASE := "res://implementation/fhd-player/pilots/2026-10-06/walk-up-right-low-step/runtime-80/"
const DIRECTIONS := ["down", "right", "up", "left", "down-right", "up-right", "up-left", "down-left"]
const CHANGED := ["up-left"]
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
	var body: Sprite2D = farmer.get_node("Body")
	var folder := ProjectSettings.globalize_path(HERE + "captures/")
	DirAccess.make_dir_recursive_absolute(folder)
	var captures: Array = []
	for night in [false, true]:
		var state := State.create(20261006)
		for key in ["occupants", "plots", "entities", "livestock", "crafting", "produced"]:
			(state[key] as Dictionary).clear()
		state["terrain"].fill(Farm.Terrain.GRASS)
		state["phase"] = Phases.NIGHT if night else Phases.DAY
		state["day_tick"] = GameData.DAY_TICKS / 2
		state["player"]["pos"] = [20 * Player.SUBTILE + Player.SUBTILE / 2, 10 * Player.SUBTILE + Player.SUBTILE / 2]
		world.show_state(state)
		world.look_at_cell(Vector2i(20, 10))
		world._process(5.0)
		farmer.show_state(state)
		farmer._process(0.0)
		body.centered = false
		body.flip_h = false
		body.offset = Vector2(-40, -72)
		body.scale = Vector2(0.5, 0.5)
		for variant in ["before", "after"]:
			for direction in DIRECTIONS:
				if variant == "after" and direction not in CHANGED:
					continue
				for frame in range(1, 9):
					var path := (BASE if variant == "before" else HERE + "runtime-80/") + "walk/%s/%02d.png" % [direction, frame]
					var image := Image.load_from_file(ProjectSettings.globalize_path(path))
					expect(image.get_size() == Vector2i(80, 80), "Fixed runtime canvas")
					body.texture = ImageTexture.create_from_image(image)
					var before := var_to_bytes(state)
					await process_frame
					await RenderingServer.frame_post_draw
					expect(var_to_bytes(state) == before, "Review leaves simulation untouched")
					var rendered := root.get_texture().get_image()
					expect(rendered.get_size() == Vector2i(1920, 1080), "Real FHD output")
					var contact: Vector2 = root.get_stretch_transform() * (farmer.get_global_transform_with_canvas() * Vector2.ZERO)
					var region := Rect2i(Vector2i(contact) - Vector2i(120, 205), Vector2i(240, 240))
					expect(Rect2i(Vector2i.ZERO, rendered.get_size()).encloses(region), "Unscaled crop around fixed feet pivot")
					var label := "%s_%s_%s_%02d" % ["night" if night else "day", variant, direction, frame]
					rendered.get_region(region).save_png(folder + label + ".png")
					captures.append({"label":label,"source":path,"frame":frame,"seconds":0.1,"contact": [contact.x,contact.y]})
	var file := FileAccess.open(HERE + "renderer-report.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":captures}, "  ") + "\n")
	print("FINAL MIRROR REVIEW: %d checks, %d failed" % [checks, failures])
	quit(1 if failures else 0)
