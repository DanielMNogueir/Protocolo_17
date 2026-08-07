extends Node2D

signal mission_completed(stats: Dictionary)

## Camada jog??vel da miss??o "Opera????o Filtro".
## Mant??m o cen??rio original intacto e adiciona pickup, tiro, alvos e objetivo.

const CYAN := Color("#35d6df")
const CYAN_SOFT := Color(0.21, 0.84, 0.87, 0.25)
const GREEN := Color("#58df7a")
const GOLD := Color("#ffd35a")
const MAGENTA := Color("#ff4fc3")
const DARK := Color("#16252c")
const WEAPON_SHEET := preload("res://assets/armas_protocolo17.png")
const DRONE_SHEET := preload("res://assets/drones_inimigos.png")

var elapsed := 0.0
var shoot_cooldown := 0.0
var weapon_collected := false
var repaired_filters := 0
var defeated_drones := 0
var weapon_position := Vector2(520, 500)
var mission_finished := false

var filters := [
	{"name": "OFICINA SOLAR", "position": Vector2(500, 380), "repaired": false},
	{"name": "ESTAÇÃO DE ÁGUA", "position": Vector2(1100, 450), "repaired": false},
	{"name": "CANAL CENTRAL", "position": Vector2(800, 720), "repaired": false},
]

var drones := [
	{"anchor": Vector2(425, 505), "position": Vector2(425, 505), "health": 2, "phase": 0.0, "active": true},
	{"anchor": Vector2(1020, 320), "position": Vector2(1020, 320), "health": 2, "phase": 1.8, "active": true},
	{"anchor": Vector2(1030, 590), "position": Vector2(1030, 590), "health": 2, "phase": 3.2, "active": true},
]

var projectiles: Array = []


func _ready() -> void:
	_create_input_actions()
	_update_hud(get_node_or_null("Lia"))
	queue_redraw()


func reset_mission() -> void:
	elapsed = 0.0
	shoot_cooldown = 0.0
	weapon_collected = false
	repaired_filters = 0
	defeated_drones = 0
	mission_finished = false
	projectiles.clear()

	for filter_index in range(filters.size()):
		filters[filter_index]["repaired"] = false

	for drone_index in range(drones.size()):
		drones[drone_index]["position"] = drones[drone_index]["anchor"]
		drones[drone_index]["health"] = 2
		drones[drone_index]["active"] = true

	var player = get_node_or_null("Lia")
	if player:
		player.call("reset_for_new_mission", Vector2(800, 500))
	_update_hud(player)
	queue_redraw()


func _process(delta: float) -> void:
	if mission_finished:
		return
	elapsed += delta
	shoot_cooldown = maxf(0.0, shoot_cooldown - delta)
	var player = get_node_or_null("Lia")
	if player == null:
		return

	_update_drones()
	_handle_weapon_pickup(player)
	_handle_repair(player)
	_handle_shoot(player)
	_update_projectiles(delta)
	_check_mission_completion()
	_update_hud(player)
	queue_redraw()


func _check_mission_completion() -> void:
	if mission_finished:
		return
	if repaired_filters < filters.size() or defeated_drones < drones.size():
		return

	mission_finished = true
	projectiles.clear()
	mission_completed.emit({
		"filters": repaired_filters,
		"total_filters": filters.size(),
		"drones": defeated_drones,
		"total_drones": drones.size(),
	})


func _create_input_actions() -> void:
	_add_key_action("shoot", KEY_SPACE)
	_add_key_action("interact", KEY_E)


func _add_key_action(action_name: StringName, keycode: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	if not InputMap.action_get_events(action_name).is_empty():
		return
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	InputMap.action_add_event(action_name, event)


func _handle_weapon_pickup(player) -> void:
	if weapon_collected:
		return
	if player.global_position.distance_to(weapon_position) <= 54.0:
		weapon_collected = true
		player.set_meta("weapon_unlocked", true)


func _handle_repair(player) -> void:
	if not Input.is_action_just_pressed("interact"):
		return
	for filter_data in filters:
		if filter_data["repaired"]:
			continue
		if player.global_position.distance_to(filter_data["position"]) <= 76.0:
			filter_data["repaired"] = true
			repaired_filters += 1
			break


func _handle_shoot(player) -> void:
	if not weapon_collected or shoot_cooldown > 0.0:
		return
	if not Input.is_action_just_pressed("shoot"):
		return
	var direction_name = player.get("last_direction")
	var direction := _direction_from_name(direction_name)
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	projectiles.append({
		"position": _get_weapon_muzzle_position(player.global_position, str(direction_name)),
		"direction": direction,
		"life": 1.25,
	})
	shoot_cooldown = 0.22


func _get_weapon_muzzle_position(player_position: Vector2, direction_name: String) -> Vector2:
	match direction_name:
		"left":
			return player_position + Vector2(-38, -42)
		"right":
			return player_position + Vector2(38, -42)
		"up":
			return player_position + Vector2(0, -68)
		"down":
			return player_position + Vector2(0, -18)
	return player_position + Vector2(38, -42)


func _update_projectiles(delta: float) -> void:
	for projectile_index in range(projectiles.size() - 1, -1, -1):
		var projectile = projectiles[projectile_index]
		projectile["position"] += projectile["direction"] * 620.0 * delta
		projectile["life"] -= delta
		var remove_projectile: bool = projectile["life"] <= 0.0

		for drone_index in range(drones.size()):
			var drone = drones[drone_index]
			if not drone["active"]:
				continue
			if projectile["position"].distance_to(drone["position"]) <= 30.0:
				drone["health"] -= 1
				if drone["health"] <= 0:
					drone["active"] = false
					defeated_drones += 1
				drones[drone_index] = drone
				remove_projectile = true
				break

		if remove_projectile:
			projectiles.remove_at(projectile_index)
		else:
			projectiles[projectile_index] = projectile


func _update_drones() -> void:
	for drone_index in range(drones.size()):
		var drone = drones[drone_index]
		if drone["active"]:
			var phase: float = drone["phase"]
			drone["position"] = drone["anchor"] + Vector2(
				sin(elapsed * 1.4 + phase) * 26.0,
				cos(elapsed * 1.8 + phase) * 14.0
			)
			drones[drone_index] = drone


func _direction_from_name(direction_name) -> Vector2:
	match str(direction_name):
		"up":
			return Vector2.UP
		"down":
			return Vector2.DOWN
		"left":
			return Vector2.LEFT
		"right":
			return Vector2.RIGHT
	return Vector2.ZERO


func _update_hud(player) -> void:
	var title = get_node_or_null("Interface/TopBar/Title")
	var subtitle = get_node_or_null("Interface/TopBar/Subtitle")
	var objective = get_node_or_null("Interface/ObjectivePanel/Objective")
	var controls = get_node_or_null("Interface/Controls")
	if title:
		title.text = "PROTOCOLO 17  |  OPERAÇÃO FILTRO"
	if subtitle:
		var weapon_text := "ARMA DE PULSO EQUIPADA" if weapon_collected else "ENCONTRE A ARMA DE PULSO"
		subtitle.text = "DISTRITO DAS ÁGUAS  -  " + weapon_text
	if objective:
		var state_text := "REPARAR OS FILTROS"
		if repaired_filters == filters.size() and defeated_drones < drones.size():
			state_text = "ELIMINAR OS DRONES"
		elif defeated_drones == drones.size() and repaired_filters < filters.size():
			state_text = "CONCLUIR OS REPAROS"
		elif mission_finished:
			state_text = "DISTRITO ESTABILIZADO"
		var remaining_drones := drones.size() - defeated_drones
		objective.text = (
			"OBJETIVO\n" + state_text
			+ "\nFILTROS: " + str(repaired_filters) + "/" + str(filters.size())
			+ "\nDRONES RESTANTES: " + str(remaining_drones)
		)
	if controls:
		controls.text = "WASD/SETAS mover   E reparar   ESPAÇO atirar"


func _draw() -> void:
	# ??reas contaminadas e sinaliza????o da miss??o.
	for puddle_position in [Vector2(420, 255), Vector2(1010, 210), Vector2(500, 625)]:
		draw_circle(puddle_position, 36.0 + sin(elapsed * 2.0) * 3.0, Color(0.34, 0.12, 0.42, 0.28))
		draw_arc(puddle_position, 29.0, 0.0, TAU, 24, Color(0.78, 0.24, 0.72, 0.65), 2.0)

	# Arma de pulso colet??vel.
	if not weapon_collected:
		var glow := 43.0 + sin(elapsed * 4.0) * 4.0
		draw_circle(weapon_position, glow, Color(1.0, 0.75, 0.22, 0.12))
		draw_arc(weapon_position, 39.0, 0.0, TAU, 32, GOLD, 3.0)
		var weapon_cell := Vector2(WEAPON_SHEET.get_width() / 4.0, WEAPON_SHEET.get_height() / 4.0)
		var weapon_source := Rect2(Vector2(weapon_cell.x, 0.0), weapon_cell)
		var weapon_target := Rect2(weapon_position - Vector2(47.0, 47.0), Vector2(94.0, 94.0))
		draw_texture_rect_region(WEAPON_SHEET, weapon_target, weapon_source)

	# Filtros que o jogador precisa reparar.
	for filter_data in filters:
		var filter_position: Vector2 = filter_data["position"]
		var repaired: bool = filter_data["repaired"]
		var filter_color := GREEN if repaired else CYAN
		draw_circle(filter_position, 29.0, Color(filter_color, 0.12))
		draw_arc(filter_position, 25.0, 0.0, TAU, 32, filter_color, 3.0)
		draw_rect(Rect2(filter_position + Vector2(-19, -13), Vector2(38, 27)), DARK)
		draw_rect(Rect2(filter_position + Vector2(-12, -7), Vector2(24, 14)), filter_color)
		draw_line(filter_position + Vector2(-8, 0), filter_position + Vector2(8, 0), Color.WHITE, 2.0)
		if not repaired:
			draw_line(filter_position + Vector2(0, -34), filter_position + Vector2(0, -25), filter_color, 3.0)
		var repair_label := "OK - " + str(filter_data["name"]) if repaired else str(filter_data["name"])
		draw_string(
			ThemeDB.fallback_font,
			filter_position + Vector2(-72, -43),
			repair_label,
			HORIZONTAL_ALIGNMENT_CENTER,
			144.0,
			14,
			filter_color
		)

	# Drones de teste.
	var drone_cell := Vector2(DRONE_SHEET.get_width() / 4.0, DRONE_SHEET.get_height() / 4.0)
	var hover_frame := int(elapsed * 6.0) % 4
	for drone_index in range(drones.size()):
		var drone = drones[drone_index]
		if not drone["active"]:
			continue
		var drone_position: Vector2 = drone["position"]
		var drone_row := drone_index % 4
		var drone_source := Rect2(Vector2(hover_frame * drone_cell.x, drone_row * drone_cell.y), drone_cell)
		var drone_target := Rect2(drone_position - Vector2(48.0, 48.0), Vector2(96.0, 96.0))
		draw_circle(drone_position, 34.0, Color(0.95, 0.2, 0.68, 0.12))
		draw_texture_rect_region(DRONE_SHEET, drone_target, drone_source)
		var health_ratio: float = float(drone["health"]) / 2.0
		draw_rect(Rect2(drone_position + Vector2(-23, -47), Vector2(46, 6)), Color(0.05, 0.08, 0.1, 0.9))
		draw_rect(Rect2(drone_position + Vector2(-23, -47), Vector2(46 * health_ratio, 6)), MAGENTA)

	# Proj??teis de energia.
	for projectile in projectiles:
		var projectile_position: Vector2 = projectile["position"]
		var projectile_direction: Vector2 = projectile["direction"]
		draw_line(projectile_position - projectile_direction * 22.0, projectile_position, CYAN, 5.0)
		draw_circle(projectile_position, 8.0, Color(0.45, 1.0, 1.0, 0.28))
		draw_circle(projectile_position, 3.0, Color.WHITE)
