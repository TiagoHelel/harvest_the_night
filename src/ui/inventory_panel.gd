class_name InventoryPanel
extends Control

## Everything you own, on one key.
##
## The top bar shows six numbers because that is what fits across 480 pixels.
## There are fifteen resources. This is where the other nine live.
##
## ## It is a view, and it behaves like one
##
## **The day does not stop.** `design.md` calls the farm the cozy half, and a
## panel that paused the clock would make checking your stores a free action
## and reading the HUD a chore you do instead. Crops grow, the press runs and
## the animals go on standing there while this is up - it is a window, not a
## menu.
##
## It also takes no keys away. The shop panel of task 0020 sets
## `state["open_panel"]`, which stops the farmer walking, because standing at a
## stall and running are two different things. This does not: you can open it
## mid-walk and close it without stopping. Nothing in here can be clicked, so
## there is nothing to steal.
##
## ## Nothing here decides anything
##
## Every row comes from `Inventory.groups()`, which is in `src/core/` and reads
## the ledger on the spot. This file knows the colour of a heading and nothing
## else - which is what makes "add a resource and it appears with no UI edit"
## true: the panel is rebuilt from the list every time it is opened, and a list
## one longer is a panel one row taller.


const ROW_HEIGHT := 11

var _state: Dictionary = {}
var _rows: VBoxContainer
var _total: Label
var _built_for := ""


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
	# The complete fifteen-resource ledger is 252px tall at native resolution.
	frame.position = Vector2(138, 9)
	frame.custom_minimum_size = Vector2(204, 0)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(frame)

	var column := VBoxContainer.new()
	column.name = "InventoryColumn"
	frame.add_child(column)

	var title := _line("InventoryTitle", I18n.t(&"INV_TITLE"), UiKit.WARM)
	column.add_child(title)

	_rows = VBoxContainer.new()
	_rows.name = "InventoryRows"
	column.add_child(_rows)

	_total = _line("InventoryTotal", "", UiKit.MONEY)
	column.add_child(_total)


func show_state(state: Dictionary) -> void:
	_state = state


## Whether the panel is up. The key toggles it and nothing else does.
func is_open() -> bool:
	return visible


func toggle() -> void:
	visible = not visible
	if visible:
		_built_for = ""         # rebuild from the ledger, never from memory


func close() -> void:
	visible = false


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
	# **Rebuilt when the numbers move, not every frame.** A signature of what
	# is actually on screen, so picking up wood while this is open updates it
	# and standing still costs nothing.
	var signature := _signature()
	if signature != _built_for:
		_built_for = signature
		_build()


func _signature() -> String:
	var parts: Array = [str(I18n.revision())]
	for entry in Inventory.rows(_state):
		var r: Dictionary = entry
		parts.append("%s=%d" % [r["id"], r["held"]])
	return ",".join(parts)


func _build() -> void:
	(find_child("InventoryTitle",true,false) as Label).text = I18n.t(&"INV_TITLE")
	for child in _rows.get_children():
		# Out of the tree before it is freed: `queue_free()` is deferred, and
		# a container that lays out the old rows and the new ones for a frame
		# puts every row somewhere it is not drawn. Found in build mode in
		# task 0032.
		_rows.remove_child(child)
		child.queue_free()

	for entry in Inventory.groups(_state):
		var group: Dictionary = entry
		var rows: Array = group["rows"]
		if rows.is_empty():
			continue
		_rows.add_child(_line("group_%s" % group["name"],
			"- %s" % str(group["name"]).to_upper(), UiKit.WARM))
		for line in rows:
			_rows.add_child(_row(line as Dictionary))

	var worth := Inventory.worth(_state)
	_total.text = I18n.f(&"INV_WORTH", [worth])


## One resource: what it is, how much, and what it fetches each.
func _row(line: Dictionary) -> Control:
	var held := int(line["held"])
	var row := HBoxContainer.new()
	row.name = "inv_%s" % line["id"]
	Tooltip.describes(row, StringName("resource:%s" % line["id"]))
	row.custom_minimum_size = Vector2(190, ROW_HEIGHT)
	var icon := TextureRect.new()
	icon.name = "inv_icon_%s" % line["id"]
	icon.texture = UiKit.icon(StringName(line["id"]),true)
	icon.custom_minimum_size = Vector2(10,10)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)

	var name_label := Label.new()
	name_label.name = "inv_name_%s" % line["id"]
	name_label.text = "  " + Names.of(StringName(line["id"]))
	name_label.custom_minimum_size = Vector2(104, 0)
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
	price_label.text = "  $%d ea" % int(line["price"]) \
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
	label.custom_minimum_size = Vector2(190, ROW_HEIGHT)
	label.theme_type_variation = role
	return label
