extends RefCounted
## Original deterministic layered mechanical sounds, synthesized once at boot.
const RATE := 22050
const KINDS := ["scout", "sentry", "rammer", "boss"]
const EVENTS := ["wake", "windup", "fire", "hit", "death"]

static func make_effect(id: String) -> AudioStreamWAV:
	var words := id.split("_")
	var kind: String = words[1]
	var event: String = words[2]
	var base: float = {"scout": 620.0, "sentry": 230.0, "rammer": 115.0, "boss": 58.0}.get(kind, 230.0)
	var duration: float = {"wake": .28, "windup": .60, "fire": .24, "hit": .13, "death": .68}[event]
	if kind == "boss": duration *= 1.35
	var bytes := PackedByteArray()
	bytes.resize(int(duration * RATE) * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = id.hash()
	var phase := 0.0
	var filtered_noise := 0.0
	for i in bytes.size() / 2:
		var t := float(i) / RATE
		var p := t / duration
		var hz := base
		var envelope := minf(t / .008, 1.0) * pow(1.0 - p, 1.8)
		var noise_amount := .12
		match event:
			"wake":
				hz *= 1.0 + floor(p * 3.0) * .25
				envelope *= .45 + .55 * pow(sin(p * PI * 3.0), 2)
			"windup":
				hz *= .65 + p * 1.6
				envelope = minf(t / .035, 1.0) * minf((duration - t) / .025, 1.0) * (.2 + p * .55)
				noise_amount = .22
			"fire":
				hz *= 1.6 * exp(-p * 5.0) + .35
				noise_amount = .50
			"hit":
				hz *= 2.8 - p
				noise_amount = .62
			"death":
				hz *= 1.3 * pow(1.0 - p, 2) + .12
				noise_amount = .72
				envelope *= .6 + .4 * absf(sin(t * 39.0))
		phase += TAU * hz / RATE
		filtered_noise = lerpf(filtered_noise, rng.randf_range(-1, 1), .18 if kind == "boss" else .55)
		var metal := sin(phase + sin(phase * 1.73) * .8) * .55 + sin(phase * 2.71) * .18
		var motor := sin(phase * .5) * (.25 if kind in ["rammer", "boss"] else .08)
		var pulse := .8 + .2 * sin(t * TAU * (38.0 if kind == "scout" else 17.0))
		var sample := (metal * (1.0 - noise_amount) + filtered_noise * noise_amount + motor) * envelope * pulse * .75
		var pcm := int(clampf(sample, -.9, .9) * 32767.0)
		bytes[i * 2] = pcm & 255
		bytes[i * 2 + 1] = (pcm >> 8) & 255
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.data = bytes
	return stream
