class_name TechPanel
extends Control

## The tech tree, a floor a page.
##
## `design.md` section 12 wants somewhere to spend technology and is explicit
## that the MVP does not get a giant tree. Twelve nodes in three branches of
## four, drawn as three columns, so the whole thing is visible at once and a
## player can see what they are giving up as well as what they are taking.
##
## **A page a season since task 0220.** Spring's floor is those twelve; summer,
## autumn and winter add a row each. The panel opens on today's season and
## turns a page with Q and E - LB and RB on a pad, the arrows by mouse - the
## inventory's own page keys. A season the run has not reached is drawn
## greyed, with the reason under it.
##
## **It reads `Tech` and nothing else.** Which nodes exist, what they cost,
## what they need and whether one can be bought today are all questions with
## answers in `src/core/`; this file asks them and draws the replies. A
## thirteenth node is a row in `GameData.TECH_TREE` and nothing here changes.
##
## ## A sibling after the day HUD
##
## For the reason task 0056 wrote down: `DayHud` is the first child of
## `Screen` and `MOUSE_FILTER_IGNORE` across the whole of it, and a button in
## that corner is not hit-testable. Panels that are clicked go after it.


## A node's button. Three across, four down, and a floor on one screen.
const NODE_SIZE := Vector2(148, 30)

var _state: Dictionary = {}
var _frame: Control
var _held: Label
var _reason: Label
var _note: Label
var _buttons: Dictionary = {}       # id -> Button
var _drawn_for := -1
## **The floor on screen** (task 0220): 0 for spring to 3 for winter.
var _page := 0
var _previous: Button
var _next: Button
var _season: Label
var _locked: Label
## The words set once at `_ready` - the title, the branches, the hint -
## written again on every redraw, so a language chosen later reaches them.
var _heading: Label
var _hint: Label
var _branch_titles: Dictionary = {}     # branch -> Label
## **A moon stone for essence** (task 0221), bottom right: the one door
## to `Tech.trade_moon_stones`.
var _trade: Button


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)

	# **The kit's frame, the same one the records screen wears.** This was a
	# flat `ColorRect` of its own purple, which made the tech tree the one
	# full-screen panel in the game that was not brass-edged - the "odd one
	# out" task 0081 names, and the reason the screen read as an overlay
	# rather than as a place.
	var backing := Panel.new()
	backing.name = "TechBacking"
	backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backing.position = Vector2(8, 22)
	backing.size = Vector2(464, 222)
	add_child(backing)

	_frame = Control.new()
	_frame.name = "TechFrame"
	_frame.mouse_filter = Control.MOUSE_FILTER_STOP
	_frame.position = Vector2(8, 24)
	_frame.size = Vector2(464, 216)
	add_child(_frame)

	_heading = _label("TechHeading", Vector2(8, 4), UiKit.WARM)
	_heading.text = I18n.t(&"TECH_TITLE")
	var icon := TextureRect.new()
	icon.texture = UiKit.icon(GameData.TECH,true)
	icon.position = Vector2(120,4)
	icon.size = Vector2(10,10)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame.add_child(icon)
	_held = _label("TechHeld", Vector2(132, 4), UiKit.WARM)
	_reason = _label("TechReason", Vector2(8, 186), UiKit.DIM)
	# **What the node under the cursor does**, on its own line where there is
	# room for a sentence. The buttons are too narrow for one.
	_note = _label("TechNote", Vector2(8, 172), UiKit.WARM)

	_hint = _label("TechHint", Vector2(8, 200), UiKit.DIM)
	_hint.text = I18n.t(&"TECH_HINT")

	# **The seasons' pages**, top right: the inventory's page buttons, read
	# off the same bindings, and the season between them.
	_previous = _page_button("TechPrevious", Vector2(286, 2), -1)
	_next = _page_button("TechNext", Vector2(416, 2), 1)
	_season = _label("TechSeason", Vector2(330, 4), UiKit.WARM)
	_season.size = Vector2(84, 11)
	_season.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# Why an unreached floor is greyed: low on the frame, above the note,
	# where the focused node's tooltip - which opens under the row - does
	# not cover it.
	_locked = _label("TechSeasonLocked", Vector2(8, 158), UiKit.DIM)

	# **Moon stones for essence** (task 0221), under the summary and right
	# of the hint. In the focus chain, so the arrows and the D-pad reach it
	# from the nodes above, and Enter or A trades.
	_trade = Button.new()
	_trade.name = "TechTradeStone"
	_trade.theme_type_variation = UiKit.ROW
	_trade.focus_mode = Control.FOCUS_ALL
	_trade.clip_text = true
	_trade.position = Vector2(296, 198)
	_trade.size = Vector2(160, 14)
	_trade.custom_minimum_size = Vector2(160, 14)
	_trade.pressed.connect(_trade_one)
	_frame.add_child(_trade)

	_build_nodes()


func _build_nodes() -> void:
	var branches := Tech.branches()
	for column in branches.size():
		var branch: StringName = branches[column]
		var at := Vector2(6 + column * 152.0, 22.0)
		var title := _label("TechBranch_" + str(branch), at, UiKit.WARM)
		title.text = Names.of(branch)
		_branch_titles[branch] = title
		# **Each floor from the top of the column** (task 0220): a later
		# floor's node sits where spring's first does, one floor shown.
		for season in GameData.SEASONS.size():
			_build_floor(branch, season, at)


func _build_floor(branch: StringName, season: int, at: Vector2) -> void:
	var row := 0
	for entry in Tech.floor_of(branch, season):
		var one: Dictionary = entry
		var id: StringName = one["id"]
		var button := Button.new()
		button.name = "Tech_" + str(id).replace(" ", "_")
		Tooltip.describes(button, StringName("tech:%s" % id))
		button.focus_mode = Control.FOCUS_ALL
		# **Clipped, and the note lives elsewhere.** A `Button` sizes
		# itself to its text whatever `custom_minimum_size` says, so "the
		# flare comes back in a little over half the time" made a button a
		# hundred and ninety-three pixels wide and pushed the third column
		# off a four-hundred-and-eighty pixel screen. The fifth of this
		# family after tasks 0032, 0040, 0055 and 0061, and `input_check`
		# asserts every node is on the screen now.
		button.clip_text = true
		button.autowrap_mode = TextServer.AUTOWRAP_OFF
		_frame.add_child(button)
		button.position = at + Vector2(0, 14 + row * 34.0)
		button.size = NODE_SIZE
		button.custom_minimum_size = NODE_SIZE
		button.pressed.connect(_buy.bind(id))
		button.visible = season == _page
		_buttons[id] = button
		row += 1


## A page button: the inventory's look, never in the focus chain - the
## arrow keys and the D-pad walk the nodes, Q and E turn the page.
func _page_button(node_name: String, at: Vector2, step: int) -> Button:
	var button := Button.new()
	button.name = node_name
	button.theme_type_variation = UiKit.ROW
	button.focus_mode = Control.FOCUS_NONE
	button.position = at
	button.size = Vector2(40, 14)
	button.custom_minimum_size = Vector2(40, 14)
	button.pressed.connect(func() -> void: turn_page(step))
	_frame.add_child(button)
	return button


func _label(node_name: String, at: Vector2,
		role: StringName = &"") -> Label:
	var label := Label.new()
	label.name = node_name
	label.position = at
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.theme_type_variation = role
	_frame.add_child(label) if _frame != null else add_child(label)
	return label


# ---------------------------------------------------------------- the frame

func show_state(state: Dictionary) -> void:
	_state = state


## Whether the tree is up. `input_check` and the day HUD both ask.
func is_open() -> bool:
	return visible


func open() -> void:
	if _state.is_empty() or int(_state["phase"]) != Phases.DAY:
		return
	visible = true
	# Today's floor first: the newest the run can buy from.
	show_page(Calendar.season_of(Calendar.date(_state)))


## **Turn the floor** by `step` seasons, round the year (task 0220).
func turn_page(step: int) -> void:
	show_page(posmod(_page + step, GameData.SEASONS.size()))


## Which floor is on screen, for the checks.
func page() -> int:
	return _page


## A season's floor by its name: the shot tool's `TechPanel:autumn`.
func show_tab(season: StringName) -> void:
	var at := GameData.SEASONS.find(season)
	if at >= 0:
		show_page(at)


## Put a floor on screen, its nodes and nothing else, and the keyboard's
## focus on the first of them it can buy - so a pad pages and buys.
func show_page(season: int) -> void:
	_page = clampi(season, 0, GameData.SEASONS.size() - 1)
	for id in _buttons:
		(_buttons[id] as Button).visible = int(Tech.node(StringName(id)).get("season", 0)) == _page
	_drawn_for = -1
	if not _state.is_empty():
		_refresh()
	if visible:
		_focus_first()


func _focus_first() -> void:
	var first: Button = null
	for row in GameData.TECH_TREE:
		var button: Button = _buttons.get(StringName((row as Dictionary)["id"]), null)
		if button == null or not button.visible:
			continue
		if first == null:
			first = button
		if not button.disabled:
			button.grab_focus()
			return
	if first != null:
		first.grab_focus()


# **Q and E turn the page while the tree is up**, LB and RB on a pad - the
# inventory's own page keys - taken before the hotbar sees them.
func _input(event: InputEvent) -> void:
	if not visible or _state.is_empty():
		return
	if event.is_action_pressed(&"hotbar_prev") or event.is_action_pressed(&"hotbar_next"):
		# Let the shared tracker see the device in hand, as the inventory does.
		var actions := get_tree().root.get_node_or_null("Actions")
		if actions != null:
			actions._input(event)
		turn_page(-1 if event.is_action_pressed(&"hotbar_prev") else 1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"interact"):
		# **A buys the node the pad is on.** Godot's own `ui_accept` is Enter
		# and Space and no pad button at all, so the confirm is read here, as
		# the night HUD reads it - once, for every device - and goes no
		# further.
		var on := get_viewport().gui_get_focus_owner() as Button
		if on != null and (_buttons.values().has(on) or on == _trade):
			if not on.disabled:
				on.pressed.emit()
			get_viewport().set_input_as_handled()


func close() -> void:
	visible = false


func _process(_delta: float) -> void:
	if _state.is_empty():
		return
	# **Never during a wave.** The rules refuse a purchase after dark anyway;
	# this is so the panel is not sitting open over a night it cannot act on.
	if visible and int(_state["phase"]) != Phases.DAY:
		var shut := get_node_or_null(^"/root/App")
		if shut != null:
			shut.back()
		else:
			close()
		return
	# Through the router, for the reason `stats_screen.gd` gives.
	var router := get_node_or_null(^"/root/App")
	if router != null and Input.is_action_just_pressed(&"tech"):
		if visible:
			router.back()
		else:
			router.goto(router.TECH)
	if visible and Input.is_action_just_pressed(&"cancel"):
		close()
	if not visible:
		return

	# Redrawn when something changed, not every frame: twelve buttons of text
	# rebuilt sixty times a second is sixty times the work for one picture.
	var signature := hash([Tech.held(_state), Tech.owned(_state).size(), _page,
		Resources.amount(_state, GameData.MOON_STONE)])
	if signature != _drawn_for:
		_drawn_for = signature
		_refresh()
	_show_the_note()


## The note of whichever node the cursor is over, or nothing.
func _show_the_note() -> void:
	if _trade.get_global_rect().has_point(get_global_mouse_position()):
		_note.text = I18n.f(&"TECH_TRADE_NOTE", [GameData.MOON_STONE_ESSENCE])
		return
	for id in _buttons:
		var button: Button = _buttons[id]
		if button.visible and button.get_global_rect().has_point(get_global_mouse_position()):
			_note.text = I18n.f(&"TECH_NOTE", [Names.of(StringName(id)),
				Names.note_of(StringName(id))])
			return
	_note.text = ""


func _refresh() -> void:
	_held.text = I18n.f(&"TECH_HELD", [Tech.held(_state)])
	var spent := 0
	for id in Tech.owned(_state):
		spent += int(Tech.node(StringName(id))["cost"])
	_reason.text = I18n.f(&"TECH_SUMMARY", [
		Tech.owned(_state).size(), Tech.tree().size(), spent,
		Tech.total_available(), _whole_tree()])

	_heading.text = I18n.t(&"TECH_TITLE")
	_hint.text = I18n.t(&"TECH_HINT")
	for branch in _branch_titles:
		(_branch_titles[branch] as Label).text = Names.of(StringName(branch))

	# **The floor on screen**, and why it is greyed if it is.
	var season := StringName(GameData.SEASONS[_page])
	_season.text = Names.of(season)
	_previous.text = I18n.f(&"INV_PREVIOUS", [_binding(&"hotbar_prev")])
	_next.text = I18n.f(&"INV_NEXT", [_binding(&"hotbar_next")])
	var reached := Calendar.season_reached(_state, _page)
	_season.theme_type_variation = UiKit.WARM if reached else UiKit.DIM
	_locked.visible = not reached
	_locked.text = "" if reached else Names.refusal([&"WHY_NOT_YET_SEASON", season])

	# The trade: how many stones there are to trade, and why not when not.
	var not_now := Tech.why_not_trade(_state)
	_trade.text = I18n.f(&"TECH_TRADE", [Resources.amount(_state, GameData.MOON_STONE)])
	_trade.disabled = not not_now.is_empty()
	var trade_note := I18n.f(&"TECH_TRADE_NOTE", [GameData.MOON_STONE_ESSENCE])
	_trade.tooltip_text = trade_note if not_now.is_empty() \
		else I18n.f(&"TECH_REFUSED", [trade_note, Names.refusal(not_now)])

	for id in _buttons:
		var one := Tech.node(StringName(id))
		var button: Button = _buttons[id]
		var mine := Tech.owns(_state, StringName(id))
		var refused := Tech.why_not_buy(_state, StringName(id))
		button.text = I18n.f(&"TECH_NODE",
			[Names.of(StringName(id)), int(one["cost"])])
		button.disabled = mine or not refused.is_empty()
		var note := Names.note_of(StringName(id))
		# The refusal in words: it was printed as the raw `[key, ...]`.
		button.tooltip_text = note if mine or refused.is_empty() \
			else I18n.f(&"TECH_REFUSED", [note, Names.refusal(refused)])
		# **Disabled says it once.** A locked node is already `disabled`, so
		# the theme is drawing it in the dull frame with faint letters; the
		# `modulate` that used to be here multiplied that by a dim colour
		# again and made an unlit button almost invisible. Owned is the same
		# disabled button with green letters, which is the only difference
		# that needs saying.
		button.theme_type_variation = UiKit.OWNED if mine else &""


func _binding(action: StringName) -> String:
	var actions := get_tree().root.get_node_or_null("Actions")
	return str(actions.text_of(action)) if actions != null else ""


func _whole_tree() -> int:
	var total := 0
	for row in Tech.tree():
		total += int((row as Dictionary)["cost"])
	return total


func _buy(id: StringName) -> void:
	if _state.is_empty():
		return
	# **The rules decide.** The button is a request, the same as a key press.
	Tech.buy(_state, id)
	_drawn_for = -1


## Trade one moon stone for essence: a request, as a node is.
func _trade_one() -> void:
	if _state.is_empty():
		return
	Tech.trade_moon_stones(_state, 1)
	_drawn_for = -1
