class_name UiKit
extends RefCounted

## The panels, frames and buttons, and one icon per resource.
##
## **One kit, so four screens look like one game.** The day HUD, the night
## HUD, the shop and the tech tree each grew their own `StyleBoxFlat` with its
## own colours as they were written, which is four places to change a border
## and four chances to miss one. Everything here is generated from
## `tools/sprite_maps.py` like the rest of the art, and anything that wants a
## panel asks for the same one.
##
## ## Nine-slice, and the margin is three
##
## Every frame is sixteen by sixteen with a three pixel border and a middle
## that repeats, so one drawing serves a tooltip, a shop panel and the whole
## tech tree at whatever size each needs. `headless_check` asserts the border
## in the art and `MARGIN` here agree, because two numbers that have to match
## and live in different files are two numbers that will not.
##
## ## Nothing here is a rule
##
## `src/ui/` draws and owns no rules, and this is the drawing half of the
## drawing half. It reads `GameData.RESOURCES` to know what icons to expect
## and writes nothing anywhere.

const DIR := "res://sprites/ui/"

## The border of every nine-slice frame, in pixels.
##
## **Three, because that is what the drawings have.** It was five here and
## three in the art, which slices a frame four pixels into its own middle -
## the check that reads `panel.png` and counts caught it on the first run.
## Two numbers that have to match and live in different files are two numbers
## that will not, so that check stays.
const MARGIN := 3

## The four a button can be in. Godot's own names, so wiring one up is
## `add_theme_stylebox_override(state, UiKit.button(state))`.
const BUTTON_STATES := ["normal", "hover", "pressed", "disabled"]

## Loaded once each. A panel asking for its background every frame would
## otherwise be a file read every frame.
static var _cache: Dictionary = {}


## The icon for a resource, or null when nobody has drawn one.
static func icon(id: StringName) -> Texture2D:
	return _texture("icon_%s" % id)


## Whether every resource has one and no icon is orphaned. The done-when of
## task 0079, asked as a question rather than left to a person to check.
static func missing_icons() -> Array:
	var out: Array = []
	for id in GameData.RESOURCES:
		if icon(StringName(id)) == null:
			out.append(str(id))
	return out


## Icons in `sprites/ui/` that no resource claims.
static func orphan_icons() -> Array:
	var wanted: Dictionary = {}
	for id in GameData.RESOURCES:
		wanted["icon_%s" % id] = true
	var out: Array = []
	var folder := DirAccess.open(DIR)
	if folder == null:
		return out
	for name in folder.get_files():
		if not name.begins_with("icon_") or not name.ends_with(".png"):
			continue
		var stem := name.substr(0, name.length() - 4)
		if not wanted.has(stem):
			out.append(stem)
	out.sort()
	return out


# ------------------------------------------------------------------ the frames

## The frame a panel sits in.
static func panel() -> StyleBox:
	return _frame("panel")


## The quieter one a tooltip sits in.
static func tooltip() -> StyleBox:
	return _frame("tooltip")


## The one a tab sits in - a panel with its bottom edge open, so it reads as
## joined to what is under it.
static func tab() -> StyleBox:
	return _frame("tab", 0)


## A button in one of `BUTTON_STATES`.
static func button(state: String) -> StyleBox:
	return _frame("button_%s" % state)


## The rail a slider runs along, and the thing that runs along it.
static func slider_track() -> StyleBox:
	return _frame("slider_track", 2, 2)


static func slider_grab() -> Texture2D:
	return _texture("slider_grab")


static func checkbox(ticked: bool) -> Texture2D:
	return _texture("checkbox_on" if ticked else "checkbox_off")


## A nine-slice box off one of the drawings.
##
## `bottom` and `top` default to `MARGIN` and are given only where a frame is
## deliberately open on one side.
static func _frame(name: String, bottom: int = MARGIN,
		top: int = MARGIN) -> StyleBox:
	var texture := _texture(name)
	if texture == null:
		# **A flat box rather than nothing.** A missing frame should look
		# wrong on screen, not crash the panel that asked for it.
		var flat := StyleBoxFlat.new()
		flat.bg_color = Color(0.10, 0.09, 0.16, 0.92)
		flat.set_border_width_all(1)
		flat.border_color = Color(0.42, 0.37, 0.30, 0.75)
		return flat
	var box := StyleBoxTexture.new()
	box.texture = texture
	box.texture_margin_left = MARGIN
	box.texture_margin_right = MARGIN
	box.texture_margin_top = top
	box.texture_margin_bottom = bottom
	return box


static func _texture(name: String) -> Texture2D:
	if _cache.has(name):
		return _cache[name]
	var path := DIR + name + ".png"
	var found: Texture2D = load(path) if ResourceLoader.exists(path) else null
	_cache[name] = found
	return found
