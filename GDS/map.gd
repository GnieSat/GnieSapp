extends SubViewport

signal map_generated

# Called when the node enters the scene tree for the first time.
@export var zoom : int = 16
@onready var n : int = int(pow(2, zoom))
@export var meter_to_px_scale = 0.224

@export var last_open_data : LastOpenData = null

const CORD_STEP_SCALE_LAT : float = 111320
const k_y = 111132
var CORD_STEP_SCALE_LONG : float = 0
var CORD_STEP_SCALE_LONG_ALT : float = 0

var latlong_base = Vector3(0, 0, 0)


func _ready() -> void:
	_on_base_gps_map_range_update(0)
	_on_base_gps_long_update(str(last_open_data.Last_Pos.x))
	_on_base_gps_lat_update(str(last_open_data.Last_Pos.y))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func update_poles():
	var pos : Vector3 = $Map/Physical/CanSat.position
	$Map/Physical/Lines/XLine.length = pos.x
	$Map/Physical/Lines/YLine.length = pos.y
	$Map/Physical/Lines/ZLine.length = pos.z
	$Map/Physical/Lines/TargetLine.target = Vector3(pos.x, 0, pos.z)

func latlong_to_meters(data : Vector3) -> Vector3:
	var result : Vector3 = Vector3(0, 0, 0)
	CORD_STEP_SCALE_LONG_ALT = CORD_STEP_SCALE_LAT * cos( (latlong_base.y + data.y) / 2 * 0.01745329)
	
	result.x = (data.x - latlong_base.x) * CORD_STEP_SCALE_LONG * meter_to_px_scale
	result.y = data.y * meter_to_px_scale
	result.z = (data.z - latlong_base.z) * k_y * meter_to_px_scale * -1
	#print(result)
	return result




func _on_stat_panel_map_update(data: Dictionary) -> void:
	#print("LatLong: " + str(Vector2(float(data["Lat"]), float(data["Long"]))))
	$Map/Physical/CanSat.position = latlong_to_meters(Vector3( float(data["Long"]), float(data["Height"]), float(data["Lat"])))
	$Map/Physical/CanSat/Label3D.text = ".             Long:" + data["Long"] + "\n.             Lat:" + data["Lat"] + "\n.             Height:" + data["Height"] + ".             Speed:" + data["Speed"]
	#$Map/Physical/CanSat.position += Vector3(2,1,1)
	update_poles()

func _on_base_gps_long_update(val: String) -> void:
	latlong_base.x = float(val)

func _on_base_gps_lat_update(val: String) -> void:
	latlong_base.z = float(val)
	CORD_STEP_SCALE_LONG = CORD_STEP_SCALE_LAT * cos(latlong_base.z * 0.0174532925199)

func _on_base_gps_map_update() -> void:
	last_open_data.Last_Pos = Vector2(latlong_base.x, latlong_base.z)
	var map_generator : Thread = Thread.new()
	map_generator.start(generate_map.bind(Vector2(latlong_base.x, latlong_base.z)))

func generate_map(cords : Vector2):
	var ball = []
	OS.execute("python", ["Scripts/EEmap.py", cords.x, cords.y], ball, true, true)
	print(ball)
	call_deferred("emit_signal", "map_generated")



func MapEE_update():
	$Map/Physical/Map/Timer.start()

func _on_base_gps_map_range_update(val: int) -> void:
	$Map/Physical/Map/MapOSM.extend_by_preset(val)
	$Map/Physical/Skeleton/SkeleXLine.position.x = (val+1) * -224 
	$Map/Physical/Skeleton/SkeleXLine.length = 2 * 1000 * (val+1) * meter_to_px_scale
	
	$Map/Physical/Skeleton/SkeleZLine.position.z = (val+1) * -224 
	$Map/Physical/Skeleton/SkeleZLine.length = 2 * 1000 * (val+1) * meter_to_px_scale



func _on_base_gps_model_update(val: int) -> void:
	if val == 0:
		$Map/Physical/CanSat/MeshInstance3D2.visible = true
		$Map/Physical/CanSat/Sprite3D.visible = false
	else:
		$Map/Physical/CanSat/MeshInstance3D2.visible = false
		$Map/Physical/CanSat/Sprite3D.visible = true

func _on_base_gps_focus_update(val: int) -> void:
	$Map.reparent_Anchor(val)



#func MapOSM_update():
	#var http_request = HTTPRequest.new()
	#add_child(http_request)
	#http_request.request_completed.connect(self._http_request_completed)
	#
	#var error = http_request.request("https://a.tile.openstreetmap.fr/osmfr/" + str(zoom) + "/" + str(latlong_tile.x) + "/" + str(latlong_tile.y) + ".png?api=demo")
	#if error != OK:
		#push_error("An error occurred in the HTTP request.")

#func _http_request_completed(result, _response_code, _headers, body):
	#if result != HTTPRequest.RESULT_SUCCESS:
		#push_error("Image couldn't be downloaded. Try a different image.")
#
	#var image = Image.new()
	#var error = image.load_png_from_buffer(body)
	#if error != OK:
		#push_error("Couldn't load the image.")
	#$Map/Physical/Map/MapOSM.modulate = Color(1,1,1,1)
	#$Map/Physical/Map/MapOSM.texture = null
	#$Map/Physical/Map/MapOSM.texture = ImageTexture.create_from_image(image)
