extends SceneTree

## Deterministic isolated fixtures, never writing player saves.
## Locomotion mode drives unchanged Player.tick; rendering cannot mutate state.
## tools/show_art.py supplies the real renderer and fixed FPS for PNG capture.
var _world: WorldView
var _state: Dictionary
var _checks := 0
var _failed := 0
var _capture := false
var _folder := "res://implementation/shots/sprites/0003/showcase/"
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
	if args.has("--terrain") or args.has("--water"):
		# Use Main's real relighting pipeline for all three material light states.
		var relight := Relight.new()
		relight.name = "Relight"
		relight.layer = 1
		root.add_child(relight)
	_world = load("res://scenes/World.tscn").instantiate()
	root.add_child(_world)
	await process_frame
	var overlay := CanvasLayer.new()
	root.add_child(overlay)
	_caption = Label.new()
	_caption.position = Vector2(8, 8)
	_caption.add_theme_font_override("font", load("res://assets/fonts/harvest_hud.fnt"))
	_caption.add_theme_font_size_override("font_size", 8)
	overlay.add_child(_caption)
	_state = State.create(3003)
	var terrain: PackedByteArray = _state["terrain"]
	terrain.fill(Farm.Terrain.GRASS)
	_state["terrain"] = terrain
	(_state["occupants"] as Dictionary).clear()
	(_state["plots"] as Dictionary).clear()
	_state["tick"] = GameData.DUSK_AT_TICK / 2
	_state["house_cell"] = [21, 7]
	_add_house(Vector2i(20, 6))
	(_state["occupants"] as Dictionary)[Grid.index(Vector2i(12, 9))] = {"id": &"tree"}
	var enemy := Entities.spawn(_state, &"walker", Vector2i(21, 8))
	var player: Dictionary = _state["player"]
	player["facing"] = Player.SOUTH
	player["action"] = {}
	var actor := Entities.get_one(_state, enemy)
	if args.has("--water"):
		await _water_edges()
		print("WATER SHOWCASE: %d checks, %d failed" % [_checks, _failed])
		quit(1 if _failed > 0 else 0)
		return
	if args.has("--terrain"):
		await _terrain_materials()
		print("TERRAIN SHOWCASE: %d checks, %d failed" % [_checks, _failed])
		quit(1 if _failed > 0 else 0)
		return
	if args.has("--reactions"):
		await _reactions()
		print("PLAYER REACTIONS: %d checks, %d failed" % [_checks, _failed])
		quit(1 if _failed > 0 else 0)
		return
	if args.has("--work"):
		await _work_cycles()
		print("PLAYER WORK: %d checks, %d failed" % [_checks, _failed])
		quit(1 if _failed > 0 else 0)
		return
	if args.has("--locomotion"):
		await _locomotion()
		print("PLAYER SHOWCASE: %d checks, %d failed" % [_checks, _failed])
		quit(1 if _failed > 0 else 0)
		return
	# Traverse the overlap in both directions, swapping farmer/enemy subjects.
	for subject in 2:
		for step in 9:
			var dy := -24 + step * 6
			_set_contact(player, Vector2i(200 if subject == 0 else 344, (160 if subject == 0 else 144) + dy))
			_set_contact(actor, Vector2i(344 if subject == 0 else 200, (144 if subject == 0 else 160) + dy))
			await _settle()
			_check_placement()
			await _shoot("occlusion_%d_%02d" % [subject, step], "Farmer / walker behind -> in front; %d" % dy)
	# House ghost and its full logical footprint, plus tall tower preview.
	_world.show_ghost(Vector2i(14, 10), &"house", true)
	await _settle()
	var ghost: Sprite2D = _world.find_child("Ghost", true, false)
	expect(ghost.position == Vector2(248, 208), "House ghost sorts at the 3x3 ground contact")
	expect(ghost.offset == Vector2(-32, -60), "House ghost uses source-owned pivot")
	expect(_world.ghost_footprint() == Vector2i(3, 3), "House preview frame covers its nine cells")
	await _shoot("ghost_house", "House preview: unchanged 3x3 footprint / roof overhang")
	_world.show_ghost(Vector2i(14, 10), &"gun_tower", true)
	await _settle()
	expect(ghost.position == Vector2(232, 176), "Tower ghost stands on the selected cell")
	expect(ghost.offset.y == -ghost.texture.get_height(), "Legacy tower preview bottom agrees with placed tower")
	expect(_world.ghost_footprint() == Vector2i.ONE, "Changing family in the same cell updates the preview frame")
	await _shoot("ghost_tower", "Tower preview: base stays on the selected cell")
	_world.hide_ghost()
	# Real map/camera limits: both horizontal sides and top/bottom roof clips.
	for corner in [Vector2i(0, 0), Vector2i(37, 0), Vector2i(0, 15), Vector2i(37, 15)]:
		(_state["occupants"] as Dictionary).clear()
		_add_house(corner)
		_state["house_cell"] = [corner.x + 1, corner.y + 1]
		_set_contact(player, Vector2i((corner.x + 1) * 16 + 8, mini(corner.y + 4, 17) * 16))
		await _settle()
		_world.look_at_cell(corner)
		await process_frame
		await _shoot("bounds_%d_%d" % [corner.x, corner.y], "Map/camera boundary: one house, 3x3 logical base")
	# Living crop states and all existing tower upgrade/damage/fire states.
	(_state["occupants"] as Dictionary).clear()
	(_state["entities"] as Dictionary).clear()
	var row := 5
	for crop in Farming.seeds():
		var needed := int(GameData.CROPS[crop]["growth_ticks"])
		for stage in 4:
			(_state["plots"] as Dictionary)[Grid.index(Vector2i(9 + stage * 3, row))] = {
				"crop": crop, "growth": stage * needed / 3, "watered": stage % 2 == 0, "soak": 0}
		row += 3
	var column := 21
	for kind in [&"gun_tower", &"flame_tower", &"mortar", &"auto_crossbow"]:
		for level in 3:
			var cell := Vector2i(column, 5 + level * 4)
			(_state["occupants"] as Dictionary)[Grid.index(cell)] = {"id": kind, "level": level + 1,
				"hp": int(GameData.DEFENCES[kind]["hp"]), "reload": 0}
		column += 4
	await _settle()
	_world.look_at_cell(Vector2i(20, 9))
	await _shoot("crop_tower_whole", "Three crop families / stages 0-3; four tower families / levels 1-3")
	for idx in _state["occupants"]:
		(_state["occupants"][idx] as Dictionary)["hp"] = 1
	await _settle()
	await _shoot("crop_tower_hurt", "Same crop stages and tower levels: damaged")
	for idx in _state["occupants"]:
		var on: Dictionary = _state["occupants"][idx]
		on["reload"] = int(GameData.DEFENCES[on["id"]].get("reload_ticks", 10))
	await _settle()
	await _shoot("crop_tower_fire", "Same tower levels: firing / native ground anchors")
	await _contacts()
	print("ART SHOWCASE: %d checks, %d failed" % [_checks, _failed])
	quit(1 if _failed > 0 else 0)


## Uniform repeated materials plus the production weighted grass selector.
## Fixture-only maps; the authoritative FARM_MAP and walkability never change.
func _terrain_materials() -> void:
	var view: PlayerView = _world.get_node("Occupants/PlayerView")
	view.set_process(false)
	_world.set_process(false)
	expect(_world._relight != null, "Terrain fixtures use the same relight shader as Main")
	var names := ["grass", "grass_b", "grass_c", "grass_d", "soil", "path", "floor", "rock", "grass_mixed"]
	var kinds := [Farm.Terrain.GRASS, Farm.Terrain.GRASS, Farm.Terrain.GRASS, Farm.Terrain.GRASS,
		Farm.Terrain.SOIL, Farm.Terrain.PATH, Farm.Terrain.FLOOR, Farm.Terrain.ROCK, Farm.Terrain.GRASS]
	for lighting in 3:
		for material in names.size():
			_state = State.create(7007)
			for key in ["occupants", "plots", "entities", "livestock", "crafting", "produced"]:
				(_state[key] as Dictionary).clear()
			var terrain: PackedByteArray = _state["terrain"]
			terrain.fill(kinds[material])
			_state["terrain"] = terrain
			_state["phase"] = Phases.NIGHT if lighting == 2 else Phases.DAY
			_state["day_tick"] = GameData.DAY_TICKS - 1 if lighting == 1 else GameData.DAY_TICKS / 2
			_state["tick"] = GameData.DUSK_AT_TICK / 2
			_state["player"]["facing"] = Player.SOUTH
			_set_contact(_state["player"], Vector2i(296, 176))
			var enemy := Entities.spawn(_state, &"walker", Vector2i(21, 10))
			_set_contact(Entities.get_one(_state, enemy), Vector2i(344, 176))
			var before := var_to_bytes(_state)
			await _reaction_settle(view)
			_world.look_at_cell(Vector2i(20, 9))
			var tiles: TileMapLayer = _world.get_node("Terrain")
			# Pure grass variants use the same actual atlas cells as production.
			if material < 4:
				for idx in Grid.CELLS:
					tiles.set_cell(Grid.cell(idx), 0, Vector2i(material, WorldView.ROW_GRASS))
			for idx in Grid.CELLS:
				var cell := Grid.cell(idx)
				var wanted := Vector2i(material, WorldView.ROW_GRASS) if material < 4 else WorldView._base_tile(kinds[material], cell)
				expect(tiles.get_cell_atlas_coords(cell) == wanted, "Every fixture cell selects its accepted material/grass variant")
			var source: TileSetAtlasSource = tiles.tile_set.get_source(0)
			expect(source.texture.resource_path == WorldView.TERRAIN_ATLAS, "World draws the committed source-owned atlas")
			expect(source.texture.get_size() == Vector2(256, 80), "Native terrain atlas row shape is unchanged")
			expect(view.position == Vector2(296, 176), "Terrain art cannot move farmer feet")
			expect(view.get_node("Body").offset == Vector2(-24, -44), "Farmer retains the accepted body pivot")
			expect(var_to_bytes(_state) == before, "Material/lighting view changes cannot alter any serialized state")
			await _shoot("material_%s_light%d" % [names[material], lighting], "%s / day-dusk-night %d / native tiles and actors" % [names[material], lighting])
		# The unmodified farm, including paths, rocky ground and the wooden dock.
		_state = State.create(7007)
		var farm_before := var_to_bytes(_state["terrain"])
		_state["phase"] = Phases.NIGHT if lighting == 2 else Phases.DAY
		_state["day_tick"] = GameData.DAY_TICKS - 1 if lighting == 1 else GameData.DAY_TICKS / 2
		var before := var_to_bytes(_state)
		await _reaction_settle(view)
		expect(var_to_bytes(_state["terrain"]) == farm_before and var_to_bytes(_state) == before,
			"Full farm keeps its authoritative terrain, occupants, positions and save fields")
		await _shoot("farm_light%d" % lighting, "Unchanged FARM_MAP / day-dusk-night %d" % lighting)


## Exhaustive cardinal/diagonal masks plus real shader and automatic pond motion.
func _water_fixture(base: int, lighting: int) -> void:
	_state = State.create(8008)
	for key in ["occupants", "plots", "entities", "livestock", "crafting", "produced"]:
		(_state[key] as Dictionary).clear()
	_state["terrain"].fill(base)
	_state["phase"] = Phases.NIGHT if lighting == 2 else Phases.DAY
	_state["day_tick"] = GameData.DAY_TICKS - 1 if lighting == 1 else GameData.DAY_TICKS / 2
	_state["tick"] = GameData.DUSK_AT_TICK / 2
	_set_contact(_state["player"], Vector2i(24, 24))


func _water_cards(diagonal: bool) -> void:
	var bytes: PackedByteArray = _state["terrain"]
	for mask in 16:
		var center := Vector2i(10 + (mask % 4) * 6, 4 + (mask / 4) * 3)
		for bit in 4:
			var step: Vector2i = WorldView.CORNER_NEIGHBOURS[bit] if diagonal else WorldView.EDGE_NEIGHBOURS[bit]
			if mask & (1 << bit):
				bytes[Grid.index(center + step)] = Farm.Terrain.GRASS
	_state["terrain"] = bytes


func _water_phase(phase: int, preview: TileSet) -> void:
	_world._terrain.tile_set = preview
	for idx in Grid.CELLS:
		if int(_state["terrain"][idx]) == Farm.Terrain.WATER:
			_world._terrain.set_cell(Grid.cell(idx), 0, Vector2i(phase, WorldView.ROW_WATER))


func _water_check_cards(diagonal: bool, base: int) -> void:
	var bytes: PackedByteArray = _state["terrain"]
	for mask in 16:
		var center := Vector2i(10 + (mask % 4) * 6, 4 + (mask / 4) * 3)
		if diagonal:
			expect(WorldView._corner_mask(bytes, center, base) == mask, "All sixteen diagonal corner combinations select exact cap bits")
			expect(_world._edges.get_cell_source_id(center) == -1, "Diagonal-only join does not invent a cardinal edge")
			for bit in 4:
				var layer: TileMapLayer = _world._corners[bit]
				var wanted := Vector2i((WorldView.CORNER_SHORE_START if base == Farm.Terrain.WATER else WorldView.CORNER_EDGE_START) + bit, 0)
				expect(layer.get_cell_atlas_coords(center) == wanted if mask & (1 << bit) else layer.get_cell_source_id(center) == -1,
					"Actual corner layers render exactly the requested diagonal caps")
		else:
			var wanted := Vector2i(mask, WorldView.ROW_SHORE if base == Farm.Terrain.WATER else WorldView.ROW_EDGE)
			expect(_world._edges.get_cell_atlas_coords(center) == wanted if mask else _world._edges.get_cell_source_id(center) == -1,
				"Actual edge layer shows cardinal mask zero through fifteen")
			# All diagonals remain base material, so none may draw a cap.
			expect(WorldView._corner_mask(bytes, center, base) == 0, "Cardinal card has no false diagonal cap")


func _water_compound() -> void:
	# Contiguous concave/convex turns, narrow channels, a T join and diagonal
	# contacts, alongside a wooden jetty. Fixture coordinates only.
	var rows := [
		"ggggggggggwwwwwwwwww",
		"gggwwwwgggwwggwwwwww",
		"ggwwggwgggwwggwwwwww",
		"ggwgggggggwwwwwwwwww",
		"ggwwggwgggwwwwwwwggw",
		"gggwwwwgggwwwwwwggww",
		"ggggggggggwwwwwggwww",
		"ggggggffffwwwwwwwwww",
		"ggggggffffwwwwwwwwww",
		"ggggggffffwwwwwwwwww",
	]
	var bytes: PackedByteArray = _state["terrain"]
	for y in rows.size():
		for x in rows[y].length():
			var material := Farm.Terrain.WATER
			if rows[y][x] == "g":
				material = Farm.Terrain.GRASS
			elif rows[y][x] == "f":
				material = Farm.Terrain.FLOOR
			bytes[Grid.index(Vector2i(10 + x, 4 + y))] = material
	_state["terrain"] = bytes


func _water_edges() -> void:
	var view: PlayerView = _world.get_node("Occupants/PlayerView")
	view.set_process(false)
	_world.set_process(false)
	view.visible = false
	expect(_world._relight != null, "Water uses Main's actual day/dusk/night shader")
	var production := _world._terrain.tile_set
	var source: TileSetAtlasSource = production.get_source(0)
	var origin := Vector2i(0, WorldView.ROW_WATER)
	expect(source.get_tile_animation_frames_count(origin) == 3, "Production pond uses the three accepted phases")
	for frame in 3:
		expect(is_equal_approx(source.get_tile_animation_frame_duration(origin, frame), 0.55), "Production water timing remains 550ms per phase")
	for corner in 4:
		expect(source.has_tile(Vector2i(WorldView.CORNER_EDGE_START + corner, 0)) and source.has_tile(Vector2i(WorldView.CORNER_SHORE_START + corner, 0)),
			"Production atlas registers every source-owned grass and bank cap")
	# A private fixture copy freezes exact atlas phases for comparable captures.
	# Production retains normal automatic animation; edges stay static.
	var preview: TileSet = production.duplicate(true)
	var frozen: TileSetAtlasSource = preview.get_source(0)
	frozen.set_tile_animation_frames_count(origin, 1)
	frozen.create_tile(Vector2i(1, WorldView.ROW_WATER))
	frozen.create_tile(Vector2i(2, WorldView.ROW_WATER))
	# Exhaust every 4-cardinal x 4-diagonal case for both material families.
	for base in [Farm.Terrain.SOIL, Farm.Terrain.WATER]:
		for cardinal in 16:
			for diagonal in 16:
				_water_fixture(base, 0)
				var cell := Vector2i(20, 9)
				for bit in 4:
					if cardinal & (1 << bit):
						_state["terrain"][Grid.index(cell + WorldView.EDGE_NEIGHBOURS[bit])] = Farm.Terrain.GRASS
					if diagonal & (1 << bit):
						_state["terrain"][Grid.index(cell + WorldView.CORNER_NEIGHBOURS[bit])] = Farm.Terrain.GRASS
				var before := var_to_bytes(_state)
				var expected := 0
				for bit in 4:
					if diagonal & (1 << bit) and not (cardinal & WorldView.CORNER_CARDINALS[bit]):
						expected |= 1 << bit
				expect(WorldView._corner_mask(_state["terrain"], cell, base) == expected, "Cardinal joins suppress only their adjoining diagonal caps")
				expect(var_to_bytes(_state) == before, "Corner selection cannot mutate any state/save field")
		_water_fixture(base, 0)
		for cell in [Vector2i(0, 0), Vector2i(39, 0), Vector2i(0, 17), Vector2i(39, 17)]:
			expect(WorldView._corner_mask(_state["terrain"], cell, base) == 0, "Map boundaries do not invent caps outside the unchanged grid")
	for lighting in 3:
		for base in [Farm.Terrain.SOIL, Farm.Terrain.PATH, Farm.Terrain.FLOOR, Farm.Terrain.ROCK]:
			_water_fixture(base, lighting)
			_water_cards(false)
			var before := var_to_bytes(_state)
			await _reaction_settle(view)
			_world.look_at_cell(Vector2i(20, 9))
			_water_check_cards(false, base)
			await _shoot("edges_material%d_light%d" % [base, lighting], "N1 E2 S4 W8 / masks 0-15 row-major / material%d / light%d" % [base, lighting])
			expect(var_to_bytes(_state) == before, "Land transition fixture cannot change simulation or save fields")
		_water_fixture(Farm.Terrain.WATER, lighting)
		_water_cards(false)
		var before := var_to_bytes(_state)
		await _reaction_settle(view)
		_world.look_at_cell(Vector2i(20, 9))
		_water_check_cards(false, Farm.Terrain.WATER)
		var edges_before := _world._edges.get_used_cells()
		for frame in 3:
			_water_phase(frame, preview)
			await _shoot("shore_masks_light%d_phase%d" % [lighting, frame], "Banks / masks0-15 row-major / phase%d / light%d" % [frame, lighting])
			expect(_world._edges.get_used_cells() == edges_before and var_to_bytes(_state) == before, "Water phase cannot move shore cells or mutate simulation")
		for base in [Farm.Terrain.SOIL, Farm.Terrain.WATER]:
			_water_fixture(base, lighting)
			_water_cards(true)
			before = var_to_bytes(_state)
			await _reaction_settle(view)
			_world.look_at_cell(Vector2i(20, 9))
			if base == Farm.Terrain.WATER:
				_water_phase(0, preview)
			_water_check_cards(true, base)
			await _shoot("corners_material%d_light%d" % [base, lighting], "NW1 NE2 SE4 SW8 / diagonal masks0-15 / light%d" % lighting)
			expect(var_to_bytes(_state) == before, "Diagonal cap rendering cannot change serialized state")
		_water_fixture(Farm.Terrain.WATER, lighting)
		_water_compound()
		before = var_to_bytes(_state)
		await _reaction_settle(view)
		_world.look_at_cell(Vector2i(20, 9))
		var edges := _world._edges.get_used_cells()
		var caps := []
		for layer in _world._corners:
			caps.append(layer.get_used_cells())
		for frame in 3:
			_water_phase(frame, preview)
			await _shoot("compound_light%d_phase%d" % [lighting, frame], "Joined convex/concave banks, channels, diagonal contacts, timber jetty / phase%d / light%d" % [frame, lighting])
			expect(_world._edges.get_used_cells() == edges and var_to_bytes(_state) == before, "Compound banks stay fixed while the water alone moves")
			for bit in 4:
				expect(_world._corners[bit].get_used_cells() == caps[bit], "Compound corner pixels do not swim between water frames")
		_world._terrain.tile_set = production
		_state = State.create(8008)
		_state["phase"] = Phases.NIGHT if lighting == 2 else Phases.DAY
		_state["day_tick"] = GameData.DAY_TICKS - 1 if lighting == 1 else GameData.DAY_TICKS / 2
		before = var_to_bytes(_state)
		view.visible = true
		await _reaction_settle(view)
		await _shoot("farm_light%d" % lighting, "Unchanged FARM_MAP / actual jetty / light%d" % lighting)
		expect(var_to_bytes(_state) == before, "Water rendering preserves the real farm's full serialized state")
		view.visible = false
	await _water_automatic(view, production)
	view.visible = true


func _water_automatic(view: PlayerView, production: TileSet) -> void:
	_world._terrain.tile_set = production
	_water_fixture(Farm.Terrain.WATER, 0)
	var before := var_to_bytes(_state)
	await _reaction_settle(view)
	_world.look_at_cell(Vector2i(20, 9))
	expect(_world._terrain.tile_set == production, "Automatic playback restores untouched production TileSet")
	if not _capture:
		return
	_caption.text = "Actual automatic water loop / three550ms phases / stationary camera and state"
	var seen := {}
	var trace := []
	var previous := -1
	var until := Time.get_ticks_msec() + 3800
	while Time.get_ticks_msec() < until:
		await process_frame
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		var point: Vector2 = _world._terrain.get_global_transform_with_canvas() * Vector2(20 * 16, 9 * 16)
		var patch := image.get_region(Rect2i(Vector2i(point), Vector2i(16,16)))
		var signature := hash(patch.get_data())
		if signature == previous:
			continue
		previous = signature
		seen[signature] = true
		trace.append(signature)
		if trace.size() <= 6:
			expect(image.save_png(_folder + "automatic_loop_%02d.png" % (trace.size()-1)) == OK, "Actual animated viewport phase saved")
	expect(seen.size() == 3 and trace.size() >= 6, "Actual renderer shows three distinct pond phases through two loops")
	if trace.size() >= 6:
		expect(trace[0] == trace[3] and trace[1] == trace[4] and trace[2] == trace[5], "Real automatic water phase order closes without a direction jump")
	expect(var_to_bytes(_state) == before, "Automatic pond motion cannot modify simulation/save fields")
	var file := FileAccess.open(_folder + "automatic-loop.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"unique_rendered_phases":seen.size(),"phase_trace":trace,"seconds":3.8,"serialized_state_unchanged":var_to_bytes(_state)==before}, "\t"))


func _add_house(corner: Vector2i) -> void:
	for y in 3:
		for x in 3:
			(_state["occupants"] as Dictionary)[Grid.index(corner + Vector2i(x, y))] = {"id": &"house"}


## The actual PlayerView clock/flip/frame binding, plus core-resolved diagonal facing.
func _locomotion() -> void:
	(_state["entities"] as Dictionary).clear()
	var view: PlayerView = _world.get_node("Occupants/PlayerView")
	view.set_process(false)
	var body: Sprite2D = view.get_node("Body")
	var player: Dictionary = _state["player"]
	for facing in [Player.SOUTH, Player.WEST, Player.NORTH, Player.EAST]:
		for moving in [false, true]:
			_set_contact(player, Vector2i(248, 208))
			var step: Vector2i = Player.FACING_STEPS[facing]
			_state["intent"]["move"] = [step.x, step.y]
			Player.tick(_state)
			expect(Player.facing(_state) == facing, "Core movement resolves the cardinal facing")
			if not moving:
				_state["intent"]["move"] = [0, 0]
			var pose := PlayerArt.pose(facing, moving, &"")
			var count := int(pose["frames"])
			var each := float(pose["seconds"])
			var expected_name: StringName = StringName("%s_%s" % [
				"walk" if moving else "idle", PlayerArt.FACINGS[facing][0]])
			expect(pose["name"] == expected_name and count == (4 if moving else 3),
				"Each facing selects its complete authored idle/walk family")
			expect(PlayerFrames.SECONDS.has(expected_name), "Timing comes from the accepted strip")
			await _settle()
			var fixed_contact := ArtPlacement.contact(player["pos"])
			for phase in count * 2:
				if moving and phase > 0:
					Player.tick(_state)
				var before := State.hash_of(_state)
				view._process(0.0 if phase == 0 else each)
				expect(State.hash_of(_state) == before, "Drawing the player never changes core state")
				expect(view.playing() == expected_name, "No locomotion family silently falls back to idle")
				expect(view.flipped() == (facing == Player.EAST), "Only east mirrors the accepted west")
				expect(body.texture != null and body.texture.resource_path ==
					PlayerArt.texture_path(expected_name, phase % count),
					"Actual view clock selects each authored frame, including loop wrap")
				expect(body.offset == Vector2(-24, -44), "A turn or mirror cannot move the foot pivot")
				expect(view.position == ArtPlacement.contact(player["pos"]),
					"Visible ground origin agrees with unchanged core position")
				if not moving:
					expect(view.position == fixed_contact, "Idle feet stay planted across both loops")
				var metadata: Dictionary = RasterArt.FRAMES.get(body.texture.resource_path, {})
				expect(metadata.get("canvas") == Vector2i(48, 48)
					and metadata.get("pivot") == Vector2i(24, 44), "Every frame uses accepted source geometry")
				if phase < count:
					await _shoot("%s_facing%d_%02d" % ["walk" if moving else "idle", facing, phase],
						"%s / facing %d / authored frame %d" % [expected_name, facing, phase])
	# Vertical wins a diagonal tie in core; release retains the resulting facing.
	for move in [Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)]:
		_set_contact(player, Vector2i(248, 208))
		_state["intent"]["move"] = [move.x, move.y]
		var previous := Player.position(_state)
		Player.tick(_state)
		var expected := Player.NORTH if move.y < 0 else Player.SOUTH
		var after := Player.position(_state)
		expect(signi(after.x - previous.x) == move.x and signi(after.y - previous.y) == move.y,
			"Diagonal movement advances both axes using actual core rules")
		view._process(0.13)
		expect(Player.facing(_state) == expected and view.playing() ==
			StringName("walk_%s" % PlayerArt.FACINGS[expected][0]), "Diagonal direction binds to core-facing art")
		await _shoot("diagonal_%d_%d" % [move.x, move.y], "Diagonal %s: core facing, shared feet" % str(move))
		_state["intent"]["move"] = [0, 0]
		view._process(0.0)
		expect(view.playing() == StringName("idle_%s" % PlayerArt.FACINGS[expected][0]),
			"Releasing diagonal input retains facing and enters authored idle")
	# Direction changes without recreating the view, including east -> west.
	for facing in [Player.EAST, Player.WEST, Player.NORTH, Player.SOUTH]:
		var step: Vector2i = Player.FACING_STEPS[facing]
		_state["intent"]["move"] = [step.x, step.y]
		Player.tick(_state)
		view._process(0.13)
		expect(view.playing() == StringName("walk_%s" % PlayerArt.FACINGS[facing][0])
			and view.flipped() == (facing == Player.EAST), "Immediate direction changes show the correct art")
		expect(view.position == ArtPlacement.contact(player["pos"]) and body.offset == Vector2(-24, -44),
			"Turning never adds an artificial canvas-width displacement")
		await _shoot("turn_%d" % facing, "Direction change / facing %d / no contact jump" % facing)


func _set_contact(who: Dictionary, pixels: Vector2i) -> void:
	var scale := Player.SUBTILE / GameData.TILE_SIZE
	who["pos"] = [pixels.x * scale, (pixels.y - GameData.TILE_SIZE / 2) * scale]


## Real interaction fixtures for every existing verb, with production carry.
func _work_fixture(verb: StringName, facing: int) -> Vector2i:
	_state = State.create(5005)
	_state["tick"] = GameData.DUSK_AT_TICK / 2
	for key in ["occupants", "plots", "entities", "livestock", "crafting", "produced"]:
		(_state[key] as Dictionary).clear()
	Resources.gain(_state, {GameData.MONEY: 1000, GameData.WOOD: 100,
		GameData.STONE: 100, GameData.IRON: 100, GameData.FOOD: 100})
	var at := Vector2i(14, 9)
	var idx := Grid.index(at)
	var terrain: PackedByteArray = _state["terrain"]
	terrain.fill(Farm.Terrain.GRASS)
	var on: Dictionary = _state["occupants"]
	var crop: StringName = Farming.seeds()[0]
	match verb:
		&"chop":
			on[idx] = {"id": &"tree"}
		&"mine":
			on[idx] = {"id": &"rock"}
		&"till", &"plant", &"water", &"harvest":
			terrain[idx] = Farm.Terrain.SOIL
			if verb != &"till":
				var plot := Farming.EMPTY_PLOT.duplicate()
				if verb != &"plant":
					plot["crop"] = crop
				if verb == &"harvest":
					plot["growth"] = int(GameData.CROPS[crop]["growth_ticks"])
				_state["plots"][idx] = plot
			_state["selected_seed"] = crop
			_state["water_can"] = GameData.WATER_CAN_CAPACITY
		&"fish", &"reel":
			terrain[idx] = Farm.Terrain.WATER
		&"collect":
			on[idx] = {"id": &"cow"}
			_state["livestock"][idx] = {"ready": 1, "left": 100}
		&"craft", &"carry":
			on[idx] = {"id": &"workshop", "hp": int(GameData.BUILDINGS[&"workshop"]["hp"])}
		&"trade":
			on[idx] = {"id": &"shop"}
		&"repair":
			on[idx] = {"id": &"fence", "hp": int(GameData.DEFENCES[&"fence"]["hp"]) - 10}
	_state["terrain"] = terrain
	var here: Vector2i = at - Player.FACING_STEPS[facing]
	_state["player"]["pos"] = [here.x * Player.SUBTILE + Player.SUBTILE / 2,
		here.y * Player.SUBTILE + Player.SUBTILE / 2]
	_state["player"]["facing"] = facing
	if verb == &"reel":
		Fishing.begin(_state, at)
		_state["fishing"]["stage"] = Fishing.BITING
		_state["fishing"]["left"] = 100
	var view: PlayerView = _world.get_node("Occupants/PlayerView")
	_world.show_state(_state)
	view.show_state(_state)
	return at


func _work_tick(view: PlayerView, whole_sim: bool = false) -> void:
	var before := var_to_bytes(_state)
	view.before_tick(_state)
	expect(var_to_bytes(_state) == before, "Pre-tick work observer cannot change any state/save field")
	if whole_sim:
		Sim.tick(_state)
	else:
		Player.tick(_state)
	before = var_to_bytes(_state)
	view.after_tick(_state)
	expect(var_to_bytes(_state) == before, "Post-tick work observer cannot change any state/save field")


func _work_frame(view: PlayerView, verb: StringName, frame: int, facing: int, delta: float) -> void:
	var before := var_to_bytes(_state)
	view._process(delta)
	var body: Sprite2D = view.get_node("Body")
	expect(var_to_bytes(_state) == before, "Work rendering leaves complete isolated state unchanged")
	expect(view.playing() == verb, "Actual PlayerView plays its own %s work strip" % verb)
	expect(body.texture != null and body.texture.resource_path == PlayerArt.texture_path(verb, frame),
		"Actual work completion clock selects %s authored frame %d" % [verb, frame])
	expect(view.flipped() == (facing == Player.EAST), "Work east mirrors west, with consistent handedness")
	expect(body.offset == Vector2(-24, -44) and body.texture.get_size() == Vector2(48, 48),
		"Tools share the fixed player canvas and feet")
	expect(view.position == ArtPlacement.contact(_state["player"]["pos"]),
		"Work never shifts the logical ground contact")


func _work_cycles() -> void:
	var view: PlayerView = _world.get_node("Occupants/PlayerView")
	view.set_process(false)
	var verbs := PlayerArt.known_verbs()
	expect(verbs == GameData.sorted_names(Interact.DEFAULT_TICKS.keys()), "Every core verb has a work binding")
	for facing in [Player.WEST, Player.EAST]:
		for verb in verbs:
			var at := _work_fixture(verb, facing)
			expect(Interact.verb_at(_state, at) == verb, "Real target offers %s" % verb)
			expect(PlayerFrames.COUNT[verb] == 4, "Each verb has four authored frames without aliases")
			for side in [Player.SOUTH, Player.NORTH]:
				expect(PlayerArt.pose(side, false, verb)["name"] == verb,
					"North/south work intentionally uses reviewed side-on art")
			var total := Interact.ticks_for(_state, at, verb)
			var instant := [&"water", &"reel", &"trade"].has(verb)
			_state["intent"]["interact"] = true
			_work_tick(view)
			await _settle()
			if not instant:
				expect(Player.is_busy(_state), "Timed verb enters the existing core action")
				_work_frame(view, verb, 0, facing, 0.0)
				await _shoot("work_%s_facing%d_frame0" % [verb, facing], "%s / anticipation / %d ticks" % [verb, total])
				for _i in total - 1:
					_work_tick(view)
				_work_frame(view, verb, 1, facing, 0.0)
			else:
				expect(not Player.is_busy(_state), "One-tick/instant verb finishes without a retained core action")
				_work_frame(view, verb, 1, facing, 0.0)
			await _shoot("work_%s_facing%d_frame1" % [verb, facing], "%s / contact on core completion" % verb)
			var each := 0.09 if instant else minf(0.09, float(total) / GameData.TICK_HZ / 4.0)
			for frame in [2, 3]:
				_work_frame(view, verb, frame, facing, each)
				await _shoot("work_%s_facing%d_frame%d" % [verb, facing, frame], "%s / cosmetic follow-through or recovery" % verb)
			if instant:
				_work_frame(view, verb, 0, facing, each)
				await _shoot("work_%s_facing%d_frame0" % [verb, facing], "%s / returned ready pose" % verb)
			# Cancel consumes the pending return as well as an active repeated job.
			_state["intent"]["cancel"] = true
			_work_tick(view)
			view._process(0.0)
			expect(String(view.playing()).begins_with("idle_"), "%s cancel never leaves a tool stuck" % verb)
			_state["intent"]["move"] = [1, 0]
			_work_tick(view)
			view._process(0.0)
			expect(view.playing() == &"walk_west" and view.flipped(), "%s returns immediately to core-resolved walking" % verb)
			# Interrupt before the timed payload, not only after a finished cycle.
			if not instant:
				for walk_away in [false, true]:
					_work_fixture(verb, facing)
					_state["intent"]["interact"] = true
					_work_tick(view)
					view._process(0.0)
					if walk_away:
						_state["intent"]["move"] = [1, 0]
					else:
						_state["intent"]["cancel"] = true
					_work_tick(view)
					view._process(0.09)
					expect(not Player.is_busy(_state), "%s mid-work interruption cancels the real core job" % verb)
					expect(String(view.playing()).begins_with("walk_" if walk_away else "idle_"),
						"Mid-work interruption immediately removes the tool pose")
					_state["intent"]["move"] = [0, 0]
					for _i in total + 2:
						_work_tick(view)
					view._process(1.0)
					expect(String(view.playing()).begins_with("idle_"), "Cancelled work cannot reappear from a delayed cue")
		# A delivery actually run by Crafting.tick triggers the independent carry strip.
		var station := _work_fixture(&"carry", facing)
		expect(Crafting.start_at(_state, station), "Carry fixture starts a payable real station job")
		var job := Crafting.job(_state, station)
		job["left"] = 1
		_work_tick(view, true)
		expect(not Crafting.produced_at(_state, station).is_empty(), "Core production delivers before carrying is shown")
		await _settle()
		for frame in 4:
			_work_frame(view, &"carry", frame, facing, 0.0 if frame == 0 else 0.09)
			await _shoot("work_carry_facing%d_frame%d" % [facing, frame], "Nearby completed production / cosmetic carry %d" % frame)
		view._process(0.09001)
		expect(String(view.playing()).begins_with("idle_"), "Carrying expires without adding a core action")
	# Catch-up ticks use the same Sim.tick sequence and expose short events.
	for verb in [&"water", &"reel", &"trade"]:
		_work_fixture(verb, Player.WEST)
		_state["intent"]["interact"] = true
		var expected := _state.duplicate(true)
		Sim.advance(expected, 4)
		var driver := SimDriver.new()
		driver.state = _state
		driver.speed = 4
		driver.stepping.connect(view.before_tick)
		driver.stepped.connect(view.after_tick)
		driver._process(1.01 / GameData.TICK_HZ / driver._slowness())
		expect(driver.last_ticks == 4 and var_to_bytes(_state) == var_to_bytes(expected),
			"4x work observers preserve the exact Sim.advance state and tick count")
		_work_frame(view, verb, 1, Player.WEST, 0.0)
		driver.free()
	# Repeating three-tick repair must show all phases at normal rendering speed.
	var repair_at := _work_fixture(&"repair", Player.WEST)
	_state["intent"]["interact"] = true
	var seen := {}
	for video_frame in 60:
		if video_frame % 2 == 0:
			_work_tick(view)
		view._process(1.0 / 60.0)
		var body: Sprite2D = view.get_node("Body")
		if view.playing() == &"repair":
			seen[body.texture.resource_path] = true
	expect(seen.size() == 4, "Fast repeated repair visibly uses all four frames at 60FPS")
	expect(int(Farm.occupant(_state, repair_at)["hp"]) == int(GameData.DEFENCES[&"fence"]["hp"]),
		"Animated repeated repair still restores exactly the unchanged core HP")
	# Repair remains available at night; other work does not persist through dusk.
	_work_fixture(&"repair", Player.WEST)
	_state["phase"] = Phases.NIGHT
	_state["intent"]["interact"] = true
	for _i in GameData.REPAIR_TICKS_PER_HP:
		_work_tick(view)
	_work_frame(view, &"repair", 1, Player.WEST, 0.0)
	_work_fixture(&"chop", Player.WEST)
	_state["intent"]["interact"] = true
	_work_tick(view)
	_state["phase"] = Phases.PREPARATION
	_work_tick(view)
	view._process(0.0)
	expect(String(view.playing()).begins_with("idle_"), "Dusk ends daylight work without leaving a tool")


## Existing reaction rules and actual PlayerView, including viewport limits.
func _reaction_fixture(phase: int = Phases.DAY, late_day: bool = false) -> void:
	_state = State.create(6006)
	for key in ["occupants", "plots", "entities", "livestock", "crafting", "produced"]:
		(_state[key] as Dictionary).clear()
	var terrain: PackedByteArray = _state["terrain"]
	terrain.fill(Farm.Terrain.GRASS)
	_state["terrain"] = terrain
	_state["phase"] = phase
	_state["tick"] = GameData.DUSK_AT_TICK / 2
	_state["day_tick"] = GameData.DAY_TICKS - 1 if late_day else GameData.DAY_TICKS / 2
	_state["house_cell"] = [21, 7]
	_add_house(Vector2i(20, 6))
	_state["occupants"][Grid.index(Vector2i(12, 9))] = {"id": &"tree"}
	Entities.spawn(_state, &"walker", Vector2i(20, 11))
	_set_contact(_state["player"], Vector2i(296, 160))


func _reaction_settle(view: PlayerView) -> void:
	var before := var_to_bytes(_state)
	_world.show_state(_state)
	view.show_state(_state)
	_world._process(5.0)
	await process_frame
	await process_frame
	view._process(0.0)
	expect(var_to_bytes(_state) == before, "Reaction world/view rendering cannot mutate any state/save field")


func _reaction_check(view: PlayerView, kind: StringName) -> void:
	var before := var_to_bytes(_state)
	view._process(0.2)
	var body: Sprite2D = view.get_node("Body")
	var bubble: Sprite2D = view.get_node("ReactionBubble")
	var shadow: Sprite2D = view.get_node("Shadow")
	var name := StringName("react_%s" % kind)
	expect(var_to_bytes(_state) == before, "Held reaction cannot update state or its lifetime")
	expect(view.playing() == name and not view.flipped(), "All reactions keep their south pose without mirroring")
	expect(body.texture != null and body.texture.resource_path == PlayerArt.texture_path(name, 0),
		"Each existing reaction uses its own source-owned frame")
	expect(body.offset == Vector2(-24, -44) and body.texture.get_size() == Vector2(48, 48),
		"Reaction body preserves the common canvas and planted feet")
	expect(view.position == ArtPlacement.contact(_state["player"]["pos"]), "Bubble clamping never moves the farmer")
	var metadata: Dictionary = RasterArt.FRAMES[body.texture.resource_path]
	expect(bubble.visible and bubble.texture == body.texture and bubble.region_rect == Rect2(metadata["bubble"]),
		"One separate glyph draws the exact source-owned crop")
	expect(body.material is ShaderMaterial and (body.material as ShaderMaterial).get_shader_parameter("bubble_box")
		== Vector4(bubble.region_rect.position.x, bubble.region_rect.position.y,
			bubble.region_rect.size.x, bubble.region_rect.size.y), "Body masks only its duplicate source glyph")
	var canvas_transform := bubble.get_global_transform_with_canvas()
	var first := canvas_transform * Vector2.ZERO
	var last := canvas_transform * bubble.region_rect.size
	var safe := view.get_viewport_rect().grow(-1.99)
	expect(safe.has_point(first) and safe.has_point(last), "Entire bubble stays inside viewport with a two-pixel margin")
	expect(shadow.texture.resource_path == PlayerView.SHADOW and shadow.texture.get_size() == Vector2(20, 8)
		and shadow.position == Vector2(0, -1) and is_equal_approx(shadow.modulate.a, PlayerView.SHADOW_ALPHA),
		"Single shared shadow retains contact and view-owned transparency")
	expect(view.get_children().filter(func(child): return child.name == "Shadow").size() == 1,
		"Reaction never adds a second shadow")


func _reactions() -> void:
	var view: PlayerView = _world.get_node("Occupants/PlayerView")
	view.set_process(false)
	_world.set_process(false)
	# Each symbol under day/dusk/night; all initial facings select south art.
	for lighting in 3:
		for kind in Reactions.KINDS:
			for facing in (range(4) if lighting == 0 else [Player.SOUTH]):
				_reaction_fixture(Phases.NIGHT if lighting == 2 else Phases.DAY, lighting == 1)
				_state["player"]["facing"] = facing
				Reactions.show(_state, kind)
				await _reaction_settle(view)
				_reaction_check(view, kind)
				await _shoot("reaction_%s_light%d_facing%d" % [kind, lighting, facing],
					"%s / day-dusk-night %d / idle facing %d" % [kind, lighting, facing])
	# Actual crop-ready event, rather than a view inventing a note.
	_reaction_fixture()
	var cell := Vector2i(17, 9)
	var crop: StringName = Farming.seeds()[0]
	_state["terrain"][Grid.index(cell)] = Farm.Terrain.SOIL
	var plot := Farming.EMPTY_PLOT.duplicate()
	plot["crop"] = crop
	plot["growth"] = int(GameData.CROPS[crop]["growth_ticks"]) - 1
	_state["plots"][Grid.index(cell)] = plot
	Farming.tick(_state)
	Reactions.tick(_state)
	expect(Reactions.now(_state) == &"note", "Actual nearby crop completion selects the existing note")
	await _reaction_settle(view)
	_reaction_check(view, &"note")
	await _shoot("event_crop_ready", "Actual crop_ready -> note; stable feet and shadow")
	# Actual fishing wait -> bite, using the existing core timer and selection.
	_reaction_fixture()
	var water := Vector2i(19, 9)
	_state["terrain"][Grid.index(water)] = Farm.Terrain.WATER
	expect(Fishing.begin(_state, water), "Existing fishing cast begins in isolated pond")
	_state["fishing"]["left"] = 1
	Fishing.tick(_state, Player.cell(_state))
	Reactions.tick(_state)
	expect(Fishing.is_biting(_state) and Reactions.now(_state) == &"bang", "Actual bite selects the existing bang")
	await _reaction_settle(view)
	_reaction_check(view, &"bang")
	await _shoot("event_fishing_bite", "Actual fishing bite -> bang, only after work ends")
	# Existing night transition and damage/destruction priority.
	_reaction_fixture()
	expect(Phases.begin_preparation(_state) and Phases.begin_night(_state), "Existing phase transitions begin night")
	Reactions.tick(_state)
	expect(Reactions.now(_state) == &"bang", "Night boundary selects the existing bang")
	await _reaction_settle(view)
	_reaction_check(view, &"bang")
	await _shoot("event_night_began", "Actual night_began -> bang under night lighting")
	var fence := Vector2i(17, 9)
	_state["occupants"][Grid.index(fence)] = {"id": &"fence", "hp": 1}
	_state["tick"] = int(_state["tick"]) + 1
	# The event tick must not precede the reader's existing seen watermark.
	expect(Farm.damage(_state, fence, 1) == 1, "Actual damage destroys the isolated fence")
	Reactions.tick(_state)
	expect(Reactions.now(_state) == &"question", "Destruction reaction outranks the night bang")
	await _reaction_settle(view)
	_reaction_check(view, &"question")
	await _shoot("event_structure_lost", "Actual fence destruction -> question; no new reaction rule")
	# Walking and every core verb suppress bubbles, including view return cues.
	for verb in PlayerArt.known_verbs():
		for kind in Reactions.KINDS:
			_work_fixture(verb, Player.WEST)
			_state["intent"]["interact"] = true
			_work_tick(view)
			Reactions.show(_state, kind)
			await _reaction_settle(view)
			var body: Sprite2D = view.get_node("Body")
			expect(view.playing() == verb and not view.get_node("ReactionBubble").visible
				and body.material == null, "Reaction never obscures active/returning %s work" % verb)
			if kind == &"question":
				await _shoot("suppressed_work_%s" % verb, "Reaction waits: %s tool pose remains unobscured" % verb)
	_reaction_fixture()
	Reactions.show(_state, &"note")
	await _reaction_settle(view)
	_state["intent"]["move"] = [1, 0]
	Player.tick(_state)
	view._process(0.0)
	expect(view.playing() == &"walk_west" and view.flipped() and not view.get_node("ReactionBubble").visible,
		"Walking hides the reaction without changing the state's remaining lifetime")
	await _shoot("suppressed_walk", "Moving east: authored walk, no reaction layer")
	_state["intent"]["move"] = [0, 0]
	view._process(0.0)
	expect(view.playing() == &"react_note", "Stopping shows the still-active existing reaction")
	for _i in GameData.REACTION_TICKS:
		Reactions.tick(_state)
	view._process(0.0)
	expect(Reactions.now(_state) == &"" and view.playing() == &"idle_west"
		and not view.get_node("ReactionBubble").visible, "Expiry removes bubble and body mask and restores idle")
	await _shoot("expired_reaction", "Existing reaction lifetime expires to normal authored idle")
	# Four symbols at all map/camera corners: glyph alone can be clamped.
	_caption.position = Vector2(120, 128)
	for corner in [Vector2i(0, 0), Vector2i(39, 0), Vector2i(0, 17), Vector2i(39, 17)]:
		for kind in Reactions.KINDS:
			_reaction_fixture()
			_set_contact(_state["player"], Vector2i(corner.x * 16 + 8, corner.y * 16 + 16))
			Reactions.show(_state, kind)
			_world.look_at_cell(corner)
			await _reaction_settle(view)
			_reaction_check(view, kind)
			await _shoot("bounds_%d_%d_%s" % [corner.x, corner.y, kind],
				"Map corner %s / %s / glyph clamped, feet unchanged" % [str(corner), kind])
	_caption.position = Vector2(8, 8)
	# Shared prop/enemy shadow consumers retain exactly one source-owned shadow.
	_reaction_fixture()
	_world.look_at_cell(Vector2i(18, 9))
	await _reaction_settle(view)
	for actor in _world.get_node("Occupants/Actors").get_children():
		var shadow: Sprite2D = actor.get_node("Shadow")
		expect(shadow.texture.resource_path == PlayerView.SHADOW and shadow.position == Vector2(0, -1),
			"Shared enemy shadow uses unchanged ground placement")
	for prop in _world.get_node("Occupants").get_children():
		if prop is Sprite2D and prop.texture != null and prop.texture.resource_path.ends_with("/tree.png"):
			expect(prop.get_child_count() == 1 and prop.get_child(0).texture.resource_path == PlayerView.SHADOW,
				"Tree has one separate shared contact shadow")
	await _shoot("shared_shadows", "Farmer, tree and walker share one compact contact-shadow source")
	# On the real renderer, split body/glyph must equal the original combined PNG.
	if _capture:
		for kind in Reactions.KINDS:
			_reaction_fixture()
			Reactions.show(_state, kind)
			await _reaction_settle(view)
			var body: Sprite2D = view.get_node("Body")
			var bubble: Sprite2D = view.get_node("ReactionBubble")
			await process_frame
			await RenderingServer.frame_post_draw
			var split := root.get_texture().get_image()
			body.material = null
			bubble.visible = false
			await process_frame
			await RenderingServer.frame_post_draw
			var combined := root.get_texture().get_image()
			expect(split.get_data() == combined.get_data(), "Split %s glyph equals combined source: no double glyph/halo/body alteration" % kind)
			view._process(0.0)
			await _shoot("split_equals_source_%s" % kind, "Renderer: %s body+glyph equals combined committed PNG" % kind)
		_reaction_fixture()
		await _reaction_settle(view)
		var shadow: Sprite2D = view.get_node("Shadow")
		await process_frame
		await RenderingServer.frame_post_draw
		var grounded := root.get_texture().get_image()
		shadow.visible = false
		await process_frame
		await RenderingServer.frame_post_draw
		var floating := root.get_texture().get_image()
		var changed := 0
		for y in grounded.get_height():
			for x in grounded.get_width():
				if grounded.get_pixel(x, y) != floating.get_pixel(x, y):
					changed += 1
		expect(changed >= 5 and changed <= 54, "New shadow changes a small readable ground contact, without a painted halo")
		shadow.visible = true
		await _shoot("shadow_contact", "Compact separate shadow: %d ground pixels changed, stable boots" % changed)


func _settle() -> void:
	var before := State.hash_of(_state)
	_world.show_state(_state)
	_world.get_node("Occupants/PlayerView").show_state(_state)
	for _i in 3:
		await process_frame
	expect(State.hash_of(_state) == before, "Drawing/showcase frame cannot change isolated simulation")


func _check_placement() -> void:
	var drawn := {}
	var house_count := 0
	for node in _world.get_node("Occupants").get_children():
		if node is Sprite2D and node.has_meta("logical_cells"):
			for idx in node.get_meta("logical_cells"):
				expect(not drawn.has(idx), "No duplicated logical cell in grouped sprites")
				drawn[idx] = true
			if node.texture.resource_path.ends_with("/house.png"):
				house_count += 1
				expect(node.position == Vector2(344, 144), "House node sorts at facade ground contact")
				expect(node.offset == Vector2(-32, -60), "House roof overhang retains its accepted source pivot")
			if node.texture.resource_path.ends_with("/tree.png"):
				expect(node.position == Vector2(200, 160), "Tree sorts by trunk contact, not canopy top")
				expect(node.offset == Vector2(-20, -44), "Tree uses source-owned pivot")
	expect(drawn.size() == (_state["occupants"] as Dictionary).size() and house_count == 1,
		"Exactly one house drawing covers all nine logical cells")
	var actors := _world.get_node("Occupants/Actors")
	expect(actors.y_sort_enabled, "Nested actors participate in their parent's y-sort")
	var enemy := Entities.get_one(_state, Entities.ids(_state)[0])
	expect(actors.get_child(0).position == ArtPlacement.contact(enemy["pos"]), "Enemy sort origin is its ground contact")
	var player := _world.get_node("Occupants/PlayerView")
	expect(player.position == ArtPlacement.contact(_state["player"]["pos"]), "Player and enemies share contact coordinates")
	var body: Sprite2D = player.get_node("Body")
	expect(body.offset == Vector2(-24, -44), "Pilot farmer is the accepted 30px source at its ground pivot")
	var light := ArtPlacement.emission(&"house", Vector2(320, 96), &"light", Vector2.ZERO)
	var smoke := ArtPlacement.emission(&"house", Vector2(320, 96), &"smoke", Vector2.ZERO)
	expect(light == Vector2(344, 127) and smoke == Vector2(361, 98), "Lamp/chimney anchor follows the same full house drawing")


func _shoot(name: String, caption: String) -> void:
	_caption.text = caption
	if not _capture:
		return
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	expect(image != null and image.get_size() == Vector2i(480, 270), "Capture is the native viewport")
	if image != null:
		expect(image.save_png(_folder + name + ".png") == OK, "Capture saved: " + name)


## Real texture frames on native canvases, grouped into review pages.
func _contacts() -> void:
	_world.visible = false
	var layer := Node2D.new()
	root.add_child(layer)
	_world.get_node("Camera").enabled = false
	root.canvas_transform = Transform2D.IDENTITY
	var paths: Array[String] = []
	for name in GameData.sorted_names(PlayerFrames.COUNT.keys()):
		for frame in int(PlayerFrames.COUNT[name]):
			paths.append(PlayerArt.texture_path(name, frame))
	for name in ["walker", "walker_walk_b", "walker_attack", "walker_death"]:
		paths.append(WorldView.ENEMY_DIR + name + ".png")
	paths.append(WorldView.BUILDING_DIR + "house.png")
	paths.append(WorldView.PROP_DIR + "tree.png")
	for page in ceili(float(paths.size()) / 28.0):
		for child in layer.get_children():
			child.queue_free()
		await process_frame
		for i in mini(28, paths.size() - page * 28):
			var path := paths[page * 28 + i]
			var sprite := Sprite2D.new()
			sprite.texture = load(path)
			sprite.centered = false
			var metadata: Dictionary = RasterArt.FRAMES.get(path, {})
			var pivot: Vector2 = Vector2(metadata.get("pivot", PlayerFrames.FEET))
			sprite.offset = -pivot
			sprite.position = Vector2(32 + i % 7 * 64, 80 + i / 7 * 58)
			layer.add_child(sprite)
			expect(sprite.texture != null, "Every contact frame has an actual texture")
		await _shoot("animation_frames_%02d" % page, "Committed player / walker frames at native scale; page %d" % page)
		for sprite in layer.get_children():
			sprite.modulate = Color.BLACK
		await _shoot("silhouettes_%02d" % page, "Native alpha silhouettes: committed actors and pilot landmarks")
	layer.queue_free()
