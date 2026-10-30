extends Node2D
## Original alpha shell: presentation, input, camera, interface and checkpoint I/O.
const FieldHUD = preload("res://scripts/field_hud.gd")
const World = preload("res://scripts/world.gd")
const StationArt = preload("res://scripts/station_art.gd")
const Simulation = preload("res://scripts/simulation.gd")
const Actors = preload("res://scripts/actors_art.gd")
const LiaAnimation = preload("res://scripts/lia_animation.gd")
const EnemyPresentation = preload("res://scripts/enemy_presentation.gd")
const Sound = preload("res://scripts/audio.gd")
const ENERGY_STATION_SCENE = preload("res://scenes/structures/energy_station.tscn")
const WaterSurface = preload("res://scripts/water_surface.gd")
const Objectives = preload("res://scripts/objective_visual.gd")
const Prologue = preload("res://scripts/prologue.gd")
const PrologueView = preload("res://scripts/prologue_presentation.gd")
const LaboratoryEffects = preload("res://scripts/laboratory_effects.gd")
const DistrictLighting = preload("res://scripts/district_lighting.gd")
const SAVE_PATH := "user://aurora_beta_checkpoint.json"
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
var menu_focus := ""
var menu_focus_mode := ""
var _brand_font: SystemFont
var previous_mode := "play"
var clock := 0.0
var camera_pos := World.START
var buttons: Array[Dictionary] = []
var pointer := Vector2.ZERO
var dash_requested := false
var selected_difficulty := "operation"
var secondary_requested := false
var interact_requested := false
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
var energy_station: Node2D
var water_surface: P17WaterSurface
var prologue: P17Prologue
var laboratory_effects: P17LaboratoryEffects
var district_effects: P17DistrictLighting
var prologue_camera := Vector2(480,730)
var prologue_replay := false
var prologue_interact_requested := false
var instant_prologue_text := false
var ui_mouse_held := false

func _ready() -> void:
	laboratory_effects = LaboratoryEffects.new()
	laboratory_effects.configure(Prologue.Lab.ROOM,Prologue.Lab.shadow_casters(),Prologue.Lab.CORE)
	add_child(laboratory_effects)
	water_surface=WaterSurface.new()
	water_surface.configure(World.SIZE,World.REGIONS,World.BRIDGES,World.PIER,World.BASINS,World.Wetlands.CHANNELS)
	water_surface.visible=false
	add_child(water_surface)
	district_effects=DistrictLighting.new()
	district_effects.configure()
	add_child(district_effects)
	Actors.ENEMIES.prepare()
	energy_station = ENERGY_STATION_SCENE.instantiate()
	energy_station.position = World.ENERGY_STATION_ORIGIN
	# The alpha draws the game in one batched CanvasItem. The authored scene
	# remains active for collision/navigation/state while its script supplies
	# layered draw calls that can interleave with Lia and enemies.
	energy_station.visible = false
	add_child(energy_station)
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
	_update_energy_station(dt)
	pointer = get_global_mouse_position()
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT): ui_mouse_held = false
	briefing_clock += dt
	dialogue_clock += dt
	toast_time = maxf(0, toast_time - dt)
	shake = maxf(0, shake - dt * 14)
	screen_flash = maxf(0, screen_flash - dt * 3)
	title_fade = maxf(0, title_fade - dt * 0.7)
	if mode == "prologue":
		var motion := Vector2(float(_key(KEY_D) or _key(KEY_RIGHT))-float(_key(KEY_A) or _key(KEY_LEFT)),float(_key(KEY_S) or _key(KEY_DOWN))-float(_key(KEY_W) or _key(KEY_UP)))
		var offset := (_size()/2-prologue_camera).round()
		var cursor := pointer-offset
		if _key(KEY_SPACE): cursor = prologue.pos+prologue.aim*100
		prologue.tick(dt,motion,cursor,(Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not ui_mouse_held) or _key(KEY_SPACE),false,prologue_interact_requested,_key(KEY_ENTER) or _key(KEY_KP_ENTER))
		prologue_interact_requested = false
		dash_requested = false
		prologue_camera = Prologue.Lab.camera(prologue_camera.lerp(prologue.pos,1-exp(-dt*6)),_size())
		for cue in prologue.events: sound.play_sfx(cue)
		sound.set_mood("suspense" if prologue.step>=3 else "calm")
		if prologue.finished: _finish_prologue()
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
		sim.tick(dt, motion, world_mouse, (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not ui_mouse_held) or _key(KEY_SPACE), dash_requested, _key(KEY_E) or interact_requested, lia_animation.elapsed, lia_animation.moving, secondary_requested)
		secondary_requested = false
		interact_requested = false
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
	if sound and energy_station and sound.has_method("set_structure_hum"):
		var hum_proximity := clampf(1.0 - sim.pos.distance_to(World.ENERGY_STATION_ORIGIN) / 520.0, 0.0, 1.0)
		sound.set_structure_hum(mode == "play" and energy_station.is_online(), hum_proximity)
	queue_redraw()

func _update_energy_station(delta: float) -> void:
	if energy_station == null:
		return
	var should_be_online := sim.restored > 1
	if should_be_online and energy_station.structure_state == energy_station.StructureState.OFFLINE:
		energy_station.set_online(true, true)
	elif not should_be_online and energy_station.structure_state != energy_station.StructureState.OFFLINE:
		energy_station.set_online(false, false)
	energy_station.advance_state(delta)

func _size() -> Vector2:
	return get_viewport_rect().size

func _key(code: Key) -> bool:
	return Input.is_physical_key_pressed(code)

func _clamp_camera() -> void:
	var half := _size() * 0.5
	camera_pos = camera_pos.clamp(half, World.SIZE - half)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion: menu_focus = ""
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT and mode == "play" and dialogue.is_empty() and sim.state == "combat":
		secondary_requested = true
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for button in buttons:
			if button.rect.has_point(event.position):
				ui_mouse_held = true
				get_viewport().set_input_as_handled()
				_action(button.id)
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
	if mode in ["title","pause","settings","difficulty"] and not buttons.is_empty():
		if key in [KEY_UP,KEY_DOWN,KEY_LEFT,KEY_RIGHT,KEY_TAB]:
			var index := -1
			for n in buttons.size():
				if buttons[n].id==menu_focus: index=n
			var backward: bool = key in [KEY_UP,KEY_LEFT] or (key==KEY_TAB and event.shift_pressed)
			index = posmod((0 if index<0 and backward else index)+(-1 if backward else 1),buttons.size())
			menu_focus = buttons[index].id
			sound.play_sfx("ui")
			queue_redraw()
			return
		if key in [KEY_ENTER,KEY_KP_ENTER,KEY_SPACE] and not menu_focus.is_empty():
			var target := menu_focus
			_action(target)
			return
	if mode == "prologue":
		match key:
			KEY_P: _finish_prologue()
			KEY_TAB: _action("intro_fast")
			KEY_ENTER, KEY_KP_ENTER: prologue.advance()
			KEY_E:
				if prologue.phase == "lab" and (prologue.conversation.is_empty() or not prologue.dialogue_blocks): prologue_interact_requested = true
			KEY_R:
				if prologue.phase == "retry": _action("intro_retry")
			KEY_ESCAPE:
				prologue_interact_requested = false
				previous_mode = "prologue"
				mode = "pause"
		get_viewport().set_input_as_handled()
		return
	if key == KEY_ESCAPE:
		_clear_pending_actions()
		if mode == "difficulty":
			mode = "title"
		elif not dialogue.is_empty() and mode == "play":
			previous_mode = "play"
			mode = "pause"
		elif mode == "map" or mode == "pause":
			mode = previous_mode if mode == "pause" else "play"
		elif mode == "settings":
			mode = settings_return
		elif mode == "play":
			previous_mode = "play"
			mode = "pause"
		elif mode == "briefing":
			_start_new_run()
		sound.play_sfx("ui")
		return
	if key == KEY_M and mode in ["play", "map"] and dialogue.is_empty():
		_clear_pending_actions()
		mode = "play" if mode == "map" else "map"
		sound.play_sfx("ui")
	elif key == KEY_E and mode == "play" and dialogue.is_empty():
		interact_requested = true
	elif key == KEY_Q and mode == "play" and dialogue.is_empty() and sim.state == "combat":
		secondary_requested = true
	elif mode == "play" and dialogue.is_empty() and key in [KEY_1,KEY_2,KEY_3] and sim.operation.wants_treatment(sim.pos):
		sim.select_treatment(key-KEY_1)
		_consume_events()
	elif key == KEY_SHIFT and mode == "play" and dialogue.is_empty():
		dash_requested = true
	elif key in [KEY_ENTER, KEY_KP_ENTER]:
		if mode == "difficulty":
			_action("difficulty_"+selected_difficulty)
		elif mode == "title":
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
	elif mode == "difficulty" and key in [KEY_1,KEY_2,KEY_3]:
		_action("difficulty_"+Simulation.DIFFICULTIES[key-KEY_1])

func _action(id: String) -> void:
	menu_focus = ""
	_clear_pending_actions()
	sound.play_sfx("ui")
	match id:
		"new":
			mode = "difficulty"
		"difficulty_back": mode = "title"
		"treatment_0", "treatment_1", "treatment_2":
			sim.select_treatment(int(id.trim_prefix("treatment_")))
			_consume_events()
		"intro_replay": _start_prologue(true)
		"intro_next": prologue.advance()
		"intro_skip": _finish_prologue()
		"intro_retry":
			prologue_interact_requested = false
			prologue.retry()
		"intro_fast":
			instant_prologue_text = not instant_prologue_text
			if prologue != null: prologue.fast_text = instant_prologue_text
			_save_settings()
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
			previous_mode = mode
			mode = "pause"
		"map":
			mode = "map"
		"resume":
			mode = previous_mode
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
			prologue = null
			previous_mode = "play"
			dialogue.clear()
			has_save = not _read_checkpoint().is_empty()
			sound.set_mood("menu")
		"exit":
			get_tree().quit()
		"residues":
			get_tree().set_meta("p17_residue_handoff", {"difficulty": sim.difficulty, "upgrades": sim.chosen.duplicate()})
			get_tree().change_scene_to_file("res://scenes/residues.tscn")
		_:
			if id.begins_with("difficulty_"):
				selected_difficulty = id.trim_prefix("difficulty_")
				_save_settings()
				_start_prologue(false)
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

func _start_prologue(replay: bool) -> void:
	prologue_interact_requested = false
	prologue = Prologue.new()
	prologue.fast_text = instant_prologue_text
	prologue_replay = replay
	prologue_camera = Prologue.Lab.camera(prologue.pos,_size())
	dash_requested = false
	mode = "prologue"
	sound.set_mood("calm")

func _finish_prologue() -> void:
	prologue_interact_requested = false
	if prologue_replay:
		mode = "title"
		has_save = not _read_checkpoint().is_empty()
		sound.set_mood("menu")
	else:
		_start_new_run()
	prologue = null
	previous_mode = "play"
	dash_requested = false

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
	sim.start(0, selected_difficulty)
	secondary_requested = false
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
			_notify("SETOR SEGURO  /  " + ("RESTAURE O TERMINAL" if sim.operation.ready() else sim.operation.label()), 3)
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
			sound.play_sfx("shoot" if event == "secondary" else ("ui" if event in ["operation_done","reinforcements","timing_miss","treatment_ok","treatment_miss"] else event))
		match event:
			"reinforcements":
				sound.set_mood("combat")
				_notify("ATIVIDADE HOSTIL  /  REFORÇOS DETECTADOS",3)
			"timing_miss": _notify("FORA DE SINCRONIA  /  SOLTE E E TENTE NA FAIXA VERDE",2)
			"treatment_miss": _notify("A AMOSTRA CONTÉM SÓLIDOS  /  ESCOLHA FILTRAÇÃO",2)
			"treatment_ok": _notify("FILTRAÇÃO SELECIONADA  /  SEGURE E PARA LAVAR O FILTRO",2)
			"boss_phase":
				_notify("GUARDIÃO EM SOBRECARGA  /  PADRÃO DE ATAQUE ALTERADO",3)
				shake = 3
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
	if value is Dictionary:
		var validator := Simulation.new()
		if validator.load_data(value): return value
	return {}

func _clear_checkpoint() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	has_save = false

func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("gameplay", "difficulty", selected_difficulty)
	config.set_value("audio", "muted", muted)
	config.set_value("display", "fullscreen", fullscreen)
	config.set_value("narrative", "instant_prologue_text", instant_prologue_text)
	config.save("user://settings.cfg")

func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		var saved_difficulty: Variant = config.get_value("gameplay","difficulty","operation")
		selected_difficulty = saved_difficulty if saved_difficulty is String and saved_difficulty in Simulation.DIFFICULTIES else "operation"
		muted = config.get_value("audio", "muted", false)
		fullscreen = config.get_value("display", "fullscreen", false)
		instant_prologue_text = config.get_value("narrative", "instant_prologue_text", false)
		sound.set_muted(muted)
		if fullscreen:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func _draw() -> void:
	var showing_prologue := prologue!=null and (mode=="prologue" or (mode=="pause" and previous_mode=="prologue") or (mode=="settings" and settings_return=="pause" and previous_mode=="prologue"))
	laboratory_effects.present(prologue.elapsed if prologue!=null else 0.0,prologue!=null and prologue.step>=3,showing_prologue and prologue.phase in ["lab","ending","retry"])
	water_surface.visible=not (showing_prologue or mode in ["title","briefing","difficulty"] or (mode=="settings" and settings_return=="title"))
	district_effects.present(clock,sim.restored,water_surface.visible)
	if menu_focus_mode != mode:
		menu_focus = ""
		menu_focus_mode = mode
	buttons.clear()
	if _font == null:
		return
	if showing_prologue:
		PrologueView.draw(self,prologue,prologue_camera)
		if mode!="prologue": buttons.clear()
	elif mode in ["title", "briefing", "difficulty"] or (mode == "settings" and settings_return == "title"):
		_draw_opening()
	else:
		_draw_game()
	match mode:
		"title": _draw_title()
		"difficulty": _draw_difficulty()
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
		var rect := Rect2((_size().x - width) * 0.5, 139, width, 32)
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
	draw_rect(Rect2(0, size.y - 32, size.x, 32), Color(INK, 0.88))
	for i in 35:
		var p := Vector2(fposmod(i * 181.73 + clock * (3 + i % 3), size.x), fposmod(i * 97.21 - clock * 7, size.y))
		draw_rect(Rect2(p, Vector2(2, 2)), Color(CYAN, 0.1 + 0.2 * (sin(clock + i) + 1) * 0.5))

func _draw_title() -> void:
	var size := _size()
	var x := 52.0 + maxf(0,(size.x-960)*0.08)
	var y := clampf((size.y-540)*0.18,0,45)
	if _brand_font == null:
		_brand_font = SystemFont.new()
		_brand_font.font_names = PackedStringArray(["Bahnschrift","DejaVu Sans","Arial"])
		_brand_font.font_weight = 600
	FieldHUD.text(self,"UMA CIDADE PARA RECUPERAR.",Vector2(x,y+51),10,CYAN)
	draw_line(Vector2(x,y+66),Vector2(x+49,y+66),CYAN,1)
	draw_string(_brand_font,Vector2(x-3,y+128),"PROTOCOLO",HORIZONTAL_ALIGNMENT_LEFT,-1,53,FieldHUD.WHITE)
	draw_line(Vector2(x+2,y+143),Vector2(x+100,y+143),GOLD,3)
	draw_string(_brand_font,Vector2(x-7,y+232),"17",HORIZONTAL_ALIGNMENT_LEFT,-1,115,CYAN)
	draw_string(_brand_font,Vector2(x+130,y+192),"A U R O R A",HORIZONTAL_ALIGNMENT_LEFT,-1,20,FieldHUD.WHITE)
	draw_line(Vector2(x+132,y+207),Vector2(x+292,y+207),GOLD,1)
	FieldHUD.text(self,"A rede caiu. A esperança, ainda não.",Vector2(x+132,y+225),10,MUTED)
	FieldHUD.text(self,"AÇÃO / EXPLORAÇÃO / RECUPERAÇÃO",Vector2(x,y+257),9,MUTED)
	FieldHUD.menu_button(self,Rect2(x-1,y+282,276,40),"CONTINUAR OPERAÇÃO" if has_save else "INICIAR OPERAÇÃO","continue" if has_save else "new",true,menu_focus==("continue" if has_save else "new"))
	FieldHUD.text(self,"CHECKPOINT DISPONÍVEL" if has_save else "NOVA MISSÃO / DISTRITO DAS ÁGUAS",Vector2(x+11,y+339),8,CYAN)
	var row := y+351
	if has_save:
		FieldHUD.menu_button(self,Rect2(x,row,274,28),"NOVA OPERAÇÃO","new",false,menu_focus=="new")
		row+=31
	for entry in [["CONFIGURAÇÕES","settings"],["REVER PRÓLOGO","intro_replay"],["SAIR","exit"]]:
		FieldHUD.menu_button(self,Rect2(x,row,274,28),entry[0],entry[1],false,menu_focus==entry[1])
		row+=31
	FieldHUD.text(self,"LIA / AGENTE DE RECUPERAÇÃO",Vector2(size.x-322,size.y-64),9,MUTED)
	draw_line(Vector2(38,size.y-32),Vector2(size.x-38,size.y-32),Color("415c54"),1)
	draw_circle(Vector2(43,size.y-16),2,CYAN)
	FieldHUD.text(self,"OPERAÇÃO FILTRO / SINAL LOCALIZADO",Vector2(53,size.y-12),8,MUTED)
	FieldHUD.centered(self,"↑ ↓ SELECIONAR / ENTER CONFIRMAR",Vector2(size.x/2,size.y-12),8,MUTED)
	_text_right("BETA 0.2.1 RC / F11 TELA CHEIA",Vector2(size.x-24,size.y-12),8,MUTED)

func _menu_control(r: Rect2,label: String,id: String,key: String="",accent: Color=CYAN) -> void:
	FieldHUD.control(self,r,label,id,key,accent)
	if menu_focus==id: FieldHUD.edge(self,r.grow(1),accent,2,4)

func _draw_briefing() -> void:
	var size := _size()
	draw_rect(Rect2(Vector2.ZERO, size), Color(INK, 0.65))
	_text("ARQUIVO AURORA", Vector2(60, 65), 12, CYAN)
	_text_right("REGISTRO %02d / 03" % (briefing_page + 1), Vector2(size.x - 60, 65), 11, MUTED)
	draw_line(Vector2(60, 82), Vector2(size.x - 60, 82), Color("36524f"))
	var headlines := ["O futuro tinha um endereço.", "Então, a rede silenciou.", "As ordens foram alteradas."]
	var descriptions := [
		"Aurora nasceu de uma promessa: tecnologia e natureza poderiam crescer juntas. Uma rede automatizada cuidava da água, da energia e da vida que ligava a cidade.",
		"Os canais escureceram. As bombas pararam. Os drones de manutenção passaram a atacar as pessoas que deveriam proteger.",
		"Lia recebe um último sinal do Distrito das Águas. Quatro sistemas precisam voltar a funcionar antes que a contaminação alcance toda Aurora."
	]
	_text(headlines[briefing_page], Vector2(60, 157), 34, WHITE if briefing_page != 2 else GOLD)
	_wrapped(descriptions[briefing_page], Rect2(62, 183, 650, 98), 17, MUTED, 26)
	var trans: Array = TRANSMISSIONS[briefing_page]
	draw_rect(Rect2(60, 302, size.x - 120, 104), Color(INK, 0.94))
	draw_rect(Rect2(60, 302, 3, 104), CYAN)
	_radio_portrait(Vector2(81, 321), trans[0] == "LIA")
	_text("CANAL LOCAL  /  " + trans[0], Vector2(153, 329), 10, CYAN)
	var message: String = trans[1]
	var visible := message.substr(0, mini(message.length(), int(briefing_clock * 60)))
	_wrapped(visible, Rect2(153, 342, size.x - 240, 60), 14, WHITE, 21)
	_button(Rect2(size.x - 269, size.y - 86, 209, 39), "DESEMBARCAR  →" if briefing_page == 2 else "PRÓXIMO REGISTRO  →", "next", true)
	_button(Rect2(60, size.y - 86, 171, 39), "PULAR INTRODUÇÃO", "skip", false)
	_text("ENTER AVANÇA  /  ESC PULA", Vector2(60, size.y - 22), 10, MUTED)

func _draw_game() -> void:
	var jitter := Vector2(sin(clock * 103), cos(clock * 79)) * shake
	var world_offset:=(_size()*0.5-camera_pos+jitter).round()
	water_surface.present(world_offset,clock,sim.restored)
	draw_set_transform(world_offset)
	district_effects.present(clock,sim.restored)
	World.draw(self, camera_pos, sim.stage, sim.restored, clock,water_surface,district_effects)
	energy_station.draw_foundation(self, clock)
	_draw_terminals()
	_draw_operation_markers()
	var entities: Array[Dictionary] = []
	for enemy in sim.enemies:
		if enemy.hp > 0:
			entities.append({"y": enemy.pos.y+(29 if enemy.kind=="boss" else 14), "enemy": enemy})
	entities.append({"y": sim.pos.y+14, "player": true})
	for wreck in enemy_presentation.wrecks:
		entities.append({"y": wreck.pos.y, "wreck": wreck})
	var world_view := Rect2(camera_pos-Vector2(770,490),Vector2(1540,980))
	for world_object in World.sortable_objects(world_view):
		entities.append({"y": world_object.y, "world_object": world_object})
	for part in energy_station.sortable_parts():
		entities.append({"y":part.y,"structure":energy_station,"part":part.index})
	entities.sort_custom(func(a, b): return a.y < b.y)
	for entity in entities:
		if entity.has("world_object"):
			World.draw_sortable(self,entity.world_object,sim.restored,clock,sim.stage,sim.state=="activation" and sim.operation.ready(),sim.repair)
		elif entity.has("structure"):
			if entity.part == 2:
				Objectives.draw_body(self,World.GOALS[1],1,sim.restored>1,clock,sim.stage==1 and sim.state=="activation" and sim.operation.ready(),sim.repair if sim.stage==1 else 0.0)
			else:
				entity.structure.draw_part(self,entity.part,clock)
		elif entity.has("player"):
			var lia_action := "repair" if sim.repair > 0 else ("fire" if sim.state == "combat" and sim._fire_cd > 0 else "idle")
			var shot_age := sim.fire_interval - sim._fire_cd if sim._fire_cd > 0 else -1.0
			Actors.draw_lia(self, sim.pos, sim.aim, lia_animation.elapsed, lia_animation.moving, sim.invuln > 0 and int(clock * 16) % 2 == 0, sim.dash_time > 0, lia_action, shot_age)
		elif entity.has("wreck"):
			Actors.ENEMIES.draw_destroyed(self, entity.wreck)
		else:
			var enemy: Dictionary = entity.enemy
			if enemy.get("warning", 0.0) > 0:
				_text_center("!",enemy.pos+Vector2(0,-65 if enemy.kind == "boss" else -43),18,GOLD)
			Actors.draw_drone(self, enemy_presentation.view_for(enemy), sim.elapsed)
	energy_station.draw_effects(self, clock)
	for index in range(4):
		Objectives.draw_sign(self,World.GOALS[index],index,index<sim.restored,index==sim.stage and sim.state=="activation" and sim.operation.ready(),sim.repair if index==sim.stage else 0.0,clock)
	_draw_operation_beacon()
	for bolt in sim.bullets:
		if not bolt.hostile:
			Actors.WEAPON.draw_pulse(self, bolt, clock)
			continue
		var color: Color = MAGENTA if bolt.hostile else CYAN
		var tail: Vector2 = bolt.pos - bolt.vel.normalized() * 11
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
		var light_color: Color = CYAN if i < sim.restored or (i == sim.stage and sim.state == "activation" and sim.operation.ready()) else MAGENTA
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
		Objectives.draw_service_marker(self,World.GOALS[i],i,i<sim.restored,i==sim.stage and sim.state=="activation" and sim.operation.ready(),sim.repair if i==sim.stage else 0.0,clock)

func _draw_hud() -> void:
	var size := _size()
	FieldHUD.vital(self, sim.hp, sim.max_hp, clock)
	var alive := 0
	for enemy in sim.enemies:
		if enemy.hp > 0: alive += 1
	var detail: String = sim.operation.label() if not sim.operation.ready() else ("Restaure o terminal do setor" if sim.state == "activation" else "Neutralize os drones para liberar o terminal")
	var status := "%02d DRONES  •  LEVA %d/3  •  TAREFAS %d/2" % [alive, mini(sim.wave + 1, 3), sim.operation.completed]
	if sim.restored > sim.stage:
		detail = "Sistema restaurado"
		status = "REDE EM OPERAÇÃO"
	FieldHUD.mission(self, size.x, SECTOR_SUBTITLES[sim.stage], detail, status, sim.stage, sim.restored, 4)
	FieldHUD.navigation(self, "ÁGUAS / AURORA", Simulation.DIFFICULTY_NAMES[Simulation.DIFFICULTIES.find(sim.difficulty)] + " / OPERAÇÃO DE CAMPO", pointer)
	buttons.append({"rect": Rect2(333, 28, 78, 23), "id": "map"})
	buttons.append({"rect": Rect2(419, 28, 107, 23), "id": "pause"})
	_draw_operation_hud()
	FieldHUD.abilities(self, size.y, sim.secondary_cd, sim.secondary_recharge, sim.dash_cd, sim.dash_recharge)
	_draw_minimap(Rect2(size.x - 202, size.y - 160, 186, 144))

	if sim.pos.distance_to(World.GOALS[sim.stage]) < 84 and sim.operation.ready():
		var message: String = "[E] REPARAR " + Objectives.SYSTEMS[sim.stage] if sim.state == "activation" else "TERMINAL BLOQUEADO  /  ELIMINE OS DRONES"
		if sim.restored>sim.stage: message = "SISTEMA RESTAURADO  /  " + Objectives.TITLES[sim.stage]
		var rect := Rect2(size.x * 0.5 - 190, size.y - 110, 380, 45)
		FieldHUD.panel(self, rect)
		_text_center(message, rect.get_center() + Vector2(0, 1), 10, CYAN if sim.state == "activation" else GOLD)
		if sim.state == "activation":
			draw_rect(Rect2(rect.position + Vector2(12, 35), Vector2((rect.size.x - 24) * sim.repair, 3)), CYAN)
	else:
		var goal: Vector2 = World.GOALS[sim.stage] if sim.operation.ready() else sim.operation.target()
		var difference: Vector2 = goal - sim.pos
		if difference.length() > 250:
			var anchor := size * 0.5 + difference.normalized() * minf(size.y * 0.32, 170)
			draw_circle(anchor, 12, Color(INK, 0.82))
			var dir := difference.normalized()
			var side := dir.orthogonal()
			draw_colored_polygon(PackedVector2Array([anchor + dir * 6, anchor - dir * 4 + side * 4, anchor - dir * 4 - side * 4]), CYAN)
	for enemy in sim.enemies:
		if enemy.kind == "boss" and enemy.hp > 0 and enemy.pos.distance_to(sim.pos) < 480:
			FieldHUD.panel(self, Rect2(size.x * 0.5 - 190, size.y - 61, 380, 43), MAGENTA)
			var rect := Rect2(size.x * 0.5 - 176, size.y - 33, 352, 5)
			_text_center("GUARDIÃO DA REDE  /  FASE %d" % (int(enemy.tier)+1), Vector2(size.x * 0.5, size.y - 42), 10, MAGENTA)
			draw_rect(rect, Color("352835"))
			draw_rect(Rect2(rect.position, Vector2(rect.size.x * enemy.hp / enemy.max_hp, 5)), MAGENTA)

func _draw_crosshair(p: Vector2) -> void:
	var c := CYAN
	for d in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		draw_line(p + d * 5, p + d * 9, Color(INK, 0.9), 3)
		draw_line(p + d * 5, p + d * 9, c, 1)
	draw_rect(Rect2(p - Vector2.ONE, Vector2(2, 2)), WHITE)

func _draw_minimap(rect: Rect2) -> void:
	var inner := FieldHUD.radar(self, rect)
	var scale_value := minf(inner.size.x / World.SIZE.x, inner.size.y / World.SIZE.y)
	var origin := inner.get_center() - World.SIZE * scale_value * 0.5
	for i in 4:
		var region: Rect2 = World.REGIONS[i]
		draw_rect(Rect2(origin + region.position * scale_value, region.size * scale_value), Color("31544d") if i <= sim.stage else Color("182e38"))
		var p: Vector2 = origin + World.GOALS[i] * scale_value
		draw_rect(Rect2(p - Vector2(2, 2), Vector2(4, 4)), CYAN if i < sim.restored else GOLD)
	for channel in World.Wetlands.CHANNELS:
		draw_rect(Rect2(origin+channel.position*scale_value,channel.size*scale_value),Color("103f4c"))
	for crossing in World.Wetlands.CROSSINGS:
		draw_rect(Rect2(origin+crossing.position*scale_value,crossing.size*scale_value),Color("709183"))
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
	for index in 2:
		var point: Vector2 = sim.operation.points[index]
		draw_circle(origin+point*scale_value,2,CYAN if index<sim.operation.completed else GOLD)
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
	for channel in World.Wetlands.CHANNELS:
		draw_rect(Rect2(origin+channel.position*ratio,channel.size*ratio),Color("103f4c"))
	for crossing in World.Wetlands.CROSSINGS:
		draw_rect(Rect2(origin+crossing.position*ratio,crossing.size*ratio),Color("709183"))
	var route: Array = World.ROUTES[sim.stage]
	for i in range(route.size() - 1):
		draw_dashed_line(origin + route[i] * ratio, origin + route[i + 1] * ratio, Color(CYAN, 0.6), 1, 5)
	for enemy in sim.enemies:
		if enemy.hp > 0:
			draw_circle(origin + enemy.pos * ratio, 3, MAGENTA)
	for index in 2:
		var point: Vector2 = sim.operation.points[index]
		draw_circle(origin+point*ratio,5,CYAN if index<sim.operation.completed else GOLD)
		_text(str(index+1),origin+point*ratio+Vector2(8,-5),10,GOLD)
	var player_p: Vector2 = origin + sim.pos * ratio
	draw_circle(player_p, 7, Color(WHITE, 0.15))
	draw_circle(player_p, 3, WHITE)
	var x := size.x - 248
	_text("SISTEMAS ONLINE", Vector2(x, 138), 11, MUTED)
	_text("%d / 4" % sim.restored, Vector2(x, 185), 35, CYAN)
	_wrapped("Cumpra as duas tarefas de campo, neutralize as três levas e restaure o terminal para liberar a passagem.", Rect2(x, 211, 195, 70), 12, WHITE, 19)
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
	var size := _size()
	draw_rect(Rect2(Vector2.ZERO,size),Color(INK,0.92))
	var r := Rect2(size.x/2-240,size.y/2-182,480,364)
	FieldHUD.panel(self,r)
	FieldHUD.centered(self,"SINAL EM ESPERA",r.position+Vector2(240,44),26,WHITE)
	FieldHUD.centered(self,"A operação está pausada.",r.position+Vector2(240,72),12,MUTED)
	_menu_control(Rect2(r.position+Vector2(60,104),Vector2(360,40)),"RETOMAR OPERAÇÃO","resume","ESC")
	_menu_control(Rect2(r.position+Vector2(60,158),Vector2(360,35)),"CONFIGURAÇÕES","settings")
	_menu_control(Rect2(r.position+Vector2(60,207),Vector2(360,35)),"VOLTAR AO INÍCIO","title")
	if previous_mode=="prologue":
		_menu_control(Rect2(r.position+Vector2(60,256),Vector2(360,32)),"PULAR INTRODUÇÃO","intro_skip","P",GOLD)
	else:
		FieldHUD.centered(self,"O checkpoint guarda o início da etapa atual.",r.position+Vector2(240,281),10,MUTED)
	FieldHUD.centered(self,"↑ ↓ SELECIONAR / ENTER CONFIRMAR",r.position+Vector2(240,333),9,GOLD)

func _draw_settings() -> void:
	var size := _size()
	draw_rect(Rect2(Vector2.ZERO,size),Color(INK,0.92))
	var r := Rect2(size.x/2-340,size.y/2-216,680,432)
	FieldHUD.panel(self,r)
	FieldHUD.centered(self,"CONFIGURAÇÕES",r.position+Vector2(340,43),26,WHITE)
	FieldHUD.centered(self,"Ajuste seu equipamento de campo.",r.position+Vector2(340,69),12,MUTED)
	_menu_control(Rect2(r.position+Vector2(40,96),Vector2(600,40)),"ÁUDIO / "+("DESLIGADO" if muted else "LIGADO"),"sound","F10")
	_menu_control(Rect2(r.position+Vector2(40,149),Vector2(600,40)),"TELA / "+("CHEIA" if fullscreen else "JANELA"),"fullscreen","F11")
	var area := Rect2(r.position+Vector2(40,212),Vector2(600,117))
	FieldHUD.inset(self,area)
	FieldHUD.centered(self,"CONTROLES DE CAMPO",area.position+Vector2(300,23),10,GOLD)
	FieldHUD.centered(self,"WASD / SETAS: MOVER   •   MOUSE: MIRAR E DISPARAR",area.position+Vector2(300,47),10,WHITE)
	FieldHUD.centered(self,"Q / BOTÃO DIREITO: RAJADA   •   SHIFT: ESQUIVA",area.position+Vector2(300,68),10,MUTED)
	FieldHUD.centered(self,"E: RESTAURAR   •   M: MAPA   •   ESC: PAUSA",area.position+Vector2(300,89),10,MUTED)
	var level_name: String = Simulation.DIFFICULTY_NAMES[Simulation.DIFFICULTIES.find(sim.difficulty if settings_return=="pause" else selected_difficulty)]
	FieldHUD.text(self,"DIFICULDADE / "+level_name,r.position+Vector2(43,356),9,GOLD)
	_menu_control(Rect2(r.position+Vector2(240,371),Vector2(200,35)),"VOLTAR","back","ESC")
func _draw_upgrades() -> void:
	var size := _size()
	draw_rect(Rect2(Vector2.ZERO, size), Color(INK, 0.93))
	var header := Rect2(size.x * 0.5 - 163, 23, 326, 36)
	FieldHUD.panel(self, header)
	FieldHUD.centered(self, "SISTEMA %02d RESTAURADO / OFICINA P17" % sim.restored, header.get_center() + Vector2(0, 4), 10, CYAN)
	FieldHUD.centered(self, "Recuperar também transforma você.", Vector2(size.x * 0.5, 108), 27, WHITE)
	FieldHUD.centered(self, "ESCOLHA UM MÓDULO PARA A PRÓXIMA ETAPA", Vector2(size.x * 0.5, 137), 10, MUTED)
	var options: Array = sim.upgrade_options()
	var content_width := minf(size.x - 64, 1100)
	var width := (content_width - 32) / 3
	var height := minf(300, size.y - 250)
	var top := maxf(169, (size.y - height) * 0.5 - 5)
	var left := (size.x - content_width) * 0.5
	for i in options.size():
		var option: Dictionary = options[i]
		var rect := Rect2(left + i * (width + 16), top, width, height)
		var hover := rect.has_point(pointer)
		FieldHUD.perk_card(self, rect, option.id, i, hover)
		_wrapped(option.title.to_upper(), Rect2(rect.position + Vector2(24, 112), Vector2(width - 48, 47)), 17, WHITE, 22)
		_wrapped(option.description, Rect2(rect.position + Vector2(24, 174), Vector2(width - 48, 62)), 12, MUTED, 17)
		buttons.append({"rect": rect, "id": "upgrade_%d" % i})
	var footer := Rect2(size.x * 0.5 - 302, size.y - 56, 604, 34)
	FieldHUD.panel(self, footer, CYAN)
	FieldHUD.centered(self, "VIDA CHEIA NO PRÓXIMO SETOR  /  CLIQUE OU PRESSIONE 1, 2 OU 3", footer.get_center() + Vector2(0, 4), 10, CYAN)

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
	_button(Rect2(size.x * 0.5 - 155, 438, 310, 42), "SEGUIR AO DISTRITO DE RESÍDUOS  →", "residues", true)
	_text_center("OPERAÇÃO FILTRO  /  ODS 6 — ÁGUA POTÁVEL E SANEAMENTO", Vector2(size.x * 0.5, size.y - 19), 9, MUTED)

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


func _draw_difficulty() -> void:
	var size := _size()
	draw_rect(Rect2(Vector2.ZERO,size),Color(INK,0.90))
	var r := Rect2(size.x/2-360,size.y/2-235,720,470)
	FieldHUD.panel(self,r)
	FieldHUD.centered(self,"ESCOLHA SUA OPERAÇÃO",r.position+Vector2(360,44),26,WHITE)
	FieldHUD.centered(self,"Quatro setores. Uma cidade para recuperar.",r.position+Vector2(360,72),12,MUTED)
	var descriptions := ["9 de vida / 37 inimigos. Mais tempo para reagir e sincronizar.","6 de vida / 57 inimigos. Tiros rápidos e pressão crescente.","5 de vida / 77 inimigos. Tiros mais rápidos e sincronização precisa."]
	for index in 3:
		var id: String = "difficulty_"+Simulation.DIFFICULTIES[index]
		var y := 99.0+index*88
		_menu_control(Rect2(r.position+Vector2(35,y),Vector2(650,43)),Simulation.DIFFICULTY_NAMES[index]+(" / SELECIONADO" if selected_difficulty==Simulation.DIFFICULTIES[index] else ""),id,str(index+1),CYAN if index==1 else GOLD)
		FieldHUD.centered(self,descriptions[index],r.position+Vector2(360,y+64),11,MUTED)
	_menu_control(Rect2(r.position+Vector2(270,375),Vector2(180,34)),"VOLTAR","difficulty_back","ESC")
	FieldHUD.centered(self,"A dificuldade fica vinculada ao checkpoint da operação.",r.position+Vector2(360,443),10,MUTED)
func _draw_operation_markers() -> void:
	for index in 2:
		var point: Vector2 = sim.operation.points[index]
		var done: bool = index < sim.operation.completed
		var active: bool = index == sim.operation.completed and sim.state == "activation"
		var color := CYAN if done else (GOLD if active else MUTED)
		# A compact floor console; all points are validated against world collision.
		draw_rect(Rect2(point+Vector2(-18,-18),Vector2(36,36)),INK)
		draw_rect(Rect2(point+Vector2(-16,-16),Vector2(32,32)),color,false,2)
		draw_rect(Rect2(point+Vector2(-10,-10),Vector2(20,13)),Color(color,0.35))
		_text_center("OK" if done else str(index+1),point+Vector2(0,5),11,color)


func _draw_operation_hud() -> void:
	var size := _size()
	if sim.state != "activation" or sim.operation.ready() or sim.pos.distance_to(sim.operation.target()) > 72: return
	if sim.operation.wants_treatment(sim.pos):
		var rect := Rect2(size.x*0.5-232,192,464,207)
		FieldHUD.panel(self, rect)
		_text_center("ANÁLISE DA AMOSTRA",Vector2(size.x*0.5,220),15,CYAN)
		_text_center("Sólidos em suspensão. Qual etapa retém as partículas?",Vector2(size.x*0.5,246),12,WHITE)
		var choices := ["1  /  DISTRIBUIR SEM TRATAMENTO","2  /  FILTRAR A ÁGUA","3  /  AUMENTAR A PRESSÃO"]
		for index in 3:
			_button(Rect2(rect.position.x+22,264+index*40,420,32),choices[index],"treatment_"+str(index),false)
		return
	var rect := Rect2(size.x*0.5-190,size.y-115,380,62)
	FieldHUD.panel(self, rect)
	var prompt := "SEGURE E  /  " + sim.operation.label()
	if sim.stage == 1: prompt = "APERTE E QUANDO O INDICADOR ESTIVER VERDE"
	_text_center(prompt,rect.position+Vector2(190,21),10,WHITE)
	var bar := Rect2(rect.position+Vector2(18,34),Vector2(344,10))
	draw_rect(bar,Color("29424a"))
	if sim.stage == 1:
		var width: float = 0.22 if sim.difficulty=="story" else (0.11 if sim.difficulty=="veteran" else 0.16)
		draw_rect(Rect2(bar.position+Vector2((0.5-width)*bar.size.x,0),Vector2(width*2*bar.size.x,10)),CYAN)
		draw_rect(Rect2(bar.position+Vector2(sim.operation.charge()*bar.size.x-2,-3),Vector2(4,16)),WHITE)
	else:
		draw_rect(Rect2(bar.position,Vector2(bar.size.x*sim.operation.progress,10)),CYAN)


func _clear_pending_actions() -> void:
	dash_requested = false
	secondary_requested = false
	interact_requested = false

func _draw_operation_beacon() -> void:
	if sim.state != "activation" or sim.operation.ready(): return
	var point: Vector2 = sim.operation.target()
	var rect := Rect2(point+Vector2(-130,-84),Vector2(260,26))
	draw_rect(rect,Color(INK,0.94))
	draw_rect(rect,GOLD,false,1)
	_text_center(str(sim.operation.completed+1)+"  /  "+sim.operation.label(),rect.get_center()+Vector2(0,4),10,GOLD)
	draw_colored_polygon(PackedVector2Array([point+Vector2(-5,-52),point+Vector2(5,-52),point+Vector2(0,-44)]),GOLD)
