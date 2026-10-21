extends SceneTree
class Shell extends "res://scripts/main.gd":
	func _save_checkpoint() -> void: pass
	func _read_checkpoint() -> Dictionary: return {}
	func _load_settings() -> void: pass
	func _save_settings() -> void: pass
var checks:=0
var failures:=0
func _initialize() -> void: _run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		push_error(message)
func key(game: Shell, code: Key, pressed: bool=true) -> void:
	var event:=InputEventKey.new()
	event.physical_keycode=code
	event.pressed=pressed
	game._unhandled_input(event)
func _run() -> void:
	var game:=Shell.new()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.sound.set_muted(true)
	game.sim.start(1)
	game.sim.enemies.clear()
	game.sim.state="activation"
	game.sim.pos=game.sim.operation.target()
	game.sim.operation.clock=0.90
	game.mode="play"
	key(game,KEY_E)
	key(game,KEY_E,false)
	check(game.interact_requested,"Brief E press is latched between frames")
	game._process(1.0/60)
	check(game.sim.operation.completed==1 and game.sim.wave==1,"Brief E press actually completes synchronization")
	game.sim.start()
	game.dialogue=["COMANDO","Sinal"]
	key(game,KEY_Q)
	key(game,KEY_SHIFT)
	check(not game.secondary_requested and not game.dash_requested,"Dialogue does not queue attacks or dashes")
	var mouse:=InputEventMouseButton.new()
	mouse.button_index=MOUSE_BUTTON_RIGHT
	mouse.pressed=true
	game._unhandled_input(mouse)
	check(not game.secondary_requested,"Right click during dialogue does not fire later")
	game.dialogue.clear()
	key(game,KEY_Q)
	check(game.secondary_requested,"Q is available in active combat")
	key(game,KEY_ESCAPE)
	check(game.mode=="pause" and not game.secondary_requested,"Pause discards queued attack")
	game._action("resume")
	game._process(1.0/60)
	check(game.sim.secondary_shots==0,"Resuming does not fire stale input")
	key(game,KEY_E)
	key(game,KEY_M)
	check(game.mode=="map" and not game.interact_requested,"Map discards queued interaction")
	game._action("title")
	game._action("new")
	key(game,KEY_3)
	game._action("intro_skip")
	check(game.sim.difficulty=="veteran" and game.sim.max_hp==5,"Difficulty keyboard selection and intro preserve hard mode")
	game.free()
	game=null
	for frame in 5: await process_frame
	print("BETA_INPUT_%s: %d checks; %d failures" % ["OK" if failures==0 else "FAILED",checks,failures])
	quit(0 if failures==0 else 1)
