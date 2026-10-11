class_name ForecastPanel
extends Control

## **The night's forecast** (task 0158), top right: on the day HUD from 18:00
## (`Phases.is_dusk`) and on the night HUD in the build step; hidden by day
## before dusk and once the waves start.
##
## Everything on it is `Forecast.tonight` - the record the night will fight -
## so it can only be as wrong as the night is. From the top:
##
## - the season's mark, TONIGHT and the date, with the night's marks at the
##   right: a Full Moon, a boss, a calm night (A010's art since task 0161);
## - the sides in words - from the EAST, or from every side;
## - the waves, the Full Moon and the boss in words;
## - one head and count per kind, in the order they arrive (A011's heads
##   since task 0162: exact crops of each enemy's own walk frame).
##
## A calm night says so and nothing else. 0256's events have a slot in the
## forecast and nothing here until then.
##
## **It holds no game state.** The forecast is asked again only when the run,
## the date or the language changes - `Waves.night_of` builds a generated
## night from scratch, and that is not a thing to do sixty times a second.

## Where it stands: the right edge, under both HUDs' strips.
const WIDTH := 150.0
const AT := Vector2(480.0 - 4.0 - WIDTH, 30.0)
const PAD := 4.0
## A line of text, and the head box.
const LINE := 10.0
const HEAD := 16.0
## Between one head-and-count and the next.
const HEAD_GAP := 6.0

var _state: Dictionary = {}
var _built_for := ""
var _forecast: Dictionary = {}
var _textures: Dictionary = {}

var _back: ColorRect
var _season: CalendarMark
var _title: Label
var _date: Label
var _marks: Array[CalendarMark] = []
var _lines: Array[Label] = []
var _heads: Control


func _ready() -> void:
	name = "ForecastPanel"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	position = AT
	size = Vector2(WIDTH, 40.0)
	visible = false

	_back = ColorRect.new()
	_back.name = "Back"
	_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_back.color = Color(0.05, 0.04, 0.09, 0.8)
	add_child(_back)

	_season = CalendarMark.new()
	_season.name = "SeasonMark"
	add_child(_season)
	_season.position = Vector2(PAD, PAD)
	_title = _label("ForecastTitle", Vector2(PAD + HEAD + 4.0, PAD - 2.0), UiKit.WARM)
	_date = _label("ForecastDate", Vector2(PAD + HEAD + 4.0, PAD + 7.0), UiKit.DIM)

	_heads = Control.new()
	_heads.name = "Heads"
	_heads.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_heads)


func show_state(state: Dictionary) -> void:
	_state = state
	_built_for = ""


func _process(_delta: float) -> void:
	visible = wanted()
	if not visible:
		return
	var key := "%d|%d|%d" % [int(_state["seed"]), Calendar.date(_state), I18n.revision()]
	if key != _built_for:
		_built_for = key
		_forecast = Forecast.tonight(_state)
		_build()


## Whether the forecast is up: from dusk by day, and in the build step. Not
## inside the house, where the day HUD is down too, and not over an open
## panel - the market at 19:00 is the market.
func wanted() -> bool:
	if _state.is_empty() or House.inside(_state):
		return false
	if StringName(_state.get("open_panel", &"")) != &"":
		return false
	var phase := int(_state["phase"])
	if phase == Phases.PREPARATION:
		return true
	return phase == Phases.DAY and Phases.is_dusk(_state)


## The forecast it is showing - for `input_v1` and the shots.
func shown() -> Dictionary:
	return _forecast


## Every line of words on it, in order - for the width checks.
func texts() -> Array:
	var out: Array = [_title.text, _date.text]
	for line in _lines:
		out.append(line.text)
	return out


## Anything drawn outside the panel's own box, or the title and the date
## under a night's mark - which should be nothing, in either language.
func outside() -> Array:
	var out: Array = []
	var box := Rect2(Vector2.ZERO, size)
	for child in _all_drawn():
		var item: Control = child
		var where := _drawn_box(item)
		if not box.encloses(where):
			out.append("%s %s" % [item.name, where])
	for mark in _marks:
		for words in [_title, _date]:
			if _drawn_box(words).intersects(_drawn_box(mark)):
				out.append("%s under %s" % [words.name, mark.name])
	return out


## Where a control draws, in the panel's pixels: a line of words as wide as
## its words, a wrapped line as wide as the panel lets it be.
func _drawn_box(item: Control) -> Rect2:
	var where := Rect2(item.global_position - global_position, item.size)
	if item is Label:
		var label := item as Label
		if label.autowrap_mode == TextServer.AUTOWRAP_OFF:
			where.size = Vector2(_text_width(label), LINE)
		else:
			where.size = Vector2(label.size.x, LINE * maxi(label.get_line_count(), 1))
	return where


func _all_drawn() -> Array:
	var out: Array = [_season, _title, _date]
	out.append_array(_marks)
	out.append_array(_lines)
	for child in _heads.get_children():
		out.append(child)
	return out


# ----------------------------------------------------------------- the build

func _build() -> void:
	var f := _forecast
	_season.setup(StringName(f["season"]))
	_title.text = I18n.t(&"FCAST_TITLE")
	# The date without the year: the day HUD has it under the clock and the
	# night strip beside the date, and a boss night in Year 2 would put it
	# under the marks.
	_date.text = I18n.f(&"DHUD_DATE", [Names.of(StringName(f["season"])),
		int(f["day_of_season"])])

	# Freed now rather than queued, so the new ones keep their names.
	for old in _marks:
		old.free()
	_marks.clear()
	var night_marks: Array = []
	if bool(f["full_moon"]):
		night_marks.append(&"full_moon")
	if StringName(f["boss"]) != &"":
		night_marks.append(&"boss_night")
	if bool(f["calm"]):
		night_marks.append(&"calm_night")
	var x := WIDTH - PAD
	for which in night_marks:
		var one := CalendarMark.new()
		one.name = "Mark_%s" % which
		add_child(one)
		one.setup(which)
		x -= HEAD
		one.position = Vector2(x, PAD)
		x -= 2.0
		_marks.append(one)

	for old in _lines:
		old.free()
	_lines.clear()
	for old in _heads.get_children():
		old.free()

	var y := PAD + HEAD + 4.0
	if bool(f["calm"]):
		y = _line("Calm", I18n.t(&"FCAST_CALM"), y, UiKit.GOOD)
	else:
		y = _line("Sides", _sides_text(f["sides"]), y, &"")
		y = _line("Waves", I18n.plural(&"FCAST_WAVES", int(f["waves"]),
			[int(f["waves"])]), y, UiKit.DIM)
		if bool(f["full_moon"]):
			y = _line("FullMoon", I18n.t(&"FCAST_FULL_MOON"), y, UiKit.WARM)
		if StringName(f["boss"]) != &"":
			y = _line("Boss", I18n.f(&"FCAST_BOSS",
				[Names.of(StringName(f["boss"])).to_upper()]), y, UiKit.BAD)
		y = _lay_heads(f["kinds"], y + 2.0)
	size = Vector2(WIDTH, y + PAD)
	_back.size = size


## The sides in words: every one of them, or the ones there are.
func _sides_text(sides: Array) -> String:
	if sides.size() >= GameData.SPAWN_SIDES.size():
		return I18n.t(&"FCAST_EVERY_SIDE")
	var names := PackedStringArray()
	for side in sides:
		names.append(Names.of(StringName(side)))
	return I18n.f(&"FCAST_FROM", [", ".join(names)])


## One line - wrapped inside the panel when it has to be - and where the next
## one starts.
func _line(node_name: String, text: String, y: float, role: StringName) -> float:
	var label := _label(node_name, Vector2(PAD, y - 1.0), role)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size = Vector2(WIDTH - 2.0 * PAD, LINE)
	label.text = text
	_lines.append(label)
	return y + LINE * maxi(label.get_line_count(), 1)


## One head and its count per kind, left to right, onto a new row when the
## next would not fit. Returns where the rows end.
func _lay_heads(kinds: Array, y: float) -> float:
	var x := PAD
	for pair in kinds:
		var kind := StringName((pair as Array)[0])
		var count := Label.new()
		count.name = "Count_%s" % kind
		count.mouse_filter = Control.MOUSE_FILTER_IGNORE
		count.text = str(int((pair as Array)[1]))
		# In the tree before it is measured, so it is measured in the game's
		# font rather than the engine's.
		_heads.add_child(count)
		var cell := HEAD + 1.0 + _text_width(count)
		if x > PAD and x + cell > WIDTH - PAD:
			x = PAD
			y += HEAD + 2.0
		var head := TextureRect.new()
		head.name = "Head_%s" % kind
		head.mouse_filter = Control.MOUSE_FILTER_IGNORE
		head.texture = _head_of(kind)
		# A stand-in's head soured as its body is (task 0247's spitter).
		head.self_modulate = PlaceholderArt.art_tint(StringName("head_%s" % kind))
		head.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		head.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		head.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_heads.add_child(head)
		head.position = Vector2(x, y)
		head.size = Vector2(HEAD, HEAD)
		count.position = Vector2(x + HEAD + 1.0, y + 4.0)
		x += cell + HEAD_GAP
	return y + (HEAD if not kinds.is_empty() else 0.0)


## A kind's head: its `ui/head_<kind>` - A011's five since task 0162, drawn at
## their native 16x16 with no flip - a later pack's registered stand-in, a box
## of the walk frame or a drawing (task 0248's rat), or, for a kind no pack
## has drawn yet, the whole walk frame shrunk into the box.
func _head_of(kind: StringName) -> Texture2D:
	var art := StringName("head_%s" % kind)
	if _textures.has(art):
		return _textures[art]
	var texture: Texture2D = null
	if not PlaceholderArt.art(art).is_empty():
		var file := PlaceholderArt.texture_path(PlaceholderArt.art_path(art, 0))
		var region := PlaceholderArt.art_region(art)
		if ResourceLoader.exists(file):
			texture = load(file)
			if region.has_area() and file != PlaceholderArt.art_path(art, 0):
				var cut := AtlasTexture.new()
				cut.atlas = texture
				cut.region = Rect2(region)
				texture = cut
		# A head drawn in code (task 0248's rat), until its pack lands.
		if texture == null:
			texture = WorldView.drawn_enemy(PlaceholderArt.art_path(art, 0))
	elif ResourceLoader.exists("res://sprites/ui/%s.png" % art):
		texture = load("res://sprites/ui/%s.png" % art)
	elif ResourceLoader.exists("res://sprites/enemies/%s_walk_0.png" % kind):
		texture = load("res://sprites/enemies/%s_walk_0.png" % kind)
	_textures[art] = texture
	return texture


func _text_width(label: Label) -> float:
	var font := label.get_theme_font(&"font")
	if font == null:
		return 0.0
	var widest := 0.0
	for line in label.text.split("\n"):
		widest = maxf(widest, font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT,
			-1, label.get_theme_font_size(&"font_size")).x)
	return widest


func _label(node_name: String, at: Vector2, role: StringName = &"") -> Label:
	var label := Label.new()
	label.name = node_name
	label.position = at
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.theme_type_variation = role
	add_child(label)
	return label
