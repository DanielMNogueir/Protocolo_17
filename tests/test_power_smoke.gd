extends SceneTree
## Loads the Energy district with physics running for a few seconds of real
## frames (dialogue, then play) so every draw and tick path executes once.

func _initialize() -> void: _run.call_deferred()

func _run() -> void:
	var game: Node2D = load("res://scenes/power.tscn").instantiate()
	root.add_child(game)
	for frame in 20: await physics_frame
	var ok: bool = game.state == "dialogue"
	game._finish_dialogue()
	for frame in 90: await physics_frame
	game.state = "map"
	for frame in 4: await process_frame
	game.state = "pause"
	for frame in 4: await process_frame
	game.stage = 2
	game.state = "play"
	game.pos = game.M.w(game.M.RING_CENTER)
	for frame in 60: await physics_frame
	ok = ok and game.battery.started
	game.state = "victory"
	for frame in 4: await process_frame
	print("POWER_SMOKE_", "OK" if ok else "FAILED")
	game.queue_free()
	for frame in 3: await process_frame
	quit(0 if ok else 1)
