class_name Shop
extends RefCounted

## Money, and the first reason to care which resource you went and got.
##
## Selling is how a morning of chopping becomes a tower. Buying is the
## emergency exit - and it is **always a bad deal on purpose**, because a shop
## that could replace an afternoon at the rock face would quietly replace
## playing the game.
##
## ## The panel is a state, not a screen
##
## `state["open_panel"]` says which panel the player has open. Core owns it, the
## interact verb sets it and the cancel intent clears it, and `src/ui/` only
## draws whatever it says. That keeps "the player is shopping" a fact about the
## game rather than a fact about a node - which is what lets the autoplayer of
## task 0067 sell a day's wood without a window being open.
##
## **The day stops while the stall is open** (task 0039). Section 13's promise
## is that the farm runs while you are doing something else *on the farm*; a
## conversation with a shopkeeper is not that, and a player who opened this to
## think and came back to a dead field would learn to think somewhere else.
##
## ## The stock is the limit, and it is a daily one
##
## The stall has a few of each thing and refreshes at dawn. **Once a day, not
## once a visit**: restocking when you walked away and came back would be
## unlimited stock with extra walking, and unlimited stock is a stall that a
## player with money never has to leave.
##
## ## The peddler keeps hours and seasons (task 0190)
##
## He trades from `STALL_OPENS` to `STALL_CLOSES` on 0126's clock, and the
## `trade` verb is what is refused outside them (`why_closed`) - never
## `buy` or `sell`, because an open panel stops the clock and the stall
## cannot close under the player. His shelf is the date's season's
## (`GameData.stall_stock`): the materials, this season's packets and none
## in winter, the farm's animals and the workshop's tool upgrades. Neither
## of those last two is a resource: an animal goes into a coop or a barn
## with room or is not sold, and an upgrade is the workshop's order - the
## same price, the same `ToolTiers` rules - waiting for the morning.


## What the stall will take off you, in the reference sheet's order.
##
## Money is not here - money does not sell for money - and neither is energy,
## which is a rate rather than a stock.
static func sellable() -> Array:
	var out: Array = []
	for id in GameData.RESOURCES:
		if GameData.SELL_PRICE.has(id):
			out.append(id)
	return out


## What the stall sells today that goes into the ledger: the materials and
## this season's packets (task 0190). Its animals and its tool upgrades are
## `animals()` and `upgrades()`.
static func buyable(state: Dictionary) -> Array:
	var out: Array = []
	for id in GameData.sorted_names(GameData.stall_stock(season(state)).keys()):
		if GameData.RESOURCES.has(id):
			out.append(id)
	return out


## The animals the peddler brings, in name order (task 0190).
static func animals() -> Array:
	return GameData.sorted_names(GameData.ANIMAL_STOCK.keys())


## The tool upgrades in his pack: the workshop's recipes (task 0190).
static func upgrades() -> Array:
	return GameData.tool_upgrades()


## The season whose shelf the stall puts out.
static func season(state: Dictionary) -> StringName:
	return Calendar.season_id(Calendar.date(state))


static func initial() -> Dictionary:
	return {
		"stall": {
			# {resource: how many are left today}
			#
			# **Stocked from the start**, not one tick later. A farm exists
			# before its first tick - the tests build one and trade with it,
			# and so does a save loaded at dawn - and a stall that was empty
			# until something advanced would be a stall that is empty exactly
			# when somebody looks at it directly.
			"stock": _fresh_stock(GameData.SEASONS[0]),
			# The day the stock above was put out.
			"day": 1,
			# Which tab is showing. A fact about the game rather than about a
			# node, like `open_panel` itself, so the autoplayer can buy.
			#
			# **Selling first**, because that is what the player came for: a
			# stall is where a morning of chopping becomes money, and buying is
			# the emergency exit. Opening on the tab nobody wants is one click
			# on every single visit.
			"tab": SELL,
		},
	}


const BUY := &"buy"
const SELL := &"sell"


## A full day's worth of everything the stall carries in this season.
static func _fresh_stock(in_season: StringName) -> Dictionary:
	var stock := {}
	var table := GameData.stall_stock(in_season)
	for id in GameData.sorted_names(table.keys()):
		stock[id] = int(table[id])
	return stock


## How many of this the stall has left today.
static func stock_of(state: Dictionary, id: StringName) -> int:
	return int(((state["stall"] as Dictionary)["stock"] as Dictionary)
		.get(id, 0))


## Which tab is showing.
static func tab(state: Dictionary) -> StringName:
	return StringName((state["stall"] as Dictionary)["tab"])


static func show_tab(state: Dictionary, which: StringName) -> bool:
	if which != BUY and which != SELL:
		return false
	(state["stall"] as Dictionary)["tab"] = which
	return true


## Put the day's stock out, if it has not been put out today.
##
## **Called from the tick, not from `open()`.** Opening the stall is a thing
## the player does as often as they like; the morning is not.
static func restock(state: Dictionary) -> bool:
	var stall: Dictionary = state["stall"]
	var today := int(state["day"])
	if int(stall["day"]) == today:
		return false
	stall["day"] = today
	stall["stock"] = _fresh_stock(season(state))
	return true


## New packet shelves in an old save start stocked; existing shelves keep
## their quantities, so loading cannot restock a shelf the player emptied.
static func reconcile_stock(state: Dictionary) -> Array:
	var added: Array = []
	var stock: Dictionary = state["stall"]["stock"]
	var table := GameData.stall_stock(season(state))
	for id in GameData.sorted_names(table.keys()):
		if not stock.has(id):
			stock[id] = int(table[id])
			added.append(id)
	return added


static func sell_price(id: StringName) -> int:
	return int(GameData.SELL_PRICE.get(id, 0))


## **What one of anything on the shelf costs**, as a cost dictionary (task
## 0190): money for a resource or an animal, the workshop's money and ore for
## a tool upgrade.
static func cost_of(id: StringName, n: int = 1) -> Dictionary:
	if GameData.is_tool_upgrade(id):
		return ((GameData.RECIPES[id] as Dictionary)["inputs"] as Dictionary).duplicate()
	return {GameData.MONEY: buy_price(id) * n}


## **The peddler's hours** (task 0190): whether the stall trades now - by
## day, from `STALL_OPENS` up to `STALL_CLOSES`.
static func open_hours(state: Dictionary) -> bool:
	if int(state["phase"]) != Phases.DAY:
		return false
	var minute := Phases.clock_minute(state)
	return minute >= GameData.STALL_OPENS and minute < GameData.STALL_CLOSES


## Why the `trade` verb is refused now: empty in hours, else the hours.
static func why_closed(state: Dictionary) -> Array:
	if open_hours(state):
		return []
	return [&"WHY_STALL_CLOSED", _clock(GameData.STALL_OPENS), _clock(GameData.STALL_CLOSES)]


static func _clock(minute: int) -> String:
	return "%02d:%02d" % [(minute / 60) % 24, minute % 60]


## What a sale actually pays: the stall's price, and whatever the tech tree
## has to say about it.
##
## **`sell_percent` was declared and read by nothing.** "A name at market"
## costs six points - the most expensive node in the production branch - and
## says everything you sell fetches a quarter more. It did not, until task
## 0106's checklist checked every node's effect against what reads it. One
## function rather than two call sites, so selling one and selling all cannot
## disagree about the price.
static func paid_for(state: Dictionary, id: StringName, n: int) -> int:
	return sell_price(id) * n \
		* Tech.bonus(state, "sell_percent", 100) / 100


## Packets use their crop's balanced seed cost; other goods use the markup.
## What the stall charges is always more than it pays, rounded up
## so that the markup cannot vanish on a cheap item - `headless_check` asserts
## the inequality for every sellable thing.
static func buy_price(id: StringName) -> int:
	# An animal's own price, and an upgrade's money (task 0190).
	if GameData.LIVESTOCK.has(id):
		return int(GameData.ANIMAL_PRICE.get(id, 0))
	if GameData.is_tool_upgrade(id):
		return int(cost_of(id).get(GameData.MONEY, 0))
	var crop := StringName(String(id).trim_suffix("_seed"))
	if String(id).ends_with("_seed") and GameData.CROPS.has(crop):
		return int(GameData.CROPS[crop]["seed_cost"])
	return int(ceil(float(sell_price(id)) * GameData.BUY_MARKUP))


static func is_open(state: Dictionary) -> bool:
	return StringName(state["open_panel"]) == &"shop"


## Open the stall. Called by `Interact.complete()` for the `trade` verb.
static func open(state: Dictionary) -> void:
	state["open_panel"] = &"shop"


## Close whatever is open. The cancel intent does this; so does walking away.
static func close(state: Dictionary) -> void:
	state["open_panel"] = &""


# ----------------------------------------------------------------- trading

## Sell `n` of something. Returns the money made, or 0 when it will not happen.
##
## **All or nothing**: selling ten wood when you have four sells none of them
## rather than four. A shop that quietly sold what it could would be a shop
## that emptied your bag when you fumbled a number.
static func sell(state: Dictionary, id: StringName, n: int) -> int:
	if n <= 0 or not GameData.SELL_PRICE.has(id):
		return 0
	if not Resources.spend(state, id, n):
		return 0
	var paid := paid_for(state, id, n)
	Resources.add(state, GameData.MONEY, paid)
	return paid


## Sell everything you have of one thing. The button people actually press.
static func sell_all(state: Dictionary, id: StringName) -> int:
	return sell(state, id, Resources.amount(state, id))


## Buy `n` of something. False when there is not the money for all of it.
static func buy(state: Dictionary, id: StringName, n: int) -> bool:
	if n <= 0:
		return false
	# **Not a resource** (task 0190): an animal into a home with room, or a
	# tool upgrade through the workshop's rules.
	if GameData.LIVESTOCK.has(id):
		return _buy_animals(state, id, n)
	if GameData.is_tool_upgrade(id):
		return n == 1 and _order_upgrade(state, id)
	if not buyable(state).has(id):
		return false
	# **All or nothing, against the stock as well as the purse.** Buying five
	# when three are left sells none of them rather than three, the same rule
	# as selling - a stall that quietly sold what it could would be a stall
	# that emptied your purse when you fumbled a number.
	if stock_of(state, id) < n:
		return false
	var cost := buy_price(id) * n
	if not Resources.pay(state, {GameData.MONEY: cost}):
		return false
	var stock: Dictionary = (state["stall"] as Dictionary)["stock"]
	stock[id] = int(stock.get(id, 0)) - n
	Resources.add(state, id, n)
	return true


## Whether `n` of this can be bought now. The panel greys a row on it.
static func can_buy(state: Dictionary, id: StringName, n: int = 1) -> bool:
	return n > 0 and why_not_buy(state, id, n).is_empty()


## **Why not**, for the tooltip of a greyed row (task 0190), in
## `Building.why_not`'s shape: empty when it can be bought.
static func why_not_buy(state: Dictionary, id: StringName, n: int = 1) -> Array:
	if GameData.is_tool_upgrade(id):
		if stock_of(state, id) < 1:
			return [&"WHY_SOLD_OUT"]
		return ToolTiers.why_not(state, id)
	if GameData.LIVESTOCK.has(id):
		if stock_of(state, id) < n:
			return [&"WHY_SOLD_OUT"]
		if Livestock.room_for(state, id) < n:
			return [&"WHY_NO_HOME", Livestock.home_of(id)]
	elif not buyable(state).has(id):
		return [&"WHY_SOLD_OUT"]
	elif stock_of(state, id) < n:
		return [&"WHY_SOLD_OUT"]
	var cost := {GameData.MONEY: buy_price(id) * n}
	if not Resources.can_afford(state, cost):
		return [&"WHY_SHORT", Resources.missing(state, cost)]
	return []


## **Animals, into homes with room** (task 0190): all of them or none, the
## money paid only when every one has somewhere to go. Each comes fed, the
## way one off the map does.
static func _buy_animals(state: Dictionary, kind: StringName, n: int) -> bool:
	if not why_not_buy(state, kind, n).is_empty():
		return false
	if not Resources.pay(state, {GameData.MONEY: buy_price(kind) * n}):
		return false
	var stock: Dictionary = (state["stall"] as Dictionary)["stock"]
	stock[kind] = int(stock.get(kind, 0)) - n
	for _i in n:
		Livestock.house(state, Livestock.home_with_room(state, kind), kind)
	return true


## **A tool upgrade from his pack** (task 0190): the workshop's order, by the
## same rule - `ToolTiers.why_not`, the recipe's money and ore - paid now and
## ready the next morning (`ToolTiers.deliver`), as the workshop's is.
static func _order_upgrade(state: Dictionary, recipe_id: StringName) -> bool:
	if not why_not_buy(state, recipe_id).is_empty():
		return false
	var recipe: Dictionary = GameData.RECIPES[recipe_id]
	if not Resources.pay(state, recipe["inputs"]):
		return false
	var stock: Dictionary = (state["stall"] as Dictionary)["stock"]
	stock[recipe_id] = int(stock.get(recipe_id, 0)) - 1
	ToolTiers.deliver(state, StringName((recipe["output"] as Dictionary).keys()[0]))
	return true


## What a whole bag is worth, for the "sell everything" summary of task 0040
## and for the autoplayer deciding whether a trip to the stall is worth it.
static func value_of_stock(state: Dictionary) -> int:
	var total := 0
	for id in sellable():
		total += paid_for(state, id, Resources.amount(state, id))
	return total
