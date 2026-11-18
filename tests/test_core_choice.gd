extends SceneTree

const Choice = preload("res://scripts/core_choice.gd")
const Story = preload("res://scripts/core_story.gd")
var failures := 0

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	var choice := Choice.new()
	check(choice.tick(3.0, "ai", true).is_empty() and choice.hold == 0.0, "No decision before the arguments")
	for index in Story.AI_CASE.size():
		check(choice.listen("ai") == Story.AI_CASE[index], "Each tap advances an argument")
	check(choice.listen("ai") == Story.AI_CASE[-1] and not choice.weigh(), "Repeat the final argument and wait for Beatrix")
	choice.listen("human")
	check(choice.weigh() and not choice.weigh(), "Lia weighs the arguments once")
	check(choice.tick(1.0, "human", true).is_empty() and choice.hold > 0.0, "Holding fills the confirmation")
	choice.tick(0.0, "human", false)
	check(choice.hold == 0.0, "Release cancels the choice")
	choice.tick(2.4, "human", true)
	check(choice.tick(0.2, "ai", true).is_empty() and choice.hold < 0.1, "Changing consoles resets the hold")
	check(choice.tick(2.3, "ai", true) == "decided" and choice.result == "ai", "Magenta console releases the AI")
	check(choice.tick(3.0, "ai", true).is_empty(), "Decision only emits once")
	choice.reopen()
	check(choice.can_decide() and choice.tick(2.5, "human", true) == "decided" and choice.result == "humanity", "Return to choice can isolate the Core")
	print("CORE_CHOICE_OK" if failures == 0 else "CORE_CHOICE_FAILED")
	quit(0 if failures == 0 else 1)
