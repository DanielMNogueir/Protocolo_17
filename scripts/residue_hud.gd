extends Control

const MapUI = preload("res://scripts/field_map.gd")
const FieldHUD = preload("res://scripts/field_hud.gd")
const M = preload("res://scripts/residue_map.gd")
const Loadout = preload("res://scripts/campaign_loadout.gd")
const WHITE := Color("e9ece0")
const CYAN := Color("7be4ce")
const GOLD := Color("e8bd74")
const INK := Color("091922")
const MUTED := FieldHUD.MUTED
var game: Node2D

func _draw() -> void:
	if game == null: return
	game.buttons.clear()
	var size := get_viewport_rect().size
	FieldHUD.vital(self, game.hp, game.max_hp, game.clock)
	var direction: Vector2 = game.guidance_point() - game.pos
	FieldHUD.mission(self, size.x, ["CENTRO DE TRIAGEM", "USINA DE RECICLAGEM", "UNIDADE DE COMPOSTAGEM", "DISTRITO RECUPERADO"][game.stage], _direction(direction) + "  " + game.objective_label(), "RESÍDUOS  •  SISTEMAS %d/3" % mini(game.stage, 3), game.stage, mini(game.stage, 3), 3)
	FieldHUD.abilities(self, size.y, game.secondary_cd, 3.8, game.dash_cd, game.dash_recharge)
	FieldHUD.navigation(self, "RESÍDUOS / AURORA", "RECUPERAÇÃO INDUSTRIAL", game.pointer)
	if game.state == "play":
		game.buttons.append({"rect": Rect2(333, 28, 78, 23), "id": "map"})
		game.buttons.append({"rect": Rect2(419, 28, 107, 23), "id": "pause"})
	var mini_map := FieldHUD.radar(self, Rect2(size.x - 202, size.y - 160, 186, 144))

	_draw_plan(mini_map, false)
	var candidate: Dictionary = game._interaction_candidate()
	if not candidate.is_empty():
		var message := ""
		match candidate.kind:
			"item": message = "E  •  RECOLHER " + M.MATERIALS[candidate.index]
			"bin": message = "E  •  ENTREGAR " + M.MATERIALS[game.carried]
			"block": message = "SEGURE E  •  " + ("DESOBSTRUIR ESTEIRA" if candidate.index < 2 else "REABRIR VENTILAÇÃO")
			"terminal": message = "SEGURE E  •  RESTAURAR SISTEMA"
		var box := Rect2(size.x * 0.5 - 200, size.y - 110, 400, 44)
		_panel(box)
		_text_center(message, box.get_center() + Vector2(0, 3), 11, CYAN)
		if game.hold_progress > 0: draw_rect(Rect2(box.position + Vector2(0, 41), Vector2(400 * game.hold_progress, 3)), CYAN)
	elif game.carried >= 0:
		_text_center("EM MÃOS: " + M.MATERIALS[game.carried] + "  /  PROCURE A BAIA", Vector2(size.x * 0.5, size.y - 38), 11, GOLD)
	if game.bin_lock > 0:
		_text_center("TRIAGEM REINICIANDO  /  %.1f s" % game.bin_lock, Vector2(size.x * 0.5, size.y - 128), 11, GOLD)
	if game.toast_time > 0:
		var toast := Rect2(size.x * 0.5 - 265, 146, 530, 34)
		_panel(toast)
		_text_center(game.toast, toast.get_center() + Vector2(0, 4), 10, WHITE)
	match game.state:
		"defeat":
			game.buttons.clear()
			_overlay("CONEXÃO INTERROMPIDA", "R reinicia o Distrito de Resíduos")
			_overlay_buttons(true)
		"victory":
			game.buttons.clear()
			_draw_victory(size)
		"upgrade":
			game.buttons.clear()
			_draw_modules(size)
		"pause":
			game.buttons.clear()
			_overlay("OPERAÇÃO PAUSADA", "ESC continua  /  R reinicia o distrito")
			_overlay_buttons(true)
		"map":
			game.buttons.clear()
			_draw_map(size)
	if game.state == "play":
		var aim: Vector2 = game.pointer
		for axis in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]: draw_line(aim + axis * 3, aim + axis * 7, CYAN, 1)

func _panel(rect: Rect2) -> void:
	FieldHUD.panel(self, rect)

func _draw_victory(size: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(INK, 0.95))
	_text_center("DISTRITO DE RESÍDUOS  /  RECUPERADO", Vector2(size.x * 0.5, 62), 11, CYAN)
	_text_center("A cidade volta a separar o que pode renascer.", Vector2(size.x * 0.5, 110), 26, WHITE)
	_text_center("Triagem. Reciclagem. Compostagem. Nada mais se acumula nos bairros.", Vector2(size.x * 0.5, 140), 12, MUTED)
	var record := Rect2(size.x * 0.5 - 330, 172, 660, 128)
	_panel(record)
	draw_rect(Rect2(record.position, Vector2(3, record.size.y)), GOLD)
	_text("REGISTRO RECUPERADO  /  NÚCLEO DA IA", record.position + Vector2(22, 27), 10, GOLD)
	_wrapped("LIA: Liga metálica, polímero e vidro técnico. Os materiais saíram daqui para montar o núcleo da IA… e seguiram pela rede elétrica.", Rect2(record.position + Vector2(22, 38), Vector2(record.size.x - 44, 50)), 13, WHITE, 19)
	_text("DESTINO DO ÚLTIMO LOTE: DISTRITO DE ENERGIA", record.position + Vector2(22, 108), 10, Color("e36b92"))
	var center := Vector2(size.x * 0.5, 0)
	_button(Rect2(center + Vector2(-150, 322), Vector2(300, 36)), "INSTALAR MÓDULO  /  ENTER", "modules")
	_button(Rect2(center + Vector2(-150, 368), Vector2(300, 32)), "ESCOLHER DISTRITO / B", "districts")
	_text_center("DISTRITO DE RESÍDUOS  /  ODS 12 — CONSUMO E PRODUÇÃO RESPONSÁVEIS", Vector2(size.x * 0.5, size.y - 19), 9, MUTED)

func _draw_modules(size: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(INK, 0.95))
	var header := Rect2(size.x * 0.5 - 170, 23, 340, 36)
	FieldHUD.panel(self, header)
	FieldHUD.centered(self, "RESÍDUOS RECUPERADO / OFICINA P17", header.get_center() + Vector2(0, 4), 10, CYAN)
	FieldHUD.centered(self, "Prepare-se para a rede elétrica.", Vector2(size.x * 0.5, 104), 25, WHITE)
	FieldHUD.centered(self, "ESCOLHA UM MÓDULO PARA O DISTRITO DE ENERGIA", Vector2(size.x * 0.5, 132), 10, MUTED)
	var options: Array = Loadout.RESIDUE_UPGRADES
	var content_width := minf(size.x - 64, 1100)
	var width := (content_width - 32) / 3
	var height := minf(300, size.y - 236)
	var top := maxf(158, (size.y - height) * 0.5 - 5)
	var left := (size.x - content_width) * 0.5
	for i in options.size():
		var option: Dictionary = options[i]
		var rect := Rect2(left + i * (width + 16), top, width, height)
		FieldHUD.perk_card(self, rect, option.id, i, rect.has_point(game.pointer))
		_wrapped(str(option.title).to_upper(), Rect2(rect.position + Vector2(24, 112), Vector2(width - 48, 47)), 16, WHITE, 21)
		_wrapped(option.description, Rect2(rect.position + Vector2(24, 174), Vector2(width - 48, 62)), 12, MUTED, 17)
		game.buttons.append({"rect": rect, "id": "module_%d" % i})
	var footer := Rect2(size.x * 0.5 - 302, size.y - 50, 604, 32)
	FieldHUD.panel(self, footer, CYAN)
	var notice: String = game.module_notice
	FieldHUD.centered(self, notice if notice != "" else "MÓDULOS ANTERIORES PRESERVADOS  /  CLIQUE OU PRESSIONE 1, 2 OU 3", footer.get_center() + Vector2(0, 4), 10, Color("e36b92") if notice != "" else CYAN)

func _wrapped(value: String, rect: Rect2, font_size: int, color: Color, line_height: int) -> void:
	var line := ""
	var y := rect.position.y + font_size
	for word in value.split(" "):
		var candidate := word if line.is_empty() else line + " " + word
		if ThemeDB.fallback_font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > rect.size.x and not line.is_empty():
			_text(line, Vector2(rect.position.x, y), font_size, color)
			line = word
			y += line_height
		else:
			line = candidate
	_text(line, Vector2(rect.position.x, y), font_size, color)

func _overlay_buttons(retry: bool) -> void:
	var center := get_viewport_rect().size * 0.5
	if game.state == "pause": _button(Rect2(center + Vector2(-150, 51), Vector2(300, 34)), "CONTINUAR / ESC", "resume")
	elif retry: _button(Rect2(center + Vector2(-150, 51), Vector2(300, 34)), "TENTAR NOVAMENTE / R", "retry")
	else: _button(Rect2(center + Vector2(-150, 51), Vector2(300, 34)), "JOGAR NOVAMENTE", "retry")
	_button(Rect2(center + Vector2(-150, 98), Vector2(300, 34)), "ESCOLHER DISTRITO / B", "districts")
	if game.state != "victory": _text_center("Ao sair, esta tentativa de Resíduos será reiniciada.", center + Vector2(0, 155), 10, MUTED)

func _button(rect: Rect2, label: String, id: String) -> void:
	FieldHUD.panel(self, rect, CYAN if rect.has_point(game.pointer) else GOLD)
	_text_center(label, rect.get_center() + Vector2(0, 4), 11, CYAN if rect.has_point(game.pointer) else WHITE)
	game.buttons.append({"rect": rect, "id": id})

func _overlay(title: String, subtitle: String) -> void:
	var size := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, size), Color(INK, 0.9))
	_text_center(title, Vector2(size.x * 0.5, size.y * 0.5 - 30), 30, WHITE)
	_text_center(subtitle, Vector2(size.x * 0.5, size.y * 0.5 + 20), 14, GOLD)

func _draw_plan(area: Rect2, detailed: bool) -> void:
	M.draw_background(self, area, Color(0.6, 0.7, 0.69, 0.95))
	if not detailed: draw_rect(area, Color(INK, 0.48))
	var scale := area.size / M.SIZE
	if detailed:
		for i in 3:
			var rect := M.world_rect(M.FACILITIES[i])
			var screen := Rect2(area.position + rect.position * scale, rect.size * scale)
			draw_rect(screen, CYAN if game.terminal_on[i] else GOLD, false, 1)
			var nameplate := Rect2(screen.position, Vector2(screen.size.x, 22))
			draw_rect(nameplate, Color(INK, 0.93))
			_text(["01  TRIAGEM AURORA", "02  RECICLAGEM PRISMA", "03  COMPOSTAGEM ÍRIS"][i], screen.position + Vector2(7, 15), 10, WHITE)
	var route := PackedVector2Array()
	for point in game.guidance_path: route.append(area.position + point * scale)
	if route.size() > 1: draw_polyline(route, Color(GOLD, 0.95), 2 if detailed else 1)
	var target: Vector2 = area.position + game.objective_point() * scale
	draw_arc(target, 7 if detailed else 4, 0, TAU, 20, GOLD, 2)
	var lia: Vector2 = area.position + game.pos * scale
	draw_circle(lia, 7 if detailed else 5, INK)
	draw_circle(lia, 4 if detailed else 3, WHITE)
	if detailed: _text("LIA", lia + Vector2(9, 3), 9, WHITE)

func _draw_map(size: Vector2) -> void:
	var parts := MapUI.shell(self,size,"DISTRITO DE RESÍDUOS","BAIRRO INDUSTRIAL / 3 INSTALAÇÕES",game.pointer)
	var canvas: Rect2 = parts.canvas
	var ratio := minf(canvas.size.x/M.SIZE.x,canvas.size.y/M.SIZE.y)
	var area := Rect2(canvas.get_center()-M.SIZE*ratio/2,M.SIZE*ratio)
	M.draw_background(self,area,Color(0.55,0.68,0.62,1))
	draw_rect(area,Color(INK,0.34))
	var scale := area.size/M.SIZE
	var occupied: Array[Vector2] = [area.position+game.pos*scale]
	if game.stage<3: occupied.append(area.position+game.objective_point()*scale)
	for terminal in M.TERMINALS: occupied.append(area.position+terminal*scale)
	for enemy in game.enemies:
		if enemy.hp>0 and enemy.zone<=game.stage: occupied.append(area.position+Vector2(enemy.pos)*scale)
	for i in 3:
		var region := M.world_rect(M.FACILITIES[i])
		var r := Rect2(area.position+region.position*scale,region.size*scale)
		draw_rect(r,CYAN if game.terminal_on[i] else (GOLD if i==game.stage else Color("617970")),false,1)
		var label: String = ["01 / TRIAGEM","02 / RECICLAGEM","03 / COMPOSTAGEM"][i]
		MapUI.tag(self,label,MapUI.label_anchor(r,[label],occupied),CYAN if game.terminal_on[i] else WHITE)
		MapUI.marker(self,area.position+M.TERMINALS[i]*scale,"terminal",game.terminal_on[i])
	for i in 2:
		var gate: Rect2 = M.GATES[i]
		draw_rect(Rect2(area.position+gate.position*scale,gate.size*scale).grow(1),CYAN if i<game.stage else MapUI.RED)
	if game.stage<3:
		var route := PackedVector2Array()
		route.append(area.position+game.pos*scale)
		for point in game.guidance_path: route.append(area.position+point*scale)
		for i in range(route.size()-1): draw_dashed_line(route[i],route[i+1],GOLD,2,4)
		MapUI.marker(self,area.position+game.objective_point()*scale,"objective")
	var alive := 0
	for enemy in game.enemies:
		if enemy.hp>0 and enemy.zone<=game.stage:
			if enemy.zone==game.stage: alive+=1
			MapUI.marker(self,area.position+Vector2(enemy.pos)*scale,"boss" if enemy.boss else "enemy")
	var player: Vector2 = area.position+game.pos*scale
	MapUI.marker(self,player,"player",false,game.aim)
	MapUI.tag(self,"LIA",player+Vector2(11,13),WHITE)
	var sorted_count := 0
	for value in game.sorted:
		if value: sorted_count+=1
	var cleared_count := 0
	for value in game.cleared:
		if value: cleared_count+=1
	var stats := [{"label":"MATERIAIS TRIADOS","value":"%d / 4" % sorted_count},{"label":"ROTAS LIBERADAS","value":"%d / 4" % cleared_count},{"label":"AMEAÇAS NO SETOR","value":"%02d" % alive,"color":MapUI.RED if alive>0 else CYAN}]
	var location: String = ["CENTRO DE TRIAGEM","USINA DE RECICLAGEM","UNIDADE DE COMPOSTAGEM","DISTRITO RECUPERADO"][game.stage]
	var hint := "Siga a rota âmbar pelas entradas das instalações e use E para interagir."
	if game.carried>=0: hint="EM MÃOS: "+M.MATERIALS[game.carried]+". Entregue o material na baia indicada."
	if game.stage==3: hint="Rede industrial recuperada. Os três sistemas estão em operação."
	MapUI.sidebar(self,parts.sidebar,mini(game.stage,3),3,location,game.objective_label(),stats,hint)
func _direction(vector: Vector2) -> String:
	if vector.length() < 45: return "●"
	return ["→", "↘", "↓", "↙", "←", "↖", "↑", "↗"][posmod(int(round(vector.angle() / (PI / 4.0))), 8)]

func _text(value: String, point: Vector2, size: int, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, point.round(), value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _text_center(value: String, point: Vector2, size: int, color: Color) -> void:
	var width := ThemeDB.fallback_font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	_text(value, point - Vector2(width * 0.5, 0), size, color)
