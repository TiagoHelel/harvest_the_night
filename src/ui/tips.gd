class_name Tips
extends Control

## **The new day's tips** (task 0195): one line each for tilling grass, the
## seasons, the shipping bin, the fishing bar and the animals
## (`GameData.TIPS`). Each sits over the thing it is about, the first time it
## matters, and never again.
##
## ## The profile, not Settings
##
## Day one's lines remember themselves in the `gameplay/tutorial_seen`
## Settings key (`TutorialPrompt`). A tip remembers itself in the profile,
## under `tips_seen`, for two reasons:
## - **It is history, not a preference.** It belongs with the profile's other
##   lifetime facts - the runs, the stats, the fish book - and an options
##   screen's "back to defaults" has no business teaching it again.
## - **The profile is plain data.** `Save.read_profile` hands it over without
##   an autoload, so `due` is a pure function of a state and a profile, which
##   the headless group calls as it is.
##
## `Main` keeps the profile and writes it (`keeper`'s `profile` and
## `remember_tip`), so a tip shown is in the copy every later save writes.
##
## ## View only
##
## The triggers are read off the state and nothing here writes to it. Its
## `mouse_filter` is IGNORE from the root down, so a tip gates nothing and
## pauses nothing. It stays while its moment lasts, for `GameData.TIP_MIN_SECONDS`
## to `TIP_SECONDS`, and goes by itself. None shows on the first day, which is
## the tutorial's, nor while a tutorial line is up.

## Who keeps the profile: `Main`, with `profile()` and `remember_tip(id)`.
var keeper: Object
## Day one's prompt, which a tip waits for.
var tutorial: TutorialPrompt
## The day HUD, whose date the seasons' tip points at.
var hud: Control

var _state: Dictionary = {}
var _world: WorldView
var _panel: ColorRect
var _line: Label
var _arrow: Label
var _showing := &""
var _up := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = false
	_panel = ColorRect.new()
	_panel.name = "TipBacking"
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.color = Color(0.05, 0.04, 0.09, 0.78)
	add_child(_panel)
	_line = Label.new()
	_line.name = "TipLine"
	_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_line)
	_arrow = Label.new()
	_arrow.name = "TipArrow"
	_arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_arrow.theme_type_variation = UiKit.WARM
	add_child(_arrow)


func show_state(state: Dictionary, world: WorldView) -> void:
	_state = state
	_world = world


## Which tip is up, or `&""`. For the checks.
func showing() -> StringName:
	return _showing


func _process(delta: float) -> void:
	if _showing != &"":
		_up += delta
		var over := _up >= float(GameData.TIP_SECONDS) \
			or (_up >= float(GameData.TIP_MIN_SECONDS) and not triggered(_showing, _state))
		if over or _state.is_empty():
			_showing = &""
			visible = false
			return
		_place_for(_showing)
		return
	if _state.is_empty() or keeper == null:
		return
	if tutorial != null and tutorial.showing() != &"":
		return
	var id := due(_state, keeper.call(&"profile"))
	if id == &"":
		return
	keeper.call(&"remember_tip", id)
	_showing = id
	_up = 0.0
	_line.text = I18n.t(line_of(id))
	visible = true
	_place_for(id)


# ------------------------------------------------------------------ the rules

## **What is due** (task 0195): the first tip in `GameData.TIPS` whose moment
## it is and that the profile has not seen, from the second day on - or
## `&""`. Pure: it reads the state and the profile and writes neither.
static func due(state: Dictionary, profile: Dictionary) -> StringName:
	if state.is_empty() or int(state.get("day", 1)) < 2:
		return &""
	for entry in GameData.TIPS:
		var id := StringName((entry as Dictionary)["id"])
		if not seen(profile, id) and triggered(id, state):
			return id
	return &""


## Whether the profile has seen a tip.
static func seen(profile: Dictionary, id: StringName) -> bool:
	return (profile.get("tips_seen", []) as Array).has(String(id))


## The profile, with `id` written in as shown.
static func remember(profile: Dictionary, id: StringName) -> Dictionary:
	var out := profile.duplicate(true)
	var shown: Array = out.get("tips_seen", [])
	if not shown.has(String(id)):
		shown.append(String(id))
	out["tips_seen"] = shown
	return out


## A tip's line key.
static func line_of(id: StringName) -> StringName:
	for entry in GameData.TIPS:
		if StringName((entry as Dictionary)["id"]) == id:
			return StringName((entry as Dictionary)["line"])
	return &""


## **Each tip's moment**, off the state alone:
## - `till`: the farmer, by day and out of doors, faces open grass the hoe
##   would turn;
## - `season`: the first morning of a season after the first;
## - `bin`: the farmer faces the shipping bin;
## - `bite`: a fish is on the line, and the bar is up;
## - `animal`: an animal lives in a home - bought, or moved in when its
##   first coop or barn went up - and eats hay from tomorrow.
static func triggered(id: StringName, state: Dictionary) -> bool:
	if state.is_empty():
		return false
	var by_day := int(state["phase"]) == Phases.DAY
	var outside := by_day and not House.inside(state)
	match id:
		&"till":
			var at := Player.target(state)
			return outside and Farm.terrain_at(state, at) == Farm.Terrain.GRASS \
				and Interact.verb_at(state, at) == &"till"
		&"season":
			var today := Calendar.date(state)
			return by_day and Calendar.season_of(today) > 0 and Calendar.day_of_season(today) == 1
		&"bin":
			return outside and StringName(Farm.occupant(state, Player.target(state)).get("id", &"")) == Shipping.BIN
		&"bite":
			return Fishing.is_biting(state)
		&"animal":
			return _first_home(state).x >= 0
	return false


## The first home with an animal in it, in cell order - or (-1, -1).
static func _first_home(state: Dictionary) -> Vector2i:
	var homes: Dictionary = state.get("housed", {})
	var keys: Array = homes.keys()
	# Cell indices, so integers: a plain sort is cell order.
	keys.sort()
	for idx in keys:
		if not ((homes[idx] as Dictionary).get("animals", []) as Array).is_empty():
			return Grid.cell(int(idx))
	return Vector2i(-1, -1)


# ------------------------------------------------------------------- placing

## Over the thing a tip is about: the grass faced, the bin, a home's door,
## the bar - or under the date, for the season.
func _place_for(id: StringName) -> void:
	match id:
		&"till":
			_place_over_cell(Player.target(_state))
		&"bin":
			var bins := Farm.cells_with(_state, Shipping.BIN)
			_place_over_cell(bins[0] if not bins.is_empty() else Player.target(_state))
		&"animal":
			var home := _first_home(_state)
			_place_over_cell(Livestock.door_of(_state, home) if home.x >= 0 else Player.target(_state))
		&"bite":
			var top := FishingBar.CENTRE - Vector2(FishingBar.FRAME) / 2.0
			_place_at(Vector2(FishingBar.CENTRE.x, top.y), true, false)
		&"season":
			var date := hud.find_child("Day", true, false) as Control if hud != null else null
			if date != null and date.is_visible_in_tree():
				var box := date.get_global_rect()
				_place_at(Vector2(box.position.x + 24.0, box.end.y), true, true)
			else:
				_place_at(Vector2(240.0, 40.0), false, true)


## Over a farm cell: `WorldView.cell_to_screen`, the screen's own pixels at
## any window size, as the world tooltip is placed.
func _place_over_cell(cell: Vector2i) -> void:
	var at := Vector2(240.0, 120.0)
	if _world != null:
		at = _world.cell_to_screen(cell) - Vector2(0.0, float(GameData.TILE_SIZE) * 0.5)
	_place_at(at, true, false)


## The line above a point, or under it, kept on the screen, the pointer at
## the point.
func _place_at(at: Vector2, pointing: bool, below: bool) -> void:
	var width := _line.get_minimum_size().x + 10.0
	var left := clampf(at.x - width * 0.5, 4.0, 480.0 - width - 4.0)
	var top := clampf(at.y + 10.0 if below else at.y - 26.0, 4.0, 236.0)
	_panel.position = Vector2(left, top)
	_panel.size = Vector2(width, 13)
	_line.position = Vector2(left + 5.0, top + 1.0)
	_arrow.text = "^" if below else "v"
	_arrow.position = Vector2(clampf(at.x - 2.0, 4.0, 470.0), top - 10.0 if below else top + 12.0)
	_arrow.visible = pointing
