class_name AnimalView
extends Node2D

## **The barnyard, alive** (task 0185): the animals that live in a coop or a
## barn wander the ground in front of it by day - walking, stopping to eat,
## now and then lying down - and go in at night, where `Transition` fades
## them with the loose ones (`day_only`). The dog follows the farmer by day
## and sleeps by the porch after dark; petting it puts a heart over it. The
## pigs' dig spots are drawn here too, on the ground under the boots.
##
## **View only.** Nothing here writes the state, and nothing in `src/core/`
## knows there is a dog, so the determinism hash cannot see it. Where an
## animal stands is this file's business: it starts by its home's door and
## wanders a little pen in front of it, from a sequence of its own - the same
## animal makes the same walk every time, so a picture is repeatable.
##
## The drawings are A026's (sheep, pig), A027's (cow, chicken) and A028's
## (dog) animations, through 0120's road until 0209, 0210 and 0245 integrate
## them: the cow's and the chicken's props tinted and scaled, every frame the
## same picture, with a bob for a step, a dip for a bite and a squash for
## sleep so the states still read. A029's dig spot is drawn in code until
## 0211.

## How fast they go, in pixels a second.
const WALK_SPEED := 12.0
const DOG_SPEED := 60.0
## How far behind the farmer the dog keeps, and how near counts as there.
const DOG_BEHIND := 14.0
const DOG_NEAR := 10.0
## How deep the pen in front of a home is, in cells.
const PEN_DEPTH := 2.5
## How long a heart floats over the dog, in seconds.
const HEART_SECONDS := 1.0

var _state: Dictionary = {}
var _layer: Node2D
var _ground: Node2D
var _spots: Node2D
## "anchor:index" -> {"sprite", "kind", "pos", "target", "mode", "left", "step", "phase", "facing_east"}
var _animals: Dictionary = {}
var _signature := ""
var _spots_signature := ""
var _dog: Sprite2D
var _heart: Node2D
var _dog_pos := Vector2(-1, -1)
var _dog_mode := &"sit"
var _dog_east := false
var _dog_clock := 0.0
var _heart_left := 0.0
var _time := 0.0
var _textures: Dictionary = {}


## Where to draw: the world's y-sorted layer for the animals and the dog, and
## beside the layer under the boots, for the dig spots.
func setup(layer: Node2D, ground: Node2D) -> void:
	_layer = layer
	_ground = ground
	_spots = Node2D.new()
	_spots.name = "DigSpots"
	_spots.draw.connect(_draw_spots)
	# Beside the boots' layer rather than in it: that layer lends itself to
	# the ground effects, and is empty when they are gone.
	var world := _ground.get_parent()
	world.add_child(_spots)
	world.move_child(_spots, _ground.get_index())
	_dog = Sprite2D.new()
	_dog.name = "Dog"
	_dog.centered = false
	_layer.add_child(_dog)
	_heart = Node2D.new()
	_heart.name = "DogHeart"
	_heart.z_index = 6
	_heart.draw.connect(_draw_heart)
	add_child(_heart)


func show_state(state: Dictionary) -> void:
	if not is_same(_state, state):
		_dog_pos = Vector2(-1, -1)
		_signature = ""
	_state = state


func _process(delta: float) -> void:
	if _state.is_empty() or _layer == null:
		return
	_time += delta
	_follow_homes()
	for key in _animals:
		_step_animal(_animals[key], delta)
	_step_dog(delta)
	var spots := _spot_signature()
	if spots != _spots_signature:
		_spots_signature = spots
		_spots.queue_redraw()
	if _heart_left > 0.0:
		_heart_left = maxf(_heart_left - delta, 0.0)
		_heart.queue_redraw()


# ------------------------------------------------------------- the animals

## Who lives where, without the clocks: a move-in rebuilds, a ticking hen
## does not.
func _homes_signature() -> String:
	var homes: Dictionary = _state.get("housed", {})
	var anchors: Array = homes.keys()
	anchors.sort()
	var parts: Array = []
	for idx in anchors:
		var ids: Array = []
		for animal in ((homes[idx] as Dictionary)["animals"] as Array):
			ids.append(str((animal as Dictionary)["id"]))
		parts.append("%d:%s" % [int(idx), ",".join(ids)])
	return ";".join(parts)


func _follow_homes() -> void:
	var signature := _homes_signature()
	if signature == _signature:
		return
	_signature = signature
	for key in _animals:
		((_animals[key] as Dictionary)["sprite"] as Sprite2D).queue_free()
	_animals.clear()
	var homes: Dictionary = _state.get("housed", {})
	var anchors: Array = homes.keys()
	anchors.sort()
	for idx in anchors:
		var anchor := Grid.cell(int(idx))
		if Farm.occupant(_state, anchor).is_empty():
			continue
		var animals: Array = (homes[idx] as Dictionary)["animals"]
		for i in animals.size():
			var kind := StringName((animals[i] as Dictionary)["id"])
			var sprite := Sprite2D.new()
			sprite.name = "Housed_%d_%d" % [int(idx), i]
			sprite.centered = false
			sprite.set_meta("day_only", true)
			sprite.set_meta("housed_at", int(idx))
			sprite.set_meta("animal", kind)
			_layer.add_child(sprite)
			var start := _start_point(anchor, i, animals.size())
			_animals["%d:%d" % [int(idx), i]] = {
				"sprite": sprite, "kind": kind, "anchor": anchor, "index": i,
				"pos": start, "target": start, "mode": &"idle",
				"left": 0.5 + float(i) * 0.4, "step": 0, "phase": float(i) * 0.7,
				"facing_east": i % 2 == 1,
			}


## The pen: the two rows in front of a home's front wall, a cell either side
## of it. A point in it from the animal's own sequence.
func _pen_point(anchor: Vector2i, index: int, step: int) -> Vector2:
	var id := StringName(Farm.occupant(_state, anchor).get("id", &""))
	var size := Building.size_of(id)
	var tile := float(GameData.TILE_SIZE)
	var left := (float(anchor.x) - 0.5) * tile
	var width := (float(size.x) + 1.0) * tile
	var top := float(anchor.y + size.y) * tile + 6.0
	var depth := PEN_DEPTH * tile
	var h := absi(hash([anchor.x, anchor.y, index, step]))
	return Vector2(left + float(h % 1000) / 1000.0 * width,
		top + float((h / 1000) % 1000) / 1000.0 * depth)


## Where each animal stands first: spread along the pen's front, a row
## each other one, so a full home does not start in a heap.
func _start_point(anchor: Vector2i, index: int, count: int) -> Vector2:
	var id := StringName(Farm.occupant(_state, anchor).get("id", &""))
	var size := Building.size_of(id)
	var tile := float(GameData.TILE_SIZE)
	var left := (float(anchor.x) - 0.5) * tile
	var width := (float(size.x) + 1.0) * tile
	var top := float(anchor.y + size.y) * tile + 6.0
	return Vector2(left + (float(index) + 0.5) / float(maxi(count, 1)) * width,
		top + (PEN_DEPTH * tile * 0.6 if index % 2 == 1 else 4.0))


## Walk, eat, rest, lie down: a little state machine on the animal's own
## sequence - view only.
func _step_animal(animal: Dictionary, delta: float) -> void:
	var sprite: Sprite2D = animal["sprite"]
	if not is_instance_valid(sprite):
		return
	animal["left"] = float(animal["left"]) - delta
	var mode := StringName(animal["mode"])
	if mode == &"walk":
		var pos: Vector2 = animal["pos"]
		var to: Vector2 = animal["target"]
		var gap := to - pos
		if gap.length() <= WALK_SPEED * delta:
			animal["pos"] = to
			_next_mode(animal)
		else:
			animal["pos"] = pos + gap.normalized() * WALK_SPEED * delta
			if absf(gap.x) > 0.5:
				animal["facing_east"] = gap.x > 0.0
	elif float(animal["left"]) <= 0.0:
		_next_mode(animal)
	_draw_animal(animal)


func _next_mode(animal: Dictionary) -> void:
	var step := int(animal["step"]) + 1
	animal["step"] = step
	var roll := absi(hash([animal["anchor"], animal["index"], step, &"mode"])) % 10
	var was := StringName(animal["mode"])
	if was != &"walk" and roll < 6:
		animal["mode"] = &"walk"
		animal["target"] = _pen_point(animal["anchor"], int(animal["index"]), step)
		return
	animal["mode"] = &"eat" if roll < 8 else (&"sleep" if roll == 9 else &"idle")
	animal["left"] = 2.0 + float(roll % 3)


func _draw_animal(animal: Dictionary) -> void:
	var sprite: Sprite2D = animal["sprite"]
	var kind := StringName(animal["kind"])
	var mode := StringName(animal["mode"])
	var name := StringName("%s_%s" % [kind, mode])
	var entry := PlaceholderArt.art(name)
	var frames := maxi(int(entry.get("frames", 1)), 1)
	var seconds := maxf(float(entry.get("seconds", 0.5)), 0.05)
	var frame := int((_time + float(animal["phase"])) / seconds) % frames
	sprite.texture = _texture(name, frame, kind)
	var pos: Vector2 = animal["pos"]
	var pivot := _pivot(sprite.texture)
	var scale := PlaceholderArt.art_scale(name) if not entry.is_empty() else 1.0
	sprite.offset = -pivot
	sprite.flip_h = bool(animal["facing_east"])
	sprite.modulate = Color(PlaceholderArt.art_tint(name), sprite.modulate.a) if not entry.is_empty() \
		else Color(1, 1, 1, sprite.modulate.a)
	var lift := 0.0
	var squash := 1.0
	match mode:
		&"walk":
			lift = -absf(sin((_time + float(animal["phase"])) * 9.0))
		&"eat":
			lift = 1.0 if frame == 0 else 0.0
		&"sleep":
			squash = 0.78
	sprite.position = pos.round() + Vector2(0, lift)
	sprite.scale = Vector2(scale, scale * squash)


# ------------------------------------------------------------------- the dog

## **The dog**: a pet from the first morning. By day it trots after the
## farmer and sits a little behind him; at night - and while he is indoors -
## it sleeps by the porch. Never in the state.
func _step_dog(delta: float) -> void:
	if _dog == null:
		return
	var porch := House.porch(_state)
	var tile := float(GameData.TILE_SIZE)
	var home := Vector2((float(porch.x) + 1.5) * tile, (float(porch.y) + 1.0) * tile)
	var day := int(_state["phase"]) == Phases.DAY and not House.inside(_state) and not House.asleep(_state)
	var target := home
	if day:
		var feet := ArtPlacement.contact((_state["player"] as Dictionary)["pos"])
		var facing: Vector2i = Player.FACING_STEPS[Player.facing(_state)]
		target = feet - Vector2(facing) * DOG_BEHIND + Vector2(8.0, 0.0)
	if _dog_pos.x < 0.0:
		_dog_pos = target
	var gap := target - _dog_pos
	var speed := DOG_SPEED if day else DOG_SPEED * 0.6
	if gap.length() > DOG_NEAR:
		_dog_pos += gap.normalized() * minf(speed * delta, gap.length())
		_dog_mode = &"walk"
		if absf(gap.x) > 0.5:
			_dog_east = gap.x > 0.0
	else:
		_dog_mode = &"sit" if day else &"sleep"
	if _heart_left > 0.0 and day:
		_dog_mode = &"wag"
	_dog_clock += delta
	var name := StringName("dog_%s" % _dog_mode)
	var entry := PlaceholderArt.art(name)
	var frames := maxi(int(entry.get("frames", 1)), 1)
	var frame := int(_dog_clock / maxf(float(entry.get("seconds", 0.5)), 0.05)) % frames
	_dog.texture = _texture(name, frame, &"dog")
	_dog.offset = -_pivot(_dog.texture)
	_dog.flip_h = _dog_east
	_dog.modulate = PlaceholderArt.art_tint(name)
	var scale := PlaceholderArt.art_scale(name)
	_dog.scale = Vector2(scale, scale * (0.75 if _dog_mode == &"sleep" else 1.0))
	var lift := -absf(sin(_dog_clock * 12.0)) if _dog_mode == &"walk" else 0.0
	_dog.position = _dog_pos.round() + Vector2(0, lift)


## A small heart rising over the dog and fading, for a pat.
func _draw_heart() -> void:
	if _heart_left <= 0.0:
		return
	var rise := (HEART_SECONDS - _heart_left) / HEART_SECONDS
	var at := _dog_pos.round() + Vector2(-3.0, -22.0 - rise * 6.0)
	var red := Color(_colour(&"roof"), clampf(_heart_left / HEART_SECONDS * 1.5, 0.0, 1.0))
	var ink := Color(_colour(&"ink"), red.a)
	_heart.draw_rect(Rect2(at + Vector2(0, 0), Vector2(2, 1)), ink)
	_heart.draw_rect(Rect2(at + Vector2(3, 0), Vector2(2, 1)), ink)
	_heart.draw_rect(Rect2(at + Vector2(-1, 1), Vector2(7, 2)), red)
	_heart.draw_rect(Rect2(at + Vector2(0, 3), Vector2(5, 1)), red)
	_heart.draw_rect(Rect2(at + Vector2(1, 4), Vector2(3, 1)), red)
	_heart.draw_rect(Rect2(at + Vector2(2, 5), Vector2(1, 1)), red)


## Where the dog is, for the checks and the picture.
func dog_position() -> Vector2:
	return _dog_pos


func dog_mode() -> StringName:
	return _dog_mode


## **A pat**: a heart over the dog. A click on it, or the interact key while
## the farmer faces it with nothing else to do there - the rules never hear
## of it.
func pet() -> void:
	_heart_left = HEART_SECONDS


func petted() -> bool:
	return _heart_left > 0.0


func _unhandled_input(event: InputEvent) -> void:
	if _state.is_empty() or _dog == null or int(_state["phase"]) != Phases.DAY:
		return
	if event is InputEventMouseButton and event.is_action_pressed(&"place"):
		var at := _dog.get_global_transform_with_canvas().affine_inverse() \
			* (event as InputEventMouseButton).position
		if _dog.texture != null and Rect2(_dog.offset, _dog.texture.get_size()).has_point(at):
			pet()
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"interact") and _faces_dog():
		pet()


## Whether the farmer stands facing the dog with nothing else to do on that
## cell - so the key that pats it never also tills or chops.
func _faces_dog() -> bool:
	var ahead := Player.cell(_state) + Player.FACING_STEPS[Player.facing(_state)]
	var dog_cell := Vector2i(floori(_dog_pos.x / GameData.TILE_SIZE), floori((_dog_pos.y - 1.0) / GameData.TILE_SIZE))
	return dog_cell == ahead and Interact.verb_at(_state, ahead) == &""


# ------------------------------------------------------------- dig spots

func _spot_signature() -> String:
	var parts: Array = []
	for cell in Livestock.spots(_state):
		parts.append(str(cell))
	return ",".join(parts)


## A029's truffle spot, drawn in code until 0211: a heap of turned soil with
## a truffle's knobbly top showing - 16x16 at (8,14), visible 12 wide.
func _draw_spots() -> void:
	if _state.is_empty():
		return
	var tile := float(GameData.TILE_SIZE)
	for cell in Livestock.spots(_state):
		var at := Vector2(cell) * tile
		_spots.draw_rect(Rect2(at + Vector2(2, 9), Vector2(12, 4)), _colour(&"soil_dark"))
		_spots.draw_rect(Rect2(at + Vector2(3, 8), Vector2(10, 4)), _colour(&"soil"))
		_spots.draw_rect(Rect2(at + Vector2(4, 7), Vector2(3, 1)), _colour(&"soil_light"))
		_spots.draw_rect(Rect2(at + Vector2(9, 7), Vector2(3, 1)), _colour(&"soil_light"))
		_spots.draw_rect(Rect2(at + Vector2(6, 5), Vector2(4, 3)), _colour(&"ink"))
		_spots.draw_rect(Rect2(at + Vector2(7, 4), Vector2(2, 2)), _colour(&"wood_dark"))
		_spots.draw_rect(Rect2(at + Vector2(7, 5), Vector2(1, 1)), _colour(&"soil_light"))


func _colour(id: StringName) -> Color:
	return PaletteData.COLOURS.get(id, Color.MAGENTA)


# ------------------------------------------------------------------ pictures

func _texture(name: StringName, frame: int, kind: StringName) -> Texture2D:
	var path := PlaceholderArt.texture_path(PlaceholderArt.art_path(name, frame)) \
		if not PlaceholderArt.art(name).is_empty() else "res://sprites/props/%s.png" % kind
	if not _textures.has(path):
		_textures[path] = load(path) if ResourceLoader.exists(path) else null
	return _textures[path]


func _pivot(texture: Texture2D) -> Vector2:
	if texture == null:
		return Vector2.ZERO
	var metadata: Dictionary = PlaceholderArt.frame(texture.resource_path)
	return Vector2(metadata.get("pivot", Vector2i(texture.get_width() / 2, texture.get_height())))

