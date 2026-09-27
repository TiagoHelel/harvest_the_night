class_name Rng
extends RefCounted

## The only source of randomness the rules may use.
##
## `randi()`, `randf()` and `RandomNumberGenerator` are banned in `src/core/`.
## They draw from a global stream nobody can save, which would mean a reloaded
## save and a replayed night diverge from the original - and the autoplayer,
## the hash guard and the skip-the-night button all depend on them not doing
## that.
##
## The generator is xorshift128 over four 32-bit words. Every intermediate value
## is masked back into 32 bits, so nothing is ever negative and `>>` is never an
## arithmetic shift on a sign bit: that is the trap that makes most GDScript
## PRNG ports disagree with themselves, and masking is cheaper than debugging
## it. The state is a plain `Array` of four ints, so it saves, loads, copies and
## hashes with the rest of the state.
##
## Every function takes that array and mutates it in place - arrays are passed
## by reference - so a draw always advances the stream the state carries, and
## there is no way to take a number without recording that you did.

const MASK := 0xFFFFFFFF
const RANGE := 0x100000000          # 2^32, the number of values next_u32 gives


## A fresh four-word stream from one integer seed.
##
## The seed goes through splitmix32 first: a seed of 1 and a seed of 2 must not
## produce streams that look related for the first few draws, and feeding small
## numbers straight into xorshift does exactly that.
static func create(seed_value: int) -> Array:
	var s := seed_value & MASK
	var words: Array = []
	for _i in 4:
		s = (s + 0x9E3779B9) & MASK
		var z := s
		z = ((z ^ (z >> 16)) * 0x21F0AAAD) & MASK
		z = ((z ^ (z >> 15)) * 0x735A2D97) & MASK
		words.append((z ^ (z >> 15)) & MASK)
	# xorshift128 has one dead state and it is all zeroes.
	if words[0] == 0 and words[1] == 0 and words[2] == 0 and words[3] == 0:
		words[0] = 1
	return words


## The next raw draw, in [0, 2^32).
static func next_u32(rng: Array) -> int:
	var t: int = rng[0] ^ ((rng[0] << 11) & MASK)
	rng[0] = rng[1]
	rng[1] = rng[2]
	rng[2] = rng[3]
	var w: int = rng[3]
	rng[3] = (w ^ (w >> 19) ^ (t ^ (t >> 8))) & MASK
	return rng[3]


## An integer in [low, high], both ends included.
##
## Named `int_between` rather than `randi_range` on purpose. GDScript has a
## global `randi_range(from, to)`, and a static method of the same name loses to
## it at the call site inside this very file - silently, until the parser
## complains about the argument count. Keeping the names distinct also means
## `grep -rE 'randi|randf|Time\.' src/core/` should find **nothing at all**,
## which is a cleaner guarantee than "only the one file".
##
## Rejection sampling rather than a bare modulo: taking `% span` directly makes
## the low end of the range very slightly more likely, and "very slightly" over
## a ten night run is a bias the balance sweep would chase for an afternoon.
static func int_between(rng: Array, low: int, high: int) -> int:
	if high <= low:
		return low
	var span := high - low + 1
	var limit := RANGE - (RANGE % span)
	var v := next_u32(rng)
	while v >= limit:
		v = next_u32(rng)
	return low + (v % span)


## True `numerator` times out of `denominator`.
##
## Integer odds rather than a float probability, because the rules should stay
## out of floating point wherever they can: two machines agreeing on `3 in 20`
## is free, and agreeing on `0.15` is only nearly free.
static func chance(rng: Array, numerator: int, denominator: int) -> bool:
	if numerator <= 0:
		return false
	if numerator >= denominator:
		return true
	return int_between(rng, 1, denominator) <= numerator


## One element of `options`, or null when it is empty.
static func pick(rng: Array, options: Array) -> Variant:
	if options.is_empty():
		return null
	return options[int_between(rng, 0, options.size() - 1)]


## A float in [0, 1).
##
## Here for the view layer and for tooling. **Prefer `int_between` or `chance`
## in the rules**: the whole point of the integer generator above is that the
## rules never have to trust a float to be the same on two machines. Named
## `unit_float` for the same reason `int_between` is not `randi_range`.
static func unit_float(rng: Array) -> float:
	return float(next_u32(rng)) / float(RANGE)
