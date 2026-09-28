extends Node

## Puts the video settings on the window, and takes a bad one back.
##
## `Settings` has held `video/window_mode`, `video/scale` and the rest since
## task 0009 and **nothing has ever applied them**: the game came up at
## whatever `project.godot` said and the keys were a promise nobody kept.
## This is the sibling of `Audio`, which does the same job for the buses -
## applied on boot and again whenever a key changes, which is what makes
## "survives a restart" true rather than hoped for.
##
## ## A bad mode cannot strand the player
##
## A resolution the monitor cannot show, or a fullscreen mode a driver
## refuses, leaves a player looking at nothing - and the control that would
## put it back is on the screen they can no longer see. So every change of
## mode is **provisional**: it applies at once and starts a countdown, and if
## nobody confirms it inside `REVERT_SECONDS` it goes back to what worked.
##
## The countdown lives here rather than in the options screen for exactly
## that reason: the screen is the thing that may have become unreadable.
##
## ## Integer scaling is the whole reason this task is not a checkbox
##
## The game is drawn at 480x270 and stretched. At a whole multiple of that
## every game pixel is the same square block of screen pixels. At anything
## else some pixels are two screen pixels wide and their neighbours are three,
## which crawls when the camera moves. So the resolution list **marks** the
## multiples rather than hiding the rest: a 1366x768 laptop and a 1920x1200
## monitor have no multiple at their own size, and a game that refused to run
## at native on them would be a game being clever at the player's expense.

## What the game is drawn at, before any of this.
const BASE := Vector2i(480, 270)

## How long a new mode has to be confirmed before it is undone. **Under the
## ten seconds the task allows**, because ten seconds of a black screen is a
## long time when you are not sure the game is still running.
const REVERT_SECONDS := 8.0

## How many multiples to offer at most, largest first. A 4K monitor fits eight
## of them and 480x270 on a 4K monitor is a postage stamp nobody wants.
const MOST := 5

## The three window modes, in the order the screen offers them.
const WINDOWED := 0
const BORDERLESS := 1
const FULLSCREEN := 2

const MODE_NAMES: Dictionary = {
	WINDOWED: "WINDOWED",
	BORDERLESS: "BORDERLESS",
	FULLSCREEN: "FULLSCREEN",
}

## The frame caps the screen offers. Zero is uncapped.
const FPS_CAPS: Array = [0, 60, 120, 144, 240]

## What is pending, and how long it has left.
var _pending: Dictionary = {}
var _left := 0.0

## Set while `apply()` is running, so the settings it writes do not look like
## a player changing their mind.
var _applying := false


func _ready() -> void:
	var settings := _settings()
	if settings != null and not settings.changed.is_connected(_on_changed):
		settings.changed.connect(_on_changed)
		settings.reloaded.connect(apply)
	apply()


func _process(delta: float) -> void:
	if _left <= 0.0:
		return
	_left = maxf(_left - delta, 0.0)
	if _left <= 0.0:
		revert()


# ----------------------------------------------------------------- the maths

## Every whole multiple of the base that fits on a monitor this size.
##
## Static and given the monitor, so a check can ask it about a screen nobody
## has - which is the only way to test a resolution list that is built from
## the hardware.
static func multiples_on(monitor: Vector2i) -> Array:
	var out: Array = []
	var n := 1
	while BASE.x * n <= monitor.x and BASE.y * n <= monitor.y:
		out.append(n)
		n += 1
	# **Never empty.** A monitor smaller than 480x270 does not exist any more,
	# but a game that offered no resolutions at all on one would be a game
	# that could not be started.
	if out.is_empty():
		out.append(1)
	return out


## The resolution list: what fits, smallest first, each saying whether it is a
## whole multiple and which one.
##
## Every entry is `{"size": Vector2i, "scale": int, "crisp": bool}`, where
## `scale` is 0 for a size that is not a multiple. The monitor's own size is
## always in the list even when it is not one, because that is the size a
## borderless window ends up at and the one most players want.
static func sizes_on(monitor: Vector2i) -> Array:
	var all := multiples_on(monitor)
	if all.size() > MOST:
		all = all.slice(all.size() - MOST)

	var out: Array = []
	for scale in all:
		out.append({
			"size": size_of(int(scale)),
			"scale": int(scale),
			"crisp": true,
		})

	var native := Vector2i(maxi(monitor.x, BASE.x), maxi(monitor.y, BASE.y))
	var already := false
	for entry in out:
		if entry["size"] == native:
			already = true
	if not already:
		out.append({"size": native, "scale": 0, "crisp": false})
		out.sort_custom(func(a, b): return _area(a["size"]) < _area(b["size"]))
	return out


static func _area(size: Vector2i) -> int:
	return size.x * size.y


static func size_of(scale: int) -> Vector2i:
	return BASE * maxi(scale, 1)


## Whether a window this size shows square pixels.
static func is_crisp(size: Vector2i) -> bool:
	if size.x % BASE.x != 0 or size.y % BASE.y != 0:
		return false
	return size.x / BASE.x == size.y / BASE.y


## The largest multiple that fits, for a first run with nothing saved.
static func best_on(monitor: Vector2i) -> int:
	var all := multiples_on(monitor)
	return int(all[all.size() - 1])


## A size as it is written in the settings file, and back again.
##
## A string rather than a `Vector2i` because the config is read by hand as
## often as by the game, and `size=1366x768` says what it means.
static func text_of(size: Vector2i) -> String:
	return "%dx%d" % [size.x, size.y]


static func size_from(text: String) -> Vector2i:
	var parts := text.split("x", false)
	if parts.size() != 2 or not parts[0].is_valid_int() \
			or not parts[1].is_valid_int():
		return Vector2i.ZERO
	var found := Vector2i(int(parts[0]), int(parts[1]))
	if found.x < BASE.x or found.y < BASE.y:
		return Vector2i.ZERO
	return found


# ------------------------------------------------------------------ applying

## The window size the settings ask for: the saved size if there is one, and
## the saved multiple otherwise.
func window_size() -> Vector2i:
	var settings := _settings()
	if settings == null:
		return size_of(3)
	var written := size_from(String(settings.get_string(&"video/size")))
	if written != Vector2i.ZERO:
		return written
	return size_of(int(settings.get_int(&"video/scale")))


## Put every video setting on the window. Safe with no display at all.
func apply() -> void:
	_applying = true
	var settings := _settings()
	var mode := int(settings.get_int(&"video/window_mode")) \
		if settings != null else WINDOWED
	var vsync := bool(settings.get_bool(&"video/vsync")) if settings != null \
		else true
	var cap := int(settings.get_int(&"video/max_fps")) if settings != null \
		else 0
	var crisp := bool(settings.get_bool(&"video/integer_scaling")) \
		if settings != null else true
	_put(mode, window_size(), vsync, cap, crisp)
	_applying = false


## Try a window mode and a size, and take them back if nobody says otherwise.
##
## Returns what was there before, which is what the screen shows in its
## "keep this?" line. An empty dictionary means nothing changed.
func try_mode(mode: int, size: Vector2i) -> Dictionary:
	var settings := _settings()
	if settings == null:
		return {}
	var was := {
		"window_mode": int(settings.get_int(&"video/window_mode")),
		"scale": int(settings.get_int(&"video/scale")),
		"size": String(settings.get_string(&"video/size")),
	}
	var crisp_scale := size.x / BASE.x if is_crisp(size) else 0
	var want_size := "" if crisp_scale > 0 else text_of(size)
	var want_scale := crisp_scale if crisp_scale > 0 else int(was["scale"])
	if was["window_mode"] == mode and was["scale"] == want_scale \
			and was["size"] == want_size:
		return {}
	_pending = was
	_left = REVERT_SECONDS
	settings.set_value(&"video/window_mode", mode)
	settings.set_value(&"video/scale", want_scale)
	settings.set_value(&"video/size", want_size)
	apply()
	return was


## The player can see it, so it stays.
func keep() -> void:
	_pending = {}
	_left = 0.0


## Put back whatever worked before.
func revert() -> void:
	var settings := _settings()
	_left = 0.0
	if _pending.is_empty() or settings == null:
		_pending = {}
		return
	settings.set_value(&"video/window_mode", int(_pending["window_mode"]))
	settings.set_value(&"video/scale", int(_pending["scale"]))
	settings.set_value(&"video/size", String(_pending["size"]))
	_pending = {}
	apply()


func waiting() -> bool:
	return _left > 0.0


func seconds_left() -> float:
	return _left


func pending_from() -> Dictionary:
	return _pending.duplicate()


## The monitor, or a sensible answer when there is no display at all.
func monitor() -> Vector2i:
	if DisplayServer.get_name() == "headless":
		return Vector2i(1920, 1080)
	var found := DisplayServer.screen_get_size(
		DisplayServer.window_get_current_screen())
	return found if found.x > 0 and found.y > 0 else Vector2i(1920, 1080)


# ---------------------------------------------------------------- privately

func _on_changed(key: StringName) -> void:
	if _applying:
		return
	if String(key).begins_with("video/"):
		apply()


func _put(mode: int, size: Vector2i, vsync: bool, cap: int,
		crisp: bool) -> void:
	Engine.max_fps = maxi(cap, 0)

	# **The stretch is where integer scaling lives.** Not the window: a window
	# of any size can show square pixels, and a window of a perfect size can
	# show smeared ones. The root viewport is what decides - and on a window
	# that is not a multiple, INTEGER draws the largest whole multiple that
	# fits and puts bars round it, which is the right answer and the reason a
	# non-multiple size is safe to offer at all.
	var tree := _tree()
	if tree != null:
		tree.root.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_INTEGER \
			if crisp else Window.CONTENT_SCALE_STRETCH_FRACTIONAL

	if DisplayServer.get_name() == "headless":
		return
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)
	match mode:
		FULLSCREEN:
			DisplayServer.window_set_flag(
				DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			DisplayServer.window_set_mode(
				DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		BORDERLESS:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			DisplayServer.window_set_flag(
				DisplayServer.WINDOW_FLAG_BORDERLESS, true)
		_:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(
				DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			DisplayServer.window_set_size(size)
			# Middle of the screen, so a window that just grew is not half off
			# the bottom of it.
			var screen := DisplayServer.window_get_current_screen()
			DisplayServer.window_set_position(
				(DisplayServer.screen_get_size(screen) - size) / 2
				+ DisplayServer.screen_get_position(screen))


func _settings() -> Node:
	var tree := _tree()
	return tree.root.get_node_or_null(^"Settings") if tree != null else null


## The scene tree, asked of the engine rather than of this node.
##
## `get_tree()` errors with "Parameter data.tree is null" on a node that is
## not in the tree, and - measured - a node added to `root` before the main
## loop starts is not in it yet even though `root` already holds it. The main
## loop is there either way.
func _tree() -> SceneTree:
	var loop := Engine.get_main_loop() as SceneTree
	return loop if loop != null and loop.root != null else null
