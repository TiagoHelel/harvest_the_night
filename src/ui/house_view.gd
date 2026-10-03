class_name HouseView
extends CanvasLayer

## The room uses the existing farmer, native pixels and its own clipped camera.
## Rendering never writes visit position, crops, time or inventory.
var state: Dictionary = {}
var _room: Node2D
var _clip: Control
var _farmer: PlayerView
var _title: Label
var _hint: Label
var _porch_hint: Label
var _backdrop: ColorRect
var _fade: ColorRect
var _was_inside := false
var _zoom_index := 1
var _zoom := 1.0
var _focus := Vector2(160, 104)
var ambient_running := true
var _ambient_time := 0.0
var _flame: ShaderMaterial
const HEARTH_FLAME := preload("res://src/ui/hearth_flame.gdshader")
const FURNITURE_OFFSETS := {&"bed": Vector2(0, -4),
	&"nightstand": Vector2(0, -9), &"storage": Vector2(9, 0)}


## Match the outdoor farmer's held run animation without changing house rules.
func set_running(running: bool) -> void:
	if _farmer != null:
		_farmer.set_running(running)


func _ready() -> void:
	layer = 2
	_backdrop = ColorRect.new()
	_backdrop.color = Color8(30, 24, 28)
	_backdrop.size = Vector2(480, 270)
	_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_backdrop)
	_clip = Control.new()
	_clip.position = Vector2(0, 36)
	_clip.size = Vector2(480, 212)
	_clip.clip_contents = true
	_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_clip)
	_room = Node2D.new()
	_clip.add_child(_room)
	_build_room()
	_title = _label(Vector2(12, 12))
	_hint = _label(Vector2(12, 254))
	_porch_hint = _label(Vector2(156, 40))
	_porch_hint.theme_type_variation = UiKit.PORCH_HINT
	_porch_hint.visible = false
	var fades := CanvasLayer.new()
	fades.layer = 4
	add_child(fades)
	_fade = ColorRect.new()
	_fade.color = Color(0.08, 0.06, 0.09, 0)
	_fade.size = Vector2(480, 270)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fades.add_child(_fade)
	UiKit.dress(self)
	_set_room_visible(false)


func _label(at: Vector2) -> Label:
	var label := Label.new()
	label.position = at
	label.theme_type_variation = UiKit.WARM
	add_child(label)
	return label


func _sprite(id: String, parent: Node, at: Vector2, centered := false) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = load("res://sprites/interior/%s.png" % id)
	sprite.centered = centered
	sprite.position = at
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	parent.add_child(sprite)
	return sprite


func _build_room() -> void:
	for y in range(2, House.ROOM.y):
		for x in House.ROOM.x:
			_sprite("floor", _room, Vector2(x * 16, y * 16))
	for x in 14:
		var wall := _sprite("wall", _room, Vector2(x * 24, 0))
		wall.region_enabled = true
		wall.region_rect = Rect2(0, 0, mini(24, House.ROOM.x * 16 - x * 24), 32)
	var rug := _sprite("rug", _room, Vector2(160, 166), true)
	rug.name = "Rug"
	var furniture := Node2D.new()
	furniture.y_sort_enabled = true
	_room.add_child(furniture)
	for piece in House.FURNITURE:
		var cell: Vector2i = piece["cell"]
		var size: Vector2i = piece["size"]
		var at := Vector2((cell.x + size.x * 0.5) * 16, (cell.y + size.y) * 16)
		var sprite := _sprite(str(piece["id"]), furniture, at)
		sprite.position += Vector2(FURNITURE_OFFSETS.get(piece["id"], Vector2.ZERO))
		sprite.name = str(piece["id"])
		sprite.offset = -Vector2(RasterArt.FRAMES[sprite.texture.resource_path]["pivot"])
		if piece["id"] == &"fireplace":
			_flame = ShaderMaterial.new()
			_flame.shader = HEARTH_FLAME
			sprite.material = _flame
		elif piece["id"] == &"nightstand":
			_add_lamp_glow(sprite)
	_farmer = PlayerView.new()
	_farmer.name = "IndoorFarmer"
	furniture.add_child(_farmer)
	# Structural wall edges frame the generated wall/floor rather than cover it.
	var frame := Node2D.new()
	frame.z_index = 10
	frame.draw.connect(func():
		frame.draw_rect(Rect2(0, 32, 10, 176), Color8(58, 38, 29))
		frame.draw_rect(Rect2(310, 32, 10, 176), Color8(58, 38, 29))
		frame.draw_rect(Rect2(0, 196, 152, 12), Color8(58, 38, 29))
		frame.draw_rect(Rect2(184, 196, 136, 12), Color8(58, 38, 29))
		frame.draw_rect(Rect2(152, 192, 32, 16), Color8(140, 98, 57))
		frame.draw_line(Vector2(154, 205), Vector2(182, 205), Color8(232, 224, 207), 1.0))
	_room.add_child(frame)


func _add_lamp_glow(sprite: Sprite2D) -> void:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.3, 1.0])
	gradient.colors = PackedColorArray([Color(1.0, 0.76, 0.34, 0.20),
		Color(1.0, 0.76, 0.34, 0.08), Color(1.0, 0.76, 0.34, 0.0)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 48
	texture.height = 48
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	var glow := Sprite2D.new()
	glow.name = "LampGlow"
	glow.texture = texture
	glow.position = Vector2(0, -32)
	glow.show_behind_parent = true
	sprite.add_child(glow)


func _refresh_ambient(delta: float) -> void:
	if not ambient_running:
		return
	var settings := get_node_or_null("/root/Settings")
	if settings != null and not settings.get_bool(&"a11y/flashing"):
		_flame.set_shader_parameter("flame_time", 0.0)
		return
	_ambient_time += maxf(delta, 0.0)
	_flame.set_shader_parameter("flame_time", _ambient_time)


func _set_room_visible(on: bool) -> void:
	_backdrop.visible = on
	_clip.visible = on
	_title.visible = on
	_hint.visible = on


func show_state(value: Dictionary) -> void:
	state = value
	if _farmer != null:
		_farmer.show_state(state)


func change_zoom(direction: int) -> void:
	_zoom_index = clampi(_zoom_index + direction, 0, WorldView.ZOOM_LEVELS.size() - 1)


func reset_zoom() -> void:
	_zoom_index = 1


func _process(delta: float) -> void:
	if state.is_empty():
		return
	var indoors := House.inside(state)
	var actions := get_node_or_null("/root/Actions")
	var interact_key: String = actions.text_of(&"interact") if actions != null else ""
	_porch_hint.visible = House.can_enter(state)
	_porch_hint.text = I18n.f(&"HOUSE_ENTER_HINT", [interact_key])
	if _porch_hint.visible:
		var feet := get_viewport().get_canvas_transform() * ArtPlacement.contact(state["player"]["pos"])
		_porch_hint.position = Vector2(clampf(feet.x - _porch_hint.size.x * 0.5, 8,
			480 - _porch_hint.size.x - 8), clampf(feet.y + 8, 40, 232))
	if indoors != _was_inside:
		_was_inside = indoors
		_set_room_visible(indoors)
		_fade.color.a = 1.0
		_focus = Vector2(Player.position(state)) * GameData.TILE_SIZE / Player.SUBTILE
	_fade.color.a = maxf(0.0, _fade.color.a - delta * 5.0)
	if not indoors:
		return
	_refresh_ambient(delta)
	_title.text = I18n.t(&"HOUSE_TITLE")
	_hint.text = I18n.f(&"HOUSE_EXIT_HINT", [interact_key])
	var blend := 1.0 - exp(-WorldView.CAMERA_RESPONSE * delta)
	_zoom = lerpf(_zoom, float(WorldView.ZOOM_LEVELS[_zoom_index]), blend)
	var target := Vector2(Player.position(state)) * GameData.TILE_SIZE / Player.SUBTILE
	_focus = _focus.lerp(target, blend)
	var extent := Vector2(House.ROOM) * GameData.TILE_SIZE
	var half := _clip.size * 0.5 / _zoom
	var camera := Vector2(
		extent.x * 0.5 if extent.x < half.x * 2.0 else clampf(_focus.x, half.x, extent.x - half.x),
		extent.y * 0.5 if extent.y < half.y * 2.0 else clampf(_focus.y, half.y, extent.y - half.y))
	_room.scale = Vector2.ONE * _zoom
	_room.position = _clip.size * 0.5 - camera * _zoom
