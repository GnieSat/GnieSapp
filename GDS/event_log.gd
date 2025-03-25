extends Node2D

func _ready() -> void:
	Logger.log_update.connect(update)
	$Label.text = Logger.Log

func update():
	$Label.text = Logger.Log
