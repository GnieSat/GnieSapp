extends button

signal save(path : String)

var is_pathname_pressed = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _on_button_pressed() -> void:
	$FileDialog.popup()


func _on_file_dialog_file_selected(path: String) -> void:
	assert(path.substr(path.length()-4, 4) == "json")
	$PathName.text = path
	save.emit(path)

func _on_path_name_button_on_pressed() -> void:
	if is_pathname_pressed == false:
		is_pathname_pressed = true
		$PathName.fit_content = true
	else:
		is_pathname_pressed = false
		$PathName.fit_content = false
