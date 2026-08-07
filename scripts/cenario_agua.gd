extends Node2D

const WORLD_SIZE := Vector2(1600.0, 900.0)
const GRASS := Color("#476b3c")
const GRASS_LIGHT := Color("#577d47")
const PATH := Color("#bca77a")
const PATH_EDGE := Color("#8b7752")
const WATER := Color("#26718b")
const WATER_LIGHT := Color("#49a8b5")
const METAL := Color("#344b56")
const CYAN := Color("#35d6df")

var tree_positions := [
	Vector2(120, 120), Vector2(245, 155), Vector2(385, 105),
	Vector2(105, 430), Vector2(245, 535), Vector2(1490, 545),
	Vector2(1370, 625), Vector2(1110, 690), Vector2(510, 650)
]


func _ready() -> void:
	_create_collision_rect(Rect2(-32, -32, WORLD_SIZE.x + 64, 32))
	_create_collision_rect(Rect2(-32, WORLD_SIZE.y, WORLD_SIZE.x + 64, 32))
	_create_collision_rect(Rect2(-32, 0, 32, WORLD_SIZE.y))
	_create_collision_rect(Rect2(WORLD_SIZE.x, 0, 32, WORLD_SIZE.y))

	# Canal: a ponte central permanece livre para passagem.
	_create_collision_rect(Rect2(0, 720, 710, 180))
	_create_collision_rect(Rect2(890, 720, 710, 180))

	# Predio da estacao e paineis solares.
	_create_collision_rect(Rect2(1175, 125, 305, 270))
	_create_collision_rect(Rect2(85, 260, 250, 85))

	for tree_position in tree_positions:
		_create_collision_rect(Rect2(tree_position - Vector2(18, 10), Vector2(36, 28)))

	queue_redraw()


func _draw() -> void:
	# Base do mapa.
	draw_rect(Rect2(Vector2.ZERO, WORLD_SIZE), GRASS)
	draw_rect(Rect2(0, 0, WORLD_SIZE.x, 28), Color("#29452f"))
	draw_rect(Rect2(0, WORLD_SIZE.y - 20, WORLD_SIZE.x, 20), Color("#29452f"))

	# Pequenas variacoes no gramado.
	for x in range(45, 1550, 95):
		for y in range(55, 700, 110):
			var parity := int(x / 95) + int(y / 110)
			var offset := 18 if parity % 2 == 0 else -12
			draw_line(Vector2(x + offset, y), Vector2(x + offset + 5, y - 7), GRASS_LIGHT, 2)
			draw_line(Vector2(x + offset + 5, y), Vector2(x + offset + 10, y - 5), GRASS_LIGHT, 2)

	# Caminhos principais.
	draw_rect(Rect2(650, 0, 300, 720), PATH_EDGE)
	draw_rect(Rect2(664, 0, 272, 720), PATH)
	draw_rect(Rect2(0, 390, 1600, 210), PATH_EDGE)
	draw_rect(Rect2(0, 404, 1600, 182), PATH)

	# Marcacoes de pedra no caminho.
	for x in range(690, 930, 48):
		for y in range(25, 700, 54):
			draw_rect(Rect2(x, y, 34, 3), Color("#aa956b"))

	# Canal e ondas.
	draw_rect(Rect2(0, 720, 1600, 180), Color("#173f52"))
	draw_rect(Rect2(0, 735, 1600, 165), WATER)
	for y in range(758, 890, 34):
		for x in range(20, 1580, 95):
			draw_line(Vector2(x, y), Vector2(x + 42, y), WATER_LIGHT, 3)

	# Ponte central.
	draw_rect(Rect2(710, 690, 180, 210), Color("#4e3825"))
	for y in range(700, 900, 24):
		draw_rect(Rect2(720, y, 160, 18), Color("#9a673a"))
		draw_line(Vector2(720, y + 18), Vector2(880, y + 18), Color("#5b3d27"), 2)
	draw_line(Vector2(714, 690), Vector2(714, 900), Color("#d0a45b"), 6)
	draw_line(Vector2(886, 690), Vector2(886, 900), Color("#d0a45b"), 6)

	# Estacao de tratamento.
	draw_rect(Rect2(1175, 125, 305, 270), Color("#1c3038"))
	draw_rect(Rect2(1190, 142, 275, 238), METAL)
	draw_rect(Rect2(1220, 175, 105, 175), Color("#233d48"))
	draw_rect(Rect2(1340, 175, 95, 175), Color("#26343d"))
	draw_rect(Rect2(1240, 200, 65, 115), Color("#237c91"))
	draw_rect(Rect2(1252, 215, 41, 80), Color("#57c7d2"))
	draw_circle(Vector2(1387, 230), 28, Color("#10252d"))
	draw_circle(Vector2(1387, 230), 17, CYAN)
	draw_rect(Rect2(1250, 355, 140, 12), CYAN)

	# Paineis solares.
	for panel_x in [85, 215]:
		draw_rect(Rect2(panel_x, 260, 120, 85), Color("#172936"))
		draw_rect(Rect2(panel_x + 7, 267, 106, 71), Color("#1f6380"))
		for gx in range(panel_x + 32, panel_x + 110, 26):
			draw_line(Vector2(gx, 267), Vector2(gx, 338), Color("#63acc2"), 2)
		for gy in range(290, 338, 23):
			draw_line(Vector2(panel_x + 7, gy), Vector2(panel_x + 113, gy), Color("#63acc2"), 2)

	# Arvores e vegetacao.
	for tree_position in tree_positions:
		_draw_tree(tree_position)

	# Ponto inicial e area do objetivo.
	draw_circle(Vector2(800, 500), 34, Color(0.15, 0.85, 0.88, 0.18))
	draw_arc(Vector2(800, 500), 34, 0, TAU, 48, CYAN, 3)
	draw_rect(Rect2(1080, 430, 230, 115), Color(0.08, 0.15, 0.18, 0.82))
	draw_rect(Rect2(1092, 442, 206, 91), Color("#27505a"))
	draw_rect(Rect2(1110, 468, 170, 14), Color("#13252c"))
	draw_rect(Rect2(1110, 468, 102, 14), CYAN)

	# Moldura do mapa.
	draw_rect(Rect2(2, 2, WORLD_SIZE.x - 4, WORLD_SIZE.y - 4), Color("#22382a"), false, 5)


func _draw_tree(position: Vector2) -> void:
	draw_rect(Rect2(position.x - 7, position.y + 18, 14, 24), Color("#5c3b25"))
	draw_circle(position + Vector2(-16, 5), 25, Color("#244c31"))
	draw_circle(position + Vector2(14, 3), 27, Color("#2f6339"))
	draw_circle(position + Vector2(0, -14), 30, Color("#3b7942"))
	draw_circle(position + Vector2(-4, -18), 17, Color("#55954e"))


func _create_collision_rect(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collision.shape = shape
	collision.position = rect.position + rect.size / 2.0
	body.add_child(collision)
	add_child(body)
