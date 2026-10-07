class_name P17Wetlands
extends RefCounted
const DistrictAssets = preload("res://scripts/district_assets.gd")
## Authored wetland composition. Deep service channels and bridges share data
## between rendering and collision; shallow puddles and vegetation are cosmetic.
const Art = preload("res://scripts/station_art.gd")
const Water = preload("res://scripts/water_surface.gd")
const Ground = preload("res://scripts/ground_ecology.gd")
enum Habitat { FLOW, REEDS, RETENTION, FILTER, SWALE }
# Water cuts into the former solid yards. All footprints are also movement
# barriers; crossings cut exact deck openings out of this shared geometry.
const CHANNELS: Array[Rect2] = [
	Rect2(100,1376,1010,64), Rect2(330,1344,38,48),
	Rect2(988,1160,122,216), Rect2(535,1020,130,108),
	Rect2(100,100,130,380), Rect2(650,100,200,140), Rect2(100,704,550,88),
	Rect2(1730,485,180,100), Rect2(2010,100,380,72), Rect2(2390,172,70,584),
	Rect2(1450,1178,50,400), Rect2(2310,1200,150,132), Rect2(1450,1620,340,60),
	Rect2(1850,1458,280,44), Rect2(1818,1458,38,44), Rect2(2350,1430,110,250),
]
const SECTORS := [0,0,0,0,1,1,1,2,2,2,3,3,3,3,3,3]
const HABITATS := [Habitat.FLOW,Habitat.FLOW,Habitat.REEDS,Habitat.RETENTION,
	Habitat.REEDS,Habitat.RETENTION,Habitat.SWALE,Habitat.FILTER,Habitat.RETENTION,
	Habitat.FLOW,Habitat.REEDS,Habitat.RETENTION,Habitat.SWALE,Habitat.FLOW,
	Habitat.FLOW,Habitat.REEDS]
const CROSSINGS: Array[Rect2] = [
	Rect2(620,1368,146,80),Rect2(128,1368,116,80),
	Rect2(502,696,116,104),Rect2(1970,1450,120,60),
]
const CHANNEL_RIM := 3.0
static var _plants: Array[Dictionary] = []
static var _ground: Array[Dictionary] = []

static func water_contains(point: Vector2) -> bool:
	for channel in CHANNELS:
		if channel.has_point(point): return true
	return false

static func channel_solids() -> Array[Rect2]:
	var result: Array[Rect2] = []
	# Water features include their coping; walking decks cut exact openings.
	for channel in CHANNELS:
		var pieces: Array[Rect2] = [channel.grow(CHANNEL_RIM)]
		for crossing in CROSSINGS:
			var deck := Rect2(crossing.position+Vector2(6,0),crossing.size-Vector2(12,0))
			var next: Array[Rect2] = []
			for piece in pieces:
				if not piece.intersects(deck):
					next.append(piece)
					continue
				var cut := piece.intersection(deck)
				for r in [Rect2(piece.position,Vector2(cut.position.x-piece.position.x,piece.size.y)),
					Rect2(cut.end.x,piece.position.y,piece.end.x-cut.end.x,piece.size.y),
					Rect2(cut.position.x,piece.position.y,cut.size.x,cut.position.y-piece.position.y),
					Rect2(cut.position.x,cut.end.y,cut.size.x,piece.end.y-cut.end.y)]:
					if r.size.x>0 and r.size.y>0: next.append(r)
			pieces = next
		result.append_array(pieces)
	return result

static func _seed(a: int, b: int) -> int:
	return posmod(a*137+b*73+a*b*11,1009)

static func _route_clear(p: Vector2, radius: float, routes: Array) -> bool:
	for route in routes:
		for i in range(route.size()-1):
			if p.distance_to(Geometry2D.get_closest_point_to_segment(p,route[i],route[i+1]))<radius:
				return false
	return true

static func prepare(regions: Array[Rect2], routes: Array, reservations: Array[Rect2], basins: Array[Rect2] = []) -> void:
	if not _plants.is_empty(): return
	# Irregular coherent beds at banks, not uniform independent tufts.
	var beds: Array = []
	for sector in range(regions.size()):
		var r := regions[sector]
		for x_fraction in [0.06,0.28,0.48,0.87]:
			for edge in [0,1]:
				beds.append([Vector2(r.position.x+r.size.x*x_fraction, r.position.y+28 if edge==0 else r.end.y-12),Vector2(64,30),sector])
		for fraction in [0.12,0.40,0.72,0.92]:
			for side in [0,1]:
				beds.append([Vector2(r.position.x+18 if side==0 else r.end.x-20,r.position.y+r.size.y*fraction),Vector2(33,47),sector])
	# Leaks and bank planting reach into the yard, while objective arenas stay open.
	beds.append_array([
		[Vector2(468,1295),Vector2(34,36),0], [Vector2(440,1353),Vector2(51,20),0],
		[Vector2(215,1369),Vector2(60,15),0], [Vector2(460,1438),Vector2(64,12),0],
		[Vector2(880,1368),Vector2(82,14),0], [Vector2(962,1446),Vector2(42,15),0],
		[Vector2(610,582),Vector2(48,30),1], [Vector2(233,420),Vector2(44,30),1],
		[Vector2(1580,624),Vector2(45,28),2], [Vector2(1870,770),Vector2(54,22),2],
		[Vector2(2010,353),Vector2(24,56),2], [Vector2(1590,1245),Vector2(25,70),3],
		[Vector2(1839,1466),Vector2(24,54),3], [Vector2(2265,1588),Vector2(66,28),3],
	])
	var bed_index := 0
	for bed in beds:
		var center: Vector2 = bed[0]
		var radii: Vector2 = bed[1]
		var sector: int = bed[2]
		for i in range(8):
			var seed := _seed(bed_index,i)
			var angle := float(seed%360)*PI/180.0
			var spread := sqrt(float(posmod(seed*19,100))/100.0)
			var foot := (center+Vector2(cos(angle),sin(angle))*radii*spread).round()
			var width := 27.0+seed%26
			if not regions[sector].grow(-4).has_point(foot): continue
			if not _route_clear(foot,width*0.5+30,routes): continue
			var excluded := false
			for reserved in reservations:
				if reserved.grow(width*0.3+5).has_point(foot):
					excluded = true
					break
			if excluded: continue
			for channel in CHANNELS:
				if channel.grow(2).has_point(foot): excluded = true
			if excluded: continue
			var kind: int = [4,5,6,9,4,0,6][seed%7]
			_add_plant(foot,width,kind,seed,false)
		bed_index += 1
	# New banks establish wetland masses inside each yard. Reeds grow in water;
	# ferns/moss occupy the landward side. Their roots determine depth sorting.
	for index in range(CHANNELS.size()):
		var channel := CHANNELS[index]
		for side in range(4):
			var length := channel.size.x if side<2 else channel.size.y
			for n in range(maxi(1,int(length/52))):
				var seed := _seed(index*19+side,n+71)
				var fraction := (n+0.5)/maxi(1,int(length/52))
				var center := Vector2(channel.position.x+length*fraction,channel.position.y-8 if side==0 else channel.end.y+21) if side<2 else Vector2(channel.position.x-17 if side==2 else channel.end.x+17,channel.position.y+length*fraction)
				for sprig in range(1):
					var foot := (center+Vector2(seed%19-9,posmod(seed*13+sprig*17,19)-9)).round()
					var width := 30.0+posmod(seed+sprig*11,26)
					if not regions[SECTORS[index]].grow(-10).has_point(foot): continue
					if water_contains(foot) or not _route_clear(foot,width*0.5+24,routes): continue
					var excluded := false
					for reserved in reservations:
						if reserved.grow(width*0.25+6).has_point(foot): excluded = true
					if not excluded: _add_plant(foot,width,[4,5,6,5,9][seed%5],seed,false)
		if HABITATS[index] == Habitat.FLOW: continue
		var inner := channel.grow(-14)
		var cols := maxi(1,int(inner.size.x/43))
		var rows := maxi(1,int(inner.size.y/42))
		for row in range(rows):
			for col in range(cols):
				var seed := _seed(index+71,col+row*cols)
				if seed%5==0 and HABITATS[index]!=Habitat.FILTER: continue
				var foot := (inner.position+Vector2((col+0.5)*inner.size.x/cols,(row+0.5)*inner.size.y/rows)+Vector2(seed%9-4,posmod(seed*11,9)-4)).round()
				var free := true
				for crossing in CROSSINGS:
					if crossing.grow(24).has_point(foot): free = false
				if not free: continue
				var kind: int = [0,1,2,3,8,3][seed%6]
				if HABITATS[index] == Habitat.SWALE: kind=[0,1,9,3][seed%4]
				var width := 30.0+seed%20
				_add_plant(foot,width,kind,seed,true)
	# Shallow pools are walkable, with broken reflective silhouettes rather than
	# the thick coping and flowing surface used for the blocked service channels.
	var depressions := [
		[Vector2(760,1125),Vector2(900,1300),Vector2(770,1512),Vector2(550,1560),Vector2(910,1630),Vector2(620,1180)],
		[Vector2(300,510),Vector2(540,665),Vector2(960,685),Vector2(925,240),Vector2(875,325),Vector2(360,290)],
		[Vector2(1670,360),Vector2(1990,645),Vector2(2290,700),Vector2(2050,270),Vector2(1570,750),Vector2(2280,470)],
		[Vector2(1930,1290),Vector2(2180,1545),Vector2(2080,1170),Vector2(2280,1640),Vector2(1750,1540),Vector2(2010,1605)],
	]
	for sector in range(regions.size()):
		for i in range(depressions[sector].size()):
			var seed := _seed(sector+17,i)
			var p: Vector2 = depressions[sector][i]
			var size := Vector2(62+seed%50,32+seed%29)
			var rect := Rect2(p-size*0.5,size)
			var free := true
			for reserved in reservations:
				if reserved.grow(10).intersects(rect): free = false
			for channel in CHANNELS:
				if channel.grow(12).intersects(rect): free = false
			if free: _ground.append({"rect":rect,"seed":seed,"puddle":true})
	Ground.prepare(regions,CHANNELS,basins,_plants,_ground,CROSSINGS)

static func _add_plant(foot: Vector2, width: float, kind: int, seed: int, aquatic: bool) -> void:
	if not aquatic: width += 6.0
	var source: Rect2 = Art.PLANT_CROPS[kind] if aquatic else Art.FERN_CROPS[seed%4]
	var height := width*source.size.y/source.size.x
	_plants.append({"type":"wetland_plant","foot":foot,"width":width,"kind":kind,
		"bounds":Rect2(foot-Vector2(width/2,height),Vector2(width,height)),"y":foot.y,"seed":seed,"aquatic":aquatic})

static func plants(view: Rect2) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for plant in _plants:
		if plant.bounds.intersects(view): result.append(plant)
	return result

static func draw_ground(canvas: Node2D, view: Rect2, _time: float) -> void:
	Ground.draw(canvas,view)

static func draw_plant(canvas: Node2D, plant: Dictionary, time: float) -> void:
	if plant.get("aquatic",false): Water.draw_plant_contact(canvas,plant.foot,plant.width,time)
	if plant.get("aquatic",false):
		Art.draw_plant(canvas,plant.kind,plant.foot,plant.width)
	else:
		Art.draw_fern(canvas,plant.foot,plant.width,plant.seed)

static func draw_channels(canvas: Node2D, view: Rect2, water: P17WaterSurface, time: float, restored: int) -> void:
	# Paint the union in two passes so intersections do not acquire closed rims.
	for r in CHANNELS:
		if not r.grow(10).intersects(view): continue
		canvas.draw_rect(r.grow(7),Color("233c40"))
		canvas.draw_rect(r.grow(3),Color("849387"))
	for i in range(CHANNELS.size()):
		var r := CHANNELS[i]
		if not r.grow(8).intersects(view): continue
		canvas.draw_rect(r,Color("0c343c"))
		water.draw_service_channel(canvas,r.grow(-3),i)
	for i in range(CHANNELS.size()):
		var r := CHANNELS[i]
		if not r.grow(20).intersects(view): continue
		_draw_bank(canvas,r,i)
		if HABITATS[i] in [Habitat.RETENTION,Habitat.FILTER]:
			_draw_wetland_floor(canvas,r,i,time)
	# Banks at T/L joins remain open to the visible flow.
	for i in range(CHANNELS.size()):
		for j in range(i+1,CHANNELS.size()):
			var join := CHANNELS[i].grow(3).intersection(CHANNELS[j].grow(3))
			if join.size.x>0 and join.size.y>0 and join.intersects(view):
				canvas.draw_rect(join,Color("296971"))
	# Feed collar links the clarifier's existing illustrated discharge to the drain.
	canvas.draw_rect(Rect2(335,1350,28,5),Color("36565b"))
	canvas.draw_rect(Rect2(341,1355,16,13),Color("58a9ad",0.72))
	for i in range(4):
		var y := 1356+posmod(int(time*(18 if restored>0 else 8))+i*4,14)
		canvas.draw_rect(Rect2(343+i%2*5,y,5,1),Color("c4ded1",0.65))
	_draw_feeds(canvas,view,time,restored)
	for bridge in CROSSINGS:
		if not bridge.grow(12).intersects(view): continue
		canvas.draw_rect(Rect2(bridge.position+Vector2(3,4),bridge.size),Color("102c33",0.5))
		canvas.draw_rect(bridge,Color("597579"))
		DistrictAssets.grate(canvas,bridge.grow(-5))
		for x in [bridge.position.x,bridge.end.x-5]:
			canvas.draw_rect(Rect2(x,bridge.position.y,5,bridge.size.y),Color("9aa99b"))
			for y in range(int(bridge.position.y)+3,int(bridge.end.y)-3,12):
				canvas.draw_rect(Rect2(x,y,5,5),Color("cbb765"))
		for y in range(int(bridge.position.y)+8,int(bridge.end.y)-5,19):
			for x in [bridge.position.x-3,bridge.end.x-4]:
				canvas.draw_rect(Rect2(x,y,7,4),Color("4c4e41"))
				canvas.draw_rect(Rect2(x+2,y,2,2),Color("d0c39a"))

static func _draw_bank(canvas: Node2D, r: Rect2, index: int) -> void:
	var natural: bool = HABITATS[index] in [Habitat.REEDS,Habitat.SWALE,Habitat.FILTER]
	for side in range(4):
		var length := r.size.x if side<2 else r.size.y
		for step in range(0,int(length),22):
			var p := Vector2(r.position.x+step,r.position.y-3 if side==0 else r.end.y) if side<2 else Vector2(r.position.x-3 if side==2 else r.end.x,r.position.y+step)
			var size := Vector2(minf(20,length-step),3) if side<2 else Vector2(3,minf(20,length-step))
			var seed := _seed(index+side,step)
			var normal: Vector2 = [Vector2.UP,Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT][side]
			if water_contains(p+size*0.5+normal*8): continue
			# The coping has a chipped stone top and a dark wet face below it.
			var wall := Rect2(p+Vector2(0,3),Vector2(size.x,7)) if side==0 else (
				Rect2(p-Vector2(0,6),Vector2(size.x,6)) if side==1 else (
				Rect2(p+Vector2(3,0),Vector2(6,size.y)) if side==2 else Rect2(p-Vector2(6,0),Vector2(6,size.y))))
			canvas.draw_rect(wall,Color("1a3b43"))
			canvas.draw_rect(Rect2(wall.position+Vector2(1,2),wall.size-Vector2(2,3)),Color("35514f") if seed%3!=0 else Color("294643"))
			var tint := Color("a5b39c") if seed%4!=0 else Color("596c65")
			canvas.draw_rect(Rect2(p,size),tint)
			if natural:
				canvas.draw_rect(Rect2(p+Vector2(seed%3-1,1),size+Vector2(1,2)),Color("568047",0.73))
				if seed%3==0: canvas.draw_rect(Rect2(p+Vector2(4,3),Vector2(8+seed%7,3)),Color("355c41",0.7))
				if seed%2==0:
					canvas.draw_rect(Rect2(wall.position+Vector2(seed%3,1),Vector2(2,4+seed%3)),Color("6c8030",0.82))
			elif seed%4==0:
				canvas.draw_rect(Rect2(p+Vector2(1,1),Vector2(3,2)),Color("b39862"))

static func _draw_wetland_floor(canvas: Node2D, r: Rect2, index: int, time: float) -> void:
	# Small submerged planting beds signal engineered biological filtration.
	if HABITATS[index]!=Habitat.FILTER: return
	var inner := r.grow(-13)
	for x in range(int(inner.position.x)+6,int(inner.end.x)-4,28):
		canvas.draw_rect(Rect2(x,inner.position.y,2,inner.size.y),Color("6d9579",0.20))
	for row in range(2):
		var y := inner.position.y+row*inner.size.y*0.5+6
		canvas.draw_rect(Rect2(inner.position.x,y,inner.size.x,2),Color("3d6650",0.46))
		for n in range(5):
			var p := Vector2(inner.position.x+6+n*(inner.size.x-12)/5.0,y+7)
			canvas.draw_rect(Rect2(p,Vector2(5,2)),Color("88b276",0.16+sin(time*0.4+n)*0.04))

static func _draw_feeds(canvas: Node2D, view: Rect2, time: float, restored: int) -> void:
	var connections := [
		[Vector2(533,1292),Vector2(598,1292),Vector2(598,1069)],
		[Vector2(988,1128),Vector2(1049,1128),Vector2(1049,1194)],
		[Vector2(2300,352),Vector2(2421,352)],
		[Vector2(1841,410),Vector2(1841,499)],
		[Vector2(2337,1400),Vector2(2397,1400),Vector2(2397,1466)],
	]
	for path in connections:
		for i in range(path.size()-1):
			var a: Vector2 = path[i]
			var b: Vector2 = path[i+1]
			if not Rect2(a.min(b),(a-b).abs()).grow(12).intersects(view): continue
			canvas.draw_line(a+Vector2(2,3),b+Vector2(2,3),Color("17363b",0.62),8)
			canvas.draw_line(a,b,Color("526d70"),5)
			canvas.draw_line(a-Vector2(1,1),b-Vector2(1,1),Color("a4aa88"),1)
			for p in [a,b]:
				canvas.draw_rect(Rect2(p-Vector2(4,3),Vector2(8,6)),Color("948967"))
	for outlet in [[Vector2(1102,1408),0],[Vector2(2420,736),2],[Vector2(2398,1650),3]]:
		var p: Vector2 = outlet[0]
		if not view.grow(50).has_point(p): continue
		var active: bool = restored>outlet[1]
		canvas.draw_rect(Rect2(p-Vector2(14,18),Vector2(25,36)),Color("3b5558"))
		canvas.draw_rect(Rect2(p-Vector2(9,14),Vector2(15,28)),Color("152f36"))
		for n in range(4): canvas.draw_rect(Rect2(p+Vector2(-8,-11+n*7),Vector2(13,2)),Color("819083"))
		canvas.draw_circle(p+Vector2(-17,-16),6,Color("31494c"))
		canvas.draw_arc(p+Vector2(-17,-16),4,0,TAU,10,Color("b28d58"),2)
		canvas.draw_rect(Rect2(p+Vector2(-19,15),Vector2(3,3)),Color("75d8a6") if active else Color("ba8758"))
		Water.draw_outlet_contact(canvas,p+Vector2(4,0),time,active)
