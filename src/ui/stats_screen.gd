class_name StatsScreen
extends Control

## What the player did, this run and across every run, side by side.
##
## Two columns and nothing else. The comparison *is* the feature: a lifetime
## column that is only a little bigger than the run column is a player on
## their second night, and one that dwarfs it is a player with a history. A
## single set of numbers would say much less for the same space.
##
## **It reads `Stats` and nothing else.** What counts as gathered, what a run
## has banked and what a fresh profile answers are all questions with answers
## in `src/core/`; this asks them and draws the replies.
##
## ## No buttons, and open whenever
##
## The tech tree shuts itself at dusk because it cannot be spent after dark.
## This one is read-only, so there is nothing for a wave to invalidate and no
## reason to take it away - a player who wants to know how many runners they
## have killed can look while the runners are arriving.
##
## ## A sibling after the day HUD
##
## For the reason task 0056 wrote down: `DayHud` is the first child of
## `Screen` and `MOUSE_FILTER_IGNORE` across the whole of it, and anything in
## that corner is not hit-testable. Panels go after it.
##
## ## The main menu
##
## Task 0069 asks for this to be reachable from the main menu, and the main
## menu is task 0092. Until it exists there is nowhere to put the entry, so
## the key is the way in and 0092's prompt has been given the line. Said out
## loud in the journal rather than quietly skipped.


## Where the two columns of numbers start. The labels live left of the first.
const RUN_X := 196.0
const LIFE_X := 320.0

var _state: Dictionary = {}
var _profile: Dictionary = {}
var _frame: Control
var _rows: Dictionary = {}          # key -> [Label, Label, Label]
var _breakdown: Label
var _drawn_for := ""


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var shade := ColorRect.new()
	shade.name = "StatsShade"
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.color = Color(0.03, 0.02, 0.06, 0.90)
	shade.position = Vector2.ZERO
	shade.size = Vector2(480, 270)
	add_child(shade)

	# **The frame gets its own backing, and it has to.** The tech tree draws
	# on a 0.88 shade and reads perfectly well, because every one of its
	# twelve nodes is a `Button` with a filled stylebox behind its text. This
	# screen is bare labels, and on the same shade the farm and the wave
	# counter came through the numbers. Rows of digits need something solid
	# under them.
	# Task 0079's panel, so this screen is framed like the rest of the game
	# rather than in a colour picked for it alone.
	var backing := Panel.new()
	backing.name = "StatsBacking"
	backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backing.position = Vector2(8, 22)
	backing.size = Vector2(464, 222)
	add_child(backing)

	_frame = Control.new()
	_frame.name = "StatsFrame"
	_frame.mouse_filter = Control.MOUSE_FILTER_STOP
	_frame.position = Vector2(8, 22)
	_frame.size = Vector2(464, 222)
	add_child(_frame)

	var heading := _label("StatsHeading", Vector2(4, 2), UiKit.WARM)
	heading.text = "RECORDS"
	var hint := _label("StatsHint", Vector2(316, 2), UiKit.DIM)
	hint.text = "R or ESC to close"

	_label("StatsRunHead", Vector2(RUN_X, 18), UiKit.COOL).text = "THIS RUN"
	_label("StatsLifeHead", Vector2(LIFE_X, 18), UiKit.WARM).text = "ALL RUNS"

	var rule := ColorRect.new()
	rule.name = "StatsRule"
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rule.color = Color(0.32, 0.29, 0.38, 0.9)
	rule.position = Vector2(4, 32)
	rule.size = Vector2(452, 1)
	_frame.add_child(rule)

	# The five the task names, in the order it names them, plus the two that
	# only mean anything across runs.
	var row := 0
	for line in [
		["nights", "nights survived"],
		["killed", "zombies killed"],
		["gathered", "resources gathered"],
		["built", "structures built"],
		["lost", "structures lost"],
		["best_night", "best night reached"],
		["runs", "runs started / won"],
	]:
		var key: String = line[0]
		var y := 34.0 + row * 14.0
		var name_label := _label("StatsName_" + key, Vector2(4, y), UiKit.DIM)
		name_label.text = str(line[1])
		_rows[key] = [
			_label("StatsRun_" + key, Vector2(RUN_X, y), UiKit.COOL),
			_label("StatsLife_" + key, Vector2(LIFE_X, y), UiKit.WARM),
		]
		row += 1

	# **What was killed, by kind**, on its own lines. The task asks for kills
	# by type and a single number cannot say it; four enemy kinds and a Giant
	# will not fit in a column two hundred pixels from the edge.
	_label("StatsByKindHead", Vector2(4, 148), UiKit.COOL).text = "BY KIND, THIS RUN"
	_breakdown = _label("StatsByKind", Vector2(4, 162), UiKit.WARM)
	_breakdown.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_breakdown.size = Vector2(452, 40)
	_breakdown.custom_minimum_size = Vector2(452, 40)


func _label(node_name: String, at: Vector2,
		role: StringName = &"") -> Label:
	var label := Label.new()
	label.name = node_name
	label.position = at
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.theme_type_variation = role
	if _frame != null:
		_frame.add_child(label)
	else:
		add_child(label)
	return label


# ----------------------------------------------------------------- the frame

func show_state(state: Dictionary) -> void:
	_state = state


## The profile the numbers on the right come from. `Main` hands it over on
## boot and again whenever it is written, so the lifetime column is as fresh
## as the last save rather than as fresh as the last launch.
func show_profile(profile: Dictionary) -> void:
	_profile = profile
	_drawn_for = ""


func is_open() -> bool:
	return visible


func open() -> void:
	if _state.is_empty():
		return
	visible = true
	_drawn_for = ""


func close() -> void:
	visible = false


func _process(_delta: float) -> void:
	if _state.is_empty():
		return
	# **The key asks the router, and so does the menu entry.** Task 0092:
	# there is one way in and one way out, so a player who opened this from
	# the title menu and a player who pressed R mid-night leave it by the
	# same door. `Main` is what actually opens and closes it, because `App`
	# owns which screen is up and this one does not.
	var router := get_node_or_null(^"/root/App")
	if router != null:
		if Input.is_action_just_pressed(&"stats"):
			if visible:
				router.back()
			else:
				router.goto(router.STATS)
		if visible and Input.is_action_just_pressed(&"cancel"):
			router.back()
	if not visible:
		return

	# Redrawn when something changed rather than sixty times a second, for the
	# reason the tech panel gives: twenty labels of formatted text rebuilt
	# every frame is twenty times the work for one picture.
	var run := Stats.of_run(_state)
	var signature := "%d/%d/%d/%d/%d" % [run["nights"], run["killed"],
		(run["gathered"] as Dictionary).size(), run["built"], run["lost"]]
	if signature == _drawn_for:
		return
	_drawn_for = signature
	_refresh(run)


func _refresh(run: Dictionary) -> void:
	var life := Stats.lifetime(_profile)
	_write("nights", str(run["nights"]), str(life["nights"]))
	_write("killed", str(run["killed"]), str(life["killed"]))
	_write("gathered", str(_total(run["gathered"])),
		str(_total(life["gathered"])))
	_write("built", str(run["built"]), str(life["built"]))
	_write("lost", str(run["lost"]), str(life["lost"]))
	_write("best_night", str(run["best_night"]), str(life["best_night"]))
	_write("runs", "-", "%d / %d" % [life["runs_started"], life["runs_won"]])
	_breakdown.text = _by_kind(run["killed_by_kind"])


func _write(key: String, run_text: String, life_text: String) -> void:
	var pair: Array = _rows[key]
	(pair[0] as Label).text = run_text
	(pair[1] as Label).text = life_text


## One line of "walker 41, runner 12", in a fixed order so it does not shuffle
## between frames.
func _by_kind(by_kind: Dictionary) -> String:
	if by_kind.is_empty():
		return "nothing yet"
	var parts: Array = []
	for kind in GameData.sorted_names(by_kind.keys()):
		parts.append("%s %d" % [str(kind), int(by_kind[kind])])
	return ", ".join(parts)


## Everything gathered, added up. The column has room for one number and the
## detail is a run's whole haul; the total is what a player compares.
func _total(haul: Dictionary) -> int:
	var sum := 0
	for key in haul:
		sum += int(haul[key])
	return sum
