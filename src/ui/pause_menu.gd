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
## ## Laid out like WELCOME BACK, HERO's (2026-10-07)
##
## The owner asked for the pause menu that game has, so it has that game's
## shape: the world dimmed behind one card, the caret on RESUME every time it
## opens, one selection for the keys, the pointer and a pad (`MenuFocus`), a
## line at the bottom saying which key gets you out, and the same six things
## to do - resume, options, start the run again, save and leave, abandon,
## close the game.
##
## ## Anything that cannot be undone asks first, and says what it takes
##
## RESTART, ABANDON and QUIT each swap the list for a question - in red - and
## what is about to be lost in the player's own units: the day, the nights
## survived, what is standing. The caret starts on KEEP PLAYING, so the key
## that was pressed by reflex is the safe one, and escape takes the question
## away. A confirmation that says "are you sure?" and nothing else is a
## confirmation people learn to press twice.

## What the menu offers, in order: the name, and the line that names it.
const ENTRIES: Array = [
	[&"resume", &"PAUSE_RESUME"],
	[&"options", &"PAUSE_OPTIONS"],
	[&"restart", &"PAUSE_RESTART"],
	[&"save", &"PAUSE_SAVE"],
	[&"abandon", &"PAUSE_ABANDON"],
	[&"quit", &"PAUSE_QUIT"],
]

## The entries that ask before they act: what they ask, and the words on the
## button that goes ahead.
const QUESTIONS := {
	&"restart": [&"PAUSE_ASK_RESTART", &"PAUSE_DO_RESTART"],
	&"abandon": [&"PAUSE_ASK_ABANDON", &"PAUSE_ABANDON_SURE"],
	&"quit": [&"PAUSE_ASK_QUIT", &"PAUSE_DO_QUIT"],
}

## How dark the world goes behind the card. Dim enough that the card is the
## only thing asking to be read, light enough that the farm is still there.
const SCRIM_ALPHA := 0.55

## The card's inner width, and an entry's size. The question below the list
## is held to the list's height, so asking does not move the card.
const CARD_WIDTH := 164
const ENTRY := Vector2(148, 16)

## Emitted for whoever is listening; `Main` does the saving, restarting and
## quitting, because a screen does not own a run.
signal chose(which: StringName)

var _state: Dictionary = {}

var _scrim: ColorRect
var _frame: PanelContainer
var _title: Label
var _menu: VBoxContainer
var _question: VBoxContainer
var _ask: Label
var _cost: Label
var _answers: VBoxContainer
var _hint: Label

## Which entry is asking its question, or nothing.
var _asking: StringName = &""

var _router: Node


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_router = get_node_or_null(^"/root/App")

	# **The world behind it, dimmed** - and held: a click on a HUD button
	# behind a pause menu would be a game played while it is paused.
	_scrim = ColorRect.new()
	_scrim.name = "PauseScrim"
	var ink: Color = PaletteData.COLOURS[&"ink"]
	_scrim.color = Color(ink.r, ink.g, ink.b, SCRIM_ALPHA)
	_scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	_scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_scrim)

	var middle := CenterContainer.new()
	middle.name = "PauseMiddle"
	middle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	middle.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(middle)

	_frame = PanelContainer.new()
	_frame.name = "PauseFrame"
	_frame.custom_minimum_size = Vector2(CARD_WIDTH, 0)
	_frame.mouse_filter = Control.MOUSE_FILTER_STOP
	middle.add_child(_frame)

	var column := VBoxContainer.new()
	column.name = "PauseColumn"
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	_frame.add_child(column)

	_title = Label.new()
	_title.name = "PauseTitle"
	_title.theme_type_variation = UiKit.HEADING
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_title)
	column.add_child(_gap(4))

	_menu = VBoxContainer.new()
	_menu.name = "PauseMenuList"
	_menu.theme_type_variation = UiKit.STACKED
	_menu.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(_menu)

	# **The question takes the list's place and the list's height**, so the
	# card does not jump when it is asked and the pointer is not left over a
	# different entry from the one it was on.
	_question = VBoxContainer.new()
	_question.name = "PauseQuestion"
	_question.visible = false
	_question.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(_question)

	_ask = Label.new()
	_ask.name = "PauseAsk"
	_ask.theme_type_variation = UiKit.BAD
	_ask.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ask.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ask.custom_minimum_size = Vector2(ENTRY.x, 0)
	_question.add_child(_ask)
	_question.add_child(_gap(3))

	_cost = Label.new()
	_cost.name = "PauseCost"
	_cost.theme_type_variation = UiKit.DIM
	_cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cost.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_cost.custom_minimum_size = Vector2(ENTRY.x, 0)
	_question.add_child(_cost)

	var room := Control.new()
	room.name = "PauseQuestionRoom"
	room.size_flags_vertical = Control.SIZE_EXPAND_FILL
	room.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_question.add_child(room)

	_answers = VBoxContainer.new()
	_answers.name = "PauseAnswers"
	_answers.theme_type_variation = UiKit.STACKED
	_question.add_child(_answers)
	_answers.add_child(_entry(&"keep", I18n.t(&"PAUSE_KEEP")))
	var go := _entry(&"do", "")
	go.theme_type_variation = UiKit.DANGER
	_answers.add_child(go)
	MenuFocus.wire(_answers.get_children())

	column.add_child(_gap(5))
	_hint = Label.new()
	_hint.name = "PauseHint"
	_hint.theme_type_variation = UiKit.FAINT
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_hint)

	_build()


## The run, so a question can say what it is about to take.
func show_state(state: Dictionary) -> void:
	_state = state


func _build() -> void:
	for child in _menu.get_children():
		_menu.remove_child(child)
		child.queue_free()
	for entry in ENTRIES:
		_menu.add_child(_entry(entry[0], I18n.t(entry[1])))
	MenuFocus.wire(_menu.get_children())
	# Held to the list's height, so asking does not resize the card.
	var tall := ENTRY.y * ENTRIES.size() + UiKit.MENU_GAP * (ENTRIES.size() - 1)
	_question.custom_minimum_size = Vector2(ENTRY.x, tall)
	_title.text = I18n.t(&"PAUSE_TITLE")
	(_answers.get_node(^"Pause_keep") as Button).text = I18n.t(&"PAUSE_KEEP")
	_wear_question()


func _entry(which: StringName, words: String) -> Button:
	var button := Button.new()
	button.name = "Pause_%s" % which
	button.text = words
	button.custom_minimum_size = ENTRY
	button.focus_mode = Control.FOCUS_ALL
	button.pressed.connect(_pick.bind(which))
	return button


func _gap(height: int) -> Control:
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, height)
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return gap


## What going ahead is about to take, in the player's own units.
func _what_is_lost() -> String:
	if _asking == &"quit":
		return I18n.t(&"PAUSE_SAVED_FIRST")
	if _state.is_empty():
		return I18n.t(&"PAUSE_LOST_EMPTY")
	var summary := Run.summary(_state)
	var standing := 0
	for kind in summary["build"]:
		standing += int((summary["build"] as Dictionary)[kind])
	return I18n.f(&"PAUSE_LOST", [int(summary["days"]),
		int(summary["nights_won"]), standing])


## Show the list or the question, whichever is up, and the line under them.
func _wear_question() -> void:
	var asking := _asking != &""
	_menu.visible = not asking
	_question.visible = asking
	var actions := get_node_or_null(^"/root/Actions")
	var pause_key: String = actions.text_of(&"pause") if actions != null else "P"
	var back_key: String = actions.text_of(&"cancel") if actions != null else "ESC"
	if not asking:
		_hint.text = I18n.f(&"PAUSE_HINT", [pause_key, back_key])
		return
	var words: Array = QUESTIONS[_asking]
	_ask.text = I18n.t(words[0])
	_cost.text = _what_is_lost()
	(_answers.get_node(^"Pause_do") as Button).text = I18n.t(words[1])
	_hint.text = I18n.f(&"PAUSE_ASK_HINT", [back_key])


# ----------------------------------------------------------------- the clicks

## **Nothing here saves or changes a scene.** Every entry says what it wants
## and `Main` and the router do the rest, the same rule the title menu keeps.
func _pick(which: StringName) -> void:
	match which:
		&"resume":
			chose.emit(which)
			_resume()
		&"options":
			chose.emit(which)
			if _router != null:
				_router.goto(_router.OPTIONS)
		&"save":
			chose.emit(which)
		&"restart", &"abandon", &"quit":
			_ask_about(which)
		&"keep":
			_take_back_question()
		&"do":
			var going := _asking
			_asking = &""
			_wear_question()
			chose.emit(going)


## Swap the list for the question, with the caret on KEEP PLAYING.
func _ask_about(which: StringName) -> void:
	_asking = which
	_wear_question()
	MenuFocus.select_first(_answers.get_children())


## And back to the list, on the entry that asked.
func _take_back_question() -> void:
	var was := _asking
	_asking = &""
	_wear_question()
	var entry := _menu.get_node_or_null(NodePath("Pause_%s" % was)) as Button
	if entry != null and visible:
		entry.grab_focus()


func _resume() -> void:
	if _router != null:
		_router.back()


## Open, close and the keys that do both.
##
## `pause` - P, or a pad's Start since task 0121 bound it - opens it from a
## run and closes it again; BACK closes it, or takes a question away first.
## Both go through the router, so the way out of the pause menu is the way out
## of every other overlay. Escape *opening* it is `Main`'s, because only Main
## knows whether escape had something else to stop first.
func _unhandled_input(event: InputEvent) -> void:
	if _router == null:
		return
	if event.is_action_pressed(&"pause"):
		if visible:
			if _asking != &"":
				_take_back_question()
			else:
				_resume()
			MenuFocus.backed_out(self)
		elif _router.here() == _router.RUN:
			_router.goto(_router.PAUSE)
		get_viewport().set_input_as_handled()
		return
	if not visible:
		return
	if event.is_action_pressed(&"cancel") or event.is_action_pressed(&"ui_cancel"):
		if _asking != &"":
			_take_back_question()
		else:
			_resume()
		MenuFocus.backed_out(self)
		get_viewport().set_input_as_handled()


## Shown or hidden by `Main`, off the router. Opening puts the caret on RESUME
## every time; closing forgets a half-asked question, so opening it again
## does not offer to abandon the run outright.
func set_open(open: bool) -> void:
	if _asking != &"":
		_asking = &""
		_wear_question()
	visible = open
	if open:
		_wear_question()
		MenuFocus.select_first(_menu.get_children())


func is_open() -> bool:
	return visible


## Say it all again in whatever language is up now.
func relabel() -> void:
	if _menu == null:
		return
	_build()
	if visible and _asking == &"":
		MenuFocus.select_first(_menu.get_children())


# ------------------------------------------------------------ for the checks

## Whether a question is up.
func asking() -> bool:
	return _asking != &""


## Which entry is asking, or nothing.
func question() -> StringName:
	return _asking


func cost_shown() -> String:
	return _cost.text if _question.visible else ""


func label_of(which: StringName) -> String:
	var button := _menu.get_node_or_null(
		NodePath("Pause_%s" % which)) as Button
	if button == null:
		button = _answers.get_node_or_null(NodePath("Pause_%s" % which)) as Button
	return button.text if button != null else ""


## The entries, in order, as the menu shows them.
func entries() -> Array:
	var out: Array = []
	for child in _menu.get_children():
		if child is Button:
			out.append(StringName(String(child.name).replace("Pause_", "")))
	return out


## The entry the caret is on, or nothing.
func selected() -> StringName:
	var on := MenuFocus.caret_on(
		(_answers if _asking != &"" else _menu).get_children())
	return StringName(String(on.name).replace("Pause_", "")) if on != null else &""
