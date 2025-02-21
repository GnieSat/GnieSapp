extends button

signal pressedtext(val : String)

func _on_on_pressed() -> void:
	pressedtext.emit($LineEdit.text)
