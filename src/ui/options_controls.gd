class_name OptionsControls
extends OptionsPage

## The controls page: every action, the key it is on, and a way to move it.
##
## **Enter listens, the next key is the answer.** The row says PRESS A KEY and
## the line under the page says how to give up; the next key or mouse button
## pressed is the new binding, and escape - or `LISTEN_SECONDS` with nothing
## pressed - leaves it as it was. A key another action already has is refused
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

## How long a row listens before it gives up.
const LISTEN_SECONDS := 5.0

var _actions: Node
## action -> its row
var _binds: Dictionary = {}
var _reset_all: OptionRow

## The action listening for a key, and how long it has left.
var _waiting := &""
var _left := 0.0
## What the line under the page last had to say about a binding, or "".
var _said := ""


func _init() -> void:
	title_key = &"OPT_TAB_CONTROLS"


func _build() -> void:
	_actions = get_node_or_null(^"/root/Actions")
	_binds.clear()
	if _actions == null:
		return
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
	var taking: InputEvent = null
	if key != null and key.pressed and not key.echo:
		taking = key
	elif click != null and click.pressed:
		taking = click
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
