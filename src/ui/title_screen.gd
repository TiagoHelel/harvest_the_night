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
## **Options is in that state today.** The options screens are tasks 0093 to
## 0095 and the router that would open them is 0092; until one of those
## exists there is nothing behind the button, so it is absent rather than
## inert. Task 0092's prompt has been given the line that puts it back. Said
## out loud in the journal rather than quietly counted as done.

## The two things the screen can be.
enum { IDENT, MENU }

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

var _phase := IDENT
var _state: Dictionary = {}
var _from := 0

var _world: WorldView
var _logo: TextureRect
var _ident: Label
var _menu: VBoxContainer
var _stats: StatsScreen


func _ready() -> void:
	UiKit.dress(self)
	_world = get_node_or_null(^"WorldView") as WorldView
	_logo = get_node_or_null(^"UI/Screen/Logo") as TextureRect
	_ident = get_node_or_null(^"UI/Screen/Ident") as Label
	_menu = get_node_or_null(^"UI/Screen/Menu") as VBoxContainer
	_stats = get_node_or_null(^"UI/Screen/StatsScreen") as StatsScreen

	_begin_backdrop()
	_build_menu()
	_show_ident()


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

func _show_ident() -> void:
	_phase = IDENT
	if _menu != null:
		_menu.visible = false
	if _ident != null:
		_ident.visible = true
		_ident.text = "PRESS ANY KEY"


func _show_menu() -> void:
	_phase = MENU
	if _ident != null:
		_ident.visible = false
	if _menu != null:
		_menu.visible = true
		for child in _menu.get_children():
			if child is Button and not (child as Button).disabled:
				(child as Button).grab_focus()
				break


func _unhandled_input(event: InputEvent) -> void:
	if _phase != IDENT:
		return
	# **Any key or click.** Not a named action: a player who has just started
	# the game has not learned any of them, and "press any key" has to be
	# true.
	var pressed := event is InputEventKey and event.is_pressed() \
		and not event.is_echo()
	var clicked := event is InputEventMouseButton and event.is_pressed()
	var padded := event is InputEventJoypadButton and event.is_pressed()
	if pressed or clicked or padded:
		_show_menu()
		get_viewport().set_input_as_handled()


# ------------------------------------------------------------------- the menu

## Whether there is anywhere for an entry to go. See the note at the top.
static func is_shown(which: StringName, has_run: bool) -> bool:
	match which:
		&"continue":
			return has_run
		&"options":
			# Tasks 0093 to 0095 build the screens and 0092 the router that
			# opens them. Nothing yet, so nothing shown.
			return false
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


func _pick(which: StringName) -> void:
	chose.emit(which)
	match which:
		&"new":
			Save.delete_run()
			get_tree().change_scene_to_file("res://scenes/Main.tscn")
		&"continue":
			# The run on disk is picked up by `Main`; task 0096 is what saves
			# one mid-night, and until then this is the same door as new.
			get_tree().change_scene_to_file("res://scenes/Main.tscn")
		&"stats":
			_show_stats()
		&"quit":
			get_tree().quit()


func _show_stats() -> void:
	if _stats == null:
		return
	_stats.show_state(_state)
	_stats.show_profile(Save.read_profile())
	_stats.visible = true
	if _menu != null:
		_menu.visible = false


func _input(event: InputEvent) -> void:
	# The records screen closes itself on its own key; this puts the menu
	# back when it does.
	if _stats != null and not _stats.visible and _phase == MENU \
			and _menu != null and not _menu.visible:
		_menu.visible = true
	if event.is_action_pressed(&"cancel") and _stats != null \
			and _stats.visible:
		_stats.visible = false
		if _menu != null:
			_menu.visible = true


# ------------------------------------------------------------- for the checks

func phase() -> int:
	return _phase


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
