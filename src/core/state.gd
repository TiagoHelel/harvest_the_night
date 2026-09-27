class_name State
extends RefCounted

## The whole game, as plain data.
##
## `Dictionary` and `Array` of primitives, and nothing else. That is what lets
## it be deep-copied, hashed, written to a save file and diffed between two
## runs - and it is the reason `src/core/` may not hold a node. Put an object in
## here and the save, the hash guard and the autoplayer all stop working on the
## same afternoon.
##
## Keys are Strings. Access is `state["tick"]`, spelled out rather than
## `state.tick`, so a typo is a missing key at the call site instead of a silent
## new one.

## Bumped whenever the shape changes. Task 0010 hangs the save migrations off
## it; until then it exists so that the first save has something to migrate
## from.
const VERSION := 1

const _FNV_OFFSET := 2166136261
const _FNV_PRIME := 16777619
const _MASK := 0xFFFFFFFF


## A new game.
##
## Each subsystem contributes the keys it owns through its own `initial()`, so
## that adding one is an edit in that file plus a line here, rather than a
## growing literal nobody can find their way around.
static func create(seed_value: int) -> Dictionary:
	var state := {
		"version": VERSION,
		"seed": seed_value,
		"tick": 0,
		"rng": Rng.create(seed_value),
	}
	state.merge(Phases.initial())
	state.merge(Resources.initial())
	state.merge(Farm.initial())
	return state


## A deep copy, safe to simulate forward without touching the original.
##
## What the "what if I placed it here" preview will run on, and what the
## headless tests compare against.
static func copy(state: Dictionary) -> Dictionary:
	return state.duplicate(true)


## One integer that stands for the entire state.
##
## The determinism guard is this number: two runs of the same seed that end with
## the same hash did the same thing, and a task that moves it changed a rule -
## deliberately, and recorded in the journal, or by accident, which is a bug.
static func hash_of(state: Dictionary) -> int:
	return _fold(_FNV_OFFSET, state)


static func _fold(h: int, value: Variant) -> int:
	match typeof(value):
		TYPE_DICTIONARY:
			# **Sorted keys.** Dictionary iteration follows insertion order, so
			# two states that are equal in every value can still be built in
			# different orders. Sorting is what makes this a hash of the state
			# rather than a hash of how the state was assembled.
			var d: Dictionary = value
			var keys: Array = d.keys()
			keys.sort()
			for k in keys:
				h = _fold(h, k)
				h = _fold(h, d[k])
		TYPE_ARRAY:
			# Arrays keep their order: in an array, order is data.
			for item in (value as Array):
				h = _fold(h, item)
		_:
			h = _bytes(h, str(value))
	return h


static func _bytes(h: int, s: String) -> int:
	for b in s.to_utf8_buffer():
		h = (h ^ b) & _MASK
		h = (h * _FNV_PRIME) & _MASK
	return h
