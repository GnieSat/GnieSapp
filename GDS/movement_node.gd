extends Node2D

var Offset: Vector2 = Vector2()
var is_Dragging: bool = false
var is_Draggable: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.is_pressed() and is_Draggable:
			Offset = get_local_mouse_position()
			is_Dragging = true
		else:
			is_Dragging = false
	if event is InputEventMouseMotion and is_Dragging:
		global_position = get_global_mouse_position() - Offset


func _on_mouse_entered() -> void:
	is_Draggable = true


func _on_mouse_exited() -> void:
	is_Draggable = false
	Offset = Vector2(0, 0)
