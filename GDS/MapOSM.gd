extends Sprite3D

@export var MapSizePresets : Array[Rect2] = []

func _ready() -> void:
	region_rect = MapSizePresets[0]
	update_map()

func extend_by_preset(size : int) -> void:
	region_rect = MapSizePresets[size]

func extend_by_value(size : Rect2) -> void:
	region_rect = size

func update_map() -> void:
	texture = ImageTexture.create_from_image(Image.load_from_file("NewMap.png"))
	Logger.add_Log("- Map should be loaded")
	

func _on_timer_timeout() -> void:
	update_map()
