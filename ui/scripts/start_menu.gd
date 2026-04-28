extends Control

const OPTIONS_SCENE_PATH := "res://ui/scenes/options_ui.tscn"
const START_SCENE_PATH := "res://scenes/levels/level_0.tscn"



const STREAM_PATH: AudioStream = preload("res://assets/sounds/sfx/general_ui/ui_click.ogg")
var bus_category: AudioManager.BusCategory = AudioManager.BusCategory.UI
var volume_db: float = -12.0
var pitch_range: Vector2 = Vector2(1.0, 1.0)
var unique_tag: StringName = &""
var category: StringName = &""
var fade_out_seconds: float = 0.15
var playback_kind: AudioManager.PlaybackKind = AudioManager.PlaybackKind.GLOBAL_2D

func _ready():
	InputManager.set_input_enabled(false)

func _on_start_pressed() -> void:
	_play_ui_click_stream_sound()
	AudioManager.stop_all()
	SceneManager.change_scene_with_loading(START_SCENE_PATH, 2.0)


func _on_settings_pressed() -> void:
	_play_ui_click_stream_sound()
	SceneManager.change_scene(OPTIONS_SCENE_PATH)


func _on_quit_pressed() -> void:
	_play_ui_click_stream_sound()
	AudioManager.stop_all()
	get_tree().quit()

func _play_ui_click_stream_sound() -> void:
	var request := AudioManager.SoundRequest.new()
	request.stream = STREAM_PATH
	request.playback_kind = playback_kind
	request.bus_category = bus_category
	request.volume_db = volume_db
	request.pitch_range = pitch_range
	request.unique_tag = unique_tag
	request.fade_out_seconds = fade_out_seconds
	AudioManager.play_sound(request)