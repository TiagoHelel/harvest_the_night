class_name Sfx
extends Node

## Watches the day happen and asks `Audio` for the noise it made.
##
## **The rules do not know sound exists.** `src/core/` records what happened
## and this reads it, exactly as `particles.gd` reads it to throw sparks. That
## is what keeps a volume slider out of the determinism hash, and it is why
## there is no `Audio.play()` anywhere in `src/core/`.
##
## ## How a finished verb is spotted from outside
##
## A working verb lives in `state["player"]["action"]` as
## `{verb, cell, left, total}`, and `left` falls by one every tick while
## `state["tick"]` rises by one. So **`left + tick` is the tick the cycle is
## due to finish on, and it does not move while the cycle runs.** That one
## invariant answers both awkward questions exactly:
##
## - The due tick jumping forward means a cycle finished and the verb went
##   round again - which is what chopping a tree is, twenty times over.
## - An action that vanished finished if the clock had reached its due tick,
##   and was **interrupted** if it had not. Walking away mid-swing is not a
##   sound, and without this it would be one.
##
## Guessing from "the action disappeared and `left` was small" would have been
## a fudge that failed at four times speed. This is arithmetic.
##
## ## What the action cannot see
##
## Watering is on `Interact.INSTANT`: it never creates an action, because a
## held key has to water a whole row as the player walks it. So it is spotted
## by counting watered plots instead. The bite has no verb at all - it is a
## window opening - and the sale is money arriving while the stall is open.
##
## ## The night, and why fifty zombies are not fifty groans
##
## A shot is a tower whose `reload` went **up**: it counts down, so a rise is
## the tick it fired on, read off the rules rather than guessed from a
## projectile. Impacts, deaths and wrecks are the edges `particles.gd`
## already watches, for the same reasons and with the same caveat - missing
## one costs a noise and nothing else.
##
## Groans are **per kind and not per body**. Fifty walkers do not groan fifty
## times; the walkers groan, now and then, from wherever the nearest one is.
## That is the whole of "fifty zombies do not turn into noise": the rate is
## fixed by how many *sorts* of thing are out there, which is at most five,
## and `input_check` asserts that ten times the crowd is not ten times the
## sound.

## Verb -> the sound it makes. A verb absent from here is deliberately silent:
## `repair` is the night's and belongs to task 0085, and asking for a sound
## that does not exist would put a warning in the log on every swing.
const VERB_SOUNDS := {
	&"chop": &"sfx/chop",
	&"mine": &"sfx/mine",
	&"till": &"sfx/till",
	&"plant": &"sfx/plant",
	&"harvest": &"sfx/harvest",
	&"collect": &"sfx/collect",
	# **Their own since task 0281**, where they had borrowed: a pig's truffle
	# dug up (0185), bone meal into the furrow (0222), and the shipping bin's
	# lid and drop (0189) - not the stall's coins, since nothing is paid until
	# dawn.
	&"dig": &"sfx/dig",
	&"fertilise": &"sfx/fertilise",
	&"craft": &"sfx/craft",
	&"trade": &"sfx/trade",
	&"ship": &"sfx/ship",
	&"fish": &"sfx/cast",
	&"reel": &"sfx/reel",
}

## **What the thing under the verb sounds like** (task 0281), asked before
## `VERB_SOUNDS` with the cell the action carries: the cliff's metals (0176)
## each ring as their ore, and each artisan machine (0187, 0188) sounds like
## itself when a job goes in. A target absent from here falls back to its
## verb's sound - a plain rock is `mine`, the workshop is `craft`.
const TARGET_SOUNDS := {
	&"copper_ore": &"sfx/mine_copper",
	&"coal_seam": &"sfx/mine_coal",
	&"gold_ore": &"sfx/mine_gold",
	&"keg": &"sfx/keg",
	&"preserves_jar": &"sfx/preserves_jar",
	&"dairy": &"sfx/dairy",
	&"loom": &"sfx/loom",
	&"mill": &"sfx/mill",
}

const WATER_SOUND := &"sfx/water"
const BITE_SOUND := &"sfx/bite"
const SELL_SOUND := &"sfx/sell"

## The smith's anvil, when a tool upgrade is ordered (task 0281). Furniture:
## short and soft, under the bite.
const ANVIL_SOUND := &"sfx/anvil"

## **0180's bar, by ear** (task 0282), all furniture under the bite:
## - the tick as the marker **enters the green** - the moment to press. The
##   turn at an end of the bar would be a metronome that says nothing about
##   the fish; the green is the one thing a press is judged against;
## - a hit or a miss off the press the line keeps (`last`, which
##   `Fishing.strike` writes for an assisted press as for any other);
## - the catch when the cast ends with a species landed - under the reel,
##   `VERB_SOUNDS`' `sfx/reel`, kept as the line coming in. A legendary
##   (0182) plays `LEGEND_SOUND` instead of the catch: a cue on the Music bus,
##   the year's motif answering the one catch a run gets of each.
const TICK_SOUND := &"sfx/fish_tick"
const HIT_SOUND := &"sfx/fish_hit"
const MISS_SOUND := &"sfx/fish_miss"
const CATCH_SOUND := &"sfx/fish_catch"
const LEGEND_SOUND := &"music/fanfare"

## **The day's moments** (task 0281), heard from the state: the bed and the
## floor at 02:00 as the day ends, the stretch at 06:00, ONE coins sound when
## the bin is paid at dawn, the peddler's bell as his hours begin and end, and
## the ting of a tool handed over. Once or twice a day each, so they are
## `gen_sfx.py`'s `MOMENT_SOUNDS`: longer than furniture, under the alarm.
const BED_SOUND := &"sfx/bed"
const WAKE_SOUND := &"sfx/wake"
const PASS_OUT_SOUND := &"sfx/pass_out"
const PAYOUT_SOUND := &"sfx/payout"
const BELL_SOUND := &"sfx/stall_bell"
const TOOL_READY_SOUND := &"sfx/tool_ready"
const MOMENT_SOUNDS: Array = [BED_SOUND, WAKE_SOUND, PASS_OUT_SOUND,
	PAYOUT_SOUND, BELL_SOUND, TOOL_READY_SOUND]

## What each defence sounds like when it goes off. A defence absent from here
## does not fire - a wall, a fence and a barricade are furniture.
const TOWER_SOUNDS := {
	&"gun_tower": &"sfx/shot_gun",
	&"auto_crossbow": &"sfx/shot_bolt",
	&"flame_tower": &"sfx/flame",
	&"mortar": &"sfx/mortar",
	&"mine": &"sfx/mine_blast",
	# **Their own since task 0283**, where 0226 and 0227 borrowed the flame's
	# hiss and the mortar's thump: a swarm leaving the hive - heard per kind,
	# from the nearest hive that stung (`PER_KIND_SHOTS`) - and the
	# catapult's arm.
	&"beehive": &"sfx/buzz",
	&"catapult": &"sfx/catapult",
}

## **A shot heard per kind, not per structure** (task 0283): ten hives that
## sting on one tick are one swarm, from the nearest of them, as the groans
## are one voice a kind.
const PER_KIND_SHOTS: Array = [&"beehive"]

## **What a defence without `damage` sounds like** (task 0283) - kept out of
## `TOWER_SOUNDS`, which is exactly the defences that shoot: the decoy's straw
## when it is bitten, the searchlight's hum (per kind, from the nearest lit
## lamp) and the electric fence's zap when it stuns.
const DEFENCE_SOUNDS := {
	&"decoy": &"sfx/straw",
	&"searchlight": &"sfx/hum",
	&"electric_fence": &"sfx/zap",
}

## A pumpkin landing where it was thrown (task 0283): the catapult's shell is
## in the state as a ballistic projectile, so its landing can be heard there.
const SPLAT_SOUND := &"sfx/splat"

## **The cursor's hand** (task 0283), quieter than the weapons and played at
## its cell: a defence put down, a level gained, hit points put back - on a
## defence or the house, in the build step and the night, never the fill
## `begin_night` gives the house - and a defence sold back. A defence gone
## with rubble on its cell broke, one gone without was sold
## (`vanished_as`).
const PLACE_SOUND := &"sfx/place"
const UPGRADE_SOUND := &"sfx/upgrade"
const MEND_SOUND := &"sfx/mend"
const SELL_BACK_SOUND := &"sfx/sell_back"

## **START** (task 0283): the build step giving way to the waves, once a
## night, heard everywhere and ducking the rest.
const HORN_SOUND := &"sfx/horn"

## **The powers** (tasks 0232, 0233), each when its cooldown rises - the
## reading `_watch_towers` uses for `reload` - at the cell it was aimed at.
## The bell stops every zombie on the farm and is heard with no position.
## The dog's bite lands when its run does.
const POWER_SOUNDS := {
	&"flare": &"sfx/power_flare",
	&"farm_bell": &"sfx/farm_bell",
	&"call_dog": &"sfx/dog_bark",
	&"emergency_repair": &"sfx/power_mend",
}
const DOG_BITE_SOUND := &"sfx/dog_bite"

## How often the nearest lit searchlight hums, on average, and the shortest
## gaps for the night's per-kind and per-cell noises, in frames.
const HUM_EVERY_SECONDS := 3.5
const HUM_GAP := 60
const BUZZ_GAP := 20
const ZAP_GAP := 6
const STRAW_GAP := 10

## One voice each, so a crowd is a chord rather than a wall - **every one its
## own since task 0284**, where 0247-0255 borrowed the first five's.
const ENEMY_SOUNDS := {
	&"walker": &"sfx/groan_walker",
	&"runner": &"sfx/groan_runner",
	&"tank": &"sfx/groan_tank",
	&"breaker": &"sfx/groan_breaker",
	&"giant": &"sfx/roar_giant",
	&"spitter": &"sfx/voice_spitter",
	&"rat": &"sfx/squeak",
	&"crow": &"sfx/caw",
	&"digger": &"sfx/rumble",
	&"frost_zombie": &"sfx/voice_frost",
	# **From nowhere** (`UNPLACED_VOICES`): a wraith outside light cannot be
	# shot (0252), and a whisper with a position would say where the eyes
	# cannot - so it says they are out, and not where.
	&"wraith": &"sfx/whisper",
	&"harvester": &"sfx/engine",
	&"scarecrow_king": &"sfx/king_call",
	&"winter_lord": &"sfx/lord_ice",
}

## The voices heard with no position (task 0284): the wraith's whisper.
const UNPLACED_VOICES: Array = [&"wraith"]

## **What a boss with no voice of its own roars with** (task 0246): the
## Giant's. Every boss has its own since task 0284; this is the fallback a
## fifth would get.
const BOSS_VOICE := &"sfx/roar_giant"

## **Deaths that sound like their kind** (task 0284), falling back to
## `DEATH_SOUND` with `DEATH_GAP`: the frost zombie shatters.
const DEATH_SOUNDS := {
	&"frost_zombie": &"sfx/shatter",
}

## **What the new enemies do, heard** (task 0284), each on the edge the state
## already sets: a spitter's glob leaving (`enemy_shots` gaining one) and
## landing (losing it), a digger breaking the surface (`Enemies.underground`
## going false), frost on a tower a frost zombie chills (`Towers.chill_left`
## rising), the Harvester's charge winding up (`charge_dir` set) and the walls
## it crushes (rubble on its last line), the Scarecrow King's cast (`casting`
## set) and the Winter Lord's aura taking a tower (`Towers.frozen_left`
## rising).
const SPIT_SOUND := &"sfx/spit"
const SPIT_LAND_SOUND := &"sfx/spit_splat"
const SURFACE_SOUND := &"sfx/burst"
const CHILL_SOUND := &"sfx/crackle"
const CHARGE_SOUND := &"sfx/charge"
const CRUSH_SOUND := &"sfx/crunch"
const SUMMON_SOUND := &"sfx/summon"
const FREEZE_SOUND := &"sfx/freeze"
const FROST_GAP := 8

## The `Audio` script, **preloaded rather than named**. `verify.py` parses
## each file on its own with no autoloads registered, so `Audio.NOWHERE`
## would be an undeclared identifier there and the parse row would go red for
## a file that is perfectly correct at runtime. A preload is a resource path
## and always resolves.
const AudioScript := preload("res://src/app/audio.gd")

const IMPACT_SOUND := &"sfx/impact"
const DEATH_SOUND := &"sfx/death"
const BREAK_SOUND := &"sfx/wall_break"
const HOUSE_SOUND := &"sfx/house_hit"

## How often one sort of enemy is heard from, on average. Not a rule and not
## in `game_data.gd`: a groan changes nothing, and a number in there would
## move the data hash for a noise.
const GROAN_EVERY_SECONDS := 2.6

## The shortest gap between two of the same sound, in frames at sixty.
##
## A tower may fire as fast as it reloads, so its gap is nearly nothing. A
## groan that came round twice in half a second would be the same zombie
## clearing its throat, so its gap is long. The house has no gap at all:
## every hit it takes is one you are meant to count.
const SHOT_GAP := 3
const GROAN_GAP := 40
const IMPACT_GAP := 5
const DEATH_GAP := 8

var _state: Dictionary = {}

## The cycle being watched: what it is, where, the tick it finishes on, and
## what was standing on the cell when it began - a seam struck to its end is
## gone by the time its last swing sounds.
var _verb := &""
var _cell := Vector2i(-1, -1)
var _due := -1
var _target := &""

var _was_biting := false
var _watered := -1
var _money := -1

## The bar's memory (task 0282): the cast being watched - the state's own
## dictionary, which `Fishing.reel` and `give_up` replace rather than empty,
## so a cast that just ended still holds its last press - that press, whether
## the marker was over the green, and how many fish the run's book holds.
var _line: Dictionary = {}
var _pressed: Array = []
var _in_green := false
var _landed := -1

## The moments' memory (task 0281): the phase last frame, what the bin held,
## whether the stall kept hours, and the tools pending and their tiers.
var _phase := -1
var _in_bin := -1
var _stall := -1
var _pending: Dictionary = {}
var _tiers: Dictionary = {}
var _tools_known := false

## The night's memory: reload counters by cell, what was alive and how hurt,
## which occupants were standing, and the house.
var _reloads: Dictionary = {}
var _bodies: Dictionary = {}
var _standing: Dictionary = {}
var _house := -1

## And the guardian's (task 0283): whether the defences have been seen once
## (a farm with none still hears its first), each power's cooldown, whether
## the dog was running, the catapult's shells in the air, and whether the
## phase turned this frame.
var _seen_structures := false
var _powers: Dictionary = {}
var _dog_due := 0
var _shells: Dictionary = {}
var _turned := false

## And the new enemies' (task 0284): the globs in the air, the frost and the
## freeze on each tower, and the cells the chargers' lines covered last frame.
var _spits: Dictionary = {}
var _chills: Dictionary = {}
var _frozen: Dictionary = {}
var _charge_cells: Dictionary = {}
var _charging_now: Dictionary = {}

## The view whose camera the guardian looks through at night (task 0283),
## handed over the way `Music.show_state` gets it. Null by day's checks.
var _world: WorldView = null

var _audio: Node = null


func show_state(state: Dictionary, world: WorldView = null) -> void:
	_state = state
	_world = world
	# **Nothing is remembered across runs.** A new farm starting with the last
	# one's money on record would play a sale the first time the player sold
	# nothing at all.
	_verb = &""
	_cell = Vector2i(-1, -1)
	_due = -1
	_target = &""
	_was_biting = false
	_watered = -1
	_money = -1
	_forget_the_bar()
	# Nor a bed, a payout or a bell for the frame a saved farm arrives on.
	_phase = -1
	_in_bin = -1
	_stall = -1
	_pending.clear()
	_tiers.clear()
	_tools_known = false
	_forget_the_night()


func _forget_the_night() -> void:
	_reloads.clear()
	_bodies.clear()
	_standing.clear()
	_house = -1
	_seen_structures = false
	_powers.clear()
	_dog_due = 0
	_shells.clear()
	_spits.clear()
	_chills.clear()
	_frozen.clear()
	_charge_cells.clear()
	_charging_now.clear()


func _process(delta: float) -> void:
	if _state.is_empty():
		return
	# The ears go where the camera is: on the farmer by day, and at night on
	# the guardian's view rather than the farmer asleep in bed (task 0283).
	if _audio != null:
		_audio.listen_at(ears())

	# The moments that sit on the day's edges are watched in every phase.
	_watch_the_day_turning()
	_watch_the_bin()
	_watch_tools()

	if int(_state["phase"]) != Phases.DAY:
		# The farm is asleep after dark and these verbs do not tick then. The
		# counters are reset so that coming back to the farm does not fire a
		# sale for every coin the night paid out.
		_verb = &""
		_due = -1
		_watered = -1
		_money = -1
		_stall = -1
		_forget_the_bar()
		_watch_night(delta)
		return
	# And the night's memory goes the other way, so that a tower which fired
	# on the last tick of a wave does not fire again at dawn.
	_forget_the_night()
	_watch_action()
	_watch_water()
	_watch_fishing()
	_watch_money()
	_watch_the_stall()


# ------------------------------------------------------------------ the verbs

func _watch_action() -> void:
	var player: Dictionary = _state["player"]
	var action: Dictionary = player["action"]
	var tick := int(_state["tick"])

	if action.is_empty():
		if _due >= 0 and tick >= _due:
			_play_verb(_verb, _target)
		_verb = &""
		_cell = Vector2i(-1, -1)
		_due = -1
		_target = &""
		return

	var verb := StringName(action["verb"])
	var at := Vector2i(int(action["cell"][0]), int(action["cell"][1]))
	var due := tick + int(action["left"])
	# The same verb on the same cell with its due tick pushed forward is the
	# one that repeated - a held key on a tree that is not down yet.
	if _due >= 0 and verb == _verb and at == _cell and due > _due:
		_play_verb(verb, _target)
	if verb != _verb or at != _cell:
		_target = StringName(Farm.occupant(_state, at).get("id", &""))
	_verb = verb
	_cell = at
	_due = due


func _play_verb(verb: StringName, target: StringName) -> void:
	var id := sound_for(verb, target)
	if id != &"":
		_ask(id)


## **What a finished verb sounds like** (task 0281): what it was done to
## first (`TARGET_SOUNDS`), then the verb (`VERB_SOUNDS`), and `&""` for a
## verb that is deliberately silent.
static func sound_for(verb: StringName, target: StringName) -> StringName:
	if verb == &"" or not VERB_SOUNDS.has(verb):
		return &""
	return TARGET_SOUNDS.get(target, VERB_SOUNDS[verb])


# ------------------------------------------------------------- the other three

## Watering, which has no action to watch because it is instant.
func _watch_water() -> void:
	var now := _watered_plots()
	if _watered >= 0 and now > _watered:
		_ask(WATER_SOUND)
	_watered = now


func _watered_plots() -> int:
	var n := 0
	# A count, so the order this comes out in cannot matter - which is the one
	# thing the house rule about unsorted dictionaries is protecting.
	for key in (_state["plots"] as Dictionary):
		if bool((_state["plots"][key] as Dictionary).get("watered", false)):
			n += 1
	return n


## The bite, which is a window opening rather than anything the player did.
func _watch_fishing() -> void:
	var biting := Fishing.is_biting(_state)
	if biting and not _was_biting:
		_ask(BITE_SOUND)
	_was_biting = biting
	_watch_the_bar()


func _forget_the_bar() -> void:
	_line = {}
	_pressed = []
	_in_green = false
	_landed = -1


## **The bar** (task 0282): the tick, the hit or the miss, and the catch -
## read off the state the way the bite is, no key added to be heard.
func _watch_the_bar() -> void:
	var line := Fishing.cast_of(_state)
	var landed := fish_landed(_state)
	if not _line.is_empty():
		var press: Array = _line.get("last", [])
		var ended := not is_same(line, _line)
		if ended and _landed >= 0 and landed > _landed:
			# The press that landed it is a hit, and the catch says so.
			_land()
		elif not press.is_empty() and press != _pressed:
			_ask(HIT_SOUND if bool(press[1]) else MISS_SOUND)
	var green := Fishing.is_biting(_state) and Fishing.in_zone(line)
	if green and not _in_green:
		_ask(TICK_SOUND)
	_in_green = green
	_line = line
	_pressed = (line.get("last", []) as Array).duplicate()
	_landed = landed


## The line coming in, and the catch - or, for a legendary, its fanfare.
func _land() -> void:
	_ask(VERB_SOUNDS[&"reel"])
	if Fishing.is_legendary(StringName(Fishing.last_catch(_state).get("species", &""))):
		_ask_at(LEGEND_SOUND, AudioScript.NOWHERE, 1)
	else:
		_ask(CATCH_SOUND)


## How many fish the run's book holds: it goes up by one on every landing,
## whatever was landed before.
static func fish_landed(state: Dictionary) -> int:
	var total := 0
	var book := Fishing.book_of(state)
	for species in book:        # a sum, so the order cannot matter
		total += int((book[species] as Dictionary).get("caught", 0))
	return total


## A sale: money arriving while the stall is open. Buying spends rather than
## earns, so only the way up makes a noise.
func _watch_money() -> void:
	var now := Resources.amount(_state, GameData.MONEY)
	if _money >= 0 and now > _money and Shop.is_open(_state):
		_ask(SELL_SOUND)
	_money = now


# ---------------------------------------------------------------- the moments

## **The bed, the floor and the morning** (task 0281), off the phase's edges.
## Leaving the day asleep is the bed (0127's `House.asleep`) or, at 02:00,
## the floor (0128's `passed_out`); coming back to the day is 0138's morning.
## The first frame of a farm only records where it is.
func _watch_the_day_turning() -> void:
	var phase := int(_state["phase"])
	_turned = _phase >= 0 and phase != _phase
	if _turned:
		if _phase == Phases.DAY and House.asleep(_state):
			_ask(PASS_OUT_SOUND if House.passed_out(_state) else BED_SOUND)
		elif phase == Phases.DAY:
			_ask(WAKE_SOUND)
		elif _phase == Phases.PREPARATION and phase == Phases.NIGHT:
			# **START** (task 0283), 0136's edge: once a night, everywhere.
			_ask_at(HORN_SOUND, AudioScript.NOWHERE, 1)
	_phase = phase


## **The morning's payout** (task 0281): ONE coins sound when a bin that held
## something is emptied by day - `Shipping.pay` at `begin_day` - never one a
## coin and never the night's reward. Read off the bin, because
## `_watch_money` forgets outside the day and swallows that rise.
func _watch_the_bin() -> void:
	var held := 0
	var bin: Dictionary = Shipping.waiting(_state)
	for id in bin:      # a sum, so the order cannot matter
		held += int(bin[id])
	if _in_bin > 0 and held == 0 and int(_state["phase"]) == Phases.DAY:
		_ask(PAYOUT_SOUND)
	_in_bin = held


## **The peddler's bell** (task 0281), at his stall, as `STALL_OPENS` and
## `STALL_CLOSES` pass - read off `Shop.open_hours`, so a lever moving his
## hours moves the bell with them.
func _watch_the_stall() -> void:
	var open := 1 if Shop.open_hours(_state) else 0
	if _stall >= 0 and open != _stall:
		var stalls := Farm.cells_with(_state, &"shop")
		_ask_at(BELL_SOUND, _cell_middle(stalls[0]) if not stalls.is_empty()
			else _where_the_player_is(), 1)
	_stall = open


## **The anvil and the ting** (task 0281): an upgrade 0173 has paid for
## appears among `tools.pending` - ordered at the stall, or finished at the
## workshop - and is handed over at dawn as its tool's tier going up.
func _watch_tools() -> void:
	var tools: Dictionary = _state.get("tools", {})
	var waiting: Dictionary = tools.get("pending", {})
	var pending := {}
	var tiers := {}
	var ordered := false
	var handed := false
	for tool in GameData.sorted_names(GameData.TOOLS.keys()):
		var key := String(tool)
		tiers[key] = int(tools.get(key, 0))
		if waiting.has(key):
			pending[key] = true
			ordered = ordered or not _pending.has(key)
		handed = handed or int(tiers[key]) > int(_tiers.get(key, tiers[key]))
	if _tools_known:
		if ordered:
			_ask(ANVIL_SOUND)
		if handed:
			_ask(TOOL_READY_SOUND)
	_pending = pending
	_tiers = tiers
	_tools_known = true


func _ready() -> void:
	# **By path and never by name.** `verify.py` parses each script on its own
	# with no autoloads registered, so a bare `Audio.play(...)` is an
	# undeclared identifier there and the parse row goes red for a file that
	# is perfectly correct at runtime.
	_audio = get_node_or_null(^"/root/Audio")


# ------------------------------------------------------------------ the night

func _watch_night(delta: float) -> void:
	var powers_fired := _watch_powers()
	_watch_towers()
	_watch_bodies(powers_fired.has(Ability.FARM_BELL))
	_watch_structures(powers_fired.has(Ability.EMERGENCY_REPAIR))
	_watch_house()
	_watch_shells()
	_watch_spits()
	_watch_frost()
	_watch_groans(delta)
	_watch_lamps(delta)
	# A wall crushed this frame lay on a line last frame or this one.
	_charge_cells = _charging_now
	_charging_now = {}


## **A shot is a reload counter going up.** It counts down every tick, so the
## one tick it rises on is the tick the thing went off - the same reading
## `world_view.gd` uses to put a muzzle flash in the right frame.
##
## A kind in `PER_KIND_SHOTS` (task 0283) is heard once, from the nearest of
## its kind that fired, however many did.
func _watch_towers() -> void:
	var occupants: Dictionary = _state["occupants"]
	var now: Dictionary = {}
	var swarms: Dictionary = {}
	var ears_now := ears()
	# Cell indices, so these are integers and sort as integers.
	var keys: Array = occupants.keys()
	keys.sort()
	for idx in keys:
		var on: Dictionary = occupants[idx]
		var id := StringName(on["id"])
		if not TOWER_SOUNDS.has(id):
			continue
		var reload := int(on.get("reload", 0))
		now[idx] = reload
		if reload <= int(_reloads.get(idx, reload)):
			continue
		var at := _cell_middle(Grid.cell(int(idx)))
		if PER_KIND_SHOTS.has(id):
			var best: Variant = swarms.get(id, null)
			if best == null or ears_now.distance_to(at) < ears_now.distance_to(best):
				swarms[id] = at
			continue
		_ask_at(TOWER_SOUNDS[id], at, SHOT_GAP)
	for id in GameData.sorted_names(swarms.keys()):
		_ask_at(TOWER_SOUNDS[id], swarms[id], BUZZ_GAP)
	_reloads = now


## Impacts, deaths, a boss announcing itself (any `is_boss`, task 0246) and
## **the electric fence's zap** (task 0283): a body's `stun` rising on a tick
## the bell did not ring is a bite on a live wire, heard where it stands.
func _watch_bodies(bell_rang: bool) -> void:
	var now: Dictionary = {}
	for entity_id in Entities.ids(_state):
		var one := Entities.get_one(_state, int(entity_id))
		if one.is_empty():
			continue
		var kind := StringName(one["kind"])
		var hurt := int(one.get("hurt", 0))
		var stun := int(one.get("stun", 0))
		var at := _body_middle(one)
		var under := Enemies.underground(_state, int(entity_id))
		var charging := one.has("charge_dir")
		var casting := one.has("casting")
		now[int(entity_id)] = [kind, hurt, at, stun, under, charging, casting]
		if charging:
			for cell in Enemies.charge_line(_state, int(entity_id)):
				_charging_now[Grid.index(cell as Vector2i)] = true

		var was: Variant = _bodies.get(int(entity_id), null)
		if was == null:
			# **Heard before it is seen.** `NOWHERE` rather than a position,
			# so the roar arrives at full volume from the far fence - which
			# is the requirement, and the only place the falloff is skipped
			# on purpose.
			if Combat.is_boss(kind):
				_ask_at(voice_of(kind), AudioScript.NOWHERE, 1)
			continue
		# On the rise, not for as long as it shows: `hurt` is a countdown and
		# reading it as a level emitted on every frame of it.
		if hurt > int((was as Array)[1]):
			_ask_at(IMPACT_SOUND, at, IMPACT_GAP)
		if stun > int((was as Array)[3]) and not bell_rang:
			_ask_at(DEFENCE_SOUNDS[&"electric_fence"], at, ZAP_GAP)
		# Task 0284's edges: up out of the ground, a charge fixed, a cast begun.
		if bool((was as Array)[4]) and not under:
			_ask_at(SURFACE_SOUND, at, 1)
		if charging and not bool((was as Array)[5]):
			_ask_at(CHARGE_SOUND, at, 1)
		if casting and not bool((was as Array)[6]):
			_ask_at(SUMMON_SOUND, at, 1)

	for gone in _bodies:
		if now.has(gone):
			continue
		var was_at: Vector2 = (_bodies[gone] as Array)[2]
		_ask_at(DEATH_SOUNDS.get(StringName((_bodies[gone] as Array)[0]), DEATH_SOUND),
			was_at, DEATH_GAP)
	_bodies = now


## **What the cursor did, and what the night took** (task 0283), off every
## defence's anchor: one appearing is placed, its `level` rising is an
## upgrade, its hit points rising a repair - not on the frame the phase
## turned, and not when the emergency repair did it, which is heard as
## itself - and a decoy's falling is the straw. One gone is heard as
## `vanished_as` says: a mine going off, a wall breaking, or a sale.
func _watch_structures(mended_by_power: bool) -> void:
	var occupants: Dictionary = _state["occupants"]
	var now: Dictionary = {}
	var keys: Array = occupants.keys()
	keys.sort()             # cell indices, integers
	for idx in keys:
		var on: Dictionary = occupants[idx]
		var id := StringName(on["id"])
		if not GameData.DEFENCES.has(id):
			continue
		var cell := Grid.cell(int(idx))
		if Building.anchor_of(_state, cell) != cell:
			continue
		now[idx] = [id, int(on.get("level", 1)), int(on.get("hp", 0))]
	if _seen_structures:
		for idx in now:
			var at := _cell_middle(Grid.cell(int(idx)))
			var one: Array = now[idx]
			var was: Variant = _standing.get(idx, null)
			if was == null or StringName((was as Array)[0]) != StringName(one[0]):
				_ask_at(PLACE_SOUND, at, 1)
				continue
			if int(one[1]) > int((was as Array)[1]):
				_ask_at(UPGRADE_SOUND, at, 1)
			elif int(one[2]) > int((was as Array)[2]) and not _turned and not mended_by_power:
				_ask_at(MEND_SOUND, at, 1)
			elif int(one[2]) < int((was as Array)[2]) and StringName(one[0]) == &"decoy":
				_ask_at(DEFENCE_SOUNDS[&"decoy"], at, STRAW_GAP)
		for gone in _standing:
			if now.has(gone):
				continue
			var cell := Grid.cell(int(gone))
			match vanished_as(_state, cell, StringName((_standing[gone] as Array)[0])):
				&"spent":
					_ask_at(TOWER_SOUNDS[&"mine"], _cell_middle(cell), 1)
				&"broke":
					# Under a charge it was crushed (task 0284), not broken.
					var crushed := _charge_cells.has(int(gone)) or _charging_now.has(int(gone))
					_ask_at(CRUSH_SOUND if crushed else BREAK_SOUND, _cell_middle(cell), 1)
				&"sold":
					_ask_at(SELL_BACK_SOUND, _cell_middle(cell), 1)
	_standing = now
	_seen_structures = true


## **What became of a defence no longer standing** (task 0283), for `Sfx`
## and for the checks: `&"spent"` for a one-shot that went off (the mine),
## `&"broke"` for one that left rubble on its cell (`Farm.rubble_at`),
## `&"expired"` for one whose life ran out (a barricade, the bait), and
## `&"sold"` for one that left nothing - the guardian took it back. Task
## 0085 sounded every one of these but the mine as a wall breaking, a sale
## included.
static func vanished_as(state: Dictionary, cell: Vector2i, id: StringName) -> StringName:
	var entry: Dictionary = GameData.DEFENCES.get(id, {})
	if bool(entry.get("one_shot", false)):
		return &"spent"
	if Farm.rubble_at(state, cell) != &"":
		return &"broke"
	if entry.has("lifetime_ticks"):
		return &"expired"
	return &"sold"


## **The one that means you are losing.** No gap on it: every hit is one the
## player is meant to count. Since task 0283 a rise is the cursor mending
## it - except the fill `begin_night` gives it, on the frame the phase turns.
func _watch_house() -> void:
	var hp := int(_state["house_hp"])
	if _house >= 0 and hp < _house:
		_ask_at(HOUSE_SOUND, _house_middle(), 1)
	elif _house >= 0 and hp > _house and not _turned:
		_ask_at(MEND_SOUND, _house_middle(), 1)
	_house = hp


## **The powers** (task 0283): each heard when its cooldown rises, at the cell
## it was aimed at - the bell with no position - and the dog's bite when its
## run ends. Returns the powers that went off this frame.
func _watch_powers() -> Array:
	var fired: Array = []
	var one: Dictionary = _state["ability"]
	for id in Ability.ORDER:
		var wait := Ability.cooldown_left(_state, id)
		if _powers.has(id) and wait > int(_powers[id]):
			fired.append(id)
			var aimed: Array = one.get((Ability.POWERS[id] as Dictionary)["at"], [])
			var at := AudioScript.NOWHERE if id == Ability.FARM_BELL or aimed.size() < 2 \
				else _cell_middle(Vector2i(int(aimed[0]), int(aimed[1])))
			_ask_at(POWER_SOUNDS[id], at, 1)
		_powers[id] = wait
	var due := int(one.get("dog_due", 0))
	if _dog_due > 0 and due == 0:
		var sent: Array = one.get("dog", [])
		_ask_at(DOG_BITE_SOUND, _cell_middle(Vector2i(int(sent[0]), int(sent[1])))
			if sent.size() >= 2 else ears(), 1)
	_dog_due = due
	return fired


## **A pumpkin landing** (task 0283): a catapult's ballistic shell leaving the
## air is heard where it was thrown to.
func _watch_shells() -> void:
	var now: Dictionary = {}
	for shot in (_state.get("projectiles", []) as Array):
		var one: Dictionary = shot
		if StringName(one.get("from", &"")) == &"catapult":
			now[int(one["id"])] = one.get("to", [])
	for gone in _shells:
		if now.has(gone):
			continue
		var to: Array = _shells[gone]
		if to.size() >= 2:
			_ask_at(SPLAT_SOUND, _cell_middle(Vector2i(int(to[0]), int(to[1]))), 1)
	_shells = now


## **Per kind, not per body.** However many are out there, the walkers are one
## voice and they are heard from now and again, from wherever the nearest one
## is standing.
func _watch_groans(delta: float) -> void:
	var nearest := nearest_by_kind()
	for kind in GameData.sorted_names(nearest.keys()):
		# A chance a frame rather than a timer, so two kinds that arrived
		# together do not groan in lockstep for the rest of the night.
		if randf() < delta / GROAN_EVERY_SECONDS:
			_ask_at(ENEMY_SOUNDS[kind], AudioScript.NOWHERE if UNPLACED_VOICES.has(kind)
				else nearest[kind], GROAN_GAP)


## **A spitter's globs** (task 0284): one leaving is the spit, from where the
## spitter stood; one gone from the air landed on the tower it was aimed at.
func _watch_spits() -> void:
	var now: Dictionary = {}
	for shot in (_state.get("enemy_shots", []) as Array):
		var one: Dictionary = shot
		var key := "%d:%d" % [int(one.get("by", 0)), int(one.get("fired", 0))]
		now[key] = one.get("to", [])
		if not _spits.has(key):
			var per := float(GameData.TILE_SIZE) / float(Player.SUBTILE)
			var from: Array = one.get("pos", [0, 0])
			_ask_at(SPIT_SOUND, Vector2(float(from[0]), float(from[1])) * per, 1)
	for gone in _spits:
		if now.has(gone):
			continue
		var to: Array = _spits[gone]
		if to.size() >= 2:
			_ask_at(SPIT_LAND_SOUND, _cell_middle(Vector2i(int(to[0]), int(to[1]))), 1)
	_spits = now


## **Frost and freeze on the towers** (task 0284), read like `reload`: a
## tower's `chill` rising is a frost zombie's breath on it, its `frozen`
## rising the Winter Lord's aura taking it.
func _watch_frost() -> void:
	var occupants: Dictionary = _state["occupants"]
	var chills: Dictionary = {}
	var frozen: Dictionary = {}
	var keys: Array = occupants.keys()
	keys.sort()             # cell indices, integers
	for idx in keys:
		var on: Dictionary = occupants[idx]
		if not on.has("chill") and not on.has("frozen"):
			continue
		var at := _cell_middle(Grid.cell(int(idx)))
		var chill := int(on.get("chill", 0))
		var cold := int(on.get("frozen", 0))
		if chill > int(_chills.get(idx, 0)):
			_ask_at(CHILL_SOUND, at, FROST_GAP)
		if cold > int(_frozen.get(idx, 0)):
			_ask_at(FREEZE_SOUND, at, FROST_GAP)
		chills[idx] = chill
		frozen[idx] = cold
	_chills = chills
	_frozen = frozen


## **The searchlights' hum** (task 0283), per kind as the groans are: now and
## then in the waves, from the nearest lit lamp - ten lamps are one hum.
func _watch_lamps(delta: float) -> void:
	if int(_state["phase"]) != Phases.NIGHT:
		return
	var ears_now := ears()
	var best: Variant = null
	for cell in Farm.cells_with(_state, &"searchlight"):
		var lamp: Vector2i = cell
		if Building.anchor_of(_state, lamp) != lamp or Light.lamp_tiles(_state, lamp) <= 0:
			continue
		var at := _cell_middle(lamp)
		if best == null or ears_now.distance_to(at) < ears_now.distance_to(best):
			best = at
	if best != null and randf() < delta / HUM_EVERY_SECONDS:
		_ask_at(DEFENCE_SOUNDS[&"searchlight"], best, HUM_GAP)


## The closest of each sort of enemy, which is how many voices a crowd
## amounts to - measured from the ears, the night camera's centre at night.
##
## **This is the whole of "fifty zombies do not turn into noise".** Fifty
## walkers are one entry, not fifty: the size of what this returns is capped
## by how many *sorts* of thing exist, which is four. Public so that
## `input_check` can ask the claim directly rather than counting noises over
## a stretch of frames and hoping the random draw cooperated.
func nearest_by_kind() -> Dictionary:
	var nearest: Dictionary = {}
	var ears_now := ears()
	for entity_id in Entities.ids(_state):
		var one := Entities.get_one(_state, int(entity_id))
		if one.is_empty():
			continue
		var kind := StringName(one["kind"])
		if not ENEMY_SOUNDS.has(kind) or Combat.is_boss(kind):
			continue        # a boss announces itself and does not mutter
		var at := _body_middle(one)
		var best: Variant = nearest.get(kind, null)
		if best == null or ears_now.distance_to(at) < ears_now.distance_to(best):
			nearest[kind] = at
	return nearest


# ----------------------------------------------------------------- the places

## **Where the ears are** (task 0283): the farmer by day, and at night the
## centre of the guardian's camera (0130) - not the farmer asleep in bed. A
## check with no view hears from the farmer.
func ears() -> Vector2:
	if _world != null and not _state.is_empty() and int(_state["phase"]) != Phases.DAY:
		return _world.camera_centre()
	return _where_the_player_is()


func _where_the_player_is() -> Vector2:
	return _cell_middle(Player.cell(_state))


func _cell_middle(cell: Vector2i) -> Vector2:
	var size := float(GameData.TILE_SIZE)
	return Vector2(cell.x * size + size * 0.5, cell.y * size + size * 0.5)


func _body_middle(one: Dictionary) -> Vector2:
	var per := float(GameData.TILE_SIZE) / float(Player.SUBTILE)
	return Vector2(float(one["pos"][0]), float(one["pos"][1])) * per


func _house_middle() -> Vector2:
	var cells := Farm.cells_with(_state, &"house")
	if cells.is_empty():
		return _where_the_player_is()
	return _cell_middle(cells[cells.size() / 2] as Vector2i)


# ------------------------------------------------------------------- the asks

func _ask(id: StringName) -> void:
	_ask_at(id, ears(), 1)


## The sounds that get the ambience out of their way.
##
## **The house is the whole reason ducking exists** - the done-when says the
## bed may never mask it. The Giant's roar is here too because it is meant to
## arrive over everything, and a wall going because it is the moment a player
## has to look up.
## START's horn too (task 0283): the waves are on their way.
const DUCKS: Array = [HOUSE_SOUND, BREAK_SOUND, HORN_SOUND]


func _ask_at(id: StringName, at: Vector2, gap: int) -> void:
	if _audio == null:
		return
	if _audio.play(id, at, gap) and _ducks(id):
		_audio.duck()


func _ducks(id: StringName) -> bool:
	if DUCKS.has(id):
		return true
	# **Any boss's voice ducks the rest** (task 0246), as the Giant's did.
	for kind in GameData.sorted_names(GameData.ENEMIES.keys()):
		if Combat.is_boss(StringName(kind)) and voice_of(StringName(kind)) == id:
			return true
	return false


## **A kind's voice** (task 0246): its own in `ENEMY_SOUNDS`, a boss's the
## Giant's roar until it has one, and nothing for anything else.
static func voice_of(kind: StringName) -> StringName:
	if ENEMY_SOUNDS.has(kind):
		return ENEMY_SOUNDS[kind]
	return BOSS_VOICE if Combat.is_boss(kind) else &""
