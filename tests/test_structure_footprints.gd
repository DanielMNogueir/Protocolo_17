extends SceneTree
const World = preload("res://scripts/world.gd")
const Core = preload("res://scripts/core_map.gd")
const Simulation = preload("res://scripts/simulation.gd")
const Occlusion = preload("res://scripts/occlusion.gd")
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
	check(not World.walkable(Vector2(300, 250), 14.0, 3), "Nobody walks behind the control room roof")
	_check_no_actor_inside_structures()
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

## Every tall Water structure is solid over its whole drawn body: wherever Lia
## or a drone can stand, its sprite never sits behind or inside the art (it may
## only stand in front of it). Bridge railings are low rails, not structures.
func _check_no_actor_inside_structures() -> void:
	var view := Rect2(Vector2.ZERO, World.SIZE)
	var structures: Array[Dictionary] = []
	for object in World.sortable_objects(view):
		var bounds: Rect2 = World.sortable_bounds(object)
		if str(object.type) == "bridge_part" or bounds.size.y < Occlusion.MIN_COVER_HEIGHT: continue
		structures.append({"bounds": bounds, "y": float(object.y)})
	for i in 3:
		structures.append({"bounds": World.station_part_bounds(i), "y": World.EnergyStation.COLLISION_RECTS[i].end.y})
	check(structures.size() > 40, "Every Water structure is audited")
	# Terminal signs are floating labels: actors walk under them freely and the
	# label fades/ghosts them (main.gd), so a sign never blocks movement.
	for index in range(World.GOALS.size()):
		var sign: Rect2 = World.Objectives.sign_rect(World.GOALS[index], index)
		var under := Vector2(sign.get_center().x, sign.end.y - 4.0)
		var sign_blocked := false
		for rect in World.solids(4):
			if rect.encloses(Rect2(sign.position + Vector2(20, 4), Vector2(sign.size.x - 40, 8))): sign_blocked = true
		check(not sign_blocked, "Sign %d is not a solid" % index)
	for actor in [["Lia", 14.0], ["drone", 17.0], ["drone", 21.0]]:
		for structure in structures:
			var bounds: Rect2 = structure.bounds
			var area := bounds.grow(60.0)
			var y := area.position.y
			while y < area.end.y:
				var x := area.position.x
				while x < area.end.x:
					var at := Vector2(x, y)
					if at.y < float(structure.y) and World.walkable(at, actor[1], 3):
						var sprite := Occlusion.lia_rect(at) if actor[0] == "Lia" else Occlusion.drone_rect(at, false)
						var covered := Occlusion.hidden_fraction(sprite, [bounds])
						# Directly behind the art nothing may show through; at the front
						# corners a few edge pixels may touch, never enough for a silhouette.
						var behind := at.x >= bounds.position.x and at.x <= bounds.end.x
						var limit := 0.05 if behind else Occlusion.THRESHOLD
						if covered > limit:
							check(false, "%s at %s is %d%% inside the structure at %s" % [actor[0], at, roundi(covered * 100.0), bounds])
							return
					x += 6.0
				y += 6.0
