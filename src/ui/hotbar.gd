class_name Hotbar
extends Control

## **The night's shop window** (task 0133): every defence the catalogue
## offers, along the bottom from the build step to the morning, each with its
## icon and its price - so what the day earned is there to see as walls and
## towers, not as a text list.
##
## **Built from `Building.catalogue`**, in its order, never from a list here:
## a defence added to `GameData.DEFENCES` gets a slot with no edit.
##
## **A page a season** (task 0234): spring's six, then summer's, autumn's and
## winter's, each from the cheapest (the catalogue's order). The page is the
## one holding the selection - the first, spring's, with nothing picked (task
## 0224) - and the page turner at the row's end shows the season and turns it
## with a click, without picking anything. A season the calendar has not
## reached is shown greyed, its prices there to save for.
##
## It decides nothing. A slot is picked with a click, `slot_1`..`slot_8` (the
## seed keys by day, which `DayHud` leaves alone at night) on the page shown,
## or `hotbar_prev` / `hotbar_next` (the bumpers on a pad, Q and E on the
## keyboard) a slot at a time through every page, and every way goes through
## `Building.select` - the road the day palette's rows take. `cancel` clears
## it through `BuildMode`, and the cursor goes back to inspecting.
##
## A slot shows the kit count when one is banked, with the money placing it
## still charges (task 0234), and the price otherwise - money first - or,
## greyed, what is short; and for a defence with a nightly limit how many more
## may go down tonight. Its tooltip is `Describe.defence`, read out of
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
## **The page turner** (task 0234): an arrow either side of the season's
## name and where its page is among them, at the row's right end.
const PAGER := Vector2(78, 32)
const ARROW := Vector2(12, 32)

var _state: Dictionary = {}
var _row: Control
var _pager: Control
var _built_for := ""
var _page := 0
var _ids: Array = []
var _pages: Array = []
## The selection the page last followed, so a turned page stays turned until
## something else is picked.
var _followed: StringName = &""
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
	_build_pager()
	visible = false


## How many slots one page holds: the row left of the page turner.
static func per_page() -> int:
	return maxi(int((RIGHT - AT.x - PAGER.x) / SLOT.x), 1)


## **The pages** (task 0234): the catalogue's ids, a season to a page in its
## order, and a season with more than a page goes on to the next one.
static func pages_of(ids: Array) -> Array:
	var out: Array = []
	var season := -1
	for id in ids:
		var at := Building.season_of(StringName(id))
		if at != season or (out.back() as Array).size() >= per_page():
			out.append([])
			season = at
		(out.back() as Array).append(id)
	return out


func _build_pager() -> void:
	_pager = Control.new()
	_pager.name = "HotbarPages"
	_pager.position = AT + Vector2(per_page() * SLOT.x + 2.0, 0.0)
	_pager.size = PAGER
	_pager.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_pager)
	for side in [[-1, "HotbarPrev", &"HOTBAR_PAGE_PREV", 0.0], [1, "HotbarNext", &"HOTBAR_PAGE_NEXT", PAGER.x - ARROW.x]]:
		var arrow := Button.new()
		arrow.name = side[1]
		arrow.text = I18n.t(side[2])
		arrow.position = Vector2(float(side[3]), 0.0)
		arrow.size = ARROW
		arrow.custom_minimum_size = ARROW
		# Clicked, never focused: the bumpers step through every slot already.
		arrow.focus_mode = Control.FOCUS_NONE
		arrow.pressed.connect(turn.bind(int(side[0])))
		_pager.add_child(arrow)
	for line in [["HotbarSeason", 3.0], ["HotbarPage", 17.0]]:
		var label := Label.new()
		label.name = line[0]
		label.position = Vector2(ARROW.x, float(line[1]))
		label.size = Vector2(PAGER.x - 2.0 * ARROW.x, 12.0)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.clip_text = true
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_pager.add_child(label)


func _process(_delta: float) -> void:
	if _state.is_empty():
		return
	var phase := int(_state["phase"])
	visible = (phase == Phases.PREPARATION or phase == Phases.NIGHT) \
		and not House.inside(_state) and StringName(_state["open_panel"]) == &""
	if not visible:
		return
	_ids = Building.catalogue(_state)
	_pages = pages_of(_ids)
	var picked := Building.selected(_state) if Building.is_active(_state) else &""
	# **The page follows the selection, and the first page with nothing
	# picked** (task 0224): once something is put away the slots and the keys
	# a player knows are back where they were. A page turned by hand stays
	# turned until something else is picked.
	if picked != _followed:
		_followed = picked
		_page = maxi(_page_holding(picked), 0) if picked != &"" else 0
	_page = clampi(_page, 0, maxi(_pages.size() - 1, 0))
	var chosen := (_pages[_page] as Array).find(picked) if not _pages.is_empty() and picked != &"" else -1
	var key := _signature(chosen)
	if key != _built_for:
		_built_for = key
		_build(chosen)


## The page an id is on, or -1.
func _page_holding(id: StringName) -> int:
	for i in _pages.size():
		if (_pages[i] as Array).has(id):
			return i
	return -1


## **Turn the page** (task 0234), round from the last to the first: the
## arrows' click. Nothing is picked; the keys `slot_1`.. pick on the page shown.
func turn(step: int) -> void:
	if _pages.is_empty():
		return
	_page = posmod(_page + step, _pages.size())
	_built_for = ""


## Everything a slot shows, so the row is rebuilt only when one of them moved.
func _signature(chosen: int) -> String:
	var parts: Array = [str(_page), str(_pages.size()), str(chosen), I18n.locale()]
	for id in (_pages[_page] if not _pages.is_empty() else []):
		# Affordable as well as the price: a purse emptied to nothing is short
		# of exactly what the thing costs, so the line alone does not move.
		parts.append("%s:%d:%d:%s:%s:%s" % [id, Crafting.kits(_state, id),
			Building.left_tonight(_state, id), _price_line(id),
			Building.affordable(_state, id), Building.unlocked(_state, id)])
	return "|".join(parts)


func _build(chosen: int) -> void:
	# Out of the tree first, then freed: `BuildMode._build_palette` says why.
	for child in _row.get_children():
		_row.remove_child(child)
		child.queue_free()
	var page: Array = _pages[_page] if not _pages.is_empty() else []
	for i in page.size():
		var id: StringName = page[i]
		var open := Building.unlocked(_state, id)
		var paid := Building.affordable(_state, id)
		var slot := Button.new()
		slot.name = "Hotbar_%s" % id
		slot.position = Vector2(i * SLOT.x, 0.0)
		slot.size = SLOT
		slot.custom_minimum_size = SLOT
		slot.toggle_mode = true
		slot.button_pressed = i == chosen
		slot.focus_mode = Control.FOCUS_ALL
		# **Greyed before its season** (task 0234), as when it cannot be paid for.
		slot.modulate = Color.WHITE if open and paid else FADED
		Tooltip.describes(slot, StringName("defence:%s" % id))
		slot.pressed.connect(func() -> void: Building.select(_state, id))
		_row.add_child(slot)

		var icon := TextureRect.new()
		icon.name = "Icon"
		icon.texture = _icon_of(id)
		# A stand-in's own tint (task 0225's bait, the fish rotted green; a
		# stand-in tower's, task 0226's hive, when it has no icon); white for
		# real art.
		var tinted := StringName("icon_%s" % id)
		icon.modulate = PlaceholderArt.art_tint(tinted if not PlaceholderArt.art(tinted).is_empty() else id)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.position = Vector2((SLOT.x - 16.0) * 0.5, 1.0)
		icon.size = Vector2(16, 16)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(icon)

		var keyed := _key_of(i)
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
		price.theme_type_variation = UiKit.SLOT_SHORT if open and not paid \
			and Crafting.kits(_state, id) <= 0 else UiKit.SLOT_PRICE
		price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		# **Clipped to the slot**: a label grows to its text, and the next slot
		# drew over the tail of a price that did ("20i 1").
		price.clip_text = true
		price.position = Vector2(0.0, 15.0)
		price.size = Vector2(SLOT.x, SLOT.y - 15.0)
		price.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(price)
	_dress_pager(page)


## The page turner's words: the page's season - dim until the calendar has
## reached it - and where the page is among them.
func _dress_pager(page: Array) -> void:
	var season := Building.season_of(StringName(page[0])) if not page.is_empty() else 0
	var named := _pager.get_node(^"HotbarSeason") as Label
	named.text = Names.of(StringName(GameData.SEASONS[season]))
	named.theme_type_variation = UiKit.DIM if not Calendar.season_reached(_state, season) else &""
	(_pager.get_node(^"HotbarPage") as Label).text = I18n.f(&"HOTBAR_PAGE", [_page + 1, maxi(_pages.size(), 1)])
	(_pager.get_node(^"HotbarPage") as Label).theme_type_variation = UiKit.DIM
	for arrow in [^"HotbarPrev", ^"HotbarNext"]:
		(_pager.get_node(arrow) as Button).text = I18n.t(&"HOTBAR_PAGE_PREV" if arrow == ^"HotbarPrev" else &"HOTBAR_PAGE_NEXT")
	_pager.visible = _pages.size() > 1


## The slot's price, as at most two short lines: the kits when one is banked
## and the money placing one still charges, else the cost - money first - or,
## when it cannot be paid for and its season is open, what is short; and the
## nightly allowance left for a thing that has one.
func _price_line(id: StringName) -> String:
	var lines: Array = []
	var banked := Crafting.kits(_state, id)
	# A thing from a kit only (task 0225) counts its kits, none and all: its
	# cost is fish nobody can pay at night.
	if banked > 0 or Building.kit_only(id):
		var kits := I18n.f(&"HOTBAR_KITS", [banked])
		var money := Building.money_of(id)
		lines.append(kits if money <= 0 else "%s %s" % [kits, I18n.f(&"HOTBAR_MONEY", [money])])
	else:
		var cost := Building.cost_of(id)
		# A season not reached shows what it will cost, to save for, rather
		# than what is short tonight (task 0234).
		var short := Resources.missing(_state, cost) if Building.unlocked(_state, id) else {}
		lines.append_array(_two_lines(short if not short.is_empty() else cost))
	var limit := int((GameData.DEFENCES.get(id, {}) as Dictionary).get("per_night_limit", 0))
	if limit > 0:
		lines = [lines[0], I18n.f(&"HOTBAR_LEFT", [Building.left_tonight(_state, id)])]
	return "\n".join(lines.slice(0, 2))


## "$15 12i 10w" as "$15 12i" over "10w": a slot is 40 pixels wide, and the
## money goes first (task 0234).
static func _two_lines(amounts: Dictionary) -> Array:
	var parts: Array = []
	if amounts.has(GameData.MONEY):
		parts.append(I18n.f(&"HOTBAR_MONEY", [int(amounts[GameData.MONEY])]))
	for res in GameData.sorted_names(amounts.keys()):
		if res != GameData.MONEY:
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
## pack's registered stand-in (A045's since task 0234); a defence no pack has
## drawn yet falls back to its own building sprite, so a new one still shows
## something - the drawing made in code when that is all there is (task
## 0224's decoy, until A037).
func _icon_of(id: StringName) -> Texture2D:
	var name := StringName("icon_%s" % id)
	var file := "res://sprites/buildings/%s.png" % id
	var registered := "" if PlaceholderArt.art(name).is_empty() else PlaceholderArt.art_path(name, 0)
	if registered != "" and PlaceholderArt.is_drawn(registered):
		# **Drawn in code until A045 lands** (task 0234): the defence's own
		# drawing, as on the farm.
		return _drawn(id)
	if registered != "":
		file = PlaceholderArt.texture_path(registered)
	elif ResourceLoader.exists("res://sprites/ui/%s.png" % name):
		file = "res://sprites/ui/%s.png" % name
	elif PlaceholderArt.is_drawn(file):
		return _drawn(id)
	elif not PlaceholderArt.art(id).is_empty():
		# **A stand-in tower** (task 0226's hive, until A038): its own
		# stand-in, scaled into the box.
		file = PlaceholderArt.texture_path(PlaceholderArt.art_path(id, 0))
	if not _textures.has(file):
		_textures[file] = load(file) if ResourceLoader.exists(file) else null
	return _textures[file]


## A defence's own art as its icon: the decoy's, the garlic braid's (task
## 0228; A040's since 0239), the electric fence's (task 0230; A042's since
## 0241) or the sandbags' (task 0231, drawn in code until A043 lands).
static func _drawn(id: StringName) -> Texture2D:
	var drawn := DecoyArt.texture(id)
	if drawn == null:
		drawn = GarlicArt.texture(id)
	if drawn == null:
		drawn = ElectricFenceArt.icon(id)
	return drawn if drawn != null else StrongWallArt.icon(id)


func _unhandled_input(event: InputEvent) -> void:
	if not visible or _ids.is_empty() or _paused():
		return
	for n in 8:
		if event.is_action_pressed(StringName("slot_%d" % (n + 1))):
			# **On the page shown** (task 0234).
			var page: Array = _pages[_page] if _page < _pages.size() else []
			if n < page.size():
				Building.select(_state, page[n])
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


## The pages as shown, for the checks.
func pages() -> Array:
	return _pages.duplicate(true)
