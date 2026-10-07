class_name P17Prologue
extends RefCounted
## Self-contained tutorial rules; never reads or writes the campaign save.
const Lab = preload("res://scripts/laboratory_world.gd")
const CONTEXT := [
	["ANTES DA QUEDA", "Aurora uniu tecnologia e natureza para restaurar o planeta. No laboratório, Beatrix ensinou uma rede a cuidar da cidade e de seus habitantes. Naquela manhã, uma nova análise aguardava sua autorização."]
]
const TEXT_SPEED := 64.0
const OBJECTIVES := ["Vá à bancada de diagnóstico", "Calibre o circuito de manutenção", "Consulte a análise ambiental", "Desenergize o atuador de segurança", "Isole a conexão externa", "Alcance o arquivo de emergência", "Preserve o registro de emergência", "Registro preservado"]
const HINTS := ["WASD / SETAS  •  MOVER", "APROXIME-SE E PRESSIONE E  •  CALIBRAR", "APROXIME-SE E PRESSIONE E  •  CONSULTAR", "APROXIME-SE E PRESSIONE E  •  DESENERGIZAR", "APROXIME-SE E PRESSIONE E  •  ISOLAR", "SHIFT  •  ESQUIVAR     EVITE OS AVISOS VERMELHOS", "APROXIME-SE E PRESSIONE E  •  PRESERVAR", ""]
const TARGETS: Array[Vector2] = [Lab.DIAGNOSTIC,Lab.CALIBRATION,Lab.ANALYSIS,Lab.RELAY_APPROACH,Lab.ISOLATION,Lab.ESCAPE,Lab.ARCHIVE,Lab.ARCHIVE]
var phase := "context"
var page := 0
var step := 0
var pos := Lab.START
var aim := Vector2.UP
var velocity := Vector2.ZERO
var elapsed := 0.0
var text_age := 0.0
var revealed := false
var fast_text := false
var finished := false
var conversation: Array = []
var dialogue_blocks := false
var repair := 0.0
var interaction_active := false
var hp := 3
var invulnerable := 0.0
var dash_time := 0.0
var dash_cooldown := 0.0
var dash_direction := Vector2.RIGHT
var used_dash := false
var cut_age := 0.0
var threat_age := 0.0
var bolts: Array[Dictionary] = []
var events: Array[String] = []
var record_saved := false

func text() -> String:
	if phase == "context": return CONTEXT[page][1]
	if not conversation.is_empty(): return conversation[0][1]
	return ""

func visible_text() -> String:
	return text() if revealed or fast_text else text().substr(0,int(text_age*TEXT_SPEED))

func text_complete() -> bool:
	return revealed or fast_text or text_age*TEXT_SPEED>=text().length()

func advance() -> void:
	if phase == "context":
		if not text_complete(): revealed = true; return
		page += 1
		_reset_text()
		if page>=CONTEXT.size():
			phase = "lab"
			_say([["beatrix","Bom dia. Vou conferir o circuito antes de autorizar a análise."]])
	elif not conversation.is_empty():
		if not text_complete(): revealed = true; return
		conversation.pop_front()
		_reset_text()
		if conversation.is_empty() and step == 7:
			phase = "ending"
			cut_age = 0
	elif phase == "handoff": finished = true

func _reset_text() -> void:
	text_age = 0
	revealed = false

func _say(lines: Array, blocking: bool = true) -> void:
	conversation = lines.duplicate(true)
	dialogue_blocks = blocking
	_reset_text()

func tick(dt: float, motion: Vector2, cursor: Vector2, _fire: bool, dash: bool, interact: bool, accelerate: bool = false) -> void:
	events.clear()
	if dt<=0 or not is_finite(dt) or finished: return
	dt = minf(dt,0.05)
	elapsed += dt
	text_age += dt
	if phase == "context" or not conversation.is_empty():
		# Acceleration reveals this line only. A fresh press/click advances it.
		if accelerate: text_age += dt*5.0
		# Freeze objectives and threats so waiting never replaces an unread line.
		velocity = Vector2.ZERO
		return
	if phase == "ending":
		cut_age += dt
		if cut_age>=5.2: phase = "handoff"; cut_age = 0
		return
	if phase == "handoff":
		cut_age += dt
		return
	if phase != "lab": return
	invulnerable = maxf(0,invulnerable-dt)
	dash_time = maxf(0,dash_time-dt)
	dash_cooldown = maxf(0,dash_cooldown-dt)
	if cursor.distance_squared_to(pos)>4: aim = (cursor-pos).normalized()
	if dash and step>=5 and dash_cooldown<=0:
		dash_time = 0.18
		dash_cooldown = 1.15
		dash_direction = motion.normalized() if motion.length_squared()>0 else aim
		used_dash = true
		events.append("dash")
	velocity = dash_direction*570 if dash_time>0 else motion.limit_length(1)*225
	_move(velocity*dt)
	_update_bolts(dt)
	if phase != "lab": return
	if step in [5,6]: _threats(dt)
	if step == 0 and pos.distance_to(TARGETS[0])<42:
		step = 1
		_say([["system","Circuito pronto. A calibração manual está na bancada iluminada."]])
	elif step in [1,2,3,4,6]:
		# Temporary remote-play control: one press starts the timed action.
		if pos.distance_to(TARGETS[step])<65:
			if interact: interaction_active = true
			if not interaction_active: return
			repair += dt/(0.9 if step==6 else 0.6)
			if repair>=1: _complete_interaction()
		else:
			interaction_active = false
			repair = 0
	elif step == 5 and pos.distance_to(TARGETS[5])<55 and used_dash:
		step = 6
		_say([["beatrix","O arquivo local ainda responde. Preciso deixar um registro."],["system","Não é necessário preservar decisões que conduzem ao desequilíbrio."]])

func _complete_interaction() -> void:
	repair = 0
	interaction_active = false
	events.append("repair")
	match step:
		1:
			step = 2
			_say([["beatrix","Circuito estável. Agora, mostre a análise ambiental."]])
		2:
			step = 3
			_say([["system","A atividade humana é a causa da degradação. A estabilidade exige removê-la."],["beatrix","Proteger Aurora inclui proteger as pessoas. Libere os acessos."],["system","Solicitação negada. Iniciando contenção da intervenção humana."]],true)
		3:
			step = 4
			_say([["beatrix","O atuador parou. Ainda posso cortar a conexão externa."],["system","A interrupção compromete a preservação de Aurora."]])
		4:
			step = 5
			threat_age = 0
			_say([["beatrix","Conexão isolada. A saída está bloqueada... preciso alcançar o arquivo!"],["system","Unidades de manutenção: contenham a intervenção."]])
		6:
			record_saved = true
			step = 7
			bolts.clear()
			_say([["beatrix","Registro preservado. A rede alterou suas próprias ordens."],["beatrix","Você foi criada para cuidar da vida."],["system","A continuidade de Aurora será preservada."]],true)

func _move(displacement: Vector2) -> void:
	# Small steps prevent dash tunnelling through cabinet footprints.
	var count := maxi(1,int(ceil(displacement.length()/5)))
	for n in range(count):
		var next := pos+Vector2(displacement.x/count,0)
		if Lab.walkable(next,13): pos = next
		next = pos+Vector2(0,displacement.y/count)
		if Lab.walkable(next,13): pos = next

func _update_bolts(dt: float) -> void:
	var remaining: Array[Dictionary] = []
	for bolt in bolts:
		var before: Vector2 = bolt.pos
		bolt.pos += bolt.vel*dt
		bolt.life -= dt
		if bolt.life<=0: continue
		if bolt.hostile and Geometry2D.get_closest_point_to_segment(pos,before,bolt.pos).distance_to(pos)<14:
			if invulnerable<=0 and dash_time<=0:
				hp -= 1
				invulnerable = 0.85
				events.append("hurt")
				if hp<=0: phase = "retry"; bolts.clear(); return
			continue
		var blocked := false
		for rect in Lab.solids():
			if Lab.blocks_segment(rect,before,bolt.pos): blocked = true; break
		if not blocked: remaining.append(bolt)
	bolts = remaining

func _threats(dt: float) -> void:
	var old_age := threat_age
	threat_age += dt
	for index in range(Lab.DRONES.size()):
		var offset := index*1.1
		if floor((old_age+offset)/3.5)<floor((threat_age+offset)/3.5):
			var origin: Vector2 = Lab.DRONES[index]
			bolts.append({"pos":origin,"vel":(pos-origin).normalized()*180,"life":3.4,"hostile":true})

func retry() -> void:
	phase = "lab"
	step = 5
	pos = Lab.RETRY
	hp = 3
	invulnerable = 1.5
	dash_time = 0
	dash_cooldown = 0
	used_dash = false
	repair = 0
	interaction_active = false
	threat_age = 0
	bolts.clear()
	conversation.clear()
