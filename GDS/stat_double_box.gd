extends Node2D

@export var MSource: ModSource = null
@export var VSource: StResource = null
@export var Name : String = ""
@export var UnitName : String = ""



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Title.text = Name + " (" + UnitName + ")"
	$Value.text = VSource.Values[Name]


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func update():
	$Title.text = VSource.Title
	$Value.text = VSource.Value

func Xupdate(value:String):
	$Value.text = value
