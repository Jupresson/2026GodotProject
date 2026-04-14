# scripts/components/health_component.gd
extends Node
class_name HealthComponent

@export var max_health: int = 1
var current_health: int

signal died(player: Node3D)

func _ready():
    current_health = max_health

func take_damage(amount: int = 1) -> void:
    current_health -= amount
    if current_health <= 0:
        died.emit(get_parent() as Node3D)
        get_parent().queue_free()