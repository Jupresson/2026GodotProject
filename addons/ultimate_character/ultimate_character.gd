@tool
extends EditorPlugin

func _enter_tree():
	var icon: Texture2D = null
	if ResourceLoader.exists("res://addons/ultimate_character/UCharacterBody3D.svg"):
		icon = load("res://addons/ultimate_character/UCharacterBody3D.svg")
	add_custom_type("UCharacterBody3D", "CharacterBody3D", preload("ucharacterbody3d.gd"), icon)

func _exit_tree():
	remove_custom_type("UCharacterBody3D")
