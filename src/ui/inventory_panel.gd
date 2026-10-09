class_name InventoryPanel
extends Control

## A read-only ledger: one category at a time, split into bounded pages.
## The day keeps running. Q/E and pad bumpers reuse InputActions' hotbar
## actions while this view is open; mouse tabs and arrows use the same pages.
## Page and selection state live only here, never in the simulation.

const ROW_HEIGHT := 16
const ROW_SPACE := 160
const ROWS_PER_PAGE := ROW_SPACE / ROW_HEIGHT

var _state: Dictionary = {}
var _rows: VBoxContainer
var _tabs: VBoxContainer
var _heading: Label
var _previous: Button
var _next: Button
var _total: Label
var _built_for := ""
var _page := 0
var _pages: Array = []


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.name = "InventoryDim"
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.color = Color(0.02, 0.02, 0.05, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var frame := PanelContainer.new()
	frame.name = "InventoryFrame"
	frame.position = Vector2(20, 18)
	frame.custom_minimum_size = Vector2(440, 0)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(frame)
	var column := VBoxContainer.new()
	column.name = "InventoryColumn"
	frame.add_child(column)
	column.add_child(_line("InventoryTitle", I18n.t(&"INV_TITLE"), UiKit.WARM))
	var body := HBoxContainer.new()
	column.add_child(body)
	_tabs = VBoxContainer.new()
	_tabs.name = "InventoryTabs"
	_tabs.custom_minimum_size.x = 112
	body.add_child(_tabs)
	var content := VBoxContainer.new()
	body.add_child(content)
	_heading = _line("InventoryPage", "", UiKit.WARM)
	content.add_child(_heading)
	_rows = VBoxContainer.new()
	_rows.name = "InventoryRows"
	_rows.custom_minimum_size = Vector2(300, ROW_SPACE)
	content.add_child(_rows)
	var pager := HBoxContainer.new()
	content.add_child(pager)
	_previous = _button("InventoryPrevious", "", func() -> void: turn_page(-1))
	_next = _button("InventoryNext", "", func() -> void: turn_page(1))
	pager.add_child(_previous)
	pager.add_child(_next)
	_total = _line("InventoryTotal", "", UiKit.MONEY)
	column.add_child(_total)


func show_state(state: Dictionary) -> void:
	_state = state
	_built_for = ""


## Whether the ledger is up.
func is_open() -> bool:
	return visible


func toggle() -> void:
	visible = not visible
	if visible:
		_built_for = ""
		_process(0.0)


func close() -> void:
	visible = false


## Bounded slices: even seventy resources in one category fit the same frame.
static func pages_for(groups: Array) -> Array:
	var pages: Array = []
	for entry in groups:
		var rows: Array = entry["rows"]
		var count := int(ceil(float(rows.size()) / ROWS_PER_PAGE))
		for part in count:
			pages.append({"name": entry["name"], "part": part, "count": count,
				"rows": rows.slice(part * ROWS_PER_PAGE, (part + 1) * ROWS_PER_PAGE)})
	return pages


## Public view queries also let the input and screenshot harness visit every page.
func page_count() -> int:
	return _pages.size()


func current_page() -> int:
	return _page


func page_rows() -> Array:
	return _pages[_page]["rows"] if not _pages.is_empty() else []


func turn_page(step: int) -> void:
	if _pages.is_empty():
		return
	_page = posmod(_page + step, _pages.size())
	_build()


func select_group(id: StringName) -> void:
	for i in _pages.size():
		if _pages[i]["name"] == id:
			_page = i
			_build()
			return


# Consume page actions before the night hotbar sees them; the same binding
# still selects defences when the ledger is closed.
func _input(event: InputEvent) -> void:
	if not visible or _state.is_empty():
		return
	if event.is_action_pressed(&"hotbar_prev") or event.is_action_pressed(&"hotbar_next"):
		# This early handler consumes the event before the autoload's tracker.
		# Let the shared tracker see it so the arrows show the device in hand.
		var actions := get_tree().root.get_node_or_null("Actions")
		if actions != null:
			actions._input(event)
	if event.is_action_pressed(&"hotbar_prev"):
		turn_page(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"hotbar_next"):
		turn_page(1)
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if _state.is_empty():
		return
	if event.is_action_pressed(&"inventory"):
		toggle()
		get_viewport().set_input_as_handled()
	elif visible and event.is_action_pressed(&"cancel"):
		close()
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if _state.is_empty() or not visible:
		return
	var signature := _signature()
	if signature != _built_for:
		_built_for = signature
		_pages = pages_for(Inventory.groups(_state))
		_page = clampi(_page, 0, maxi(0, _pages.size() - 1))
		_build()


func _signature() -> String:
	var parts: Array = [str(I18n.revision()), _binding(&"hotbar_prev"),
		_binding(&"hotbar_next")]
	for entry in Inventory.rows(_state):
		parts.append("%s=%d" % [entry["id"], entry["held"]])
	return ",".join(parts)


func _clear(container: Container) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


func _build() -> void:
	(find_child("InventoryTitle", true, false) as Label).text = I18n.t(&"INV_TITLE")
	_clear(_rows)
	_clear(_tabs)
	var seen: Array = []
	for page in _pages:
		var id := StringName(page["name"])
		if id in seen:
			continue
		seen.append(id)
		var tab := _button("inv_tab_%s" % id, Names.group_of(id),
			func() -> void: select_group(id))
		tab.theme_type_variation = UiKit.TAB
		tab.toggle_mode = true
		tab.button_pressed = not _pages.is_empty() and _pages[_page]["name"] == id
		tab.custom_minimum_size = Vector2(112, 18)
		_tabs.add_child(tab)
	if not _pages.is_empty():
		var page: Dictionary = _pages[_page]
		_heading.text = I18n.f(&"INV_PAGE", [Names.group_of(page["name"]),
			page["part"] + 1, page["count"]])
		for row in page["rows"]:
			_rows.add_child(_row(row))
	_previous.text = I18n.f(&"INV_PREVIOUS", [_binding(&"hotbar_prev")])
	_next.text = I18n.f(&"INV_NEXT", [_binding(&"hotbar_next")])
	_previous.custom_minimum_size = Vector2(150, 16)
	_next.custom_minimum_size = Vector2(150, 16)
	_previous.disabled = _pages.size() < 2
	_next.disabled = _pages.size() < 2
	_total.text = I18n.f(&"INV_WORTH", [Inventory.worth(_state)])


func _button(node_name: String, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = text
	button.theme_type_variation = UiKit.ROW
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(action)
	return button


## One resource: what it is, how much, and what it fetches each.
func _row(line: Dictionary) -> Control:
	var held := int(line["held"])
	var row := HBoxContainer.new()
	row.name = "inv_%s" % line["id"]
	Tooltip.describes(row, StringName("resource:%s" % line["id"]))
	row.custom_minimum_size = Vector2(300, ROW_HEIGHT)
	var icon := TextureRect.new()
	icon.name = "inv_icon_%s" % line["id"]
	icon.texture = UiKit.icon(StringName(line["id"]),true)
	icon.modulate = PlaceholderArt.art_tint(StringName("hud_%s" % line["id"]))
	icon.modulate = PlaceholderArt.art_tint(StringName("hud_%s" % line["id"]))
	icon.custom_minimum_size = Vector2(10,10)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)

	var name_label := Label.new()
	name_label.name = "inv_name_%s" % line["id"]
	name_label.text = "  " + Names.of(StringName(line["id"]))
	name_label.custom_minimum_size = Vector2(164, 0)
	name_label.theme_type_variation = UiKit.DIM if held > 0 \
		else UiKit.FAINT
	row.add_child(name_label)

	var held_label := Label.new()
	held_label.name = "inv_held_%s" % line["id"]
	held_label.text = str(held)
	held_label.custom_minimum_size = Vector2(38, 0)
	held_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	held_label.theme_type_variation = UiKit.DIM if held > 0 \
		else UiKit.FAINT
	row.add_child(held_label)

	var price_label := Label.new()
	price_label.name = "inv_price_%s" % line["id"]
	# **Blank rather than zero** for the things that cannot be sold. Money has
	# no price and energy is a rate; "$0" would read as worthless, which is a
	# different thing from "not for sale".
	price_label.text = "  " + I18n.f(&"INV_PRICE", [int(line["price"])]) \
		if bool(line["sellable"]) else "   -"
	price_label.theme_type_variation = UiKit.DIM if held > 0 \
		else UiKit.FAINT
	row.add_child(price_label)

	return row


func _line(node_name: String, text: String,
		role: StringName = &"") -> Label:
	var label := Label.new()
	label.name = node_name
	label.text = text
	label.custom_minimum_size = Vector2(300, 12)
	label.theme_type_variation = role
	return label


func _binding(action: StringName) -> String:
	var actions := get_tree().root.get_node_or_null("Actions")
	return str(actions.text_of(action)) if actions != null else ""
