class_name TutorialPrompt
extends Control

## The first week's lines, each over the thing it is about.
##
## **A label, not a manual.** The line follows the cell `Tutorial.points_at()`
## names - the nearest tree, the bare plot, the workshop - so it is read on the
## way to the thing rather than instead of going there. A pointer under it says
## which tile, because a line floating over a farm is a line about the farm.
##
## ## Never twice, step by step
##
## `gameplay/tutorial_seen` is a `Settings` key, which is a node and an
## autoload, so `src/core/` may not look at it. Since task 0293 it is the list
## of step ids done in any run: this hands it to `Tutorial` as the steps to
## pass over, and writes each step into it as it is done. A lesson added in a
## later build still reaches a player who finished the rest.
##
## **Reached by path, not by name.** `verify.py` parses every script on its own
## with `--check-only`, where no autoload is registered - so `Settings.x` is a
## compile error in a file that works perfectly at runtime. Going through
## `get_node_or_null("/root/Settings")` also means this survives a test scene
## that has no settings service at all, which is what `input_check` builds.
##
## The checks and the shots turn both off (`remembers`, `reads_seen`): a
## test run or a picture never teaches this machine's player anything.
##
## ## The first night is taught too (task 0141)
##
## Each step is taught in its own part of the day (`Tutorial.current_here`):
## the day's and the bed's by day, the build step's two in the build step,
## dawn's in the night. In the house only the bed's line shows, over the bed;
## START's sits over the button and dawn's under the countdown, which the
## rules can only name (`Tutorial.anchor_of`), so this finds them. Since task
## 0293 the forecast's line sits by the forecast's panel, and the seasons' and
## the Full Moon's under the date.
##
## ## It never stops anything
##
## `mouse_filter` is IGNORE from the root down and nothing here writes to the
## state. Closing it is not a feature because it does not take anything away:
## a player who ignores it simply finishes the steps in some other order and
## the lines disappear behind them.

const SEEN_KEY := &"gameplay/tutorial_seen"

## Where a line about a night control sits when it is above one: clear of
## the hotbar, whose slots start at 215.
const ABOVE_THE_HOTBAR := 199.0
## And when it is under the night strip, which is 24 pixels tall.
const UNDER_THE_STRIP := 34.0

## The room and the night HUD, for the bed's line and the night's; the
## forecast's panel and the day HUD, for the forecast's and the date's (task
## 0293). Set by `main.gd`.
var house: HouseView
var night_hud: NightHud
var forecast: Control
var hud: Control

## **Whether this writes the steps it sees done into `tutorial_seen`**, and
## whether it passes over the ones there. Both off for the shots, which must
## not change a player's settings nor depend on them.
var remembers := true
var reads_seen := true

var _state: Dictionary = {}
var _world: WorldView
var _line: Label
var _arrow: Label
var _panel: ColorRect
var _seen: Array = []
var _read := false
var _showing := &""


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = false

	_panel = ColorRect.new()
	_panel.name = "TutorialBacking"
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.color = Color(0.05, 0.04, 0.09, 0.78)
	add_child(_panel)

	_line = Label.new()
	_line.name = "TutorialLine"
	_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_line)

	_arrow = Label.new()
	_arrow.name = "TutorialArrow"
	_arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_arrow.text = "v"
	_arrow.theme_type_variation = UiKit.WARM
	add_child(_arrow)


func show_state(state: Dictionary, world: WorldView) -> void:
	_state = state
	_world = world


## Which step is on screen, or `&""`. For the tests, and for task 0089's
## tooltip to keep out of the way of.
func showing() -> StringName:
	return _showing


func _process(_delta: float) -> void:
	if _state.is_empty():
		return

	# Read once, on the first frame with a state; written as steps are done.
	if not _read:
		_read = true
		_seen = _seen_list() if reads_seen else []
	_remember_done()

	# **The step of this part of the day** (task 0141), past the ones seen
	# before (0293), and in the house only the bed's.
	var skip := _seen if reads_seen else []
	var step := Tutorial.current_here(_state, skip)
	var anchor := Tutorial.anchor_of(_state, skip)
	# Nor while the bed beat plays: the room is on screen for it, and the
	# build step's line belongs to the farm it cuts to.
	var beat := house != null and house.is_showing_bedtime()
	if step.is_empty() or beat \
			or (House.inside(_state) and anchor != &"room"):
		visible = false
		_showing = &""
		return

	_showing = StringName(step["id"])
	_line.text = I18n.t(StringName(step["line"]))
	visible = true
	match anchor:
		&"start":
			_place_by(_night_control("StartButton"), false)
		&"dawn":
			_place_by(_night_control("DawnCountdown"), true)
		&"forecast":
			_place_by_panel(forecast)
		&"date":
			_place_under(hud.find_child("Day", true, false) as Control if hud != null else null)
		&"room":
			if house != null:
				_place_at(house.room_to_screen(Tutorial.points_at(_state)), true)
			else:
				_place_at(Vector2(240.0, 120.0), false)
		_:
			_place(Tutorial.points_at(_state))


## The settings service, or null when there is not one.
func _settings() -> Node:
	return get_node_or_null(^"/root/Settings")


## The step ids seen before, as `tutorial_seen` has them - none with no
## settings service.
func _seen_list() -> Array:
	var service := _settings()
	if service == null or not service.has_method(&"get_value"):
		return []
	var held: Variant = service.call(&"get_value", SEEN_KEY)
	return (held as Array).duplicate() if held is Array else []


## **Every step done, written down once** (task 0293): the list grows as the
## run teaches, so a crash after the first night costs nothing it learned.
func _remember_done() -> void:
	if not remembers:
		return
	var grew := false
	for id in (_state["tutorial"] as Dictionary)["done"]:
		if not _seen.has(String(id)):
			_seen.append(String(id))
			grew = true
	if not grew:
		return
	var service := _settings()
	if service != null and service.has_method(&"set_value"):
		service.call(&"set_value", SEEN_KEY, _seen.duplicate())


## The ids this will not show again - for the checks.
func seen_ids() -> Array:
	return _seen.duplicate()


## Put the line above the farm cell it is about, kept on screen.
##
## **`WorldView.cell_to_screen`** (task 0293), as the tips and the world
## tooltip are placed: the screen's own pixels at any window size. The
## viewport's transform it used before is the window's, which a 1920x1080
## capture made four times too large - the cursor's line landed on the
## hotbar.
func _place(cell: Vector2i) -> void:
	var at := Vector2(200, 60)
	if _world != null and cell != Tutorial.NOWHERE:
		at = _world.cell_to_screen(cell)
	_place_at(at, cell != Tutorial.NOWHERE)


## Put the line above a point on the screen, with the pointer under it on
## the point.
func _place_at(at: Vector2, pointing: bool) -> void:
	var width := _line.get_minimum_size().x + 10.0
	# **Kept on the screen**, because the nearest tree can be at the edge of it
	# and a line half off the side is a line nobody reads.
	var left := clampf(at.x - width * 0.5, 4.0, 480.0 - width - 4.0)
	var top := clampf(at.y - 26.0, 30.0, 236.0)

	_panel.position = Vector2(left, top)
	_panel.size = Vector2(width, 13)
	_line.position = Vector2(left + 5.0, top + 1.0)
	_arrow.text = "v"
	_arrow.position = Vector2(clampf(at.x - 2.0, 4.0, 470.0), top + 12.0)
	_arrow.visible = pointing


## Beside one of the night HUD's controls (task 0141): above START and
## clear of the hotbar, with the pointer down at the button; or under the
## night strip, with the pointer up at the dawn countdown.
func _place_by(control: Control, below: bool) -> void:
	if control == null or not control.is_visible_in_tree():
		_place_at(Vector2(240.0, 120.0), false)
		return
	var box := control.get_global_rect()
	var width := _line.get_minimum_size().x + 10.0
	var left := clampf(box.get_center().x - width * 0.5, 4.0, 480.0 - width - 4.0)
	var top := UNDER_THE_STRIP if below else ABOVE_THE_HOTBAR
	_panel.position = Vector2(left, top)
	_panel.size = Vector2(width, 13)
	_line.position = Vector2(left + 5.0, top + 1.0)
	_arrow.text = "^" if below else "v"
	_arrow.position = Vector2(box.get_center().x - 2.0,
		UNDER_THE_STRIP - 10.0 if below else box.position.y - 12.0)
	_arrow.visible = true


## **By the forecast's panel** (task 0293): under it, its right edge with
## the panel's, the pointer up at the panel - on the farm, clear of the day
## HUD's seed list on the left and of the strip above.
func _place_by_panel(panel: Control) -> void:
	if panel == null or not panel.is_visible_in_tree():
		_place_at(Vector2(240.0, 120.0), false)
		return
	var box := panel.get_global_rect()
	var width := _line.get_minimum_size().x + 10.0
	var left := clampf(box.end.x - width, 4.0, 480.0 - width - 4.0)
	var top := clampf(box.end.y + 10.0, 30.0, 236.0)
	_panel.position = Vector2(left, top)
	_panel.size = Vector2(width, 13)
	_line.position = Vector2(left + 5.0, top + 1.0)
	_arrow.text = "^"
	_arrow.position = Vector2(box.get_center().x - 2.0, top - 10.0)
	_arrow.visible = true


## **Under a control of the day HUD** (task 0293): the date, the pointer up
## at it - where 0195's season tip sits too.
func _place_under(control: Control) -> void:
	if control == null or not control.is_visible_in_tree():
		_place_at(Vector2(240.0, 120.0), false)
		return
	var box := control.get_global_rect()
	var width := _line.get_minimum_size().x + 10.0
	var at_x := box.position.x + 24.0
	var left := clampf(at_x - width * 0.5, 4.0, 480.0 - width - 4.0)
	var top := box.end.y + 10.0
	_panel.position = Vector2(left, top)
	_panel.size = Vector2(width, 13)
	_line.position = Vector2(left + 5.0, top + 1.0)
	_arrow.text = "^"
	_arrow.position = Vector2(clampf(at_x - 2.0, 4.0, 470.0), top - 10.0)
	_arrow.visible = true


## A control of the night HUD by name, or null.
func _night_control(control_name: String) -> Control:
	if night_hud == null:
		return null
	return night_hud.find_child(control_name, true, false) as Control
