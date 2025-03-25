@tool
extends Node2D
class_name button

signal on_pressed

@export var Name : String = "Start"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$RichTextLabel.text = Name

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		$RichTextLabel.text = Name

	if not Engine.is_editor_hint():
		return




func _on_button_pressed() -> void:
	on_pressed.emit()
