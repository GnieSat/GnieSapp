extends SubViewport

# Called when the node enters the scene tree for the first time.
@export var zoom : int = 16
@onready var n : int = pow(2, zoom)

var latlong_tile = Vector2(0, 0)
var longtitude : String = ""
var latitude : String = ""

func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func calc_long(val : float) -> int:
	val = 0.5 + val / 360
	return val * n

func calc_lat(val : float) -> int:
	print(arsinh(tan(val)))
	val = arsinh(tan(val))
	val = 0.5 - val / (2 * PI)
	return val * n

func arsinh(val) -> float:
	return log(val + sqrt(pow(val, 2) + 2))






func _on_stat_panel_map_update(data: Dictionary) -> void:
	$Map/Physical/CanSat.global_position = Vector3i(float(data["Lat"])/100000000.0, float(data["Height"])/10000.0, float(data["Long"])/100000000.0)


func _on_base_gps_long_update(val: String) -> void:
	longtitude = val

func _on_base_gps_lat_update(val: String) -> void:
	latitude = val

func _on_base_gps_map_update() -> void:
	OS.execute("R:/Programy/Pliki Programów/Python/python", ["W:/kitus/Documents/GitHub/GnieSapp/Scripts/EEmap.py", longtitude, latitude], [], true, true)
	

func MapEE_update():
	$Map/Physical/Map/MapOSM.modulate = Color(1,1,1,1)
	$Map/Physical/Map/MapOSM.texture = null
	$Map/Physical/Map/MapOSM.texture = load("res://Scripts/NewMap.png")

func MapOSM_update():
	print(latlong_tile)
	
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(self._http_request_completed)
	
	var error = http_request.request("https://a.tile.openstreetmap.fr/osmfr/" + str(zoom) + "/" + str(latlong_tile.x) + "/" + str(latlong_tile.y) + ".png?api=demo")
	if error != OK:
		push_error("An error occurred in the HTTP request.")

func _http_request_completed(result, response_code, headers, body):
	if result != HTTPRequest.RESULT_SUCCESS:
		push_error("Image couldn't be downloaded. Try a different image.")

	var image = Image.new()
	var error = image.load_png_from_buffer(body)
	if error != OK:
		push_error("Couldn't load the image.")
	$Map/Physical/Map/MapOSM.modulate = Color(1,1,1,1)
	$Map/Physical/Map/MapOSM.texture = null
	$Map/Physical/Map/MapOSM.texture = ImageTexture.create_from_image(image)
