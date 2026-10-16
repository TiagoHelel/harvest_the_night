class_name UiKit
extends RefCounted

## The panels, frames and buttons, and one icon per resource.
##
## **One kit, so four screens look like one game.** The day HUD, the night
## HUD, the shop and the tech tree each grew their own `StyleBoxFlat` with its
## own colours as they were written, which is four places to change a border
## and four chances to miss one. Frames come from `tools/sprite_maps.py`;
## resource icons are deterministic cuts from preserved ImageGen sources.
## Anything that wants a panel asks for the same one.
##
## ## Nine-slice, and the margin is three
##
## Every frame is sixteen by sixteen with a three pixel border and a middle
## that repeats, so one drawing serves a tooltip, a shop panel and the whole
## tech tree at whatever size each needs. `headless_check` asserts the border
## in the art and `MARGIN` here agree, because two numbers that have to match
## and live in different files are two numbers that will not.
##
## ## One theme, and no screen dresses itself
##
## `theme()` builds the whole of it - every font, colour, frame and gap the
## game uses - and `dress()` puts it on. **Nothing in `src/ui/` calls
## `add_theme_*_override`**: task 0081 took the last of them out and
## `headless_check` reads the source files and fails if one comes back. An
## override is a colour one screen has and the other eleven do not, which is
## how this game ended up with four different values of `DIM` and five
## hand-rolled panel backgrounds that were all nearly the same purple.
##
## A screen says *what a thing is* - `label.theme_type_variation = UiKit.DIM`
## - and the theme says what that looks like. `modulate` is left for how lit a
## thing is **right now**, which is the one job it is actually good at: a
## flash decaying back to its own colour.
##
## ## The scale factor is the window's
##
## `SCALE` is one and has to be. The project stretches a 480x270 viewport with
## an integer scale mode, so the whole screen - world, HUD and letters
## together - is already multiplied by a whole number at every window size. A
## second scale inside the theme would multiply that one and put an eight
## pixel font at eleven and a half, which is the blurred bitmap the whole art
## pipeline exists to avoid.
##
## ## Nothing here is a rule
##
## `src/ui/` draws and owns no rules, and this is the drawing half of the
## drawing half. It reads `GameData.RESOURCES` to know what icons to expect
## and writes nothing anywhere.

const DIR := "res://sprites/ui/"

## The game's own letters, drawn from ASCII maps by `tools/gen_font.py`.
const FONT_DIR := "res://assets/fonts/"
## Its native size. Anything asking for a different one gets a blurred bitmap,
## so headings ask for exactly twice this and nothing asks for anything else.
const FONT_SIZE := 8
const HEADING_SIZE := 16

## The border of every nine-slice frame, in pixels.
##
## **Three, because that is what the drawings have.** It was five here and
## three in the art, which slices a frame four pixels into its own middle -
## the check that reads `panel.png` and counts caught it on the first run.
## Two numbers that have to match and live in different files are two numbers
## that will not, so that check stays.
const MARGIN := 3

## The four a button can be in, in Godot's own names, because `theme()` hands
## each one straight to `Theme.set_stylebox`. Nothing outside this file wires
## a button up any more: it is a `Button`, and the theme knows what that is.
const SEED_PACKET := &"SeedPacket"

const BUTTON_STATES := ["normal", "hover", "pressed", "disabled"]

## Loaded once each. A panel asking for its background every frame would
## otherwise be a file read every frame.
static var _cache: Dictionary = {}


## Resource icons use the placeholder road, including a generic stand-in
## for an item whose own icon has not arrived yet.
static func icon(id: StringName, compact: bool = false) -> Texture2D:
	var texture := _texture(("hud_%s" if compact else "icon_%s") % id)
	return texture if texture != null else _texture("hud_wood" if compact else "icon_wood")


## A UI picture by its runtime name in `sprites/ui/` - a book portrait, a tab
## icon - through 0120's road while its pack is a stand-in, or null (task
## 0182). Its tint and scale are `PlaceholderArt.art_tint`/`art_scale`.
static func picture(name: StringName) -> Texture2D:
	return _texture(String(name))


## **A picture in its stand-in's tint** (task 0233), for where only a texture
## goes - a button's icon, whose colours are the theme's - as a `TextureRect`
## takes the tint for its `modulate`. The picture itself for real art, which
## is white, and wherever the image cannot be read back.
static func tinted_picture(name: StringName) -> Texture2D:
	var plain := picture(name)
	var tint := PlaceholderArt.art_tint(name)
	if plain == null or tint == Color.WHITE:
		return plain
	var key := "%s@tinted" % name
	if _cache.has(key):
		return _cache[key]
	var image: Image = plain.get_image()
	var made: Texture2D = plain
	if image != null and not image.is_empty():
		image = image.duplicate() as Image
		if image.is_compressed():
			image.decompress()
		image.convert(Image.FORMAT_RGBA8)
		for y in image.get_height():
			for x in image.get_width():
				var was := image.get_pixel(x, y)
				image.set_pixel(x, y, Color(minf(was.r * tint.r, 1.0), minf(was.g * tint.g, 1.0),
					minf(was.b * tint.b, 1.0), was.a * tint.a))
		made = ImageTexture.create_from_image(image)
	_cache[key] = made
	return made


## Whether every resource has one and no icon is orphaned. The done-when of
## task 0079, asked as a question rather than left to a person to check.
static func missing_icons() -> Array:
	var out: Array = []
	for id in GameData.RESOURCES:
		if _texture("icon_%s" % id) == null:
			out.append(str(id))
	return out


## Icons in `sprites/ui/` that no resource claims - nor a group a cost may
## name, whose icon stands for any of it (`GameData.ANY_OF`: the fish since
## task 0179), nor a defence of the hotbar or a picture of the night bar
## (A005's, task 0147), nor a calendar mark (A010's, task 0161), nor a tool at
## one of its tiers (A019's, task 0202).
static func orphan_icons() -> Array:
	var wanted: Dictionary = {}
	for id in GameData.RESOURCES + GameData.ANY_OF:
		wanted["icon_%s" % id] = true
	for id in GameData.DEFENCES.keys() + NightHud.ICONS + CalendarMark.MARKS:
		wanted["icon_%s" % id] = true
	# **The night events' marks** (task 0269): A055's fog, rain and Blood
	# Moon, in the calendar mark's event slot.
	for id in Weather.EVENTS:
		wanted["icon_%s" % id] = true
	# **The powers' pictures and a defence's later levels** (A045, task
	# 0244): the bell, the dog and the repair, and the hardwood wall that is
	# the stone wall's level two.
	for id in Ability.ORDER:
		wanted["icon_%s" % id] = true
	for id in GameData.TOWER_LEVELS:
		for step in (GameData.TOWER_LEVELS[id] as Array).size():
			wanted["icon_%s_%d" % [id, step + 2]] = true
	# **The fish book's tab** (task 0182), its picture at 16 as well as the
	# tab's 10 - A023's since task 0206.
	wanted["icon_book_fish"] = true
	# **The collection book's tabs** (task 0288), A056's.
	for tab in [&"crops", &"bosses", &"year", &"achievements"]:
		wanted["icon_book_%s" % tab] = true
	# **The day's build list** (task 0201): a building's pictures, A018's
	# sprinklers the first.
	for id in GameData.BUILDINGS:
		wanted["icon_%s" % id] = true
	for tool in GameData.TOOLS:
		for tier in (GameData.TOOLS[tool] as Array).size():
			wanted["icon_%s" % ToolTiers.item(tool, tier)] = true
	var out: Array = []
	var folder := DirAccess.open(DIR)
	if folder == null:
		return out
	for name in folder.get_files():
		if not name.begins_with("icon_") or not name.ends_with(".png"):
			continue
		var stem := name.substr(0, name.length() - 4)
		if not wanted.has(stem):
			out.append(stem)
	out.sort()
	return out


## The HUD face, or null before task 0080 has been run.
static func font() -> Font:
	return _font("hud")


## The same letters at twice the size. **Not a second design**: a whole-number
## scale of a bitmap is still a bitmap, and two faces drawn separately are two
## faces to keep in step.
static func heading_font() -> Font:
	return _font("heading")


## The theme's own scale. **One, and it has to be** - see the note at the top
## of this file. It is named rather than written as a bare 1 so that the next
## person who wants a bigger UI finds the reason before they find the number.
const SCALE := 1.0

## How far a panel holds its contents off its own frame, on top of the three
## pixel border. Five on every panel in the game, because five on one and
## eight on another is exactly what "no screen is the odd one out" rules out.
const PAD := 5

## What a list row holds its text off its own edges. Tighter than `PAD`: a row
## is eleven pixels tall and five a side would leave one for the letters.
const ROW_PAD := 3

## **The colours the UI is allowed to be, and where each one comes from.**
##
## Every value is a name in `PaletteData.COLOURS`, so the UI and the sprites
## are painted out of the same tin and a palette change reaches both. Before
## task 0081 these lived as `const DIM := Color(...)` in ten different files
## with four different values of `DIM`, which is not a palette, it is a habit.
##
## The key is the theme type variation a screen asks for. `&""` is the plain
## `Label` every screen gets without asking for anything.
const ROLES := {
	&"": &"bone",                   # body text: warm off-white, not white
	&"Dim": &"bone_dark",           # secondary - a label beside a number
	&"Faint": &"stone",             # none held, locked, unavailable
	&"Warm": &"gold_light",         # a heading, or the thing being pointed at
	&"Money": &"gold",              # brass, like the coins on the sheet
	&"Warn": &"flame",              # short of something, but not yet losing
	&"Good": &"grass_light",        # owned, safe, survived
	&"Bad": &"roof_light",          # a zombie on the house, a night lost
	&"Cool": &"moon",               # the records screen's quiet blue
}

## The names a screen uses, so a typo is a parse error rather than a label
## that quietly stays the wrong colour.
const DIM := &"Dim"
const FAINT := &"Faint"
const WARM := &"Warm"
const MONEY := &"Money"
const WARN := &"Warn"
const GOOD := &"Good"
const BAD := &"Bad"
const COOL := &"Cool"

## The heading face, which is the same design at twice the size. Its own
## variation rather than one more role, because it changes the size as well as
## the colour.
const HEADING := &"Heading"

## A list row: a button with no frame until it is pointed at. The panels are
## full of them, and a drawn sixteen pixel frame around an eleven pixel row
## would be a frame with no room left for the row.
const ROW := &"Row"

## **A click with nothing drawn** (task 0222): laid over something that
## draws itself - the seed strip's bone meal row - so the row keeps its own
## look and the screen still names no mouse button.
const HIT := &"Hit"

## The frame the debug read-out wears - the quiet one, because a developer
## overlay that competes with the game is an overlay in the way.
const OVERLAY := &"Overlay"

## A shop tab: the panel with its bottom edge open, so it reads as joined to
## the list underneath it.
const TAB := &"Tab"

## A container that keeps a gap between its children.
##
## **For two columns on one line, where the left one can grow.** The game's
## containers are gapless because a list of a dozen rows with four pixels
## between each is fifty pixels of nothing on a 270 pixel screen - but a
## label beside a value is not a list, and when the label ran past its column
## the two ran into each other and printed "still up19 untouched". Found by
## looking at task 0082's result shot.
const SPACED := &"Spaced"

## A button for something already bought. It is a `disabled` button - there is
## nothing left to press - with green letters, so "you have this" and "you
## cannot afford this" are not the same grey.
const OWNED := &"Owned"
const PORCH_HINT := &"PorchHint"

## A line of the options screen (`OptionRow`): no frame until it is pointed at
## or selected, then a quiet wash, with the caret in the margin and the
## value's arrows lit. Its own variation because a row is the whole width of
## the card, and a drawn key that wide would be a slab.
const OPTION := &"OptionRow"

## How far an options row holds its name in from its left edge - room for the
## caret it draws there.
const OPTION_INDENT := 8

## A heading between rows of options - a group of controls: gold words, no
## frame, not a thing to stand on.
const OPTION_HEADING := &"OptionHeading"

## A column of menu entries - the title's, the pause menu's - with a little
## air between them. See `MENU_GAP`.
const STACKED := &"Stacked"

## The air between two entries of a menu column, in pixels.
const MENU_GAP := 2

## **A hotbar slot's price** (task 0133): two lines packed tighter than the
## theme's own spacing - a slot is 32 pixels tall with a 16 pixel icon in it -
## warm when it can be paid and red with what is short.
const SLOT_PRICE := &"SlotPrice"
const SLOT_SHORT := &"SlotShort"
const SLOT_LINE_SPACING := -2

## A button that does something that cannot be undone - abandon, quit - in
## the same key with red letters, so it never looks like the one beside it
## that keeps things as they are.
const DANGER := &"Danger"

## **The day HUD's clock, late** (task 0140): the heading face in the warn
## colour, from the minutes before he passes out.
const CLOCK_LATE := &"ClockLate"

## **GO TO BED** (task 0140): the way into the night wears the moon's letters,
## and from the reminder hour the whole key is lit, as if it were pointed at.
const BED := &"BedButton"
const BED_LIT := &"BedButtonLit"



## The same nine roles, pushed apart. **Task 0098.**
##
## Not a second palette: every value here is still a name in
## `PaletteData.COLOURS`, picked so that **no role is darker than it was and
## the quiet ones stop being quiet** - `Dim` becomes the body colour and
## `Faint` becomes what `Dim` was. What it costs is the hierarchy, which is
## exactly the trade somebody turning it on is asking to make.
##
## The frames stay as they are. They are drawings, and a second set of them
## would be art nobody asked for; the win here is in the words.
const CONTRAST_ROLES := {
	&"": &"bone",                   # already the brightest thing there is
	&"Dim": &"bone",                # nothing is dim any more
	&"Faint": &"bone_dark",         # and nothing is faint
	&"Warm": &"flame_hot",
	&"Money": &"gold_light",
	&"Warn": &"flame",
	&"Good": &"grass_light",
	&"Bad": &"roof_light",
	&"Cool": &"moon",
}

## Whether the game is wearing the pushed-apart colours.
static var _high_contrast := false


static func high_contrast() -> bool:
	return _high_contrast


## **Changing this does not redress anything.** `A11y` sets it and then walks
## the tree, because a kit that reached into a tree would be a kit that knew
## what a screen was.
static func set_high_contrast(on: bool) -> void:
	_high_contrast = on


## A colour by the name a screen knows it as, straight off the palette.
##
## An unknown name comes back as the body text colour rather than as magenta
## or as a crash: a typo should make a label look ordinary, not make the
## screen it is on disappear.
static func colour(role: StringName = &"") -> Color:
	var table: Dictionary = CONTRAST_ROLES if _high_contrast else ROLES
	var key: StringName = table.get(role, table[&""])
	return PaletteData.COLOURS.get(key, Color.WHITE)


## The whole theme: every font, colour, frame and gap the game uses.
##
## **Built here rather than set in `project.godot`.** `gui/theme/custom_font`
## read back as an empty string with the path still in it - Godot did not take
## a `.fnt` through that setting - and a line of configuration that silently
## does nothing is worse than no line at all. This is code, so
## `headless_check` can ask it questions.
static func theme() -> Theme:
	var out := Theme.new()
	out.default_base_scale = SCALE
	out.default_font_size = FONT_SIZE
	var face := font()
	if face != null:
		out.default_font = face

	_dress_text(out)
	_dress_frames(out)
	_dress_buttons(out)
	_dress_gaps(out)
	return out


## Puts the theme on a tree, and says how many islands it dressed.
##
## Walks it and dresses **every Control with no Control above it** - the root
## of each `CanvasLayer`, and anything hung straight off a `Node2D`. A theme
## is inherited by a Control's descendants, so one per island is enough, and a
## row built later inherits it the moment it is added.
##
## Done by walking rather than by hand because the debug overlay is on its own
## `CanvasLayer` outside the UI one, and a screen that has to remember to ask
## for the theme is a screen that will one day forget. Task 0091's title
## screen and 0092's router arrive dressed without touching this.
static func dress(root: Node, wearing: Theme = null) -> int:
	return _dress(root, wearing if wearing != null else theme(), false)


static func _dress(node: Node, wearing: Theme, under_control: bool) -> int:
	var count := 0
	var control := node as Control
	if control != null and not under_control:
		control.theme = wearing
		count += 1
	var inside := under_control or control != null
	for child in node.get_children():
		count += _dress(child, wearing, inside)
	return count


# ------------------------------------------------------------------ the parts

static func _dress_text(out: Theme) -> void:
	# The plain Label first, then one variation per role. A screen names the
	# role and never the colour, which is what makes a palette change one edit
	# instead of forty.
	out.set_color(&"font_color", &"Label", colour())
	for role in ROLES:
		if role == &"":
			continue
		out.set_type_variation(role, &"Label")
		out.set_color(&"font_color", role, colour(role))

	out.set_type_variation(HEADING, &"Label")
	out.set_color(&"font_color", HEADING, colour(WARM))
	out.set_font_size(&"font_size", HEADING, HEADING_SIZE)
	var big := heading_font()
	if big != null:
		out.set_font(&"font", HEADING, big)
	out.set_type_variation(CLOCK_LATE, HEADING)
	out.set_color(&"font_color", CLOCK_LATE, colour(WARN))

	# Godot draws tooltips through these two types and nothing else, so a
	# tooltip not named here would be the one control still wearing the
	# engine's grey.
	out.set_stylebox(&"panel", &"TooltipPanel", tooltip())
	out.set_color(&"font_color", &"TooltipLabel", colour())
	out.set_type_variation(PORCH_HINT, &"Label")
	out.set_color(&"font_color", PORCH_HINT, colour(WARM))
	for price in [[SLOT_PRICE, WARM], [SLOT_SHORT, BAD]]:
		out.set_type_variation(price[0], &"Label")
		out.set_color(&"font_color", price[0], colour(price[1]))
		out.set_constant(&"line_spacing", price[0], SLOT_LINE_SPACING)
	out.set_stylebox(&"normal", PORCH_HINT, _flat(_wash(&"ink", 0.90)))


static func _dress_frames(out: Theme) -> void:
	for type in [&"Panel", &"PanelContainer"]:
		out.set_stylebox(&"panel", type, _padded(panel(), PAD, PAD))
	out.set_type_variation(OVERLAY, &"PanelContainer")
	out.set_stylebox(&"panel", OVERLAY, _padded(tooltip(), PAD - 1, PAD - 1))


static func _dress_buttons(out: Theme) -> void:
	out.set_type_variation(SEED_PACKET, &"Button")
	for state in ["normal", "hover", "focus", "pressed", "disabled"]:
		out.set_color(StringName("icon_%s_color" % state), SEED_PACKET, Color(0.72, 0.84, 1.0))
	# **Three pixels across, none down.** A `Button` computes its minimum
	# height from its content margins, so a vertical margin here is a control
	# that ignores the size it was given - the bug that put the build palette
	# off the bottom of the screen at 0032, the shop rows at 0040, the speed
	# control at 0055 and the tech tree's third column off the side at 0061.
	# Every one of those screens had pinned this by hand; now it is pinned
	# once.
	for state in BUTTON_STATES:
		out.set_stylebox(StringName(state), &"Button",
			_padded(button(state), ROW_PAD, 0))
	# **A pressed key sinks.** The drawing moves the light to the bottom
	# edge; this moves the label down the pixel that goes with it. One pixel
	# of top margin on one state, so the button still reserves almost nothing
	# (see the note above) and the label only ever travels while it is held.
	(out.get_stylebox(&"pressed", &"Button") as StyleBox).content_margin_top = 1
	# **Focus is a state, not the absence of one.** Two screens used to hide
	# Godot's grey dashed ring behind an empty box, which leaves a keyboard
	# with no way to say where it is. `ui/button_focus` is a gold ring laid
	# over the brass trim, drawn over whichever state the button is in.
	out.set_stylebox(&"focus", &"Button", _frame("button_focus"))
	out.set_color(&"font_color", &"Button", colour())
	# **Bone on the warm face, gold when only the keyboard has it.** Pointing
	# warms the whole key (`ui/button_hover`), so its letters stay the body
	# colour, which reads better on wood than gold does; a button selected by
	# the keys keeps its dark face and says so with gold letters and the ring.
	out.set_color(&"font_hover_color", &"Button", colour())
	out.set_color(&"font_focus_color", &"Button", colour(WARM))
	# Pressed is gold, so its letters are ink. Bone on gold is the one pair in
	# this palette that cannot be read at eight pixels.
	out.set_color(&"font_pressed_color", &"Button",
		PaletteData.COLOURS[&"ink"])
	out.set_color(&"font_hover_pressed_color", &"Button",
		PaletteData.COLOURS[&"ink"])
	out.set_color(&"font_disabled_color", &"Button", colour(FAINT))

	# **An options row** - see `OPTION`. The wash is the selection; the name
	# is dim until the row is stood on, then the body colour, then gold.
	var nothing := Color(0, 0, 0, 0)
	out.set_type_variation(OPTION, &"Button")
	# Eight pixels in on the left, so the caret the row draws for itself sits
	# inside it: a page scrolls, and a scroll clips anything left of its rows.
	for state in ["normal", "disabled", "hover", "pressed", "focus"]:
		var fill := nothing
		match state:
			"hover":
				fill = _wash(&"night_light", 0.55)
			"pressed":
				fill = _wash(&"night_light", 0.95)
			"focus":
				fill = _wash(&"night_light", 0.80)
		var box := _flat(fill) as StyleBoxFlat
		box.content_margin_left = OPTION_INDENT
		out.set_stylebox(StringName(state), OPTION, box)
	out.set_color(&"font_color", OPTION, colour(DIM))
	out.set_color(&"font_hover_color", OPTION, colour())
	out.set_color(&"font_focus_color", OPTION, colour(WARM))
	out.set_color(&"font_pressed_color", OPTION, colour(WARM))
	out.set_color(&"font_hover_pressed_color", OPTION, colour(WARM))
	out.set_color(&"font_disabled_color", OPTION, colour(FAINT))
	out.set_type_variation(OPTION_HEADING, &"Button")
	for state in BUTTON_STATES + ["focus"]:
		out.set_stylebox(StringName(state), OPTION_HEADING, _flat(nothing))
	for colour_name in [&"font_color", &"font_hover_color", &"font_focus_color",
			&"font_pressed_color", &"font_disabled_color"]:
		out.set_color(colour_name, OPTION_HEADING, colour(MONEY))

	# **The button that does something that cannot be undone.** Red letters on
	# the same key, so the one entry in a question that throws a run away does
	# not look like the one that keeps it.
	out.set_type_variation(DANGER, &"Button")
	out.set_color(&"font_color", DANGER, colour(BAD))
	out.set_color(&"font_focus_color", DANGER, colour(BAD))
	out.set_color(&"font_hover_color", DANGER, colour(BAD))

	# **A list row has no frame until it is pointed at.** Flat boxes rather
	# than drawings: a row's hover is one flat colour, and an ASCII map of
	# sixteen by sixteen pixels all the same would be a drawing pretending to
	# be a number.
	out.set_type_variation(ROW, &"Button")
	out.set_stylebox(&"normal", ROW, _flat(_wash(&"night", 0.80)))
	out.set_stylebox(&"hover", ROW, _flat(_wash(&"night_light", 0.90)))
	out.set_stylebox(&"pressed", ROW, _flat(_wash(&"gold_dark", 0.95)))
	out.set_stylebox(&"disabled", ROW, _flat(_wash(&"ink", 0.70)))
	out.set_stylebox(&"focus", ROW, _frame("button_focus"))
	out.set_color(&"font_color", ROW, colour())
	out.set_color(&"font_hover_color", ROW, colour(WARM))
	out.set_color(&"font_pressed_color", ROW, colour(WARM))
	out.set_color(&"font_disabled_color", ROW, colour(FAINT))

	# **A click with nothing drawn** (task 0222): every state the option
	# heading's clear box.
	out.set_type_variation(HIT, &"Button")
	for state in BUTTON_STATES + ["focus"]:
		out.set_stylebox(StringName(state), HIT, _flat(nothing))

	# **A variation only has to say what differs.** Everything `Owned` does
	# not name falls through to `Button`, so this is one colour rather than a
	# second set of four frames to keep in step.
	out.set_type_variation(OWNED, &"Button")
	out.set_color(&"font_disabled_color", OWNED, colour(GOOD))

	# **GO TO BED, and GO TO BED when it is time.** The moon's letters on the
	# usual key, then the warm face pointing gives a key, with the body
	# colour on it - gold on wood is the pair that does not read.
	out.set_type_variation(BED, &"Button")
	for name in [&"font_color", &"font_hover_color", &"font_focus_color"]:
		out.set_color(name, BED, colour(COOL))
	out.set_type_variation(BED_LIT, &"Button")
	out.set_stylebox(&"normal", BED_LIT, _padded(button("hover"), ROW_PAD, 0))
	for name in [&"font_color", &"font_hover_color", &"font_focus_color"]:
		out.set_color(name, BED_LIT, colour())

	# Open-bottom tabs retain their three-pixel side margins. A gold underline
	# identifies the selected page; hover and disabled have their own fields.
	# Pressed letters remain warm rather than disappearing against the field.
	out.set_type_variation(TAB, &"Button")
	for state in BUTTON_STATES:
		var name := "tab_hover" if state == "hover" else "tab_selected" if state == "pressed" else "tab_disabled" if state == "disabled" else "tab"
		out.set_stylebox(StringName(state), TAB, _padded(_frame(name, 0), ROW_PAD, 0))
	out.set_stylebox(&"focus", TAB, _frame("button_focus"))
	out.set_color(&"font_color", TAB, colour(DIM))
	out.set_color(&"font_hover_color", TAB, colour())
	out.set_color(&"font_pressed_color", TAB, colour(WARM))
	out.set_color(&"font_disabled_color", TAB, colour(FAINT))

	# The two the settings screen wants at task 0086. Named now because the
	# kit drew them at 0079, and a piece of art nothing can reach is a piece
	# of art nobody will remember to wire up.
	out.set_stylebox(&"slider", &"HSlider", slider_track())
	# **The filled part of the track, which Godot draws over the top of it.**
	# Left alone it is the default engine grey - measured at (118, 116, 131),
	# a colour that is in no palette this game has - and it hid the trough
	# completely, so a slider at seven tenths was a short grey bar with
	# nothing after it to be seven tenths *of*. Task 0094 put the first
	# slider on a screen and that is how it was found.
	out.set_stylebox(&"grabber_area", &"HSlider",
		_bar(_wash(&"gold_dark", 0.95)))
	out.set_stylebox(&"grabber_area_highlight", &"HSlider",
		_bar(_wash(&"gold", 0.95)))
	var grab := slider_grab()
	if grab != null:
		out.set_icon(&"grabber", &"HSlider", grab)
		out.set_icon(&"grabber_highlight", &"HSlider", _texture("slider_grab_highlight"))
		out.set_icon(&"grabber_disabled", &"HSlider", _texture("slider_grab_disabled"))
	out.set_stylebox(&"focus", &"HSlider", _frame("button_focus"))
	# **A scroll bar, which nothing had ever dressed.** There have been three
	# `ScrollContainer`s in the game since task 0040 and every one of them
	# had Godot's default grey slab down its side - found the same way the
	# slider was, by putting one on a screen and looking at it. A thin dark
	# groove with a gold grabber, the same vocabulary as everything else.
	for bar in [&"VScrollBar", &"HScrollBar"]:
		out.set_stylebox(&"scroll", bar, _groove(2))
		out.set_stylebox(&"scroll_focus", bar, _groove(2))
		for state in ["grabber", "grabber_highlight", "grabber_pressed"]:
			out.set_stylebox(StringName(state), bar,
				_bar(_wash(&"gold_dark" if state == "grabber" else "gold",
					0.95)))

	var on := checkbox(true)
	var off := checkbox(false)
	if on != null and off != null:
		out.set_icon(&"checked", &"CheckBox", on)
		out.set_icon(&"unchecked", &"CheckBox", off)
		out.set_icon(&"checked_disabled", &"CheckBox", _texture("checkbox_on_disabled"))
		out.set_icon(&"unchecked_disabled", &"CheckBox", _texture("checkbox_off_disabled"))


static func _dress_gaps(out: Theme) -> void:
	# **No gap between rows.** Godot's default puts four pixels between a
	# container's children, which down a list of a dozen is fifty pixels of
	# nothing on a screen two hundred and seventy tall. Eight screens set this
	# to zero one container at a time; now the game does it once.
	for type in [&"BoxContainer", &"VBoxContainer", &"HBoxContainer"]:
		out.set_constant(&"separation", type, 0)
	out.set_type_variation(SPACED, &"HBoxContainer")
	out.set_constant(&"separation", SPACED, ROW_PAD)
	# A column of menu entries: two pixels of air between keys, so each one
	# is its own thing to point at rather than one striped slab.
	out.set_type_variation(STACKED, &"VBoxContainer")
	out.set_constant(&"separation", STACKED, MENU_GAP)
	for side in [&"margin_left", &"margin_right", &"margin_top",
			&"margin_bottom"]:
		out.set_constant(side, &"MarginContainer", PAD)


## A palette colour at less than full opacity, for a fill that sits over the
## game rather than over a panel.
static func _wash(key: StringName, alpha: float) -> Color:
	var found: Color = PaletteData.COLOURS.get(key, Color.WHITE)
	return Color(found.r, found.g, found.b, alpha)


## The empty half of a track: dark, with a quiet edge. `across` is how wide
## it makes whatever asks for its minimum size.
static func _groove(across: int) -> StyleBox:
	var box := StyleBoxFlat.new()
	box.bg_color = _wash(&"ink", 0.9)
	box.set_border_width_all(1)
	box.border_color = _wash(&"ink_soft", 0.85)
	box.content_margin_left = across
	box.content_margin_right = across
	return box


## A flat box with no margins at all, for something drawn inside a track
## rather than round a piece of text.
static func _bar(fill: Color) -> StyleBox:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	return box


static func _flat(fill: Color) -> StyleBox:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.content_margin_left = ROW_PAD
	box.content_margin_right = ROW_PAD
	box.content_margin_top = 1
	box.content_margin_bottom = 1
	return box


## The same frame with its padding pinned.
##
## **A `StyleBoxTexture` otherwise takes its content margin from its own
## nine-slice border**, so every panel in the game would hold its contents
## exactly three pixels off the edge whether that suited it or not, and a
## button would grow by however wide its frame happened to be drawn. Task
## 0079 found this the hard way, when a button pushed the tech tree's third
## column off a four hundred and eighty pixel screen.
static func _padded(box: StyleBox, across: int, down: int) -> StyleBox:
	box.content_margin_left = across
	box.content_margin_right = across
	box.content_margin_top = down
	box.content_margin_bottom = down
	return box


static func _font(face: String) -> Font:
	var path := FONT_DIR + "harvest_%s.fnt" % face
	if _cache.has(path):
		return _cache[path]
	var found: Font = load(path) if ResourceLoader.exists(path) else null
	_cache[path] = found
	return found


# ------------------------------------------------------------------ the frames

## The frame a panel sits in.
static func panel() -> StyleBox:
	return _frame("panel")


## The quieter one a tooltip sits in.
static func tooltip() -> StyleBox:
	return _frame("tooltip")


## The one a tab sits in - a panel with its bottom edge open, so it reads as
## joined to what is under it.
static func tab() -> StyleBox:
	return _frame("tab", 0)


## A button in one of `BUTTON_STATES`.
static func button(state: String) -> StyleBox:
	return _frame("button_%s" % state)


## The rail a slider runs along, and the thing that runs along it.
## The empty part of a slider.
##
## **One pixel of margin, not three.** Godot draws this at the stylebox's own
## height rather than the control's, and it is four pixels tall - so a margin
## of two at the top and two at the bottom is the entire thing, and the middle
## it would stretch is nothing at all. Measured at task 0094, which put the
## first slider in the game on a screen.
static func slider_track() -> StyleBox:
	return _frame("slider_track", 1, 1, 1)


static func slider_grab() -> Texture2D:
	return _texture("slider_grab")


static func checkbox(ticked: bool) -> Texture2D:
	return _texture("checkbox_on" if ticked else "checkbox_off")


## A nine-slice box off one of the drawings.
##
## `bottom` and `top` default to `MARGIN` and are given only where a frame is
## deliberately open on one side.
static func _frame(name: String, bottom: int = MARGIN,
		top: int = MARGIN, across: int = MARGIN) -> StyleBox:
	var texture := _texture(name)
	if texture == null:
		# **A flat box rather than nothing.** A missing frame should look
		# wrong on screen, not crash the panel that asked for it.
		var flat := StyleBoxFlat.new()
		flat.bg_color = Color(0.10, 0.09, 0.16, 0.92)
		flat.set_border_width_all(1)
		flat.border_color = Color(0.42, 0.37, 0.30, 0.75)
		return flat
	var box := StyleBoxTexture.new()
	box.texture = texture
	box.texture_margin_left = across
	box.texture_margin_right = across
	box.texture_margin_top = top
	box.texture_margin_bottom = bottom
	return box


static func _texture(name: String) -> Texture2D:
	if _cache.has(name):
		return _cache[name]
	var path := PlaceholderArt.texture_path(DIR + name + ".png")
	var found: Texture2D = load(path) if ResourceLoader.exists(path) else null
	_cache[name] = found
	return found
