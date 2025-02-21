extends Node3D


func reparent_Anchor(val : int):
	if val == 0:
		%Anchor.reparent($Physical/CenterAnchor)
	else:
		%Anchor.reparent($Physical/CanSat)
