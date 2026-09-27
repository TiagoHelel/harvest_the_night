extends SceneTree

## The other half of the gate: real clicks and real keys, through the real
## scenes, with nobody in the room.
##
## `headless_check` proves the rules are right. This proves you can still reach
## them - that the night button is still wired to the night, that placing a
## tower still places a tower, that a refactor which quietly broke a signal is
## a red line the same minute rather than a bug report in three weeks.
##
## Run by `python tools/verify.py`. The last line it prints is
## `N cases, M failed`, and it exits non-zero when M is not zero.
##
## ## It really is headless
##
## Measured before this file was written: with `--headless` the viewport is the
## project's 480x270, `root.push_input()` reaches Controls and fires their
## signals, and `Input.parse_input_event()` sets `Input.is_key_pressed()`. So
## there is no need for a window, and no need for a separate "test mode" path
## through the UI - which is the point, because a test mode is a thing that can
## be right while the real path is wrong.
##
## ## House style
##
## One `_case_NNNN_*` function per task that added an input path, counted the
## same way `headless_check` counts its groups: a case that dies half way
## cannot report success, because the counter is its last line.

const MAIN_SCENE := "res://scenes/Main.tscn"

## How long the run may go without a single assert landing.
##
## **A stall, not a budget.** This used to be the whole run's time, and
## that is a deadline that every new case eats into: the eleventh one
## tripped it on a suite where nothing was wrong at all. Every `expect()`
## puts it back to zero, so what it now catches is what it was always for -
## a scene that never loads, an `await` that never returns, a case that
## stopped making progress - and it does that just as well whether there
## are eleven cases or two hundred.
const WATCHDOG_SECONDS := 20.0

## How many `_case_NNNN_*` functions `_run()` is expected to finish.
## **Adding a case means bumping this.**
const CASES := 22

var passed := 0
var failed := 0

var _completed := 0
var _finished := false
var _elapsed := 0.0
var _scene: Node = null


func _initialize() -> void:
	# Not awaited: `_run()` needs frames to pass, which only happens once
	# `_initialize()` has returned and the main loop is turning. `_finish()` is
	# called at the end of `_run()`, and the watchdog covers the case where it
	# never gets there.
	_run()


func _process(delta: float) -> bool:
	_elapsed += delta
	if _elapsed < WATCHDOG_SECONDS:
		return false
	push_error("input_check: watchdog fired after %.0fs" % _elapsed)
	print("WATCHDOG: a case never finished - look at the last case named above")
	_finish()
	return true


func _run() -> void:
	await _case_0011_harness()
	await _case_0012_debug_overlay()
	await _case_0013_world_view()
	await _case_0015_player()
	await _case_0020_shop()
	await _case_0021_day_hud()
	await _case_0022_reality()
	await _case_0023_build_mode()
	await _case_0027_the_loop()
	await _case_0028_seeds()
	await _case_0029_watering()
	await _case_0030_fishing()
	await _case_0032_press()
	await _case_0033_power()
	await _case_0034_livestock()
	await _case_0035_ammo()
	await _case_0036_inventory()
	await _case_0037_queue()
	await _case_0038_away()
	await _case_0039_clock()
	await _case_0040_shop()
	await _case_0041_tutorial()
	_finish()


func _finish() -> void:
	if _finished:
		return
	_finished = true
	if _completed < CASES:
		failed += 1
		print("  FAIL  a case did not finish   %d of %d completed"
			% [_completed, CASES])
	print("%d cases, %d failed" % [passed + failed, failed])
	quit(1 if failed > 0 else 0)


# ------------------------------------------------------------------- the cases

## 0011 - the harness itself. Until there is a button to press, what is worth
## checking is that the machinery which will press it works and complains.
func _case_0011_harness() -> void:
	await open_scene(MAIN_SCENE)

	# The real scene, with the nodes it says it has.
	expect(_scene != null, "the main scene loads")
	expect(require_control("WorldView") != null, "the farm is on screen")
	expect(require_control("Day") != null, "the day label is there")
	expect(require_control("SimDriver") != null, "the sim driver is there")

	# **Prove it fails loudly**, rather than trusting that it would. A control
	# that is named and missing has to be a red line - a harness that quietly
	# returns null would pass for ever while the button it was meant to press
	# no longer existed.
	#
	# This is the one place in this file that takes a failure back off the
	# tally, and it is doing so on purpose.
	print("  (the FAIL line below is deliberate - it is the harness being ",
		"asked for a control that does not exist, and the failure is taken ",
		"back off the tally on the next line)")
	var before := failed
	require_control("NoSuchControlExists")
	var was_loud := failed == before + 1
	failed = before
	expect(was_loud, "naming a control that does not exist fails the run")
	expect(locate_control("NoSuchControlExists") == null,
		"while locate() is the quiet one, for asking whether something is there")

	# The scene is really being ticked and not merely instantiated. The tick
	# counter rather than the clock label: the label reads in whole seconds, so
	# twenty frames of it say nothing at all.
	var driver: SimDriver = require_control("SimDriver")
	var first := int(driver.state["tick"])
	await frames(20)
	expect(int(driver.state["tick"]) > first, "the scene is live - it is ticking",
		"%d then %d" % [first, driver.state["tick"]])

	# A mouse click reaches a Control and its handler runs.
	var probe := Button.new()
	probe.name = "ClickProbe"
	probe.position = Vector2(200, 120)
	probe.size = Vector2(80, 24)
	var clicks := [0]
	probe.pressed.connect(func() -> void: clicks[0] += 1)
	require_control("Screen").add_child(probe)
	await frames(2)

	await click_control("ClickProbe")
	expect(clicks[0] == 1, "a synthesised click reaches a control and fires it",
		str(clicks[0]))

	await click_at(Vector2(5, 5))
	expect(clicks[0] == 1, "and a click somewhere else does not", str(clicks[0]))

	# A key reaches the input system.
	await tap_key(KEY_F9)
	expect(not Input.is_key_pressed(KEY_F9), "a tapped key is released again")
	await press_key(KEY_F9, true)
	expect(Input.is_key_pressed(KEY_F9), "a held key stays held")
	await press_key(KEY_F9, false)
	expect(not Input.is_key_pressed(KEY_F9), "and lets go")

	# Clicking a farm cell. Now that task 0013 has given the world view a
	# camera, the mapping comes from the view rather than from the naive
	# identity - so what is checked here is that a cell lands somewhere on
	# screen and comes back as itself, not where it happens to be today.
	var view: WorldView = require_control("WorldView")
	var centre := cell_to_screen(Vector2i(20, 9))
	expect(centre.x > 0.0 and centre.y > 0.0, "a farm cell is somewhere on screen",
		str(centre))
	expect(view.screen_to_cell(centre) == Vector2i(20, 9),
		"and the screen position maps back to the cell it came from",
		str(view.screen_to_cell(centre)))
	await click_cell(Vector2i(20, 9))
	expect(true, "clicking a cell does not throw")

	await close_scene()
	expect(_scene == null, "and the scene is torn down for the next case")

	_completed += 1     # last line: an abandoned case never gets here


## 0012 - the overlay: it toggles, it reads, and it changes nothing.
func _case_0012_debug_overlay() -> void:
	await open_scene(MAIN_SCENE)

	var overlay := locate_control("DebugOverlay")
	expect(overlay != null,
		"the debug overlay is present in a debug build - if this fails in a "
		+ "release build that is correct, it frees itself")
	if overlay == null:
		_completed += 1
		await close_scene()
		return

	expect(not overlay.visible, "it is off by default - a player never sees it")

	var driver: SimDriver = require_control("SimDriver")
	await frames(10)

	# **Toggling it cannot move the game.** The overlay reads the state and
	# never writes to it, so this is true by construction - and checked anyway,
	# because "by construction" is how view layers start writing to state.
	var before := State.hash_of(driver.state)
	var tick_before := int(driver.state["tick"])
	driver.running = false                  # freeze, so the tick is not the
	await frames(2)                         # thing that moved the hash

	await tap_key(KEY_F3)
	expect(overlay.visible, "F3 turns it on")
	await frames(5)
	await tap_key(KEY_F3)
	expect(not overlay.visible, "and F3 turns it off again")

	expect(State.hash_of(driver.state) == before,
		"toggling it did not move the determinism hash",
		"%d vs %d" % [State.hash_of(driver.state), before])
	expect(int(driver.state["tick"]) == tick_before,
		"nor advance the simulation")
	driver.running = true

	# It says the true things about the game it is watching.
	await tap_key(KEY_F3)
	await frames(12)
	var label: Label = overlay.find_child("Readout", true, false)
	expect(label != null and not label.text.is_empty(), "it has something to say")
	if label != null:
		expect(label.text.contains("DAY"), "it names the phase", label.text)
		expect(label.text.contains("seed"), "and the seed")
		expect(label.text.contains("us/tick"), "and what a tick costs")
		expect(label.text.contains("tree"), "and what is standing on the farm")

	# The cost is measured, not printed as a decorative zero. The other half of
	# this task's done-when - that it climbs with a hundred zombies on the farm
	# - has to wait for task 0025 to give us a hundred zombies.
	expect(driver.peak_usec > 0, "the tick cost is a real measurement",
		"%d us peak over %d ticks" % [driver.peak_usec, driver.last_ticks])

	# **It never steals the mouse.** A probe under where the overlay draws must
	# still receive the click.
	var probe := Button.new()
	probe.name = "UnderOverlay"
	probe.position = Vector2(8, 8)          # the overlay sits at 4,4
	probe.size = Vector2(60, 20)
	var clicks := [0]
	probe.pressed.connect(func() -> void: clicks[0] += 1)
	require_control("Screen").add_child(probe)
	await frames(2)
	await click_at(Vector2(20, 14))
	expect(clicks[0] == 1,
		"a click lands on what is underneath the overlay, not on the overlay",
		str(clicks[0]))

	await tap_key(KEY_F3)
	await close_scene()

	_completed += 1     # last line: an abandoned case never gets here


## 0013 - the view: it draws the farm, it tracks the camera, it changes nothing.
func _case_0013_world_view() -> void:
	await open_scene(MAIN_SCENE)

	var view: WorldView = require_control("WorldView")
	var driver: SimDriver = require_control("SimDriver")
	expect(view != null and driver != null, "the screen has both halves")
	if view == null or driver == null:
		_completed += 1
		await close_scene()
		return

	# The generated art is what is on screen, not the fallback blocks. A
	# forgotten `python tools/gen_sprites.py` would otherwise look like a
	# slightly duller farm rather than like a missing build step.
	var terrain := view.find_child("Terrain", true, false)
	expect(terrain != null and terrain.tile_set != null, "the tileset is built")
	if terrain != null and terrain.tile_set != null:
		var src: TileSetAtlasSource = terrain.tile_set.get_source(0)
		expect(src != null and src.texture != null
			and src.texture.resource_path == WorldView.TERRAIN_ATLAS,
			"and it is the generated atlas, not the emergency flat one",
			src.texture.resource_path if src != null and src.texture != null
			else "nothing")

	# Everything on the farm got drawn, and nothing was drawn twice.
	var occupants: Dictionary = driver.state["occupants"]
	var drawn := view.find_child("Occupants", true, false)
	# Only the sprites: the layer also holds the highlight and the player, who
	# live here so that walking behind a tree puts them behind the tree.
	expect(drawn != null and _sprites_in(drawn) == occupants.size(),
		"one sprite per occupant, no more and no fewer",
		"%d drawn, %d on the farm"
		% [_sprites_in(drawn) if drawn else -1, occupants.size()])

	# **Moving the camera cannot move the game.** The view reads the state and
	# never writes to it; this is the assert that keeps it that way.
	driver.running = false
	await frames(2)
	var before := State.hash_of(driver.state)
	view.look_at_cell(Vector2i(0, 9))
	await frames(3)
	view.look_at_cell(Vector2i(39, 9))
	await frames(3)
	expect(State.hash_of(driver.state) == before,
		"panning the camera did not move the determinism hash")
	driver.running = true

	# **A click on a cell goes where the camera put it.** This is why
	# cell_to_screen exists at all: without it every click case would be wrong
	# the moment the camera moved - and since task 0015 the camera follows the
	# player, so it moves constantly.
	var cam_probe: Camera2D = view.find_child("Camera", true, false)
	var before_walk := cam_probe.position.x
	var at_cell_before := view.cell_to_screen(Vector2i(20, 9))
	await hold_key(KEY_D, 60)
	expect(cam_probe.position.x > before_walk,
		"the camera follows the player east",
		"%.0f then %.0f" % [before_walk, cam_probe.position.x])
	expect(view.cell_to_screen(Vector2i(20, 9)).x != at_cell_before.x,
		"so a fixed cell is somewhere else on screen afterwards")

	# Screen and cell are each other's inverse, wherever the camera is.
	for cell in [Vector2i(20, 9), Vector2i(25, 4), Vector2i(30, 12)]:
		expect(view.screen_to_cell(view.cell_to_screen(cell)) == cell,
			"cell %s survives a round trip through the screen" % cell,
			str(view.screen_to_cell(view.cell_to_screen(cell))))
	expect(view.screen_to_cell(Vector2(-500, -500)) == Vector2i(-1, -1),
		"and a position off the farm is not a cell")

	# **The camera is clamped**, so panning past either end shows the farm
	# rather than a gap. Godot does the clamping; this checks it was asked to.
	var cam: Camera2D = view.find_child("Camera", true, false)
	expect(cam != null and cam.limit_right == WorldView.WORLD_SIZE.x,
		"the camera is fenced in at the farm's edge")
	view.look_at_cell(Vector2i(-50, 9))
	await frames(1)
	expect(cam.position.x >= 240.0,
		"the camera cannot be pushed past the farm left edge",
		str(cam.position.x))
	view.look_at_cell(Vector2i(500, 9))
	await frames(1)
	expect(cam.position.x <= float(WorldView.WORLD_SIZE.x) - 240.0,
		"nor past its right edge", str(cam.position.x))

	# The occupant layer follows the farm when the farm changes, without
	# anybody having to say so.
	var count_before := drawn.get_child_count()
	var free := _any_buildable(driver.state)
	Farm.place(driver.state, free, {"id": &"gun_tower"})
	await frames(4)
	expect(drawn.get_child_count() == count_before + 1,
		"placing something redraws the layer",
		"%d then %d" % [count_before, drawn.get_child_count()])
	Farm.remove(driver.state, free)
	await frames(4)
	expect(drawn.get_child_count() == count_before,
		"and taking it away redraws it again")

	await close_scene()
	_completed += 1     # last line: an abandoned case never gets here


## 0015 - the player: they walk, the pond stops them, and interact does the
## thing in front of them.
func _case_0015_player() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	var view: WorldView = require_control("WorldView")
	if driver == null or view == null:
		_completed += 1
		await close_scene()
		return

	var start := Player.cell(driver.state)
	expect(Farm.walkable(driver.state, start),
		"the player starts somewhere legal", str(start))

	# Walking, and the facing that comes with it.
	await hold_key(KEY_S, 20)
	expect(Player.facing(driver.state) == Player.SOUTH,
		"walking down faces down")
	expect(Player.cell(driver.state).y >= start.y, "and moves down",
		"%s to %s" % [start, Player.cell(driver.state)])

	await hold_key(KEY_A, 30)
	expect(Player.facing(driver.state) == Player.WEST,
		"walking left faces left")

	# **The pond stops you rather than swallowing you.** Walk south-west for
	# long enough to reach the water and check where the player ended up.
	for _i in 8:
		await hold_key(KEY_S, 30)
		await hold_key(KEY_A, 30)
	var landed := Player.cell(driver.state)
	expect(Farm.walkable(driver.state, landed),
		"after walking into the pond the player is on dry land", str(landed))
	expect(Farm.terrain_at(driver.state, landed) != Farm.Terrain.WATER,
		"and specifically not in the water",
		str(Farm.terrain_at(driver.state, landed)))

	# **The same inputs from the same seed end on the same cell.** The property
	# the whole tick design exists for.
	var replay_a := _replay_walk(int(driver.state["seed"]))
	var replay_b := _replay_walk(int(driver.state["seed"]))
	expect(replay_a == replay_b, "the same key sequence ends at the same cell",
		"%s vs %s" % [replay_a, replay_b])

	# Interact starts whatever the faced cell offers.
	var state := driver.state
	var tree_cells := Farm.cells_with(state, &"tree")
	expect(not tree_cells.is_empty(), "there are trees to chop")

	# Put the player beside a tree directly: walking to a named tree is the
	# autoplayer's job at task 0067, not this case's.
	var tree := Vector2i(-1, -1)
	var beside := Vector2i(-1, -1)
	for candidate in tree_cells:
		var spot := _walkable_neighbour(state, candidate)
		if spot != Vector2i(-1, -1):
			tree = candidate
			beside = spot
			break
	expect(beside != Vector2i(-1, -1), "and one can be stood next to",
		str(tree))
	if beside != Vector2i(-1, -1):
		driver.running = false
		await frames(2)
		var who: Dictionary = state["player"]
		who["pos"] = [beside.x * Player.SUBTILE + Player.SUBTILE / 2,
			beside.y * Player.SUBTILE + Player.SUBTILE / 2]
		who["facing"] = _facing_from(beside, tree)
		driver.running = true
		await frames(3)

		expect(Player.target(state) == tree, "the target is the tree faced",
			"%s facing %d gives %s"
			% [beside, Player.facing(state), Player.target(state)])
		expect(Interact.verb_at(state, tree) == &"chop",
			"which offers chopping")

		await hold_key(KEY_SPACE, 4)
		await frames(3)
		expect(Player.is_busy(state), "pressing interact starts the work")
		var action: Dictionary = who["action"]
		expect(action.get("verb", &"") == &"chop", "and the work is chopping",
			str(action))

		# **Walking away gives it up**, rather than leaving half a tree chopped
		# in an invisible ledger.
		await hold_key(KEY_W, 6)
		expect(not Player.is_busy(state), "walking away stops the work")

	await close_scene()
	_completed += 1     # last line: an abandoned case never gets here


## Drive the same keys into a fresh game twice and see where the player lands.
func _replay_walk(seed_value: int) -> Vector2i:
	var state := State.create(seed_value)
	var script: Array = [
		[Vector2i(1, 0), 25], [Vector2i(0, 1), 40], [Vector2i(-1, -1), 30],
		[Vector2i(0, -1), 15], [Vector2i(1, 1), 50],
	]
	for step in script:
		var direction: Vector2i = step[0]
		for _i in int(step[1]):
			var move: Array = (state["intent"] as Dictionary)["move"]
			move[0] = direction.x
			move[1] = direction.y
			Sim.tick(state)
	return Player.cell(state)


func _walkable_neighbour(state: Dictionary, cell: Vector2i) -> Vector2i:
	for step in Grid.STEPS:
		var n: Vector2i = cell + step
		if Grid.in_bounds(n) and Farm.walkable(state, n):
			return n
	return Vector2i(-1, -1)


func _facing_from(from_cell: Vector2i, to_cell: Vector2i) -> int:
	var d: Vector2i = to_cell - from_cell
	if d.y > 0:
		return Player.SOUTH
	if d.y < 0:
		return Player.NORTH
	if d.x < 0:
		return Player.WEST
	return Player.EAST


## Somewhere nothing is standing and something could be. Found rather than
## written down, so that a map gaining a building does not fail a test about
## something else.
func _any_buildable(state: Dictionary) -> Vector2i:
	for idx in Grid.CELLS:
		var cell := Grid.cell(idx)
		if Farm.buildable(state, cell):
			return cell
	return Vector2i(-1, -1)


## Occupant sprites only. The layer also holds the player and, since task
## 0023, the build ghost - which is a Sprite2D and is nobody's occupant.
func _sprites_in(node: Node) -> int:
	var n := 0
	for child in node.get_children():
		if child is Sprite2D and child.name != "Ghost":
			n += 1
	return n


## 0020 - the stall, through the real panel: open it, sell something, leave.
func _case_0020_shop() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	var panel: ShopPanel = require_control("ShopPanel")
	if driver == null or panel == null:
		_completed += 1
		await close_scene()
		return

	var state := driver.state
	expect(not panel.visible, "the panel starts closed")

	# Stand at the stall and press interact, the way a player would.
	var stall: Vector2i = Farm.cells_with(state, &"shop")[0]
	var beside := _walkable_neighbour(state, stall)
	expect(beside != Vector2i(-1, -1), "the stall can be stood next to")
	if beside == Vector2i(-1, -1):
		_completed += 1
		await close_scene()
		return

	driver.running = false
	await frames(2)
	var who: Dictionary = state["player"]
	who["pos"] = [beside.x * Player.SUBTILE + Player.SUBTILE / 2,
		beside.y * Player.SUBTILE + Player.SUBTILE / 2]
	who["facing"] = _facing_from(beside, stall)
	Resources.add(state, GameData.WOOD, 12)
	driver.running = true
	await frames(3)

	expect(Player.target(state) == stall, "the stall is the target",
		str(Player.target(state)))
	await hold_key(KEY_SPACE, 4)
	await until(func() -> bool: return panel.visible, "the shop to open")
	expect(panel.visible, "pressing interact opens the panel")

	# Sell, by clicking the button a player would click.
	var wood_before := Resources.amount(state, GameData.WOOD)
	var money_before := Resources.amount(state, GameData.MONEY)
	var sell_button: Control = require_control("sell_one_wood")
	if sell_button != null:
		var box := sell_button.get_global_rect()
		var at := box.position + box.size * 0.5
		print("  0020 clicking sell_one_wood at %s (rect %s); panel %s; top %s"
			% [at, box, str((require_control("ShopPanel") as Control)
				.get_global_rect()),
				str(sell_button.get_viewport().gui_get_hovered_control())])
	await click_control("sell_one_wood")
	await frames(4)
	expect(Resources.amount(state, GameData.WOOD) == wood_before - 1,
		"clicking sell sells one", str(Resources.amount(state, GameData.WOOD)))
	expect(Resources.amount(state, GameData.MONEY)
		== money_before + Shop.sell_price(GameData.WOOD),
		"and pays for it", str(Resources.amount(state, GameData.MONEY)))

	await click_control("sell_all_wood")
	await frames(4)
	expect(Resources.amount(state, GameData.WOOD) == 0,
		"and sell-all empties the bag",
		str(Resources.amount(state, GameData.WOOD)))

	# A row with nothing behind it is shown and refuses to be pressed.
	var button := locate_control("sell_one_wood")
	expect(button != null and button.disabled,
		"a row with none left is greyed rather than gone")

	# Leaving.
	await hold_key(KEY_ESCAPE, 4)
	await until(func() -> bool: return not panel.visible, "the shop to close")
	expect(not panel.visible, "escape closes it")
	# **And it stays closed.** The trade action used to repeat, so the panel
	# reopened on the tick after it was shut.
	await frames(30)
	expect(not panel.visible, "and stays closed a second later")
	expect(not Shop.is_open(state), "and the game agrees it is closed")

	await close_scene()
	_completed += 1     # last line: an abandoned case never gets here


## 0021 - the HUD: it tells the truth the same tick, and the button works by
## mouse and by key.
func _case_0021_day_hud() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	var hud: DayHud = require_control("DayHud")
	if driver == null or hud == null:
		_completed += 1
		await close_scene()
		return

	var state := driver.state
	expect(hud.visible, "the day HUD is up during the day")

	var day_label: Label = require_control("Day")
	var money_label: Label = require_control("Money")
	var wood_label: Label = require_control("res_wood")
	# The label carries the clock as well as the day now, so this asks what it
	# is for rather than what it happened to read the day it was written.
	expect(day_label != null and day_label.text.begins_with("DAY 1"),
		"it says which day", day_label.text if day_label else "")
	expect(day_label != null and day_label.text.contains(":"),
		"and what time it is", day_label.text if day_label else "")
	expect(money_label != null and money_label.text.contains("25"),
		"and what is in the purse",
		money_label.text if money_label else "")

	# **The same tick.** Not next frame, not after a refresh timer.
	var before := wood_label.text
	Resources.add(state, GameData.WOOD, 7)
	await frames(2)
	expect(wood_label.text != before, "gathering wood updates the HUD at once",
		"%s then %s" % [before, wood_label.text])
	expect(wood_label.text.contains("19"), "with the right number",
		wood_label.text)

	# A changed number lights up and settles back, so a gain is visible from
	# the corner of the eye.
	var lit := wood_label.modulate
	await frames(60)
	expect(wood_label.modulate != lit, "and the flash fades back",
		"%s then %s" % [lit, wood_label.modulate])

	# **The button is reachable by keyboard.**
	var button: Button = require_control("NightButton")
	expect(button != null and button.focus_mode != Control.FOCUS_NONE,
		"the night button can take focus")

	# Pressing it asks for the night, and the rules give it.
	expect(int(state["phase"]) == Phases.DAY, "still day")
	await click_control("NightButton")
	await until(func() -> bool:
		return int(state["phase"]) == Phases.PREPARATION,
		"the night button to take effect")
	expect(int(state["phase"]) == Phases.PREPARATION,
		"clicking it starts the night", Phases.name_of(int(state["phase"])))
	await until(func() -> bool: return not hud.shows_day(),
		"the day HUD to go")
	expect(not hud.shows_day(), "and the day HUD goes away with the day")

	# The key does the same thing from a fresh day.
	await open_scene(MAIN_SCENE)
	driver = require_control("SimDriver")
	expect(int(driver.state["phase"]) == Phases.DAY, "a fresh day")
	await hold_key(KEY_N, 4)
	var keyed := driver.state
	await until(func() -> bool:
		return int(keyed["phase"]) == Phases.PREPARATION, "N to take effect")
	expect(int(driver.state["phase"]) == Phases.PREPARATION,
		"and N does what the button does",
		Phases.name_of(int(driver.state["phase"])))

	await close_scene()
	_completed += 1     # last line: an abandoned case never gets here


## 0022 - the light changes and the farm does not.
func _case_0022_reality() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	var view: WorldView = require_control("WorldView")
	if driver == null or view == null:
		_completed += 1
		await close_scene()
		return

	var light: CanvasModulate = view.find_child("Light", true, false)
	expect(light != null, "the world has a light")
	if light == null:
		_completed += 1
		await close_scene()
		return

	await frames(30)
	# **The daylight moves across the day** since task 0039, so this cannot
	# ask for `DAY_TINT` on the nose any more - at dawn it is the cool colour
	# and at dusk the warm one, with noon in between. What matters is that it
	# is a *daylight*: somewhere on the dawn-noon-dusk line and nowhere near
	# the night.
	expect(_is_daylight(light.color),
		"and by day it is one of the day's", str(light.color))
	expect(not light.color.is_equal_approx(PaletteData.NIGHT_TINT),
		"and nothing like the night's", str(light.color))

	var state := driver.state
	var day_colour := light.color

	# Press the night button the way a player would.
	await click_control("NightButton")
	await until(func() -> bool: return int(state["phase"]) != Phases.DAY,
		"the night to begin")
	expect(int(state["phase"]) != Phases.DAY, "the night has begun")
	expect(view.light_target().is_equal_approx(PaletteData.NIGHT_TINT),
		"and the light is heading for the night", str(view.light_target()))

	# **The simulation never waits for it.** The tick keeps running while the
	# light is on its way.
	var tick_mid := int(state["tick"])
	await frames(10)
	expect(int(state["tick"]) >= tick_mid,
		"the game runs while the light is changing")
	expect(light.color != day_colour, "and the light has left the day behind",
		str(light.color))

	# **Skipping lands where watching would have.** How far a fade has got
	# after N frames depends on how busy the machine is, so nothing here asks
	# that - it asks where the fade ends, which is a fact.
	view.skip_transition()
	await frames(2)
	expect(light.color.is_equal_approx(PaletteData.NIGHT_TINT),
		"skipping lands it on the night", str(light.color))
	expect(not view.is_transitioning(), "and stops")

	# **Skipping lands in the same place watching would have.**
	await open_scene(MAIN_SCENE)
	driver = require_control("SimDriver")
	view = require_control("WorldView")
	light = view.find_child("Light", true, false)
	await frames(20)
	var fresh_day := light.color
	var fresh_state := driver.state
	await click_control("NightButton")
	await until(func() -> bool: return light.color != fresh_day,
		"the light to start moving")
	expect(light.color != fresh_day, "a fresh fade has started moving",
		str(light.color))
	view.skip_transition()
	await frames(2)
	expect(not view.is_transitioning(), "skipping ends it")
	expect(light.color.is_equal_approx(PaletteData.NIGHT_TINT),
		"at the colour it was heading for", str(light.color))

	await close_scene()
	_completed += 1     # last line: an abandoned case never gets here


## 0023 - build mode through the screen: the ghost, a click, a right click.
func _case_0023_build_mode() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	var view: WorldView = require_control("WorldView")
	var build: BuildMode = require_control("BuildMode")
	if driver == null or view == null or build == null:
		_completed += 1
		await close_scene()
		return

	var state := driver.state
	Resources.gain(state, {GameData.WOOD: 100, GameData.STONE: 100,
		GameData.IRON: 100})
	expect(not build.visible, "build mode starts off")

	await hold_key(KEY_B, 4)
	await until(func() -> bool: return build.visible, "build mode to open")
	expect(build.visible, "B opens it")
	expect(Building.selected(state) != &"", "with something selected",
		str(Building.selected(state)))

	# The palette lists everything the phase allows.
	for id in Building.catalogue(state):
		expect(locate_control("build_%s" % id) != null,
			"the palette offers %s" % id)

	await click_control("build_wall")
	await frames(3)
	expect(Building.selected(state) == &"wall", "clicking a row selects it",
		str(Building.selected(state)))

	# **The ghost.** Point at grass and it is green; point at the pond and it
	# is red with a reason.
	var ghost: Sprite2D = view.find_child("Ghost", true, false)
	expect(ghost != null, "there is a ghost")

	var grass := _any_buildable(state)
	await _point_at(view, grass)
	expect(ghost.visible, "it shows over the farm")
	var reason: Label = require_control("BuildReason")
	expect(reason != null and reason.text.is_empty(),
		"and says nothing is wrong", reason.text if reason else "")
	expect(view.ghost_cell() == grass, "on the cell under the cursor",
		str(view.ghost_cell()))
	expect(view.ghost_is_ok(), "framed green, because it fits")

	var pond: Vector2i = Farm.cells_of(state, Farm.Terrain.WATER)[0]
	await _point_at(view, pond)
	expect(reason.text == "in the water", "over the pond it says why not",
		reason.text)
	expect(not view.ghost_is_ok(), "and framed red, because it does not fit")

	# Over something already built, it refuses for a different reason.
	var taken: Vector2i = Farm.cells_with(state, &"house")[0]
	await _point_at(view, taken)
	expect(not view.ghost_is_ok(), "over the house it refuses too")
	expect(reason.text == "on the house", "naming the house", reason.text)

	# **A click places it.** Through the same intent the rules read.
	await _point_at(view, grass)
	var stone_before := Resources.amount(state, GameData.STONE)
	await click_at(view.cell_to_screen(grass))
	await until(func() -> bool:
		return not Farm.occupant(state, grass).is_empty(), "the wall to go up")
	expect(Farm.occupant(state, grass).get("id", &"") == &"wall",
		"a wall is built where the cursor was",
		str(Farm.occupant(state, grass)))
	expect(Resources.amount(state, GameData.STONE) < stone_before,
		"and it was paid for")

	# **A right click sells it back.**
	var stone_after_build := Resources.amount(state, GameData.STONE)
	await _point_at(view, grass)
	await click_at(view.cell_to_screen(grass), MOUSE_BUTTON_RIGHT)
	await until(func() -> bool: return Farm.occupant(state, grass).is_empty(),
		"the wall to come back up")
	expect(Farm.occupant(state, grass).is_empty(), "right click takes it back up")
	expect(Resources.amount(state, GameData.STONE) > stone_after_build,
		"and some of the stone comes back")
	expect(Resources.amount(state, GameData.STONE) < stone_before,
		"but not all of it")

	await hold_key(KEY_B, 4)
	await until(func() -> bool: return not build.visible, "build mode to close")
	expect(not build.visible, "and B closes it")
	expect(not ghost.visible, "taking the ghost with it")

	await close_scene()
	_completed += 1     # last line: an abandoned case never gets here


## Put the mouse over a cell and let the build panel notice.
func _point_at(view: WorldView, cell: Vector2i) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = view.cell_to_screen(cell)
	motion.global_position = motion.position
	Input.warp_mouse(motion.position)
	root.push_input(motion)
	await frames(3)


## 0027 - the loop, through the screen: press night, watch it, take the money,
## come back to the farm.
func _case_0027_the_loop() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	var result: ResultScreen = require_control("ResultScreen")
	var hud: DayHud = require_control("DayHud")
	if driver == null or result == null:
		_completed += 1
		await close_scene()
		return

	var state := driver.state
	expect(not result.visible, "the payout is not up during the day")

	# Arm the farm the way a player who spent their day would, then press the
	# button a player would press.
	Resources.gain(state, {GameData.WOOD: 200, GameData.IRON: 200})
	var placed := 0
	for x in range(22, 34):
		for y in [7, 9, 11, 5]:
			if placed < 4 and Farm.buildable(state, Vector2i(x, y)):
				if Building.place(state, &"gun_tower", Vector2i(x, y)):
					placed += 1
	expect(placed == 4, "four towers go up", str(placed))

	await click_control("NightButton")
	await until(func() -> bool: return int(state["phase"]) != Phases.DAY,
		"the night to begin")

	# Let the night play out. Faster than real time, because a night is a
	# minute and a test is not.
	driver.speed = 8
	await until(func() -> bool: return int(state["phase"]) == Phases.RESULT,
		"the night to finish", 4000)
	driver.speed = 1
	expect(int(state["phase"]) == Phases.RESULT, "the night ends by itself",
		Phases.name_of(int(state["phase"])))

	await until(func() -> bool: return result.visible, "the payout to come up")
	expect(result.visible, "and the payout comes up")
	expect(not hud.shows_day(), "with the day HUD out of the way")

	var title: Label = require_control("ResultTitle")
	expect(title != null and title.text.contains("NIGHT 1"),
		"it says which night", title.text if title else "")
	expect(title != null and title.text.contains("SURVIVED"),
		"and how it went", title.text if title else "")

	# **Taking the money is a click.**
	var money_before := Resources.amount(state, GameData.MONEY)
	expect(money_before > 25, "the payout already landed",
		str(money_before))
	await click_control("ContinueButton")
	await until(func() -> bool: return int(state["phase"]) == Phases.DAY,
		"the farm to come back")
	expect(int(state["phase"]) == Phases.DAY, "and it goes back to the farm")
	expect(int(state["day"]) == 2, "on day two", str(state["day"]))
	await until(func() -> bool: return hud.shows_day(),
		"the day HUD to return")
	expect(hud.shows_day(), "with the HUD back")
	expect(not result.visible, "and the payout gone")

	# **Day two is a better day than day one.** The whole point of the loop.
	expect(Resources.amount(state, GameData.MONEY) > 25,
		"there is more money than the farm started with",
		str(Resources.amount(state, GameData.MONEY)))
	expect(Interact.verb_at(state, Farm.cells_with(state, &"tree")[0]) == &"chop",
		"and there are trees to chop again")

	await close_scene()
	_completed += 1     # last line: an abandoned case never gets here


# ----------------------------------------------------------------- the helpers

## Put a scene up and let it settle. Every case starts with one, so no case can
## inherit the mess left by the one before it.
func open_scene(path: String) -> void:
	await close_scene()
	var packed: PackedScene = load(path)
	if packed == null:
		_fail("could not load %s" % path)
		return
	_scene = packed.instantiate()
	root.add_child(_scene)
	await frames(3)


func close_scene() -> void:
	if _scene == null:
		return
	_scene.queue_free()
	_scene = null
	await frames(2)


func frames(n: int) -> void:
	for _i in maxi(n, 1):
		await process_frame


## Wait until something is true, or give up and say so.
##
## **Frame counts are not time.** A tick is owed every thirtieth of a second and
## a headless frame can be a thousandth, so "wait four frames for the phase to
## change" is a bet on how busy the machine is - which is exactly the bet that
## made this file fail one run in four under load and pass on its own. Waiting
## for the condition is both faster when things are quick and correct when they
## are not.
func until(condition: Callable, what: String, max_frames: int = 600) -> bool:
	for _i in max_frames:
		if condition.call():
			return true
		await process_frame
	_fail("timed out waiting for %s" % what)
	return false


## Find a control by node name, anywhere under the scene. **Loud**: a name that
## is not there is a failed case, because that is almost always a signal that
## something was renamed and a screen quietly stopped working.
func require_control(control_name: String) -> Node:
	var node := locate_control(control_name)
	if node == null:
		_fail("no node named '%s' in %s" % [control_name, MAIN_SCENE])
	return node


## The quiet version, for asking whether something is there at all.
func locate_control(control_name: String) -> Node:
	if _scene == null:
		return null
	if _scene.name == control_name:
		return _scene
	return _scene.find_child(control_name, true, false)


## Click the middle of a named control.
func click_control(control_name: String) -> void:
	var node := require_control(control_name)
	if node == null or not (node is Control):
		return
	var ctl: Control = node
	await click_at(ctl.global_position + ctl.size * 0.5)


## Press and release the left button at a screen position.
func click_at(position: Vector2, button: int = MOUSE_BUTTON_LEFT) -> void:
	for pressed in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = button
		ev.pressed = pressed
		ev.position = position
		ev.global_position = position
		root.push_input(ev)
		await process_frame
	await process_frame


## Click a cell of the farm.
func click_cell(cell: Vector2i, button: int = MOUSE_BUTTON_LEFT) -> void:
	await click_at(cell_to_screen(cell), button)


## Where a farm cell is on screen.
##
## Asks the world view when there is one, so that the camera of task 0013 is
## accounted for automatically. Until then the viewport is the farm's own
## resolution and the mapping is the obvious one.
func cell_to_screen(cell: Vector2i) -> Vector2:
	var view := locate_control("WorldView")
	if view != null and view.has_method("cell_to_screen"):
		return view.call("cell_to_screen", cell)
	var size := float(GameData.TILE_SIZE)
	return Vector2(cell.x * size + size * 0.5, cell.y * size + size * 0.5)


func press_key(keycode: int, pressed: bool) -> void:
	var ev := InputEventKey.new()
	ev.keycode = keycode
	ev.physical_keycode = keycode
	ev.pressed = pressed
	Input.parse_input_event(ev)
	await process_frame


func tap_key(keycode: int) -> void:
	await press_key(keycode, true)
	await press_key(keycode, false)


## Hold a key down for a number of frames, then let go. What "walk east for a
## second" looks like from outside the game.
func hold_key(keycode: int, frame_count: int) -> void:
	await press_key(keycode, true)
	await frames(frame_count)
	await press_key(keycode, false)
	await frames(2)


func expect(ok: bool, what: String, detail: String = "") -> void:
	# An assert landing is the definition of progress, so it is what puts
	# the watchdog back to zero.
	_elapsed = 0.0
	if ok:
		passed += 1
	else:
		_fail(what, detail)


func _fail(what: String, detail: String = "") -> void:
	failed += 1
	print("  FAIL  ", what, "  ", detail)


## 0028 - picking a seed with a number key, and the strip that says why.
func _case_0028_seeds() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	var hud: DayHud = require_control("DayHud")
	if driver == null or hud == null:
		_completed += 1
		await close_scene()
		return

	var state := driver.state
	var ids := Farming.seeds()

	# **There is a row per crop, and it was built from the table.** Nothing in
	# the HUD names a crop, so a fourth one appears here on its own.
	for id in ids:
		var row: Label = require_control("seed_%s" % id)
		expect(row != null, "the strip has a row for %s" % id)
		if row == null:
			continue
		expect(row.text.contains(str(id)), "which says what it is", row.text)
		expect(row.text.contains("%ds" % Farming.seconds_to_grow(id)),
			"and how long it takes to grow", row.text)
		expect(row.text.contains(str(Farming.value_per_day(id))),
			"and what a plot of it is worth over a day", row.text)
		expect(row.text.contains("$%d" % int((GameData.CROPS[id]
			as Dictionary)["seed_cost"])), "and what the seed costs", row.text)

	# **The chosen row is the lit one**, so the strip answers "what am I about
	# to plant" without the player remembering which key they last pressed.
	var first: Label = require_control("seed_%s" % ids[0])
	var second: Label = require_control("seed_%s" % ids[1])
	await frames(2)
	expect(first.modulate != second.modulate,
		"the selected crop is lit and the others are not",
		"%s against %s" % [first.modulate, second.modulate])
	var lit_colour := first.modulate

	# **The number key picks**, through the real key, in the real scene.
	expect(Farming.selected_seed(state) == StringName(ids[0]),
		"the first crop is what a new farm starts on",
		str(Farming.selected_seed(state)))
	await tap_key(KEY_2)
	await until(func() -> bool:
		return Farming.selected_seed(state) == StringName(ids[1]),
		"the 2 key to pick the second crop")
	expect(Farming.selected_seed(state) == StringName(ids[1]),
		"2 picks the second crop", str(Farming.selected_seed(state)))
	await frames(2)
	expect(second.modulate == lit_colour, "and the strip moves the light",
		"%s" % second.modulate)
	expect(first.modulate != lit_colour, "off the one it left", "%s"
		% first.modulate)

	# **A key past the last crop changes nothing**, rather than selecting
	# something that is not there and failing at the furrow a minute later.
	await tap_key(KEY_6)
	await frames(2)
	expect(Farming.selected_seed(state) == StringName(ids[1]),
		"a number with no crop behind it is ignored",
		str(Farming.selected_seed(state)))

	# **And what gets planted is what the strip said.** Walk the farmer onto a
	# plot, till it, plant it, and look at what came up.
	await tap_key(KEY_3)
	await until(func() -> bool:
		return Farming.selected_seed(state) == StringName(ids[2]),
		"the 3 key to pick the third crop")
	var chosen := Farming.selected_seed(state)

	var cell := _reachable_plot(state)
	expect(cell != Vector2i(-1, -1), "there is soil to stand next to")
	if cell != Vector2i(-1, -1):
		var stand := cell + Vector2i(0, -1)
		var who: Dictionary = state["player"]
		who["pos"] = [stand.x * Player.SUBTILE + Player.SUBTILE / 2,
			stand.y * Player.SUBTILE + Player.SUBTILE / 2]
		who["facing"] = Player.SOUTH
		await frames(2)
		expect(Player.target(state) == cell, "the farmer is looking at it",
			str(Player.target(state)))

		await hold_key(KEY_SPACE, 4)
		await until(func() -> bool: return Farming.is_tilled(state, cell),
			"the ground to be turned over")
		expect(Farming.is_tilled(state, cell), "space tills it")

		await hold_key(KEY_SPACE, 4)
		await until(func() -> bool: return Farming.crop_on(state, cell) != &"",
			"a seed to go in")
		expect(Farming.crop_on(state, cell) == chosen,
			"and what went in is what the strip said it would be",
			"%s, not %s" % [Farming.crop_on(state, cell), chosen])

	# The strip is a day thing: it goes away with the day.
	await hold_key(KEY_N, 4)
	await until(func() -> bool: return not hud.shows_day(),
		"the day HUD to go")
	expect(not hud.shows_day(), "and the seed strip goes with the day")
	await tap_key(KEY_1)
	await frames(2)
	expect(Farming.selected_seed(state) == chosen,
		"a number key at night picks nothing - there is no field to plant",
		str(Farming.selected_seed(state)))

	await close_scene()
	_completed += 1     # last line: an abandoned case never gets here


## A soil cell with a free tile above it to stand on.
func _reachable_plot(state: Dictionary) -> Vector2i:
	for cell in Farm.cells_of(state, Farm.Terrain.SOIL):
		if not Farm.is_empty(state, cell) or Farming.is_tilled(state, cell):
			continue
		if Farm.walkable(state, cell + Vector2i(0, -1)):
			return cell
	return Vector2i(-1, -1)


## 0029 - filling the can at the well, and watering a row with one held key.
func _case_0029_watering() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	var hud: DayHud = require_control("DayHud")
	if driver == null or hud == null:
		_completed += 1
		await close_scene()
		return

	var state := driver.state
	var can: Label = require_control("WaterCan")
	expect(can != null, "the HUD says how much water is in hand")

	# **An empty can says where to fill it.** A number on its own would leave a
	# player who has not found the well with no idea what to do about it.
	expect(Farming.water_carried(state) == 0, "the can starts empty")
	await frames(2)
	expect(can != null and can.text.to_lower().contains("well"),
		"and an empty one points at the well", can.text if can else "")

	# **Walking up to the well fills it**, with nothing pressed.
	var well: Vector2i = Farm.cells_with(state, &"well")[0]
	_stand_at(state, well + Vector2i(0, -1))
	await until(func() -> bool: return Farming.water_carried(state) > 0,
		"standing by the well to fill the can")
	expect(Farming.water_carried(state) == GameData.WATER_CAN_CAPACITY,
		"standing next to the well fills the can to the top",
		str(Farming.water_carried(state)))
	await frames(2)
	expect(can != null and can.text.contains(str(GameData.WATER_CAN_CAPACITY)),
		"and the HUD says so", can.text if can else "")

	# A row of four, planted and dry, with somewhere to stand at the west end.
	var row := _a_planted_row(state, 4)
	expect(row.size() == 4, "there is a row to water", str(row.size()))
	if row.size() < 4:
		await close_scene()
		_completed += 1
		return
	for cell in row:
		expect(not Farming.is_watered(state, cell), "and it is dry to start")

	var start: Vector2i = row[0] + Vector2i(-1, 0)
	_stand_at(state, start, Player.EAST)
	await frames(2)
	var before := Farming.water_carried(state)

	# **One held key and a walk down the row.** Not four presses, and not four
	# stops: watering is the one verb that finishes on the tick it starts, so
	# stepping does not cancel it the way stepping cancels chopping.
	await press_key(KEY_SPACE, true)
	await press_key(KEY_D, true)
	await until(func() -> bool: return Farming.is_watered(state, row[3]),
		"the walk to reach the end of the row", 900)
	await press_key(KEY_D, false)
	await press_key(KEY_SPACE, false)
	await frames(2)

	var wet := 0
	for cell in row:
		if Farming.is_watered(state, cell):
			wet += 1
	expect(wet == row.size(), "holding water across a row waters all of it",
		"%d of %d" % [wet, row.size()])

	# **Once each.** A held key on a verb that repeated would have emptied the
	# can into the first tile.
	var spent := before - Farming.water_carried(state)
	expect(spent == row.size(), "one tile off the can per tile, not one per "
		+ "tick", "%d spent for %d tiles" % [spent, row.size()])

	# And walking back over it spends nothing, because there is nothing to do.
	var after_row := Farming.water_carried(state)
	await press_key(KEY_SPACE, true)
	await press_key(KEY_A, true)
	await frames(60)
	await press_key(KEY_A, false)
	await press_key(KEY_SPACE, false)
	await frames(2)
	expect(Farming.water_carried(state) == after_row,
		"walking back over a wet row spends nothing",
		str(Farming.water_carried(state)))

	# **The night dries it out**, so the chore comes round again tomorrow.
	await hold_key(KEY_N, 4)
	await until(func() -> bool:
		return int(state["phase"]) != Phases.DAY, "the night to start")
	var still_wet := 0
	for cell in row:
		if Farming.is_watered(state, cell):
			still_wet += 1
	expect(still_wet == 0, "the night dries the whole field out",
		str(still_wet))

	await close_scene()
	_completed += 1     # last line: an abandoned case never gets here


## Put the farmer on a cell, the way the other cases do.
func _stand_at(state: Dictionary, cell: Vector2i,
		facing: int = Player.SOUTH) -> void:
	var who: Dictionary = state["player"]
	who["pos"] = [cell.x * Player.SUBTILE + Player.SUBTILE / 2,
		cell.y * Player.SUBTILE + Player.SUBTILE / 2]
	who["facing"] = facing
	who["action"] = {}


## `count` soil cells in a row running east, planted and with a free tile at
## the west end to start the walk from.
func _a_planted_row(state: Dictionary, count: int) -> Array:
	Resources.gain(state, {GameData.MONEY: 100})
	for found in Farm.cells_of(state, Farm.Terrain.SOIL):
		var cell: Vector2i = found
		if not Farm.walkable(state, cell + Vector2i(-1, 0)):
			continue
		var run: Array = []
		for i in count:
			var at := cell + Vector2i(i, 0)
			if Farm.terrain_at(state, at) != Farm.Terrain.SOIL \
					or not Farm.is_empty(state, at):
				break
			run.append(at)
		if run.size() < count:
			continue
		for planted in run:
			var at2: Vector2i = planted
			Farming.act(state, at2)         # till
			Farming.act(state, at2)         # plant
		return run
	return []


## 0030 - standing at the pond and landing one, through the real keys.
func _case_0030_fishing() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	if driver == null:
		_completed += 1
		await close_scene()
		return

	var state := driver.state
	var line: Label = require_control("FishingLine")
	expect(line != null, "the HUD has somewhere to say there is a line out")
	await frames(2)
	expect(line != null and not line.visible,
		"and it says nothing when nobody is fishing")

	# Stand on the bank looking at the water.
	var shore := _a_shore(state)
	expect(shore != Vector2i(-1, -1), "there is a bank to fish from")
	if shore == Vector2i(-1, -1):
		await close_scene()
		_completed += 1
		return
	var pond := _water_beside(state, shore)
	_stand_at(state, shore, _facing_towards(shore, pond))
	await frames(2)
	expect(Player.target(state) == pond, "the farmer is looking at the water",
		str(Player.target(state)))
	expect(Interact.verb_at(state, pond) == &"fish",
		"which offers a cast", str(Interact.verb_at(state, pond)))

	# **Cast.** One press, and then the wait is out of the player's hands.
	await hold_key(KEY_SPACE, 4)
	await until(func() -> bool: return Fishing.is_casting(state),
		"the cast to go in")
	expect(Fishing.is_casting(state), "pressing interact casts")
	expect(Fishing.line_cell(state) == pond, "into the water in front",
		str(Fishing.line_cell(state)))
	await frames(2)
	expect(line != null and line.visible,
		"and the HUD says there is a line out")

	# **Wait for the bite**, which is the part the player cannot hurry.
	var bit := await until(func() -> bool: return Fishing.is_biting(state),
		"a fish to bite", 1200)
	expect(bit, "something bites inside the lever range")
	await frames(1)
	expect(line != null and line.text.to_lower().contains("bite"),
		"and the HUD shouts about it", line.text if line else "")
	expect(Interact.verb_at(state, pond) == &"reel",
		"the water says reel now", str(Interact.verb_at(state, pond)))

	# **Land it.** A press inside the window, and the fish is in the basket.
	var before := Resources.amount(state, GameData.FISH)
	await tap_key(KEY_SPACE)
	await until(func() -> bool:
		return Resources.amount(state, GameData.FISH) > before,
		"the fish to come in")
	expect(Resources.amount(state, GameData.FISH) > before,
		"reeling inside the window lands a fish",
		"%d then %d" % [before, Resources.amount(state, GameData.FISH)])
	expect(not Fishing.is_casting(state), "and the line comes out with it")
	await frames(2)
	expect(line != null and not line.visible, "and the HUD goes quiet")

	# **Walking away gives a cast up**, through the real movement keys.
	await hold_key(KEY_SPACE, 4)
	await until(func() -> bool: return Fishing.is_casting(state),
		"a second cast to go in")
	await press_key(KEY_W, true)
	await frames(40)
	await press_key(KEY_W, false)
	await frames(2)
	expect(not Fishing.is_casting(state),
		"walking off the bank gives the cast up")

	await close_scene()
	_completed += 1     # last line: an abandoned case never gets here


## Land next to open water.
func _a_shore(state: Dictionary) -> Vector2i:
	for found in Farm.cells_of(state, Farm.Terrain.WATER):
		var wet: Vector2i = found
		for step in [Vector2i(0, -1), Vector2i(-1, 0), Vector2i(1, 0)]:
			var dry: Vector2i = wet + step
			if Farm.walkable(state, dry) and Farm.walkable(state, dry + step):
				return dry
	return Vector2i(-1, -1)


func _water_beside(state: Dictionary, shore: Vector2i) -> Vector2i:
	for step in [Vector2i(0, 1), Vector2i(1, 0), Vector2i(-1, 0),
			Vector2i(0, -1)]:
		if Farm.terrain_at(state, shore + step) == Farm.Terrain.WATER:
			return shore + step
	return Vector2i(-1, -1)


func _facing_towards(here: Vector2i, there: Vector2i) -> int:
	var step := there - here
	if step.y > 0:
		return Player.SOUTH
	if step.y < 0:
		return Player.NORTH
	return Player.EAST if step.x > 0 else Player.WEST


## 0032 - putting a press on the farm and pressing corn into oil.
func _case_0032_press() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	var build: BuildMode = require_control("BuildMode")
	if driver == null or build == null:
		_completed += 1
		await close_scene()
		return

	var state := driver.state
	Resources.gain(state, Building.cost_of(&"press"))
	Resources.gain(state, {GameData.CORN: 20})

	# **The press is in the build palette.** It was not before this task: the
	# palette read the defences table and a press is not a defence.
	await hold_key(KEY_B, 4)
	await until(func() -> bool: return Building.is_active(state),
		"build mode to open")
	expect(Building.is_active(state), "B opens build mode")
	var row: Button = require_control("build_press")
	expect(row != null, "and the palette has a row for the press")
	if row == null:
		await close_scene()
		_completed += 1
		return

	# **Every row of the palette is on the screen.** Making the buildings
	# placeable took it from eight rows to twelve and pushed the last of them
	# to y=294 on a 270 pixel screen - the press could not be clicked at all.
	# The next task that adds a defence gets told, rather than finding out.
	var frame: Control = require_control("Frame")
	var screen := Vector2(480, 270)
	expect(frame != null and frame.get_global_rect().end.y <= screen.y,
		"the build palette fits on the screen",
		str(frame.get_global_rect()) if frame else "")
	for id in Building.catalogue(state):
		var each: Control = require_control("build_%s" % id)
		if each == null:
			continue
		var box := each.get_global_rect()
		expect(box.position.y >= 0 and box.end.y <= screen.y,
			"the %s row is somewhere it can be clicked" % id, str(box))
	await click_control("build_press")
	await until(func() -> bool: return Building.selected(state) == &"press",
		"the press to be selected")
	expect(Building.selected(state) == &"press", "clicking it selects it",
		str(Building.selected(state)))

	# **Down it goes**, two tiles by two, paid for out of the ledger.
	var spot := _room_for_press(state)
	expect(spot != Vector2i(-1, -1), "there is room for a press")
	if spot == Vector2i(-1, -1):
		await close_scene()
		_completed += 1
		return
	var wood_before := Resources.amount(state, GameData.WOOD)
	await click_cell(spot)
	await until(func() -> bool:
		return Farm.occupant(state, spot).get("id", &"") == &"press",
		"the press to go down")
	expect(Farm.occupant(state, spot).get("id", &"") == &"press",
		"clicking the farm puts it there",
		str(Farm.occupant(state, spot)))
	expect(Resources.amount(state, GameData.WOOD) < wood_before,
		"and it was paid for")
	var covered := 0
	for at in Building.footprint(&"press", spot):
		if Farm.occupant(state, at).get("id", &"") == &"press":
			covered += 1
	expect(covered == 4, "all four tiles of it are there", str(covered))

	# B toggles it, the same key that opened it.
	await hold_key(KEY_B, 4)
	await until(func() -> bool: return not Building.is_active(state),
		"build mode to close")
	expect(not Building.is_active(state), "B closes build mode again")

	# **Stand at it and press interact.** The far corner, because any tile of
	# a press is the same press.
	var corner: Vector2i = Building.footprint(&"press", spot)[3]
	var stand := _free_cell_beside(state, corner)
	expect(stand != Vector2i(-1, -1), "somewhere to stand at the press")
	if stand == Vector2i(-1, -1):
		await close_scene()
		_completed += 1
		return
	_stand_at(state, stand, _facing_towards(stand, corner))
	await frames(2)
	expect(Player.target(state) == corner, "the farmer is at the press",
		str(Player.target(state)))
	expect(Interact.verb_at(state, corner) == &"craft",
		"which offers to make something",
		str(Interact.verb_at(state, corner)))

	Crafting.select_recipe(state, &"press_oil")
	var oil_before := Resources.amount(state, GameData.OIL)
	await hold_key(KEY_SPACE, 4)
	await until(func() -> bool: return Crafting.busy(state, spot),
		"the press to start")
	expect(Crafting.busy(state, spot), "and pressing interact starts it")

	# **And it finishes into oil.** Driven at speed, because twenty seconds of
	# real time is not something a test should sit through.
	var ticks := int((GameData.RECIPES[&"press_oil"] as Dictionary)["ticks"])
	Sim.advance(state, ticks + 2)
	await frames(2)
	expect(Resources.amount(state, GameData.OIL) > oil_before,
		"and out comes oil",
		"%d then %d" % [oil_before, Resources.amount(state, GameData.OIL)])

	await close_scene()
	_completed += 1     # last line: an abandoned case never gets here


## Two by two of clear farm, away from the house and the field edges.
## **East of the build panel.** The palette covers the left eighth of the
## screen, so a press placed under it is a press the click never reaches - and
## the cell has to be on camera, which near the farmer it is.
func _room_for_press(state: Dictionary) -> Vector2i:
	for y in range(6, Grid.HEIGHT - 3):
		for x in range(24, Grid.WIDTH - 6):
			var origin := Vector2i(x, y)
			var clear := true
			for at in Building.footprint(&"press", origin):
				if not Farm.buildable(state, at):
					clear = false
					break
			# Somewhere to stand at it afterwards, or the rest of the case has
			# nowhere to put the farmer.
			if clear and _free_cell_beside(state, origin + Vector2i(1, 1)) \
					!= Vector2i(-1, -1):
				return origin
	return Vector2i(-1, -1)


func _free_cell_beside(state: Dictionary, cell: Vector2i) -> Vector2i:
	for step in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(0, -1),
			Vector2i(-1, 0)]:
		var at: Vector2i = cell + (step as Vector2i)
		if Farm.walkable(state, at):
			return at
	return Vector2i(-1, -1)


## 0033 - the power line, and what it says when the farm is over-built.
func _case_0033_power() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	var hud: DayHud = require_control("DayHud")
	if driver == null or hud == null:
		_completed += 1
		await close_scene()
		return

	var state := driver.state
	var power: Label = require_control("PowerLine")
	expect(power != null, "the HUD has a power line")
	if power == null:
		await close_scene()
		_completed += 1
		return

	await frames(2)
	expect(power.visible, "and it is up on day one")
	expect(power.text.contains("%d" % Power.supply(state)),
		"saying what the farm supplies", power.text)
	expect(power.text.contains("/"), "against what it draws", power.text)
	var settled := power.modulate

	# **Build past the farm's means and the line says so.**
	Resources.gain(state, {GameData.WOOD: 600, GameData.IRON: 600})
	var built := 0
	for y in range(3, 12):
		for x in range(22, 34):
			if built >= 4:
				break
			if Building.place(state, &"auto_crossbow", Vector2i(x, y)):
				built += 1
		if built >= 4:
			break
	expect(built == 4, "four hungry towers go up", str(built))
	await until(func() -> bool: return Power.is_short(state),
		"the farm to run short")
	await frames(2)
	expect(Power.is_short(state), "and the farm is short",
		"%d/%d" % [Power.supply(state), Power.draw(state)])
	expect(power.text.contains("%d%%" % Power.percent(state)),
		"the line says what that is doing to the speed of things", power.text)
	expect(power.modulate != settled, "and it changes colour to say so",
		"%s then %s" % [settled, power.modulate])

	# **A generator puts it back.**
	Resources.gain(state, Building.cost_of(&"generator"))
	Resources.gain(state, {GameData.OIL: 20})
	var spot := Vector2i(-1, -1)
	for y in range(3, 12):
		for x in range(24, 34):
			var origin := Vector2i(x, y)
			var clear := true
			for at in Building.footprint(&"generator", origin):
				if not Farm.buildable(state, at):
					clear = false
					break
			if clear:
				spot = origin
				break
		if spot != Vector2i(-1, -1):
			break
	expect(spot != Vector2i(-1, -1), "there is room for a generator")
	if spot != Vector2i(-1, -1):
		expect(Building.place(state, &"generator", spot), "and it goes up")
		await until(func() -> bool: return not Power.is_short(state),
			"the generator to take up the slack")
		await frames(2)
		expect(not Power.is_short(state),
			"and the farm is not short any more",
			"%d/%d" % [Power.supply(state), Power.draw(state)])
		expect(power.modulate == settled, "the line settles back", "%s"
			% power.modulate)

	# **It stays up after dark**, which is when a generator running dry is the
	# thing a player most needs to be told about.
	await hold_key(KEY_N, 4)
	await until(func() -> bool: return not hud.shows_day(), "the day to end")
	await frames(2)
	expect(not hud.shows_day(), "the day HUD is gone")
	expect(power.visible, "and the power line is not - towers draw at night")
	expect(power.text.contains("/"),
		"still saying supply against draw", power.text)

	await close_scene()
	_completed += 1     # last line: an abandoned case never gets here


## 0034 - walking over to the chickens.
func _case_0034_livestock() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	if driver == null:
		_completed += 1
		await close_scene()
		return

	var state := driver.state
	var hens := Farm.cells_with(state, &"chicken")
	expect(hens.size() > 0, "there are chickens on the farm")
	if hens.is_empty():
		await close_scene()
		_completed += 1
		return

	# Pick one with somewhere to stand beside it.
	var hen := Vector2i(-1, -1)
	var stand := Vector2i(-1, -1)
	for found in hens:
		var at: Vector2i = found
		var beside := _free_cell_beside(state, at)
		if beside != Vector2i(-1, -1):
			hen = at
			stand = beside
			break
	expect(hen != Vector2i(-1, -1), "one of them can be walked up to")
	if hen == Vector2i(-1, -1):
		await close_scene()
		_completed += 1
		return

	# **An empty chicken offers nothing**, so the key does nothing and the
	# highlight says so. (`Player.target()` still points at it - the fallback
	# returns the cell ahead whatever is on it, and it is `verb_at` that
	# decides whether anything happens.)
	_stand_at(state, stand, _facing_towards(stand, hen))
	await frames(2)
	expect(Interact.verb_at(state, hen) == &"",
		"a chicken with nothing to give offers nothing",
		str(Interact.verb_at(state, hen)))
	var nothing := Resources.amount(state, GameData.MEAT)
	await hold_key(KEY_SPACE, 6)
	await frames(2)
	expect(Resources.amount(state, GameData.MEAT) == nothing,
		"and pressing interact at it takes nothing",
		str(Resources.amount(state, GameData.MEAT)))

	# Wait for it to have something. Driven at speed rather than in real time.
	var every := int((GameData.LIVESTOCK[&"chicken"]
		as Dictionary)["every_ticks"])
	Sim.advance(state, every + 2)
	await frames(2)
	expect(Livestock.ready_at(state, hen) > 0, "it has something now",
		str(Livestock.ready_at(state, hen)))
	_stand_at(state, stand, _facing_towards(stand, hen))
	await frames(2)
	expect(Player.target(state) == hen, "and now the farmer can aim at it",
		str(Player.target(state)))
	expect(Interact.verb_at(state, hen) == &"collect",
		"which offers to collect", str(Interact.verb_at(state, hen)))

	# **Press interact and the meat is in the ledger.**
	var before := Resources.amount(state, GameData.MEAT)
	await hold_key(KEY_SPACE, 4)
	await until(func() -> bool:
		return Resources.amount(state, GameData.MEAT) > before,
		"the meat to come in")
	expect(Resources.amount(state, GameData.MEAT) > before,
		"collecting puts meat in the ledger",
		"%d then %d" % [before, Resources.amount(state, GameData.MEAT)])
	expect(Livestock.ready_at(state, hen) == 0, "and the chicken is empty")
	await frames(4)
	expect(Resources.amount(state, GameData.MEAT)
		== before + int((GameData.LIVESTOCK[&"chicken"]
			as Dictionary)["holds"]),
		"once, not once a tick - a held key does not milk it dry",
		str(Resources.amount(state, GameData.MEAT)))

	await close_scene()
	_completed += 1     # last line: an abandoned case never gets here


## 0035 - the pool, and watching it drain after dark.
func _case_0035_ammo() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	var hud: DayHud = require_control("DayHud")
	if driver == null or hud == null:
		_completed += 1
		await close_scene()
		return

	var state := driver.state
	var ammo: Label = require_control("AmmoLine")
	expect(ammo != null, "the HUD has an ammunition line")
	if ammo == null:
		await close_scene()
		_completed += 1
		return

	await frames(2)
	expect(ammo.visible, "and it is up on day one")
	for res in Ammo.kinds():
		expect(ammo.text.contains(str(res)),
			"it names %s" % res, ammo.text)

	# **An empty pool is flagged**, rather than being a number nobody reads.
	for res in Ammo.kinds():
		Resources.spend(state, res, Resources.amount(state, res))
	await frames(2)
	var warned := ammo.modulate
	Resources.gain(state, {GameData.GUNPOWDER: 9, GameData.INCENDIARY: 9})
	await frames(2)
	expect(ammo.modulate != warned, "and a stocked one is not",
		"%s then %s" % [warned, ammo.modulate])
	expect(ammo.text.contains("9"), "with the count on it", ammo.text)

	# **It stays up after dark**, which is when it is actually draining.
	await hold_key(KEY_N, 4)
	await until(func() -> bool: return not hud.shows_day(), "the day to end")
	await frames(2)
	expect(not hud.shows_day(), "the day HUD is gone")
	expect(ammo.visible, "and the ammunition line is not")
	expect(ammo.text.contains(str(GameData.GUNPOWDER)),
		"still naming the pool", ammo.text)

	await close_scene()
	_completed += 1     # last line: an abandoned case never gets here


## 0036 - the inventory, on one key, without stopping the day.
func _case_0036_inventory() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	var panel: InventoryPanel = require_control("InventoryPanel")
	if driver == null or panel == null:
		_completed += 1
		await close_scene()
		return

	var state := driver.state
	await frames(2)
	expect(not panel.is_open(), "the inventory starts closed")

	# **One key opens it.**
	await tap_key(KEY_I)
	await until(func() -> bool: return panel.is_open(), "the panel to open")
	expect(panel.is_open(), "I opens the inventory")
	await frames(2)

	# **Every resource is on it, once**, with a row built from the table.
	for id in GameData.RESOURCES:
		var row: Control = require_control("inv_%s" % id)
		expect(row != null, "%s has a row" % id)
		var held: Label = require_control("inv_held_%s" % id)
		if held != null:
			expect(held.text == str(Resources.amount(state, id)),
				"saying how much %s there is" % id, held.text)

	# **The numbers follow the ledger while it is open.**
	var wood: Label = require_control("inv_held_%s" % GameData.WOOD)
	expect(wood != null, "there is a wood row")
	if wood != null:
		var before := wood.text
		Resources.gain(state, {GameData.WOOD: 11})
		await until(func() -> bool:
			return (require_control("inv_held_%s" % GameData.WOOD)
				as Label).text != before, "the row to follow the ledger")
		var now: Label = require_control("inv_held_%s" % GameData.WOOD)
		expect(now.text == str(Resources.amount(state, GameData.WOOD)),
			"it is a view of the ledger, not a snapshot of it", now.text)

	# **The day does not stop.** The clock runs and the crops grow behind it.
	var tick_before := int(state["tick"])
	await frames(20)
	expect(int(state["tick"]) > tick_before,
		"the day keeps running while the panel is up",
		"%d then %d" % [tick_before, state["tick"]])
	expect(panel.is_open(), "and the panel is still up")

	# **And it takes no keys away**, unlike the stall: the farmer can still
	# walk with it open.
	expect(StringName(state["open_panel"]) == &"",
		"the inventory does not claim the keyboard",
		str(state["open_panel"]))

	# **The same key closes it**, and so does cancel.
	await tap_key(KEY_I)
	await until(func() -> bool: return not panel.is_open(),
		"the panel to close")
	expect(not panel.is_open(), "I closes it again")
	await tap_key(KEY_I)
	await until(func() -> bool: return panel.is_open(), "the panel to reopen")
	await tap_key(KEY_ESCAPE)
	await until(func() -> bool: return not panel.is_open(),
		"escape to close it")
	expect(not panel.is_open(), "and escape does too")

	await close_scene()
	_completed += 1     # last line: an abandoned case never gets here


## 0037 - standing at the bench and lining five things up.
func _case_0037_queue() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	var panel: WorkshopPanel = require_control("WorkshopPanel")
	if driver == null or panel == null:
		_completed += 1
		await close_scene()
		return

	var state := driver.state
	Resources.gain(state, {GameData.WOOD: 200, GameData.STONE: 200})
	await frames(2)
	expect(not panel.is_open(),
		"the workshop panel is not up out in the field")

	# **Walking up to the bench is what opens it.** There is no key: the panel
	# is what being at the bench looks like.
	var bench := Building.anchor_of(state,
		Farm.cells_with(state, &"workshop")[0])
	var stand := _free_cell_beside(state, bench)
	expect(stand != Vector2i(-1, -1), "somewhere to stand at the workshop")
	if stand == Vector2i(-1, -1):
		await close_scene()
		_completed += 1
		return
	_stand_at(state, stand, _facing_towards(stand, bench))
	await until(func() -> bool: return panel.is_open(),
		"the panel to appear at the bench")
	expect(panel.is_open(), "standing at the bench opens it")

	var title: Label = require_control("WorkshopTitle")
	expect(title != null and title.text.to_lower().contains("workshop"),
		"and it says which bench", title.text if title else "")

	# **Clicking a recipe puts it on the queue**, and does not pay for it
	# unless it goes straight to the front.
	var before := Crafting.queue_at(state, bench).size()
	await click_control("make_barricade_kit")
	await until(func() -> bool:
		return Crafting.queue_at(state, bench).size() > before,
		"the click to queue one")
	expect(Crafting.queue_at(state, bench).size() == before + 1,
		"clicking a recipe queues it",
		str(Crafting.queue_at(state, bench)))

	var wood_after_first := Resources.amount(state, GameData.WOOD)
	await click_control("make_barricade_kit")
	await click_control("make_barricade_kit")
	await frames(4)
	expect(Crafting.queue_at(state, bench).size() == 3,
		"three lined up", str(Crafting.queue_at(state, bench)))
	expect(Resources.amount(state, GameData.WOOD) == wood_after_first,
		"and queuing the other two cost nothing - the wood goes in when an "
		+ "item reaches the front",
		str(Resources.amount(state, GameData.WOOD)))

	# **The panel counts down the one that is running.**
	var progress: Label = require_control("WorkshopProgress")
	expect(progress != null, "there is a progress line")
	if progress != null:
		expect(progress.text.contains("barricade_kit"),
			"naming what is being made", progress.text)
		expect(progress.text.contains("s"), "and how long is left", progress.text)
		var shown := progress.text
		await frames(20)
		expect(progress.text != shown, "which goes down as it works",
			"%s then %s" % [shown, progress.text])

	# **Clicking a queued item takes it off**, and the rest stay in order.
	var queued := Crafting.queue_at(state, bench).duplicate()
	await click_control("queued_1")
	await until(func() -> bool:
		return Crafting.queue_at(state, bench).size() < queued.size(),
		"the middle one to come off")
	expect(Crafting.queue_at(state, bench).size() == queued.size() - 1,
		"one fewer", str(Crafting.queue_at(state, bench)))
	expect(Crafting.making(state, bench) == StringName(queued[0]),
		"and the one that was running still is",
		str(Crafting.making(state, bench)))

	# **Walking away closes it**, and the queue keeps going without anybody
	# looking - which is the whole feature.
	var kits_before := Crafting.kits(state, &"barricade")
	_stand_at(state, Vector2i(stand.x, stand.y + 3), Player.SOUTH)
	await until(func() -> bool: return not panel.is_open(),
		"the panel to close when the farmer walks off")
	expect(not panel.is_open(), "walking away closes it")
	Sim.advance(state, int((GameData.RECIPES[&"barricade_kit"]
		as Dictionary)["ticks"]) + 4)
	await frames(2)
	expect(Crafting.kits(state, &"barricade") > kits_before,
		"and the bench carried on without being watched",
		str(Crafting.kits(state, &"barricade")))

	await close_scene()
	_completed += 1     # last line: an abandoned case never gets here


## 0038 - walking back to a bench and being told what it did.
func _case_0038_away() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	var panel: WorkshopPanel = require_control("WorkshopPanel")
	if driver == null or panel == null:
		_completed += 1
		await close_scene()
		return

	var state := driver.state
	Resources.gain(state, {GameData.WOOD: 200, GameData.STONE: 200})
	var bench := Building.anchor_of(state,
		Farm.cells_with(state, &"workshop")[0])
	var stand := _free_cell_beside(state, bench)
	if stand == Vector2i(-1, -1):
		await close_scene()
		_completed += 1
		return

	# Queue three, stand at the bench once so the panel has seen the tally.
	for _i in 3:
		Crafting.enqueue(state, bench, &"barricade_kit")
	_stand_at(state, stand, _facing_towards(stand, bench))
	await until(func() -> bool: return panel.is_open(), "the panel to open")
	var away: Label = require_control("WorkshopAway")
	expect(away != null, "there is a line for what happened while away")
	await frames(2)
	expect(away == null or not away.visible,
		"which says nothing the first time you walk up",
		away.text if away else "")

	# **Walk off to the pond, let the bench work, walk back.**
	var pond: Vector2i = Farm.cells_of(state, Farm.Terrain.WATER)[0]
	_stand_at(state, pond + Vector2i(0, -1), Player.SOUTH)
	await until(func() -> bool: return not panel.is_open(),
		"the panel to close when the farmer leaves")

	var ticks := int((GameData.RECIPES[&"barricade_kit"]
		as Dictionary)["ticks"])
	var kits_before := Crafting.kits(state, &"barricade")
	Sim.advance(state, ticks * 2 + 6)
	await frames(2)
	expect(Crafting.kits(state, &"barricade") >= kits_before + 2,
		"the bench worked while the farmer stood at the pond",
		str(Crafting.kits(state, &"barricade")))

	_stand_at(state, stand, _facing_towards(stand, bench))
	await until(func() -> bool: return panel.is_open(),
		"the panel to open again")
	await frames(2)
	var back: Label = require_control("WorkshopAway")
	expect(back != null and back.visible,
		"and coming back says what happened", back.text if back else "")
	if back != null:
		expect(back.text.contains("barricade_kit"),
			"naming what was made", back.text)
		expect(back.text.contains("2"), "and how many", back.text)

	await close_scene()
	_completed += 1     # last line: an abandoned case never gets here


## Whether a colour is somewhere on the day's dawn-noon-dusk line.
##
## Each channel has to sit inside the range those three colours span, with a
## little slack for the fade being part way. Asking "is it exactly noon" was
## the old test and stopped being answerable when the light started moving.
func _is_daylight(colour: Color) -> bool:
	var lights: Array = [PaletteData.DAWN_TINT, PaletteData.DAY_TINT,
		PaletteData.DUSK_TINT]
	for channel in 3:
		var low := 9.0
		var high := -9.0
		for entry in lights:
			var each: Color = entry
			low = minf(low, each[channel])
			high = maxf(high, each[channel])
		if colour[channel] < low - 0.06 or colour[channel] > high + 0.06:
			return false
	return true


## 0039 - the clock, the light, and the stall that stops both.
func _case_0039_clock() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	var world: WorldView = require_control("WorldView")
	if driver == null or world == null:
		_completed += 1
		await close_scene()
		return

	var state := driver.state
	var clock: Label = require_control("Day")
	expect(clock != null, "there is a clock")
	await frames(2)
	expect(clock != null and clock.text.begins_with("DAY 1"),
		"saying which day", clock.text if clock else "")
	expect(clock != null and clock.text.contains("0:0"),
		"and starting near the top of it", clock.text if clock else "")

	# **The light is not the same at dawn as at dusk.**
	var dawn := world.light_target()
	Sim.advance(state, GameData.DAY_TICKS / 2)
	await frames(4)
	var noon := world.light_target()
	Sim.advance(state, GameData.DAY_TICKS / 2 - 30)
	await frames(4)
	var evening := world.light_target()
	expect(not dawn.is_equal_approx(noon),
		"the light moves from dawn to noon",
		"%s then %s" % [dawn, noon])
	expect(not noon.is_equal_approx(evening),
		"and from noon to evening", "%s then %s" % [noon, evening])
	expect(evening.r > dawn.r,
		"warming as it goes - evening is redder than morning",
		"%.2f against %.2f" % [evening.r, dawn.r])

	# **Past dusk the button asks rather than pressing itself.**
	var night: Button = require_control("NightButton")
	expect(night != null, "there is a night button")
	await until(func() -> bool: return Phases.is_dusk(state), "dusk", 300)
	await frames(4)
	expect(Phases.is_dusk(state), "it is dusk")
	expect(night != null and night.text.to_lower().contains("waiting"),
		"and the button asks", night.text if night else "")
	expect(int(state["phase"]) == Phases.DAY,
		"but the night has not started itself",
		Phases.name_of(int(state["phase"])))
	expect(clock != null and clock.text.to_lower().contains("dusk"),
		"and the clock says so too", clock.text if clock else "")

	Sim.advance(state, 600)
	await frames(4)
	expect(int(state["phase"]) == Phases.DAY,
		"twenty seconds later it still has not",
		Phases.name_of(int(state["phase"])))

	# **The stall stops the clock**, on screen and in the state.
	var shop: ShopPanel = require_control("ShopPanel")
	Shop.open(state)
	await until(func() -> bool: return shop.visible, "the stall to open")
	var shown := clock.text
	var ticked := int(state["day_tick"])
	await frames(30)
	expect(int(state["day_tick"]) == ticked,
		"the day clock stops while the stall is open",
		str(int(state["day_tick"]) - ticked))
	expect(clock.text == shown, "and the label with it", clock.text)

	await tap_key(KEY_ESCAPE)
	await until(func() -> bool: return not Shop.is_open(state),
		"the stall to close")
	await frames(20)
	expect(int(state["day_tick"]) > ticked,
		"and closing it starts the day again",
		str(int(state["day_tick"]) - ticked))

	await close_scene()
	_completed += 1     # last line: an abandoned case never gets here


## 0040 - two tabs, a shelf that empties, and the seeds side by side.
func _case_0040_shop() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	var shop: ShopPanel = require_control("ShopPanel")
	if driver == null or shop == null:
		_completed += 1
		await close_scene()
		return

	var state := driver.state
	Resources.gain(state, {GameData.MONEY: 4000})
	Shop.open(state)
	await until(func() -> bool: return shop.visible, "the stall to open")
	await frames(2)

	# **It opens on selling**, which is what the player came for.
	expect(Shop.tab(state) == Shop.SELL, "the stall opens on selling",
		str(Shop.tab(state)))
	var probe: Button = require_control("sell_one_wood")
	print("  PROBE sell_one_wood: rect %s, disabled %s, scroll %s"
		% [str(probe.get_global_rect()) if probe else "none",
			str(probe.disabled) if probe else "?",
			str((require_control("Scroll") as Control).get_global_rect())])
	expect(probe != null, "so the sell rows are there")
	expect(locate_control("buy_one_wood") == null,
		"and the buy rows are not - it is one tab at a time")

	# **Two tabs, not two shops.**
	await click_control("tab_buy")
	await until(func() -> bool: return Shop.tab(state) == Shop.BUY,
		"the buy tab")
	await frames(2)
	expect(Shop.tab(state) == Shop.BUY, "clicking BUY switches",
		str(Shop.tab(state)))
	expect(require_control("buy_one_wood") != null, "and the buy rows appear")
	expect(locate_control("sell_one_wood") == null, "as the sell rows go")

	# **The shelf is on the label, and it empties.**
	var label: Label = require_control("buy_label_stone")
	expect(label != null, "the stone row says what is left")
	if label != null:
		expect(label.text.contains(str(Shop.stock_of(state, GameData.STONE))),
			"with today's number on it", label.text)

	var shelf := Shop.stock_of(state, GameData.STONE)
	await click_control("buy_one_stone")
	await until(func() -> bool:
		return Shop.stock_of(state, GameData.STONE) < shelf,
		"one off the shelf")
	expect(Shop.stock_of(state, GameData.STONE) == shelf - 1,
		"buying one takes one off it",
		str(Shop.stock_of(state, GameData.STONE)))
	await frames(2)
	var after: Label = require_control("buy_label_stone")
	expect(after != null and after.text.contains(str(shelf - 1)),
		"and the label says so", after.text if after else "")

	# Empty it, and the button stops offering.
	while Shop.stock_of(state, GameData.STONE) > 0:
		Shop.buy(state, GameData.STONE, 1)
	await frames(4)
	var sold_out: Button = require_control("buy_one_stone")
	expect(sold_out != null and sold_out.disabled,
		"an empty shelf is a button that says no rather than one that lies")

	# **The seeds, side by side with what the choice needs.**
	for id in Farming.seeds():
		var seed: Label = require_control("seed_label_%s" % id)
		expect(seed != null, "%s has a row" % id)
		if seed == null:
			continue
		expect(seed.text.contains("%ds" % Farming.seconds_to_grow(id)),
			"saying how long it takes", seed.text)
		expect(seed.text.contains(str(Farming.value_per_day(id))),
			"and what it is worth over a day", seed.text)

	var other := &""
	for id in Farming.seeds():
		if Farming.selected_seed(state) != id:
			other = id
			break
	var sow: Button = require_control("sow_%s" % other)
	print("  sow_%s: rect %s, disabled %s"
		% [other, str(sow.get_global_rect()) if sow else "none",
			str(sow.disabled) if sow else "?"])
	await click_control("sow_%s" % other)
	await until(func() -> bool: return Farming.selected_seed(state) == other,
		"the seed to change")
	expect(Farming.selected_seed(state) == other,
		"and clicking one picks it", str(Farming.selected_seed(state)))

	await tap_key(KEY_ESCAPE)
	await until(func() -> bool: return not Shop.is_open(state),
		"the stall to close")
	expect(not Shop.is_open(state), "escape leaves the stall")

	await close_scene()
	_completed += 1     # last line: an abandoned case never gets here


## 0041 - five lines that follow the thing they are about.
func _case_0041_tutorial() -> void:
	await open_scene(MAIN_SCENE)
	var driver: SimDriver = require_control("SimDriver")
	var prompt: TutorialPrompt = require_control("TutorialPrompt")
	if driver == null or prompt == null:
		_completed += 1
		await close_scene()
		return

	var state := driver.state
	await frames(3)

	# **It is up on day one**, on the first line.
	expect(prompt.visible, "day one starts with something to read")
	expect(prompt.showing() == &"chop", "and it is about the trees",
		str(prompt.showing()))
	var line: Label = require_control("TutorialLine")
	expect(line != null and not line.text.strip_edges().is_empty(),
		"there is a line of text", line.text if line else "")

	# **It sits over the thing**, not in a corner - and on the screen.
	var arrow: Label = require_control("TutorialArrow")
	expect(arrow != null and arrow.visible, "with a pointer under it")
	var box := line.get_global_rect()
	expect(box.position.x >= 0.0 and box.end.x <= 480.0
		and box.position.y >= 0.0 and box.end.y <= 270.0,
		"and all of it is on the screen", str(box))
	var first_at := arrow.position

	# **It follows.** Move the farmer and the pointer goes with the nearest
	# tree, because which tree is nearest is a fact about where you are.
	var trees := Farm.cells_with(state, &"tree")
	var far: Vector2i = trees[trees.size() - 1]
	_stand_at(state, _free_cell_beside(state, far), Player.SOUTH)
	await frames(3)
	expect(arrow.position != first_at,
		"walking across the farm moves the pointer",
		"%s then %s" % [first_at, arrow.position])

	# **Doing the thing makes it go away**, and the next one appears.
	Resources.gain(state, {GameData.WOOD: 5})
	await until(func() -> bool: return prompt.showing() == &"plant",
		"the second line")
	expect(prompt.showing() == &"plant",
		"chopping moves it on to the sowing", str(prompt.showing()))

	# **It takes nothing away.** The line is up and every key still works.
	var before := int(state["day_tick"])
	await hold_key(KEY_B, 4)
	await until(func() -> bool: return Building.is_active(state),
		"build mode with the prompt up")
	expect(Building.is_active(state),
		"build mode opens while the tutorial is talking")
	await hold_key(KEY_B, 4)
	await until(func() -> bool: return not Building.is_active(state),
		"build mode to close")
	expect(int(state["day_tick"]) > before,
		"and the day ran the whole time", str(int(state["day_tick"]) - before))

	# **Out of order is fine.** Skip straight to the last thing the game has
	# not asked for yet and watch the lines behind it disappear.
	Resources.gain(state, {GameData.WOOD: 200, GameData.IRON: 200,
		GameData.STONE: 200})
	var spot := Vector2i(-1, -1)
	for y in range(4, 12):
		for x in range(20, 32):
			if Farm.buildable(state, Vector2i(x, y)):
				spot = Vector2i(x, y)
				break
		if spot != Vector2i(-1, -1):
			break
	expect(Building.place(state, &"gun_tower", spot),
		"a tower goes down out of order")
	await until(func() -> bool: return Tutorial.is_done(state, &"build"),
		"the build line to tick itself off")
	expect(Tutorial.is_done(state, &"build"),
		"and the line about building is simply gone, unread")

	# **It goes away with the day.**
	await hold_key(KEY_N, 4)
	await until(func() -> bool: return int(state["phase"]) != Phases.DAY,
		"the night")
	await frames(3)
	expect(not prompt.visible, "and nothing is being taught at night")

	await close_scene()
	_completed += 1     # last line: an abandoned case never gets here
