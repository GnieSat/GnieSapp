@tool
extends Node3D

func _ready() -> void:
	$Label3D.position = $Path3D.curve.get_point_position(1)

func update_line_target(pos : Vector3):
	$SpatiaLine/Path3D.curve.set_point_position(1, pos + Vector3(0, 1, 0))


func _on_spatia_line_line_update() -> void:
	$Label3D.position = $Path3D.curve.get_point_position(1)
