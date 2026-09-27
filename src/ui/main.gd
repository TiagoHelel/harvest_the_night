extends Node

## The game screen.
##
## It owns the simulation, hands it to the world view to draw and to the debug
## overlay to describe, and keeps the clock in the corner.
##
## **The UI is on its own `CanvasLayer`, and it has to be.** A `Camera2D`
## transforms the whole default canvas, so a HUD that shared it would slide
## around the screen as the camera followed the player - and a button would be
## picked at a different place from where it was drawn. Found by input_check
## the moment the camera started following anybody. Task 0091 puts a
## title screen in front of it and task 0092 a router above both; until then
## this is the whole game.

## Any seed would do here. It is written down rather than taken from the system
## clock so that two boots of the prototype show the same numbers, which is the
## habit the whole codebase is built on.
const BOOT_SEED := 20260927

## The edge of each one-shot action, tracked here rather than taken from
## `Input.is_action_just_pressed()`.
##
## **That function is only true during the frame the event arrived in**, so a
## press that lands after this node's `_process` has already run that frame is
## lost entirely. With a keyboard it is a rare dropped keypress; with
## synthesised input it made a test fail one run in three, which is how it was
## found. `is_action_pressed()` is level rather than edge, so comparing it with
## last frame cannot race with anything.
var _was_down: Dictionary = {}

@onready var _world: WorldView = %WorldView
@onready var _shop: ShopPanel = %ShopPanel
@onready var _hud: DayHud = %DayHud
@onready var _build: BuildMode = %BuildMode
@onready var _result: ResultScreen = %ResultScreen
@onready var _inventory: InventoryPanel = %InventoryPanel
@onready var _workshop: WorkshopPanel = %WorkshopPanel
@onready var _tutorial: TutorialPrompt = %TutorialPrompt
@onready var _player_view: PlayerView = %WorldView/Occupants/PlayerView
@onready var _driver: SimDriver = %SimDriver
@onready var _debug: CanvasLayer = %DebugOverlay


func _ready() -> void:
	print(BuildInfo.line())

	_driver.start(BOOT_SEED)

	_world.show_state(_driver.state)
	_player_view.show_state(_driver.state)
	_shop.show_state(_driver.state)
	_hud.show_state(_driver.state)
	_build.show_state(_driver.state, _world)
	_result.show_state(_driver.state)
	_inventory.show_state(_driver.state)
	_workshop.show_state(_driver.state)
	_tutorial.show_state(_driver.state, _world)
	_world.look_at_cell(Player.cell(_driver.state))

	# The overlay is handed its driver rather than going looking for one: a
	# screen owns its simulation, and two on screen at once would still each
	# describe their own.
	if is_instance_valid(_debug) and _debug.has_method("watch"):
		_debug.watch(_driver)


## **The only place keys become game input.**
##
## Nothing is applied here: what the player is asking for is written into
## `state["intent"]` and the tick decides what it means. That is what lets the
## autoplayer of task 0067 drive the same game by writing the same field, and
## it is why holding a key in a menu cannot move the farmer.
func _process(_delta: float) -> void:
	if _driver.state.is_empty():
		return
	var intent: Dictionary = _driver.state["intent"]
	var move: Array = intent["move"]
	move[0] = int(Input.get_axis(&"move_left", &"move_right"))
	move[1] = int(Input.get_axis(&"move_up", &"move_down"))
	if _just_pressed(&"interact"):
		intent["interact"] = true
	# **The level as well as the edge.** Holding the key is how a row gets
	# watered in one walk; the edge is what starts a job that then repeats
	# itself. See `Player.initial()` for why they are two fields.
	intent["interact_held"] = Input.is_action_pressed(&"interact")
	if _just_pressed(&"cancel"):
		intent["cancel"] = true

	# Build mode owns the cursor while it is up: two frames pointing at two
	# different cells is two different games.
	_world.highlight(Vector2i(-1, -1)
		if Shop.is_open(_driver.state) or Building.is_active(_driver.state)
		else _target_cell())
	_world.look_at_cell(Player.cell(_driver.state))


## True on the frame an action goes from up to down, whenever that frame is.
func _just_pressed(action: StringName) -> bool:
	var down := Input.is_action_pressed(action)
	var edge := down and not bool(_was_down.get(action, false))
	_was_down[action] = down
	return edge


## What the player would act on, or nowhere when there is nothing to do there.
func _target_cell() -> Vector2i:
	var state := _driver.state
	var cell := Player.target(state)
	return cell if Interact.verb_at(state, cell) != &"" else Vector2i(-1, -1)


## Nothing listens for a tick any more: every panel reads the state each frame
## and draws what it finds. A signal per tick would have meant a redraw per
## tick, which at 4x speed is four times the work for the same picture.

