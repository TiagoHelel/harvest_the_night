extends "res://src/tools/input_v1.gd"

## **Task 0148's played nights**, through the real scenes with synthetic input:
## the checkpoint "is the night better with him asleep?" put to the game the
## way a player meets it - clicks, keys and pad buttons pushed into the real
## `Main`, never a rule called to stand in for a press the player makes.
##
##     godot --path . --headless --script res://src/tools/night_session.gd
##
## **Synthetic, and it says so.** Nobody's hands are on it: the presses are
## `InputEvent`s, and what a day of work would bring is handed over as a gain
## rather than walked for (the day is not what 0148 is asking about). Four
## nights in one run:
##
## 1. mouse and keyboard: GO TO BED, towers and walls by click, START, the
##    speed, a repair, a flare, an upgrade and a sale by cursor, SKIP, the
##    morning report;
## 2. mouse and keyboard: to bed by the bed, START by its key, the night at
##    4x to its own end;
## 3. mouse and keyboard: still up at 02:00, he passes out, and the short
##    build step runs out by itself;
## 4. a pad alone: Back to bed, the bumpers, the D-pad and A to build, LT to
##    upgrade, L3 to START, the bar by focus, RT for the flare, A on the
##    morning report.
##
## Each night prints one `NIGHT` line: the device, how it ended (dawn,
## everything dead, the house), the house left, what was killed, what walked
## off, what came down. `-- --first-night` stops after the first. Not part
## of `verify.py`: the four take a minute and a half.

## The watchdog of a session: whole nights at 4x pass between asserts.
const SESSION_WATCHDOG := 600.0
## The share of the screen a cell must be in to be clicked: inside the band
## the night's HUD leaves free (the tooltip's own `WORLD_AREA`, less a margin).
const FREE_BAND := Rect2(12, 30, 456, 176)

var _rows: Array = []


func _process(delta: float) -> bool:
	_elapsed += delta
	if _elapsed < SESSION_WATCHDOG:
		return false
	push_error("night_session: watchdog fired after %.0fs" % _elapsed)
	_finish()
	return true


func _run() -> void:
	Save.delete_run()
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	if driver == null:
		_finish()
		return
	await frames(4)
	var state := driver.state
	print("seed %d" % int(state["seed"]))
	await _night_by_mouse(driver, state)
	if OS.get_cmdline_user_args().has("--first-night"):
		_finish()
		return
	await _night_in_bed_by_keys(driver, state)
	await _night_after_passing_out(driver, state)
	await _night_by_pad(driver, state)
	await close_scene()
	Save.delete_run()
	_finish()


func _finish() -> void:
	if _finished:
		return
	_finished = true
	print("")
	for row in _rows:
		print("NIGHT %s" % row)
	print("%d checks, %d failed" % [passed + failed, failed])
	quit(1 if failed > 0 else 0)


# ------------------------------------------------------------------ night 1

## GO TO BED by click, the defence by click, START, 2x, a repair, a flare, an
## upgrade, a sale, SKIP, and the report confirmed by click.
func _night_by_mouse(driver: SimDriver, state: Dictionary) -> void:
	print("-- night 1: mouse and keyboard")
	_a_days_work(state, 1)
	_buy(state, &"true sights")
	await click_control("NightButton")
	await until(func() -> bool: return int(state["phase"]) == Phases.PREPARATION,
		"GO TO BED")
	await _the_bed_beat()
	var towers := await _build_by_click(state, &"gun_tower", 2)
	var walls := await _build_by_click(state, &"wall", 2)
	expect(towers.size() == 2 and walls.size() == 2,
		"night 1: two towers and two walls go down by click",
		"%d towers, %d walls" % [towers.size(), walls.size()])
	await click_control("StartButton")
	await until(func() -> bool: return int(state["phase"]) == Phases.NIGHT, "START")
	# The bar swaps START for the flare, the speed and SKIP a frame or two on.
	var speed_button: Button = require_control("SpeedButton") as Button
	await until(func() -> bool: return speed_button.is_visible_in_tree(), "the night's bar")
	await click_control("SpeedButton")
	await frames(2)
	expect(driver.speed == 2, "the speed button doubles the night", str(driver.speed))
	var world: WorldView = require_control("WorldView")

	# **A repair by cursor**: a wall knocked about, pointed at, clicked.
	if not walls.is_empty():
		var wall: Vector2i = walls[0]
		Farm.damage(state, wall, 50)
		var hurt := int(Farm.occupant(state, wall).get("hp", 0))
		await _point_at(world, wall)
		await click_cell(wall)
		await until(func() -> bool: return int(Farm.occupant(state, wall).get("hp", 0)) > hurt,
			"the wall mended", 300)
		expect(int(Farm.occupant(state, wall).get("hp", 0)) > hurt,
			"a click mends the hurt wall", str(Farm.occupant(state, wall)))

	# **A flare**: the button arms it, a click lets it go.
	await click_control("FlareButton")
	await frames(2)
	var aim := world.screen_to_cell(Vector2(300.0, 130.0))
	await _point_at(world, aim)
	await click_cell(aim)
	await until(func() -> bool: return Ability.flares_used(state) > 0, "the flare", 300)
	expect(Ability.flare_at(state) == [aim.x, aim.y], "the flare goes where it was clicked",
		str(Ability.flare_at(state)))

	# **An upgrade by middle click, a sale by right click.**
	if not towers.is_empty():
		var tower: Vector2i = towers[0]
		Resources.gain(state, {GameData.IRON: 60, GameData.WOOD: 60})
		var level := Building.level_at(state, tower)
		var refused := Building.why_not_upgrade(state, tower)
		await _point_at(world, tower)
		await click_cell(tower, MOUSE_BUTTON_MIDDLE)
		await until(func() -> bool: return Building.level_at(state, tower) > level,
			"the upgrade", 300)
		expect(Building.level_at(state, tower) > level,
			"a middle click upgrades a tower mid-wave", str(refused))
	if walls.size() > 1:
		var spare: Vector2i = walls[1]
		await _point_at(world, spare)
		await click_cell(spare, MOUSE_BUTTON_RIGHT)
		await until(func() -> bool: return Farm.occupant(state, spare).is_empty(),
			"the sale", 300)
		expect(Farm.occupant(state, spare).is_empty(), "a right click sells a wall",
			str(Farm.occupant(state, spare)))

	# **SKIP**, which the rules allow with the house whole.
	await frames(30)
	var refusal := Sim.why_not_skip(state)
	await click_control("SkipButton")
	await until(func() -> bool: return int(state["phase"]) == Phases.RESULT, "SKIP", 600)
	expect(int(state["phase"]) == Phases.RESULT, "SKIP runs the night out", str(refusal))
	driver.set_speed(1)
	await _read_and_confirm(state, "KBM: bed button, SKIP", true)


# ------------------------------------------------------------------ night 2

## To bed by the bed, the defence by click, START by its key, and the night
## at 4x to its own end.
func _night_in_bed_by_keys(driver: SimDriver, state: Dictionary) -> void:
	print("-- night 2: mouse and keyboard, the bed")
	_a_days_work(state, 2)
	expect(House.inside(state), "the day begins inside, beside the bed")
	var side := Vector2i(-1, -1)
	for y in range(3, House.ROOM.y - 1):
		for x in range(1, House.ROOM.x - 1):
			if side.x < 0 and House.bedside(Vector2i(x, y)):
				side = Vector2i(x, y)
	_stand_at(state, side, Player.NORTH)
	await frames(3)
	await tap_key(KEY_SPACE)
	await until(func() -> bool: return int(state["phase"]) == Phases.PREPARATION,
		"the bed")
	await _the_bed_beat()
	var towers := await _build_by_click(state, &"gun_tower", 2)
	var walls := await _build_by_click(state, &"wall", 2)
	var world: WorldView = require_control("WorldView")
	var upgraded := 0
	for found in towers:
		var tower: Vector2i = found
		var level := Building.level_at(state, tower)
		if not Building.can_upgrade(state, tower):
			continue
		await _point_at(world, tower)
		await click_cell(tower, MOUSE_BUTTON_MIDDLE)
		await until(func() -> bool: return Building.level_at(state, tower) > level,
			"the upgrade", 300)
		if Building.level_at(state, tower) > level:
			upgraded += 1
	expect(towers.size() + walls.size() > 0,
		"night 2: the defence by click in the build step",
		"%d towers (%d upgraded), %d walls" % [towers.size(), upgraded, walls.size()])
	await tap_key(KEY_G)
	await until(func() -> bool: return int(state["phase"]) == Phases.NIGHT, "START by G")
	driver.set_speed(4)
	await until(func() -> bool: return int(state["phase"]) == Phases.RESULT,
		"the night at 4x", 5000000)
	driver.set_speed(1)
	await _read_and_confirm(state, "KBM: the bed, G, 4x", false)


# ------------------------------------------------------------------ night 3

## Still up at 02:00: he passes out, the short build step runs out by itself.
func _night_after_passing_out(driver: SimDriver, state: Dictionary) -> void:
	print("-- night 3: mouse and keyboard, passed out")
	_a_days_work(state, 3)
	House.leave(state)
	_stand_at(state, House.porch(state))
	# The day itself is not the question: the clock is put near its end.
	state["day_tick"] = GameData.DAY_TICKS - 30
	await until(func() -> bool: return int(state["phase"]) == Phases.PREPARATION,
		"02:00", 100000)
	expect(House.passed_out(state), "night 3 begins with a pass-out")
	var house_view: HouseView = require_control("HouseView")
	await until(func() -> bool: return not house_view.is_showing_blackout(),
		"the black to lift", 100000)
	var towers := await _build_by_click(state, &"gun_tower", 2)
	expect(towers.size() >= 1, "towers by click in the short build step", str(towers.size()))
	await until(func() -> bool: return int(state["phase"]) == Phases.NIGHT,
		"the short build step to run out", 5000000)
	driver.set_speed(4)
	await until(func() -> bool: return int(state["phase"]) == Phases.RESULT,
		"the night at 4x", 5000000)
	driver.set_speed(1)
	await _read_and_confirm(state, "KBM: passed out, 4x", false)


# ------------------------------------------------------------------ night 4

## A pad alone: Back, the bumpers, the D-pad, A, LT, L3, the bar by focus,
## RT, and A on the report.
func _night_by_pad(driver: SimDriver, state: Dictionary) -> void:
	print("-- night 4: pad")
	_a_days_work(state, 4)
	await _pad_tap(JOY_BUTTON_BACK)
	await until(func() -> bool: return int(state["phase"]) == Phases.PREPARATION,
		"Back to bed")
	await _the_bed_beat()
	var world: WorldView = require_control("WorldView")
	var cursor := world.cursor()
	# The bumpers to a gun tower.
	var guard := 0
	while Building.selected(state) != &"gun_tower" and guard < 12:
		await _pad_tap(JOY_BUTTON_RIGHT_SHOULDER)
		await frames(1)
		guard += 1
	expect(Building.selected(state) == &"gun_tower", "the bumpers pick the gun tower",
		str(Building.selected(state)))
	# The D-pad walks the cursor onto open ground, A puts a tower there.
	var placed: Array = []
	for target in _open_cells(state, &"gun_tower", 2):
		var cell: Vector2i = target
		for _step in 40:
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
		if await _stands(state, cell, &"gun_tower"):
			placed.append(cell)
	expect(placed.size() >= 1, "the D-pad and A put towers down", str(placed.size()))
	# LT on the tower the cursor sits on: an upgrade.
	var top := cursor.cell()
	if placed.has(top):
		var level := Building.level_at(state, top)
		var refused := Building.why_not_upgrade(state, top)
		await _pad_axis(JOY_AXIS_TRIGGER_LEFT, 1.0)
		await _pad_axis(JOY_AXIS_TRIGGER_LEFT, 0.0)
		await until(func() -> bool: return Building.level_at(state, top) > level,
			"LT's upgrade", 300)
		expect(Building.level_at(state, top) > level,
			"LT upgrades the tower under the cursor",
			"level %d, refused %s" % [Building.level_at(state, top), refused])
	await _pad_tap(JOY_BUTTON_LEFT_STICK)
	await until(func() -> bool: return int(state["phase"]) == Phases.NIGHT, "L3 START")
	# The bar by focus: Back lands on the flare, right to the speed, A, B.
	var night_hud: NightHud = require_control("NightHud")
	await _pad_tap(JOY_BUTTON_BACK)
	await frames(2)
	await _pad_tap(JOY_BUTTON_DPAD_RIGHT)
	await frames(2)
	await _pad_tap(JOY_BUTTON_A)
	await frames(2)
	await _pad_tap(JOY_BUTTON_B)
	await frames(2)
	expect(driver.speed > 1 and not night_hud.holds_focus(),
		"Back, the D-pad and A speed the night up from the bar", str(driver.speed))
	# RT: the flare at the cursor, wherever the pad left it.
	await frames(30)
	await _pad_axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)
	await _pad_axis(JOY_AXIS_TRIGGER_RIGHT, 0.0)
	await until(func() -> bool: return Ability.flares_used(state) > 0, "RT's flare", 600)
	expect(Ability.flares_used(state) > 0, "RT lets a flare go at the cursor",
		"%s at %s" % [Ability.flare_at(state), cursor.cell()])
	driver.set_speed(4)
	await until(func() -> bool: return int(state["phase"]) == Phases.RESULT,
		"the night at 4x", 5000000)
	driver.set_speed(1)
	await _read_and_confirm(state, "pad: Back, L3, 4x", false, true)


# ------------------------------------------------------------------ helpers

## What a day of work brings, handed over: the day is not what 0148 asks
## about, and walking it would be minutes of synthetic chopping.
func _a_days_work(state: Dictionary, day: int) -> void:
	Resources.gain(state, {GameData.WOOD: 60, GameData.STONE: 40,
		GameData.IRON: 40, GameData.FOOD: 30, GameData.MONEY: 40,
		GameData.TECH: 3})
	print("day %d: %d wood, %d stone, %d iron, %d food, house %d/%d" % [day,
		Resources.amount(state, GameData.WOOD), Resources.amount(state, GameData.STONE),
		Resources.amount(state, GameData.IRON), Resources.amount(state, GameData.FOOD),
		int(state["house_hp"]), Phases.house_full(state)])


func _buy(state: Dictionary, id: StringName) -> void:
	var refused := Tech.why_not_buy(state, id)
	expect(Tech.buy(state, id), "bought %s by day" % id, str(refused))


## The getting-into-bed beat, which the build step opens on.
func _the_bed_beat() -> void:
	var house_view: HouseView = require_control("HouseView")
	var settled := func() -> bool:
		return not house_view.is_showing_bedtime() and not house_view.is_showing_blackout()
	await until(settled, "the bed beat", 100000)
	await frames(2)


## Pick a defence on the hotbar by click and click it down on open ground.
## Returns the cells it went on.
func _build_by_click(state: Dictionary, id: StringName, how_many: int) -> Array:
	var out: Array = []
	# **The row is made again on the tick after anything is bought** (its
	# prices move), and a press on a slot that is gone by its release selects
	# nothing. A hand is never that quick; this script is, so it waits.
	await frames(6)
	await click_control("Hotbar_%s" % id)
	await until(func() -> bool: return Building.selected(state) == id, "the %s slot" % id)
	var world: WorldView = require_control("WorldView")
	for target in _open_cells(state, id, how_many):
		var cell: Vector2i = target
		await _point_at(world, cell)
		await click_cell(cell)
		if await _stands(state, cell, id):
			out.append(cell)
	return out


## Whether a defence goes up on a cell within a few ticks: a press is an
## intent, and the tick that acts on it is up to a thirtieth of a second away
## while a headless frame is a fraction of that.
func _stands(state: Dictionary, cell: Vector2i, id: StringName) -> bool:
	var there := func() -> bool: return StringName(Farm.occupant(state, cell).get("id", &"")) == id
	for _i in 600:
		if there.call():
			return true
		await process_frame
	return false


## Cells a defence could take now: near the ground between the house and the
## spawn, inside the band the HUD leaves free.
func _open_cells(state: Dictionary, id: StringName, how_many: int) -> Array:
	var out: Array = []
	var world: WorldView = require_control("WorldView")
	var anchor := Tutorial._between_house_and_spawn(state)
	for radius in 10:
		for found in Grid.within(anchor, radius):
			var candidate: Vector2i = found
			if out.size() >= how_many:
				return out
			if out.has(candidate) or not FREE_BAND.has_point(world.cell_to_screen(candidate)):
				continue
			# Not next to another one, so a click is never on its neighbour.
			var crowded := false
			for other in out:
				if (candidate - (other as Vector2i)).length_squared() < 4:
					crowded = true
			if not crowded and Building.why_not(state, id, candidate).is_empty():
				out.append(candidate)
	return out


## The morning report: read, recorded, confirmed - by click, or by the pad's A.
func _read_and_confirm(state: Dictionary, device: String, skipped: bool,
		by_pad: bool = false) -> void:
	var screen: Control = require_control("ResultScreen") as Control
	await until(func() -> bool: return screen.visible, "the morning report", 100000)
	await frames(3)
	var result: Dictionary = state["last_result"]
	var paid := Rewards.last(state)
	var ended := "house down"
	if bool(result.get("survived", false)):
		var dawn := int((state["wave"] as Dictionary).get("dawn_at", GameData.NIGHT_TICKS))
		ended = "dawn" if int(result.get("ticks", 0)) >= dawn else "everything dead"
	if skipped:
		ended += " (skipped)"
	_rows.append("%d [%s]: %s at tick %d, house %d/%d, %d killed, %d walked off, %d came down, passed out: %s"
		% [int(result.get("night", 0)), device, ended, int(result.get("ticks", 0)),
			int(paid.get("house_hp", 0)), Phases.house_full(state),
			int(paid.get("killed", 0)), int(paid.get("walked", 0)),
			int(paid.get("structures_lost", 0)), House.passed_out(state)])
	print("   %s" % _rows[_rows.size() - 1])
	if by_pad:
		await _pad_tap(JOY_BUTTON_A)
	else:
		await click_control("ContinueButton")
	await until(func() -> bool: return int(state["phase"]) == Phases.DAY, "the morning")
	await frames(3)
	expect(int(state["phase"]) == Phases.DAY and House.inside(state),
		"%s: the report confirmed, he wakes in the house" % device)
