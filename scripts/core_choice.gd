extends RefCounted

const Story = preload("res://scripts/core_story.gd")
const HOLD_TIME := 2.5
const TAP_TIME := 0.25

var heard_ai := 0
var heard_human := 0
var weighed := false
var hold := 0.0
var holding := ""
var result := ""


func can_decide() -> bool:
	return heard_ai > 0 and heard_human > 0


func listen(side: String) -> Dictionary:
	if side == "ai":
		var line: Dictionary = Story.AI_CASE[mini(heard_ai, Story.AI_CASE.size() - 1)]
		heard_ai = mini(heard_ai + 1, Story.AI_CASE.size())
		return line.duplicate()
	if side == "human":
		var line: Dictionary = Story.HUMAN_CASE[mini(heard_human, Story.HUMAN_CASE.size() - 1)]
		heard_human = mini(heard_human + 1, Story.HUMAN_CASE.size())
		return line.duplicate()
	return {}


func weigh() -> bool:
	if weighed or not can_decide():
		return false
	weighed = true
	return true


func tick(dt: float, side: String, held: bool) -> String:
	if not result.is_empty():
		return ""
	if not held or side not in ["ai", "human"] or not can_decide():
		hold = 0.0
		holding = ""
		return ""
	if side != holding:
		hold = 0.0
		holding = side
	hold = minf(1.0, hold + dt / HOLD_TIME)
	if hold < 1.0 - 0.00001:
		return ""
	result = "ai" if side == "ai" else "humanity"
	return "decided"


func reopen() -> void:
	hold = 0.0
	holding = ""
	result = ""
