extends SceneTree
func _initialize() -> void:
	var file := FileAccess.open("res://build/LICENCAS_DO_MOTOR.txt",FileAccess.WRITE)
	if file == null:
		push_error("Could not write runtime notices")
		quit(1)
		return
	file.store_string(Engine.get_license_text()+"\n\nTHIRD-PARTY COPYRIGHT NOTICES\n\n")
	file.store_string(JSON.stringify(Engine.get_copyright_info(),"  "))
	file.store_string("\n\nTHIRD-PARTY LICENSES\n\n")
	var licenses := Engine.get_license_info()
	for title in licenses:
		file.store_string(str(title)+"\n"+str(licenses[title])+"\n\n")
	file.close()
	print("RUNTIME_LICENSES_OK")
	quit()
