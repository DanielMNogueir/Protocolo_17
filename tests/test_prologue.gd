extends SceneTree
const Intro = preload("res://scripts/prologue.gd")
const Lab = preload("res://scripts/laboratory_world.gd")
var failures: Array[String] = []
var checks := 0

func _initialize() -> void: _run.call_deferred()
func check(value: bool, label: String) -> void:
	checks += 1
	if not value: failures.append(label)

func _dismiss(story: P17Prologue) -> void:
	for guard in range(50):
		if story.phase!="context" and story.conversation.is_empty(): return
		story.advance()

func route(start: Vector2, goal: Vector2) -> Array[Vector2]:
	var origin := Vector2i(roundi(start.x/10),roundi(start.y/10))
	var destination := Vector2i(roundi(goal.x/10),roundi(goal.y/10))
	var queue: Array[Vector2i] = [origin]
	var parents := {origin:origin}
	var cursor := 0
	var found := false
	while cursor<queue.size():
		var cell: Vector2i = queue[cursor]
		cursor += 1
		if cell==destination: found = true; break
		for direction in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			var next: Vector2i = cell+direction
			if parents.has(next) or not Lab.walkable(Vector2(next)*10) or not Lab.walkable((Vector2(cell)+Vector2(next))*5): continue
			parents[next] = cell
			queue.append(next)
	if not found: return []
	var result: Array[Vector2] = [goal]
	var current := destination
	while current!=origin:
		result.push_front(Vector2(current)*10)
		current = parents[current]
	return result

func walk(story: P17Prologue, goal: Vector2, protect: bool = true) -> void:
	var path := route(story.pos,goal)
	check(not path.is_empty(),"Reachable tutorial station: "+str(goal))
	for point in path:
		for frame in range(250):
			if story.pos.distance_to(point)<4: break
			if not story.conversation.is_empty(): _dismiss(story)
			if protect: story.invulnerable = 1 # Only isolate route/progression from combat difficulty.
			story.tick(1.0/60,(point-story.pos).normalized(),goal,false,false,false)
			check(Lab.walkable(story.pos),"Real tutorial movement respects the laboratory footprints")
	check(story.pos.distance_to(goal)<10,"Bot reaches station through movement, without teleporting")

func interact(story: P17Prologue) -> void:
	_dismiss(story)
	var initial := story.step
	for frame in range(180):
		story.invulnerable = 1
		story.tick(1.0/60,Vector2.ZERO,story.pos+Vector2.UP,false,false,frame==0)
		if story.step!=initial: break
	check(story.step!=initial,"One E press completes tutorial action after release "+str(initial))
	_dismiss(story)

func _run() -> void:
	var story := Intro.new()
	check(story.visible_text().is_empty(),"World context starts with progressive text")
	story.advance()
	check(story.text_complete() and story.page==0,"First Enter reveals current sentence without skipping the page")
	story.advance()
	check(story.phase=="lab","Second Enter enters the laboratory from the single context page")
	story.fast_text = true
	check(story.visible_text()==story.text(),"Instant text reveals the entire sentence")
	_dismiss(story)
	check(story.phase=="lab" and story.step==0,"Context enters playable laboratory")
	walk(story,Intro.TARGETS[0])
	_dismiss(story)
	check(story.step==1,"Movement reaches the first tutorial objective")
	walk(story,Lab.CALIBRATION)
	interact(story)
	walk(story,Lab.ANALYSIS)
	interact(story)
	check(story.step==3,"Environmental report triggers containment")
	walk(story,Intro.TARGETS[3])
	for frame in range(60): story.tick(1.0/60,Vector2.ZERO,Lab.RELAY,true,false,false)
	check(story.step==3 and story.bolts.is_empty(),"Shooting no longer advances the actuator objective")
	interact(story)
	check(story.step==4,"One E press disables the actuator after remaining nearby")
	walk(story,Lab.ISOLATION)
	interact(story)
	check(story.step==5,"Isolation opens the escape objective")
	story.invulnerable = 0
	story.tick(1.0/60,Vector2.RIGHT,story.pos+Vector2.RIGHT,false,true,false)
	check(story.velocity.length()==225 and not story.events.has("dash"),"Shift has no movement effect in the prologue")
	walk(story,Intro.TARGETS[5],false)
	_dismiss(story)
	check(story.step==6 and story.hp>0,"Walking to the archive survives and advances without Shift")
	walk(story,Lab.ARCHIVE)
	interact(story)
	check(story.record_saved and story.phase=="ending","Successful archive action precedes the scripted death")
	for frame in range(700): story.tick(1.0/60,Vector2.ZERO,Vector2.ZERO,false,false,false)
	check(not story.finished and story.phase=="handoff","Lia handoff waits for the player to read the transmission")
	story.advance()
	check(story.finished,"Confirming the handoff enters Lia's campaign")
	var recovery := Intro.new()
	recovery.phase = "lab"
	recovery.step = 6
	recovery.hp = 1
	recovery.pos = Lab.ESCAPE
	recovery.bolts.append({"pos":recovery.pos-Vector2(5,0),"vel":Vector2(200,0),"life":1.0,"hostile":true})
	recovery.tick(0.04,Vector2.ZERO,recovery.pos+Vector2.UP,false,false,false)
	check(recovery.phase=="retry","Early damage provides a retry rather than the narrative ending")
	recovery.retry()
	check(recovery.phase=="lab" and recovery.step==5 and recovery.hp==3 and recovery.bolts.is_empty(),"Retry resumes at containment with restored health")
	check(not Lab.walkable(Lab.CORE),"Core footprint blocks walking")
	var tapping := Intro.new()
	tapping.phase = "lab"
	tapping.step = 1
	tapping.pos = Lab.START
	tapping.tick(0.05,Vector2.ZERO,tapping.pos,false,false,true)
	tapping.pos = Lab.CALIBRATION
	tapping.tick(0.05,Vector2.ZERO,tapping.pos,false,false,false)
	check(not tapping.interaction_active and tapping.repair==0,"An out-of-range press does not start an action later")
	tapping.tick(0.05,Vector2.ZERO,tapping.pos,false,false,true)
	check(tapping.interaction_active and tapping.repair>0,"A single press starts progress at the station")
	tapping.pos = Lab.START
	tapping.tick(0.05,Vector2.ZERO,tapping.pos,false,false,false)
	check(not tapping.interaction_active and tapping.repair==0,"Leaving the station cancels automatic progress")
	tapping.pos = Lab.CALIBRATION
	tapping.tick(0.05,Vector2.ZERO,tapping.pos,false,false,false)
	check(not tapping.interaction_active,"Returning to the station requires a fresh press")
	tapping.tick(0.05,Vector2.ZERO,tapping.pos,false,false,true)
	tapping.retry()
	check(not tapping.interaction_active and tapping.repair==0,"Retry clears the pending interaction")
	var accelerating := Intro.new()
	for frame in range(160): accelerating.tick(0.05,Vector2.ZERO,Vector2.ZERO,false,false,false,true)
	check(accelerating.phase=="context" and accelerating.text_complete(),"Holding Enter reveals the current line without changing page or phase")
	accelerating.advance()
	var first_line: String = accelerating.text()
	for frame in range(160): accelerating.tick(0.05,Vector2.RIGHT,accelerating.pos,false,false,true,true)
	check(accelerating.phase=="lab" and accelerating.text()==first_line and accelerating.text_complete(),"Holding Enter never consumes the next line, even after it is complete")
	accelerating.advance()
	check(accelerating.conversation.is_empty() and accelerating.step==0,"Only explicit advance dismisses the revealed greeting")
	var flowing := Intro.new()
	flowing.phase = "lab"
	flowing.pos = Lab.START
	flowing._say([["beatrix","Vou conferir o circuito."]])
	var origin := flowing.pos
	flowing.tick(0.05,Vector2.RIGHT,flowing.pos+Vector2.RIGHT,false,false,false)
	check(flowing.pos==origin,"Routine dialogue waits for the reader before resuming the tutorial")
	for frame in range(70): flowing.tick(0.05,Vector2.ZERO,flowing.pos,false,false,false)
	check(not flowing.conversation.is_empty() and flowing.text_complete(),"A completed line remains visible regardless of elapsed time")
	flowing.fast_text = true
	for frame in range(600): flowing.tick(0.05,Vector2.RIGHT,flowing.pos,true,true,true)
	check(flowing.conversation.size()==1 and flowing.pos==origin and flowing.step==0,"Instant text, movement and actions cannot replace an unread line")
	flowing._say([["beatrix","Primeira fala."],["system","Segunda fala."]])
	flowing.advance()
	check(flowing.conversation.size()==1 and flowing.text()=="Segunda fala.","One advance consumes exactly one complete line")
	for frame in range(600): flowing.tick(0.05,Vector2.ZERO,flowing.pos,false,false,false,true)
	check(flowing.text()=="Segunda fala.","The following line also waits while Enter is held")
	flowing.advance()
	check(flowing.conversation.is_empty(),"A fresh advance finishes the final line")
	flowing.step = 7
	flowing._say([["system","Registro final."]])
	for frame in range(160): flowing.tick(0.05,Vector2.ZERO,flowing.pos,false,false,false)
	check(flowing.phase=="lab" and not flowing.conversation.is_empty(),"Ending cannot start before the player dismisses the final speech")
	flowing.advance()
	check(flowing.phase=="ending","Explicit advance starts the ending after its last speech")
	flowing.phase = "lab"
	flowing.step = 0
	flowing._say([["system","Iniciando contenção."]],true)
	origin = flowing.pos
	flowing.tick(0.05,Vector2.RIGHT,flowing.pos,false,false,true)
	check(flowing.pos==origin and flowing.repair==0,"Critical reveal pauses actions while the line is read")
	print("PROLOGUE_%s: %d checks; %d failures" % ["OK" if failures.is_empty() else "FAILED",checks,failures.size()])
	for failure in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)
