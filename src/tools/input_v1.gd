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
const V1_CASES := 14


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
	var field: Vector2i = Farm.cells_of(state, Farm.Terrain.SOIL)[0]
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
