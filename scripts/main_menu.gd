extends Control

const CYAN := Color("#35d6df")
const CYAN_LIGHT := Color("#7cf4ee")
const DARK := Color("#07141c")
const PANEL := Color(0.025, 0.075, 0.095, 0.96)
const MAP_TEXTURE := preload("res://assets/cenario_distrito_das_aguas.png")

var content: VBoxContainer
var status_label: Label
var volume_slider: HSlider
var volume_value_label: Label
var fullscreen_toggle: CheckButton


func _ready() -> void:
	_build_background()
	_build_shell()
	_show_main_options()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_show_main_options()


func _build_background() -> void:
	var image := TextureRect.new()
	image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	image.texture = MAP_TEXTURE
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	image.modulate = Color(0.42, 0.58, 0.58, 1.0)
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(image)

	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.01, 0.025, 0.04, 0.76)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	var accent := ColorRect.new()
	accent.anchor_left = 0.0
	accent.anchor_top = 0.0
	accent.anchor_right = 0.012
	accent.anchor_bottom = 1.0
	accent.color = CYAN
	accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(accent)


func _build_shell() -> void:
	var panel := PanelContainer.new()
	panel.anchor_left = 0.07
	panel.anchor_top = 0.07
	panel.anchor_right = 0.56
	panel.anchor_bottom = 0.93
	panel.add_theme_stylebox_override("panel", _panel_style())
	add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 42)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_right", 42)
	margin.add_theme_constant_override("margin_bottom", 26)
	panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	margin.add_child(layout)

	var eyebrow := _label("SISTEMA DE RECUPERAÇÃO DE AURORA", 13, CYAN_LIGHT)
	layout.add_child(eyebrow)

	var logo := _label("PROTOCOLO 17", 43, CYAN)
	logo.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	logo.add_theme_constant_override("shadow_offset_x", 3)
	logo.add_theme_constant_override("shadow_offset_y", 3)
	layout.add_child(logo)

	var tagline := _label("O futuro de Aurora está em nossas mãos.", 17, Color("#d7e8e4"))
	layout.add_child(tagline)

	var separator := HSeparator.new()
	separator.custom_minimum_size.y = 18
	layout.add_child(separator)

	content = VBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10)
	layout.add_child(content)

	status_label = _label("ODS 6  |  ÁGUA POTÁVEL E SANEAMENTO", 13, Color("#91b8b2"))
	layout.add_child(status_label)


func _show_main_options() -> void:
	_clear_content()
	content.add_child(_section_title("MENU PRINCIPAL"))
	content.add_child(_make_button("JOGAR", _show_play_options, true))
	content.add_child(_make_button("CONFIGURAÇÕES", _show_settings))
	content.add_child(_make_button("SAIR", _quit_game))
	status_label.text = "ODS 6  |  ÁGUA POTÁVEL E SANEAMENTO"


func _show_play_options() -> void:
	_clear_content()
	content.add_child(_section_title("SELECIONE UMA JORNADA"))
	content.add_child(_description("Inicie a história de Lia ou retorne ao Distrito das Águas."))
	content.add_child(_make_button("NOVO JOGO", _start_new_game, true))
	var continue_button := _make_button("CONTINUAR", _continue_game)
	continue_button.disabled = not _state().has_save()
	continue_button.tooltip_text = "Nenhum save encontrado." if continue_button.disabled else "Continuar a jornada salva."
	content.add_child(continue_button)
	content.add_child(_make_button("VOLTAR", _show_main_options))
	status_label.text = "SAVE LOCAL  |  PROGRESSO SALVO AUTOMATICAMENTE"


func _show_settings() -> void:
	_clear_content()
	content.add_child(_section_title("CONFIGURAÇÕES"))
	content.add_child(_description("Ajuste a apresentação do jogo. As preferências ficam salvas neste computador."))

	var volume_row := HBoxContainer.new()
	volume_row.add_theme_constant_override("separation", 12)
	var volume_title := _label("VOLUME GERAL", 16, Color.WHITE)
	volume_title.custom_minimum_size.x = 145
	volume_row.add_child(volume_title)
	volume_slider = HSlider.new()
	volume_slider.min_value = 0.0
	volume_slider.max_value = 100.0
	volume_slider.step = 1.0
	volume_slider.value = _state().master_volume * 100.0
	volume_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	volume_slider.value_changed.connect(_on_volume_changed)
	volume_row.add_child(volume_slider)
	volume_value_label = _label(str(roundi(volume_slider.value)) + "%", 15, CYAN_LIGHT)
	volume_value_label.custom_minimum_size.x = 48
	volume_row.add_child(volume_value_label)
	content.add_child(volume_row)

	fullscreen_toggle = CheckButton.new()
	fullscreen_toggle.text = "TELA CHEIA"
	fullscreen_toggle.button_pressed = _state().fullscreen
	fullscreen_toggle.add_theme_font_size_override("font_size", 16)
	content.add_child(fullscreen_toggle)

	content.add_child(_make_button("SALVAR E VOLTAR", _save_settings, true))
	content.add_child(_make_button("CANCELAR", _show_main_options))
	status_label.text = "CONFIGURAÇÕES DE EXIBIÇÃO E ÁUDIO"


func _start_new_game() -> void:
	_state().start_new_game()
	get_tree().change_scene_to_file("res://scenes/prologue.tscn")


func _continue_game() -> void:
	if not _state().has_save():
		return
	var destination := "res://scenes/main.tscn" if _state().has_seen_prologue() else "res://scenes/prologue.tscn"
	get_tree().change_scene_to_file(destination)


func _save_settings() -> void:
	_state().save_settings(volume_slider.value / 100.0, fullscreen_toggle.button_pressed)
	_show_main_options()


func _on_volume_changed(value: float) -> void:
	if volume_value_label:
		volume_value_label.text = str(roundi(value)) + "%"


func _quit_game() -> void:
	get_tree().quit()


func _clear_content() -> void:
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()


func _state():
	var state = get_node_or_null("/root/GameState")
	if state == null:
		state = load("res://scripts/game_state.gd").new()
		state.name = "GameState"
		get_tree().root.add_child(state)
	return state


func _make_button(text_value: String, callback: Callable, primary: bool = false) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(320, 48)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 17)
	button.add_theme_color_override("font_color", DARK if primary else Color.WHITE)
	button.add_theme_color_override("font_hover_color", DARK)
	button.add_theme_stylebox_override("normal", _button_style(CYAN if primary else Color("#173441"), CYAN))
	button.add_theme_stylebox_override("hover", _button_style(CYAN_LIGHT, CYAN_LIGHT))
	button.add_theme_stylebox_override("pressed", _button_style(Color("#22aeb7"), CYAN_LIGHT))
	button.add_theme_stylebox_override("disabled", _button_style(Color("#1a292f"), Color("#40535a")))
	button.pressed.connect(callback)
	return button


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL
	style.border_color = Color(CYAN, 0.7)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.shadow_color = Color(0, 0, 0, 0.55)
	style.shadow_size = 16
	return style


func _button_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(5)
	style.content_margin_left = 18
	style.content_margin_right = 18
	return style


func _label(text_value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _section_title(text_value: String) -> Label:
	var label := _label(text_value, 20, CYAN_LIGHT)
	label.custom_minimum_size.y = 36
	return label


func _description(text_value: String) -> Label:
	var label := _label(text_value, 15, Color("#c3d5d2"))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.y = 54
	return label
