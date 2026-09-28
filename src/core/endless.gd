class_name Endless
extends RefCounted

## Night eleven and everything after it, written by a curve.
##
## For the player who beat the Giant and wants to know how far the farm goes.
## `design.md` does not describe endless at all - it is scoped to the ten
## authored nights - so the shape here follows task 0070 and says so in the
## journal.
##
## ## It produces the same record a person would have written
##
## `night()` returns exactly what a row of `GameData.NIGHTS` is: a note, an
## opening delay, a gap, and a list of `[kind, count, spawn]` waves. That is
## the whole of the integration. `Waves.night_of()` hands back a generated
## record past the tenth night and every function downstream of it -
## `table`, `size_of`, `reward_of`, `kinds_of`, `spawns_of`, `summary_of`,
## `delay_before`, and the tick that sends them - carries on without knowing.
## Nothing in `Enemies`, `Rewards`, `Towers` or the HUD needed a line about
## endless, and `tools/nights.py` can print night 25 because it already knew
## how to print a night.
##
## ## Seeded, and not from the run's stream
##
## Two runs of the same seed must meet the same night 25, and a night must be
## the same whether it is generated when it starts, when the HUD asks how many
## are left, or when a tool prints a table of forty of them. So the stream is
## made fresh from `(run seed, night number)` every time, with `Rng.create()`,
## and the run's own stream is never touched.
##
## Drawing from the run's stream instead would have been quietly catastrophic:
## `Waves.remaining()` is asked every tick by the night HUD, and a pure
## question that advanced the run's RNG would make the answer depend on how
## often somebody looked at the screen.
##
## **`RandomNumberGenerator` is banned in `src/core/`** for the reason `Rng`
## gives, and this file is not an exception to it: `Rng.create()` returns a
## plain four-word array that is as saveable and as hashable as any other, and
## this one simply is not kept.
##
## ## The curve decides what comes; the seed decides how it arrives
##
## Two runs meeting night 25 meet the same crowd - 240 bodies, two Giants, the
## same count of each kind - because that is the difficulty contract, and a
## night that was harder on an unlucky seed would make "how far did you get"
## mean nothing. What the seed changes is the **order**: which kind opens, how
## the heavy waves interleave, and which side the night starts on. Thirty
## seeds of night 25 produce twenty-one different wave tables that all sum to
## the same thing.
##
## So `Waves.summary_of(25, a)` and `Waves.summary_of(25, b)` print the same
## line, because a summary aggregates by kind. That is not the seed doing
## nothing; it is the summary not being the place to look.
##
## ## What the curve does and does not do
##
## It scales how many arrive and shifts what they are. It never invents an
## enemy: every kind comes from `GameData.ENDLESS.mix`, which `validate()`
## refuses unless every name in it is a real, non-boss entry of
## `GameData.ENEMIES`. The Giant is not in the mix - it arrives on its own
## schedule, every fifth night, one more every tenth - because a boss rolled
## out of a weighted bag would turn up on night eleven.


## Whether this night is written by the curve rather than by a person.
static func is_generated(night: int) -> bool:
	return night > GameData.MVP_NIGHTS


## How far past the authored ten this night is. Night 11 is the first step.
static func step_of(night: int) -> int:
	return maxi(night - GameData.MVP_NIGHTS, 0)


## The whole record for a generated night: the same shape `GameData.NIGHTS`
## holds, so nothing downstream can tell it was not typed by hand.
static func night(seed_value: int, night_number: int) -> Dictionary:
	if not is_generated(night_number):
		return {}
	var curve: Dictionary = GameData.ENDLESS
	var step := step_of(night_number)
	var rng := Rng.create(_stream_for(seed_value, night_number))

	var waves := _waves(curve, step)
	var bodies := _share_out(_size(curve, night_number), _weights(curve, step))
	var rows := _lay_out(rng, bodies, waves)
	_put_the_giants_in(rows, curve, night_number)

	return {
		"note": _note(night_number, giants_on(night_number)),
		"opening_ticks": int(curve["opening_ticks"]),
		"gap_ticks": int(curve["gap_ticks"]),
		"waves": rows,
	}


## How many bodies a generated night sends, before the Giants are added.
##
## **Added per night, not compounded.** See the note on `GameData.ENDLESS`.
static func size_of(night_number: int) -> int:
	return _size(GameData.ENDLESS, night_number)


## How many Giants a night brings. Zero on most of them.
static func giants_on(night_number: int) -> int:
	if not is_generated(night_number):
		return 0
	var curve: Dictionary = GameData.ENDLESS
	var every := maxi(int(curve["giant_every"]), 1)
	if night_number % every != 0:
		return 0
	var extra := maxi(int(curve["giant_extra_every"]), 1)
	return 1 + step_of(night_number) / extra


# ------------------------------------------------------------------ the curve

static func _size(curve: Dictionary, night_number: int) -> int:
	var base := Waves.size_of(GameData.MVP_NIGHTS)
	var grown := 100 + int(curve["growth_percent"]) * step_of(night_number)
	return maxi(base * grown / 100, 1)


static func _waves(curve: Dictionary, step: int) -> int:
	var every := maxi(int(curve["extra_wave_every"]), 1)
	return maxi(int(curve["waves"]) + step / every, 1)


## Each kind's weight tonight.
##
## **The drift settles after `mix_settles_after` nights**, and a floor of one
## is not a substitute for that. The first version only clamped at one and it
## measured badly: by night 99 the walker's weight had been at its floor for
## seventy nights and the night sent one of them against 386 breakers. A kind
## that is one body in a thousand has left the game; settling keeps the late
## mix heavy *and* varied, which is what "scales the mix" should mean.
static func _weights(curve: Dictionary, step: int) -> Dictionary:
	var settled := mini(step, maxi(int(curve["mix_settles_after"]), 0))
	var out := {}
	var mix: Dictionary = curve["mix"]
	for kind in GameData.sorted_names(mix.keys()):
		var pair: Array = mix[kind]
		out[kind] = maxi(int(pair[0]) + int(pair[1]) * settled, 1)
	return out


## Split `total` bodies between the kinds in proportion to their weights.
##
## Sorted keys and integer arithmetic, so the same weights always give the
## same answer. Whatever the division leaves over goes to the heaviest kind,
## which is the one the rounding hurt most.
static func _share_out(total: int, weights: Dictionary) -> Dictionary:
	var kinds := GameData.sorted_names(weights.keys())
	var sum := 0
	for kind in kinds:
		sum += int(weights[kind])
	if sum <= 0 or kinds.is_empty():
		return {}

	var out := {}
	var handed := 0
	var heaviest: StringName = StringName(kinds[0])
	for kind in kinds:
		var mine := total * int(weights[kind]) / sum
		out[kind] = mine
		handed += mine
		if int(weights[kind]) > int(weights[heaviest]):
			heaviest = StringName(kind)
	out[heaviest] = int(out[heaviest]) + (total - handed)
	return out


# ------------------------------------------------------------- the wave list

## Deal the night's bodies out into waves.
##
## One kind per wave, the way the authored nights are written - a wave is a
## thing arriving, not an assortment - and the kinds are dealt round-robin so
## that the hard ones are not all saved for the end.
##
## **The sides alternate, and the seed only picks which one starts.** Rolling
## each wave's side independently looked more varied and was worse: night 20
## came out of the generator with all seven of its waves on the east edge,
## which is a night you can answer with half a farm. Every authored night from
## the second onward comes from both sides, and this is not the place to
## quietly take that back on a one-in-a-hundred roll.
static func _lay_out(rng: Array, bodies: Dictionary, waves: int) -> Array:
	var queue: Array = []
	for kind in GameData.sorted_names(bodies.keys()):
		if int(bodies[kind]) > 0:
			queue.append([StringName(kind), int(bodies[kind])])
	if queue.is_empty():
		return [[&"walker", 1, 0]]

	# **The seed decides the order the kinds are dealt in**, and it has to
	# decide something. Before this, the only thing it chose was which side
	# the night opened on - so two seeds produced the same night 25 half the
	# time, which is not what "seeded" means. Shuffling the deal changes what
	# opens the night and how the heavy kinds interleave, and it cannot change
	# the totals or lose the alternating sides, so it is variation that costs
	# the curve nothing.
	_shuffle(rng, queue)

	# How many waves each kind gets, in proportion to how many of it there are.
	var rows: Array = []
	var slots := maxi(waves, queue.size())
	var share: Array = []
	var total := 0
	for entry in queue:
		total += int((entry as Array)[1])
	for entry in queue:
		share.append(maxi(slots * int((entry as Array)[1]) / maxi(total, 1), 1))

	# Deal them out one slot at a time, round-robin, so a night opens with
	# something ordinary and the heavier kinds are spread through it.
	var left: Array = []
	for i in queue.size():
		left.append(int((queue[i] as Array)[1]))
	var placed: Array = []
	for _i in queue.size():
		placed.append(0)
	var spawns: int = maxi((GameData.SPAWNS as Array).size(), 1)
	var side := Rng.int_between(rng, 0, spawns - 1)
	var guard := 0
	while guard < 200:
		guard += 1
		var sent_any := false
		for i in queue.size():
			if left[i] <= 0 or placed[i] >= int(share[i]):
				continue
			var slots_left: int = int(share[i]) - int(placed[i])
			var count: int = maxi(int(left[i]) / maxi(slots_left, 1), 1)
			count = mini(count, int(left[i]))
			rows.append([(queue[i] as Array)[0], count, side % spawns])
			side += 1
			left[i] = int(left[i]) - count
			placed[i] = int(placed[i]) + 1
			sent_any = true
		if not sent_any:
			break

	# Anything the division left behind joins the last wave of its kind, so
	# the night sends exactly what `size_of()` promised.
	for i in queue.size():
		if left[i] <= 0:
			continue
		var kind: StringName = (queue[i] as Array)[0]
		var found := false
		for r in range(rows.size() - 1, -1, -1):
			if StringName((rows[r] as Array)[0]) == kind:
				(rows[r] as Array)[1] = int((rows[r] as Array)[1]) + left[i]
				found = true
				break
		if not found:
			rows.append([kind, int(left[i]), side % spawns])
			side += 1
		left[i] = 0
	return rows


## Fisher-Yates, off the run's own generator rather than `Array.shuffle()`,
## which draws from the global stream that `Rng` exists to keep out of here.
static func _shuffle(rng: Array, items: Array) -> void:
	for i in range(items.size() - 1, 0, -1):
		var j := Rng.int_between(rng, 0, i)
		var held: Variant = items[i]
		items[i] = items[j]
		items[j] = held


## The Giants, on the nights that have them.
##
## **Third from last, not last.** The authored tenth night puts its Giant in
## the middle of the crowd on purpose - "a Giant that arrived alone would be a
## duel; arriving third, with runners behind it, is a test of the whole build"
## - and a generated night that ended on the boss would undo that.
static func _put_the_giants_in(rows: Array, curve: Dictionary,
		night_number: int) -> void:
	var giants := giants_on(night_number)
	if giants <= 0 or rows.is_empty():
		return
	var _unused: Dictionary = curve
	var at := maxi(rows.size() - 2, 0)
	rows.insert(at, [&"giant", giants, 0])


## What the night calls itself, in the same voice as the authored ten.
static func _note(night_number: int, giants: int) -> String:
	if giants == 1:
		return "past the ten: the Giant is back, and it brought the night"
	if giants > 1:
		return "past the ten: %d Giants, which is the question answered" \
			% giants
	return "past the ten: night %d, and more of everything that hurt" \
		% night_number


## A stream of this night's own, mixed from the run's seed and the night.
##
## Mixed rather than added, so that seed 11 night 12 and seed 12 night 11 are
## not the same night. The constants are the ones `Rng` already uses on the
## way in, which is enough for a wave table and is not pretending to be more.
static func _stream_for(seed_value: int, night_number: int) -> int:
	var h := (seed_value ^ 0x9E3779B9) & 0xFFFFFFFF
	h = (h * 16777619) & 0xFFFFFFFF
	h = (h ^ (night_number * 2654435761)) & 0xFFFFFFFF
	h = (h * 16777619) & 0xFFFFFFFF
	return h
