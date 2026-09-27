class_name DayHud
extends Control

## The bar across the top of the reference sheet, and the button that starts
## the night.
##
## `design.md` section 14: which day it is, what you have, and the one control
## that matters. **It reads the state and holds none of its own** - every number
## here is a lookup, so the HUD and the ledger cannot drift apart. The only
## thing it remembers is what each number was a moment ago, which is not game
## state, it is how a flash knows to happen.
##
## ## The flash
##
## A number changing is easy to miss and a farm is a place where you are looking
## somewhere else. When a total moves, its label goes bright and fades back over
## a few tenths of a second - so picking up wood is visible from the corner of
## the eye rather than only to somebody watching the number.
##
## ## The night button
##
## Bottom right, and it says what it will do rather than just "night". It is a
## real focusable `Button`, so the keyboard reaches it; `N` does the same thing
## without having to find it.

## What the top bar shows, in two rows. Not all thirteen: the bar has 480
## pixels and the inventory panel of task 0036 is where everything lives.
## These are the six a player is deciding with.
const SHOWN: Array = [
	[GameData.WOOD, GameData.STONE, GameData.IRON],
	[GameData.WHEAT, GameData.FOOD, GameData.OIL],
]

## How long a changed number stays lit.
const FLASH_SECONDS := 0.45

const DIM := Color(0.62, 0.60, 0.70)
const LIT := Color(1.0, 0.95, 0.70)
const WARM := Color(0.95, 0.85, 0.55)

var _state: Dictionary = {}
var _day: Label
var _money: Label
var _night: Button
var _labels: Dictionary = {}        # resource id -> Label
var _last: Dictionary = {}          # resource id -> the number it last showed
var _flash: Dictionary = {}         # resource id -> seconds of glow left


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)

	# **A strip behind the bar.** Pale text on a sunlit farm is text nobody can
	# read; the first render of this HUD had the numbers disappearing into the
	# grass.
	var strip := ColorRect.new()
	strip.name = "TopStrip"
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	strip.color = Color(0.05, 0.04, 0.09, 0.72)
	strip.position = Vector2.ZERO
	strip.size = Vector2(480, 27)   # tall enough for both rows
	add_child(strip)

	_day = _label("Day", Vector2(4, 3), WARM)
	_day.text = "DAY 1"

	_money = _label("Money", Vector2(96, 3), WARM)
	_money.text = "$ 0"

	# Two rows of three, right-aligned against the top-right corner, the way
	# section 14 of the design document lays them out.
	for row in SHOWN.size():
		for column in (SHOWN[row] as Array).size():
			var id: StringName = SHOWN[row][column]
			var label := _label("res_%s" % id,
				Vector2(210 + column * 88, 3 + row * 11), DIM)
			_labels[id] = label
			_last[id] = -1

	_night = Button.new()
	_night.name = "NightButton"
	_night.text = "SWITCH TO NIGHT"
	_night.position = Vector2(352, 248)
	_night.size = Vector2(124, 18)
	_night.add_theme_font_size_override("font_size", 9)
	_night.focus_mode = Control.FOCUS_ALL          # the keyboard can reach it
	_night.pressed.connect(_ask_for_night)
	add_child(_night)


func show_state(state: Dictionary) -> void:
	_state = state
	_refresh(true)


func _process(delta: float) -> void:
	if _state.is_empty():
		return
	_refresh(false)
	_fade(delta)

	# `N` does what the button does, for a player whose hands are on the keys.
	if Input.is_action_just_pressed(&"night"):
		_ask_for_night()


## Ask the rules to start the night. **The HUD does not change the phase**: it
## writes what the player wants into the intent and the tick decides, which is
## the same road the keyboard and the autoplayer take.
func _ask_for_night() -> void:
	if _state.is_empty():
		return
	(_state["intent"] as Dictionary)["begin_night"] = true


func _refresh(force: bool) -> void:
	var phase := int(_state["phase"])
	visible = phase == Phases.DAY
	if not visible:
		return

	# The clock lives here now rather than in its own label on the other side
	# of the screen, where it sat on top of the resource grid.
	var tick := int(_state["tick"])
	_day.text = "DAY %d   %d:%02d" % [
		int(_state["day"]),
		tick / (GameData.TICK_HZ * 60),
		(tick / GameData.TICK_HZ) % 60,
	]
	var money := Resources.amount(_state, GameData.MONEY)
	if force or money != int(_last.get(GameData.MONEY, -1)):
		if not force and _last.has(GameData.MONEY):
			_flash[GameData.MONEY] = FLASH_SECONDS
		_last[GameData.MONEY] = money
		_money.text = "$ %d" % money

	for id in _labels:
		var held := Resources.amount(_state, id)
		if not force and held == int(_last[id]):
			continue
		if not force and int(_last[id]) >= 0:
			_flash[id] = FLASH_SECONDS
		_last[id] = held
		(_labels[id] as Label).text = "%s %d" % [_short(id), held]

	# **Past dusk the button asks.** It never presses itself: `design.md`
	# promises the player switches reality when they want to.
	_night.text = "NIGHT %d IS WAITING" % int(_state["day"]) \
		if Phases.is_dusk(_state) else "SWITCH TO NIGHT"
	_night.modulate = LIT if Phases.is_dusk(_state) else Color(1, 1, 1)


func _fade(delta: float) -> void:
	var done: Array = []
	for id in _flash:
		var left := float(_flash[id]) - delta
		if left <= 0.0:
			done.append(id)
			continue
		_flash[id] = left
		var t := left / FLASH_SECONDS
		var label: Label = _money if id == GameData.MONEY else _labels[id]
		label.modulate = DIM.lerp(LIT, t)
	for id in done:
		_flash.erase(id)
		var label: Label = _money if id == GameData.MONEY else _labels[id]
		label.modulate = WARM if id == GameData.MONEY else DIM


## The whole word, until task 0079 draws the icons the reference sheet has.
##
## The first version of this abbreviated to three letters and produced "WOO",
## "STO" and "IRO" - which is not shorthand, it is a puzzle. At font size 9 the
## longest of these is forty pixels and the bar is four hundred and eighty.
func _short(id: StringName) -> String:
	return str(id)


func _label(node_name: String, at: Vector2, colour: Color) -> Label:
	var label := Label.new()
	label.name = node_name
	label.position = at
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.modulate = colour
	label.add_theme_font_size_override("font_size", 9)
	add_child(label)
	return label
