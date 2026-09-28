extends SceneTree

## Puts the game in a known state and takes the picture.
##
## Run it through `python tools/shot.py`, which supplies the flags that make
## the pictures repeatable:
##
##     python tools/shot.py 0082              the whole set
##     python tools/shot.py 0082 wave tech    two of them
##     python tools/shot.py --list            what there is
##
## Each scenario writes `implementation/shots/<id>/<name>.png` at the game's
## own 480x270, so a change of look can be **looked at** rather than hoped
## for. The runner loop says to do that after any task that draws.
##
## ## Why this is not headless
##
## The task asked for headless and Godot cannot do it. `--headless` selects
## the dummy rendering backend: `get_texture().get_image()` comes back null
## out of `dummy/storage/texture_storage.h`, and `frame_post_draw` never
## fires at all, so a script that waits for it hangs for ever rather than
## failing. Both were measured before this was written.
##
## What it does instead is `tools/shot.py`, which opens a real window far off
## the left of the screen and closes it when the last picture is written.
## There is nothing to click and nothing to look at while it runs, which is
## the part of "headless" that the task actually wanted.
##
## ## Why the same picture twice
##
## A scenario is a seed and a script: `Main.begin_run` on `SEED`, a fixed
## sequence of calls into `src/core/`, and `Sim.advance` for a fixed number of
## ticks. None of that touches a clock, so the simulation half is exactly
## reproducible by the same argument the whole game rests on.
##
## The **view** half is not so lucky, and needs two things doing to it:
##
## - `tools/shot.py` passes `--fixed-fps`, so every `_process(delta)` gets the
##   same delta whatever the machine is doing. Without it a flickering lamp, a
##   pulsing warning and a walking farmer all land somewhere slightly
##   different.
## - `seed()` is called before each scenario, because `particles.gd` draws
##   from the global RNG rather than from the run's - deliberately, since a
##   spark is not a rule and must not touch the run's stream.

## The one seed every picture is built from. Written down rather than taken
## from the clock, which is the habit the whole codebase is built on.
const SEED := 82082082

## The global RNG's seed, for the sparks. A different number from `SEED` so
## that nothing can quietly come to depend on the two being the same.
const SPARK_SEED := 4820

## Ticks to run on each of those frames, so the world is alive while the view
## is watching it. Two, which over thirty frames is two seconds of game.
const STIR_TICKS := 2

## Frames to let the view settle after the state is scripted, before the
## shutter. Enough for a panel to lay itself out and for particles to have
## something in the air.
const SETTLE := 30

## Where they go.
const OUT := "res://implementation/shots/"

## The set, in the order the task names them. Each is a scenario name, the
## line that describes it, and the screen to bring up over the world.
const SCENARIOS: Array = [
	["noon", "the farm at noon", ""],
	["dusk", "the same farm at dusk", ""],
	["wave", "a wave mid-fight", ""],
	["result", "the night's result", "ResultScreen"],
	["tech", "the tech tree", "TechPanel"],
	["pause", "the pause menu", "PauseMenu"],
	["options_access", "the access tab", "OptionsScreen:access"],
	["options_video", "the video tab", "OptionsScreen:video"],
	["options_audio", "the audio tab", "OptionsScreen:audio"],
	["options_controls", "the controls tab", "OptionsScreen:controls"],
]

var _written := 0
var _failed := 0

## Where the farmer is walked to before the shutter.
##
## **The camera is not something a scenario can set.** `Main._process` calls
## `look_at_cell(Player.cell(state))` every frame, because the camera follows
## the farmer - so a scenario that moved the camera had it moved back before
## the first settle frame, and the field stayed just off the left edge
## through three attempts at this. Walking the farmer is not a workaround for
## that, it is the same thing a player does when they want to look at
## something.
var _standing_at := Vector2i.ZERO

## Put on the end of a picture's name when it is not in English.
var _tongue := ""


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.has("--list"):
		for entry in SCENARIOS:
			print("  %-8s %s" % [entry[0], entry[1]])
		quit()
		return

	# **A language is a flag, not a scenario.** `--pt_BR` takes the same
	# pictures in the other language, which is the only way to see that a
	# translation fits the control it is in - task 0097 added a check that
	# measures it, and this is how it is looked at.
	var speaking := ""
	var loud := false
	var id := "latest"
	var wanted: Array = []
	for arg in args:
		if arg.begins_with("--"):
			var maybe := arg.substr(2)
			if I18n.LOCALES.has(maybe):
				speaking = maybe
			elif maybe == "contrast":
				loud = true
			continue
		if id == "latest" and not _is_scenario(arg):
			id = arg
		else:
			wanted.append(arg)
	if wanted.is_empty():
		for entry in SCENARIOS:
			wanted.append(str(entry[0]))

	var folder := OUT + id + "/"
	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(folder))

	# **Seeded before the scene exists, not just before each scenario.**
	# Godot randomises the global RNG at startup, and the two warm-up frames
	# below run `particles.gd` - which draws from that RNG deliberately,
	# since a spark is not a rule and must not touch the run's stream. The
	# smoke those frames put in the air survived into the first scenario and
	# made three of the five pictures differ between runs, by about seven
	# hundredths of one per cent of their pixels, all of it around the
	# chimneys. Found by diffing two runs rather than by reading the code.
	if speaking != "":
		_tongue = "-" + speaking
	# **Contrast is a flag too.** The same pictures with the quiet
	# colours turned up, which is the only way to see what the
	# switch actually costs.
	if loud:
		UiKit.set_high_contrast(true)
		_tongue += "-contrast"

	seed(SPARK_SEED)
	var main: Node = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame

	for name in wanted:
		var entry := _scenario(name)
		if entry.is_empty():
			print("  no scenario called '%s'" % name)
			_failed += 1
			continue
		await _take(main, entry, folder)

	print("%d written, %d failed, into %s" % [_written, _failed, folder])
	quit(1 if _failed > 0 else 0)


func _is_scenario(name: String) -> bool:
	return not _scenario(name).is_empty()


func _scenario(name: String) -> Array:
	for entry in SCENARIOS:
		if str(entry[0]) == name:
			return entry as Array
	return []


## Build one scenario, let it settle, and write the PNG.
func _take(main: Node, entry: Array, folder: String) -> void:
	var name := str(entry[0])

	# **A fresh run for every picture**, so a scenario cannot be affected by
	# the one before it. Same seed each time, so the farm is the same farm.
	seed(SPARK_SEED)
	main.begin_run(SEED)
	# **After the run is built, not before.** The `Locale` autoload sets the
	# language from `Settings` in its own `_ready`, which happens somewhere
	# in the middle of all this - so the language is put on again here, where
	# nothing can come along afterwards and put it back.
	if _tongue != "":
		I18n.use(_tongue.substr(1))
		I18n.relabel(main)
	var driver = main.get_node("%SimDriver")
	var state: Dictionary = driver.state
	_standing_at = Player.cell(state)

	match name:
		"noon": _set_noon(state)
		"dusk": _set_dusk(state)
		"wave": _set_wave(state)
		"result": _set_result(state)
		"tech": _set_tech(state)
		"pause": _set_pause(state)
		"options_access": _set_options_access(state)
		"options_video": _set_options_video(state)
		"options_audio": _set_options_audio(state)
		"options_controls": _set_options_controls(state)

	_walk_to(state, _standing_at)
	main.get_node("%WorldView").look_at_cell(Player.cell(state))
	_only_showing(main, str(entry[2]))

	for i in SETTLE:
		# **The game has to be running while the shutter is open.** The view
		# notices things by comparing this frame with the last one - damage
		# numbers, corpses, muzzle flashes, sparks - so a scenario that does
		# all its work in one `Sim.advance` and then holds still gives them
		# nothing to have noticed. Task 0088's wave came back with a battle
		# in it and not one damage number, because every blow had landed
		# before `Juice` had a first frame to compare against.
		#
		# A fixed number of ticks a frame, so two runs still tick identically.
		Sim.advance(state, STIR_TICKS)
		await process_frame
	await RenderingServer.frame_post_draw

	var image := root.get_texture().get_image()
	if image == null:
		print("  %-8s no image came back - is this running headless?" % name)
		_failed += 1
		return
	var path := folder + name + _tongue + ".png"
	var wrote := image.save_png(ProjectSettings.globalize_path(path))
	if wrote != OK:
		print("  %-8s could not be written" % name)
		_failed += 1
		return
	_written += 1
	print("  %-8s %-24s tick %5d  %-11s %s" % [name, str(entry[1]),
		int(state["tick"]), Phases.name_of(int(state["phase"])),
		_worth_saying(state)])


## The one line that says whether the scenario is actually showing what it
## claims to. **A picture of an empty battlefield is a passing run and a
## useless shot**: the first version of the wave scenario gave the towers nine
## seconds and they had killed all fourteen zombies before the shutter.
func _worth_saying(state: Dictionary) -> String:
	if int(state["phase"]) == Phases.NIGHT:
		return "%d still coming, house %d%%" % [Waves.remaining(state),
			int(Enemies.house_fraction(state) * 100.0)]
	if int(state["phase"]) == Phases.RESULT:
		return "%d lines of payout" % _result_lines(state)
	if int(state["phase"]) == Phases.DAY:
		return "%d crops up, %d tech" % [_crops_up(state),
			Tech.owned(state).size()]
	return ""


## **Plots are not occupants.** The first version of this asked
## `Farm.cells_with(state, &"plot")` and got nothing, and reported "0 crops
## up" over a picture of a field full of them - a measurement wrong in the
## direction that makes you distrust working code. Tilled soil lives in
## `state["plots"]`, and the grid is six hundred and forty cells.
func _crops_up(state: Dictionary) -> int:
	var out := 0
	for y in GameData.GRID_HEIGHT:
		for x in GameData.GRID_WIDTH:
			if Farming.crop_on(state, Vector2i(x, y)) != &"":
				out += 1
	return out


func _result_lines(state: Dictionary) -> int:
	var payout: Dictionary = state.get("payout", {})
	return payout.size()


## Bring one screen up and put the others away, so a picture has one subject.
func _only_showing(main: Node, wanted: String) -> void:
	# **A screen, optionally with a tab.** `"OptionsScreen:audio"` is the
	# options frame open on its audio tab - which is the only way to
	# photograph the second of three tabs that all live in one screen.
	var want_screen := wanted.get_slice(":", 0)
	var want_tab := wanted.get_slice(":", 1) if wanted.contains(":") else ""
	for named in ["ShopPanel", "TechPanel", "StatsScreen", "InventoryPanel",
			"WorkshopPanel", "ResultScreen", "OptionsScreen",
			"PauseMenu"]:
		var screen: Control = main.get_node_or_null("%" + named)
		if screen == null:
			continue
		screen.visible = named == want_screen
		if screen.visible and want_tab != "":
			screen.show_tab(StringName(want_tab))


# ---------------------------------------------------------------- the farms

## A worked field: tilled, sown and watered.
##
## **It finds the soil rather than guessing where it is.** The first version
## sowed a fixed block at (6,6) and the camera followed the farmer, who
## starts at (17,7) - so the picture was of a lawn with the field just off the
## left edge. The second version sowed around the farmer instead and got
## nothing at all, because tilling is only offered on the farm's own soil and
## the farmer starts on grass beside the house. `Interact.verb_at` knows
## where the soil is; asking it is shorter than either guess and cannot go
## stale when the map moves.
## The farm at noon with the options over it, for looking at a settings tab
## rather than at the farm. One per tab, because they are one screen and only
## one of them is on it at a time.
## The pause menu over a night, because that is when it matters: the
## whole point of it is that the world stops with a wave on the screen.
func _set_pause(state: Dictionary) -> void:
	_set_wave(state)


func _set_options_access(state: Dictionary) -> void:
	_set_noon(state)


func _set_options_video(state: Dictionary) -> void:
	_set_noon(state)


func _set_options_audio(state: Dictionary) -> void:
	_set_noon(state)


func _set_options_controls(state: Dictionary) -> void:
	_set_noon(state)


func _a_sown_field(state: Dictionary) -> void:
	Resources.gain(state, {GameData.MONEY: 240, GameData.WOOD: 180,
		GameData.STONE: 120, GameData.IRON: 90, GameData.OIL: 30})
	var seeds := Farming.seeds()
	var sown := 0
	var middle := Vector2i.ZERO
	for y in GameData.GRID_HEIGHT:
		for x in GameData.GRID_WIDTH:
			var cell := Vector2i(x, y)
			if Interact.verb_at(state, cell) != &"till":
				continue
			Farming.select_seed(state, StringName(seeds[sown % seeds.size()]))
			Interact.complete(state, cell, &"till")
			Interact.complete(state, cell, &"plant")
			Interact.complete(state, cell, &"water")
			middle += cell
			sown += 1
	if sown > 0:
		# **Stand at the near edge of the field.** The camera is thirty tiles
		# wide and centres on the farmer, so from here one frame holds the
		# crops, the farmer and the house. A farm shot with no farmer in it
		# is a picture of scenery.
		middle = Vector2i(middle.x / sown, middle.y / sown)
		_standing_at = Vector2i(middle.x + 3, middle.y)
	# The crops need time on them or the field is six rows of bare soil.
	Sim.advance(state, 40 * GameData.SECONDS)


func _set_noon(state: Dictionary) -> void:
	_a_sown_field(state)
	# Half way through the day, which is what "noon" means to the light ramp.
	Sim.advance(state, maxi(GameData.DAY_TICKS / 2 - int(state["tick"]), 1))


func _set_dusk(state: Dictionary) -> void:
	_a_sown_field(state)
	# Just past the hour the ramp starts going warm, so the picture is of the
	# change rather than of the day before it.
	Sim.advance(state, maxi(GameData.DUSK_AT_TICK + 2 * GameData.SECONDS
		- int(state["tick"]), 1))


# ---------------------------------------------------------------- the night

func _set_wave(state: Dictionary) -> void:
	_a_defended_farm(state)
	Phases.begin_preparation(state)
	Sim.advance(state, GameData.PREPARATION_TICKS + 1)
	# **Spawned by hand rather than waited for.** A wave arriving on its own
	# schedule would make the picture depend on how long the preparation ran,
	# which is the sort of thing that drifts a tick and moves every zombie.
	#
	# Thirty rather than fourteen, and four seconds rather than nine: eight
	# towers cleared the first version before the shutter and the picture was
	# of an empty field. The line it prints says how many are still coming,
	# so that cannot happen quietly again.
	for i in 30:
		Enemies.spawn(state, &"walker" if i % 3 else &"runner",
			i % GameData.SPAWNS.size())
	Sim.advance(state, 4 * GameData.SECONDS)
	_standing_at = _the_defence_line(state)


func _set_result(state: Dictionary) -> void:
	_a_defended_farm(state)
	Phases.begin_preparation(state)
	Sim.advance(state, GameData.PREPARATION_TICKS + 1)
	# **The night is played, not declared.** Calling `enter_result` straight
	# out gave a panel with a title and a button and nothing between them -
	# there was no night for it to itemise. `skip_night` is the game's own
	# fast-forward, and task 0078 proved it lands where watching lands.
	Sim.skip_night(state)
	Sim.advance(state, 2)


func _set_tech(state: Dictionary) -> void:
	_a_sown_field(state)
	# Enough points that the tree shows all three states at once: bought,
	# affordable and out of reach. One state of anything is a picture that
	# cannot say what the other two look like.
	Resources.gain(state, {GameData.TECH: 9})
	# **The ids have spaces in them.** `&"sharp_tools"` bought nothing and
	# said nothing, and the picture came back with "0 of 12 nodes" on it
	# while the panel showed nine points unspent.
	for id in [&"sharp tools", &"true sights"]:
		if not Tech.buy(state, id):
			push_warning("shot: could not buy %s" % id)
	Sim.advance(state, 2)


## A farm with something on it worth defending and something defending it.
func _a_defended_farm(state: Dictionary) -> void:
	_a_sown_field(state)
	Resources.gain(state, {GameData.WOOD: 900, GameData.IRON: 900,
		GameData.STONE: 900, GameData.OIL: 200, GameData.GUNPOWDER: 120,
		GameData.INCENDIARY: 60})
	var here := Player.cell(state)
	var put := 0
	for y in range(here.y - 2, here.y + 6):
		for x in range(here.x + 3, here.x + 13):
			if put >= 8:
				break
			var id: StringName = &"gun_tower" if put % 2 else &"auto_crossbow"
			if Building.place(state, id, Vector2i(x, y)):
				put += 1
		if put >= 8:
			break
	for y in range(here.y - 4, here.y + 9):
		Building.place(state, &"fence", Vector2i(here.x + 14, y))


## Walk the farmer there, through the real intent the keyboard writes.
##
## Ticked by hand rather than by frames, so it costs no wall clock and cannot
## depend on one. Bounded, because a farmer walked at a rock would otherwise
## push against it until the heat death of the universe - and a shot tool
## that hangs is worse than one that takes a slightly wrong picture.
func _walk_to(state: Dictionary, target: Vector2i) -> void:
	var intent: Dictionary = state["intent"]
	var move: Array = intent["move"]
	var stuck := 0
	for step in 20 * GameData.SECONDS:
		var here := Player.cell(state)
		if here == target:
			break
		move[0] = signi(target.x - here.x)
		move[1] = signi(target.y - here.y)
		Sim.advance(state, 1)
		if Player.cell(state) == here:
			stuck += 1
			if stuck > 2 * GameData.SECONDS:
				break       # something is in the way; near enough is near enough
		else:
			stuck = 0
	move[0] = 0
	move[1] = 0


## The middle of what is defending the farm, which is where the fighting is.
func _the_defence_line(state: Dictionary) -> Vector2i:
	var towers: Array = []
	for id in GameData.DEFENCES:
		towers += Farm.cells_with(state, StringName(id))
	if towers.is_empty():
		return Player.cell(state)
	var sum := Vector2i.ZERO
	for cell in towers:
		sum += cell as Vector2i
	return Vector2i(sum.x / towers.size(), sum.y / towers.size())
