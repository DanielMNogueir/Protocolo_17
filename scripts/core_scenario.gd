extends Node2D

const Map = preload("res://scripts/core_map.gd")
const Boss = preload("res://scripts/core_boss.gd")
const Choice = preload("res://scripts/core_choice.gd")
const Story = preload("res://scripts/core_story.gd")
const Art = preload("res://scripts/core_art.gd")
const HUD = preload("res://scripts/core_hud.gd")
const Ending = preload("res://scripts/ending_sequence.gd")
const Actors = preload("res://scripts/actors_art.gd")
const LiaAnimation = preload("res://scripts/lia_animation.gd")
const Pose = preload("res://scripts/lia_directional.gd")
const Audio = preload("res://scripts/audio.gd")
const Progress = preload("res://scripts/campaign_progress.gd")
const Loadout = preload("res://scripts/campaign_loadout.gd")
const Guide = preload("res://scripts/objective_guide.gd")
const Lighting = preload("res://scripts/power_lighting.gdshader")

class Effects extends Node2D:
	var game: Node2D

	func _draw() -> void:
		Art.effects(self, game)
		game.guide.draw_world(self, game.clock, game.guide.intensity)

var map := Map.new()
var campaign := Progress.new()
var loadout := Loadout.new()
var choice := Choice.new()
var ending := Ending.new()
var guide := Guide.new()
var animation := LiaAnimation.new()
var boss: Boss
var sound: Audio
var state := "gallery"
var in_gallery := true
var channel_read := false
var checkpoint_phase := 1
var pos := Map.GALLERY_START
var camera := Map.GALLERY_START
var aim := Vector2.UP
var velocity := Vector2.ZERO
var pointer := Vector2.ZERO
var clock := 0.0
var elapsed := 0.0
var hp := 6
var kills := 0
var deaths := 0
var fire_cd := 0.0
var dash_cd := 0.0
var dash_time := 0.0
var secondary_cd := 0.0
var invuln := 0.0
var flash := 0.0
var arrival := 0.0
var collapse := 0.0
var terminal_hold := 0.0
var active_pillar := -1
var enemies: Array[Dictionary] = []
var shots: Array[Dictionary] = []
var effects: Array[Dictionary] = []
var buttons: Array[Dictionary] = []
var dialogue: Array = []
var dialogue_chars := 0.0
var dialogue_fast := false
var evidence: Dictionary = {}
var toast := ""
var toast_left := 0.0
var overlay_return := ""
var after_dialogue := ""
var test_endings: Array[String] = []
var save_error := false
var objective: Dictionary = {}
var _settings := ConfigFile.new()
var _route_time := 0.0
var _route_target := Vector2.INF
var _waypoint := Vector2.ZERO
var _tap_side := ""
var _tap_age := 0.0
var _e_previous := false
var _require_release := true
var _dash_requested := false
var _burst_requested := false
var _mouse_captured := false
var _shock_debt := 0.0
var _light: Sprite2D
var _light_material: ShaderMaterial
var _fx: Effects
var _hud: Node2D


func _ready() -> void:
	var handoff: Dictionary = get_tree().get_meta("p17_core_handoff", {})
	if get_tree().has_meta("p17_core_handoff"):
		get_tree().remove_meta("p17_core_handoff")
	campaign.path = handoff.get("save_path", campaign.path)
	campaign.load_progress()
	if handoff.is_empty() and campaign.energy_completed:
		handoff = campaign.core_loadout(campaign.difficulty)
	loadout.configure(handoff.get("difficulty", "operation"), handoff.get("upgrades", []))
	boss = Boss.new(loadout.difficulty, loadout.timing_scale)
	hp = loadout.max_hp
	_settings.load("user://settings.cfg")
	dialogue_fast = _settings.get_value("narrative", "instant_prologue_text", false)
	guide.configure(_settings, "core")
	sound = Audio.new()
	add_child(sound)
	sound.set_muted(_settings.get_value("audio", "muted", false))
	sound.set_mood("suspense")
	Actors.ENEMIES.prepare()
	_create_layers()
	_talk(Story.GALLERY_ENTER, "gallery")
	_present(0.0)


func _create_layers() -> void:
	var pixel := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	pixel.fill(Color.WHITE)
	_light = Sprite2D.new()
	_light.texture = ImageTexture.create_from_image(pixel)
	_light.centered = false
	_light_material = ShaderMaterial.new()
	_light_material.shader = Lighting
	_light.material = _light_material
	add_child(_light)
	_fx = Effects.new()
	_fx.game = self
	add_child(_fx)
	var canvas := CanvasLayer.new()
	canvas.layer = 5
	add_child(canvas)
	_hud = HUD.new()
	_hud.game = self
	canvas.add_child(_hud)


func _physics_process(delta: float) -> void:
	var dt := minf(delta, 0.05)
	clock += dt
	pointer = get_viewport().get_mouse_position()
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_mouse_captured = false
	match state:
		"dialogue":
			dialogue_chars += dt * (1000.0 if dialogue_fast else (180.0 if Input.is_physical_key_pressed(KEY_ENTER) else 46.0))
		"arrival":
			_update_arrival(dt)
		"collapse":
			collapse -= dt
			if collapse <= 0.0:
				_talk(Story.PHASE3, "arena")
		"ending":
			_advance_ending(false, dt)
		"credits":
			if ending.tick_credits(dt, get_viewport_rect().size.y):
				state = "complete"
		"gallery", "arena", "choice", "overlook":
			var movement := Vector2(
				float(_key(KEY_D, KEY_RIGHT)) - float(_key(KEY_A, KEY_LEFT)),
				float(_key(KEY_S, KEY_DOWN)) - float(_key(KEY_W, KEY_UP))).normalized()
			var firing := Input.is_physical_key_pressed(KEY_SPACE) or (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not _mouse_captured)
			play_step(dt, movement, pointer - world_offset(), Input.is_physical_key_pressed(KEY_E), firing, _dash_requested, _burst_requested)
	_dash_requested = false
	_burst_requested = false
	_present(dt)


func _key(a: Key, b: Key) -> bool:
	return Input.is_physical_key_pressed(a) or Input.is_physical_key_pressed(b)


# Field input and combat share this path with the playthrough driver.
func play_step(dt: float, movement: Vector2, target: Vector2, held: bool, firing: bool = false,
		dash: bool = false, burst: bool = false) -> void:
	elapsed += dt
	toast_left = maxf(0.0, toast_left - dt)
	invuln = maxf(0.0, invuln - dt)
	fire_cd = maxf(0.0, fire_cd - dt)
	dash_cd = maxf(0.0, dash_cd - dt)
	dash_time = maxf(0.0, dash_time - dt)
	secondary_cd = maxf(0.0, secondary_cd - dt)
	if target.distance_squared_to(pos) > 9.0:
		aim = pos.direction_to(target)
	if state == "arena" and dash and dash_cd <= 0.0 and movement.length_squared() > 0.0:
		dash_time = 0.16
		dash_cd = loadout.dash_recharge
		invuln = maxf(invuln, 0.16)
		sound.play_sfx("dash")
	velocity = velocity.move_toward(movement * (650.0 if dash_time > 0.0 else loadout.move_speed), 1800.0 * dt)
	var previous := pos
	pos = Map.slide(pos, velocity * dt, 14.0, map_phase())
	animation.advance(dt, (pos - previous) / dt, dash_time > 0.0)

	if _require_release and not held:
		_require_release = false
	var active_e := held and not _require_release
	var pressed := active_e and not _e_previous
	match state:
		"gallery": _interact_gallery(dt, active_e)
		"arena":
			if burst and secondary_cd <= 0.0:
				_fire(target, true)
				secondary_cd = loadout.secondary_recharge
			elif firing and fire_cd <= 0.0:
				_fire(target, false)
			_interact_pillars(pressed)
			_combat(dt)
		"choice": _interact_choice(dt, active_e, pressed)
		"overlook":
			if pos.distance_to(Map.OVERLOOK) <= 36.0:
				_talk(Story.OVERLOOK, "human_cards")
	_e_previous = active_e


func _interact_gallery(dt: float, held: bool) -> void:
	if channel_read:
		if Map.STAIRS.has_point(pos):
			state = "arrival"
			arrival = 0.0
			velocity = Vector2.ZERO
		return
	terminal_hold = minf(1.1, terminal_hold + dt) if held and near(Map.TERMINAL, 78.0) else 0.0
	if terminal_hold >= 1.1:
		channel_read = true
		terminal_hold = 0.0
		sound.play_sfx("power_up")
		_talk(Story.COMMAND_CHANNEL, "gallery")


func _update_arrival(dt: float) -> void:
	arrival += dt
	if arrival >= 0.6 and in_gallery:
		in_gallery = false
		pos = Map.ENTRY
		camera = pos.lerp(Map.CENTER, 0.3)
		sound.play_sfx("power_up")
	if not in_gallery:
		var old := pos
		pos = Map.ENTRY.lerp(Map.ARRIVAL, clampf((arrival - 0.6) / 0.65, 0.0, 1.0))
		if dt > 0.0: animation.advance(dt, (pos - old) / dt, false)
	if arrival >= 1.3:
		_talk(Story.ARENA_INTRO, "arena")
		sound.set_mood("boss")


func map_phase() -> int:
	return 0 if in_gallery else boss.phase


func near(point: Vector2, radius: float = 80.0) -> bool:
	return pos.distance_squared_to(point) <= radius * radius


func pillar_in_reach() -> int:
	return _nearest_pillar(true)


func _nearest_pillar(require_reach: bool) -> int:
	var index := -1
	var distance := 80.0 if require_reach else INF
	var points := Map.pillars()
	for i in points.size():
		var current := pos.distance_to(points[i])
		if current <= distance and not boss.pillars[i].done:
			index = i
			distance = current
	return index


func _interact_pillars(pressed: bool) -> void:
	if boss.phase != 1:
		return
	var index := pillar_in_reach()
	if active_pillar >= 0 and index != active_pillar:
		boss.pillars[active_pillar].cancel()
		active_pillar = -1
	if index < 0 or not pressed:
		return
	var result := boss.press_pillar(index)
	match result:
		"start":
			active_pillar = index
			sound.play_sfx("overload_start")
		"hit":
			sound.play_sfx("relay")
		"miss":
			active_pillar = -1
			sound.play_sfx("discharge")
			_damage(true)
		"fallen":
			active_pillar = -1
			sound.play_sfx("pillar_fall")
			_emit(Map.pillars()[index], HUD.CYAN, 0.5)


func _fire(target: Vector2, burst: bool) -> void:
	fire_cd = loadout.fire_interval
	var source: Vector2 = pos + Pose.pose(aim, animation.elapsed, animation.moving).muzzle
	if target.is_equal_approx(source):
		return
	if not Map.line_clear(pos, source, 2.0, map_phase()):
		source = pos
	var direction := source.direction_to(target)
	sound.play_sfx("shoot")
	var count := 5 if burst else 1
	for index in count:
		var angle := (index - 2) * 0.12 if burst else 0.0
		shots.append({"pos": source, "vel": direction.rotated(angle) * loadout.pulse_speed,
			"hostile": false, "life": 1.7, "damage": loadout.pulse_damage + int(burst)})


func _combat(dt: float) -> void:
	if state != "arena":
		return
	var threatened := false
	for shot in shots:
		if shot.hostile and near(shot.pos, 90.0):
			threatened = true
			break
	var requests := boss.tick(dt, pos, velocity, dash_time > 0.0 or threatened)
	_boss_events()
	if state != "arena":
		return
	for request in requests:
		if request.kind == "spark":
			_spawn_spark(request.pos)
		else:
			_hostile(request.pos, request.vel)
	_tick_sparks(dt)
	_tick_shots(dt)
	_boss_events()
	if state != "arena":
		return
	if boss.attack == "laser" and boss.fire_time > 0.0:
		if _distance_to_segment(pos, boss.core_position(), boss.core_position() + Vector2.from_angle(boss.laser_angle()) * 1150.0) <= 17.0:
			_damage()
	if boss.phase == 2:
		for arc in boss.arcs:
			if arc.state(boss.phase_time) == "active" and arc.touches(pos, 13.0):
				_damage(true)


func _boss_events() -> void:
	for event in boss.events:
		match event:
			"phase2", "phase3", "down":
				shots.clear()
				for enemy in enemies:
					_emit(enemy.pos, HUD.CYAN, 0.55)
					kills += 1
				enemies.clear()
				flash = 1.0
				sound.play_sfx("emp")
				hp = mini(loadout.max_hp, hp + int(Boss.HEAL[loadout.difficulty]))
				invuln = maxf(invuln, 0.8)
				match event:
					"phase2":
						checkpoint_phase = 2
						sound.set_mood("blackout")
					"phase3":
						checkpoint_phase = 3
						collapse = 1.2
						state = "collapse"
						sound.set_mood("boss")
					"down":
						sound.set_mood("decision")
						_talk(Story.CHOICE_INTRO, "choice")
			"attack_warn":
				sound.play_sfx("laser_warn" if boss.attack == "laser" else "overload_start")
			"laser_fire":
				sound.play_sfx("laser_fire")
			"sunrise":
				sound.play_sfx("sunrise")
		if event in Story.TOASTS:
			toast = Story.TOASTS[event]
			if event == "adaptive":
				var parts := boss.adaptive_message.split(" ")
				toast = toast.format({"side": parts[0], "pct": parts[1]})
			toast_left = 4.2
	boss.events.clear()


func _spawn_spark(at: Vector2) -> void:
	if enemies.size() >= int(Boss.SPARK_CAP[loadout.difficulty]):
		return
	for enemy in enemies:
		if Vector2(enemy.pos).distance_to(at) < 44.0:
			return
	enemies.append({"kind": "spark", "pos": at, "facing": at.direction_to(pos), "hp": 3,
		"max_hp": 3, "radius": 16.0, "warning": 0.0, "hurt": 0.0, "windup": 0.0,
		"recharge": 1.0, "warp": 0.45, "route_time": 0.0, "waypoint": at, "arc_cd": 0.0})
	_emit(at, HUD.PINK, 0.45)


func _tick_sparks(dt: float) -> void:
	for i in range(enemies.size() - 1, -1, -1):
		var enemy := enemies[i]
		var at: Vector2 = enemy.pos
		var distance := at.distance_to(pos)
		enemy.warp = maxf(0.0, enemy.warp - dt)
		enemy.hurt = maxf(0.0, enemy.hurt - dt)
		enemy.arc_cd = maxf(0.0, enemy.arc_cd - dt)
		if enemy.warp > 0.0:
			continue
		var clear := distance < 360.0 and Map.line_clear(at, pos, 2.0, boss.phase)
		if enemy.windup > 0.0:
			enemy.windup = maxf(0.0, enemy.windup - dt)
			enemy.warning = enemy.windup / (0.65 * float(Boss.WINDUP[loadout.difficulty]))
			if enemy.windup <= 0.0:
				_hostile(at + Vector2(0, -5), Vector2(enemy.facing) * 195.0 * float(Boss.Simulation.HOSTILE_SPEED[loadout.difficulty]))
				sound.play_sfx("unit_scout_fire")
				enemy.recharge = 1.7 * float(Boss.PRESSURE[loadout.difficulty])
			continue
		enemy.recharge = maxf(0.0, enemy.recharge - dt)
		enemy.facing = at.direction_to(pos)
		if clear and distance < 225.0 and enemy.recharge <= 0.0:
			enemy.windup = 0.65 * float(Boss.WINDUP[loadout.difficulty])
			continue
		enemy.route_time -= dt
		if enemy.route_time <= 0.0:
			enemy.route_time = 0.3
			enemy.waypoint = map.waypoint(at, pos, boss.phase, 16.0)
		var course := at.direction_to(enemy.waypoint)
		if clear and distance < 90.0: course = -Vector2(enemy.facing)
		enemy.pos = Map.slide(at, course * 118.0 * dt, 16.0, boss.phase)
		if boss.phase == 2 and enemy.arc_cd <= 0.0:
			for arc in boss.arcs:
				if arc.state(boss.phase_time) == "active" and arc.touches(enemy.pos, 16.0):
					enemy.arc_cd = 0.5
					_hit_spark(i, 2)
					break


func _hostile(at: Vector2, velocity_value: Vector2) -> void:
	shots.append({"pos": at, "vel": velocity_value, "hostile": true, "life": 6.0})


func _tick_shots(dt: float) -> void:
	var remaining: Array[Dictionary] = []
	for shot in shots:
		var previous: Vector2 = shot.pos
		var next: Vector2 = previous + Vector2(shot.vel) * dt
		shot.life -= dt
		if shot.life <= 0.0 or not Rect2(Vector2.ZERO, Map.ARENA_SIZE).has_point(next):
			continue
		if shot.hostile:
			if _distance_to_segment(pos, previous, next) < 16.0:
				_damage()
				if state == "defeat":
					break
				continue
		elif _hit_player_shot(shot, previous, next):
			if boss.phase == 4:
				break
			continue
		shot.pos = next
		remaining.append(shot)
	shots = remaining


func _hit_player_shot(shot: Dictionary, previous: Vector2, next: Vector2) -> bool:
	if boss.phase == 2:
		var mirrors := Map.mirrors()
		for i in 3:
			if _distance_to_segment(mirrors[i], previous, next) <= 26.0:
				if boss.hit_mirror(i):
					sound.play_sfx("mirror")
					_emit(mirrors[i], HUD.GOLD, 0.3)
				return true
	if _distance_to_segment(boss.core_position(), previous, next) <= 56.0 or _distance_to_segment(Map.CENTER, previous, next) <= 72.0:
		var damage: float = shot.damage
		_emit(next, HUD.PINK if boss.hit_core(damage) else HUD.CYAN, 0.2)
		return true
	for i in enemies.size():
		if _distance_to_segment(enemies[i].pos, previous, next) <= 19.0 and enemies[i].warp <= 0.0:
			var hit_origin: Vector2 = enemies[i].pos
			_hit_spark(i, shot.damage)
			if loadout.chain_pulse:
				for j in enemies.size():
					var other: Vector2 = enemies[j].pos
					if other != hit_origin and other.distance_to(hit_origin) <= 120.0:
						_hit_spark(j, 1)
						break
			return true
	return not Map.line_clear(previous, next, 2.0, boss.phase)


func _hit_spark(index: int, damage: int) -> void:
	var enemy := enemies[index]
	enemy.hp -= damage
	enemy.hurt = 0.18
	if enemy.hp > 0:
		sound.play_sfx("unit_scout_hit")
	else:
		_emit(enemy.pos, HUD.CYAN, 0.55)
		enemies.remove_at(index)
		kills += 1
		sound.play_sfx("enemy_dead")


func _distance_to_segment(at: Vector2, from: Vector2, to: Vector2) -> float:
	return at.distance_to(Geometry2D.get_closest_point_to_segment(at, from, to))


func _emit(at: Vector2, color: Color, duration: float) -> void:
	effects.append({"pos": at, "color": color, "left": duration, "duration": duration})


func _damage(shock: bool = false) -> void:
	if state != "arena" or invuln > 0.0:
		return
	if shock:
		_shock_debt += loadout.shock_factor
		if _shock_debt < 1.0:
			invuln = 0.55
			sound.play_sfx("shield")
			return
		_shock_debt -= 1.0
	hp -= 1
	invuln = 0.8
	sound.play_sfx("hurt")
	if hp <= 0:
		deaths += 1
		state = "defeat"
		_clear_input()


func _retry() -> void:
	boss = Boss.new(loadout.difficulty, loadout.timing_scale, checkpoint_phase if loadout.difficulty == "story" else 1)
	boss.events.clear()
	checkpoint_phase = boss.phase
	hp = loadout.max_hp
	pos = Map.ARRIVAL
	velocity = Vector2.ZERO
	animation.reset()
	fire_cd = 0.0
	dash_cd = 0.0
	dash_time = 0.0
	secondary_cd = 0.0
	invuln = 0.8
	_shock_debt = 0.0
	active_pillar = -1
	shots.clear()
	enemies.clear()
	effects.clear()
	_clear_input()
	state = "arena"
	sound.set_mood("blackout" if boss.phase == 2 else "boss")


func side_at_console() -> String:
	if near(Map.CONSOLES[0]): return "human"
	if near(Map.CONSOLES[1]): return "ai"
	return ""


func _interact_choice(dt: float, held: bool, pressed: bool) -> void:
	var side := side_at_console()
	if pressed:
		_tap_side = side
		_tap_age = 0.0
	if held:
		_tap_age += dt
		if side != _tap_side:
			_tap_side = ""
		if choice.tick(dt, _tap_side, true) == "decided":
			_start_ending()
	elif _e_previous:
		choice.tick(dt, "", false)
		if _tap_age < Choice.TAP_TIME and side == _tap_side and not side.is_empty():
			var line := choice.listen(side)
			var total: int = campaign.campaign_totals().kills - int(campaign.stats.get("core", {}).get("kills", 0)) + kills
			line.text = str(line.text).replace("{kills}", str(total))
			evidence = {"side": side, "number": choice.heard_ai if side == "ai" else choice.heard_human, "kills": total}
			_talk([line], "choice")


func _start_ending() -> void:
	_clear_input()
	ending.start(choice.result)
	state = "ending"
	sound.set_mood("final_ai" if choice.result == "ai" else "victory")
	sound.play_sfx("antenna_beam" if choice.result == "ai" else "complete")


func _advance_ending(skip: bool, dt: float = 0.0) -> void:
	var previous := ending.sequence
	var transition := ending.step(dt, skip)
	if previous != ending.sequence and ending.sequence == "signal": sound.play_sfx("radio_static")
	match transition:
		"human_dialogue": _talk(Story.ISOLATE_DONE, "overlook")
		"ai_dialogue": _talk(Story.RELEASE_DONE, "ai_cards")
		"finish":
			_record_ending()
			ending.begin_credits()
			state = "credits"


func _record_ending() -> void:
	if not campaign.energy_completed:
		if choice.result not in test_endings:
			test_endings.append(choice.result)
		return
	save_error = campaign.complete_core(loadout.difficulty, choice.result,
		{"kills": kills, "deaths": deaths, "time": elapsed}) != OK


func _reopen() -> void:
	choice.reopen()
	_clear_input()
	pos = Map.ARRIVAL
	velocity = Vector2.ZERO
	state = "choice"
	sound.set_mood("decision")


func _talk(lines: Array, next: String) -> void:
	dialogue = lines.duplicate()
	dialogue_chars = 9999.0 if dialogue_fast else 0.0
	after_dialogue = next
	state = "dialogue"
	velocity = Vector2.ZERO
	if not dialogue.is_empty() and dialogue[0].speaker == "major_glitch": sound.play_sfx("radio_static")
	_clear_input()


func _advance_dialogue() -> void:
	if dialogue.is_empty():
		return
	if dialogue_chars < str(dialogue[0].text).length():
		dialogue_chars = 9999.0
		return
	dialogue.pop_front()
	dialogue_chars = 9999.0 if dialogue_fast else 0.0
	sound.play_sfx("ui")
	if dialogue.is_empty():
		_end_dialogue()


func _end_dialogue() -> void:
	dialogue.clear()
	evidence.clear()
	_clear_input()
	state = after_dialogue
	if state == "choice" and choice.weigh():
		_talk(Story.LIA_WEIGHS, "choice")
	elif state in ["ai_cards", "human_cards"]:
		ending.show_cards()
		state = "ending"


func _clear_input() -> void:
	_e_previous = false
	_require_release = true
	_tap_side = ""
	_tap_age = 0.0
	if choice.result.is_empty(): choice.tick(0.0, "", false)
	_dash_requested = false
	_burst_requested = false


func _action(id: String) -> void:
	match id:
		"intro_next": _advance_dialogue()
		"intro_fast":
			dialogue_fast = not dialogue_fast
			if dialogue_fast: dialogue_chars = 9999.0
		"map", "pause":
			overlay_return = state
			_clear_input()
			state = id
		"resume":
			if state in ["pause", "map"]:
				state = overlay_return
				_clear_input()
		"retry": _retry()
		"again":
			if save_error: _record_ending()
			if not save_error: _reopen()
		"skip_credits": state = "complete"
		"credits":
			ending.begin_credits()
			state = "credits"
		"save": _record_ending()
		"title":
			get_tree().change_scene_to_file("res://scenes/main.tscn")
		"next_card": _advance_ending(true)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT and state == "arena":
			_burst_requested = true
		elif event.button_index == MOUSE_BUTTON_LEFT:
			for button in buttons:
				if button.rect.has_point(event.position):
					_mouse_captured = true
					get_viewport().set_input_as_handled()
					_action(button.id)
					return
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	var key: Key = event.physical_keycode if event.physical_keycode else event.keycode
	if key == KEY_F11:
		get_window().mode = Window.MODE_WINDOWED if get_window().mode == Window.MODE_FULLSCREEN else Window.MODE_FULLSCREEN
		return
	if key == KEY_F10:
		var mute: bool = not _settings.get_value("audio", "muted", false)
		_settings.set_value("audio", "muted", mute)
		_settings.save("user://settings.cfg")
		sound.set_muted(mute)
		return
	match state:
		"dialogue":
			if key in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]: _advance_dialogue()
			elif key == KEY_TAB: _action("intro_fast")
			elif key == KEY_ESCAPE: _end_dialogue()
		"gallery", "arena", "choice", "overlook":
			if key == KEY_ESCAPE: _action("pause")
			elif key == KEY_M: _action("map")
			elif state == "arena" and key == KEY_SHIFT: _dash_requested = true
			elif state == "arena" and key == KEY_Q: _burst_requested = true
		"pause", "map":
			if key == KEY_ESCAPE or (key == KEY_M and state == "map"): _action("resume")
			elif key == KEY_B and state == "pause": _action("title")
		"defeat":
			if key in [KEY_R, KEY_ENTER]: _retry()
			elif key == KEY_B: _action("title")
		"ending":
			if key in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]: _advance_ending(true)
		"credits":
			if key in [KEY_ESCAPE, KEY_ENTER]: state = "complete"
		"complete":
			if key == KEY_R: _action("again")
			elif key == KEY_C: _action("credits")
			elif key == KEY_S and save_error: _action("save")
			elif key == KEY_ESCAPE: _action("title")


func world_offset() -> Vector2:
	return (get_viewport_rect().size * 0.5 - camera).round()


func _present(dt: float) -> void:
	var size := get_viewport_rect().size
	var extent := Map.GALLERY_SIZE if in_gallery else Map.ARENA_SIZE
	var focus := pos if in_gallery else pos.lerp(Map.CENTER, 0.3)
	var margin := (size * 0.5).min(extent * 0.5)
	camera = camera.lerp(focus.clamp(margin, extent - margin), 1.0 - exp(-dt * 7.0)) if dt > 0.0 else focus.clamp(margin, extent - margin)
	_fx.position = world_offset()
	_light.position = world_offset()
	_light.scale = extent
	_light_material.set_shader_parameter("map_size", extent)
	_light_material.set_shader_parameter("scene_time", clock)
	_light_material.set_shader_parameter("lia_pos", pos)
	_light_material.set_shader_parameter("aim", aim)
	_light_material.set_shader_parameter("flash", flash * 0.65)
	_light_material.set_shader_parameter("darkness", Art.darkness(self))
	var lights := Art.lights(self)
	_light_material.set_shader_parameter("lights", lights)
	_light_material.set_shader_parameter("light_count", lights.size())
	flash = maxf(0.0, flash - dt * 2.1)
	for i in range(effects.size() - 1, -1, -1):
		effects[i].left -= dt
		if effects[i].left <= 0.0: effects.remove_at(i)

	objective = objective_data()
	var active := state in ["gallery", "arena", "choice", "overlook"]
	var point: Vector2 = objective.point
	_route_time -= dt
	if active and (_route_time <= 0.0 or not point.is_equal_approx(_route_target)):
		_waypoint = map.waypoint(pos, point, map_phase())
		_route_target = point
		_route_time = 0.25
	guide.in_combat = false
	for enemy in enemies:
		if near(enemy.pos, 200.0):
			guide.in_combat = true
			break
	guide.update(dt, pos, _waypoint, point, Transform2D(0.0, world_offset()), HUD.Field.guide_safe_rect(size, -1.0, 201.0, 195.0 if active_pillar >= 0 else HUD.Field.GUIDE_BOTTOM),
		active, objective.place, size)
	guide.cues(dt, sound)
	var hum := clampf(1.0 - pos.distance_to(Map.CENTER) / 650.0, 0.0, 1.0)
	sound.set_structure_hum(not in_gallery and state in ["arena", "choice", "overlook"], hum, true)
	queue_redraw()
	_fx.queue_redraw()
	_hud.queue_redraw()


func objective_data() -> Dictionary:
	if in_gallery:
		return {"title": "GALERIA DO NÚCLEO", "text": "SUBA À COROA DA TORRE" if channel_read else "LEIA O CANAL DE COMANDO",
			"place": "ESCADA PARA A COROA" if channel_read else "CANAL DE COMANDO",
			"point": Map.STAIRS.get_center() if channel_read else Map.TERMINAL, "done": int(channel_read), "total": 1}
	if state == "overlook" or (state == "pause" and overlay_return == "overlook") or (state == "map" and overlay_return == "overlook"):
		return {"title": "MIRANTE", "text": "VÁ ATÉ O GUARDA-CORPO", "place": "MIRANTE NORTE",
			"point": Map.OVERLOOK, "done": 0, "total": 1}
	match boss.phase:
		1:
			var index := maxi(0, _nearest_pillar(false))
			return {"title": "DERRUBE OS PILARES", "text": "SOBRECARREGUE O " + Map.PILLAR_NAMES[index],
				"place": Map.PILLAR_NAMES[index], "point": Map.pillars()[index], "done": boss.fallen_count(), "total": 4}
		2:
			if boss.burn > 0.0:
				return {"title": "ALINHE O SOL", "text": "ATAQUE O NÚCLEO EXPOSTO", "place": "NÚCLEO AURORA",
					"point": Map.CENTER, "done": 3, "total": 3}
			var mirrors := Map.mirrors()
			var index := 0
			var distance := INF
			for i in 3:
				var current := pos.distance_squared_to(mirrors[i])
				if current < distance and not boss.mirrors.aligned(i):
					distance = current
					index = i
			return {"title": "ALINHE O SOL", "text": "ATIRE NOS ESPELHOS ATÉ ALINHAR", "place": Map.MIRROR_NAMES[index],
				"point": mirrors[index], "done": boss.aligned_count(), "total": 3}
		3:
			return {"title": "NÚCLEO EXPOSTO", "text": "ATAQUE E DESVIE DAS ESPIRAIS", "place": "NÚCLEO AURORA",
				"point": Map.CENTER, "done": 0, "total": 1}
	var human := choice.heard_human < choice.heard_ai
	if choice.heard_human == choice.heard_ai:
		human = pos.distance_squared_to(Map.CONSOLES[0]) <= pos.distance_squared_to(Map.CONSOLES[1])
	return {"title": "A DECISÃO", "text": "SEGURE E PARA DECIDIR" if choice.can_decide() else "OUÇA OS DOIS LADOS",
		"place": "CONSOLE DA BEATRIX" if human else "CONSOLE DA IA", "point": Map.CONSOLES[0 if human else 1],
		"done": int(choice.heard_ai > 0) + int(choice.heard_human > 0), "total": 2}


func _draw() -> void:
	Art.world(self)
