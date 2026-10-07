class_name P17WaterSurface
extends Node2D
## One background quad. The small depth/flow/shadow field is built once at startup.
const WATER_SHADER = preload("res://scripts/water_surface.gdshader")
const FIELD_STEP := 4
const DEPTH_RANGE := 128.0
var world_size := Vector2.ZERO
var field_image: Image
var field_texture: ImageTexture
var water_material: ShaderMaterial
var setup_usec := 0
var pool_viewport: SubViewport
var pool_material: ShaderMaterial
var pool_regions: Array[Rect2]=[]
var service_channel_offset := 0

func configure(size: Vector2, banks: Array[Rect2], bridges: Array[Rect2], pier: Rect2, pools: Array[Rect2]=[], service_channels: Array[Rect2]=[]) -> void:
	var start := Time.get_ticks_usec()
	world_size=size
	show_behind_parent=true
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	field_image=Image.create(int(size.x/FIELD_STEP),int(size.y/FIELD_STEP),false,Image.FORMAT_RGB8)
	for y in range(field_image.get_height()):
		for x in range(field_image.get_width()):
			var p:=Vector2((x+0.5)*FIELD_STEP,(y+0.5)*FIELD_STEP)
			var distance:=DEPTH_RANGE
			for bank in banks: distance=minf(distance,p.distance_to(p.clamp(bank.position,bank.end)))
			# The east/west waterway crosses the vertical trunk at the central junction.
			var horizontal:=maxf(1.0-smoothstep(65,140,p.y),smoothstep(1630,1700,p.y))
			horizontal=maxf(horizontal,smoothstep(800,860,p.y)*(1.0-smoothstep(1000,1060,p.y)))
			var shadow:=0.0
			for bridge in bridges:
				var r:=Rect2(bridge.position+Vector2(12,12),bridge.size)
				var d:=p.distance_to(p.clamp(r.position,r.end))
				shadow=maxf(shadow,1.0-clampf(d/14.0,0,1))
			var pier_shadow:=Rect2(pier.position+Vector2(8,9),pier.size)
			shadow=maxf(shadow,(1.0-clampf(p.distance_to(p.clamp(pier_shadow.position,pier_shadow.end))/10,0,1))*0.85)
			field_image.set_pixel(x,y,Color(distance/DEPTH_RANGE,horizontal,shadow))
	field_texture=ImageTexture.create_from_image(field_image)
	var noise:=FastNoiseLite.new()
	noise.seed=1703
	noise.frequency=0.022
	noise.fractal_octaves=3
	var texture:=NoiseTexture2D.new()
	texture.width=256
	texture.height=256
	texture.seamless=true
	texture.generate_mipmaps=false
	texture.noise=noise
	water_material=ShaderMaterial.new()
	water_material.shader=WATER_SHADER
	water_material.set_shader_parameter("field_texture",field_texture)
	water_material.set_shader_parameter("surface_noise",texture)
	water_material.set_shader_parameter("world_size",world_size)
	material=water_material
	if not pools.is_empty(): _prepare_pools(pools,service_channels)
	setup_usec=Time.get_ticks_usec()-start
	queue_redraw()

func _prepare_pools(pools: Array[Rect2], service_channels: Array[Rect2]) -> void:
	# One tiny shared render texture lets the existing immediate-mode renderer
	# place animated water between the basin floor and its rim/plants.
	var atlas_size:=Vector2i(288,384)
	var region_sizes: Array[Vector2] = []
	for index in range(1,pools.size()):
		var inner:=pools[index].grow(-8)
		region_sizes.append(inner.size)
	service_channel_offset = region_sizes.size()
	for channel in service_channels:
		var inner := channel.grow(-3)
		region_sizes.append(inner.size)
	if service_channels.is_empty():
		var y := 0.0
		for size in region_sizes:
			pool_regions.append(Rect2(Vector2(0,y),size))
			y += size.y+16
	else:
		# Shelf packing shares the new lakes with the existing reservoirs without
		# paying for a several-thousand-pixel vertical strip of empty render space.
		atlas_size.x = 1024
		var order: Array[int] = []
		for index in range(region_sizes.size()):
			order.append(index)
			atlas_size.x = maxi(atlas_size.x,int(ceil(region_sizes[index].x/4.0))*4+16)
		order.sort_custom(func(a: int, b: int) -> bool: return region_sizes[a].y>region_sizes[b].y)
		pool_regions.resize(region_sizes.size())
		var cursor := Vector2.ZERO
		var row_height := 0.0
		for index in order:
			var size := region_sizes[index]
			var slot := Vector2(ceil(size.x/4.0)*4+16,ceil(size.y/4.0)*4+16)
			if cursor.x+slot.x>atlas_size.x:
				cursor = Vector2(0,cursor.y+row_height)
				row_height = 0.0
			pool_regions[index] = Rect2(cursor,size)
			cursor.x += slot.x
			row_height = maxf(row_height,slot.y)
		atlas_size.y = int(cursor.y+row_height)
	var image:=Image.create(atlas_size.x/FIELD_STEP,atlas_size.y/FIELD_STEP,false,Image.FORMAT_RGB8)
	for py in range(image.get_height()):
		for px in range(image.get_width()):
			var p:=Vector2((px+0.5)*FIELD_STEP,(py+0.5)*FIELD_STEP)
			var depth:=0.0
			var horizontal:=1.0
			for region in pool_regions:
				if not region.has_point(p): continue
				depth=minf(minf(p.x-region.position.x,region.end.x-p.x),minf(p.y-region.position.y,region.end.y-p.y))/DEPTH_RANGE
				horizontal=1.0 if region.size.x>region.size.y else 0.0
			image.set_pixel(px,py,Color(depth,horizontal,0))
	pool_material=water_material.duplicate()
	pool_material.set_shader_parameter("field_texture",ImageTexture.create_from_image(image))
	pool_material.set_shader_parameter("world_size",Vector2(atlas_size))
	pool_material.set_shader_parameter("allow_pollution",0.0)
	pool_viewport=SubViewport.new()
	pool_viewport.size=atlas_size
	pool_viewport.disable_3d=true
	pool_viewport.render_target_update_mode=SubViewport.UPDATE_WHEN_VISIBLE
	var sprite:=Sprite2D.new()
	sprite.centered=false
	sprite.texture=pool_material.get_shader_parameter("field_texture")
	sprite.scale=Vector2(FIELD_STEP,FIELD_STEP)
	sprite.material=pool_material
	pool_viewport.add_child(sprite)
	add_child(pool_viewport)

func draw_pool(canvas: Node2D, inner: Rect2, index: int) -> void:
	canvas.draw_texture_rect_region(pool_viewport.get_texture(),inner,pool_regions[index-1])

func draw_service_channel(canvas: Node2D, inner: Rect2, index: int) -> void:
	canvas.draw_texture_rect_region(pool_viewport.get_texture(),inner,pool_regions[service_channel_offset+index])

func present(offset: Vector2, time: float, restored: int) -> void:
	position=offset
	water_material.set_shader_parameter("water_time",time)
	water_material.set_shader_parameter("recovery",1.0 if restored>=3 else 0.0)
	if pool_material:
		pool_material.set_shader_parameter("water_time",time)
		pool_material.set_shader_parameter("recovery",1.0 if restored>=3 else 0.0)

func _draw() -> void:
	if field_texture: draw_texture_rect(field_texture,Rect2(Vector2.ZERO,world_size),false)

static func draw_plant_contact(canvas: Node2D, foot: Vector2, width: float, time: float) -> void:
	# Broken, low-contrast rings put existing reeds and floating leaves in the water.
	var center:=foot-Vector2(0,2)
	canvas.draw_colored_polygon(PackedVector2Array([
		center+Vector2(-width*0.24,-2),center+Vector2(width*0.24,-2),
		center+Vector2(width*0.35,2),center+Vector2(width*0.18,5),
		center+Vector2(-width*0.28,4)
	]),Color("092932",0.43))
	var phase:=fposmod(time*0.24+foot.x*0.017+foot.y*0.013,1.0)
	var radius:=width*0.27+phase*9
	var alpha: float=(1.0-phase)*0.23
	_draw_ripple(canvas,center+Vector2(0,3),Vector2(radius,3+phase*3),Color("8bbcb0",alpha))

static func _draw_ripple(canvas: Node2D, center: Vector2, radii: Vector2, color: Color) -> void:
	var segments:=PackedVector2Array()
	for side in [-1.0,1.0]:
		for step in range(5):
			for vertex in [step,step+1]:
				var angle:=0.25+float(vertex)*0.38
				segments.append((center+Vector2(cos(angle)*radii.x*side,sin(angle)*radii.y)).round())
	canvas.draw_multiline(segments,color,1,false)

static func draw_structure_contacts(canvas: Node2D, view: Rect2, bridges: Array[Rect2], pier: Rect2, time: float) -> void:
	var structures: Array[Rect2]=bridges.duplicate()
	structures.append(pier)
	for rect in structures:
		if not rect.grow(28).intersects(view): continue
		var vertical:=rect.size.y>rect.size.x
		# Wake leaves the bridge's downstream side, never its pedestrian deck.
		var edge:=rect.end.x+3 if vertical else rect.end.y+5
		for end in [0,1]:
			var p:=Vector2(edge,rect.position.y+18+end*(rect.size.y-36)) if vertical else Vector2(rect.position.x+22+end*(rect.size.x-44),edge)
			for ring in range(2):
				var phase:=fposmod(time*0.26+ring*0.5,1.0)
				_draw_ripple(canvas,p+Vector2(phase*6,phase*2),Vector2(8+phase*13,3+phase*5),Color("a1c6b5",(1-phase)*0.24))

static func draw_outlet_contact(canvas: Node2D, mouth: Vector2, time: float, active: bool) -> void:
	# Collar at the existing distribution feed; ripples stay inside the reservoir.
	canvas.draw_rect(Rect2(mouth-Vector2(8,4),Vector2(10,8)),Color("344f50"))
	canvas.draw_rect(Rect2(mouth-Vector2(7,3),Vector2(9,2)),Color("b29970"))
	canvas.draw_rect(Rect2(mouth-Vector2(2,2),Vector2(3,4)),Color("142d34"))
	var phase:=fposmod(time*(0.42 if active else 0.17),1.0)
	var strength:=0.28 if active else 0.12
	_draw_ripple(canvas,mouth+Vector2(7+phase*8,0),Vector2(6+phase*9,2+phase*4),Color("b6d0bd",strength*(1-phase)))
	canvas.draw_rect(Rect2(mouth+Vector2(3,-1),Vector2(5,1)),Color("76b6ae",strength))

