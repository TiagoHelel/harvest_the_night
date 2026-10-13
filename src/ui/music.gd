class_name Music
extends Node

## Decides which piece is playing, and when the night gets urgent.
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
## Day is the season's piece; preparation, night and the result screen are
## the night's. **The result keeps the night's music** on purpose: the payout
## is read with the night still in the air, and snapping to the farm the
## instant the last zombie fell would take the weight out of having survived.
## The music turns over when the day does, which is also when the screen does.
##
## ## A year of it (task 0285)
##
## - **Each season's day has its piece** on the shared motif: spring is the
##   MVP's `farm`, kept under its id, then summer, autumn and winter. The
##   season turns on the first morning of the new season, because that is
##   when the calendar does.
## - **Winter has its own night**; the other three keep the MVP's.
## - **A boss night plays the boss track** from its build step to dawn. The
##   morning report is the night's again: the boss is down, or held over.
## - **The credits** take over on 0160's ending screen and play once.
## - **No urgent layer over the boss track.** The layer was written over the
##   night piece - its pulse and its rising figure are what the night lacks -
##   and the boss track already has both, every bar of the night. Stacked, the
##   last wave of a boss night would be two pulses in one key fighting.

const FARM := &"music/farm"
const SUMMER := &"music/summer"
const AUTUMN := &"music/autumn"
const WINTER := &"music/winter"
const NIGHT := &"music/night"
const WINTER_NIGHT := &"music/winter_night"
const BOSS := &"music/boss"
const CREDITS := &"music/credits"
const INTENSITY := &"music/night_intensity"

## Each season's day (task 0285), by the calendar's season id.
const DAY_PIECES := {
	&"spring": FARM,
	&"summer": SUMMER,
	&"autumn": AUTUMN,
	&"winter": WINTER,
}

## **Every piece that loops** - held to the seam, the motif and the one tempo
## - and the one that plays once.
const LOOPS: Array = [FARM, SUMMER, AUTUMN, WINTER, NIGHT, WINTER_NIGHT, BOSS, INTENSITY]
const PLAYS_ONCE: Array = [CREDITS]

## Task 0094: a second of it, for auditioning the music level. Not
## something `piece_for` ever returns - the options screen plays it by
## hand, and it is named here so there is one spelling of it.
const STING := &"music/sting"

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
	var phase := int(_state["phase"])
	var boss_night := Calendar.is_boss_night(Phases.night_ahead(_state))
	var piece := piece_for(phase, in_menu, _menus_play(),
		Calendar.season_id(Calendar.date(_state)), boss_night,
		phase == Phases.RESULT and Run.is_over(_state))
	_audio.play_music(piece, seconds, not PLAYS_ONCE.has(piece))
	_audio.set_layer(layer_for(phase, _waves(), boss_night), seconds)


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
##
## Since task 0285 it also takes the season (0149's calendar id), whether the
## night ahead is a boss night (0153) and whether the ending screen is up
## (0160); each defaults to what the MVP's two pieces assumed.
static func piece_for(phase: int, menu: bool, menus_play: bool,
		season: StringName = &"spring", boss_night: bool = false,
		ending: bool = false) -> StringName:
	if menu:
		# **Off in menus by default, and it is a setting.** A title screen
		# that starts a tune before the player has decided whether they want
		# one is a title screen people mute. When it plays, it is spring's.
		return FARM if menus_play else &""
	if ending:
		return CREDITS
	if phase == Phases.DAY:
		return DAY_PIECES.get(season, FARM)
	if boss_night and (phase == Phases.PREPARATION or phase == Phases.NIGHT):
		return BOSS
	return WINTER_NIGHT if season == &"winter" else NIGHT


## Whether the urgent layer is wanted.
##
## **On the last wave, and only at night.** `wave` counts from one and `waves`
## is how many there are tonight, which is what `Waves.progress` hands back.
## A night with no waves in its table gets nothing rather than getting the
## layer for the whole of it.
##
## **Never on a boss night** (task 0285): the boss track already carries the
## pulse and the climb the layer adds to the night.
static func layer_for(phase: int, progress: Array, boss_night: bool = false) -> StringName:
	if phase != Phases.NIGHT or progress.size() != 2 or boss_night:
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
