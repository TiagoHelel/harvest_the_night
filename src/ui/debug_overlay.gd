extends CanvasLayer

## What you actually want on screen while tuning: what phase, what tick, what
## seed, what the player has, and what the last frame cost.
##
## **It reads and never writes.** Every number here comes out of the core state
## or out of `SimDriver`'s measurements; nothing on this overlay can change the
## game, which is what makes "toggling it does not move the determinism hash"
## true by construction rather than by care. `input_check` asserts it anyway.
##
## **Not in a release build.** `_ready()` frees the whole node when the build is
## not a debug one, so there is no key combination a player can find and no
## per-frame cost in a shipped game.
##
## Off by default, toggled with the `debug_overlay` action - F3 until task 0095
## makes it rebindable.

## Above everything. The HUDs of tasks 0021 and 0056 sit below this.
const LAYER := 128

## How often the text is rebuilt. Every frame would make the overlay itself the
## most expensive thing on screen, which would be a funny way to measure
## performance.
const REFRESH_EVERY := 0.1          # seconds

@export var driver_path: NodePath

var _driver: SimDriver
var _label: Label
var _until_refresh := 0.0


func _ready() -> void:
	# A player should not be able to find this, and a shipped build should not
	# pay for it: in a release export the whole node goes away, so there is no
	# key combination that reveals it and no per-frame cost at all.
	if not OS.is_debug_build():
		queue_free()
		return

	layer = LAYER
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS    # still readable while paused

	# Named, because a node added in code without one gets an internal
	# `@PanelContainer@2` that nothing can reliably find - including
	# input_check, which is the point of naming things.
	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.position = Vector2(4, 4)

	# **The theme's quiet frame, not a flat box of its own.** An earlier note
	# here argued the overlay should look the same whatever the theme does; it
	# wears `OVERLAY` instead, which is the tooltip frame - still quieter than
	# a game panel, still solid enough to read digits over a lit farm, and now
	# one edit away rather than one file away. The theme has asserts on it,
	# which is the robustness the old note actually wanted.
	panel.theme_type_variation = UiKit.OVERLAY
	add_child(panel)

	_label = Label.new()
	_label.name = "Readout"
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(_label)

	if driver_path != NodePath():
		_driver = get_node_or_null(driver_path)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"debug_overlay"):
		visible = not visible
		if visible:
			_refresh()
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if not visible:
		return
	_until_refresh -= delta
	if _until_refresh <= 0.0:
		_until_refresh = REFRESH_EVERY
		_refresh()


## Point it at the driver whose game it should describe. The overlay does not
## go looking: a screen owns its driver and hands it over, so two of them on
## screen at once would still each describe their own.
func watch(driver: SimDriver) -> void:
	_driver = driver


func _refresh() -> void:
	if _label == null:
		return
	if _driver == null or _driver.state.is_empty():
		_label.text = "no simulation"
		return

	var state: Dictionary = _driver.state
	var lines: Array = []

	lines.append("%s  day %d  night %d" % [
		Phases.name_of(int(state["phase"])),
		int(state["day"]),
		int(state["night"]),
	])
	lines.append("tick %d   phase %d   day %d   night %d" % [
		int(state["tick"]), int(state["phase_tick"]),
		int(state["day_tick"]), int(state["night_tick"]),
	])
	lines.append("seed %d   rng %s" % [int(state["seed"]), str(state["rng"])])

	lines.append("")
	lines.append("%.1f fps   x%d   %d ticks/frame" % [
		Engine.get_frames_per_second(), _driver.speed, _driver.last_ticks,
	])
	lines.append("sim %.2f ms   %.1f us/tick   peak %.2f ms" % [
		_driver.last_usec / 1000.0,
		_driver.usec_per_tick(),
		_driver.peak_usec / 1000.0,
	])

	lines.append("")
	lines.append(_resource_line(state))

	lines.append("")
	lines.append(_occupant_line(state))

	_label.text = "\n".join(lines)


## What the player has, only counting what they have any of - twelve zeroes
## would push everything worth reading off the bottom.
func _resource_line(state: Dictionary) -> String:
	var parts: Array = []
	for id in GameData.RESOURCES:
		var n := Resources.amount(state, id)
		if n != 0:
			parts.append("%s %d" % [id, n])
	return "held: " + (", ".join(parts) if not parts.is_empty() else "nothing")


## Everything standing on the farm, by kind. Trees and rocks today; zombies,
## towers and walls as tasks 0024 and 0025 add them, without this file changing.
func _occupant_line(state: Dictionary) -> String:
	var counts := {}
	for idx in (state["occupants"] as Dictionary):
		var id: StringName = (state["occupants"][idx] as Dictionary)["id"]
		counts[id] = int(counts.get(id, 0)) + 1
	# Occupant ids are StringNames, and `Array.sort()` puts those in pointer
	# order rather than alphabetical - a tally that reshuffles itself between
	# two runs of the same farm. `sorted_names` is the one to use.
	var keys: Array = GameData.sorted_names(counts.keys())
	var parts: Array = []
	for id in keys:
		parts.append("%s %d" % [id, counts[id]])
	return "on the farm: " + ", ".join(parts)
