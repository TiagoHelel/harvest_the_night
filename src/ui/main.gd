extends Control

## The game screen.
##
## It owns the simulation, hands it to the world view to draw and to the debug
## overlay to describe, and keeps the clock in the corner. Task 0091 puts a
## title screen in front of it and task 0092 a router above both; until then
## this is the whole game.

## Any seed would do here. It is written down rather than taken from the system
## clock so that two boots of the prototype show the same numbers, which is the
## habit the whole codebase is built on.
const BOOT_SEED := 20260927

@onready var _clock: Label = %Clock
@onready var _world: WorldView = %WorldView
@onready var _driver: SimDriver = %SimDriver
@onready var _debug: CanvasLayer = %DebugOverlay


func _ready() -> void:
	print(BuildInfo.line())

	_driver.ticked.connect(_on_ticked)
	_driver.start(BOOT_SEED)

	_world.show_state(_driver.state)
	_world.look_at_cell(Farm.house_centre(_driver.state))

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
	_clock.text = "%s %d   %d:%02d" % [
		Phases.name_of(int(state.get("phase", 0))),
		int(state.get("day", 1)),
		tick / (GameData.TICK_HZ * 60),
		(tick / GameData.TICK_HZ) % 60,
	]
