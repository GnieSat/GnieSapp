extends Node2D

var counter : int = 0;
var last_OptionPanelPos : Vector2 = Vector2(0,0) 
var mouse_entered : bool = false

@onready var state_machine = $AnimationTree.get("parameters/playback")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$DragComponent2/Node/OptionPanel.load.connect(_on_option_panel_load)
	$DragComponent2/Node/OptionPanel.start.connect(_on_option_panel_start)
	$DragComponent2/Node/OptionPanel.stop.connect(_on_option_panel_stop)
	$DragComponent2/Node/OptionPanel.pathsave.connect(_on_option_panel_pathsave)
	$DragComponent2/Node/OptionPanel.pathload.connect(_on_option_panel_pathload)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	update.call()

var update = func():
	pass

var update_Slider = func(): # this function does nothing for the first call
	update_Slider = func():
		$DragComponent2/Node/Container/Chart/DataSlider.max_value += 1
		if $DragComponent2/Node/Container/Chart/DataSlider.max_value - 1 == $DragComponent2/Node/Container/Chart/DataSlider.value:
			$DragComponent2/Node/Container/Chart/DataSlider.value = $DragComponent2/Node/Container/Chart/DataSlider.max_value

func parse_to_TextBox(container: Dictionary):
	$DragComponent2/Node/Container/Temperature.Xupdate(container["Temperature"])
	$DragComponent2/Node/Container/Pressure.Xupdate(container["Pressure"])
	$DragComponent2/Node/Container/Radiation.Xupdate(container["Radiation"])
	$DragComponent2/Node/Container/Gas1.Xupdate(container["Gas1"])
	$DragComponent2/Node/Container/Gas2.Xupdate(container["Gas2"])

func do_Temperature(raw_data : String) -> String:
	return raw_data

func do_Pressure(raw_data : String) -> String:
	return raw_data

func do_Radiation(raw_data : String) -> String:
	return raw_data

func do_Gas(raw_data : String) -> String:
	return raw_data


func update_on_Raw(message : String):
	var container : Dictionary = {
		"Temperature" : do_Temperature(message.substr(0,2)),
		"Pressure" : do_Pressure(message.substr(2,2)),
		"Radiation" : do_Radiation(message.substr(4,2)),
		"Gas1" : do_Gas(message.substr(6,2)),
		"Gas2" : do_Gas(message.substr(8,2))
	}
	
	$JsonHandle.Jadd(str(counter), container)
	$JsonHandle.Jsave()
	counter += 1
	
	update_Slider.call()


func update_on_Processed():
	pass


func _on_option_panel_start() -> void:
	$DragComponent2/Node/Container/ArduinoReader.start()


func _on_option_panel_stop() -> void:
	$DragComponent2/Node/Container/ArduinoReader.stop()


func _on_arduino_reader_on_update(message: String) -> void:
	update_on_Raw(message)



func _on_data_slider_value_changed(value: float) -> void:
	if $JsonHandle.container.has(str($DragComponent2/Node/Container/Chart/DataSlider.value)):
		parse_to_TextBox($JsonHandle.container[str($DragComponent2/Node/Container/Chart/DataSlider.value)])


func _on_json_handle_start_load() -> void:
	counter = 0
	$DragComponent2/Node/Container/Chart/DataSlider.max_value = int($JsonHandle.container["size"])
	if $DragComponent2/Node/Container/Chart/DataSlider.max_value - 1 == $DragComponent2/Node/Container/Chart/DataSlider.value:
		$DragComponent2/Node/Container/Chart/DataSlider.value = $DragComponent2/Node/Container/Chart/DataSlider.max_value


func _on_option_panel_load() -> void:
	$DragComponent2/Node/Container/ArduinoReader.stop()
	$JsonHandle.Jload()


func _on_option_panel_pathsave(path: String) -> void:
	$JsonHandle.SavePath = path


func _on_option_panel_pathload(path: String) -> void:
	$JsonHandle.LoadPath = path


func _on_option_panel_maximize() -> void:
	if mouse_entered:
		state_machine.travel("Extend")


func _on_option_panel_minimize() -> void:
	if mouse_entered:
		state_machine.travel("Extend BW")


func _on_drag_component_2_focus_entered() -> void:
	if not $DragComponent2/Node/OptionPanel.is_maximized and mouse_entered:
		state_machine.travel("PopOut")


func _on_drag_component_2_focus_exited() -> void:
	if not $DragComponent2/Node/OptionPanel.is_maximized and mouse_entered:
		state_machine.travel("PopOut BW")


func _on_area_2d_mouse_entered() -> void:
	mouse_entered = true


func _on_area_2d_mouse_exited() -> void:
	mouse_entered = false
