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
var _play_on: Button

## Set by `main.gd`, so the ending can start a new run. The screen asks; the
## app does.
var driver: SimDriver
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
	# **Room for the itemised money.** A `PanelContainer` grows with what is
	# in it, and task 0061 added up to seven rows saying where the money came
	# from: at y=40 that pushed "back to the farm" off the bottom of a
	# two-hundred-and-seventy pixel screen and the run could not continue.
	# `input_check` asserts the button is on screen now.
	frame.position = Vector2(128, 30)
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
	_continue.clip_text = true
	_continue.custom_minimum_size = Vector2(206, 20)
	_continue.add_theme_font_size_override("font_size", 9)
	_continue.focus_mode = Control.FOCUS_ALL
	_continue.pressed.connect(_confirm)
	column.add_child(_continue)

	# **The second door, and it is only there at the end.** A run that has
	# been beaten offers to carry on; task 0070 is what makes night eleven
	# worth playing, and this is the switch that asks for it.
	_play_on = Button.new()
	_play_on.name = "PlayOnButton"
	_play_on.text = "PLAY ON - THE NIGHTS KEEP COMING"
	_play_on.clip_text = true
	_play_on.custom_minimum_size = Vector2(206, 20)
	_play_on.add_theme_font_size_override("font_size", 9)
	_play_on.focus_mode = Control.FOCUS_ALL
	_play_on.visible = false
	_play_on.pressed.connect(_carry_on)
	column.add_child(_play_on)


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
	# **At the end of a run, this button starts another one.** The run is
	# written to the profile first: a win that was not recorded is a win the
	# player did not have.
	if Run.is_over(_state):
		_record_and_restart()
		return
	(_state["intent"] as Dictionary)["confirm_result"] = true


## Carry on into the nights past the authored ten.
func _carry_on() -> void:
	if _state.is_empty() or not Run.is_over(_state):
		return
	_record(_state)
	Run.go_endless(_state)
	(_state["intent"] as Dictionary)["confirm_result"] = true


## Write the run to the profile and deal a new farm.
func _record_and_restart() -> void:
	_record(_state)
	if driver == null:
		return
	# A different seed, so a second run is a different farm's worth of luck.
	driver.start(int(Time.get_unix_time_from_system()) & 0x7FFFFFFF)
	_state = driver.state
	visible = false


## The profile is the thing that outlives a run.
func _record(state: Dictionary) -> void:
	var profile := Save.read_profile()
	Save.write_profile(Run.record(state, profile))


func _build(payout: Dictionary) -> void:
	for child in _lines.get_children():
		child.queue_free()
	if payout.is_empty():
		_title.text = "NIGHT OVER"
		return

	var survived := bool(payout["survived"])

	# **The end of the run gets its own screen.** Ten nights and the Giant is
	# the whole MVP, and a player who has just done it should not be handed
	# the same four lines they have read nine times.
	if _state != null and not _state.is_empty() and Run.is_over(_state):
		_build_the_ending()
		_continue.text = "A NEW FARM, A NEW TEN NIGHTS"
		_play_on.visible = true
		return
	_play_on.visible = false

	_title.text = "NIGHT %d %s" % [int(payout["night"]),
		"SURVIVED" if survived else "LOST"]
	_title.modulate = WON if survived else LOST

	# **Four numbers on two rows, not four.** A `Label` reserves its font's
	# line height whatever `custom_minimum_size` claims, so a row here is
	# twenty-two pixels: eight of them plus a title and a button is taller
	# than the screen, and the button goes off the bottom - which ends the
	# run, because "back to the farm" is the only way out of this screen.
	# `input_check` asserts it is on screen.
	_row("killed %d, %d got through" % [int(payout["killed"]),
		int(payout["breaches"])], "", DIM)
	_row("house %d/%d, %d built still up"
		% [int(payout["house_hp"]), GameData.HOUSE_HP,
			int(payout.get("structures", 0))],
		"%d untouched" % int(payout.get("intact", 0)), DIM)

	_gap()
	if survived:
		_row("PAID", "", WON)
		# Materials on one line and money on the next, for the same reason.
		var goods: Array = []
		var purse: Array = []
		for id in _sorted(payout["gained"] as Dictionary):
			var n := int((payout["gained"] as Dictionary)[id])
			if id == GameData.MONEY or id == GameData.TECH:
				purse.append("+%d %s" % [n, id])
			else:
				goods.append("+%d %s" % [n, id])
		if not goods.is_empty():
			_row("  " + "  ".join(goods), "", WON)
		if not purse.is_empty():
			_row("  " + "  ".join(purse), "", WON)

		# **What the defending was worth**, which is the half of `design.md`
		# section 12 that changes how the next night gets built: "+ $112"
		# tells a player they were paid, "for defending well + $32" tells
		# them what they were paid *for*.
		var from: Dictionary = payout.get("money_from", {})
		var well := int(from.get("nothing touched", 0)) 			+ int(from.get("still standing", 0)) 			+ int(from.get("the house untouched", 0))
		if well > 0:
			_row("  for defending well", "+%d" % well, WON)
	else:
		_row("LOST", "", LOST)
		var lost: Dictionary = payout["lost"]
		if lost.is_empty():
			_row("  nothing - there was nothing to take", "", DIM)
		else:
			var taken: Array = []
			for id in _sorted(lost):
				taken.append("-%d %s" % [int(lost[id]), id])
			_row("  " + "  ".join(taken), "", LOST)
		_gap()
		_row("money and the farm are untouched", "", DIM)

## The run summary: what the whole thing was.
##
## Every line is a lookup off `Run.summary()`, which is itself a lookup off
## the state. There is no second ledger here to disagree with the first.
func _build_the_ending() -> void:
	var run := Run.summary(_state)
	_title.text = "THE FARM HELD"
	_title.modulate = WON

	_row("%d days, %d nights, the Giant down"
		% [int(run["days"]), int(run["nights_won"])], "", WON)
	_row("zombies killed", str(int(run["killed"])), DIM)
	_row("got through", str(int(run["breaches"])), DIM)
	_row("structures lost", str(int(run["structures_lost"])), DIM)

	var hauled: Array = []
	for id in _sorted(run["gathered"] as Dictionary):
		hauled.append("%d %s" % [int((run["gathered"] as Dictionary)[id]), id])
	if not hauled.is_empty():
		_row("  gathered " + "  ".join(hauled.slice(0, 4)), "", DIM)

	_gap()
	_row("THE BUILD THAT WON", "", WON)
	var built: Array = []
	for id in _sorted(run["build"] as Dictionary):
		built.append("%d %s" % [int((run["build"] as Dictionary)[id]), id])
	_row("  " + ("  ".join(built) if not built.is_empty()
		else "nothing left standing"), "", WON)
	if not (run["technology"] as Array).is_empty():
		_row("  " + ", ".join(run["technology"] as Array), "", DIM)


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
