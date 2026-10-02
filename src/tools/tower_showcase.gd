extends SceneTree

## Actual WorldView/Building/Towers fixtures, without player saves or Main menus.
class LampProbe extends Lighting:
	var outlets: Array[Vector2] = []
	func _glow_at(at: Vector2, _radius: float, _colour: Color, _strength: float) -> void:
		outlets.append(at)

const FAMILIES: Array[StringName] = [&"gun_tower", &"flame_tower", &"mortar", &"auto_crossbow"]
var _world: WorldView
var _view: PlayerView
var _lighting: Lighting
var _state: Dictionary
var _cells: Array[Vector2i] = []
var _checks := 0
var _failed := 0
var _capture := false
var _folder := "res://implementation/shots/sprites/0013/towers/"
var _caption: Label


func _initialize() -> void:
	call_deferred("_run")


func expect(ok: bool, message: String) -> void:
	_checks += 1
	if not ok:
		_failed += 1
		push_error(message)


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	_capture = not args.has("--check")
	for arg in args:
		if arg.begins_with("--out="):
			_folder = "res://" + arg.substr(6).trim_suffix("/") + "/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_folder))
	var relight := Relight.new()
	relight.name = "Relight"
	relight.layer = 1
	root.add_child(relight)
	_world = load("res://scenes/World.tscn").instantiate()
	root.add_child(_world)
	_world.set_process(false)
	await process_frame
	_view = _world.get_node("Occupants/PlayerView")
	_view.set_process(false)
	var lamps := CanvasLayer.new()
	lamps.layer = 2
	root.add_child(lamps)
	_lighting = Lighting.new()
	lamps.add_child(_lighting)
	_lighting.set_process(false)
	_lighting.set_quality(Lighting.STEADY)
	var overlay := CanvasLayer.new()
	overlay.layer = 3
	root.add_child(overlay)
	_caption = Label.new()
	_caption.position = Vector2(8, 8)
	_caption.add_theme_font_override("font", load("res://assets/fonts/harvest_hud.fnt"))
	_caption.add_theme_font_size_override("font_size", 8)
	overlay.add_child(_caption)
	for material_light in 3:
		_fixture(material_light)
		await _settle()
		_check_standing("")
		await _shoot("levels_%d_whole" % material_light, "Gun / flame / mortar / crossbow - rows L1 / L2 / L3")
		for cell in _cells:
			var on := Farm.occupant(_state, cell)
			Farm.damage(_state, cell, int(on["hp"]) / 2 + 1)
		await _settle()
		_check_standing("_hurt")
		await _shoot("levels_%d_hurt" % material_light, "Authored structural damage at all 12 levels")
		for cell in _cells:
			var on := Farm.occupant(_state, cell)
			on["reload"] = WorldView.levelled_stat(on, "reload_ticks")
		await _settle()
		_check_standing("_fire")
		await _shoot("levels_%d_fire" % material_light, "Weapon action takes priority over wear - measured outlets")
		for cell in _cells:
			Farm.damage(_state, cell, 9999)
		await _settle()
		_check_wrecks(true)
		await _shoot("levels_%d_wreck" % material_light, "Real destruction remembers the level - ground rubble is passable")
		var version := int(_state["grid_version"])
		Farm.clear_rubble(_state)
		await _settle()
		expect(int(_state["grid_version"]) == version, "Morning rubble cleanup does not change the core occupancy version")
		expect(_world._wreck_sprites.is_empty() and _world._tower_history.is_empty(), "Morning frees every destroyed tower sprite and remembered level")
	await _outlets()
	await _ghosts()
	await _launches()
	await _depth()
	await _loaded_rubble()
	await _mixed_night()
	print("TOWER SHOWCASE: %d checks, %d failed" % [_checks, _failed])
	quit(1 if _failed > 0 else 0)


func _blank(material_light: int = 0) -> Dictionary:
	var state := State.create(3013)
	var terrain: PackedByteArray = state["terrain"]
	terrain.fill(Farm.Terrain.GRASS)
	state["terrain"] = terrain
	(state["occupants"] as Dictionary).clear()
	(state["plots"] as Dictionary).clear()
	state["tech_owned"] = [&"true sights", &"long barrels", &"oiled works"]
	for res in GameData.RESOURCES:
		(state["held"] as Dictionary)[res] = 10000
	state["tick"] = GameData.DUSK_AT_TICK / 2 if material_light == 0 else GameData.DAY_TICKS - 1
	state["day_tick"] = state["tick"]
	state["phase"] = Phases.DAY if material_light < 2 else Phases.NIGHT
	state["house_cell"] = [20, 7]
	_set_contact(state["player"], Vector2i(296, 246))
	return state


func _place(family: StringName, level: int, cell: Vector2i) -> void:
	var phase := int(_state["phase"])
	_state["phase"] = Phases.DAY
	expect(Building.place(_state, family, cell), "Real one-cell tower placement: " + str(family))
	for step in level - 1:
		expect(Building.upgrade(_state, cell), "Real authored level upgrade: %s L%d" % [family, step + 2])
	_state["phase"] = phase
	expect(Building.size_of(family) == Vector2i.ONE and Building.level_at(_state, cell) == level, "Art never changes logical tower footprint or level")


func _fixture(material_light: int = 0) -> void:
	_state = _blank(material_light)
	_cells.clear()
	for col in FAMILIES.size():
		for row in 3:
			var cell := Vector2i(10 + col * 6, 5 + row * 4)
			_place(FAMILIES[col], row + 1, cell)
			_cells.append(cell)


func _set_contact(actor: Dictionary, contact: Vector2i) -> void:
	actor["pos"] = [contact.x * Player.SUBTILE / 16, (contact.y - 8) * Player.SUBTILE / 16]
	actor["facing"] = Player.SOUTH
	actor["action"] = {}


func _settle() -> void:
	var before := var_to_bytes(_state)
	_world.show_state(_state)
	_view.show_state(_state)
	_lighting.show_state(_state)
	_lighting.queue_redraw()
	_world._process(5.0)
	_world.look_at_cell(Vector2i(20, 9))
	await process_frame
	await process_frame
	_view._process(0.0)
	expect(var_to_bytes(_state) == before, "Tower drawing/lights/actors preserve every state/save byte")


func _sprite(cell: Vector2i) -> Sprite2D:
	for node in _world._sprites:
		if node is Sprite2D and (node.get_meta("logical_cells", []) as Array).has(Grid.index(cell)):
			return node
	return null


func _check_standing(suffix: String) -> void:
	for cell in _cells:
		var on := Farm.occupant(_state, cell)
		var sprite := _sprite(cell)
		expect(sprite != null, "Every family/level has one visible world sprite")
		if sprite == null:
			continue
		var path := WorldView.BUILDING_DIR + str(WorldView.tower_name(on, suffix)) + ".png"
		expect(sprite.texture.resource_path == path, "Actual world wear/fire resolver selects " + path)
		expect(sprite.texture.get_size() == Vector2(32, 48) and sprite.offset == Vector2(-16, -44), "Every level/state has the common canvas and planted pivot")
		expect(sprite.position == Vector2(cell) * 16 + Vector2(8, 16), "Tower sorts at the unchanged one-cell ground contact")
		expect(sprite.get_child_count() == 0, "Authored upgrades add no legacy colored level pips")
		var fire_path := WorldView.BUILDING_DIR + str(WorldView.tower_name(on, "_fire")) + ".png"
		var metadata: Dictionary = RasterArt.FRAMES[fire_path]
		var points := WorldView.tower_muzzles(on, cell)
		for i in points.size():
			expect(points[i] == sprite.position + sprite.offset + Vector2(metadata["muzzles"][i]), "Muzzle origin follows the source-owned weapon outlet")


func _check_wrecks(remembered: bool) -> void:
	expect(_world._wreck_sprites.size() == _cells.size(), "Every real destroyed tower has one bounded rubble sprite")
	for cell in _cells:
		var idx := Grid.index(cell)
		var sprite: Sprite2D = _world._wreck_sprites.get(idx)
		expect(Farm.occupant(_state, cell).is_empty() and Farm.rubble_at(_state, cell) != &"", "Rubble remains outside logical occupancy")
		if sprite == null:
			expect(false, "Missing wreck at " + str(cell))
			continue
		var level := (cell.y - 5) / 4 + 1 if remembered else 1
		var on := {"id": Farm.rubble_at(_state, cell), "level": level}
		expect(sprite.texture.resource_path == WorldView.BUILDING_DIR + str(WorldView.tower_name(on, "_wreck")) + ".png", "Destruction selects the actual remembered level")
		expect(sprite.position == Vector2(cell) * 16 + Vector2(8, 16) and sprite.offset == Vector2(-16, -44), "Collapsed art keeps its source canvas/contact")


func _outlets() -> void:
	_fixture(2)
	for cell in _cells:
		var on := Farm.occupant(_state, cell)
		on["reload"] = WorldView.levelled_stat(on, "reload_ticks")
	await _settle()
	var before := var_to_bytes(_state)
	var expected: Array[Vector2] = []
	for cell in _cells:
		expected.append_array(WorldView.tower_muzzles(Farm.occupant(_state, cell), cell))
	var probe := LampProbe.new()
	root.add_child(probe)
	probe.set_process(false)
	probe.show_state(_state)
	probe.set_quality(Lighting.STEADY)
	probe._draw()
	expect(probe.outlets.size() == expected.size(), "Actual lighting visits exactly 13 measured weapon outlets")
	for point in expected:
		expect(probe.outlets.count(point) == 1, "Actual lamp uses each measured outlet once, including both L3 gun barrels")
	probe.queue_free()
	var sparks := Particles.new()
	root.add_child(sparks)
	sparks.set_process(false)
	sparks.set_cap(420)
	sparks.set_density(1.0)
	sparks.set_motion(true)
	var particle_state := _state.duplicate(true)
	for cell in _cells:
		Farm.occupant(particle_state,cell)["reload"] = 0
	sparks.show_state(particle_state)
	sparks._smoke_due = 100.0
	sparks.before_tick(particle_state)
	particle_state["tick"] = int(particle_state["tick"])+1
	for cell in _cells:
		var on := Farm.occupant(particle_state,cell)
		on["reload"] = WorldView.levelled_stat(on,"reload_ticks")
	var contacts := var_to_bytes(particle_state)
	sparks.after_tick(particle_state)
	sparks._forms.advance(0.0,sparks)
	expect(sparks._forms.records.size() == expected.size(), "Exactly one localized authored form per measured barrel, without duplicate buildings")
	for point in expected:
		var count := 0
		for sprite in sparks._forms.sprites:
			if sprite.visible and sprite.position == point:
				count += 1
				expect(sprite.offset == -Vector2(RasterArt.FRAMES[sprite.texture.resource_path]["pivot"]),"Actual launch form uses its source-owned origin")
		expect(count == 1, "Real raster particle pool launches on the reviewed muzzle: " + str(point))
	expect(var_to_bytes(particle_state)==contacts,"Fixed-tick muzzle observations cannot alter their core/save bytes")
	sparks._process(0.0)
	sparks.after_tick(particle_state)
	expect(sparks._forms.records.size()==expected.size(),"Repeated rendered/after-tick observations cannot duplicate launches")
	expect(var_to_bytes(_state) == before, "Particles and emission probes cannot alter gameplay or RNG")
	await _shoot("outlets_night", "All 13 weapon outlets / real glow and authored launch forms")
	sparks.queue_free()
	# Replacing a tower with a different cell at the same occupant count must
	# invalidate the gun cache, unlike its former count-only key.
	var old_cell := _cells[0]
	var new_cell := Vector2i(11, 16)
	var cached := Particles.new()
	cached.set_cap(0)
	cached.show_state(_state)
	var original := cached._gun_cells().duplicate()
	Farm.remove(_state, old_cell)
	_place(&"gun_tower", 1, new_cell)
	var fresh := cached._gun_cells()
	expect(original.size() == fresh.size() and not fresh.has(Grid.index(old_cell)) and fresh.has(Grid.index(new_cell)), "Same-count replacement refreshes particle gun cells by grid version")
	cached.free()


func _ghosts() -> void:
	_fixture()
	_set_contact(_state["player"], Vector2i(296, 218))
	await _settle()
	for family in FAMILIES:
		_world.show_ghost(Vector2i(18, 15), family, true)
		var ghost: Sprite2D = _world.find_child("Ghost", true, false)
		expect(_world.ghost_footprint() == Vector2i.ONE and ghost.position == Vector2(296, 256), "Each tower ghost follows the selected one-cell base")
		expect(ghost.texture.resource_path == WorldView.BUILDING_DIR + str(family) + ".png" and ghost.offset == Vector2(-16, -44), "Ghost uses authored L1 canvas/pivot")
		await _shoot("ghost_" + str(family), "One-cell placement preview: " + str(family))
	_world.hide_ghost()


func _launches() -> void:
	for family in [&"gun_tower", &"mortar"]:
		_state = _blank(2)
		var cell := Vector2i(17, 9)
		_place(family, 3, cell)
		Entities.spawn(_state, &"tank", Vector2i(20, 8))
		Entities.spawn(_state, &"tank", Vector2i(20, 10))
		await _settle()
		var before := var_to_bytes(_state)
		_world.before_tick(_state)
		expect(var_to_bytes(_state) == before, "Launch observer snapshot is read-only")
		Towers.tick(_state)
		var core := var_to_bytes(_state)
		_world.after_tick(_state)
		expect(var_to_bytes(_state) == core, "Launch observer cannot rewrite the real shot")
		var points := WorldView.tower_muzzles(Farm.occupant(_state, cell), cell)
		var shots: Array = _state["projectiles"]
		expect(shots.size() == points.size(), "Real projectile birth uses the authored barrel count")
		for i in shots.size():
			var shot: Dictionary = shots[i]
			expect(shot["pos"] == [cell.x * Player.SUBTILE + Player.SUBTILE / 2, cell.y * Player.SUBTILE + Player.SUBTILE / 2], "Core birth remains at the unchanged logical cell center")
			expect(_world.shot_position(shot) == points[i].floor(), "New visual projectile appears on its own weapon outlet")
		await _settle()
		await _shoot("launch_" + str(family), "Real projectile launch from authored " + str(family) + " muzzle")
		for tick in 90:
			_world.before_tick(_state)
			Towers.tick(_state)
			var observed := var_to_bytes(_state)
			_world.after_tick(_state)
			expect(var_to_bytes(_state) == observed, "Every flight observer preserves projectile and damage bytes")
			expect(_world._shot_origins.size() <= (_state["projectiles"] as Array).size(), "Launch cache stays bounded by live core shots")
			if (_state["projectiles"] as Array).is_empty():
				break
		expect(_world._shot_origins.is_empty(), "Landing prunes all presentation launch records")
	# Real SimDriver runs four ticks before any rendered frame. Observers must
	# capture launches inside that batch, not discover them late in _process.
	_state = _blank(2)
	_place(&"gun_tower", 3, Vector2i(17, 9))
	Entities.spawn(_state, &"tank", Vector2i(20, 8))
	Entities.spawn(_state, &"tank", Vector2i(20, 10))
	await _settle()
	var driver := SimDriver.new()
	root.add_child(driver)
	driver.set_process(false)
	driver.state = _state
	driver.speed = 4
	driver.stepping.connect(_world.before_tick)
	driver.stepped.connect(_world.after_tick)
	var control := State.copy(_state)
	for tick in 4:
		Sim.tick(control)
	driver._process((1.0 / GameData.TICK_HZ + 0.00001) / driver._slowness())
	expect(driver.last_ticks == 4 and int(_state["tick"]) == int(control["tick"]), "Real 4x driver executes exactly four unchanged simulation ticks")
	expect(var_to_bytes(_state) == var_to_bytes(control), "Observed 4x gameplay equals the identical unobserved core run byte for byte")
	expect(_world._shot_origins.size() == (_state["projectiles"] as Array).size() and not _world._shot_origins.is_empty(), "4x observes both L3 launch origins before the first redraw")
	driver.queue_free()
	await _shoot("launch_4x", "Real 4x observer batch - gameplay matches the unobserved run")
	_state = State.copy(_state)
	await _settle()
	expect(_world._shot_origins.is_empty(), "A loaded save has no invented launch history")
	for shot in (_state["projectiles"] as Array):
		var at := Vector2(float(shot["pos"][0]), float(shot["pos"][1])) * 16.0 / Player.SUBTILE
		expect(_world.shot_position(shot) == at.floor(), "Mature loaded projectiles stay at their actual core positions")
	_world.before_tick(_state)
	Towers.tick(_state)
	_world.after_tick(_state)
	expect(_world._shot_origins.is_empty(), "Observer does not mistake existing loaded projectiles for newborns")
	# Non-observed completion (e.g. skip-night) must also release stale records.
	_state = _blank(2)
	_place(&"gun_tower", 1, Vector2i(17, 9))
	Entities.spawn(_state, &"tank", Vector2i(20, 9))
	await _settle()
	_world.before_tick(_state)
	Towers.tick(_state)
	_world.after_tick(_state)
	expect(not _world._shot_origins.is_empty(), "Non-observed cleanup fixture really starts with a remembered launch")
	_state["projectiles"] = []
	var before := var_to_bytes(_state)
	_world._process(0.0)
	expect(_world._shot_origins.is_empty() and var_to_bytes(_state) == before, "Rendering releases stale launch records after non-observed completion without core writes")


func _depth() -> void:
	_state = _blank()
	var cell := Vector2i(18, 10)
	_place(&"gun_tower", 3, cell)
	for behind in [true, false]:
		_set_contact(_state["player"], Vector2i(296, 164 if behind else 184))
		await _settle()
		var prop := _sprite(cell)
		expect(_view.position.y < prop.position.y if behind else _view.position.y > prop.position.y, "Farmer sorts on the correct side of the tower base")
		if _capture:
			await RenderingServer.frame_post_draw
			var covered := root.get_texture().get_image()
			prop.hide()
			await process_frame
			await RenderingServer.frame_post_draw
			var open := root.get_texture().get_image()
			var body: Sprite2D = _view.get_node("Body")
			var pixels := body.texture.get_image()
			var origin := root.get_canvas_transform() * (body.global_position + body.offset)
			var changed := 0
			for y in pixels.get_height():
				for x in pixels.get_width():
					if pixels.get_pixel(x, y).a <= 0.0:
						continue
					var p := Vector2i(origin) + Vector2i(x, y)
					if Rect2i(Vector2i.ZERO, covered.get_size()).has_point(p) and covered.get_pixelv(p) != open.get_pixelv(p):
						changed += 1
			expect(changed > 8 if behind else changed == 0, "Rendered tower covers the farmer only behind its ground contact: " + str(changed))
			prop.show()
		await _shoot("depth_behind" if behind else "depth_front", "Farmer depth and relative scale against L3 gun")


func _loaded_rubble() -> void:
	_fixture(2)
	await _settle()
	for cell in _cells:
		Farm.damage(_state, cell, 9999)
	# Saves retain the family, but do not contain destroyed tower levels.
	_state = State.copy(_state)
	await _settle()
	_check_wrecks(false)
	expect(_world._tower_history.is_empty(), "Loaded rubble cannot invent unsaved destroyed levels")
	await _shoot("loaded_rubble", "Loaded save rubble uses honest family L1 fallback; save format unchanged")
	var at := _cells[0]
	_place(&"gun_tower", 1, at)
	await _settle()
	expect(not _world._wreck_sprites.has(Grid.index(at)), "A new standing tower hides old passable rubble in the same cell")


func _mixed_night() -> void:
	_fixture(2)
	# Farmhouse and actors provide real palette/scale context alongside towers.
	var house := Vector2i(19, 7)
	for y in 3:
		for x in 3:
			Farm.place(_state, house + Vector2i(x, y), {"id": &"house", "anchor": [house.x, house.y]})
	for i in 4:
		Entities.spawn(_state, &"walker", Vector2i(31 + i, 8 + i))
	for i in _cells.size():
		var on := Farm.occupant(_state, _cells[i])
		if i % 3 == 0:
			on["reload"] = WorldView.levelled_stat(on, "reload_ticks")
		elif i % 3 == 1:
			Farm.damage(_state, _cells[i], int(on["hp"]) / 2 + 1)
	_set_contact(_state["player"], Vector2i(330, 220))
	await _settle()
	await _shoot("mixed_night", "Mixed defenses / farmhouse / farmer / enemies under the actual night ramp")
	if _capture:
		_lighting.set_quality(Lighting.OFF)
		await process_frame
		await RenderingServer.frame_post_draw
		var off := root.get_texture().get_image()
		_lighting.set_quality(Lighting.STEADY)
		await process_frame
		await RenderingServer.frame_post_draw
		var lit := root.get_texture().get_image()
		var changed := 0
		for cell in _cells:
			var on := Farm.occupant(_state, cell)
			if not WorldView.just_fired(on):
				continue
			for point in WorldView.tower_muzzles(on, cell):
				var p := Vector2i(root.get_canvas_transform() * point)
				if Rect2i(Vector2i.ZERO, lit.get_size()).has_point(p) and lit.get_pixelv(p).r > off.get_pixelv(p).r + 0.02:
					changed += 1
		expect(changed >= 4, "Rendered night lamps brighten actual measured weapon outlets: " + str(changed))


func _shoot(name: String, caption: String) -> void:
	_caption.text = caption
	if not _capture:
		return
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	expect(image != null and image.get_size() == Vector2i(480, 270), "Capture uses the native game viewport")
	if image != null:
		expect(image.save_png(_folder + name + ".png") == OK, "Capture saved: " + name)
