extends RefCounted
## Permanent district access is independent from the current Water checkpoint.
const PATH := "user://aurora_campaign.json"
const Simulation = preload("res://scripts/simulation.gd")
var path := PATH
var water_completed := false
var difficulty := "operation"
var upgrades: Array = []

func load_progress() -> void:
	if not FileAccess.file_exists(path): return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Dictionary or data.get("version") != 1 or data.get("water_completed") != true: return
	var validator := Simulation.new()
	if not validator.load_data({"version": 2, "stage": 3, "difficulty": data.get("difficulty"), "chosen": data.get("upgrades")}): return
	water_completed = true
	difficulty = validator.difficulty
	upgrades = validator.chosen.duplicate()

func complete_water(level: String, chosen: Array) -> Error:
	var validator := Simulation.new()
	if not validator.load_data({"version": 2, "stage": 3, "difficulty": level, "chosen": chosen}): return ERR_INVALID_DATA
	var data := {"version": 1, "water_completed": true, "difficulty": level, "upgrades": chosen.duplicate()}
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null: return FileAccess.get_open_error()
	file.store_string(JSON.stringify(data))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK: return write_error
	var error := DirAccess.rename_absolute(path + ".tmp", path)
	if error == OK:
		water_completed = true
		difficulty = level
		upgrades = chosen.duplicate()
	return error

func residue_loadout(level: String) -> Dictionary:
	return {"difficulty": level, "upgrades": upgrades.duplicate()}
