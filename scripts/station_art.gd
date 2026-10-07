class_name P17StationArt
extends RefCounted
## Approved water-treatment-station concept art, placed without changing world geometry.

const WaterSurface = preload("res://scripts/water_surface.gd")
const FLOOR: Texture2D = preload("res://assets/station/wet_concrete_v2.png")
const FERNS: Texture2D = preload("res://assets/station/wetland_ferns.png")
const FERN_CROPS := [Rect2(20,130,590,460),Rect2(640,20,595,570),Rect2(25,755,585,430),Rect2(650,680,590,550)]
static var _floor_layouts: Dictionary = {}
const STRUCTURES: Texture2D = preload("res://assets/station/structures_atlas.png")
const TOTEMS: Texture2D = preload("res://assets/station/totems_atlas.png")
const VEGETATION: Texture2D = preload("res://assets/station/vegetation_atlas.png")

# Full opaque silhouettes, measured on the source images, with a 2px gutter.
# In particular pump intake, manifold outlet and generator elbow exceed old cells.
const STRUCTURE_CROPS := [
	Rect2(10,214,504,467), Rect2(515,174,333,492),
	Rect2(861,328,382,359), Rect2(14,722,440,421),
	Rect2(456,732,459,444), Rect2(849,817,392,351),
]
# The bottom two concepts overlap each other's rectangular bounds. These convex
# contours enclose every original opaque pixel and exclude the neighbouring unit.
# Positions and UVs use the SAME uniform affine mapping: no perspective warp.
const STRUCTURE_CONTOURS := {
	4: [Vector2(914.00000,942.69169),Vector2(866.11731,1025.62693),Vector2(607.39557,1175.00000),Vector2(505.27499,1175.00000),Vector2(468.09808,1153.53590),Vector2(457.00000,1134.31347),Vector2(457.00000,964.13140),Vector2(493.92047,900.18327),Vector2(783.49038,733.00000),Vector2(811.24167,733.00000),Vector2(832.85452,745.47818),Vector2(914.00000,886.02628)],
	5: [Vector2(1240.00000,1061.58142),Vector2(1228.86603,1080.86603),Vector2(1079.67761,1167.00000),Vector2(902.47114,1167.00000),Vector2(860.73205,1142.90192),Vector2(850.00000,1124.31347),Vector2(850.00000,1060.61474),Vector2(950.51855,886.51151),Vector2(1069.18396,818.00000),Vector2(1133.58142,818.00000),Vector2(1196.08399,854.08588),Vector2(1240.00000,930.15064)],
}
const TOTEM_CROPS := [
	Rect2(29,332,291,277), Rect2(335,196,281,401),
	Rect2(624,159,296,447), Rect2(934,276,297,357),
	Rect2(25,838,295,271), Rect2(335,685,279,410),
	Rect2(623,660,301,445), Rect2(934,772,299,354),
]
const PLANT_CROPS := [
	Rect2(42, 95, 256, 312), Rect2(346, 69, 257, 349),
	Rect2(636, 124, 288, 294), Rect2(954, 178, 265, 239),
	Rect2(35, 514, 279, 258), Rect2(314, 418, 299, 418),
	Rect2(644, 418, 278, 353), Rect2(955, 439, 263, 379),
	Rect2(37, 891, 274, 262), Rect2(347, 836, 259, 337),
	Rect2(631, 868, 293, 309), Rect2(953, 889, 274, 282),
]

static func draw_floor(canvas: Node2D, rect: Rect2, sector: int) -> void:
	var color: Color = [Color("506971"),Color("647777"),Color("4f7276"),Color("526e6b")][sector]
	canvas.draw_rect(rect,color)

static func draw_floor_tile(canvas: Node2D, tile: Rect2, seed: int, sector: int) -> void:
	var sample_width := int(tile.size.x * 1.85)
	var sample_height := int(tile.size.y * 1.85)
	var dimensions := FLOOR.get_size()
	var source := Rect2(16 + posmod(seed * 61, int(dimensions.x) - sample_width - 32),
		16 + posmod(seed * 97, int(dimensions.y) - sample_height - 32), sample_width, sample_height)
	var tint: Color = [Color("c2d8de"),Color("d5dbd1"),Color("b8d8d5"),Color("c2d4c9")][sector]
	canvas.draw_texture_rect_region(FLOOR,tile,source,tint)
	# A quiet maintenance floor keeps actor silhouettes above its fine aggregate.
	canvas.draw_rect(tile,Color("78929c",0.17))
	canvas.draw_rect(Rect2(tile.position+Vector2(2,1),Vector2(maxf(0,tile.size.x-4),1)),Color("aec6bc",0.12))
	canvas.draw_rect(Rect2(tile.position+Vector2(0,tile.size.y-2),Vector2(tile.size.x,2)),Color("152a2e",0.69))
	canvas.draw_rect(Rect2(tile.position+Vector2(tile.size.x-2,0),Vector2(2,tile.size.y)),Color("203435",0.68))
	if seed%3 != 0:
		var a := tile.position+Vector2(tile.size.x*(0.25+seed%3*0.17),2)
		var b := a+Vector2(seed%23-11,tile.size.y*0.32)
		var c := b+Vector2(seed%17-8,tile.size.y*0.22)
		canvas.draw_polyline(PackedVector2Array([a,b,c]),Color("172d30",0.67),1)
		canvas.draw_polyline(PackedVector2Array([a+Vector2(1,0),b+Vector2(1,0),c+Vector2(1,0)]),Color("acc0af",0.12),1)

static func floor_tiles(rect: Rect2, sector: int) -> Array[Dictionary]:
	if _floor_layouts.has(rect): return _floor_layouts[rect]
	var result: Array[Dictionary] = []
	var y := int(rect.position.y)
	var row := 0
	while y<int(rect.end.y):
		var height := mini([80,96,88,104][row%4],int(rect.end.y)-y)
		var x := int(rect.position.x)
		while x<int(rect.end.x):
			var seed := posmod(int(x/13)*73+(row*7+sector*19)*157+int(x/13)*(row*7+sector*19)*13,997)
			var width := mini(48 if x==int(rect.position.x) and row%2==1 else [104,128,144,112][seed%4],int(rect.end.x)-x)
			result.append({"rect":Rect2(x,y,width,height),"seed":seed})
			x += width
		y += height
		row += 1
	_floor_layouts[rect] = result
	return result

static func draw_fern(canvas: Node2D, foot: Vector2, width: float, seed: int) -> void:
	var source: Rect2 = FERN_CROPS[seed%4]
	var height := width*source.size.y/source.size.x
	canvas.draw_texture_rect_region(FERNS,Rect2(foot-Vector2(width*0.5,height),Vector2(width,height)),source,Color("e2edd2"))

static func draw_structure(canvas: Node2D, kind: int, rect: Rect2, tint: Color = Color.WHITE) -> void:
	var source: Rect2 = STRUCTURE_CROPS[kind]
	assert(is_equal_approx(rect.size.x/source.size.x,rect.size.y/source.size.y),"Structure art must keep a uniform scale")
	if not STRUCTURE_CONTOURS.has(kind):
		canvas.draw_texture_rect_region(STRUCTURES,rect,source,tint)
		return
	var vertices := PackedVector2Array()
	var uv := PackedVector2Array()
	var scale_factor := rect.size.x/source.size.x
	for point in STRUCTURE_CONTOURS[kind]:
		vertices.append(rect.position+(point-source.position)*scale_factor)
		uv.append(point/STRUCTURES.get_size())
	canvas.draw_polygon(vertices,PackedColorArray([tint]),uv,STRUCTURES)

static func draw_totem(canvas: Node2D, position: Vector2, system: int, restored: bool, time: float) -> void:
	var source: Rect2 = TOTEM_CROPS[system + (4 if restored else 0)]
	# The visual stands above the objective's walkable point. The pad still marks
	# its footprint, while Lia can approach the same position as before.
	var height: float = [72.0, 88.0, 94.0, 80.0][system]
	var nominal: Rect2 = TOTEM_CROPS[system]
	var width: float = height * nominal.size.x / nominal.size.y
	height = width * source.size.y / source.size.x
	position.x -= 70.0
	var destination := Rect2(position + Vector2(-width * 0.5, -23.0 - height), Vector2(width, height))
	canvas.draw_rect(Rect2(position + Vector2(-width * 0.35, -27), Vector2(width * 0.84, 8)), Color(0.03, 0.08, 0.09, 0.3))
	canvas.draw_texture_rect_region(TOTEMS, destination, source)
	if restored:
		var glint := 0.42 + 0.25 * sin(time * 3.5 + system)
		canvas.draw_circle(position + Vector2(0, -23 - height * 0.39), 2.0, Color(0.39, 0.94, 0.88, glint))

static func draw_plant(canvas: Node2D, kind: int, foot: Vector2, width: float, opacity: float = 1.0) -> void:
	var source: Rect2 = PLANT_CROPS[kind]
	var height := width * source.size.y / source.size.x
	var destination := Rect2(foot - Vector2(width * 0.5, height), Vector2(width, height))
	canvas.draw_texture_rect_region(VEGETATION, destination, source, Color(1, 1, 1, opacity))

static func draw_shoreline(canvas: Node2D, region: Rect2, sector: int, view: Rect2, restored: int, time: float = 0.0) -> void:
	# Dense plants stay in the water and at the concrete lip, leaving the
	# courtyard interior, objective approaches and bridge mouths clear.
	for edge in 2:
		for column in range(10):
			var x := region.position.x + 63 + column * (region.size.x - 126) / 9.0
			if _bridge_column(sector, x):
				continue
			var y := region.position.y + 2 if edge == 0 else region.end.y + 45
			var foot := Vector2(x + ((column * 17 + sector * 13) % 19) - 9, y)
			if not view.grow(90).has_point(foot):
				continue
			var kind: int = [0, 1, 9, 0, 6][(column * 3 + edge + sector) % 5]
			if sector == 0 and restored == 0 and column == 2:
				kind = 11
			var width:=38.0+float((column*7+sector*5)%20)
			WaterSurface.draw_plant_contact(canvas,foot,width,time)
			draw_plant(canvas,kind,foot,width)
	for side in 2:
		for row in range(8):
			var y := region.position.y + 52 + row * (region.size.y - 104) / 7.0
			if (sector == 1 or sector == 2) and y > 490 and y < 720:
				continue
			var x := region.position.x - 12 if side == 0 else region.end.x + 10
			var foot := Vector2(x,y + (row * 11 + sector * 7) % 13 - 6)
			if not view.grow(80).has_point(foot):
				continue
			var kind: int = [0,1,9,6][(row+side+sector)%4]
			var width:=39.0+float(row%3)*7.0
			WaterSurface.draw_plant_contact(canvas,foot,width,time)
			draw_plant(canvas,kind,foot,width)
			if row%3 == 0:
				var floating_x := region.position.x - 42 if side == 0 else region.end.x + 78
				var floating_foot:=Vector2(floating_x+round(sin(time*0.33+row)*1.5),foot.y+13)
				WaterSurface.draw_plant_contact(canvas,floating_foot,32,time)
				draw_plant(canvas,3,floating_foot,32)

static func _bridge_column(sector: int, x: float) -> bool:
	return (sector <= 1 and x > 660 and x < 875) or (sector >= 2 and x > 1930 and x < 2150)
