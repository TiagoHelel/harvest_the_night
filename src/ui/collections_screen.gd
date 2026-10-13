class_name CollectionsScreen
extends Control

## **The collections and the achievements** (task 0287): one book with five
## tabs - the fish, the crops, the bosses' trophies, the years won without
## losing the house and the achievements - each tab carrying its count. It
## reads `Collections` and draws the replies; it holds nothing and decides
## nothing.
##
## ## A sibling of `StatsScreen`
##
## Opened the same two ways - the title menu's COLLECTIONS and, in a run, the
## `collections` key - and both go through the router's COLLECTIONS state, so
## the way out is the router's `back()` whichever way the player came in: the
## key again or cancel in a run, cancel on the title (the title answers that
## one, as it does for the records). Read-only, so like the records it may
## stay open while the night goes on; the farmer just does not walk while the
## pages turn (`Main`).
##
## ## The fish are 0182's book
##
## The fish tab embeds a `FishBook` - the inventory's page, not a second one
## - and turns it with left and right or a click on the strip of species
## under it. The inventory's way into the book keeps working.
##
## ## The keys
##
## The tabs are a column, so up and down move along it - and so do the
## inventory's page keys, `hotbar_prev`/`hotbar_next` (Q/E, a pad's
## shoulders), taken here before the night's hotbar hears them.
##
## ## Placeholders
##
## A056 through 0120's road until 0288 integrates it: the tab books and the
## trophies are `UiKit.picture`s - a trophy is each boss's first walk frame
## in its tint, hung on a plaque `CollectionArt` draws - and the cover, the
## ornament and the badges are `CollectionArt` while `PlaceholderArt.is_drawn`
## says so. **Locked is the earned art dimmed** (`LOCKED`): A056 has no locked
## state to draw.

## The tabs, in their order down the column.
const TABS: Array = [&"fish", &"crops", &"bosses", &"year", &"achievements"]

## The words on each tab, with its count. Literal keys, for `i18n_check`.
const TAB_NAMES: Dictionary = {
	&"fish": &"COLL_TAB_FISH",
	&"crops": &"COLL_TAB_CROPS",
	&"bosses": &"COLL_TAB_BOSSES",
	&"year": &"COLL_TAB_YEAR",
	&"achievements": &"COLL_TAB_ACHIEVEMENTS",
}

## How a crop, trophy or badge not yet had is drawn: its own art, dimmed.
const LOCKED := Color(0.3, 0.3, 0.36)

## The panel, and in it the column (cover, tabs, hint) and the page.
const FRAME := Rect2(8, 12, 464, 246)
const COLUMN_W := 116.0
const TAB_SIZE := Vector2(116, 18)
const PAGE := Rect2(128, 30, 332, 212)

var _state: Dictionary = {}
var _profile: Dictionary = {}
var _tab: StringName = &"fish"
var _fish := 0
var _drawn_for := ""

var _frame: Control
var _tabs: Dictionary = {}          # tab -> Button
var _pages: Dictionary = {}         # tab -> Control
var _hint: Label
var _book: FishBook
var _strip: Array = []              # Button per species
var _marker: ColorRect
var _crop_cells: Dictionary = {}    # crop -> [TextureRect, Label, Label]
var _boss_cells: Dictionary = {}    # boss -> [Control, Label, Label]
var _badges: Dictionary = {}        # id -> [Control, Label, Label]
var _counts: Dictionary = {}        # tab -> Label, the page's count line
var _year_art: Control
var _year_rule: Label
var _year_run: Label
var _year_now: Label


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var shade := ColorRect.new()
	shade.name = "CollectionsShade"
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.color = Color(0.03, 0.02, 0.06, 0.90)
	shade.size = Vector2(480, 270)
	add_child(shade)

	# Task 0079's panel under the whole book, for the reason `StatsScreen`
	# gives: bare labels need something solid under them.
	var backing := Panel.new()
	backing.name = "CollectionsBacking"
	backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backing.position = FRAME.position
	backing.size = FRAME.size
	add_child(backing)

	_frame = Control.new()
	_frame.name = "CollectionsFrame"
	_frame.mouse_filter = Control.MOUSE_FILTER_STOP
	_frame.position = FRAME.position
	_frame.size = FRAME.size
	add_child(_frame)

	# **The column**: the book's cover, its tabs, the keys.
	var cover := _piece(&"collection_cover", CollectionArt.COVER, &"",
		Vector2(48, 64))
	cover.name = "CollectionsCover"
	cover.position = Vector2(4 + (COLUMN_W - 48) / 2.0, 4)
	_frame.add_child(cover)
	for i in TABS.size():
		var which: StringName = TABS[i]
		var tab := Button.new()
		tab.name = "CollectionsTab_%s" % which
		tab.toggle_mode = true
		tab.theme_type_variation = UiKit.TAB
		tab.custom_minimum_size = TAB_SIZE
		tab.size = TAB_SIZE
		tab.position = Vector2(4, 72 + i * (TAB_SIZE.y + 2))
		tab.focus_mode = Control.FOCUS_NONE
		tab.alignment = HORIZONTAL_ALIGNMENT_LEFT
		tab.icon = UiKit.tinted_picture(StringName("hud_book_%s" % which))
		tab.pressed.connect(show_tab.bind(which))
		_frame.add_child(tab)
		_tabs[which] = tab
	_hint = _label("CollectionsHint", Vector2(4, 176), UiKit.DIM, _frame)
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.custom_minimum_size = Vector2(COLUMN_W, 0)
	_hint.size = Vector2(COLUMN_W, 60)

	# **The page's head**: the title and the ornament under it.
	var heading := _label("CollectionsHeading", Vector2(PAGE.position.x, 2),
		UiKit.WARM, _frame)
	heading.text = I18n.t(&"COLL_TITLE")
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.size = Vector2(PAGE.size.x, 12)
	var ornament := _piece(&"collection_ornament", CollectionArt.ORNAMENT, &"",
		Vector2(64, 12))
	ornament.name = "CollectionsOrnament"
	ornament.position = Vector2(PAGE.position.x + (PAGE.size.x - 64) / 2.0, 14)
	_frame.add_child(ornament)

	for which in TABS:
		var page := Control.new()
		page.name = "CollectionsPage_%s" % which
		page.mouse_filter = Control.MOUSE_FILTER_IGNORE
		page.position = PAGE.position
		page.size = PAGE.size
		page.visible = false
		_frame.add_child(page)
		_pages[which] = page
	_build_fish(_pages[&"fish"])
	_build_crops(_pages[&"crops"])
	_build_bosses(_pages[&"bosses"])
	_build_year(_pages[&"year"])
	_build_achievements(_pages[&"achievements"])
	show_tab(_tab)


# ------------------------------------------------------------------ the pages

func _build_fish(page: Control) -> void:
	_book = FishBook.new()
	_book.position = Vector2.ZERO
	page.add_child(_book)
	var species := Collections.fish_ids()
	var pitch := minf(21.0, PAGE.size.x / maxf(species.size(), 1))
	for i in species.size():
		var id: StringName = species[i]
		var cell := Button.new()
		cell.name = "CollectionsFish_%s" % id
		cell.flat = true
		cell.focus_mode = Control.FOCUS_NONE
		cell.icon = UiKit.tinted_picture(StringName("icon_%s" % id))
		if cell.icon == null:
			cell.icon = UiKit.icon(id)
		cell.custom_minimum_size = Vector2(18, 18)
		cell.size = Vector2(18, 18)
		cell.position = Vector2(i * pitch, 122)
		cell.pressed.connect(_turn_to.bind(i))
		page.add_child(cell)
		_strip.append(cell)
	_marker = ColorRect.new()
	_marker.name = "CollectionsFishMarker"
	_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_marker.color = UiKit.colour(UiKit.WARM)
	_marker.size = Vector2(14, 1)
	page.add_child(_marker)
	_label("CollectionsFishTurn", Vector2(0, 146), UiKit.DIM, page).text = \
		I18n.t(&"COLL_FISH_TURN")


func _build_crops(page: Control) -> void:
	_counts[&"crops"] = _label("CollectionsCount_crops", Vector2.ZERO, UiKit.WARM, page)
	var crops := Collections.crop_ids()
	for i in crops.size():
		var crop: StringName = crops[i]
		var at := Vector2((i % 3) * 110.0, 16 + (i / 3) * 30.0)
		var icon := TextureRect.new()
		icon.name = "CollectionsCrop_%s" % crop
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.texture = UiKit.tinted_picture(StringName("icon_%s" % crop))
		if icon.texture == null:
			icon.texture = UiKit.icon(crop)
		icon.position = at + Vector2(0, 2)
		icon.size = Vector2(16, 16)
		page.add_child(icon)
		var name_label := _label("CollectionsCropName_%s" % crop, at + Vector2(20, 0),
			UiKit.DIM, page)
		name_label.text = Names.of(crop)
		var count := _label("CollectionsCropCount_%s" % crop, at + Vector2(20, 10),
			UiKit.DIM, page)
		_crop_cells[crop] = [icon, name_label, count]


func _build_bosses(page: Control) -> void:
	_counts[&"bosses"] = _label("CollectionsCount_bosses", Vector2.ZERO, UiKit.WARM, page)
	var bosses := Collections.boss_ids()
	for i in bosses.size():
		var boss: StringName = bosses[i]
		var at := Vector2(i * 83.0, 16)
		var trophy := _trophy(boss)
		trophy.position = at + Vector2(25, 0)
		page.add_child(trophy)
		var name_label := _label("CollectionsBossName_%s" % boss, at + Vector2(0, 36),
			UiKit.DIM, page)
		name_label.text = Names.of(boss)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_label.custom_minimum_size = Vector2(83, 0)
		name_label.size = Vector2(83, 20)
		var count := _label("CollectionsBossCount_%s" % boss, at + Vector2(0, 58),
			UiKit.DIM, page)
		count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		count.size = Vector2(83, 12)
		_boss_cells[boss] = [trophy, name_label, count]
	_label("CollectionsBossRule", Vector2(0, 92), UiKit.DIM, page).text = \
		I18n.t(&"COLL_BOSSES_RULE")


func _build_year(page: Control) -> void:
	_counts[&"year"] = _label("CollectionsCount_year", Vector2.ZERO, UiKit.WARM, page)
	var art := TextureRect.new()
	art.name = "CollectionsYearArt"
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	art.texture = UiKit.tinted_picture(&"icon_book_year")
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.position = Vector2(0, 18)
	art.size = Vector2(32, 32)
	page.add_child(art)
	_year_art = art
	_year_rule = _label("CollectionsYearRule", Vector2(40, 18), UiKit.DIM, page)
	_year_rule.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_year_rule.custom_minimum_size = Vector2(PAGE.size.x - 40, 0)
	_year_rule.size = Vector2(PAGE.size.x - 40, 22)
	_year_rule.text = I18n.t(&"COLL_YEAR_RULE")
	_year_run = _label("CollectionsYearRun", Vector2(40, 44), UiKit.COOL, page)
	_year_now = _label("CollectionsYearNow", Vector2(40, 56), UiKit.DIM, page)


func _build_achievements(page: Control) -> void:
	_counts[&"achievements"] = _label("CollectionsCount_achievements", Vector2.ZERO,
		UiKit.WARM, page)
	# **The table's order**, first night first: a constant's keys keep the
	# order they were written in, and this only draws them.
	var ids: Array = GameData.ACHIEVEMENTS.keys()
	for i in ids.size():
		var id := StringName(ids[i])
		var one: Dictionary = GameData.ACHIEVEMENTS[id]
		var at := Vector2((i % 2) * 166.0, 14 + (i / 2) * 32.0)
		var badge := _piece(StringName("badge_%s" % id), CollectionArt.BADGE, id,
			Vector2(24, 24))
		badge.name = "CollectionsBadge_%s" % id
		badge.position = at + Vector2(0, 2)
		page.add_child(badge)
		var name_label := _label("CollectionsAchName_%s" % id, at + Vector2(28, 0),
			UiKit.DIM, page)
		name_label.text = I18n.t(one["name"])
		var desc := _label("CollectionsAchDesc_%s" % id, at + Vector2(28, 10),
			UiKit.DIM, page)
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.custom_minimum_size = Vector2(138, 0)
		desc.size = Vector2(138, 20)
		desc.text = describe(id)
		_badges[id] = [badge, name_label, desc]


## An achievement's line, its threshold filled in where the line has a place
## for it - so a designer turning the `# LEVER` turns the words with it.
static func describe(id: StringName) -> String:
	var one: Dictionary = GameData.ACHIEVEMENTS.get(id, {})
	if one.is_empty():
		return ""
	var text := I18n.t(one["desc"])
	return text % [int(one.get("n", 1))] if text.contains("%d") else text


# ------------------------------------------------------------- the art, drawn

## One of A056's pieces: the pack's picture once it has arrived, and until
## then `CollectionArt` drawing it in its box (`PlaceholderArt.is_drawn`).
func _piece(name: StringName, kind: int, id: StringName, box: Vector2) -> Control:
	var path := "%s%s.png" % [UiKit.DIR, name]
	if PlaceholderArt.is_drawn(path):
		return CollectionArt.make(kind, id)
	var art := TextureRect.new()
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	art.texture = UiKit.tinted_picture(name)
	art.size = box
	art.custom_minimum_size = box
	return art


## A boss's trophy: A056's own once it lands; until then the boss's first
## walk frame, in its tint, on a plaque drawn by code.
func _trophy(boss: StringName) -> Control:
	var name := StringName("trophy_%s" % boss)
	var holder := Control.new()
	holder.name = "CollectionsTrophy_%s" % boss
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.size = Vector2(32, 32)
	if not PlaceholderArt.art(name).is_empty():
		holder.add_child(CollectionArt.make(CollectionArt.PLAQUE))
	var art := TextureRect.new()
	art.name = "TrophyArt"
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	art.texture = UiKit.picture(name)
	art.self_modulate = PlaceholderArt.art_tint(name)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if not PlaceholderArt.art(name).is_empty():
		art.position = Vector2(4, 4)
		art.size = Vector2(24, 22)
	else:
		art.size = Vector2(32, 32)
	holder.add_child(art)
	return holder


func _label(node_name: String, at: Vector2, role: StringName,
		parent: Control) -> Label:
	var label := Label.new()
	label.name = node_name
	label.position = at
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.theme_type_variation = role
	parent.add_child(label)
	return label


# ------------------------------------------------------------------- the frame

## The run, or an empty dictionary on the title: the collections are then the
## profile's alone.
func show_state(state: Dictionary) -> void:
	_state = state
	_drawn_for = ""


## The profile every collection but this run's unbanked part comes from.
func show_profile(profile: Dictionary) -> void:
	_profile = profile
	_drawn_for = ""


func is_open() -> bool:
	return visible


func open() -> void:
	visible = true
	_drawn_for = ""


func close() -> void:
	visible = false


## Which tab is up, and which species the fish page is on - for the checks.
func tab() -> StringName:
	return _tab


func fish_page() -> StringName:
	return _book.shown() if _book != null else &""


func show_tab(which: StringName) -> void:
	if not TABS.has(which):
		return
	_tab = which
	for one in TABS:
		(_pages[one] as Control).visible = one == which
		(_tabs[one] as Button).set_pressed_no_signal(one == which)
	_drawn_for = ""


## Along the tabs by `step`, wrapping.
func turn_tab(step: int) -> void:
	show_tab(TABS[posmod(TABS.find(_tab) + step, TABS.size())])


## Along the fish book by `step`, wrapping.
func turn_fish(step: int) -> void:
	_turn_to(_fish + step)


func _turn_to(index: int) -> void:
	_fish = posmod(index, maxi(Collections.fish_ids().size(), 1))
	_drawn_for = ""


func _input(event: InputEvent) -> void:
	if not visible:
		return
	var step := 0
	if event.is_action_pressed(&"hotbar_prev") or event.is_action_pressed(&"ui_up"):
		step = -1
	elif event.is_action_pressed(&"hotbar_next") or event.is_action_pressed(&"ui_down"):
		step = 1
	if step != 0:
		turn_tab(step)
		get_viewport().set_input_as_handled()
		return
	if _tab != &"fish":
		return
	if event.is_action_pressed(&"ui_left"):
		turn_fish(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"ui_right"):
		turn_fish(1)
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	# **In a run the key asks the router**, as the records' does: one way in
	# and one way out, and `Main` opens and closes this by the router's state.
	# On the title there is no run and the menu is the way in.
	var router := get_node_or_null(^"/root/App")
	if router != null and not _state.is_empty():
		if Input.is_action_just_pressed(&"collections"):
			if visible:
				router.back()
			else:
				router.goto(router.COLLECTIONS)
		if visible and Input.is_action_just_pressed(&"cancel"):
			router.back()
	if not visible:
		return
	var counts := Collections.counts(_profile, _state)
	var signature := "%s/%d/%s/%d/%s/%s" % [_tab, _fish, str(counts),
		I18n.revision(), _keys(), str(Stats.of_run(_state)["nights"]) if not _state.is_empty() else "-"]
	if signature == _drawn_for:
		return
	_drawn_for = signature
	_refresh(counts)


func _keys() -> String:
	var actions := get_tree().root.get_node_or_null(^"Actions") if is_inside_tree() else null
	if actions == null:
		return "--"
	return "%s/%s/%s" % [actions.text_of(&"hotbar_prev"), actions.text_of(&"hotbar_next"),
		actions.text_of(&"collections")]


func _refresh(counts: Dictionary) -> void:
	for which in TABS:
		var tab_button: Button = _tabs[which]
		match which:
			&"year":
				tab_button.text = I18n.f(TAB_NAMES[which], [int(counts["year"])])
			_:
				var pair: Array = counts[String(which) if which != &"bosses" else "trophies"]
				tab_button.text = I18n.f(TAB_NAMES[which], [pair[0], pair[1]])
	var keys := _keys().split("/")
	if _state.is_empty():
		_hint.text = I18n.f(&"COLL_HINT_TITLE", [keys[0], keys[1]])
	else:
		_hint.text = I18n.f(&"COLL_HINT_RUN", [keys[0], keys[1], keys[2]])
	match _tab:
		&"fish":
			_refresh_fish()
		&"crops":
			_refresh_crops(counts)
		&"bosses":
			_refresh_bosses(counts)
		&"year":
			_refresh_year(counts)
		&"achievements":
			_refresh_achievements(counts)


func _refresh_fish() -> void:
	var species := Collections.fish_ids()
	if species.is_empty():
		return
	_fish = clampi(_fish, 0, species.size() - 1)
	_book.show_page(_state, _profile, species[_fish])
	var known := Collections.fish(_profile, _state)
	for i in _strip.size():
		var cell: Button = _strip[i]
		# **Unknown is a silhouette**, as on the book's own page.
		cell.modulate = Color.WHITE if int(known.get(species[i], 0)) > 0 else Color.BLACK
	var at: Button = _strip[_fish]
	_marker.position = at.position + Vector2(2, 19)


func _refresh_crops(counts: Dictionary) -> void:
	_counts[&"crops"].text = I18n.f(&"COLL_CROPS_COUNT", counts["crops"])
	var field := Collections.crops(_profile, _state)
	for crop in GameData.sorted_names(_crop_cells.keys()):
		var cell: Array = _crop_cells[crop]
		var had := int(field.get(crop, 0))
		(cell[0] as TextureRect).modulate = Color.WHITE if had > 0 else LOCKED
		(cell[1] as Label).theme_type_variation = UiKit.WARM if had > 0 else UiKit.DIM
		(cell[2] as Label).text = I18n.f(&"COLL_CROP_HARVESTED", [had]) if had > 0 \
			else I18n.t(&"COLL_NOT_YET")


func _refresh_bosses(counts: Dictionary) -> void:
	_counts[&"bosses"].text = I18n.f(&"COLL_BOSSES_COUNT", counts["trophies"])
	var fell := Collections.trophies(_profile, _state)
	for boss in GameData.sorted_names(_boss_cells.keys()):
		var cell: Array = _boss_cells[boss]
		var times := int(fell.get(boss, 0))
		(cell[0] as Control).modulate = Color.WHITE if times > 0 else LOCKED
		(cell[1] as Label).theme_type_variation = UiKit.WARM if times > 0 else UiKit.DIM
		(cell[2] as Label).text = I18n.f(&"COLL_BOSS_FELL", [times]) if times > 0 \
			else I18n.t(&"COLL_NOT_YET")


func _refresh_year(counts: Dictionary) -> void:
	var years := int(counts["year"])
	_counts[&"year"].text = I18n.f(&"COLL_YEAR_COUNT", [years])
	_year_art.modulate = Color.WHITE if years > 0 else LOCKED
	if _state.is_empty():
		_year_run.text = ""
		_year_now.text = I18n.t(&"COLL_YEAR_NO_RUN")
		return
	var lost := int((_state.get("stats", {}) as Dictionary).get("nights_lost", 0))
	_year_run.text = I18n.f(&"COLL_YEAR_RUN", [lost])
	if Collections.year_earned(_state):
		_year_now.text = I18n.t(&"COLL_YEAR_DONE")
	elif lost > 0:
		_year_now.text = I18n.t(&"COLL_YEAR_BROKEN")
	else:
		_year_now.text = I18n.t(&"COLL_YEAR_ON_TRACK")


func _refresh_achievements(counts: Dictionary) -> void:
	_counts[&"achievements"].text = I18n.f(&"COLL_ACH_COUNT", counts["achievements"])
	var earned: Dictionary = _profile.get("achievements", {})
	for id in GameData.sorted_names(_badges.keys()):
		var cell: Array = _badges[id]
		var has := bool(earned.get(id, false))
		(cell[0] as Control).modulate = Color.WHITE if has else LOCKED
		(cell[1] as Label).theme_type_variation = UiKit.WARM if has else UiKit.DIM
		(cell[1] as Label).text = I18n.t(GameData.ACHIEVEMENTS[id]["name"])
		(cell[2] as Label).text = describe(StringName(id))
