extends Node

## Estado persistente mínimo para a demonstração do Protocolo 17.
## O progresso e as configurações ficam em user://, fora dos arquivos do projeto.

const SAVE_PATH := "user://protocolo17_save.json"
const SETTINGS_PATH := "user://protocolo17_settings.cfg"
const GAME_FONT_PATH := "res://assets/fonts/Kanit-Regular.ttf"

var save_data: Dictionary = {}
var master_volume: float = 0.8
var fullscreen: bool = false
var game_font: Font


func _ready() -> void:
	_setup_game_font()
	_load_save()
	_load_settings()
	apply_settings()


func _setup_game_font() -> void:
	var font_data: FontFile = load(GAME_FONT_PATH) as FontFile
	if font_data == null:
		push_error("Não foi possível carregar a fonte do jogo: %s" % GAME_FONT_PATH)
		return
	var font_variation := FontVariation.new()
	font_variation.base_font = font_data
	font_variation.variation_opentype = {}
	game_font = font_variation
	ThemeDB.fallback_font = game_font
	ThemeDB.fallback_font_size = 16


func start_new_game() -> void:
	save_data = {
		"version": 1,
		"prologue_seen": false,
		"mission_completed": false,
		"current_mission": "distrito_das_aguas",
	}
	save_game()


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH) and not save_data.is_empty()


func has_seen_prologue() -> bool:
	return bool(save_data.get("prologue_seen", false))


func mark_prologue_seen() -> void:
	if save_data.is_empty():
		start_new_game()
	save_data["prologue_seen"] = true
	save_game()


func complete_mission() -> void:
	if save_data.is_empty():
		start_new_game()
	save_data["mission_completed"] = true
	save_game()


func save_game() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Não foi possível salvar o progresso do Protocolo 17.")
		return
	file.store_string(JSON.stringify(save_data, "\t"))


func save_settings(volume_value: float, fullscreen_value: bool) -> void:
	master_volume = clampf(volume_value, 0.0, 1.0)
	fullscreen = fullscreen_value
	var config := ConfigFile.new()
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("display", "fullscreen", fullscreen)
	var error := config.save(SETTINGS_PATH)
	if error != OK:
		push_error("Não foi possível salvar as configurações do Protocolo 17.")
	apply_settings()


func apply_settings() -> void:
	AudioServer.set_bus_mute(0, master_volume <= 0.001)
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(master_volume, 0.001)))
	var desired_mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != desired_mode:
		DisplayServer.window_set_mode(desired_mode)


func _load_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		save_data = parsed


func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	master_volume = float(config.get_value("audio", "master_volume", 0.8))
	fullscreen = bool(config.get_value("display", "fullscreen", false))
