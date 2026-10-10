class_name LootView
extends Node2D

## **What the night left lying about** (task 0221): the bone piles where
## zombies fell and the moon stones a Full Moon laid along the horde's road,
## on the ground under the boots until the farmer walks over them.
##
## **View only.** It reads `Loot` and writes nothing; the shimmer runs on a
## wall clock, so the determinism hash cannot see it.
##
## A036's bone pile and moon stone, drawn in code in their 16x16 boxes at
## (8,14) until 0235 integrates the pack (`PlaceholderArt.is_drawn`): a low
## heap of two pale bones, and a smooth pale stone whose crescent glint
## slides along it between two frames. Its glow is code too - a faint halo
## here by day, and `Lighting`'s cold point after dark.

## How long a frame of the moon stone's shimmer lasts: A036's 0.4 seconds.
const SHIMMER_SECONDS := 0.4
## Where on the stone its light sits, in its 16x16 box: on the sheen, the
## same point in both frames (A036's `light_xy`). `Lighting` centres the
## night glow here.
const STONE_LIGHT := Vector2(6.5, 8.5)
const PILE_PATH := "res://sprites/props/bone_pile.png"

var _state: Dictionary = {}
var _signature := ""
var _clock := 0.0
var _frame := 0
var _textures: Dictionary = {}


func show_state(state: Dictionary) -> void:
	if not is_same(_state, state):
		_signature = ""
	_state = state
	queue_redraw()


func _process(delta: float) -> void:
	if _state.is_empty():
		return
	var redraw := false
	var signature := str(_state.get("loot", {}))
	if signature != _signature:
		_signature = signature
		redraw = true
	_clock += delta
	var frame := int(_clock / SHIMMER_SECONDS) % 2
	if frame != _frame:
		_frame = frame
		# Only a stone shimmers; a farm of bones alone is never redrawn for it.
		redraw = redraw or not Loot.cells_with(_state, GameData.MOON_STONE).is_empty()
	if redraw:
		queue_redraw()


## Which of the stone's two frames is on screen, for the checks.
func shimmer_frame() -> int:
	return _frame


## Where each moon stone's light is, in world pixels: `Lighting`'s night glow.
static func stone_lights(state: Dictionary) -> Array[Vector2]:
	var out: Array[Vector2] = []
	if state.is_empty() or not state.has("loot"):
		return out
	for cell in Loot.cells_with(state, GameData.MOON_STONE):
		out.append(Vector2(cell as Vector2i) * float(GameData.TILE_SIZE) + STONE_LIGHT)
	return out


func _draw() -> void:
	if _state.is_empty() or not _state.has("loot"):
		return
	var tile := float(GameData.TILE_SIZE)
	for cell in Loot.cells(_state):
		var at := Vector2(cell as Vector2i) * tile
		var pile := Loot.at(_state, cell)
		if int(pile.get(GameData.BONES, 0)) > 0:
			_draw_bones(at)
		if int(pile.get(GameData.MOON_STONE, 0)) > 0:
			_draw_stone(at)


# ------------------------------------------------------------------- bones

## A036's bone pile, drawn in code until 0235: two pale bones heaped one
## above the other, each with the two-lobed ends that make a bone a bone, on a
## soft shadow - visible 12 wide and 7 tall, its lowest row 13.
func _draw_bones(at: Vector2) -> void:
	if not PlaceholderArt.is_drawn(PILE_PATH):
		var texture := _texture(PILE_PATH)
		if texture != null:
			draw_texture(texture, at)
			return
	_rect(at, 2, 13, 12, 1, &"ink_soft")
	# The long one underneath: a lobe above and below at each end, the shaft
	# between them.
	_bone(at, 2, 10, 12)
	# The shorter one on top of it, set right.
	_bone(at, 5, 7, 8)


## One bone lying across: `length` wide from `(x, y)`, three rows tall - the
## two lobes at each end on the outer rows, the shaft on the middle one and
## the notch where it meets the end.
func _bone(at: Vector2, x: int, y: int, length: int) -> void:
	var right := x + length - 2
	_rect(at, x, y, 2, 1, &"bone")
	_rect(at, right, y, 2, 1, &"bone")
	_rect(at, x + 1, y + 1, length - 2, 1, &"bone")
	_rect(at, x, y + 2, 2, 1, &"bone_dark")
	_rect(at, right, y + 2, 2, 1, &"bone_dark")
	# The shaft's underside, in the shade of the lobes.
	_rect(at, x + 3, y + 2, length - 6, 1, &"stone_light")


# -------------------------------------------------------------- the stone

## A036's moon stone, drawn in code until 0235: a smooth, rounded pale stone,
## cool blue-white, shaded to blue at its lower right - never the grey of a
## rock - with a glint sliding along the sheen of its upper left between the
## two frames: visible 10 wide and 8 tall, its lowest row 13, over a halo of
## its own light.
func _draw_stone(at: Vector2) -> void:
	var path := PlaceholderArt.art_path(&"moon_stone", _frame)
	if not PlaceholderArt.is_drawn(path):
		var texture := _texture(path)
		if texture != null:
			_halo(at)
			draw_texture(texture, at)
			return
	_halo(at)
	# The outline, rounded at the corners.
	_rect(at, 5, 6, 6, 1, &"ink_soft")
	_rect(at, 4, 7, 1, 1, &"ink_soft")
	_rect(at, 11, 7, 1, 1, &"ink_soft")
	_rect(at, 3, 8, 1, 4, &"ink_soft")
	_rect(at, 12, 8, 1, 4, &"ink")
	_rect(at, 4, 12, 1, 1, &"ink")
	_rect(at, 11, 12, 1, 1, &"ink")
	_rect(at, 5, 13, 6, 1, &"ink")
	# The body, pale and cool, and its shade.
	_rect(at, 5, 7, 6, 1, &"moon")
	_rect(at, 4, 8, 8, 4, &"moon")
	_rect(at, 5, 12, 6, 1, &"water_light")
	_rect(at, 7, 11, 5, 1, &"water_light")
	_rect(at, 10, 9, 2, 2, &"water_light")
	_rect(at, 7, 12, 3, 1, &"stone")
	# The glint, sliding along the sheen: low on its left, then over its top.
	if _frame == 0:
		_rect(at, 5, 9, 1, 2, &"bone")
		_rect(at, 6, 8, 1, 1, &"bone")
	else:
		_rect(at, 6, 8, 1, 1, &"bone")
		_rect(at, 7, 7, 2, 1, &"bone")


## The stone's own light by day: a faint cold pool round `STONE_LIGHT`.
## After dark `Lighting` lays the real one over the night.
func _halo(at: Vector2) -> void:
	var colour := _colour(&"moon")
	for ring in [[7.0, 0.08], [5.0, 0.12], [3.0, 0.16]]:
		colour.a = float(ring[1])
		draw_circle(at + STONE_LIGHT, float(ring[0]), colour)


func _rect(at: Vector2, x: int, y: int, w: int, h: int, colour: StringName) -> void:
	draw_rect(Rect2(at + Vector2(x, y), Vector2(w, h)), _colour(colour))


func _colour(id: StringName) -> Color:
	return PaletteData.COLOURS.get(id, Color.MAGENTA)


func _texture(path: String) -> Texture2D:
	if not _textures.has(path):
		_textures[path] = load(path) if ResourceLoader.exists(path) else null
	return _textures[path]
