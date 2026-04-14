@tool
extends RoommateStyle


@export_group("Materials")
@export var wall_material: Material = preload("res://materials/walls/old_decorative_wallpaper_2k_mat.tres")
@export var floor_material: Material = preload("res://materials/ground/Carpet_2k_mat.tres")
@export var ceiling_material: Material = preload("res://materials/ceiling/OfficeCeiling_2k_mat.tres")


func _build_rulesets() -> void:
	var ruleset := create_ruleset()
	ruleset.select_all_blocks()


	var walls_setter := ruleset.select_all_walls()
	if wall_material:
		walls_setter.override_fallback_surface().material.override(wall_material)


	var floor_setter := ruleset.select_floor()
	if floor_material:
		floor_setter.override_fallback_surface().material.override(floor_material)


	var roof_setter := ruleset.select_ceil()
	if ceiling_material:
		roof_setter.override_fallback_surface().material.override(ceiling_material)
