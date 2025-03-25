@tool
extends Node3D

@export_enum ("X axis", "Y axis", "Z axis", "Direction", "Skeleton") var color_preset : int
var rotation_presets : Array[Vector3] = [ Vector3i.ZERO, Vector3i(0,0,90), Vector3i(0,-90,0), Vector3i.ZERO, Vector3i.ZERO]
var color_presets : Array[Color] = [Color("875858", 1.0), Color("58875e", 1.0), Color("5b5887", 1.0), Color("f2d472", 1.0), Color("aa9fa5", 1)]


@export var width_radius : float = 0.5
@export var line_resolution : float = 180

var target : Vector3 = Vector3.ZERO:
	set(val):
		target = val
		set_target(val)

var rotation_override : Vector3 = Vector3.ZERO:
	set(val):
		rotation_override = val
		$Path3D.rotation_degrees = rotation_override

var length : float = 0.0:
	set(val):
		length = val
		if length <= 1 and length >= -1:
			length = 1
		$Path3D.curve.set_point_position(1, Vector3(length, 0.0, 0.0))

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	setup()
	var circle = PackedVector2Array()
	for degree in line_resolution:
		var x = width_radius * sin(PI * 2 * degree / line_resolution)
		var y = width_radius * cos(PI * 2 * degree / line_resolution)
		var coords = Vector2(x,y)
		circle.append(coords)
	$CSGPolygon3D.polygon = circle

func setup():
	set_Color(color_presets[color_preset])
	
	length = 30
	rotation_override = rotation_presets[color_preset]
	$Path3D.rotation_degrees = rotation_override

func set_target(pos : Vector3):
	$Path3D.curve.set_point_position(1, pos)
	if $Path3D.curve.get_point_position(1) == $Path3D.curve.get_point_position(0):
		$Path3D.curve.set_point_position(1, Vector3(1,0,0))

func set_base(pos : Vector3):
	$Path3D.curve.set_point_position(0, pos)

func set_Color(val : Color):
	var newcolor : StandardMaterial3D = StandardMaterial3D.new()
	newcolor.render_priority = 2
	newcolor.transparency = newcolor.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
	newcolor.albedo_color = val
	$CSGPolygon3D.material_override = newcolor
