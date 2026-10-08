class_name Calendar
extends RefCounted

## **What day of the year it is** (task 0149).
##
## A year is `GameData.SEASONS` in order, each `GameData.SEASON_DAYS` long:
## day 1 is Spring 1 of Year 1, day 15 Summer 1, day 56 Winter 14 and day 57
## Spring 1 of Year 2. Every rule of the calendar phase hangs off these, and
## nothing else counts seasons.
##
## **No state of its own.** The date is read off the day the run already
## keeps, so asking never changes a hash. The pure helpers take the season
## length as an optional argument, so a test can prove a seven-day season
## without turning the lever.


## Today's date: the calendar day the farm is on.
##
## **The one place that knows it.** The days lived less the days a boss has
## held the calendar on its night (task 0153, `days_held`): `day` moves every
## morning - the stall restocks on it, the report and the stats count it -
## while the date stays on the boss's night until the boss falls.
static func date(state: Dictionary) -> int:
	return maxi(int(state["day"]) - int(state.get("days_held", 0)), 1)


## How many days a year has.
static func year_days(season_days: int = GameData.SEASON_DAYS) -> int:
	return GameData.SEASONS.size() * maxi(season_days, 1)


## Which year a date falls in, from 1.
static func year_of(day: int, season_days: int = GameData.SEASON_DAYS) -> int:
	return (maxi(day, 1) - 1) / year_days(season_days) + 1


## Which season a date falls in: 0 spring, 1 summer, 2 autumn, 3 winter.
static func season_of(day: int, season_days: int = GameData.SEASON_DAYS) -> int:
	return ((maxi(day, 1) - 1) % year_days(season_days)) / maxi(season_days, 1)


## The day of its season a date is, from 1 to `SEASON_DAYS`.
static func day_of_season(day: int, season_days: int = GameData.SEASON_DAYS) -> int:
	return (maxi(day, 1) - 1) % maxi(season_days, 1) + 1


## Whether a date is a Full Moon night (task 0152): one of
## `GameData.FULL_MOON_DAYS` of its season.
static func is_full_moon(day: int, season_days: int = GameData.SEASON_DAYS) -> bool:
	return GameData.FULL_MOON_DAYS.has(day_of_season(day, season_days))


## Days from a date to the next Full Moon: 0 on the night itself. -1 when the
## calendar has no Full Moons at all.
static func days_to_full_moon(day: int, season_days: int = GameData.SEASON_DAYS) -> int:
	var today := day_of_season(day, season_days)
	var ahead := -1
	var first := -1
	for moon in GameData.FULL_MOON_DAYS:
		var on := int(moon)
		if first < 0 or on < first:
			first = on
		if on >= today and (ahead < 0 or on - today < ahead):
			ahead = on - today
	if ahead >= 0 or first < 0:
		return ahead
	# None left this season: the next season's first.
	return maxi(season_days, 1) - today + first


## Whether a date is its season's boss night (task 0153): the season's last
## day.
static func is_boss_night(day: int, season_days: int = GameData.SEASON_DAYS) -> bool:
	return day_of_season(day, season_days) == maxi(season_days, 1)


## The boss of the season a date falls in.
static func boss_of(day: int, season_days: int = GameData.SEASON_DAYS) -> StringName:
	var bosses: Array = GameData.SEASON_BOSSES
	if bosses.is_empty():
		return &""
	return StringName(bosses[season_of(day, season_days) % bosses.size()])


## The season's id (`&"spring"` ...), for `Names.of` and every table keyed by
## season.
static func season_id(day: int, season_days: int = GameData.SEASON_DAYS) -> StringName:
	return GameData.SEASONS[season_of(day, season_days)]
