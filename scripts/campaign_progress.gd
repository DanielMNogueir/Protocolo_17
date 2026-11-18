extends RefCounted
## Permanent district access and ending history, independent of checkpoints.
const PATH := "user://aurora_campaign.json"
const Simulation = preload("res://scripts/simulation.gd")
const Loadout = preload("res://scripts/campaign_loadout.gd")
const DISTRICTS := ["water", "residues", "energy", "core"]
const ENDINGS := ["humanity", "ai"]

var path := PATH
var water_completed := false
var difficulty := "operation"
var upgrades: Array = []
var residues_completed := false
var residue_upgrade := ""
var energy_completed := false
var core_completed := false
var endings_seen: Array[String] = []
var stats: Dictionary = {}


func load_progress() -> void:
	if not FileAccess.file_exists(path): return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Dictionary or data.get("version") not in [1, 1.0, 2, 2.0, 3, 3.0] or data.get("water_completed") != true: return
	var validator := Simulation.new()
	if not validator.load_data({"version": 2, "stage": 3, "difficulty": data.get("difficulty"), "chosen": data.get("upgrades")}): return
	var residues: bool = data.get("residues_completed", false) == true
	var module: Variant = data.get("residue_upgrade", "")
	if residues and not (module is String and Loadout.is_residue_upgrade(module)): return
	var energy: bool = data.get("energy_completed", false) == true
	if energy and not residues: return

	var seen: Array[String] = []
	var records: Dictionary = {}
	var core := false
	if data.version == 3:
		var saved_core: Variant = data.get("core_completed")
		var saved_endings: Variant = data.get("endings_seen")
		var saved_stats: Variant = data.get("stats")
		if not (saved_core is bool and saved_endings is Array and saved_stats is Dictionary): return
		if (saved_core and not energy) or saved_core != (not saved_endings.is_empty()): return
		for ending in saved_endings:
			if not (ending is String and ending in ENDINGS): return
			if ending not in seen: seen.append(ending)
		for district in saved_stats:
			if district not in DISTRICTS or not _valid_stats(saved_stats[district]): return
			var record: Dictionary = saved_stats[district]
			records[district] = _record(int(record.kills), int(record.deaths), float(record.time))
		core = saved_core

	water_completed = true
	difficulty = validator.difficulty
	upgrades = validator.chosen.duplicate()
	residues_completed = residues
	residue_upgrade = str(module) if residues else ""
	energy_completed = energy
	core_completed = core
	endings_seen = seen
	stats = records


func complete_water(level: String, chosen: Array, record: Dictionary = {}) -> Error:
	var validator := Simulation.new()
	if not validator.load_data({"version": 2, "stage": 3, "difficulty": level, "chosen": chosen}): return ERR_INVALID_DATA
	return _complete("water", record, {"difficulty": level, "upgrades": chosen})


func complete_residues(level: String, module: String, record: Dictionary = {}) -> Error:
	if not water_completed or not Loadout.is_residue_upgrade(module) or level not in Simulation.DIFFICULTIES: return ERR_INVALID_DATA
	return _complete("residues", record, {"difficulty": level, "residues_completed": true, "residue_upgrade": module})


func complete_energy(level: String, record: Dictionary = {}) -> Error:
	if not residues_completed or level not in Simulation.DIFFICULTIES: return ERR_INVALID_DATA
	return _complete("energy", record, {"difficulty": level, "energy_completed": true})


func complete_core(level: String, ending: String, record: Dictionary = {}) -> Error:
	if not energy_completed or level not in Simulation.DIFFICULTIES or ending not in ENDINGS: return ERR_INVALID_DATA
	var seen := endings_seen.duplicate()
	if ending not in seen: seen.append(ending)
	return _complete("core", record, {"difficulty": level, "core_completed": true, "endings_seen": seen})


func record_stats(district: String, kills: int, deaths: int, time: float) -> Error:
	if not water_completed or district not in DISTRICTS: return ERR_INVALID_DATA
	return _complete(district, _record(kills, deaths, time), {})


func campaign_totals() -> Dictionary:
	var totals := _record(0, 0, 0.0)
	for record: Dictionary in stats.values():
		for key in totals:
			totals[key] += record[key]
	return totals


func residue_loadout(level: String) -> Dictionary:
	return {"difficulty": level, "upgrades": upgrades.duplicate()}


func energy_loadout(level: String) -> Dictionary:
	var chosen := upgrades.duplicate()
	if residue_upgrade != "": chosen.append(residue_upgrade)
	return {"difficulty": level, "upgrades": chosen}


func core_loadout(level: String) -> Dictionary:
	return energy_loadout(level)


static func _record(kills: int, deaths: int, time: float) -> Dictionary:
	return {"kills": kills, "deaths": deaths, "time": time}


static func _valid_stats(record: Variant) -> bool:
	if not record is Dictionary:
		return false
	for key in ["kills", "deaths", "time"]:
		var value: Variant = record.get(key)
		if not (value is float or value is int) or not is_finite(float(value)) or value < 0:
			return false
		if key != "time" and (value != floorf(float(value)) or value >= float(9223372036854775807)):
			return false
	return true


func _complete(district: String, record: Dictionary, changes: Dictionary) -> Error:
	var records := stats.duplicate(true)
	if not record.is_empty():
		if not _valid_stats(record): return ERR_INVALID_DATA
		records[district] = _record(int(record.kills), int(record.deaths), float(record.time))
	var data := {"version": 3, "water_completed": true, "difficulty": difficulty, "upgrades": upgrades,
		"residues_completed": residues_completed, "residue_upgrade": residue_upgrade, "energy_completed": energy_completed,
		"core_completed": core_completed, "endings_seen": endings_seen, "stats": records}
	data.merge(changes, true)
	var error := _write(data)
	if error != OK: return error
	water_completed = true
	difficulty = data.difficulty
	upgrades = data.upgrades.duplicate()
	residues_completed = data.residues_completed
	residue_upgrade = data.residue_upgrade
	energy_completed = data.energy_completed
	core_completed = data.core_completed
	endings_seen = data.endings_seen.duplicate()
	stats = records
	return OK


func _write(data: Dictionary) -> Error:
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null: return FileAccess.get_open_error()
	file.store_string(JSON.stringify(data, "", true, true))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK: return write_error
	return DirAccess.rename_absolute(path + ".tmp", path)
