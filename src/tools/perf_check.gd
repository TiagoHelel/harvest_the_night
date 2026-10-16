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
## ## The worst case is Winter 14 with everything built (task 0275)
##
## The heaviest night 1.0 makes: the year's last, the Winter Lord in the
## company of every kind on every side, on a seed whose weather gives it fog.
## Against it, the forty guns of the old case and **one of every defence** -
## each at the top level its family has, powered and loaded, put down in the
## build step where the fight is. If it fits here it fits everywhere. Until
## task 0275 it was Spring 14, where 0153 had moved the MVP's night ten.
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

## How many gun towers the worst case has on it, besides one of every other
## defence. **More than anybody builds**, and few enough that the night is
## still being fought while it is timed.
const TOWERS := 40

## Their hit points, and every other defence's that is not a barrier: more
## than any night takes off them (task 0157). Barriers keep their own, so a
## wall still costs a crowd something to chew.
const TOWER_HP := 1000000

## And how many times a one-off - a path rebuild - is repeated.
const REPEATS := 40

## **The swarm** (task 0218): how many bodies more the worst case gets, on
## open ground round its towers - rats since task 0248, whose stand-in the
## walkers were. **Its own rows since task 0275**, on the winter case: the
## night's must stay the night the calendar sends.
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

## **The first seed tried for the winter case** (task 0275): the run is the
## first from here whose Winter 14 `Weather` gives fog - the heaviest event
## that night can have, since 0257 keeps the Blood Moon off a boss's night
## and winter has no rain. Found, never forced.
const FIRST_SEED := 102102

## How far past `FIRST_SEED` it looks before it settles for a clear night.
const SEEDS_TRIED := 4000

## **The 1.0 day's stations** (task 0275): every one a recipe names, each
## with a queue.
const STATIONS: Array = [&"workshop", &"press", &"kitchen", &"keg",
	&"preserves_jar", &"dairy", &"loom", &"mill"]

## And its sprinklers, one of each.
const SPRINKLERS: Array = [&"copper_sprinkler", &"iron_sprinkler", &"gold_sprinkler"]

## How many cells of grass the 1.0 day tills round its fields.
const TILLED := 40

const WATCHDOG_SECONDS := 60.0

## The two lists live in `PerfNames`, because `headless_check.gd` checks them
## against what `Sim.tick()` actually calls and a list in two files is a list
## that disagrees with itself.
const NIGHT_SYSTEMS: Array = PerfNames.NIGHT
const DAY_SYSTEMS: Array = PerfNames.DAY

var _elapsed := 0.0
var _done := false

## The busiest moment and the night's first tick, kept for the rows the first
## frame times (task 0275).
var _night: Dictionary = {}
var _start: Dictionary = {}
## **The date the case is armed on** (task 0279): Winter 14 of Year 1 unless
## `--date=<n>` names another - Year 3's heaviest night, say. `tools/perf.py
## --date` forwards it, and compares and accepts nothing on such a run.
var _date := Calendar.year_days()


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if String(arg).begins_with("--date="):
			_date = maxi(int(String(arg).trim_prefix("--date=")), 1)
	print("COUNT date ", _date)
	_run()


## **The view's rows on the first frame** (task 0275): a node added to `root`
## in `_initialize()` is not inside the tree yet, so `_ready` never came and
## every frame of the emitter asked a viewport it had none of - six hundred
## errors a run, timed as the rain's cost since task 0258. On the first frame
## the tree is up and the nodes are the game's own.
func _process(delta: float) -> bool:
	if not _done:
		_done = true
		_view_rows()
		quit(0)
		return true
	_elapsed += delta
	if _elapsed < WATCHDOG_SECONDS:
		return false
	push_error("perf_check: watchdog fired after %.0fs" % _elapsed)
	return true


func _run() -> void:
	_start = _the_winter_farm()
	_night = _the_worst_case(_start)
	_counts(_start, _night)
	var night := _night
	var start := _start

	# **The whole tick, which is the number the budget is about.**
	print("PERF night_tick ", _per_tick(night))
	var day := _a_busy_day()
	_day_counts(day)
	print("PERF day_tick ", _per_tick(day))

	# Then each system on its own, so a regression points at itself.
	for named in NIGHT_SYSTEMS:
		print("PERF night_%s " % String(named).to_lower(),
			_system(night, named))
	for named in DAY_SYSTEMS:
		print("PERF day_%s " % String(named).to_lower(), _system(day, named))

	# **The swarm** (task 0218): the same night with a few hundred bodies
	# more at the towers, which is what the decoy, the bait, the digger and the
	# rat swarm ask of it - the decoy in it since task 0224. Its own lines,
	# because the night's must stay the night the calendar sends.
	var swarm := _the_swarm(night)
	print("COUNT swarm ", Entities.count(swarm))
	print("COUNT swarm_rats ", int(_up_by_kind(swarm).get(&"rat", 0)))
	print("COUNT decoys ", Pathing.lure_cells(swarm).size())
	print("PERF swarm_tick ", _per_tick(swarm, SWARM_TICKS))
	print("PERF swarm_towers ", _system(swarm, &"Towers"))
	print("PERF swarm_enemies ", _system(swarm, &"Enemies"))

	# **The path fields, which are the one thing that is not per tick.** They
	# are rebuilt when the walls change, and a player in build mode changes
	# them once a click: **every field in `Pathing.FIELDS`** (task 0275), the
	# three every night walks by and every one a night builds when asked.
	print("PERF path_refresh ", _path(night))
	# **And with four decoys more** (task 0224): the rebuild and the lure
	# beside it the way a night asks for it.
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

	# **One winter night, end to end** (task 0275): not budgeted - a night is
	# not a tick - but what 0277's sweep multiplies by thousands.
	print("COUNT winter_night_ms ", _whole_night(start))


## The view's per-frame thinking, which is not its drawing - on the first
## frame, inside the tree (task 0275).
func _view_rows() -> void:
	# Two numbers rather than one: a total cannot say which of them grew.
	var seen := _view(_night)
	print("PERF view_lighting ", int(seen[0]))
	print("PERF view_particles ", int(seen[1]))
	# **And a rainy night at four times speed** (task 0258): the emitter's
	# per-frame thinking with the rain over the same fight, four ticks of it
	# between frames. Its own line, so the two above stay comparable.
	print("PERF view_rain ", _view_rain(_night))


## **What the case is** (task 0275), so a reader can see it is the case: the
## date and its weather; every defence family on the farm as it was armed,
## at the night's first tick - a mine or a bait is spent by the busiest
## moment - and how many stand at their family's top level; every kind
## tonight sends and how many are up at the busiest moment, the boss, the
## power, and every path field the night has built.
func _counts(start: Dictionary, night: Dictionary) -> void:
	var date := Calendar.date(night)
	print("COUNT date ", date)
	print("COUNT fog ", 1 if Weather.tonight(night) == Weather.FOG else 0)
	var top := 0
	var all := 0
	for id in GameData.sorted_names(GameData.DEFENCES.keys()):
		var cells := Farm.cells_with(start, StringName(id))
		print("COUNT defence_%s %d" % [id, cells.size()])
		for cell in cells:
			all += 1
			if Building.level_at(start, cell) >= _top_level(StringName(id)):
				top += 1
	print("COUNT defences ", all)
	print("COUNT at_top_level ", top)
	var up := _up_by_kind(night)
	var sent := Waves.kinds_of(date, int(night["seed"]))
	for kind in GameData.sorted_names(GameData.ENEMIES.keys()):
		if sent.has(kind) or up.has(kind):
			print("COUNT enemy_%s %d" % [kind, int(up.get(kind, 0))])
	print("COUNT boss ", int(up.get(Calendar.boss_of(date), 0)))
	print("COUNT zombies ", Entities.count(night))
	print("COUNT power_percent ", Power.percent(night))
	for name in GameData.sorted_names(Pathing.FIELDS.keys()):
		var key := String((Pathing.FIELDS[name] as Dictionary)["field"])
		var built := night.has(key) and (night[key] as PackedInt32Array).size() == Grid.CELLS
		print("COUNT field_%s %d" % [name, 1 if built else 0])


## The 1.0 day's own lines (task 0275): what it has on it.
func _day_counts(day: Dictionary) -> void:
	print("COUNT day_crops ", int(Farming.counts(day)["planted"]))
	var animals := 0
	for home in (day["housed"] as Dictionary).values():
		animals += ((home as Dictionary)["animals"] as Array).size()
	print("COUNT day_animals ", animals)
	var sprinklers := 0
	for id in SPRINKLERS:
		sprinklers += Farm.cells_with(day, StringName(id)).size()
	print("COUNT day_sprinklers ", sprinklers)
	var queued := 0
	for idx in (day["crafting"] as Dictionary).keys():
		queued += ((day["crafting"] as Dictionary)[idx]["queue"] as Array).size()
	print("COUNT day_queued ", queued)


## How many of each kind are up, by kind.
func _up_by_kind(state: Dictionary) -> Dictionary:
	var out := {}
	for one in (state["entities"] as Dictionary).values():
		var kind := StringName((one as Dictionary).get("kind", &""))
		out[kind] = int(out.get(kind, 0)) + 1
	return out


## The level a family stops at: `TOP_TOWER_LEVEL`, or one past its last row
## (task 0226), or one for a family with none.
func _top_level(id: StringName) -> int:
	return mini(GameData.TOP_TOWER_LEVEL, (GameData.TOWER_LEVELS.get(id, []) as Array).size() + 1)


## **The first seed whose night on the case's date is foggy** (task 0275;
## the date since task 0279), or `FIRST_SEED` with an error when none in
## `SEEDS_TRIED` is.
func _foggy_seed() -> int:
	for seed_value in range(FIRST_SEED, FIRST_SEED + SEEDS_TRIED):
		if Weather.event(seed_value, _date) == Weather.FOG:
			return seed_value
	push_error("perf_check: no seed from %d gives day %d fog" % [FIRST_SEED, _date])
	return FIRST_SEED


## **Winter 14's farm at the first tick of its night** (task 0275), armed the
## way a player arms one:
## - by day, the tree's nodes every level asks for, and enough generators
##   for everything that draws;
## - in the build step (task 0119), the forty guns and the wall line on the
##   farmstead, as the old case had them, and one of every other defence on
##   the free ground nearest the guns;
## - every defence taken to its family's top level, and loaded.
## The date is the calendar's (`Calendar.date`, task 0151): `day`, which every
## rule that asks for the date reads.
func _the_winter_farm() -> Dictionary:
	var state := State.create(_foggy_seed())
	var plenty := {}
	for res in GameData.RESOURCES:
		if res != GameData.ENERGY:
			plenty[res] = 9000
	Resources.gain(state, plenty)
	state["day"] = _date
	state["days_held"] = 0
	state["nights_won"] = _date - 1
	# **Carried on** (task 0279): a run past Year 1 chose to, at 0160's ending.
	state["endless"] = _date > Calendar.year_days()
	# A run this far in has its lessons behind it.
	var lessons: Array = []
	for step in Tutorial.steps():
		lessons.append(StringName((step as Dictionary)["id"]))
	((state["tutorial"] as Dictionary)["done"] as Array).assign(lessons)

	_buy_the_levels(state)
	# **Power by day** (task 0132): as many plants as the build will draw.
	var draw := TOWERS * _top_draw(&"gun_tower")
	for id in GameData.sorted_names(GameData.DEFENCES.keys()):
		if StringName(id) != &"gun_tower":
			draw += _top_draw(StringName(id))
	var output := int((GameData.BUILDINGS[&"generator"] as Dictionary)["energy_output"])
	var supply := GameData.BASE_ENERGY
	while supply < draw:
		var gen := _room_for(state, Building.size_of(&"generator"))
		if gen == Vector2i(-1, -1) or not Building.place(state, &"generator", gen):
			push_error("perf_check: no room for the generators %d draws" % draw)
			break
		supply += output

	NightRoad.to_build(state)
	# **Towers a player would actually have**, not a wall of them. Filling
	# the east half put two hundred and seventeen guns down, which killed
	# night ten before it walked ten tiles - a worst case with nothing in it
	# is not a worst case. Forty is more than anybody builds and still
	# leaves a fight to time.
	# **On the farmstead, where the fight is**: the old yard's band, moved
	# with the farmstead to the middle of the farm (24 east, 18 south,
	# 2026-10-06). The wall line stands on the house's east side, as it did.
	var moved := GameData.PLAYER_START - Vector2i(16, 8)
	var guns := 0
	for y in range(1 + moved.y, Grid.HEIGHT - 1):
		for x in range(21 + moved.x, mini(Grid.WIDTH, Save.V3_FARM.x + moved.x) - 1):
			if guns >= TOWERS:
				break
			if Building.place(state, &"gun_tower", Vector2i(x, y)):
				guns += 1
	for y in range(1, Grid.HEIGHT - 1):
		Building.place(state, &"wall", Vector2i(19 + moved.x, y))
	# **One of every other defence** (task 0275), on the free ground nearest
	# the middle of the guns: what shoots beside them, what is walked over on
	# the roads into them, what lures in front of them. A kit-only one comes
	# off the pile its station's morning would have left.
	for id in GameData.sorted_names(GameData.DEFENCES.keys()):
		if Building.kit_only(StringName(id)):
			Crafting.bank_kit(state, StringName(id))
	var nearest := _by_distance(_middle_of(Farm.cells_with(state, &"gun_tower")))
	_one_of_each(state, nearest)
	# **Every one at its family's top level**, paid for and through the tree,
	# in the build step where a level goes up.
	for id in GameData.sorted_names(GameData.DEFENCES.keys()):
		for cell in Farm.cells_with(state, StringName(id)):
			while Building.upgrade(state, cell):
				pass
	# **Guns that stay up** (task 0157), and every other defence that is not a
	# barrier: this measures what a night costs, not whether the farm holds
	# it. The plants too, which the breakers hunt.
	for id in GameData.sorted_names(GameData.DEFENCES.keys()):
		if (GameData.DEFENCES[id] as Dictionary).has("path_cost"):
			continue
		for cell in Farm.cells_with(state, StringName(id)):
			Farm.occupant(state, cell)["hp"] = TOWER_HP
	for cell in Farm.cells_with(state, &"generator"):
		Farm.occupant(state, cell)["hp"] = TOWER_HP

	NightRoad.to_night(state)
	# **What goes down only at night** - the bait is thrown, not built - on
	# the night's first tick.
	_one_of_each(state, nearest)
	# **And a house that does not fall** (task 0275): every side is open in
	# winter, and the forty guns stand on the east road, so the house went
	# down a minute in and the Winter Lord never came. As the guns, this
	# measures what the night costs, not whether the farm holds it.
	state["house_hp"] = TOWER_HP
	return state


## **One of every defence not yet on the farm** (task 0275), each on the
## first of `nearest` that will take it now.
func _one_of_each(state: Dictionary, nearest: Array) -> void:
	for id in GameData.sorted_names(GameData.DEFENCES.keys()):
		if not Farm.cells_with(state, StringName(id)).is_empty():
			continue
		for cell in nearest:
			if Building.can_place(state, StringName(id), cell) and Building.place(state, StringName(id), cell):
				break


## **Stopped at the busiest moment, not at a fixed tick**, of the night that
## starts at `start` - and **with the boss up** (task 0275): the most bodies
## on any tick the Winter Lord is on the field, or on any tick when he never
## is. A fixed number of ticks lands somewhere different every time the wave
## table moves.
func _the_worst_case(start: Dictionary) -> Dictionary:
	var state: Dictionary = start.duplicate(true)
	var boss := Calendar.boss_of(Calendar.date(state))
	var busiest := 0
	var with_boss := 0
	var peak: Dictionary = state.duplicate(true)
	for _i in GameData.NIGHT_TICKS / 15 + 1:
		Sim.advance(state, 15)
		if int(state["phase"]) != Phases.NIGHT:
			break
		var many := Entities.count(state)
		var up := _up_by_kind(state).has(boss)
		if up and many > with_boss:
			with_boss = many
			peak = state.duplicate(true)
		elif with_boss == 0 and many > busiest:
			busiest = many
			peak = state.duplicate(true)
	return peak


## **Milliseconds for one night, end to end** (task 0275): from the night's
## first tick to its result, every system in it, on its own copy.
func _whole_night(start: Dictionary) -> int:
	var mine: Dictionary = start.duplicate(true)
	var started := Time.get_ticks_msec()
	NightRoad.run_night(mine)
	return Time.get_ticks_msec() - started


## **The tree's nodes every level asks for** (task 0275), with what they
## need in turn, bought by day off the run's essence the way a player buys
## them - nothing written into the state by hand.
func _buy_the_levels(state: Dictionary) -> void:
	var wanted := {}
	for id in GameData.sorted_names(GameData.TOWER_LEVELS.keys()):
		for step in (GameData.TOWER_LEVELS[id] as Array):
			var needs := StringName((step as Dictionary).get("needs", &""))
			if needs != &"":
				wanted[needs] = true
	var grew := true
	while grew:
		grew = false
		for row in GameData.TECH_TREE:
			if wanted.has(StringName((row as Dictionary)["id"])):
				for needed in ((row as Dictionary)["needs"] as Array):
					if not wanted.has(StringName(needed)):
						wanted[StringName(needed)] = true
						grew = true
	for _pass in wanted.size():
		for row in GameData.TECH_TREE:
			var id := StringName((row as Dictionary)["id"])
			if wanted.has(id) and not Tech.owns(state, id):
				Tech.buy(state, id)


## What a defence draws at its family's top level.
func _top_draw(id: StringName) -> int:
	var draw := int((GameData.DEFENCES[id] as Dictionary).get("energy_draw", 0))
	var steps: Array = GameData.TOWER_LEVELS.get(id, [])
	for step in steps.slice(0, _top_level(id) - 1):
		draw = int(((step as Dictionary)["gives"] as Dictionary).get("energy_draw", draw))
	return draw


## The middle of some cells, or the farm's middle when there are none.
func _middle_of(cells: Array) -> Vector2i:
	if cells.is_empty():
		return Vector2i(Grid.WIDTH / 2, Grid.HEIGHT / 2)
	var sum := Vector2i.ZERO
	for cell in cells:
		sum += cell as Vector2i
	return Vector2i(sum.x / cells.size(), sum.y / cells.size())


## Every cell of the farm by how far it is from `want`, nearest first - ties
## in reading order.
func _by_distance(want: Vector2i) -> Array:
	var rings: Array = []
	for _i in Grid.WIDTH + Grid.HEIGHT:
		rings.append([])
	for y in Grid.HEIGHT:
		for x in Grid.WIDTH:
			var apart := absi(x - want.x) + absi(y - want.y)
			(rings[mini(apart, rings.size() - 1)] as Array).append(Vector2i(x, y))
	var out: Array = []
	for ring in rings:
		out.append_array(ring)
	return out


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
	# Winter has every season's arsenal open, so the straw needs no date.
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


## **The 1.0 day** (task 0275): Summer 3 with as much going on as a day gets
## - every field and `TILLED` cells of grass round them sown with summer's
## crops, a sprinkler of each kind on them, the barn and the coop full, and
## every station a recipe names with its queue full.
func _a_busy_day() -> Dictionary:
	var state := State.create(102103)
	var plenty := {}
	for res in GameData.RESOURCES:
		if res != GameData.ENERGY:
			plenty[res] = 9000
	Resources.gain(state, plenty)
	state["day"] = GameData.SEASON_DAYS + 3
	state["days_held"] = 0

	# **Tilled grass** (task 0167): the grass round the fields that a hoe
	# takes, nearest the fields first.
	var fields := Farming.field_cells(state)
	var round_fields := _by_distance(_middle_of(fields))
	var tilled := 0
	for cell in round_fields:
		if tilled >= TILLED:
			break
		if Farming.verb_at(state, cell) == &"till" and Farm.is_empty(state, cell):
			Farming.act(state, cell)
			tilled += 1
	# **The season's crops** on all of it: summer's, in turn.
	var crops := Farming.in_season(state)
	var sown := 0
	for cell in Farming.field_cells(state):
		var crop := StringName(crops[sown % crops.size()])
		SuiteKit.crop_supplies(state, crop)
		Farming.select_seed(state, crop)
		Farming.act(state, cell)
		Farming.act(state, cell)
		sown += 1
	# **A sprinkler of each kind** beside the fields.
	for id in SPRINKLERS:
		for cell in round_fields:
			if Building.can_place(state, StringName(id), cell) and Building.place(state, StringName(id), cell):
				break

	# **The barn and the coop on their site, full** (tasks 0183-0185).
	var room: Array = GameData.MAP_SITES[&"barn"]
	var site := Vector2i(int(room[0]), int(room[1]))
	var round_site := _by_distance(site)
	for home in [&"barn", &"coop"]:
		var at := Vector2i(-1, -1)
		for cell in round_site:
			if Building.can_place(state, home, cell) and Building.place(state, home, cell):
				at = cell
				break
		if at.x < 0:
			continue
		for kind in GameData.sorted_names(GameData.LIVESTOCK.keys()):
			if Livestock.home_of(StringName(kind)) != home:
				continue
			for _i in 4:
				Livestock.house(state, at, StringName(kind))

	# **Every station a recipe names, with its queue full** (task 0275).
	for station in STATIONS:
		if Farm.cells_with(state, station).is_empty():
			for cell in round_site:
				if Building.can_place(state, station, cell) and Building.place(state, station, cell):
					break
		var cells := Farm.cells_with(state, station)
		if cells.is_empty():
			continue
		var at := Building.anchor_of(state, cells[0])
		var recipes: Array = []
		for recipe in GameData.sorted_names(GameData.RECIPES.keys()):
			if StringName((GameData.RECIPES[recipe] as Dictionary).get("station", &"")) == station:
				recipes.append(recipe)
		for _i in GameData.QUEUE_LENGTH:
			for recipe in recipes:
				if Crafting.enqueue(state, at, StringName(recipe)):
					break
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
## **Every name in `PerfNames` has its branch** (task 0275): `headless_v1`'s
## `_task_0275_perf_year` reads this match for each one.
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


## **Microseconds per rebuild of every path field** (task 0275): the three
## `refresh()` keeps and every field built when asked, each asked the way a
## night asks for it - the whole of `Pathing.FIELDS` on one change to the farm.
func _path(state: Dictionary) -> int:
	var mine: Dictionary = state.duplicate(true)
	var asked: Array = []
	for name in GameData.sorted_names(Pathing.FIELDS.keys()):
		if not bool((Pathing.FIELDS[name] as Dictionary).get("eager", false)):
			asked.append(StringName(name))
	var started := Time.get_ticks_usec()
	for _i in REPEATS:
		mine["grid_version"] = int(mine["grid_version"]) + 1
		Pathing.refresh(mine)
		for name in asked:
			Pathing.field(mine, name)
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
	# **`_ready` as the game has it**, on the first frame (task 0275): until
	# then it was called by hand on nodes outside the tree, which sized the
	# emitter's pools but left every frame asking for a viewport it had not
	# got.
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
