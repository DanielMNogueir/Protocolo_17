class_name P17World
extends RefCounted
## Original district geometry, collision and procedural pixel scenery.
## All public coordinates are world coordinates; stage is zero based.

const StationArt = preload("res://scripts/station_art.gd")
const EnergyStation = preload("res://scripts/energy_station.gd")
const EnvironmentProps = preload("res://scripts/environment_props.gd")
const WaterSurface = preload("res://scripts/water_surface.gd")
const BridgeLayout = preload("res://scripts/bridge_layout.gd")
const SIZE := Vector2(2560, 1800)
const REGIONS: Array[Rect2] = [
	Rect2(100, 1020, 1010, 660), Rect2(100, 100, 1010, 740),
	Rect2(1450, 100, 1010, 740), Rect2(1450, 1020, 1010, 660),
]
const NAMES := ["CAIS DAS BOMBAS", "PÁTIO SOLAR", "GALERIA DOS FILTROS", "DISTRIBUIÇÃO AURORA"]
const START := Vector2(440, 1570)
const GOALS: Array[Vector2] = [Vector2(870,1190), EnergyStation.INTERACTION_POINT, Vector2(2210,600), Vector2(2110,1430)]
const ENERGY_STATION_ORIGIN: Vector2 = EnergyStation.WORLD_ORIGIN
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
	[GOALS[0],Vector2(870,1070),Vector2(770,1070),Vector2(770,730),Vector2(850,730),Vector2(1030,520),Vector2(1030,450),GOALS[1]],
	[GOALS[1],Vector2(1030,450),Vector2(1030,610),Vector2(1530,610),Vector2(2110,610),GOALS[2]],
	[GOALS[2],Vector2(2040,600),Vector2(2040,1110),Vector2(2110,1110),GOALS[3]],
]
const BASINS: Array[Rect2] = [Rect2(210,1180,260,180),Rect2(1550,670,300,120),Rect2(1630,1240,190,250)]
const BUILDINGS: Array[Rect2] = [Rect2(230,220,350,230),Rect2(1550,180,430,220),Rect2(1510,1060,280,130)]
static var _solid_cache: Array[Rect2] = []
static var _props_cache: Array[Dictionary] = []
static var _building_cache: Array[Dictionary] = []

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
		["pallet",Rect2(210,1510,52,34)],["crate",Rect2(270,1530,42,38)],
		["barrel",Rect2(330,1480,28,34)],["barrel",Rect2(361,1485,28,34)],
		["tank",Rect2(960,1050,74,94)],["cabinet",Rect2(160,1090,32,55)],
		["barrier",Rect2(205,600,72,28)],["spool",Rect2(300,605,45,38)],
		["barrel",Rect2(273,625,28,34)],["barrel",Rect2(306,625,28,34)],
		["solar",Rect2(250,495,190,66)],["solar",Rect2(450,495,190,66)],
		["tank",Rect2(2080,190,120,150)],["tank",Rect2(2240,190,120,150)],
		["pump",Rect2(2100,370,72,80)],["cabinet",Rect2(2300,380,44,66)],
		["stacked_crates",Rect2(1510,465,54,42)],["barrel",Rect2(1575,465,30,36)],
		["tank",Rect2(1510,1310,80,100)],["cabinet",Rect2(2335,1120,45,70)],
		["solar",Rect2(2280,1350,115,60)],["open_crate",Rect2(1530,1570,50,44)],
		["barrel",Rect2(1600,1580,28,34)],["pump",Rect2(1880,1550,65,70)],
	]
	for item in items:
		var rect: Rect2 = item[1]
		var kind: String = item[0]
		if EnvironmentProps.supports(kind):
			var width := rect.size.x - (10.0 if kind == "tank" else 0.0)
			if kind in ["crate","open_crate","stacked_crates","barrel","pallet","cabinet","barrier","spool"]:
				width = 0.0
			_props_cache.append(EnvironmentProps.create(kind,Vector2(rect.get_center().x,rect.end.y),width))
		else:
			# Solar arrays stand on two support bars, not the panel's upper surface.
			var contact := Rect2(rect.position+Vector2(9,rect.size.y-18),Vector2(rect.size.x-18,18))
			_props_cache.append({"kind":kind,"pos":contact.get_center(),"rect":contact,"solid":true,
				"visual_bounds":rect,"collision_rect":contact,"depth_anchor":Vector2(rect.get_center().x,contact.end.y),"station":-1})
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
	for index in range(1,BASINS.size()):
		_solid_cache.append(BASINS[index])
	_solid_cache.append(clarifier().collision_rect)
	for building in building_objects():
		_solid_cache.append(building.collision_rect)
	for bridge in BRIDGES:
		_solid_cache.append_array(BridgeLayout.collision_rects(bridge))
	_solid_cache.append(Rect2(PIER.position,Vector2(16,PIER.size.y)))
	_solid_cache.append(Rect2(PIER.position+Vector2(PIER.size.x-16,0),Vector2(16,PIER.size.y)))
	for index in [0,2,3]:
		_solid_cache.append(terminal(index).collision_rect)
	_solid_cache.append_array(EnergyStation.COLLISION_RECTS)
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

static func draw(canvas: Node2D, camera_pos: Vector2, stage: int, restored: int, time: float, water_surface: P17WaterSurface) -> void:
	var viewport_size:=canvas.get_viewport_rect().size
	var view:=Rect2(camera_pos-viewport_size*0.5,viewport_size).grow(90)
	WaterSurface.draw_structure_contacts(canvas,view,BRIDGES,PIER,time)
	for i in range(REGIONS.size()):
		if _visible(REGIONS[i],view):
			_draw_region(canvas,REGIONS[i],i,view,restored)
			StationArt.draw_shoreline(canvas,REGIONS[i],i,view,restored,time)
	for bridge in BRIDGES:
		if _visible(bridge,view): _draw_bridge(canvas,bridge,false)
	if _visible(PIER,view): _draw_bridge(canvas,PIER,true)
	_draw_utilities(canvas,view,restored,time)
	for i in range(BASINS.size()):
		if i != 0 and _visible(BASINS[i],view): _draw_basin(canvas,BASINS[i],i,restored,time,water_surface)
	for prop in props():
		if not _visible(prop.rect,view): continue
		if prop.kind == "fern":
			_draw_prop_art(canvas,prop,restored,time)
		elif EnvironmentProps.supports(prop.kind):
			EnvironmentProps.draw_foundation(canvas,prop)
	for building in building_objects():
		if _visible(building.visual_bounds,view): EnvironmentProps.draw_foundation(canvas,building)
	if _visible(clarifier().visual_bounds,view): EnvironmentProps.draw_foundation(canvas,clarifier())
	for i in range(GOALS.size()):
		if i != 1 and view.grow(90).has_point(GOALS[i]): _draw_goal_pad(canvas,GOALS[i],i,i<restored,time)
	_draw_route(canvas,stage,view,time)

static func building_objects() -> Array[Dictionary]:
	if not _building_cache.is_empty(): return _building_cache
	var placements := [
		["control_room",Vector2(357.5,425),225.0], ["pump",Vector2(522,417),92.0],
		["tank",Vector2(1667,388),150.0], ["tank",Vector2(1841,388),150.0],
		["purifier",Vector2(1588.5,1172),137.0], ["manifold",Vector2(1719,1172),126.0],
	]
	for placement in placements:
		_building_cache.append(EnvironmentProps.create(placement[0],placement[1],placement[2]))
	return _building_cache

static func clarifier() -> Dictionary:
	return EnvironmentProps.create("clarifier",Vector2(BASINS[0].get_center().x,BASINS[0].end.y-3),256.0)

static func terminal(index: int) -> Dictionary:
	# The original objective coordinate stays free, just in front of the pedestal.
	var height: float = [72.0,88.0,94.0,80.0][index]
	var source: Rect2 = StationArt.TOTEM_CROPS[index]
	var size := Vector2(height*source.size.x/source.size.y,height)
	var visual := Rect2(GOALS[index]-Vector2(70+size.x*0.5,height+23),size)
	var contact := Rect2(visual.position+size*Vector2(0.15,0.75),size*Vector2(0.70,0.20))
	return {"visual_bounds":visual,"collision_rect":contact,"depth_anchor":Vector2(GOALS[index].x-70,contact.end.y)}

static func sortable_objects(view: Rect2) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for building in building_objects():
		if _visible(building.visual_bounds,view):
			result.append({"type":"machine","prop":building,"y":building.depth_anchor.y})
	var tank := clarifier()
	if _visible(tank.visual_bounds,view): result.append({"type":"machine","prop":tank,"y":tank.depth_anchor.y})
	for prop in props():
		if prop.kind != "fern" and _visible(prop.visual_bounds,view):
			result.append({"type":"prop","prop":prop,"y":prop.depth_anchor.y})
	for index in [0,2,3]:
		var data := terminal(index)
		if _visible(data.visual_bounds,view): result.append({"type":"terminal","index":index,"y":data.depth_anchor.y})
	for bridge in BRIDGES:
		if _visible(bridge.grow(60),view): result.append_array(BridgeLayout.parts(bridge))
	if _visible(PIER.grow(50),view): result.append_array(BridgeLayout.pier_parts(PIER))
	for index in range(GATES.size()):
		if _visible(GATES[index],view): result.append({"type":"gate","index":index,"rect":GATES[index],"y":GATES[index].end.y})
	return result

static func draw_sortable(canvas: Node2D, object: Dictionary, restored: int, time: float, stage: int = 0) -> void:
	match object.type:
		"machine": EnvironmentProps.draw(canvas,object.prop,time)
		"terminal": StationArt.draw_totem(canvas,GOALS[object.index],object.index,object.index<restored,time)
		"bridge_part": BridgeLayout.draw_part(canvas,object)
		"gate": _draw_gate(canvas,object.rect,object.index<stage,time)
		_: _draw_prop_art(canvas,object.prop,restored,time)

static func _draw_region(canvas: Node2D, rect: Rect2, index: int, view: Rect2, restored: int) -> void:
	_pixel(canvas,Rect2(rect.position+Vector2(13,19),rect.size),Color("071923"))
	_pixel(canvas,rect.grow(9),Color("0a2029"))
	StationArt.draw_floor(canvas,rect,index)
	var area := rect.intersection(view)
	var row := 0
	var tile_y := int(rect.position.y)
	while tile_y < int(rect.end.y):
		var height: int = mini([48,58,44,62][row%4],int(rect.end.y)-tile_y)
		if tile_y+height >= int(area.position.y) and tile_y <= int(area.end.y):
			var x := int(rect.position.x)
			while x < int(rect.end.x):
				var seed := _hash(int(x/13)+row*7,int(tile_y/11)+index*19)
				var width: int = mini((24+row%3*8) if x == int(rect.position.x) and row%2 == 1 else [56,72,92,64][seed%4],int(rect.end.x)-x)
				var tile := Rect2(x,tile_y,width,height)
				if tile.intersects(view):
					StationArt.draw_floor_tile(canvas,tile,seed,index)
				x += width
		tile_y += height
		row += 1
	# Extra translucent damp marks vary per sector without interrupting routes.
	for n in range(9):
		var stain := rect.position+Vector2(72+posmod(n*137+index*83,int(rect.size.x)-144),84+posmod(n*89+index*59,int(rect.size.y)-168))
		if view.has_point(stain):
			_pixel(canvas,Rect2(stain,Vector2(35+n%3*8,4)),Color("40676a",0.10))
			_pixel(canvas,Rect2(stain+Vector2(-4,4),Vector2(27+n%4*6,3)),Color("4a7476",0.07))
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
	# Wet concrete darkens irregular joints facing the water, not the whole yard.
	for x in range(int(rect.position.x)+16,int(rect.end.x)-12,47):
		for y in [rect.position.y+8,rect.end.y-11]:
			if _bridge_mouth(Vector2(x,y),index) or not view.has_point(Vector2(x,y)): continue
			var seed:=_hash(x,int(y))
			if seed%3!=0: continue
			_pixel(canvas,Rect2(x,y,13+seed%13,3),Color("21454a",0.36))
			_pixel(canvas,Rect2(x+3,y+3,8+seed%7,2),Color("365e55",0.24))
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

static func _bridge_mouth(point: Vector2, index: int) -> bool:
	for bridge in BRIDGES:
		if bridge.grow(9).has_point(point): return true
	return index==0 and PIER.grow(9).has_point(point)

static func _draw_bridge(canvas: Node2D, rect: Rect2, wooden: bool) -> void:
	_draw_bridge_approaches(canvas,rect,rect.size.y>rect.size.x,wooden)
	if wooden: BridgeLayout.draw_pier_deck(canvas,rect)
	else: BridgeLayout.draw_deck(canvas,rect)

static func _draw_bridge_approaches(canvas: Node2D, rect: Rect2, vertical: bool, wooden: bool) -> void:
	var pads: Array[Rect2] = []
	if wooden:
		pads.append(Rect2(rect.position + Vector2(16, -8), Vector2(rect.size.x - 32, 18)))
	elif vertical:
		pads.append(Rect2(rect.position + Vector2(34, -12), Vector2(rect.size.x - 68, 20)))
		pads.append(Rect2(Vector2(rect.position.x + 34, rect.end.y - 8), Vector2(rect.size.x - 68, 20)))
	else:
		pads.append(Rect2(rect.position + Vector2(-12, 34), Vector2(20, rect.size.y - 68)))
		pads.append(Rect2(Vector2(rect.end.x - 8, rect.position.y + 34), Vector2(20, rect.size.y - 68)))
	for pad in pads:
		_pixel(canvas, Rect2(pad.position + Vector2(3, 4), pad.size), Color(0.02, 0.055, 0.06, 0.28))
		_pixel(canvas, pad, Color("465450"))
		_pixel(canvas, pad.grow(-3), Color("706e5f"))
		if vertical or wooden:
			_pixel(canvas, Rect2(pad.position + Vector2(6, 4), Vector2(pad.size.x - 12, 2)), Color("9d987d"))
			_pixel(canvas, Rect2(pad.position + Vector2(10, pad.size.y - 5), Vector2(pad.size.x - 20, 2)), Color("303f40"))
		else:
			_pixel(canvas, Rect2(pad.position + Vector2(4, 6), Vector2(2, pad.size.y - 12)), Color("9d987d"))
			_pixel(canvas, Rect2(pad.position + Vector2(pad.size.x - 5, 10), Vector2(2, pad.size.y - 20)), Color("303f40"))
		for corner in [pad.position + Vector2(3,3), pad.end - Vector2(6,6)]:
			_pixel(canvas, Rect2(corner, Vector2(3,3)), Color("c2ae78"))

static func _draw_utilities(canvas: Node2D, view: Rect2, restored: int, time: float) -> void:
	# Existing assets form actual supply circuits; cables stay flush with the floor.
	var pipes := [
		[Vector2(260,1145),Vector2(260,1168),Vector2(530,1168),Vector2(530,1295)],
		[Vector2(385,1145),Vector2(385,1168)],
		[Vector2(340,1330),Vector2(480,1330),Vector2(480,1295),Vector2(530,1295)],
		[Vector2(357,412),Vector2(474,412),Vector2(520,405)],
		[Vector2(1667,375),Vector2(1667,410),Vector2(1841,410),Vector2(1841,375)],
		[Vector2(2140,323),Vector2(2140,352),Vector2(2300,352),Vector2(2300,323)],
		[Vector2(2140,352),Vector2(2140,430),Vector2(2136,430)],
		[Vector2(1841,410),Vector2(2000,410),Vector2(2000,430),Vector2(2136,430)],
		[Vector2(1588,1160),Vector2(1719,1160),Vector2(1840,1160),Vector2(1840,1390)],
		[Vector2(1550,1390),Vector2(1550,1430),Vector2(1639,1430)],
	]
	for path in pipes:
		for index in range(path.size()-1):
			var a: Vector2 = path[index]
			var b: Vector2 = path[index+1]
			if not Rect2(a.min(b),a.max(b)-a.min(b)).grow(10).intersects(view): continue
			canvas.draw_line(a+Vector2(2,3),b+Vector2(2,3),Color("23383b",0.55),8)
			canvas.draw_line(a,b,Color("775d48"),5)
			canvas.draw_line(a-Vector2(1,1),b-Vector2(1,1),Color("b99b72"),1)
			for point in [a,b]:
				canvas.draw_rect(Rect2(point-Vector2(3,2),Vector2(6,4)),Color("52625e"))
	# Solar output feeds the energy station's existing buried cable.
	_draw_ground_conduit(canvas,PackedVector2Array([Vector2(344,549),Vector2(344,575),Vector2(736,575),Vector2(736,455)]))
	_draw_ground_conduit(canvas,PackedVector2Array([Vector2(546,549),Vector2(546,575)]))
	for p in [Vector2(550,1420),Vector2(950,750),Vector2(1690,435),Vector2(2310,1520)]:
		if not view.has_point(p): continue
		_pixel(canvas,Rect2(p,Vector2(60,24)),Color("263c41"))
		for i in range(9): _pixel(canvas,Rect2(p+Vector2(4+i*6,3),Vector2(2,18)),Color("87958b"))
	if restored>=4:
		for i in range(10):
			var p := Vector2(2140+int(time*26+i*25)%250,1430)
			if view.has_point(p): _pixel(canvas,Rect2(p,Vector2(8,3)),Color("67d7b7"))

static func _draw_basin(canvas: Node2D, rect: Rect2, index: int, restored: int, time: float, water_surface: P17WaterSurface) -> void:
	_pixel(canvas,Rect2(rect.position+Vector2(6,8),rect.size),Color("2b393a"))
	_pixel(canvas,rect,Color("152e39"))
	water_surface.draw_pool(canvas,rect.grow(-8),index)
	canvas.draw_rect(rect,Color("a89c7e"),false,7)
	for x in range(int(rect.position.x)+12,int(rect.end.x),32):
		_pixel(canvas,Rect2(x,rect.position.y-3,4,6),Color("d7c392"))
		_pixel(canvas,Rect2(x,rect.end.y-4,4,6),Color("67786f"))
	_pixel(canvas,Rect2(rect.position+Vector2(17,14),Vector2(6,6)),Color("94c8b1"))
	if index==2:
		WaterSurface.draw_outlet_contact(canvas,Vector2(rect.position.x+10,1430),time,restored>=3)
	for n in range(4):
		var foot := rect.position+Vector2(40+n*(rect.size.x-80)/3.0,42+(n%2)*36)
		WaterSurface.draw_plant_contact(canvas,foot,34,time)
		StationArt.draw_plant(canvas,3 if n%2==0 else 2,foot,34)
	for side in 2:
		var x := rect.position.x+22 if side == 0 else rect.end.x-20
		StationArt.draw_plant(canvas,4 if side == 0 else 0,Vector2(x,rect.end.y+7),43)
		StationArt.draw_plant(canvas,1 if side == 0 else 9,Vector2(x,rect.position.y+58),36)
	StationArt.draw_plant(canvas,6,rect.position+Vector2(rect.size.x*0.52,rect.size.y+6),31)

static func _draw_solar(canvas: Node2D, rect: Rect2) -> void:
	var a := rect.position+Vector2(8,7)
	var b := Vector2(rect.end.x-4,rect.position.y+2)
	var c := rect.end-Vector2(13,8)
	var d := Vector2(rect.position.x+1,rect.end.y-3)
	canvas.draw_colored_polygon(PackedVector2Array([a+Vector2(6,8),b+Vector2(6,8),c+Vector2(6,8),d+Vector2(6,8)]),Color(0.02,0.06,0.08,0.40))
	for foot in [d+Vector2(10,0),c-Vector2(10,0)]:
		_pixel(canvas,Rect2(foot-Vector2(3,1),Vector2(7,11)),Color("4d5550"))
		_pixel(canvas,Rect2(foot+Vector2(-6,9),Vector2(13,4)),Color("81755d"))
	canvas.draw_colored_polygon(PackedVector2Array([a,b,c,d]),Color("b2a174"))
	canvas.draw_colored_polygon(PackedVector2Array([a+Vector2(3,3),b+Vector2(-4,3),c+Vector2(-4,-3),d+Vector2(4,-3)]),Color("1d4b65"))
	for row in range(1,4):
		var t := float(row)/4.0
		canvas.draw_line(a.lerp(d,t)+Vector2(3,0),b.lerp(c,t)-Vector2(4,0),Color("4f7788"),1.0)
	for column in range(1,8):
		var t := float(column)/8.0
		canvas.draw_line(a.lerp(b,t)+Vector2(0,3),d.lerp(c,t)-Vector2(0,3),Color("4a7183"),1.0)
	canvas.draw_polyline(PackedVector2Array([a,b,c,d,a]),Color("d0bd84"),2.0)
	canvas.draw_line(a+Vector2(5,4),b-Vector2(8,-4),Color("78a4af",0.65),2.0)

static func _draw_prop(canvas: Node2D, prop: Dictionary, _restored: int, _time: float) -> void:
	if prop.kind == "solar": _draw_solar(canvas,prop.visual_bounds)

static func _draw_ground_conduit(canvas: Node2D, points: PackedVector2Array) -> void:
	var shadow_points := PackedVector2Array()
	for point in points:
		shadow_points.append(point+Vector2(3,5))
	canvas.draw_polyline(shadow_points,Color(0.02,0.05,0.06,0.34),11.0)
	canvas.draw_polyline(points,Color("725747"),8.0)
	var highlight_points := PackedVector2Array()
	for point in points:
		highlight_points.append(point-Vector2(0,2))
	canvas.draw_polyline(highlight_points,Color("bd9869"),2.0)
	for point in [points[0],points[points.size()-1]]:
		canvas.draw_circle(point,6.0,Color("34474a"))
		canvas.draw_circle(point,3.0,Color("b99061"))

static func _draw_prop_art(canvas: Node2D, prop: Dictionary, restored: int, time: float) -> void:
	var r: Rect2 = prop.get("visual_bounds",prop["rect"])
	var kind: String = prop["kind"]
	if kind == "fern":
		var seed := _hash(int(r.position.x),int(r.position.y))
		var plant_kind: int = [5,6,5,4,9][seed%5]
		if restored == 0 and r.position.x < 1100 and seed%19 == 0:
			plant_kind = 11
		StationArt.draw_plant(canvas,plant_kind,prop["pos"]+Vector2(0,6),25+seed%10)
		return
	if EnvironmentProps.supports(kind):
		EnvironmentProps.draw(canvas,prop,time)
		return
	_draw_prop(canvas,prop,restored,time)

static func _draw_goal_pad(canvas: Node2D, p: Vector2, index: int, active: bool, time: float) -> void:
	var r: Rect2 = terminal(index).collision_rect
	# Low service pedestal supports feet instead of presenting the art in a frame.
	canvas.draw_colored_polygon(PackedVector2Array([
		r.position+Vector2(-3,2),Vector2(r.end.x+2,r.position.y+2),r.end+Vector2(4,4),Vector2(r.position.x-1,r.end.y+4)
	]),Color("556157"))
	canvas.draw_line(Vector2(r.position.x+2,r.end.y+4),r.end+Vector2(2,4),Color("a59b7a"),2)
	for x in [r.position.x+2,r.end.x-3]: canvas.draw_rect(Rect2(x,r.end.y,2,2),Color("d1b878"))
	var light := Color("78dbc4") if active else Color("b76c93")
	var connection := PackedVector2Array([p+Vector2(-70,-24),p+Vector2(-70,-8),p+Vector2(0,-8)])
	canvas.draw_polyline(connection,Color("293e43"),5)
	canvas.draw_polyline(connection,Color(light,0.48),1)

static func _draw_gate(canvas: Node2D, rect: Rect2, opened: bool, time: float) -> void:
	var crosses_vertical_bridge := rect.size.x>rect.size.y
	var center := rect.get_center()
	var span := 92.0
	var start := center-Vector2(span*0.5,0) if crosses_vertical_bridge else center-Vector2(0,span*0.5)
	var color := Color("76dec1") if opened else Color("d29c63")
	# Actuator sits outside the clear deck; the beam follows the collision plane.
	var housing := Rect2(start-Vector2(12,26),Vector2(24,27))
	canvas.draw_rect(Rect2(housing.position+Vector2(2,3),housing.size),Color(0.02,0.05,0.06,0.40))
	canvas.draw_rect(housing,Color("2a4249"))
	canvas.draw_rect(housing.grow(-3),Color("60756b"))
	canvas.draw_rect(Rect2(housing.position+Vector2(5,6),Vector2(14,6)),color)
	for point in [housing.position+Vector2(2,2),housing.end-Vector2(4,4)]:
		canvas.draw_rect(Rect2(point,Vector2(2,2)),Color("c6ac72"))
	if opened: return
	var beam := Rect2(start-Vector2(0,10),Vector2(span,7)) if crosses_vertical_bridge else Rect2(start-Vector2(3,0),Vector2(7,span))
	canvas.draw_rect(Rect2(beam.position+Vector2(2,3),beam.size),Color("182d34"))
	canvas.draw_rect(beam,Color("bc954d"))
	for offset in range(5,int(span)-5,16):
		var mark := Rect2(beam.position+Vector2(offset,0),Vector2(7,7)) if crosses_vertical_bridge else Rect2(beam.position+Vector2(0,offset),Vector2(7,7))
		canvas.draw_rect(mark,Color("34444a"))
	canvas.draw_circle(housing.position+Vector2(12,9),2,Color("ffc27a",0.6+0.25*sin(time*4)))

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
