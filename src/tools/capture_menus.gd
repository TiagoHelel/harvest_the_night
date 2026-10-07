extends SceneTree

## The menus, photographed from the real renderer at 1920x1080 - the title
## menu, the pause menu and its questions, and every page of the options - so
## a change to how a button looks or behaves is reviewed in the game's own
## frame rather than in a drawing of one.
##
##     godot --path . --position -4000,-4000 \
##         --script res://src/tools/capture_menus.gd -- [--out=<dir>] [--pt_BR]
##
## Each screen is put up through the router, the way a player gets there, and
## the selection is moved the way a player moves it: by the keys, and once by
## the pointer, so the hover and the keyboard's caret are both on record.

const OUT := "res://implementation/shots/menus/"
const RUN_SEED := 20260927

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
		elif arg == "--pt_BR":
			I18n.use("pt_BR")
	var folder := _out if not _out.begins_with("res://") \
		else ProjectSettings.globalize_path(_out)
	DirAccess.make_dir_recursive_absolute(folder)
	var router: Node = root.get_node(^"App")

	# --- the title menu
	var title: Node = load("res://scenes/Title.tscn").instantiate()
	root.add_child(title)
	await _settle(4)
	router.goto(router.MENU)
	await _settle(4)
	await _shoot(folder, "title_menu")
	await _key(KEY_DOWN)
	await _key(KEY_DOWN)
	await _shoot(folder, "title_menu_keys")
	var entry := title.find_child("Menu_options", true, false) as Control
	if entry != null:
		await _point_at(entry)
		await _shoot(folder, "title_menu_hover")
	root.remove_child(title)
	title.free()

	# --- the pause menu, over a run
	router.reset(router.RUN)
	var main: Node = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await _settle(4)
	main.begin_run(RUN_SEED)
	await _settle(6)
	router.goto(router.PAUSE)
	await _settle(4)
	await _shoot(folder, "pause")
	for which in ["restart", "abandon", "quit"]:
		var asks := main.find_child("Pause_%s" % which, true, false) as Button
		if asks == null:
			continue
		asks.grab_focus()
		asks.pressed.emit()
		await _settle(3)
		await _shoot(folder, "pause_ask_%s" % which)
		await _key(KEY_ESCAPE)
		await _settle(2)

	# --- every page of the options, opened from the pause menu
	router.goto(router.OPTIONS)
	await _settle(4)
	var options := main.find_child("OptionsScreen", true, false)
	if options != null and options.has_method("tab_names"):
		for tab in options.tab_names():
			options.show_tab(StringName(tab))
			await _settle(2)
			# The selection on the page's first row, the way a player who
			# pressed down from the strip sees it.
			var rows: Array = options.page().entries()
			if not rows.is_empty():
				(rows[0] as Control).grab_focus()
			await _settle(3)
			await _shoot(folder, "options_%s" % tab)
	root.remove_child(main)
	main.free()
	print("MENU CAPTURE: %d pictures into %s" % [_written, folder])
	quit(0)


func _settle(frames: int) -> void:
	for _i in frames:
		await process_frame


func _key(keycode: int) -> void:
	for down in [true, false]:
		var ev := InputEventKey.new()
		ev.keycode = keycode
		ev.physical_keycode = keycode
		ev.pressed = down
		Input.parse_input_event(ev)
		await process_frame
	await process_frame


## Move the pointer over a control, as a mouse would.
func _point_at(control: Control) -> void:
	var at := control.get_global_rect().get_center()
	var screen: Vector2 = root.get_final_transform() * at
	var ev := InputEventMouseMotion.new()
	ev.position = screen
	ev.global_position = screen
	Input.parse_input_event(ev)
	await _settle(3)


func _shoot(folder: String, name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null:
		return
	image.convert(Image.FORMAT_RGB8)
	image.save_png(folder.path_join(name + ".png"))
	_written += 1
