extends Control

@onready var dwarf_instance: Node2D = $CanvasLayer/Title/Dwarf

#Start
func _on_start_pressed():
	get_tree().change_scene_to_file("res://scenes/level1.tscn")


func _ready() -> void:
	dwarf_instance.get_node("AnimatedSprite2D").play("idle")
