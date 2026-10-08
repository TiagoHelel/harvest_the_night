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
	[&"move_up", &"ACT_MOVE_UP", &"ACT_GROUP_MOVING"],
	[&"move_down", &"ACT_MOVE_DOWN", &"ACT_GROUP_MOVING"],
	[&"move_left", &"ACT_MOVE_LEFT", &"ACT_GROUP_MOVING"],
	[&"move_right", &"ACT_MOVE_RIGHT", &"ACT_GROUP_MOVING"],
	[&"run", &"ACT_RUN", &"ACT_GROUP_MOVING"],

	[&"interact", &"ACT_INTERACT", &"ACT_GROUP_FARM"],
	[&"inventory", &"ACT_INVENTORY", &"ACT_GROUP_FARM"],
	[&"slot_1", &"ACT_SLOT_1", &"ACT_GROUP_FARM"],
	[&"slot_2", &"ACT_SLOT_2", &"ACT_GROUP_FARM"],
	[&"slot_3", &"ACT_SLOT_3", &"ACT_GROUP_FARM"],
	[&"slot_4", &"ACT_SLOT_4", &"ACT_GROUP_FARM"],
	[&"slot_5", &"ACT_SLOT_5", &"ACT_GROUP_FARM"],
	[&"slot_6", &"ACT_SLOT_6", &"ACT_GROUP_FARM"],
	# Seeds by day, the hotbar's slots at night (task 0133): two more for it.
	[&"slot_7", &"ACT_SLOT_7", &"ACT_GROUP_FARM"],
	[&"slot_8", &"ACT_SLOT_8", &"ACT_GROUP_FARM"],

	[&"build", &"ACT_BUILD", &"ACT_GROUP_BUILD"],
	[&"place", &"ACT_PLACE", &"ACT_GROUP_BUILD"],
	[&"remove", &"ACT_REMOVE", &"ACT_GROUP_BUILD"],
	[&"upgrade", &"ACT_UPGRADE", &"ACT_GROUP_BUILD"],

	[&"night", &"ACT_NIGHT", &"ACT_GROUP_NIGHT"],
	# START (task 0136): the build step waits for it. Not the GO TO BED key,
	# so a double press cannot skip the build step.
	[&"start_waves", &"ACT_START", &"ACT_GROUP_NIGHT"],
	[&"ability", &"ACT_ABILITY", &"ACT_GROUP_NIGHT"],
	[&"speed", &"ACT_SPEED", &"ACT_GROUP_NIGHT"],
	[&"skip_night", &"ACT_SKIP_NIGHT", &"ACT_GROUP_NIGHT"],
	# The night camera (task 0130): the right stick's own, beside the move
	# keys that also pan once he is in bed.
	[&"pan_left", &"ACT_PAN_LEFT", &"ACT_GROUP_NIGHT"],
	[&"pan_right", &"ACT_PAN_RIGHT", &"ACT_GROUP_NIGHT"],
	[&"pan_up", &"ACT_PAN_UP", &"ACT_GROUP_NIGHT"],
	[&"pan_down", &"ACT_PAN_DOWN", &"ACT_GROUP_NIGHT"],
	# The hotbar of defences (task 0133): the bumpers on a pad.
	[&"hotbar_prev", &"ACT_HOTBAR_PREV", &"ACT_GROUP_NIGHT"],
	[&"hotbar_next", &"ACT_HOTBAR_NEXT", &"ACT_GROUP_NIGHT"],

	[&"pause", &"ACT_PAUSE", &"ACT_GROUP_SCREENS"],
	[&"cancel", &"ACT_CANCEL", &"ACT_GROUP_SCREENS"],
	[&"tech", &"ACT_TECH", &"ACT_GROUP_SCREENS"],
	[&"stats", &"ACT_STATS", &"ACT_GROUP_SCREENS"],
	[&"log", &"ACT_LOG", &"ACT_GROUP_SCREENS"],
]

## What a mouse button is called. Godot's own `as_text()` says "Left Mouse
## Button (Left Mouse Button)" in places, which is not a thing to put on a
## screen eight pixels tall.
const MOUSE_NAMES: Dictionary = {
	MOUSE_BUTTON_LEFT: &"ACT_MOUSE_LEFT",
	MOUSE_BUTTON_RIGHT: &"ACT_MOUSE_RIGHT",
	MOUSE_BUTTON_MIDDLE: &"ACT_MOUSE_MIDDLE",
	MOUSE_BUTTON_WHEEL_UP: &"ACT_MOUSE_WHEEL_UP",
	MOUSE_BUTTON_WHEEL_DOWN: &"ACT_MOUSE_WHEEL_DOWN",
}

## What a pad button is called (task 0121), Xbox names, from the table so the
## language can say "DIRECIONAL" where English says "D-PAD".
const PAD_NAMES: Dictionary = {
	JOY_BUTTON_A: &"ACT_PAD_A",
	JOY_BUTTON_B: &"ACT_PAD_B",
	JOY_BUTTON_X: &"ACT_PAD_X",
	JOY_BUTTON_Y: &"ACT_PAD_Y",
	JOY_BUTTON_LEFT_SHOULDER: &"ACT_PAD_LB",
	JOY_BUTTON_RIGHT_SHOULDER: &"ACT_PAD_RB",
	JOY_BUTTON_START: &"ACT_PAD_START",
	JOY_BUTTON_BACK: &"ACT_PAD_BACK",
	JOY_BUTTON_LEFT_STICK: &"ACT_PAD_L3",
	JOY_BUTTON_RIGHT_STICK: &"ACT_PAD_R3",
	JOY_BUTTON_DPAD_UP: &"ACT_PAD_DPAD_UP",
	JOY_BUTTON_DPAD_DOWN: &"ACT_PAD_DPAD_DOWN",
	JOY_BUTTON_DPAD_LEFT: &"ACT_PAD_DPAD_LEFT",
	JOY_BUTTON_DPAD_RIGHT: &"ACT_PAD_DPAD_RIGHT",
}

## A stick or trigger direction, `"<axis>:<sign>"` -> its name.
const AXIS_NAMES: Dictionary = {
	"0:-1": &"ACT_PAD_LS_LEFT",
	"0:1": &"ACT_PAD_LS_RIGHT",
	"1:-1": &"ACT_PAD_LS_UP",
	"1:1": &"ACT_PAD_LS_DOWN",
	"2:-1": &"ACT_PAD_RS_LEFT",
	"2:1": &"ACT_PAD_RS_RIGHT",
	"3:-1": &"ACT_PAD_RS_UP",
	"3:1": &"ACT_PAD_RS_DOWN",
	"4:1": &"ACT_PAD_LT",
	"5:1": &"ACT_PAD_RT",
}

## How far a stick or trigger has to go before a rebind takes it as the
## answer. Half way: a resting stick drifts, a meant one does not stop there.
const PAD_TAKE := 0.5

## The suffix a pad binding is saved under, beside the keyboard one. See
## `bind()`.
const PAD_SUFFIX := "@pad"

## What a binding with no event at all shows as. It cannot happen through the
## screen - a rebind always takes an event - but a hand-edited config can.
const NOTHING := &"CTL_NOTHING"

## Said whenever the last thing the player touched changed between a pad and
## the keyboard or mouse, so hints and the controls page can relabel.
signal device_changed(using_pad: bool)

## Whether the last input came from a pad. **View only**: it decides which
## names `text_of()` shows, and nothing the rules read.
var using_pad := false

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
			return I18n.t(entry[1])
	return String(action).to_upper()


## The group's own key, so a screen can put a heading on it in whatever
## language is up.
static func group_for(action: StringName) -> StringName:
	for entry in ACTIONS:
		if entry[0] == action:
			return entry[2]
	return &""


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
		if MOUSE_NAMES.has(button.button_index):
			return I18n.t(MOUSE_NAMES[button.button_index])
		return I18n.f(&"ACT_MOUSE_OTHER", [button.button_index])
	var key := event as InputEventKey
	if key != null:
		var code := key.keycode if key.keycode != 0 else key.physical_keycode
		# **Not translated.** A key is called whatever is printed on it, and
		# the keyboard in front of the player says Q whatever the menu says.
		return OS.get_keycode_string(code).to_upper()
	var pad := event as InputEventJoypadButton
	if pad != null:
		if PAD_NAMES.has(pad.button_index):
			return I18n.t(PAD_NAMES[pad.button_index])
		return I18n.f(&"ACT_PAD_OTHER", [pad.button_index])
	var stick := event as InputEventJoypadMotion
	if stick != null:
		var named := "%d:%d" % [stick.axis, 1 if stick.axis_value > 0.0 else -1]
		if AXIS_NAMES.has(named):
			return I18n.t(AXIS_NAMES[named])
		return I18n.f(&"ACT_PAD_OTHER", [stick.axis])
	return I18n.t(NOTHING)


## Whether an event came from a pad - a button, a stick or a trigger.
static func is_pad(event: InputEvent) -> bool:
	return event is InputEventJoypadButton or event is InputEventJoypadMotion


## "Press any key", made true for every device: a key going down (not a
## repeat), a click, or a pad button. The title and the studio ident ask this
## rather than each naming the pad (task 0121).
static func is_any_press(event: InputEvent) -> bool:
	if event is InputEventKey:
		return event.is_pressed() and not event.is_echo()
	return (event is InputEventMouseButton or event is InputEventJoypadButton) \
		and event.is_pressed()


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
	var pad := event as InputEventJoypadButton
	if pad != null:
		return "joy:%d" % pad.button_index
	var stick := event as InputEventJoypadMotion
	if stick != null and not is_zero_approx(stick.axis_value):
		return "axis:%d:%d" % [stick.axis, 1 if stick.axis_value > 0.0 else -1]
	return ""


## And back again. Null for anything that is not one of those shapes, which
## is what a hand-edited config gets.
static func from_text(text: String) -> InputEvent:
	if text.begins_with("axis:"):
		var bits := text.split(":")
		if bits.size() != 3 or not bits[1].is_valid_int() \
				or not bits[2].is_valid_int() or absi(int(bits[2])) != 1:
			return null
		var stick := InputEventJoypadMotion.new()
		stick.axis = int(bits[1]) as JoyAxis
		stick.axis_value = float(int(bits[2]))
		return stick
	var parts := text.split(":", true, 1)
	if parts.size() != 2 or not parts[1].is_valid_int():
		return null
	var number := int(parts[1])
	if parts[0] == "joy":
		var pad := InputEventJoypadButton.new()
		pad.button_index = number as JoyButton
		return pad
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
## Shift is a standalone hold action for the run animation. Other modifiers
## and lock keys remain unavailable as lone bindings.
static func is_bindable(event: InputEvent) -> bool:
	var button := event as InputEventMouseButton
	if button != null:
		return MOUSE_NAMES.has(button.button_index)
	# A pad button with a name, or a stick or trigger pushed past half way.
	# The guide button belongs to the system, so it has no name here.
	var pad := event as InputEventJoypadButton
	if pad != null:
		return PAD_NAMES.has(pad.button_index)
	var stick := event as InputEventJoypadMotion
	if stick != null:
		return absf(stick.axis_value) >= PAD_TAKE \
			and AXIS_NAMES.has("%d:%d" % [stick.axis, 1 if stick.axis_value > 0.0 else -1])
	var key := event as InputEventKey
	if key == null:
		return false
	var code := key.keycode if key.keycode != 0 else key.physical_keycode
	return not [KEY_CTRL, KEY_ALT, KEY_META, KEY_CAPSLOCK,
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


## What an action is bound to now, as one line of screen text - **on the
## device in the player's hand** (task 0121): a pad's buttons after a pad was
## touched, the keyboard and mouse otherwise. An action the pad has no button
## for shows its key rather than nothing.
func text_of(action: StringName) -> String:
	return _shown(events_of(action))


## Whether this action has been moved off what the game shipped with, on
## either device.
func rebound(action: StringName) -> bool:
	var saved := _saved()
	return saved.has(String(action)) or saved.has(String(action) + PAD_SUFFIX)


## The labels of the events for the device in hand, joined.
func _shown(events: Array) -> String:
	var mine: Array = []
	for event in events:
		if is_pad(event) == using_pad:
			mine.append(event)
	if mine.is_empty():
		mine = events
	var bits: Array = []
	for event in mine:
		bits.append(label_of(event))
	return " / ".join(bits) if not bits.is_empty() else I18n.t(NOTHING)


## Remember which device the player last touched, and say when it changes.
func _input(event: InputEvent) -> void:
	var pad := false
	if event is InputEventJoypadButton:
		pad = true
	elif event is InputEventJoypadMotion:
		# A stick at rest still reports; only a deliberate push counts.
		if absf((event as InputEventJoypadMotion).axis_value) < PAD_TAKE:
			return
		pad = true
	elif not (event is InputEventKey or event is InputEventMouseButton):
		return
	if pad != using_pad:
		using_pad = pad
		device_changed.emit(pad)


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
		return {"ok": false, "clash": &"", "why": I18n.t(&"CTL_NO_ACTION")}
	if event == null or not is_bindable(event):
		return {"ok": false, "clash": &"",
			"why": I18n.t(&"CTL_UNBINDABLE")}
	var clash := clash_of(action, event)
	if clash != &"":
		return {"ok": false, "clash": clash,
			"why": I18n.f(&"CTL_CLASH", [label_for(clash)])}
	var settings := _settings()
	if settings == null:
		return {"ok": false, "clash": &"",
			"why": I18n.t(&"CTL_NO_SETTINGS")}
	# **One binding per device kind** (task 0121): a pad event is saved under
	# `<action>@pad` beside the keyboard or mouse one, so moving the key keeps
	# the pad button and moving the button keeps the key. A saved value from
	# before pads, `key:` or `mouse:` under the bare name, is the keyboard's.
	var saved := _saved().duplicate()
	saved[String(action) + (PAD_SUFFIX if is_pad(event) else "")] = as_text(event)
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
	if settings == null or not rebound(action):
		return
	var saved := _saved().duplicate()
	saved.erase(String(action))
	saved.erase(String(action) + PAD_SUFFIX)
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
		# Each device kind on its own: the saved binding if there is one that
		# parses, the shipped events of that kind if not. A binding that will
		# not parse is a config somebody edited by hand - it falls through to
		# the shipped ones rather than to nothing.
		for pad in [false, true]:
			var slot := action + (PAD_SUFFIX if pad else "")
			var event: InputEvent = from_text(String(saved[slot])) \
				if saved.has(slot) else null
			if event != null and is_pad(event) == pad:
				InputMap.action_add_event(action, event)
				continue
			for shipped in _shipped.get(action, []):
				if is_pad(shipped) == pad:
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
	return _shown(_shipped.get(String(action), []))


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
