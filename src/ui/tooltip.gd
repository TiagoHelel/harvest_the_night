class_name Tooltip
extends Control

## The panel that explains whatever the player is pointing at or has tabbed to.
##
## **One node, and no panel has any describing code in it.** A control that
## wants explaining carries `set_meta(&"describes", &"defence:gun_tower")`;
## this polls what is hovered and what has focus, resolves the key through
## `Describe`, and puts the words on the screen.
##
## ## Why not Godot's own tooltips
##
## `Control.tooltip_text` very nearly does this, and task 0081 already themed
## `TooltipPanel` and `TooltipLabel` for it. Two of task 0089's requirements
## are the ones it cannot meet:
##
## - **No delay moving to the next thing.** Godot waits its full delay again
##   for every control, so reading a row of five structures costs two and a
##   half seconds of waiting. A tooltip that is already up should follow the
##   cursor immediately; the delay is there to stop it flashing at somebody
##   crossing the screen, and once it is up that has already been decided.
## - **Keyboard focus shows the same tooltip.** Godot's appears for the mouse
##   and nothing else, so a player on a keyboard or a pad is told nothing.
##
## ## It never leaves the screen
##
## Clamped against the viewport on both axes, and flipped above the cursor
## rather than squashed when there is no room below. `input_check` walks every
## corner of a 480x270 screen and asserts the whole panel is inside it.

## How long the cursor has to rest on something before it is explained.
##
## Half a second: long enough not to flash at somebody crossing the screen on
## their way to a button, short enough that anybody who wanted it has not
## given up. Godot's own default, which is a reasonable thing to agree with.
const DELAY := 0.5

## How far from the cursor it sits, and how far from the screen edge it stops.
const CURSOR_GAP := Vector2(10.0, 12.0)
const EDGE := 3.0

## The meta a control carries to say what it is.
const META := &"describes"

## **The night's free band** (task 0131), where the cursor's tooltip may go:
## below the night HUD's 24 pixel strip and above the lines and buttons along
## the bottom, which start at 240. A tooltip over the house bar or the
## REPAIR button would hide the thing the player is about to read or press.
const WORLD_AREA := Rect2(3.0, 26.0, 474.0, 212.0)

var _key := &""
var _showing := &""
## What is under the guardian's cursor, and where its cell is on screen. Set
## every frame by `Main` while there is a cursor; a control under the pointer
## or with the focus still wins.
var _world_text := ""
var _world_at := Vector2.ZERO
var _waited := 0.0
var _panel: PanelContainer
var _label: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)

	_panel = PanelContainer.new()
	_panel.name = "TooltipPanel"
	_panel.theme_type_variation = UiKit.OVERLAY
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.visible = false
	add_child(_panel)

	_label = Label.new()
	_label.name = "TooltipText"
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_label)


func _process(delta: float) -> void:
	var wanted := _what_is_pointed_at()
	if wanted == &"" and not _world_text.is_empty():
		wanted = StringName("world:" + _world_text)
	if wanted != _key:
		_key = wanted
		# **The delay only applies to the first one.** Once a tooltip is up,
		# moving to the next thing swaps it at once: the decision that this
		# player wants to be told things has already been made.
		_waited = 0.0 if _showing != &"" else DELAY
	if _key == &"":
		_hide()
		return
	if _waited > 0.0:
		_waited = maxf(_waited - delta, 0.0)
		if _waited > 0.0:
			return
	_show(_key)


## What the player is pointing at, or has tabbed to.
##
## **Focus wins over hover**, because a player who is using the keyboard is
## not using the mouse, and a cursor left lying over something while they tab
## through a tech tree would describe the wrong node for the rest of the
## night.
func _what_is_pointed_at() -> StringName:
	var port := get_viewport()
	if port == null:
		return &""
	var focused := port.gui_get_focus_owner()
	var key := _key_of(focused)
	if key != &"":
		return key
	return _key_of(port.gui_get_hovered_control())


## The key a control carries, or the nearest one above it.
##
## Walking up matters: a row is an `HBoxContainer` of three labels and the
## player is pointing at one of them, not at the row. Marking the row once is
## the whole of what a panel has to do.
func _key_of(from: Node) -> StringName:
	var at := from
	while at != null:
		if at.has_meta(META):
			return StringName(at.get_meta(META))
		at = at.get_parent()
	return &""


func _show(key: StringName) -> void:
	var world := String(key).begins_with("world:")
	var text := _world_text if world else Describe.of(key)
	if text.is_empty():
		_hide()
		return
	if key != _showing:
		_showing = key
		_label.text = text
		# **Back to the new text's size.** A container grows to its content
		# and never shrinks by itself, so "open ground" after a long refusal
		# sat in the refusal's box (found in task 0136's pictures).
		_panel.reset_size()
	_panel.visible = true
	if world:
		# Beside the cell, inside the night's free band.
		_panel.position = place_within(_world_at,
			_panel.get_combined_minimum_size(), WORLD_AREA)
		return
	_panel.position = _place(_panel.get_combined_minimum_size())


## What the guardian's cursor is over (task 0131): `text` from
## `Describe.under_cursor`, `at` the cell's place on screen. Empty clears it.
func show_world(text: String, at: Vector2) -> void:
	_world_text = text
	_world_at = at


## Like `place_at`, inside an area rather than the whole screen.
static func place_within(cursor: Vector2, panel: Vector2, area: Rect2) -> Vector2:
	var at := place_at(cursor - area.position, panel, area.size)
	return (at + area.position).round()


## Where the panel goes: beside the cursor, and never off the screen.
##
## Static and given everything it needs, so `headless_check` can walk it round
## every corner without building a game.
static func place_at(cursor: Vector2, panel: Vector2,
		screen: Vector2) -> Vector2:
	var at := cursor + CURSOR_GAP
	# **Flipped, not squashed.** With no room below, it goes above the
	# cursor - which keeps it off the thing being described either way.
	if at.y + panel.y > screen.y - EDGE:
		at.y = cursor.y - panel.y - CURSOR_GAP.y
	if at.x + panel.x > screen.x - EDGE:
		at.x = cursor.x - panel.x - CURSOR_GAP.x
	at.x = clampf(at.x, EDGE, maxf(screen.x - panel.x - EDGE, EDGE))
	at.y = clampf(at.y, EDGE, maxf(screen.y - panel.y - EDGE, EDGE))
	return at.round()


func _place(panel: Vector2) -> Vector2:
	var port := get_viewport()
	var cursor := port.get_mouse_position() if port != null else Vector2.ZERO
	var focused := port.gui_get_focus_owner() if port != null else null
	if focused != null and _key_of(focused) == _key:
		# A keyboard has no cursor, so the panel sits under the control the
		# player has actually landed on.
		cursor = focused.get_global_rect().position \
			+ Vector2(0.0, focused.size.y)
	var screen := Vector2(get_viewport_rect().size)
	return place_at(cursor, panel, screen)


func _hide() -> void:
	_showing = &""
	_panel.visible = false


# ------------------------------------------------------------- for the checks

func showing() -> StringName:
	return _showing


func text_showing() -> String:
	return _label.text if _panel.visible else ""


func panel_rect() -> Rect2:
	return Rect2(_panel.position, _panel.size)


## Put a key on a control, and on nothing else. One line where a panel builds
## a row, which is all the wiring any of this needs.
static func describes(control: Control, key: StringName) -> void:
	control.set_meta(META, key)
