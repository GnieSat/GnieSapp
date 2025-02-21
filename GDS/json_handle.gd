extends Node2D
class_name JsonHandle

signal start_load

@export var SavePath : String = "res://Resources/Saves/test.json"
@export var LoadPath : String = "res://Resources/Saves/test.json"

var container : Dictionary

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func Jadd(index:String, value : Dictionary):
	container[index] = value
	container["size"] = index

func Jsave():
	var file = FileAccess.open(SavePath, FileAccess.WRITE) 
	var jsonsolution = JSON.stringify(container, "\t")
	file.store_string(jsonsolution)
	file.close()

func JustAdd(String, value : Dictionary, size : int):
	var new_entry : Dictionary = Dictionary()

func Jload():
	if FileAccess.file_exists(LoadPath):
		var jsonHandle : Dictionary = {}
		var file = FileAccess.open(LoadPath, FileAccess.READ) 
		jsonHandle = JSON.parse_string(file.get_as_text())
		file.close()
		assert(jsonHandle is Dictionary)
		container = jsonHandle
		start_load.emit()
	else:
		OS.alert("Savefile not found")

func flush():
	container.clear()
