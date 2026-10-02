extends SceneTree

## Asset review only: clocks animate candidates without running game simulation.
const HERE := "res://implementation/fhd-player/directional/"
const DIRECTIONS := ["FRONT", "LEFT", "BACK", "RIGHT"]
const SIZE := Vector2i(1040, 288)
var _bodies: Array[Sprite2D] = []
var _labels: Array[Label] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.content_scale_size = SIZE
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	root.size = SIZE
	var layer := Node2D.new()
	root.add_child(layer)
	for column in 4:
		var panel := ColorRect.new()
		panel.position = Vector2(column * 260 + 4, 4)
		panel.size = Vector2(252, 280)
		panel.color = Color8(54, 49, 61)
		layer.add_child(panel)
		var label := Label.new()
		label.position = Vector2(column * 260 + 14, 14)
		label.add_theme_font_override("font", load("res://assets/fonts/harvest_hud.fnt"))
		label.add_theme_font_size_override("font_size", 8)
		layer.add_child(label)
		_labels.append(label)
		var shadow := Sprite2D.new()
		shadow.texture = load(PlayerView.SHADOW)
		shadow.position = Vector2(column * 260 + 130, 240)
		shadow.scale = Vector2(4, 4)
		shadow.modulate.a = PlayerView.SHADOW_ALPHA
		layer.add_child(shadow)
		var line := Line2D.new()
		line.points = PackedVector2Array([Vector2(column * 260 + 18, 244), Vector2(column * 260 + 242, 244)])
		line.width = 1
		line.default_color = Color8(112, 96, 76)
		layer.add_child(line)
		var body := Sprite2D.new()
		body.centered = false
		body.position = Vector2(column * 260 + 130, 244)
		body.scale = Vector2(2, 2)
		body.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		layer.add_child(body)
		_bodies.append(body)
	var text: String = FileAccess.get_file_as_string(HERE + "playback.json")
	var spec: Dictionary = JSON.parse_string(text)
	var only: PackedStringArray = []
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--only="):
			only = argument.trim_prefix("--only=").split(",")
	for raw_group in spec["groups"]:
		var group: Dictionary = raw_group
		var action: String = group["action"]
		if not only.is_empty() and not only.has(action):
			continue
		var destination: String = HERE + "captures/" + action + "/"
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(destination))
		var textures: Array = []
		for column in 4:
			var frames: Array = group["columns"][column]["frames"]
			var sequence: Array[Texture2D] = []
			for raw_frame in frames:
				var frame: Dictionary = raw_frame
				var path: String = frame["path"]
				# Load raw native review PNGs so a crop revision is visible without
				# relying on an older editor-imported texture cache.
				var native := Image.new()
				var image_error: int = native.load_png_from_buffer(FileAccess.get_file_as_bytes(path))
				if image_error != OK or native.is_empty():
					push_error("Missing candidate asset: " + path)
					quit(1)
					return
				var texture: Texture2D = ImageTexture.create_from_image(native)
				sequence.append(texture)
			textures.append(sequence)
			_bodies[column].offset = -Vector2(frames[0]["pivot"][0], frames[0]["pivot"][1])
			_labels[column].text = String(group["label"]) + "\n" + String(DIRECTIONS[column])
		for frame_number in 192:
			var elapsed := float(frame_number) / 25.0
			var index: int = 0
			if action == "idle":
				var blink := fmod(elapsed, 3.44)
				index = 0 if blink < 3.2 else 1 if blink < 3.32 else 2
			elif action == "walk":
				index = (frame_number / 3) % 8
			elif action == "run":
				index = (frame_number / 2) % 8
			elif action == "fish":
				# A deliberate wait displays the held rod rather than recasting nonstop.
				var phase := fmod(elapsed, 2.56)
				index = 0 if phase < 0.24 else 1 if phase < 0.40 else 2 if phase < 0.64 else 3
			else:
				index = int(floor(elapsed / float(group["seconds"]))) % 4
			for column in 4:
				_bodies[column].texture = textures[column][index]
			await process_frame
			await RenderingServer.frame_post_draw
			var picture := root.get_texture().get_image()
			if picture == null or picture.get_size() != SIZE:
				push_error("Directional capture requires actual 1040x288 renderer output")
				quit(1)
				return
			picture.save_png(ProjectSettings.globalize_path(destination + "frame-%03d.png" % frame_number))
		print("DIRECTIONAL REVIEW: ", action, " 192 renderer frames, four directions, 120px body reference")
	quit(0)
