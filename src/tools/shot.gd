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
	["days", "0196's two played days: Spring 9 at 07:00, noon and dusk; then Summer 9 at 07:00, 11:46 and dusk", ""],
	["tips", "Spring 3, the shipping bin's tip over the bin; then the first bite's over the fishing bar", ""],
	["kitchen", "a kitchen on the grass at noon in spring, the farmer at it with its panel up: seven dishes, a stew on the fire", "WorkshopPanel"],
	["house_tiers", "the house in tier I at noon, the farmer by its west wall; then tier II with its plaque over the door, the workshop's upgrades tab offering tier III, and tier III", ""],
	["peddler", "the stall open at noon with the peddler at its end; then shut at dusk, nobody there", ""],
	["shipping_bin", "the shipping bin by the porch at noon; then its panel with wood and carrots in; then the morning report naming what it pays", ""],
	["machines", "the keg, the preserves jar, the dairy, the loom and the mill in a row at noon, idle; then working; then the same at 01:30", ""],
	["machines_worn", "the same row at noon, the keg and the dairy past the wear line, the jar and the loom wrecked, the mill whole", ""],
	["keg_jar", "a keg aging wine, five mornings to go, its panel up; a preserves jar beside it setting jelly", "WorkshopPanel"],
	["barn_night", "a wrecked barn and a hurt one at night; then the next morning, the wreck's animals inside and the hurt one's out", ""],
	["barnyard", "the barn's cow, sheep and pig and the coop's hens about their homes, a pig's spot, the dog behind the farmer", ""],
	["barnyard_night", "the same barnyard at 01:30, before bed: the pigs' spots in the darkest light they meet", ""],
	["coop_barn", "a coop and a barn on their sites at noon, the map's animals moved in and more", ""],
	["fish_book", "the fish book on the Old Catfish's page, four of sixteen; then a silhouette", "InventoryPanel"],
	["bait", "a worm on the iron rod's hook, the line waiting, the bait choice under it", ""],
	["fishing_bar", "a trout on the line: one hit of two, the marker on its way", ""],
	["sprinklers", "a copper, an iron and a gold sprinkler at 06:20, spraying", ""],
	["hardwood", "a chipped big stump and a whole one among the trees", ""],
	["hardwood_night", "the same two big stumps on that night, the waves held off", ""],
	["quarry", "copper, coal and iron-gated gold on Autumn 1", ""],
	["can_area", "three dry plots in the iron can's next stroke", ""],
	["tool_upgrades", "upgrades ready tomorrow and an iron axe in hand", "WorkshopPanel"],
	["regrowing", "regrowing strawberries beside ripe fruit", ""],
	["withered", "summer crops wither on Autumn 1", ""],
	["withered_night", "the same withered field on Autumn 1's night, the waves held off, three plots trampled", ""],
	["winter_day", "outdoor fields rest in winter", ""],
	["spring_field", "spring crops and held seed packets", ""],
	["spring_field_night", "the same ripe spring field on its night, the waves held off", ""],
	["summer_field", "summer crops and held seed packets", ""],
	["summer_field_night", "the same ripe summer field on its night, the waves held off", ""],
	["summer_regrowing", "summer's field after a pick: peppers and corn regrowing beside the ripe ones", ""],
	["inventory_crops", "the crop category in the ledger", "InventoryPanel"],
	["inventory_full", "every item held, every inventory page", "InventoryPanel"],
	["inventory_night", "the same ledger opened on Spring 3's night: its materials, crops, seeds, fish, fish book, animal goods, artisan goods and tools pages", "InventoryPanel"],
	["twelve_crops", "twelve crops at all four stages", ""],
	["seed_page_one", "spring choices in the HUD", ""],
	["seed_page_two", "last spring choice in the HUD", ""],
	["shop_seeds_one", "spring seed picker at the stall", "ShopPanel"],
	["shop_seeds_two", "last spring seed choice at the stall", "ShopPanel"],
	["till_grass", "tilled grass beside starter beds at noon", ""],
	["till_grass_night", "the same expanded field at night", ""],
	["noon", "the farm at noon", ""],
	["dusk", "the same farm at dusk", ""],
	["bedtime", "the same farm at 22:30, time for bed", ""],
	["wave", "a wave mid-fight", ""],
	["full_moon", "the same wave on day 7, under a Full Moon", ""],
	["result", "the night's result", "ResultScreen"],
	["tech", "the tech tree", "TechPanel"],
	["tech_autumn", "the tech tree on Autumn 2, on its own floor: a node bought, one affordable, one waiting on another; then winter's floor, greyed", "TechPanel:autumn"],
	["pause", "the pause menu", "PauseMenu"],
	["options_access", "the access tab", "OptionsScreen:access"],
	["options_video", "the video tab", "OptionsScreen:video"],
	["options_audio", "the audio tab", "OptionsScreen:audio"],
	["options_controls", "the controls tab", "OptionsScreen:controls"],
	["react", "a crop came ready nearby", ""],
	["refused", "build mode, over something built", ""],
	["build_day", "build mode by day: the buildings", ""],
	["repair", "the cursor over a hurt tower at night", ""],
	["aim", "the flare armed: its reach round the cursor", ""],
	["house_interior", "the furnished farmhouse", ""],
	["farm_extension", "planting on the new southern land", ""],
	["larger_stations", "the larger farm buildings", ""],
	["passed_out", "passed out at 02:00: the night, and nobody on the farm", ""],
	["tutorial_bed", "day one, after the day's lines: the bed's, over the bed", ""],
	["tutorial_start", "day one's build step: START's line", ""],
	["tutorial_dawn", "day one's night: dawn's line", ""],
	["morning", "the morning report, every line it has", "ResultScreen"],
	["boss_escaped", "the morning after Spring 14's boss got away", "ResultScreen"],
	["year_end", "the year survived, after the credits", "ResultScreen"],
	["year_credits", "the credits before the year ending", "ResultScreen"],
	["calm_morning", "the morning after Summer 1's calm night", "ResultScreen"],
	["trampled", "the morning after a loss, by the trampled crops", ""],
	["tarps", "Spring 3 at noon, a defended farm's towers asleep under tarps and the one hurt last night under a torn one; then the same towers at dusk, still covered, the covers yanked off at the wake as he goes to bed, and the night", ""],
	["decoy", "a lured crowd at night: three decoys past a defended farm's fence - walkers, a runner and a tank biting the first, hurt, while the guns work; the second whole, out of their reach; the third bitten down to its straw - and the decoy picked on the hotbar's second page", ""],
	["zombie_bait", "a crowd turned toward a zombie bait at night: a rotten fish thrown past a defended farm's fence, the nearest already eating on it and the rest - from further than a decoy pulls - on their way; the bait picked on the hotbar, one kit left", ""],
	["bone_meal", "Spring 2 at noon: a starter row turned, plain and fertilised side by side, dry then watered, and carrot sprouts on fertilised earth dry and wet; bone meal chosen in the strip", ""],
	["night_loot", "the morning after Spring 7's Full Moon, fought from a defended farm: the report counting the bones and moon stones lying about; then him out by the moon stone nearest the house, the night's bones about it", "ResultScreen"],
	["north_band", "standing on the north spawn ground", ""],
	["new_ore", "beside the copper, the coal and the gold", ""],
	["stump", "in the woods, by a hardwood stump", ""],
	["winter_build", "the build step on Winter 2: a route from every side", ""],
	["forecast_dusk", "Spring 14 at 18:30: the boss night's forecast, every kind's head on it", ""],
	["forecast_build", "the build step on Winter 14: a boss under a Full Moon, from every side", ""],
	["forecast_calm", "Summer 1 at 18:30: the forecast of a calm night", ""],
	["season_summer", "the farm at noon on Summer 3", ""],
	["season_autumn", "the farm at noon on Autumn 3", ""],
	["season_winter", "the farm at noon on Winter 3, snowing", ""],
	["season_winter_night", "the same farm on Winter 3's night", ""],
	["winter_fishing", "Winter 3 at noon: a line in the north-west pond, its snowed shore and corners round open water", ""],
	["winter_quarry", "the quarry on Winter 3: snow caps on the rocks, the ores, the seams and the copper, coal and gold", ""],
	["winter_stumps", "the south-west woods on Winter 3: a stump's cap and the big stumps' 2x2 caps among bare trees", ""],
	["woken", "out of bed at 06:00, beside it", ""],
	# Last, so the pad's names do not follow the shutter into another picture.
	["options_controls_pad", "the controls tab, a pad in hand", "OptionsScreen:controls"],
]

var _written := 0
var _failed := 0

## Where the farmer is walked to before the shutter, by day.
##
## **By day the camera is not something a scenario can set.** `Main` follows
## the farmer every frame, so a scenario that moved the camera had it moved
## back before the first settle frame, and the field stayed just off the left
## edge through three attempts at this. Walking the farmer is not a
## workaround for that, it is the same thing a player does when they want to
## look at something.
var _standing_at := Vector2i.ZERO

## **And from the build step to the morning it is** (task 0130): the camera
## is the player's, so a night scenario puts it where the picture is with
## `Main.aim_night_camera`. Nowhere is the house, where the night opens.
## Both are set through `_look_at`.
var _camera_at := Vector2i(-1, -1)

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
	CaptureSize.configure(root, OS.get_cmdline_user_args().has("--fhd"))
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

	# The expanded-field scenario is always reviewed in both lights.
	if wanted.has("till_grass") and not wanted.has("till_grass_night"):
		wanted.append("till_grass_night")

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

	seed(SPARK_SEED)
	var main: Node = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	# **The profile's tips, put back at the end** (task 0195): every picture
	# plays the real main scene, which writes the tips it shows into this
	# machine's profile.
	var tips_before := (Save.read_profile().get("tips_seen", []) as Array).duplicate()

	for name in wanted:
		var entry := _scenario(name)
		if entry.is_empty():
			print("  no scenario called '%s'" % name)
			_failed += 1
			continue
		await _take(main, entry, folder)

	var profile := Save.read_profile()
	profile["tips_seen"] = tips_before
	Save.write_profile(profile)
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
## the build step between sending for the night and the night arriving: since
## task 0136 it waits for START, so the cut is START pressed off camera. The
## cut is between the light going over and the first wave, which is where a
## viewer expects one anyway.
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
	main.edge_pan = false
	# Nor does the guardian's cursor follow it (task 0139): the window can
	# land under the desk's own mouse, and then every night still had the
	# cursor wherever that mouse happened to be.
	main.get_node("%WorldView").cursor().follows_pointer = false
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
	(state["intent"] as Dictionary)["sleep"] = true
	for _i in BEAT_SWITCH:
		shot = await _reel_frame(state, shot, folder)

	# **The cut.** START, off camera (task 0136: the build step has no clock,
	# so a loop waiting it out would wait for ever).
	NightRoad.through_build(state)

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
	main.edge_pan = false
	# Nor does the guardian's cursor follow it (task 0139): the window can
	# land under the desk's own mouse, and then every night still had the
	# cursor wherever that mouse happened to be.
	main.get_node("%WorldView").cursor().follows_pointer = false
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
	(state["intent"] as Dictionary)["sleep"] = true

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
## The studio ident is caught **with its plate complete** - the crest lit, the
## name and PRESENTS settled - because that is the frame that says whose it
## is; its clock is set rather than waited for and then stopped, so two runs
## catch the same frame. It is its own scene ahead of the title, and taking it
## away puts this game's 480x270 frame back on the window.
func _take_the_front(folder: String) -> void:
	var ident := load("res://scenes/StudioIntro.tscn").instantiate() as StudioIntro
	root.add_child(ident)
	await process_frame
	ident.set_process(false)
	ident.set_clock(StudioIntro.T_HOLD - 0.4)
	await process_frame
	await process_frame
	await _shoot("ident", folder)
	root.remove_child(ident)
	ident.free()

	var title: Node = load("res://scenes/Title.tscn").instantiate()
	root.add_child(title)
	await process_frame
	await process_frame
	_say_it_in(title)
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
	# **No tip in a picture that is not about one** (task 0195): every tip
	# counts as shown until the `tips` scenario lets one through.
	_tips_shown_but(main, [])
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
	_camera_at = Vector2i(-1, -1)
	# The real pointer is wherever the desk left it: no edge panning.
	main.edge_pan = false
	# Nor does the guardian's cursor follow it (task 0139): the window can
	# land under the desk's own mouse, and then every night still had the
	# cursor wherever that mouse happened to be.
	main.get_node("%WorldView").cursor().follows_pointer = false

	match name:
		"quarry": _set_quarry(state)
		"can_area": _set_can_area(state)
		"tool_upgrades": _set_tool_upgrades(state)
		"inventory_crops": _set_inventory_crops(state)
		"inventory_full": _set_inventory_full(state)
		"inventory_night": _set_inventory_night(state)
		"twelve_crops": _set_twelve_crops(state)
		"spring_field": _set_spring_field(state)
		"spring_field_night": _set_spring_field_night(state)
		"summer_field": _set_summer_field(state)
		"summer_field_night": _set_summer_field_night(state)
		"summer_regrowing": _set_summer_regrowing(state)
		"withered": _set_withered(state)
		"withered_night": _set_withered_night(state)
		"regrowing": _set_regrowing(state)
		"winter_day": _set_winter_day(state)
		"seed_page_one": _set_seed_page_one(state)
		"seed_page_two": _set_seed_page_two(state)
		"shop_seeds_one": _set_shop_seeds_one(state)
		"shop_seeds_two": _set_shop_seeds_two(state)
		"till_grass": _set_till_grass(state)
		"till_grass_night": _set_till_grass_night(state)
		"noon": _set_noon(state)
		"dusk": _set_dusk(state)
		"bedtime": _set_bedtime(state)
		"wave": _set_wave(state)
		"full_moon": _set_full_moon(state)
		"result": _set_result(state)
		"tech": _set_tech(state)
		"tech_autumn": _set_tech_autumn(state)
		"pause": _set_pause(state)
		"options_access": _set_options_access(state)
		"options_video": _set_options_video(state)
		"options_audio": _set_options_audio(state)
		"options_controls": _set_options_controls(state)
		"react": _set_react(state)
		"refused": _set_refused(state)
		"build_day": _set_build_day(state)
		"house_interior": _set_house_interior(state)
		"farm_extension": _set_farm_extension(state)
		"larger_stations": _set_larger_stations(state)
		"passed_out": _set_passed_out(state)
		"tutorial_bed": _set_tutorial_bed(state)
		"tutorial_start": _set_tutorial_start(state)
		"tutorial_dawn": _set_tutorial_dawn(state)
		"morning": _set_morning(state)
		"boss_escaped": _set_boss_escaped(state)
		"calm_morning": _set_calm_morning(state)
		"year_end": _set_year_end(state)
		"year_credits": _set_year_credits(state)
		"trampled": _set_trampled(state)
		"night_loot": _set_night_loot(state)
		"bone_meal": _set_bone_meal(state)
		"tarps": _set_tarps(state)
		"decoy": _set_decoy(state)
		"zombie_bait": _set_zombie_bait(state)
		"north_band": _set_north_band(state)
		"new_ore": _set_new_ore(state)
		"stump": _set_stump(state)
		"hardwood": _set_hardwood(state)
		"hardwood_night": _set_hardwood_night(state)
		"sprinklers": _set_sprinklers(state)
		"fishing_bar": _set_fishing_bar(state)
		"winter_fishing": _set_winter_fishing(state)
		"winter_quarry": _set_winter_quarry(state)
		"winter_stumps": _set_winter_stumps(state)
		"bait": _set_bait(state)
		"fish_book": _set_fish_book(state)
		"coop_barn": _set_coop_barn(state)
		"barnyard": _set_barnyard(state)
		"barnyard_night": _set_barnyard_night(state)
		"barn_night": _set_barn_night(state)
		"keg_jar": _set_keg_jar(state)
		"machines": _set_machines(state)
		"machines_worn": _set_machines_worn(state)
		"shipping_bin": _set_shipping_bin(state)
		"peddler": _set_peddler(state)
		"house_tiers": _set_house_tiers(state)
		"tips": _set_tips(state)
		"days": _set_days(state)
		"kitchen": _set_kitchen(state)
		"winter_build": _set_winter_build(state)
		"forecast_dusk": _set_forecast_dusk(state)
		"forecast_build": _set_forecast_build(state)
		"forecast_calm": _set_forecast_calm(state)
		"season_summer": _set_season_summer(state)
		"season_autumn": _set_season_autumn(state)
		"season_winter": _set_season_winter(state)
		"season_winter_night": _set_season_winter_night(state)
		"woken": _set_woken(state)
		"repair": _set_repair(state)
		"aim": _set_aim(state)
		"options_controls_pad": _set_options_controls_pad(state)

	# **A picture never writes the player's settings.** A run set late in
	# the year has the lessons behind it (`_on_date`), and the prompt that
	# sees a finished tutorial records `gameplay/tutorial_seen` in the real
	# `user://settings.cfg` - which mutes day one's lines on this machine, and
	# `input_v1`'s tutorial case with them. Told it has been seen, it stays
	# down and writes nothing.
	if Tutorial.is_finished(state):
		var prompt: Node = main.get_node_or_null("%TutorialPrompt")
		if prompt != null:
			prompt.set("_asked", true)
			prompt.set("_muted", true)

	if int(state["phase"]) == Phases.DAY:
		_walk_to(state, _standing_at)
		main.get_node("%WorldView").look_at_cell(Vector2i(51, 22) if name == "twelve_crops" else Player.cell(state))
	else:
		var at := _camera_at if _camera_at.x >= 0 else Farm.house_centre(state)
		main.aim_night_camera((Vector2(at) + Vector2.ONE * 0.5) * float(GameData.TILE_SIZE))
		# **The guardian's cursor** (task 0131) on the open ground nearest the
		# picture's middle: the question these pictures answer is whether it
		# reads over dark ground.
		main.get_node("%WorldView").cursor().place_at(_open_ground_near(state, at))
	# Fixtures edit state after begin_run handed it to the view. Two identical
	# fields can share a cached signature; explicitly hand over the completed
	# fixture so consecutive seed-page captures keep the crops on screen.
	main.get_node("%WorldView").show_state(state)
	_only_showing(main, str(entry[2]))
	if name == "twelve_crops":
		for i in Farming.seeds().size():
			var label := Label.new()
			label.name = "CropStageLabel_%d" % i
			label.text = Names.of(Farming.seeds()[i])
			label.position = Vector2(48 + (i % 3) * 5, 18 + (i / 3) * 3) * GameData.TILE_SIZE - Vector2(0, 16)
			label.add_theme_font_override("font", UiKit.font())
			label.add_theme_font_size_override("font_size", 8)
			label.add_theme_color_override("font_color", UiKit.colour(UiKit.WARM))
			label.z_index = 100
			main.get_node("%WorldView").add_child(label)

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
	# Standard stills show a settled reality, not an arbitrary 0.5s of fade.
	# The --switch sequence remains responsible for photographing the change.
	var view := main.get_node("%WorldView") as WorldView
	view.skip_transition()
	view._light_for_phase(0.0)
	# And the bed beat (task 0129), which a build-step scenario would catch.
	(main.get_node("HouseView") as HouseView).skip_bedtime()
	if name == "year_end":
		(main.get_node("%ResultScreen").get_node("CreditsRoll") as CreditsRoll).finish()
	_just_before_the_shutter(main, state, name)
	await process_frame
	if name == "twelve_crops":
		view.look_at_cell(Vector2i(51, 22))
	await RenderingServer.frame_post_draw

	if name == "inventory_full":
		var inventory := main.get_node("%InventoryPanel") as InventoryPanel
		inventory.select_group(&"materials")
		for page in inventory.page_count():
			await process_frame
			await process_frame
			var group: Dictionary = inventory._pages[inventory.current_page()]
			await _shoot("inventory_full_%s_%d" % [group["name"], group["part"] + 1], folder)
			inventory.turn_page(1)
		print("  inventory_full photographed %d pages" % inventory.page_count())
		return
	if name == "inventory_night":
		var ledger := main.get_node("%InventoryPanel") as InventoryPanel
		for group in [&"materials", &"crops", &"seeds", &"fish", InventoryPanel.BOOK, &"animal_goods",
				&"artisan_goods", &"tools"]:
			ledger.select_group(group)
			await process_frame
			await process_frame
			await _shoot("inventory_night_%s" % group, folder)
		return
	if name == "fish_book":
		# The run's book alone, whatever profile is on this machine: an empty
		# profile, and nothing of the run banked into it (`Main` folds the
		# run when the date moves). The Old Catfish's page, then the Golden
		# Queen's, never caught.
		var ledger := main.get_node("%InventoryPanel") as InventoryPanel
		(state["stats"]["banked"] as Dictionary).erase("fish_book")
		ledger.show_profile({})
		ledger._process(0.0)
		ledger.select_group(InventoryPanel.BOOK)
		ledger.turn_page(FishBook.species().find(GameData.OLD_CATFISH))
		await process_frame
		await process_frame
		await _shoot("fish_book", folder)
		ledger.turn_page(1)
		await process_frame
		await process_frame
		await _shoot("fish_book_unknown", folder)
		print("  fish_book on %s, then %s" % [ledger.book().shown(), FishBook.species()[FishBook.species().find(GameData.OLD_CATFISH) + 1]])
		return
	if name == "barn_night":
		await _shoot("barn_night", folder)
		await _take_barn_morning(main, state, folder)
		return
	if name == "machines":
		await _shoot("machines", folder)
		await _take_machines_working(main, state, folder)
		return
	if name == "shipping_bin":
		await _shoot("shipping_bin", folder)
		await _take_bin_extras(main, state, folder)
		return
	if name == "peddler":
		await _shoot("peddler", folder)
		await _take_stall_dusk(main, state, folder)
		return
	if name == "house_tiers":
		await _shoot("house_tiers", folder)
		await _take_house_tiers(main, state, folder)
		return
	if name == "tips":
		await _shoot("tips", folder)
		await _take_tip_bite(main, state, folder)
		return
	if name == "days":
		await _shoot("days_spring_morning", folder)
		await _take_days(main, state, folder)
		return
	if name == "tarps":
		await _shoot("tarps", folder)
		await _take_tarps_evening(main, state, folder)
		return
	if name == "bone_meal":
		await _shoot("bone_meal", folder)
		await _take_meal_workshop(main, state, folder)
		return
	if name == "night_loot":
		await _shoot("night_loot", folder)
		await _take_loot_morning(main, state, folder)
		return
	if name == "tech_autumn":
		await _shoot("tech_autumn", folder)
		# **And winter's floor from autumn** (task 0220): greyed, with the
		# season it waits for under it.
		(main.get_node("%TechPanel") as TechPanel).show_page(3)
		for _i in 3:
			await process_frame
		await RenderingServer.frame_post_draw
		await _shoot("tech_autumn_winter", folder)
		return
	if name == "inventory_crops":
		(main.get_node("%InventoryPanel") as InventoryPanel).select_group(&"crops")
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
	if name == "tool_upgrades":
		await _take_tool_chop(main, state, folder)
	if name == "quarry":
		await _take_quarry_extras(main, state, folder)
	if name == "twelve_crops":
		for i in Farming.seeds().size():
			main.get_node("%WorldView").get_node("CropStageLabel_%d" % i).free()


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
		# Opened the way the router opens it, so the picture has the caret on
		# RESUME that a player sees.
		if screen.visible and screen.has_method("set_open"):
			screen.set_open(true)


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
func _just_before_the_shutter(main: Node, state: Dictionary,
		name: String) -> void:
	match name:
		"zombie_bait":
			# What the shutter finds (task 0225): the bait, and who is on it.
			var bait: Array = Pathing.lure_cells(state)
			var eating := 0
			for id in Entities.ids(state):
				if not bait.is_empty() and Entities.cell_of(state, id) == bait[0]:
					eating += 1
			print("  bait: %s, %d eating on it of %d" % [str(bait), eating, Entities.count(state)])
		"decoy":
			# What the shutter finds: each decoy's hit points, and who is
			# biting the first (task 0224).
			var standing: Array = []
			for cell in Farm.rubble_cells(state) + Pathing.lure_cells(state):
				standing.append("%s %d" % [cell, int(Farm.occupant(state, cell).get("hp", 0))])
			var biting := 0
			for id in Entities.ids(state):
				if int(Entities.get_one(state, id).get("chewing", -1)) >= 0:
					biting += 1
			print("  decoy: %s; %d of %d have bitten" % [", ".join(standing), biting, Entities.count(state)])
		"can_area":
			SuiteKit.stand_the_farmer(state, _standing_at)
			state["player"]["facing"] = Player.SOUTH
			var view := main.get_node("%WorldView") as WorldView
			view.look_at_cell(_standing_at)
			view.highlight(Player.target(state))
			print("  can_area: %d highlighted plots, capacity %d" % [view.highlighted_cells().size(), Farming.can_capacity(state)])
		"tool_upgrades":
			SuiteKit.stand_the_farmer(state, _standing_at)
			main.get_node("%WorldView").look_at_cell(_standing_at)
			state["player"]["facing"] = Player.SOUTH
			var panel := main.get_node("%WorkshopPanel") as WorkshopPanel
			panel._tool_tab = true
			panel._built_for = ""
			panel._process(0.0)
		"react":
			Reactions.show(state, &"note")
		"tips":
			# Turned to the bin again, and its tip let through: the next
			# frame puts it up.
			SuiteKit.stand_the_farmer(state, _standing_at)
			state["player"]["facing"] = Player.WEST
			(main.get_node("%WorldView") as WorldView).look_at_cell(_standing_at)
			_tips_shown_but(main, [&"bin"])
		"kitchen":
			SuiteKit.stand_the_farmer(state, _standing_at)
			state["player"]["facing"] = Player.NORTH
			(main.get_node("%WorldView") as WorldView).look_at_cell(_standing_at)
			(main.get_node("%WorkshopPanel") as WorkshopPanel)._process(0.0)
		"keg_jar":
			# Stood again and turned to the keg: the walk to the spot
			# leaves him facing wherever he last stepped.
			SuiteKit.stand_the_farmer(state, _standing_at)
			state["player"]["facing"] = Player.NORTH
			(main.get_node("%WorldView") as WorldView).look_at_cell(_standing_at)
			(main.get_node("%WorkshopPanel") as WorkshopPanel)._process(0.0)
		"refused":
			# **Pointed by hand, because there is no mouse.** `BuildMode`
			# takes its cell from the pointer every frame, so a scripted
			# state with `build_cell` set has it overwritten before the
			# shutter - which is how the first picture came back with an
			# empty panel and no ghost.
			var mode: Node = main.get_node_or_null("%BuildMode")
			var view: Node = main.get_node_or_null("%WorldView")
			if mode == null or view == null:
				return
			# **The longest refusal there is**, not the shortest. "in the
			# water" fits anything; "there is a workshop there already"
			# is the one that finds out whether the panel wraps.
			var taken: Vector2i = Farm.cells_with(state, &"workshop")[0]
			mode.set("_pointer", view.cell_to_screen(taken))
			# At night the guardian's cursor is what build mode follows.
			view.cursor().place_at(taken)
			mode.call("_follow_cursor")
		"repair":
			var repair_view: Node = main.get_node_or_null("%WorldView")
			if repair_view != null:
				repair_view.cursor().place_at(_repair_at)
		"aim":
			var aim_view: Node = main.get_node_or_null("%WorldView")
			if aim_view != null:
				aim_view.cursor().place_at(_repair_at)
				aim_view.cursor().arm()
				main.call("_drive_cursor", 0.0)
		"winter_build":
			# The wall held over open ground by the house, so the preview
			# runs from every side open tonight (task 0157).
			var winter_mode: Node = main.get_node_or_null("%BuildMode")
			var winter_view: Node = main.get_node_or_null("%WorldView")
			if winter_mode == null or winter_view == null:
				return
			var spot := _open_ground_near(state, Farm.house_centre(state) + Vector2i(5, 1))
			winter_mode.set("_pointer", winter_view.cell_to_screen(spot))
			winter_view.cursor().place_at(spot)
			winter_mode.call("_follow_cursor")
			print("winter_build: %d route cells from %d sides"
				% [winter_view.previewed_route().size(),
					Calendar.open_sides(Phases.night_ahead(state)).size()])
		"build_day":
			var day_mode: Node = main.get_node_or_null("%BuildMode")
			var day_view: Node = main.get_node_or_null("%WorldView")
			if day_mode == null or day_view == null:
				return
			var open := _room_for_selected(state, Player.cell(state) + Vector2i(4, -3))
			day_mode.set("_pointer", day_view.cell_to_screen(open))
			day_mode.call("_follow_cursor")
		"passed_out":
			# **Lying, not falling.** The settle is half a second and the
			# collapse is longer; the picture is of the frame the view holds.
			var farmer: Node = main.get_node_or_null("%WorldView/Occupants/PlayerView")
			if farmer != null:
				farmer.set("_elapsed", 5.0)


## Build mode with the ghost somewhere it will not go, task 0110.
##
## **The one place a refusal is drawn.** The rules hand back a key and the
## panel says it, and the panel is 124 pixels wide - so this is the picture
## that answers whether "there is a wall there already" fits, in both
## languages, which no width column can.
func _set_refused(state: Dictionary) -> void:
	_a_sown_field(state)
	Resources.gain(state, {GameData.WOOD: 200, GameData.STONE: 200})
	# **In the build step since task 0132**: a wall goes down at night only,
	# so the palette is the defences and the guardian's cursor points.
	NightRoad.into_build(state)
	var build: Dictionary = state["build"]
	build["active"] = true
	build["selected"] = &"wall"
	var taken: Vector2i = Farm.cells_with(state, &"workshop")[0]
	(state["intent"] as Dictionary)["build_cell"] = [taken.x, taken.y]
	_look_at(taken)


## Build mode by day, task 0132: the palette holds the production buildings
## and nothing that defends, with the ghost on open ground near the farmer.
func _set_build_day(state: Dictionary) -> void:
	_a_sown_field(state)
	Resources.gain(state, {GameData.WOOD: 400, GameData.STONE: 400,
		GameData.IRON: 400, GameData.OIL: 100})
	var build: Dictionary = state["build"]
	build["active"] = true
	build["selected"] = Building.catalogue(state)[0]


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


## The same tab with the last input from a pad (task 0121): every row names
## the pad's button, which is what has to fit.
func _set_options_controls_pad(state: Dictionary) -> void:
	_set_noon(state)
	var actions: Node = root.get_node_or_null(^"Actions")
	if actions != null:
		actions.using_pad = true
		actions.device_changed.emit(true)


func _a_sown_field(state: Dictionary) -> void:
	Resources.gain(state, {GameData.MONEY: 999, GameData.WOOD: 180,
		GameData.STONE: 120, GameData.IRON: 90, GameData.OIL: 30})
	var seeds := Farming.in_season(state)
	var sown := 0
	var middle := Vector2i.ZERO
	for cell in Farming.field_cells(state):
		if Interact.verb_at(state, cell) != &"till":
			continue
		# **Winter sows nothing** (task 0170): its beds are turned and bare.
		# The packet arithmetic below divided by an empty season.
		if not seeds.is_empty():
			SuiteKit.crop_supplies(state, StringName(seeds[sown % seeds.size()]))
			Farming.select_seed(state, StringName(seeds[sown % seeds.size()]))
		Interact.complete(state, cell, &"till")
		if not seeds.is_empty():
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
		_look_at(Vector2i(middle.x + 3, middle.y))
	# Daytime establishes the clock; individual scenarios choose crop ages.
	Sim.advance(state, 40 * GameData.SECONDS)


func _set_house_interior(state: Dictionary) -> void:
	_walk_to(state, House.porch(state))
	House.enter(state)
	# **Beside the bed** since task 0127, so the picture shows what the line
	# at the bottom says there: the way to bed, which is the way to the night.
	_standing_at = House.bed().position + Vector2i(1, House.bed().size.y)


## The north-west beds of the farmstead, planted and grown.
##
## **Stood beside, not walked to.** Since the farmstead moved to the middle of
## the farm (2026-10-06) its workshop and well stand between the porch and
## these beds, and the walk stopped at the well with the crops behind the
## crop table. The farmer starts the picture next to them instead.
func _set_farm_extension(state: Dictionary) -> void:
	SuiteKit.crop_supplies(state, GameData.CARROT)
	Resources.gain(state, {GameData.MONEY: 999})
	for y in range(20, 23):
		for x in range(30, 34):
			var cell := Vector2i(x, y)
			Farming.act(state, cell)
			Farming.act(state, cell)
			state["plots"][Grid.index(cell)]["growth"] = Farming.days_to_grow(Farming.crop_on(state, cell))
	_standing_at = Vector2i(34, 21)
	_stand(state, _standing_at)


## The press, the kitchen and the generator on the open ground east of the
## stall, measured from the porch so the picture follows the farmstead.
## The old cells were the old yard's and now sit behind the workshop; the
## generator's no longer fitted at all. Each is four by three, so each takes
## the nearest room it fits rather than a cell that a tree may be on.
func _set_larger_stations(state: Dictionary) -> void:
	Resources.gain(state, {GameData.WOOD: 999, GameData.STONE: 999, GameData.IRON: 999})
	var porch := GameData.PLAYER_START
	for pair in [[&"press", Vector2i(8, -4)], [&"kitchen", Vector2i(13, -4)],
			[&"generator", Vector2i(18, -4)]]:
		var at := _room_near(state, pair[0], porch + pair[1])
		if at != Vector2i(-1, -1):
			Building.place(state, pair[0], at)
	_standing_at = porch + Vector2i(12, 0)
	_stand(state, _standing_at)


## The cell nearest `near` where `id` can go, ring by ring, or (-1, -1).
func _room_near(state: Dictionary, id: StringName, near: Vector2i) -> Vector2i:
	for radius in 6:
		for cell in Grid.within(near, radius):
			if Grid.chebyshev(near, cell) == radius and Building.can_place(state, id, cell):
				return cell
	return Vector2i(-1, -1)


## Put the farmer on a cell outright, for a subject the walk cannot reach.
func _stand(state: Dictionary, cell: Vector2i) -> void:
	state["player"]["pos"] = [cell.x * Player.SUBTILE + Player.SUBTILE / 2,
		cell.y * Player.SUBTILE + Player.SUBTILE / 2]


func _set_noon(state: Dictionary) -> void:
	_a_sown_field(state)
	var keys: Array = state["plots"].keys()
	keys.sort()
	for i in keys.size():
		var plot: Dictionary = state["plots"][keys[i]]
		var days := Farming.days_to_grow(StringName(plot["crop"]))
		plot["growth"] = ((i % 4) * days + 2) / 3
	# **Noon on the clock**, 12:00, where the light ramp is plain day. Until
	# task 0126 gave the day an hour this was half way, and half way is 16:00.
	Sim.advance(state, maxi(Phases.tick_at_minute(WorldView.NOON_MINUTE)
		- int(state["tick"]), 1))


## 0174 - a dry row ahead and a watered row behind it, at native farm scale.
func _set_can_area(state: Dictionary) -> void:
	_set_noon(state)
	state["tools"]["can"] = 1
	state["tech_owned"].append(&"full cans")
	state["water_can"] = Farming.can_capacity(state)
	# A cleared garden: foliage must not hide the farmer or the stroke frames.
	for y in range(18, 24):
		for x in range(29, 36):
			var at := Vector2i(x, y)
			if Farm.occupant(state, at).get("id", &"") in [&"tree", &"rock"]:
				Farm.remove(state, at)
	for y in range(20, 23):
		for x in range(30, 35):
			var at := Vector2i(x, y)
			if not Farm.is_empty(state, at):
				continue
			if Farming.verb_at(state, at) == &"till":
				Farming.act(state, at)
			if not Farming.is_tilled(state, at):
				continue
			var plot := Farming.plot(state, at)
			plot["crop"] = GameData.CARROT
			plot["growth"] = 1
			plot["watered"] = y != 20
	_standing_at = Vector2i(32, 19)
	_stand(state, _standing_at)
	state["player"]["facing"] = Player.SOUTH


## The guardian's cursor over a hurt tower at night, task 0134: the repair
## look and the tooltip that says what mending it costs.
func _set_repair(state: Dictionary) -> void:
	_a_defended_farm(state, true)
	NightRoad.to_night(state)
	NightRoad.park(state)
	Sim.advance(state, 1)
	var towers: Array = Farm.cells_with(state, &"gun_tower")
	_repair_at = towers[0] if not towers.is_empty() else Farm.house_centre(state)
	Farm.damage(state, _repair_at, 25)
	_look_at(_repair_at)


## The flare armed at night, task 0135: its reach drawn round the cursor,
## with walkers just inside the rim and just outside it, so the picture
## says whether the square is what the flare hits.
func _set_aim(state: Dictionary) -> void:
	_a_sown_field(state)
	NightRoad.to_night(state)
	NightRoad.park(state)
	var radius := int(GameData.ABILITY["radius_tiles"])
	_repair_at = _open_ground_near(state, Farm.house_centre(state) + Vector2i(9, 5))
	for step in [Vector2i(radius, 0), Vector2i(-radius, radius), Vector2i(radius + 1, 1),
			Vector2i(0, -radius - 1)]:
		var at: Vector2i = _repair_at + step
		if Farm.walkable(state, at):
			Entities.set_hp(state, Entities.spawn(state, &"walker", at), 999)
	_look_at(_repair_at)


## Where `repair` puts the cursor, for `_just_before_the_shutter`.
var _repair_at := Vector2i(-1, -1)


## Still out on the field at 02:00, task 0129: he passes out where he
## stands and lies there through the short build step.
func _set_passed_out(state: Dictionary) -> void:
	_a_sown_field(state)
	state["day_tick"] = GameData.DAY_TICKS - 1
	Sim.advance(state, 1)
	_look_at(Player.cell(state))


## **The morning report with every line it has** (task 0138): a night that
## began with a pass-out and ended at dawn, a wall lost in it and two still
## on the farm to walk off.
func _set_morning(state: Dictionary) -> void:
	Phases.pass_out(state)
	NightRoad.through_build(state)
	NightRoad.park(state)
	var doomed := SuiteKit.any_buildable(state)
	Farm.place(state, doomed, {"id": &"wall", "hp": 30})
	Farm.damage(state, doomed, 999)
	var far: Vector2i = Enemies.spawn_cells(state, 0)[0]
	for _i in 2:
		Entities.set_hp(state, Entities.spawn(state, &"walker", far), 9999)
	(state["wave"] as Dictionary)["dawn_at"] = int(state["night_tick"]) + 2
	Sim.advance(state, 4)


## **The boss got away** (task 0153): Spring 14, the Giant still standing
## when dawn comes. The report names it and says it comes back tonight.
func _set_boss_escaped(state: Dictionary) -> void:
	state["day"] = GameData.SEASON_DAYS
	state["nights_won"] = GameData.SEASON_DAYS - 1
	NightRoad.to_night(state)
	NightRoad.park(state)
	var far: Vector2i = Enemies.spawn_cells(state, 0)[0]
	Entities.set_hp(state, Entities.spawn(state, Calendar.boss_of(GameData.SEASON_DAYS), far), 99999)
	for _i in 3:
		Entities.set_hp(state, Entities.spawn(state, &"walker", far), 9999)
	(state["wave"] as Dictionary)["dawn_at"] = int(state["night_tick"]) + 2
	Sim.advance(state, 4)


## **The calm night** (task 0154): Summer 1, the first night after Spring's
## boss fell. Nothing came; the report says so, and what is on the porch.
func _set_calm_morning(state: Dictionary) -> void:
	state["day"] = GameData.SEASON_DAYS + 1
	state["nights_won"] = GameData.SEASON_DAYS
	NightRoad.to_night(state)
	Sim.advance(state, 2)


## **The morning after a loss** (task 0155): carrots planted in three rows
## across the horde's east route by the house, the middle row on it; the
## house falls, the report is confirmed, and he is outside looking at them.
## The middle row is trampled and the two either side are not.
func _set_trampled(state: Dictionary) -> void:
	state["day"] = 3
	state["nights_won"] = 2
	Pathing.refresh(state)
	var route := {}
	for start in Enemies.spawn_cells(state, 0):
		var c: Vector2i = start
		for _i in Grid.CELLS:
			route[Grid.index(c)] = true
			var next := Pathing.step_from(state, c)
			if next == c:
				break
			c = next
	var plots: Dictionary = state["plots"]
	var near := Farm.house_centre(state)
	for idx in route.keys():
		var c := Grid.cell(int(idx))
		if c.x < near.x + 3 or c.x > near.x + 10:
			continue
		for dy in [-1, 0, 1]:
			var cell := c + Vector2i(0, dy)
			if Farm.is_empty(state, cell) and Farm.walkable(state, cell):
				# Ripe, so the rows the horde spared stand tall beside the
				# one it pressed flat.
				plots[Grid.index(cell)] = {"crop": &"carrot",
					"growth": int((GameData.CROPS[&"carrot"] as Dictionary)["growth_days"]),
					"watered": false}
	NightRoad.to_night(state)
	NightRoad.park(state)
	state["house_hp"] = 1
	Entities.spawn(state, &"walker", House.porch(state))
	for _t in 300:
		if int(state["phase"]) != Phases.NIGHT:
			break
		Sim.advance(state, 1)
	(state["intent"] as Dictionary)["confirm_result"] = true
	Sim.advance(state, 2)
	House.leave(state)
	Sim.advance(state, 2)
	_look_at(near + Vector2i(6, 0))


## **The 1.0 farm** (task 0156): the north spawn ground, the new ore on the
## north-east outcrop, and a hardwood stump in the south-west woods.
func _set_north_band(state: Dictionary) -> void:
	_standing_at = Vector2i(40, 3)
	_stand(state, _standing_at)


func _set_new_ore(state: Dictionary) -> void:
	_standing_at = Vector2i(66, 3)
	_stand(state, _standing_at)


func _set_stump(state: Dictionary) -> void:
	_standing_at = Vector2i(10, 46)
	_stand(state, _standing_at)


## **The big stumps** (task 0177): the one in the south-west woods chipped
## by an iron axe's first swing, the farmer beside it with the axe, and the
## whole one east of him in the same frame, among the trees.
## **The bar mid-catch** (task 0180): on the north-west pond's shore at 08:00
## of Spring 3, a trout on the line - one of its two hits scored, the marker
## on its way across, the green ahead of it.
func _set_fishing_bar(state: Dictionary, date: int = 3, minute: int = 8 * 60) -> void:
	_on_date(state, date)
	state["day_tick"] = Phases.tick_at_minute(minute)
	var anchor: Array = GameData.PONDS[&"north_west_pond"]
	var centre := Vector2i(int(anchor[0]), int(anchor[1]))
	var water := Vector2i(-1, -1)
	var shore := Vector2i(-1, -1)
	var facing := Player.SOUTH
	for radius in range(0, 12):
		for found in Grid.within(centre, radius):
			if water != Vector2i(-1, -1) or Farm.terrain_at(state, found) != Farm.Terrain.WATER:
				continue
			for side in Player.FACING_STEPS.size():
				var dry: Vector2i = found - Player.FACING_STEPS[side]
				if water == Vector2i(-1, -1) and Farm.walkable(state, dry):
					water = found
					shore = dry
					facing = side
	_standing_at = shore
	_stand(state, shore)
	state["player"]["facing"] = facing
	Fishing.begin(state, water)
	var line: Dictionary = state["fishing"]
	line["species"] = GameData.TROUT
	line["zone"] = Fishing.zone_for(state, GameData.TROUT)
	line["zone_at"] = 58
	line["speed"] = Fishing.speed_for(state, GameData.TROUT)
	line["needs"] = 2
	line["stage"] = Fishing.BITING
	line["since"] = 2
	line["hits"] = 1
	line["misses"] = 0
	line["struck"] = 0
	line["left"] = int(GameData.FISHING["bar_ticks"])


## **Fishing in winter** (task 0163): the same cast on Winter 3 at noon, A012's
## snowed shore and corners round water that never freezes.
func _set_winter_fishing(state: Dictionary) -> void:
	_set_fishing_bar(state, 3 * GameData.SEASON_DAYS + 3, 12 * 60)


## **The snow caps** (task 0164): the quarry and the south-west woods on
## Winter 3 - A013's cap on every host the farm has, the 1x1 nodes' generic
## one and the big stumps' 2x2, each at its host's canvas origin.
func _set_winter_quarry(state: Dictionary) -> void:
	_set_quarry(state)
	_on_date(state, 3 * GameData.SEASON_DAYS + 3)


func _set_winter_stumps(state: Dictionary) -> void:
	_on_date(state, 3 * GameData.SEASON_DAYS + 3)
	_set_hardwood(state)


## **The coop and the barn** (task 0183): the barn on its site by the
## animals, the coop beside it to the east - its own site is twelve rows north,
## too far for one picture - at noon on Spring 3. The map's two chickens and
## its cow moved in, the coop filled to its four and two more cows in the barn,
## the farmer at the barn's door.
func _set_coop_barn(state: Dictionary) -> void:
	_set_noon(state)
	_on_date(state, 3)
	Resources.gain(state, {GameData.WOOD: 500, GameData.STONE: 500, GameData.MONEY: 2000})
	var room: Array = GameData.MAP_SITES[&"barn"]
	var barn := Vector2i(int(room[0]), int(room[1]))
	var homes: Array = []
	if Building.place(state, &"barn", barn):
		homes.append([barn, &"cow", 3])
	var coop := Vector2i(-1, -1)
	for y in range(barn.y, barn.y + 4):
		for x in range(barn.x + 6, barn.x + 14):
			if coop.x < 0 and Building.can_place(state, &"coop", Vector2i(x, y + 1)):
				coop = Vector2i(x, y + 1)
	if coop.x >= 0 and Building.place(state, &"coop", coop):
		homes.append([coop, &"chicken", 4])
	for home in homes:
		while Livestock.residents(state, home[0]).size() < int(home[2]):
			if not Livestock.house(state, home[0], home[1]):
				break
		print("  coop_barn: %s at %s, %d inside, door %s" % [Farm.occupant(state, home[0])["id"], home[0],
			Livestock.residents(state, home[0]).size(), Livestock.door_of(state, home[0])])
	# The day's camera follows him: at the barn's door, facing it, the barn
	# stays clear of the seed strip on the left and the coop is in frame.
	_standing_at = Livestock.door_of(state, barn) + Vector2i.DOWN
	_stand(state, _standing_at)
	state["player"]["facing"] = Player.NORTH


## **The barnyard** (task 0185): noon on Spring 3. The barn on its site with
## the map's cow, a sheep and two pigs, the coop beside it with four hens, all
## of them about their homes; the pigs' spots for the morning on the grass;
## the farmer in the open below the pen, and the dog a step behind him.
func _set_barnyard(state: Dictionary) -> void:
	_set_noon(state)
	_on_date(state, 3)
	Resources.gain(state, {GameData.WOOD: 500, GameData.STONE: 500, GameData.MONEY: 2000})
	var room: Array = GameData.MAP_SITES[&"barn"]
	var barn := Vector2i(int(room[0]), int(room[1]))
	Building.place(state, &"barn", barn)
	for kind in [&"sheep", &"pig", &"pig"]:
		Livestock.house(state, barn, kind)
	var coop := Vector2i(-1, -1)
	for y in range(barn.y, barn.y + 4):
		for x in range(barn.x + 6, barn.x + 14):
			if coop.x < 0 and Building.can_place(state, &"coop", Vector2i(x, y + 1)):
				coop = Vector2i(x, y + 1)
	if coop.x >= 0 and Building.place(state, &"coop", coop):
		while Livestock.residents(state, coop).size() < 4:
			if not Livestock.house(state, coop, &"chicken"):
				break
	# The pigs are fed on their first day: their spots for this morning.
	Livestock.mark_spots(state)
	print("  barnyard: %d in the barn, %d in the coop, spots %s" % [Livestock.residents(state, barn).size(),
		Livestock.residents(state, coop).size() if coop.x >= 0 else 0, str(Livestock.spots(state))])
	# In the open below the barn's pen: the day's camera follows him.
	_standing_at = barn + Vector2i(3, 6)
	_stand(state, _standing_at)
	state["player"]["facing"] = Player.NORTH


## **The barnyard at night** (task 0211): the same homes at 01:30, the
## farmer still up. The pigs' spots go with the sun only at bedtime
## (`Phases.begin_preparation`), so the late evening, half way to the
## night's light (`WorldView.EVENING_DEPTH`), is the darkest their mounds
## ever see.
func _set_barnyard_night(state: Dictionary) -> void:
	_set_barnyard(state)
	_camera_at = _standing_at
	Sim.advance(state, maxi(Phases.tick_at_minute(25 * 60 + 30) - int(state["day_tick"]), 1))


## **Barns at night** (task 0186): the night of Spring 3. The barn on its
## site wrecked - standing at 0 HP, its cow and sheep inside - and a second
## barn east of it hurt past the wear line; then the next morning
## (`_take_barn_morning`). **No breakers in the picture**: the driver runs in
## real time under the settle, up to ten ticks a frame on a loaded machine,
## and two breakers at its walls had wrecked the hurt one too by the shutter.
func _set_barn_night(state: Dictionary) -> void:
	_on_date(state, 3)
	Resources.gain(state, {GameData.WOOD: 500, GameData.STONE: 500, GameData.MONEY: 2000})
	var room: Array = GameData.MAP_SITES[&"barn"]
	var wreck := Vector2i(int(room[0]), int(room[1]))
	Building.place(state, &"barn", wreck)
	Livestock.house(state, wreck, &"sheep")
	var hurt := Vector2i(-1, -1)
	for x in range(wreck.x + 6, wreck.x + 16):
		if hurt.x < 0 and Building.can_place(state, &"barn", Vector2i(x, wreck.y)):
			hurt = Vector2i(x, wreck.y)
	if hurt.x >= 0 and Building.place(state, &"barn", hurt):
		for kind in [&"sheep", &"pig"]:
			Livestock.house(state, hurt, kind)
	NightRoad.to_night(state)
	NightRoad.park(state)
	# Through `Farm.damage`, the breakers' own road: the wreck is marked,
	# the hunt field told, the log told.
	Farm.damage(state, wreck, 999)
	# Hurt, and not yet smoking: under the art's three quarters and over the
	# particles' two fifths.
	if hurt.x >= 0:
		Farm.damage(state, hurt, 40)
	_barns = [wreck, hurt]
	print("  barn_night: wreck at %s %d hp, hurt at %s %d hp" % [wreck, int(Farm.occupant(state, wreck).get("hp", -1)),
		hurt, int(Farm.occupant(state, hurt).get("hp", -1)) if hurt.x >= 0 else -1])
	_look_at(wreck + Vector2i(5, 3))


## The wrecked barn and the hurt one, for the morning after.
var _barns: Array = []


## **The next morning** (task 0186): dawn ends the night, the report is
## confirmed, and he is out in front of the two barns - the wreck still
## standing, nobody in its pen; the hurt one's animals out in theirs.
func _take_barn_morning(main: Node, state: Dictionary, folder: String) -> void:
	(state["wave"] as Dictionary)["dawn_at"] = int(state["night_tick"]) + 2
	Sim.advance(state, 4)
	(state["intent"] as Dictionary)["confirm_result"] = true
	Sim.advance(state, 1)
	House.leave(state)
	var wreck: Vector2i = _barns[0]
	var hurt: Vector2i = _barns[1]
	# Below the wreck, facing it: the camera follows him, and this keeps both
	# barns clear of the seed bag's page in the day HUD's top left corner.
	_stand(state, wreck + Vector2i(3, 6))
	state["player"]["facing"] = Player.NORTH
	_only_showing(main, "")
	var view := main.get_node("%WorldView") as WorldView
	view.show_state(state)
	view.look_at_cell(Player.cell(state))
	for _i in SETTLE:
		Sim.advance(state, STIR_TICKS)
		await process_frame
	(main.get_node("HouseView") as HouseView).skip_bedtime()
	view.skip_transition()
	view._light_for_phase(0.0)
	await process_frame
	await _shoot("barn_night_morning", folder)
	print("  barn_night_morning: %s, wreck %d hp, %d inside, door offers %s; hurt %d hp" % [
		Phases.name_of(int(state["phase"])), int(Farm.occupant(state, wreck).get("hp", -1)),
		Livestock.residents(state, wreck).size(), Interact.verb_at(state, Livestock.door_of(state, wreck)),
		int(Farm.occupant(state, hurt).get("hp", -1)) if hurt.x >= 0 else -1])


## **Days in a barrel** (task 0187): noon on Spring 3. A keg east of the
## barn's site aging wine, two of its seven mornings gone and a second batch
## behind it, its panel up and counting days; a preserves jar beside it
## setting jelly. Both working.
func _set_keg_jar(state: Dictionary) -> void:
	_set_noon(state)
	_on_date(state, 3)
	Resources.gain(state, {GameData.WOOD: 200, GameData.IRON: 20, GameData.STONE: 100,
		GameData.MONEY: 500, GameData.GRAPE: 6, GameData.STRAWBERRY: 3, GameData.SUGAR: 1})
	var room: Array = GameData.MAP_SITES[&"barn"]
	var keg := Vector2i(-1, -1)
	var jar := Vector2i(-1, -1)
	for y in range(int(room[1]), int(room[1]) + 6):
		for x in range(int(room[0]), int(room[0]) + 14):
			var at := Vector2i(x, y)
			if keg.x < 0 and Building.can_place(state, &"keg", at) \
					and Building.can_place(state, &"preserves_jar", at + Vector2i(3, 0)) \
					and Farm.walkable(state, at + Vector2i(0, 2)):
				keg = at
				jar = at + Vector2i(3, 0)
	Building.place(state, &"keg", keg)
	Building.place(state, &"preserves_jar", jar)
	for recipe in [&"make_wine", &"make_wine"]:
		Crafting.start(state, keg, recipe)
	Crafting.start(state, jar, &"make_jelly")
	Crafting.morning(state)
	Crafting.morning(state)
	print("  keg_jar: keg at %s %s, jar at %s %s" % [keg, str(Crafting.progress_at(state, keg)),
		jar, str(Crafting.progress_at(state, jar))])
	_standing_at = keg + Vector2i(0, 2)
	_stand(state, _standing_at)
	state["player"]["facing"] = Player.NORTH


## **The five machines** (task 0188): noon on Spring 3, a row of them by
## the barn's empty site - keg, preserves jar, dairy, loom and mill, a cell
## apart but the keg and the jar side by side - all idle; then the same
## row working (`_take_machines_working`).
func _set_machines(state: Dictionary) -> void:
	_set_noon(state)
	_on_date(state, 3)
	Resources.gain(state, {GameData.WOOD: 600, GameData.IRON: 40, GameData.STONE: 300,
		GameData.MONEY: 2000})
	# **On open grass, nearest the barn's empty site** - in rings out from
	# it, so the row is not put down over the sown field the noon brings.
	var room: Array = GameData.MAP_SITES[&"barn"]
	var site := Vector2i(int(room[0]), int(room[1]))
	var origin := Vector2i(-1, -1)
	for reach in 24:
		for dy in range(-reach, reach + 1):
			for dx in [reach - absi(dy), absi(dy) - reach]:
				if origin.x < 0 and _row_fits(state, site + Vector2i(dx, dy)):
					origin = site + Vector2i(dx, dy)
	_machines = {}
	var left := origin.x
	for machine in MACHINE_ROW:
		_machines[machine] = Vector2i(left, origin.y)
		Building.place(state, machine, _machines[machine])
		left += _row_step(machine)
	print("  machines: a row at %s, %s" % [origin, str(_machines)])
	# Below the jar: the camera follows him, and this keeps the keg clear of
	# the seed bag's page in the day HUD's top left corner.
	_standing_at = origin + Vector2i(3, 4)
	_stand(state, _standing_at)
	state["player"]["facing"] = Player.NORTH


## The five, left to right.
const MACHINE_ROW := [&"keg", &"preserves_jar", &"dairy", &"loom", &"mill"]


## **The machines worn** (task 0213): the row `machines` puts down, at noon -
## the keg and the dairy hurt past the wear line, the jar and the loom
## wrecked and standing, the mill whole.
func _set_machines_worn(state: Dictionary) -> void:
	_set_machines(state)
	for machine in [&"keg", &"dairy"]:
		Farm.damage(state, _machines[machine], int(GameData.BUILDINGS[machine]["hp"]) * 3 / 4)
	for machine in [&"preserves_jar", &"loom"]:
		Farm.damage(state, _machines[machine], int(GameData.BUILDINGS[machine]["hp"]))


## From one machine's left edge to the next one's: a cell apart, but the keg
## and the jar side by side - sixteen cells is what fits between the trees
## west of the barn's site and the path east of it.
func _row_step(machine: StringName) -> int:
	return Building.size_of(machine).x + (0 if machine == &"keg" else 1)


## Where `machines` put each of them.
var _machines: Dictionary = {}


## Whether the five fit side by side from `origin`, a cell apart, every cell
## of them open grass, with grass below for the farmer to stand on.
func _row_fits(state: Dictionary, origin: Vector2i) -> bool:
	var left := origin.x
	for machine in MACHINE_ROW:
		var at := Vector2i(left, origin.y)
		if not Building.can_place(state, machine, at):
			return false
		for cell in Building.footprint(machine, at):
			if Farm.terrain_at(state, cell) != Farm.Terrain.GRASS or Farming.is_tilled(state, cell):
				return false
		left += _row_step(machine)
	var stand := origin + Vector2i(3, 4)
	return Farm.walkable(state, stand) and Farm.terrain_at(state, stand) == Farm.Terrain.GRASS


## **The same row working** (task 0188): wine in the keg, jelly in the jar,
## and five of butter, cloth and flour queued at the others, so none of
## them runs dry before the shutter.
func _take_machines_working(main: Node, state: Dictionary, folder: String) -> void:
	Resources.gain(state, {GameData.GRAPE: 3, GameData.STRAWBERRY: 3, GameData.SUGAR: 1,
		GameData.MILK: 10, GameData.WOOL: 5, GameData.WHEAT: 5})
	Crafting.start(state, _machines[&"keg"], &"make_wine")
	Crafting.start(state, _machines[&"preserves_jar"], &"make_jelly")
	for _i in 5:
		Crafting.start(state, _machines[&"dairy"], &"make_butter")
		Crafting.start(state, _machines[&"loom"], &"make_cloth")
		Crafting.start(state, _machines[&"mill"], &"make_flour")
	var view := main.get_node("%WorldView") as WorldView
	for _i in SETTLE:
		Sim.advance(state, STIR_TICKS)
		await process_frame
	view.skip_transition()
	view._light_for_phase(0.0)
	await process_frame
	await _shoot("machines_working", folder)
	var running: Array = []
	for machine in MACHINE_ROW:
		running.append("%s %s" % [machine, WorldView.station_running(state, machine, _machines[machine])])
	print("  machines_working: %s" % ", ".join(running))
	# **The row at night** (task 0213): the same jobs at 01:30, the farmer
	# still up - the jar's firebox lit while it works, the rest dark.
	Sim.advance(state, maxi(Phases.tick_at_minute(25 * 60 + 30) - int(state["day_tick"]), 1))
	for _i in SETTLE:
		await process_frame
	view.skip_transition()
	view._light_for_phase(0.0)
	await process_frame
	await _shoot("machines_evening", folder)
	running.clear()
	for machine in MACHINE_ROW:
		running.append("%s %s" % [machine, WorldView.station_running(state, machine, _machines[machine])])
	print("  machines_evening: %s" % ", ".join(running))


## **The shipping bin** (task 0189): noon on Spring 3, the bin on its site
## by the porch and the farmer on the site's other cell, facing it - from
## below, he stood in front of it; then its panel and the next morning
## (`_take_bin_extras`).
func _set_shipping_bin(state: Dictionary) -> void:
	_set_noon(state)
	_on_date(state, 3)
	Resources.gain(state, {GameData.CARROT: 12, GameData.WOOD: 30})
	var bin: Vector2i = Farm.cells_with(state, Shipping.BIN)[0]
	_standing_at = bin + Vector2i.RIGHT
	_stand(state, _standing_at)
	state["player"]["facing"] = Player.WEST


## **The bin's panel and the morning after** (task 0189): ten carrots and
## twenty wood in, the panel up with the morning's total on top and the next
## stack lit; then the night, won at once, and the report's line naming what
## the bin pays.
func _take_bin_extras(main: Node, state: Dictionary, folder: String) -> void:
	Shipping.put(state, GameData.CARROT, 10)
	Shipping.put(state, GameData.WOOD, 20)
	Shipping.open(state)
	_only_showing(main, "ShopPanel")
	for _i in 4:
		await process_frame
	await _shoot("shipping_bin_panel", folder)
	var due := Shipping.due(state)
	state["open_panel"] = &""
	NightRoad.to_night(state)
	NightRoad.park(state)
	(state["wave"] as Dictionary)["dawn_at"] = int(state["night_tick"]) + 2
	Sim.advance(state, 4)
	_only_showing(main, "ResultScreen")
	var view := main.get_node("%WorldView") as WorldView
	for _i in SETTLE:
		await process_frame
	view.skip_transition()
	view._light_for_phase(0.0)
	await process_frame
	await _shoot("shipping_bin_morning", folder)
	print("  shipping_bin: $%d due, %s, phase %s" % [due, str(Shipping.waiting(state)),
		Phases.name_of(int(state["phase"]))])


## **The peddler** (task 0190): noon on Spring 3, the stall in his hours and
## him at its east end, the farmer below the stall facing it; then the same
## stall at dusk (`_take_stall_dusk`).
func _set_peddler(state: Dictionary) -> void:
	_set_noon(state)
	_on_date(state, 3)
	var stall: Vector2i = Farm.cells_with(state, &"shop")[0]
	_standing_at = stall + Vector2i(1, 2)
	_stand(state, _standing_at)
	state["player"]["facing"] = Player.NORTH


## **The stall at dusk** (task 0190): 18:00, past his hours and his walk
## off - the stall shut, nobody at it, and the reason over it where the
## farmer faces it.
func _take_stall_dusk(main: Node, state: Dictionary, folder: String) -> void:
	var view := main.get_node("%WorldView") as WorldView
	var noon := view.peddler_view().peddler_position()
	state["day_tick"] = Phases.tick_at_minute(GameData.DUSK_MINUTE)
	for _i in 6:
		await process_frame
	view.skip_transition()
	view._light_for_phase(0.0)
	await process_frame
	await _shoot("peddler_dusk", folder)
	print("  peddler: at %s by noon, %s at dusk; stall %s" % [noon, view.peddler_view().peddler_position(),
		"open" if Shop.open_hours(state) else "shut"])


## **The house in three tiers** (task 0191): noon on Spring 3, the house
## still tier I, with the money for both tiers above it, and the farmer by
## its west wall facing it. The camera follows him, so the house stands right
## of the middle, clear of the seed panel; then tiers II and III and the
## upgrades tab (`_take_house_tiers`).
func _set_house_tiers(state: Dictionary) -> void:
	_set_noon(state)
	_on_date(state, 3)
	Resources.gain(state, {GameData.MONEY: 2500, GameData.WOOD: 200, GameData.STONE: 300,
		GameData.IRON: 60})
	var bounds := Farm.house_bounds(state)
	_standing_at = _open_ground_near(state, Vector2i(bounds.position.x - 1, bounds.end.y))
	_stand(state, _standing_at)
	state["player"]["facing"] = Player.EAST


## **Tiers II and III** (task 0191), bought on the spot, each with its plaque
## over the door; between them the farmer at the bench with the workshop's
## upgrades tab up, scrolled to the house's row, offering tier III at its
## price.
func _take_house_tiers(main: Node, state: Dictionary, folder: String) -> void:
	var view := main.get_node("%WorldView") as WorldView
	var bought: Array = [House.tier(state)]
	House.buy_tier(state)
	bought.append(House.tier(state))
	for _i in 6:
		await process_frame
	await _shoot("house_tiers_2", folder)
	var bench: Vector2i = Farm.cells_with(state, &"workshop")[0]
	SuiteKit.stand_the_farmer(state, bench + Vector2i.UP)
	state["player"]["facing"] = Player.SOUTH
	view.look_at_cell(bench + Vector2i.UP)
	var panel := main.get_node("%WorkshopPanel") as WorkshopPanel
	panel._tool_tab = true
	panel._built_for = ""
	panel._process(0.0)
	# **Scrolled once it is laid out**: a row added this frame has no place
	# in the scroll yet.
	await process_frame
	var row := panel.find_child("house_tier_up", true, false) as Button
	if row != null:
		(panel.find_child("WorkshopRecipeScroll", true, false) as ScrollContainer).ensure_control_visible(row)
	for _i in 4:
		await process_frame
	await _shoot("house_tiers_panel", folder)
	var offered := row.text.strip_edges() if row != null else "(no row)"
	House.buy_tier(state)
	bought.append(House.tier(state))
	SuiteKit.stand_the_farmer(state, _standing_at)
	state["player"]["facing"] = Player.EAST
	view.look_at_cell(_standing_at)
	for _i in 6:
		await process_frame
	await _shoot("house_tiers_3", folder)
	print("  house_tiers: tiers %s, a whole house %d, the tab offered '%s', the farmer at %s" % [
		str(bought), Phases.house_full(state), offered, str(_standing_at)])


## **The played days** (task 0196): `day_tour.gd`'s Spring 9, its farm played
## to the morning and then to 07:00 - the strawberries coming in - and the
## rest of the two days in `_take_days`.
func _set_days(state: Dictionary) -> void:
	_become(state, DayTour.prepare(&"spring"))
	DayTour.play(state, &"spring", 7 * 60)
	_standing_at = Player.cell(state)


## Spring 9's noon (at the pond) and dusk (at the bin, the forecast up), then
## Summer 9's farm played afresh to 07:00 (the peppers and the corn), 11:46
## (the jars and the keg being filled) and dusk.
func _take_days(main: Node, state: Dictionary, folder: String) -> void:
	var view := main.get_node("%WorldView") as WorldView
	var season := &"spring"
	for take in [[&"spring", 12 * 60, "days_spring_noon"], [&"spring", 18 * 60, "days_spring_dusk"],
			[&"summer", 7 * 60, "days_summer_morning"], [&"summer", 11 * 60 + 46, "days_summer_noon"],
			[&"summer", 18 * 60, "days_summer_dusk"]]:
		if StringName(take[0]) != season:
			season = StringName(take[0])
			# **Summer on a fresh run, as every scenario is.** Kept, the log
			# had read spring's record to a later tick than any of summer's,
			# and went on showing spring's lines over summer.
			seed(SPARK_SEED)
			main.begin_run(SEED)
			_tips_shown_but(main, [])
			if _speaking != "":
				I18n.use(_speaking)
				I18n.relabel(main)
			state = main.get_node("%SimDriver").state
			_become(state, DayTour.prepare(season))
		DayTour.play(state, season, int(take[1]))
		if Phases.clock_minute(state) < int(take[1]):
			Sim.advance(state, Phases.tick_at_minute(int(take[1])) - int(state["day_tick"]))
		view.show_state(state)
		view.look_at_cell(Player.cell(state))
		for _i in 12:
			await process_frame
		view.look_at_cell(Player.cell(state))
		view.skip_transition()
		view._light_for_phase(0.0)
		await process_frame
		await RenderingServer.frame_post_draw
		await _shoot(String(take[2]), folder)
		print("  days: %s at %02d:%02d, the farmer at %s" % [take[2], Phases.clock_minute(state) / 60,
			Phases.clock_minute(state) % 60, Player.cell(state)])


## Make `state` another, in place: every view keeps the dictionary it holds.
func _become(state: Dictionary, other: Dictionary) -> void:
	state.clear()
	state.merge(other)


## **The tips** (task 0195): noon on Spring 3, a day after the first and its
## lessons behind it, the farmer beside the shipping bin facing it - its tip
## over the bin; then the first bite's over the bar (`_take_tip_bite`).
func _set_tips(state: Dictionary) -> void:
	_set_noon(state)
	_on_date(state, 3)
	_standing_at = Farm.cells_with(state, Shipping.BIN)[0] + Vector2i.RIGHT
	_stand(state, _standing_at)
	state["player"]["facing"] = Player.WEST


## **The first bite's tip** (task 0195): the farmer on the north-west pond's
## shore, a line in, a fish on it at once - the bar up, and its tip over it.
func _take_tip_bite(main: Node, state: Dictionary, folder: String) -> void:
	var tips := main.find_child("Tips", true, false) as Tips
	var at: Array = GameData.PONDS[&"north_west_pond"]
	var water := Vector2i(-1, -1)
	var shore := Vector2i(-1, -1)
	for radius in 12:
		for cell in Grid.within(Vector2i(int(at[0]), int(at[1])), radius):
			if water.x >= 0 or Farm.terrain_at(state, cell) != Farm.Terrain.WATER:
				continue
			if Farm.walkable(state, cell + Vector2i.DOWN):
				water = cell
				shore = cell + Vector2i.DOWN
	SuiteKit.stand_the_farmer(state, shore)
	state["player"]["facing"] = Player.NORTH
	(main.get_node("%WorldView") as WorldView).look_at_cell(shore)
	_tips_shown_but(main, [&"bite"])
	# The bin's tip goes first: its moment is over once he walks off, and
	# one tip is up at a time.
	for _i in 900:
		if tips == null or tips.showing() == &"":
			break
		await process_frame
	Fishing.begin(state, water)
	state["fishing"]["left"] = 1
	for _i in 120:
		await process_frame
		if Fishing.is_biting(state) and tips != null and tips.showing() == &"bite":
			break
	for _i in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	await _shoot("tips_bite", folder)
	print("  tips: the bin's, then %s at the bar (biting %s)" % [tips.showing() if tips != null else &"none",
		Fishing.is_biting(state)])


## Every tip counted as shown in the run's profile but `let`.
func _tips_shown_but(main: Node, let: Array) -> void:
	var shown: Array = []
	for entry in GameData.TIPS:
		var id := StringName((entry as Dictionary)["id"])
		if not let.has(id):
			shown.append(String(id))
	(main.call(&"profile") as Dictionary)["tips_seen"] = shown


## **The kitchen** (task 0192): noon on Spring 3, a kitchen on open grass
## nearest the barn's empty site and the farmer below it facing it, its
## panel up - the seven dishes, a stew on the fire - with spring's carrots,
## potatoes and a carp in hand, and flour, eggs and milk for the rest.
func _set_kitchen(state: Dictionary) -> void:
	_set_noon(state)
	_on_date(state, 3)
	Resources.gain(state, Building.cost_of(&"kitchen"))
	Resources.gain(state, {GameData.CARROT: 6, GameData.POTATO: 3, GameData.CARP: 2,
		GameData.FLOUR: 2, GameData.EGG: 4, GameData.MILK: 2})
	var room: Array = GameData.MAP_SITES[&"barn"]
	var site := Vector2i(int(room[0]), int(room[1]))
	var at := Vector2i(-1, -1)
	for reach in 24:
		for dy in range(-reach, reach + 1):
			for dx in [reach - absi(dy), absi(dy) - reach]:
				if at.x < 0 and _kitchen_fits(state, site + Vector2i(dx, dy)):
					at = site + Vector2i(dx, dy)
	Building.place(state, &"kitchen", at)
	Crafting.start(state, at, &"cook_stew")
	_standing_at = at + Vector2i(1, Building.size_of(&"kitchen").y)
	_stand(state, _standing_at)
	state["player"]["facing"] = Player.NORTH
	print("  kitchen: at %s, the farmer at %s" % [at, _standing_at])


## Whether a kitchen fits at `at` with every cell of it open grass, and grass
## below for the farmer to stand on.
func _kitchen_fits(state: Dictionary, at: Vector2i) -> bool:
	if not Building.can_place(state, &"kitchen", at):
		return false
	var size := Building.size_of(&"kitchen")
	for y in size.y + 1:
		for x in size.x:
			if Farm.terrain_at(state, at + Vector2i(x, y)) != Farm.Terrain.GRASS:
				return false
	return Farm.walkable(state, at + Vector2i(1, size.y))


## **The fish book** (task 0182): a spring Full Moon, and four species
## landed this run - three carp, two perch, a trout and, that night, the
## Old Catfish - each counted in the run's book and held.
func _set_fish_book(state: Dictionary) -> void:
	_set_noon(state)
	var moon := int(GameData.FULL_MOON_DAYS[0])
	_on_date(state, moon)
	var book: Dictionary = state["fish_book"]
	for entry in [[GameData.CARP, 3, 2], [GameData.PERCH, 2, 3], [GameData.TROUT, 1, 5],
			[GameData.OLD_CATFISH, 1, moon]]:
		book[entry[0]] = {"caught": entry[1], "first_day": entry[2]}
		Resources.add(state, entry[0], entry[1])


## **Bait on the hook** (task 0181): the bar's shore at 08:00 of Spring 3,
## the iron rod in hand, three worms and four fish bait held and the worm
## on - cast, so one is on the hook and two are left, the line waiting and
## the bait choice under it.
func _set_bait(state: Dictionary) -> void:
	_set_fishing_bar(state)
	Fishing.give_up(state)
	state["tools"]["rod"] = 2
	Resources.gain(state, {GameData.WORM: 3, GameData.BAIT: 4})
	Fishing.choose_bait(state, GameData.WORM)
	var shore: Vector2i = _standing_at
	Fishing.begin(state, shore + Player.FACING_STEPS[int(state["player"]["facing"])])


## **Sprinklers at dawn** (task 0178): a copper, an iron and a gold one in
## the south beds at 06:20. The plots of their patterns are wet and the rest
## dry, and the morning's water is still in the air.
func _set_sprinklers(state: Dictionary) -> void:
	Resources.gain(state, {GameData.MONEY: 999, GameData.COPPER: 9,
		GameData.IRON: 9, GameData.GOLD: 9})
	for pair in [[&"copper_sprinkler", Vector2i(33, 30)],
			[&"iron_sprinkler", Vector2i(36, 30)], [&"gold_sprinkler", Vector2i(44, 31)]]:
		Building.place(state, pair[0], pair[1])
	_a_sown_field(state)
	for idx in state["plots"]:
		state["plots"][idx]["watered"] = false
	Farming.sprinkle(state)
	state["day_tick"] = Phases.tick_at_minute(6 * 60 + 20)
	_standing_at = Vector2i(39, 28)
	_stand(state, _standing_at)


func _set_hardwood(state: Dictionary) -> void:
	state["tools"]["axe"] = 1
	var chipped := Building.anchor_of(state, Vector2i(8, 45))
	Gathering.strike(state, chipped)
	# North of it, facing down: the frame then holds both stumps below the
	# seed list, which since 0168 reaches half way down the left side.
	_standing_at = Vector2i(9, 44)
	_stand(state, _standing_at)
	state["player"]["facing"] = Player.SOUTH


## **A021's big stumps at night** (task 0204): the chipped one and the whole
## one on that night, the waves held off.
func _set_hardwood_night(state: Dictionary) -> void:
	_set_hardwood(state)
	_camera_at = _standing_at
	NightRoad.to_night(state)
	NightRoad.park(state)
	Sim.advance(state, 1)


## **The build step in winter** (task 0157): Winter 2, every side open, a
## wall in hand by the house - and the preview drawing the route from each of
## the five.
func _set_winter_build(state: Dictionary) -> void:
	_on_date(state, 3 * GameData.SEASON_DAYS + 2)
	Resources.gain(state, {GameData.WOOD: 400, GameData.STONE: 400})
	NightRoad.into_build(state)
	var build: Dictionary = state["build"]
	build["active"] = true
	build["selected"] = &"wall"
	_camera_at = Farm.house_centre(state)


## **A run this far into the year**: on `day`, every night before it won, and
## the lessons long behind him.
func _on_date(state: Dictionary, day: int) -> void:
	state["day"] = day
	state["nights_won"] = day - 1
	var lessons: Array = []
	for step in Tutorial.steps():
		lessons.append(StringName((step as Dictionary)["id"]))
	((state["tutorial"] as Dictionary)["done"] as Array).assign(lessons)


func _set_season_summer(state: Dictionary) -> void:
	_set_season(state, 1)


func _set_season_autumn(state: Dictionary) -> void:
	_set_season(state, 2)


func _set_season_winter(state: Dictionary) -> void:
	_set_season(state, 3)


func _set_season_winter_night(state: Dictionary) -> void:
	_set_season_night(state, 3)


## **The seasons on screen** (task 0159): the noon farm, framed as `noon`
## is, on the third day of a season - no Full Moon, no boss, no calm.
func _set_season(state: Dictionary, season: int) -> void:
	_on_date(state, season * GameData.SEASON_DAYS + 3)
	_set_noon(state)


## The same field on that date's night, the waves held off: the night ramp
## over the season.
func _set_season_night(state: Dictionary, season: int) -> void:
	_on_date(state, season * GameData.SEASON_DAYS + 3)
	_a_sown_field(state)
	_camera_at = _standing_at
	NightRoad.to_night(state)
	NightRoad.park(state)
	Sim.advance(state, 1)


## **The forecast at dusk** (task 0158): Spring 14 at 18:30 since task 0162,
## the season's boss night under a Full Moon - the one date of the first
## season whose forecast has every kind's head on it. Autumn 7's, a Full Moon
## from three sides, had four.
func _set_forecast_dusk(state: Dictionary) -> void:
	_on_date(state, GameData.SEASON_DAYS)
	_a_sown_field(state)
	Sim.advance(state, maxi(Phases.tick_at_minute(18 * 60 + 30)
		- int(state["day_tick"]), 1))


## **The forecast in the build step** (task 0158): Winter 14, the year's last
## night - its boss, a Full Moon and every side - with the date on the strip.
func _set_forecast_build(state: Dictionary) -> void:
	_on_date(state, 4 * GameData.SEASON_DAYS)
	NightRoad.into_build(state)
	_camera_at = Farm.house_centre(state)


## **A calm night's forecast** (task 0158): Summer 1 at 18:30 says so and
## nothing else.
func _set_forecast_calm(state: Dictionary) -> void:
	_on_date(state, GameData.SEASON_DAYS + 1)
	_a_sown_field(state)
	Sim.advance(state, maxi(Phases.tick_at_minute(18 * 60 + 30)
		- int(state["day_tick"]), 1))


## **Out of bed at 06:00** (task 0138): the report confirmed, he stands on
## the floor beside his bed - the wake beat cut short, as stills cut the
## bed beat.
func _set_woken(state: Dictionary) -> void:
	NightRoad.to_night(state)
	NightRoad.park(state)
	(state["wave"] as Dictionary)["done"] = true
	Sim.advance(state, 1)
	(state["intent"] as Dictionary)["confirm_result"] = true
	Sim.advance(state, 1)
	_standing_at = Player.cell(state)


## **The farm at 22:30** (task 0140): the clock lit, GO TO BED lit, and
## the evening's line saying it is time for bed.
func _set_bedtime(state: Dictionary) -> void:
	_a_sown_field(state)
	Sim.advance(state, maxi(Phases.tick_at_minute(22 * 60 + 30)
		- int(state["day_tick"]), 1))


func _set_tutorial_bed(state: Dictionary) -> void:
	_set_tutorial_night(state, 0)


func _set_tutorial_start(state: Dictionary) -> void:
	_set_tutorial_night(state, 1)


func _set_tutorial_dawn(state: Dictionary) -> void:
	_set_tutorial_night(state, 2)


## **Day one teaching the night** (task 0141): the day's five lines done, and
## then the bed's line in the house (`stage` 0), START's in the build step
## with a wall down (1), or dawn's in the night (2).
func _set_tutorial_night(state: Dictionary, stage: int) -> void:
	((state["tutorial"] as Dictionary)["done"] as Array).assign(
		[&"chop", &"plant", &"water", &"sell", &"craft"])
	if stage == 0:
		_set_house_interior(state)
		return
	Resources.gain(state, {GameData.WOOD: 200, GameData.STONE: 200})
	NightRoad.into_build(state)
	var spot := Tutorial.points_at(state)
	Building.place(state, &"wall", spot)
	Sim.advance(state, GameData.TUTORIAL_CHECK_TICKS)
	if stage == 2:
		NightRoad.through_build(state)
		NightRoad.park(state)
		Sim.advance(state, GameData.TUTORIAL_CHECK_TICKS)
	_look_at(spot)


func _set_dusk(state: Dictionary) -> void:
	_a_sown_field(state)
	# Just past the hour the ramp starts going warm, so the picture is of the
	# change rather than of the day before it.
	Sim.advance(state, maxi(GameData.DUSK_AT_TICK + 2 * GameData.SECONDS
		- int(state["tick"]), 1))


# ---------------------------------------------------------------- the night

func _set_wave(state: Dictionary) -> void:
	_a_defended_farm(state, true)
	NightRoad.to_night(state)
	Sim.advance(state, 1)
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
	_look_at(_the_defence_line(state))


## **The wave under a Full Moon** (task 0152): the same fight on day 7, so
## the two pictures differ only in the light - brighter, and still night.
func _set_full_moon(state: Dictionary) -> void:
	state["day"] = 7
	state["nights_won"] = 6
	_set_wave(state)


func _set_result(state: Dictionary) -> void:
	_a_defended_farm(state, true)
	NightRoad.to_night(state)
	Sim.advance(state, 1)
	# **The night is played, not declared.** Calling `enter_result` straight
	# out gave a panel with a title and a button and nothing between them -
	# there was no night for it to itemise. `skip_night` is the game's own
	# fast-forward, and task 0078 proved it lands where watching lands.
	Sim.skip_night(state)
	Sim.advance(state, 2)
	# The result leaves the night camera where it was: over the fight.
	_look_at(_the_defence_line(state))


func _set_tech(state: Dictionary) -> void:
	_a_sown_field(state)
	# Enough points that the tree shows all three states at once: bought,
	# affordable and out of reach. One state of anything is a picture that
	# cannot say what the other two look like.
	Resources.gain(state, {GameData.TECH: 9})
	# And three moon stones, so the trade at the bottom is on offer (0221).
	Resources.gain(state, {GameData.MOON_STONE: 3})
	# **The ids have spaces in them.** `&"sharp_tools"` bought nothing and
	# said nothing, and the picture came back with "0 of 12 nodes" on it
	# while the panel showed nine points unspent.
	for id in [&"sharp tools", &"true sights"]:
		if not Tech.buy(state, id):
			push_warning("shot: could not buy %s" % id)
	Sim.advance(state, 2)


## **A lured crowd** (task 0224): the defended farm's night with three decoys
## on open ground past its fence - the three states A037 draws. Walkers, a
## runner and a tank come for the first from the north and the east - the far
## side, so it stands in front of them - and bite it hurt while the guns
## work; the second, out of their reach, stands whole; the third is bitten
## down to its heap of straw. The decoy is picked on the hotbar, which turns
## to its page.
##
## **Timed to the shutter, not to a `Sim.advance`**: the crowd starts at the
## decoy's reach, and the two seconds every picture runs (`SETTLE` frames of
## `STIR_TICKS`) are its walk in - so the picture is of them arriving at a
## decoy still standing, not of the heap they left.
func _set_decoy(state: Dictionary) -> void:
	_a_defended_farm(state, true)
	Resources.gain(state, {GameData.STRAW: 60, GameData.WOOD: 30})
	var middle := _clear_patch(state, Player.cell(state) + Vector2i(19, 1), 4)
	var spots: Array = []
	for offset in [Vector2i.ZERO, Vector2i(-4, 3), Vector2i(-2, 4)]:
		var spot: Vector2i = middle + offset
		if middle.x >= 0 and Building.place(state, &"decoy", spot):
			spots.append(spot)
	if spots.size() < 3:
		push_warning("shot: only %d decoys went down" % spots.size())
		_look_at(_the_defence_line(state))
		return
	NightRoad.through_build(state)
	NightRoad.park(state)
	Enemies.withdraw(state)
	Farm.damage(state, spots[2], int((GameData.DEFENCES[&"decoy"] as Dictionary)["hp"]))
	# Five steps out - the decoy's reach - and the tank three: the walk in
	# is the picture's two seconds and a little more the driver adds.
	var crowd := {Vector2i(0, -3): &"tank", Vector2i(-3, -2): &"runner",
		Vector2i(1, -4): &"walker", Vector2i(-1, -4): &"walker", Vector2i(2, -3): &"walker",
		Vector2i(-2, -3): &"walker", Vector2i(3, -2): &"walker", Vector2i(4, -1): &"walker"}
	for at in crowd:
		Entities.spawn(state, crowd[at], (spots[0] as Vector2i) + (at as Vector2i))
	print("  decoys at %s, %d coming for the first" % [str(spots), Entities.count(state)])
	Building.select(state, &"decoy")
	_look_at((spots[0] as Vector2i) + Vector2i(-1, 2))


## **A crowd turned toward a bait** (task 0225): the defended farm's night,
## a rotten fish thrown on open ground past its fence and a crowd coming in to
## it - the nearest three steps or less, eating on it by the shutter, and the
## rest from five to eight, further than a decoy pulls, still on their way.
## The bait is picked on the hotbar with one kit left, its page turned.
func _set_zombie_bait(state: Dictionary) -> void:
	_a_defended_farm(state, true)
	var middle := _clear_patch(state, Player.cell(state) + Vector2i(19, 1), 4)
	if middle.x < 0:
		push_warning("shot: no open patch for the bait")
		_look_at(_the_defence_line(state))
		return
	NightRoad.through_build(state)
	NightRoad.park(state)
	Enemies.withdraw(state)
	(state["kits"] as Dictionary)[&"zombie_bait"] = 2
	Building.place(state, &"zombie_bait", middle)
	var crowd := {Vector2i(2, 0): &"walker", Vector2i(0, -3): &"walker", Vector2i(-3, 0): &"runner",
		Vector2i(4, -2): &"walker", Vector2i(-4, 3): &"walker", Vector2i(-2, -4): &"walker",
		Vector2i(3, 4): &"walker", Vector2i(4, 4): &"tank"}
	for at in crowd:
		Entities.spawn(state, crowd[at], middle + (at as Vector2i))
	print("  bait at %s, %d coming for it" % [str(middle), Entities.count(state)])
	Building.select(state, &"zombie_bait")
	_look_at(middle + Vector2i(-2, 2))


## The cell nearest `near` with `radius` cells of nothing standing every way
## round it - no tree in front of what is put there - ring by ring.
func _clear_patch(state: Dictionary, near: Vector2i, radius: int) -> Vector2i:
	for ring in 12:
		for cell in Grid.within(near, ring):
			if Grid.chebyshev(near, cell) != ring:
				continue
			var clear := true
			for dy in range(-radius, radius + 1):
				for dx in range(-radius, radius + 1):
					var at: Vector2i = cell + Vector2i(dx, dy)
					clear = clear and Grid.in_bounds(at) and Farm.occupant(state, at).is_empty() \
						and Farm.walkable(state, at)
			if clear:
				return cell
	return Vector2i(-1, -1)


## **The defences asleep** (task 0223): a defended farm at noon on Spring 3,
## its towers under tarps, and one tower hurt last night - its cover torn.
func _set_tarps(state: Dictionary) -> void:
	_on_date(state, 3)
	_a_defended_farm(state)
	# The front row's last tower, whose cover nothing stands in front of.
	var hurt := Vector2i(-1, -1)
	for id in [&"gun_tower", &"auto_crossbow"]:
		for cell in Farm.cells_with(state, id):
			var at: Vector2i = cell
			if hurt.x < 0 or at.y > hurt.y or (at.y == hurt.y and at.x > hurt.x):
				hurt = at
	if hurt.x >= 0:
		Farm.damage(state, hurt, WorldView.levelled_stat(Farm.occupant(state, hurt), "hp") * 2 / 3)
	Sim.advance(state, maxi(Phases.tick_at_minute(WorldView.NOON_MINUTE) - int(state["tick"]), 1))
	_look_at(_the_defence_line(state))
	print("  tarps: %d towers, the one at %s hurt" % [Farm.cells_with(state, &"gun_tower").size()
		+ Farm.cells_with(state, &"auto_crossbow").size(), str(hurt)])


## **Dusk, the wake and the night** (task 0223): the same towers at 18:30,
## still covered; then he goes to bed and the covers are yanked off at the
## wake, caught on that frame; then the night, every tower bare.
func _take_tarps_evening(main: Node, state: Dictionary, folder: String) -> void:
	var view := main.get_node("%WorldView") as WorldView
	Sim.advance(state, maxi(GameData.DUSK_AT_TICK + 30 * GameData.SECONDS - int(state["day_tick"]), 1))
	for _i in SETTLE:
		await process_frame
	await _shoot("tarps_dusk", folder)
	(state["intent"] as Dictionary)["sleep"] = true
	Sim.advance(state, 1)
	main.aim_night_camera((Vector2(_camera_at) + Vector2.ONE * 0.5) * float(GameData.TILE_SIZE))
	# **The bed's beat cut short as it starts**, every frame: it begins a
	# frame after the phase turns, and it would hold the room over the farm
	# through the whole change.
	var house := main.get_node("HouseView") as HouseView
	for _f in 240:
		await process_frame
		house.skip_bedtime()
		if view.tarp_stage() == TarpArt.YANK:
			break
	var caught := view.tarp_stage()
	await _shoot("tarps_unveil", folder)
	view.skip_transition()
	for _i in 4:
		await process_frame
		house.skip_bedtime()
	await _shoot("tarps_night", folder)
	print("  tarps_dusk / tarps_unveil (stage %d) / tarps_night (stage %d), %s" % [caught,
		view.tarp_stage(), Phases.name_of(int(state["phase"]))])


## **Bone meal in the earth** (task 0222): Spring 2 at noon. The top row
## of the first starter bed six wide, turned: plain dry, fertilised dry,
## plain wet, fertilised wet, then a carrot sprout on fertilised earth dry
## and one wet. He stands at the foot of the bed, clear of the row, the
## strip's bone meal chosen.
func _set_bone_meal(state: Dictionary) -> void:
	_on_date(state, 2)
	Resources.gain(state, {GameData.BONE_MEAL: 6})
	var row: Array = []
	for cell in Farming.field_cells(state):
		var at: Vector2i = cell
		var wide := true
		for dx in 6:
			wide = wide and Farm.terrain_at(state, at + Vector2i(dx, 0)) == Farm.Terrain.SOIL
		if wide:
			for dx in 6:
				row.append(at + Vector2i(dx, 0))
			break
	for i in row.size():
		var here: Dictionary = Farming.EMPTY_PLOT.duplicate()
		(state["plots"] as Dictionary)[Grid.index(row[i] as Vector2i)] = here
		here["fertilised"] = i % 2 == 1 or i >= 4
		here["watered"] = i in [2, 3, 5]
		if i >= 4:
			here["crop"] = GameData.CARROT
			here["growth"] = 1
	Farming.select_bone_meal(state)
	_look_at((row[2] as Vector2i) + Vector2i(0, 3))
	Sim.advance(state, maxi(Phases.tick_at_minute(WorldView.NOON_MINUTE)
		- int(state["tick"]), 1))
	print("  bone_meal: row %s, %d fertilised, bone meal chosen: %s" % [str(row),
		row.filter(func(c: Vector2i) -> bool: return Farming.is_fertilised(state, c)).size(),
		str(Farming.fertilising(state))])


## **The bench that grinds it** (task 0222): six bones held, him at the
## workshop, bone meal chosen among its kits.
func _take_meal_workshop(main: Node, state: Dictionary, folder: String) -> void:
	Resources.add(state, GameData.BONES, 6)
	var bench: Vector2i = Farm.cells_with(state, &"workshop")[0]
	_stand(state, bench + Vector2i.UP)
	state["player"]["facing"] = Player.SOUTH
	Crafting.select_recipe(state, &"grind_bone_meal")
	_only_showing(main, "WorkshopPanel")
	var view := main.get_node("%WorldView") as WorldView
	view.show_state(state)
	view.look_at_cell(Player.cell(state))
	for _i in SETTLE:
		Sim.advance(state, STIR_TICKS)
		await process_frame
	await process_frame
	await _shoot("bone_meal_workshop", folder)
	print("  bone_meal_workshop: at %s, the bench chooses %s" % [str(Player.cell(state)),
		str(Crafting.selected_at(state, &"workshop"))])


## **What the night leaves behind** (task 0221): Spring 7, a Full Moon,
## fought from a defended farm to dawn - the morning report says what is
## lying on the farm to collect.
##
## **Held, by a propped-up house.** A Full Moon's horde is more than this
## fixture's eight towers hold, and a lost night's report is a report about
## the loss: its line of what was taken runs off the frame. The house is
## mended every tick, so the night runs to dawn and the bones are the real
## night's.
func _set_night_loot(state: Dictionary) -> void:
	_on_date(state, 7)
	_a_defended_farm(state, true)
	NightRoad.to_night(state)
	for _t in Sim.MOST_TICKS_IN_A_NIGHT:
		if int(state["phase"]) != Phases.NIGHT:
			break
		state["house_hp"] = Phases.house_full(state)
		Sim.advance(state, 1)
	Sim.advance(state, 2)
	print("  night_loot: %s lying, %d piles, stones on %s" % [str(Loot.lying(state)),
		Loot.cells(state).size(), str(Loot.cells_with(state, GameData.MOON_STONE))])
	_look_at(_the_defence_line(state))


## **The morning round** (task 0221): the report confirmed, he is out below
## the moon stone nearest the house, facing it, with the night's bones lying
## about - nothing picked up yet.
func _take_loot_morning(main: Node, state: Dictionary, folder: String) -> void:
	(state["intent"] as Dictionary)["confirm_result"] = true
	Sim.advance(state, 1)
	House.leave(state)
	var home := Farm.house_centre(state)
	var stone := home
	var best := 1 << 30
	for cell in Loot.cells_with(state, GameData.MOON_STONE):
		var far := ((cell as Vector2i) - home).length_squared()
		if far < best:
			best = far
			stone = cell
	var spot := stone + Vector2i(0, 2)
	for step in [Vector2i(0, 2), Vector2i(0, 3), Vector2i(-2, 0), Vector2i(2, 0), Vector2i(0, -2)]:
		var at: Vector2i = stone + (step as Vector2i)
		if Farm.walkable(state, at) and Loot.at(state, at).is_empty():
			spot = at
			break
	_stand(state, spot)
	state["player"]["facing"] = Player.NORTH
	_only_showing(main, "")
	var view := main.get_node("%WorldView") as WorldView
	view.show_state(state)
	view.look_at_cell(Player.cell(state))
	for _i in SETTLE:
		Sim.advance(state, STIR_TICKS)
		await process_frame
	(main.get_node("HouseView") as HouseView).skip_bedtime()
	view.skip_transition()
	view._light_for_phase(0.0)
	await process_frame
	await _shoot("night_loot_morning", folder)
	print("  night_loot_morning: %s, him at %s, the stone at %s, %s lying" % [
		Phases.name_of(int(state["phase"])), str(Player.cell(state)), str(stone),
		str(Loot.lying(state))])


## **The tree in autumn** (task 0220): Autumn 2, so the panel opens on
## autumn's floor. Spring's floor and two of summer's are owned, and so is
## autumn's defence; the essence buys the production node, and the survival
## one waits on the summer node it needs.
func _set_tech_autumn(state: Dictionary) -> void:
	_a_sown_field(state)
	_on_date(state, 2 * GameData.SEASON_DAYS + 2)
	for row in GameData.TECH_TREE:
		if int((row as Dictionary)["season"]) == 0:
			(state["tech_owned"] as Array).append((row as Dictionary)["id"])
	for id in [&"keen edges", &"heavy shot", &"tall mounts"]:
		(state["tech_owned"] as Array).append(id)
	Resources.gain(state, {GameData.TECH: 30})
	Sim.advance(state, 2)


## A farm with something on it worth defending and something defending it.
##
## **The defence goes up in the build step** (task 0119): a night scene opens
## it and builds there (`for_the_night`), a day scene shows a farm whose
## defence went up last night.
func _a_defended_farm(state: Dictionary, for_the_night: bool = false) -> void:
	_a_sown_field(state)
	Resources.gain(state, {GameData.WOOD: 900, GameData.IRON: 900,
		GameData.STONE: 900, GameData.OIL: 200, GameData.GUNPOWDER: 120,
		GameData.INCENDIARY: 60})
	if for_the_night:
		NightRoad.to_build(state)
		_put_up_the_defence(state)
	else:
		SuiteKit.built_last_night(state, func() -> void:
			_put_up_the_defence(state))


## Eight towers in a block beside the farmer and a fence line past them.
func _put_up_the_defence(state: Dictionary) -> void:
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
## The nearest cell to `cell` where build mode's selection would go down.
func _room_for_selected(state: Dictionary, cell: Vector2i) -> Vector2i:
	var id := Building.selected(state)
	for radius in 10:
		for candidate in Grid.within(cell, radius):
			if Building.why_not(state, id, candidate).is_empty():
				return candidate
	return cell


## The nearest cell to `cell` with nothing on it and nobody in it.
func _open_ground_near(state: Dictionary, cell: Vector2i) -> Vector2i:
	for radius in 8:
		for candidate in Grid.within(cell, radius):
			if Grid.in_bounds(candidate) and Farm.walkable(state, candidate) \
					and Describe.under_cursor(state, candidate) == I18n.t(&"CURSOR_GROUND"):
				return candidate
	return cell


## **The camera hook** (task 0130): what a scenario wants in the picture. By
## day the farmer is walked there and the camera follows him; from the
## build step to the morning the night camera is put on it.
func _look_at(cell: Vector2i) -> void:
	_standing_at = cell
	_camera_at = cell


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


## The completed year, without playing fifty-six nights for a picture.
func _set_year_end(state: Dictionary) -> void:
	_on_date(state, Run.final_night())
	_a_defended_farm(state)
	NightRoad.to_night(state)
	NightRoad.park(state)
	(state["killed_by_kind"] as Dictionary)[Calendar.boss_of(Run.final_night())] = 1
	state["bosses_down"] = 4
	state["killed_all_run"] = 1842
	state["structures_lost"] = 12
	(state["wave"] as Dictionary)["dawn_at"] = int(state["night_tick"]) + 2
	Sim.advance(state, 4)


## The same ending while the credits are still rolling.
func _set_year_credits(state: Dictionary) -> void:
	_set_year_end(state)


## 0167 - the starter beds join a hoed lawn, with dry/wet earth and a notch.
func _set_till_grass(state: Dictionary) -> void:
	_till_grass_fixture(state, false)


func _set_till_grass_night(state: Dictionary) -> void:
	_till_grass_fixture(state, true)


func _till_grass_fixture(state: Dictionary, night: bool) -> void:
	_on_date(state, 2)
	Resources.gain(state, {GameData.MONEY: 999})
	state["water_can"] = Farming.can_capacity(state)
	for y in range(20, 24):
		for x in range(30, 37):
			var cell := Vector2i(x, y)
			if cell in [Vector2i(36, 20), Vector2i(35, 23)] or not Farm.is_empty(state, cell):
				continue
			if Farming.verb_at(state, cell) != &"till":
				continue
			Farming.act(state, cell)
			# **Spring's two**, so the fixture stays on Spring 2: wheat
			# became an autumn crop at task 0170, and its packets moved the
			# date there.
			if (x + y) % 3 == 0:
				SuiteKit.crop_supplies(state, GameData.CARROT if x % 2 else GameData.POTATO)
				Farming.select_seed(state, GameData.CARROT if x % 2 else GameData.POTATO)
				Farming.act(state, cell)
				Farming.act(state, cell)
				Farming.plot(state, cell)["growth"] = (x + y) % (Farming.days_to_grow(Farming.crop_on(state, cell)) + 1)
	_look_at(Vector2i(35, 21))
	# A fixture starts beside the new plots, beyond the well on the walk in.
	_stand(state, _standing_at)
	state["day_tick"] = Phases.tick_at_minute(WorldView.NOON_MINUTE)
	if night:
		NightRoad.to_night(state)
		NightRoad.park(state)


## 0168 - each crop occupies a labelled four-stage strip, at game scale.
func _set_twelve_crops(state: Dictionary) -> void:
	_on_date(state, 2)
	state["plots"].clear()
	for y in range(16, 31):
		for x in range(47, 64):
			var idx := Grid.index(Vector2i(x, y))
			state["terrain"][idx] = Farm.Terrain.GRASS
			state["occupants"].erase(idx)
	state["grid_version"] += 1
	var ids := Farming.seeds()
	for i in ids.size():
		var id: StringName = ids[i]
		for stage in 4:
			var cell := Vector2i(48 + (i % 3) * 5 + stage, 18 + (i / 3) * 3)
			var idx := Grid.index(cell)
			# A photographed display bed, not a rule for clearing the real farm.
			state["terrain"][idx] = Farm.Terrain.GRASS
			state["occupants"].erase(idx)
			state["plots"][idx] = {"crop": id, "growth": ceili(float(stage * Farming.days_to_grow(id)) / 3.0),
				"watered": true, "last_worked_morning": int(state["day"])}
	_standing_at = Vector2i(51, 29)
	_stand(state, _standing_at)
	state["day_tick"] = Phases.tick_at_minute(WorldView.NOON_MINUTE)


func _set_seed_page_one(state: Dictionary) -> void:
	_set_noon(state)
	_on_date(state, 2)
	SuiteKit.crop_supplies(state, Farming.in_season(state)[0])
	Farming.select_seed(state, Farming.in_season(state)[0])


func _set_seed_page_two(state: Dictionary) -> void:
	_set_seed_page_one(state)
	SuiteKit.crop_supplies(state, Farming.in_season(state)[3])
	Farming.select_seed(state, Farming.in_season(state)[3])


func _set_shop_seeds_one(state: Dictionary) -> void:
	_set_seed_page_one(state)
	Shop.open(state)
	Shop.show_tab(state, Shop.BUY)


func _set_shop_seeds_two(state: Dictionary) -> void:
	_set_seed_page_two(state)
	Shop.open(state)
	Shop.show_tab(state, Shop.BUY)


func _set_inventory_crops(state: Dictionary) -> void:
	_set_seed_page_one(state)


## 0169 - the entire ledger is held; the shutter visits every bounded page.
func _set_inventory_full(state: Dictionary) -> void:
	_set_noon(state)
	for id in GameData.RESOURCES:
		Resources.add(state, StringName(id), 999)


## **The ledger at night** (task 0202): everything held, opened on Spring 3's
## night with the waves held off - the pages whose icons are Codex art, under
## the night's light.
func _set_inventory_night(state: Dictionary) -> void:
	_set_season_night(state, 0)
	for id in GameData.RESOURCES:
		Resources.add(state, StringName(id), 999)


## Four seasonal crops on the actual starter beds, with held packet counts.
func _set_season_field(state: Dictionary, season: int) -> void:
	_set_noon(state)
	_on_date(state, season * GameData.SEASON_DAYS + 2)
	var ids := Farming.in_season(state)
	var cells := Farming.field_cells(state)
	state["plots"].clear()
	for i in cells.size():
		var id: StringName = ids[(i / 15) % ids.size()]
		SuiteKit.crop_supplies(state, id)
		Farming.select_seed(state, id)
		Farming.act(state, cells[i])
		Farming.act(state, cells[i])
		Farming.plot(state, cells[i])["growth"] = Farming.days_to_grow(id)
		Farming.plot(state, cells[i])["watered"] = true
	Farming.select_seed(state, ids[0])


func _set_spring_field(state: Dictionary) -> void:
	_set_season_field(state, 0)


## **A season's crops at night** (task 0198): its ripe field on the beds, as
## `_set_season_field` sows it, on that date's night with the waves held off.
func _set_field_night(state: Dictionary, season: int) -> void:
	_set_season_field(state, season)
	_camera_at = _standing_at
	NightRoad.to_night(state)
	NightRoad.park(state)
	Sim.advance(state, 1)


func _set_spring_field_night(state: Dictionary) -> void:
	_set_field_night(state, 0)


func _set_summer_field_night(state: Dictionary) -> void:
	_set_field_night(state, 1)


## **Summer's regrowth** (task 0199): the ripe summer field with every other
## ripe pepper and corn plot picked, regrowing beside the ones still ripe.
func _set_summer_regrowing(state: Dictionary) -> void:
	_set_summer_field(state)
	var seen := 0
	for cell in Farming.field_cells(state):
		if Farming.crop_on(state, cell) in [GameData.PEPPER, GameData.CORN] and Farming.is_ready(state, cell):
			if seen % 2 == 0:
				Farming.act(state, cell)
			seen += 1


func _set_summer_field(state: Dictionary) -> void:
	_set_season_field(state, 1)


func _set_withered(state: Dictionary) -> void:
	_set_summer_field(state)
	Farming.dry_out(state)
	_on_date(state, 2 * GameData.SEASON_DAYS + 1)
	Farming.morning(state)


## **A014's overlays at night** (task 0197): Autumn 1's withered field on its
## night, the waves held off, and three of its plots trampled as a lost night
## leaves them - both overlays under the night's light.
func _set_withered_night(state: Dictionary) -> void:
	_set_withered(state)
	var withered: Array = []
	for cell in Farming.field_cells(state):
		if Farming.plot(state, cell).has("withered"):
			withered.append(cell)
	for cell in withered.slice(0, 3):
		var here := Farming.plot(state, cell)
		here["trampled"] = here["withered"]
		here.erase("withered")
	_camera_at = _standing_at
	NightRoad.to_night(state)
	NightRoad.park(state)
	Sim.advance(state, 1)


func _set_winter_day(state: Dictionary) -> void:
	_set_season_field(state, 2)
	Farming.dry_out(state)
	_on_date(state, 3 * GameData.SEASON_DAYS + 1)
	Farming.morning(state)


func _set_regrowing(state: Dictionary) -> void:
	_set_spring_field(state)
	var cells := Farming.field_cells(state)
	for i in cells.size():
		var here := Farming.plot(state, cells[i])
		here["crop"] = GameData.STRAWBERRY
		here["growth"] = Farming.days_to_grow(GameData.STRAWBERRY)
		if i % 6 < 3:
			Farming.act(state, cells[i])
	Farming.select_seed(state, GameData.STRAWBERRY)


## A real paid axe, delivered at dawn; the can has finished and waits for tomorrow.
func _set_tool_upgrades(state: Dictionary) -> void:
	_set_noon(state)
	state["held"][GameData.MONEY] = 1000
	state["held"][GameData.IRON] = 100
	var bench: Vector2i = Farm.cells_with(state, &"workshop")[0]
	Crafting.enqueue(state, bench, &"upgrade_axe_iron")
	Sim.advance(state, int(GameData.RECIPES[&"upgrade_axe_iron"]["ticks"]) + 1)
	Phases.go_to_bed(state)
	Phases.start_waves(state)
	Phases.enter_result(state, false)
	Phases.begin_day(state)
	House.leave(state)
	Sim.advance(state, Phases.tick_at_minute(WorldView.NOON_MINUTE))
	Crafting.enqueue(state, bench, &"upgrade_can_iron")
	Sim.advance(state, int(GameData.RECIPES[&"upgrade_can_iron"]["ticks"]) + 1)
	_standing_at = bench + Vector2i.UP
	state["player"]["facing"] = Player.SOUTH


## Freeze the real felling swing at contact, with the delivered iron axe.
func _take_tool_chop(main: Node, state: Dictionary, folder: String) -> void:
	var trees := Farm.cells_with(state, &"tree")
	var tree: Vector2i = trees[0]
	for candidate in trees:
		if (candidate as Vector2i).distance_squared_to(Farm.house_centre(state) + Vector2i(7, 7)) < tree.distance_squared_to(Farm.house_centre(state) + Vector2i(7, 7)):
			tree = candidate
	var at := tree + Vector2i.RIGHT
	for nearby in Grid.within(at, 2):
		if nearby != tree and Farm.occupant(state, nearby).get("id", &"") == &"tree":
			Farm.remove(state, nearby)
	state["player"]["pos"] = [at.x * Player.SUBTILE + Player.SUBTILE / 2, at.y * Player.SUBTILE + Player.SUBTILE / 2]
	state["player"]["facing"] = Player.WEST
	state["intent"]["interact"] = true
	Sim.advance(state, 1)
	var view := main.get_node("%WorldView") as WorldView
	view.look_at_cell(at)
	view.show_state(state)
	var farmer := view.get_node("Occupants/PlayerView") as PlayerView
	farmer.show_state(state)
	if not state["player"]["action"].is_empty():
		while Gathering.swings_left(state, tree) > 1:
			Sim.advance(state, int(state["player"]["action"]["left"]))
		Sim.advance(state, int(state["player"]["action"]["left"]) - 1)
		farmer.before_tick(state)
		Sim.advance(state, 1)
		farmer.after_tick(state)
	farmer._process(0.0)
	await process_frame
	await process_frame
	await _shoot("tool_upgrades_chop", folder)
	print("  tool_upgrades_chop: %s, tier %d" % [farmer._playing, ToolTiers.tier(state, &"axe")])


## 0176 - the existing quarry, in daylight, its material ledger, and night.
func _set_quarry(state: Dictionary) -> void:
	_on_date(state, GameData.SEASON_DAYS * 2 + 1)
	state["tools"]["pickaxe"] = 1
	state["held"][GameData.COPPER] = 12
	state["held"][GameData.COAL] = 8
	state["held"][GameData.GOLD] = 5
	_standing_at = Vector2i(66, 3)
	_stand(state, _standing_at)


func _take_quarry_extras(main: Node, state: Dictionary, folder: String) -> void:
	_only_showing(main, "InventoryPanel")
	(main.get_node("%InventoryPanel") as InventoryPanel).select_group(&"materials")
	await process_frame
	await process_frame
	await _shoot("quarry_materials", folder)
	_only_showing(main, "")
	# Autumn 1 is calm and settles immediately; show the following night.
	_on_date(state, GameData.SEASON_DAYS * 2 + 2)
	NightRoad.to_night(state)
	main.aim_night_camera((Vector2(_standing_at) + Vector2.ONE * 0.5) * float(GameData.TILE_SIZE))
	var view := main.get_node("%WorldView") as WorldView
	view.show_state(state)
	# Let the views notice bedtime before skipping its beat, as _take does.
	await process_frame
	await process_frame
	(main.get_node("HouseView") as HouseView).skip_bedtime()
	view.skip_transition()
	view._light_for_phase(0.0)
	await process_frame
	await _shoot("quarry_night", folder)
