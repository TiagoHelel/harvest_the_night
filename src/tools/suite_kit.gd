class_name SuiteKit

## Plain helpers the test suites share.
##
## Task 0112 split the suites in two: `headless_check` / `input_check` hold
## every group and case up to task 0111, `headless_v1` / `input_v1` everything
## from 0112 on. A helper a new suite needs is **moved here, not copied**, so
## the two halves can never drift into two slightly different ideas of the same
## fixture. Only plain functions of their arguments live here: nothing that
## needs the running SceneTree, nothing that counts an assert.


## Put the farmer on a tile, for a check that needs them somewhere.
static func stand_the_farmer(state: Dictionary, cell: Vector2i) -> void:
	var mine: Dictionary = state["player"]
	mine["pos"] = [cell.x * Player.SUBTILE + Player.SUBTILE / 2,
		cell.y * Player.SUBTILE + Player.SUBTILE / 2]


## Where a cell of the first farm's yard is now.
##
## **The farmstead moved to the middle of the farm** (2026-10-06) and took the
## night's spawn points with it, 24 tiles east and 18 south, and the camera
## with the farmer standing on its porch. These fixtures were measured against
## the old yard - a tower so many tiles east of the house, a fence across the
## way in from the east - so they are written in those coordinates and moved by
## the same step: the same fight, on the same ground relative to the house and
## the horde.
static func moved(cell: Vector2i) -> Vector2i:
	return cell + GameData.PLAYER_START - Vector2i(16, 8)


## The first cell in reading order a defence could go on, skipping tilled
## soil; `(-1, -1)` when there is none.
static func any_buildable(state: Dictionary) -> Vector2i:
	for idx in Grid.CELLS:
		var cell := Grid.cell(idx)
		if Farm.buildable(state, cell) and not Farming.is_tilled(state, cell):
			return cell
	return Vector2i(-1, -1)


## A file with its whole-line comments taken out, for a check about what code
## does.
static func code_lines_of(path: String) -> String:
	var out := PackedStringArray()
	for line in FileAccess.get_file_as_string(path).split("\n"):
		var trimmed := String(line).strip_edges()
		if trimmed.begins_with("#"):
			continue
		out.append(line)
	return "\n".join(out)


## Put defences up on a farm that stays where it is - usually the day - as if
## they had gone up in last night's build step. Returns what `build` returns.
##
## Task 0119: 0132 forbids defences by day, and a tower standing on a day farm
## is one that was built the night before. A fixture that needs that farm
## builds it this way rather than playing a whole night first: the phase reads
## PREPARATION for exactly the length of `build`, then goes back. A check that
## goes on into the night takes `NightRoad.to_build()` instead, which is the
## real road.
static func built_last_night(state: Dictionary, build: Callable) -> Variant:
	var phase := int(state["phase"])
	state["phase"] = Phases.PREPARATION
	var out: Variant = build.call()
	state["phase"] = phase
	return out


## **The other way round** (task 0132): a production building goes up by day
## only, so a build-step fixture that needs one standing - the generator
## behind a measured tower line - builds it this way: the phase reads DAY for
## exactly the length of `build`, then goes back.
static func built_by_day(state: Dictionary, build: Callable) -> Variant:
	var phase := int(state["phase"])
	state["phase"] = Phases.DAY
	var out: Variant = build.call()
	state["phase"] = phase
	return out


## Advance only regrowth timers in a fixture, checking the real expiry road.
## No full-day simulation: unrelated systems cannot affect these resource checks.
static func regrow_after(state: Dictionary, ticks: int) -> void:
	if ticks <= 0:
		return
	for pending in (state["regrowing"] as Array):
		pending[Gathering.PENDING_TICKS] = int(pending[Gathering.PENDING_TICKS]) - ticks + 1
	Gathering.tick(state)


## A clock fixture exercises the boundary tick without simulating the skipped hours.
static func reach_day_tick(state: Dictionary, target: int) -> void:
	state["day_tick"] = target - 1
	Sim.advance(state, 1)


## Suites exercise an early bedtime; the standalone robot keeps its full day.
static func early_policy(name: StringName) -> Dictionary:
	var policy: Dictionary = Autoplay.POLICIES[name].duplicate(true)
	policy["bed_minute"] = 20 * 60
	return policy


## Advance crop fixtures through watered mornings without simulating long days.
static func watered_mornings(state: Dictionary, days: int = 1) -> void:
	for _day in days:
		var keys: Array = state["plots"].keys()
		keys.sort()
		for idx in keys:
			var plot: Dictionary = state["plots"][idx]
			if plot["crop"] != &"":
				plot["watered"] = true
		Farming.dry_out(state)
		Farming.morning(state)


## A crop fixture gets packets and a valid date without weakening the rules.
static func crop_supplies(state: Dictionary, id: StringName, packets: int = 80) -> void:
	if id not in Farming.in_season(state):
		var season: StringName = GameData.CROPS[id]["seasons"][0]
		state["day"] = GameData.SEASONS.find(season) * GameData.SEASON_DAYS + 1
		state["days_held"] = 0
	state["held"][Farming.packet(id)] = packets
