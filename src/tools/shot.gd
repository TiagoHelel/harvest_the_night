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
	["react", "a crop came ready nearby", ""],
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

## Which language the pictures are in, on its own.
##
## **Separate from `_tongue`, which is a filename.** `--pt_BR --contrast`
## makes that `-pt_BR-contrast`, and the one place that used to ask it for a
## locale took everything after the dash and asked `I18n` for a language
## called `pt_BR-contrast`. `I18n.use` falls back to English without
## complaining, which is how `--title --pt_BR` wrote English pictures under
## Portuguese names - found at task 0103 by taking one and looking at it.
var _speaking := ""


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
	var front := false
	var strip := false
	var reel := false
	var id := "latest"
	var wanted: Array = []
	for arg in args:
		if arg.begins_with("--"):
			var maybe := arg.substr(2)
			if I18n.LOCALES.has(maybe):
				speaking = maybe
			elif maybe == "contrast":
				loud = true
			elif maybe == "title":
				front = true
			elif maybe == "trailer":
				# **Thirty seconds, task 0108.** Four beats out of one
				# seeded run; `tools/devlog.py` turns them into a clip.
				reel = true
			elif maybe == "switch":
				# **The moment the game is named after, as frames.**
				# Task 0107 turns them into a GIF; nothing else in this
				# tool writes more than one picture of one thing.
				strip = true
			elif maybe == "playtest":
				# **Task 0105's build, photographed.** The badge and the
				# watermark only exist when the flag is on, so this is the
				# only way to look at either.
				Playtest.force(true)
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
		_speaking = speaking
	# **Contrast is a flag too.** The same pictures with the quiet
	# colours turned up, which is the only way to see what the
	# switch actually costs.
	if loud:
		UiKit.set_high_contrast(true)
		_tongue += "-contrast"

	# **The front of the game, which is not a farm.** `--title` takes
	# two pictures of `Title.tscn` instead of the scenario set:
	# the ident that plays before it, and the title behind that.
	if reel:
		await _take_the_trailer(folder)
		print("%d written, %d failed, into %s"
			% [_written, _failed, folder])
		quit(1 if _failed > 0 else 0)
		return

	if strip:
		await _take_the_switch(folder)
		print("%d written, %d failed, into %s"
			% [_written, _failed, folder])
		quit(1 if _failed > 0 else 0)
		return

	if front:
		await _take_the_front(folder)
		print("%d written, %d failed, into %s"
			% [_written, _failed, folder])
		quit(1 if _failed > 0 else 0)
		return

	# The title is photographed without its ident in front of it.
	BootIdent.played()

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


## The trailer: how long it is, and how many pictures a second of it has.
##
## **Thirty seconds at ten a second.** Ten is enough for a farm and a horde to
## read as moving and few enough that three hundred frames is a file somebody
## can put on a page. The game runs at 30Hz, so three ticks a picture makes
## the clip play at the speed the game is actually played at - which is the
## only honest speed for a trailer.
const TRAILER_SECONDS := 30
const TRAILER_FPS := 10
const TRAILER_TICKS_PER_FRAME := 3

## And the four beats, in pictures. They add up to `TRAILER_SECONDS * FPS`.
##
## `design.md` asks the trailer to answer one question - what kind of game is
## this - and the answer is the four things in this list, in this order. A day
## that went on for fifteen seconds would be a farming game with a surprise at
## the end; five seconds of farm and twenty-five of shooting would be a tower
## defence that lied about the other half.
const BEAT_DAY := 80        # the farm being worked
const BEAT_SWITCH := 50     # the light going over
const BEAT_NIGHT := 120     # the horde arriving and the towers answering
const BEAT_FALL := 50       # something coming down

## How many walk in for the night beat.
##
## **More than the table sends**, for the reason task 0082 wrote down about
## the wave picture: eight towers clear a normal wave in four seconds and the
## shutter gets an empty field. A trailer needs the fence to be under enough
## pressure to come down, and the fourth beat is that happening.
const HORDE := 60


## Thirty seconds of the game, from one seed.
##
## ## Four beats and one cut
##
## Day, switch, night, and something falling. There is **one cut**, and it is
## the twenty seconds of preparation between sending for the night and the
## night arriving: `GameData.PREPARATION_TICKS` is two thirds of the whole
## clip, and a trailer that spent it watching a farmer stand still would be a
## trailer nobody finished. The cut is between the light going over and the
## first wave, which is where a viewer expects one anyway.
##
## ## It says whether the beats actually happened
##
## A wall falling is not something a capture can promise - it depends on
## where the horde walks and what it chews through. So the tool **checks**,
## and prints what it found rather than writing three hundred frames and
## leaving somebody to notice that the fourth beat is thirty towers shooting
## at nothing.
func _take_the_trailer(folder: String) -> void:
	seed(SPARK_SEED)
	var main: Node = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame

	main.begin_run(SEED)
	var driver = main.get_node("%SimDriver")
	var state: Dictionary = driver.state
	_a_defended_farm(state)
	Sim.advance(state, maxi(GameData.DUSK_AT_TICK - 30 * GameData.SECONDS
		- int(state["tick"]), 1))

	_standing_at = Player.cell(state)
	for _i in SETTLE:
		await process_frame

	var shot := 0

	# ------------------------------------------------- a day of farming
	for i in BEAT_DAY:
		_work_the_farm(state, i)
		shot = await _reel_frame(state, shot, folder)

	# ------------------------------------------------- send for the night
	(state["intent"] as Dictionary)["begin_night"] = true
	for _i in BEAT_SWITCH:
		shot = await _reel_frame(state, shot, folder)

	# **The cut.** The rest of the preparation, off camera.
	while int(state["phase"]) == Phases.PREPARATION:
		Sim.advance(state, 30)

	# ------------------------------------------------- a night holding
	#
	# **A horde spawned by hand, and the camera on the fence.** The first
	# version watched the farmer, who had spent the day beat walking west
	# into the field - so the night was thirty seconds of an empty meadow
	# with a fight happening off the right of the screen, and the wave the
	# table sends was dead four seconds in. `_set_wave` learned the same
	# thing at task 0082 and its comment says so.
	for i in HORDE:
		Enemies.spawn(state, &"walker" if i % 3 else &"runner",
			i % GameData.SPAWNS.size())
	var standing_before := Farm.cells_with(state, &"fence").size()
	for _i in BEAT_NIGHT:
		shot = await _reel_frame(state, shot, folder, _the_defence_line(state))

	# ------------------------------------------------- and something falls
	for _i in BEAT_FALL:
		shot = await _reel_frame(state, shot, folder, _the_defence_line(state))

	# What actually happened, said out loud.
	var lost := standing_before - Farm.cells_with(state, &"fence").size()
	var walkers := Entities.count(state)
	print("  the day     %d frames of a farm being worked" % BEAT_DAY)
	print("  the switch  %d frames of the light going over" % BEAT_SWITCH)
	print("  the night   %d frames, %d still walking at the end"
		% [BEAT_NIGHT + BEAT_FALL, walkers])
	if lost > 0:
		print("  the fall    %d of the fence came down" % lost)
	else:
		print("  the fall    NOTHING CAME DOWN - the fourth beat is missing")
		_failed += 1
	print("  %d seconds at %d a second" % [TRAILER_SECONDS, TRAILER_FPS])

	root.remove_child(main)
	main.free()


## One picture, and the ticks that go under it.
##
## `look_at` is where the camera goes; `(-1, -1)` follows the farmer, which is
## what the day beat wants and what the night beat very much does not.
func _reel_frame(state: Dictionary, shot: int, folder: String,
		look_at: Vector2i = Vector2i(-1, -1)) -> int:
	for _f in TRAILER_TICKS_PER_FRAME:
		Sim.advance(state, 1)
		await process_frame
	_standing_at = look_at if look_at.x >= 0 else Player.cell(state)
	await _shoot("trailer-%03d" % shot, folder)
	return shot + 1


## What the farmer is doing during the first beat.
##
## **Walking west into the field and working whatever is under them.**
## `interact_held` is a level rather than an edge - task 0056's note - so
## holding it down is a farmer who tills, sows and waters their way along a
## row, which is what a day looks like from outside.
func _work_the_farm(state: Dictionary, frame: int) -> void:
	var intent: Dictionary = state["intent"]
	var move: Array = intent["move"]
	move[0] = -1 if frame < BEAT_DAY / 2 else 0
	move[1] = 0
	intent["interact_held"] = frame >= BEAT_DAY / 2
	intent["interact"] = frame == BEAT_DAY / 2


## How many pictures the switch is captured as. What ends up in the GIF.
const SWITCH_FRAMES := 24

## The frame rate `tools/shot.py` passes as `--fixed-fps`.
##
## **Two numbers in two files that have to agree**, so `headless_check`
## asserts they do. The transition runs on `delta`, so how many engine frames
## it lasts is this times `GameData.TRANSITION_SECONDS` - which is how the
## step below is worked out rather than guessed. The first version guessed
## one engine frame per picture and caught the first quarter of the fade:
## twenty-four brightening frames of a farm that never got dark.
const FIXED_FPS := 60

## And how many of them are the farm before anything happens, so the GIF has
## somewhere to start rather than opening mid-fade.
const SWITCH_LEAD := 4


## The reality switch, frame by frame.
##
## **The one thing in this tool that photographs a change rather than a
## state.** Everything else builds a scripted moment and takes one picture;
## this builds the moment before, asks for the night the way a player does,
## and then takes a picture every frame while the light goes over.
##
## The simulation is advanced by hand a fixed amount per frame, so the strip
## is the same strip every time. `WorldView` runs its fade on `delta`, which
## `--fixed-fps` makes a fixed number - which is the whole reason this tool
## passes that flag.
func _take_the_switch(folder: String) -> void:
	seed(SPARK_SEED)
	var main: Node = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame

	main.begin_run(SEED)
	var driver = main.get_node("%SimDriver")
	var state: Dictionary = driver.state
	_a_defended_farm(state)
	_standing_at = Player.cell(state)

	# Dusk, with the night not yet asked for.
	Sim.advance(state, maxi(GameData.DUSK_AT_TICK - int(state["tick"]), 1))
	for _i in SETTLE:
		await process_frame
	for i in SWITCH_LEAD:
		await _shoot("switch-%02d" % i, folder)
		await process_frame

	# **Asked for the way a player asks**, by writing the intent, so the
	# phase machine and the light and the theatre all start together.
	(state["intent"] as Dictionary)["begin_night"] = true

	# **The whole fade, spread over the pictures there are.** A tenth past
	# the end, so the strip settles on the night rather than stopping while
	# the light is still moving.
	var over := int(round(GameData.TRANSITION_SECONDS * float(FIXED_FPS)))
	var step := maxi(int(ceil(float(over) * 1.1 / float(SWITCH_FRAMES))), 1)
	for i in SWITCH_FRAMES:
		for _f in step:
			# One tick a frame is twice speed, which is a farm that is doing
			# something while the light goes over rather than a still.
			Sim.advance(state, 1)
			await process_frame
		await _shoot("switch-%02d" % (SWITCH_LEAD + i), folder)

	root.remove_child(main)
	main.free()


## The two pictures of the front of the game.
##
## The ident is caught **half way through its hold**, because the interesting
## frame is the one with the mark at full brightness rather than the first or
## the last - and it is driven by hand, a fixed number of fixed steps, so two
## runs catch the same frame.
func _take_the_front(folder: String) -> void:
	BootIdent.forget()
	var title: Node = load("res://scenes/Title.tscn").instantiate()
	root.add_child(title)
	await process_frame
	await process_frame
	_say_it_in(title)

	var ident := _find(title, "BootIdent") as BootIdent
	if ident != null:
		var step := BootIdent.SECONDS / float(SETTLE)
		var held := int(SETTLE * (BootIdent.IN + BootIdent.HOLD * 0.5))
		for i in held:
			ident._process(step)
		await process_frame
		await _shoot("ident", folder)
		while ident.running():
			ident._process(step)
	await process_frame
	await process_frame
	await _shoot("title", folder)
	root.remove_child(title)
	title.free()
	await _take_the_crash(folder)
	await _take_the_save_trouble(folder)


## And the crash dialogue, which lives on the title screen.
##
## **A screen a player sees once, if ever**, which is exactly why it gets
## photographed: nobody is going to notice it is wrong by playing. The report
## is written before the scene is built, because the title reads the folder
## in `_ready` and never again - and it is taken away afterwards, because a
## picture is not a reason to leave a crash report on somebody's disk.
func _take_the_crash(folder: String) -> void:
	BootIdent.played()
	var state := State.create(SEED)
	Sim.advance(state, 5400)
	var made := Crash.report(state,
		"a picture of the dialogue, from tools/shot.py - nothing crashed")
	var title: Node = load("res://scenes/Title.tscn").instantiate()
	root.add_child(title)
	await process_frame
	_say_it_in(title)
	for _i in SETTLE:
		await process_frame
	await _shoot("crash", folder)
	root.remove_child(title)
	title.free()
	Crash.erase(made)


## Put the chosen language on a scene that is already built.
##
## The `Locale` autoload sets the language from `Settings` in its own
## `_ready`, so this has to happen after the scene exists rather than before
## it - the same reason `_take()` does it where it does.
func _say_it_in(scene: Node) -> void:
	if _speaking == "":
		return
	I18n.use(_speaking)
	I18n.relabel(scene)


## And the title with a saved run on the disk that this build cannot read.
##
## **The player's own save is put back afterwards.** This has to write
## `user://run.sav` to make the picture, and the machine taking the picture
## is somebody's machine with somebody's farm on it.
func _take_the_save_trouble(folder: String) -> void:
	BootIdent.played()
	var theirs := PackedByteArray()
	if FileAccess.file_exists(Save.RUN_PATH):
		theirs = FileAccess.get_file_as_bytes(Save.RUN_PATH)

	var state := State.create(SEED)
	Sim.advance(state, 1800)
	state["version"] = State.VERSION + 1
	Save.write_run(state)

	var title: Node = load("res://scenes/Title.tscn").instantiate()
	root.add_child(title)
	await process_frame
	_say_it_in(title)
	var router := _router()
	if router != null:
		router.goto(router.MENU)
	for _i in SETTLE:
		await process_frame
	await _shoot("save_trouble", folder)
	root.remove_child(title)
	title.free()

	if theirs.is_empty():
		Save.delete_run()
	else:
		var f := FileAccess.open(Save.RUN_PATH, FileAccess.WRITE)
		if f != null:
			f.store_buffer(theirs)
			f.close()


## The router, asked of the engine rather than of this script.
func _router() -> Node:
	return root.get_node_or_null(^"App")


func _find(node: Node, named: String) -> Node:
	if node.name == named:
		return node
	for child in node.get_children():
		var found := _find(child, named)
		if found != null:
			return found
	return null


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
	if _speaking != "":
		I18n.use(_speaking)
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
		"react": _set_react(state)

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
	_just_before_the_shutter(state, name)
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


## Open the shutter and write what is on the screen.
##
## Pulled out of `_take` at task 0099, because the title pictures need the
## same three steps - wait for a drawn frame, read the viewport, write the
## file - and a second copy of them would be a second place to get the
## headless caveat wrong.
func _shoot(name: String, folder: String) -> bool:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null:
		print("  %-8s no image came back - is this running headless?" % name)
		_failed += 1
		return false
	var path := folder + name + _tongue + ".png"
	if image.save_png(ProjectSettings.globalize_path(path)) != OK:
		print("  %-8s could not be written" % name)
		_failed += 1
		return false
	_written += 1
	return true


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


## The last thing before the picture is taken.
##
## **For anything that does not last as long as the settle.** The settle runs
## thirty frames of the game so that the view has something to have noticed -
## damage numbers, sparks - and task 0109's bubble is up for forty-five ticks,
## which is less than that. So the scenario that is about a bubble puts it up
## here, after the stirring and before the shutter.
##
## Found by taking the picture: the farmer stood there with nothing over their
## head, because the reaction had come and gone during the settle. Which is
## also the feature working - it is meant to be a beat and not a badge.
func _just_before_the_shutter(state: Dictionary, name: String) -> void:
	match name:
		"react": Reactions.show(state, &"note")


## The farmer noticing something, task 0109.
##
## **Put up by hand rather than waited for.** The moment is real - a crop
## coming ready within sight - but waiting for one would mean a picture that
## depends on which tick the shutter falls on, and the whole point of these
## is that two runs produce the same file.
func _set_react(state: Dictionary) -> void:
	_a_sown_field(state)
	Sim.advance(state, 4 * GameData.SECONDS)
	_standing_at = Player.cell(state)


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
