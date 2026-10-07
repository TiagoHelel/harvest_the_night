class_name OptionsA11y
extends OptionsPage

## The access page: the settings that decide whether somebody can play at all.
##
## Each row is one of `A11y`'s keys, and `headless_check` holds the two lists
## equal - a setting that exists is on this page, and a row on this page is a
## setting that exists. What each one does is `A11y`'s: this draws them and
## writes them.
##
## A row with a list of values steps through it; a row with none is a switch.

## Every row: the setting, its name, and the values it steps through - empty
## for a switch.
const ROWS: Array = [
	[&"a11y/screen_shake", &"ACC_SHAKE", [
		[0.0, &"ACC_OFF"], [0.5, &"ACC_HALF"], [1.0, &"ACC_FULL"]]],
	[&"a11y/flashing", &"ACC_FLASHING", []],
	[&"a11y/hit_stop", &"ACC_HIT_STOP", []],
	[&"a11y/particle_density", &"ACC_PARTICLES", [
		[0.0, &"ACC_OFF"], [0.5, &"ACC_HALF"], [1.0, &"ACC_FULL"]]],
	[&"a11y/ui_scale", &"ACC_PICTURE", [
		[1.0, &"ACC_SIZE_1"], [1.25, &"ACC_SIZE_2"], [1.5, &"ACC_SIZE_3"]]],
	[&"a11y/high_contrast", &"ACC_CONTRAST", []],
	[&"a11y/hold_to_act", &"ACC_HOLD", []],
	[&"a11y/slow", &"ACC_SLOW", [
		[1.0, &"ACC_SPEED_1"], [0.75, &"ACC_SPEED_2"],
		[0.5, &"ACC_SPEED_3"]]],
]

## settings key -> its row
var _rows: Dictionary = {}


func _init() -> void:
	var keys: Array = []
	for row in ROWS:
		keys.append((row as Array)[0])
	resets = keys
	title_key = &"OPT_TAB_ACCESS"


func _build() -> void:
	for row in ROWS:
		var key: StringName = (row as Array)[0]
		var values: Array = (row as Array)[2]
		var bare := String(key).get_slice("/", 1)
		if values.is_empty():
			_rows[key] = toggle_row("Access_%s" % bare, key)
		else:
			_rows[key] = choice_row("Access_%s" % bare,
				_step.bind(key, values), _shows.bind(key, values))


func relabel() -> void:
	if _rows.is_empty():
		return
	for row in ROWS:
		(_rows[(row as Array)[0]] as OptionRow).text = I18n.t((row as Array)[1])
	say(I18n.t(&"ACC_NOTE"))
	super()


func _step(delta: int, key: StringName, values: Array) -> void:
	if _settings == null:
		return
	var plain: Array = []
	for one in values:
		plain.append(float((one as Array)[0]))
	_settings.set_value(key, float(stepped(plain, float(_settings.get_float(key)), delta)))


func _shows(key: StringName, values: Array) -> String:
	var now := float(_settings.get_float(key)) if _settings != null else 0.0
	for one in values:
		if is_equal_approx(float((one as Array)[0]), now):
			return I18n.t((one as Array)[1])
	return str(now)


func _on_setting(key: StringName) -> void:
	if String(key).begins_with("a11y/"):
		refresh()


# ---------------------------------------------------------- for the checks

func rows_count() -> int:
	return ROWS.size()


## What a setting is on, as a number: the value for a list, 1 or 0 for a
## switch.
func chosen(key: StringName) -> float:
	if _settings == null:
		return -1.0
	for row in ROWS:
		if (row as Array)[0] != key:
			continue
		if ((row as Array)[2] as Array).is_empty():
			return 1.0 if bool(_settings.get_bool(key)) else 0.0
		return float(_settings.get_float(key))
	return -1.0
