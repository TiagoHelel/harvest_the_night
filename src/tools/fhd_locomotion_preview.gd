extends SceneTree

## Real renderer playback of approved front-facing idle/walk/run art.
## The preview advances only view clocks; no movement speed/rule is added.
const ART := "res://assets/art_source/player-fhd/approved/frames/"
const OUT := "res://implementation/fhd-player/locomotion-playback/"
const LABELS := ["IDLE", "WALK - 8 FRAMES", "RUN - 8 FRAMES"]
const NAMES := ["idle_south", "walk_south", "run_south"]
const COUNTS := [3, 8, 8]
var _bodies: Array[Sprite2D] = []
var _textures: Array = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	# Physical 120px character size matches the planned actual FHD appearance.
	root.content_scale_size = Vector2i(660, 240)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	root.size = Vector2i(660, 240)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var layer := Node2D.new()
	root.add_child(layer)
	for column in 3:
		var panel := ColorRect.new()
		panel.position = Vector2(column * 220 + 4, 4)
		panel.size = Vector2(212, 232)
		panel.color = Color8(54, 49, 61)
		layer.add_child(panel)
		var label := Label.new()
		label.text = LABELS[column]
		label.position = Vector2(column * 220 + 26, 14)
		label.add_theme_font_override("font", load("res://assets/fonts/harvest_hud.fnt"))
		label.add_theme_font_size_override("font_size", 8)
		layer.add_child(label)
		var shadow := Sprite2D.new()
		shadow.texture = load(PlayerView.SHADOW)
		shadow.position = Vector2(column * 220 + 110, 206)
		shadow.scale = Vector2(4, 4)
		shadow.modulate.a = PlayerView.SHADOW_ALPHA
		layer.add_child(shadow)
		var line := Line2D.new()
		line.points = PackedVector2Array([Vector2(column * 220 + 35, 210), Vector2(column * 220 + 185, 210)])
		line.width = 1
		line.default_color = Color8(112, 96, 76)
		layer.add_child(line)
		var body := Sprite2D.new()
		body.centered = false
		body.offset = Vector2(-48, -88)
		body.position = Vector2(column * 220 + 110, 210)
		body.scale = Vector2(2, 2)
		body.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		layer.add_child(body)
		_bodies.append(body)
		var group: Array[Texture2D] = []
		for frame in COUNTS[column]:
			var path: String = ART + String(NAMES[column]) + "_%d.png" % frame
			var texture: Texture2D = load(path)
			if texture == null or texture.get_size() != Vector2(96, 96):
				push_error("Missing complete source-owned animation frame: " + path)
				quit(1)
				return
			group.append(texture)
		_textures.append(group)
	for frame in 192:
		var elapsed := float(frame) / 25.0
		var blink := fmod(elapsed, 3.44)
		var indices := [0 if blink < 3.2 else 1 if blink < 3.32 else 2,
			(frame / 3) % 8, (frame / 2) % 8]
		for column in 3:
			_bodies[column].texture = _textures[column][indices[column]]
		await process_frame
		await RenderingServer.frame_post_draw
		var picture := root.get_texture().get_image()
		if picture == null or picture.get_size() != Vector2i(660, 240):
			push_error("Locomotion capture must use exact physical review dimensions")
			quit(1)
			return
		picture.save_png(ProjectSettings.globalize_path(OUT + "frame-%03d.png" % frame))
	print("LOCOMOTION PLAYBACK: 192 actual renderer frames at 25 fps; idle + 8 walk + 8 run; 120px physical body reference")
	quit(0)
