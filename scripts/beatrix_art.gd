extends RefCounted
const SHEET: Texture2D = preload("res://assets/prologue/beatrix.png")
const DATA = preload("res://assets/prologue/beatrix_frames.gd")

static func draw(canvas: Node2D, position: Vector2, facing: Vector2, time: float, moving: bool, hurt: bool = false) -> void:
	var direction := posmod(int(floor((facing.angle()+PI/8)/(PI/4))),8)
	var row := 1+posmod(int(time*8),2) if moving else 0
	var frame: Dictionary = DATA.FRAMES[row*8+direction]
	var region: Rect2 = frame.region
	var scale_value := 58.0/float(DATA.HEIGHT)
	var foot := position.round()+Vector2(0,13)
	var vertices := PackedVector2Array()
	for n in range(16): vertices.append(foot+Vector2(cos(n*TAU/16)*13,sin(n*TAU/16)*4))
	canvas.draw_colored_polygon(vertices,Color("091d28",0.45))
	var destination := Rect2(foot+(region.position-frame.anchor)*scale_value,region.size*scale_value)
	canvas.draw_texture_rect_region(SHEET,destination,region,Color("e79daa") if hurt else Color.WHITE)

static func portrait(canvas: Node2D, destination: Rect2) -> void:
	var r: Rect2 = DATA.FRAMES[2].region
	r.size.y *= 0.39
	canvas.draw_texture_rect_region(SHEET,destination,r)
