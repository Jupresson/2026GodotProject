extends Node
class_name SceneReadySound

enum PlaybackKind {
	GLOBAL_2D,
	SPATIAL_3D,
}

@export_group("Source")
@export var stream: AudioStream
@export_file("*.ogg", "*.wav", "*.mp3", "*.flac", "*.opus", "*.xm", "*.s3m", "*.mod", "*.it") var stream_path: String = ""
@export_dir var folder_path: String = ""
@export var search_recursively: bool = true

@export_group("Playback")
@export var playback_kind: PlaybackKind = PlaybackKind.GLOBAL_2D
@export var bus_category: AudioManager.BusCategory = AudioManager.BusCategory.AMBIENT
@export var volume_db: float = -12.0
@export var pitch_scale: float = 1.0
@export var pitch_range: Vector2 = Vector2(1.0, 1.0)
@export var unique_tag: StringName = &"level_0_general_ambient"
@export var category: StringName = &""
@export var looping: bool = true
@export var fade_out_seconds: float = 0.15
@export_range(0.0, 60.0, 0.01, "or_greater") var delay_seconds: float = 0.0

@export_group("3D")
@export var global_position: Vector3 = Vector3.ZERO
@export var spatial_unit_size: float = 1.0
@export var spatial_max_distance: float = 0.0
@export var spatial_attenuation_model: AudioStreamPlayer3D.AttenuationModel = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
@export var spatial_doppler_tracking: AudioStreamPlayer3D.DopplerTracking = AudioStreamPlayer3D.DOPPLER_TRACKING_DISABLED


func _ready() -> void:
	if delay_seconds <= 0.0:
		play_sound()
		return

	await get_tree().create_timer(delay_seconds).timeout
	if is_inside_tree():
		play_sound()


func play_sound() -> void:
	var request := AudioManager.SoundRequest.new()
	request.stream = _resolve_stream()
	request.folder_path = folder_path
	request.search_recursively = search_recursively
	request.playback_kind = _resolve_playback_kind()
	request.bus_category = bus_category
	request.volume_db = volume_db
	request.pitch_scale = pitch_scale
	request.pitch_range = pitch_range
	request.unique_tag = unique_tag
	request.category = category
	request.looping = looping
	request.fade_out_seconds = fade_out_seconds
	request.global_position = global_position
	request.spatial_unit_size = spatial_unit_size
	request.spatial_max_distance = spatial_max_distance
	request.spatial_attenuation_model = spatial_attenuation_model
	request.spatial_doppler_tracking = spatial_doppler_tracking
	AudioManager.play_sound(request)


func _resolve_stream() -> AudioStream:
	if stream != null:
		return stream

	if not stream_path.is_empty():
		return load(stream_path) as AudioStream

	return null


func _resolve_playback_kind() -> AudioManager.PlaybackKind:
	match playback_kind:
		PlaybackKind.SPATIAL_3D:
			return AudioManager.PlaybackKind.SPATIAL_3D
		_:
			return AudioManager.PlaybackKind.GLOBAL_2D