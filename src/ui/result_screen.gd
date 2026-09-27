class_name ResultScreen
extends Control

## What the night cost and what it paid.
##
## The moment `design.md` section 17 is actually about: the player finds out
## whether the thing they built worked, and decides to go back and make it
## better. So it shows **why**, not only how much - "you were paid more because
## nothing you built came down" is a sentence that changes how the next night
## gets built, and "+ $112" is not.
##
## Every number is read from `Rewards.last()`. The screen computes nothing: a
## total shown here and a total added to the ledger would be two numbers that
## could disagree, and the one the player believes is the one on screen.

const WON := Color(0.65, 0.92, 0.55)
const LOST := Color(0.94, 0.42, 0.38)
const DIM := Color(0.66, 0.64, 0.74)

var _state: Dictionary = {}
var _title: Label
var _lines: VBoxContainer
var _continue: Button
var _built_for := -1


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var dim := ColorRect.new()
	dim.name = "Dim"
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.color = Color(0.02, 0.02, 0.05, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var frame := PanelContainer.new()
	frame.name = "ResultFrame"
	frame.position = Vector2(128, 40)
	frame.custom_minimum_size = Vector2(224, 190)
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.07, 0.06, 0.12, 0.98)
	box.border_color = Color(0.55, 0.48, 0.35)
	box.set_border_width_all(1)
	box.set_content_margin_all(8)
	frame.add_theme_stylebox_override("panel", box)
	add_child(frame)

	var column := VBoxContainer.new()
	column.name = "ResultColumn"
	frame.add_child(column)

	_title = Label.new()
	_title.name = "ResultTitle"
	column.add_child(_title)

	_lines = VBoxContainer.new()
	_lines.name = "ResultLines"
	column.add_child(_lines)

	_continue = Button.new()
	_continue.name = "ContinueButton"
	_continue.text = "BACK TO THE FARM"
	_continue.custom_minimum_size = Vector2(206, 20)
	_continue.add_theme_font_size_override("font_size", 9)
	_continue.focus_mode = Control.FOCUS_ALL
	_continue.pressed.connect(_confirm)
	column.add_child(_continue)


func show_state(state: Dictionary) -> void:
	_state = state


func _process(_delta: float) -> void:
	if _state.is_empty():
		return
	var up := int(_state["phase"]) == Phases.RESULT
	if up != visible:
		visible = up
		if up:
			_built_for = -1
			_continue.grab_focus()
	if not visible:
		return

	var payout := Rewards.last(_state)
	var signature := int(payout.get("night", 0)) * 1000 \
		+ int(payout.get("killed", 0))
	if signature != _built_for:
		_built_for = signature
		_build(payout)

	# The keyboard reaches it without having to find it.
	if Input.is_action_just_pressed(&"interact") \
			or Input.is_action_just_pressed(&"night"):
		_confirm()


func _confirm() -> void:
	if _state.is_empty():
		return
	(_state["intent"] as Dictionary)["confirm_result"] = true


func _build(payout: Dictionary) -> void:
	for child in _lines.get_children():
		child.queue_free()
	if payout.is_empty():
		_title.text = "NIGHT OVER"
		return

	var survived := bool(payout["survived"])
	_title.text = "NIGHT %d %s" % [int(payout["night"]),
		"SURVIVED" if survived else "LOST"]
	_title.modulate = WON if survived else LOST

	_row("zombies killed", str(int(payout["killed"])), DIM)
	_row("got through", str(int(payout["breaches"])), DIM)
	_row("the house", "%d / %d" % [int(payout["house_hp"]), GameData.HOUSE_HP],
		DIM)
	_row("still standing", "%d" % int(payout["structures"]), DIM)

	_gap()
	if survived:
		_row("PAID", "", WON)
		for id in _sorted(payout["gained"] as Dictionary):
			var n := int((payout["gained"] as Dictionary)[id])
			_row("  " + str(id), "+%d" % n, WON)
	else:
		_row("LOST", "", LOST)
		var lost: Dictionary = payout["lost"]
		if lost.is_empty():
			_row("  nothing - there was nothing to take", "", DIM)
		for id in _sorted(lost):
			_row("  " + str(id), "-%d" % int(lost[id]), LOST)
		_gap()
		_row("money and the farm are untouched", "", DIM)


func _row(left: String, right: String, colour: Color) -> void:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(206, 11)
	_lines.add_child(row)

	var a := Label.new()
	a.text = left
	a.custom_minimum_size = Vector2(150, 0)
	a.add_theme_font_size_override("font_size", 9)
	a.modulate = colour
	row.add_child(a)

	var b := Label.new()
	b.text = right
	b.add_theme_font_size_override("font_size", 9)
	b.modulate = colour
	row.add_child(b)


func _gap() -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 5)
	_lines.add_child(spacer)


func _sorted(d: Dictionary) -> Array:
	var keys: Array = d.keys()
	keys.sort()
	return keys
