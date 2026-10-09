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
## of numbers. Six rows per page come from `Farming.seeds()`; number keys
## always pick the matching row on the visible page (task 0168).
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
## ## The ammunition pool, also after dark
##
## Beside the power line and for the same reason: a mortar running out of
## powder mid-wave is something the player has to be able to see happening, and
## everything else in this panel belongs to the day.
##
## ## The clock and bedtime (task 0140)
##
## Top left, in the heading face: the hour is what the day is spent against
## now that 02:00 ends it. Beside it the day, and under the day one line for
## the evening - dusk, then from `BEDTIME_REMINDER_MINUTE` a quiet "time for
## bed" naming the GO TO BED key, then from `PASS_OUT_WARNING_MINUTE` the
## minutes left before he passes out, in the warn colour, with the clock
## gone the same colour.
##
## ## The night button
##
## Bottom right, and it says what it will do rather than just "night". It is a
## real focusable `Button`, so the keyboard reaches it; `N` does the same thing
## without having to find it. It wears the moon's letters (`UiKit.BED`) and
## lights up from the reminder hour (`UiKit.BED_LIT`).

## What the top bar shows, in two rows. The bar has 480
## pixels and the inventory panel of task 0036 is where everything lives.
## These are the six a player is deciding with.
const SHOWN: Array = [
	[GameData.WOOD, GameData.STONE, GameData.IRON],
	[GameData.FOOD, GameData.MONEY, GameData.TECH],
]

## How long a changed number stays lit.
const FLASH_SECONDS := 0.45

## What a flashing number is multiplied by at the top of its flash, and what
## the dusk labels wear while the sun is going down.
##
## **A brightness, not a colour.** The variation says what a label *is* and
## this says how lit it is right now, which is the one thing `modulate` is
## actually good at. Before task 0081 the two were the same mechanism and the
## HUD had six colour constants to keep in step.
const LIT_TINT := Color(1.55, 1.45, 1.10)

## The clock, the date beside it (task 0149) and the evening's line under
## the date: the clock is in the heading face across both rows of the bar.
const CLOCK_AT := Vector2(4, 2)
const DAY_AT := Vector2(68, 3)
const STATUS_AT := Vector2(68, 14)
## **The year, under the clock** (task 0152), from Year 2 on: the line under
## the date became the Full Moon's, and the free corner under the hour is the
## one place in the bar a year fits beside everything else.
const YEAR_AT := Vector2(4, 16)

## The actions that pick a seed, in `Farming.seeds()` order.
##
## **Six slots, not one per crop.** That was the objection when these were
## raw number keys - a `plant_crop_4` in `project.godot` every time somebody
## adds a dictionary entry - and it is answered by binding the *position*
## rather than the crop. A hotbar has six slots however many things exist.
const SEED_ACTIONS: Array = [&"slot_1", &"slot_2", &"slot_3", &"slot_4",
	&"slot_5", &"slot_6"]



var _state: Dictionary = {}
var _clock: Label
var _day: Label
var _status: Label
var _year: Label
var _money: Label
var _night: Button

## The driver, for the speed and skip keys (their buttons are the night
## HUD's). Set by `main.gd`; the HUD asks it to do things and never touches
## `state` to do them.
var driver: SimDriver
var _labels: Dictionary = {}        # resource id -> Label
var _last: Dictionary = {}          # resource id -> the number it last showed
var _flash: Dictionary = {}         # resource id -> seconds of glow left
var _seed_page := 0
var _last_seed := &""
var _seed_badge: Label
var _seed_previous: Button
var _seed_next: Button
var _seed_rows: Dictionary = {}     # crop id -> Label
var _water: Label
var _line: Label
var _power: Label
var _power_icon: TextureRect
var _ammo: Label
var _day_only: Array[Control] = []
var _last_purse := -1


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

	# **The clock first** (task 0140), its own label in the heading face.
	_clock = _label("Clock", CLOCK_AT, UiKit.HEADING)
	_clock.text = I18n.f(&"DHUD_CLOCK", [6, 0])
	_day = _label("Day", DAY_AT, UiKit.WARM)
	_day.text = I18n.f(&"DHUD_DATE", [Names.of(GameData.SEASONS[0]), 1])
	_status = _label("DayStatus", STATUS_AT, UiKit.DIM)
	_year = _label("Year", YEAR_AT, UiKit.DIM)

	# **The date ends before the money group**: its widest, PRIMAVERA 14, is
	# 69 of the 74 pixels up to the purse (`DHUD_DATE`'s width, measured by
	# 0149's case). The year never shares that row - it has the line below.
	_icon(GameData.MONEY, Vector2(144, 3))
	_money = _label("Money", Vector2(156, 3), UiKit.WARM)
	_money.text = I18n.t(&"DHUD_MONEY_FIRST")

	# Two rows of three, right-aligned against the top-right corner, the way
	# section 14 of the design document lays them out.
	for row in SHOWN.size():
		for column in (SHOWN[row] as Array).size():
			var id: StringName = SHOWN[row][column]
			_icon(id, Vector2(210 + column * 88, 3 + row * 11))
			var label := _label("res_%s" % id,
				Vector2(222 + column * 88, 3 + row * 11), UiKit.DIM)
			_labels[id] = label
			_last[id] = -1

	_build_seed_strip()

	# The can sits under the seed strip, because the two are the same chore:
	# what am I about to plant, and have I got water for it.
	_water = _label("WaterCan",
		Vector2(7, 46 + SEED_ACTIONS.size() * 10 + 3), UiKit.DIM)

	# Middle of the screen, under the farmer rather than in a corner: the
	# player is looking at the water, not at the top bar.
	_line = _label("FishingLine", Vector2(186, 208), UiKit.WARM)
	_line.visible = false

	# **Bottom left, and it stays up after dark.** Supply against draw, and
	# what that is doing to the speed of everything.
	_power_icon = _icon(GameData.ENERGY, Vector2(4, 258))
	_power = _label("PowerLine", Vector2(16, 258), UiKit.DIM)

	# Under the power line, and up after dark for the same reason.
	_ammo = _label("AmmoLine", Vector2(4, 248), UiKit.DIM)

	# Neither of these is day chrome, so they are built after `_day_only` is
	# collected and shown by hand on the night side of `_refresh()`.
	_night = Button.new()
	_night.name = "NightButton"
	_night.text = I18n.t(&"DHUD_TO_NIGHT")
	_night.position = Vector2(352, 248)
	_night.size = Vector2(124, 18)
	_night.focus_mode = Control.FOCUS_ALL          # the keyboard can reach it
	_night.theme_type_variation = UiKit.BED
	_night.pressed.connect(_ask_for_night)
	add_child(_night)

	# **The night's controls are the night HUD's**: the flare and the speed
	# since task 0056, and SKIP since 0139, a button with its refusal as its
	# tooltip. Their keys are still read here, beside the night key.


## Cycle 1x, 2x, 4x. The label follows on the next frame, off the driver.
func _cycle_speed() -> void:
	if driver != null:
		driver.cycle_speed()


## Run the rest of the night now, if the rules allow it.
func _skip_the_night() -> void:
	if driver != null:
		driver.skip_night()


## One row per crop, read off the data. Nothing here names wheat, corn or
## carrot: the strip is whatever `GameData.CROPS` turned out to hold.
func _build_seed_strip() -> void:
	var ids := Farming.seeds()

	var strip := ColorRect.new()
	strip.name = "SeedStrip"
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	strip.color = Color(0.05, 0.04, 0.09, 0.66)
	strip.position = Vector2(4, 33)
	strip.size = Vector2(168, 108)
	add_child(strip)

	var heading := _label("SeedHeading", Vector2(7, 35), UiKit.WARM)
	heading.text = I18n.t(&"DHUD_SEED_HEADING")

	for i in ids.size():
		var id: StringName = ids[i]
		var row := _label("seed_%s" % id, Vector2(7, 46 + (i % SEED_ACTIONS.size()) * 10), UiKit.DIM)
		row.text = I18n.f(&"DHUD_SEED_ROW", [i % SEED_ACTIONS.size() + 1, Names.of(id),
			(0 if _state.is_empty() else Resources.amount(_state, Farming.packet(id))),
			Farming.days_to_grow(id), Farming.value_per_season(id)])
		_seed_rows[id] = row
	_seed_previous = _seed_button("SeedPrevious", &"SEED_PREVIOUS", Vector2(7, 123), -1)
	_seed_next = _seed_button("SeedNext", &"SEED_NEXT", Vector2(114, 123), 1)
	_seed_badge = _label("SeedPage", Vector2(77, 125), UiKit.DIM)


func _seed_button(node_name: String, key: StringName, at: Vector2, step: int) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = I18n.t(key)
	button.position = at
	button.size = Vector2(50, 14)
	button.focus_mode = Control.FOCUS_ALL
	button.theme_type_variation = UiKit.ROW
	button.pressed.connect(func() -> void:
		_seed_page = clampi(_seed_page + step, 0, maxi((Farming.in_season(_state).size() - 1) / SEED_ACTIONS.size(), 0))
		_refresh(true))
	add_child(button)
	return button


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

	# The night's own two keys, live only after dark. The buttons for these
	# are on the night HUD; these are for hands already on the keyboard.
	if int(_state["phase"]) == Phases.NIGHT:
		if Input.is_action_just_pressed(&"speed"):
			_cycle_speed()
		if Input.is_action_just_pressed(&"skip_night"):
			_skip_the_night()

	# `N` does what the button does, for a player whose hands are on the keys.
	if Input.is_action_just_pressed(&"night"):
		_ask_for_night()


## Pick a seed by its place in the row.
func _unhandled_input(event: InputEvent) -> void:
	if _state.is_empty() or int(_state["phase"]) != Phases.DAY:
		return
	for slot in SEED_ACTIONS.size():
		if not event.is_action_pressed(SEED_ACTIONS[slot]):
			continue
		if Farming.select_seed_at(_state, _seed_page * SEED_ACTIONS.size() + slot):
			get_viewport().set_input_as_handled()
		return


## Ask the rules to put the farmer to bed, which starts the night (task 0127).
## **The HUD does not change the phase**: it writes what the player wants into
## the intent and the tick decides, which is the same road the keyboard, the
## bed and the autoplayer take. Only by day - there is no bed to go to twice.
func _ask_for_night() -> void:
	if _state.is_empty() or int(_state["phase"]) != Phases.DAY:
		return
	(_state["intent"] as Dictionary)["sleep"] = true


func _refresh(force: bool) -> void:
	var phase := int(_state["phase"])
	var daylight := phase == Phases.DAY

	# **The power line first**, because it is the one thing here that outlives
	# the day.
	var supply := Power.supply(_state)
	var draw := Power.draw(_state)
	var percent := Power.percent(_state)
	_power.text = I18n.f(&"DHUD_POWER", [supply, draw]) \
		if percent >= 100 \
		else I18n.f(&"DHUD_POWER_SHORT", [supply, draw, percent])
	_power.theme_type_variation = UiKit.WARN if percent < 100 \
		else UiKit.DIM

	# **What is left to shoot**, and a warning when a kind has run dry.
	var parts: Array = []
	var empty := false
	for res in Ammo.kinds():
		var held := Resources.amount(_state, res)
		parts.append(I18n.f(&"DHUD_AMMO_ONE", [Names.of(res), held]))
		if held <= 0:
			empty = true
	_ammo.text = I18n.f(&"DHUD_AMMO", ["   ".join(parts)]) \
		if not parts.is_empty() else I18n.t(&"DHUD_AMMO_NONE")
	_ammo.theme_type_variation = UiKit.WARN if empty else UiKit.DIM

	if _day_only.is_empty():
		for child in get_children():
			if child is Control and child != _power and child != _ammo and child != _power_icon:
				_day_only.append(child as Control)
	for node in _day_only:
		node.visible = daylight
	visible = not House.inside(_state)

	if not daylight:
		return

	# The clock lives here now rather than in its own label on the other side
	# of the screen, where it sat on top of the resource grid.
	#
	# **`day_tick`, not `tick`.** The global counter never resets, so on day
	# three this read 12:00 and kept climbing - a clock measuring how long the
	# session had been running rather than how much of today is left, which is
	# the one thing it is for.
	#
	# **The hour, since task 0126**: 24-hour HH:MM off `Phases.clock_minute`,
	# wrapping after midnight - 01:30, never 25:30. Its own label in the
	# heading face since task 0140, tinted from dusk and in the warn colour
	# from the pass-out warning.
	var minute := Phases.clock_minute(_state)
	var late := minute >= GameData.PASS_OUT_WARNING_MINUTE
	_clock.text = I18n.f(&"DHUD_CLOCK", [(minute / 60) % 24, minute % 60])
	_clock.theme_type_variation = UiKit.CLOCK_LATE if late else UiKit.HEADING
	_clock.modulate = LIT_TINT if Phases.is_dusk(_state) and not late \
		else Color.WHITE
	# **The date, not a count of days** (task 0149): SPRING 3, one number
	# for the day.
	var today := Calendar.date(_state)
	_day.text = I18n.f(&"DHUD_DATE",
		[Names.of(Calendar.season_id(today)), Calendar.day_of_season(today)])
	var year := Calendar.year_of(today)
	_year.text = I18n.f(&"DHUD_YEAR", [year]) if year > 1 else ""
	_refresh_evening(minute, today)
	var money := Resources.amount(_state, GameData.MONEY)
	if force or money != _last_purse:
		if not force and _last_purse >= 0:
			_flash[GameData.MONEY] = FLASH_SECONDS
		_last_purse = money
		_money.text = I18n.f(&"DHUD_MONEY", [money])

	for id in _labels:
		var held := Resources.amount(_state, id)
		if not force and held == int(_last[id]):
			continue
		if not force and int(_last[id]) >= 0:
			_flash[id] = FLASH_SECONDS
		_last[id] = held
		(_labels[id] as Label).text = I18n.f(&"DHUD_HELD",
			[_short(id), held])

	# **The can, and where to fill it when it is empty.** A number on its own
	# would leave a player who has never found the well holding an empty can
	# with no idea why.
	var carried := Farming.water_carried(_state)
	_water.text = I18n.f(&"DHUD_WATER",
		[carried, GameData.WATER_CAN_CAPACITY]) \
		if carried > 0 else I18n.t(&"DHUD_WATER_EMPTY")
	_water.theme_type_variation = UiKit.WARM if carried > 0 \
		else UiKit.DIM

	# The chosen row is lit, so the strip answers "what am I about to plant"
	# without the player having to remember which key they last pressed.
	var chosen := Farming.selected_seed(_state)
	var seeds := Farming.in_season(_state)
	if chosen != _last_seed:
		_seed_page = maxi(seeds.find(chosen), 0) / SEED_ACTIONS.size()
		_last_seed = chosen
	for id in Farming.seeds():
		(_seed_rows[id] as Label).visible = false
	for i in seeds.size():
		var id: StringName = seeds[i]
		var row: Label = _seed_rows[id]
		row.position = Vector2(7, 46 + (i % SEED_ACTIONS.size()) * 10)
		row.text = I18n.f(&"DHUD_SEED_ROW", [i % SEED_ACTIONS.size() + 1, Names.of(id),
			(0 if _state.is_empty() else Resources.amount(_state, Farming.packet(id))), Farming.days_to_grow(id), Farming.value_per_season(id)])
		row.visible = daylight and i / SEED_ACTIONS.size() == _seed_page
		row.theme_type_variation = UiKit.WARM if id == chosen else UiKit.DIM

	# The theme arrives after _ready; shrink the default-font minimum again.
	_seed_previous.size = Vector2(50, 14)
	_seed_next.size = Vector2(50, 14)
	_seed_badge.text = I18n.t(&"DHUD_NO_SEEDS") if seeds.is_empty() else I18n.f(&"SEED_PAGE", [_seed_page + 1,
		ceili(float(seeds.size()) / SEED_ACTIONS.size())])
	_seed_badge.position.x = 7 if seeds.is_empty() else 77
	_seed_previous.visible = daylight and not seeds.is_empty()
	_seed_next.visible = daylight and not seeds.is_empty()
	_seed_previous.disabled = _seed_page == 0
	_seed_next.disabled = (_seed_page + 1) * SEED_ACTIONS.size() >= seeds.size()
	_seed_previous.text = I18n.t(&"SEED_PREVIOUS")
	_seed_next.text = I18n.t(&"SEED_NEXT")

	# **The line, while there is one.** Waiting says so quietly; a bite shouts,
	# because the window is a second and a half.
	_line.visible = daylight and Fishing.is_casting(_state)
	if _line.visible:
		var biting := Fishing.is_biting(_state)
		_line.text = I18n.t(&"DHUD_BITE") if biting \
			else I18n.t(&"DHUD_WAITING")
		_line.theme_type_variation = UiKit.WARM if biting else UiKit.DIM

	# **Past dusk the button asks.** It never presses itself: `design.md`
	# promises the player switches reality when they want to. It names the
	# night it starts - the one after the last won, which is not the day's
	# number once a night has been lost - and lights up from the reminder
	# hour (task 0140).
	_night.text = I18n.f(&"DHUD_NIGHT_WAITING", [Phases.night_ahead(_state)]) \
		if Phases.is_dusk(_state) else I18n.t(&"DHUD_TO_NIGHT")
	_night.theme_type_variation = UiKit.BED_LIT \
		if minute >= GameData.BEDTIME_REMINDER_MINUTE else UiKit.BED


## **The line under the date**: the calendar's by day, the evening's after.
##
## - By day, **the Full Moon** (task 0152, the plan's "Primavera 3 - Lua Cheia
##   em 4 dias"): FULL MOON IN 4 DAYS, and FULL MOON TONIGHT on the day.
##   It is up to 111 pixels and the date has 74 before the purse, so it has
##   this line rather than the date's.
## - From dusk (task 0140): dusk; then, from the reminder hour, a quiet time
##   for bed naming the GO TO BED key (0121's names, for the device in hand);
##   then, from the warning minute, the minutes left before he passes out, in
##   the warn colour.
## - A Full Moon tonight outranks dusk, and gives way to bedtime: by then the
##   only thing left to say about the night is to go to it. So does a calm
##   night (task 0154), CALM NIGHT on the first day of a season.
func _refresh_evening(minute: int, today: int) -> void:
	var text := ""
	var role := UiKit.DIM
	var moon := Calendar.days_to_full_moon(today)
	if minute >= GameData.PASS_OUT_WARNING_MINUTE:
		text = I18n.f(&"DHUD_PASS_OUT_SOON",
			[maxi(GameData.DAY_END_MINUTE - minute, 0)])
		role = UiKit.WARN
	elif minute >= GameData.BEDTIME_REMINDER_MINUTE:
		var actions := get_node_or_null(^"/root/Actions")
		text = I18n.f(&"DHUD_BEDTIME",
			[actions.text_of(&"night") if actions != null else ""])
	elif Calendar.is_calm(today):
		text = I18n.t(&"DHUD_CALM_TONIGHT")
		role = UiKit.GOOD
	elif moon == 0:
		text = I18n.t(&"DHUD_FULL_MOON_TONIGHT")
		role = UiKit.WARM
	elif Phases.is_dusk(_state):
		text = I18n.t(&"DHUD_DUSK")
	elif moon > 0:
		text = I18n.plural(&"DHUD_FULL_MOON_IN", moon, [moon])
	_status.text = text
	_status.theme_type_variation = role


## Say it all again in whatever language is up now.
##
## The strip of seeds and its heading are built once, so unlike everything
## else on this HUD they do not come back on their own.
func relabel() -> void:
	if _state.is_empty():
		return
	var heading := get_node_or_null(^"SeedHeading") as Label
	if heading != null:
		heading.text = I18n.t(&"DHUD_SEED_HEADING")
	var ids := Farming.seeds()
	for i in ids.size():
		var id: StringName = ids[i]
		if not _seed_rows.has(id):
			continue
		(_seed_rows[id] as Label).text = I18n.f(&"DHUD_SEED_ROW",
			[i % SEED_ACTIONS.size() + 1, Names.of(id),
			(0 if _state.is_empty() else Resources.amount(_state, Farming.packet(id))),
			Farming.days_to_grow(id), Farming.value_per_season(id)])
	show_state(_state)


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
		label.modulate = Color.WHITE.lerp(LIT_TINT, t)
	for id in done:
		_flash.erase(id)
		var label: Label = _money if id == GameData.MONEY else _labels[id]
		label.modulate = Color.WHITE


## Keep the localized whole word beside the compact icon.
##
## The first version of this abbreviated to three letters and produced "WOO",
## "STO" and "IRO" - which is not shorthand, it is a puzzle. At font size 9 the
## longest of these is forty pixels and the bar is four hundred and eighty.
func _short(id: StringName) -> String:
	return Names.of(id)


## Compact cuts keep their own native pixels in the existing eleven-pixel rows.
func _icon(id: StringName, at: Vector2) -> TextureRect:
	var image := TextureRect.new()
	image.name = "icon_%s" % id
	image.texture = UiKit.icon(id, true)
	image.position = at
	image.size = Vector2(10, 10)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP
	image.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(image)
	return image


func _label(node_name: String, at: Vector2,
		role: StringName = &"") -> Label:
	var label := Label.new()
	label.name = node_name
	label.position = at
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.theme_type_variation = role
	add_child(label)
	return label
