class_name Juice
extends Node2D

## Makes a kill feel like a kill: shake, hit stop, damage numbers, a corpse.
##
## **None of it is in `src/core/` and none of it moves the hash.** Every event
## here is read out of the state the way `particles.gd` and `sfx.gd` read it -
## an id that has gone is a death, hit points that fell are damage - so the
## rules never learn that any of this exists. Task 0088's last requirement,
## and the reason the determinism guard can be the proof.
##
## ## Hit stop does not desynchronise anything, and the hash says so
##
## A hold does not touch `TICK_HZ` and does not touch `Engine.time_scale`. It
## stops `SimDriver` for a fraction of a second, and the ticks that were going
## to run still run, at the same fixed rate, a moment later. **The simulation
## does not measure itself in real time**, so a game that was held and a game
## that was not reach the same state after the same number of ticks - which
## `headless_check` asserts by hashing both.
##
## ## Where the damage type comes from
##
## Exactly, and without asking the rules for anything new. A shot in flight is
## in `state["projectiles"]` and **carries its own `type` and `target`**; when
## one disappears it has landed, so the damage its target takes that frame is
## that type. A flame tower has no projectile, but its victims are in
## `state["burning"]`. A mine has neither, and is spotted by the same signal
## that sounds it: a `one_shot` defence that is no longer there.
##
## Nothing is guessed and nothing was added to the state to make it work.
##
## ## Above the night ramp on purpose
##
## This draws on the `Lights` layer rather than in the world, because a
## damage number tinted blue by the night is a damage number whose colour
## coding has stopped working - and the colour coding is the requirement. The
## corpse goes up there with it, which makes a death pop a little at night.
## That reads as juice rather than as a mistake, so it stays.

## How long a number lives and how far it drifts up while it does.
const NUMBER_SECONDS := 0.85
const NUMBER_RISE := 16.0

## **How long hits on one thing are gathered before a number appears.** The
## batching requirement: an auto-crossbow that pierces three times in a fifth
## of a second is one number saying nine, not three saying three. It also
## keeps the pool honest, because a pierce shot cannot spend three slots.
const BATCH_SECONDS := 0.18

## The most numbers that may be in the air. **A crowded wave does not spawn a
## thousand labels**: the oldest is reused, exactly as the particle pool does
## it, so a busy night costs what a quiet one costs.
const MAX_NUMBERS := 24

## And the most corpses.
const MAX_CORPSES := 16

## How long a body takes to flatten, and how far it squashes.
const SQUASH_SECONDS := 0.32
const SQUASH_TO := 0.45

## What a shake is worth. A death is a nudge, a big hit is a knock, and the
## house being hit is the most the cap allows.
const SHAKE_DEATH := 1.4
const SHAKE_BIG_HIT := 3.2
const SHAKE_HOUSE := 9.0

## What counts as a big hit: enough damage to stop the world for a moment.
const BIG_HIT := 12

## How long the world stops for. **Four frames at sixty**, which is the
## shortest hold anybody feels and the longest one nobody notices.
const HIT_STOP_SECONDS := 0.066

## Damage type -> the colour its number is written in. Off the palette, like
## everything else that has a colour in this game.
const TYPE_COLOURS := {
	&"impact": &"bone",
	&"fire": &"flame",
	&"explosive": &"gold_light",
}

var _state: Dictionary = {}
var _world: WorldView = null
var _driver: SimDriver = null

var _numbers_on := true
var _hit_stop_on := true

## What was alive last frame, and what it had: id -> [hp, kind, position].
var _seen: Dictionary = {}
## Shots in the air last frame: id -> [target, type].
var _seen_shots: Dictionary = {}
## Defences standing last frame: cell index -> whether it was a one-shot.
var _seen_traps: Dictionary = {}
var _house := -1

## Damage gathered but not yet shown: id -> [amount, x, y, type, left].
var _pending: Dictionary = {}

## The number pool, in parallel arrays like the particles'.
var _n_at: PackedVector2Array = PackedVector2Array()
var _n_amount: PackedInt32Array = PackedInt32Array()
var _n_left: PackedFloat32Array = PackedFloat32Array()
var _n_tint: PackedColorArray = PackedColorArray()

## **The mark that survives greyscale.** A colour-blind player and a bad
## monitor see the same three numbers; a `+`, a `^` and a `*` are three
## different shapes to everybody. Task 0098.
var _n_mark: PackedStringArray = PackedStringArray()
var _n_next := 0

## The corpse pool.
var _c_at: PackedVector2Array = PackedVector2Array()
var _c_left: PackedFloat32Array = PackedFloat32Array()
var _c_kind: Array = []
var _c_sprite: Array = []
var _c_next := 0


func _ready() -> void:
	arm()
	_read_settings()
	var service := get_node_or_null(^"/root/Settings")
	if service != null and not service.changed.is_connected(_on_setting):
		service.changed.connect(_on_setting)
		service.reloaded.connect(_read_settings)


## Size the two pools. Called by `_ready`, and by `headless_check`, which
## drives `gather` and `ripen` directly without a tree.
func arm() -> void:
	if _n_at.size() == MAX_NUMBERS:
		return
	_n_at.resize(MAX_NUMBERS)
	_n_amount.resize(MAX_NUMBERS)
	_n_left.resize(MAX_NUMBERS)
	_n_tint.resize(MAX_NUMBERS)
	_n_mark.resize(MAX_NUMBERS)
	_c_at.resize(MAX_CORPSES)
	_c_left.resize(MAX_CORPSES)
	_c_kind.resize(MAX_CORPSES)
	_c_sprite.resize(MAX_CORPSES)
	for i in MAX_CORPSES:
		if _c_sprite[i] != null:
			continue
		var sprite := Sprite2D.new()
		sprite.name = "Corpse%02d" % i
		sprite.visible = false
		# Feet on the ground, like every other actor in the game.
		sprite.centered = false
		sprite.offset = Vector2(-16.0, -32.0)
		add_child(sprite)
		_c_sprite[i] = sprite


func show_state(state: Dictionary, world: WorldView, driver: SimDriver) -> void:
	_state = state
	_world = world
	_driver = driver
	_seen.clear()
	_seen_shots.clear()
	_seen_traps.clear()
	_pending.clear()
	_house = -1
	for i in MAX_NUMBERS:
		_n_left[i] = 0.0
	for i in MAX_CORPSES:
		_c_left[i] = 0.0
		if i < _c_sprite.size() and _c_sprite[i] != null:
			(_c_sprite[i] as Sprite2D).visible = false


func _process(delta: float) -> void:
	if _state.is_empty():
		return
	_watch(delta)
	_age(delta)
	queue_redraw()


# ------------------------------------------------------------------ watching

func _watch(delta: float) -> void:
	var landed := _shots_that_landed()
	var blasts := _traps_that_went_off()

	var now: Dictionary = {}
	var deaths := 0
	var biggest := 0
	for entity_id in Entities.ids(_state):
		var one := Entities.get_one(_state, int(entity_id))
		if one.is_empty():
			continue
		var id := int(entity_id)
		var hp := int(one["hp"])
		var at := _body_middle(one)
		now[id] = [hp, StringName(one["kind"]), at]

		var was: Variant = _seen.get(id, null)
		if was == null:
			continue
		var lost := int((was as Array)[0]) - hp
		if lost > 0:
			biggest = maxi(biggest, lost)
			gather(id, lost, at, _type_of(id, landed, blasts, at))

	for gone in _seen:
		if now.has(gone):
			continue
		var last: Array = _seen[gone]
		_corpse(last[2] as Vector2, last[1] as StringName)
		deaths += 1
	_seen = now

	# The house, which is the one thing worth the whole cap.
	var house := int(_state["house_hp"])
	if _house >= 0 and house < _house:
		_shake(SHAKE_HOUSE)
		_stop()
	_house = house

	if deaths > 0:
		_shake(SHAKE_DEATH * sqrt(float(deaths)))
	if biggest >= BIG_HIT:
		_shake(SHAKE_BIG_HIT)
		_stop()

	ripen(delta)


## Shots that were in the air last frame and are not now: target -> type.
func _shots_that_landed() -> Dictionary:
	var now: Dictionary = {}
	for shot in (_state["projectiles"] as Array):
		var one: Dictionary = shot
		now[int(one["id"])] = [int(one["target"]),
			StringName(one.get("type", GameData.DAMAGE_IMPACT))]
	var landed: Dictionary = {}
	for shot_id in _seen_shots:
		if now.has(shot_id):
			continue
		var pair: Array = _seen_shots[shot_id]
		landed[int(pair[0])] = pair[1]
	_seen_shots = now
	return landed


## Where a one-shot defence stopped being there, which is a mine going off.
func _traps_that_went_off() -> Array:
	var occupants: Dictionary = _state["occupants"]
	var now: Dictionary = {}
	var keys: Array = occupants.keys()
	keys.sort()             # cell indices, integers
	for idx in keys:
		var id := StringName((occupants[idx] as Dictionary)["id"])
		if GameData.DEFENCES.has(id):
			now[idx] = bool((GameData.DEFENCES[id] as Dictionary)
				.get("one_shot", false))
	var blasts: Array = []
	for gone in _seen_traps:
		if not now.has(gone) and bool(_seen_traps[gone]):
			blasts.append(_cell_middle(Grid.cell(int(gone))))
	_seen_traps = now
	return blasts


## What sort of damage this was. See the note at the top: exact, from three
## signals the rules already keep.
func _type_of(id: int, landed: Dictionary, blasts: Array,
		at: Vector2) -> StringName:
	if landed.has(id):
		return landed[id]
	if Combat.is_burning(_state, id):
		return GameData.DAMAGE_FIRE
	for where in blasts:
		if (where as Vector2).distance_to(at) < GameData.TILE_SIZE * 3:
			return GameData.DAMAGE_EXPLOSIVE
	return GameData.DAMAGE_IMPACT


# ------------------------------------------------------------- the two pools

## Add to what this thing is owed, rather than showing a number at once.
##
## **Public, with `ripen`, because the two of them are the batching** and a
## check has to be able to ask them directly. At any frame rate a suite
## actually runs at, several hits in a row land in the same frame - so a live
## test cannot tell gathering from not gathering, and one written that way
## passed with the gathering taken out. These two are where the question has
## an answer.
func gather(id: int, amount: int, at: Vector2, type: StringName) -> void:
	if not _numbers_on:
		return
	var row: Variant = _pending.get(id, null)
	if row == null:
		# **Spread sideways by whose number it is.** Two zombies standing
		# together get two numbers in the same place, and two bone-coloured
		# numbers on top of each other are one unreadable blob - which is
		# what the first wave screenshot showed. Off the id rather than out
		# of a generator, so it is the same every run.
		var nudge := float((id * 7) % 11) - 5.0
		_pending[id] = [amount, at + Vector2(nudge, 0.0), type,
			BATCH_SECONDS]
		return
	var one: Array = row
	one[0] = int(one[0]) + amount
	# **The louder type wins.** Fire over impact, explosive over both: a
	# zombie shot and then blown up in the same fifth of a second is a zombie
	# that was blown up.
	if _louder(type, one[2]):
		one[2] = type


func _louder(a: StringName, b: StringName) -> bool:
	var order := [GameData.DAMAGE_IMPACT, GameData.DAMAGE_FIRE,
		GameData.DAMAGE_EXPLOSIVE]
	return order.find(a) > order.find(b)


## Show whatever has finished gathering. See `gather`.
func ripen(delta: float) -> void:
	var done: Array = []
	for id in _pending:
		var one: Array = _pending[id]
		one[3] = float(one[3]) - delta
		if float(one[3]) <= 0.0:
			done.append(id)
	done.sort()             # entity ids, integers - a fixed order
	for id in done:
		var one: Array = _pending[id]
		_number(one[1] as Vector2, int(one[0]), one[2] as StringName)
		_pending.erase(id)


func _number(at: Vector2, amount: int, type: StringName) -> void:
	if amount <= 0:
		return
	var slot := _n_next
	_n_next = (_n_next + 1) % MAX_NUMBERS
	_n_at[slot] = at
	_n_amount[slot] = amount
	_n_left[slot] = NUMBER_SECONDS
	_n_tint[slot] = _colour_of(type)
	_n_mark[slot] = A11y.mark_of(type)


func _corpse(at: Vector2, kind: StringName) -> void:
	var slot := _c_next
	_c_next = (_c_next + 1) % MAX_CORPSES
	_c_at[slot] = at
	_c_left[slot] = SQUASH_SECONDS
	_c_kind[slot] = kind
	var sprite := _c_sprite[slot] as Sprite2D
	sprite.texture = _corpse_art(kind)
	sprite.visible = sprite.texture != null


## **Sprites, not `draw_texture`.** Drawn through `_draw` on this layer, every
## body came out as a solid white rectangle - and the death art has not one
## white pixel in it, so nothing was being drawn but a box. Rather than chase
## that through the renderer, corpses go on the screen the way every other
## picture in this game does: a `Sprite2D` with a texture, a position and a
## scale. `particles.gd` is the hint - it is on the same layer and draws only
## rectangles.
func _place_corpses(to_screen: Transform2D) -> void:
	for i in MAX_CORPSES:
		var sprite := _c_sprite[i] as Sprite2D
		if _c_left[i] <= 0.0 or sprite.texture == null:
			sprite.visible = false
			continue
		var gone := 1.0 - _c_left[i] / SQUASH_SECONDS
		var squash := lerpf(1.0, SQUASH_TO, gone)
		sprite.visible = true
		sprite.scale = Vector2(2.0 - squash, squash)
		sprite.position = (to_screen * _c_at[i]).round()
		sprite.modulate = Color(1.0, 1.0, 1.0, 1.0 - gone * gone)


func _age(delta: float) -> void:
	for i in MAX_NUMBERS:
		if _n_left[i] > 0.0:
			_n_left[i] = maxf(_n_left[i] - delta, 0.0)
	for i in MAX_CORPSES:
		if _c_left[i] > 0.0:
			_c_left[i] = maxf(_c_left[i] - delta, 0.0)


# --------------------------------------------------------------- the effects

func _shake(pixels: float) -> void:
	if _world != null:
		_world.shake(pixels)


func _stop() -> void:
	if _hit_stop_on and _driver != null:
		_driver.hold(HIT_STOP_SECONDS)


# ---------------------------------------------------------------- the drawing

func _draw() -> void:
	if _world == null:
		return
	var to_screen := get_viewport().get_canvas_transform()
	var font := UiKit.font()
	_place_corpses(to_screen)

	if font == null:
		return
	for i in MAX_NUMBERS:
		if _n_left[i] <= 0.0:
			continue
		var gone := 1.0 - _n_left[i] / NUMBER_SECONDS
		var tint: Color = _n_tint[i]
		tint.a = 1.0 - gone * gone
		var at := to_screen * _n_at[i] - Vector2(0.0, NUMBER_RISE * gone)
		var text := str(_n_amount[i]) + _n_mark[i]
		var wide := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1,
			UiKit.FONT_SIZE).x
		draw_string(font, (at - Vector2(wide * 0.5, 0.0)).round(), text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, UiKit.FONT_SIZE, tint)


func _corpse_art(kind: StringName) -> Texture2D:
	var path := "res://sprites/enemies/%s_death.png" % kind
	if not ResourceLoader.exists(path):
		return null
	return load(path)


func _colour_of(type: StringName) -> Color:
	var name: StringName = TYPE_COLOURS.get(type, &"bone")
	return PaletteData.COLOURS.get(name, Color.WHITE)


# ------------------------------------------------------------------ settings

func _on_setting(key: StringName) -> void:
	if key == &"video/damage_numbers" or key == &"a11y/hit_stop":
		_read_settings()


func _read_settings() -> void:
	var service := get_node_or_null(^"/root/Settings")
	if service == null:
		return
	_numbers_on = bool(service.get_bool(&"video/damage_numbers"))
	_hit_stop_on = bool(service.get_bool(&"a11y/hit_stop"))
	if not _numbers_on:
		_pending.clear()
		for i in MAX_NUMBERS:
			_n_left[i] = 0.0


# ------------------------------------------------------------------ the maths

func _body_middle(one: Dictionary) -> Vector2:
	var per := float(GameData.TILE_SIZE) / float(Player.SUBTILE)
	return Vector2(float(one["pos"][0]), float(one["pos"][1])) * per


func _cell_middle(cell: Vector2i) -> Vector2:
	var size := float(GameData.TILE_SIZE)
	return Vector2(cell.x * size + size * 0.5, cell.y * size + size * 0.5)


# ------------------------------------------------------------- for the checks

## How many numbers are in the air, and how many bodies are still flattening.
func numbers_showing() -> int:
	var n := 0
	for i in MAX_NUMBERS:
		if _n_left[i] > 0.0:
			n += 1
	return n


func corpses_showing() -> int:
	var n := 0
	for i in MAX_CORPSES:
		if _c_left[i] > 0.0:
			n += 1
	return n


func waiting_to_show() -> int:
	return _pending.size()


## What all the numbers on screen add up to. With `numbers_showing()` this
## separates "one label saying five" from "two labels saying two and three".
func shown_total() -> int:
	var total := 0
	for i in MAX_NUMBERS:
		if _n_left[i] > 0.0:
			total += _n_amount[i]
	return total
