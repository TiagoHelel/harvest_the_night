extends SceneTree

## Dawn after a lost night, photographed from the real game at 1920x1080: the
## house falls with zombies still in the yard, the result is read, and the
## morning sends them walking off. Through the real driver, router and view,
## so what is reviewed is what a player sees rather than a test rig.
##
##     godot --path . --fixed-fps 30 --position -4000,-4000 \
##         --script res://src/tools/capture_dawn.gd -- [--out=<dir>]
##
## Writes `night.png` (the yard before the house falls), `result.png`, and
## every `STRIDE`th frame of the morning as `dawn_NN.png`. Pass
## `--fixed-fps` so the strip is paced by the clock and not by the renderer.
## The reviewed set keeps two of the strip and a `playback.gif` made from all
## of it, a tenth of a second a picture.

const OUT := "res://implementation/shots/dawn/"
const RUN_SEED := 20260927
## How many frames of the morning make one picture of it.
const STRIDE := 3
## How long the morning is watched: the walk off and a little over.
const DAWN_SECONDS := 3.0
## Where the night's winners stand, from the house's centre.
const YARD: Array = [
	[&"walker", Vector2i(-4, -1)], [&"walker", Vector2i(-5, 2)],
	[&"runner", Vector2i(4, 0)], [&"walker", Vector2i(5, 2)],
	[&"tank", Vector2i(-2, 4)], [&"breaker", Vector2i(2, 4)],
	[&"walker", Vector2i(3, -4)], [&"runner", Vector2i(-3, -4)],
]

var _out := OUT
var _written := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	CaptureSize.configure(root, true)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
			if not _out.ends_with("/"):
				_out += "/"
	var folder := _out if not _out.begins_with("res://") \
		else ProjectSettings.globalize_path(_out)
	DirAccess.make_dir_recursive_absolute(folder)
	var router: Node = root.get_node(^"App")
	router.reset(router.RUN)
	var main: Node = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await _settle(4)
	main.begin_run(RUN_SEED)
	await _settle(6)
	var driver: SimDriver = main.get_node("%SimDriver")
	var state: Dictionary = driver.state

	# Straight into the dark with a crowd already in the yard, and once it
	# has been seen closing in, a house one bite from falling.
	Phases.begin_preparation(state)
	Phases.start_waves(state)
	var home := Farm.house_centre(state)
	for entry in YARD:
		var cell: Vector2i = home + (entry[1] as Vector2i)
		if Farm.walkable(state, cell):
			Entities.spawn(state, entry[0], cell)
	await _settle(45)
	await _shoot(folder, "night")
	state["house_hp"] = 1

	for _frame in 30 * 30:
		if int(state["phase"]) != Phases.NIGHT:
			break
		await process_frame
	print("DAWN CAPTURE: the night ended %s with %d still in the yard"
		% [Phases.name_of(int(state["phase"])), Entities.count(state)])
	await _settle(20)
	await _shoot(folder, "result")

	var result := main.find_child("ResultScreen", true, false)
	if result != null and result.has_method("_confirm"):
		result.call("_confirm")
	else:
		(state["intent"] as Dictionary)["confirm_result"] = true
	var frames := int(DAWN_SECONDS * 30.0)
	for i in frames:
		await process_frame
		if i % STRIDE == 0:
			await _shoot(folder, "dawn_%02d" % (i / STRIDE))
	print("DAWN CAPTURE: %d pictures into %s, %d zombies left by day"
		% [_written, folder, Entities.count(state)])
	root.remove_child(main)
	main.free()
	quit(0)


func _settle(frames: int) -> void:
	for _i in frames:
		await process_frame


func _shoot(folder: String, name: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null:
		return
	image.convert(Image.FORMAT_RGB8)
	image.save_png(folder.path_join(name + ".png"))
	_written += 1
