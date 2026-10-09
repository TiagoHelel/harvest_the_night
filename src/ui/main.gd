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

## The day the profile and the run were last written on. **Every night's
## end turns it over** (task 0138) - `enter_result` moves the day on, won
## or lost - so a lost night is saved as surely as a won one. Keyed on
## `nights_won` until then, which a lost night never moves.
var _banked_day := -1

## The one `Theme` every screen in the game wears. Built in `_enter_tree` and
## put on again in `_ready`; see both for why it is twice.
var _dressed: Theme

## The router. By path, because it is an autoload: see `app.gd`.
var _router: Node

## **True from the moment the pause menu lets go until every action key is up.**
##
## The key that closes the menu - Enter on RESUME, Space, Escape - is still
## held on the first frame the world runs again, and an edge read that frame
## went straight into `state["intent"]`: resuming with Enter interacted with
## whatever the farmer was facing, and with Space held it started watering.
## While this is up nothing the keys say reaches the run; it drops the moment
## they are all released.
var _quiet := false
## Whether the world was stopped last time the router spoke, so the moment it
## starts again can be told from every other change.
var _was_paused := false
var _house_view: HouseView
var _inside_house := false

## **The night camera** (task 0130). From the build step until the morning the
## camera is the player's: whether it has been handed over this night.
var _night_camera := false
## The pointer at the window's edge pans only while the window has the focus
## and the pointer is inside it - both the window's own signals, so a pointer
## resting on the next monitor over pans nothing.
var _window_focused := true
var _pointer_in_window := false
## Off for the shots: their real pointer is wherever the desk left it.
var edge_pan := true
## The pointer's last place, in the viewport's own pixels, from `_input`: every
## motion passes there before any control can take it.
var _pointer_at := Vector2(-1, -1)

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
@onready var _tooltip: Tooltip = %Tooltip
## The night's shop window (task 0133), built here and put under the tooltip.
var _hotbar: Hotbar
## The night's forecast (task 0158), built here and put over both HUDs.
var _forecast: ForecastPanel


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
	_result.new_farm_requested.connect(begin_run)
	_result.run_recorded.connect(_year_recorded)
	_house_view = HouseView.new()
	_house_view.name = "HouseView"
	add_child(_house_view)
	_hotbar = Hotbar.new()
	_tooltip.get_parent().add_child(_hotbar)
	_tooltip.get_parent().move_child(_hotbar, _tooltip.get_index())
	# **Over both HUDs and under every panel**: the market opened at 19:00
	# covers it, and the forecast steps aside while it is open anyway.
	_forecast = ForecastPanel.new()
	_night_hud.get_parent().add_child(_forecast)
	_night_hud.get_parent().move_child(_forecast, _night_hud.get_index() + 1)
	var window := get_window()
	_window_focused = window.has_focus()
	window.focus_entered.connect(func() -> void: _window_focused = true)
	window.focus_exited.connect(func() -> void: _window_focused = false)
	window.mouse_entered.connect(func() -> void: _pointer_in_window = true)
	window.mouse_exited.connect(func() -> void: _pointer_in_window = false)
	_driver.stepping.connect(_player_view.before_tick)
	_driver.stepped.connect(_player_view.after_tick)
	_driver.stepping.connect(_world.before_tick)
	_driver.stepped.connect(_world.after_tick)
	_driver.stepping.connect(_particles.before_tick)
	_driver.stepped.connect(_particles.after_tick)

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
	var paused_now: bool = _router.paused()
	_driver.running = not paused_now
	if _was_paused and not paused_now:
		_quiet = true
	_was_paused = paused_now
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


## The ending has banked the year. Keep the live profile in sync so a new
## morning, the stats screen or save-and-quit cannot erase that victory.
func _year_recorded(profile: Dictionary) -> void:
	_profile = profile
	_stats.show_profile(_profile)


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
	_house_view.show_state(_driver.state)
	_shop.show_state(_driver.state)
	# The HUD drives the speed and skip buttons through this,
	# rather than reaching into the state to do it itself.
	_hud.driver = _driver
	_hud.show_state(_driver.state)
	_night_hud.driver = _driver
	_night_hud.cursor = _world.cursor()
	_night_hud.show_state(_driver.state)
	_tech.show_state(_driver.state)
	_build.show_state(_driver.state, _world)
	_hotbar.show_state(_driver.state)
	_forecast.show_state(_driver.state)
	_result.show_state(_driver.state)
	_inventory.show_state(_driver.state)
	_workshop.show_state(_driver.state)
	_tutorial.house = _house_view
	_tutorial.night_hud = _night_hud
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
	_world.ambient_running = _driver.running and not _driver.holding()
	_house_view.ambient_running = _world.ambient_running
	var indoors := House.inside(_driver.state)
	_world.visible = not indoors
	_lighting.visible = not indoors
	if _inside_house and not indoors:
		_world.look_at_cell(Player.cell(_driver.state))
	_inside_house = indoors
	var intent: Dictionary = _driver.state["intent"]
	var move: Array = intent["move"]
	# **A stick walks exactly like a key** (task 0121): the axis is past the
	# action's deadzone or it is not, so -1, 0 or 1. `int()` on its own
	# truncated a half-tilted stick, which reports 0.4, to standing still.
	move[0] = int(signf(Input.get_axis(&"move_left", &"move_right")))
	move[1] = int(signf(Input.get_axis(&"move_up", &"move_down")))
	# **Nobody walks at night** (task 0129): outside the day the move axes
	# write nothing - they pan the night camera instead (`_steer_camera`).
	if int(_driver.state["phase"]) != Phases.DAY:
		move[0] = 0
		move[1] = 0
	var running_art := _driver.running and not _driver.holding() \
		and Input.is_action_pressed(&"run")
	_player_view.set_running(running_art)
	_house_view.set_running(running_art)
	# Every edge is read every frame, paused or not, so `_was_down` knows what
	# the keys are doing - and only reaches the run while the pause menu is
	# not up and the keys that closed it have been let go (see `_quiet`).
	# **The router's pause, not the driver's switch**: a check that stops the
	# driver to step the sim by hand still wants the keys in the intent.
	var ability := _just_pressed(&"ability")
	var interact := _just_pressed(&"interact")
	var cancel := _just_pressed(&"cancel")
	var holding := Input.is_action_pressed(&"interact")
	if _quiet:
		_quiet = holding or Input.is_action_pressed(&"ability") \
			or Input.is_action_pressed(&"cancel")
	var live := not _was_paused and not _quiet
	# **Only a press that can fire is written** (task 0135): `Ability.tick` runs
	# at night alone, so a press by day stayed in the intent and went off on
	# the night's first tick, wherever the cursor happened to be.
	if live and ability and Ability.ready(_driver.state):
		intent["ability"] = true
	# **START** (task 0136): an edge the build step spends and every other
	# phase drops.
	if live and _just_pressed(&"start_waves"):
		intent["start_waves"] = true
	if live and interact:
		intent["interact"] = true
	# **The level as well as the edge.** Holding the key is how a row gets
	# watered in one walk; the edge is what starts a job that then repeats
	# itself. See `Player.initial()` for why they are two fields.
	intent["interact_held"] = holding and live
	if live and cancel:
		intent["cancel"] = true

	_bank_if_a_night_ended()

	# Build mode owns the cursor while it is up: two frames pointing at two
	# different cells is two different games.
	# Nor is there anything to point at while he sleeps (task 0129).
	_world.highlight(Vector2i(-1, -1)
		if Shop.is_open(_driver.state) or Building.is_active(_driver.state)
			or int(_driver.state["phase"]) != Phases.DAY
		else _target_cell())
	_steer_camera(_delta, indoors)
	_drive_cursor(_delta)


## **The guardian's cursor** (task 0131): from the build step to the morning,
## the cell every night action points at. Here it is stepped, written into
## the levels the rules read (`build_cell`), given its look, and described.
func _drive_cursor(delta: float) -> void:
	var cursor := _world.cursor()
	var phase := int(_driver.state["phase"])
	var on := phase == Phases.PREPARATION or phase == Phases.NIGHT
	cursor.set_active(on)
	var intent: Dictionary = _driver.state["intent"]
	if not on:
		# No cursor, no aim: a flare asked for now goes nowhere and is refused.
		intent["ability_cell"] = [-1, -1]
		var target := _target_cell()
		var refusal := Names.refusal(Interact.why_not(_driver.state, target)) if phase == Phases.DAY else ""
		_tooltip.show_world(refusal, _world.cell_to_screen(target))
		return
	var step := Vector2i.ZERO
	# **Not while the night bar has a pad on it** (task 0139): the D-pad and
	# the stick are moving along its buttons then.
	if not _was_paused and not _night_hud.holds_focus():
		step = Vector2i(int(signf(Input.get_axis(&"move_left", &"move_right"))),
			int(signf(Input.get_axis(&"move_up", &"move_down"))))
	cursor.advance(delta, step)
	if cursor.by_pad():
		# The camera follows a stepped cursor near the edge of the view.
		_world.keep_in_view(cursor.centre(), 2.0 * float(GameData.TILE_SIZE))
	var cell := cursor.cell()
	intent["build_cell"] = [cell.x, cell.y]
	# **The flare goes where the cursor is** (task 0135): a level, every frame.
	intent["ability_cell"] = [cell.x, cell.y]
	# Its reach is shown while the flare is ready and the FLARE button is armed
	# or the ability key held - and then the cursor reads aim.
	var ready := Ability.ready(_driver.state)
	if not ready:
		cursor.disarm()
	var aiming := ready and (cursor.is_armed() or Input.is_action_pressed(&"ability"))
	cursor.set_aiming(aiming)
	cursor.set_look(&"aim" if aiming else _cursor_look(cell))
	var mending := cursor.look() == &"repair"
	var said := Describe.under_cursor(_driver.state, cell)
	# **And why not, when the cursor says blocked** (task 0133): the night's
	# palette is the hotbar, which has no reason line of its own.
	var id := Building.selected(_driver.state)
	if cursor.look() == &"blocked" and id != &"":
		var refused := Names.refusal(Building.why_not(_driver.state, id, cell))
		if not refused.is_empty():
			said = refused if said.is_empty() else said + "\n" + refused
	# **What mending it costs** (task 0134): the whole of it, and how much
	# the ledger covers tonight.
	if mending:
		said += "\n" + Describe.repair_line(_driver.state,
			GuardianCursor.mend_target(_driver.state, cell))
	_tooltip.show_world(said,
		_world.cell_to_screen(cell) + Vector2(0.0, float(GameData.TILE_SIZE) * 0.5))


## What confirming would do at the cursor: place, refused, or nothing to do.
## **Something to mend comes first** (task 0134), with or without anything
## in hand: a confirm on it mends it. **Over something of the player's**
## (task 0132) it says what the upgrade and remove buttons would do there
## instead: up a level if it can go, back to the ledger if not. Aim is
## 0135's to switch on.
func _cursor_look(cell: Vector2i) -> StringName:
	var state := _driver.state
	var on := Farm.occupant(state, cell)
	if GuardianCursor.mend_target(state, cell).x >= 0:
		return &"repair"
	if not Building.is_active(state):
		return &"neutral"
	if not on.is_empty() and Building.is_placeable(StringName(on["id"])):
		if Building.can_upgrade(state, cell):
			return &"upgrade"
		if Building.why_not_sell(state, cell).is_empty():
			return &"sell"
		return &"blocked"
	var id := Building.selected(state)
	if id == &"":
		return &"neutral"
	return &"place" if Building.why_not(state, id, cell).is_empty() else &"blocked"


## **Whose camera it is** (task 0130). By day it follows the farmer. From the
## build step until the morning it is the player's: it opens on the house,
## pans with the move keys, the right stick and the pointer at the window's
## edge, and holds still while the pause menu is up and on the result. The
## morning gives it back to the farmer.
func _steer_camera(delta: float, indoors: bool) -> void:
	var phase := int(_driver.state["phase"])
	if phase == Phases.DAY:
		if _night_camera:
			_night_camera = false
			_world.look_at_cell(Player.cell(_driver.state))
		if not indoors:
			_world.follow_player(Player.position(_driver.state), delta)
		return
	if not _night_camera:
		aim_night_camera((Vector2(Farm.house_centre(_driver.state)) + Vector2.ONE * 0.5)
			* float(GameData.TILE_SIZE))
	if phase == Phases.RESULT or _was_paused:
		return
	_world.pan_camera(pan_direction(), delta)


## Hand the camera to the player and put it on a world point. The night
## opens here on the house; `shot.gd` calls it to frame a night scenario.
func aim_night_camera(point: Vector2) -> void:
	_night_camera = true
	_world.look_at_point(point)


## Which way the night camera is being asked to go: the move keys (and the
## left stick bound to them), the right stick's `pan_*`, and the pointer in
## the edge band of a focused window. Up to 1 a side.
func pan_direction() -> Vector2:
	var direction := Vector2.ZERO
	# **A pad's move axes step the cursor instead** (task 0131); the keyboard
	# keeps panning, because the last device touched decides.
	# Nor while the night bar has the focus (task 0139).
	if not _world.cursor().by_pad() and not _night_hud.holds_focus():
		direction = Vector2(Input.get_axis(&"move_left", &"move_right"),
			Input.get_axis(&"move_up", &"move_down"))
	direction += Vector2(Input.get_axis(&"pan_left", &"pan_right"),
		Input.get_axis(&"pan_up", &"pan_down"))
	if edge_pan and _window_focused and _pointer_in_window:
		var size := get_viewport().get_visible_rect().size
		var at := _pointer_at
		var band := float(GameData.CAMERA_EDGE_PIXELS)
		if Rect2(Vector2.ZERO, size).has_point(at):
			direction.x += -1.0 if at.x < band else (1.0 if at.x >= size.x - band else 0.0)
			direction.y += -1.0 if at.y < band else (1.0 if at.y >= size.y - band else 0.0)
	return direction.clamp(-Vector2.ONE, Vector2.ONE)


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
	_banked_day = int(_driver.state["day"])


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
		&"restart":
			# **Abandon and NEW RUN in one**, without the trip through the
			# title: the run and its save go, the profile stays, and the same
			# seed every NEW RUN starts on begins again under the menu as it
			# closes.
			Save.delete_run()
			_left_on_purpose()
			begin_run(BOOT_SEED)
			_banked_day = -1
			if _router != null:
				_router.goto(_router.RUN)
		&"quit":
			# **Saved first, as SAVE AND QUIT saves**, then the window goes -
			# the question said so before it was answered.
			_profile = Stats.fold(_profile, _driver.state)
			Save.write_profile(_profile)
			Save.write_run(_driver.state)
			_left_on_purpose()
			get_tree().quit()


## **Escape stops the world when it has nothing else to stop.**
##
## The pause menu closes on escape itself; opening it is here, because only
## this node knows what else escape is for. It is the last thing to hear an
## unhandled key, so a panel that took escape to close itself has already
## kept it; and the run's own uses of it - leaving a stall, giving up a job, a
## line in the water - come first, because they are what a player pressing
## escape there means. WELCOME BACK, HERO's run screen asks the same questions
## in the same order.
## Where the pointer is, for the night camera's edge band. Read, never
## consumed.
func _input(event: InputEvent) -> void:
	var motion := event as InputEventMouseMotion
	if motion != null:
		_pointer_at = motion.position


func _unhandled_input(event: InputEvent) -> void:
	# **The cursor's confirm** when build mode is not up to take it: an armed
	# flare goes off there (task 0135), or what it reads as repair is mended
	# (task 0134). `cancel` puts an armed flare away before it opens a menu.
	var cursor := _world.cursor()
	if cursor.cancel_aim(event) or cursor.confirm_flare(_driver.state, event) \
			or cursor.confirm_repair(_driver.state, event):
		get_viewport().set_input_as_handled()
		return
	if not event.is_action_pressed(&"cancel") or not escape_is_free():
		return
	_router.goto(_router.PAUSE)
	get_viewport().set_input_as_handled()


## Whether escape, pressed now, would have nothing else to do in the run.
func escape_is_free() -> bool:
	if _router == null or _router.here() != _router.RUN:
		return false
	var state := _driver.state
	if state.is_empty():
		return false
	if StringName(state.get("open_panel", &"")) != &"":
		return false
	if Player.is_busy(state) or Fishing.is_casting(state):
		return false
	if Building.is_active(state):
		return false
	for panel in [_inventory, _result, _workshop, _shop]:
		if panel != null and (panel as CanvasItem).visible:
			return false
	return true


## **This is what "written with the profile, not at the end of a run" means.**
## A player who crashes on night nine should lose the night, not the run, and
## a run's statistics only exist on a state that a crash takes with it.
## `Stats.fold()` banks what it has already counted, so a night that has been
## folded in is not counted again when `Run.record()` closes the run out -
## nor when the next night's end folds the same run again.
func _bank_if_a_night_ended() -> void:
	var day := int(_driver.state["day"])
	if day == _banked_day:
		return
	_banked_day = day
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
