extends Node2D

## Invisible collision layout for the Distrito das Aguas mission.
## The rectangles are siblings of CenarioArte, so they use world coordinates.

const COLLISION_RECTS := [
	{"name": "LimiteSuperior", "position": Vector2(800, 45), "size": Vector2(1600, 90)},
	{"name": "LimiteInferior", "position": Vector2(800, 855), "size": Vector2(1600, 90)},
	{"name": "LimiteEsquerdo", "position": Vector2(40, 450), "size": Vector2(80, 900)},
	{"name": "LimiteDireito", "position": Vector2(1560, 450), "size": Vector2(80, 900)},
	{"name": "OficinaSolar", "position": Vector2(285, 175), "size": Vector2(370, 210)},
	{"name": "EstacaoTratamento", "position": Vector2(1370, 205), "size": Vector2(360, 270)},
	{"name": "JardimInferiorEsquerdo", "position": Vector2(255, 670), "size": Vector2(410, 160)},
	{"name": "JardimInferiorDireito", "position": Vector2(1270, 690), "size": Vector2(430, 150)},
	{"name": "TanqueCentral", "position": Vector2(1010, 195), "size": Vector2(150, 95)},
]


func _ready() -> void:
	for collision_data in COLLISION_RECTS:
		_create_rectangle_collision(
			collision_data["name"],
			collision_data["position"],
			collision_data["size"]
		)


func _create_rectangle_collision(body_name: String, body_position: Vector2, body_size: Vector2) -> void:
	var static_body := StaticBody2D.new()
	static_body.name = body_name
	static_body.position = body_position
	static_body.collision_layer = 1
	static_body.collision_mask = 1
	static_body.set_meta("collision_size", body_size)
	add_child(static_body)

	var collision_shape := CollisionShape2D.new()
	collision_shape.name = "CollisionShape2D"
	var rectangle := RectangleShape2D.new()
	rectangle.size = body_size
	collision_shape.shape = rectangle
	static_body.add_child(collision_shape)