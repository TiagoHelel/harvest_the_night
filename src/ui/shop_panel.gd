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

## Short enough that a full buy tab - six things on the shelf and three seeds
## under them - fits in the box without anybody having to scroll.
##
## **A default `Button` ignores this and reserves thirty-one pixels**, which at
## eleven rows is three hundred and forty on a screen two hundred and seventy
## tall: the seed rows landed at y=350, where a player would have to hunt for
## them and a click cannot reach them at all. `_button()` overrides the theme's
## padding, the same way the build palette does since task 0032.
const ROW_HEIGHT := 12

var _state: Dictionary = {}
var _rows: VBoxContainer
var _tabs: HBoxContainer
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
	add_child(frame)

	var column := VBoxContainer.new()
	column.name = "Column"
	frame.add_child(column)

	var title := Label.new()
	title.name = "Title"
	title.text = I18n.t(&"SHOP_TITLE")
	column.add_child(title)

	_money = Label.new()
	_money.name = "Money"
	column.add_child(_money)

	# **Two tabs, not two shops.** Buying and selling are one conversation
	# with one shopkeeper; a player who has to close a window and open
	# another to turn wood into stone is doing paperwork.
	_tabs = HBoxContainer.new()
	_tabs.name = "Tabs"
	for which in [Shop.SELL, Shop.BUY]:
		var side: StringName = which
		var tab := Button.new()
		tab.name = "tab_%s" % side
		tab.text = str(side).to_upper()
		tab.toggle_mode = true
		tab.custom_minimum_size = Vector2(72, 14)
		tab.theme_type_variation = UiKit.TAB
		tab.pressed.connect(func() -> void: Shop.show_tab(_state, side))
		_tabs.add_child(tab)
	column.add_child(_tabs)

	var scroll := ScrollContainer.new()
	scroll.name = "Scroll"
	scroll.custom_minimum_size = Vector2(276, 160)
	column.add_child(scroll)

	_rows = VBoxContainer.new()
	_rows.name = "Rows"
	scroll.add_child(_rows)

	var hint := Label.new()
	hint.name = "Hint"
	hint.text = I18n.t(&"SHOP_HINT")
	hint.theme_type_variation = UiKit.DIM
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
		+ Shop.value_of_stock(_state) * 1000 \
		+ _shelf_signature() * 100000
	if signature != _built_for:
		_build()

	# Lit from the state rather than from the click, so the autoplayer
	# switching tabs shows up on screen like anything else.
	for child in _tabs.get_children():
		var tab := child as Button
		if tab != null:
			tab.button_pressed = str(tab.name) == "tab_%s" % Shop.tab(_state)


## What else the rows depend on, folded into one number: which tab is
## showing, which seed is picked, and what is left on each shelf. The money
## and the bag are in the expression above; this is everything task 0040
## added that a row can be wrong about.
func _shelf_signature() -> int:
	var n := 1 if Shop.tab(_state) == Shop.SELL else 0
	n = n * 31 + Farming.seeds().find(Farming.selected_seed(_state))
	for id in Shop.buyable():
		n = n * 61 + Shop.stock_of(_state, id)
	return n


func _build() -> void:
	_built_for = Resources.amount(_state, GameData.MONEY) \
		+ Shop.value_of_stock(_state) * 1000 \
		+ _shelf_signature() * 100000
	_money.text = I18n.f(&"SHOP_MONEY",
		[Resources.amount(_state, GameData.MONEY)])

	for child in _rows.get_children():
		child.queue_free()

	if Shop.tab(_state) == Shop.SELL:
		_heading(&"SHOP_SELL")
		for id in Shop.sellable():
			_sell_row(id)
		return

	_heading(&"SHOP_BUY")
	for id in Shop.buyable():
		_buy_row(id)

	_heading(&"SHOP_SEEDS")
	for id in Farming.seeds():
		_seed_row(id)


func _heading(key: StringName) -> void:
	var label := Label.new()
	label.text = I18n.t(key)
	label.theme_type_variation = UiKit.WARM
	_rows.add_child(label)


## One crop, with everything the choice needs on one line: what a seed costs,
## how long it takes and what a plot of it is worth over a whole day. Clicking
## it picks it, which is the same thing the number keys do out in the field.
func _seed_row(id: StringName) -> void:
	var chosen := Farming.selected_seed(_state) == id
	var row := HBoxContainer.new()
	row.name = "seed_%s" % id
	Tooltip.describes(row, StringName("crop:%s" % id))
	row.custom_minimum_size = Vector2(0, ROW_HEIGHT)
	_rows.add_child(row)

	var label := Label.new()
	label.name = "seed_label_%s" % id
	label.text = I18n.f(&"SHOP_SEED_ROW", [Names.of(id),
		int((GameData.CROPS[id] as Dictionary)["seed_cost"]),
		Farming.days_to_grow(id), Farming.value_per_season(id)])
	label.custom_minimum_size = Vector2(168, 0)
	label.theme_type_variation = UiKit.WARM if chosen else UiKit.DIM
	row.add_child(label)

	row.add_child(_button("sow_%s" % id, I18n.t(&"SHOP_SOW"), not chosen,
		func() -> void: Farming.select_seed(_state, id)))


func _sell_row(id: StringName) -> void:
	var held := Resources.amount(_state, id)
	var row := HBoxContainer.new()
	row.name = "sell_%s" % id
	Tooltip.describes(row, StringName("resource:%s" % id))
	row.custom_minimum_size = Vector2(0, ROW_HEIGHT)
	_rows.add_child(row)

	var label := Label.new()
	label.text = I18n.f(&"SHOP_SELL_ROW",
		[Names.of(id), held, Shop.sell_price(id)])
	label.custom_minimum_size = Vector2(168, 0)
	# **Shown, not hidden**, when there is none: the list is also how a player
	# learns what this farm produces and what it is worth.
	label.theme_type_variation = &"" if held > 0 else UiKit.FAINT
	row.add_child(label)

	row.add_child(_button("sell_one_%s" % id, I18n.t(&"SHOP_ONE"), held > 0,
		func() -> void: Shop.sell(_state, id, 1)))
	row.add_child(_button("sell_all_%s" % id, I18n.t(&"SHOP_ALL"), held > 0,
		func() -> void: Shop.sell_all(_state, id)))


func _buy_row(id: StringName) -> void:
	var price := Shop.buy_price(id)
	var afford := Resources.amount(_state, GameData.MONEY) >= price
	var row := HBoxContainer.new()
	row.name = "buy_%s" % id
	Tooltip.describes(row, StringName("resource:%s" % id))
	row.custom_minimum_size = Vector2(0, ROW_HEIGHT)
	_rows.add_child(row)

	var left := Shop.stock_of(_state, id)
	var label := Label.new()
	label.name = "buy_label_%s" % id
	# **What is left is on the label.** A price with no stock beside it is a
	# button that refuses for a reason the player cannot see.
	label.text = I18n.f(&"SHOP_BUY_ROW", [Names.of(id), price, left])
	label.custom_minimum_size = Vector2(168, 0)
	label.theme_type_variation = &"" if afford and left > 0 \
		else UiKit.FAINT
	row.add_child(label)

	row.add_child(_button("buy_one_%s" % id, I18n.t(&"SHOP_ONE"),
		Shop.can_buy(_state, id, 1),
		func() -> void: Shop.buy(_state, id, 1)))
	row.add_child(_button("buy_five_%s" % id, I18n.t(&"SHOP_FIVE"),
		Shop.can_buy(_state, id, 5),
		func() -> void: Shop.buy(_state, id, 5)))


## A button that is greyed rather than missing when it cannot be pressed, and
## **named**, because `input_check` finds it by name and a button nothing can
## find is a button nothing tests.
func _button(button_name: String, text: String, enabled: bool,
		action: Callable) -> Button:
	var button := Button.new()
	button.name = button_name
	if button_name.begins_with("sell_one_") or button_name.begins_with("buy_one_"):
		var id := button_name.trim_prefix("sell_one_").trim_prefix("buy_one_")
		button.icon = UiKit.icon(StringName(id),true)
	button.text = text
	button.disabled = not enabled
	button.custom_minimum_size = Vector2(34, ROW_HEIGHT)
	button.pressed.connect(action)
	return button
