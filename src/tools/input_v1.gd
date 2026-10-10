extends "res://src/tools/input_check.gd"

## The input paths of version 1.0: real clicks and real keys through the real
## scenes, with nobody in the room.
##
## Run by `python tools/verify.py`. The last line it prints is
## `N cases, M failed`, and it exits non-zero when M is not zero.
##
## **Every case from task 0112 on lives here.** `input_check` holds the MVP's
## 61 cases (tasks 0011-0111) and was already spending some 74 of the 120
## seconds verify gives a script when the 1.0 backlog was queued. Nothing moved
## across: the old cases stay where they are and this file starts with one.
##
## ## How it shares the old harness
##
## **It extends `input_check.gd`** rather than copying it. Every tree helper -
## `open_scene`, `until`, `click_control`, `tap_key`, `hold_key`, `expect` and
## the rest - needs the running SceneTree and the scene this run opened, and an
## inherited method has both without being handed them. What is overridden is
## everything that counts: `_run()` calls only the cases below, `_finish()`
## compares against `V1_CASES` and prints this file's own last line, and the
## watchdog names this file. Each suite is its own process, so `passed`,
## `failed` and `_completed` are this run's alone - the two counters never
## meet. `V1_CASES` rather than `CASES` because GDScript will not let a class
## declare a constant its parent already has.
##
## A plain helper that does not need the tree is shared through `SuiteKit`
## (`src/tools/suite_kit.gd`), never copied.
##
## **Defences are put down by night.** From task 0132 the rules refuse to
## place, upgrade or sell a defence by day; a case that needs one does it in
## PREPARATION - the way task 0119 moves the old suites - never by day.
##
## The stall watchdog is the parent's `WATCHDOG_SECONDS` (20 s without an
## assert landing), and every `expect()` puts it back to zero.

## How many `_case_NNNN_*` functions `_run()` is expected to finish.
## **Adding a case means bumping this.**
const V1_CASES := 39


func _process(delta: float) -> bool:
	_elapsed += delta
	if _elapsed < WATCHDOG_SECONDS:
		return false
	push_error("input_v1: watchdog fired after %.0fs" % _elapsed)
	print("WATCHDOG: a case never finished - look at the last case named above")
	_finish()
	return true


func _run() -> void:
	await _case_0112_harness()
	await _case_0114_house_bar()
	await _case_0121_pad()
	await _case_0127_bed()
	await _case_0129_asleep()
	await _case_0130_night_camera()
	await _case_0131_cursor()
	await _case_0133_hotbar()
	await _case_0134_repair()
	await _case_0135_flare_aim()
	await _case_0136_start()
	await _case_0138_morning()
	await _case_0139_night_hud()
	await _case_0140_bedtime()
	await _case_0141_tutorial()
	await _case_0149_date()
	await _case_0152_moon_line()
	await _case_0154_calm()
	await _case_0157_routes()
	await _case_0158_panel()
	await _case_0159_seasons()
	await _case_0160_ending()
	await _case_0167_till_grass()
	await _case_0168_seed_pages()
	await _case_0169_inventory()
	await _case_0170_seeds()
	await _case_0171_winter()
	await _case_0172_regrow()
	await _case_0173_upgrade()
	await _case_0174_area()
	await _case_0175_swings()
	await _case_0176_gold()
	await _case_followup_0176_review()
	await _case_0177_hardwood()
	await _case_0178_sprinkler()
	await _case_0180_minigame()
	await _case_0181_bait()
	await _case_0182_book()
	await _case_0183_barn()
	_finish()


func _finish() -> void:
	if _finished:
		return
	_finished = true
	if _completed < V1_CASES:
		failed += 1
		print("  FAIL  a case did not finish   %d of %d completed"
			% [_completed, V1_CASES])
	print("%d cases, %d failed" % [passed + failed, failed])
	quit(1 if failed > 0 else 0)


# ------------------------------------------------------------------- the cases

## 0112 - the harness itself: boot the game and press one real key.
func _case_0112_harness() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	if driver == null:
		await close_scene()
		_completed += 1
		return
	expect(driver.running, "Main boots into a running day")

	# A direction the farmer is not already facing, so that turning to it can
	# only be the key's doing.
	var east := Player.facing(driver.state) != Player.EAST
	var key := KEY_D if east else KEY_A
	var want := Player.EAST if east else Player.WEST
	var tick := int(driver.state["tick"])
	await hold_key(key, 20)
	expect(Player.facing(driver.state) == want,
		"a real key press reaches the rules through the real scene",
		"facing %d, wanted %d" % [Player.facing(driver.state), want])
	expect(int(driver.state["tick"]) > tick, "and the world turned meanwhile",
		"tick %d, then %d" % [tick, int(driver.state["tick"])])
	await close_scene()
	_completed += 1


## 0114 - the night HUD's house bar measures the house the night started with.
func _case_0114_house_bar() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	var night_hud: NightHud = require_control("NightHud")
	if driver == null or night_hud == null:
		await close_scene()
		_completed += 1
		return
	var state := driver.state
	driver.set_speed(1)
	(state["tech_owned"] as Array).append(&"stout timbers")
	var full := Phases.house_full(state)
	state["house_hp"] = full
	NightRoad.to_night(state)
	await frames(3)
	expect(int(state["phase"]) == Phases.NIGHT and night_hud.visible,
		"it is night and the night HUD is up")
	var house_text: Label = locate_control("HouseNumbers") as Label
	var house_bar: ColorRect = locate_control("HouseBar") as ColorRect
	expect(house_text != null and house_bar != null, "the house bar is there")
	if house_text == null or house_bar == null:
		await close_scene()
		_completed += 1
		return

	# **A 140 house reads 140/140, whole and calm.** Against the base 100 it
	# printed 140/100 and a bar clamped at full.
	expect(full == 140, "stout timbers makes the house 140", str(full))
	expect(house_text.text.contains("%d/%d" % [full, full]),
		"the HUD reads 140/140", house_text.text)
	# The danger pulse is the BAD variation and a red fill. **Not `r > g`**:
	# the calm DIM ink is a warm grey, so its red is already over its green.
	expect(house_text.theme_type_variation != UiKit.BAD
		and house_bar.color == UiKit.colour(UiKit.GOOD),
		"with no danger pulse", "%s, %s"
			% [house_text.theme_type_variation, house_bar.color])
	var whole := house_bar.size.x

	# **And 80 of 140 is in danger**, which against 100 it was not: 57
	# percent, under `HOUSE_DANGER_PERCENT`.
	state["house_hp"] = 80
	await frames(2)
	expect(house_text.text.contains("80/%d" % full), "80 of 140 says so",
		house_text.text)
	expect(house_text.theme_type_variation == UiKit.BAD,
		"and pulses red at 57 percent", str(house_text.theme_type_variation))
	expect(house_bar.size.x < whole * 0.6, "on a bar four sevenths long",
		"%f against %f" % [house_bar.size.x, whole])
	await close_scene()
	_completed += 1


## 0121 - a controller for every action, through synthetic pad events.
func _case_0121_pad() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	var router: Node = root.get_node_or_null(^"App")
	var actions: Node = root.get_node_or_null(^"Actions")
	if driver == null or router == null or actions == null:
		expect(actions != null, "the Actions autoload is up")
		await close_scene()
		_completed += 1
		return
	var state := driver.state
	await frames(4)

	# **The stick, half tilted, walks exactly like a key.** 0.6 is past the
	# deadzone and was truncated to standing still by `int()`.
	var east := Player.facing(state) != Player.EAST
	var axis_value := 0.6 if east else -0.6
	await _pad_axis(JOY_AXIS_LEFT_X, axis_value)
	await frames(6)
	var pushed := int((state["intent"]["move"] as Array)[0])
	await frames(10)
	await _pad_axis(JOY_AXIS_LEFT_X, 0.0)
	await frames(3)
	expect(pushed == (1 if east else -1),
		"a half-tilted stick writes a whole step, like a key", str(pushed))
	expect(Player.facing(state) == (Player.EAST if east else Player.WEST),
		"and the farmer turns to it", str(Player.facing(state)))

	# **The d-pad walks too.**
	var south := Player.facing(state) != Player.SOUTH
	var dpad := JOY_BUTTON_DPAD_DOWN if south else JOY_BUTTON_DPAD_UP
	await _pad_button(dpad, true)
	await frames(15)
	await _pad_button(dpad, false)
	await frames(3)
	expect(Player.facing(state) == (Player.SOUTH if south else Player.NORTH),
		"the d-pad walks the farmer", str(Player.facing(state)))

	# **A chops the tree in front of him.**
	var tree := Vector2i(-1, -1)
	var beside := Vector2i(-1, -1)
	for candidate in Farm.cells_with(state, &"tree"):
		var spot := _walkable_neighbour(state, candidate)
		if spot != Vector2i(-1, -1):
			tree = candidate
			beside = spot
			break
	expect(beside != Vector2i(-1, -1), "there is a tree to stand beside")
	if beside != Vector2i(-1, -1):
		driver.running = false
		await frames(2)
		_stand_at(state, beside, _facing_from(beside, tree))
		driver.running = true
		await frames(3)
		await _pad_button(JOY_BUTTON_A, true)
		# **Waited for, not counted** (`until`'s own note): four headless
		# frames can pass inside one tick, and counting them failed one run in
		# three during task 0133.
		await until(func() -> bool: return Player.is_busy(state), "A to start the chopping")
		var action: Dictionary = (state["player"] as Dictionary)["action"]
		expect(Player.is_busy(state) and action.get("verb", &"") == &"chop",
			"A starts the chopping", str(action))
		await _pad_button(JOY_BUTTON_A, false)
		await frames(2)

	# **The labels follow the hand that is on the controls.**
	expect(bool(actions.using_pad), "a pad press puts the names on the pad")
	expect(actions.text_of(&"interact") == I18n.t(&"ACT_PAD_A"),
		"interact reads as the A button", actions.text_of(&"interact"))
	await tap_key(KEY_F20)
	var keyboard := String(actions.text_of(&"interact"))
	expect(not bool(actions.using_pad) and keyboard.begins_with("SPACE")
		and keyboard == actions.shipped_text(&"interact"),
		"and a key puts them back on the keyboard", keyboard)

	# **Y opens build mode and closes it again.**
	await _pad_tap(JOY_BUTTON_Y)
	await frames(2)
	expect(Building.is_active(state), "Y opens build mode")
	await _pad_tap(JOY_BUTTON_Y)
	await frames(2)
	expect(not Building.is_active(state), "and Y closes it")

	# **Start pauses and resumes.**
	await _pad_tap(JOY_BUTTON_START)
	await frames(4)
	expect(router.here() == router.PAUSE, "Start opens the pause menu",
		router.name_of(router.here()))
	await _pad_tap(JOY_BUTTON_START)
	await frames(4)
	expect(router.here() == router.RUN, "and Start closes it",
		router.name_of(router.here()))

	# **Back sends for the night.**
	await _pad_tap(JOY_BUTTON_BACK)
	await until(func() -> bool: return int(state["phase"]) != Phases.DAY,
		"the night to be sent for")
	expect(int(state["phase"]) == Phases.PREPARATION,
		"Back is the night button", Phases.name_of(int(state["phase"])))

	# **Rebinding keeps the devices apart.** A new key keeps the pad button;
	# a new pad input keeps the key.
	var g := InputEventKey.new()
	g.keycode = KEY_J
	var a := InputEventJoypadButton.new()
	a.button_index = JOY_BUTTON_A
	var keyed: Dictionary = actions.bind(&"interact", g)
	expect(bool(keyed.get("ok", false))
		and InputMap.action_has_event("interact", g)
		and InputMap.action_has_event("interact", a),
		"interact on J keeps its A", str(keyed))
	var up := InputEventJoypadMotion.new()
	up.axis = JOY_AXIS_RIGHT_Y
	up.axis_value = -1.0
	# **The right stick is the night camera's since task 0130**, and no pad
	# input is left over: the move is refused, naming it.
	var taken: Dictionary = actions.bind(&"interact", up)
	expect(not bool(taken.get("ok", true))
		and StringName(taken.get("clash", &"")) == &"pan_up",
		"the right stick is the camera's: interact onto it is refused", str(taken))
	# So it is freed by hand for the rest of this. `apply()` - which the bind
	# below and the reset both run - builds from the photograph, so LOOK UP
	# gets it back.
	for held in InputMap.action_get_events("pan_up"):
		if actions.same_event(held, up):
			InputMap.action_erase_event("pan_up", held)
	var padded: Dictionary = actions.bind(&"interact", up)
	expect(bool(padded.get("ok", false))
		and InputMap.action_has_event("interact", g)
		and InputMap.action_has_event("interact", up)
		and not InputMap.action_has_event("interact", a),
		"and its pad moved to the right stick keeps the G", str(padded))
	actions.reset(&"interact")
	var space := InputEventKey.new()
	space.keycode = KEY_SPACE
	expect(not bool(actions.rebound(&"interact"))
		and InputMap.action_has_event("interact", space)
		and InputMap.action_has_event("interact", a),
		"and reset puts back both, SPACE and A")
	expect(InputMap.action_has_event("pan_up", up),
		"and LOOK UP has the right stick back")
	await close_scene()
	_completed += 1


## A pad button going down or up, through the door a real pad uses.
func _pad_button(button: JoyButton, pressed: bool) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	event.pressed = pressed
	event.pressure = 1.0 if pressed else 0.0
	Input.parse_input_event(event)
	await process_frame


func _pad_tap(button: JoyButton) -> void:
	await _pad_button(button, true)
	await _pad_button(button, false)


## A stick or trigger at a value, the same way.
func _pad_axis(axis: JoyAxis, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = value
	Input.parse_input_event(event)
	await process_frame


## 0127 - the bed and the GO TO BED button start the night.
func _case_0127_bed() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	if driver == null:
		await close_scene()
		_completed += 1
		return
	var state := driver.state
	await frames(4)

	# **Into the house, beside the bed, interact.**
	_stand_at(state, House.porch(state))
	await tap_key(KEY_SPACE)
	await until(func() -> bool: return House.inside(state), "the house visit")
	var side := Vector2i(-1, -1)
	for y in range(3, House.ROOM.y - 1):
		for x in range(1, House.ROOM.x - 1):
			if side.x < 0 and House.bedside(Vector2i(x, y)):
				side = Vector2i(x, y)
	_stand_at(state, side, Player.NORTH)
	await frames(3)
	await tap_key(KEY_SPACE)
	await until(func() -> bool: return int(state["phase"]) == Phases.PREPARATION,
		"the bed to start the night")
	expect(int(state["phase"]) == Phases.PREPARATION and House.asleep(state)
		and not House.inside(state), "the bed starts the build step, asleep")
	await close_scene()

	# **GO TO BED from the far field** does the same, with no walking home.
	await open_scene(MAIN_SCENE)
	driver = require_control("SimDriver")
	state = driver.state
	await frames(4)
	var field: Vector2i = Farming.field_cells(state)[0]
	var stand := _walkable_neighbour(state, field)
	_stand_at(state, stand)
	await frames(3)
	var button: Button = require_control("NightButton")
	expect(button != null and button.text == I18n.t(&"DHUD_TO_NIGHT"),
		"the night button reads GO TO BED", button.text if button else "")
	await click_control("NightButton")
	await until(func() -> bool: return int(state["phase"]) == Phases.PREPARATION,
		"GO TO BED to start the night")
	expect(int(state["phase"]) == Phases.PREPARATION and House.asleep(state),
		"GO TO BED from the field starts the build step, asleep")
	await close_scene()
	_completed += 1


## 0129 - he stays in bed all night: held keys move nobody, and the night
## HUD's REPAIR mends the house without him.
func _case_0129_asleep() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	if driver == null:
		await close_scene()
		_completed += 1
		return
	var state := driver.state
	await frames(4)
	await click_control("NightButton")
	await until(func() -> bool: return int(state["phase"]) == Phases.PREPARATION,
		"GO TO BED to start the night")
	await frames(2)
	var house_view: HouseView = require_control("HouseView")
	expect(house_view != null and house_view.is_showing_bedtime(),
		"the switch opens on him getting into bed")
	NightRoad.through_build(state)
	NightRoad.park(state)
	await until(func() -> bool: return int(state["phase"]) == Phases.NIGHT, "the night")

	# **Holding D at night moves nobody.**
	var before := Player.position(state)
	await hold_key(KEY_D, 45)
	expect(Player.position(state) == before,
		"holding D at night does not move him",
		"%s to %s" % [before, Player.position(state)])
	var farmer: PlayerView = require_control("PlayerView") as PlayerView
	var world: WorldView = require_control("WorldView")
	expect(farmer != null and not farmer.is_drawn(), "nobody on the porch at night")
	expect(world != null and world.zzz_showing(), "and a Zzz over the house")

	# **A damaged house is mended without him** - by the guardian's cursor
	# since task 0134, where 0129 had a REPAIR button.
	state["house_hp"] = Phases.house_full(state) - 30
	Resources.gain(state, {GameData.FOOD: 200, GameData.WOOD: 200})
	await frames(2)
	var hurt := int(state["house_hp"])
	# Holding D above panned the night camera off the house (0130).
	world.look_at_cell(Farm.house_centre(state))
	await frames(2)
	await click_cell(Farm.house_centre(state))
	await until(func() -> bool: return int(state["house_hp"]) > hurt,
		"the house to be mended")
	expect(int(state["house_hp"]) > hurt,
		"clicking the damaged house mends it",
		"%d to %d" % [hurt, int(state["house_hp"])])
	await close_scene()
	_completed += 1


## 0130 - at night the camera is the player's.
func _case_0130_night_camera() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	var world: WorldView = require_control("WorldView")
	if driver == null or world == null:
		await close_scene()
		_completed += 1
		return
	var main := _scene
	var state := driver.state
	await frames(4)
	await click_control("NightButton")
	await until(func() -> bool: return int(state["phase"]) == Phases.PREPARATION,
		"GO TO BED to start the night")
	await frames(3)
	var house := (Vector2(Farm.house_centre(state)) + Vector2.ONE * 0.5) \
		* float(GameData.TILE_SIZE)
	expect(world.camera_centre().distance_to(world._camera_bounds(house)) < 1.0,
		"the night opens with the camera on the house",
		"%s against %s" % [world.camera_centre(), house])
	NightRoad.through_build(state)
	NightRoad.park(state)
	await until(func() -> bool: return int(state["phase"]) == Phases.NIGHT, "the night")

	# **Holding D pans right at CAMERA_PAN_SPEED, in real seconds**, from the
	# middle of the farm so no bound is near; the farmer stays in bed.
	var middle := Vector2(WorldView.WORLD_SIZE) * 0.5
	main.aim_night_camera(middle)
	await frames(2)
	var from := world.camera_centre()
	var farmer := Player.position(state)
	await press_key(KEY_D, true)
	var started := Time.get_ticks_usec()
	await frames(20)
	var seconds := float(Time.get_ticks_usec() - started) / 1000000.0
	var moved := world.camera_centre() - from
	await press_key(KEY_D, false)
	await frames(2)
	var expected := GameData.CAMERA_PAN_SPEED * seconds
	expect(moved.x > expected * 0.6 and moved.x < expected * 1.5 and absf(moved.y) < 0.01,
		"holding D at night pans the camera right by about speed x time",
		"%.1f px in %.3f s, expected about %.1f" % [moved.x, seconds, expected])
	expect(Player.position(state) == farmer, "and leaves the farmer where he is")

	# **The bound.** Far past the right edge, D holds it there.
	var edge: Vector2 = world._camera_bounds(Vector2(1.0e6, middle.y))
	main.aim_night_camera(Vector2(1.0e6, middle.y))
	await hold_key(KEY_D, 20)
	expect(is_equal_approx(world.camera_centre().x, edge.x),
		"panning past the farm's edge stops at the bound",
		"%s against %s" % [world.camera_centre(), edge])

	# **The right stick**, through `pan_left`.
	main.aim_night_camera(middle)
	await frames(2)
	from = world.camera_centre()
	await _pad_axis(JOY_AXIS_RIGHT_X, -1.0)
	await frames(15)
	await _pad_axis(JOY_AXIS_RIGHT_X, 0.0)
	await frames(2)
	expect(world.camera_centre().x < from.x - 4.0,
		"a right-stick push pans the camera",
		"%s from %s" % [world.camera_centre(), from])

	# **The edge band**, only with the window focused and the pointer in it.
	var size := main.get_viewport().get_visible_rect().size
	var motion := InputEventMouseMotion.new()
	motion.position = Vector2(size.x - 1.0, size.y * 0.5)
	motion.global_position = motion.position
	root.push_input(motion)
	main.get_window().mouse_exited.emit()
	main.aim_night_camera(middle)
	await frames(10)
	expect(world.camera_centre() == world._camera_bounds(middle),
		"the pointer at the edge pans nothing while it is outside the window")
	main.get_window().focus_entered.emit()
	main.get_window().mouse_entered.emit()
	await frames(15)
	expect(world.camera_centre().x > middle.x + 4.0,
		"and pans right at the right edge once it is in a focused window",
		str(world.camera_centre()))
	main.get_window().mouse_exited.emit()

	# **Nothing pans while the pause menu is up.**
	var router: Node = root.get_node_or_null(^"App")
	main.aim_night_camera(middle)
	await tap_key(KEY_P)
	await until(func() -> bool: return router.here() == router.PAUSE, "the pause menu")
	from = world.camera_centre()
	await hold_key(KEY_D, 15)
	expect(world.camera_centre() == from, "nothing pans while the pause menu is up")
	await tap_key(KEY_ESCAPE)
	await until(func() -> bool: return router.here() == router.RUN, "the run again")

	# **The morning gives it back to the farmer.**
	main.aim_night_camera(Vector2(1.0e6, 0.0))
	Phases.enter_result(state, true)
	await frames(3)
	var held := world.camera_centre()
	expect(held == world._camera_bounds(Vector2(1.0e6, 0.0)),
		"the result leaves the camera where it is", str(held))
	Phases.begin_day(state)
	await frames(30)
	var on := Vector2(Player.position(state)) * float(GameData.TILE_SIZE) / Player.SUBTILE
	expect(world.camera_centre().distance_to(world._camera_bounds(on)) < float(GameData.TILE_SIZE),
		"after the morning the camera is back on the farmer",
		"%s against %s" % [world.camera_centre(), world._camera_bounds(on)])
	await close_scene()
	_completed += 1


## 0131 - the guardian's cursor: the mouse puts it, the pad steps it, a
## placement lands on it, and by day there is none.
func _case_0131_cursor() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	var world: WorldView = require_control("WorldView")
	if driver == null or world == null:
		await close_scene()
		_completed += 1
		return
	var state := driver.state
	var cursor := world.cursor()
	await frames(4)
	expect(not cursor.is_active() and not cursor.visible, "there is no cursor by day")
	await click_control("NightButton")
	await until(func() -> bool: return int(state["phase"]) == Phases.PREPARATION,
		"GO TO BED to start the night")
	var house_view: HouseView = require_control("HouseView")
	await until(func() -> bool: return not house_view.is_showing_bedtime(),
		"the bed beat to end", 100000)
	await frames(2)
	expect(cursor.is_active() and cursor.visible, "the cursor is up in the build step")

	# **A mouse move puts it on the cell under the pointer.**
	var target := world.screen_to_cell(Vector2(240.0, 140.0))
	var motion := InputEventMouseMotion.new()
	motion.position = world.cell_to_screen(target)
	motion.global_position = motion.position
	root.push_input(motion)
	await frames(2)
	expect(cursor.cell() == target and not cursor.by_pad(),
		"a mouse move puts the cursor on that cell", "%s against %s" % [cursor.cell(), target])
	expect((state["intent"] as Dictionary)["build_cell"] == [target.x, target.y],
		"and it writes build_cell")

	# **The dpad steps it, one cell a press, and repeats when held.**
	await _pad_button(JOY_BUTTON_DPAD_RIGHT, true)
	await frames(1)
	await _pad_button(JOY_BUTTON_DPAD_RIGHT, false)
	await frames(2)
	expect(cursor.cell() == target + Vector2i(1, 0) and cursor.by_pad(),
		"one dpad press steps one cell", str(cursor.cell()))
	var from := cursor.cell()
	var camera := world.camera_centre()
	await _pad_button(JOY_BUTTON_DPAD_UP, true)
	var started := Time.get_ticks_usec()
	var long := GameData.CURSOR_REPEAT_DELAY + 4.0 * GameData.CURSOR_REPEAT_RATE
	await until(func() -> bool: return float(Time.get_ticks_usec() - started) / 1000000.0 > long,
		"a held dpad", 100000)
	await _pad_button(JOY_BUTTON_DPAD_UP, false)
	await frames(2)
	expect(from.y - cursor.cell().y >= 3 and cursor.cell().x == from.x,
		"held, it repeats", "%s to %s" % [from, cursor.cell()])
	expect(world.camera_centre() == camera
		or world.camera_centre().y < camera.y,
		"and the camera follows it up, if anywhere", "%s to %s" % [camera, world.camera_centre()])

	# **A placement at the cursor lands on that cell**: a wall, put down with
	# the pad's trigger wherever the pad left the cursor.
	Resources.gain(state, {GameData.WOOD: 600, GameData.STONE: 600})
	Building.set_active(state, true)
	(state["build"] as Dictionary)["selected"] = &"wall"
	var spot := Vector2i(-1, -1)
	for radius in 6:
		for candidate in Grid.within(cursor.cell(), radius):
			if spot.x < 0 and Building.why_not(state, &"wall", candidate).is_empty():
				spot = candidate
	cursor.place_at(spot)
	await frames(3)
	expect(cursor.look() == &"place", "over a free cell with a wall in hand it reads place",
		String(cursor.look()))
	# A confirms at the cursor at night (task 0133; it was RT's `place`).
	await _pad_button(JOY_BUTTON_A, true)
	await _pad_button(JOY_BUTTON_A, false)
	await until(func() -> bool: return StringName(Farm.occupant(state, spot).get("id", &"")) == &"wall",
		"the wall to go down")
	expect(StringName(Farm.occupant(state, spot).get("id", &"")) == &"wall",
		"a placement at the cursor lands on that cell", str(spot))
	await frames(3)
	# Over the wall it put down, it says what remove would do there (task
	# 0132: a wall has no levels, so not upgrade).
	expect(cursor.look() == &"sell", "and over the wall it filled it reads sell",
		String(cursor.look()))

	# **What is under it**, through the tooltip, inside the night's free band.
	var tooltip: Tooltip = require_control("Tooltip")
	await until(func() -> bool: return tooltip.text_showing().contains(Names.of(&"wall").to_upper()),
		"the tooltip over the wall", 100000)
	expect(tooltip.text_showing().contains(Names.of(&"wall").to_upper()),
		"the tooltip says what is under the cursor", tooltip.text_showing())
	expect(Tooltip.WORLD_AREA.encloses(tooltip.panel_rect()),
		"and stays off the HUD", str(tooltip.panel_rect()))

	# **The guardian is awake**, its eyes lit.
	var guardian := world.guardian()
	var lighting: Lighting = require_control("Lighting")
	await frames(2)
	expect(guardian.playing() == &"guardian_night" or guardian.playing() == &"guardian_wake",
		"the guardian woke for the night", String(guardian.playing()))
	expect(lighting.eye_cores().size() == 2, "with two lit eyes", str(lighting.eye_cores()))

	# **And by day there is none again.**
	Building.set_active(state, false)
	NightRoad.through_build(state)
	NightRoad.park(state)
	Phases.enter_result(state, true)
	Phases.begin_day(state)
	await frames(4)
	expect(not cursor.is_active() and not cursor.visible
		and tooltip.text_showing().is_empty(),
		"by day there is no cursor and nothing it describes")
	expect(guardian.playing() == &"guardian_day", "and the guardian is still again",
		String(guardian.playing()))
	await close_scene()
	_completed += 1


## 0133 - the hotbar of defences: number keys, clicks and bumpers pick a slot,
## the cursor places it, a slot short of money says so, and the guardian
## points at what went down.
func _case_0133_hotbar() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	var world: WorldView = require_control("WorldView")
	if driver == null or world == null:
		await close_scene()
		_completed += 1
		return
	var state := driver.state
	await frames(4)
	var hotbar: Hotbar = require_control("Hotbar")
	expect(hotbar != null and not hotbar.visible, "no hotbar by day")
	var seed_before := Farming.selected_seed(state)
	await click_control("NightButton")
	await until(func() -> bool: return int(state["phase"]) == Phases.PREPARATION,
		"GO TO BED to start the night")
	var house_view: HouseView = require_control("HouseView")
	await until(func() -> bool: return not house_view.is_showing_bedtime(),
		"the bed beat to end", 100000)
	Resources.gain(state, {GameData.WOOD: 900, GameData.STONE: 900,
		GameData.IRON: 900, GameData.OIL: 900, GameData.GUNPOWDER: 900})
	await frames(3)
	var ids := Building.catalogue(state)
	expect(hotbar.visible and ids.size() >= 5 and locate_control("Hotbar_%s" % ids[0]) != null,
		"in the build step the hotbar holds the catalogue", str(ids))

	# **The number keys**: slot_2 is the second defence, and not a seed.
	await tap_key(KEY_2)
	await frames(2)
	expect(Building.is_active(state) and Building.selected(state) == ids[1],
		"slot_2 selects the second defence", String(Building.selected(state)))
	expect(Farming.selected_seed(state) == seed_before,
		"and leaves the selected seed alone", String(Farming.selected_seed(state)))

	# **A click.**
	await click_control("Hotbar_%s" % ids[3])
	await frames(2)
	expect(Building.selected(state) == ids[3], "clicking a slot selects it",
		String(Building.selected(state)))

	# **The bumpers**, cycling and wrapping both ways.
	await _pad_button(JOY_BUTTON_RIGHT_SHOULDER, true)
	await _pad_button(JOY_BUTTON_RIGHT_SHOULDER, false)
	await frames(2)
	expect(Building.selected(state) == ids[4], "RB moves to the next slot",
		String(Building.selected(state)))
	Building.select(state, ids[ids.size() - 1])
	await frames(2)
	await _pad_button(JOY_BUTTON_RIGHT_SHOULDER, true)
	await _pad_button(JOY_BUTTON_RIGHT_SHOULDER, false)
	await frames(2)
	expect(Building.selected(state) == ids[0], "and wraps from the last to the first",
		String(Building.selected(state)))
	await _pad_button(JOY_BUTTON_LEFT_SHOULDER, true)
	await _pad_button(JOY_BUTTON_LEFT_SHOULDER, false)
	await frames(2)
	expect(Building.selected(state) == ids[ids.size() - 1], "and LB wraps back",
		String(Building.selected(state)))

	# **A placement at the cursor uses the selection**: the wall's slot, then a
	# click on a free cell.
	await click_control("Hotbar_wall")
	await frames(2)
	expect(Building.selected(state) == &"wall", "the wall's slot picks the wall")
	var cursor := world.cursor()
	var spot := Vector2i(-1, -1)
	var middle := world.screen_to_cell(Vector2(240.0, 120.0))
	for radius in 6:
		for candidate in Grid.within(middle, radius):
			if spot.x < 0 and Building.why_not(state, &"wall", candidate).is_empty():
				spot = candidate
	await click_cell(spot)
	await until(func() -> bool: return StringName(Farm.occupant(state, spot).get("id", &"")) == &"wall",
		"the wall to go down")
	expect(cursor.cell() == spot and StringName(Farm.occupant(state, spot).get("id", &"")) == &"wall",
		"a placement at the cursor uses the selection", str(spot))
	await frames(2)
	expect(world.guardian().playing() == &"guardian_point",
		"and the guardian points at it", String(world.guardian().playing()))

	# **Short of money**: greyed, and the slot says what is short.
	for id in (state["held"] as Dictionary).keys():
		(state["held"] as Dictionary)[id] = 0
	await frames(3)
	var tower: Control = locate_control("Hotbar_gun_tower")
	var missing := Resources.missing(state, Building.cost_of(&"gun_tower"))
	var first: StringName = GameData.sorted_names(missing.keys())[0]
	var price: Label = tower.get_node_or_null("Price") if tower != null else null
	expect(tower != null and tower.modulate.a < 1.0 and price != null
		and price.text.contains("%d%s" % [missing[first], str(first).substr(0, 1)]),
		"an unaffordable slot is greyed and shows its shortfall",
		price.text if price != null else "")
	await close_scene()
	_completed += 1


## 0134 - mending by pointing: the mouse and a pad confirm on a damaged wall
## at night, and there is no REPAIR button any more.
func _case_0134_repair() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	var world: WorldView = require_control("WorldView")
	if driver == null or world == null:
		await close_scene()
		_completed += 1
		return
	var state := driver.state
	await frames(4)
	await click_control("NightButton")
	await until(func() -> bool: return int(state["phase"]) == Phases.PREPARATION,
		"GO TO BED to start the night")
	var house_view: HouseView = require_control("HouseView")
	await until(func() -> bool: return not house_view.is_showing_bedtime(),
		"the bed beat to end", 100000)
	expect(locate_control("RepairButton") == null, "there is no RepairButton any more")
	Resources.gain(state, {GameData.STONE: 400, GameData.WOOD: 400})
	var spot := Vector2i(-1, -1)
	var middle := world.screen_to_cell(Vector2(240.0, 120.0))
	for radius in 6:
		for candidate in Grid.within(middle, radius):
			if spot.x < 0 and Building.why_not(state, &"wall", candidate).is_empty():
				spot = candidate
	expect(Building.place(state, &"wall", spot), "a wall goes down in the build step")
	NightRoad.through_build(state)
	NightRoad.park(state)
	await until(func() -> bool: return int(state["phase"]) == Phases.NIGHT, "the night")
	var cursor := world.cursor()

	# **The mouse**: point at the hurt wall, click it.
	Farm.damage(state, spot, 60)
	var hurt := int(Farm.occupant(state, spot)["hp"])
	var motion := InputEventMouseMotion.new()
	motion.position = world.cell_to_screen(spot)
	motion.global_position = motion.position
	root.push_input(motion)
	await frames(3)
	expect(cursor.cell() == spot and cursor.look() == &"repair",
		"over a hurt wall the cursor reads repair", String(cursor.look()))
	var tooltip: Tooltip = require_control("Tooltip")
	var line := Describe.repair_line(state, spot)
	await until(func() -> bool: return tooltip.text_showing().contains(line),
		"the tooltip's repair line", 100000)
	expect(tooltip.text_showing().contains(line),
		"and the tooltip says what mending it costs", tooltip.text_showing())
	await click_cell(spot)
	await until(func() -> bool: return int(Farm.occupant(state, spot)["hp"]) > hurt,
		"the wall to be mended")
	expect(int(Farm.occupant(state, spot)["hp"]) > hurt,
		"clicking a hurt wall at night mends it",
		"%d to %d" % [hurt, int(Farm.occupant(state, spot)["hp"])])

	# **A pad**: A on the same wall, hurt again.
	Farm.damage(state, spot, 60)
	hurt = int(Farm.occupant(state, spot)["hp"])
	await _pad_button(JOY_BUTTON_A, true)
	await _pad_button(JOY_BUTTON_A, false)
	await until(func() -> bool: return int(Farm.occupant(state, spot)["hp"]) > hurt,
		"A to mend the wall")
	expect(cursor.by_pad() and int(Farm.occupant(state, spot)["hp"]) > hurt,
		"and a pad's A mends it too",
		"%d to %d" % [hurt, int(Farm.occupant(state, spot)["hp"])])
	await close_scene()
	_completed += 1


## 0135 - aiming the flare: the key fires at the cursor, the button arms it
## and the next click fires where it lands, with the reach drawn meanwhile.
func _case_0135_flare_aim() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	var world: WorldView = require_control("WorldView")
	if driver == null or world == null:
		await close_scene()
		_completed += 1
		return
	var state := driver.state
	await frames(4)
	NightRoad.to_night(state)
	NightRoad.park(state)
	await frames(4)
	var cursor := world.cursor()

	# **The key**: move the cursor, press F, the flare goes off there.
	var aim := world.screen_to_cell(Vector2(300.0, 130.0))
	var motion := InputEventMouseMotion.new()
	motion.position = world.cell_to_screen(aim)
	motion.global_position = motion.position
	root.push_input(motion)
	await frames(2)
	expect(cursor.cell() == aim, "the cursor is on the cell to aim at", str(cursor.cell()))
	await press_key(KEY_F, true)
	await until(func() -> bool: return Ability.flares_used(state) > 0, "the flare to go off")
	await press_key(KEY_F, false)
	expect(Ability.flare_at(state) == [aim.x, aim.y],
		"pressing the ability key flares the cursor's cell", str(Ability.flare_at(state)))

	# **The button**: armed, the reach shows round the cursor and the look is
	# aim; the next click flares the clicked cell; cancel disarms.
	(state["ability"] as Dictionary)["cooldown"] = 0
	await frames(2)
	await click_control("FlareButton")
	await frames(2)
	expect(cursor.is_armed() and cursor.is_aiming() and cursor.look() == &"aim",
		"the FLARE button arms it: the reach is drawn and the cursor reads aim")
	var reach := cursor.reach_cells()
	var side := int(GameData.ABILITY["radius_tiles"]) * 2 + 1
	expect(reach.size() == side * side and reach.has(cursor.cell()),
		"the square is radius_tiles round the cursor, the cells the flare hits", str(reach.size()))
	await tap_key(KEY_ESCAPE)
	await frames(2)
	expect(not cursor.is_armed() and Ability.flares_used(state) == 1,
		"cancel disarms it and fires nothing")
	await click_control("FlareButton")
	await frames(2)
	var target := world.screen_to_cell(Vector2(180.0, 110.0))
	await click_cell(target)
	await until(func() -> bool: return Ability.flares_used(state) > 1, "the armed flare to go off")
	expect(Ability.flare_at(state) == [target.x, target.y] and not cursor.is_armed(),
		"and the next click flares the clicked cell", str(Ability.flare_at(state)))
	await close_scene()
	_completed += 1


## 0136 - START: the button and the key each begin the waves.
func _case_0136_start() -> void:
	for way in ["button", "key"]:
		await open_scene(MAIN_SCENE)
		var driver: SimDriver = require_control("SimDriver")
		if driver == null:
			await close_scene()
			_completed += 1
			return
		var state := driver.state
		await frames(4)
		await click_control("NightButton")
		await until(func() -> bool: return int(state["phase"]) == Phases.PREPARATION,
			"GO TO BED to start the build step")
		var start: Button = require_control("StartButton") as Button
		await frames(3)
		expect(start != null and start.is_visible_in_tree() and start.text == I18n.t(&"NHUD_START"),
			"the build step shows START", start.text if start != null else "")
		if way == "button":
			await click_control("StartButton")
		else:
			await tap_key(KEY_G)
		await until(func() -> bool: return int(state["phase"]) == Phases.NIGHT,
			"START to begin the waves")
		expect(int(state["phase"]) == Phases.NIGHT,
			"%s begins the waves" % ("clicking StartButton" if way == "button"
				else "pressing the START key"))
		await frames(2)
		expect(not start.is_visible_in_tree(), "and START goes with the build step")
		await close_scene()
	_completed += 1


## 0138 - the morning report: its lines on screen in both languages,
## confirming brings up the house with him getting out of bed, and a lost
## night is saved with the day it is now.
func _case_0138_morning() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	var result: ResultScreen = require_control("ResultScreen")
	var house_view: HouseView = require_control("HouseView")
	if driver == null or result == null or house_view == null:
		await close_scene()
		_completed += 1
		return
	var state := driver.state
	await frames(4)
	var nights_before := int(Stats.lifetime(Save.read_profile())["nights"])

	# **Every line the report has**: a night that began with a pass-out and
	# ended at dawn, with a wall lost in it and two still on the farm.
	Phases.pass_out(state)
	# **Passing out is a black screen** (the owner, 2026-10-08): no collapse,
	# and nobody lying on the farm.
	await frames(2)
	var farmer: PlayerView = require_control("PlayerView") as PlayerView
	expect(house_view.is_showing_blackout() and farmer != null
		and not farmer.is_drawn(), "passing out is a black screen, with nobody on the farm")
	NightRoad.through_build(state)
	NightRoad.park(state)
	var doomed := SuiteKit.any_buildable(state)
	Farm.place(state, doomed, {"id": &"wall", "hp": 30})
	Farm.damage(state, doomed, 999)
	var far: Vector2i = Enemies.spawn_cells(state, 0)[0]
	for _i in 2:
		Entities.set_hp(state, Entities.spawn(state, &"walker", far), 9999)
	(state["wave"] as Dictionary)["dawn_at"] = int(state["night_tick"]) + 10
	await until(func() -> bool: return result.visible, "the morning report")
	await frames(2)
	var at := GameData.DAY_END_MINUTE
	for locale in ["en", "pt_BR"]:
		I18n.use(locale)
		await frames(3)
		var said := _report_lines(result)
		for line in [I18n.f(&"RES_MORNING", [int(state["day"])]),
				I18n.f(&"RES_NIGHT", [1, I18n.t(&"RES_SURVIVED")]),
				I18n.plural(&"RES_WALKED", 2, [2]),
				I18n.plural(&"RES_CAME_DOWN", 1, [1]),
				I18n.f(&"RES_PASSED_OUT", [(at / 60) % 24, at % 60]),
				I18n.t(&"RES_LEFTOVERS")]:
			expect(said.has(line), "the report says '%s'" % line, str(said))
		var outside := _outside_the_frame(result)
		expect(outside.is_empty(), "and all of it fits inside its frame, on screen (%s)" % locale,
			str(outside))
	I18n.use("en")
	var header: Control = locate_control("ReportHeader") as Control
	expect(header != null and header.is_visible_in_tree()
		and header.size == Vector2(206, 40), "under a 206x40 sunrise",
		str(header.size) if header != null else "none")

	# **Confirming brings up the house**, him already standing beside the
	# bed - no getting-up beat (the owner's call) - and his to move at once.
	await click_control("ContinueButton")
	await until(func() -> bool: return int(state["phase"]) == Phases.DAY,
		"the morning")
	await frames(2)
	expect(House.inside(state) and House.bedside(Player.cell(state)),
		"confirming wakes him inside, beside the bed", str(Player.cell(state)))
	expect(house_view.is_showing_room() and not house_view.is_showing_bedtime(),
		"and the house view is up, him on his feet")
	var stood := Player.position(state)
	await hold_key(KEY_A, 10)
	expect(Player.position(state) != stood, "and he walks off straight away",
		"%s to %s" % [stood, Player.position(state)])

	# **A lost night is saved** - since 0138 every night's end is, keyed on
	# the day rather than the nights won.
	Save.delete_run()
	NightRoad.to_night(state)
	NightRoad.park(state)
	state["house_hp"] = 1
	Entities.spawn(state, &"walker", House.porch(state))
	await until(func() -> bool: return int(state["phase"]) == Phases.RESULT,
		"the house to fall")
	expect(not bool((state["last_result"] as Dictionary).get("survived", true)),
		"the night is lost")
	await until(func() -> bool: return Save.has_run(), "the lost night to be saved")
	var saved := Save.read_run()
	expect(int(saved.get("day", -1)) == int(state["day"])
		and int(saved.get("phase", -1)) == Phases.RESULT,
		"a lost night writes the run save, on the morning it is now",
		"day %d against %d" % [int(saved.get("day", -1)), int(state["day"])])
	expect(int(Stats.lifetime(Save.read_profile())["nights"]) == nights_before + 1,
		"and the profile counts the one night won once, the lost one not at all",
		"%d from %d" % [int(Stats.lifetime(Save.read_profile())["nights"]), nights_before])

	# **Confirmed with the interact key** beside the bed, the same press is
	# not taken for going back to it.
	await tap_key(KEY_SPACE)
	await until(func() -> bool: return int(state["phase"]) == Phases.DAY,
		"the key to confirm the report")
	await frames(10)
	expect(int(state["phase"]) == Phases.DAY and House.inside(state)
		and not House.asleep(state),
		"the interact key confirms the report and leaves him up, not back in bed",
		Phases.name_of(int(state["phase"])))
	Save.delete_run()
	await close_scene()
	_completed += 1


## The text of every label showing under a node.
func _report_lines(root: Control) -> Array:
	var out: Array = []
	var stack: Array = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		for child in node.get_children():
			stack.append(child)
		var label := node as Label
		if label != null and label.is_visible_in_tree() and not label.text.is_empty():
			out.append(label.text)
	return out


## Every showing label, button and picture of the report that pokes out of
## its frame or the 480x270 screen, as "name rect".
func _outside_the_frame(result: Control) -> Array:
	var frame: Control = locate_control("ResultFrame") as Control
	var out: Array = []
	if frame == null:
		return ["no ResultFrame"]
	var box := frame.get_global_rect()
	if not Rect2(0, 0, 480, 270).encloses(box):
		out.append("ResultFrame %s" % box)
	var stack: Array = [result]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		for child in node.get_children():
			stack.append(child)
		var shown := node as Control
		if shown == null or not shown.is_visible_in_tree() or shown == frame \
				or not frame.is_ancestor_of(shown):
			continue
		if not (shown is Label or shown is Button or shown.name == "ReportHeader"):
			continue
		if not box.encloses(shown.get_global_rect()):
			out.append("%s %s" % [shown.name, shown.get_global_rect()])
	return out


## 0139 - the night HUD for the guardian: START, the flare, the speed and SKIP
## on one bar a pad reaches by focus, and a hint that says what a confirm does.
func _case_0139_night_hud() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	var world: WorldView = require_control("WorldView")
	var night_hud: NightHud = require_control("NightHud")
	var actions := root.get_node_or_null(^"Actions")
	if driver == null or world == null or night_hud == null or actions == null:
		await close_scene()
		_completed += 1
		return
	var state := driver.state
	driver.set_speed(1)
	await frames(4)
	Resources.gain(state, {GameData.WOOD: 900, GameData.STONE: 900,
		GameData.IRON: 900, GameData.FOOD: 900})
	await click_control("NightButton")
	await until(func() -> bool: return int(state["phase"]) == Phases.PREPARATION,
		"GO TO BED to start the night")
	var house_view: HouseView = require_control("HouseView")
	await until(func() -> bool: return not house_view.is_showing_bedtime(),
		"the bed beat to end", 100000)
	await frames(2)

	# **The build step: START across the bar, the strip, nothing else yet.**
	var start: Button = locate_control("StartButton") as Button
	expect(start != null and start.is_visible_in_tree()
		and start.size.x >= NightHud.START_SIZE.x,
		"START is up across the bar in the build step",
		str(start.size) if start != null else "none")
	var waiting: Array = []
	for named in ["FlareButton", "SpeedButton", "SkipButton", "WaveCounter",
			"DawnCountdown"]:
		var it: Control = locate_control(named) as Control
		if it == null or it.is_visible_in_tree():
			waiting.append(named)
	expect(waiting.is_empty(),
		"the flare, the speed, SKIP, the wave and the countdown wait for the waves",
		str(waiting))
	var night_number: Label = locate_control("NightNumber") as Label
	expect(night_number != null and night_number.is_visible_in_tree()
		and night_number.text == I18n.f(&"NHUD_NIGHT", [Phases.night_ahead(state)]),
		"the strip names the night ahead",
		night_number.text if night_number != null else "none")
	expect(locate_control("RepairButton") == null, "there is no RepairButton")

	# **The hint follows the cursor.** A wall in hand over open ground: what a
	# click there does.
	Building.select(state, &"wall")
	var spot := Vector2i(-1, -1)
	var middle := world.screen_to_cell(Vector2(240.0, 140.0))
	for radius in 8:
		for candidate in Grid.within(middle, radius):
			if spot.x < 0 and Building.why_not(state, &"wall", candidate).is_empty():
				spot = candidate
	await _point_at(world, spot)
	expect(world.cursor().look() == &"place"
		and night_hud.hint_text() == I18n.f(&"NHUD_HINT_PLACE",
			[actions.text_of(&"place"), Names.of(&"wall")]),
		"over open ground with a wall in hand, the hint says what a click does",
		night_hud.hint_text())
	expect(Building.place(state, &"wall", spot), "a wall goes down")
	await frames(3)
	var own := world.cursor().look()
	var said_own := I18n.f(&"NHUD_HINT_UPGRADE",
		[actions.text_of(&"upgrade"), Names.of(&"wall")]) if own == &"upgrade" \
		else I18n.f(&"NHUD_HINT_SELL", [actions.text_of(&"remove"), Names.of(&"wall")])
	expect((own == &"upgrade" or own == &"sell") and night_hud.hint_text() == said_own,
		"over a wall of his, it says what the upgrade or remove button does",
		"%s: %s" % [own, night_hud.hint_text()])
	Farm.damage(state, spot, 40)
	await frames(3)
	expect(world.cursor().look() == &"repair"
		and night_hud.hint_text() == I18n.f(&"NHUD_HINT_REPAIR",
			[actions.text_of(&"place"), Names.of(&"wall")]),
		"and hurt, that a click mends it", night_hud.hint_text())

	# **Every hint fits its line**, in both languages and on both devices,
	# right of the house numbers.
	var hint: Label = locate_control("ModeHint") as Label
	var font := hint.get_theme_font(&"font")
	var font_size := hint.get_theme_font_size(&"font_size")
	var widest := 0.0
	var widest_text := ""
	var says := [[&"NHUD_HINT_PLACE", [&"ACT_MOUSE_LEFT", &"ACT_PAD_A"]],
		[&"NHUD_HINT_UPGRADE", [&"ACT_MOUSE_MIDDLE", &"ACT_PAD_LT"]],
		[&"NHUD_HINT_SELL", [&"ACT_MOUSE_RIGHT", &"ACT_PAD_R3"]],
		[&"NHUD_HINT_REPAIR", [&"ACT_MOUSE_LEFT", &"ACT_PAD_A"]]]
	var named: Array = GameData.sorted_names(GameData.DEFENCES.keys()) \
		+ GameData.sorted_names(GameData.BUILDINGS.keys()) + [&"house"]
	for locale in ["en", "pt_BR"]:
		I18n.use(locale)
		for id in named:
			for row in says:
				for key in (row[1] as Array):
					var text := I18n.f(row[0], [I18n.t(key), Names.of(id)])
					var wide := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1,
						font_size).x
					if wide > widest:
						widest = wide
						widest_text = text
	I18n.use("en")
	expect(widest <= hint.size.x, "every hint fits its line",
		"%s: %.0f of %.0f" % [widest_text, widest, hint.size.x])
	var house_numbers: Label = locate_control("HouseNumbers") as Label
	expect(house_numbers != null
		and hint.get_global_rect().position.x >= house_numbers.get_global_rect().end.x,
		"and starts right of the house numbers",
		"%s against %s" % [hint.get_global_rect(), house_numbers.get_global_rect()])

	# **A pad reaches START by focus**: Back puts it on the bar, the D-pad
	# steps nothing while it is there, B takes it off, and A presses.
	await _pad_tap(JOY_BUTTON_BACK)
	await frames(2)
	expect(night_hud.holds_focus() and start.has_focus(), "Back puts the pad on START")
	var before := world.cursor().cell()
	await _pad_tap(JOY_BUTTON_DPAD_RIGHT)
	await frames(2)
	expect(world.cursor().cell() == before and start.has_focus(),
		"the D-pad moves neither the cursor nor the focus off the bar",
		"%s to %s" % [before, world.cursor().cell()])
	await _pad_tap(JOY_BUTTON_B)
	await frames(2)
	expect(not night_hud.holds_focus(), "B hands the pad back to the cursor")
	await _pad_tap(JOY_BUTTON_BACK)
	await frames(2)
	await _pad_tap(JOY_BUTTON_A)
	await until(func() -> bool: return int(state["phase"]) == Phases.NIGHT,
		"START to begin the waves")
	expect(int(state["phase"]) == Phases.NIGHT, "and A on START begins the waves")
	await frames(3)

	# **The waves: the flare, the speed and SKIP share the bar.**
	var flare: Button = locate_control("FlareButton") as Button
	var speed: Button = locate_control("SpeedButton") as Button
	var skip: Button = locate_control("SkipButton") as Button
	expect(flare.is_visible_in_tree() and speed.is_visible_in_tree()
		and skip.is_visible_in_tree() and not start.is_visible_in_tree(),
		"during the waves the bar is the flare, the speed and SKIP")
	var boxes: Array = [flare.get_global_rect(), speed.get_global_rect(),
		skip.get_global_rect()]
	var crossed := false
	for i in boxes.size():
		var box: Rect2 = boxes[i]
		if box.position.x < Hotbar.RIGHT or not Rect2(0, 0, 480, 270).encloses(box):
			crossed = true
		for j in range(i + 1, boxes.size()):
			if box.intersects(boxes[j]):
				crossed = true
	expect(not crossed, "side by side, on screen, right of the hotbar", str(boxes))

	# **On a pad**: Back lands on the flare, the D-pad moves along, A presses.
	await _pad_tap(JOY_BUTTON_BACK)
	await frames(2)
	expect(flare.has_focus(), "at night Back puts the pad on the flare first")
	await _pad_tap(JOY_BUTTON_DPAD_RIGHT)
	await frames(2)
	expect(speed.has_focus(), "the D-pad moves along the bar to the speed")
	var was := driver.speed
	await _pad_tap(JOY_BUTTON_A)
	await frames(2)
	expect(driver.speed != was, "and A cycles it", str(driver.speed))
	await _pad_tap(JOY_BUTTON_B)
	await frames(2)
	expect(not night_hud.holds_focus(), "B gives the pad back")
	driver.set_speed(GameData.SPEEDS[0])
	await frames(2)

	# **The speed cycles 1, 2, 4** on a click.
	var seen: Array = []
	for _i in GameData.SPEEDS.size():
		await click_control("SpeedButton")
		await frames(2)
		seen.append(driver.speed)
	var cycle: Array = (GameData.SPEEDS as Array).slice(1) + [GameData.SPEEDS[0]]
	expect(seen == cycle and speed.text == I18n.f(&"NHUD_SPEED", [driver.speed]),
		"SPEED cycles through the table and says where it is", str(seen))

	# **The flare**: armed, the hint says a click lets it go; gone, its
	# charge is on the button.
	await click_control("FlareButton")
	await frames(2)
	await _point_at(world, spot)
	expect(world.cursor().look() == &"aim"
		and night_hud.hint_text() == I18n.f(&"NHUD_HINT_AIM", [actions.text_of(&"place")]),
		"an armed flare's hint says a click lets it go", night_hud.hint_text())
	await click_cell(spot)
	await until(func() -> bool: return Ability.flares_used(state) > 0, "the flare")
	await frames(2)
	expect(flare.disabled and flare.text == I18n.f(&"NHUD_FLARE_CHARGE",
		[Ability.charge_percent(state)]), "and then the flare shows its charge", flare.text)

	# **SKIP is refused under SKIP_MIN_HOUSE_PERCENT, and says why.**
	state["house_hp"] = maxi(Phases.house_full(state)
		* GameData.SKIP_MIN_HOUSE_PERCENT / 100 - 1, 1)
	await frames(3)
	var refused := Sim.why_not_skip(state)
	var why := Describe.of(StringName(skip.get_meta(&"describes", &"")))
	expect(not refused.is_empty() and skip.disabled and why == Names.refusal(refused),
		"under SKIP_MIN_HOUSE_PERCENT SKIP is dead, with the refusal as its tooltip", why)
	var tooltip: Tooltip = require_control("Tooltip") as Tooltip
	var over := InputEventMouseMotion.new()
	over.position = skip.get_global_rect().get_center()
	over.global_position = over.position
	root.push_input(over)
	await until(func() -> bool: return tooltip.text_showing() == why,
		"the refusal on the tooltip", 20000)
	expect(tooltip.text_showing() == why, "and pointing at it shows the reason",
		tooltip.text_showing())
	await click_control("SkipButton")
	await frames(3)
	expect(int(state["phase"]) == Phases.NIGHT, "a click on it then skips nothing")

	# **Above it, SKIP runs the night out.**
	state["house_hp"] = Phases.house_full(state)
	await frames(3)
	expect(not skip.disabled and Describe.of(StringName(skip.get_meta(&"describes", &"")))
		== I18n.t(&"NHUD_SKIP_TIP"), "with the house whole SKIP is live, and says what it does")
	await click_control("SkipButton")
	await until(func() -> bool: return int(state["phase"]) != Phases.NIGHT,
		"SKIP to run the night out")
	expect(int(state["phase"]) == Phases.RESULT, "and a click runs the night to its end",
		Phases.name_of(int(state["phase"])))
	driver.set_speed(1)
	await close_scene()
	_completed += 1


## 0140 - the day HUD tells the time and says when it is time for bed.
func _case_0140_bedtime() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	var actions := root.get_node_or_null(^"Actions")
	if driver == null or actions == null:
		await close_scene()
		_completed += 1
		return
	var state := driver.state
	await frames(4)
	var clock: Label = require_control("Clock") as Label
	var day: Label = require_control("Day") as Label
	var evening: Label = require_control("DayStatus") as Label
	var bed: Button = require_control("NightButton") as Button
	if clock == null or day == null or evening == null or bed == null:
		await close_scene()
		_completed += 1
		return
	# The clock held where it is put, so a minute is the minute asked for.
	driver.running = false

	# **21:59: dusk, nothing more.**
	state["day_tick"] = Phases.tick_at_minute(21 * 60 + 59)
	await frames(3)
	expect(clock.text == I18n.f(&"DHUD_CLOCK", [21, 59])
		and evening.text == I18n.t(&"DHUD_DUSK")
		and bed.theme_type_variation == UiKit.BED,
		"at 21:59 the clock says so, the line says dusk and GO TO BED is not lit",
		"%s / %s / %s" % [clock.text, evening.text, bed.theme_type_variation])

	# **22:00: a quiet time for bed, naming the key, and the button lit.**
	state["day_tick"] = Phases.tick_at_minute(GameData.BEDTIME_REMINDER_MINUTE)
	await frames(3)
	expect(evening.text == I18n.f(&"DHUD_BEDTIME", [actions.text_of(&"night")])
		and evening.theme_type_variation == UiKit.DIM
		and bed.theme_type_variation == UiKit.BED_LIT,
		"at 22:00 a quiet line names the GO TO BED key, and the button lights up",
		evening.text)
	# On a pad it names the pad's button (0121's names).
	actions.set(&"using_pad", true)
	await frames(2)
	expect(evening.text == I18n.f(&"DHUD_BEDTIME", [I18n.t(&"ACT_PAD_BACK")]),
		"with a pad in hand it names Back", evening.text)
	actions.set(&"using_pad", false)

	# **01:30: the warning, with the minutes he has left.**
	state["day_tick"] = Phases.tick_at_minute(GameData.PASS_OUT_WARNING_MINUTE)
	await frames(3)
	var left := GameData.DAY_END_MINUTE - GameData.PASS_OUT_WARNING_MINUTE
	expect(evening.text == I18n.f(&"DHUD_PASS_OUT_SOON", [left])
		and evening.theme_type_variation == UiKit.WARN
		and clock.theme_type_variation == UiKit.CLOCK_LATE
		and clock.text == I18n.f(&"DHUD_CLOCK", [1, 30]),
		"at 01:30 the line counts the minutes left in the warn colour, the clock too",
		"%s / %s" % [evening.text, clock.text])

	# **It all fits**: the clock left of the day, and the evening's widest
	# line - both languages, both devices - before the resource grid at 210.
	expect(clock.get_global_rect().end.x <= day.get_global_rect().position.x,
		"the clock ends before the day begins",
		"%s against %s" % [clock.get_global_rect(), day.get_global_rect()])
	var font := evening.get_theme_font(&"font")
	var font_size := evening.get_theme_font_size(&"font_size")
	var widest := 0.0
	var widest_text := ""
	for locale in ["en", "pt_BR"]:
		I18n.use(locale)
		for text in [I18n.t(&"DHUD_DUSK"),
				I18n.f(&"DHUD_BEDTIME", [I18n.t(&"ACT_PAD_BACK")]),
				I18n.f(&"DHUD_BEDTIME", ["N"]),
				I18n.f(&"DHUD_PASS_OUT_SOON", [left])]:
			var wide := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1,
				font_size).x
			if wide > widest:
				widest = wide
				widest_text = text
	I18n.use("en")
	expect(evening.position.x + widest <= 206.0,
		"the evening's widest line ends before the resource grid",
		"%s: %.0f from %.0f" % [widest_text, widest, evening.position.x])

	# **23:00: GO TO BED starts the night.**
	state["day_tick"] = Phases.tick_at_minute(23 * 60)
	driver.running = true
	await frames(3)
	await click_control("NightButton")
	await until(func() -> bool: return int(state["phase"]) == Phases.PREPARATION,
		"GO TO BED at 23:00")
	expect(int(state["phase"]) == Phases.PREPARATION,
		"clicking GO TO BED at 23:00 starts the night",
		Phases.name_of(int(state["phase"])))
	await close_scene()
	_completed += 1


## 0141 - the first night is taught: the bed's line after the day's, the
## build step's and START's in the build step, dawn's in the night.
func _case_0141_tutorial() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	var prompt: TutorialPrompt = require_control("TutorialPrompt")
	var house_view: HouseView = require_control("HouseView")
	if driver == null or prompt == null or house_view == null:
		await close_scene()
		_completed += 1
		return
	var state := driver.state
	await frames(3)
	var line: Label = require_control("TutorialLine") as Label
	var arrow: Label = require_control("TutorialArrow") as Label

	# **After the day's five, the bed's line**, over the farmhouse door.
	((state["tutorial"] as Dictionary)["done"] as Array).assign(
		[&"chop", &"plant", &"water", &"sell", &"craft"])
	await until(func() -> bool: return prompt.showing() == &"bed", "the bed's line")
	expect(prompt.visible and prompt.showing() == &"bed"
		and line.text == I18n.t(&"TUT_BED"),
		"after the day's lines comes the bed's", line.text)

	# **In the house it sits over the bed.**
	_stand_at(state, House.porch(state))
	await tap_key(KEY_SPACE)
	await until(func() -> bool: return House.inside(state), "the house")
	await frames(3)
	var bed := House.bed()
	var over := house_view.room_to_screen(Vector2i(bed.position.x + bed.size.x / 2,
		bed.position.y))
	expect(prompt.visible and prompt.showing() == &"bed"
		and absf(arrow.position.x + 2.0 - over.x) < 4.0,
		"in the house the line stays, its pointer over the bed",
		"%s against %s" % [arrow.position, over])

	# **To bed, and the build step's line.**
	var side := Vector2i(-1, -1)
	for y in range(3, House.ROOM.y - 1):
		for x in range(1, House.ROOM.x - 1):
			if side.x < 0 and House.bedside(Vector2i(x, y)):
				side = Vector2i(x, y)
	_stand_at(state, side, Player.NORTH)
	await frames(3)
	await tap_key(KEY_SPACE)
	await until(func() -> bool: return int(state["phase"]) == Phases.PREPARATION,
		"the bed to start the night")
	await until(func() -> bool: return prompt.showing() == &"build",
		"the build step's line", 100000)
	expect(prompt.visible and line.text == I18n.t(&"TUT_BUILD"),
		"in the build step the build line is up", line.text)

	# **A wall down, and START's line, pointing at START.**
	Resources.gain(state, {GameData.WOOD: 200, GameData.STONE: 200})
	expect(Building.place(state, &"wall", SuiteKit.any_buildable(state)),
		"a wall goes down")
	await until(func() -> bool: return prompt.showing() == &"start", "START's line")
	await frames(2)
	var start: Button = require_control("StartButton") as Button
	expect(prompt.visible and line.text == I18n.t(&"TUT_START")
		and start != null and absf(arrow.position.x + 2.0
			- start.get_global_rect().get_center().x) < 4.0
		and arrow.position.y < start.get_global_rect().position.y,
		"then START's line, its pointer down at the button",
		"%s against %s" % [arrow.position, start.get_global_rect() if start else Rect2()])
	var box := line.get_global_rect()
	expect(box.end.y <= Hotbar.AT.y, "and clear of the hotbar", str(box))

	# **START, and dawn's line under the countdown.**
	await click_control("StartButton")
	await until(func() -> bool: return prompt.showing() == &"dawn", "dawn's line")
	await frames(2)
	var countdown: Label = require_control("DawnCountdown") as Label
	expect(prompt.visible and line.text == I18n.t(&"TUT_DAWN")
		and countdown != null and absf(arrow.position.x + 2.0
			- countdown.get_global_rect().get_center().x) < 4.0
		and arrow.position.y >= countdown.get_global_rect().end.y,
		"in the night, dawn's line, its pointer up at the countdown",
		"%s against %s" % [arrow.position, countdown.get_global_rect() if countdown else Rect2()])
	await close_scene()
	_completed += 1


## 0149 - the date beside the clock: SPRING 3, SUMMER 1, in both languages;
## its widest before the purse; and from Year 2 the year on the line under
## it, until the evening needs that line.
func _case_0149_date() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	var day: Label = require_control("Day") as Label
	var evening: Label = require_control("DayStatus") as Label
	var purse: Control = require_control("icon_money") as Control
	if driver == null or day == null or evening == null or purse == null:
		await close_scene()
		_completed += 1
		return
	var state := driver.state
	await frames(4)
	driver.running = false
	state["day_tick"] = Phases.tick_at_minute(12 * 60)

	# **SPRING 3 on day 3, SUMMER 1 on day 15**, in English and Portuguese.
	for row in [[3, "SPRING 3", "PRIMAVERA 3"], [15, "SUMMER 1", "VERÃO 1"]]:
		state["day"] = row[0]
		for locale in ["en", "pt_BR"]:
			I18n.use(locale)
			await frames(3)
			var want: String = row[1] if locale == "en" else row[2]
			expect(day.text == want, "day %d reads %s (%s)" % [row[0], want, locale], day.text)
		I18n.use("en")
	var year_label: Label = require_control("Year") as Label
	expect(year_label != null and year_label.text.is_empty(),
		"and in Year 1 no year is shown", year_label.text if year_label else "")

	# **The widest date ends before the purse**: every season's last day,
	# both languages.
	var font := day.get_theme_font(&"font")
	var font_size := day.get_theme_font_size(&"font_size")
	var widest := 0.0
	var widest_text := ""
	for locale in ["en", "pt_BR"]:
		I18n.use(locale)
		for season in GameData.SEASONS:
			var text := I18n.f(&"DHUD_DATE", [Names.of(season), GameData.SEASON_DAYS])
			var wide := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1,
				font_size).x
			if wide > widest:
				widest = wide
				widest_text = text
	I18n.use("en")
	expect(day.global_position.x + widest < purse.global_position.x,
		"the widest date ends before the purse",
		"%s: %.0f from %.0f, the purse at %.0f" % [widest_text, widest,
			day.global_position.x, purse.global_position.x])

	# **Year 2**: SPRING 1 beside the clock and YEAR 2 under the clock (task
	# 0152 moved it there: the line under the date became the Full Moon's),
	# left of the date, at dusk as by day.
	var clock: Label = require_control("Clock") as Label
	state["day"] = Calendar.year_days() + 1
	for locale in ["en", "pt_BR"]:
		I18n.use(locale)
		await frames(3)
		var year := I18n.f(&"DHUD_YEAR", [2])
		var date := I18n.f(&"DHUD_DATE", [Names.of(&"spring"), 1])
		var wide := font.get_string_size(year, HORIZONTAL_ALIGNMENT_LEFT, -1,
			font_size).x
		expect(day.text == date and year_label.text == year,
			"on day 57 the HUD reads %s, and %s under the clock (%s)" % [date, year, locale],
			"%s / %s" % [day.text, year_label.text])
		expect(year_label.global_position.x + wide < day.global_position.x
			and year_label.global_position.y > clock.global_position.y,
			"and the year sits under the clock, left of the date (%s)" % locale,
			"%s at %s" % [year, year_label.global_position])
	I18n.use("en")
	# Day 58: day 57 is Spring 1 of Year 2, a calm night (task 0154), whose
	# line outranks dusk.
	state["day"] = Calendar.year_days() + 2
	state["day_tick"] = GameData.DUSK_AT_TICK
	await frames(3)
	expect(evening.text == I18n.t(&"DHUD_DUSK") and year_label.text == I18n.f(&"DHUD_YEAR", [2]),
		"at dusk the line is the evening's, and the year stays", evening.text)
	state["day"] = 1
	await close_scene()
	_completed += 1


## 0152 - the Full Moon on the day HUD: FULL MOON IN 4 DAYS on day 3, IN 1 DAY
## on day 6 and TONIGHT on day 7, in both languages, under the date.
func _case_0152_moon_line() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	var line: Label = require_control("DayStatus") as Label
	if driver == null or line == null:
		await close_scene()
		_completed += 1
		return
	var state := driver.state
	await frames(4)
	driver.running = false
	state["day_tick"] = Phases.tick_at_minute(12 * 60)
	var says := {
		3: ["FULL MOON IN 4 DAYS", "LUA CHEIA EM 4 DIAS"],
		6: ["FULL MOON IN 1 DAY", "LUA CHEIA EM 1 DIA"],
		7: ["FULL MOON TONIGHT", "LUA CHEIA HOJE"],
	}
	var font := line.get_theme_font(&"font")
	var font_size := line.get_theme_font_size(&"font_size")
	var widest := 0.0
	for day in [3, 6, 7]:
		state["day"] = day
		for locale in ["en", "pt_BR"]:
			I18n.use(locale)
			await frames(3)
			var want: String = (says[day] as Array)[0 if locale == "en" else 1]
			expect(line.text == want, "day %d at noon reads %s (%s)" % [day, want, locale],
				line.text)
			widest = maxf(widest, font.get_string_size(line.text,
				HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x)
	I18n.use("en")
	# The widest the line can be: a Full Moon six days off, in both languages.
	for locale in ["en", "pt_BR"]:
		I18n.use(locale)
		widest = maxf(widest, font.get_string_size(
			I18n.plural(&"DHUD_FULL_MOON_IN", 6, [6]), HORIZONTAL_ALIGNMENT_LEFT, -1,
			font_size).x)
	I18n.use("en")
	expect(line.global_position.x + widest < 206.0,
		"and the widest moon line ends before the resource grid",
		"%.0f from %.0f" % [widest, line.global_position.x])

	# **Tonight's Full Moon outranks dusk**, and gives way to bedtime.
	state["day"] = 7
	state["day_tick"] = GameData.DUSK_AT_TICK
	await frames(3)
	expect(line.text == I18n.t(&"DHUD_FULL_MOON_TONIGHT"),
		"on day 7 at dusk the line is still the Full Moon's", line.text)
	state["day"] = 8
	await frames(3)
	expect(line.text == I18n.t(&"DHUD_DUSK"),
		"and on an ordinary day at dusk it is the evening's", line.text)
	state["day"] = 1
	await close_scene()
	_completed += 1


## 0154 - the calm night: to bed on Summer 1, START, and the morning report
## shows the calm and the gift - once by keyboard, once by pad.
func _case_0154_calm() -> void:
	for device in ["keyboard", "pad"]:
		await open_scene(MAIN_SCENE)
		var driver: SimDriver = require_control("SimDriver")
		var result: ResultScreen = require_control("ResultScreen") as ResultScreen
		var line: Label = require_control("DayStatus") as Label
		if driver == null or result == null or line == null:
			await close_scene()
			_completed += 1
			return
		var state := driver.state
		await frames(4)
		state["day"] = GameData.SEASON_DAYS + 1
		state["nights_won"] = GameData.SEASON_DAYS
		await frames(3)
		expect(line.text == I18n.t(&"DHUD_CALM_TONIGHT"),
			"on Summer 1 the line under the date says CALM NIGHT (%s)" % device, line.text)
		House.leave(state)
		await frames(2)
		if device == "keyboard":
			await tap_key(KEY_N)
		else:
			await _pad_tap(JOY_BUTTON_BACK)
		await until(func() -> bool: return int(state["phase"]) == Phases.PREPARATION,
			"to bed (%s)" % device)
		var house_view: HouseView = require_control("HouseView")
		await until(func() -> bool: return not house_view.is_showing_bedtime(),
			"the bed beat", 100000)
		await frames(3)
		if device == "keyboard":
			await tap_key(KEY_G)
		else:
			await _pad_tap(JOY_BUTTON_LEFT_STICK)
		await until(func() -> bool: return result.visible, "the morning report (%s)" % device)
		await frames(3)
		var said := _report_lines(result)
		var gift: Array = []
		for id in GameData.sorted_names(GameData.CALM_NIGHT_GIFT.keys()):
			gift.append(I18n.f(&"RES_GAINED", [int(GameData.CALM_NIGHT_GIFT[id]), Names.of(id)]))
		var gift_line := I18n.f(&"RES_INDENT", ["  ".join(gift)])
		expect(said.has(I18n.t(&"RES_CALM_NIGHT")) and said.has(I18n.t(&"RES_GIFT"))
			and said.has(gift_line) and not said.has(I18n.t(&"RES_PAID")),
			"the report says the night was calm and what is on the porch (%s)" % device,
			str(said))
		expect(_outside_the_frame(result).is_empty(), "and all of it fits its frame (%s)" % device,
			str(_outside_the_frame(result)))
		await close_scene()
	_completed += 1


## 0157 - the build step's route preview, by mouse: a wall held over open
## ground on Winter 2 draws a route from each of the five sides, and on Spring
## 2 from the east alone.
func _case_0157_routes() -> void:
	for season in [3, 0]:
		await open_scene(MAIN_SCENE)
		var driver: SimDriver = require_control("SimDriver")
		var world: WorldView = require_control("WorldView")
		if driver == null or world == null:
			await close_scene()
			_completed += 1
			return
		var state := driver.state
		await frames(4)
		state["day"] = season * GameData.SEASON_DAYS + 2
		state["nights_won"] = int(state["day"]) - 1
		await click_control("NightButton")
		await until(func() -> bool: return int(state["phase"]) == Phases.PREPARATION,
			"GO TO BED (%s)" % GameData.SEASONS[season])
		var house_view: HouseView = require_control("HouseView")
		await until(func() -> bool: return not house_view.is_showing_bedtime(),
			"the bed beat to end", 100000)
		Resources.gain(state, {GameData.WOOD: 900, GameData.STONE: 900})
		await frames(3)
		await click_control("Hotbar_wall")
		await frames(2)
		var spot := Vector2i(-1, -1)
		var middle := world.screen_to_cell(Vector2(240.0, 120.0))
		for radius in 6:
			for candidate in Grid.within(middle, radius):
				if spot.x < 0 and Building.why_not(state, &"wall", candidate).is_empty():
					spot = candidate
		await move_mouse_to_cell(spot)
		await frames(3)
		# A route starts beside the spawn cell it came from.
		var route := world.previewed_route()
		var from: Array = []
		for side in GameData.SPAWNS.size():
			var start: Vector2i = Enemies.spawn_cells(state, side)[0]
			for cell in route:
				var apart: Vector2i = (cell as Vector2i) - start
				if absi(apart.x) <= 1 and absi(apart.y) <= 1:
					from.append(side)
					break
		var open := Calendar.open_sides(Phases.night_ahead(state))
		expect(Building.selected(state) == &"wall" and spot.x >= 0 and from == open,
			"a wall held on %s 2 draws a route from each side open tonight"
				% GameData.SEASONS[season],
			"%d cells, from %s, open %s" % [route.size(), from, open])
		await close_scene()
	_completed += 1


## 0158 - the forecast panel: hidden at noon, up at 18:00 and in the build
## step, gone once START is pressed; every line inside it, in both languages,
## for the kinds of night a year has; and the night strip naming the date
## beside the night, its widest clear of the wave counter.
func _case_0158_panel() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	var panel: ForecastPanel = require_control("ForecastPanel") as ForecastPanel
	var hud: NightHud = require_control("NightHud") as NightHud
	if driver == null or panel == null or hud == null:
		await close_scene()
		_completed += 1
		return
	var state := driver.state
	await frames(4)
	# Autumn 7: a Full Moon from three sides.
	state["day"] = 2 * GameData.SEASON_DAYS + 7
	state["nights_won"] = int(state["day"]) - 1
	state["day_tick"] = Phases.tick_at_minute(12 * 60)
	await frames(3)
	expect(not panel.visible, "no forecast at noon")
	state["day_tick"] = Phases.tick_at_minute(18 * 60)
	await frames(3)
	expect(panel.visible and int(panel.shown().get("date", 0)) == Calendar.date(state)
		and bool(panel.shown().get("full_moon", false)),
		"at 18:00 the forecast is up, for today's Full Moon", str(panel.shown()))

	# **Every line inside the panel**, in both languages: plain, Full Moon,
	# boss and calm nights from all four seasons.
	var bad: Array = []
	for date in [3, 7, 14, 15, 21, 28, 35, 42, 43, 49, 52, 56]:
		state["day"] = date
		state["nights_won"] = date - 1
		for locale in ["en", "pt_BR"]:
			I18n.use(locale)
			await frames(2)
			for fault in panel.outside():
				bad.append("%d %s: %s" % [date, locale, fault])
	I18n.use("en")
	expect(bad.is_empty(), "every line of every forecast fits its panel, in both languages",
		str(bad.slice(0, 4)))

	# **In the build step**: Winter 14, to bed at 18:00.
	state["day"] = 4 * GameData.SEASON_DAYS
	state["nights_won"] = int(state["day"]) - 1
	await frames(2)
	await click_control("NightButton")
	await until(func() -> bool: return int(state["phase"]) == Phases.PREPARATION,
		"GO TO BED")
	var house_view: HouseView = require_control("HouseView")
	await until(func() -> bool: return not house_view.is_showing_bedtime(),
		"the bed beat to end", 100000)
	await frames(3)
	expect(panel.visible and StringName(panel.shown().get("boss", &"")) == &"giant"
		and bool(panel.shown().get("full_moon", false)),
		"in the build step the forecast is up: the Giant under a Full Moon",
		str(panel.shown()))
	expect(hud.date_text() == I18n.f(&"DHUD_DATE", [Names.of(&"winter"), 14]),
		"and the night strip names the date beside the night", hud.date_text())

	# **The widest strip**: a boss night in Year 2 and one with a three-digit
	# night, both languages - the night clear of the season's mark, and the
	# date with its marks clear of the wave counter.
	var night_label: Label = require_control("NightNumber") as Label
	var wave_label: Label = require_control("WaveCounter") as Label
	var font := night_label.get_theme_font(&"font")
	var font_size := night_label.get_theme_font_size(&"font_size")
	var tight: Array = []
	for date in [Calendar.year_days() + GameData.SEASON_DAYS,
			2 * Calendar.year_days() + GameData.SEASON_DAYS]:
		state["day"] = date
		for locale in ["en", "pt_BR"]:
			I18n.use(locale)
			await frames(2)
			var night_end := night_label.position.x + font.get_string_size(night_label.text,
				HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
			if night_end >= NightHud.SEASON_MARK_AT.x or hud.date_end() >= wave_label.position.x - 2.0:
				tight.append("%s | %s %.0f-%.0f" % [night_label.text, hud.date_text(),
					night_end, hud.date_end()])
	I18n.use("en")
	expect(tight.is_empty(), "the widest night and date fit the strip, in both languages",
		str(tight))

	# **START, and it goes.**
	state["day"] = 4 * GameData.SEASON_DAYS
	await frames(2)
	await click_control("StartButton")
	await until(func() -> bool: return int(state["phase"]) == Phases.NIGHT, "START")
	await frames(3)
	expect(not panel.visible, "once START is pressed the forecast goes")
	expect(hud.date_text() == I18n.f(&"DHUD_DATE", [Names.of(&"winter"), 14]),
		"and through the waves the strip still names the date", hud.date_text())
	await close_scene()
	_completed += 1


## 0159 - the seasons on screen: the remap's season and the snowfall follow
## the date - off in spring, on in winter, off again with the density - and
## the terrain is never laid again for a season.
func _case_0159_seasons() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	var world: WorldView = require_control("WorldView") as WorldView
	var particles: Particles = require_control("Particles") as Particles
	if driver == null or world == null or particles == null:
		await close_scene()
		_completed += 1
		return
	var state := driver.state
	await frames(4)
	state["day_tick"] = Phases.tick_at_minute(12 * 60)
	state["day"] = 3
	await frames(3)
	var seasons := world.season_view()
	var laid := world.terrain_draws()
	expect(seasons.shader_season() == 0 and not particles.snowing() and particles.flakes() == 0,
		"Spring 3: today's art and no snow",
		"season %d, %d flakes" % [seasons.shader_season(), particles.flakes()])
	var read: Array = []
	for day in [GameData.SEASON_DAYS + 3, 2 * GameData.SEASON_DAYS + 3,
			3 * GameData.SEASON_DAYS + 3]:
		state["day"] = day
		state["nights_won"] = day - 1
		await frames(3)
		read.append(seasons.shader_season())
	expect(read == [1, 2, 3], "the remap follows the date: summer, autumn, winter", str(read))
	expect(particles.snowing() and particles.flakes() > 0, "and on Winter 3 it snows",
		"%d flakes" % particles.flakes())
	expect(world.terrain_draws() == laid,
		"and the terrain was not laid again for any of it",
		"%d against %d" % [world.terrain_draws(), laid])

	# **The density setting turns the snow off**, as it does every particle.
	particles.set_density(0.0)
	await frames(2)
	expect(not particles.snowing() and particles.flakes() == 0,
		"at zero particle density there is no snow", str(particles.flakes()))
	particles.set_density(1.0)

	# **Spring again** in Year 2: the snow stops and the art is today's.
	state["day"] = Calendar.year_days() + 3
	await frames(3)
	expect(seasons.shader_season() == 0 and not particles.snowing(),
		"and Spring 3 of Year 2 is spring again, with no snow")
	state["day"] = 1
	await close_scene()
	_completed += 1


## 0160 - Every skip device opens choices without accidentally choosing one.
func _case_0160_ending() -> void:
	for device in ["keyboard", "pad", "mouse", "keyboard_cancel", "pad_cancel", "roll"]:
		await open_scene(MAIN_SCENE)
		await frames(3)
		var driver: SimDriver = require_control("SimDriver")
		var result: ResultScreen = require_control("ResultScreen")
		var state := driver.state
		I18n.use("pt_BR" if device == "pad" else "en")
		state["day"] = Run.final_night()
		NightRoad.to_night(state)
		NightRoad.park(state)
		(state["killed_by_kind"] as Dictionary)[Calendar.boss_of(Run.final_night())] = 1
		(state["wave"] as Dictionary)["dawn_at"] = int(state["night_tick"]) + 2
		Sim.advance(state, 4)
		await frames(4)
		var credits: CreditsRoll = require_control("CreditsRoll")
		var carry: Button = require_control("PlayOnButton")
		var fresh: Button = require_control("ContinueButton")
		expect(credits.visible and not carry.is_visible_in_tree() and not fresh.is_visible_in_tree(),
			"credits come before both choices (%s)" % device)
		if device == "keyboard":
			await tap_key(KEY_ENTER)
		elif device == "keyboard_cancel":
			await tap_key(KEY_ESCAPE)
		elif device == "pad":
			await _pad_tap(JOY_BUTTON_A)
		elif device == "pad_cancel":
			await _pad_tap(JOY_BUTTON_B)
		elif device == "roll":
			credits._process(100.0)
		else:
			await click_control("SkipCreditsButton")
		await frames(4)
		expect(not credits.visible and Run.is_over(driver.state) and carry.is_visible_in_tree(),
			"skip only dismisses the credits (%s)" % device)
		var title: Label = require_control("ResultTitle")
		expect(title.text == I18n.t(&"END_TITLE") and carry.text == I18n.f(&"RES_PLAY_ON", [2]),
			"ending names the year and the next year (%s)" % device)
		expect(_outside_the_frame(result).is_empty(), "the ending fits (%s)" % device,
			str(_outside_the_frame(result)))
		# **The days behind him** (review of 0160): a whole year is the
		# final night's date, not the date dawn has already moved to.
		var lines: Array = []
		for node in result.find_children("*", "Label", true, false):
			lines.append((node as Label).text)
		var lived := I18n.f(&"RES_RUN_LINE", [Run.final_night(), Phases.nights_won(driver.state)])
		expect(lines.has(lived), "a whole year reads %d days lived (%s)" % [Run.final_night(), device],
			str(lines))
		var wins := int(Save.read_profile()["runs_won"])
		if device == "pad":
			fresh.grab_focus()
			await _pad_tap(JOY_BUTTON_A)
			await frames(4)
			expect(int(driver.state["day"]) == 1 and not Run.is_endless(driver.state),
				"A NEW FARM starts day 1 of a new run")
		else:
			await click_control("PlayOnButton")
			await frames(4)
			expect(Run.is_endless(driver.state) and int(driver.state["phase"]) == Phases.DAY
				and Calendar.date(driver.state) == 57 and House.inside(driver.state),
				"CARRY ON wakes at home on Year 2 Spring 1 (%s)" % device)
			NightRoad.to_night(driver.state)
			Sim.advance(driver.state, 4)
			await frames(3)
			expect(bool(Rewards.last(driver.state).get("calm", false)) and not credits.visible,
				"the calm night banks without replaying the credits (%s)" % device)
		expect(int(Save.read_profile()["runs_won"]) == wins + 1,
			"either choice records the year once (%s)" % device,
			"before %d, after %d" % [wins, int(Save.read_profile()["runs_won"])])
		await close_scene()
	I18n.use("en")
	_completed += 1


## 0167 - walk onto lawn and hold the ordinary interact key to hoe ahead.
func _case_0167_till_grass() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	if driver == null:
		await close_scene()
		_completed += 1
		return
	var state := driver.state
	await frames(4)
	var middle := Vector2i(35, 20)
	var target := middle + Vector2i.RIGHT
	expect(Farm.terrain_at(state, middle) == Farm.Terrain.GRASS
		and Farm.is_empty(state, middle) and Farm.is_empty(state, target), "open grass is walkable")
	_stand_at(state, middle + Vector2i.LEFT, Player.EAST)
	await press_key(KEY_D, true)
	await until(func() -> bool: return Player.cell(state) == middle, "walking onto the lawn")
	await press_key(KEY_D, false)
	await frames(2)
	expect(Player.cell(state) == middle and Player.target(state) == target,
		"the hoe targets the faced lawn after walking")
	await press_key(KEY_SPACE, true)
	await until(func() -> bool: return Farming.is_tilled(state, target), "holding interact to till grass")
	await press_key(KEY_SPACE, false)
	expect(Farming.is_tilled(state, target) and not Farming.is_tilled(state, middle)
		and Farm.terrain_at(state, target) == Farm.Terrain.GRASS,
		"the held key hoes ahead and preserves the lawn's terrain")
	var world: WorldView = require_control("WorldView")
	await frames(3)
	var earth := false
	var turf := false
	for sprite in world._plot_sprites:
		if int(sprite.get_meta("plot_cell", -1)) == Grid.index(target):
			earth = earth or str(sprite.get_meta("plot_art", "")) == "tilled"
			turf = turf or str(sprite.get_meta("plot_art", "")) == "tilled_edge_n"
	expect(earth and turf, "turned earth and its turf border appear in the real view")
	# An open-ground press facing a path has no underfoot hoe fallback.
	_stand_at(state, middle, Player.NORTH)
	state["terrain"][Grid.index(middle + Vector2i.UP)] = Farm.Terrain.PATH
	await hold_key(KEY_SPACE, 40)
	expect(not Farming.is_tilled(state, middle), "facing a path never hoes under the farmer's feet")
	await close_scene()
	_completed += 1


## 0168/0170 - the strip now exposes just this season's numbered choices.
func _case_0168_seed_pages() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	if driver == null:
		await close_scene()
		_completed += 1
		return
	var state := driver.state
	var language := I18n.locale()
	I18n.use("pt_BR")
	I18n.relabel(_scene)
	var ids := Farming.in_season(state)
	await frames(2)
	var before := State.hash_of(state)
	driver.set_process(false)
	await click_control("SeedNext")
	await frames(2)
	expect(State.hash_of(state) == before, "browsing the seed strip does not write game state")
	for id in Farming.seeds():
		var row := require_control("seed_%s" % id) as Label
		expect(row != null and row.visible == (id in ids), "the HUD contains exactly this season's crops")
	await tap_key(KEY_4)
	expect(Farming.selected_seed(state) == ids[3], "4 chooses the fourth spring crop")
	await tap_key(KEY_6)
	expect(Farming.selected_seed(state) == ids[3], "an unused seed slot cannot select an off-season crop")
	Shop.open(state)
	Shop.show_tab(state, Shop.BUY)
	await frames(3)
	var row := require_control("seed_label_%s" % ids[0]) as Label
	if row != null:
		var scroll := row.get_parent().get_parent().get_parent() as ScrollContainer
		scroll.ensure_control_visible(row)
		await frames(3)
		expect(scroll.get_global_rect().encloses(row.get_global_rect()), "a translated seed choice fits the stall viewport")
	await click_control("sow_%s" % ids[0])
	expect(Farming.selected_seed(state) == ids[0], "the stall picker chooses an in-season crop")
	Shop.close(state)
	driver.set_process(true)
	I18n.use(language)
	await close_scene()
	_completed += 1


## 0169 - real keys, clicks and synthetic bumpers visit the same ledger pages.
func _case_0169_inventory() -> void:
	await open_scene(MAIN_SCENE)
	var driver := require_control("SimDriver") as SimDriver
	var panel := require_control("InventoryPanel") as InventoryPanel
	if driver == null or panel == null:
		await close_scene()
		_completed += 1
		return
	var language := I18n.locale()
	I18n.use("pt_BR")
	driver.set_process(false)
	var before := State.hash_of(driver.state)
	await tap_key(KEY_I)
	await frames(2)
	expect(panel.is_open(), "the ledger opens through its bound key")
	expect((require_control("InventoryNext") as Button).text.contains("E"),
		"the page arrow names its current keyboard binding")
	var count := panel.page_count()
	var seen: Array = []
	for page in count:
		expect(panel.current_page() == page, "keyboard visits page %d" % page)
		var frame := require_control("InventoryFrame") as Control
		expect(Rect2(Vector2.ZERO, Vector2(480,270)).encloses(frame.get_global_rect()),
			"the inventory frame fits the native viewport")
		for line in panel.page_rows():
			if line.has("tool"):
				continue
			var id := StringName(line["id"])
			seen.append(id)
			var row := require_control("inv_%s" % id) as Control
			var label := require_control("inv_name_%s" % id) as Label
			expect(row != null and frame.get_global_rect().encloses(row.get_global_rect()),
				"the whole %s row fits its frame" % id)
			expect(label != null and label.text.contains(Names.of(id)), "the page names %s in Portuguese" % id)
		await tap_key(KEY_E)
		await frames(2)
	expect(seen.size() == GameData.RESOURCES.size(), "the keyboard visits every resource exactly once")
	for page in count:
		expect(panel.current_page() == page, "mouse visits page %d" % page)
		await click_control("InventoryNext")
		await frames(2)
	for group in Inventory.groups(driver.state):
		await click_control("inv_tab_%s" % group["name"])
		await frames(2)
		expect(panel._pages[panel.current_page()]["name"] == group["name"], "a category tab opens its first page")
	panel.select_group(&"materials")
	for page in count:
		expect(panel.current_page() == page, "pad visits page %d" % page)
		await _pad_tap(JOY_BUTTON_RIGHT_SHOULDER)
		await frames(2)
	expect((require_control("InventoryNext") as Button).text.contains("RB"),
		"the page arrow follows the pad binding after a bumper event")
	await _pad_tap(JOY_BUTTON_LEFT_SHOULDER)
	expect(panel.current_page() == count - 1, "the previous bumper wraps to the last page")
	await tap_key(KEY_Q)
	expect(panel.current_page() == count - 2, "the previous key moves back one page")
	expect(State.hash_of(driver.state) == before, "all navigation leaves the simulation unchanged")
	await tap_key(KEY_I)
	expect(not panel.is_open(), "the inventory closes through its bound key")
	Resources.add(driver.state, GameData.MONEY, 123)
	await frames(2)
	var held := Resources.amount(driver.state, GameData.MONEY)
	expect((require_control("res_money") as Label).text.contains(str(held))
		and (require_control("Money") as Label).text.contains(str(held)),
		"both HUD money displays follow the ledger after a gain")
	I18n.use(language)
	await close_scene()
	_completed += 1


## 0170 - buy real packets, choose the potato slot, and sow through SPACE.
func _case_0170_seeds() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	if driver == null:
		await close_scene()
		_completed += 1
		return
	var state := driver.state
	state["held"][GameData.POTATO_SEED] = 0
	var money := Resources.amount(state, GameData.MONEY)
	Shop.open(state)
	Shop.show_tab(state, Shop.BUY)
	await frames(3)
	var buy := require_control("buy_one_potato_seed") as Button
	if buy != null:
		var scroll := buy.get_parent().get_parent().get_parent() as ScrollContainer
		scroll.ensure_control_visible(buy)
		await frames(3)
	await click_control("buy_one_potato_seed")
	await frames(2)
	expect(Resources.amount(state, GameData.POTATO_SEED) == 1 and Resources.amount(state, GameData.MONEY) == money - 4, "the stall sells a potato packet for $4")
	await tap_key(KEY_ESCAPE)
	await frames(2)
	await tap_key(KEY_3)
	expect(Farming.selected_seed(state) == GameData.POTATO, "slot 3 selects spring potatoes")
	var cell: Vector2i = Farming.field_cells(state)[0]
	_stand_at(state, cell + Vector2i.UP, Player.SOUTH)
	await frames(2)
	await press_key(KEY_SPACE, true)
	await until(func() -> bool: return Farming.is_tilled(state, cell), "SPACE tills the potato bed")
	await press_key(KEY_SPACE, false)
	await frames(2)
	await press_key(KEY_SPACE, true)
	await until(func() -> bool: return Farming.crop_on(state, cell) == GameData.POTATO, "SPACE sows the bought packet")
	await press_key(KEY_SPACE, false)
	expect(Resources.amount(state, GameData.POTATO_SEED) == 0 and Resources.amount(state, GameData.MONEY) == money - 4, "planting consumes only the bought packet")
	await close_scene()
	_completed += 1


## 0171 - SPACE can till in winter, but sowing has a visible refusal.
func _case_0171_winter() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	if driver == null:
		await close_scene()
		_completed += 1
		return
	var state := driver.state
	state["day"] = GameData.SEASON_DAYS * 3 + 2
	Farming.morning(state)
	var cell: Vector2i = Farming.field_cells(state)[0]
	_stand_at(state, cell + Vector2i.UP, Player.SOUTH)
	await frames(3)
	await press_key(KEY_SPACE, true)
	await until(func() -> bool: return Farming.is_tilled(state, cell), "SPACE tills a winter bed")
	await press_key(KEY_SPACE, false)
	await frames(3)
	var packets := Resources.amount(state, GameData.CARROT_SEED)
	await press_key(KEY_SPACE, true)
	await frames(20)
	await press_key(KEY_SPACE, false)
	expect(Farming.crop_on(state, cell) == &"" and not Player.is_busy(state), "winter SPACE cannot start a sowing action")
	expect(Resources.amount(state, GameData.CARROT_SEED) == packets, "winter refusal consumes no packets")
	var main := _scene
	var world := require_control("WorldView")
	var tooltip := require_control("Tooltip")
	expect(main._target_cell() == cell and world._highlight_cell == cell, "the refused bed keeps its highlight")
	expect(tooltip._world_text == I18n.t(&"WHY_NO_OUTDOOR_GROWTH"), "the highlight's tooltip explains winter")
	var badge := require_control("SeedPage") as Label
	if badge != null:
		expect(badge.text == I18n.t(&"DHUD_NO_SEEDS"), "the winter seed strip explains outdoor dormancy")
		expect(badge.autowrap_mode == TextServer.AUTOWRAP_WORD_SMART and badge.position.y == 46 and badge.size.x <= 158, "the winter explanation fits the seed rows instead of overflowing the pager")
	await close_scene()
	_completed += 1


## 0172 - SPACE picks once; the existing REMOVE action hoes the standing plant.
func _case_0172_regrow() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	if driver == null:
		await close_scene()
		_completed += 1
		return
	var state := driver.state
	SuiteKit.crop_supplies(state, GameData.STRAWBERRY)
	Farming.select_seed(state, GameData.STRAWBERRY)
	var cell: Vector2i = Farming.field_cells(state)[0]
	Farming.act(state, cell)
	Farming.act(state, cell)
	Farming.plot(state, cell)["growth"] = Farming.days_to_grow(GameData.STRAWBERRY)
	state["water_can"] = 0
	_stand_at(state, cell + Vector2i.UP, Player.SOUTH)
	await frames(2)
	var before := Resources.amount(state, GameData.STRAWBERRY)
	await press_key(KEY_SPACE, true)
	await until(func() -> bool: return bool(Farming.plot(state, cell).get("regrowing", false)), "SPACE picks strawberries and leaves their plant")
	await press_key(KEY_SPACE, false)
	await frames(3)
	expect(Resources.amount(state, GameData.STRAWBERRY) == before + 2, "one SPACE harvest pays once")
	var world := require_control("WorldView")
	var regrow := false
	for sprite in world._plot_sprites:
		if sprite.get_meta("plot_cell", -1) == Grid.index(cell) and sprite.get_meta("plot_art", "") == "strawberry_regrow":
			regrow = true
	expect(regrow, "the picked crop draws its regrowth frame")
	var tooltip := require_control("Tooltip")
	expect(tooltip._world_text.contains(I18n.f(&"DHUD_HOE_CLEAR", [root.get_node("Actions").text_of(&"remove")])), "the highlighted plant explains how to clear with the hoe")
	await click_cell(cell, MOUSE_BUTTON_RIGHT)
	await frames(4)
	expect(Farming.plot(state, cell) == Farming.EMPTY_PLOT, "REMOVE clears the standing plant with the hoe")
	expect(Resources.amount(state, GameData.STRAWBERRY) == before + 2, "the hoe gives no second harvest")
	Farming.act(state, cell)
	Farming.plot(state, cell)["growth"] = Farming.days_to_grow(GameData.STRAWBERRY)
	Farming.act(state, cell)
	await _pad_tap(JOY_BUTTON_RIGHT_STICK)
	await frames(4)
	expect(Farming.plot(state, cell) == Farming.EMPTY_PLOT, "the pad REMOVE button also clears a regrowing plant")
	await close_scene()
	_completed += 1


## 0173 - both workshop input paths order once and show tomorrow's delivery.
func _case_0173_upgrade() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	if driver == null:
		await close_scene()
		_completed += 1
		return
	var state := driver.state
	state["held"][GameData.MONEY] = 1000
	state["held"][GameData.IRON] = 100
	var bench: Vector2i = Farm.cells_with(state, &"workshop")[0]
	_stand_at(state, bench + Vector2i.UP, Player.SOUTH)
	await frames(3)
	await click_control("WorkshopToolsTab")
	await frames(3)
	# **The mouse's, both orders** (review of 0173, 2026-10-09). The keyboard
	# half used to focus the row from code and press Enter on it, but nothing
	# a player can press reaches this list: the station panels are mouse-only,
	# and how the keyboard and the pad get in is the owner's call.
	await click_control("make_upgrade_axe_iron")
	await until(func() -> bool: return state["tools"]["pending"].has("axe"), "a mouse axe order finishes pending tomorrow")
	await frames(3)
	expect(ToolTiers.tier(state, &"axe") == 0 and (require_control("WorkshopToolPending") as Label).visible, "the workshop shows pending while the old axe remains usable")
	await click_control("make_upgrade_can_iron")
	await until(func() -> bool: return state["tools"]["pending"].has("can"), "a mouse can order finishes pending tomorrow")
	await frames(3)
	expect(ToolTiers.tier(state, &"can") == 0 and state["tools"]["pending"].size() == 2, "each input ordered one upgrade")
	var gold := require_control("make_upgrade_axe_gold") as Button
	expect(gold != null and gold.disabled, "gold stays visible and refused")
	var frame := require_control("WorkshopFrame") as Control
	expect(Rect2(Vector2.ZERO, Vector2(480, 270)).encloses(frame.get_global_rect()), "the upgrade list fits the native viewport", str(frame.get_global_rect()))
	await tap_key(KEY_I)
	await frames(2)
	var inventory := require_control("InventoryPanel") as InventoryPanel
	inventory.select_group(&"tools")
	await frames(2)
	expect(inventory.page_rows().size() == 5 and (require_control("inv_tool_pending_axe") as Label).visible, "inventory shows the five held tools and pending delivery")
	await close_scene()
	_completed += 1


## 0174 - the same held SPACE and southward walk cover three times the field.
func _case_0174_area() -> void:
	var wet_counts: Array = []
	for level in [0, 1]:
		await open_scene(MAIN_SCENE)
		var driver: SimDriver = require_control("SimDriver")
		if driver == null:
			await close_scene()
			_completed += 1
			return
		var state := driver.state
		driver.set_speed(1)
		var row: Array = []
		for y in range(20, 23):
			for x in range(30, 33):
				var at := Vector2i(x, y)
				state["terrain"][Grid.index(at)] = Farm.Terrain.GRASS
				state["occupants"].erase(Grid.index(at))
				state["plots"][Grid.index(at)] = {"crop": GameData.CARROT, "growth": 0, "watered": false}
				row.append(at)
		state["grid_version"] += 1
		state["tools"]["can"] = level
		state["tech_owned"].append(&"full cans")
		state["water_can"] = Farming.can_capacity(state)
		state["terrain"][Grid.index(Vector2i(31, 19))] = Farm.Terrain.GRASS
		state["occupants"].erase(Grid.index(Vector2i(31, 19)))
		_stand_at(state, Vector2i(31, 19), Player.SOUTH)
		await frames(3)
		var view := require_control("WorldView") as WorldView
		expect(view.highlighted_cells().size() == 1 + level * 2, "the next held-key stroke highlights its tier's area")
		expect(view._highlight.get_index() > view._plots.get_index(), "soil and crop sprites cannot cover the area frames")
		var carried := Farming.water_carried(state)
		await press_key(KEY_SPACE, true)
		await press_key(KEY_S, true)
		await until(func() -> bool: return Farming.is_watered(state, Vector2i(31, 22)), "held SPACE reaches the third row", 900)
		await press_key(KEY_S, false)
		await press_key(KEY_SPACE, false)
		await frames(3)
		var wet := 0
		for at in row:
			if Farming.is_watered(state, at):
				wet += 1
		wet_counts.append(wet)
		expect(wet == 3 * (1 + level * 2), "three row steps cover the whole iron strip or one basic column", str(wet))
		expect(Farming.water_carried(state) == carried - wet, "holding interact spends exactly one per plot, once")
		var water := require_control("WaterCan") as Label
		expect(water.text == I18n.f(&"DHUD_WATER", [Farming.water_carried(state), Farming.can_capacity(state)]), "the live HUD includes both the tier and full cans")
		await close_scene()
	expect(wet_counts == [3, 9], "an iron can covers nine plots in the steps a basic can needs for three")
	_completed += 1


## 0175 - a real SPACE starts the delivered axe's faster work timer.
func _case_0175_swings() -> void:
	var timers: Array = []
	for level in [0, 1]:
		await open_scene(MAIN_SCENE)
		var driver: SimDriver = require_control("SimDriver")
		if driver == null:
			await close_scene()
			_completed += 1
			return
		var state := driver.state
		driver.set_speed(1)
		state["tools"]["axe"] = level
		state["tech_owned"].append(&"sharp tools")
		var tree := Vector2i(-1, -1)
		for candidate in Farm.cells_with(state, &"tree"):
			var cell: Vector2i = candidate
			if Farm.walkable(state, cell + Vector2i.DOWN):
				tree = cell
				break
		expect(tree.x >= 0, "a tree has a walkable southern neighbour")
		if tree.x < 0:
			await close_scene()
			_completed += 1
			return
		_stand_at(state, tree + Vector2i.DOWN, Player.NORTH)
		await frames(3)
		var wood := Resources.amount(state, GameData.WOOD)
		await press_key(KEY_SPACE, true)
		await until(func() -> bool: return Player.is_busy(state), "SPACE starts chopping")
		var action: Dictionary = state["player"]["action"]
		timers.append(int(action.get("total", -1)))
		expect(action.get("verb", &"") == &"chop" and int(action.get("total", -1)) == (27 if level == 0 else 18), "real input reads both the held axe and sharp tools", str(action))
		await until(func() -> bool: return Farm.occupant(state, tree).get("id", &"") == &"stump", "the held SPACE fells this tree")
		await press_key(KEY_SPACE, false)
		expect(Resources.amount(state, GameData.WOOD) == wood + 3, "faster real-input work pays the same yield once")
		await close_scene()
	expect(timers == [27, 18], "the iron axe starts a third shorter timer with the same sharp-tools tech")
	_completed += 1


## 0176 - real SPACE refuses a basic pickaxe, then mines with delivered iron.
func _case_0176_gold() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	if driver == null:
		await close_scene()
		_completed += 1
		return
	var state := driver.state
	driver.set_speed(1)
	var gold: Vector2i = Farm.cells_with(state, &"gold_ore")[0]
	for offset in Farming.NEIGHBOURS:
		if Farm.walkable(state, gold + offset):
			_stand_at(state, gold + offset, Farming.NEIGHBOURS.find(-offset))
			break
	await frames(3)
	await press_key(KEY_SPACE, true)
	await frames(5)
	await press_key(KEY_SPACE, false)
	expect(not Player.is_busy(state) and not Farm.occupant(state, gold).has("hp"), "spring SPACE cannot work gold")
	state["day"] = GameData.SEASON_DAYS * 2 + 1
	for locale in ["en", "pt_BR"]:
		I18n.use(locale)
		await frames(3)
		await press_key(KEY_SPACE, true)
		await frames(5)
		await press_key(KEY_SPACE, false)
		var tooltip := require_control("Tooltip")
		expect(not Player.is_busy(state) and not Farm.occupant(state, gold).has("hp"), "a basic pickaxe cannot start the autumn gold timer")
		expect(tooltip._world_text.contains(Names.refusal([&"WHY_GATHER_TOOL", &"pickaxe_iron"])), "the real highlight explains the required iron pickaxe in %s" % locale)
	state["tools"]["pickaxe"] = 1
	await frames(3)
	var before := Resources.amount(state, GameData.GOLD)
	await press_key(KEY_SPACE, true)
	await until(func() -> bool: return Player.is_busy(state), "iron starts a real gold swing")
	expect(int(state["player"]["action"].get("total", -1)) == 80, "iron gold mining starts the exact 80-tick timer")
	await until(func() -> bool: return Farm.occupant(state, gold).is_empty(), "held SPACE mines gold with an iron pickaxe", 2400)
	await press_key(KEY_SPACE, false)
	expect(Resources.amount(state, GameData.GOLD) == before + 1, "real gold mining gives its yield exactly once")
	I18n.use("en")
	await close_scene()
	_completed += 1


## Follow-up to the review of 0160-0176 (2026-10-09). Ordering an upgrade
## with the mouse queues it and chooses nothing: SPACE at the bench still
## makes the bench's own recipe, and a row taking the focus leaves the choice
## alone. And a starter bed's grass edge stops at the lawn the hoe turns
## beside it, and comes back when that plot fades - the terrain laid once.
func _case_followup_0176_review() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	var world: WorldView = require_control("WorldView") as WorldView
	if driver == null or world == null:
		await close_scene()
		_completed += 1
		return
	var state := driver.state
	state["held"][GameData.MONEY] = 1000
	state["held"][GameData.IRON] = 100
	state["held"][GameData.WOOD] = 100
	var bench: Vector2i = Building.anchor_of(state, Farm.cells_with(state, &"workshop")[0])
	var own := Crafting.selected_at(state, &"workshop")
	_stand_at(state, Farm.cells_with(state, &"workshop")[0] + Vector2i.UP, Player.SOUTH)
	await frames(3)
	await click_control("WorkshopToolsTab")
	await frames(3)
	await click_control("make_upgrade_axe_iron")
	await until(func() -> bool: return state["tools"]["pending"].has("axe"),
		"a mouse order of the iron axe")
	await frames(2)
	var clicked := require_control("make_upgrade_can_iron") as Button
	var frame := require_control("WorkshopFrame") as Control
	var focused := world.get_viewport().gui_get_focus_owner()
	expect(Crafting.selected_at(state, &"workshop") == own
		and clicked != null and clicked.focus_mode == Control.FOCUS_NONE
		and frame != null and (focused == null or not frame.is_ancestor_of(focused)),
		"the order changes nothing the bench makes, and leaves no row focused for SPACE to press",
		"%s, focus on %s" % [Crafting.selected_at(state, &"workshop"), focused])
	var queued := Crafting.queue_at(state, bench).size()
	await tap_key(KEY_SPACE)
	await until(func() -> bool: return Crafting.queue_at(state, bench).size() == queued + 1,
		"SPACE at the bench after an upgrade order")
	var queue := Crafting.queue_at(state, bench)
	expect(not queue.is_empty() and StringName(queue.back()) == own,
		"and SPACE queues the bench's own recipe", str(queue))

	# **The bed's edge and the hoe.**
	var edges := world.get_node("TerrainEdges") as TileMapLayer
	var bed := Vector2i(-1, -1)
	var lawn := Vector2i(-1, -1)
	var bit := -1
	for at in Farm.cells_of(state, Farm.Terrain.SOIL):
		for side in WorldView.EDGE_NEIGHBOURS.size():
			var next: Vector2i = at + WorldView.EDGE_NEIGHBOURS[side]
			if Grid.in_bounds(next) and Farm.terrain_at(state, next) == Farm.Terrain.GRASS \
					and Farm.is_empty(state, next) and not Farming.is_tilled(state, next):
				bed = at
				lawn = next
				bit = side
				break
		if bit >= 0:
			break
	var laid := world.terrain_draws()
	expect(bit >= 0 and maxi(edges.get_cell_atlas_coords(bed).x, 0) & (1 << bit),
		"fixture: a starter bed draws grass toward the lawn beside it", "%s %s" % [bed, lawn])
	Farming.act(state, lawn)
	await frames(3)
	expect(Farming.is_tilled(state, lawn) and not (maxi(edges.get_cell_atlas_coords(bed).x, 0) & (1 << bit)),
		"hoed, that lawn takes the bed's grass edge with it",
		str(edges.get_cell_atlas_coords(bed)))
	state["plots"].erase(Grid.index(lawn))
	await frames(3)
	expect(maxi(edges.get_cell_atlas_coords(bed).x, 0) & (1 << bit) and world.terrain_draws() == laid,
		"and faded back to lawn it gets it back, the terrain never laid again",
		"%s, %d against %d" % [edges.get_cell_atlas_coords(bed), world.terrain_draws(), laid])
	await close_scene()
	_completed += 1


## 0177 - a real SPACE at a big stump: refused to the basic axe with the
## iron axe named; with the iron axe, held SPACE from the cell beside the
## stump's far corner fells the whole thing, the view chipped from the first
## swing to the last, for the levers' hardwood.
func _case_0177_hardwood() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	var world: WorldView = require_control("WorldView") as WorldView
	if driver == null or world == null:
		await close_scene()
		_completed += 1
		return
	var state := driver.state
	driver.set_speed(1)
	var anchor := Building.anchor_of(state, Farm.cells_with(state, &"hardwood_stump")[0])
	var cells: Array = Building.footprint(&"hardwood_stump", anchor)
	var stood := false
	for cell in cells:
		if cell == anchor:
			continue
		for offset in Farming.NEIGHBOURS:
			var beside: Vector2i = cell + offset
			if not cells.has(beside) and Farm.walkable(state, beside):
				_stand_at(state, beside, Farming.NEIGHBOURS.find(-offset))
				stood = true
				break
		if stood:
			break
	expect(stood, "fixture: a free cell beside one of the stump's non-anchor cells")
	await frames(3)
	await press_key(KEY_SPACE, true)
	await frames(5)
	await press_key(KEY_SPACE, false)
	var tooltip := require_control("Tooltip")
	expect(not Player.is_busy(state) and Gathering.swings_left(state, anchor) == int(GameData.GATHERING[&"hardwood_stump"]["hits"])
		and tooltip._world_text.contains(Names.refusal([&"WHY_GATHER_TOOL", &"axe_iron"])),
		"a basic axe cannot start on the big stump, and the highlight names the iron axe")
	state["tools"]["axe"] = 1
	await frames(3)
	var before := Resources.amount(state, GameData.HARDWOOD)
	await press_key(KEY_SPACE, true)
	await until(func() -> bool: return Gathering.swings_left(state, anchor) < int(GameData.GATHERING[&"hardwood_stump"]["hits"]),
		"an iron axe's first swing lands", 600)
	await frames(2)
	var chipped := false
	for sprite in world.find_children("Prop_*", "Sprite2D", true, false):
		if StringName(sprite.get_meta("prop_art", &"")) == &"hardwood_stump_chipped":
			chipped = true
	expect(chipped, "from the first swing the stump is drawn chipped")
	await until(func() -> bool: return Farm.is_empty(state, anchor), "held SPACE fells the whole stump", 3000)
	await press_key(KEY_SPACE, false)
	var empty := true
	for cell in cells:
		empty = empty and Farm.is_empty(state, cell)
	expect(empty and Resources.amount(state, GameData.HARDWOOD)
		== before + int(GameData.GATHERING[&"hardwood_stump"]["yield"][GameData.HARDWOOD]),
		"all four cells go and the hardwood arrives once")
	await close_scene()
	_completed += 1


## 0178 - a copper sprinkler put down by day from the build list: B, its row,
## a click on the farm; paid for, and its tooltip says what it waters.
func _case_0178_sprinkler() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	if driver == null:
		await close_scene()
		_completed += 1
		return
	var state := driver.state
	Resources.gain(state, Building.cost_of(&"copper_sprinkler"))
	var spot := Vector2i(-1, -1)
	var here := Player.cell(state)
	# Below and to the right of him: clear of the seed list and of the
	# lines and buttons along the bottom.
	for dy in range(1, 5):
		for dx in range(1, 6):
			var cell := here + Vector2i(dx, dy)
			if spot == Vector2i(-1, -1) and Building.can_place(state, &"copper_sprinkler", cell):
				spot = cell
	expect(spot != Vector2i(-1, -1), "fixture: room for a sprinkler near the farmer")
	await hold_key(KEY_B, 4)
	await until(func() -> bool: return Building.is_active(state), "build mode to open by day")
	var row := require_control("build_copper_sprinkler") as Button
	expect(row != null and row.get_global_rect().end.y <= 270.0,
		"the day's build list has the copper sprinkler, on the screen")
	await click_control("build_copper_sprinkler")
	await until(func() -> bool: return Building.selected(state) == &"copper_sprinkler",
		"the sprinkler to be selected")
	var copper := Resources.amount(state, GameData.COPPER)
	await click_cell(spot)
	await until(func() -> bool:
		return StringName(Farm.occupant(state, spot).get("id", &"")) == &"copper_sprinkler",
		"a click on the farm to put it down")
	expect(Resources.amount(state, GameData.COPPER) < copper, "and it was paid for in copper")
	expect(Describe.building(&"copper_sprinkler").contains(I18n.f(&"DESC_SPRINKLES", [4])),
		"its description says it waters four plots each morning")
	await hold_key(KEY_B, 4)
	await close_scene()
	_completed += 1


## 0180 - the bar through real input: a fish landed with SPACE, with a click
## on the farm and with the pad's A - the same press to the bar - which is on
## screen while it runs and gone when the fish is in.
func _case_0180_minigame() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	var bar := require_control("FishingBar") as FishingBar
	if driver == null or bar == null:
		await close_scene()
		_completed += 1
		return
	var state := driver.state
	driver.set_speed(1)
	var water := Vector2i(-1, -1)
	var shore := Vector2i(-1, -1)
	var facing := Player.SOUTH
	for found in Farm.cells_of(state, Farm.Terrain.WATER):
		for side in Player.FACING_STEPS.size():
			var dry: Vector2i = found - Player.FACING_STEPS[side]
			if water == Vector2i(-1, -1) and Farm.walkable(state, dry):
				water = found
				shore = dry
				facing = side
	expect(water != Vector2i(-1, -1), "fixture: a shore to fish from")
	for device in ["keyboard", "mouse", "pad"]:
		_stand_at(state, shore, facing)
		await frames(2)
		expect(Fishing.begin(state, water), "a line goes in (%s)" % device)
		state["fishing"]["left"] = 1
		await until(func() -> bool: return Fishing.is_biting(state), "the bite (%s)" % device)
		# The whole bar green and one hit to land it: the judgement is the
		# headless suite's; this is the three ways of pressing.
		state["fishing"]["zone_at"] = 0
		state["fishing"]["zone"] = int(GameData.FISHING["bar_units"])
		state["fishing"]["needs"] = 1
		await frames(2)
		expect(bar.shown() and bar.zone_rect().size.x > 0, "the bar is on screen while it runs (%s)" % device)
		var before := Resources.amount(state, GameData.FISH)
		match device:
			"keyboard":
				await tap_key(KEY_SPACE)
			"mouse":
				await click_cell(shore + Player.FACING_STEPS[(facing + 2) % 4] * 2)
			"pad":
				await _pad_tap(JOY_BUTTON_A)
		await until(func() -> bool: return Resources.amount(state, GameData.FISH) > before,
			"a %s press to land the fish" % device)
		expect(Resources.amount(state, GameData.FISH) == before + 1 and not Fishing.is_casting(state),
			"a %s press on the green lands one fish" % device)
		await frames(2)
		expect(not bar.shown(), "and the bar goes with it (%s)" % device)
	await close_scene()
	_completed += 1


## Task 0181: at the water with the iron rod, the bait button says what is
## on. E, a click on it and the right shoulder step it on, Q and the left
## shoulder back; SPACE then casts with it, and the worm goes on the hook.
## With the bamboo rod there is nothing to choose.
func _case_0181_bait() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	var hud := require_control("DayHud") as DayHud
	var button := require_control("BaitButton") as Button
	if driver == null or hud == null or button == null:
		await close_scene()
		_completed += 1
		return
	var state := driver.state
	driver.set_speed(1)
	var water := Vector2i(-1, -1)
	var shore := Vector2i(-1, -1)
	var facing := Player.SOUTH
	for found in Farm.cells_of(state, Farm.Terrain.WATER):
		for side in Player.FACING_STEPS.size():
			var dry: Vector2i = found - Player.FACING_STEPS[side]
			if water == Vector2i(-1, -1) and Farm.walkable(state, dry):
				water = found
				shore = dry
				facing = side
	expect(water != Vector2i(-1, -1), "fixture: a shore to fish from")
	_stand_at(state, shore, facing)
	await frames(2)
	expect(not button.visible and not hud.shows_bait(), "with the bamboo rod there is no bait to choose")
	state["tools"]["rod"] = 2
	Resources.add(state, GameData.WORM, 2)
	Resources.add(state, GameData.BAIT, 1)
	await frames(2)
	expect(button.visible and hud.shows_bait() and Fishing.bait_of(state) == &"",
		"with the iron rod at the water the bait button is up, nothing on", button.text)
	await tap_key(KEY_E)
	await frames(2)
	expect(Fishing.bait_of(state) == GameData.WORM and button.text.contains(Names.of(GameData.WORM)),
		"E puts the worm on, and the button says so", button.text)
	await click_control("BaitButton")
	await frames(2)
	expect(Fishing.bait_of(state) == GameData.BAIT and not Fishing.is_casting(state) and not Player.is_busy(state),
		"a click on it steps to the fish bait and casts nothing", button.text)
	await tap_key(KEY_Q)
	await frames(2)
	expect(Fishing.bait_of(state) == GameData.WORM, "Q steps back to the worm")
	await _pad_tap(JOY_BUTTON_RIGHT_SHOULDER)
	await frames(2)
	expect(Fishing.bait_of(state) == GameData.BAIT, "the right shoulder steps it on")
	await _pad_tap(JOY_BUTTON_LEFT_SHOULDER)
	await frames(2)
	expect(Fishing.bait_of(state) == GameData.WORM, "and the left shoulder back")
	var worms := Resources.amount(state, GameData.WORM)
	await tap_key(KEY_SPACE)
	await until(func() -> bool: return Fishing.is_casting(state), "the cast with a worm on")
	expect(Resources.amount(state, GameData.WORM) == worms - 1
		and StringName(Fishing.cast_of(state).get("bait", &"")) == GameData.WORM,
		"SPACE casts, and the worm goes on the hook")
	await frames(2)
	expect(button.visible and button.text.contains("x%d" % (worms - 1)),
		"the button stays up while the line waits, one worm fewer", button.text)
	await close_scene()
	_completed += 1


## Task 0182: the fish book, opened and its pages turned with the keyboard,
## the mouse and the pad. A carp landed this run is a known page and the
## perch beside it a silhouette; the count says one of sixteen.
func _case_0182_book() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	var inventory := require_control("InventoryPanel") as InventoryPanel
	if driver == null or inventory == null:
		await close_scene()
		_completed += 1
		return
	var state := driver.state
	driver.set_speed(1)
	var water: Vector2i = Farm.cells_of(state, Farm.Terrain.WATER)[0]
	Fishing.begin(state, water)
	state["fishing"]["species"] = GameData.CARP
	state["fishing"]["stage"] = Fishing.BITING
	Fishing.reel(state)
	# Only this run counts here, whatever an earlier one left on disk: an
	# empty profile, and nothing of this run banked into one.
	(state["stats"]["banked"] as Dictionary).erase("fish_book")
	inventory.show_profile({})
	var book := inventory.book()
	var species := FishBook.species()

	# **The keyboard**: I opens the ledger, Q from its first page wraps round
	# to the book's last, and Q and E turn the book's pages.
	await tap_key(KEY_I)
	await frames(2)
	expect(inventory.is_open() and not inventory.on_book(), "I opens the ledger on its first page")
	await tap_key(KEY_Q)
	await frames(2)
	expect(inventory.on_book() and book.visible and book.shown() == species.back(),
		"Q wraps round to the book's last page", String(book.shown()))
	await tap_key(KEY_Q)
	await frames(2)
	expect(book.shown() == species[species.size() - 2], "Q turns a page back", String(book.shown()))
	await tap_key(KEY_E)
	await frames(2)
	expect(book.shown() == species.back(), "and E forward again", String(book.shown()))

	# **The mouse**: the book's tab opens it on its first page, the carp's,
	# and the arrows turn it.
	await click_control("inv_tab_fish_book")
	await frames(2)
	var name_label := book.get_node("BookTop/BookTitles/BookName") as Label
	var count_label := book.get_node("BookCount") as Label
	expect(book.shown() == GameData.CARP and book.known() and name_label.text == Names.of(GameData.CARP),
		"the book's tab opens it on the carp's page, named", name_label.text)
	expect(count_label.text == I18n.f(&"BOOK_COUNT", [1, species.size()]),
		"and the count says one of every species", count_label.text)
	await click_control("InventoryNext")
	await frames(2)
	var portrait := book.get_node("BookTop/BookPortrait") as TextureRect
	expect(book.shown() == GameData.PERCH and not book.known() and name_label.text == I18n.t(&"BOOK_UNKNOWN")
		and portrait.texture != null and portrait.modulate == Color.BLACK,
		"the next arrow turns to the perch, never caught: a black silhouette", name_label.text)
	await click_control("InventoryPrevious")
	await frames(2)
	expect(book.shown() == GameData.CARP, "and the previous one back")

	# **The pad**: the shoulder buttons turn it, and X closes the ledger.
	await _pad_tap(JOY_BUTTON_RIGHT_SHOULDER)
	await frames(2)
	expect(book.shown() == GameData.PERCH, "RB turns a page on")
	await _pad_tap(JOY_BUTTON_LEFT_SHOULDER)
	await frames(2)
	expect(book.shown() == GameData.CARP, "LB turns it back")
	await _pad_tap(JOY_BUTTON_X)
	await frames(2)
	expect(not inventory.is_open(), "the pad's inventory button closes the book")
	await close_scene()
	_completed += 1


## Task 0183: a coop put down by day through build mode - B, its row in the
## day's list, a click on the farm - takes the map's chickens in, and SPACE
## at its door collects what they have.
func _case_0183_barn() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	if driver == null:
		await close_scene()
		_completed += 1
		return
	var state := driver.state
	Resources.gain(state, Building.cost_of(&"coop"))
	# **Where he already stands**, below and to the right of him, as 0178's
	# case does: clear of the build list and the seed strip on the left, and
	# with the camera still - a farmer moved first left it gliding, and the
	# click now and then landed on another cell. A coop takes the map's hens
	# in wherever it goes up.
	var spot := Vector2i(-1, -1)
	var here := Player.cell(state)
	for dy in range(1, 5):
		for dx in range(1, 6):
			var cell := here + Vector2i(dx, dy)
			if spot == Vector2i(-1, -1) and Building.can_place(state, &"coop", cell):
				spot = cell
	expect(spot != Vector2i(-1, -1), "fixture: room for a coop near the farmer")
	await hold_key(KEY_B, 4)
	await until(func() -> bool: return Building.is_active(state), "build mode to open by day")
	var row := require_control("build_coop") as Button
	expect(row != null and row.get_global_rect().end.y <= 270.0,
		"the day's build list has the coop, on the screen")
	await click_control("build_coop")
	await until(func() -> bool: return Building.selected(state) == &"coop", "the coop to be selected")
	await click_cell(spot)
	await until(func() -> bool:
		return StringName(Farm.occupant(state, spot).get("id", &"")) == &"coop",
		"a click on the farm to put it down")
	expect(Farm.cells_with(state, &"chicken").is_empty() and Livestock.residents(state, spot).size() == 2,
		"the map's two chickens move in")
	expect(Describe.building(&"coop").contains(I18n.f(&"DESC_HOUSES", [int(GameData.BUILDINGS[&"coop"]["capacity"])])),
		"its description says how many it houses")
	await hold_key(KEY_B, 4)
	await until(func() -> bool: return not Building.is_active(state), "build mode to close")
	# Both hens with something to take, and the farmer at the door, facing it.
	for animal in Livestock.residents(state, spot):
		(animal as Dictionary)["ready"] = 1
	var door := Livestock.door_of(state, spot)
	_stand_at(state, door + Vector2i.DOWN, Player.NORTH)
	await frames(2)
	expect(Interact.verb_at(state, Player.target(state)) == &"collect",
		"facing the coop's door, the key collects")
	var meat := Resources.amount(state, GameData.MEAT)
	await tap_key(KEY_SPACE)
	await until(func() -> bool: return Resources.amount(state, GameData.MEAT) > meat,
		"SPACE at the door to collect")
	expect(Resources.amount(state, GameData.MEAT) == meat + 2 and Livestock.ready_at(state, door) == 0,
		"both hens' worth, and nothing left waiting")
	await close_scene()
	_completed += 1
