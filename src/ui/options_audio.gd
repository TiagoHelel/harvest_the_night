class_name OptionsAudio
extends Control

## The audio tab: four levels, a mute, and a sound on each of them.
##
## Like the video tab it owns no policy. `Audio` already had all of it - the
## four keys, which bus each turns, the rule that zero is silence rather than
## eighty decibels down, and re-applying on every change since task 0083. What
## was missing was somewhere to turn them.
##
## ## A number with no sound on it is a number nobody can set
##
## "Ambience 0.4" means nothing on its own: the only way to know whether it is
## right is to hear it against the other three. So letting go of a slider
## plays that slider's own bus, which is the difference between a settings
## screen and a form.
##
## ## Mute is not a zero slider
##
## They silence the same speaker and they are not the same thing. A zero
## slider is a level, and comes back as zero. Mute is a state over the top of
## whatever the levels are, and comes back to them - so the sliders stay live
## while muted, and the numbers stay on the screen rather than dropping to
## nought. `Audio.is_silent` is where that actually lives; this draws it.

## The four, in the order they belong in: the one that governs the others
## first, then loudest to quietest.
const KEYS: Array = [&"audio/master", &"audio/music", &"audio/sfx",
	&"audio/ambience"]

## What each is called on the screen. `audio/sfx` is "EFFECTS" because that is
## what the task calls it and what a player would.
const LABELS: Dictionary = {
	&"audio/master": &"AUD_MASTER",
	&"audio/music": &"AUD_MUSIC",
	&"audio/sfx": &"AUD_SFX",
	&"audio/ambience": &"AUD_AMBIENCE",
}

## Twenty notches across. Fine enough to find a level, coarse enough that a
## keyboard can cross the slider without holding the key down.
const STEP := 0.05

var _audio: Node
var _settings: Node

var _sliders: Dictionary = {}
var _readouts: Dictionary = {}
var _mute: Button
var _note: Label


func _ready() -> void:
	_audio = get_node_or_null(^"/root/Audio")
	_settings = get_node_or_null(^"/root/Settings")
	set_anchors_preset(Control.PRESET_FULL_RECT)
	if _settings != null:
		_settings.changed.connect(_on_setting)
		_settings.reloaded.connect(_fill)

	var column := VBoxContainer.new()
	column.name = "AudioColumn"
	column.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(column)

	for key in KEYS:
		_build_row(column, key)

	var muting := HBoxContainer.new()
	muting.name = "AudioMuteRow"
	muting.theme_type_variation = UiKit.SPACED
	column.add_child(muting)
	var label := Label.new()
	label.text = I18n.t(&"AUD_MUTE")
	label.custom_minimum_size = Vector2(76, 0)
	label.theme_type_variation = UiKit.DIM
	muting.add_child(label)
	_mute = Button.new()
	_mute.name = "AudioMute"
	_mute.toggle_mode = true
	_mute.custom_minimum_size = Vector2(40, 14)
	_mute.focus_mode = Control.FOCUS_ALL
	_mute.pressed.connect(_toggle_mute)
	muting.add_child(_mute)

	_note = Label.new()
	_note.name = "AudioNote"
	_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_note.custom_minimum_size = Vector2(330, 16)
	_note.theme_type_variation = UiKit.DIM
	column.add_child(_note)

	_fill()


func _build_row(column: VBoxContainer, key: StringName) -> void:
	var bare := String(key).get_slice("/", 1)
	var row := HBoxContainer.new()
	row.name = "Audio%sRow" % bare.capitalize()
	row.theme_type_variation = UiKit.SPACED
	column.add_child(row)

	var label := Label.new()
	label.text = I18n.t(LABELS[key])
	label.custom_minimum_size = Vector2(76, 0)
	label.theme_type_variation = UiKit.DIM
	row.add_child(label)

	var slider := HSlider.new()
	slider.name = "AudioLevel_%s" % bare
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = STEP
	slider.custom_minimum_size = Vector2(180, 12)
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.focus_mode = Control.FOCUS_ALL
	slider.value_changed.connect(_moved.bind(key))
	# **On release, not on every notch.** A slider dragged from nought to one
	# would otherwise fire twenty test sounds, and `Audio`'s same-frame dedupe
	# would not stop them because they are twenty different frames.
	slider.drag_ended.connect(_let_go.bind(key))
	row.add_child(slider)
	_sliders[key] = slider

	var readout := Label.new()
	readout.name = "AudioValue_%s" % bare
	readout.custom_minimum_size = Vector2(28, 0)
	readout.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(readout)
	_readouts[key] = readout


# ---------------------------------------------------------------- the state

func _fill() -> void:
	if _settings == null:
		return
	var muted := bool(_settings.get_bool(&"audio/muted"))
	for key in KEYS:
		var level := float(_settings.get_float(key))
		var slider: HSlider = _sliders[key]
		if not is_equal_approx(slider.value, level):
			slider.set_value_no_signal(level)
		var readout: Label = _readouts[key]
		readout.text = "%d%%" % int(round(level * 100.0))
		# **The numbers stay** while muted, faint rather than gone: they are
		# still what the game will sound like the moment it comes back.
		readout.theme_type_variation = UiKit.FAINT if muted else UiKit.DIM
	_mute.button_pressed = muted
	_mute.text = I18n.t(&"OPT_ON") if muted else I18n.t(&"OPT_OFF")
	_note.text = I18n.t(&"AUD_NOTE_MUTED" if muted else &"AUD_NOTE_TRY")


func _on_setting(key: StringName) -> void:
	if String(key).begins_with("audio/"):
		_fill()


# --------------------------------------------------------------- the clicks

func _moved(value: float, key: StringName) -> void:
	if _settings != null:
		_settings.set_value(key, snappedf(value, STEP))


## Letting go plays the bus that was being adjusted.
func _let_go(changed: bool, key: StringName) -> void:
	if not changed:
		return
	_audition(key)


## Unmuting says so out loud; muting has nothing to say.
func _toggle_mute() -> void:
	if _settings == null:
		return
	_settings.set_value(&"audio/muted", _mute.button_pressed)
	if not _mute.button_pressed:
		_audition(&"audio/master")


func _audition(key: StringName) -> void:
	if _audio == null:
		return
	var id: StringName = _audio.TEST_SOUNDS.get(key, &"")
	if id != &"":
		_audio.play(id)


# ----------------------------------------------------------- for the checks

func level_shown(key: StringName) -> float:
	var slider: HSlider = _sliders.get(key, null)
	return slider.value if slider != null else -1.0


func value_shown(key: StringName) -> String:
	var readout: Label = _readouts.get(key, null)
	return readout.text if readout != null else ""


func mute_showing() -> bool:
	return _mute != null and _mute.button_pressed


## Say it all again in whatever language is up now.
func relabel() -> void:
	if _mute == null:
		return
	for key in KEYS:
		var row := _sliders[key].get_parent() as HBoxContainer
		(row.get_child(0) as Label).text = I18n.t(LABELS[key])
	var muting := _mute.get_parent() as HBoxContainer
	(muting.get_child(0) as Label).text = I18n.t(&"AUD_MUTE")
	_fill()
