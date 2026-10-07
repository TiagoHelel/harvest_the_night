class_name OptionsPage
extends Control

## One page of the options screen: a column of `OptionRow`s that scrolls when
## it is longer than the room, a line of small print under it, and - on a page
## that owns settings - a last row that puts the page back the way it shipped.
##
## A page builds its rows in `_build()` with the four helpers below and says
## what they are called in `relabel()`. Everything about moving between rows,
## the caret and the sounds is `MenuFocus` and the frame's, so a page is only
## ever the list of what can be set on it.
##
## **Putting a page back asks twice.** The first press turns the row into the
## question - in the warning colour - and the second does it; walking off the
## row forgets the question. A page of settings is minutes of somebody's
## fiddling and the one key that throws it away should not be one keystroke.

## The settings this page owns, for its reset row. None means no reset row.
var resets: Array = []
## What the page is called, for the reset row.
var title_key: StringName = &""

var _settings: Node
var _scroll: ScrollContainer
var _column: VBoxContainer
var _note: Label
var _reset: OptionRow
var _asked := false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_settings = get_node_or_null(^"/root/Settings")

	var box := VBoxContainer.new()
	box.name = "PageBox"
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)

	_scroll = ScrollContainer.new()
	_scroll.name = "PageScroll"
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.follow_focus = true
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(_scroll)

	_column = VBoxContainer.new()
	_column.name = "PageRows"
	_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_column)

	_note = Label.new()
	_note.name = "PageNote"
	_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_note.theme_type_variation = UiKit.DIM
	_note.custom_minimum_size = Vector2(0, 8)
	box.add_child(_note)

	_build()
	if not resets.is_empty():
		_reset = action_row("ResetPage", _reset_pressed)
		_reset.focus_exited.connect(_forget_reset)
	if _settings != null:
		_settings.changed.connect(_on_setting)
		_settings.reloaded.connect(refresh)
	relabel()


## The page's own rows. Every page writes this.
func _build() -> void:
	pass


## Say it all again in whatever language is up now. A page that overrides
## this calls it last, for the reset row and the redraw.
func relabel() -> void:
	if _reset != null:
		var page := I18n.t(title_key)
		_reset.text = I18n.f(&"OPT_RESET_SURE", [page]) if _asked \
			else I18n.f(&"OPT_RESET_TAB", [page])
		_reset.urgent = _asked
	refresh()


## Draw every row again, because a value changed somewhere.
func refresh() -> void:
	for row in rows():
		(row as OptionRow).refresh()


## Every row on the page, headings included, top to bottom.
func rows() -> Array:
	var out: Array = []
	if _column == null:
		return out
	for child in _column.get_children():
		if child is OptionRow:
			out.append(child)
	return out


## The rows a player can stand on, top to bottom.
func entries() -> Array:
	var out: Array = []
	for row in rows():
		var one := row as OptionRow
		if one.visible and one.focus_mode != Control.FOCUS_NONE:
			out.append(one)
	return out


## Whether the page is in the middle of something escape should end first -
## a key being listened for, a new window size waiting to be kept.
func busy() -> bool:
	return _asked


## Escape, while the page is busy. True when it was the page's to take.
func cancel() -> bool:
	if _asked:
		_forget_reset()
		return true
	return false


## The small print under the rows.
func say(words: String, role: StringName = UiKit.DIM) -> void:
	_note.text = words
	_note.theme_type_variation = role


func note_shown() -> String:
	return _note.text if _note != null else ""


# ------------------------------------------------------------------ the rows

func choice_row(named: String, step: Callable, shows: Callable) -> OptionRow:
	var row := _row(named, OptionRow.Kind.CHOICE)
	row.on_step = step
	row.shows = shows
	return row


func toggle_row(named: String, key: StringName) -> OptionRow:
	var row := _row(named, OptionRow.Kind.TOGGLE)
	row.on_step = func(_delta: int) -> void:
		if _settings != null:
			_settings.set_value(key, not bool(_settings.get_bool(key)))
	row.shows = func() -> String:
		var on: bool = _settings != null and bool(_settings.get_bool(key))
		return I18n.t(&"OPT_ON") if on else I18n.t(&"OPT_OFF")
	return row


func slider_row(named: String, step: Callable, shows: Callable,
		fill: Callable) -> OptionRow:
	var row := _row(named, OptionRow.Kind.SLIDER)
	row.on_step = step
	row.shows = shows
	row.fill = fill
	return row


func action_row(named: String, take: Callable) -> OptionRow:
	var row := _row(named, OptionRow.Kind.ACTION)
	row.on_take = take
	return row


func heading_row(named: String) -> OptionRow:
	var row := _row(named, OptionRow.Kind.HEADING)
	row.as_heading()
	return row


func _row(named: String, kind: OptionRow.Kind) -> OptionRow:
	var row := OptionRow.new()
	row.name = named
	row.kind = kind
	_column.add_child(row)
	return row


## Step through a list by one, wrapping at both ends.
static func stepped(values: Array, now: Variant, delta: int) -> Variant:
	if values.is_empty():
		return now
	var at := 0
	for i in values.size():
		if typeof(values[i]) == TYPE_FLOAT or typeof(now) == TYPE_FLOAT:
			if is_equal_approx(float(values[i]), float(now)):
				at = i
		elif values[i] == now:
			at = i
	return values[posmod(at + delta, values.size())]


# ----------------------------------------------------------------- the reset

func _reset_pressed() -> void:
	if not _asked:
		_asked = true
		relabel()
		return
	_asked = false
	if _settings != null:
		for key in resets:
			_settings.reset(key)
	relabel()


func _forget_reset() -> void:
	if not _asked:
		return
	_asked = false
	relabel()


func _on_setting(_key: StringName) -> void:
	refresh()


# ------------------------------------------------------------ for the checks

## Whether the reset row is asking its question.
func reset_asking() -> bool:
	return _asked
