class_name NightHud
extends Control

## What is on screen after dark: `design.md` section 14.
##
## Which night, which wave, how the house is doing, and the three things the
## player can do about it. It comes up when the night does and goes away with
## it, and it holds no game state of its own - every number is a lookup, the
## same rule the day HUD follows, so the bar and the ledger cannot drift.
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
## ## What it does not own
##
## The power and ammunition lines stay on the day HUD. They have been up in
## both phases since task 0033 and their comments say why; moving them would
## have given two panels an opinion about the same number, which is the thing
## "sharing no state" is actually guarding against.

## Colours, matched to the reference sheet's night.

## The three controls, bottom right, in the order `design.md` draws them.
const BUTTON_SIZE := Vector2(46, 16)

var _state: Dictionary = {}

## The driver, for the speed control. Set by `main.gd`; this panel asks it to
## do things and never reaches into the state to do them.
var driver: SimDriver

var _strip: ColorRect
var _night: Label
var _wave: Label
var _left: Label
var _house_back: ColorRect
var _house_fill: ColorRect
var _house_text: Label
var _announce: Label
var _boss_back: ColorRect
var _boss_fill: ColorRect
var _boss_name: Label
var _bar: Control
var _repair: Button
var _flare: Button
var _speed: Button

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
	_wave = _label("WaveCounter", Vector2(120, 2), UiKit.WARM)
	_left = _label("ZombiesLeft", Vector2(240, 2), UiKit.DIM)

	# **The house bar, and it is the biggest thing up there.** A number is easy
	# to miss and this is the one that ends the run.
	_house_back = ColorRect.new()
	_house_back.name = "HouseBarBack"
	_house_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_house_back.color = Color(0.18, 0.10, 0.12, 0.9)
	_house_back.position = Vector2(4, 14)
	_house_back.size = Vector2(160, 7)
	add_child(_house_back)

	_house_fill = ColorRect.new()
	_house_fill.name = "HouseBar"
	_house_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_house_fill.color = UiKit.colour(UiKit.GOOD)
	_house_fill.position = Vector2(5, 15)
	_house_fill.size = Vector2(158, 5)
	add_child(_house_fill)

	_house_text = _label("HouseNumbers", Vector2(170, 12), UiKit.DIM)

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


## The three controls, in a frame that stops the mouse.
func _build_controls() -> void:
	_bar = Control.new()
	_bar.name = "NightBar"
	_bar.mouse_filter = Control.MOUSE_FILTER_STOP
	_bar.position = Vector2(330, 248)
	_bar.size = Vector2(146, 18)
	add_child(_bar)

	_repair = _button("RepairButton", I18n.t(&"NHUD_REPAIR"),
		Vector2(0, 1))
	_repair.pressed.connect(_do_repair)
	_flare = _button("FlareButton", I18n.t(&"NHUD_FLARE"),
		Vector2(50, 1))
	_flare.pressed.connect(_do_flare)
	_speed = _button("SpeedButton", I18n.f(&"NHUD_SPEED", [1]),
		Vector2(100, 1))
	_speed.pressed.connect(_do_speed)


## A button that is the size it is told to be.
##
## **A default `Button` reserves thirty-one pixels of height** whatever its
## `size` says: the theme's stylebox has content margins and the minimum size
## is computed from them. On a 270-pixel screen that is a control hanging off
## the bottom edge, and the project has walked into it three times now - the
## build palette at 0032, the shop rows at 0040 and the speed control at 0055.
## Styleboxes with the vertical margins taken out are the fix.
func _button(node_name: String, text: String, at: Vector2) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = text
	button.focus_mode = Control.FOCUS_ALL
	_bar.add_child(button)
	button.position = at
	button.size = BUTTON_SIZE
	button.custom_minimum_size = BUTTON_SIZE
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


# ---------------------------------------------------------------- the frame

func show_state(state: Dictionary) -> void:
	_state = state


func _process(delta: float) -> void:
	if _state.is_empty():
		return
	var after_dark := int(_state["phase"]) == Phases.NIGHT
	visible = after_dark
	if not after_dark:
		return
	_pulse += delta
	_refresh()


func _refresh() -> void:
	_night.text = I18n.f(&"NHUD_NIGHT", [int(_state["night"])])

	var at: Array = Waves.progress(_state)
	_wave.text = I18n.f(&"NHUD_WAVE", [int(at[0]), int(at[1])])
	_left.text = I18n.f(&"NHUD_LEFT", [Waves.remaining(_state)])

	# **The house bar.** Width is the fraction, colour is the warning, and the
	# pulse is what makes it impossible to look past.
	var hp := int(_state["house_hp"])
	# The house the night started with, 'stout timbers' and all (task 0114).
	var full := maxi(Phases.house_full(_state), 1)
	var share := clampf(float(hp) / float(full), 0.0, 1.0)
	_house_fill.size = Vector2(maxf(158.0 * share, 0.0), 5.0)
	_house_text.text = I18n.f(&"NHUD_HOUSE", [hp, full])

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
	# **Repair**, lit when the cell the player is facing can actually be
	# mended. The button is the key: it writes the same intent.
	var target := Player.target(_state)
	var can_mend := Interact.verb_at(_state, target) == &"repair"
	# **Disabled is enough.** The theme draws a disabled button in ink_soft
	# with faint letters, so the grey the old `modulate` added was the same
	# thing said twice.
	_repair.disabled = not can_mend

	# **The flare**, with its wait on it rather than a bare "no".
	var charge := Ability.charge_percent(_state)
	_flare.disabled = not Ability.ready(_state)
	_flare.text = I18n.t(&"NHUD_FLARE") if not _flare.disabled \
		else I18n.f(&"NHUD_FLARE_CHARGE", [charge])

	_speed.text = I18n.f(&"NHUD_SPEED",
		[driver.speed if driver != null else 1])


# --------------------------------------------------------------- the presses

## **Every one of these writes an intent or asks the driver.** None of them
## changes the state itself, so the button, the key and the autoplayer of task
## 0067 all take the same road into the rules.
func _do_repair() -> void:
	if not _state.is_empty():
		(_state["intent"] as Dictionary)["interact"] = true


func _do_flare() -> void:
	if not _state.is_empty():
		(_state["intent"] as Dictionary)["ability"] = true


func _do_speed() -> void:
	if driver != null:
		driver.cycle_speed()
