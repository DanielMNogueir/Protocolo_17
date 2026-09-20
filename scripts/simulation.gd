class_name P17Simulation
extends RefCounted
## Independent, deterministic game rules. Rendering, input and disk I/O live outside.

const W = preload("res://scripts/world.gd")
const PLAYER_RADIUS: float = 14.0
const REPAIR_SECONDS: float = 1.8
const MAX_STEP: float = 1.0 / 90.0
const WAVE_KINDS: Array = [
	["scout", "scout", "sentry"],
	["scout", "rammer", "sentry", "scout"],
	["sentry", "rammer", "scout", "sentry", "rammer"],
	["sentry", "rammer", "scout", "sentry", "boss"],
]
const UPGRADES: Array = [
	[
		{"id": "focused_pulse", "title": "Pulso focado", "description": "Dispare 25% mais rápido. Recuperação precisa, sem desperdício."},
		{"id": "reserve_cell", "title": "Célula de reserva", "description": "+2 de integridade máxima. Recompõe também 2 pontos agora."},
		{"id": "light_harness", "title": "Arnês leve", "description": "+25 de velocidade. Reposicione-se entre as rajadas."},
	],
	[
		{"id": "induction_coil", "title": "Bobina de indução", "description": "+1 de dano por pulso. Reaproveite energia dos drones."},
		{"id": "reclaimed_armor", "title": "Placas recuperadas", "description": "+2 de integridade máxima e 2 pontos de reparo imediato."},
		{"id": "efficient_dash", "title": "Impulso eficiente", "description": "Recarga do impulso reduzida em 0,25 s."},
	],
	[
		{"id": "clean_frequency", "title": "Frequência limpa", "description": "Cadência 20% maior e pulsos 15% mais velozes."},
		{"id": "living_circuit", "title": "Circuito resiliente", "description": "+2 de integridade máxima. Um último reforço para a central."},
		{"id": "water_stride", "title": "Passo da corrente", "description": "+20 de velocidade e recarga do impulso 0,15 s menor."},
	],
]

var state: String = "combat"
var stage: int = 0
var restored: int = 0
var pos: Vector2 = W.START
var velocity: Vector2 = Vector2.ZERO
var aim: Vector2 = Vector2.UP
var hp: int = 6
var max_hp: int = 6
var dash_cd: float = 0.0
var dash_time: float = 0.0
var invuln: float = 0.0
var repair: float = 0.0
var enemies: Array[Dictionary] = []
var bullets: Array[Dictionary] = []
var particles: Array[Dictionary] = []
var events: Array[String] = []
var chosen: Array[String] = []
var elapsed: float = 0.0
var kills: int = 0
var shots: int = 0

var move_speed: float = 205.0
var fire_interval: float = 0.20
var pulse_damage: int = 1
var pulse_speed: float = 640.0
var dash_recharge: float = 1.2
var _fire_cd: float = 0.0
var _dash_direction: Vector2 = Vector2.UP
var _solid_rects: Array[Rect2] = []
var _particle_serial: int = 0


func start(stage_index: int = 0) -> void:
	stage = clampi(stage_index, 0, 3)
	restored = stage
	chosen.clear()
	elapsed = 0.0
	kills = 0
	shots = 0
	_reset_stats()
	_begin_encounter(true)


func tick(dt: float, movement: Vector2, target: Vector2, shooting: bool, dash_pressed: bool, interacting: bool) -> void:
	events.clear()
	if dt <= 0.0 or not is_finite(dt):
		return
	if state != "combat" and state != "activation":
		return
	# Limit catch-up after a suspended window; all accepted time uses bounded steps.
	var remaining: float = minf(dt, 0.1)
	var input_move: Vector2 = movement.limit_length(1.0)
	if not input_move.is_finite():
		input_move = Vector2.ZERO
	if target.is_finite() and target.distance_squared_to(pos) > 1.0:
		aim = (target - pos).normalized()
	if dash_pressed and dash_cd <= 0.0:
		_dash_direction = input_move.normalized() if input_move.length_squared() > 0.01 else aim
		dash_time = 0.16
		dash_cd = dash_recharge
		invuln = maxf(invuln, 0.16)
		events.append("dash")
		_emit_particles(pos, Color("72ead7"), 7, 90.0)
	while remaining > 0.000001:
		var step: float = minf(remaining, MAX_STEP)
		remaining -= step
		elapsed += step
		_step(step, input_move, shooting, interacting)
		if state != "combat" and state != "activation":
			break


func _step(dt: float, movement: Vector2, shooting: bool, interacting: bool) -> void:
	dash_cd = maxf(0.0, dash_cd - dt)
	_fire_cd = maxf(0.0, _fire_cd - dt)
	var was_dashing: bool = dash_time > 0.0
	if was_dashing:
		velocity = _dash_direction * 650.0
	else:
		velocity = velocity.move_toward(movement * move_speed, (1650.0 if movement != Vector2.ZERO else 2200.0) * dt)
	pos = _slide(pos, velocity * dt, PLAYER_RADIUS)
	dash_time = maxf(0.0, dash_time - dt)
	if was_dashing and dash_time <= 0.0:
		velocity = movement * move_speed
	if shooting and state == "combat" and _fire_cd <= 0.0:
		_fire_cd = fire_interval
		_spawn_bullet(pos, aim, pulse_speed, false, pulse_damage, 1.7, 3.0)
		shots += 1
		events.append("shoot")
	if state == "combat":
		_update_enemies(dt)
		if state == "defeat":
			return
		_update_bullets(dt)
		if state == "defeat":
			return
		if enemies.is_empty():
			state = "activation"
			bullets.clear()
			repair = 0.0
	elif state == "activation":
		if interacting and pos.distance_to(W.GOALS[stage]) <= 84.0 and dash_time <= 0.0:
			repair = minf(1.0, repair + dt / REPAIR_SECONDS)
			if repair >= 1.0:
				_activate()
		else:
			repair = 0.0
	invuln = maxf(0.0, invuln - dt)
	_update_particles(dt)


func _reset_stats() -> void:
	max_hp = 6
	move_speed = 205.0
	fire_interval = 0.20
	pulse_damage = 1
	pulse_speed = 640.0
	dash_recharge = 1.2


func _begin_encounter(at_checkpoint: bool) -> void:
	state = "combat"
	if at_checkpoint:
		pos = W.CHECKPOINTS[stage]
	hp = max_hp if at_checkpoint else hp
	velocity = Vector2.ZERO
	dash_cd = 0.0
	dash_time = 0.0
	invuln = 1.0
	repair = 0.0
	_fire_cd = 0.0
	bullets.clear()
	particles.clear()
	events.clear()
	enemies.clear()
	_solid_rects = W.solids(stage)
	var locations: Array = W.SPAWNS[stage]
	var kinds: Array = WAVE_KINDS[stage]
	for index in mini(locations.size(), kinds.size()):
		var kind: String = str(kinds[index])
		var enemy_hp: int = 5 + stage * 2
		var radius: float = 17.0
		if kind == "sentry":
			enemy_hp += 2
			radius = 20.0
		elif kind == "rammer":
			enemy_hp += 3
			radius = 21.0
		elif kind == "boss":
			enemy_hp = 80
			radius = 44.0
		enemies.append({
			"pos": locations[index], "kind": kind, "hp": enemy_hp, "max_hp": enemy_hp,
			"radius": radius, "warning": 0.0, "aim": Vector2.DOWN,
			"cooldown": 0.7 + float(index) * 0.35, "phase": "idle", "age": 0.0,
			"charge_time": 0.0, "attack": 0, "id": index, "engaged": false,
			"hurt": 0.0, "steer": 1.0 if index % 2 == 0 else -1.0,
		})


func _update_enemies(dt: float) -> void:
	for enemy in enemies:
		var origin: Vector2 = enemy["pos"]
		var kind: String = str(enemy["kind"])
		var radius: float = float(enemy["radius"])
		var offset: Vector2 = pos - origin
		var distance: float = offset.length()
		enemy["age"] = float(enemy["age"]) + dt
		enemy["hurt"] = maxf(0.0, float(enemy["hurt"]) - dt)
		if distance > (610.0 if kind == "boss" else 570.0) and not bool(enemy["engaged"]):
			continue
		if not bool(enemy["engaged"]):
			enemy["engaged"] = true
			if kind == "boss":
				events.append("boss")
		enemy["cooldown"] = maxf(0.0, float(enemy["cooldown"]) - dt)
		var phase: String = str(enemy["phase"])
		if phase == "windup":
			enemy["warning"] = maxf(0.0, float(enemy["warning"]) - dt)
			if float(enemy["warning"]) <= 0.0:
				_enemy_attack(enemy)
		elif phase == "charge":
			var charge: Vector2 = Vector2(enemy["aim"]) * 375.0 * dt
			var moved: Vector2 = _slide(origin, charge, radius)
			enemy["pos"] = moved
			enemy["charge_time"] = float(enemy["charge_time"]) - dt
			if float(enemy["charge_time"]) <= 0.0 or moved.distance_squared_to(origin) < charge.length_squared() * 0.3:
				enemy["phase"] = "idle"
				enemy["cooldown"] = 1.2
		else:
			var desired_range: float = 225.0 if kind == "sentry" else (270.0 if kind == "boss" else 165.0)
			if kind == "rammer":
				desired_range = 110.0
			var travel: Vector2 = Vector2.ZERO
			var speed: float = 68.0 if kind == "sentry" else (43.0 if kind == "boss" else 90.0)
			if distance > desired_range:
				travel = offset.normalized() * speed * dt
			elif distance < desired_range - 65.0 and kind != "rammer":
				travel = -offset.normalized() * speed * 0.65 * dt
			if travel != Vector2.ZERO:
				enemy["pos"] = _avoid_move(enemy, travel, radius)
			var reach: float = 285.0 if kind == "rammer" else (535.0 if kind == "boss" else 470.0)
			if distance < reach and float(enemy["cooldown"]) <= 0.0 and _wall_fraction(origin, pos, 1.0) == INF:
				enemy["phase"] = "windup"
				enemy["warning"] = 0.8 if kind == "boss" else (0.75 if kind == "rammer" else 0.65)
				enemy["aim"] = offset.normalized() if distance > 0.01 else Vector2.DOWN
		# Contact uses the final position; obstacle separation still protects Lia.
		var final_pos: Vector2 = enemy["pos"]
		if final_pos.distance_to(pos) < radius + PLAYER_RADIUS - 2.0 and _wall_fraction(final_pos, pos, 0.0) == INF:
			_hurt(1)
			if state == "defeat":
				return


func _enemy_attack(enemy: Dictionary) -> void:
	var origin: Vector2 = enemy["pos"]
	var direction: Vector2 = enemy["aim"]
	var kind: String = str(enemy["kind"])
	enemy["phase"] = "idle"
	enemy["cooldown"] = 1.65 if kind != "boss" else 1.95
	if kind == "rammer":
		enemy["phase"] = "charge"
		enemy["charge_time"] = 0.52
	elif kind == "boss":
		var attack: int = int(enemy["attack"])
		enemy["attack"] = attack + 1
		if attack % 2 == 0:
			# The aim line is a safe gap in an otherwise radial, slow volley.
			for index in 14:
				var angle: float = TAU * (float(index) + 0.5) / 14.0
				_spawn_bullet(origin, direction.rotated(angle), 155.0, true, 1, 4.0, 5.0)
		else:
			for index in 5:
				_spawn_bullet(origin, direction.rotated(float(index - 2) * 0.17), 220.0, true, 1, 3.2, 5.0)
	elif kind == "sentry":
		for angle in [-0.11, 0.11]:
			_spawn_bullet(origin, direction.rotated(float(angle)), 215.0, true, 1, 2.8, 4.0)
	else:
		_spawn_bullet(origin, direction, 190.0, true, 1, 2.8, 4.0)


func _spawn_bullet(origin: Vector2, direction: Vector2, speed: float, hostile: bool, damage: int, life: float, radius: float) -> void:
	bullets.append({"pos": origin, "vel": direction.normalized() * speed, "hostile": hostile,
		"damage": damage, "life": life, "radius": radius})


func _update_bullets(dt: float) -> void:
	for index in range(bullets.size() - 1, -1, -1):
		var bullet: Dictionary = bullets[index]
		bullet["life"] = float(bullet["life"]) - dt
		if float(bullet["life"]) <= 0.0:
			bullets.remove_at(index)
			continue
		var origin: Vector2 = bullet["pos"]
		var destination: Vector2 = origin + Vector2(bullet["vel"]) * dt
		var radius: float = float(bullet["radius"])
		var fraction: float = _wall_fraction(origin, destination, radius)
		var hit_enemy: int = -1
		var hit_player: bool = false
		if bool(bullet["hostile"]):
			var impact: float = _segment_circle(origin, destination, pos, PLAYER_RADIUS + radius)
			if impact < fraction:
				fraction = impact
				hit_player = true
		else:
			for target_index in enemies.size():
				var target: Dictionary = enemies[target_index]
				var impact: float = _segment_circle(origin, destination, target["pos"], float(target["radius"]) + radius)
				if impact < fraction:
					fraction = impact
					hit_enemy = target_index
		if fraction != INF:
			var impact_pos: Vector2 = origin.lerp(destination, fraction)
			bullets.remove_at(index)
			_emit_particles(impact_pos, Color("ff8da2") if bool(bullet["hostile"]) else Color("70f1dd"), 4, 65.0)
			if hit_player:
				_hurt(int(bullet["damage"]))
				if state == "defeat":
					return
			elif hit_enemy >= 0:
				_damage_enemy(hit_enemy, int(bullet["damage"]))
		else:
			bullet["pos"] = destination


func _damage_enemy(index: int, amount: int) -> void:
	var enemy: Dictionary = enemies[index]
	enemy["hp"] = maxi(0, int(enemy["hp"]) - amount)
	enemy["hurt"] = 0.12
	if int(enemy["hp"]) == 0:
		_emit_particles(enemy["pos"], Color("d2ad69"), 16 if str(enemy["kind"]) == "boss" else 9, 125.0)
		enemies.remove_at(index)
		kills += 1
		events.append("enemy_dead")


func _hurt(amount: int) -> void:
	if invuln > 0.0 or state != "combat":
		return
	hp = maxi(0, hp - amount)
	invuln = 0.8
	events.append("hurt")
	_emit_particles(pos, Color("ff708d"), 8, 100.0)
	if hp == 0:
		state = "defeat"
		velocity = Vector2.ZERO
		dash_time = 0.0
		bullets.clear()


func _activate() -> void:
	restored = stage + 1
	hp = mini(max_hp, hp + 2)
	velocity = Vector2.ZERO
	bullets.clear()
	events.append("repair")
	_emit_particles(W.GOALS[stage], Color("a9e797"), 28, 140.0)
	if stage == 3:
		state = "victory"
		events.append("complete")
	else:
		state = "upgrade"


func upgrade_options() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if stage >= 3:
		return result
	for option in UPGRADES[stage]:
		result.append(Dictionary(option).duplicate())
	return result


func choose_upgrade(index: int) -> bool:
	if state != "upgrade" or stage >= 3 or index < 0 or index > 2:
		return false
	var options: Array[Dictionary] = upgrade_options()
	var id: String = str(options[index]["id"])
	chosen.append(id)
	_apply_upgrade(id, true)
	stage += 1
	# Only the next gate changes. Lia stays at the terminal she just repaired.
	_begin_encounter(false)
	return true


func _apply_upgrade(id: String, heal_now: bool) -> void:
	match id:
		"focused_pulse":
			fire_interval *= 0.8
		"reserve_cell", "reclaimed_armor", "living_circuit":
			max_hp += 2
			if heal_now:
				hp = mini(max_hp, hp + 2)
		"light_harness":
			move_speed += 25.0
		"induction_coil":
			pulse_damage += 1
		"efficient_dash":
			dash_recharge -= 0.25
		"clean_frequency":
			fire_interval /= 1.2
			pulse_speed *= 1.15
		"water_stride":
			move_speed += 20.0
			dash_recharge -= 0.15


func retry() -> void:
	if state == "defeat":
		_begin_encounter(true)


func save_data() -> Dictionary:
	return {"version": 1, "stage": stage, "chosen": chosen.duplicate()}


func load_data(data: Dictionary) -> bool:
	if not data.has("version") or not data.has("stage") or not data.has("chosen"):
		return false
	if not (data["version"] is int or data["version"] is float) or float(data["version"]) != 1.0:
		return false
	if not (data["stage"] is int or data["stage"] is float):
		return false
	var stage_number: float = float(data["stage"])
	if not is_finite(stage_number) or stage_number != floorf(stage_number) or stage_number < 0.0 or stage_number > 3.0:
		return false
	if not data["chosen"] is Array:
		return false
	var saved_stage: int = int(stage_number)
	var ids: Array = data["chosen"]
	if ids.size() != saved_stage:
		return false
	var validated: Array[String] = []
	for index in ids.size():
		if not ids[index] is String:
			return false
		var found: bool = false
		for option in UPGRADES[index]:
			if str(option["id"]) == str(ids[index]):
				found = true
		if not found:
			return false
		validated.append(str(ids[index]))
	# Validation is complete before mutating the running encounter.
	start(saved_stage)
	chosen = validated
	for id in chosen:
		_apply_upgrade(id, false)
	hp = max_hp
	return true


func _slide(origin: Vector2, offset: Vector2, radius: float) -> Vector2:
	var destination: Vector2 = origin + offset
	if W.walkable(destination, radius, stage):
		return destination
	var result: Vector2 = origin
	if W.walkable(result + Vector2(offset.x, 0.0), radius, stage):
		result.x += offset.x
	if W.walkable(result + Vector2(0.0, offset.y), radius, stage):
		result.y += offset.y
	return result


func _avoid_move(enemy: Dictionary, travel: Vector2, radius: float) -> Vector2:
	var origin: Vector2 = enemy["pos"]
	var direct: Vector2 = _slide(origin, travel, radius)
	if direct.distance_squared_to(origin) > travel.length_squared() * 0.6:
		return direct
	var side: float = float(enemy["steer"])
	for angle in [0.65, 1.1, 1.57, 2.1]:
		var step: Vector2 = travel.rotated(float(angle) * side)
		if W.walkable(origin + step * 5.0, radius, stage):
			return origin + step
	enemy["steer"] = -side
	return direct


func _wall_fraction(origin: Vector2, destination: Vector2, radius: float) -> float:
	var first: float = INF
	for rect in _solid_rects:
		first = minf(first, _segment_box(origin, destination, rect.grow(radius)))
	# Land boundaries are part of collision too, including water between regions.
	var samples: int = maxi(1, int(ceil(origin.distance_to(destination) / 5.0)))
	for index in samples + 1:
		var fraction: float = float(index) / float(samples)
		if fraction >= first:
			break
		if not W.walkable(origin.lerp(destination, fraction), radius, stage):
			first = fraction
			break
	return first


static func _segment_circle(origin: Vector2, destination: Vector2, center: Vector2, radius: float) -> float:
	var offset: Vector2 = origin - center
	var c: float = offset.length_squared() - radius * radius
	if c <= 0.0:
		return 0.0
	var direction: Vector2 = destination - origin
	var a: float = direction.length_squared()
	if a < 0.000001:
		return INF
	var b: float = 2.0 * offset.dot(direction)
	var discriminant: float = b * b - 4.0 * a * c
	if discriminant < 0.0:
		return INF
	var fraction: float = (-b - sqrt(discriminant)) / (2.0 * a)
	return fraction if fraction >= 0.0 and fraction <= 1.0 else INF


static func _segment_box(origin: Vector2, destination: Vector2, rect: Rect2) -> float:
	var direction: Vector2 = destination - origin
	var low: float = 0.0
	var high: float = 1.0
	for axis in 2:
		if absf(direction[axis]) < 0.000001:
			if origin[axis] < rect.position[axis] or origin[axis] > rect.end[axis]:
				return INF
		else:
			var a: float = (rect.position[axis] - origin[axis]) / direction[axis]
			var b: float = (rect.end[axis] - origin[axis]) / direction[axis]
			low = maxf(low, minf(a, b))
			high = minf(high, maxf(a, b))
			if low > high:
				return INF
	return low


func _emit_particles(origin: Vector2, color: Color, count: int, speed: float) -> void:
	for index in count:
		_particle_serial += 1
		var angle: float = float(_particle_serial) * 2.399963
		var life: float = 0.22 + float(_particle_serial % 5) * 0.055
		particles.append({"pos": origin, "vel": Vector2.from_angle(angle) * speed * (0.45 + float(index % 4) * 0.18),
			"life": life, "max_life": life, "color": color, "size": 2.0 + float(index % 3)})
	while particles.size() > 220:
		particles.remove_at(0)


func _update_particles(dt: float) -> void:
	for index in range(particles.size() - 1, -1, -1):
		var particle: Dictionary = particles[index]
		particle["life"] = float(particle["life"]) - dt
		if float(particle["life"]) <= 0.0:
			particles.remove_at(index)
		else:
			particle["pos"] = Vector2(particle["pos"]) + Vector2(particle["vel"]) * dt
			particle["vel"] = Vector2(particle["vel"]) * exp(-dt * 4.0)
