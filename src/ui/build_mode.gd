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

## What a row that cannot be paid for is multiplied by. **An alpha rather
## than a grey**: the theme already says what colour a row is, and a second
## colour here would be the theme said twice and disagreed with once.
const FADED := Color(1, 1, 1, 0.55)

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

## The cell the last placement went on, while a button is still down.
##
## **Task 0098: holding is an alternative to pressing.** A fence along one
## side of the farm is a dozen clicks, and a dozen clicks in the same second
## is the thing some hands cannot do. Dragging places one per cell and never
## twice on the same one.
var _held_cell := Vector2i(-1, -1)

## The text palette. **By day only** since task 0133: at night the hotbar is
## the palette, and the reason a placement is refused rides on the cursor's
## tooltip.
var _frame: PanelContainer


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var frame := PanelContainer.new()
	_frame = frame
	frame.name = "Frame"
	frame.position = Vector2(4, 30)
	frame.custom_minimum_size = Vector2(124, 0)
	frame.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(frame)

	var column := VBoxContainer.new()
	column.name = "Column"
	frame.add_child(column)

	var title := Label.new()
	title.name = "BuildTitle"
	title.text = I18n.t(&"BUILD_TITLE")
	column.add_child(title)

	_rows = VBoxContainer.new()
	_rows.name = "BuildRows"
	column.add_child(_rows)

	_reason = Label.new()
	_reason.name = "BuildReason"
	_reason.theme_type_variation = UiKit.BAD
	# **It wraps now.** The panel is 124 wide and "already occupied by a gun
	# tower" is not, so before task 0110 the end of most refusals was off the
	# side of the frame. Two lines of it is the room there is.
	_reason.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_reason.custom_minimum_size = Vector2(114, 20)
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

	_frame.visible = not _by_cursor()
	var key := "%s|%d|%d" % [Building.selected(_state), int(_state["phase"]),
		Resources.amount(_state, GameData.WOOD)
			+ Resources.amount(_state, GameData.STONE) * 1000
			+ Resources.amount(_state, GameData.IRON) * 1000000]
	if key != _built_for:
		_built_for = key
		_build_palette()

	_follow_cursor()
	_keep_placing()


## **Holding the button places one per cell, and never twice on the same
## one.** The press itself is handled where every other press is; this is what
## happens while it is still down and the cursor has moved somewhere new.
##
## Off when `a11y/hold_to_act` is off, for a player who would rather one press
## meant one thing.
func _keep_placing() -> void:
	if not Input.is_action_pressed(&"place") \
			and not (_by_cursor() and Input.is_action_pressed(&"interact")):
		_held_cell = Vector2i(-1, -1)
		return
	if _hovered == _held_cell or not Grid.in_bounds(_hovered):
		return
	var access := get_node_or_null(^"/root/Access")
	if access != null and not access.holding():
		return
	_held_cell = _hovered
	(_state["intent"] as Dictionary)["build_place"] = true


## Where the mouse is, what would happen there, and the ghost that says so.
func _follow_cursor() -> void:
	var at := _pointer
	if at.x < 0.0:
		at = get_viewport().get_mouse_position()
	var cell := _view.screen_to_cell(at)
	# **The guardian's cursor, while there is one** (task 0131): from the build
	# step to the morning the ghost and its route preview go where it is, so
	# a pad that steps it places exactly where the mouse would.
	var cursor := _view.cursor()
	if cursor != null and cursor.is_active():
		cell = cursor.cell()
	_hovered = cell
	var id := Building.selected(_state)
	(_state["intent"] as Dictionary)["build_cell"] = [cell.x, cell.y]

	if not Grid.in_bounds(cell) or id == &"":
		_view.hide_ghost()
		_reason.text = ""
		return

	var reason := Building.why_not(_state, id, cell)
	_view.show_ghost(cell, id, reason.is_empty())
	_reason.text = Names.refusal(reason)

	# **What the zombies would do about it.** Only for a thing that actually
	# blocks the way, and only where it could go: previewing a route around a
	# tower the player cannot afford is answering a question nobody asked.
	if reason.is_empty() and _blocks_the_way(id):
		_view.show_route(Pathing.route_if_blocked(_state, cell,
			_a_way_in(), ROUTE_STEPS))
	else:
		_view.clear_route()


## Whether the guardian's cursor is up - from the build step to the morning.
func _by_cursor() -> bool:
	return _view != null and _view.cursor() != null and _view.cursor().is_active()


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

	# **An armed flare is put away before anything else** (task 0135).
	if _by_cursor() and _view.cursor().cancel_aim(event):
		get_viewport().set_input_as_handled()
		return

	# **Escape leaves build mode first.** Escape opens the pause menu when it
	# has nothing else to stop (`Main.escape_is_free`), and a player holding a
	# wall over the farm who presses it means "put that down", not "pause".
	if Building.is_active(_state) and event.is_action_pressed(&"cancel"):
		Building.set_active(_state, false)
		get_viewport().set_input_as_handled()
		return

	if not visible:
		return

	# **Three named actions, not three mouse buttons.** They still ship as
	# left, right and middle - that is what `project.godot` binds them to -
	# but since task 0095 a player can move them, and a mouse button is a
	# binding like any other rather than a special case.
	var intent: Dictionary = _state["intent"]
	# **An armed flare, then something to mend, take the confirm first**
	# (tasks 0135, 0134), whatever is in hand: the cursor's look says which.
	if _by_cursor() and (_view.cursor().confirm_flare(_state, event)
			or _view.cursor().confirm_repair(_state, event)):
		get_viewport().set_input_as_handled()
		return
	# **At night `interact` confirms at the cursor too** (task 0133): A on a
	# pad, where `place` gave its trigger up to the flare and the hotbar took
	# the bumpers. The farmer is in bed, so the key has nothing else to do.
	if event.is_action_pressed(&"place") \
			or (_by_cursor() and event.is_action_pressed(&"interact")):
		_held_cell = _hovered
		intent["build_place"] = true
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"remove"):
		# **Right click sells**, and only in build mode: a stray right click
		# while farming should not take a tower down.
		intent["build_sell"] = true
	elif event.is_action_pressed(&"upgrade"):
		# **Middle click upgrades**, so the three things you can do to a cell
		# in build mode are three buttons rather than three modes.
		intent["build_upgrade"] = true
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
		# One line, and the tooltip does the rest. The catalogue holds
		# both sorts, so which table it came out of decides the key.
		Tooltip.describes(row, StringName("%s:%s"
			% ["defence" if GameData.DEFENCES.has(id) else "building", id]))
		row.custom_minimum_size = Vector2(114, ROW_HEIGHT)
		# **A list row**, which the theme keeps short. A default `Button`
		# reserves about twenty pixels whatever `ROW_HEIGHT` says, and twelve
		# of those is 327 pixels of palette on a 270 pixel screen - which is
		# what happened when task 0032 made the four buildings placeable: the
		# press row landed at y=294 and could not be clicked at all. There is
		# an assert in input_check that the whole palette is on screen.
		row.theme_type_variation = UiKit.ROW
		row.text = "%s  %s" % [id, _price_of(id)]
		row.toggle_mode = true
		row.button_pressed = id == Building.selected(_state)
		# **Shown rather than hidden** when it cannot be paid for. The ghost
		# and the reason line explain it the moment the cursor moves.
		row.modulate = Color.WHITE if Building.affordable(_state, id) \
			else FADED
		row.pressed.connect(func() -> void: Building.select(_state, id))
		_rows.add_child(row)


func _price_of(id: StringName) -> String:
	var banked := Crafting.kits(_state, id)
	if banked > 0:
		return I18n.f(&"BUILD_BANKED", [banked])
	var parts: Array = []
	var cost := Building.cost_of(id)
	# **Through `sorted_names`, not `Array.sort()`.** These keys are resource
	# names, and `sort()` orders StringNames by their interned pointer - so
	# the price of a fence read "5 wood 3 iron" on one run and "3 iron 5
	# wood" on the next. See `result_screen._sorted`, where the same mistake
	# was caught by comparing two screenshots byte for byte.
	for res in GameData.sorted_names(cost.keys()):
		parts.append("%d%s" % [cost[res], str(res).substr(0, 1)])
	return " ".join(parts)
