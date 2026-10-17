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


signal new_farm_requested(seed_value: int)
signal run_recorded(profile: Dictionary)

var _state: Dictionary = {}
var _header: Control
var _day: Label
var _title: Label
var _lines: VBoxContainer
var _continue: Button
var _play_on: Button
var _credits: CreditsRoll
var _credits_seen := false
var _wait_for_release := false
var _frame: PanelContainer

var _built_for := ""

## **The sunrise is A057's** (task 0289), over the report at its 206x40 -
## 0138 drew the band in code until the pack landed.
const HEADER := "res://sprites/ui/report_header.png"


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
	_frame = frame
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
	_play_on.text = I18n.f(&"RES_PLAY_ON", [2])
	_play_on.clip_text = true
	_play_on.custom_minimum_size = Vector2(206, 20)
	_play_on.focus_mode = Control.FOCUS_ALL
	_play_on.visible = false
	_play_on.pressed.connect(_carry_on)
	column.add_child(_play_on)

	_credits = CreditsRoll.new()
	_credits.name = "CreditsRoll"
	_credits.finished.connect(_credits_finished)
	add_child(_credits)


## A057's picture over the report (task 0289).
func _make_header() -> Control:
	var made := TextureRect.new()
	made.texture = load(HEADER)
	made.stretch_mode = TextureRect.STRETCH_KEEP
	made.name = "ReportHeader"
	made.custom_minimum_size = Vector2(PlaceholderArt.frame(HEADER).get("canvas", Vector2i(206, 40)))
	made.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	made.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return made


func show_state(state: Dictionary) -> void:
	if not is_same(_state, state):
		_credits_seen = false
		_wait_for_release = false
		_built_for = ""
		_credits.visible = false
		_frame.visible = true
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

	# Shrink after queued old rows have left the container.
	_frame.size = _frame.custom_minimum_size
	if _credits.visible:
		return
	if _wait_for_release:
		_wait_for_release = Input.is_action_pressed(&"interact") \
			or Input.is_action_pressed(&"night") or Input.is_action_pressed(&"ui_accept") \
			or Input.is_action_pressed(&"cancel") or Input.is_action_pressed(&"ui_cancel")
		return
	# The keyboard reaches it without having to find it.
	if Input.is_action_just_pressed(&"interact") \
			or Input.is_action_just_pressed(&"night"):
		if Run.is_over(_state) and _play_on.has_focus():
			_carry_on()
		else:
			_confirm()


func _confirm() -> void:
	if _state.is_empty() or _credits.visible or _wait_for_release:
		return
	# **At the end of a run, this button starts another one.** The run is
	# written to the profile first: a win that was not recorded is a win the
	# player did not have.
	if Run.is_over(_state):
		_record_and_restart()
		return
	(_state["intent"] as Dictionary)["confirm_result"] = true


## **The year a morning ends** (task 0279): the year of `night` when it was a
## later year's last boss night and the calendar has moved past it - its
## Winter Lord fell - else 0. Year 1's ends on 0160's screen instead.
static func year_survived(state: Dictionary, night: int) -> int:
	if Calendar.year_of(night) <= 1 or not Calendar.is_boss_night(night) 			or Calendar.season_of(night) != GameData.SEASONS.size() - 1 			or Calendar.date(state) <= night:
		return 0
	return Calendar.year_of(night)


## Carry on into Year 2 of the calendar (task 0279), and the years after it.
func _carry_on() -> void:
	if _state.is_empty() or not Run.is_over(_state) or _credits.visible or _wait_for_release:
		return
	_record(_state)
	Run.go_endless(_state)
	(_state["intent"] as Dictionary)["confirm_result"] = true


## Write the run to the profile and deal a new farm.
func _record_and_restart() -> void:
	_record(_state)
	# Main owns starting a run: every panel and the in-memory profile must
	# move together, or the next banking frame overwrites the recorded win.
	new_farm_requested.emit(int(Time.get_unix_time_from_system()) & 0x7FFFFFFF)
	visible = false


## The profile is the thing that outlives a run.
func _record(state: Dictionary) -> void:
	var profile := Save.read_profile()
	profile = Run.record(state, profile)
	Save.write_profile(profile)
	run_recorded.emit(profile)


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

	# The winter boss opens the credits, then the year summary and choices.
	if _state != null and not _state.is_empty() and Run.is_over(_state):
		_header.visible = false
		_day.visible = false
		_build_the_ending()
		_continue.text = I18n.t(&"RES_NEW_FARM")
		_play_on.text = I18n.f(&"RES_PLAY_ON", [Calendar.year_of(Calendar.date(_state))])
		_play_on.visible = true
		_frame.position = Vector2(80, 21)
		_frame.custom_minimum_size = Vector2(320, 228)
		_frame.size = _frame.custom_minimum_size
		if not _credits_seen:
			_credits_seen = true
			_frame.visible = false
			_credits.start()
		return
	_play_on.visible = false
	_frame.position = Vector2(128, 30)
	_frame.custom_minimum_size = Vector2(224, 190)
	_frame.size = _frame.custom_minimum_size

	_title.text = I18n.f(&"RES_NIGHT", [int(payout["night"]),
		I18n.t(&"RES_SURVIVED" if survived else &"RES_WAS_LOST")])
	_title.theme_type_variation = UiKit.GOOD if survived else UiKit.BAD
	# **A boss that lived to dawn** (task 0153) neither won nor lost the
	# night: the night is over, and it is coming back.
	if escaped:
		_title.text = I18n.t(&"RES_NIGHT_OVER")
		_title.theme_type_variation = UiKit.WARN
	# **A later year's Winter Lord down** (task 0279): the year survived,
	# said on its morning - 0160's ending is Year 1's alone, and a farm that
	# carried on ends each later year here.
	var fought := int(payout["night"])
	if survived and not escaped and year_survived(_state, fought) > 0:
		_row(I18n.f(&"RES_YEAR_SURVIVED", [year_survived(_state, fought)]), "", UiKit.GOOD)

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
			var given := int((payout["gained"] as Dictionary)[id])
			gift.append(I18n.f(&"RES_GAINED", [given, Names.of_count(id, given)]))
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
			var said := I18n.f(&"RES_GAINED", [n, Names.of_count(id, n)])
			if id == GameData.MONEY or id == GameData.TECH:
				purse.append(said)
			else:
				goods.append(said)
		if not goods.is_empty():
			_row(I18n.f(&"RES_INDENT", ["  ".join(goods)]), "", UiKit.GOOD)
		if not purse.is_empty():
			_row(I18n.f(&"RES_INDENT", ["  ".join(purse)]), "", UiKit.GOOD)
		# **What the essence was for** (task 0219), line by line as
		# `Tech.would_pay` gave them inside `Rewards.settle`: the night, each
		# bonus earned, a Full Moon's share and a Blood Moon's (task 0257).
		var parts := essence_parts(payout.get("essence_from", {}))
		if not parts.is_empty():
			_listed(I18n.t(&"RES_ESSENCE_FOR"), parts, UiKit.DIM)

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
					[int(lost[id]), Names.of_count(id, int(lost[id]))]))
			_row(I18n.f(&"RES_INDENT", ["  ".join(taken)]), "", UiKit.BAD)
		_row(I18n.t(&"RES_UNTOUCHED_ALL"), "", UiKit.DIM)

	_gap()
	# **A night that began with him face down at 02:00** (task 0128) had the
	# short build step, and the morning says why.
	if House.passed_out(_state):
		var at := GameData.DAY_END_MINUTE
		_row(I18n.f(&"RES_PASSED_OUT", [(at / 60) % 24, at % 60]), "",
			UiKit.WARN)
	# **The shipping bin** (task 0189): what it pays when he gets up - the
	# same `Shipping.due` that `Phases.begin_day` puts in the purse.
	var shipped := Shipping.due(_state)
	if shipped > 0:
		_row(I18n.f(&"RES_BIN", [shipped]), "", UiKit.GOOD)
	# **What the night left lying on the farm** (task 0221): the bones and
	# the moon stones the morning round will pick up - counted after the
	# night's end took what had lain too long, so it is what the morning has.
	var left := leftovers_parts(_state)
	if left.is_empty():
		_row(I18n.t(&"RES_LEFTOVERS"), "", UiKit.DIM)
	else:
		_listed(I18n.t(&"RES_LEFTOVERS_LYING"), left, UiKit.GOOD)


## **The leftovers line's parts, in words** (task 0221): "12 bones", then
## "4 moon stones" - what `Loot` says is lying on the farm, nothing for
## a thing there is none of.
static func leftovers_parts(state: Dictionary) -> Array:
	var lying := Loot.lying(state)
	var out: Array = []
	var bones := int(lying.get(GameData.BONES, 0))
	if bones > 0:
		out.append(I18n.plural(&"RES_LEFT_BONES", bones, [bones]))
	var stones := int(lying.get(GameData.MOON_STONE, 0))
	if stones > 0:
		out.append(I18n.plural(&"RES_LEFT_STONES", stones, [stones]))
	return out


## **The essence's lines, in words** (task 0219): the night first, then the
## bonuses in `GameData.TECH_BONUSES` order, then the Full Moon's share and
## the Blood Moon's (task 0257).
static func essence_parts(lines: Dictionary) -> Array:
	var order: Array = ["for surviving"]
	for row in GameData.TECH_BONUSES:
		order.append(String((row as Dictionary)["id"]))
	order.append("full moon")
	order.append("blood moon")
	var out: Array = []
	for line in order:
		if not lines.has(line) and not lines.has(StringName(line)):
			continue
		var n := int(lines.get(line, lines.get(StringName(line), 0)))
		if n > 0:
			out.append(I18n.f(&"RES_ESSENCE_PART", [I18n.t(ESSENCE_LINES.get(line, &"RES_ESSENCE_FOR_SURVIVING")), n]))
	return out


## Which words say each of the essence's lines.
const ESSENCE_LINES := {
	"for surviving": &"RES_ESSENCE_FOR_SURVIVING",
	"house untouched": &"RES_ESSENCE_HOUSE_UNTOUCHED",
	"nothing lost": &"RES_ESSENCE_NOTHING_LOST",
	"not one got through": &"RES_ESSENCE_NOT_ONE_GOT_THROUGH",
	"full moon": &"RES_ESSENCE_FULL_MOON",
	"blood moon": &"RES_ESSENCE_BLOOD_MOON",
}


## The run summary: what the whole thing was.
##
## Every line is a lookup off `Run.summary()`, which is itself a lookup off
## the state. There is no second ledger here to disagree with the first.
func _build_the_ending() -> void:
	var run := Run.summary(_state)
	_title.text = I18n.t(&"END_TITLE")
	_title.theme_type_variation = UiKit.GOOD
	# **The days behind him, not the day ahead.** The calendar moved on at
	# dawn, under this screen, so the day count is already tomorrow's: a whole
	# year read "57 days lived, 56 nights won".
	_row(I18n.f(&"RES_RUN_LINE", [maxi(int(run["days"]) - 1, 1), int(run["nights_won"])]), "", UiKit.GOOD)
	_row(I18n.t(&"END_BOSSES"), str(int(run["bosses"])), UiKit.DIM)
	_row(I18n.t(&"RES_ZOMBIES"), str(int(run["killed"])), UiKit.DIM)
	_row(I18n.t(&"RES_STRUCTURES_LOST"), str(int(run["structures_lost"])), UiKit.DIM)
	_gap()
	_row(I18n.t(&"RES_BUILD_WON"), "", UiKit.GOOD)
	var built: Array = []
	for id in _sorted(run["build"] as Dictionary):
		built.append(I18n.f(&"RES_COUNTED", [Names.of(id), int((run["build"] as Dictionary)[id])]))
	# The final farm may contain every defence: keep the choices on screen.
	var scroll := ScrollContainer.new()
	scroll.name = "EndingBuildScroll"
	scroll.custom_minimum_size = Vector2(300, 48)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_lines.add_child(scroll)
	var build := Label.new()
	build.text = ", ".join(built) if not built.is_empty() else I18n.t(&"RES_NOTHING_STANDING")
	build.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	build.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	build.theme_type_variation = UiKit.GOOD
	scroll.add_child(build)


func _credits_finished() -> void:
	_frame.visible = true
	_wait_for_release = true
	_play_on.grab_focus()


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


## **Words that go together, broken only between them** (task 0219): the
## parts after `prefix`, in as many lines as the frame's width needs, the
## lines after the first indented under it. Wrapping by word broke 'house
## untouched +1' in two and put the rest at the frame's edge.
func _listed(prefix: String, parts: Array, role: StringName) -> void:
	var font := get_theme_font(&"font", &"Label")
	var font_size := get_theme_font_size(&"font_size", &"Label")
	var line := prefix
	var started := false
	for i in parts.size():
		var piece := String(parts[i]) + ("," if i < parts.size() - 1 else "")
		var longer := line + " " + piece
		if started and font.get_string_size(longer, HORIZONTAL_ALIGNMENT_LEFT, -1,
				font_size).x > LINE_WIDTH:
			_plain(line, role)
			line = "    " + piece
		else:
			line = longer
		started = true
	_plain(line, role)


## The width a line of the report has: the frame's, less its margins.
const LINE_WIDTH := 206.0


## One line, as it is: no wrapping, the frame's width.
func _plain(text: String, role: StringName = &"") -> void:
	var line := Label.new()
	line.text = text
	line.custom_minimum_size = Vector2(LINE_WIDTH, 0)
	line.theme_type_variation = role
	_lines.add_child(line)


func _gap() -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 5)
	_lines.add_child(spacer)


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
