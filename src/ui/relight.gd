class_name Relight
extends CanvasLayer

## The second half of the light: everything a `CanvasModulate` cannot do.
##
## `design.md` section 18 wants two realities out of one set of sprites, and
## the reference sheet is explicit about what that means - the night half is
## the same farm, same shapes, in purple and blue, with fire and lit windows
## as the only warm things in it. A multiply gets part of the way there and
## then stops: it can take light away, so it can make a dim blue afternoon,
## but the sheet's night is *lifted* towards purple and *drained* of colour,
## and neither is a thing a multiply can do.
##
## So the tint stays on the `CanvasModulate` in `WorldView` - it is free, and
## it is what the rest of the game reads to know what the light is doing - and
## this layer adds lift, saturation and the warm exemption over the top.
##
## ## Where it sits, and why that needed no renumbering
##
## Between `WorldView` and `UI` in `Main.tscn`. Both this and `UI` are on
## `CanvasLayer` 1 and ties are broken by tree order, so the world is relit and
## the HUD is not - which is what you want: a health bar that went purple
## after dark would be a health bar nobody can read at the moment it matters.
##
## ## It is cosmetic, and structurally so
##
## Nothing here is ever read by `src/core/`. It owns no state, takes no input
## and draws nothing of its own - it is a full-screen rectangle over a copy of
## the frame. Turning it off changes what a night looks like and nothing about
## what a night does, which is the promise task 0076 has to keep as well.

const SHADER: Shader = preload("res://src/ui/relight.gdshader")

var _rect: ColorRect
var _material: ShaderMaterial


func _ready() -> void:
	# **The copy has to be its own node.** A canvas shader that reads
	# `hint_screen_texture` is reading a back buffer, and in 2D that buffer is
	# only filled where something asked for it. Without this, the shader
	# samples whatever was left in it - which is the previous frame on a good
	# day and nothing at all on the first one.
	var copy := BackBufferCopy.new()
	copy.name = "RelightCopy"
	copy.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
	add_child(copy)

	_material = ShaderMaterial.new()
	_material.shader = SHADER

	_rect = ColorRect.new()
	_rect.name = "RelightRect"
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.material = _material
	add_child(_rect)

	apply(Color.WHITE, Color(0, 0, 0), 1.0, 1.0)


## Light the farm this way. Called every frame by `WorldView`, which owns the
## question of what the light should be; this owns only how to apply it.
##
## `tint` is the same colour the `CanvasModulate` is set to, and it is passed
## in rather than looked up because the shader needs to divide it back out to
## find what the palette originally painted - see `relight.gdshader`.
func apply(tint: Color, lift: Color, saturation: float,
		warm_keep: float, warm_edge: float = 0.06) -> void:
	if _material == null:
		return
	_material.set_shader_parameter("tint",
		Vector3(tint.r, tint.g, tint.b))
	_material.set_shader_parameter("lift",
		Vector3(lift.r, lift.g, lift.b))
	_material.set_shader_parameter("saturation", saturation)
	_material.set_shader_parameter("warm_keep", warm_keep)
	_material.set_shader_parameter("warm_edge", warm_edge)


## What the shader is currently set to, for `input_check` to read back.
func settings() -> Dictionary:
	if _material == null:
		return {}
	return {
		"tint": _material.get_shader_parameter("tint"),
		"lift": _material.get_shader_parameter("lift"),
		"saturation": _material.get_shader_parameter("saturation"),
		"warm_keep": _material.get_shader_parameter("warm_keep"),
		"warm_edge": _material.get_shader_parameter("warm_edge"),
	}
