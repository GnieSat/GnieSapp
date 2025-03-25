extends Node2D

#GPS
signal lat_update(val: String)
signal long_update(val: String)
signal map_update

#PLANE
signal map_range_update(val: int)

signal model_update(val : int)
signal focus_update(val : int)

@export var save_path : SaveFilePath = null

var is_extended = false

func _ready() -> void:
	var save_file := ConfigFile.new()
	var error := save_file.load(save_path.Last_Pos_Source)
	
	if error:
		print("An error happened while loading data: ", error)
		return
	$BaseGPS/GPSLocation/Long/LineEdit.text = str(save_file.get_value("Cords", "Long"))
	$BaseGPS/GPSLocation/Lat/LineEdit.text = str(save_file.get_value("Cords", "Lat"))
	long_update.emit(str(save_file.get_value("Cords", "Long")))
	lat_update.emit(str(save_file.get_value("Cords", "Lat")))

func _on_button_pressed() -> void:
	if is_extended:
		$AnimationPlayer.play_backwards("Extend")
		is_extended = false
	else:
		$AnimationPlayer.play("Extend")
		is_extended = true


func _on_lat_pressedtext(val: String) -> void:
	lat_update.emit(val)


func _on_long_pressedtext(val: String) -> void:
	long_update.emit(val)


func _on_update_on_pressed() -> void:
	map_update.emit()


func _on_option_button_item_selected(index: int) -> void:
	map_range_update.emit(index)


func _on_model_chosen(index: int) -> void:
	model_update.emit(index)


func _on_Focus_selected(index: int) -> void:
	focus_update.emit(index)
