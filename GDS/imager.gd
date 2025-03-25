extends Node2D

signal photo_starded
signal photo_finished

@export_enum("Image", "Sound") var WorkMode : int

const FORMAT : String = ".hex"
@export var IMAGE_FORMAT : String = ".png"

@export var Resolution : Vector2i = Vector2(640, 480)
@export var DefaultImagePath : String = "Output/Spit"
@export var TargetIndex : int = 3
@export var TargetSize = 614400

@onready var CurrentPath : String = DefaultImagePath + "0" + FORMAT
@onready var CurrentImagePath : String = DefaultImagePath + "0" + IMAGE_FORMAT
var CurrentIndex : int = -2
var LastMessageSize : int = 0
var CurrentRawSize : int = 0
var File : FileAccess

var save_Batch : Callable = func():
	return

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if WorkMode:
		save_Batch = save_Sound_Batch
		IMAGE_FORMAT = ".wav"
		$Label.text = "Sound download progress"
	else:
		save_Batch = save_Image_Batch
		IMAGE_FORMAT = ".png"
		$Label.text = "Photo download progress"
	CurrentImagePath = DefaultImagePath + "0" + IMAGE_FORMAT

func init_Photo() -> void:
	create_FileName()
	File = FileAccess.open(CurrentPath, FileAccess.WRITE)
	CurrentIndex = -1
	$ProgressBar.max_value = TargetIndex + 1
	Logger.add_Log("- Started downloading photo")


var counter : int = 1

func parse_Batch(code : PackedByteArray) -> void:
	if(code.size() == 0) :
		return
	
	var pal : StreamPeerBuffer = StreamPeerBuffer.new()
	pal.data_array = code
	pal.big_endian = true
	counter += 1
	
	#var ReverseCode : PackedByteArray = code.slice(0,8)
	#ReverseCode.reverse()
	#TargetIndex = ReverseCode.slice(6,8).decode_u16(0)
	#var index = ReverseCode.slice(4,6).decode_u16(0)
	#LastMessageSize = ReverseCode.slice(0,4).decode_u8(0)
	#var index_difference : int = index - CurrentIndex
	
	#TargetIndex = code.slice(0,2).decode_u16(0)
	#var index = code.slice(2,4).decode_u16(0)
	#LastMessageSize = code.slice(4,8).decode_u8(0)
	#var index_difference : int = index - CurrentIndex
	
	TargetIndex = pal.get_u16() - 1
	pal.seek(2)
	var index = pal.get_u16()
	pal.seek(4)
	LastMessageSize = pal.get_u32()
	pal.seek(8)
	
	if CurrentIndex == -2:
		init_Photo()
	
	var index_difference : int = index - CurrentIndex
	CurrentIndex = index
	
	if index_difference > 1:
		fill_Blank(index_difference - 1, LastMessageSize)
	elif index_difference < 0:
		fill_Blank(1, TargetSize - CurrentRawSize)
		save_Batch.call()
		CurrentIndex = -2
		CurrentRawSize = 0
		init_Photo()
		fill_Blank(index, LastMessageSize)
		CurrentIndex = index
	
	add_Batch(code.slice(8))
	CurrentRawSize += LastMessageSize * index_difference
	$ProgressBar.value = index + 1
	
	if index >= TargetIndex:
		print()
		save_Batch.call()
		reset_OpData()

func reset_OpData() -> void:
	CurrentIndex = -2
	CurrentRawSize = 0
	LastMessageSize = 0

func add_Batch(code : PackedByteArray) -> void:
	File.seek_end()
	File.store_buffer(code)

func save_Image_Batch() -> void:
	File.close()
	Logger.add_Log("- Photo is saving")
	OS.execute(
		"ffmpeg",
		[
		"-vcodec", "rawvideo",
		"-f", "rawvideo", 
		"-pix_fmt", "rgb565",
		"-s", str(Resolution.x) + "x" + str(Resolution.y),
		"-i", CurrentPath,
		"-f", "image2",
		"-vcodec", "png",
		CurrentImagePath
		 ], [], true, true)
	Logger.add_Log("- Image " + CurrentPath + " should be ready at the " + CurrentImagePath)

func fill_Blank(difference : int, size : int) -> void:
	var result : PackedByteArray = PackedByteArray()
	result.resize(difference * size)
	result.fill(0)
	add_Batch(result)

func save_Sound_Batch():
	File.close()
	Logger.add_Log("- Sound is saving")
	OS.execute(
		"ffmpeg",
		[
		"-f", "s16le", 
		"-ar", "32000",
		"-ac", "2",
		"-i", CurrentPath,
		CurrentImagePath
		 ], [], true, true)
	Logger.add_Log("- Sound " + CurrentPath + " should be ready at the " + CurrentImagePath)

func create_FileName() -> void:
	var is_name_free : bool = false
	var index_name : int = 0
	while !is_name_free:
		if not FileAccess.file_exists(DefaultImagePath + str(index_name) + FORMAT):
			is_name_free = true
			CurrentPath = DefaultImagePath + str(index_name) + FORMAT
			CurrentImagePath = DefaultImagePath + str(index_name) + IMAGE_FORMAT
		else:
			index_name += 1
