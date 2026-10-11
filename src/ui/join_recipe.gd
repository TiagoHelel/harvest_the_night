class_name JoinRecipe
extends RefCounted

## **The contract's recipe for a barrier's joins** (ART-CONTRACT 2.3): a
## family's three modules - `post`, `horizontal` and `vertical`, on one canvas
## - make its 16 masks by slicing the arms out of them and pasting them where
## the table says, N, W, E and S, and the post over them. An approved pack's
## `build.py` composes its masks this way, and so do the placeholder road's
## drawings (task 0230's electric fence, 0231's hardwood wall and sandbags),
## so they join as the real art will. View only.

## Each arm: its bit (N = 1, E = 2, S = 4, W = 8), the module it comes from,
## the slice of it and where the slice goes - in the order they are pasted.
const STEPS := [
	[1, &"vertical", Rect2i(0, 8, 16, 20), Vector2i(0, 0)],
	[8, &"horizontal", Rect2i(0, 0, 8, 32), Vector2i(0, 0)],
	[2, &"horizontal", Rect2i(8, 0, 8, 32), Vector2i(8, 0)],
	[4, &"vertical", Rect2i(0, 8, 16, 20), Vector2i(0, 8)],
]


## `mask` composed from `modules` onto a clear canvas of the post's size.
static func compose(modules: Dictionary, mask: int) -> Image:
	var post: Image = modules[&"post"]
	var image := Image.create(post.get_width(), post.get_height(), false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for step in STEPS:
		if mask & int(step[0]):
			image.blend_rect(modules[step[1]] as Image, step[2] as Rect2i, step[3] as Vector2i)
	image.blend_rect(post, Rect2i(Vector2i.ZERO, post.get_size()), Vector2i.ZERO)
	return image


## The runtime name of a family's mask, whole or hurt - what
## `WorldView._barrier_name()` asks for: `<family>`, `<family>_join_<mask>`,
## either with `_hurt`.
static func name_of(family: String, mask: int, hurt: bool) -> StringName:
	return StringName(family + ("_join_%d" % mask if mask > 0 else "") + ("_hurt" if hurt else ""))


## `[mask, hurt]` for one of a family's joins by its runtime name, or
## `[-1, false]` for anything else - its wreck included.
static func parse(family: String, name: String) -> Array:
	if not name.begins_with(family):
		return [-1, false]
	var rest := name.substr(family.length())
	var hurt := rest.ends_with("_hurt")
	if hurt:
		rest = rest.trim_suffix("_hurt")
	if rest.is_empty():
		return [0, hurt]
	if not rest.begins_with("_join_") or not rest.substr(6).is_valid_int():
		return [-1, false]
	var mask := int(rest.substr(6))
	return [mask, hurt] if mask >= 1 and mask <= 15 else [-1, false]


## Every runtime name of a family's joins: the 16 masks whole, then hurt.
static func names(family: String) -> Array:
	var out: Array = []
	for hurt in [false, true]:
		for mask in 16:
			out.append(name_of(family, mask, hurt))
	return out
