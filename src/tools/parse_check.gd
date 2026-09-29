extends SceneTree

## Every script in the project, compiled, in one process.
##
##     godot --headless --script res://src/tools/parse_check.gd
##
## Prints one line per script that will not compile, then
##
##     PARSED <n> scripts, <m> failed
##
## ## Why this exists rather than a loop in `verify.py`
##
## It was a loop in `verify.py`: `--check-only --script` once per file, which
## is a whole Godot process per script. Ninety-eight of them took
## **ninety-five seconds**, almost none of it compiling anything - it is
## process startup, ninety-eight times. The same work in one process is a
## couple of seconds, and the suite was over its own time budget by twenty.
##
## ## `load()` really does compile, and that was measured rather than assumed
##
## `--import` does not: it imports resources and exits 0 with a script full of
## parse errors sitting next to it, which is the trap `verify.py`'s old
## comment warns about and the reason the per-file loop existed. `load()` on a
## `.gd` is a different thing - it runs the parser and returns `null` when the
## parse fails. Task 0106 planted a syntax error in a script and checked that
## this catches it before the loop was taken out.
##
## ## The cache is why this is one shot
##
## A script already loaded comes back from the cache without being parsed
## again, so this is worth exactly one run per process. That is fine: it is
## run as its own process, once, by `verify.py`.

var _checked := 0
var _bad: Array = []

## Directories that are not the game and not checked. `.godot` holds the
## import cache, which has no scripts in it worth compiling.
const SKIP: Array = [".godot", "build", "__pycache__"]


func _initialize() -> void:
	_walk("res://")
	_bad.sort()
	if _bad.size() > 1:
		print("  (a script that will not compile fails everything that")
		print("   depends on it, so the list is longer than the mistake)")
	for line in _bad:
		print("  ", line)
	print("PARSED %d scripts, %d failed" % [_checked, _bad.size()])
	quit(1 if _bad.size() > 0 else 0)


func _walk(where: String) -> void:
	var at := DirAccess.open(where)
	if at == null:
		return
	for name in at.get_files():
		if String(name).ends_with(".gd"):
			_compile(where.path_join(String(name)))
	for name in at.get_directories():
		if SKIP.has(String(name)):
			continue
		_walk(where.path_join(String(name)))


func _compile(path: String) -> void:
	# Not itself: it is already running, and loading it again is a second
	# copy of the thing doing the loading.
	if path == "res://src/tools/parse_check.gd":
		return
	_checked += 1
	# **The cache is left alone.** `CACHE_MODE_IGNORE` re-runs a script's
	# static initialisers on every load, and doing that to every script in
	# the project inside one process took the engine down with an internal
	# error - measured, not guessed. The default is right anyway: a fresh
	# process has an empty cache, so each script is parsed exactly once here,
	# either on its own or as somebody else's dependency. A dependency that
	# will not parse fails the script that needed it, so nothing hides.
	var loaded: Resource = ResourceLoader.load(path, "GDScript")
	if loaded == null:
		_bad.append("%s will not compile" % path)
		return
	var script := loaded as GDScript
	if script == null:
		_bad.append("%s is not a GDScript" % path)
		return

	# **A failed parse comes back as a `GDScript` with nothing in it**, not
	# as `null` - which is the one thing about this that had to be found out
	# by trying it. A script that compiled knows what it extends; one that
	# did not knows nothing and cannot be instantiated. Checked against all
	# hundred scripts in this project before it was trusted: every real one
	# passes, including the `class_name`-and-static-functions files that
	# never get instantiated by anybody.
	if not script.can_instantiate() and script.get_instance_base_type() == "":
		_bad.append("%s will not compile" % path)
