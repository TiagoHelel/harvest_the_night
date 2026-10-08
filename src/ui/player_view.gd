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
## ## Two tiles tall, like Stardew Valley's farmer
##
## FHD art: the reviewed blue walk, a ~64px body on an 80x80 source canvas,
## drawn at half scale over the unchanged 16px grid. At 1920x1080 a tile is
## 64 screen pixels, so the farmer stands 128 pixels tall - the height of
## Stardew Valley's 16x32 farmer at its 4x scale. Since 2026-10-06 the frames
## carry the chosen "32px" detail: each art pixel is a 2x2 block of the
## canvas, four screen pixels square, like the zombies, the tool poses and
## the rest of the world (`detail_wh` in tools/import_art.py).
##
## **The node sits at the feet and the sprite is offset up and left**, rather
## than the node sitting at the sprite's corner, because y-sorting uses the
## node's own y - and sorting a character by the top of their hat draws them
## behind things they are standing in front of.
##
## ## The animation is the state's, not the view's
##
## Which drawing plays is `PlayerArt.pose()` off `Player.facing()`, the
## action verb and the direction last held - eight ways, read from the same
## `intent.move` the rules read. PlayerWork observes core completion for tool
## contact and uses a view clock only for the expiring return; idle/walk use
## their authored durations. Neither clock can affect gameplay.

## Separately authored contact shadow, never painted into body/reaction art.
## Binary source pixels use the shared palette; modulate supplies transparency.
const SHADOW := "res://sprites/actors/shadow.png"
## Strong enough to read on grass and weak enough not to look like a hole.
## Measured rather than picked: at 0.30 the shadow changed 47 pixels of the
## screen and was invisible in a screenshot at three times magnification.
const SHADOW_ALPHA := 0.42
## The reaction glyphs were drawn three pixels above a 30px farmer's head. The
## walking farmer is 32px tall, so the glyph keeps its authored place beside
## the head and rises by the difference.
const BUBBLE_LIFT := Vector2(0.0, -2.0)

var _sprite: Sprite2D
var _shadow: Sprite2D
var _bubble: Sprite2D
var _state: Dictionary = {}

## Seconds into the current animation, and which one that was. Reset when the
## drawing changes, so a swing always starts at the top of the swing.
var _elapsed := 0.0
var _playing: StringName = &""
var _seconds := 0.0
## The last direction held, eight ways. View memory only: it decides which of
## the eight drawings stands still, never where anybody is.
var _heading := Vector2i.ZERO
var _textures: Dictionary = {}      # path -> Texture2D, loaded once
var _work := PlayerWork.new()
var _running := false


## A presentation choice only; core movement remains owned by Player.tick.
func set_running(running: bool) -> void:
	_running = running


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
		_heading = Vector2i.ZERO
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
	# **In bed from the switch to the morning** (task 0129): nobody on the
	# porch at night. After a collapse at 02:00 he lies where he fell through
	# the short build step instead, and is gone with the night.
	var lying := _lying()
	var away := House.asleep(_state) and int(_state["phase"]) != Phases.DAY and not lying
	_sprite.visible = not away
	_shadow.visible = not away
	if away:
		return
	var move := Vector2i.ZERO if lying else _move()
	if move != Vector2i.ZERO:
		_heading = move
	var pose := PlayerArt.pass_out_pose(Player.facing(_state)) if lying \
		else _work.pose(_state, delta)
	if pose.is_empty():
		pose = PlayerArt.pose(Player.facing(_state), move != Vector2i.ZERO, _verb(), _running, _heading)
	var name: StringName = pose["name"]
	if int(pose["frames"]) < 1:
		_sprite.texture = null
		return

	# **Task 0109.** The rules say which bubble and for how long; this only
	# draws it. Nothing here decides when one appears, which is what lets a
	# replay and a screenshot show the same one. Only the glyph is drawn:
	# the farmer keeps standing the way they stand.
	var holding_rod := Fishing.is_casting(_state) and name == &"reel"
	var reacting := PlayerArt.reaction_pose(&"idle_south" if holding_rod else name, Reactions.now(_state))
	var seconds := float(pose["seconds"])
	if name != _playing:
		# **From the start.** A chop that inherited the walk's clock would
		# begin halfway through the swing, which is the one frame of it that
		# has to land on the tree.
		_playing = name
		_elapsed = 0.0
	else:
		# Walking and running share drawings at two speeds. Rescaling the
		# clock keeps the frame on screen when the run key changes.
		if _seconds > 0.0 and seconds > 0.0 and not is_equal_approx(seconds, _seconds):
			_elapsed *= seconds / _seconds
		_elapsed += delta
	_seconds = seconds

	var frame := int(pose["frame"]) if pose.has("frame") else PlayerArt.frame_at(pose, _elapsed)
	if bool(pose.get("hold", false)):
		# Played once, then held on its last frame.
		frame = mini(int(_elapsed / maxf(seconds, 0.01)), int(pose["frames"]) - 1)
	var path := PlayerArt.texture_path(name, frame)
	var texture := _texture(path)
	_sprite.texture = texture
	_sprite.flip_h = bool(pose["flip"])
	# A stand-in's own tint and turn (task 0129); white and upright for art
	# that has arrived.
	_sprite.modulate = PlaceholderArt.stand_in_tint(name)
	_sprite.rotation_degrees = PlaceholderArt.stand_in_turn(name, frame)
	# Flipping a sprite mirrors it about its offset, so the offset has to be
	# mirrored too or the farmer steps a canvas-width sideways when they turn.
	var metadata: Dictionary = PlaceholderArt.frame(path)
	var feet: Vector2i = metadata.get("pivot", PlayerFrames.FEET)
	var canvas: Vector2i = metadata.get("canvas", PlayerFrames.CANVAS)
	_sprite.scale = Vector2.ONE * float(metadata.get("draw_scale", 1.0))
	_sprite.offset = Vector2(float(feet.x - canvas.x) if bool(pose["flip"])
		else -float(feet.x), -float(feet.y))
	if reacting != &"" and texture != null:
		var reaction_path := PlayerArt.texture_path(reacting, 0)
		# The rod pose is the older 30px farmer the glyph was drawn beside.
		_show_bubble(_texture(reaction_path), PlaceholderArt.frame(reaction_path),
			Vector2.ZERO if holding_rod else BUBBLE_LIFT)


## The reaction frame's own glyph, where it was drawn relative to the feet.
## Only the glyph can move to stay within the viewport; the body keeps its
## ground anchor, scale and sorting.
func _show_bubble(texture: Texture2D, metadata: Dictionary, lift: Vector2) -> void:
	if not metadata.has("bubble"):
		push_error("Missing source-owned reaction bubble crop")
		return
	var box: Rect2i = metadata["bubble"]
	_bubble.texture = texture
	_bubble.region_rect = Rect2(box)
	var draw_scale := float(metadata.get("draw_scale", 1.0))
	_bubble.scale = Vector2.ONE * draw_scale
	_bubble.position = (Vector2(box.position) - Vector2(metadata["pivot"])) * draw_scale + lift
	# Work in actual viewport pixels, including the integer stretch.
	var transform := get_global_transform_with_canvas()
	var top_left := transform * _bubble.position
	var bottom_right := transform * (_bubble.position + Vector2(box.size) * draw_scale)
	var safe := get_viewport_rect().grow(-2.0)
	var shift := Vector2(
		maxf(safe.position.x - top_left.x, 0.0) - maxf(bottom_right.x - safe.end.x, 0.0),
		maxf(safe.position.y - top_left.y, 0.0) - maxf(bottom_right.y - safe.end.y, 0.0))
	_bubble.position += transform.affine_inverse() * (top_left + shift) \
		- transform.affine_inverse() * top_left
	_bubble.visible = true


## Lying where he fell: passed out at 02:00 and still in the build step.
func _lying() -> bool:
	return House.passed_out(_state) and House.asleep(_state) \
		and int(_state["phase"]) == Phases.PREPARATION


## Whether he is on screen at all: not while he is in bed (task 0129).
func is_drawn() -> bool:
	return _sprite != null and _sprite.visible


## What the rules say the player is doing, or nothing.
func _verb() -> StringName:
	var player: Dictionary = _state["player"]
	var action: Dictionary = player["action"]
	return &"" if action.is_empty() else StringName(action["verb"])


## The direction held, eight ways, or zero. Asked of the intent rather than of
## two positions, because comparing frames would make a farmer standing
## against a fence look like a farmer standing still - and they are holding a
## key.
func _move() -> Vector2i:
	var move: Array = (_state["intent"] as Dictionary)["move"]
	return Vector2i(signi(int(move[0])), signi(int(move[1])))


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


## How long each frame of it lasts: shorter while the run key is held.
func frame_seconds() -> float:
	return _seconds


func flipped() -> bool:
	return _sprite != null and _sprite.flip_h
