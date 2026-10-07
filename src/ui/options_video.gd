class_name OptionsVideo
extends OptionsPage

## The video page: which window, how big, and whether the pixels stay square.
##
## It owns no policy. Every decision is `Video`'s - which resolutions fit,
## which of them are whole multiples, how long a new mode has to be confirmed -
## and this draws them and hands the changes back. That is what makes the
## awkward half of this testable without a monitor.
##
## ## A new window is a question, and the question is in the way on purpose
##
## Changing the window or its size applies at once and `Video` starts a
## countdown: if nobody keeps it, it goes back. While it runs the rows are put
## aside for KEEP and PUT IT BACK with the caret on KEEP - the one a player
## who can see the screen wants - and escape puts it back, because a player
## who cannot see the screen will press escape.
##
## ## The note under the rows is not decoration
##
## Integer scaling is on by default, and both of the things it can say are
## things a player needs: with it on, **which sizes are the good ones** (the
## ones marked `x2`, `x3`); with it off, **what they just gave up**. A setting
## whose only explanation is its own name is a setting people flip at random
## to see which they prefer, and this one has a right answer.

## Shown when square pixels are off, and when they are on.
const WARNING := &"VID_WARNING"
const LEGEND := &"VID_LEGEND"

var _video: Node

var _window: OptionRow
var _size: OptionRow
var _crisp: OptionRow
var _vsync: OptionRow
var _cap: OptionRow

## The row whose change started the question, which the selection goes back
## to when it is answered - so the next key moves the same thing again.
var _trial_from: OptionRow

var _trial: VBoxContainer
var _countdown: Label
var _keep: Button
var _put_back: Button


func _init() -> void:
	resets = [&"video/window_mode", &"video/scale", &"video/size",
		&"video/integer_scaling", &"video/vsync", &"video/max_fps"]
	title_key = &"OPT_TAB_VIDEO"


func _build() -> void:
	_video = get_node_or_null(^"/root/Video")
	_window = choice_row("VideoWindow", _step_window, _window_text)
	_size = choice_row("VideoSize", _step_size, _size_text)
	_crisp = toggle_row("VideoCrisp", &"video/integer_scaling")
	_vsync = toggle_row("VideoVsync", &"video/vsync")
	_cap = choice_row("VideoCap", _step_cap, _cap_text)

	# **The question a new window asks**, built once and shown while `Video`
	# is counting down. In the column, under the rows, so it is where the eye
	# already is.
	_trial = VBoxContainer.new()
	_trial.name = "VideoTrial"
	_trial.visible = false
	_column.add_child(_trial)
	_countdown = Label.new()
	_countdown.name = "VideoCountdown"
	_countdown.theme_type_variation = UiKit.WARN
	_countdown.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_trial.add_child(_countdown)
	var answers := HBoxContainer.new()
	answers.name = "VideoTrialAnswers"
	answers.theme_type_variation = UiKit.SPACED
	answers.alignment = BoxContainer.ALIGNMENT_CENTER
	_trial.add_child(answers)
	_keep = Button.new()
	_keep.name = "VideoKeep"
	_keep.custom_minimum_size = Vector2(96, 16)
	_keep.pressed.connect(_keep_it)
	answers.add_child(_keep)
	_put_back = Button.new()
	_put_back.name = "VideoPutBack"
	_put_back.custom_minimum_size = Vector2(96, 16)
	_put_back.pressed.connect(_put_it_back)
	answers.add_child(_put_back)
	MenuFocus.wire(answers.get_children())


func relabel() -> void:
	if _window == null:
		return
	_window.text = I18n.t(&"VID_WINDOW")
	_size.text = I18n.t(&"VID_SIZE")
	_crisp.text = I18n.t(&"VID_CRISP")
	_vsync.text = I18n.t(&"VID_VSYNC")
	_cap.text = I18n.t(&"VID_CAP")
	_keep.text = I18n.t(&"VID_KEEP")
	_put_back.text = I18n.t(&"VID_PUT_BACK")
	super()


func refresh() -> void:
	super()
	if _window == null or _settings == null:
		return
	var crisp := bool(_settings.get_bool(&"video/integer_scaling"))
	say(I18n.t(LEGEND if crisp else WARNING), UiKit.DIM if crisp else UiKit.WARN)
	# **The size is only the window's to have.** Borderless and fullscreen
	# are the monitor's size whatever this says, so the row is switched off
	# rather than offering a choice that would do nothing.
	_size.disabled = _video == null \
		or int(_settings.get_int(&"video/window_mode")) != _video.WINDOWED


func _process(_delta: float) -> void:
	if not visible or _video == null:
		return
	var waiting: bool = _video.waiting()
	if waiting != _trial.visible:
		_show_trial(waiting)
	if waiting:
		_countdown.text = I18n.f(&"VID_COUNTDOWN",
			[int(ceil(float(_video.seconds_left())))])


## Put the rows aside for the question, or bring them back.
func _show_trial(up: bool) -> void:
	_trial.visible = up
	for row in rows():
		(row as OptionRow).visible = not up
	if up:
		_keep.grab_focus()
	elif is_visible_in_tree():
		var back_to: OptionRow = _window
		if _trial_from != null and not _trial_from.disabled:
			back_to = _trial_from
		back_to.grab_focus()


# ------------------------------------------------------------- the choices

func _modes() -> Array:
	return [_video.WINDOWED, _video.BORDERLESS, _video.FULLSCREEN] \
		if _video != null else []


func _step_window(delta: int) -> void:
	if _video == null or _settings == null:
		return
	var now := int(_settings.get_int(&"video/window_mode"))
	_trial_from = _window
	_video.try_mode(int(stepped(_modes(), now, delta)), _video.window_size())
	refresh()


func _window_text() -> String:
	if _video == null or _settings == null:
		return ""
	return I18n.t(_video.MODE_NAMES[int(_settings.get_int(&"video/window_mode"))])


## **The list comes off the monitor**, and the whole multiples are marked with
## the multiple they are. The rest are offered too - a 1366x768 laptop has no
## multiple at its own size, and refusing to run at native there would be the
## game being clever at the player's expense.
func _sizes() -> Array:
	var out: Array = []
	if _video == null:
		return out
	for entry in _video.sizes_on(_video.monitor()):
		out.append(entry)
	return out


func _step_size(delta: int) -> void:
	if _video == null or _settings == null:
		return
	var sizes := _sizes()
	if sizes.is_empty():
		return
	var now: Vector2i = _video.window_size()
	var at := 0
	for i in sizes.size():
		if (sizes[i] as Dictionary)["size"] == now:
			at = i
	var next: Vector2i = (sizes[posmod(at + delta, sizes.size())] as Dictionary)["size"]
	_trial_from = _size
	_video.try_mode(int(_settings.get_int(&"video/window_mode")), next)
	refresh()


func _size_text() -> String:
	if _video == null:
		return ""
	var now: Vector2i = _video.window_size()
	for entry in _sizes():
		if (entry as Dictionary)["size"] == now:
			return _size_words(entry)
	return "%dx%d" % [now.x, now.y]


static func _size_words(entry: Dictionary) -> String:
	var size: Vector2i = entry["size"]
	return "%dx%d x%d" % [size.x, size.y, int(entry["scale"])] \
		if bool(entry["crisp"]) else "%dx%d" % [size.x, size.y]


func _step_cap(delta: int) -> void:
	# **No countdown on a frame cap.** It cannot make the screen unreadable,
	# and a "keep this?" over a number that changed nothing visible is a
	# question nobody knows how to answer.
	if _video == null or _settings == null:
		return
	var now := int(_settings.get_int(&"video/max_fps"))
	_settings.set_value(&"video/max_fps", int(stepped(_video.FPS_CAPS, now, delta)))


func _cap_text() -> String:
	var now := int(_settings.get_int(&"video/max_fps")) if _settings != null else 0
	return I18n.t(&"VID_CAP_OFF") if now == 0 else str(now)


# ----------------------------------------------------------------- the trial

func _keep_it() -> void:
	if _video != null:
		_video.keep()
	_show_trial(false)
	refresh()


func _put_it_back() -> void:
	if _video != null:
		_video.revert()
	_show_trial(false)
	refresh()


func busy() -> bool:
	return (_video != null and _video.waiting()) or super()


func cancel() -> bool:
	if _video != null and _video.waiting():
		_put_it_back()
		return true
	return super()


## **The page follows the settings, not only its own rows.** The countdown
## running out is `Video` putting a size back with nobody touching anything,
## and a page that only redrew on a key would still show the size it took
## away - which reads as the revert having failed.
func _on_setting(key: StringName) -> void:
	if String(key).begins_with("video/"):
		refresh()


# ---------------------------------------------------------- for the checks

func size_choices() -> int:
	return _sizes().size()


func marked_sizes() -> int:
	var marked := 0
	for entry in _sizes():
		if bool((entry as Dictionary)["crisp"]):
			marked += 1
	return marked


func warning_showing() -> bool:
	return note_shown() == I18n.t(WARNING)


func countdown_showing() -> bool:
	return _trial != null and _trial.visible


## Every size the page offers, as it says them.
func size_words() -> Array:
	var out: Array = []
	for entry in _sizes():
		out.append(_size_words(entry))
	return out
