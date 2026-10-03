extends "res://src/tools/shot.gd"

## Paired lighting on one immutable farm, with actual native renderer probes.
var _world: WorldView
var _farmer: PlayerView
var _lamps: Lighting
var _relight: Relight
var _fx: Particles
var _switch: Transition
var _hud: Control
var _state: Dictionary
var _capture := true
var _folder := "res://implementation/shots/sprites/0019/atmosphere/"
var _checks := 0
var _images: Dictionary = {}
var _settings: Node
var _saved_settings: Dictionary = {}


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
			_folder = "res://"+arg.substr(6).trim_suffix("/")+"/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_folder))
	root.size = Vector2i(480,270)
	root.content_scale_size = Vector2i(480,270)
	_settings = root.get_node_or_null("Settings")
	if _settings!=null:
		for key in [&"video/lights",&"a11y/flashing",&"a11y/particle_density",&"video/max_particles",&"video/transition_seconds",&"gameplay/skip_transition"]:
			_saved_settings[key] = _settings.get_value(key)
		_settings.set_value(&"video/lights",Lighting.STEADY,false)
		_settings.set_value(&"a11y/flashing",true,false)
		_settings.set_value(&"a11y/particle_density",1.0,false)
		_settings.set_value(&"video/max_particles",420,false)
		_settings.set_value(&"video/transition_seconds",0.0,false)
		_settings.set_value(&"gameplay/skip_transition",false,false)
	seed(SPARK_SEED)
	_relight = Relight.new()
	_relight.name = "Relight"
	root.add_child(_relight)
	_world = load("res://scenes/World.tscn").instantiate()
	root.add_child(_world)
	_world.set_process(false)
	_farmer = _world.get_node("Occupants/PlayerView")
	_farmer.set_process(false)
	_fx = Particles.new()
	_world.add_child(_fx)
	_fx.set_process(false)
	var light_layer := CanvasLayer.new()
	light_layer.layer = 2
	root.add_child(light_layer)
	_lamps = Lighting.new()
	light_layer.add_child(_lamps)
	_lamps.set_process(false)
	_lamps.set_quality(Lighting.STEADY)
	_switch = Transition.new()
	light_layer.add_child(_switch)
	_switch.set_process(false)
	var ui_layer := CanvasLayer.new()
	ui_layer.layer = 3
	root.add_child(ui_layer)
	_hud = Control.new()
	_hud.theme = UiKit.theme()
	ui_layer.add_child(_hud)
	var day := DayHud.new()
	_hud.add_child(day)
	var night := NightHud.new()
	_hud.add_child(night)
	await process_frame
	_state = State.create(SEED)
	_a_defended_farm(_state)
	_state["night"] = 1
	(state_held()).clear()
	for resource in GameData.RESOURCES:
		state_held()[resource] = 999
	_state["player"]["action"] = {}
	_state["player"]["pos"] = [18*Player.SUBTILE,8*Player.SUBTILE]
	_state["intent"]["move"] = [0,0]
	# Fixed specimen positions: nothing walks or attacks while ramps are paired.
	for i in 4:
		var kind: StringName = [&"walker",&"runner",&"tank",&"breaker"][i]
		Entities.spawn(_state,kind,Vector2i(11+i*3,10))
	for node in [day,night]:
		node.show_state(_state)
	for phase in ["dawn","day","dusk","night"]:
		await _phase(phase)
		await _capture_view("farm_"+phase)
	await _phase("night")
	_lamps.set_quality(Lighting.OFF)
	await _capture_view("farm_night_lights_off")
	_lamps.set_quality(Lighting.STEADY)
	await _window_pixels()
	await _transitions()
	await _emission_gallery()
	await _accessibility()
	await _palette_probes()
	if _settings!=null:
		for key in _saved_settings:
			_settings.set_value(key,_saved_settings[key],false)
	print("ATMOSPHERE SHOWCASE: %d checks, %d failed" % [_checks,_failed])
	quit(1 if _failed else 0)


func state_held() -> Dictionary:
	return _state["held"]


func _phase(phase: String) -> void:
	_state["phase"] = Phases.NIGHT if phase=="night" else Phases.DAY
	_state["day_tick"] = 0 if phase=="dawn" else GameData.DAY_TICKS if phase=="dusk" else GameData.DAY_TICKS/2
	var before := var_to_bytes(_state)
	_world.show_state(_state)
	_farmer.show_state(_state)
	_lamps.show_state(_state)
	_fx.show_state(_state)
	_switch.show_state(_state,_world)
	_world._process(0.0)
	_world.skip_transition()
	_world._light_for_phase(0.0)
	_world.look_at_cell(Vector2i(18,8))
	_farmer._process(0.0)
	_lamps._process(0.0)
	_switch._process(0.0)
	await process_frame
	await process_frame
	expect(not _world.is_transitioning(),"Paired farm captures wait for the actual ramp endpoint")
	expect(var_to_bytes(_state)==before,"Lighting/placement observers preserve complete core/save bytes")


func _capture_view(name: String) -> Image:
	# These observers process automatically in Main, but this fixture advances
	# them manually. Refresh them after every phase/ramp/quality change too.
	_lamps._process(0.0)
	_switch._process(0.0)
	if not _capture:
		return null
	var before := var_to_bytes(_state)
	await process_frame
	await RenderingServer.frame_post_draw
	var picture := root.get_texture().get_image()
	expect(picture!=null and picture.get_size()==Vector2i(480,270),"Actual capture uses the native viewport")
	if picture!=null:
		expect(picture.save_png(ProjectSettings.globalize_path(_folder+name+".png"))==OK,"Native evidence saved: "+name)
		_images[name] = picture
	expect(var_to_bytes(_state)==before,"Capture changes no state byte")
	return picture


func _palette_probes() -> void:
	_hud.hide()
	_lamps.set_quality(Lighting.OFF)
	var probes := Node2D.new()
	probes.z_index = 100
	_world.add_child(probes)
	var names: Array = GameData.sorted_names(PaletteData.COLOURS.keys())
	var rectangles: Array[ColorRect] = []
	var transform := _world.get_viewport().get_canvas_transform().affine_inverse()
	for i in names.size():
		var patch := ColorRect.new()
		patch.position = transform*Vector2(12+(i%7)*66,36+(i/7)*32)
		patch.size = Vector2(24,24)
		patch.color = PaletteData.COLOURS[names[i]]
		probes.add_child(patch)
		rectangles.append(patch)
	await _phase("day")
	var day := await _capture_view("palette_day")
	await _phase("night")
	var night := await _capture_view("palette_night")
	if _capture and day!=null and night!=null:
		var report := []
		for i in names.size():
			var at := Vector2i(24+(i%7)*66,48+(i/7)*32)
			var by_day := day.get_pixelv(at)
			var by_night := night.get_pixelv(at)
			report.append({"name":names[i],"day":by_day.to_html(),"night":by_night.to_html(),"day_luma":_brightness(by_day),"night_luma":_brightness(by_night)})
			if names[i] in [&"bone",&"bone_dark",&"flame_hot",&"gold_light",&"skin_light"]:
				expect(_brightness(by_night)<_brightness(by_day)*0.65,"Non-emissive pale/hot palette material must not glow: "+str(names[i]))
			if names[i] in [&"grass",&"soil",&"stone",&"wood",&"bone"]:
				expect(by_night.b>by_night.r and by_night.b>by_night.g,"Night material has a cool blue/violet cast: "+str(names[i]))
		var file := FileAccess.open(_folder+"palette-measurements.json",FileAccess.WRITE)
		file.store_string(JSON.stringify(report,"\t"))
	probes.free()


func _brightness(colour: Color) -> float:
	return colour.r*0.299+colour.g*0.587+colour.b*0.114


func _window_pixels() -> void:
	await _phase("night")
	var lit := await _capture_view("window_cores_steady")
	_lamps.set_quality(Lighting.OFF)
	var dark := await _capture_view("window_cores_off")
	if _capture:
		var house: Sprite2D
		for sprite in _world._sprites:
			if sprite.texture.resource_path=="res://sprites/buildings/house.png":
				house = sprite
		expect(house!=null,"Whole source-owned house is present")
		if house!=null:
			var metadata: Dictionary = RasterArt.FRAMES[house.texture.resource_path]
			for window in metadata["windows"]:
				var at := Vector2i(house.get_global_transform_with_canvas()*(house.offset+Vector2(window)))
				expect(lit.get_pixelv(at).is_equal_approx(PaletteData.COLOURS[&"flame_hot"]),"Warm glass core aligns with measured native window: "+str(at))
				expect(dark.get_pixelv(at)!=lit.get_pixelv(at),"Lights off removes actual glass emission")
	_lamps.set_quality(Lighting.STEADY)


func _transitions() -> void:
	for into_night in [true,false]:
		await _phase("dusk" if into_night else "night")
		_state["phase"] = Phases.NIGHT if into_night else Phases.DAY
		_state["day_tick"] = 0
		var before := var_to_bytes(_state)
		_world._light_for_phase(0.0)
		_switch._process(0.0)
		expect(_switch._day_actors.size()>0 and _switch._wakers.size()==8,"Pivot metadata identifies all day animals and eight actual towers")
		for i in 5:
			if i>0:
				_world._light_for_phase(_world.transition_seconds()/4.0)
			_switch._process(0.0)
			for animal in _switch._day_actors:
				expect(is_equal_approx(animal.modulate.a,1.0-_switch._nightness()),"Day animal follows the actual fade without changing occupancy")
			for tower in _switch._wakers:
				expect(tower.modulate.r<=1.4501,"Transition flare never blankets the tower silhouette")
			await _capture_view("transition_%s_%02d"%["night" if into_night else "dawn",i])
			expect(var_to_bytes(_state)==before,"Transition never writes to any core/save field")
		expect(not _world.is_transitioning(),"Both transition directions finish exactly")
	# Reverse a real partial fade: every ramp field must be continuous.
	await _phase("dusk")
	_state["phase"] = Phases.NIGHT
	_world._light_for_phase(_world.transition_seconds()/4.0)
	var prior := _relight.settings()
	var prior_nightness := _world.visual_nightness()
	_state["phase"] = Phases.DAY
	_world._light_for_phase(0.0)
	var now := _relight.settings()
	expect(is_equal_approx(prior_nightness,_world.visual_nightness()),"Interrupted fade also preserves day-animal opacity")
	for field in ["tint","lift","saturation","warm_keep","warm_edge"]:
		expect(prior[field]==now[field],"Interrupted fade preserves the actual current ramp: "+field)
	await _capture_view("transition_reversed")


func _emission_gallery() -> void:
	_hud.hide()
	_lamps.set_quality(Lighting.OFF)
	var materials := Node2D.new()
	materials.z_index = 99
	_world.add_child(materials)
	var inverse := _world.get_viewport().get_canvas_transform().affine_inverse()
	var paths := ["sprites/actors/idle_south_0.png","sprites/props/cow.png","sprites/props/chicken.png","sprites/crops/wheat_3.png","sprites/crops/corn_3.png","sprites/crops/carrot_3.png"]
	for i in paths.size():
		var sprite := Sprite2D.new()
		sprite.texture = load("res://"+paths[i])
		sprite.centered = false
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.position = inverse*Vector2(52+i*66,110)
		sprite.offset = -Vector2(RasterArt.FRAMES[sprite.texture.resource_path]["pivot"])
		materials.add_child(sprite)
	for night in [false,true]:
		await _phase("night" if night else "day")
		_fx._forms.reset()
		var families: Array = GameData.sorted_names(PixelEffects.COUNTS.keys())
		for i in families.size():
			_fx._forms.emit(families[i],inverse*Vector2(36+i*66,200))
		_fx._forms.advance(0.0,_fx)
		for sprite in _fx._forms.sprites:
			if not sprite.visible:
				continue
			var family := StringName(sprite.texture.resource_path.get_file().get_slice("_",0))
			var warm := family in PixelEffects.WARM_FAMILIES
			expect((sprite.get_parent()==_fx._warm)==warm,"Semantic fire layer contains only actual warm forms: "+str(family))
			var record := _fx._forms.records[_fx._forms.sprites.find(sprite)]
			var at := sprite.get_global_transform_with_canvas()*Vector2.ZERO
			var expected := _fx.get_global_transform_with_canvas()*(record["at"] as Vector2)
			expect(at.is_equal_approx(expected),"Emission layer keeps actual camera/contact transform: "+str(family))
		await _capture_view("material_emission_"+("night" if night else "day"))
	_fx._forms.reset()
	materials.free()
	_hud.show()


func _accessibility() -> void:
	await _phase("night")
	var before := var_to_bytes(_state)
	for quality in [Lighting.OFF,Lighting.STEADY,Lighting.FULL]:
		_lamps.set_quality(quality)
		_lamps._process(0.016)
		await _capture_view("quality_%d"%quality)
		expect(var_to_bytes(_state)==before,"Every lighting quality preserves all rules")
	if _settings!=null:
		_settings.set_value(&"video/lights",Lighting.FULL,false)
		_settings.set_value(&"a11y/flashing",false,false)
		_settings.set_value(&"a11y/particle_density",0.5,false)
		expect(_lamps.quality()==Lighting.STEADY and not _fx._motion,"Live reduced flashing makes emission forms and glows steady")
		expect(_fx.density()==0.5,"Live reduced density is honored")
		await _capture_view("reduced_flashing_density")
		_settings.set_value(&"gameplay/skip_transition",true,false)
		_world._read_transition_length()
		expect(is_equal_approx(_world.transition_seconds(),0.05),"Skip-transition accessibility uses the shortest real fade")
		await _phase("day")
		_state["phase"] = Phases.NIGHT
		_world._light_for_phase(0.05)
		_switch._process(0.0)
		for animal in _switch._day_actors:
			expect(is_zero_approx(animal.modulate.a),"Skipped transition reaches the actual night animal opacity")
		expect(not _world.is_transitioning(),"Reduced transition still reaches the same night ramp")
		await _capture_view("skip_transition_night")
		_settings.set_value(&"gameplay/skip_transition",false,false)
		_settings.set_value(&"a11y/flashing",true,false)
		_settings.set_value(&"a11y/particle_density",1.0,false)
		_world._read_transition_length()
	_lamps.set_quality(Lighting.STEADY)
