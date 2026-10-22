extends Node

const SAMPLE_RATE := 22050

var players: Dictionary = {}
var definitions: Dictionary = {
	"ui": Vector2(760.0, 0.045),
	"footstep": Vector2(105.0, 0.055),
	"footstep_heavy": Vector2(72.0, 0.085),
	"door": Vector2(330.0, 0.12),
	"pause": Vector2(390.0, 0.055),
	"clean": Vector2(435.0, 0.11),
	"pick_small": Vector2(715.0, 0.08),
	"carry_large": Vector2(290.0, 0.14),
	"drop": Vector2(245.0, 0.12),
	"trunk": Vector2(510.0, 0.13),
	"success": Vector2(880.0, 0.20),
	"call": Vector2(565.0, 0.10)
}


func _ready() -> void:
	for key in definitions:
		var entry: Vector2 = definitions[key]
		var sound := AudioStreamPlayer.new()
		sound.name = "Tone_" + str(key)
		sound.volume_db = -15.0 if key in ["footstep", "footstep_heavy"] else -8.0
		sound.stream = _make_tone(entry.x, entry.y)
		add_child(sound)
		players[key] = sound


func play_event(event_name: String) -> void:
	var sound: AudioStreamPlayer = players.get(event_name)
	if not is_instance_valid(sound):
		sound = players.get("ui")
	if is_instance_valid(sound):
		sound.stop()
		sound.play()


func _make_tone(frequency: float, duration: float) -> AudioStreamWAV:
	var count := maxi(1, int(SAMPLE_RATE * duration))
	var samples := PackedByteArray()
	samples.resize(count * 2)
	for index in range(count):
		var progress := float(index) / float(count)
		var attack := minf(progress * 70.0, 1.0)
		var release := pow(maxf(0.0, 1.0 - progress), 1.7)
		var phase := TAU * frequency * float(index) / float(SAMPLE_RATE)
		var sweep := sin(phase + 0.12 * progress * progress)
		var amplitude := clampf(sweep * attack * release * 0.30, -1.0, 1.0)
		samples.encode_s16(index * 2, int(amplitude * 32767.0))

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = samples
	return stream
