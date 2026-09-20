extends SceneTree
const LiaClock = preload("res://scripts/lia_animation.gd")
var checks: int = 0
var failures: Array[String] = []


class SilentSound extends Node:
	func set_mood(_mood: String) -> void:
		pass

	func set_muted(_muted: bool) -> void:
		pass

	func play_sfx(_event: String) -> void:
		pass


class GameHarness extends "res://scripts/main.gd":
	var held: Array[Key] = []

	func _ready() -> void:
		# Exercise the actual update loop without opening audio or settings resources.
		sound = SilentSound.new()
		add_child(sound)

	func _key(code: Key) -> bool:
		return held.has(code)

	func _save_checkpoint() -> void:
		pass # Tests must not replace the player's saved operation.

func _initialize() -> void:
	_run.call_deferred()


func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)


func _run() -> void:
	var animation := LiaClock.new()
	animation.advance(0.3, Vector2(5.0, 0.0), false)
	check(not animation.moving and is_equal_approx(animation.elapsed, 0.3), "At the movement threshold, idle time advances normally")
	animation.advance(0.05, Vector2(5.1, 0.0), false)
	check(animation.moving and animation.elapsed == 0.0, "First moving frame starts at gait phase zero")
	animation.advance(0.2, Vector2(120.0, 0.0), false)
	animation.advance(0.1, Vector2(0.0, -180.0), false)
	check(is_equal_approx(animation.elapsed, 0.3), "Turning and changing speed preserve accumulated gait phase")
	animation.advance(0.05, Vector2.ZERO, true)
	check(animation.moving and is_equal_approx(animation.elapsed, 0.35), "A dash preserves movement phase even with zero reported velocity")
	animation.advance(0.05, Vector2.ZERO, false)
	check(not animation.moving and animation.elapsed == 0.0, "Stopping restarts idle at its first frame")
	animation.advance(0.2, Vector2.ZERO, false)
	check(is_equal_approx(animation.elapsed, 0.2), "Idle breathing advances from its own fresh time origin")

	var game: GameHarness = GameHarness.new()
	game.set_process(false)
	game.visible = false
	root.add_child(game)
	game.sound.set_muted(true)
	game._start_new_run()
	game._process(0.05)
	game._process(0.05)
	check(is_equal_approx(game.lia_animation.elapsed, 0.1), "Actual play branch advances Lia's idle clock")
	game.held = [KEY_D]
	game._process(0.05)
	check(game.lia_animation.moving and game.lia_animation.elapsed == 0.0, "Actual movement input starts the gait at frame zero")
	game._process(0.05)
	game.held = [KEY_W]
	game._process(0.05)
	check(is_equal_approx(game.lia_animation.elapsed, 0.1), "Direction change through the real game loop preserves walking phase")
	for mode in ["pause", "map", "upgrade", "defeat", "victory", "title", "settings", "briefing"]:
		game.mode = mode
		var pose_time: float = game.lia_animation.elapsed
		var simulation_time: float = game.sim.elapsed
		var global_time: float = game.clock
		game._process(0.05)
		check(game.lia_animation.elapsed == pose_time and game.sim.elapsed == simulation_time and game.clock > global_time,
			"Mode %s freezes Lia and simulation while presentation time continues" % mode)
	game.mode = "play"
	game.dialogue = ["LIA", "Relógio de teste."]
	var paused_time: float = game.lia_animation.elapsed
	var paused_simulation: float = game.sim.elapsed
	game._process(0.05)
	check(game.lia_animation.elapsed == paused_time and game.sim.elapsed == paused_simulation, "A field conversation freezes Lia's current phase")
	game.dialogue.clear()
	game._process(0.05)
	check(is_equal_approx(game.lia_animation.elapsed, paused_time + 0.05), "Resuming continues from the frozen phase without catching up elapsed menu time")
	game.held.clear()
	for frame in 20:
		game._process(0.01)
		if not game.lia_animation.moving:
			break
	check(not game.lia_animation.moving and game.lia_animation.elapsed == 0.0, "Actual braking reaches idle with a fresh phase")
	game._process(0.05)
	check(is_equal_approx(game.lia_animation.elapsed, 0.05), "Idle phase advances after the real stop transition")
	game._start_new_run()
	check(game.lia_animation.elapsed == 0.0 and not game.lia_animation.moving, "Starting a new operation resets only the pose clock alongside the new simulation")
	game.queue_free()
	await process_frame
	print("LIA_ANIMATION_TEST_%s: %d checks, %d failures" % ["OK" if failures.is_empty() else "FAILED", checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
