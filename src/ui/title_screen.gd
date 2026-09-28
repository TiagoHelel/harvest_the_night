class_name TitleScreen
extends Node

## What the game boots into: the farm at dusk, with the night coming.
##
## ## The premise, in one image
##
## The backdrop is not a painting of a farm - it **is** the farm, the same
## `World.tscn` the game runs, with a scripted state sat at dusk and creeping
## on. The light ramp task 0071 built does the rest: the sky goes from warm to
## cold behind the logo while nobody touches anything. A player who has read
## no words yet has been told what kind of game this is.
##
## When it reaches night it goes back to dusk and does it again, because the
## one thing a title screen must not do is end.
##
## ## A menu entry with nowhere to go is absent, not greyed
##
## Task 0091 says so about **Continue**, and the reason generalises: a greyed
## button is a promise the game is not keeping and a player cannot tell
## whether it is broken or they are. So `SHOWN_WHEN` decides every entry the
## same way, and an entry whose screen does not exist yet is simply not there.
##
## Continue is still decided that way. **Options came back at task 0092**,
## when the router and the frame it opens were built; the three screens that
## fill that frame are 0093 to 0095, and the frame shows the tabs that exist
## and no more - the same rule again, one level down.
##
## ## The router owns which screen is up
##
## This screen asks `App` and listens to it rather than changing scenes
## itself. `TITLE` is the ident, `MENU` is the menu, and `OPTIONS` is over the
## top of either - so Back from the options screen comes here without the
## options screen having heard of this one.

## The seed the backdrop farm grows from. Written down, like every other seed
## in this project, so the title screen looks the same every boot.
const BACKDROP_SEED := 91091

## How fast the backdrop creeps on. Four ticks a frame is eight times speed:
## a title screen is not a game and nobody is waiting on it for anything.
const CREEP_TICKS := 4

## How long it stays at dusk before the night is let in, and how long the
## whole loop runs before it starts over.
##
## **It has to actually get dark.** The first version held the farm at dusk
## and never crossed into night, which is a green field in slightly warm
## light - a farming game, and only half the premise. What says what this
## game is is the light going cold on the same tiles, with something walking
## in from the fence.
const DUSK_FOR := 10 * GameData.SECONDS
const CREEP_UNTIL := 150 * GameData.SECONDS

## How many things walk in once it is dark. Enough to read as a threat, few
## enough that a title screen costs nothing.
const VISITORS := 5

## The menu, in order. Each is an id, its words, and whether it is shown.
const ENTRIES: Array = [
	[&"continue", "CONTINUE"],
	[&"new", "NEW RUN"],
	[&"stats", "STATISTICS"],
	[&"options", "OPTIONS"],
	[&"quit", "QUIT"],
]

signal chose(which: StringName)

var _state: Dictionary = {}
var _from := 0

var _world: WorldView
var _logo: TextureRect
var _ident: Label
var _menu: VBoxContainer
var _stats: StatsScreen
var _options: OptionsScreen
var _router: Node


func _ready() -> void:
	UiKit.dress(self)
	_world = get_node_or_null(^"WorldView") as WorldView
	_logo = get_node_or_null(^"UI/Screen/Logo") as TextureRect
	_ident = get_node_or_null(^"UI/Screen/Ident") as Label
	_menu = get_node_or_null(^"UI/Screen/Menu") as VBoxContainer
	_stats = get_node_or_null(^"UI/Screen/StatsScreen") as StatsScreen

	_options = get_node_or_null(^"UI/Screen/OptionsScreen") as OptionsScreen
	_router = get_node_or_null(^"/root/App")
	if _router != null and not _router.state_changed.is_connected(_went):
		_router.state_changed.connect(_went)

	_begin_backdrop()
	_build_menu()
	if _router != null:
		_router.reset(_router.TITLE)
	_wear(_router.here() if _router != null else 0)


func _begin_backdrop() -> void:
	_state = State.create(BACKDROP_SEED)
	# A farm with something growing on it, because an empty field says
	# nothing about what the days are for.
	var seeds := Farming.seeds()
	var sown := 0
	for y in GameData.GRID_HEIGHT:
		for x in GameData.GRID_WIDTH:
			var cell := Vector2i(x, y)
			if Interact.verb_at(_state, cell) != &"till":
				continue
			Farming.select_seed(_state, StringName(seeds[sown % seeds.size()]))
			Interact.complete(_state, cell, &"till")
			Interact.complete(_state, cell, &"plant")
			Interact.complete(_state, cell, &"water")
			sown += 1
	Sim.advance(_state, 60 * GameData.SECONDS)
	_from = GameData.DUSK_AT_TICK
	Sim.advance(_state, maxi(_from - int(_state["tick"]), 1))
	if _world != null:
		_world.show_state(_state)
		_world.look_at_cell(Player.cell(_state))


func _process(_delta: float) -> void:
	if _state.is_empty():
		return
	# **The night creeps in, and then it is dusk again.** A title screen that
	# arrived at night and stayed there would be a title screen showing the
	# half of the game it is not about.
	var since := int(_state["tick"]) - _from
	if since > CREEP_UNTIL:
		_begin_backdrop()
		return
	Sim.advance(_state, CREEP_TICKS)

	# Dusk for a moment, then the night is asked for the way the player would
	# ask for it - by writing the intent, not by setting the phase.
	if int(_state["phase"]) == Phases.DAY and since > DUSK_FOR:
		(_state["intent"] as Dictionary)["begin_night"] = true
	var dark := int(_state["phase"]) == Phases.NIGHT
	if dark and Entities.count(_state) < VISITORS:
		Enemies.spawn(_state, &"walker",
			Entities.count(_state) % GameData.SPAWNS.size())

	if _world != null:
		_world.look_at_cell(Player.cell(_state))


# --------------------------------------------------------------- the two views

func _went(_to: int, _from: int) -> void:
	_wear(_router.here() if _router != null else 0)


## Show whatever the router says is up. One function, so there is no way for
## two of these screens to be on at once.
func _wear(state: int) -> void:
	if _router == null:
		return
	# Typed by hand: `_router` is an untyped `Node` - it is an autoload and
	# naming its class here would be the very parse error the path lookup
	# exists to avoid - so everything it hands back is a Variant.
	var menu_up: bool = state == _router.MENU
	var options_up: bool = state == _router.OPTIONS
	var stats_up: bool = state == _router.STATS
	if _ident != null:
		_ident.visible = state == _router.TITLE
		_ident.text = "PRESS ANY KEY"
	if _menu != null:
		_menu.visible = menu_up
		if menu_up:
			_focus_menu()
	if _options != null:
		_options.visible = options_up
	if _stats != null:
		_stats.visible = stats_up
		if stats_up:
			_stats.show_state(_state)
			_stats.show_profile(Save.read_profile())


func _focus_menu() -> void:
	for child in _menu.get_children():
		if child is Button and not (child as Button).disabled:
			(child as Button).grab_focus()
			return


func _unhandled_input(event: InputEvent) -> void:
	if _router == null or _router.here() != _router.TITLE:
		return
	# **Any key or click.** Not a named action: a player who has just started
	# the game has not learned any of them, and "press any key" has to be
	# true.
	var pressed := event is InputEventKey and event.is_pressed() \
		and not event.is_echo()
	var clicked := event is InputEventMouseButton and event.is_pressed()
	var padded := event is InputEventJoypadButton and event.is_pressed()
	if pressed or clicked or padded:
		_router.goto(_router.MENU)
		get_viewport().set_input_as_handled()


# ------------------------------------------------------------------- the menu

## Whether there is anywhere for an entry to go. See the note at the top.
static func is_shown(which: StringName, has_run: bool) -> bool:
	match which:
		&"continue":
			return has_run
		&"options":
			# Task 0092 built the router and the frame, so there is somewhere
			# to go. The three screens that fill it are 0093 to 0095, and
			# `OptionsScreen` shows what has been registered and no more.
			return true
	return true


func _build_menu() -> void:
	if _menu == null:
		return
	for child in _menu.get_children():
		_menu.remove_child(child)
		child.queue_free()
	var saved := Save.has_run()
	for entry in ENTRIES:
		var which: StringName = entry[0]
		if not is_shown(which, saved):
			continue
		var button := Button.new()
		button.name = "Menu_%s" % which
		button.text = str(entry[1])
		button.custom_minimum_size = Vector2(140, 16)
		button.focus_mode = Control.FOCUS_ALL
		button.pressed.connect(_pick.bind(which))
		_menu.add_child(button)


## **Nothing here changes a scene or opens a panel.** Every entry says where
## it wants to go and the router does the rest, which is the whole of "screens
## stop knowing about each other".
func _pick(which: StringName) -> void:
	chose.emit(which)
	if _router == null:
		return
	match which:
		&"new":
			Save.delete_run()
			_router.goto(_router.RUN)
		&"continue":
			# The run on disk is picked up by `Main`; task 0096 is what saves
			# one mid-night, and until then this is the same door as new.
			_router.goto(_router.RUN)
		&"stats":
			_router.goto(_router.STATS)
		&"options":
			_router.goto(_router.OPTIONS)
		&"quit":
			get_tree().quit()


func _input(event: InputEvent) -> void:
	# The records screen has its own key to close; this is the other way out,
	# and both end at the same place because both go through the router.
	if _router == null or not event.is_action_pressed(&"cancel"):
		return
	if _router.here() == _router.STATS or _router.here() == _router.OPTIONS:
		_router.back()
		get_viewport().set_input_as_handled()


# ------------------------------------------------------------- for the checks

func phase() -> int:
	return _router.here() if _router != null else 0


func menu_entries() -> Array:
	var out: Array = []
	if _menu == null:
		return out
	for child in _menu.get_children():
		if child is Button:
			out.append(String(child.name).replace("Menu_", ""))
	return out


func backdrop_tick() -> int:
	return int(_state.get("tick", 0))
