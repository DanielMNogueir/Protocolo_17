extends SceneTree
const Intro = preload("res://scripts/prologue.gd")
const Lab = preload("res://scripts/laboratory_world.gd")
const Art = preload("res://scripts/beatrix_art.gd")
var checks := 0
var failures: Array[String] = []
class View extends Node2D:
 var story: P17Prologue
 var effects := P17LaboratoryEffects.new()
 var offset := Vector2(0,-50)
 func _ready() -> void: add_child(effects)
 func _draw() -> void:
  effects.present(story.elapsed,story.step>=3)
  draw_set_transform(offset)
  Lab.draw(self,story,Rect2(Vector2.ZERO,Lab.SIZE),effects)
func _initialize() -> void: _run.call_deferred()
func check(ok: bool,label: String) -> void:
 checks += 1
 if not ok: failures.append(label)
func delta(a: Color,b: Color) -> float: return maxf(absf(a.r-b.r),maxf(absf(a.g-b.g),absf(a.b-b.b)))
func capture(view: View, time: float) -> Image:
 view.story.elapsed=time
 for n in range(4):
  view.queue_redraw()
  await process_frame
 await RenderingServer.frame_post_draw
 return root.get_texture().get_image()
func changed(a: Image,b: Image,rect: Rect2i,threshold: float=0.015) -> int:
 var count:=0
 for y in range(rect.position.y,rect.end.y):
  for x in range(rect.position.x,rect.end.x):
   if delta(a.get_pixel(x,y),b.get_pixel(x,y))>threshold: count+=1
 return count
func _run() -> void:
 root.content_scale_size=Vector2i(960,540)
 root.size=Vector2i(960,540)
 var view:=View.new()
 view.story=Intro.new()
 view.story.phase="lab"
 view.story.pos=Lab.START
 root.add_child(view)
 var a:=await capture(view,12)
 var surface_a:=view.effects.scene.get_texture().get_image()
 var b:=await capture(view,12.4)
 var surface_b:=view.effects.scene.get_texture().get_image()
 for area in [Rect2i(490,200,130,100),Rect2i(400,130,55,45),Rect2i(100,220,55,65)]:
  check(changed(surface_a,surface_b,area,0.003)>20,"Glass / displays animate on their real equipment surfaces "+str(area))
 var moving:=changed(a,b,Rect2i(80,130,790,340))
 check(moving>100,"Visible room materials and maintenance drones animate")
 view.offset+=Vector2(20,12)
 var shifted:=await capture(view,12.4)
 for y in range(70,470,20):
  for x in range(40,860,20):
   check(delta(b.get_pixel(x,y),shifted.get_pixel(x+20,y+12))<0.012,"Room cutouts and scientist remain anchored when camera moves")
 view.story.step=7
 var red:=await capture(view,12.4)
 check(changed(red,shifted,Rect2i(400,130,250,280))>500,"Containment changes core glass, instruments and reflected light")
 view.offset=Vector2(0,-50)
 view.story.pos=Lab.Set.point(Vector2(925,435))
 check(Lab.walkable(view.story.pos),"Depth test uses a real accessible position behind the core")
 view.story.phase="ending"
 view.story.cut_age=4.5
 var hidden:=await capture(view,12)
 view.story.phase="lab"
 var behind:=await capture(view,12)
 var rect:=Rect2i(Vector2i(view.story.pos+view.offset-Vector2(18,58)),Vector2i(36,60))
 check(changed(hidden,behind,rect)<5,"The core actually occludes the scientist standing behind it")
 view.story.pos=Lab.Set.point(Vector2(918,660))
 check(Lab.walkable(view.story.pos),"Front depth test uses an accessible floor position")
 view.story.phase="ending"
 var clear:=await capture(view,12)
 view.story.phase="lab"
 var front:=await capture(view,12)
 rect=Rect2i(Vector2i(view.story.pos+view.offset-Vector2(18,58)),Vector2i(36,60))
 check(changed(clear,front,rect)>250,"Scientist standing in front of the core remains visible")
 for target in [Lab.START,Lab.CALIBRATION,Lab.ANALYSIS,Lab.ISOLATION,Lab.ARCHIVE,Lab.RETRY]:
  check(Lab.walkable(target),"Published interaction / recovery position lies on clear floor")
 check(not Lab.walkable(Lab.CORE),"Scientist cannot stand inside the core pedestal")
 check(not Lab.walkable(Vector2(900,500)),"Scientist cannot walk beyond the isometric platform")
 for unit in Lab.Set.UNITS:
  var shape:=Lab.Set.polygon(unit.outline)
  check(not Geometry2D.triangulate_polygon(shape).is_empty(),"Foreground silhouette triangulates: "+unit.name)
 check(Art.DATA.FRAMES.size()==24,"Scientist supplies eight directions and three poses")
 for frame in Art.DATA.FRAMES:
  check(Rect2(Vector2.ZERO,Art.SHEET.get_size()).encloses(frame.region),"Scientist pose remains inside its original atlas")
  check(frame.anchor.y==frame.region.end.y,"Every pose retains its measured foot anchor")
 print("PROLOGUE_RENDERING_%s: %d checks; %d animated pixels; %d failures" % ["OK" if failures.is_empty() else "FAILED",checks,moving,failures.size()])
 for failure in failures: push_error(failure)
 view.free()
 await process_frame
 quit(0 if failures.is_empty() else 1)
