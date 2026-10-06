extends "res://src/tools/enemy_showcase.gd"

## Real-renderer FHD review of the integrated 32px farmer, 2026-10-06.
##
## The game's own 1920x1080 output - its 480x270 viewport stretched four times
## over canvas items - through the production WorldView, PlayerView, Relight
## and Lighting, driven by the real core: Player.tick for idle, walk and run in
## all eight directions and for stopping and starting; Interact for the tool
## poses; Sim.tick for a fishing line (a day job by rule); Enemies.tick for
## zombies walking left and right and striking a wall; Combat.hit for deaths;
## the Giant's own wind-up and slam. By day and by night. It takes pictures
## and changes nothing: no texture is swapped, no rule, save or production
## file is touched.
##
##     godot --path . --fixed-fps 60 --position -4000,-4000 --script \
##         res://implementation/fhd-player/pilots/2026-10-06/farmer32-integration/capture.gd
##
## Every farmer crop is also measured on the renderer: the pixels that change
## when only the body sprite is hidden are the body as drawn, so the report
## holds its height in physical pixels and where its lowest pixel sits
## against the core contact point.

const OUT := "res://implementation/shots/farmer32-1080/"
## One unscaled crop per pose, the feet 205 pixels down it: a 128px farmer,
## his shadow and a swung tool fit with room to spare.
const CROP := Vector2i(240, 240)
const FEET_IN_CROP := Vector2i(120, 205)
## The Giant's 80x64 canvas is 320x256 on screen.
const BIG_CROP := Vector2i(360, 320)
const BIG_FEET := Vector2i(180, 280)
## Near the middle of what `_settle()` looks at, cell (15, 8).
const STAND := Vector2i(15, 9)

var _report: Dictionary = {"farmer": [], "sheets": [], "frames": []}
var _pictures := 0
## Where pictures go, and how many walk phases a row shows: a script that
## extends this one may point them elsewhere, or add the 8 -> 1 wrap.
var _out := OUT
var _walk_frames := 8
## The last whole frame `_shoot` wrote, for crops of the same instant.
var _last: Image


func _run() -> void:
	CaptureSize.configure(root, true)
	await _setup()
	_capture = true
	_folder = _out
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out))
	for night in [false, true]:
		await _locomotion(night)
		await _stop_start(night)
		await _tools(night)
		await _zombie_walks(night)
		await _zombie_attacks(night)
		await _deaths(night)
		await _giant_attack(night)
	await _fishing()
	_summarise()
	var file := FileAccess.open(_out + "renderer-report.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(_report, "  ") + "\n")
	file.close()
	print("FARMER32 FHD REVIEW: %d checks, %d failed, %d pictures" % [_checks, _failed, _pictures])
	quit(1 if _failed > 0 else 0)


# ------------------------------------------------------------------- frames

func _frame() -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()


## The whole frame, exactly as the game shows it at 1920x1080.
func _shoot(name: String, caption: String) -> void:
	_caption.text = caption
	var image: Image = await _frame()
	expect(image.get_size() == Vector2i(1920, 1080), "The game's own FHD output: " + name)
	expect(image.save_png(_out + name + ".png") == OK, "Saved " + name)
	_last = image
	_pictures += 1
	(_report["frames"] as Array).append({"name": name, "caption": caption})


## Where a node's ground point is drawn, in physical pixels.
func _on_screen(node: CanvasItem) -> Vector2i:
	return Vector2i(root.get_stretch_transform() * (node.get_global_transform_with_canvas() * Vector2.ZERO))


func _crop(image: Image, feet: Vector2i, size := CROP, at := FEET_IN_CROP) -> Image:
	var region := Rect2i(feet - at, size)
	expect(Rect2i(Vector2i.ZERO, image.get_size()).encloses(region), "An unscaled crop fits the frame")
	return image.get_region(region)


## The farmer as drawn: a crop around the feet, and the body's own pixels
## found by hiding the body sprite alone and comparing the two renders.
func _farmer(label: String) -> Image:
	_caption.text = ""
	var body: Sprite2D = _view.get_node("Body")
	var feet := _on_screen(_view)
	var before := var_to_bytes(_state)
	var first: Image = await _frame()
	var shown := _crop(first, feet)
	body.visible = false
	var second: Image = await _frame()
	var hidden := _crop(second, feet)
	body.visible = true
	expect(var_to_bytes(_state) == before, "Rendering the farmer changes no core byte")
	var a := shown.get_data()
	var b := hidden.get_data()
	var top := CROP.y
	var bottom := -1
	for y in CROP.y:
		for x in CROP.x:
			var at := (y * CROP.x + x) * 4
			if a.decode_u32(at) != b.decode_u32(at):
				top = mini(top, y)
				bottom = maxi(bottom, y)
	var path := body.texture.resource_path if body.texture != null else ""
	expect(bottom >= 0, "The farmer is visible in " + label)
	(_report["farmer"] as Array).append({
		"label": label, "texture": path, "playing": String(_view.playing()),
		"flipped": _view.flipped(), "scale": body.scale.x,
		"body_height_px": bottom - top + 1,
		"lowest_pixel_vs_contact_px": bottom + 1 - FEET_IN_CROP.y,
	})
	return shown


func _sheet(name: String, rows: Array, size := CROP) -> void:
	var columns := 0
	for row in rows:
		columns = maxi(columns, (row as Array).size())
	var sheet := Image.create(size.x * columns, size.y * rows.size(), false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.05, 0.05, 0.06))
	for r in rows.size():
		for c in (rows[r] as Array).size():
			var crop: Image = rows[r][c]
			sheet.blit_rect(crop, Rect2i(Vector2i.ZERO, crop.get_size()), Vector2i(c * size.x, r * size.y))
	expect(sheet.save_png(_out + name + ".png") == OK, "Saved sheet " + name)
	_pictures += 1
	(_report["sheets"] as Array).append({"name": name, "rows": rows.size(), "columns": columns})


func _place(cell: Vector2i, facing: int = Player.SOUTH) -> void:
	_state["player"]["pos"] = [cell.x * Player.SUBTILE + Player.SUBTILE / 2,
		cell.y * Player.SUBTILE + Player.SUBTILE / 2]
	_state["player"]["facing"] = facing
	_state["player"]["action"] = {}
	_state["intent"]["move"] = [0, 0]


func _tag(night: bool) -> String:
	return "night" if night else "day"


# ----------------------------------------------------------------- farmer

## Idle, walk and run in each of the eight directions: one sheet each, a row
## per direction in PlayerArt.HEADINGS order, a column per authored frame.
func _locomotion(night: bool) -> void:
	for motion in ["idle", "walk", "run"]:
		var rows: Array = []
		for heading in PlayerArt.HEADINGS:
			var suffix: StringName = PlayerArt.HEADINGS[heading]
			_state = _blank(night)
			_place(STAND)
			_view.set_running(motion == "run")
			_state["intent"]["move"] = [heading.x, heading.y]
			Player.tick(_state)
			await _settle()
			if motion == "idle":
				_state["intent"]["move"] = [0, 0]
				_view._process(0.0)
			var wanted := StringName("%s_%s" % ["idle" if motion == "idle" else "walk", suffix])
			expect(_view.playing() == wanted, "%s %s plays %s" % [motion, suffix, wanted])
			var row: Array = []
			for frame in (1 if motion == "idle" else _walk_frames):
				if frame > 0:
					Player.tick(_state)
					_view._process(_view.frame_seconds() + 0.0001)
				var body: Sprite2D = _view.get_node("Body")
				expect(body.texture.resource_path == PlayerArt.texture_path(wanted, frame % 8),
					"%s %s shows authored frame %d" % [motion, suffix, frame])
				row.append(await _farmer("%s_%s_%s_%d" % [_tag(night), motion, suffix, frame]))
			if motion == "walk" and heading == Vector2i(1, 0):
				await _shoot("%s_walk_east_full" % _tag(night), "32px farmer walking east / %s / 1920x1080" % _tag(night))
			rows.append(row)
		_view.set_running(false)
		if motion == "idle":
			# One row reads better than a column of eight.
			var line: Array = []
			for row in rows:
				line.append(row[0])
			rows = [line]
		await _sheet("farmer_%s_%s" % [motion, _tag(night)], rows)


## Standing, setting off, stopping, turning, running and stopping again, in
## one strip of consecutive views.
func _stop_start(night: bool) -> void:
	_state = _blank(night)
	_place(STAND)
	await _settle()
	var strip: Array = [await _farmer("%s_stop_start_00_idle" % _tag(night))]
	var plan := [
		[Vector2i(1, 0), false, 4], [Vector2i.ZERO, false, 1],
		[Vector2i(-1, -1), false, 3], [Vector2i.ZERO, false, 1],
		[Vector2i(0, 1), true, 3], [Vector2i.ZERO, false, 1],
	]
	for leg in plan:
		var move: Vector2i = leg[0]
		_view.set_running(bool(leg[1]))
		for step in int(leg[2]):
			_state["intent"]["move"] = [move.x, move.y]
			if move != Vector2i.ZERO:
				Player.tick(_state)
			_view._process(0.0 if step == 0 else _view.frame_seconds() + 0.0001)
			strip.append(await _farmer("%s_stop_start_%02d_%s" % [_tag(night), strip.size(), _view.playing()]))
			if move == Vector2i.ZERO:
				expect(String(_view.playing()).begins_with("idle_"), "Releasing the keys stands still at once")
	_view.set_running(false)
	await _sheet("farmer_stop_start_%s" % _tag(night), [strip])


## A tool job seen through: walking at the target, standing, the four
## authored frames on the real completion clock, and standing again. At
## night only mending is offered (`Interact.DAY_ONLY`), so that is the job.
func _tools(night: bool) -> void:
	var rows: Array = []
	for verb in ([&"repair"] if night else [&"chop", &"mine", &"water", &"repair"]):
		for facing in [Player.EAST, Player.WEST]:
			_state = _blank(night)
			var step: Vector2i = Player.FACING_STEPS[facing]
			var target := STAND + step
			_target(verb, target)
			_place(STAND, facing)
			await _settle()
			var row: Array = []
			_state["intent"]["move"] = [step.x, step.y]
			_tick()
			_view._process(0.0)
			row.append(await _farmer("%s_%s_%d_walk_in" % [_tag(night), verb, facing]))
			_state["intent"]["move"] = [0, 0]
			_view._process(0.0)
			row.append(await _farmer("%s_%s_%d_stand" % [_tag(night), verb, facing]))
			expect(Interact.verb_at(_state, target) == verb, "Real target offers %s" % verb)
			var total := Interact.ticks_for(_state, target, verb)
			_state["intent"]["interact"] = true
			_tick()
			_view._process(0.0)
			if Player.is_busy(_state):
				row.append(await _farmer("%s_%s_%d_frame0" % [_tag(night), verb, facing]))
				for _i in total - 1:
					_tick()
				_view._process(0.0)
			row.append(await _farmer("%s_%s_%d_contact" % [_tag(night), verb, facing]))
			for _i in 2:
				_view._process(0.09)
				row.append(await _farmer("%s_%s_%d_follow" % [_tag(night), verb, facing]))
			# A tree or a rock repeats its swing while the job holds; the
			# cancel key is how a player puts the tool down.
			_state["intent"]["cancel"] = true
			_tick()
			_view._process(0.0)
			row.append(await _farmer("%s_%s_%d_after" % [_tag(night), verb, facing]))
			expect(String(_view.playing()).begins_with("idle_"), "%s puts the tool down and stands" % verb)
			rows.append(row)
	await _sheet("farmer_tools_%s" % _tag(night), rows)


func _target(verb: StringName, at: Vector2i) -> void:
	var idx := Grid.index(at)
	var on: Dictionary = _state["occupants"]
	match verb:
		&"chop":
			on[idx] = {"id": &"tree"}
		&"mine":
			on[idx] = {"id": &"rock"}
		&"water":
			var crop: StringName = Farming.seeds()[0]
			var terrain: PackedByteArray = _state["terrain"]
			terrain[idx] = Farm.Terrain.SOIL
			_state["terrain"] = terrain
			var plot := Farming.EMPTY_PLOT.duplicate()
			plot["crop"] = crop
			_state["plots"][idx] = plot
			_state["water_can"] = GameData.WATER_CAN_CAPACITY
		&"repair":
			on[idx] = {"id": &"fence", "hp": int(GameData.DEFENCES[&"fence"]["hp"]) - 10}
	_state["grid_version"] = int(_state["grid_version"]) + 1


## One tick of the farmer, watched the way Main watches it.
func _tick(whole := false) -> void:
	_view.before_tick(_state)
	if whole:
		Sim.tick(_state)
	else:
		Player.tick(_state)
	_view.after_tick(_state)


## Casting, the rod held through the wait, the bite, the catch and standing
## again. Fishing is a day job by rule (`Fishing.tick` runs in the day only).
func _fishing() -> void:
	var rows: Array = []
	for facing in [Player.EAST, Player.WEST]:
		_state = _blank(false)
		var step: Vector2i = Player.FACING_STEPS[facing]
		var water := STAND + step
		var terrain: PackedByteArray = _state["terrain"]
		terrain[Grid.index(water)] = Farm.Terrain.WATER
		_state["terrain"] = terrain
		_place(STAND, facing)
		await _settle()
		var row: Array = [await _farmer("fish_%d_stand" % facing)]
		_state["intent"]["interact"] = true
		for i in Interact.ticks_for(_state, water, &"fish"):
			_tick(true)
			_view._process(1.0 / GameData.TICK_HZ)
			if i == 0:
				row.append(await _farmer("fish_%d_cast" % facing))
		expect(Fishing.is_casting(_state), "The cast puts a line in")
		_view._process(0.3)
		row.append(await _farmer("fish_%d_wait" % facing))
		for _i in Fishing.ticks_left(_state):
			_tick(true)
			_view._process(1.0 / GameData.TICK_HZ)
		expect(Fishing.is_biting(_state), "The real wait reaches the bite")
		row.append(await _farmer("fish_%d_bite" % facing))
		_state["intent"]["interact"] = true
		_tick(true)
		_view._process(0.0)
		row.append(await _farmer("fish_%d_catch" % facing))
		_view._process(0.6)
		row.append(await _farmer("fish_%d_after" % facing))
		rows.append(row)
	await _sheet("farmer_fishing_day", rows)


# ----------------------------------------------------------------- zombies

## The four families walking at the house, from the right and from the left,
## with the farmer standing by for scale.
func _zombie_walks(night: bool) -> void:
	for left in [true, false]:
		_state = _blank(night)
		_house(Vector2i(2, 8) if left else Vector2i(26, 8))
		_place(Vector2i(15, 15))
		var ids: Array[int] = []
		for i in EnemyMotion.FAMILIES.size():
			ids.append(Entities.spawn(_state, EnemyMotion.FAMILIES[i], Vector2i(21 if left else 8, 3 + i * 3)))
		await _settle()
		var strip: Array = []
		for t in 72:
			_step()
			_world._refresh_actors()
			if t in [11, 35, 59]:
				await _settle()
				var name := "%s_zombies_walk_%s_t%02d" % [_tag(night), "left" if left else "right", t]
				await _shoot(name, "Zombies walking %s / real core movement / %s" % ["left" if left else "right", _tag(night)])
				for i in _world._actor_sprites.size():
					var sprite: Sprite2D = _world._actor_sprites[i]
					if sprite.visible:
						strip.append(_crop(_last, _on_screen(sprite)))
		for id in ids:
			var one := Entities.get_one(_state, id)
			if not one.is_empty() and int(one["pos"][0]) != (21 if left else 8) * Player.SUBTILE + Player.SUBTILE / 2:
				expect(_world._enemy_motion.faces_right(one) != left, "A zombie walking %s faces that way" % ("left" if left else "right"))
		await _sheet("zombies_walk_%s_%s" % ["left" if left else "right", _tag(night)], [strip])


## Real strikes on a paid wall: contact, recovery and the existing waits.
func _zombie_attacks(night: bool) -> void:
	_state = _blank(false)
	_house(Vector2i(2, 8))
	_place(Vector2i(15, 15))
	var ids: Array[int] = []
	for i in EnemyMotion.FAMILIES.size():
		var cell := Vector2i(17, 3 + i * 3)
		var terrain: PackedByteArray = _state["terrain"]
		for side in [Vector2i.UP, Vector2i.DOWN, Vector2i.RIGHT]:
			terrain[Grid.index(cell + side)] = Farm.Terrain.WATER
		_state["terrain"] = terrain
		expect(Building.place(_state, &"wall", cell + Vector2i.LEFT), "A paid wall blocks the only way")
		ids.append(Entities.spawn(_state, EnemyMotion.FAMILIES[i], cell))
	_state["phase"] = Phases.NIGHT if night else Phases.DAY
	await _settle()
	var strip: Array = []
	var seen: Dictionary = {}
	for t in 64:
		_step()
		_world._refresh_actors()
		for id in ids:
			var one := Entities.get_one(_state, id)
			if not one.is_empty():
				var pose := String(_world._pose_of(one))
				if pose.contains("_attack_") and not seen.has(pose):
					seen[pose] = t
		if t in [2, 13, 30, 32]:
			await _settle()
			await _shoot("%s_zombies_attack_t%02d" % [_tag(night), t], "Zombies striking a wall / %s" % _tag(night))
			for node in _world._actor_sprites:
				var sprite := node as Sprite2D
				if sprite.visible:
					strip.append(_crop(_last, _on_screen(sprite)))
	expect(seen.size() >= 4, "Real contact plays the authored attack poses: %s" % str(seen.keys()))
	await _sheet("zombies_attack_%s" % _tag(night), [strip])


## Five real deaths, every authored frame once, at the last contact point.
## Deaths are observed at night, the only time zombies die; the day version
## keeps that and only lights the scene by day, as the Giant showcase does.
func _deaths(night: bool) -> void:
	_state = _blank(true)
	_place(Vector2i(15, 15))
	var ids: Array[int] = []
	for i in EnemyMotion.TRACKED.size():
		ids.append(Entities.spawn(_state, EnemyMotion.TRACKED[i], Vector2i(5 + i * 5, 10)))
	await _settle()
	_world.before_tick(_state)
	_state["tick"] = int(_state["tick"]) + 1
	Enemies.tick(_state)
	for id in ids:
		Combat.hit(_state, id, 10000)
	_world.after_tick(_state)
	expect(Entities.count(_state) == 0 and _world._enemy_deaths._cues.size() == 5, "Five real deaths, five visual cues")
	if not night:
		_world._light.color = Color.WHITE
		(root.get_node("Relight") as Relight).apply(Color.WHITE, Color(0, 0, 0), 1.0, 1.0)
	var rows: Array = []
	for frame in 4:
		_world._refresh_deaths(0.0 if frame == 0 else EnemyDeaths.FRAME_SECONDS)
		_world._refresh_actors()
		await _shoot("%s_deaths_f%d" % [_tag(night), frame], "Deaths / frame %d / %s" % [frame, _tag(night)])
		var row: Array = []
		for sprite in _world._death_sprites:
			if sprite.visible:
				row.append(_crop(_last, _on_screen(sprite), BIG_CROP, BIG_FEET))
		rows.append(row)
	_world._refresh_deaths(EnemyDeaths.FRAME_SECONDS * 2.0)
	await _sheet("deaths_%s" % _tag(night), rows, BIG_CROP)


## The Giant's real wind-up and slam on a wall, each pose the first time
## the core puts it there.
func _giant_attack(night: bool) -> void:
	_state = _blank(false)
	_house(Vector2i(2, 8))
	_place(Vector2i(15, 15))
	var cell := Vector2i(17, 9)
	var terrain: PackedByteArray = _state["terrain"]
	for side in [Vector2i.UP, Vector2i.DOWN, Vector2i.RIGHT]:
		terrain[Grid.index(cell + side)] = Farm.Terrain.WATER
	_state["terrain"] = terrain
	expect(Building.place(_state, &"wall", cell + Vector2i.LEFT), "A paid wall is the Giant's only way")
	_state["phase"] = Phases.NIGHT if night else Phases.DAY
	var id := Entities.spawn(_state, &"giant", cell)
	await _settle()
	var row: Array = []
	var seen: Dictionary = {}
	for t in 60:
		_step()
		var one := Entities.get_one(_state, id)
		if one.is_empty():
			break
		var pose := String(_world._pose_of(one))
		if (pose.begins_with("giant_windup_") or pose.begins_with("giant_slam_")) and not seen.has(pose):
			seen[pose] = t
			await _settle()
			await _shoot("%s_giant_%s" % [_tag(night), pose], "Giant %s / real target and wait / %s" % [pose, _tag(night)])
			for node in _world._actor_sprites:
				var sprite := node as Sprite2D
				if sprite.visible:
					row.append(_crop(_last, _on_screen(sprite), BIG_CROP, BIG_FEET))
					break
	expect(seen.size() == 6, "Three wind-up and three slam poses played: %s" % str(seen.keys()))
	await _sheet("giant_attack_%s" % _tag(night), [row], BIG_CROP)


# ----------------------------------------------------------------- summary

## Body height and ground contact, per family of pose, over every crop.
func _summarise() -> void:
	var groups: Dictionary = {}
	for entry in _report["farmer"]:
		var playing: String = entry["playing"]
		var key := playing.get_slice("_", 0)
		if not groups.has(key):
			groups[key] = {"count": 0, "height_min": 9999, "height_max": 0, "low_min": 9999, "low_max": -9999}
		var g: Dictionary = groups[key]
		g["count"] += 1
		g["height_min"] = mini(g["height_min"], int(entry["body_height_px"]))
		g["height_max"] = maxi(g["height_max"], int(entry["body_height_px"]))
		g["low_min"] = mini(g["low_min"], int(entry["lowest_pixel_vs_contact_px"]))
		g["low_max"] = maxi(g["low_max"], int(entry["lowest_pixel_vs_contact_px"]))
	_report["summary"] = groups
	var keys := groups.keys()
	keys.sort()
	for key in keys:
		print("  %-8s %s" % [key, str(groups[key])])
