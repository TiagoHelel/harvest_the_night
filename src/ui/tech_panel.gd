class_name TechPanel
extends Control

## The tech tree, on one screen.
##
## `design.md` section 12 wants somewhere to spend technology and is explicit
## that the MVP does not get a giant tree. Twelve nodes in three branches of
## four, drawn as three columns, so the whole thing is visible at once and a
## player can see what they are giving up as well as what they are taking.
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


## A node's button. Four across, three down, and the whole tree on one screen.
const NODE_SIZE := Vector2(148, 30)

var _state: Dictionary = {}
var _frame: Control
var _held: Label
var _reason: Label
var _note: Label
var _buttons: Dictionary = {}       # id -> Button
var _drawn_for := -1


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

	var heading := _label("TechHeading", Vector2(8, 4), UiKit.WARM)
	heading.text = "TECHNOLOGY"
	_held = _label("TechHeld", Vector2(120, 4), UiKit.WARM)
	_reason = _label("TechReason", Vector2(8, 186), UiKit.DIM)
	# **What the node under the cursor does**, on its own line where there is
	# room for a sentence. The buttons are too narrow for one.
	_note = _label("TechNote", Vector2(8, 172), UiKit.WARM)

	var hint := _label("TechHint", Vector2(300, 4), UiKit.DIM)
	hint.text = "T or ESC to close"

	_build_nodes()


func _build_nodes() -> void:
	var branches := Tech.branches()
	for column in branches.size():
		var branch: StringName = branches[column]
		var at := Vector2(6 + column * 152.0, 22.0)
		var title := _label("TechBranch_" + str(branch), at, UiKit.WARM)
		title.text = str(branch).to_upper()
		var row := 0
		for entry in Tech.nodes_of(branch):
			var one: Dictionary = entry
			var id: StringName = one["id"]
			var button := Button.new()
			button.name = "Tech_" + str(id).replace(" ", "_")
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
			_buttons[id] = button
			row += 1


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
	_drawn_for = -1


func close() -> void:
	visible = false


func _process(_delta: float) -> void:
	if _state.is_empty():
		return
	# **Never during a wave.** The rules refuse a purchase after dark anyway;
	# this is so the panel is not sitting open over a night it cannot act on.
	if visible and int(_state["phase"]) != Phases.DAY:
		close()
		return
	if Input.is_action_just_pressed(&"tech"):
		close() if visible else open()
	if visible and Input.is_action_just_pressed(&"cancel"):
		close()
	if not visible:
		return

	# Redrawn when something changed, not every frame: twelve buttons of text
	# rebuilt sixty times a second is sixty times the work for one picture.
	var signature := Tech.held(_state) * 100 + Tech.owned(_state).size()
	if signature != _drawn_for:
		_drawn_for = signature
		_refresh()
	_show_the_note()


## The note of whichever node the cursor is over, or nothing.
func _show_the_note() -> void:
	for id in _buttons:
		var button: Button = _buttons[id]
		if button.get_global_rect().has_point(get_global_mouse_position()):
			_note.text = "%s - %s" % [str(id),
				str(Tech.node(StringName(id))["note"])]
			return
	_note.text = ""


func _refresh() -> void:
	_held.text = "%d points" % Tech.held(_state)
	var spent := 0
	for id in Tech.owned(_state):
		spent += int(Tech.node(StringName(id))["cost"])
	_reason.text = ("%d of %d nodes, %d points spent - the ten nights pay "
		+ "%d at best and the whole tree costs %d") % [
			Tech.owned(_state).size(), Tech.tree().size(), spent,
			Tech.total_available(), _whole_tree()]

	for id in _buttons:
		var one := Tech.node(StringName(id))
		var button: Button = _buttons[id]
		var mine := Tech.owns(_state, StringName(id))
		var refused := Tech.why_not_buy(_state, StringName(id))
		button.text = "%s   %d" % [str(id), int(one["cost"])]
		button.disabled = mine or not refused.is_empty()
		button.tooltip_text = str(one["note"]) if mine or refused.is_empty() \
			else "%s - %s" % [str(one["note"]), refused]
		# **Disabled says it once.** A locked node is already `disabled`, so
		# the theme is drawing it in the dull frame with faint letters; the
		# `modulate` that used to be here multiplied that by a dim colour
		# again and made an unlit button almost invisible. Owned is the same
		# disabled button with green letters, which is the only difference
		# that needs saying.
		button.theme_type_variation = UiKit.OWNED if mine else &""


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
