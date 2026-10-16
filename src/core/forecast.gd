class_name Forecast
extends RefCounted

## **What tonight will send, told at dusk** (task 0158).
##
## From 18:00 and in the build step the farmer is told which sides the horde
## comes from, how many and of what kind, and whether it is a Full Moon, a
## boss or a calm night. **It is never wrong, because it is the night**: every
## answer is read off `Waves.night_of(date, seed)` - the very record
## `Waves.tonight` will keep and fight, calendar flags and all - and off
## `Calendar`. Nothing here is a guess and nothing here is kept.
##
## **Never the run's stream.** It reads `state["seed"]` and never
## `state["rng"]`: asking the forecast a thousand times must leave the run
## exactly where it was. The one thing in it that is random, the night's
## weather (task 0256), is `Weather.event`'s: a fresh `(seed, date)` stream
## the way `Almanac.stream_for` deals a made night.


## The forecast for one date of a run started on `seed_value`:
##
## - `date`, `season` (`&"spring"`...), `day_of_season`;
## - `full_moon`, `boss` (the boss's kind, or `&""`) and `calm`, the record's
##   own flags (tasks 0152-0154);
## - `sides`: `GameData.SPAWN_SIDES` ids (`&"east"`...), in `SPAWNS` order;
## - `waves`: how many; `kinds`: `[kind, count]` pairs in the order each kind
##   first arrives; `count`: everything the night sends;
## - `event`: the night's weather (task 0256), `Weather.event` - `&"fog"`,
##   `&"rain"`, or `&""` for none.
static func of(seed_value: int, date: int) -> Dictionary:
	var one := Waves.night_of(date, seed_value)
	var rows: Array = one.get("waves", [])
	var order: Array = []
	var counts := {}
	for row in rows:
		var kind := StringName((row as Array)[0])
		if not counts.has(kind):
			order.append(kind)
			counts[kind] = 0
		counts[kind] = int(counts[kind]) + int((row as Array)[1])
	var kinds: Array = []
	for kind in order:
		kinds.append([kind, int(counts[kind])])
	var sides: Array = []
	for index in Waves.spawns_in(one):
		sides.append(side_id(int(index)))
	return {
		"date": date,
		"season": Calendar.season_id(date),
		"day_of_season": Calendar.day_of_season(date),
		"full_moon": bool(one.get("full_moon", false)),
		"boss": StringName(one.get("boss", &"")),
		"calm": bool(one.get("calm", false)),
		"sides": sides,
		"waves": rows.size(),
		"kinds": kinds,
		"count": Waves.size_in(one),
		"event": Weather.event(seed_value, date),
	}


## Tonight's forecast: the one for today's date (`Calendar.date`), which is
## the night the build step opens on.
static func tonight(state: Dictionary) -> Dictionary:
	return of(int(state["seed"]), Calendar.date(state))


## The name of a `SPAWNS` region (task 0157), or `&""` for one that is not.
static func side_id(index: int) -> StringName:
	var names: Array = GameData.SPAWN_SIDES
	if index < 0 or index >= names.size():
		return &""
	return StringName(names[index])
