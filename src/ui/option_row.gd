class_name OptionRow
extends Button

## One line of the options screen, the way WELCOME BACK, HERO's work: the
## name on the left, the value on the right, and one way of changing it for
## every hand.
##
##     LANGUAGE                         <  ENGLISH  >
##     MUSIC                    ########----  70%
##     JUMP                                     SPACE
##
## **Left and right change it, Enter takes it.** On a choice or a switch left
## and right step through the values and Enter steps forward; on a slider they
## move it a notch; on an action or a key binding Enter is the whole thing. The
## pointer does the same by clicking the left or the right half of the value.
## Up and down are left alone, so
## the screen's own focus walks between rows - `MenuFocus` puts the caret on
## the one that has it.
##
## **The row knows how to look, not what it means.** What a value is called,
## what stepping does and what Enter does are callables the page hands it, so
## the settings, the video trial and the key bindings stay where they were and
## this is the one place a row is drawn.

## What kind of line it is.
enum Kind { CHOICE, TOGGLE, SLIDER, ACTION, BIND, HEADING }

## The height of every row, in pixels: the eight pixel face and two either side.
const HEIGHT := 12

## Where the value column starts, from the right edge, and the slider's bar.
const VALUE_WIDTH := 132
const BAR := Vector2i(64, 4)
const RIGHT_PAD := 4

var kind: Kind = Kind.CHOICE

## `func(delta: int) -> void`: move the value one step left (-1) or right (+1).
var on_step: Callable
## `func() -> void`: what Enter, Space or a click on the name does.
var on_take: Callable
## `func() -> String`: the value as the row shows it.
var shows: Callable
## `func() -> float`: for a slider, how full the bar is, 0 to 1.
var fill: Callable
## Whether the value is on its way somewhere - a key being listened for, a
## question being asked - so it is drawn in the warning colour.
var urgent := false

## Where the last click on this row landed, across it, or below zero when it
## was a key that pressed it. A `Button` only ever presses for the left
## button, so this is all a row needs to know about the pointer.
var _pointer := -1.0


func _init() -> void:
	theme_type_variation = UiKit.OPTION
	alignment = HORIZONTAL_ALIGNMENT_LEFT
	custom_minimum_size = Vector2(0, HEIGHT)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	focus_mode = Control.FOCUS_ALL
	pressed.connect(_taken)


## A row that is only a heading: not a thing to stand on, so the keys pass it.
func as_heading() -> OptionRow:
	kind = Kind.HEADING
	focus_mode = Control.FOCUS_NONE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme_type_variation = UiKit.OPTION_HEADING
	return self


## Whether the row has a value that steps: a choice, a switch or a slider.
func _has_value() -> bool:
	return kind == Kind.CHOICE or kind == Kind.TOGGLE or kind == Kind.SLIDER


## It draws its own caret, inside the row; see `_draw`. `MenuFocus` asks.
func draws_own_caret() -> bool:
	return true


## Draw it again: a value changed somewhere else.
func refresh() -> void:
	queue_redraw()


## The value as it is on the screen, for the checks.
func value_text() -> String:
	return String(shows.call()) if shows.is_valid() else ""


func step(delta: int) -> void:
	if disabled or kind == Kind.HEADING:
		return
	if on_step.is_valid():
		on_step.call(delta)
		MenuFocus.changed(self)
	refresh()


func _taken() -> void:
	# **The value's two halves are its two arrows.** A click on the name is an
	# ordinary press, which a choice takes as a step forward - the same thing
	# Enter does.
	var at := _pointer
	_pointer = -1.0
	if _has_value() and at >= size.x - VALUE_WIDTH:
		step(-1 if at < size.x - VALUE_WIDTH * 0.5 - RIGHT_PAD else 1)
		return
	match kind:
		Kind.CHOICE, Kind.TOGGLE:
			step(1)
		Kind.SLIDER:
			pass
		_:
			if on_take.is_valid():
				on_take.call()
	refresh()


func _gui_input(event: InputEvent) -> void:
	if disabled or kind == Kind.HEADING:
		return
	# A key binding steps too - left and right put a moved one back - but
	# only by the keys: a click on it is a click to listen.
	var steps := _has_value() or (kind == Kind.BIND and on_step.is_valid())
	if steps and event.is_action_pressed(&"ui_left", true):
		step(-1)
		accept_event()
		return
	if steps and event.is_action_pressed(&"ui_right", true):
		step(1)
		accept_event()
		return
	var click := event as InputEventMouseButton
	if click != null and click.pressed:
		_pointer = click.position.x


# --------------------------------------------------------------- the drawing

func _draw() -> void:
	if kind == Kind.HEADING:
		return
	var face := get_theme_font(&"font")
	var tall := get_theme_font_size(&"font_size")
	if face == null:
		return
	var lit := has_focus() or is_hovered()
	var colour := get_theme_color(&"font_disabled_color") if disabled \
		else UiKit.colour(UiKit.WARN) if urgent \
		else get_theme_color(&"font_focus_color") if lit \
		else get_theme_color(&"font_color")
	var arrow := UiKit.colour(UiKit.WARM) if lit and not disabled \
		else UiKit.colour(UiKit.FAINT)
	var baseline := floorf((size.y - float(tall)) * 0.5) \
		+ face.get_ascent(tall)
	var right := size.x - RIGHT_PAD
	var words := value_text()
	# **The caret, inside the row**, in the gold `MenuFocus` uses everywhere
	# else - a page scrolls, and a pointer in the margin outside the row would
	# be clipped away with it.
	if has_focus() and not disabled:
		var gold := UiKit.colour(UiKit.WARM)
		var top := floorf((size.y - 5.0) * 0.5)
		draw_rect(Rect2(2, top, 1, 5), gold)
		draw_rect(Rect2(3, top + 1, 1, 3), gold)
		draw_rect(Rect2(4, top + 2, 1, 1), gold)
	match kind:
		Kind.SLIDER:
			var amount := clampf(float(fill.call()) if fill.is_valid() else 0.0, 0.0, 1.0)
			var number_w := face.get_string_size("100%", HORIZONTAL_ALIGNMENT_LEFT, -1, tall).x
			draw_string(face, Vector2(right - number_w, baseline), words,
				HORIZONTAL_ALIGNMENT_RIGHT, number_w, tall, colour)
			var bar_x := right - number_w - 6 - BAR.x
			var bar_y := floorf((size.y - BAR.y) * 0.5)
			draw_rect(Rect2(bar_x - 1, bar_y - 1, BAR.x + 2, BAR.y + 2),
				PaletteData.COLOURS[&"ink"])
			draw_rect(Rect2(bar_x, bar_y, BAR.x, BAR.y),
				PaletteData.COLOURS[&"ink_soft"])
			if amount > 0.0:
				draw_rect(Rect2(bar_x, bar_y, roundf(BAR.x * amount), BAR.y),
					UiKit.colour(UiKit.MONEY) if not disabled else UiKit.colour(UiKit.FAINT))
			if lit:
				draw_string(face, Vector2(bar_x - 10, baseline), "<",
					HORIZONTAL_ALIGNMENT_LEFT, -1, tall, arrow)
		Kind.CHOICE, Kind.TOGGLE:
			var word_w := face.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, tall).x
			var gt_w := face.get_string_size(">", HORIZONTAL_ALIGNMENT_LEFT, -1, tall).x
			draw_string(face, Vector2(right - gt_w, baseline), ">",
				HORIZONTAL_ALIGNMENT_LEFT, -1, tall, arrow)
			var word_x := right - gt_w - 6 - word_w
			draw_string(face, Vector2(word_x, baseline), words,
				HORIZONTAL_ALIGNMENT_LEFT, -1, tall, colour)
			draw_string(face, Vector2(word_x - 6 - gt_w, baseline), "<",
				HORIZONTAL_ALIGNMENT_LEFT, -1, tall, arrow)
		Kind.BIND, Kind.ACTION:
			if words != "":
				draw_string(face, Vector2(right - VALUE_WIDTH, baseline), words,
					HORIZONTAL_ALIGNMENT_RIGHT, VALUE_WIDTH, tall, colour)
