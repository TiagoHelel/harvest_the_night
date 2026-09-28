class_name PauseMenu
extends Control

## Escape stops the world.
##
## ## A paused game banks nothing
##
## `SimDriver` does not advance its accumulator while it is not running, so
## five minutes paused is five minutes of nothing rather than five minutes
## owed - and the first frame after resuming runs the one tick it is due and
## not three hundred seconds of catching up. That rule is the driver's and it
## was written at task 0006 with this task named in the comment; what is new
## is something that turns it, and checks that measure it.
##
## **`Main` is what turns the driver**, off `App.paused()`, because the game
## stays stopped while Options is open *over* the pause menu and this screen
## is not the one that knows that.
##
## ## Abandon asks twice and says what it is taking
##
## Losing a run is the only thing in this game that cannot be undone, and the
## second press is not a formality: the first press replaces the entry with
## what is about to be lost - the day, the nights survived, what is standing -
## and only then offers to do it. A confirmation that says "are you sure?"
## and nothing else is a confirmation people learn to press twice.

## What the menu offers, in order: the name, and the line that names it.
const ENTRIES: Array = [
	[&"resume", &"PAUSE_RESUME"],
	[&"options", &"PAUSE_OPTIONS"],
	[&"save", &"PAUSE_SAVE"],
	[&"abandon", &"PAUSE_ABANDON"],
]

## Emitted for whoever is listening; `Main` does the saving, because a screen
## does not own a run.
signal chose(which: StringName)

var _state: Dictionary = {}

var _frame: PanelContainer
var _title: Label
var _menu: VBoxContainer
var _cost: Label

## True once ABANDON has been pressed once and is showing what it will take.
var _asking := false

var _router: Node


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_router = get_node_or_null(^"/root/App")

	_frame = PanelContainer.new()
	_frame.name = "PauseFrame"
	_frame.position = Vector2(160, 70)
	# **Tall enough for the question before it is asked.** The two lines
	# ABANDON puts up are already paid for in this height, so pressing it
	# does not move the other three entries out from under the pointer.
	_frame.custom_minimum_size = Vector2(160, 118)
	_frame.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_frame)

	var column := VBoxContainer.new()
	column.name = "PauseColumn"
	column.theme_type_variation = UiKit.SPACED
	_frame.add_child(column)

	_title = Label.new()
	_title.name = "PauseTitle"
	_title.text = I18n.t(&"PAUSE_TITLE")
	_title.theme_type_variation = UiKit.HEADING
	column.add_child(_title)

	_menu = VBoxContainer.new()
	_menu.name = "PauseMenuList"
	column.add_child(_menu)

	_cost = Label.new()
	_cost.name = "PauseCost"
	_cost.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_cost.custom_minimum_size = Vector2(148, 24)
	_cost.theme_type_variation = UiKit.BAD
	_cost.visible = false
	column.add_child(_cost)

	_build()


## The run, so ABANDON can say what it is about to take.
func show_state(state: Dictionary) -> void:
	_state = state


func _build() -> void:
	for child in _menu.get_children():
		_menu.remove_child(child)
		child.queue_free()
	for entry in ENTRIES:
		var which: StringName = entry[0]
		var button := Button.new()
		button.name = "Pause_%s" % which
		button.text = _label_for(which)
		button.custom_minimum_size = Vector2(148, 16)
		button.focus_mode = Control.FOCUS_ALL
		button.pressed.connect(_pick.bind(which))
		_menu.add_child(button)
	_cost.visible = _asking
	_cost.text = _what_is_lost() if _asking else ""
	_title.text = I18n.t(&"PAUSE_TITLE")


func _label_for(which: StringName) -> String:
	if which == &"abandon" and _asking:
		return I18n.t(&"PAUSE_ABANDON_SURE")
	for entry in ENTRIES:
		if entry[0] == which:
			return I18n.t(entry[1])
	return String(which).to_upper()


## What the second press is about to take, in the player's own units.
func _what_is_lost() -> String:
	if _state.is_empty():
		return I18n.t(&"PAUSE_LOST_EMPTY")
	var summary := Run.summary(_state)
	var standing := 0
	for kind in summary["build"]:
		standing += int((summary["build"] as Dictionary)[kind])
	return I18n.f(&"PAUSE_LOST", [int(summary["days"]),
		int(summary["nights_won"]), standing])


# ----------------------------------------------------------------- the clicks

## **Nothing here saves or changes a scene.** Every entry says what it wants
## and `Main` and the router do the rest, the same rule the title menu keeps.
func _pick(which: StringName) -> void:
	# Any other entry takes the question away: a player who went looking at
	# the options is not still halfway through abandoning their run.
	if which != &"abandon" and _asking:
		_asking = false
		_build()

	match which:
		&"resume":
			chose.emit(which)
			if _router != null:
				_router.back()
		&"options":
			chose.emit(which)
			if _router != null:
				_router.goto(_router.OPTIONS)
		&"save":
			chose.emit(which)
		&"abandon":
			if not _asking:
				_asking = true
				_build()
				return
			_asking = false
			_build()
			chose.emit(which)


## Open, close and the key that does both.
##
## `pause` opens it from a run and closes it again; BACK closes it. Both go
## through the router, so the way out of the pause menu is the way out of
## every other overlay.
func _unhandled_input(event: InputEvent) -> void:
	if _router == null:
		return
	if event.is_action_pressed(&"pause"):
		if visible:
			_router.back()
		elif _router.here() == _router.RUN:
			_router.goto(_router.PAUSE)
		get_viewport().set_input_as_handled()
		return
	if visible and event.is_action_pressed(&"cancel"):
		_router.back()
		get_viewport().set_input_as_handled()


## Shown or hidden by `Main`, off the router. Closing forgets a half-asked
## question, so opening it again does not offer to abandon the run outright.
func set_open(open: bool) -> void:
	if not open and _asking:
		_asking = false
		_build()
	visible = open


func is_open() -> bool:
	return visible


## Say it all again in whatever language is up now.
func relabel() -> void:
	if _menu == null:
		return
	_build()


# ------------------------------------------------------------ for the checks

func asking() -> bool:
	return _asking


func cost_shown() -> String:
	return _cost.text if _cost.visible else ""


func label_of(which: StringName) -> String:
	var button := _menu.get_node_or_null(
		NodePath("Pause_%s" % which)) as Button
	return button.text if button != null else ""
