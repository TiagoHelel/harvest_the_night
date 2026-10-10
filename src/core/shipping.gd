class_name Shipping
extends RefCounted

## The shipping bin (task 0189; plan section 3.6): drop things in at any hour
## of the day and be paid the next morning, so selling no longer waits on the
## stall's hours.
##
## ## A fixture, like the stall
##
## The bin stands on the site 0156 kept clear by the porch, laid by
## `FARM_MAP` and in `Farm.FIXTURES`: never sold, never wrecked, nothing a
## breaker comes for. A thing the farm has from the first morning rather than
## something to build - a player who had to buy the bin would first have to
## know it exists. Older saves get it from `Save`'s step up from version 8.
##
## ## What waits is sold, not stock
##
## `state["shipping"]` is resource -> count, and putting a stack in takes it
## out of `held` at once: what is in the bin is no longer the farmer's to lose.
## A lost night takes a quarter of the stock (`Rewards`), and the bin is not
## stock - the morning pays for every last carrot in it (decided).
##
## ## A panel, and the day stops while it is open
##
## `ship` opens it the way `trade` opens the stall: `open_panel` says so, and
## `Sim._tick_day` holds the clock while any panel is up. Choosing what to sell
## out of a full bag is the same conversation as at the stall, only with
## nobody behind the counter, and a player who stopped to think should not
## come back to a dead field (decided).
##
## ## Paid at dawn
##
## `Phases.begin_day` calls `pay()`: every stack at `Shop.paid_for` - the
## stall's price and the tech tree's `sell_percent` - and the bin empties. The
## morning report shows `due()`, the same sum, in RESULT before the money
## lands, so the line and the purse cannot disagree.

## What `open_panel` says while the bin is open.
const PANEL := &"bin"

## The bin's occupant id, on the map since task 0189.
const BIN := &"shipping_bin"


static func initial() -> Dictionary:
	# {resource: how many wait in the bin}. Keys come from play.
	return {"shipping": {}}


## Whether the bin's panel is open.
static func is_open(state: Dictionary) -> bool:
	return StringName(state["open_panel"]) == PANEL


## Open the bin. Called by `Interact.complete()` for the `ship` verb.
static func open(state: Dictionary) -> void:
	state["open_panel"] = PANEL


## What waits in the bin, as resource -> count.
static func waiting(state: Dictionary) -> Dictionary:
	return state["shipping"]


## How many of this wait in the bin.
static func count(state: Dictionary, id: StringName) -> int:
	return int((state["shipping"] as Dictionary).get(id, 0))


## Whether the bin takes this: anything the stall would buy.
static func takes(id: StringName) -> bool:
	return GameData.SELL_PRICE.has(id)


## Put `n` of something in. **All or nothing**, as at the stall: putting ten
## wood in when you have four puts none of them in.
static func put(state: Dictionary, id: StringName, n: int) -> bool:
	if n <= 0 or not takes(id):
		return false
	if not Resources.spend(state, id, n):
		return false
	var bin: Dictionary = state["shipping"]
	bin[id] = int(bin.get(id, 0)) + n
	return true


## Put everything you have of one thing in. The button people actually press.
static func put_all(state: Dictionary, id: StringName) -> bool:
	return put(state, id, Resources.amount(state, id))


## What the bin will pay in the morning: every stack at `Shop.paid_for`, in
## name order.
static func due(state: Dictionary) -> int:
	var total := 0
	var bin: Dictionary = state["shipping"]
	for id in GameData.sorted_names(bin.keys()):
		total += Shop.paid_for(state, StringName(id), int(bin[id]))
	return total


## Pay for what waits and empty the bin, from `Phases.begin_day`. Returns the
## money it paid.
static func pay(state: Dictionary) -> int:
	var total := due(state)
	(state["shipping"] as Dictionary).clear()
	if total > 0:
		Resources.add(state, GameData.MONEY, total)
		Events.add(state, &"shipped", {"money": total})
	return total
