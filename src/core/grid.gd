class_name Grid
extends RefCounted

## Cell arithmetic, and nothing else.
##
## No state, no farm, no game: just the conversions between a `Vector2i` cell
## and the flat index everything is stored under, plus the neighbourhood the
## flow field of task 0025 will walk. `Farm` is what knows what is on a cell.
##
## Flat indices rather than `Vector2i` keys throughout, because the terrain is
## a `PackedByteArray` and a dictionary of 720 vectors would be both slower and
## harder to hash the same way twice.

const WIDTH := GameData.GRID_WIDTH
const HEIGHT := GameData.GRID_HEIGHT
const CELLS := WIDTH * HEIGHT

## The four cardinal steps, in a fixed order.
##
## **The order is part of the rules.** A flow field breaks ties between equally
## short paths by whichever neighbour it looked at first, so the order below
## decides which way a zombie walks around a wall - and it has to be the same
## order on every machine and every run.
const STEPS: Array = [
	Vector2i(0, -1),        # north
	Vector2i(1, 0),         # east
	Vector2i(0, 1),         # south
	Vector2i(-1, 0),        # west
]

## The eight, for anything that spreads rather than walks - splash, fire, the
## autotiler. Same reasoning about the order.
const STEPS_8: Array = [
	Vector2i(0, -1), Vector2i(1, -1), Vector2i(1, 0), Vector2i(1, 1),
	Vector2i(0, 1), Vector2i(-1, 1), Vector2i(-1, 0), Vector2i(-1, -1),
]


static func in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < WIDTH and cell.y < HEIGHT


## The flat index of a cell. -1 when it is off the farm, so a caller that
## forgets to check gets an obvious wrong answer rather than a wrapped one.
static func index(cell: Vector2i) -> int:
	return cell.y * WIDTH + cell.x if in_bounds(cell) else -1


static func cell(idx: int) -> Vector2i:
	return Vector2i(idx % WIDTH, idx / WIDTH)


## The cells sharing an edge with this one, in `STEPS` order, clipped to the
## farm.
static func neighbours(c: Vector2i) -> Array:
	var out: Array = []
	for step in STEPS:
		var n: Vector2i = c + step
		if in_bounds(n):
			out.append(n)
	return out


## Steps between two cells if you may only move in the four directions. What
## "range" means for a tower, so that a diagonal does not quietly reach
## further than a straight line.
static func manhattan(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)


## The larger of the two axis distances: what "within N tiles" means when a
## diagonal should count the same as a straight line, which is how a splash
## radius reads on screen.
static func chebyshev(a: Vector2i, b: Vector2i) -> int:
	return maxi(absi(a.x - b.x), absi(a.y - b.y))


## Every cell within `radius`, nearest first and then in a fixed order.
##
## Sorted so that a splash resolving against several targets always resolves in
## the same order, whatever order they were spawned in.
static func within(centre: Vector2i, radius: int) -> Array:
	var out: Array = []
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			var c := centre + Vector2i(dx, dy)
			if in_bounds(c) and chebyshev(centre, c) <= radius:
				out.append(c)
	return out
