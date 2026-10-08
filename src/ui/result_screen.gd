class_name ResultScreen
extends Control

## The morning report (task 0138): what the night cost and what it paid, read
## at 06:00 before he gets out of bed.
##
## Every night ends here, won or lost: a sunrise, the day it is now, the night
## that brought it, what came in, what was lost, how many walked off at dawn
## and what the night left lying on the farm. Confirming is the same
## `confirm_result` it always was, and the morning begins beside his bed.
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


var _state: Dictionary = {}
var _header: Control
var _day: Label
var _title: Label
var _lines: VBoxContainer
var _continue: Button
var _play_on: Button

## Set by `main.gd`, so the ending can start a new run. The screen asks; the
## app does.
var driver: SimDriver
var _built_for := ""

## **The sunrise is A057's** (`sprites/ui/report_header.png`), registered on
## the placeholder road: until the pack is integrated - and for good if the
## owner declines it - the band below is drawn in code at its canvas.
const HEADER := &"report_header"


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
	add_child(frame)

	var column := VBoxContainer.new()
	column.name = "ResultColumn"
	frame.add_child(column)

	_header = _make_header()
	column.add_child(_header)

	_day = Label.new()
	_day.name = "ReportDay"
	_day.theme_type_variation = UiKit.WARM
	column.add_child(_day)

	_title = Label.new()
	_title.name = "ResultTitle"
	column.add_child(_title)

	_lines = VBoxContainer.new()
	_lines.name = "ResultLines"
	column.add_child(_lines)

	_continue = Button.new()
	_continue.name = "ContinueButton"
	_continue.text = I18n.t(&"RES_GET_UP")
	_continue.clip_text = true
	_continue.custom_minimum_size = Vector2(206, 20)
	_continue.focus_mode = Control.FOCUS_ALL
	_continue.pressed.connect(_confirm)
	column.add_child(_continue)

	# **The second door, and it is only there at the end.** A run that has
	# been beaten offers to carry on; task 0070 is what makes night eleven
	# worth playing, and this is the switch that asks for it.
	_play_on = Button.new()
	_play_on.name = "PlayOnButton"
	_play_on.text = I18n.t(&"RES_PLAY_ON")
	_play_on.clip_text = true
	_play_on.custom_minimum_size = Vector2(206, 20)
	_play_on.focus_mode = Control.FOCUS_ALL
	_play_on.visible = false
	_play_on.pressed.connect(_carry_on)
	column.add_child(_play_on)


## A057's picture once it is on disk, the code-drawn band until then.
func _make_header() -> Control:
	var path := PlaceholderArt.art_path(HEADER, 0)
	var made: Control
	if PlaceholderArt.is_drawn(path):
		made = Control.new()
		made.draw.connect(_draw_sunrise)
	else:
		var picture := TextureRect.new()
		picture.texture = load(PlaceholderArt.texture_path(path))
		picture.stretch_mode = TextureRect.STRETCH_KEEP
		made = picture
	made.name = "ReportHeader"
	made.custom_minimum_size = Vector2(PlaceholderArt.frame(path).get("canvas", Vector2i(206, 40)))
	made.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	made.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return made


func show_state(state: Dictionary) -> void:
	_state = state


func _process(_delta: float) -> void:
	if _state.is_empty():
		return
	var up := int(_state["phase"]) == Phases.RESULT
	if up != visible:
		visible = up
		if up:
			_built_for = ""
			_continue.grab_focus()
	if not visible:
		return

	var payout := Rewards.last(_state)
	# Rebuilt when the night, the morning or the language changes.
	var signature := "%d/%d/%d/%d" % [int(payout.get("night", 0)),
		int(payout.get("killed", 0)), int(_state["day"]), I18n.revision()]
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
	_header.visible = true
	_day.visible = true
	_day.text = I18n.f(&"RES_MORNING", [int(_state["day"])])
	_continue.text = I18n.t(&"RES_GET_UP")
	if payout.is_empty():
		_title.text = I18n.t(&"RES_NIGHT_OVER")
		return

	var survived := bool(payout["survived"])
	var escaped := bool(payout.get("escaped", false))

	# **The end of the run gets its own screen.** Ten nights and the Giant is
	# the whole MVP, and a player who has just done it should not be handed
	# the same four lines they have read nine times. It stays as it was
	# until task 0160 reworks it: no sunrise, no morning heading.
	if _state != null and not _state.is_empty() and Run.is_over(_state):
		_header.visible = false
		_day.visible = false
		_build_the_ending()
		_continue.text = I18n.t(&"RES_NEW_FARM")
		_play_on.visible = true
		return
	_play_on.visible = false

	_title.text = I18n.f(&"RES_NIGHT", [int(payout["night"]),
		I18n.t(&"RES_SURVIVED" if survived else &"RES_WAS_LOST")])
	_title.theme_type_variation = UiKit.GOOD if survived else UiKit.BAD
	# **A boss that lived to dawn** (task 0153) neither won nor lost the
	# night: the night is over, and it is coming back.
	if escaped:
		_title.text = I18n.t(&"RES_NIGHT_OVER")
		_title.theme_type_variation = UiKit.WARN

	# **Four numbers on two rows, not four.** A `Label` reserves its font's
	# line height whatever `custom_minimum_size` claims, so a row here is
	# twenty-two pixels: eight of them plus a title and a button is taller
	# than the screen, and the button goes off the bottom - which ends the
	# run, because "back to the farm" is the only way out of this screen.
	# `input_check` asserts it is on screen.
	_row(I18n.f(&"RES_KILLED", [int(payout["killed"]),
		int(payout["breaches"])]), "", UiKit.DIM)
	# **Shorter than it reads.** The font's digits are tabular and six pixels
	# wide, so "house 100/100, 19 built still up" is a hundred and seventy
	# pixels in a column a hundred and fifty wide - it overran and collided
	# with the count beside it. Counting the characters is not the same as
	# measuring the string.
	_row(I18n.f(&"RES_HOUSE",
		# Recomputed rather than recorded: the tree only changes by day
		# (`Tech.buy` and `Tech.refund` refuse anything else), and this
		# screen is only up in RESULT, so it is the night's own number.
		[int(payout["house_hp"]), Phases.house_full(_state),
			int(payout.get("structures", 0))]),
		I18n.f(&"RES_UNTOUCHED", [int(payout.get("intact", 0))]),
		UiKit.DIM)
	# Whoever was still on the farm when it ended goes with the morning; a
	# night won by killing everything has nobody left to say so about.
	var walked := int(payout.get("walked", 0))
	if walked > 0:
		_row(I18n.plural(&"RES_WALKED", walked, [walked]), "", UiKit.DIM)
	var fell := int(payout.get("structures_lost", 0))
	if fell > 0:
		_row(I18n.plural(&"RES_CAME_DOWN", fell, [fell]), "", UiKit.BAD)
	# **The field the horde walked through** (task 0155).
	var trampled := int(payout.get("trampled", 0))
	if trampled > 0:
		_row(I18n.plural(&"RES_TRAMPLED", trampled, [trampled]), "", UiKit.BAD)

	_gap()
	if escaped:
		_wrapped(I18n.f(&"RES_BOSS_ESCAPED",
			[Names.of(StringName(payout.get("boss", &""))).to_upper()]), UiKit.WARN)
		_row(I18n.t(&"RES_UNTOUCHED_ALL"), "", UiKit.DIM)
	elif bool(payout.get("calm", false)):
		# **The calm night** (task 0154): the horde regrouped, and what is
		# on the porch is all it pays.
		_wrapped(I18n.t(&"RES_CALM_NIGHT"), UiKit.GOOD)
		_row(I18n.t(&"RES_GIFT"), "", UiKit.GOOD)
		var gift: Array = []
		for id in _sorted(payout["gained"] as Dictionary):
			gift.append(I18n.f(&"RES_GAINED", [int((payout["gained"] as Dictionary)[id]),
				Names.of(id)]))
		_row(I18n.f(&"RES_INDENT", ["  ".join(gift)]), "", UiKit.GOOD)
	elif survived:
		_row(I18n.t(&"RES_PAID"), "", UiKit.GOOD)
		# Materials on one line and money on the next, for the same reason -
		# named like the rest since 0138: the bare ids printed "+70 money" on
		# the Portuguese report.
		var goods: Array = []
		var purse: Array = []
		for id in _sorted(payout["gained"] as Dictionary):
			var n := int((payout["gained"] as Dictionary)[id])
			var said := I18n.f(&"RES_GAINED", [n, Names.of(id)])
			if id == GameData.MONEY or id == GameData.TECH:
				purse.append(said)
			else:
				goods.append(said)
		if not goods.is_empty():
			_row(I18n.f(&"RES_INDENT", ["  ".join(goods)]), "", UiKit.GOOD)
		if not purse.is_empty():
			_row(I18n.f(&"RES_INDENT", ["  ".join(purse)]), "", UiKit.GOOD)

		# **What the defending was worth**, which is the half of `design.md`
		# section 12 that changes how the next night gets built: "+ $112"
		# tells a player they were paid, "for defending well + $32" tells
		# them what they were paid *for*.
		var from: Dictionary = payout.get("money_from", {})
		var well := int(from.get("nothing touched", 0)) \
			+ int(from.get("still standing", 0)) \
			+ int(from.get("the house untouched", 0))
		if well > 0:
			_row(I18n.t(&"RES_DEFENDING_WELL"),
				I18n.f(&"RES_PLUS", [well]), UiKit.GOOD)
		# **The Full Moon's share** (task 0152), its own line: the materials
		# above are already its percent of an ordinary night's.
		var moon := int(from.get("full moon", 0))
		if moon > 0:
			_row(I18n.f(&"RES_INDENT", [I18n.t(&"RES_FULL_MOON")]),
				I18n.f(&"RES_PLUS", [moon]), UiKit.GOOD)
	else:
		_row(I18n.t(&"RES_LOST"), "", UiKit.BAD)
		var lost: Dictionary = payout["lost"]
		if lost.is_empty():
			_row(I18n.t(&"RES_NOTHING_TO_TAKE"), "", UiKit.DIM)
		else:
			var taken: Array = []
			for id in _sorted(lost):
				taken.append(I18n.f(&"RES_TAKEN",
					[int(lost[id]), Names.of(id)]))
			_row(I18n.f(&"RES_INDENT", ["  ".join(taken)]), "", UiKit.BAD)
		_row(I18n.t(&"RES_UNTOUCHED_ALL"), "", UiKit.DIM)

	_gap()
	# **A night that began with him face down at 02:00** (task 0128) had the
	# short build step, and the morning says why.
	if House.passed_out(_state):
		var at := GameData.DAY_END_MINUTE
		_row(I18n.f(&"RES_PASSED_OUT", [(at / 60) % 24, at % 60]), "",
			UiKit.WARN)
	# **What the night left lying on the farm**: nothing yet - phase 13's
	# bones and moon stones are what fill this line.
	_row(I18n.t(&"RES_LEFTOVERS"), "", UiKit.DIM)


## The run summary: what the whole thing was.
##
## Every line is a lookup off `Run.summary()`, which is itself a lookup off
## the state. There is no second ledger here to disagree with the first.
func _build_the_ending() -> void:
	var run := Run.summary(_state)
	_title.text = I18n.t(&"RES_FARM_HELD")
	_title.theme_type_variation = UiKit.GOOD

	_row(I18n.f(&"RES_RUN_LINE",
		[int(run["days"]), int(run["nights_won"])]), "",
		UiKit.GOOD)
	_row(I18n.t(&"RES_ZOMBIES"), str(int(run["killed"])), UiKit.DIM)
	_row(I18n.t(&"RES_GOT_THROUGH"), str(int(run["breaches"])),
		UiKit.DIM)
	_row(I18n.t(&"RES_STRUCTURES_LOST"),
		str(int(run["structures_lost"])), UiKit.DIM)

	var hauled: Array = []
	for id in _sorted(run["gathered"] as Dictionary):
		hauled.append(I18n.f(&"RES_COUNTED",
			[int((run["gathered"] as Dictionary)[id]), Names.of(id)]))
	if not hauled.is_empty():
		_row(I18n.f(&"RES_GATHERED", ["  ".join(hauled.slice(0, 4))]),
			"", UiKit.DIM)

	_gap()
	_row(I18n.t(&"RES_BUILD_WON"), "", UiKit.GOOD)
	var built: Array = []
	for id in _sorted(run["build"] as Dictionary):
		built.append(I18n.f(&"RES_COUNTED",
			[int((run["build"] as Dictionary)[id]), Names.of(id)]))
	_row(I18n.f(&"RES_INDENT", ["  ".join(built) if not built.is_empty()
		else I18n.t(&"RES_NOTHING_STANDING")]), "",
		UiKit.GOOD)
	if not (run["technology"] as Array).is_empty():
		_row(I18n.f(&"RES_INDENT", [", ".join(_named(
			run["technology"] as Array))]), "", UiKit.DIM)


func _row(left: String, right: String, role: StringName = &"") -> void:
	var row := HBoxContainer.new()
	row.theme_type_variation = UiKit.SPACED
	row.custom_minimum_size = Vector2(206, 11)
	_lines.add_child(row)

	var a := Label.new()
	a.text = left
	a.custom_minimum_size = Vector2(150, 0)
	a.theme_type_variation = role
	row.add_child(a)

	var b := Label.new()
	b.text = right
	b.theme_type_variation = role
	row.add_child(b)


## A line that may be longer than a row, wrapped onto as many as it needs
## inside the row's width: a boss's escape (task 0153), whose name the
## line cannot know the length of.
func _wrapped(text: String, role: StringName = &"") -> void:
	var line := Label.new()
	line.text = text
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line.custom_minimum_size = Vector2(206, 0)
	line.theme_type_variation = role
	_lines.add_child(line)


## A list of ids as a list of names.
func _named(ids: Array) -> Array:
	var out: Array = []
	for id in ids:
		out.append(Names.of(StringName(id)))
	return out


func _gap() -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 5)
	_lines.add_child(spacer)


## **The code-drawn sunrise** over the farmhouse, at A057's 206x40 canvas and
## in its composition: the sky in flat stepped bands down to the horizon at
## row 26, a half sun rising left of a small distant house - lit from the
## upper left as in the game - and the fields in front with the path to the
## door. Palette colours only, opaque edge to edge; no text, no frame.
func _draw_sunrise() -> void:
	var w := int(_header.size.x)
	var c: Dictionary = PaletteData.COLOURS
	# The sky, top to bottom, each band stepping into the next in clusters
	# rather than a straight edge.
	var bands := [[0, &"night_light"], [6, &"cloth_light"], [12, &"water_light"],
		[17, &"roof_light"], [22, &"flame"]]
	for i in bands.size():
		var top: int = bands[i][0]
		var bottom: int = bands[i + 1][0] if i + 1 < bands.size() else 26
		_header.draw_rect(Rect2(0, top, w, bottom - top), c[bands[i][1]])
		if i + 1 < bands.size():
			for x in range(4 + i * 3, w, 11):
				_header.draw_rect(Rect2(x, bottom - 1, mini(5, w - x), 1),
					c[bands[i + 1][1]])
	# The sun, half over the horizon: a gold rim round a hot core.
	var sun := Vector2(70, 26)
	for dy in range(-7, 0):
		var half := int(sqrt(49.0 - dy * dy))
		_header.draw_rect(Rect2(sun.x - half, sun.y + dy, half * 2, 1), c[&"gold_light"])
		if dy >= -5:
			var core := int(sqrt(25.0 - dy * dy))
			_header.draw_rect(Rect2(sun.x - core, sun.y + dy, core * 2, 1), c[&"flame_hot"])
	# The fields: grass to the bottom edge, quieter at the sides.
	_header.draw_rect(Rect2(0, 26, w, 14), c[&"grass"])
	_header.draw_rect(Rect2(0, 26, w, 2), c[&"grass_dark"])
	for row in [31, 35]:
		_header.draw_rect(Rect2(14, row, 104, 2), c[&"soil_dark"])
		_header.draw_rect(Rect2(178, row, w - 192, 2), c[&"soil_dark"])
		for x in range(16, 116, 4):
			_header.draw_rect(Rect2(x, row - 1, 2, 1), c[&"grass_light"])
		for x in range(180, w - 16, 4):
			_header.draw_rect(Rect2(x, row - 1, 2, 1), c[&"grass_light"])
	# The path from the door down to the bottom edge, widening as it comes.
	for y in range(29, 40):
		var spread := (y - 29) / 3
		_header.draw_rect(Rect2(147 - spread, y, 7 + spread * 2, 1), c[&"soil_light"])
	# The farmhouse, small and distant, centre-right: stone foundation,
	# timber walls lit on the left, dark panes and door, the chimney, and a
	# terracotta roof in tile courses.
	_header.draw_rect(Rect2(131, 27, 40, 2), c[&"stone"])
	_header.draw_rect(Rect2(132, 16, 38, 11), c[&"wood"])
	_header.draw_rect(Rect2(132, 16, 3, 11), c[&"wood_light"])
	_header.draw_rect(Rect2(166, 16, 4, 11), c[&"wood_dark"])
	for x in [137, 159]:
		_header.draw_rect(Rect2(x, 19, 5, 4), c[&"ink"])
	_header.draw_rect(Rect2(148, 20, 6, 7), c[&"wood_dark"])
	_header.draw_rect(Rect2(160, 4, 4, 8), c[&"stone_dark"])
	for y in range(6, 17):
		var reach := (y - 5) * 2
		var left := 151 - reach
		var right := 151 + reach
		var tone: StringName = &"roof" if y % 2 == 0 else &"roof_dark"
		_header.draw_rect(Rect2(left, y, right - left, 1), c[tone])
		# The lit slope on the left, as the house in the world is lit.
		_header.draw_rect(Rect2(left, y, maxi(reach / 2, 1), 1), c[&"roof_light"])


## The keys of a dictionary, in an order that is the same on every machine.
##
## **`Array.sort()` does not sort StringNames alphabetically.** It compares
## them by their interned pointer, so `[&"money", &"tech"]` comes back in
## whatever order those two names were first created in - which differs
## between two runs of the same game. The reward line printed "+4 tech +182
## money" on one run and "+182 money +4 tech" on the next, from an identical
## night, and only a byte comparison of two screenshots would ever have shown
## it: within one process the order is stable, so no test that runs once can
## catch it.
##
## `src/core/` has known this all along - every one of its key walks goes
## through `sorted_names` and the four that do not carry a comment saying the
## keys are integers. This file rolled its own and got it wrong.
func _sorted(d: Dictionary) -> Array:
	return GameData.sorted_names(d.keys())
