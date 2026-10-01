class_name P17BridgeLayout
extends RefCounted
## New orthogonal bridge, built from actual geometry; no old atlas resampling.
## Ground modules and raised modules share a footprint for collision and Y sorting.
const EDGE := 34.0
const STEEL := Color("354b52")
const LIGHT := Color("738c8b")
const DARK := Color("142c34")
const BRASS := Color("a47b36")
const GOLD := Color("e3b65c")

static func deck(rect: Rect2) -> Rect2:
	if rect.size.y > rect.size.x:
		return Rect2(rect.position+Vector2(EDGE,-12),rect.size+Vector2(-EDGE*2,24))
	return Rect2(rect.position+Vector2(-12,EDGE),rect.size+Vector2(24,-EDGE*2))

static func collision_rects(rect: Rect2) -> Array[Rect2]:
	if rect.size.y > rect.size.x:
		return [Rect2(rect.position,Vector2(EDGE,rect.size.y)),Rect2(rect.position+Vector2(rect.size.x-EDGE,0),Vector2(EDGE,rect.size.y))]
	return [Rect2(rect.position,Vector2(rect.size.x,EDGE)),Rect2(rect.position+Vector2(0,rect.size.y-EDGE),Vector2(rect.size.x,EDGE))]

static func draw_deck(canvas: Node2D, rect: Rect2) -> void:
	_draw_grating(canvas,deck(rect),rect.size.y>rect.size.x)

static func _draw_grating(canvas: Node2D, d: Rect2, vertical: bool) -> void:
	canvas.draw_rect(Rect2(d.position+Vector2(5,7),d.size),Color("071b23",0.50))
	canvas.draw_rect(d,DARK)
	canvas.draw_rect(d.grow(-2),Color("273f48"))
	# Square openings and tiny bevels remain the same pixel size in both directions.
	for y in range(int(d.position.y)+3,int(d.end.y)-3,5):
		for x in range(int(d.position.x)+3,int(d.end.x)-3,5):
			canvas.draw_rect(Rect2(x,y,3,3),Color("0c252f"))
			canvas.draw_rect(Rect2(x,y,3,1),Color("526971"))
			if posmod(x/5+y/5,13)==0:
				canvas.draw_rect(Rect2(x+3,y+2,1,2),Color("80634b"))
	var length := d.size.y if vertical else d.size.x
	for offset in range(0,int(length),48):
		var p := d.position+(Vector2(0,offset) if vertical else Vector2(offset,0))
		var seam := Rect2(p,Vector2(d.size.x,4) if vertical else Vector2(4,d.size.y))
		canvas.draw_rect(seam,Color("203239"))
		canvas.draw_rect(Rect2(p,Vector2(d.size.x,1) if vertical else Vector2(1,d.size.y)),LIGHT)
		_bolt(canvas,p+Vector2(2,1))
		_bolt(canvas,p+(Vector2(d.size.x-5,1) if vertical else Vector2(1,d.size.y-5)))
	# Thresholds extend twelve pixels onto each existing bank, without closing it.
	var ends: Array[Rect2]
	if vertical:
		ends=[Rect2(d.position,Vector2(d.size.x,12)),Rect2(d.position.x,d.end.y-12,d.size.x,12)]
	else:
		ends=[Rect2(d.position,Vector2(12,d.size.y)),Rect2(d.end.x-12,d.position.y,12,d.size.y)]
	for r in ends:
		canvas.draw_rect(r,Color("34454a"))
		canvas.draw_rect(r.grow(-2),Color("7e8270"))
		canvas.draw_line(r.position+Vector2(2,2),Vector2(r.end.x-2,r.position.y+2),Color("c3b78f"),1)
		for p in [r.position+Vector2(3,4),r.end-Vector2(6,6)]: _bolt(canvas,p)
	# Painted edge stripes orient the walking lane rather than crossing it.
	if vertical:
		for x in [d.position.x+1,d.end.x-3]:
			for y in range(int(d.position.y)+14,int(d.end.y)-13,14): canvas.draw_rect(Rect2(x,y,2,7),BRASS)
	else:
		for y in [d.position.y+1,d.end.y-3]:
			for x in range(int(d.position.x)+14,int(d.end.x)-13,14): canvas.draw_rect(Rect2(x,y,7,2),BRASS)

static func parts(rect: Rect2) -> Array[Dictionary]:
	var result: Array[Dictionary]=[]
	var vertical := rect.size.y>rect.size.x
	for side in collision_rects(rect):
		var length := side.size.y if vertical else side.size.x
		for offset in range(0,int(length),36):
			var extent := minf(36,length-offset)
			var base := Rect2(side.position+(Vector2(0,offset) if vertical else Vector2(offset,0)),Vector2(side.size.x,extent) if vertical else Vector2(extent,side.size.y))
			result.append({"type":"bridge_part","rect":base,"y":base.end.y,"support":false,"vertical":vertical})
		# Every pier has its own complete shape and stays inside the blocked shoulder.
		var feet: Array[Vector2]
		if vertical:
			feet=[Vector2(side.get_center().x,rect.position.y+14),Vector2(side.get_center().x,rect.end.y-2)]
		else:
			feet=[Vector2(rect.position.x+17,side.end.y-2),Vector2(rect.end.x-17,side.end.y-2)]
		for foot in feet: result.append({"type":"bridge_part","rect":Rect2(foot-Vector2(13,58),Vector2(26,58)),"y":foot.y,"support":true})
	return result

static func draw_part(canvas: Node2D, part: Dictionary) -> void:
	var r: Rect2=part.rect
	if part.support:
		_draw_pillar(canvas,r)
		return
	# The solid shoulder contains a steel box girder and guarded service conduit.
	canvas.draw_rect(r,Color("142b34"))
	canvas.draw_rect(r.grow(-2),STEEL)
	canvas.draw_line(r.position+Vector2(2,2),Vector2(r.end.x-2,r.position.y+2),LIGHT,1)
	if part.vertical:
		var x := r.get_center().x-8
		canvas.draw_rect(Rect2(x,r.position.y,16,r.size.y),Color("233b46"))
		canvas.draw_rect(Rect2(x+1,r.position.y,2,r.size.y),Color("698184"))
		canvas.draw_rect(Rect2(x+13,r.position.y,2,r.size.y),Color("091f2a"))
		# Raised handrail projection is vertical; the deck has no baked perspective.
		canvas.draw_rect(Rect2(x+5,r.position.y-17,5,r.size.y),Color("473e2e"))
		canvas.draw_rect(Rect2(x+5,r.position.y-17,2,r.size.y),GOLD)
		canvas.draw_rect(Rect2(x+7,r.position.y-17,1,r.size.y),BRASS)
		_draw_post(canvas,Vector2(x+7,r.position.y+5),18)
		canvas.draw_rect(Rect2(r.position.x+1,r.position.y+8,r.size.x-2,5),Color("5c6b67"))
		_bolt(canvas,Vector2(r.position.x+2,r.position.y+9))
		_bolt(canvas,Vector2(r.end.x-5,r.position.y+9))
	else:
		var y := r.position.y+19
		canvas.draw_rect(Rect2(r.position.x,y, r.size.x,8),Color("1c333d"))
		canvas.draw_rect(Rect2(r.position.x,y, r.size.x,2),Color("71847c"))
		canvas.draw_rect(Rect2(r.position.x,y-17,r.size.x,4),Color("5b4328"))
		canvas.draw_rect(Rect2(r.position.x,y-17,r.size.x,1),GOLD)
		canvas.draw_rect(Rect2(r.position.x,y-15,r.size.x,1),BRASS)
		_draw_post(canvas,Vector2(r.position.x+5,y+3),22)
		_bolt(canvas,Vector2(r.position.x+3,r.end.y-5))
		_bolt(canvas,Vector2(r.end.x-6,r.end.y-5))
	# Fixed chips, fasteners and moss occur on the structure, never in the lane.
	var seed := posmod(int(r.position.x+r.position.y),7)
	canvas.draw_rect(Rect2(r.position+Vector2(4+seed,4),Vector2(4,2)),Color("9b7044"))
	if seed<2:
		canvas.draw_rect(Rect2(r.end-Vector2(9,4),Vector2(5,2)),Color("596b33"))

static func _draw_pillar(canvas: Node2D, r: Rect2) -> void:
	var x := r.position.x
	var y := r.end.y
	canvas.draw_rect(Rect2(x-1,y-5,r.size.x+3,7),Color("071c23",0.48))
	# Concrete shoe, bevelled edges and anchor bolts.
	canvas.draw_rect(Rect2(x,y-12,r.size.x,12),Color("414c45"))
	canvas.draw_rect(Rect2(x+1,y-12,r.size.x-3,7),Color("95907a"))
	canvas.draw_rect(Rect2(x+3,y-11,r.size.x-7,2),Color("c0b593"))
	canvas.draw_rect(Rect2(x+2,y-3,r.size.x-5,2),Color("646e50"))
	for bx in [x+3,x+r.size.x-6]: _bolt(canvas,Vector2(bx,y-8))
	var c := x+r.size.x*0.5
	var ring := minf(10,r.size.x*0.5-1)
	var shaft := ring-2
	canvas.draw_rect(Rect2(c-shaft,r.position.y+6,shaft*2,r.size.y-17),Color("132c37"))
	canvas.draw_rect(Rect2(c-shaft+2,r.position.y+7,shaft*2-4,r.size.y-18),Color("285265"))
	canvas.draw_rect(Rect2(c-shaft+3,r.position.y+8,1,r.size.y-20),Color("589497"))
	canvas.draw_rect(Rect2(c+shaft-5,r.position.y+10,1,r.size.y-24),Color("183b49"))
	for by in [r.position.y+7,y-18]:
		canvas.draw_rect(Rect2(c-ring,by,ring*2,6),Color("4b422c"))
		canvas.draw_rect(Rect2(c-ring+1,by,ring*2-2,2),GOLD)
		canvas.draw_rect(Rect2(c-ring+2,by+4,ring*2-4,1),BRASS)
		_bolt(canvas,Vector2(c-1,by+2))
	canvas.draw_rect(Rect2(c-ring+1,r.position.y+1,ring*2-2,6),Color("61553b"))
	canvas.draw_rect(Rect2(c-ring+3,r.position.y,ring*2-6,3),Color("b19658"))
	canvas.draw_rect(Rect2(c-4,r.position.y+1,5,1),Color("e7c77f"))
	canvas.draw_rect(Rect2(c-5,y-31,9,4),Color("122c34"))
	canvas.draw_rect(Rect2(c-3,y-30,5,2),Color("68cbbb"))
	canvas.draw_rect(Rect2(x+3,y-3,5,2),Color("5d7539"))

static func _draw_post(canvas: Node2D, foot: Vector2, height: float) -> void:
	canvas.draw_rect(Rect2(foot-Vector2(3,height),Vector2(6,height)),Color("665333"))
	canvas.draw_rect(Rect2(foot-Vector2(2,height),Vector2(2,height-2)),Color("c7a153"))
	canvas.draw_rect(Rect2(foot-Vector2(4,height),Vector2(8,3)),GOLD)
	canvas.draw_rect(Rect2(foot-Vector2(5,2),Vector2(10,3)),Color("465957"))

static func _bolt(canvas: Node2D, p: Vector2) -> void:
	canvas.draw_rect(Rect2(p,Vector2(3,3)),Color("23383a"))
	canvas.draw_rect(Rect2(p,Vector2(2,1)),Color("d5cba8"))
	canvas.draw_rect(Rect2(p+Vector2(1,1),Vector2(1,1)),Color("8c8a70"))

static func draw_pier_deck(canvas: Node2D, rect: Rect2) -> void:
	_draw_grating(canvas,Rect2(rect.position+Vector2(16,-8),rect.size+Vector2(-32,8)),true)

static func pier_parts(rect: Rect2) -> Array[Dictionary]:
	var result: Array[Dictionary]=[]
	for x in [rect.position.x,rect.end.x-16]:
		for y in range(int(rect.position.y),int(rect.end.y),30):
			var r := Rect2(x,y,16,minf(30,rect.end.y-y))
			result.append({"type":"bridge_part","rect":r,"y":r.end.y,"support":false,"vertical":true})
		for y in [rect.position.y+12,rect.end.y-2]:
			result.append({"type":"bridge_part","rect":Rect2(x+1,y-48,14,48),"y":y,"support":true})
	return result
