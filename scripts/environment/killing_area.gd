@tool
class_name KillingArea extends Area3D

## scene goup usseally like on player scene has root as group "player"
@export var target_group: String = ""


func _func_godot_apply_properties(entity_properties: Dictionary) -> void:
	target_group = entity_properties.get("target_group", target_group) as String

func _ready() -> void:
	if not Engine.is_editor_hint():
		_start()

func _start() -> void: # used just for a cleaner arcitehture for all entitys that has scripts.
	body_entered.connect(_on_area_3d_body_entered)

#func _exit_tree() -> void: # Used for stopping timers, killing tweens, freeing helper nodes, disconnecting signals from other nodes...

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group(target_group):
		var health = body.get_node_or_null("HealthComponent")
		if health:
			health.take_damage(1)