extends RefCounted
## Phase22 checkpoint: authored wetland dressing with bounded clue visuals and no gameplay collision changes.
const Art=preload("res://scripts/phase4/art.gd")
const RING_STEPS:=18
static var splashes: Array=[]
static var ripple_mesh: TorusMesh

static func audio() -> Array:
	if not splashes.is_empty():return splashes
	for variant in range(3):
		var bytes:=PackedByteArray();bytes.resize(8820)
		var rng:=RandomNumberGenerator.new();rng.seed=21200+variant
		var low:=0.0;var phase:=0.0
		for i in range(4410):
			var t:=float(i)/4409.0
			var noise:=rng.randf_range(-1,1);low=lerpf(low,noise,0.16)
			phase+=TAU*(620.0-380*t+variant*29)/22050
			var env:=sin(t*PI)*exp(-t*4.5)
			bytes.encode_s16(i*2,int((low*0.8+sin(phase)*0.18)*env*14000))
		var wav:=AudioStreamWAV.new();wav.format=AudioStreamWAV.FORMAT_16_BITS;wav.mix_rate=22050;wav.data=bytes
		splashes.append(wav)
	return splashes

static func no_shadow(n: MeshInstance3D) -> void:
	n.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	n.gi_mode=GeometryInstance3D.GI_MODE_DISABLED

static func wet_print(parent: Node3D) -> Node3D:
	var root:=Node3D.new();root.name="WaterPrint21";parent.add_child(root);root.visible=false
	if ripple_mesh==null:
		ripple_mesh=TorusMesh.new();ripple_mesh.inner_radius=0.14;ripple_mesh.outer_radius=0.165;ripple_mesh.rings=20;ripple_mesh.ring_segments=6
	for side in [-1,1]:
		var n:=MeshInstance3D.new();n.mesh=ripple_mesh;n.material_override=Art.material(Color("bee5df"),"foam")
		n.position=Vector3(side*0.15,0.074,side*0.055);n.scale=Vector3(0.8,0.4,1.2);root.add_child(n);no_shadow(n)
		var drop:=Art.ball(root,Vector3(side*0.15,0.073,side*0.055),Vector3(0.09,0.013,0.15),Color("428d96"),"ceramic");no_shadow(drop)
	return root

static func reed_print(parent: Node3D) -> Node3D:
	var root:=Node3D.new();root.name="ReedPrint21";parent.add_child(root);root.visible=false
	for i in range(3):
		var n:=Art.box(root,Vector3(-0.13+0.13*i,0.041,0.02*(i%2)),Vector3(0.043,0.016,0.34),Color("d9c791"),"wood",0.006)
		n.rotation.y=-0.45+0.35*i;no_shadow(n)
		n.set_meta("reed_rest",n.transform)
	return root

# Only the three clue meshes are fitted/attached. Their pooled parent and recorded
# event point stay unchanged, so investigation never reads a decorative position.
static func reset_reed_print(root: Node3D) -> void:
	for strand: MeshInstance3D in root.get_children():
		strand.transform=strand.get_meta("reed_rest")
		if strand.has_meta("reed_surface"):strand.remove_meta("reed_surface")
		if strand.has_meta("reed_anchor"):strand.remove_meta("reed_anchor")

# Clip an actual terrain triangle to the strand's rectangular footprint. The
# maximum is exact for the piecewise-planar mound, including seams and rims.
static func _clip_reed_footprint(polygon: Array[Vector3],axis: int,edge: float,keep_above: bool) -> Array[Vector3]:
	var result: Array[Vector3]=[]
	if polygon.is_empty():return result
	var previous: Vector3=polygon[-1]
	var previous_in: bool=previous[axis]>=edge if keep_above else previous[axis]<=edge
	for point in polygon:
		var inside: bool=point[axis]>=edge if keep_above else point[axis]<=edge
		if inside!=previous_in:result.append(previous.lerp(point,(edge-previous[axis])/(point[axis]-previous[axis])))
		if inside:result.append(point)
		previous=point;previous_in=inside
	return result

static func _reed_support(surface: MeshInstance3D,fitted: Transform3D,bounds: AABB) -> float:
	var local:=fitted.affine_inverse()*surface.global_transform
	var faces: PackedVector3Array=surface.get_meta("reed_clue_faces")
	var highest:=-INF
	for i in range(0,faces.size(),3):
		var polygon: Array[Vector3]=[local*faces[i],local*faces[i+1],local*faces[i+2]]
		for axis in [0,2]:
			polygon=_clip_reed_footprint(polygon,axis,bounds.position[axis],true)
			polygon=_clip_reed_footprint(polygon,axis,bounds.end[axis],false)
		for point in polygon:highest=maxf(highest,point.y)
	return highest

static func place_reed_print(root: Node3D,tufts: Array[Node3D]) -> void:
	reset_reed_print(root)
	for strand: MeshInstance3D in root.get_children():
		var rest: Transform3D=strand.get_meta("reed_rest")
		var at:=strand.global_position
		var highest: Dictionary={}
		for tuft in tufts:
			if not is_instance_valid(tuft):continue
			var surface: MeshInstance3D=tuft.get_meta("reed_clue_surface")
			var from:=surface.to_local(Vector3(at.x,surface.global_position.y+2.0,at.z))
			var to:=surface.to_local(Vector3(at.x,surface.global_position.y-2.0,at.z))
			var faces: PackedVector3Array=surface.get_meta("reed_clue_faces")
			for i in range(0,faces.size(),3):
				var hit=Geometry3D.segment_intersects_triangle(from,to,faces[i],faces[i+1],faces[i+2])
				if hit==null:continue
				var point:=surface.to_global(hit)
				if not highest.is_empty() and point.y<=highest.point.y:continue
				var normal:=surface.global_basis.inverse().transposed()*((faces[i+1]-faces[i]).cross(faces[i+2]-faces[i]))
				normal=normal.normalized()
				if normal.y<0:normal=-normal
				highest={"point":point,"normal":normal,"surface":surface}
		var fitted:=strand.global_transform
		var support: MeshInstance3D=null
		if not highest.is_empty():
			var normal: Vector3=highest.normal
			var forward:=strand.global_basis.z.slide(normal).normalized()
			var right:=normal.cross(forward).normalized()
			fitted=Transform3D(Basis(right,normal,right.cross(normal)),highest.point+normal*rest.origin.y)
			support=highest.surface
		var bounds:=strand.mesh.get_aabb()
		var clearance:=0.0
		# A rigid strand can cross several facets or bridge the rim. Check its
		# entire footprint instead of trusting the center's tangent plane alone.
		for tuft in tufts:
			if not is_instance_valid(tuft):continue
			var surface: MeshInstance3D=tuft.get_meta("reed_clue_surface")
			var world_bounds: AABB=surface.global_transform*surface.mesh.get_aabb()
			var strand_bounds: AABB=fitted*bounds
			if strand_bounds.end.x<world_bounds.position.x or strand_bounds.position.x>world_bounds.end.x or strand_bounds.end.z<world_bounds.position.z or strand_bounds.position.z>world_bounds.end.z:continue
			var height:=_reed_support(surface,fitted,bounds)
			if is_finite(height):
				if support==null:support=surface
				clearance=maxf(clearance,height-bounds.position.y+0.003)
		if support==null:continue # Bare ground retains the exact authored transform.
		# Preserve at least the authored floor clearance at every tilted corner.
		var floor_y:=root.global_position.y+rest.origin.y+bounds.position.y
		for corner in range(8):
			var bottom:=fitted*bounds.get_endpoint(corner)
			clearance=maxf(clearance,(floor_y-bottom.y)/fitted.basis.y.y)
		fitted.origin+=fitted.basis.y*clearance
		strand.global_transform=fitted
		strand.set_meta("reed_surface",support)
		strand.set_meta("reed_anchor",support.global_transform.affine_inverse()*fitted)

static func update_reed_print(root: Node3D) -> void:
	# Follow only the sampled decorative surface's existing sway, never an actor.
	for strand: MeshInstance3D in root.get_children():
		if not strand.has_meta("reed_surface"):continue
		var surface: MeshInstance3D=strand.get_meta("reed_surface")
		if not is_instance_valid(surface):continue
		var fitted: Transform3D=surface.global_transform*strand.get_meta("reed_anchor")
		var rest: Transform3D=strand.get_meta("reed_rest")
		var bounds:=strand.mesh.get_aabb()
		var floor_y:=root.global_position.y+rest.origin.y+bounds.position.y
		var lift:=0.0
		for corner in range(8):lift=maxf(lift,floor_y-(fitted*bounds.get_endpoint(corner)).y)
		fitted.origin.y+=lift
		strand.global_transform=fitted

static func _material_variant(color: Color,kind: String,scale_value: float,normal_scale: float=-1.0) -> StandardMaterial3D:
	var mat: StandardMaterial3D=Art.material(color,kind).duplicate()
	if mat.uv1_triplanar:mat.uv1_scale=Vector3.ONE*scale_value
	if normal_scale>=0.0 and mat.normal_enabled:mat.normal_scale=normal_scale
	return mat

static func _mesh_node(parent: Node3D,mesh: Mesh,color: Color,kind: String,scale_value: float,normal_scale: float=-1.0) -> MeshInstance3D:
	var node:=MeshInstance3D.new();node.mesh=mesh;node.material_override=_material_variant(color,kind,scale_value,normal_scale);parent.add_child(node)
	return node

static func _push_tri(st: SurfaceTool,a: Vector3,b: Vector3,c: Vector3,uv_scale: float=0.12) -> void:
	var normal: Vector3=(c-a).cross(b-a)
	if normal.length_squared()<0.000001:return
	normal=normal.normalized()
	st.set_normal(normal);st.set_uv(Vector2(a.x,a.z)*uv_scale);st.add_vertex(a)
	st.set_normal(normal);st.set_uv(Vector2(b.x,b.z)*uv_scale);st.add_vertex(b)
	st.set_normal(normal);st.set_uv(Vector2(c.x,c.z)*uv_scale);st.add_vertex(c)

static func _square_ring(half: Vector2,margin: Vector2,base_y: float,phase: float,relief: float=0.0) -> Array:
	var ring: Array=[]
	for i in range(RING_STEPS):
		var angle:=TAU*float(i)/float(RING_STEPS)
		var direction:=Vector2(cos(angle),sin(angle))
		var denom:=maxf(absf(direction.x),absf(direction.y))
		var square:=direction/denom
		var expand_x:=margin.x*(0.80+0.14*sin(angle*3.0+phase)+0.06*cos(angle*5.0-phase*0.4))
		var expand_z:=margin.y*(0.76+0.14*cos(angle*2.0+phase)+0.08*sin(angle*4.0-phase*0.5))
		expand_x=maxf(expand_x,margin.x*0.38)
		expand_z=maxf(expand_z,margin.y*0.38)
		var py:=base_y+relief*(0.5+0.25*sin(angle*2.0+phase)+0.25*cos(angle*3.0-phase*0.6))
		ring.append(Vector3(square.x*(half.x+expand_x),py,square.y*(half.y+expand_z)))
	return ring

static func _cap_center(ring: Array,flip: bool=false) -> Vector3:
	var center:=Vector3.ZERO
	for p in ring:center+=p
	center/=max(1,ring.size())
	if flip:center.y-=0.001
	return center

static func _closed_mass(rings: Array) -> ArrayMesh:
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var count: int=rings[0].size()
	for layer in range(rings.size()-1):
		var lower: Array=rings[layer]
		var upper: Array=rings[layer+1]
		for i in range(count):
			var j:=int((i+1)%count)
			_push_tri(st,lower[i],lower[j],upper[j])
			_push_tri(st,lower[i],upper[j],upper[i])
	var bottom: Array=rings[0]
	var bottom_center: Vector3=_cap_center(bottom,true)
	for i in range(count):
		var j:=int((i+1)%count)
		_push_tri(st,bottom_center,bottom[j],bottom[i])
	var top: Array=rings[rings.size()-1]
	var top_center: Vector3=_cap_center(top)
	for i in range(count):
		var j:=int((i+1)%count)
		_push_tri(st,top_center,top[i],top[j])
	return st.commit()

static func _reed_stem(parent: Node3D,pos: Vector3,height: float,yaw: float,pitch: float,thickness: float,color: Color,leaf_color: Color,has_head: bool) -> void:
	var mesh:=CylinderMesh.new();mesh.top_radius=thickness*0.45;mesh.bottom_radius=thickness;mesh.height=height;mesh.radial_segments=8
	var stem:=MeshInstance3D.new();stem.mesh=mesh;stem.material_override=Art.material(color,"wood")
	stem.position=pos+Vector3(0,height*0.5,0);stem.rotation=Vector3(pitch,yaw,0);parent.add_child(stem)
	for side in [-1,1]:
		var leaf:=Art.box(parent,pos+Vector3(side*0.05,height*0.56,0),Vector3(0.03,0.01,height*0.46),leaf_color,"foam",0.015)
		leaf.rotation=Vector3(deg_to_rad(-28.0+8.0*side),yaw,pitch+side*0.65)
	if has_head:
		var head:=Art.ball(parent,pos+Vector3(0,height+0.05,0),Vector3(0.08,0.18,0.08),Color("af8f60"),"foam")
		head.rotation.y=yaw

static func _reed_cluster(parent: Node3D,rng: RandomNumberGenerator,extent: Vector2,count: int,height_scale: float=1.0,cattails: float=0.35) -> void:
	for i in range(count):
		var angle:=rng.randf()*TAU
		var spread:=pow(rng.randf(),0.72)
		var pos:=Vector3(cos(angle)*extent.x*spread,0,sin(angle)*extent.y*spread)
		var height:=height_scale*rng.randf_range(0.55,1.16)
		var yaw:=rng.randf()*TAU
		var pitch:=rng.randf_range(-0.16,0.16)
		_reed_stem(parent,pos,height,yaw,pitch,rng.randf_range(0.018,0.026),Color("7f9361"),Color("a9bc76"),rng.randf()<cattails)

static func _water_patch(parent: Node3D,r: Rect2,index: int) -> void:
	var root:=Node3D.new();root.name="WaterArea%02d"%index;root.position=Vector3(r.get_center().x,0,r.get_center().y);parent.add_child(root)
	var size:=r.size
	# Low visual perimeter and open centre: the service-owned track remains visible.
	var shore:=Art.box(root,Vector3(0,0.018,0),Vector3(size.x+0.20,0.012,size.y+0.16),Color("758461"),"plaster",0.08)
	no_shadow(shore)
	var water:=Art.box(root,Vector3(0,0.040,0),Vector3(size.x-0.30,0.008,size.y-0.18),Color("6ba6ab"),"ceramic",1.0)
	no_shadow(water)
	var rng:=RandomNumberGenerator.new();rng.seed=4400+index
	for i in range(6):
		var pos:=Vector3(rng.randf_range(-size.x*0.32,size.x*0.32),0.043,rng.randf_range(-size.y*0.20,size.y*0.20))
		var lily:=Art.ball(root,pos,Vector3(0.13,0.006,0.15),Color("9ebf7d"),"foam")
		no_shadow(lily)
	for side in [-1,1]:
		var clump:=Node3D.new();clump.position=Vector3(side*(size.x*0.5+0.12),0.02,0);root.add_child(clump)
		_reed_cluster(clump,rng,Vector2(0.16,0.14),4,0.55,0.0)

static func _reactive_tuft(parent: Node3D,index: int) -> void:
	var rng:=RandomNumberGenerator.new();rng.seed=7800+index
	var mound:=_closed_mass([
		_square_ring(Vector2(0.38,0.34),Vector2(0.10,0.10),0.00,0.4+index),
		_square_ring(Vector2(0.26,0.24),Vector2(0.08,0.08),0.08,0.7+index),
		_square_ring(Vector2(0.14,0.12),Vector2(0.06,0.05),0.16,1.1+index,0.04)
	])
	var surface:=_mesh_node(parent,mound,Color("76845f"),"plaster",1.5,0.12)
	parent.set_meta("reed_clue_surface",surface)
	surface.set_meta("reed_clue_faces",mound.get_faces())
	for i in range(4):
		var rootlog:=Art.box(parent,Vector3(-0.18+0.12*i,0.10,-0.12+0.06*(i%2)),Vector3(0.24,0.08,0.10),Color("8c6b49"),"wood",0.035)
		rootlog.rotation.y=-0.45+0.28*i
	_reed_cluster(parent,rng,Vector2(0.40,0.64),13,1.0,0.42)
	for i in range(6):
		var pos:=Vector3(rng.randf_range(-0.36,0.36),0.18+rng.randf_range(0.0,0.18),rng.randf_range(-0.70,0.70))
		var sprig:=Art.ball(parent,pos,Vector3(0.08,0.12,0.08),Color("98b672"),"foam")
		sprig.rotation.y=rng.randf()*TAU

static func build(arena,water: Array,brush: Array) -> Array[Node3D]:
	var root: Node3D=arena.get_node_or_null("Wetland21Art")
	if root==null:
		root=Node3D.new();root.name="Wetland21Art";arena.add_child(root)
		for i in range(water.size()):_water_patch(root,water[i],i)
		for i in range(brush.size()):
			var r: Rect2=brush[i];var c: Vector2=r.get_center()
			var tuft:=Node3D.new();tuft.name="ReedTuft%02d"%i;tuft.position=Vector3(c.x,0,c.y);root.add_child(tuft)
			_reactive_tuft(tuft,i)
	var result: Array[Node3D]=[]
	for i in range(brush.size()):result.append(root.get_node("ReedTuft%02d"%i))
	return result
