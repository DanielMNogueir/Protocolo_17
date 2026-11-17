extends Node2D
## Industrial city district. Campaign stats survive a district retry.

const M = preload("res://scripts/residue_map.gd")
const Actors = preload("res://scripts/actors_art.gd")
const LiaAnimation = preload("res://scripts/lia_animation.gd")
const Occlusion = preload("res://scripts/occlusion.gd")
const LIA_POSE = preload("res://scripts/lia_directional.gd")
const FieldHUD = preload("res://scripts/field_hud.gd")
const Guide = preload("res://scripts/objective_guide.gd")
const HUD = preload("res://scripts/residue_hud.gd")
const LIGHT_SHADER = preload("res://scripts/residue_lighting.gdshader")
const BACKGROUND_SHADER = preload("res://scripts/residue_background.gdshader")
const Sound = preload("res://scripts/audio.gd")
const Simulation = preload("res://scripts/simulation.gd")
const CampaignProgress = preload("res://scripts/campaign_progress.gd")
const Loadout = preload("res://scripts/campaign_loadout.gd")
const Story = preload("res://scripts/residue_story.gd")
const DialogueLayer = preload("res://scripts/residue_dialogue_layer.gd")
## Hostile pulse speed and cadence by difficulty; "operation" keeps the original values.
const SHOT_SPEED := {"story": 0.85, "operation": 1.0, "veteran": 1.15}
const PRESSURE := {"story": 1.25, "operation": 1.0, "veteran": 0.8}
const CYAN := Color("7be4ce")
const WHITE := Color("e9ece0")
const PINK := Color("e36b92")
const GOLD := Color("e8bd74")

var state := "play"
var buttons: Array[Dictionary] = []
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
var _map_mouse_held := false
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
var toast_ai := false
var after_dialogue := "play"
var dialogue: Array = []
var dialogue_chars := 0.0
var dialogue_fast := false
var effects: Array[Dictionary] = []
var kills := 0
var deaths := 0
var elapsed := 0.0
var _taunts := {}
var _dialogue_layer: Node2D
var _animation := LiaAnimation.new()
var _light: Sprite2D
var _backgrounds: Array[Sprite2D] = []
var collision_audit := false
var _light_material: ShaderMaterial
var _hud: Control
var difficulty := "operation"
var upgrades: Array = []
var move_speed := 205.0
var fire_interval := 0.145
var pulse_speed := 640.0
var pulse_damage := 1
var dash_recharge := 1.2
var objective_guide := Guide.new()
var _guide_layer: Node2D
var guidance_path := PackedVector2Array()
var _guide_timer := 0.0
var _guide_target := Vector2.INF
var sound: Node
var _muted := false
var campaign := CampaignProgress.new()
var module_notice := ""

class GuidanceLayer extends Node2D:
	var game: Node2D

	func _draw() -> void:
		if game.state != "play": return
		draw_set_transform(game._offset())
		game.objective_guide.draw_world(self, game.clock, game.objective_guide.intensity)
		var candidate: Dictionary = game._interaction_candidate()
		if not candidate.is_empty():
			FieldHUD.interaction(self, candidate.pos, game.clock)
		draw_set_transform(Vector2.ZERO)


func _ready() -> void:
	_apply_handoff()
	sound = Sound.new()
	add_child(sound)
	var settings := ConfigFile.new()
	if settings.load("user://settings.cfg") == OK:
		_muted = settings.get_value("audio", "muted", false)
		dialogue_fast = settings.get_value("narrative", "instant_prologue_text", false)
	sound.set_muted(_muted)
	objective_guide.configure(settings, "residues")
	sound.set_mood("calm")
	Actors.ENEMIES.prepare()
	for i in 4:
		var background := Sprite2D.new()
		background.texture = M.SECTORS[i]
		background.centered = false
		background.scale = M.SIZE * 0.5 / background.texture.get_size()
		background.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		background.z_index = -10
		var background_material := ShaderMaterial.new()
		background_material.shader = BACKGROUND_SHADER
		background_material.set_shader_parameter("reference_plate", M.PLATE)
		background_material.set_shader_parameter("quadrant", Vector2(i % 2, i / 2))
		background.material = background_material
		add_child(background)
		_backgrounds.append(background)
	_setup_lighting()
	_guide_layer = GuidanceLayer.new()
	_guide_layer.game = self
	add_child(_guide_layer)
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	_hud = HUD.new()
	_hud.game = self
	_hud.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_hud)
	# The shared RPG dialogue frame draws on a Node2D, above the field HUD.
	_dialogue_layer = DialogueLayer.new()
	_dialogue_layer.game = self
	layer.add_child(_dialogue_layer)
	_spawn_enemies()
	M.prepare_navigation()
	camera = pos.clamp(get_viewport_rect().size * 0.5, M.SIZE - get_viewport_rect().size * 0.5)
	_light.position = M.SIZE * 0.5 + _offset()
	_start_dialogue(Story.INTRO, "play")

func _apply_handoff() -> void:
	campaign.load_progress()
	var retry: Dictionary = get_tree().get_meta("p17_residues_retry", {})
	if get_tree().has_meta("p17_residues_retry"): get_tree().remove_meta("p17_residues_retry")
	deaths = retry.get("deaths", 0)
	elapsed = retry.get("time", 0.0)
	if get_tree().has_meta("p17_residue_handoff"):
		var data: Dictionary = get_tree().get_meta("p17_residue_handoff")
		difficulty = data.get("difficulty", "operation")
		upgrades = data.get("upgrades", []).duplicate()
	else:
		if campaign.water_completed:
			difficulty = campaign.difficulty
			upgrades = campaign.upgrades.duplicate()
	# Same base values and perk effects as Water; see campaign_loadout.gd.
	var loadout := Loadout.new()
	loadout.configure(difficulty, upgrades)
	difficulty = loadout.difficulty
	max_hp = loadout.max_hp
	move_speed = loadout.move_speed
	fire_interval = loadout.fire_interval
	pulse_speed = loadout.pulse_speed
	pulse_damage = loadout.pulse_damage
	dash_recharge = loadout.dash_recharge
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
		var kind := "boss" if boss else ("scout" if i % 2 == 0 else "sentry")
		# Continue the resistance of Water's last sector; never reset to prototype HP.
		var health := Simulation.enemy_health(kind, 3)
		enemies.append({"pos": M.ENEMY_POSITIONS[i], "home": M.ENEMY_POSITIONS[i], "kind": kind, "hp": health, "max_hp": health, "zone": 2 if boss else i / 2,
		"shot_cd": 1.1 + i * 0.19, "hit_cd": 0.0, "phase": 0.0, "id": i, "boss": boss})

func _physics_process(delta: float) -> void:
	var dt := minf(delta, 0.05)
	clock += dt
	pointer = get_viewport().get_mouse_position()
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT): _map_mouse_held=false
	_update_audio()
	if Input.is_physical_key_pressed(KEY_R) and state == "defeat":
		_retry()
		return
	if state == "dialogue":
		dialogue_chars += dt * (400.0 if dialogue_fast else 46.0)
	_update_effects(dt)
	if state != "play":
		_update_objective_guide(dt)
		queue_redraw()
		_hud.queue_redraw()
		_dialogue_layer.queue_redraw()
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
	toxic_cd = maxf(0, toxic_cd - dt)
	bin_lock = maxf(0, bin_lock - dt)
	fire_cd = maxf(0, fire_cd - dt)
	toast_time = maxf(0, toast_time - dt)
	if dash_requested and dash_cd <= 0.0 and movement != Vector2.ZERO:
		dash_time = 0.16
		dash_cd = dash_recharge
		invuln = 0.16
		sound.play_sfx("dash")
	dash_requested = false
	velocity = velocity.move_toward(movement * (620.0 if dash_time > 0 else move_speed), 1800 * dt)
	var previous := pos
	_move_player(velocity * dt)
	_animation.advance(dt, (pos - previous) / dt, dash_time > 0)
	if secondary_requested and secondary_cd <= 0.0:
		_fire(target, true)
		secondary_cd = 3.8
	elif ((Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not _map_mouse_held) or _key(KEY_SPACE)) and fire_cd <= 0.0:
		_fire(target)
	secondary_requested = false
	var e_down := _key(KEY_E)
	_interact(dt, e_down, e_down and not interact_down)
	interact_down = e_down
	_guide_timer -= dt
	_update_guidance()
	_update_enemies(dt)
	_update_bullets(dt)
	_check_toxic()
	camera = camera.lerp(pos + aim * 52.0, 1.0 - exp(-dt * 6.0))
	var half := get_viewport_rect().size * 0.5
	camera = camera.clamp(half, M.SIZE - half)
	_light.position = M.SIZE * 0.5 + _offset()
	_light_material.set_shader_parameter("scene_time", clock)
	_light_material.set_shader_parameter("restored", float(stage))
	_light_material.set_shader_parameter("ventilation", float(int(cleared[2]) + int(cleared[3])))
	_update_objective_guide(dt)
	queue_redraw()
	_hud.queue_redraw()

func _key(code: Key) -> bool:
	return Input.is_physical_key_pressed(code)

func _unhandled_input(event: InputEvent) -> void:
	if state == "dialogue":
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			for button in buttons:
				if button.id == "intro_fast" and button.rect.has_point(event.position):
					dialogue_fast = not dialogue_fast
					get_viewport().set_input_as_handled()
					return
			_advance_dialogue()
			get_viewport().set_input_as_handled()
		elif event is InputEventKey and event.pressed and not event.echo:
			match event.physical_keycode:
				KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_E: _advance_dialogue()
				KEY_TAB: dialogue_fast = not dialogue_fast
				KEY_ESCAPE: _finish_dialogue()
			get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for button in buttons:
			if button.rect.has_point(event.position):
				_map_mouse_held = true
				get_viewport().set_input_as_handled()
				_action(button.id)
				return
	if state=="map" and event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT and HUD.MapUI.close_rect(get_viewport_rect().size).has_point(event.position):
		state="play"
		_map_mouse_held=true
		dash_requested=false
		secondary_requested=false
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT and state == "play":
		secondary_requested = true
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE:
			_clear_pending_actions()
			state = "play" if state in ["pause", "map"] else ("pause" if state == "play" else state)
			get_viewport().set_input_as_handled()
		elif event.physical_keycode == KEY_M and state in ["play", "map"]:
			_clear_pending_actions()
			state = "play" if state == "map" else "map"
			get_viewport().set_input_as_handled()
		elif event.physical_keycode == KEY_R and state == "pause":
			_retry()
		elif event.physical_keycode in [KEY_ENTER, KEY_KP_ENTER] and state == "victory":
			_action("modules")
		elif event.physical_keycode in [KEY_1, KEY_2, KEY_3] and state == "upgrade":
			_action("module_%d" % (event.physical_keycode - KEY_1))
		elif event.physical_keycode == KEY_B and state in ["pause", "victory", "defeat"]:
			_return_to_districts()
		elif event.physical_keycode == KEY_SHIFT and state == "play":
			dash_requested = true
		elif event.physical_keycode == KEY_Q and state == "play":
			secondary_requested = true
		elif event.physical_keycode == KEY_F10:
			_muted = not _muted
			sound.set_muted(_muted)
		elif event.physical_keycode == KEY_F11:
			var fullscreen := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if fullscreen else DisplayServer.WINDOW_MODE_FULLSCREEN)

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
		"retry": _retry()
		"districts": _return_to_districts()
		"modules":
			if state == "victory": state = "upgrade"
		_:
			if id.begins_with("module_") and state == "upgrade":
				choose_module(int(id.trim_prefix("module_")))
	queue_redraw()
	_hud.queue_redraw()

## Records Residues, installs the fourth module and opens Energy. A failed save
## keeps the player on the module screen so the choice can be retried.
func choose_module(index: int) -> bool:
	if state != "upgrade" or index < 0 or index >= Loadout.RESIDUE_UPGRADES.size(): return false
	var id: String = Loadout.RESIDUE_UPGRADES[index].id
	var loadout := {"difficulty": difficulty, "upgrades": upgrades.duplicate() + [id]}
	# A scene opened directly in the editor has no Water save to extend.
	if campaign.water_completed:
		if campaign.complete_residues(difficulty, id, {"kills": kills, "deaths": deaths, "time": elapsed}) != OK:
			module_notice = "Não foi possível salvar o progresso. Tente novamente."
			return false
		loadout = campaign.energy_loadout(difficulty)
	module_notice = ""
	sound.play_sfx("complete")
	_open_power(loadout)
	return true

func _open_power(loadout: Dictionary) -> void:
	if get_tree().has_meta("p17_residue_handoff"): get_tree().remove_meta("p17_residue_handoff")
	get_tree().set_meta("p17_power_handoff", loadout)
	get_tree().change_scene_to_file("res://scenes/power.tscn")

func _retry() -> void:
	get_tree().set_meta("p17_residues_retry", {"deaths": deaths, "time": elapsed})
	get_tree().reload_current_scene()

func _return_to_districts() -> void:
	get_tree().set_meta("p17_open_districts", true)
	if get_tree().has_meta("p17_residue_handoff"): get_tree().remove_meta("p17_residue_handoff")
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _update_audio() -> void:
	var mood := "calm"
	if state in ["victory", "upgrade"]: mood = "victory"
	elif state == "play":
		for enemy in enemies:
			if enemy.hp > 0 and enemy.zone <= stage and enemy.pos.distance_to(pos) < 340:
				mood = "boss" if enemy.boss else "combat"
				if enemy.boss: break
	sound.set_mood(mood)
	var proximity := 0.0
	for i in 3:
		if terminal_on[i]: proximity = maxf(proximity, 1.0 - pos.distance_to(M.TERMINALS[i]) / 350.0)
	sound.set_structure_hum(state == "play", proximity)

func _offset() -> Vector2:
	return (get_viewport_rect().size * 0.5 - camera).round()

func _move_player(change: Vector2) -> void:
	pos = M.slide(pos, change, 14.0, stage, cleared)

func _fire(target: Vector2, secondary: bool = false) -> void:
	fire_cd = fire_interval
	sound.play_sfx("shoot")
	# Match Water's held pose, emitter, target correction and five-pulse burst.
	var start: Vector2 = pos + LIA_POSE.pose(aim, _animation.elapsed, _animation.moving).muzzle
	if not M.line_clear(pos, start, 3.0, stage, cleared): return
	var direction := (target - start).normalized() if target.is_finite() and target.distance_squared_to(start) > 1.0 else aim
	if secondary:
		for index in 5:
			bullets.append({"pos": start, "source": start, "vel": direction.rotated(float(index - 2) * 0.12) * pulse_speed * 0.85, "hostile": false, "life": 1.2, "damage": pulse_damage + 1})
	else:
		bullets.append({"pos": start, "source": start, "vel": direction * pulse_speed, "hostile": false, "life": 1.7, "damage": pulse_damage})

func shot_age() -> float:
	return fire_interval - fire_cd if fire_cd > 0.0 else -1.0

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
		sound.play_sfx("ui")
		_set_toast("MATERIAL COLETADO  /  " + M.MATERIALS[index])
	elif kind == "bin" and pressed and carried >= 0:
		if bin_lock > 0.0:
			_set_toast("BAIAS TRAVADAS  /  AGUARDE A REINICIALIZAÇÃO")
			return
		if carried == index:
			sorted[index] = true
			carried = -1
			sound.play_sfx("repair")
			_burst(M.BINS[index] + Vector2(0, -20), CYAN, 12)
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
		sound.play_sfx("repair")
		_burst(M.BLOCKS[index] + Vector2(0, -20), GOLD, 14)
		_set_toast("ROTA DE CARGA LIBERADA")
	else:
		terminal_on[index] = true
		stage += 1
		sound.play_sfx("complete")
		_burst(M.TERMINALS[index] + Vector2(0, -40), CYAN, 26)
		_start_dialogue([Story.SORTING, Story.RECYCLING, Story.FINAL][index], "victory" if stage == 3 else "play")

func _spawn_alarm_drone() -> void:
	var active := 0
	for enemy in enemies:
		if enemy.get("alarm", false) and enemy.hp > 0: active += 1
	if active >= 2: return
	var location := Vector2(453, 455) * M.SCALE if active == 0 else Vector2(337, 470) * M.SCALE
	var health := Simulation.enemy_health("scout", 3)
	enemies.append({"pos": location, "home": location, "kind": "scout", "hp": health, "max_hp": health, "zone": 0,
		"shot_cd": 0.5, "hit_cd": 0.0, "phase": 0.0, "id": enemies.size(), "boss": false, "alarm": true})

func _interaction_candidate() -> Dictionary:
	var candidates: Array[Dictionary] = []
	if stage == 0:
		if carried < 0:
			for i in 4:
				if not sorted[i]: candidates.append({"kind": "item", "index": i, "pos": M.ITEMS[i], "reach": 51.0})
		else:
			for i in 4:
				candidates.append({"kind": "bin", "index": i, "pos": M.BINS[i], "reach": 48.0})
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
		# Ignore only the target's own base; walls and other machines still block E.
		var body := ""
		if candidate.kind == "block": body = ("sucata %d" if candidate.index < 2 else "válvula %d") % candidate.index
		elif candidate.kind == "terminal": body = "terminal %d" % candidate.index
		if distance <= candidate.reach and distance < best and M.line_clear(pos, candidate.pos, 0.5, stage, cleared, body):
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
		if carried >= 0: return M.BINS[carried]
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

func objective_place() -> String:
	match stage:
		0:
			if carried >= 0: return "BAIA DE " + M.MATERIALS[carried]
			for i in sorted.size():
				if not sorted[i]: return "CARGA DE " + M.MATERIALS[i]
			return "CENTRO DE TRIAGEM"
		1:
			if not (cleared[0] and cleared[1]): return "ROTA DA PRENSA"
			return "USINA DE RECICLAGEM"
		2:
			if not (cleared[2] and cleared[3]): return "DUTOS ORGÂNICOS"
			return "UNIDADE DE COMPOSTAGEM"
	return "DISTRITO RECUPERADO"


func _update_objective_guide(dt: float) -> void:
	var size := get_viewport_rect().size
	objective_guide.in_combat = false
	for enemy in enemies:
		if enemy.hp > 0 and enemy.zone <= stage and pos.distance_squared_to(enemy.pos) <= 40000.0:
			objective_guide.in_combat = true
			break
	objective_guide.update(dt, pos, guidance_point(), objective_point(), Transform2D(0.0, _offset()),
		FieldHUD.guide_safe_rect(size), state == "play", objective_place(), size)
	objective_guide.cues(dt, sound)
	_guide_layer.queue_redraw()


func _update_guidance() -> void:
	var target := objective_point()
	if _guide_timer > 0.0 and target.distance_to(_guide_target) < 25.0: return
	_guide_target = target
	_guide_timer = 0.65
	var reach := 35.0 if stage == 0 and (carried >= 0 or sorted.has(false)) else 65.0
	var body := ""
	for i in 4:
		if target == M.BLOCKS[i]: body = ("sucata %d" if i < 2 else "válvula %d") % i
	for i in 3:
		if target == M.TERMINALS[i]: body = "terminal %d" % i
	guidance_path = M.path_between(pos, target, stage, cleared, reach, 14.0, true, body)

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

func _update_enemies(dt: float) -> void:
	for i in enemies.size():
		var enemy: Dictionary = enemies[i]
		if enemy.hp <= 0:
			if enemy.get("death_age", -1.0) >= 0.0: enemy.death_age += dt
			continue
		if enemy.zone > stage: continue
		enemy.hit_cd = maxf(0.0, enemy.hit_cd - dt)
		enemy.shot_cd -= dt
		enemy.phase += dt
		var distance: float = enemy.pos.distance_to(pos)
		var visible := M.line_clear(enemy.pos, pos, 3.0, stage, cleared)
		if distance < 520: enemy["engaged"] = true
		var radius := 25.0 if enemy.boss else 18.0
		if enemy.get("engaged", false) and (distance > (145.0 if enemy.boss else 125.0) or not visible):
			enemy["route_timer"] = float(enemy.get("route_timer", 0.0)) - dt
			var changed := int(enemy.get("route_geometry", -1)) != M._geometry_key(stage, cleared)
			if changed or enemy.route_timer <= 0.0 or Vector2(enemy.get("route_target", Vector2.INF)).distance_to(pos) > 64.0:
				enemy["route"] = M.path_between(enemy.pos, pos, stage, cleared, 85.0, radius, true)
				if enemy.route.is_empty(): enemy.route = M.path_between(enemy.pos, pos, stage, cleared, 410.0, radius, true)
				enemy["route_cursor"] = 0
				enemy["route_timer"] = 1.0 + i * 0.07
				enemy["route_target"] = pos
				enemy["route_geometry"] = M._geometry_key(stage, cleared)
			var route: PackedVector2Array = enemy.get("route", PackedVector2Array())
			var cursor: int = enemy.get("route_cursor", 0)
			while cursor < route.size() and enemy.pos.distance_to(route[cursor]) < 8.0: cursor += 1
			enemy["route_cursor"] = cursor
			if cursor < route.size():
				var travel: Vector2 = (route[cursor] - Vector2(enemy.pos)).normalized() * (43.0 if enemy.boss else 68.0)
				# Gentle separation prevents drones stacking in entrances. Floor and
				# machine collision still govern the final displacement.
				for j in enemies.size():
					if j == i or enemies[j].hp <= 0 or enemies[j].zone > stage: continue
					var away: Vector2 = enemy.pos - enemies[j].pos
					var gap := radius + (25.0 if enemies[j].boss else 18.0) + 9.0
					if away.length() < gap:
						travel += away.normalized() * (gap - away.length()) * 3.0
				var before: Vector2 = enemy.pos
				enemy.pos = M.slide(before, travel.limit_length(80.0) * dt, radius, stage, cleared)
				if enemy.pos.distance_to(before) < 0.1: enemy.route_timer = minf(enemy.route_timer, 0.15)
		if distance < 440 and visible and enemy.shot_cd <= 0.0:
			var direction: Vector2 = (pos - enemy.pos).normalized()
			var spreads := [-0.20, 0.0, 0.20] if enemy.boss else [0.0]
			for spread in spreads:
				bullets.append({"pos": enemy.pos + direction * 28, "vel": direction.rotated(spread) * (260.0 if enemy.boss else 235.0) * float(SHOT_SPEED[difficulty]), "hostile": true, "life": 2.2})
			enemy.shot_cd = (1.35 if enemy.boss else 1.55 + (i % 3) * 0.31) * float(PRESSURE[difficulty])
			sound.play_sfx("unit_" + ("boss" if enemy.boss else "scout") + "_fire")
		enemies[i] = enemy

func _update_bullets(dt: float) -> void:
	for i in range(bullets.size() - 1, -1, -1):
		var bullet: Dictionary = bullets[i]
		bullet.life -= dt
		var gone: bool = bullet.life <= 0.0
		var steps := maxi(1, int(ceil(Vector2(bullet.vel).length() * dt / 4.0)))
		for step in steps:
			if gone: break
			bullet.pos += bullet.vel * dt / steps
			gone = not M.walkable(bullet.pos, 3.0, stage, cleared)
			if gone: break
			if bullet.hostile:
				if bullet.pos.distance_to(pos) < 17 and invuln <= 0.0:
					_damage()
					gone = true
			else:
				for j in enemies.size():
					var enemy: Dictionary = enemies[j]
					if enemy.hp > 0 and enemy.zone <= stage and bullet.pos.distance_to(enemy.pos) < (28.0 if enemy.boss else 21.0):
						enemy.hp = maxi(0, enemy.hp - int(bullet.damage))
						enemy.hit_cd = 0.18
						enemy["engaged"] = true
						if enemy.hp <= 0:
							enemy["death_age"] = 0.0
							kills += 1
							sound.play_sfx("enemy_dead")
							_burst(enemy.pos + Vector2(0, -10), PINK, 18 if enemy.boss else 10)
						else:
							sound.play_sfx("unit_%s_hit" % _enemy_view(enemy).kind)
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
			if not _taunts.has("toxic") and state == "play":
				_taunts["toxic"] = true
				_set_toast(Story.AI_TAUNTS.toxic, true)
			toxic_cd = 1.15
			break

func _damage() -> void:
	if invuln > 0.0: return
	sound.play_sfx("hurt")
	hp -= 1
	invuln = 0.68
	if hp <= 0:
		deaths += 1
		state = "defeat"
		_set_toast("O distrito será reiniciado; Águas permanece recuperado.")

func _set_toast(message: String, from_ai: bool = false) -> void:
	toast = message
	toast_time = 3.6
	toast_ai = from_ai

# ---------------------------------------------------------------- dialogue

func _start_dialogue(lines: Array, next_state: String) -> void:
	dialogue = lines.duplicate()
	dialogue_chars = 0.0
	after_dialogue = next_state
	state = "dialogue"
	toast_time = 0.0
	_clear_pending_actions()
	if _dialogue_layer != null: _dialogue_layer.queue_redraw()

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
	_clear_pending_actions()
	if _dialogue_layer != null: _dialogue_layer.queue_redraw()
	if state == "play": _set_toast(["OBJETIVO  /  CLASSIFICAR OS QUATRO MATERIAIS", "PRÓXIMA ÁREA  /  USINA DE RECICLAGEM", "PRÓXIMA ÁREA  /  UNIDADE DE COMPOSTAGEM"][mini(stage, 2)])

# ---------------------------------------------------------------- effects

func _burst(at: Vector2, color: Color, count: int) -> void:
	effects.append({"kind": "burst", "pos": at, "color": color, "count": count, "life": 0.45, "max": 0.45, "seed": randf() * TAU})

func _update_effects(dt: float) -> void:
	for i in range(effects.size() - 1, -1, -1):
		effects[i].life -= dt
		if effects[i].life <= 0.0: effects.remove_at(i)

func _draw_effect(effect: Dictionary) -> void:
	var t: float = 1.0 - effect.life / effect.max
	for k in int(effect.count):
		var direction := Vector2.from_angle(float(k) / effect.count * TAU + effect.seed)
		var p: Vector2 = effect.pos + direction * t * 34.0 + Vector2(0, t * t * 18.0)
		draw_line(p, p - direction * 5.0 * (1.0 - t), Color(effect.color, 1.0 - t), 2)

func _draw() -> void:
	var offset := _offset()
	for i in _backgrounds.size(): _backgrounds[i].position = offset + Vector2(i % 2, i / 2) * M.SIZE * 0.5
	draw_set_transform(offset)
	M.draw_map(self, clock, stage, sorted, cleared, terminal_on, carried, false)
	var depth_entries: Array[Dictionary] = []
	for prop in M.props(sorted, cleared, terminal_on, carried):
		depth_entries.append({"kind": "prop", "depth": prop.depth, "data": prop})
	for prop in M.occluders():
		depth_entries.append({"kind": "occluder", "depth": prop.depth, "data": prop})
	for enemy in enemies:
		if enemy.zone > stage: continue
		if enemy.hp > 0 or (enemy.get("death_age", -1.0) >= 0.0 and enemy.death_age < 1.05):
			depth_entries.append({"kind": "enemy", "depth": enemy.pos.y + 18.0, "data": enemy})
	depth_entries.append({"kind": "lia", "depth": pos.y + 18.0})
	depth_entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.depth < b.depth)
	var scenery: Array[Dictionary] = []
	for entry in depth_entries:
		var bounds := _scenery_bounds(entry)
		if bounds.has_area(): scenery.append({"y": float(entry.depth), "bounds": bounds})
	var ghosts: Array[Dictionary] = []
	for entry in depth_entries:
		match entry.kind:
			"prop": M.draw_prop(self, entry.data, clock)
			"occluder": M.draw_occluder(self, entry.data)
			"enemy":
				_draw_enemy(entry.data)
				var enemy: Dictionary = entry.data
				if enemy.hp > 0 and Occlusion.is_hidden(Occlusion.drone_rect(enemy.pos, enemy.boss), float(entry.depth), scenery):
					ghosts.append(enemy)
			"lia":
				_draw_lia()
				if Occlusion.is_hidden(Occlusion.lia_rect(pos), float(entry.depth), scenery):
					ghosts.append({"lia": true})
	# Actors behind the biodigesters, the truck or lamp posts stay readable.
	for ghost in ghosts:
		if ghost.has("lia"):
			Occlusion.draw_lia_ghost(self, pos, aim, _animation.elapsed, _animation.moving, "repair" if hold_progress > 0 else "idle")
		else:
			Occlusion.draw_drone_ghost(self, _enemy_view(ghost), clock + int(ghost.id) * 0.137)
	for bullet in bullets:
		if not bullet.hostile:
			Actors.WEAPON.draw_pulse(self, bullet, clock)
		else:
			draw_line(bullet.pos - bullet.vel.normalized() * 14, bullet.pos, Color(PINK, 0.45), 6)
			draw_circle(bullet.pos, 4, PINK)
	for effect in effects: _draw_effect(effect)
	if collision_audit:
		M.draw_collision_audit(self, stage, cleared)
		draw_arc(pos, 14, 0, TAU, 24, Color.WHITE, 1)
		for enemy in enemies:
			if enemy.hp > 0 and enemy.zone <= stage: draw_arc(enemy.pos, 25 if enemy.boss else 18, 0, TAU, 24, Color("f4d977"), 1)
	draw_set_transform(Vector2.ZERO)

func _draw_lia() -> void:
	var action := "repair" if hold_progress > 0 else ("fire" if fire_cd > 0 else "idle")
	Actors.draw_lia(self, pos, aim, _animation.elapsed, _animation.moving, invuln > 0 and int(clock * 16) % 2 == 0, dash_time > 0, action, shot_age())
	if carried >= 0:
		M.draw_sprite(self, carried, pos + Vector2(-14, -25), 24)

func _scenery_bounds(entry: Dictionary) -> Rect2:
	if entry.kind in ["prop", "occluder"]: return M.scenery_bounds(entry.kind, entry.data)
	return Rect2()

func _enemy_view(enemy: Dictionary) -> Dictionary:
	var view := enemy.duplicate()
	view["kind"] = enemy.get("kind", "boss" if enemy.boss else ("scout" if enemy.id % 2 == 0 else "sentry"))
	view["max_hp"] = enemy.get("max_hp", Simulation.enemy_health(view.kind, 3))
	view["facing"] = (pos - Vector2(enemy.pos)).normalized()
	view["phase"] = "windup" if enemy.shot_cd < 0.27 else "idle"
	view["warning"] = 1.0 if enemy.shot_cd < 0.27 else 0.0
	view["hurt"] = enemy.hit_cd
	view["moving"] = enemy.pos.distance_to(pos) < 420
	return view

func _draw_enemy(enemy: Dictionary) -> void:
	var view := _enemy_view(enemy)
	if enemy.hp <= 0:
		view["anim_time"] = clock + enemy.id * 0.137
		Actors.ENEMIES.draw_destroyed(self, view)
		return
	Actors.draw_drone(self, view, clock + enemy.id * 0.137)
	if enemy.boss or enemy.hp < view.max_hp:
		var width := 70.0 if enemy.boss else 34.0
		var bar := Rect2(enemy.pos + Vector2(-width * 0.5, -54 if enemy.boss else -38), Vector2(width, 4))
		draw_rect(bar.grow(1), Color("07171d"))
		draw_rect(bar, Color("263b40"))
		draw_rect(Rect2(bar.position, Vector2(width * clampf(float(enemy.hp) / view.max_hp, 0, 1), 4)), PINK)
