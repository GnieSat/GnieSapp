extends Node2D
class_name JsonHandle

signal start_load

@export var SavePath : String = "res://Resources/Saves/test.json"
@export var LoadPath : String = "res://Resources/Saves/test.json"

var File : FileAccess
var Ccontainer : Array[Dictionary] = []
var container : Dictionary


func JLOpen(truncate : int) -> void:
	File = FileAccess.open(SavePath, truncate) 
	if File.get_length() > 0:
		JLBigLoad()

func JLClose() -> void:
	if File != null:
		File.close()
	Ccontainer = []


func JLSaveAdd(value : Dictionary) -> void:
	Ccontainer.append(value)
	var jsonsolution = JSON.stringify(value)
	File.seek_end(0)
	File.store_line(jsonsolution)


func JLLittleLoad(index : int) -> Dictionary:
	var line : String
	var json_line : JSON
	for i in index:
		line = File.get_line()
	json_line.parse_string(line)
	return json_line.data

func JLBigLoad() -> void:
	var line : String
	while not File.eof_reached():
		line = File.get_line()
		Ccontainer.append(JSON.parse_string(line))
	start_load.emit()


func Jadd(index : String, value : Dictionary) -> void:
	container[index] = value
	container["size"] = index

func makeTracePos(pos : Vector3) -> Dictionary:
	var result : Dictionary
	result["TracePos"] = Dictionary()
	result["TracePos"]["X"] = pos.x
	result["TracePos"]["Y"] = pos.y
	result["TracePos"]["Z"] = pos.z
	return result

func Jsave() -> void:
	var file = FileAccess.open(SavePath, FileAccess.WRITE) 
	var jsonsolution = JSON.stringify(container, "\t")
	file.store_string(jsonsolution)
	file.close()

func Jload() -> void:
	if FileAccess.file_exists(LoadPath):
		var jsonHandle : Dictionary = {}
		var file = FileAccess.open(LoadPath, FileAccess.READ) 
		jsonHandle = JSON.parse_string(file.get_as_text())
		file.close()
		assert(jsonHandle is Dictionary)
		container = jsonHandle
	else:
		OS.alert("Savefile not found")

func flush():
	container.clear()
