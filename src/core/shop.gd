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


## The flat daily shelf: materials, the original harvested crops and every
## seed packet. Seasonal stock belongs to the peddler pass in 0190.
static func buyable() -> Array:
	return GameData.sorted_names(GameData.DAILY_STOCK.keys())


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
			"stock": _fresh_stock(),
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


## A full day's worth of everything the stall carries.
static func _fresh_stock() -> Dictionary:
	var stock := {}
	for id in GameData.sorted_names(GameData.DAILY_STOCK.keys()):
		stock[id] = int(GameData.DAILY_STOCK[id])
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
	stall["stock"] = _fresh_stock()
	return true


## New packet shelves in an old save start stocked; existing shelves keep
## their quantities, so loading cannot restock a shelf the player emptied.
static func reconcile_stock(state: Dictionary) -> Array:
	var added: Array = []
	var stock: Dictionary = state["stall"]["stock"]
	for id in buyable():
		if not stock.has(id):
			stock[id] = int(GameData.DAILY_STOCK[id])
			added.append(id)
	return added


static func sell_price(id: StringName) -> int:
	return int(GameData.SELL_PRICE.get(id, 0))


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
	if n <= 0 or not buyable().has(id):
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


## What one more of this would cost, or 0 when there is none left.
static func can_buy(state: Dictionary, id: StringName, n: int = 1) -> bool:
	if n <= 0 or not buyable().has(id) or stock_of(state, id) < n:
		return false
	return Resources.can_afford(state,
		{GameData.MONEY: buy_price(id) * n})


## What a whole bag is worth, for the "sell everything" summary of task 0040
## and for the autoplayer deciding whether a trip to the stall is worth it.
static func value_of_stock(state: Dictionary) -> int:
	var total := 0
	for id in sellable():
		total += paid_for(state, id, Resources.amount(state, id))
	return total
