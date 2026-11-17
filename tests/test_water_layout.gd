extends SceneTree
## Water district traversal audit on the real collision: every sector's
## objective is reachable on foot, the next sector stays behind its gate, and
## every spawn, checkpoint and field-task point stands on open ground.
const World = preload("res://scripts/world.gd")
const Guidance = preload("res://scripts/water_guidance.gd")
const Operation = preload("res://scripts/sector_operation.gd")
var checks := 0
var failures := 0

func _initialize() -> void: _run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("WATER_LAYOUT_FAILED: " + label)

func reachable(from: Vector2, target: Vector2, stage: int, reach: float) -> bool:
	var path := Guidance.route(from, target, stage, reach)
	return not path.is_empty() and path[path.size() - 1].distance_to(target) <= reach + Guidance.SPACING

func _run() -> void:
	for stage in 4:
		var origin: Vector2 = World.CHECKPOINTS[stage]
		check(World.walkable(origin, 14.0, stage), "checkpoint %d stands on open ground" % stage)
		check(reachable(origin, World.GOALS[stage], stage, 84.0), "terminal %d reachable from its checkpoint" % stage)
		check(reachable(World.START, World.GOALS[stage], stage, 84.0), "terminal %d reachable from the quay" % stage)
		if stage < 3:
			check(not reachable(origin, World.GOALS[stage + 1], stage, 84.0), "gate %d keeps sector %d closed" % [stage, stage + 1])
			check(reachable(origin, World.GOALS[stage + 1], stage + 1, 84.0), "opening gate %d leads into sector %d" % [stage, stage + 1])
		for spawn in World.SPAWNS[stage]:
			check(World.walkable(spawn, 18.0, stage), "spawn %s of sector %d on open ground" % [spawn, stage])
		var operation := Operation.new()
		operation.reset(stage)
		for i in 2:
			var authored: Vector2 = Operation.POINTS[stage][i]
			var placed: Vector2 = operation.points[i]
			check(placed.distance_to(authored) <= 40.0, "task %d/%d stays at its authored spot (moved %.0f px)" % [stage, i, placed.distance_to(authored)])
			check(reachable(origin, placed, stage, 60.0), "task %d/%d reachable" % [stage, i])
	check(World.walkable(World.START, 14.0, 0), "start quay is walkable")
	print("WATER_LAYOUT_%s: %d checks; %d failures" % ["OK" if failures == 0 else "FAILED", checks, failures])
	quit(0 if failures == 0 else 1)
