class_name CreditsRoll
extends Control

## The year's credits, before either ending choice. All motion is view-only.
signal finished

const SCROLL_SPEED := 18.0
const LINES: Array[StringName] = [&"CRED_GAME", &"CRED_DESIGN", &"CRED_ENGINE",
	&"CRED_ART", &"CRED_THANKS"]

var _roll: VBoxContainer
var _window: Control
var _title: Label
var _skip: Button


func _ready() -> void:
	visible = false
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	panel.position = Vector2(80, 21)
	panel.custom_minimum_size = Vector2(320, 228)
	add_child(panel)
	var column := VBoxContainer.new()
	panel.add_child(column)
	var title := Label.new()
	_title = title
	title.text = I18n.t(&"END_TITLE")
	title.theme_type_variation = UiKit.GOOD
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	_window = Control.new()
	_window.custom_minimum_size = Vector2(300, 156)
	_window.clip_contents = true
	column.add_child(_window)
	_roll = VBoxContainer.new()
	_roll.size = Vector2(300, 0)
	_window.add_child(_roll)
	for key in LINES:
		var line := Label.new()
		line.text = I18n.t(key)
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line.custom_minimum_size = Vector2(300, 30)
		line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_roll.add_child(line)
	var skip := Button.new()
	_skip = skip
	skip.name = "SkipCreditsButton"
	skip.custom_minimum_size = Vector2(300, 20)
	skip.text = I18n.t(&"CRED_SKIP")
	skip.pressed.connect(finish)
	column.add_child(skip)


## Start a fresh roll; it is never a simulation timer.
func start() -> void:
	_title.text = I18n.t(&"END_TITLE")
	_skip.text = I18n.t(&"CRED_SKIP")
	for i in LINES.size():
		(_roll.get_child(i) as Label).text = I18n.t(LINES[i])
	_roll.position.y = 50.0
	visible = true


## Both the end of the roll and a skip open the same two choices.
func finish() -> void:
	if not visible:
		return
	visible = false
	finished.emit()


func _process(delta: float) -> void:
	if visible:
		_roll.position.y -= SCROLL_SPEED * delta
		if _roll.position.y + _roll.size.y < 0.0:
			finish()


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or event.is_echo():
		return
	if event.is_action_pressed(&"ui_accept") or event.is_action_pressed(&"interact") \
			or event.is_action_pressed(&"night") or event.is_action_pressed(&"cancel") \
			or event.is_action_pressed(&"ui_cancel") \
			or event.is_action_pressed(&"place") or event.is_action_pressed(&"remove"):
		get_viewport().set_input_as_handled()
		finish()
