extends Button
class_name DragComponent

@export var SCALE_FACTOR : Vector2 = Vector2(0, 0)

var Offset: Vector2 = Vector2()
var is_Dragging: bool = false

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and is_Dragging:
		get_parent().global_position = get_global_mouse_position() - Offset * SCALE_FACTOR


func _on_button_down() -> void:
	Offset = get_local_mouse_position()
	is_Dragging = true


func _on_button_up() -> void:
	is_Dragging = false
