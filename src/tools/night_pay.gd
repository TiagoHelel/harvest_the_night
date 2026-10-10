extends SceneTree

## **What a night pays, beside what a day earns** (task 0219): every night of
## the year, held well - everything it sent killed, the house untouched,
## nothing lost, nobody through, `INTACT` defences standing unscratched - and
## priced through the rules themselves (`Rewards._money_from`,
## `Rewards.preview`, `Tech.would_pay`), so the table is what the game pays and
## not a second copy of its arithmetic. Materials are counted at what the stall
## pays for them, as 0194 counts a day. Headless, outside the suite:
##
##     godot --headless --path . --script res://src/tools/night_pay.gd
##
## Prints spring night by night, then each season's average beside its day
## band (`GameData.DAY_TARGETS`).

## How many defences a well-held night has standing, untouched: a spring
## farm's, a tower or two a side and the walls in front of them.
const INTACT := 8


func _initialize() -> void:
	print("| Night | Fee | Bounty | Bonuses | Full Moon | Money | Materials | Their worth | Essence |")
	print("|---|---|---|---|---|---|---|---|---|")
	var seasons := {}
	for night in range(1, Calendar.year_days() + 1):
		var paid := pay(night)
		var season := Calendar.season_of(night)
		var sums: Array = seasons.get(season, [0, 0, 0, 0, 0, 0, 0, 0])
		sums[0] += int(paid["money"])
		sums[1] += int(paid["worth"])
		sums[2] += int(paid["essence"])
		sums[3] += 1
		sums[4] += int(paid["fee"])
		sums[5] += int(paid["bounty"])
		sums[6] += int(paid["bonuses"])
		sums[7] += int(paid["moon"])
		seasons[season] = sums
		if night <= GameData.SEASON_DAYS:
			print("| %d%s | $%d | $%d | $%d | $%d | $%d | %s | $%d | %d |" % [night,
				" (calm)" if Rewards.is_calm(paid["state"]) else (" (Full Moon)" if Calendar.is_full_moon(night) else ""),
				int(paid["fee"]), int(paid["bounty"]), int(paid["bonuses"]), int(paid["moon"]),
				int(paid["money"]), paid["materials"], int(paid["worth"]), int(paid["essence"])])
	print("")
	print("| Season | Fee | Bounty | Bonuses | Full Moon | A night's money | Its materials' worth | Essence | A day's band |")
	print("|---|---|---|---|---|---|---|---|---|")
	var order: Array = seasons.keys()
	order.sort()
	for season in order:
		var sums: Array = seasons[season]
		var name := StringName(GameData.SEASONS[int(season)])
		var band: Array = GameData.DAY_TARGETS[name]
		var n := int(sums[3])
		print("| %s | $%d | $%d | $%d | $%d | $%d | $%d | %.1f | $%d-%d |" % [name, int(sums[4]) / n,
			int(sums[5]) / n, int(sums[6]) / n, int(sums[7]) / n, int(sums[0]) / n,
			int(sums[1]) / n, float(sums[2]) / float(n), int(band[0]), int(band[1])])
	quit()


## One night, held well, priced.
static func pay(night: int) -> Dictionary:
	var state := State.create(2190 + night)
	state["day"] = night
	state["night"] = night
	state["house_hp"] = Phases.house_full(state)
	state["breaches"] = 0
	state["killed_by_kind"] = Waves.kinds_of(night).duplicate()
	var stood := 0
	for idx in Grid.CELLS:
		var cell := Grid.cell(idx)
		if stood < INTACT and Farm.buildable(state, cell):
			(state["occupants"] as Dictionary)[idx] = {"id": &"gun_tower",
				"hp": int((GameData.DEFENCES[&"gun_tower"] as Dictionary)["hp"])}
			stood += 1
	# A calm night pays its gift and nothing else (task 0154).
	var lines := {} if Rewards.is_calm(state) else Rewards._money_from(state)
	var all := Rewards.preview(state, true)
	var materials := {}
	var worth := 0
	for id in GameData.sorted_names(all.keys()):
		if id == GameData.MONEY:
			continue
		materials[String(id)] = int(all[id])
		worth += int(all[id]) * int(GameData.SELL_PRICE.get(id, 0))
	var essence := 0
	var owed := Tech.would_pay(state, night) if not Rewards.is_calm(state) else {}
	for line in GameData.sorted_names(owed.keys()):
		essence += int(owed[line])
	return {
		"state": state,
		"fee": int(lines.get("for the night", 0)),
		"bounty": int(lines.get("bounty", 0)),
		"bonuses": int(lines.get("nothing touched", 0)) + int(lines.get("still standing", 0))
			+ int(lines.get("the house untouched", 0)),
		"moon": int(lines.get("full moon", 0)),
		"money": int(all.get(GameData.MONEY, 0)),
		"materials": materials,
		"worth": worth,
		"essence": essence,
	}
