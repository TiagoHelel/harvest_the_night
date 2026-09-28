class_name BootIdent
extends Control

## Two seconds before the title that are not somebody else's logo.
##
## The mark, and then the game. It is short on purpose: an ident
## is a signature, and a signature that takes longer than the thing it signs
## is an advertisement.
##
## ## Any input skips it
##
## A key, a button, a click - anything. The second time somebody opens this
## game they have already seen it, and an ident that cannot be got past is
## the reason people remember idents badly.
##
## ## Once per launch, not once per scene
##
## **A static flag rather than a timer**, because the title scene is opened
## and closed by more than a player: `input_check` opens it a dozen times and
## `shot.py` opens it to photograph it, and an ident that played every time
## would be a second and a half of black in front of every one of them. Both
## of those call `played()` at startup and get the title straight away, which
## is also what a player gets on their second visit within one launch.

## How long the whole thing takes, at the top of the file because it is the
## number somebody will want to argue with.
const SECONDS := 1.6

## Fading in, holding, fading out. They add up to one.
const IN := 0.25
const HOLD := 0.45

## How big the mark is drawn, in pixels. Ten times the sixteen it is drawn
## at, so it is the same drawing with bigger pixels.
##
## **The mark alone, and no wordmark.** The first version had both and they
## overlapped - and the title behind it puts the name on the screen a second
## later anyway, so the ident saying it first was the same thing twice.
const MARK := 160

## Whether this launch has already shown it.
static var _played := false


## Say that it has been seen, without showing it. For the tools.
static func played() -> void:
	_played = true


## Let it happen again. For the check that watches it happen.
static func forget() -> void:
	_played = false


static func seen() -> bool:
	return _played


var _left := 0.0

var _sheet: ColorRect
var _mark: TextureRect


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_sheet = ColorRect.new()
	_sheet.name = "IdentSheet"
	_sheet.color = PaletteData.COLOURS.get(&"ink", Color.BLACK)
	_sheet.set_anchors_preset(Control.PRESET_FULL_RECT)
	_sheet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_sheet)

	_mark = TextureRect.new()
	_mark.name = "IdentMark"
	_mark.texture = load("res://assets/icon.png")
	_mark.custom_minimum_size = Vector2(MARK, MARK)
	_mark.size = Vector2(MARK, MARK)
	_mark.position = Vector2(240.0 - MARK / 2.0, 135.0 - MARK / 2.0)
	_mark.stretch_mode = TextureRect.STRETCH_SCALE
	_mark.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_mark)

	if _played:
		visible = false
		set_process(false)
		set_process_unhandled_input(false)
		return
	_played = true
	_left = SECONDS
	_wear()


func _process(delta: float) -> void:
	if _left <= 0.0:
		return
	_left = maxf(_left - delta, 0.0)
	if _left <= 0.0:
		_finish()
		return
	_wear()


## **Anything at all.** Not `cancel`, not a named action: somebody who has
## seen it once presses whatever is under their hand.
func _unhandled_input(event: InputEvent) -> void:
	if not visible or _left <= 0.0:
		return
	var pressed := (event is InputEventKey and (event as InputEventKey).pressed
		and not (event as InputEventKey).echo) \
		or (event is InputEventMouseButton
			and (event as InputEventMouseButton).pressed) \
		or event is InputEventJoypadButton
	if not pressed:
		return
	_finish()
	get_viewport().set_input_as_handled()


func _finish() -> void:
	_left = 0.0
	visible = false
	set_process(false)
	set_process_unhandled_input(false)


## How far through it is, as an alpha: up, held, down.
func _wear() -> void:
	var gone := 1.0 - _left / SECONDS
	var alpha := 1.0
	if gone < IN:
		alpha = gone / IN
	elif gone > IN + HOLD:
		alpha = maxf(1.0 - (gone - IN - HOLD) / maxf(1.0 - IN - HOLD, 0.001),
			0.0)
	_mark.modulate.a = alpha


# ------------------------------------------------------------ for the checks

func running() -> bool:
	return visible and _left > 0.0


func left() -> float:
	return _left
