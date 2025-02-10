extends Node2D

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Get window"):
		$StatPanel.global_position = get_global_mouse_position() + Vector2(350, -40)
