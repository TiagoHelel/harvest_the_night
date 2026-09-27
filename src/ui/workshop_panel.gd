class_name WorkshopPanel
extends Control

## What a station is making, and what it is making next.
##
## Appears when the farmer is standing at a workshop, a press or a kitchen, and
## goes away when they walk off. There is no key for it: **the panel is what
## being at the bench looks like**, and a key would be one more thing to
## remember for information the player has already walked over to get.
##
## ## It shows the queue, and the queue is the feature
##
## `design.md` section 13 is semi-idle: do a thing, go away, come back to
## something better. A queue you cannot see is a queue you do not trust, so the
## front item gets a countdown and a bar and everything behind it gets a line.
##
## ## What happened while you were elsewhere
##
## `design.md` section 13 promises you come back to something better. A bench
## that had silently gone from three queued to three kits in the pile would be
## the same event with none of the telling, so the panel keeps the tally it
## last showed for each bench and reports the difference when the farmer walks
## back up: "while you were away: 3 barricade_kit".
##
## **That memory is the panel's, not the game's.** `Crafting.made_at()` is the
## running total and lives in the state; what *this viewer* has already been
## told is a fact about this screen, and putting it in the state would be a
## second player's panel telling the first player's lies.
##
## ## Nothing here is a rule
##
## The rows come from `Crafting.queue_at()` and the countdown from
## `Crafting.progress_at()`. Clicking a recipe calls `Crafting.enqueue()` and
## clicking a queued item calls `Crafting.cancel_at()`; both of those refuse on
## their own terms and this file does not second-guess them.

const HEADING := Color(0.96, 0.85, 0.55)
const DIM := Color(0.66, 0.64, 0.74)
const SHORT := Color(0.96, 0.55, 0.36)
const RUNNING := Color(0.75, 0.92, 0.62)
const ROW_HEIGHT := 11

var _state: Dictionary = {}
var _frame: PanelContainer
var _title: Label
var _recipes: VBoxContainer
var _queue: VBoxContainer
var _progress: Label
var _built_for := ""
## {station cell index: the tally this panel last showed for it}
var _last_seen: Dictionary = {}
var _away: Label


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)

	_frame = PanelContainer.new()
	_frame.name = "WorkshopFrame"
	_frame.position = Vector2(336, 32)
	_frame.custom_minimum_size = Vector2(140, 0)
	_frame.mouse_filter = Control.MOUSE_FILTER_STOP
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.07, 0.06, 0.12, 0.96)
	box.border_color = Color(0.52, 0.46, 0.34)
	box.set_border_width_all(1)
	box.set_content_margin_all(5)
	_frame.add_theme_stylebox_override("panel", box)
	add_child(_frame)

	var column := VBoxContainer.new()
	column.name = "WorkshopColumn"
	column.add_theme_constant_override("separation", 0)
	_frame.add_child(column)

	_title = _line("WorkshopTitle", "", HEADING)
	column.add_child(_title)

	_progress = _line("WorkshopProgress", "", RUNNING)
	column.add_child(_progress)

	_away = _line("WorkshopAway", "", HEADING)
	_away.visible = false
	column.add_child(_away)

	_queue = VBoxContainer.new()
	_queue.name = "WorkshopQueue"
	_queue.add_theme_constant_override("separation", 0)
	column.add_child(_queue)

	column.add_child(_line("WorkshopMakeLabel", "- MAKE", HEADING))
	_recipes = VBoxContainer.new()
	_recipes.name = "WorkshopRecipes"
	_recipes.add_theme_constant_override("separation", 0)
	column.add_child(_recipes)


func show_state(state: Dictionary) -> void:
	_state = state


## The station the farmer is at, or off the farm when they are not at one.
func station_cell() -> Vector2i:
	if _state.is_empty() or int(_state["phase"]) != Phases.DAY:
		return Vector2i(-1, -1)
	var at := Player.target(_state)
	var on := Farm.occupant(_state, at)
	if on.is_empty() or not Crafting.is_station(on["id"]):
		return Vector2i(-1, -1)
	return Building.anchor_of(_state, at)


func is_open() -> bool:
	return visible


func _process(_delta: float) -> void:
	if _state.is_empty():
		return
	var cell := station_cell()
	visible = cell != Vector2i(-1, -1)
	if not visible:
		_built_for = ""
		return

	# **What arrived since this panel last had its eyes on this bench.**
	# Worked out on arrival and then held, so it does not flicker away while
	# the player is reading it; the tally is banked when they walk off.
	if _built_for == "":
		_away.text = _what_happened(cell)
		_away.visible = _away.text != ""

	var signature := _signature(cell)
	if signature != _built_for:
		_built_for = signature
		_build(cell)

	# **The countdown is every frame**, not every rebuild: a number that only
	# moved when the queue changed would be a timer that stood still.
	var progress := Crafting.progress_at(_state, cell)
	if Crafting.is_stalled(_state, cell):
		_progress.text = "waiting on materials"
		_progress.modulate = SHORT
	elif int(progress[1]) > 0:
		_progress.text = "%s  %.1fs" % [Crafting.making(_state, cell),
			float(progress[0]) / float(GameData.TICK_HZ)]
		_progress.modulate = RUNNING
	else:
		_progress.text = "idle"
		_progress.modulate = DIM


## The difference between what this bench has made and what this panel last
## told the player about it, in words. Empty when nothing has changed.
func _what_happened(cell: Vector2i) -> String:
	var made := Crafting.made_at(_state, cell)
	var idx := Grid.index(cell)
	# **Whether we have looked, not what we saw.** Testing the remembered tally
	# for emptiness conflated "never been here" with "been here, and it had
	# made nothing yet" - which is every first visit to a bench, so the line
	# never appeared at all.
	var first_look := not _last_seen.has(idx)
	var seen: Dictionary = _last_seen.get(idx, {})
	_last_seen[idx] = made.duplicate()
	if first_look:
		return ""               # no "while you were away" before you were here

	var parts: Array = []
	for id in GameData.sorted_names(made.keys()):
		var since := int(made[id]) - int(seen.get(id, 0))
		if since > 0:
			parts.append("%d %s" % [since, id])
	if parts.is_empty():
		return ""
	return "while you were away:  " + ", ".join(parts)


func _signature(cell: Vector2i) -> String:
	var parts: Array = [str(cell)]
	for id in Crafting.queue_at(_state, cell):
		parts.append(str(id))
	parts.append("stalled" if Crafting.is_stalled(_state, cell) else "running")
	return "|".join(parts)


func _build(cell: Vector2i) -> void:
	var station: StringName = Farm.occupant(_state, cell)["id"]
	_title.text = str(station).to_upper()

	for holder in [_queue, _recipes]:
		for child in (holder as VBoxContainer).get_children():
			(holder as VBoxContainer).remove_child(child)
			child.queue_free()

	# What is lined up, front first. Clicking one takes it out.
	var lined_up := Crafting.queue_at(_state, cell)
	for i in lined_up.size():
		var slot := i
		var row := Button.new()
		row.name = "queued_%d" % slot
		row.text = "%d. %s%s" % [slot + 1, lined_up[slot],
			"  (running)" if slot == 0 else ""]
		_style(row)
		row.pressed.connect(func() -> void:
			Crafting.cancel_at(_state, cell, slot))
		_queue.add_child(row)

	var room := Crafting.room_at(_state, cell)
	if room > 0:
		_queue.add_child(_line("WorkshopRoom", "  %d slot%s free"
			% [room, "" if room == 1 else "s"], DIM))

	# What it can make. Clicking one puts it on the end.
	for id in Crafting.recipes_at(station):
		var recipe_id: StringName = id
		var row := Button.new()
		row.name = "make_%s" % recipe_id
		row.text = str(recipe_id)
		_style(row)
		row.modulate = Color(1, 1, 1) if Crafting.can_queue(_state, cell,
			recipe_id) else Color(0.5, 0.48, 0.55)
		row.pressed.connect(func() -> void:
			Crafting.enqueue(_state, cell, recipe_id))
		_recipes.add_child(row)


## The compact button style the build palette settled on in task 0032: the
## theme's default reserves twenty pixels and this screen is 270 tall.
func _style(row: Button) -> void:
	row.custom_minimum_size = Vector2(130, ROW_HEIGHT)
	row.add_theme_font_size_override("font_size", 8)
	for style in ["normal", "hover", "pressed", "focus", "disabled"]:
		var box := StyleBoxFlat.new()
		box.bg_color = Color(0.12, 0.11, 0.18, 0.0 if style == "focus" else 0.8)
		if style == "hover":
			box.bg_color = Color(0.20, 0.19, 0.28, 0.9)
		box.content_margin_left = 3
		box.content_margin_right = 3
		box.content_margin_top = 1
		box.content_margin_bottom = 1
		row.add_theme_stylebox_override(style, box)


func _line(node_name: String, text: String, colour: Color) -> Label:
	var label := Label.new()
	label.name = node_name
	label.text = text
	label.custom_minimum_size = Vector2(130, ROW_HEIGHT)
	label.add_theme_font_size_override("font_size", 8)
	label.modulate = colour
	return label
