class_name Names
extends RefCounted

## What the things in the game are called, in whatever language is up.
##
## **The rules hold ids and this holds names.** `src/core/` says `&"wheat"`
## and never says "wheat", which is what lets a Portuguese player harvest
## trigo off the same tile - and what keeps a rule from depending on a
## setting. Before task 0097 the id *was* the name: a screen printed
## `String(id).replace("_", " ")` and got "gun tower", which is a translation
## system that only works in one language.
##
## ## Every key is a literal here
##
## The obvious shortcut is `&"ITEM_%s" % id.to_upper()`, and it is wrong for
## one reason: `tools/i18n_check.py` finds keys by reading the source, and a
## key that is assembled at runtime is a key it cannot see - so a missing
## Portuguese name would be found by a player rather than by the check. One
## table, one line per thing, every key written out.

## Data id -> the key that names it.
const KEYS: Dictionary = {
	&"hoe": &"TOOL_HOE",
	&"hoe_basic": &"TOOL_HOE_BASIC",
	&"hoe_iron": &"TOOL_HOE_IRON",
	&"upgrade_hoe_iron": &"REC_UPGRADE_HOE_IRON",
	&"hoe_gold": &"TOOL_HOE_GOLD",
	&"upgrade_hoe_gold": &"REC_UPGRADE_HOE_GOLD",
	&"can": &"TOOL_CAN",
	&"can_basic": &"TOOL_CAN_BASIC",
	&"can_iron": &"TOOL_CAN_IRON",
	&"upgrade_can_iron": &"REC_UPGRADE_CAN_IRON",
	&"can_gold": &"TOOL_CAN_GOLD",
	&"upgrade_can_gold": &"REC_UPGRADE_CAN_GOLD",
	&"axe": &"TOOL_AXE",
	&"axe_basic": &"TOOL_AXE_BASIC",
	&"axe_iron": &"TOOL_AXE_IRON",
	&"upgrade_axe_iron": &"REC_UPGRADE_AXE_IRON",
	&"axe_gold": &"TOOL_AXE_GOLD",
	&"upgrade_axe_gold": &"REC_UPGRADE_AXE_GOLD",
	&"pickaxe": &"TOOL_PICKAXE",
	&"pickaxe_basic": &"TOOL_PICKAXE_BASIC",
	&"pickaxe_iron": &"TOOL_PICKAXE_IRON",
	&"upgrade_pickaxe_iron": &"REC_UPGRADE_PICKAXE_IRON",
	&"pickaxe_gold": &"TOOL_PICKAXE_GOLD",
	&"upgrade_pickaxe_gold": &"REC_UPGRADE_PICKAXE_GOLD",
	&"rod": &"TOOL_ROD",
	&"rod_bamboo": &"TOOL_ROD_BAMBOO",
	&"rod_fibre": &"TOOL_ROD_FIBRE",
	&"upgrade_rod_fibre": &"REC_UPGRADE_ROD_FIBRE",
	&"rod_iron": &"TOOL_ROD_IRON",
	&"upgrade_rod_iron": &"REC_UPGRADE_ROD_IRON",
	# ---- what a farm produces and a shop buys
	&"wood": &"ITEM_WOOD",
	&"hardwood": &"ITEM_HARDWOOD",
	&"stone": &"ITEM_STONE",
	&"iron": &"ITEM_IRON",
	&"copper": &"ITEM_COPPER",
	&"coal": &"ITEM_COAL",
	&"gold": &"ITEM_GOLD",
	&"food": &"ITEM_FOOD",
	&"fish": &"ITEM_FISH",
	&"carp": &"ITEM_CARP",
	&"perch": &"ITEM_PERCH",
	&"catfish": &"ITEM_CATFISH",
	&"tilapia": &"ITEM_TILAPIA",
	&"sunfish": &"ITEM_SUNFISH",
	&"bream": &"ITEM_BREAM",
	&"trout": &"ITEM_TROUT",
	&"pike": &"ITEM_PIKE",
	&"eel": &"ITEM_EEL",
	&"dorado": &"ITEM_DORADO",
	&"salmon": &"ITEM_SALMON",
	&"sturgeon": &"ITEM_STURGEON",
	&"old_catfish": &"ITEM_OLD_CATFISH",
	&"golden_queen": &"ITEM_GOLDEN_QUEEN",
	&"ghost_pike": &"ITEM_GHOST_PIKE",
	&"ice_sturgeon": &"ITEM_ICE_STURGEON",
	&"worm": &"ITEM_WORM",
	&"bait": &"ITEM_BAIT",
	&"straw": &"ITEM_STRAW",
	&"hay": &"ITEM_HAY",
	&"egg": &"ITEM_EGG",
	&"milk": &"ITEM_MILK",
	&"wool": &"ITEM_WOOL",
	&"truffle": &"ITEM_TRUFFLE",
	&"wine": &"ITEM_WINE",
	&"juice": &"ITEM_JUICE",
	&"jelly": &"ITEM_JELLY",
	&"pickles": &"ITEM_PICKLES",
	&"cheese": &"ITEM_CHEESE",
	&"butter": &"ITEM_BUTTER",
	&"cloth": &"ITEM_CLOTH",
	&"sandbag": &"ITEM_SANDBAG",
	&"flour": &"ITEM_FLOUR",
	&"sugar": &"ITEM_SUGAR",
	&"oil": &"ITEM_OIL",
	&"wheat": &"ITEM_WHEAT",
	&"corn": &"ITEM_CORN",
	&"carrot": &"ITEM_CARROT",
	&"potato": &"ITEM_POTATO",
	&"garlic": &"ITEM_GARLIC",
	&"strawberry": &"ITEM_STRAWBERRY",
	&"pepper": &"ITEM_PEPPER",
	&"sunflower": &"ITEM_SUNFLOWER",
	&"melon": &"ITEM_MELON",
	&"pumpkin": &"ITEM_PUMPKIN",
	&"grape": &"ITEM_GRAPE",
	&"beet": &"ITEM_BEET",
	&"carrot_seed": &"ITEM_CARROT_SEED",
	&"potato_seed": &"ITEM_POTATO_SEED",
	&"garlic_seed": &"ITEM_GARLIC_SEED",
	&"strawberry_seed": &"ITEM_STRAWBERRY_SEED",
	&"corn_seed": &"ITEM_CORN_SEED",
	&"pepper_seed": &"ITEM_PEPPER_SEED",
	&"sunflower_seed": &"ITEM_SUNFLOWER_SEED",
	&"melon_seed": &"ITEM_MELON_SEED",
	&"wheat_seed": &"ITEM_WHEAT_SEED",
	&"pumpkin_seed": &"ITEM_PUMPKIN_SEED",
	&"grape_seed": &"ITEM_GRAPE_SEED",
	&"beet_seed": &"ITEM_BEET_SEED",
	&"meat": &"ITEM_MEAT",
	&"gunpowder": &"ITEM_GUNPOWDER",
	&"incendiary": &"ITEM_INCENDIARY",
	&"money": &"ITEM_MONEY",
	&"energy": &"ITEM_ENERGY",
	&"tech": &"ITEM_TECH",

	# ---- what a night is held off with
	&"gun_tower": &"DEF_GUN_TOWER",
	&"flame_tower": &"DEF_FLAME_TOWER",
	&"mortar": &"DEF_MORTAR",
	&"auto_crossbow": &"DEF_AUTO_CROSSBOW",
	&"mine": &"DEF_MINE",
	&"fence": &"DEF_FENCE",
	&"wall": &"DEF_WALL",
	&"barricade": &"DEF_BARRICADE",

	# ---- what a day builds
	&"workshop": &"BLD_WORKSHOP",
	&"press": &"BLD_PRESS",
	&"kitchen": &"BLD_KITCHEN",
	&"generator": &"BLD_GENERATOR",
	&"copper_sprinkler": &"BLD_COPPER_SPRINKLER",
	&"iron_sprinkler": &"BLD_IRON_SPRINKLER",
	&"gold_sprinkler": &"BLD_GOLD_SPRINKLER",
	&"coop": &"BLD_COOP",
	&"barn": &"BLD_BARN",
	&"keg": &"BLD_KEG",
	&"preserves_jar": &"BLD_PRESERVES_JAR",
	&"dairy": &"BLD_DAIRY",
	&"loom": &"BLD_LOOM",
	&"mill": &"BLD_MILL",

	# ---- what those make
	&"barricade_kit": &"REC_BARRICADE_KIT",
	&"fence_kit": &"REC_FENCE_KIT",
	&"mine_kit": &"REC_MINE_KIT",
	&"wall_kit": &"REC_WALL_KIT",
	&"press_oil": &"REC_PRESS_OIL",
	&"press_fish_oil": &"REC_PRESS_FISH_OIL",
	&"make_incendiary": &"REC_MAKE_INCENDIARY",
	&"make_gunpowder": &"REC_MAKE_GUNPOWDER",
	&"cook_meal": &"REC_COOK_MEAL",
	&"cook_fish": &"REC_COOK_FISH",
	&"cook_roast": &"REC_COOK_ROAST",
	&"make_bait": &"REC_MAKE_BAIT",
	&"make_hay": &"REC_MAKE_HAY",
	&"make_wine": &"REC_MAKE_WINE",
	&"make_juice": &"REC_MAKE_JUICE",
	&"make_jelly": &"REC_MAKE_JELLY",
	&"make_pickles": &"REC_MAKE_PICKLES",
	&"make_butter": &"REC_MAKE_BUTTER",
	&"make_cheese": &"REC_MAKE_CHEESE",
	&"make_cloth": &"REC_MAKE_CLOTH",
	&"make_sandbag": &"REC_MAKE_SANDBAG",
	&"make_flour": &"REC_MAKE_FLOUR",
	&"make_sugar": &"REC_MAKE_SUGAR",

	# ---- what comes out of the dark. **Plural pairs**, so `I18n.plural`
	# takes these keys and adds `.one` or `.other` itself.
	&"walker": &"ENEMY_WALKER",
	&"runner": &"ENEMY_RUNNER",
	&"tank": &"ENEMY_TANK",
	&"breaker": &"ENEMY_BREAKER",
	&"giant": &"ENEMY_GIANT",

	# ---- what the tech tree buys
	&"sharp tools": &"TECH_SHARP_TOOLS",
	&"full cans": &"TECH_FULL_CANS",
	&"steady hands": &"TECH_STEADY_HANDS",
	&"a name at market": &"TECH_A_NAME_AT_MARKET",
	&"true sights": &"TECH_TRUE_SIGHTS",
	&"long barrels": &"TECH_LONG_BARRELS",
	&"oiled works": &"TECH_OILED_WORKS",
	&"a standing order": &"TECH_A_STANDING_ORDER",
	&"stout timbers": &"TECH_STOUT_TIMBERS",
	&"a full larder": &"TECH_A_FULL_LARDER",
	&"spare stakes": &"TECH_SPARE_STAKES",
	&"a second flare": &"TECH_A_SECOND_FLARE",

	# ---- the branches of it
	&"production": &"TECH_BRANCH_PRODUCTION",
	&"defence": &"TECH_BRANCH_DEFENCE",
	&"survival": &"TECH_BRANCH_SURVIVAL",

	# ---- what a hit is made of
	&"impact": &"DMG_IMPACT",
	&"fire": &"DMG_FIRE",
	&"explosive": &"DMG_EXPLOSIVE",

	# ---- where a recipe is made
	&"workbench": &"STATION_WORKBENCH",

	# ---- the seasons of the calendar (task 0149)
	&"spring": &"SEASON_SPRING",
	&"summer": &"SEASON_SUMMER",
	&"autumn": &"SEASON_AUTUMN",
	&"winter": &"SEASON_WINTER",

	# ---- the sides the horde comes from (task 0157's `SPAWN_SIDES`), for the
	# forecast (task 0158)
	&"east": &"SIDE_EAST",
	&"south_east": &"SIDE_SOUTH_EAST",
	&"north": &"SIDE_NORTH",
	&"west": &"SIDE_WEST",
	&"south": &"SIDE_SOUTH",
}

## Literal category keys: the translation checker can see every tab.
const GROUP_KEYS: Dictionary = {
	&"tools": &"INV_GROUP_TOOLS",
	&"fish_book": &"INV_GROUP_FISH_BOOK",
	&"materials": &"INV_GROUP_MATERIALS",
	&"crops": &"INV_GROUP_CROPS",
	&"seeds": &"INV_GROUP_SEEDS",
	&"fish": &"INV_GROUP_FISH",
	&"bait": &"INV_GROUP_BAIT",
	&"animal_goods": &"INV_GROUP_ANIMAL_GOODS",
	&"artisan_goods": &"INV_GROUP_ARTISAN_GOODS",
	&"ammunition": &"INV_GROUP_AMMUNITION",
	&"night_leftovers": &"INV_GROUP_NIGHT_LEFTOVERS",
	&"farm": &"INV_GROUP_FARM",
	&"other": &"INV_GROUP_OTHER",
}


## What an inventory category is called.
static func group_of(id: StringName) -> String:
	return I18n.t(GROUP_KEYS[id]) if GROUP_KEYS.has(id) else of(id)


## And what each tech node promises, which is a sentence rather than a name.
const NOTES: Dictionary = {
	&"sharp tools": &"TECHNOTE_SHARP_TOOLS",
	&"full cans": &"TECHNOTE_FULL_CANS",
	&"steady hands": &"TECHNOTE_STEADY_HANDS",
	&"a name at market": &"TECHNOTE_A_NAME_AT_MARKET",
	&"true sights": &"TECHNOTE_TRUE_SIGHTS",
	&"long barrels": &"TECHNOTE_LONG_BARRELS",
	&"oiled works": &"TECHNOTE_OILED_WORKS",
	&"a standing order": &"TECHNOTE_A_STANDING_ORDER",
	&"stout timbers": &"TECHNOTE_STOUT_TIMBERS",
	&"a full larder": &"TECHNOTE_A_FULL_LARDER",
	&"spare stakes": &"TECHNOTE_SPARE_STAKES",
	&"a second flare": &"TECHNOTE_A_SECOND_FLARE",
}


## What this thing is called.
##
## **An id with no name reads as itself**, spaced out rather than
## underscored, which is what every screen used to do for everything - so a
## thing added to a table and not named here still appears, and still looks
## like something somebody forgot.
static func of(id: StringName) -> String:
	if KEYS.has(id):
		return I18n.t(KEYS[id])
	return String(id).replace("_", " ")


## A refusal from the rules, as a sentence.
##
## Task 0110: `Building.why_not()`, `Farm.why_not_buildable()`,
## `Tech.why_not_buy()` and `Sim.why_not_skip()` all hand back
## `[key, argument, ...]` rather than English, and this is the one place that
## turns one into words. An empty Array is not a refusal and comes back as
## "".
##
## **Three rules for the arguments, and no fourth.** A `StringName` is an id
## and goes through `of()`, so a player is told "gun tower" and never
## `gun_tower`. A `Dictionary` is a pile of resources - `{wood: 3}` - and
## comes out as "3 wood, 2 stone", sorted so two runs read the same. Anything
## else is a number and is printed.
static func refusal(reason: Array) -> String:
	if reason.is_empty():
		return ""
	var key := StringName(reason[0])
	var args: Array = []
	for i in range(1, reason.size()):
		args.append(_said(reason[i]))
	return I18n.f(key, args) if args.size() > 0 else I18n.t(key)


## One argument of a refusal, in words.
static func _said(arg: Variant) -> Variant:
	if arg is StringName:
		return of(arg as StringName)
	if arg is Dictionary:
		var parts := PackedStringArray()
		for id in GameData.sorted_names((arg as Dictionary).keys()):
			parts.append("%d %s" % [int((arg as Dictionary)[id]),
				of(StringName(id))])
		return ", ".join(parts)
	return arg


## The key rather than the words, for a plural or a count.
static func key_of(id: StringName) -> StringName:
	return KEYS.get(id, StringName(String(id).to_upper()))


## What a tech node promises.
static func note_of(id: StringName) -> String:
	return I18n.t(NOTES[id]) if NOTES.has(id) else ""


## Every id this knows a name for, sorted. For the checks.
static func known() -> Array:
	var out: Array = KEYS.keys()
	out.sort()
	return out
