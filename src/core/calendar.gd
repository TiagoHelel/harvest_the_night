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
## **The one place that knows it.** It is `state["day"]` until task 0153
## holds the calendar still on a boss night; every reader asks here, so that
## change is made once.
static func date(state: Dictionary) -> int:
	return maxi(int(state["day"]), 1)


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


## The season's id (`&"spring"` ...), for `Names.of` and every table keyed by
## season.
static func season_id(day: int, season_days: int = GameData.SEASON_DAYS) -> StringName:
	return GameData.SEASONS[season_of(day, season_days)]
