extends RefCounted
## Original low-cost toy VFX geometry. No image assets, fonts or collision objects.
static var cache: Dictionary = {}

static func star() -> ArrayMesh:
	if cache.has("star"): return cache.star
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for face in [-1.0,1.0]:
		for i in range(10):
			var a := TAU*i/10-PI*0.5; var b := TAU*(i+1)/10-PI*0.5
			var p := Vector3(cos(a),sin(a),0)*(0.50 if i%2==0 else 0.23)
			var q := Vector3(cos(b),sin(b),0)*(0.50 if (i+1)%2==0 else 0.23)
			for v in [Vector3.ZERO,p,q]:
				st.set_normal(Vector3(0,0,face)); st.add_vertex(v+Vector3(0,0,face*0.06))
			for v in [p+Vector3(0,0,-0.06),q+Vector3(0,0,-0.06),q+Vector3(0,0,0.06),p+Vector3(0,0,-0.06),q+Vector3(0,0,0.06),p+Vector3(0,0,0.06)]:
				st.set_normal((p+q).normalized()); st.add_vertex(v)
	cache.star = st.commit(); return cache.star

static func ring() -> ArrayMesh:
	if cache.has("ring"): return cache.ring
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(48):
		var a := TAU*i/48; var b := TAU*(i+1)/48
		var p := Vector3(cos(a),sin(a),0); var q := Vector3(cos(b),sin(b),0)
		for v in [p*0.44,p*0.50,q*0.50,p*0.44,q*0.50,q*0.44]:
			st.set_normal(Vector3.BACK); st.add_vertex(v)
	cache.ring = st.commit(); return cache.ring

static func spiral() -> ArrayMesh:
	if cache.has("spiral"): return cache.spiral
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(48):
		var a := float(i)/48; var b := float(i+1)/48
		var p := Vector3(cos(a*TAU*2.2),sin(a*TAU*2.2),0)
		var q := Vector3(cos(b*TAU*2.2),sin(b*TAU*2.2),0)
		for v in [p*(0.06+a*0.42-0.038),p*(0.06+a*0.42+0.038),q*(0.06+b*0.42+0.038),p*(0.06+a*0.42-0.038),q*(0.06+b*0.42+0.038),q*(0.06+b*0.42-0.038)]:
			st.set_normal(Vector3.BACK); st.add_vertex(v)
	cache.spiral = st.commit(); return cache.spiral

static func material(color: Color, vertex: bool = false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color; m.vertex_color_use_as_albedo = vertex
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m

static func item(parent: Node3D, mesh: Mesh, at: Vector3, size3: Vector3, color: Color) -> MeshInstance3D:
	var n := MeshInstance3D.new(); n.mesh = mesh; n.position = at; n.scale = size3
	n.material_override = material(color); n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(n); return n
