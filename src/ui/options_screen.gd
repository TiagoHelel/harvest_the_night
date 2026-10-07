class_name OptionsScreen
extends Control

## The frame the options live in, and the way back out of it.
##
## ## Laid out like WELCOME BACK, HERO's (2026-10-07)
##
## The owner asked for that game's options screen, so it has that game's shape:
## one card over the dimmed screen, a strip of pages along its top, and every
## setting a row - its name on the left, its value on the right - that the
## keys, the pointer and a pad all change the same way (`OptionRow`). Up and
## down walk the rows; left and right change the one with the caret on it;
## Enter takes it. On the strip, left and right turn the page. Escape goes
## back - or first ends whatever the page is in the middle of: a key being
## listened for, a new window size waiting to be kept, a reset half asked.
##
## **What can be set is what it was.** The pages keep the settings, the video
## trial and the key bindings tasks 0093 to 0098 built, and every function the
## checks asked of them; what changed is how they are drawn and walked.
##
## ## A seam, as it always was
##
## `register()` is still the plug: a page that exists is a page on the strip,
## and with none registered the screen is a heading and a way out, and says
## so. It appears in both `Title.tscn` and `Main.tscn`, and neither of them
## knows about the other. `App` is what says when it is up.

## What the strip can hold, in the order the pages belong in.
const TABS: Array = [&"game", &"video", &"audio", &"access", &"controls"]

## What each is called on the strip. Not the page's own name upper-cased:
## "CONTROLS" is "CONTROLES" in Portuguese and an upper-cased `controls` is
## not.
const TAB_NAMES: Dictionary = {
	&"game": &"OPT_TAB_GAME",
	&"access": &"OPT_TAB_ACCESS",
	&"video": &"OPT_TAB_VIDEO",
	&"audio": &"OPT_TAB_AUDIO",
	&"controls": &"OPT_TAB_CONTROLS",
}

## The card, in pixels, and how dark the screen goes behind it.
const CARD := Vector2(392, 238)
const SCRIM_ALPHA := 0.7
const TAB := Vector2(68, 14)

var _tabs: Dictionary = {}
var _open := &""

var _scrim: ColorRect
var _frame: PanelContainer
var _title: Label
var _strip: HBoxContainer
var _room: Control
var _empty: Label
var _hint: Label
var _back: Button


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visibility_changed.connect(_arrive)

	_scrim = ColorRect.new()
	_scrim.name = "OptionsScrim"
	var ink: Color = PaletteData.COLOURS[&"ink"]
	_scrim.color = Color(ink.r, ink.g, ink.b, SCRIM_ALPHA)
	_scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	_scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_scrim)

	var middle := CenterContainer.new()
	middle.name = "OptionsMiddle"
	middle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	middle.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(middle)

	_frame = PanelContainer.new()
	_frame.name = "OptionsFrame"
	_frame.custom_minimum_size = CARD
	_frame.mouse_filter = Control.MOUSE_FILTER_STOP
	middle.add_child(_frame)

	var column := VBoxContainer.new()
	column.name = "OptionsColumn"
	_frame.add_child(column)

	_title = Label.new()
	_title.name = "OptionsTitle"
	_title.theme_type_variation = UiKit.HEADING
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_title)
	column.add_child(_gap(3))

	_strip = HBoxContainer.new()
	_strip.name = "OptionsTabs"
	_strip.theme_type_variation = UiKit.SPACED
	_strip.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(_strip)
	column.add_child(_gap(4))

	_room = Control.new()
	_room.name = "OptionsRoom"
	_room.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_room.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_room)

	_empty = Label.new()
	_empty.name = "OptionsEmpty"
	_empty.theme_type_variation = UiKit.DIM
	_room.add_child(_empty)

	column.add_child(_gap(3))
	var footer := HBoxContainer.new()
	footer.name = "OptionsFooter"
	footer.theme_type_variation = UiKit.SPACED
	column.add_child(footer)
	_hint = Label.new()
	_hint.name = "OptionsHint"
	_hint.theme_type_variation = UiKit.FAINT
	_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	footer.add_child(_hint)
	_back = Button.new()
	_back.name = "OptionsBack"
	_back.custom_minimum_size = Vector2(80, 16)
	_back.focus_mode = Control.FOCUS_ALL
	_back.pressed.connect(_go_back)
	footer.add_child(_back)
	MenuFocus.wire([_back])

	# **The pages register themselves here.** The frame knows the names in
	# `TABS` and nothing about what any of them does.
	for entry in [[&"game", OptionsGame, "OptionsGame"],
			[&"video", OptionsVideo, "OptionsVideo"],
			[&"audio", OptionsAudio, "OptionsAudio"],
			[&"access", OptionsA11y, "OptionsA11y"],
			[&"controls", OptionsControls, "OptionsControls"]]:
		var page: Control = (entry[1] as GDScript).new()
		page.name = entry[2]
		register(entry[0], page)
	relabel()


## Put a page on the strip. The page is added in `TABS` order however late it
## registers, so the strip reads the same whichever is built first.
func register(which: StringName, screen: Control) -> bool:
	if not TABS.has(which):
		push_error("OptionsScreen: '%s' is not one of the tabs" % which)
		return false
	_tabs[which] = screen
	screen.visible = false
	if screen.get_parent() == null:
		_room.add_child(screen)
	_rebuild_strip()
	if _open == &"":
		show_tab(which)
	return true


## Turn to a page.
func show_tab(which: StringName) -> void:
	if not _tabs.has(which):
		return
	var was := _open
	_open = which
	for name in _tabs:
		(_tabs[name] as Control).visible = name == which
	_empty.visible = false
	for tab in _strip.get_children():
		(tab as Button).set_pressed_no_signal(
			String(tab.name) == "OptionsTab_%s" % which)
	if was != which and was != &"":
		var left: OptionsPage = _tabs.get(was) as OptionsPage
		if left != null and left.busy():
			left.cancel()
	_wire()


func open_tab() -> StringName:
	return _open


func tabs() -> Array:
	var out: Array = []
	for which in TABS:
		if _tabs.has(which):
			out.append(which)
	return out


## The pages, for the capture tool.
func tab_names() -> Array:
	return tabs()


## The page that is open.
func page() -> OptionsPage:
	return _tabs.get(_open) as OptionsPage


## Say it all again in whatever language is up now.
func relabel() -> void:
	if _frame == null:
		return
	_title.text = I18n.t(&"OPT_TITLE")
	_back.text = I18n.t(&"OPT_BACK")
	_empty.text = I18n.t(&"OPT_EMPTY")
	var actions := get_node_or_null(^"/root/Actions")
	var back_key: String = actions.text_of(&"cancel") if actions != null else "ESC"
	_hint.text = I18n.f(&"OPT_HINT", [back_key])
	for which in _tabs:
		var page_node := _tabs[which] as Node
		if page_node.has_method(&"relabel"):
			page_node.relabel()
	_rebuild_strip()


# ---------------------------------------------------------------- the strip

func _rebuild_strip() -> void:
	var focused := get_viewport().gui_get_focus_owner() if is_inside_tree() else null
	var had_focus := focused != null and focused.get_parent() == _strip
	for child in _strip.get_children():
		_strip.remove_child(child)
		child.queue_free()
	for which in tabs():
		var tab := Button.new()
		tab.name = "OptionsTab_%s" % which
		tab.text = I18n.t(TAB_NAMES.get(which, &"OPT_TAB_GAME"))
		tab.toggle_mode = true
		tab.button_pressed = which == _open
		tab.theme_type_variation = UiKit.TAB
		tab.custom_minimum_size = TAB
		tab.focus_mode = Control.FOCUS_ALL
		tab.pressed.connect(show_tab.bind(which))
		# **The strip turns the page as the selection moves along it**, the
		# way that game's does: left and right on a tab are left and right
		# through the pages.
		tab.focus_entered.connect(show_tab.bind(which))
		_strip.add_child(tab)
	_empty.visible = _tabs.is_empty()
	_wire()
	if had_focus:
		_focus_strip()


## Join the strip, the page's rows and Back into one walk for the keys: along
## the strip with left and right, down into the rows, down off the last row
## onto Back, and up from the first row back onto the strip.
func _wire() -> void:
	if _strip == null:
		return
	var tabs_now := _strip.get_children()
	var page_now := page()
	var rows: Array = page_now.entries() if page_now != null else []
	MenuFocus.wire(rows, false)
	var active: Button = _strip.get_node_or_null(
		NodePath("OptionsTab_%s" % _open)) as Button
	for i in tabs_now.size():
		var tab := tabs_now[i] as Button
		var left := tabs_now[posmod(i - 1, tabs_now.size())] as Button
		var right := tabs_now[posmod(i + 1, tabs_now.size())] as Button
		tab.focus_neighbor_left = tab.get_path_to(left)
		tab.focus_neighbor_right = tab.get_path_to(right)
		tab.focus_neighbor_top = tab.get_path_to(tab)
		var below: Control = rows[0] if not rows.is_empty() else _back
		tab.focus_neighbor_bottom = tab.get_path_to(below)
	if not rows.is_empty() and active != null:
		var first := rows[0] as Control
		var last := rows[rows.size() - 1] as Control
		first.focus_neighbor_top = first.get_path_to(active)
		last.focus_neighbor_bottom = last.get_path_to(_back)
		_back.focus_neighbor_top = _back.get_path_to(last)
	elif active != null:
		_back.focus_neighbor_top = _back.get_path_to(active)
	_back.focus_neighbor_bottom = _back.get_path_to(_back)
	_back.focus_neighbor_left = _back.get_path_to(_back)
	_back.focus_neighbor_right = _back.get_path_to(_back)


func _focus_strip() -> void:
	var active := _strip.get_node_or_null(
		NodePath("OptionsTab_%s" % _open)) as Button
	if active != null and is_visible_in_tree():
		active.grab_focus()


## Opened: on the first page, with the selection on the strip - that game's
## way in, so the first thing the keys do is choose a page.
func _arrive() -> void:
	if not visible:
		var open := page()
		if open != null and open.busy():
			open.cancel()
		return
	var first: StringName = tabs()[0] if not tabs().is_empty() else &""
	if first != &"":
		show_tab(first)
	_focus_strip()


func _gap(height: int) -> Control:
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, height)
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return gap


func _go_back() -> void:
	var router := get_node_or_null(^"/root/App")
	if router != null:
		router.back()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed(&"cancel") or event.is_action_pressed(&"ui_cancel"):
		var open := page()
		if open != null and open.busy() and open.cancel():
			get_viewport().set_input_as_handled()
			return
		MenuFocus.backed_out(self)
		_go_back()
		get_viewport().set_input_as_handled()
