class_name WeatherView
extends Node2D

## **The night's weather on screen** (task 0258): fog that looks like fog and
## ground gone to mud - with the rain's drops in `Particles` and the rain's
## and the Blood Moon's ramps in `WorldView._night_ramp` - and none of it
## touches a rule. It reads `Weather.event` and `Light.lit_cells`, writes
## nothing, and the whole node can go without changing a tick.
##
## - **Fog**: a noise a shader works out (`fog.gdshader`, no texture) over the
##   whole farm, over the actors and under the night's cues, the lamps and
##   the HUD, in whole world pixels and four steps of thickness, drifting -
##   and thinner on every cell `Light` calls lit, so the searchlight visibly
##   cuts it. Under the night's ramp, so the night colours it.
## - **Mud**: on a rainy night the ground's material (`SeasonView.set_mud`)
##   darkens the grass and the soil toward wet earth; water, rock and the
##   path's stones stay as they are.
##
## ## With the night, and gone at dawn
##
## Each comes up with the light's own fade into the night
## (`WorldView.visual_nightness`) and goes with its fade into the day. What
## is shown is the night being fought, or the one the build step is getting
## ready for - and through the morning's fade it is still the night just gone,
## never the one ahead.

## The fog before the night colours it: a palette entry, as everything is.
const FOG_COLOUR := &"bone_dark"
## How often the fog looks again at what is lit, in seconds: the searchlights
## and the porch move with the farm, a burning zombie with its feet.
const LIT_EVERY := 0.1

## The last answer `tonight` worked out: the run's seed, the night, the event.
static var _asked: Array = [-1, -1, &""]

var _state: Dictionary = {}
var _world: WorldView
var _season: SeasonView
var _fog: ColorRect
var _fog_material: ShaderMaterial
var _lit_image: Image
var _lit_texture: ImageTexture
var _lit_due := 0.0
var _showing: StringName = &""
var _strength := 0.0
var _drift := true
var _enabled := true


## Tonight's weather as the view sees it: the night being fought once it has
## begun, today's date's before - `Weather.event`, remembered for the run and
## the night, so a frame that asks it often works it out once.
static func tonight(state: Dictionary) -> StringName:
	if state.is_empty():
		return Weather.NONE
	var phase := int(state.get("phase", Phases.DAY))
	var night := int(state["night"]) if phase == Phases.NIGHT or phase == Phases.RESULT \
		else Phases.night_ahead(state)
	var seed_value := int(state["seed"])
	if int(_asked[0]) != seed_value or int(_asked[1]) != night:
		_asked = [seed_value, night, Weather.event(seed_value, night)]
	return StringName(_asked[2])


## Hang it on a world: the light it fades with, and the ground it muddies.
func setup(world: WorldView, season: SeasonView) -> void:
	_world = world
	_season = season


func _ready() -> void:
	name = "Weather"
	_lit_image = Image.create(Grid.WIDTH, Grid.HEIGHT, false, Image.FORMAT_L8)
	_lit_image.fill(Color.BLACK)
	_lit_texture = ImageTexture.create_from_image(_lit_image)
	_fog_material = ShaderMaterial.new()
	_fog_material.shader = preload("res://src/ui/fog.gdshader")
	var tile := float(GameData.TILE_SIZE)
	var colour: Color = PaletteData.COLOURS[FOG_COLOUR]
	_fog_material.set_shader_parameter("world_size", Vector2(Grid.WIDTH, Grid.HEIGHT) * tile)
	_fog_material.set_shader_parameter("lit_mask", _lit_texture)
	_fog_material.set_shader_parameter("fog_colour", Vector3(colour.r, colour.g, colour.b))
	_fog_material.set_shader_parameter("density", 0.0)
	_fog = ColorRect.new()
	_fog.name = "Fog"
	_fog.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fog.size = Vector2(Grid.WIDTH, Grid.HEIGHT) * tile
	_fog.material = _fog_material
	# Over the actors, under the particles (15) - the snow falls in front of
	# it - and every layer above the world.
	_fog.z_index = 14
	_fog.z_as_relative = false
	_fog.visible = false
	add_child(_fog)
	_read_motion()
	var service := get_node_or_null(^"/root/Settings")
	if service != null and not service.changed.is_connected(_on_setting):
		service.changed.connect(_on_setting)
		service.reloaded.connect(_read_motion)


func show_state(state: Dictionary) -> void:
	if not is_same(_state, state):
		_showing = &""
		_strength = 0.0
		_lit_due = 0.0
	_state = state


func _process(delta: float) -> void:
	if _state.is_empty():
		_fog.visible = false
		if _season != null:
			_season.set_mud(0.0)
		return
	var phase := int(_state["phase"])
	# The night's own weather from its build step to its morning; through the
	# day's fade, still that one.
	if phase != Phases.DAY:
		_showing = tonight(_state)
	_strength = _world.visual_nightness() if _world != null \
		else (0.0 if phase == Phases.DAY else 1.0)
	if not _enabled:
		_strength = 0.0
	var fog := strength(Weather.FOG)
	_fog.visible = fog > 0.0
	_fog_material.set_shader_parameter("density", fog)
	_fog_material.set_shader_parameter("drift", Vector2(3.0, 1.0) if _drift else Vector2.ZERO)
	if _fog.visible:
		_lit_due -= delta
		if _lit_due <= 0.0:
			_lit_due = LIT_EVERY
			_mark_lit()
	if _season != null:
		_season.set_mud(strength(Weather.RAIN))


## How strongly `kind` is on screen now, 0 to 1 - for `Particles`, which
## rains by it, and for `input_v2`.
func strength(kind: StringName) -> float:
	return _strength if _showing == kind else 0.0


## **Every layer off, or back on** - the fog, the mud, the rain and the
## weather's ramps - for `input_v2`, which proves a night ends the same with
## them as without them.
func set_enabled(on: bool) -> void:
	_enabled = on


func is_enabled() -> bool:
	return _enabled


## How muddy the ground is drawn now, 0 to 1 - for `input_v2`.
func mud() -> float:
	return _season.mud() if _season != null else 0.0


## The fog's thickness now, 0 to 1, as the shader has it - for `input_v2`.
func fog_density() -> float:
	return float(_fog_material.get_shader_parameter("density")) if _fog.visible else 0.0


## How many cells the fog thins over now - for `input_v2` and the shots.
func lit_in_fog() -> int:
	var n := 0
	for y in Grid.HEIGHT:
		for x in Grid.WIDTH:
			if _lit_image.get_pixel(x, y).r > 0.5:
				n += 1
	return n


## The mask of lit cells the fog thins over, from `Light.lit_cells` - which
## works the farm out afresh and writes nothing, as the view must.
func _mark_lit() -> void:
	_lit_image.fill(Color.BLACK)
	for cell in Light.lit_cells(_state):
		var at: Vector2i = cell
		_lit_image.set_pixel(at.x, at.y, Color.WHITE)
	_lit_texture.update(_lit_image)


func _on_setting(key: StringName) -> void:
	if key == &"a11y/flashing":
		_read_motion()


## **A player who has turned off light that moves** (`a11y/flashing`) gets a
## fog that holds still. Read by path, as `Lighting` reads it: `verify.py`
## parses every script on its own with no autoload registered.
func _read_motion() -> void:
	var loop := Engine.get_main_loop() as SceneTree
	var service: Node = loop.root.get_node_or_null(^"Settings") \
		if loop != null and loop.root != null else null
	if service == null or not service.has_method("get_value"):
		return
	var flashing: Variant = service.get_value(&"a11y/flashing")
	_drift = flashing == null or bool(flashing)
