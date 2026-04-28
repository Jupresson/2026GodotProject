extends Node
class_name SceneReadySound

enum PlaybackKind {
	GLOBAL_2D,
	SPATIAL_3D,
}

@export_group("Source")
## Direct AudioStream resource (assign an AudioStream or sample resource in the Inspector)
@export var stream: AudioStream

## File path selected with a file picker (filtered by the given extensions). Used with load(stream_path) at runtime.
@export_file("*.ogg", "*.wav", "*.mp3", "*.flac", "*.opus", "*.xm", "*.s3m", "*.mod", "*.it") var stream_path: String = ""

## Directory path selected with a directory picker. When set, AudioManager may search this folder for audio files.
@export_dir var folder_path: String = ""

## If true, AudioManager should search subdirectories of folder_path as well; if false, only the top-level folder is used.
@export var search_recursively: bool = true

@export_group("Playback")
## Choose between global 2D playback or spatial 3D playback.
@export var playback_kind: PlaybackKind = PlaybackKind.GLOBAL_2D

## Target bus category used by AudioManager for routing/mixing.
@export var bus_category: AudioManager.BusCategory = AudioManager.BusCategory.AMBIENT

## Playback volume in decibels.
@export var volume_db: float = -12.0

## Base pitch multiplier for playback.
@export var pitch_scale: float = 1.0

## Random pitch range (min, max) applied per play when using randomization.
@export var pitch_range: Vector2 = Vector2(1.0, 1.0)

## Optional tag to make this sound instance unique for AudioManager (prevents duplicates, etc.). Leave empty to allow multiple scene-ready sounds to play together.
@export var unique_tag: StringName = &""

## Optional semantic category for grouping or filtering sounds.
@export var category: StringName = &""

## Whether the sound should loop.
@export var looping: bool = true

## Fade-out time (seconds) when stopping the sound.
@export var fade_out_seconds: float = 0.15

## Delay before playing the sound (seconds). Can be used to stagger ambient sounds.
@export_range(0.0, 60.0, 0.01, "or_greater") var delay_seconds: float = 0.0

@export_group("3D")
## World-space position for 3D/spatial playback (used when playback_kind is SPATIAL_3D).
@export var global_position: Vector3 = Vector3.ZERO

## Unit size used by spatial attenuation calculations.
@export var spatial_unit_size: float = 1.0

## Maximum audible distance for spatial playback (0.0 means use engine defaults).
@export var spatial_max_distance: float = 0.0

## Attenuation model used for spatial audio (inverse, linear, etc.).
@export var spatial_attenuation_model: AudioStreamPlayer3D.AttenuationModel = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE

## Doppler tracking mode for spatial audio (disabled, simple, full).
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
	var player := AudioManager.play_sound(request)
	if not looping and player != null:
		queue_free()


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