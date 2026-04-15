# scripts/managers/game_manager.gd
extends Node
class_name GameManagerClass

@export var respawn_scene_path: String = "res://addons/ultimate_character/Sample/SampleScene.tscn"
@export var player_prefab_path: String = "res://scenes/player.tscn"

var current_respawn_point_position: Vector3 = Vector3.ZERO
var current_respawn_point_rotation: Vector3 = Vector3.ZERO
signal player_died

func _ready():
	add_to_group("autoload")
	# Find the initial player in the scene and connect it
	await get_tree().process_frame  # Wait for scene to fully load
	var initial_player = get_tree().root.find_child("Player", true, false)
	_connect_player_health(initial_player)

func _connect_player_health(player: Node) -> void:
	if player and player.has_node("HealthComponent"):
		var health = player.get_node("HealthComponent")
		if not health.died.is_connected(_on_player_died):
			health.died.connect(_on_player_died)
	else:
		push_error("Could not find Player with HealthComponent in scene")

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
	respawn_player()
