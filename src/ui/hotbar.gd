class_name Hotbar
extends Control

## **The night's shop window** (task 0133): every defence the catalogue
## offers, along the bottom from the build step to the morning, each with its
## icon and its price - so what the day earned is there to see as walls and
## towers, not as a text list.
##
## **Built from `Building.catalogue`**, in its order, never from a list here:
## a defence added to `GameData.DEFENCES` gets a slot with no edit. More slots
## than fit between the log and the night HUD's bottom-right controls go on
## pages, and the page is the one holding the selection.
##
## It decides nothing. A slot is picked with a click, `slot_1`..`slot_8` (the
## seed keys by day, which `DayHud` leaves alone at night) or `hotbar_prev` /
## `hotbar_next` (the bumpers on a pad, Q and E on the keyboard), and every way
## goes through `Building.select` - the road the day palette's rows take.
## `cancel` clears it through `BuildMode`, and the cursor goes back to
## inspecting.
##
## A slot shows the kit count when one is banked, the price otherwise - or,
## greyed, what is short - and for a defence with a nightly limit how many
## more may go down tonight. Its tooltip is `Describe.defence`, read out of
## `GameData` when asked. The icons are A005's 16x16 cuts (task 0147), drawn at
## their native size; a defence the pack never drew shows its own sprite
## scaled into the box until its icon lands.

## One slot: the 16x16 icon over two short lines of price, packed closer
## than the theme's own spacing (`UiKit.SLOT_PRICE`).
const SLOT := Vector2(40, 32)
## Its top left: under the log's four lines, over the ammo line at 248.
const AT := Vector2(4, 215)
## Where it must stop: the night HUD's bottom-right controls start at 330.
const RIGHT := 326.0
## How a slot that cannot be paid for looks - an alpha, as the palette's is.
const FADED := Color(1, 1, 1, 0.55)

var _state: Dictionary = {}
var _row: Control
var _built_for := ""
var _page := 0
var _ids: Array = []
var _textures: Dictionary = {}


func show_state(state: Dictionary) -> void:
	_state = state


func _ready() -> void:
	name = "Hotbar"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_row = Control.new()
	_row.name = "HotbarRow"
	_row.position = AT
	_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_row)
	visible = false


## How many slots one page holds.
static func per_page() -> int:
	return maxi(int((RIGHT - AT.x) / SLOT.x), 1)


func _process(_delta: float) -> void:
	if _state.is_empty():
		return
	var phase := int(_state["phase"])
	visible = (phase == Phases.PREPARATION or phase == Phases.NIGHT) \
		and not House.inside(_state) and StringName(_state["open_panel"]) == &""
	if not visible:
		return
	_ids = Building.catalogue(_state)
	var chosen := _ids.find(Building.selected(_state)) if Building.is_active(_state) else -1
	if chosen >= 0:
		_page = chosen / per_page()
	_page = clampi(_page, 0, maxi((_ids.size() - 1) / per_page(), 0))
	var key := _signature(chosen)
	if key != _built_for:
		_built_for = key
		_build(chosen)


## Everything a slot shows, so the row is rebuilt only when one of them moved.
func _signature(chosen: int) -> String:
	var parts: Array = [str(_page), str(chosen), I18n.locale()]
	for id in _ids:
		# Affordable as well as the price: a purse emptied to nothing is short
		# of exactly what the thing costs, so the line alone does not move.
		parts.append("%s:%d:%d:%s:%s" % [id, Crafting.kits(_state, id),
			Building.left_tonight(_state, id), _price_line(id),
			Building.affordable(_state, id)])
	return "|".join(parts)


func _build(chosen: int) -> void:
	# Out of the tree first, then freed: `BuildMode._build_palette` says why.
	for child in _row.get_children():
		_row.remove_child(child)
		child.queue_free()
	var first := _page * per_page()
	for i in range(first, mini(first + per_page(), _ids.size())):
		var id: StringName = _ids[i]
		var slot := Button.new()
		slot.name = "Hotbar_%s" % id
		slot.position = Vector2((i - first) * SLOT.x, 0.0)
		slot.size = SLOT
		slot.custom_minimum_size = SLOT
		slot.toggle_mode = true
		slot.button_pressed = i == chosen
		slot.focus_mode = Control.FOCUS_ALL
		slot.modulate = Color.WHITE if Building.affordable(_state, id) else FADED
		Tooltip.describes(slot, StringName("defence:%s" % id))
		slot.pressed.connect(func() -> void: Building.select(_state, id))
		_row.add_child(slot)

		var icon := TextureRect.new()
		icon.name = "Icon"
		icon.texture = _icon_of(id)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.position = Vector2((SLOT.x - 16.0) * 0.5, 1.0)
		icon.size = Vector2(16, 16)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(icon)

		var keyed := _key_of(i - first)
		if keyed != "":
			var hint := Label.new()
			hint.name = "Key"
			hint.text = keyed
			hint.theme_type_variation = UiKit.DIM
			hint.position = Vector2(2.0, 0.0)
			hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
			slot.add_child(hint)

		var price := Label.new()
		price.name = "Price"
		price.text = _price_line(id)
		price.theme_type_variation = UiKit.SLOT_SHORT if not Building.affordable(_state, id) \
			and Crafting.kits(_state, id) <= 0 else UiKit.SLOT_PRICE
		price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		# **Clipped to the slot**: a label grows to its text, and the next slot
		# drew over the tail of a price that did ("20i 1").
		price.clip_text = true
		price.position = Vector2(0.0, 15.0)
		price.size = Vector2(SLOT.x, SLOT.y - 15.0)
		price.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(price)


## The slot's price, as at most two short lines: the kits when one is banked,
## else the cost - or, when it cannot be paid for, what is short - and the
## nightly allowance left for a thing that has one.
func _price_line(id: StringName) -> String:
	var lines: Array = []
	var banked := Crafting.kits(_state, id)
	if banked > 0:
		lines.append(I18n.f(&"HOTBAR_KITS", [banked]))
	else:
		var cost := Building.cost_of(id)
		var short := Resources.missing(_state, cost)
		lines.append_array(_two_lines(short if not short.is_empty() else cost))
	var limit := int((GameData.DEFENCES.get(id, {}) as Dictionary).get("per_night_limit", 0))
	if limit > 0:
		lines = [lines[0], I18n.f(&"HOTBAR_LEFT", [Building.left_tonight(_state, id)])]
	return "\n".join(lines.slice(0, 2))


## "25i 10o 20w" as "25i 10o" over "20w": a slot is 40 pixels wide.
static func _two_lines(amounts: Dictionary) -> Array:
	var parts: Array = []
	for res in GameData.sorted_names(amounts.keys()):
		parts.append("%d%s" % [amounts[res], str(res).substr(0, 1)])
	if parts.size() <= 2:
		return [" ".join(parts)]
	return [" ".join(parts.slice(0, 2)), " ".join(parts.slice(2))]


## The key a slot answers to, when it is short enough to print on it.
func _key_of(index: int) -> String:
	if index >= 8:
		return ""
	var actions := get_node_or_null(^"/root/Actions")
	if actions == null:
		return ""
	var text: String = actions.text_of(StringName("slot_%d" % (index + 1)))
	return text if text.length() <= 1 else ""


## The defence's `icon_<id>` - A005's eight since task 0147 - or a later
## pack's registered stand-in; a defence no pack has drawn yet falls back to
## its own building sprite, so a new one still shows something.
func _icon_of(id: StringName) -> Texture2D:
	var name := StringName("icon_%s" % id)
	var file := "res://sprites/buildings/%s.png" % id
	if not PlaceholderArt.art(name).is_empty():
		file = PlaceholderArt.texture_path(PlaceholderArt.art_path(name, 0))
	elif ResourceLoader.exists("res://sprites/ui/%s.png" % name):
		file = "res://sprites/ui/%s.png" % name
	if not _textures.has(file):
		_textures[file] = load(file) if ResourceLoader.exists(file) else null
	return _textures[file]


func _unhandled_input(event: InputEvent) -> void:
	if not visible or _ids.is_empty() or _paused():
		return
	for n in 8:
		if event.is_action_pressed(StringName("slot_%d" % (n + 1))):
			var at := _page * per_page() + n
			if at < _ids.size():
				Building.select(_state, _ids[at])
				get_viewport().set_input_as_handled()
			return
	var step := 0
	if event.is_action_pressed(&"hotbar_next"):
		step = 1
	elif event.is_action_pressed(&"hotbar_prev"):
		step = -1
	if step == 0:
		return
	var now := _ids.find(Building.selected(_state)) if Building.is_active(_state) else -1
	# **Wrapping**, and from nothing the first step lands on an end.
	var next := (now + step) % _ids.size() if now >= 0 \
		else (0 if step > 0 else _ids.size() - 1)
	if next < 0:
		next += _ids.size()
	Building.select(_state, _ids[next])
	get_viewport().set_input_as_handled()


func _paused() -> bool:
	var router := get_node_or_null(^"/root/App")
	return router != null and router.has_method(&"paused") and bool(router.call(&"paused"))


# ------------------------------------------------------------- for the checks

## The slot's shown price - for `input_v1`.
func price_of(id: StringName) -> String:
	return _price_line(id)


func page() -> int:
	return _page
