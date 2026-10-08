class_name TutorialPrompt
extends Control

## Day one's nine lines, each over the thing it is about.
##
## **A label, not a manual.** The line follows the cell `Tutorial.points_at()`
## names - the nearest tree, the bare plot, the workshop - so it is read on the
## way to the thing rather than instead of going there. A pointer under it says
## which tile, because a line floating over a farm is a line about the farm.
##
## ## It is off by default on a second run
##
## `gameplay/tutorial_seen` is a `Settings` key, which is a node and an
## autoload, so `src/core/` may not look at it. This file does, once, on the
## first frame it has a state: if the flag is set the whole thing stays hidden
## for the rest of the run.
##
## **Reached by path, not by name.** `verify.py` parses every script on its own
## with `--check-only`, where no autoload is registered - so `Settings.x` is a
## compile error in a file that works perfectly at runtime. Going through
## `get_node_or_null("/root/Settings")` also means this survives a test scene
## that has no settings service at all, which is what `input_check` builds.
##
## It is written back when the last step finishes, which is the first night
## held - at which point they have demonstrably seen all nine.
##
## ## The first night is taught too (task 0141)
##
## Each step is taught in its own part of the day (`Tutorial.current_here`):
## the day's and the bed's by day, the build step's two in the build step,
## dawn's in the night. In the house only the bed's line shows, over the bed;
## START's sits over the button and dawn's under the countdown, which the
## rules can only name (`Tutorial.anchor_of`), so this finds them.
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

## The room and the night HUD, for the bed's line and the night's. Set by
## `main.gd`.
var house: HouseView
var night_hud: NightHud

var _state: Dictionary = {}
var _world: WorldView
var _line: Label
var _arrow: Label
var _panel: ColorRect
var _asked := false
var _muted := false
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

	# Asked once, on the first frame with a state. A player who has seen it
	# does not see it again; a player halfway through their first day does.
	if not _asked:
		_asked = true
		_muted = _seen()

	# **The step of this part of the day** (task 0141), and in the house only
	# the bed's.
	var step := Tutorial.current_here(_state)
	var anchor := Tutorial.anchor_of(_state)
	# Nor while the bed beat plays: the room is on screen for it, and the
	# build step's line belongs to the farm it cuts to.
	var beat := house != null and house.is_showing_bedtime()
	if _muted or step.is_empty() or beat \
			or (House.inside(_state) and anchor != &"room"):
		# Finishing the last step is the first night held, so this is also
		# where "seen it" gets written down.
		if not _muted and Tutorial.is_finished(_state) and not _seen():
			_remember()
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


func _seen() -> bool:
	var service := _settings()
	if service == null or not service.has_method(&"get_bool"):
		return false
	return bool(service.call(&"get_bool", SEEN_KEY))


func _remember() -> void:
	var service := _settings()
	if service != null and service.has_method(&"set_value"):
		service.call(&"set_value", SEEN_KEY, true)


## Put the line above the farm cell it is about, kept on screen.
func _place(cell: Vector2i) -> void:
	var at := Vector2(200, 60)
	if _world != null and cell != Tutorial.NOWHERE:
		var size := float(GameData.TILE_SIZE)
		var middle := Vector2(cell) * size + Vector2(size, size) * 0.5
		at = _world.get_viewport_transform() * (_world.get_global_transform()
			* middle)
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


## A control of the night HUD by name, or null.
func _night_control(control_name: String) -> Control:
	if night_hud == null:
		return null
	return night_hud.find_child(control_name, true, false) as Control
