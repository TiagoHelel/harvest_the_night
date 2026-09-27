class_name ShopPanel
extends Control

## The stall, drawn.
##
## It reads `Shop` for everything and writes nothing except through `Shop`'s own
## functions, which go through the ledger. There is no arithmetic in this file:
## a price shown here and a price charged by the rules would be two numbers that
## could disagree, and the one the player believes is the one on screen.
##
## Task 0081 gives it the game's theme and task 0040 gives it tabs, stock and a
## daily limit. What it has to be today is honest and usable.

## Emitted when the player closes it, so the screen can put the keys back.
signal closed

const ROW_HEIGHT := 14

var _state: Dictionary = {}
var _rows: VBoxContainer
var _money: Label
var _built_for := -1        # the money total the rows were last drawn against


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP     # it is a panel; it eats clicks
	set_anchors_preset(Control.PRESET_CENTER)

	var frame := PanelContainer.new()
	frame.name = "Frame"
	frame.position = Vector2(96, 24)
	frame.custom_minimum_size = Vector2(288, 222)
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.06, 0.05, 0.10, 0.96)
	box.border_color = Color(0.55, 0.45, 0.30)
	box.set_border_width_all(1)
	box.set_content_margin_all(6)
	frame.add_theme_stylebox_override("panel", box)
	add_child(frame)

	var column := VBoxContainer.new()
	column.name = "Column"
	frame.add_child(column)

	var title := Label.new()
	title.name = "Title"
	title.text = "MARKET"
	column.add_child(title)

	_money = Label.new()
	_money.name = "Money"
	column.add_child(_money)

	var scroll := ScrollContainer.new()
	scroll.name = "Scroll"
	scroll.custom_minimum_size = Vector2(276, 160)
	column.add_child(scroll)

	_rows = VBoxContainer.new()
	_rows.name = "Rows"
	scroll.add_child(_rows)

	var hint := Label.new()
	hint.name = "Hint"
	hint.text = "esc to leave"
	hint.modulate = Color(0.6, 0.58, 0.68)
	column.add_child(hint)


func show_state(state: Dictionary) -> void:
	_state = state


func _process(_delta: float) -> void:
	if _state.is_empty():
		return
	var should_be_open := Shop.is_open(_state)
	if should_be_open != visible:
		visible = should_be_open
		if visible:
			_build()
		else:
			closed.emit()
	if not visible:
		return

	# Prices never change, but what the player holds does - and a row that said
	# "sell 12 wood" after you had sold it would be a lie the panel told.
	var signature := Resources.amount(_state, GameData.MONEY) \
		+ Shop.value_of_stock(_state) * 1000
	if signature != _built_for:
		_build()


func _build() -> void:
	_built_for = Resources.amount(_state, GameData.MONEY) \
		+ Shop.value_of_stock(_state) * 1000
	_money.text = "$ %d" % Resources.amount(_state, GameData.MONEY)

	for child in _rows.get_children():
		child.queue_free()

	_heading("SELL")
	for id in Shop.sellable():
		_sell_row(id)

	_heading("BUY")
	for id in Shop.buyable():
		_buy_row(id)


func _heading(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.modulate = Color(0.75, 0.68, 0.45)
	_rows.add_child(label)


func _sell_row(id: StringName) -> void:
	var held := Resources.amount(_state, id)
	var row := HBoxContainer.new()
	row.name = "sell_%s" % id
	row.custom_minimum_size = Vector2(0, ROW_HEIGHT)
	_rows.add_child(row)

	var label := Label.new()
	label.text = "%s  x%d  @ $%d" % [id, held, Shop.sell_price(id)]
	label.custom_minimum_size = Vector2(168, 0)
	# **Shown, not hidden**, when there is none: the list is also how a player
	# learns what this farm produces and what it is worth.
	label.modulate = Color(1, 1, 1) if held > 0 else Color(0.45, 0.43, 0.5)
	row.add_child(label)

	row.add_child(_button("sell_one_%s" % id, "1", held > 0,
		func() -> void: Shop.sell(_state, id, 1)))
	row.add_child(_button("sell_all_%s" % id, "all", held > 0,
		func() -> void: Shop.sell_all(_state, id)))


func _buy_row(id: StringName) -> void:
	var price := Shop.buy_price(id)
	var afford := Resources.amount(_state, GameData.MONEY) >= price
	var row := HBoxContainer.new()
	row.name = "buy_%s" % id
	row.custom_minimum_size = Vector2(0, ROW_HEIGHT)
	_rows.add_child(row)

	var label := Label.new()
	label.text = "%s  @ $%d" % [id, price]
	label.custom_minimum_size = Vector2(168, 0)
	label.modulate = Color(1, 1, 1) if afford else Color(0.45, 0.43, 0.5)
	row.add_child(label)

	row.add_child(_button("buy_one_%s" % id, "1", afford,
		func() -> void: Shop.buy(_state, id, 1)))
	row.add_child(_button("buy_five_%s" % id, "5",
		Resources.amount(_state, GameData.MONEY) >= price * 5,
		func() -> void: Shop.buy(_state, id, 5)))


## A button that is greyed rather than missing when it cannot be pressed, and
## **named**, because `input_check` finds it by name and a button nothing can
## find is a button nothing tests.
func _button(button_name: String, text: String, enabled: bool,
		action: Callable) -> Button:
	var button := Button.new()
	button.name = button_name
	button.text = text
	button.disabled = not enabled
	button.custom_minimum_size = Vector2(28, ROW_HEIGHT)
	button.pressed.connect(action)
	return button
