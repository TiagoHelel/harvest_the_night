extends SceneTree

## **The economy across a year** (task 0278), a season at a time, from the
## tables through the rules - nothing here is played. `tools/autoplay.py
## --economy` plays the year for the rest: what the line was worth, what each
## boss cost and what winter lived off. Headless, outside the suite:
##
##     godot --headless --path . --script res://src/tools/year_economy.gd
##
## It prints, for each season:
## - **a focused day by earner** (`Economy.day`, 0194), and the best of them;
## - **the mixed day** a real one is (0196's tour): the field tended for
##   `FIELD_HOURS`, then the best other earner for the working hours left -
##   winter, with no field, is its best earner alone;
## - **each new defence** at a money-only price (`Building.price_of`, 0234),
##   and the **day-to-defence ratio**: a day over the price of the season's
##   opener (`OPENERS`), for the focused day and the mixed one;
## - **the night's purse** held well (`night_pay.gd`), against the best
##   focused day, with what it leaves lying about;
##
## and the hens' **eggs a day at one, two and three visits**, through the
## hen's own clock (`Livestock._produce`), one tick at a time.

## **The field's hours** in a real day: 0196's tour tended it in two to two
## and a half game hours.
const FIELD_HOURS := 2.25

## **Each season's opener** (0234's bold rows): the first tower of its
## arsenal a good day is meant to buy. The barriers and the throwaways are a
## fraction of a day, the heavy towers the season's saving.
const OPENERS := {&"spring": &"gun_tower", &"summer": &"beehive",
	&"autumn": &"catapult", &"winter": &"searchlight"}

## The visits a day the hens are measured at: the morning feed alone, the
## morning and dusk, and the morning, noon and dusk - and 0196's tour, the
## morning and four hours after it.
const VISITS := {"one (06:00)": [6 * 60], "two (06:00, 18:00)": [6 * 60, 18 * 60],
	"three (06:00, 12:00, 18:00)": [6 * 60, 12 * 60, 18 * 60],
	"the tour's two (06:00, 10:00)": [6 * 60, 10 * 60]}


func _initialize() -> void:
	var night_pay: Script = load("res://src/tools/night_pay.gd")
	var nights := {}
	for night in range(1, Calendar.year_days() + 1):
		var season := StringName(GameData.SEASONS[Calendar.season_of(night)])
		var paid: Dictionary = night_pay.call("pay", night)
		var sums: Array = nights.get(season, [0, 0, 0])
		sums[0] += int(paid["money"])
		sums[1] += int(paid["left_worth"])
		sums[2] += 1
		nights[season] = sums

	print("| Season | Field | Pond | Cliff and woods | Animals | Machines | Best focused day | Mixed day | Opener | Its price | Focused ratio | Mixed ratio | Night held well | Night / best day | What it leaves |")
	print("|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|")
	for season in GameData.SEASONS:
		var days := {}
		var best := 0
		for earner in Economy.STRATEGIES:
			days[earner] = Economy.day(earner, season)
			best = maxi(best, int(days[earner]))
		var mixed := mixed_day(season)
		var opener: StringName = OPENERS[season]
		var price := Building.price_of(opener)
		var sums: Array = nights[season]
		var night := int(sums[0]) / int(sums[2])
		print("| %s | %s | %s | %s | %s | %s | $%d | $%d | %s | $%d | %.2f | %.2f | $%d | %d%% | $%d |" % [season,
			_money(days[&"crops"]), _money(days[&"fishing"]), _money(days[&"mining"]),
			_money(days[&"animals"]), _money(days[&"artisan"]), best, mixed, opener, price,
			float(best) / float(price), float(mixed) / float(price), night, night * 100 / best,
			int(sums[1]) / int(sums[2])])

	print("")
	print("| Season | New defence | Money | Materials at the stall | Price | Focused days |")
	print("|---|---|---|---|---|---|")
	for season in GameData.SEASONS:
		var best := 0
		for earner in Economy.STRATEGIES:
			best = maxi(best, Economy.day(earner, season))
		for id in GameData.sorted_names(GameData.DEFENCES.keys()):
			if GameData.defence_season(GameData.DEFENCES[id]) != season:
				continue
			var price := Building.price_of(id)
			print("| %s | %s | $%d | $%d | $%d | %.2f |" % [season, id, Building.money_of(id),
				price - Building.money_of(id), price, float(price) / float(best)])

	print("")
	var holds := int((GameData.LIVESTOCK[&"chicken"] as Dictionary)["holds"])
	print("| Visits a day | Eggs a hen a day, holding %d | Holding %d | Holding %d |" % [holds, holds + 1, holds + 2])
	print("|---|---|---|---|")
	for label in VISITS:
		print("| %s | %.2f | %.2f | %.2f |" % [label, eggs_a_day(VISITS[label], holds),
			eggs_a_day(VISITS[label], holds + 1), eggs_a_day(VISITS[label], holds + 2)])
	print("")
	print("Collected the moment each is laid (Economy.animals): %.2f eggs a hen a day" % [
		float(Phases.tick_at_minute(int(GameData.DAY_FARM["animal_bed_minute"])))
		/ float((GameData.LIVESTOCK[&"chicken"] as Dictionary)["every_ticks"])])
	quit()


## **The mixed day** (0196): the season's field for `FIELD_HOURS` - its whole
## day's money, for the field is tended, not watched - then the best other
## earner for the hours left of 06:00 to dusk. A season with no field is its
## best earner.
static func mixed_day(season: StringName) -> int:
	var field := Economy.day(&"crops", season)
	var other := 0
	for earner in Economy.STRATEGIES:
		if earner != &"crops":
			other = maxi(other, Economy.day(earner, season))
	if field < 0:
		return other
	var hours := float(GameData.DUSK_MINUTE - GameData.DAY_START_MINUTE) / 60.0
	return field + int(float(other) * (hours - FIELD_HOURS) / hours)


## **A hen's eggs a day** collected at `minutes`, holding `holds` - the
## steady state over a fortnight of days from 06:00 to the animals' bedtime,
## through the hen's own clock (`Livestock._produce`), what she holds carried
## from day to day.
static func eggs_a_day(minutes: Array, holds: int) -> float:
	var entry: Dictionary = (GameData.LIVESTOCK[&"chicken"] as Dictionary).duplicate()
	entry["holds"] = holds
	var hen := {"ready": 0, "left": int(entry["every_ticks"])}
	var day := Phases.tick_at_minute(int(GameData.DAY_FARM["animal_bed_minute"]))
	var visits: Array = []
	for minute in minutes:
		visits.append(Phases.tick_at_minute(int(minute)))
	var collected := 0
	var days := 14
	for d in days + 2:
		for tick in day:
			if visits.has(tick):
				if d >= 2:
					collected += int(hen["ready"])
				hen["ready"] = 0
			Livestock._produce(hen, entry)
	return float(collected) / float(days)


static func _money(value: int) -> String:
	return "-" if value < 0 else "$%d" % value
