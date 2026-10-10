class_name PeddlerView
extends Node2D

## **The peddler at the stall** (task 0190): he keeps the stall's hours. Half
## an hour before `STALL_OPENS` he walks in along the farm road from the east,
## stands at the stall's east end through his hours - waving and talking while
## its panel is open - and walks off the same way after `STALL_CLOSES`.
## Outside his hours the stall is shut: A034's `shop_closed`, through 0120's
## road a dimmed stall until 0216.
##
## **View only.** The hours are `Shop.open_hours`, which the rules keep. Where
## he stands and how far along his walk he is are read off the day's clock
## every frame, so a picture at a given minute is the same picture every time,
## and nothing here writes the state.

## How long his walk in and out takes, in game minutes.
const WALK_MINUTES := 30
## How far east of his post he comes from, in cells, and how far south: the
## farm road runs two rows below the stall.
const WALK_FROM := Vector2i(12, 2)

var _state: Dictionary = {}
var _layer: Node2D
var _sprite: Sprite2D
var _stall: Sprite2D
var _stall_open: Texture2D
var _clock := 0.0
var _textures: Dictionary = {}


## Where to draw: the world's y-sorted layer, where he stands among things.
func setup(layer: Node2D) -> void:
	_layer = layer
	_sprite = Sprite2D.new()
	_sprite.name = "Peddler"
	_sprite.centered = false
	_sprite.visible = false
	_layer.add_child(_sprite)


func show_state(state: Dictionary) -> void:
	_state = state


## The stall's drawing, which this shuts and opens. `WorldView` hands it over
## each time it redraws the farm, open, as it draws it.
func set_stall(sprite: Sprite2D) -> void:
	_stall = sprite
	_stall_open = sprite.texture


func _process(delta: float) -> void:
	if _state.is_empty() or _sprite == null:
		return
	_clock += delta
	_dress_stall()
	_step()


## **Open or shut.** In his hours the stall is its own drawing; out of them,
## `shop_closed` - the shutters, once A034 has them, a dimmed stall till then.
func _dress_stall() -> void:
	if _stall == null or not is_instance_valid(_stall):
		return
	var shut := not Shop.open_hours(_state)
	var texture := _picture(PlaceholderArt.texture_path("res://sprites/props/shop_closed.png")) \
		if shut else _stall_open
	if texture != null and _stall.texture != texture:
		_stall.texture = texture
	_stall.modulate = PlaceholderArt.art_tint(&"shop_closed") if shut else Color.WHITE


## Where he is and what he is doing, off the clock.
func _step() -> void:
	var minute := Phases.clock_minute(_state) if int(_state["phase"]) == Phases.DAY else -1
	var opens := GameData.STALL_OPENS
	var closes := GameData.STALL_CLOSES
	_sprite.visible = minute >= opens - WALK_MINUTES and minute < closes + WALK_MINUTES
	if not _sprite.visible:
		return
	var post := _post()
	if post.x < 0.0:
		_sprite.visible = false
		return
	var away := post + Vector2(WALK_FROM) * float(GameData.TILE_SIZE)
	var walk := float(Phases.tick_at_minute(WALK_MINUTES + GameData.DAY_START_MINUTE))
	var tick := float(int(_state["day_tick"]))
	var mode := &"idle"
	var at := post
	var east := false
	if minute < opens:
		at = away.lerp(post, clampf((tick - float(Phases.tick_at_minute(opens - WALK_MINUTES))) / walk, 0.0, 1.0))
		mode = &"walk"
	elif minute >= closes:
		at = post.lerp(away, clampf((tick - float(Phases.tick_at_minute(closes))) / walk, 0.0, 1.0))
		mode = &"walk"
		east = true
	elif Shop.is_open(_state):
		mode = &"talk"
	var name := StringName("peddler_%s" % mode)
	var entry := PlaceholderArt.art(name)
	var frames := maxi(int(entry.get("frames", 1)), 1)
	var frame := int(_clock / maxf(float(entry.get("seconds", 0.4)), 0.05)) % frames
	var path := PlaceholderArt.texture_path(PlaceholderArt.art_path(name, frame)) if not entry.is_empty() \
		else "res://sprites/actors/%s_%d.png" % [name, frame]
	_sprite.texture = _picture(path)
	_sprite.offset = -_pivot(_sprite.texture)
	_sprite.flip_h = east
	_sprite.modulate = PlaceholderArt.art_tint(name) if not entry.is_empty() else Color.WHITE
	# The stand-in's own drawing scale too: the farmer's walk and stand are
	# drawn at half their canvas, as `PlayerView` draws them.
	var scale := PlaceholderArt.art_scale(name) if not entry.is_empty() else 1.0
	if _sprite.texture != null:
		scale *= float(PlaceholderArt.frame(_sprite.texture.resource_path).get("draw_scale", 1.0))
	_sprite.scale = Vector2(scale, scale)
	_sprite.position = at.round()


## Where he stands: on the ground just east of the stall's east end, his feet
## on its front row.
func _post() -> Vector2:
	var cells := Farm.cells_with(_state, &"shop")
	if cells.is_empty():
		return Vector2(-1, -1)
	var east := 0
	var front := 0
	for cell in cells:
		east = maxi(east, (cell as Vector2i).x)
		front = maxi(front, (cell as Vector2i).y)
	var tile := float(GameData.TILE_SIZE)
	return Vector2((float(east) + 1.5) * tile, (float(front) + 1.0) * tile - 1.0)


## Where he is, for the checks and the pictures: nowhere outside his hours.
func peddler_position() -> Vector2:
	return _sprite.position if _sprite != null and _sprite.visible else Vector2(-1, -1)


func _picture(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if not _textures.has(path):
		_textures[path] = load(path) if ResourceLoader.exists(path) else null
	return _textures[path]


func _pivot(texture: Texture2D) -> Vector2:
	if texture == null:
		return Vector2.ZERO
	var metadata: Dictionary = PlaceholderArt.frame(texture.resource_path)
	return Vector2(metadata.get("pivot", Vector2i(texture.get_width() / 2, texture.get_height())))
