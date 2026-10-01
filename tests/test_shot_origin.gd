extends SceneTree
## The projectile path must begin at the emitter in every authored Lia pose.
const Simulation = preload("res://scripts/simulation.gd")
const LiaPose = preload("res://scripts/lia_directional.gd")
const World = preload("res://scripts/world.gd")
const DT := 1.0 / 240.0
var checks := 0
var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)


func _run() -> void:
	var sim = Simulation.new()
	for direction in 24:
		var aim := Vector2.from_angle(deg_to_rad(direction * 15.0))
		for moving in [false, true]:
			var frames := 8 if moving else 2
			for frame in frames:
				var phase := (frame + 0.01) / LiaPose.WALK_FPS if moving else (0.0 if frame == 0 else 3.9)
				sim.start()
				sim.pos = Vector2(800, 1420)
				var enemy: Dictionary = sim.enemies[0]
				sim.enemies.clear()
				enemy.pos = Vector2(10000, 10000)
				enemy.phase = "windup"
				enemy.warning = 999.0
				enemy.cooldown = 999.0
				sim.enemies.append(enemy)
				var target: Vector2 = sim.pos + aim * 250.0
				var muzzle: Vector2 = sim.pos + LiaPose.pose(aim, phase, moving).muzzle
				sim.tick(DT, Vector2.ZERO, target, true, false, false, phase, moving)
				var label := "%d degrees, %s frame %d" % [direction * 15, "walk" if moving else "idle", frame]
				_check(sim.bullets.size() == 1, "Pulse survives its first step: " + label)
				if sim.bullets.size() != 1:
					continue
				var bullet: Dictionary = sim.bullets[0]
				_check(Vector2(bullet.source).distance_to(muzzle) < 0.01, "Pulse starts at the sprite emitter: " + label)
				_check(Vector2(bullet.vel).normalized().dot((target - muzzle).normalized()) > 0.9999, "Pulse travels toward the cursor: " + label)
				_check(Vector2(bullet.pos).distance_to(muzzle + Vector2(bullet.vel) * DT) < 0.01, "Pulse advances from emitter: " + label)

	# Use the pump's physical base, not the now-walkable upper sprite rectangle.
	sim.start()
	var pump: Rect2 = World.props()[2].collision_rect
	var left_muzzle: Vector2 = LiaPose.pose(Vector2.LEFT,0,false).muzzle
	sim.pos = Vector2(pump.end.x+15,pump.get_center().y-left_muzzle.y)
	var enemy: Dictionary = sim.enemies[0]
	sim.enemies.clear()
	enemy.pos = Vector2(10000, 10000)
	enemy.phase = "windup"
	enemy.warning = 999.0
	enemy.cooldown = 999.0
	sim.enemies.append(enemy)
	_check(World.walkable(sim.pos, Simulation.PLAYER_RADIUS, 0), "Wall fixture keeps Lia on walkable ground")
	_check(sim._wall_fraction(sim.pos,sim.pos+left_muzzle,3)!=INF,"Wall fixture places the emitter through the physical pump base")
	sim.tick(DT, Vector2.ZERO, sim.pos + Vector2.LEFT * 200, true, false, false)
	_check(sim.shots == 1 and sim.bullets.is_empty(), "A barrel beyond a wall cannot fire through it")

	print("SHOT_ORIGIN_TEST_%s: %d checks; %d failures" % ["OK" if failures == 0 else "FAILED", checks, failures])
	quit(0 if failures == 0 else 1)
