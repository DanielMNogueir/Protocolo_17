extends RefCounted
const Lab = preload("res://scripts/laboratory_world.gd")
const Beatrix = preload("res://scripts/beatrix_art.gd")
const Dialogue = preload("res://scripts/dialogue_panel.gd")
const AURORA: Texture2D = preload("res://assets/prologue/aurora_before.png")
const INK := Color("102731")
const TEXT := Color("e5ece3")
const CYAN := Color("7de0cf")
const RED := Color("ef8c98")

static func draw(canvas: Node2D, story: P17Prologue, camera: Vector2) -> void:
	var size: Vector2 = canvas._size()
	if story.phase == "context":
		var ratio := maxf(size.x/AURORA.get_width(),size.y/AURORA.get_height())
		var extent := AURORA.get_size()*ratio
		canvas.draw_texture_rect(AURORA,Rect2((size-extent)*0.5,extent),false)
		canvas.draw_rect(Rect2(Vector2.ZERO,size),Color(INK,0.28))
		canvas._text_center(story.CONTEXT[story.page][0],Vector2(size.x/2,139),26,TEXT)
		canvas._text_center("MEMÓRIA ANTERIOR AO COLAPSO",Vector2(size.x/2,165),10,CYAN)
		Dialogue.draw(canvas,size,"aurora","AURORA",story.visible_text(),story.text_complete(),story.fast_text,story.elapsed,false,"ENTRAR / ENTER")
	elif story.phase == "handoff":
		canvas.draw_rect(Rect2(Vector2.ZERO,size),Color("081d28"))
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
				canvas._text_center("REGISTRO PRESERVADO",Vector2(size.x/2,size.y/2-15),19,CYAN)
				canvas._text_center("O laboratório perdeu seu último sinal humano.",Vector2(size.x/2,size.y/2+22),14,Color("aabdc0"))
		elif story.phase == "retry":
			canvas._overlay("CONTENÇÃO INTERROMPIDA","Retome a fuga a partir da conexão isolada.",RED)
			canvas._button(Rect2(size.x/2-155,300,310,40),"RETOMAR TENTATIVA  /  R","intro_retry",true)
	# Always reachable, including dialogue, ending, retry and world introduction.
	canvas._button(Rect2(size.x-244,19,224,31),"PULAR INTRODUÇÃO  /  P","intro_skip",false)
	if story.phase not in ["context","handoff"] and story.conversation.is_empty():
		canvas.draw_rect(Rect2(0,size.y-35,size.x,35),Color(INK,0.94))
		canvas.draw_line(Vector2(20,size.y-35),Vector2(size.x-20,size.y-35),Color("a58c65",0.5),1)
		canvas._text("ENTER: COMPLETAR / AVANÇAR   •   SEGURE ENTER: ACELERAR",Vector2(20,size.y-13),10,Color("aabdc0"))
		canvas._button(Rect2(size.x-273,size.y-30,253,24),"FALAS INSTANTÂNEAS: "+("SIM" if story.fast_text else "NÃO")+"  /  TAB","intro_fast",false)

static func _draw_hud(canvas: Node2D, story: P17Prologue, size: Vector2) -> void:
	canvas.draw_rect(Rect2(20,19,285,70),Color(INK,0.94))
	canvas.draw_rect(Rect2(20,19,285,70),Color("627b80"),false,1)
	Beatrix.portrait(canvas,Rect2(31,25,42,44))
	canvas._text("DRA. BEATRIX WINDOW",Vector2(86,40),11,TEXT)
	canvas._text("LABORATÓRIO  /  ANTES DA QUEDA",Vector2(86,57),8,CYAN)
	for n in range(3): canvas.draw_rect(Rect2(87+n*17,68,12,5),CYAN if n<story.hp else Color("354d56"))
	var r := Rect2(size.x-306,58,286,72)
	canvas.draw_rect(r,Color(INK,0.94))
	canvas._text("ROTINA %02d / 07" % mini(story.step+1,7),r.position+Vector2(15,20),9,CYAN if story.step<3 else RED)
	canvas._wrapped(story.OBJECTIVES[story.step],Rect2(r.position+Vector2(15,28),Vector2(256,37)),12,TEXT,16)
	for n in range(7): canvas.draw_rect(Rect2(r.position+Vector2(15+n*37,65),Vector2(31,3)),CYAN if n<story.step else Color("f0c77c") if n==story.step else Color("34505b"))
	if (story.conversation.is_empty() or not story.dialogue_blocks) and story.phase == "lab" and story.step<7:
		var hint: String = story.HINTS[story.step]
		if story.interaction_active: hint = "AÇÃO EM ANDAMENTO  •  PERMANEÇA PERTO DA ESTAÇÃO"
		if story.step == 5 and story.used_dash: hint = "ALCANCE O ARQUIVO  •  OS DRONES ANUNCIAM CADA DISPARO"
		var bottom: float = size.y-43 if story.conversation.is_empty() else Dialogue.layout(size).frame.position.y-24
		canvas.draw_rect(Rect2(180,bottom-25,size.x-360,25),Color(INK,0.93))
		canvas._text_center(hint,Vector2(size.x/2,bottom-8),9,CYAN)
		if story.repair>0:
			canvas.draw_rect(Rect2(190,bottom+2,size.x-380,3),Color("263f49"))
			canvas.draw_rect(Rect2(190,bottom+2,(size.x-380)*story.repair,3),CYAN)
		if story.step == 3:
			canvas._text("PULSOS NO ATUADOR: %d / 2" % story.relay_hits,Vector2(24,111),10,CYAN)
		_draw_navigation(canvas,story,size)

static func _draw_navigation(canvas: Node2D, story: P17Prologue, size: Vector2) -> void:
	if story.step>=7: return
	var target: Vector2 = story.TARGETS[story.step]
	var delta: Vector2 = target-story.pos
	var screen: Vector2 = target+(size*0.5-canvas.prologue_camera).round()
	var bottom: float = size.y-121 if story.conversation.is_empty() else Dialogue.layout(size).frame.position.y-48
	var safe := Rect2(40,159,size.x-80,bottom-159)
	if Rect2(30,145,size.x-60,bottom-145).has_point(screen): return
	var p := screen.clamp(safe.position,safe.end)
	var direction := delta.normalized()
	var side := direction.orthogonal()
	canvas.draw_circle(p,17,Color(INK,0.96))
	canvas.draw_arc(p,17,0,TAU,24,Color("f3cc80"),1)
	canvas.draw_colored_polygon(PackedVector2Array([p+direction*10,p-direction*6+side*6,p-direction*6-side*6]),Color("f3cc80"))
	canvas._text_center("OBJETIVO",p+Vector2(0,31),8,Color("f3cc80"))

static func _draw_dialogue(canvas: Node2D, story: P17Prologue, size: Vector2) -> void:
	var human: bool = story.conversation[0][0] == "beatrix"
	Dialogue.draw(canvas,size,"beatrix" if human else "terminal","DRA. BEATRIX" if human else "",story.visible_text(),story.text_complete(),story.fast_text,story.elapsed,story.step>=3)
