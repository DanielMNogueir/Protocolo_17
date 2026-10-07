class_name P17LaboratoryWorld
extends RefCounted
const Set = preload("res://scripts/laboratory_set.gd")
const Beatrix = preload("res://scripts/beatrix_art.gd")
const Drones = preload("res://scripts/enemy_art.gd")
const SIZE := Vector2(960,640)
const ROOM := Rect2(75,205,815,350)
const START := Set.ORIGIN+Vector2(690,785)*Set.SCALE
const DIAGNOSTIC := Set.ORIGIN+Vector2(414,496)*Set.SCALE
const CALIBRATION := DIAGNOSTIC
const ANALYSIS := Set.ORIGIN+Vector2(733,395)*Set.SCALE
const RELAY := Set.ORIGIN+Vector2(321,342)*Set.SCALE
const RELAY_APPROACH := Set.ORIGIN+Vector2(381,467)*Set.SCALE
const ACTUATOR_HIT_AREA := [Vector2(287,330),Vector2(352,330),Vector2(352,422),Vector2(287,422)]
const ISOLATION := Set.ORIGIN+Vector2(381,467)*Set.SCALE
const ESCAPE := Set.ORIGIN+Vector2(1215,710)*Set.SCALE
const RETRY := Set.ORIGIN+Vector2(641,702)*Set.SCALE
const ARCHIVE := ESCAPE
const CORE := Set.ORIGIN+Vector2(910,535)*Set.SCALE
const EMITTER := Set.ORIGIN+Vector2(909,200)*Set.SCALE
const DRONES: Array[Vector2] = [Set.ORIGIN+Vector2(614,544)*Set.SCALE,Set.ORIGIN+Vector2(1190,608)*Set.SCALE]
static func solids() -> Array[PackedVector2Array]:
 var result: Array[PackedVector2Array] = []
 for unit in Set.UNITS: result.append(Set.polygon(unit.solid))
 for polygon in Set.EXTRA_SOLIDS: result.append(Set.polygon(polygon))
 return result
static func walkable(point: Vector2, radius: float = 13) -> bool:
 var floor_shape := Set.polygon(Set.FLOOR)
 if not Geometry2D.is_point_in_polygon(point,floor_shape): return false
 for i in range(floor_shape.size()):
  if point.distance_to(Geometry2D.get_closest_point_to_segment(point,floor_shape[i],floor_shape[(i+1)%floor_shape.size()]))<radius: return false
 for shape in solids():
  if Geometry2D.is_point_in_polygon(point,shape): return false
  for i in range(shape.size()):
   if point.distance_to(Geometry2D.get_closest_point_to_segment(point,shape[i],shape[(i+1)%shape.size()]))<radius: return false
 return true
static func blocks_segment(shape: PackedVector2Array, a: Vector2, b: Vector2) -> bool:
 if Geometry2D.is_point_in_polygon(a,shape) or Geometry2D.is_point_in_polygon(b,shape): return true
 for i in range(shape.size()):
  if Geometry2D.segment_intersects_segment(a,b,shape[i],shape[(i+1)%shape.size()])!=null: return true
 return false
static func camera(_position: Vector2, _viewport: Vector2) -> Vector2: return SIZE*0.5
static func shadow_casters() -> Array[Dictionary]: return [] # Shadows are baked into the coherent set.
static func draw(canvas: Node2D, state: P17Prologue, _view: Rect2, effects: P17LaboratoryEffects = null) -> void:
 canvas.draw_rect(Rect2(Vector2.ZERO,SIZE),Color("081018"))
 var texture: Texture2D = effects.scene.get_texture() if effects else null
 if texture: canvas.draw_texture_rect(texture,Rect2(Vector2.ZERO,SIZE),false)
 else: canvas.draw_texture_rect(Set.TEXTURE,Set.ART,false)
 _draw_objective_pad(canvas,state)
 var ordered: Array[Dictionary] = []
 for i in range(Set.UNITS.size()): ordered.append({"y":Set.front_y(Set.UNITS[i],state.pos.x),"unit":i})
 ordered.append({"y":state.pos.y,"beatrix":true})
 for n in range(DRONES.size()): ordered.append({"y":DRONES[n].y,"drone":n})
 ordered.sort_custom(func(a,b): return a.y<b.y)
 for entity in ordered:
  if entity.has("unit"):
   var shape := Set.polygon(Set.UNITS[entity.unit].outline)
   var uv := PackedVector2Array()
   for p in shape: uv.append(p/SIZE if texture else (p-Set.ORIGIN)/(Set.SOURCE_SIZE*Set.SCALE))
   canvas.draw_polygon(shape,PackedColorArray([Color.WHITE]),uv,texture if texture else Set.TEXTURE)
  elif entity.has("beatrix"):
   if state.phase!="ending" or state.cut_age<4.2:
    var facing := state.aim if state.velocity.length()<1 else state.velocity.normalized()
    Beatrix.draw(canvas,state.pos-Vector2(0,13),facing,state.elapsed,state.velocity.length()>1,state.invulnerable>0 and int(state.elapsed*12)%2==0)
  else:
   var n: int = entity.drone
   var p: Vector2 = DRONES[n]
   Drones.draw(canvas,{"kind":"scout","pos":p-Vector2(0,14),"hp":3,"max_hp":3,"facing":(state.pos-p).normalized() if state.step>=3 else Vector2.DOWN,"moving":false},state.elapsed)
   if state.step in [5,6] and fposmod(state.threat_age+n*1.1,3.5)>2.7: canvas.draw_line(p,state.pos,Color("f57c85",0.45),1)
   if state.phase=="ending" and state.cut_age<2.2:
    canvas.draw_line(p-Vector2(0,16),state.pos-Vector2(0,28),Color("f57c85",0.35+0.25*absf(sin(state.elapsed*14))),2)
 for bolt in state.bolts:
  canvas.draw_line(bolt.pos-bolt.vel.normalized()*9,bolt.pos,Color("ee7b89") if bolt.hostile else Color("a0f1df"),2)
 _draw_beacon(canvas,state)
static func _draw_objective_pad(canvas: Node2D, state: P17Prologue) -> void:
 if state.step>=7 or state.step==3: return
 var p: Vector2 = state.TARGETS[state.step]
 var shape := PackedVector2Array([p+Vector2(-24,0),p+Vector2(0,-11),p+Vector2(24,0),p+Vector2(0,11)])
 canvas.draw_colored_polygon(shape,Color("f3cc80",0.07))
 shape.append(shape[0])
 canvas.draw_polyline(shape,Color("f3cc80",0.7),1)
 if state.repair>0: canvas.draw_arc(p,22,-PI/2,-PI/2+state.repair*TAU,32,Color("8df2ce"),2)
static func _draw_beacon(canvas: Node2D, state: P17Prologue) -> void:
 if state.step>=7: return
 var p: Vector2 = state.TARGETS[state.step]
 var source: Vector2 = [Vector2(353,518),Vector2(353,518),Vector2(666,232),Vector2(321,327),Vector2(321,327),Vector2(1043,647),Vector2(1043,647)][state.step]
 var instrument := Set.point(source)
 var amber := Color("f3cc80")
 var top := instrument-Vector2(0,19+sin(state.elapsed*3)*2)
 canvas.draw_colored_polygon(PackedVector2Array([top+Vector2(-5,-5),top+Vector2(5,-5),top+Vector2(0,2)]),amber)
 canvas.draw_arc(instrument,13,0,TAU,24,Color(amber,0.55),1)
 if state.step!=3: canvas.draw_line(instrument+Vector2(0,14),p,Color(amber,0.3),1)
 var labels := ["DIAGNÓSTICO","E • CALIBRAR","E • CONSULTAR","PULSO • ATUADOR","E • ISOLAR","ARQUIVO","E • PRESERVAR"]
 var text: String = "EM ANDAMENTO" if state.interaction_active else labels[state.step]
 var font := ThemeDB.fallback_font
 var width := font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,10).x+16
 var anchor := instrument+Vector2(0,-43) if state.step==3 else p+Vector2(45,7)
 var rect := Rect2(anchor+Vector2(-width/2,0),Vector2(width,21))
 if rect.intersects(Rect2(state.pos-Vector2(17,60),Vector2(34,63))): rect.position.x = p.x-width-25
 canvas.draw_rect(rect,Color("0c2630",0.96))
 canvas.draw_rect(rect,amber,false,1)
 canvas.draw_string(font,rect.position+Vector2(8,14),text,HORIZONTAL_ALIGNMENT_LEFT,-1,10,amber)
