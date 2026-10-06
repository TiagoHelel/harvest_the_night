extends RefCounted

## Which of the 320 inventory PNGs a running view actually holds.
##
## Polled once a frame from a probe that extends an existing showcase or the
## shot scenarios: a texture alive in Godot's resource cache was loaded by a
## view and is still held by something drawing or caching it. Each new path
## is appended to `seen/<label>.txt` as it is first noticed, so a run that
## ends in `quit()` has already written everything it saw. Read-only: it
## loads nothing and changes nothing.

const HERE := "res://implementation/fhd-assets/pilots/2026-10-06/32px-integration/probe/"

static var _paths := PackedStringArray()
static var _seen := {}
static var _out := ""


static func poll(name: String) -> void:
	if _out == "":
		_start(name)
	for path in _paths:
		if not _seen.has(path) and ResourceLoader.has_cached(path):
			_seen[path] = true
			var file := FileAccess.open(_out, FileAccess.READ_WRITE)
			file.seek_end()
			file.store_line(path)
			file.close()


static func _start(name: String) -> void:
	_paths = FileAccess.get_file_as_string(HERE + "inventory.txt").split("\n", false)
	var flags: Array = []
	for arg in OS.get_cmdline_user_args():
		if arg != "--check" and not arg.begins_with("--out="):
			flags.append(arg.trim_prefix("--"))
	var label := name if flags.is_empty() else name + "-" + "-".join(flags)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(HERE + "seen"))
	_out = ProjectSettings.globalize_path(HERE + "seen/" + label + ".txt")
	FileAccess.open(_out, FileAccess.WRITE).close()
