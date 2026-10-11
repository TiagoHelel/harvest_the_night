extends SceneTree

## The worst case, timed, in numbers a tool can compare.
##
## Run by `python tools/perf.py`. Prints one machine-readable line per
## measurement and nothing else that looks like one:
##
##     PERF <name> <microseconds>
##     COUNT <name> <n>
##
## `tools/perf.py` compares each `PERF` against `tools/perf_baseline.txt` and
## fails when one has grown past its tolerance. Moving a baseline is
## `python tools/perf.py --accept`, which prints the old and the new number
## the way the determinism guard does.
##
## ## The worst case is night ten with everything built
##
## Not a typical farm: every soil tile planted, every buildable cell on the
## east half towered, a generator, and the last night of the run - which is
## the biggest wave the table sends. If it fits here it fits everywhere.
##
## ## Each system is timed on its own copy of the same state
##
## **So that the numbers are comparable and one of them can be blamed.** The
## systems tick in an order and each leaves the state different for the next,
## so timing them in sequence measures the order as much as the work. Every
## measurement below starts from a deep copy of one state, which costs a copy
## per system and buys a table that can be read down the middle column.
##
## ## What cannot be measured here, and is said so rather than faked
##
## Lights and particles are `src/ui/`. A headless run has the dummy renderer:
## nothing is rasterised, so "how long does it take to draw four hundred
## sparks" is not a question this can answer. What it *can* answer is the
## per-frame **logic** those systems run - deciding which lamps are lit,
## advancing and retiring particles - and that is what is timed. The drawing
## itself is the debug overlay's number, on a machine with a screen.

## How many ticks each timing runs for. Long enough that the clock's own
## resolution is noise, short enough that the whole thing is a second or two.
const TICKS := 600

## How many towers the worst case has on it. **More than anybody builds**,
## and few enough that night ten is still being fought while it is timed.
const TOWERS := 40

## Their hit points: more than any night takes off them (task 0157).
const TOWER_HP := 1000000

## And how many times a one-off - a path rebuild - is repeated.
const REPEATS := 40

## **The swarm** (task 0218): how many bodies more the worst case gets, on
## open ground round its towers - rats since task 0248, whose stand-in the
## walkers were.
const SWARM := 300

## How far round the towers' band they stand, in cells: inside some tower's
## reach, or a few steps from it.
const SWARM_MARGIN := 6

## **Four decoys in the swarm** (task 0224), spread over the ground it stands
## on, so the lure is built and asked by every rat on every tick it times.
## Hit points nothing bites through while it is timed, as the guns have: this
## measures what the lure costs, not how long straw lasts.
const DECOYS := 4
const DECOY_HP := 1000000

## **Ten garlic braids** (task 0228) over the same ground, for the rebuild with
## their areas in the entry costs: `garlic_refresh`, held to the path's budget.
const GARLIC_BRAIDS := 10

## How many ticks the swarm's whole tick is averaged over. Ten seconds: long
## enough to time, and short enough that the guns have not thinned it out.
const SWARM_TICKS := 300

## How many calls a single system gets before the state is copied again.
##
## **A system ticked on its own goes somewhere the game never goes.** Six
## hundred calls of `Waves.tick` with nothing else running ends the night and
## then keeps ending it, which is an error log rather than a measurement. One
## second's worth at a time is long enough to time and short enough that the
## state is still a state.
const BLOCK := 30

const WATCHDOG_SECONDS := 60.0

## The two lists live in `PerfNames`, because `headless_check.gd` checks them
## against what `Sim.tick()` actually calls and a list in two files is a list
## that disagrees with itself.
const NIGHT_SYSTEMS: Array = PerfNames.NIGHT
const DAY_SYSTEMS: Array = PerfNames.DAY

var _elapsed := 0.0
var _done := false


func _initialize() -> void:
	_run()
	_done = true
	quit(0)


func _process(delta: float) -> bool:
	_elapsed += delta
	if _elapsed < WATCHDOG_SECONDS or _done:
		return _done
	push_error("perf_check: watchdog fired after %.0fs" % _elapsed)
	return true


func _run() -> void:
	var night := _the_worst_case()
	print("COUNT towers ", Farm.cells_with(night, &"gun_tower").size())
	print("COUNT crops ", int(Farming.counts(night)["planted"]))
	print("COUNT zombies ", Entities.count(night))
	print("COUNT walls ", Farm.cells_with(night, &"wall").size()
		+ Farm.cells_with(night, &"fence").size())

	# **The whole tick, which is the number the budget is about.**
	print("PERF night_tick ", _per_tick(night))
	var day := _a_busy_day()
	print("PERF day_tick ", _per_tick(day))

	# Then each system on its own, so a regression points at itself.
	for named in NIGHT_SYSTEMS:
		print("PERF night_%s " % String(named).to_lower(),
			_system(night, named))
	for named in DAY_SYSTEMS:
		print("PERF day_%s " % String(named).to_lower(), _system(day, named))

	# **The swarm** (task 0218): the same night with a few hundred bodies
	# more at the towers, which is what the decoy, the bait, the digger and the
	# rat swarm are about to ask of it - the decoy in it since task 0224. Its
	# own lines, because the night's must stay comparable with every baseline
	# before them.
	var swarm := _the_swarm(night)
	print("COUNT swarm ", Entities.count(swarm))
	print("COUNT decoys ", Pathing.lure_cells(swarm).size())
	print("PERF swarm_tick ", _per_tick(swarm, SWARM_TICKS))
	print("PERF swarm_towers ", _system(swarm, &"Towers"))
	print("PERF swarm_enemies ", _system(swarm, &"Enemies"))

	# **The path field, which is the one thing that is not per tick.** It is
	# rebuilt when the walls change, and a player in build mode changes them
	# once a click.
	print("PERF path_refresh ", _path(night))
	# **And with four decoys standing** (task 0224): the same rebuild, and the
	# lure beside it the way a night asks for it.
	print("PERF lure_refresh ", _lure_path(swarm))
	# **And the digger's** (task 0250): the same rebuild with the burrow field
	# swept beside the fields every night walks by, the way the first digger
	# to ask builds it - on the worst case's wall line with every other wall
	# a fence, so it has barriers to go under and barriers it cannot.
	var dug := _with_fences(night)
	print("COUNT burrow_fences ", Farm.cells_with(dug, &"fence").size())
	print("PERF burrow_refresh ", _burrow_path(dug))
	# **And with ten garlic braids hung** (task 0228): their areas are part of
	# the entry costs every field is swept against.
	var garlic := _with_garlic(night)
	print("COUNT garlic ", Farm.cells_with(garlic, &"garlic_braid").size())
	print("PERF garlic_refresh ", _path(garlic))

	# And the view's per-frame thinking, which is not its drawing. Two
	# numbers rather than one: a total cannot say which of them grew.
	var seen := _view(night)
	print("PERF view_lighting ", int(seen[0]))
	print("PERF view_particles ", int(seen[1]))
	# **And a rainy night at four times speed** (task 0258): the emitter's
	# per-frame thinking with the rain over the same fight, four ticks of it
	# between frames. Its own line, so the two above stay comparable.
	print("PERF view_rain ", _view_rain(night))


## Night ten, everything built, the biggest wave the table sends.
func _the_worst_case() -> Dictionary:
	var state := State.create(102102)
	Resources.gain(state, {GameData.WOOD: 8000, GameData.STONE: 8000,
		GameData.IRON: 8000, GameData.OIL: 800, GameData.GUNPOWDER: 800,
		GameData.INCENDIARY: 800, GameData.CORN: 800, GameData.MONEY: 8000})

	var seeds := Farming.seeds()
	var sown := 0
	for found in Farming.field_cells(state):
		SuiteKit.crop_supplies(state, StringName(seeds[sown % seeds.size()]))
		Farming.select_seed(state, StringName(seeds[sown % seeds.size()]))
		Farming.act(state, found)
		Farming.act(state, found)
		sown += 1

	# **Towers a player would actually have**, not a wall of them. Filling
	# the east half put two hundred and seventeen guns down, which killed
	# night ten before it walked ten tiles - a worst case with nothing in it
	# is not a worst case. Forty is more than anybody builds and still
	# leaves a fight to time.
	# **On the farmstead, where the fight is**: the old yard's band, moved
	# with the farmstead to the middle of the farm (24 east, 18 south,
	# 2026-10-06). A row-by-row fill of the whole farm puts guns where nothing
	# walks, and forty towers with nothing to shoot is a quieter night, not a
	# worse one. The wall line stands on the house's east side, as it did.
	# The generator is a day job and goes up first; the towers and the wall
	# go up in the build step (task 0119).
	var gen := _room_for(state, Building.size_of(&"generator"))
	if gen != Vector2i(-1, -1):
		Building.place(state, &"generator", gen)
	NightRoad.to_build(state)
	var moved := GameData.PLAYER_START - Vector2i(16, 8)
	var guns := 0
	for y in range(1 + moved.y, Grid.HEIGHT - 1):
		for x in range(21 + moved.x, mini(Grid.WIDTH, Save.V3_FARM.x + moved.x) - 1):
			if guns >= TOWERS:
				break
			if Building.place(state, &"gun_tower", Vector2i(x, y)):
				guns += 1
	# **Guns that stay up** (task 0157). Spring opens the east alone now, so
	# Spring 14's forty-two breakers and thirty-one tanks walk into this band
	# instead of coming from the south east, and by the busiest moment every
	# tower was rubble: a night tick of 433 us against 2265, `night_towers` at
	# 2. This measures what a night costs, not whether the farm holds it, so
	# the guns here take no lasting harm.
	for cell in Farm.cells_with(state, &"gun_tower"):
		Farm.occupant(state, cell)["hp"] = TOWER_HP
	for y in range(1, Grid.HEIGHT - 1):
		Building.place(state, &"wall", Vector2i(19 + moved.x, y))

	# **The night is the calendar day's** since task 0151 - `Phases.begin_night`
	# numbers it with `Calendar.date` - so the day picks the boss's night:
	# Spring 14 since task 0153, a Full Moon with the Giant in company. 0275
	# moves it to Winter 14.
	state["day"] = GameData.SEASON_DAYS
	state["nights_won"] = GameData.SEASON_DAYS - 1
	NightRoad.to_night(state)

	# **Stopped at the busiest moment, not at a fixed tick.** Advance until
	# the field is as full as it gets, then stop - a fixed number of ticks
	# lands somewhere different every time the wave table moves.
	var busiest := 0
	var peak: Dictionary = state.duplicate(true)
	for _i in 160:
		Sim.advance(state, 15)
		var many := Entities.count(state)
		if many > busiest:
			busiest = many
			peak = state.duplicate(true)
		if int(state["phase"]) != Phases.NIGHT:
			break
	return peak


## **The worst case and `SWARM` rats more** (tasks 0218 and 0248), spread
## over the open cells within `SWARM_MARGIN` of the towers' band - every cell
## nothing stands on that the house can be reached from, in reading order, and
## round again when there are fewer cells than rats. **`DECOYS` go down first**
## (task 0224), evenly along that ground, and the rats round them.
func _the_swarm(night: Dictionary) -> Dictionary:
	var state: Dictionary = night.duplicate(true)
	var lo := Vector2i(Grid.WIDTH, Grid.HEIGHT)
	var hi := Vector2i(-1, -1)
	for cell in Towers.cells(state):
		lo = Vector2i(mini(lo.x, cell.x), mini(lo.y, cell.y))
		hi = Vector2i(maxi(hi.x, cell.x), maxi(hi.y, cell.y))
	var open := _open_round(state, lo, hi)
	if open.is_empty():
		push_error("perf_check: no open ground round the towers for the swarm")
		return state
	Resources.gain(state, {GameData.STRAW: 100, GameData.WOOD: 100})
	# **Summer's straw on Spring 14's night** (task 0234): the calendar opened
	# for the placing and put back, so the night measured is still the boss's.
	var day := int(state["day"])
	SuiteKit.open_arsenal(state, [&"decoy"])
	for k in DECOYS:
		var spot: Vector2i = open[open.size() * (k + 1) / (DECOYS + 1)]
		if Building.place(state, &"decoy", spot):
			Farm.occupant(state, spot)["hp"] = DECOY_HP
	state["day"] = day
	# The lure built with the fields every night walks by, as they are: what
	# a rebuild costs is `lure_refresh`'s line, not the swarm's first tick.
	Pathing.refresh(state)
	Pathing.field(state, &"lure")
	open = _open_round(state, lo, hi)
	# **Rats** (task 0248): the swarm 0218 was built for, a few hundred small
	# fast bodies that a gun tower spends a whole shot on each.
	for i in SWARM:
		Entities.spawn(state, &"rat", open[i % open.size()])
	return state


## **The worst case with `GARLIC_BRAIDS` braids hung** (task 0228), evenly
## along the open ground round the towers' band, fresh.
func _with_garlic(night: Dictionary) -> Dictionary:
	var state: Dictionary = night.duplicate(true)
	var lo := Vector2i(Grid.WIDTH, Grid.HEIGHT)
	var hi := Vector2i(-1, -1)
	for cell in Towers.cells(state):
		lo = Vector2i(mini(lo.x, cell.x), mini(lo.y, cell.y))
		hi = Vector2i(maxi(hi.x, cell.x), maxi(hi.y, cell.y))
	var open := _open_round(state, lo, hi)
	Resources.gain(state, {GameData.GARLIC: 200, GameData.WOOD: 100})
	# Autumn's braids on Spring 14's night, as the swarm's straw (task 0234).
	var day := int(state["day"])
	SuiteKit.open_arsenal(state, [&"garlic_braid"])
	for k in GARLIC_BRAIDS:
		if not open.is_empty():
			Building.place(state, &"garlic_braid", open[open.size() * (k + 1) / (GARLIC_BRAIDS + 1)])
	state["day"] = day
	return state


## The cells within `SWARM_MARGIN` of a band that nothing stands on and the
## house can be reached from, in reading order.
func _open_round(state: Dictionary, lo: Vector2i, hi: Vector2i) -> Array:
	var open: Array = []
	for y in range(maxi(lo.y - SWARM_MARGIN, 0), mini(hi.y + SWARM_MARGIN + 1, Grid.HEIGHT)):
		for x in range(maxi(lo.x - SWARM_MARGIN, 0), mini(hi.x + SWARM_MARGIN + 1, Grid.WIDTH)):
			var cell := Vector2i(x, y)
			if Farm.occupant(state, cell).is_empty() and Pathing.reachable(state, cell):
				open.append(cell)
	return open


## A day with as much going on as a day gets.
func _a_busy_day() -> Dictionary:
	var state := State.create(102103)
	Resources.gain(state, {GameData.WOOD: 8000, GameData.STONE: 8000,
		GameData.IRON: 8000, GameData.CORN: 800})
	var seeds := Farming.seeds()
	var sown := 0
	for found in Farming.field_cells(state):
		SuiteKit.crop_supplies(state, StringName(seeds[sown % seeds.size()]))
		Farming.select_seed(state, StringName(seeds[sown % seeds.size()]))
		Farming.act(state, found)
		Farming.act(state, found)
		sown += 1
	var bench := Building.anchor_of(state,
		Farm.cells_with(state, &"workshop")[0])
	for _i in GameData.QUEUE_LENGTH:
		Crafting.enqueue(state, bench, &"barricade_kit")
	Sim.advance(state, 60)
	return state


## Microseconds per whole tick, averaged - **over the ticks still in the phase
## it started in**. Spring 14's night (task 0153) is over, everything dead,
## inside the 600 ticks after its busiest moment, and an average that ran on
## into the morning reported a night tick of 36 us against the towers' 1435:
## a number about the result screen, under the night's name.
func _per_tick(state: Dictionary, most: int = TICKS) -> int:
	var mine: Dictionary = state.duplicate(true)
	var phase := int(mine["phase"])
	var ticks := 0
	var started := Time.get_ticks_usec()
	while ticks < most and int(mine["phase"]) == phase:
		Sim.advance(mine, 1)
		ticks += 1
	return int(round(float(Time.get_ticks_usec() - started) / float(maxi(ticks, 1))))


## Microseconds per call of one system's `tick`, on its own copy.
func _system(state: Dictionary, named: StringName) -> int:
	var blocks := maxi(TICKS / BLOCK, 1)
	var spent := 0
	for _b in blocks:
		# **The copy is not timed.** It is how the measurement stays honest,
		# not part of what is being measured.
		var mine: Dictionary = state.duplicate(true)
		var started := Time.get_ticks_usec()
		for _i in BLOCK:
			mine["tick"] = int(mine["tick"]) + 1
			_tick_one(mine, named)
		spent += Time.get_ticks_usec() - started
	return int(round(float(spent) / float(blocks * BLOCK)))


## The one place that maps a name onto a system, so `NIGHT_SYSTEMS` can be a
## list of names and a typo is a missing row rather than a wrong number.
func _tick_one(state: Dictionary, named: StringName) -> void:
	match named:
		&"Power": Power.tick(state)
		&"Waves": Waves.tick(state)
		&"Ability": Ability.tick(state)
		&"Enemies": Enemies.tick(state)
		&"Traps": Traps.tick(state)
		&"Towers": Towers.tick(state)
		&"Combat": Combat.tick(state)
		&"Building": Building.tick(state)
		&"Player": Player.tick(state)
		&"Gathering": Gathering.tick(state)
		&"Livestock": Livestock.tick(state)
		&"Tutorial": Tutorial.tick(state)
		&"Crafting": Crafting.tick(state)
		&"Reactions": Reactions.tick(state)
		_: push_error("perf_check: no system called '%s'" % named)


## Microseconds per rebuild of the path field.
func _path(state: Dictionary) -> int:
	var mine: Dictionary = state.duplicate(true)
	var started := Time.get_ticks_usec()
	for _i in REPEATS:
		mine["grid_version"] = int(mine["grid_version"]) + 1
		Pathing.refresh(mine)
	return int(round(float(Time.get_ticks_usec() - started) / float(REPEATS)))


## **Microseconds per rebuild with the lure in it** (task 0224): the fields
## every night walks by and the lure swept from the decoys standing, asked the
## way `Enemies.tick` asks for it.
func _lure_path(state: Dictionary) -> int:
	var mine: Dictionary = state.duplicate(true)
	var started := Time.get_ticks_usec()
	for _i in REPEATS:
		mine["grid_version"] = int(mine["grid_version"]) + 1
		Pathing.refresh(mine)
		Pathing.field(mine, &"lure")
	return int(round(float(Time.get_ticks_usec() - started) / float(REPEATS)))


## **The worst case with every other wall of its line a fence** (task 0250),
## in reading order: the walls and fences the digger's case is measured on.
func _with_fences(night: Dictionary) -> Dictionary:
	var state: Dictionary = night.duplicate(true)
	var walls := Farm.cells_with(state, &"wall")
	var hp := int((GameData.DEFENCES[&"fence"] as Dictionary)["hp"])
	for i in range(1, walls.size(), 2):
		var cell: Vector2i = walls[i]
		if Farm.remove(state, cell):
			Farm.place(state, cell, {"id": &"fence", "hp": hp})
	return state


## **Microseconds per rebuild with the burrow field in it** (task 0250): the
## fields every night walks by and the digger's, asked the way `Enemies.tick`
## asks for it.
func _burrow_path(state: Dictionary) -> int:
	var mine: Dictionary = state.duplicate(true)
	var started := Time.get_ticks_usec()
	for _i in REPEATS:
		mine["grid_version"] = int(mine["grid_version"]) + 1
		Pathing.refresh(mine)
		Pathing.field(mine, &"burrow")
	return int(round(float(Time.get_ticks_usec() - started) / float(REPEATS)))


## Microseconds per frame of the view's thinking - not its drawing.
##
## The lamps decide which of them are lit and the emitters advance and retire
## what is in the air. Both are per-frame CPU on a real machine and neither
## needs a pixel, which is why they can be timed here at all.
func _view(state: Dictionary) -> Array:
	var lighting := Lighting.new()
	var particles := Particles.new()
	root.add_child(lighting)
	root.add_child(particles)
	# **`_ready` by hand, because nothing here reaches a frame.** A node
	# added to `root` during `_initialize()` never gets one, and the
	# emitter sizes its pools in `_ready` - so every burst wrote past the
	# end of a zero-length array, and what the first version of this timed
	# was Godot printing an error. Half a second a frame, for a loop that
	# costs microseconds.
	lighting._ready()
	particles._ready()
	lighting.show_state(state)
	particles.show_state(state)

	var started := Time.get_ticks_usec()
	for _i in TICKS:
		lighting._process(1.0 / 60.0)
	var lit := float(Time.get_ticks_usec() - started) / float(TICKS)

	started = Time.get_ticks_usec()
	for _i in TICKS:
		particles._process(1.0 / 60.0)
	var sparks := float(Time.get_ticks_usec() - started) / float(TICKS)

	root.remove_child(lighting)
	root.remove_child(particles)
	lighting.free()
	particles.free()
	return [int(round(lit)), int(round(sparks))]


## Microseconds per frame of the emitter's thinking on a rainy night at four
## times speed (task 0258): a copy of the worst case's night, its night moved
## to the first of its run that `Weather` makes rainy - found, never forced -
## and four ticks between frames. Only the frames are timed.
func _view_rain(state: Dictionary) -> int:
	var wet := state.duplicate(true)
	var date := 2
	while date < 10 * Calendar.year_days() and Weather.event(int(wet["seed"]), date) != Weather.RAIN:
		date += 1
	wet["night"] = date
	var particles := Particles.new()
	root.add_child(particles)
	particles._ready()
	particles.show_state(wet)
	var spent := 0
	for _i in TICKS:
		for _t in 4:
			Sim.tick(wet)
		var started := Time.get_ticks_usec()
		particles._process(1.0 / 60.0)
		spent += Time.get_ticks_usec() - started
	print("COUNT raindrops ", particles.raindrops())
	root.remove_child(particles)
	particles.free()
	return int(round(float(spent) / float(TICKS)))


## Somewhere a building of this size fits, or (-1, -1).
func _room_for(state: Dictionary, size: Vector2i) -> Vector2i:
	for y in range(1, Grid.HEIGHT - size.y):
		for x in range(1, 18):
			var where := Vector2i(x, y)
			if Building.why_not(state, &"generator", where).is_empty():
				return where
	return Vector2i(-1, -1)
