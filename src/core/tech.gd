class_name Tech
extends RefCounted

## Essence: what a night survived is worth towards never having this problem
## again.
##
## **Essence since task 0219** (plan section 4.6): the night hands it over for
## holding the farm, and the tree is bought with it. Only the words changed -
## the resource id is still `tech`, so every save still reads - and the tree
## itself is still the technology tree.
##
## `design.md` section 12 pays three things for a night - money, resources and
## **pontos de tecnologia** - and this is the third. Money buys the next night;
## technology buys every night after it, which is the difference between
## spending and investing and is why it is a separate currency rather than an
## expensive shop item.
##
## ## One a night, and the rest is earned
##
## The flat point is for finishing. The bonuses are **conditions in a table**,
## not code: `GameData.TECH_BONUSES` says what is worth an extra point, and
## adding a fourth way to earn one is a table entry and an arm of
## `_earned()`. That keeps "how do I get more" answerable by reading the data
## rather than the rules.
##
## ## A night pays once
##
## `nights_paid` remembers which nights have handed over their points, so a
## player who reloads a save from before a night they already beat cannot beat
## it again for the technology. Money and resources are not protected this way
## on purpose: replaying a night to farm it costs a real night of the ten, and
## the ten are the run. Technology is permanent, so it is the one that has to
## be defended.

## What `nights` nights pay in total, if every bonus is taken every time -
## by default the run's, `Run.final_night()` of them. The number
## `tools/nights.py` prints and task 0063 budgets the tree against.
##
## **A year is 56 nights since task 0151**, 224 points at best against a
## tree that costs 45. Until 0220 re-prices the tree against the year, its
## budget is asked of the authored nights by passing their count.
##
## **A Full Moon pays its own share on top** (task 0219), as `would_pay` adds
## it: night by night, so the dates decide.
##
## **The calendar's ceiling, not a run's** (task 0257): a Blood Moon is the
## run's own roll (`Weather.event`), and each one a run has pays its
## `blood_moon_essence` over this.
static func total_available(nights: int = -1) -> int:
	if nights < 0:
		nights = Run.final_night()
	var each := int(GameData.REWARDS["tech_points"])
	for row in GameData.TECH_BONUSES:
		each += int((row as Dictionary)["points"])
	var most := 0
	for night in range(1, nights + 1):
		most += with_the_moon(each, night)
	return most


## The least `nights` nights pay - the run's by default: one a night, no
## bonuses at all, and a Full Moon's share of that one.
static func least_available(nights: int = -1) -> int:
	if nights < 0:
		nights = Run.final_night()
	var least := 0
	for night in range(1, nights + 1):
		least += with_the_moon(int(GameData.REWARDS["tech_points"]), night)
	return least


## **What a night pays of an ordinary night's essence, in percent** (task
## 0219): `full_moon_essence_percent` on a Full Moon, 100 otherwise.
static func moon_percent(night: int) -> int:
	if Calendar.is_full_moon(night):
		return int(GameData.REWARDS["full_moon_essence_percent"])
	return 100


## `points` of essence with the night's Full Moon line added, the way
## `would_pay` adds it: the share over a hundred, rounded down.
static func with_the_moon(points: int, night: int) -> int:
	return points + points * (moon_percent(night) - 100) / 100


static func initial() -> Dictionary:
	return {
		# Which nights have already handed over their technology. A list
		# rather than a set, because a `State` has to be plain data - and it
		# is ten entries at most.
		"nights_paid": [],
		# Which nodes of the tree have been bought, in the order they were.
		"tech_owned": [],
	}


# --------------------------------------------------------------- the tree

## Every node, in table order. The screen draws this and nothing else.
static func tree() -> Array:
	return GameData.TECH_TREE


## The branches, in the order they are drawn.
static func branches() -> Array:
	var out: Array = []
	for row in GameData.TECH_TREE:
		var branch: StringName = (row as Dictionary)["branch"]
		if not out.has(branch):
			out.append(branch)
	return out


## The nodes of one branch and one floor (task 0220), in table order.
static func floor_of(branch: StringName, season: int) -> Array:
	var out: Array = []
	for row in GameData.TECH_TREE:
		if (row as Dictionary)["branch"] == branch and int((row as Dictionary).get("season", 0)) == season:
			out.append(row)
	return out


## The nodes of one branch, cheapest first.
static func nodes_of(branch: StringName) -> Array:
	var out: Array = []
	for row in GameData.TECH_TREE:
		if (row as Dictionary)["branch"] == branch:
			out.append(row)
	return out


## One node by id, or an empty Dictionary.
static func node(id: StringName) -> Dictionary:
	for row in GameData.TECH_TREE:
		if (row as Dictionary)["id"] == id:
			return row
	return {}


static func owns(state: Dictionary, id: StringName) -> bool:
	return (state["tech_owned"] as Array).has(id)


## Everything bought so far.
static func owned(state: Dictionary) -> Array:
	return state["tech_owned"]


## Why this node cannot be bought, for the tooltip. An empty Array when it
## can. A key and its arguments - see `Building.why_not`.
static func why_not_buy(state: Dictionary, id: StringName) -> Array:
	var one := node(id)
	if one.is_empty():
		return [&"WHY_NO_SUCH_NODE"]
	if owns(state, id):
		return [&"WHY_ALREADY_YOURS"]
	# **Never during a wave.** The requirement, and the reason for it: a tree
	# a player can re-cut while the crowd is walking in is not a decision
	# made before the night, it is a menu they pause in.
	if int(state["phase"]) != Phases.DAY:
		return [&"WHY_AFTER_DARK"]
	# **A floor opens with its season** (task 0220), and stays open: asked
	# before what it needs and what it costs, because neither matters yet.
	var season := int(one.get("season", 0))
	if not Calendar.season_reached(state, season):
		return [&"WHY_NOT_YET_SEASON", StringName(GameData.SEASONS[season])]
	for needed in (one["needs"] as Array):
		if not owns(state, StringName(needed)):
			return [&"WHY_NEEDS_NODE", StringName(needed)]
	if held(state) < int(one["cost"]):
		return [&"WHY_COSTS", int(one["cost"]), held(state)]
	return []


static func can_buy(state: Dictionary, id: StringName) -> bool:
	return why_not_buy(state, id).is_empty()


## Buy a node. False and nothing spent when it will not go.
static func buy(state: Dictionary, id: StringName) -> bool:
	if not can_buy(state, id):
		return false
	var one := node(id)
	if not spend(state, int(one["cost"])):
		return false
	(state["tech_owned"] as Array).append(id)
	return true


## Whether anything bought depends on this one.
static func depends_on(state: Dictionary, id: StringName) -> Array:
	var out: Array = []
	for row in GameData.TECH_TREE:
		var one: Dictionary = row
		var mine := owns(state, StringName(one["id"]))
		if mine and (one["needs"] as Array).has(id):
			out.append(one["id"])
	return out


## What selling a node back would return.
static func refund_for(id: StringName) -> int:
	var one := node(id)
	if one.is_empty():
		return 0
	return int(one["cost"]) * GameData.TECH_REFUND_PERCENT / 100


## Sell a node back for a share of what it cost.
##
## **Refused while something you own still needs it**, or the tree could be
## left with a branch hanging off nothing - and a node whose prerequisite is
## gone is a node you did not earn.
static func refund(state: Dictionary, id: StringName) -> int:
	if not owns(state, id) or int(state["phase"]) != Phases.DAY:
		return 0
	if not depends_on(state, id).is_empty():
		return 0
	var back := refund_for(id)
	(state["tech_owned"] as Array).erase(id)
	if back > 0:
		Resources.add(state, GameData.TECH, back)
	return back


# -------------------------------------------------------------- the effects

## What the tree is worth for one named number.
##
## **The one door every system uses.** `Towers` asks what
## `tower_damage_percent` is and does not know a tree exists; the tree hands
## out numbers and does not know what a tower is. `missing` is what to answer
## when nobody has bought anything that touches it, which is almost always.
##
## **Two nodes giving one number: the stronger wins** (task 0220). That is
## the value farthest from `missing` - the bigger bonus, the bigger percent
## above a hundred, the smaller one below it. A later floor strengthens a
## number an earlier one gave (`GameData.check_tech_tree` holds it so), so
## owning both is owning the later, and selling the later back falls to the
## earlier. They never add up: `true sights` and `heavy shot` are 140, not
## 168. Asked in table order, so a tie is the earlier row - and there is
## none, since the check refuses a later floor no stronger.
static func bonus(state: Dictionary, key: String, missing: int) -> int:
	if state.is_empty() or not state.has("tech_owned"):
		return missing
	var owned: Array = state["tech_owned"]
	if owned.is_empty():
		return missing
	var best := missing
	for row in GameData.TECH_TREE:
		var gives: Dictionary = (row as Dictionary)["gives"]
		if not gives.has(key) or not owned.has((row as Dictionary)["id"]):
			continue
		var value := int(gives[key])
		if absi(value - missing) > absi(best - missing):
			best = value
	return best


# ------------------------------------------------------------------- asking

static func held(state: Dictionary) -> int:
	return Resources.amount(state, GameData.TECH)


## Whether this night has already paid its technology.
static func already_paid(state: Dictionary, night: int) -> bool:
	return (state["nights_paid"] as Array).has(night)


## What a night would pay, itemised, without paying it. `Rewards.settle`
## keeps these lines in the payout for the morning report, and
## `headless_check` adds them up.
##
## Empty when the night has already been paid for, which is the whole of
## "essence cannot be earned by replaying a night already survived".
##
## **A Full Moon is its own line** (task 0219), `"full moon"`: what the other
## lines add up to, times `full_moon_essence_percent` less a hundred, over a
## hundred - the money's arithmetic (`Rewards._money_from`).
##
## **So is a Blood Moon** (task 0257), `"blood moon"`: `blood_moon_essence`
## on top, for the run's own night (`Weather.event`). It never falls on a
## Full Moon, so the two lines never meet.
static func would_pay(state: Dictionary, night: int) -> Dictionary:
	if already_paid(state, night):
		return {}
	var out := {"for surviving": int(GameData.REWARDS["tech_points"])}
	for row in GameData.TECH_BONUSES:
		var bonus: Dictionary = row
		if _earned(state, StringName(bonus["id"])):
			out[StringName(bonus["id"])] = int(bonus["points"])
	if moon_percent(night) != 100:
		var ordinary := 0
		for line in GameData.sorted_names(out.keys()):
			ordinary += int(out[line])
		out["full moon"] = with_the_moon(ordinary, night) - ordinary
	if Weather.event(int(state["seed"]), night) == Weather.BLOOD_MOON:
		out["blood moon"] = int(GameData.REWARDS["blood_moon_essence"])
	return out


# -------------------------------------------------------------------- doing

## Hand over what the night earned and remember that it has. Returns the
## points paid, which is zero for a night that has already paid.
static func award(state: Dictionary, night: int) -> int:
	var lines := would_pay(state, night)
	if lines.is_empty():
		return 0
	var points := 0
	for id in GameData.sorted_names(lines.keys()):
		points += int(lines[id])
	if points > 0:
		Resources.add(state, GameData.TECH, points)
	(state["nights_paid"] as Array).append(night)
	return points


## Write a night down as paid without paying it (task 0154): the calm night,
## which earns no technology - nothing was defended - and must still never
## be paid later.
static func mark_paid(state: Dictionary, night: int) -> void:
	if not already_paid(state, night):
		(state["nights_paid"] as Array).append(night)


## Spend them. False and nothing taken when there are not enough: the tech
## tree of task 0063 is the only caller.
static func spend(state: Dictionary, points: int) -> bool:
	if points <= 0 or held(state) < points:
		return false
	return Resources.spend(state, GameData.TECH, points)


# -------------------------------------------------------------- moon stones

## Why a moon stone cannot be traded for essence now (task 0221): a key and
## its arguments, or an empty Array when it can - see `why_not_buy`.
static func why_not_trade(state: Dictionary) -> Array:
	if int(state["phase"]) != Phases.DAY:
		return [&"WHY_AFTER_DARK"]
	if Resources.amount(state, GameData.MOON_STONE) <= 0:
		return [&"WHY_NO_MOON_STONE"]
	return []


## **Moon stones for essence** (task 0221; plan section 3.3: "they are
## worth essence or money"), by day, `MOON_STONE_ESSENCE` a stone. The
## stall buys them for money; this is the other half, and the one door to
## it. Returns the essence paid - 0, with nothing taken, after dark or for
## more stones than are held.
static func trade_moon_stones(state: Dictionary, n: int = 1) -> int:
	if n <= 0 or not why_not_trade(state).is_empty():
		return 0
	if not Resources.spend(state, GameData.MOON_STONE, n):
		return 0
	var paid := n * GameData.MOON_STONE_ESSENCE
	Resources.add(state, GameData.TECH, paid)
	return paid


# ------------------------------------------------------------ the conditions

## Whether one of the table's conditions was met tonight.
##
## **One arm per condition**, and the table names which. An arm for a
## condition nobody has written is a loud error rather than a quiet no,
## because a bonus that silently never pays is worse than one that does not
## exist.
static func _earned(state: Dictionary, id: StringName) -> bool:
	match id:
		&"house untouched":
			return int(state["house_hp"]) >= Phases.house_full(state)
		&"nothing lost":
			# Nothing the player built came down tonight.
			return Farm.rubble_cells(state).is_empty()
		&"not one got through":
			return int(state["breaches"]) == 0
		_:
			push_error("Tech: nobody implements the bonus '%s'" % id)
			return false
