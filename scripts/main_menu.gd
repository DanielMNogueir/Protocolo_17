extends Control

## Menu principal do Protocolo 17.
## Layout inspirado em Stardew Valley: logo centralizada + botões em fileira.

# ── Paleta ──────────────────────────────────────────────
const CYAN := Color("#35d6df")
const CYAN_LIGHT := Color("#7cf4ee")
const DARK := Color("#07141c")
const MAP_TEXTURE := preload("res://assets/cenario_distrito_das_aguas.png")

# Logo (protocolo_17_logo_hud.html)
const LOGO_WHITE := Color("#f4faf8")
const LOGO_TEAL := Color("#6fe0d6")
const LOGO_LEAF := Color("#7fd858")
const LOGO_GRAD_A := Color("#3fb6e8")
const LOGO_GRAD_B := Color("#6fd85e")
const LOGO_BG := Color(0.039, 0.055, 0.047, 0.75)
const LOGO_BORDER_GLOW := Color(0.435, 0.878, 0.839, 0.2)
const KANIT_FONT := preload("res://assets/fonts/Kanit-Regular.ttf")

# Botões tile
const TILE_BG := Color(0.035, 0.10, 0.14, 0.88)
const TILE_BORDER := Color("#35d6df")
const TILE_HOVER_BG := Color(0.055, 0.18, 0.22, 0.94)
const TILE_DISABLED_BG := Color(0.03, 0.06, 0.08, 0.65)
const TILE_DISABLED_BORDER := Color("#304550")

var button_row: HBoxContainer
var overlay_layer: Control
var overlay_content: VBoxContainer
var volume_slider: HSlider
var volume_value_label: Label
var fullscreen_toggle: CheckButton
var status_label: Label


func _ready() -> void:
	_build_background()
	_build_main_screen()
	_build_overlay_layer()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if overlay_layer.visible:
			_close_overlay()


# ── Fundo cênico ────────────────────────────────────────
func _build_background() -> void:
	var image := TextureRect.new()
	image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	image.texture = MAP_TEXTURE
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	image.modulate = Color(0.50, 0.68, 0.68, 1.0)
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(image)

	# Escurecimento sutil
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.01, 0.03, 0.05, 0.40)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)


# ── Tela principal ──────────────────────────────────────
func _build_main_screen() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 0)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# Espaço superior — empurra a logo para o terço superior
	var top_spacer := Control.new()
	top_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	top_spacer.custom_minimum_size.y = 20
	top_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(top_spacer)

	# ── Logo centralizada ──
	var logo_wrap := CenterContainer.new()
	logo_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(logo_wrap)
	logo_wrap.add_child(_build_logo_panel())

	# Gap
	var gap1 := Control.new()
	gap1.custom_minimum_size.y = 14
	gap1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(gap1)

	# Espaço do meio
	var mid_spacer := Control.new()
	mid_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mid_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(mid_spacer)

	# ── Fileira de botões (estilo Stardew Valley) ──
	var btn_wrap := CenterContainer.new()
	btn_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(btn_wrap)
	button_row = HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 18)
	button_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn_wrap.add_child(button_row)
	_populate_main_buttons()

	# Espaço inferior + status
	var gap2 := Control.new()
	gap2.custom_minimum_size.y = 28
	gap2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(gap2)

	var status_wrap := CenterContainer.new()
	status_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(status_wrap)
	status_label = _label("ODS 6  |  ÁGUA POTÁVEL E SANEAMENTO", 12, Color("#7a9e98"))
	status_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
	status_label.add_theme_constant_override("shadow_offset_x", 1)
	status_label.add_theme_constant_override("shadow_offset_y", 1)
	status_wrap.add_child(status_label)

	var bottom_pad := Control.new()
	bottom_pad.custom_minimum_size.y = 22
	bottom_pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bottom_pad)


func _populate_main_buttons() -> void:
	for child in button_row.get_children():
		button_row.remove_child(child)
		child.queue_free()

	button_row.add_child(_tile_button("NOVO\nJOGO", _start_new_game, true))

	var cont := _tile_button("CONTINUAR", _continue_game, false)
	if not _state().has_save():
		cont.disabled = true
		cont.tooltip_text = "Nenhum save encontrado."
		cont.modulate = Color(1, 1, 1, 0.50)
	button_row.add_child(cont)

	button_row.add_child(_tile_button("OPÇÕES", _show_settings, false))
	button_row.add_child(_tile_button("SAIR", _quit_game, false))


# ── Painel da logo (reproduz protocolo_17_logo_hud.html) ─
func _build_logo_panel() -> Control:
	var container := PanelContainer.new()
	container.add_theme_stylebox_override("panel", _logo_bg_style())
	container.clip_contents = true  # overflow: hidden
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 36)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 36)
	margin.add_theme_constant_override("margin_bottom", 24)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(col)

	# ── PROTOCOLO 17 🌿 ──
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 2)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(row)

	var bold := _bold_kanit()

	# "PROTOCOLO" — glow branco suave (text-shadow: 0 0 10px)
	var proto := Label.new()
	proto.text = "PROTOCOLO"
	proto.add_theme_font_override("font", bold)
	proto.add_theme_font_size_override("font_size", 60)
	proto.add_theme_color_override("font_color", LOGO_WHITE)
	proto.add_theme_color_override("font_shadow_color", Color(0.96, 0.98, 0.97, 0.3))
	proto.add_theme_constant_override("shadow_offset_x", 1)
	proto.add_theme_constant_override("shadow_offset_y", 1)
	proto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(proto)

	# Spacer 8px (margin-left: 8px no HTML)
	var spc := Control.new()
	spc.custom_minimum_size.x = 8
	spc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(spc)

	# "17" — neon teal glow (text-shadow: 0 0 12px rgba(111,224,214,0.6))
	var num := Label.new()
	num.text = "17"
	num.add_theme_font_override("font", bold)
	num.add_theme_font_size_override("font_size", 60)
	num.add_theme_color_override("font_color", LOGO_TEAL)
	num.add_theme_color_override("font_shadow_color", Color(0.435, 0.878, 0.839, 0.6))
	num.add_theme_constant_override("shadow_offset_x", 1)
	num.add_theme_constant_override("shadow_offset_y", 1)
	num.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(num)

	# Spacer 6px
	var spc2 := Control.new()
	spc2.custom_minimum_size.x = 6
	spc2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(spc2)

	# 🌿 Folha com animação de pulso (leafPulse 3s infinite)
	var leaf := Label.new()
	leaf.text = "🌿"
	leaf.add_theme_font_size_override("font_size", 18)
	leaf.add_theme_color_override("font_color", LOGO_LEAF)
	leaf.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	leaf.pivot_offset = Vector2(9, 9)  # centro do emoji para scale
	leaf.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(leaf)
	_start_leaf_pulse(leaf)

	# ── Barra gradiente com scanline animada ──
	var bar_container := Control.new()
	bar_container.custom_minimum_size = Vector2(0, 4)
	bar_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar_container.clip_contents = true
	bar_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(bar_container)

	var bar := TextureRect.new()
	bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bar.texture = _gradient_tex()
	bar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bar.stretch_mode = TextureRect.STRETCH_SCALE
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar_container.add_child(bar)

	# Scanline sweep (hud-bar::after animation)
	var scanline := ColorRect.new()
	scanline.color = Color(1, 1, 1, 0.35)
	scanline.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scanline.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	scanline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar_container.add_child(scanline)
	_start_scanline(scanline, bar_container)

	return container


# ── Animação de pulso na folha (leafPulse 3s infinite) ──
func _start_leaf_pulse(leaf: Label) -> void:
	var tween := create_tween().set_loops()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(leaf, "scale", Vector2(1.15, 1.15), 1.5)
	tween.tween_property(leaf, "scale", Vector2(1.0, 1.0), 1.5)


# ── Animação de varredura na barra (hudScan 2.5s infinite) ──
func _start_scanline(scanline: ColorRect, bar_container: Control) -> void:
	# Espera 1 frame para bar_container ter tamanho calculado
	await get_tree().process_frame
	var bar_w := bar_container.size.x
	if bar_w <= 0:
		bar_w = 400.0  # fallback
	var scan_w := bar_w * 0.6
	scanline.custom_minimum_size.x = scan_w
	scanline.size = Vector2(scan_w, 4)
	scanline.position = Vector2(-scan_w, 0)

	var tween := create_tween().set_loops()
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(scanline, "position:x", bar_w * 1.4, 2.5)
	tween.tween_callback(func(): scanline.position.x = -scan_w)


# ── Overlay (Configurações) ─────────────────────────────
func _build_overlay_layer() -> void:
	overlay_layer = Control.new()
	overlay_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay_layer.visible = false
	add_child(overlay_layer)

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.62)
	overlay_layer.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay_layer.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(520, 0)
	panel.add_theme_stylebox_override("panel", _overlay_panel_style())
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 36)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_right", 36)
	margin.add_theme_constant_override("margin_bottom", 30)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(margin)

	overlay_content = VBoxContainer.new()
	overlay_content.add_theme_constant_override("separation", 16)
	overlay_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(overlay_content)


func _show_settings() -> void:
	_clear(overlay_content)

	overlay_content.add_child(_section_title("CONFIGURAÇÕES"))
	overlay_content.add_child(_description("Ajuste a apresentação do jogo. As preferências ficam salvas neste computador."))

	# Volume
	var vol_row := HBoxContainer.new()
	vol_row.add_theme_constant_override("separation", 12)
	var vol_title := _label("VOLUME GERAL", 16, Color.WHITE)
	vol_title.custom_minimum_size.x = 150
	vol_row.add_child(vol_title)
	volume_slider = HSlider.new()
	volume_slider.min_value = 0.0
	volume_slider.max_value = 100.0
	volume_slider.step = 1.0
	volume_slider.value = _state().master_volume * 100.0
	volume_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	volume_slider.value_changed.connect(_on_volume_changed)
	vol_row.add_child(volume_slider)
	volume_value_label = _label(str(roundi(volume_slider.value)) + "%", 15, CYAN_LIGHT)
	volume_value_label.custom_minimum_size.x = 48
	vol_row.add_child(volume_value_label)
	overlay_content.add_child(vol_row)

	# Tela cheia
	fullscreen_toggle = CheckButton.new()
	fullscreen_toggle.text = "TELA CHEIA"
	fullscreen_toggle.button_pressed = _state().fullscreen
	fullscreen_toggle.add_theme_font_size_override("font_size", 16)
	overlay_content.add_child(fullscreen_toggle)

	# Botões ação
	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 14)
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_child(_action_button("SALVAR", _save_settings, true))
	btn_row.add_child(_action_button("CANCELAR", _close_overlay, false))
	overlay_content.add_child(btn_row)

	overlay_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay_layer.visible = true


func _close_overlay() -> void:
	overlay_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay_layer.visible = false


# ── Ações ───────────────────────────────────────────────
func _start_new_game() -> void:
	_state().start_new_game()
	get_tree().change_scene_to_file("res://scenes/prologue.tscn")


func _continue_game() -> void:
	if not _state().has_save():
		return
	var dest := "res://scenes/main.tscn" if _state().has_seen_prologue() else "res://scenes/prologue.tscn"
	get_tree().change_scene_to_file(dest)


func _save_settings() -> void:
	_state().save_settings(volume_slider.value / 100.0, fullscreen_toggle.button_pressed)
	_close_overlay()


func _on_volume_changed(value: float) -> void:
	if volume_value_label:
		volume_value_label.text = str(roundi(value)) + "%"


func _quit_game() -> void:
	get_tree().quit()


func _state():
	var s = get_node_or_null("/root/GameState")
	if s == null:
		s = load("res://scripts/game_state.gd").new()
		s.name = "GameState"
		get_tree().root.add_child(s)
	return s


func _clear(container: Control) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


# ── Botão tile (estilo Stardew Valley) ──────────────────
func _tile_button(text_value: String, callback: Callable, primary: bool) -> Button:
	var btn := Button.new()
	btn.text = text_value
	btn.custom_minimum_size = Vector2(155, 90)
	btn.add_theme_font_override("font", _bold_kanit())
	btn.add_theme_font_size_override("font_size", 20)
	btn.add_theme_color_override("font_color", LOGO_WHITE if not primary else DARK)
	btn.add_theme_color_override("font_hover_color", DARK)
	btn.add_theme_stylebox_override("normal", _tile_style(
		CYAN if primary else TILE_BG,
		CYAN_LIGHT if primary else TILE_BORDER))
	btn.add_theme_stylebox_override("hover", _tile_style(CYAN_LIGHT, CYAN_LIGHT))
	btn.add_theme_stylebox_override("pressed", _tile_style(Color("#22aeb7"), CYAN))
	btn.add_theme_stylebox_override("disabled", _tile_style(TILE_DISABLED_BG, TILE_DISABLED_BORDER))
	btn.add_theme_color_override("font_disabled_color", Color("#5a6e72"))
	btn.pressed.connect(callback)
	return btn


# ── Botão de ação (dentro do overlay) ───────────────────
func _action_button(text_value: String, callback: Callable, primary: bool) -> Button:
	var btn := Button.new()
	btn.text = text_value
	btn.custom_minimum_size = Vector2(180, 44)
	btn.add_theme_font_size_override("font_size", 16)
	btn.add_theme_color_override("font_color", DARK if primary else Color.WHITE)
	btn.add_theme_color_override("font_hover_color", DARK)
	btn.add_theme_stylebox_override("normal", _flat_btn_style(
		CYAN if primary else Color("#173441"), CYAN))
	btn.add_theme_stylebox_override("hover", _flat_btn_style(CYAN_LIGHT, CYAN_LIGHT))
	btn.add_theme_stylebox_override("pressed", _flat_btn_style(Color("#22aeb7"), CYAN))
	btn.pressed.connect(callback)
	return btn


# ── Estilos ─────────────────────────────────────────────
func _logo_bg_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = LOGO_BG  # rgba(10, 14, 12, 0.75)
	style.border_color = LOGO_BORDER_GLOW  # rgba(111, 224, 214, 0.2)
	style.set_border_width_all(1)  # border: 1px
	style.set_corner_radius_all(8)  # border-radius: 8px
	style.shadow_color = Color(0, 0, 0, 0.8)  # box-shadow: 0 0 25px
	style.shadow_size = 25
	return style


func _tile_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(3)
	style.set_corner_radius_all(10)
	style.shadow_color = Color(0, 0, 0, 0.40)
	style.shadow_size = 8
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style


func _flat_btn_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 20
	style.content_margin_right = 20
	return style


func _overlay_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.075, 0.095, 0.96)
	style.border_color = Color(CYAN, 0.7)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.shadow_color = Color(0, 0, 0, 0.6)
	style.shadow_size = 24
	return style


func _bold_kanit() -> Font:
	var variation := FontVariation.new()
	variation.base_font = KANIT_FONT
	variation.variation_embolden = 0.8  # font-weight: 900
	return variation


func _gradient_tex() -> GradientTexture2D:
	# linear-gradient(90deg, #3fb6e8 0%, #6fd85e 100%)
	var gradient := Gradient.new()
	gradient.set_color(0, LOGO_GRAD_A)
	gradient.set_color(1, LOGO_GRAD_B)
	var tex := GradientTexture2D.new()
	tex.gradient = gradient
	tex.width = 256
	tex.height = 1
	tex.fill_from = Vector2(0, 0)
	tex.fill_to = Vector2(1, 0)
	return tex


# ── Helpers de label ────────────────────────────────────
func _label(text_value: String, font_size: int, color: Color) -> Label:
	var lbl := Label.new()
	lbl.text = text_value
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return lbl


func _section_title(text_value: String) -> Label:
	var lbl := _label(text_value, 22, CYAN_LIGHT)
	lbl.add_theme_font_override("font", _bold_kanit())
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.custom_minimum_size.y = 36
	return lbl


func _description(text_value: String) -> Label:
	var lbl := _label(text_value, 15, Color("#c3d5d2"))
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return lbl
