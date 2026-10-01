class_name P17StationArt
extends RefCounted
## Approved water-treatment-station concept art, placed without changing world geometry.

const FLOOR: Texture2D = preload("res://assets/station/stone_surface.png")
const STRUCTURES: Texture2D = preload("res://assets/station/structures_atlas.png")
const TOTEMS: Texture2D = preload("res://assets/station/totems_atlas.png")
const VEGETATION: Texture2D = preload("res://assets/station/vegetation_atlas.png")

# Tight source bounds of the six isolated concepts: clarifier, filters, pump,
# control room, pipe manifold and purifier. Cropping happens only while drawing.
const STRUCTURE_CROPS := [
	Rect2(12, 216, 498, 462), Rect2(510, 176, 365, 488),
	Rect2(875, 331, 365, 354), Rect2(16, 724, 436, 416),
	Rect2(459, 735, 416, 438), Rect2(875, 820, 364, 346),
]
const TOTEM_CROPS := [
	Rect2(31, 334, 283, 273), Rect2(314, 199, 314, 395),
	Rect2(628, 161, 314, 443), Rect2(942, 279, 287, 348),
	Rect2(28, 840, 286, 267), Rect2(314, 688, 314, 404),
	Rect2(628, 662, 314, 441), Rect2(942, 627, 288, 497),
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
	var color: Color = [Color("796d5d"),Color("6e7165"),Color("74766b"),Color("6a746d")][sector]
	canvas.draw_rect(rect,color)

static func draw_floor_tile(canvas: Node2D, tile: Rect2, seed: int, sector: int) -> void:
	var sample_width := int(tile.size.x * 1.65)
	var sample_height := int(tile.size.y * 1.65)
	var source := Rect2(29 + posmod(seed * 61, 1190 - sample_width),
		23 + posmod(seed * 97, 1200 - sample_height), sample_width, sample_height)
	var tint: Color = [Color("e8e1d4"),Color("d7ded5"),Color("d9dcd5"),Color("d1ddd7")][sector]
	canvas.draw_texture_rect_region(FLOOR,tile,source,tint)
	canvas.draw_rect(Rect2(tile.position+Vector2(2,1),Vector2(maxf(0,tile.size.x-4),1)),Color("d2c6a9",0.14))
	canvas.draw_rect(Rect2(tile.position+Vector2(0,tile.size.y-1),Vector2(tile.size.x,1)),Color("393e3a",0.24))
	canvas.draw_rect(Rect2(tile.position+Vector2(tile.size.x-1,0),Vector2(1,tile.size.y)),Color("3d413d",0.19))
	if seed%7 == 0:
		canvas.draw_rect(Rect2(tile.position+Vector2(2,2),Vector2(4,2)),Color("658045",0.60))

static func draw_structure(canvas: Node2D, kind: int, rect: Rect2, tint: Color = Color.WHITE) -> void:
	canvas.draw_texture_rect_region(STRUCTURES, rect, STRUCTURE_CROPS[kind], tint)

static func draw_totem(canvas: Node2D, position: Vector2, system: int, restored: bool, time: float) -> void:
	var source: Rect2 = TOTEM_CROPS[system + (4 if restored else 0)]
	# The visual stands above the objective's walkable point. The pad still marks
	# its footprint, while Lia can approach the same position as before.
	var height: float = [72.0, 88.0, 94.0, 80.0][system]
	var width: float = height * source.size.x / source.size.y
	var destination := Rect2(position + Vector2(-width * 0.5, 18.0 - height), Vector2(width, height))
	canvas.draw_rect(Rect2(position + Vector2(-width * 0.42, 15), Vector2(width * 0.84, 8)), Color(0.03, 0.08, 0.09, 0.3))
	canvas.draw_texture_rect_region(TOTEMS, destination, source)
	if restored:
		var glint := 0.42 + 0.25 * sin(time * 3.5 + system)
		canvas.draw_circle(position + Vector2(0, -height * 0.39), 2.0, Color(0.39, 0.94, 0.88, glint))

static func draw_plant(canvas: Node2D, kind: int, foot: Vector2, width: float, opacity: float = 1.0) -> void:
	var source: Rect2 = PLANT_CROPS[kind]
	var height := width * source.size.y / source.size.x
	var destination := Rect2(foot - Vector2(width * 0.5, height), Vector2(width, height))
	canvas.draw_texture_rect_region(VEGETATION, destination, source, Color(1, 1, 1, opacity))

static func draw_shoreline(canvas: Node2D, region: Rect2, sector: int, view: Rect2, restored: int) -> void:
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
			draw_plant(canvas, kind, foot, 38.0 + float((column * 7 + sector * 5) % 20))
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
			draw_plant(canvas,kind,foot,39.0 + float(row%3)*7.0)
			if row%3 == 0:
				var floating_x := region.position.x - 42 if side == 0 else region.end.x + 78
				draw_plant(canvas,3,Vector2(floating_x,foot.y+13),32)

static func _bridge_column(sector: int, x: float) -> bool:
	return (sector <= 1 and x > 660 and x < 875) or (sector >= 2 and x > 1930 and x < 2150)
