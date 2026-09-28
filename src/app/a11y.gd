class_name A11y
extends Node

## The settings that decide whether somebody can play this at all.
##
## **Most of the work was already done and nothing turned it.** Screen shake
## has been scaled by `a11y/screen_shake` since task 0055, the lamps have
## checked `a11y/flashing` since 0076, the emitters have scaled themselves by
## `a11y/particle_density` since 0077 and hit stop has read `a11y/hit_stop`
## since 0088. What task 0098 adds is the four that had nobody reading them,
## a screen to turn all of them, and a marking on damage that does not depend
## on being able to tell red from gold.
##
## Static, with the `Access` autoload behind it, for the same reason `I18n`
## is: `verify.py` parses every script alone, so a `class_name` is nameable
## and an autoload is not.
##
## ## What a 480x270 game can honestly call a bigger UI
##
## Not a bigger font: the HUD is laid out in whole pixels against a viewport
## that is 480 across, and doubling the text would put half of it off the
## edge. `content_scale_factor` scales **everything** instead - the world with
## the words - so a player who needs it bigger gets it bigger and sees a
## little less farm. That is the trade a pixel game has; pretending otherwise
## would mean a second layout nobody maintains.
##
## ## Slower is fewer ticks a second, not different ticks
##
## `a11y/slow` scales the **budget**, which is real seconds, and never the
## rate. The simulation still runs at a fixed thirty a second's worth of
## ticks; it just takes longer to be handed them. So a night played at half
## speed is the same night - the determinism hash cannot tell, and a check
## says so.

## How much slower the game may be asked to run.
const SLOWS: Array = [1.0, 0.75, 0.5]

## And how much bigger the picture may be asked to be.
const SCALES: Array = [1.0, 1.25, 1.5]

## **Damage types, told apart without colour.** A mark on the end of the
## number, in the game's own font, because a shape survives greyscale,
## a colour-blind eye and a bad monitor - and the colour stays as well, for
## everybody who can see it.
const MARKS: Dictionary = {
	&"impact": "+",
	&"fire": "^",
	&"explosive": "*",
}

## The settings this screen owns, in the order it shows them.
const KEYS: Array = [
	&"a11y/screen_shake",
	&"a11y/flashing",
	&"a11y/hit_stop",
	&"a11y/particle_density",
	&"a11y/ui_scale",
	&"a11y/high_contrast",
	&"a11y/hold_to_act",
	&"a11y/slow",
]

## Set while `apply()` is running, so what it writes is not mistaken for
## somebody changing their mind.
var _applying := false


func _ready() -> void:
	var settings := _settings()
	if settings != null:
		if not settings.changed.is_connected(_on_changed):
			settings.changed.connect(_on_changed)
		if not settings.reloaded.is_connected(apply):
			settings.reloaded.connect(apply)
	apply()


# ------------------------------------------------------------------ the rules

## The mark that goes on a damage number of this type.
static func mark_of(type: StringName) -> String:
	return String(MARKS.get(type, ""))


## Whether two damage types can be told apart with no colour at all.
##
## Its own function so a check can ask it rather than infer it from a picture:
## the done-when is "every damage type is identifiable in greyscale", and a
## mark that two types share is not identifiable.
static func distinct_marks() -> bool:
	var seen: Dictionary = {}
	for type in MARKS:
		var mark := String(MARKS[type])
		if mark == "" or seen.has(mark):
			return false
		seen[mark] = true
	return true


## Snap a number to one the screen offers, so a hand-edited config cannot put
## the game somewhere the screen cannot get it back from.
static func nearest(value: float, offered: Array) -> float:
	var best := float(offered[0])
	for one in offered:
		if absf(float(one) - value) < absf(best - value):
			best = float(one)
	return best


# --------------------------------------------------------------- applying it

## Put the two that are not read by anybody else onto the tree.
##
## Shake, flashing, particles and hit stop are read where they are used, every
## frame, by the screens that do those things - there is nothing to apply.
## The picture's scale and the contrast are properties of the whole tree, so
## they are set here.
func apply() -> void:
	_applying = true
	var tree := _tree()
	var settings := _settings()
	if tree != null and settings != null:
		var scale := nearest(float(settings.get_float(&"a11y/ui_scale")),
			SCALES)
		if not is_equal_approx(tree.root.content_scale_factor, scale):
			tree.root.content_scale_factor = scale
		_dress(tree, bool(settings.get_bool(&"a11y/high_contrast")))
	_applying = false


## How much of a second of real time counts as a second of game.
func slow() -> float:
	var settings := _settings()
	if settings == null:
		return 1.0
	return nearest(float(settings.get_float(&"a11y/slow")), SLOWS)


## Whether holding a button keeps doing the thing.
func holding() -> bool:
	var settings := _settings()
	return settings == null or bool(settings.get_bool(&"a11y/hold_to_act"))


func contrast() -> bool:
	var settings := _settings()
	return settings != null and bool(settings.get_bool(&"a11y/high_contrast"))


func scale() -> float:
	var settings := _settings()
	if settings == null:
		return 1.0
	return nearest(float(settings.get_float(&"a11y/ui_scale")), SCALES)


# ----------------------------------------------------------------- privately

## Rebuild the one `Theme` every screen wears, in the contrast that is asked
## for. `UiKit.dress` walks the tree and hands the same object to everything,
## so this is one allocation and not one per screen.
func _dress(tree: SceneTree, high: bool) -> void:
	if UiKit.high_contrast() == high:
		return
	UiKit.set_high_contrast(high)
	for child in tree.root.get_children():
		UiKit.dress(child)


func _on_changed(key: StringName) -> void:
	if _applying:
		return
	if String(key).begins_with("a11y/"):
		apply()


func _tree() -> SceneTree:
	var loop := Engine.get_main_loop() as SceneTree
	return loop if loop != null and loop.root != null else null


func _settings() -> Node:
	var tree := _tree()
	return tree.root.get_node_or_null(^"Settings") if tree != null else null
