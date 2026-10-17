class_name Almanac
extends RefCounted

## **The year's nights, as data** (task 0270): a template per season
## (`GameData.SEASON_NIGHTS`), the nights a person writes (`KEY_NIGHTS`:
## every introduction and every Full Moon), and this - the generator that
## fills every other day of the year from its season's template.
##
## A night it makes is the record a person would have written - `{note,
## opening_ticks, gap_ticks, waves}` with waves `[kind, count, spawn]` - so
## nothing downstream of `Waves.night_of` can tell a key night from a made
## one: `Waves`, `Enemies`, `Rewards`, the forecast and the HUD needed no new
## case. `Waves.plain_night` asks here for every day.
##
## **And the years after the first** (task 0279): each day of Year 2 on is
## Year 1's day grown by `GameData.LATER_YEARS`, made from its season's whole
## template - `_later`. That replaced the MVP's endless curve (0070), whose
## deal - the stream, the sharing out, the waves and the fit before dawn -
## lives here now.
##
## ## The template decides what comes; the seed decides how it arrives
##
## The old curve's contract: two runs meeting the same day meet the same crowd.
## The template's numbers, read at the day of the season, give the night's
## hit points, its waves and its gap, and the kinds that have joined share
## the hit points by weight - so the totals per kind are the day's on every
## seed. The seed only orders the waves and picks which of the open sides
## the night starts from, out of a fresh stream of `(seed, day)`
## (`stream_for`) - never `state["rng"]`, so asking about a night a thousand
## times moves nothing.
##
## ## What it never makes
##
## A key night's day - the record is written - and a calm date (0154): those
## carry no record of their own, and `Waves.night_of` answers the calm night
## for them. Nor a boss: 0153's rule adds the season's boss row on its last
## night, and `check_nights` refuses one in a template.


## The record of `day` for a run started on `seed_value`: in Year 1 its key
## night as written, or one made from its season's template; in a later year
## Year 1's day grown (`_later`). Empty for a calm date and before day 1.
static func night(seed_value: int, day: int) -> Dictionary:
	if day < 1:
		return {}
	if day > Calendar.year_days():
		return {} if Calendar.is_calm(day) else _later(seed_value, day)
	if is_key(day):
		return GameData.KEY_NIGHTS[day]
	if Calendar.is_calm(day):
		return {}
	return _made(seed_value, day)


## Whether a person wrote `day`'s night (`KEY_NIGHTS`): Year 1's alone - a
## later year has no introductions (task 0279).
static func is_key(day: int) -> bool:
	return day <= Calendar.year_days() and GameData.KEY_NIGHTS.has(day)


## **Whether `day` is a second week's pinch** (task 0298): Year 1's key night
## on `GameData.PINCH_DAY` of its season.
static func is_pinch(day: int) -> bool:
	return is_key(day) and Calendar.day_of_season(day) == GameData.PINCH_DAY


## **Whether `day` is a later year's** (task 0279): past Year 1 and not a calm
## date, so made by `_later`.
static func is_later(day: int) -> bool:
	return day > Calendar.year_days() and not Calendar.is_calm(day)


## Whether `day`'s night is made from its season's template: a day of the
## year that is neither a key night nor a calm date.
static func is_made(day: int) -> bool:
	return day >= 1 and day <= Calendar.year_days() and not is_key(day) \
		and not Calendar.is_calm(day)


## A template's number on day `of_season`: its first value up to the second
## day, its second from the thirteenth, and the line between them on the
## days between - integers, rounded down.
static func on_day(pair: Array, of_season: int) -> int:
	var first := int(pair[0])
	var last := int(pair[1])
	if of_season <= 2:
		return first
	if of_season >= 13:
		return last
	return first + (last - first) * (of_season - 2) / 11


## The sides a template deals from on day `of_season`: every one that has
## joined by then, in the template's order.
static func sides_on(template: Dictionary, of_season: int) -> Array:
	var out: Array = []
	for pair in template.get("sides", []):
		if int((pair as Array)[1]) <= of_season:
			out.append(int((pair as Array)[0]))
	return out


## The kinds a template mixes on day `of_season`, with their weights: every one
## that has joined by then - every one of the season's, `whole`, for a later
## year - less those the template **rests** that day (task 0298), so the
## night after an introduction and each night of the second week lean on
## part of the season rather than all of it.
static func mix_on(template: Dictionary, of_season: int, whole: bool = false) -> Dictionary:
	var out := {}
	var mix: Dictionary = template.get("mix", {})
	var resting: Array = (template.get("rests", {}) as Dictionary).get(of_season, [])
	for kind in GameData.sorted_names(mix.keys()):
		var pair: Array = mix[kind]
		if (whole or int(pair[1]) <= of_season) and not resting.has(kind):
			out[kind] = int(pair[0])
	return out


## **A made night.** The day's hit points shared out by weight between the
## kinds that have joined, each share in bodies of its kind - at least one -
## dealt into the day's waves round the open sides (`lay_out`), spaced to fill
## the night (0271) and sent inside it (0137).
static func _made(seed_value: int, day: int) -> Dictionary:
	var of_season := Calendar.day_of_season(day)
	var template: Dictionary = GameData.SEASON_NIGHTS[Calendar.season_of(day)]
	var points := share_out(on_day(template["size"], of_season), mix_on(template, of_season))
	var bodies := {}
	for kind in GameData.sorted_names(points.keys()):
		var hp := maxi(int((GameData.ENEMIES[kind] as Dictionary)["hp"]), 1)
		bodies[kind] = maxi(int(points[kind]) / hp, 1)
	var rng := Rng.create(stream_for(seed_value, day))
	var one := {
		"note": "%s %d, from the season's template" % [Calendar.season_id(day), of_season],
		"opening_ticks": 0,
		"gap_ticks": on_day(template["gap_ticks"], of_season),
		"waves": lay_out(rng, bodies, on_day(template["waves"], of_season),
			sides_on(template, of_season)),
	}
	_fill_the_night(one)
	fit_before_dawn(one)
	return one


## **A night of a later year** (task 0279): Year 1's night on the same day of
## the year - a key night's hit points as written too, its boss rows aside -
## grown by `LATER_YEARS.growth_percent` for each year past the first, added
## and never compounded. It is made from its season's **whole** template:
## every kind of the season mixed from its first day, for nothing is new any
## more and a later year has no introductions - less the kinds the template
## rests that day, as Year 1's made nights do (task 0298). Each share is rounded **up**
## to whole bodies, so a later year never sends fewer hit points than the
## year before it. Its sides open day by day as Year 1's did, its waves and
## gaps are the template's, and it fills the night as a made one does. The
## boss and the Full Moon come on top in `Waves.night_of`, as in Year 1.
static func _later(seed_value: int, day: int) -> Dictionary:
	var of_season := Calendar.day_of_season(day)
	var template: Dictionary = GameData.SEASON_NIGHTS[Calendar.season_of(day)]
	var points := share_out(later_hit_points(day), mix_on(template, of_season, true))
	var bodies := {}
	for kind in GameData.sorted_names(points.keys()):
		var hp := maxi(int((GameData.ENEMIES[kind] as Dictionary)["hp"]), 1)
		bodies[kind] = maxi((int(points[kind]) + hp - 1) / hp, 1)
	var rng := Rng.create(stream_for(seed_value, day))
	var one := {
		"note": "%s %d of year %d, from the season's template" % [Calendar.season_id(day),
			of_season, Calendar.year_of(day)],
		"opening_ticks": 0,
		"gap_ticks": on_day(template["gap_ticks"], of_season),
		"waves": lay_out(rng, bodies, on_day(template["waves"], of_season),
			sides_on(template, of_season)),
	}
	_fill_the_night(one)
	fit_before_dawn(one)
	return one


## **The hit points a later year's day is made to** (task 0279): Year 1's on
## the same day of the year, its boss rows aside, grown by `growth_percent`
## for each year past the first. A day's record is the same on every seed, so
## seed 0's is asked.
static func later_hit_points(day: int) -> int:
	var first := (maxi(day, 1) - 1) % Calendar.year_days() + 1
	var hp := 0
	for row in (night(0, first).get("waves", []) as Array):
		var data: Dictionary = GameData.ENEMIES.get((row as Array)[0], {})
		if not bool(data.get("is_boss", false)):
			hp += int(data.get("hp", 0)) * int((row as Array)[1])
	return hp * (100 + int(GameData.LATER_YEARS["growth_percent"]) * (Calendar.year_of(day) - 1)) / 100


## **A boss's hit points on `day`** (task 0279): its own, grown by
## `boss_hp_percent` for each year past the first. `Entities.spawn` writes it
## down as the body's `max_hp`.
static func boss_hp(hp: int, day: int) -> int:
	return hp * (100 + int(GameData.LATER_YEARS["boss_hp_percent"]) * (Calendar.year_of(day) - 1)) / 100


## **Still coming at the fill line** (task 0271): a made night that would be
## all sent before `Waves.fill_line()` spaces its waves further - the
## shortfall shared between its gaps, rounded up - so a day whose deal came
## out in few waves still sends its last one late. A night of one wave waits
## for it instead. Never past the dawn margin: the fill line comes before it.
static func _fill_the_night(one: Dictionary) -> void:
	var short := Waves.fill_line() - Waves.schedule_ticks(one)
	if short <= 0:
		return
	var rows := (one["waves"] as Array).size()
	if rows > 1:
		one["gap_ticks"] = int(one["gap_ticks"]) + (short + rows - 2) / (rows - 1)
	else:
		one["opening_ticks"] = int(one["opening_ticks"]) + short


# ------------------------------------------------------- the deal (task 0070)

## **Sent inside the night** (task 0137): a made night that would still be
## sending at `NIGHT_TICKS - DAWN_MARGIN_TICKS` sends its members closer
## together - the largest `interval_ticks` that fits, down to one a tick.
## Written for the old curve (0070), here since task 0279; a key night keeps
## the house pace, and `check_nights` holds it to the same rule.
static func fit_before_dawn(one: Dictionary) -> void:
	var budget := GameData.NIGHT_TICKS - GameData.DAWN_MARGIN_TICKS
	if Waves.schedule_ticks(one) <= budget:
		return
	var waits := 0
	var spaced := 0
	var rows: Array = one["waves"]
	for i in rows.size():
		waits += Waves._delay_in(one, i) + 1
		spaced += int((rows[i] as Array)[1]) - 1
	var each := (budget - waits) / maxi(spaced, 1) - 1
	one["interval_ticks"] = clampi(each, 0, GameData.SPAWN_INTERVAL_TICKS)


## Split `total` bodies between the kinds in proportion to their weights.
##
## Sorted keys and integer arithmetic, so the same weights always give the
## same answer. Whatever the division leaves over goes to the heaviest kind,
## which is the one the rounding hurt most.
static func share_out(total: int, weights: Dictionary) -> Dictionary:
	var kinds := GameData.sorted_names(weights.keys())
	var sum := 0
	for kind in kinds:
		sum += int(weights[kind])
	if sum <= 0 or kinds.is_empty():
		return {}

	var out := {}
	var handed := 0
	var heaviest: StringName = StringName(kinds[0])
	for kind in kinds:
		var mine := total * int(weights[kind]) / sum
		out[kind] = mine
		handed += mine
		if int(weights[kind]) > int(weights[heaviest]):
			heaviest = StringName(kind)
	out[heaviest] = int(out[heaviest]) + (total - handed)
	return out


## Deal the night's bodies out into waves.
##
## One kind per wave, the way the authored nights are written - a wave is a
## thing arriving, not an assortment - and the kinds are dealt round-robin so
## that the hard ones are not all saved for the end.
##
## **The sides alternate, and the seed only picks which one starts.** Rolling
## each wave's side independently looked more varied and was worse: night 20
## came out of the generator with all seven of its waves on the east edge,
## which is a night you can answer with half a farm. Every authored night from
## the second onward comes from both sides, and this is not the place to
## quietly take that back on a one-in-a-hundred roll.
static func lay_out(rng: Array, bodies: Dictionary, waves: int,
		sides: Array = [0]) -> Array:
	if sides.is_empty():
		sides = [0]
	var queue: Array = []
	for kind in GameData.sorted_names(bodies.keys()):
		if int(bodies[kind]) > 0:
			queue.append([StringName(kind), int(bodies[kind])])
	if queue.is_empty():
		return [[&"walker", 1, 0]]

	# **The seed decides the order the kinds are dealt in**, and it has to
	# decide something. Before this, the only thing it chose was which side
	# the night opened on - so two seeds produced the same night 25 half the
	# time, which is not what "seeded" means. Shuffling the deal changes what
	# opens the night and how the heavy kinds interleave, and it cannot change
	# the totals or lose the alternating sides, so it is variation that costs
	# the curve nothing.
	_shuffle(rng, queue)

	# How many waves each kind gets, in proportion to how many of it there are.
	var rows: Array = []
	var slots := maxi(waves, queue.size())
	var share: Array = []
	var total := 0
	for entry in queue:
		total += int((entry as Array)[1])
	for entry in queue:
		share.append(maxi(slots * int((entry as Array)[1]) / maxi(total, 1), 1))

	# Deal them out one slot at a time, round-robin, so a night opens with
	# something ordinary and the heavier kinds are spread through it.
	var left: Array = []
	for i in queue.size():
		left.append(int((queue[i] as Array)[1]))
	var placed: Array = []
	for _i in queue.size():
		placed.append(0)
	# The sides it alternates through: the date's open ones (task 0157).
	var spawns: int = sides.size()
	var side := Rng.int_between(rng, 0, spawns - 1)
	var guard := 0
	while guard < 200:
		guard += 1
		var sent_any := false
		for i in queue.size():
			if left[i] <= 0 or placed[i] >= int(share[i]):
				continue
			var slots_left: int = int(share[i]) - int(placed[i])
			var count: int = maxi(int(left[i]) / maxi(slots_left, 1), 1)
			count = mini(count, int(left[i]))
			rows.append([(queue[i] as Array)[0], count, int(sides[side % spawns])])
			side += 1
			left[i] = int(left[i]) - count
			placed[i] = int(placed[i]) + 1
			sent_any = true
		if not sent_any:
			break

	# Anything the division left behind joins the last wave of its kind, so
	# the night sends exactly what `size_of()` promised.
	for i in queue.size():
		if left[i] <= 0:
			continue
		var kind: StringName = (queue[i] as Array)[0]
		var found := false
		for r in range(rows.size() - 1, -1, -1):
			if StringName((rows[r] as Array)[0]) == kind:
				(rows[r] as Array)[1] = int((rows[r] as Array)[1]) + left[i]
				found = true
				break
		if not found:
			rows.append([kind, int(left[i]), int(sides[side % spawns])])
			side += 1
		left[i] = 0
	return rows


## Fisher-Yates, off the run's own generator rather than `Array.shuffle()`,
## which draws from the global stream that `Rng` exists to keep out of here.
static func _shuffle(rng: Array, items: Array) -> void:
	for i in range(items.size() - 1, 0, -1):
		var j := Rng.int_between(rng, 0, i)
		var held: Variant = items[i]
		items[i] = items[j]
		items[j] = held


## A stream of this night's own, mixed from the run's seed and the night.
##
## Mixed rather than added, so that seed 11 night 12 and seed 12 night 11 are
## not the same night. The constants are the ones `Rng` already uses on the
## way in, which is enough for a wave table and is not pretending to be more.
static func stream_for(seed_value: int, night_number: int) -> int:
	var h := (seed_value ^ 0x9E3779B9) & 0xFFFFFFFF
	h = (h * 16777619) & 0xFFFFFFFF
	h = (h ^ (night_number * 2654435761)) & 0xFFFFFFFF
	h = (h * 16777619) & 0xFFFFFFFF
	return h
