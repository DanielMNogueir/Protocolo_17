extends SceneTree
const S = preload("res://scripts/simulation.gd")
var checks := 0
var failures := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)
func run() -> void:
	var game: Node2D = load("res://scenes/residues.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.sound.set_muted(true)
	game.stage = 2
	var originals: Array = game.enemies.duplicate(true)
	for original in originals:
		var expected := S.enemy_health(original.kind, 3)
		check(original.hp == expected and original.max_hp == expected, "Real HP and maximum match the final Water sector: " + original.kind)
		for damage in [1, 2]:
			var target: Dictionary = original.duplicate(true)
			game.enemies.assign([target])
			var required := int(ceil(float(expected) / damage))
			for hit in required:
				game.bullets.append({"pos": target.pos, "vel": Vector2.ZERO, "life": 1.0, "hostile": false, "damage": damage})
				game._update_bullets(0.016)
				check(target.hp == maxi(0, expected - (hit + 1) * damage), "Pulse subtracts the real damage and never produces negative HP")
				check(target.max_hp == expected, "Taking damage never changes maximum HP")
				if hit < required - 1: check(target.hp > 0, "Enemy survives until its actual HP is exhausted")
			check(target.hp == 0, "Enemy dies on the expected pulse count with damage " + str(damage))
	game.enemies.clear()
	game._spawn_alarm_drone()
	check(game.enemies[0].hp == 11 and game.enemies[0].max_hp == 11, "Alarm drone uses the same health rule")
	var q := InputEventKey.new()
	q.pressed = true
	q.physical_keycode = KEY_Q
	game._unhandled_input(q)
	var escape := InputEventKey.new()
	escape.pressed = true
	escape.physical_keycode = KEY_ESCAPE
	game._unhandled_input(escape)
	check(game.state == "pause" and not game.secondary_requested, "Pause clears a queued burst")
	game._unhandled_input(escape)
	game._physics_process(0.016)
	check(game.secondary_cd == 0.0, "Resuming does not consume a burst")
	game.free()
	for frame in 4: await process_frame
	print("RESIDUE_HEALTH_%s: %d checks; %d failures" % ["OK" if failures == 0 else "FAILED", checks, failures])
	quit(0 if failures == 0 else 1)
