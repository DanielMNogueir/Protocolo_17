extends RefCounted
const Lab = preload("res://scripts/laboratory_world.gd")
const Beatrix = preload("res://scripts/beatrix_art.gd")
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
		var panel := Rect2(40,size.y-285,size.x-80,217)
		canvas.draw_rect(panel,Color(INK,0.94))
		canvas.draw_rect(Rect2(panel.position,Vector2(3,panel.size.y)),CYAN)
		canvas._text("AURORA  /  MEMÓRIA ANTERIOR AO COLAPSO",panel.position+Vector2(25,29),10,CYAN)
		canvas._wrapped(story.CONTEXT[story.page][0],Rect2(panel.position+Vector2(25,42),Vector2(size.x-130,45)),28,TEXT,34)
		canvas._wrapped(story.visible_text(),Rect2(panel.position+Vector2(25,94),Vector2(size.x-150,68)),15,Color("b6cdca"),23)
		canvas._button(Rect2(panel.end.x-251,panel.end.y-45,222,31),"ENTRAR NO LABORATÓRIO" if story.text_complete() else "COMPLETAR  /  ENTER","intro_next",true)
	elif story.phase == "handoff":
		canvas.draw_rect(Rect2(Vector2.ZERO,size),Color("081d28"))
		canvas._text_center("ALGUM TEMPO DEPOIS",Vector2(size.x/2,size.y/2-72),12,CYAN)
		canvas._text_center("DISTRITO DAS ÁGUAS",Vector2(size.x/2,size.y/2-27),32,TEXT)
		canvas._wrapped("MAJOR 0: Lia, recebemos um sinal do cais. A rede não responde. Precisamos recuperar os sistemas de Aurora.",Rect2(size.x/2-290,size.y/2+8,580,76),15,Color("aabdc0"),23)
		canvas._button(Rect2(size.x/2-130,size.y/2+111,260,39),"ASSUMIR CONTROLE DE LIA","intro_next",true)
	else:
		var offset := (size*0.5-camera).round()
		canvas.draw_set_transform(offset)
		Lab.draw(canvas,story,Rect2(camera-size/2,size).grow(100),canvas.laboratory_effects)
		canvas.draw_set_transform(Vector2.ZERO)
		_draw_hud(canvas,story,size)
		if not story.conversation.is_empty(): _draw_balloon(canvas,story,offset,size)
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
	canvas.draw_rect(Rect2(0,size.y-35,size.x,35),Color(INK,0.94))
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
		canvas.draw_rect(Rect2(180,size.y-68,size.x-360,25),Color(INK,0.93))
		canvas._text_center(hint,Vector2(size.x/2,size.y-51),9,CYAN)
		if story.repair>0:
			canvas.draw_rect(Rect2(190,size.y-41,size.x-380,3),Color("263f49"))
			canvas.draw_rect(Rect2(190,size.y-41,(size.x-380)*story.repair,3),CYAN)
		if story.step == 3:
			canvas._text("PULSOS NO ATUADOR: %d / 2" % story.relay_hits,Vector2(24,111),10,CYAN)
		_draw_navigation(canvas,story,size)

static func _draw_navigation(canvas: Node2D, story: P17Prologue, size: Vector2) -> void:
	if story.step>=7: return
	var target: Vector2 = story.TARGETS[story.step]
	var delta: Vector2 = target-story.pos
	var screen: Vector2 = target+(size*0.5-canvas.prologue_camera).round()
	var safe := Rect2(40,159,size.x-80,size.y-280)
	if Rect2(30,145,size.x-60,size.y-227).has_point(screen): return
	var p := screen.clamp(safe.position,safe.end)
	var direction := delta.normalized()
	var side := direction.orthogonal()
	canvas.draw_circle(p,17,Color(INK,0.96))
	canvas.draw_arc(p,17,0,TAU,24,Color("f3cc80"),1)
	canvas.draw_colored_polygon(PackedVector2Array([p+direction*10,p-direction*6+side*6,p-direction*6-side*6]),Color("f3cc80"))
	canvas._text_center("OBJETIVO",p+Vector2(0,31),8,Color("f3cc80"))

static func _draw_balloon(canvas: Node2D, story: P17Prologue, offset: Vector2, size: Vector2) -> void:
	var human: bool = story.conversation[0][0] == "beatrix"
	var anchor: Vector2 = (story.pos+Vector2(0,-45) if human else Lab.EMITTER)+offset
	anchor = anchor.clamp(Vector2(35,155),size-Vector2(35,110))
	var width := minf(390,size.x-60)
	var line := ""
	var lines := 1
	for word in story.text().split(" "):
		var candidate: String = word if line.is_empty() else line+" "+word
		if ThemeDB.fallback_font.get_string_size(candidate,HORIZONTAL_ALIGNMENT_LEFT,-1,13).x>width-32:
			lines += 1
			line = word
		else: line = candidate
	var balloon_height := 62.0+lines*20
	var r := Rect2(Vector2(clampf(anchor.x-width/2,25,size.x-width-25),clampf(anchor.y-balloon_height-15,150,size.y-balloon_height-93)),Vector2(width,balloon_height))
	var color := CYAN if human or story.step<3 else RED
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(clampf(anchor.x,r.position.x+15,r.end.x-15)-9,r.end.y-1),Vector2(clampf(anchor.x,r.position.x+15,r.end.x-15)+9,r.end.y-1),anchor]),Color(INK,0.97))
	canvas.draw_rect(r,Color(INK,0.98))
	canvas.draw_rect(r,color,false,1)
	if human: canvas._text("DRA. BEATRIX",r.position+Vector2(16,21),10,color)
	else:
		# The terminal answers without a displayed identity or name.
		for n in range(14):
			var height := 2+absf(sin(story.elapsed*5+n))*7
			canvas.draw_rect(Rect2(r.position+Vector2(16+n*5,19-height/2),Vector2(2,height)),color)
	canvas._wrapped(story.visible_text(),Rect2(r.position+Vector2(16,32),Vector2(width-32,65)),13,TEXT,20)
	canvas._text("A FALA AVANÇA SOZINHA",r.position+Vector2(16,r.size.y-14),8,Color("9ab6b2"))
	canvas._button(Rect2(r.end.x-151,r.end.y-29,135,23),"AVANÇAR  ENTER" if story.text_complete() else "COMPLETAR  ENTER","intro_next",false)
