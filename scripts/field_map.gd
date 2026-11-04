extends RefCounted
## Shared full-screen cartography. Coordinates and objectives come from each district.
const HUD = preload("res://scripts/field_hud.gd")
const INK := HUD.INK
const WHITE := HUD.WHITE
const MUTED := HUD.MUTED
const CYAN := HUD.CYAN
const GOLD := HUD.GOLD
const RED := HUD.RED

static func layout(size: Vector2) -> Dictionary:
	var map := Rect2(16,100,size.x-326,size.y-166)
	return {"frame":map,"canvas":Rect2(map.position+Vector2(17,41),map.size-Vector2(34,60)),"sidebar":Rect2(size.x-296,100,280,size.y-166),"footer":Rect2(16,size.y-52,size.x-32,36)}

static func close_rect(size: Vector2) -> Rect2:
	return Rect2(size.x-224,35,190,31)

static func shell(c: CanvasItem, size: Vector2, title: String, subtitle: String, pointer: Vector2) -> Dictionary:
	c.draw_rect(Rect2(Vector2.ZERO,size),INK)
	var parts := layout(size)
	HUD.panel(c,Rect2(16,16,size.x-32,70))
	HUD.icon(c,"network",Rect2(34,34,30,30),GOLD)
	HUD.text(c,"AURORA / MAPA DE CAMPO",Vector2(78,38),9,GOLD)
	HUD.text(c,title,Vector2(78,64),20,WHITE)
	c.draw_circle(Vector2(size.x-401,52),2,CYAN)
	HUD.text(c,"SIMULAÇÃO PAUSADA",Vector2(size.x-391,56),9,MUTED)
	var exit := close_rect(size)
	HUD.plate(c,exit,GOLD if exit.has_point(pointer) else Color("56695f"),4)
	HUD.plate(c,exit.grow(-2),Color("264b43") if exit.has_point(pointer) else Color("142b32"),3)
	HUD.keycap(c,"M",Rect2(exit.position+Vector2(5,5),Vector2(23,21)))
	HUD.centered(c,"VOLTAR AO CAMPO",exit.get_center()+Vector2(12,4),10,WHITE)
	HUD.panel(c,parts.frame)
	HUD.text(c,subtitle,parts.frame.position+Vector2(18,25),9,MUTED)
	HUD.text(c,"N",Vector2(parts.frame.end.x-28,parts.frame.position.y+24),9,GOLD)
	var area: Rect2 = parts.canvas
	HUD.inset(c,area.grow(2))
	for x in range(int(area.position.x)+16,int(area.end.x),24):
		c.draw_line(Vector2(x,area.position.y+2),Vector2(x,area.end.y-2),Color(CYAN,0.045),1)
	for y in range(int(area.position.y)+16,int(area.end.y),24):
		c.draw_line(Vector2(area.position.x+2,y),Vector2(area.end.x-2,y),Color(CYAN,0.045),1)
	HUD.panel(c,parts.sidebar)
	legend(c,parts.footer)
	return parts

static func wrapped(c: CanvasItem, value: String, rect: Rect2, size: int, color: Color, step: int = 16) -> void:
	var font := ThemeDB.fallback_font
	var lines: Array[String] = []
	var line := ""
	for word in value.split(" "):
		var candidate: String = word if line.is_empty() else line+" "+word
		if not line.is_empty() and font.get_string_size(candidate,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x>rect.size.x:
			lines.append(line)
			line=word
		else: line=candidate
	if not line.is_empty(): lines.append(line)
	var maximum := maxi(1,int(rect.size.y/step))
	for i in mini(lines.size(),maximum):
		var value_line := lines[i]
		if i==maximum-1 and lines.size()>maximum: value_line=HUD.fit(value_line+"…",rect.size.x,size)
		HUD.text(c,value_line,rect.position+Vector2(0,size+i*step),size,color)

static func sidebar(c: CanvasItem, r: Rect2, restored: int, total: int, location: String, objective: String, stats: Array, hint: String) -> void:
	var p := r.position
	HUD.text(c,"SISTEMAS RESTAURADOS",p+Vector2(18,25),9,MUTED)
	HUD.text(c,"%02d / %02d" % [restored,total],p+Vector2(18,59),29,CYAN)
	HUD.icon(c,"network",Rect2(p+Vector2(225,35),Vector2(30,30)),GOLD)
	HUD.bar(c,Rect2(p+Vector2(18,72),Vector2(244,8)),float(restored)/total,CYAN)
	var objective_box := Rect2(p+Vector2(16,96),Vector2(248,91))
	HUD.inset(c,objective_box)
	HUD.text(c,"OBJETIVO ATUAL",p+Vector2(28,115),9,GOLD)
	wrapped(c,objective,Rect2(p+Vector2(28,126),Vector2(224,48)),12,WHITE,16)
	for i in mini(stats.size(),3):
		var y := 209.0+i*23
		var color: Color = stats[i].get("color",CYAN)
		c.draw_circle(p+Vector2(23,y-3),2,color)
		HUD.text(c,stats[i].label,p+Vector2(34,y),10,MUTED)
		var value: String = str(stats[i].value)
		var w := ThemeDB.fallback_font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x
		HUD.text(c,value,p+Vector2(260-w,y),12,color)
	c.draw_line(p+Vector2(18,274),p+Vector2(262,274),Color("415c54"),1)
	HUD.text(c,"SETOR EM FOCO",p+Vector2(18,295),8,GOLD)
	HUD.text(c,HUD.fit(location,244,11),p+Vector2(18,313),11,WHITE)
	wrapped(c,hint,Rect2(p+Vector2(18,326),Vector2(244,r.size.y-338)),10,MUTED,14)

static func marker(c: CanvasItem, point: Vector2, kind: String, done: bool = false, direction: Vector2 = Vector2.UP) -> void:
	match kind:
		"player":
			c.draw_circle(point,10,Color(CYAN,0.18))
			c.draw_circle(point,7,INK)
			var aim := direction.normalized() if direction.length_squared()>0.01 else Vector2.UP
			var side := aim.orthogonal()
			c.draw_colored_polygon(PackedVector2Array([point+aim*7,point-aim*4+side*4,point-aim*4-side*4]),WHITE)
		"objective":
			var ring := PackedVector2Array([point+Vector2(0,-8),point+Vector2(8,0),point+Vector2(0,8),point+Vector2(-8,0),point+Vector2(0,-8)])
			c.draw_colored_polygon(ring,INK)
			c.draw_polyline(ring,GOLD,2)
			c.draw_circle(point,2,GOLD)
		"terminal":
			c.draw_rect(Rect2(point-Vector2(5,5),Vector2(10,10)),INK)
			c.draw_rect(Rect2(point-Vector2(5,5),Vector2(10,10)),CYAN if done else GOLD,false,1)
			if done: c.draw_polyline(PackedVector2Array([point+Vector2(-3,0),point+Vector2(-1,2),point+Vector2(3,-2)]),CYAN,1)
			else: c.draw_rect(Rect2(point-Vector2(2,2),Vector2(4,4)),GOLD)
		"enemy":
			c.draw_circle(point,4,INK)
			c.draw_circle(point,2.5,RED)
		"boss":
			c.draw_circle(point,6,INK)
			c.draw_rect(Rect2(point-Vector2(3,3),Vector2(6,6)),RED)
		"task":
			c.draw_circle(point,5,INK)
			c.draw_arc(point,4,0,TAU,16,CYAN if done else GOLD,1)
			if done: c.draw_circle(point,2,CYAN)

static func tag(c: CanvasItem, value: String, point: Vector2, color: Color = WHITE) -> void:
	var width := ThemeDB.fallback_font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,9).x
	c.draw_rect(Rect2(point+Vector2(-3,-10),Vector2(width+6,14)),Color(INK,0.96))
	HUD.text(c,value,point,9,color)

static func legend(c: CanvasItem, r: Rect2) -> void:
	HUD.panel(c,r)
	var labels := ["LIA","OBJETIVO","TERMINAL","AMEAÇA","RESTAURADO","ROTA"]
	var kinds := ["player","objective","terminal","enemy","terminal","route"]
	var step := (r.size.x-30)/6
	for i in 6:
		var point := r.position+Vector2(25+i*step,18)
		if kinds[i]=="route": c.draw_dashed_line(point-Vector2(7,0),point+Vector2(7,0),GOLD,1,3)
		else: marker(c,point,kinds[i],i==4)
		HUD.text(c,labels[i],point+Vector2(14,4),9,MUTED)
## Choose a label position that leaves real player/objective/terminal markers visible.
static func label_anchor(region: Rect2, labels: Array, occupied: Array[Vector2]) -> Vector2:
	var width := 0.0
	for label in labels: width=maxf(width,ThemeDB.fallback_font.get_string_size(str(label),HORIZONTAL_ALIGNMENT_LEFT,-1,9).x)
	var height := 14.0*labels.size()
	var left := region.position.x+9
	var right := region.end.x-width-8
	var top := region.position.y+17
	var bottom := region.end.y-height+3
	var middle := region.get_center().y-height/2+10
	var candidates := [Vector2(left,top),Vector2(left,bottom),Vector2(right,top),Vector2(right,bottom),Vector2(left,middle),Vector2(right,middle)]
	var anchor: Vector2=candidates[0]
	var lowest := 1000
	for candidate in candidates:
		var collisions := 0
		var box := Rect2(candidate-Vector2(3,10),Vector2(width+6,height)).grow(9)
		for point in occupied:
			if box.has_point(point): collisions+=1
		if collisions<lowest:
			lowest=collisions
			anchor=candidate
	return anchor