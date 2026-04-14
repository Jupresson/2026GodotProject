extends Node3D

func _on_area_3d_body_entered(body: Node3D) -> void:
    if body.is_in_group("player"):
        var health = body.get_node_or_null("HealthComponent")
        if health:
            health.take_damage(1)