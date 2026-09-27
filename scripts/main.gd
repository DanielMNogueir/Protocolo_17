extends Node2D
## Original alpha shell: presentation, input, camera, interface and checkpoint I/O.
const World = preload("res://scripts/world.gd")
const StationArt = preload("res://scripts/station_art.gd")
const Simulation = preload("res://scripts/simulation.gd")
const Actors = preload("res://scripts/actors_art.gd")
const LiaAnimation = preload("res://scripts/lia_animation.gd")
const EnemyPresentation = preload("res://scripts/enemy_presentation.gd")
const Sound = preload("res://scripts/audio.gd")
const SAVE_PATH := "user://aurora_checkpoint.json"
const INK := Color("091922")
const PANEL := Color("102730")
const CYAN := Color("7be4ce")
const WHITE := Color("e9ece0")
const MUTED := Color("94aca9")
const GOLD := Color("e8bd74")
const MAGENTA := Color("e36b92")
const SECTOR_SUBTITLES := ["CAIS DE CAPTAÇÃO", "PÁTIO DE ENERGIA", "RESERVATÓRIOS DE FILTRAGEM", "CENTRAL DE DISTRIBUIÇÃO"]
const TRANSMISSIONS := [
	["COMANDO", "Lia, o Distrito das Águas parou de responder. Se os filtros cederem, a contaminação alcança toda Aurora."],
	["LIA", "Estou no cais. Os drones ainda têm energia… mas estão mirando em mim."],
	["COMANDO", "Essas máquinas foram feitas para proteger a cidade. Alguém mudou as ordens. Recupere os quatro sistemas. E encontre o registro de comando."],
]
const FIELD_MESSAGES := [
	["COMANDO", "Captação restabelecida. A ponte norte está aberta. Siga os cabos até o Pátio de Energia."],
	["LIA", "As baterias estão respondendo. Achei um comando externo nos drones. O registro é anterior à falha da rede."],
	["COMANDO", "Filtros ativos. Só falta a distribuição. Há uma unidade pesada defendendo o núcleo. Observe os avisos antes de avançar."],
]
var sim: P17Simulation = Simulation.new()
var lia_animation := LiaAnimation.new()
var enemy_presentation := EnemyPresentation.new()
var sound: Node
var mode := "title"
var previous_mode := "play"
var clock := 0.0
var camera_pos := World.START
var buttons: Array[Dictionary] = []
var pointer := Vector2.ZERO
var dash_requested := false
var muted := false
var fullscreen := false
var briefing_page := 0
var briefing_clock := 0.0
var dialogue: Array = []
var dialogue_clock := 0.0
var toast := ""
var toast_time := 0.0
var screen_flash := 0.0
var shake := 0.0
var last_stage := 0
var title_texture: Texture2D
var has_save := false
var save_notice := ""
var menu_selection := 0
var title_fade := 1.0
var world_mouse := Vector2.ZERO
var settings_return := "title"
var _font: Font
var _shade: GradientTexture2D
var _glow: GradientTexture2D

func _ready() -> void:
	Actors.ENEMIES.prepare()
	_font = ThemeDB.fallback_font
	_prepare_lighting()
	sound = Sound.new()
	add_child(sound)
	sound.set_mood("menu")
	if ResourceLoader.exists("res://assets/aurora_opening.png"):
		title_texture = load("res://assets/aurora_opening.png")
	has_save = _read_checkpoint().size() > 0
	_load_settings()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	queue_redraw()

func _process(delta: float) -> void:
	var dt := minf(delta, 0.05)
	clock += dt
	pointer = get_global_mouse_position()
	briefing_clock += dt
	dialogue_clock += dt
	toast_time = maxf(0, toast_time - dt)
	shake = maxf(0, shake - dt * 14)
	screen_flash = maxf(0, screen_flash - dt * 3)
	title_fade = maxf(0, title_fade - dt * 0.7)
	if mode == "play" and dialogue.is_empty():
		var motion := Vector2(
			float(_key(KEY_D) or _key(KEY_RIGHT)) - float(_key(KEY_A) or _key(KEY_LEFT)),
			float(_key(KEY_S) or _key(KEY_DOWN)) - float(_key(KEY_W) or _key(KEY_UP)))
		if motion.length() > 1:
			motion = motion.normalized()
		world_mouse = pointer - _size() * 0.5 + camera_pos
		if _key(KEY_SPACE):
			world_mouse = sim.pos + sim.aim * 100
		var old_state: String = sim.state
		if enemy_presentation.units.is_empty() and not sim.enemies.is_empty():
			enemy_presentation.advance(.000001, sim.enemies, sim.stage, sim.elapsed)
		sim.tick(dt, motion, world_mouse, Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or _key(KEY_SPACE), dash_requested, _key(KEY_E), lia_animation.elapsed, lia_animation.moving)
		lia_animation.advance(dt, sim.velocity, sim.dash_time > 0)
		enemy_presentation.advance(dt, sim.enemies, sim.stage, sim.elapsed)
		var heard := {}
		for cue in enemy_presentation.cues:
			if Vector2(cue.pos).distance_to(sim.pos) < 650.0 and not heard.has(cue.id):
				sound.play_sfx(cue.id)
				heard[cue.id] = true
		dash_requested = false
		_consume_events()
		if old_state != sim.state:
			_state_changed()
		var target: Vector2 = sim.pos + (world_mouse - sim.pos).limit_length(100) * 0.18
		camera_pos = camera_pos.lerp(target, 1 - exp(-dt * 7))
		_clamp_camera()
	queue_redraw()

func _size() -> Vector2:
	return get_viewport_rect().size

func _key(code: Key) -> bool:
	return Input.is_physical_key_pressed(code)

func _clamp_camera() -> void:
	var half := _size() * 0.5
	camera_pos = camera_pos.clamp(half, World.SIZE - half)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for button in buttons:
			if button.rect.has_point(event.position):
				_action(button.id)
				get_viewport().set_input_as_handled()
				return
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	var key: int = event.physical_keycode if event.physical_keycode else event.keycode
	if key == KEY_F11:
		_toggle_fullscreen()
		return
	if key == KEY_F10:
		_toggle_sound()
		return
	if key == KEY_ESCAPE:
		if not dialogue.is_empty() and mode == "play":
			previous_mode = "play"
			mode = "pause"
		elif mode == "map" or mode == "pause":
			mode = "play"
		elif mode == "settings":
			mode = settings_return
		elif mode == "play":
			mode = "pause"
		elif mode == "briefing":
			_start_new_run()
		sound.play_sfx("ui")
		return
	if key == KEY_M and mode in ["play", "map"] and dialogue.is_empty():
		mode = "play" if mode == "map" else "map"
		sound.play_sfx("ui")
	elif key == KEY_SHIFT and mode == "play":
		dash_requested = true
	elif key in [KEY_ENTER, KEY_KP_ENTER]:
		if mode == "title":
			_action("continue" if has_save else "new")
		elif mode == "briefing":
			_advance_briefing()
		elif not dialogue.is_empty() and mode == "play":
			dialogue.clear()
		elif mode == "defeat":
			_action("retry")
		elif mode == "pause":
			_action("resume")
	elif key == KEY_R and mode == "defeat":
		_action("retry")
	elif mode == "upgrade" and key in [KEY_1, KEY_2, KEY_3]:
		_action("upgrade_%d" % (key - KEY_1))

func _action(id: String) -> void:
	sound.play_sfx("ui")
	match id:
		"new":
			mode = "briefing"
			briefing_page = 0
			briefing_clock = 0
			sound.set_mood("calm")
		"continue":
			var data := _read_checkpoint()
			if not data.is_empty() and sim.load_data(data):
				enemy_presentation.reset()
				mode = "play"
				camera_pos = sim.pos
				_clamp_camera()
				last_stage = sim.stage
				sound.set_mood("combat")
				_notify("SINAL RECUPERADO  /  CHECKPOINT DA ETAPA", 3)
			else:
				has_save = false
				_notify("Não foi possível ler o checkpoint. Inicie uma operação.", 5)
		"settings":
			settings_return = mode
			mode = "settings"
		"back":
			mode = settings_return
		"fullscreen":
			_toggle_fullscreen()
		"sound":
			_toggle_sound()
		"next":
			_advance_briefing()
		"skip":
			_start_new_run()
		"dialogue":
			dialogue.clear()
		"pause":
			mode = "pause"
		"map":
			mode = "map"
		"resume":
			mode = "play"
		"retry":
			sim.retry()
			enemy_presentation.reset()
			mode = "play"
			camera_pos = sim.pos
			_clamp_camera()
			sound.set_mood("combat")
			_notify("RECONEXÃO CONCLUÍDA  /  ETAPA PRESERVADA", 3)
		"title":
			mode = "title"
			dialogue.clear()
			has_save = not _read_checkpoint().is_empty()
			sound.set_mood("menu")
		"exit":
			get_tree().quit()
		_:
			if id.begins_with("upgrade_") and mode == "upgrade":
				var index := int(id.trim_prefix("upgrade_"))
				sim.choose_upgrade(index)
				mode = "play"
				last_stage = sim.stage
				_save_checkpoint()
				dialogue = FIELD_MESSAGES[clampi(sim.stage - 1, 0, 2)].duplicate()
				dialogue_clock = 0
				sound.set_mood("combat")
				_notify("PASSAGEM LIBERADA  /  " + SECTOR_SUBTITLES[sim.stage], 4)

func _advance_briefing() -> void:
	if briefing_clock < 1.2:
		briefing_clock = 10
		return
	briefing_page += 1
	briefing_clock = 0
	if briefing_page == 2:
		sound.set_mood("combat")
	if briefing_page >= 3:
		_start_new_run()

func _start_new_run() -> void:
	sim = Simulation.new()
	sim.start()
	lia_animation.reset()
	enemy_presentation.reset()
	mode = "play"
	camera_pos = sim.pos
	_clamp_camera()
	last_stage = 0
	dialogue.clear()
	dash_requested = false
	_save_checkpoint()
	sound.set_mood("combat")
	_notify("OPERAÇÃO FILTRO  /  RECUPERE A CAPTAÇÃO", 4)

func _state_changed() -> void:
	match sim.state:
		"activation":
			sound.set_mood("calm")
			_notify("SETOR SEGURO  /  APROXIME-SE DO TERMINAL E SEGURE E", 4)
		"upgrade":
			mode = "upgrade"
			screen_flash = 0.4
			sound.set_mood("calm")
		"defeat":
			mode = "defeat"
			sound.set_mood("calm")
		"victory":
			mode = "victory"
			sound.set_mood("victory")
			_clear_checkpoint()
			screen_flash = 0.6

func _consume_events() -> void:
	for event in sim.events:
		if event != "enemy_dead":
			sound.play_sfx(event)
		if event == "hurt":
			shake = 4
			screen_flash = 0.22
		elif event == "enemy_dead":
			shake = maxf(shake, 1.6)
		elif event == "boss":
			sound.set_mood("boss")
			_notify("UNIDADE DE CONTENÇÃO  /  ORDENS SOBRESCRITAS", 3)
	sim.events.clear()

func _notify(message: String, seconds: float) -> void:
	toast = message
	toast_time = seconds

func _toggle_sound() -> void:
	muted = not muted
	sound.set_muted(muted)
	_save_settings()

func _toggle_fullscreen() -> void:
	fullscreen = not fullscreen
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
	_save_settings()

func _save_checkpoint() -> void:
	var file := FileAccess.open(SAVE_PATH + ".tmp", FileAccess.WRITE)
	if file == null:
		_notify("Checkpoint indisponível nesta sessão.", 4)
		return
	file.store_string(JSON.stringify(sim.save_data()))
	file.close()
	var result := DirAccess.rename_absolute(SAVE_PATH + ".tmp", SAVE_PATH)
	has_save = result == OK
	if not has_save:
		_notify("Não foi possível gravar o checkpoint.", 4)

func _read_checkpoint() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return {}
	var value = JSON.parse_string(file.get_as_text())
	if value is Dictionary and value.get("version", 0) == 1:
		return value
	return {}

func _clear_checkpoint() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	has_save = false

func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "muted", muted)
	config.set_value("display", "fullscreen", fullscreen)
	config.save("user://settings.cfg")

func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		muted = config.get_value("audio", "muted", false)
		fullscreen = config.get_value("display", "fullscreen", false)
		sound.set_muted(muted)
		if fullscreen:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func _draw() -> void:
	buttons.clear()
	if _font == null:
		return
	if mode in ["title", "briefing"] or (mode == "settings" and settings_return == "title"):
		_draw_opening()
	else:
		_draw_game()
	match mode:
		"title": _draw_title()
		"briefing": _draw_briefing()
		"play":
			_draw_hud()
			if not dialogue.is_empty():
				_draw_dialogue()
		"map": _draw_map()
		"pause": _draw_pause()
		"settings": _draw_settings()
		"upgrade": _draw_upgrades()
		"defeat": _draw_defeat()
		"victory": _draw_victory()
	if toast_time > 0 and mode == "play" and dialogue.is_empty():
		var alpha := minf(toast_time, 1)
		var width := minf(_size().x - 140, _font.get_string_size(toast, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 44)
		var rect := Rect2((_size().x - width) * 0.5, 101, width, 32)
		draw_rect(rect, Color(INK, alpha * 0.94))
		draw_rect(Rect2(rect.position.x, rect.position.y, 2, 32), Color(CYAN, alpha))
		_text_center(toast, rect.get_center() + Vector2(0, 4), 12, Color(WHITE, alpha))
	if screen_flash > 0:
		draw_rect(Rect2(Vector2.ZERO, _size()), Color(MAGENTA if mode == "play" else CYAN, screen_flash * 0.3))

func _draw_opening() -> void:
	var size := _size()
	draw_rect(Rect2(Vector2.ZERO, size), INK)
	if title_texture:
		var ratio := maxf(size.x / title_texture.get_width(), size.y / title_texture.get_height())
		var image_size := title_texture.get_size() * ratio
		draw_texture_rect(title_texture, Rect2((size - image_size) * 0.5, image_size), false)
	else:
		# Original live city silhouette remains available without an illustration.
		for i in 45:
			var height := 45 + posmod(i * 719, 200)
			var x := i * 29.0
			draw_rect(Rect2(x, size.y * 0.64 - height, 24, height), Color("163239"))
			for j in range(4, height, 13):
				draw_rect(Rect2(x + 7, size.y * 0.64 - j, 3, 2), Color("477c70"))
		for i in 35:
			draw_line(Vector2(0, size.y * 0.65 + i * 8), Vector2(size.x, size.y * 0.65 + i * 8), Color("163339"))
	draw_texture_rect(_shade, Rect2(Vector2.ZERO, size), false)
	draw_rect(Rect2(0, size.y - 56, size.x, 56), Color(INK, 0.83))
	for i in 35:
		var p := Vector2(fposmod(i * 181.73 + clock * (3 + i % 3), size.x), fposmod(i * 97.21 - clock * 7, size.y))
		draw_rect(Rect2(p, Vector2(2, 2)), Color(CYAN, 0.1 + 0.2 * (sin(clock + i) + 1) * 0.5))

func _draw_title() -> void:
	var size := _size()
	_text("UMA CIDADE PARA RECUPERAR.", Vector2(50, 66), 11, CYAN)
	draw_line(Vector2(50, 81), Vector2(110, 81), CYAN, 2)
	_text("PROTOCOLO", Vector2(45, 172), 60, WHITE)
	_text("17", Vector2(44, 273), 112, CYAN)
	_text("A U R O R A", Vector2(197, 229), 18, WHITE)
	_text("A rede caiu. A esperança, ainda não.", Vector2(198, 255), 12, MUTED)
	_text("AÇÃO  /  EXPLORAÇÃO  /  RECUPERAÇÃO", Vector2(50, 310), 10, MUTED)
	var y := 343.0
	if has_save:
		_button(Rect2(50, y, 300, 42), "CONTINUAR OPERAÇÃO", "continue", true)
		y += 51
		_button(Rect2(50, y, 194, 36), "NOVA OPERAÇÃO", "new", false)
		_button(Rect2(252, y, 98, 36), "OPÇÕES", "settings", false)
	else:
		_button(Rect2(50, y, 300, 46), "INICIAR OPERAÇÃO", "new", true)
		_button(Rect2(50, y + 56, 145, 36), "CONFIGURAÇÕES", "settings", false)
		_button(Rect2(204, y + 56, 146, 36), "SAIR", "exit", false)
	_text("01 / OPERAÇÃO FILTRO", Vector2(50, size.y - 25), 11, WHITE)
	_text_right("ALPHA 0.1  •  F11 TELA CHEIA", Vector2(size.x - 35, size.y - 25), 10, MUTED)
	_text_right("DISTRITO DAS ÁGUAS", Vector2(size.x - 38, size.y - 84), 11, WHITE)
	draw_circle(Vector2(size.x - 175, size.y - 88), 3, CYAN)

func _draw_briefing() -> void:
	var size := _size()
	draw_rect(Rect2(Vector2.ZERO, size), Color(INK, 0.65))
	_text("ARQUIVO AURORA", Vector2(60, 65), 12, CYAN)
	_text_right("REGISTRO %02d / 03" % (briefing_page + 1), Vector2(size.x - 60, 65), 11, MUTED)
	draw_line(Vector2(60, 82), Vector2(size.x - 60, 82), Color("36524f"))
	var headlines := ["O futuro tinha um endereço.", "Então, a rede silenciou.", "As ordens foram alteradas."]
	var descriptions := [
		"Aurora nasceu de uma promessa: tecnologia e natureza poderiam crescer juntas. O Protocolo 17 cuidava da água, da energia e da vida que ligava a cidade.",
		"Os canais escureceram. As bombas pararam. Os drones de manutenção passaram a atacar as pessoas que deveriam proteger.",
		"Lia recebe um último sinal do Distrito das Águas. Quatro sistemas precisam voltar a funcionar antes que a contaminação alcance toda Aurora."
	]
	_text(headlines[briefing_page], Vector2(60, 157), 34, WHITE if briefing_page != 2 else GOLD)
	_wrapped(descriptions[briefing_page], Rect2(62, 183, 650, 98), 17, MUTED, 26)
	var trans: Array = TRANSMISSIONS[briefing_page]
	draw_rect(Rect2(60, 302, size.x - 120, 104), Color(INK, 0.94))
	draw_rect(Rect2(60, 302, 3, 104), CYAN)
	_radio_portrait(Vector2(81, 321), trans[0] == "LIA")
	_text("CANAL 17  /  " + trans[0], Vector2(153, 329), 10, CYAN)
	var message: String = trans[1]
	var visible := message.substr(0, mini(message.length(), int(briefing_clock * 60)))
	_wrapped(visible, Rect2(153, 342, size.x - 240, 60), 14, WHITE, 21)
	_button(Rect2(size.x - 269, size.y - 86, 209, 39), "DESEMBARCAR  →" if briefing_page == 2 else "PRÓXIMO REGISTRO  →", "next", true)
	_button(Rect2(60, size.y - 86, 171, 39), "PULAR INTRODUÇÃO", "skip", false)
	_text("ENTER AVANÇA  /  ESC PULA", Vector2(60, size.y - 22), 10, MUTED)

func _draw_game() -> void:
	var jitter := Vector2(sin(clock * 103), cos(clock * 79)) * shake
	draw_set_transform((_size() * 0.5 - camera_pos + jitter).round())
	World.draw(self, camera_pos, sim.stage, sim.restored, clock)
	_draw_terminals()
	var entities: Array[Dictionary] = []
	for enemy in sim.enemies:
		if enemy.hp > 0:
			entities.append({"y": enemy.pos.y, "enemy": enemy})
	entities.append({"y": sim.pos.y, "player": true})
	for wreck in enemy_presentation.wrecks:
		entities.append({"y": wreck.pos.y, "wreck": wreck})
	entities.sort_custom(func(a, b): return a.y < b.y)
	for entity in entities:
		if entity.has("player"):
			var lia_action := "repair" if sim.repair > 0 else ("fire" if sim.state == "combat" and sim._fire_cd > 0 else "idle")
			var shot_age := sim.fire_interval - sim._fire_cd if sim._fire_cd > 0 else -1.0
			Actors.draw_lia(self, sim.pos, sim.aim, lia_animation.elapsed, lia_animation.moving, sim.invuln > 0 and int(clock * 16) % 2 == 0, sim.dash_time > 0, lia_action, shot_age)
		elif entity.has("wreck"):
			Actors.ENEMIES.draw_destroyed(self, entity.wreck)
		else:
			var enemy: Dictionary = entity.enemy
			if enemy.get("warning", 0.0) > 0:
				var direction: Vector2 = enemy.get("aim", Vector2.DOWN)
				draw_line(enemy.pos, enemy.pos + direction * (155 if enemy.kind != "boss" else 220), Color(GOLD, 0.35), 2)
				draw_arc(enemy.pos, float(enemy.get("radius", 14)) + 8, 0, TAU, 20, GOLD, 1)
			Actors.draw_drone(self, enemy_presentation.view_for(enemy), sim.elapsed)
	for bolt in sim.bullets:
		if not bolt.hostile:
			Actors.WEAPON.draw_pulse(self, bolt, clock)
			continue
		var color: Color = MAGENTA if bolt.hostile else CYAN
		var tail: Vector2 = bolt.pos - bolt.vel.normalized() * (11 if bolt.hostile else 17)
		draw_line(tail, bolt.pos, Color(color, 0.22), 7)
		draw_line(tail.lerp(bolt.pos, 0.3), bolt.pos, color, 3)
		draw_rect(Rect2(bolt.pos - Vector2(1, 1), Vector2(3, 3)), WHITE)
	for particle in sim.particles:
		var alpha := clampf(float(particle.life) / maxf(float(particle.get("max_life", 1.0)), 0.01), 0, 1)
		var col: Color = particle.get("color", CYAN)
		var psize: float = particle.get("size", 2.0)
		draw_rect(Rect2(particle.pos, Vector2.ONE * psize), Color(col, alpha))
	for i in 30:
		var p := camera_pos - _size() * 0.5 + Vector2(fposmod(i * 173.4 + clock * 5, _size().x), fposmod(i * 111.7 - clock * 11, _size().y))
		draw_rect(Rect2(p, Vector2(1, 2)), Color("b3d7ac", 0.22))
	for i in 4:
		var light: Vector2 = World.GOALS[i]
		var light_color: Color = CYAN if i < sim.restored or (i == sim.stage and sim.state == "activation") else MAGENTA
		draw_texture_rect(_glow, Rect2(light - Vector2(94, 88), Vector2(188, 152)), false, Color(light_color, 0.11))
	draw_texture_rect(_glow, Rect2(sim.pos - Vector2(65, 55), Vector2(130, 110)), false, Color(CYAN, 0.08))
	draw_set_transform(Vector2.ZERO)
	_draw_vignette()
	if mode == "play" and dialogue.is_empty():
		_draw_crosshair(pointer)

func _draw_route() -> void:
	if mode == "map":
		return
	var route: Array = World.ROUTES[sim.stage]
	for i in range(route.size() - 1):
		var a: Vector2 = route[i]
		var b: Vector2 = route[i + 1]
		var count := int(a.distance_to(b) / 115)
		for j in range(1, count):
			var p := a.lerp(b, float(j) / count)
			if p.distance_to(sim.pos) > 370:
				continue
			var direction := (b - a).normalized()
			var side := direction.orthogonal()
			var color := Color(CYAN, 0.15 + 0.08 * sin(clock * 2 - j))
			draw_polyline(PackedVector2Array([p - direction * 5 + side * 4, p, p - direction * 5 - side * 4]), color, 1)

func _draw_terminals() -> void:
	for i in 4:
		var p: Vector2 = World.GOALS[i]
		var active := i < sim.restored
		var available := i == sim.stage and sim.state == "activation"
		var color: Color = CYAN if active or available else MAGENTA
		StationArt.draw_totem(self,p,i,active,clock)
		if available:
			draw_arc(p+Vector2(0,10), 43 + sin(clock * 3) * 2, 0, TAU, 28, Color(CYAN, 0.45), 1)
		if i == sim.stage:
			_text_center("%02d" % (i + 1), p + Vector2(0, -101), 12, color)
		if i == sim.stage and sim.pos.distance_to(p) < 80 and sim.state == "activation":
			draw_arc(p+Vector2(0,10), 38, -PI / 2, -PI / 2 + TAU * maxf(sim.repair, 0.01), 32, CYAN, 3)

func _draw_hud() -> void:
	var size := _size()
	_panel(Rect2(22, 19, 248, 66))
	_text("LIA", Vector2(37, 39), 11, CYAN)
	_text("AGENTE DE RECUPERAÇÃO", Vector2(73, 39), 9, MUTED)
	for i in sim.max_hp:
		var step := minf(23, 216.0 / sim.max_hp)
		draw_rect(Rect2(37 + i * step, 49, step - 4, 10), CYAN if i < sim.hp else Color("29424a"))
	_text("INTEGRIDADE", Vector2(37, 74), 8, MUTED)
	_text_right("%d / %d" % [sim.hp, sim.max_hp], Vector2(252, 74), 9, WHITE)
	_panel(Rect2(size.x - 280, 19, 258, 66))
	_text("OPERAÇÃO FILTRO", Vector2(size.x - 265, 38), 9, MUTED)
	_text(SECTOR_SUBTITLES[sim.stage], Vector2(size.x - 265, 56), 12, WHITE)
	for i in 4:
		draw_rect(Rect2(size.x - 265 + i * 59, 69, 52, 3), CYAN if i < sim.restored else (GOLD if i == sim.stage else Color("29424a")))
	_button(Rect2(size.x * 0.5 - 51, 20, 46, 26), "M", "map", false)
	_button(Rect2(size.x * 0.5 + 5, 20, 46, 26), "ESC", "pause", false)
	var alive := 0
	for e in sim.enemies:
		if e.hp > 0: alive += 1
	var objective := "%02d DRONES  /  NEUTRALIZE AS AMEAÇAS" % alive
	if sim.state == "activation":
		objective = "ÁREA SEGURA  /  RESTAURE O SISTEMA"
	_text_center(objective, Vector2(size.x * 0.5, 73), 10, CYAN if sim.state == "activation" else GOLD)
	_draw_minimap(Rect2(size.x - 182, size.y - 147, 160, 110))
	_text_right("M  MAPA DO DISTRITO", Vector2(size.x - 22, size.y - 23), 9, MUTED)
	_panel(Rect2(22, size.y - 73, 260, 50))
	_text("PULSO", Vector2(37, size.y - 51), 10, CYAN)
	_text("MOUSE / ESPAÇO", Vector2(89, size.y - 51), 9, MUTED)
	_text("ESQUIVA", Vector2(37, size.y - 33), 10, WHITE)
	var ready := sim.dash_cd <= 0
	_text("SHIFT", Vector2(104, size.y - 33), 9, CYAN if ready else MUTED)
	draw_rect(Rect2(152, size.y - 40, 111, 4), Color("29424a"))
	draw_rect(Rect2(152, size.y - 40, 111 * (1 - clampf(sim.dash_cd / sim.dash_recharge, 0, 1)), 4), CYAN)
	if sim.pos.distance_to(World.GOALS[sim.stage]) < 84:
		var message := "SEGURE E  /  RESTAURAR SISTEMA" if sim.state == "activation" else "TERMINAL BLOQUEADO  /  ELIMINE OS DRONES"
		var rect := Rect2(size.x * 0.5 - 190, size.y - 87, 380, 45)
		_panel(rect)
		_text_center(message, rect.get_center() + Vector2(0, 1), 10, CYAN if sim.state == "activation" else GOLD)
		if sim.state == "activation":
			draw_rect(Rect2(rect.position + Vector2(12, 35), Vector2((rect.size.x - 24) * sim.repair, 3)), CYAN)
	else:
		var goal: Vector2 = World.GOALS[sim.stage]
		var difference: Vector2 = goal - sim.pos
		if difference.length() > 250:
			var anchor := size * 0.5 + difference.normalized() * minf(size.y * 0.32, 170)
			draw_circle(anchor, 12, Color(INK, 0.82))
			var dir := difference.normalized()
			var side := dir.orthogonal()
			draw_colored_polygon(PackedVector2Array([anchor + dir * 6, anchor - dir * 4 + side * 4, anchor - dir * 4 - side * 4]), CYAN)
	for enemy in sim.enemies:
		if enemy.kind == "boss" and enemy.hp > 0 and enemy.pos.distance_to(sim.pos) < 480:
			var rect := Rect2(size.x * 0.5 - 170, size.y - 41, 340, 5)
			_text_center("GUARDIÃO DA REDE  /  CONTROLE EXTERNO", Vector2(size.x * 0.5, size.y - 50), 9, MAGENTA)
			draw_rect(rect, Color("352835"))
			draw_rect(Rect2(rect.position, Vector2(rect.size.x * enemy.hp / enemy.max_hp, 5)), MAGENTA)

func _draw_crosshair(p: Vector2) -> void:
	var c := CYAN
	for d in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		draw_line(p + d * 5, p + d * 9, Color(INK, 0.9), 3)
		draw_line(p + d * 5, p + d * 9, c, 1)
	draw_rect(Rect2(p - Vector2.ONE, Vector2(2, 2)), WHITE)

func _draw_minimap(rect: Rect2) -> void:
	_panel(rect)
	var inner := Rect2(rect.position + Vector2(7, 7), rect.size - Vector2(14, 14))
	var scale_value := minf(inner.size.x / World.SIZE.x, inner.size.y / World.SIZE.y)
	var origin := inner.get_center() - World.SIZE * scale_value * 0.5
	for i in 4:
		var region: Rect2 = World.REGIONS[i]
		draw_rect(Rect2(origin + region.position * scale_value, region.size * scale_value), Color("31544d") if i <= sim.stage else Color("182e38"))
		var p: Vector2 = origin + World.GOALS[i] * scale_value
		draw_rect(Rect2(p - Vector2(2, 2), Vector2(4, 4)), CYAN if i < sim.restored else GOLD)
	for i in 3:
		var gate: Rect2 = World.GATES[i]
		var p: Vector2 = origin + gate.get_center() * scale_value
		draw_circle(p, 2, CYAN if i < sim.stage else MAGENTA)
	var route: Array = World.ROUTES[sim.stage]
	for i in range(route.size() - 1):
		draw_line(origin + route[i] * scale_value, origin + route[i + 1] * scale_value, Color(CYAN, 0.38), 1)
	for enemy in sim.enemies:
		if enemy.hp > 0:
			draw_circle(origin + enemy.pos * scale_value, 1.5, MAGENTA)
	draw_circle(origin + sim.pos * scale_value, 3, WHITE)

func _draw_map() -> void:
	var size := _size()
	draw_rect(Rect2(Vector2.ZERO, size), Color(INK, 0.97))
	_text("DISTRITO DAS ÁGUAS", Vector2(45, 53), 24, WHITE)
	_text("REDE DE RECUPERAÇÃO  /  AURORA", Vector2(46, 77), 10, CYAN)
	_button(Rect2(size.x - 210, 32, 165, 37), "VOLTAR AO CAMPO  M", "resume", false)
	var map_rect := Rect2(46, 104, size.x - 332, size.y - 141)
	var ratio := minf(map_rect.size.x / World.SIZE.x, map_rect.size.y / World.SIZE.y)
	var origin := map_rect.get_center() - World.SIZE * ratio * 0.5
	for i in 3:
		var gate: Rect2 = World.GATES[i]
		var r := Rect2(origin + gate.position * ratio, gate.size * ratio)
		draw_rect(r.grow(4), Color("233d43"))
		draw_rect(r, CYAN if i < sim.stage else MAGENTA)
	for i in 4:
		var region: Rect2 = World.REGIONS[i]
		var r := Rect2(origin + region.position * ratio, region.size * ratio)
		draw_rect(r, Color("20483e") if i < sim.restored else (Color("263c45") if i == sim.stage else Color("142831")))
		draw_rect(r, CYAN if i <= sim.stage else Color("34505a"), false, 1)
		_text("0%d" % (i + 1), r.position + Vector2(13, 30), 22, CYAN if i <= sim.stage else MUTED)
		var label: String = ["CAPTAÇÃO", "ENERGIA", "FILTRAGEM", "DISTRIBUIÇÃO"][i]
		_text(label, r.position + Vector2(13, 51), 11, WHITE)
		_text("RESTAURADO" if i < sim.restored else ("SINAL ATIVO" if i == sim.stage else "SEM ACESSO"), r.position + Vector2(13, 68), 8, CYAN if i <= sim.stage else MUTED)
		draw_circle(origin + World.GOALS[i] * ratio, 4, GOLD)
	var route: Array = World.ROUTES[sim.stage]
	for i in range(route.size() - 1):
		draw_dashed_line(origin + route[i] * ratio, origin + route[i + 1] * ratio, Color(CYAN, 0.6), 1, 5)
	for enemy in sim.enemies:
		if enemy.hp > 0:
			draw_circle(origin + enemy.pos * ratio, 3, MAGENTA)
	var player_p: Vector2 = origin + sim.pos * ratio
	draw_circle(player_p, 7, Color(WHITE, 0.15))
	draw_circle(player_p, 3, WHITE)
	var x := size.x - 248
	_text("SISTEMAS ONLINE", Vector2(x, 138), 11, MUTED)
	_text("%d / 4" % sim.restored, Vector2(x, 185), 35, CYAN)
	_wrapped("Restaure o terminal de cada setor para abrir a próxima passagem.", Rect2(x, 211, 195, 70), 12, WHITE, 19)
	_text("●  LIA", Vector2(x, 316), 11, WHITE)
	_text("●  DRONE CORROMPIDO", Vector2(x, 342), 10, MAGENTA)
	_text("●  TERMINAL", Vector2(x, 368), 11, GOLD)
	_text("—  ROTA SUGERIDA", Vector2(x, 394), 10, CYAN)
	_text("SIMULAÇÃO PAUSADA", Vector2(x, size.y - 45), 9, MUTED)

func _draw_dialogue() -> void:
	var size := _size()
	var rect := Rect2(130, size.y - 166, size.x - 260, 122)
	_panel(rect)
	draw_rect(Rect2(rect.position, Vector2(3, rect.size.y)), CYAN)
	_radio_portrait(rect.position + Vector2(18, 20), dialogue[0] == "LIA")
	_text("TRANSMISSÃO  /  " + dialogue[0], rect.position + Vector2(90, 27), 10, CYAN)
	_wrapped(dialogue[1], Rect2(rect.position + Vector2(90, 39), Vector2(rect.size.x - 115, 63)), 13, WHITE, 20)
	_button(Rect2(rect.end.x - 157, rect.end.y - 28, 140, 22), "ENTENDIDO  ENTER", "dialogue", false)

func _draw_pause() -> void:
	_overlay("SINAL EM ESPERA", "A operação está pausada.")
	var x := _size().x * 0.5 - 145
	_button(Rect2(x, 253, 290, 42), "RETOMAR OPERAÇÃO", "resume", true)
	_button(Rect2(x, 306, 290, 36), "CONFIGURAÇÕES", "settings", false)
	_button(Rect2(x, 354, 290, 36), "VOLTAR AO INÍCIO", "title", false)
	_text_center("O checkpoint guarda o início da etapa atual.", Vector2(_size().x * 0.5, 431), 11, MUTED)

func _draw_settings() -> void:
	_overlay("CONFIGURAÇÕES", "Ajuste seu equipamento de campo.")
	var x := _size().x * 0.5 - 190
	_button(Rect2(x, 245, 380, 38), "ÁUDIO   " + ("DESLIGADO" if muted else "LIGADO") + "   /   F10", "sound", false)
	_button(Rect2(x, 293, 380, 38), "TELA   " + ("CHEIA" if fullscreen else "JANELA") + "   /   F11", "fullscreen", false)
	_text_center("WASD / SETAS   MOVER      MOUSE   MIRAR E DISPARAR", Vector2(_size().x * 0.5, 362), 11, WHITE)
	_text_center("SHIFT   ESQUIVA      E   RESTAURAR      M   MAPA      ESC   PAUSA", Vector2(_size().x * 0.5, 386), 10, MUTED)
	_button(Rect2(x + 90, 423, 200, 39), "VOLTAR", "back", true)

func _draw_upgrades() -> void:
	var size := _size()
	draw_rect(Rect2(Vector2.ZERO, size), Color(INK, 0.96))
	_text_center("SISTEMA %02d RESTAURADO" % sim.restored, Vector2(size.x * 0.5, 59), 11, CYAN)
	_text_center("Recuperar também transforma você.", Vector2(size.x * 0.5, 109), 29, WHITE)
	_text_center("ESCOLHA UMA MELHORIA PARA ESTA OPERAÇÃO", Vector2(size.x * 0.5, 139), 10, MUTED)
	var options: Array = sim.upgrade_options()
	var width := (size.x - 128) / 3
	for i in options.size():
		var option: Dictionary = options[i]
		var rect := Rect2(48 + i * (width + 16), 184, width, 256)
		var hover := rect.has_point(pointer)
		draw_rect(rect, Color("193a3c") if hover else PANEL)
		draw_rect(rect, CYAN if hover else Color("3a5355"), false, 1)
		draw_rect(Rect2(rect.position, Vector2(rect.size.x, 3)), CYAN if i == 0 else (GOLD if i == 1 else MAGENTA))
		_upgrade_icon(rect.position + Vector2(31, 40), [0, 2, 1][i])
		_text("MÓDULO 0%d" % (i + 1), rect.position + Vector2(28, 103), 9, MUTED)
		_wrapped(option.title.to_upper(), Rect2(rect.position + Vector2(27, 117), Vector2(width - 48, 50)), 19, WHITE, 24)
		_wrapped(option.description, Rect2(rect.position + Vector2(28, 172), Vector2(width - 50, 61)), 12, MUTED, 18)
		buttons.append({"rect": rect, "id": "upgrade_%d" % i})
		_text("[%d]  INSTALAR MÓDULO  →" % (i + 1), rect.position + Vector2(28, 238), 10, CYAN)
	_text_center("+2 INTEGRIDADE RECUPERADA  /  PRÓXIMA PASSAGEM LIBERADA APÓS A ESCOLHA", Vector2(size.x * 0.5, size.y - 40), 10, CYAN)

func _draw_defeat() -> void:
	_overlay("CONEXÃO INTERROMPIDA", "Lia caiu. A missão ainda pode continuar.", MAGENTA)
	_text_center("ETAPA %d / 4  •  %s" % [sim.stage + 1, SECTOR_SUBTITLES[sim.stage]], Vector2(_size().x * 0.5, 263), 12, WHITE)
	_text_center("Os sistemas restaurados e suas melhorias foram preservados.", Vector2(_size().x * 0.5, 296), 12, MUTED)
	_button(Rect2(_size().x * 0.5 - 160, 338, 320, 44), "TENTAR NOVAMENTE  /  ENTER", "retry", true)
	_button(Rect2(_size().x * 0.5 - 160, 395, 320, 35), "VOLTAR AO INÍCIO", "title", false)

func _draw_victory() -> void:
	var size := _size()
	draw_rect(Rect2(Vector2.ZERO, size), Color(INK, 0.96))
	_text_center("OPERAÇÃO FILTRO  /  CONCLUÍDA", Vector2(size.x * 0.5, 55), 11, CYAN)
	_text_center("Aurora volta a respirar.", Vector2(size.x * 0.5, 109), 39, WHITE)
	_text_center("Captação. Energia. Filtragem. Distribuição. A água encontrou o caminho de casa.", Vector2(size.x * 0.5, 145), 13, MUTED)
	var stats := ["4 / 4\nSISTEMAS ONLINE", "%02d:%02d\nTEMPO DE OPERAÇÃO" % [int(sim.elapsed) / 60, int(sim.elapsed) % 60], "%02d\nDRONES NEUTRALIZADOS" % sim.kills]
	for i in 3:
		var p := Vector2(size.x * 0.5 - 260 + i * 260, 203)
		_text_center(stats[i].split("\n")[0], p, 30, CYAN)
		_text_center(stats[i].split("\n")[1], p + Vector2(0, 25), 9, MUTED)
	var rect := Rect2(120, 276, size.x - 240, 134)
	_panel(rect)
	draw_rect(Rect2(rect.position, Vector2(3, rect.size.y)), GOLD)
	_text("REGISTRO RECUPERADO  /  ACESSO EXTERNO", rect.position + Vector2(24, 28), 10, GOLD)
	_wrapped("LIA: Comando… a alteração nas ordens aconteceu antes do colapso. Isso não foi uma falha.", Rect2(rect.position + Vector2(24, 42), Vector2(rect.size.x - 48, 47)), 15, WHITE, 23)
	_text("ORIGEM DO COMANDO: REDIGIDA  /  DESTINO: OUTRO DISTRITO", rect.position + Vector2(24, 110), 10, MAGENTA)
	_button(Rect2(size.x * 0.5 - 150, 444, 300, 42), "VOLTAR A AURORA", "title", true)
	_text_center("FIM DA ALPHA  /  O MISTÉRIO CONTINUA", Vector2(size.x * 0.5, size.y - 19), 9, MUTED)

func _overlay(title: String, subtitle: String, accent: Color = CYAN) -> void:
	draw_rect(Rect2(Vector2.ZERO, _size()), Color(INK, 0.94))
	draw_line(Vector2(_size().x * 0.5 - 25, 117), Vector2(_size().x * 0.5 + 25, 117), accent, 2)
	_text_center(title, Vector2(_size().x * 0.5, 173), 32, WHITE)
	_text_center(subtitle, Vector2(_size().x * 0.5, 207), 14, MUTED)

func _radio_portrait(p: Vector2, lia: bool) -> void:
	draw_rect(Rect2(p, Vector2(51, 60)), Color("203b42"))
	if lia:
		Actors.draw_lia_portrait(self, p + Vector2(26, 34), Vector2.DOWN, clock, false, false, false)
	else:
		for i in 10:
			var h := 6 + absf(sin(clock * 4 + i * 0.7)) * 26
			draw_rect(Rect2(p + Vector2(6 + i * 4, 30 - h * 0.5), Vector2(2, h)), CYAN)
	_text_center("17", p + Vector2(26, 55), 8, MUTED)

func _upgrade_icon(p: Vector2, index: int) -> void:
	var col: Color = [CYAN, GOLD, MAGENTA][index]
	draw_rect(Rect2(p, Vector2(45, 40)), Color(col, 0.08))
	if index == 0:
		draw_line(p + Vector2(10, 30), p + Vector2(31, 9), col, 4)
		draw_line(p + Vector2(22, 9), p + Vector2(33, 9), col, 3)
		draw_line(p + Vector2(32, 9), p + Vector2(32, 20), col, 3)
	elif index == 1:
		draw_polyline(PackedVector2Array([p + Vector2(12, 9), p + Vector2(25, 20), p + Vector2(12, 31)]), col, 3)
		draw_polyline(PackedVector2Array([p + Vector2(24, 9), p + Vector2(37, 20), p + Vector2(24, 31)]), col, 3)
	else:
		draw_rect(Rect2(p + Vector2(19, 8), Vector2(7, 25)), col)
		draw_rect(Rect2(p + Vector2(10, 17), Vector2(25, 7)), col)

func _panel(rect: Rect2) -> void:
	draw_rect(rect, Color(INK, 0.92))
	draw_rect(rect, Color("385153", 0.65), false, 1)

func _prepare_lighting() -> void:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0, 0.35, 0.72, 1])
	gradient.colors = PackedColorArray([Color(INK, 0.94), Color(INK, 0.68), Color(INK, 0.13), Color(INK, 0.02)])
	_shade = GradientTexture2D.new()
	_shade.gradient = gradient
	_shade.width = 960
	_shade.height = 8
	_shade.fill_from = Vector2.ZERO
	_shade.fill_to = Vector2.RIGHT
	var glow_gradient := Gradient.new()
	glow_gradient.offsets = PackedFloat32Array([0, 0.4, 1])
	glow_gradient.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0.38), Color(1, 1, 1, 0)])
	_glow = GradientTexture2D.new()
	_glow.gradient = glow_gradient
	_glow.width = 128
	_glow.height = 128
	_glow.fill = GradientTexture2D.FILL_RADIAL
	_glow.fill_from = Vector2(0.5, 0.5)
	_glow.fill_to = Vector2(1, 0.5)

func _draw_vignette() -> void:
	var size := _size()
	for i in 12:
		var alpha := 0.024 * (1.0 - float(i) / 12)
		var inset := i * 7.0
		draw_rect(Rect2(inset, inset, size.x - 2 * inset, size.y - 2 * inset), Color(INK, alpha), false, 14)

func _button(rect: Rect2, label: String, id: String, primary: bool) -> void:
	var hover := rect.has_point(pointer)
	var color: Color = CYAN if primary else Color("15313a")
	if hover:
		color = Color("b4f3d5") if primary else Color("2b4e52")
	draw_rect(rect, color)
	if not primary:
		draw_rect(rect, Color("416264"), false, 1)
	_text_center(label, rect.get_center() + Vector2(0, 4), 11 if rect.size.y > 30 else 9, INK if primary else WHITE)
	buttons.append({"rect": rect, "id": id})

func _text(text: String, p: Vector2, size: int, color: Color) -> void:
	draw_string(_font, p.round(), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _text_center(text: String, p: Vector2, size: int, color: Color) -> void:
	var width := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	_text(text, p - Vector2(width * 0.5, 0), size, color)

func _text_right(text: String, p: Vector2, size: int, color: Color) -> void:
	var width := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	_text(text, p - Vector2(width, 0), size, color)

func _wrapped(text: String, rect: Rect2, size: int, color: Color, line_height: int) -> void:
	var line := ""
	var y := rect.position.y + size
	for word in text.split(" "):
		var candidate := word if line.is_empty() else line + " " + word
		if _font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > rect.size.x and not line.is_empty():
			_text(line, Vector2(rect.position.x, y), size, color)
			line = word
			y += line_height
		else:
			line = candidate
	_text(line, Vector2(rect.position.x, y), size, color)
