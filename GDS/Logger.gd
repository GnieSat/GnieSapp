extends Node

signal log_update

var Log : String = ""

func add_Log(log : String):
	Log += log + "\n"
	log_update.emit()

func clear():
	Log = ""
	log_update.emit()
