extends RefCounted
## Project-authored smooth implicit toy surface. One indexed manifold body, four skin weights.
## Offline baking is preferred. The same deterministic builder is a bounded fallback, cached once.
const VERSION := 1
const STEP := 0.050
const ORIGIN := Vector3(-0.90,-0.05,-0.55)
const DIMS := Vector3i(37,42,23)
const TETS := [[0,5,1,6],[0,1,2,6],[0,2,3,6],[0,3,7,6],[0,7,4,6],[0,4,5,6]]
const CORNERS := [Vector3i(0,0,0),Vector3i(1,0,0),Vector3i(1,1,0),Vector3i(0,1,0),Vector3i(0,0,1),Vector3i(1,0,1),Vector3i(1,1,1),Vector3i(0,1,1)]
const NAMES := ["pelvis","spine","neck","head","upper_arm_L","lower_arm_L","hand_L","upper_arm_R","lower_arm_R","hand_R","thigh_L","shin_L","foot_L","thigh_R","shin_R","foot_R","ear_L","ear_R"]
const PARENTS := [-1,0,1,2,1,4,5,1,7,8,0,10,11,0,13,14,3,3]
const JOINTS := [Vector3(0,0.58,0),Vector3(0,0.92,0),Vector3(0,1.12,0),Vector3(0,1.37,0.015),Vector3(-0.33,1.00,0),Vector3(-0.52,0.82,0.02),Vector3(-0.59,0.63,0.08),Vector3(0.33,1.00,0),Vector3(0.52,0.82,0.02),Vector3(0.59,0.63,0.08),Vector3(-0.17,0.51,0),Vector3(-0.21,0.30,0.02),Vector3(-0.23,0.16,0.09),Vector3(0.17,0.51,0),Vector3(0.21,0.30,0.02),Vector3(0.23,0.16,0.09),Vector3(-0.29,1.70,0),Vector3(0.29,1.70,0)]
static var cached: ArrayMesh
var lattice := PackedVector3Array()
var values := PackedFloat32Array()
var vertices := PackedVector3Array()
var normals := PackedVector3Array()
var indices := PackedInt32Array()
var edges: Dictionary = {}
var welded: Dictionary = {}

static func ellipse(p: Vector3, c: Vector3, r: Vector3) -> float:
	var q := p-c
	var k0 := (q/r).length()
	var k1 := (q/(r*r)).length()
	return k0*(k0-1.0)/k1 if k1>0.00001 else -minf(r.x,minf(r.y,r.z))
static func capsule(p: Vector3,a: Vector3,b: Vector3,r: float) -> float:
	return p.distance_to(a+(b-a)*clampf((p-a).dot(b-a)/(b-a).length_squared(),0,1))-r
static func blend(a: float,b: float,k: float) -> float:
	var h := clampf(0.5+0.5*(b-a)/k,0,1)
	return lerpf(b,a,h)-k*h*(1-h)
static func field(p: Vector3) -> float:
	var d := ellipse(p,Vector3(0,0.70,0),Vector3(0.38,0.44,0.285))
	d=blend(d,ellipse(p,Vector3(0,1.37,0.015),Vector3(0.505,0.44,0.375)),0.23)
	for sign_value in [-1.0,1.0]:
		d=blend(d,ellipse(p,Vector3(sign_value*0.29,1.77,0.0),Vector3(0.135,0.20,0.13)),0.105)
		d=blend(d,capsule(p,Vector3(sign_value*0.31,1.00,0),Vector3(sign_value*0.52,0.82,0.02),0.125),0.12)
		d=blend(d,capsule(p,Vector3(sign_value*0.52,0.82,0.02),Vector3(sign_value*0.59,0.64,0.08),0.116),0.08)
		d=blend(d,ellipse(p,Vector3(sign_value*0.59,0.615,0.10),Vector3(0.148,0.165,0.15)),0.09)
		d=blend(d,ellipse(p,Vector3(sign_value*0.49,0.635,0.195),Vector3(0.072,0.084,0.077)),0.055)
		d=blend(d,capsule(p,Vector3(sign_value*0.17,0.49,0),Vector3(sign_value*0.22,0.24,0.025),0.133),0.095)
		d=blend(d,ellipse(p,Vector3(sign_value*0.23,0.16,0.10),Vector3(0.174,0.148,0.23)),0.07)
	return d
static func gradient(p: Vector3) -> Vector3:
	var e:=0.001
	return Vector3(field(p+Vector3(e,0,0))-field(p-Vector3(e,0,0)),field(p+Vector3(0,e,0))-field(p-Vector3(0,e,0)),field(p+Vector3(0,0,e))-field(p-Vector3(0,0,e))).normalized()
static func front(x: float,y: float) -> float:
	var low:=0.0; var high:=0.6
	for i in range(18):
		var mid: float=(low+high)*0.5
		if field(Vector3(x,y,mid))<0: low=mid
		else: high=mid
	return (low+high)*0.5
static func weights(p: Vector3) -> Array:
	var w:=PackedFloat32Array();w.resize(NAMES.size());w.fill(0)
	var ax:=absf(p.x)
	var arm:=smoothstep(0.29,0.47,ax)*(1-smoothstep(1.02,1.17,p.y))*smoothstep(0.25,0.39,p.y)
	var leg: float=(1-smoothstep(0.42,0.60,p.y))*smoothstep(0.02,0.13,ax)*(1-smoothstep(0.32,0.43,ax))
	var ear:=smoothstep(1.64,1.82,p.y)*smoothstep(0.10,0.23,ax)
	var rest: float=maxf(0,1-arm-leg-ear)
	var head:=smoothstep(1.02,1.29,p.y)
	var spine:=smoothstep(0.51,0.98,p.y)
	w[3]=rest*head;w[1]=rest*(1-head)*spine;w[0]=rest*(1-head)*(1-spine)
	var a:=4 if p.x<0 else 7
	var palm: float=1-smoothstep(0.75,0.84,p.y)
	var upper:=smoothstep(0.89,0.995,p.y)
	w[a]=arm*(1-palm)*upper;w[a+1]=arm*(1-palm)*(1-upper);w[a+2]=arm*palm
	var l:=10 if p.x<0 else 13
	var foot: float=1-smoothstep(0.20,0.31,p.y)
	var thigh:=smoothstep(0.33,0.49,p.y)
	w[l]=leg*(1-foot)*thigh;w[l+1]=leg*(1-foot)*(1-thigh);w[l+2]=leg*foot
	w[16 if p.x<0 else 17]=ear
	var order: Array[int]=[]
	for i in range(w.size()): order.append(i)
	order.sort_custom(func(a0: int,b0: int): return w[a0]>w[b0] if w[a0]!=w[b0] else a0<b0)
	var bone:=PackedInt32Array();var amounts:=PackedFloat32Array();var total:=0.0
	for i in range(4): bone.append(order[i]);amounts.append(w[order[i]]);total+=w[order[i]]
	if total<=0: amounts[0]=1.0;total=1.0
	for i in range(4):amounts[i]/=total
	return [bone,amounts]
static func mesh() -> ArrayMesh:
	if cached!=null:return cached
	var builder=load("res://scripts/character13/mesh_builder.gd").new()
	cached=builder.generate()
	return cached
func id_at(x: int,y: int,z: int) -> int:
	return x+DIMS.x*(y+DIMS.y*z)
func edge(a: int,b: int) -> int:
	var key:=Vector2i(mini(a,b),maxi(a,b))
	if edges.has(key):return edges[key]
	var t:=clampf(values[a]/(values[a]-values[b]),0,1)
	var p:=lattice[a].lerp(lattice[b],t)
	# Project interpolation vertices to the analytic skin, reducing small voxel facets.
	for iteration in range(2):p-=gradient(p)*field(p)
	var cell:=Vector3i((p*100000.0).round())
	if welded.has(cell):edges[key]=welded[cell];return welded[cell]
	var result:=vertices.size();vertices.append(p);normals.append(gradient(p));edges[key]=result;welded[cell]=result
	return result
func triangle(a: int,b: int,c: int) -> void:
	# Godot front faces wind clockwise. Normal data is the outward field gradient.
	var cross: Vector3=(vertices[b]-vertices[a]).cross(vertices[c]-vertices[a])
	if cross.length_squared()<0.000000000000000001:return
	if cross.dot(normals[a]+normals[b]+normals[c])>0:indices.append_array(PackedInt32Array([a,c,b]))
	else:indices.append_array(PackedInt32Array([a,b,c]))
func tetra(ids: Array[int]) -> void:
	var inside: Array[int]=[];var outside: Array[int]=[]
	for id in ids:
		if values[id]<0:inside.append(id)
		else:outside.append(id)
	if inside.is_empty() or outside.is_empty():return
	if inside.size()==1 or outside.size()==1:
		var one: Array[int]=inside if inside.size()==1 else outside
		var three: Array[int]=outside if inside.size()==1 else inside
		triangle(edge(one[0],three[0]),edge(one[0],three[1]),edge(one[0],three[2]))
	else:
		var a:=edge(inside[0],outside[0]);var b:=edge(inside[0],outside[1])
		var c:=edge(inside[1],outside[0]);var d:=edge(inside[1],outside[1])
		triangle(a,b,c);triangle(b,d,c)
func generate() -> ArrayMesh:
	for z in range(DIMS.z):
		for y in range(DIMS.y):
			for x in range(DIMS.x):
				var p:=ORIGIN+Vector3(x,y,z)*STEP;lattice.append(p);values.append(field(p))
	for z in range(DIMS.z-1):
		for y in range(DIMS.y-1):
			for x in range(DIMS.x-1):
				var cube: Array[int]=[];var negative:=0
				for c in CORNERS:
					var id:=id_at(x+c.x,y+c.y,z+c.z);cube.append(id)
					if values[id]<0:negative+=1
				if negative==0 or negative==8:continue
				for t in TETS:tetra([cube[t[0]],cube[t[1]],cube[t[2]],cube[t[3]]])
	var bones:=PackedInt32Array();var amounts:=PackedFloat32Array();var uv:=PackedVector2Array()
	for p in vertices:
		var w:=weights(p);bones.append_array(w[0]);amounts.append_array(w[1])
		uv.append(Vector2(p.x/1.82+0.5,p.y/2.1))
	var arrays:=[];arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices;arrays[Mesh.ARRAY_NORMAL]=normals;arrays[Mesh.ARRAY_TEX_UV]=uv
	arrays[Mesh.ARRAY_INDEX]=indices;arrays[Mesh.ARRAY_BONES]=bones;arrays[Mesh.ARRAY_WEIGHTS]=amounts
	var result:=ArrayMesh.new();result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	result.resource_name="Buddy13_Connected_Skinned_Body"
	result.set_meta("builder_version",VERSION);result.set_meta("vertices",vertices.size());result.set_meta("triangles",indices.size()/3)
	return result
