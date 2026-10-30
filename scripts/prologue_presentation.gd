extends RefCounted
const FieldHUD = preload("res://scripts/field_hud.gd")
const Lab = preload("res://scripts/laboratory_world.gd")
const Beatrix = preload("res://scripts/beatrix_art.gd")
const Dialogue = preload("res://scripts/dialogue_panel.gd")
const AURORA: Texture2D = preload("res://assets/prologue/aurora_before.png")
const INK := FieldHUD.INK
const TEXT := FieldHUD.WHITE
const CYAN := FieldHUD.CYAN
const RED := FieldHUD.RED

static func draw(canvas: Node2D, story: P17Prologue, camera: Vector2) -> void:
	var size: Vector2 = canvas._size()
	if story.phase == "context":
		var ratio := maxf(size.x/AURORA.get_width(),size.y/AURORA.get_height())
		var extent := AURORA.get_size()*ratio
		canvas.draw_texture_rect(AURORA,Rect2((size-extent)*0.5,extent),false)
		canvas.draw_rect(Rect2(Vector2.ZERO,size),Color(INK,0.28))
		FieldHUD.panel(canvas,Rect2(size.x/2-240,107,480,78))
		canvas._text_center(story.CONTEXT[story.page][0],Vector2(size.x/2,139),26,TEXT)
		canvas._text_center("MEMÓRIA ANTERIOR AO COLAPSO",Vector2(size.x/2,165),10,CYAN)
		Dialogue.draw(canvas,size,"aurora","AURORA",story.visible_text(),story.text_complete(),story.fast_text,story.elapsed,false,"ENTRAR / ENTER")
	elif story.phase == "handoff":
		canvas.draw_rect(Rect2(Vector2.ZERO,size),Color("081d28"))
		FieldHUD.panel(canvas,Rect2(size.x/2-280,size.y/2-107,560,108))
		canvas._text_center("ALGUM TEMPO DEPOIS",Vector2(size.x/2,size.y/2-72),12,CYAN)
		canvas._text_center("DISTRITO DAS ÁGUAS",Vector2(size.x/2,size.y/2-27),32,TEXT)
		Dialogue.draw(canvas,size,"radio","MAJOR 0","Lia, recebemos um sinal do cais. A rede não responde. Precisamos recuperar os sistemas de Aurora.",true,story.fast_text,story.elapsed,false,"ASSUMIR LIA")
	else:
		var offset := (size*0.5-camera).round()
		canvas.draw_set_transform(offset)
		Lab.draw(canvas,story,Rect2(camera-size/2,size).grow(100),canvas.laboratory_effects)
		canvas.draw_set_transform(Vector2.ZERO)
		_draw_hud(canvas,story,size)
		if not story.conversation.is_empty(): _draw_dialogue(canvas,story,size)
		if story.phase == "ending":
			var fade := clampf((story.cut_age-2.2)/0.55,0,1)
			canvas.draw_rect(Rect2(Vector2.ZERO,size),Color("050e16",fade))
			if story.cut_age>3:
				FieldHUD.panel(canvas,Rect2(size.x/2-275,size.y/2-49,550,100),CYAN)
				canvas._text_center("REGISTRO PRESERVADO",Vector2(size.x/2,size.y/2-15),19,CYAN)
				canvas._text_center("O laboratório perdeu seu último sinal humano.",Vector2(size.x/2,size.y/2+22),14,Color("aabdc0"))
		elif story.phase == "retry":
			canvas.draw_rect(Rect2(Vector2.ZERO,size),Color(INK,0.94))
			FieldHUD.panel(canvas,Rect2(size.x/2-270,size.y/2-100,540,192),RED)
			FieldHUD.centered(canvas,"CONTENÇÃO INTERROMPIDA",Vector2(size.x/2,size.y/2-59),24,RED)
			FieldHUD.centered(canvas,"Retome a fuga a partir da conexão isolada.",Vector2(size.x/2,size.y/2-24),13,TEXT)
			FieldHUD.control(canvas,Rect2(size.x/2-160,size.y/2+15,320,36),"RETOMAR TENTATIVA","intro_retry","R",CYAN)
	# Always reachable, including dialogue, ending, retry and world introduction.
	FieldHUD.control(canvas,Rect2(size.x-244,16,228,32),"PULAR INTRODUÇÃO","intro_skip","P")
	if story.phase not in ["context","handoff"] and story.conversation.is_empty():
		FieldHUD.panel(canvas,Rect2(16,size.y-52,size.x-32,36))
		FieldHUD.text(canvas,"WASD / SETAS: MOVER  •  E: INTERAGIR  •  ESC: PAUSA",Vector2(32,size.y-29),9,FieldHUD.MUTED)
		FieldHUD.control(canvas,Rect2(size.x-278,size.y-45,246,23),"FALAS INSTANTÂNEAS: "+("SIM" if story.fast_text else "NÃO"),"intro_fast","TAB")
static func _draw_hud(canvas: Node2D, story: P17Prologue, size: Vector2) -> void:
	var low := story.hp <= 1
	var color := RED if low else CYAN
	FieldHUD.panel(canvas,Rect2(16,16,288,100),color if low else FieldHUD.GOLD)
	FieldHUD.inset(canvas,Rect2(29,30,53,66))
	Beatrix.portrait(canvas,Rect2(31,32,49,60))
	canvas.draw_line(Vector2(87,31),Vector2(87,95),Color("6b7a60"),1)
	FieldHUD.text(canvas,"DRA. BEATRIX WINDOW",Vector2(98,44),12,TEXT)
	FieldHUD.text(canvas,"INTEGRIDADE",Vector2(98,63),9,FieldHUD.MUTED)
	FieldHUD.text(canvas,"%d/3" % story.hp,Vector2(250,64),16,color)
	FieldHUD.inset(canvas,Rect2(98,73,187,15))
	for n in 3:
		var cell := Rect2(102+n*61,77,57,7)
		FieldHUD.plate(canvas,cell,color if n<story.hp else Color("20383b"),1)
	FieldHUD.text(canvas,"SINAL CRÍTICO" if low else "LABORATÓRIO / ANTES DA QUEDA",Vector2(98,102),8,color if low else FieldHUD.MUTED)
	canvas.draw_circle(Vector2(37,103),2,color)
	if low: FieldHUD.edge(canvas,Rect2(18,18,284,96),Color(RED,0.45+0.3*sin(story.elapsed*5)),2)
	var r := Rect2(size.x-346,60,330,100)
	var accent := RED if story.step>=3 else FieldHUD.GOLD
	FieldHUD.panel(canvas,r,accent)
	FieldHUD.icon(canvas,"network",Rect2(r.position+Vector2(16,12),Vector2(18,18)),accent)
	FieldHUD.text(canvas,("CONTENÇÃO" if story.step>=3 else "ROTINA")+" / %02d DE 07" % mini(story.step+1,7),r.position+Vector2(43,25),10,accent)
	canvas._wrapped(story.OBJECTIVES[story.step],Rect2(r.position+Vector2(18,39),Vector2(294,34)),12,TEXT,16)
	for n in 7:
		FieldHUD.bar(canvas,Rect2(r.position+Vector2(18+n*42,80),Vector2(36,8)),1.0 if n<story.step else (0.4 if n==story.step else 0.0),CYAN if n<story.step else accent)
	if (story.conversation.is_empty() or not story.dialogue_blocks) and story.phase == "lab" and story.step<7:
		var hint: String = story.HINTS[story.step]
		if story.interaction_active: hint = "AÇÃO EM ANDAMENTO / PERMANEÇA PERTO DA ESTAÇÃO"
		var bottom: float = size.y-67 if story.conversation.is_empty() else Dialogue.layout(size).frame.position.y-24
		var width := minf(560,size.x-64)
		var box := Rect2((size.x-width)/2,bottom-48,width,44)
		FieldHUD.panel(canvas,box,CYAN)
		FieldHUD.centered(canvas,hint,box.position+Vector2(width/2,21),9,CYAN)
		if story.repair>0: FieldHUD.bar(canvas,Rect2(box.position+Vector2(17,28),Vector2(width-34,7)),story.repair,CYAN)
		_draw_navigation(canvas,story,size)
static func _draw_navigation(canvas: Node2D, story: P17Prologue, size: Vector2) -> void:
	if story.step>=7: return
	var target: Vector2 = story.TARGETS[story.step]
	var offset: Vector2 = (size*0.5-canvas.prologue_camera).round()
	var player: Vector2 = story.pos+offset
	var screen: Vector2 = target+offset
	var delta: Vector2 = screen-player
	var bottom: float = size.y-121 if story.conversation.is_empty() else Dialogue.layout(size).frame.position.y-48
	var safe := Rect2(40,179,size.x-80,maxf(1,bottom-179))
	if delta.length()<75 and safe.has_point(screen): return
	var p: Vector2 = (player+delta.normalized()*52) if safe.has_point(screen) else screen
	p = p.clamp(safe.position,safe.end)
	var direction := delta.normalized()
	var side := direction.orthogonal()
	FieldHUD.panel(canvas,Rect2(p-Vector2(20,20),Vector2(40,40)))
	canvas.draw_arc(p,13,0,TAU,24,Color(FieldHUD.GOLD,0.4),1)
	canvas.draw_colored_polygon(PackedVector2Array([p+direction*11,p-direction*6+side*7,p-direction*6-side*7]),Color("f3cc80"))
	canvas._text_center("OBJETIVO",p+Vector2(0,31),8,Color("f3cc80"))

static func _draw_dialogue(canvas: Node2D, story: P17Prologue, size: Vector2) -> void:
	var human: bool = story.conversation[0][0] == "beatrix"
	Dialogue.draw(canvas,size,"beatrix" if human else "terminal","DRA. BEATRIX" if human else "",story.visible_text(),story.text_complete(),story.fast_text,story.elapsed,story.step>=3)
