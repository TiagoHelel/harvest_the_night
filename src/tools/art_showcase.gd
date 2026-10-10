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
var _house_lighting: Lighting


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
	if args.has("--terrain") or args.has("--water") or args.has("--props") or args.has("--crops") or args.has("--house") or args.has("--stations"):
		# Use Main's real relighting pipeline for all three material light states.
		var relight := Relight.new()
		relight.name = "Relight"
		relight.layer = 1
		root.add_child(relight)
	_world = load("res://scenes/World.tscn").instantiate()
	root.add_child(_world)
	await process_frame
	var overlay := CanvasLayer.new()
	overlay.layer = 3
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
	if args.has("--house") or args.has("--stations"):
		var lamps := CanvasLayer.new()
		lamps.layer = 2
		root.add_child(lamps)
		_house_lighting = Lighting.new()
		lamps.add_child(_house_lighting)
		_house_lighting.set_quality(Lighting.STEADY)
		_house_lighting.set_process(false)
		if args.has("--stations"):
			await _station_family()
			print("STATION SHOWCASE: %d checks, %d failed" % [_checks, _failed])
		else:
			await _house_family()
			print("HOUSE SHOWCASE: %d checks, %d failed" % [_checks, _failed])
		quit(1 if _failed > 0 else 0)
		return
	if args.has("--crops"):
		await _crops_family()
		print("CROP SHOWCASE: %d checks, %d failed" % [_checks, _failed])
		quit(1 if _failed > 0 else 0)
		return
	if args.has("--props"):
		await _props_family()
		print("PROP SHOWCASE: %d checks, %d failed" % [_checks, _failed])
		quit(1 if _failed > 0 else 0)
		return
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
	if args.has("--fishing-hold"):
		await _fishing_hold()
		print("FISHING HOLD: %d checks, %d failed" % [_checks, _failed])
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
	expect(ghost.position == Vector2(272, 224) and ghost.scale == Vector2(2, 2), "House ghost sorts at the enlarged ground contact")
	expect(ghost.offset == Vector2(-32, -60), "House ghost uses source-owned pivot")
	expect(_world.ghost_footprint() == GameData.HOUSE_SIZE, "House preview frame covers its enlarged blocked cells")
	await _shoot("ghost_house", "House preview: 6x4 footprint / enlarged existing roof")
	_world.show_ghost(Vector2i(14, 10), &"gun_tower", true)
	await _settle()
	expect(ghost.position == Vector2(232, 176), "Tower ghost stands on the selected cell")
	expect(ghost.offset == Vector2(-16, -44) and ghost.texture.get_size() == Vector2(32, 48), "Authored tower preview keeps its source-owned canvas and ground pivot")
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
		var needed := int(GameData.CROPS[crop]["growth_days"])
		for stage in 4:
			(_state["plots"] as Dictionary)[Grid.index(Vector2i(9 + stage * 3, row))] = {
				"crop": crop, "growth": (stage * needed + 2) / 3, "watered": stage % 2 == 0}
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


const STATIONS := [&"workshop", &"kitchen", &"press", &"generator", &"shop", &"well"]
const STATION_CORNERS := [Vector2i(12,7),Vector2i(20,7),Vector2i(28,7),Vector2i(12,12),Vector2i(20,12),Vector2i(28,12)]


func _station_fixture(lighting: int = 1, kind: int = 0) -> void:
	_crops_fixture(lighting)
	for id in GameData.RESOURCES:
		Resources.add(_state, id, 1000)
	# Build through the real footprint/anchor API in this isolated fixture.
	var phase: int = _state["phase"]
	_state["phase"] = Phases.DAY
	for i in STATIONS.size():
		if i < 4:
			expect(Building.place(_state, STATIONS[i], STATION_CORNERS[i]), "Real station placement retains its existing cost and 2x2 anchor")
		else:
			for cell in Building.footprint(STATIONS[i], STATION_CORNERS[i]):
				expect(Farm.restore(_state, cell, {"id":STATIONS[i], "anchor": [STATION_CORNERS[i].x,STATION_CORNERS[i].y]}),
					"Shop/well fixture covers its declared occupied cells")
		if kind == 2 and i < 4:
			Farm.damage(_state, STATION_CORNERS[i], int(GameData.BUILDINGS[STATIONS[i]]["hp"]) * 3 / 4)
	if kind == 1:
		_station_start()
	_state["phase"] = phase
	_set_contact(_state["player"], Vector2i(344,248))
	_state["player"]["facing"] = Player.SOUTH
	_state["player"]["action"] = {}


func _station_start() -> void:
	for i in 3:
		expect(Crafting.start_at(_state, STATION_CORNERS[i]), "Real paid job starts on the existing station anchor")
	Power.tick(_state)


func _station_sprite(i: int) -> Sprite2D:
	var idx := Grid.index(STATION_CORNERS[i])
	for node in _world.get_node("Occupants").get_children():
		if node is Sprite2D and idx in node.get_meta("logical_cells", []):
			return node
	return null


func _station_check() -> void:
	var total := 0
	for node in _world.get_node("Occupants").get_children():
		if node is Sprite2D and node.has_meta("logical_cells"):
			total += 1
	expect(total == 6, "All six full stations draw once, never as repeated quarter miniatures")
	for i in STATIONS.size():
		var id: StringName = STATIONS[i]
		var corner: Vector2i = STATION_CORNERS[i]
		var sprite := _station_sprite(i)
		expect(sprite != null, "Full station has a real drawing at its unchanged logical anchor")
		if sprite == null:
			continue
		var size := Building.size_of(id)
		var on := Farm.occupant(_state, corner)
		var running := WorldView.station_running(_state,id,corner)
		var hurt := i < 4 and float(on.get("hp",1))/float(GameData.BUILDINGS[id]["hp"]) < 0.75
		var suffix := "_hurt" if hurt else ("_active" if running else "")
		var folder := WorldView.BUILDING_DIR if i < 2 else WorldView.PROP_DIR
		expect(sprite.texture.resource_path == folder+String(id)+suffix+".png", "Activity and wear select distinct authored states from existing core data")
		expect(sprite.position == Vector2(corner*16+Vector2i(size.x*8,size.y*16)), "Each station sorts at its original footprint bottom center")
		var pivot := Vector2(24,44) if i < 4 else (Vector2(16,36) if i == 4 else Vector2(12,30))
		expect(sprite.offset == -pivot and sprite.modulate == Color.WHITE, "All states preserve contact and readable material colors")
		expect(sprite.get_meta("logical_cells").size() == size.x*size.y, "Full drawing retains exactly the existing blocked cells")
		for y in size.y:
			for x in size.x:
				var cell := corner+Vector2i(x,y)
				expect(Farm.occupant(_state,cell).get("id") == id and not Farm.walkable(_state,cell), "Cosmetic station never changes footprint occupancy")
				if i < 4:
					expect(Building.anchor_of(_state,cell) == corner, "Every quarter still targets the same real production anchor")
		expect(Farm.walkable(_state,corner+Vector2i(size.x,0)), "Station overhang never adds blocking cells")
		if int(_state["phase"]) == Phases.DAY:
			if i < 3:
				expect(Interact.verb_at(_state,corner) == (&"repair" if hurt else &"craft"), "Existing station interaction target still offers the correct real verb")
			elif i == 4:
				expect(Interact.verb_at(_state,corner) == &"trade", "Shop counter remains the original trade target")
			elif i == 5:
				expect(Farming.is_water_source(_state,corner) and not Farming.is_water_source(_state,corner+Vector2i.RIGHT), "Well source remains one logical cell")
		if i in [0,1,3]:
			expect(_house_lighting._lights_up(id,on,corner) == running, "Idle/stalled station does not emit a working furnace/engine glow")


func _station_overlap(prop: Sprite2D, body: Sprite2D, behind: bool) -> void:
	if not _capture:
		return
	var before := var_to_bytes(_state)
	await RenderingServer.frame_post_draw
	var covered := root.get_texture().get_image()
	prop.hide()
	await process_frame
	await RenderingServer.frame_post_draw
	var open := root.get_texture().get_image()
	var source := body.texture.get_image()
	var transform := body.get_global_transform_with_canvas()
	var changed := 0
	for y in source.get_height():
		for x in source.get_width():
			if source.get_pixel(x,y).a < 0.99:
				continue
			var point := Vector2i(transform*(body.offset+Vector2(x,y)))
			if Rect2i(Vector2i.ZERO,covered.get_size()).has_point(point) and covered.get_pixelv(point)!=open.get_pixelv(point):
				changed += 1
	expect(changed > 8 if behind else changed == 0, "Actual station masks actors behind and preserves their pixels in front")
	prop.show()
	await process_frame
	expect(var_to_bytes(_state) == before, "Station occlusion sampling is read-only")


func _station_lamp_pixels() -> void:
	if not _capture:
		return
	var before := var_to_bytes(_state)
	_house_lighting.set_quality(Lighting.OFF)
	await process_frame
	await RenderingServer.frame_post_draw
	var dark := root.get_texture().get_image()
	_house_lighting.set_quality(Lighting.STEADY)
	await process_frame
	await RenderingServer.frame_post_draw
	var lit := root.get_texture().get_image()
	var transform := root.get_canvas_transform()
	for i in [0,1,3]:
		var lamp := ArtPlacement.emission(STATIONS[i],Vector2(STATION_CORNERS[i]*16),&"light",Vector2.ZERO)
		var point := Vector2i(transform*lamp)
		expect(lit.get_pixelv(point).r > dark.get_pixelv(point).r+0.05, "Actual active furnace/engine receives light at its authored source pixel")
	expect(var_to_bytes(_state)==before, "Station light quality cannot change jobs, fuel or HP")


func _station_family() -> void:
	var view: PlayerView = _world.get_node("Occupants/PlayerView")
	view.set_process(false)
	_world.set_process(false)
	for lighting in 4:
		for kind in 3:
			_station_fixture(lighting,kind)
			await _house_settle(view)
			_world.look_at_cell(Vector2i(20,9))
			await process_frame
			_station_check()
			await _shoot("family_%d_light%d"%[kind,lighting],"Six stations: idle/active/hurt %d; dawn/day/dusk/night %d"%[kind,lighting])
			if lighting == 3 and kind == 1:
				await _station_lamp_pixels()
	# Both actual actor types cross every fixture in the real nested sort layer.
	for i in STATIONS.size():
		_station_fixture()
		var enemy_id := Entities.spawn(_state,&"walker",Vector2i(34,14))
		var enemy := Entities.get_one(_state,enemy_id)
		await _house_settle(view)
		var contact: Vector2i = Vector2i(_station_sprite(i).position)
		for subject in 2:
			for front in 2:
				var at := contact+Vector2i(0,6 if front else -6)
				_set_contact(_state["player"],at if subject==0 else Vector2i(544,248))
				_set_contact(enemy,at if subject==1 else Vector2i(544,248))
				await _house_settle(view)
				_station_check()
				var body: Sprite2D = view.get_node("Body") if subject==0 else _world.get_node("Occupants/Actors").get_child(0)
				await _station_overlap(_station_sprite(i),body,not bool(front))
				await _shoot("overlap_%s_subject%d_front%d"%[STATIONS[i],subject,front],"%s: farmer/walker %d behind/front %d"%[STATIONS[i],subject,front])
		_station_fixture()
		await _house_settle(view)
		var cell := Vector2i(24,14)
		_world.show_ghost(cell,STATIONS[i],true)
		var ghost: Sprite2D = _world.find_child("Ghost",true,false)
		var size := Building.size_of(STATIONS[i])
		expect(_world.ghost_footprint()==size and ghost.position==Vector2(cell*16+Vector2i(size.x*8,size.y*16)), "Station preview covers its original logical footprint once")
		expect(ghost.offset==_station_sprite(i).offset, "Preview and actual placed station share the source-owned ground pivot")
		await _shoot("ghost_%s"%STATIONS[i],"Full %s preview; original fixture footprint"%STATIONS[i])
		_world.hide_ghost()
	# Outside occupancy hashing: only real queue/power changes, no refresh hint.
	_station_fixture()
	await _house_settle(view)
	var identities: Array = _world._stations.duplicate()
	var occupancy: int = _state["occupants"].hash()
	_station_start()
	var before := var_to_bytes(_state)
	_world._process(0.13)
	await process_frame
	_station_check()
	expect(_state["occupants"].hash()==occupancy and var_to_bytes(_state)==before and identities==_world._stations, "Queue-only activity updates cached sprites without allocating occupants or mutating core")
	await _shoot("activity_only_start","Real queue/engine change: active sprites update without an occupancy rebuild")
	for i in 3:
		Crafting.cancel_all(_state,STATION_CORNERS[i])
	_state["power"]["burning"].clear()
	before=var_to_bytes(_state)
	_world._process(0.13)
	await process_frame
	_station_check()
	expect(var_to_bytes(_state)==before and identities==_world._stations, "Cancellation/fuel-off returns to idle on the bounded view update")
	await _shoot("activity_only_stop","Cancelled real jobs and stopped engine return to idle")
	# A second station of the same kind owns a separate job and ground anchor.
	var second := Vector2i(34,7)
	expect(Building.place(_state,&"workshop",second), "A second real workshop can be placed without merging fixtures")
	expect(Crafting.start_at(_state,second), "Second workshop owns an independent real job")
	await _house_settle(view)
	var workshops := 0
	for sprite in _world._stations:
		if sprite.get_meta("station_id") == &"workshop":
			workshops+=1
			var active: bool = sprite.get_meta("station_anchor") == second
			expect(sprite.texture.resource_path == WorldView.BUILDING_DIR+("workshop_active.png" if active else "workshop.png"), "Only the workshop with the real running job shows activity")
	expect(workshops==2,"Two independent 2x2 anchors draw as two whole workshops")
	await _shoot("independent_jobs","Two workshops: one idle, one working at its own existing anchor")
	# Real damage, exact wear threshold, and repair only refresh presentation.
	_station_fixture(1,1)
	await _house_settle(view)
	for i in 4:
		var on := Farm.occupant(_state,STATION_CORNERS[i])
		var full: int = GameData.BUILDINGS[STATIONS[i]]["hp"]
		Farm.damage(_state,STATION_CORNERS[i],full/4)
		before=var_to_bytes(_state)
		_world._process(0.13)
		await process_frame
		expect(_station_sprite(i).texture.resource_path.ends_with("_active.png"), "Exactly 75 percent HP keeps the active undamaged station")
		Farm.damage(_state,STATION_CORNERS[i],1)
		before=var_to_bytes(_state)
		_world._process(0.13)
		await process_frame
		expect(_station_sprite(i).texture.resource_path.ends_with("_hurt.png") and WorldView.station_running(_state,STATIONS[i],STATION_CORNERS[i]), "Below the existing wear threshold, damage remains visible without cancelling a real job")
		expect(var_to_bytes(_state)==before,"HP-only refresh cannot alter damage, fuel or job timers")
		on["hp"]=full
		before=var_to_bytes(_state)
		_world._process(0.13)
		await process_frame
		expect(_station_sprite(i).texture.resource_path.ends_with("_active.png") and var_to_bytes(_state)==before,"Restored HP returns the same running station to its active source")
	for lighting in [1,3]:
		_station_fixture(lighting)
		for id in GameData.RESOURCES:
			_state["held"][id]=0
		for i in 3:
			expect(Crafting.enqueue(_state,STATION_CORNERS[i],Crafting.selected_at(_state,STATIONS[i])), "Unpaid real front job can be queued")
			expect(Crafting.is_stalled(_state,STATION_CORNERS[i]), "Fixture is truly stalled in core")
		Power.tick(_state)
		await _house_settle(view)
		_station_check()
		await _shoot("stalled_light%d"%lighting,"Queued without materials/fuel: inactive art and no false working glow")
	_station_fixture(3,1)
	for i in 4:
		Farm.damage(_state,STATION_CORNERS[i],int(GameData.BUILDINGS[STATIONS[i]]["hp"])*3/4)
	await _house_settle(view)
	_station_check()
	await _shoot("working_hurt_light3","Damaged real running jobs: structural wear stays visible, physical lights still work")
	await _station_lamp_pixels()
	# Every valid map corner is checked for the same fixed placement contract.
	for i in STATIONS.size():
		var size := Building.size_of(STATIONS[i])
		for corner in [Vector2i.ZERO,Vector2i(40-size.x,0),Vector2i(0,18-size.y),Vector2i(40-size.x,18-size.y)]:
			_station_fixture()
			_state["occupants"].clear()
			for y in size.y:
				for x in size.x:
					Farm.restore(_state,corner+Vector2i(x,y),{"id":STATIONS[i],"anchor":[corner.x,corner.y],"hp":999})
			await _house_settle(view)
			var drawn := 0
			for node in _world.get_node("Occupants").get_children():
				if node is Sprite2D and node.has_meta("logical_cells"):
					drawn+=1
					expect(node.position==Vector2(corner*16+Vector2i(size.x*8,size.y*16)), "Map boundary keeps station at its unchanged full footprint contact")
			expect(drawn==1,"Map boundary never duplicates a station quarter")


## Independent full/hurt farmhouse states through the production view and lights.
func _house_sprite() -> Sprite2D:
	for node in _world.get_node("Occupants").get_children():
		if node is Sprite2D and node.get_meta("logical_cells", []).size() == 9:
			return node
	return null


func _house_check(corner: Vector2i = Vector2i(20, 6)) -> void:
	var sprite := _house_sprite()
	expect(sprite != null, "Exactly one grouped farmhouse drawing exists")
	if sprite == null:
		return
	var wanted := "house_hurt" if float(_state["house_hp"]) / Phases.house_full(_state) < 0.75 else "house"
	expect(sprite.texture.resource_path == WorldView.BUILDING_DIR + wanted + ".png", "House art reads the separate HP field, including upgrades")
	expect(sprite.position == Vector2(corner * 16 + Vector2i(24, 48)) and sprite.offset == Vector2(-32, -60), "Damage preserves roof, entrance and source ground anchor")
	expect(sprite.modulate == Color.WHITE, "Authored damaged facade retains readable source colors")
	var found := 0
	for node in _world.get_node("Occupants").get_children():
		if node is Sprite2D and node.get_meta("logical_cells", []).size() == 9:
			found += 1
	expect(found == 1, "Nine compatibility slices are never drawn as nine roofs")
	for y in 3:
		for x in 3:
			var cell := corner + Vector2i(x, y)
			expect(Farm.occupant(_state, cell).get("id") == &"house" and not Farm.is_empty(_state, cell), "All nine original footprint cells remain blocked")
	expect(Farm.is_empty(_state, corner + Vector2i(3, 2)), "Roof overhang adds no logical blocking cell")
	var size := Farm.house_bounds(_state).size
	var windows := ArtPlacement.emissions(&"house", Vector2(corner * 16), &"windows", Vector2.ZERO, &"light", size)
	expect(windows.size() == 5, "One grouped house emits exactly five physical window lights")
	var local := [Vector2(32, 33), Vector2(19, 45), Vector2(41, 45), Vector2(30, 45), Vector2(52, 46)]
	for i in windows.size():
		expect(windows[i] == sprite.position + (local[i] + sprite.offset) * sprite.scale,
			"Each glow uses the measured glass plane of the actual enlarged drawing")
	expect(ArtPlacement.emission(&"house", Vector2(corner * 16), &"smoke", Vector2.ZERO, size)
		== sprite.position + (Vector2(51,12) + sprite.offset) * sprite.scale,
		"Chimney smoke shares the authored whole/hurt roof opening")


func _house_settle(view: PlayerView) -> void:
	var before := var_to_bytes(_state)
	_house_lighting.show_state(_state)
	_house_lighting.queue_redraw()
	await _reaction_settle(view)
	expect(var_to_bytes(_state) == before, "House/lamp presentation cannot change HP, occupancy, RNG or saves")


func _house_overlap(body: Sprite2D, behind: bool) -> void:
	if not _capture:
		return
	var house := _house_sprite()
	var before := var_to_bytes(_state)
	await RenderingServer.frame_post_draw
	var covered := root.get_texture().get_image()
	house.hide()
	await process_frame
	await RenderingServer.frame_post_draw
	var open := root.get_texture().get_image()
	var source := body.texture.get_image()
	var transform := body.get_global_transform_with_canvas()
	var changed := 0
	for y in source.get_height():
		for x in source.get_width():
			if source.get_pixel(x, y).a < 0.99:
				continue
			var point := Vector2i(transform * (body.offset + Vector2(x, y)))
			if Rect2i(Vector2i.ZERO, covered.get_size()).has_point(point) and covered.get_pixelv(point) != open.get_pixelv(point):
				changed += 1
	expect(changed > 10 if behind else changed == 0, "Actual whole/hurt facade hides actors behind and preserves all their pixels in front")
	house.show()
	await process_frame
	expect(var_to_bytes(_state) == before, "Occlusion sampling never changes simulation state")


func _house_lamp_pixels() -> void:
	if not _capture:
		return
	var before := var_to_bytes(_state)
	_house_lighting.set_quality(Lighting.OFF)
	await process_frame
	await RenderingServer.frame_post_draw
	var dark := root.get_texture().get_image()
	_house_lighting.set_quality(Lighting.STEADY)
	await process_frame
	await RenderingServer.frame_post_draw
	var lit := root.get_texture().get_image()
	var transform := root.get_canvas_transform()
	for window in ArtPlacement.emissions(&"house", Vector2(320, 96), &"windows", Vector2.ZERO, &"light", Farm.house_bounds(_state).size):
		var point := Vector2i(transform * window)
		expect(lit.get_pixelv(point).r > dark.get_pixelv(point).r + 0.05, "Each physical window receives a visible local warm pool")
	var outside := Vector2i(transform * Vector2(344, 90))
	expect(lit.get_pixelv(outside) == dark.get_pixelv(outside), "House lights do not bleach the terracotta roof ridge")
	expect(var_to_bytes(_state) == before, "Light quality cannot alter the night's rules")


func _house_family() -> void:
	var view: PlayerView = _world.get_node("Occupants/PlayerView")
	view.set_process(false)
	_world.set_process(false)
	expect(_world._relight != null, "House fixtures use the actual Main relighting pipeline")
	for lighting in 4:
		for hurt in 2:
			_reaction_fixture(Phases.NIGHT if lighting == 3 else Phases.DAY, lighting == 2)
			if lighting == 0:
				_state["day_tick"] = 0
			_state["house_hp"] = Phases.house_full(_state) / 5 if hurt else Phases.house_full(_state)
			await _house_settle(view)
			_world.look_at_cell(Vector2i(20, 9))
			await process_frame
			_house_check()
			await _shoot("state_%d_light%d" % [hurt, lighting], "Whole/hurt farmhouse; dawn/day/dusk/night %d; five source-owned windows" % lighting)
			if lighting == 3:
				await _house_lamp_pixels()
				for quality in [Lighting.OFF, Lighting.FULL]:
					_house_lighting.set_quality(quality)
					await _shoot("state_%d_quality%d" % [hurt, quality], "Night farmhouse: quality %d; same HP and anchored lamps" % quality)
				_house_lighting.set_quality(Lighting.STEADY)
			if lighting in [1, 3]:
				var enemy := Entities.get_one(_state, Entities.ids(_state)[0])
				for subject in 2:
					for front in 2:
						var at := Vector2i(344, 150 if front else 138)
						_set_contact(_state["player"], at if subject == 0 else Vector2i(296, 160))
						_set_contact(enemy, at if subject == 1 else Vector2i(400, 180))
						await _house_settle(view)
						_house_check()
						var body: Sprite2D = view.get_node("Body") if subject == 0 else _world.get_node("Occupants/Actors").get_child(0)
						await _house_overlap(body, not bool(front))
						await _shoot("overlap_%d_light%d_subject%d_front%d" % [hurt, lighting, subject, front], "Farmer/walker %d behind/front %d; whole/hurt %d; light %d" % [subject, front, hurt, lighting])
	# Only HP changes: no occupant dictionary change or explicit show_state.
	_reaction_fixture()
	await _house_settle(view)
	var occupant_hash: int = _state["occupants"].hash()
	for upgraded in 2:
		_state["tech_owned"] = [&"stout timbers"] if upgraded else []
		var full := Phases.house_full(_state)
		for hp in [full, full * 3 / 4, full * 3 / 4 - 1, 1, 0, full]:
			_state["house_hp"] = hp
			var before := var_to_bytes(_state)
			_world._process(0.0)
			await process_frame
			_house_check()
			expect(var_to_bytes(_state) == before and _state["occupants"].hash() == occupant_hash, "HP threshold refreshes without a core/occupancy write")
			if hp == full * 3 / 4 or hp == full * 3 / 4 - 1:
				await _shoot("threshold_%d_hp%d" % [upgraded, hp], "Automatic HP-only refresh; upgraded %d; HP %d/%d" % [upgraded, hp, full])
	for lighting in 4:
		_reaction_fixture(Phases.NIGHT if lighting == 3 else Phases.DAY, lighting == 2)
		if lighting == 0:
			_state["day_tick"] = 0
		await _house_settle(view)
		_world.show_ghost(Vector2i(14, 10), &"house", true)
		var ghost: Sprite2D = _world.find_child("Ghost", true, false)
		expect(ghost.position == Vector2(272, 224) and ghost.offset == Vector2(-32, -60) and ghost.scale == Vector2(2,2)
			and _world.ghost_footprint() == GameData.HOUSE_SIZE, "House preview covers its enlarged collision footprint")
		await _shoot("ghost_light%d" % lighting, "Full farmhouse preview; unchanged 3x3 footprint; light %d" % lighting)
		_world.hide_ghost()
	for hurt in 2:
		for corner in [Vector2i(0, 0), Vector2i(37, 0), Vector2i(0, 15), Vector2i(37, 15)]:
			_reaction_fixture()
			_state["occupants"].clear()
			_add_house(corner)
			_state["house_cell"] = [corner.x + 1, corner.y + 1]
			_state["house_hp"] = 1 if hurt else Phases.house_full(_state)
			await _house_settle(view)
			_world.look_at_cell(corner)
			await process_frame
			_house_check(corner)
			await _shoot("bounds_%d_%d_%d" % [hurt, corner.x, corner.y], "Map/camera boundary: one coherent whole/hurt roof and nine logical cells")


## All actual growth stages and moisture cues in the production ground layer.
func _crops_fixture(lighting: int) -> void:
	_water_fixture(Farm.Terrain.GRASS, 2 if lighting == 3 else (1 if lighting == 2 else 0))
	_state["regrowing"].clear()
	if lighting == 0:
		_state["day_tick"] = 0
	_state["player"]["action"] = {}
	_state["player"]["facing"] = Player.SOUTH


func _crops_put(kind: StringName, stage: int, wet: bool, cell: Vector2i) -> void:
	var needed := int(GameData.CROPS[kind]["growth_days"])
	_state["terrain"][Grid.index(cell)] = Farm.Terrain.SOIL
	_state["plots"][Grid.index(cell)] = {
		"crop": kind, "growth": ceili(float(stage * needed) / 3.0),
		"watered": wet}
	expect(Farming.stage(_state, cell) == stage, "Every fixture selects the actual core growth stage")


func _crops_check() -> void:
	var counts := {}
	for sprite in _world._plot_sprites:
		var idx: int = sprite.get_meta("plot_cell")
		var cell := Grid.cell(idx)
		var art: String = sprite.get_meta("plot_art")
		var path := WorldView.CROP_DIR + art + ".png"
		var shape := PlaceholderArt.frame(path)
		var source := PlaceholderArt.texture_path(path)
		if shape.is_empty():
			expect(false, "Every crop has registered runtime geometry: %s" % path)
			continue
		var texture: Texture2D = sprite.texture.atlas if sprite.texture is AtlasTexture else sprite.texture
		expect(texture.resource_path == source and not shape.is_empty(),
			"Every crop and soil uses its required accepted source or registered stand-in")
		expect(Vector2i(sprite.texture.get_size()) == shape["canvas"],
			"Every crop uses its final native canvas, including padded tall stand-ins")
		expect(sprite.position == Vector2(cell * 16 + Vector2i(8,16)), "Water and growth never shift a crop's logical ground contact")
		expect(sprite.offset == -Vector2(shape["pivot"]), "Tall crops and soil use their exact separate pivots")
		var crop := StringName(art.get_slice("_", 0))
		if shape.has("stand_in") and GameData.CROPS.has(crop):
			expect(sprite.modulate == PlaceholderArt.art_tint(StringName(art) if art.ends_with("_regrow") else crop),
				"A temporary crop draws its stage or regrowth registered tint")
		expect(sprite.get_parent() == _world._plots, "Walkable crop art stays on the ground layer below actors")
		counts[idx] = int(counts.get(idx, 0)) + 1
	for idx in _state["plots"]:
		var cell := Grid.cell(int(idx))
		expect(int(counts.get(idx,0)) == (1 if Farming.crop_on(_state,cell) == &"" else 2), "Harvest removes only crop art and leaves one soil drawing")
		expect(Farm.is_empty(_state,cell), "Crop canopy adds no occupant or blocked interactive cell")


func _crops_moisture_pixels(view: PlayerView, cell: Vector2i, lighting: int) -> void:
	if not _capture:
		return
	var idx := Grid.index(cell)
	await RenderingServer.frame_post_draw
	var dry := root.get_texture().get_image()
	var before := var_to_bytes(_state)
	var can_original: int = _state["water_can"]
	_state["water_can"] = Farming.can_capacity(_state)
	var can_before: int = _state["water_can"]
	Farming._water(_state,cell)
	expect(Farming.is_watered(_state,cell) and int(_state["water_can"]) == can_before - 1, "Actual water spends exactly one can unit")
	await _reaction_settle(view)
	_crops_check()
	await RenderingServer.frame_post_draw
	var wet := root.get_texture().get_image()
	var transform := _world.get_global_transform_with_canvas()
	var changed := 0
	for y in 16:
		for x in 16:
			var pixel := Vector2i(transform * Vector2(cell * 16 + Vector2i(x,y)))
			if Rect2i(Vector2i.ZERO,dry.get_size()).has_point(pixel) and dry.get_pixelv(pixel) != wet.get_pixelv(pixel):
				changed += 1
	expect(changed >= 50, "Actual wet soil remains visible beneath mature foliage under every light ramp")
	await _shoot("moisture_light%d_%s" % [lighting,Farming.crop_on(_state,cell)], "Actual dry -> watered crop: %d changed soil pixels under mature foliage" % changed)
	# Restore only the fixture's intentional watering; rendering itself is guarded.
	_state["plots"][idx]["watered"] = false
	_state["water_can"] = can_original
	expect(var_to_bytes(_state) == before, "Restoring intentional fixture watering preserves every state/save field")
	expect(Farming.stage(_state,cell) == 3, "Water leaves maturity and source frame selection unchanged")
	await _reaction_settle(view)


func _crops_family() -> void:
	var view: PlayerView = _world.get_node("Occupants/PlayerView")
	view.set_process(false)
	_world.set_process(false)
	for lighting in 4:
		_crops_fixture(lighting)
		var kinds: Array = [&"carrot", &"corn", &"wheat"]
		for row in kinds.size():
			for stage in 4:
				for moisture in 2:
					_crops_put(kinds[row],stage,moisture == 1,Vector2i(9+stage*4+moisture,5+row*4))
		await _reaction_settle(view)
		_world.look_at_cell(Vector2i(18,9))
		await process_frame
		_crops_check()
		await _shoot("matrix_light%d" % lighting, "Three species / four stages / dry + wet, dawn/day/dusk/night %d" % lighting)
		for row in kinds.size():
			await _crops_moisture_pixels(view,Vector2i(21,5+row*4),lighting)
		await _shoot("watered_light%d" % lighting, "Real watering preserves all crop anchors and stage art")
		# Adjacent beds expose the actual tall-corn overlap and neighboring cells.
		_crops_fixture(lighting)
		for row in kinds.size():
			for y in range(5,9):
				for x in range(8+row*7,13+row*7):
					_crops_put(kinds[row],3,(x+y)%2 == 0,Vector2i(x,y))
		_set_contact(_state["player"],Vector2i(248,160))
		Entities.spawn(_state,&"walker",Vector2i(17,7))
		await _reaction_settle(view)
		_crops_check()
		await _shoot("dense_light%d" % lighting, "Dense ready beds: grounded corn, visible soil and walkable neighboring cells")
		for row in kinds.size():
			var cell := Vector2i(9+row*7,8)
			var kind: StringName = kinds[row]
			var before := Resources.amount(_state,kind)
			Farming._harvest(_state,cell)
			expect(Resources.amount(_state,kind) == before + int(GameData.CROPS[kind]["yield"]), "Actual harvest preserves the exact production yield")
		await _reaction_settle(view)
		_crops_check()
		await _shoot("harvested_light%d" % lighting, "Actual harvest clears single-harvest crops and keeps corn regrowing in aligned furrows")
		# Actual growth from planted through every stage, without changing rates.
		_crops_fixture(lighting)
		for row in kinds.size():
			var kind: StringName = kinds[row]
			var cell := Vector2i(12+row*5,9)
			_crops_put(kind,0,false,cell)
			SuiteKit.watered_mornings(_state, Farming.days_to_grow(kind))
			expect(Farming.is_ready(_state,cell), "Actual watered mornings reaches the ready stage")
		await _reaction_settle(view)
		_crops_check()
		await _shoot("grown_light%d" % lighting, "Real farming growth reaches ready art, without changing growth balance")
		_state = State.create(1010)
		_state["phase"] = Phases.NIGHT if lighting == 3 else Phases.DAY
		_state["day_tick"] = [0,GameData.DAY_TICKS/2,GameData.DAY_TICKS-1,0][lighting]
		await _reaction_settle(view)
		_crops_check()
		await _shoot("farm_light%d" % lighting, "Unchanged production farm crops, dawn/day/dusk/night %d" % lighting)

	# 0168: the original three-row fixtures retain their framing. All twelve
	# get a separate grid, which never writes beyond the farm's right edge.
	for lighting in 4:
		_crops_fixture(lighting)
		var ids := Farming.seeds()
		for i in ids.size():
			for stage in 4:
				_crops_put(ids[i], stage, stage % 2 == 0,
					Vector2i(9 + (i % 3) * 6 + stage, 5 + (i / 3) * 3))
		await _reaction_settle(view)
		_crops_check()
		await _shoot("twelve_light%d" % lighting,
			"Twelve crops / four real growth stages / final canvases and feet")


## Source-owned prop species and real harvest/occlusion fixtures.
func _props_fixture(lighting: int) -> void:
	_water_fixture(Farm.Terrain.GRASS, lighting)
	_state["regrowing"].clear()
	_set_contact(_state["player"], Vector2i(296, 192))
	_state["player"]["facing"] = Player.SOUTH
	_state["player"]["action"] = {}


func _props_cell(id: StringName, variant: int, near: Vector2i) -> Vector2i:
	for dx in [0, -1, 1, -2, 2, -3, 3]:
		var cell := near + Vector2i(dx, 0)
		if WorldView._prop_variant(id, cell) == WorldView.PROP_VARIANTS[id][variant]:
			return cell
	expect(false, "Fixture finds both controlled prop variants")
	return near


func _props_put(id: StringName, cell: Vector2i) -> void:
	expect(Farm.restore(_state, cell, {"id": id}), "Fixture uses one unchanged logical prop cell")
	if id in [&"ore", &"seam"]:
		_state["terrain"][Grid.index(cell)] = Farm.Terrain.ROCK


func _props_check() -> void:
	var seen := {}
	for node in _world.get_node("Occupants").get_children():
		if not (node is Sprite2D and node.has_meta("logical_cells")):
			continue
		var cells: Array = node.get_meta("logical_cells")
		if cells.size() != 1:
			continue
		var cell := Grid.cell(int(cells[0]))
		var on := Farm.occupant(_state, cell)
		var id: StringName = on["id"]
		if not id in [&"tree", &"stump", &"rock", &"seam", &"ore", &"cow", &"chicken"]:
			continue
		var chosen := WorldView._prop_variant(id, cell)
		var path := WorldView.PROP_DIR + str(chosen) + ".png"
		expect(node.texture.resource_path == path and RasterArt.FRAMES.has(path), "Every prop selects its required accepted source, with no flat fallback")
		expect(node.position == Vector2(cell * 16 + Vector2i(8, 16)), "Props sort at the unchanged one-cell ground contact")
		expect(node.offset == -Vector2(RasterArt.FRAMES[path]["pivot"]), "Prop view uses its species/material source pivot")
		expect(not seen.has(cells[0]), "Visual overhang never creates another logical collision cell")
		seen[cells[0]] = true
		if id == &"tree":
			expect(node.get_child_count() == 1 and node.get_child(0).texture.resource_path == PlayerView.SHADOW,
				"Each tree retains one separate compact ground shadow")
	var wanted := 0
	for on in _state["occupants"].values():
		if on["id"] in [&"tree", &"stump", &"rock", &"seam", &"ore", &"cow", &"chicken"]:
			wanted += 1
	expect(seen.size() == wanted, "Removed props leave no stale drawing; every current prop has exactly one drawing")


func _props_overlap_pixels(view: PlayerView, tree_cell: Vector2i, behind: bool) -> void:
	if not _capture:
		return
	var tree_sprite: Sprite2D
	for node in _world.get_node("Occupants").get_children():
		if node is Sprite2D and node.get_meta("logical_cells", []) == [Grid.index(tree_cell)]:
			tree_sprite = node
			break
	expect(tree_sprite != null, "Occlusion comparison locates the actual drawn logical tree cell")
	if tree_sprite == null:
		return
	var before := var_to_bytes(_state)
	await RenderingServer.frame_post_draw
	var covered := root.get_texture().get_image()
	tree_sprite.hide()
	await process_frame
	await RenderingServer.frame_post_draw
	var open := root.get_texture().get_image()
	var body: Sprite2D = view.get_node("Body")
	var source := body.texture.get_image()
	var transform := body.get_global_transform_with_canvas()
	var changed := 0
	for y in source.get_height():
		for x in source.get_width():
			if source.get_pixel(x, y).a < 0.99:
				continue
			var pixel := Vector2i(transform * (body.offset + Vector2(x, y)))
			if Rect2i(Vector2i.ZERO, covered.get_size()).has_point(pixel) and covered.get_pixelv(pixel) != open.get_pixelv(pixel):
				changed += 1
	expect(changed > 10 if behind else changed == 0, "Actual tree pixels occlude the farmer behind and preserve every farmer pixel in front")
	tree_sprite.show()
	await process_frame
	expect(var_to_bytes(_state) == before, "Pixel occlusion comparison cannot change any simulation/save field")


func _props_family() -> void:
	var view: PlayerView = _world.get_node("Occupants/PlayerView")
	view.set_process(false)
	_world.set_process(false)
	expect(_world._relight != null, "Props use Main's actual day/dusk/night shader")
	var choice_counts := {}
	var state_before := var_to_bytes(_state)
	for id in WorldView.PROP_VARIANTS:
		var choices := [0, 0]
		for idx in Grid.CELLS:
			var cell := Grid.cell(idx)
			var selected := WorldView._prop_variant(id, cell)
			expect(selected in WorldView.PROP_VARIANTS[id], "Every map cell selects an authored material/species variant")
			expect(selected == WorldView._prop_variant(id, cell), "Cell selection stays stable across redraws and ticks")
			choices[1 if str(selected).ends_with("_b") else 0] += 1
		expect(choices[0] > choices[1] and choices[1] > 0, "Controlled shape variation keeps the base most common")
		choice_counts[str(id)] = choices
	expect(var_to_bytes(_state) == state_before, "Exhaustive decorative choices consume no simulation RNG and write no state")
	for lighting in 3:
		_props_fixture(lighting)
		for variant in 2:
			_props_put(&"tree", _props_cell(&"tree", variant, Vector2i(12 + variant * 7, 6)))
			for row in 3:
				var id: StringName = [&"rock", &"seam", &"ore"][row]
				_props_put(id, _props_cell(id, variant, Vector2i(11 + row * 7 + variant * 3, 12)))
		_props_put(&"stump", Vector2i(21, 8))
		_props_put(&"cow", Vector2i(27, 7))
		_props_put(&"chicken", Vector2i(31, 7))
		Entities.spawn(_state, &"walker", Vector2i(29, 10))
		await _reaction_settle(view)
		_world.look_at_cell(Vector2i(20, 9))
		await process_frame
		_props_check()
		await _shoot("catalog_light%d" % lighting, "All prop species / both controlled variants / light %d" % lighting)
		# Production gathering: partial swings, final removal and actual regrowth.
		var targets := {}
		for idx in _state["occupants"]:
			var id: StringName = _state["occupants"][idx]["id"]
			if Gathering.is_node(id):
				targets[idx] = id
				for _hit in int(GameData.GATHERING[id]["hits"]) - 1:
					expect(Gathering.strike(_state, Grid.cell(idx)).is_empty(), "Partial gathering gives no yield and keeps its prop")
		await _reaction_settle(view)
		_props_check()
		await _shoot("partial_light%d" % lighting, "Partial work: same anchored props, no invented damage state")
		for idx in targets:
			var id: StringName = targets[idx]
			expect(Gathering.strike(_state, Grid.cell(idx)) == GameData.GATHERING[id]["yield"], "Final real gathering swing preserves the exact resource yield")
			var on := Farm.occupant(_state, Grid.cell(idx))
			expect(on.get("id", &"") == (&"stump" if id == &"tree" else &""), "Felled trees leave matching stumps; mined nodes disappear")
		await _reaction_settle(view)
		_props_check()
		await _shoot("cleared_light%d" % lighting, "Actual harvest removal: roots/stumps remain, loose rocks clear permanently")
		for _tick in int(GameData.GATHERING[&"tree"]["regrow_ticks"]):
			Gathering.tick(_state)
		for idx in targets:
			var id: StringName = targets[idx]
			expect(Farm.occupant(_state, Grid.cell(idx)).get("id", &"") == (&"" if id == &"rock" else id), "Existing regrowth restores the same cell-selected art; loose boulders remain removed")
		await _reaction_settle(view)
		_props_check()
		await _shoot("regrown_light%d" % lighting, "Real regrowth: identical canopy/resource choices at original ground contacts")
		# Existing livestock ready/collection changes only production state.
		Livestock.tick(_state)
		for cell in [Vector2i(27, 7), Vector2i(31, 7)]:
			_state["livestock"][Grid.index(cell)]["left"] = 1
		Livestock.tick(_state)
		await _reaction_settle(view)
		_props_check()
		await _shoot("animals_ready_light%d" % lighting, "Native cow/hen remain recognizable when production is ready")
		for cell in [Vector2i(27, 7), Vector2i(31, 7)]:
			var id: StringName = Farm.occupant(_state, cell)["id"]
			expect(Livestock.collect(_state, cell) == GameData.LIVESTOCK[id]["produces"], "Actual livestock collection preserves its product and yield")
			expect(Livestock.ready_at(_state, cell) == 0, "Collection resets readiness without removing the animal")
		await _reaction_settle(view)
		_props_check()
		await _shoot("animals_collected_light%d" % lighting, "Same grounded species after actual livestock collection")
		# Dense broad canopies on original one-cell footprints.
		_props_fixture(lighting)
		for y in [6, 8, 10]:
			for x in [10, 12, 14, 16, 18]:
				_props_put(&"tree", Vector2i(x, y))
		_set_contact(_state["player"], Vector2i(248, 192))
		await _reaction_settle(view)
		_props_check()
		await _shoot("forest_light%d" % lighting, "Dense mixed canopies: unchanged footprint, visible foreground farmer")
		# Both tree variants with farmer/walker crossing behind and in front.
		for subject in 2:
			_props_fixture(lighting)
			var left := _props_cell(&"tree", subject, Vector2i(15, 9))
			var right := _props_cell(&"tree", 1 - subject, Vector2i(25, 9))
			_props_put(&"tree", left)
			_props_put(&"tree", right)
			var enemy := Entities.spawn(_state, &"walker", right)
			var actor := Entities.get_one(_state, enemy)
			for step in 4:
				var dy: int = [-24, -8, 8, 24][step]
				_set_contact(_state["player"], Vector2i(left.x * 16 + 8, 160 + dy))
				_set_contact(actor, Vector2i(right.x * 16 + 8, 160 + dy))
				view._elapsed = 0.0
				await _reaction_settle(view)
				_props_check()
				expect(view.position.y == 160 + dy, "Canopies never move farmer contact or sorting origin")
				if lighting == 0 and step in [1, 2]:
					await _props_overlap_pixels(view, left, step == 1)
				await _shoot("overlap_light%d_variant%d_step%d" % [lighting, subject, step], "Farmer / walker and both full canopies: behind -> front %d" % dy)
		_state = State.create(9009)
		_state["phase"] = Phases.NIGHT if lighting == 2 else Phases.DAY
		_state["day_tick"] = GameData.DAY_TICKS - 1 if lighting == 1 else GameData.DAY_TICKS / 2
		var farm_before := var_to_bytes(_state)
		await _reaction_settle(view)
		_props_check()
		expect(var_to_bytes(_state) == farm_before, "Full farm props preserve map/occupancy, resources, RNG and every save field")
		await _shoot("farm_light%d" % lighting, "Production farm density / resources / livestock, light %d" % lighting)
	var file := FileAccess.open(_folder + "selection.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(choice_counts, "\t") + "\n")


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
			expect(_body_contact_is_valid(view.get_node("Body")), "Farmer retains its source-owned canvas, scale and body pivot")
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
	# Observe six real phase changes. Wall time is only a failure bound: a
	# loaded machine can render fewer fixed-FPS frames in the old 3.8s window.
	var started := Time.get_ticks_msec()
	var render_frames := 0
	var until := started + 12000
	while Time.get_ticks_msec() < until and trace.size() < 6:
		await process_frame
		await RenderingServer.frame_post_draw
		render_frames += 1
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
	file.store_string(JSON.stringify({"unique_rendered_phases":seen.size(),"phase_trace":trace,"elapsed_seconds":float(Time.get_ticks_msec()-started)/1000.0,"render_frames":render_frames,"timeout_seconds":12,"serialized_state_unchanged":var_to_bytes(_state)==before}, "\t"))


func _add_house(corner: Vector2i) -> void:
	for y in 3:
		for x in 3:
			(_state["occupants"] as Dictionary)[Grid.index(corner + Vector2i(x, y))] = {"id": &"house"}


## The actual PlayerView clock/frame binding for the reviewed blue walk, in
## all eight directions, plus the four facings core resolves them onto.
func _locomotion() -> void:
	(_state["entities"] as Dictionary).clear()
	var view: PlayerView = _world.get_node("Occupants/PlayerView")
	view.set_process(false)
	var body: Sprite2D = view.get_node("Body")
	var player: Dictionary = _state["player"]
	for heading in PlayerArt.HEADINGS:
		var suffix: StringName = PlayerArt.HEADINGS[heading]
		for motion in ["idle", "walk", "run"]:
			var moving: bool = motion != "idle"
			var running: bool = motion == "run"
			view.set_running(running)
			_set_contact(player, Vector2i(248, 208))
			_state["intent"]["move"] = [heading.x, heading.y]
			Player.tick(_state)
			var facing := Player.facing(_state)
			expect(facing == Player.facing_for(heading.x, heading.y, facing),
				"Core resolves the eight-way heading onto one of its four facings")
			# The view sees the direction while it is held, then stands in it.
			view._process(0.0)
			if not moving:
				_state["intent"]["move"] = [0, 0]
			# Run and walk share drawings, so start every family from frame 0.
			view._playing = &""
			var pose := PlayerArt.pose(facing, moving, &"", running, heading)
			var count := int(pose["frames"])
			var expected_name := StringName("%s_%s" % ["walk" if moving else "idle", suffix])
			expect(pose["name"] == expected_name and count == (8 if moving else 3),
				"Each of the eight directions selects its own reviewed walk and grounded idle")
			expect(PlayerFrames.SECONDS.has(expected_name), "Timing comes from the accepted strip")
			expect(is_equal_approx(float(pose["seconds"]), PlayerArt.RUN_FRAME_SECONDS if running
				else float(PlayerFrames.SECONDS[expected_name])), "Running plays the same cycle faster")
			await _settle()
			var fixed_contact := ArtPlacement.contact(player["pos"])
			for phase in count * 2:
				if moving and phase > 0:
					Player.tick(_state)
				var before := State.hash_of(_state)
				view._process(0.0 if phase == 0 else PlayerArt.frame_seconds(pose, (phase - 1) % count) + 0.0001)
				expect(State.hash_of(_state) == before, "Drawing the player never changes core state")
				expect(view.playing() == expected_name, "No locomotion family silently falls back to idle")
				expect(not view.flipped(), "Locomotion owns its direction and reflected ground registration")
				expect(body.texture != null and body.texture.resource_path ==
					PlayerArt.texture_path(expected_name, phase % count),
					"Actual view clock selects each authored frame, including loop wrap")
				expect(_body_contact_is_valid(body), "A turn or mirror cannot move the foot pivot")
				expect(view.position == ArtPlacement.contact(player["pos"]),
					"Visible ground origin agrees with unchanged core position")
				if not moving:
					expect(view.position == fixed_contact, "Idle feet stay planted across both loops")
				var metadata: Dictionary = RasterArt.FRAMES.get(body.texture.resource_path, {})
				expect(metadata.get("canvas") == Vector2i(80, 80) and metadata.get("pivot") == Vector2i(40, 72)
					and body.scale == Vector2(0.5,0.5), "Every locomotion frame preserves reviewed native geometry")
				if phase < count:
					await _shoot("%s_%s_%02d" % [motion, suffix, phase],
						"%s / %s / authored frame %d" % [expected_name, motion, phase])
			if motion == "walk":
				# Releasing ANY step must select the independent grounded pose,
				# rather than freezing the step with its suspended boot.
				for step in 8:
					_state["intent"]["move"] = [heading.x, heading.y]
					view._playing = expected_name
					view._elapsed = step * 0.1
					view._process(0.0)
					var walk_pixels := body.texture.get_image().get_data()
					var stopped_at := view.position
					_state["intent"]["move"] = [0, 0]
					view._process(0.0)
					expect(body.texture.resource_path == PlayerArt.texture_path(StringName("idle_%s" % suffix), 0),
						"Releasing each walk phase immediately selects neutral idle frame zero")
					expect(body.texture.get_image().get_data() != walk_pixels and view.position == stopped_at,
						"Stopping changes the suspended-leg drawing without shifting the ground pivot")
	view.set_running(false)
	view._playing = &""
	# Vertical wins a diagonal tie in core, but the drawing is the diagonal one.
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
			StringName("walk_%s" % PlayerArt.HEADINGS[move]), "A diagonal walk shows its own diagonal drawing")
		await _shoot("diagonal_%d_%d" % [move.x, move.y], "Diagonal %s: its own drawing, shared feet" % str(move))
		_state["intent"]["move"] = [0, 0]
		view._process(0.0)
		expect(view.playing() == StringName("idle_%s" % PlayerArt.HEADINGS[move]),
			"Releasing a diagonal stands still in that diagonal")
	# A facing the rules change afterwards (a verb turning to its target)
	# outranks the remembered diagonal.
	expect(PlayerArt.pose(Player.WEST, false, &"", false, Vector2i(1, 1))["name"] == &"idle_west"
		and PlayerArt.pose(Player.NORTH, true, &"", false, Vector2i(1, 1))["name"] == &"walk_north",
		"A heading the core facing disagrees with falls back to the facing's own drawing")
	# Direction changes without recreating the view, including east -> west.
	for facing in [Player.EAST, Player.WEST, Player.NORTH, Player.SOUTH]:
		var step: Vector2i = Player.FACING_STEPS[facing]
		_state["intent"]["move"] = [step.x, step.y]
		Player.tick(_state)
		view._process(0.13)
		expect(view.playing() == StringName("walk_%s" % PlayerArt.FACINGS[facing][0])
			and not view.flipped(), "Immediate direction changes show the correct art")
		expect(view.position == ArtPlacement.contact(player["pos"]) and _body_contact_is_valid(body),
			"Turning never adds an artificial canvas-width displacement")
		await _shoot("turn_%d" % facing, "Direction change / facing %d / no contact jump" % facing)
	# **Stardew Valley's height at 1920x1080.** Its farmer is a 16x32 sprite at
	# 4x: two 64px tiles. Ours is ~64 native pixels at half scale, which the
	# 480x270 viewport stretches by four: 128 screen pixels, the same two tiles.
	for name in PlayerFrames.COUNT:
		if not (String(name).begins_with("walk_") or String(name).begins_with("idle_")):
			continue
		for frame in int(PlayerFrames.COUNT[name]):
			var path := PlayerArt.texture_path(name, frame)
			var image := Image.load_from_file(ProjectSettings.globalize_path(path))
			var used := image.get_used_rect()
			var tall := float(used.size.y) * float(RasterArt.FRAMES[path].get("draw_scale", 1.0))
			# A long stride dips the body a little: 1.8 tiles is the deepest.
			expect(tall >= GameData.TILE_SIZE * 1.8 and tall <= GameData.TILE_SIZE * 2.1,
				"%s is two tiles tall, like Stardew's farmer on a 1080p screen" % path)
			# **The chosen 32px detail (2026-10-06).** One art pixel is 4x4
			# physical pixels at 1080p, as on the zombies and the world - not
			# the sources' 2x2 (64px) nor the 16px comparison's 8x8.
			expect(is_equal_approx(_screen_detail(path), 4.0),
				"%s draws each art pixel 4x4 at 1080p: the 32px farmer" % path)


## How many physical pixels at 1920x1080 one art pixel of `path` covers: the
## side of the largest aligned square of canvas pixels that always holds a
## single colour, times the frame's draw scale, times the viewport's stretch.
func _screen_detail(path: String) -> float:
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	image.convert(Image.FORMAT_RGBA8)
	var block := 1
	for side in [2, 4, 8]:
		if not _uniform_blocks(image, side):
			break
		block = side
	var stretch := float(ProjectSettings.get_setting("display/window/size/window_width_override")) \
		/ float(ProjectSettings.get_setting("display/window/size/viewport_width"))
	return block * float(RasterArt.FRAMES[path].get("draw_scale", 1.0)) * stretch


## Whether every aligned side x side square of the image is one colour.
func _uniform_blocks(image: Image, side: int) -> bool:
	var data := image.get_data()
	var width := image.get_width()
	if width % side != 0 or image.get_height() % side != 0:
		return false
	for y in range(0, image.get_height(), side):
		for x in range(0, width, side):
			var first := data.decode_u32((y * width + x) * 4)
			for dy in side:
				for dx in side:
					if data.decode_u32(((y + dy) * width + x + dx) * 4) != first:
						return false
	return true


func _body_contact_is_valid(body: Sprite2D) -> bool:
	if body.texture == null:
		return false
	var metadata: Dictionary = RasterArt.FRAMES.get(body.texture.resource_path, {})
	var pivot: Vector2i = metadata.get("pivot", PlayerFrames.FEET)
	var canvas: Vector2i = metadata.get("canvas", PlayerFrames.CANVAS)
	var offset := Vector2(pivot.x - canvas.x if body.flip_h else -pivot.x, -pivot.y)
	return body.offset == offset and body.texture.get_size() == Vector2(canvas) \
		and body.scale == Vector2.ONE * float(metadata.get("draw_scale", 1.0))


func _set_contact(who: Dictionary, pixels: Vector2i) -> void:
	var scale := Player.SUBTILE / GameData.TILE_SIZE
	who["pos"] = [pixels.x * scale, (pixels.y - GameData.TILE_SIZE / 2) * scale]


## Real interaction fixtures for every existing verb, with production carry.
## The strip a verb plays (`PlayerArt.VERBS`): its own, or a borrowed one -
## since task 0185 digging a truffle plays the collect strip until A025.
func _strip(verb: StringName) -> StringName:
	return PlayerArt.VERBS.get(verb, verb)


func _work_fixture(verb: StringName, facing: int) -> Vector2i:
	_state = State.create(5005)
	_state["tick"] = GameData.DUSK_AT_TICK / 2
	for key in ["occupants", "plots", "entities", "livestock", "crafting", "produced", "dig_spots"]:
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
					plot["growth"] = int(GameData.CROPS[crop]["growth_days"])
				_state["plots"][idx] = plot
			_state["selected_seed"] = crop
			_state["water_can"] = GameData.WATER_CAN_CAPACITY
		&"fish", &"reel":
			terrain[idx] = Farm.Terrain.WATER
		&"collect":
			on[idx] = {"id": &"cow"}
			_state["livestock"][idx] = {"ready": 1, "left": 100}
		# A pig's truffle on open grass (task 0185).
		&"dig":
			_state["dig_spots"][idx] = GameData.DIG_GIVES.duplicate()
		&"craft", &"carry":
			on[idx] = {"id": &"workshop", "hp": int(GameData.BUILDINGS[&"workshop"]["hp"])}
		&"trade":
			on[idx] = {"id": &"shop"}
		# The shipping bin's lid (task 0189), a one-tick panel verb like trade.
		&"ship":
			on[idx] = {"id": &"shipping_bin"}
		&"repair":
			# A building since task 0134: the farmer's verb no longer mends a
			# defence - the cursor does, at night.
			on[idx] = {"id": &"workshop", "hp": int(GameData.BUILDINGS[&"workshop"]["hp"]) - 10}
	_state["terrain"] = terrain
	var here: Vector2i = at - Player.FACING_STEPS[facing]
	_state["player"]["pos"] = [here.x * Player.SUBTILE + Player.SUBTILE / 2,
		here.y * Player.SUBTILE + Player.SUBTILE / 2]
	_state["player"]["facing"] = facing
	if verb == &"reel":
		Fishing.begin(_state, at)
		_state["fishing"]["stage"] = Fishing.BITING
		_state["fishing"]["left"] = 100
		# **The whole bar green and one hit** (task 0180): the pose checks
		# press once and watch the catch's follow-through; where the green
		# sits is the suites' question.
		_state["fishing"]["zone_at"] = 0
		_state["fishing"]["zone"] = int(GameData.FISHING["bar_units"])
		_state["fishing"]["needs"] = 1
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
	expect(view.playing() == _strip(verb), "Actual PlayerView plays its own %s work strip" % verb)
	expect(body.texture != null and body.texture.resource_path == PlayerArt.texture_path(_strip(verb), frame),
		"Actual work completion clock selects %s authored frame %d" % [verb, frame])
	expect(view.flipped() == (facing == Player.EAST), "Work east mirrors west, with consistent handedness")
	expect(body.offset == -Vector2(PlayerFrames.FEET) and body.texture.get_size() == Vector2(PlayerFrames.CANVAS),
		"Tools share the fixed player canvas and feet")
	expect(view.position == ArtPlacement.contact(_state["player"]["pos"]),
		"Work never shifts the logical ground contact")


func _work_cycles() -> void:
	var view: PlayerView = _world.get_node("Occupants/PlayerView")
	view.set_process(false)
	var verbs := PlayerArt.known_verbs()
	expect(verbs == GameData.sorted_names(Interact.DEFAULT_TICKS.keys()), "Every core verb has a work binding")
	# A tool pose keeps the density of the walk it interrupts. The work art is
	# native pixels at full scale - 4x4 at 1080p already, like the 32px walk's
	# 2x2 blocks at half scale - so it is used as authored, never halved.
	var walking := _screen_detail(PlayerArt.texture_path(&"walk_east", 0))
	for verb in verbs:
		for frame in int(PlayerFrames.COUNT[_strip(verb)]):
			var path := PlayerArt.texture_path(_strip(verb), frame)
			expect(is_equal_approx(_screen_detail(path), walking),
				"%s keeps the walking farmer's 4x4 art pixel: no detail jump" % path)
	for facing in [Player.SOUTH, Player.WEST, Player.NORTH, Player.EAST]:
		for verb in verbs:
			var at := _work_fixture(verb, facing)
			expect(Interact.verb_at(_state, at) == verb, "Real target offers %s" % verb)
			expect(PlayerFrames.COUNT[_strip(verb)] == 4, "Each verb's strip has four authored frames without aliases")
			for side in [Player.SOUTH, Player.NORTH]:
				expect(PlayerArt.pose(side, false, verb)["name"] == _strip(verb),
					"North/south work intentionally uses reviewed side-on art")
			var total := Interact.ticks_for(_state, at, verb)
			var instant := [&"water", &"reel", &"trade", &"ship"].has(verb)
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
			expect(view.playing() == &"walk_east" and not view.flipped(), "%s returns immediately to core-resolved walking" % verb)
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
		driver.stepping.connect(view.before_tick)
		driver.stepped.connect(view.after_tick)
		# A frame four ticks long, as a slow one is. Not 4x: these are the
		# day's verbs, and the night's speed no longer runs the day.
		driver._process(4.01 / GameData.TICK_HZ / driver._slowness())
		expect(driver.last_ticks == 4 and var_to_bytes(_state) == var_to_bytes(expected),
			"Four catch-up ticks of work observers preserve the exact Sim.advance state and tick count")
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
	expect(int(Farm.occupant(_state, repair_at)["hp"]) == int(GameData.BUILDINGS[&"workshop"]["hp"]),
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
	await _fishing_hold()


## A completed cast is no longer a player action, but still owns the rod pose.
func _fishing_hold() -> void:
	var view: PlayerView = _world.get_node("Occupants/PlayerView")
	view.set_process(false)
	_world.set_process(false)
	for facing in [Player.SOUTH, Player.WEST, Player.NORTH, Player.EAST]:
		var water := _work_fixture(&"fish", facing)
		_state["intent"]["interact"] = true
		for _i in Interact.ticks_for(_state, water, &"fish"):
			_work_tick(view, true)
			view._process(1.0 / GameData.TICK_HZ)
		expect(Fishing.is_casting(_state) and not Player.is_busy(_state),
			"Completed cast keeps its line without inventing another action")
		view._process(0.3)
		_work_frame(view, &"reel", 0, facing, 0.0)
		await _settle()
		await _shoot("fishing_wait_facing%d" % facing, "Waiting / rod stays in hand / facing %d" % facing)
		# Repeated rendering, including a pause, cannot advance the fishing timer.
		_work_frame(view, &"reel", 0, facing, 100.0)
		# A loaded/resumed waiting state recovers the pose without a cast cue.
		_state = _state.duplicate(true)
		view.show_state(_state)
		_work_frame(view, &"reel", 0, facing, 0.0)
		for _i in Fishing.ticks_left(_state):
			_work_tick(view, true)
			_work_frame(view, &"reel", 0, facing, 1.0 / GameData.TICK_HZ)
		expect(Fishing.is_biting(_state), "Real wait timer reaches the bite window")
		_reaction_check(view, &"bang", true)
		await _settle()
		await _shoot("fishing_bite_facing%d" % facing, "Bite / rod and warning together / facing %d" % facing)
		# **The bar** (task 0180): a press is judged against its marker, so
		# the fixture puts the whole bar under the green and asks for one hit
		# - the strike's judgement is the suites'; this watches the poses.
		_state["fishing"]["zone_at"] = 0
		_state["fishing"]["zone"] = int(GameData.FISHING["bar_units"])
		_state["fishing"]["needs"] = 1
		_state["intent"]["interact"] = true
		_work_tick(view, true)
		expect(not Fishing.is_casting(_state) and not Fishing.last_catch(_state).is_empty(),
			"A strike on the green still pays the actual catch")
		_work_frame(view, &"reel", 1, facing, 0.0)
		await _settle()
		await _shoot("fishing_catch_facing%d" % facing, "Catch / existing reel animation / facing %d" % facing)
		view._process(0.4)
		expect(view.playing() != &"reel", "Catch follow-through returns to an ordinary pose")
		for exit_kind in ["cancel", "move", "miss", "dusk"]:
			_work_fixture(&"reel", facing)
			_work_frame(view, &"reel", 0, facing, 0.0)
			match exit_kind:
				"cancel":
					_state["intent"]["cancel"] = true
				"move":
					_state["intent"]["move"] = [1, 0]
				"miss":
					_state["fishing"]["left"] = 1
				"dusk":
					_state["intent"]["sleep"] = true
			_work_tick(view, true)
			view._process(0.4)
			if exit_kind == "dusk":
				# Since task 0129 bedtime takes him off the farm altogether.
				expect(int(_state["phase"]) == Phases.PREPARATION and not view.is_drawn(),
					"Ending daylight removes the rod pose, and the farmer with it")
			else:
				expect(not Fishing.is_casting(_state) and view.playing() != &"reel",
					"%s ends the line and held rod together" % exit_kind)


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


func _reaction_check(view: PlayerView, kind: StringName, holding_rod := false) -> void:
	var before := var_to_bytes(_state)
	view._process(0.2)
	var body: Sprite2D = view.get_node("Body")
	var bubble: Sprite2D = view.get_node("ReactionBubble")
	var shadow: Sprite2D = view.get_node("Shadow")
	var name := StringName("react_%s" % kind)
	# The farmer keeps standing as they stand: the reaction frames show the
	# previous farmer, so only their glyph is drawn.
	var body_name: StringName = &"reel" if holding_rod else PlayerArt.pose(Player.facing(_state), false, &"")["name"]
	var glyph_path := PlayerArt.texture_path(name, 0)
	expect(var_to_bytes(_state) == before, "Held reaction cannot update state or its lifetime")
	expect(view.playing() == body_name and view.flipped() == (holding_rod and Player.facing(_state) == Player.EAST),
		"Reaction keeps the farmer's own idle pose, or the held fishing rod's facing")
	var body_path := body.texture.resource_path if body.texture != null else ""
	expect(body_path.begins_with(PlayerArt.DIR + String(body_name) + "_"),
		"A reaction never swaps the farmer for the older reaction body")
	var body_metadata: Dictionary = RasterArt.FRAMES.get(body_path, {})
	expect(_body_contact_is_valid(body) and body_metadata.has("pivot"),
		"Reaction body preserves its own canvas and planted feet")
	expect(view.position == ArtPlacement.contact(_state["player"]["pos"]), "Bubble clamping never moves the farmer")
	var metadata: Dictionary = RasterArt.FRAMES[glyph_path]
	expect(bubble.visible and bubble.texture.resource_path == glyph_path and bubble.region_rect == Rect2(metadata["bubble"]),
		"One separate glyph draws the exact source-owned crop")
	expect(body.material == view._work.head_material(_state, view.playing()),
		"Only the current tool head tint accompanies a glyph")
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


## **In bed from the switch to the morning** (task 0129). The night's own
## reactions are still chosen by the rules, but nobody is on the porch to
## wear them: no farmer, no shadow and no glyph.
func _asleep_check(view: PlayerView) -> void:
	view._process(0.2)
	var bubble: Sprite2D = view.get_node("ReactionBubble")
	var shadow: Sprite2D = view.get_node("Shadow")
	expect(House.asleep(_state) and not view.is_drawn() and not bubble.visible
		and not shadow.visible, "Asleep at night: nobody on the porch, and no glyph")


func _reactions() -> void:
	var view: PlayerView = _world.get_node("Occupants/PlayerView")
	view.set_process(false)
	_world.set_process(false)
	# The glyphs are native pixels at full scale: the 32px farmer's density.
	for kind in Reactions.KINDS:
		var glyph := PlayerArt.texture_path(StringName("react_%s" % kind), 0)
		expect(is_equal_approx(_screen_detail(glyph), 4.0),
			"%s draws each art pixel 4x4 at 1080p, like the farmer under it" % glyph)
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
	plot["growth"] = int(GameData.CROPS[crop]["growth_days"]) - 1
	_state["plots"][Grid.index(cell)] = plot
	SuiteKit.watered_mornings(_state)
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
	_reaction_check(view, &"bang", true)
	await _shoot("event_fishing_bite", "Actual fishing bite -> bang while keeping the rod in hand")
	# Existing night transition and damage/destruction priority.
	_reaction_fixture()
	expect(Phases.begin_preparation(_state) and Phases.start_waves(_state), "Existing phase transitions begin night")
	Reactions.tick(_state)
	expect(Reactions.now(_state) == &"bang", "Night boundary selects the existing bang")
	await _reaction_settle(view)
	_asleep_check(view)
	await _shoot("event_night_began", "Actual night_began -> bang, with nobody up to wear it")
	var fence := Vector2i(17, 9)
	_state["occupants"][Grid.index(fence)] = {"id": &"fence", "hp": 1}
	_state["tick"] = int(_state["tick"]) + 1
	# The event tick must not precede the reader's existing seen watermark.
	expect(Farm.damage(_state, fence, 1) == 1, "Actual damage destroys the isolated fence")
	Reactions.tick(_state)
	expect(Reactions.now(_state) == &"question", "Destruction reaction outranks the night bang")
	await _reaction_settle(view)
	_asleep_check(view)
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
			expect(view.playing() == _strip(verb) and not view.get_node("ReactionBubble").visible
				and body.material == view._work.head_material(_state, verb), "Reaction never obscures active/returning %s work" % verb)
			if kind == &"question":
				await _shoot("suppressed_work_%s" % verb, "Reaction waits: %s tool pose remains unobscured" % verb)
	_reaction_fixture()
	Reactions.show(_state, &"note")
	await _reaction_settle(view)
	_state["intent"]["move"] = [1, 0]
	Player.tick(_state)
	view._process(0.0)
	expect(view.playing() == &"walk_east" and not view.flipped() and not view.get_node("ReactionBubble").visible,
		"Walking hides the reaction without changing the state's remaining lifetime")
	await _shoot("suppressed_walk", "Moving east: authored walk, no reaction layer")
	_state["intent"]["move"] = [0, 0]
	view._process(0.0)
	expect(view.playing() == &"idle_east" and view.get_node("ReactionBubble").visible,
		"Stopping shows the still-active existing reaction")
	for _i in GameData.REACTION_TICKS:
		Reactions.tick(_state)
	view._process(0.0)
	expect(Reactions.now(_state) == &"" and view.playing() == &"idle_east"
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
	# On the real renderer a reaction adds its glyph and nothing else: every
	# pixel it changes lies inside the glyph's own box.
	if _capture:
		for kind in Reactions.KINDS:
			_reaction_fixture()
			Reactions.show(_state, kind)
			await _reaction_settle(view)
			var bubble: Sprite2D = view.get_node("ReactionBubble")
			await process_frame
			await RenderingServer.frame_post_draw
			var with_glyph := root.get_texture().get_image()
			var glyph_box := Rect2(bubble.get_global_transform_with_canvas() * Vector2.ZERO,
				bubble.region_rect.size * bubble.scale).grow(1.0)
			bubble.visible = false
			await process_frame
			await RenderingServer.frame_post_draw
			var without := root.get_texture().get_image()
			var inside := 0
			var outside := 0
			for y in with_glyph.get_height():
				for x in with_glyph.get_width():
					if with_glyph.get_pixel(x, y) != without.get_pixel(x, y):
						if glyph_box.has_point(Vector2(x, y) + Vector2(0.5, 0.5)):
							inside += 1
						else:
							outside += 1
			expect(inside > 0 and outside == 0, "The %s glyph changes only its own box; the farmer is untouched" % kind)
			view._process(0.0)
			await _shoot("glyph_only_%s" % kind, "Renderer: %s glyph beside the farmer's head" % kind)
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
			if node.texture.resource_path.get_file() in ["tree.png", "tree_b.png"]:
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
	expect(_body_contact_is_valid(body), "Farmer retains its accepted source geometry and ground pivot")
	var light := ArtPlacement.emission(&"house", Vector2(320, 96), &"light", Vector2.ZERO, Vector2i(3,3))
	var smoke := ArtPlacement.emission(&"house", Vector2(320, 96), &"smoke", Vector2.ZERO, Vector2i(3,3))
	expect(light == Vector2(318, 114) and smoke == Vector2(382, 48), "Lamp/chimney anchor follows the enlarged legacy fixture drawing")


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
			sprite.scale = Vector2.ONE * float(metadata.get("draw_scale", 1.0))
			sprite.position = Vector2(32 + i % 7 * 64, 80 + i / 7 * 58)
			layer.add_child(sprite)
			expect(sprite.texture != null, "Every contact frame has an actual texture")
		await _shoot("animation_frames_%02d" % page, "Committed player / walker frames at native scale; page %d" % page)
		for sprite in layer.get_children():
			sprite.modulate = Color.BLACK
		await _shoot("silhouettes_%02d" % page, "Native alpha silhouettes: committed actors and pilot landmarks")
	layer.queue_free()
