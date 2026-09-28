extends RefCounted
## Indexed reusable bevel geometry. Mesh axes stay within the requested dimensions.
static var cache: Dictionary = {}
static func rounded(size: Vector3, radius: float=0.10) -> ArrayMesh:
	var key := str(size)+str(radius)
	if cache.has(key): return cache[key]
	var r := minf(radius,minf(size.x,minf(size.y,size.z))*0.46)
	var half := size*0.5; var inner:=half-Vector3.ONE*r
	var st:=SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var coordinates := [0.0,0.18,0.35,0.50,0.65,0.82,1.0]
	for axis in range(3):
		for sign_value in [-1.0,1.0]:
			var a: int=(axis+1)%3; var b: int=(axis+2)%3
			for i in range(6):
				for j in range(6):
					var pos: Array[Vector3]=[]; var norms: Array[Vector3]=[]; var uv: Array[Vector2]=[]
					for corner in [Vector2i(0,0),Vector2i(1,0),Vector2i(1,1),Vector2i(0,1)]:
						var tex:=Vector2(coordinates[i+corner.x],coordinates[j+corner.y])
						var p:=Vector3.ZERO; p[axis]=half[axis]*sign_value
						p[a]=coord(tex.x,half[a],r); p[b]=coord(tex.y,half[b],r)
						var core:=p.clamp(-inner,inner); var n:=(p-core).normalized()
						pos.append(core+n*r); norms.append(n); uv.append(tex)
					for k in ([0,2,1,0,3,2] if sign_value>0 else [0,1,2,0,2,3]):
						st.set_normal(norms[k]); st.set_uv(uv[k]); st.add_vertex(pos[k])
	st.index(); st.generate_tangents()
	var mesh:=st.commit(); cache[key]=mesh
	return mesh
static func coord(t: float,h: float,r: float) -> float:
	if t<=0.35: return lerpf(-h,-h+r,t/0.35)
	if t>=0.65: return lerpf(h-r,h,(t-0.65)/0.35)
	return lerpf(-h+r,h-r,(t-0.35)/0.30)
