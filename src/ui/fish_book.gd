class_name FishBook
extends VBoxContainer

## **The fish book** (task 0182): a page for each species, the first
## collection that makes a player come back. Its portrait - or its black
## silhouette while it has never been landed - what it is called, how rare
## it is, where and when it bites, how many have come out of the water and
## what one fetches, under the count of the whole collection.
##
## It reads and holds nothing. The run's book is `Fishing.book_of`; every
## run's is `Stats.fish_known` over the profile `Main` hands the inventory;
## which page is up is the inventory's, which turns them with the rest of its
## pages. The portraits are A022's, through 0120's road until 0205 integrates
## them: an unknown species is the same picture drawn black.

## Where and when each species bites, as a sentence a player can act on.
## **Literal keys**, so `tools/i18n_check.py` measures every hint against the
## line it is drawn on (`HINT_WIDTH`).
const HINTS: Dictionary = {
	&"carp": &"BOOK_HINT_CARP",
	&"perch": &"BOOK_HINT_PERCH",
	&"catfish": &"BOOK_HINT_CATFISH",
	&"tilapia": &"BOOK_HINT_TILAPIA",
	&"sunfish": &"BOOK_HINT_SUNFISH",
	&"bream": &"BOOK_HINT_BREAM",
	&"trout": &"BOOK_HINT_TROUT",
	&"pike": &"BOOK_HINT_PIKE",
	&"eel": &"BOOK_HINT_EEL",
	&"dorado": &"BOOK_HINT_DORADO",
	&"salmon": &"BOOK_HINT_SALMON",
	&"sturgeon": &"BOOK_HINT_STURGEON",
	&"old_catfish": &"BOOK_HINT_OLD_CATFISH",
	&"golden_queen": &"BOOK_HINT_GOLDEN_QUEEN",
	&"ghost_pike": &"BOOK_HINT_GHOST_PIKE",
	&"ice_sturgeon": &"BOOK_HINT_ICE_STURGEON",
}

## What each rarity is called on its page.
const TIERS: Dictionary = {
	&"common": &"BOOK_TIER_COMMON",
	&"uncommon": &"BOOK_TIER_UNCOMMON",
	&"rare": &"BOOK_TIER_RARE",
	&"legendary": &"BOOK_TIER_LEGENDARY",
}

## The page's lines are the inventory's rows' width.
const WIDTH := 300
const HINT_WIDTH := 300
## A022's portrait canvas.
const PORTRAIT := Vector2(32, 32)

var _count: Label
var _portrait: TextureRect
var _name: Label
var _tier: Label
var _hint: Label
var _caught: Label
var _first: Label
var _price: Label
var _species := &""
var _known := false


## Every species in the book's order: the fish group's, the commons first and
## the legendaries last.
static func species() -> Array:
	var out: Array = []
	for id in GameData.group_members(GameData.FISH):
		if GameData.FISH_SPECIES.has(id):
			out.append(StringName(id))
	return out


## How many species are in the book at all, and how many of them have been
## landed in any run - the count over every page.
static func collected(known: Dictionary) -> int:
	var count := 0
	for id in species():
		if int(known.get(id, 0)) > 0:
			count += 1
	return count


func _init() -> void:
	name = "FishBook"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(WIDTH, 0)
	_count = _label("BookCount", UiKit.WARM)
	add_child(_count)
	var top := HBoxContainer.new()
	top.name = "BookTop"
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top)
	_portrait = TextureRect.new()
	_portrait.name = "BookPortrait"
	_portrait.custom_minimum_size = PORTRAIT
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(_portrait)
	var titles := VBoxContainer.new()
	titles.name = "BookTitles"
	titles.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(titles)
	_name = _label("BookName", UiKit.WARM)
	_name.custom_minimum_size.x = WIDTH - PORTRAIT.x - 8
	titles.add_child(_name)
	_tier = _label("BookTier", UiKit.DIM)
	_tier.custom_minimum_size.x = _name.custom_minimum_size.x
	titles.add_child(_tier)
	_hint = _label("BookHint", UiKit.DIM)
	_hint.custom_minimum_size.x = HINT_WIDTH
	add_child(_hint)
	_caught = _label("BookCaught", UiKit.DIM)
	add_child(_caught)
	_first = _label("BookFirst", UiKit.DIM)
	add_child(_first)
	_price = _label("BookPrice", UiKit.MONEY)
	add_child(_price)


## Draw `id`'s page: `state` is the run, `profile` every run before it.
func show_page(state: Dictionary, profile: Dictionary, id: StringName) -> void:
	_species = id
	var known := Stats.fish_known(profile, state)
	var landed := int(known.get(id, 0))
	_known = landed > 0
	var all := species()
	_count.text = I18n.f(&"BOOK_COUNT", [collected(known), all.size()])
	_portrait.texture = UiKit.picture(StringName("portrait_%s" % id))
	# **Unknown is a silhouette**: the same picture, drawn black.
	_portrait.modulate = PlaceholderArt.art_tint(StringName("portrait_%s" % id)) \
		if _known else Color.BLACK
	_name.text = Names.of(id) if _known else I18n.t(&"BOOK_UNKNOWN")
	var tier := StringName((GameData.FISH_SPECIES[id] as Dictionary).get("tier", &"common"))
	_tier.text = I18n.t(TIERS.get(tier, &"BOOK_TIER_COMMON"))
	_tier.theme_type_variation = UiKit.GOOD if tier == &"legendary" else UiKit.DIM
	_hint.text = I18n.t(HINTS.get(id, &"BOOK_UNKNOWN"))
	_caught.text = I18n.f(&"BOOK_CAUGHT", [landed]) if _known else I18n.t(&"BOOK_NOT_YET")
	var page: Dictionary = Fishing.book_of(state).get(id, {})
	if page.is_empty():
		_first.text = I18n.t(&"BOOK_NOT_THIS_RUN") if _known else ""
	else:
		var day := int(page["first_day"])
		_first.text = I18n.f(&"BOOK_FIRST", [Names.of(Calendar.season_id(day)),
			Calendar.day_of_season(day)])
	_price.text = I18n.f(&"INV_PRICE", [int(GameData.SELL_PRICE.get(id, 0))]) if _known else ""


## Which species the page is on, and whether it has ever been landed - for
## the checks.
func shown() -> StringName:
	return _species


func known() -> bool:
	return _known


func _label(node_name: String, role: StringName) -> Label:
	var label := Label.new()
	label.name = node_name
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.custom_minimum_size = Vector2(WIDTH, 12)
	label.theme_type_variation = role
	return label
