class_name OptionsControls
extends OptionsPage

## The controls page: every action, the key it is on, and a way to move it.
##
## **Enter listens, the next key is the answer.** The row says PRESS A KEY and
## the line under the page says how to give up; the next key, mouse button or
## pad button, stick or trigger (task 0121) is the new binding - a pad's on
## the pad side, so it never knocks the key off - and escape - or
## `LISTEN_SECONDS` with nothing pressed - leaves it as it was. A key another
## action already has is refused
## and named, and the row keeps listening, so the player can try another
## without starting over.
##
## **A moved binding says so, and left or right puts it back.** A star after
## the key marks every action that is not on its shipped key, and the row
## that has the caret on one of them says how to undo it - the way
## WELCOME BACK, HERO's controls do it, rather than a second little button on
## every row. RESET ALL, at the bottom, is there only while there is something
## to reset.
##
## What a binding is and which keys clash is `Actions`'; this only asks it.
##
## **The cursor and the camera** (task 0292), under their own heading after
## the bindings: how fast a held step moves the guardian's cursor, whether the
## window's edge pans the night camera, and how far a stick must tilt. Their
## steps sit here, with their rows, the way `OptionsA11y.ROWS` keeps its own:
## preferences, not balance, so not in `game_data.gd`. The page's reset row
## puts these three back; RESET ALL is the bindings'.

const ActionsScript := preload("res://src/app/input_actions.gd")

## How long a row listens before it gives up.
const LISTEN_SECONDS := 5.0

## `controls/cursor_speed`'s steps: percents of 0131's repeat rate.
const CURSOR_SPEEDS: Array = [50, 75, 100, 150, 200]
## `controls/pad_deadzone`'s steps, 0121's 0.2 among them.
const DEADZONES: Array = [0.1, 0.15, 0.2, 0.25, 0.3, 0.35, 0.4, 0.45, 0.5]

var _actions: Node
## action -> its row
var _binds: Dictionary = {}
var _reset_all: OptionRow
var _cursor_speed: OptionRow
var _edge_pan: OptionRow
var _deadzone: OptionRow

## The action listening for a key, and how long it has left.
var _waiting := &""
var _left := 0.0
## What the line under the page last had to say about a binding, or "".
var _said := ""


func _init() -> void:
	resets = [&"controls/cursor_speed", &"controls/edge_pan",
		&"controls/pad_deadzone"]
	title_key = &"OPT_TAB_CONTROLS"


func _build() -> void:
	_actions = get_node_or_null(^"/root/Actions")
	_binds.clear()
	if _actions == null:
		return
	# The page names the device in hand (task 0121): the pad's buttons after a
	# pad was touched, the keys after a key.
	if _actions.has_signal(&"device_changed") \
			and not _actions.device_changed.is_connected(_on_device):
		_actions.device_changed.connect(_on_device)
	var group := &""
	for action in _actions.names():
		var belongs: StringName = _actions.group_for(action)
		if belongs != group:
			group = belongs
			var heading := heading_row("ControlsGroup_%s" % String(group).replace(
				"ACT_GROUP_", ""))
			heading.set_meta(&"group", group)
		var row := _bind_row(action)
		_binds[action] = row
	var heading := heading_row("ControlsGroup_CURSOR")
	heading.set_meta(&"group", &"CTL_GROUP_CURSOR")
	_cursor_speed = choice_row("ControlsCursorSpeed", _step_cursor_speed,
		_cursor_speed_text)
	_edge_pan = toggle_row("ControlsEdgePan", &"controls/edge_pan")
	_deadzone = choice_row("ControlsDeadzone", _step_deadzone, _deadzone_text)
	_reset_all = action_row("ControlsResetAll", _reset_everything)


func _bind_row(action: StringName) -> OptionRow:
	var row := _row("Bind_%s" % action, OptionRow.Kind.BIND)
	row.on_take = _start_waiting.bind(action)
	row.shows = _binding_text.bind(action)
	# Left and right on a moved binding put it back - see the note at the top.
	row.on_step = func(_delta: int) -> void:
		if _actions != null and _actions.rebound(action):
			_reset_one(action)
	row.kind = OptionRow.Kind.BIND
	row.focus_entered.connect(_explain.bind(action))
	return row


func relabel() -> void:
	if _reset_all == null:
		return
	for row in rows():
		var one := row as OptionRow
		if one.has_meta(&"group"):
			one.text = I18n.t(one.get_meta(&"group"))
	for action in _binds:
		(_binds[action] as OptionRow).text = String(_actions.label_for(action))
	_reset_all.text = I18n.t(&"CTL_RESET_ALL")
	_cursor_speed.text = I18n.t(&"CTL_CURSOR_SPEED")
	_edge_pan.text = I18n.t(&"CTL_EDGE_PAN")
	_deadzone.text = I18n.t(&"CTL_DEADZONE")
	super()


func refresh() -> void:
	super()
	if _actions == null or _reset_all == null:
		return
	var any := false
	for action in _binds:
		var row: OptionRow = _binds[action]
		row.urgent = action == _waiting
		any = any or bool(_actions.rebound(action))
	_reset_all.visible = any
	if _waiting != &"":
		say(_said if _said != "" else I18n.t(&"CTL_ASKING"),
			UiKit.BAD if _said != "" else UiKit.DIM)
	else:
		say(_said, UiKit.BAD)


func _binding_text(action: StringName) -> String:
	if action == _waiting:
		return I18n.t(&"CTL_WAITING")
	var words := String(_actions.text_of(action))
	return words + " *" if bool(_actions.rebound(action)) else words


## The line under the page says how to undo a moved binding while the caret
## is on it.
func _explain(action: StringName) -> void:
	if _waiting != &"":
		return
	_said = ""
	if _actions != null and bool(_actions.rebound(action)):
		say(I18n.t(&"CTL_RESET_HINT"))
	else:
		say("")


# ---------------------------------------------------- the cursor and camera

func _step_cursor_speed(delta: int) -> void:
	if _settings == null:
		return
	_settings.set_value(&"controls/cursor_speed", int(stepped(CURSOR_SPEEDS,
		int(_settings.get_int(&"controls/cursor_speed")), delta)))


func _cursor_speed_text() -> String:
	var now := int(_settings.get_int(&"controls/cursor_speed")) 		if _settings != null else 100
	return "%d%%" % now


func _step_deadzone(delta: int) -> void:
	if _settings == null:
		return
	_settings.set_value(&"controls/pad_deadzone", float(stepped(DEADZONES,
		float(_settings.get_float(&"controls/pad_deadzone")), delta)))


func _deadzone_text() -> String:
	var now := float(_settings.get_float(&"controls/pad_deadzone")) 		if _settings != null else 0.2
	return "%d%%" % roundi(now * 100.0)


# ------------------------------------------------------------ the listening

func _start_waiting(action: StringName) -> void:
	_waiting = action
	_left = LISTEN_SECONDS
	_said = ""
	refresh()


func _stop_waiting() -> void:
	_waiting = &""
	_left = 0.0
	refresh()


func _process(delta: float) -> void:
	if _waiting == &"":
		return
	_left -= delta
	if _left <= 0.0:
		_said = ""
		_stop_waiting()


func _input(event: InputEvent) -> void:
	if _waiting == &"" or not is_visible_in_tree():
		return
	if event.is_action_pressed(&"cancel"):
		_said = ""
		_stop_waiting()
		get_viewport().set_input_as_handled()
		return
	var key := event as InputEventKey
	var click := event as InputEventMouseButton
	var pad := event as InputEventJoypadButton
	var stick := event as InputEventJoypadMotion
	var taking: InputEvent = null
	if key != null and key.pressed and not key.echo:
		taking = key
	elif click != null and click.pressed:
		taking = click
	elif pad != null and pad.pressed:
		taking = pad
	elif stick != null and absf(stick.axis_value) >= ActionsScript.PAD_TAKE:
		# A stick or trigger is taken as its direction, not its tilt: the
		# binding is "left stick up", whatever angle it was pushed at.
		var direction := InputEventJoypadMotion.new()
		direction.axis = stick.axis
		direction.axis_value = 1.0 if stick.axis_value > 0.0 else -1.0
		taking = direction
	if taking == null:
		return
	get_viewport().set_input_as_handled()
	var action := _waiting
	var done: Dictionary = _actions.bind(action, taking)
	if bool(done.get("ok", false)):
		_said = ""
		_stop_waiting()
		_explain(action)
		return
	# **Refused, and still listening**, so the next key is the next try.
	_said = String(done.get("why", I18n.t(&"CTL_NO_ACTION")))
	_left = LISTEN_SECONDS
	refresh()


func _reset_one(action: StringName) -> void:
	_actions.reset(action)
	_said = ""
	refresh()
	_explain(action)


func _reset_everything() -> void:
	_actions.reset_all()
	_said = ""
	refresh()
	# The row it was on has gone; the first binding takes the caret.
	var first := entries()
	if not first.is_empty() and is_visible_in_tree():
		(first[0] as Control).grab_focus()


func busy() -> bool:
	return _waiting != &"" or super()


func cancel() -> bool:
	if _waiting != &"":
		_said = ""
		_stop_waiting()
		return true
	return super()


func _on_setting(key: StringName) -> void:
	if String(key).begins_with("controls/"):
		refresh()


func _on_device(_using_pad: bool) -> void:
	if is_inside_tree():
		refresh()


# ---------------------------------------------------------- for the checks

func waiting_for() -> StringName:
	return _waiting


func binding_shown(action: StringName) -> String:
	var row: OptionRow = _binds.get(action, null)
	return row.value_text() if row != null else ""


func message_shown() -> String:
	return note_shown()


## Whether a row says its binding was moved - the star.
func reset_showing(action: StringName) -> bool:
	return binding_shown(action).ends_with(" *")


func reset_all_showing() -> bool:
	return _reset_all != null and _reset_all.visible
