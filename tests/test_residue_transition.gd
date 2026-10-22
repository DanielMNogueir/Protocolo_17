extends SceneTree
class Shell extends "res://scripts/main.gd":
	func _draw() -> void: pass
	func _save_checkpoint() -> void: pass
	func _read_checkpoint() -> Dictionary: return {}
	func _load_settings() -> void: pass
	func _save_settings() -> void: pass

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var game := Shell.new()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.set_process(false)
	game.mode = "victory"
	game.buttons.append({"rect": Rect2(0, 0, 100, 100), "id": "residues"})
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.position = Vector2(50, 50)
	click.pressed = true
	game._unhandled_input(click)
	await process_frame
	if current_scene == null or current_scene.scene_file_path != "res://scenes/residues.tscn":
		push_error("RESIDUE_TRANSITION_FAILED: destination scene did not open")
		quit(1)
		return
	print("RESIDUE_TRANSITION_OK")
	quit(0)
