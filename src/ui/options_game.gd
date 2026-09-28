class_name OptionsGame
extends Control

## The game tab. One row so far, and it is the one this task is about.
##
## ## The language names itself
##
## PORTUGUÊS, not "Portuguese". Somebody looking for their own language is
## looking for the word they would write, and a player who has ended up in a
## language they cannot read needs the way out to be in a language they can.
##
## Changing it applies at once: `Locale` hears `Settings.changed`, loads the
## other column of the table and walks the tree calling `relabel()` on
## everything that has one - including this screen, which is why the buttons
## come back in the new language rather than the one they were built in.

var _settings: Node

var _label: Label
var _choices: HBoxContainer


func _ready() -> void:
	_settings = get_node_or_null(^"/root/Settings")
	set_anchors_preset(Control.PRESET_FULL_RECT)
	if _settings != null:
		_settings.changed.connect(_on_setting)

	var column := VBoxContainer.new()
	column.name = "GameColumn"
	column.theme_type_variation = UiKit.SPACED
	column.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(column)

	var row := HBoxContainer.new()
	row.name = "GameLanguageRow"
	row.theme_type_variation = UiKit.SPACED
	column.add_child(row)

	_label = Label.new()
	_label.name = "GameLanguageLabel"
	_label.custom_minimum_size = Vector2(86, 0)
	_label.theme_type_variation = UiKit.DIM
	row.add_child(_label)

	_choices = HBoxContainer.new()
	_choices.name = "GameLanguageChoices"
	_choices.theme_type_variation = UiKit.SPACED
	row.add_child(_choices)

	relabel()


func relabel() -> void:
	if _label == null:
		return
	_label.text = I18n.t(&"GAME_LANGUAGE")
	_fill()


func _fill() -> void:
	for child in _choices.get_children():
		_choices.remove_child(child)
		child.queue_free()
	var now := I18n.locale()
	for locale in I18n.LOCALES:
		var button := Button.new()
		button.name = "Language_%s" % locale
		# **Its own name, in its own language.** The only string in the game
		# that is deliberately the same in every language.
		button.text = String(I18n.NAMES.get(locale, locale))
		button.toggle_mode = true
		button.button_pressed = String(locale) == now
		button.theme_type_variation = UiKit.TAB
		button.custom_minimum_size = Vector2(96, 14)
		button.focus_mode = Control.FOCUS_ALL
		button.pressed.connect(_pick.bind(String(locale)))
		_choices.add_child(button)


func _pick(locale: String) -> void:
	if _settings != null:
		_settings.set_value(&"gameplay/language", locale)


func _on_setting(key: StringName) -> void:
	if key == &"gameplay/language":
		_fill()


# ------------------------------------------------------------ for the checks

func language_shown() -> String:
	for child in _choices.get_children():
		if (child as Button).button_pressed:
			return String(child.name).replace("Language_", "")
	return ""


func choices() -> int:
	return _choices.get_child_count()
