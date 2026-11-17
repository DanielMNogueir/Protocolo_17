extends RefCounted

const Story = preload("res://scripts/core_story.gd")
const Field = preload("res://scripts/field_hud.gd")
const MapUI = preload("res://scripts/field_map.gd")
const CITY: Texture2D = preload("res://assets/prologue/aurora_before.png")
const PIER: Texture2D = preload("res://docs/direcao-visual/distrito-das-aguas-conceito.png")
const LAB: Texture2D = preload("res://assets/prologue/laboratory_set_v1.png")
const RESIDUES: Texture2D = preload("res://assets/residues/district_city_v3.png")
const WATER_CROP := Rect2(20, 172, 1630, 545)
const PINK := Color("e36b92")
const CREDIT_SPEED := 40.0
const CREDIT_ROW := 96
const CREDITS := [
	["PROTOCOLO 17", []],
	["DIREÇÃO E DESIGN", ["EQUIPE PROTOCOLO 17"]],
	["PROGRAMAÇÃO", ["EQUIPE PROTOCOLO 17"]],
	["ARTE", ["EQUIPE PROTOCOLO 17"]],
	["NARRATIVA", ["EQUIPE PROTOCOLO 17"]],
	["ÁUDIO", ["EQUIPE PROTOCOLO 17"]],
	["AGRADECIMENTOS", ["EQUIPE PROTOCOLO 17"]],
]

var result := ""
var sequence := ""
var index := 0
var age := 0.0
var credits_time := 0.0


func start(ending: String) -> void:
	result = ending
	sequence = "resolution"
	age = 0.0


func show_cards() -> void:
	sequence = "cards"
	index = 0
	age = 0.0


func cards() -> Array:
	return Story.EPILOGUE_AI if result == "ai" else Story.EPILOGUE_HUMANITY


func step(dt: float, skip: bool) -> String:
	age += dt
	match sequence:
		"resolution":
			if age >= 3.0:
				sequence = ""
				return "ai_dialogue" if result == "ai" else "human_dialogue"
		"cards":
			if (skip and age >= 0.3) or age >= 8.5:
				age = 0.0
				index += 1
				if index == cards().size(): sequence = "signal"
		"signal":
			var duration := float(Story.PIER_RADIO.length()) / 32.0 + 2.0 if result == "ai" else 5.0
			if age >= duration:
				sequence = ""
				return "finish"
	return ""


func begin_credits() -> void:
	credits_time = 0.0


func tick_credits(dt: float, height: float) -> bool:
	credits_time += dt
	return credits_time * CREDIT_SPEED > height + CREDITS.size() * CREDIT_ROW + 85.0


func accent() -> Color:
	return PINK if result == "ai" else Field.CYAN


func draw(canvas: Node2D, size: Vector2) -> void:
	match sequence:
		"cards":
			var card: Array = cards()[index]
			_draw_card(canvas, size, card)
		"signal":
			_draw_signal(canvas, size)


func _draw_card(canvas: Node2D, size: Vector2, card: Array) -> void:
	var r := Rect2(Vector2.ZERO, size)
	match card[0]:
		"aurora": _cover(canvas, CITY, r)
		"ai_aurora": _cover(canvas, CITY, r, Color("8cae96"))
		"residues": _cover(canvas, RESIDUES, r)
		"water": _cover(canvas, PIER, r, Color.WHITE, WATER_CROP)
		"exodus":
			_cover(canvas, CITY, r, Color("697f86"))
			_exodus(canvas, size)
		"spread": _spread(canvas, size)
	var panel := Rect2(size.x * 0.5 - 358.0, size.y - 112.0, 716.0, 88.0)
	Field.panel(canvas, panel, accent())
	MapUI.wrapped(canvas, card[1], Rect2(panel.position + Vector2(22, 18), Vector2(panel.size.x - 180, 56)), 16, Field.WHITE, 21)
	Field.control(canvas, Rect2(panel.end - Vector2(147, 48), Vector2(125, 29)), "AVANÇAR", "next_card", "ENTER", accent())


func _draw_signal(canvas: Node2D, size: Vector2) -> void:
	_cover(canvas, PIER if result == "ai" else LAB, Rect2(Vector2.ZERO, size), Color("526976"),
		WATER_CROP if result == "ai" else Rect2())
	var panel := Rect2(size.x * 0.5 - 320.0, size.y - 144.0, 640, 112)
	Field.panel(canvas, panel, accent())
	var message := Story.PIER_RADIO if result == "ai" else Story.LAB_MESSAGE
	Field.text(canvas, "MAJOR 0" if result == "ai" else "LABORATÓRIO / TERMINAL", panel.position + Vector2(18, 26), 12, accent())
	Field.text(canvas, message.left(int(age * 32.0)), panel.position + Vector2(18, 56), 16)
	if result == "humanity" and age >= 2.0:
		Field.text(canvas, Story.LAB_RADIO.left(int((age - 2.0) * 26.0)), panel.position + Vector2(18, 86), 15, Field.CYAN)


func _exodus(canvas: Node2D, size: Vector2) -> void:
	var y := size.y * 0.67
	canvas.draw_rect(Rect2(0, y, size.x, 24), Color("283b43"))
	canvas.draw_line(Vector2(0, y), Vector2(size.x, y), Field.GOLD, 3)
	for i in 30:
		var x := fposmod(i * 43.0 - age * 48.0, size.x + 90.0) - 40.0
		var feet := Vector2(x, y - 2)
		var step := sin(age * 11.0 + i) * 4.0
		var ink := Color("11252c")
		canvas.draw_circle(feet + Vector2(0, -24), 4, ink)
		canvas.draw_line(feet + Vector2(0, -19), feet + Vector2(0, -7), ink, 5)
		canvas.draw_line(feet + Vector2(0, -7), feet + Vector2(step, 0), ink, 2)
		canvas.draw_line(feet + Vector2(0, -7), feet + Vector2(-step, 0), ink, 2)


func _spread(canvas: Node2D, size: Vector2) -> void:
	canvas.draw_rect(Rect2(Vector2.ZERO, size), Field.INK)
	var center := Vector2(size.x * 0.5, size.y * 0.4)
	for i in 7:
		var end := center + Vector2.from_angle(TAU * i / 7.0) * Vector2(size.x * 0.32, size.y * 0.27)
		var p := clampf((age - i * 0.4) * 2.0, 0.0, 1.0)
		canvas.draw_line(center, end, Color(PINK, 0.18), 2, true)
		canvas.draw_line(center, center.lerp(end, p), PINK, 3, true)
		canvas.draw_circle(end, 5, PINK if p >= 1.0 else Field.MUTED)
	canvas.draw_circle(center, 11, PINK)
	Field.centered(canvas, "AURORA", center + Vector2(0, -18), 14, Field.WHITE)


func draw_credits(canvas: Node2D, size: Vector2) -> void:
	draw_background(canvas, size)
	var x := size.x * 0.5
	var y := size.y + 30.0 - credits_time * CREDIT_SPEED
	for group in CREDITS:
		Field.centered(canvas, group[0], Vector2(x, y), 22, accent())
		for person in group[1]:
			Field.centered(canvas, person, Vector2(x, y + 26), 14)
		y += CREDIT_ROW
	Field.centered(canvas, "Aurora está limpa. E vazia." if result == "ai" else "Aurora foi recuperada. Por enquanto.", Vector2(x, y), 18)
	Field.control(canvas, Rect2(size.x - 160, size.y - 48, 144, 32), "PULAR CRÉDITOS", "skip_credits", "ESC", accent())


func draw_background(canvas: Node2D, size: Vector2) -> void:
	var r := Rect2(Vector2.ZERO, size)
	_cover(canvas, CITY, r, Color("846c9c") if result == "ai" else Color("b2a08a"))
	canvas.draw_rect(r, Color(Field.INK, 0.72))


static func _cover(canvas: Node2D, texture: Texture2D, frame: Rect2, tint: Color = Color.WHITE, source: Rect2 = Rect2()) -> void:
	if not source.has_area():
		source = Rect2(Vector2.ZERO, texture.get_size())
	var fit := maxf(frame.size.x / source.size.x, frame.size.y / source.size.y)
	var crop := frame.size / fit
	canvas.draw_texture_rect_region(texture, frame, Rect2(source.get_center() - crop * 0.5, crop), tint)
