extends SceneTree
const World = preload("res://scripts/world.gd")
const Core = preload("res://scripts/core_map.gd")
const Simulation = preload("res://scripts/simulation.gd")
var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _initialize() -> void:
	# The front of the building, tank and clarifier used to allow an actor's feet
	# well into the visible base. Test those spots independently of the profile.
	var building_rect: Rect2 = World.building_objects()[0].visual_bounds
	var tank_rect: Rect2 = World.props()[0].visual_bounds
	var clarifier_rect: Rect2 = World.clarifier().visual_bounds
	for entry in [[building_rect, 0.50], [tank_rect, 0.72], [clarifier_rect, 0.36]]:
		var visual: Rect2 = entry[0]
		var point := visual.position + visual.size * Vector2(0.5, entry[1])
		check(not World.walkable(point, 14.0, 3), "The visible ground footprint is solid at %s" % point)
	check(World.walkable(Vector2(300, 250), 14.0, 3), "Roof overhang leaves room to walk behind the building")
	for radius in [14.0, 18.0, 25.0]:
		check(not World.walkable(Vector2(652, 352), radius, 1), "Water control-room side is solid for every actor")
		var sim := Simulation.new()
		sim.start(1)
		var at := Vector2(610, 350)
		for step in 60:
			at = sim._slide(at, Vector2(4, 0), radius)
		check(at.x < 640.0, "Actor cannot cross the side of the Water station")
		for phase in [1, 2, 3, 4]:
			var base := Core.pillars()[2]
			check(not Core.walkable(base + Vector2(0, 44), radius, phase), "Pillar platform stays solid throughout the fight")
			at = base + Vector2(110, 0)
			for step in 60:
				at = Core.slide(at, Vector2(-4, 0), radius, phase)
			check(at.x > base.x + 35.0, "Actor slides around the pillar base")
	print("STRUCTURE_FOOTPRINTS_OK" if failures == 0 else "STRUCTURE_FOOTPRINTS_FAILED")
	quit(0 if failures == 0 else 1)
