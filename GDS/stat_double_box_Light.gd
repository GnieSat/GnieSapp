extends "res://GDS/stat_double_box.gd"

func XXupdate(r : String, g : String, b : String, clear : String, ir : String,):
	$R.text = "R: " + str(r)
	$G.text = "G: " + str(g)
	$B.text = "B: " + str(b)
	$Clear.text = "Clear: " + clear
	$IR.text = "IR: " + ir
	
	$StatBlock2.self_modulate = Color(translate_color(int(r)), translate_color(int(g)), translate_color(int(b)))

func translate_color(val : int) -> float:
	return float(val/65535.0)
