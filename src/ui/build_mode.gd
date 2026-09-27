class_name BuildMode
extends Control

## The palette, the ghost, and the two clicks.
##
## `B` turns it on. The palette lists **everything the phase allows**, greyed
## and labelled with what is short rather than hidden, because a menu that grew
## as you got richer would teach nothing about what to go and get. The ghost
## under the cursor is green where it fits and red where it does not, and the
## line under the palette says why.
##
## **It decides nothing.** Where the player is pointing and what they asked for
## go into the intent; `Building.tick()` is what puts a wall up. That is the
## same road the autoplayer of task 0067 will take, and it is why a placement
## can never happen on a frame the rules did not agree to.

## Kept short on purpose: the palette has to fit on a 270 pixel screen
## with a dozen things on it.
const ROW_HEIGHT := 11

var _state: Dictionary = {}
var _view: WorldView
var _rows: VBoxContainer
var _reason: Label
var _built_for := ""            # what the palette was last drawn against
var _hovered := Vector2i(-1, -1)

## Where the pointer is, taken from the events rather than polled.
##
## `get_viewport().get_mouse_position()` asks the display server, which does not
## follow a synthesised event - so under `input_check` the ghost stayed wherever
## the real cursor happened to be and every placement went to the wrong cell.
## Events carry their own position and are what the player actually did.
var _pointer := Vector2(-1, -1)


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var frame := PanelContainer.new()
	frame.name = "Frame"
	frame.position = Vector2(4, 30)
	frame.custom_minimum_size = Vector2(124, 0)
	frame.mouse_filter = Control.MOUSE_FILTER_STOP
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.06, 0.05, 0.10, 0.94)
	box.border_color = Color(0.45, 0.42, 0.55)
	box.set_border_width_all(1)
	box.set_content_margin_all(5)
	frame.add_theme_stylebox_override("panel", box)
	add_child(frame)

	var column := VBoxContainer.new()
	column.name = "Column"
	frame.add_child(column)

	var title := Label.new()
	title.name = "BuildTitle"
	title.text = "BUILD"
	title.add_theme_font_size_override("font_size", 9)
	column.add_child(title)

	_rows = VBoxContainer.new()
	_rows.name = "BuildRows"
	# No gap between rows. The default theme puts four pixels between children,
	# which across a dozen entries is fifty pixels of nothing on a screen that
	# is two hundred and seventy tall.
	_rows.add_theme_constant_override("separation", 0)
	column.add_child(_rows)

	_reason = Label.new()
	_reason.name = "BuildReason"
	_reason.add_theme_font_size_override("font_size", 8)
	_reason.modulate = Color(0.85, 0.55, 0.5)
	column.add_child(_reason)


func show_state(state: Dictionary, view: WorldView) -> void:
	_state = state
	_view = view


func _process(_delta: float) -> void:
	if _state.is_empty() or _view == null:
		return

	# A panel takes precedence: shopping and building at once is two cursors.
	var blocked := StringName(_state["open_panel"]) != &""
	visible = Building.is_active(_state) and not blocked
	if not visible:
		if _view != null:
			_view.hide_ghost()
			_view.clear_route()
		return

	var key := "%s|%d|%d" % [Building.selected(_state), int(_state["phase"]),
		Resources.amount(_state, GameData.WOOD)
			+ Resources.amount(_state, GameData.STONE) * 1000
			+ Resources.amount(_state, GameData.IRON) * 1000000]
	if key != _built_for:
		_built_for = key
		_build_palette()

	_follow_cursor()


## Where the mouse is, what would happen there, and the ghost that says so.
func _follow_cursor() -> void:
	var at := _pointer
	if at.x < 0.0:
		at = get_viewport().get_mouse_position()
	var cell := _view.screen_to_cell(at)
	_hovered = cell
	var id := Building.selected(_state)
	(_state["intent"] as Dictionary)["build_cell"] = [cell.x, cell.y]

	if not Grid.in_bounds(cell) or id == &"":
		_view.hide_ghost()
		_reason.text = ""
		return

	var reason := Building.why_not(_state, id, cell)
	_view.show_ghost(cell, id, reason.is_empty())
	_reason.text = reason

	# **What the zombies would do about it.** Only for a thing that actually
	# blocks the way, and only where it could go: previewing a route around a
	# tower the player cannot afford is answering a question nobody asked.
	if reason.is_empty() and _blocks_the_way(id):
		_view.show_route(Pathing.route_if_blocked(_state, cell,
			_a_way_in(), ROUTE_STEPS))
	else:
		_view.clear_route()


## Whether this is a thing zombies have to go round. A tower blocks too, but
## a player putting one down is thinking about range, not about traffic; the
## line is for the things whose whole job is traffic.
func _blocks_the_way(id: StringName) -> bool:
	return (GameData.DEFENCES.get(id, {}) as Dictionary).has("path_cost")


## Where to draw the route from: the spawn the next wave uses.
func _a_way_in() -> Vector2i:
	var cells := Enemies.spawn_cells(_state, 0)
	return Vector2i(-1, -1) if cells.is_empty() else cells[0]


## Long enough to cross the farm, short enough that a preview is cheap.
const ROUTE_STEPS := 120


## Motion is watched here rather than in `_unhandled_input`, because a panel
## with `MOUSE_FILTER_STOP` eats it before it gets that far - and the pointer
## still has to be known while the cursor is over the palette.
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_pointer = (event as InputEventMouseMotion).position
	elif event is InputEventMouseButton:
		_pointer = (event as InputEventMouseButton).position


func _unhandled_input(event: InputEvent) -> void:
	if _state.is_empty():
		return

	if event.is_action_pressed(&"build"):
		Building.set_active(_state, not Building.is_active(_state))
		get_viewport().set_input_as_handled()
		return

	if not visible or not (event is InputEventMouseButton):
		return
	var click: InputEventMouseButton = event
	if not click.pressed:
		return

	var intent: Dictionary = _state["intent"]
	if click.button_index == MOUSE_BUTTON_LEFT:
		intent["build_place"] = true
		get_viewport().set_input_as_handled()
	elif click.button_index == MOUSE_BUTTON_RIGHT:
		# **Right click sells**, and only in build mode: a stray right click
		# while farming should not take a tower down.
		intent["build_sell"] = true
		get_viewport().set_input_as_handled()


func _build_palette() -> void:
	# **Out of the tree first, then freed.** `queue_free()` alone is deferred,
	# so for one frame the container holds the old rows and the new ones and
	# lays out twice as many as it has - every row sits somewhere it is not
	# drawn, and a click lands on the wrong one. Harmless while the palette was
	# eight rows of defences and immediately visible at twelve, when task 0032
	# added the buildings: clicking "press" selected "auto_crossbow".
	for child in _rows.get_children():
		_rows.remove_child(child)
		child.queue_free()

	for id in Building.catalogue(_state):
		var row := Button.new()
		row.name = "build_%s" % id
		row.custom_minimum_size = Vector2(114, ROW_HEIGHT)
		row.add_theme_font_size_override("font_size", 8)
		# **The theme's padding, overridden.** A default Button reserves about
		# twenty pixels whatever `ROW_HEIGHT` says, and twelve of those is 327
		# pixels of palette on a 270 pixel screen - which is exactly what
		# happened when task 0032 made the four buildings placeable: the press
		# row landed at y=294 and could not be clicked at all. There is an
		# assert in input_check now that the whole palette is on the screen.
		for style in ["normal", "hover", "pressed", "focus", "disabled"]:
			var box := StyleBoxFlat.new()
			box.bg_color = Color(0.12, 0.11, 0.18, 0.0 if style == "focus" 				else 0.8)
			if style == "pressed":
				box.bg_color = Color(0.32, 0.30, 0.20, 0.95)
			elif style == "hover":
				box.bg_color = Color(0.20, 0.19, 0.28, 0.9)
			box.content_margin_left = 3
			box.content_margin_right = 3
			box.content_margin_top = 1
			box.content_margin_bottom = 1
			row.add_theme_stylebox_override(style, box)
		row.text = "%s  %s" % [id, _price_of(id)]
		row.toggle_mode = true
		row.button_pressed = id == Building.selected(_state)
		# **Shown rather than hidden** when it cannot be paid for. The ghost
		# and the reason line explain it the moment the cursor moves.
		row.modulate = Color(1, 1, 1) if Building.affordable(_state, id) \
			else Color(0.5, 0.48, 0.55)
		row.pressed.connect(func() -> void: Building.select(_state, id))
		_rows.add_child(row)


func _price_of(id: StringName) -> String:
	var banked := Crafting.kits(_state, id)
	if banked > 0:
		return "(%d ready)" % banked
	var parts: Array = []
	var cost := Building.cost_of(id)
	var keys: Array = cost.keys()
	keys.sort()
	for res in keys:
		parts.append("%d%s" % [cost[res], str(res).substr(0, 1)])
	return " ".join(parts)
