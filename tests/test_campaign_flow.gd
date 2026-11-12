extends SceneTree
## Whole campaign hand-off on a throwaway save: Water victory unlocks Residues;
## Residues victory offers the three Energy modules and opens the Energy
## district with Water modules + the chosen one; Energy victory is saved; the
## district selector then reopens Energy with the same loadout, keeps Energy
## locked on a fresh profile, and shows the Núcleo card as in production.
const Progress = preload("res://scripts/campaign_progress.gd")
const Loadout = preload("res://scripts/campaign_loadout.gd")
const TEST_PATH := "user://campaign_flow_test.json"
const WATER := ["reserve_cell", "induction_coil", "water_stride"]
var checks := 0
var failures := 0

class Shell extends "res://scripts/main.gd":
	var opened_power: Dictionary = {}
	var opened_residues: Dictionary = {}
	func _save_checkpoint() -> void: pass
	func _read_checkpoint() -> Dictionary: return {}
	func _clear_checkpoint() -> void: pass
	func _load_settings() -> void: pass
	func _save_settings() -> void: pass
	func _open_residues(level: String) -> void: opened_residues = campaign.residue_loadout(level)
	func _open_power(level: String) -> void: opened_power = campaign.energy_loadout(level)

func _initialize() -> void: _run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("CAMPAIGN_FLOW_FAILED: " + label)

func shell() -> Shell:
	var game := Shell.new()
	game.campaign.path = TEST_PATH
	root.add_child(game)
	game.set_process(false)
	game.sound.set_muted(true)
	return game

func key(target: Node, code: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	target._unhandled_input(event)

func _run() -> void:
	if FileAccess.file_exists(TEST_PATH): DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
	# Fresh profile: Energy is locked and cannot be forced open.
	var menu := shell()
	menu._action("new")
	key(menu, KEY_3)
	check(menu.mode == "districts", "Energy locked on a fresh profile (key 3)")
	menu._action("district_energy")
	check(menu.mode == "districts" and menu.opened_power.is_empty(), "Energy locked on a fresh profile (direct action)")
	# Water victory.
	menu.sim.load_data({"version": 2, "stage": 3, "chosen": WATER.duplicate(), "difficulty": "veteran"})
	menu.sim.state = "victory"
	menu._state_changed()
	check(menu.campaign.water_completed and not menu.campaign.residues_completed, "Water victory unlocks Residues only")
	menu.free()
	# Residues: victory → module screen → Energy.
	set_meta("p17_residue_handoff", {"difficulty": "veteran", "upgrades": WATER.duplicate()})
	var residues: Node2D = load("res://scenes/residues.tscn").instantiate()
	residues.campaign.path = TEST_PATH
	root.add_child(residues)
	current_scene = residues
	residues.set_physics_process(false)
	await process_frame
	check(residues.campaign.water_completed and residues.difficulty == "veteran", "Residues reads the saved Water campaign")
	residues.state = "victory"
	key(residues, KEY_R)
	check(residues.state == "victory", "R no longer restarts a won Residues district")
	key(residues, KEY_ENTER)
	check(residues.state == "upgrade", "Enter on victory opens the module workshop")
	residues._hud.queue_redraw()
	await process_frame
	var module_buttons := 0
	for button in residues.buttons:
		if str(button.id).begins_with("module_"): module_buttons += 1
	check(module_buttons == 3, "Workshop shows three clickable modules")
	key(residues, KEY_2)
	await process_frame
	await process_frame
	var power: Node = current_scene
	check(power != null and power.scene_file_path == "res://scenes/power.tscn", "Choosing a module opens the Energy district")
	var saved := Progress.new()
	saved.path = TEST_PATH
	saved.load_progress()
	check(saved.residues_completed and saved.residue_upgrade == "steady_hand" and not saved.energy_completed, "Residues victory and module are saved")
	if power != null and power.scene_file_path == "res://scenes/power.tscn":
		check(power.difficulty == "veteran" and power.upgrades == WATER + ["steady_hand"], "Energy receives Water modules + the new one")
		check(power.max_hp == Loadout.base_health("veteran") + 2 and power.pulse_damage == 2, "Water modules still apply in Energy")
		check(is_equal_approx(power.loadout.timing_scale, 1.3), "Residue module applies in Energy")
		check(not power.get_tree().has_meta("p17_residue_handoff"), "Residues hand-off is consumed")
		# Win Energy on the test profile.
		power.set_physics_process(false)
		power.campaign = Progress.new()
		power.campaign.path = TEST_PATH
		power.campaign.load_progress()
		power.stage = 3
		power._start_dialogue(power.Story.ELEVATOR, "victory")
		power._finish_dialogue()
		check(power.state == "victory" and power.victory_notice.ends_with("PROGRESSO SALVO"), "Energy victory saved")
		power.queue_free()
	if has_meta("p17_power_handoff"): remove_meta("p17_power_handoff")
	await process_frame
	saved = Progress.new()
	saved.path = TEST_PATH
	saved.load_progress()
	check(saved.energy_completed and saved.residues_completed and saved.upgrades == WATER, "Full campaign survives reload")
	# District selector after the campaign.
	menu = shell()
	check(menu.campaign.energy_completed, "Menu sees the completed Energy district")
	menu._action("new")
	key(menu, KEY_3)
	check(menu.mode == "difficulty" and menu.selected_district == "energy", "Energy selectable after Residues")
	key(menu, KEY_2)
	check(menu.opened_power.get("difficulty") == "operation" and menu.opened_power.get("upgrades") == WATER + ["steady_hand"], "Energy replays with the saved modules at the chosen difficulty")
	menu.mode = "districts"
	menu.queue_redraw()
	await process_frame
	menu.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
	for frame in 4: await process_frame
	print("CAMPAIGN_FLOW_%s: %d checks; %d failures" % ["OK" if failures == 0 else "FAILED", checks, failures])
	quit(0 if failures == 0 else 1)
