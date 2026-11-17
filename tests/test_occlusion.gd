extends SceneTree
## Lia and the drones are never lost behind scenery: every walkable spot where
## a tall object covers the sprite past the threshold gets the translucent
## silhouette, in Water (all sortable types) and in Residues.
const World = preload("res://scripts/world.gd")
const Residue = preload("res://scripts/residue_map.gd")
const Occlusion = preload("res://scripts/occlusion.gd")
var checks := 0
var failures := 0

func _initialize() -> void: _run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("OCCLUSION_FAILED: " + label)

func water_scenery() -> Array[Dictionary]:
	var scenery: Array[Dictionary] = []
	for object in World.sortable_objects(Rect2(Vector2.ZERO, World.SIZE).grow(200)):
		var bounds := World.sortable_bounds(object)
		if bounds.has_area(): scenery.append({"y": float(object.y), "bounds": bounds})
	for index in 3:
		scenery.append({"y": float(P17EnergyStation.COLLISION_RECTS[index].end.y), "bounds": World.station_part_bounds(index)})
	return scenery

func residue_scenery() -> Array[Dictionary]:
	var scenery: Array[Dictionary] = []
	var sorted := [false, false, false, false]
	var cleared := [true, true, true, true]
	for prop in Residue.props(sorted, cleared, [false, false, false], -1):
		scenery.append({"y": float(prop.depth), "bounds": Residue.scenery_bounds("prop", prop)})
	for prop in Residue.occluders():
		scenery.append({"y": float(prop.depth), "bounds": Residue.scenery_bounds("occluder", prop)})
	return scenery

## Sweep: worst covered share without a silhouette must stay below the threshold.
func sweep(label: String, size: Vector2, scenery: Array[Dictionary], walkable: Callable) -> void:
	var walk := 0
	var ghosted := 0
	var worst_before := 0.0
	var worst_after := 0.0
	for y in range(30, int(size.y) - 30, 18):
		for x in range(30, int(size.x) - 30, 18):
			var point := Vector2(x, y)
			if not walkable.call(point): continue
			walk += 1
			var rect := Occlusion.lia_rect(point)
			var fraction := Occlusion.hidden_fraction(rect, Occlusion.covers_for(rect, point.y + 14.0, scenery))
			worst_before = maxf(worst_before, fraction)
			if Occlusion.is_hidden(rect, point.y + 14.0, scenery): ghosted += 1
			else: worst_after = maxf(worst_after, fraction)
	print("%s: %d walkable spots, %d with silhouette, worst cover %.0f%% -> %.0f%% without silhouette" % [label, walk, ghosted, worst_before * 100.0, worst_after * 100.0])
	check(walk > 500, label + " sweep reaches the walkable floor")
	check(worst_after < Occlusion.THRESHOLD, label + " never leaves Lia hidden past the threshold")

func _run() -> void:
	var water := water_scenery()
	check(water.size() > 40, "Water exposes bounds for its sortable scenery")
	# Lia directly north of the distribution terminal is covered by it.
	var terminal := World.terminal(3)
	var behind := Vector2(terminal.visual_bounds.get_center().x, terminal.depth_anchor.y - 45.0)
	check(World.walkable(behind, 14.0, 4), "Spot behind the distribution terminal is walkable")
	var behind_rect := Occlusion.lia_rect(behind)
	check(Occlusion.is_hidden(behind_rect, behind.y + 14.0, water), "Silhouette behind the distribution terminal")
	check(not Occlusion.is_hidden(Occlusion.lia_rect(World.START), World.START.y + 14.0, water), "No silhouette on the open quay")
	# The same spot is clear when Lia is in front of (south of) the terminal.
	var front := Vector2(behind.x, terminal.depth_anchor.y + 30.0)
	check(not Occlusion.is_hidden(Occlusion.lia_rect(front), front.y + 14.0, water), "No silhouette in front of the terminal")
	sweep("ÁGUAS", World.SIZE, water, func(p: Vector2) -> bool: return World.walkable(p, 14.0, 4))
	var residues := residue_scenery()
	check(residues.size() > 10, "Residues exposes bounds for props and occluders")
	sweep("RESÍDUOS", Residue.SIZE, residues, func(p: Vector2) -> bool: return Residue.walkable(p, 14.0, 3, [true, true, true, true]))
	print("OCCLUSION_%s: %d checks; %d failures" % ["OK" if failures == 0 else "FAILED", checks, failures])
	quit(0 if failures == 0 else 1)
