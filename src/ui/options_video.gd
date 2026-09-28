class_name OptionsVideo
extends Control

## The video tab: how big, which window, and whether the pixels stay square.
##
## It owns no policy. Every decision is `Video`'s - which resolutions fit,
## which of them are whole multiples, how long a new mode has to be confirmed -
## and this draws them and hands clicks back. That is what makes the awkward
## half of this task testable without a monitor.
##
## ## The note under the sizes is not decoration
##
## Integer scaling is on by default, and both of the things it can say are
## things a player needs: with it on, **which sizes are the good ones** (the
## ones marked `x2`, `x3`); with it off, **what they just gave up**. "Integer
## scaling" means nothing to most people and "the pixels stop being square"
## means something to everybody. A setting whose only explanation is its own
## name is a setting people flip at random to see which they prefer, and this
## one has a right answer.

## Shown when square pixels are off.
const WARNING := ("off: pixels stop being square and the art crawls"
	+ " when the camera moves")

## Shown when they are on, as the key to the marks on the size buttons.
##
## **It does not name the multiples**, because how many there are comes off
## the monitor: a 1080p screen offers up to x4 and a 1440p one up to x5.
const LEGEND := ("the xN sizes are whole multiples of 480x270 -"
	+ " square pixels, no crawling")

var _video: Node
var _settings: Node

var _modes: HBoxContainer
var _sizes: HFlowContainer
var _crisp: Button
var _note: Label
var _vsync: Button
var _caps: HBoxContainer
var _keep: Button
var _countdown: Label


func _ready() -> void:
	_video = get_node_or_null(^"/root/Video")
	_settings = get_node_or_null(^"/root/Settings")
	set_anchors_preset(Control.PRESET_FULL_RECT)
	if _settings != null:
		_settings.changed.connect(_on_setting)
		_settings.reloaded.connect(_fill)

	var column := VBoxContainer.new()
	column.name = "VideoColumn"
	column.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(column)

	_modes = _row(column, "WINDOW", HBoxContainer.new()) as HBoxContainer
	_sizes = _row(column, "SIZE", HFlowContainer.new()) as HFlowContainer

	_crisp = _switch(column, "SQUARE PIXELS", "VideoCrisp", _toggle_crisp)

	_note = Label.new()
	_note.name = "VideoNote"
	_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_note.custom_minimum_size = Vector2(330, 16)
	column.add_child(_note)

	_vsync = _switch(column, "VSYNC", "VideoVsync", _toggle_vsync)
	_caps = _row(column, "FPS CAP", HBoxContainer.new()) as HBoxContainer

	var keeping := HBoxContainer.new()
	keeping.name = "VideoKeepRow"
	keeping.theme_type_variation = UiKit.SPACED
	column.add_child(keeping)
	_countdown = Label.new()
	_countdown.name = "VideoCountdown"
	_countdown.theme_type_variation = UiKit.BAD
	_countdown.custom_minimum_size = Vector2(230, 0)
	keeping.add_child(_countdown)
	_keep = Button.new()
	_keep.name = "VideoKeep"
	_keep.text = "KEEP"
	_keep.custom_minimum_size = Vector2(56, 14)
	_keep.focus_mode = Control.FOCUS_ALL
	_keep.pressed.connect(_keep_it)
	keeping.add_child(_keep)

	_fill()


func _row(column: VBoxContainer, title: String, holder: Container) -> Container:
	var row := HBoxContainer.new()
	var bare := title.replace(" ", "")
	row.name = "Video%sRow" % bare
	row.theme_type_variation = UiKit.SPACED
	column.add_child(row)
	var label := Label.new()
	label.text = title
	label.custom_minimum_size = Vector2(76, 0)
	label.theme_type_variation = UiKit.DIM
	row.add_child(label)
	holder.name = "Video%sChoices" % bare
	holder.theme_type_variation = UiKit.SPACED
	holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(holder)
	return holder


func _switch(column: VBoxContainer, title: String, called: String,
		when: Callable) -> Button:
	var row := HBoxContainer.new()
	row.name = "%sRow" % called
	row.theme_type_variation = UiKit.SPACED
	column.add_child(row)
	var label := Label.new()
	label.text = title
	label.custom_minimum_size = Vector2(76, 0)
	label.theme_type_variation = UiKit.DIM
	row.add_child(label)
	var button := Button.new()
	button.name = called
	button.toggle_mode = true
	button.custom_minimum_size = Vector2(40, 14)
	button.focus_mode = Control.FOCUS_ALL
	button.pressed.connect(when)
	row.add_child(button)
	return button


func _process(_delta: float) -> void:
	if not visible or _video == null:
		return
	var waiting: bool = _video.waiting()
	_keep.visible = waiting
	_countdown.visible = waiting
	if waiting:
		_countdown.text = "KEEP THIS? BACK IN %ds" \
			% int(ceil(float(_video.seconds_left())))


# -------------------------------------------------------------- the choices

func _fill() -> void:
	if _video == null or _settings == null:
		return
	_fill_modes()
	_fill_sizes()
	_fill_caps()
	_crisp.button_pressed = bool(_settings.get_bool(&"video/integer_scaling"))
	_crisp.text = "ON" if _crisp.button_pressed else "OFF"
	_note.text = LEGEND if _crisp.button_pressed else WARNING
	_note.theme_type_variation = UiKit.DIM if _crisp.button_pressed \
		else UiKit.WARN
	_vsync.button_pressed = bool(_settings.get_bool(&"video/vsync"))
	_vsync.text = "ON" if _vsync.button_pressed else "OFF"
	_keep.visible = false
	_countdown.visible = false


func _fill_modes() -> void:
	_clear(_modes)
	var now: int = _settings.get_int(&"video/window_mode")
	for mode in [_video.WINDOWED, _video.BORDERLESS, _video.FULLSCREEN]:
		var button := Button.new()
		button.name = "VideoMode_%d" % int(mode)
		button.text = String(_video.MODE_NAMES[mode])
		button.toggle_mode = true
		button.button_pressed = int(mode) == now
		button.theme_type_variation = UiKit.TAB
		button.custom_minimum_size = Vector2(74, 14)
		button.focus_mode = Control.FOCUS_ALL
		button.pressed.connect(_pick_mode.bind(int(mode)))
		_modes.add_child(button)


## **The list comes off the monitor**, and the whole multiples are marked with
## the multiple they are. The rest are offered too - a 1366x768 laptop has no
## multiple at its own size, and refusing to run at native there would be the
## game being clever at the player's expense.
func _fill_sizes() -> void:
	_clear(_sizes)
	var now: Vector2i = _video.window_size()
	for entry in _video.sizes_on(_video.monitor()):
		var size: Vector2i = entry["size"]
		var button := Button.new()
		button.name = "VideoSize_%dx%d" % [size.x, size.y]
		button.text = "%dx%d x%d" % [size.x, size.y, int(entry["scale"])] \
			if bool(entry["crisp"]) else "%dx%d" % [size.x, size.y]
		button.toggle_mode = true
		button.button_pressed = size == now
		button.theme_type_variation = UiKit.TAB
		button.custom_minimum_size = Vector2(78, 14)
		button.focus_mode = Control.FOCUS_ALL
		button.pressed.connect(_pick_size.bind(size))
		_sizes.add_child(button)


func _fill_caps() -> void:
	_clear(_caps)
	var now: int = _settings.get_int(&"video/max_fps")
	for cap in _video.FPS_CAPS:
		var button := Button.new()
		button.name = "VideoCap_%d" % int(cap)
		button.text = "OFF" if int(cap) == 0 else str(int(cap))
		button.toggle_mode = true
		button.button_pressed = int(cap) == now
		button.theme_type_variation = UiKit.TAB
		button.custom_minimum_size = Vector2(42, 14)
		button.focus_mode = Control.FOCUS_ALL
		button.pressed.connect(_pick_cap.bind(int(cap)))
		_caps.add_child(button)


func _clear(holder: Container) -> void:
	for child in holder.get_children():
		holder.remove_child(child)
		child.queue_free()


# --------------------------------------------------------------- the clicks

func _pick_mode(mode: int) -> void:
	_video.try_mode(mode, _video.window_size())
	_fill()


func _pick_size(size: Vector2i) -> void:
	_video.try_mode(int(_settings.get_int(&"video/window_mode")), size)
	_fill()


func _pick_cap(cap: int) -> void:
	# **No countdown on a frame cap.** It cannot make the screen unreadable,
	# and a "keep this?" over a number that changed nothing visible is a
	# question nobody knows how to answer.
	_settings.set_value(&"video/max_fps", cap)
	_fill()


func _toggle_crisp() -> void:
	_settings.set_value(&"video/integer_scaling", _crisp.button_pressed)
	_fill()


func _toggle_vsync() -> void:
	_settings.set_value(&"video/vsync", _vsync.button_pressed)
	_fill()


func _keep_it() -> void:
	_video.keep()
	_fill()


## **The tab follows the settings, not only its own buttons.**
##
## The countdown running out is `Video` putting a size back with nobody
## touching anything, and a tab that only redrew on a click would leave the
## size it took away still marked as the chosen one - which reads as the
## revert having failed.
func _on_setting(key: StringName) -> void:
	if String(key).begins_with("video/"):
		_fill()


# ---------------------------------------------------------- for the checks

func size_choices() -> int:
	return _sizes.get_child_count()


func marked_sizes() -> int:
	var marked := 0
	for child in _sizes.get_children():
		if String((child as Button).text).contains(" x"):
			marked += 1
	return marked


func warning_showing() -> bool:
	return _note != null and _note.visible and _note.text == WARNING


func countdown_showing() -> bool:
	return _countdown != null and _countdown.visible
