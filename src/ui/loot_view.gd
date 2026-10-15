class_name LootView
extends Node2D

## **What the night left lying about** (task 0221): the bone piles where
## zombies fell and the moon stones a Full Moon laid along the horde's road,
## on the ground under the boots until the farmer walks over them.
##
## **View only.** It reads `Loot` and writes nothing; the shimmer runs on a
## wall clock, so the determinism hash cannot see it.
##
## A036's bone pile and moon stone in their 16x16 boxes standing on (8,14),
## the pack's art since task 0235: a low heap of bones, and a smooth pale
## stone whose glint slides along it between two frames. Its glow stays code -
## a faint halo here by day, and `Lighting`'s cold point after dark.

## How long a frame of the moon stone's shimmer lasts: A036's 0.4 seconds.
const SHIMMER_SECONDS := 0.4
## Where on the stone its light sits, in its 16x16 box: on the sheen, the
## same point in both frames (A036's `light_xy`). `Lighting` centres the
## night glow here.
const STONE_LIGHT := Vector2(6.5, 8.5)
const PILE_PATH := "res://sprites/props/bone_pile.png"
const STONE_PATH := "res://sprites/props/moon_stone_%d.png"

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


# ------------------------------------------------------------- the pictures

## A036's bone pile.
func _draw_bones(at: Vector2) -> void:
	var texture := _texture(PILE_PATH)
	if texture != null:
		draw_texture(texture, at)


## A036's moon stone on its frame of the shimmer, over a halo of its light.
func _draw_stone(at: Vector2) -> void:
	_halo(at)
	var texture := _texture(STONE_PATH % _frame)
	if texture != null:
		draw_texture(texture, at)


## The stone's own light by day: a faint cold pool round `STONE_LIGHT`.
## After dark `Lighting` lays the real one over the night.
func _halo(at: Vector2) -> void:
	var colour := _colour(&"moon")
	for ring in [[7.0, 0.08], [5.0, 0.12], [3.0, 0.16]]:
		colour.a = float(ring[1])
		draw_circle(at + STONE_LIGHT, float(ring[0]), colour)


func _colour(id: StringName) -> Color:
	return PaletteData.COLOURS.get(id, Color.MAGENTA)


func _texture(path: String) -> Texture2D:
	if not _textures.has(path):
		_textures[path] = load(path) if ResourceLoader.exists(path) else null
	return _textures[path]
