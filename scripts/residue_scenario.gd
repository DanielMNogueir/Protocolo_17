extends Node2D
## Standalone playable district. State resets entirely on defeat; the water-district
## reward bridge can be connected to these stats when the full campaign is built.

const M = preload("res://scripts/residue_map.gd")
const Actors = preload("res://scripts/actors_art.gd")
const LiaAnimation = preload("res://scripts/lia_animation.gd")
const HUD = preload("res://scripts/residue_hud.gd")
const LIGHT_SHADER = preload("res://scripts/residue_lighting.gdshader")
const CYAN := Color("7be4ce")
const WHITE := Color("e9ece0")
const PINK := Color("e36b92")
const GOLD := Color("e8bd74")

var state := "play"
var pos: Vector2 = M.START
var velocity := Vector2.ZERO
var aim := Vector2.RIGHT
var camera := M.START
var pointer := Vector2.ZERO
var clock := 0.0
var hp := 6
var max_hp := 6
var stage := 0
var carried := -1
var sorted := [false, false, false, false]
var cleared := [false, false, false, false]
var terminal_on := [false, false, false]
var enemies: Array[Dictionary] = []
var bullets: Array[Dictionary] = []
var fire_cd := 0.0
var secondary_cd := 0.0
var dash_requested := false
var secondary_requested := false
var dash_cd := 0.0
var dash_time := 0.0
var invuln := 0.0
var toxic_cd := 0.0
var hold_progress := 0.0
var hold_target := ""
var bin_lock := 0.0
var interact_down := false
var toast := ""
var toast_time := 0.0
var _animation := LiaAnimation.new()
var _light: Sprite2D
var _light_material: ShaderMaterial
var _hud: Control
var difficulty := "operation"
var upgrades: Array = []
var move_speed := 205.0
var fire_interval := 0.15
var pulse_speed := 650.0
var pulse_damage := 1
var dash_recharge := 1.2

func _ready() -> void:
	_apply_handoff()
	Actors.ENEMIES.prepare()
	_setup_lighting()
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	_hud = HUD.new()
	_hud.game = self
	_hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_hud)
	_spawn_enemies()
	_set_toast("LIA: os materiais estão misturados. Vou reabrir a triagem.")

func _apply_handoff() -> void:
	if get_tree().has_meta("p17_residue_handoff"):
		var data: Dictionary = get_tree().get_meta("p17_residue_handoff")
		difficulty = data.get("difficulty", "operation")
		upgrades = data.get("upgrades", []).duplicate()
	max_hp = 9 if difficulty == "story" else (5 if difficulty == "veteran" else 6)
	if "reserve_cell" in upgrades: max_hp += 2
	if "reclaimed_armor" in upgrades: max_hp += 2
	if "living_circuit" in upgrades: max_hp += 2
	if "light_harness" in upgrades: move_speed += 25
	if "water_stride" in upgrades: move_speed += 20
	if "focused_pulse" in upgrades: fire_interval *= 0.8
	if "clean_frequency" in upgrades:
		fire_interval /= 1.2
		pulse_speed *= 1.15
	if "induction_coil" in upgrades: pulse_damage += 1
	if "efficient_dash" in upgrades: dash_recharge -= 0.25
	if "water_stride" in upgrades: dash_recharge -= 0.15
	hp = max_hp

func _setup_lighting() -> void:
	var pixel := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	pixel.fill(Color.WHITE)
	_light = Sprite2D.new()
	_light.texture = ImageTexture.create_from_image(pixel)
	_light.centered = true
	_light.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_light.scale = M.SIZE
	_light_material = ShaderMaterial.new()
	_light_material.shader = LIGHT_SHADER
	_light.material = _light_material
	add_child(_light)

func _spawn_enemies() -> void:
	enemies.clear()
	for i in M.ENEMY_POSITIONS.size():
		var boss := i == M.ENEMY_POSITIONS.size() - 1
		enemies.append({"pos": M.ENEMY_POSITIONS[i], "home": M.ENEMY_POSITIONS[i], "hp": 9 if boss else (3 if i % 2 else 2), "zone": 2 if boss else i / 2,
		"shot_cd": 1.1 + i * 0.19, "hit_cd": 0.0, "phase": 0.0, "id": i, "boss": boss})

func _physics_process(delta: float) -> void:
	var dt := minf(delta, 0.05)
	clock += dt
	pointer = get_viewport().get_mouse_position()
	if Input.is_physical_key_pressed(KEY_R) and state in ["defeat", "victory"]:
		if state == "victory": get_tree().change_scene_to_file("res://scenes/main.tscn")
		else: get_tree().reload_current_scene()
		return
	if state != "play":
		queue_redraw()
		_hud.queue_redraw()
		return
	var movement := Vector2(float(_key(KEY_D) or _key(KEY_RIGHT)) - float(_key(KEY_A) or _key(KEY_LEFT)),
		float(_key(KEY_S) or _key(KEY_DOWN)) - float(_key(KEY_W) or _key(KEY_UP))).normalized()
	var target := pointer - get_viewport_rect().size * 0.5 + camera
	if target.distance_to(pos) > 3: aim = (target - pos).normalized()
	dash_cd = maxf(0, dash_cd - dt)
	secondary_cd = maxf(0, secondary_cd - dt)
	dash_time = maxf(0, dash_time - dt)
	invuln = maxf(0, invuln - dt)
	toxic_cd = maxf(0, toxic_cd - dt)
	bin_lock = maxf(0, bin_lock - dt)
	fire_cd = maxf(0, fire_cd - dt)
	toast_time = maxf(0, toast_time - dt)
	if dash_requested and dash_cd <= 0.0 and movement != Vector2.ZERO:
		dash_time = 0.16
		dash_cd = dash_recharge
		invuln = 0.16
	dash_requested = false
	velocity = velocity.move_toward(movement * (620.0 if dash_time > 0 else move_speed), 1800 * dt)
	_move_player(velocity * dt)
	_animation.advance(dt, velocity, dash_time > 0)
	if secondary_requested and secondary_cd <= 0.0:
		_fire(target, true)
		secondary_cd = 3.8
	elif (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or _key(KEY_SPACE)) and fire_cd <= 0.0:
		_fire(target)
	secondary_requested = false
	var e_down := _key(KEY_E)
	_interact(dt, e_down, e_down and not interact_down)
	interact_down = e_down
	_update_enemies(dt)
	_update_bullets(dt)
	_check_toxic()
	camera = camera.lerp(pos + aim * 52.0, 1.0 - exp(-dt * 6.0))
	var half := get_viewport_rect().size * 0.5
	camera = camera.clamp(half, M.SIZE - half)
	_light.position = M.SIZE * 0.5 + _offset()
	_light_material.set_shader_parameter("scene_time", clock)
	_light_material.set_shader_parameter("restored", float(stage))
	queue_redraw()
	_hud.queue_redraw()

func _key(code: Key) -> bool:
	return Input.is_physical_key_pressed(code)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE:
			state = "play" if state in ["pause", "map"] else ("pause" if state == "play" else state)
			get_viewport().set_input_as_handled()
		elif event.physical_keycode == KEY_M and state in ["play", "map"]:
			state = "play" if state == "map" else "map"
			get_viewport().set_input_as_handled()
		elif event.physical_keycode == KEY_R and state == "pause":
			get_tree().reload_current_scene()
		elif event.physical_keycode == KEY_SHIFT and state == "play":
			dash_requested = true
		elif event.physical_keycode == KEY_Q and state == "play":
			secondary_requested = true

func _offset() -> Vector2:
	return (get_viewport_rect().size * 0.5 - camera).round()

func _move_player(change: Vector2) -> void:
	var next_x := pos + Vector2(change.x, 0)
	if M.walkable(next_x, 14.0, stage, cleared): pos.x = next_x.x
	var next_y := pos + Vector2(0, change.y)
	if M.walkable(next_y, 14.0, stage, cleared): pos.y = next_y.y

func _fire(target: Vector2, secondary: bool = false) -> void:
	fire_cd = fire_interval
	var start := pos + aim * 27.0
	bullets.append({"pos": start, "vel": aim * pulse_speed, "hostile": false, "life": 1.25, "damage": pulse_damage})
	if secondary:
		for spread in [-0.22, -0.11, 0.11, 0.22]:
			bullets.append({"pos": start, "vel": aim.rotated(spread) * pulse_speed, "hostile": false, "life": 1.1, "damage": pulse_damage})
		fire_cd = 0.55

func _interact(dt: float, held: bool, pressed: bool) -> void:
	var candidate := _interaction_candidate()
	if candidate.is_empty():
		hold_progress = 0.0
		hold_target = ""
		return
	var kind: String = candidate.kind
	var index: int = candidate.index
	if kind == "item" and pressed and carried < 0:
		carried = index
		_set_toast("MATERIAL COLETADO  /  " + M.MATERIALS[index])
	elif kind == "bin" and pressed and carried >= 0:
		if bin_lock > 0.0:
			_set_toast("BAIAS TRAVADAS  /  AGUARDE A REINICIALIZAÇÃO")
			return
		if carried == index:
			sorted[index] = true
			carried = -1
			_set_toast("CLASSIFICAÇÃO CORRETA  /  " + M.MATERIALS[index])
		else:
			carried = -1
			bin_lock = 2.4
			_spawn_alarm_drone()
			_set_toast("BAIA INCORRETA  /  TRAVA TEMPORÁRIA  /  DRONE ALERTADO")
		return
	if kind not in ["block", "terminal"]: return
	var id := kind + str(index)
	if not held:
		hold_progress = 0.0
		hold_target = ""
		return
	if id != hold_target:
		hold_progress = 0.0
		hold_target = id
	hold_progress = minf(1.0, hold_progress + dt / (0.85 if kind == "block" else 1.4))
	if hold_progress < 1.0: return
	hold_progress = 0.0
	hold_target = ""
	if kind == "block":
		cleared[index] = true
		_set_toast("ROTA DE CARGA LIBERADA")
	else:
		terminal_on[index] = true
		stage += 1
		if stage == 3:
			state = "victory"
		else:
			_set_toast("SISTEMA RESTAURADO  /  PRÓXIMA ÁREA LIBERADA")

func _spawn_alarm_drone() -> void:
	var active := 0
	for enemy in enemies:
		if enemy.get("alarm", false) and enemy.hp > 0: active += 1
	if active >= 2: return
	var location := Vector2(695, 475) if active == 0 else Vector2(545, 475)
	enemies.append({"pos": location, "home": location, "hp": 2, "zone": 0,
		"shot_cd": 0.5, "hit_cd": 0.0, "phase": 0.0, "id": enemies.size(), "boss": false, "alarm": true})

func _interaction_candidate() -> Dictionary:
	var candidates: Array[Dictionary] = []
	if stage == 0:
		if carried < 0:
			for i in 4:
				if not sorted[i]: candidates.append({"kind": "item", "index": i, "pos": M.ITEMS[i], "reach": 51.0})
		else:
			for i in 4:
				candidates.append({"kind": "bin", "index": i, "pos": M.BINS[i] + Vector2(0, 60), "reach": 82.0})
	if stage == 1:
		for i in 2:
			if not cleared[i]: candidates.append({"kind": "block", "index": i, "pos": M.BLOCKS[i], "reach": 86.0})
	if stage == 2:
		for i in range(2, 4):
			if not cleared[i]: candidates.append({"kind": "block", "index": i, "pos": M.BLOCKS[i], "reach": 86.0})
	if stage < 3 and _terminal_ready(stage):
		candidates.append({"kind": "terminal", "index": stage, "pos": M.TERMINALS[stage], "reach": 81.0})
	var closest := {}
	var best := INF
	for candidate in candidates:
		var distance := pos.distance_to(candidate.pos)
		if distance <= candidate.reach and distance < best:
			closest = candidate
			best = distance
	return closest

func _terminal_ready(index: int) -> bool:
	if index == 0:
		for value in sorted:
			if not value: return false
	if index == 1 and not (cleared[0] and cleared[1]): return false
	if index == 2 and not (cleared[2] and cleared[3]): return false
	for enemy in enemies:
		if enemy.zone == index and enemy.hp > 0: return false
	return true

func objective_label() -> String:
	if stage == 3: return "SISTEMAS RESTAURADOS"
	if stage == 0:
		if carried >= 0: return "ENTREGAR " + M.MATERIALS[carried] + " NA BAIA CORRETA"
		for value in sorted:
			if not value: return "CLASSIFICAR OS QUATRO MATERIAIS  /  E"
	if stage == 1 and not (cleared[0] and cleared[1]): return "DESOBSTRUIR A ROTA DA PRENSA  /  SEGURE E"
	if stage == 2 and not (cleared[2] and cleared[3]): return "REABRIR OS DUTOS ORGÂNICOS  /  SEGURE E"
	for enemy in enemies:
		if enemy.zone == stage and enemy.hp > 0:
			return "DERROTAR A COLETORA PESADA" if enemy.boss else "NEUTRALIZAR DRONES DE COLETA"
	return "RESTAURAR O TERMINAL  /  SEGURE E"

func objective_point() -> Vector2:
	if stage == 3: return M.TERMINALS[2]
	if stage == 0:
		if carried >= 0: return M.BINS[carried] + Vector2(0, 60)
		for i in 4:
			if not sorted[i]: return M.ITEMS[i]
	if stage == 1:
		for i in 2:
			if not cleared[i]: return M.BLOCKS[i]
	if stage == 2:
		for i in range(2, 4):
			if not cleared[i]: return M.BLOCKS[i]
	for enemy in enemies:
		if enemy.zone == stage and enemy.hp > 0: return enemy.pos
	return M.TERMINALS[stage]

func _update_enemies(dt: float) -> void:
	for i in enemies.size():
		var enemy: Dictionary = enemies[i]
		if enemy.hp <= 0 or enemy.zone > stage: continue
		enemy.hit_cd = maxf(0.0, enemy.hit_cd - dt)
		enemy.shot_cd -= dt
		enemy.phase += dt
		var distance: float = enemy.pos.distance_to(pos)
		if distance < 420 and distance > (145.0 if enemy.boss else 125.0):
			var desired: Vector2 = enemy.pos + (pos - enemy.pos).normalized() * (35.0 if enemy.boss else 54.0) * dt
			if M.walkable(desired, 25.0 if enemy.boss else 18.0, stage, cleared): enemy.pos = desired
		if distance < 440 and enemy.shot_cd <= 0.0:
			var direction: Vector2 = (pos - enemy.pos).normalized()
			var spreads := [-0.20, 0.0, 0.20] if enemy.boss else [0.0]
			for spread in spreads:
				bullets.append({"pos": enemy.pos + direction * 28, "vel": direction.rotated(spread) * (260.0 if enemy.boss else 235.0), "hostile": true, "life": 2.2})
			enemy.shot_cd = 1.35 if enemy.boss else 1.55 + (i % 3) * 0.31
		enemies[i] = enemy

func _update_bullets(dt: float) -> void:
	for i in range(bullets.size() - 1, -1, -1):
		var bullet: Dictionary = bullets[i]
		bullet.pos += bullet.vel * dt
		bullet.life -= dt
		var gone: bool = bullet.life <= 0.0 or not M.walkable(bullet.pos, 3.0, stage, cleared)
		if not gone and bullet.hostile:
			if bullet.pos.distance_to(pos) < 16 and invuln <= 0.0:
				_damage()
				gone = true
		elif not gone:
			for j in enemies.size():
				var enemy: Dictionary = enemies[j]
				if enemy.hp > 0 and enemy.zone <= stage and bullet.pos.distance_to(enemy.pos) < (32.0 if enemy.boss else 22.0):
					enemy.hp -= bullet.damage
					enemy.hit_cd = 0.18
					enemies[j] = enemy
					gone = true
					break
		if gone: bullets.remove_at(i)
		else: bullets[i] = bullet

func _check_toxic() -> void:
	if toxic_cd > 0.0: return
	for pool in M.TOXIC:
		if pool.has_point(pos):
			_damage()
			toxic_cd = 1.15
			break

func _damage() -> void:
	if invuln > 0.0: return
	hp -= 1
	invuln = 0.68
	if hp <= 0:
		state = "defeat"
		_set_toast("O distrito será reiniciado; Águas permanece recuperado.")

func _set_toast(message: String) -> void:
	toast = message
	toast_time = 3.6

func _draw() -> void:
	var offset := _offset()
	draw_set_transform(offset)
	M.draw_map(self, clock, stage, sorted, cleared, terminal_on, carried)
	var depth_entries: Array[Dictionary] = []
	for machine in M.major_machines():
		depth_entries.append({"kind": "machine", "depth": machine.depth, "data": machine})
	for enemy in enemies:
		if enemy.hp <= 0 or enemy.zone > stage: continue
		depth_entries.append({"kind": "enemy", "depth": enemy.pos.y + 18.0, "data": enemy})
	depth_entries.append({"kind": "lia", "depth": pos.y + 18.0})
	depth_entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.depth < b.depth)
	for entry in depth_entries:
		match entry.kind:
			"machine": M.draw_major_machine(self, entry.data)
			"enemy": _draw_enemy(entry.data)
			"lia": _draw_lia()
	for bullet in bullets:
		var color := PINK if bullet.hostile else CYAN
		draw_line(bullet.pos - bullet.vel.normalized() * 14, bullet.pos, Color(color, 0.45), 6)
		draw_circle(bullet.pos, 4 if bullet.hostile else 5, color)
	for i in 3:
		if i < stage: continue
		var marker: Vector2 = M.TERMINALS[i]
		draw_arc(marker, 59, 0, TAU, 36, Color(CYAN if _terminal_ready(i) else GOLD, 0.45), 2)
	var candidate := _interaction_candidate()
	if not candidate.is_empty():
		var p: Vector2 = candidate.pos
		draw_arc(p, 50, 0, TAU, 30, Color(CYAN, 0.64), 2)
		draw_string(ThemeDB.fallback_font, p + Vector2(-6, -55), "E", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, WHITE)
	draw_set_transform(Vector2.ZERO)

func _draw_lia() -> void:
	var action := "repair" if hold_progress > 0 else ("fire" if fire_cd > 0 else "idle")
	Actors.draw_lia(self, pos, aim, _animation.elapsed, _animation.moving, invuln > 0 and int(clock * 16) % 2 == 0, dash_time > 0, action, 0.05 if fire_cd > 0 else -1.0)
	if carried >= 0:
		var c: Color = M.MATERIAL_COLORS[carried]
		draw_rect(Rect2(pos + Vector2(-9, -49), Vector2(18, 15)), c)
		draw_rect(Rect2(pos + Vector2(-10, -50), Vector2(20, 17)), Color("142b35"), false, 2)

func _draw_enemy(enemy: Dictionary) -> void:
	var p: Vector2 = enemy.pos
	var hit: bool = enemy.hit_cd > 0.0
	if enemy.boss:
		_draw_collector(enemy)
		return
	draw_circle(p + Vector2(4, 17), 23, Color("091d25", 0.5))
	draw_rect(Rect2(p - Vector2(24, 16), Vector2(48, 35)), Color("152f3b"))
	draw_rect(Rect2(p - Vector2(18, 13), Vector2(36, 27)), Color("9a5a66") if hit else Color("657c78"))
	draw_rect(Rect2(p - Vector2(13, 8), Vector2(26, 10)), Color("253e48"))
	draw_rect(Rect2(p - Vector2(7, 6), Vector2(14, 6)), PINK)
	for side in [-1, 1]:
		var x: float = p.x + side * 27
		draw_rect(Rect2(x - 6, p.y - 10, 12, 19), Color("34525b"))
		draw_rect(Rect2(x - 9, p.y - 1, 18, 4), Color("9d7b59"))
	for j in 2:
		draw_rect(Rect2(p.x - 14 + j * 27, p.y + 15, 9, 5), Color("263f47"))
	draw_rect(Rect2(p - Vector2(20, 30), Vector2(40 * enemy.hp / 3.0, 3)), PINK)
	if enemy.shot_cd < 0.27:
		draw_arc(p, 29 + sin(clock * 12) * 2, 0, TAU, 24, Color(PINK, 0.5), 2)

func _draw_collector(enemy: Dictionary) -> void:
	var p: Vector2 = enemy.pos
	draw_circle(p + Vector2(4, 25), 38, Color("1d1e22", 0.65))
	draw_rect(Rect2(p - Vector2(36, 25), Vector2(72, 55)), Color("252629"))
	draw_rect(Rect2(p - Vector2(30, 20), Vector2(60, 40)), Color("756b60") if enemy.hit_cd <= 0 else PINK)
	draw_rect(Rect2(p - Vector2(23, 15), Vector2(46, 21)), Color("3b3837"))
	for j in 4:
		draw_rect(Rect2(p + Vector2(-20 + j * 12, -12), Vector2(5, 15)), Color("c29658"))
	for side in [-1, 1]:
		var anchor := p + Vector2(side * 31, 5)
		draw_rect(Rect2(anchor - Vector2(10, 17), Vector2(20, 36)), Color("373738"))
		draw_line(anchor + Vector2(side * 8, 9), anchor + Vector2(side * 25, 24), Color("bb8751"), 6)
		draw_rect(Rect2(anchor + Vector2(side * 18 - 4, 23), Vector2(12, 8)), Color("262426"))
	draw_rect(Rect2(p - Vector2(11, 20), Vector2(22, 8)), PINK)
	draw_rect(Rect2(p - Vector2(36, 39), Vector2(72, 6)), Color("2c2529"))
	draw_rect(Rect2(p - Vector2(35, 38), Vector2(70 * enemy.hp / 9.0, 4)), PINK)
	if enemy.shot_cd < 0.3: draw_arc(p, 43, 0, TAU, 32, Color(PINK, 0.67), 3)
