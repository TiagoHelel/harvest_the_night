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
	add_child(_frame)

	var column := VBoxContainer.new()
	column.name = "WorkshopColumn"
	_frame.add_child(column)

	_title = _line("WorkshopTitle", "", UiKit.WARM)
	column.add_child(_title)

	_progress = _line("WorkshopProgress", "", UiKit.GOOD)
	column.add_child(_progress)

	_away = _line("WorkshopAway", "", UiKit.WARM)
	_away.visible = false
	column.add_child(_away)

	_queue = VBoxContainer.new()
	_queue.name = "WorkshopQueue"
	column.add_child(_queue)

	column.add_child(_line("WorkshopMakeLabel", I18n.t(&"WORK_MAKE"),
		UiKit.WARM))
	_recipes = VBoxContainer.new()
	_recipes.name = "WorkshopRecipes"
	column.add_child(_recipes)


func show_state(state: Dictionary) -> void:
	_state = state


## The station the farmer is at, or off the farm when they are not at one.
func station_cell() -> Vector2i:
	if _state.is_empty() or int(_state["phase"]) != Phases.DAY or House.inside(_state):
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
		_progress.text = I18n.t(&"WORK_STALLED")
		_progress.theme_type_variation = UiKit.WARN
	elif int(progress[1]) > 0:
		_progress.text = I18n.f(&"WORK_MAKING",
			[Names.of(Crafting.making(_state, cell)),
			float(progress[0]) / float(GameData.TICK_HZ)])
		_progress.theme_type_variation = UiKit.GOOD
	else:
		_progress.text = I18n.t(&"WORK_IDLE")
		_progress.theme_type_variation = UiKit.DIM


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
			parts.append(I18n.f(&"WORK_AWAY_ONE", [since, Names.of(id)]))
	if parts.is_empty():
		return ""
	return I18n.f(&"WORK_AWAY", [", ".join(parts)])


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
		row.text = I18n.f(&"WORK_QUEUED_RUNNING" if slot == 0
			else &"WORK_QUEUED", [slot + 1, Names.of(lined_up[slot])])
		_style(row)
		row.pressed.connect(func() -> void:
			Crafting.cancel_at(_state, cell, slot))
		_queue.add_child(row)

	var room := Crafting.room_at(_state, cell)
	if room > 0:
		_queue.add_child(_line("WorkshopRoom",
			I18n.plural(&"WORK_ROOM", room, [room]), UiKit.DIM))

	# What it can make. Clicking one puts it on the end.
	for id in Crafting.recipes_at(station):
		var recipe_id: StringName = id
		var row := Button.new()
		row.name = "make_%s" % recipe_id
		Tooltip.describes(row, StringName("recipe:%s" % recipe_id))
		row.text = str(recipe_id)
		_style(row)
		row.modulate = Color(1, 1, 1) if Crafting.can_queue(_state, cell,
			recipe_id) else Color(0.5, 0.48, 0.55)
		row.pressed.connect(func() -> void:
			Crafting.enqueue(_state, cell, recipe_id))
		_recipes.add_child(row)


## The compact row the build palette settled on in task 0032, which is now
## the theme's `ROW`: a default `Button` reserves twenty pixels of height and
## this screen is 270 tall.
func _style(row: Button) -> void:
	row.custom_minimum_size = Vector2(130, ROW_HEIGHT)
	row.theme_type_variation = UiKit.ROW


func _line(node_name: String, text: String,
		role: StringName = &"") -> Label:
	var label := Label.new()
	label.name = node_name
	label.text = text
	label.custom_minimum_size = Vector2(130, ROW_HEIGHT)
	label.theme_type_variation = role
	return label
