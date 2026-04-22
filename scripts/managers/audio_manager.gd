extends Node
class_name AudioManagerClass

const MASTER_BUS: StringName = &"Master"
const MUSIC_BUS: StringName = &"Music"
const SFX_BUS: StringName = &"SFX"
const AMBIENT_BUS: StringName = &"Ambient"
const UI_BUS: StringName = &"UI"

const DEFAULT_SPATIAL_POOL_SIZE: int = 16
const DEFAULT_GLOBAL_POOL_SIZE: int = 10
const DEFAULT_UNIT_SIZE: float = 8.0
const DEFAULT_MAX_DISTANCE: float = 80.0

enum PitchMode {
	PRESET,
	CUSTOM_RANGE,
	CUSTOM_VALUE
}

enum PitchPreset {
	VERY_LOW,
	LOW,
	NORMAL,
	HIGH,
	VERY_HIGH,
	RANDOM_SUBTLE,
	RANDOM_WIDE
}

const _PITCH_PRESET_RANGES = {
	PitchPreset.VERY_LOW: Vector2(0.65, 0.8),
	PitchPreset.LOW: Vector2(0.8, 0.95),
	PitchPreset.NORMAL: Vector2(1.0, 1.0),
	PitchPreset.HIGH: Vector2(1.05, 1.2),
	PitchPreset.VERY_HIGH: Vector2(1.2, 1.4),
	PitchPreset.RANDOM_SUBTLE: Vector2(0.95, 1.05),
	PitchPreset.RANDOM_WIDE: Vector2(0.8, 1.25)
}

var _available_spatial_players: Array[AudioStreamPlayer3D] = []
var _active_spatial_players: Array[AudioStreamPlayer3D] = []
var _available_global_players: Array[AudioStreamPlayer] = []
var _active_global_players: Array[AudioStreamPlayer] = []
var _looping_spatial_players: Dictionary[StringName, AudioStreamPlayer3D] = {}
var _looping_global_players: Dictionary[StringName, AudioStreamPlayer] = {}
var _last_random_bank_indices: Dictionary[StringName, int] = {}
var _stream_bank_cache: Dictionary = {}
var _player_fade_tweens: Dictionary[int, Tween] = {}


func _ready() -> void:
	add_to_group("autoload")
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("audio_manager")
	_ensure_audio_buses()
	_seed_spatial_pool(DEFAULT_SPATIAL_POOL_SIZE)
	_seed_global_pool(DEFAULT_GLOBAL_POOL_SIZE)


func play_global(
	stream: AudioStream,
	bus_name: StringName = SFX_BUS,
	volume_db: float = 0.0,
	pitch_mode: PitchMode = PitchMode.PRESET,
	pitch_preset: PitchPreset = PitchPreset.NORMAL,
	custom_pitch_range: Vector2 = Vector2(1.0, 1.0),
	custom_pitch_scale: float = 1.0,
	fade_in_seconds: float = 0.0
) -> AudioStreamPlayer:
	if stream == null:
		push_warning("AudioManager.play_global() received a null stream.")
		return null

	var player: AudioStreamPlayer = _acquire_global_player() as AudioStreamPlayer
	_configure_global_player(player, stream, bus_name, volume_db)
	if fade_in_seconds > 0.0:
		_set_player_gain(player, -80.0)
	_apply_pitch(player, pitch_mode, pitch_preset, custom_pitch_range, custom_pitch_scale)
	player.play()
	if fade_in_seconds > 0.0:
		_tween_player_volume(player, volume_db, fade_in_seconds)
	return player


func play_spatial(
	stream: AudioStream,
	world_position: Vector3,
	bus_name: StringName = SFX_BUS,
	volume_db: float = 0.0,
	unit_size: float = DEFAULT_UNIT_SIZE,
	max_distance: float = DEFAULT_MAX_DISTANCE,
	pitch_mode: PitchMode = PitchMode.PRESET,
	pitch_preset: PitchPreset = PitchPreset.NORMAL,
	custom_pitch_range: Vector2 = Vector2(1.0, 1.0),
	custom_pitch_scale: float = 1.0
) -> AudioStreamPlayer3D:
	if stream == null:
		push_warning("AudioManager.play_spatial() received a null stream.")
		return null

	var player: AudioStreamPlayer3D = _acquire_spatial_player() as AudioStreamPlayer3D
	_configure_spatial_player(player, stream, world_position, bus_name, volume_db, unit_size, max_distance)
	_apply_pitch(player, pitch_mode, pitch_preset, custom_pitch_range, custom_pitch_scale)
	player.play()
	return player


func play_global_from_path(
	resource_path: String,
	bus_name: StringName = SFX_BUS,
	volume_db: float = 0.0,
	pitch_mode: PitchMode = PitchMode.PRESET,
	pitch_preset: PitchPreset = PitchPreset.NORMAL,
	custom_pitch_range: Vector2 = Vector2(1.0, 1.0),
	custom_pitch_scale: float = 1.0,
	fade_in_seconds: float = 0.0
) -> AudioStreamPlayer:
	var stream: AudioStream = load(resource_path) as AudioStream
	return play_global(stream, bus_name, volume_db, pitch_mode, pitch_preset, custom_pitch_range, custom_pitch_scale, fade_in_seconds)


func play_spatial_from_path(
	resource_path: String,
	world_position: Vector3,
	bus_name: StringName = SFX_BUS,
	volume_db: float = 0.0,
	unit_size: float = DEFAULT_UNIT_SIZE,
	max_distance: float = DEFAULT_MAX_DISTANCE,
	pitch_mode: PitchMode = PitchMode.PRESET,
	pitch_preset: PitchPreset = PitchPreset.NORMAL,
	custom_pitch_range: Vector2 = Vector2(1.0, 1.0),
	custom_pitch_scale: float = 1.0
) -> AudioStreamPlayer3D:
	var stream: AudioStream = load(resource_path) as AudioStream
	return play_spatial(stream, world_position, bus_name, volume_db, unit_size, max_distance, pitch_mode, pitch_preset, custom_pitch_range, custom_pitch_scale)


func play_ui(stream: AudioStream, volume_db: float = 0.0, pitch_preset: PitchPreset = PitchPreset.NORMAL) -> AudioStreamPlayer:
	return play_global(stream, UI_BUS, volume_db, PitchMode.PRESET, pitch_preset)


func play_music(stream: AudioStream, volume_db: float = -6.0) -> AudioStreamPlayer:
	return play_global(stream, MUSIC_BUS, volume_db)


func play_ambient_spatial(
	stream: AudioStream,
	world_position: Vector3,
	volume_db: float = 0.0,
	unit_size: float = DEFAULT_UNIT_SIZE,
	max_distance: float = DEFAULT_MAX_DISTANCE
) -> AudioStreamPlayer3D:
	return play_spatial(stream, world_position, AMBIENT_BUS, volume_db, unit_size, max_distance)


func play_global_loop(
	key: StringName,
	stream: AudioStream,
	bus_name: StringName = MUSIC_BUS,
	volume_db: float = 0.0,
	pitch_mode: PitchMode = PitchMode.PRESET,
	pitch_preset: PitchPreset = PitchPreset.NORMAL,
	custom_pitch_range: Vector2 = Vector2(1.0, 1.0),
	custom_pitch_scale: float = 1.0,
	fade_in_seconds: float = 0.0
) -> AudioStreamPlayer:
	if key.is_empty():
		push_warning("AudioManager.play_global_loop() received an empty key.")
		return null

	var existing: AudioStreamPlayer = _looping_global_players.get(key, null) as AudioStreamPlayer
	if existing is AudioStreamPlayer and is_instance_valid(existing):
		return existing

	var player: AudioStreamPlayer = _acquire_global_player() as AudioStreamPlayer
	_configure_global_player(player, stream, bus_name, volume_db)
	if fade_in_seconds > 0.0:
		_set_player_gain(player, -80.0)
	_apply_pitch(player, pitch_mode, pitch_preset, custom_pitch_range, custom_pitch_scale)
	player.stream_paused = false
	_looping_global_players[key] = player
	player.play()
	if fade_in_seconds > 0.0:
		_tween_player_volume(player, volume_db, fade_in_seconds)
	return player


func play_spatial_loop(
	key: StringName,
	stream: AudioStream,
	world_position: Vector3,
	bus_name: StringName = AMBIENT_BUS,
	volume_db: float = 0.0,
	unit_size: float = DEFAULT_UNIT_SIZE,
	max_distance: float = DEFAULT_MAX_DISTANCE,
	pitch_mode: PitchMode = PitchMode.PRESET,
	pitch_preset: PitchPreset = PitchPreset.NORMAL,
	custom_pitch_range: Vector2 = Vector2(1.0, 1.0),
	custom_pitch_scale: float = 1.0
) -> AudioStreamPlayer3D:
	if key.is_empty():
		push_warning("AudioManager.play_spatial_loop() received an empty key.")
		return null

	var existing: AudioStreamPlayer3D = _looping_spatial_players.get(key, null) as AudioStreamPlayer3D
	if existing is AudioStreamPlayer3D and is_instance_valid(existing):
		return existing

	var player: AudioStreamPlayer3D = _acquire_spatial_player() as AudioStreamPlayer3D
	_configure_spatial_player(player, stream, world_position, bus_name, volume_db, unit_size, max_distance)
	_apply_pitch(player, pitch_mode, pitch_preset, custom_pitch_range, custom_pitch_scale)
	player.stream_paused = false
	_looping_spatial_players[key] = player
	player.play()
	return player


func stop_global_loop(key: StringName, fade_out_seconds: float = 0.0) -> void:
	if not _looping_global_players.has(key):
		return

	var player: AudioStreamPlayer = _looping_global_players[key]
	_looping_global_players.erase(key)

	if fade_out_seconds <= 0.0:
		_release_global_player(player)
		return

	if player == null or not is_instance_valid(player):
		return

	_tween_player_volume(player, -80.0, fade_out_seconds, true)


func stop_spatial_loop(key: StringName) -> void:
	if not _looping_spatial_players.has(key):
		return

	_release_spatial_player(_looping_spatial_players[key])
	_looping_spatial_players.erase(key)


func stop_all() -> void:
	for key in _looping_spatial_players.keys():
		_release_spatial_player(_looping_spatial_players[key])
	_looping_spatial_players.clear()

	for key in _looping_global_players.keys():
		_release_global_player(_looping_global_players[key])
	_looping_global_players.clear()

	for player in _active_spatial_players.duplicate():
		_release_spatial_player(player)

	for player in _active_global_players.duplicate():
		_release_global_player(player)


func set_bus_volume_linear(bus_name: StringName, linear_value: float) -> void:
	var bus_index: int = AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		push_warning("AudioManager.set_bus_volume_linear() could not find bus: %s" % bus_name)
		return

	var safe_linear: float = clampf(linear_value, 0.0001, 1.0)
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(safe_linear))


func set_bus_volume_db(bus_name: StringName, volume_db: float) -> void:
	var bus_index: int = AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		push_warning("AudioManager.set_bus_volume_db() could not find bus: %s" % bus_name)
		return

	AudioServer.set_bus_volume_db(bus_index, volume_db)


func set_bus_mute(bus_name: StringName, muted: bool) -> void:
	var bus_index: int = AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		push_warning("AudioManager.set_bus_mute() could not find bus: %s" % bus_name)
		return

	AudioServer.set_bus_mute(bus_index, muted)


func set_global_loop_volume_db(key: StringName, volume_db: float, fade_seconds: float = 0.0) -> void:
	var player: AudioStreamPlayer = _looping_global_players.get(key, null) as AudioStreamPlayer
	if player == null or not is_instance_valid(player):
		return

	if fade_seconds > 0.0:
		_tween_player_volume(player, volume_db, fade_seconds)
		return

	_set_player_gain(player, volume_db)


func set_global_loop_volume_linear(key: StringName, linear_value: float, fade_seconds: float = 0.0) -> void:
	var safe_linear: float = clampf(linear_value, 0.0001, 1.0)
	set_global_loop_volume_db(key, linear_to_db(safe_linear), fade_seconds)


func play_spatial_sfx(
	stream: AudioStream,
	world_position: Vector3,
	bus_name: StringName = SFX_BUS,
	volume_db: float = 0.0,
	unit_size: float = DEFAULT_UNIT_SIZE,
	max_distance: float = DEFAULT_MAX_DISTANCE
) -> AudioStreamPlayer3D:
	return play_spatial(stream, world_position, bus_name, volume_db, unit_size, max_distance)


func play_global_sfx(
	stream: AudioStream,
	bus_name: StringName = UI_BUS,
	volume_db: float = 0.0
) -> AudioStreamPlayer:
	return play_global(stream, bus_name, volume_db)


func play_global_from_streams(
	streams: Array[AudioStream],
	bus_name: StringName = SFX_BUS,
	volume_db: float = 0.0,
	pitch_mode: PitchMode = PitchMode.PRESET,
	pitch_preset: PitchPreset = PitchPreset.NORMAL,
	custom_pitch_range: Vector2 = Vector2(1.0, 1.0),
	custom_pitch_scale: float = 1.0,
	avoid_immediate_repeat: bool = true
) -> AudioStreamPlayer:
	return play_random_global_from_streams(streams, bus_name, volume_db, pitch_mode, pitch_preset, custom_pitch_range, custom_pitch_scale, avoid_immediate_repeat)


func play_spatial_from_streams(
	streams: Array[AudioStream],
	world_position: Vector3,
	bus_name: StringName = SFX_BUS,
	volume_db: float = 0.0,
	unit_size: float = DEFAULT_UNIT_SIZE,
	max_distance: float = DEFAULT_MAX_DISTANCE,
	pitch_mode: PitchMode = PitchMode.PRESET,
	pitch_preset: PitchPreset = PitchPreset.NORMAL,
	custom_pitch_range: Vector2 = Vector2(1.0, 1.0),
	custom_pitch_scale: float = 1.0,
	avoid_immediate_repeat: bool = true
) -> AudioStreamPlayer3D:
	return play_random_spatial_from_streams(streams, world_position, bus_name, volume_db, unit_size, max_distance, pitch_mode, pitch_preset, custom_pitch_range, custom_pitch_scale, avoid_immediate_repeat)


func play_global_from_folder(
	folder_path: String,
	bus_name: StringName = SFX_BUS,
	volume_db: float = 0.0,
	pitch_mode: PitchMode = PitchMode.PRESET,
	pitch_preset: PitchPreset = PitchPreset.NORMAL,
	custom_pitch_range: Vector2 = Vector2(1.0, 1.0),
	custom_pitch_scale: float = 1.0,
	avoid_immediate_repeat: bool = true
) -> AudioStreamPlayer:
	return play_random_global_from_folder(folder_path, bus_name, volume_db, pitch_mode, pitch_preset, custom_pitch_range, custom_pitch_scale, avoid_immediate_repeat)


func play_spatial_from_folder(
	folder_path: String,
	world_position: Vector3,
	bus_name: StringName = SFX_BUS,
	volume_db: float = 0.0,
	unit_size: float = DEFAULT_UNIT_SIZE,
	max_distance: float = DEFAULT_MAX_DISTANCE,
	pitch_mode: PitchMode = PitchMode.PRESET,
	pitch_preset: PitchPreset = PitchPreset.NORMAL,
	custom_pitch_range: Vector2 = Vector2(1.0, 1.0),
	custom_pitch_scale: float = 1.0,
	avoid_immediate_repeat: bool = true
) -> AudioStreamPlayer3D:
	return play_random_spatial_from_folder(folder_path, world_position, bus_name, volume_db, unit_size, max_distance, pitch_mode, pitch_preset, custom_pitch_range, custom_pitch_scale, avoid_immediate_repeat)


func play_random_global_from_streams(
	streams: Array[AudioStream],
	bus_name: StringName = SFX_BUS,
	volume_db: float = 0.0,
	pitch_mode: PitchMode = PitchMode.PRESET,
	pitch_preset: PitchPreset = PitchPreset.NORMAL,
	custom_pitch_range: Vector2 = Vector2(1.0, 1.0),
	custom_pitch_scale: float = 1.0,
	avoid_immediate_repeat: bool = true
) -> AudioStreamPlayer:
	var random_stream: AudioStream = _pick_random_stream(streams, avoid_immediate_repeat)
	if random_stream == null:
		return null

	return play_global(random_stream, bus_name, volume_db, pitch_mode, pitch_preset, custom_pitch_range, custom_pitch_scale)


func play_random_spatial_from_streams(
	streams: Array[AudioStream],
	world_position: Vector3,
	bus_name: StringName = SFX_BUS,
	volume_db: float = 0.0,
	unit_size: float = DEFAULT_UNIT_SIZE,
	max_distance: float = DEFAULT_MAX_DISTANCE,
	pitch_mode: PitchMode = PitchMode.PRESET,
	pitch_preset: PitchPreset = PitchPreset.NORMAL,
	custom_pitch_range: Vector2 = Vector2(1.0, 1.0),
	custom_pitch_scale: float = 1.0,
	avoid_immediate_repeat: bool = true
) -> AudioStreamPlayer3D:
	var random_stream: AudioStream = _pick_random_stream(streams, avoid_immediate_repeat)
	if random_stream == null:
		return null

	return play_spatial(random_stream, world_position, bus_name, volume_db, unit_size, max_distance, pitch_mode, pitch_preset, custom_pitch_range, custom_pitch_scale)


func play_random_global_from_folder(
	folder_path: String,
	bus_name: StringName = SFX_BUS,
	volume_db: float = 0.0,
	pitch_mode: PitchMode = PitchMode.PRESET,
	pitch_preset: PitchPreset = PitchPreset.NORMAL,
	custom_pitch_range: Vector2 = Vector2(1.0, 1.0),
	custom_pitch_scale: float = 1.0,
	avoid_immediate_repeat: bool = true
) -> AudioStreamPlayer:
	var stream_bank: Array[AudioStream] = get_stream_bank(folder_path)
	return play_random_global_from_streams(stream_bank, bus_name, volume_db, pitch_mode, pitch_preset, custom_pitch_range, custom_pitch_scale, avoid_immediate_repeat)


func play_random_spatial_from_folder(
	folder_path: String,
	world_position: Vector3,
	bus_name: StringName = SFX_BUS,
	volume_db: float = 0.0,
	unit_size: float = DEFAULT_UNIT_SIZE,
	max_distance: float = DEFAULT_MAX_DISTANCE,
	pitch_mode: PitchMode = PitchMode.PRESET,
	pitch_preset: PitchPreset = PitchPreset.NORMAL,
	custom_pitch_range: Vector2 = Vector2(1.0, 1.0),
	custom_pitch_scale: float = 1.0,
	avoid_immediate_repeat: bool = true
) -> AudioStreamPlayer3D:
	var stream_bank: Array[AudioStream] = get_stream_bank(folder_path)
	return play_random_spatial_from_streams(stream_bank, world_position, bus_name, volume_db, unit_size, max_distance, pitch_mode, pitch_preset, custom_pitch_range, custom_pitch_scale, avoid_immediate_repeat)


func get_stream_bank(folder_path: String) -> Array[AudioStream]:
	var bank_key: StringName = StringName(folder_path)
	if _stream_bank_cache.has(bank_key):
		return _stream_bank_cache[bank_key] as Array[AudioStream]

	var loaded_streams: Array[AudioStream] = []
	var dir: DirAccess = DirAccess.open(folder_path)
	if dir == null:
		push_warning("AudioManager could not open folder: %s" % folder_path)
		_stream_bank_cache[bank_key] = loaded_streams
		return loaded_streams

	var audio_files: Array[String] = []
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and _is_audio_file(file_name):
			audio_files.append(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()

	audio_files.sort()
	for audio_file in audio_files:
		var resource_path: String = folder_path.path_join(audio_file)
		var stream: AudioStream = load(resource_path) as AudioStream
		if stream != null:
			loaded_streams.append(stream)

	_stream_bank_cache[bank_key] = loaded_streams
	return loaded_streams


func _seed_spatial_pool(count: int) -> void:
	for _index in range(count):
		_available_spatial_players.append(_create_spatial_player())


func _seed_global_pool(count: int) -> void:
	for _index in range(count):
		_available_global_players.append(_create_global_player())


func _ensure_audio_buses() -> void:
	_ensure_bus(MUSIC_BUS, MASTER_BUS)
	_ensure_bus(SFX_BUS, MASTER_BUS)
	_ensure_bus(AMBIENT_BUS, MASTER_BUS)
	_ensure_bus(UI_BUS, MASTER_BUS)


func _ensure_bus(bus_name: StringName, send_to: StringName) -> void:
	var bus_index: int = AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		AudioServer.add_bus(AudioServer.get_bus_count())
		bus_index = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(bus_index, bus_name)

	if bus_name != MASTER_BUS:
		AudioServer.set_bus_send(bus_index, send_to)


func _create_spatial_player() -> AudioStreamPlayer3D:
	var player: AudioStreamPlayer3D
	if ClassDB.class_exists("SpatialAudioPlayer3D"):
		player = SpatialAudioPlayer3D.new()
	else:
		player = AudioStreamPlayer3D.new()
	player.finished.connect(_on_spatial_player_finished.bind(player))
	add_child(player)
	return player


func _create_global_player() -> AudioStreamPlayer:
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.finished.connect(_on_global_player_finished.bind(player))
	add_child(player)
	return player


func _acquire_spatial_player() -> AudioStreamPlayer3D:
	if not _available_spatial_players.is_empty():
		var last_index: int = _available_spatial_players.size() - 1
		var pooled_player: AudioStreamPlayer3D = _available_spatial_players[last_index]
		_available_spatial_players.remove_at(last_index)
		if not _active_spatial_players.has(pooled_player):
			_active_spatial_players.append(pooled_player)
		return pooled_player

	var created_player: AudioStreamPlayer3D = _create_spatial_player()
	if not _active_spatial_players.has(created_player):
		_active_spatial_players.append(created_player)
	return created_player


func _acquire_global_player() -> AudioStreamPlayer:
	if not _available_global_players.is_empty():
		var last_index: int = _available_global_players.size() - 1
		var pooled_player: AudioStreamPlayer = _available_global_players[last_index]
		_available_global_players.remove_at(last_index)
		if not _active_global_players.has(pooled_player):
			_active_global_players.append(pooled_player)
		return pooled_player

	var created_player: AudioStreamPlayer = _create_global_player()
	if not _active_global_players.has(created_player):
		_active_global_players.append(created_player)
	return created_player


func _configure_spatial_player(
	player: AudioStreamPlayer3D,
	stream: AudioStream,
	world_position: Vector3,
	bus_name: StringName,
	volume_db: float,
	unit_size: float,
	max_distance: float
) -> void:
	player.stop()
	player.stream = stream
	player.bus = bus_name
	player.global_position = world_position
	player.unit_size = unit_size
	player.max_distance = max_distance
	player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	player.doppler_tracking = AudioStreamPlayer3D.DOPPLER_TRACKING_PHYSICS_STEP
	_set_player_gain(player, volume_db)


func _configure_global_player(
	player: AudioStreamPlayer,
	stream: AudioStream,
	bus_name: StringName,
	volume_db: float
) -> void:
	player.stop()
	player.stream = stream
	player.bus = bus_name
	_set_player_gain(player, volume_db)


func _apply_pitch(
	player: Object,
	pitch_mode: PitchMode,
	pitch_preset: PitchPreset,
	custom_pitch_range: Vector2,
	custom_pitch_scale: float
) -> void:
	var pitch_scale: float = 1.0
	match pitch_mode:
		PitchMode.CUSTOM_VALUE:
			pitch_scale = maxf(custom_pitch_scale, 0.01)
		PitchMode.CUSTOM_RANGE:
			pitch_scale = _random_pitch(custom_pitch_range)
		_:
			var preset_range: Vector2 = _PITCH_PRESET_RANGES.get(pitch_preset, Vector2(1.0, 1.0))
			pitch_scale = _random_pitch(preset_range)

	if player is AudioStreamPlayer:
		(player as AudioStreamPlayer).pitch_scale = pitch_scale
	elif player is AudioStreamPlayer3D:
		(player as AudioStreamPlayer3D).pitch_scale = pitch_scale
	elif _has_property(player, &"pitch_scale"):
		player.set("pitch_scale", pitch_scale)


func _random_pitch(value_range: Vector2) -> float:
	var min_pitch: float = maxf(minf(value_range.x, value_range.y), 0.01)
	var max_pitch: float = maxf(maxf(value_range.x, value_range.y), min_pitch)
	if is_equal_approx(min_pitch, max_pitch):
		return min_pitch
	return randf_range(min_pitch, max_pitch)


func _set_player_gain(player: Object, volume_db: float) -> void:
	if player is AudioStreamPlayer:
		(player as AudioStreamPlayer).volume_db = volume_db
		return

	if player is AudioStreamPlayer3D:
		(player as AudioStreamPlayer3D).volume_db = volume_db
		return

	if _has_property(player, &"max_db"):
		player.set("max_db", volume_db)
	if _has_property(player, &"volume_db"):
		player.set("volume_db", volume_db)


func _has_property(object: Object, property_name: StringName) -> bool:
	for property_info in object.get_property_list():
		if StringName(property_info["name"]) == property_name:
			return true
	return false


func _pick_random_stream(streams: Array[AudioStream], avoid_immediate_repeat: bool) -> AudioStream:
	if streams.is_empty():
		push_warning("AudioManager received an empty stream bank.")
		return null

	if streams.size() == 1:
		return streams[0]

	var bank_key: StringName = _get_stream_bank_key(streams)
	var last_index: int = _last_random_bank_indices.get(bank_key, -1)
	var next_index: int = randi_range(0, streams.size() - 1)

	if avoid_immediate_repeat:
		var attempts: int = 0
		while next_index == last_index and attempts < 12:
			next_index = randi_range(0, streams.size() - 1)
			attempts += 1

	_last_random_bank_indices[bank_key] = next_index
	return streams[next_index]


func _is_audio_file(file_name: String) -> bool:
	var lower_name: String = file_name.to_lower()
	return lower_name.ends_with(".ogg") or lower_name.ends_with(".wav") or lower_name.ends_with(".mp3") or lower_name.ends_with(".flac")


func _get_stream_bank_key(streams: Array[AudioStream]) -> StringName:
	var key_parts: PackedStringArray = []
	for stream in streams:
		if stream == null:
			key_parts.append("null")
		else:
			key_parts.append(stream.resource_path)

	return StringName("|".join(key_parts))


func _release_spatial_player(player: AudioStreamPlayer3D) -> void:
	if player == null or not is_instance_valid(player):
		return

	_kill_player_fade(player)
	player.stop()
	player.stream = null
	if _active_spatial_players.has(player):
		_active_spatial_players.erase(player)
	if not _available_spatial_players.has(player):
		_available_spatial_players.append(player)


func _release_global_player(player: AudioStreamPlayer) -> void:
	if player == null or not is_instance_valid(player):
		return

	_kill_player_fade(player)
	player.stop()
	player.stream = null
	if _active_global_players.has(player):
		_active_global_players.erase(player)
	if not _available_global_players.has(player):
		_available_global_players.append(player)


func _on_spatial_player_finished(player: AudioStreamPlayer3D) -> void:
	if _looping_spatial_players.values().has(player):
		return
	_release_spatial_player(player)


func _on_global_player_finished(player: AudioStreamPlayer) -> void:
	if _looping_global_players.values().has(player):
		return
	_release_global_player(player)


func _tween_player_volume(player: Object, target_volume_db: float, duration: float, release_on_finish: bool = false) -> void:
	if player == null or not is_instance_valid(player):
		return

	if !_has_property(player, &"volume_db"):
		return

	if duration <= 0.0:
		_set_player_gain(player, target_volume_db)
		if release_on_finish:
			if player is AudioStreamPlayer:
				_release_global_player(player as AudioStreamPlayer)
			elif player is AudioStreamPlayer3D:
				_release_spatial_player(player as AudioStreamPlayer3D)
		return

	_kill_player_fade(player)
	var tween: Tween = create_tween()
	_player_fade_tweens[player.get_instance_id()] = tween
	tween.tween_property(player, "volume_db", target_volume_db, duration)
	tween.finished.connect(_on_player_fade_finished.bind(player.get_instance_id(), player, release_on_finish), CONNECT_ONE_SHOT)


func _kill_player_fade(player: Object) -> void:
	if player == null or not is_instance_valid(player):
		return

	var player_id: int = player.get_instance_id()
	if !_player_fade_tweens.has(player_id):
		return

	var tween: Tween = _player_fade_tweens[player_id] as Tween
	if tween != null and is_instance_valid(tween):
		tween.kill()
	_player_fade_tweens.erase(player_id)


func _on_player_fade_finished(player_id: int, player: Object, release_on_finish: bool) -> void:
	_player_fade_tweens.erase(player_id)
	if !release_on_finish:
		return

	if player == null or not is_instance_valid(player):
		return

	if player is AudioStreamPlayer:
		_release_global_player(player as AudioStreamPlayer)
	elif player is AudioStreamPlayer3D:
		_release_spatial_player(player as AudioStreamPlayer3D)
