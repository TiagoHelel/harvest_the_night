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
## Nothing pauses. Crops grow and the workshop keeps working while the player
## haggles, because `design.md` section 13 is about a farm that runs itself and
## a shop that stopped the world would be the one place it did not.


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
static func buyable() -> Array:
	return [GameData.WOOD, GameData.STONE, GameData.IRON]


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
	var cost := buy_price(id) * n
	if not Resources.pay(state, {GameData.MONEY: cost}):
		return false
	Resources.add(state, id, n)
	return true


## What a whole bag is worth, for the "sell everything" summary of task 0040
## and for the autoplayer deciding whether a trip to the stall is worth it.
static func value_of_stock(state: Dictionary) -> int:
	var total := 0
	for id in sellable():
		total += sell_price(id) * Resources.amount(state, id)
	return total
