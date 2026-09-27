extends Control

## The boot screen.
##
## It exists to prove the project runs, to say which build is running, and - now
## that task 0002 has landed - to show the clock actually ticking. Task 0091
## replaces it with the title screen and task 0092 puts a router in front of
## both; until then this is the whole game.

## Any seed would do here. It is written down rather than taken from the system
## clock so that two boots of the prototype show the same numbers, which is the
## habit the whole codebase is built on.
const BOOT_SEED := 20260927

@onready var _title: Label = %Title
@onready var _version: Label = %Version
@onready var _pitch: Label = %Pitch
@onready var _clock: Label = %Clock
@onready var _driver: SimDriver = %SimDriver
@onready var _debug: CanvasLayer = %DebugOverlay


func _ready() -> void:
	_title.text = BuildInfo.GAME_NAME
	_version.text = BuildInfo.short()
	_pitch.text = "the farm is the fortress"
	print(BuildInfo.line())

	_driver.ticked.connect(_on_ticked)
	_driver.start(BOOT_SEED)

	# The overlay is handed its driver rather than going looking for one: a
	# screen owns its simulation, and two on screen at once would still each
	# describe their own.
	if is_instance_valid(_debug) and _debug.has_method("watch"):
		_debug.watch(_driver)
	_show(_driver.state)


func _on_ticked(state: Dictionary) -> void:
	_show(state)


func _show(state: Dictionary) -> void:
	var tick: int = int(state.get("tick", 0))
	_clock.text = "%s %d   tick %d   %d:%02d" % [
		Phases.name_of(int(state.get("phase", 0))),
		int(state.get("day", 1)),
		tick,
		tick / (GameData.TICK_HZ * 60),
		(tick / GameData.TICK_HZ) % 60,
	]
