extends "res://src/tools/enemy_showcase.gd"

## Real Giant movement/hits and removed-enemy playback on the native renderer.
##
## **Any boss drawn in the Giant's pose names** (task 0246): `--boss=<family>`
## picks it, `--giant` and no flag the Giant, whose pictures and report are as
## before. The leaves 0266-0268 run it for theirs.

## The boss family shown, and each one's ground pivot.
var _family: StringName = &"giant"
const PIVOTS := {&"giant": Vector2(40, 60)}


func _run() -> void:
	CaptureSize.configure(root)
	for arg in OS.get_cmdline_user_args():
		if String(arg).begins_with("--boss="):
			_family = StringName(String(arg).trim_prefix("--boss="))
	_folder = "res://implementation/shots/sprites/0016/giant/" if _family == &"giant" \
		else "res://implementation/shots/sprites/boss/%s/" % _family
	await _setup()
	await _boss_identity()
	await _boss_walk(false)
	await _boss_walk(true)
	await _boss_attack(false)
	await _boss_attack(true)
	await _house_warning()
	await _death_playback(false)
	await _death_playback(true)
	await _pool_guards()
	print("%s SHOWCASE: %d checks, %d failed" % [String(_family).to_upper(), _checks, _failed])
	quit(1 if _failed > 0 else 0)


## The ordinary four and the boss, as the Giant's five identities were.
func _lineup() -> Array[StringName]:
	var out: Array[StringName] = EnemyMotion.FAMILIES.duplicate()
	out.append(_family)
	return out


## The boss's pose name: `walk`, `windup`, `slam` and a frame.
func _pose_name(motion: String, frame: int) -> StringName:
	return StringName("%s_%s_%d" % [_family, motion, frame])


func _prefix(motion: String) -> String:
	return "%s_%s_" % [_family, motion]


func _boss_identity() -> void:
	for night in [false,true]:
		_state = _blank(night)
		for i in _lineup().size():
			Entities.spawn(_state,_lineup()[i],Vector2i(5+i*4,9))
		await _settle()
		await _shoot("identities_%d" % int(night), "Five identities / Giant 42px body / existing farm scale")
		if not night:
			for sprite in _world._actor_sprites:
				sprite.modulate = Color.BLACK
			await _shoot("silhouettes", "Giant dominates visible bodies; transparent canvases are not body size")


func _boss_walk(left: bool) -> void:
	_state = _blank(true)
	_house(Vector2i(2,8) if left else Vector2i(26,8))
	var id := Entities.spawn(_state,_family,Vector2i(21 if left else 6,9))
	for i in 4:
		Entities.spawn(_state,EnemyMotion.FAMILIES[i],Vector2i(19 if left else 8,3+i*3))
	await _settle()
	var seen: Dictionary = {}
	for t in 110:
		_step()
		var one := Entities.get_one(_state,id)
		var pose := _world._pose_of(one)
		if str(pose).begins_with(_prefix("walk")):
			seen[pose] = true
		if t in [15,31,47,63,79,95]:
			await _settle()
			await _shoot("walk_%d_%03d" % [int(left),t], "Real Giant movement with ordinary escorts / stable feet")
	expect(seen.size()==4,"Four articulated Giant walk poses follow real distance")
	expect(_world._enemy_motion.faces_right(Entities.get_one(_state,id)) != left,"Giant mirrors actual horizontal movement")


func _boss_attack(right: bool) -> void:
	_state = _blank()
	_house(Vector2i(26 if right else 2,8))
	var cell := Vector2i(17,9)
	var toward := Vector2i.RIGHT if right else Vector2i.LEFT
	var terrain: PackedByteArray = _state["terrain"]
	for step in [Vector2i.UP,Vector2i.DOWN,-toward]:
		terrain[Grid.index(cell+step)] = Farm.Terrain.WATER
	_state["terrain"] = terrain
	_state["phase"] = Phases.PREPARATION  # where defences go up since task 0119
	expect(Building.place(_state,&"wall",cell+toward),"Actual paid wall is the Giant's only route")
	_state["phase"] = Phases.NIGHT
	var id := Entities.spawn(_state,_family,cell)
	await _settle()
	var poses: Dictionary = {}
	var hit_tick := -1
	var last_hp := int(Farm.occupant(_state,cell+toward).get("hp",0))
	for t in 60:
		_step()
		var one := Entities.get_one(_state,id)
		var pose := _world._pose_of(one)
		if str(pose).begins_with(_prefix("windup")) or str(pose).begins_with(_prefix("slam")):
			if not poses.has(pose):
				await _settle()
				await _shoot("attack_%d_%s" % [int(right),str(pose)], "Actual core target/wait/hit / body and ring agree")
				if str(pose).begins_with(_prefix("windup")):
					expect(Enemies.winding_at(_state,id)==cell+toward,"Raised arm targets the existing core ring cell")
					expect(_world._enemy_motion.faces_right(one)==right,"Wind-up faces its observed target")
					await _ring_pixels()
			poses[pose] = true
		var hp := int(Farm.occupant(_state,cell+toward).get("hp",0))
		if hp < last_hp and hit_tick < 0:
			hit_tick = t
			expect(str(pose).begins_with(_prefix("slam")),"The slam starts on the actual damage tick")
		if hit_tick < 0:
			expect(hp==120,"Telegraph does not invent early wall damage")
		last_hp = hp
	expect(hit_tick>=int(GameData.ENEMIES[_family]["telegraph_ticks"]),"Giant's first strike preserves the existing warning")
	for prefix in ["windup","slam"]:
		for frame in 3:
			expect(poses.has(_pose_name(prefix,frame)),"All three actual "+prefix+" poses played")
	# A loaded target is read directly; a stale distant target is not a tell.
	one_saved_guard(id,cell+toward)


func one_saved_guard(id: int, target: Vector2i) -> void:
	var one := Entities.get_one(_state,id)
	one["winding_at"] = Grid.index(target)
	one["chew_wait"] = 12
	one["pos"] = [3*Player.SUBTILE,3*Player.SUBTILE]
	_world._enemy_motion.clear()
	expect(_world._pose_of(one)==_family,"A distant stale saved wind-up cannot advertise an attack")


func _house_warning() -> void:
	_state = _blank(true)
	var id := Entities.spawn(_state,_family,Vector2i(26,8))
	await _settle()
	var seen: Dictionary = {}
	for t in 34:
		_step()
		var one := Entities.get_one(_state,id)
		if one.is_empty():
			continue
		var pose := _world._pose_of(one)
		if str(pose).begins_with(_prefix("windup")) and not seen.has(pose):
			seen[pose] = true
			await _settle()
			await _shoot("house_"+str(pose),"Existing house wind-up / visible ring above roof and boss")
			await _ring_pixels()
	expect(seen.size()==3,"House wind-up preserves all three real warning phases")
	expect(not Entities.alive(_state,id) and int(_state["house_hp"])==GameData.HOUSE_HP-int(GameData.ENEMIES[_family]["damage"]),"The actual house strike consumes the Giant and deals the original forty damage")
	expect(_world._enemy_deaths._cues.size()==1,"A spent Giant is removed and gets one bounded visual death")
	_world._refresh_actors()
	_world._refresh_deaths(0.0)
	await _shoot("house_spent_death","House damage uses core rules; spent Giant plays one death at its final contact")


func _ring_pixels() -> void:
	if not _capture:
		return
	_world._enemy_warning.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var with_ring := root.get_texture().get_image()
	_world._enemy_warning.visible = false
	await process_frame
	await RenderingServer.frame_post_draw
	var without := root.get_texture().get_image()
	_world._enemy_warning.visible = true
	var changed := 0
	for y in 270:
		for x in 480:
			if with_ring.get_pixel(x,y)!=without.get_pixel(x,y):
				changed += 1
	expect(changed>=12,"Actual target ring remains visible around the Giant: "+str(changed)+" pixels")


func _death_playback(night: bool) -> void:
	_state = _blank(true)
	var ids: Array[int] = []
	for i in _lineup().size():
		ids.append(Entities.spawn(_state,_lineup()[i],Vector2i(6+i*4,9)))
	await _settle()
	var control := _state.duplicate(true)
	var before := var_to_bytes(_state)
	_world.before_tick(_state)
	expect(var_to_bytes(_state)==before,"Death observation does not mutate live entities")
	_state["tick"] = int(_state["tick"])+1
	control["tick"] = int(control["tick"])+1
	Enemies.tick(_state)
	Enemies.tick(control)
	var final_positions: Array[Vector2i] = []
	for id in ids:
		final_positions.append(Entities.position(_state,id))
		Combat.hit(_state,id,10000)
		Combat.hit(control,id,10000)
	var after := var_to_bytes(_state)
	_world.after_tick(_state)
	expect(var_to_bytes(_state)==after and var_to_bytes(control)==after,"Real movement and five deaths match an unobserved control")
	expect(Entities.count(_state)==0 and _world._enemy_motion._actors.is_empty(),"No dead entity survives in core or live motion")
	expect(_world._enemy_deaths._cues.size()==5 and _world._enemy_deaths._before.is_empty(),"Only five copied visual cues survive; borrowed arrays released")
	for i in 5:
		expect(_world._enemy_deaths._cues[i]["pos"]==final_positions[i],"Death uses the exact moved position before core removal")
	if not night:
		# Keep observer semantics real; only the fixture's lighting is daylight.
		_world._light.color = Color.WHITE
		var relight := root.get_node("Relight") as Relight
		relight.apply(Color.WHITE, Color(0,0,0), 1.0, 1.0)
	for frame in 5:
		_world._refresh_deaths(0.0 if frame==0 else EnemyDeaths.FRAME_SECONDS)
		_world._refresh_actors()
		expect(var_to_bytes(_state)==after,"Death playback leaves every core/save byte unchanged")
		for i in _world._enemy_deaths._cues.size():
			var cue: Dictionary = _world._enemy_deaths._cues[i]
			var sprite: Sprite2D = _world._death_sprites[i]
			expect(sprite.texture.resource_path==WorldView.ENEMY_DIR+"%s_death_%d.png" % [cue["kind"],frame],"Actual death texture advances through every authored frame once")
			expect(sprite.position==ArtPlacement.contact([cue["pos"].x,cue["pos"].y]),"Every death frame keeps the last core contact")
			expect(sprite.offset==-PIVOTS.get(_family,Vector2(40,60)) if cue["kind"]==_family else sprite.offset==Vector2(-32,-44),"Death texture retains its complete family's ground pivot")
		for sprite in _world._death_sprites:
			if sprite.visible:
				expect(sprite.get_parent().y_sort_enabled,"Death depth still uses the last feet position")
		await _shoot("deaths_%d_%d" % [int(night),frame],"One-shot deaths / exact final position / frame "+str(frame))
	_world._refresh_deaths(EnemyDeaths.FRAME_SECONDS+0.01)
	expect(_world._enemy_deaths._cues.is_empty(),"All five death sequences expire once")
	for sprite in _world._death_sprites:
		expect(not sprite.visible,"Expired corpse sprites are hidden")
	_world.after_tick(_state)
	expect(_world._enemy_deaths._cues.is_empty(),"Duplicate after_tick cannot replay a death")
	await _shoot("deaths_%d_expired" % int(night),"Death pool expired; removed enemies remain removed")


func _pool_guards() -> void:
	_state = _blank(true)
	var ids: Array[int] = []
	for i in 64:
		ids.append(Entities.spawn(_state,_lineup()[i%_lineup().size()],Vector2i(5+i%20,3+i/20)))
	await _settle()
	_world.before_tick(_state)
	_state["tick"] = int(_state["tick"])+1
	for id in ids:
		Combat.hit(_state,id,10000)
	_world.after_tick(_state)
	_world._refresh_deaths(0.0)
	expect(_world._enemy_deaths._cues.size()==EnemyDeaths.CAP,"64 simultaneous deaths obey a hard 24-cue cap")
	expect(_world._death_sprites.size()==EnemyDeaths.CAP,"Allocated Sprite2D pool also obeys the hard cap")
	var before := var_to_bytes(_state)
	for repeat in 4:
		_world._process(0.001)
	expect(var_to_bytes(_state)==before,"Rendering the full pool cannot affect hits/pathing/state")
	var started := Time.get_ticks_usec()
	for repeat in 240:
		_world._refresh_deaths(0.0)
	var usec := float(Time.get_ticks_usec()-started)/240.0
	print("DEATH POOL: 24 sprites, %.1fus per refresh" % usec)
	expect(usec<8333.0,"Full cosmetic death pool stays inside a fixed-tick budget")
	await _shoot("death_pool_cap","64 real core removals / hard 24-sprite pool / oldest cues reused")
	_world.show_state(_state.duplicate(true))
	expect(_world._enemy_deaths._cues.is_empty(),"A loaded/new state clears old death history")
	_world._refresh_deaths(1.0)
	expect(_world._death_sprites.size()<=EnemyDeaths.CAP,"Expiry keeps the allocation bound")
	_world.show_state(_state)
	var id := Entities.spawn(_state,&"walker",Vector2i(12,9))
	_world.before_tick(_state)
	_state["tick"] = int(_state["tick"])+2
	Combat.hit(_state,id,10000)
	_world.after_tick(_state)
	expect(_world._enemy_deaths._cues.is_empty(),"Unobserved skip/load gaps do not fabricate death positions")
	Entities.spawn(_state,&"walker",Vector2i(12,9))
	_world.before_tick(_state)
	_state["tick"] = int(_state["tick"])+1
	_state["phase"] = Phases.DAY
	(_state["entities"] as Dictionary).clear()
	_world.after_tick(_state)
	_world._refresh_deaths(0.0)
	expect(_world._enemy_deaths._cues.is_empty(),"Morning cleanup cannot create a corpse wave")
