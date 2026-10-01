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

## The router. By path, because it is an autoload: see `app.gd`.
var _router: Node

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
@onready var _pause: PauseMenu = %PauseMenu
@onready var _lighting: Lighting = %Lighting
@onready var _particles: Particles = %Particles
@onready var _transition: Transition = %Transition
@onready var _sfx: Sfx = %Sfx
@onready var _music: Music = %Music
@onready var _ambience: Ambience = %Ambience
@onready var _juice: Juice = %Juice
@onready var _log: LogPanel = %LogPanel
@onready var _options: OptionsScreen = %OptionsScreen
@onready var _player_view: PlayerView = %WorldView/Occupants/PlayerView
@onready var _driver: SimDriver = %SimDriver
@onready var _playtest: PlaytestBadge = %PlaytestBadge
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
	_driver.stepping.connect(_player_view.before_tick)
	_driver.stepped.connect(_player_view.after_tick)

	# **Again, for what the first pass could not see.** The debug overlay
	# builds its panel in its own `_ready`, on a `CanvasLayer` of its own with
	# no Control above it, so it did not exist during `_enter_tree` and
	# nothing would ever have inherited a theme to it. Same theme object, so
	# every screen in the game is wearing one `Theme` and not two copies of
	# one.
	UiKit.dress(self, _dressed)

	# **The router before the run**, since task 0096: the title's CONTINUE
	# leaves a one-shot on it saying to pick up the save, and a run that
	# started before anybody asked would have thrown the save away.
	_router = get_node_or_null(^"/root/App")
	var carry_on: bool = _router != null and _router.take_resume()
	var saved: Dictionary = Save.read_run() if carry_on else {}
	if saved.is_empty():
		begin_run(BOOT_SEED)
	else:
		resume_run(saved)

	# The overlay is handed its driver rather than going looking for one: a
	# screen owns its simulation, and two on screen at once would still each
	# describe their own.
	if is_instance_valid(_debug) and _debug.has_method("watch"):
		_debug.watch(_driver)

	# **The run is a state of the router, not the root of the world.** It
	# says so on the way in, and from here on `App` decides which of the
	# run's panels is up - the keys ask it, the title menu asks it, and
	# neither of them knows the other exists.
	if _router != null:
		if not _router.state_changed.is_connected(_went):
			_router.state_changed.connect(_went)
		_router.reset(_router.RUN)
	if not _pause.chose.is_connected(_pause_chose):
		_pause.chose.connect(_pause_chose)


## Show whichever of the run's overlays the router says is up.
func _went(_to: int, _from: int) -> void:
	if _router == null:
		return
	var at: int = _router.here()
	var tech_up: bool = at == _router.TECH
	var stats_up: bool = at == _router.STATS
	var options_up: bool = at == _router.OPTIONS
	var pause_up: bool = at == _router.PAUSE
	if _pause != null and pause_up != _pause.is_open():
		_pause.set_open(pause_up)
	# **The world is stopped while the pause menu is anywhere on the stack**,
	# not only while it is the top of it - Options opened from it leaves the
	# game paused. `App.paused()` is the one that knows; this turns the only
	# thing that advances time.
	_driver.running = not _router.paused()
	if tech_up != _tech.is_open():
		_tech.open() if tech_up else _tech.close()
	if _stats != null and stats_up != _stats.is_open():
		if stats_up:
			_stats.show_profile(_profile)
			_stats.open()
		else:
			_stats.close()
	if _options != null:
		_options.visible = options_up


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
	_hand_out()

	# **The profile, and a run counted the moment it starts.** `runs_started`
	# is the one lifetime number that cannot be folded out of a state: by the
	# time there is a state to read, the run has already begun.
	#
	# Not in `_hand_out()`, because a run resumed from a save was counted the
	# day it was first started and counting it again would make every quit
	# and carry on look like a new attempt.
	_profile = Stats.begin_run(Save.read_profile())
	Save.write_profile(_profile)
	_stats.show_profile(_profile)


## Hand the state every screen holds to every screen that holds one.
##
## **Shared by `begin_run` and `resume_run`**, which is the point: a screen
## left holding the old dictionary draws a game that has stopped advancing,
## and two lists of twenty `show_state` calls would drift the first time
## somebody added a screen.
func _hand_out() -> void:
	# **Task 0103, and here for exactly the reason the rest of this is
	# here.** `SimDriver.start()` replaces the dictionary, so a crash
	# handler holding the old one would report a run that stopped
	# advancing - the same failure, one layer down.
	Crash.watch(_driver.state)
	_crumb = 0.0
	# Task 0105: a new dictionary is a new run, which is a new session log.
	_playtest.show_state(_driver.state)

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
	_sfx.show_state(_driver.state)
	_music.show_state(_driver.state, _world)
	_ambience.show_state(_driver.state, _world)
	_juice.show_state(_driver.state, _world, _driver)
	_log.show_state(_driver.state)
	_stats.show_state(_driver.state)
	_pause.show_state(_driver.state)

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
	_drop_a_crumb(_delta)
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
## Start a run from a save file rather than from a seed.
##
## `begin_run` builds a state and hands it round; this is handed one and does
## the same round. Everything after `_driver` is identical, which is why they
## share `_hand_out()` rather than being two lists that drift.
func resume_run(saved: Dictionary) -> void:
	_driver.resume(saved)
	_hand_out()
	_profile = Save.read_profile()
	_stats.show_profile(_profile)
	# Already banked up to here, so the night that has not finished yet is
	# the next one to trigger a save rather than the first one counted twice.
	_banked_nights = Phases.nights_won(_driver.state)


## What the pause menu asked for. **The screen says what it wants and this
## does it**, because saving and abandoning a run are not a screen's to do.
func _pause_chose(which: StringName) -> void:
	match which:
		&"save":
			_profile = Stats.fold(_profile, _driver.state)
			Save.write_profile(_profile)
			Save.write_run(_driver.state)
			_left_on_purpose()
			if _router != null:
				_router.goto(_router.TITLE)
		&"abandon":
			# **The run goes, the profile stays.** What a player earned over
			# every run they have played is not what they are abandoning.
			Save.delete_run()
			_left_on_purpose()
			if _router != null:
				_router.goto(_router.TITLE)


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



## How long since the breadcrumb was rewritten.
var _crumb := 0.0


## Leave a trail, so a crash that takes the window with it still says which
## seed and which tick it took.
##
## **Not every frame.** The run is fifteen kilobytes and this is a real file
## write; once every `Crash.BREADCRUMB_SECONDS` is the trade, and what it
## costs is that the recorded tick can be that far behind the one it died on.
## What it buys is that there is a recorded tick at all.
func _drop_a_crumb(delta: float) -> void:
	_crumb += delta
	if _crumb < Crash.BREADCRUMB_SECONDS:
		return
	_crumb = 0.0
	Crash.mark()


## The player is leaving on purpose. **Take the breadcrumb with them**, or
## the next boot opens on a dialogue about a crash that was a player pressing
## SAVE AND QUIT.
func _left_on_purpose() -> void:
	Crash.forget()
	Crash.clear_mark()
	# **Which way they left is the finding.** A run that was abandoned and a
	# run that was lost are two different answers to "where did it end", and
	# a log that recorded them the same way would be a log that could not
	# tell you whether the night was too hard or the day was too dull.
	Playtest.run_ended(_driver.state, "the player left from the pause menu")
