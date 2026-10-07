class_name P17DistrictLighting
extends Node
const World = preload("res://scripts/world.gd")
const SURFACE = preload("res://scripts/district_lighting.gdshader")
const SIZE := Vector2(2560,1800)
const LAMPS: Array[Vector2] = [Vector2(590,1150),Vector2(640,435),Vector2(2015,340),Vector2(1820,1180)]
var atlas: SubViewport
var material: ShaderMaterial
var field_image: Image
var setup_usec:=0
var caster_count:=0
func _init() -> void:
 atlas=SubViewport.new()
 atlas.size=Vector2i(1280,900)
 atlas.disable_3d=true
 atlas.transparent_bg=true
 atlas.render_target_update_mode=SubViewport.UPDATE_DISABLED
 add_child(atlas)
 var white:=Image.create(1,1,false,Image.FORMAT_RGBA8)
 white.fill(Color.WHITE)
 var sprite:=Sprite2D.new()
 sprite.centered=false
 sprite.texture=ImageTexture.create_from_image(white)
 sprite.scale=Vector2(1280,900)
 material=ShaderMaterial.new()
 material.shader=SURFACE
 material.set_shader_parameter("lamps",PackedVector2Array(LAMPS))
 sprite.material=material
 atlas.add_child(sprite)
func configure() -> void:
 var started:=Time.get_ticks_usec()
 World.prepare_wetlands()
 # Moisture changes smoothly: calculate it at eight world pixels per sample.
 # Contact and cast shadows retain the finer four-pixel raster below.
 field_image=Image.create(320,225,false,Image.FORMAT_RGBA8)
 for y in range(225):
  for x in range(320):
   var p:=Vector2(x*8+4,y*8+4)
   var land:=false
   var distance:=999.0
   for r in World.REGIONS:
    if r.has_point(p):
     land=true
     distance=minf(minf(p.x-r.position.x,r.end.x-p.x),minf(p.y-r.position.y,r.end.y-p.y))
   for r in World.Wetlands.CHANNELS:
    if r.has_point(p): land=false
    distance=minf(distance,p.distance_to(p.clamp(r.position,r.end)))
   for r in World.BASINS:
    if r.has_point(p): land=false
    distance=minf(distance,p.distance_to(p.clamp(r.position,r.end)))
   var wet:=exp(-maxf(0,distance)/47.0) if land else 0.0
   field_image.set_pixel(x,y,Color(0,0,wet,1.0 if land else 0.0))
 field_image.resize(640,450,Image.INTERPOLATE_BILINEAR)
 var casters: Array[Dictionary] = []
 for p in World.props():
  if p.solid: casters.append({"rect":p.collision_rect,"height":p.visual_bounds.size.y})
 for p in World.building_objects(): casters.append({"rect":p.collision_rect,"height":p.visual_bounds.size.y})
 var clarifier:=World.clarifier()
 casters.append({"rect":clarifier.collision_rect,"height":clarifier.visual_bounds.size.y})
 for i in [0,2,3]:
  var p:=World.terminal(i)
  casters.append({"rect":p.collision_rect,"height":p.visual_bounds.size.y})
 for r in World.EnergyStation.COLLISION_RECTS: casters.append({"rect":r,"height":70.0})
 for r in World.BRIDGES:
  for base in World.BridgeLayout.collision_rects(r): casters.append({"rect":base,"height":27.0})
 for wall in World.Architecture.walls: casters.append({"rect":wall.collision_rect,"height":wall.height})
 for caster in casters: _stamp(caster.rect,caster.height)
 caster_count=casters.size()
 material.set_shader_parameter("field",ImageTexture.create_from_image(field_image))
 setup_usec=Time.get_ticks_usec()-started
func _stamp(base: Rect2,height: float) -> void:
 var shift:=Vector2(0.55,0.38)*clampf(height,16,135)
 var corners:=PackedVector2Array([base.position,Vector2(base.end.x,base.position.y),base.end,Vector2(base.position.x,base.end.y)])
 var volume:=corners.duplicate()
 for p in corners: volume.append(p+shift)
 volume=Geometry2D.convex_hull(volume)
 var bounds:=Rect2(base.position-Vector2(8,8),base.size+shift+Vector2(16,16))
 for y in range(maxi(0,int(bounds.position.y/4)),mini(450,int(ceil(bounds.end.y/4)))):
  for x in range(maxi(0,int(bounds.position.x/4)),mini(640,int(ceil(bounds.end.x/4)))):
   var p:=Vector2(x*4+2,y*4+2)
   var d:=p.distance_to(p.clamp(base.position,base.end))
   var value:=field_image.get_pixel(x,y)
   value.g=maxf(value.g,exp(-d/4.0)*0.65)
   if Geometry2D.is_point_in_polygon(p,volume): value.r=maxf(value.r,0.82-clampf(d/(shift.length()+1),0,1)*0.4)
   field_image.set_pixel(x,y,value)
func present(time: float,systems: int,active: bool=true) -> void:
 atlas.render_target_update_mode=SubViewport.UPDATE_ALWAYS if active else SubViewport.UPDATE_DISABLED
 material.set_shader_parameter("scene_time",time)
 material.set_shader_parameter("restored",float(systems))
func draw_ground(canvas: Node2D) -> void:
 canvas.draw_texture_rect(atlas.get_texture(),Rect2(Vector2.ZERO,SIZE),false)
