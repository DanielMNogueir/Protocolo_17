extends "res://tests/test_beta_playthrough.gd"
func _run() -> void:
	var reports: Array=[]
	var loadouts: Array=[[0,0,0],[2,2,2],[1,1,1]]
	for level in S.DIFFICULTIES:
		for route in 3:
			orbit_bias = -1.0 if route%2==0 else 1.0
			var sim: P17Simulation=S.new()
			sim.start(0,level)
			print("ENDURANCE_BEGIN level=",level," loadout=",loadouts[route])
			for stage in 4:
				var finished:=false
				for attempt in 8:
					orbit_bias = 1.0 if (route+attempt)%2 else -1.0
					combat_range = [280.0,240.0,320.0,360.0][attempt%4]
					var clear:=_fight(sim)
					if clear:
						for task in 2:
							if not _complete_field_task(sim):
								clear=false
								break
							clear=_fight(sim)
							if not clear: break
					if clear and sim.operation.ready() and _walk_to(sim,W.GOALS[stage]):
						for frame in 120: sim.tick(DT,Vector2.ZERO,sim.pos+Vector2.UP,false,false,true)
						finished=sim.restored==stage+1
						if finished: break
					if sim.state!="defeat": break
					print("ENDURANCE_RETRY level=",level," route=",route," stage=",stage+1," attempt=",attempt+1)
					sim.retry()
				check(finished,"Endurance completes %s/%d sector %d" % [level,route,stage+1])
				if not finished: break
				if stage<3: sim.choose_upgrade(loadouts[route][stage])
			var report:=sim.save_data()
			report["victory"]=sim.state=="victory"
			report["loadout"]=loadouts[route]
			report["hp"]=sim.hp
			reports.append(report)
			check(sim.state=="victory","Endurance reaches ending: %s/%d" % [level,route])
			print("ENDURANCE_RESULT ",JSON.stringify(report))
	var file:=FileAccess.open("res://.runtime/beta_endurance.json",FileAccess.WRITE)
	if file!=null: file.store_string(JSON.stringify(reports,"  "))
	print("BETA_ENDURANCE_%s: %d checks; %d frames; %d failures" % ["OK" if failures.is_empty() else "FAILED",checks,bot_frames,failures.size()])
	quit(0 if failures.is_empty() else 1)
