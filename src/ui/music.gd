class_name Music
extends Node

## Decides which of the two pieces is playing, and when the night gets urgent.
##
## **It owns no rules and holds no audio.** It reads the phase and the wave
## count and tells `Audio` what it wants; `Audio` owns the crossfade. That
## split is the same one everywhere in `src/ui/`, and it is what lets the
## three decisions below be static functions a check can ask directly rather
## than infer from what came out of a speaker.
##
## ## The crossfade is the transition's own length
##
## Task 0086's done-when is that the crossfade lands *with* the switch of
## reality, not before or after it. So the length is not a number here: it is
## `WorldView.transition_seconds()`, which is the number the screen fades on -
## `GameData.TRANSITION_SECONDS` unless the player has overridden it in
## `video/transition_seconds`. One number, read from where it already lives,
## and `headless_check` asserts the two are the same rather than trusting
## them to stay that way.
##
## ## What plays when
##
## Day is the farm; preparation, night and the result screen are the night.
## **The result keeps the night's music** on purpose: the payout is read with
## the night still in the air, and snapping to the farm the instant the last
## zombie fell would take the weight out of having survived. The music turns
## over when the day does, which is also when the screen does.

const FARM := &"music/farm"
const NIGHT := &"music/night"
const INTENSITY := &"music/night_intensity"

## Whether a menu is up. **Nothing sets this yet**: task 0091 is the title
## screen and 0092 the router, and they are what will. The rule is here now
## because task 0086 asks for it, and it is asserted now so that 0091 gets a
## failing check rather than a silent nothing if it forgets to set it.
var in_menu := false

var _state: Dictionary = {}
var _world: WorldView = null
var _audio: Node = null


func show_state(state: Dictionary, world: WorldView) -> void:
	_state = state
	_world = world


func _ready() -> void:
	# By path and never by name: `verify.py` parses each script on its own
	# with no autoloads registered.
	_audio = get_node_or_null(^"/root/Audio")


func _process(_delta: float) -> void:
	if _audio == null or _state.is_empty():
		return
	var seconds := fade_seconds()
	_audio.play_music(piece_for(int(_state["phase"]), in_menu,
		_menus_play()), seconds)
	_audio.set_layer(layer_for(int(_state["phase"]), _waves()), seconds)


## How long a change of music takes: exactly as long as the screen takes.
func fade_seconds() -> float:
	if _world != null:
		return _world.transition_seconds()
	return GameData.TRANSITION_SECONDS


# -------------------------------------------------------------- the decisions

## Which piece belongs to a moment.
##
## Static, so that a check can ask "what plays in a menu" without building a
## game first - the same reason `Audio.is_silent` and `Audio.loudness` are.
static func piece_for(phase: int, menu: bool, menus_play: bool) -> StringName:
	if menu:
		# **Off in menus by default, and it is a setting.** A title screen
		# that starts a tune before the player has decided whether they want
		# one is a title screen people mute.
		return FARM if menus_play else &""
	if phase == Phases.DAY:
		return FARM
	return NIGHT


## Whether the urgent layer is wanted.
##
## **On the last wave, and only at night.** `wave` counts from one and `waves`
## is how many there are tonight, which is what `Waves.progress` hands back.
## A night with no waves in its table gets nothing rather than getting the
## layer for the whole of it.
static func layer_for(phase: int, progress: Array) -> StringName:
	if phase != Phases.NIGHT or progress.size() != 2:
		return &""
	var wave := int(progress[0])
	var waves := int(progress[1])
	if waves <= 0 or wave < waves:
		return &""
	return INTENSITY


func _waves() -> Array:
	return Waves.progress(_state)


func _menus_play() -> bool:
	var settings := get_node_or_null(^"/root/Settings")
	if settings == null:
		return false
	return bool(settings.get_bool(&"audio/music_in_menus"))
