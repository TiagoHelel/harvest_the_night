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
## case. `Waves.plain_night` asks here for the year's 56 days, and past them
## `Endless` still writes the night until 0279.
##
## ## The template decides what comes; the seed decides how it arrives
##
## The `Endless` contract: two runs meeting the same day meet the same crowd.
## The template's numbers, read at the day of the season, give the night's
## hit points, its waves and its gap, and the kinds that have joined share
## the hit points by weight - so the totals per kind are the day's on every
## seed. The seed only orders the waves and picks which of the open sides
## the night starts from, out of a fresh stream of `(seed, day)`
## (`Endless._stream_for`) - never `state["rng"]`, so asking about a night a
## thousand times moves nothing.
##
## ## What it never makes
##
## A key night's day - the record is written - and a calm date (0154): those
## carry no record of their own, and `Waves.night_of` answers the calm night
## for them. Nor a boss: 0153's rule adds the season's boss row on its last
## night, and `check_nights` refuses one in a template.


## The record of `day` in Year 1 for a run started on `seed_value`: its key
## night as written, or one made from its season's template. Empty for a calm
## date and for a day outside the year.
static func night(seed_value: int, day: int) -> Dictionary:
	if day < 1 or day > Calendar.year_days():
		return {}
	if is_key(day):
		return GameData.KEY_NIGHTS[day]
	if Calendar.is_calm(day):
		return {}
	return _made(seed_value, day)


## Whether a person wrote `day`'s night (`KEY_NIGHTS`).
static func is_key(day: int) -> bool:
	return GameData.KEY_NIGHTS.has(day)


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
## that has joined by then.
static func mix_on(template: Dictionary, of_season: int) -> Dictionary:
	var out := {}
	var mix: Dictionary = template.get("mix", {})
	for kind in GameData.sorted_names(mix.keys()):
		var pair: Array = mix[kind]
		if int(pair[1]) <= of_season:
			out[kind] = int(pair[0])
	return out


## **A made night.** The day's hit points shared out by weight between the
## kinds that have joined, each share in bodies of its kind - at least one -
## dealt into the day's waves round the open sides by `Endless`'s own deal,
## spaced to fill the night (0271) and sent inside it (0137).
static func _made(seed_value: int, day: int) -> Dictionary:
	var of_season := Calendar.day_of_season(day)
	var template: Dictionary = GameData.SEASON_NIGHTS[Calendar.season_of(day)]
	var points := Endless._share_out(on_day(template["size"], of_season), mix_on(template, of_season))
	var bodies := {}
	for kind in GameData.sorted_names(points.keys()):
		var hp := maxi(int((GameData.ENEMIES[kind] as Dictionary)["hp"]), 1)
		bodies[kind] = maxi(int(points[kind]) / hp, 1)
	var rng := Rng.create(Endless._stream_for(seed_value, day))
	var one := {
		"note": "%s %d, from the season's template" % [Calendar.season_id(day), of_season],
		"opening_ticks": 0,
		"gap_ticks": on_day(template["gap_ticks"], of_season),
		"waves": Endless._lay_out(rng, bodies, on_day(template["waves"], of_season),
			sides_on(template, of_season)),
	}
	_fill_the_night(one)
	Endless._fit_before_dawn(one)
	return one


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
