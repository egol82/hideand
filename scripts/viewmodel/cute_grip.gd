extends "res://scripts/viewmodel/grip_rig.gd"
## Rounded toy paws, no individual finger loops. Real grip sockets and authority stay unchanged.
func _make_hand(parent: Node3D, radius: float, color: Color, left: bool = false) -> Node3D:
	var hand := Node3D.new()
	hand.name = "LeftGrip" if left else "RightGrip"
	parent.add_child(hand)
	var sign_x := -1.0 if left else 1.0
	Art.ball(hand,Vector3(sign_x*(radius+0.025),-0.010,0.012),Vector3(0.084,0.094,0.075),color).name = "RoundPaw"
	# Small rounded thumb reads as a grip without anatomical fingers or crease details.
	Art.ball(hand,Vector3(-sign_x*0.013,0.043,0.040),Vector3(0.039,0.040,0.038),color).name = "ThumbPad"
	Art.ball(hand,Vector3(sign_x*(radius+0.054),-0.085,0.019),Vector3(0.045,0.055,0.047),color).name = "WristPad"
	return hand
