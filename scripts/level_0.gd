extends Node3D

const AMBIENT_SOUNDS_AMBIENT: AudioStream = preload("res://assets/sounds/ambient/levels_general/level_0_ambient_loop.ogg")
const AMBIENT_VOLUME_DB: float = -12.0
const AMBIENT_PITCH_RANGE: Vector2 = Vector2(0.96, 1.04)
const AMBIENT_SOUND_TAG: StringName = &"level_0_general_ambient"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var request := AudioManager.SoundRequest.new()
	request.stream = AMBIENT_SOUNDS_AMBIENT
	request.playback_kind = AudioManager.PlaybackKind.GLOBAL_2D
	request.bus_category = AudioManager.BusCategory.AMBIENT
	request.volume_db = AMBIENT_VOLUME_DB
	request.pitch_range = AMBIENT_PITCH_RANGE
	request.unique_tag = AMBIENT_SOUND_TAG
	request.looping = true
	AudioManager.play_sound(request)