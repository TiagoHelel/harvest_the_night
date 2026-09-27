class_name PlayerView
extends Node2D

## The player, drawn where the rules say they are.
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

const SPRITE := "res://sprites/actors/placeholder.png"

## The actor sprite is 16x24 standing on a 16x16 tile: eight pixels of head-room
## above the tile the feet are on. **The node sits at the feet and the sprite is
## offset upwards**, rather than the node sitting at the sprite's corner -
## because y-sorting uses the node's own y, and sorting a character by the top
## of their head draws them behind things they are standing in front of.
const HEAD_ROOM := 8

var _sprite: Sprite2D
var _state: Dictionary = {}


func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.name = "Body"
	_sprite.centered = false
	_sprite.offset = Vector2(-float(GameData.TILE_SIZE) * 0.5,
		-float(GameData.TILE_SIZE) - float(HEAD_ROOM))
	_sprite.texture = load(SPRITE)
	if _sprite.texture == null:
		push_error("no player sprite at %s - run: python tools/gen_sprites.py"
			% SPRITE)
	add_child(_sprite)


func show_state(state: Dictionary) -> void:
	_state = state


func _process(_delta: float) -> void:
	if _state.is_empty():
		return
	var sub := Player.position(_state)
	var scale_factor := float(GameData.TILE_SIZE) / float(Player.SUBTILE)

	# Floored to whole pixels. A sprite on a half pixel has a shimmering edge,
	# which is the one thing integer scaling was set up to avoid.
	position = Vector2(
		floorf(float(sub.x) * scale_factor),
		floorf(float(sub.y) * scale_factor))
