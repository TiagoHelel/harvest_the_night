extends SceneTree

## Candidate-only visual review in the real game. No source family is promoted.
const OUT := "res://implementation/fhd-player/approved-pilot-review/"
const CANDIDATE := "res://assets/art_source/player-fhd/approved/frames/idle_south_0.png"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	CaptureSize.configure(root, true)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var main: Node = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.begin_run(82082082)
	var driver: Node = main.get_node("%SimDriver")
	driver.set_process(false)
	var state: Dictionary = driver.state
	state["tick"] = GameData.DUSK_AT_TICK / 2
	state["player"]["pos"] = [17 * Player.SUBTILE + Player.SUBTILE / 2,
		9 * Player.SUBTILE + Player.SUBTILE / 2]
	state["intent"]["move"] = [0, 0]
	state["player"]["facing"] = Player.SOUTH
	var world: WorldView = main.get_node("%WorldView")
	world.show_state(state)
	world.look_at_cell(Player.cell(state))
	world.skip_transition()
	world._light_for_phase(0.0)
	var player: PlayerView = world.get_node("Occupants/PlayerView")
	player.show_state(state)
	player._process(0.0)
	player.set_process(false)
	var body: Sprite2D = player.get_node("Body")
	body.texture = load(CANDIDATE)
	body.scale = Vector2(0.5, 0.5)
	body.offset = Vector2(-48, -88)
	player.get_node("ReactionBubble").hide()
	I18n.use("pt_BR")
	I18n.relabel(main)
	# Art review focuses on actual scenery and depth, without tutorial overlays.
	main.get_node("UI").hide()
	for frame in 30:
		await process_frame
	await RenderingServer.frame_post_draw
	var picture := root.get_texture().get_image()
	if picture == null or picture.get_size() != Vector2i(1920, 1080):
		push_error("Pilot review must use an actual FHD render target")
		quit(1)
		return
	picture.save_png(ProjectSettings.globalize_path(OUT + "farm-fhd.png"))
	var feet := player.get_global_transform_with_canvas() * Vector2.ZERO
	feet *= Vector2(picture.get_size()) / root.get_visible_rect().size
	var crop := Rect2i(Vector2i(feet) - Vector2i(170, 200), Vector2i(340, 260))
	picture.get_region(crop).save_png(ProjectSettings.globalize_path(OUT + "farm-detail.png"))
	print("FHD PILOT: real %s render, unchanged source family, candidate drawn at half scale; feet %s" % [picture.get_size(), feet])
	quit(0)
