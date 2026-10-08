class_name StudioIntro
extends Control

## DEF4ULT STUDIO ident - the first screen of the game, ahead of the title.
##
## **Ported from WELCOME BACK, HERO** (`one_room_dg`, its task 0221, itself a
## port of Overstack's), because the owner asked for this game to open the way
## that one does - the same ident, not one like it. A studio ident belongs to
## the studio rather than to the game, so the cue table, the easings, the
## composition, the cyan, the crest, the two sounds and the face of the plate
## all come across unchanged; if a number here disagrees with that file's, that
## is a bug in one of them. What this port changed is listed at the bottom of
## this header, and nowhere else.
##
## WHY THIS IS DRAWN AND NOT ANIMATED IN THE SCENE. Everything visible here is
## one _draw() reading one clock (`_t`). A studio ident is a piece of timing,
## and timing spread across eight AnimationPlayer tracks cannot be read or
## retuned in one place; the cue table below is the whole animation, in order,
## in seconds.
##
## THE CREST IS A SPRITE, THE LIGHT IS NOT. assets/studio/def4ult_studio.png is
## the studio mark; see _resolve_crest_size() for how a pixel art source and a
## high-resolution export are each drawn correctly. The bloom, the sweeping
## lock-on arc and the ignition flash are drawn in screen space instead of being
## baked into it, so the light stays smooth however coarse the artwork is.
##
## SKIPPING IS NOT OPTIONAL. Any key, click or pad button cuts to the collapse;
## a second press drops straight into the game. `--skip-intro` bypasses the
## whole thing, for a developer who has seen it enough times today.
##
## --- what this port changed, and why ------------------------------------------
##
##  * **It is laid out on that game's frame, 1280x720.** This game designs at
##    480x270 and draws it at whole multiples; the ident was composed for a
##    1280x720 canvas stretched to the window, and a 300 pixel crest does not
##    fit in a 270 pixel screen at all. So while it runs the window shows a
##    1280x720 canvas stretched smoothly - exactly what that game does - and
##    the moment it hands over, this game's own frame is put back. See `FRAME`.
##  * **The router hands over, not a scene path.** `App.goto(TITLE)` loads the
##    title the way every other scene change in this game is made, and the
##    title opens on its PRESS ANY KEY exactly as it did before.
##  * **Its own two voices.** This game's `Audio` plays generated effects by
##    name; the studio's two sounds are not generated and do not belong in that
##    table, so the ident owns two players on the SFX bus and the volumes the
##    player chose still apply. Their levels are that game's, in decibels.
##  * **The face came too.** That game set the plate in its own font; so does
##    this one, and it is that game's font, from assets/studio/ - this game's
##    is wider and squarer and the plate would not be the same plate.
##  * **`rise_from_black` lives on the `App` autoload**, runtime only, where
##    "which screen comes next" already lives.

const ActionsScript := preload("res://src/app/input_actions.gd")

## Where the ident hands over to. Read by the checks; the router is what loads
## it (`App.SCENES[TITLE]`).
const NEXT_SCENE := "res://scenes/Title.tscn"

## The canvas the ident is composed on, in that game's pixels. See the header.
const FRAME := Vector2i(1280, 720)

const CREST := preload("res://assets/studio/def4ult_studio.png")
const PLATE_FONT := preload("res://assets/studio/one_room_pixel.fnt")
const POWER_SOUND := preload("res://assets/studio/ident_power.wav")
const STING_SOUND := preload("res://assets/studio/ident_sting.wav")

const STUDIO_NAME := "DEF4ULT STUDIO"

## **English in every language, like the name above it.** The studio name and
## the word under it are one plate, and the plate is one language on purpose;
## `headless_check` asserts it, so it cannot quietly pick up a translation.
const TAGLINE := "PRESENTS"

# --- cue table (absolute seconds on one clock) -----------------------------
# Read top to bottom: each constant is the moment that beat FINISHES. Durations
# are the gaps between them, which is the thing that actually needs tuning.
# The clock starts NEGATIVE, at -T_LEAD, and the tube strikes when it reaches
# zero. Doing it that way instead of adding 2.0 to all seven numbers below is
# what keeps this table readable: every constant still says how far into the
# IDENT its beat lands, and the lead is one independent number that can be
# taken to zero without touching the rhythm. Everything downstream compares
# against `_t` and is already correct for negative values -- the shutter clamps
# to fully shut, and every beat's own `_t < T_x` guard keeps it off screen.
const T_LEAD := 2.00     # pure black before anything happens at all

const T_POWER := 0.70    # CRT strikes: black -> hairline -> full frame
const T_CREST := 2.20    # crest fades up, lock-on arc sweeps a full turn
const T_IGNITE := 2.40   # core flares white, sting fires
const T_NAME := 3.60     # DEF4ULT STUDIO settles in, letter by letter
const T_TAG := 4.35      # PRESENTS fades in under it
const T_HOLD := 5.45     # the frame just sits there
const T_OUT := 6.05      # collapses back to a scanline
const T_BLACK := 6.45    # ... and then holds pure black before handing over

# The table is stretched by a single factor when it needs to be slower, never
# by nudging the beat that feels worst: the RATIOS are the ident, and pulling
# one gap without the others turns a rhythm into a list of events. The
# exponents in the drawing code are what reads as calm; the length alone did
# not (that game measured it).

# --- how the crest is sized ------------------------------------------------
# PIXEL ART needs NEAREST filtering and a WHOLE-NUMBER scale; a HIGH-RESOLUTION
# EXPORT needs LINEAR and is simply fitted to the box. _ready() picks between
# them from the texture's own height, so swapping the asset needs no code
# change. The shipped mark is the studio's own render, 300 pixels square.
const PIXEL_ART_MAX := 128  # source no taller than this is treated as pixel art
const CREST_BOX := 300.0    # target height for the crest on the 720px frame

const NAME_SIZE := 34
const NAME_GAP := 7.0
const TAG_SIZE := 16
const TAG_GAP := 9.0
const NAME_MARGIN := 30.0  # crest bottom -> name top
const TAG_MARGIN := 26.0   # name bottom -> tagline top

# The studio's palette, not the game's. An ident whose colour changes from one
# of the studio's games to the next is not an ident.
const C_NAME := Color(0.88, 0.92, 1.0)
const C_NAME_HOT := Color(1.0, 1.0, 1.0)
const C_SHADOW := Color(0.01, 0.012, 0.02, 0.85)
const C_TAG := Color(0.52, 0.63, 0.80)
const C_ACCENT := Color(0.42, 0.82, 0.88)
## **This one number is shared with `project.godot`.** The ident opens on two
## seconds of nothing, so any difference between the engine's boot splash
## colour and this field shows up as a colour click on the very first frame.
## The `boot_splash/bg_color` there is this value; `headless_check` holds them
## equal, so changing one means changing both.
const C_BLACK := Color(0.016, 0.020, 0.033)

# Where the crest's glowing core and its reticle ring sit inside the art, as
# FRACTIONS of the drawn size - measured off the shipped asset, not guessed.
const CORE_UV := Vector2(0.500, 0.455)
const RING_UV := 0.410

## The sounds' levels, in decibels: that game's own, which were Overstack's
## linear 0.35 and 1.0 converted (20*log10(0.35) is -9.1).
const POWER_DB := -9.1
const POWER_PITCH := 0.55
const STING_DB := 0.0
const STING_PITCH := 0.78

var _t := -T_LEAD
var _leaving := false
var _sting_played := false
var _power_played := false
var _rng := RandomNumberGenerator.new()
var _crest := Vector2.ZERO  # drawn size of the crest, resolved in _ready()
var _font: Font = null
var _name_font: Font = null
var _power: AudioStreamPlayer
var _sting: AudioStreamPlayer

## The window as this game had it before the ident put its own frame on it,
## put back the moment it hands over. Empty until `_ready`.
var _kept: Dictionary = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_wear_frame()
	_power = _voice(POWER_SOUND, POWER_DB, POWER_PITCH)
	_sting = _voice(STING_SOUND, STING_DB, STING_PITCH)
	_font = PLATE_FONT
	if _font == null:
		_font = ThemeDB.fallback_font
	_name_font = _font
	_resolve_crest_size()
	# Deterministic noise: the static bars are the same on every launch, so the
	# ident is a fixed piece of film rather than something that flickers
	# differently each time the player sees it.
	_rng.seed = 0x4EFA17
	if "--skip-intro" in OS.get_cmdline_user_args() \
			or "--skip-intro" in OS.get_cmdline_args():
		_hand_over()
		return
	set_process(true)


## The window goes back to this game's frame however the ident leaves - the
## timeline, a skip, or a check freeing it halfway.
func _exit_tree() -> void:
	_give_frame_back()


# --- the frame -------------------------------------------------------------

## Lay the window out as that game's 1280x720 canvas, stretched smoothly, with
## the bars round it (on a window that is not 16:9) in the ident's own black.
func _wear_frame() -> void:
	var win := get_window()
	if win == null or not _kept.is_empty():
		return
	_kept = {
		"size": win.content_scale_size,
		"stretch": win.content_scale_stretch,
		"factor": win.content_scale_factor,
		"aspect": win.content_scale_aspect,
		"clear": RenderingServer.get_default_clear_color(),
	}
	win.content_scale_size = FRAME
	win.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_FRACTIONAL
	win.content_scale_factor = 1.0
	win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	RenderingServer.set_default_clear_color(C_BLACK)


func _give_frame_back() -> void:
	if _kept.is_empty():
		return
	var win := get_window()
	if win != null:
		win.content_scale_size = _kept["size"]
		win.content_scale_stretch = _kept["stretch"]
		win.content_scale_factor = _kept["factor"]
		win.content_scale_aspect = _kept["aspect"]
	RenderingServer.set_default_clear_color(_kept["clear"])
	_kept = {}


func _voice(stream: AudioStream, db: float, pitch: float) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = &"SFX"
	player.volume_db = db
	player.pitch_scale = pitch
	add_child(player)
	return player


# Picks the drawn size and the filter from the texture itself. Aspect is
# preserved either way, so a non-square export is letterboxed rather than
# stretched.
#
# **The filter follows the scale and the node draws the text too.** The plate
# is a bitmap font, and a LINEAR node blurs every letter of it - which is what
# that game's first port did. A crest drawn at a whole-number scale is not
# being resampled at all, so NEAREST costs it nothing and buys the text back.
# The shipped mark is sized to `CREST_BOX` exactly, which makes that scale 1.0.
func _resolve_crest_size() -> void:
	var tex := Vector2(CREST.get_width(), CREST.get_height())
	var scale := CREST_BOX / tex.y
	if tex.y <= float(PIXEL_ART_MAX):
		# floor, never round: 2.9x rounded to 3x would overflow the box, and a
		# fractional scale is the one thing pixel art cannot survive.
		scale = maxf(1.0, floorf(scale))
	_crest = tex * scale
	var whole: bool = is_equal_approx(scale, roundf(scale))
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if whole \
		else CanvasItem.TEXTURE_FILTER_LINEAR


func _process(delta: float) -> void:
	if _leaving:
		return
	_t += delta
	if not _power_played and _t >= T_POWER * 0.5:
		_power_played = true
		# The CRT striking. Deep and quiet: it sets the room, it is not an event.
		_power.play()
	if not _sting_played and _t >= T_IGNITE - 0.06:
		_sting_played = true
		# The studio's "something is being made" sound, pitched down so it
		# reads as a core coming up.
		_sting.play()
	if _t >= T_BLACK:
		_hand_over(true)
		return
	queue_redraw()


# First press skips to the collapse, second press leaves now. Cutting straight
# to the title on the first press is jarring on the launch where the player did
# want to see it and pressed something by reflex; the collapse still reads as
# "yes, skipped" without slamming the door. Neither press asks the game to rise
# out of black: somebody who pressed skip wants the game, not another second
# of atmosphere on the way to it.
func _unhandled_input(event: InputEvent) -> void:
	if _leaving:
		return
	if not ActionsScript.is_any_press(event):
		return
	get_viewport().set_input_as_handled()
	if _t < 0.0:
		# Still inside the black lead. Nothing has been shown, so there is
		# nothing to collapse: running the outro here would be a second of black
		# after two seconds of black. Leave now.
		_hand_over(false)
	elif _t < T_HOLD:
		_t = T_HOLD
	else:
		_hand_over(false)


# `rise` asks the title to come up out of black instead of appearing at full
# strength. Only the timeline sets it: the ident earns that second because it
# just spent one going dark, whereas both skip paths were asked for speed.
func _hand_over(rise: bool = false) -> void:
	if _leaving:
		return
	_leaving = true
	set_process(false)
	queue_redraw()
	_give_frame_back()
	var app := get_node_or_null(^"/root/App")
	if app == null:
		# DEFERRED, always: from `_ready` (the --skip-intro path) the tree is
		# still adding this node, and changing scene then leaves the ident on
		# screen for ever.
		get_tree().change_scene_to_file.call_deferred(NEXT_SCENE)
		return
	app.set(&"rise_from_black", rise)
	app.goto(app.TITLE)


# --- for the checks and the capture tool ---------------------------------------

## Where the ident's clock is, in seconds from the strike (negative in the lead).
func clock() -> float:
	return _t


## Put the clock somewhere, for a picture of one beat or a check of one path.
func set_clock(seconds: float) -> void:
	_t = seconds
	queue_redraw()


## Whether it has handed over (or is handing over) to the title.
func leaving() -> bool:
	return _leaving


## Whether its sounds have been fired, in order: the strike, the sting.
func sounds_fired() -> Array:
	return [_power_played, _sting_played]


# --- drawing ---------------------------------------------------------------

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), C_BLACK)
	# **Black and nothing else once it is leaving.** The frame has already gone
	# back to this game's 480x270 by then, and one more frame of the plate laid
	# out for 1280x720 would be the plate drawn at three times its size.
	if _leaving:
		return

	# The whole block (crest + name + tagline) is centred as one unit, so the
	# composition stays balanced if any of the sizes above change.
	var name_h := float(_name_font.get_ascent(NAME_SIZE) + _name_font.get_descent(NAME_SIZE))
	var tag_h := float(_font.get_ascent(TAG_SIZE) + _font.get_descent(TAG_SIZE))
	var block_h := _crest.y + NAME_MARGIN + name_h + TAG_MARGIN + tag_h
	var top := roundf((size.y - block_h) * 0.5)
	var center_x := roundf(size.x * 0.5)
	var crest_pos := Vector2(roundf(center_x - _crest.x * 0.5), top)
	var core := crest_pos + CORE_UV * _crest

	_draw_crest(crest_pos, core)
	_draw_name(center_x, top + _crest.y + NAME_MARGIN)
	_draw_tagline(center_x, top + _crest.y + NAME_MARGIN + name_h + TAG_MARGIN)
	_draw_ignition(core)
	_draw_shutter()


func _draw_crest(pos: Vector2, core: Vector2) -> void:
	if _t < T_POWER:
		return
	var reveal: float = clampf((_t - T_POWER) / (T_CREST - T_POWER), 0.0, 1.0)
	var eased: float = 1.0 - pow(1.0 - reveal, 2.0)

	# Bloom first, so the sprite sits on top of its own light.
	var bloom: float = eased * (1.0 + 2.2 * _flash())
	_draw_glow(core, _crest.y * 0.80, C_ACCENT, 0.16 * bloom)

	# The crest rises as it fades up. Rounded to whole pixels so a pixel art
	# source never lands on a half-pixel and shimmers on the way in.
	var rise: float = roundf((1.0 - eased) * 12.0)
	draw_texture_rect(CREST, Rect2(pos + Vector2(0.0, rise), _crest),
		false, Color(1.0, 1.0, 1.0, eased))

	# A bright band sweeping down the crest while it resolves: the signal
	# painting the image in, rather than a plain dissolve.
	if reveal < 1.0:
		var band_y: float = pos.y + rise + reveal * _crest.y
		draw_rect(Rect2(pos.x - 8.0, band_y - 1.0, _crest.x + 16.0, 2.0),
			Color(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 0.55 * (1.0 - reveal)))
		draw_rect(Rect2(pos.x - 8.0, band_y - 10.0, _crest.x + 16.0, 20.0),
			Color(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 0.10 * (1.0 - reveal)))

	# Lock-on: one bright arc sweeps a full turn over the reticle baked into the
	# art, then fades, leaving the dim ring behind. The radius matches the
	# baked circle.
	var ring_r: float = RING_UV * _crest.y
	if reveal < 1.0:
		var sweep: float = reveal * TAU
		draw_arc(core, ring_r, -PI * 0.5, -PI * 0.5 + sweep, 96,
			Color(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 0.9), 2.0)
	elif _t < T_CREST + 0.56:
		var fade: float = 1.0 - (_t - T_CREST) / 0.56
		draw_arc(core, ring_r, 0.0, TAU, 96,
			Color(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 0.55 * fade), 2.0)


# The ignition: a white core flash and one ring thrown off it. Short - 0.4s -
# because this is the punctuation the sting lands on.
func _draw_ignition(core: Vector2) -> void:
	var f := _flash()
	if f <= 0.0:
		return
	_draw_glow(core, 150.0, Color(1.0, 1.0, 1.0), 0.85 * f)
	var age: float = _t - T_IGNITE
	if age >= 0.0 and age < 0.64:
		var p: float = age / 0.64
		draw_arc(core, 24.0 + p * 190.0, 0.0, TAU, 72,
			Color(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 0.5 * (1.0 - p)), 2.0)


# A soft radial glow, stacked from concentric filled circles. Rectangles of low
# alpha behind a round crest read as glowing SQUARES with visible corners. The
# radii fall off as sqrt, so the accumulated alpha lands on a quadratic curve
# rather than a linear ramp - a straight ramp reads as a flat disc with a rim.
func _draw_glow(center: Vector2, radius: float, color: Color, strength: float) -> void:
	if strength <= 0.0 or radius <= 0.0:
		return
	const RINGS := 26
	var step := strength / float(RINGS)
	for i in RINGS:
		var f := 1.0 - float(i) / float(RINGS)
		draw_circle(center, radius * sqrt(f), Color(color.r, color.g, color.b, step),
			true, -1.0, true)


# 0 -> 1 -> 0 around T_IGNITE, quick in and slower out.
func _flash() -> float:
	var age := _t - T_IGNITE
	if age < -0.16 or age > 0.55:
		return 0.0
	if age < 0.0:
		return (age + 0.16) / 0.16
	return 1.0 - age / 0.55


func _draw_name(center_x: float, top: float) -> void:
	if _t < T_IGNITE:
		return
	var w := _text_width(_name_font, STUDIO_NAME, NAME_SIZE, NAME_GAP)
	var x := roundf(center_x - w * 0.5)
	var baseline := top + float(_name_font.get_ascent(NAME_SIZE))
	var span := T_NAME - T_IGNITE
	var n := STUDIO_NAME.length()
	var pos := Vector2(x, baseline)
	for i in n:
		var glyph := STUDIO_NAME[i]
		# Each letter has its own window, staggered across the beat. They land
		# hot white and cool to the title colour, so the row reads as switching
		# on rather than sliding in.
		var start: float = T_IGNITE + span * 0.45 * (float(i) / float(n))
		var a: float = clampf((_t - start) / (span * 0.55), 0.0, 1.0)
		var adv := _name_font.get_string_size(glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_SIZE).x
		if a > 0.0 and glyph != " ":
			var col := C_NAME_HOT.lerp(C_NAME, a)
			col.a = a
			var shadow := C_SHADOW
			shadow.a = C_SHADOW.a * a
			draw_string(_name_font, pos + Vector2(2.0, 2.0), glyph,
				HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_SIZE, shadow)
			draw_string(_name_font, pos, glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_SIZE, col)
		pos.x += adv + NAME_GAP


func _draw_tagline(center_x: float, top: float) -> void:
	if _t < T_TAG - 0.75:
		return
	var a: float = clampf((_t - (T_TAG - 0.75)) / 0.75, 0.0, 1.0)
	var text := TAGLINE
	var w := _text_width(_font, text, TAG_SIZE, TAG_GAP)
	var x := roundf(center_x - w * 0.5)
	var baseline := top + float(_font.get_ascent(TAG_SIZE))
	var col := C_TAG
	col.a = a
	var shadow := C_SHADOW
	shadow.a = C_SHADOW.a * a
	_draw_spaced(_font, text, Vector2(x, baseline + 2.0), TAG_SIZE, TAG_GAP, shadow)
	_draw_spaced(_font, text, Vector2(x, baseline), TAG_SIZE, TAG_GAP, col)
	# Rules either side.
	var rule_y := baseline - 5.0
	for side in [-1.0, 1.0]:
		var x0: float = center_x + side * (w * 0.5 + 18.0)
		var x1: float = center_x + side * (w * 0.5 + 64.0)
		draw_line(Vector2(x0, rule_y), Vector2(x1, rule_y),
			Color(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 0.55 * a), 1.0)
		draw_rect(Rect2(minf(x0, x1) - 2.0, rule_y - 2.0, 4.0, 4.0),
			Color(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 0.7 * a))


# --- CRT shutter -----------------------------------------------------------
# One function for both ends of the ident: two black bars that retract from the
# centre as the tube strikes, and close back onto it as it dies. Drawn LAST so
# it masks everything, which is what makes the collapse read as the screen
# going away rather than as the artwork fading.
func _draw_shutter() -> void:
	var open := 1.0
	if _t < T_POWER:
		open = clampf(_t / T_POWER, 0.0, 1.0)
		# 2.2, not 4: a higher exponent front-loads the travel so hard that the
		# tube reads as snapping open no matter how long this beat is given.
		open = 1.0 - pow(1.0 - open, 2.2)
		_draw_static()
	elif _t > T_HOLD:
		open = 1.0 - clampf((_t - T_HOLD) / (T_OUT - T_HOLD), 0.0, 1.0)
		open = pow(open, 0.85)  # holds a moment, then closes evenly
	if open >= 1.0:
		return
	var half: float = size.y * 0.5 * open
	var mid: float = size.y * 0.5
	draw_rect(Rect2(0.0, 0.0, size.x, mid - half), C_BLACK)
	draw_rect(Rect2(0.0, mid + half, size.x, mid - half + 1.0), C_BLACK)

	# HOW LIT THE BEAM IS, and it is not something `open` can answer. A shut
	# shutter is open == 0 at BOTH ends of the ident - before the tube has
	# struck and after it has died - and the two look nothing alike: the first
	# is unlit black, the second is a fading line. This is the beam's own
	# state, and it multiplies into every lit part below.
	var hot: float = 1.0
	if _t < 0.0:
		hot = 0.0  # the lead: the tube has not struck yet, there is no beam
	elif _t > T_OUT:
		hot = clampf(1.0 - (_t - T_OUT) / 0.22, 0.0, 1.0)  # the tube dying

	# The hot edge of the beam at both lips of the shutter.
	var edge: float = 0.9 * (1.0 - open) * hot
	draw_rect(Rect2(0.0, mid - half - 1.0, size.x, 2.0), Color(0.75, 0.92, 1.0, edge))
	draw_rect(Rect2(0.0, mid + half - 1.0, size.x, 2.0), Color(0.75, 0.92, 1.0, edge))
	# The last sliver of a dying tube is a horizontal line, not a thin band.
	if open < 0.06:
		draw_rect(Rect2(0.0, mid - 1.0, size.x, 2.0),
			Color(0.85, 0.95, 1.0, ((0.06 - open) / 0.06) * hot))


# Interference while the tube warms up. Seeded once in _ready, so the bars are
# in the same places every launch.
func _draw_static() -> void:
	# Nothing during the lead. The formula below goes ABOVE 1.0 for negative
	# _t, so an unguarded lead would open on the brightest static of the ident.
	if _t < 0.0:
		return
	var noise := 1.0 - _t / T_POWER
	_rng.seed = 0x4EFA17
	for i in 22:
		var y := _rng.randf() * size.y
		var h := _rng.randf_range(1.0, 5.0)
		var a := _rng.randf() * 0.09 * noise
		draw_rect(Rect2(0.0, y, size.x, h), Color(0.55, 0.72, 0.9, a))


# --- text helpers ----------------------------------------------------------
# The face is drawn glyph by glyph with an explicit gap: its own advance is
# tight, and a studio name wants air.

func _draw_spaced(font: Font, text: String, origin: Vector2, fsize: int, gap: float, color: Color) -> void:
	var pos := origin
	for ch in text:
		var glyph := String(ch)
		draw_string(font, pos, glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, color)
		pos.x += font.get_string_size(glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize).x + gap


func _text_width(font: Font, text: String, fsize: int, gap: float) -> float:
	var w := 0.0
	for ch in text:
		w += font.get_string_size(String(ch), HORIZONTAL_ALIGNMENT_LEFT, -1, fsize).x + gap
	return maxf(w - gap, 0.0)
