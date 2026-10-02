class_name I18n
extends Node

## Every word the player reads, in one table per language.
##
## **Static, with a small autoload behind it.** `verify.py` parses every
## script on its own with no autoloads registered, so `Audio` and the rest
## have to be reached by path - and a path lookup at every label would be
## absurd. A `class_name` with static functions is nameable at parse time, so
## a screen writes `I18n.t(&"HUD_DAY")` and nothing has to be found first.
## The node this script is also attached to - the `Locale` autoload - exists
## to hear `Settings.changed` and to relabel the screens.
##
## ## The keys are symbols, not English
##
## `MENU_ABANDON`, not `"ABANDON RUN"`. English-as-key is how gettext works
## and it is tempting, but two English strings that happen to match collapse
## into one - and "BUILD" the verb and "BUILD" the noun are not the same word
## in Portuguese. It also makes every English edit a broken translation.
##
## ## Nothing is concatenated
##
## A sentence assembled from pieces is a sentence that can only be word
## ordered one way, and Portuguese does not order words the way English does.
## So every line is one key with `%s` in it, and `f()` fills them in.
## Plurals are two keys - `KEY.one` and `KEY.other` - rather than an `s`
## stuck on the end, because Portuguese plurals are not an `s` stuck on the
## end either.
##
## ## The file
##
##     key,width,en,pt_BR
##
## `width` is how many **pixels** the control that draws this key gives it,
## or 0 for something that wraps or has no fixed size. `tools/i18n_check.py`
## measures both languages in the game's own font and fails on one that does
## not fit - which is the only way to know that a translation fits before a
## player finds out that it does not.

const DIR := "res://assets/locale/"

## The one every other language falls back to, key by key.
const FALLBACK := "en"

## What there is, in the order the options screen offers them.
const LOCALES: Array = ["en", "pt_BR"]

## What each is called **in its own language**, which is the only name a
## player looking for it would recognise.
const NAMES: Dictionary = {
	"en": "ENGLISH",
	"pt_BR": "PORTUGUÊS",
}

## How a number's thousands are grouped, per language.
const GROUPING: Dictionary = {
	"en": ",",
	"pt_BR": ".",
}

## locale -> {key: text}
static var _table: Dictionary = {}

## key -> the pixel width its control gives it, or 0.
static var _widths: Dictionary = {}

static var _locale := FALLBACK

## Bumped every time the language changes, for a screen that would rather
## compare a number than connect a signal.
static var _revision := 0

## Every key something asked for and no language had. Read by the checks.
static var _missing: Dictionary = {}


func _ready() -> void:
	var settings := _settings()
	if settings != null:
		if not settings.changed.is_connected(_on_changed):
			settings.changed.connect(_on_changed)
		if not settings.reloaded.is_connected(_take_setting):
			settings.reloaded.connect(_take_setting)
	# **Set the language, and relabel nothing.** Every screen is built after
	# this and reads the table as it builds, so there is nothing on screen
	# yet to put back into another language - and walking a tree that is
	# still being built reaches a screen whose `_ready` has not run.
	var settings_now := _settings()
	use(String(settings_now.get_string(&"gameplay/language"))
		if settings_now != null else FALLBACK)


# ------------------------------------------------------------------ the words

## The table for a language, loaded once.
static func load_all() -> int:
	if not _table.is_empty():
		return _table.size()
	var file := FileAccess.open(DIR + "strings.csv", FileAccess.READ)
	if file == null:
		push_error("I18n: no %sstrings.csv" % DIR)
		return 0
	var columns: Array = []
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() < 2 or String(row[0]).strip_edges() == "":
			continue
		if columns.is_empty():
			for cell in row:
				columns.append(String(cell).strip_edges())
			for i in range(2, columns.size()):
				_table[columns[i]] = {}
			continue
		var key := String(row[0]).strip_edges()
		_widths[key] = int(String(row[1])) if String(row[1]).is_valid_int() \
			else 0
		for i in range(2, columns.size()):
			if i < row.size():
				(_table[columns[i]] as Dictionary)[key] = String(row[i])
	return _table.size()


## Change language. Safe to call with one that does not exist - the fallback
## is a game somebody can still read.
static func use(locale: String) -> void:
	load_all()
	var wanted := locale if _table.has(locale) else FALLBACK
	if wanted == _locale:
		return
	_locale = wanted
	_revision += 1


static func locale() -> String:
	return _locale


static func revision() -> int:
	return _revision


## One line, in the language that is up.
##
## **A missing key reads as itself** rather than as an empty label: a screen
## with a gap on it says nothing, and a screen saying `HUD_DAY` says exactly
## which row of the table is missing.
static func t(key: StringName) -> String:
	load_all()
	var named := String(key)
	var here: Dictionary = _table.get(_locale, {})
	var found := String(here.get(named, ""))
	if found != "":
		return found
	var back: Dictionary = _table.get(FALLBACK, {})
	found = String(back.get(named, ""))
	if found != "":
		return found
	_missing[named] = true
	return named


## One line with things filled into it.
static func f(key: StringName, args: Array) -> String:
	return t(key) % args


## One of two keys, by how many there are.
##
## `KEY.one` and `KEY.other`, and the count is **not** put in by this: the
## line itself says where the number goes, because "1 slot free" and "um
## lugar livre" do not put it in the same place.
static func plural(key: StringName, count: int, args: Array = []) -> String:
	load_all()
	var here: Dictionary = _table.get(_locale, {})
	var back: Dictionary = _table.get(FALLBACK, {})
	# **The bare key is the singular.** A `.one` row exists only where the
	# singular differs from the name of the thing, which in these two
	# languages is almost never - and a table with "walker" written twice
	# is a table with two places to get it wrong.
	var one := StringName("%s.one" % key)
	var which := key
	if absi(count) == 1:
		if here.has(String(one)) or back.has(String(one)):
			which = one
	else:
		which = StringName("%s.other" % key)
	return t(which) if args.is_empty() else f(which, args)


## A number with its thousands grouped the way this language groups them.
static func number(value: int) -> String:
	load_all()
	var mark := String(GROUPING.get(_locale, ","))
	var digits := str(absi(value))
	var out := ""
	var taken := 0
	for i in range(digits.length() - 1, -1, -1):
		out = digits[i] + out
		taken += 1
		if taken % 3 == 0 and i > 0:
			out = mark + out
	return ("-" + out) if value < 0 else out


## What the table says this key's control is, in pixels. Zero for something
## that wraps or grows.
static func width_of(key: StringName) -> int:
	load_all()
	return int(_widths.get(String(key), 0))


static func keys() -> Array:
	load_all()
	var out: Array = (_table.get(FALLBACK, {}) as Dictionary).keys()
	out.sort()
	return out


static func missing() -> Array:
	var out: Array = _missing.keys()
	out.sort()
	return out


static func forget_missing() -> void:
	_missing.clear()


# ------------------------------------------------------------- the screens

## Tell every screen under `from` to write its words again.
##
## **A convention rather than a signal**: a screen with a fixed label builds
## it once and would otherwise keep whatever language it was born in, and
## having it implement `relabel()` puts the list of what needs redoing next
## to the code that does it. Returns how many answered, so a check can say
## that a screen was reached rather than hoping.
static func relabel(from: Node) -> int:
	var done := 0
	if not from is I18n and from.has_method(&"relabel"):
		from.call(&"relabel")
		done += 1
	for child in from.get_children():
		done += relabel(child)
	return done


# ------------------------------------------------------------------ the node

func _on_changed(key: StringName) -> void:
	if key == &"gameplay/language":
		_take_setting()


func _take_setting() -> void:
	var settings := _settings()
	var wanted := String(settings.get_string(&"gameplay/language")) \
		if settings != null else FALLBACK
	var was := _locale
	use(wanted)
	if _locale == was:
		return
	var loop := Engine.get_main_loop() as SceneTree
	if loop != null and loop.root != null:
		relabel(loop.root)


func _settings() -> Node:
	var loop := Engine.get_main_loop() as SceneTree
	if loop == null or loop.root == null:
		return null
	return loop.root.get_node_or_null(^"Settings")
