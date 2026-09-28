class_name OptionsScreen
extends Control

## The frame the options live in, and the way back out of it.
##
## **This is a seam, and it is nearly empty on purpose.** Task 0092 owns the
## router and the back stack; the three screens that go in here are tasks
## 0093 (video), 0094 (audio) and 0095 (controls), each of which has its own
## file and its own prompt. What this task ships is the state, the frame, the
## tab strip and a Back that goes to whoever opened it - which is the thing
## the three of them plug into.
##
## `register()` is that plug. A tab that exists is a tab on the strip; with
## none registered the screen is a heading and a way out, and it says so
## rather than showing three tabs that open nothing. Same rule as the title
## menu's: **absent, not greyed**.
##
## It appears in both `Title.tscn` and `Main.tscn`, and neither of them knows
## about the other. `App` is what says when it is up.

## What the strip can hold, in the order the tabs belong in. A task that
## builds one registers under its own name.
const TABS: Array = [&"video", &"audio", &"controls"]

var _tabs: Dictionary = {}
var _open := &""

var _frame: PanelContainer
var _strip: HBoxContainer
var _room: Control
var _empty: Label


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)

	_frame = PanelContainer.new()
	_frame.name = "OptionsFrame"
	_frame.position = Vector2(60, 26)
	_frame.custom_minimum_size = Vector2(360, 216)
	_frame.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_frame)

	var column := VBoxContainer.new()
	column.name = "OptionsColumn"
	_frame.add_child(column)

	var title := Label.new()
	title.name = "OptionsTitle"
	title.text = "OPTIONS"
	title.theme_type_variation = UiKit.HEADING
	column.add_child(title)

	_strip = HBoxContainer.new()
	_strip.name = "OptionsTabs"
	_strip.theme_type_variation = UiKit.SPACED
	column.add_child(_strip)

	_room = Control.new()
	_room.name = "OptionsRoom"
	_room.custom_minimum_size = Vector2(348, 148)
	column.add_child(_room)

	_empty = Label.new()
	_empty.name = "OptionsEmpty"
	_empty.text = "nothing to set yet"
	_empty.theme_type_variation = UiKit.DIM
	_room.add_child(_empty)

	# **The tabs register themselves here.** The frame knows the names in
	# `TABS` and nothing about what any of them does, which is what made 0094
	# three lines - and leaves 0095 the same.
	var video := OptionsVideo.new()
	video.name = "OptionsVideo"
	register(&"video", video)

	var audio := OptionsAudio.new()
	audio.name = "OptionsAudio"
	register(&"audio", audio)

	var controls := OptionsControls.new()
	controls.name = "OptionsControls"
	register(&"controls", controls)

	var back := Button.new()
	back.name = "OptionsBack"
	back.text = "BACK"
	back.custom_minimum_size = Vector2(80, 16)
	back.focus_mode = Control.FOCUS_ALL
	back.pressed.connect(_go_back)
	column.add_child(back)


## Put a screen on the strip. Tasks 0093 to 0095 each call this once.
##
## The tab is added in `TABS` order however late it registers, so the strip
## reads the same whichever of the three is built first.
func register(which: StringName, screen: Control) -> bool:
	if not TABS.has(which):
		push_error("OptionsScreen: '%s' is not one of the tabs" % which)
		return false
	_tabs[which] = screen
	screen.visible = false
	if screen.get_parent() == null:
		_room.add_child(screen)
	_rebuild_strip()
	if _open == &"":
		show_tab(which)
	return true


func show_tab(which: StringName) -> void:
	if not _tabs.has(which):
		return
	_open = which
	for name in _tabs:
		(_tabs[name] as Control).visible = name == which
	_empty.visible = false
	_rebuild_strip()


func open_tab() -> StringName:
	return _open


func tabs() -> Array:
	var out: Array = []
	for which in TABS:
		if _tabs.has(which):
			out.append(which)
	return out


func _rebuild_strip() -> void:
	for child in _strip.get_children():
		_strip.remove_child(child)
		child.queue_free()
	for which in tabs():
		var tab := Button.new()
		tab.name = "OptionsTab_%s" % which
		tab.text = String(which).to_upper()
		tab.toggle_mode = true
		tab.button_pressed = which == _open
		tab.theme_type_variation = UiKit.TAB
		tab.custom_minimum_size = Vector2(72, 14)
		tab.focus_mode = Control.FOCUS_ALL
		tab.pressed.connect(show_tab.bind(which))
		_strip.add_child(tab)
	_empty.visible = _tabs.is_empty()


func _go_back() -> void:
	var router := get_node_or_null(^"/root/App")
	if router != null:
		router.back()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed(&"cancel"):
		_go_back()
		get_viewport().set_input_as_handled()
