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
## ## The seed strip
##
## Down the left, one row per crop: what it costs, how long it takes and what
## a plot of it is worth over a whole day. **That last number is the reason the
## strip exists** - corn sells for more than carrot and carrot is worth more per
## day, and a player comparing the two sale prices is comparing the wrong pair
## of numbers. The rows are built from `Farming.seeds()`, so a fourth crop
## appears here, on a number key, without this file being touched.
##
## ## The watering can
##
## Under the strip, because the two are one chore: what am I about to plant,
## and have I got water for it. It says where to fill up rather than only how
## much is left - an empty can and no explanation is how a player decides the
## mechanic is broken.
##
## ## The line in the water
##
## One label in the middle of the screen while a cast is out, because a bite
## nobody can see is a reaction test with nothing to react to. It is deliberately
## plain: **task 0078 draws the float going under**, which is the version a
## player should get, and this is what keeps the mechanic playable until then.
##
## ## The power line stays up at night
##
## Everything else here belongs to the day and goes away with it. The energy
## readout does not: towers draw while they are shooting, and a generator
## running dry half way through a wave is the one moment a player most needs to
## be told. So `_refresh()` hides the **contents** rather than the panel, and
## the power line is the one child left showing.
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

## The keys that pick a seed, in `Farming.seeds()` order.
const SEED_KEYS: Array = [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6]

const PICKED := Color(1.0, 0.92, 0.62)
const BITE := Color(1.0, 0.85, 0.35)
const SHORT := Color(0.96, 0.55, 0.36)

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
var _seed_rows: Dictionary = {}     # crop id -> Label
var _water: Label
var _line: Label
var _power: Label
var _day_only: Array[Control] = []


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

	_build_seed_strip()

	# The can sits under the seed strip, because the two are the same chore:
	# what am I about to plant, and have I got water for it.
	_water = _label("WaterCan",
		Vector2(7, 46 + Farming.seeds().size() * 10 + 3), DIM)

	# Middle of the screen, under the farmer rather than in a corner: the
	# player is looking at the water, not at the top bar.
	_line = _label("FishingLine", Vector2(186, 208), BITE)
	_line.visible = false

	# **Bottom left, and it stays up after dark.** Supply against draw, and
	# what that is doing to the speed of everything.
	_power = _label("PowerLine", Vector2(4, 258), DIM)

	_night = Button.new()
	_night.name = "NightButton"
	_night.text = "SWITCH TO NIGHT"
	_night.position = Vector2(352, 248)
	_night.size = Vector2(124, 18)
	_night.add_theme_font_size_override("font_size", 9)
	_night.focus_mode = Control.FOCUS_ALL          # the keyboard can reach it
	_night.pressed.connect(_ask_for_night)
	add_child(_night)


## One row per crop, read off the data. Nothing here names wheat, corn or
## carrot: the strip is whatever `GameData.CROPS` turned out to hold.
func _build_seed_strip() -> void:
	var ids := Farming.seeds()

	var strip := ColorRect.new()
	strip.name = "SeedStrip"
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	strip.color = Color(0.05, 0.04, 0.09, 0.66)
	strip.position = Vector2(4, 33)
	strip.size = Vector2(134, 13 + ids.size() * 10 + 14)
	add_child(strip)

	var heading := _label("SeedHeading", Vector2(7, 35), WARM)
	heading.text = "# CROP    $  TIME  /DAY"

	for i in ids.size():
		var id: StringName = ids[i]
		var row := _label("seed_%s" % id, Vector2(7, 46 + i * 10), DIM)
		row.text = "%d %-7s $%-2d %3ds  %2d" % [i + 1, str(id),
			int((GameData.CROPS[id] as Dictionary)["seed_cost"]),
			Farming.seconds_to_grow(id), Farming.value_per_day(id)]
		_seed_rows[id] = row


## Everything that belongs to the daylight, hidden together when it ends.
func _remember_day_only(nodes: Array) -> void:
	for node in nodes:
		if node is Control:
			_day_only.append(node as Control)


## Whether the day's own chrome is up: the bar, the seed strip, the night
## button. **Not `visible`** - the panel itself stays up after dark to carry
## the power line, so a test that asked the node would be asking the wrong
## question and getting the wrong answer.
func shows_day() -> bool:
	if _state.is_empty() or _day_only.is_empty():
		return visible
	return visible and _day_only[0].visible


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


## **The number keys are read as keys, not as actions.** One action per crop
## would put a `plant_crop_4` in `project.godot` every time somebody adds a
## dictionary entry, which is the opposite of what this task is for. Task 0095
## rebinds the named actions; these stay positional, the way a hotbar is.
func _unhandled_input(event: InputEvent) -> void:
	if _state.is_empty() or int(_state["phase"]) != Phases.DAY:
		return
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	var slot := SEED_KEYS.find(key.keycode)
	if slot >= 0 and Farming.select_seed_at(_state, slot):
		get_viewport().set_input_as_handled()


## Ask the rules to start the night. **The HUD does not change the phase**: it
## writes what the player wants into the intent and the tick decides, which is
## the same road the keyboard and the autoplayer take.
func _ask_for_night() -> void:
	if _state.is_empty():
		return
	(_state["intent"] as Dictionary)["begin_night"] = true


func _refresh(force: bool) -> void:
	var phase := int(_state["phase"])
	var daylight := phase == Phases.DAY

	# **The power line first**, because it is the one thing here that outlives
	# the day.
	var supply := Power.supply(_state)
	var draw := Power.draw(_state)
	var percent := Power.percent(_state)
	_power.text = "POWER %d/%d" % [supply, draw] \
		if percent >= 100 else "POWER %d/%d  everything at %d%%" \
			% [supply, draw, percent]
	_power.modulate = SHORT if percent < 100 else DIM

	if _day_only.is_empty():
		for child in get_children():
			if child is Control and child != _power:
				_day_only.append(child as Control)
	for node in _day_only:
		node.visible = daylight
	visible = true
	if not daylight:
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

	# **The can, and where to fill it when it is empty.** A number on its own
	# would leave a player who has never found the well holding an empty can
	# with no idea why.
	var carried := Farming.water_carried(_state)
	_water.text = "WATER %d/%d" % [carried, GameData.WATER_CAN_CAPACITY] \
		if carried > 0 else "WATER  fill at the well"
	_water.modulate = PICKED if carried > 0 else DIM

	# The chosen row is lit, so the strip answers "what am I about to plant"
	# without the player having to remember which key they last pressed.
	var chosen := Farming.selected_seed(_state)
	for id in _seed_rows:
		(_seed_rows[id] as Label).modulate = PICKED if id == chosen else DIM

	# **The line, while there is one.** Waiting says so quietly; a bite shouts,
	# because the window is a second and a half.
	_line.visible = daylight and Fishing.is_casting(_state)
	if _line.visible:
		var biting := Fishing.is_biting(_state)
		_line.text = "A BITE - PRESS SPACE" if biting else "waiting for a bite"
		_line.modulate = BITE if biting else DIM

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
