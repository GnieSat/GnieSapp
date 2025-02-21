extends Node2D

var counter : int = 0;
var last_OptionPanelPos : Vector2 = Vector2(0,0) 
var mouse_entered : bool = false
var has_focus : bool = false
var error_weight : int = 0

var WorkMode : String = ""

@onready var ArduinoProcessor : Node = get_node("DragComponent2/Node/Container/ArduinoReader")
@onready var OptionPanel : Node = get_node("DragComponent2/Node/OptionPanel")
@onready var DataSlider : Node = get_node("DragComponent2/Node/Container/DataSlider")
@onready var state_machine = $AnimationTree.get("parameters/playback")

signal MapUpdate(data : Dictionary)
signal MapGPSUpdate(pos : Vector3)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	OptionPanel.load.connect(_on_option_panel_load)
	OptionPanel.start.connect(_on_option_panel_start)
	OptionPanel.stop.connect(_on_option_panel_stop)
	OptionPanel.pathsave.connect(_on_option_panel_pathsave)
	OptionPanel.pathload.connect(_on_option_panel_pathload)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	update.call()

var update = func():
	pass

var update_Slider = func(): # this function does nothing for the first call
	update_Slider = func():
		DataSlider.max_value += 1
		if DataSlider.max_value - 1 == DataSlider.value:
			DataSlider.value = DataSlider.max_value

func parse_to_TextBox(container: Dictionary):
	$DragComponent2/Node/Container/Temperature.Xupdate(container["Temperature"])
	$DragComponent2/Node/Container/Pressure.Xupdate(container["Pressure"])
	$DragComponent2/Node/Container/Radiation.Xupdate(container["Radiation"])
	$DragComponent2/Node/Container/Humidity.Xupdate(container["Humidity"])
	$DragComponent2/Node/Container/Gas1.Xupdate(container["Gas1"])
	$DragComponent2/Node/Container/Gas2.Xupdate(container["Gas2"])
	$DragComponent2/Node/Container/Light.XXupdate(
		str(container["Light"]["R"]),
		str(container["Light"]["G"]),
		str(container["Light"]["B"]),
		str(container["Light"]["Clear"]),
		str(container["Light"]["IR"])
		)
	MapUpdate.emit(container["Position"])

func do_Temperature(raw_data : String) -> String:
	return str(ArduinoProcessor.bits_to_sint8(raw_data))

func do_Pressure(raw_data : String) -> String:
	return str(ArduinoProcessor.bits_to_uint16(raw_data))

func do_Radiation(raw_data : String) -> String:
	return str(ArduinoProcessor.bits_to_uint16(raw_data))

func do_Humidity(raw_data : String) -> String:
	return str(ArduinoProcessor.bits_to_uint8(raw_data))

func do_Gas(raw_data : String) -> String:
	return str(ArduinoProcessor.bits_to_uint16(raw_data))

func do_Color(raw_data : String) -> String:
	return str(ArduinoProcessor.bits_to_uint16(raw_data))
	
func do_Light(raw_data : String) -> Dictionary:
	var result : Dictionary = {
		"R" : str(ArduinoProcessor.bits_to_uint16(raw_data.substr(0,16))),
		"G" : str(ArduinoProcessor.bits_to_uint16(raw_data.substr(16,16))),
		"B" : str(ArduinoProcessor.bits_to_uint16(raw_data.substr(32,16))),
		"Clear" : str(ArduinoProcessor.bits_to_uint16(raw_data.substr(48,16))),
		"IR" : str(ArduinoProcessor.bits_to_uint16(raw_data.substr(64,16))),
	}
	return result

func do_Position(raw_data : String) -> Dictionary:
	var result : Dictionary = {
		"Long" : str(ArduinoProcessor.bits_to_float32(raw_data.substr(0,32))),
		"Lat" : str(ArduinoProcessor.bits_to_float32(raw_data.substr(32,32))),
		"Height" : str(ArduinoProcessor.bits_to_uint16(raw_data.substr(64,16))),
		"Speed" : str(ArduinoProcessor.bits_to_uint8(raw_data.substr(80,8)))
	}
	return result

func update_on_Raw(message : String):
	var container : Dictionary = {
		"Temperature" : do_Temperature(message.substr(0,8)),
		"Pressure" : do_Pressure(message.substr(8,16)),
		"Radiation" : do_Radiation(message.substr(24,16)),
		"Humidity" : do_Humidity(message.substr(40, 8)),
		"Gas1" : do_Gas(message.substr(48,16)),
		"Gas2" : do_Gas(message.substr(64,16)),
		"Light" : do_Light(message.substr(80, 80)),
		"Position" : do_Position(message.substr(160, 88))
	}
	$JsonHandle.Jadd(str(counter), container)
	$JsonHandle.Jsave()
	counter += 1
	
	update_Slider.call()
	update_SliderLayout()


func update_on_Processed():
	pass

func update_SliderLayout():
	DataSlider.position.x = -100 + DataSlider.max_value * 15
	DataSlider.size.x = DataSlider.max_value * 15

func _on_option_panel_start() -> void:
	if WorkMode == "Read":
		counter = 0
		DataSlider.max_value = 0
		if DataSlider.max_value - 1 == DataSlider.value:
			DataSlider.value = DataSlider.max_value
	ArduinoProcessor.start()
	WorkMode = "Active"


func _on_option_panel_stop() -> void:
	ArduinoProcessor.stop()


func _on_arduino_reader_on_update(message: String) -> void:
	#if messagep[0] == "G":
		#
	#else:
	update_on_Raw(message)



func _on_data_slider_value_changed(value: float) -> void:
	if $JsonHandle.container.has(str(DataSlider.value)):
		parse_to_TextBox($JsonHandle.container[str(DataSlider.value)])


func _on_json_handle_start_load() -> void:
	counter = 0
	DataSlider.max_value = int($JsonHandle.container["size"])
	if DataSlider.max_value - 1 == DataSlider.value:
		DataSlider.value = DataSlider.max_value
	update_SliderLayout()
	WorkMode = "Read"


func _on_option_panel_load() -> void:
	ArduinoProcessor.stop()
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
		if not has_focus:
			state_machine.travel("PopOut BW")
		else:
			state_machine.travel("Extend BW")


func _on_drag_component_2_focus_entered() -> void:
	if not OptionPanel.is_maximized:
		state_machine.travel("PopOut")
	has_focus = true


func _on_drag_component_2_focus_exited() -> void:
	if not OptionPanel.is_maximized and not mouse_entered:
		state_machine.travel("PopOut BW")
	has_focus = false


func _on_area_2d_mouse_entered() -> void:
	mouse_entered = true


func _on_area_2d_mouse_exited() -> void:
	mouse_entered = false


func _on_option_panel_port_change(port: String) -> void:
	$DragComponent2/Node/Container/ArduinoReader.PortName = port


func _on_option_panel_write_type_change(val: int) -> void:
	pass # Replace with function body.


func _on_arduino_reader_on_error(really: bool) -> void:
	if really:
		error_weight += 1
	else:
		error_weight -= 1
	if error_weight > 2:
		$DragComponent2/Node/StabilityState.texture = ImageTexture.create_from_image(Image.load_from_file("res://Resources/Textures/NEIN.png"))
	if error_weight > 0:
		$DragComponent2/Node/StabilityState.texture = ImageTexture.create_from_image(Image.load_from_file("res://Resources/Textures/MID.png"))
