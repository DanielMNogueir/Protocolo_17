extends SceneTree
## The game must not load files the Windows export leaves out (docs/, tools/,
## captures/...): in the exe they do not exist, and the humanity ending once
## froze on an image read from docs/.
const EXCLUDED := ["res://docs/", "res://tools/", "res://tests/", "res://captures/", "res://review_captures/",
	"res://update_captures/", "res://output/", "res://build/"]

func _initialize() -> void:
	var failures: Array[String] = []
	var checked := 0
	for folder in ["res://scripts", "res://scenes", "res://assets"]:
		for file in _files(folder):
			if not (file.ends_with(".gd") or file.ends_with(".tscn") or file.ends_with(".tres")): continue
			checked += 1
			var text := FileAccess.get_file_as_string(file)
			for prefix in EXCLUDED:
				if text.contains(prefix): failures.append("%s uses %s, which the export leaves out" % [file, prefix])
	for failure in failures: push_error(failure)
	print("EXPORT_PATHS_OK: %d files" % checked if failures.is_empty() else "EXPORT_PATHS_FAILED: %s" % [failures])
	quit(0 if failures.is_empty() else 1)

func _files(folder: String) -> Array[String]:
	var result: Array[String] = []
	var dir := DirAccess.open(folder)
	if dir == null: return result
	for file in dir.get_files(): result.append(folder.path_join(file))
	for sub in dir.get_directories(): result.append_array(_files(folder.path_join(sub)))
	return result
