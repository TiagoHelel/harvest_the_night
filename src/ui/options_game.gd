class_name OptionsGame
extends OptionsPage

## The game page: which language the game speaks, how fast a night runs,
## the fishing assist and whether the forecast is up all day.
##
## **The language applies the moment it changes**, like everything else on
## this screen - `Locale` relabels every screen that is up, this one included,
## so the row a player just changed is already in the language they chose.
##
## **Night speed is the HUD's speed button, written down** (2026-10-07).
## WELCOME BACK, HERO keeps its playback speed with its other settings; this
## game's lives on the night HUD as well, and both are the same setting, so a
## speed chosen here is the one the button starts from - and a run that is up
## behind the options picks it up at once (`SimDriver` listens).
##
## **The fishing assist and the all-day forecast** (task 0292) are switches.
## The assist is 0180's rule, reaching the run through an intent `Main`
## writes every frame; the forecast's hours are the view's.

var _language: OptionRow
var _speed: OptionRow
var _assist: OptionRow
var _forecast: OptionRow


func _init() -> void:
	resets = [&"gameplay/language", &"gameplay/night_speed",
		&"gameplay/fishing_assist", &"gameplay/forecast_all_day"]
	title_key = &"OPT_TAB_GAME"


func _build() -> void:
	_language = choice_row("GameLanguage", _step_language, _language_text)
	_speed = choice_row("GameNightSpeed", _step_speed, _speed_text)
	_assist = toggle_row("GameFishingAssist", &"gameplay/fishing_assist")
	_forecast = toggle_row("GameForecastAllDay", &"gameplay/forecast_all_day")


func relabel() -> void:
	if _language == null:
		return
	_language.text = I18n.t(&"GAME_LANGUAGE")
	_speed.text = I18n.t(&"GAME_NIGHT_SPEED")
	_assist.text = I18n.t(&"GAME_FISHING_ASSIST")
	_forecast.text = I18n.t(&"GAME_FORECAST_ALL_DAY")
	say("")
	super()


func _step_language(delta: int) -> void:
	if _settings == null:
		return
	var next: String = String(stepped(I18n.LOCALES, I18n.locale(), delta))
	_settings.set_value(&"gameplay/language", next)


func _language_text() -> String:
	var now := I18n.locale()
	return String(I18n.NAMES.get(now, now))


func _step_speed(delta: int) -> void:
	if _settings == null:
		return
	var now := int(_settings.get_int(&"gameplay/night_speed"))
	_settings.set_value(&"gameplay/night_speed",
		int(stepped(GameData.SPEEDS, now, delta)))


func _speed_text() -> String:
	var now := int(_settings.get_int(&"gameplay/night_speed")) \
		if _settings != null else 1
	return I18n.f(&"NHUD_SPEED", [now])


func _on_setting(key: StringName) -> void:
	if String(key).begins_with("gameplay/"):
		refresh()


# ------------------------------------------------------------ for the checks

## The language the row says, as a locale id.
func language_shown() -> String:
	return I18n.locale() if _language != null else ""


## How many languages there are to step through.
func choices() -> int:
	return I18n.LOCALES.size()
