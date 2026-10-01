class_name P17Audio
extends Node
## Original, self-contained score and effects. All PCM is built once and cached.
## Playback uses native WAV streams; synthesis never runs in an audio callback.

const RATE := 22050
const MUSIC_DB := -13.0
const EFFECT_DB := -9.0
const MAX_VOICES := 10
const EnemyAudio := preload("res://scripts/enemy_audio.gd")

var _music: Array[AudioStreamPlayer] = []
var _voices: Array[AudioStreamPlayer] = []
var _structure_hum: AudioStreamPlayer
var _tracks: Dictionary = {}
var _effects: Dictionary = {}
var _notes: Dictionary = {}
var _current := -1
var _voice_index := 0
var _mood := ""
var _muted := false
var _warmed := false
var _fade: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_prepare_players()
	warm_up()


func warm_up() -> void:
	if _warmed:
		return
	# Pay synthesis cost at boot, before play begins, never at an encounter trigger.
	for mood in ["menu", "calm", "combat", "boss", "victory", "suspense"]:
		if not _tracks.has(mood):
			_tracks[mood] = _compose(mood)
	for id in ["shoot", "hurt", "dash", "enemy_dead", "repair", "boss", "complete", "ui"]:
		_effects[id] = _make_effect(id)
	for kind in EnemyAudio.KINDS:
		for event in EnemyAudio.EVENTS:
			var id: String = "unit_" + kind + "_" + event
			_effects[id] = EnemyAudio.make_effect(id)
	_notes.clear()
	_warmed = true


func _prepare_players() -> void:
	if not _music.is_empty():
		return
	for index in range(2):
		var player := AudioStreamPlayer.new()
		player.name = "Music%d" % index
		player.volume_db = -80.0
		add_child(player)
		_music.append(player)
	for index in range(MAX_VOICES):
		var player := AudioStreamPlayer.new()
		player.name = "Effect%d" % index
		player.volume_db = EFFECT_DB
		add_child(player)
		_voices.append(player)
	_structure_hum = AudioStreamPlayer.new()
	_structure_hum.name = "StructureHum"
	_structure_hum.volume_db = -36.0
	add_child(_structure_hum)


func set_mood(mood: String) -> void:
	_prepare_players()
	if mood not in ["menu", "calm", "combat", "boss", "victory", "suspense"]:
		mood = "calm"
	if _mood == mood:
		return
	_mood = mood
	if not _tracks.has(mood):
		_tracks[mood] = _compose(mood)
	if is_instance_valid(_fade):
		_fade.kill()
	var old := _current
	_current = 0 if _current != 0 else 1
	var next := _music[_current]
	next.stop()
	next.stream = _tracks[mood]
	next.volume_db = -80.0 if _muted else -36.0
	next.play()
	if _muted:
		if old >= 0:
			_music[old].stop()
		return
	_fade = create_tween().set_parallel(true)
	_fade.tween_property(next, "volume_db", MUSIC_DB, 0.8)
	if old >= 0:
		var previous := _music[old]
		_fade.tween_property(previous, "volume_db", -50.0, 0.7)
		_fade.chain().tween_callback(previous.stop)


func set_muted(value: bool) -> void:
	_muted = value
	if is_instance_valid(_fade):
		_fade.kill()
	for index in range(_music.size()):
		_music[index].volume_db = MUSIC_DB if not value and index == _current else -80.0
		if index != _current:
			_music[index].stop()
	if value:
		for voice in _voices:
			voice.stop()
		if _structure_hum:
			_structure_hum.stop()


func set_structure_hum(active: bool, proximity: float) -> void:
	_prepare_players()
	if _muted or not active or proximity <= 0.01:
		if _structure_hum.playing:
			_structure_hum.stop()
		return
	if _structure_hum.stream == null:
		_structure_hum.stream = _make_structure_hum()
	_structure_hum.volume_db = lerpf(-34.0, -20.0, clampf(proximity, 0.0, 1.0))
	if not _structure_hum.playing:
		_structure_hum.play()


func play_sfx(id: String) -> void:
	if _muted:
		return
	_prepare_players()
	if not _effects.has(id):
		_effects[id] = _make_effect(id)
	var voice := _voices[_voice_index]
	# A fixed pool caps overlap; shots generate neither nodes nor new PCM buffers.
	_voice_index = (_voice_index + 1) % MAX_VOICES
	voice.stop()
	voice.stream = _effects[id]
	voice.volume_db = EFFECT_DB - (4.0 if id == "shoot" else 0.0)
	if id.begins_with("unit_"):
		voice.volume_db -= 9.0 if id.ends_with("hit") else 5.0
	voice.play()


func _compose(mood: String) -> AudioStreamWAV:
	var urgent := mood in ["combat", "boss", "suspense"]
	var boss := mood == "boss"
	var suspense := mood == "suspense"
	var bright := mood == "victory"
	var step := 0.30 if not urgent else (0.19 if boss else 0.235)
	if suspense:
		step = 0.29
	var step_count := 32
	var result := PackedFloat32Array()
	result.resize(int(RATE * step * step_count))
	# D minor/add9, Bb major, F major, C suspended; an original eight-bar phrase.
	var roots: Array[int] = [38, 34, 41, 36]
	var melody: Array[int] = [62, 69, 65, 64, 62, 57, 60, 64,
		58, 65, 62, 60, 58, 65, 69, 65,
		65, 72, 69, 67, 65, 60, 64, 67,
		60, 67, 64, 62, 60, 64, 69, 64]
	if bright:
		roots = [38, 43, 46, 45]
		melody = [62, 66, 69, 74, 73, 69, 66, 64,
			67, 71, 74, 79, 78, 74, 71, 69,
			70, 74, 77, 82, 81, 77, 74, 72,
			69, 73, 76, 81, 76, 73, 69, 62]
	for beat in range(step_count):
		var root_note: int = roots[beat / 8]
		var offset := int(beat * step * RATE)
		if beat % 4 == 0:
			_mix(result, _tone(root_note, step * 3.9, "bass"), offset, 0.34 if urgent else 0.27)
		if beat % 8 == 0 and not boss:
			for interval in [12, 19, 26]:
				_mix(result, _tone(root_note + interval, step * 7.9, "pad"), offset, 0.11)
		var melody_note: int = melody[beat]
		if urgent:
			melody_note -= 12
		if not suspense or beat % 2 == 0:
			_mix(result, _tone(melody_note, step * (0.75 if urgent else 1.7), "pluck"), offset, 0.12 if suspense else 0.20)
		if urgent:
			_mix(result, _tone(root_note + 12 + (7 if beat % 2 else 0), step * 0.7, "pulse"), offset, 0.06 if suspense else 0.12)
			if beat % 4 == 0 or (boss and beat % 4 == 2):
				_mix(result, _percussion("kick", step * 0.8), offset, 0.15 if suspense else 0.30)
			if beat % 8 == 4 and not suspense:
				_mix(result, _percussion("snare", 0.14), offset, 0.13)
			if not suspense:
				_mix(result, _percussion("hat", 0.045), offset, 0.045 if beat % 2 else 0.075)
		elif beat % 8 == 4:
			_mix(result, _percussion("hat", 0.07), offset, 0.025)
	return _wav(result, true)


func _tone(midi: int, seconds: float, voice: String) -> PackedFloat32Array:
	var key := "%d/%.3f/%s" % [midi, seconds, voice]
	if _notes.has(key):
		return _notes[key]
	var data := PackedFloat32Array()
	data.resize(maxi(1, int(seconds * RATE)))
	var hz := 440.0 * pow(2.0, float(midi - 69) / 12.0)
	for index in range(data.size()):
		var t := float(index) / RATE
		var phase := TAU * hz * t
		var sample := sin(phase)
		var attack := minf(t / 0.012, 1.0)
		var release := minf((seconds - t) / 0.065, 1.0)
		var envelope := attack * release
		match voice:
			"pluck":
				sample = sin(phase) * 0.70 + sin(phase * 2.0) * 0.21 + sin(phase * 3.0) * 0.09
				envelope *= exp(-t * 4.1)
			"bass":
				sample = sin(phase) * 0.85 + sin(phase * 2.0) * 0.15
				envelope *= exp(-t * 1.7)
			"pad":
				sample = sin(phase) * 0.5 + sin(phase * 1.003) * 0.3 + sin(phase * 0.998) * 0.2
				envelope *= minf(t / 0.15, 1.0) * minf((seconds - t) / 0.3, 1.0)
			"pulse":
				sample = sin(phase) * 0.64 + sin(phase * 3.0) * 0.23 + sin(phase * 5.0) * 0.13
				envelope *= exp(-t * 8.0)
		data[index] = sample * envelope
	_notes[key] = data
	return data


func _percussion(kind: String, seconds: float) -> PackedFloat32Array:
	var key := "drum/%s/%.3f" % [kind, seconds]
	if _notes.has(key):
		return _notes[key]
	var rng := RandomNumberGenerator.new()
	rng.seed = 170619
	var data := PackedFloat32Array()
	data.resize(int(seconds * RATE))
	var phase := 0.0
	var last_noise := 0.0
	for index in range(data.size()):
		var t := float(index) / RATE
		var noise := rng.randf_range(-1.0, 1.0)
		var sample := noise
		if kind == "kick":
			phase += TAU * (48.0 + 105.0 * exp(-t * 35.0)) / RATE
			sample = sin(phase) * exp(-t * 20.0)
		elif kind == "snare":
			sample = (noise * 0.7 + sin(t * TAU * 170.0) * 0.3) * exp(-t * 27.0)
		else:
			sample = (noise - last_noise) * 0.5 * exp(-t * 62.0)
		last_noise = noise
		data[index] = sample * minf(t / 0.002, 1.0) * minf((seconds - t) / 0.012, 1.0)
	_notes[key] = data
	return data


func _make_effect(id: String) -> AudioStreamWAV:
	if id.begins_with("unit_"):
		return EnemyAudio.make_effect(id)
	var duration := 0.18
	match id:
		"shoot": duration = 0.09
		"hurt": duration = 0.25
		"dash": duration = 0.21
		"enemy_dead": duration = 0.32
		"repair": duration = 0.70
		"boss": duration = 0.8
		"complete": duration = 1.15
		"ui": duration = 0.08
	var samples := PackedFloat32Array()
	samples.resize(int(duration * RATE))
	var rng := RandomNumberGenerator.new()
	rng.seed = 170017
	var phase := 0.0
	for index in range(samples.size()):
		var t := float(index) / RATE
		var p := t / duration
		var hz := 650.0
		var noise := rng.randf_range(-1.0, 1.0)
		var noise_amount := 0.0
		match id:
			"shoot": hz = lerpf(1250.0, 280.0, pow(p, 0.45))
			"hurt":
				hz = lerpf(170.0, 68.0, p)
				noise_amount = 0.22
			"dash":
				hz = lerpf(320.0, 1450.0, p)
				noise_amount = 0.72
			"enemy_dead":
				hz = lerpf(260.0, 42.0, p)
				noise_amount = 0.50
			"repair": hz = 440.0 * pow(2.0, float([2, 5, 9, 14][mini(3, int(p * 4.0))]) / 12.0)
			"boss":
				hz = 74.0 + sin(t * 15.0) * 12.0
				noise_amount = 0.10
			"complete": hz = 440.0 * pow(2.0, float([2, 5, 9, 14, 17][mini(4, int(p * 5.0))]) / 12.0)
			"ui": hz = 880.0 + p * 220.0
		phase += TAU * hz / RATE
		var wave := sin(phase) * 0.76 + sin(phase * 2.0) * 0.16 + sin(phase * 3.0) * 0.08
		var envelope := minf(t / 0.006, 1.0) * pow(1.0 - p, 1.5)
		if id in ["repair", "complete"]:
			var note_phase := fmod(p * (4.0 if id == "repair" else 5.0), 1.0)
			envelope *= minf(note_phase * 15.0, 1.0) * minf((1.0 - note_phase) * 8.0, 1.0)
		samples[index] = lerpf(wave, noise, noise_amount) * envelope * 0.68
	return _wav(samples, false)


func _make_structure_hum() -> AudioStreamWAV:
	var duration := 1.6
	var samples := PackedFloat32Array()
	samples.resize(int(duration * RATE))
	for index in range(samples.size()):
		var t := float(index) / RATE
		var low := sin(TAU * 55.0 * t) * 0.25 + sin(TAU * 110.0 * t) * 0.09
		var motor := sin(TAU * 27.5 * t + sin(TAU * 0.625 * t) * 0.12) * 0.08
		var pulse := pow(maxf(0.0, sin(TAU * 1.25 * t)), 12.0) * sin(TAU * 330.0 * t) * 0.10
		samples[index] = (low + motor + pulse) * 0.42
	return _wav(samples, true)


func _mix(target: PackedFloat32Array, source: PackedFloat32Array, offset: int, gain: float) -> void:
	# Wrap note tails across the phrase boundary for a click-free continuous loop.
	for index in range(source.size()):
		var destination := (offset + index) % target.size()
		target[destination] += source[index] * gain


func _wav(samples: PackedFloat32Array, loop: bool) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for index in range(samples.size()):
		var value := clampf(samples[index], -0.95, 0.95)
		var pcm := int(value * 32767.0)
		bytes[index * 2] = pcm & 255
		bytes[index * 2 + 1] = (pcm >> 8) & 255
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = bytes
	if loop:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = samples.size()
	return stream
