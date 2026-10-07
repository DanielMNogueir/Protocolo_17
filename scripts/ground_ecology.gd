class_name P17GroundEcology
extends RefCounted
## Cached ground-only weathering, linked to real banks, slab joints and roots.
const Art = preload("res://scripts/station_art.gd")
const STEP := 1
static var surfaces: Array[Dictionary] = []
static var puddles: Array[Dictionary] = []
static var setup_usec := 0

static func prepare(regions: Array[Rect2], channels: Array[Rect2], basins: Array[Rect2], plants: Array[Dictionary], marks: Array[Dictionary], crossings: Array[Rect2]) -> void:
	if not surfaces.is_empty(): return
	var start := Time.get_ticks_usec()
	var broad := FastNoiseLite.new()
	broad.seed = 17031
	broad.frequency = 0.038
	broad.fractal_octaves = 3
	var detail := FastNoiseLite.new()
	detail.seed = 17032
	detail.frequency = 0.24
	detail.fractal_octaves = 2
	var features: Array[Rect2] = channels.duplicate()
	features.append_array(basins)
	for sector in range(regions.size()):
		var region := regions[sector]
		var coarse := Image.create(int(ceil(region.size.x/8)),int(ceil(region.size.y/8)),false,Image.FORMAT_RGBA8)
		for y in coarse.get_height():
			for x in coarse.get_width():
				var p := region.position+Vector2(x*8+4,y*8+4)
				var distance := minf(minf(p.x-region.position.x,region.end.x-p.x),minf(p.y-region.position.y,region.end.y-p.y))
				for feature in features:
					if not feature.grow(130).has_point(p): continue
					distance = minf(distance,p.distance_to(p.clamp(feature.position,feature.end)))
				coarse.set_pixel(x,y,Color(0.10+0.90*exp(-maxf(0,distance)/46),0,0,1))
		# Root footprints influence the ground, never scatter independently of plants.
		for plant in plants:
			if plant.get("aquatic",false) or not region.has_point(plant.foot): continue
			var center: Vector2 = (plant.foot-region.position)/8
			var radius: float = plant.width*0.65/8+2
			for y in range(maxi(0,int(center.y-radius)),mini(coarse.get_height(),int(center.y+radius)+1)):
				for x in range(maxi(0,int(center.x-radius)),mini(coarse.get_width(),int(center.x+radius)+1)):
					var strength := maxf(0,1-Vector2(x,y).distance_to(center)/radius)
					var color := coarse.get_pixel(x,y)
					color.g = maxf(color.g,strength)
					coarse.set_pixel(x,y,color)
		var width := int(ceil(region.size.x/STEP))
		var height := int(ceil(region.size.y/STEP))
		coarse.resize(width,height,Image.INTERPOLATE_BILINEAR)
		var joints := Image.create(width,height,false,Image.FORMAT_L8)
		for tile in Art.floor_tiles(region,sector):
			var r: Rect2 = tile.rect
			var local := Rect2i((r.position-region.position)/STEP,r.size/STEP)
			joints.fill_rect(Rect2i(local.position.x,maxi(0,local.end.y-6),local.size.x,6),Color.WHITE)
			joints.fill_rect(Rect2i(maxi(0,local.end.x-6),local.position.y,6,local.size.y),Color.WHITE)
		var image := Image.create(width,height,false,Image.FORMAT_RGBA8)
		for y in height:
			for x in width:
				var p := region.position+Vector2(x,y)*STEP
				var field := coarse.get_pixel(x,y)
				var n := broad.get_noise_2dv(p)*0.5+0.5
				var grain := detail.get_noise_2dv(p)*0.5+0.5
				var joint := joints.get_pixel(x,y).r
				var score := n*0.48+field.r*0.44+field.g*0.34+joint*(0.10+grain*0.21)
				var cover := smoothstep(0.56,0.74,score+grain*0.09)
				var damp := Color("102e36",field.r*(0.13+0.10*n))
				if cover>0.04:
					var moss := Color("24422d").lerp(Color("637e27"),clampf(grain*1.7-0.35,0,1))
					if grain>0.66: moss = moss.lerp(Color("a2ad49"),0.45)
					moss.a = cover*(0.64+0.30*grain)
					damp = damp.blend(moss)
				image.set_pixel(x,y,damp)
		# Walking decks remain bare metal. Channels are painted above this layer.
		for crossing in crossings:
			var cut := crossing.intersection(region)
			if cut.size.x>0 and cut.size.y>0:
				image.fill_rect(Rect2i((cut.position-region.position)/STEP,cut.size/STEP),Color.TRANSPARENT)
		surfaces.append({"rect":region,"texture":ImageTexture.create_from_image(image),"field":coarse})
	for mark in marks:
		if not mark.puddle: continue
		var r: Rect2 = mark.rect
		var image := Image.create(int(r.size.x/STEP),int(r.size.y/STEP),false,Image.FORMAT_RGBA8)
		for y in image.get_height():
			for x in image.get_width():
				var uv := Vector2((x+0.5)/image.get_width(),(y+0.5)/image.get_height())*2-Vector2.ONE
				var p := r.position+Vector2(x,y)*STEP
				var n := broad.get_noise_2dv(p)*0.5+0.5
				var grain := detail.get_noise_2dv(p)*0.5+0.5
				var shape := 1-uv.length()+(n-0.5)*0.9+(grain-0.5)*0.15
				if shape<0: continue
				var color := Color("3e6475").lerp(Color("668f9e"),n)
				color.a = smoothstep(0,0.035,shape)*0.73
				if shape<0.03: color = Color("162f32",0.64)
				if uv.y<-0.22 and n>0.56 and shape>0.12: color = Color("99b8be",0.49)
				image.set_pixel(x,y,color)
		puddles.append({"rect":r,"texture":ImageTexture.create_from_image(image)})
	setup_usec = Time.get_ticks_usec()-start

static func draw(canvas: Node2D, view: Rect2) -> void:
	for surface in surfaces:
		if surface.rect.intersects(view): canvas.draw_texture_rect(surface.texture,surface.rect,false)
	for puddle in puddles:
		if puddle.rect.intersects(view): canvas.draw_texture_rect(puddle.texture,puddle.rect,false)
