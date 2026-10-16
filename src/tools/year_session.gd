extends "res://src/tools/night_session.gd"

## **Task 0280's played nights**: the checkpoint "do fifty-six nights tire?"
## put to the real game a season at a time - one ordinary night of each
## season and every boss night, through the real `Main` with synthetic input,
## the way 0148's `night_session.gd` played spring's first four:
##
##     godot --path . --headless --script res://src/tools/year_session.gd
##
## **The farm is the robot's, the night is the player's.** The year autoplayer
## plays one run of its `towers` policy - the one that wins the year (0277) -
## day and night up to each date (`Autoplay._one_night`), and the real `Main`
## resumes that farm as a saved run (`resume_run`). Its line is what a player
## who played the year that way would have. Then the night is driven:
## - GO TO BED by click, or Back on the pad;
## - two more gun towers by click, or by the bumpers, the D-pad and A;
## - START by click or L3;
## - once the field fills, a flare by the button and a click, or by RT;
## - the night at 4x to its end, and the morning report confirmed.
##
## **Synthetic, and it says so.** No pad was attached: the pad's nights are
## `InputEvent`s, as the mouse's are. Each night prints its `NIGHT` line. Not
## part of `verify.py`: the robot's year takes minutes.

## The nights played: the date and the device - spring's ninth, then each
## season's ninth and its boss, mouse and pad in turn.
const NIGHTS := [[9, "pad"], [14, "mouse"], [23, "mouse"], [28, "pad"],
	[37, "pad"], [42, "mouse"], [51, "mouse"], [56, "pad"]]

## The robot whose farm is played on, and its seed.
const POLICY := &"towers"
const SEED := 9000

## How many bodies on the field count as the night under way, when the
## flare goes.
const UNDER_WAY := 12
## The watchdog of the year's session: the robot's year and eight nights.
const YEAR_WATCHDOG := 3600.0


func _process(delta: float) -> bool:
	_elapsed += delta
	if _elapsed < YEAR_WATCHDOG:
		return false
	push_error("year_session: watchdog fired after %.0fs" % _elapsed)
	_finish()
	return true


func _run() -> void:
	var farm := State.create(SEED)
	var policy: Dictionary = Autoplay.POLICIES[POLICY].duplicate(true)
	for night in NIGHTS:
		var date := int((night as Array)[0])
		# **The robot's days and nights up to the date**: its morning there.
		for _guard in 120:
			if Calendar.date(farm) >= date or Run.is_over(farm):
				break
			Autoplay._one_night(farm, policy)
		if Calendar.date(farm) != date:
			expect(false, "the robot's farm reaches day %d" % date, str(Calendar.date(farm)))
			continue
		Save.delete_run()
		await open_scene(MAIN_SCENE)
		var driver: SimDriver = require_control("SimDriver")
		if driver == null:
			break
		_scene.resume_run(farm.duplicate(true))
		await frames(4)
		await _a_night_of_the_year(driver, driver.state, date, String((night as Array)[1]))
		await close_scene()
	Save.delete_run()
	_finish()


## One night of the year on `date`, played by `device` on the robot's farm.
func _a_night_of_the_year(driver: SimDriver, state: Dictionary, date: int, device: String) -> void:
	print("-- %s %d (day %d): %s, the %s robot's farm, %d defences, house %d/%d" % [
		Calendar.season_id(date), Calendar.day_of_season(date), date, device, POLICY,
		Autoplay._towers_standing(state), int(state["house_hp"]), Phases.house_full(state)])
	if device == "pad":
		await _pad_tap(JOY_BUTTON_BACK)
	else:
		# GO TO BED is the yard's button - inside, the bed itself is - so he
		# steps out of the door first, as 0148's third night did.
		House.leave(state)
		_stand_at(state, House.porch(state))
		await frames(3)
		await click_control("NightButton")
	await until(func() -> bool: return int(state["phase"]) == Phases.PREPARATION, "to bed")
	await _the_bed_beat()
	Resources.gain(state, {GameData.WOOD: 40, GameData.IRON: 40, GameData.MONEY: 60})
	var placed: Array = []
	if device == "mouse":
		placed = await _build_by_click(state, &"gun_tower", 2)
	else:
		placed = await _build_by_pad(state, &"gun_tower", 2)
	expect(placed.size() >= 1, "%s %d: towers go down by %s" % [Calendar.season_id(date),
		Calendar.day_of_season(date), device], "%d placed" % placed.size())
	if device == "pad":
		await _pad_tap(JOY_BUTTON_LEFT_STICK)
	else:
		await click_control("StartButton")
	await until(func() -> bool: return int(state["phase"]) == Phases.NIGHT, "START")
	# **Once the field fills, a flare** - by the button and a click, or RT.
	await until(func() -> bool: return (Entities.count(state) >= UNDER_WAY
		or int(state["phase"]) != Phases.NIGHT), "the night under way", 100000)
	print("   under way: %d on the field, house %d/%d, tonight %s" % [Entities.count(state),
		int(state["house_hp"]), Phases.house_full(state),
		Waves.summary_of(date, int(state["seed"])).strip_edges()])
	if int(state["phase"]) == Phases.NIGHT:
		var flares := Ability.used(state, Ability.FLARE)
		if device == "pad":
			await _pad_axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)
			await _pad_axis(JOY_AXIS_TRIGGER_RIGHT, 0.0)
		else:
			await click_control("FlareButton")
			await frames(2)
			var world: WorldView = require_control("WorldView")
			var aim := world.screen_to_cell(Vector2(300.0, 130.0))
			await _point_at(world, aim)
			await click_cell(aim)
		await until(func() -> bool: return (Ability.used(state, Ability.FLARE) > flares
			or int(state["phase"]) != Phases.NIGHT), "the flare", 600)
	driver.set_speed(4)
	await until(func() -> bool: return int(state["phase"]) == Phases.RESULT,
		"the night at 4x", 5000000)
	driver.set_speed(1)
	await _read_and_confirm(state, "%s, %s %d" % [device, Calendar.season_id(date),
		Calendar.day_of_season(date)], false, device == "pad")


## Pick a defence by the bumpers and put it down by the D-pad and A, as
## 0148's pad night did. Returns the cells it went on.
func _build_by_pad(state: Dictionary, id: StringName, how_many: int) -> Array:
	var world: WorldView = require_control("WorldView")
	var cursor := world.cursor()
	await frames(6)
	var guard := 0
	while Building.selected(state) != id and guard < 24:
		await _pad_tap(JOY_BUTTON_RIGHT_SHOULDER)
		await frames(1)
		guard += 1
	var placed: Array = []
	if Building.selected(state) != id:
		return placed
	for target in _open_cells(state, id, how_many):
		var cell: Vector2i = target
		for _step in 60:
			var here := cursor.cell()
			if here == cell:
				break
			var button := JOY_BUTTON_DPAD_UP
			if cell.x > here.x:
				button = JOY_BUTTON_DPAD_RIGHT
			elif cell.x < here.x:
				button = JOY_BUTTON_DPAD_LEFT
			elif cell.y > here.y:
				button = JOY_BUTTON_DPAD_DOWN
			await _pad_tap(button)
			await frames(1)
		if cursor.cell() != cell:
			continue
		await _pad_tap(JOY_BUTTON_A)
		if await _stands(state, cell, id):
			placed.append(cell)
	return placed
