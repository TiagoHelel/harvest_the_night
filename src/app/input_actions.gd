extends Node

## The one place that says which key does what.
##
## Every key and every mouse button the game reads is a **named action** -
## `project.godot` ships the defaults, this rewrites them from
## `controls/bindings` at boot, and nothing in `src/ui/` mentions a keycode.
## There is a check that walks the whole folder and fails on one.
##
## ## The defaults are the input map, not a second copy of it
##
## A table of shipped bindings here would be a second place to edit and a
## second place to be wrong. So the first `apply()` **photographs `InputMap`**
## before touching it, and that photograph is what "reset to defaults" puts
## back. Adding an action means adding it to `project.godot` and to `ACTIONS`,
## and a check fails if those two lists ever disagree.
##
## ## A rebind that would be ambiguous is refused, not silently taken
##
## Two actions on one key is a game that does two things at once or the wrong
## one of them, and either way the player did not ask for it. `bind()` returns
## the action it clashed with so the screen can name it - "already SELL" is an
## answer, "invalid" is not.
##
## ## Mouse buttons are bindings like any other
##
## They are in `ACTIONS`, they are stored the same way, they clash the same
## way, and they are rebound by clicking rather than typing. The only thing
## that knows the difference is `label_of()`.

## Which settings key holds the changes. A binding that is not in it is the
## shipped one, so "reset" is an erase rather than a second table of values.
const KEY := &"controls/bindings"

## Every rebindable action: its name, what to call it, and the group it is
## shown under. **In screen order.**
const ACTIONS: Array = [
	[&"move_up", "MOVE UP", "MOVING"],
	[&"move_down", "MOVE DOWN", "MOVING"],
	[&"move_left", "MOVE LEFT", "MOVING"],
	[&"move_right", "MOVE RIGHT", "MOVING"],

	[&"interact", "INTERACT", "FARM"],
	[&"inventory", "INVENTORY", "FARM"],
	[&"slot_1", "SEED 1", "FARM"],
	[&"slot_2", "SEED 2", "FARM"],
	[&"slot_3", "SEED 3", "FARM"],
	[&"slot_4", "SEED 4", "FARM"],
	[&"slot_5", "SEED 5", "FARM"],
	[&"slot_6", "SEED 6", "FARM"],

	[&"build", "BUILD MODE", "BUILD"],
	[&"place", "PLACE", "BUILD"],
	[&"remove", "SELL", "BUILD"],
	[&"upgrade", "UPGRADE", "BUILD"],

	[&"night", "START THE NIGHT", "NIGHT"],
	[&"ability", "ABILITY", "NIGHT"],
	[&"speed", "SPEED", "NIGHT"],
	[&"skip_night", "SKIP THE NIGHT", "NIGHT"],

	[&"pause", "PAUSE", "SCREENS"],
	[&"cancel", "BACK", "SCREENS"],
	[&"tech", "TECH TREE", "SCREENS"],
	[&"stats", "RECORDS", "SCREENS"],
	[&"log", "LOG", "SCREENS"],
]

## What a mouse button is called. Godot's own `as_text()` says "Left Mouse
## Button (Left Mouse Button)" in places, which is not a thing to put on a
## screen eight pixels tall.
const MOUSE_NAMES: Dictionary = {
	MOUSE_BUTTON_LEFT: "LEFT CLICK",
	MOUSE_BUTTON_RIGHT: "RIGHT CLICK",
	MOUSE_BUTTON_MIDDLE: "MIDDLE CLICK",
	MOUSE_BUTTON_WHEEL_UP: "WHEEL UP",
	MOUSE_BUTTON_WHEEL_DOWN: "WHEEL DOWN",
}

## What a binding with no event at all shows as. It cannot happen through the
## screen - a rebind always takes an event - but a hand-edited config can.
const NOTHING := "-"

## action -> the events `project.godot` shipped it with.
var _shipped: Dictionary = {}


func _ready() -> void:
	var settings := _settings()
	if settings != null:
		if not settings.changed.is_connected(_on_changed):
			settings.changed.connect(_on_changed)
		if not settings.reloaded.is_connected(apply):
			settings.reloaded.connect(apply)
	apply()


# ------------------------------------------------------------------- the list

## Just the names, in screen order.
static func names() -> Array:
	var out: Array = []
	for entry in ACTIONS:
		out.append(entry[0])
	return out


static func label_for(action: StringName) -> String:
	for entry in ACTIONS:
		if entry[0] == action:
			return String(entry[1])
	return String(action).to_upper()


static func group_for(action: StringName) -> String:
	for entry in ACTIONS:
		if entry[0] == action:
			return String(entry[2])
	return ""


## The groups, in screen order, without repeats.
static func groups() -> Array:
	var out: Array = []
	for entry in ACTIONS:
		if not out.has(entry[2]):
			out.append(entry[2])
	return out


# ------------------------------------------------------------- reading events

## What one event is called on the screen.
static func label_of(event: InputEvent) -> String:
	var button := event as InputEventMouseButton
	if button != null:
		return String(MOUSE_NAMES.get(button.button_index,
			"MOUSE %d" % button.button_index))
	var key := event as InputEventKey
	if key != null:
		var code := key.keycode if key.keycode != 0 else key.physical_keycode
		return OS.get_keycode_string(code).to_upper()
	return NOTHING


## How an event is written in the settings file.
##
## `key:32` rather than Godot's own serialisation, which is a hundred and
## eighty characters of object literal and unreadable in a config a player may
## well open.
static func as_text(event: InputEvent) -> String:
	var button := event as InputEventMouseButton
	if button != null:
		return "mouse:%d" % button.button_index
	var key := event as InputEventKey
	if key != null:
		return "key:%d" % (key.keycode if key.keycode != 0
			else key.physical_keycode)
	return ""


## And back again. Null for anything that is not one of those two shapes,
## which is what a hand-edited config gets.
static func from_text(text: String) -> InputEvent:
	var parts := text.split(":", true, 1)
	if parts.size() != 2 or not parts[1].is_valid_int():
		return null
	var number := int(parts[1])
	if parts[0] == "mouse":
		var button := InputEventMouseButton.new()
		button.button_index = number
		return button
	if parts[0] == "key":
		var key := InputEventKey.new()
		key.keycode = number
		return key
	return null


## Whether an event is one this game will take as a binding.
##
## **Not every key is a binding.** A modifier on its own binds an action to
## something that can never be pressed alone, and the three Godot reserves for
## the window would take the game away from the player with no way back.
static func is_bindable(event: InputEvent) -> bool:
	var button := event as InputEventMouseButton
	if button != null:
		return MOUSE_NAMES.has(button.button_index)
	var key := event as InputEventKey
	if key == null:
		return false
	var code := key.keycode if key.keycode != 0 else key.physical_keycode
	return not [KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_META, KEY_CAPSLOCK,
		KEY_NUMLOCK, KEY_SCROLLLOCK, KEY_UNKNOWN, 0].has(code)


## Whether two events are the same button or the same key.
static func same_event(a: InputEvent, b: InputEvent) -> bool:
	if a == null or b == null:
		return false
	return as_text(a) == as_text(b) and as_text(a) != ""


# ------------------------------------------------------------------- bindings

## What an action is bound to now, as events.
func events_of(action: StringName) -> Array:
	if not InputMap.has_action(String(action)):
		return []
	return InputMap.action_get_events(String(action))


## What an action is bound to now, as one line of screen text.
func text_of(action: StringName) -> String:
	var bits: Array = []
	for event in events_of(action):
		bits.append(label_of(event))
	return " / ".join(bits) if not bits.is_empty() else NOTHING


## Whether this action has been moved off what the game shipped with.
func rebound(action: StringName) -> bool:
	return _saved().has(String(action))


## Which other action already holds this event, or empty.
##
## **The action being rebound does not clash with itself.** Pressing the key
## something is already on is a player checking rather than a mistake.
func clash_of(action: StringName, event: InputEvent) -> StringName:
	for entry in ACTIONS:
		var other: StringName = entry[0]
		if other == action:
			continue
		for held in events_of(other):
			if same_event(held, event):
				return other
	return &""


## Put an action on an event, or say what stopped it.
##
## Returns `{"ok": bool, "clash": StringName, "why": String}`. `why` is what
## the screen prints, and it names the clash rather than saying no.
func bind(action: StringName, event: InputEvent) -> Dictionary:
	if not InputMap.has_action(String(action)):
		return {"ok": false, "clash": &"", "why": "NO SUCH ACTION"}
	if event == null or not is_bindable(event):
		return {"ok": false, "clash": &"", "why": "THAT KEY CANNOT BE BOUND"}
	var clash := clash_of(action, event)
	if clash != &"":
		return {"ok": false, "clash": clash,
			"why": "ALREADY %s" % label_for(clash)}
	var settings := _settings()
	if settings == null:
		return {"ok": false, "clash": &"", "why": "NO SETTINGS"}
	var saved := _saved().duplicate()
	saved[String(action)] = as_text(event)
	settings.set_value(KEY, saved)
	# **The one that changed a binding is the one that lands it.** `_ready`
	# hooks `Settings.changed` and that is what catches a change made
	# anywhere else, but a function that moves a key and leaves the input map
	# on the old one is a function whose caller has to know about a signal.
	# `apply()` starts from the photograph every time, so calling it twice
	# costs a rebuild of twenty-five actions and changes nothing.
	apply()
	return {"ok": true, "clash": &"", "why": ""}


## Put one action back to what the game shipped with.
func reset(action: StringName) -> void:
	var settings := _settings()
	if settings == null or not _saved().has(String(action)):
		return
	var saved := _saved().duplicate()
	saved.erase(String(action))
	settings.set_value(KEY, saved)
	apply()


## And all of them.
func reset_all() -> void:
	var settings := _settings()
	if settings == null or _saved().is_empty():
		return
	settings.set_value(KEY, {})
	apply()


# ------------------------------------------------------------------- applying

## Rewrite `InputMap` from the shipped defaults plus whatever was saved.
##
## Safe to call as often as anybody likes: it starts from the photograph every
## time rather than from whatever the last call left behind.
func apply() -> void:
	_photograph()
	var saved := _saved()
	for entry in ACTIONS:
		var action := String(entry[0])
		if not InputMap.has_action(action):
			continue
		InputMap.action_erase_events(action)
		if saved.has(action):
			var event := from_text(String(saved[action]))
			if event != null:
				InputMap.action_add_event(action, event)
				continue
			# A binding that will not parse is a config somebody edited by
			# hand. Fall through to the shipped keys rather than to nothing.
		for shipped in _shipped.get(action, []):
			InputMap.action_add_event(action, shipped)


## Take the photograph once, before anything has been rewritten.
func _photograph() -> void:
	if not _shipped.is_empty():
		return
	for entry in ACTIONS:
		var action := String(entry[0])
		if InputMap.has_action(action):
			_shipped[action] = InputMap.action_get_events(action).duplicate()


## What `project.godot` shipped an action with. Empty before the first apply.
func shipped_text(action: StringName) -> String:
	var bits: Array = []
	for event in _shipped.get(String(action), []):
		bits.append(label_of(event))
	return " / ".join(bits) if not bits.is_empty() else NOTHING


# ----------------------------------------------------------------- privately

func _saved() -> Dictionary:
	var settings := _settings()
	if settings == null:
		return {}
	return settings.get_dict(KEY)


func _on_changed(key: StringName) -> void:
	if key == KEY:
		apply()


func _settings() -> Node:
	var loop := Engine.get_main_loop() as SceneTree
	if loop == null or loop.root == null:
		return null
	return loop.root.get_node_or_null(^"Settings")
