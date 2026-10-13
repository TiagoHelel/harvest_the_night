extends SceneTree

## The collections book (task 0287), photographed from the real renderer at
## 1920x1080: every tab with an empty profile and with a full one, opened
## from the title menu through the router the way a player opens it, and the
## book over a run once, for the run's own hint.
##
##     godot --path . --position -4000,-4000 \
##         --script res://src/tools/capture_collections.gd -- [--out=<dir>] [--pt_BR]
##
## **The profiles are made here and handed to the screen**, never written:
## the player's own profile on disk is not this tool's to touch. With
## `--pt_BR` it shoots the full profile alone, in Portuguese.

const OUT := "res://implementation/shots/0287/"
const RUN_SEED := 20260927

var _out := OUT
var _written := 0
var _portuguese := false


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
			_portuguese = true
	var folder := _out if not _out.begins_with("res://") \
		else ProjectSettings.globalize_path(_out)
	DirAccess.make_dir_recursive_absolute(folder)
	var router: Node = root.get_node(^"App")
	var tag := "pt_BR" if _portuguese else "en"

	# --- from the title menu
	var title: Node = load("res://scenes/Title.tscn").instantiate()
	root.add_child(title)
	await _settle(4)
	router.goto(router.MENU)
	await _settle(4)
	await _shoot(folder, "title_menu_%s" % tag)
	router.goto(router.COLLECTIONS)
	await _settle(4)
	var book := title.find_child("CollectionsScreen", true, false) as CollectionsScreen
	var profiles: Array = [["full", full_profile()]]
	if not _portuguese:
		profiles.push_front(["empty", Save.default_profile()])
	for pair in profiles:
		book.show_profile(pair[1])
		for tab in CollectionsScreen.TABS:
			book.show_tab(tab)
			await _settle(3)
			await _shoot(folder, "%s_%s_%s" % [tag, pair[0], tab])
	# A legendary's page, and the strip's marker off the first species.
	book.show_tab(&"fish")
	for _i in Collections.fish_ids().size() - 1:
		book.turn_fish(1)
	await _settle(3)
	await _shoot(folder, "%s_full_fish_last" % tag)
	root.remove_child(title)
	title.free()

	# --- over a run, for the run's hint
	router.reset(router.RUN)
	var main: Node = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await _settle(4)
	main.begin_run(RUN_SEED)
	await _settle(6)
	router.goto(router.COLLECTIONS)
	await _settle(4)
	var in_run := main.find_child("CollectionsScreen", true, false) as CollectionsScreen
	in_run.show_profile(full_profile())
	in_run.show_tab(&"achievements")
	await _settle(3)
	await _shoot(folder, "%s_run_achievements" % tag)
	root.remove_child(main)
	main.free()
	print("COLLECTIONS CAPTURE: %d pictures into %s" % [_written, folder])
	quit(0)


## A profile with every page filled: each species landed, each crop grown,
## each boss down, two years won and every badge.
static func full_profile() -> Dictionary:
	var profile := Save.default_profile()
	var fish := {}
	for id in Collections.fish_ids():
		fish[id] = 3
	var bosses := {}
	for boss in Collections.boss_ids():
		bosses[boss] = 2
	var crops := {}
	for crop in Collections.crop_ids():
		crops[crop] = 40
	var badges := {}
	for id in GameData.ACHIEVEMENTS:
		badges[id] = true
	profile["stats"]["lifetime"] = {"nights": 120, "killed": 2400,
		"killed_by_kind": bosses, "built": 180, "gathered": {}, "lost": 3,
		"fish_book": fish}
	profile["collections"] = {"crops": crops, "years": 2}
	profile["achievements"] = badges
	return profile


func _settle(frames: int) -> void:
	for _i in frames:
		await process_frame


func _shoot(folder: String, name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null:
		return
	image.convert(Image.FORMAT_RGB8)
	image.save_png(folder.path_join(name + ".png"))
	_written += 1
