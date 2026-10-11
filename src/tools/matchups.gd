extends SceneTree

## **Every weapon has its night** (task 0259): the plan's test for phases 4
## and 5 in numbers - every defence the best buy somewhere, every enemy
## asking for a different answer - and the report the night authors of
## 0270-0274 build the year from (`implementation/MATCHUPS.md`).
##
## Run by `python tools/matchups.py`, never by `verify.py`: the whole grid is
## minutes, and verify gives a script 120 seconds. `--only=<enemy>` plays one
## enemy's rows and writes nothing. Seeded and deterministic: two runs print
## the same report byte for byte; only the run time differs, and it is printed
## outside the report.
##
## ## The arena
##
## - **One lane on the real farm**: the last `LANE` cells of the east spawn's
##   road to the house, worked out on the farm before anything is built. The
##   group walks in from its far end, so a fight is short and the lane is the
##   same for every defence.
## - **The base line**, always there: `BASE_GUNS` gun towers at level one
##   either side of the lane `BASE_AT` cells from the house, and generators
##   enough by day that nothing is short of power. The house is given
##   `HOUSE_POOL` hit points, so it never falls and what it takes is counted
##   whole rather than stopped at a hundred.
## - **Each defence on top of it**, bought with the same budget: the dearest
##   single unit's price, money plus materials at `SELL_PRICE` (0234's), so
##   the dearest gets one and the cheap ones many. Each goes in at the level
##   its season allows - every level's node is on spring's floor, so its top
##   one - and the levels' costs are in its price. Placed by its kind:
##   - **beside the lane**, alternating sides from `BESIDE_FROM` cells out,
##     anything that shoots, lights or lures (the towers, the hive, the
##     searchlight, the decoy);
##   - **on the road**, from `ROAD_FROM` cells out, anything walked over or a
##     trap (the mine, the garlic braid, the bait);
##   - **round the house**, `RING` cells out from its walls, the side facing
##     the lane first, the barriers - as a farm walls itself in. Across an
##     open lane they were walked round and prevented nothing.
##   What the placement rule or its own limit cannot fit is not bought. A
##   defence that lasts a while (`lifetime_ticks`: the barricade, the bait)
##   goes down when the first of the group comes within `DEFER_REACH` cells
##   of the house end, as a player throws it - put down in the build step,
##   the bait had rotted before anything arrived.
## - **One group**: a kind's `GROUP_HP` hit points' worth of it - so no kind
##   is fairer than another for being many - one every `SPAWN_EVERY` ticks
##   from the lane's far end, rats in clusters; a boss with its season's
##   escort, `ESCORT_HP` worth of each of two kinds.
## - **A fight** ends when everything sent is dead or `CAP_TICKS` have gone.
##   The top buy is the highest score; on a tie - more than one line keeping
##   the whole group off the house - the one that cleared the lane sooner,
##   then the one that killed more.
##   Per pair: the house damage, the kills, the ticks to clear and the
##   structures lost. **The score**: house damage prevented against the base
##   alone, per thousand of the budget - so a barrier or a support piece is
##   scored as what it adds to the base line, as everything is. Per thousand
##   of the budget rather than of what was spent: every defence was handed
##   the same sum, and one that cannot take it all is not made cheaper by
##   that - per thousand spent, five barricades that turned one bite away
##   outscored every tower line.
## - **The same grid under fog, rain and the Blood Moon**: each on the first
##   night of Year 2 the seed's `Weather` gives it - Year 2 because every
##   season's arsenal is open there - and the ordinary night on the first
##   with no weather. Never a Full Moon, a boss night or a calm one.

const SEED := 2590259
const LANE := 24
const BASE_AT := 4
const BASE_GUNS := 2
const BESIDE_FROM := 3
const ROAD_FROM := 6
const RING := 2
const DEFER_REACH := 10
const GENERATORS := 5
const HOUSE_POOL := 1000000
const GROUP_HP := 1440
const ESCORT_HP := 360
const SPAWN_EVERY := 8
const RAT_CLUSTER := 8
const CAP_TICKS := 2400
const PLENTY := 100000

## A boss's season's escort: the two kinds that season brought.
const ESCORTS := {
	&"giant": [&"walker", &"runner"],
	&"harvester": [&"spitter", &"rat"],
	&"scarecrow_king": [&"crow", &"digger"],
	&"winter_lord": [&"frost_zombie", &"wraith"],
}
## The enemies 1.0 brought: each one's top answer must not be the walker's.
const NEW_ENEMIES := [&"spitter", &"rat", &"crow", &"digger", &"frost_zombie", &"wraith"]
const EVENTS := [&"", &"fog", &"rain", &"blood_moon"]
const EVENT_NAMES := {&"": "ordinary", &"fog": "fog", &"rain": "rain", &"blood_moon": "Blood Moon"}

var _lane_cache: Array = []


func _initialize() -> void:
	var started := Time.get_ticks_msec()
	var only := &""
	for arg in OS.get_cmdline_user_args():
		if String(arg).begins_with("--only="):
			only = StringName(String(arg).substr(7))
	var defences: Array = GameData.sorted_names(GameData.DEFENCES.keys())
	var foes := _foes()
	if only != &"":
		if not GameData.ENEMIES.has(only):
			print("FAIL  no enemy called '%s'" % only)
			quit(1)
			return
		foes = [only]
	var levels := {}
	var prices := {}
	var budget := 0
	for id in defences:
		levels[id] = _top_level(StringName(id))
		prices[id] = _price(StringName(id), int(levels[id]))
		budget = maxi(budget, int(prices[id]))
	print("DEFENCES %d: %s" % [defences.size(), ", ".join(PackedStringArray(defences))])
	print("BUDGET %d" % budget)

	var results := {}
	var dates := {}
	for event in EVENTS:
		dates[event] = _date_of(event)
		for foe in foes:
			var base := _fight(int(dates[event]), foe, &"", 1, 0)
			base["spent"] = 0
			base["score"] = 0
			results[_key(event, foe, &"")] = base
			print("ROW %s | %s | base | house %d | kills %d | ticks %d | lost %d"
				% [EVENT_NAMES[event], foe, int(base["house"]), int(base["kills"]),
					int(base["ticks"]), int(base["lost"])])
			for id in defences:
				var bought := budget / int(prices[id])
				var one := _fight(int(dates[event]), foe, StringName(id), int(levels[id]), bought)
				one["spent"] = int(one["placed"]) * int(prices[id])
				one["score"] = (int(base["house"]) - int(one["house"])) * 1000 / budget
				results[_key(event, foe, StringName(id))] = one
				print("ROW %s | %s | %s | %d placed | %d spent | house %d | kills %d | ticks %d | lost %d | score %d"
					% [EVENT_NAMES[event], foe, id, int(one["placed"]), int(one["spent"]), int(one["house"]),
						int(one["kills"]), int(one["ticks"]), int(one["lost"]), int(one["score"])])

	var report := _report(defences, foes, levels, prices, budget, dates, results)
	if only == &"":
		print("BEGIN MATCHUPS")
		print(report)
		print("END MATCHUPS")
	for line in _claims(defences, foes, results)["lines"]:
		print("CLAIM " + String(line))
	print("RUN %d s, %d fights" % [(Time.get_ticks_msec() - started) / 1000, results.size()])
	quit(0)


# ------------------------------------------------------------------ a fight

## One fight: the base line, `count` of `id` at `level` on top of it (none
## when `id` is empty), and one group of `foe` - on `date`'s night.
func _fight(date: int, foe: StringName, id: StringName, level: int, count: int) -> Dictionary:
	var state := State.create(SEED)
	state["day"] = date
	state["nights_won"] = date - 1
	var plenty := {}
	for res in GameData.RESOURCES:
		plenty[res] = PLENTY
	Resources.gain(state, plenty)
	(state["tech_owned"] as Array).append_array(_level_nodes())
	# Power for everything, by day: a generator is a day job.
	for _i in GENERATORS:
		var spot := _room_for(state, Building.size_of(&"generator"))
		if spot.x >= 0:
			Building.place(state, &"generator", spot)
	NightRoad.into_build(state)
	var lane := _lane(state)
	_put_base(state, lane)
	var placed := 0
	var deferred := id != &"" and (GameData.DEFENCES[id] as Dictionary).has("lifetime_ticks")
	if id != &"" and not deferred:
		placed = _put(state, id, level, count, lane)
	NightRoad.through_build(state)
	NightRoad.park(state)
	Enemies.withdraw(state)
	state["house_hp"] = HOUSE_POOL

	var plan := _group(foe)
	var start: Vector2i = lane[0]
	var sent := 0
	var tick := 0
	var cleared := -1
	while tick < CAP_TICKS and int(state["phase"]) == Phases.NIGHT:
		if sent < plan.size() and tick % SPAWN_EVERY == 0:
			var one: Array = plan[sent]
			if int(one[1]) > 1:
				Enemies.cluster_at(state, StringName(one[0]), start, int(one[1]))
			else:
				Entities.spawn(state, StringName(one[0]), start)
			sent += 1
		if deferred and _near(state, lane[lane.size() - 1]):
			deferred = false
			placed = _put(state, id, level, count, lane)
		Sim.tick(state)
		tick += 1
		if sent >= plan.size() and Entities.count(state) == 0:
			cleared = tick
			break
	return {
		"house": HOUSE_POOL - int(state["house_hp"]),
		"kills": int(state["killed"]),
		"ticks": cleared if cleared >= 0 else CAP_TICKS,
		"lost": _lost(state),
		"placed": placed,
	}


## Whether anything of the group has come within `DEFER_REACH` of `cell`.
func _near(state: Dictionary, cell: Vector2i) -> bool:
	for one in Entities.ids(state):
		var at := Entities.cell_of(state, int(one))
		if at.x >= 0 and Grid.chebyshev(at, cell) <= DEFER_REACH:
			return true
	return false


## The group: `GROUP_HP` worth of one kind, rats in clusters; or a boss and
## `ESCORT_HP` worth of each of its season's two kinds. `[kind, count]` in
## the order they are sent.
func _group(foe: StringName) -> Array:
	if not ESCORTS.has(foe):
		return _of(foe, GROUP_HP)
	var out: Array = [[foe, 1]]
	for kind in ESCORTS[foe]:
		out.append_array(_of(StringName(kind), ESCORT_HP))
	return out


func _of(kind: StringName, hit_points: int) -> Array:
	var hp := maxi(int((GameData.ENEMIES[kind] as Dictionary)["hp"]), 1)
	var many := (hit_points + hp - 1) / hp
	var out: Array = []
	if kind == &"rat":
		for _i in (many + RAT_CLUSTER - 1) / RAT_CLUSTER:
			out.append([kind, RAT_CLUSTER])
		return out
	for _i in many:
		out.append([kind, 1])
	return out


## The lane: the last `LANE` cells of the east spawn's road to the house, far
## end first - worked out once, on the farm with nothing built on its road.
func _lane(state: Dictionary) -> Array:
	if not _lane_cache.is_empty():
		return _lane_cache
	Pathing.refresh(state)
	var at: Vector2i = Enemies.spawn_cells(state, 0)[0]
	var road: Array = [at]
	for _i in Grid.CELLS:
		var next := Pathing.step_from(state, at)
		if next == at or Farm.occupant(state, next).get("id", &"") == &"house":
			break
		road.append(next)
		at = next
	_lane_cache = road.slice(maxi(road.size() - LANE, 0))
	return _lane_cache


## Across the lane at cell `i`: the way the road turns there, a quarter turn.
func _across(lane: Array, i: int) -> Vector2i:
	var a: Vector2i = lane[maxi(i - 1, 0)]
	var b: Vector2i = lane[mini(i + 1, lane.size() - 1)]
	var along := b - a
	var step := Vector2i(signi(along.x), signi(along.y))
	return Vector2i(-step.y, step.x) if step != Vector2i.ZERO else Vector2i(0, 1)


## The lane's cell `distance` cells out from the house end.
func _from_house(lane: Array, distance: int) -> int:
	return clampi(lane.size() - 1 - distance, 0, lane.size() - 1)


func _put_base(state: Dictionary, lane: Array) -> void:
	var i := _from_house(lane, BASE_AT)
	for k in BASE_GUNS:
		var side := 1 if k % 2 == 0 else -1
		for off in [2, 3, 4]:
			if Building.place(state, &"gun_tower", lane[i] + _across(lane, i) * side * int(off)):
				break


## `count` of `id` by its kind's rule, each brought up to `level`. How many
## went down.
func _put(state: Dictionary, id: StringName, level: int, count: int, lane: Array) -> int:
	var placed := 0
	# A kit-only one (0225's bait) is put down from kits, banked here.
	if Building.kit_only(id):
		Crafting.bank_kit(state, id, count)
	match _role(id):
		&"road":
			for distance in range(ROAD_FROM, lane.size()):
				if placed >= count:
					break
				var cell: Vector2i = lane[_from_house(lane, distance)]
				if Building.place(state, id, cell):
					_level_up(state, cell, level)
					placed += 1
		&"beside":
			for k in 2 * lane.size():
				if placed >= count:
					break
				var distance := BESIDE_FROM + (k / 2) * 2
				if distance >= lane.size():
					break
				var i := _from_house(lane, distance)
				var side := 1 if k % 2 == 0 else -1
				for off in [2, 3, 4]:
					var cell: Vector2i = lane[i] + _across(lane, i) * side * int(off)
					if Building.place(state, id, cell):
						_level_up(state, cell, level)
						placed += 1
						break
		_:
			for cell in _ring(state, lane):
				if placed >= count:
					break
				if Building.place(state, id, cell):
					_level_up(state, cell as Vector2i, level)
					placed += 1
	return placed


## Every cell `RING` out from the house's walls, the nearest to the lane's
## house end first, then by index.
func _ring(state: Dictionary, lane: Array) -> Array:
	var house := Farm.house_bounds(state)
	var end: Vector2i = lane[lane.size() - 1]
	var keyed: Array = []
	for y in range(house.position.y - RING, house.end.y + RING):
		for x in range(house.position.x - RING, house.end.x + RING):
			var cell := Vector2i(x, y)
			var dx := maxi(maxi(house.position.x - x, x - (house.end.x - 1)), 0)
			var dy := maxi(maxi(house.position.y - y, y - (house.end.y - 1)), 0)
			if maxi(dx, dy) == RING and Grid.in_bounds(cell):
				keyed.append([Grid.chebyshev(cell, end), Grid.index(cell)])
	keyed.sort()
	var out: Array = []
	for pair in keyed:
		out.append(Grid.cell(int((pair as Array)[1])))
	return out


## How a defence is placed: on the road if it is walked over or a trap,
## beside the lane if it shoots, lights or lures, round the house otherwise.
func _role(id: StringName) -> StringName:
	if Building.walked_over(id) or Traps.is_trap(id):
		return &"road"
	var row: Dictionary = GameData.DEFENCES[id]
	if row.has("reload_ticks") or row.has("light_tiles") or row.has("lure_tiles"):
		return &"beside"
	return &"ring"


func _level_up(state: Dictionary, cell: Vector2i, level: int) -> void:
	for _l in range(1, level):
		if not Building.upgrade(state, cell):
			break


## The structures that came down: the rubble the morning would sweep.
func _lost(state: Dictionary) -> int:
	var out := 0
	for cell in Farm.rubble_cells(state):
		var id := Farm.rubble_at(state, cell)
		if GameData.DEFENCES.has(id) or GameData.BUILDINGS.has(id):
			out += 1
	return out


func _room_for(state: Dictionary, size: Vector2i) -> Vector2i:
	for y in range(1, Grid.HEIGHT - size.y):
		for x in range(1, Grid.WIDTH - size.x):
			var where := Vector2i(x, y)
			if Building.why_not(state, &"generator", where).is_empty():
				return where
	return Vector2i(-1, -1)


# ---------------------------------------------------------------- the table

## The ordinary enemies by name, then the bosses in their seasons' order.
func _foes() -> Array:
	var out: Array = []
	for kind in GameData.sorted_names(GameData.ENEMIES.keys()):
		if not Combat.is_boss(kind):
			out.append(kind)
	for boss in GameData.SEASON_BOSSES:
		out.append(StringName(boss))
	return out


## The level a defence's season allows: one, and a level more for each of its
## `TOWER_LEVELS` rows whose node is on its season's floor or an earlier one.
func _top_level(id: StringName) -> int:
	var season := GameData.SEASONS.find(GameData.defence_season(GameData.DEFENCES[id]))
	var level := 1
	for step in GameData.TOWER_LEVELS.get(id, []):
		var needs := StringName((step as Dictionary).get("needs", &""))
		if _node_season(needs) > season:
			break
		level += 1
	return level


func _node_season(node: StringName) -> int:
	for row in GameData.TECH_TREE:
		if StringName((row as Dictionary)["id"]) == node:
			return int((row as Dictionary).get("season", 0))
	return 0


## Every node a level needs, given to every fight.
func _level_nodes() -> Array:
	var out: Array = []
	for id in GameData.sorted_names(GameData.TOWER_LEVELS.keys()):
		for step in GameData.TOWER_LEVELS[id]:
			var needs := StringName((step as Dictionary).get("needs", &""))
			if needs != &"" and not out.has(needs):
				out.append(needs)
	return out


## What one unit costs at `level`: its cost and every level's on the way, money
## plus materials at `SELL_PRICE`.
func _price(id: StringName, level: int) -> int:
	var total := _worth(GameData.DEFENCES[id].get("cost", {}))
	var steps: Array = GameData.TOWER_LEVELS.get(id, [])
	for l in range(0, mini(level - 1, steps.size())):
		total += _worth((steps[l] as Dictionary).get("cost", {}))
	return maxi(total, 1)


func _worth(cost: Dictionary) -> int:
	var total := 0
	for res in GameData.sorted_names(cost.keys()):
		total += int(cost[res]) if res == GameData.MONEY \
			else int(cost[res]) * int(GameData.SELL_PRICE.get(res, 0))
	return total


## The first night of Year 2 the seed's weather makes `event` - none for the
## ordinary night - that is no Full Moon, boss night or calm night.
func _date_of(event: StringName) -> int:
	var first := Calendar.year_days() + 2
	for date in range(first, first + 4 * Calendar.year_days()):
		if Calendar.is_full_moon(date) or Calendar.is_boss_night(date) or Calendar.is_calm(date):
			continue
		if Weather.event(SEED, date) == event:
			return date
	return first


func _key(event: StringName, foe: StringName, id: StringName) -> String:
	return "%s|%s|%s" % [event, foe, id]


## The top buy for one enemy on one night: the defence with the highest
## score - on a tie, the one that cleared the lane sooner, then the one that
## killed more, then the first by name. Empty when nothing prevented anything.
func _top(defences: Array, results: Dictionary, event: StringName, foe: StringName, skip: Array = []) -> StringName:
	var best := &""
	var most := [0, 0, 0]
	for id in defences:
		if skip.has(id):
			continue
		var r: Dictionary = results.get(_key(event, foe, StringName(id)), {})
		var score := int(r.get("score", 0))
		if score <= 0:
			continue
		var rank := [score, -int(r.get("ticks", 0)), int(r.get("kills", 0))]
		if best == &"" or rank > most:
			most = rank
			best = StringName(id)
	return best


## The plan's three claims, line by line, and each defence's best night or
## its UNPROVEN numbers.
func _claims(defences: Array, foes: Array, results: Dictionary) -> Dictionary:
	var lines: Array = []
	var best_night := {}
	var unproven: Array = []
	for id in defences:
		var where := ""
		var high := 0
		var top_anywhere := false
		for event in EVENTS:
			for foe in foes:
				if _top(defences, results, event, foe) != StringName(id):
					continue
				top_anywhere = true
				var score := int(results[_key(event, foe, StringName(id))]["score"])
				if where == "" or score > high:
					high = score
					where = "%s, %s night (%d)" % [foe, EVENT_NAMES[event], score]
		if top_anywhere:
			best_night[id] = where
			continue
		# Its best score anywhere, and the top's there.
		var near := ""
		var own := -(1 << 30)
		for event in EVENTS:
			for foe in foes:
				var score := int((results.get(_key(event, foe, StringName(id)), {}) as Dictionary).get("score", 0))
				if score > own:
					own = score
					var top := _top(defences, results, event, foe)
					near = "%d against %s on the %s night, where %s scores %d" % [score, foe,
						EVENT_NAMES[event], top if top != &"" else "nothing", int((results.get(_key(event, foe, top), {})
							as Dictionary).get("score", 0))]
		best_night[id] = "UNPROVEN: at best %s" % near
		unproven.append(id)
	lines.append("every defence is the top buy somewhere: %d of %d%s" % [defences.size() - unproven.size(),
		defences.size(), "" if unproven.is_empty() else " - UNPROVEN: " + ", ".join(PackedStringArray(unproven))])
	for event in EVENTS:
		var tops := {}
		for foe in foes:
			tops[_top(defences, results, event, foe)] = true
		lines.append("no defence is top against every enemy on the %s night: %s (%d different tops over %d enemies)"
			% [EVENT_NAMES[event], "yes" if tops.size() > 1 else "NO", tops.size(), foes.size()])
	var walker := _top(defences, results, &"", &"walker")
	for foe in NEW_ENEMIES:
		if not foes.has(foe) or not foes.has(&"walker"):
			continue
		var top := _top(defences, results, &"", StringName(foe))
		lines.append("%s's top answer differs from the walker's (%s): %s - %s" % [foe, walker,
			"yes" if top != walker else "NO", top])
	return {"lines": lines, "best_night": best_night, "unproven": unproven}


func _report(defences: Array, foes: Array, levels: Dictionary, prices: Dictionary, budget: int,
		dates: Dictionary, results: Dictionary) -> String:
	var out := PackedStringArray()
	out.append("# Matchups")
	out.append("")
	out.append("Every weapon's night (task 0259), written by `python tools/matchups.py` from `src/tools/matchups.gd`. Seed %d; a lane of the last %d cells of the east road; the base line %d gun towers at level one %d cells from the house; one group of %d hit points of a kind - a boss with %d of each of its season's two - sent one every %d ticks; a fight to its clearing or %d ticks." % [SEED, LANE, BASE_GUNS, BASE_AT, GROUP_HP, ESCORT_HP, SPAWN_EVERY, CAP_TICKS])
	out.append("")
	out.append("**The budget** is the dearest unit's price, %d: money plus materials at `SELL_PRICE`, every defence at the top level its season allows. **The score** is house damage prevented against the base line alone, per thousand of the budget: what a defence adds to that line, a barrier or a support piece as much as a tower - and a defence its placement or its own limit keeps from spending it all is not made cheaper by that. Beside the lane: what shoots, lights or lures. On the road: what is walked over, and the traps. Round the house, %d cells out from its walls, the lane's side first: the barriers. What lasts a while (the barricade, the bait) goes down when the group comes within %d cells of the house end." % [budget, RING, DEFER_REACH])
	out.append("")
	out.append("| defence | level | price | role |")
	out.append("|---|---|---|---|")
	for id in defences:
		out.append("| %s | %d | %d | %s |" % [id, int(levels[id]), int(prices[id]), _role(StringName(id))])
	for event in EVENTS:
		out.append("")
		out.append("## The %s night (date %d)" % [EVENT_NAMES[event], int(dates[event])])
		out.append("")
		var head := "| defence |"
		var rule := "|---|"
		for foe in foes:
			head += " %s |" % foe
			rule += "---|"
		out.append(head)
		out.append(rule)
		var base := "| *base line: house damage* |"
		for foe in foes:
			base += " %d |" % int(results[_key(event, foe, &"")]["house"])
		out.append(base)
		for id in defences:
			var line := "| %s |" % id
			for foe in foes:
				var r: Dictionary = results[_key(event, foe, StringName(id))]
				var mark := "**" if _top(defences, results, event, foe) == StringName(id) else ""
				line += " %s%d%s |" % [mark, int(r["score"]), mark]
			out.append(line)
	out.append("")
	out.append("## Each enemy's top three answers")
	out.append("")
	for event in EVENTS:
		for foe in foes:
			var picks := PackedStringArray()
			var taken: Array = []
			for _n in 3:
				var top := _top(defences, results, event, foe, taken)
				if top == &"":
					break
				taken.append(top)
				picks.append("%s %d" % [top, int(results[_key(event, foe, top)]["score"])])
			out.append("- %s, %s night: %s" % [foe, EVENT_NAMES[event], ", ".join(picks) if not picks.is_empty() else "nothing prevented anything"])
	var claims := _claims(defences, foes, results)
	out.append("")
	out.append("## Each defence's best night")
	out.append("")
	for id in defences:
		out.append("- %s: %s" % [id, claims["best_night"][id]])
	out.append("")
	out.append("## For the night authors")
	out.append("")
	for foe in foes:
		var picks := PackedStringArray()
		var taken: Array = []
		for _n in 2:
			var top := _top(defences, results, &"", foe, taken)
			if top == &"":
				break
			taken.append(top)
			picks.append(String(top))
		var weather := PackedStringArray()
		for event in [&"fog", &"rain", &"blood_moon"]:
			var top := _top(defences, results, event, foe)
			if top != &"" and not taken.has(top):
				weather.append("%s: %s" % [EVENT_NAMES[event], top])
		out.append("- %s: %s%s" % [foe, ", ".join(picks) if not picks.is_empty() else "nothing the budget buys",
			"" if weather.is_empty() else " (" + "; ".join(weather) + ")"])
	out.append("")
	out.append("## The claims")
	out.append("")
	for line in claims["lines"]:
		out.append("- " + String(line))
	out.append("")
	out.append("## Every fight")
	out.append("")
	out.append("| night | enemy | defence | placed | spent | house | kills | ticks | lost | score |")
	out.append("|---|---|---|---|---|---|---|---|---|---|")
	for event in EVENTS:
		for foe in foes:
			var b: Dictionary = results[_key(event, foe, &"")]
			out.append("| %s | %s | *base* | - | - | %d | %d | %d | %d | - |" % [EVENT_NAMES[event], foe,
				int(b["house"]), int(b["kills"]), int(b["ticks"]), int(b["lost"])])
			for id in defences:
				var r: Dictionary = results[_key(event, foe, StringName(id))]
				out.append("| %s | %s | %s | %d | %d | %d | %d | %d | %d | %d |" % [EVENT_NAMES[event], foe, id,
					int(r["placed"]), int(r["spent"]), int(r["house"]), int(r["kills"]), int(r["ticks"]),
					int(r["lost"]), int(r["score"])])
	return "\n".join(out)
