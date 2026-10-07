extends RefCounted
## A small, enclosed research room: wall volumes, service bays and a central work aisle.
const FLOOR := Rect2(45,170,870,380)

static func floor(canvas: Node2D, view: Rect2) -> void:
	canvas.draw_rect(FLOOR,Color("20313d"))
	for y in range(170,550,40):
		for x in range(45,915,58):
			var r := Rect2(x,y,minf(58,915-x),minf(40,550-y)).grow(-0.5)
			if not r.intersects(view): continue
			var seed := posmod(x*17+y*31,17)
			var tint := Color("657780") if seed%4==0 else Color("596b77")
			canvas.draw_rect(r,tint)
			canvas.draw_line(r.position+Vector2(1,1),r.position+Vector2(r.size.x-1,1),Color("b0c3c3",0.35),1)
			canvas.draw_line(r.position+Vector2(1,2),r.position+Vector2(1,r.size.y-1),Color("9dafb4",0.24),1)
			canvas.draw_line(r.position+Vector2(2,r.size.y-1),r.end-Vector2(1,1),Color("253747",0.8),1)
			if seed%3==0: canvas.draw_line(r.position+Vector2(9,29),r.position+Vector2(19,29),Color("b5c5be",0.13),1)
	# Flush service mats, directly beneath their workstations.
	for r in [Rect2(92,370,125,105),Rect2(299,365,130,95),Rect2(424,258,120,99),Rect2(643,430,137,98)]:
		canvas.draw_rect(r,Color("344b56",0.75))
		canvas.draw_rect(r.grow(-3),Color("8caaa8",0.35),false,1)
	# A shared grated cable trench and the core's protected footprint.
	_grate(canvas,Rect2(465,350,23,98))
	_grate(canvas,Rect2(260,463,132,15))
	var core_pad := PackedVector2Array([Vector2(532,287),Vector2(620,253),Vector2(707,287),Vector2(707,338),Vector2(620,370),Vector2(532,338)])
	canvas.draw_colored_polygon(core_pad,Color("293c49"))
	core_pad.append(core_pad[0])
	canvas.draw_polyline(core_pad,Color("ad9967"),2)
	for n in range(6):
		var p := Vector2(542+n*14,345+n*0.6)
		canvas.draw_line(p,p+Vector2(5,4),Color("d3b573"),2)
	for path in [PackedVector2Array([Vector2(360,395),Vector2(360,425),Vector2(595,425),Vector2(595,400)]),PackedVector2Array([Vector2(150,410),Vector2(150,485),Vector2(575,485),Vector2(575,500),Vector2(710,500),Vector2(710,465)])]:
		canvas.draw_polyline(path,Color("162631"),5)
		canvas.draw_polyline(path,Color("73858a"),1)
	for x in [304,326,348]:
		canvas.draw_line(Vector2(x,505),Vector2(x+7,510),Color("bfd1c0",0.3),1)

static func _grate(canvas: Node2D, r: Rect2) -> void:
	canvas.draw_rect(r.grow(2),Color("293a45"))
	canvas.draw_rect(r,Color("142832"))
	if r.size.y>r.size.x:
		for y in range(int(r.position.y)+2,int(r.end.y)-1,5): canvas.draw_line(Vector2(r.position.x+3,y),Vector2(r.end.x-3,y),Color("859692"),1)
	else:
		for x in range(int(r.position.x)+2,int(r.end.x)-1,5): canvas.draw_line(Vector2(x,r.position.y+3),Vector2(x,r.end.y-3),Color("859692"),1)
	canvas.draw_rect(r,Color("a3b5ab",0.6),false,1)

static func walls(canvas: Node2D, alarm: bool, time: float, effects: P17LaboratoryEffects) -> void:
	var light := Color("eb6577") if alarm else Color("85e5d6")
	# Rear wall is a visible vertical face with a roof cap and an inset plinth.
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(28,45),Vector2(907,45),Vector2(932,64),Vector2(45,64)]),Color("61737d"))
	canvas.draw_rect(Rect2(45,64,870,106),Color("314454"))
	for x in range(145,795,106):
		var r := Rect2(x,73,99,82)
		canvas.draw_rect(r,Color("647680"))
		canvas.draw_line(r.position,r.position+Vector2(98,0),Color("bdcecb"),2)
		canvas.draw_rect(Rect2(r.position+Vector2(7,9),Vector2(85,55)),Color("526570"))
		canvas.draw_rect(Rect2(r.position+Vector2(12,13),Vector2(74,1)),Color("91a5ad",0.5))
		canvas.draw_rect(Rect2(r.position+Vector2(12,68),Vector2(72,3)),light)
		for side in [0,1]: canvas.draw_rect(Rect2(r.position+Vector2(5+side*86,73),Vector2(3,3)),Color("cccfb7"))
	# Inspection window and ventilation built into the wall, rather than floor props.
	canvas.draw_rect(Rect2(426,79,154,63),Color("152d3c"))
	if effects: effects.draw_glass(canvas,Rect2(432,85,142,51))
	canvas.draw_rect(Rect2(426,79,154,63),Color("9cb7b9"),false,2)
	for n in range(5): canvas.draw_line(Vector2(290,97+n*7),Vector2(327,97+n*7),Color("263e4b"),2)
	for x in [63,811]: _door(canvas,Vector2(x,70),light,alarm)
	canvas.draw_rect(Rect2(45,155,870,8),Color("243744"))
	canvas.draw_rect(Rect2(45,163,870,7),Color("a7b4ad"))
	canvas.draw_line(Vector2(46,158),Vector2(914,158),Color("839ca2"),1)
	# Left and right wall thickness; the foreground rim stays below the play area.
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(28,45),Vector2(45,64),Vector2(45,550),Vector2(28,532)]),Color("435966"))
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(915,64),Vector2(932,45),Vector2(932,532),Vector2(915,550)]),Color("314854"))
	for x in [34,918]:
		for y in [270,415]:
			canvas.draw_rect(Rect2(x,y,8,61),Color("182c3a"))
			canvas.draw_rect(Rect2(x+2,y+5,3,48),light)
			if effects: effects.draw_light(canvas,Vector2(x+4,y+30),Vector2(145,123),Color(light,0.55))
	canvas.draw_rect(Rect2(45,550,870,8),Color("a8b8b2"))
	canvas.draw_rect(Rect2(45,558,870,13),Color("2b424f"))
	for x in range(54,905,75): canvas.draw_rect(Rect2(x,562,26,2),Color("6b8990"))
	# Ceiling lights cast a gentle warm key light; red lamps belong to the alarm.
	if effects:
		effects.draw_light(canvas,Vector2(425,235),Vector2(620,470),Color("d9deca",0.50))
		for x in [88,850]:
			var p := Vector2(x+24,82)
			canvas.draw_rect(Rect2(p-Vector2(5,3),Vector2(10,6)),light)
			effects.draw_light(canvas,p+Vector2(0,45),Vector2(175,150),Color(light,0.65 if not alarm else 0.8+sin(time*2.4)*0.15))
	var font := ThemeDB.fallback_font
	canvas.draw_string(font,Vector2(652,150),"PESQUISA AMBIENTAL",HORIZONTAL_ALIGNMENT_LEFT,-1,7,Color("ccdcd5"))

static func _door(canvas: Node2D, origin: Vector2, light: Color, alarm: bool) -> void:
	canvas.draw_rect(Rect2(origin-Vector2(5,5),Vector2(92,102)),Color("182c3b"))
	canvas.draw_rect(Rect2(origin,Vector2(80,95)),Color("86969b"))
	for n in range(2):
		var r := Rect2(origin+Vector2(5+n*36,5),Vector2(34,84))
		canvas.draw_rect(r,Color("415665"))
		canvas.draw_rect(r.grow(-3),Color("576c77"))
		canvas.draw_rect(Rect2(r.position+Vector2(7,7),Vector2(19,42)),Color("233f4b"))
		canvas.draw_line(r.position+Vector2(8,8),r.position+Vector2(21,23),Color("88b8bf",0.5),1)
		canvas.draw_rect(Rect2(r.position+Vector2(24 if n==0 else 5,57),Vector2(3,11)),Color("c2b384"))
	canvas.draw_rect(Rect2(origin+Vector2(8,-9),Vector2(64,3)),light)
	canvas.draw_rect(Rect2(origin+Vector2(82,44),Vector2(8,20)),Color("162c39"))
	canvas.draw_rect(Rect2(origin+Vector2(84,47),Vector2(4,9)),Color("e57b7c") if alarm else light)
