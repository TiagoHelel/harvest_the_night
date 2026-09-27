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

## The check takes well under a second; this is the backstop for a scene that
## never finishes loading or an `await` that never returns.
const WATCHDOG_SECONDS := 20.0

## How many `_case_NNNN_*` functions `_run()` is expected to finish.
## **Adding a case means bumping this.**
const CASES := 5

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
	expect(require_control("Clock") != null, "the clock label is there")
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


func _sprites_in(node: Node) -> int:
	var n := 0
	for child in node.get_children():
		if child is Sprite2D:
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
	await frames(20)
	expect(panel.visible, "pressing interact opens the panel")

	# Sell, by clicking the button a player would click.
	var wood_before := Resources.amount(state, GameData.WOOD)
	var money_before := Resources.amount(state, GameData.MONEY)
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
	await frames(20)
	expect(not panel.visible, "escape closes it")
	# **And it stays closed.** The trade action used to repeat, so the panel
	# reopened on the tick after it was shut.
	await frames(30)
	expect(not panel.visible, "and stays closed a second later")
	expect(not Shop.is_open(state), "and the game agrees it is closed")

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
	if ok:
		passed += 1
	else:
		_fail(what, detail)


func _fail(what: String, detail: String = "") -> void:
	failed += 1
	print("  FAIL  ", what, "  ", detail)
