class_name P17World
extends RefCounted
## Original district geometry, collision and procedural pixel scenery.
## All public coordinates are world coordinates; stage is zero based.

const SIZE := Vector2(2560, 1800)
const REGIONS: Array[Rect2] = [
	Rect2(100, 1020, 1010, 660), Rect2(100, 100, 1010, 740),
	Rect2(1450, 100, 1010, 740), Rect2(1450, 1020, 1010, 660),
]
const NAMES := ["CAIS DAS BOMBAS", "PÁTIO SOLAR", "GALERIA DOS FILTROS", "DISTRIBUIÇÃO AURORA"]
const START := Vector2(440, 1570)
const GOALS: Array[Vector2] = [Vector2(870,1190), Vector2(850,320), Vector2(2210,600), Vector2(2110,1430)]
const CHECKPOINTS: Array[Vector2] = [START, Vector2(770,760), Vector2(1530,610), Vector2(2040,1100)]
const SPAWNS := [
	[Vector2(740,1360),Vector2(955,1260),Vector2(510,1450)],
	[Vector2(560,610),Vector2(920,455),Vector2(740,310),Vector2(410,670)],
	[Vector2(1620,590),Vector2(1910,460),Vector2(2200,720),Vector2(2310,540),Vector2(2050,540)],
	[Vector2(1890,1140),Vector2(2220,1210),Vector2(2260,1510),Vector2(1890,1510),Vector2(2110,1370)],
]
const BRIDGES: Array[Rect2] = [Rect2(690,840,160,180),Rect2(1110,530,340,160),Rect2(1960,840,160,180)]
const GATES: Array[Rect2] = [Rect2(682,919,176,22),Rect2(1269,522,22,176),Rect2(1952,919,176,22)]
const PIER := Rect2(370,1680,140,90)
const ROUTES := [
	[START,Vector2(690,1570),Vector2(690,1190),GOALS[0]],
	[GOALS[0],Vector2(870,1070),Vector2(770,1070),Vector2(770,730),Vector2(850,730),GOALS[1]],
	[GOALS[1],Vector2(850,610),Vector2(1530,610),Vector2(2110,610),GOALS[2]],
	[GOALS[2],Vector2(2040,600),Vector2(2040,1110),Vector2(2110,1110),GOALS[3]],
]
const BASINS: Array[Rect2] = [Rect2(210,1180,260,180),Rect2(1550,670,300,120),Rect2(1630,1240,190,250)]
const BUILDINGS: Array[Rect2] = [Rect2(230,220,350,230),Rect2(1550,180,430,220),Rect2(1510,1060,280,130)]
static var _solid_cache: Array[Rect2] = []
static var _props_cache: Array[Dictionary] = []

static func _land_at(point: Vector2) -> bool:
	for region in REGIONS:
		if region.has_point(point):
			return true
	for bridge in BRIDGES:
		if bridge.has_point(point):
			return true
	return PIER.has_point(point)

static func props() -> Array[Dictionary]:
	if not _props_cache.is_empty():
		return _props_cache
	# Positions describe ground footprints, with ornamental tops inside that footprint.
	var items := [
		["tank",Rect2(210,1060,100,96)],["tank",Rect2(335,1060,100,96)],
		["pump",Rect2(495,1230,76,80)],["cabinet",Rect2(960,1450,55,72)],
		["crate",Rect2(210,1510,46,40)],["crate",Rect2(258,1530,42,38)],
		["barrel",Rect2(330,1480,28,34)],["barrel",Rect2(361,1485,28,34)],
		["tank",Rect2(960,1050,74,94)],["cabinet",Rect2(160,1090,32,55)],
		["battery",Rect2(660,200,46,70)],["battery",Rect2(720,200,46,70)],
		["cabinet",Rect2(955,220,45,68)],["crate",Rect2(215,595,44,40)],
		["barrel",Rect2(273,625,28,34)],["barrel",Rect2(306,625,28,34)],
		["solar",Rect2(250,495,190,66)],["solar",Rect2(450,495,190,66)],
		["tank",Rect2(2080,190,120,150)],["tank",Rect2(2240,190,120,150)],
		["pump",Rect2(2100,370,72,80)],["cabinet",Rect2(2300,380,44,66)],
		["crate",Rect2(1510,465,48,42)],["barrel",Rect2(1570,465,30,36)],
		["tank",Rect2(1510,1310,80,100)],["cabinet",Rect2(2335,1120,45,70)],
		["solar",Rect2(2280,1350,115,60)],["crate",Rect2(1530,1570,50,44)],
		["barrel",Rect2(1600,1580,28,34)],["pump",Rect2(1880,1550,65,70)],
	]
	for item in items:
		var rect: Rect2 = item[1]
		_props_cache.append({"kind":item[0],"pos":rect.get_center(),"rect":rect,"solid":true})
	for region_index in range(REGIONS.size()):
		var region: Rect2 = REGIONS[region_index]
		for i in range(27):
			var x := region.position.x + 35 + posmod(i*131 + region_index*41, 930)
			var y := region.position.y + 20 if i%2==0 else region.end.y-31
			if (region_index <= 1 and x>665 and x<870) or (region_index>=2 and x>1935 and x<2140):
				continue
			_props_cache.append({"kind":"fern","pos":Vector2(x,y),"rect":Rect2(x-15,y-16,30,24),"solid":false})
	for point in [Vector2(570,1500),Vector2(610,1120),Vector2(200,690),Vector2(1015,650),Vector2(1860,440),Vector2(2360,650),Vector2(1980,1530),Vector2(2200,1580)]:
		_props_cache.append({"kind":"fern","pos":point,"rect":Rect2(point-Vector2(15,16),Vector2(30,24)),"solid":false})
	return _props_cache

static func _build_solids() -> void:
	if not _solid_cache.is_empty():
		return
	# Exact rectangle partition of the land union: no raster gaps on the banks.
	var xs: Array[float] = [0.0,SIZE.x]
	var ys: Array[float] = [0.0,SIZE.y]
	var land: Array[Rect2] = []
	land.append_array(REGIONS)
	land.append_array(BRIDGES)
	land.append(PIER)
	for rect in land:
		for x in [rect.position.x,rect.end.x]:
			if not xs.has(x): xs.append(x)
		for y in [rect.position.y,rect.end.y]:
			if not ys.has(y): ys.append(y)
	xs.sort()
	ys.sort()
	for yi in range(ys.size()-1):
		var row_start := -1.0
		for xi in range(xs.size()-1):
			var center := Vector2((xs[xi]+xs[xi+1])*0.5,(ys[yi]+ys[yi+1])*0.5)
			if not _land_at(center):
				if row_start<0: row_start=xs[xi]
			elif row_start>=0:
				_solid_cache.append(Rect2(row_start,ys[yi],xs[xi]-row_start,ys[yi+1]-ys[yi]))
				row_start=-1
		if row_start>=0:
			_solid_cache.append(Rect2(row_start,ys[yi],SIZE.x-row_start,ys[yi+1]-ys[yi]))
	_solid_cache.append_array(BASINS)
	_solid_cache.append_array(BUILDINGS)
	for prop in props():
		if prop["solid"]: _solid_cache.append(prop["rect"])

static func solids(stage: int) -> Array[Rect2]:
	_build_solids()
	var result: Array[Rect2] = _solid_cache.duplicate()
	for i in range(GATES.size()):
		if stage<=i: result.append(GATES[i])
	# Also seal the space beyond the rendered district.
	result.append(Rect2(-100,-100,SIZE.x+200,100))
	result.append(Rect2(-100,SIZE.y,SIZE.x+200,100))
	result.append(Rect2(-100,0,100,SIZE.y))
	result.append(Rect2(SIZE.x,0,100,SIZE.y))
	return result

static func walkable(point: Vector2, radius: float, stage: int) -> bool:
	if point.x<radius or point.y<radius or point.x>SIZE.x-radius or point.y>SIZE.y-radius:
		return false
	_build_solids()
	for rect in _solid_cache:
		if _circle_hits_rect(point,radius,rect): return false
	for i in range(GATES.size()):
		if stage<=i and _circle_hits_rect(point,radius,GATES[i]): return false
	return true

static func _circle_hits_rect(point: Vector2, radius: float, rect: Rect2) -> bool:
	var near := point.clamp(rect.position,rect.end)
	return rect.has_point(point) or point.distance_squared_to(near)<radius*radius

static func _pixel(canvas: Node2D, rect: Rect2, color: Color) -> void:
	canvas.draw_rect(rect,color)

static func _visible(rect: Rect2, view: Rect2) -> bool:
	return rect.grow(35).intersects(view)

static func _hash(x: int, y: int) -> int:
	return posmod(x*73+y*157+x*y*13,997)

static func draw(canvas: Node2D, camera_pos: Vector2, stage: int, restored: int, time: float) -> void:
	var view := Rect2(camera_pos-Vector2(770,490),Vector2(1540,980))
	_pixel(canvas,Rect2(Vector2.ZERO,SIZE),Color("102d37"))
	_draw_water(canvas,view,restored,time)
	for i in range(REGIONS.size()):
		if _visible(REGIONS[i],view):
			_draw_region(canvas,REGIONS[i],i,view,restored)
	for bridge in BRIDGES:
		if _visible(bridge,view): _draw_bridge(canvas,bridge,false)
	if _visible(PIER,view): _draw_bridge(canvas,PIER,true)
	_draw_utilities(canvas,view,restored,time)
	for i in range(BASINS.size()):
		if _visible(BASINS[i],view): _draw_basin(canvas,BASINS[i],i,restored,time)
	for i in range(BUILDINGS.size()):
		if _visible(BUILDINGS[i],view): _draw_building(canvas,BUILDINGS[i],i,restored)
	for prop in props():
		if _visible(prop["rect"],view): _draw_prop(canvas,prop,restored,time)
	for i in range(GOALS.size()):
		if view.grow(90).has_point(GOALS[i]): _draw_goal_pad(canvas,GOALS[i],i,i<restored,time)
	for i in range(GATES.size()):
		if _visible(GATES[i],view): _draw_gate(canvas,GATES[i],i<stage,time)
	_draw_route(canvas,stage,view,time)

static func _draw_water(canvas: Node2D, view: Rect2, restored: int, time: float) -> void:
	var clean := restored>=3
	_pixel(canvas,Rect2(0,0,1280,SIZE.y),Color("201e30") if not clean else Color("0c2a34"))
	_pixel(canvas,Rect2(1280,0,1280,SIZE.y),Color("0b2934"))
	var extent := view.intersection(Rect2(Vector2.ZERO,SIZE))
	for y in range(int(extent.position.y/56)*56,int(extent.end.y)+56,56):
		for x in range(int(extent.position.x/80)*80,int(extent.end.x)+80,80):
			if _land_at(Vector2(x+40,y+28)): continue
			var seed := _hash(x/80,y/56)
			var purple := x<1280 and not clean
			var drift := int(sin(time*0.6+seed)*6)
			var tint := Color("543348") if purple else Color("1b4852")
			var p := Vector2(x+12+seed%29+drift,y+9+seed%26)
			# Disconnected reflections describe flow without exposing the sampling grid.
			_pixel(canvas,Rect2(p,Vector2(17+seed%28,2)),tint)
			_pixel(canvas,Rect2(p+Vector2(-7,4),Vector2(14+seed%12,2)),tint.darkened(0.2))
			if seed%3==0:
				_pixel(canvas,Rect2(p+Vector2(9,-4),Vector2(7,1)),Color("84536b") if purple else Color("397680"))
			if seed%7==0:
				_pixel(canvas,Rect2(p+Vector2(-9,14),Vector2(25,3)),Color("382b3e") if purple else Color("103941"))
				_pixel(canvas,Rect2(p+Vector2(-2,17),Vector2(34,3)),Color("382b3e") if purple else Color("103941"))

static func _draw_region(canvas: Node2D, rect: Rect2, index: int, view: Rect2, restored: int) -> void:
	_pixel(canvas,Rect2(rect.position+Vector2(13,19),rect.size),Color("071923"))
	_pixel(canvas,rect.grow(9),Color("0a2029"))
	_pixel(canvas,rect,Color("142e35"))
	var area := rect.intersection(view)
	for y in range(int((area.position.y-rect.position.y)/40)*40+int(rect.position.y),int(area.end.y),40):
		for x in range(int((area.position.x-rect.position.x)/40)*40+int(rect.position.x),int(area.end.x),40):
			var seed := _hash(x/40,y/40)
			var tile := Rect2(x+1,y+1,minf(38,rect.end.x-x-1),minf(38,rect.end.y-y-1))
			var color := Color("213c43") if index!=1 else Color("263e3e")
			_pixel(canvas,tile,color.lightened(float(seed%6)*0.004))
			if seed%3!=0:
				_pixel(canvas,Rect2(x+3,y+2,tile.size.x-4,1),Color("355056"))
			if seed%5==0:
				var crack := Color("152d36")
				_pixel(canvas,Rect2(x+7,y+14,12,2),crack)
				_pixel(canvas,Rect2(x+17,y+16,2,6),crack)
				_pixel(canvas,Rect2(x+18,y+21,8,2),crack)
				_pixel(canvas,Rect2(x+24,y+22,2,9),crack)
				_pixel(canvas,Rect2(x+20,y+24,3,1),Color("425c59"))
			if seed%11==0:
				_draw_stain(canvas,Vector2(x+10,y+20),seed,index==1)
			elif seed%9==0:
				_pixel(canvas,Rect2(x+10,y+12,17,2),Color("2c474c"))
				_pixel(canvas,Rect2(x+7,y+15,23,4),Color("1b353d"))
				_pixel(canvas,Rect2(x+16,y+19,14,3),Color("1b353d"))
			if seed%17==0:
				for n in range(4):
					_pixel(canvas,Rect2(x+5+(n*11)%27,y+8+(n*7)%25,2,1),Color("546561"))
	# Low concrete coping; visual gaps coincide with every bridge mouth.
	for x in range(int(rect.position.x),int(rect.end.x),32):
		for y in [rect.position.y,rect.end.y-8]:
			if _bridge_mouth(Vector2(x+16,y+4),index): continue
			_pixel(canvas,Rect2(x,y,minf(30,rect.end.x-x),8),Color("4d6561"))
			_pixel(canvas,Rect2(x+2,y+1,minf(26,rect.end.x-x-2),1),Color("849487"))
			_pixel(canvas,Rect2(x+4,y+3,3,2),Color("243f46"))
	for y in range(int(rect.position.y)+8,int(rect.end.y)-8,32):
		for x in [rect.position.x,rect.end.x-8]:
			if _bridge_mouth(Vector2(x+4,y+16),index): continue
			_pixel(canvas,Rect2(x,y,8,30),Color("405b5a"))
			_pixel(canvas,Rect2(x+2,y+3,2,22),Color("688076"))
			if (y/32)%3==0:
				_pixel(canvas,Rect2(x-2,y+13,11,5),Color("897752"))
	# Sparse service lines make the yard a maintained machine, interrupted by wear.
	var lane_y := rect.position.y+rect.size.y-101
	for x in range(int(rect.position.x)+55,int(rect.end.x)-45,58):
		if view.has_point(Vector2(x,lane_y)):
			_pixel(canvas,Rect2(x,lane_y,32,2),Color("6c7961"))
	for p2 in [rect.position+Vector2(54,117),rect.end-Vector2(136,57)]:
		if view.has_point(p2):
			_pixel(canvas,Rect2(p2,Vector2(78,25)),Color("172f36"))
			for n in range(6):
				_pixel(canvas,Rect2(p2+Vector2(5+n*12,4),Vector2(5,2)),Color("587d75"))
			canvas.draw_string(ThemeDB.fallback_font,p2+Vector2(5,19),"P17 / %02d" % (index+1),HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("708b7e"))
	# Service numbers painted into each yard.
	var p := rect.position+Vector2(35,55)
	canvas.draw_string(ThemeDB.fallback_font,p,"0%d" % (index+1),HORIZONTAL_ALIGNMENT_LEFT,-1,28,Color("819780"))
	var light := Color("6bd8bc") if index<restored else Color("ba8b60")
	for corner in [rect.position+Vector2(16,16),rect.position+Vector2(rect.size.x-22,16),rect.end-Vector2(22,22),rect.position+Vector2(16,rect.size.y-22)]:
		_pixel(canvas,Rect2(corner,Vector2(7,7)),Color("18343b"))
		_pixel(canvas,Rect2(corner+Vector2(2,2),Vector2(3,3)),light)

static func _draw_stain(canvas: Node2D, p: Vector2, seed: int, moss: bool) -> void:
	var shadow := Color("19343a") if not moss else Color("213d38")
	var tint := Color("2a4645") if not moss else Color("345247")
	_pixel(canvas,Rect2(p+Vector2(-8,0),Vector2(29,5)),shadow)
	_pixel(canvas,Rect2(p+Vector2(-13,5),Vector2(44,6)),shadow)
	_pixel(canvas,Rect2(p+Vector2(-7,11),Vector2(32,5)),shadow)
	_pixel(canvas,Rect2(p+Vector2(2,16),Vector2(17,3)),shadow)
	for i in range(7):
		var spot := p+Vector2(-7+(seed+i*7)%28,2+(seed+i*11)%12)
		_pixel(canvas,Rect2(spot,Vector2(3+i%3,2)),tint)
	if not moss:
		_pixel(canvas,Rect2(p+Vector2(-3,2),Vector2(12,1)),Color("416263"))

static func _draw_shadow(canvas: Node2D, rect: Rect2) -> void:
	_pixel(canvas,Rect2(rect.position+Vector2(7,11),rect.size+Vector2(7,5)),Color(0.025,0.065,0.08,0.38))
	_pixel(canvas,Rect2(rect.position+Vector2(5,8),rect.size+Vector2(2,2)),Color(0.025,0.055,0.07,0.62))
	_pixel(canvas,Rect2(rect.position+Vector2(3,5),rect.size),Color("112931"))

static func _bridge_mouth(point: Vector2, index: int) -> bool:
	for bridge in BRIDGES:
		if bridge.grow(9).has_point(point): return true
	return index==0 and PIER.grow(9).has_point(point)

static func _draw_bridge(canvas: Node2D, rect: Rect2, wooden: bool) -> void:
	_pixel(canvas,rect,Color("35434a") if not wooden else Color("564e44"))
	var vertical := rect.size.y>rect.size.x
	var step := 18 if wooden else 24
	if vertical:
		for y in range(int(rect.position.y),int(rect.end.y),step):
			_pixel(canvas,Rect2(rect.position.x+5,y+1,rect.size.x-10,step-3),Color("7a7361") if wooden else Color("66787a"))
			_pixel(canvas,Rect2(rect.position.x+12,y+5,rect.size.x-24,2),Color("91876b") if wooden else Color("839291"))
		for x in [rect.position.x,rect.end.x-5]:
			_pixel(canvas,Rect2(x,rect.position.y,5,rect.size.y),Color("b49966"))
			for y in range(int(rect.position.y),int(rect.end.y),40): _pixel(canvas,Rect2(x-2,y,9,6),Color("dae0b7"))
	else:
		for x in range(int(rect.position.x),int(rect.end.x),step):
			_pixel(canvas,Rect2(x+1,rect.position.y+5,step-3,rect.size.y-10),Color("66787a"))
			_pixel(canvas,Rect2(x+5,rect.position.y+12,2,rect.size.y-24),Color("839291"))
		for y in [rect.position.y,rect.end.y-5]:
			_pixel(canvas,Rect2(rect.position.x,y,rect.size.x,5),Color("b49966"))
			for x in range(int(rect.position.x),int(rect.end.x),40): _pixel(canvas,Rect2(x,y-2,6,9),Color("dae0b7"))
	# Hazard edges frame a clearly open central walking lane.
	for i in range(int(rect.size.x/32)):
		_pixel(canvas,Rect2(rect.position.x+10+i*32,rect.position.y+8,12,4),Color("cbb578"))

static func _draw_utilities(canvas: Node2D, view: Rect2, restored: int, time: float) -> void:
	var pipes := [
		[Vector2(260,1156),Vector2(260,1168),Vector2(530,1168),Vector2(530,1230)],
		[Vector2(2200,265),Vector2(2220,265),Vector2(2220,405),Vector2(2172,405)],
		[Vector2(1690,1190),Vector2(1690,1220),Vector2(1840,1220),Vector2(1840,1390)],
	]
	for path in pipes:
		for i in range(path.size()-1):
			if not view.grow(200).has_point(path[i]): continue
			canvas.draw_line(path[i]+Vector2(3,4),path[i+1]+Vector2(3,4),Color("23383b"),12)
			canvas.draw_line(path[i],path[i+1],Color("946750"),9)
			canvas.draw_line(path[i]-Vector2(2,2),path[i+1]-Vector2(2,2),Color("b99b72"),2)
	for p in [Vector2(550,1420),Vector2(950,750),Vector2(1690,435),Vector2(2310,1520)]:
		if not view.has_point(p): continue
		_pixel(canvas,Rect2(p,Vector2(60,24)),Color("263c41"))
		for i in range(9): _pixel(canvas,Rect2(p+Vector2(4+i*6,3),Vector2(2,18)),Color("87958b"))
	# A live conduit is a quiet visual reward after the distribution system comes online.
	if restored>=4:
		for i in range(10):
			var p := Vector2(2140+int(time*26+i*25)%250,1430)
			if view.has_point(p): _pixel(canvas,Rect2(p,Vector2(8,3)),Color("67d7b7"))

static func _draw_basin(canvas: Node2D, rect: Rect2, index: int, restored: int, time: float) -> void:
	_pixel(canvas,Rect2(rect.position+Vector2(6,8),rect.size),Color("2b393a"))
	_pixel(canvas,rect,Color("152e39"))
	var water := Color("63394e") if index==0 and restored<1 else Color("245b62")
	_pixel(canvas,rect.grow(-8),water)
	for y in range(int(rect.position.y)+20,int(rect.end.y)-12,22):
		var offset := int(time*6+y)%24
		for x in range(int(rect.position.x)+14,int(rect.end.x)-30,47):
			_pixel(canvas,Rect2(x+offset,y,19,2),water.lightened(0.18))
	canvas.draw_rect(rect,Color("a3a58f"),false,7)
	for x in range(int(rect.position.x)+12,int(rect.end.x),32):
		_pixel(canvas,Rect2(x,rect.position.y-3,4,6),Color("d7c392"))
		_pixel(canvas,Rect2(x,rect.end.y-4,4,6),Color("67786f"))
	_pixel(canvas,Rect2(rect.position+Vector2(17,14),Vector2(6,6)),Color("94c8b1"))

static func _draw_building(canvas: Node2D, rect: Rect2, index: int, restored: int) -> void:
	_pixel(canvas,Rect2(rect.position+Vector2(12,14),rect.size),Color("2a3b3b"))
	_pixel(canvas,rect,Color("243c45"))
	_pixel(canvas,Rect2(rect.position+Vector2(5,5),Vector2(rect.size.x-10,rect.size.y-35)),Color("677670"))
	_pixel(canvas,Rect2(rect.position+Vector2(10,10),Vector2(rect.size.x-20,rect.size.y-48)),Color("52636a"))
	for y in range(int(rect.position.y)+15,int(rect.end.y)-36,18):
		_pixel(canvas,Rect2(rect.position.x+12,y,rect.size.x-24,2),Color("718384"))
	var facade := Rect2(rect.position.x+5,rect.end.y-30,rect.size.x-10,25)
	_pixel(canvas,facade,Color("a18f6b"))
	for x in range(int(rect.position.x)+14,int(rect.end.x)-10,42):
		_pixel(canvas,Rect2(x,facade.position.y+5,27,13),Color("223c48"))
		_pixel(canvas,Rect2(x+2,facade.position.y+7,23,3),Color("7fbeb5") if restored>index else Color("507a83"))
	var door := Rect2(rect.get_center().x-24,rect.end.y-30,48,29)
	_pixel(canvas,door,Color("253843"))
	for y in range(int(door.position.y)+3,int(door.end.y)-2,5): _pixel(canvas,Rect2(door.position.x+3,y,42,2),Color("576968"))
	_pixel(canvas,Rect2(rect.position+Vector2(13,13),Vector2(63,22)),Color("1b3843"))
	canvas.draw_string(ThemeDB.fallback_font,rect.position+Vector2(20,29),["OFICINA","FILTROS","REDE 17"][index],HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("c0d4b4"))
	if index==0:
		for i in range(3): _draw_solar(canvas,Rect2(rect.position+Vector2(100+i*72,48),Vector2(64,104)))
	elif index==1:
		for i in range(5):
			var p := rect.position+Vector2(34+i*78,70)
			_pixel(canvas,Rect2(p,Vector2(49,61)),Color("2e424b"))
			_pixel(canvas,Rect2(p+Vector2(4,4),Vector2(41,45)),Color("7e9090"))
			for n in range(5): _pixel(canvas,Rect2(p+Vector2(8,9+n*7),Vector2(33,3)),Color("405b64"))
	else:
		_pixel(canvas,Rect2(rect.position+Vector2(85,25),Vector2(156,48)),Color("304c59"))
		for i in range(9): _pixel(canvas,Rect2(rect.position+Vector2(93+i*16,32),Vector2(6,34)),Color("6a8983"))

static func _draw_solar(canvas: Node2D, rect: Rect2) -> void:
	_pixel(canvas,Rect2(rect.position+Vector2(3,5),rect.size),Color("293d45"))
	_pixel(canvas,rect,Color("a6a78d"))
	_pixel(canvas,rect.grow(-3),Color("244c65"))
	for y in range(int(rect.position.y)+5,int(rect.end.y)-3,14):
		for x in range(int(rect.position.x)+5,int(rect.end.x)-3,17):
			_pixel(canvas,Rect2(x,y,minf(14,rect.end.x-x-3),minf(11,rect.end.y-y-3)),Color("386780"))
	canvas.draw_line(rect.position+Vector2(8,5),rect.end-Vector2(8,5),Color("668d94"),2)

static func _draw_prop(canvas: Node2D, prop: Dictionary, restored: int, time: float) -> void:
	var r: Rect2 = prop["rect"]
	var p: Vector2 = prop["pos"]
	var kind: String = prop["kind"]
	if kind=="fern":
		_pixel(canvas,Rect2(p+Vector2(-13,2),Vector2(28,8)),Color("344944"))
		for i in range(5):
			var height := 8+_hash(int(p.x)+i,int(p.y))%12
			var x := p.x-10+i*5
			_pixel(canvas,Rect2(x,p.y-height,3,height+5),Color("466f5b"))
			_pixel(canvas,Rect2(x-4,p.y-height+3,5,3),Color("789466"))
			_pixel(canvas,Rect2(x+3,p.y-height+7,5,3),Color("608958"))
		return
	_pixel(canvas,Rect2(r.position+Vector2(5,6),r.size),Color("30423f"))
	match kind:
		"solar": _draw_solar(canvas,r)
		"tank":
			_pixel(canvas,r,Color("273e45"))
			_pixel(canvas,r.grow(-4),Color("70837f"))
			_pixel(canvas,Rect2(r.position+Vector2(8,8),Vector2(r.size.x-16,r.size.y-30)),Color("9ba99a"))
			_pixel(canvas,Rect2(r.position+Vector2(13,11),Vector2(9,r.size.y-37)),Color("c0c3a6"))
			for y in [r.position.y+26,r.end.y-23]:
				_pixel(canvas,Rect2(r.position.x+3,y,r.size.x-6,6),Color("586e73"))
				_pixel(canvas,Rect2(r.position.x+6,y+1,4,3),Color("d1c493"))
			_pixel(canvas,Rect2(p.x-11,r.position.y+9,22,15),Color("2d4d56"))
			_pixel(canvas,Rect2(p.x-6,r.position.y+12,12,6),Color("83b6ad"))
			_pixel(canvas,Rect2(p.x-14,r.end.y-16,28,8),Color("233e48"))
		"crate":
			_pixel(canvas,r,Color("403e3a"))
			_pixel(canvas,r.grow(-3),Color("ad8c60"))
			_pixel(canvas,r.grow(-7),Color("806c50"))
			canvas.draw_line(r.position+Vector2(6,6),r.end-Vector2(6,6),Color("c0a276"),5)
			canvas.draw_line(Vector2(r.end.x-6,r.position.y+6),Vector2(r.position.x+6,r.end.y-6),Color("ae8e66"),4)
		"barrel":
			_pixel(canvas,r,Color("32434a"))
			_pixel(canvas,r.grow(-3),Color("8b6c53"))
			_pixel(canvas,Rect2(r.position+Vector2(5,2),Vector2(r.size.x-10,7)),Color("b0966c"))
			for y in [r.position.y+12,r.end.y-8]: _pixel(canvas,Rect2(r.position.x+2,y,r.size.x-4,4),Color("526d70"))
		"cabinet","battery":
			_pixel(canvas,r,Color("203944"))
			_pixel(canvas,r.grow(-3),Color("788879") if kind=="cabinet" else Color("a18d67"))
			_pixel(canvas,Rect2(r.position+Vector2(7,8),Vector2(r.size.x-14,15)),Color("254650"))
			_pixel(canvas,Rect2(r.position+Vector2(10,11),Vector2(r.size.x-20,4)),Color("78d1b1") if restored>0 else Color("d69b72"))
			for i in range(4): _pixel(canvas,Rect2(r.position+Vector2(9,31+i*6),Vector2(r.size.x-18,2)),Color("405456"))
			_pixel(canvas,Rect2(r.end-Vector2(10,18),Vector2(3,8)),Color("d8c395"))
		"pump":
			_pixel(canvas,r,Color("29434d"))
			_pixel(canvas,r.grow(-5),Color("a38c66"))
			_pixel(canvas,Rect2(r.position+Vector2(10,10),r.size-Vector2(20,28)),Color("4b777b"))
			var spin := int(time*3)%4 if restored>0 else 0
			canvas.draw_circle(p-Vector2(0,7),16,Color("284a57"))
			canvas.draw_arc(p-Vector2(0,7),12,0,TAU,12,Color("b5aa80"),3)
			for i in range(4):
				var v := Vector2.from_angle((i+spin*0.25)*PI*0.5)*9
				canvas.draw_line(p-Vector2(0,7),p-Vector2(0,7)+v,Color("76b4ad"),4)
			_pixel(canvas,Rect2(r.position.x+10,r.end.y-12,r.size.x-20,4),Color("263d48"))

static func _draw_goal_pad(canvas: Node2D, p: Vector2, index: int, active: bool, time: float) -> void:
	var r := Rect2(p-Vector2(62,51),Vector2(124,104))
	_pixel(canvas,Rect2(r.position+Vector2(5,7),r.size),Color("324542"))
	_pixel(canvas,r,Color("314751"))
	_pixel(canvas,r.grow(-5),Color("677972"))
	_pixel(canvas,r.grow(-10),Color("3b555d"))
	for corner in [r.position+Vector2(3,3),Vector2(r.end.x-8,r.position.y+3),r.end-Vector2(8,8),Vector2(r.position.x+3,r.end.y-8)]:
		_pixel(canvas,Rect2(corner,Vector2(5,5)),Color("c4b087"))
	var light := Color("80dfb6") if active else Color("78b6bb")
	canvas.draw_arc(p,30,0,TAU,24,Color("223d48"),7)
	canvas.draw_arc(p,29,0,TAU,24,light.darkened(0.25),2)
	for i in range(4):
		var point := p+Vector2.from_angle(i*PI*0.5)*41
		_pixel(canvas,Rect2(point-Vector2(4,3),Vector2(8,6)),light if active or int(time*2)%2==0 else light.darkened(0.4))
	canvas.draw_string(ThemeDB.fallback_font,p+Vector2(-4,6),str(index+1),HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("d0d6bb"))

static func _draw_gate(canvas: Node2D, rect: Rect2, opened: bool, time: float) -> void:
	var horizontal := rect.size.x>rect.size.y
	var endpoints := [Vector2(rect.position.x,rect.get_center().y),Vector2(rect.end.x,rect.get_center().y)] if horizontal else [Vector2(rect.get_center().x,rect.position.y),Vector2(rect.get_center().x,rect.end.y)]
	for p in endpoints:
		_pixel(canvas,Rect2(p-Vector2(8,10),Vector2(16,20)),Color("253f49"))
		_pixel(canvas,Rect2(p-Vector2(5,7),Vector2(10,5)),Color("7fe3b5") if opened else Color("e3a27d"))
	if opened:
		return
	_pixel(canvas,rect,Color("253b45"))
	_pixel(canvas,rect.grow(-3),Color("9a7759"))
	var count := int(maxf(rect.size.x,rect.size.y)/20)
	for i in range(count):
		var p := rect.position+Vector2(7+i*20,3) if horizontal else rect.position+Vector2(3,7+i*20)
		_pixel(canvas,Rect2(p,Vector2(9,rect.size.y-6) if horizontal else Vector2(rect.size.x-6,9)),Color("dac28c"))
	var pulse := Color("e3b59b") if int(time*2)%2==0 else Color("aa6b65")
	_pixel(canvas,Rect2(rect.get_center()-Vector2(5,5),Vector2(10,10)),pulse)

static func _draw_route(canvas: Node2D, stage: int, view: Rect2, time: float) -> void:
	if stage<0 or stage>=ROUTES.size(): return
	var route: Array = ROUTES[stage]
	for i in range(route.size()-1):
		var a: Vector2 = route[i]
		var b: Vector2 = route[i+1]
		var vector := (b-a).normalized()
		var distance := a.distance_to(b)
		for step in range(int(distance/120)):
			var p := a+vector*(65+step*120)
			if not view.has_point(p): continue
			var normal := vector.orthogonal()
			var color := Color("85a89a")
			if int(time*0.8+step)%5==0: color=Color("a8c5ac")
			canvas.draw_line(p-vector*5+normal*4,p,color,2)
			canvas.draw_line(p-vector*5-normal*4,p,color,2)
