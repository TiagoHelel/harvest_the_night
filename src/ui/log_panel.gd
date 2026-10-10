class_name LogPanel
extends Control

## A short running account of what just happened.
##
## At four times speed a frame is eight ticks and seven of them go by
## unwatched. `design.md` lets a player skip a night; this is what stops
## skipping it meaning missing it.
##
## ## The rules record, this reads
##
## `Events` keeps `{tick, kind, ...}` and knows no words at all. Everything a
## player reads is written here, which is what makes task 0097 a translation
## file rather than a rewrite of the simulation - and what lets the same
## record feed a history panel, a replay and anything else later without the
## rules learning about any of them.
##
## ## It never covers the farm
##
## Collapsed it is four lines of text with **no panel behind them**, on the
## left where the day HUD keeps its own, and each line fades out on its own
## clock. A game where nothing is happening has nothing on the screen.
##
## Expanded - one key - it is a panel with the whole night in it, and that one
## does cover the farm, because a player who asked to read the night is not
## looking at the farm.

## How many lines the collapsed log shows at once.
const LINES := 4

## How long a line stays up, by how much it matters. **The alarming ones are
## held longer**: a crop coming ready can be missed, a wall coming down is the
## thing you needed to know.
const HOLD := {
	&"note": 4.0,
	&"good": 5.0,
	&"warn": 7.0,
	&"bad": 10.0,
}

## How long a line takes to fade once its hold is up.
const FADE := 1.2

## What each kind is worth. A kind missing from here is a kind nobody decided
## about, and `headless_check` fails on it rather than letting it show up grey.
const SEVERITY := {
	&"night_began": &"note",
	&"wave_began": &"warn",
	&"structure_lost": &"bad",
	&"house_hit": &"bad",
	&"crop_ready": &"good",
	&"craft_done": &"good",
	&"boss_arrived": &"bad",
	&"night_won": &"good",
	&"night_lost": &"bad",
	&"passed_out": &"warn",
	&"dawn": &"good",
}

## Severity -> the theme role it is written in.
const TINTS := {
	&"note": UiKit.DIM,
	&"good": UiKit.GOOD,
	&"warn": UiKit.WARM,
	&"bad": UiKit.BAD,
}

## Where the collapsed lines sit: left, above the ammo and power read-outs.
const AT := Vector2(4, 178)
const LINE_HEIGHT := 10.0

var _state: Dictionary = {}
var _labels: Array = []
var _left: Array = []

## The newest tick already read. Everything after it is news.
var _read := -1

var _expanded := false
var _panel: PanelContainer
var _scroll: ScrollContainer
var _history: VBoxContainer


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)

	for i in LINES:
		var line := Label.new()
		line.name = "LogLine%d" % i
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		line.position = AT + Vector2(0.0, i * LINE_HEIGHT)
		line.modulate = Color(1.0, 1.0, 1.0, 0.0)
		add_child(line)
		_labels.append(line)
		_left.append(0.0)

	_panel = PanelContainer.new()
	_panel.name = "LogHistory"
	_panel.position = Vector2(60, 24)
	_panel.custom_minimum_size = Vector2(360, 200)
	_panel.visible = false
	add_child(_panel)

	var column := VBoxContainer.new()
	column.name = "LogColumn"
	_panel.add_child(column)
	var title := Label.new()
	title.name = "LogTitle"
	title.text = I18n.t(&"LOG_TITLE")
	title.theme_type_variation = UiKit.WARM
	column.add_child(title)

	_scroll = ScrollContainer.new()
	_scroll.name = "LogScroll"
	_scroll.custom_minimum_size = Vector2(348, 170)
	column.add_child(_scroll)
	_history = VBoxContainer.new()
	_history.name = "LogHistoryLines"
	_scroll.add_child(_history)


func show_state(state: Dictionary) -> void:
	_state = state
	# **Everything already in the record counts as read.** Setting this to
	# -1 replayed the whole log the next frame: on a fresh state that is
	# nothing, and on a state that already had a night in it that is
	# sixty-four lines arriving at once. A log opens silent.
	_read = -1
	for one in (state.get("events", []) as Array):
		_read = maxi(_read, int((one as Dictionary)["tick"]))
	_expanded = false
	_panel.visible = false
	for i in LINES:
		_left[i] = 0.0
		(_labels[i] as Label).text = ""


func _process(delta: float) -> void:
	if _state.is_empty():
		return
	_read_the_news()
	_fade(delta)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"log"):
		toggle()
		get_viewport().set_input_as_handled()


func toggle() -> void:
	_expanded = not _expanded
	_panel.visible = _expanded
	if _expanded:
		_fill_history()


func is_expanded() -> bool:
	return _expanded


# ------------------------------------------------------------------- the news

func _read_the_news() -> void:
	var fresh: Array = []
	for one in (_state["events"] as Array):
		var event: Dictionary = one
		if int(event["tick"]) > _read:
			fresh.append(event)
	if fresh.is_empty():
		return
	_read = int((fresh[fresh.size() - 1] as Dictionary)["tick"])
	for event in fresh:
		_push(event as Dictionary)
	if _expanded:
		_fill_history()


## Push a line on the bottom and shuffle the rest up.
func _push(event: Dictionary) -> void:
	for i in range(LINES - 1):
		(_labels[i] as Label).text = (_labels[i + 1] as Label).text
		(_labels[i] as Label).theme_type_variation = \
			(_labels[i + 1] as Label).theme_type_variation
		_left[i] = _left[i + 1]
	var last := _labels[LINES - 1] as Label
	var how_bad := severity_of(StringName(event["kind"]))
	last.text = line_for(event)
	last.theme_type_variation = TINTS.get(how_bad, UiKit.DIM)
	_left[LINES - 1] = float(HOLD.get(how_bad, 4.0)) + FADE


func _fade(delta: float) -> void:
	# **Out of the way of the morning report** (task 0138), which says what
	# the night's last lines said: the panel sits in the middle of the screen
	# and a long line ran under its left edge in Portuguese. They keep their
	# time meanwhile, and the history (`log`) is still there on a key.
	var reporting := int(_state["phase"]) == Phases.RESULT
	for i in LINES:
		(_labels[i] as Label).visible = not reporting
		var left := float(_left[i])
		if left <= 0.0:
			(_labels[i] as Label).modulate.a = 0.0
			continue
		left = maxf(left - delta, 0.0)
		_left[i] = left
		# **Solid while it is held, then out.** A line that started fading the
		# moment it appeared would be a line nobody finished reading.
		(_labels[i] as Label).modulate.a = clampf(left / FADE, 0.0, 1.0)


func _fill_history() -> void:
	for child in _history.get_children():
		_history.remove_child(child)
		child.queue_free()
	var since := int(_state.get("night_tick", 0))
	var from := maxi(int(_state["tick"]) - since, 0)
	for one in Events.since(_state, from):
		var event: Dictionary = one
		var row := Label.new()
		row.text = "%s  %s" % [_clock(int(event["tick"]) - from),
			line_for(event)]
		row.theme_type_variation = TINTS.get(
			severity_of(StringName(event["kind"])), UiKit.DIM)
		_history.add_child(row)


# ------------------------------------------------------------------ the words

## How much a kind matters. Static, so the check can ask it of every kind the
## rules can record without building a game.
static func severity_of(kind: StringName) -> StringName:
	return SEVERITY.get(kind, &"")


## What a player reads. **The only place in the game that turns an event into
## a sentence**, which is what makes task 0097 a translation file.
static func line_for(event: Dictionary) -> String:
	var kind := StringName(event.get("kind", &""))
	match kind:
		&"night_began":
			return I18n.f(&"LOG_NIGHT_BEGAN", [int(event.get("night", 0))])
		&"wave_began":
			return I18n.f(&"LOG_WAVE_BEGAN", [int(event.get("wave", 0)),
				int(event.get("waves", 0)), _how_many(event)])
		&"boss_arrived":
			return I18n.t(&"LOG_BOSS")
		&"structure_lost":
			# A coop or a barn stands wrecked rather than gone (task 0186).
			if bool(event.get("wrecked", false)):
				return I18n.f(&"LOG_STRUCTURE_WRECKED",
					[Names.of(StringName(event.get("id", &"")))])
			return I18n.f(&"LOG_STRUCTURE_LOST",
				[Names.of(StringName(event.get("id", &"")))])
		&"house_hit":
			return I18n.f(&"LOG_HOUSE_HIT", [int(event.get("left", 0))])
		&"crop_ready":
			return I18n.f(&"LOG_CROP_READY",
				[Names.of(StringName(event.get("crop", &"")))])
		&"craft_done":
			return I18n.f(&"LOG_CRAFT_DONE",
				[Names.of(StringName(event.get("recipe", &"")))])
		&"night_won":
			return I18n.f(&"LOG_NIGHT_WON", [int(event.get("night", 0))])
		&"night_lost":
			return I18n.f(&"LOG_NIGHT_LOST", [int(event.get("night", 0))])
		&"passed_out":
			return I18n.t(&"LOG_PASSED_OUT")
		&"dawn":
			return I18n.f(&"LOG_DAWN", [int(event.get("walked", 0))])
	return ""


## "1 walker" or "6 walkers".
##
## **Two rows in the table, not an `s` on the end.** English makes a plural by
## adding one letter and Portuguese does not always make one at all - "6
## brutamontes" is the same word as one of them - so the count picks a line
## rather than editing it.
static func _how_many(event: Dictionary) -> String:
	var many := int(event.get("count", 0))
	return "%d %s" % [many, I18n.plural(
		Names.key_of(StringName(event.get("enemy", &""))), many)]


## Ticks into the night as minutes and seconds.
static func _clock(ticks: int) -> String:
	var seconds := ticks / GameData.TICK_HZ
	return "%d:%02d" % [seconds / 60, seconds % 60]


# ------------------------------------------------------------- for the checks

func lines_showing() -> int:
	var n := 0
	for i in LINES:
		if float(_left[i]) > 0.0:
			n += 1
	return n


## The longest any line still has to run. Zero when the log is silent.
##
## Exposed because the fading is on a real clock and this suite's frames go
## by far faster than real seconds - waiting out the longest hold would be
## eleven seconds of test for a countdown that can simply be read.
func time_left() -> float:
	var most := 0.0
	for i in LINES:
		most = maxf(most, float(_left[i]))
	return most


func newest_line() -> String:
	return (_labels[LINES - 1] as Label).text


func history_lines() -> int:
	return _history.get_child_count()
