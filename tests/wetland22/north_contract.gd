extends RefCounted
## Independently pinned approval: ONLY Cover_reed_north at (0,-7) changes shape.
## Do not import production profile points here: this is its numeric contract.
static func points() -> PackedVector3Array:
	var result:=PackedVector3Array()
	var layers: Array=[[1.0,0.0,Vector2.ZERO],[0.87,0.48,Vector2(0.06,-0.10)],[0.64,1.32,Vector2(-0.12,0.08)],[0.27,1.90,Vector2(-0.35,0.18)]]
	for layer in layers:
		for i in range(16):
			var angle: float=TAU*float(i)/16.0
			var radius: float=0.96+0.04*cos(3.0*angle+0.4)
			var p:=Vector2(3.5*cos(angle)*radius,3.0*sin(angle)*radius)*float(layer[0])+Vector2(layer[2])
			result.append(Vector3(p.x,float(layer[1]),p.y))
	return result
static func collision(helpers) -> Array:
	return [Transform3D(Basis.IDENTITY,Vector3(0,0,-7)),"ConvexPolygonShape3D",helpers.normalized_vertices(points())]
