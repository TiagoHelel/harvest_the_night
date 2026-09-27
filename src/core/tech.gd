class_name Tech
extends RefCounted

## Technology points: what a night survived is worth towards never having this
## problem again.
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

## What the ten nights pay in total, if every bonus is taken every time. The
## number `tools/nights.py` prints and task 0063 budgets the tree against.
static func total_available() -> int:
	var most := 0
	for _night in range(1, GameData.MVP_NIGHTS + 1):
		most += int(GameData.REWARDS["tech_points"])
		for row in GameData.TECH_BONUSES:
			most += int((row as Dictionary)["points"])
	return most


## The least the ten nights pay: one a night, no bonuses at all.
static func least_available() -> int:
	return int(GameData.REWARDS["tech_points"]) * GameData.MVP_NIGHTS


static func initial() -> Dictionary:
	return {
		# Which nights have already handed over their technology. A list
		# rather than a set, because a `State` has to be plain data - and it
		# is ten entries at most.
		"nights_paid": [],
	}


# ------------------------------------------------------------------- asking

static func held(state: Dictionary) -> int:
	return Resources.amount(state, GameData.TECH)


## Whether this night has already paid its technology.
static func already_paid(state: Dictionary, night: int) -> bool:
	return (state["nights_paid"] as Array).has(night)


## What a night would pay, itemised, without paying it. The result screen
## shows this and `headless_check` adds it up.
##
## Empty when the night has already been paid for, which is the whole of
## "points cannot be earned by replaying a night already survived".
static func would_pay(state: Dictionary, night: int) -> Dictionary:
	if already_paid(state, night):
		return {}
	var out := {"for surviving": int(GameData.REWARDS["tech_points"])}
	for row in GameData.TECH_BONUSES:
		var bonus: Dictionary = row
		if _earned(state, StringName(bonus["id"])):
			out[StringName(bonus["id"])] = int(bonus["points"])
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


## Spend them. False and nothing taken when there are not enough: the tech
## tree of task 0063 is the only caller.
static func spend(state: Dictionary, points: int) -> bool:
	if points <= 0 or held(state) < points:
		return false
	return Resources.spend(state, GameData.TECH, points)


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
			return int(state["house_hp"]) >= GameData.HOUSE_HP
		&"nothing lost":
			# Nothing the player built came down tonight.
			return Farm.rubble_cells(state).is_empty()
		&"not one got through":
			return int(state["breaches"]) == 0
		_:
			push_error("Tech: nobody implements the bonus '%s'" % id)
			return false
