extends Node2D

#GPS
signal lat_update(val: String)
signal long_update(val: String)
signal map_update

#PLANE
signal map_range_update(val: int)

signal model_update(val : int)
signal focus_update(val : int)

var is_extended = false

@export var last_open_data : LastOpenData = null

func _ready() -> void:
	$BaseGPS/GPSLocation/Long/LineEdit.text = str(last_open_data.Last_Pos.x)
	$BaseGPS/GPSLocation/Lat/LineEdit.text = str(last_open_data.Last_Pos.y)

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
