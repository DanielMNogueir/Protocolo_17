class_name P17ObjectiveVisual
extends RefCounted
## Physical mission equipment, shared placement and readable service states.
const Art = preload("res://scripts/station_art.gd")
const Hydraulics = preload("res://scripts/hydraulic_effects.gd")
const TITLES := ["CAPTAÇÃO", "ENERGIA", "FILTRAGEM", "DISTRIBUIÇÃO"]
const SYSTEMS := ["BOMBA DE ADMISSÃO", "CONTROLE DA REDE", "NÚCLEO DOS FILTROS", "CENTRAL DE VAZÃO"]
const INK := Color("102630")
const STEEL := Color("587174")
const COPPER := Color("b79963")
const AMBER := Color("efb95b")
const CYAN := Color("80ebd0")
const FAULT := Color("e98187")

static func placement(goal: Vector2, index: int) -> Dictionary:
	if index == 1:
		var visual := Rect2(goal+Vector2(-22,-94),Vector2(44,82))
		var collision := Rect2(goal+Vector2(-12,-24),Vector2(24,8))
		return {"visual_bounds":visual,"collision_rect":collision,"depth_anchor":Vector2(goal.x,collision.end.y),"foot":Vector2(goal.x,collision.end.y)}
	var source: Rect2 = Art.TOTEM_CROPS[index]
	var width: float = [128.0,44.0,116.0,124.0][index]
	var foot := goal+Vector2(-[64.0,0.0,34.0,104.0][index],-30)
	var size := Vector2(width,width*source.size.y/source.size.x)
	var visual := Rect2(foot-Vector2(width*0.5,size.y),size)
	var collision := Rect2(visual.position+size*Vector2(0.15,0.80),size*Vector2(0.70,0.18))
	return {"visual_bounds":visual,"collision_rect":collision,"depth_anchor":Vector2(foot.x,collision.end.y),"foot":foot}

static func state_name(online: bool, available: bool, repair: float) -> String:
	if online: return "SISTEMA ATIVO"
	if repair>0: return "REPARANDO %02d%%" % roundi(repair*100)
	return "PRONTO PARA REPARO" if available else "SISTEMA AVARIADO"

static func state_color(online: bool, available: bool, repair: float) -> Color:
	if online: return CYAN
	return AMBER if available or repair>0 else FAULT

static func draw_foundation(canvas: Node2D, goal: Vector2, index: int, online: bool, time: float) -> void:
	var data := placement(goal,index)
	var base: Rect2 = data.collision_rect
	var deck := Rect2(Vector2(minf(base.position.x-8,goal.x-30),base.end.y+3),Vector2(maxf(base.end.x+8,goal.x+30)-minf(base.position.x-8,goal.x-30),goal.y+24-base.end.y-3))
	canvas.draw_rect(Rect2(deck.position+Vector2(3,4),deck.size),Color("0b2028",0.45))
	canvas.draw_rect(deck,Color("344d52"))
	canvas.draw_rect(deck.grow(-3),Color("1c333b"))
	var bars := PackedVector2Array()
	for x in range(int(deck.position.x)+7,int(deck.end.x)-4,6):
		bars.append(Vector2(x,deck.position.y+5))
		bars.append(Vector2(x,deck.end.y-5))
	canvas.draw_multiline(bars,Color("527174"),1)
	for y in [deck.position.y,deck.end.y-3]:
		canvas.draw_rect(Rect2(deck.position.x,y,deck.size.x,3),Color("75857a"))
		for x in range(int(deck.position.x)+4,int(deck.end.x)-5,16):
			canvas.draw_rect(Rect2(x,y,7,3),Color("b79963"))
	# The maintenance apron is walkable; its lights physically connect the machine
	# to the unchanged repair point rather than marking an unrelated empty circle.
	var contact := Vector2(data.depth_anchor.x,deck.get_center().y)
	var cable := PackedVector2Array([Vector2(data.foot.x,base.end.y+1),contact,Vector2(goal.x,contact.y)])
	canvas.draw_polyline(cable,Color("101f25"),6)
	canvas.draw_polyline(cable,Color("9c7951"),2)
	for n in range(3):
		var p := contact.lerp(Vector2(goal.x,contact.y),float(n+1)/4)
		canvas.draw_rect(Rect2(p-Vector2(2,1),Vector2(4,2)),CYAN if online else COPPER)
	if online:
		var p := contact.lerp(Vector2(goal.x,contact.y),fposmod(time*0.45,1))
		canvas.draw_rect(Rect2(p-Vector2(3,1),Vector2(6,2)),CYAN)
	canvas.draw_rect(Rect2(goal+Vector2(-19,-3),Vector2(38,24)),Color("2b4247",0.85))
	draw_icon(canvas,goal+Vector2(0,8),index,Color("a0b3a1"),0.65)

static func draw_body(canvas: Node2D, goal: Vector2, index: int, online: bool, time: float, available: bool = false, repair: float = 0.0) -> void:
	var data := placement(goal,index)
	var rect: Rect2 = data.visual_bounds
	var color := state_color(online,available,repair)
	if index == 1:
		_draw_energy_panel(canvas,rect,color,online,time,repair)
	else:
		var source: Rect2 = Art.TOTEM_CROPS[index+(4 if online else 0)]
		# Online/offline atlas silhouettes keep the same base anchor and width.
		var height := rect.size.x*source.size.y/source.size.x
		var destination := Rect2(data.foot-Vector2(rect.size.x/2,height),Vector2(rect.size.x,height))
		canvas.draw_texture_rect_region(Art.TOTEMS,destination,source)
		Hydraulics.draw_objective(canvas,destination,source,index,time,online)
	var lamp_position: Vector2 = [Vector2(0.87,0.42),Vector2(0.90,0.22),Vector2(0.93,0.67),Vector2(0.49,0.77)][index]
	var lamp_center := rect.position+rect.size*lamp_position
	var beacon := Rect2(lamp_center-Vector2(2,6),Vector2(4,12))
	canvas.draw_rect(beacon.grow(2),INK)
	canvas.draw_rect(beacon,color.darkened(0.40))
	var power := 0.65+sin(time*(4.0 if available else 2.0))*0.18
	for n in range(3):
		canvas.draw_rect(Rect2(beacon.position+Vector2(1,1+n*4),Vector2(2,3)),Color(color,power if not online else 1.0))
	if repair>0:
		canvas.draw_rect(Rect2(rect.position.x+4,rect.end.y-5,rect.size.x-8,3),INK)
		canvas.draw_rect(Rect2(rect.position.x+4,rect.end.y-5,(rect.size.x-8)*repair,3),AMBER)

static func _draw_energy_panel(canvas: Node2D, r: Rect2, color: Color, online: bool, time: float, repair: float) -> void:
	canvas.draw_rect(Rect2(r.position+Vector2(3,3),r.size),Color("0d252d"))
	canvas.draw_rect(r,Color("293e47"))
	canvas.draw_rect(Rect2(r.position+Vector2(0,0),Vector2(5,r.size.y)),Color("82928a"))
	canvas.draw_rect(Rect2(r.position+Vector2(5,4),r.size-Vector2(10,8)),STEEL)
	canvas.draw_rect(Rect2(r.position+Vector2(9,8),Vector2(26,24)),INK)
	canvas.draw_rect(Rect2(r.position+Vector2(11,10),Vector2(22,20)),Color(color,0.18))
	draw_icon(canvas,r.position+Vector2(22,20),1,color,0.70)
	for side in [8,32]:
		canvas.draw_rect(Rect2(r.position+Vector2(side,36),Vector2(3,26)),COPPER)
		for n in range(3):
			canvas.draw_rect(Rect2(r.position+Vector2(side-1,37+n*9),Vector2(5,4)),Color("1b313b"))
	canvas.draw_rect(Rect2(r.position+Vector2(14,36),Vector2(14,28)),Color("263d45"))
	for n in range(3):
		var y := r.position.y+39+n*8
		canvas.draw_rect(Rect2(r.position.x+17,y,8,4),Color("95aaa2"))
		canvas.draw_rect(Rect2(r.position.x+18+(3 if online else 0),y-1,3,6),color)
	canvas.draw_rect(Rect2(r.position+Vector2(6,67),Vector2(31,8)),Color("1a3037"))
	for n in range(6):
		var lit: bool = online or (repair>0 and float(n)/6<repair)
		canvas.draw_rect(Rect2(r.position+Vector2(8+n*5,69),Vector2(3,4)),CYAN if lit else color.darkened(0.35))
	for p in [r.position+Vector2(2,3),r.end-Vector2(4,4)]:
		canvas.draw_rect(Rect2(p,Vector2(2,2)),COPPER)
	if online:
		canvas.draw_rect(Rect2(r.position+Vector2(10+int(time*10)%22,29),Vector2(3,1)),CYAN)

static func draw_sign(canvas: Node2D, goal: Vector2, index: int, online: bool, available: bool, repair: float, time: float) -> void:
	var data := placement(goal,index)
	var bounds: Rect2 = data.visual_bounds
	var color := state_color(online,available,repair)
	var width := 166.0
	var sign := Rect2(bounds.get_center().x-width/2,bounds.position.y-48,width,40)
	# Small metal legs attach the sign to the equipment, not a floating UI card.
	for x in [sign.position.x+14,sign.end.x-14]:
		canvas.draw_rect(Rect2(x,sign.end.y,2,12),Color("738983"))
	canvas.draw_rect(Rect2(sign.position+Vector2(2,3),sign.size),Color("071d25",0.55))
	canvas.draw_rect(sign,Color("162e37"))
	canvas.draw_rect(sign,Color("73847b"),false,1)
	canvas.draw_rect(Rect2(sign.position,Vector2(3,sign.size.y)),color)
	draw_icon(canvas,sign.position+Vector2(19,16),index,color,0.80)
	canvas.draw_string(ThemeDB.fallback_font,sign.position+Vector2(35,16),"%02d / %s" % [index+1,TITLES[index]],HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("e2e9d8"))
	canvas.draw_string(ThemeDB.fallback_font,sign.position+Vector2(35,30),state_name(online,available,repair),HORIZONTAL_ALIGNMENT_LEFT,-1,8,color)
	if available and not online:
		var p := Vector2(goal.x,goal.y+29)
		canvas.draw_polyline(PackedVector2Array([p+Vector2(-5,3),p,p+Vector2(5,3)]),Color(AMBER,0.65+0.25*sin(time*3)),2)

static func draw_service_marker(canvas: Node2D, goal: Vector2, index: int, online: bool, available: bool, repair: float, time: float) -> void:
	var color := state_color(online,available,repair)
	if not available and not online: return
	var r := Rect2(goal+Vector2(-28,-8),Vector2(56,35))
	for corner in [r.position,Vector2(r.end.x,r.position.y),r.end,Vector2(r.position.x,r.end.y)]:
		var direction: Vector2 = (r.get_center()-corner).sign()
		canvas.draw_line(corner,corner+Vector2(direction.x*8,0),color,2)
		canvas.draw_line(corner,corner+Vector2(0,direction.y*6),color,2)
	if repair>0:
		canvas.draw_rect(Rect2(r.position.x,r.end.y+4,r.size.x,3),INK)
		canvas.draw_rect(Rect2(r.position.x,r.end.y+4,r.size.x*repair,3),AMBER)

static func draw_icon(canvas: Node2D, center: Vector2, index: int, color: Color, scale_value: float = 1.0) -> void:
	if index==0:
		var points := PackedVector2Array([Vector2(0,-9),Vector2(6,0),Vector2(5,5),Vector2(0,7),Vector2(-5,5),Vector2(-6,0),Vector2(0,-9)])
		for i in points.size(): points[i]=center+points[i]*scale_value
		canvas.draw_polyline(points,color,2)
	elif index==1:
		var points := PackedVector2Array([Vector2(2,-9),Vector2(-6,1),Vector2(0,1),Vector2(-2,9),Vector2(6,-2),Vector2(0,-2),Vector2(2,-9)])
		for i in points.size(): points[i]=center+points[i]*scale_value
		canvas.draw_colored_polygon(points,color)
	elif index==2:
		for n in range(3):
			var p := center+Vector2((n-1)*6,-7)*scale_value
			canvas.draw_rect(Rect2(p,Vector2(4,14)*scale_value),color,false,1)
	else:
		canvas.draw_circle(center,2*scale_value,color)
		for direction in [Vector2.UP,Vector2.LEFT,Vector2.RIGHT,Vector2.DOWN]:
			canvas.draw_line(center+direction*3*scale_value,center+direction*8*scale_value,color,2)
			canvas.draw_rect(Rect2(center+direction*9*scale_value-Vector2.ONE*2,Vector2(4,4)),color)
