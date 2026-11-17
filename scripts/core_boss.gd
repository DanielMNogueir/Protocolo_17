extends RefCounted

const Map = preload("res://scripts/core_map.gd")
const Mechanics = preload("res://scripts/power_mechanics.gd")
const Simulation = preload("res://scripts/simulation.gd")
const PRESSURE := {"story": 1.25, "operation": 1.0, "veteran": 0.77}
const WINDUP := {"story": 1.3, "operation": 1.0, "veteran": 0.85}
const ARC_PERIOD := {"story": 3.2, "operation": 2.6, "veteran": 2.2}
const SPARK_INTERVAL := {"story": 16.0, "operation": 12.0, "veteran": 9.0}
const SPARK_CAP := {"story": 2, "operation": 4, "veteran": 5}
const SOLAR_DAMAGE := {"story": 0.06, "operation": 0.05, "veteran": 0.04}
const HEAL := {"story": 3, "operation": 2, "veteran": 1}
const BIAS := {"story": 0.0, "operation": 0.35, "veteran": 0.6}
const PULSE_SCALE := {"story": 1.4, "operation": 1.0, "veteran": 0.85}
const SUN := Vector2(1740, 465)
const SCRAMBLE := [2, 3, 1]

var difficulty: String
var phase := 1
var integrity := 1.0
var pillars: Array[Mechanics.Overload] = []
var mirrors: Mechanics.Mirrors
var arcs: Array[Mechanics.ArcPair] = []
var events: Array[String] = []
var phase_time := 0.0
var burn := 0.0
var dawn_amount := 0.0
var pattern_timer := 0.0
var attack := ""
var warning := 0.0
var warning_length := 0.0
var aim_angle := 0.0
var sweep := 0.0
var fire_time := 0.0
var fire_length := 0.0
var adaptive_message := ""
var _pattern := 0
var _spark_timer := 0.0
var _rng := RandomNumberGenerator.new()
var _samples: Array[float] = []
var _sample_delay := 0.0
var _next_shot := 0.0
var _shots := 0
var _sunrise := false


func _init(level: String = "operation", timing_scale: float = 1.0, checkpoint: int = 1) -> void:
	difficulty = level
	for index in 4:
		pillars.append(Mechanics.Overload.new(level, timing_scale, "steady" if index % 2 == 0 else "surge"))
	var headings: Array[int] = []
	var starts: Array[int] = []
	for point in Map.mirrors():
		var normal := (point.direction_to(SUN) + point.direction_to(Map.CENTER)).normalized()
		headings.append(posmod(roundi(normal.angle() / (PI / 4.0)), 8))
		starts.append((headings[-1] + 4) % 8)
	mirrors = Mechanics.Mirrors.new(headings, starts)
	var period: float = ARC_PERIOD[level]
	var warn: float = 0.6 * WINDUP[level]
	arcs.assign([Mechanics.ArcPair.new(Map.ring(0.42, -60), Map.ring(0.42, -20), period, 0.0, 0.7, warn),
		Mechanics.ArcPair.new(Map.ring(0.42, 120), Map.ring(0.42, 160), period, period * 0.5, 0.7, warn)])
	_rng.randomize()
	_enter(checkpoint)


func _enter(next: int) -> void:
	phase = next
	phase_time = 0.0
	attack = ""
	warning = 0.0
	fire_time = 0.0
	burn = 0.0
	_pattern = 0
	pattern_timer = 2.4 * float(PRESSURE[difficulty])
	_spark_timer = float(SPARK_INTERVAL[difficulty]) if next == 1 else 14.0 * float(PRESSURE[difficulty])
	if next >= 3:
		dawn_amount = 1.0
	if next >= 2:
		for pillar in pillars:
			pillar.done = true
	if next == 3:
		integrity = 0.5
	events.append("down" if next == 4 else "phase%d" % next)


func core_position() -> Vector2:
	return Map.CENTER + Vector2(0, -70 if phase <= 2 else 0)


func press_pillar(index: int) -> String:
	if phase != 1 or index < 0 or index >= pillars.size():
		return ""
	var result := pillars[index].press()
	if result == "done":
		if fallen_count() == 2:
			events.append("pillar")
		if fallen_count() == 4:
			_enter(2)
		return "fallen"
	return "miss" if result == "discharge" else result


func fallen_count() -> int:
	var count := 0
	for pillar in pillars:
		count += int(pillar.done)
	return count


func aligned_count() -> int:
	var count := 0
	for index in 3:
		count += int(mirrors.aligned(index) and mirrors.turning[index] <= 0.0)
	return count


func hit_mirror(index: int) -> bool:
	return phase == 2 and burn <= 0.0 and mirrors.rotate(index)


func hit_core(damage: float) -> bool:
	if damage <= 0.0 or (phase != 3 and (phase != 2 or burn <= 0.0)):
		return false
	_damage(damage * 0.004 * float(PULSE_SCALE[difficulty]) if phase == 3 else damage * 0.004)
	return true


func _damage(amount: float) -> void:
	var previous := integrity
	integrity = maxf(0.0, integrity - amount)
	if phase == 2 and integrity <= 0.5:
		_enter(3)
	elif phase == 3:
		if previous > 0.375 and integrity <= 0.375:
			events.append("beatrix_75")
		if previous > 0.2 and integrity <= 0.2:
			events.append("beatrix_40")
		if integrity <= 0.0:
			_enter(4)


func lateral_average() -> float:
	if _samples.is_empty():
		return 0.0
	var sum := 0.0
	for sample in _samples:
		sum += sample
	return sum / _samples.size()


func observe(dt: float, lia: Vector2, velocity: Vector2, exposed: bool) -> void:
	_sample_delay = maxf(0.0, _sample_delay - dt)
	if not exposed or _sample_delay > 0.0:
		return
	var lateral := Map.CENTER.direction_to(lia).cross(velocity)
	if absf(lateral) < 20.0:
		return
	_samples.append(signf(lateral))
	if _samples.size() > 30:
		_samples.pop_front()
	_sample_delay = 0.2


func tick(dt: float, lia: Vector2, velocity: Vector2, dashing: bool) -> Array[Dictionary]:
	var requests: Array[Dictionary] = []
	if phase == 4:
		return requests
	observe(dt, lia, velocity, dashing)
	phase_time += dt
	if phase == 1:
		for pillar in pillars:
			pillar.tick(dt)
	if phase == 2:
		_solar(dt)
	if phase == 3 and adaptive_message.is_empty() and _samples.size() >= 10:
		var average := lateral_average()
		if absf(average) >= 0.4:
			adaptive_message = _adaptive_text(average)
			events.append("adaptive")
	if phase <= 2:
		_spark_timer -= dt
		if _spark_timer <= 0.0:
			_spark_timer += float(SPARK_INTERVAL[difficulty]) if phase == 1 else 14.0 * float(PRESSURE[difficulty])
			_sparks(requests, lia, 1)
	_patterns(dt, lia, velocity, requests)
	return requests


func _adaptive_text(average: float) -> String:
	var side := "direita" if average > 0.0 else "esquerda"
	return "%s %d" % [side, roundi((1.0 + absf(average)) * 50.0)]


func _solar(dt: float) -> void:
	dawn_amount = clampf((phase_time - 6.0) / 8.0, 0.0, 1.0)
	if not _sunrise and phase_time >= 6.0:
		_sunrise = true
		events.append("sunrise")
	mirrors.tick(dt)
	if burn > 0.0:
		_damage(minf(burn, dt) * float(SOLAR_DAMAGE[difficulty]))
		if phase != 2:
			return
		burn = maxf(0.0, burn - dt)
		if burn <= 0.0:
			mirrors.solved = false
			for i in 3:
				mirrors.orientation[i] = (mirrors.orientation[i] + SCRAMBLE[i]) % 8
			events.append("scramble")
	elif _sunrise and mirrors.update_solved():
		burn = 6.0


func _patterns(dt: float, lia: Vector2, velocity: Vector2, requests: Array[Dictionary]) -> void:
	if warning > 0.0:
		warning = maxf(0.0, warning - dt)
		if warning == 0.0:
			_release(lia, requests)
		return
	if fire_time > 0.0:
		_fire_pattern(dt, lia, requests)
		return
	pattern_timer -= dt
	if pattern_timer > 0.0:
		return
	match phase:
		1: attack = ["fan", "laser", "fan", "call"][_pattern % 4]
		2: attack = "ring"
		3: attack = ["spiral", "aimed", "ring", "aimed"][_pattern % 4]
	_pattern += 1
	warning_length = float({"fan": 0.7, "laser": 1.0, "call": 0.85, "ring": 0.8, "spiral": 0.8, "aimed": 0.55}[attack]) * float(WINDUP[difficulty])
	warning = warning_length
	aim_angle = core_position().direction_to(lia).angle()
	var lateral := Vector2.from_angle(aim_angle).cross(velocity)
	sweep = deg_to_rad(-50.0 if lateral >= 0.0 else 50.0)
	if attack == "aimed":
		aim_angle += lateral_average() * float(BIAS[difficulty]) * 0.25
	if attack == "ring":
		aim_angle += _rng.randf_range(-PI / 3.0, PI / 3.0)
	events.append("attack_warn")


func _release(lia: Vector2, requests: Array[Dictionary]) -> void:
	match attack:
		"fan":
			for i in 7:
				_projectile(requests, aim_angle + deg_to_rad(70.0) * (i / 6.0 - 0.5), 150.0)
		"laser":
			fire_length = 0.9
			events.append("laser_fire")
		"call":
			_sparks(requests, lia, 2)
		"ring":
			var count := 12 if phase == 2 else 16
			for i in range(2, count - 1):
				_projectile(requests, aim_angle + TAU * i / count, 150.0)
		"spiral":
			fire_length = 2.5
		"aimed":
			fire_length = 0.32
	if attack in ["laser", "spiral", "aimed"]:
		fire_time = fire_length
		_next_shot = 0.0
		_shots = 0
	else:
		_finish_attack()


func _fire_pattern(dt: float, lia: Vector2, requests: Array[Dictionary]) -> void:
	fire_time = maxf(0.0, fire_time - dt)
	var age := fire_length - fire_time
	if attack == "aimed" or attack == "spiral":
		var cadence := 0.12 if attack == "aimed" else 0.125
		while _next_shot <= age and _next_shot < fire_length:
			if attack == "spiral":
				_projectile(requests, aim_angle + TAU * (_shots % 5) / 5.0 + deg_to_rad(40.0) * _next_shot, 140.0)
			else:
				var angle := core_position().direction_to(lia).angle() + lateral_average() * float(BIAS[difficulty]) * 0.25
				_projectile(requests, angle, 220.0, "bolt")
			_next_shot += cadence
			_shots += 1
	if fire_time <= 0.0:
		_finish_attack()


func _finish_attack() -> void:
	attack = ""
	pattern_timer = (3.0 if phase == 2 else 2.4) * float(PRESSURE[difficulty])


func laser_angle() -> float:
	return aim_angle + sweep * (1.0 - fire_time / fire_length) if fire_time > 0.0 else aim_angle


func _projectile(requests: Array[Dictionary], angle: float, speed: float, kind: String = "orb") -> void:
	var direction := Vector2.from_angle(angle)
	requests.append({"kind": kind, "pos": core_position() + direction * 50.0,
		"vel": direction * speed * float(Simulation.HOSTILE_SPEED[difficulty])})


func _sparks(requests: Array[Dictionary], lia: Vector2, count: int) -> void:
	var points := Map.spawns()
	points.sort_custom(func(a: Vector2, b: Vector2) -> bool: return lia.distance_squared_to(a) > lia.distance_squared_to(b))
	var start := _rng.randi_range(0, 1)
	for i in count:
		requests.append({"kind": "spark", "pos": points[start + i]})
