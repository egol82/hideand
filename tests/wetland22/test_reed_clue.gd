extends SceneTree
## Actual rendered mound triangles, original clue state, and all pooled reuse paths.
const Scene=preload("res://scenes/phase21.tscn")
const Ready=preload("res://tests/seed21/round_ready.gd")
var game
var checks:=0
var failures:=0
var records:Array=[]
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label:String) -> void:
	checks+=1
	if not ok:failures+=1
	print(("PASS: " if ok else "FAIL: ")+label)
# Independent vertical projection: barycentric XZ coordinates from render arrays,
# without using the production segment-intersection or stored attachment metadata.
func height_at(mesh:MeshInstance3D,p:Vector3) -> float:
	var faces:=mesh.mesh.get_faces();var result:=-INF
	for i in range(0,faces.size(),3):
		var a:=mesh.to_global(faces[i]);var b:=mesh.to_global(faces[i+1]);var c:=mesh.to_global(faces[i+2])
		var v0:=Vector2(b.x-a.x,b.z-a.z);var v1:=Vector2(c.x-a.x,c.z-a.z);var v2:=Vector2(p.x-a.x,p.z-a.z)
		var det:=v0.cross(v1)
		if absf(det)<0.0000001:continue
		var u:=v2.cross(v1)/det;var v:=v0.cross(v2)/det
		if u>=-0.00001 and v>=-0.00001 and u+v<=1.00001:result=maxf(result,a.y+u*(b.y-a.y)+v*(c.y-a.y))
	return result
func clearance_ok(visual:Node3D,surface:MeshInstance3D,floor_y:float) -> bool:
	for strand:MeshInstance3D in visual.get_children():
		var bounds:=strand.mesh.get_aabb()
		for ix in range(3):
			for iz in range(5):
				var local:=Vector3(lerpf(bounds.position.x,bounds.end.x,ix/2.0),bounds.position.y,lerpf(bounds.position.z,bounds.end.z,iz/4.0))
				var point:=strand.to_global(local)
				if point.y<floor_y-0.0001 or point.y<height_at(surface,point)-0.0001:return false
	return true
func restored(visual:Node3D) -> bool:
	for n:MeshInstance3D in visual.get_children():
		if n.transform!=n.get_meta("reed_rest") or n.has_meta("reed_surface") or n.has_meta("reed_anchor"):return false
	return true
func fresh(map_id:String="reedwater_bend") -> void:
	game.return_to_menu();game.select_map(map_id);game.set_mode("field")
	await process_frame;await physics_frame
	game.rng.seed=8027;game.start_match(true);await Ready.wait(game)
	game.accept_drawing();game.rules.tick(game.rules.hiding_seconds+0.01)
	for i in range(4):game.fighters[i].reset_fight(Vector3(-18+i*1.4,0,14))
	await Ready.positions(game)
func run() -> void:
	game=Scene.instantiate();root.add_child(game);game.automated=true
	await process_frame;await process_frame;await physics_frame
	game.set_process(false);game.get_node("ToyStudio").set_process(false)
	await fresh()
	var h=game.hiding
	game.preferences.reduced_motion=true
	var count:=0
	for tuft:Node3D in h.tufts:
		var surface:MeshInstance3D=tuft.get_child(0)
		for offset in [Vector3.ZERO,Vector3(0.18,0,0.10),Vector3(-0.18,0,-0.10),Vector3(0.65,0,0),Vector3(0,0,0.85),Vector3(-0.1,0,0.4),Vector3(0.45,0,0.3),Vector3(-0.3,0,-0.4),Vector3(0.4,0,0.1)]:
			for yaw in [0.0,1.1,2.4]:
				var p:Vector3=tuft.position+offset;p.y=-0.024
				game.fighters[1].visual.rotation.y=yaw
				var slot:int=h.track_cursor;var clock:float=h.elapsed;var sounds:int=h.sounds.size()
				h.make_track(p,1,"reed21")
				var t:Dictionary=h.tracks[slot];var visual:Node3D=h.reed_visuals[slot]
				var fit:=true;var lifted:=0;var bare:=0
				for n:MeshInstance3D in visual.get_children():
					var rest:Transform3D=n.get_meta("reed_rest")
					var original:Vector3=visual.to_global(rest.origin)
					var y:=height_at(surface,original)
					if is_finite(y):
						lifted+=1
						var delta:=n.global_position-Vector3(original.x,y,original.z)
						fit=fit and delta.cross(n.global_basis.y).length()<0.0001 and delta.dot(n.global_basis.y)>=rest.origin.y-0.0001 and n.global_basis.y.y>0.5
					else:
						bare+=1
						fit=fit and n.basis.is_equal_approx(rest.basis) and n.position.y>=rest.origin.y
					for corner in range(8):fit=fit and (n.global_transform*n.mesh.get_aabb().get_endpoint(corner)).y>=p.y+0.033-0.0001
				check(fit and clearance_ok(visual,surface,p.y+0.033) and t.at==p and t.node.position==p and t.time==clock and t.source==1 and t.kind=="reed21" and h.sounds.size()==sounds,"actual mound fit and fixed authority fixture %d"%count)
				records.append({"fixture":count,"lifted":lifted,"bare":bare,"event":str(p),"yaw":yaw});count+=1
	check(count==108,"all four mounds, inside/outside/rim points and three headings are covered")
	h.track_cursor=0;h.make_track(Vector3(4.9,-0.024,-7.0),1,"reed21")
	h.WetArt.reset_reed_print(h.reed_visuals[0])
	check(not clearance_ok(h.reed_visuals[0],h.tufts[0].get_child(0),0.009),"negative control rejects the original buried clue at the same mound")
	# A real movement sample retains the original single-track/sound producer.
	h.reset();game.preferences.reduced_motion=false
	var actor=game.fighters[1];actor.reset_fight(Vector3(4.9,0,-8.5));await Ready.positions(game)
	for tick in range(100):
		await physics_frame;actor.step(1.0/60,Vector3.BACK*0.6,Vector3.BACK);game._update_actor_events(1)
		if h.track_cursor>0:break
	check(h.track_cursor==1 and h.tracks[0].kind=="reed21" and h.sounds.size()==1,"real movement still produces exactly one reed clue and sound")
	var event:Vector3=h.tracks[0].at;var sound:Vector3=h.sounds[0].at
	var anchors:Array=[]
	for n:MeshInstance3D in h.reed_visuals[0].get_children():anchors.append(n.get_meta("reed_anchor"))
	h.tick(0.15)
	var follows:=true
	for i in range(3):
		var n:MeshInstance3D=h.reed_visuals[0].get_child(i)
		follows=follows and n.global_transform.is_equal_approx(h.tufts[0].get_child(0).global_transform*anchors[i])
	check(h.tufts[0].rotation.length()>0.001 and follows and h.tracks[0].at==event and h.sounds[0].at==sound,"normal sway carries only surface-attached visuals, never event or sound coordinates")
	game.preferences.reduced_motion=true;h.tick(0.01)
	check(h.tufts[0].rotation==Vector3.ZERO and h.tracks[0].node.visible and h.tracks[0].at==event,"comfort toggle restores static attached clue with the original event")
	game.paused=true;var time:float=h.elapsed;var pose:Transform3D=h.reed_visuals[0].get_child(0).global_transform;h.tick(10)
	check(h.elapsed==time and h.reed_visuals[0].get_child(0).global_transform==pose and h.tracks[0].node.visible,"pause freezes existing lifetime and visual attachment")
	game.paused=false;h.tick(1.5-h.elapsed)
	check(not h.tracks[0].node.visible and h.tracks[0].time<0 and h.sounds.is_empty(),"reed visual and hearing authority expire at exactly 1.5 seconds")
	# A clue may be emitted while a previous step already bends the mound.
	# Its rim must remain clear when comfort is enabled or the sway reverses.
	var tuft:Node3D=h.tufts[0];var rim:=tuft.position+Vector3(-0.1,-0.024,0.4)
	tuft.rotation=Vector3(0.15,0,-0.12);game.fighters[1].visual.rotation.y=0
	h.track_cursor=0;h.make_track(rim,1,"reed21")
	check(clearance_ok(h.reed_visuals[0],tuft.get_child(0),rim.y+0.033),"rim clue emitted on an already-bent surface has full footprint clearance")
	for surface_pose in [Vector3.ZERO,Vector3(-0.15,0,0.12),Vector3(0.15,0,0.12)]:
		tuft.rotation=surface_pose;h.WetArt.update_reed_print(h.reed_visuals[0])
		check(clearance_ok(h.reed_visuals[0],tuft.get_child(0),rim.y+0.033) and h.tracks[0].at==rim,"bent-origin rim remains above surface and floor after sway/comfort "+str(surface_pose))
	tuft.rotation=Vector3.ZERO
	# Overwrite every raised pool slot with each original presentation type.
	for kind in ["water21","leaves","step","reed21"]:
		for slot in range(h.MAX_TRACKS):
			h.track_cursor=slot;h.make_track(Vector3(4.9,-0.024,-7.0),1,"reed21")
			h.track_cursor=slot;h.make_track(Vector3(12,-0.024,12),1,kind)
			var expected:Node3D=h.wet_visuals[slot] if kind=="water21" else (h.leaf_visuals[slot] if kind=="leaves" else h.reed_visuals[slot])
			var children_ok:=true
			for child in h.tracks[slot].node.get_children():
				var ordinary:bool=child not in [h.wet_visuals[slot],h.leaf_visuals[slot],h.reed_visuals[slot]]
				children_ok=children_ok and child.visible==(ordinary if kind=="step" else child==expected)
			check(restored(h.reed_visuals[slot]) and children_ok and h.tracks[slot].at==Vector3(12,-0.024,12),"pooled slot %d restores %s without raised mesh or stale binding"%[slot,kind])
	for slot in range(h.MAX_TRACKS):h.track_cursor=slot;h.make_track(Vector3(4.9,-0.024,-7.0),1,"reed21")
	h.reset();var clean:=true
	for slot in range(h.MAX_TRACKS):clean=clean and restored(h.reed_visuals[slot]) and not h.tracks[slot].node.visible
	check(clean and h.track_cursor==0,"round reset clears all 24 raised slots and surface bindings")
	await fresh("pine_hollow");h.make_track(Vector3(12,0,12),1,"step")
	check(not h.wetland_active and restored(h.reed_visuals[0]) and h.tracks[0].kind=="step","map switch leaves normal footprints at their authored transform")
	var file:=FileAccess.open("res://ci-artifacts/wetland22-reed-clue.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"fixtures":records},"  "));file.close()
	game.queue_free();await process_frame
	print("REED_CLUE22_RESULT: %d checks, %d failures"%[checks,failures]);quit(0 if failures==0 else 1)
