extends Node2D

signal MapUpdate(data : Dictionary)
signal MapGPSUpdate(pos : Vector3)

signal SubtleMapUpdate(data : Dictionary)

signal PointAdded()
signal PointReaded(data : Vector3)
signal ClearPoints()

enum MessageTypes 
{
	Photo,
	Sound
}

var counter : int = 0;
var last_OptionPanelPos : Vector2 = Vector2.ZERO 
var LastTracePos : Dictionary
var mouse_entered : bool = false
var has_focus : bool = false
var error_weight : int = 0

var WriteType : int = 3
var WorkMode : String = "Read"
var MessageType : int = false
var CanSatAcquireMode : int = false
var update_Slider : Callable

@onready var ArduinoProcessor : Node = get_node("DragComponent2/Node/Container/ArduinoReader")
@onready var OptionPanel : Node = get_node("DragComponent2/Node/OptionPanel")
@onready var DataSlider : Node = get_node("DragComponent2/Node/Container/DataSlider")
@onready var state_machine = $AnimationTree.get("parameters/playback")
@onready var Math = $Math
@onready var Chartt = $DragComponent2/Node/Container/Chart2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	OptionPanel.load.connect(_on_option_panel_load)
	OptionPanel.start.connect(_on_option_panel_start)
	OptionPanel.stop.connect(_on_option_panel_stop)
	OptionPanel.pathsave.connect(_on_option_panel_pathsave)
	OptionPanel.pathload.connect(_on_option_panel_pathload)
	reset_Slider()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	update.call()

var update = func():
	pass

func reset_Slider():
	update_Slider = func(): # this function does nothing for the first call
		update_Slider = func():
			DataSlider.max_value += 1
			if DataSlider.max_value - 1 == DataSlider.value:
				DataSlider.value = DataSlider.max_value

func do_ChartSelf(data : Dictionary) -> void:
	Chartt.new_Temperature(data["Temperature"])
	Chartt.new_Pressure(data["Pressure"])
	Chartt.new_Radiation(data["Radiation"])
	Chartt.new_Humidity(data["Humidity"])
	Chartt.new_Gas1(data["Gas1"])
	Chartt.new_Gas2(data["Gas2"])
	Chartt.new_Light(data["Battery"]["Battery2"])

func fill_Chart() -> void :
	Chartt.new_Temperature(0)
	Chartt.new_Pressure(0)
	Chartt.new_Radiation(0)
	Chartt.new_Humidity(0)
	Chartt.new_Gas1(0)
	Chartt.new_Gas2(0)
	Chartt.new_Light(0)

func parse_to_TextBox(container: Dictionary):
	$DragComponent2/Node/Container/Temperature.Xupdate(str(container["Temperature"]))
	$DragComponent2/Node/Container/Pressure.Xupdate(str(container["Pressure"]))
	$DragComponent2/Node/Container/Radiation.Xupdate(str(container["Radiation"]))
	$DragComponent2/Node/Container/Humidity.Xupdate(str(container["Humidity"]))
	$DragComponent2/Node/Container/Gas1.Xupdate(str(container["Gas1"]))
	$DragComponent2/Node/Container/Gas2.Xupdate(str(container["Gas2"]))
	$DragComponent2/Node/Container/Battery.refresh(container["Battery"])
	$DragComponent2/Node/Container/DataSlider/Time.text = "Time: " + to_Time(container["Time"])
	MapUpdate.emit(container["Position"])

func to_Time(dict : Dictionary) -> String :
	return str(dict["hour"]) + ":" + str(dict["minute"]) + ":" + str(dict["second"])

func do_Type(raw_data : PackedByteArray) -> int:
	var val : int = raw_data.decode_u8(0)
	MessageType = val
	return val

func do_Mode(raw_data : PackedByteArray) -> int:
	var val : int = raw_data.decode_u8(0)
	CanSatAcquireMode = val
	return val


func do_Temperature(raw_data : PackedByteArray) -> int:
	var val = raw_data.decode_u8(0) - 129
	Chartt.new_Temperature(val)
	return val

func do_Pressure(raw_data : PackedByteArray) -> int:
	var val = raw_data.decode_u16(0)
	Chartt.new_Pressure(val)
	return val

func do_Radiation(raw_data : PackedByteArray) -> int:
	var val = raw_data.decode_u8(0)
	Chartt.new_Radiation(val)
	return val

func do_Humidity(raw_data : PackedByteArray) -> int:
	var val = raw_data.decode_u8(0)
	Chartt.new_Humidity(val)
	return val

func do_Gas1(raw_data : PackedByteArray) -> int:
	var val = raw_data.decode_u8(0)
	Chartt.new_Gas1(val)
	return val

func do_Gas2(raw_data : PackedByteArray) -> int:
	var val = raw_data.decode_u8(0)
	Chartt.new_Gas2(val)
	return val

func do_Color(raw_data : PackedByteArray) -> int:
	return raw_data.decode_u16(0)

func do_Battery(raw_data : PackedByteArray) -> Dictionary:
	var val : int = raw_data.slice(1,2).decode_u8(0) / 10
	Chartt.new_Light(val)
	return {
		"Battery1" : raw_data.slice(0,1).decode_u8(0) / 10,
		"Battery2" : val
	}

func do_Light(raw_data : PackedByteArray) -> Dictionary:
	var val = raw_data.slice(6,8).decode_u16(0)
	var result : Dictionary = {
		"R" : str(raw_data.slice(0.2).decode_u16(0)),
		"G" : str(raw_data.slice(2,4).decode_u16(0)),
		"B" : str(raw_data.slice(4,6).decode_u16(0)),
		"Clear" : str(val),
		"IR" : str(raw_data.slice(8,10).decode_u16(0)),
	}
	
	return result

func do_Position(raw_data : PackedByteArray) -> Dictionary:
	var result : Dictionary = {
		"Long" : raw_data.slice(0,4).decode_float(0),
		"Lat" : raw_data.slice(4,8).decode_float(0),
		"Height" : raw_data.slice(8,10).decode_u16(0),
	}
	return result

func update_on_Raw(message : PackedByteArray):
	var container : Dictionary = {
		"index" : counter,
		"MessageType" : do_Type(message.slice(0,1)),
		"Battery" : do_Battery(message.slice(1,3)),
		"Mode" : do_Mode(message.slice(3,4)),
		"Position" : do_Position(message.slice(4,14)),
		"Temperature" : do_Temperature(message.slice(14,15)),
		"Pressure" : do_Pressure(message.slice(15,17)),
		"Humidity" : do_Humidity(message.slice(17,18)),
		"Radiation" : do_Radiation(message.slice(18,19)),
		"Gas1" : do_Gas1(message.slice(19,20)),
		"Gas2" : do_Gas2(message.slice(20,21)),
		"Time" : Time.get_time_dict_from_system()
	}
	SubtleMapUpdate.emit(container["Position"])
	PointAdded.emit()
	counter += 1
	
	container["TracePos"] = LastTracePos["TracePos"]
	
	$JsonHandle.JLSaveAdd(container)
	update_Slider.call()
	print(DataSlider.max_value)


func revert(arr : PackedByteArray) -> PackedByteArray:
	#arr.reverse()
	return arr

func update_SliderLayout():
	DataSlider.position.x = -100 + DataSlider.max_value * 15
	DataSlider.size.x = DataSlider.max_value * 15

#var points = [1,3,0,2]
#var ccounter : int = 0

func _on_option_panel_start() -> void:
	#var file = FileAccess.open("Output/News/ooutput_part_"+str(points[ccounter])+".hex", FileAccess.READ)
	#$DragComponent2/Imager.parse_Batch(file.get_buffer(file.get_length()))
	#ccounter += 1
	#ccounter = ccounter % 4
	
	Logger.add_Log("- Started")
	if WorkMode == "Read":
		$JsonHandle.JLClose()
		$JsonHandle.JLOpen(WriteType)
		reset_Slider()
		counter = 0
		DataSlider.max_value = 0
		ClearPoints.emit()
		Chartt.clear_All()
		if DataSlider.max_value - 1 == DataSlider.value:
			DataSlider.value = DataSlider.max_value
	ArduinoProcessor.start()
	WorkMode = "Active"


func _on_option_panel_stop() -> void:
	ArduinoProcessor.stop()

func _on_arduino_reader_on_update(message: PackedByteArray, sender : String) -> void:
	#if messagep[0] == "G":
		#
	#else:
	#message.reverse()
	update_on_Raw(message)
	$DragComponent2/Node/OptionPanel/TabContainer/Active/AntennaName.text = "Data current sender: " + sender

func _on_arduino_reader_on_lack_data() -> void:
	fill_Chart()
	$DragComponent2/Node/OptionPanel/TabContainer/Active/AntennaName.text = "Data current sender: None"

func _on_data_slider_value_changed(value: float) -> void:
	if $JsonHandle.Ccontainer.size() > 0:
		parse_to_TextBox($JsonHandle.Ccontainer[DataSlider.value])


func _on_json_handle_start_load() -> void:
	counter = 0
	ClearPoints.emit()
	var data_size : int = $JsonHandle.Ccontainer.size()
	DataSlider.max_value = data_size - 1
	Chartt.clear_All()
	if DataSlider.max_value - 1 == DataSlider.value:
		DataSlider.value = DataSlider.max_value
	for n in data_size:
		do_ChartSelf($JsonHandle.Ccontainer[n])
		MapUpdate.emit($JsonHandle.Ccontainer[n]["Position"])
		PointReaded.emit(Vector3(
			$JsonHandle.Ccontainer[n]["TracePos"]["X"],
			$JsonHandle.Ccontainer[n]["TracePos"]["Y"],
			$JsonHandle.Ccontainer[n]["TracePos"]["Z"]
			))
	WorkMode = "Read"


func _on_option_panel_load() -> void:
	ArduinoProcessor.stop()
	$JsonHandle.JLClose()
	$JsonHandle.JLOpen(FileAccess.READ)
	$JsonHandle.JLBigLoad()


func _on_option_panel_pathsave(path: String) -> void:
	$JsonHandle.SavePath = path


func _on_option_panel_pathload(path: String) -> void:
	$JsonHandle.SavePath = path


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


func _on_option_panel_port_change(index : int, port: String) -> void:
	$DragComponent2/Node/Container/ArduinoReader.PortName = port


func _on_option_panel_write_type_change(val: int) -> void:
	WriteType = 3 + 4 * val


func _on_arduino_reader_on_error(really: bool) -> void:
	if really:
		error_weight += 1
	else:
		error_weight = 0
	if error_weight > 2:
		$DragComponent2/Node/StabilityState.texture = ImageTexture.create_from_image(Image.load_from_file("res://Resources/Textures/NEIN.png"))
	elif error_weight > 0:
		$DragComponent2/Node/StabilityState.texture = ImageTexture.create_from_image(Image.load_from_file("res://Resources/Textures/MID.png"))
	else:
		$DragComponent2/Node/StabilityState.texture = ImageTexture.create_from_image(Image.load_from_file("res://Resources/Textures/OK.png"))
func _on_map_viewport_trace_saved(pos: Vector3) -> void:
	LastTracePos = $JsonHandle.makeTracePos(pos)


func _on_temperature_pressed() -> void:
	Chartt.Temp.get_parent().visible = true
	$DragComponent2/Node/Container/ChartName.text = "Current chart: Temperature"

func _on_pressure_pressed() -> void:
	Chartt.Pres.get_parent().visible = true
	$DragComponent2/Node/Container/ChartName.text = "Current chart: Pressure"

func _on_radiation_pressed() -> void:
	Chartt.Rad.get_parent().visible = true
	$DragComponent2/Node/Container/ChartName.text = "Current chart: Radiation"

func _on_humidity_pressed() -> void:
	Chartt.Hum.get_parent().visible = true
	$DragComponent2/Node/Container/ChartName.text = "Current chart: Humidity"

func _on_gas_1_pressed() -> void:
	Chartt.Gas1.get_parent().visible = true
	$DragComponent2/Node/Container/ChartName.text = "Current chart: CO concetration"
	
func _on_gas_2_pressed() -> void:
	Chartt.Gas2.get_parent().visible = true
	$DragComponent2/Node/Container/ChartName.text = "Current chart: NO2 concetration"

func _on_light_pressed() -> void:
	pass

func _on_battery_pressed() -> void:
	Chartt.Light.get_parent().visible = true
	$DragComponent2/Node/Container/ChartName.text = "Current chart: Battery level"


func _on_option_panel_timestamp_request() -> void:
	var data_size : int  = int($JsonHandle.Ccontainer.size())
	var pos : int = DataSlider.value
	var target = 100 + pos if data_size - pos >= 100 else data_size
	Chartt.clear_All()
	Chartt.set_CounterTime(pos+1)
	for n in range(pos, target):
		do_ChartSelf($JsonHandle.Ccontainer[n])

func update_on_RawOld(message : PackedByteArray):
	var container : Dictionary = {
		"Temperature" : do_Temperature(message.slice(0,1)),
		"Pressure" : do_Pressure(message.slice(1,3)),
		"Radiation" : do_Radiation(message.slice(3,5)),
		"Humidity" : do_Humidity(message.slice(5,6)),
		"Gas1" : do_Gas1(message.slice(6,8)),
		"Gas2" : do_Gas2(message.slice(8,10)),
		"Light" : do_Light(message.slice(10,20)),
		"Position" : do_Position(message.slice(20,31)),
		"Time" : Time.get_time_dict_from_system()
	}
	$JsonHandle.Jadd(str(counter), container)
	SubtleMapUpdate.emit(container["Position"])
	PointAdded.emit()
	counter += 1
	
	update_Slider.call()
