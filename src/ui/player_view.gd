class_name PlayerView
extends Node2D

## The player, drawn where the rules say they are and doing what they say.
##
## It reads `Player.position()` every frame and puts a sprite there. **No
## interpolation and no prediction**: at 30 ticks a second on a 16 pixel tile
## the player moves under two pixels a tick, which reads as smooth without the
## view ever showing a position the simulation does not agree with. The moment
## it did, "the tile in front of me" would mean two different things depending
## on who you asked.
##
## It sits inside the world's y-sorted layer, so walking behind a tree puts the
## player behind the tree.
##
## ## Two tiles wide and three tall
##
## Sprite task 0003's pilot: 30px body on a 48x48 canvas over the unchanged
## 16px grid. Legacy poses use the same scale during the authored migration.
##
## **The node sits at the feet and the sprite is offset up and left**, rather
## than the node sitting at the sprite's corner, because y-sorting uses the
## node's own y - and sorting a character by the top of their hat draws them
## behind things they are standing in front of.
##
## ## The animation is the state's, not the view's
##
## Which drawing plays is `PlayerArt.pose()` off `Player.facing()` and the
## action verb. PlayerWork observes core completion for tool contact and uses
## a view clock only for the expiring return; idle/walk use their authored
## durations. Neither clock can affect gameplay.

## Separately authored contact shadow, never painted into body/reaction art.
## Binary source pixels use the shared palette; modulate supplies transparency.
const SHADOW := "res://sprites/actors/shadow.png"
const BUBBLE_MASK := preload("res://src/ui/player_bubble.gdshader")
## Strong enough to read on grass and weak enough not to look like a hole.
## Measured rather than picked: at 0.30 the shadow changed 47 pixels of the
## screen and was invisible in a screenshot at three times magnification.
const SHADOW_ALPHA := 0.42

var _sprite: Sprite2D
var _shadow: Sprite2D
var _bubble: Sprite2D
var _bubble_material: ShaderMaterial
var _state: Dictionary = {}

## Seconds into the current animation, and which one that was. Reset when the
## drawing changes, so a swing always starts at the top of the swing.
var _elapsed := 0.0
var _playing: StringName = &""
var _textures: Dictionary = {}      # path -> Texture2D, loaded once
var _work := PlayerWork.new()


func _ready() -> void:
	_shadow = Sprite2D.new()
	_shadow.name = "Shadow"
	_shadow.centered = true
	_shadow.texture = load(SHADOW)
	_shadow.modulate = Color(1.0, 1.0, 1.0, SHADOW_ALPHA)
	# Just above the ground the feet are on, so it reads as cast rather than
	# painted on the boots.
	_shadow.position = Vector2(0.0, -1.0)
	add_child(_shadow)

	_sprite = Sprite2D.new()
	_sprite.name = "Body"
	_sprite.centered = false
	_sprite.offset = Vector2(-float(PlayerFrames.FEET.x),
		-float(PlayerFrames.FEET.y))
	add_child(_sprite)
	_bubble_material = ShaderMaterial.new()
	_bubble_material.shader = BUBBLE_MASK
	_bubble = Sprite2D.new()
	_bubble.name = "ReactionBubble"
	_bubble.centered = false
	_bubble.region_enabled = true
	_bubble.visible = false
	add_child(_bubble)


func show_state(state: Dictionary) -> void:
	if not is_same(state, _state):
		_work.reset()
		_playing = &""
	_state = state


func before_tick(state: Dictionary) -> void:
	_work.before_tick(state)


func after_tick(state: Dictionary) -> void:
	_work.after_tick(state)


func _process(delta: float) -> void:
	if _state.is_empty():
		return
	var sub := Player.position(_state)

	# Floored to whole pixels. A sprite on a half pixel has a shimmering edge,
	# which is the one thing integer scaling was set up to avoid.
	position = ArtPlacement.contact([sub.x, sub.y])

	_animate(delta)


## Pick the drawing, advance the clock, and show the frame.
func _animate(delta: float) -> void:
	_bubble.visible = false
	_sprite.material = null
	var pose := _work.pose(_state, delta)
	if pose.is_empty():
		pose = PlayerArt.pose(Player.facing(_state), _is_moving(), _verb())
	var name: StringName = pose["name"]
	if int(pose["frames"]) < 1:
		_sprite.texture = null
		return

	# **Task 0109.** The rules say which bubble and for how long; this only
	# draws it. Nothing here decides when one appears, which is what lets a
	# replay and a screenshot show the same one.
	var holding_rod := Fishing.is_casting(_state) and name == &"reel"
	var reacting := PlayerArt.reaction_pose(&"idle_south" if holding_rod else name, Reactions.now(_state))
	if reacting != &"" and not holding_rod:
		name = reacting
		pose = pose.duplicate()
		pose["name"] = name
		pose["frames"] = int(PlayerFrames.COUNT.get(name, 1))
		pose["seconds"] = float(PlayerFrames.SECONDS.get(name, 0.2))
		# The drawings face the viewer, so a mirrored one would be a farmer
		# whose bubble sits on the wrong shoulder.
		pose["flip"] = false
	if name != _playing:
		# **From the start.** A chop that inherited the walk's clock would
		# begin halfway through the swing, which is the one frame of it that
		# has to land on the tree.
		_playing = name
		_elapsed = 0.0
	else:
		_elapsed += delta

	var frame := int(pose["frame"]) if pose.has("frame") else PlayerArt.frame_at(pose, _elapsed)
	var path := PlayerArt.texture_path(name, frame)
	var texture := _texture(path)
	_sprite.texture = texture
	_sprite.flip_h = bool(pose["flip"])
	# Flipping a sprite mirrors it about its offset, so the offset has to be
	# mirrored too or the farmer steps a canvas-width sideways when they turn.
	var metadata: Dictionary = RasterArt.FRAMES.get(path, {})
	var feet: Vector2i = metadata.get("pivot", PlayerFrames.FEET)
	var canvas: Vector2i = metadata.get("canvas", PlayerFrames.CANVAS)
	_sprite.offset = Vector2(float(feet.x - canvas.x) if bool(pose["flip"])
		else -float(feet.x), -float(feet.y))
	if reacting != &"" and texture != null:
		if holding_rod:
			var reaction_path := PlayerArt.texture_path(reacting, 0)
			_show_bubble(_texture(reaction_path), RasterArt.FRAMES[reaction_path], false)
		else:
			_show_bubble(texture, metadata)


## The existing reaction selects the pose; only its glyph can move to stay
## within the viewport. The body keeps its ground anchor, scale and sorting.
func _show_bubble(texture: Texture2D, metadata: Dictionary, mask_body := true) -> void:
	if not metadata.has("bubble"):
		push_error("Missing source-owned reaction bubble crop")
		return
	var box: Rect2i = metadata["bubble"]
	if mask_body:
		_sprite.material = _bubble_material
		_bubble_material.set_shader_parameter("bubble_box",
			Vector4(box.position.x, box.position.y, box.size.x, box.size.y))
	_bubble.texture = texture
	_bubble.region_rect = Rect2(box)
	var origin := _sprite.offset if mask_body else -Vector2(metadata["pivot"])
	_bubble.position = origin + Vector2(box.position)
	# Work in actual viewport pixels, including integer stretch/camera zoom.
	var transform := get_global_transform_with_canvas()
	var top_left := transform * _bubble.position
	var bottom_right := transform * (_bubble.position + Vector2(box.size))
	var safe := get_viewport_rect().grow(-2.0)
	var shift := Vector2(
		maxf(safe.position.x - top_left.x, 0.0) - maxf(bottom_right.x - safe.end.x, 0.0),
		maxf(safe.position.y - top_left.y, 0.0) - maxf(bottom_right.y - safe.end.y, 0.0))
	_bubble.position += transform.affine_inverse() * (top_left + shift) \
		- transform.affine_inverse() * top_left
	_bubble.visible = true


## What the rules say the player is doing, or nothing.
func _verb() -> StringName:
	var player: Dictionary = _state["player"]
	var action: Dictionary = player["action"]
	return &"" if action.is_empty() else StringName(action["verb"])


## Whether they are walking. Asked of the intent rather than of two positions,
## because comparing frames would make a farmer standing against a fence look
## like a farmer standing still - and they are holding a key.
func _is_moving() -> bool:
	var move: Array = (_state["intent"] as Dictionary)["move"]
	return int(move[0]) != 0 or int(move[1]) != 0


## Textures, loaded once each. Forty-two frames loaded per frame of video
## would be forty-two file reads a sixtieth of a second.
func _texture(path: String) -> Texture2D:
	if _textures.has(path):
		return _textures[path]
	var texture: Texture2D = load(path) if ResourceLoader.exists(path) else null
	if texture == null:
		push_error("no player frame at %s - rebuild its registered source owner"
			% path)
	_textures[path] = texture
	return texture


## What is on screen right now, for `input_check` to read back.
func playing() -> StringName:
	return _playing


func flipped() -> bool:
	return _sprite != null and _sprite.flip_h
