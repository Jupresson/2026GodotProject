# scripts/managers/game_manager.gd
extends Node
class_name GameManagerClass

@export var respawn_scene_path: String = "res://addons/ultimate_character/Sample/SampleScene.tscn"
@export var player_prefab_path: String = "res://scenes/player.tscn"

@export_group("Startup Display Settings")
@export var apply_display_settings_on_startup: bool = true
@export var startup_resolution: String = "1920x1080"
@export var startup_fullscreen: bool = true
@export var startup_vsync: bool = false
@export_range(50.0, 200.0, 1.0) var startup_scale_percent: float = 100.0
@export_range(-1, 2, 1) var startup_scaler_index: int = -1
@export_range(-1, 4, 1) var startup_fsr_preset_index: int = 2
@export_range(-1, 8, 1) var startup_screen_index: int = 1

const STARTUP_RESOLUTIONS: Dictionary = {
	"3840x2160": Vector2i(3840, 2160),
	"2560x1440": Vector2i(2560, 1440),
	"1920x1080": Vector2i(1920, 1080),
	"1366x768": Vector2i(1366, 768),
	"1536x864": Vector2i(1536, 864),
	"1280x720": Vector2i(1280, 720),
	"1440x900": Vector2i(1440, 900),
	"1600x900": Vector2i(1600, 900),
	"1024x600": Vector2i(1024, 600),
	"800x600": Vector2i(800, 600)
}

var current_respawn_point_position: Vector3 = Vector3.ZERO
var current_respawn_point_rotation: Vector3 = Vector3.ZERO
signal player_died

func _ready():
	add_to_group("autoload")
	if apply_display_settings_on_startup:
		_apply_startup_display_settings()

	# Find the initial player in the scene and connect it
	await get_tree().process_frame  # Wait for scene to fully load
	var initial_player = get_tree().root.find_child("Player", true, false)
	_connect_player_health(initial_player)


func _apply_startup_display_settings() -> void:
	var _window := get_window()
	var screen_count := DisplayServer.get_screen_count()

	if startup_screen_index >= 0 and startup_screen_index < screen_count:
		_window.set_mode(Window.MODE_WINDOWED)
		_window.set_current_screen(startup_screen_index)

	if STARTUP_RESOLUTIONS.has(startup_resolution):
		_window.set_size(STARTUP_RESOLUTIONS[startup_resolution])

	_window.set_mode(Window.MODE_FULLSCREEN if startup_fullscreen else Window.MODE_WINDOWED)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if startup_vsync else DisplayServer.VSYNC_DISABLED)

	var viewport := get_tree().root.get_viewport()
	if startup_scaler_index >= 0:
		match startup_scaler_index:
			1:
				viewport.set_scaling_3d_mode(Viewport.SCALING_3D_MODE_BILINEAR)
			2:
				viewport.set_scaling_3d_mode(Viewport.SCALING_3D_MODE_FSR2)

	if viewport.get_scaling_3d_mode() == Viewport.SCALING_3D_MODE_FSR2 and startup_fsr_preset_index >= 1:
		viewport.set_scaling_3d_scale(_get_fsr_scale_from_preset(startup_fsr_preset_index))
	else:
		var safe_scale_percent := clampf(startup_scale_percent, 50.0, 200.0)
		if viewport.get_scaling_3d_mode() == Viewport.SCALING_3D_MODE_FSR2:
			safe_scale_percent = minf(safe_scale_percent, 100.0)
		viewport.set_scaling_3d_scale(safe_scale_percent / 100.0)

	if not startup_fullscreen:
		_centre_window()


func _get_fsr_scale_from_preset(preset_index: int) -> float:
	match preset_index:
		1:
			return 0.50
		2:
			return 0.59
		3:
			return 0.67
		4:
			return 0.77
		_:
			return 0.77


func _centre_window() -> void:
	var centre_screen := Vector2(DisplayServer.screen_get_position()) + (Vector2(DisplayServer.screen_get_size()) / 2.0)
	var window_size := Vector2(get_window().get_size_with_decorations())
	get_window().set_position(Vector2i(centre_screen - (window_size / 2.0)))

func _connect_player_health(player: Node) -> void:
	if player and player.has_node("HealthComponent"):
		var health = player.get_node("HealthComponent")
		if not health.died.is_connected(_on_player_died):
			health.died.connect(_on_player_died)
	else:
		pass
		#push_error("Could not find Player with HealthComponent in scene")

func respawn_player() -> void:
	await get_tree().process_frame  # Wait for death cleanup
	var player = load(player_prefab_path).instantiate()
	get_tree().root.add_child(player)
	player.global_position = current_respawn_point_position
	player.rotation = current_respawn_point_rotation
	_connect_player_health(player)

func set_checkpoint(position: Vector3, rotation: Vector3) -> void:
	current_respawn_point_position = position
	current_respawn_point_rotation = rotation

func _on_player_died(_player: Node3D) -> void:
	player_died.emit()
	var managers: Array[Node] = get_tree().get_nodes_in_group("audio_manager")
	if not managers.is_empty() and managers[0].has_method("stop_all"):
		managers[0].call("stop_all")
	respawn_player()
