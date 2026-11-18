extends SceneTree

const Progress = preload("res://scripts/campaign_progress.gd")
const PATH := "user://test_campaign_save_v3.json"
var failures := 0


func check(condition: bool, label: String) -> void:
	if not condition:
		push_error(label)
		failures += 1


func _initialize() -> void:
	var progress := Progress.new()
	progress.path = PATH
	var old := {"version": 2, "water_completed": true, "difficulty": "story", "upgrades": ["reserve_cell", "induction_coil", "water_stride"],
		"residues_completed": true, "residue_upgrade": "steady_hand", "energy_completed": true}
	_write(old)
	progress.load_progress()
	check(progress.energy_completed and not progress.core_completed and progress.endings_seen.is_empty(), "Load v2 without final progress")
	check(progress.record_stats("water", 21, 1, 125.5) == OK, "Record Water")
	check(progress.complete_core("story", "humanity", {"kills": 4, "deaths": 2, "time": 44.5}) == OK, "Record humanity and stats together")
	check(progress.complete_core("story", "humanity") == OK, "Replaying an ending is valid")
	check(progress.complete_core("story", "ai") == OK, "Record second ending")
	check(progress.complete_core("story", "unknown") == ERR_INVALID_DATA, "Reject unknown ending")
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	check(data.version == 3, "Write v3")
	var reloaded := Progress.new()
	reloaded.path = PATH
	reloaded.load_progress()
	check(reloaded.core_completed and reloaded.endings_seen == ["humanity", "ai"], "Reload both endings without duplicates")
	check(reloaded.campaign_totals() == {"kills": 25, "deaths": 3, "time": 170.0}, "Aggregate district stats")
	data.endings_seen.append("unknown")
	_write(data)
	var rejected := Progress.new()
	rejected.path = PATH
	rejected.load_progress()
	check(not rejected.water_completed, "Reject a corrupt v3 transaction")
	check(rejected.complete_core("story", "ai") == ERR_INVALID_DATA, "A fresh profile cannot record a Core ending")
	DirAccess.remove_absolute(PATH)
	print("CAMPAIGN_SAVE_V3_OK" if failures == 0 else "CAMPAIGN_SAVE_V3_FAILED")
	quit(0 if failures == 0 else 1)


func _write(data: Dictionary) -> void:
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()
