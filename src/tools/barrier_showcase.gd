extends SceneTree

## Real placement, adjacency, damage, ground layering and one-shot mine cues.
## Isolated fixed fixtures use the production renderer and never write saves.
var _world: WorldView
var _view: PlayerView
var _lighting: Lighting
var _state: Dictionary
var _checks := 0
var _failed := 0
var _capture := false
var _folder := "res://implementation/shots/sprites/0014/barriers/"
var _caption: Label
var _centers: Array[Vector2i] = []


func _initialize() -> void:
	call_deferred("_run")


func expect(ok: bool, message: String) -> void:
	_checks += 1
	if not ok:
		_failed += 1
		push_error(message)


func _run() -> void:
	CaptureSize.configure(root)
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
	_caption.position = Vector2(8, 2)
	_caption.add_theme_font_override("font", load("res://assets/fonts/harvest_hud.fnt"))
	_caption.add_theme_font_size_override("font_size", 8)
	overlay.add_child(_caption)
	for family in [&"wall", &"fence"]:
		for light in 3:
			_state = _blank(light)
			_centers.clear()
			for mask in range(16):
				var cell := Vector2i(3 + (mask % 4) * 6, 3 + (mask / 4) * 4)
				_centers.append(cell)
				_place(family, cell)
				for bit in 4:
					if mask & (1 << bit):
						_place(family, cell + WorldView.EDGE_NEIGHBOURS[bit])
			await _settle()
			_check_joins(family, "")
			await _shoot("%s_%d_whole" % [family, light], "%s - all 16 occupied neighbor masks" % family)
			for cell in Farm.cells_with(_state, family):
				Farm.damage(_state, cell, int(Farm.occupant(_state, cell)["hp"]) / 2 + 1)
			await _settle()
			_check_joins(family, "_hurt")
			await _shoot("%s_%d_hurt" % [family, light], "Broken construction - same joins, unchanged legal cells")
			var lost := Farm.cells_with(_state, family)
			for cell in lost:
				Farm.damage(_state, cell, 9999)
			await _settle()
			expect(_world._wreck_sprites.size() == lost.size(), "Every actual destroyed barrier leaves ground art")
			for cell in lost:
				var sprite: Sprite2D = _world._wreck_sprites.get(Grid.index(cell))
				expect(sprite != null and sprite.texture.resource_path == WorldView.BUILDING_DIR + str(family) + "_wreck.png", "Matching low source-owned ruin")
				expect(Farm.walkable(_state, cell) and Farm.rubble_at(_state, cell) == family, "Ruins never block the formerly occupied cell")
				if sprite != null:
					expect(sprite.position == Vector2(cell) * 16 + Vector2(8, 16), "Ruin stays on the destroyed logical cell")
			await _shoot("%s_%d_wreck" % [family, light], "Real destruction / passable rubble / correct cells")
			var version := int(_state["grid_version"])
			Farm.clear_rubble(_state)
			await _settle()
			expect(_world._wreck_sprites.is_empty() and int(_state["grid_version"]) == version, "Morning clears ground ruins without changing occupancy")
	await _masks_and_borders()
	await _ghosts_and_route()
	await _barricades()
	await _mine_states()
	await _mine_exclusions()
	await _mine_batch()
	await _depth()
	await _mixed_perimeter()
	print("BARRIER SHOWCASE: %d checks, %d failed" % [_checks, _failed])
	quit(1 if _failed > 0 else 0)


func _blank(light: int = 0) -> Dictionary:
	var state := State.create(3014)
	var terrain: PackedByteArray = state["terrain"]
	terrain.fill(Farm.Terrain.GRASS)
	state["terrain"] = terrain
	(state["occupants"] as Dictionary).clear()
	(state["plots"] as Dictionary).clear()
	(state["entities"] as Dictionary).clear()
	state["tick"] = GameData.DUSK_AT_TICK / 2 if light == 0 else GameData.DAY_TICKS - 1
	state["day_tick"] = state["tick"]
	state["phase"] = Phases.DAY if light < 2 else Phases.NIGHT
	state["house_cell"] = [24, 8]
	for resource in GameData.RESOURCES:
		(state["held"] as Dictionary)[resource] = 10000
	var player: Dictionary = state["player"]
	player["pos"] = [440 * Player.SUBTILE / 16, 244 * Player.SUBTILE / 16]
	player["facing"] = Player.SOUTH
	player["action"] = {}
	# Every season's barriers go down here (task 0234).
	SuiteKit.open_every_season(state)
	return state


func _contact(at: Vector2i) -> void:
	if _state.is_empty():
		return
	var player: Dictionary = _state["player"]
	player["pos"] = [at.x * Player.SUBTILE / 16, (at.y - 8) * Player.SUBTILE / 16]
	player["facing"] = Player.SOUTH
	player["action"] = {}


func _place(family: StringName, cell: Vector2i) -> void:
	var phase := int(_state["phase"])
	_state["phase"] = Phases.PREPARATION  # where defences go up since task 0119
	expect(Building.place(_state, family, cell), "Actual paid placement: %s at %s" % [family, cell])
	_state["phase"] = phase
	expect(Building.size_of(family) == Vector2i.ONE, "One-cell gameplay footprint")


func _settle() -> void:
	var before := var_to_bytes(_state)
	_world.show_state(_state)
	_view.show_state(_state)
	_lighting.show_state(_state)
	_lighting.queue_redraw()
	_world.skip_transition()
	_world._process(0.0)
	_world._light_for_phase(5.0)
	_world.look_at_cell(Vector2i(15, 8))
	await process_frame
	await process_frame
	_view._process(0.0)
	expect(var_to_bytes(_state) == before, "Render, joins, lamps and actor placement preserve every state/save byte")
	expect(_world._light.color.is_equal_approx(_world.light_target()) and not _world.is_transitioning(), "Every fixture renders its actual settled day/dusk/night light")


func _sprite(cell: Vector2i) -> Sprite2D:
	for node in _world._sprites:
		if node is Sprite2D and (node.get_meta("logical_cells", []) as Array).has(Grid.index(cell)):
			return node
	return null


func _check_joins(family: StringName, suffix: String) -> void:
	for mask in range(16):
		var cell := _centers[mask]
		var sprite := _sprite(cell)
		expect(WorldView.barrier_mask(_state, cell) == mask, "Actual neighbors select every N/E/S/W mask")
		var path := WorldView.BUILDING_DIR + str(family) + ("_join_%d" % mask if mask else "") + suffix + ".png"
		expect(sprite != null and sprite.texture.resource_path == path, "No missing-art fallback: " + path)
		if sprite != null:
			expect(sprite.position == Vector2(cell) * 16 + Vector2(8, 16) and sprite.offset == Vector2(-8, -28), "Common source contact / integer placement")
			expect(sprite.texture.get_size() == Vector2(16, 32), "Every joined state retains its source canvas")
		expect(not Farm.walkable(_state, cell), "The whole/hurt cell keeps original collision")


func _masks_and_borders() -> void:
	# All four neighbor kinds (empty / same / mixed / unrelated) in all four
	# directions, independently of the fixture scene's fixed mask examples.
	_state = _blank()
	var center := Vector2i(12, 8)
	for value in 256:
		(_state["occupants"] as Dictionary).clear()
		var expected := 0
		for bit in 4:
			var choice := (value >> (bit * 2)) & 3
			if choice > 0:
				var id: StringName = [&"", &"wall", &"fence", &"barricade"][choice]
				Farm.place(_state, center + WorldView.EDGE_NEIGHBOURS[bit], {"id": id, "hp": 100})
			if choice in [1, 2]:
				expected |= 1 << bit
		var before := var_to_bytes(_state)
		expect(WorldView.barrier_mask(_state, center) == expected, "Empty/mixed/unrelated neighbor connectivity")
		expect(var_to_bytes(_state) == before, "Mask query cannot change occupancy/pathing/save")
	var corners: Array[Vector2i] = [Vector2i.ZERO, Vector2i(Grid.WIDTH - 1, 0), Vector2i(0, Grid.HEIGHT - 1), Vector2i(Grid.WIDTH - 1, Grid.HEIGHT - 1)]
	for i in corners.size():
		var at := corners[i]
		(_state["occupants"] as Dictionary).clear()
		for delta in WorldView.EDGE_NEIGHBOURS:
			if Grid.in_bounds(at + delta):
				Farm.place(_state, at + delta, {"id": &"wall", "hp": 120})
		expect(WorldView.barrier_mask(_state, at) == [6, 12, 3, 9][i], "Map corners never connect to out-of-bounds cells")


func _ghosts_and_route() -> void:
	_state = _blank()
	var cell := Vector2i(12, 10)
	_place(&"wall", cell + Vector2i.LEFT)
	_place(&"fence", cell + Vector2i.UP)
	await _settle()
	for family in [&"wall", &"fence", &"barricade", &"mine"]:
		var before := var_to_bytes(_state)
		# A defence is previewed where it can go up: the build step (task 0119).
		var phase := int(_state["phase"])
		_state["phase"] = Phases.PREPARATION
		var legal := Building.can_place(_state, family, cell)
		_state["phase"] = phase
		_world.show_ghost(cell, family, legal)
		expect(_world.ghost_footprint() == Vector2i.ONE and _world.ghost_cell() == cell and _world.ghost_is_ok(), "Actual one-cell legal preview")
		var name := str(family) + ("_join_9" if family in [&"wall", &"fence"] else "")
		expect(_world._ghost.texture.resource_path == WorldView.BUILDING_DIR + name + ".png", "Ghost uses real adjacent materials and matching source canvas")
		expect(_world._ghost.position == Vector2(cell) * 16 + Vector2(8, 16), "Ghost contact matches placed construction")
		expect(var_to_bytes(_state) == before, "Preview consumes no kits/resources or occupancy")
		await _shoot("ghost_" + str(family), "Source preview uses the existing legal one-cell footprint")
	_world.hide_ghost()
	# Neighbors removed while the pointer stays in place must refresh the art.
	Farm.remove(_state, cell + Vector2i.UP)
	_world.show_ghost(cell, &"wall", true)
	expect(_world._ghost.texture.resource_path.ends_with("wall_join_8.png"), "Same-cell ghost immediately updates changed adjacency")
	_world.hide_ghost()
	for y in 3:
		for x in 3:
			Farm.place(_state, Vector2i(23 + x, 7 + y), {"id": &"house"})
	for y in range(2, 16):
		if y != 9:
			_place(&"wall", Vector2i(16, y))
	var before := var_to_bytes(_state)
	var route := Pathing.route_if_blocked(_state, Vector2i(16, 9), Vector2i(5, 9))
	_world.show_route(route)
	_world.show_ghost(Vector2i(16, 9), &"wall", Building.can_place(_state, &"wall", Vector2i(16, 9)))
	expect(not route.is_empty() and _world.previewed_route() == route, "The existing core route preview stays visible")
	expect(var_to_bytes(_state) == before, "Route preview restores every temporarily queried occupancy/save field")
	await _settle()
	await _shoot("route_preview", "Existing predicted route / connected ghost / unchanged pathing")
	_world.hide_ghost()
	_world.clear_route()


func _barricades() -> void:
	for light in 3:
		_state = _blank(light)
		var cells: Array[Vector2i] = [Vector2i(9, 8), Vector2i(13, 8), Vector2i(17, 8)]
		for at in cells:
			_place(&"barricade", at)
		# Put down in the build step, a barricade's clock starts with the
		# waves (task 0132): wound here as `Phases.begin_night` winds it.
		Building.start_lifetimes(_state)
		Farm.damage(_state, cells[1], 12)
		Farm.damage(_state, cells[2], 9999)
		await _settle()
		expect(_sprite(cells[0]).texture.resource_path.ends_with("barricade.png"), "Whole barricade")
		expect(_sprite(cells[1]).texture.resource_path.ends_with("barricade_hurt.png"), "Snapped brace barricade")
		expect((_world._wreck_sprites[Grid.index(cells[2])]["texture"] as Texture2D).resource_path.ends_with("barricade_wreck.png"), "Collapsed barricade on real destruction")
		await _shoot("barricade_%d" % light, "Whole / snapped / collapsed timber, same one-cell mechanics")
		var expires := int(Farm.occupant(_state, cells[0])["expires"])
		_state["tick"] = expires
		Building.tick(_state)
		await _settle()
		expect(Farm.occupant(_state, cells[0]).is_empty() and _sprite(cells[0]) == null, "Temporary barricade expires by the original core rule")
	_state = State.copy(_state)
	await _settle()
	expect(not _world._wreck_sprites.is_empty(), "Loaded barrier ruins need no invented saved view fields")
	await _shoot("loaded_ruins", "Reloaded actual barrier ruins / unchanged save data")


func _mine_states() -> void:
	_state = _blank(2)
	var cell := Vector2i(14, 9)
	_place(&"mine", cell)
	await _settle()
	var mine := _sprite(cell)
	expect(mine.get_parent() == _world._ground_traps, "Mine is ground art below every actor")
	await _shoot("mine_armed", "Armed pressure disc / restrained red mechanical plate")
	_world.before_tick(_state)
	var enemy := Entities.spawn(_state, &"walker", cell)
	Traps.tick(_state)
	var after := var_to_bytes(_state)
	_world.after_tick(_state)
	expect(var_to_bytes(_state) == after and not Entities.alive(_state, enemy), "Actual trap damage/removal, observers never keep killed enemies alive")
	expect(Traps.sprung(_state) == 1 and Traps.at(_state, cell).is_empty(), "Actual core consumption is observed once")
	await _settle()
	var idx := Grid.index(cell)
	expect(_world._mine_cues.size() == 1 and _world._mine_before.is_empty(), "One bounded source cue, snapshot released")
	var sprite: Sprite2D = _world._mine_cues[idx]["sprite"]
	expect(sprite.texture.resource_path.ends_with("mine_triggered.png") and sprite.position == Vector2(cell) * 16 + Vector2(8, 16), "Trigger stays at the consumed mine's original contact")
	await _shoot("mine_triggered", "Actual consumed trap / source-owned one-shot trigger")
	_world._process_mine_cues(WorldView.MINE_TRIGGER_SECONDS + 0.01)
	expect(sprite.texture.resource_path.ends_with("mine_spent.png"), "The short trigger changes once to its spent casing")
	await _shoot("mine_spent", "Short spent casing cue / no new occupant or collision")
	_world._process_mine_cues(1.0)
	expect(_world._mine_cues.is_empty() and Traps.at(_state, cell).is_empty(), "One-shot cue expires without returning to armed or retaining core entities")
	await _shoot("mine_expired", "Expired mine cue leaves the original open cell")


func _mine_exclusions() -> void:
	_state = _blank(2)
	var cells: Array[Vector2i] = [Vector2i(10, 8), Vector2i(14, 8), Vector2i(18, 8)]
	for at in cells:
		_place(&"mine", at)
	await _settle()
	# Sell and damage a different mine in the same observation as a real trigger.
	_state["intent"]["build_sell"] = true
	_state["intent"]["build_cell"] = [cells[0].x, cells[0].y]
	_world.before_tick(_state)
	Building.sell(_state, cells[0])
	Farm.damage(_state, cells[1], 9999)
	Traps.detonate_for_test(_state, cells[2])
	var before := var_to_bytes(_state)
	_world.after_tick(_state)
	expect(_world._mine_cues.keys() == [Grid.index(cells[2])] and var_to_bytes(_state) == before, "Sale/damage cannot invent a triggered mine when a different mine goes off")
	await _settle()
	expect((_world._wreck_sprites[Grid.index(cells[1])]["texture"] as Texture2D).resource_path.ends_with("mine_spent.png"), "Destroyed one-HP mine uses spent art at actual core rubble")
	await _shoot("mine_exclusions", "Sold / destroyed / detonated are distinct observed outcomes")
	_place(&"mine", cells[2])
	await _settle()
	expect(_world._mine_cues.is_empty(), "Rearming the same cell immediately removes the old cue")
	_state = State.copy(_state)
	await _settle()
	expect(_world._mine_cues.is_empty(), "Loaded saves never invent past transient mine events")
	_world.before_tick(_state)
	Building.sell(_state, cells[2])
	_world.after_tick(_state)
	expect(_world._mine_cues.is_empty(), "Removal without a new sprung count has no burst")
	# Real rubble can remain under a rebuilt mine until morning. A trigger on
	# that cell must still be visible; old receipts must not suppress it.
	_state["intent"]["build_sell"] = false
	_state["tick"] = int(_state["tick"]) + 1
	_place(&"mine", cells[1])
	await _settle()
	_world.before_tick(_state)
	Traps.detonate_for_test(_state, cells[1])
	_world.after_tick(_state)
	expect(_world._mine_cues.has(Grid.index(cells[1])), "Rearmed mine triggers despite old ground rubble / old destruction receipt")
	_world._process_mine_cues(1.0)
	# Upgrade takes precedence over sell in the unchanged Building.tick.
	_place(&"mine", cells[2])
	await _settle()
	_state["intent"]["build_upgrade"] = true
	_state["intent"]["build_sell"] = true
	_state["intent"]["build_cell"] = [cells[2].x, cells[2].y]
	_world.before_tick(_state)
	Building.tick(_state)
	Traps.detonate_for_test(_state, cells[2])
	_world.after_tick(_state)
	expect(_world._mine_cues.has(Grid.index(cells[2])), "Ignored sell intent cannot suppress a real trigger when upgrade took precedence")
	_state["phase"] = Phases.DAY
	_world._process_mine_cues(0.0)
	expect(_world._mine_cues.is_empty(), "Morning clears transient mine cues immediately")
	# An unknown external removal has no core receipt. If another mine really
	# triggered during the observation, the view must not guess which vanished.
	_state = _blank(2)
	for at in cells.slice(0, 2):
		_place(&"mine", at)
	await _settle()
	_world.before_tick(_state)
	Farm.remove(_state, cells[0])
	Traps.detonate_for_test(_state, cells[1])
	_world.after_tick(_state)
	expect(Traps.sprung(_state) == 1 and _world._mine_cues.is_empty(), "Ambiguous external removal cannot invent a trigger location")
	# Same-count replacement must refresh the occupancy-version cache.
	_state = _blank(2)
	_place(&"mine", cells[0])
	await _settle()
	_world.before_tick(_state)
	_world.after_tick(_state)
	Building.sell(_state, cells[0])
	_place(&"mine", cells[1])
	_world.before_tick(_state)
	Traps.detonate_for_test(_state, cells[1])
	_world.after_tick(_state)
	expect(_world._mine_cues.keys() == [Grid.index(cells[1])], "Same-count replacement observes the new mine cell")
	# More real triggers than the presentation budget retain at most six
	# one-shot drawings; older cues are freed rather than leaking sprites.
	_state = _blank(2)
	await _settle()
	for x in range(8, 15):
		var at := Vector2i(x, 8)
		_place(&"mine", at)
		_world.before_tick(_state)
		Traps.detonate_for_test(_state, at)
		_world.after_tick(_state)
	expect(Traps.sprung(_state) == 7 and _world._mine_cues.size() == WorldView.MINE_CUE_CAP, "Seven actual triggers respect the bounded presentation budget")
	_world._process_mine_cues(1.0)
	expect(_world._mine_cues.is_empty(), "Every bounded cue expires after overflow")


func _mine_batch() -> void:
	_state = _blank(2)
	for at in [Vector2i(11, 8), Vector2i(15, 8)]:
		_place(&"mine", at)
		Entities.spawn(_state, &"tank", at)
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
	expect(driver.last_ticks == 4 and var_to_bytes(_state) == var_to_bytes(control), "Four real observed driver ticks equal the unobserved core run byte for byte")
	expect(Traps.sprung(_state) == 2 and _world._mine_cues.size() == 2, "Both real mine arrivals are retained before a 4x rendered frame")
	driver.queue_free()
	await _settle()
	await _shoot("mine_4x", "Both real 4x triggers observed / identical simulation bytes")
	_world._process_mine_cues(1.0)
	expect(_world._mine_cues.is_empty(), "Multiple mine cues stay bounded and expire")
	# Nearby mature crops remain original walkable ground art; mine placement
	# is allowed by the existing rules even on a plot.
	_state = _blank()
	var cell := Vector2i(14, 9)
	_state["plots"][Grid.index(cell)] = {"crop": &"corn", "growth": Farming.days_to_grow(&"corn"), "watered": true}
	_place(&"mine", cell)
	var walker := Entities.spawn(_state, &"walker", cell)
	Entities.get_one(_state, walker)["pos"][0] += Player.SUBTILE / 3
	_contact(Vector2i(260, 164))
	await _settle()
	expect(_sprite(cell).get_parent() == _world._ground_traps and _world._ground_traps.get_index() > _world._plots.get_index(), "Mechanical plate reads above crop ground while remaining below actors")
	if _capture:
		await RenderingServer.frame_post_draw
		var covered := root.get_texture().get_image()
		var mine := _sprite(cell)
		mine.hide()
		await process_frame
		await RenderingServer.frame_post_draw
		var open := root.get_texture().get_image()
		var actor: Sprite2D = _world._actor_sprites[0]
		var actor_pixels := actor.texture.get_image()
		var origin := root.get_canvas_transform() * (actor.global_position + actor.offset)
		var over_boots := 0
		var overlap := 0
		var mine_origin := root.get_canvas_transform() * (mine.global_position + mine.offset)
		var mine_pixels := mine.texture.get_image()
		for y in actor_pixels.get_height():
			for x in actor_pixels.get_width():
				if actor_pixels.get_pixel(x, y).a <= 0:
					continue
				var p := Vector2i(origin) + Vector2i(x, y)
				var local := p - Vector2i(mine_origin)
				if Rect2i(Vector2i.ZERO, mine_pixels.get_size()).has_point(local) and mine_pixels.get_pixelv(local).a > 0:
					overlap += 1
				if Rect2i(Vector2i.ZERO, covered.get_size()).has_point(p) and covered.get_pixelv(p) != open.get_pixelv(p):
					over_boots += 1
		var visible_plate := 0
		for y in mine_pixels.get_height():
			for x in mine_pixels.get_width():
				var p := Vector2i(mine_origin) + Vector2i(x, y)
				if mine_pixels.get_pixel(x, y).a > 0 and Rect2i(Vector2i.ZERO, covered.get_size()).has_point(p) and covered.get_pixelv(p) != open.get_pixelv(p):
					visible_plate += 1
		expect(overlap >= 4 and over_boots == 0, "Actual mine/actor overlap never paints over zombie boots")
		expect(visible_plate >= 3, "Actual plate remains visible beside the actor and mature corn: " + str(visible_plate))
		mine.show()
	await _shoot("mine_crop_actor", "Existing crop/mine coexistence / low plate / boots above ground art")


func _depth() -> void:
	_state = _blank()
	var cell := Vector2i(14, 10)
	_place(&"wall", cell)
	_place(&"wall", cell + Vector2i.LEFT)
	_place(&"wall", cell + Vector2i.RIGHT)
	for behind in [true, false]:
		_contact(Vector2i(232, 164 if behind else 184))
		await _settle()
		var prop := _sprite(cell)
		expect(_view.position.y < prop.position.y if behind else _view.position.y > prop.position.y, "Farmer depth agrees with the occupied wall cell")
		if _capture:
			await RenderingServer.frame_post_draw
			var covered := root.get_texture().get_image()
			for at in [cell, cell + Vector2i.LEFT, cell + Vector2i.RIGHT]:
				_sprite(at).hide()
			await process_frame
			await RenderingServer.frame_post_draw
			var open := root.get_texture().get_image()
			var body: Sprite2D = _view.get_node("Body")
			var pixels := body.texture.get_image()
			var origin := root.get_canvas_transform() * (body.global_position + body.offset)
			var changed := 0
			for y in pixels.get_height():
				for x in pixels.get_width():
					var p := Vector2i(origin) + Vector2i(x, y)
					if pixels.get_pixel(x, y).a > 0 and Rect2i(Vector2i.ZERO, covered.get_size()).has_point(p) and covered.get_pixelv(p) != open.get_pixelv(p):
						changed += 1
			expect(changed > 3 if behind else changed == 0, "Rendered wall covers farmer only behind its ground contact: " + str(changed))
			for at in [cell, cell + Vector2i.LEFT, cell + Vector2i.RIGHT]:
				_sprite(at).show()
		await _shoot("depth_behind" if behind else "depth_front", "Farmer behind/front of the real connected wall")


func _mixed_perimeter() -> void:
	_state = _blank(2)
	for y in 3:
		for x in 3:
			Farm.place(_state, Vector2i(18 + x, 7 + y), {"id": &"house"})
	for x in range(10, 25):
		_place(&"wall" if x < 18 else &"fence", Vector2i(x, 5))
		if x != 16:
			_place(&"fence", Vector2i(x, 12))
	for y in range(6, 12):
		_place(&"wall", Vector2i(10, y))
		_place(&"fence", Vector2i(24, y))
	_place(&"gun_tower", Vector2i(12, 7))
	_place(&"flame_tower", Vector2i(22, 7))
	_place(&"mortar", Vector2i(12, 10))
	_place(&"auto_crossbow", Vector2i(22, 10))
	_place(&"barricade", Vector2i(16, 12))
	_place(&"mine", Vector2i(16, 14))
	Farm.damage(_state, Vector2i(14, 5), 80)
	Farm.damage(_state, Vector2i(20, 12), 9999)
	Entities.spawn(_state, &"walker", Vector2i(26, 9))
	Entities.spawn(_state, &"walker", Vector2i(16, 15))
	_contact(Vector2i(280, 188))
	await _settle()
	await _shoot("mixed_perimeter_night", "Connected stone/timber perimeter / real gap / farmhouse / towers / mine")


func _shoot(name: String, caption: String) -> void:
	_caption.text = caption
	if not _capture:
		return
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	expect(image != null and image.get_size() == Vector2i(480, 270), "Actual native game renderer")
	if image != null:
		expect(image.save_png(_folder + name + ".png") == OK, "Saved actual viewport: " + name)
