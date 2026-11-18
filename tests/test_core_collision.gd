extends SceneTree

const Map = preload("res://scripts/core_map.gd")
var failures := 0

func check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		push_error(label)

func _initialize() -> void:
	var map := Map.new()
	check(not map.route(Map.GALLERY_START, Map.TERMINAL, 0).is_empty(), "Gallery terminal reachable")
	check(not map.route(Map.TERMINAL, Map.STAIRS.get_center(), 0).is_empty(), "Gallery stairs reachable across the cradle")
	for phase in range(1, 5):
		var targets: Array = [Map.pillars(), Map.mirrors(), [Map.OVERLOOK], Map.CONSOLES][phase - 1]
		for target: Vector2 in targets:
			check(((target - Map.CENTER) / Map.RADII).length() < 1.0, "Target sits on the platform")
			var route := map.route(Map.ARRIVAL, target, phase)
			check(not route.is_empty() and route[-1].distance_to(target) <= 80.0, "Interaction reachable from the stairs")
		var player := Map.ARRIVAL
		var rng := RandomNumberGenerator.new()
		rng.seed = 17
		for i in 2000:
			player = Map.slide(player, Vector2.from_angle(rng.randf_range(0, TAU)) * 38.0, 14.0, phase)
			check(Map.walkable(player, 14.0, phase), "Cannot slide out of the ring")
		for spawn in Map.spawns():
			check(Map.walkable(spawn, 16.0, phase), "Spark spawn fits within the arena")
			var drone := spawn
			for tick in 300:
				var next := map.waypoint(drone, Map.ARRIVAL, phase, 16.0)
				drone = Map.slide(drone, drone.direction_to(next) * 6.0, 16.0, phase)
				if drone.distance_to(Map.ARRIVAL) < 76.0: break
			check(drone.distance_to(Map.ARRIVAL) < 76.0, "Spark routes around the fixtures")
	print("CORE_COLLISION_OK" if failures == 0 else "CORE_COLLISION_FAILED")
	quit(0 if failures == 0 else 1)
