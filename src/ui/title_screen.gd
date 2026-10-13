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

const ActionsScript := preload("res://src/app/input_actions.gd")

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
	[&"continue", &"TITLE_CONTINUE"],
	[&"new", &"TITLE_NEW"],
	[&"stats", &"TITLE_STATS"],
	# Task 0287: the collections and achievements, kept across runs.
	[&"collections", &"TITLE_COLLECTIONS"],
	[&"options", &"TITLE_OPTIONS"],
	[&"quit", &"TITLE_QUIT"],
]

signal chose(which: StringName)

var _state: Dictionary = {}
var _from := 0

var _world: WorldView
var _logo: TextureRect
var _ident: Label
var _version: Label
var _menu: VBoxContainer
var _stats: StatsScreen
var _collections: CollectionsScreen
var _options: OptionsScreen
var _router: Node


func _ready() -> void:
	UiKit.dress(self)
	_world = get_node_or_null(^"WorldView") as WorldView
	_logo = get_node_or_null(^"UI/Screen/Logo") as TextureRect
	_ident = get_node_or_null(^"UI/Screen/Ident") as Label
	_menu = get_node_or_null(^"UI/Screen/Menu") as VBoxContainer
	_stats = get_node_or_null(^"UI/Screen/StatsScreen") as StatsScreen
	_collections = get_node_or_null(^"UI/Screen/CollectionsScreen") as CollectionsScreen

	_options = get_node_or_null(^"UI/Screen/OptionsScreen") as OptionsScreen
	_crash = get_node_or_null(^"UI/Screen/CrashDialog") as CrashDialog

	# **Task 0103: a crash that took the window is announced here.** A dead
	# process cannot draw a dialogue, so "rather than vanishing" is kept one
	# launch later - `sweep()` turns a breadcrumb the last session left
	# behind into a report, and `pending()` is whichever report nobody has
	# been shown yet, including one written by an error that did not stop
	# the game at all.
	Crash.sweep()
	_to_announce = Crash.pending()
	_version = get_node_or_null(^"UI/Screen/Version") as Label
	# **A panel and the words on it.** The first version was a bare label
	# over the backdrop, which is a farm: orange text on grass, trees and a
	# roof, and the third line ran off the bottom of it. Everything else in
	# this game that expects to be read sits on a frame.
	_trouble = get_node_or_null(^"UI/Screen/SaveTrouble") as PanelContainer
	_trouble_text = get_node_or_null(
		^"UI/Screen/SaveTrouble/SaveTroubleText") as Label
	_router = get_node_or_null(^"/root/App")
	if _router != null and not _router.state_changed.is_connected(_went):
		_router.state_changed.connect(_went)

	_begin_backdrop()
	_build_menu()
	_wear_version()
	if _router != null:
		_router.reset(_router.TITLE)
		# **Out of the studio ident's black**, when its timeline handed over
		# rather than a skip - taken once and cleared, like the resume.
		if bool(_router.get(&"rise_from_black")):
			_router.set(&"rise_from_black", false)
			_rise_from_black()
	_wear(_router.here() if _router != null else 0)


## How long the title takes to come up out of the ident's black. The same
## second that game gives its title.
const RISE_SECONDS := 0.9


## A sheet of the ident's own black over everything, faded away: the ident
## went dark on purpose, and a title that arrived at full strength the next
## frame would undo it.
func _rise_from_black() -> void:
	var layer := CanvasLayer.new()
	layer.name = "RiseFromBlack"
	layer.layer = 100
	var sheet := ColorRect.new()
	sheet.color = StudioIntro.C_BLACK
	sheet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sheet.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(sheet)
	add_child(layer)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(sheet, "color:a", 0.0, RISE_SECONDS)
	tween.tween_callback(layer.queue_free)


## Say it all again in whatever language is up now.
## Which build this is, in the corner.
##
## **On the title rather than in the debug overlay**, because the overlay is
## a developer key and the person who needs this is a stranger sending a
## screenshot of something going wrong. Task 0100 stamps the date on the way
## out of `tools/release.py`, so what is written here is the build that was
## made rather than the day somebody edited a constant.
func _wear_version() -> void:
	if _version == null:
		return
	_version.text = I18n.f(&"TITLE_BUILD",
		[BuildInfo.VERSION, BuildInfo.STAGE, BuildInfo.BUILT])
	_version.theme_type_variation = UiKit.DIM
	# **Task 0105, and on this line rather than a new one.** A tester needs
	# to know which build they have before they report the missing content
	# as a bug; the corner that already says which build this is is where
	# they will look. Loud rather than dim, because it is the one thing on
	# the screen that is not true of the game anybody else will play.
	# **Its own line.** On the same one it ran off the right of the screen
	# and "built 2026-09-28" came out as "built 2026" - the label is 240
	# wide and `TITLE_BUILD` already uses most of it. The box is two lines
	# tall now and the shipping build simply leaves the first one empty.
	if Playtest.is_on():
		_version.text = "%s%s%s" % [I18n.t(&"PLAYTEST_TITLE"), "
",
			_version.text]
		_version.theme_type_variation = UiKit.WARN


func relabel() -> void:
	if _menu == null:
		return
	_build_menu()
	_wear_trouble()
	_wear_version()
	if _ident != null:
		_ident.text = I18n.t(&"TITLE_PRESS_ANY")


func _begin_backdrop() -> void:
	_state = State.create(BACKDROP_SEED)
	# A farm with something growing on it, because an empty field says
	# nothing about what the days are for.
	var seeds := Farming.in_season(_state)
	var sown := 0
	for cell in Farming.field_cells(_state):
		if Interact.verb_at(_state, cell) != &"till":
			continue
		Resources.add(_state, Farming.packet(StringName(seeds[sown % seeds.size()])), 1)
		Farming.select_seed(_state, StringName(seeds[sown % seeds.size()]))
		Interact.complete(_state, cell, &"till")
		Interact.complete(_state, cell, &"plant")
		Interact.complete(_state, cell, &"water")
		sown += 1
	# **Shortly before 02:00** (task 0128): the backdrop does not send for the
	# night - the farmer passes out, as anyone up that late does, and the
	# short build step and the night follow by themselves.
	_from = GameData.DAY_TICKS - DUSK_FOR
	# This is a disposable display fixture, not a player save. Start at its
	# opening clock instead of simulating nine minutes on every title visit.
	_state["tick"] = _from
	_state["phase_tick"] = _from
	_state["day_tick"] = _from
	if _world != null:
		_world.show_state(_state)
		_world.look_at_cell(Player.cell(_state))


func _process(_delta: float) -> void:
	_announce_a_crash()
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

	# The late evening for a moment, then 02:00 brings the night itself.
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
	var collections_up: bool = state == _router.COLLECTIONS
	if _ident != null:
		# **Not while the crash dialogue is up**, because then it is a lie:
		# the dialogue has the keyboard, and a screen that says PRESS ANY
		# KEY under a panel where any key does nothing is a screen a player
		# reasonably concludes is frozen.
		_ident.visible = state == _router.TITLE and not _crash_is_up()
		_ident.text = I18n.t(&"TITLE_PRESS_ANY")
	if _menu != null:
		_menu.visible = menu_up
		if menu_up:
			_focus_menu()
	if _trouble != null:
		# With the menu, because that is where CONTINUE is missing from and
		# this is the sentence that says why.
		_trouble.visible = menu_up and _why != Save.NO_SAVE
	if _options != null:
		_options.visible = options_up
	if _stats != null:
		_stats.visible = stats_up
		if stats_up:
			_stats.show_state(_state)
			_stats.show_profile(Save.read_profile())
	if _collections != null:
		# **No run under the title**: the backdrop's farm is not the
		# player's, so the book is the profile's alone.
		if collections_up and not _collections.is_open():
			_collections.show_state({})
			_collections.show_profile(Save.read_profile())
		_collections.visible = collections_up


## The first entry takes the selection - and with it the caret - whenever
## the menu comes up.
func _focus_menu() -> void:
	MenuFocus.select_first(_menu.get_children())


func _unhandled_input(event: InputEvent) -> void:
	# **The dialogue has the keyboard while it is up.** "Press any key" and
	# a dialogue with two buttons on it cannot both be true, and the one
	# that has something to say wins.
	if _crash != null and _crash.showing():
		return
	if _router == null or _router.here() != _router.TITLE:
		return
	# **Any key or click.** Not a named action: a player who has just started
	# the game has not learned any of them, and "press any key" has to be
	# true.
	if ActionsScript.is_any_press(event):
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
	# **Whether it loads, not whether it exists.** A CONTINUE that throws
	# away the run it offered to resume is worse than no CONTINUE: the rule
	# at the top of this file is that an entry with nowhere to go is absent,
	# and a save this build cannot read is nowhere to go.
	var saved := Save.can_continue()
	# **Taken here, not asked for later.** `Save.trouble()` is about the last
	# read, and the line above is that read - so the answer is caught while
	# it is the right one rather than by a second function happening to run
	# next. A planted bug found this: take `can_continue()` away and the
	# notice went blank, because nothing had read the file that frame.
	_why = Save.trouble()
	_wear_trouble()
	for entry in ENTRIES:
		var which: StringName = entry[0]
		if not is_shown(which, saved):
			continue
		var button := Button.new()
		button.name = "Menu_%s" % which
		button.text = I18n.t(entry[1])
		button.custom_minimum_size = Vector2(140, 16)
		button.focus_mode = Control.FOCUS_ALL
		button.pressed.connect(_pick.bind(which))
		_menu.add_child(button)
	# **One selection for the keys, the pointer and a pad**, with the caret,
	# wrapping and the menu's sounds - WELCOME BACK, HERO's lists.
	_menu.theme_type_variation = UiKit.STACKED
	MenuFocus.wire(_menu.get_children())


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
			# **The one-shot the run reads on the way in.** Task 0096 both
			# writes the save - from the pause menu - and makes this pick it
			# up; any other way into a run starts fresh, which is what keeps
			# a save written by one check out of the next one.
			_router.ask_to_resume()
			_router.goto(_router.RUN)
		&"stats":
			_router.goto(_router.STATS)
		&"collections":
			_router.goto(_router.COLLECTIONS)
		&"options":
			_router.goto(_router.OPTIONS)
		&"quit":
			get_tree().quit()


func _input(event: InputEvent) -> void:
	# The records screen has its own key to close; this is the other way out,
	# and both end at the same place because both go through the router.
	if _router == null or not event.is_action_pressed(&"cancel"):
		return
	# **The options screen answers its own escape** (2026-10-07): it may have
	# something to end first - a key being listened for, a new window size
	# waiting to be kept - and this runs before it would hear the key.
	if _router.here() == _router.STATS or _router.here() == _router.COLLECTIONS:
		_router.back()
		MenuFocus.backed_out(self)
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


## The report waiting to be announced, or "" when there is nothing to say.
var _to_announce := ""

var _crash: CrashDialog


## Put the crash dialogue up on the first frame of the title.
##
## **Not in `_ready`**, so it lands on a title that is already built. The
## studio ident is a scene of its own ahead of this one now, so there is no
## ident on this screen for a key meant for the dialogue to skip.
func _announce_a_crash() -> void:
	if _to_announce == "" or _crash == null:
		return
	var folder := _to_announce
	_to_announce = ""
	_crash.show_report(folder)
	if not _crash.closed.is_connected(_crash_closed):
		_crash.closed.connect(_crash_closed)
	_wear(_router.here() if _router != null else 0)


## Whether the dialogue has the screen.
func _crash_is_up() -> bool:
	return _crash != null and _crash.showing()


## It has been read and put away: the title screen is a title screen again.
func _crash_closed() -> void:
	_wear(_router.here() if _router != null else 0)


# ------------------------------------------------------- for the checks, 0103

## Which report is waiting, for a check that wants to watch it arrive.
func announcing() -> String:
	return _to_announce


var _trouble: PanelContainer
var _trouble_text: Label

## What the last read of the run had to say, caught when it was read.
var _why: StringName = &""


## Say that there is a run on the disk this build cannot read.
##
## **Three things, because a player needs all three**: that it could not be
## read, why - as far as anybody can tell from outside - and that the file has
## not been thrown away. The third is the one that matters: somebody whose
## save will not open should know the file is still sitting there before they
## press NEW GAME, because a later build may well read it.
func _wear_trouble() -> void:
	if _trouble == null or _trouble_text == null:
		return
	if _why == Save.NO_SAVE:
		_trouble_text.text = ""
		_trouble.visible = false
		return
	_trouble_text.text = "%s%s%s%s%s" % [I18n.t(&"SAVE_UNREADABLE"),
		"\n", I18n.t(_why), "\n", I18n.t(&"SAVE_KEPT")]
	_trouble_text.theme_type_variation = UiKit.WARN
	_trouble.visible = _router != null and _router.here() == _router.MENU


# --------------------------------------------------- for the checks, 0104

## What the title is saying about the save, if anything.
func trouble_says() -> String:
	return _trouble_text.text if _trouble_text != null else ""
