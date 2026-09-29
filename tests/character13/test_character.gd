extends SceneTree
const Scene=preload("res://scenes/phase13.tscn")
const Legacy=preload("res://scenes/phase12.tscn")
const Buddy=preload("res://scripts/character13/avatar.gd")
const Builder=preload("res://scripts/character13/mesh_builder.gd")
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1
	print(("PASS: " if ok else "FAIL: ")+label)
func count_nodes(node: Node,physics: bool=false) -> int:
	var n:=int(node is CollisionObject3D) if physics else 1
	for child in node.get_children():n+=count_nodes(child,physics)
	return n
func state(game) -> Dictionary:
	var records:=[]
	for a in game.fighters:
		records.append([a.transform,a.weapon_pivot.global_transform,a.weapon_data.to_dictionary(),a.hit_samples.duplicate(),a.health,a.collision_layer,a.collision_mask])
	return {"actors":records,"time":game.rules.time_left,"scores":game.rules.scores.duplicate(),"phase":game.rules.phase,"colliders":count_nodes(game,true)}
func deformed(avatar,vertex: int) -> Vector3:
	var a: Array=avatar.body.mesh.surface_get_arrays(0)
	var v: Vector3=a[Mesh.ARRAY_VERTEX][vertex];var result:=Vector3.ZERO
	for i in range(4):
		var b: int=a[Mesh.ARRAY_BONES][vertex*4+i]
		var w: float=a[Mesh.ARRAY_WEIGHTS][vertex*4+i]
		var t: Transform3D=avatar.skeleton.get_bone_global_pose(b)*avatar.body.skin.get_bind_pose(b)
		result+=(t*v)*w
	return result
func mesh_checks(avatar) -> void:
	var m: ArrayMesh=avatar.body.mesh
	var a: Array=m.surface_get_arrays(0);var v: PackedVector3Array=a[Mesh.ARRAY_VERTEX];var ids: PackedInt32Array=a[Mesh.ARRAY_INDEX]
	check(m.get_surface_count()==1,"one real body surface includes head/torso/arms/hands/legs/feet/ears")
	check(v.size()>5000 and v.size()<16000 and ids.size()<100000,"bounded mesh budget")
	check(a[Mesh.ARRAY_BONES].size()==v.size()*4 and a[Mesh.ARRAY_WEIGHTS].size()==v.size()*4,"four real bone weights on every vertex")
	var valid:=true;var normalized:=true;var smooth:=true;var influence: Dictionary={}
	var hand_isolated:=true;var foot_isolated:=true
	for i in range(v.size()):
		valid=valid and v[i].is_finite() and a[Mesh.ARRAY_NORMAL][i].is_finite() and a[Mesh.ARRAY_TEX_UV][i].is_finite()
		smooth=smooth and absf(a[Mesh.ARRAY_NORMAL][i].length()-1)<0.001
		var total:=0.0
		for j in range(4):
			var b: int=a[Mesh.ARRAY_BONES][i*4+j];var w: float=a[Mesh.ARRAY_WEIGHTS][i*4+j]
			valid=valid and b>=0 and b<Builder.NAMES.size() and is_finite(w) and w>=0
			total+=w
			if w>0.01:influence[b]=true
			if absf(v[i].x)>0.52 and v[i].y<0.72 and v[i].y>0.43 and b in [10,11,12,13,14,15]:hand_isolated=hand_isolated and w<0.001
			if v[i].y<0.23 and b in [4,5,6,7,8,9]:foot_isolated=foot_isolated and w<0.001
		normalized=normalized and absf(total-1)<0.0001
	check(valid,"finite geometry/UVs and valid bone indices/weights")
	check(normalized,"all skin influences sum to one")
	check(hand_isolated,"low-hanging paws cannot inherit leg weights")
	check(foot_isolated,"feet cannot inherit arm weights")
	check(smooth,"unit outward field normals")
	var edge_counts: Dictionary={};var adjacency: Dictionary={};var winding:=true
	for j in range(0,ids.size(),3):
		var t:=PackedInt32Array([ids[j],ids[j+1],ids[j+2]])
		var normal: Vector3=(v[t[1]]-v[t[0]]).cross(v[t[2]]-v[t[0]])
		winding=winding and normal.dot(a[Mesh.ARRAY_NORMAL][t[0]]+a[Mesh.ARRAY_NORMAL][t[1]]+a[Mesh.ARRAY_NORMAL][t[2]])<=0.0000001
		for k in range(3):
			var x: int=t[k];var y: int=t[(k+1)%3];var e:=Vector2i(mini(x,y),maxi(x,y))
			edge_counts[e]=edge_counts.get(e,0)+1
			if not adjacency.has(x):adjacency[x]=[]
			adjacency[x].append(y)
	var closed:=true
	for number in edge_counts.values():closed=closed and number==2
	check(closed,"closed two-manifold body: every triangle edge belongs to two faces")
	var seen: Dictionary={};var todo: Array=[ids[0]]
	while not todo.is_empty():
		var x: int=todo.pop_back()
		if seen.has(x):continue
		seen[x]=true
		for next in adjacency.get(x,[]):
			if not seen.has(next):todo.append(next)
	check(seen.size()==v.size(),"single connected surface, not merely merged disconnected primitives")
	check(winding,"clockwise front faces agree with outward normals")
	for id in [0,1,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17]:check(influence.has(id),"deform bone has real vertex influence: "+Builder.NAMES[id])
	check(avatar.skeleton.get_bone_count()==18 and avatar.body.skin.get_bind_count()==18,"eighteen-bone skeleton and matching rest skin")
	check(avatar.body.get_node(avatar.body.skeleton)==avatar.skeleton,"explicit MeshInstance3D skeleton path resolves")
	check(avatar.attachments.R.get_parent()==avatar.skeleton and avatar.attachments.L.has_node("Grip"),"left/right BoneAttachment3D grip sockets")
	avatar.pose_mode="rest";avatar.sync_pose(0,true)
	var arm_id:=-1;var head_id:=-1;var rest_ok:=true
	for i in range(v.size()):
		if i%37==0:rest_ok=rest_ok and deformed(avatar,i).distance_to(v[i])<0.0002
		if v[i].x>0.62 and v[i].y<0.73:arm_id=i
		if v[i].y>1.5 and absf(v[i].x)<0.1:head_id=i
	check(rest_ok,"rest bind matrices reproduce body within 0.2mm compressed-weight tolerance")
	avatar.skeleton.set_bone_pose_rotation(7,Quaternion(Vector3.FORWARD,0.45))
	check(arm_id>=0 and deformed(avatar,arm_id).distance_to(v[arm_id])>0.10,"arm bone actually deforms weighted hand surface")
	check(head_id>=0 and deformed(avatar,head_id).distance_to(v[head_id])<0.0001,"moving arm does not pull the head")
	avatar.pose_mode="weapon_ready";avatar.sync_pose(0,true)
	var hand: Vector3=avatar.skeleton.get_bone_global_pose(9).origin
	check(hand.distance_to(avatar.grip_target)<0.02,"ready-pose wrist reaches original world grip without moving the weapon")
	avatar.pose_mode="idle";avatar.sync_pose(0,true)
func run() -> void:
	var game=Scene.instantiate();root.add_child(game);game.automated=true
	await process_frame;await process_frame;game.set_process(false)
	check(game.skin_ready,"new scene finished character installation")
	mesh_checks(game.fighters[0].body_art)
	for i in range(4):
		var actor=game.fighters[i];var avatar=actor.body_art
		check(avatar is Buddy,"actor "+str(i)+" uses actual skinned body")
		check(count_nodes(avatar,true)==0,"actor "+str(i)+" character art has no collision objects")
		check(not avatar.is_ancestor_of(actor.weapon_pivot) and not avatar.skeleton.is_ancestor_of(actor.weapon),"actor "+str(i)+" authority weapon remains outside animated hierarchy")
		check(avatar.body.mesh==game.fighters[0].body_art.body.mesh,"actor "+str(i)+" shares immutable body mesh")
		check(avatar.body.skin!=game.fighters[(i+1)%4].body_art.body.skin,"actor "+str(i)+" owns its skin binding")
		check(avatar.face.get_parent()==avatar.skeleton,"actor "+str(i)+" face follows head bone")
		check(game.get_node("SmashDirector").reactions[i].face.get_parent()==avatar.face,"actor "+str(i)+" reaction face follows new head")
		check(game.get_node("SmashDirector").ghosts[i].toy is Buddy,"actor "+str(i)+" exit echo uses same model")
	game.start_practice();game.accept_drawing();game._process(0)
	var before:=state(game);var count:=count_nodes(game)
	var body=game.fighters[0].body_art
	var mesh_id: int=body.body.mesh.get_instance_id()
	for i in range(180):game._sync_characters(1.0/60)
	check(state(game)==before,"pose updates do not alter physics/drawing/HP/score/clocks")
	check(count_nodes(game)==count and body.body.mesh.get_instance_id()==mesh_id,"no per-frame mesh/node rebuild")
	var idle_phase: float=body.phase;game.paused=true
	for i in range(60):game._process(1.0/60)
	check(is_equal_approx(body.phase,idle_phase),"pause freezes new idle motion")
	game.paused=false
	game.preferences.reduced_motion=true;idle_phase=body.phase
	for i in range(60):game._sync_characters(1.0/60)
	check(is_equal_approx(body.phase,idle_phase),"reduced motion disables added breathing phase")
	for map_id in ["toy_manor","toy_home","warehouse","garden","sugar_market","starlight_arcade","pocket_station"]:
		game.return_to_menu();game.select_map(map_id);game.start_practice();game._process(0)
		check(game.ui.preview_actor is Buddy,map_id+" workshop uses same model")
		check(game.ui.preview_grip.get_parent()==game.ui.preview_actor,map_id+" workshop preserves actual drawn weapon node")
		game.accept_drawing();game._process(0);await process_frame
		var actor=game.fighters[1]
		actor.set_hidden(true,0)
		check(not actor.body_art.body.is_visible_in_tree(),map_id+" hidden body not leaked")
		check(not actor.body_art.features.LeftEye.is_visible_in_tree(),map_id+" hidden face not leaked")
		actor.set_hidden(false)
		actor.set_view_subject(true)
		check(actor.body_art.body.layers==actor.SELF_LAYER,map_id+" observed body excluded from first-person view")
		actor.set_view_subject(false)
		check(actor.body_art.body.layers==1,map_id+" non-observed body world layer restored")
		var old_shape: Dictionary=actor.weapon_data.to_dictionary();var old_samples: PackedVector3Array=actor.hit_samples.duplicate()
		actor.body_art.controls.LeftArm.rotation=Vector3(0.3,0,-0.5);actor.body_art.sync_pose(0,false)
		check(actor.weapon_data.to_dictionary()==old_shape and actor.hit_samples==old_samples,map_id+" pose preserves weapon data and collision samples")
	var native:=load("res://assets/character13/buddy_rig.scn") as PackedScene
	check(native!=null,"editable native rig resource loads")
	if native!=null:
		var copy=native.instantiate();root.add_child(copy);await process_frame
		check(copy.get_node("Skeleton3D").get_bone_count()==18,"reloaded native rig has real bones")
		check(copy.get_node("ConnectedBody").skin.get_bind_count()==18,"reloaded native rig retains skin weights/binds")
		copy.queue_free()
	game.queue_free();await process_frame
	var previous=Legacy.instantiate();root.add_child(previous);previous.automated=true
	await process_frame;await process_frame
	check(not previous.fighters[0].body_art is Buddy,"Phase 12 entry retains its original model")
	previous.queue_free();await process_frame
	print("CHARACTER_UNIT_RESULT: %d checks, %d failures"%[checks,failures]);quit(0 if failures==0 else 1)
