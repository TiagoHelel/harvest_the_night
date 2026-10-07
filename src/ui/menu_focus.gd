class_name MenuFocus
extends RefCounted

## One selection behind the keyboard, the mouse and a pad, for a column of
## buttons - the way WELCOME BACK, HERO's menus work.
##
##     MenuFocus.wire(_menu.get_children())
##     MenuFocus.select_first(_menu.get_children())
##
## **Pointing at an entry selects it.** A column where the mouse lit one button
## while the keyboard's focus sat on another showed two answers to "which one
## will Enter take?". Here hovering moves the focus, so there is only ever one
## selected entry, and it wears the caret: a small gold pointer in the margin to
## the left of it, on top of the theme's gold focus ring.
##
## **Up and down wrap**, top to bottom and back, the same as that game's lists,
## and pass over an entry that is switched off rather than stopping on it.
##
## **It is heard as well as seen.** Moving the selection, taking an entry and
## backing out each have their own short, quiet sound from `tools/gen_sfx.py`.
##
## A column that is built again - a language change, a question coming and
## going - is wired again, which is safe: nothing is connected twice. Nothing
## here decides what an entry does; the screen that owns the buttons still
## connects `pressed` itself.

## The three sounds, as `Audio` knows them.
const MOVE := &"sfx/ui_move"
const CONFIRM := &"sfx/ui_confirm"
const BACK := &"sfx/ui_back"

## The caret: how far into the left margin it sits, and its size.
const CARET_GAP := 2
const CARET_SIZE := Vector2i(3, 5)

## Set on a button once it is wired, so wiring a column twice connects nothing
## twice.
const WIRED := &"menu_focus_wired"


## Wire a column of buttons. Anything in `nodes` that is not a visible Button
## is left alone, so a container's children can be passed straight in.
static func wire(nodes: Array, wrap: bool = true) -> void:
	var live: Array = []
	for node in nodes:
		var button := node as Button
		if button == null or not button.visible:
			continue
		if not button.has_meta(WIRED):
			button.set_meta(WIRED, true)
			button.mouse_entered.connect(_point.bind(button))
			button.focus_entered.connect(_selected.bind(button))
			button.focus_exited.connect(_left.bind(button))
			button.pressed.connect(_taken.bind(button))
		# **A switched-off entry is passed over**, by the keys and the pointer
		# both - it is still on the list, so the player can read what it is.
		button.focus_mode = Control.FOCUS_NONE if button.disabled \
			else Control.FOCUS_ALL
		if not button.disabled:
			live.append(button)
	for i in live.size():
		var button: Button = live[i]
		var above: Button = live[i - 1] if i > 0 \
			else (live[live.size() - 1] if wrap else button)
		var below: Button = live[i + 1] if i < live.size() - 1 \
			else (live[0] if wrap else button)
		button.focus_neighbor_top = button.get_path_to(above)
		button.focus_neighbor_bottom = button.get_path_to(below)
		button.focus_previous = button.focus_neighbor_top
		button.focus_next = button.focus_neighbor_bottom


## Put the selection on the first entry that can take it.
static func select_first(nodes: Array) -> void:
	for node in nodes:
		var button := node as Button
		if button != null and button.visible and not button.disabled:
			button.grab_focus()
			return


## The tick of a value changing under the keys or the pointer - a row of the
## options screen stepping - which is the same small sound as the caret moving.
static func changed(from: Node) -> void:
	_play(from, MOVE)


## The sound of backing out, for whoever handles `cancel`.
static func backed_out(from: Node) -> void:
	_play(from, BACK)


## Which entry wears the caret, or null. For the checks.
static func caret_on(nodes: Array) -> Button:
	for node in nodes:
		var button := node as Button
		if button != null:
			var caret := button.get_node_or_null(^"Caret") as Control
			if caret != null and caret.visible:
				return button
	return null


# ----------------------------------------------------------------- privately

static func _point(button: Button) -> void:
	if button.disabled or not button.is_visible_in_tree():
		return
	if not button.has_focus():
		button.grab_focus()


static func _selected(button: Button) -> void:
	var caret := _caret_for(button)
	var was := caret.get_parent()
	if was != button:
		if was != null:
			was.remove_child(caret)
			_play(button, MOVE)
		button.add_child(caret)
	caret.position = Vector2(-CARET_GAP - CARET_SIZE.x,
		floorf((button.size.y - CARET_SIZE.y) * 0.5))
	# A row that draws its own pointer - an options row, inside a page that
	# scrolls - keeps this one hidden; the sounds are the same either way.
	caret.visible = not button.has_method(&"draws_own_caret")


## **The caret is where the focus is, and nowhere else.** A screen with two
## columns - a page of rows and a Back button under it - would otherwise keep
## a caret on the row the selection just left.
static func _left(button: Button) -> void:
	var caret := button.get_node_or_null(^"Caret") as Control
	if caret != null:
		caret.visible = false


static func _taken(button: Button) -> void:
	_play(button, CONFIRM)


## One caret per column: whichever button has it now, or a new one.
static func _caret_for(button: Button) -> Control:
	var column := button.get_parent()
	if column != null:
		for sibling in column.get_children():
			var held := sibling.get_node_or_null(^"Caret") as Control
			if held != null:
				return held
	var caret := Caret.new()
	caret.name = "Caret"
	caret.size = Vector2(CARET_SIZE)
	caret.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return caret


static func _play(from: Node, id: StringName) -> void:
	if from == null or not from.is_inside_tree():
		return
	var audio := from.get_node_or_null(^"/root/Audio")
	if audio != null:
		audio.play(id)


## The pointer itself: three pixels wide and five tall, in the warm gold the
## theme lights a selection with.
class Caret:
	extends Control

	func _draw() -> void:
		var gold := UiKit.colour(UiKit.WARM)
		draw_rect(Rect2(0, 0, 1, 5), gold)
		draw_rect(Rect2(1, 1, 1, 3), gold)
		draw_rect(Rect2(2, 2, 1, 1), gold)
