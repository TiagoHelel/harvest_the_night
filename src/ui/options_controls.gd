class_name OptionsControls
extends Control

## The controls tab: every key the game reads, and a way to move it.
##
## It owns no policy either. Which actions there are, what they are called,
## what clashes with what, what "default" means and how a binding is written
## to disk are all `Actions`. This is a list, a listener and a message line.
##
## ## Waiting for a key is a mode, and it says so
##
## Pressing the button puts one row into **PRESS A KEY** and takes the very
## next thing pressed - a key or a mouse button, because a mouse button is a
## binding like any other. BACK gets out without binding anything, which is
## why the listener has to run before the options screen's own: otherwise the
## key that cancels a rebind closes the screen instead.
##
## ## A refusal names the clash
##
## "ALREADY SELL" tells a player what to do next. "Invalid" tells them to try
## things until one works. The rule is `Actions.bind()`'s; the words are its
## too, so a second screen would say the same thing.

## How tall a row is. Eight pixels of text and a little air - there are
## twenty-five of them and they have to fit in a window a player can read.
const ROW := 11

## The list is taller than the frame, on purpose: twenty-five bindings do not
## fit on a screen two hundred and seventy pixels high, and the alternative to
## scrolling is hiding half of them behind a second tab nobody would find.
const ROOM := Vector2(340, 130)

var _actions: Node

var _rows: VBoxContainer
var _bind_buttons: Dictionary = {}
var _message: Label
var _reset_all: Button

## Which action is waiting for a key, or empty.
var _waiting := &""


func _ready() -> void:
	_actions = get_node_or_null(^"/root/Actions")
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var settings := get_node_or_null(^"/root/Settings")
	if settings != null:
		settings.changed.connect(_on_setting)
		settings.reloaded.connect(_refresh)

	var column := VBoxContainer.new()
	column.name = "ControlsColumn"
	column.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(column)

	var scroll := ScrollContainer.new()
	scroll.name = "ControlsScroll"
	scroll.custom_minimum_size = ROOM
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	column.add_child(scroll)

	_rows = VBoxContainer.new()
	_rows.name = "ControlsRows"
	_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_rows)

	var footer := HBoxContainer.new()
	footer.name = "ControlsFooter"
	footer.theme_type_variation = UiKit.SPACED
	column.add_child(footer)
	_message = Label.new()
	_message.name = "ControlsMessage"
	_message.custom_minimum_size = Vector2(232, 10)
	footer.add_child(_message)
	_reset_all = Button.new()
	_reset_all.name = "ControlsResetAll"
	_reset_all.text = "RESET ALL"
	_reset_all.custom_minimum_size = Vector2(72, 12)
	_reset_all.focus_mode = Control.FOCUS_ALL
	_reset_all.pressed.connect(_reset_everything)
	footer.add_child(_reset_all)

	_build()


func _build() -> void:
	for child in _rows.get_children():
		_rows.remove_child(child)
		child.queue_free()
	_bind_buttons.clear()
	if _actions == null:
		return

	var group := ""
	for action in _actions.names():
		var belongs: String = _actions.group_for(action)
		if belongs != group:
			group = belongs
			var heading := Label.new()
			heading.name = "ControlsGroup_%s" % group.replace(" ", "")
			heading.text = group
			heading.custom_minimum_size = Vector2(0, ROW)
			heading.theme_type_variation = UiKit.DIM
			_rows.add_child(heading)
		_rows.add_child(_row_for(action))
	_refresh()


func _row_for(action: StringName) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "ControlsRow_%s" % action
	row.theme_type_variation = UiKit.SPACED
	row.custom_minimum_size = Vector2(0, ROW)

	var label := Label.new()
	label.text = String(_actions.label_for(action))
	label.custom_minimum_size = Vector2(112, ROW)
	row.add_child(label)

	var bind := Button.new()
	bind.name = "Bind_%s" % action
	bind.custom_minimum_size = Vector2(104, ROW)
	bind.theme_type_variation = UiKit.TAB
	bind.focus_mode = Control.FOCUS_ALL
	bind.pressed.connect(_start_waiting.bind(action))
	row.add_child(bind)
	_bind_buttons[action] = bind

	# **Absent, not greyed.** A row that is on the key the game shipped with
	# has nothing to put back, and a column of dead buttons down the side of
	# twenty-five rows is a column of noise.
	var undo := Button.new()
	undo.name = "Reset_%s" % action
	undo.text = "X"
	undo.custom_minimum_size = Vector2(12, ROW)
	undo.focus_mode = Control.FOCUS_ALL
	undo.pressed.connect(_reset_one.bind(action))
	row.add_child(undo)
	return row


# ----------------------------------------------------------------- the state

func _refresh() -> void:
	if _actions == null:
		return
	var any := false
	for action in _bind_buttons:
		var button: Button = _bind_buttons[action]
		button.text = "PRESS A KEY" if action == _waiting \
			else String(_actions.text_of(action))
		var moved: bool = _actions.rebound(action)
		any = any or moved
		var undo := button.get_parent().get_node_or_null(
			NodePath("Reset_%s" % action)) as Button
		if undo != null:
			undo.visible = moved
	_reset_all.visible = any


## A binding changed by something other than this screen - a reset from
## anywhere, a settings file reloaded - still has to reach the rows.
func _on_setting(key: StringName) -> void:
	if String(key).begins_with("controls/"):
		_refresh()


func _message_says(words: String) -> void:
	_message.text = words
	_message.theme_type_variation = UiKit.BAD if words != "" else UiKit.DIM


# --------------------------------------------------------------- the rebinding

func _start_waiting(action: StringName) -> void:
	_waiting = action
	_message_says("")
	_message.text = "PRESS A KEY OR A MOUSE BUTTON - BACK TO KEEP IT"
	_message.theme_type_variation = UiKit.DIM
	_refresh()


func _stop_waiting() -> void:
	_waiting = &""
	_refresh()


## **Before the options screen's own listener**, which is why this is `_input`
## and not `_unhandled_input`: BACK has to get out of a rebind without also
## closing the screen it would go back to.
func _input(event: InputEvent) -> void:
	if _waiting == &"" or not visible:
		return
	if event.is_action_pressed(&"cancel"):
		_stop_waiting()
		_message_says("")
		get_viewport().set_input_as_handled()
		return

	var key := event as InputEventKey
	var click := event as InputEventMouseButton
	var taking: InputEvent = null
	if key != null and key.pressed and not key.echo:
		taking = key
	elif click != null and click.pressed:
		taking = click
	if taking == null:
		return

	get_viewport().set_input_as_handled()
	var action := _waiting
	_waiting = &""
	var done: Dictionary = _actions.bind(action, taking)
	if bool(done.get("ok", false)):
		_message_says("")
	else:
		_message_says(String(done.get("why", "NO")))
	_refresh()


func _reset_one(action: StringName) -> void:
	_actions.reset(action)
	_message_says("")
	_refresh()


func _reset_everything() -> void:
	_actions.reset_all()
	_message_says("")
	_refresh()


# ------------------------------------------------------------ for the checks

func waiting_for() -> StringName:
	return _waiting


func binding_shown(action: StringName) -> String:
	var button: Button = _bind_buttons.get(action, null)
	return button.text if button != null else ""


func message_shown() -> String:
	return _message.text


func reset_showing(action: StringName) -> bool:
	var button: Button = _bind_buttons.get(action, null)
	if button == null:
		return false
	var undo := button.get_parent().get_node_or_null(
		NodePath("Reset_%s" % action)) as Button
	return undo != null and undo.visible


func reset_all_showing() -> bool:
	return _reset_all != null and _reset_all.visible
