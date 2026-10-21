extends SceneTree
var failures := 0
var checks := 0
func _initialize() -> void: _run.call_deferred()
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		push_error(label)
func _run() -> void:
	print("BETA_USER_DATA=",OS.get_user_data_dir())
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.sound.set_muted(true)
	var prior_file := ""
	var existed := FileAccess.file_exists(game.SAVE_PATH)
	if existed: prior_file=FileAccess.get_file_as_string(game.SAVE_PATH)
	check(game.sim.load_data({"version":2,"stage":1,"chosen":["reserve_cell"],"difficulty":"veteran","elapsed":123.5,"kills":10}),"Prepare valid checkpoint")
	game._save_checkpoint()
	check(game.has_save and FileAccess.file_exists(game.SAVE_PATH),"Checkpoint file is actually written and atomically renamed")
	var loaded: Dictionary=game._read_checkpoint()
	check(loaded.get("difficulty","")=="veteran" and loaded.get("elapsed",0)==123.5,"Read actual disk checkpoint with difficulty and time")
	game._action("continue")
	check(game.mode=="play" and game.sim.hp==7 and game.sim.chosen==["reserve_cell"],"Continue reconstructs permanent upgrades and difficulty")
	var file=FileAccess.open(game.SAVE_PATH,FileAccess.WRITE)
	if file!=null:
		file.store_string('{"version":2,"stage":9,"chosen":[]}')
		file.close()
	check(game._read_checkpoint().is_empty(),"Corrupted disk checkpoint does not appear as resumable")
	if existed:
		file=FileAccess.open(game.SAVE_PATH,FileAccess.WRITE)
		if file!=null: file.store_string(prior_file)
	else: game._clear_checkpoint()
	game.free()
	for frame in 4: await process_frame
	print("BETA_STORAGE_%s: %d checks; %d failures" % ["OK" if failures==0 else "FAILED",checks,failures])
	quit(0 if failures==0 else 1)
