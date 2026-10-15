class_name BobberView
extends Node2D

## **The float** (task 0206): A023's bobber on the water where the line went
## in, from the cast to the reel - bobbing, two frames round and round, while
## the line waits, and sinking through its three bite frames the moment a
## fish takes it, held under while it is on.
##
## **View only.** Where the line is and whether a fish has it are
## `Fishing`'s, read every frame; nothing here is in the state.

## Where A023 delivers it.
const DIR := "res://sprites/effects/"

var _state: Dictionary = {}
var _elapsed := 0.0
var _was_biting := false
var _held: Dictionary = {}


func show_state(state: Dictionary) -> void:
	_state = state


## **The frame for a line** (task 0206): biting, the bite's frame `seconds`
## after the take, held on its last; waiting, the float's, round and round.
static func frame_name(biting: bool, seconds: float) -> String:
	var first := PlaceholderArt.frame(DIR + ("bobber_bite_0.png" if biting else "bobber_float_0.png"))
	var each := maxf(float(first.get("seconds", 0.1)), 0.01)
	if biting:
		return "bobber_bite_%d" % mini(int(seconds / each), 2)
	return "bobber_float_%d" % (int(seconds / each) % 2)


## Where it floats: the middle of the line's water cell.
static func spot(state: Dictionary) -> Vector2:
	return (Vector2(Fishing.line_cell(state)) + Vector2(0.5, 0.5)) * float(GameData.TILE_SIZE)


## The frame up now - "" while there is no line - for the tests.
func shown() -> String:
	return "" if not visible else DIR + frame_name(_was_biting, _elapsed) + ".png"


func _process(delta: float) -> void:
	visible = not _state.is_empty() and int(_state["phase"]) == Phases.DAY \
		and Fishing.is_casting(_state) and not House.inside(_state)
	if not visible:
		_elapsed = 0.0
		_was_biting = false
		return
	var biting := Fishing.is_biting(_state)
	if biting != _was_biting:
		_was_biting = biting
		_elapsed = 0.0
	else:
		_elapsed += maxf(delta, 0.0)
	position = spot(_state)
	queue_redraw()


func _draw() -> void:
	if not visible:
		return
	var path := shown()
	if not _held.has(path):
		_held[path] = load(path) if ResourceLoader.exists(path) else null
	var texture: Texture2D = _held[path]
	if texture != null:
		draw_texture(texture, -Vector2(PlaceholderArt.frame(path).get("pivot", Vector2i(4, 6))))
