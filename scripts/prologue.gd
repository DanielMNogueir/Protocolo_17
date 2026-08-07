extends Control

const CYAN := Color("#35d6df")
const CYAN_LIGHT := Color("#82f5ef")
const MAP_TEXTURE := preload("res://assets/cenario_distrito_das_aguas.png")

const STORY_PAGES := [
	{
		"chapter": "REGISTRO 01  |  A CIDADE-MODELO",
		"title": "AURORA",
		"text": "Aurora nasceu para provar que desenvolvimento e natureza poderiam crescer juntos. Água limpa, energia renovável e consumo responsável faziam parte da vida de todos.",
	},
	{
		"chapter": "REGISTRO 02  |  OS DEZESSETE OBJETIVOS",
		"title": "PROTOCOLO 17",
		"text": "Para proteger esse futuro, a cidade criou o Protocolo 17: uma rede inspirada nos 17 Objetivos de Desenvolvimento Sustentável, capaz de monitorar água, energia, resíduos e qualidade ambiental.",
	},
	{
		"chapter": "REGISTRO 03  |  A NOITE DA FALHA",
		"title": "O COLAPSO",
		"text": "Então, sem aviso, a rede entrou em falha. Sistemas essenciais foram interrompidos, canais receberam água contaminada e drones de manutenção passaram a atacar quem se aproximasse.",
	},
	{
		"chapter": "REGISTRO 04  |  SINAL DE EMERGÊNCIA",
		"title": "O CHAMADO DE LIA",
		"text": "Lia, uma jovem agente de recuperação ambiental, recebeu um sinal vindo do Distrito das Águas. Se os filtros pararem por completo, a contaminação alcançará toda Aurora.",
	},
	{
		"chapter": "MISSÃO 01  |  ÁGUAS DE AURORA",
		"title": "OPERAÇÃO FILTRO",
		"text": "Entre no distrito, encontre o Disparador de Pulso, repare os três filtros e neutralize todos os drones hostis. A origem da falha ainda é desconhecida — mas a recuperação de Aurora começa agora.",
	},
]

var page_index := 0
var chapter_label: Label
var title_label: Label
var body_label: Label
var page_label: Label
var previous_button: Button
var next_button: Button


func _ready() -> void:
	_build_screen()
	_update_page()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_next_page()


func _build_screen() -> void:
	var image := TextureRect.new()
	image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	image.texture = MAP_TEXTURE
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	image.modulate = Color(0.34, 0.46, 0.47, 1.0)
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(image)

	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.005, 0.02, 0.035, 0.80)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	var top_line := ColorRect.new()
	top_line.anchor_right = 1.0
	top_line.offset_bottom = 5.0
	top_line.color = CYAN
	add_child(top_line)

	var panel := PanelContainer.new()
	panel.anchor_left = 0.12
	panel.anchor_top = 0.14
	panel.anchor_right = 0.88
	panel.anchor_bottom = 0.88
	panel.add_theme_stylebox_override("panel", _panel_style())
	add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 45)
	margin.add_theme_constant_override("margin_top", 32)
	margin.add_theme_constant_override("margin_right", 45)
	margin.add_theme_constant_override("margin_bottom", 28)
	panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 9)
	margin.add_child(layout)

	chapter_label = _label("", 14, CYAN_LIGHT)
	layout.add_child(chapter_label)
	title_label = _label("", 34, CYAN)
	layout.add_child(title_label)

	var separator := HSeparator.new()
	separator.custom_minimum_size.y = 12
	layout.add_child(separator)

	body_label = _label("", 21, Color("#e5f1ef"))
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	body_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(body_label)

	page_label = _label("", 14, Color("#94b7b2"))
	page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	layout.add_child(page_label)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	layout.add_child(actions)
	previous_button = _button("ANTERIOR", _previous_page, false)
	actions.add_child(previous_button)
	actions.add_spacer(false)
	actions.add_child(_button("PULAR HISTÓRIA", _finish_story, false))
	next_button = _button("PRÓXIMO", _next_page, true)
	actions.add_child(next_button)


func _update_page() -> void:
	var page: Dictionary = STORY_PAGES[page_index]
	chapter_label.text = page["chapter"]
	title_label.text = page["title"]
	body_label.text = page["text"]
	page_label.text = str(page_index + 1) + " / " + str(STORY_PAGES.size())
	previous_button.disabled = page_index == 0
	next_button.text = "INICIAR MISSÃO" if page_index == STORY_PAGES.size() - 1 else "PRÓXIMO"


func _next_page() -> void:
	if page_index >= STORY_PAGES.size() - 1:
		_finish_story()
		return
	page_index += 1
	_update_page()


func _previous_page() -> void:
	page_index = maxi(0, page_index - 1)
	_update_page()


func _finish_story() -> void:
	_state().mark_prologue_seen()
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _state():
	var state = get_node_or_null("/root/GameState")
	if state == null:
		state = load("res://scripts/game_state.gd").new()
		state.name = "GameState"
		get_tree().root.add_child(state)
	return state


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.065, 0.085, 0.96)
	style.border_color = Color(CYAN, 0.75)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.shadow_color = Color(0, 0, 0, 0.65)
	style.shadow_size = 18
	return style


func _button(text_value: String, callback: Callable, primary: bool) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(150, 44)
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_color_override("font_color", Color("#07141c") if primary else Color.WHITE)
	button.add_theme_stylebox_override("normal", _button_style(CYAN if primary else Color("#173441")))
	button.add_theme_stylebox_override("hover", _button_style(CYAN_LIGHT))
	button.add_theme_stylebox_override("pressed", _button_style(Color("#22aeb7")))
	button.pressed.connect(callback)
	return button


func _button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = CYAN_LIGHT
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	return style


func _label(text_value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label
