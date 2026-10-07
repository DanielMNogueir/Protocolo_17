class_name P17DistrictArchitecture
extends RefCounted
## Authored engineering bays and continuous retaining walls with real crossing gaps.
const Assets = preload("res://scripts/district_assets.gd")
const ZONES := [
 ["CAPTAÇÃO",Rect2(196,1050,254,110)],["MANUTENÇÃO",Rect2(485,1222,106,99)],
 ["CARGA",Rect2(198,1464,212,126)],["ENERGIA",Rect2(240,478,410,96)],
 ["FILTRAGEM",Rect2(2068,181,305,164)],["INSUMOS",Rect2(1498,445,149,87)],
 ["DISTRIBUIÇÃO",Rect2(1512,1130,324,76)],["RESERVA",Rect2(1515,1552,129,84)],
 ]
static var walls: Array[Dictionary] = []

static func prepare(regions: Array[Rect2], channels: Array[Rect2], bridges: Array[Rect2], crossings: Array[Rect2], pier: Rect2, basins: Array[Rect2] = []) -> void:
 if not walls.is_empty(): return
 var passages: Array[Rect2] = bridges.duplicate()
 passages.append_array(crossings)
 passages.append(pier)
 var features: Array[Rect2] = channels.duplicate()
 for index in range(1,basins.size()): features.append(basins[index])
 for region in regions:
  for side in range(4):
   var horizontal:=side<2
   var origin:=Vector2(region.position.x,region.position.y+3 if side==0 else region.end.y+3) if horizontal else Vector2(region.position.x if side==2 else region.end.x,region.position.y)
   var length:=region.size.x if horizontal else region.size.y
   var cuts: Array[Rect2] = passages.duplicate()
   cuts.append_array(features)
   _edge(origin,length,horizontal,side,cuts,140.0,true)
 for i in range(features.size()):
  var r:=features[i]
  for side in range(4):
   var horizontal:=side<2
   var origin:=Vector2(r.position.x,r.position.y if side==0 else r.end.y) if horizontal else Vector2(r.position.x if side==2 else r.end.x,r.position.y)
   var cuts: Array[Rect2] = passages.duplicate()
   for j in range(features.size()):
    if j!=i: cuts.append(features[j].grow(3))
   _edge(origin,r.size.x if horizontal else r.size.y,horizontal,side,cuts,76.0,false)

static func _edge(origin: Vector2,length: float,horizontal: bool,side: int,cuts: Array[Rect2],module: float,outer: bool) -> void:
 var segments: Array[Vector2] = [Vector2(0,length)]
 for cut in cuts:
  var line:=Rect2(origin-Vector2(2,2),Vector2(length+4,4) if horizontal else Vector2(4,length+4))
  if not line.intersects(cut.grow(5)): continue
  var lo:=cut.position.x-origin.x-7 if horizontal else cut.position.y-origin.y-7
  var hi:=cut.end.x-origin.x+7 if horizontal else cut.end.y-origin.y+7
  var remaining: Array[Vector2] = []
  for interval in segments:
   if hi<=interval.x or lo>=interval.y: remaining.append(interval); continue
   if lo>interval.x: remaining.append(Vector2(interval.x,lo))
   if hi<interval.y: remaining.append(Vector2(hi,interval.y))
  segments=remaining
 for interval in segments:
  var cursor:=interval.x
  while cursor<interval.y-1:
   var extent:=minf(module,interval.y-cursor)
   var source:=Assets.WALL_H if horizontal else Assets.WALL_V
   var scale_value:=module/source.size.x if horizontal else (76.0 if outer else 46.0)/source.size.y
   if not horizontal: extent=minf(76.0 if outer else 46.0,interval.y-cursor)
   var size:=Vector2(extent,source.size.y*scale_value) if horizontal else Vector2(source.size.x*scale_value,extent)
   var foot:=origin+(Vector2(cursor,0) if horizontal else Vector2(0,cursor))
   var visual:=Rect2(foot-Vector2(0,size.y),size) if horizontal else Rect2(foot+Vector2(-size.x+3 if side==2 else -3,0),size)
   if not outer and horizontal and side==0: visual.position.y=foot.y-3
   if not outer and horizontal and side==1: visual.position.y=foot.y-size.y+3
   if not outer and not horizontal: visual.position.x=foot.x-3 if side==2 else foot.x-size.x+3
   var sample:=Rect2(source.position,size/scale_value)
   var base:=Rect2(Vector2(visual.position.x,foot.y-3),Vector2(size.x,6)) if horizontal else Rect2(foot+Vector2(-3,0),Vector2(6,extent))
   walls.append({"type":"district_wall","visual_bounds":visual,"source":sample,"collision_rect":base,"y":base.end.y,"height":size.y if horizontal else 22.0,"outer":outer})
   cursor+=extent

static func parts(view: Rect2) -> Array[Dictionary]:
 var result: Array[Dictionary] = []
 for wall in walls:
  if wall.visual_bounds.grow(30).intersects(view): result.append(wall)
 return result

static func draw_wall(canvas: Node2D,wall: Dictionary) -> void:
 canvas.draw_texture_rect_region(Assets.ATLAS,wall.visual_bounds,wall.source,Color("bccfc9") if wall.outer else Color("a5bdb5"))

static func draw_ground(canvas: Node2D,view: Rect2) -> void:
 for zone in ZONES:
  var r: Rect2=zone[1]
  if not r.intersects(view): continue
  # A bay is a usable floor finish; only the actual machine bases are solid.
  canvas.draw_rect(r,Color("20343b",0.22))
  for corner in [r.position,Vector2(r.end.x,r.position.y),r.end,Vector2(r.position.x,r.end.y)]:
   var dx:=12 if corner.x==r.position.x else -12
   var dy:=9 if corner.y==r.position.y else -9
   canvas.draw_line(corner,corner+Vector2(dx,0),Color("b3a36d",0.65),2)
   canvas.draw_line(corner,corner+Vector2(0,dy),Color("b3a36d",0.65),2)
  canvas.draw_string(ThemeDB.fallback_font,r.position+Vector2(7,r.size.y-7),zone[0],HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("b6b8a0",0.7))
 for path in [
  [Vector2(590,1150),Vector2(590,1190),Vector2(533,1190),Vector2(533,1292)],
  [Vector2(640,435),Vector2(522,435),Vector2(522,417)],
  [Vector2(2015,340),Vector2(2015,360),Vector2(2136,360),Vector2(2136,430)],
  [Vector2(1820,1180),Vector2(1840,1180),Vector2(1840,1390)]]:
  for n in range(path.size()-1):
   var a: Vector2=path[n]
   var b: Vector2=path[n+1]
   if not Rect2(a.min(b),(a-b).abs()).grow(8).intersects(view): continue
   canvas.draw_line(a+Vector2(2,3),b+Vector2(2,3),Color("071924",0.5),7)
   canvas.draw_line(a,b,Color("3c535a"),5)
   canvas.draw_line(a-Vector2(1,1),b-Vector2(1,1),Color("98a299"),1)
