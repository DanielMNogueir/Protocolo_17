extends SceneTree
const Presentation = preload("res://scripts/enemy_presentation.gd")
const Art = preload("res://scripts/enemy_art.gd")
const Audio = preload("res://scripts/enemy_audio.gd")
const Simulation = preload("res://scripts/simulation.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func _run() -> void:
	var sim = Simulation.new()
	sim.start()
	var presentation = Presentation.new()
	var before := var_to_str([sim.enemies, sim.pos, sim.bullets, sim.hp, sim.state, sim.stage, sim.events])
	presentation.advance(.016, sim.enemies, 0, .016)
	check(before == var_to_str([sim.enemies, sim.pos, sim.bullets, sim.hp, sim.state, sim.stage, sim.events]), "Presentation cannot mutate combat")
	var enemy: Dictionary = sim.enemies[0]
	var id: int = enemy.id
	enemy.phase = "windup"
	enemy.warning = .65
	presentation.advance(.016, sim.enemies, 0, .032)
	check(presentation.cues.size() == 1 and presentation.cues[0].id.ends_with("windup"), "One warning cue at the start of preparation")
	presentation.advance(.016, sim.enemies, 0, .048)
	check(presentation.cues.is_empty(), "A held warning does not spam sound")
	enemy.phase = "idle"
	enemy.warning = 0.0
	presentation.advance(.016, sim.enemies, 0, .064)
	check(presentation.units[id].attack_age == 0 and presentation.cues[0].id.ends_with("fire"), "Attack animation and sound begin on the combat transition")
	enemy.hp -= 1
	presentation.advance(.016, sim.enemies, 0, .08)
	check(presentation.cues[0].id.ends_with("hit"), "Damage generates the mechanical impact cue")
	var frozen: String = var_to_str(presentation.units)
	presentation.advance(0.0, sim.enemies, 0, .08)
	check(frozen == var_to_str(presentation.units), "Pause freezes enemy animation")
	sim.enemies.remove_at(0)
	presentation.advance(.016, sim.enemies, 0, .096)
	check(presentation.wrecks.size() == 1 and presentation.cues[0].id.ends_with("death"), "Removed enemy creates one transient destruction effect")
	presentation.advance(.5, sim.enemies, 0, .596)
	check(presentation.wrecks.size() == 1, "Destruction remains visible after combat removal")
	presentation.advance(.6, sim.enemies, 0, 1.196)
	check(presentation.wrecks.is_empty(), "Destruction expires without adding world objects")
	presentation.advance(.016, sim.enemies, 1, 1.212)
	check(presentation.cues.is_empty(), "Stage transition does not invent deaths or sounds")

	Art.prepare()
	var total := 0
	for kind in Audio.KINDS:
		var texture: Texture2D = Art._textures[kind]
		var source := texture.get_image()
		check(source.get_pixel(0, 0).a == 0.0, "Transparent background: " + kind)
		check(Art._data[kind].frames.size() == 16, "Eight headings with two source frames: " + kind)
		var signatures := {}
		for frame in Art._data[kind].frames:
			var region := Rect2i(frame.region[0], frame.region[1], frame.region[2], frame.region[3])
			check(Rect2i(Vector2i.ZERO, source.get_size()).encloses(region), "Frame lies inside atlas")
			var pixels := source.get_region(region)
			check(pixels.get_used_rect().has_area(), "Frame has visible sprite pixels")
			var hash := HashingContext.new()
			hash.start(HashingContext.HASH_SHA256)
			hash.update(pixels.get_data())
			var signature := hash.finish().hex_encode()
			check(not signatures.has(signature), "Distinct authored direction or animation frame")
			signatures[signature] = true
			total += 1
	check(total == 64, "All four enemy atlases are integrated")
	var sound_hashes := {}
	DirAccess.make_dir_recursive_absolute("res://.runtime/enemy_review")
	for kind in Audio.KINDS:
		for event in Audio.EVENTS:
			var id_sound: String = "unit_" + kind + "_" + event
			var stream := Audio.make_effect(id_sound)
			var hash := HashingContext.new()
			hash.start(HashingContext.HASH_SHA256)
			hash.update(stream.data)
			var signature := hash.finish().hex_encode()
			check(not sound_hashes.has(signature), "Distinct sound: " + id_sound)
			sound_hashes[signature] = true
			var peak := 0
			for i in stream.data.size() / 2:
				peak = maxi(peak, absi(stream.data.decode_s16(i * 2)))
			check(peak > 1000 and peak < 31000, "Audible sound without clipping: " + id_sound)
			stream.save_to_wav("res://.runtime/enemy_review/" + id_sound + ".wav")
	print("ENEMY_PRESENTATION_%s: %d checks; %d failures" % ["OK" if failures == 0 else "FAILED", checks, failures])
	quit(0 if failures == 0 else 1)
