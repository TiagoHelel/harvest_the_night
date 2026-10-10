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
##
## **And the shipping bin's** (task 0189): the same panel opens when the bin's
## lid does, with the stall's sell rows putting stacks in the bin instead of
## selling them, the morning's total where the money was, and no tabs. The
## keyboard and the pad have a way in here that the stall does not: it opens
## with a row's `all` lit, the arrows and the d-pad walk the rows, and SPACE,
## ENTER or A puts the stack in.

## Emitted when the player closes it, so the screen can put the keys back.
signal closed

## Compact shelf rows and six seeds per page (0168). The scroll container
## still reaches the final row when a language needs more vertical space.
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
var _title: Label
var _hint: Label
## Whether it is the bin's panel rather than the stall's (task 0189).
var _bin := false
var _seed_page := 0
var _last_seed := &""
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

	_title = Label.new()
	_title.name = "Title"
	_title.text = I18n.t(&"SHOP_TITLE")
	column.add_child(_title)

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
	scroll.custom_minimum_size = Vector2(276, 174)
	# The row the keyboard is on stays in view (task 0189).
	scroll.follow_focus = true
	column.add_child(scroll)

	_rows = VBoxContainer.new()
	_rows.name = "Rows"
	scroll.add_child(_rows)

	_hint = Label.new()
	_hint.name = "Hint"
	_hint.text = I18n.t(&"SHOP_HINT")
	_hint.theme_type_variation = UiKit.DIM
	column.add_child(_hint)


func show_state(state: Dictionary) -> void:
	_state = state


func _process(_delta: float) -> void:
	if _state.is_empty():
		return
	var should_be_open := Shop.is_open(_state) or Shipping.is_open(_state)
	var bin := Shipping.is_open(_state)
	if should_be_open != visible or (should_be_open and bin != _bin):
		visible = should_be_open
		_bin = bin
		if visible:
			_build()
		else:
			closed.emit()
	if not visible:
		return

	# Prices never change, but what the player holds does - and a row that said
	# "sell 12 wood" after you had sold it would be a lie the panel told.
	if _signature() != _built_for:
		_build()

	# Lit from the state rather than from the click, so the autoplayer
	# switching tabs shows up on screen like anything else.
	for child in _tabs.get_children():
		var tab := child as Button
		if tab != null:
			tab.button_pressed = str(tab.name) == "tab_%s" % Shop.tab(_state)


## Everything the rows are drawn against: the money and the bag, the
## shelves, and for the bin what it holds.
func _signature() -> int:
	var n := Resources.amount(_state, GameData.MONEY) \
		+ Shop.value_of_stock(_state) * 1000 \
		+ _shelf_signature() * 100000
	if _bin:
		n = n * 31 + Shipping.due(_state) * 7 + 1
	return n


## What else the rows depend on, folded into one number: which tab is
## showing, which seed is picked, and what is left on each shelf. The money
## and the bag are in the expression above; this is everything task 0040
## added that a row can be wrong about.
func _shelf_signature() -> int:
	var n := 1 if Shop.tab(_state) == Shop.SELL else 0
	n = n * 31 + Calendar.season_of(Calendar.date(_state))
	n = n * 31 + Farming.seeds().find(Farming.selected_seed(_state))
	for id in Shop.buyable(_state):
		n = n * 61 + Shop.stock_of(_state, id)
	# The animals and the upgrades (task 0190): their shelf, the room in
	# the homes, and the tools' ladder.
	for id in Shop.animals():
		n = n * 61 + Shop.stock_of(_state, id) * 7 + Livestock.room_for(_state, id)
	for id in Shop.upgrades():
		n = n * 61 + Shop.stock_of(_state, id)
	return n * 31 + str(_state["tools"]).hash()


func _build() -> void:
	var chosen := Farming.selected_seed(_state)
	if chosen != _last_seed:
		_seed_page = maxi(Farming.in_season(_state).find(chosen), 0) / DayHud.SEED_ACTIONS.size()
		_last_seed = chosen
	_built_for = _signature()
	_title.text = I18n.t(&"SHIP_TITLE" if _bin else &"SHOP_TITLE")
	_hint.text = I18n.t(&"SHIP_HINT" if _bin else &"SHOP_HINT")
	_tabs.visible = not _bin
	_money.text = I18n.f(&"SHIP_DUE", [Shipping.due(_state)]) if _bin \
		else I18n.f(&"SHOP_MONEY", [Resources.amount(_state, GameData.MONEY)])

	# The button the keyboard was on, to light again once its row is redrawn.
	var lit := get_viewport().gui_get_focus_owner() if is_inside_tree() else null
	var was := str(lit.name) if lit != null and _rows.is_ancestor_of(lit) else ""
	for child in _rows.get_children():
		_rows.remove_child(child)
		child.queue_free()

	# **The bin's rows** (task 0189): the stall's sell rows, putting in.
	if _bin:
		_heading(&"SHIP_HEADING")
		for id in Shop.sellable():
			_sell_row(id, true)
		_focus(was)
		return

	if Shop.tab(_state) == Shop.SELL:
		_heading(&"SHOP_SELL")
		for id in Shop.sellable():
			_sell_row(id)
		return

	_heading(&"SHOP_BUY")
	for id in Shop.buyable(_state):
		_buy_row(id)
	# **What the farm cannot make for itself** (task 0190): the animals,
	# into a coop or a barn with room, and the workshop's tool upgrades.
	_heading(&"SHOP_ANIMALS")
	for id in Shop.animals():
		_one_row(id)
	_heading(&"SHOP_TOOLS")
	for id in Shop.upgrades():
		_one_row(id)

	var pager := HBoxContainer.new()
	_rows.add_child(pager)
	var heading := Label.new()
	heading.text = I18n.t(&"SHOP_SEEDS")
	heading.theme_type_variation = UiKit.WARM
	pager.add_child(heading)
	var seeds := Farming.in_season(_state)
	if seeds.is_empty():
		heading.text = I18n.t(&"DHUD_NO_SEEDS")
		return
	var pages := ceili(float(seeds.size()) / DayHud.SEED_ACTIONS.size())
	pager.add_child(_button("ShopSeedsPrevious", I18n.t(&"SEED_PREVIOUS"), _seed_page > 0,
		func() -> void: _seed_page -= 1; _build()))
	var badge := Label.new()
	badge.text = I18n.f(&"SEED_PAGE", [_seed_page + 1, pages])
	pager.add_child(badge)
	pager.add_child(_button("ShopSeedsNext", I18n.t(&"SEED_NEXT"), _seed_page + 1 < pages,
		func() -> void: _seed_page += 1; _build()))
	for i in range(_seed_page * DayHud.SEED_ACTIONS.size(),
		mini((_seed_page + 1) * DayHud.SEED_ACTIONS.size(), seeds.size())):
		_seed_row(seeds[i])


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
		Resources.amount(_state, Farming.packet(id)),
		Farming.days_to_grow(id), Farming.value_per_season(id)])
	label.custom_minimum_size = Vector2(168, 0)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.theme_type_variation = UiKit.WARM if chosen else UiKit.DIM
	row.add_child(label)

	row.add_child(_button("sow_%s" % id, I18n.t(&"SHOP_SOW"), not chosen,
		func() -> void: Farming.select_seed(_state, id)))


## One thing the stall will buy - or, for the bin (task 0189), put in it:
## the same name, count and price, and `ship_` buttons.
func _sell_row(id: StringName, ship := false) -> void:
	var held := Resources.amount(_state, id)
	var row := HBoxContainer.new()
	row.name = ("ship_%s" if ship else "sell_%s") % id
	Tooltip.describes(row, StringName("resource:%s" % id))
	row.custom_minimum_size = Vector2(0, ROW_HEIGHT)
	_rows.add_child(row)

	var label := Label.new()
	label.text = I18n.f(&"SHOP_SELL_ROW",
		[Names.of(id), held, Shop.sell_price(id)])
	label.custom_minimum_size = Vector2(168, 0)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# **Shown, not hidden**, when there is none: the list is also how a player
	# learns what this farm produces and what it is worth.
	label.theme_type_variation = &"" if held > 0 else UiKit.FAINT
	row.add_child(label)

	if ship:
		row.add_child(_button("ship_one_%s" % id, I18n.t(&"SHOP_ONE"), held > 0,
			func() -> void: Shipping.put(_state, id, 1)))
		row.add_child(_button("ship_all_%s" % id, I18n.t(&"SHOP_ALL"), held > 0,
			func() -> void: Shipping.put_all(_state, id)))
		return
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
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.theme_type_variation = &"" if afford and left > 0 \
		else UiKit.FAINT
	row.add_child(label)

	row.add_child(_button("buy_one_%s" % id, I18n.t(&"SHOP_ONE"),
		Shop.can_buy(_state, id, 1),
		func() -> void: Shop.buy(_state, id, 1)))
	row.add_child(_button("buy_five_%s" % id, I18n.t(&"SHOP_FIVE"),
		Shop.can_buy(_state, id, 5),
		func() -> void: Shop.buy(_state, id, 5)))


## **The keyboard's and the pad's way into the bin** (task 0189): light the
## button that was lit before the rows were redrawn, or - when it has gone
## grey, or nothing was - the first stack that can go in.
func _focus(was: String) -> void:
	var button: Button = _rows.find_child(was, true, false) as Button if was != "" else null
	if button == null or button.disabled:
		button = null
		for id in Shop.sellable():
			var each := _rows.find_child("ship_all_%s" % id, true, false) as Button
			if each != null and not each.disabled:
				button = each
				break
	if button != null and button.is_inside_tree():
		button.grab_focus()


## **An animal or a tool upgrade** (task 0190): its name, what it costs and
## how many are left, and one button, greyed with the reason on its tooltip
## when there is no home for it or the ladder says no.
func _one_row(id: StringName) -> void:
	var row := HBoxContainer.new()
	row.name = "buy_%s" % id
	row.custom_minimum_size = Vector2(0, ROW_HEIGHT)
	_rows.add_child(row)
	var cost: Array = []
	var price := Shop.cost_of(id)
	for res in GameData.sorted_names(price.keys()):
		cost.append("$%d" % int(price[res]) if res == GameData.MONEY
			else "%d %s" % [int(price[res]), Names.of(res)])
	var label := Label.new()
	label.name = "buy_label_%s" % id
	label.text = I18n.f(&"SHOP_ONE_ROW", [Names.of(id), " ".join(cost), Shop.stock_of(_state, id)])
	label.custom_minimum_size = Vector2(168, 0)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var why := Shop.why_not_buy(_state, id)
	label.theme_type_variation = &"" if why.is_empty() else UiKit.FAINT
	row.add_child(label)
	# **An order, not a quantity button**: no resource's icon to show. An
	# upgrade shows the tool it makes, an animal nothing yet.
	var button := _button("order_%s" % id, I18n.t(&"SHOP_ONE"), why.is_empty(),
		func() -> void: Shop.buy(_state, id, 1))
	if GameData.is_tool_upgrade(id):
		button.icon = UiKit.icon(StringName(((GameData.RECIPES[id] as Dictionary)["output"] as Dictionary).keys()[0]), true)
	Tooltip.describes(button, StringName("text:%s" % (Names.refusal(why) if not why.is_empty()
		else Names.of(id))))
	row.add_child(button)


## A button that is greyed rather than missing when it cannot be pressed, and
## **named**, because `input_check` finds it by name and a button nothing can
## find is a button nothing tests.
func _button(button_name: String, text: String, enabled: bool,
		action: Callable) -> Button:
	var button := Button.new()
	button.name = button_name
	if button_name.begins_with("sell_one_") or button_name.begins_with("buy_one_") \
			or button_name.begins_with("ship_one_"):
		var id := StringName(button_name.trim_prefix("sell_one_").trim_prefix("buy_one_").trim_prefix("ship_one_"))
		button.icon = UiKit.icon(id, true)
		if id.ends_with("_seed"):
			button.theme_type_variation = UiKit.SEED_PACKET
	button.text = text
	button.disabled = not enabled
	button.custom_minimum_size = Vector2(34, ROW_HEIGHT)
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.pressed.connect(action)
	return button
