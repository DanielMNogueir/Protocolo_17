extends SceneTree
## Shared physical lips, sector coverage and GPU shadow anchoring.
const W=preload("res://scripts/world.gd")
const Lighting=preload("res://scripts/district_lighting.gd")
const Assets=preload("res://scripts/district_assets.gd")
class Preview extends Node2D:
 var effects: P17DistrictLighting
 var offset:=Vector2(-240,-980)
 func _draw() -> void:
  draw_rect(Rect2(Vector2.ZERO,Vector2(960,540)),Color("789397"))
  draw_set_transform(offset)
  effects.draw_ground(self)
  draw_set_transform(Vector2.ZERO)
  draw_rect(Rect2(30,30,40,40),Color("e3b65c"))
var checks:=0
var failures: Array[String]=[]
func _initialize() -> void: _run.call_deferred()
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok: failures.append(message)
func difference(a: Color,b: Color) -> float:
 return maxf(absf(a.r-b.r),maxf(absf(a.g-b.g),absf(a.b-b.b)))
func frame(preview: Preview,time: float) -> Image:
 preview.effects.present(time,0)
 preview.queue_redraw()
 for n in range(5):
  await process_frame
  await RenderingServer.frame_post_draw
 return root.get_texture().get_image()
func _run() -> void:
 W.prepare_wetlands()
 var coverage: Array[int]=[0,0,0,0]
 for wall in W.Architecture.walls:
  check(Rect2(Vector2.ZERO,Assets.ATLAS.get_size()).encloses(wall.source),"Wall samples stay inside the original atlas")
  check(is_equal_approx(wall.visual_bounds.size.x/wall.source.size.x,wall.visual_bounds.size.y/wall.source.size.y),"Wall modules retain uniform scale")
  check(not W.walkable(wall.collision_rect.get_center(),1,3),"Rendered retaining lip blocks feet")
  for i in range(4):
   if W.REGIONS[i].grow(8).has_point(wall.collision_rect.get_center()): coverage[i]+=1
 for i in range(4): check(coverage[i]>20,"Every sector has architectural coverage")
 for bridge in W.BRIDGES:
  var direction:=Vector2.DOWN if bridge.size.y>bridge.size.x else Vector2.RIGHT
  var half: float=(bridge.size.y if bridge.size.y>bridge.size.x else bridge.size.x)*0.5
  for t in range(21):
   check(W.walkable(bridge.get_center()+direction*lerpf(-half-24,half+24,t/20.0),14,3),"New parapets leave bridge approaches open")
 var cabinets:=0
 for p in W.props():
  if p.kind!="service_rack": continue
  cabinets+=1
  check(p.visual_bounds.grow(2).encloses(p.collision_rect),"Control cabinet has a grounded physical base")
  check(not W.walkable(p.collision_rect.get_center(),1,3),"Control cabinet cannot be crossed")
 check(cabinets==4,"Each sector has its own control cabinet")
 root.content_scale_size=Vector2i(960,540)
 root.size=Vector2i(960,540)
 var preview:=Preview.new()
 preview.effects=Lighting.new()
 preview.effects.configure()
 preview.add_child(preview.effects)
 root.add_child(preview)
 check(preview.effects.caster_count>300,"Architecture and equipment cast shadows together")
 var mask:=preview.effects.field_image
 check(mask.get_pixel(149,287).g>0.1,"Contact shadow attaches to the captação cabinet base")
 check(mask.get_pixel(155,290).r>0.3,"Raised cabinet casts beyond its ground footprint")
 var a: Image=await frame(preview,7)
 var atlas_a:=preview.effects.atlas.get_texture().get_image()
 preview.offset-=Vector2(32,16)
 var b: Image=await frame(preview,7)
 var changed:=0
 for y in range(130,460,15):
  for x in range(170,680,15):
   check(difference(a.get_pixel(x,y),b.get_pixel(x-32,y-16))<0.009,"Lighting remains anchored during camera movement")
 check(difference(a.get_pixel(50,50),Color("e3b65c"))<0.009,"World lighting leaves the interface untouched")
 await frame(preview,10)
 var atlas_b:=preview.effects.atlas.get_texture().get_image()
 for y in range(550,580):
  for x in range(250,340):
   if difference(atlas_a.get_pixel(x,y),atlas_b.get_pixel(x,y))>0.007: changed+=1
 check(changed>30,"Wet banks and cabinet lamps produce visible shader motion")
 preview.effects.present(10,0,false)
 check(preview.effects.atlas.render_target_update_mode==SubViewport.UPDATE_DISABLED,"Offscreen lighting can stop outside campaign scenes")
 print("DISTRICT_ARCHITECTURE_%s: %d checks; sectors=%s; moving=%d; setup_ms=%.1f"%["OK" if failures.is_empty() else "FAILED",checks,coverage,changed,preview.effects.setup_usec/1000.0])
 for failure in failures: push_error(failure)
 preview.free()
 for n in range(3): await process_frame
 quit(0 if failures.is_empty() else 1)
