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

## What survives a run. Read on boot, banked at the end of every night.
var _profile: Dictionary = {}

## How many nights had been won the last time the profile was written. The
## night that changes it is the night that triggers a save.
var _banked_nights := -1

## The one `Theme` every screen in the game wears. Built in `_enter_tree` and
## put on again in `_ready`; see both for why it is twice.
var _dressed: Theme

@onready var _world: WorldView = %WorldView
@onready var _shop: ShopPanel = %ShopPanel
@onready var _hud: DayHud = %DayHud
@onready var _night_hud: NightHud = %NightHud
@onready var _tech: TechPanel = %TechPanel
@onready var _build: BuildMode = %BuildMode
@onready var _result: ResultScreen = %ResultScreen
@onready var _inventory: InventoryPanel = %InventoryPanel
@onready var _workshop: WorkshopPanel = %WorkshopPanel
@onready var _tutorial: TutorialPrompt = %TutorialPrompt
@onready var _stats: StatsScreen = %StatsScreen
@onready var _lighting: Lighting = %Lighting
@onready var _particles: Particles = %Particles
@onready var _transition: Transition = %Transition
@onready var _player_view: PlayerView = %WorldView/Occupants/PlayerView
@onready var _driver: SimDriver = %SimDriver
@onready var _debug: CanvasLayer = %DebugOverlay


## **The theme goes on before anything is built against it**, which is why
## this is `_enter_tree` and not `_ready`.
##
## `_enter_tree` runs on a parent before its children; `_ready` runs on
## children before their parent. A screen that builds a `Button` in its own
## `_ready` with no theme yet gets Godot's default minimum size - sixty-three
## by thirty-one - and `size` is clamped *up* to it. When the theme lands a
## moment later the minimum drops to forty-six by eight, but a Control's
## `size` is never clamped back down, so the button stays thirty-one pixels
## tall for the rest of the run. That is three controls hanging off the
## bottom of a 270 pixel screen, and `input_check` caught all three.
func _enter_tree() -> void:
	_dressed = UiKit.theme()
	UiKit.dress(self, _dressed)


func _ready() -> void:
	print(BuildInfo.line())

	# **Again, for what the first pass could not see.** The debug overlay
	# builds its panel in its own `_ready`, on a `CanvasLayer` of its own with
	# no Control above it, so it did not exist during `_enter_tree` and
	# nothing would ever have inherited a theme to it. Same theme object, so
	# every screen in the game is wearing one `Theme` and not two copies of
	# one.
	UiKit.dress(self, _dressed)

	begin_run(BOOT_SEED)

	# The overlay is handed its driver rather than going looking for one: a
	# screen owns its simulation, and two on screen at once would still each
	# describe their own.
	if is_instance_valid(_debug) and _debug.has_method("watch"):
		_debug.watch(_driver)


## Start a run on `seed_value` and hand the new state to every screen.
##
## **A method rather than a block inside `_ready`** because three things want
## it: boot, `src/tools/shot.gd`, which restarts on its own seed to build a
## scenario, and task 0092's router, which has to be able to begin a run from
## the menu. `SimDriver.start` replaces the state dictionary rather than
## emptying it, so a screen still holding the old one would draw a game that
## has stopped advancing - which is the failure this exists to make
## impossible to forget.
func begin_run(seed_value: int) -> void:
	_driver.start(seed_value)

	_world.show_state(_driver.state)
	_player_view.show_state(_driver.state)
	_shop.show_state(_driver.state)
	# The HUD drives the speed and skip buttons through this,
	# rather than reaching into the state to do it itself.
	_hud.driver = _driver
	_hud.show_state(_driver.state)
	_night_hud.driver = _driver
	_night_hud.show_state(_driver.state)
	_tech.show_state(_driver.state)
	_build.show_state(_driver.state, _world)
	_result.driver = _driver
	_result.show_state(_driver.state)
	_inventory.show_state(_driver.state)
	_workshop.show_state(_driver.state)
	_tutorial.show_state(_driver.state, _world)
	_lighting.show_state(_driver.state)
	_particles.show_state(_driver.state)
	_transition.show_state(_driver.state, _world)

	# **The profile, and a run counted the moment it starts.** `runs_started`
	# is the one lifetime number that cannot be folded out of a state: by the
	# time there is a state to read, the run has already begun.
	_profile = Stats.begin_run(Save.read_profile())
	Save.write_profile(_profile)
	_stats.show_state(_driver.state)
	_stats.show_profile(_profile)

	_world.look_at_cell(Player.cell(_driver.state))


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
	if _just_pressed(&"ability"):
		intent["ability"] = true
	if _just_pressed(&"interact"):
		intent["interact"] = true
	# **The level as well as the edge.** Holding the key is how a row gets
	# watered in one walk; the edge is what starts a job that then repeats
	# itself. See `Player.initial()` for why they are two fields.
	intent["interact_held"] = Input.is_action_pressed(&"interact")
	if _just_pressed(&"cancel"):
		intent["cancel"] = true

	_bank_if_a_night_ended()

	# Build mode owns the cursor while it is up: two frames pointing at two
	# different cells is two different games.
	_world.highlight(Vector2i(-1, -1)
		if Shop.is_open(_driver.state) or Building.is_active(_driver.state)
		else _target_cell())
	_world.look_at_cell(Player.cell(_driver.state))


## Fold this run's numbers into the profile and write both files, once per
## night survived.
##
## **This is what "written with the profile, not at the end of a run" means.**
## A player who crashes on night nine should lose the night, not the run, and
## a run's statistics only exist on a state that a crash takes with it.
## `Stats.fold()` banks what it has already counted, so a night that has been
## folded in is not counted again when `Run.record()` closes the run out.
func _bank_if_a_night_ended() -> void:
	var won := Phases.nights_won(_driver.state)
	if won == _banked_nights:
		return
	_banked_nights = won
	_profile = Stats.fold(_profile, _driver.state)
	Save.write_profile(_profile)
	Save.write_run(_driver.state)
	_stats.show_profile(_profile)


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

