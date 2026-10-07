class_name OptionsAudio
extends OptionsPage

## The audio page: four levels and a mute.
##
## **One row per bus, and the bus is heard as it moves.** A level is a number
## nobody can judge in silence, so each one plays its own test sound - the
## sound that bus carries - a moment after the level stops moving, so a run of
## twenty steps is one sound and not twenty. Which sound is `Audio`'s
## (`TEST_SOUNDS`); this only says when.
##
## **Mute keeps the levels.** It is a switch over the top of them, not four
## sliders sent to zero - turning it off brings back exactly the mix that was
## there, which is what anybody who muted for a phone call wants.

## The levels this page shows, in the order it shows them.
const KEYS: Array = [&"audio/master", &"audio/music", &"audio/sfx",
	&"audio/ambience"]

const LABELS: Dictionary = {
	&"audio/master": &"AUD_MASTER",
	&"audio/music": &"AUD_MUSIC",
	&"audio/sfx": &"AUD_SFX",
	&"audio/ambience": &"AUD_AMBIENCE",
}

## One step of a level: twenty steps from silent to full.
const STEP := 0.05

## How long a level has to stop moving before its test sound plays.
const SETTLE_SECONDS := 0.35

var _audio: Node
var _levels: Dictionary = {}
var _mute: OptionRow

## The level waiting to be heard, and how long until it is.
var _audition_key := &""
var _audition_left := 0.0


func _init() -> void:
	resets = KEYS + [&"audio/muted"]
	title_key = &"OPT_TAB_AUDIO"


func _build() -> void:
	_audio = get_node_or_null(^"/root/Audio")
	for key in KEYS:
		var bare := String(key).get_slice("/", 1)
		_levels[key] = slider_row("Audio_%s" % bare, _step_level.bind(key),
			_level_text.bind(key), _level.bind(key))
	_mute = toggle_row("AudioMute", &"audio/muted")


func relabel() -> void:
	if _mute == null:
		return
	for key in KEYS:
		(_levels[key] as OptionRow).text = I18n.t(LABELS[key])
	_mute.text = I18n.t(&"AUD_MUTE")
	super()


func refresh() -> void:
	super()
	if _mute == null or _settings == null:
		return
	var muted := bool(_settings.get_bool(&"audio/muted"))
	for key in KEYS:
		(_levels[key] as OptionRow).urgent = false
	say(I18n.t(&"AUD_NOTE_MUTED" if muted else &"AUD_NOTE_TRY"))


func _process(delta: float) -> void:
	if _audition_key == &"":
		return
	_audition_left -= delta
	if _audition_left <= 0.0:
		var key := _audition_key
		_audition_key = &""
		_audition(key)


func _step_level(delta: int, key: StringName) -> void:
	if _settings == null:
		return
	var level := clampf(_level(key) + STEP * float(delta), 0.0, 1.0)
	_settings.set_value(key, snappedf(level, STEP))
	_audition_key = key
	_audition_left = SETTLE_SECONDS


func _level(key: StringName) -> float:
	return float(_settings.get_float(key)) if _settings != null else 0.0


func _level_text(key: StringName) -> String:
	return "%d%%" % int(round(_level(key) * 100.0))


## Play the sound a bus carries, so a level is heard rather than read.
func _audition(key: StringName) -> void:
	if _audio == null:
		return
	var id: StringName = _audio.TEST_SOUNDS.get(key, &"")
	if id != &"":
		_audio.play(id)


func _on_setting(key: StringName) -> void:
	if String(key).begins_with("audio/"):
		refresh()


# ---------------------------------------------------------- for the checks

func level_shown(key: StringName) -> float:
	return _level(key) if _levels.has(key) else -1.0


func value_shown(key: StringName) -> String:
	var row: OptionRow = _levels.get(key, null)
	return row.value_text() if row != null else ""


func mute_showing() -> bool:
	return _settings != null and bool(_settings.get_bool(&"audio/muted"))


## Which level is waiting to be heard, for a check that wants to watch it.
func auditioning() -> StringName:
	return _audition_key
