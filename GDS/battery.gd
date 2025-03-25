extends Button

@export var VoltCurve : Curve = null

func refresh(data : Dictionary) -> void:
	Xrefresh(data["Battery1"], data["Battery2"])

func Xrefresh(val1 : float, val2: float) -> void:
	
	var val2true = val2 - val1
	$Bat1Name.text = "1: " + "%0.2f" % val1
	$Bat2Name.text = "2: " + "%0.2f" % val2true
	$Bat1.value = VoltCurve.sample((val1 - 3.0) / 1.2)
	$Bat2.value = VoltCurve.sample((val2true - 3.0) / 1.2)
