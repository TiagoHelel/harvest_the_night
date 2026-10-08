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
## dark ground. Until A004 lands it is a code-drawn outline in A004's geometry
## (`PlaceholderArt.ART`): four L brackets on the cell edge, 5 px arms 2 px
## thick (the state's colour outside, `ink` inside), stepping 1 px in on the
## second frame of a 0.4 s pulse, a small glyph replacing the top-right one.

## The seven looks, in A004's order. 0131 uses the first three.
const LOOKS: Array[StringName] = [&"neutral", &"place", &"blocked", &"upgrade",
	&"sell", &"repair", &"aim"]

## Each look's colour, from A004's table.
const COLOURS := {&"neutral": &"bone", &"place": &"grass_light",
	&"blocked": &"roof_light", &"upgrade": &"water_light", &"sell": &"gold_light",
	&"repair": &"flame", &"aim": &"moon"}

## The stand-in glyphs, 5x5 in the top-right corner (x 10..14, y 1..5).
## Neutral and aim have none and keep all four brackets.
const GLYPHS := {
	&"place": ["..#..", "..#..", "#####", "..#..", "..#.."],
	&"blocked": ["#...#", ".#.#.", "..#..", ".#.#.", "#...#"],
	&"upgrade": ["..#..", ".###.", "#.#.#", "..#..", "..#.."],
	&"sell": [".###.", "#...#", "#.#.#", "#...#", ".###."],
	&"repair": ["####.", "####.", ".#...", ".#...", ".#..."],
}

var _world: WorldView
var _active := false
var _cell := Vector2i(-1, -1)
var _look: StringName = &"neutral"
var _by_pad := false
## The pointer's last place in the viewport's own pixels, from the events:
## the display server does not follow a synthesised one (see `BuildMode`).
var _pointer := Vector2(-1, -1)
var _held := Vector2i.ZERO
var _repeat_left := 0.0
var _pulse := 0.0
## Whether the pointer moves it. Always, but for `shot.gd` (task 0139): its
## window lands wherever the desk has room, under whatever the desk's own
## mouse is doing, so a still puts the cursor by hand and keeps it there.
var follows_pointer := true


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


## **The flare's aim** (task 0135). The night HUD's FLARE button arms it; the
## next confirm fires at the cursor and `cancel` disarms. While it is armed,
## or the ability key is held, with the flare ready, the cursor draws the
## flare's reach: `ABILITY.radius_tiles` round the cell, a Chebyshev square,
## measured the way `Ability.use` measures it.
var _armed := false
var _aiming := false


func arm() -> void:
	if _active:
		_armed = true


func disarm() -> void:
	_armed = false


func is_armed() -> bool:
	return _armed


## Whether the reach is drawn - `Main` says, from the button and the key.
func set_aiming(on: bool) -> void:
	if on != _aiming:
		_aiming = on
		queue_redraw()


func is_aiming() -> bool:
	return _aiming


## An armed flare's confirm: aim it at the cursor and let it go. The cell as
## it is at the press, like `confirm_repair`.
func confirm_flare(state: Dictionary, event: InputEvent) -> bool:
	if not _active or not _armed or state.is_empty():
		return false
	if not (event.is_action_pressed(&"place") or event.is_action_pressed(&"interact")):
		return false
	var intent: Dictionary = state["intent"]
	intent["ability_cell"] = [_cell.x, _cell.y]
	intent["ability"] = true
	_armed = false
	return true


## `cancel` while armed puts the flare away rather than doing anything else.
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
	if state.is_empty() or not Grid.in_bounds(cell_at) \
			or Farm.occupant(state, cell_at).is_empty():
		return Vector2i(-1, -1)
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
		_repeat_left += maxf(GameData.CURSOR_REPEAT_RATE, 0.01)


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
	return maxf(float(PlaceholderArt.art(&"cursor_neutral").get("seconds", 0.4)), 0.05)


## Which of its two frames is up.
func frame() -> int:
	return int(_pulse / _pulse_seconds()) % 2


func _draw() -> void:
	if not _active or _cell.x < 0:
		return
	if _aiming:
		_draw_reach()
	var name := StringName("cursor_%s" % _look)
	var path := PlaceholderArt.art_path(name, frame())
	var shape := PlaceholderArt.frame(path)
	var pivot := Vector2(shape.get("pivot", Vector2i(8, 8)))
	if not PlaceholderArt.is_drawn(path):
		var texture: Texture2D = load(path) if ResourceLoader.exists(path) else null
		if texture != null:
			draw_texture(texture, -pivot)
		return
	_draw_stand_in(-pivot, frame())


## **The flare's reach** (task 0135): every cell within `radius_tiles` of the
## cursor's, Chebyshev, so the square is exactly what `Ability.use` hits.
## Code, like the range ring and the route preview - A004 draws the cursor,
## not this. Cells off the farm are left out, as the flare leaves them.
func reach_cells() -> Array:
	var radius := int(GameData.ABILITY["radius_tiles"])
	var out: Array = []
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			var at := _cell + Vector2i(dx, dy)
			if Grid.in_bounds(at):
				out.append(at)
	return out


func _draw_reach() -> void:
	var tile := float(GameData.TILE_SIZE)
	var radius := float(int(GameData.ABILITY["radius_tiles"]))
	var moon: Color = PaletteData.COLOURS[&"moon"]
	var box := Rect2(Vector2.ONE * -(radius + 0.5) * tile, Vector2.ONE * (radius * 2.0 + 1.0) * tile)
	draw_rect(box, Color(moon, 0.10), true)
	draw_rect(box, Color(moon, 0.75), false, 1.0)


## A004's brackets, in code until the pack lands.
func _draw_stand_in(origin: Vector2, pulse_frame: int) -> void:
	var colour: Color = PaletteData.COLOURS[COLOURS.get(_look, &"bone")]
	var ink: Color = PaletteData.COLOURS[&"ink"]
	var inset := pulse_frame
	var glyph: Array = GLYPHS.get(_look, [])
	for corner in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
		if corner == Vector2i(1, 0) and not glyph.is_empty():
			continue
		for i in 5:
			for line in 2:
				# The outer line on the edge, the ink one inside it.
				var along := inset + i + line
				var across := inset + line
				var tint := colour if line == 0 else ink
				if line == 1 and i == 4:
					continue
				_pixel(origin, corner, Vector2i(along, across), tint)
				_pixel(origin, corner, Vector2i(across, along), tint)
	for row in glyph.size():
		var text: String = glyph[row]
		for column in text.length():
			if text[column] == "#":
				draw_rect(Rect2(origin + Vector2(10 + column, 1 + row), Vector2.ONE), colour)
	if _look == &"aim":
		for d in [Vector2i(7, 8), Vector2i(8, 8), Vector2i(9, 8), Vector2i(8, 7), Vector2i(8, 9)]:
			draw_rect(Rect2(origin + Vector2(d), Vector2.ONE), colour)


## One pixel of a bracket, mirrored into its corner of the 16x16 canvas.
func _pixel(origin: Vector2, corner: Vector2i, at: Vector2i, tint: Color) -> void:
	var x := at.x if corner.x == 0 else 15 - at.x
	var y := at.y if corner.y == 0 else 15 - at.y
	draw_rect(Rect2(origin + Vector2(x, y), Vector2.ONE), tint)
