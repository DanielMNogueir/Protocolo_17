extends RefCounted
## Shared perception, squad coordination and reactions. Districts supply
## collision queries and apply the movement and attacks to the world.
const TOKENS := {"story": 1, "operation": 2, "veteran": 3}
const LEAD := {"story": 0.0, "operation": 0.35, "veteran": 0.6}
const REACTION := {"story": 0.3, "operation": 0.2, "veteran": 0.12}
const ALERT_TIME := 0.4
const SEARCH_TIME := 4.0
const ALARM_RADIUS := 300.0
const DODGE_SPEED := 140.0

var _tokens: Dictionary = {}
var _slots: Dictionary = {}
var last_attack_origin := Vector2.INF


class Unit:
	var mode := "patrol"
	var home: Vector2
	var patrol_axis: Vector2
	var patrol_side := 1.0
	var last_seen := Vector2.ZERO
	var alert_time := 0.0
	var search_time := 0.0
	var tactic_time := 0.0
	var flank := Vector2.INF
	var path := PackedVector2Array()
	var route_time := 0.0
	var route_target := Vector2.INF
	var retreat := 0.0
	var retreated := false
	var stunned := 0.0
	var dodge_cd := 0.0
	var dodge_delay := 0.0
	var dodge_left := 0.0
	var dodge := Vector2.ZERO

	func _init(start: Vector2, id: int) -> void:
		home = start
		patrol_axis = Vector2.from_angle(id * 2.399963)

	func notice(target: Vector2) -> bool:
		last_seen = target
		if mode in ["alert", "combat"]:
			return false
		mode = "alert"
		alert_time = ALERT_TIME
		return true

	func sense(dt: float, target: Vector2, visible: bool) -> bool:
		tactic_time -= dt
		retreat = maxf(0.0, retreat - dt)
		stunned = maxf(0.0, stunned - dt)
		match mode:
			"patrol":
				return notice(target) if visible else false
			"alert":
				if visible: last_seen = target
				alert_time = maxf(0.0, alert_time - dt)
				if alert_time <= 0.0:
					mode = "combat" if visible else "search"
					search_time = SEARCH_TIME
			"combat":
				if visible:
					last_seen = target
				else:
					mode = "search"
					search_time = SEARCH_TIME
			"search":
				if visible:
					mode = "combat"
					last_seen = target
				else:
					search_time = maxf(0.0, search_time - dt)
					if search_time <= 0.0:
						mode = "patrol"
		return false

	func damaged(ratio: float, target: Vector2) -> bool:
		var alarm := notice(target)
		if ratio > 0.0 and ratio < 0.3 and not retreated:
			retreated = true
			retreat = 1.5
			return true
		return alarm

	func patrol_point(at: Vector2, walkable: Callable) -> Vector2:
		var point := home + patrol_axis * (42.0 * patrol_side)
		if not walkable.call(point) or at.distance_squared_to(point) < 144.0:
			patrol_side *= -1.0
			point = home + patrol_axis * (42.0 * patrol_side)
		return point if walkable.call(point) else home

	func course(dt: float, at: Vector2, target: Vector2, planner: Callable) -> Vector2:
		route_time -= dt
		if route_time <= 0.0 or target.distance_squared_to(route_target) > 4096.0:
			path = planner.call(at, target)
			route_target = target
			route_time = 0.9
		while path.size() > 1 and at.distance_squared_to(path[0]) < 100.0:
			path.remove_at(0)
		if path.size() == 1 and at.distance_squared_to(path[0]) < 36.0:
			return Vector2.ZERO
		return at.direction_to(path[0] if not path.is_empty() else target)

	func dodge_course(dt: float, level: String, at: Vector2, shots: Array, walkable: Callable) -> Vector2:
		dodge_cd = maxf(0.0, dodge_cd - dt)
		if dodge_left > 0.0:
			dodge_left = maxf(0.0, dodge_left - dt)
			return dodge
		if dodge_delay > 0.0:
			dodge_delay = maxf(0.0, dodge_delay - dt)
			if dodge_delay <= 0.0:
				dodge_left = 0.25
				return dodge
			return Vector2.ZERO
		if dodge_cd > 0.0:
			return Vector2.ZERO
		for bullet in shots:
			if not bullet.get("secondary", false):
				continue
			var start: Vector2 = bullet.pos
			var velocity: Vector2 = bullet.vel
			if velocity.dot(at - start) <= 0.0:
				continue
			var closest := Geometry2D.get_closest_point_to_segment(at, start, start + velocity * 0.4)
			if closest.distance_squared_to(at) >= 2500.0:
				continue
			var lateral := velocity.normalized().orthogonal()
			if lateral.dot(at - closest) < 0.0:
				lateral = -lateral
			if not walkable.call(at + lateral * 37.0):
				lateral = -lateral
			if walkable.call(at + lateral * 37.0):
				dodge = lateral
				dodge_delay = REACTION[level]
				dodge_cd = 3.0
				break
		return Vector2.ZERO


static func for_enemy(enemy: Dictionary) -> Unit:
	if not enemy.has("mind"):
		enemy["mind"] = Unit.new(enemy.get("home", enemy.pos), enemy.id)
	return enemy.mind


func acquire(id: int, level: String) -> bool:
	if _tokens.has(id):
		return true
	if _tokens.size() >= int(TOKENS[level]):
		return false
	_tokens[id] = true
	return true


func release(id: int) -> void:
	_tokens.erase(id)


func clear() -> void:
	_tokens.clear()
	_slots.clear()
	last_attack_origin = Vector2.INF


func clear_slot(id: int) -> void:
	_slots.erase(id)


func flank(id: int, kind: String, at: Vector2, target: Vector2, distance: float,
		walkable: Callable, visible: Callable, covered: Callable) -> Vector2:
	var best := Vector2.INF
	var best_score := INF
	var slot := -1
	_slots.erase(id)
	var occupied := _slots.values()
	for i in 8:
		if i in occupied:
			continue
		var axis := Vector2.from_angle(i * TAU / 8.0)
		var point := target + axis * distance
		if not walkable.call(point) or not visible.call(point, target):
			continue
		var score := at.distance_to(point)
		if kind == "scout" and last_attack_origin.is_finite():
			var angle := absf(target.direction_to(last_attack_origin).angle_to(axis))
			if angle >= PI / 3.0 and angle <= 2.0 * PI / 3.0: score -= 110.0
		elif kind == "sentry" and covered.call(point):
			score -= 100.0
		if score < best_score:
			slot = i
			best = point
			best_score = score
	if slot >= 0: _slots[id] = slot
	return best


static func aim(at: Vector2, target: Vector2, velocity: Vector2, projectile_speed: float, level: String) -> Vector2:
	var travel := at.distance_to(target) / projectile_speed
	return at.direction_to(target + velocity * travel * float(LEAD[level]))


static func near_cover(point: Vector2, walkable: Callable) -> bool:
	for direction in [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]:
		if not walkable.call(point + direction * 40.0):
			return true
	return false
