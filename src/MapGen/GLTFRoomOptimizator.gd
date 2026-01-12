@icon("res://MapGen/icons/GLTFRoomOptimizer.svg")
extends Node3D
class_name GLTFRoomOptimizator

var distance_between_camera_and_self: float = 64.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if get_viewport().get_camera_3d().global_position.distance_to(global_position) > distance_between_camera_and_self:
		hide()
	else:
		show()
