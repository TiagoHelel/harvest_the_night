extends "res://src/tools/tree_wind_showcase.gd"

## Binding probe: the unchanged tree_wind_showcase plus a once-a-frame look at
## which inventory textures are alive. See probe_common.gd.

const PROBE := preload("res://implementation/fhd-assets/pilots/2026-10-06/32px-integration/probe/probe_common.gd")


func _process(_delta: float) -> bool:
	PROBE.poll("tree_wind")
	return false
