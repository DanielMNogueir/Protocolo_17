extends RefCounted
## Permanent district access is independent from the current Water checkpoint.
## Version 2 adds Residues and Energy completion and the module chosen after
## Residues. Version 1 files (Water only) still load.
const PATH := "user://aurora_campaign.json"
const Simulation = preload("res://scripts/simulation.gd")
const Loadout = preload("res://scripts/campaign_loadout.gd")
var path := PATH
var water_completed := false
var difficulty := "operation"
var upgrades: Array = []
var residues_completed := false
var residue_upgrade := ""
var energy_completed := false

func load_progress() -> void:
	if not FileAccess.file_exists(path): return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Dictionary or data.get("version") not in [1, 1.0, 2, 2.0] or data.get("water_completed") != true: return
	var validator := Simulation.new()
	if not validator.load_data({"version": 2, "stage": 3, "difficulty": data.get("difficulty"), "chosen": data.get("upgrades")}): return
	var residues: bool = data.get("residues_completed", false) == true
	var module: Variant = data.get("residue_upgrade", "")
	if residues and not (module is String and Loadout.is_residue_upgrade(module)): return
	var energy: bool = data.get("energy_completed", false) == true
	if energy and not residues: return
	water_completed = true
	difficulty = validator.difficulty
	upgrades = validator.chosen.duplicate()
	residues_completed = residues
	residue_upgrade = str(module) if residues else ""
	energy_completed = energy

func complete_water(level: String, chosen: Array) -> Error:
	var validator := Simulation.new()
	if not validator.load_data({"version": 2, "stage": 3, "difficulty": level, "chosen": chosen}): return ERR_INVALID_DATA
	var error := _write(level, chosen, residues_completed, residue_upgrade, energy_completed)
	if error == OK:
		water_completed = true
		difficulty = level
		upgrades = chosen.duplicate()
	return error

func complete_residues(level: String, module: String) -> Error:
	if not water_completed or not Loadout.is_residue_upgrade(module) or level not in Simulation.DIFFICULTIES: return ERR_INVALID_DATA
	var error := _write(level, upgrades, true, module, energy_completed)
	if error == OK:
		difficulty = level
		residues_completed = true
		residue_upgrade = module
	return error

func complete_energy(level: String) -> Error:
	if not residues_completed or level not in Simulation.DIFFICULTIES: return ERR_INVALID_DATA
	var error := _write(level, upgrades, true, residue_upgrade, true)
	if error == OK:
		difficulty = level
		energy_completed = true
	return error

func residue_loadout(level: String) -> Dictionary:
	return {"difficulty": level, "upgrades": upgrades.duplicate()}

## Water modules plus the module chosen after Residues.
func energy_loadout(level: String) -> Dictionary:
	var chosen := upgrades.duplicate()
	if residue_upgrade != "": chosen.append(residue_upgrade)
	return {"difficulty": level, "upgrades": chosen}

func _write(level: String, chosen: Array, residues: bool, module: String, energy: bool) -> Error:
	var data := {"version": 2, "water_completed": true, "difficulty": level, "upgrades": chosen.duplicate(),
		"residues_completed": residues, "residue_upgrade": module if residues else "", "energy_completed": energy}
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null: return FileAccess.get_open_error()
	file.store_string(JSON.stringify(data))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK: return write_error
	return DirAccess.rename_absolute(path + ".tmp", path)
