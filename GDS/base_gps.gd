extends Node2D

signal lat_update(val: String)
signal long_update(val: String)
signal map_update

var is_extended = false


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
