class_name SeasonView
extends Node

## **The same farm through the year** (task 0159): today's green in spring,
## warmer in summer, ochre and rust in autumn, snow in winter - all of it in
## the view, with not one rule touched.
##
## ## How
##
## - **A palette remap**, not new art: the farm is drawn in the palette's own
##   colours, so a season is a table of entry -> entry for the grass and the
##   foliage (`PaletteData.SEASON_REMAP`, from `tools/palette.py`). One
##   material wears it on the terrain, its edges and corners (`ground`); the
##   trees wear it inside their wind shader. Switching is one uniform: the
##   terrain, drawn once, is never redrawn for it.
## - **Snow on the roofs** in winter, by a code mask: the top rows of the
##   house's, the stations' and the stall's opaque pixels draw in `bone` and
##   `moon` (`roof_material`). And over every stump, rock, seam and ore node a
##   snow cap - A013's since task 0164; a registered stand-in would be the
##   host itself through the same mask, the snow alone (`cap_material`).
## - **Snowfall** is `Particles`', which asks `season_on_screen` too.
##
## ## The hooks the art packs fill in
##
## `frame_for(name, season)` answers `<name>_<season>` when 0120's lookup has
## it - A012's winter ground, A013's seasonal trees, real or a registered
## stand-in - and `name` otherwise; `carries_season` says whether that frame
## is the real thing, which the remap then leaves alone. A seasonal terrain
## atlas, when one exists, goes onto the terrain's tile set (`WorldView`).
## So 0163 and 0164 only added frames and deleted their registry lines:
## A012's winter tiles, and `gen_sprites`' winter atlas built from them, are
## what winter's ground is drawn with (0163), and A013's spring, autumn and
## winter trees and its caps what the trees and the nodes wear (0164) - all
## unremapped. Summer keeps today's trees, through the remap.
##
## ## When it changes
##
## On the morning of a season's first day, behind 0138's wake-up: the date
## moves at dawn, under the morning report, and the report is still the
## night's - so the farm keeps the night's season until the day begins
## (`season_on_screen`), and every material switches in the same frame.

const SHADER: Shader = preload("res://src/ui/season_remap.gdshader")

## The seasons, as `GameData.SEASONS` counts them.
const SPRING := 0
const WINTER := 3

## Rows of snow on a roof's or a node's top edge, in native pixels.
const SNOW_ROWS := 2

## The ids whose top edge takes snow in winter: the farmhouse, the stall and
## the stations.
const ROOFED: Array = [&"house", &"shop", &"workshop", &"kitchen", &"press",
	&"generator"]

## The map nodes a snow cap settles on (A013), by the art name the view draws
## them under; anything else here takes the generic cap.
const CAPPED: Array = [&"stump", &"rock", &"ore", &"seam", &"copper_ore",
	&"coal_seam", &"gold_ore", &"hardwood_stump"]

## **The palette entries a rainy night muddies** (task 0258): the grass's and
## the soil's, which the path is drawn in too.
const MUDDIED: Array = [&"grass_dark", &"grass", &"grass_light", &"soil_dark", &"soil", &"soil_light"]

## Emitted the frame the season on screen moves.
signal changed(season: int)

## The material the terrain, its edges and its corners wear.
var ground: ShaderMaterial

var _state: Dictionary = {}
var _season := SPRING
## Every sprite material that wears the season, dropped with the sprites.
var _worn: Array[ShaderMaterial] = []


func _init() -> void:
	name = "SeasonView"
	ground = ShaderMaterial.new()
	ground.shader = SHADER
	_dress(ground, true)


func show_state(state: Dictionary) -> void:
	_state = state
	_switch_to(season_on_screen(state))


## Called once a frame, before the farm is drawn: true when the season on
## screen has just moved.
func update() -> bool:
	var now := season_on_screen(_state)
	if now == _season:
		return false
	_switch_to(now)
	return true


## The season the farm is drawn in now.
func season() -> int:
	return _season


## What the shader is set to - for `input_v1`.
func shader_season() -> int:
	return int(ground.get_shader_parameter("season"))


## **The ground gone to mud** (task 0258): 0 dry to 1 a whole rainy night's,
## on the ground's material only - `WeatherView` fades it with the night.
func set_mud(amount: float) -> void:
	ground.set_shader_parameter("mud", clampf(amount, 0.0, 1.0))


## How muddy the ground is drawn now - for `input_v2`.
func mud() -> float:
	return float(ground.get_shader_parameter("mud"))


## **The season on screen** for a state: its date's, except under the morning
## report, which is still the night's - the date has already moved at dawn,
## and the farm changes behind the wake-up (0138), not under the report.
static func season_on_screen(state: Dictionary) -> int:
	if state.is_empty():
		return SPRING
	var date := Calendar.date(state)
	if int(state["phase"]) == Phases.RESULT and int(state.get("night", 0)) > 0:
		date = int(state["night"])
	return Calendar.season_of(date)


# --------------------------------------------------------------- materials

## A sprite's material: `remapped` grass and foliage, snow on its top edge in
## winter when `snow`, and only that snow when `snow_only`.
func sprite_material(remapped: bool, snow: bool = false,
		snow_only: bool = false) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = SHADER
	_dress(material, remapped)
	material.set_shader_parameter("snow_rows", SNOW_ROWS if snow else 0)
	material.set_shader_parameter("snow_only", snow_only)
	return material


## A roof: no remap, snow on the top edge.
func roof_material() -> ShaderMaterial:
	return sprite_material(false, true)


## A snow cap's stand-in: the host's own frame, the snow alone.
func cap_material() -> ShaderMaterial:
	return sprite_material(false, true, true)


## Put the season on a material that wears another shader including
## `season.gdshaderinc` - the trees' wind.
func dress(material: ShaderMaterial, remapped: bool) -> void:
	_dress(material, remapped)


## Forget the sprite materials: the occupants are being redrawn.
func forget_sprites() -> void:
	_worn.clear()


func _dress(material: ShaderMaterial, remapped: bool) -> void:
	var from := PackedVector3Array()
	var to := PackedVector3Array()
	var foliage: Array = PaletteData.FOLIAGE
	for entry in foliage:
		from.append(_vec(StringName(entry)))
	for i in range(foliage.size(), 8):
		from.append(Vector3(-1.0, -1.0, -1.0))
	for season_id in GameData.SEASONS:
		var table: Dictionary = PaletteData.SEASON_REMAP.get(season_id, {})
		for i in 8:
			var entry: StringName = foliage[i] if i < foliage.size() else &""
			to.append(_vec(StringName(table.get(entry, entry))) if entry != &"" else Vector3.ZERO)
	material.set_shader_parameter("season_from", from)
	material.set_shader_parameter("season_to", to)
	material.set_shader_parameter("season_count", mini(foliage.size(), 8))
	material.set_shader_parameter("remap", remapped)
	material.set_shader_parameter("snow_body", _vec(&"bone"))
	material.set_shader_parameter("snow_light", _vec(&"moon"))
	material.set_shader_parameter("snow_line", _vec(&"ink"))
	material.set_shader_parameter("season", _season)
	if material != ground:
		_worn.append(material)
		return
	# What the rain muddies (task 0258): the grass and the soil, the path's
	# soil with them - never water, rock or the path's stones.
	var ground_entries := PackedVector3Array()
	for entry in MUDDIED:
		ground_entries.append(_vec(entry))
	material.set_shader_parameter("mud_from", ground_entries)
	material.set_shader_parameter("mud", 0.0)


func _switch_to(now: int) -> void:
	_season = now
	ground.set_shader_parameter("season", now)
	for material in _worn:
		if material != null:
			material.set_shader_parameter("season", now)
	changed.emit(now)


static func _vec(colour_name: StringName) -> Vector3:
	var colour: Color = PaletteData.COLOURS.get(colour_name, Color.BLACK)
	return Vector3(colour.r, colour.g, colour.b)


# -------------------------------------------------------- the seasonal art

## The art for a frame (`"props/tree"`, a path under `res://sprites/` without
## `.png`) in `season`: `<art>_<season>` when 0120's lookup has it - the
## pack's raster, or its registered stand-in - and `art` otherwise.
static func frame_for(art: String, season: int) -> String:
	var seasonal := "%s_%s" % [art, GameData.SEASONS[clampi(season, 0, 3)]]
	if PlaceholderArt.has_frame(file_of(seasonal)) or ResourceLoader.exists(file_of(seasonal)):
		return seasonal
	return art


## **Every foliage colour in `used` a season of `tables` leaves unmapped**,
## as `"season: colour"` - for the check that guards the tables (task 0159).
## `tables` is `PaletteData.SEASON_REMAP`'s shape: season -> {from: to}.
static func unmapped(tables: Dictionary, used: Array) -> Array:
	var out: Array = []
	for season_id in GameData.SEASONS:
		var table: Dictionary = tables.get(season_id, {})
		for colour in used:
			if not table.has(colour):
				out.append("%s: %s" % [season_id, colour])
	return out


## Whether `art` in `season` is the real seasonal art - which the remap
## leaves alone - rather than the base frame or a stand-in, which it remaps.
static func carries_season(art: String, season: int) -> bool:
	var seasonal := frame_for(art, season)
	return seasonal != art and not stand_in(seasonal) \
		and ResourceLoader.exists(file_of(seasonal))


## Whether a frame is a registered stand-in (0120's road) rather than art.
static func stand_in(art: String) -> bool:
	var file := file_of(art)
	return PlaceholderArt.texture_path(file) != file


## The file a frame draws from: its own, or its stand-in's.
static func texture_file(art: String) -> String:
	return PlaceholderArt.texture_path(file_of(art))


static func file_of(art: String) -> String:
	return "res://sprites/%s.png" % art


## A node drawn in another node's shape wears that node's cap. A021's coal
## seams are seams (task 0204): A013's generic cap, fitted to the ore and the
## rock, floats above them, and the seam's own sits on them as it does on a
## seam.
const CAP_LIKE := {&"coal_seam": &"seam", &"coal_seam_b": &"seam"}


## The snow cap for a node drawn as `art` (`"rock_b"`), a path like
## `frame_for`'s: its own (A013's `props/<art>_snow`), its shape's
## (`CAP_LIKE`), or the generic one.
static func cap_for(art: StringName, two_by_two: bool) -> String:
	var own := "props/%s_snow" % CAP_LIKE.get(art, art)
	if PlaceholderArt.has_frame(file_of(own)) or ResourceLoader.exists(file_of(own)):
		return own
	return "props/snow_cap_2x2" if two_by_two else "props/snow_cap"
