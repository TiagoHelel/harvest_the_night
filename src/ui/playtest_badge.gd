class_name PlaytestBadge
extends Control

## It is obvious this is a playtest build, and one key leaves a marker.
##
## Invisible and inert in every other build: `Playtest.is_on()` is false, and
## this node hides itself in `_ready` and stops processing. A release carries
## it and never draws it.
##
## ## Why a badge and not a line in the options
##
## A tester who forgets they are on a playtest build reports the watermark as
## a bug and the missing content as a bug, and neither is worth their evening.
## It sits in a corner, it says which key leaves a note, and it says how many
## they have left - which is the one number they need when they sit down
## afterwards to say what note 3 was about.
##
## ## The state comes in the same way every other screen's does
##
## `Main._hand_out()` hands it the run, which is how a new dictionary gets
## noticed: `SimDriver.start()` replaces it rather than emptying it, so a
## screen holding the old one draws a game that has stopped. Here it means a
## new run, which is a new session log.

## Where it sits on a 480x270 screen. Top left, which is where a reader
## starts - and which is also where the day HUD keeps the clock and the money
## and the night HUD keeps the wave counter. **That is why it does not stay.**
const AT := Vector2(4, 4)

## How long it is up at the start of a run.
##
## **It goes away, and that took looking at the picture.** The first version
## sat in the corner for the whole run: the noon shot came back with the day,
## the time and the money behind it, and the night shot with NIGHT 1 and WAVE
## 2/3 behind it. Covering the clock for an hour to tell somebody a key they
## needed once is a bad trade.
##
## Twelve seconds at the top of every run, which is when a tester has nothing
## to read on the HUD yet and everything to learn, and then the screen is the
## game's again. The title screen carries the permanent watermark.
const SHOWN_FOR := 12.0

## How long the note confirmation stays up.
const SAID_FOR := 2.0

var _state: Dictionary = {}

var _frame: PanelContainer
var _label: Label
var _said := 0.0
var _greeting := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = false
	if not Playtest.is_on():
		set_process(false)
		set_process_unhandled_input(false)
		return

	_frame = PanelContainer.new()
	_frame.name = "PlaytestFrame"
	_frame.position = AT
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_frame)

	_label = Label.new()
	_label.name = "PlaytestLabel"
	_label.theme_type_variation = UiKit.WARN
	_frame.add_child(_label)
	_wear()


## The run, handed over the way every other screen is handed it.
func show_state(state: Dictionary) -> void:
	if not Playtest.is_on():
		return
	_state = state
	Playtest.begin(state)
	_greeting = SHOWN_FOR
	visible = true
	_wear()


func _process(delta: float) -> void:
	if not Playtest.is_on():
		return
	Playtest.watch(_state)
	if _greeting > 0.0:
		_greeting = maxf(_greeting - delta, 0.0)
	if _said > 0.0:
		_said = maxf(_said - delta, 0.0)
		if _said == 0.0:
			_wear()
	visible = _greeting > 0.0 or _said > 0.0


func _unhandled_input(event: InputEvent) -> void:
	if not Playtest.is_on():
		return
	if not (event is InputEventKey) or not event.is_pressed() \
			or event.is_echo():
		return
	if (event as InputEventKey).keycode != Playtest.NOTE_KEY:
		return
	leave_a_note()
	get_viewport().set_input_as_handled()


## Mark this moment. Public so a check can press the key without one.
func leave_a_note() -> int:
	var which := Playtest.note()
	if which > 0:
		_said = SAID_FOR
		visible = true
		_wear()
	return which


## What it says right now, for a check that wants to read it.
func says() -> String:
	return _label.text if _label != null else ""


func _wear() -> void:
	if _label == null:
		return
	if _said > 0.0:
		_label.text = I18n.f(&"PLAYTEST_NOTED", [Playtest.notes()])
		return
	_label.text = I18n.f(&"PLAYTEST_BADGE",
		[OS.get_keycode_string(Playtest.NOTE_KEY), Playtest.notes()])
