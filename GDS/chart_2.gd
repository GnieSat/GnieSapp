extends Node2D

@onready var Temp = $SubViewportContainer/SubViewport/Container/Temperature/Chart
@onready var Pres = $SubViewportContainer/SubViewport/Container/Pressure/Chart
@onready var Rad = $SubViewportContainer/SubViewport/Container/Radiation/Chart
@onready var Hum = $SubViewportContainer/SubViewport/Container/Humidity/Chart
@onready var Gas1 = $SubViewportContainer/SubViewport/Container/Gas1/Chart
@onready var Gas2 = $SubViewportContainer/SubViewport/Container/Gas2/Chart
@onready var Light = $SubViewportContainer/SubViewport/Container/Light/Chart
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func new_Temperature(val : float):
	Temp.add_Point(val)

func new_Pressure(val : float):
	Pres.add_Point(val)
	
func new_Radiation(val : float):
	Rad.add_Point(val)
	
func new_Humidity(val : float):
	Hum.add_Point(val)
	
func new_Gas1(val : float):
	Gas1.add_Point(val)
	
func new_Gas2(val : float):
	Gas2.add_Point(val)
	
func new_Light(val : float):
	Light.add_Point(val)

func clear_All():
	for tab in $SubViewportContainer/SubViewport/Container.get_children():
		tab.get_child(0).clear_Points()

func set_CounterTime(val : int):
	for tab in $SubViewportContainer/SubViewport/Container.get_children():
		tab.get_child(0).set_Counter(val)
