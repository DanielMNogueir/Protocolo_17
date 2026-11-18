extends SceneTree

const Boss = preload("res://scripts/core_boss.gd")
const Map = preload("res://scripts/core_map.gd")
var failures := 0

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	var boss := Boss.new()
	check(not boss.hit_core(200.0) and boss.integrity == 1.0, "Armored Core takes no pulse damage")
	check(boss.press_pillar(0) == "start" and boss.press_pillar(0) == "miss", "An early press discharges the pillar")
	check(boss.press_pillar(0).is_empty(), "A discharge locks the pillar")
	boss.tick(3.0, Map.ARRIVAL, Vector2.ZERO, false)
	for index in 4:
		check(boss.press_pillar(index) == "start", "Start synchronizing the pillar")
		for hit in 3:
			boss.pillars[index].phase = boss.pillars[index].window_center()
			check(boss.press_pillar(index) == ("fallen" if hit == 2 else "hit"), "Three synchronized hits drop the pillar")
	check(boss.phase == 2 and boss.fallen_count() == 4, "All four pillars open the solar phase")
	check(not boss.hit_core(10.0), "A pulse cannot damage the Core before the beam")
	for index in 3:
		var turns := posmod(boss.mirrors.targets[index] - boss.mirrors.orientation[index], 8)
		check(turns >= 2, "Mirrors start off their lines")
		for turn in turns:
			check(boss.hit_mirror(index), "Shooting rotates the mirror one step")
			boss.mirrors.tick(0.33)
	boss.tick(6.0, Map.ARRIVAL, Vector2.ZERO, false)
	check(boss.burn == 6.0 and "sunrise" in boss.events, "Aligned mirrors start the beam at sunrise")
	boss.tick(2.0, Map.ARRIVAL, Vector2.ZERO, false)
	check(is_equal_approx(boss.integrity, 0.9), "Beam deals five percent per second in Operation")
	boss.tick(4.0, Map.ARRIVAL, Vector2.ZERO, false)
	check(boss.burn == 0.0 and boss.aligned_count() == 0 and "scramble" in boss.events, "Beam cycle scrambles the mirrors")
	boss.burn = 6.0
	check(boss.hit_core(60.0) and boss.phase == 3 and boss.integrity == 0.5, "Beam exposure unlocks phase 3")
	for i in 30:
		boss.observe(0.25, Map.CENTER + Vector2.RIGHT * 100, Vector2.DOWN * 200, true)
	check(is_equal_approx(boss.lateral_average(), 1.0) and Boss.BIAS.story == 0, "Observe lateral dodges without affecting Story aim")
	boss.tick(0.1, Map.ARRIVAL, Vector2.ZERO, false)
	boss.tick(0.1, Map.ARRIVAL, Vector2.ZERO, false)
	check(boss.events.count("adaptive") == 1, "Adaptive toast fires once")
	check(boss.hit_core(125.0) and boss.phase == 4 and "down" in boss.events, "Exposed Core can end the fight")
	check(Boss.new("veteran").pattern_timer < Boss.new("story").pattern_timer, "Veteran attacks more often")
	for phase in [1, 2, 3]:
		_test_patterns(phase)
	print("CORE_BOSS_OK" if failures == 0 else "CORE_BOSS_FAILED")
	quit(0 if failures == 0 else 1)

func _test_patterns(phase: int) -> void:
	var boss := Boss.new("operation", 1.0, phase)
	var expected: Array = [["fan", "laser", "call"], ["ring"], ["spiral", "aimed", "ring"]][phase - 1]
	var warnings := {}
	for i in 3600:
		var active := boss.attack
		var telegraph := boss.warning
		var requests := boss.tick(1.0 / 60.0, Map.ARRIVAL, Vector2.ZERO, false)
		if boss.warning > 0.0:
			warnings[boss.attack] = true
		if active == "ring" and telegraph > 0.0 and boss.warning == 0.0:
			check(requests.filter(func(item: Dictionary) -> bool: return item.kind == "orb").size() == (9 if phase == 2 else 13),
				"Each ring has a three-position gap")
	for name in expected: check(warnings.has(name), "Attack has a visible warning: " + name)
