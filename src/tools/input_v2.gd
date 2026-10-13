extends "res://src/tools/input_v1.gd"

## The input paths of version 1.0, continued: real clicks and real keys
## through the real scenes, with nobody in the room.
##
## Run by `python tools/verify.py`. The last line it prints is
## `N cases, M failed`, and it exits non-zero when M is not zero.
##
## **Every case from task 0258 on lives here.** `input_v1` holds the 54 cases
## of tasks 0112-0257 and spent 115-119 of the 120 seconds verify gives a
## script by 0257, so the next case would have tipped it over - as the MVP's
## suites had filled theirs when 0112 started `input_v1`. Nothing moved
## across: the old cases stay where they are and this file starts with one.
##
## It **extends `input_v1.gd`**, which extends `input_check.gd`, so every tree
## helper of both is here without being copied - `open_scene`, `until`,
## `expect`, `_weathered_dates` and the rest. What is overridden is everything
## that counts: `_run()` calls only the cases below, `_finish()` compares
## against `V2_CASES` and prints this file's own last line, and the watchdog
## names this file.

## How many `_case_NNNN_*` functions `_run()` is expected to finish.
## **Adding a case means bumping this.**
const V2_CASES := 4

## The run the weather's hash check plays (task 0258).
const WEATHER_SEED := 2580258


func _process(delta: float) -> bool:
	_elapsed += delta
	if _elapsed < WATCHDOG_SECONDS:
		return false
	push_error("input_v2: watchdog fired after %.0fs" % _elapsed)
	print("WATCHDOG: a case never finished - look at the last case named above")
	_finish()
	return true


func _run() -> void:
	await _case_0258_event_visuals()
	await _case_0281_day_moments()
	await _case_0282_fishing_sounds()
	await _case_0283_guardian_sounds()
	_finish()


func _finish() -> void:
	if _finished:
		return
	_finished = true
	if _completed < V2_CASES:
		failed += 1
		print("  FAIL  a case did not finish   %d of %d completed"
			% [_completed, V2_CASES])
	print("%d cases, %d failed" % [passed + failed, failed])
	_put_tips_back()
	quit(1 if failed > 0 else 0)


# ------------------------------------------------------------------- the cases

## 0258 - fog, rain and a red moon on screen. Each event turns its layer on
## with the night and off at dawn - the fog, the rain's drops, mud and ramp,
## the Blood Moon's ramp; the rain follows the particle density; and a night
## with the layers on ends on the same SIM hash as one with them off.
func _case_0258_event_visuals() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	var view: WorldView = require_control("WorldView") as WorldView
	var particles: Particles = require_control("Particles") as Particles
	if driver == null or view == null or particles == null or view.weather_view() == null:
		await close_scene()
		_completed += 1
		return
	# By hand from here: no wall-clock ticks under the checks.
	var processing := driver.is_processing()
	driver.set_process(false)
	var weather := view.weather_view()
	var state := driver.state
	var dates := _weathered_dates(int(state["seed"]))

	# **On with the night, off at dawn.** For each event its first night in
	# this run: at noon nothing, in the night's waves its layer, after the
	# morning nothing again - the light's fade skipped each time.
	var wrong: Array = []
	for kind in Weather.EVENTS:
		if not dates.has(kind):
			wrong.append("no %s in four years" % kind)
			continue
		state["day"] = int(dates[kind])
		state["nights_won"] = int(dates[kind]) - 1
		state["day_tick"] = Phases.tick_at_minute(12 * 60)
		await _settled(view)
		var noon := _layer_on(view, particles, kind)
		NightRoad.to_night(state)
		await _settled(view)
		var night := _layer_on(view, particles, kind)
		Enemies.withdraw(state)
		Phases.enter_result(state, true)
		Phases.begin_day(state)
		await _settled(view)
		var morning := _layer_on(view, particles, kind)
		if noon or not night or morning:
			wrong.append("%s on %d: noon %s, night %s, morning %s"
				% [kind, int(dates[kind]), noon, night, morning])
	expect(wrong.is_empty(),
		"fog, rain and the Blood Moon each turn their layer on with the night and off at dawn",
		str(wrong))

	# **The rain follows the density setting**: as many drops as the setting
	# asks the first frame it rains - at full, at half, and none at all.
	if dates.has(Weather.RAIN):
		state["day"] = int(dates[Weather.RAIN])
		state["nights_won"] = int(dates[Weather.RAIN]) - 1
		NightRoad.to_night(state)
		await _settled(view)
		var was := particles.density()
		var counted: Array = []
		for density in [1.0, 0.0, 0.5]:
			particles.set_density(0.0)
			await frames(1)
			particles.set_density(density)
			await frames(1)
			counted.append(particles.raindrops())
		particles.set_density(was)
		var full := int(counted[0])
		expect(full > 0 and full <= particles.cap() and int(counted[1]) == 0
			and absf(float(counted[2]) - float(full) / 2.0) <= maxf(float(full) * 0.1, 3.0),
			"the rain follows the particle density: %d drops at full, none at none, half at half" % full,
			str(counted))
		Enemies.withdraw(state)
		Phases.enter_result(state, true)
		Phases.begin_day(state)

	# **A night with the layers on ends where one with them off does**, on a
	# foggy night and on a rainy one: the view reads, and writes nothing.
	# Each pair after a night of its own date played and thrown away: the
	# first run on a new date starts with banked `stats` the runs after it do
	# not, layers on or off - found by playing on, off, on, off and seeing
	# only the first differ.
	var hashes: Array = []
	for kind in [Weather.FOG, Weather.RAIN]:
		await _night_in_weather(driver, view, kind, true)
		for on in [true, false]:
			hashes.append(await _night_in_weather(driver, view, kind, on))
	weather.set_enabled(true)
	expect(int(hashes[0]) == int(hashes[1]) and int(hashes[2]) == int(hashes[3]),
		"a foggy night and a rainy one end on the same SIM hash with their layers on and off",
		str(hashes))

	driver.set_process(processing)
	await close_scene()
	_completed += 1     # last line: an abandoned case never gets here


## 0281 - the new day's sounds, heard through the real scene's `Sfx` and
## `Audio`: mining a copper seam rings copper and not stone; going to bed
## plays the bed once; and a morning with goods in the bin plays the coins
## exactly once - the bin's payout, not one a coin.
func _case_0281_day_moments() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	var audio: Node = root.get_node_or_null(^"Audio")
	if driver == null or audio == null:
		expect(audio != null, "the Audio autoload is up for the day's moments")
		await close_scene()
		_completed += 1
		return
	var state := driver.state
	driver.running = false
	await frames(2)

	# **A copper seam rings as copper.** One on the map with ground beside
	# it, or a rock made into one - the table entry is what is being heard.
	var seam := Vector2i(-1, -1)
	var beside := Vector2i(-1, -1)
	for id in [&"copper_ore", &"rock"]:
		for candidate in Farm.cells_with(state, id):
			var spot := _walkable_neighbour(state, candidate as Vector2i)
			if spot != Vector2i(-1, -1):
				seam = candidate
				beside = spot
				break
		if seam.x >= 0:
			break
	expect(seam.x >= 0, "there is a seam to stand beside")
	if seam.x < 0:
		driver.running = true
		await close_scene()
		_completed += 1
		return
	(state["occupants"] as Dictionary)[Grid.index(seam)] = {"id": &"copper_ore"}
	Farm.touch(state)
	var who: Dictionary = state["player"]
	who["pos"] = [beside.x * Player.SUBTILE + Player.SUBTILE / 2,
		beside.y * Player.SUBTILE + Player.SUBTILE / 2]
	who["facing"] = _facing_from(beside, seam)
	await frames(2)
	expect(Interact.verb_at(state, seam) == &"mine", "and it offers mining")
	audio.stop_all()
	audio.forget_counts()
	await press_key(KEY_SPACE, true)
	await frames(2)
	for i in 120:
		Sim.advance(state, 2)
		await frames(1)
		if audio.plays_of(Sfx.TARGET_SOUNDS[&"copper_ore"]) > 0:
			break
	await press_key(KEY_SPACE, false)
	await frames(2)
	expect(audio.plays_of(Sfx.TARGET_SOUNDS[&"copper_ore"]) >= 1
			and audio.plays_of(&"sfx/mine") == 0,
		"mining a copper seam plays the copper strike and not the stone one",
		"%d copper, %d stone, last '%s'" % [audio.plays_of(Sfx.TARGET_SOUNDS[&"copper_ore"]),
			audio.plays_of(&"sfx/mine"), audio.last_played()])

	# **To bed, with goods in the bin.** The `sleep` intent is the road the
	# bed and GO TO BED take.
	Resources.gain(state, {GameData.CARROT: 6})
	Shipping.put(state, GameData.CARROT, 6)
	await frames(2)
	audio.stop_all()
	audio.forget_counts()
	(state["intent"] as Dictionary)["sleep"] = true
	Sim.advance(state, 1)
	await frames(4)
	expect(int(state["phase"]) != Phases.DAY and House.asleep(state),
		"the sleep intent puts him to bed", Phases.name_of(int(state["phase"])))
	expect(audio.plays_of(Sfx.BED_SOUND) == 1 and audio.plays_of(Sfx.PASS_OUT_SOUND) == 0,
		"going to bed plays the bed sound once, and not the floor's",
		"%d bed, %d pass-out" % [audio.plays_of(Sfx.BED_SOUND), audio.plays_of(Sfx.PASS_OUT_SOUND)])

	# **The morning pays the bin, and that is one sound.** Through the night
	# and its result by hand, as 0258's case does, then frames for `Sfx` to
	# hear the morning - and more, to be sure it is heard once.
	audio.forget_counts()
	NightRoad.to_night(state)
	await frames(2)
	Enemies.withdraw(state)
	Phases.enter_result(state, true)
	await frames(2)
	Phases.begin_day(state)
	await frames(8)
	expect(Shipping.waiting(state).is_empty(), "the morning emptied the bin",
		str(Shipping.waiting(state)))
	expect(audio.plays_of(Sfx.PAYOUT_SOUND) == 1,
		"a morning with goods in the bin plays the coins exactly once",
		"%d payouts, %d sales" % [audio.plays_of(Sfx.PAYOUT_SOUND), audio.plays_of(Sfx.SELL_SOUND)])
	expect(audio.plays_of(Sfx.WAKE_SOUND) == 1,
		"and the stretch at 06:00 once", "%d" % audio.plays_of(Sfx.WAKE_SOUND))

	driver.running = true
	audio.stop_all()
	await close_scene()
	_completed += 1     # last line: an abandoned case never gets here


## 0282 - the fishing bar by ear, through the real scene's `Sfx` and `Audio`,
## the presses through the `interact` intent the bar spends: a press in the
## green plays the hit, one outside it the miss, the landing the catch - and
## a legendary landed plays its fanfare and not the catch.
func _case_0282_fishing_sounds() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	var audio: Node = root.get_node_or_null(^"Audio")
	if driver == null or audio == null:
		expect(audio != null, "the Audio autoload is up for the bar")
		await close_scene()
		_completed += 1
		return
	var state := driver.state
	driver.running = false
	await frames(2)

	var water := Vector2i(-1, -1)
	var beside := Vector2i(-1, -1)
	for cell in Farm.cells_of(state, Farm.Terrain.WATER):
		var spot := _walkable_neighbour(state, cell as Vector2i)
		if spot.x >= 0:
			water = cell
			beside = spot
			break
	expect(water.x >= 0, "there is water to stand beside")
	if water.x < 0:
		driver.running = true
		await close_scene()
		_completed += 1
		return
	var who: Dictionary = state["player"]
	who["pos"] = [beside.x * Player.SUBTILE + Player.SUBTILE / 2,
		beside.y * Player.SUBTILE + Player.SUBTILE / 2]
	who["facing"] = _facing_from(beside, water)
	await frames(2)

	# **An ordinary fish**: a hit, a miss, then hits until it is landed.
	audio.stop_all()
	audio.forget_counts()
	await _bitten(state, water, &"", 2)
	await _strike_at(state, true)
	expect(audio.plays_of(Sfx.HIT_SOUND) == 1 and audio.plays_of(Sfx.MISS_SOUND) == 0,
		"a press in the green plays the hit",
		"%d hits, %d misses" % [audio.plays_of(Sfx.HIT_SOUND), audio.plays_of(Sfx.MISS_SOUND)])
	await _strike_at(state, false)
	expect(audio.plays_of(Sfx.MISS_SOUND) == 1 and Fishing.is_biting(state),
		"and one outside it the miss, the fish still on",
		"%d misses" % audio.plays_of(Sfx.MISS_SOUND))
	for _guard in 4:
		if not Fishing.is_biting(state):
			break
		await _strike_at(state, true)
	expect(not Fishing.is_biting(state) and audio.plays_of(Sfx.CATCH_SOUND) == 1
			and audio.last_played() == Sfx.CATCH_SOUND,
		"landing it plays the catch, last",
		"catch %d, last '%s'" % [audio.plays_of(Sfx.CATCH_SOUND), audio.last_played()])
	expect(audio.plays_of(Sfx.TICK_SOUND) >= 1,
		"and the marker entering the green ticked on the way",
		"%d ticks" % audio.plays_of(Sfx.TICK_SOUND))

	# **A legendary**, on a bite crafted for it: the fanfare, and no catch.
	var legend := &""
	for id in GameData.sorted_names(GameData.FISH_SPECIES.keys()):
		if legend == &"" and Fishing.is_legendary(StringName(id)):
			legend = StringName(id)
	audio.stop_all()
	audio.forget_counts()
	await _bitten(state, water, legend, 1)
	await _strike_at(state, true)
	expect(legend != &"" and audio.last_played() == Sfx.LEGEND_SOUND
			and audio.plays_of(Sfx.CATCH_SOUND) == 0,
		"a legendary landed plays its fanfare and not the catch",
		"%s: last '%s', %d catches" % [legend, audio.last_played(), audio.plays_of(Sfx.CATCH_SOUND)])

	driver.running = true
	audio.stop_all()
	await close_scene()
	_completed += 1     # last line: an abandoned case never gets here


## 0283 - the guardian's sounds, through the cursor's intents in the real
## scene: in the build step a defence placed, upgraded and sold is heard as
## exactly that - never as a wall breaking; START blows the horn; an aimed
## flare is the flare; and the night's ears are the camera, so panning away
## from a tower makes it quieter.
func _case_0283_guardian_sounds() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	var audio: Node = root.get_node_or_null(^"Audio")
	var view: WorldView = require_control("WorldView") as WorldView
	if driver == null or audio == null or view == null:
		expect(audio != null, "the Audio autoload is up for the guardian")
		await close_scene()
		_completed += 1
		return
	var state := driver.state
	driver.running = false
	await frames(2)
	Resources.gain(state, {GameData.WOOD: 900, GameData.IRON: 900,
		GameData.STONE: 900, GameData.MONEY: 900})
	(state["tech_owned"] as Array).append(&"true sights")
	NightRoad.to_build(state)
	await frames(3)

	# Two cells for guns, a few tiles out from the farmer's bed.
	var here := Player.cell(state)
	var spots: Array = []
	for y in range(here.y - 3, here.y + 6):
		for x in range(here.x + 3, here.x + 12):
			if spots.size() < 2 and Building.can_place(state, &"gun_tower", Vector2i(x, y)):
				spots.append(Vector2i(x, y))
	expect(spots.size() == 2, "there is room for two guns", str(spots))
	if spots.size() < 2:
		driver.running = true
		await close_scene()
		_completed += 1
		return
	var gun: Vector2i = spots[0]
	var intent: Dictionary = state["intent"]
	Building.set_active(state, true)
	Building.select(state, &"gun_tower")

	var heard: Array = []
	audio.stop_all()
	audio.forget_counts()
	for press in [&"build_place", &"build_upgrade", &"build_sell"]:
		intent["build_cell"] = [gun.x, gun.y]
		intent[press] = true
		Sim.advance(state, 1)
		await frames(2)
		heard.append(audio.last_played())
	expect(heard == [Sfx.PLACE_SOUND, Sfx.UPGRADE_SOUND, Sfx.SELL_BACK_SOUND]
			and audio.plays_of(Sfx.BREAK_SOUND) == 0,
		"the cursor's place, upgrade and sell are heard as themselves, never as a wall breaking",
		"%s, %d breaks" % [str(heard), audio.plays_of(Sfx.BREAK_SOUND)])

	# A gun that stays, for the ears.
	var stays: Vector2i = spots[1]
	intent["build_cell"] = [stays.x, stays.y]
	intent["build_place"] = true
	Sim.advance(state, 1)
	Building.set_active(state, false)
	await frames(2)

	audio.forget_counts()
	intent["start_waves"] = true
	Sim.advance(state, 1)
	await frames(3)
	expect(int(state["phase"]) == Phases.NIGHT and audio.plays_of(Sfx.HORN_SOUND) == 1,
		"START blows the horn, once",
		"%s, %d horns" % [Phases.name_of(int(state["phase"])), audio.plays_of(Sfx.HORN_SOUND)])

	audio.forget_counts()
	intent["ability_cell"] = [stays.x + 2, stays.y]
	intent["ability"] = true
	Sim.advance(state, 1)
	await frames(2)
	expect(audio.plays_of(Sfx.POWER_SOUNDS[&"flare"]) == 1,
		"an aimed flare is heard as the flare",
		"%d, last '%s'" % [audio.plays_of(Sfx.POWER_SOUNDS[&"flare"]), audio.last_played()])

	# **The ears are the camera at night**: panned away from the gun, it
	# is quieter.
	var tower := Vector2((stays.x + 0.5) * GameData.TILE_SIZE, (stays.y + 0.5) * GameData.TILE_SIZE)
	view.look_at_cell(stays)
	await frames(2)
	var near: float = audio.loudness(audio.ears(), tower)
	var away := Vector2(1.0, 0.0) if view.camera_centre().x >= tower.x else Vector2(-1.0, 0.0)
	view.pan_camera(away, 3.0)
	await frames(2)
	var far: float = audio.loudness(audio.ears(), tower)
	expect(audio.ears().distance_to(view.camera_centre()) < 1.0 and far < near,
		"the night's ears follow the camera, and panning away from a gun makes it quieter",
		"ears %s, camera %s, %.2f then %.2f" % [str(audio.ears()), str(view.camera_centre()), near, far])

	driver.running = true
	audio.stop_all()
	await close_scene()
	_completed += 1     # last line: an abandoned case never gets here


## A cast at `water` whose float goes under on the next tick, `needs` hits
## to land `species` (`&""` for what the draw gave) and the bar given all the
## time the checks take.
func _bitten(state: Dictionary, water: Vector2i, species: StringName, needs: int) -> void:
	Fishing.give_up(state)
	Fishing.begin(state, water)
	var line := Fishing.cast_of(state)
	if species != &"":
		line["species"] = species
	line["needs"] = needs
	line["left"] = 1
	Sim.advance(state, 1)
	(Fishing.cast_of(state) as Dictionary)["left"] = 100000
	await frames(2)


## Play the bar on until the marker is over the green on a sweep not yet
## scored (`inside`), or off the green, then press once through the intent.
func _strike_at(state: Dictionary, inside: bool) -> void:
	for i in 4000:
		var line := Fishing.cast_of(state)
		if line.is_empty():
			return
		var ready := not Fishing.in_zone(line)
		if inside:
			ready = Fishing.in_zone(line) and int(line.get("struck", -1)) != Fishing.pass_of(line)
		if ready:
			break
		Sim.advance(state, 1)
		if i % 3 == 0:
			await frames(1)
	(state["intent"] as Dictionary)["interact"] = true
	Sim.advance(state, 1)
	await frames(2)


## A frame for the view to see the phase it is in now, the light's change
## skipped, and two more for every layer to come up to it.
func _settled(view: WorldView) -> void:
	await frames(1)
	view.skip_transition()
	await frames(2)


## Whether `kind`'s layer is on screen now: the fog's thickness, the rain's
## drops, mud and ramp, the Blood Moon's ramp.
func _layer_on(view: WorldView, particles: Particles, kind: StringName) -> bool:
	var weather := view.weather_view()
	match kind:
		Weather.FOG:
			return weather.fog_density() > 0.5
		Weather.RAIN:
			return particles.raining() and particles.raindrops() > 0 and weather.mud() > 0.5 \
				and view.light_target().is_equal_approx(PaletteData.RAIN_TINT)
		Weather.BLOOD_MOON:
			return view.light_target().is_equal_approx(PaletteData.BLOOD_MOON_TINT)
	return false


## Play the opening of one run's first `kind` night with the weather's layers
## on or off, and hand back the state hash. The simulation is advanced by hand
## and the view given a frame between, as `_night_with_lights` does: if
## drawing the weather touched anything, this is where it would show. Main's
## reset, so every view observes this same fresh state.
func _night_in_weather(driver: SimDriver, view: WorldView, kind: StringName,
		on: bool) -> int:
	_scene.begin_run(WEATHER_SEED)
	var state := driver.state
	var date := int(_weathered_dates(WEATHER_SEED).get(kind, 2))
	state["day"] = date
	state["nights_won"] = date - 1
	view.weather_view().set_enabled(on)
	Resources.gain(state, {GameData.WOOD: 400, GameData.IRON: 400, GameData.STONE: 400})
	var at := Player.cell(state)
	NightRoad.to_build(state)
	for i in 4:
		Building.place(state, &"gun_tower", Vector2i(at.x + 2 + i * 2, at.y + 1))
	NightRoad.to_night(state)
	await _settled(view)
	for chunk in 12:
		Sim.advance(state, 30)
		await frames(1)
	return State.hash_of(state)
