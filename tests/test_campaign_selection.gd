extends SceneTree
const Progress = preload("res://scripts/campaign_progress.gd")
const TEST_PATH := "user://campaign_selection_test.json"
const CHOSEN := ["reserve_cell", "induction_coil", "water_stride"]
var checks := 0
var failures := 0

class Shell extends "res://scripts/main.gd":
	var checkpoint: Dictionary = {}
	var opened: Dictionary = {}
	var checkpoint_cleared := false
	func _save_checkpoint() -> void: checkpoint = sim.save_data()
	func _read_checkpoint() -> Dictionary: return checkpoint
	func _clear_checkpoint() -> void:
		checkpoint_cleared = true
		checkpoint = {}
	func _load_settings() -> void: pass
	func _save_settings() -> void: pass
	func _open_residues(level: String) -> void: opened = campaign.residue_loadout(level)

func _initialize() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)
func shell() -> Shell:
	var game := Shell.new()
	game.campaign.path = TEST_PATH
	root.add_child(game)
	game.set_process(false)
	game.sound.set_muted(true)
	return game
func key(game: Shell, code: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	game._unhandled_input(event)

func run() -> void:
	if FileAccess.file_exists(TEST_PATH): DirAccess.remove_absolute(TEST_PATH)
	var game := shell()
	check(not game.campaign.water_completed, "New profile starts with Residues locked")
	game._action("new")
	check(game.mode == "districts", "New operation opens the district selector")
	key(game, KEY_2)
	check(game.mode == "districts" and game.selected_district == "water", "Locked district cannot be selected by keyboard")
	game._action("residues")
	check(game.opened.is_empty(), "Direct start action cannot bypass locked district")
	key(game, KEY_1)
	check(game.mode == "difficulty" and game.selected_district == "water", "Water is selectable before any victory")
	key(game, KEY_ESCAPE)
	check(game.mode == "districts", "Difficulty returns to district selection")
	game._action("district_water")
	game._action("difficulty_veteran")
	game._action("intro_skip")
	check(game.mode == "play" and game.sim.difficulty == "veteran", "Water keeps the existing difficulty and prologue flow")
	check(not game.campaign.water_completed, "Starting or skipping the prologue does not unlock Residues")
	check(game.sim.load_data({"version": 2, "stage": 3, "chosen": CHOSEN.duplicate(), "difficulty": "veteran"}), "Prepare the final Water loadout")
	game.sim.state = "victory"
	game._state_changed()
	check(game.campaign.water_completed and FileAccess.file_exists(TEST_PATH), "Water victory writes permanent access to disk")
	check(game.checkpoint_cleared, "Water checkpoint is cleared after a successful unlock save")
	game.free()
	game = shell()
	check(game.campaign.water_completed, "District stays unlocked after recreating the game")
	check(game.campaign.upgrades == CHOSEN and game.campaign.difficulty == "veteran", "Completed Water equipment survives restart")
	game._action("new")
	key(game, KEY_2)
	check(game.mode == "difficulty" and game.selected_district == "residues", "Unlocked Residues can be selected directly")
	key(game, KEY_1)
	check(game.opened.get("difficulty") == "story" and game.opened.get("upgrades") == CHOSEN, "Residues accepts its selected difficulty and saved Water upgrades")
	game._action("new")
	game._action("district_water")
	game._action("difficulty_operation")
	game._action("intro_skip")
	var reloaded := Progress.new()
	reloaded.path = TEST_PATH
	reloaded.load_progress()
	check(reloaded.water_completed and reloaded.upgrades == CHOSEN, "Replaying Water does not erase access or equipment")
	game.campaign.path = "user://missing_campaign_test_directory/progress.json"
	game.checkpoint_cleared = false
	game.sim.load_data({"version": 2, "stage": 3, "chosen": CHOSEN.duplicate(), "difficulty": "operation"})
	game.sim.state = "victory"
	game._state_changed()
	check(not game.checkpoint_cleared, "A failed permanent save preserves the Water checkpoint")
	game.free()
	var corrupt := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	corrupt.store_string('{"version":1,"water_completed":true,"difficulty":"operation","upgrades":["unknown"]}')
	corrupt.close()
	var rejected := Progress.new()
	rejected.path = TEST_PATH
	rejected.load_progress()
	check(not rejected.water_completed, "Corrupt campaign data cannot unlock a district with an invalid loadout")
	DirAccess.remove_absolute(TEST_PATH)
	for frame in 4: await process_frame
	print("CAMPAIGN_SELECTION_%s: %d checks; %d failures" % ["OK" if failures == 0 else "FAILED", checks, failures])
	quit(0 if failures == 0 else 1)
