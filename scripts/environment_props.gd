class_name P17EnvironmentProps
extends RefCounted
## One placement record supplies art, ground contact, collision and depth.
const StationArt = preload("res://scripts/station_art.gd")
const ATLAS: Texture2D = preload("res://assets/environment/props/industrial_props_atlas.png")
const CROPS: Array[Rect2] = [
	Rect2(62,74,373,379), Rect2(516,110,361,342),
	Rect2(963,90,355,354), Rect2(1452,104,225,343),
	Rect2(31,499,429,343), Rect2(526,481,306,367),
	Rect2(910,500,432,332), Rect2(1415,491,340,343),
]
# Footprints are measured fractions of the visible source, not its full box.
# Explicit category profiles keep upper equipment and transparent corners free.
const PROFILES := {
	"crate": {"art":0,"width":52.0,"contact":Rect2(0.12,0.70,0.76,0.25)},
	"open_crate": {"art":1,"width":54.0,"contact":Rect2(0.10,0.64,0.80,0.31)},
	"stacked_crates": {"art":2,"width":66.0,"contact":Rect2(0.09,0.72,0.82,0.23)},
	"barrel": {"art":3,"width":34.0,"contact":Rect2(0.12,0.79,0.76,0.17)},
	"pallet": {"art":4,"width":66.0,"contact":Rect2(0.06,0.60,0.90,0.34)},
	"cabinet": {"art":5,"width":55.0,"contact":Rect2(0.04,0.84,0.91,0.13)},
	"barrier": {"art":6,"width":76.0,"contact":Rect2(0.05,0.78,0.90,0.17)},
	"spool": {"art":7,"width":62.0,"contact":Rect2(0.05,0.74,0.91,0.22)},
	"tank": {"station":1,"width":90.0,"contact":Rect2(0.06,0.79,0.88,0.18)},
	"pump": {"station":2,"width":83.0,"contact":Rect2(0.08,0.68,0.87,0.28)},
	"battery": {"station":4,"width":126.0,"contact":Rect2(0.07,0.79,0.86,0.18)},
	"control_room": {"station":3,"width":225.0,"contact":Rect2(0.06,0.73,0.87,0.23)},
	"purifier": {"station":5,"width":137.0,"contact":Rect2(0.06,0.70,0.88,0.26)},
	"manifold": {"station":4,"width":126.0,"contact":Rect2(0.06,0.77,0.88,0.19)},
	"clarifier": {"station":0,"width":256.0,"contact":Rect2(0.04,0.48,0.92,0.46)},
}

static func supports(kind: String) -> bool:
	return PROFILES.has(kind)

static func create(kind: String, foot: Vector2, width: float = 0.0) -> Dictionary:
	var profile: Dictionary = PROFILES[kind]
	var source: Rect2 = CROPS[profile.art] if profile.has("art") else StationArt.STRUCTURE_CROPS[profile.station]
	var actual_width: float = profile.width if width <= 0.0 else width
	var size := Vector2(actual_width, actual_width * source.size.y / source.size.x)
	var visual := Rect2(foot - Vector2(size.x * 0.5, size.y), size)
	var contact: Rect2 = profile.contact
	var collision := Rect2(visual.position + contact.position * size, contact.size * size)
	return {"kind":kind,"pos":collision.get_center(),"rect":collision,
		"visual_bounds":visual,"source":source,"collision_rect":collision,
		"depth_anchor":Vector2(foot.x,collision.end.y),"solid":true,
		"station":profile.get("station",-1),"foot":foot}

static func draw_foundation(canvas: Node2D, prop: Dictionary) -> void:
	var r: Rect2 = prop.collision_rect
	var p := r.position
	var e := r.end
	canvas.draw_colored_polygon(PackedVector2Array([
		p+Vector2(5,2),Vector2(e.x-5,p.y+2),Vector2(e.x+2,p.y+r.size.y*0.5),
		e+Vector2(-3,4),Vector2(p.x+3,e.y+4),Vector2(p.x-2,p.y+r.size.y*0.5)
	]),Color(0.02,0.045,0.05,0.34))
	if prop.station < 0:
		return
	# The art already contains concrete feet. Small pads extend those feet;
	# a broad filled plate would recreate the old framed-PNG silhouette.
	var pad_width := clampf(r.size.x*0.17,8,30)
	for x in [p.x+4,e.x-pad_width-4]:
		canvas.draw_colored_polygon(PackedVector2Array([
			Vector2(x,e.y-3),Vector2(x+pad_width-2,e.y-3),
			Vector2(x+pad_width,e.y+4),Vector2(x+2,e.y+4)
		]),Color("626659",0.75))
		canvas.draw_line(Vector2(x+3,e.y+4),Vector2(x+pad_width-2,e.y+4),Color("92917a"),1)
		canvas.draw_rect(Rect2(x+3,e.y,2,2),Color("bea776"))
	if prop.kind in ["tank","pump","clarifier"]:
		canvas.draw_rect(Rect2(p.x-4,e.y+5,minf(r.size.x*0.46,42),3),Color("34575b",0.27))
	if prop.kind in ["clarifier","control_room","manifold"]:
		StationArt.draw_plant(canvas,4,Vector2(p.x+8,e.y+5),19,0.80)

static func draw(canvas: Node2D, prop: Dictionary, time: float) -> void:
	var texture: Texture2D = ATLAS if prop.station < 0 else StationArt.STRUCTURES
	if prop.station>=0: StationArt.draw_structure(canvas,prop.station,prop.visual_bounds)
	else: canvas.draw_texture_rect_region(texture,prop.visual_bounds,prop.source)
	if prop.kind == "cabinet":
		var visual: Rect2 = prop.visual_bounds
		canvas.draw_rect(Rect2(visual.position+visual.size*Vector2(0.66,0.46),Vector2(3,4)),Color("72dac7",0.65+0.2*sin(time*2.4)))
