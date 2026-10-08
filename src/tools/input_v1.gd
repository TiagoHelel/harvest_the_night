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
const V1_CASES := 3


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
