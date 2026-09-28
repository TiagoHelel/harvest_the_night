class_name CrashDialog
extends Control

## After a crash, the next boot says so instead of pretending it did not.
##
## ## Why this is at the title and not at the moment
##
## A process that dies cannot draw a dialogue; that is what dying is. So the
## promise "rather than vanishing" is kept one launch later - the game comes
## back, notices the breadcrumb `Crash` left, and the first thing a player
## sees is an account of what happened and where it is written down. A player
## who watched the window disappear last night gets told, and a player whose
## machine did it while they were away finds out at all.
##
## A reported error - `Crash.report()`, which does not stop the game - lands
## here too, for the same reason it is not a modal mid-fight: the run is still
## going and interrupting a night to talk about a log file is worse than
## waiting until there is nothing at stake.
##
## ## It offers the folder, and it offers it in words that mean something
##
## `user://crash/...` is not somewhere anybody can go. The path shown is the
## real one, and the button opens the folder in whatever the machine uses for
## folders. On the web there is no such folder and no such button, and the
## dialogue says so rather than showing something that does nothing.
##
## ## Nothing is sent, and the dialogue is where that is said
##
## The file repeats it in English for whoever ends up reading it. This says it
## in the player's language, because the player is the one deciding.

## How wide the frame is, and where it sits on a 480x270 screen.
##
## **Measured off the picture, not guessed.** The first version was 172 tall
## and the content stopped two thirds of the way down, which reads as a panel
## with something missing from it.
const FRAME := Vector2(340, 132)

## Emitted when it is closed, so the title screen can take its input back.
signal closed

var _folder := ""

var _frame: PanelContainer
var _title: Label
var _body: Label
var _facts: Label
var _path: Label
var _open: Button
var _close: Button


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)

	_frame = PanelContainer.new()
	_frame.name = "CrashFrame"
	_frame.position = (Vector2(480, 270) - FRAME) * 0.5
	_frame.custom_minimum_size = FRAME
	_frame.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_frame)

	var column := VBoxContainer.new()
	column.name = "CrashColumn"
	column.theme_type_variation = UiKit.SPACED
	_frame.add_child(column)

	_title = Label.new()
	_title.name = "CrashTitle"
	_title.theme_type_variation = UiKit.HEADING
	column.add_child(_title)

	_body = Label.new()
	_body.name = "CrashBody"
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.custom_minimum_size = Vector2(FRAME.x - 16, 40)
	column.add_child(_body)

	# **The same four numbers that are in the file.** A player who can read
	# "seed 20260927, tick 41230" off the screen and off the report can tell
	# they are looking at the same crash, which is the whole of what they are
	# being asked to judge.
	_facts = Label.new()
	_facts.name = "CrashFacts"
	# **`Warm`, not `Faint`.** `Faint` is the colour of something a player
	# cannot have - locked, unavailable - and at eight pixels on this panel
	# it is barely there at all, which task 0099 already found out about the
	# version label. These two numbers are the thing being pointed at: they
	# are what a player checks against the file before sending it.
	_facts.theme_type_variation = UiKit.WARM
	column.add_child(_facts)

	_path = Label.new()
	_path.name = "CrashPath"
	_path.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	_path.custom_minimum_size = Vector2(FRAME.x - 16, 18)
	_path.theme_type_variation = UiKit.DIM
	column.add_child(_path)

	var row := HBoxContainer.new()
	row.name = "CrashButtons"
	column.add_child(row)

	_open = Button.new()
	_open.name = "CrashOpen"
	_open.custom_minimum_size = Vector2(160, 16)
	_open.focus_mode = Control.FOCUS_ALL
	_open.pressed.connect(_show_the_folder)
	row.add_child(_open)

	_close = Button.new()
	_close.name = "CrashClose"
	_close.custom_minimum_size = Vector2(160, 16)
	_close.focus_mode = Control.FOCUS_ALL
	_close.pressed.connect(close)
	row.add_child(_close)

	_relabel()
	var locale := _service(^"Locale")
	if locale != null and locale.has_signal("changed"):
		locale.changed.connect(_relabel)


## Show the report in `folder`, or do nothing when there is none.
##
## Returns whether anything was put up, so a caller can decide what to do with
## the keyboard without asking twice.
func show_report(folder: String) -> bool:
	if folder == "":
		return false
	_folder = folder
	_relabel()
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	_close.grab_focus()
	# **Marked the moment it is shown**, not when it is closed. A player who
	# alt-F4s out of this dialogue has still been told, and being told twice
	# about the same crash is how a game teaches somebody to dismiss it
	# without reading.
	Crash.mark_seen(folder)
	return true


## Put it away. The report stays on disk; this is a dialogue, not a bin.
func close() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_folder = ""
	closed.emit()


func showing() -> bool:
	return visible


## Which report is up, for anybody checking.
func folder() -> String:
	return _folder


func _relabel() -> void:
	_title.text = I18n.t(&"CRASH_TITLE")
	_body.text = I18n.t(&"CRASH_BODY")
	_facts.text = " ".join(_fact_line())
	_path.text = (I18n.t(&"CRASH_NO_FOLDER") if _on_the_web()
		else Crash.where(_folder))
	_open.text = I18n.t(&"CRASH_OPEN")
	_open.visible = not _on_the_web()
	_close.text = I18n.t(&"CRASH_CLOSE")


## Seed and tick off the snapshot, so the line is about the crash and not
## about whatever the title screen's backdrop is doing.
func _fact_line() -> PackedStringArray:
	var out := PackedStringArray()
	if _folder == "":
		return out
	var state := Crash.snapshot_of(_folder)
	if state.is_empty():
		out.append(I18n.t(&"CRASH_NO_STATE"))
		return out
	out.append(I18n.t(&"CRASH_SEED") % int(state.get("seed", 0)))
	out.append(I18n.t(&"CRASH_TICK") % int(state.get("tick", 0)))
	return out


func _show_the_folder() -> void:
	if _folder == "" or _on_the_web():
		return
	OS.shell_open(Crash.where(_folder))


## There is no file manager in a browser tab, so there is no button either.
func _on_the_web() -> bool:
	return OS.has_feature("web")


## **Asked of the engine, not of this node.** `get_node` with an absolute path
## errors from outside the active tree, which is every node a headless check
## builds.
func _service(named: NodePath) -> Node:
	var loop := Engine.get_main_loop() as SceneTree
	if loop == null or loop.root == null:
		return null
	return loop.root.get_node_or_null(named)
