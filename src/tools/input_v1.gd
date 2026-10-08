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
const V1_CASES := 7


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
		await frames(4)
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
	g.keycode = KEY_G
	var a := InputEventJoypadButton.new()
	a.button_index = JOY_BUTTON_A
	var keyed: Dictionary = actions.bind(&"interact", g)
	expect(bool(keyed.get("ok", false))
		and InputMap.action_has_event("interact", g)
		and InputMap.action_has_event("interact", a),
		"interact on G keeps its A", str(keyed))
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

	# **REPAIR mends a damaged house.**
	state["house_hp"] = Phases.house_full(state) - 30
	Resources.gain(state, {GameData.FOOD: 200, GameData.WOOD: 200})
	await frames(2)
	var hurt := int(state["house_hp"])
	await click_control("RepairButton")
	await until(func() -> bool: return int(state["house_hp"]) > hurt,
		"the house to be mended")
	expect(int(state["house_hp"]) > hurt,
		"clicking RepairButton mends a damaged house",
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
	await _pad_axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)
	await _pad_axis(JOY_AXIS_TRIGGER_RIGHT, 0.0)
	await until(func() -> bool: return StringName(Farm.occupant(state, spot).get("id", &"")) == &"wall",
		"the wall to go down")
	expect(StringName(Farm.occupant(state, spot).get("id", &"")) == &"wall",
		"a placement at the cursor lands on that cell", str(spot))
	await frames(3)
	expect(cursor.look() == &"blocked", "and the cell it filled now reads blocked",
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
