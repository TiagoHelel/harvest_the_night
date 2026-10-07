extends SceneTree

## The DEF4ULT STUDIO ident, photographed beat by beat from the real renderer,
## so its timing can be reviewed as stills instead of by staring at an 8.5 s
## clip - and so it can be laid over WELCOME BACK, HERO's own pictures of it.
##
##     godot --path . --fixed-fps 30 --position -4000,-4000 \
##         --script res://src/tools/capture_intro.gd -- [--out=<dir>] [--size=1920x1080] [--realtime]
##
## **The clock is driven, not waited on.** Every still stops the ident's own
## `_process` and sets its clock, so each shot is exactly the second it says it
## is. The beats and their names are that game's `capture_intro.gd` SHOTS, so
## `--size=1280x720` here and its default there photograph the same frames.
##
## `--realtime` instead lets the ident run out on its own and keeps every
## `STRIDE`th frame through the hand-over and the title rising from black - the
## one thing the driven clock cannot reach, because the title does not exist
## until the ident has gone. Pass `--fixed-fps` so the strip is paced by the
## clock and not by the renderer.

const OUT := "res://implementation/shots/studio-intro/"

## (seconds on the ident's clock, name) - that game's beats, unchanged.
const SHOTS: Array = [
	[-1.00, "00_lead"],     # the black lead: black, with no static yet
	[0.22, "01_power"],     # tube striking, shutter still mostly shut
	[0.85, "02_open"],      # frame open, crest starting to resolve
	[1.50, "03_sweep"],     # lock-on arc mid-turn
	[2.40, "04_ignite"],    # core flare + sting
	[3.00, "05_name"],      # studio name half settled
	[4.10, "06_tag"],       # PRESENTS coming in
	[5.20, "07_hold"],      # the frame the ident is for
	[5.85, "08_collapse"],  # shutter closing
	[6.25, "09_black"],     # held black: the dying sliver gone by here
]

## How many frames of the real-time run make one picture of it.
const STRIDE := 3

## How long the real-time run goes on after the ident starts: its eight and a
## half seconds and the title's second of rising, with a little over.
const REALTIME_SECONDS := 10.0

var _out := OUT
var _size := Vector2i(1920, 1080)
var _written := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var realtime := false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
			if not _out.ends_with("/"):
				_out += "/"
		elif arg.begins_with("--size="):
			var parts := arg.trim_prefix("--size=").split("x")
			_size = Vector2i(int(parts[0]), int(parts[1]))
		elif arg == "--realtime":
			realtime = true
	var folder := _out if not _out.begins_with("res://") \
		else ProjectSettings.globalize_path(_out)
	DirAccess.make_dir_recursive_absolute(folder)
	root.size = _size
	await process_frame
	await process_frame

	var router: Node = root.get_node_or_null(^"App")
	if router != null:
		router.reset(router.BOOT)
	var ident := load("res://scenes/StudioIntro.tscn").instantiate() as StudioIntro
	root.add_child(ident)
	await process_frame
	if realtime:
		await _realtime(folder, ident)
	else:
		ident.set_process(false)
		for shot in SHOTS:
			ident.set_clock(float(shot[0]))
			await _shoot(folder, String(shot[1]))
		root.remove_child(ident)
		ident.free()
	print("STUDIO INTRO: %d pictures at %dx%d into %s"
		% [_written, _size.x, _size.y, folder])
	quit(0)


## The ident runs out by itself and hands over; every `STRIDE`th frame is kept
## until the title has come up out of the black.
func _realtime(folder: String, ident: StudioIntro) -> void:
	var frame := 0
	var kept := 0
	var started := Time.get_ticks_msec()
	# `--fixed-fps` pins every frame's delta, so the frame count is the clock.
	var fixed := 30
	var args := OS.get_cmdline_args()
	var at := args.find("--fixed-fps")
	if at >= 0 and at + 1 < args.size() and String(args[at + 1]).is_valid_int():
		fixed = maxi(int(args[at + 1]), 1)
	var budget := int(REALTIME_SECONDS * float(fixed))
	while frame < budget:
		if frame % STRIDE == 0:
			await _shoot(folder, "rt_%04d" % kept)
			kept += 1
		else:
			await process_frame
		frame += 1
	if is_instance_valid(ident) and ident.is_inside_tree():
		root.remove_child(ident)
		ident.free()
	if current_scene != null:
		var title := current_scene
		current_scene = null
		root.remove_child(title)
		title.free()
	print("realtime: %d frames, %d kept, %.1f s of wall clock"
		% [frame, kept, (Time.get_ticks_msec() - started) / 1000.0])


func _shoot(folder: String, name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null:
		return
	image.convert(Image.FORMAT_RGB8)
	image.save_png(folder.path_join(name + ".png"))
	_written += 1
