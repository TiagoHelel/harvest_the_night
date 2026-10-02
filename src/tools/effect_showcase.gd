extends "res://src/tools/enemy_showcase.gd"

## Real renderer, actual core contacts and side-by-side unobserved controls.
var _fx: Particles
var _juice: Juice
var _saved_options: Dictionary = {}


func _run() -> void:
	_folder = "res://implementation/shots/sprites/0017/effects/"
	await _setup()
	_fx = Particles.new()
	_world.add_child(_fx)
	_fx.set_process(false)
	var overlay := CanvasLayer.new()
	overlay.layer = 2
	root.add_child(overlay)
	_juice = Juice.new()
	overlay.add_child(_juice)
	_juice.set_process(false)
	_juice._hit_stop_on = false
	var options := root.get_node_or_null("Settings")
	if options != null:
		for key in [&"video/max_particles",&"a11y/particle_density",&"a11y/flashing",&"a11y/screen_shake"]:
			_saved_options[key] = options.get_value(key)
		options.set_value(&"video/max_particles",420,false)
		options.set_value(&"a11y/particle_density",1.0,false)
		options.set_value(&"a11y/flashing",true,false)
		options.set_value(&"a11y/screen_shake",0.0,false)
	await _scene_order()
	await _forms_gallery(false)
	await _forms_gallery(true)
	await _firing()
	await _chimney()
	await _working()
	await _crowd()
	await _accessibility()
	await _density_controls()
	await _performance()
	if options != null:
		for key in _saved_options:
			options.set_value(key,_saved_options[key],false)
	print("EFFECT SHOWCASE: %d checks, %d failed" % [_checks,_failed])
	quit(1 if _failed>0 else 0)


func _scene_order() -> void:
	# Match Main.tscn: Particles already is a child when WorldView enters.
	var staged: WorldView = load("res://scenes/World.tscn").instantiate()
	var child := Particles.new()
	staged.add_child(child)
	root.add_child(staged)
	staged.set_process(false)
	child.set_process(false)
	child.show_state(_blank())
	child._forms.emit(&"dust",Vector2(180,145))
	child._forms.advance(0.0,child)
	expect(child._forms.ground_parent==staged._ground_traps and child._forms.sprites[0].get_parent()==staged._ground_traps,"Actual Main child/parent ready order still binds ground effects below actors")
	child.queue_free()
	await process_frame
	expect(staged._ground_traps.get_child_count()==0,"Removing the emitter releases its borrowed ground-layer children")
	staged.queue_free()
	await process_frame
	_world._camera.make_current()


func _settle() -> void:
	await super._settle()
	_fx.show_state(_state)
	_juice.show_state(_state,_world,null)
	_fx.set_cap(420)
	_fx.set_density(1.0)
	_fx.set_motion(true)
	_fx._smoke_due = 100.0
	_fx._process(0.0)
	_juice._process(0.0)
	_lighting._process(0.0)


func _observers_before() -> void:
	var bytes := var_to_bytes(_state)
	_world.before_tick(_state)
	_view.before_tick(_state)
	_fx.before_tick(_state)
	expect(var_to_bytes(_state)==bytes,"All FX/contact snapshots are read-only")


func _observers_after(control: Dictionary) -> void:
	var bytes := var_to_bytes(_state)
	_world.after_tick(_state)
	_view.after_tick(_state)
	_fx.after_tick(_state)
	expect(var_to_bytes(_state)==bytes and var_to_bytes(control)==bytes,"Core/save bytes match unobserved control after effect emission")
	expect(_fx._forms._entities.is_empty() and _fx._forms._guns.is_empty(),"Borrowed contact/reload snapshots are released")
	_fx._forms.advance(0.0,_fx)
	_world._process(0.0)
	_view._process(0.0)
	_juice._process(0.0)
	_lighting._process(0.0)


func _core_tick(towers_only: bool = false) -> void:
	var control := _state.duplicate(true)
	_observers_before()
	if towers_only:
		_state["tick"] = int(_state["tick"])+1
		control["tick"] = int(control["tick"])+1
		Towers.tick(_state)
		Towers.tick(control)
	else:
		Sim.tick(_state)
		Sim.tick(control)
	_observers_after(control)


func _forms_gallery(night: bool) -> void:
	_state = _blank(night)
	await _settle()
	_fx._forms.reset()
	var families: Array = PixelEffects.COUNTS.keys()
	for family in families:
		for frame in int(PixelEffects.COUNTS[family]):
			var path := PixelEffects.path_for(family,frame)
			var metadata: Dictionary = RasterArt.FRAMES.get(path,{})
			expect(not metadata.is_empty() and not bool(metadata["loop"]),"All actual effect frames are owned one-shots")
			expect(ResourceLoader.exists(path),"Every required effect PNG is importable")
	for phase in 4:
		_fx._forms.reset()
		for i in families.size():
			var family: StringName = families[i]
			_fx._forms.emit(family,Vector2(100+i*48,145))
			_fx._forms.records[-1]["age"] = mini(phase,int(PixelEffects.COUNTS[family])-1)*PixelEffects.seconds(family)
		var bytes := var_to_bytes(_state)
		_fx._forms.advance(0.0,_fx)
		for i in families.size():
			var family: StringName = families[i]
			var frame := mini(phase,int(PixelEffects.COUNTS[family])-1)
			var sprite := _fx._forms.sprites[i]
			var path := PixelEffects.path_for(family,frame)
			expect(sprite.texture.resource_path==path,"Runtime selects the actual authored frame: "+path)
			expect(sprite.offset==-Vector2(RasterArt.FRAMES[path]["pivot"]) and sprite.position==Vector2(100+i*48,145),"Raster origin remains fixed throughout expansion/dissipation")
			if _capture:
				expect(sprite.texture.get_image().get_data()==Image.load_from_file(ProjectSettings.globalize_path(path)).get_data(),"Imported texture pixels match the deterministic PNG")
		expect(var_to_bytes(_state)==bytes,"Effect frame playback cannot change state")
		await _shoot("gallery_%d_%d"%[int(night),phase],"Muzzle / impact / flame / smoke / dust / splash / flare - authored phase%d"%phase)
		if phase==1 and _capture:
			await _rendered_forms(night)
	_fx._forms.advance(2.0,_fx)
	expect(_fx._forms.records.is_empty(),"All seven one-shots expire without looping")
	await _shoot("gallery_%d_expired"%int(night),"All seven one-shots expired; no lingering glare")


func _rendered_forms(night: bool) -> void:
	var bytes := var_to_bytes(_state)
	var shown: Array[Sprite2D] = []
	for sprite in _fx._forms.sprites:
		if sprite.visible:
			shown.append(sprite)
			sprite.hide()
	await process_frame
	await RenderingServer.frame_post_draw
	var without := root.get_texture().get_image()
	for sprite in shown:
		sprite.show()
	await process_frame
	await RenderingServer.frame_post_draw
	var with_forms := root.get_texture().get_image()
	var report := []
	for sprite in _fx._forms.sprites:
		if not sprite.visible:
			continue
		var source := sprite.texture.get_image()
		var origin := sprite.get_global_transform_with_canvas()*sprite.offset
		var changed := 0
		var opaque := 0
		var warm := 0
		var luma := 0.0
		for y in source.get_height():
			for x in source.get_width():
				var pixel := source.get_pixel(x,y)
				if pixel.a==0.0:
					continue
				opaque += 1
				var at := Vector2i(origin)+Vector2i(x,y)
				var drawn := with_forms.get_pixelv(at)
				if drawn!=without.get_pixelv(at):
					changed += 1
				if drawn.r>drawn.b*1.25 and drawn.r>drawn.g*1.03:
					warm += 1
				luma += drawn.r*0.299+drawn.g*0.587+drawn.b*0.114
		expect(changed>0 and changed<=opaque,"Actual source pixels appear in the native renderer: "+sprite.texture.resource_path)
		if "muzzle" in sprite.texture.resource_path or "flame_" in sprite.texture.resource_path or "flare_" in sprite.texture.resource_path:
			expect(warm>0,"Actual fire/flash pixels stay warm under both real light states")
		if "smoke" in sprite.texture.resource_path:
			expect(luma/maxi(opaque,1)<0.55,"Actual smoke stays subdued under both real light states")
		report.append({"path":sprite.texture.resource_path,"source_pixels":opaque,"changed_native_pixels":changed,"warm_pixels":warm,"mean_luma":luma/maxi(opaque,1)})
	expect(var_to_bytes(_state)==bytes,"Actual hide/show render comparison changes no simulation/save byte")
	var file := FileAccess.open(_folder+"rendered-forms-%d.json"%int(night),FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))


func _firing() -> void:
	_state = _blank(true)
	_state["phase"] = Phases.DAY
	_state["tech_owned"] = [&"true sights",&"long barrels",&"oiled works"]
	for row in 3:
		for col in 3:
			var cell := Vector2i(7+col*5,5+row*4)
			var kind: StringName = [&"gun_tower",&"flame_tower",&"mortar"][row]
			expect(Building.place(_state,kind,cell),"Real tower can be placed")
			for level in col:
				expect(Building.upgrade(_state,cell),"Real tower upgrade follows the authored level")
			Entities.spawn(_state,&"tank",cell+Vector2i(2,0))
	_state["phase"] = Phases.NIGHT
	await _settle()
	_core_tick(true)
	var records := _fx._forms.records.duplicate(true)
	var muzzles := 0
	for idx in _fx._gun_cells():
		var on: Dictionary = _state["occupants"][int(idx)]
		if int(on.get("reload",0))<=0:
			continue
		for muzzle in WorldView.tower_muzzles(on,Grid.cell(int(idx))):
			var matched := false
			for record in records:
				matched = matched or (record["at"]==muzzle and record["family"]==(&"flame" if on["id"]==&"flame_tower" else &"muzzle"))
			expect(matched,"Actual shot emits at every measured levelled muzzle")
			muzzles += 1
	expect(muzzles>=9,"All nine real towers fire in the fixture")
	await _shoot("towers_contact","Actual tower shots / levels1-3 / exact authored outlets")
	var count := _fx._forms.records.size()
	for frame in 8:
		_fx._process(0.0)
	expect(_fx._forms.records.size()==count,"Eight render frames cannot repeat a fixed-tick muzzle")
	_fx.after_tick(_state)
	expect(_fx._forms.records.size()==count,"Duplicate after-tick observation cannot replay a muzzle")
	for phase in 3:
		_fx._forms.advance(0.07,_fx)
		await _shoot("towers_after%d"%phase,"Localized muzzle dissipation without repeated render emissions")


func _chimney() -> void:
	for night in [false,true]:
		_state = _blank(night)
		await _settle()
		_fx._smoke_due = 0.0
		_fx._process(0.0)
		var corner := Farm.house_centre(_state)-Vector2i.ONE
		var at := ArtPlacement.emission(&"house",Vector2(corner)*GameData.TILE_SIZE,&"smoke",Vector2.ZERO)
		var count := 0
		for record in _fx._forms.records:
			if record["family"]==&"smoke":
				count += 1
				expect(record["at"]==at,"House smoke starts at the source-measured chimney")
		expect(count==1,"Nine logical house cells emit only one raster smoke puff")
		_fx._forms.advance(0.14,_fx)
		await _shoot("chimney_%d"%int(night),"One subdued puff at the measured chimney / nine cells remain one building")


func _working() -> void:
	for verb in [&"harvest",&"water",&"chop",&"mine",&"fish"]:
		_state = _blank()
		var cell := Vector2i(14,9)
		var idx := Grid.index(cell)
		var terrain: PackedByteArray = _state["terrain"]
		if verb in [&"harvest",&"water"]:
			terrain[idx] = Farm.Terrain.SOIL
			var crop: StringName = Farming.seeds()[0]
			var plot := Farming.EMPTY_PLOT.duplicate()
			plot["crop"] = crop
			plot["growth"] = int(GameData.CROPS[crop]["growth_ticks"]) if verb==&"harvest" else 0
			_state["plots"][idx] = plot
			_state["water_can"] = GameData.WATER_CAN_CAPACITY
		elif verb==&"fish":
			for y in range(-2,1):
				for x in range(-1,2):
					terrain[Grid.index(cell+Vector2i(x,y))] = Farm.Terrain.WATER
		else:
			_state["occupants"][idx] = {"id":&"tree" if verb==&"chop" else &"rock"}
		_state["terrain"] = terrain
		_state["grid_version"] = int(_state["grid_version"])+1
		_state["player"]["pos"] = [14*Player.SUBTILE+Player.SUBTILE/2,10*Player.SUBTILE+Player.SUBTILE/2]
		_state["player"]["facing"] = Player.NORTH
		await _settle()
		_state["intent"]["interact"] = true
		var family: StringName = &"splash" if verb in [&"water",&"fish"] else &"dust"
		var found := false
		for tick in 200:
			_core_tick()
			for record in _fx._forms.records:
				if record["family"]==family:
					found = true
			if found:
				break
		expect(found,"Actual completed work emits its matching effect: "+str(verb))
		if found:
			var at := (Vector2(cell)+Vector2(0.5,0.7))*GameData.TILE_SIZE
			expect(_fx._forms.records[-1]["at"]==at,"Work effect is anchored to the actual target cell")
			await _shoot("work_%s_contact"%verb,"Actual completed %s / localized %s"%[verb,family])
			_fx._forms.advance(PixelEffects.seconds(family),_fx)
			await _shoot("work_%s_peak"%verb,"Actual %s effect peak at unchanged target"%verb)
			for sprite in _fx._forms.sprites:
				if sprite.visible and sprite.texture.resource_path==PixelEffects.path_for(family,1):
					expect(sprite.get_parent()==_world._ground_traps,"Ground dust/water draw below the farmer and neighboring actors")
			if _capture:
				await _work_occlusion()


func _work_occlusion() -> void:
	var body: Sprite2D = _view.get_node("Body")
	var source := body.texture.get_image()
	var origin := body.get_global_transform_with_canvas()*body.offset
	await process_frame
	await RenderingServer.frame_post_draw
	var with_forms := root.get_texture().get_image()
	var shown: Array[Sprite2D] = []
	for sprite in _fx._forms.sprites:
		if sprite.visible:
			shown.append(sprite)
			sprite.hide()
	await process_frame
	await RenderingServer.frame_post_draw
	var without := root.get_texture().get_image()
	var covered := 0
	for y in source.get_height():
		for x in source.get_width():
			if source.get_pixel(x,y).a!=1.0:
				continue
			var at := Vector2i(origin)+Vector2i(x,y)
			if with_forms.get_pixelv(at)!=without.get_pixelv(at):
				covered += 1
	for sprite in shown:
		sprite.show()
	expect(covered==0,"Actual renderer preserves all opaque farmer/tool pixels under ground work effects")


func _crowd() -> void:
	_state = _blank(true)
	for i in 75:
		Entities.spawn(_state,EnemyMotion.FAMILIES[i%4],Vector2i(5+i%15,6+i/15*2))
	await _settle()
	var burning_control := _state.duplicate(true)
	_observers_before()
	_state["tick"] = int(_state["tick"])+1
	burning_control["tick"] = int(burning_control["tick"])+1
	for id in Entities.ids(_state):
		Combat.set_alight(_state,int(id),1,300)
		Combat.set_alight(burning_control,int(id),1,300)
	_observers_after(burning_control)
	_fx._forms.advance(0.14,_fx)
	await _shoot("busy_ignition","75 real ignitions / at most24 warm flame forms / no additive wash")
	_fx._smoke_due = 0.0
	for frame in 30:
		_fx._process(1.0/60.0)
	expect(_fx.live()<=_fx.cap() and _fx._forms.records.size()<=24 and _fx._forms.sprites.size()<=24,"Busy burning wave shares the hard ceiling")
	expect(_lighting.burning_lights().size()<=Lighting.MAX_BURNING_LIGHTS,"Dense burning wave cannot allocate one additive halo per enemy")
	var lights := _lighting.burning_lights()
	for i in lights.size():
		for j in range(i+1,lights.size()):
			expect(lights[i].distance_to(lights[j])>=Lighting.BURNING_RADIUS*GameData.TILE_SIZE*1.6,"Neighboring flames share non-stacking halos")
	await _shoot("busy_burning","75 real burning enemies / bounded warm flames and tiny embers")
	# Use the actual ability and its real damage/slow, with an unobserved twin.
	_state["player"]["pos"] = [12*Player.SUBTILE+Player.SUBTILE/2,10*Player.SUBTILE+Player.SUBTILE/2]
	var control := _state.duplicate(true)
	_observers_before()
	_state["tick"] = int(_state["tick"])+1
	control["tick"] = int(control["tick"])+1
	Ability.use(_state)
	Ability.use(control)
	_observers_after(control)
	var flare := false
	for record in _fx._forms.records:
		flare = flare or record["family"]==&"flare"
	expect(flare,"Actual successful ability emits one localized flare")
	await _shoot("busy_flare","Real flare, real casualties and surviving slowed enemies")
	var ids := Entities.ids(_state)
	control = _state.duplicate(true)
	_observers_before()
	_state["tick"] = int(_state["tick"])+1
	control["tick"] = int(control["tick"])+1
	for id in ids:
		Combat.hit(_state,int(id),9999,&"impact")
		Combat.hit(control,int(id),9999,&"impact")
	_observers_after(control)
	expect(_juice.corpses_showing()==0,"Juice does not overlay flattened bodies on authored WorldView deaths")
	expect(_world._enemy_deaths._cues.size()==24 and _fx._forms.records.size()==24,"Simultaneous deaths stay within both independent view limits")
	_fx._smoke_due = 100.0
	_fx._process(0.0)
	for phase in 4:
		await _shoot("deaths_%d"%phase,"Simultaneous deaths / authored corpses and bounded ground dust / phase%d"%phase)
		_fx._forms.advance(0.12,_fx)
		_world._process(0.12)
	_fx._process(2.0)
	_world._process(2.0)
	expect(_fx.live()==0 and _world._enemy_deaths._cues.is_empty(),"Expired effects/deaths release all live view records")
	await _shoot("deaths_expired","All simultaneous death forms and pixels expired")


func _accessibility() -> void:
	_state = _blank()
	await _settle()
	var options := root.get_node_or_null("Settings")
	expect(options!=null,"Actual live Settings autoload exists")
	if options==null:
		return
	options.set_value(&"video/max_particles",40,false)
	expect(_fx.cap()==40 and _fx._forms.limit==10 and _fx._left.size()==30,"Live cap setting reserves one shared budget")
	options.set_value(&"a11y/particle_density",0.5,false)
	for i in 20:
		_fx._forms.emit(&"splash",Vector2(90+i*10,145),Vector2(2,-4))
	expect(_fx._forms.records.size()==10,"Half density accepts half the isolated emission requests")
	options.set_value(&"a11y/flashing",false,false)
	expect(_lighting.quality()<=Lighting.STEADY,"Live flashing setting also stops the shared light wobble")
	var at: Vector2 = _fx._forms.records[0]["at"]
	_fx._forms.advance(0.15,_fx)
	expect(_fx._forms.records[0]["at"]==at and _fx._forms.sprites[0].texture.resource_path==PixelEffects.path_for(&"splash",0),"Steady accessibility holds the first pose and suppresses drift")
	await _shoot("a11y_steady_half","Actual live Settings / half density / steady silhouettes without drift")
	options.set_value(&"a11y/particle_density",0.0,false)
	_fx._process(0.4)
	expect(_fx.live()==0,"Live density zero immediately hides forms and cheap particles")
	await _shoot("a11y_off","Actual live Settings / density zero / no effect remnants")
	options.set_value(&"a11y/particle_density",1.0,false)
	options.set_value(&"video/max_particles",0,false)
	expect(not _fx._forms.emit(&"flare",Vector2.ZERO) and _fx.live()==0,"Zero cap refuses all effect forms")
	options.set_value(&"video/max_particles",420,false)
	options.set_value(&"a11y/flashing",true,false)
	options.set_value(&"a11y/particle_density",1.0,false)
	_fx._forms.emit(&"muzzle",Vector2(200,145))
	_fx._forms.advance(0.0,_fx)
	var other := _blank()
	_fx.show_state(other)
	expect(_fx.live()==0 and _fx._forms._entities.is_empty(),"State replacement clears prior event identities and pixels")
	await _shoot("a11y_reset","State replacement clears old one-shots")


func _density_controls() -> void:
	var hashes: Array[int] = []
	for density in [1.0,0.5,0.0]:
		_state = _blank(true)
		_state["phase"] = Phases.DAY
		expect(Building.place(_state,&"gun_tower",Vector2i(14,9)),"Density control builds a real firing tower")
		_state["phase"] = Phases.NIGHT
		for i in 12:
			Entities.spawn(_state,&"tank",Vector2i(13+i%4,6+i/4))
		await _settle()
		_fx.set_density(density)
		for tick in 90:
			_core_tick()
			var bytes := var_to_bytes(_state)
			_fx._process(1.0/30.0)
			expect(var_to_bytes(_state)==bytes and _fx.live()<=_fx.cap(),"Rendered FX/density cannot touch a core/save byte or exceed the shared cap")
		hashes.append(State.hash_of(_state))
	expect(hashes[0]==hashes[1] and hashes[1]==hashes[2],"Actual identical 90-tick nights retain equal simulation hashes at full/half/off density")


func _performance() -> void:
	_state = _blank(true)
	for i in 100:
		var id := Entities.spawn(_state,&"tank",Vector2i(5+i%15,6+i/15))
		Combat.set_alight(_state,id,1,300)
	await _settle()
	var bytes := var_to_bytes(_state)
	var samples: Array[int] = []
	for frame in 240:
		var started := Time.get_ticks_usec()
		if frame%5==0:
			for i in 24:
				_fx._forms.emit(&"flame",Vector2(80+i*8,145))
		_fx._process(1.0/60.0)
		samples.append(Time.get_ticks_usec()-started)
		expect(_fx.live()<=_fx.cap() and _fx._forms.sprites.size()<=24,"Saturated reusable FX pool retains a bounded allocation count")
	samples.sort()
	var p95 := samples[int(samples.size()*0.95)]
	expect(p95<16000,"100 burning actors + saturated raster/pixel FX update fits the 16ms view frame budget")
	expect(var_to_bytes(_state)==bytes,"Saturated view benchmark changes no core/save byte")
	print("EFFECT PERF: 100 burning actors, 24 raster slots, 420 shared limit, p95=%dus (budget16000us)"%p95)
	if _capture:
		var file := FileAccess.open(_folder+"effect-perf.json",FileAccess.WRITE)
		file.store_string(JSON.stringify({"actors":100,"raster_slots":24,"shared_limit":420,"samples":240,"view_update_p95_us":p95,"budget_us":16000,"includes_gpu":false,"state_bytes_unchanged":var_to_bytes(_state)==bytes},"\t"))
