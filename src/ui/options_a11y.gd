class_name OptionsA11y
extends Control

## The access tab: the eight settings that decide whether somebody can play.
##
## Like the other four it owns no policy. What the numbers are and what they
## mean is `A11y`'s; the screens that read them have read them for tasks -
## shake since 0055, lamps since 0076, particles since 0077, hit stop since
## 0088 - and what was missing was somewhere to turn them.
##
## ## Three choices, not a slider
##
## Everything here except the two switches is a small list of named steps.
## A slider from nought to two asks a player how much screen shake they want
## in decimals; **OFF, HALF and FULL** asks them a question they can answer.

## Each row: the setting, its label, and what it offers.
##
## An empty list of choices means a switch. A list of `[value, key]` pairs is
## a row of buttons, in the order they are offered.
const ROWS: Array = [
	[&"a11y/screen_shake", &"ACC_SHAKE", [
		[0.0, &"ACC_OFF"], [0.5, &"ACC_HALF"], [1.0, &"ACC_FULL"]]],
	[&"a11y/flashing", &"ACC_FLASHING", []],
	[&"a11y/hit_stop", &"ACC_HIT_STOP", []],
	[&"a11y/particle_density", &"ACC_PARTICLES", [
		[0.0, &"ACC_OFF"], [0.5, &"ACC_HALF"], [1.0, &"ACC_FULL"]]],
	[&"a11y/ui_scale", &"ACC_PICTURE", [
		[1.0, &"ACC_SIZE_1"], [1.25, &"ACC_SIZE_2"], [1.5, &"ACC_SIZE_3"]]],
	[&"a11y/high_contrast", &"ACC_CONTRAST", []],
	[&"a11y/hold_to_act", &"ACC_HOLD", []],
	[&"a11y/slow", &"ACC_SLOW", [
		[1.0, &"ACC_SPEED_1"], [0.75, &"ACC_SPEED_2"],
		[0.5, &"ACC_SPEED_3"]]],
]

var _settings: Node

var _column: VBoxContainer
var _labels: Dictionary = {}        # settings key -> its Label
var _holders: Dictionary = {}       # settings key -> the row of buttons
var _switches: Dictionary = {}      # settings key -> its Button
var _note: Label


func _ready() -> void:
	_settings = get_node_or_null(^"/root/Settings")
	set_anchors_preset(Control.PRESET_FULL_RECT)
	if _settings != null:
		_settings.changed.connect(_on_setting)

	_column = VBoxContainer.new()
	_column.name = "AccessColumn"
	_column.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_column)

	for row in ROWS:
		_build_row(row as Array)

	_note = Label.new()
	_note.name = "AccessNote"
	_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_note.custom_minimum_size = Vector2(330, 16)
	_note.theme_type_variation = UiKit.DIM
	_column.add_child(_note)

	relabel()


func _build_row(row: Array) -> void:
	var key: StringName = row[0]
	var bare := String(key).get_slice("/", 1)
	var line := HBoxContainer.new()
	line.name = "Access%sRow" % bare.capitalize()
	line.theme_type_variation = UiKit.SPACED
	_column.add_child(line)

	var label := Label.new()
	label.custom_minimum_size = Vector2(112, 0)
	label.theme_type_variation = UiKit.DIM
	line.add_child(label)
	_labels[key] = label

	if (row[2] as Array).is_empty():
		var switch := Button.new()
		switch.name = "Access_%s" % bare
		switch.toggle_mode = true
		switch.custom_minimum_size = Vector2(40, 13)
		switch.focus_mode = Control.FOCUS_ALL
		switch.pressed.connect(_toggle.bind(key))
		line.add_child(switch)
		_switches[key] = switch
		return

	var holder := HBoxContainer.new()
	holder.name = "Access%sChoices" % bare.capitalize()
	holder.theme_type_variation = UiKit.SPACED
	line.add_child(holder)
	_holders[key] = holder


# ----------------------------------------------------------------- the state

## Say it all again, in whatever language and contrast is up now.
func relabel() -> void:
	if _column == null:
		return
	for row in ROWS:
		var key: StringName = row[0]
		(_labels[key] as Label).text = I18n.t(row[1])
	_note.text = I18n.t(&"ACC_NOTE")
	_fill()


func _fill() -> void:
	if _settings == null:
		return
	for row in ROWS:
		var key: StringName = row[0]
		var choices: Array = row[2]
		if choices.is_empty():
			var switch: Button = _switches[key]
			switch.button_pressed = bool(_settings.get_bool(key))
			switch.text = I18n.t(&"OPT_ON") if switch.button_pressed \
				else I18n.t(&"OPT_OFF")
			continue
		var holder: HBoxContainer = _holders[key]
		for child in holder.get_children():
			holder.remove_child(child)
			child.queue_free()
		var now := float(_settings.get_float(key))
		for one in choices:
			var value := float((one as Array)[0])
			var button := Button.new()
			button.name = "Access_%s_%d" % [String(key).get_slice("/", 1),
				int(round(value * 100.0))]
			button.text = I18n.t((one as Array)[1])
			button.toggle_mode = true
			button.button_pressed = is_equal_approx(now, value)
			button.theme_type_variation = UiKit.TAB
			button.custom_minimum_size = Vector2(62, 13)
			button.focus_mode = Control.FOCUS_ALL
			button.pressed.connect(_pick.bind(key, value))
			holder.add_child(button)


# ---------------------------------------------------------------- the clicks

func _pick(key: StringName, value: float) -> void:
	if _settings != null:
		_settings.set_value(key, value)


func _toggle(key: StringName) -> void:
	if _settings != null:
		_settings.set_value(key, (_switches[key] as Button).button_pressed)


func _on_setting(key: StringName) -> void:
	if String(key).begins_with("a11y/"):
		_fill()


# ------------------------------------------------------------ for the checks

func rows() -> int:
	return ROWS.size()


func chosen(key: StringName) -> float:
	var holder: HBoxContainer = _holders.get(key, null)
	if holder == null:
		var switch: Button = _switches.get(key, null)
		return 1.0 if switch != null and switch.button_pressed else 0.0
	for child in holder.get_children():
		if (child as Button).button_pressed:
			return float(String(child.name).get_slice("_", 2).to_int()) / 100.0
	return -1.0
