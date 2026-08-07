extends CanvasLayer

const CYAN := Color("#35d6df")
const GREEN := Color("#58df7a")

var results_label: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	_build_overlay()
	visible = false
	var mission := get_parent()
	if mission.has_signal("mission_completed"):
		mission.connect("mission_completed", Callable(self, "_on_mission_completed"))


func _build_overlay() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.005, 0.02, 0.03, 0.88)
	root.add_child(shade)

	var panel := PanelContainer.new()
	panel.anchor_left = 0.18
	panel.anchor_top = 0.11
	panel.anchor_right = 0.82
	panel.anchor_bottom = 0.89
	panel.add_theme_stylebox_override("panel", _panel_style())
	root.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 42)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_right", 42)
	margin.add_theme_constant_override("margin_bottom", 28)
	panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 9)
	margin.add_child(layout)

	var overline := _label("PROTOCOLO 17  |  RELATORIO DE CAMPO", 14, CYAN)
	layout.add_child(overline)
	var title := _label("MISSÃO CONCLUÍDA", 36, GREEN)
	layout.add_child(title)
	var subtitle := _label("O Distrito das Águas voltou a operar.", 20, Color.WHITE)
	layout.add_child(subtitle)

	var separator := HSeparator.new()
	separator.custom_minimum_size.y = 14
	layout.add_child(separator)

	var summary := _label("Os filtros foram restaurados e os drones corrompidos foram neutralizados. A água limpa volta a circular por Aurora, mas a origem da falha permanece desconhecida.", 16, Color("#d5e8e4"))
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary.custom_minimum_size.y = 75
	layout.add_child(summary)

	results_label = _label("", 17, CYAN)
	results_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(results_label)

	var clue := _label("NOVO REGISTRO: alguém alterou as ordens dos drones pouco antes do colapso.", 14, Color("#ffd35a"))
	clue.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	clue.custom_minimum_size.y = 44
	layout.add_child(clue)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 12)
	layout.add_child(actions)
	actions.add_child(_button("REPETIR MISSÃO", _replay_mission, false))
	actions.add_spacer(false)
	actions.add_child(_button("MENU PRINCIPAL", _return_to_menu, true))


func _on_mission_completed(stats: Dictionary) -> void:
	results_label.text = (
		"FILTROS RESTAURADOS: " + str(stats.get("filters", 0)) + "/" + str(stats.get("total_filters", 3))
		+ "\nDRONES NEUTRALIZADOS: " + str(stats.get("drones", 0)) + "/" + str(stats.get("total_drones", 3))
		+ "\nDISTRITO RECUPERADO: ÁGUAS DE AURORA"
		+ "\nODS PROTEGIDO: ODS 6 — ÁGUA POTÁVEL E SANEAMENTO"
	)
	_state().complete_mission()
	visible = true
	get_tree().paused = true


func _replay_mission() -> void:
	visible = false
	get_tree().paused = false
	get_parent().call("reset_mission")


func _return_to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _state():
	var state = get_node_or_null("/root/GameState")
	if state == null:
		state = load("res://scripts/game_state.gd").new()
		state.name = "GameState"
		get_tree().root.add_child(state)
	return state


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.065, 0.085, 0.98)
	style.border_color = GREEN
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.shadow_color = Color(0, 0, 0, 0.7)
	style.shadow_size = 20
	return style


func _button(text_value: String, callback: Callable, primary: bool) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(180, 46)
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_color_override("font_color", Color("#07141c") if primary else Color.WHITE)
	button.add_theme_stylebox_override("normal", _button_style(GREEN if primary else Color("#173441")))
	button.add_theme_stylebox_override("hover", _button_style(Color("#8af29e")))
	button.add_theme_stylebox_override("pressed", _button_style(Color("#35b95a")))
	button.pressed.connect(callback)
	return button


func _button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = GREEN
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	return style


func _label(text_value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label
