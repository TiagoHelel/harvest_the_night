class_name GuardianCursor
extends Node2D

## **The guardian's hand** (task 0131): one farm cell, from the build step to
## the morning, that every night action points at.
##
## The pointer puts it on the cell under it; a pad's dpad and left stick - the
## `move_*` actions - step it a cell per press and repeat when held
## (`CURSOR_REPEAT_DELAY`, `CURSOR_REPEAT_RATE`). **The last device touched
## decides**, as 0121's glyphs do: a key or the mouse hands it back to the
## pointer, and then the move keys pan the camera (0130) instead of stepping.
##
## It owns no rules. `Main` reads `cell()` into `intent.build_cell` (and 0135's
## `ability_cell`), `BuildMode` puts its ghost there, and the look - neutral,
## place, blocked, and later upgrade, sell, repair, aim - is set from outside.
##
## Drawn above the night's ramp, on `WorldView`'s cue layer, so it reads over
## dark ground, and unlit: A004's art since task 0146 - each look a 16x16
## frame centred on the cell, a two-frame 0.4 s pulse, a small glyph in the
## top-right corner but on neutral and aim, and aim's plus in the middle.

## The seven looks, in A004's order. 0131 uses the first three.
const LOOKS: Array[StringName] = [&"neutral", &"place", &"blocked", &"upgrade",
	&"sell", &"repair", &"aim"]

## Where A004 delivers it.
const DIR := "res://sprites/ui/"

var _world: WorldView
var _active := false
var _cell := Vector2i(-1, -1)
var _look: StringName = &"neutral"
var _by_pad := false
## The pointer's last place in the viewport's own pixels, from the events:
## the display server does not follow a synthesised one (see `BuildMode`).
var _pointer := Vector2(-1, -1)
var _held := Vector2i.ZERO
## **How fast a held step repeats** (task 0292): `controls/cursor_speed`, a
## percent of `CURSOR_REPEAT_RATE` - 200 repeats twice as often. `Main` sets
## it from the setting; the first step and the delay before the repeat are
## the same at every speed.
var speed_percent := 100
var _repeat_left := 0.0
var _pulse := 0.0
## Whether the pointer moves it. Always, but for `shot.gd` (task 0139): its
## window lands wherever the desk has room, under whatever the desk's own
## mouse is doing, so a still puts the cursor by hand and keeps it there.
var follows_pointer := true
## Each frame's texture, held for `_draw` (task 0146).
var _textures: Dictionary = {}


func setup(world: WorldView) -> void:
	_world = world
	visible = false


## On in the build step and the night, off otherwise. Switched on, it starts
## where the player is looking: the pointer's cell, or the middle of the view.
func set_active(on: bool) -> void:
	if on == _active:
		return
	_active = on
	visible = on
	_held = Vector2i.ZERO
	_armed = false
	if on and _world != null:
		var at := _pointer if follows_pointer and _pointer.x >= 0.0 and not _by_pad \
			else _world.get_viewport_rect().size * 0.5
		_put(_world.screen_to_cell(at))


func is_active() -> bool:
	return _active


func cell() -> Vector2i:
	return _cell


## Whether a pad is driving it - which is also whether the move keys step it
## rather than pan the camera.
func by_pad() -> bool:
	return _by_pad


func look() -> StringName:
	return _look


## **A power's aim** (task 0135's flare; every power since 0233). A night
## HUD button arms it with its power; the next confirm fires that power at the
## cursor and `cancel` disarms. While it is armed, or a power's key is held,
## with that power ready, the cursor draws the power's reach
## (`reach_tiles`): the flare's and the dog's squares round the cell, a
## Chebyshev square measured the way `Ability` measures it, the repair's own
## cell, and nothing for the bell, which reaches the whole farm.
var _armed := false
var _armed_power: StringName = Ability.FLARE
var _aiming := false
var _aiming_power: StringName = Ability.FLARE


func arm(power: StringName = Ability.FLARE) -> void:
	if _active:
		_armed = true
		_armed_power = power


func disarm() -> void:
	_armed = false


func is_armed() -> bool:
	return _armed


## The power a button armed, or `&""`.
func armed_power() -> StringName:
	return _armed_power if _armed else &""


## Whether a reach is drawn, and whose - `Main` says, from the buttons and
## the keys.
func set_aiming(on: bool, power: StringName = Ability.FLARE) -> void:
	if on != _aiming or power != _aiming_power:
		_aiming = on
		_aiming_power = power
		queue_redraw()


func is_aiming() -> bool:
	return _aiming


## The power whose reach is drawn, while one is.
func aiming_power() -> StringName:
	return _aiming_power if _aiming else &""


## An armed power's confirm: aim it at the cursor and let it go. The cell as
## it is at the press, like `confirm_repair`.
func confirm_power(state: Dictionary, event: InputEvent) -> bool:
	if not _active or not _armed or state.is_empty():
		return false
	if not (event.is_action_pressed(&"place") or event.is_action_pressed(&"interact")):
		return false
	press(state, _armed_power, _cell)
	_armed = false
	return true


## **A power's press at `cell`** (task 0233): the aim and the intent the rules
## read - the flare's `ability`, which it has had since task 0054, or another
## power's id in `power`. The one road the confirm and the keys take.
static func press(state: Dictionary, power: StringName, cell: Vector2i) -> void:
	var intent: Dictionary = state["intent"]
	intent["ability_cell"] = [cell.x, cell.y]
	if power == Ability.FLARE:
		intent["ability"] = true
	else:
		intent["power"] = power


## **A power's reach round the cursor**, in tiles: the flare's and the dog's
## squares, the repair's one cell (0), and -1 for the bell, whose reach is the
## whole farm - nothing to draw.
static func reach_tiles(power: StringName) -> int:
	match power:
		Ability.FLARE:
			return int(GameData.ABILITY["radius_tiles"])
		Ability.CALL_DOG:
			return int((GameData.POWERS[Ability.CALL_DOG] as Dictionary)["radius_tiles"])
		Ability.EMERGENCY_REPAIR:
			return 0
	return -1


## `cancel` while armed puts the power away rather than doing anything else.
func cancel_aim(event: InputEvent) -> bool:
	if _armed and event.is_action_pressed(&"cancel"):
		_armed = false
		return true
	return false


## **What a confirm on this cell mends** (task 0134): the anchor of whatever
## stands there - a multi-cell building mends from any part of it - when
## `Repair` says it can be mended now, or (-1, -1). The one rule both the
## repair look and the confirm read.
static func mend_target(state: Dictionary, cell_at: Vector2i) -> Vector2i:
	if state.is_empty() or not Grid.in_bounds(cell_at):
		return Vector2i(-1, -1)
	# **A ruin is mended where it lies** (task 0277): one cell, nothing on it.
	if Farm.occupant(state, cell_at).is_empty():
		return cell_at if not Farm.ruin_at(state, cell_at).is_empty() \
			and Repair.can_mend(state, cell_at) else Vector2i(-1, -1)
	var anchor := Building.anchor_of(state, cell_at)
	return anchor if Repair.can_mend(state, anchor) else Vector2i(-1, -1)


## A confirm on something to mend: write `repair_cell` there and say so, or
## say no and leave it to whoever else wants the press. `BuildMode` asks first
## while it is up, `Main` otherwise. **The cell as it is at the press**, not
## as the look last drew it: a click that moves the cursor onto the house is a
## click on the house (`_input` puts the cell there first).
func confirm_repair(state: Dictionary, event: InputEvent) -> bool:
	if not _active:
		return false
	if not (event.is_action_pressed(&"place") or event.is_action_pressed(&"interact")):
		return false
	var at := mend_target(state, _cell)
	if at.x < 0:
		return false
	(state["intent"] as Dictionary)["repair_cell"] = [at.x, at.y]
	return true


func set_look(value: StringName) -> void:
	if value != _look and LOOKS.has(value):
		_look = value
		queue_redraw()


## Put it on a cell - the shots' hook, and where a stepped cursor lands.
func place_at(cell_at: Vector2i) -> void:
	_put(cell_at)


## The middle of its cell, in world pixels.
func centre() -> Vector2:
	return (Vector2(_cell) + Vector2.ONE * 0.5) * float(GameData.TILE_SIZE)


## One frame: the pointer's cell, or the pad's steps. `step` is the move
## axes, -1, 0 or 1 a side.
func advance(seconds: float, step: Vector2i) -> void:
	if not _active:
		return
	var before := int(_pulse / _pulse_seconds())
	_pulse += maxf(seconds, 0.0)
	if int(_pulse / _pulse_seconds()) != before:
		queue_redraw()
	if not _by_pad:
		_held = Vector2i.ZERO
		if follows_pointer and _pointer.x >= 0.0 and _world != null:
			_put(_world.screen_to_cell(_pointer))
		return
	if step == Vector2i.ZERO:
		_held = Vector2i.ZERO
		return
	if step != _held:
		_held = step
		_put(_cell + step)
		_repeat_left = GameData.CURSOR_REPEAT_DELAY
		return
	_repeat_left -= maxf(seconds, 0.0)
	while _repeat_left <= 0.0:
		_put(_cell + step)
		_repeat_left += maxf(GameData.CURSOR_REPEAT_RATE * 100.0
			/ float(maxi(speed_percent, 1)), 0.01)


func _put(cell_at: Vector2i) -> void:
	var clamped := Vector2i(clampi(cell_at.x, 0, GameData.GRID_WIDTH - 1),
		clampi(cell_at.y, 0, GameData.GRID_HEIGHT - 1))
	if clamped != _cell:
		_cell = clamped
		position = centre()
		queue_redraw()


## The device the player last touched. Read, never consumed.
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		_pointer = (event as InputEventMouse).position
		_by_pad = false
		# A press lands on the cell under it now, before anything that
		# handles the press asks where the cursor is (task 0134).
		if event is InputEventMouseButton and _active and _world != null \
				and follows_pointer:
			_put(_world.screen_to_cell(_pointer))
	elif event is InputEventKey:
		_by_pad = false
	elif event is InputEventJoypadButton:
		_by_pad = true
	elif event is InputEventJoypadMotion:
		if absf((event as InputEventJoypadMotion).axis_value) >= 0.5:
			_by_pad = true


func _pulse_seconds() -> float:
	return maxf(float(PlaceholderArt.frame(path_of(&"neutral", 0)).get("seconds", 0.4)), 0.05)


## One look's frame `index`, by its runtime path.
static func path_of(look_name: StringName, index: int) -> String:
	return "%scursor_%s_%d.png" % [DIR, look_name, index]


## Which of its two frames is up.
func frame() -> int:
	return int(_pulse / _pulse_seconds()) % 2


## The frame that is up, by its runtime path - for the tests.
func shown() -> String:
	return path_of(_look, frame())


func _draw() -> void:
	if not _active or _cell.x < 0:
		return
	if _aiming:
		_draw_reach()
	var path := shown()
	var pivot := Vector2(PlaceholderArt.frame(path).get("pivot", Vector2i(8, 8)))
	# Held here: a texture loaded inside `_draw` and let go is freed before
	# the frame renders.
	if not _textures.has(path):
		_textures[path] = load(path) if ResourceLoader.exists(path) else null
	if _textures[path] != null:
		draw_texture(_textures[path], -pivot)


## **A power's reach** (task 0135's flare; 0233's powers): every cell within
## `reach_tiles` of the cursor's, Chebyshev, so the square is exactly what
## `Ability` reaches - none for the bell. Code, like the range ring and the
## route preview - A004 draws the cursor, not this. Cells off the farm are
## left out, as the powers leave them.
func reach_cells(power: StringName = Ability.FLARE) -> Array:
	var radius := reach_tiles(power)
	var out: Array = []
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			var at := _cell + Vector2i(dx, dy)
			if Grid.in_bounds(at):
				out.append(at)
	return out


func _draw_reach() -> void:
	var tile := float(GameData.TILE_SIZE)
	if reach_tiles(_aiming_power) < 0:
		return
	var radius := float(reach_tiles(_aiming_power))
	var moon: Color = PaletteData.COLOURS[&"moon"]
	var box := Rect2(Vector2.ONE * -(radius + 0.5) * tile, Vector2.ONE * (radius * 2.0 + 1.0) * tile)
	draw_rect(box, Color(moon, 0.10), true)
	draw_rect(box, Color(moon, 0.75), false, 1.0)
