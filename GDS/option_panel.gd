extends Node2D

@export var ModulationResource: ModSource = null

signal start
signal stop

signal load

signal pathsave(path : String)
signal pathload(path : String)

signal PortChange(port : String)
signal WriteType_change(val : int)

signal maximize
signal minimize
var is_maximized = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_button_on_pressed() -> void:
	start.emit()


func _on_button_2_on_pressed() -> void:
	stop.emit()


func _on_button_load_on_pressed() -> void:
	load.emit()

func _on_buttonSave_save(path: String) -> void:
	pathsave.emit(path)

func _on_buttonLoad_save(path: String) -> void:
	pathload.emit(path)


func _on_extend_button_on_pressed() -> void:
	if is_maximized:
		minimize.emit()
		is_maximized = false
		$TabContainer/ExtendButton/RichTextLabel.text = "[center]->[/center]"
		$AnimationPlayer.play_backwards("Extend")
	else:
		maximize.emit()
		is_maximized = true
		$TabContainer/ExtendButton/RichTextLabel.text = "[center]<-[/center]"
		$AnimationPlayer.play("Extend")


func _on_button_port_pressedtext(val: String) -> void:
	PortChange.emit(val)


func _on_WriteType_selected(index: int) -> void:
	WriteType_change.emit(index)
