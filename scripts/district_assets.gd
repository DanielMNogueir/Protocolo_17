class_name P17DistrictAssets
extends RefCounted
## Original generated pixels; only uniformly scaled source regions are sampled.
const ATLAS: Texture2D = preload("res://assets/station/district_modules_v1.png")
const FLOOR: Texture2D = preload("res://assets/station/district_concrete_v3.png")
const WALL_H := Rect2(48,245,1098,278)
const WALL_V := Rect2(1215,180,179,350)
const GRATE := Rect2(90,582,992,364)
const CABINET := Rect2(1194,555,284,440)

static func grate(canvas: Node2D, rect: Rect2) -> void:
 canvas.draw_rect(rect,Color("162831"))
 # Flat material cutouts keep one consistent two-source-pixels-per-world-pixel scale.
 for y in range(int(rect.position.y),int(rect.end.y),48):
  for x in range(int(rect.position.x),int(rect.end.x),64):
   var tile:=Rect2(x,y,minf(64,rect.end.x-x),minf(48,rect.end.y-y))
   var source:=Rect2(GRATE.position+Vector2(40+posmod(x/64,7)*112,50+posmod(y/48,2)*112),tile.size*2)
   canvas.draw_texture_rect_region(ATLAS,tile,source,Color("ccd7d3"))
 canvas.draw_rect(rect,Color("162a32"),false,3)
 canvas.draw_line(rect.position+Vector2(2,2),Vector2(rect.end.x-2,rect.position.y+2),Color("a79877"),1)
 for x in [rect.position.x+3,rect.end.x-6]:
  for y in [rect.position.y+3,rect.end.y-6]:
   canvas.draw_rect(Rect2(x,y,3,3),Color("cab894"))
