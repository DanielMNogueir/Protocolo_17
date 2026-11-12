extends Node2D
## Distrito de Energia — Operação Corrente. The district starts in blackout.
## Three installations each teach a mechanic: the Central Solar (mirrors shot
## into alignment, then Sobrecarga v2), the Torre Norte (rhythmic arc pylons,
## relays charged by pulses, a surging Sobrecarga) and the Banco de Baterias
## (hold the ring while venting cells). Restoring all three opens the Elevador
## do Núcleo. Rules live in power_mechanics.gd; geometry in power_map.gd.

const M = preload("res://scripts/power_map.gd")
const Art = preload("res://scripts/power_art.gd")
const Mechanics = preload("res://scripts/power_mechanics.gd")
const Story = preload("res://scripts/power_story.gd")
const Actors = preload("res://scripts/actors_art.gd")
const LiaAnimation = preload("res://scripts/lia_animation.gd")
const LIA_POSE = preload("res://scripts/lia_directional.gd")
const HUD = preload("res://scripts/power_hud.gd")
const LIGHT_SHADER = preload("res://scripts/power_lighting.gdshader")
const Sound = preload("res://scripts/audio.gd")
const Simulation = preload("res://scripts/simulation.gd")
const CampaignProgress = preload("res://scripts/campaign_progress.gd")
const Loadout = preload("res://scripts/campaign_loadout.gd")
const CYAN := Color("7be4ce")
const WHITE := Color("e9ece0")
const PINK := Color("e36b92")
const GOLD := Color("e8bd74")
const ELECTRIC := Color("9fe9ff")
const SUN := Color("fff1c4")
const PRESSURE := {"story": 1.25, "operation": 1.0, "veteran": 0.77}
const WINDUP := {"story": 1.3, "operation": 1.0, "veteran": 0.85}
const ARC_PERIOD := {"story": 3.2, "operation": 2.6, "veteran": 2.2}
const ENEMY_RADIUS := {"scout": 17.0, "sentry": 20.0, "spark": 16.0, "coil": 18.0, "transformer": 26.0}
const ENEMY_SPEED := {"scout": 90.0, "sentry": 68.0, "spark": 118.0}
const PREFERRED := {"scout": [165.0, 110.0], "sentry": [230.0, 160.0], "spark": [200.0, 120.0]}
const SHIELD_RADIUS := 260.0
const COIL_LINK := 320.0
const WAVES := [["scout", "scout"], ["spark", "sentry"], ["spark", "spark", "scout"], ["sentry", "spark"]]

## Effects and glows drawn above the blackout layer.
class FxLayer extends Node2D:
	var game: Node2D
	func _draw() -> void:
		if game != null: game._draw_fx(self)

var state := "dialogue"
var after_dialogue := "play"
var dialogue: Array = []
var dialogue_chars := 0.0
var dialogue_fast := false
var buttons: Array[Dictionary] = []
var pos: Vector2 = M.START
var velocity := Vector2.ZERO
var aim := Vector2.RIGHT
var camera: Vector2 = M.START
var pointer := Vector2.ZERO
var clock := 0.0
var elapsed := 0.0
var hp := 6
var max_hp := 6
var stage := 0
var restored_light := 0.0
var enemies: Array[Dictionary] = []
var bullets: Array[Dictionary] = []
var trails: Array[Dictionary] = []
var effects: Array[Dictionary] = []
var kills := 0
var shots := 0
var fire_cd := 0.0
var secondary_cd := 0.0
var dash_requested := false
var secondary_requested := false
var _map_mouse_held := false
var dash_cd := 0.0
var dash_time := 0.0
var invuln := 0.0
var shock_debt := 0.0
var hold_progress := 0.0
var hold_target := ""
var interact_down := false
var toast := ""
var toast_time := 0.0
var toast_ai := false
var flash := 0.0
var shake := 0.0
var collision_audit := false
## Draws only the static background, for the art reference plates.
var plate_mode := false
var difficulty := "operation"
var upgrades: Array = []
var loadout := Loadout.new()
var move_speed := 205.0
var fire_interval := 0.145
var pulse_speed := 640.0
var pulse_damage := 1
var dash_recharge := 1.2
var guidance_path := PackedVector2Array()
var _guide_timer := 0.0
var _guide_target := Vector2.INF
var sound: Node
var _muted := false
var campaign := CampaignProgress.new()
var victory_notice := ""
var overloads: Array = []
var mirrors: Mechanics.Mirrors = Mechanics.Mirrors.new()
var relays: Mechanics.Relays
var battery: Mechanics.Battery
var arcs: Array = []
var _taunts: Dictionary = {}
var _arc_hit_cd := 0.0
var _animation := LiaAnimation.new()
var _light: Sprite2D
var _light_material: ShaderMaterial
var _fx: FxLayer
var _hud: Node2D

func _ready() -> void:
	_apply_handoff()
	sound = Sound.new()
	add_child(sound)
	var settings := ConfigFile.new()
	if settings.load("user://settings.cfg") == OK:
		_muted = settings.get_value("audio", "muted", false)
		dialogue_fast = settings.get_value("narrative", "instant_prologue_text", false)
	sound.set_muted(_muted)
	sound.set_mood("blackout")
	Actors.ENEMIES.prepare()
	overloads = [Mechanics.Overload.new(difficulty, loadout.timing_scale, "steady"), Mechanics.Overload.new(difficulty, loadout.timing_scale, "surge")]
	relays = Mechanics.Relays.new(difficulty, loadout.timing_scale)
	battery = Mechanics.Battery.new(difficulty, loadout.timing_scale)
	for i in M.ARCS.size():
		var data: Array = M.ARCS[i]
		var period: float = ARC_PERIOD[difficulty] * (float(data[2]) / 2.6)
		arcs.append(Mechanics.ArcPair.new(M.w(data[0]), M.w(data[1]), period, float(data[3]) * period / float(data[2])))
	_setup_layers()
	_spawn_enemies()
	M.prepare_navigation()
	camera = pos.clamp(get_viewport_rect().size * 0.5, M.SIZE - get_viewport_rect().size * 0.5)
	_start_dialogue(Story.INTRO, "play")

func _apply_handoff() -> void:
	campaign.load_progress()
	if get_tree().has_meta("p17_power_handoff"):
		var data: Dictionary = get_tree().get_meta("p17_power_handoff")
		difficulty = data.get("difficulty", "operation")
		upgrades = data.get("upgrades", []).duplicate()
	elif campaign.residues_completed:
		var data := campaign.energy_loadout(campaign.difficulty)
		difficulty = data.difficulty
		upgrades = data.upgrades
	loadout.configure(difficulty, upgrades)
	difficulty = loadout.difficulty
	max_hp = loadout.max_hp
	move_speed = loadout.move_speed
	fire_interval = loadout.fire_interval
	pulse_speed = loadout.pulse_speed
	pulse_damage = loadout.pulse_damage
	dash_recharge = loadout.dash_recharge
	hp = max_hp

func _setup_layers() -> void:
	var pixel := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	pixel.fill(Color.WHITE)
	_light = Sprite2D.new()
	_light.texture = ImageTexture.create_from_image(pixel)
	# Anchored at its top-left: with 2D pixel snapping a centred 1×1 sprite is
	# floored to offset (0, 0), which would shift the overlay by half the map.
	_light.centered = false
	_light.scale = M.SIZE
	_light_material = ShaderMaterial.new()
	_light_material.shader = LIGHT_SHADER
	_light_material.set_shader_parameter("map_size", M.SIZE)
	_light.material = _light_material
	add_child(_light)
	_fx = FxLayer.new()
	_fx.game = self
	add_child(_fx)
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	_hud = HUD.new()
	_hud.game = self
	_hud.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	layer.add_child(_hud)

func _spawn_enemies() -> void:
	enemies.clear()
	var layout: Array = M.ENEMIES.duplicate()
	var extras := {"story": 0, "operation": 2, "veteran": 4}.get(difficulty, 2) as int
	for i in extras: layout.append(M.EXTRA_ENEMIES[i])
	for entry in layout: _add_enemy(entry[0], M.w(entry[1]), entry[2], false)

func _add_enemy(kind: String, at: Vector2, zone: int, warped: bool) -> void:
	var health := 8
	match kind:
		"scout", "sentry": health = Simulation.enemy_health(kind, 3)
		"coil": health = 16
		"transformer": health = {"story": 14, "operation": 18, "veteran": 22}[difficulty]
	enemies.append({"id": enemies.size(), "kind": kind, "pos": at, "zone": zone, "hp": health, "max_hp": health,
		"radius": ENEMY_RADIUS[kind], "cooldown": 1.2 + enemies.size() * 0.23, "phase": "spawn" if warped else "idle",
		"timer": 0.7 if warped else 0.0, "aim": Vector2.DOWN, "facing": Vector2.DOWN, "attacks": 0, "hit_cd": 0.0,
		"engaged": warped, "anim_time": float(enemies.size()) * 0.37, "attack_age": 99.0, "death_age": -1.0,
		"arc_cd": 0.0, "moving": false, "warning": 0.0})

# ---------------------------------------------------------------- main loop

func _physics_process(delta: float) -> void:
	var dt := minf(delta, 0.05)
	clock += dt
	pointer = get_viewport().get_mouse_position()
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT): _map_mouse_held = false
	flash = maxf(0.0, flash - dt * 2.2)
	shake = maxf(0.0, shake - dt * 18.0)
	restored_light = move_toward(restored_light, float(stage), dt * 0.7)
	_update_audio()
	_update_effects(dt)
	if state == "dialogue":
		dialogue_chars += dt * (400.0 if dialogue_fast else 46.0)
	if state != "play":
		_present(dt)
		return
	elapsed += dt
	var movement := Vector2(float(_key(KEY_D) or _key(KEY_RIGHT)) - float(_key(KEY_A) or _key(KEY_LEFT)),
		float(_key(KEY_S) or _key(KEY_DOWN)) - float(_key(KEY_W) or _key(KEY_UP))).normalized()
	var target := pointer - get_viewport_rect().size * 0.5 + camera
	if target.distance_to(pos) > 3: aim = (target - pos).normalized()
	dash_cd = maxf(0, dash_cd - dt)
	secondary_cd = maxf(0, secondary_cd - dt)
	dash_time = maxf(0, dash_time - dt)
	invuln = maxf(0, invuln - dt)
	fire_cd = maxf(0, fire_cd - dt)
	toast_time = maxf(0, toast_time - dt)
	_arc_hit_cd = maxf(0, _arc_hit_cd - dt)
	if dash_requested and dash_cd <= 0.0 and movement != Vector2.ZERO:
		dash_time = 0.16
		dash_cd = dash_recharge
		invuln = maxf(invuln, 0.16)
		sound.play_sfx("dash")
	dash_requested = false
	velocity = velocity.move_toward(movement * (650.0 if dash_time > 0 else move_speed), 1800 * dt)
	var previous := pos
	_move_player(velocity * dt)
	_animation.advance(dt, (pos - previous) / dt, dash_time > 0)
	if secondary_requested and secondary_cd <= 0.0:
		_fire(target, true)
		secondary_cd = loadout.secondary_recharge
	elif ((Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not _map_mouse_held) or _key(KEY_SPACE)) and fire_cd <= 0.0:
		_fire(target)
	secondary_requested = false
	var e_down := _key(KEY_E)
	_interact(dt, e_down, e_down and not interact_down)
	interact_down = e_down
	tick_world(dt)
	_guide_timer -= dt
	_update_guidance()
	_present(dt)

## Everything that advances with time while playing; tests call it directly.
func tick_world(dt: float) -> void:
	for overload in overloads: overload.tick(dt)
	mirrors.tick(dt)
	if stage == 0 and not mirrors.solved and mirrors.update_solved(): _on_mirrors_solved()
	relays.tick(dt)
	_update_battery(dt)
	_update_arcs(dt)
	_update_enemies(dt)
	_update_bullets(dt)
	_update_trails(dt)
	_check_taunts()

func _present(dt: float) -> void:
	var half := get_viewport_rect().size * 0.5
	if state == "play":
		camera = camera.lerp(pos + aim * 52.0, 1.0 - exp(-dt * 6.0))
	camera = camera.clamp(half, M.SIZE - half)
	_light.position = _offset()
	_light_material.set_shader_parameter("scene_time", clock)
	_light_material.set_shader_parameter("restored", restored_light)
	_light_material.set_shader_parameter("lia_pos", pos)
	_light_material.set_shader_parameter("aim", aim)
	_light_material.set_shader_parameter("flash", clampf(flash, 0.0, 1.0) * 0.8)
	var lights := _dynamic_lights()
	_light_material.set_shader_parameter("lights", lights)
	_light_material.set_shader_parameter("light_count", lights.size())
	queue_redraw()
	_fx.queue_redraw()
	_hud.queue_redraw()

func _key(code: Key) -> bool:
	return Input.is_physical_key_pressed(code)

# ---------------------------------------------------------------- input

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for button in buttons:
			if button.rect.has_point(event.position):
				_map_mouse_held = true
				get_viewport().set_input_as_handled()
				_action(button.id)
				return
	if state == "map" and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and HUD.MapUI.close_rect(get_viewport_rect().size).has_point(event.position):
		state = "play"
		_map_mouse_held = true
		_clear_pending_actions()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT and state == "play":
		secondary_requested = true
		get_viewport().set_input_as_handled()
		return
	if not (event is InputEventKey and event.pressed and not event.echo): return
	var key: Key = event.physical_keycode
	if state == "dialogue":
		if key in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_E]: _action("intro_next")
		elif key == KEY_TAB: _action("intro_fast")
		elif key == KEY_ESCAPE: _finish_dialogue()
		get_viewport().set_input_as_handled()
		return
	match key:
		KEY_ESCAPE:
			_clear_pending_actions()
			state = "play" if state in ["pause", "map"] else ("pause" if state == "play" else state)
		KEY_M:
			if state in ["play", "map"]:
				_clear_pending_actions()
				state = "play" if state == "map" else "map"
		KEY_R:
			if state in ["pause", "defeat"]: get_tree().reload_current_scene()
		KEY_B:
			if state in ["pause", "victory", "defeat"]: _return_to_districts()
		KEY_SHIFT:
			if state == "play": dash_requested = true
		KEY_Q:
			if state == "play": secondary_requested = true
		KEY_F10:
			_muted = not _muted
			sound.set_muted(_muted)
		KEY_F11:
			var fullscreen := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if fullscreen else DisplayServer.WINDOW_MODE_FULLSCREEN)
	get_viewport().set_input_as_handled()

func _clear_pending_actions() -> void:
	dash_requested = false
	secondary_requested = false
	interact_down = true
	hold_progress = 0.0
	hold_target = ""

func _action(id: String) -> void:
	_clear_pending_actions()
	match id:
		"map": state = "map"
		"pause": state = "pause"
		"resume": state = "play"
		"retry": get_tree().reload_current_scene()
		"districts": _return_to_districts()
		"intro_next": _advance_dialogue()
		"intro_fast":
			dialogue_fast = not dialogue_fast
	queue_redraw()

func _return_to_districts() -> void:
	get_tree().set_meta("p17_open_districts", true)
	if get_tree().has_meta("p17_power_handoff"): get_tree().remove_meta("p17_power_handoff")
	get_tree().change_scene_to_file("res://scenes/main.tscn")

# ---------------------------------------------------------------- dialogue

func _start_dialogue(lines: Array, next_state: String) -> void:
	dialogue = lines.duplicate()
	dialogue_chars = 0.0
	after_dialogue = next_state
	state = "dialogue"
	_clear_pending_actions()

func dialogue_line() -> Dictionary:
	return dialogue[0] if not dialogue.is_empty() else {}

func dialogue_complete() -> bool:
	return not dialogue.is_empty() and dialogue_chars >= float(str(dialogue[0].text).length())

func _advance_dialogue() -> void:
	if state != "dialogue": return
	if not dialogue_complete():
		dialogue_chars = 9999.0
		return
	dialogue.pop_front()
	dialogue_chars = 0.0
	sound.play_sfx("ui")
	if dialogue.is_empty(): _finish_dialogue()

func _finish_dialogue() -> void:
	dialogue.clear()
	state = after_dialogue
	if state == "victory": _complete_campaign()
	_clear_pending_actions()

# ---------------------------------------------------------------- player

func _offset() -> Vector2:
	var jitter := Vector2(sin(clock * 91.0), cos(clock * 77.0)) * shake
	return (get_viewport_rect().size * 0.5 - camera + jitter).round()

func _move_player(change: Vector2) -> void:
	pos = M.slide(pos, change, 14.0, stage)

func _fire(target: Vector2, secondary: bool = false) -> void:
	fire_cd = fire_interval
	sound.play_sfx("shoot")
	var start: Vector2 = pos + LIA_POSE.pose(aim, _animation.elapsed, _animation.moving).muzzle
	if not M.line_clear(pos, start, 3.0, stage): return
	shots += 1
	var direction := (target - start).normalized() if target.is_finite() and target.distance_squared_to(start) > 1.0 else aim
	if secondary:
		for index in 5:
			bullets.append({"pos": start, "source": start, "vel": direction.rotated(float(index - 2) * 0.12) * pulse_speed * 0.85, "hostile": false, "life": 1.2, "damage": pulse_damage + 1})
	else:
		bullets.append({"pos": start, "source": start, "vel": direction * pulse_speed, "hostile": false, "life": 1.7, "damage": pulse_damage})

func shot_age() -> float:
	return fire_interval - fire_cd if fire_cd > 0.0 else -1.0

## Electrical damage honours Isolamento (half damage through a debt counter).
func _damage(shock: bool = false) -> void:
	if invuln > 0.0 or state != "play": return
	if shock:
		shock_debt += loadout.shock_factor
		_burst(pos + Vector2(0, -10), ELECTRIC, 10)
		if shock_debt < 1.0:
			invuln = 0.55
			sound.play_sfx("shield")
			return
		shock_debt -= 1.0
	sound.play_sfx("hurt")
	hp -= 1
	invuln = 0.8
	shake = maxf(shake, 4.0)
	if hp <= 0:
		hp = 0
		state = "defeat"
		_set_toast("A rede desligou Lia. O distrito será reiniciado; os módulos permanecem.")

func _set_toast(message: String, from_ai: bool = false) -> void:
	toast = message
	toast_time = 3.8
	toast_ai = from_ai

# ---------------------------------------------------------------- interaction

func _interact(dt: float, held: bool, pressed: bool) -> void:
	var candidate := interaction_candidate()
	for i in overloads.size():
		if overloads[i].running and (candidate.is_empty() or candidate.kind != "terminal" or candidate.index != i): overloads[i].cancel()
	if candidate.is_empty():
		hold_progress = 0.0
		hold_target = ""
		return
	match candidate.kind:
		"terminal":
			if pressed: _press_overload(candidate.index)
		"console":
			if pressed and battery.vent(candidate.index):
				sound.play_sfx("vent")
				_burst(M.w(M.CELL_CONSOLES[candidate.index]) + Vector2(0, -50), CYAN, 14)
		"elevator":
			if not held:
				hold_progress = 0.0
				hold_target = ""
				return
			hold_target = "elevator"
			hold_progress = minf(1.0, hold_progress + dt / 1.1)
			if hold_progress >= 1.0:
				hold_progress = 0.0
				hold_target = ""
				sound.play_sfx("power_up")
				_start_dialogue(Story.ELEVATOR, "victory")

func _press_overload(index: int) -> void:
	var overload = overloads[index]
	var result: String = overload.press()
	match result:
		"start": sound.play_sfx("overload_start")
		"hit":
			sound.play_sfx("pulse_hit")
			_burst(M.w(M.TERMINALS[index]) + Vector2(0, -42), CYAN, 8)
		"done": _restore(index)
		"discharge":
			sound.play_sfx("discharge")
			flash = maxf(flash, 0.55)
			shake = maxf(shake, 6.0)
			effects.append({"kind": "bolt", "a": M.w(M.TERMINALS[index]) + Vector2(0, -42), "b": pos + Vector2(0, -12), "life": 0.35, "max": 0.35})
			invuln = 0.0
			_damage(true)
			for enemy in enemies:
				if enemy.zone == stage and enemy.hp > 0: enemy.engaged = true
			_set_toast(Story.AI_TAUNTS.discharge if not _taunts.has("discharge") else "DESCARGA  /  CONSOLE TRAVADO POR 3 s", not _taunts.has("discharge"))
			_taunts["discharge"] = true

func interaction_candidate() -> Dictionary:
	var candidates: Array[Dictionary] = []
	if stage < 2 and terminal_ready(stage):
		candidates.append({"kind": "terminal", "index": stage, "pos": M.w(M.TERMINALS[stage]), "reach": 78.0, "body": "terminal %d" % stage})
	if stage == 2 and battery.started and not battery.done:
		for i in 3: candidates.append({"kind": "console", "index": i, "pos": M.w(M.CELL_CONSOLES[i]), "reach": 70.0, "body": "console %d" % i})
	if stage == 3: candidates.append({"kind": "elevator", "index": 0, "pos": M.w(M.ELEVATOR), "reach": 80.0, "body": "porta do elevador"})
	var closest := {}
	var best := INF
	for candidate in candidates:
		var distance := pos.distance_to(candidate.pos)
		if distance <= candidate.reach and distance < best and M.line_clear(pos, candidate.pos, 0.5, stage, candidate.body):
			closest = candidate
			best = distance
	return closest

func zone_alive(zone: int) -> int:
	var count := 0
	for enemy in enemies:
		if enemy.zone == zone and enemy.hp > 0: count += 1
	return count

func terminal_ready(index: int) -> bool:
	if index == 0 and not mirrors.solved: return false
	if index == 1 and not relays.solved: return false
	return zone_alive(index) == 0 and overloads[index].available()

func _on_mirrors_solved() -> void:
	sound.play_sfx("power_up")
	flash = maxf(flash, 0.25)
	_set_toast("FEIXE ALINHADO  /  COLETOR SOLAR CARREGADO")

func _restore(index: int) -> void:
	stage = index + 1
	sound.play_sfx("complete")
	sound.play_sfx("power_up")
	flash = 0.9
	shake = 5.0
	_burst(M.w(M.TERMINALS[index]) + Vector2(0, -42), CYAN, 26)
	_guide_timer = 0.0
	_start_dialogue(Story.SOLAR if index == 0 else Story.TOWER, "play")

func _update_battery(dt: float) -> void:
	if stage != 2: return
	var inside := pos.distance_to(M.w(M.RING_CENTER)) < M.RING_RADIUS * M.SCALE
	for event in battery.tick(dt, inside and state == "play"):
		if event == "start":
			sound.play_sfx("overload_start")
			_set_toast(Story.AI_TAUNTS.battery, true)
		elif event.begins_with("wave:"):
			_spawn_wave(int(event.trim_prefix("wave:")))
		elif event.begins_with("overload:"):
			var cell := int(event.trim_prefix("overload:"))
			var top := M.w(M.CELL_CONSOLES[cell]) + Vector2(0, -60)
			sound.play_sfx("discharge")
			flash = maxf(flash, 0.4)
			effects.append({"kind": "bolt", "a": top, "b": M.w(M.RING_CENTER), "life": 0.4, "max": 0.4})
			if inside:
				invuln = 0.0
				_damage(true)
			_set_toast("CÉLULA %d SOBRECARREGADA  /  CARGA PERDIDA" % (cell + 1))
		elif event == "done":
			_battery_complete()

func _spawn_wave(index: int) -> void:
	var kinds: Array = WAVES[index].duplicate()
	if difficulty == "story" and kinds.size() > 1: kinds.pop_back()
	if difficulty == "veteran": kinds.append("scout")
	for i in kinds.size():
		var spawn: Vector2 = M.w(M.WAVE_SPAWNS[(index + i) % M.WAVE_SPAWNS.size()])
		_add_enemy(kinds[i], spawn, 2, true)
		effects.append({"kind": "warp", "pos": spawn, "life": 0.7, "max": 0.7})
	sound.play_sfx("relay")

func _battery_complete() -> void:
	stage = 3
	sound.play_sfx("emp")
	sound.play_sfx("complete")
	flash = 1.0
	shake = 8.0
	effects.append({"kind": "emp", "pos": M.w(M.RING_CENTER), "life": 1.1, "max": 1.1})
	# The restored grid reclaims every drone that still answered to the AI here.
	for enemy in enemies:
		if enemy.zone == 2 and enemy.hp > 0: _kill(enemy)
	_start_dialogue(Story.BANK, "play")

func _complete_campaign() -> void:
	sound.play_sfx("complete")
	if not campaign.residues_completed:
		victory_notice = "Sessão de teste: progresso não registrado."
		return
	victory_notice = "OPERAÇÃO CORRENTE REGISTRADA  /  PROGRESSO SALVO" if campaign.complete_energy(difficulty) == OK else "Não foi possível salvar o progresso desta operação."

# ---------------------------------------------------------------- hazards

func _update_arcs(dt: float) -> void:
	for arc in arcs:
		if arc.state(clock) != "active": continue
		if dash_time <= 0.0 and arc.touches(pos, 13.0): _damage(true)
		for enemy in enemies:
			if enemy.hp <= 0 or enemy.zone > stage or enemy.kind in ["coil", "transformer"]: continue
			if enemy.arc_cd <= 0.0 and arc.touches(enemy.pos, enemy.radius):
				enemy.arc_cd = 0.5
				_hit_enemy(enemy, 2, true)
	for link in coil_links():
		if link.active and dash_time <= 0.0 and pos.distance_to(Geometry2D.get_closest_point_to_segment(pos, link.a, link.b)) < 12.0: _damage(true)
	for enemy in enemies: enemy.arc_cd = maxf(0.0, enemy.arc_cd - dt)

## Live coil pairs project a pulsing arc that blocks pulses and shocks Lia.
func coil_links() -> Array[Dictionary]:
	var links: Array[Dictionary] = []
	var coils: Array[Dictionary] = []
	for enemy in enemies:
		if enemy.kind == "coil" and enemy.hp > 0 and enemy.zone <= stage: coils.append(enemy)
	for i in coils.size():
		for j in range(i + 1, coils.size()):
			if coils[i].pos.distance_to(coils[j].pos) > COIL_LINK: continue
			var active := fposmod(clock + coils[i].id * 0.3, 2.4) < 1.5
			links.append({"a": coils[i].pos + Vector2(0, -40), "b": coils[j].pos + Vector2(0, -40), "active": active})
	return links

func shielded(enemy: Dictionary) -> bool:
	if enemy.kind == "transformer": return false
	for source in enemies:
		if source.kind == "transformer" and source.hp > 0 and source.zone == enemy.zone and source.pos.distance_to(enemy.pos) < SHIELD_RADIUS: return true
	return false

func _update_trails(dt: float) -> void:
	for i in range(trails.size() - 1, -1, -1):
		trails[i].life -= dt
		if trails[i].life <= 0.0:
			trails.remove_at(i)
			continue
		if dash_time <= 0.0 and pos.distance_to(Geometry2D.get_closest_point_to_segment(pos, trails[i].a, trails[i].b)) < 11.0:
			_damage(true)

func _check_taunts() -> void:
	if not _taunts.has("corridor") and stage >= 1 and M.world_rect(Rect2(610, 190, 290, 100)).has_point(pos):
		_taunts["corridor"] = true
		_set_toast(Story.AI_TAUNTS.corridor, true)
	if not _taunts.has("transformer") and stage >= 1 and pos.x > 900 * M.SCALE and pos.y < 430 * M.SCALE:
		_taunts["transformer"] = true
		_set_toast(Story.AI_TAUNTS.transformer, true)

# ---------------------------------------------------------------- enemies

func _update_enemies(dt: float) -> void:
	var mult: float = Simulation.HOSTILE_SPEED[difficulty]
	var pressure: float = PRESSURE[difficulty] * (1.0 - 0.045 * 3.0)
	var windup_mult: float = WINDUP[difficulty]
	for i in enemies.size():
		var enemy: Dictionary = enemies[i]
		if enemy.hp <= 0:
			if enemy.death_age >= 0.0: enemy.death_age += dt
			continue
		if enemy.zone > stage: continue
		enemy.hit_cd = maxf(0.0, enemy.hit_cd - dt)
		enemy.attack_age += dt
		enemy.anim_time += dt
		enemy.moving = false
		enemy.warning = 0.0
		if enemy.kind == "transformer": continue
		var to_lia: Vector2 = pos - enemy.pos
		var distance := to_lia.length()
		var visible := M.line_clear(enemy.pos, pos, 3.0, stage)
		if distance < 560.0 and visible: enemy.engaged = true
		if not enemy.engaged: continue
		if enemy.phase == "spawn":
			enemy.timer -= dt
			if enemy.timer <= 0.0: enemy.phase = "idle"
			continue
		enemy.facing = to_lia.normalized() if enemy.phase != "dash" else enemy.aim
		if distance < enemy.radius + 12.0 and enemy.kind != "coil": _damage(enemy.kind == "spark")
		match enemy.phase:
			"dash":
				enemy.timer -= dt
				var before: Vector2 = enemy.pos
				enemy.pos = M.slide(before, enemy.aim * 430.0 * dt, enemy.radius, stage)
				enemy.moving = true
				if enemy.pos.distance_to(before) > 0.5:
					trails.append({"a": before, "b": enemy.pos, "life": 1.3})
				if enemy.timer <= 0.0 or enemy.pos.distance_to(before) < 0.5:
					enemy.phase = "rest"
					enemy.timer = 1.0 * PRESSURE[difficulty]
				continue
			"rest":
				enemy.timer -= dt
				if enemy.timer <= 0.0: enemy.phase = "idle"
				continue
			"windup":
				enemy.timer -= dt
				enemy.warning = 1.0
				if enemy.timer <= 0.0: _enemy_attack(enemy, mult, pressure)
				continue
		enemy.cooldown -= dt
		if enemy.kind != "coil": _move_enemy(enemy, i, distance, visible, dt)
		var reach := 470.0 if enemy.kind != "spark" else 330.0
		if enemy.cooldown <= 0.0 and visible and distance < reach:
			enemy.phase = "windup"
			enemy.aim = to_lia.normalized()
			enemy.timer = (0.55 if enemy.kind == "spark" else (0.7 if enemy.kind == "coil" else 0.65)) * windup_mult
			sound.play_sfx("unit_%s_windup" % ("scout" if enemy.kind in ["spark", "coil"] else enemy.kind))

func _move_enemy(enemy: Dictionary, index: int, distance: float, visible: bool, dt: float) -> void:
	var range_pair: Array = PREFERRED[enemy.kind]
	var speed: float = ENEMY_SPEED[enemy.kind]
	var travel := Vector2.ZERO
	if distance > range_pair[0] + 30.0 or not visible:
		enemy["route_timer"] = float(enemy.get("route_timer", 0.0)) - dt
		if enemy.route_timer <= 0.0 or Vector2(enemy.get("route_target", Vector2.INF)).distance_to(pos) > 64.0 or int(enemy.get("route_stage", -1)) != stage:
			enemy["route"] = M.path_between(enemy.pos, pos, stage, 85.0, enemy.radius, true)
			if enemy.route.is_empty(): enemy.route = M.path_between(enemy.pos, pos, stage, 410.0, enemy.radius, true)
			enemy["route_cursor"] = 0
			enemy["route_timer"] = 0.9 + index * 0.05
			enemy["route_target"] = pos
			enemy["route_stage"] = stage
		var route: PackedVector2Array = enemy.get("route", PackedVector2Array())
		var cursor: int = enemy.get("route_cursor", 0)
		while cursor < route.size() and enemy.pos.distance_to(route[cursor]) < 8.0: cursor += 1
		enemy["route_cursor"] = cursor
		if cursor < route.size(): travel = (route[cursor] - Vector2(enemy.pos)).normalized() * speed
	elif distance < range_pair[1]:
		travel = (Vector2(enemy.pos) - pos).normalized() * speed * 0.8
	else:
		# Circle Lia at the preferred range so drones never stand still.
		var side := 1.0 if index % 2 == 0 else -1.0
		travel = (pos - Vector2(enemy.pos)).normalized().orthogonal() * side * speed * 0.45
	for other in enemies:
		if other.id == enemy.id or other.hp <= 0 or other.zone > stage: continue
		var away: Vector2 = enemy.pos - other.pos
		var gap: float = enemy.radius + other.radius + 9.0
		if away.length() < gap and away.length() > 0.01: travel += away.normalized() * (gap - away.length()) * 3.0
	if travel == Vector2.ZERO: return
	var before: Vector2 = enemy.pos
	enemy.pos = M.slide(before, travel.limit_length(speed * 1.2) * dt, enemy.radius, stage)
	enemy.moving = enemy.pos.distance_to(before) > 0.2
	if not enemy.moving: enemy["route_timer"] = minf(float(enemy.get("route_timer", 0.0)), 0.15)

func _enemy_attack(enemy: Dictionary, mult: float, pressure: float) -> void:
	enemy.attacks += 1
	enemy.attack_age = 0.0
	enemy.phase = "idle"
	enemy.cooldown = 1.65 * pressure
	var muzzle: Vector2 = enemy.pos + enemy.aim * (enemy.radius + 6.0) + Vector2(0, -8)
	match enemy.kind:
		"scout":
			_hostile(muzzle, enemy.aim * 190.0 * mult, "bolt")
			if enemy.attacks % 2 == 1 and difficulty != "story": _hostile(muzzle, enemy.aim * 250.0 * mult, "bolt")
		"sentry":
			var spread := [-0.095, 0.095] if difficulty == "story" else [-0.19, 0.0, 0.19]
			for angle in spread: _hostile(muzzle, enemy.aim.rotated(angle) * 215.0 * mult, "bolt")
		"spark":
			enemy.phase = "dash"
			enemy.timer = 0.42
			enemy.cooldown = 1.4 * pressure
		"coil":
			for angle in [-0.22, 0.22]: _hostile(enemy.pos + Vector2(0, -42), enemy.aim.rotated(angle) * 150.0 * mult * 0.75, "orb")
			enemy.cooldown = 2.6 * pressure
	sound.play_sfx("unit_%s_fire" % ("scout" if enemy.kind in ["spark", "coil"] else enemy.kind))

func _hostile(from: Vector2, velocity_value: Vector2, kind: String) -> void:
	bullets.append({"pos": from, "vel": velocity_value, "hostile": true, "life": 3.0 if kind == "orb" else 2.4, "kind": kind})

func _hit_enemy(enemy: Dictionary, amount: int, environmental: bool = false) -> void:
	if enemy.hp <= 0: return
	enemy.hp = maxi(0, enemy.hp - amount)
	enemy.hit_cd = 0.18
	enemy.engaged = true
	if enemy.hp <= 0: _kill(enemy)
	elif not environmental: sound.play_sfx("unit_%s_hit" % ("scout" if enemy.kind in ["spark", "coil", "transformer"] else enemy.kind))

func _kill(enemy: Dictionary) -> void:
	enemy.hp = 0
	enemy.death_age = 0.0
	kills += 1
	sound.play_sfx("enemy_dead")
	_burst(enemy.pos + Vector2(0, -10), PINK if enemy.kind != "transformer" else ELECTRIC, 18 if enemy.kind == "transformer" else 10)
	if enemy.kind == "transformer":
		sound.play_sfx("emp")
		_set_toast("TRANSFORMADOR NEUTRALIZADO  /  ESCUDOS DESATIVADOS")
		effects.append({"kind": "emp", "pos": enemy.pos, "life": 0.7, "max": 0.7})

# ---------------------------------------------------------------- bullets

func _update_bullets(dt: float) -> void:
	var links := coil_links()
	for i in range(bullets.size() - 1, -1, -1):
		var bullet: Dictionary = bullets[i]
		bullet.life -= dt
		var gone: bool = bullet.life <= 0.0
		var steps := maxi(1, int(ceil(Vector2(bullet.vel).length() * dt / 4.0)))
		for step in steps:
			if gone: break
			var before: Vector2 = bullet.pos
			bullet.pos += bullet.vel * dt / steps
			if bullet.hostile:
				var reach := 19.0 if bullet.kind == "orb" else 15.0
				if bullet.pos.distance_to(pos + Vector2(0, -4)) < reach and invuln <= 0.0:
					_damage(bullet.kind == "orb")
					gone = true
					break
				if not M.walkable(bullet.pos, 3.0, stage):
					gone = true
				continue
			gone = _player_bullet_step(bullet, before, links)
		if gone: bullets.remove_at(i)
		else: bullets[i] = bullet

## Returns true when the pulse is consumed.
func _player_bullet_step(bullet: Dictionary, before: Vector2, links: Array[Dictionary]) -> bool:
	var at: Vector2 = bullet.pos
	for link in links:
		if link.active and Geometry2D.segment_intersects_segment(before, at, link.a, link.b) != null:
			_burst(at, ELECTRIC, 5)
			return true
	# Mirrors and relays are hit anywhere on their silhouette (base to head),
	# so a pulse fired from the south does not die on the footprint first.
	if stage == 0 and not mirrors.solved:
		for m in 3:
			if M.world_rect(Rect2(M.MIRRORS[m] - Vector2(17, 38), Vector2(34, 48))).has_point(at):
				if mirrors.rotate(m):
					sound.play_sfx("mirror")
					_burst(at, SUN, 6)
				return true
	if stage >= 1 and not relays.solved:
		for r in 3:
			if M.world_rect(Rect2(M.RELAYS[r] - Vector2(13, 44), Vector2(26, 52))).has_point(at):
				relays.energize(r)
				sound.play_sfx("relay")
				_burst(at, ELECTRIC, 8)
				if relays.solved:
					sound.play_sfx("power_up")
					flash = maxf(flash, 0.3)
					_set_toast("RELÉS SINCRONIZADOS  /  TORRE ENERGIZADA")
				return true
	for enemy in enemies:
		if enemy.hp <= 0 or enemy.zone > stage: continue
		var center: Vector2 = enemy.pos + Vector2(0, -8 if enemy.kind != "coil" else -22)
		if at.distance_to(center) >= enemy.radius + 6.0: continue
		if shielded(enemy):
			sound.play_sfx("shield")
			effects.append({"kind": "shield", "pos": enemy.pos, "life": 0.25, "max": 0.25})
			return true
		_hit_enemy(enemy, int(bullet.damage))
		if loadout.chain_pulse: _chain_from(enemy)
		return true
	return not M.walkable(at, 3.0, stage)

func _chain_from(source: Dictionary) -> void:
	var best: Dictionary = {}
	var best_distance := 150.0
	for enemy in enemies:
		if enemy.id == source.id or enemy.hp <= 0 or enemy.zone > stage or shielded(enemy): continue
		var distance: float = enemy.pos.distance_to(source.pos)
		if distance < best_distance:
			best = enemy
			best_distance = distance
	if best.is_empty(): return
	effects.append({"kind": "bolt", "a": source.pos + Vector2(0, -8), "b": best.pos + Vector2(0, -8), "life": 0.18, "max": 0.18})
	_hit_enemy(best, 1)

# ---------------------------------------------------------------- objectives

func objective_label() -> String:
	match stage:
		0:
			if not mirrors.solved: return "ALINHAR OS ESPELHOS  /  ATIRE PARA GIRAR"
			if zone_alive(0) > 0: return "NEUTRALIZAR OS DRONES DA CENTRAL"
			return "ESTABILIZAR A SOBRECARGA  /  E NA FAIXA VERDE"
		1:
			if pos.x < 900 * M.SCALE: return "ATRAVESSAR O CORREDOR DE CABOS"
			if _alive_kind(1, "transformer"): return "DESTRUIR O TRANSFORMADOR CORROMPIDO"
			if not relays.solved: return "ENERGIZAR OS TRÊS RELÉS  /  ATIRE NELES"
			if zone_alive(1) > 0: return "NEUTRALIZAR OS DRONES DA TORRE"
			return "ESTABILIZAR A SOBRECARGA DA TORRE  /  E"
		2:
			if not battery.started: return "ENTRAR NO ANEL DE RECARGA"
			for i in 3:
				if battery.danger(i): return "ALIVIAR A CÉLULA %d  /  E NO CONSOLE" % (i + 1)
			return "SEGURAR A CARGA NO ANEL  /  %d%%" % int(battery.charge * 100.0)
	return "ELEVADOR DO NÚCLEO  /  SEGURE E"

func _alive_kind(zone: int, kind: String) -> bool:
	for enemy in enemies:
		if enemy.zone == zone and enemy.kind == kind and enemy.hp > 0: return true
	return false

func _nearest_enemy(zone: int, kind: String = "") -> Dictionary:
	var best: Dictionary = {}
	var best_distance := INF
	for enemy in enemies:
		if enemy.zone != zone or enemy.hp <= 0 or (kind != "" and enemy.kind != kind): continue
		var distance: float = pos.distance_to(enemy.pos)
		if distance < best_distance:
			best = enemy
			best_distance = distance
	return best

func objective_point() -> Vector2:
	match stage:
		0:
			if not mirrors.solved: return M.w(M.MIRRORS[mini(mirrors.lit_count() - 1, 2)])
			if zone_alive(0) > 0: return _nearest_enemy(0).pos
			return M.w(M.TERMINALS[0])
		1:
			if pos.x < 900 * M.SCALE: return M.w(Vector2(950, 240))
			if _alive_kind(1, "transformer"): return _nearest_enemy(1, "transformer").pos
			if not relays.solved:
				var best := Vector2.ZERO
				var best_distance := INF
				for r in 3:
					var point := M.w(M.RELAYS[r])
					if not relays.lit(r) and pos.distance_to(point) < best_distance:
						best = point
						best_distance = pos.distance_to(point)
				return best
			if zone_alive(1) > 0: return _nearest_enemy(1).pos
			return M.w(M.TERMINALS[1])
		2:
			if battery.started:
				for i in 3:
					if battery.danger(i): return M.w(M.CELL_CONSOLES[i])
			return M.w(M.RING_CENTER)
	return M.w(M.ELEVATOR)

func _objective_body(target: Vector2) -> String:
	for i in 2:
		if target == M.w(M.TERMINALS[i]): return "terminal %d" % i
	for i in 3:
		if target == M.w(M.MIRRORS[i]): return "espelho %d" % i
		if target == M.w(M.RELAYS[i]): return "relé %d" % i
		if target == M.w(M.CELL_CONSOLES[i]): return "console %d" % i
	if target == M.w(M.ELEVATOR): return "porta do elevador"
	return ""

func _update_guidance() -> void:
	var target := objective_point()
	if _guide_timer > 0.0 and target.distance_to(_guide_target) < 25.0: return
	_guide_target = target
	_guide_timer = 0.65
	var body := _objective_body(target)
	var reach := 120.0 if body.begins_with("espelho") or body.begins_with("relé") else 60.0
	guidance_path = M.path_between(pos, target, stage, reach, 14.0, body.is_empty() or not (body.begins_with("espelho") or body.begins_with("relé")), body)
	if guidance_path.is_empty(): guidance_path = M.path_between(pos, target, stage, 160.0, 14.0, false)

func guidance_point() -> Vector2:
	var nearest := 0
	var best := INF
	for i in guidance_path.size():
		var distance := pos.distance_squared_to(guidance_path[i])
		if distance < best:
			best = distance
			nearest = i
	for i in range(nearest, guidance_path.size()):
		if pos.distance_to(guidance_path[i]) > 75.0: return guidance_path[i]
	return objective_point()

# ---------------------------------------------------------------- effects and audio

func _burst(at: Vector2, color: Color, count: int) -> void:
	effects.append({"kind": "burst", "pos": at, "color": color, "count": count, "life": 0.45, "max": 0.45, "seed": randi() % 1000})

func _update_effects(dt: float) -> void:
	for i in range(effects.size() - 1, -1, -1):
		effects[i].life -= dt
		if effects[i].life <= 0.0: effects.remove_at(i)

func _update_audio() -> void:
	var mood := "blackout" if stage < 2 else "grid"
	if state == "victory": mood = "victory"
	elif state == "play":
		if stage == 2 and battery.started and not battery.done: mood = "boss"
		else:
			for enemy in enemies:
				if enemy.hp > 0 and enemy.zone <= stage and enemy.kind != "transformer" and enemy.engaged and enemy.pos.distance_to(pos) < 360:
					mood = "combat"
					break
	sound.set_mood(mood)
	var proximity := 0.0
	for arc in arcs:
		if arc.state(clock) != "idle": proximity = maxf(proximity, 1.0 - pos.distance_to((arc.a + arc.b) * 0.5) / 260.0)
	sound.set_structure_hum(state == "play", proximity)

func _dynamic_lights() -> Array[Vector4]:
	var lights: Array[Vector4] = []
	for lamp in M.LAMPS:
		var p := M.w(lamp) - Vector2(0, 52)
		lights.append(Vector4(p.x, p.y + 40, 120.0 if stage >= 1 else 70.0, 0.85 if stage >= 1 else 0.45))
	for i in 2:
		var t := M.w(M.TERMINALS[i])
		lights.append(Vector4(t.x, t.y - 20, 80.0, 0.55 if terminal_ready(i) or stage > i else 0.25))
	for arc in arcs:
		var s: String = arc.state(clock)
		if s == "idle": continue
		var c: Vector2 = (arc.a + arc.b) * 0.5
		lights.append(Vector4(c.x, c.y, 150.0 if s == "active" else 70.0, 0.95 if s == "active" else 0.35 * arc.warning_amount(clock)))
	for link in coil_links():
		if link.active:
			var c: Vector2 = (link.a + link.b) * 0.5
			lights.append(Vector4(c.x, c.y + 30, 160.0, 0.75))
	var lit := mirrors.lit_count() if stage == 0 else 4
	for m in mini(lit, 3):
		var p := M.w(M.MIRRORS[m])
		lights.append(Vector4(p.x, p.y - 20, 90.0, 0.7))
	if mirrors.solved or stage > 0:
		var c := M.w(M.COLLECTOR)
		lights.append(Vector4(c.x, c.y, 180.0, 0.9))
	for r in 3:
		if stage >= 1 and relays.lit(r):
			var p := M.w(M.RELAYS[r])
			lights.append(Vector4(p.x, p.y - 30, 90.0, 0.7))
	if stage == 2 and battery.started:
		var c := M.w(M.RING_CENTER)
		lights.append(Vector4(c.x, c.y, 140.0, 0.6))
		for i in 3:
			var console := M.w(M.CELL_CONSOLES[i])
			lights.append(Vector4(console.x, console.y - 20.0, 110.0 if battery.danger(i) else 70.0, 0.8 if battery.danger(i) else 0.4))
	# Amber emergency lamps mark every sealed gate in the dark.
	for i in M.GATES.size():
		if not M.gate_open(i, stage):
			var gate := M.world_rect(M.GATES[i][1]).get_center()
			lights.append(Vector4(gate.x, gate.y, 85.0, 0.4))
	if stage >= 3:
		var e := M.w(M.ELEVATOR)
		lights.append(Vector4(e.x, e.y, 130.0, 0.9))
	if fire_cd > fire_interval * 0.5:
		lights.append(Vector4(pos.x + aim.x * 20.0, pos.y + aim.y * 20.0 - 8.0, 90.0, 0.5))
	for effect in effects:
		if effect.kind in ["bolt", "emp"] and lights.size() < 39:
			var p: Vector2 = effect.get("b", effect.get("pos", pos))
			lights.append(Vector4(p.x, p.y, 200.0 if effect.kind == "emp" else 120.0, effect.life / effect.max))
	if lights.size() > 40: lights.resize(40)
	return lights

# ---------------------------------------------------------------- drawing

func _draw() -> void:
	var offset := _offset()
	draw_set_transform(offset)
	if plate_mode:
		# Static background only (floor, walls, buildings, lamps): the framed
		# reference that the painted sectors in assets/power must match.
		Art.draw_ground(self, clock, stage)
		var plate := Art.structures()
		plate.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.depth < b.depth)
		for structure in plate: Art.draw_structure(self, structure, clock, stage)
		draw_set_transform(Vector2.ZERO)
		return
	_draw_ground()
	for i in M.GATES.size():
		if not M.gate_open(i, stage): Art.draw_gate(self, M.world_rect(M.GATES[i][1]), M.GATE_LABELS[i][0], clock, M.GATE_LABELS[i][1])
	var entries: Array[Dictionary] = []
	if not Art.has_painted_sectors():
		for structure in Art.structures(): entries.append({"kind": "structure", "depth": structure.depth, "data": structure})
	for m in 3: entries.append({"kind": "mirror", "depth": M.w(M.MIRRORS[m]).y + 8, "index": m})
	for r in 3: entries.append({"kind": "relay", "depth": M.w(M.RELAYS[r]).y + 8, "index": r})
	for a in arcs.size():
		entries.append({"kind": "pylon", "depth": arcs[a].a.y + 6, "index": a, "end": 0})
		entries.append({"kind": "pylon", "depth": arcs[a].b.y + 6, "index": a, "end": 1})
	for t in 2: entries.append({"kind": "terminal", "depth": M.w(M.TERMINALS[t]).y - 10, "index": t})
	for c in 3: entries.append({"kind": "console", "depth": M.w(M.CELL_CONSOLES[c]).y - 10, "index": c})
	for enemy in enemies:
		if enemy.zone > stage: continue
		if enemy.hp > 0 or (enemy.death_age >= 0.0 and enemy.death_age < 1.05):
			entries.append({"kind": "enemy", "depth": enemy.pos.y + 16.0, "data": enemy})
	entries.append({"kind": "lia", "depth": pos.y + 18.0})
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.depth < b.depth)
	for entry in entries:
		match entry.kind:
			"structure": Art.draw_structure(self, entry.data, clock, stage)
			"mirror":
				var m: int = entry.index
				Art.draw_mirror(self, M.w(M.MIRRORS[m]), mirrors.orientation[m], mirrors.turning[m], stage > 0 or mirrors.lit_count() > m, mirrors.aligned(m), clock)
			"relay":
				var r: int = entry.index
				Art.draw_relay(self, M.w(M.RELAYS[r]), relays.charge[r], relays.window, stage >= 1 and relays.lit(r), clock)
			"pylon":
				var arc = arcs[entry.index]
				Art.draw_pylon(self, arc.a if entry.end == 0 else arc.b, arc.state(clock), arc.warning_amount(clock), clock)
			"terminal":
				var t: int = entry.index
				Art.draw_console(self, M.w(M.TERMINALS[t]), stage > t, overloads[t].cooldown > 0.0, clock, true)
			"console":
				var c: int = entry.index
				Art.draw_console(self, M.w(M.CELL_CONSOLES[c]), stage >= 3, stage == 2 and battery.started and battery.danger(c), clock)
			"enemy": _draw_enemy(entry.data)
			"lia": _draw_lia()
	Art.draw_elevator(self, stage >= 3, clock)
	if collision_audit: _draw_collision_audit()
	draw_set_transform(Vector2.ZERO)

func _draw_ground() -> void:
	if not Art.has_painted_sectors():
		Art.draw_ground(self, clock, stage)
		return
	var half := M.SIZE * 0.5
	var off := Art.sector_textures(false)
	var on := Art.sector_textures(true)
	for i in 4: draw_texture_rect(off[i], Rect2(Vector2(i % 2, i / 2) * half, half), false)
	# Powered versions fade in over each restored compound.
	var regions := [[Rect2(30, 50, 600, 940), 0], [Rect2(600, 50, 936, 420), 1], [Rect2(600, 470, 936, 520), 2]]
	for region in regions:
		var amount := clampf(restored_light - float(region[1]), 0.0, 1.0)
		if amount <= 0.0: continue
		var world := M.world_rect(region[0])
		for i in 4:
			var sector := Rect2(Vector2(i % 2, i / 2) * half, half)
			var overlap := sector.intersection(world)
			if overlap.size.x <= 0 or overlap.size.y <= 0: continue
			var texture: Texture2D = on[i]
			var source := Rect2((overlap.position - sector.position) / half * texture.get_size(), overlap.size / half * texture.get_size())
			draw_texture_rect_region(texture, overlap, source, Color(1, 1, 1, amount))

func _draw_lia() -> void:
	var action := "repair" if hold_progress > 0 else ("fire" if fire_cd > 0 else "idle")
	Actors.draw_lia(self, pos, aim, _animation.elapsed, _animation.moving, invuln > 0 and int(clock * 16) % 2 == 0, dash_time > 0, action, shot_age())

func _draw_enemy(enemy: Dictionary) -> void:
	var view := enemy.duplicate()
	view["hurt"] = enemy.hit_cd
	if enemy.hp <= 0:
		if enemy.kind in ["scout", "sentry", "spark"]:
			view["kind"] = "scout" if enemy.kind == "spark" else enemy.kind
			Actors.ENEMIES.draw_destroyed(self, view)
		return
	Art.draw_enemy(self, view, clock + enemy.id * 0.137)
	if enemy.hp < enemy.max_hp or enemy.kind == "transformer":
		var width := 56.0 if enemy.kind == "transformer" else 34.0
		var bar := Rect2(enemy.pos + Vector2(-width * 0.5, -66 if enemy.kind in ["transformer", "coil"] else -38), Vector2(width, 4))
		draw_rect(bar.grow(1), Color("07171d"))
		draw_rect(bar, Color("263b40"))
		draw_rect(Rect2(bar.position, Vector2(width * clampf(float(enemy.hp) / enemy.max_hp, 0, 1), 4)), PINK)

func _draw_collision_audit() -> void:
	for edge in M.floor_edges(): draw_line(edge.a, edge.b, Color("75e6da"), 2)
	for shape in M.collision_shapes(stage):
		draw_rect(shape.rect, Color(1, 0.25, 0.3, 0.30))
		draw_rect(shape.rect, Color("ff9b79"), false, 1)
	draw_arc(pos, 14, 0, TAU, 24, Color.WHITE, 1)
	for enemy in enemies:
		if enemy.hp > 0 and enemy.zone <= stage: draw_arc(enemy.pos, enemy.radius, 0, TAU, 24, Color("f4d977"), 1)

## Above the blackout: beams, arcs, bullets, glows, prompts and guidance.
func _draw_fx(layer: Node2D) -> void:
	layer.draw_set_transform(_offset())
	_draw_beams(layer)
	for arc in arcs:
		var s: String = arc.state(clock)
		if s == "active": Art.draw_lightning(layer, arc.a + Vector2(0, -34), arc.b + Vector2(0, -34), clock, 2.5)
		elif s == "warning" and int(clock * 20) % 3 == 0:
			for end in [arc.a, arc.b]: Art.draw_lightning(layer, end + Vector2(0, -34), end + Vector2(randf_range(-10, 10), -50), clock + end.x, 1.0, Color(ELECTRIC, 0.7), 4.0)
	for link in coil_links():
		if link.active: Art.draw_lightning(layer, link.a, link.b, clock + 0.5, 2.0, Color("f4a6ff"), 12.0)
		else: layer.draw_dashed_line(link.a, link.b, Color(PINK, 0.25), 1.0, 6.0)
	for trail in trails:
		var alpha: float = clampf(trail.life / 1.3, 0.0, 1.0)
		layer.draw_line(trail.a, trail.b, Color(ELECTRIC, 0.18 * alpha), 9)
		layer.draw_line(trail.a, trail.b, Color(ELECTRIC, 0.8 * alpha), 2)
	# Battery ring progress.
	if stage == 2:
		var c := M.w(M.RING_CENTER)
		var r := M.RING_RADIUS * M.SCALE
		layer.draw_arc(c, r + 6, -PI / 2, -PI / 2 + TAU * battery.charge, 64, CYAN, 4)
		if not battery.started: layer.draw_arc(c, r + 6 + sin(clock * 4) * 3, 0, TAU, 64, Color(GOLD, 0.5), 2)
		for i in 3:
			if battery.started and battery.danger(i):
				var foot := M.w(M.CELL_CONSOLES[i])
				var console := foot + Vector2(0, -60)
				Art.draw_lightning(layer, console, console + Vector2(randf_range(-14, 14), -26), clock + i, 1.5, Color(PINK, 0.8), 6.0)
				var beat := 0.5 + 0.5 * sin(clock * 10.0)
				layer.draw_arc(foot + Vector2(0, -14), 30.0 + beat * 6.0, 0, TAU, 32, Color(PINK, 0.45 + 0.4 * beat), 3)
				layer.draw_string(ThemeDB.fallback_font, foot + Vector2(-24, 34), "CÉLULA %d" % (i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, PINK)
	for r in 3:
		if stage >= 1 and relays.lit(r):
			var head := M.w(M.RELAYS[r]) + Vector2(0, -46)
			layer.draw_circle(head, 10 + sin(clock * 9 + r) * 2, Color(ELECTRIC, 0.22))
	# Enemy cores glow through the dark; shields show as hex bubbles.
	for enemy in enemies:
		if enemy.hp <= 0 or enemy.zone > stage: continue
		var core: Vector2 = enemy.pos + Vector2(0, -10 if enemy.kind != "coil" else -42)
		var pulse := 0.5 + 0.5 * sin(clock * 5.0 + enemy.id)
		layer.draw_circle(core, 3.0 + pulse, Color(PINK, 0.9))
		layer.draw_circle(core, 9.0 + pulse * 3.0, Color(PINK, 0.12 + enemy.warning * 0.25))
		if enemy.phase == "windup" and enemy.kind == "spark":
			layer.draw_line(enemy.pos, enemy.pos + enemy.aim * 150.0, Color(ELECTRIC, 0.25 + 0.25 * absf(sin(clock * 30))), 2)
		if shielded(enemy):
			var points := PackedVector2Array()
			for k in 7: points.append(enemy.pos + Vector2(0, -8) + Vector2.from_angle(k * TAU / 6.0 + clock * 0.6) * (enemy.radius + 9.0))
			layer.draw_polyline(points, Color(ELECTRIC, 0.55 + 0.2 * pulse), 2)
	for enemy in enemies:
		if enemy.kind == "transformer" and enemy.hp > 0 and enemy.zone <= stage:
			layer.draw_arc(enemy.pos, SHIELD_RADIUS, 0, TAU, 72, Color(ELECTRIC, 0.06 + 0.04 * sin(clock * 2)), 2)
	for bullet in bullets:
		if not bullet.hostile:
			Actors.WEAPON.draw_pulse(layer, bullet, clock)
		elif bullet.kind == "orb":
			layer.draw_circle(bullet.pos, 9, Color("f4a6ff", 0.25))
			layer.draw_circle(bullet.pos, 5, Color("f4a6ff"))
			layer.draw_circle(bullet.pos, 2, Color.WHITE)
		else:
			layer.draw_line(bullet.pos - bullet.vel.normalized() * 14, bullet.pos, Color(PINK, 0.5), 6)
			layer.draw_circle(bullet.pos, 4, PINK)
	for effect in effects: _draw_effect(layer, effect)
	if state == "play":
		var next := guidance_point()
		if next.distance_to(pos) > 95.0:
			var direction := (next - pos).normalized()
			var p := pos + direction * 62 + Vector2(0, 18)
			layer.draw_polyline(PackedVector2Array([p - direction.rotated(-0.65) * 9, p, p - direction.rotated(0.65) * 9]), Color(GOLD, 0.65 + 0.15 * sin(clock * 3)), 2)
		var candidate := interaction_candidate()
		if not candidate.is_empty():
			var p: Vector2 = candidate.pos
			layer.draw_arc(p, 46, 0, TAU, 30, Color(CYAN, 0.64), 2)
			layer.draw_string(ThemeDB.fallback_font, p + Vector2(-6, -52), "E", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, WHITE)
	layer.draw_set_transform(Vector2.ZERO)

func _draw_beams(layer: Node2D) -> void:
	var nodes: Array[Vector2] = [M.w(M.SUN_ENTRY)]
	for m in 3: nodes.append(M.w(M.MIRRORS[m]) + Vector2(0, -38))
	nodes.append(M.w(M.COLLECTOR) + Vector2(0, -54))
	var lit := 4 if stage > 0 else mirrors.lit_count()
	for i in mini(lit, 4):
		var a: Vector2 = nodes[i]
		var b: Vector2 = nodes[i + 1]
		var width := 3.0 + sin(clock * 6.0 + i) * 0.6
		layer.draw_line(a, b, Color(SUN, 0.12), width * 5.0)
		layer.draw_line(a, b, Color(SUN, 0.75), width)
		layer.draw_line(a, b, Color.WHITE, 1.0)
	# A mirror that still points the wrong way shows where its light goes.
	if stage == 0 and lit < 4:
		var m := lit - 1
		var origin: Vector2 = nodes[lit]
		var direction: Vector2 = Mechanics.direction(mirrors.orientation[m]).rotated(-mirrors.turning[m] / 0.32 * PI / 4.0)
		layer.draw_line(origin, origin + direction * 120.0, Color(SUN, 0.35), 2)
		layer.draw_circle(origin + direction * 120.0, 4, Color(SUN, 0.3))

func _draw_effect(layer: Node2D, effect: Dictionary) -> void:
	var t: float = 1.0 - effect.life / effect.max
	match effect.kind:
		"burst":
			for k in int(effect.count):
				var direction := Vector2.from_angle(float(k) / effect.count * TAU + effect.seed)
				var p: Vector2 = effect.pos + direction * t * 34.0 + Vector2(0, t * t * 18.0)
				layer.draw_line(p, p - direction * 5.0 * (1.0 - t), Color(effect.color, 1.0 - t), 2)
		"bolt":
			Art.draw_lightning(layer, effect.a, effect.b, clock, 3.0 * (1.0 - t) + 1.0, ELECTRIC, 14.0)
		"shield":
			layer.draw_arc(effect.pos + Vector2(0, -8), 22 + t * 8, 0, TAU, 24, Color(ELECTRIC, 1.0 - t), 2)
		"warp":
			layer.draw_circle(effect.pos, 30 * (1.0 - t), Color(PINK, 0.25 * (1.0 - t)))
			Art.draw_lightning(layer, effect.pos + Vector2(0, -70), effect.pos, clock, 2.0, Color(PINK, 1.0 - t), 10.0)
		"emp":
			layer.draw_arc(effect.pos, 40 + t * 700.0, 0, TAU, 96, Color(CYAN, 0.8 * (1.0 - t)), 6)
			layer.draw_arc(effect.pos, 20 + t * 520.0, 0, TAU, 96, Color(ELECTRIC, 0.5 * (1.0 - t)), 3)
