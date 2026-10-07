extends RefCounted
## Curated cultivation and research stations in Aurora before its collapse.
const ATLAS: Texture2D = preload("res://assets/prologue/laboratory_details.png")
const Data = preload("res://assets/prologue/laboratory_details_frames.gd")
const PROPS := [
	["garden",Vector2(105,243),80.0,Rect2(69,224,72,23)],
	["garden",Vector2(863,279),68.0,Rect2(832,261,62,22)],
	["research",Vector2(448,488),106.0,Rect2(400,468,96,26)],
	["cart",Vector2(370,290),45.0,Rect2(349,277,42,16)],
	["storage",Vector2(510,532),82.0,Rect2(473,512,74,23)],
	["storage",Vector2(885,525),42.0,Rect2(866,510,38,19)],
	["terrarium",Vector2(768,257),102.0,Rect2(722,238,92,23)],
	["terrarium",Vector2(840,520),68.0,Rect2(809,503,62,23)],
	["garden",Vector2(105,523),75.0,Rect2(71,505,68,22)],
	["pump",Vector2(225,523),48.0,Rect2(203,509,44,18)],
]

static func ground(canvas: Node2D, time: float, alarm: bool, effects: P17LaboratoryEffects) -> void:
	if not effects: return
	for p in [Vector2(360,390),Vector2(485,290),Vector2(150,405),Vector2(710,460)]:
		effects.draw_light(canvas,p,Vector2(165,100),Color("7bded2",0.60))
	for p in [Vector2(265,350),Vector2(825,355)]:
		effects.draw_light(canvas,p,Vector2(145,115),Color("9be3b6",0.45))
	if alarm: effects.draw_light(canvas,Vector2(620,320),Vector2(320,255),Color("ff5d77",0.8+sin(time*2.4)*0.12))
static func draw(canvas: Node2D, index: int, time: float, effects: P17LaboratoryEffects, alarm: bool = false) -> void:
	var item: Array = PROPS[index]
	var p: Vector2 = item[1]
	var width: float = item[2]
	var kind: int = {"garden":0,"research":1,"cart":2,"storage":3,"terrarium":4,"pump":5}[item[0]]
	var source: Rect2 = Data.REGIONS[kind]
	var size := Vector2(width,width*source.size.y/source.size.x)
	var rect := Rect2(p-Vector2(size.x*0.5,size.y),size)
	canvas.draw_texture_rect_region(ATLAS,rect,source,effects.light_tint(p,alarm) if effects else Color.WHITE)
	if not effects: return
	if kind==4:
		effects.draw_glass(canvas,Rect2(rect.position+size*Vector2(0.15,0.23),size*Vector2(0.69,0.36)))
	elif kind==1:
		effects.draw_glass(canvas,Rect2(rect.position+size*Vector2(0.77,0.26),size*Vector2(0.14,0.17)))
	elif kind in [0,5]:
		# Bubbles remain in the original glass cylinder; moving drops land in its tray.
		var glass: Vector2 = Vector2(0.78,0.32) if kind==0 else Vector2(0.36,0.43)
		for n in range(4):
			var phase := fposmod(time*0.36+n*0.25,1.0)
			var q := rect.position+size*(glass+Vector2((n%2)*0.018,0.10-phase*0.19))
			canvas.draw_circle(q,0.7,Color("b0f7e4",sin(phase*PI)*0.70))
		var flow := fposmod(time*1.4,1.0)
		var nozzle := Vector2(0.87,0.72) if kind==0 else Vector2(0.92,0.71)
		var drop := rect.position+size*(nozzle+Vector2(0.016*sin(flow*PI),flow*0.12))
		canvas.draw_line(drop,drop+Vector2(0,2),Color("88efdc",0.85),1)
		effects.draw_light(canvas,p-Vector2(0,14),Vector2(width*1.3,38),Color("74deb3",0.3))
