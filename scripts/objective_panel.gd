@tool
extends Node2D
## Native scene counterpart of the energy control cabinet.
const Objectives = preload("res://scripts/objective_visual.gd")
@export var online := false:
	set(value):
		online = value
		queue_redraw()
@export_range(0.0,1.0) var repair := 0.0:
	set(value):
		repair = value
		queue_redraw()
var clock := 0.0

func _process(delta: float) -> void:
	if not is_visible_in_tree(): return
	clock += delta
	queue_redraw()

func _draw() -> void:
	Objectives.draw_foundation(self,Vector2.ZERO,1,online,clock)
	Objectives.draw_body(self,Vector2.ZERO,1,online,clock,false,repair)
