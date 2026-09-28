extends Node

## Which screen is up, and how to get back.
##
## **One place decides, and screens stop knowing about each other.** Before
## this, the title called `change_scene_to_file` itself and the run's panels
## opened one another by name; now everything says `App.goto(App.STATS)` and
## whatever is listening shows itself.
##
## ## Two sorts of state
##
## `SCENES` are a whole scene of their own - the title and the run. Going to
## one of those is a change of scene and **clears the back stack**, because
## there is no going back from a run into the title screen you left: the title
## screen no longer exists.
##
## Everything else is an overlay that sits over whichever scene is up, and
## going to one **pushes**. That is the whole of "Options returns to whoever
## opened it": opened from the title menu it returns to the menu, opened from
## a paused run it returns to the pause menu, and neither of them had to know
## the other existed.
##
## ## It works with no tree at all
##
## Every decision here is arithmetic on an integer and an array, so
## `headless_check` drives the whole state machine without building a game.
## The one thing that needs a tree - actually changing the scene - is guarded
## and reported, so a check can watch the router decide and a player gets the
## scene.
##
## ## `/root/` is not banned, reaching across screens is
##
## Task 0092 asks for no `get_node("/root/...")` between screens, and this is
## what replaces it. The **autoloads** are still reached by path - `Settings`,
## `Audio`, and this - because `verify.py` parses every script on its own with
## no autoloads registered, so naming one is a parse error for a file that is
## perfectly correct at runtime. An autoload is a service; a screen is not.

enum {
	BOOT,
	TITLE,
	MENU,
	RUN,
	TECH,
	STATS,
	OPTIONS,
	SUMMARY,
}

## Every state, in order, for the checks and for printing.
const STATES: Array = [BOOT, TITLE, MENU, RUN, TECH, STATS, OPTIONS, SUMMARY]

const NAMES: Dictionary = {
	BOOT: "BOOT",
	TITLE: "TITLE",
	MENU: "MENU",
	RUN: "RUN",
	TECH: "TECH",
	STATS: "STATS",
	OPTIONS: "OPTIONS",
	SUMMARY: "SUMMARY",
}

## The states that are a scene of their own.
const SCENES: Dictionary = {
	TITLE: "res://scenes/Title.tscn",
	MENU: "res://scenes/Title.tscn",
	RUN: "res://scenes/Main.tscn",
}

## How deep the stack may get. **A stack that can grow is a leak**, and a
## player who has opened the records screen from the options screen from the
## pause menu has already gone further than anybody designed for.
const MAX_DEPTH := 8

signal state_changed(to: int, from: int)

var _here := BOOT
var _stack: Array = []

## How many times a scene change has been asked for, and the last one asked
## for. Read by the checks, which have no business changing scenes.
var _changes := 0
var _last_scene := ""


func here() -> int:
	return _here


func depth() -> int:
	return _stack.size()


func name_of(state: int) -> String:
	return String(NAMES.get(state, "?"))


## Whether a state is a whole scene rather than something over one.
func is_scene(state: int) -> bool:
	return SCENES.has(state)


## Go somewhere.
##
## Returns false when it was already there, so a screen may say what it wants
## every frame without the router doing anything about it.
func goto(to: int) -> bool:
	if not NAMES.has(to):
		push_error("App: no state %d" % to)
		return false
	if to == _here:
		return false
	var from := _here

	if is_scene(to):
		# **A change of scene forgets the way back.** See the note at the top.
		# Two states can share a scene - the title's ident and its menu do -
		# and moving between those two is not a change of scene at all.
		_stack.clear()
		_here = to
		if String(SCENES[to]) != _last_scene:
			_change_scene(String(SCENES[to]))
	else:
		if _stack.size() >= MAX_DEPTH:
			push_error("App: %s is too deep to open from %s"
				% [name_of(to), name_of(_here)])
			return false
		_stack.append(from)
		_here = to
	state_changed.emit(_here, from)
	return true


## Back to whoever opened this. False at the bottom, where there is no back.
func back() -> bool:
	if _stack.is_empty():
		return false
	var from := _here
	_here = int(_stack.pop_back())
	state_changed.emit(_here, from)
	return true


## Back all the way out of every overlay, to the scene underneath.
func close_overlays() -> void:
	while back():
		pass


## Begin again from a state that is already up.
##
## **It records the scene that state lives in**, which the first version did
## not: `TITLE` and `MENU` are two states of one scene, and a router that did
## not know the title scene was already loaded reloaded it the moment a key
## moved from the ident to the menu. The screen came back and the key looked
## like it had done nothing.
func reset(to: int = BOOT) -> void:
	_stack.clear()
	_here = to
	_changes = 0
	_last_scene = String(SCENES.get(to, ""))


func scene_changes() -> int:
	return _changes


func last_scene() -> String:
	return _last_scene


func _change_scene(path: String) -> void:
	_changes += 1
	_last_scene = path
	# **Guarded, so the router is testable without a window.** A check drives
	# the whole state machine and reads `last_scene()`; a player gets the
	# scene.
	if not is_inside_tree():
		return
	var tree := get_tree()
	if tree == null:
		return
	tree.call_deferred("change_scene_to_file", path)
