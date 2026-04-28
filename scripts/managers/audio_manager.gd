extends Node

const DEFAULT_BUS: StringName = &"Master"

enum BusCategory {
	MUSIC,
	SFX,
	AMBIENT,
	UI,
}

enum PlaybackKind {
	GLOBAL_2D,
	SPATIAL_3D,
}


class SoundRequest:
	extends RefCounted

	var stream: AudioStream = null
	var folder_path: String = ""
	var playback_kind: PlaybackKind = PlaybackKind.GLOBAL_2D
	var bus_category: BusCategory = BusCategory.SFX
	var volume_db: float = 0.0
	var pitch_scale: float = 1.0
	var pitch_range: Vector2 = Vector2.ONE
	var unique_tag: StringName = &""
	var category: StringName = &""
	var global_position: Vector3 = Vector3.ZERO
	var spatial_unit_size: float = 1.0
	var spatial_max_distance: float = 0.0
	var spatial_attenuation_model: int = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	var spatial_doppler_tracking: int = AudioStreamPlayer3D.DOPPLER_TRACKING_DISABLED
	var search_recursively: bool = true
	var fade_out_seconds: float = 0.15


class ActiveSound:
	extends RefCounted

	var id: int = 0
	var player: Node = null
	var unique_tag: StringName = &""
	var category: StringName = &""
	var stream_length: float = 0.0
	var elapsed_time: float = 0.0
	var fade_out_seconds: float = 0.0
	var fading_out: bool = false
	var fade_tween: Tween = null


var _active_sounds: Dictionary = {}
var _folder_cache: Dictionary = {}
var _next_sound_id: int = 1
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

const BUS_NAMES: Dictionary = {
	BusCategory.MUSIC: &"Music",
	BusCategory.SFX: &"SFX",
	BusCategory.AMBIENT: &"Ambient",
	BusCategory.UI: &"UI",
}


func _ready() -> void:
	add_to_group("audio_manager")
	_rng.randomize()
	set_process(true)


func _exit_tree() -> void:
	set_process(false)
	stop_all()


func _process(delta: float) -> void:
	if _active_sounds.is_empty():
		return

	var active_ids: Array = _active_sounds.keys()
	for raw_id in active_ids:
		var sound_id := int(raw_id)
		var entry := _active_sounds.get(sound_id) as ActiveSound
		if entry == null:
			_active_sounds.erase(sound_id)
			continue

		if not is_instance_valid(entry.player):
			_active_sounds.erase(sound_id)
			continue

		if entry.fading_out:
			continue

		entry.elapsed_time += delta
		if entry.fade_out_seconds <= 0.0:
			continue

		if entry.stream_length <= 0.0:
			continue

		var fade_start_time := maxf(entry.stream_length - entry.fade_out_seconds, 0.0)
		if entry.elapsed_time >= fade_start_time:
			_begin_fade_out(sound_id, entry, false)


func play_sound(request: SoundRequest) -> Node:
	if request == null:
		push_error("AudioManager.play_sound() requires a SoundRequest.")
		return null

	var stream := _resolve_stream(request)
	if stream == null:
		push_warning("AudioManager.play_sound() could not resolve an AudioStream.")
		return null

	if request.unique_tag != &"":
		stop_by_unique_tag(request.unique_tag)

	var player := _create_player(request.playback_kind)
	if player == null:
		push_error("AudioManager.play_sound() could not create an audio player.")
		return null

	var sound_id := _next_sound_id
	_next_sound_id += 1

	var entry := ActiveSound.new()
	entry.id = sound_id
	entry.player = player
	entry.unique_tag = request.unique_tag
	entry.category = request.category
	entry.stream_length = maxf(stream.get_length(), 0.0)
	entry.fade_out_seconds = maxf(request.fade_out_seconds, 0.0)
	_active_sounds[sound_id] = entry

	_configure_player(player, request, stream)
	player.name = "Audio_%d" % sound_id
	_get_spawn_parent(request.playback_kind).add_child(player)
	_apply_spatial_position(player, request)
	_track_player(player, sound_id)
	_start_player(player)

	return player


func stop_by_unique_tag(unique_tag: StringName) -> void:
	if unique_tag == &"":
		return
	_stop_entries(Callable(self, "_entry_matches_unique_tag").bind(unique_tag))


func stop_by_category(category: StringName) -> void:
	if category == &"":
		return
	_stop_entries(Callable(self, "_entry_matches_category").bind(category))


func stop_all() -> void:
	_stop_entries(Callable(self, "_entry_matches_all"))


func _resolve_stream(request: SoundRequest) -> AudioStream:
	if not request.folder_path.is_empty():
		var folder_stream := _pick_random_stream_from_folder(request.folder_path, request.search_recursively)
		if folder_stream != null:
			return folder_stream

	if request.stream != null:
		return request.stream

	return null


func _pick_random_stream_from_folder(folder_path: String, search_recursively: bool) -> AudioStream:
	var cache_key := _folder_cache_key(folder_path, search_recursively)
	var cached_paths: Array = _folder_cache.get(cache_key, [])

	if cached_paths.is_empty():
		cached_paths = _collect_audio_paths(folder_path, search_recursively)
		_folder_cache[cache_key] = cached_paths

	if cached_paths.is_empty():
		return null

	var chosen_path: String = cached_paths[_rng.randi_range(0, cached_paths.size() - 1)]
	return load(chosen_path) as AudioStream


func _collect_audio_paths(folder_path: String, search_recursively: bool) -> Array[String]:
	var paths: Array[String] = []
	if not DirAccess.dir_exists_absolute(folder_path):
		return paths

	for file_name in DirAccess.get_files_at(folder_path):
		if _is_supported_audio_extension(file_name.get_extension()):
			paths.append(folder_path.path_join(file_name))

	if search_recursively:
		for directory_name in DirAccess.get_directories_at(folder_path):
			paths.append_array(_collect_audio_paths(folder_path.path_join(directory_name), true))

	return paths


func _is_supported_audio_extension(extension: String) -> bool:
	match extension.to_lower():
		"ogg", "wav", "mp3", "flac", "opus", "xm", "s3m", "mod", "it":
			return true
		_:
			return false


func _create_player(playback_kind: int) -> Node:
	match playback_kind:
		PlaybackKind.SPATIAL_3D:
			return SpatialAudioPlayer3D.new()
		_:
			return AudioStreamPlayer.new()


func _configure_player(player: Node, request: SoundRequest, stream: AudioStream) -> void:
	if player is AudioStreamPlayer:
		var audio_player := player as AudioStreamPlayer
		audio_player.stream = stream
		audio_player.bus = get_bus_name(request.bus_category)
		audio_player.volume_db = request.volume_db
		audio_player.pitch_scale = _resolve_pitch_scale(request)
		audio_player.autoplay = false
		return

	if player is AudioStreamPlayer3D:
		var spatial_player := player as AudioStreamPlayer3D
		spatial_player.stream = stream
		spatial_player.bus = get_bus_name(request.bus_category)
		spatial_player.volume_db = request.volume_db
		spatial_player.pitch_scale = _resolve_pitch_scale(request)
		spatial_player.unit_size = request.spatial_unit_size
		if request.spatial_max_distance > 0.0:
			spatial_player.max_distance = request.spatial_max_distance
		spatial_player.attenuation_model = request.spatial_attenuation_model as AudioStreamPlayer3D.AttenuationModel
		spatial_player.doppler_tracking = request.spatial_doppler_tracking as AudioStreamPlayer3D.DopplerTracking
		spatial_player.autoplay = false


func _apply_spatial_position(player: Node, request: SoundRequest) -> void:
	if request.playback_kind != PlaybackKind.SPATIAL_3D:
		return

	if player is Node3D:
		(player as Node3D).global_position = request.global_position


func _track_player(player: Node, sound_id: int) -> void:
	player.tree_exited.connect(_on_player_tree_exited.bind(sound_id))

	if player is AudioStreamPlayer:
		(player as AudioStreamPlayer).finished.connect(_on_player_finished.bind(sound_id))
	elif player is AudioStreamPlayer3D:
		(player as AudioStreamPlayer3D).finished.connect(_on_player_finished.bind(sound_id))


func _start_player(player: Node) -> void:
	if player is AudioStreamPlayer:
		(player as AudioStreamPlayer).play()
	elif player is AudioStreamPlayer3D:
		(player as AudioStreamPlayer3D).play()


func _stop_player(player: Node) -> void:
	if player is AudioStreamPlayer:
		(player as AudioStreamPlayer).stop()
	elif player is AudioStreamPlayer3D:
		(player as AudioStreamPlayer3D).stop()
	player.queue_free()


func _get_spawn_parent(playback_kind: int) -> Node:
	if playback_kind == PlaybackKind.SPATIAL_3D:
		var current_scene := get_tree().current_scene
		if current_scene is Node3D:
			return current_scene
		push_warning("Spatial audio requested without a Node3D current scene; attaching to AudioManager instead.")
	return self


func _resolve_pitch_scale(request: SoundRequest) -> float:
	if request.pitch_range != Vector2.ONE:
		var min_pitch := minf(request.pitch_range.x, request.pitch_range.y)
		var max_pitch := maxf(request.pitch_range.x, request.pitch_range.y)
		return _rng.randf_range(min_pitch, max_pitch)

	return request.pitch_scale


func _folder_cache_key(folder_path: String, search_recursively: bool) -> String:
	return "%s|%s" % [folder_path, "recursive" if search_recursively else "flat"]


func get_bus_name(bus_category: BusCategory) -> StringName:
	return BUS_NAMES.get(bus_category, DEFAULT_BUS)


func set_bus_volume_db(bus_category: BusCategory, volume_db: float) -> void:
	var bus_index := AudioServer.get_bus_index(get_bus_name(bus_category))
	if bus_index == -1:
		push_warning("AudioManager could not find bus %s." % get_bus_name(bus_category))
		return
	AudioServer.set_bus_volume_db(bus_index, volume_db)


func set_bus_volume_linear(bus_category: BusCategory, volume_linear: float) -> void:
	set_bus_volume_db(bus_category, linear_to_db(maxf(volume_linear, 0.0001)))


func set_bus_mute(bus_category: BusCategory, muted: bool) -> void:
	var bus_index := AudioServer.get_bus_index(get_bus_name(bus_category))
	if bus_index == -1:
		push_warning("AudioManager could not find bus %s." % get_bus_name(bus_category))
		return
	AudioServer.set_bus_mute(bus_index, muted)


func _stop_entries(predicate: Callable) -> void:
	var active_ids: Array = _active_sounds.keys()
	for raw_id in active_ids:
		var sound_id := int(raw_id)
		var entry := _active_sounds.get(sound_id) as ActiveSound
		if entry == null:
			_active_sounds.erase(sound_id)
			continue

		if predicate.call(entry):
			_begin_fade_out(sound_id, entry, true)


func _entry_matches_unique_tag(entry: ActiveSound, unique_tag: StringName) -> bool:
	return entry.unique_tag == unique_tag


func _entry_matches_category(entry: ActiveSound, category: StringName) -> bool:
	return entry.category == category


func _entry_matches_all(_entry: ActiveSound) -> bool:
	return true


func _release_entry(sound_id: int, entry: ActiveSound, stop_player: bool) -> void:
	_active_sounds.erase(sound_id)
	_kill_entry_tween(entry)

	if not is_instance_valid(entry.player):
		return

	if stop_player:
		_stop_player(entry.player)
	elif entry.player is AudioStreamPlayer:
		(entry.player as AudioStreamPlayer).volume_db = -80.0
	elif entry.player is AudioStreamPlayer3D:
		(entry.player as AudioStreamPlayer3D).volume_db = -80.0

	entry.player.queue_free()


func _on_player_tree_exited(sound_id: int) -> void:
	_active_sounds.erase(sound_id)


func _on_player_finished(sound_id: int) -> void:
	var entry := _active_sounds.get(sound_id) as ActiveSound
	if entry == null:
		return

	_release_entry(sound_id, entry, false)


func _begin_fade_out(sound_id: int, entry: ActiveSound, stop_after_fade: bool) -> void:
	if entry.fading_out:
		return

	entry.fading_out = true
	_kill_entry_tween(entry)

	if not is_instance_valid(entry.player):
		_release_entry(sound_id, entry, stop_after_fade)
		return

	if entry.fade_out_seconds <= 0.0:
		_release_entry(sound_id, entry, stop_after_fade)
		return

	var tween := create_tween()
	entry.fade_tween = tween
	var target_volume := -80.0
	tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(entry.player, "volume_db", target_volume, entry.fade_out_seconds)
	tween.finished.connect(_on_entry_fade_finished.bind(sound_id, stop_after_fade), CONNECT_ONE_SHOT)


func _on_entry_fade_finished(sound_id: int, stop_after_fade: bool) -> void:
	var entry := _active_sounds.get(sound_id) as ActiveSound
	if entry == null:
		return

	_release_entry(sound_id, entry, stop_after_fade)


func _kill_entry_tween(entry: ActiveSound) -> void:
	if entry == null:
		return

	if entry.fade_tween != null and is_instance_valid(entry.fade_tween):
		entry.fade_tween.kill()
	entry.fade_tween = null
