extends SceneTree

## The other half of the gate: real clicks and real keys, through the real
## scenes, with nobody in the room.
##
## `headless_check` proves the rules are right. This proves you can still reach
## them - that the night button is still wired to the night, that placing a
## tower still places a tower, that a refactor which quietly broke a signal is
## a red line the same minute rather than a bug report in three weeks.
##
## Run by `python tools/verify.py`. The last line it prints is
## `N cases, M failed`, and it exits non-zero when M is not zero.
##
## ## It really is headless
##
## Measured before this file was written: with `--headless` the viewport is the
## project's 480x270, `root.push_input()` reaches Controls and fires their
## signals, and `Input.parse_input_event()` sets `Input.is_key_pressed()`. So
## there is no need for a window, and no need for a separate "test mode" path
## through the UI - which is the point, because a test mode is a thing that can
## be right while the real path is wrong.
##
## ## House style
##
## One `_case_NNNN_*` function per task that added an input path, counted the
## same way `headless_check` counts its groups: a case that dies half way
## cannot report success, because the counter is its last line.

const MAIN_SCENE := "res://scenes/Main.tscn"

## How long the run may go without a single assert landing.
##
## **A stall, not a budget.** This used to be the whole run's time, and
## that is a deadline that every new case eats into: the eleventh one
## tripped it on a suite where nothing was wrong at all. Every `expect()`
## puts it back to zero, so what it now catches is what it was always for -
## a scene that never loads, an `await` that never returns, a case that
## stopped making progress - and it does that just as well whether there
## are eleven cases or two hundred.
const WATCHDOG_SECONDS := 20.0

## How many `_case_NNNN_*` functions `_run()` is expected to finish.
## **Adding a case means bumping this.**
const CASES := 61

## The pixels two pieces of text in one row must have between them. Two is
## the width of the gap inside a letter at this size, so anything less reads
## as one word.
const MIN_INK_GAP := 2.0

var passed := 0
var failed := 0

var _completed := 0
var _finished := false
var _elapsed := 0.0
var _scene: Node = null


func _initialize() -> void:
	# Not awaited: `_run()` needs frames to pass, which only happens once
	# `_initialize()` has returned and the main loop is turning. `_finish()` is
	# called at the end of `_run()`, and the watchdog covers the case where it
	# never gets there.
	_run()


func _process(delta: float) -> bool:
	_elapsed += delta
	if _elapsed < WATCHDOG_SECONDS:
		return false
	push_error("input_check: watchdog fired after %.0fs" % _elapsed)
	print("WATCHDOG: a case never finished - look at the last case named above")
	_finish()
	return true


func _run() -> void:
	if OS.get_cmdline_user_args().has("--house-visit-only"):
		await _case_0111_farm_house()
		print("HOUSE INPUT: %d cases, %d failed" % [passed + failed, failed])
		quit(1 if failed > 0 else 0)
		return
	await _case_0011_harness()
	await _case_0012_debug_overlay()
	await _case_0013_world_view()
	await _case_0015_player()
	await _case_0020_shop()
	await _case_0021_day_hud()
	await _case_0022_reality()
	await _case_0023_build_mode()
	await _case_0027_the_loop()
	await _case_0028_seeds()
	await _case_0029_watering()
	await _case_0030_fishing()
	await _case_0111_farm_house()
	await _case_0032_press()
	await _case_0033_power()
	await _case_0034_livestock()
	await _case_0035_ammo()
	await _case_0036_inventory()
	await _case_0037_queue()
	await _case_0038_away()
	await _case_0039_clock()
	await _case_0040_shop()
	await _case_0041_tutorial()
	await _case_0046_walls()
	await _case_0053_repair()
	await _case_0054_ability()
	await _case_0055_speed()
	await _case_0056_night_hud()
	await _case_0063_tech_tree()
	await _case_0069_stats()
	await _case_0070_endless()
	await _case_0071_palettes()
	await _case_0072_tileset()
	await _case_0073_player_art()
	await _case_0074_zombie_art()
	await _case_0076_lighting()
	await _case_0077_particles()
	await _case_0078_transition()
	await _case_0081_theme()
	await _case_0082_shots()
	await _case_0083_audio()
	await _case_0084_day_sounds()
	await _case_0085_night_sounds()
	await _case_0086_music()
	await _case_0087_ambience()
	await _case_0088_juice()
	await _case_0089_tooltips()
	await _case_0090_log()
	await _case_0091_title()
	await _case_0092_router()
	await _case_0093_video()
	await _case_0094_audio()
	await _case_0095_controls()
	await _case_0096_pause()
	await _case_0097_language()
	await _case_0098_access()
	await _case_0099_ident()
	await _case_0100_version()
	await _case_0103_crash()
	await _case_0104_saves()
	await _case_0105_playtest()
	_finish()


## 0103 - the crash dialogue, and the key it takes off the title screen.
func _case_0103_crash() -> void:
	_forget_any_loaded_scene()
	_empty_the_crash_folder()

	# Something to be told about. Written before the scene opens, because
	# the title reads the folder once, in `_ready`.
	var state := State.create(103104)
	Sim.advance(state, 450)
	var folder := Crash.report(state, "a deliberate crash, from input_check")
	expect(folder != "", "there is a report to announce")

	await open_scene("res://scenes/Title.tscn")
	await frames(4)
	var dialog: CrashDialog = locate_control("CrashDialog") as CrashDialog
	expect(dialog != null, "the title scene has a crash dialogue on it")
	if dialog == null or folder == "":
		await close_scene()
		_empty_the_crash_folder()
		_completed += 1
		return

	expect(dialog.showing(),
		"and it is up, because the last session did not end well")
	expect(dialog.folder() == folder, "showing the report that was written",
		dialog.folder())

	# **It offers somewhere a player can actually go.** `user://` is not a
	# folder anybody can open; the label is the real path.
	var path: Label = locate_control("CrashPath") as Label
	expect(path != null and path.text != "", "it says where the file is")
	expect(path != null and not path.text.begins_with("user://"),
		"in a path that exists on this machine",
		path.text if path != null else "")

	# And the two numbers that make it the same crash as the one in the file.
	var facts: Label = locate_control("CrashFacts") as Label
	expect(facts != null and facts.text.contains(str(int(state["seed"]))),
		"and which run it was", facts.text if facts != null else "")
	expect(facts != null and facts.text.contains(str(int(state["tick"]))),
		"and which tick", facts.text if facts != null else "")

	# **The new input path.** "Press any key" is the title screen's, and
	# while this is up it is not the title screen's turn: a player who
	# pressed a key to read the dialogue would be reading the menu instead.
	var router: Node = root.get_node_or_null(^"App")
	expect(router != null and router.here() == router.TITLE,
		"the title is still the title")
	await tap_key(KEY_Z)
	await frames(3)
	expect(router != null and router.here() == router.TITLE,
		"a key does not get past the dialogue",
		router.name_of(router.here()) if router != null else "no router")
	expect(dialog.showing(), "and the dialogue is still up")

	# Closing it hands the keyboard back.
	await click_control("CrashClose")
	await frames(3)
	expect(not dialog.showing(), "CLOSE puts it away")
	await tap_key(KEY_X)
	await frames(3)
	expect(router != null and router.here() == router.MENU,
		"and the title has its key back",
		router.name_of(router.here()) if router != null else "no router")
	await close_scene()

	# **Told once.** A game that opens on the same crash every launch for
	# the rest of its life teaches a player to close it without reading.
	await open_scene("res://scenes/Title.tscn")
	await frames(4)
	dialog = locate_control("CrashDialog") as CrashDialog
	expect(dialog != null and not dialog.showing(),
		"opening the title again does not announce it again")
	await close_scene()

	# And the report is still on disk, because a dialogue is not a bin.
	expect(Crash.text_of(folder).contains("seed    %d" % int(state["seed"])),
		"the report is still there to send")

	_empty_the_crash_folder()
	_completed += 1


## Drop whatever the router loaded earlier and nobody took away.
##
## **`App.goto()` really changes the scene**, which task 0096 found out the
## hard way: a case that sends the game to the title leaves a title screen
## under the root as `current_scene`, and it stays there for every case after
## it. Usually harmless - two screens that agree about everything. Not here:
## the second title has no crash to announce, so it is the one that takes the
## key this case is checking the dialogue keeps, and the case failed against
## code that was right. Found with a print, after reading the assert twice.
func _forget_any_loaded_scene() -> void:
	if current_scene == null:
		return
	var stale: Node = current_scene
	current_scene = null
	root.remove_child(stale)
	# `free` rather than `queue_free`: a deferred one is still in the tree
	# for the frames this case spends pressing keys at it.
	stale.free()


## Leave `user://crash/` as it was found: empty.
func _empty_the_crash_folder() -> void:
	if not DirAccess.dir_exists_absolute(Crash.DIR):
		return
	for name in DirAccess.get_directories_at(Crash.DIR):
		var inner := Crash.DIR.path_join(String(name))
		Crash.erase(inner)


## 0104 - a save that will not load, on the title screen.
func _case_0104_saves() -> void:
	_forget_any_loaded_scene()

	# **A readable run first**, so the difference is the save and not the
	# screen: CONTINUE is there, and nothing is being complained about.
	var state := State.create(104105)
	Sim.advance(state, 900)
	Save.write_run(state)
	await open_scene("res://scenes/Title.tscn")
	await frames(3)
	var title: TitleScreen = _scene as TitleScreen
	var router: Node = root.get_node_or_null(^"App")
	router.goto(router.MENU)
	await frames(3)
	expect(locate_control("Menu_continue") != null,
		"a run that loads puts CONTINUE on the menu")
	expect(title.trouble_says() == "",
		"and the title has nothing to complain about",
		title.trouble_says())
	await close_scene()

	# **Now the same file, written by a build that does not exist yet.**
	# This is the one that matters: the file is fine, the game is fine, and
	# this build simply cannot read that run.
	_forget_any_loaded_scene()
	state["version"] = State.VERSION + 1
	Save.write_run(state)
	expect(Save.has_run(), "the file is on the disk")
	await open_scene("res://scenes/Title.tscn")
	await frames(3)
	title = _scene as TitleScreen
	router = root.get_node_or_null(^"App")
	router.goto(router.MENU)
	await frames(3)

	expect(locate_control("Menu_continue") == null,
		"a run that does not load takes CONTINUE away")
	expect(locate_control("Menu_new") != null,
		"and NEW GAME is still there, which is the way out")

	var says := title.trouble_says()
	expect(says != "", "the title says why", says)
	expect(says.contains(I18n.t(&"SAVE_UNREADABLE")),
		"that the run could not be read", says)
	expect(says.contains(I18n.t(&"SAVE_FROM_THE_FUTURE")),
		"and which of the reasons it was", says)
	expect(says.contains(I18n.t(&"SAVE_KEPT")),
		"and that the file is still there", says)

	# The frame, not the words: since the picture was looked at, the notice
	# is a `PanelContainer` with a `Label` on it rather than orange text over
	# a farm.
	var panel: Control = locate_control("SaveTrouble") as Control
	expect(panel != null and panel.visible, "and it is on the screen")
	expect(panel == null or panel.get_global_rect().end.y
		<= float(root.get_visible_rect().size.y),
		"rather than off the bottom of it",
		str(panel.get_global_rect()) if panel != null else "")
	var words: Label = locate_control("SaveTroubleText") as Label
	expect(words != null and words.text == says,
		"with the sentence on it and not beside it")

	# **And the file really was kept**, which is the promise underneath the
	# sentence. A player pressing NEW GAME is choosing to lose it; the game
	# has not chosen for them.
	expect(Save.has_run(), "the save this build cannot read is still there")
	await close_scene()

	# The notice goes when the trouble does.
	_forget_any_loaded_scene()
	state["version"] = State.VERSION
	Save.write_run(state)
	await open_scene("res://scenes/Title.tscn")
	await frames(3)
	title = _scene as TitleScreen
	router = root.get_node_or_null(^"App")
	router.goto(router.MENU)
	await frames(3)
	expect(title.trouble_says() == "", "a readable run says nothing",
		title.trouble_says())
	expect(locate_control("Menu_continue") != null, "and CONTINUE is back")
	await close_scene()

	Save.delete_run()
	_completed += 1


## 0105 - the playtest badge and the key that leaves a note.
func _case_0105_playtest() -> void:
	_forget_any_loaded_scene()

	# **Off first.** The badge is in the run scene of every build, including
	# the one people will buy, and in that one it has to be nothing at all.
	Playtest.force(false)
	await open_scene(MAIN_SCENE)
	await frames(4)
	var badge: PlaytestBadge = locate_control("PlaytestBadge") as PlaytestBadge
	expect(badge != null, "the run scene has the badge on it")
	expect(badge == null or not badge.visible,
		"and in a normal build it is not drawn")
	await tap_key(KEY_F1)
	await frames(2)
	expect(not Playtest.running(),
		"and the note key does nothing, because there is no session")
	await close_scene()

	# ---------------------------------------------------------- and on

	Playtest.force(true)
	_forget_any_loaded_scene()
	await open_scene(MAIN_SCENE)
	await frames(6)
	badge = locate_control("PlaytestBadge") as PlaytestBadge
	expect(badge != null and badge.visible,
		"a playtest build says so on the screen")
	if badge == null:
		Playtest.force(false)
		await close_scene()
		_completed += 1
		return

	expect(Playtest.running(),
		"and opening a run opens a session log", Playtest.path())
	expect(badge.says().contains(OS.get_keycode_string(Playtest.NOTE_KEY)),
		"the badge names the key that leaves a note", badge.says())

	# **The key, pressed the way a tester presses it.** Not the function
	# called directly: what is being checked is that the key reaches this
	# node at all, past a run that is also listening for keys.
	var path := Playtest.path()
	await tap_key(KEY_F1)
	await frames(3)
	expect(Playtest.notes() == 1, "pressing it leaves a marker",
		str(Playtest.notes()))
	expect(badge.says().contains("1"),
		"and the badge says so, so the tester knows it took",
		badge.says())

	await tap_key(KEY_F1)
	await frames(3)
	expect(Playtest.notes() == 2, "and again is the second one",
		str(Playtest.notes()))

	var log_text := FileAccess.get_file_as_string(path)
	expect(log_text.contains("NOTE 1") and log_text.contains("NOTE 2"),
		"both are in the file rather than only on the screen")

	# **And then it gets out of the way.** It sits over the day HUD's clock
	# and the night HUD's wave counter, which is only acceptable because it
	# is not there for long - so how long is the thing to check, and a
	# picture cannot show twelve seconds passing.
	badge._process(PlaytestBadge.SHOWN_FOR + 1.0)
	expect(not badge.visible,
		"the badge goes away, so the HUD it sits over comes back")
	expect(Playtest.running(),
		"and the session carries on without it on the screen")
	badge.leave_a_note()
	expect(badge.visible, "a note brings it back to say so")
	badge._process(PlaytestBadge.SAID_FOR + 1.0)
	expect(not badge.visible, "and it goes again")

	# **It does not eat the game's own keys.** A tester who cannot play
	# because the badge swallowed a keystroke is a wasted evening.
	var driver: SimDriver = _scene.get_node("%SimDriver")
	var before := int(driver.state["tick"])
	await tap_key(KEY_B)
	await frames(3)
	expect(int(driver.state["tick"]) > before, "and the run carries on")

	await close_scene()

	# **And the title says so permanently**, which is the half the badge
	# gave up when it started going away. It is the first screen a tester
	# sees and the one they will be looking at when they wonder which build
	# they have.
	_forget_any_loaded_scene()
	await open_scene("res://scenes/Title.tscn")
	await frames(3)
	var version: Label = locate_control("Version") as Label
	expect(version != null and version.text.contains(
		I18n.t(&"PLAYTEST_TITLE")),
		"the title screen says which build this is",
		version.text if version != null else "")
	expect(version != null and version.text.contains(BuildInfo.BUILT),
		"and still says when it was built",
		version.text if version != null else "")
	expect(version == null or version.get_global_rect().end.x
		<= float(root.get_visible_rect().size.x),
		"with both lines on the screen rather than off the right of it",
		str(version.get_global_rect()) if version != null else "")
	await close_scene()

	Playtest.force(false)
	_empty_the_playtest_folder()
	_completed += 1


## Leave `user://playtest/` as it was found.
func _empty_the_playtest_folder() -> void:
	if not DirAccess.dir_exists_absolute(Playtest.DIR):
		return
	var at := DirAccess.open(Playtest.DIR)
	if at == null:
		return
	for name in at.get_files():
		at.remove(name)


func _finish() -> void:
	if _finished:
		return
	_finished = true
	if _completed < CASES:
		failed += 1
		print("  FAIL  a case did not finish   %d of %d completed"
			% [_completed, CASES])
	print("%d cases, %d failed" % [passed + failed, failed])
	quit(1 if failed > 0 else 0)


# ------------------------------------------------------------------- the cases

## 0011 - the harness itself. Until there is a button to press, what is worth
## checking is that the machinery which will press it works and complains.
func _case_0011_harness() -> void:
	await open_scene(MAIN_SCENE)

	# The real scene, with the nodes it says it has.
	expect(_scene != null, "the main scene loads")
	expect(require_control("WorldView") != null, "the farm is on screen")
	expect(require_control("Day") != null, "the day label is there")
	expect(require_control("SimDriver") != null, "the sim driver is there")

	# **Prove it fails loudly**, rather than trusting that it would. A control
	# that is named and missing has to be a red line - a harness that quietly
	# returns null would pass for ever while the button it was meant to press
	# no longer existed.
	#
	# This is the one place in this file that takes a failure back off the
	# tally, and it is doing so on purpose.
	print("  (the FAIL line below is deliberate - it is the harness being ",
		"asked for a control that does not exist, and the failure is taken ",
		"back off the tally on the next line)")
	var before := failed
	require_control("NoSuchControlExists")
	var was_loud := failed == before + 1
	failed = before
	expect(was_loud, "naming a control that does not exist fails the run")
	expect(locate_control("NoSuchControlExists") == null,
		"while locate() is the quiet one, for asking whether something is there")

	# The scene is really being ticked and not merely instantiated. The tick
	# counter rather than the clock label: the label reads in whole seconds, so
	# twenty frames of it say nothing at all.
	var driver: SimDriver = require_control("SimDriver")
	var first := int(driver.state["tick"])
	await frames(20)
	expect(int(driver.state["tick"]) > first, "the scene is live - it is ticking",
		"%d then %d" % [first, driver.state["tick"]])

	# A mouse click reaches a Control and its handler runs.
	var probe := Button.new()
	probe.name = "ClickProbe"
	probe.position = Vector2(200, 120)
	probe.size = Vector2(80, 24)
	var clicks := [0]
	probe.pressed.connect(func() -> void: clicks[0] += 1)
	require_control("Screen").add_child(probe)
	await frames(2)

	await click_control("ClickProbe")
	expect(clicks[0] == 1, "a synthesised click reaches a control and fires it",
		str(clicks[0]))

	await click_at(Vector2(5, 5))
	expect(clicks[0] == 1, "and a click somewhere else does not", str(clicks[0]))

	# A key reaches the input system.
	await tap_key(KEY_F9)
	expect(not Input.is_key_pressed(KEY_F9), "a tapped key is released again")
	await press_key(KEY_F9, true)
	expect(Input.is_key_pressed(KEY_F9), "a held key stays held")
	await press_key(KEY_F9, false)
	expect(not Input.is_key_pressed(KEY_F9), "and lets go")

	# Clicking a farm cell. Now that task 0013 has given the world view a
	# camera, the mapping comes from the view rather than from the naive
	# identity - so what is checked here is that a cell lands somewhere on
	# screen and comes back as itself, not where it happens to be today.
	var view: WorldView = require_control("WorldView")
	var centre := cell_to_screen(SuiteKit.moved(Vector2i(20, 9)))
	expect(centre.x > 0.0 and centre.y > 0.0, "a farm cell is somewhere on screen",
		str(centre))
	expect(view.screen_to_cell(centre) == SuiteKit.moved(Vector2i(20, 9)),
		"and the screen position maps back to the cell it came from",
		str(view.screen_to_cell(centre)))
	await click_cell(SuiteKit.moved(Vector2i(20, 9)))
	expect(true, "clicking a cell does not throw")

	await close_scene()
	expect(_scene == null, "and the scene is torn down for the next case")

	_completed += 1     # last line: an abandoned case never gets here


## 0012 - the overlay: it toggles, it reads, and it changes nothing.
func _case_0012_debug_overlay() -> void:
	await open_scene(MAIN_SCENE)

	var overlay := locate_control("DebugOverlay")
	expect(overlay != null,
		"the debug overlay is present in a debug build - if this fails in a "
		+ "release build that is correct, it frees itself")
	if overlay == null:
		_completed += 1
		await close_scene()
		return

	expect(not overlay.visible, "it is off by default - a player never sees it")

	var driver: SimDriver = require_control("SimDriver")
	await frames(10)

	# **Toggling it cannot move the game.** The overlay reads the state and
	# never writes to it, so this is true by construction - and checked anyway,
	# because "by construction" is how view layers start writing to state.
	var before := State.hash_of(driver.state)
	var tick_before := int(driver.state["tick"])
	driver.running = false                  # freeze, so the tick is not the
	await frames(2)                         # thing that moved the hash

	await tap_key(KEY_F3)
	expect(overlay.visible, "F3 turns it on")
	await frames(5)
	await tap_key(KEY_F3)
	expect(not overlay.visible, "and F3 turns it off again")

	expect(State.hash_of(driver.state) == before,
		"toggling it did not move the determinism hash",
		"%d vs %d" % [State.hash_of(driver.state), before])
	expect(int(driver.state["tick"]) == tick_before,
		"nor advance the simulation")
	driver.running = true

	# It says the true things about the game it is watching.
	await tap_key(KEY_F3)
	await frames(12)
	var label: Label = overlay.find_child("Readout", true, false)
	expect(label != null and not label.text.is_empty(), "it has something to say")
	if label != null:
		expect(label.text.contains("DAY"), "it names the phase", label.text)
		expect(label.text.contains("seed"), "and the seed")
		expect(label.text.contains("us/tick"), "and what a tick costs")
		expect(label.text.contains("tree"), "and what is standing on the farm")

	# The cost is measured, not printed as a decorative zero. The other half of
	# this task's done-when - that it climbs with a hundred zombies on the farm
	# - has to wait for task 0025 to give us a hundred zombies.
	expect(driver.peak_usec > 0, "the tick cost is a real measurement",
		"%d us peak over %d ticks" % [driver.peak_usec, driver.last_ticks])

	# **It never steals the mouse.** A probe under where the overlay draws must
	# still receive the click.
	var probe := Button.new()
	probe.name = "UnderOverlay"
	probe.position = Vector2(8, 8)          # the overlay sits at 4,4
	probe.size = Vector2(60, 20)
	var clicks := [0]
	probe.pressed.connect(func() -> void: clicks[0] += 1)
	require_control("Screen").add_child(probe)
	await frames(2)
	await click_at(Vector2(20, 14))
	expect(clicks[0] == 1,
		"a click lands on what is underneath the overlay, not on the overlay",
		str(clicks[0]))

	await tap_key(KEY_F3)
	await close_scene()

	_completed += 1     # last line: an abandoned case never gets here


## 0013 - the view: it draws the farm, it tracks the camera, it changes nothing.
func _case_0013_world_view() -> void:
	await open_scene(MAIN_SCENE)

	var view: WorldView = require_control("WorldView")
	var driver: SimDriver = require_control("SimDriver")
	expect(view != null and driver != null, "the screen has both halves")
	if view == null or driver == null:
		_completed += 1
		await close_scene()
		return

	# The generated art is what is on screen, not the fallback blocks. A
	# forgotten `python tools/gen_sprites.py` would otherwise look like a
	# slightly duller farm rather than like a missing build step.
	var terrain := view.find_child("Terrain", true, false)
	expect(terrain != null and terrain.tile_set != null, "the tileset is built")
	if terrain != null and terrain.tile_set != null:
		var src: TileSetAtlasSource = terrain.tile_set.get_source(0)
		expect(src != null and src.texture != null
			and src.texture.resource_path == WorldView.TERRAIN_ATLAS,
			"and it is the generated atlas, not the emergency flat one",
			src.texture.resource_path if src != null and src.texture != null
			else "nothing")

	# Everything on the farm got drawn, and nothing was drawn twice.
	var occupants: Dictionary = driver.state["occupants"]
	var drawn := view.find_child("Occupants", true, false)
	# Only the sprites: the layer also holds the highlight and the player, who
	# live here so that walking behind a tree puts them behind the tree.
	expect(drawn != null and _sprites_in(drawn) == occupants.size(),
		"each logical occupant is covered once, including grouped buildings",
		"%d drawn, %d on the farm"
		% [_sprites_in(drawn) if drawn else -1, occupants.size()])

	# **Moving the camera cannot move the game.** The view reads the state and
	# never writes to it; this is the assert that keeps it that way.
	driver.running = false
	await frames(2)
	var before := State.hash_of(driver.state)
	view.look_at_cell(Vector2i(0, 9))
	await frames(3)
	view.look_at_cell(Vector2i(39, 9))
	await frames(3)
	expect(State.hash_of(driver.state) == before,
		"panning the camera did not move the determinism hash")
	driver.running = true
	view.look_at_cell(Player.cell(driver.state))

	# **A click on a cell goes where the camera put it.** This is why
	# cell_to_screen exists at all: without it every click case would be wrong
	# the moment the camera moved - and since task 0015 the camera follows the
	# player, so it moves constantly.
	var cam_probe: Camera2D = view.find_child("Camera", true, false)
	var before_walk := cam_probe.position.x
	var at_cell_before := view.cell_to_screen(SuiteKit.moved(Vector2i(20, 9)))
	await hold_key(KEY_D, 60)
	expect(cam_probe.position.x > before_walk,
		"the camera follows the player east",
		"%.0f then %.0f" % [before_walk, cam_probe.position.x])
	expect(view.cell_to_screen(SuiteKit.moved(Vector2i(20, 9))).x != at_cell_before.x,
		"so a fixed cell is somewhere else on screen afterwards")

	# **No zoom, as in Stardew Valley.** The keys and the wheel that used to
	# zoom do nothing to the camera: a tile is always 64 pixels at 1920x1080.
	await tap_key(KEY_EQUAL)
	await click_at(Vector2(240, 125), MOUSE_BUTTON_WHEEL_UP)
	await click_at(Vector2(240, 125), MOUSE_BUTTON_WHEEL_DOWN)
	await tap_key(KEY_MINUS)
	await frames(10)
	expect(cam_probe.zoom == Vector2.ONE, "Neither keys nor the wheel zoom the camera",
		str(cam_probe.zoom))

	# Screen and cell are each other's inverse, wherever the camera is.
	for cell in [SuiteKit.moved(Vector2i(20, 9)), SuiteKit.moved(Vector2i(25, 4)), SuiteKit.moved(Vector2i(30, 12))]:
		expect(view.screen_to_cell(view.cell_to_screen(cell)) == cell,
			"cell %s survives a round trip through the screen" % cell,
			str(view.screen_to_cell(view.cell_to_screen(cell))))
	expect(view.screen_to_cell(Vector2(-500, -500)) == Vector2i(-1, -1),
		"and a position off the farm is not a cell")

	# **The camera is clamped**, so panning past either end shows the farm
	# rather than a gap. Godot does the clamping; this checks it was asked to.
	var cam: Camera2D = view.find_child("Camera", true, false)
	expect(cam != null and cam.limit_right == WorldView.WORLD_SIZE.x,
		"the camera is fenced in at the farm's edge")
	view.look_at_cell(Vector2i(-50, 9))
	await frames(1)
	expect(cam.position.x >= 240.0,
		"the camera cannot be pushed past the farm left edge",
		str(cam.position.x))
	view.look_at_cell(Vector2i(500, 9))
	await frames(1)
	expect(cam.position.x <= float(WorldView.WORLD_SIZE.x) - 240.0,
		"nor past its right edge", str(cam.position.x))

	# The occupant layer follows the farm when the farm changes, without
	# anybody having to say so.
	var count_before := drawn.get_child_count()
	var free := _any_buildable(driver.state)
	Farm.place(driver.state, free, {"id": &"gun_tower"})
	await frames(4)
	expect(drawn.get_child_count() == count_before + 1,
		"placing something redraws the layer",
		"%d then %d" % [count_before, drawn.get_child_count()])
	Farm.remove(driver.state, free)
	await frames(4)
	expect(drawn.get_child_count() == count_before,
		"and taking it away redraws it again")

	await close_scene()
	_completed += 1     # last line: an abandoned case never gets here


## 0015 - the player: they walk, the pond stops them, and interact does the
## thing in front of them.
func _case_0015_player() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	var view: WorldView = require_control("WorldView")
	if driver == null or view == null:
		_completed += 1
		await close_scene()
		return

	var start := Player.cell(driver.state)
	expect(Farm.walkable(driver.state, start),
		"the player starts somewhere legal", str(start))

	# Walking, and the facing that comes with it.
	await hold_key(KEY_S, 20)
	expect(Player.facing(driver.state) == Player.SOUTH,
		"walking down faces down")
	expect(Player.cell(driver.state).y >= start.y, "and moves down",
		"%s to %s" % [start, Player.cell(driver.state)])

	await hold_key(KEY_A, 30)
	expect(Player.facing(driver.state) == Player.WEST,
		"walking left faces left")

	# **The pond stops you rather than swallowing you.** Walk south-west for
	# long enough to reach the water and check where the player ended up.
	for _i in 8:
		await hold_key(KEY_S, 30)
		await hold_key(KEY_A, 30)
	var landed := Player.cell(driver.state)
	expect(Farm.walkable(driver.state, landed),
		"after walking into the pond the player is on dry land", str(landed))
	expect(Farm.terrain_at(driver.state, landed) != Farm.Terrain.WATER,
		"and specifically not in the water",
		str(Farm.terrain_at(driver.state, landed)))

	# **The same inputs from the same seed end on the same cell.** The property
	# the whole tick design exists for.
	var replay_a := _replay_walk(int(driver.state["seed"]))
	var replay_b := _replay_walk(int(driver.state["seed"]))
	expect(replay_a == replay_b, "the same key sequence ends at the same cell",
		"%s vs %s" % [replay_a, replay_b])

	# Interact starts whatever the faced cell offers.
	var state := driver.state
	var tree_cells := Farm.cells_with(state, &"tree")
	expect(not tree_cells.is_empty(), "there are trees to chop")

	# Put the player beside a tree directly: walking to a named tree is the
	# autoplayer's job at task 0067, not this case's.
	var tree := Vector2i(-1, -1)
	var beside := Vector2i(-1, -1)
	for candidate in tree_cells:
		var spot := _walkable_neighbour(state, candidate)
		if spot != Vector2i(-1, -1):
			tree = candidate
			beside = spot
			break
	expect(beside != Vector2i(-1, -1), "and one can be stood next to",
		str(tree))
	if beside != Vector2i(-1, -1):
		driver.running = false
		await frames(2)
		var who: Dictionary = state["player"]
		who["pos"] = [beside.x * Player.SUBTILE + Player.SUBTILE / 2,
			beside.y * Player.SUBTILE + Player.SUBTILE / 2]
		who["facing"] = _facing_from(beside, tree)
		driver.running = true
		await frames(3)

		expect(Player.target(state) == tree, "the target is the tree faced",
			"%s facing %d gives %s"
			% [beside, Player.facing(state), Player.target(state)])
		expect(Interact.verb_at(state, tree) == &"chop",
			"which offers chopping")

		await hold_key(KEY_SPACE, 4)
		await frames(3)
		expect(Player.is_busy(state), "pressing interact starts the work")
		var action: Dictionary = who["action"]
		expect(action.get("verb", &"") == &"chop", "and the work is chopping",
			str(action))

		# **Walking away gives it up**, rather than leaving half a tree chopped
		# in an invisible ledger.
		await hold_key(KEY_W, 6)
		expect(not Player.is_busy(state), "walking away stops the work")

	await close_scene()
	_completed += 1     # last line: an abandoned case never gets here


## Drive the same keys into a fresh game twice and see where the player lands.
func _replay_walk(seed_value: int) -> Vector2i:
	var state := State.create(seed_value)
	var script: Array = [
		[Vector2i(1, 0), 25], [Vector2i(0, 1), 40], [Vector2i(-1, -1), 30],
		[Vector2i(0, -1), 15], [Vector2i(1, 1), 50],
	]
	for step in script:
		var direction: Vector2i = step[0]
		for _i in int(step[1]):
			var move: Array = (state["intent"] as Dictionary)["move"]
			move[0] = direction.x
			move[1] = direction.y
			Sim.tick(state)
	return Player.cell(state)


func _walkable_neighbour(state: Dictionary, cell: Vector2i) -> Vector2i:
	for step in Grid.STEPS:
		var n: Vector2i = cell + step
		if Grid.in_bounds(n) and Farm.walkable(state, n):
			return n
	return Vector2i(-1, -1)


func _facing_from(from_cell: Vector2i, to_cell: Vector2i) -> int:
	var d: Vector2i = to_cell - from_cell
	if d.y > 0:
		return Player.SOUTH
	if d.y < 0:
		return Player.NORTH
	if d.x < 0:
		return Player.WEST
	return Player.EAST


## Somewhere nothing is standing and something could be. Found rather than
## written down, so that a map gaining a building does not fail a test about
## something else.
## The buildable cell nearest the farmer, so it is on screen: the camera
## follows them, and the farm is four screens tall.
func _any_buildable(state: Dictionary) -> Vector2i:
	var found := _nearest(state, func(cell: Vector2i) -> bool:
		return Farm.buildable(state, cell))
	return found


## The water nearest the farmer, for the same reason.
func _nearest_water(state: Dictionary) -> Vector2i:
	return _nearest(state, func(cell: Vector2i) -> bool:
		return Farm.terrain_at(state, cell) == Farm.Terrain.WATER)


## Rings outward from the farmer's cell, each in a fixed order.
func _nearest(state: Dictionary, wanted: Callable) -> Vector2i:
	var here := Player.cell(state)
	for radius in maxi(Grid.WIDTH, Grid.HEIGHT):
		for cell in Grid.within(here, radius):
			if Grid.chebyshev(here, cell) == radius and wanted.call(cell):
				return cell
	return Vector2i(-1, -1)


## Occupant sprites only. The layer also holds the player and, since task
## 0023, the build ghost - which is a Sprite2D and is nobody's occupant.
func _sprites_in(node: Node) -> int:
	var cells := {}
	for child in node.get_children():
		if child is Sprite2D and child.has_meta("logical_cells"):
			for idx in child.get_meta("logical_cells"):
				if cells.has(idx):
					return -1
				cells[idx] = true
	return cells.size()


## 0020 - the stall, through the real panel: open it, sell something, leave.
func _case_0020_shop() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	var panel: ShopPanel = require_control("ShopPanel")
	if driver == null or panel == null:
		_completed += 1
		await close_scene()
		return

	var state := driver.state
	expect(not panel.visible, "the panel starts closed")

	# Stand at the stall and press interact, the way a player would.
	var stall: Vector2i = Farm.cells_with(state, &"shop")[0]
	var beside := _walkable_neighbour(state, stall)
	expect(beside != Vector2i(-1, -1), "the stall can be stood next to")
	if beside == Vector2i(-1, -1):
		_completed += 1
		await close_scene()
		return

	driver.running = false
	await frames(2)
	var who: Dictionary = state["player"]
	who["pos"] = [beside.x * Player.SUBTILE + Player.SUBTILE / 2,
		beside.y * Player.SUBTILE + Player.SUBTILE / 2]
	who["facing"] = _facing_from(beside, stall)
	Resources.add(state, GameData.WOOD, 12)
	driver.running = true
	await frames(3)

	expect(Player.target(state) == stall, "the stall is the target",
		str(Player.target(state)))
	await hold_key(KEY_SPACE, 4)
	await until(func() -> bool: return panel.visible, "the shop to open")
	expect(panel.visible, "pressing interact opens the panel")

	# Sell, by clicking the button a player would click.
	var wood_before := Resources.amount(state, GameData.WOOD)
	var money_before := Resources.amount(state, GameData.MONEY)
	var sell_button: Control = require_control("sell_one_wood")
	if sell_button != null:
		var box := sell_button.get_global_rect()
		var at := box.position + box.size * 0.5
		print("  0020 clicking sell_one_wood at %s (rect %s); panel %s; top %s"
			% [at, box, str((require_control("ShopPanel") as Control)
				.get_global_rect()),
				str(sell_button.get_viewport().gui_get_hovered_control())])
	await click_control("sell_one_wood")
	await frames(4)
	expect(Resources.amount(state, GameData.WOOD) == wood_before - 1,
		"clicking sell sells one", str(Resources.amount(state, GameData.WOOD)))
	expect(Resources.amount(state, GameData.MONEY)
		== money_before + Shop.sell_price(GameData.WOOD),
		"and pays for it", str(Resources.amount(state, GameData.MONEY)))

	await click_control("sell_all_wood")
	await frames(4)
	expect(Resources.amount(state, GameData.WOOD) == 0,
		"and sell-all empties the bag",
		str(Resources.amount(state, GameData.WOOD)))

	# A row with nothing behind it is shown and refuses to be pressed.
	var button := locate_control("sell_one_wood")
	expect(button != null and button.disabled,
		"a row with none left is greyed rather than gone")

	# Leaving.
	await hold_key(KEY_ESCAPE, 4)
	await until(func() -> bool: return not panel.visible, "the shop to close")
	expect(not panel.visible, "escape closes it")
	# **And it stays closed.** The trade action used to repeat, so the panel
	# reopened on the tick after it was shut.
	await frames(30)
	expect(not panel.visible, "and stays closed a second later")
	expect(not Shop.is_open(state), "and the game agrees it is closed")

	await close_scene()
	_completed += 1     # last line: an abandoned case never gets here


## 0021 - the HUD: it tells the truth the same tick, and the button works by
## mouse and by key.
func _case_0021_day_hud() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	var hud: DayHud = require_control("DayHud")
	if driver == null or hud == null:
		_completed += 1
		await close_scene()
		return

	var state := driver.state
	expect(hud.visible, "the day HUD is up during the day")

	var day_label: Label = require_control("Day")
	var money_label: Label = require_control("Money")
	var wood_label: Label = require_control("res_wood")
	# The label carries the clock as well as the day now, so this asks what it
	# is for rather than what it happened to read the day it was written.
	expect(day_label != null and day_label.text.begins_with("DAY 1"),
		"it says which day", day_label.text if day_label else "")
	expect(day_label != null and day_label.text.contains(":"),
		"and what time it is", day_label.text if day_label else "")
	expect(money_label != null and money_label.text.contains("25"),
		"and what is in the purse",
		money_label.text if money_label else "")

	# **The same tick.** Not next frame, not after a refresh timer.
	var before := wood_label.text
	Resources.add(state, GameData.WOOD, 7)
	await frames(2)
	expect(wood_label.text != before, "gathering wood updates the HUD at once",
		"%s then %s" % [before, wood_label.text])
	expect(wood_label.text.contains("19"), "with the right number",
		wood_label.text)

	# A changed number lights up and settles back, so a gain is visible from
	# the corner of the eye.
	var lit := wood_label.modulate
	await frames(60)
	expect(wood_label.modulate != lit, "and the flash fades back",
		"%s then %s" % [lit, wood_label.modulate])

	# **The button is reachable by keyboard.**
	var button: Button = require_control("NightButton")
	expect(button != null and button.focus_mode != Control.FOCUS_NONE,
		"the night button can take focus")

	# Pressing it asks for the night, and the rules give it.
	expect(int(state["phase"]) == Phases.DAY, "still day")
	await click_control("NightButton")
	await until(func() -> bool:
		return int(state["phase"]) == Phases.PREPARATION,
		"the night button to take effect")
	expect(int(state["phase"]) == Phases.PREPARATION,
		"clicking it starts the night", Phases.name_of(int(state["phase"])))
	await until(func() -> bool: return not hud.shows_day(),
		"the day HUD to go")
	expect(not hud.shows_day(), "and the day HUD goes away with the day")

	# The key does the same thing from a fresh day.
	await open_scene(MAIN_SCENE)
	driver = require_control("SimDriver")
	expect(int(driver.state["phase"]) == Phases.DAY, "a fresh day")
	await hold_key(KEY_N, 4)
	var keyed := driver.state
	await until(func() -> bool:
		return int(keyed["phase"]) == Phases.PREPARATION, "N to take effect")
	expect(int(driver.state["phase"]) == Phases.PREPARATION,
		"and N does what the button does",
		Phases.name_of(int(driver.state["phase"])))

	await close_scene()
	_completed += 1     # last line: an abandoned case never gets here


## 0022 - the light changes and the farm does not.
func _case_0022_reality() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	var view: WorldView = require_control("WorldView")
	if driver == null or view == null:
		_completed += 1
		await close_scene()
		return

	var light: CanvasModulate = view.find_child("Light", true, false)
	expect(light != null, "the world has a light")
	if light == null:
		_completed += 1
		await close_scene()
		return

	await frames(30)
	# **The daylight moves across the day** since task 0039, so this cannot
	# ask for `DAY_TINT` on the nose any more - at dawn it is the cool colour
	# and at dusk the warm one, with noon in between. What matters is that it
	# is a *daylight*: somewhere on the dawn-noon-dusk line and nowhere near
	# the night.
	expect(_is_daylight(light.color),
		"and by day it is one of the day's", str(light.color))
	expect(not light.color.is_equal_approx(PaletteData.NIGHT_TINT),
		"and nothing like the night's", str(light.color))

	var state := driver.state
	var day_colour := light.color

	# Press the night button the way a player would.
	await click_control("NightButton")
	await until(func() -> bool: return int(state["phase"]) != Phases.DAY,
		"the night to begin")
	expect(int(state["phase"]) != Phases.DAY, "the night has begun")
	expect(view.light_target().is_equal_approx(PaletteData.NIGHT_TINT),
		"and the light is heading for the night", str(view.light_target()))

	# **The simulation never waits for it.** The tick keeps running while the
	# light is on its way.
	var tick_mid := int(state["tick"])
	await frames(10)
	expect(int(state["tick"]) >= tick_mid,
		"the game runs while the light is changing")
	expect(light.color != day_colour, "and the light has left the day behind",
		str(light.color))

	# **Skipping lands where watching would have.** How far a fade has got
	# after N frames depends on how busy the machine is, so nothing here asks
	# that - it asks where the fade ends, which is a fact.
	view.skip_transition()
	await frames(2)
	expect(light.color.is_equal_approx(PaletteData.NIGHT_TINT),
		"skipping lands it on the night", str(light.color))
	expect(not view.is_transitioning(), "and stops")

	# **Skipping lands in the same place watching would have.**
	await open_scene(MAIN_SCENE)
	driver = require_control("SimDriver")
	view = require_control("WorldView")
	light = view.find_child("Light", true, false)
	await frames(20)
	var fresh_day := light.color
	var fresh_state := driver.state
	await click_control("NightButton")
	await until(func() -> bool: return light.color != fresh_day,
		"the light to start moving")
	expect(light.color != fresh_day, "a fresh fade has started moving",
		str(light.color))
	view.skip_transition()
	await frames(2)
	expect(not view.is_transitioning(), "skipping ends it")
	expect(light.color.is_equal_approx(PaletteData.NIGHT_TINT),
		"at the colour it was heading for", str(light.color))

	await close_scene()
	_completed += 1     # last line: an abandoned case never gets here


## 0023 - build mode through the screen: the ghost, a click, a right click.
func _case_0023_build_mode() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	var view: WorldView = require_control("WorldView")
	var build: BuildMode = require_control("BuildMode")
	if driver == null or view == null or build == null:
		_completed += 1
		await close_scene()
		return

	var state := driver.state
	Resources.gain(state, {GameData.WOOD: 100, GameData.STONE: 100,
		GameData.IRON: 100})
	expect(not build.visible, "build mode starts off")

	await hold_key(KEY_B, 4)
	await until(func() -> bool: return build.visible, "build mode to open")
	expect(build.visible, "B opens it")
	expect(Building.selected(state) != &"", "with something selected",
		str(Building.selected(state)))

	# The palette lists everything the phase allows.
	for id in Building.catalogue(state):
		expect(locate_control("build_%s" % id) != null,
			"the palette offers %s" % id)

	await click_control("build_wall")
	await frames(3)
	expect(Building.selected(state) == &"wall", "clicking a row selects it",
		str(Building.selected(state)))

	# **The ghost.** Point at grass and it is green; point at the pond and it
	# is red with a reason.
	var ghost: Sprite2D = view.find_child("Ghost", true, false)
	expect(ghost != null, "there is a ghost")

	var grass := _any_buildable(state)
	await _point_at(view, grass)
	expect(ghost.visible, "it shows over the farm")
	var reason: Label = require_control("BuildReason")
	expect(reason != null and reason.text.is_empty(),
		"and says nothing is wrong", reason.text if reason else "")
	expect(view.ghost_cell() == grass, "on the cell under the cursor",
		str(view.ghost_cell()))
	expect(view.ghost_is_ok(), "framed green, because it fits")

	var pond := _nearest_water(state)
	await _point_at(view, pond)
	# **The table's words, not a sentence written here.** Task 0110: the
	# rules hand back a key and `Names.refusal()` says it, so what this
	# checks is the whole road - rule, key, table, label - rather than one
	# spelling of one message.
	expect(reason.text == I18n.t(&"WHY_IN_THE_WATER"),
		"over the pond it says why not", reason.text)
	expect(not view.ghost_is_ok(), "and framed red, because it does not fit")

	# Over something already built, it refuses for a different reason.
	var taken: Vector2i = Farm.cells_with(state, &"house")[0]
	await _point_at(view, taken)
	expect(not view.ghost_is_ok(), "over the house it refuses too")
	expect(reason.text == I18n.t(&"WHY_ON_THE_HOUSE"),
		"naming the house", reason.text)

	# **And it reads in Portuguese**, which is the done-when of task 0110 and
	# the one thing a checker of widths cannot answer: the string table can
	# be complete and the refusal still arrive in English, if anything on the
	# road between the rule and the label is a sentence somebody wrote in
	# GDScript.
	var was := I18n.locale()
	I18n.use("pt_BR")
	I18n.relabel(_scene)
	await _point_at(view, pond)
	await frames(2)
	expect(reason.text == I18n.t(&"WHY_IN_THE_WATER"),
		"the refusal is in Portuguese when Portuguese is up", reason.text)
	expect(reason.text != "in the water",
		"and is not the English one with a flag on it", reason.text)
	I18n.use(was)
	I18n.relabel(_scene)
	await _point_at(view, taken)
	await frames(2)

	# **A click places it.** Through the same intent the rules read.
	await _point_at(view, grass)
	var stone_before := Resources.amount(state, GameData.STONE)
	await click_at(view.cell_to_screen(grass))
	await until(func() -> bool:
		return not Farm.occupant(state, grass).is_empty(), "the wall to go up")
	expect(Farm.occupant(state, grass).get("id", &"") == &"wall",
		"a wall is built where the cursor was",
		str(Farm.occupant(state, grass)))
	expect(Resources.amount(state, GameData.STONE) < stone_before,
		"and it was paid for")

	# **A right click sells it back.**
	var stone_after_build := Resources.amount(state, GameData.STONE)
	await _point_at(view, grass)
	await click_at(view.cell_to_screen(grass), MOUSE_BUTTON_RIGHT)
	await until(func() -> bool: return Farm.occupant(state, grass).is_empty(),
		"the wall to come back up")
	expect(Farm.occupant(state, grass).is_empty(), "right click takes it back up")
	expect(Resources.amount(state, GameData.STONE) > stone_after_build,
		"and some of the stone comes back")
	expect(Resources.amount(state, GameData.STONE) < stone_before,
		"but not all of it")

	await hold_key(KEY_B, 4)
	await until(func() -> bool: return not build.visible, "build mode to close")
	expect(not build.visible, "and B closes it")
	expect(not ghost.visible, "taking the ghost with it")

	await close_scene()
	_completed += 1     # last line: an abandoned case never gets here


## Put the mouse over a cell and let the build panel notice.
func _point_at(view: WorldView, cell: Vector2i) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = view.cell_to_screen(cell)
	motion.global_position = motion.position
	Input.warp_mouse(motion.position)
	root.push_input(motion)
	await frames(3)


## 0027 - the loop, through the screen: press night, watch it, take the money,
## come back to the farm.
func _case_0027_the_loop() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	var result: ResultScreen = require_control("ResultScreen")
	var hud: DayHud = require_control("DayHud")
	if driver == null or result == null:
		_completed += 1
		await close_scene()
		return

	var state := driver.state
	expect(not result.visible, "the payout is not up during the day")

	# Arm the farm the way a player who spent their day would, then press the
	# button a player would press.
	Resources.gain(state, {GameData.WOOD: 200, GameData.IRON: 200})
	var placed := 0
	for x in range(22, 34):
		for y in [7, 9, 11, 5]:
			var cell := SuiteKit.moved(Vector2i(x, y))
			if placed < 4 and Farm.buildable(state, cell):
				if Building.place(state, &"gun_tower", cell):
					placed += 1
	expect(placed == 4, "four towers go up", str(placed))

	await click_control("NightButton")
	await until(func() -> bool: return int(state["phase"]) != Phases.DAY,
		"the night to begin")

	# **The build step runs in real time at any speed** - it is the stretch
	# the player is promised no hurry in - so its twenty seconds are run off
	# here rather than waited for.
	if int(state["phase"]) == Phases.PREPARATION:
		Sim.advance(state, maxi(GameData.PREPARATION_TICKS
			- int(state["phase_tick"]), 0))
	expect(int(state["phase"]) == Phases.NIGHT, "the build step gives way to the night",
		Phases.name_of(int(state["phase"])))

	# Let the night play out. Faster than real time, because a night is a
	# minute and a test is not.
	driver.speed = 8
	await until(func() -> bool: return int(state["phase"]) == Phases.RESULT,
		"the night to finish", 4000)
	driver.speed = 1
	expect(int(state["phase"]) == Phases.RESULT, "the night ends by itself",
		Phases.name_of(int(state["phase"])))

	await until(func() -> bool: return result.visible, "the payout to come up")
	expect(result.visible, "and the payout comes up")
	expect(not hud.shows_day(), "with the day HUD out of the way")

	var title: Label = require_control("ResultTitle")
	expect(title != null and title.text.contains("NIGHT 1"),
		"it says which night", title.text if title else "")
	expect(title != null and title.text.contains("SURVIVED"),
		"and how it went", title.text if title else "")

	# **Taking the money is a click.**
	var money_before := Resources.amount(state, GameData.MONEY)
	expect(money_before > 25, "the payout already landed",
		str(money_before))
	# **The one way out of this screen has to be on it.** The payout has
	# grown a row at tasks 0061 and 0062 and both times pushed this button
	# off the bottom of a 270-pixel screen, which ends the run - a `Label`
	# reserves its font's line height whatever it is told, so every row is
	# twenty-two pixels.
	var out: Control = locate_control("ContinueButton") as Control
	var frame: Control = locate_control("ResultFrame") as Control
	expect(out != null and frame != null, "the result screen has a way out")
	if out != null:
		var box := out.get_global_rect()
		expect(box.end.y <= 270.0 and box.position.y >= 0.0,
			"and it is on the screen", str(box))
		expect(frame.get_global_rect().end.y <= 270.0,
			"with the whole payout above it",
			str(frame.get_global_rect()))
	await click_control("ContinueButton")
	await until(func() -> bool: return int(state["phase"]) == Phases.DAY,
		"the farm to come back")
	expect(int(state["phase"]) == Phases.DAY, "and it goes back to the farm")
	expect(int(state["day"]) == 2, "on day two", str(state["day"]))
	await until(func() -> bool: return hud.shows_day(),
		"the day HUD to return")
	expect(hud.shows_day(), "with the HUD back")
	expect(not result.visible, "and the payout gone")

	# **Day two is a better day than day one.** The whole point of the loop.
	expect(Resources.amount(state, GameData.MONEY) > 25,
		"there is more money than the farm started with",
		str(Resources.amount(state, GameData.MONEY)))
	expect(Interact.verb_at(state, Farm.cells_with(state, &"tree")[0]) == &"chop",
		"and there are trees to chop again")

	await close_scene()
	_completed += 1     # last line: an abandoned case never gets here


# ----------------------------------------------------------------- the helpers

## Put a scene up and let it settle. Every case starts with one, so no case can
## inherit the mess left by the one before it.
func open_scene(path: String) -> void:
	await close_scene()
	var packed: PackedScene = load(path)
	if packed == null:
		_fail("could not load %s" % path)
		return
	_scene = packed.instantiate()
	root.add_child(_scene)
	await frames(3)


func close_scene() -> void:
	if _scene == null:
		return
	_scene.queue_free()
	_scene = null
	await frames(2)


func frames(n: int) -> void:
	for _i in maxi(n, 1):
		await process_frame


## Wait until something is true, or give up and say so.
##
## **Frame counts are not time.** A tick is owed every thirtieth of a second and
## a headless frame can be a thousandth, so "wait four frames for the phase to
## change" is a bet on how busy the machine is - which is exactly the bet that
## made this file fail one run in four under load and pass on its own. Waiting
## for the condition is both faster when things are quick and correct when they
## are not.
func until(condition: Callable, what: String, max_frames: int = 600) -> bool:
	for _i in max_frames:
		if condition.call():
			return true
		await process_frame
	_fail("timed out waiting for %s" % what)
	return false

## The colour a label is actually drawn in.
##
## **Not `modulate`.** Task 0081 moved every UI colour into the theme: a label
## now says what it *is* - `theme_type_variation` - and the theme says what
## that looks like, so `modulate` is white on almost everything and reading it
## answers a question nobody is asking. This multiplies the two, which is what
## reaches the screen, and it is what these cases meant all along.
func ink(control: Control) -> Color:
	return control.get_theme_color(&"font_color") * control.modulate


## Find a control by node name, anywhere under the scene. **Loud**: a name that
## is not there is a failed case, because that is almost always a signal that
## something was renamed and a screen quietly stopped working.
func require_control(control_name: String) -> Node:
	var node := locate_control(control_name)
	if node == null:
		_fail("no node named '%s' in %s" % [control_name, MAIN_SCENE])
	return node


## The quiet version, for asking whether something is there at all.
func locate_control(control_name: String) -> Node:
	if _scene == null:
		return null
	if _scene.name == control_name:
		return _scene
	return _scene.find_child(control_name, true, false)


## Click the middle of a named control.
func click_control(control_name: String) -> void:
	var node := require_control(control_name)
	if node == null or not (node is Control):
		return
	var ctl: Control = node
	await click_at(ctl.global_position + ctl.size * 0.5)


## Press and release the left button at a screen position.
func click_at(position: Vector2, button: int = MOUSE_BUTTON_LEFT) -> void:
	for pressed in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = button
		ev.pressed = pressed
		ev.position = position
		ev.global_position = position
		root.push_input(ev)
		await process_frame
	await process_frame


## Click a cell of the farm.
func click_cell(cell: Vector2i, button: int = MOUSE_BUTTON_LEFT) -> void:
	await click_at(cell_to_screen(cell), button)


## Where a farm cell is on screen.
##
## Asks the world view when there is one, so that the camera of task 0013 is
## accounted for automatically. Until then the viewport is the farm's own
## resolution and the mapping is the obvious one.
func cell_to_screen(cell: Vector2i) -> Vector2:
	var view := locate_control("WorldView")
	if view != null and view.has_method("cell_to_screen"):
		return view.call("cell_to_screen", cell)
	var size := float(GameData.TILE_SIZE)
	return Vector2(cell.x * size + size * 0.5, cell.y * size + size * 0.5)


func press_key(keycode: int, pressed: bool) -> void:
	var ev := InputEventKey.new()
	ev.keycode = keycode
	ev.physical_keycode = keycode
	ev.pressed = pressed
	Input.parse_input_event(ev)
	await process_frame


func tap_key(keycode: int) -> void:
	await press_key(keycode, true)
	await press_key(keycode, false)


## Let go of several keys in the same frame, as a hand leaving a diagonal does.
func release_keys(keycodes: Array) -> void:
	for keycode in keycodes:
		var ev := InputEventKey.new()
		ev.keycode = keycode
		ev.physical_keycode = keycode
		ev.pressed = false
		Input.parse_input_event(ev)
	await process_frame


## Hold a key down for a number of frames, then let go. What "walk east for a
## second" looks like from outside the game.
func hold_key(keycode: int, frame_count: int) -> void:
	await press_key(keycode, true)
	await frames(frame_count)
	await press_key(keycode, false)
	await frames(2)


func expect(ok: bool, what: String, detail: String = "") -> void:
	# An assert landing is the definition of progress, so it is what puts
	# the watchdog back to zero.
	_elapsed = 0.0
	if ok:
		passed += 1
	else:
		_fail(what, detail)


func _fail(what: String, detail: String = "") -> void:
	failed += 1
	print("  FAIL  ", what, "  ", detail)


## 0028 - picking a seed with a number key, and the strip that says why.
func _case_0028_seeds() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	var hud: DayHud = require_control("DayHud")
	if driver == null or hud == null:
		_completed += 1
		await close_scene()
		return

	var state := driver.state
	var ids := Farming.seeds()

	# **There is a row per crop, and it was built from the table.** Nothing in
	# the HUD names a crop, so a fourth one appears here on its own.
	for id in ids:
		var row: Label = require_control("seed_%s" % id)
		expect(row != null, "the strip has a row for %s" % id)
		if row == null:
			continue
		expect(row.text.contains(str(id)), "which says what it is", row.text)
		expect(row.text.contains("%ds" % Farming.seconds_to_grow(id)),
			"and how long it takes to grow", row.text)
		expect(row.text.contains(str(Farming.value_per_day(id))),
			"and what a plot of it is worth over a day", row.text)
		expect(row.text.contains("$%d" % int((GameData.CROPS[id]
			as Dictionary)["seed_cost"])), "and what the seed costs", row.text)

	# **The chosen row is the lit one**, so the strip answers "what am I about
	# to plant" without the player remembering which key they last pressed.
	var first: Label = require_control("seed_%s" % ids[0])
	var second: Label = require_control("seed_%s" % ids[1])
	await frames(2)
	expect(ink(first) != ink(second),
		"the selected crop is lit and the others are not",
		"%s against %s" % [ink(first), ink(second)])
	var lit_colour := ink(first)

	# **The number key picks**, through the real key, in the real scene.
	expect(Farming.selected_seed(state) == StringName(ids[0]),
		"the first crop is what a new farm starts on",
		str(Farming.selected_seed(state)))
	await tap_key(KEY_2)
	await until(func() -> bool:
		return Farming.selected_seed(state) == StringName(ids[1]),
		"the 2 key to pick the second crop")
	expect(Farming.selected_seed(state) == StringName(ids[1]),
		"2 picks the second crop", str(Farming.selected_seed(state)))
	await frames(2)
	expect(ink(second) == lit_colour, "and the strip moves the light",
		"%s" % ink(second))
	expect(ink(first) != lit_colour, "off the one it left", "%s"
		% ink(first))

	# **A key past the last crop changes nothing**, rather than selecting
	# something that is not there and failing at the furrow a minute later.
	await tap_key(KEY_6)
	await frames(2)
	expect(Farming.selected_seed(state) == StringName(ids[1]),
		"a number with no crop behind it is ignored",
		str(Farming.selected_seed(state)))

	# **And what gets planted is what the strip said.** Walk the farmer onto a
	# plot, till it, plant it, and look at what came up.
	await tap_key(KEY_3)
	await until(func() -> bool:
		return Farming.selected_seed(state) == StringName(ids[2]),
		"the 3 key to pick the third crop")
	var chosen := Farming.selected_seed(state)

	var cell := _reachable_plot(state)
	expect(cell != Vector2i(-1, -1), "there is soil to stand next to")
	if cell != Vector2i(-1, -1):
		var stand := cell + Vector2i(0, -1)
		var who: Dictionary = state["player"]
		who["pos"] = [stand.x * Player.SUBTILE + Player.SUBTILE / 2,
			stand.y * Player.SUBTILE + Player.SUBTILE / 2]
		who["facing"] = Player.SOUTH
		await frames(2)
		expect(Player.target(state) == cell, "the farmer is looking at it",
			str(Player.target(state)))

		await hold_key(KEY_SPACE, 4)
		await until(func() -> bool: return Farming.is_tilled(state, cell),
			"the ground to be turned over")
		expect(Farming.is_tilled(state, cell), "space tills it")

		await hold_key(KEY_SPACE, 4)
		await until(func() -> bool: return Farming.crop_on(state, cell) != &"",
			"a seed to go in")
		expect(Farming.crop_on(state, cell) == chosen,
			"and what went in is what the strip said it would be",
			"%s, not %s" % [Farming.crop_on(state, cell), chosen])

	# The strip is a day thing: it goes away with the day.
	await hold_key(KEY_N, 4)
	await until(func() -> bool: return not hud.shows_day(),
		"the day HUD to go")
	expect(not hud.shows_day(), "and the seed strip goes with the day")
	await tap_key(KEY_1)
	await frames(2)
	expect(Farming.selected_seed(state) == chosen,
		"a number key at night picks nothing - there is no field to plant",
		str(Farming.selected_seed(state)))

	await close_scene()
	_completed += 1     # last line: an abandoned case never gets here


## A soil cell with a free tile above it to stand on.
func _reachable_plot(state: Dictionary) -> Vector2i:
	for cell in Farm.cells_of(state, Farm.Terrain.SOIL):
		if not Farm.is_empty(state, cell) or Farming.is_tilled(state, cell):
			continue
		if Farm.walkable(state, cell + Vector2i(0, -1)):
			return cell
	return Vector2i(-1, -1)


## 0029 - filling the can at the well, and watering a row with one held key.
func _case_0029_watering() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	var hud: DayHud = require_control("DayHud")
	if driver == null or hud == null:
		_completed += 1
		await close_scene()
		return

	var state := driver.state
	var can: Label = require_control("WaterCan")
	expect(can != null, "the HUD says how much water is in hand")

	# **An empty can says where to fill it.** A number on its own would leave a
	# player who has not found the well with no idea what to do about it.
	expect(Farming.water_carried(state) == 0, "the can starts empty")
	await frames(2)
	expect(can != null and can.text.to_lower().contains("well"),
		"and an empty one points at the well", can.text if can else "")

	# **Walking up to the well fills it**, with nothing pressed.
	var well: Vector2i = Farm.cells_with(state, &"well")[0]
	_stand_at(state, well + Vector2i(0, -1))
	await until(func() -> bool: return Farming.water_carried(state) > 0,
		"standing by the well to fill the can")
	expect(Farming.water_carried(state) == GameData.WATER_CAN_CAPACITY,
		"standing next to the well fills the can to the top",
		str(Farming.water_carried(state)))
	await frames(2)
	expect(can != null and can.text.contains(str(GameData.WATER_CAN_CAPACITY)),
		"and the HUD says so", can.text if can else "")

	# A row of four, planted and dry, with somewhere to stand at the west end.
	var row := _a_planted_row(state, 4)
	expect(row.size() == 4, "there is a row to water", str(row.size()))
	if row.size() < 4:
		await close_scene()
		_completed += 1
		return
	for cell in row:
		expect(not Farming.is_watered(state, cell), "and it is dry to start")

	var start: Vector2i = row[0] + Vector2i(-1, 0)
	_stand_at(state, start, Player.EAST)
	await frames(2)
	var before := Farming.water_carried(state)

	# **One held key and a walk down the row.** Not four presses, and not four
	# stops: watering is the one verb that finishes on the tick it starts, so
	# stepping does not cancel it the way stepping cancels chopping.
	await press_key(KEY_SPACE, true)
	await press_key(KEY_D, true)
	await until(func() -> bool: return Farming.is_watered(state, row[3]),
		"the walk to reach the end of the row", 900)
	await press_key(KEY_D, false)
	await press_key(KEY_SPACE, false)
	await frames(2)

	var wet := 0
	for cell in row:
		if Farming.is_watered(state, cell):
			wet += 1
	expect(wet == row.size(), "holding water across a row waters all of it",
		"%d of %d" % [wet, row.size()])

	# **Once each.** A held key on a verb that repeated would have emptied the
	# can into the first tile.
	var spent := before - Farming.water_carried(state)
	expect(spent == row.size(), "one tile off the can per tile, not one per "
		+ "tick", "%d spent for %d tiles" % [spent, row.size()])

	# And walking back over it spends nothing, because there is nothing to do.
	var after_row := Farming.water_carried(state)
	await press_key(KEY_SPACE, true)
	await press_key(KEY_A, true)
	await frames(60)
	await press_key(KEY_A, false)
	await press_key(KEY_SPACE, false)
	await frames(2)
	expect(Farming.water_carried(state) == after_row,
		"walking back over a wet row spends nothing",
		str(Farming.water_carried(state)))

	# **The night dries it out**, so the chore comes round again tomorrow.
	await hold_key(KEY_N, 4)
	await until(func() -> bool:
		return int(state["phase"]) != Phases.DAY, "the night to start")
	var still_wet := 0
	for cell in row:
		if Farming.is_watered(state, cell):
			still_wet += 1
	expect(still_wet == 0, "the night dries the whole field out",
		str(still_wet))

	await close_scene()
	_completed += 1     # last line: an abandoned case never gets here


## Put the farmer on a cell, the way the other cases do.
func _stand_at(state: Dictionary, cell: Vector2i,
		facing: int = Player.SOUTH) -> void:
	var who: Dictionary = state["player"]
	who["pos"] = [cell.x * Player.SUBTILE + Player.SUBTILE / 2,
		cell.y * Player.SUBTILE + Player.SUBTILE / 2]
	who["facing"] = facing
	who["action"] = {}


## `count` soil cells in a row running east, planted and with a free tile at
## the west end to start the walk from.
func _a_planted_row(state: Dictionary, count: int) -> Array:
	Resources.gain(state, {GameData.MONEY: 100})
	for found in Farm.cells_of(state, Farm.Terrain.SOIL):
		var cell: Vector2i = found
		if not Farm.walkable(state, cell + Vector2i(-1, 0)):
			continue
		var run: Array = []
		for i in count:
			var at := cell + Vector2i(i, 0)
			if Farm.terrain_at(state, at) != Farm.Terrain.SOIL \
					or not Farm.is_empty(state, at):
				break
			run.append(at)
		if run.size() < count:
			continue
		for planted in run:
			var at2: Vector2i = planted
			Farming.act(state, at2)         # till
			Farming.act(state, at2)         # plant
		return run
	return []


## 0030 - standing at the pond and landing one, through the real keys.
func _case_0030_fishing() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	if driver == null:
		_completed += 1
		await close_scene()
		return

	var state := driver.state
	var line: Label = require_control("FishingLine")
	expect(line != null, "the HUD has somewhere to say there is a line out")
	await frames(2)
	expect(line != null and not line.visible,
		"and it says nothing when nobody is fishing")

	# Stand on the bank looking at the water.
	var shore := _a_shore(state)
	expect(shore != Vector2i(-1, -1), "there is a bank to fish from")
	if shore == Vector2i(-1, -1):
		await close_scene()
		_completed += 1
		return
	var pond := _water_beside(state, shore)
	_stand_at(state, shore, _facing_towards(shore, pond))
	await frames(2)
	expect(Player.target(state) == pond, "the farmer is looking at the water",
		str(Player.target(state)))
	expect(Interact.verb_at(state, pond) == &"fish",
		"which offers a cast", str(Interact.verb_at(state, pond)))

	# **Cast.** One press, and then the wait is out of the player's hands.
	await hold_key(KEY_SPACE, 4)
	await until(func() -> bool: return Fishing.is_casting(state),
		"the cast to go in")
	expect(Fishing.is_casting(state), "pressing interact casts")
	expect(Fishing.line_cell(state) == pond, "into the water in front",
		str(Fishing.line_cell(state)))
	await frames(2)
	expect(line != null and line.visible,
		"and the HUD says there is a line out")
	var farmer: PlayerView = require_control("PlayerView")
	var rod_body: Sprite2D = farmer.get_node("Body")
	await until(func() -> bool: return farmer.playing() == &"reel", "the farmer holds the rod after casting")
	expect(rod_body.texture.resource_path == PlayerArt.texture_path(&"reel", 0),
		"Waiting for a fish keeps the rod-ready drawing")

	# **Wait for the bite**, which is the part the player cannot hurry.
	var bit := await until(func() -> bool: return Fishing.is_biting(state),
		"a fish to bite", 1200)
	expect(bit, "something bites inside the lever range")
	await frames(1)
	expect(line != null and line.text.to_lower().contains("bite"),
		"and the HUD shouts about it", line.text if line else "")
	expect(Interact.verb_at(state, pond) == &"reel",
		"the water says reel now", str(Interact.verb_at(state, pond)))
	expect(farmer.playing() == &"reel" and rod_body.texture.resource_path == PlayerArt.texture_path(&"reel", 0),
		"The rod remains in hand when the fish bites")

	# **Land it.** A press inside the window, and the fish is in the basket.
	var before := Resources.amount(state, GameData.FISH)
	await tap_key(KEY_SPACE)
	await until(func() -> bool:
		return Resources.amount(state, GameData.FISH) > before,
		"the fish to come in")
	expect(Resources.amount(state, GameData.FISH) > before,
		"reeling inside the window lands a fish",
		"%d then %d" % [before, Resources.amount(state, GameData.FISH)])
	expect(not Fishing.is_casting(state), "and the line comes out with it")
	await frames(2)
	expect(line != null and not line.visible, "and the HUD goes quiet")

	# **Walking away gives a cast up**, through the real movement keys.
	await hold_key(KEY_SPACE, 4)
	await until(func() -> bool: return Fishing.is_casting(state),
		"a second cast to go in")
	await press_key(KEY_W, true)
	await frames(40)
	await press_key(KEY_W, false)
	await frames(2)
	expect(not Fishing.is_casting(state),
		"walking off the bank gives the cast up")

	await close_scene()
	_completed += 1     # last line: an abandoned case never gets here


## Real doorway, room movement, furniture, camera and pause through Main.
func _case_0111_farm_house() -> void:
	print("CASE 0111 farm house")
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	var state: Dictionary = driver.state
	var porch := House.porch(state)
	_stand_at(state, porch)
	var outside := Player.position(state)
	await tap_key(KEY_SPACE)
	await until(func(): return House.inside(state), "the porch interact key to enter the house")
	await frames(4)
	expect(not (require_control("WorldView") as WorldView).visible
		and not (require_control("DayHud") as DayHud).visible, "Indoor view hides the farm and outdoor planting controls")
	var room: HouseView = require_control("HouseView")
	expect(not (require_control("WorkshopPanel") as WorkshopPanel).is_open()
		and not (require_control("TutorialPrompt") as TutorialPrompt).visible,
		"Indoor coordinates cannot open outdoor workshop or tutorial panels")
	expect(room._clip.visible and room._farmer.visible, "The furnished room uses the actual farmer view")
	await press_key(KEY_W, true)
	await until(func(): return Player.cell(state).y < House.SPAWN.y, "the farmer to walk inside")
	await press_key(KEY_W, false)
	var kitchen: Dictionary = House.FURNITURE[0]
	var kitchen_front: int = kitchen["cell"].y + kitchen["size"].y
	_stand_at(state, Vector2i(4, kitchen_front), Player.NORTH)
	var target_tick := int(state["tick"]) + 20
	await press_key(KEY_W, true)
	await until(func(): return int(state["tick"]) >= target_tick, "walking into the kitchen for twenty ticks")
	await press_key(KEY_W, false)
	expect(Player.cell(state).y == kitchen_front, "Real movement cannot pass through kitchen furniture")
	await tap_key(KEY_B)
	expect(not Building.is_active(state), "The build key cannot open an outdoor ghost inside the house")
	await tap_key(KEY_EQUAL)
	await frames(10)
	expect(room._room.scale == Vector2.ONE, "The interior camera has no zoom either")
	await tap_key(KEY_P)
	await until(func(): return not driver.running, "the indoor pause menu to stop simulation")
	var paused_tick := int(state["tick"])
	var paused_pos := Player.position(state)
	await frames(2)
	var paused_flame := room._ambient_time
	await frames(30)
	expect(int(state["tick"]) == paused_tick and Player.position(state) == paused_pos and House.inside(state),
		"Pause preserves indoor position and freezes farm time")
	expect(room._ambient_time == paused_flame, "The pause key also freezes the visible hearth flame")
	await tap_key(KEY_ESCAPE)
	await until(func(): return driver.running, "the indoor pause menu to resume")
	_stand_at(state, House.SPAWN)
	await tap_key(KEY_SPACE)
	await until(func(): return not House.inside(state), "the interior doorway to return outside")
	await frames(4)
	expect(Player.position(state) == outside and (require_control("WorldView") as WorldView).visible,
		"The same interact key returns to the saved porch position and farm camera")
	await tap_key(KEY_SPACE)
	await until(func(): return House.inside(state), "another visit to the house")
	await tap_key(KEY_N)
	await until(func(): return int(state["phase"]) == Phases.PREPARATION, "night input during a house visit")
	expect(not House.inside(state), "Starting night inside returns outside for defence")
	await close_scene()
	_completed += 1


## Land next to open water.
func _a_shore(state: Dictionary) -> Vector2i:
	for found in Farm.cells_of(state, Farm.Terrain.WATER):
		var wet: Vector2i = found
		for step in [Vector2i(0, -1), Vector2i(-1, 0), Vector2i(1, 0)]:
			var dry: Vector2i = wet + step
			if Farm.walkable(state, dry) and Farm.walkable(state, dry + step):
				return dry
	return Vector2i(-1, -1)


func _water_beside(state: Dictionary, shore: Vector2i) -> Vector2i:
	for step in [Vector2i(0, 1), Vector2i(1, 0), Vector2i(-1, 0),
			Vector2i(0, -1)]:
		if Farm.terrain_at(state, shore + step) == Farm.Terrain.WATER:
			return shore + step
	return Vector2i(-1, -1)


func _facing_towards(here: Vector2i, there: Vector2i) -> int:
	var step := there - here
	if step.y > 0:
		return Player.SOUTH
	if step.y < 0:
		return Player.NORTH
	return Player.EAST if step.x > 0 else Player.WEST


## 0032 - putting a press on the farm and pressing corn into oil.
func _case_0032_press() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	var build: BuildMode = require_control("BuildMode")
	if driver == null or build == null:
		_completed += 1
		await close_scene()
		return

	var state := driver.state
	Resources.gain(state, Building.cost_of(&"press"))
	Resources.gain(state, {GameData.CORN: 20})

	# **The press is in the build palette.** It was not before this task: the
	# palette read the defences table and a press is not a defence.
	await hold_key(KEY_B, 4)
	await until(func() -> bool: return Building.is_active(state),
		"build mode to open")
	expect(Building.is_active(state), "B opens build mode")
	var row: Button = require_control("build_press")
	expect(row != null, "and the palette has a row for the press")
	if row == null:
		await close_scene()
		_completed += 1
		return

	# **Every row of the palette is on the screen.** Making the buildings
	# placeable took it from eight rows to twelve and pushed the last of them
	# to y=294 on a 270 pixel screen - the press could not be clicked at all.
	# The next task that adds a defence gets told, rather than finding out.
	var frame: Control = require_control("Frame")
	var screen := Vector2(480, 270)
	expect(frame != null and frame.get_global_rect().end.y <= screen.y,
		"the build palette fits on the screen",
		str(frame.get_global_rect()) if frame else "")
	for id in Building.catalogue(state):
		var each: Control = require_control("build_%s" % id)
		if each == null:
			continue
		var box := each.get_global_rect()
		expect(box.position.y >= 0 and box.end.y <= screen.y,
			"the %s row is somewhere it can be clicked" % id, str(box))
	await click_control("build_press")
	await until(func() -> bool: return Building.selected(state) == &"press",
		"the press to be selected")
	expect(Building.selected(state) == &"press", "clicking it selects it",
		str(Building.selected(state)))

	# **Down it goes**, two tiles by two, paid for out of the ledger.
	var spot := _room_for_press(state)
	expect(spot != Vector2i(-1, -1), "there is room for a press")
	if spot == Vector2i(-1, -1):
		await close_scene()
		_completed += 1
		return
	var wood_before := Resources.amount(state, GameData.WOOD)
	await click_cell(spot)
	await until(func() -> bool:
		return Farm.occupant(state, spot).get("id", &"") == &"press",
		"the press to go down")
	expect(Farm.occupant(state, spot).get("id", &"") == &"press",
		"clicking the farm puts it there",
		str(Farm.occupant(state, spot)))
	expect(Resources.amount(state, GameData.WOOD) < wood_before,
		"and it was paid for")
	var covered := 0
	for at in Building.footprint(&"press", spot):
		if Farm.occupant(state, at).get("id", &"") == &"press":
			covered += 1
	expect(covered == 12, "all twelve tiles of it are there", str(covered))

	# B toggles it, the same key that opened it.
	await hold_key(KEY_B, 4)
	await until(func() -> bool: return not Building.is_active(state),
		"build mode to close")
	expect(not Building.is_active(state), "B closes build mode again")

	# **Stand at it and press interact.** The far corner, because any tile of
	# a press is the same press.
	var corner: Vector2i = Building.footprint(&"press", spot)[3]
	var stand := _free_cell_beside(state, corner)
	expect(stand != Vector2i(-1, -1), "somewhere to stand at the press")
	if stand == Vector2i(-1, -1):
		await close_scene()
		_completed += 1
		return
	_stand_at(state, stand, _facing_towards(stand, corner))
	await frames(2)
	expect(Player.target(state) == corner, "the farmer is at the press",
		str(Player.target(state)))
	expect(Interact.verb_at(state, corner) == &"craft",
		"which offers to make something",
		str(Interact.verb_at(state, corner)))

	Crafting.select_recipe(state, &"press_oil")
	var oil_before := Resources.amount(state, GameData.OIL)
	await hold_key(KEY_SPACE, 4)
	await until(func() -> bool: return Crafting.busy(state, spot),
		"the press to start")
	expect(Crafting.busy(state, spot), "and pressing interact starts it")

	# **And it finishes into oil.** Driven at speed, because twenty seconds of
	# real time is not something a test should sit through.
	var ticks := int((GameData.RECIPES[&"press_oil"] as Dictionary)["ticks"])
	Sim.advance(state, ticks + 2)
	await frames(2)
	expect(Resources.amount(state, GameData.OIL) > oil_before,
		"and out comes oil",
		"%d then %d" % [oil_before, Resources.amount(state, GameData.OIL)])

	await close_scene()
	_completed += 1     # last line: an abandoned case never gets here


## Two by two of clear farm, away from the house and the field edges.
## **East of the build panel.** The palette covers the left eighth of the
## screen, so a press placed under it is a press the click never reaches - and
## the cell has to be on camera, which near the farmer it is.
func _room_for_press(state: Dictionary) -> Vector2i:
	for y in range(6, Grid.HEIGHT - 3):
		for x in range(24, Grid.WIDTH - 6):
			var origin := Vector2i(x, y)
			var clear := true
			for at in Building.footprint(&"press", origin):
				if not Farm.buildable(state, at):
					clear = false
					break
			# Somewhere to stand at it afterwards, or the rest of the case has
			# nowhere to put the farmer.
			if clear and _free_cell_beside(state, origin + Vector2i(1, 1)) \
					!= Vector2i(-1, -1):
				return origin
	return Vector2i(-1, -1)


func _free_cell_beside(state: Dictionary, cell: Vector2i) -> Vector2i:
	for step in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(0, -1),
			Vector2i(-1, 0)]:
		var at: Vector2i = cell + (step as Vector2i)
		if Farm.walkable(state, at):
			return at
	return Vector2i(-1, -1)


## 0033 - the power line, and what it says when the farm is over-built.
func _case_0033_power() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	var hud: DayHud = require_control("DayHud")
	if driver == null or hud == null:
		_completed += 1
		await close_scene()
		return

	var state := driver.state
	var power: Label = require_control("PowerLine")
	expect(power != null, "the HUD has a power line")
	if power == null:
		await close_scene()
		_completed += 1
		return

	await frames(2)
	expect(power.visible, "and it is up on day one")
	expect(power.text.contains("%d" % Power.supply(state)),
		"saying what the farm supplies", power.text)
	expect(power.text.contains("/"), "against what it draws", power.text)
	var settled := ink(power)

	# **Build past the farm's means and the line says so.**
	Resources.gain(state, {GameData.WOOD: 600, GameData.IRON: 600})
	var built := 0
	for y in range(3, 12):
		for x in range(22, 34):
			if built >= 4:
				break
			if Building.place(state, &"auto_crossbow", Vector2i(x, y)):
				built += 1
		if built >= 4:
			break
	expect(built == 4, "four hungry towers go up", str(built))
	await until(func() -> bool: return Power.is_short(state),
		"the farm to run short")
	await frames(2)
	expect(Power.is_short(state), "and the farm is short",
		"%d/%d" % [Power.supply(state), Power.draw(state)])
	expect(power.text.contains("%d%%" % Power.percent(state)),
		"the line says what that is doing to the speed of things", power.text)
	expect(ink(power) != settled, "and it changes colour to say so",
		"%s then %s" % [settled, ink(power)])

	# **A generator puts it back.**
	Resources.gain(state, Building.cost_of(&"generator"))
	Resources.gain(state, {GameData.OIL: 20})
	var spot := Vector2i(-1, -1)
	for y in range(3, 12):
		for x in range(24, 34):
			var origin := Vector2i(x, y)
			var clear := true
			for at in Building.footprint(&"generator", origin):
				if not Farm.buildable(state, at):
					clear = false
					break
			if clear:
				spot = origin
				break
		if spot != Vector2i(-1, -1):
			break
	expect(spot != Vector2i(-1, -1), "there is room for a generator")
	if spot != Vector2i(-1, -1):
		expect(Building.place(state, &"generator", spot), "and it goes up")
		await until(func() -> bool: return not Power.is_short(state),
			"the generator to take up the slack")
		await frames(2)
		expect(not Power.is_short(state),
			"and the farm is not short any more",
			"%d/%d" % [Power.supply(state), Power.draw(state)])
		expect(ink(power) == settled, "the line settles back", "%s"
			% ink(power))

	# **It stays up after dark**, which is when a generator running dry is the
	# thing a player most needs to be told about.
	await hold_key(KEY_N, 4)
	await until(func() -> bool: return not hud.shows_day(), "the day to end")
	await frames(2)
	expect(not hud.shows_day(), "the day HUD is gone")
	expect(power.visible, "and the power line is not - towers draw at night")
	expect(power.text.contains("/"),
		"still saying supply against draw", power.text)

	await close_scene()
	_completed += 1     # last line: an abandoned case never gets here


## 0034 - walking over to the chickens.
func _case_0034_livestock() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	if driver == null:
		_completed += 1
		await close_scene()
		return

	var state := driver.state
	var hens := Farm.cells_with(state, &"chicken")
	expect(hens.size() > 0, "there are chickens on the farm")
	if hens.is_empty():
		await close_scene()
		_completed += 1
		return

	# Pick one with somewhere to stand beside it.
	var hen := Vector2i(-1, -1)
	var stand := Vector2i(-1, -1)
	for found in hens:
		var at: Vector2i = found
		var beside := _free_cell_beside(state, at)
		if beside != Vector2i(-1, -1):
			hen = at
			stand = beside
			break
	expect(hen != Vector2i(-1, -1), "one of them can be walked up to")
	if hen == Vector2i(-1, -1):
		await close_scene()
		_completed += 1
		return

	# **An empty chicken offers nothing**, so the key does nothing and the
	# highlight says so. (`Player.target()` still points at it - the fallback
	# returns the cell ahead whatever is on it, and it is `verb_at` that
	# decides whether anything happens.)
	_stand_at(state, stand, _facing_towards(stand, hen))
	await frames(2)
	expect(Interact.verb_at(state, hen) == &"",
		"a chicken with nothing to give offers nothing",
		str(Interact.verb_at(state, hen)))
	var nothing := Resources.amount(state, GameData.MEAT)
	await hold_key(KEY_SPACE, 6)
	await frames(2)
	expect(Resources.amount(state, GameData.MEAT) == nothing,
		"and pressing interact at it takes nothing",
		str(Resources.amount(state, GameData.MEAT)))

	# Wait for it to have something. Driven at speed rather than in real time.
	var every := int((GameData.LIVESTOCK[&"chicken"]
		as Dictionary)["every_ticks"])
	Sim.advance(state, every + 2)
	await frames(2)
	expect(Livestock.ready_at(state, hen) > 0, "it has something now",
		str(Livestock.ready_at(state, hen)))
	_stand_at(state, stand, _facing_towards(stand, hen))
	await frames(2)
	expect(Player.target(state) == hen, "and now the farmer can aim at it",
		str(Player.target(state)))
	expect(Interact.verb_at(state, hen) == &"collect",
		"which offers to collect", str(Interact.verb_at(state, hen)))

	# **Press interact and the meat is in the ledger.**
	var before := Resources.amount(state, GameData.MEAT)
	await hold_key(KEY_SPACE, 4)
	await until(func() -> bool:
		return Resources.amount(state, GameData.MEAT) > before,
		"the meat to come in")
	expect(Resources.amount(state, GameData.MEAT) > before,
		"collecting puts meat in the ledger",
		"%d then %d" % [before, Resources.amount(state, GameData.MEAT)])
	expect(Livestock.ready_at(state, hen) == 0, "and the chicken is empty")
	await frames(4)
	expect(Resources.amount(state, GameData.MEAT)
		== before + int((GameData.LIVESTOCK[&"chicken"]
			as Dictionary)["holds"]),
		"once, not once a tick - a held key does not milk it dry",
		str(Resources.amount(state, GameData.MEAT)))

	await close_scene()
	_completed += 1     # last line: an abandoned case never gets here


## 0035 - the pool, and watching it drain after dark.
func _case_0035_ammo() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	var hud: DayHud = require_control("DayHud")
	if driver == null or hud == null:
		_completed += 1
		await close_scene()
		return

	var state := driver.state
	var ammo: Label = require_control("AmmoLine")
	expect(ammo != null, "the HUD has an ammunition line")
	if ammo == null:
		await close_scene()
		_completed += 1
		return

	await frames(2)
	expect(ammo.visible, "and it is up on day one")
	for res in Ammo.kinds():
		expect(ammo.text.contains(str(res)),
			"it names %s" % res, ammo.text)

	# **An empty pool is flagged**, rather than being a number nobody reads.
	for res in Ammo.kinds():
		Resources.spend(state, res, Resources.amount(state, res))
	await frames(2)
	var warned := ink(ammo)
	Resources.gain(state, {GameData.GUNPOWDER: 9, GameData.INCENDIARY: 9})
	await frames(2)
	expect(ink(ammo) != warned, "and a stocked one is not",
		"%s then %s" % [warned, ink(ammo)])
	expect(ammo.text.contains("9"), "with the count on it", ammo.text)

	# **It stays up after dark**, which is when it is actually draining.
	await hold_key(KEY_N, 4)
	await until(func() -> bool: return not hud.shows_day(), "the day to end")
	await frames(2)
	expect(not hud.shows_day(), "the day HUD is gone")
	expect(ammo.visible, "and the ammunition line is not")
	expect(ammo.text.contains(str(GameData.GUNPOWDER)),
		"still naming the pool", ammo.text)

	await close_scene()
	_completed += 1     # last line: an abandoned case never gets here


## 0036 - the inventory, on one key, without stopping the day.
func _case_0036_inventory() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	var panel: InventoryPanel = require_control("InventoryPanel")
	if driver == null or panel == null:
		_completed += 1
		await close_scene()
		return

	var state := driver.state
	await frames(2)
	expect(not panel.is_open(), "the inventory starts closed")

	# **One key opens it.**
	await tap_key(KEY_I)
	await until(func() -> bool: return panel.is_open(), "the panel to open")
	expect(panel.is_open(), "I opens the inventory")
	await frames(2)

	# **Every resource is on it, once**, with a row built from the table.
	for id in GameData.RESOURCES:
		var row: Control = require_control("inv_%s" % id)
		expect(row != null, "%s has a row" % id)
		var held: Label = require_control("inv_held_%s" % id)
		if held != null:
			expect(held.text == str(Resources.amount(state, id)),
				"saying how much %s there is" % id, held.text)

	# **The numbers follow the ledger while it is open.**
	var wood: Label = require_control("inv_held_%s" % GameData.WOOD)
	expect(wood != null, "there is a wood row")
	if wood != null:
		var before := wood.text
		Resources.gain(state, {GameData.WOOD: 11})
		await until(func() -> bool:
			return (require_control("inv_held_%s" % GameData.WOOD)
				as Label).text != before, "the row to follow the ledger")
		var now: Label = require_control("inv_held_%s" % GameData.WOOD)
		expect(now.text == str(Resources.amount(state, GameData.WOOD)),
			"it is a view of the ledger, not a snapshot of it", now.text)

	# **The day does not stop.** The clock runs and the crops grow behind it.
	var tick_before := int(state["tick"])
	await frames(20)
	expect(int(state["tick"]) > tick_before,
		"the day keeps running while the panel is up",
		"%d then %d" % [tick_before, state["tick"]])
	expect(panel.is_open(), "and the panel is still up")

	# **And it takes no keys away**, unlike the stall: the farmer can still
	# walk with it open.
	expect(StringName(state["open_panel"]) == &"",
		"the inventory does not claim the keyboard",
		str(state["open_panel"]))

	# **The same key closes it**, and so does cancel.
	await tap_key(KEY_I)
	await until(func() -> bool: return not panel.is_open(),
		"the panel to close")
	expect(not panel.is_open(), "I closes it again")
	await tap_key(KEY_I)
	await until(func() -> bool: return panel.is_open(), "the panel to reopen")
	await tap_key(KEY_ESCAPE)
	await until(func() -> bool: return not panel.is_open(),
		"escape to close it")
	expect(not panel.is_open(), "and escape does too")

	await close_scene()
	_completed += 1     # last line: an abandoned case never gets here


## 0037 - standing at the bench and lining five things up.
func _case_0037_queue() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	var panel: WorkshopPanel = require_control("WorkshopPanel")
	if driver == null or panel == null:
		_completed += 1
		await close_scene()
		return

	var state := driver.state
	Resources.gain(state, {GameData.WOOD: 200, GameData.STONE: 200})
	await frames(2)
	expect(not panel.is_open(),
		"the workshop panel is not up out in the field")

	# **Walking up to the bench is what opens it.** There is no key: the panel
	# is what being at the bench looks like.
	var bench := Building.anchor_of(state,
		Farm.cells_with(state, &"workshop")[0])
	var stand := _free_cell_beside(state, bench)
	expect(stand != Vector2i(-1, -1), "somewhere to stand at the workshop")
	if stand == Vector2i(-1, -1):
		await close_scene()
		_completed += 1
		return
	_stand_at(state, stand, _facing_towards(stand, bench))
	await until(func() -> bool: return panel.is_open(),
		"the panel to appear at the bench")
	expect(panel.is_open(), "standing at the bench opens it")

	var title: Label = require_control("WorkshopTitle")
	expect(title != null and title.text.to_lower().contains("workshop"),
		"and it says which bench", title.text if title else "")

	# **Clicking a recipe puts it on the queue**, and does not pay for it
	# unless it goes straight to the front.
	var before := Crafting.queue_at(state, bench).size()
	await click_control("make_barricade_kit")
	await until(func() -> bool:
		return Crafting.queue_at(state, bench).size() > before,
		"the click to queue one")
	expect(Crafting.queue_at(state, bench).size() == before + 1,
		"clicking a recipe queues it",
		str(Crafting.queue_at(state, bench)))

	var wood_after_first := Resources.amount(state, GameData.WOOD)
	await click_control("make_barricade_kit")
	await click_control("make_barricade_kit")
	await frames(4)
	expect(Crafting.queue_at(state, bench).size() == 3,
		"three lined up", str(Crafting.queue_at(state, bench)))
	expect(Resources.amount(state, GameData.WOOD) == wood_after_first,
		"and queuing the other two cost nothing - the wood goes in when an "
		+ "item reaches the front",
		str(Resources.amount(state, GameData.WOOD)))

	# **The panel counts down the one that is running.**
	var progress: Label = require_control("WorkshopProgress")
	expect(progress != null, "there is a progress line")
	if progress != null:
		expect(progress.text.contains("barricade kit"),
			"naming what is being made", progress.text)
		expect(progress.text.contains("s"), "and how long is left", progress.text)
		var shown := progress.text
		await frames(20)
		expect(progress.text != shown, "which goes down as it works",
			"%s then %s" % [shown, progress.text])

	# **Clicking a queued item takes it off**, and the rest stay in order.
	var queued := Crafting.queue_at(state, bench).duplicate()
	await click_control("queued_1")
	await until(func() -> bool:
		return Crafting.queue_at(state, bench).size() < queued.size(),
		"the middle one to come off")
	expect(Crafting.queue_at(state, bench).size() == queued.size() - 1,
		"one fewer", str(Crafting.queue_at(state, bench)))
	expect(Crafting.making(state, bench) == StringName(queued[0]),
		"and the one that was running still is",
		str(Crafting.making(state, bench)))

	# **Walking away closes it**, and the queue keeps going without anybody
	# looking - which is the whole feature.
	var kits_before := Crafting.kits(state, &"barricade")
	_stand_at(state, Vector2i(stand.x, stand.y + Building.size_of(&"workshop").y + 3), Player.SOUTH)
	await until(func() -> bool: return not panel.is_open(),
		"the panel to close when the farmer walks off")
	expect(not panel.is_open(), "walking away closes it")
	Sim.advance(state, int((GameData.RECIPES[&"barricade_kit"]
		as Dictionary)["ticks"]) + 4)
	await frames(2)
	expect(Crafting.kits(state, &"barricade") > kits_before,
		"and the bench carried on without being watched",
		str(Crafting.kits(state, &"barricade")))

	await close_scene()
	_completed += 1     # last line: an abandoned case never gets here


## 0038 - walking back to a bench and being told what it did.
func _case_0038_away() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	var panel: WorkshopPanel = require_control("WorkshopPanel")
	if driver == null or panel == null:
		_completed += 1
		await close_scene()
		return

	var state := driver.state
	Resources.gain(state, {GameData.WOOD: 200, GameData.STONE: 200})
	var bench := Building.anchor_of(state,
		Farm.cells_with(state, &"workshop")[0])
	var stand := _free_cell_beside(state, bench)
	if stand == Vector2i(-1, -1):
		await close_scene()
		_completed += 1
		return

	# Queue three, stand at the bench once so the panel has seen the tally.
	for _i in 3:
		Crafting.enqueue(state, bench, &"barricade_kit")
	_stand_at(state, stand, _facing_towards(stand, bench))
	await until(func() -> bool: return panel.is_open(), "the panel to open")
	var away: Label = require_control("WorkshopAway")
	expect(away != null, "there is a line for what happened while away")
	await frames(2)
	expect(away == null or not away.visible,
		"which says nothing the first time you walk up",
		away.text if away else "")

	# **Walk off to the pond, let the bench work, walk back.**
	var pond: Vector2i = Farm.cells_of(state, Farm.Terrain.WATER)[0]
	_stand_at(state, pond + Vector2i(0, -1), Player.SOUTH)
	await until(func() -> bool: return not panel.is_open(),
		"the panel to close when the farmer leaves")

	var ticks := int((GameData.RECIPES[&"barricade_kit"]
		as Dictionary)["ticks"])
	var kits_before := Crafting.kits(state, &"barricade")
	Sim.advance(state, ticks * 2 + 6)
	await frames(2)
	expect(Crafting.kits(state, &"barricade") >= kits_before + 2,
		"the bench worked while the farmer stood at the pond",
		str(Crafting.kits(state, &"barricade")))

	_stand_at(state, stand, _facing_towards(stand, bench))
	await until(func() -> bool: return panel.is_open(),
		"the panel to open again")
	await frames(2)
	var back: Label = require_control("WorkshopAway")
	expect(back != null and back.visible,
		"and coming back says what happened", back.text if back else "")
	if back != null:
		expect(back.text.contains("barricade kit"),
			"naming what was made", back.text)
		expect(back.text.contains("2"), "and how many", back.text)

	await close_scene()
	_completed += 1     # last line: an abandoned case never gets here


## Whether a colour is somewhere on the day's dawn-noon-dusk line.
##
## Each channel has to sit inside the range those three colours span, with a
## little slack for the fade being part way. Asking "is it exactly noon" was
## the old test and stopped being answerable when the light started moving.
func _is_daylight(colour: Color) -> bool:
	var lights: Array = [PaletteData.DAWN_TINT, PaletteData.DAY_TINT,
		PaletteData.DUSK_TINT]
	for channel in 3:
		var low := 9.0
		var high := -9.0
		for entry in lights:
			var each: Color = entry
			low = minf(low, each[channel])
			high = maxf(high, each[channel])
		if colour[channel] < low - 0.06 or colour[channel] > high + 0.06:
			return false
	return true


## 0039 - the clock, the light, and the stall that stops both.
func _case_0039_clock() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	var world: WorldView = require_control("WorldView")
	if driver == null or world == null:
		_completed += 1
		await close_scene()
		return

	var state := driver.state
	var clock: Label = require_control("Day")
	expect(clock != null, "there is a clock")
	await frames(2)
	expect(clock != null and clock.text.begins_with("DAY 1"),
		"saying which day", clock.text if clock else "")
	expect(clock != null and clock.text.contains("0:0"),
		"and starting near the top of it", clock.text if clock else "")

	# **The light is not the same at dawn as at dusk.**
	var dawn := world.light_target()
	Sim.advance(state, GameData.DAY_TICKS / 2)
	await frames(4)
	var noon := world.light_target()
	Sim.advance(state, GameData.DAY_TICKS / 2 - 30)
	await frames(4)
	var evening := world.light_target()
	expect(not dawn.is_equal_approx(noon),
		"the light moves from dawn to noon",
		"%s then %s" % [dawn, noon])
	expect(not noon.is_equal_approx(evening),
		"and from noon to evening", "%s then %s" % [noon, evening])
	expect(evening.r > dawn.r,
		"warming as it goes - evening is redder than morning",
		"%.2f against %.2f" % [evening.r, dawn.r])

	# **Past dusk the button asks rather than pressing itself.**
	var night: Button = require_control("NightButton")
	expect(night != null, "there is a night button")
	await until(func() -> bool: return Phases.is_dusk(state), "dusk", 300)
	await frames(4)
	expect(Phases.is_dusk(state), "it is dusk")
	expect(night != null and night.text.to_lower().contains("waiting"),
		"and the button asks", night.text if night else "")
	expect(int(state["phase"]) == Phases.DAY,
		"but the night has not started itself",
		Phases.name_of(int(state["phase"])))
	expect(clock != null and clock.text.to_lower().contains("dusk"),
		"and the clock says so too", clock.text if clock else "")

	Sim.advance(state, 600)
	await frames(4)
	expect(int(state["phase"]) == Phases.DAY,
		"twenty seconds later it still has not",
		Phases.name_of(int(state["phase"])))

	# **The stall stops the clock**, on screen and in the state.
	var shop: ShopPanel = require_control("ShopPanel")
	Shop.open(state)
	await until(func() -> bool: return shop.visible, "the stall to open")
	var shown := clock.text
	var ticked := int(state["day_tick"])
	await frames(30)
	expect(int(state["day_tick"]) == ticked,
		"the day clock stops while the stall is open",
		str(int(state["day_tick"]) - ticked))
	expect(clock.text == shown, "and the label with it", clock.text)

	await tap_key(KEY_ESCAPE)
	await until(func() -> bool: return not Shop.is_open(state),
		"the stall to close")
	await frames(20)
	expect(int(state["day_tick"]) > ticked,
		"and closing it starts the day again",
		str(int(state["day_tick"]) - ticked))

	await close_scene()
	_completed += 1     # last line: an abandoned case never gets here


## 0040 - two tabs, a shelf that empties, and the seeds side by side.
func _case_0040_shop() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	var shop: ShopPanel = require_control("ShopPanel")
	if driver == null or shop == null:
		_completed += 1
		await close_scene()
		return

	var state := driver.state
	Resources.gain(state, {GameData.MONEY: 4000})
	Shop.open(state)
	await until(func() -> bool: return shop.visible, "the stall to open")
	await frames(2)

	# **It opens on selling**, which is what the player came for.
	expect(Shop.tab(state) == Shop.SELL, "the stall opens on selling",
		str(Shop.tab(state)))
	var probe: Button = require_control("sell_one_wood")
	print("  PROBE sell_one_wood: rect %s, disabled %s, scroll %s"
		% [str(probe.get_global_rect()) if probe else "none",
			str(probe.disabled) if probe else "?",
			str((require_control("Scroll") as Control).get_global_rect())])
	expect(probe != null, "so the sell rows are there")
	expect(locate_control("buy_one_wood") == null,
		"and the buy rows are not - it is one tab at a time")

	# **Two tabs, not two shops.**
	await click_control("tab_buy")
	await until(func() -> bool: return Shop.tab(state) == Shop.BUY,
		"the buy tab")
	await frames(2)
	expect(Shop.tab(state) == Shop.BUY, "clicking BUY switches",
		str(Shop.tab(state)))
	expect(require_control("buy_one_wood") != null, "and the buy rows appear")
	expect(locate_control("sell_one_wood") == null, "as the sell rows go")

	# **The shelf is on the label, and it empties.**
	var label: Label = require_control("buy_label_stone")
	expect(label != null, "the stone row says what is left")
	if label != null:
		expect(label.text.contains(str(Shop.stock_of(state, GameData.STONE))),
			"with today's number on it", label.text)

	var shelf := Shop.stock_of(state, GameData.STONE)
	await click_control("buy_one_stone")
	await until(func() -> bool:
		return Shop.stock_of(state, GameData.STONE) < shelf,
		"one off the shelf")
	expect(Shop.stock_of(state, GameData.STONE) == shelf - 1,
		"buying one takes one off it",
		str(Shop.stock_of(state, GameData.STONE)))
	await frames(2)
	var after: Label = require_control("buy_label_stone")
	expect(after != null and after.text.contains(str(shelf - 1)),
		"and the label says so", after.text if after else "")

	# Empty it, and the button stops offering.
	while Shop.stock_of(state, GameData.STONE) > 0:
		Shop.buy(state, GameData.STONE, 1)
	await frames(4)
	var sold_out: Button = require_control("buy_one_stone")
	expect(sold_out != null and sold_out.disabled,
		"an empty shelf is a button that says no rather than one that lies")

	# **The seeds, side by side with what the choice needs.**
	for id in Farming.seeds():
		var seed: Label = require_control("seed_label_%s" % id)
		expect(seed != null, "%s has a row" % id)
		if seed == null:
			continue
		expect(seed.text.contains("%ds" % Farming.seconds_to_grow(id)),
			"saying how long it takes", seed.text)
		expect(seed.text.contains(str(Farming.value_per_day(id))),
			"and what it is worth over a day", seed.text)

	var other := &""
	for id in Farming.seeds():
		if Farming.selected_seed(state) != id:
			other = id
			break
	var sow: Button = require_control("sow_%s" % other)
	print("  sow_%s: rect %s, disabled %s"
		% [other, str(sow.get_global_rect()) if sow else "none",
			str(sow.disabled) if sow else "?"])
	await click_control("sow_%s" % other)
	await until(func() -> bool: return Farming.selected_seed(state) == other,
		"the seed to change")
	expect(Farming.selected_seed(state) == other,
		"and clicking one picks it", str(Farming.selected_seed(state)))

	await tap_key(KEY_ESCAPE)
	await until(func() -> bool: return not Shop.is_open(state),
		"the stall to close")
	expect(not Shop.is_open(state), "escape leaves the stall")

	await close_scene()
	_completed += 1     # last line: an abandoned case never gets here


## 0041 - five lines that follow the thing they are about.
func _case_0041_tutorial() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	var prompt: TutorialPrompt = require_control("TutorialPrompt")
	if driver == null or prompt == null:
		_completed += 1
		await close_scene()
		return

	var state := driver.state
	await frames(3)

	# **It is up on day one**, on the first line.
	expect(prompt.visible, "day one starts with something to read")
	expect(prompt.showing() == &"chop", "and it is about the trees",
		str(prompt.showing()))
	var line: Label = require_control("TutorialLine")
	expect(line != null and not line.text.strip_edges().is_empty(),
		"there is a line of text", line.text if line else "")

	# **It sits over the thing**, not in a corner - and on the screen.
	var arrow: Label = require_control("TutorialArrow")
	expect(arrow != null and arrow.visible, "with a pointer under it")
	var box := line.get_global_rect()
	expect(box.position.x >= 0.0 and box.end.x <= 480.0
		and box.position.y >= 0.0 and box.end.y <= 270.0,
		"and all of it is on the screen", str(box))
	var first_at := arrow.position

	# **It follows.** Move the farmer and the pointer goes with the nearest
	# tree, because which tree is nearest is a fact about where you are.
	var trees := Farm.cells_with(state, &"tree")
	var far: Vector2i = trees[trees.size() - 1]
	_stand_at(state, _free_cell_beside(state, far), Player.SOUTH)
	await frames(3)
	expect(arrow.position != first_at,
		"walking across the farm moves the pointer",
		"%s then %s" % [first_at, arrow.position])

	# **Doing the thing makes it go away**, and the next one appears.
	Resources.gain(state, {GameData.WOOD: 5})
	await until(func() -> bool: return prompt.showing() == &"plant",
		"the second line")
	expect(prompt.showing() == &"plant",
		"chopping moves it on to the sowing", str(prompt.showing()))

	# **It takes nothing away.** The line is up and every key still works.
	var before := int(state["day_tick"])
	await hold_key(KEY_B, 4)
	await until(func() -> bool: return Building.is_active(state),
		"build mode with the prompt up")
	expect(Building.is_active(state),
		"build mode opens while the tutorial is talking")
	await hold_key(KEY_B, 4)
	await until(func() -> bool: return not Building.is_active(state),
		"build mode to close")
	expect(int(state["day_tick"]) > before,
		"and the day ran the whole time", str(int(state["day_tick"]) - before))

	# **Out of order is fine.** Skip straight to the last thing the game has
	# not asked for yet and watch the lines behind it disappear.
	Resources.gain(state, {GameData.WOOD: 200, GameData.IRON: 200,
		GameData.STONE: 200})
	var spot := Vector2i(-1, -1)
	for y in range(4, 12):
		for x in range(20, 32):
			if Farm.buildable(state, Vector2i(x, y)):
				spot = Vector2i(x, y)
				break
		if spot != Vector2i(-1, -1):
			break
	expect(Building.place(state, &"gun_tower", spot),
		"a tower goes down out of order")
	await until(func() -> bool: return Tutorial.is_done(state, &"build"),
		"the build line to tick itself off")
	expect(Tutorial.is_done(state, &"build"),
		"and the line about building is simply gone, unread")

	# **It goes away with the day.**
	await hold_key(KEY_N, 4)
	await until(func() -> bool: return int(state["phase"]) != Phases.DAY,
		"the night")
	await frames(3)
	expect(not prompt.visible, "and nothing is being taught at night")

	await close_scene()
	_completed += 1     # last line: an abandoned case never gets here


## 0046 - holding a wall over a tile and seeing where they would go instead.
func _case_0046_walls() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	var build: BuildMode = require_control("BuildMode")
	var world: WorldView = require_control("WorldView")
	if driver == null or build == null or world == null:
		_completed += 1
		await close_scene()
		return

	var state := driver.state
	Resources.gain(state, {GameData.STONE: 200, GameData.WOOD: 200,
		GameData.IRON: 200})

	await hold_key(KEY_B, 4)
	await until(func() -> bool: return Building.is_active(state),
		"build mode to open")

	# **A wall shows the route; a tower does not.** The line is for the things
	# whose whole job is traffic.
	await click_control("build_wall")
	await until(func() -> bool: return Building.selected(state) == &"wall",
		"the wall to be selected")

	Pathing.refresh(state)
	var lane := Vector2i(-1, -1)
	var spawn: Vector2i = Enemies.spawn_cells(state, 0)[0]
	var at := spawn
	for _step in 5:
		var next := Pathing.step_from(state, at)
		if next == at:
			break
		at = next
	if Farm.buildable(state, at):
		lane = at
	expect(lane != Vector2i(-1, -1), "there is a lane to hover over")
	if lane == Vector2i(-1, -1):
		await close_scene()
		_completed += 1
		return

	await move_mouse_to_cell(lane)
	await frames(3)
	var route := world.previewed_route()
	expect(not route.is_empty(),
		"holding a wall over the lane draws where they would go instead",
		str(route.size()))

	# It is a prediction, not a change: nothing is on the farm yet.
	expect(Farm.is_empty(state, lane),
		"and nothing has been built to find that out")
	var stone := Resources.amount(state, GameData.STONE)

	# **The route it shows is the route they take.** Put it down and compare.
	await click_cell(lane)
	await until(func() -> bool: return not Farm.is_empty(state, lane),
		"the wall to go down")
	expect(Resources.amount(state, GameData.STONE) < stone,
		"the wall is paid for now")
	Pathing.refresh(state)
	var real: Array = []
	var walk := spawn
	for _step in 120:
		var next := Pathing.step_from(state, walk)
		if next == walk:
			break
		real.append(next)
		walk = next
	expect(real == route,
		"and it is exactly the route the preview drew",
		"%d steps against %d" % [real.size(), route.size()])

	# **A tower gets no line**, because a player placing one is thinking about
	# range rather than about traffic.
	# Let the palette settle: placing the wall changed what is affordable, so
	# the rows are rebuilt on the next frame and a click aimed at a row that
	# is about to be replaced lands on whatever takes its place.
	await frames(4)
	await click_control("build_gun_tower")
	await until(func() -> bool: return Building.selected(state) == &"gun_tower",
		"the tower to be selected")
	await move_mouse_to_cell(lane + Vector2i(1, 1))
	await frames(3)
	expect(world.previewed_route().is_empty(),
		"holding a tower draws no route", str(world.previewed_route().size()))

	# **And closing build mode takes it away.**
	await click_control("build_wall")
	await move_mouse_to_cell(lane + Vector2i(2, 0))
	await frames(3)
	await hold_key(KEY_B, 4)
	await until(func() -> bool: return not Building.is_active(state),
		"build mode to close")
	await frames(3)
	expect(world.previewed_route().is_empty(),
		"the line goes with the palette", str(world.previewed_route().size()))

	await close_scene()
	_completed += 1     # last line: an abandoned case never gets here


## Put the pointer over a cell, the way a player moving the mouse would.
func move_mouse_to_cell(cell: Vector2i) -> void:
	var world: WorldView = require_control("WorldView")
	if world == null:
		return
	var size := float(GameData.TILE_SIZE)
	var middle := Vector2(cell) * size + Vector2(size, size) * 0.5
	var at := world.get_viewport_transform() * (world.get_global_transform()
		* middle)
	var ev := InputEventMouseMotion.new()
	ev.position = at
	ev.global_position = at
	Input.parse_input_event(ev)
	await process_frame


## 0053 - mending a wall at night, through the key that does it.
func _case_0053_repair() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	if driver == null:
		_completed += 1
		await close_scene()
		return

	var state := driver.state
	Resources.gain(state, {GameData.STONE: 200, GameData.WOOD: 200,
		GameData.FOOD: 200})

	# A wall the player can stand next to, and a night to mend it in.
	var spot := Vector2i(-1, -1)
	var stand := Vector2i(-1, -1)
	for y in range(2, Grid.HEIGHT - 2):
		for x in range(20, Grid.WIDTH - 2):
			var cell := Vector2i(x, y)
			var beside := cell + Vector2i(-1, 0)
			if Farm.buildable(state, cell) and Farm.walkable(state, beside):
				spot = cell
				stand = beside
				break
		if spot.x >= 0:
			break
	expect(spot.x >= 0, "there is somewhere to put a wall")
	if spot.x < 0:
		await close_scene()
		_completed += 1
		return

	Farm.place(state, spot, {"id": &"wall",
		"hp": int((GameData.DEFENCES[&"wall"] as Dictionary)["hp"])})
	Phases.begin_preparation(state)
	Sim.advance(state, GameData.PREPARATION_TICKS)
	expect(int(state["phase"]) == Phases.NIGHT, "it is night")

	Farm.damage(state, spot, 60)
	var hurt := int(Farm.occupant(state, spot).get("hp", 0))
	expect(Repair.needs_repair(state, spot), "the wall wants mending")

	_stand_at(state, stand, Player.EAST)
	expect(Player.target(state) == spot,
		"the player is facing it", str(Player.target(state)))
	expect(Interact.verb_at(state, spot) == &"repair",
		"and the cell offers to be mended",
		str(Interact.verb_at(state, spot)))

	# A wall is mended with stone since task 0057 - its own material, at a
	# share of what building it cost.
	var paid_in: StringName = GameData.sorted_names(
		Building.cost_of(&"wall").keys())[0]
	var food_before := Resources.amount(state, paid_in)

	# **The key that does everything else does this too.** No repair button,
	# no mode: stand in front of it and hold the same key you chop with.
	await hold_key(KEY_SPACE, 40)
	await frames(2)

	var mended := int(Farm.occupant(state, spot).get("hp", 0))
	expect(mended > hurt,
		"holding the interact key puts hit points back into the wall",
		"%d against %d" % [mended, hurt])
	# **What it cost, counting what is still on the slate.** A wall is four
	# hundredths of a stone a hit point since task 0057, so a short mend is
	# genuinely a debt rather than a payment, and asking the ledger alone
	# would be asking the wrong question.
	var owed := int(Repair.banked(state).get(paid_in, 0))
	var spent := (food_before - Resources.amount(state, paid_in)) * 100 + owed
	expect(spent > 0,
		"and it costs %s, banked or paid" % paid_in,
		"%d hundredths" % spent)

	# **Walking away stops it**, the same as every other job. Read from the
	# tick the step away lands on, not from the frame the key goes down: a
	# stroke the job was already due on a tick in between is the job finishing
	# what it had started before the sim heard about the key, and reading the
	# wall one frame early made this case fail about one run in three.
	await press_key(KEY_A, true)
	await until(func() -> bool: return not Player.is_busy(state),
		"the step away to reach the sim")
	var at_release := int(Farm.occupant(state, spot).get("hp", 0))
	await frames(5)
	await press_key(KEY_A, false)
	await frames(8)
	expect(not Player.is_busy(state),
		"stepping away gives up on the job")
	expect(int(Farm.occupant(state, spot).get("hp", 0)) == at_release,
		"and nothing more goes into the wall after that",
		str(Farm.occupant(state, spot).get("hp", 0)))

	await close_scene()
	_completed += 1     # last line: an abandoned case never gets here


## 0054 - the flare, off the key it lives on.
func _case_0054_ability() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	if driver == null:
		_completed += 1
		await close_scene()
		return

	var state := driver.state

	# **Not by day**, and the key says so by doing nothing.
	expect(int(state["phase"]) == Phases.DAY, "it starts as day")
	await tap_key(KEY_F)
	await frames(3)
	expect(Ability.flares_used(state) == 0,
		"pressing it in daylight does nothing",
		str(Ability.flares_used(state)))

	Phases.begin_preparation(state)
	Sim.advance(state, GameData.PREPARATION_TICKS)
	expect(int(state["phase"]) == Phases.NIGHT, "it is night")
	expect(Ability.ready(state), "and the flare is charged")

	# Something standing next to the player to be flared.
	var beside := Player.cell(state) + Vector2i(1, 0)
	if not Farm.walkable(state, beside):
		beside = Player.cell(state)
	var victim := Entities.spawn(state, &"walker", beside)
	Entities.set_hp(state, victim, 500)
	var hp_before := int(Entities.get_one(state, victim).get("hp", 0))

	await tap_key(KEY_F)
	await until(func() -> bool: return Ability.flares_used(state) > 0,
		"the flare to go off")
	expect(Ability.flares_used(state) == 1, "one press, one flare",
		str(Ability.flares_used(state)))
	expect(int(Entities.get_one(state, victim).get("hp", 0)) < hp_before,
		"and the thing beside the player is hurt by it",
		str(Entities.get_one(state, victim).get("hp", 0)))
	expect(Ability.is_slowed(state, victim), "and slowed")

	# **The player can see it.** The rules record where it went off, which is
	# all the view needs and all it is allowed to know.
	expect(Ability.flare_at(state) == [Player.cell(state).x,
		Player.cell(state).y],
		"the burst is recorded where the player is standing",
		str(Ability.flare_at(state)))

	# **Two in the same second are impossible**, through the key as well as
	# through the rule.
	var after := Ability.flares_used(state)
	for _i in 4:
		await tap_key(KEY_F)
	await frames(6)
	expect(Ability.flares_used(state) == after,
		"four more presses inside a second set off nothing",
		str(Ability.flares_used(state)))
	expect(not Ability.ready(state), "it is still waiting")
	expect(Ability.charge_percent(state) < 100,
		"and the ring the HUD draws is not full",
		str(Ability.charge_percent(state)))

	await close_scene()
	_completed += 1     # last line: an abandoned case never gets here


## 0055 - speed and skipping, off the keys they live on.
func _case_0055_speed() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	var hud: DayHud = require_control("DayHud")
	if driver == null or hud == null:
		_completed += 1
		await close_scene()
		return

	var state := driver.state
	# The speed read-out is the night HUD's own button since task 0056; the
	# skip line stays here, because skipping is not one of the three
	# controls `design.md` draws.
	var speed_line: Button = locate_control("SpeedButton") as Button
	var skip_line: Label = locate_control("SkipLine") as Label
	expect(speed_line != null and skip_line != null,
		"the speed control and the skip line both exist")
	expect(hud.driver != null,
		"and the HUD was handed the driver to work them with")

	# **Neither is up by day**, and neither key does anything then.
	await frames(2)
	expect(not speed_line.is_visible_in_tree(),
		"the speed control is down by day")
	expect(not skip_line.visible, "and so is the skip line")
	driver.set_speed(1)
	await tap_key(KEY_V)
	await frames(2)
	expect(driver.speed == 1, "V does nothing in daylight",
		str(driver.speed))
	# **The night's speed is the night's.** One chosen in the options by day,
	# or left over from last night, does not run the farm: it used to, and a
	# night at 4x was followed by a day at 4x.
	driver.set_speed(4)
	expect(driver.effective_speed() == 1,
		"a speed set by day leaves the day at one",
		str(driver.effective_speed()))
	Phases.begin_preparation(state)
	expect(driver.effective_speed() == 1,
		"and the build step too", str(driver.effective_speed()))
	Sim.advance(state, GameData.PREPARATION_TICKS)
	expect(driver.effective_speed() == 4,
		"and it takes hold when the night does",
		str(driver.effective_speed()))
	driver.set_speed(1)
	Phases.enter_result(state, true)
	(state["intent"] as Dictionary)["confirm_result"] = true
	Sim.advance(state, 2)
	expect(int(state["phase"]) == Phases.DAY, "back in daylight for the rest",
		Phases.name_of(int(state["phase"])))

	Phases.begin_preparation(state)
	Sim.advance(state, GameData.PREPARATION_TICKS)
	await frames(2)
	expect(int(state["phase"]) == Phases.NIGHT, "it is night")
	expect(speed_line.is_visible_in_tree() and skip_line.visible,
		"and after dark both are up")
	expect(speed_line.text.contains("1x"),
		"the speed control says what speed it is", speed_line.text)

	# **V cycles the table.**
	var seen: Array = [driver.speed]
	for _i in GameData.SPEEDS.size():
		await tap_key(KEY_V)
		await frames(2)
		if not seen.has(driver.speed):
			seen.append(driver.speed)
	expect(seen.size() == GameData.SPEEDS.size(),
		"V reaches every speed the table offers", str(seen))
	expect(driver.speed == 1, "and comes back round to one",
		str(driver.speed))

	# **Speed is never a changed tick rate.** Whatever it says, a tick is a
	# tick: forty ticks are forty ticks at 4x.
	driver.set_speed(4)
	await frames(2)
	expect(speed_line.text.contains("4x"),
		"the control says what it is doing", speed_line.text)
	var before := int(state["tick"])
	Sim.advance(state, 40)
	expect(int(state["tick"]) == before + 40,
		"forty ticks are forty ticks at any speed",
		str(int(state["tick"]) - before))

	# **K runs the rest of the night.**
	driver.set_speed(1)
	state["house_hp"] = GameData.HOUSE_HP
	await frames(2)
	expect(Sim.can_skip(state), "the house is healthy, so it may be skipped")
	expect(skip_line.text.contains("SKIP"),
		"and the line offers it", skip_line.text)
	await tap_key(KEY_K)
	await frames(3)
	expect(int(state["phase"]) != Phases.NIGHT,
		"pressing K ends the night", str(state["phase"]))

	# **And it is refused when the night is worth watching.**
	#
	# Skipping leaves the run on the result screen, so that has to be dealt
	# with before there is another night to refuse to skip.
	(state["intent"] as Dictionary)["confirm_result"] = true
	Sim.advance(state, 2)
	Phases.begin_preparation(state)
	Sim.advance(state, GameData.PREPARATION_TICKS)
	state["house_hp"] = 1
	await frames(2)
	expect(int(state["phase"]) == Phases.NIGHT, "another night")
	# **The key's words, not a word.** This looked for "watching", which task
	# 0110 shortened out of the sentence while moving it into the string
	# table - a check that breaks when somebody edits copy is a check about
	# the copy, and this one is about the button refusing.
	expect(skip_line.text.contains(I18n.t(&"WHY_HOUSE_LOW") % 1),
		"with the house nearly gone the line says why rather than offering",
		skip_line.text)
	var night_tick := int(state["night_tick"])
	await tap_key(KEY_K)
	await frames(3)
	expect(int(state["phase"]) == Phases.NIGHT,
		"pressing it anyway changes nothing", str(state["phase"]))
	# **Waited for rather than assumed.** Three frames is not a tick: the
	# driver turns real seconds into ticks, and on a fast enough loop three
	# frames can be less than one thirtieth of a second. This failed about
	# one run in three, which is the worst kind of failure - it was found
	# while adding something unrelated.
	await until(func() -> bool:
		return int(state["night_tick"]) > night_tick,
		"the night to tick on", 600)
	expect(int(state["night_tick"]) > night_tick,
		"and the night is still running", str(state["night_tick"]))

	# **Speed is remembered.** Four goes in, the scene closes, and the next
	# one opens at four.
	driver.set_speed(4)
	await close_scene()
	await open_scene(MAIN_SCENE)
	var again: SimDriver = require_control("SimDriver")
	expect(again != null and again.speed == 4,
		"a new scene opens at the speed the last one was left at",
		str(again.speed if again != null else -1))

	# Put it back, so this case leaves nothing behind for the next one.
	if again != null:
		again.set_speed(1)
	await close_scene()
	_completed += 1     # last line: an abandoned case never gets here


## 0056 - the night HUD, and all three of its controls pressed.
func _case_0056_night_hud() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	var hud: DayHud = require_control("DayHud")
	var night_hud: NightHud = require_control("NightHud")
	if driver == null or hud == null or night_hud == null:
		_completed += 1
		await close_scene()
		return

	var state := driver.state
	driver.set_speed(1)

	# **It is not up by day**, and the day HUD is.
	await frames(2)
	expect(not night_hud.visible, "the night HUD is down in daylight")
	expect(hud.shows_day(), "and the day's own chrome is up")

	Phases.begin_preparation(state)
	Sim.advance(state, GameData.PREPARATION_TICKS)
	await frames(2)
	expect(int(state["phase"]) == Phases.NIGHT, "it is night")
	expect(night_hud.visible, "the night HUD replaces it")
	expect(not hud.shows_day(), "and the day's chrome is gone")

	# **Every number on it.**
	var night_label: Label = locate_control("NightNumber") as Label
	var wave_label: Label = locate_control("WaveCounter") as Label
	var left_label: Label = locate_control("ZombiesLeft") as Label
	var house_text: Label = locate_control("HouseNumbers") as Label
	var house_bar: ColorRect = locate_control("HouseBar") as ColorRect
	expect(night_label != null and wave_label != null and left_label != null
		and house_text != null and house_bar != null,
		"which night, which wave, how many left and how the house is doing")
	expect(night_label.text.contains(str(int(state["night"]))),
		"the night number is the night", night_label.text)
	expect(wave_label.text.contains("/"),
		"the wave counter is a counter", wave_label.text)
	expect(house_text.text.contains(str(GameData.HOUSE_HP)),
		"and the house says both numbers", house_text.text)

	# **Readable at 480x270**: everything on it is inside the screen.
	for named in ["NightNumber", "WaveCounter", "ZombiesLeft",
			"HouseNumbers", "HouseBar", "NightBar", "RepairButton",
			"FlareButton", "SpeedButton"]:
		var ctl: Control = locate_control(named) as Control
		expect(ctl != null, "the HUD has a %s" % named)
		if ctl == null:
			continue
		var box := ctl.get_global_rect()
		expect(box.position.x >= 0.0 and box.position.y >= 0.0
			and box.end.x <= 480.0 and box.end.y <= 270.0,
			"%s is on the screen" % named, str(box))
		expect(ctl.get_global_rect().size.y <= 24.0,
			"%s did not grow a thirty-one pixel button box" % named,
			str(box.size))

	# **The house bar shrinks with the house, and goes red.**
	var whole := house_bar.size.x
	state["house_hp"] = GameData.HOUSE_HP / 2
	await frames(2)
	expect(house_bar.size.x < whole,
		"half a house is a shorter bar",
		"%f against %f" % [house_bar.size.x, whole])
	state["house_hp"] = maxi(GameData.HOUSE_HP
		* GameData.HOUSE_DANGER_PERCENT / 100 - 1, 1)
	await frames(2)
	var alarmed := ink(house_text)
	expect(alarmed.r > alarmed.g,
		"and a house in danger is red", str(alarmed))
	state["house_hp"] = GameData.HOUSE_HP

	# **All three controls, pressed.** The done-when.
	#
	# Repair first: park the player next to something broken so the control
	# is live, then click it and watch hit points go back.
	var spot := Vector2i(-1, -1)
	var stand := Vector2i(-1, -1)
	for y in range(3, Grid.HEIGHT - 3):
		for x in range(20, Grid.WIDTH - 3):
			var cell := Vector2i(x, y)
			if Farm.buildable(state, cell) 					and Farm.walkable(state, cell + Vector2i(-1, 0)):
				spot = cell
				stand = cell + Vector2i(-1, 0)
				break
		if spot.x >= 0:
			break
	expect(spot.x >= 0, "there is somewhere to put a wall")
	Farm.place(state, spot, {"id": &"wall",
		"hp": int((GameData.DEFENCES[&"wall"] as Dictionary)["hp"])})
	Farm.damage(state, spot, 60)
	Resources.gain(state, {GameData.FOOD: 200, GameData.WOOD: 200})
	_stand_at(state, stand, Player.EAST)
	await frames(2)

	var repair: Button = locate_control("RepairButton") as Button
	expect(not repair.disabled,
		"facing a broken wall, the repair control is live")
	var hurt := int(Farm.occupant(state, spot).get("hp", 0))
	await click_control("RepairButton")
	await until(func() -> bool:
		return int(Farm.occupant(state, spot).get("hp", 0)) > hurt,
		"the wall to be mended")
	expect(int(Farm.occupant(state, spot).get("hp", 0)) > hurt,
		"clicking it puts hit points back",
		str(Farm.occupant(state, spot).get("hp", 0)))

	# The flare, and it reports its own wait afterwards.
	var flare: Button = locate_control("FlareButton") as Button
	expect(Ability.ready(state), "the flare is charged")
	expect(not flare.disabled, "so the control is live")
	await click_control("FlareButton")
	await until(func() -> bool: return Ability.flares_used(state) > 0,
		"the flare to go off")
	expect(Ability.flares_used(state) == 1, "clicking it sets one off",
		str(Ability.flares_used(state)))
	await frames(2)
	expect(flare.disabled, "and then the control goes dead")
	expect(flare.text.contains("%"),
		"saying how far through the wait it is", flare.text)

	# And the speed.
	await click_control("SpeedButton")
	await frames(2)
	expect(driver.speed != 1, "clicking the speed control changes the speed",
		str(driver.speed))
	var shown: Button = locate_control("SpeedButton") as Button
	expect(shown.text.contains(str(driver.speed)),
		"and it says which", shown.text)
	driver.set_speed(1)

	# **A wave is announced before it arrives.**
	var warning: Label = locate_control("WaveWarning") as Label
	expect(warning != null, "there is a wave warning")
	var wave: Dictionary = state["wave"]
	wave["done"] = false
	wave["left"] = 0
	wave["wait"] = GameData.WAVE_WARNING_TICKS - 1
	await frames(2)
	expect(warning.visible, "with a wave seconds away it is up")
	expect(warning.text.contains("INCOMING"),
		"and it says so", warning.text)
	wave["wait"] = GameData.WAVE_WARNING_TICKS * 8
	await frames(2)
	expect(not warning.visible,
		"with one a long way off it is not - it is a warning, not furniture")

	await close_scene()
	_completed += 1     # last line: an abandoned case never gets here


## 0063 - the tech tree, opened and spent from.
func _case_0063_tech_tree() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	var panel: TechPanel = require_control("TechPanel")
	if driver == null or panel == null:
		_completed += 1
		await close_scene()
		return

	var state := driver.state
	Resources.gain(state, {GameData.TECH: 20})

	# **It is not up until it is asked for.**
	await frames(2)
	expect(not panel.is_open(), "the tree starts closed")
	await tap_key(KEY_T)
	await until(func() -> bool: return panel.is_open(), "the tree to open")
	expect(panel.is_open(), "T opens it")

	# **Everything on it is on the screen.** Twelve buttons and three column
	# headings at 480x270 is the tightest thing in the game, and a node that
	# hangs off the edge is a node nobody can buy.
	var first: StringName = Tech.nodes_of(&"production")[0]["id"]
	var second: StringName = Tech.nodes_of(&"production")[1]["id"]
	for row in Tech.tree():
		var id: StringName = (row as Dictionary)["id"]
		var button: Control = locate_control(
			"Tech_" + str(id).replace(" ", "_")) as Control
		expect(button != null, "the tree draws %s" % id)
		if button == null:
			continue
		var box := button.get_global_rect()
		expect(box.position.x >= 0.0 and box.position.y >= 0.0
			and box.end.x <= 480.0 and box.end.y <= 270.0,
			"and %s is on the screen" % id, str(box))

	# **Buying one.** The done-when.
	var had := Tech.held(state)
	var cost := int(Tech.node(first)["cost"])
	expect(not Tech.owns(state, first), "the first node is unbought")
	await click_control("Tech_" + str(first).replace(" ", "_"))
	await until(func() -> bool: return Tech.owns(state, first),
		"the node to be bought")
	expect(Tech.owns(state, first), "clicking a node buys it")
	expect(Tech.held(state) == had - cost,
		"for its price out of the purse", str(Tech.held(state)))

	# A node whose prerequisite is now owned becomes live; one already bought
	# does not.
	await frames(3)
	var bought: Button = locate_control(
		"Tech_" + str(first).replace(" ", "_")) as Button
	var next_one: Button = locate_control(
		"Tech_" + str(second).replace(" ", "_")) as Button
	expect(bought.disabled, "a node you own cannot be bought again")
	expect(not next_one.disabled,
		"and the one behind it has come alive", next_one.tooltip_text)

	# **Never during a wave.** The panel shuts itself when the night starts.
	Phases.begin_preparation(state)
	Sim.advance(state, GameData.PREPARATION_TICKS)
	await frames(3)
	expect(int(state["phase"]) == Phases.NIGHT, "it is night")
	expect(not panel.is_open(),
		"and the tree closes itself rather than sitting over a wave")
	await tap_key(KEY_T)
	await frames(3)
	expect(not panel.is_open(), "and will not open after dark")

	await close_scene()
	_completed += 1     # last line: an abandoned case never gets here


## 0069 - the records screen, opened and read.
func _case_0069_stats() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	var screen: StatsScreen = require_control("StatsScreen")
	if driver == null or screen == null:
		_completed += 1
		await close_scene()
		return

	var state := driver.state
	await frames(2)
	expect(not screen.is_open(), "the records start closed")

	await tap_key(KEY_R)
	await until(func() -> bool: return screen.is_open(), "the records to open")
	expect(screen.is_open(), "R opens them")

	# **Everything on it is on the screen.** The sixth of this family: a
	# `Label` sizes itself to its text whatever `custom_minimum_size` says,
	# and a row of numbers that runs off a 480x270 screen is a row nobody can
	# read. Tasks 0032, 0040, 0055, 0061 and 0063 are the other five.
	await frames(2)
	for row in ["nights", "killed", "gathered", "built", "lost", "best_night",
			"runs"]:
		for side in ["StatsName_", "StatsRun_", "StatsLife_"]:
			var label: Control = locate_control(side + row) as Control
			expect(label != null, "the records draw %s%s" % [side, row])
			if label == null:
				continue
			var box := label.get_global_rect()
			expect(box.position.x >= 0.0 and box.position.y >= 0.0
				and box.end.x <= 480.0 and box.end.y <= 270.0,
				"and %s%s is on the screen" % [side, row], str(box))

	# **It shows what the run has done.** Kill three and the number is three.
	var run_killed: Label = locate_control("StatsRun_killed") as Label
	expect(run_killed != null, "there is a kill count")
	Phases.begin_preparation(state)
	Sim.advance(state, GameData.PREPARATION_TICKS)
	var down := 0
	for _i in 3:
		var id := Enemies.spawn(state, &"walker", 0)
		if id > 0:
			Combat.hit(state, id, 9999)
			down += 1
	await until(func() -> bool:
		return run_killed != null and run_killed.text == str(down),
		"the kill count to catch up")
	expect(run_killed.text == str(down),
		"the screen shows what the run has killed", run_killed.text)

	# **It is read-only, so a wave does not take it away.** The tech tree
	# shuts itself at dusk because it cannot be spent after dark; there is
	# nothing here for a night to invalidate.
	expect(int(state["phase"]) == Phases.NIGHT, "it is night")
	expect(screen.is_open(), "and the records stay up through it")

	await tap_key(KEY_ESCAPE)
	await until(func() -> bool: return not screen.is_open(),
		"the records to close")
	expect(not screen.is_open(), "ESC closes them")
	await tap_key(KEY_R)
	await until(func() -> bool: return screen.is_open(),
		"the records to open after dark")
	expect(screen.is_open(), "and R opens them again, night or not")
	await tap_key(KEY_R)
	await until(func() -> bool: return not screen.is_open(),
		"the records to toggle shut")
	expect(not screen.is_open(), "and R closes them")

	await close_scene()
	_completed += 1     # last line: an abandoned case never gets here


## 0070 - playing on, past the authored ten.
func _case_0070_endless() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	var result: ResultScreen = require_control("ResultScreen")
	if driver == null or result == null:
		_completed += 1
		await close_scene()
		return

	var state := driver.state

	# **The second door is not there until the run has been beaten.** Task
	# 0070's "off the critical path: a menu option, not the default" is this
	# button: `BACK TO THE FARM` is what the screen does nine nights running,
	# and playing on is the extra one that only appears at the end.
	var play_on: Button = locate_control("PlayOnButton") as Button
	expect(play_on != null, "the play-on button exists")
	if play_on == null:
		await close_scene()
		_completed += 1
		return
	await frames(2)
	expect(not play_on.visible, "and is not offered before the run is over")

	# Beat the tenth night. The result screen reads the state, so putting the
	# state at the end of a beaten run is putting the screen at the ending.
	state["nights_won"] = GameData.MVP_NIGHTS
	state["night"] = GameData.MVP_NIGHTS
	expect(Run.is_over(state), "the run is over")
	Phases.begin_preparation(state)
	Sim.advance(state, GameData.PREPARATION_TICKS)
	for _t in 40000:
		if int(state["phase"]) != Phases.NIGHT:
			break
		Sim.advance(state, 1)
	await until(func() -> bool: return play_on != null and play_on.visible,
		"the ending to offer the second door")
	expect(play_on.visible, "a beaten run offers to play on")

	# **Clicking it puts the farm into night eleven**, which before task 0070
	# was a quiet farm with nothing authored to fight.
	var was := int(state["night"])
	await click_control("PlayOnButton")
	await until(func() -> bool: return Run.is_endless(driver.state),
		"the run to go endless")
	expect(Run.is_endless(driver.state), "clicking it carries the run on")
	expect(not Run.is_over(driver.state),
		"and the run stops being over", str(was))

	# And the night it walks into is generated rather than empty.
	var next_night := Phases.nights_won(driver.state) + 1
	expect(next_night > GameData.MVP_NIGHTS,
		"the next night is past the authored ten", str(next_night))
	expect(Waves.size_of(next_night, int(driver.state["seed"])) > 0,
		"and it has something to send",
		str(Waves.summary_of(next_night, int(driver.state["seed"]))))

	await close_scene()
	_completed += 1     # last line: an abandoned case never gets here


## 0071 - the same farm, lit twice.
func _case_0071_palettes() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	var view: WorldView = require_control("WorldView")
	var relight: Relight = require_control("Relight")
	if driver == null or view == null or relight == null:
		_completed += 1
		await close_scene()
		return

	var state := driver.state
	await frames(10)

	# **By day the shader is doing almost nothing**, which is the point: the
	# farm was drawn under this light and daylight exempts nothing.
	var by_day := relight.settings()
	expect(not by_day.is_empty(), "the relight layer has settings")
	expect(float(by_day["warm_keep"]) >= 0.99,
		"by day nothing is exempt from the light", str(by_day["warm_keep"]))
	expect(float(by_day["saturation"]) >= PaletteData.DAWN_SATURATION,
		"and the colour is left alone", str(by_day["saturation"]))

	# **The whole ramp goes over, not just the tint.** This is what a
	# `CanvasModulate` on its own could not do, and the whole of task 0071.
	await click_control("NightButton")
	await until(func() -> bool: return int(state["phase"]) != Phases.DAY,
		"the night to begin")

	# **Let the view notice the phase before skipping the fade.** `until()`
	# can return on the frame the phase changed and before `WorldView` has
	# processed it - and a `skip_transition()` in that gap is undone on the
	# next frame, because the view then sees a change it has not started a
	# fade for yet and starts one. Measured: the ramp sat at 1.9% of the way
	# into the night with the tint already reported as the night's.
	await frames(4)
	view.skip_transition()
	await until(func() -> bool:
		return not view.is_transitioning(), "the fade to land")
	await frames(2)

	var by_night := relight.settings()
	expect(float(by_night["saturation"])
		< float(by_day["saturation"]) - 0.05,
		"after dark the colour is drained",
		"%s against %s" % [str(by_night["saturation"]),
			str(by_day["saturation"])])
	var lift: Vector3 = by_night["lift"]
	expect(lift.z > lift.x and lift.z > lift.y,
		"and lifted towards purple, which a multiply cannot do", str(lift))
	expect(float(by_night["warm_keep"]) >= 0.999,
		"and pale materials are never mistaken for semantic fire sources",
		str(by_night["warm_keep"]))

	# **The tint the shader is given is the tint the light is on.** The
	# shader divides it back out to find what the palette painted, so a pair
	# that drifted apart would be a night that quietly stopped exempting
	# anything.
	var light: CanvasModulate = view.find_child("Light", true, false)
	var tint: Vector3 = by_night["tint"]
	expect(light != null
		and absf(tint.x - light.color.r) < 0.01
		and absf(tint.y - light.color.g) < 0.01
		and absf(tint.z - light.color.b) < 0.01,
		"the shader is told the same tint the light is wearing",
		"%s against %s" % [str(tint), str(light.color if light else null)])

	# **Nothing but the light changed.** The done-when, and the point of the
	# whole design.
	#
	# The first version asked whether the occupant count and the wood were the
	# same six frames later. **That is the wrong question**: a night
	# legitimately takes structures apart, so it asserted that nothing happens
	# during a night, which is false by design - and it only caught the
	# relight by accident anyway.
	#
	# It was rewritten after `verify.py` reported one failed input case that
	# four later runs did not reproduce. Which assert failed was never
	# captured, so **this is not a diagnosis** - the old assert may or may not
	# have been the one. It was replaced because it was measuring the weather
	# and not the claim, and the version below cannot depend on timing at all,
	# which closes that door whether or not it was the open one.
	#
	# The claim is that **relighting the farm changes nothing about the
	# farm**, so this relights it, hard, and asks the state hash. No `await`
	# between the two readings, so the tick cannot move underneath the
	# question and there is nothing left for the answer to depend on.
	var before := State.hash_of(state)
	relight.apply(Color(0.1, 0.1, 0.9), Color(0.5, 0.0, 0.5), 0.1, 0.1, 0.3)
	relight.apply(Color(1.9, 1.9, 0.2), Color(0.0, 0.4, 0.0), 1.0, 0.2, 0.01)
	expect(State.hash_of(state) == before,
		"relighting the farm changes nothing about the farm",
		"%d against %d" % [State.hash_of(state), before])
	# Put it back, so the rest of the case sees the light the phase asks for.
	view.skip_transition()

	# And the game was running the whole time it was being relit.
	var tick_before := int(state["tick"])
	await frames(6)
	expect(int(state["tick"]) > tick_before,
		"while the game carries on running underneath it",
		"%d against %d" % [int(state["tick"]), tick_before])

	# **The HUD is not relit.** It sits above the layer on purpose: a health
	# bar that went purple after dark is a health bar nobody can read at the
	# moment it matters.
	var rect: Control = relight.find_child("RelightRect", true, false)
	var hud: Control = locate_control("NightHud") as Control
	expect(rect != null, "the relight draws over the world")
	if rect != null and hud != null:
		expect(rect.get_parent() != hud.get_parent(),
			"and is not inside the HUD it must not touch")

	await close_scene()
	_completed += 1     # last line: an abandoned case never gets here


## 0072 - the tileset, as the running game wires it.
##
## The rules of which tile goes where are asserted in `headless_check`, where
## they are pure functions. What can only be checked here is the wiring: that
## the edges have a layer of their own over the terrain, that the farm
## actually gets some, and that the pond is set up to move.
func _case_0072_tileset() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	var view: WorldView = require_control("WorldView")
	if driver == null or view == null:
		_completed += 1
		await close_scene()
		return

	await frames(4)
	var terrain: TileMapLayer = view.find_child("Terrain", true, false)
	var edges: TileMapLayer = view.find_child("TerrainEdges", true, false)
	expect(terrain != null, "the farm has a terrain layer")
	expect(edges != null, "and the edges have one of their own")
	if terrain == null or edges == null:
		await close_scene()
		_completed += 1
		return

	# **Over the terrain, not under it.** A cell holds one tile, so an edge
	# that shared the layer would replace the ground it is meant to soften.
	expect(edges.get_index() > terrain.get_index(),
		"the edges are drawn over the ground",
		"%d against %d" % [edges.get_index(), terrain.get_index()])
	expect(edges.tile_set == terrain.tile_set,
		"and off the same atlas, so there is one texture and not two")

	expect(terrain.get_used_cells().size() == Grid.CELLS,
		"every cell of the farm has ground under it",
		str(terrain.get_used_cells().size()))
	var laid := edges.get_used_cells().size()
	expect(laid > 0 and laid < Grid.CELLS,
		"and some of them are edged, but not all - grass is the background",
		str(laid))

	# **The pond moves.** Three frames on one tile, which is what stops a
	# pond being a painted pond; the durations are what stop it flickering.
	var source: TileSetAtlasSource = terrain.tile_set.get_source(0)
	var water := Vector2i(0, WorldView.ROW_WATER)
	expect(source != null and source.has_tile(water), "the water is a tile")
	if source != null and source.has_tile(water):
		expect(source.get_tile_animation_frames_count(water) == 3,
			"with three frames",
			str(source.get_tile_animation_frames_count(water)))
		expect(source.get_tile_animation_frame_duration(water, 0) > 0.25,
			"and slow enough not to shimmer",
			str(source.get_tile_animation_frame_duration(water, 0)))
		# The frames come off the tiles to its right, and those must not be
		# tiles themselves or Godot takes them back.
		for frame in [1, 2]:
			expect(not source.has_tile(Vector2i(frame, WorldView.ROW_WATER)),
				"and frame %d is not a tile in its own right" % frame)

	# A water cell shows the animated tile and not the still one in row 0.
	var bytes: PackedByteArray = driver.state["terrain"]
	var found := false
	for idx in Grid.CELLS:
		if int(bytes[idx]) != Farm.Terrain.WATER:
			continue
		found = true
		expect(terrain.get_cell_atlas_coords(Grid.cell(idx)) == water,
			"and the pond is drawn with it",
			str(terrain.get_cell_atlas_coords(Grid.cell(idx))))
		break
	expect(found, "the farm has a pond to check")

	await close_scene()
	_completed += 1     # last line: an abandoned case never gets here


## 0073 - the farmer, walking and working.
func _case_0073_player_art() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	var view: PlayerView = require_control("PlayerView")
	if driver == null or view == null:
		_completed += 1
		await close_scene()
		return

	var state := driver.state
	await frames(6)

	var body: Sprite2D = view.find_child("Body", true, false)
	var shadow: Sprite2D = view.find_child("Shadow", true, false)
	expect(body != null and body.texture != null,
		"the farmer is drawn from a cut frame")
	expect(shadow != null and shadow.texture != null,
		"and casts a shadow, so they are standing on the farm")
	if body == null:
		await close_scene()
		_completed += 1
		return

	# **Standing still is an idle.**
	expect(str(view.playing()).begins_with("idle"),
		"a farmer nobody is moving stands still", str(view.playing()))

	# **Walking west, and east is the same art mirrored.** The only facing
	# evidence a screenshot could give, asked of the node instead.
	# **Asked while the key is down.** `hold_key()` lets go before it returns,
	# and a farmer who has stopped walking is standing still - which is what
	# the first version of this asserted against and got `idle_west` for.
	await press_key(KEY_A, true)
	await frames(8)
	expect(str(view.playing()) == "walk_west",
		"walking left plays the west walk", str(view.playing()))
	expect(not view.flipped(), "which is the art as it was drawn")
	await press_key(KEY_A, false)
	await frames(3)

	await press_key(KEY_D, true)
	await frames(8)
	expect(str(view.playing()) == "walk_east",
		"walking right uses the registered east animation", str(view.playing()))
	expect(not view.flipped(), "east locomotion already owns its facing and pivot")
	await press_key(KEY_D, false)
	await frames(3)

	# **Eight directions.** Two keys at once walk the diagonal drawing, and
	# letting go stands still in that same diagonal.
	for pair in [[KEY_S, KEY_D, &"south_east"], [KEY_S, KEY_A, &"south_west"],
			[KEY_W, KEY_D, &"north_east"], [KEY_W, KEY_A, &"north_west"]]:
		await press_key(pair[0], true)
		await press_key(pair[1], true)
		await frames(8)
		expect(view.playing() == StringName("walk_%s" % pair[2]) and not view.flipped(),
			"two keys walk the %s drawing" % pair[2], str(view.playing()))
		await release_keys([pair[0], pair[1]])
		await frames(3)
		expect(view.playing() == StringName("idle_%s" % pair[2]),
			"and letting go stands still facing %s" % pair[2], str(view.playing()))

	# Run is a named held presentation action, not a simulation speed command:
	# the same walk, played faster.
	await press_key(KEY_SHIFT, true)
	await frames(3)
	expect(str(view.playing()).begins_with("idle_"), "Shift alone does not run in place")
	for motion_key in [KEY_A, KEY_D, KEY_W, KEY_S]:
		await press_key(motion_key, true)
		await frames(8)
		var walk_name := StringName("walk_%s" % PlayerArt.FACINGS[Player.facing(state)][0])
		expect(view.playing() == walk_name and not view.flipped(),
			"Shift plus movement selects the correct running direction", str(view.playing()))
		expect(is_equal_approx(view.frame_seconds(), PlayerArt.RUN_FRAME_SECONDS),
			"and plays it at the running pace", str(view.frame_seconds()))
		expect(body.texture != null and body.texture.resource_path.begins_with(PlayerArt.DIR + String(walk_name)),
			"The actual running view resolves promoted runtime textures")
		await press_key(motion_key, false)
		await frames(3)
	await press_key(KEY_D, true)
	await frames(4)
	await press_key(KEY_SHIFT, false)
	await frames(4)
	expect(view.playing() == &"walk_east" and view.frame_seconds() > PlayerArt.RUN_FRAME_SECONDS,
		"Releasing Shift returns to walking while movement stays held")
	await press_key(KEY_D, false)
	await frames(3)

	# **The animation is the state's.** Put an action on the player through
	# the rules and the view has to follow it without being told.
	# The action record is written straight onto the state, which is what
	# `Player._begin()` does and what the view reads. Walking the farmer to a
	# tree and holding SPACE would be testing `Interact`, which has its own
	# case; what is under test here is that the drawing follows the state.
	var here := Player.cell(state)
	(state["player"] as Dictionary)["action"] = {
		"verb": &"chop", "cell": [here.x, here.y],
		"left": 90, "total": 90,
	}
	await until(func() -> bool: return str(view.playing()) == "chop",
		"the chop to start playing")
	expect(str(view.playing()) == "chop",
		"a farmer the rules say is chopping is drawn chopping",
		str(view.playing()))

	# **And walking away gives it up**, which is the rule rather than my
	# guess: `Player.tick()` calls `_stop()` the moment a direction is held,
	# because "half a tree does not stay half chopped in some invisible
	# ledger". The first version of this asserted the opposite - that a verb
	# beats a held key - and the suite said otherwise, which is the right way
	# round for a test and a rule to disagree.
	await press_key(KEY_A, true)
	await frames(8)
	expect(Player.is_busy(state) == false,
		"holding a direction gives up the work", str(Player.is_busy(state)))
	expect(str(view.playing()) == "walk_west",
		"and the farmer is drawn walking, not chopping on the spot",
		str(view.playing()))
	await press_key(KEY_A, false)
	await frames(3)

	# When the work ends the drawing goes back.
	(state["player"] as Dictionary)["action"] = {}
	await until(func() -> bool:
		return not str(view.playing()).begins_with("chop"),
		"the chop to end")
	expect(not str(view.playing()).begins_with("chop"),
		"and stops when the work does", str(view.playing()))

	await close_scene()
	_completed += 1     # last line: an abandoned case never gets here


## 0074 - a mixed wave, drawn.
##
## The shapes are asserted in `headless_check`, where they are pixels. What
## can only be checked here is that the running game finds them: a pose whose
## file the view cannot resolve falls back to a flat purple block, which looks
## like a bug and is one, and four of the five were doing exactly that before
## `_texture_for()` learned that `walker_walk_b` belongs to a walker.
func _case_0074_zombie_art() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	var view: WorldView = require_control("WorldView")
	if driver == null or view == null:
		_completed += 1
		await close_scene()
		return

	var state := driver.state
	Phases.begin_preparation(state)
	Sim.advance(state, GameData.PREPARATION_TICKS)
	await frames(3)

	var kinds := GameData.sorted_names(GameData.ENEMIES.keys())
	for kind in kinds:
		expect(Enemies.spawn(state, StringName(kind), 0) > 0,
			"a %s walks out of the dark" % kind)
	await frames(6)

	# **Every one of them is drawn from its own art.** The flat block the view
	# falls back to is generated at runtime and has no `resource_path`, which
	# is how a fallback is told from a file.
	var actors: Node2D = view.find_child("Actors", true, false)
	expect(actors != null, "the actors are on their own layer")
	var drawn := 0
	var fallen_back := 0
	if actors != null:
		for child in actors.get_children():
			var sprite := child as Sprite2D
			if sprite == null or sprite.texture == null:
				continue
			if str(sprite.texture.resource_path).contains("/enemies/"):
				drawn += 1
			elif str(sprite.texture.resource_path) == "":
				fallen_back += 1
	expect(drawn >= kinds.size(),
		"every enemy on the field is drawn from the enemy art",
		"%d drawn, %d on the fallback block" % [drawn, fallen_back])
	expect(fallen_back == 0, "and none of them is a purple block",
		str(fallen_back))

	# **The pose follows the rules.** `winding_at` is the rules' own word for
	# "about to hit something", and the Giant has a telegraph of its own.
	var ids := Entities.ids(state)
	var giant_id := 0
	for id in ids:
		var one := Entities.get_one(state, int(id))
		if StringName(one["kind"]) == &"giant":
			giant_id = int(id)
			break
	expect(giant_id > 0, "the Giant is on the field")
	if giant_id > 0:
		var one := Entities.get_one(state, giant_id)
		# The real fixed-tick observer selects one of four authored steps.
		var walking := str(view._pose_of(one))
		expect(walking in ["giant", "giant_walk_0", "giant_walk_1", "giant_walk_2", "giant_walk_3"],
			"a Giant that is walking is drawn walking", walking)
		# Let the existing rules begin a valid tell at the house. A stale
		# distant winding_at value alone must not invent an attack pose.
		var house: Array = state["house_cell"]
		one["pos"] = [int(house[0]) * Player.SUBTILE, int(house[1]) * Player.SUBTILE]
		one["winding_at"] = -1
		one["chewing"] = -1
		one["chew_wait"] = 0
		view._enemy_motion.clear()
		view.before_tick(state)
		state["tick"] = int(state["tick"]) + 1
		Enemies.tick(state)
		view.after_tick(state)
		expect(Enemies.is_winding(state, giant_id) and str(view._pose_of(one)) == "giant_windup_0",
			"and one that is winding up is drawn winding up",
			str(view._pose_of(one)))

	await close_scene()
	_completed += 1     # last line: an abandoned case never gets here


## 0076 - the lights, and the promise that they are only lights.
func _case_0076_lighting() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	var lights: Lighting = require_control("Lighting")
	if driver == null or lights == null:
		_completed += 1
		await close_scene()
		return

	var state := driver.state
	await frames(4)

	# **Over the night ramp, under the HUD.** A light under the ramp is a
	# light the ramp tints blue, and a light over the HUD is a health bar
	# nobody can read.
	var layer := lights.get_parent() as CanvasLayer
	var relight: Relight = require_control("Relight")
	var ui: CanvasLayer = locate_control("UI") as CanvasLayer
	expect(layer != null, "the lights have a layer of their own")
	if layer != null and relight != null:
		expect(layer.get_index() > relight.get_index(),
			"drawn after the night ramp",
			"%d against %d" % [layer.get_index(), relight.get_index()])
	if layer != null and ui != null:
		expect(layer.get_index() < ui.get_index(),
			"and before the HUD",
			"%d against %d" % [layer.get_index(), ui.get_index()])

	# **Turning lighting off changes nothing about the outcome of a night.**
	# Task 0076's own done-when, and the way to ask it is the state hash: run
	# the same night from the same seed twice, once lit and once not.
	var lit_hash: int = await _night_with_lights(driver, lights, Lighting.FULL)
	var dark_hash: int = await _night_with_lights(driver, lights, Lighting.OFF)
	expect(lit_hash == dark_hash,
		"a night played with the lights off comes out identical",
		"%d against %d" % [lit_hash, dark_hash])
	var steady_hash: int = await _night_with_lights(driver, lights, Lighting.STEADY)
	expect(steady_hash == lit_hash,
		"and so does one played on the middle setting", str(steady_hash))

	# The dial exists and holds what it is given.
	lights.set_quality(Lighting.OFF)
	expect(lights.quality() == Lighting.OFF, "the quality dial turns off")
	lights.set_quality(99)
	expect(lights.quality() == Lighting.FULL,
		"and cannot be turned past the top", str(lights.quality()))

	await close_scene()
	_completed += 1     # last line: an abandoned case never gets here


## Play the opening of a night at one quality and hand back the state hash.
##
## The simulation is advanced by hand rather than waited for, so this measures
## the rules and not the frame rate - and the lights are given frames to draw
## in between, which is the whole point: if drawing them touched anything,
## this is where it would show.
##
## **The driver is stopped, which it was not until task 0105.** It is a live
## node: left running, it advances the state on its own during every awaited
## frame, by however many ticks the wall clock says have gone by. So the two
## runs being compared got the hand-driven ticks *plus* a different number of
## timed ones each, and the case passed when the two happened to match. It
## did match, for twenty-eight tasks, until a node added to the run scene
## moved the frame time enough to stop it matching. A determinism check that
## can fail on frame timing is worse than no determinism check.
func _night_with_lights(driver: SimDriver, lights: Lighting,
		level: int) -> int:
	driver.start(760076)
	driver.running = false
	var state := driver.state
	lights.set_quality(level)
	Resources.gain(state, {GameData.WOOD: 400, GameData.IRON: 400,
		GameData.STONE: 400})
	var at := Player.cell(state)
	for i in 4:
		Building.place(state, &"gun_tower", Vector2i(at.x + 2 + i * 2, at.y + 1))
	Phases.begin_preparation(state)
	Sim.advance(state, GameData.PREPARATION_TICKS)
	for chunk in 20:
		Sim.advance(state, 30)
		await frames(1)
	return State.hash_of(state)


## 0077 - particles, and the promise that they are only particles.
func _case_0077_particles() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	var bits: Particles = require_control("Particles")
	if driver == null or bits == null:
		_completed += 1
		await close_scene()
		return

	await frames(4)
	expect(bits.cap() > 0, "there is a cap", str(bits.cap()))

	# **Turning them off does not change the outcome of a night.** Task
	# 0077's done-when, asked the way task 0076 asks its own: play the same
	# night from the same seed at three densities and compare the state hash.
	var full: int = await _night_with_particles(driver, bits, 1.0)
	var none: int = await _night_with_particles(driver, bits, 0.0)
	expect(full == none,
		"a night played with the particles off comes out identical",
		"%d against %d" % [full, none])
	var half: int = await _night_with_particles(driver, bits, 0.5)
	expect(half == full, "and so does one played at half density", str(half))

	# **The cap is a cap.** Fill it well past the ceiling and count.
	bits.set_density(1.0)
	bits.set_cap(40)
	var state := driver.state
	Phases.begin_preparation(state)
	Sim.advance(state, GameData.PREPARATION_TICKS)
	for _one in 60:
		Enemies.spawn(state, &"walker", 0)
	for _f in 30:
		if int(state["phase"]) == Phases.NIGHT:
			Sim.advance(state, 2)
		await frames(1)
		expect(bits.live() <= bits.cap(),
			"never more alive than the cap allows",
			"%d of %d" % [bits.live(), bits.cap()])

	# And zero means zero, which is what the accessibility setting buys.
	#
	# **Long enough for the longest-lived one.** Smoke lasts 1.6 seconds
	# times up to 1.3, which is about a hundred and twenty-five frames; the
	# first version waited forty and then asserted that thirteen puffs of
	# smoke should already have gone out.
	bits.set_density(0.0)
	await until(func() -> bool: return bits.live() == 0,
		"the last particle to go out")
	expect(bits.live() == 0,
		"at zero density they all go out and none come back",
		str(bits.live()))

	await close_scene()
	_completed += 1     # last line: an abandoned case never gets here


## Play the opening of a night at one density and hand back the state hash.
func _night_with_particles(driver: SimDriver, bits: Particles,
		density: float) -> int:
	driver.start(770077)
	# Stopped, for the reason written out over `_night_with_lights`.
	driver.running = false
	var state := driver.state
	bits.set_density(density)
	Resources.gain(state, {GameData.WOOD: 400, GameData.IRON: 400})
	var at := Player.cell(state)
	for i in 4:
		Building.place(state, &"gun_tower", Vector2i(at.x + 2 + i * 2, at.y + 1))
	Phases.begin_preparation(state)
	Sim.advance(state, GameData.PREPARATION_TICKS)
	for chunk in 20:
		Sim.advance(state, 30)
		await frames(1)
	return State.hash_of(state)


## 0078 - the moment the game is named after.
func _case_0078_transition() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	var view: WorldView = require_control("WorldView")
	var moment: Transition = require_control("Transition")
	if driver == null or view == null or moment == null:
		_completed += 1
		await close_scene()
		return

	var state := driver.state
	await frames(6)
	expect(view.transition_seconds() > 0.0,
		"the change has a length", str(view.transition_seconds()))
	expect(not view.is_transitioning(),
		"and is not running before anything has changed")

	# **It never blocks the simulation.** The tick has to keep moving while
	# the world is changing, which is the whole reason skipping is free.
	await click_control("NightButton")
	await until(func() -> bool: return int(state["phase"]) != Phases.DAY,
		"the night to begin")
	await frames(3)
	expect(view.is_transitioning(), "the change is running",
		str(view.transition_progress()))
	expect(view.going_dark(), "and it is going the dark way")
	var was := int(state["tick"])
	await frames(6)
	expect(int(state["tick"]) > was,
		"the game runs through the change rather than waiting for it",
		"%d against %d" % [int(state["tick"]), was])

	# It finishes on its own.
	await until(func() -> bool: return not view.is_transitioning(),
		"the change to end")
	expect(view.transition_progress() >= 1.0,
		"and ends at the end", str(view.transition_progress()))

	# **Skipping lands in exactly the same state as watching.** The done-when.
	# Two nights from one seed: one watched, one skipped at every change.
	var watched: int = await _night_through_changes(driver, view, false)
	var skipped: int = await _night_through_changes(driver, view, true)
	expect(watched == skipped,
		"skipping the change lands in exactly the state watching does",
		"%d against %d" % [watched, skipped])

	await close_scene()
	_completed += 1     # last line: an abandoned case never gets here


## Play a night, either watching every change or skipping it, and hand back
## the state hash. The simulation is advanced by hand at a fixed rate, so the
## only difference between the two runs is what the view was doing.
func _night_through_changes(driver: SimDriver, view: WorldView,
		skip: bool) -> int:
	# Fixed manual ticks must not also receive wall-clock ticks between frames.
	# Use Main's reset so every view observes this same fresh state dictionary.
	var processing := driver.is_processing()
	driver.set_process(false)
	_scene.begin_run(780078)
	var state := driver.state
	Resources.gain(state, {GameData.WOOD: 400, GameData.IRON: 400})
	var at := Player.cell(state)
	for i in 4:
		Building.place(state, &"gun_tower", Vector2i(at.x + 2 + i * 2, at.y + 1))
	Phases.begin_preparation(state)
	for chunk in 24:
		Sim.advance(state, 30)
		if skip:
			view.skip_transition()
		await frames(1)
	expect(int(state["tick"])==720, "Transition comparison advances exactly its 720 manual ticks", str(state["tick"]))
	var result := State.hash_of(state)
	driver.set_process(processing)
	return result
func _case_0081_theme() -> void:
	await open_scene(MAIN_SCENE)
	await frames(4)
	if _scene == null:
		_completed += 1
		await close_scene()
		return

	# **Every screen in the game, asked what it is wearing.** This is the
	# done-when a `grep` cannot answer: a screen can have no overrides left
	# and still be the odd one out, because it sits somewhere the theme never
	# reaches. Before this task the debug overlay was exactly that.
	var controls: Array = []
	_gather(_scene, controls)
	expect(controls.size() > 40, "the tree has screens in it",
		"%d controls" % controls.size())

	# **Either of the game's two faces.** The heading is the same design at
	# twice the size and is a second `FontFile`, so "wears the game's letters"
	# means one of these two and not one of them alone - which is what the
	# first version of this assert said, and the wave announcement caught it.
	var game_font := UiKit.font()
	var faces := [game_font, UiKit.heading_font()]
	var wrong_font: Array = []
	var flat_panels: Array = []
	for node in controls:
		var control: Control = node
		if control is Label or control is Button:
			if not faces.has(control.get_theme_font(&"font")):
				wrong_font.append(str(control.name))
		if control is PanelContainer or control is Panel:
			if not (control.get_theme_stylebox(&"panel") is StyleBoxTexture):
				flat_panels.append(str(control.name))
	expect(wrong_font.is_empty(),
		"every label and button in the game wears the game's own letters",
		"%d do not: %s" % [wrong_font.size(), str(wrong_font.slice(0, 4))])
	expect(flat_panels.is_empty(),
		"and every panel is the kit's drawn frame, not a flat box of its own",
		"%d are not: %s" % [flat_panels.size(), str(flat_panels.slice(0, 4))])

	# **The overlay is in that count.** It is on a `CanvasLayer` of its own
	# outside the UI one, which is how it stayed in Godot's grey through the
	# five tasks that each thought they had dressed the game.
	var readout: Control = require_control("Readout")
	if readout != null:
		expect(readout.get_theme_font(&"font") == game_font,
			"the debug overlay wears it too, on its own layer")
	var overlay_panel: Control = require_control("Panel")
	if overlay_panel != null:
		expect(overlay_panel.get_theme_stylebox(&"panel") is StyleBoxTexture,
			"and its frame is the kit's quiet one")

	# **Focus is a state you can see.** Requirement three of the task, and the
	# reason the two screens that used to hide Godot's ring behind an empty
	# box could not be left alone: a keyboard with no visible focus is a
	# keyboard nobody can use.
	var button: Button = require_control("NightButton")
	if button != null:
		expect(button.focus_mode != Control.FOCUS_NONE,
			"the night button can take focus")
		var ring := button.get_theme_stylebox(&"focus")
		var normal := button.get_theme_stylebox(&"normal")
		expect(ring is StyleBoxTexture,
			"and its focus is a drawn ring", str(ring))
		expect(ring != normal,
			"which is not the same box as its resting state")
		expect(button.get_theme_stylebox(&"disabled") != normal,
			"and a disabled button is a different box from a live one")
		button.grab_focus()
		await frames(2)
		expect(button.has_focus(), "the keyboard can land on it")

	# **Each one is the size it was told to be.** The theme has to be on the
	# tree before a screen builds against it: a Control's `size` is clamped up
	# to the minimum when it is set and never clamped back down, so a button
	# built before the theme landed keeps Godot's thirty-one pixels for the
	# rest of the run. Three night controls did exactly that until `Main`
	# moved the dressing into `_enter_tree`.
	for named in ["RepairButton", "FlareButton", "SpeedButton"]:
		var control: Control = require_control(named)
		if control == null:
			continue
		expect(control.size.y <= 20.0,
			"%s is the height it was given, not the theme's" % named,
			str(control.size))
		expect(control.get_global_rect().end.y <= 270.0,
			"and %s is on the screen" % named,
			str(control.get_global_rect()))

	await close_scene()
	_completed += 1     # last line: an abandoned case never gets here


## Every Control under a node, in tree order.
func _gather(node: Node, into: Array) -> void:
	if node is Control:
		into.append(node)
	for child in node.get_children():
		_gather(child, into)
func _case_0082_shots() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	if driver == null:
		_completed += 1
		await close_scene()
		return
	var state := driver.state

	# **No two labels in a row may run together.** The result screen printed
	# "still up19 untouched" for a task and a half with 5177 asserts passing
	# over it, because the left column's text was wider than the column and
	# the containers have no separation. Found by looking at task 0082's
	# result shot; asserted here so the next one is found by the suite.
	#
	# **The farm is defended and the night is survived on purpose.** The
	# first version of this lost the night, which prints "house 0/100, 0
	# still up" - twenty-three characters in a column a hundred and fifty
	# wide, nowhere near the edge. It passed with the bug planted, twice.
	# Long strings need a long night behind them.
	Resources.gain(state, {GameData.WOOD: 900, GameData.IRON: 900,
		GameData.STONE: 900, GameData.OIL: 200, GameData.GUNPOWDER: 120,
		GameData.INCENDIARY: 60})
	var here := Player.cell(state)
	var put := 0
	for y in range(here.y - 2, here.y + 6):
		for x in range(here.x + 3, here.x + 13):
			if put >= 12:
				break
			var id: StringName = &"gun_tower" if put % 2 else &"auto_crossbow"
			if Building.place(state, id, Vector2i(x, y)):
				put += 1
		if put >= 12:
			break
	expect(put >= 8, "the farm has something defending it", "%d up" % put)
	Phases.begin_preparation(state)
	Sim.advance(state, GameData.PREPARATION_TICKS + 1)
	Sim.skip_night(state)
	await frames(6)
	expect(int(state["phase"]) == Phases.RESULT, "the result screen is up",
		Phases.name_of(int(state["phase"])))

	var result: Control = require_control("ResultScreen")
	if result != null:
		# **The case cannot be allowed to go vacuous.** If no row is anywhere
		# near its column's edge, the crowding check is asking a question
		# with no stakes and would keep passing through a rewrite of the
		# panel. This says so out loud rather than letting it rot quietly.
		# A hundred and twenty is four fifths of the hundred-and-fifty pixel
		# column. The widest row is a hundred and forty-six, which is the
		# fixed string nearly filling it - so an overrun really is three
		# characters away and the check below has something to catch. The
		# first threshold here was a hundred and fifty and failed, because
		# only the *buggy* string was ever that wide.
		expect(_widest_row(result) >= 120.0,
			"a row nearly fills its column, so the check below has stakes",
			"widest is %.0fpx" % _widest_row(result))
		var collisions := _crowded_rows(result)
		expect(collisions.is_empty(),
			"no two labels in a row have their text run together",
			"%d: %s" % [collisions.size(), str(collisions.slice(0, 3))])

	# And the same question of every other screen that lays out in rows, so
	# this is a rule about the game rather than about one panel.
	for named in ["InventoryPanel", "ShopPanel", "WorkshopPanel"]:
		var screen: Control = require_control(named)
		if screen == null:
			continue
		screen.visible = true
		await frames(4)
		var found := _crowded_rows(screen)
		expect(found.is_empty(),
			"and none on the %s either" % named,
			"%d: %s" % [found.size(), str(found.slice(0, 3))])

	await close_scene()
	_completed += 1     # last line: an abandoned case never gets here


## The widest run of text in any row under this node.
func _widest_row(root: Control) -> float:
	var widest := 0.0
	var stack: Array = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		for child in node.get_children():
			stack.append(child)
		var label := node as Label
		if label == null or not label.is_visible_in_tree():
			continue
		if not (label.get_parent() is HBoxContainer):
			continue
		widest = maxf(widest, _ink_width(label, label.text))
	return widest


## Pairs of labels in one row whose text runs together.
##
## **Not an overlap.** The first version of this asked whether the two rects
## intersected, planted the bug it was written for, and passed: two labels
## printed as "still up19 untouched" are *adjacent*, not overlapping, and
## `Rect2.intersects` is false for touching rectangles. A test that cannot
## fail on the bug it was written for is worth less than no test, because it
## also says the area is covered.
##
## What it asks now is where the **ink** ends and where the next ink begins.
## A label is at least as wide as its column, so the gap between two rects
## says nothing; the gap between the last pixel of one string and the first
## pixel of the next is the thing a reader sees. Leading spaces count as
## space, because several rows pad inside the string rather than with a
## separation.
##
## Only horizontal containers, which promise to lay their children out along
## a line. A label deliberately drawn over a `ColorRect` is not this.
func _crowded_rows(root: Control) -> Array:
	var out: Array = []
	var stack: Array = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		for child in node.get_children():
			stack.append(child)
		if not (node is HBoxContainer):
			continue
		var previous: Label = null
		for child in node.get_children():
			var label := child as Label
			if label == null or not label.is_visible_in_tree():
				continue
			if label.text.strip_edges() == "":
				continue
			if previous != null:
				var gap := _ink_gap(previous, label)
				if gap < MIN_INK_GAP:
					out.append("%s meets %s with %.0fpx"
						% [previous.name, label.name, gap])
			previous = label
	return out


## Pixels between the last ink of one label and the first ink of the next.
func _ink_gap(left: Label, right: Label) -> float:
	var ends := left.get_global_rect().position.x + _ink_width(left, left.text)
	var starts := right.get_global_rect().position.x \
		+ _ink_width(right, _leading_space(right.text))
	return starts - ends


func _ink_width(label: Label, text: String) -> float:
	var face := label.get_theme_font(&"font")
	if face == null or text == "":
		return 0.0
	return face.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1,
		label.get_theme_font_size(&"font_size")).x


func _leading_space(text: String) -> String:
	var n := 0
	while n < text.length() and text[n] == " ":
		n += 1
	return text.substr(0, n)
func _case_0083_audio() -> void:
	await open_scene(MAIN_SCENE)

	# **The autoload, not one built by hand.** The headless group covers the
	# rules with an `Audio.new()`; what needs a running tree is the part where
	# a voice really starts and really reports itself busy, because that is
	# what the polyphony cap is counting.
	var audio: Node = root.get_node_or_null(^"Audio")
	expect(audio != null, "the Audio autoload is up")
	var settings: Node = root.get_node_or_null(^"Settings")
	expect(settings != null, "and so is Settings")
	if audio == null or settings == null:
		_completed += 1
		await close_scene()
		return

	# **Cleared with no frame in between.** Task 0084 put an `Sfx` node in the
	# scene that watches the day and plays things; a frame between clearing
	# the pool and measuring it is a frame in which the farm can make a noise
	# of its own, and this case would fail once in a while for a reason that
	# has nothing to do with it. Nothing else runs between these lines.
	await frames(2)
	audio.stop_all()
	audio.forget_counts()
	expect(audio.voices_playing() == 0, "nothing is playing to begin with",
		"%d voices" % audio.voices_playing())

	# **Twenty shots on one tick make one sound.** The done-when, asked of a
	# live pool: not "the counter says one" but "one voice is in the air".
	var tone := _a_tone()
	audio.add(&"sfx/check_tone", tone)
	for i in 20:
		audio.play(&"sfx/check_tone")
	expect(audio.voices_playing() == 1,
		"twenty shots on one frame put one voice in the air, not twenty",
		"%d playing" % audio.voices_playing())
	expect(audio.started() == 1 and audio.deduped() == 19,
		"counted as one started and nineteen folded in",
		"%d started, %d deduped" % [audio.started(), audio.deduped()])

	# **And the cap holds when they are all different sounds**, which the
	# dedupe cannot help with. A night is a shot, an impact, a groan and a
	# death all at once, many times over.
	await frames(2)
	audio.stop_all()
	audio.forget_counts()
	var many: int = audio.voice_count() * 3
	for i in many:
		var id := StringName("sfx/check_%d" % i)
		audio.add(id, tone)
		audio.play(id)
	expect(audio.started() == audio.voice_count(),
		"a hundred different sounds at once take the pool and no more",
		"%d started of %d asked, cap %d"
		% [audio.started(), many, audio.voice_count()])
	expect(audio.dropped() == many - audio.voice_count(),
		"and the rest are dropped rather than stealing a voice mid-sound",
		"%d dropped" % audio.dropped())
	expect(audio.voices_playing() <= audio.voice_count(),
		"nothing is in the air that the pool did not hand out",
		"%d playing" % audio.voices_playing())

	# **Master at zero silences everything including music.** Through the real
	# setting, because the done-when is about what a player does, not about
	# what `apply_volumes` does when called by hand.
	var master_index := AudioServer.get_bus_index("Master")
	var music_index := AudioServer.get_bus_index("Music")
	expect(master_index >= 0 and music_index >= 0, "both buses are there")
	var was: float = settings.get_float(&"audio/master")
	settings.set_value(&"audio/master", 0.0, false)
	await frames(2)
	expect(AudioServer.is_bus_mute(master_index),
		"master at zero mutes the Master bus")
	expect(String(AudioServer.get_bus_send(music_index)) == "Master",
		"and Music sends to Master, so the music goes with it")
	settings.set_value(&"audio/master", was, false)
	await frames(2)
	expect(not AudioServer.is_bus_mute(master_index),
		"and putting it back brings the sound back")

	# The mute flag takes the same route rather than muting four buses.
	var was_muted: bool = settings.get_bool(&"audio/muted")
	settings.set_value(&"audio/muted", true, false)
	await frames(2)
	expect(AudioServer.is_bus_mute(master_index),
		"the mute flag silences Master too")
	settings.set_value(&"audio/muted", was_muted, false)
	await frames(2)
	expect(not AudioServer.is_bus_mute(master_index), "and unmutes it")

	audio.stop_all()
	audio.forget_counts()
	await close_scene()
	_completed += 1     # last line: an abandoned case never gets here


## A quarter second of a sine. There are no sound files until task 0084, and
## a pool with nothing to put in it cannot be asked how many it holds.
func _a_tone() -> AudioStreamWAV:
	var rate := 22050
	var samples := rate / 2
	var bytes := PackedByteArray()
	bytes.resize(samples * 2)
	for i in samples:
		bytes.encode_s16(i * 2,
			int(sin(TAU * 440.0 * float(i) / float(rate)) * 12000.0))
	var tone := AudioStreamWAV.new()
	tone.format = AudioStreamWAV.FORMAT_16_BITS
	tone.mix_rate = rate
	tone.data = bytes
	return tone
func _case_0084_day_sounds() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	var audio: Node = root.get_node_or_null(^"Audio")
	if driver == null or audio == null:
		expect(audio != null, "the Audio autoload is up for the day sounds")
		_completed += 1
		await close_scene()
		return
	var state := driver.state

	# Stand beside a tree, the same way case 0015 does.
	var tree := Vector2i(-1, -1)
	var beside := Vector2i(-1, -1)
	for candidate in Farm.cells_with(state, &"tree"):
		var spot := _walkable_neighbour(state, candidate as Vector2i)
		if spot != Vector2i(-1, -1):
			tree = candidate
			beside = spot
			break
	expect(beside != Vector2i(-1, -1), "there is a tree to stand beside")
	if beside == Vector2i(-1, -1):
		_completed += 1
		await close_scene()
		return

	# **The clock is driven by hand.** A chop is three seconds of simulated
	# time and this suite runs its frames as fast as the loop goes, so waiting
	# for the driver would be thousands of frames. Advancing two ticks a frame
	# keeps `Sfx` sampling the cycle many times over, which is the thing being
	# tested - it works the finish out from two consecutive samples.
	driver.running = false
	await frames(2)
	var who: Dictionary = state["player"]
	who["pos"] = [beside.x * Player.SUBTILE + Player.SUBTILE / 2,
		beside.y * Player.SUBTILE + Player.SUBTILE / 2]
	who["facing"] = _facing_from(beside, tree)
	await frames(2)
	expect(Interact.verb_at(state, tree) == &"chop", "and it offers chopping")

	audio.stop_all()
	audio.forget_counts()
	await press_key(KEY_SPACE, true)
	await frames(2)

	# **A whole cycle makes a chop.** `Sfx` has no event to listen to: it works
	# out that a cycle finished from `left + tick`, which is the tick the cycle
	# is due on and does not move while it runs.
	var heard := false
	for i in 80:
		Sim.advance(state, 2)
		await frames(1)
		if String(audio.last_played()) == "sfx/chop":
			heard = true
			break
	expect(heard, "chopping a tree makes a chopping sound",
		"last was '%s' after %d ticks"
		% [audio.last_played(), int(state["tick"])])
	await press_key(KEY_SPACE, false)
	await frames(2)

	# **Walking away part way makes nothing.** An action that vanished with
	# ticks still on it was interrupted, and the arithmetic knows the
	# difference - without it, giving up on half a tree would sound exactly
	# like felling one.
	await press_key(KEY_SPACE, true)
	await frames(2)
	Sim.advance(state, 4)
	await frames(2)
	var action: Dictionary = who["action"]
	expect(not action.is_empty(), "a fresh swing is under way", str(action))
	var due := int(state["tick"]) + int(action.get("left", 0))
	expect(int(state["tick"]) < due - 10,
		"and it is nowhere near done",
		"tick %d, due %d" % [int(state["tick"]), due])
	await press_key(KEY_SPACE, false)

	audio.stop_all()
	audio.forget_counts()
	await press_key(KEY_W, true)
	for i in 10:
		Sim.advance(state, 2)
		await frames(1)
	await press_key(KEY_W, false)
	await frames(2)
	expect((who["action"] as Dictionary).is_empty(),
		"walking away gives the swing up", str(who["action"]))
	expect(audio.started() == 0,
		"and an abandoned swing makes no sound at all",
		"%d started, last '%s'" % [audio.started(), audio.last_played()])

	driver.running = true
	audio.stop_all()
	await close_scene()
	_completed += 1     # last line: an abandoned case never gets here
func _case_0085_night_sounds() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	var audio: Node = root.get_node_or_null(^"Audio")
	var sfx: Sfx = require_control("Sfx")
	if driver == null or audio == null or sfx == null:
		expect(sfx != null, "the Sfx node is in the scene")
		_completed += 1
		await close_scene()
		return
	var state := driver.state

	driver.running = false
	await frames(2)
	Resources.gain(state, {GameData.WOOD: 900, GameData.IRON: 900,
		GameData.STONE: 900, GameData.GUNPOWDER: 200})
	var here := Player.cell(state)
	var put := 0
	for y in range(here.y - 2, here.y + 5):
		for x in range(here.x + 2, here.x + 9):
			if put >= 4:
				break
			if Building.place(state, &"gun_tower", Vector2i(x, y)):
				put += 1
		if put >= 4:
			break
	expect(put >= 2, "there are guns on the farm", "%d up" % put)
	Phases.begin_preparation(state)
	Sim.advance(state, GameData.PREPARATION_TICKS + 1)
	await frames(3)
	expect(int(state["phase"]) == Phases.NIGHT, "and it is night",
		Phases.name_of(int(state["phase"])))

	# **Fifty zombies are not fifty voices.** The done-when, asked of the
	# thing that decides it rather than counted off a stretch of frames: the
	# crowd amounts to one entry per *sort* of thing, so ten times the
	# zombies is exactly the same number of voices.
	for i in 5:
		Enemies.spawn(state, &"walker", i % GameData.SPAWNS.size())
	await frames(2)
	var few: int = sfx.nearest_by_kind().size()
	expect(few == 1, "five walkers are one voice", "%d voices" % few)
	for i in 45:
		Enemies.spawn(state, &"walker", i % GameData.SPAWNS.size())
	await frames(2)
	var crowd := Entities.count(state)
	expect(crowd >= 40, "there really is a crowd out there",
		"%d bodies" % crowd)
	var many: int = sfx.nearest_by_kind().size()
	expect(many == few,
		"and fifty walkers are still one voice, not fifty",
		"%d bodies making %d voices" % [crowd, many])

	# Different sorts do get their own, which is the other half of it - a
	# crowd is meant to be a chord rather than either a wall or a monotone.
	Enemies.spawn(state, &"runner", 0)
	Enemies.spawn(state, &"tank", 1)
	await frames(2)
	expect(sfx.nearest_by_kind().size() == 3,
		"three sorts of thing are three voices",
		"%d" % sfx.nearest_by_kind().size())

	# **The house being hit is heard.** The most important sound in the game,
	# and the one that must never be missed.
	audio.stop_all()
	audio.forget_counts()
	state["house_hp"] = int(state["house_hp"]) - 10
	await frames(3)
	expect(audio.plays_of(&"sfx/house_hit") >= 1,
		"the house taking damage makes the alarm",
		"last was '%s'" % audio.last_played())

	# **A gun firing makes a gun's sound**, read off the reload counter going
	# up rather than guessed from a projectile.
	audio.forget_counts()
	var fired := false
	for i in 90:
		Sim.advance(state, 2)
		await frames(1)
		if audio.plays_of(&"sfx/shot_gun") > 0:
			fired = true
			break
	expect(fired, "a gun tower firing makes a gunshot",
		"%d shots fired by the rules" % Towers.shots_fired(state))

	driver.running = true
	audio.stop_all()
	await close_scene()
	_completed += 1     # last line: an abandoned case never gets here
func _case_0086_music() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	var view: WorldView = require_control("WorldView")
	var music: Music = require_control("Music")
	var audio: Node = root.get_node_or_null(^"Audio")
	if driver == null or view == null or music == null or audio == null:
		expect(music != null, "the Music node is in the scene")
		_completed += 1
		await close_scene()
		return
	var state := driver.state

	# **One number, not two.** The done-when is that the crossfade lands with
	# the switch of reality; the only way to be sure is for the length to be
	# the transition's own, read from the view rather than typed again.
	expect(is_equal_approx(music.fade_seconds(), view.transition_seconds()),
		"the crossfade is exactly as long as the transition",
		"%.2f against %.2f" % [music.fade_seconds(),
			view.transition_seconds()])

	await frames(6)
	expect(String(audio.music_playing()) == "music/farm",
		"the day plays the farm's music",
		"'%s'" % audio.music_playing())
	expect(String(audio.layer_playing()) == "",
		"and nothing urgent is over the top of it")

	# **They land together.** Both the screen and the deck are driven by the
	# same delta, so rather than timing either of them this waits for the
	# transition to finish and then asks whether the music has too. If the
	# fade were longer the old piece would still be audible; if it were
	# shorter it would have finished early and the swap would have been heard
	# before the screen showed it.
	await click_control("NightButton")
	await until(func() -> bool: return int(state["phase"]) != Phases.DAY,
		"the night to begin")
	await frames(2)
	expect(String(audio.music_playing()) == "music/night",
		"switching reality asks for the night's music",
		"'%s'" % audio.music_playing())
	var mid_high: float = maxf(audio.music_level(0), audio.music_level(1))
	var mid_low: float = minf(audio.music_level(0), audio.music_level(1))
	expect(mid_high < 0.99 and mid_low > 0.0 or view.transition_seconds() <= 0.0,
		"and part way through, both pieces are sounding at once",
		"%.2f and %.2f" % [mid_high, mid_low])

	await until(func() -> bool: return not view.is_transitioning(),
		"the change of reality to end", 900)
	await frames(4)
	var high: float = maxf(audio.music_level(0), audio.music_level(1))
	var low: float = minf(audio.music_level(0), audio.music_level(1))
	expect(high > 0.9,
		"when the screen has finished changing, the night's music is up",
		"%.2f" % high)
	expect(low < 0.1,
		"and the farm's has gone",
		"%.2f" % low)

	# **The urgent layer arrives on the last wave, and not before.**
	#
	# Into the night proper first: clicking the button lands in PREPARATION,
	# which is twenty seconds long and has no wave table yet - the first
	# version of this asked a night that had not started and got `[0, 0]`,
	# then set the wave index to zero and wondered why nothing was urgent.
	expect(String(audio.layer_playing()) == "",
		"the first wave is not the urgent one",
		"'%s'" % audio.layer_playing())
	Sim.advance(state, GameData.PREPARATION_TICKS + 2)
	await frames(4)
	expect(int(state["phase"]) == Phases.NIGHT, "the wave is actually coming",
		Phases.name_of(int(state["phase"])))
	var table := Waves.progress(state)
	expect(int(table[1]) > 0, "and tonight has waves in its table",
		str(table))
	var wave: Dictionary = state["wave"]
	wave["index"] = maxi(int(table[1]) - 1, 0)
	await frames(4)
	expect(String(audio.layer_playing()) == "music/night_intensity",
		"the last wave brings the urgent layer in",
		"'%s' on wave %s" % [audio.layer_playing(),
			str(Waves.progress(state))])

	# And it goes again when the night does.
	Phases.enter_result(state, true)
	await frames(4)
	expect(String(audio.layer_playing()) == "",
		"and it goes when the night is over",
		"'%s'" % audio.layer_playing())
	expect(String(audio.music_playing()) == "music/night",
		"while the result screen keeps the night in the air",
		"'%s'" % audio.music_playing())

	await close_scene()
	_completed += 1     # last line: an abandoned case never gets here
func _case_0087_ambience() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	var view: WorldView = require_control("WorldView")
	var bed: Ambience = require_control("Ambience")
	var audio: Node = root.get_node_or_null(^"Audio")
	if driver == null or view == null or bed == null or audio == null:
		expect(bed != null, "the Ambience node is in the scene")
		_completed += 1
		await close_scene()
		return
	var state := driver.state

	await frames(6)
	expect(String(audio.bed_playing()) == "ambience/day_bed",
		"the day has birds under it",
		"'%s'" % audio.bed_playing())

	# **The bed turns over with the sky**, on the same cue the music does.
	await click_control("NightButton")
	await until(func() -> bool: return int(state["phase"]) != Phases.DAY,
		"the night to begin")
	await frames(2)
	expect(String(audio.bed_playing()) == "ambience/night_bed",
		"and switching reality asks for the night's",
		"'%s'" % audio.bed_playing())
	await until(func() -> bool: return not view.is_transitioning(),
		"the change of reality to end", 900)
	await frames(4)

	# **It is on its own bus**, which is what lets it be turned down alone.
	var ambience_bus := AudioServer.get_bus_index("Ambience")
	var music_bus := AudioServer.get_bus_index("Music")
	expect(ambience_bus >= 0 and ambience_bus != music_bus,
		"the bed has a bus of its own",
		"%d against %d" % [ambience_bus, music_bus])

	# **It ducks under the house being hit.** The done-when says the bed may
	# never mask it; this is the whole chain - `Sfx` notices the damage,
	# `Audio.duck` drops the bus, and the bus is measurably quieter.
	audio.stop_all()
	audio.forget_counts()
	await frames(2)
	var resting := AudioServer.get_bus_volume_db(ambience_bus)
	expect(is_equal_approx(audio.duck_gain(), 1.0),
		"nothing is ducking the bed to begin with",
		"%.2f" % audio.duck_gain())

	state["house_hp"] = int(state["house_hp"]) - 10
	await frames(3)
	expect(audio.plays_of(&"sfx/house_hit") >= 1,
		"the house takes a hit", "last '%s'" % audio.last_played())
	expect(audio.duck_gain() < 1.0,
		"and the bed gets out of the way of it",
		"%.2f" % audio.duck_gain())
	var ducked := AudioServer.get_bus_volume_db(ambience_bus)
	expect(ducked < resting - 3.0,
		"the ambience bus is measurably quieter while the alarm sounds",
		"%.1fdB against %.1fdB" % [ducked, resting])

	# A second hit while the first is still ducking extends it rather than
	# starting over, so a house taking three blows does not pump.
	state["house_hp"] = int(state["house_hp"]) - 10
	await frames(3)
	expect(audio.duck_gain() < 1.0, "a second hit keeps it out of the way",
		"%.2f" % audio.duck_gain())

	audio.stop_all()
	await close_scene()
	_completed += 1     # last line: an abandoned case never gets here
func _case_0088_juice() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	var view: WorldView = require_control("WorldView")
	var juice: Juice = require_control("Juice")
	var settings: Node = root.get_node_or_null(^"Settings")
	if driver == null or view == null or juice == null or settings == null:
		expect(juice != null, "the Juice node is in the scene")
		_completed += 1
		await close_scene()
		return

	# **Hit stop does not desynchronise the simulation - proved with the
	# hash.** The done-when in so many words.
	#
	# A hold stops the driver for a fraction of a second. It does not touch
	# the tick rate, so the ticks that were going to run still run, at the
	# same rate, a moment later - and the simulation counts in ticks and not
	# in seconds. So a run that was held part way and a run that was not
	# reach the same state at the same tick, and the state hash is exactly
	# the thing that says so.
	var control := State.create(880088)
	Sim.advance(control, 400)
	var expected := State.hash_of(control)

	# **`begin_run`, not `driver.start`.** `SimDriver.start` replaces the state
	# dictionary, and every screen is still holding the old one until
	# somebody hands them the new one - which is the whole reason task 0082
	# pulled `begin_run` out of `Main._ready`. Calling `start` here left
	# `Juice` watching a farm that nothing was happening on, and the damage
	# numbers never appeared because there was no damage where it was
	# looking.
	_scene.begin_run(880088)
	await frames(2)
	var held := driver.state
	Sim.advance(held, 200)
	driver.hold(0.4)
	expect(driver.holding(), "the world is stopped")
	var at_hold := int(held["tick"])
	await frames(6)
	expect(int(held["tick"]) == at_hold,
		"and no tick runs while it is",
		"%d against %d" % [int(held["tick"]), at_hold])
	await until(func() -> bool: return not driver.holding(),
		"the hold to end", 900)
	Sim.advance(held, 400 - int(held["tick"]))
	expect(int(held["tick"]) == 400, "both runs reach the same tick",
		str(int(held["tick"])))
	expect(State.hash_of(held) == expected,
		"a run that was held hashes the same as one that was not",
		"%d against %d" % [State.hash_of(held), expected])

	# **A crowded wave does not spawn a thousand labels.** Sixty zombies all
	# hurt at once, and the pool is the pool.
	driver.running = false
	await frames(2)
	Phases.begin_preparation(held)
	Sim.advance(held, GameData.PREPARATION_TICKS + 1)
	await frames(2)
	for i in 60:
		Enemies.spawn(held, &"walker", i % GameData.SPAWNS.size())
	await frames(3)
	var crowd := Entities.count(held)
	expect(crowd >= 50, "there is a crowd to hurt", "%d" % crowd)
	for id in Entities.ids(held):
		Combat.hit(held, int(id), 3, GameData.DAMAGE_IMPACT)
	# Past the gathering window, so everything that is going to show has.
	await frames(4)
	await until(func() -> bool: return juice.waiting_to_show() == 0,
		"the gathered hits to come out", 600)
	expect(juice.numbers_showing() <= Juice.MAX_NUMBERS,
		"sixty hurt zombies do not make sixty labels",
		"%d showing, cap %d" % [juice.numbers_showing(), Juice.MAX_NUMBERS])

	# The batching itself is asked in `headless_check`, where `gather` and
	# `ripen` can be driven directly. At the frame rate this suite runs at,
	# three hits in a row land in the same frame and become one drop in hit
	# points - so a live test cannot tell gathering from not gathering, and
	# the one written here first passed with the gathering removed.

	# **Turned off, the game still reads.** The shake first: zero means the
	# camera does not move at all, not that it moves less.
	var was_shake: float = settings.get_float(&"a11y/screen_shake")
	settings.set_value(&"a11y/screen_shake", 0.0, false)
	view.shake(40.0)
	await frames(4)
	var camera: Camera2D = view.get_node("Camera")
	expect(camera.offset == Vector2.ZERO,
		"with the shake off the camera does not move at all",
		str(camera.offset))

	# And with it on, it moves - but never past the cap.
	settings.set_value(&"a11y/screen_shake", 1.0, false)
	view.shake(80.0)
	var moved := false
	var worst := 0.0
	for i in 12:
		await frames(1)
		worst = maxf(worst, maxf(absf(camera.offset.x), absf(camera.offset.y)))
		if camera.offset != Vector2.ZERO:
			moved = true
	expect(moved, "with it on, the camera does move")
	expect(worst <= WorldView.SHAKE_CAP + 0.001,
		"and never further than the cap, whatever is asked for",
		"%.1f against %.1f" % [worst, WorldView.SHAKE_CAP])
	settings.set_value(&"a11y/screen_shake", was_shake, false)

	# The numbers, off.
	var was_numbers: bool = settings.get_bool(&"video/damage_numbers")
	settings.set_value(&"video/damage_numbers", false, false)
	await frames(3)
	for id in Entities.ids(held):
		Combat.hit(held, int(id), 3, GameData.DAMAGE_IMPACT)
	await frames(30)
	expect(juice.numbers_showing() == 0 and juice.waiting_to_show() == 0,
		"with the numbers off, none appear at all",
		"%d showing, %d waiting"
		% [juice.numbers_showing(), juice.waiting_to_show()])
	settings.set_value(&"video/damage_numbers", was_numbers, false)

	driver.running = true
	await close_scene()
	_completed += 1     # last line: an abandoned case never gets here
func _case_0089_tooltips() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	var tip: Tooltip = require_control("Tooltip")
	if driver == null or tip == null:
		expect(tip != null, "the Tooltip node is in the scene")
		_completed += 1
		await close_scene()
		return
	var state := driver.state

	# **Every row in the five panels the task names carries a key**, and
	# every key that is carried resolves to something worth reading. Walked
	# over the live tree rather than taken on trust from the wiring.
	# The tech tree's buttons exist whether or not its panel is up, so the
	# count below does not need it open - and opening it would give one of
	# them focus, which beats hover and would make the next part describe a
	# tech node while the cursor sat on a shop row. That is the design
	# working; it was still five minutes of wondering why wood was called
	# "true sights".
	Shop.open(state)
	var inventory: InventoryPanel = require_control("InventoryPanel")
	if inventory != null:
		inventory.visible = true
	await frames(6)
	root.gui_release_focus()

	# **Counted, then put away.** The inventory sits over the middle of the
	# screen, so leaving it up meant the cursor landed on an inventory row
	# while the test thought it was pointing at a shop one - and the wood row
	# explained iron.
	var described := 0
	var mute: Array = []
	var stack: Array = [_scene]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		for child in node.get_children():
			stack.append(child)
		if not node.has_meta(&"describes"):
			continue
		described += 1
		if Describe.of(StringName(node.get_meta(&"describes"))).is_empty():
			mute.append("%s -> %s" % [node.name, node.get_meta(&"describes")])
	expect(described >= 20,
		"the panels on screen have a lot of explaining marked on them",
		"%d marked" % described)
	expect(mute.is_empty(),
		"and every key on every one of them says something",
		"%d silent: %s" % [mute.size(), str(mute.slice(0, 3))])
	if inventory != null:
		inventory.visible = false
	await frames(2)

	# **Hovering explains, after a pause.** The pause is the requirement, so
	# it is asserted both ways round: nothing at once, something shortly.
	var row: Control = require_control("sell_wood")
	if row != null:
		await _hover(row)
		expect(String(tip.showing()) == "",
			"nothing is explained the instant the cursor arrives",
			"'%s'" % tip.showing())
		await until(func() -> bool: return String(tip.showing()) != "",
			"the tooltip to appear", 900)
		var under: Control = root.gui_get_hovered_control()
		expect(String(tip.showing()) == "resource:wood",
			"and then the wood row explains wood",
			"'%s'; cursor at %s, row at %s, under the cursor is %s"
			% [tip.showing(), root.get_mouse_position(),
				row.get_global_rect(),
				under.name if under != null else "nothing"])
		expect(tip.text_showing().contains("sells for"),
			"with what it fetches in it", tip.text_showing())

		# **And no pause moving to the next.** One frame is enough: a
		# tooltip that is already up follows the cursor.
		var other: Control = require_control("sell_stone")
		if other != null:
			await _hover(other)
			await frames(2)
			expect(String(tip.showing()) == "resource:stone",
				"moving to the next row swaps at once, with no second wait",
				"'%s'" % tip.showing())

	# **It never leaves the screen**, asked of the panel that is actually up.
	var screen := Rect2(Vector2.ZERO, Vector2(480.0, 270.0))
	var box := tip.panel_rect()
	expect(screen.encloses(box),
		"the panel is inside the screen",
		"%s in %s" % [box, screen])

	# **Keyboard focus explains the same thing as hover.** A player on a pad
	# or a keyboard is told what a player with a mouse is told.
	Shop.close(state)
	var tech: TechPanel = require_control("TechPanel")
	if tech != null:
		tech.open()
	await frames(3)
	var node_button: Control = require_control("Tech_sharp_tools")
	if node_button != null:
		node_button.grab_focus()
		await until(func() -> bool:
			return String(tip.showing()).begins_with("tech:"),
			"the focused tech node to explain itself", 900)
		expect(String(tip.showing()) == "tech:sharp tools",
			"tabbing to a tech node explains that node",
			"'%s'" % tip.showing())
		expect(tip.text_showing().contains("costs"),
			"with what it costs in it", tip.text_showing())
		var focused_box := tip.panel_rect()
		expect(screen.encloses(focused_box),
			"and that panel is on the screen too",
			"%s" % focused_box)

	# Leave nothing for the next case: no focus, no open panel, no cursor
	# parked over anything.
	root.gui_release_focus()
	if tech != null:
		tech.close()
	await frames(2)
	await close_scene()
	_completed += 1     # last line: an abandoned case never gets here


## Put the cursor over the middle of a control.
func _hover(control: Control) -> void:
	# **No `Input.warp_mouse`.** The GUI is driven by the pushed event, in
	# canvas coordinates, which is what `click_control` already does. Warping
	# the real cursor as well put it in window coordinates - three times
	# larger on a 1440x810 window - and made the failure message report a
	# position nothing was ever tested at.
	var at := control.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = at
	motion.global_position = at
	root.push_input(motion)
	await frames(2)
func _case_0090_log() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	var panel: LogPanel = require_control("LogPanel")
	if driver == null or panel == null:
		expect(panel != null, "the LogPanel is in the scene")
		_completed += 1
		await close_scene()
		return
	var state := driver.state

	driver.running = false
	await frames(2)
	expect(panel.lines_showing() == 0,
		"a quiet farm says nothing at all",
		"%d lines" % panel.lines_showing())

	# **A night at four times speed is followable from the log.** The
	# done-when, asked by playing one: prepare, fight, and read what the log
	# said about it afterwards.
	Resources.gain(state, {GameData.WOOD: 900, GameData.IRON: 900,
		GameData.STONE: 900, GameData.GUNPOWDER: 200})
	var here := Player.cell(state)
	var put := 0
	for y in range(here.y - 2, here.y + 6):
		for x in range(here.x + 3, here.x + 12):
			if put >= 6:
				break
			if Building.place(state, &"gun_tower", Vector2i(x, y)):
				put += 1
		if put >= 6:
			break
	Phases.begin_preparation(state)
	Sim.advance(state, GameData.PREPARATION_TICKS + 2)
	await frames(3)
	expect(int(state["phase"]) == Phases.NIGHT, "the night has begun",
		Phases.name_of(int(state["phase"])))

	var saw: Dictionary = {}
	for i in 240:
		Sim.advance(state, 12)          # four times speed, near enough
		await frames(1)
		for one in (state["events"] as Array):
			saw[StringName((one as Dictionary)["kind"])] = true
		if int(state["phase"]) != Phases.NIGHT:
			break

	expect(saw.has(&"night_began"),
		"the log said the night began",
		str(GameData.sorted_names(saw.keys())))
	expect(saw.has(&"wave_began"),
		"and that a wave was coming", str(GameData.sorted_names(saw.keys())))
	expect(saw.size() >= 3,
		"and enough else to follow what happened",
		"%d kinds: %s" % [saw.size(), str(GameData.sorted_names(saw.keys()))])

	# **It holds a bounded number of entries.** The other done-when, asked of
	# a night that has actually been fought rather than of a loop.
	expect((state["events"] as Array).size() <= Events.CAP,
		"and the record never grew past its cap",
		"%d of %d" % [(state["events"] as Array).size(), Events.CAP])

	# **The lines fade when nothing is happening**, so the farm is never
	# covered by a log nobody is reading.
	#
	# Asked as a countdown rather than by waiting it out: the holds are real
	# seconds and this suite's frames go by far faster than those, so waiting
	# for silence was eleven seconds of test and a timeout when it was not
	# quite enough. What matters is that the clock runs down and is bounded -
	# together those are "it goes away".
	expect(panel.lines_showing() > 0, "something is on screen while it runs")
	var was: float = panel.time_left()
	var longest: float = float(LogPanel.HOLD[&"bad"]) + LogPanel.FADE
	expect(was > 0.0 and was <= longest,
		"a line has a bounded time to run",
		"%.1fs against a longest of %.1fs" % [was, longest])
	await frames(40)
	expect(panel.time_left() < was,
		"and it counts down while nothing else happens",
		"%.2f against %.2f" % [panel.time_left(), was])
	# And it really does reach nothing, which `show_state` also guarantees at
	# the start of a run.
	panel.show_state(state)
	await frames(2)
	expect(panel.lines_showing() == 0 and panel.time_left() == 0.0,
		"and a new run opens on a silent log",
		"%d lines" % panel.lines_showing())

	# **A key expands it into the night's history.**
	expect(not panel.is_expanded(), "it starts collapsed")
	await tap_key(KEY_L)
	await frames(3)
	expect(panel.is_expanded(), "the log key opens the history")
	expect(panel.history_lines() > 0,
		"and there is a night in it to read",
		"%d lines" % panel.history_lines())
	var history: Control = require_control("LogHistory")
	if history != null:
		expect(history.visible, "the panel is up")
		expect(history.get_global_rect().end.y <= 270.0
			and history.get_global_rect().end.x <= 480.0,
			"and fits on the screen", str(history.get_global_rect()))
	await tap_key(KEY_L)
	await frames(3)
	expect(not panel.is_expanded(), "and the same key puts it away")

	driver.running = true
	await close_scene()
	_completed += 1     # last line: an abandoned case never gets here
func _case_0091_title() -> void:
	# **The whole point of this one is that it is not `MAIN_SCENE`.** Every
	# other case opens the game; this opens what the game opens.
	await open_scene("res://scenes/Title.tscn")
	var title: TitleScreen = _scene as TitleScreen
	expect(title != null, "the title screen is what boots")
	if title == null:
		_completed += 1
		await close_scene()
		return

	var router: Node = root.get_node_or_null(^"App")
	expect(router != null, "the router is up")
	if router == null:
		_completed += 1
		await close_scene()
		return
	await frames(6)
	expect(title.phase() == router.TITLE,
		"it opens on the ident, not the menu", str(title.phase()))
	var menu: Control = require_control("Menu")
	expect(menu != null and not menu.visible,
		"and the menu is not up yet")

	# **The farm is behind it, and it is the real farm.**
	var view: WorldView = require_control("WorldView")
	expect(view != null, "there is a world behind the title")
	expect(title.backdrop_tick() >= GameData.DUSK_AT_TICK,
		"and it starts at dusk rather than at breakfast",
		"tick %d against dusk at %d"
		% [title.backdrop_tick(), GameData.DUSK_AT_TICK])

	# **Any key moves past the ident.** Not a named action - a player who has
	# just started the game has not learned any of them.
	await tap_key(KEY_X)
	await frames(3)
	expect(title.phase() == router.MENU,
		"any key at all opens the menu", str(title.phase()))
	expect(menu != null and menu.visible, "and the menu is up")

	# **Continue is absent, not greyed.** Whether it is there at all depends
	# on whether there is a run on disk, so this asserts the pair rather than
	# one of them: whatever `Save.has_run()` says, the menu agrees, and the
	# entry is never present-but-dead.
	var entries := title.menu_entries()
	expect(entries.has("new") and entries.has("quit"),
		"the menu has the entries that always work", str(entries))
	expect(entries.has("continue") == Save.has_run(),
		"Continue is there exactly when there is a run to continue",
		"%s with has_run %s" % [str(entries), str(Save.has_run())])
	for named in entries:
		var button: Button = require_control("Menu_%s" % named)
		if button == null:
			continue
		expect(not button.disabled,
			"'%s' is a live button rather than a greyed one" % named)
		expect(button.get_global_rect().end.y <= 270.0,
			"and is on the screen", str(button.get_global_rect()))

	# Options is on it since task 0092 built the router and the frame.
	expect(entries.has("options"),
		"Options is on the menu now that something opens it", str(entries))

	# The night really does come in behind the menu, which is the premise.
	var was := title.backdrop_tick()
	await until(func() -> bool:
		return title.backdrop_tick() > was + GameData.SECONDS,
		"the backdrop to creep on", 600)
	expect(title.backdrop_tick() > was,
		"and the farm behind it is running",
		"%d against %d" % [title.backdrop_tick(), was])

	await close_scene()
	_completed += 1     # last line: an abandoned case never gets here
func _case_0092_router() -> void:
	# **From the title first.** Options opened from the title menu comes back
	# to the title menu - one half of the done-when.
	await open_scene("res://scenes/Title.tscn")
	var router: Node = root.get_node_or_null(^"App")
	var title: TitleScreen = _scene as TitleScreen
	if router == null or title == null:
		expect(router != null, "the router autoload is up")
		_completed += 1
		await close_scene()
		return

	await frames(4)
	await tap_key(KEY_X)
	await frames(3)
	expect(router.here() == router.MENU, "the title is on its menu",
		router.name_of(router.here()))

	await click_control("Menu_options")
	await frames(4)
	expect(router.here() == router.OPTIONS,
		"the Options entry opens the options screen",
		router.name_of(router.here()))
	var frame: Control = require_control("OptionsScreen")
	expect(frame != null and frame.visible, "and the frame is up")
	var options: OptionsScreen = frame as OptionsScreen
	if options != null:
		expect(options.tabs() == [&"game", &"video", &"audio", &"access",
			&"controls"],
			"with the five pages tasks 0093 to 0098 built, in TABS order",
			str(options.tabs()))

	await click_control("OptionsBack")
	await frames(4)
	expect(router.here() == router.MENU,
		"and Back returns to the menu that opened it",
		router.name_of(router.here()))
	expect(frame != null and not frame.visible, "with the frame put away")

	# **The records screen is reachable from the menu.** Carried over from
	# task 0069, which built it when there was no menu to put it on.
	await click_control("Menu_stats")
	await frames(4)
	expect(router.here() == router.STATS,
		"the menu opens the records screen",
		router.name_of(router.here()))
	var records: Control = require_control("StatsScreen")
	expect(records != null and records.visible, "and it is up")
	await tap_key(KEY_ESCAPE)
	await frames(4)
	expect(router.here() == router.MENU, "and closes back to the menu",
		router.name_of(router.here()))
	await close_scene()

	# **And from a run, which is the other half.** The same screen, the same
	# Back, a different place to come back to - and neither screen knows the
	# other exists.
	await open_scene(MAIN_SCENE)
	router = root.get_node_or_null(^"App")
	await frames(6)
	expect(router.here() == router.RUN, "a run says it is a run",
		router.name_of(router.here()))

	# **R still opens the records mid-night.** Task 0092 asks for the key to
	# keep working, and it goes through the router now, so the key and the
	# menu entry are the same door.
	await tap_key(KEY_R)
	await frames(4)
	expect(router.here() == router.STATS,
		"R opens the records inside a run",
		router.name_of(router.here()))
	var in_run: Control = require_control("StatsScreen")
	expect(in_run != null and in_run.visible, "and it is on the screen")
	await tap_key(KEY_R)
	await frames(4)
	expect(router.here() == router.RUN,
		"and R again puts it away, back to the run",
		router.name_of(router.here()))
	expect(in_run != null and not in_run.visible, "with the panel gone")

	# The tech tree, the same way.
	await tap_key(KEY_T)
	await frames(4)
	expect(router.here() == router.TECH, "T opens the tech tree",
		router.name_of(router.here()))
	await tap_key(KEY_T)
	await frames(4)
	expect(router.here() == router.RUN, "and closes it")

	await close_scene()
	_completed += 1     # last line: an abandoned case never gets here
func _case_0093_video() -> void:
	await open_scene("res://scenes/Title.tscn")
	var video: Node = root.get_node_or_null(^"Video")
	var settings: Node = root.get_node_or_null(^"Settings")
	if video == null or settings == null:
		expect(video != null, "the video autoload is up")
		expect(settings != null, "and the settings autoload with it")
		await close_scene()
		_completed += 1
		return

	var was_mode: int = settings.get_int(&"video/window_mode")
	var was_scale: int = settings.get_int(&"video/scale")
	var was_size: String = String(settings.get_string(&"video/size"))
	var was_cap: int = settings.get_int(&"video/max_fps")
	var was_crisp: bool = settings.get_bool(&"video/integer_scaling")
	settings.set_value(&"video/window_mode", 0)
	settings.set_value(&"video/scale", 4)
	settings.set_value(&"video/size", "")

	await frames(4)
	await tap_key(KEY_X)
	await frames(3)
	await click_control("Menu_options")
	await frames(4)
	var frame: OptionsScreen = require_control("OptionsScreen") as OptionsScreen
	if frame == null:
		await close_scene()
		_completed += 1
		return

	# **Opened on the strip, on the first page** - WELCOME BACK, HERO's way in,
	# so the first thing the keys do is choose a page.
	expect(frame.open_tab() == &"game", "the options open on their first page",
		String(frame.open_tab()))
	expect(_focused() == "OptionsTab_game", "with the selection on the strip",
		_focused())
	# **Right along the strip turns the page.**
	await tap_key(KEY_RIGHT)
	await frames(3)
	expect(frame.open_tab() == &"video", "right along the strip turns to video",
		String(frame.open_tab()))
	var tab: OptionsVideo = locate_control("OptionsVideo") as OptionsVideo
	expect(tab != null and tab.visible, "and the video page comes up")
	if tab == null:
		await close_scene()
		_completed += 1
		return

	# **The list is the monitor's.** Headless answers 1920x1080, so four
	# sizes, every one of them a whole multiple and every one marked.
	expect(tab.size_choices() == 4, "four sizes are offered",
		str(tab.size_choices()))
	expect(tab.marked_sizes() == 4, "and all four marked as multiples",
		str(tab.marked_sizes()))

	# Down from the strip is the first row.
	await tap_key(KEY_DOWN)
	await frames(2)
	expect(_focused() == "VideoWindow", "down from the strip is the first row",
		_focused())

	# A frame cap is the one control with no countdown, and it lands on the
	# engine rather than only in a file.
	(locate_control("VideoCap") as Control).grab_focus()
	await frames(2)
	for _i in 6:
		if Engine.max_fps == 120:
			break
		await tap_key(KEY_RIGHT)
		await frames(1)
	expect(Engine.max_fps == 120, "stepping the cap caps the engine",
		str(Engine.max_fps))
	expect(not tab.countdown_showing(),
		"and asks nothing, because a cap cannot hide the screen")
	expect(not tab.warning_showing(),
		"with square pixels on, the note is the key to the marks")

	# **A size is provisional.** It applies at once and asks to be kept.
	var size_row := locate_control("VideoSize") as OptionRow
	expect(size_row != null and not size_row.disabled,
		"the size row is on while the game is in a window")
	size_row.grab_focus()
	await frames(2)
	await tap_key(KEY_LEFT)
	await frames(2)
	expect(settings.get_int(&"video/scale") == 3,
		"left on the size row picks the next size down at once",
		str(settings.get_int(&"video/scale")))
	expect(video.waiting(), "and starts a countdown")
	expect(tab.countdown_showing(), "which the page shows")
	expect(_focused() == "VideoKeep",
		"with the caret on KEEP, the answer for a player who can see it",
		_focused())
	await click_control("VideoKeep")
	await frames(2)
	expect(not video.waiting(), "KEEP ends it")
	expect(not tab.countdown_showing(), "and the question goes away")
	expect(_focused() == "VideoSize",
		"and the selection goes back to the row that asked", _focused())

	# Nobody answers this one, so it puts itself back.
	await tap_key(KEY_LEFT)
	await frames(2)
	expect(settings.get_int(&"video/scale") == 2, "a second size applies too",
		str(settings.get_int(&"video/scale")))
	video._process(video.REVERT_SECONDS + 0.5)
	await frames(3)
	expect(settings.get_int(&"video/scale") == 3,
		"and comes back on its own when nobody keeps it",
		str(settings.get_int(&"video/scale")))
	expect(not tab.countdown_showing(), "with the question gone with it")

	# **Escape puts it back too** - the one key a player who cannot see the
	# screen will press - and leaves the options up.
	(locate_control("VideoSize") as Control).grab_focus()
	await frames(2)
	await tap_key(KEY_LEFT)
	await frames(2)
	expect(video.waiting(), "a third size waits to be kept")
	await tap_key(KEY_ESCAPE)
	await frames(3)
	var router: Node = root.get_node_or_null(^"App")
	expect(not video.waiting() and settings.get_int(&"video/scale") == 3,
		"escape puts the old size back",
		str(settings.get_int(&"video/scale")))
	expect(router != null and router.here() == router.OPTIONS,
		"and does not also close the options",
		router.name_of(router.here()) if router != null else "no router")

	# **Square pixels go last, and go back without a key.** Measured: with
	# no window at all the viewport's transform is the identity while the
	# stretch is INTEGER and a 0.13 scale with a 14px offset the moment it is
	# FRACTIONAL, so every coordinate this harness clicks after that lands
	# somewhere else. The press that turns it off is real; the one that would
	# turn it back is the setting, which is the same path the row takes.
	(locate_control("VideoCrisp") as Control).grab_focus()
	await frames(2)
	await tap_key(KEY_ENTER)
	await frames(2)
	expect(root.content_scale_stretch
		== Window.CONTENT_SCALE_STRETCH_FRACTIONAL,
		"turning square pixels off reaches the viewport",
		str(root.content_scale_stretch))
	expect(tab.warning_showing(), "and the note becomes the warning")
	settings.set_value(&"video/integer_scaling", true)
	await frames(2)
	expect(root.content_scale_stretch
		== Window.CONTENT_SCALE_STRETCH_INTEGER, "and back on again",
		str(root.content_scale_stretch))
	expect(not tab.warning_showing(), "with the warning put away")

	settings.set_value(&"video/window_mode", was_mode)
	settings.set_value(&"video/scale", was_scale)
	settings.set_value(&"video/size", was_size)
	settings.set_value(&"video/max_fps", was_cap)
	settings.set_value(&"video/integer_scaling", was_crisp)
	await frames(2)
	await close_scene()
	_completed += 1
func _case_0094_audio() -> void:
	await open_scene("res://scenes/Title.tscn")
	var audio: Node = root.get_node_or_null(^"Audio")
	var settings: Node = root.get_node_or_null(^"Settings")
	if audio == null or settings == null:
		expect(audio != null, "the audio autoload is up")
		expect(settings != null, "and the settings autoload with it")
		await close_scene()
		_completed += 1
		return

	var was: Dictionary = {}
	for key in [&"audio/master", &"audio/music", &"audio/sfx",
			&"audio/ambience"]:
		was[key] = float(settings.get_float(key))
	var was_muted: bool = settings.get_bool(&"audio/muted")
	settings.set_value(&"audio/music", 0.6)
	settings.set_value(&"audio/ambience", 0.5)

	await frames(4)
	await tap_key(KEY_X)
	await frames(3)
	await click_control("Menu_options")
	await frames(4)
	var frame: OptionsScreen = require_control("OptionsScreen") as OptionsScreen
	expect(frame != null and frame.tabs() == [&"game", &"video", &"audio",
			&"access", &"controls"],
		"the strip has all five pages, in the order the frame names them",
		str(frame.tabs()) if frame != null else "no frame")

	await click_control("OptionsTab_audio")
	await frames(4)
	var tab: OptionsAudio = locate_control("OptionsAudio") as OptionsAudio
	expect(tab != null and tab.visible, "the audio page opens")
	if tab == null:
		await close_scene()
		_completed += 1
		return

	# **A level steps by twentieths and writes its own key and nothing else.**
	var others: Array = [&"audio/master", &"audio/sfx", &"audio/ambience"]
	var untouched: Dictionary = {}
	for key in others:
		untouched[key] = float(settings.get_float(key))
	audio.forget_counts()
	(locate_control("Audio_music") as Control).grab_focus()
	await frames(2)
	await tap_key(KEY_LEFT)
	await tap_key(KEY_LEFT)
	await frames(2)
	expect(is_equal_approx(settings.get_float(&"audio/music"), 0.5),
		"two steps left from sixty per cent is half",
		"%.2f" % settings.get_float(&"audio/music"))
	var moved: Array = []
	for key in others:
		if not is_equal_approx(settings.get_float(key), float(untouched[key])):
			moved.append(String(key))
	expect(moved.is_empty(), "and the other three do not move",
		", ".join(moved))
	expect(is_equal_approx(tab.level_shown(&"audio/music"), 0.5),
		"the row shows it", "%.2f" % tab.level_shown(&"audio/music"))
	expect(tab.value_shown(&"audio/music") == "50%",
		"and so does the number on it", tab.value_shown(&"audio/music"))

	# **The level is heard once it stops moving** - one sound for the two
	# steps, not two. Counted rather than read off `last_played()`: the
	# ambience puts a bird in the air on its own schedule.
	var want: StringName = audio.TEST_SOUNDS[&"audio/music"]
	await until(func() -> bool: return tab.auditioning() == &"",
		"the music level to settle")
	expect(audio.plays_of(want) == 1,
		"and then the music test sound plays, once",
		"%d of %s" % [audio.plays_of(want), want])

	# **The right half of a value is its right arrow**, for the pointer.
	audio.forget_counts()
	var row := locate_control("Audio_ambience") as Control
	await click_at(row.global_position + Vector2(row.size.x - 6.0, row.size.y * 0.5))
	await frames(2)
	expect(is_equal_approx(settings.get_float(&"audio/ambience"), 0.55),
		"clicking the right of the ambience value turns it up a step",
		"%.2f" % settings.get_float(&"audio/ambience"))
	await until(func() -> bool: return tab.auditioning() == &"",
		"the ambience level to settle")
	want = audio.TEST_SOUNDS[&"audio/ambience"]
	expect(audio.plays_of(want) == 1,
		"and the ambience bus is the one heard",
		"%d of %s" % [audio.plays_of(want), want])

	# **Mute is a state over the levels.** The done-when, through the row.
	var master := AudioServer.get_bus_index("Master")
	(locate_control("AudioMute") as Control).grab_focus()
	await frames(2)
	await tap_key(KEY_ENTER)
	await frames(3)
	expect(settings.get_bool(&"audio/muted"), "the mute row mutes")
	expect(AudioServer.is_bus_mute(master), "and the master bus with it")
	expect(tab.mute_showing(), "and the row says so")
	expect(is_equal_approx(settings.get_float(&"audio/music"), 0.5),
		"while every level is left exactly where it was",
		"%.2f" % settings.get_float(&"audio/music"))
	expect(tab.value_shown(&"audio/music") == "50%",
		"including on the screen, which does not drop to nought")

	await tap_key(KEY_ENTER)
	await frames(3)
	expect(not settings.get_bool(&"audio/muted"), "and unmuting unmutes")
	expect(not AudioServer.is_bus_mute(master), "the master bus comes back")
	expect(is_equal_approx(settings.get_float(&"audio/music"), 0.5),
		"with the levels it left", "%.2f" % settings.get_float(&"audio/music"))

	# **The page goes back the way it shipped, asked twice.**
	var reset := tab.find_child("ResetPage", true, false) as OptionRow
	expect(reset != null, "the page has a row that puts it back")
	if reset != null:
		reset.grab_focus()
		await frames(2)
		await tap_key(KEY_ENTER)
		await frames(2)
		expect(tab.reset_asking(), "the first press only asks")
		expect(is_equal_approx(settings.get_float(&"audio/music"), 0.5),
			"and changes nothing yet")
		await tap_key(KEY_ENTER)
		await frames(2)
		expect(not tab.reset_asking(), "the second does it")
		expect(is_equal_approx(settings.get_float(&"audio/music"), 0.8),
			"and the music is back at its shipped level",
			"%.2f" % settings.get_float(&"audio/music"))

	for key in was:
		settings.set_value(key, float(was[key]))
	settings.set_value(&"audio/muted", was_muted)
	await frames(2)
	await close_scene()
	_completed += 1
func _case_0095_controls() -> void:
	await open_scene("res://scenes/Title.tscn")
	var actions: Node = root.get_node_or_null(^"Actions")
	var settings: Node = root.get_node_or_null(^"Settings")
	if actions == null or settings == null:
		expect(actions != null, "the actions autoload is up")
		await close_scene()
		_completed += 1
		return
	actions.reset_all()

	await frames(4)
	await tap_key(KEY_X)
	await frames(3)
	await click_control("Menu_options")
	await frames(4)
	await click_control("OptionsTab_controls")
	await frames(4)
	var tab: OptionsControls = locate_control(
		"OptionsControls") as OptionsControls
	expect(tab != null and tab.visible, "the controls page opens")
	if tab == null:
		await close_scene()
		_completed += 1
		return
	expect(not tab.reset_all_showing(),
		"with nothing to reset, so nothing offering to")
	expect(tab.binding_shown(&"move_up") == "W / UP",
		"and MOVE UP on both keys the game ships it with",
		tab.binding_shown(&"move_up"))

	# **Enter listens.**
	var up := locate_control("Bind_move_up") as OptionRow
	up.grab_focus()
	await frames(2)
	await tap_key(KEY_ENTER)
	await frames(2)
	expect(tab.waiting_for() == &"move_up", "Enter on a binding listens for one",
		String(tab.waiting_for()))
	expect(tab.binding_shown(&"move_up") == "PRESS A KEY",
		"and the row says it is listening", tab.binding_shown(&"move_up"))

	# **A taken key is refused by name, and the row goes on listening** for
	# another, so a clash costs one key and not a trip back to Enter.
	await tap_key(KEY_B)
	await frames(3)
	expect(tab.message_shown().contains("BUILD MODE"),
		"a taken key is refused by name", tab.message_shown())
	expect(tab.waiting_for() == &"move_up",
		"and the row is still listening", String(tab.waiting_for()))

	# **Escape gives up** - and leaves the options screen up rather than
	# going back through it.
	var router: Node = root.get_node_or_null(^"App")
	await tap_key(KEY_ESCAPE)
	await frames(3)
	expect(tab.waiting_for() == &"", "escape ends the listening")
	expect(router != null and router.here() == router.OPTIONS,
		"and leaves the options screen up rather than going back through it",
		router.name_of(router.here()) if router != null else "no router")
	expect(tab.binding_shown(&"move_up") == "W / UP", "binding nothing")

	# **A free key is taken**, here by the pointer: a click on a binding
	# listens the same as Enter does.
	await click_control("Bind_move_up")
	await frames(2)
	expect(tab.waiting_for() == &"move_up", "a click on a binding listens too")
	await tap_key(KEY_G)
	await frames(3)
	expect(tab.binding_shown(&"move_up") == "G *",
		"a free key is taken, and the row is marked as moved",
		tab.binding_shown(&"move_up"))
	expect(tab.reset_showing(&"move_up"), "the moved row says so")
	expect(not tab.reset_showing(&"move_down"),
		"while a row that did not move does not")
	expect(tab.reset_all_showing(), "and RESET ALL is there now")
	expect(tab.message_shown() == I18n.t(&"CTL_RESET_HINT"),
		"with the line under the page saying how to undo it",
		tab.message_shown())

	# **Everything is on the screen**, and the bottom of a list that scrolls
	# comes into it when the selection gets there.
	var screen := Rect2(Vector2.ZERO, Vector2(get_viewport_size()))
	for named in ["OptionsFrame", "PageNote", "OptionsBack"]:
		var part := locate_control(named) as Control
		if named == "PageNote":
			part = tab.find_child("PageNote", true, false) as Control
		expect(part != null and screen.encloses(part.get_global_rect()),
			"'%s' is on the screen, not off the bottom of it" % named,
			"%s in %s" % [str(part.get_global_rect()) if part != null
				else "?", str(screen)])
	var everything := locate_control("ControlsResetAll") as Control
	everything.grab_focus()
	await frames(4)
	var scroll := tab.find_child("PageScroll", true, false) as Control
	expect(scroll != null and scroll.get_global_rect().grow(1.0).encloses(
			everything.get_global_rect()),
		"RESET ALL scrolls into view when the selection reaches it",
		"%s in %s" % [str(everything.get_global_rect()),
			str(scroll.get_global_rect()) if scroll != null else "?"])

	# **Left or right on a moved row puts it back.**
	up.grab_focus()
	await frames(4)
	await tap_key(KEY_LEFT)
	await frames(3)
	expect(tab.binding_shown(&"move_up") == "W / UP", "and it goes back",
		tab.binding_shown(&"move_up"))
	expect(not tab.reset_all_showing(), "with nothing left to reset")
	await close_scene()

	# **The key it was given works in a run**, through the router, and
	# keeps working after the input map is rebuilt from the settings.
	actions.bind(&"stats", _key_event(KEY_G))
	await open_scene(MAIN_SCENE)
	router = root.get_node_or_null(^"App")
	await frames(6)
	await tap_key(KEY_G)
	await frames(4)
	expect(router.here() == router.STATS,
		"the key the player chose opens the records",
		router.name_of(router.here()))
	await tap_key(KEY_G)
	await frames(4)
	expect(router.here() == router.RUN, "and closes them again")
	await tap_key(KEY_R)
	await frames(4)
	expect(router.here() == router.RUN,
		"while the key it used to be on now does nothing",
		router.name_of(router.here()))

	InputMap.action_erase_events("stats")
	actions.apply()
	await tap_key(KEY_G)
	await frames(4)
	expect(router.here() == router.STATS,
		"and it still does after a fresh boot of the input map",
		router.name_of(router.here()))
	await tap_key(KEY_G)
	await frames(4)

	actions.reset_all()
	await frames(2)
	await close_scene()
	_completed += 1


## The name of whatever has the keyboard, or "".
func _focused() -> String:
	var owner := root.gui_get_focus_owner()
	return String(owner.name) if owner != null else ""


## The size the game is drawn at, off the viewport rather than typed here.
func get_viewport_size() -> Vector2i:
	return root.get_visible_rect().size


## One key as an event. Here rather than in `Actions`, because this file is
## parsed on its own and may not name the autoload's script.
func _key_event(code: int) -> InputEventKey:
	var key := InputEventKey.new()
	key.keycode = code
	return key
func _case_0096_pause() -> void:
	await open_scene(MAIN_SCENE)
	var router: Node = root.get_node_or_null(^"App")
	var driver: SimDriver = _scene.get_node("%SimDriver")
	var menu: PauseMenu = locate_control("PauseMenu") as PauseMenu
	if router == null or menu == null:
		expect(menu != null, "the pause menu is in the scene")
		await close_scene()
		_completed += 1
		return
	await frames(6)
	expect(driver.running, "a run is running")
	expect(not menu.is_open(), "with no pause menu on it")

	# **The pause key stops the world.**
	await tap_key(KEY_P)
	await frames(4)
	expect(router.here() == router.PAUSE, "the pause key pauses",
		router.name_of(router.here()))
	expect(menu.is_open(), "and the menu is up")
	expect(not driver.running, "and the driver has stopped")
	var held := int(driver.state["tick"])
	await frames(12)
	expect(int(driver.state["tick"]) == held,
		"and no tick runs while it is up",
		"%d against %d" % [int(driver.state["tick"]), held])

	# The same key closes it, and the game carries on.
	await tap_key(KEY_P)
	await frames(4)
	expect(router.here() == router.RUN, "and closes it again",
		router.name_of(router.here()))
	expect(driver.running, "with the world going again")
	expect(not menu.is_open(), "and the menu put away")

	# **Options from the pause menu comes back to the pause menu**, and the
	# game stays stopped the whole way.
	await tap_key(KEY_P)
	await frames(3)
	await click_control("Pause_options")
	await frames(4)
	expect(router.here() == router.OPTIONS, "OPTIONS opens the options",
		router.name_of(router.here()))
	expect(not driver.running,
		"and the game is still stopped, two screens deep")
	await click_control("OptionsBack")
	await frames(4)
	expect(router.here() == router.PAUSE, "Back returns to the pause menu",
		router.name_of(router.here()))
	expect(not driver.running, "still stopped")
	expect(menu.is_open(), "and the menu is back")

	# **The caret starts on RESUME, and the keys walk it round.** One
	# selection for the keys and the pointer since 2026-10-07; down from the
	# last entry is the first one again.
	expect(menu.selected() == &"resume", "the caret is on RESUME",
		str(menu.selected()))
	await tap_key(KEY_DOWN)
	await frames(2)
	expect(menu.selected() == &"options", "down moves it", str(menu.selected()))
	await tap_key(KEY_UP)
	await tap_key(KEY_UP)
	await frames(2)
	expect(menu.selected() == &"quit", "and up from the top wraps to the bottom",
		str(menu.selected()))

	# **Abandon asks first, and says what it is taking.**
	expect(menu.label_of(&"abandon") == "ABANDON RUN",
		"the entry reads plainly", menu.label_of(&"abandon"))
	await click_control("Pause_abandon")
	await frames(3)
	expect(menu.asking() and menu.question() == &"abandon",
		"one press asks rather than doing it", str(menu.question()))
	expect(router.here() == router.PAUSE, "and nothing has happened yet",
		router.name_of(router.here()))
	expect(menu.label_of(&"do") == "YES, ABANDON IT",
		"the button that goes ahead says what it does", menu.label_of(&"do"))
	expect(menu.cost_shown().contains("DAY"),
		"and what will be lost is on the screen", menu.cost_shown())
	expect(menu.selected() == &"keep",
		"with the caret on KEEP PLAYING, so a reflex press is the safe one",
		str(menu.selected()))

	# **Escape takes the question back, not the menu.**
	await tap_key(KEY_ESCAPE)
	await frames(3)
	expect(not menu.asking(), "escape takes the question away")
	expect(router.here() == router.PAUSE and menu.is_open(),
		"and leaves the pause menu up", router.name_of(router.here()))
	expect(menu.selected() == &"abandon",
		"with the caret back on the entry that asked", str(menu.selected()))
	await click_control("Pause_abandon")
	await frames(3)
	await click_control("Pause_keep")
	await frames(3)
	expect(not menu.asking() and router.here() == router.PAUSE,
		"KEEP PLAYING takes it back too", router.name_of(router.here()))

	# **Quitting says the run is saved first** - and is not pressed here, for
	# the obvious reason.
	await click_control("Pause_quit")
	await frames(3)
	expect(menu.question() == &"quit" and menu.cost_shown().contains("SAVED"),
		"closing the game asks too, and says the run is kept",
		menu.cost_shown())
	await tap_key(KEY_ESCAPE)
	await frames(3)

	await click_control("Pause_resume")
	await frames(4)
	expect(router.here() == router.RUN, "RESUME resumes",
		router.name_of(router.here()))
	expect(driver.running, "and the world with it")

	# **Escape opens it when escape has nothing else to do**, and closes it.
	await tap_key(KEY_ESCAPE)
	await frames(3)
	expect(router.here() == router.PAUSE, "escape pauses an idle farmer",
		router.name_of(router.here()))
	await tap_key(KEY_ESCAPE)
	await frames(3)
	expect(router.here() == router.RUN, "and escape resumes",
		router.name_of(router.here()))
	# A panel that is open keeps escape for itself.
	await tap_key(KEY_I)
	await frames(3)
	var bag: Control = locate_control("InventoryPanel") as Control
	expect(bag != null and bag.visible, "the inventory opens")
	await tap_key(KEY_ESCAPE)
	await frames(3)
	expect(bag != null and not bag.visible, "escape closes it")
	expect(router.here() == router.RUN,
		"and does not also pause the game", router.name_of(router.here()))

	# **The key that resumes is not also a key pressed in the farm.** The
	# farmer faces a tree; ENTER on RESUME used to start chopping it on the
	# first tick back, because the edge went into the run's intent.
	var state: Dictionary = driver.state
	var tree_at := Vector2i(-1, -1)
	var stand := Vector2i(-1, -1)
	for y in range(2, Grid.HEIGHT - 2):
		for x in range(2, Grid.WIDTH - 2):
			var cell := Vector2i(x, y)
			if Interact.verb_at(state, cell) == &"chop" \
					and Farm.walkable(state, cell + Vector2i(-1, 0)):
				tree_at = cell
				stand = cell + Vector2i(-1, 0)
				break
		if tree_at.x >= 0:
			break
	expect(tree_at.x >= 0, "there is a tree to face")
	if tree_at.x >= 0:
		_stand_at(state, stand, Player.EAST)
		await tap_key(KEY_P)
		await frames(3)
		expect(menu.selected() == &"resume", "back on RESUME")
		await tap_key(KEY_ENTER)
		await frames(8)
		expect(router.here() == router.RUN, "ENTER on RESUME resumes",
			router.name_of(router.here()))
		expect(not Player.is_busy(state),
			"and the farmer does not start on the tree with it")

	# **Restart begins the run again where it stands.**
	Resources.gain(state, {GameData.WOOD: 7})
	await frames(30)
	var before := int(driver.state["tick"])
	await tap_key(KEY_P)
	await frames(3)
	await click_control("Pause_restart")
	await frames(3)
	expect(menu.question() == &"restart", "RESTART RUN asks first")
	expect(menu.label_of(&"do") == "YES, START AGAIN",
		"and says what going ahead does", menu.label_of(&"do"))
	await click_control("Pause_do")
	await frames(6)
	expect(router.here() == router.RUN and not menu.is_open(),
		"going ahead closes the menu on a run", router.name_of(router.here()))
	expect(int(driver.state["tick"]) < before,
		"which is a new one, from the start",
		"%d against %d" % [int(driver.state["tick"]), before])
	expect(driver.running, "and running")

	# **Save and quit writes the run and leaves.**
	Save.delete_run()
	await tap_key(KEY_P)
	await frames(3)
	var at_save := int(driver.state["tick"])
	await click_control("Pause_save")
	await frames(4)
	expect(router.here() == router.TITLE, "SAVE AND QUIT goes to the title",
		router.name_of(router.here()))
	expect(Save.has_run(), "with a run on the disk")
	expect(int(Save.read_run().get("tick", -1)) == at_save,
		"which is the game that was on the screen",
		"%d against %d" % [int(Save.read_run().get("tick", -1)), at_save])
	await close_scene()

	# **And CONTINUE picks it up.** Which is the point of saving: the title
	# has offered this entry since task 0091 and until now it started a new
	# game.
	await open_scene("res://scenes/Title.tscn")
	router = root.get_node_or_null(^"App")
	await frames(4)
	await tap_key(KEY_X)
	await frames(3)
	var title: TitleScreen = _scene as TitleScreen
	expect(title != null and title.is_shown(&"continue", true),
		"the title offers CONTINUE when there is a run to continue")
	expect(locate_control("Menu_continue") != null,
		"and the entry is on the menu")

	# **The button is pressed, and the router brings up the scene itself.**
	# Every other case in this file opens its own; here the loading is the
	# thing being tested, so what comes up is read and then cleaned away.
	# `change_scene_to_file` is deferred, hence the wait.
	await click_control("Menu_continue")
	await frames(10)
	expect(router.last_scene() == MAIN_SCENE,
		"and pressing it brings up the run", router.last_scene())
	var brought: Node = current_scene
	expect(brought != null, "which the router loaded by itself")
	if brought != null:
		var carried: SimDriver = brought.get_node("%SimDriver")
		expect(int(carried.state["tick"]) >= at_save,
			"and the run comes back where it was left, not at nought",
			"%d against %d" % [int(carried.state["tick"]), at_save])
		current_scene = null
		root.remove_child(brought)
		brought.free()
	await close_scene()

	# The rest is driven the usual way, on a run resumed by hand.
	router.ask_to_resume()
	await open_scene(MAIN_SCENE)
	await frames(6)
	driver = _scene.get_node("%SimDriver")
	expect(int(driver.state["tick"]) >= at_save,
		"and by hand as well as by the button",
		"%d against %d" % [int(driver.state["tick"]), at_save])

	# **Abandon, answered, takes it.**
	await tap_key(KEY_P)
	await frames(3)
	menu = locate_control("PauseMenu") as PauseMenu
	await click_control("Pause_abandon")
	await frames(3)
	await click_control("Pause_do")
	await frames(4)
	expect(router.here() == router.TITLE, "going ahead ends the run",
		router.name_of(router.here()))
	expect(not Save.has_run(), "and the save goes with it")
	await close_scene()
	Save.delete_run()
	_completed += 1
func _case_0097_language() -> void:
	await open_scene("res://scenes/Title.tscn")
	var settings: Node = root.get_node_or_null(^"Settings")
	if settings == null:
		expect(false, "the settings autoload is up")
		await close_scene()
		_completed += 1
		return
	settings.set_value(&"gameplay/language", "en")
	await frames(3)

	await tap_key(KEY_X)
	await frames(3)
	var new_run: Button = require_control("Menu_new")
	expect(new_run != null and new_run.text == "NEW RUN",
		"the title is in English", new_run.text if new_run else "")

	await click_control("Menu_options")
	await frames(4)
	var tab: OptionsGame = locate_control("OptionsGame") as OptionsGame
	expect(tab != null and tab.visible, "the game page opens first")
	if tab == null:
		await close_scene()
		_completed += 1
		return
	expect(tab.choices() == I18n.LOCALES.size(),
		"with every language to step through", str(tab.choices()))
	expect(tab.language_shown() == "en", "and English on",
		tab.language_shown())

	# **Right on the language row is the next language**, and the whole game
	# changes with it - the row that was just changed included.
	(locate_control("GameLanguage") as Control).grab_focus()
	await frames(2)
	await tap_key(KEY_RIGHT)
	await frames(4)
	expect(String(settings.get_string(&"gameplay/language")) == "pt_BR",
		"stepping the language writes the setting",
		String(settings.get_string(&"gameplay/language")))
	expect(I18n.locale() == "pt_BR", "and the table follows", I18n.locale())
	expect(tab.language_shown() == "pt_BR", "and the page says so",
		tab.language_shown())
	expect(_focused() == "GameLanguage",
		"with the selection still on the row it changed", _focused())

	var back: Button = require_control("OptionsBack")
	expect(back != null and back.text == "VOLTAR",
		"the button that was BACK is VOLTAR now",
		back.text if back else "")
	var title: Label = require_control("OptionsTitle")
	expect(title != null and title.text == "OPÇÕES",
		"and the heading with it", title.text if title else "")

	await click_control("OptionsBack")
	await frames(4)
	new_run = require_control("Menu_new")
	expect(new_run != null and new_run.text == "NOVA PARTIDA",
		"the menu behind it came back in Portuguese too",
		new_run.text if new_run else "")

	settings.set_value(&"gameplay/language", "pt_BR")
	await close_scene()
	await open_scene(MAIN_SCENE)
	await frames(6)
	var night_button: Button = require_control("NightButton")
	expect(night_button != null and night_button.text == "VIRAR A NOITE",
		"a run built in Portuguese is in Portuguese",
		night_button.text if night_button else "")

	settings.set_value(&"gameplay/language", "en")
	await frames(4)
	expect(night_button != null and night_button.text == "SWITCH TO NIGHT",
		"and back again without reloading anything",
		night_button.text if night_button else "")

	# **The night speed on the game page is the one the run uses**, and it
	# reaches a run that is up behind the options.
	var driver: SimDriver = _scene.get_node("%SimDriver")
	var was_speed: int = settings.get_int(&"gameplay/night_speed")
	settings.set_value(&"gameplay/night_speed", 1)
	await frames(2)
	settings.set_value(&"gameplay/night_speed", 2)
	await frames(2)
	expect(driver.speed == 2, "a speed written to the setting is the run's speed",
		str(driver.speed))
	settings.set_value(&"gameplay/night_speed", was_speed)
	await close_scene()
	_completed += 1
func _case_0098_access() -> void:
	await open_scene("res://scenes/Title.tscn")
	var settings: Node = root.get_node_or_null(^"Settings")
	if settings == null:
		expect(false, "the settings autoload is up")
		await close_scene()
		_completed += 1
		return
	for key in A11y.KEYS:
		settings.reset(key)
	await frames(3)

	await tap_key(KEY_X)
	await frames(3)
	await click_control("Menu_options")
	await frames(4)
	await click_control("OptionsTab_access")
	await frames(4)
	var tab: OptionsA11y = locate_control("OptionsA11y") as OptionsA11y
	expect(tab != null and tab.visible, "the access page opens")
	if tab == null:
		await close_scene()
		_completed += 1
		return
	expect(tab.rows_count() == A11y.KEYS.size(),
		"with a row for every setting it owns", str(tab.rows_count()))

	# **Past the end of a list is its start**, so FULL steps round to OFF.
	(locate_control("Access_screen_shake") as Control).grab_focus()
	await frames(2)
	await tap_key(KEY_RIGHT)
	await frames(3)
	expect(is_equal_approx(settings.get_float(&"a11y/screen_shake"), 0.0),
		"stepping the shake past FULL comes round to OFF",
		"%.2f" % settings.get_float(&"a11y/screen_shake"))
	expect(is_equal_approx(tab.chosen(&"a11y/screen_shake"), 0.0),
		"and the row says so", "%.2f" % tab.chosen(&"a11y/screen_shake"))

	var was_dim := UiKit.colour(UiKit.DIM)
	(locate_control("Access_high_contrast") as Control).grab_focus()
	await frames(2)
	await tap_key(KEY_ENTER)
	await frames(4)
	expect(UiKit.high_contrast(), "the contrast switch reaches the kit")
	expect(UiKit.colour(UiKit.DIM) != was_dim,
		"and the quiet colour stops being quiet")
	expect(UiKit.colour(UiKit.DIM).get_luminance()
		> was_dim.get_luminance(),
		"by getting brighter, not by changing hue",
		"%.2f against %.2f" % [UiKit.colour(UiKit.DIM).get_luminance(),
			was_dim.get_luminance()])
	(locate_control("Access_high_contrast") as Control).grab_focus()
	await frames(2)
	await tap_key(KEY_ENTER)
	await frames(4)
	expect(not UiKit.high_contrast(), "and back again")

	# Left from NORMAL is the other end: the slowest.
	(locate_control("Access_slow") as Control).grab_focus()
	await frames(2)
	await tap_key(KEY_LEFT)
	await frames(3)
	expect(is_equal_approx(settings.get_float(&"a11y/slow"), 0.5),
		"the slowest speed writes a half",
		"%.2f" % settings.get_float(&"a11y/slow"))
	settings.reset(&"a11y/slow")
	await close_scene()

	settings.set_value(&"a11y/screen_shake", 0.0)
	settings.set_value(&"a11y/flashing", false)
	await open_scene(MAIN_SCENE)
	await frames(6)
	var driver: SimDriver = _scene.get_node("%SimDriver")
	(driver.state["intent"] as Dictionary)["begin_night"] = true
	await until(func() -> bool:
		return int(driver.state["phase"]) != Phases.DAY,
		"the farm leaves the day")
	var at := int(driver.state["tick"])
	await frames(8)
	expect(int(driver.state["tick"]) > at,
		"and goes on ticking with the shake and the lamps turned off",
		"%d against %d" % [int(driver.state["tick"]), at])
	expect(is_equal_approx(settings.get_float(&"a11y/screen_shake"), 0.0),
		"with the shake still off", "%.2f"
		% settings.get_float(&"a11y/screen_shake"))
	await close_scene()

	for key in A11y.KEYS:
		settings.reset(key)
	await frames(2)
	_completed += 1
func _case_0099_ident() -> void:
	# **The studio ident is the boot scene** (2026-10-07): WELCOME BACK, HERO's
	# DEF4ULT STUDIO ident, a scene of its own ahead of the title. Opened here
	# the way the engine opens it - from the router's BOOT - and every way out
	# of it is walked: a skip, a second press, the black lead, the timeline.
	_forget_any_loaded_scene()
	var router: Node = root.get_node_or_null(^"App")
	expect(router != null, "the router is there for the ident to hand over to")
	if router == null:
		_completed += 1
		return
	var ours := root.content_scale_size
	var ours_stretch := root.content_scale_stretch
	router.reset(router.BOOT)
	await open_scene("res://scenes/StudioIntro.tscn")
	var ident := _scene as StudioIntro
	expect(ident != null, "the boot scene is the studio ident")
	if ident == null:
		await close_scene()
		_completed += 1
		return
	expect(root.content_scale_size == StudioIntro.FRAME,
		"it lays the window out as that game's 1280x720 frame",
		str(root.content_scale_size))
	expect(root.content_scale_stretch == Window.CONTENT_SCALE_STRETCH_FRACTIONAL,
		"stretched smoothly, the way that game draws it")
	expect(ident.clock() < 0.0 and not ident.leaving(),
		"and it opens on its black lead, running", "%.2f" % ident.clock())

	# **Its two sounds land on their beats.**
	ident.set_clock(StudioIntro.T_IGNITE - 0.05)
	await frames(2)
	expect(ident.sounds_fired() == [true, true],
		"the tube strike and the sting have both fired by the ignition",
		str(ident.sounds_fired()))

	# **The first press collapses; it does not leave.** Pressed by reflex on
	# the launch where somebody did want to see it, the collapse still reads
	# as "yes, skipped" without slamming the door.
	ident.set_clock(StudioIntro.T_CREST)
	await tap_key(KEY_Z)
	await frames(2)
	expect(not ident.leaving() and ident.clock() >= StudioIntro.T_HOLD,
		"the first key skips to the collapse rather than out",
		"%.2f" % ident.clock())

	# **The second leaves at once, and does not rise.**
	await tap_key(KEY_Z)
	await frames(10)
	expect(ident.leaving(), "the second key leaves")
	expect(router.here() == router.TITLE
		and router.last_scene() == StudioIntro.NEXT_SCENE,
		"for the title, through the router",
		"%s / %s" % [router.name_of(router.here()), router.last_scene()])
	expect(root.content_scale_size == ours
		and root.content_scale_stretch == ours_stretch,
		"with this game's own frame back on the window",
		str(root.content_scale_size))
	expect(not bool(router.rise_from_black),
		"and a skip asks for no rise out of black")
	var brought: Node = current_scene
	expect(brought is TitleScreen, "the router loaded the title by itself",
		str(brought))
	expect(brought != null and brought.find_child("RiseFromBlack", true, false) == null,
		"which comes up at once after a skip")
	_forget_any_loaded_scene()
	await close_scene()

	# **The timeline running out hands over by itself, and rises.**
	router.reset(router.BOOT)
	await open_scene("res://scenes/StudioIntro.tscn")
	ident = _scene as StudioIntro
	ident.set_clock(StudioIntro.T_BLACK - 0.01)
	await frames(10)
	expect(ident.leaving(), "the end of the timeline hands over on its own")
	brought = current_scene
	expect(brought is TitleScreen, "to the title", str(brought))
	expect(brought != null and brought.find_child("RiseFromBlack", true, false) != null,
		"which comes up out of the ident's black")
	expect(not bool(router.rise_from_black),
		"and taking that once clears it, so the next title is not dark")
	expect(router.here() == router.TITLE,
		"with PRESS ANY KEY up, as the title always opened",
		router.name_of(router.here()))
	_forget_any_loaded_scene()
	await close_scene()

	# **A key in the black lead leaves at once**: nothing has been shown, so
	# there is nothing to collapse.
	router.reset(router.BOOT)
	await open_scene("res://scenes/StudioIntro.tscn")
	ident = _scene as StudioIntro
	await tap_key(KEY_Z)
	await frames(10)
	expect(ident.leaving() and router.here() == router.TITLE,
		"a key during the black lead goes straight to the title",
		router.name_of(router.here()))
	_forget_any_loaded_scene()
	await close_scene()
	expect(root.content_scale_size == ours,
		"and nothing of the ident's frame is left behind",
		str(root.content_scale_size))
	_completed += 1
func _case_0100_version() -> void:
	await open_scene("res://scenes/Title.tscn")
	await frames(4)
	var label: Label = require_control("Version")
	expect(label != null and label.visible,
		"the title says which build it is")
	if label == null:
		await close_scene()
		_completed += 1
		return
	expect(label.text.contains(BuildInfo.VERSION),
		"with the version in it", label.text)
	expect(label.text.contains(BuildInfo.BUILT),
		"and the date it was built", label.text)
	expect(label.get_global_rect().end.x <= float(root.get_visible_rect().size.x),
		"and it is on the screen rather than off the right of it",
		str(label.get_global_rect()))
	await close_scene()
	_completed += 1
