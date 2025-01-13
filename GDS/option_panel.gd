extends Node2D

@export var ModulationResource: ModSource = null

signal start
signal stop

signal load

signal pathsave(path : String)
signal pathload(path : String)

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
