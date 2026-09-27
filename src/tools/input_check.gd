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

## The check takes well under a second; this is the backstop for a scene that
## never finishes loading or an `await` that never returns.
const WATCHDOG_SECONDS := 20.0

## How many `_case_NNNN_*` functions `_run()` is expected to finish.
## **Adding a case means bumping this.**
const CASES := 1

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
	await _case_0011_harness()
	_finish()


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
	expect(require_control("Title") != null, "the title label is there")
	expect(require_control("Clock") != null, "the clock label is there")
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

	# The clock is running, which means the scene is really being ticked and
	# not merely instantiated.
	var clock: Label = require_control("Clock")
	var first := clock.text
	await frames(20)
	expect(clock.text != first, "the scene is live - the clock moved",
		"%s then %s" % [first, clock.text])

	# A mouse click reaches a Control and its handler runs.
	var probe := Button.new()
	probe.name = "ClickProbe"
	probe.position = Vector2(200, 120)
	probe.size = Vector2(80, 24)
	var clicks := [0]
	probe.pressed.connect(func() -> void: clicks[0] += 1)
	_scene.add_child(probe)
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

	# Clicking a farm cell. The mapping is the identity today because the
	# viewport is the farm's own resolution and there is no camera yet; task
	# 0013 gives the world view a `cell_to_screen()` and this starts asking it.
	var centre := cell_to_screen(Vector2i(2, 3))
	expect(centre == Vector2(2 * GameData.TILE_SIZE + 8, 3 * GameData.TILE_SIZE + 8),
		"a farm cell maps to the middle of its tile", str(centre))
	await click_cell(Vector2i(2, 3))
	expect(true, "clicking a cell does not throw")

	await close_scene()
	expect(_scene == null, "and the scene is torn down for the next case")

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


func expect(ok: bool, what: String, detail: String = "") -> void:
	if ok:
		passed += 1
	else:
		_fail(what, detail)


func _fail(what: String, detail: String = "") -> void:
	failed += 1
	print("  FAIL  ", what, "  ", detail)
