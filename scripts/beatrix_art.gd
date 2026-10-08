extends RefCounted
const SHEET: Texture2D = preload("res://assets/prologue/beatrix.png")
const DATA = preload("res://assets/prologue/beatrix_frames.gd")
const PORTRAIT: Texture2D = preload("res://assets/prologue/beatrix_portrait_v1.png")
const WALK_ROWS := [1,0,2,0]
# Screen-pixel offsets measured from the hair centers at the 58 px game scale.
# The source atlas anchors stride frames on an extended boot, moving the torso.
const WALK_ALIGN := [[12,11],[11,12],[1,-3],[-12,-12],[-11,-11],[10,9],[-4,2],[-10,-8]]

static func draw(canvas: Node2D, position: Vector2, facing: Vector2, time: float, moving: bool, hurt: bool = false) -> void:
	var direction := posmod(int(floor((facing.angle()+PI/8)/(PI/4))),8)
	var row: int = WALK_ROWS[posmod(int(time*8),WALK_ROWS.size())] if moving else 0
	var frame: Dictionary = DATA.FRAMES[row*8+direction]
	var region: Rect2 = frame.region
	var scale_value := 58.0/float(DATA.HEIGHT)
	var foot := position.round()+Vector2(0,13)
	var vertices := PackedVector2Array()
	for n in range(16): vertices.append(foot+Vector2(cos(n*TAU/16)*13,sin(n*TAU/16)*4))
	canvas.draw_colored_polygon(vertices,Color("091d28",0.45))
	var offset_x: int = WALK_ALIGN[direction][row-1] if row>0 else 0
	var destination := Rect2(foot+(region.position-frame.anchor)*scale_value+Vector2(offset_x,0),region.size*scale_value)
	canvas.draw_texture_rect_region(SHEET,destination,region,Color("e79daa") if hurt else Color.WHITE)

static func portrait(canvas: Node2D, destination: Rect2) -> void:
	var scale_value:=minf(destination.size.x/PORTRAIT.get_width(),destination.size.y/PORTRAIT.get_height())
	var extent:=PORTRAIT.get_size()*scale_value
	canvas.draw_texture_rect(PORTRAIT,Rect2(destination.get_center()-extent*0.5,extent),false)
