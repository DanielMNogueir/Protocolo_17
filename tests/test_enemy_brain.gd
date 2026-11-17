extends SceneTree

const Brain = preload("res://scripts/enemy_brain.gd")
const Simulation = preload("res://scripts/simulation.gd")
var failures := 0

func _initialize() -> void:
	var squad := Brain.new()
	var player := Vector2(280, 400)
	var drone := Brain.Unit.new(Vector2(210, 450), 17)
	_check(not drone.sense(0.1, player, false) and drone.mode == "patrol", "Hidden Lia does not interrupt patrol")
	_check(drone.sense(0.01, player, true) and drone.mode == "alert", "Seeing Lia triggers a shared alert")
	drone.sense(0.39, player, true)
	_check(drone.mode == "alert", "The first reaction remains visible")
	drone.sense(0.02, player, true)
	_check(drone.mode == "combat", "Alert leads to combat")
	drone.sense(0.1, player + Vector2(300, 0), false)
	_check(drone.mode == "search" and drone.last_seen == player, "Losing sight keeps the last observed position")
	drone.sense(4.1, player, false)
	_check(drone.mode == "patrol", "Search eventually ends")
	_check(drone.damaged(0.25, player) and drone.retreat == 1.5, "Low integrity triggers retreat and alarm")
	_check(not drone.damaged(0.2, player), "The same retreat does not restart on every hit")

	for level in ["story", "operation", "veteran"]:
		var count: int = Brain.TOKENS[level]
		for id in count:
			_check(squad.acquire(id, level), "Allocate an available firing token")
		_check(not squad.acquire(count, level), "Difficulty caps simultaneous firing")
		squad.release(0)
		_check(squad.acquire(count, level), "A released token goes to the waiting drone")
		squad.clear()

	var open := func(_point: Vector2) -> bool: return true
	var clear := func(_a: Vector2, _b: Vector2) -> bool: return true
	var no_cover := func(_point: Vector2) -> bool: return false
	var slots: Array[Vector2] = []
	for i in 8:
		var slot := squad.flank(i, "scout", Vector2.ZERO, player, 170.0, open, clear, no_cover)
		_check(slot.is_finite() and slot not in slots, "Drones reserve unique positions")
		slots.append(slot)
	_check(not squad.flank(8, "scout", Vector2.ZERO, player, 170.0, open, clear, no_cover).is_finite(), "A full ring does not duplicate a slot")

	var movement := Vector2.DOWN * 200.0
	_check(Brain.aim(Vector2.ZERO, Vector2.RIGHT * 200, movement, 300.0, "story") == Vector2.RIGHT, "Story aim has zero lead")
	_check(Brain.aim(Vector2.ZERO, Vector2.RIGHT * 200, movement, 300.0, "veteran").y > 0.0, "Veteran aim leads a moving target")
	var shot := {"pos": Vector2(-150, 0), "vel": Vector2.RIGHT * 530.0, "secondary": true}
	_check(drone.dodge_course(0.01, "operation", Vector2.ZERO, [shot], open).is_zero_approx(), "Dodge starts with reaction delay")
	_check(not drone.dodge_course(0.21, "operation", Vector2.ZERO, [shot], open).is_zero_approx(), "Charged shot triggers lateral dodge")
	drone.dodge_course(0.26, "operation", Vector2.ZERO, [shot], open)
	_check(drone.dodge_course(0.01, "operation", Vector2.ZERO, [shot], open).is_zero_approx(), "Dodge cooldown prevents repeated moves")

	var sim := Simulation.new()
	sim.start()
	sim.pos = Vector2(740, 1450)
	sim.enemies.resize(2)
	sim.enemies[0].pos = Vector2(900, 1450)
	sim.enemies[1].pos = Vector2(955, 1450)
	sim._damage_enemy(0, 1)
	_check(sim.enemies[0].mind.mode == "alert" and sim.enemies[1].mind.mode == "alert", "A hit alerts allies across clear ground")
	sim.enemies[1].mind.stunned = 1.2
	var hp: int = sim.enemies[1].hp
	sim._damage_enemy(1, 1)
	_check(sim.enemies[1].hp == hp - 2, "An immobilized drone receives double damage")

	print("ENEMY_BRAIN_OK" if failures == 0 else "ENEMY_BRAIN_FAILED")
	quit(0 if failures == 0 else 1)


func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		push_error(label)
