extends RefCounted
## Bounded project-authored craft surfaces. Cached geometry, deterministic, no gameplay RNG.
const Art=preload("res://scripts/phase4/art.gd")
static var cache: Dictionary={}
static var built:=0

static func pillow(size3: Vector3, depression: float=0.0) -> ArrayMesh:
	var key:="pillow"+str(size3)+str(depression)
	if cache.has(key):return cache[key]
	# A rounded rectangular pillow with a broad crown and shallow centre compression.
	# Normals are recomputed from the actual shape; no vertex animation is used at runtime.
	var source:=Art.rounded(size3,minf(size3.y*0.46,0.16))
	var arrays: Array=source.surface_get_arrays(0)
	var verts: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
	for i in range(verts.size()):
		var p:=verts[i]
		var crown:=maxf(0.0,1.0-pow(p.x/(size3.x*0.53),2))*maxf(0.0,1.0-pow(p.z/(size3.z*0.53),2))
		var top:=clampf(p.y/(size3.y*0.5),0,1)
		p.y+=top*(0.055*crown-depression*exp(-(p.x*p.x+p.z*p.z)/0.09))
		verts[i]=p
	arrays[Mesh.ARRAY_VERTEX]=verts
	var tool:=SurfaceTool.new();tool.create_from_arrays(arrays);tool.generate_normals();tool.index()
	var result:=tool.commit();cache[key]=result;built+=1;return result

static func cord(points: PackedVector3Array,radius: float=0.009,closed: bool=false) -> ArrayMesh:
	var key:="cord"+str(points)+str(radius)+str(closed)
	if cache.has(key):return cache[key]
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: Array[PackedVector3Array]=[];var ns: Array[PackedVector3Array]=[]
	for i in range(points.size()):
		var a:=points[(i-1+points.size())%points.size()] if closed else points[maxi(0,i-1)]
		var b:=points[(i+1)%points.size()] if closed else points[mini(points.size()-1,i+1)]
		var tangent:=(b-a).normalized()
		var helper:=Vector3.UP if absf(tangent.y)<0.85 else Vector3.RIGHT
		var u:=tangent.cross(helper).normalized();var v:=tangent.cross(u).normalized()
		var ring:=PackedVector3Array();var normal:=PackedVector3Array()
		for j in range(8):
			var n:=u*cos(TAU*j/8)+v*sin(TAU*j/8)
			ring.append(points[i]+n*radius);normal.append(n)
		rings.append(ring);ns.append(normal)
	for i in range(points.size() if closed else points.size()-1):
		var k:=(i+1)%points.size()
		for j in range(8):
			var l:=(j+1)%8
			for ij in [Vector2i(i,j),Vector2i(k,j),Vector2i(i,l),Vector2i(i,l),Vector2i(k,j),Vector2i(k,l)]:
				st.set_normal(ns[ij.x][ij.y]);st.set_uv(Vector2(float(ij.y)/8,float(ij.x)/points.size()));st.add_vertex(rings[ij.x][ij.y])
	var mesh:=st.commit();cache[key]=mesh;built+=1;return mesh

static func piping(width: float,depth: float,y: float) -> PackedVector3Array:
	var p:=PackedVector3Array();var r:=minf(0.10,minf(width,depth)*0.12)
	for center in [Vector2(width/2-r,depth/2-r),Vector2(-width/2+r,depth/2-r),Vector2(-width/2+r,-depth/2+r),Vector2(width/2-r,-depth/2+r)]:
		var corner: int=p.size()/7
		for j in range(7):
			var angle:=float(corner)*PI/2+float(j)/6*PI/2
			p.append(Vector3(center.x+cos(angle)*r,y,center.y+sin(angle)*r))
	return p

static func lathe(profile: PackedVector2Array,flutes: float=0.0) -> ArrayMesh:
	var key:="lathe"+str(profile)+str(flutes)
	if cache.has(key):return cache[key]
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in range(profile.size()-1):
		for side in range(48):
			var p: Array[Vector3]=[];var n: Array[Vector3]=[];var uv: Array[Vector2]=[]
			for ij in [Vector2i(row,side),Vector2i(row,side+1),Vector2i(row+1,side+1),Vector2i(row+1,side)]:
				var q:=profile[ij.x];var t: float=TAU*ij.y/48.0;var r:=q.x*(1+flutes*cos(t*16))
				var d:=profile[mini(profile.size()-1,ij.x+1)]-profile[maxi(0,ij.x-1)]
				p.append(Vector3(cos(t)*r,q.y,sin(t)*r));n.append(Vector3(cos(t)*d.y,-d.x,sin(t)*d.y).normalized());uv.append(Vector2(float(ij.y)/48,float(ij.x)/profile.size()))
			for index in [0,1,2,0,2,3]:st.set_normal(n[index]);st.set_uv(uv[index]);st.add_vertex(p[index])
	var mesh:=st.commit();cache[key]=mesh;built+=1;return mesh

static func drape(width: float,height: float) -> ArrayMesh:
	var key:="drape"+str(width)+str(height)
	if cache.has(key):return cache[key]
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for y in range(16):
		for x in range(32):
			for d in [Vector2(0,0),Vector2(1,1),Vector2(1,0),Vector2(0,0),Vector2(0,1),Vector2(1,1)]:
				var u: float=(x+d.x)/32;var v: float=(y+d.y)/16
				var amp: float=0.045+0.025*v
				var p:=Vector3((u-0.5)*width,-v*height,amp*cos(u*TAU*5)+0.035*sin(v*PI))
				st.set_uv(Vector2(u,v));st.add_vertex(p)
	st.generate_normals();var mesh:=st.commit();cache[key]=mesh;built+=1;return mesh
