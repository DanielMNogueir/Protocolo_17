class_name P17HydraulicEffects
extends RefCounted
## Moving water registered against the original atlas, drawn in the machine's depth slot.
const DEEP := Color("164d58")
const FLOW := Color("3a929d")
const LIGHT := Color("89d8d1")
const FOAM := Color("c1e8dc")

static func point(prop: Dictionary, atlas_point: Vector2) -> Vector2:
	return prop.visual_bounds.position+(atlas_point-prop.source.position)*prop.visual_bounds.size/prop.source.size

static func strength(online: bool) -> float:
	return 1.0 if online else 0.38

static func outlets(prop: Dictionary) -> Array[Dictionary]:
	# Only open downward-facing mouths; closed pipe elbows never emit water.
	var result: Array[Dictionary] = []
	var atlas_mouths: Array[Vector2] = []
	match prop.kind:
		"pump": atlas_mouths = [Vector2(904,651)]
		"tank": atlas_mouths = [Vector2(777,641)]
		"manifold", "battery": atlas_mouths = [Vector2(493,1140)]
		"purifier": atlas_mouths = [Vector2(882,1138)]
		_: return result
	var scale_value: float = prop.visual_bounds.size.x/prop.source.size.x
	for atlas_mouth in atlas_mouths:
		var mouth := point(prop,atlas_mouth)
		var landing := mouth+Vector2(2,clampf(scale_value*27,5,11))
		result.append({"mouth":mouth,"landing":landing,"width":clampf(scale_value*6,1.2,2.5)})
	return result

static func draw_ground(canvas: Node2D, prop: Dictionary) -> void:
	for outlet in outlets(prop):
		var p: Vector2 = outlet.landing
		canvas.draw_colored_polygon(PackedVector2Array([
			p+Vector2(-9,-1),p+Vector2(-5,-3),p+Vector2(5,-2),
			p+Vector2(10,1),p+Vector2(4,4),p+Vector2(-7,3)
		]),Color("1a454c",0.62))
		canvas.draw_line(p+Vector2(-4,2),p+Vector2(5,2),Color("598a89",0.32),1)

static func draw_machine(canvas: Node2D, prop: Dictionary, time: float, online: bool) -> void:
	var pressure := strength(online)
	if prop.kind == "clarifier":
		_draw_clarifier(canvas,prop,time,pressure)
	elif prop.kind == "tank":
		_draw_gauge(canvas,prop,Rect2(584,354,25,116),time,pressure,0)
		_draw_gauge(canvas,prop,Rect2(747,379,22,117),time,pressure,1)
	elif prop.kind in ["manifold","battery"]:
		for n in range(4):
			_draw_gauge(canvas,prop,Rect2(636+n*46,910-n*28,10,37),time,pressure,n)
	elif prop.kind == "purifier":
		# Flow through the three exposed treatment tubes, not across their steel frame.
		for n in range(3):
			var a := point(prop,Vector2(1020,1001+n*24))
			var b := point(prop,Vector2(1173,949+n*24))
			for glint in range(3):
				var phase := fposmod(time*(0.38+pressure*0.35)+glint/3.0+n*0.19,1.0)
				canvas.draw_line(a.lerp(b,phase),a.lerp(b,minf(phase+0.07,1)),Color(LIGHT,0.28+pressure*0.24),1)
	for outlet in outlets(prop):
		_draw_leak(canvas,outlet,time+prop.visual_bounds.position.x*0.013,pressure)

static func _draw_gauge(canvas: Node2D, prop: Dictionary, source: Rect2, time: float, pressure: float, seed: int) -> void:
	var r := Rect2(point(prop,source.position),source.size*prop.visual_bounds.size/prop.source.size)
	for bubble in range(3):
		var phase := fposmod(time*(0.31+pressure*0.42)+bubble/3.0+seed*0.23,1.0)
		var p := Vector2(r.get_center().x+sin(phase*TAU+seed)*r.size.x*0.22,r.end.y-phase*r.size.y)
		canvas.draw_rect(Rect2(p.round(),Vector2(1,2)),Color(FOAM,(0.20+pressure*0.36)*sin(phase*PI)))

static func _draw_leak(canvas: Node2D, outlet: Dictionary, time: float, pressure: float) -> void:
	var mouth: Vector2 = outlet.mouth
	var landing: Vector2 = outlet.landing
	var phase := fposmod(time*(0.90+pressure),1.0)
	if pressure>0.8:
		canvas.draw_line(mouth,landing,Color(FLOW,0.70),outlet.width)
		canvas.draw_line(mouth.lerp(landing,phase),mouth.lerp(landing,minf(phase+0.24,1)),Color(LIGHT,0.80),1)
	else:
		var p := mouth.lerp(landing,phase*phase)
		canvas.draw_rect(Rect2(p.round(),Vector2(1,2)),Color(LIGHT,0.70))
	draw_ripple(canvas,landing,Vector2(2+phase*7,1+phase*2),Color(LIGHT,(1-phase)*0.35))

static func _draw_clarifier(canvas: Node2D, prop: Dictionary, time: float, pressure: float) -> void:
	var scale_value: float = prop.visual_bounds.size.x/prop.source.size.x
	var origin := point(prop,Vector2(281,583))
	var end := point(prop,Vector2(299,657))
	var width := 23.0*scale_value
	draw_waterfall(canvas,origin,end,width,time,pressure)
	# Broken arcs hug clear water near the rim, away from the mixer and railings.
	var center := point(prop,Vector2(260,388))
	for ring in range(2):
		var phase := fposmod(time*(0.12+pressure*0.10)+ring*0.5,1.0)
		var radii := Vector2(145+phase*42,68+phase*15)*scale_value
		for arc_start in [0.65,2.65,3.65,5.60]:
			_draw_arc(canvas,center,radii,arc_start,arc_start+0.22,Color(LIGHT,(1-phase)*0.27))

static func draw_objective(canvas: Node2D, destination: Rect2, source: Rect2, index: int, time: float, online: bool) -> void:
	var prop := {"visual_bounds":destination,"source":source}
	if index == 2:
		for column in range(3):
			var gauge := Rect2(662+column*68,809+column*22,32,105) if online else Rect2(662+column*68,312+column*20,32,102)
			_draw_gauge(canvas,prop,gauge,time,strength(online),column)
	if not online: return
	var scale_value := destination.size.x/source.size.x
	if index == 0:
		draw_waterfall(canvas,point(prop,Vector2(155,992)),point(prop,Vector2(133,1035)),27*scale_value,time,1.0)
	elif index == 3:
		draw_waterfall(canvas,point(prop,Vector2(1000,857)),point(prop,Vector2(989,916)),18*scale_value,time,1.0)
		draw_waterfall(canvas,point(prop,Vector2(1186,892)),point(prop,Vector2(1195,952)),18*scale_value,time+0.31,1.0)

static func draw_waterfall(canvas: Node2D, origin: Vector2, end: Vector2, width: float, time: float, pressure: float) -> void:
	var cross := Vector2.RIGHT*width*0.5
	canvas.draw_colored_polygon(PackedVector2Array([origin-cross,origin+cross,end+cross*1.15,end-cross*1.15]),Color(DEEP,0.95))
	canvas.draw_colored_polygon(PackedVector2Array([origin-cross*0.72,origin+cross*0.75,end+cross*0.80,end-cross*0.85]),Color(FLOW,0.83))
	# Independently descending broken ribbons cover the previously painted waterfall.
	for ribbon in range(5):
		var fraction := (ribbon+0.5)/5.0-0.5
		var a := origin+Vector2(width*fraction,0)
		var b := end+Vector2(width*fraction*1.1,0)
		for streak in range(3):
			var phase := fposmod(time*(0.72+pressure*0.75+ribbon*0.08)+streak/3.0+ribbon*0.13,1.0)
			var top := a.lerp(b,phase).round()
			var bottom := a.lerp(b,minf(phase+0.10,1)).round()
			canvas.draw_colored_polygon(PackedVector2Array([top,top+Vector2.RIGHT,bottom+Vector2.RIGHT,bottom]),Color(FOAM,0.42+pressure*0.25))
	var seed := time*(0.75+pressure*0.35)
	for ring in range(3):
		var phase := fposmod(seed+ring/3.0,1.0)
		draw_ripple(canvas,end+Vector2(0,2),Vector2(width*0.6+phase*10,2+phase*3),Color(FOAM,(1-phase)*0.44))
	for drop in range(6):
		var phase := fposmod(seed+drop/6.0,1.0)
		var side := -1.0 if drop%2==0 else 1.0
		var p := end+Vector2(side*(width*0.2+phase*7),2-phase*(1-phase)*16)
		canvas.draw_rect(Rect2(p.round(),Vector2.ONE),Color(FOAM,(1-phase)*0.65))

static func draw_discharge(canvas: Node2D, mouth: Vector2, direction: Vector2, time: float, active: bool) -> void:
	var pressure := strength(active)
	var axis := direction.normalized()
	var across := Vector2(-axis.y,axis.x)
	var end := mouth+axis*(18+pressure*18)+Vector2(0,3)
	var width := 2+pressure*2
	canvas.draw_colored_polygon(PackedVector2Array([mouth-across*2,mouth+across*2,end+across*width,end-across*width]),Color(FLOW,0.68))
	for ribbon in range(3):
		var phase := fposmod(time*(0.65+pressure*0.70)+ribbon/3.0,1.0)
		var a := mouth.lerp(end,phase)+across*(ribbon-1)
		var b := mouth.lerp(end,minf(phase+0.15,1))+across*(ribbon-1)
		canvas.draw_line(a.round(),b.round(),Color(LIGHT,0.72),1)
	for ring in range(3):
		var phase := fposmod(time*0.65+ring/3.0,1.0)
		draw_ripple(canvas,end+axis*phase*7,Vector2(4+phase*12,2+phase*4),Color(FOAM,(1-phase)*0.36))
	for drop in range(4):
		var phase := fposmod(time*1.2+drop/4.0,1.0)
		var p := end+Vector2((drop-1.5)*phase*4,-sin(phase*PI)*4)
		canvas.draw_rect(Rect2(p.round(),Vector2.ONE),Color(FOAM,(1-phase)*0.55))

static func draw_ripple(canvas: Node2D, center: Vector2, radii: Vector2, color: Color) -> void:
	for start in [0.15,1.85,3.40,5.0]:
		_draw_arc(canvas,center,radii,start,start+0.65,color)

static func _draw_arc(canvas: Node2D, center: Vector2, radii: Vector2, start: float, end: float, color: Color) -> void:
	var vertices := PackedVector2Array()
	for step in range(6):
		var angle := lerpf(start,end,step/5.0)
		vertices.append((center+Vector2(cos(angle)*radii.x,sin(angle)*radii.y)).round())
	canvas.draw_polyline(vertices,color,1,false)
