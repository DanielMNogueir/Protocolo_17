extends Node2D
## Screen-space canvas for the shared RPG dialogue frame in Residues. The
## DialoguePanel draws through _text and _wrapped, like Energy's HUD.
const Dialogue = preload("res://scripts/dialogue_panel.gd")
var game: Node2D
## The panel registers its click areas on the canvas, as in Energy's HUD.
var buttons: Array[Dictionary]:
	get: return game.buttons
var pointer: Vector2:
	get: return game.pointer

func _draw() -> void:
	if game == null or game.state != "dialogue": return
	var line: Dictionary = game.dialogue_line()
	if line.is_empty(): return
	var size := get_viewport_rect().size
	draw_rect(Rect2(Vector2(0, size.y - 196), Vector2(size.x, 196)), Color(0.035, 0.1, 0.13, 0.35))
	var speaker: String = line.speaker
	var text := str(line.text)
	Dialogue.draw(self, size, speaker, str(line.label), text.left(int(game.dialogue_chars)), game.dialogue_complete(), game.dialogue_fast, game.clock, speaker == "terminal", "CONTINUAR" if game.dialogue.size() == 1 else "")

func _text(value: String, point: Vector2, size: int, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, point.round(), value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _wrapped(value: String, rect: Rect2, font_size: int, color: Color, line_height: int) -> void:
	var line := ""
	var y := rect.position.y + font_size
	for word in value.split(" "):
		var candidate := word if line.is_empty() else line + " " + word
		if ThemeDB.fallback_font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > rect.size.x and not line.is_empty():
			_text(line, Vector2(rect.position.x, y), font_size, color)
			line = word
			y += line_height
		else:
			line = candidate
	_text(line, Vector2(rect.position.x, y), font_size, color)
