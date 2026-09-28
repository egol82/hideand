extends RefCounted
## Small project-authored swept surfaces for fingers/sleeves. Built on equip, not every frame.
const Art = preload("res://scripts/phase4/art.gd")
const SIDES := 16

static func tube(points: PackedVector3Array, radii: PackedFloat32Array, rounded_caps: bool = true) -> ArrayMesh:
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: Array = []; var normals: Array = []
	for i in range(points.size()):
		var tangent := points[mini(i+1,points.size()-1)]-points[maxi(0,i-1)]
		if tangent.length_squared() < 0.0000001: tangent = Vector3.UP
		tangent = tangent.normalized()
		var helper := Vector3.UP if absf(tangent.y) < 0.90 else Vector3.RIGHT
		var u := tangent.cross(helper).normalized(); var v := tangent.cross(u).normalized()
		var ring := PackedVector3Array(); var ns := PackedVector3Array()
		for j in range(SIDES):
			var theta := TAU*float(j)/SIDES
			var normal := u*cos(theta)+v*sin(theta)
			ring.append(points[i]+normal*radii[i]); ns.append(normal)
		rings.append(ring); normals.append(ns)
	for i in range(points.size()-1):
		for j in range(SIDES):
			var k := (j+1)%SIDES
			var vertices := [rings[i][j],rings[i+1][j],rings[i][k],rings[i][k],rings[i+1][j],rings[i+1][k]]
			var ns := [normals[i][j],normals[i+1][j],normals[i][k],normals[i][k],normals[i+1][j],normals[i+1][k]]
			for q in range(6):
				st.set_normal(ns[q]); st.set_uv(Vector2(float(j)/SIDES,float(i)/points.size())); st.add_vertex(vertices[q])
	for endpoint in [0,points.size()-1]:
		var direction := (points[endpoint]-points[1 if endpoint==0 else endpoint-1]).normalized()
		if rounded_caps:
			_cap(st,points[endpoint],direction,radii[endpoint])
		else:
			for j in range(SIDES):
				for point in [points[endpoint],rings[endpoint][j],rings[endpoint][(j+1)%SIDES]]:
					st.set_normal(direction); st.set_uv(Vector2.ZERO); st.add_vertex(point)
	return st.commit()

static func _cap(st: SurfaceTool, center: Vector3, outward: Vector3, radius: float) -> void:
	var helper := Vector3.UP if absf(outward.y) < 0.9 else Vector3.RIGHT
	var u := outward.cross(helper).normalized(); var v := outward.cross(u).normalized()
	for band in range(4):
		var a := PI*0.5*band/4.0; var b := PI*0.5*(band+1)/4.0
		for j in range(SIDES):
			var t := TAU*j/SIDES; var n := TAU*(j+1)/SIDES
			var r0 := u*cos(t)+v*sin(t); var r1 := u*cos(n)+v*sin(n)
			var ns := [outward*sin(a)+r0*cos(a),outward*sin(b)+r0*cos(b),outward*sin(a)+r1*cos(a),outward*sin(b)+r1*cos(b)]
			for k in [0,1,2,2,1,3]:
				st.set_normal(ns[k]); st.set_uv(Vector2.ZERO); st.add_vertex(center+ns[k]*radius)

static func instance(parent: Node3D, mesh: Mesh, name_value: String, color: Color, kind: String = "vinyl") -> MeshInstance3D:
	var n := MeshInstance3D.new(); n.name = name_value; n.mesh = mesh
	var mat := Art.material(color,kind).duplicate() as StandardMaterial3D
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.disable_receive_shadows = true
	n.material_override = mat
	n.set_meta("view_shaded",true)
	parent.add_child(n); return n

static func curled_hand(parent: Node3D, radius: float, tint: Color, left: bool = false) -> Node3D:
	var hand := Node3D.new(); hand.name = "LeftGrip" if left else "RightGrip"; parent.add_child(hand)
	var sign_x := -1.0 if left else 1.0
	# A broad palm with a narrow wrist; its near side overlaps finger roots, not the shaft.
	Art.ball(hand,Vector3(sign_x*(radius+0.049),-0.007,-0.009),Vector3(0.056,0.083,0.054),tint).name = "Palm"
	Art.ball(hand,Vector3(sign_x*(radius+0.069),-0.082,0.019),Vector3(0.041,0.064,0.046),tint).name = "Heel"
	for finger in range(4):
		var points := PackedVector3Array(); var widths := PackedFloat32Array()
		var y := 0.052-finger*0.035
		var thickness: float = [0.019,0.020,0.019,0.017][finger]
		var r: float = radius+thickness*0.86
		for step in range(23):
			var t := float(step)/22
			var angle := lerpf(-0.62,3.72,t)
			points.append(Vector3(sign_x*cos(angle)*r,y-0.007*sin(t*PI),sin(angle)*r))
			widths.append(thickness*(0.93+0.07*sin(t*PI)))
		instance(hand,tube(points,widths),"Finger%d"%finger,tint)
	# Opposing thumb crosses diagonally over the top finger rather than pointing out like an ear.
	var thumb := PackedVector3Array(); var radii := PackedFloat32Array()
	var a := Vector3(sign_x*(radius+0.078),0.055,0.012)
	var b := Vector3(sign_x*(radius+0.045),0.088,0.074)
	var c := Vector3(sign_x*(-radius*0.35),0.030,0.057)
	for i in range(17):
		var t := float(i)/16
		thumb.append(a*(1-t)*(1-t)+b*2*t*(1-t)+c*t*t)
		radii.append(lerpf(0.028,0.020,t))
	instance(hand,tube(thumb,radii),"Thumb",tint)
	return hand

static func sleeve(parent: Node3D, name_value: String) -> MeshInstance3D:
	var points := PackedVector3Array(); var radii := PackedFloat32Array()
	for i in range(13):
		var t := float(i)/12
		points.append(Vector3(0,t,0))
		radii.append(lerpf(0.045,0.073,t)*(1.0+0.025*sin(t*PI*6)))
	return instance(parent,tube(points,radii,false),name_value,Color("ede3ce"),"fabric")

static func link(node: Node3D, from: Vector3, to: Vector3) -> void:
	var delta := to-from
	var length_value := maxf(0.001,delta.length())
	var y := delta/length_value
	var helper := Vector3.FORWARD if absf(y.z) < 0.95 else Vector3.RIGHT
	var x := y.cross(helper).normalized(); var z := x.cross(y).normalized()
	node.transform = Transform3D(Basis(x,y*length_value,z),from)
