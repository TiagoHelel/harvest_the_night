class_name NightHud
extends Control

## What is on screen after dark: `design.md` section 14, built for the guardian
## rather than for a farmer in the yard (task 0139).
##
## Which night, which wave, the time to dawn, how the house is doing, what a
## confirm does at the cursor, and the controls the guardian has. It comes up
## with the build step and goes with the night, and it holds no game state of
## its own - every number is a lookup, the same rule the day HUD follows, so
## the bar and the ledger cannot drift.
##
## ## The layout
##
## - **The strip, top:** the night, its date (task 0158: the season's mark,
##   SPRING 3, the year from Year 2 and the night's own marks), the wave, how
##   many are left and the dawn countdown on the first row; the house bar and
##   its numbers on the second, with the mode hint at its right end. In the
##   build step the night ahead, its date, the house and the hint are up; the
##   wave, the count and the countdown wait for the waves. The boss bar stays
##   under the strip, where it was. The forecast (`ForecastPanel`) stands
##   under the strip's right end in the build step.
## - **The hotbar, bottom** (task 0133, its own node).
## - **The bar, bottom right:** START across it in the build step; the flare
##   with its charge, the speed and SKIP during the waves.
## - **A005's 10x10 pictures** (task 0147): START's horn, the flare and the
##   speed's chevrons on their buttons, the setting moon before the time to
##   dawn, and before the hint's words the defence it names - or the flare,
##   when it aims one. The HUD is never relit, so they keep their colours.
##
## ## Why it is its own node
##
## The day HUD is `MOUSE_FILTER_IGNORE` across the whole screen and sits at the
## bottom of the UI's child order. Task 0055 tried to put two buttons in its
## bottom-right corner and they could not be clicked - not the button-height
## trap, which was there too: a bare `MOUSE_FILTER_STOP` control anywhere in
## that corner of `DayHud` reported no hover at all, while the night button
## four pixels away hovered perfectly well.
##
## This panel is a sibling **after** the day HUD in the scene, so it is above
## it in the hit order, and its buttons live in a stopping frame the way
## `BuildMode`'s palette does. That is the arrangement the rest of the UI
## already uses for things that are clicked.
##
## ## A pad reaches every control
##
## START has L3 (`start_waves`), the flare RT (`ability`) and the hotbar the
## bumpers. **The bar is reached by focus**: the night key - Back on a pad, N
## on the keyboard, idle after dark - puts the focus on its first live button,
## the D-pad or the stick moves along it, A presses, and B or the night key
## again hands the pad back to the cursor. While the bar has the focus the
## cursor holds still and a held A places nothing (`holds_focus`).
##
## ## What it does not own
##
## The power and ammunition lines stay on the day HUD. They have been up in
## both phases since task 0033 and their comments say why; moving them would
## have given two panels an opinion about the same number, which is the thing
## "sharing no state" is actually guarding against. The speed and skip keys
## are read there too, beside the night key.

## **The strip's first row**: the night, then the season's mark and the date
## (task 0158 made room for them, the wave and the count moving right), then
## the wave, the count and dawn. The night's own marks follow the date.
const SEASON_MARK_AT := Vector2(58, 3)
const DATE_AT := Vector2(70, 2)
const WAVE_AT := Vector2(206, 2)
const LEFT_AT := Vector2(268, 2)

## The bar of controls, bottom right: right of the hotbar, which stops at 326.
const BAR_AT := Vector2(330, 248)
const BAR_SIZE := Vector2(146, 18)
## The bar in the waves: the flare, the speed, SKIP. Not thirds since the
## flare and the speed wear their pictures (task 0147): a picture and the
## theme's gap take 14 px of a button, so the flare widens for its 29 px of
## FLARE and the speed narrows round its 17 of `%dx`.
const FLARE_SIZE := Vector2(54, 16)
const SPEED_SIZE := Vector2(38, 16)
const BUTTON_SIZE := Vector2(46, 16)
## START has the bar to itself in the build step.
const START_SIZE := Vector2(146, 16)

## The night bar's own pictures (A005, task 0147), drawn 10x10: START's horn,
## the flare, the speed's chevrons and the setting moon of the time to dawn.
const ICONS: Array = [&"start", &"flare", &"speed", &"dawn_moon"]
## The setting moon, just left of the countdown.
const DAWN_MOON_AT := Vector2(348, 3)
## Between a picture and the words it goes with.
const PICTURE_GAP := 2.0

## The house bar's width. 128 since task 0139, from 160, to make room for
## the hint; 96 since task 0219, for the essence held beside the house's
## numbers. Still the widest thing in the strip.
const HOUSE_BAR := 96.0

## The mode hint, at the right end of the strip's second row: right of the
## house numbers, left of the screen's edge, never over the hotbar. Room for
## the widest it says - the Portuguese mend hint for the auto crossbow on a
## mouse, 231 px in the game's font; `_case_0139_night_hud` measures them all.
const HINT_AT := Vector2(220, 12)
const HINT_SIZE := Vector2(256, 11)

## The bar's buttons carry this group, so `BuildMode` can tell that a held A
## belongs to one of them.
const BAR_GROUP := &"night_bar"

var _state: Dictionary = {}

## The driver, for the speed and skip controls. Set by `main.gd`; this panel
## asks it to do things and never reaches into the state to do them.
var driver: SimDriver

## The guardian's cursor, which the FLARE button arms (task 0135) and the
## mode hint reads (task 0139). Set by `main.gd`, like the driver.
var cursor: GuardianCursor

var _strip: ColorRect
var _night: Label
var _season_mark: CalendarMark
var _date: Label
var _night_marks: Array[CalendarMark] = []
var _wave: Label
var _left: Label
var _house_back: ColorRect
var _house_fill: ColorRect
var _house_text: Label
## **The essence held** (task 0219, plan section 9): the tree's currency, by
## its icon - the tech icon through 0120's road until A036 - and a number.
var _essence_icon: TextureRect
var _essence: Label
var _hint: Label
## The picture of what the hint names (task 0147).
var _hint_icon: TextureRect
var _announce: Label
var _boss_back: ColorRect
var _boss_fill: ColorRect
var _boss_name: Label
var _bar: Control
var _start: Button
var _dawn: Label
var _dawn_moon: TextureRect
var _flare: Button
var _speed: Button
var _skip: Button

## How far through a pulse the danger bar is. View-only: it is driven by
## `delta` and never read by anything that matters.
var _pulse := 0.0


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)

	_strip = ColorRect.new()
	_strip.name = "NightStrip"
	_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_strip.color = Color(0.04, 0.03, 0.08, 0.78)
	_strip.position = Vector2.ZERO
	_strip.size = Vector2(480, 24)
	add_child(_strip)

	_night = _label("NightNumber", Vector2(4, 2), UiKit.WARM)
	# **The date beside the night** (task 0158, moved here from 0151): the
	# season's mark and SPRING 3 - from Year 2 the year after it - in the
	# build step and through the waves, so the plan's 'season, night and
	# wave' is all on the strip. A Full Moon, a boss or a calm night puts its
	# mark after the date.
	_season_mark = CalendarMark.new()
	_season_mark.name = "NightSeasonMark"
	add_child(_season_mark)
	_season_mark.setup(&"spring", true)
	_season_mark.position = SEASON_MARK_AT
	_date = _label("NightDate", DATE_AT, UiKit.DIM)
	for which in [&"full_moon", &"boss_night", &"calm_night"]:
		var mark := CalendarMark.new()
		mark.name = "NightMark_%s" % which
		add_child(mark)
		mark.setup(which, true)
		mark.visible = false
		_night_marks.append(mark)
	_wave = _label("WaveCounter", WAVE_AT, UiKit.WARM)
	_left = _label("ZombiesLeft", LEFT_AT, UiKit.DIM)
	# **The time left to dawn** (task 0137): a countdown and never a wall clock
	# - after a pass-out a 22:00-06:00 mapping would lie.
	_dawn = _label("DawnCountdown", Vector2(360, 2), UiKit.WARM)
	# **And the moon setting before it** (A005, task 0147).
	_dawn_moon = _picture("DawnMoon", &"hud_dawn_moon", DAWN_MOON_AT)

	# **The house bar, and it is the biggest thing up there.** A number is easy
	# to miss and this is the one that ends the run.
	_house_back = ColorRect.new()
	_house_back.name = "HouseBarBack"
	_house_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_house_back.color = Color(0.18, 0.10, 0.12, 0.9)
	_house_back.position = Vector2(4, 14)
	_house_back.size = Vector2(HOUSE_BAR, 7)
	add_child(_house_back)

	_house_fill = ColorRect.new()
	_house_fill.name = "HouseBar"
	_house_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_house_fill.color = UiKit.colour(UiKit.GOOD)
	_house_fill.position = Vector2(5, 15)
	_house_fill.size = Vector2(HOUSE_BAR - 2.0, 5)
	add_child(_house_fill)

	_house_text = _label("HouseNumbers", Vector2(HOUSE_BAR + 10.0, 12), UiKit.DIM)

	# **The essence held**, right after the house's numbers and left of the
	# hint, on the strip's second row (task 0219).
	_essence_icon = TextureRect.new()
	_essence_icon.name = "EssenceIcon"
	_essence_icon.texture = UiKit.icon(GameData.TECH, true)
	_essence_icon.size = Vector2(10, 10)
	_essence_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_essence_icon.stretch_mode = TextureRect.STRETCH_KEEP
	_essence_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_essence_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_essence_icon)
	_essence = _label("EssenceHeld", Vector2(0, 12), UiKit.WARM)

	# **What a confirm does now** (task 0139): the cursor's look in words.
	_hint = _label("ModeHint", HINT_AT, UiKit.WARM)
	_hint.size = HINT_SIZE
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint.clip_text = true
	# **And what it names, by its picture** (A005, task 0147): just left of the
	# words, which move with the language and the device.
	_hint_icon = _picture("ModeHintIcon", &"", HINT_AT)

	# **The boss gets a bar of its own.** Nine nights of building are being
	# tested by one thing, and a number in a corner is not how that should
	# read.
	_boss_back = ColorRect.new()
	_boss_back.name = "BossBarBack"
	_boss_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_back.color = Color(0.14, 0.06, 0.10, 0.92)
	_boss_back.position = Vector2(120, 30)
	_boss_back.size = Vector2(240, 9)
	_boss_back.visible = false
	add_child(_boss_back)

	_boss_fill = ColorRect.new()
	_boss_fill.name = "BossBar"
	_boss_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_fill.color = Color(0.86, 0.26, 0.30)
	_boss_fill.position = Vector2(121, 31)
	_boss_fill.size = Vector2(238, 7)
	_boss_fill.visible = false
	add_child(_boss_fill)

	_boss_name = _label("BossName", Vector2(120, 40), UiKit.WARM)
	_boss_name.visible = false

	# **The announcement, in the middle, where you are already looking.**
	_announce = _label("WaveWarning", Vector2(0, 92), UiKit.HEADING)
	_announce.size = Vector2(480, 12)
	_announce.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_announce.visible = false

	_build_controls()


## The controls, in a frame that stops the mouse.
func _build_controls() -> void:
	_bar = Control.new()
	_bar.name = "NightBar"
	_bar.mouse_filter = Control.MOUSE_FILTER_STOP
	_bar.position = BAR_AT
	_bar.size = BAR_SIZE
	add_child(_bar)

	# **No REPAIR here since task 0134**: the guardian's cursor mends whatever
	# it confirms on. START has the bar in the build step (task 0136); the
	# flare, the speed and SKIP share it during the waves. START, the flare
	# and the speed wear their pictures left of their words (task 0147); the
	# pack has none for SKIP, which keeps its word alone.
	_start = _button("StartButton", I18n.t(&"NHUD_START"), Vector2(0, 1),
		START_SIZE)
	_start.icon = UiKit.picture(&"hud_start")
	_start.pressed.connect(_do_start)
	_flare = _button("FlareButton", I18n.t(&"NHUD_FLARE"), Vector2(0, 1),
		FLARE_SIZE)
	_flare.icon = UiKit.picture(&"hud_flare")
	_flare.pressed.connect(_do_flare)
	_speed = _button("SpeedButton", I18n.f(&"NHUD_SPEED", [1]),
		Vector2(FLARE_SIZE.x + 4.0, 1), SPEED_SIZE)
	_speed.icon = UiKit.picture(&"hud_speed")
	_speed.pressed.connect(_do_speed)
	# **SKIP is a button now** (task 0139), and when the rules refuse it the
	# reason is its tooltip - on the pointer and on the pad's focus alike.
	_skip = _button("SkipButton", I18n.t(&"NHUD_SKIP"), Vector2(100, 1))
	_skip.pressed.connect(_do_skip)

	# **Along the bar and round again, never off it**: up and down stay put,
	# so a pad on the bar cannot wander into the hotbar.
	var row: Array[Button] = [_flare, _speed, _skip]
	for i in row.size():
		var here: Button = row[i]
		here.focus_neighbor_left = NodePath("../" + String(row[(i + row.size() - 1) % row.size()].name))
		here.focus_neighbor_right = NodePath("../" + String(row[(i + 1) % row.size()].name))
		here.focus_neighbor_top = NodePath(".")
		here.focus_neighbor_bottom = NodePath(".")
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		_start.set_focus_neighbor(side, NodePath("."))


## A button that is the size it is told to be.
##
## **A default `Button` reserves thirty-one pixels of height** whatever its
## `size` says: the theme's stylebox has content margins and the minimum size
## is computed from them. On a 270-pixel screen that is a control hanging off
## the bottom edge, and the project has walked into it three times now - the
## build palette at 0032, the shop rows at 0040 and the speed control at 0055.
## Styleboxes with the vertical margins taken out are the fix.
func _button(node_name: String, text: String, at: Vector2,
		box: Vector2 = BUTTON_SIZE) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = text
	button.focus_mode = Control.FOCUS_ALL
	button.clip_text = true
	button.add_to_group(BAR_GROUP)
	_bar.add_child(button)
	button.position = at
	button.size = box
	button.custom_minimum_size = box
	return button


func _label(node_name: String, at: Vector2,
		role: StringName = &"") -> Label:
	var label := Label.new()
	label.name = node_name
	label.position = at
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.theme_type_variation = role
	add_child(label)
	return label


## One of A005's 10x10 pictures (task 0147), drawn at its native size - or an
## empty box, for `_hint_icon`'s picture to come.
func _picture(node_name: String, picture: StringName, at: Vector2) -> TextureRect:
	var image := TextureRect.new()
	image.name = node_name
	image.texture = UiKit.picture(picture) if picture != &"" else null
	image.position = at
	image.size = Vector2(10, 10)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP
	image.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(image)
	return image


# ---------------------------------------------------------------- the frame

func show_state(state: Dictionary) -> void:
	_state = state


func _process(delta: float) -> void:
	if _state.is_empty():
		return
	var phase := int(_state["phase"])
	var after_dark := phase == Phases.NIGHT
	var building := phase == Phases.PREPARATION
	visible = after_dark or building
	if not visible:
		return
	# **The build step has the strip too** (task 0139): the night ahead, the
	# house it starts with and what a confirm will do. The wave, the count
	# and the countdown wait for the waves, and so do their controls.
	for node in [_wave, _left, _dawn, _dawn_moon]:
		(node as CanvasItem).visible = after_dark
	_start.visible = building
	_flare.visible = after_dark
	_speed.visible = after_dark
	_skip.visible = after_dark
	_pulse += delta
	_refresh_house()
	_refresh_hint()
	_refresh_date(Phases.night_ahead(_state) if building else int(_state["night"]))
	if building:
		_night.text = I18n.f(&"NHUD_NIGHT", [Phases.night_ahead(_state)])
		_announce.visible = false
		for node in [_boss_back, _boss_fill, _boss_name]:
			(node as CanvasItem).visible = false
		_refresh_start()
		return
	_refresh()


func _refresh() -> void:
	_night.text = I18n.f(&"NHUD_NIGHT", [int(_state["night"])])

	var at: Array = Waves.progress(_state)
	_wave.text = I18n.f(&"NHUD_WAVE", [int(at[0]), int(at[1])])
	_left.text = I18n.f(&"NHUD_LEFT", [Waves.remaining(_state)])
	# Never more than a whole night (a parked one has its dawn out of reach).
	# Since task 0153 dawn ends a boss night too, so nothing holds it at 0:00.
	var to_dawn := mini(Phases.ticks_to_dawn(_state), GameData.NIGHT_TICKS)
	var dawn_seconds := ceili(float(to_dawn) / float(GameData.SECONDS))
	_dawn.text = I18n.f(&"NHUD_DAWN", [dawn_seconds / 60, dawn_seconds % 60])

	# **A wave is announced before it arrives**, with the seconds on it, so
	# the player knows whether there is time to mend the wall first.
	var coming := Waves.incoming_in(_state)
	var warn := coming > 0 and coming <= GameData.WAVE_WARNING_TICKS
	_announce.visible = warn
	if warn:
		var seconds := (coming + GameData.TICK_HZ - 1) / GameData.TICK_HZ
		_announce.text = I18n.f(&"NHUD_INCOMING", [mini(int(at[0]) + 1,
			int(at[1])), seconds])
		# The pulse is an alpha rather than a second colour: the label is
		# already the heading colour and blinking it to a different hue
		# would be two things changing at once.
		_announce.modulate = Color.WHITE if fmod(_pulse, 0.6) < 0.3 \
			else Color(1, 1, 1, 0.5)

	_refresh_boss()
	_refresh_controls()


## **The date of the night on the strip** (task 0158): its season's mark,
## SPRING 3 and from Year 2 the year, then the night's own marks - read off
## the calendar, whose rules made the record (`Calendar.is_full_moon`...).
func _refresh_date(night: int) -> void:
	var season := Calendar.season_id(night)
	if _season_mark.mark != season:
		_season_mark.setup(season, true)
	var text := I18n.f(&"DHUD_DATE", [Names.of(season), Calendar.day_of_season(night)])
	var year := Calendar.year_of(night)
	if year > 1:
		text += "  " + I18n.f(&"DHUD_YEAR", [year])
	_date.text = text
	var x := DATE_AT.x + _date.get_minimum_size().x + 3.0
	var flags := [Calendar.is_full_moon(night), Calendar.is_boss_night(night),
		Calendar.is_calm(night)]
	for i in _night_marks.size():
		var mark: CalendarMark = _night_marks[i]
		mark.visible = bool(flags[i])
		if mark.visible:
			mark.position = Vector2(x, SEASON_MARK_AT.y)
			x += CalendarMark.HUD + 2.0


## The date as the strip says it - for `input_v1` and the shots.
func date_text() -> String:
	return _date.text


## The essence the strip shows, for `input_v1` and the shots.
func essence_text() -> String:
	return _essence.text


## Where the strip's date and marks end, in its own pixels.
func date_end() -> float:
	var end := DATE_AT.x + _date.get_minimum_size().x
	for mark in _night_marks:
		if mark.visible:
			end = maxf(end, mark.position.x + mark.size.x)
	return end


## **The house bar.** Width is the fraction, colour is the warning, and the
## pulse is what makes it impossible to look past.
func _refresh_house() -> void:
	var hp := int(_state["house_hp"])
	# The house the night started with, 'stout timbers' and all (task 0114).
	var full := maxi(Phases.house_full(_state), 1)
	var share := clampf(float(hp) / float(full), 0.0, 1.0)
	_house_fill.size = Vector2(maxf((HOUSE_BAR - 2.0) * share, 0.0), 5.0)
	_house_text.text = I18n.f(&"NHUD_HOUSE", [hp, full])
	# The essence follows the numbers, whatever the language made them.
	var after := _house_text.position.x + _house_text.get_minimum_size().x + 5.0
	_essence_icon.position = Vector2(after, 13)
	_essence.position = Vector2(after + 12.0, 12)
	_essence.text = str(Tech.held(_state))

	var in_danger := hp * 100 / full < GameData.HOUSE_DANGER_PERCENT
	if in_danger:
		# Half a second on, half a second off, at full brightness. A colour
		# change alone is a thing you can be looking away from.
		var lit := fmod(_pulse, 1.0) < 0.5
		var bad := UiKit.colour(UiKit.BAD)
		_house_fill.color = bad if lit else bad.darkened(0.45)
		_house_text.theme_type_variation = UiKit.BAD
		_house_back.color = Color(0.32, 0.10, 0.12, 0.95) if lit \
			else Color(0.18, 0.10, 0.12, 0.9)
	else:
		_house_fill.color = UiKit.colour(UiKit.GOOD)
		_house_text.theme_type_variation = UiKit.DIM
		_house_back.color = Color(0.18, 0.10, 0.12, 0.9)


## **What a confirm does now** (task 0139), following the cursor's look -
## place, upgrade, sell, repair or aim - with the key or the pad glyph that
## does it: 0121's names, for the device in hand. Nothing over open ground or
## a refusal: the tooltip under the cursor says what and why not.
func _refresh_hint() -> void:
	var text := ""
	var named := &""
	var actions := get_node_or_null(^"/root/Actions")
	if cursor != null and cursor.is_active() and actions != null:
		var cell := cursor.cell()
		match cursor.look():
			&"place":
				named = Building.selected(_state)
				text = I18n.f(&"NHUD_HINT_PLACE", [_confirm_key(actions),
					Names.of(named)])
			&"upgrade":
				named = _id_at(cell)
				text = I18n.f(&"NHUD_HINT_UPGRADE", [actions.text_of(&"upgrade"),
					_name_at(cell)])
			&"sell":
				named = _id_at(cell)
				text = I18n.f(&"NHUD_HINT_SELL", [actions.text_of(&"remove"),
					_name_at(cell)])
			&"repair":
				var mended := GuardianCursor.mend_target(_state, cell)
				named = _id_at(mended)
				text = I18n.f(&"NHUD_HINT_REPAIR", [_confirm_key(actions),
					_name_at(mended)])
			&"aim":
				named = &"flare"
				text = I18n.f(&"NHUD_HINT_AIM", [_confirm_key(actions)])
	_hint.text = text
	_hint.visible = not text.is_empty()
	_refresh_hint_icon(named)


## **The hint's picture** (A005, task 0147): the 10x10 cut of the defence it
## names - or the flare's, when it aims - just left of the words, which are
## pushed against the strip's right edge. Nothing for what has no picture.
func _refresh_hint_icon(named: StringName) -> void:
	var picture: Texture2D = null
	if _hint.visible and (GameData.DEFENCES.has(named) or named == &"flare"):
		picture = UiKit.picture(StringName("hud_%s" % named))
	_hint_icon.texture = picture
	_hint_icon.visible = picture != null
	if picture == null:
		return
	# A stand-in's own tint (task 0225's bait, the fish rotted green); white
	# for real art.
	_hint_icon.modulate = PlaceholderArt.art_tint(StringName("hud_%s" % named))
	_hint_icon.position = Vector2(floorf(hint_words_at())
		- PICTURE_GAP - _hint_icon.size.x, HINT_AT.y + 1.0)


## Where the hint's words begin, in the HUD's pixels: they are pushed against
## the right edge of its box. For the picture, `input_v1` and the shots.
func hint_words_at() -> float:
	var font := _hint.get_theme_font(&"font")
	var wide := 0.0 if font == null else font.get_string_size(_hint.text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, _hint.get_theme_font_size(&"font_size")).x
	var box := _hint.get_theme_stylebox(&"normal")
	var margin := 0.0 if box == null else box.get_margin(SIDE_RIGHT)
	return HINT_AT.x + HINT_SIZE.x - margin - wide


## The confirm, for the device in hand: the click on a mouse - the cursor is
## where the pointer is - and A on a pad (`interact`, task 0133).
static func _confirm_key(actions: Node) -> String:
	return actions.text_of(&"interact") if bool(actions.get(&"using_pad")) \
		else actions.text_of(&"place")


## What stands on a cell - the whole of it, whichever part is pointed at.
func _name_at(cell: Vector2i) -> String:
	if not Grid.in_bounds(cell):
		return ""
	var on := Farm.occupant(_state, Building.anchor_of(_state, cell))
	return Names.of(StringName(on.get("id", &"")))


## And its id, for its picture: nothing off the farm.
func _id_at(cell: Vector2i) -> StringName:
	if not Grid.in_bounds(cell):
		return &""
	var on := Farm.occupant(_state, Building.anchor_of(_state, cell))
	return StringName(on.get("id", &""))


## The boss bar, up only while there is one on the farm.
func _refresh_boss() -> void:
	var boss := Combat.boss_here(_state)
	var here := boss != 0
	_boss_back.visible = here
	_boss_fill.visible = here
	_boss_name.visible = here
	if not here:
		return
	var one := Entities.get_one(_state, boss)
	var kind: StringName = one.get("kind", &"")
	var full := maxi(int((GameData.ENEMIES[kind] as Dictionary)["hp"]), 1)
	var share := clampf(float(int(one.get("hp", 0))) / float(full), 0.0, 1.0)
	_boss_fill.size = Vector2(maxf(238.0 * share, 0.0), 7.0)
	_boss_name.text = I18n.f(&"NHUD_BOSS", [Names.of(kind).to_upper(),
		int(one.get("hp", 0)), full])
	# **And it flashes while it is winding up**, which is the second the
	# player has to do something about the blow.
	if Enemies.is_winding(_state, boss):
		_boss_name.theme_type_variation = UiKit.BAD \
			if fmod(_pulse, 0.3) < 0.15 else UiKit.WARM
		_boss_fill.color = Color(1.0, 0.72, 0.30)
	else:
		_boss_name.theme_type_variation = UiKit.WARM
		_boss_fill.color = Color(0.86, 0.26, 0.30)


func _refresh_controls() -> void:
	# **The flare**, with its wait on it rather than a bare "no". Disabled is
	# enough: the theme draws a disabled button in ink_soft with faint letters.
	var charge := Ability.charge_percent(_state, Ability.FLARE)
	_flare.disabled = not Ability.ready(_state, Ability.FLARE)
	_flare.text = I18n.t(&"NHUD_FLARE") if not _flare.disabled \
		else I18n.f(&"NHUD_FLARE_CHARGE", [charge])

	_speed.text = I18n.f(&"NHUD_SPEED",
		[driver.speed if driver != null else 1])

	# **SKIP, and why not** (task 0139): dead while the rules refuse it, with
	# the refusal as its tooltip; what it does while they do not.
	var refused := Sim.why_not_skip(_state)
	_skip.disabled = not refused.is_empty()
	# Its word every frame, like the flare's: a language chosen after the
	# HUD was built is the one it speaks.
	_skip.text = I18n.t(&"NHUD_SKIP")
	Tooltip.describes(_skip, StringName("text:" + (I18n.t(&"NHUD_SKIP_TIP")
		if refused.is_empty() else Names.refusal(refused))))


# --------------------------------------------------------------- the presses

## **Every one of these writes an intent or asks the driver.** None of them
## changes the state itself, so the button, the key and the autoplayer of task
## 0067 all take the same road into the rules.
## START (task 0136): the build step waits for it.
func _do_start() -> void:
	if not _state.is_empty():
		(_state["intent"] as Dictionary)["start_waves"] = true


## START's label: plain after going to bed, a countdown after a pass-out,
## when the horde is at the gate and the night starts by itself.
func _refresh_start() -> void:
	var timer := Phases.build_step_ticks(_state)
	if timer <= 0:
		_start.text = I18n.t(&"NHUD_START")
		return
	var left := maxi(timer - int(_state["phase_tick"]), 0)
	_start.text = I18n.f(&"NHUD_START_IN",
		[ceili(float(left) / float(GameData.SECONDS))])


func _do_flare() -> void:
	# **Armed, not fired** (task 0135): the flare goes where it is aimed, so
	# the button hands the aim to the cursor and the next confirm lets it go.
	if not _state.is_empty() and cursor != null and Ability.ready(_state, Ability.FLARE):
		cursor.arm()
	# Let go of the focus, so a pad's next A confirms at the cursor rather
	# than pressing the button again.
	_flare.release_focus()


func _do_speed() -> void:
	if driver != null:
		driver.cycle_speed()


## Run the rest of the night now; the rules refuse it below
## `SKIP_MIN_HOUSE_PERCENT`, and then this does nothing.
func _do_skip() -> void:
	if driver != null:
		driver.skip_night()


# ------------------------------------------------------------- the pad's way

## The night key toggles the bar's focus, and cancel leaves it. In `_input`,
## so B on the bar is never also the pause menu.
func _input(event: InputEvent) -> void:
	if not visible or _state.is_empty():
		return
	if event.is_action_pressed(&"night"):
		if holds_focus():
			leave_bar()
		else:
			focus_bar()
		get_viewport().set_input_as_handled()
	elif holds_focus() and event.is_action_pressed(&"cancel"):
		leave_bar()
		get_viewport().set_input_as_handled()
	elif holds_focus() and event.is_action_pressed(&"interact"):
		# **A presses the button the pad is on.** Godot's own `ui_accept` is
		# Enter and Space and no pad button at all, so the confirm is read
		# here - once, for every device - and goes no further.
		var on := get_viewport().gui_get_focus_owner() as Button
		if on != null and not on.disabled:
			on.pressed.emit()
		get_viewport().set_input_as_handled()


## Put the focus on the bar's first live button.
func focus_bar() -> void:
	for button in [_start, _flare, _speed, _skip]:
		var it: Button = button
		if it.is_visible_in_tree() and not it.disabled:
			it.grab_focus()
			return


## Hand the pad back to the cursor.
func leave_bar() -> void:
	if holds_focus():
		get_viewport().gui_get_focus_owner().release_focus()


## Whether one of the bar's buttons has the focus: then the cursor holds
## still, and a held A is the button's (`Main`, `BuildMode`).
func holds_focus() -> bool:
	if not is_inside_tree():
		return false
	var owner := get_viewport().gui_get_focus_owner()
	return owner != null and owner.is_in_group(BAR_GROUP)


## The mode hint as it reads now - for `input_v1` and the shots.
func hint_text() -> String:
	return _hint.text if _hint.visible else ""
