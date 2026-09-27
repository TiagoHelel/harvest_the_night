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


## What the stall will sell you.
##
## Raw materials only, and at a markup: this is for the night you are three
## stone short at dusk, not for a way to skip the day. Task 0040 stocks it
## properly and gives it a daily limit.
## What the stall will sell you: whatever it has in today.
##
## Materials for the night you are three stone short at dusk, and the three
## crops for the evening you are two corn short of gunpowder. Not oil, not
## gunpowder, not food - **nothing the workshop makes**, because a stall that
## sold the output of your own machines would be a way to skip owning them.
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


static func sell_price(id: StringName) -> int:
	return int(GameData.SELL_PRICE.get(id, 0))


## What the stall charges. Always more than it pays, at every price, rounded up
## so that the markup cannot vanish on a cheap item - `headless_check` asserts
## the inequality for every sellable thing.
static func buy_price(id: StringName) -> int:
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
	var paid := sell_price(id) * n
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
		total += sell_price(id) * Resources.amount(state, id)
	return total
