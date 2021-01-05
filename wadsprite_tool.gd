tool
extends EditorPlugin


func _enter_tree():
	add_custom_type("WadSprite", "AnimatedSprite", preload("res://WadSprite.gd"), preload("res://icon.png"))

func _exit_tree():
	remove_custom_type("WadSprite")
