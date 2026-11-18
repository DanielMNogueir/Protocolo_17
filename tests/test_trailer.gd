extends SceneTree
## The story trailer ships with the game, loads as a video and is skippable.
## Playback itself needs a window: tools/ captures cover that.
const Main = preload("res://scripts/main.gd")

func _initialize() -> void:
	var failures: Array[String] = []
	if not ResourceLoader.exists(Main.TRAILER_PATH): failures.append("Trailer file is missing")
	var stream := load(Main.TRAILER_PATH) as VideoStream
	if stream == null: failures.append("Trailer does not load as a VideoStream")
	elif not stream is VideoStreamTheora: failures.append("Trailer must be Ogg Theora (.ogv)")
	if Main.TRAILER_SKIP_DELAY > 1.0: failures.append("Skip must be available almost immediately")
	for failure in failures: push_error(failure)
	print("TRAILER_OK" if failures.is_empty() else "TRAILER_FAILED: %s" % [failures])
	quit(0 if failures.is_empty() else 1)
