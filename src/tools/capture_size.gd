class_name CaptureSize
extends RefCounted

## Explicit review targets: legacy pixel fixtures or actual FHD production output.
## Only test scripts call this; the game always uses its project/video settings.
static func configure(window: Window, fhd := false) -> void:
	window.content_scale_size = Vector2i(480, 270)
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS if fhd \
		else Window.CONTENT_SCALE_MODE_VIEWPORT
	if fhd:
		window.size = Vector2i(1920, 1080)
